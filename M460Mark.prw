// Programa:   M460Mark
// Autor:      Robert Koch
// Data:       03/09/2008
// Cliente:    Alianca
// Descricao:  P.E. antes da geracao das NF de saida. Serve como validacao para impedir a geracao das notas.
//
// Historico de alteracoes:
// 03/07/2009 - Robert - Verificacao de geracao de NF fora de sequencia
//                     - Verificacao de geracao de NF com numeracao jah existente na SEFAZ
// 18/08/2009 - Robert - Verifica se existe registro duplicado no SC9 antes de gerar a nota.
// 20/04/2010 - Robert - Passa a chamar a funcao VerSqNf.
// 01/07/2010 - Robert - Novos parametros funcao VerSqNF.
// 29/10/2010 - Robert - Verificacao de estoques.
// 01/11/2010 - Robert - Verifica se todos os itens do pedido foram marcados.
// 07/11/2010 - Robert - Verifica se existem pendencias no deposito (filial 04).
// 21/12/2010 - Robert - Busca codigo da entidade direto da tabela SPED001.
// 18/02/2011 - Robert - Verificacao de nota jah transmitida para a SEFAZ passada para o programa U_VerSqNF.
// 06/08/2015 - Robert - Passa a buscar a serie da nota do SX5 (antes estava fixo '10 ').
//

// --------------------------------------------------------------------------
user function m460mark ()
	local _lRet      := .T.
//	local _aPendD04  := {}
	local _aAreaAnt  := u_ml_srarea ()
	//u_logIni ()

	// Verifica se todos os itens dos pedidos foram marcados.
	if _lRet
		_lRet = _VerMarc ()
	endif

	// Verifica geracao de nota fora de sequencia
	if _lRet //.and. cEmpAnt == "01"
		_lRet = _VerNumNF ()
	endif
	
	//u_log ('retornando', _lRet)
	//u_logFim ()
	U_ML_SRAREA (_aAreaAnt)
return _lRet




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
return _lRet



// --------------------------------------------------------------------------
// Verifica geracao de nota fora de sequencia
static function _VerNumNF ()
	local _lRet      := .T.
	local _sSerie    := ""  //"10 "  // Ainda nao descobri como buscar a serie selecionada pelo usuario. Como soh temos esta serie, por enquanto vai assim...

	_sSerie = left (sx5 -> x5_chave, 3)
	_lRet = U_VerSqNf ("S", _sSerie, cNumero, dDataBase, sc9 -> c9_cliente, sc9 -> c9_loja, sc9 -> c9_pedido, sc9 -> c9_produto, fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_TIPO"))

return _lRet

