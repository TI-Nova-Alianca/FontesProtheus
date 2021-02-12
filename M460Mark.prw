// Programa...:  M460Mark
// Autor......:  Robert Koch
// Data.......:  03/09/2008
// Cliente....:  Alianca
// Descricao..:  P.E. antes da geracao das NF de saida. Serve como validacao para impedir a geracao das notas.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. antes da geracao das NF de saida. Serve como validacao para impedir a geracao das notas.
// #PalavasChave      #faturamento #MATA460B #preparacao_documento_saida #logistica #expedicao
// #TabelasPrincipais #SF2 #SC9
// #Modulos           #FAT #OMS
//
// Historico de alteracoes:
// 03/07/2009 - Robert  - Verificacao de geracao de NF fora de sequencia
//                      - Verificacao de geracao de NF com numeracao jah existente na SEFAZ
// 18/08/2009 - Robert  - Verifica se existe registro duplicado no SC9 antes de gerar a nota.
// 20/04/2010 - Robert  - Passa a chamar a funcao VerSqNf.
// 01/07/2010 - Robert  - Novos parametros funcao VerSqNF.
// 29/10/2010 - Robert  - Verificacao de estoques.
// 01/11/2010 - Robert  - Verifica se todos os itens do pedido foram marcados.
// 07/11/2010 - Robert  - Verifica se existem pendencias no deposito (filial 04).
// 21/12/2010 - Robert  - Busca codigo da entidade direto da tabela SPED001.
// 18/02/2011 - Robert  - Verificacao de nota jah transmitida para a SEFAZ passada para o programa U_VerSqNF.
// 06/08/2015 - Robert  - Passa a buscar a serie da nota do SX5 (antes estava fixo '10 ').
// 12/02/2021 - Cláudia - Validação de cliente bloqueado. GLPI: 7982
//
// ------------------------------------------------------------------------------------------------------------
User Function m460mark ()
	local _lRet      := .T.
	local _aAreaAnt  := u_ml_srarea ()

	// Verifica se todos os itens dos pedidos foram marcados.
	if _lRet
		_lRet = _VerMarc ()
	endif

	// Verifica se o cliente não está bloqueado
	if _lRet
		_lRet = _VerCliente ()
	endif

	// Verifica geracao de nota fora de sequencia
	if _lRet //.and. cEmpAnt == "01"
		_lRet = _VerNumNF ()
	endif
	
	U_ML_SRAREA (_aAreaAnt)
Return _lRet
//
// --------------------------------------------------------------------------
// Verifica se todos os itens do pedido foram marcados.
Static Function _VerMarc ()
	local _lRet      := .T.
	local _sMarca    := ParamIXB [1]  // "marca" do markbrowse do SC9 (pedidos selecionados pelo usuario)
	local _sQuery    := ""

	_sQuery := ""
	_sQuery += " SELECT COUNT (*)"
	_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9 "
	_sQuery +=  " WHERE SC9.C9_OK     != '" + _sMarca + "'"
	_sQuery +=    " AND SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
	_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
	_sQuery +=    " AND SC9.C9_NFISCAL = ''"
	_sQuery +=    " AND SC9.C9_PEDIDO IN (SELECT DISTINCT C9_PEDIDO"
	_sQuery +=                            " FROM " + RETSQLName ("SC9") + " SC9"
	_sQuery +=                           " WHERE SC9.C9_OK      = '" + _sMarca + "'"
	_sQuery +=                             " AND SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
	_sQuery +=                             " AND SC9.D_E_L_E_T_ = ' '"
	_sQuery +=                             " AND SC9.C9_NFISCAL = '')"
	if U_RetSQL (_sQuery) > 0
		_lRet = U_MsgNoYes ("Existe(m) pedido(s) parcialmente marcados. Confirma a geracao das notas assim mesmo?")
	endif
Return _lRet
//
// --------------------------------------------------------------------------
// Verifica pedidos marcados para validar se cliente é ou não bloqueado
Static Function _VerCliente ()
	Local _lRet   := .T.
	Local _sMarca := ParamIXB [1]  // "marca" do markbrowse do SC9 (pedidos selecionados pelo usuario)
	Local _i      := 0

	_sQuery := " SELECT DISTINCT "
	_sQuery += "      C9_CLIENTE"
	_sQuery += "     ,C9_LOJA"
	_sQuery += "     ,C9_PEDIDO"
	_sQuery += "  FROM " + RETSQLName ("SC9") 
	_sQuery += "  WHERE D_E_L_E_T_ = ''"
	_sQuery += "  AND C9_FILIAL = '" + xFilial ("SC9") + "'"
	_sQuery += "  AND C9_OK     = '" + _sMarca + "'"
	_aDados:= U_Qry2Array(_sQuery)

	For _i:= 1 to Len(_aDados)
		_lRet := _EhBloq(_aDados[_i, 1], _aDados[_i, 2], _aDados[_i, 3])
		if _lRet == .F.
			Return _lRet
		endIf
	Next
Return _lRet
//
// --------------------------------------------------------------------------
// Verifica se cliente é bloqueado
Static Function _EhBloq(_sCliente, _sLoja, _sPedido)
	Local _lRet    := .T.
	Local _aDados := {}
	Local _sQuery := ""

	_sQuery := " SELECT"
	_sQuery += "  	A1_MSBLQL "
	_sQuery += " FROM " + RETSQLName ("SA1")
	_sQuery += " WHERE D_E_L_E_T_ = '' "
	_sQuery += " AND A1_COD  = '" + _sCliente + "'"
	_sQuery += " AND A1_LOJA = '" + _sLoja    + "'"
	_aDados:= U_Qry2Array(_sQuery)	

	If Len(_aDados) > 0
		If alltrim(_aDados[1,1]) == '1'
			u_help(" O pedido " + alltrim(_sPedido) + " está com o cliente " + alltrim(_sCliente) + " bloqueado!")
			_lRet := .F.
		EndIf
	EndIf
Return _lRet
//
// --------------------------------------------------------------------------
// Verifica geracao de nota fora de sequencia
Static Function _VerNumNF ()
	Local _lRet      := .T.
	Local _sSerie    := ""  //"10 "  // Ainda nao descobri como buscar a serie selecionada pelo usuario. Como soh temos esta serie, por enquanto vai assim...

	_sSerie = left (sx5 -> x5_chave, 3)
	_lRet = U_VerSqNf ("S", _sSerie, cNumero, dDataBase, sc9 -> c9_cliente, sc9 -> c9_loja, sc9 -> c9_pedido, sc9 -> c9_produto, fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_TIPO"))

Return _lRet

