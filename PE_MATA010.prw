// Programa...: ITEM
// Autor......: Andre Alves
// Data.......: 06/05/2019
// Descricao..: Ponto entrada na tela cadastro de Produtos.

// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto entrada na tela cadastro de Produtos.
// #PalavasChave      #ponto_de_entrada #cadastro_de_produto  #cadastro_de_produto_MVC
// #TabelasPrincipais #SB1 
// #Modulos 		  #todos

// Historico de alteracoes:
// 16/08/2019 - Robert  - Campo B1_VADUNCX substituido pelo campo B1_CODBAR.
// 20/08/2019 - Robert  - Ajustes para opcao de nao copiar determinados campos e gravacao de eventos.
// 28/08/2019 - Cl�udia - Incluida valida��o para n�o permitir salvar o produto quando fator de convers�o 
//                        informado no complemento e unidade DIPI n�o informada.
// 29/08/2019 - Andre   - Removido valida��o do campo CODEAN. 
// 02/09/2019 - Andre   - Campos de RASTRO e LOCALIZACAO removidos do N�O COPIA.
// 06/03/2020 - Claudia - Ajustada a leitura do SX3/SXA conforme solicita��o da R25
// 17/03/2020 - Andre   - Inserida fun��o para n�o copiar campos do cadastro de PRODUTO X FORNECEDOR (SA5)
// 22/06/2020 - Robert  - Somente envia atualizacao para o Mercanet quando for item do tipo PA (GLPI 8090).
//                      - Antes de permitir a exclusao, verifica se o item existe no Mercanet, FullWMS e NaWeb.
//                      - Eliminados logs desnecessarios.
// 20/01/2021 - Cl�udia - GLPI:8921 - Incluida verifica��o de caracteres especiais.
// 12/02/2021 - Robert  - Incluidas chamadas da funcao U_PerfMon para testes de monitoramento de 
//                        performance (GLPI 9409)
// 02/03/2021 - Sandra  - Comentariado Altera campos do modelo de dados adicionais (tabela SA5) 
//                        foi retirada do parametro mv_cadprod GLPI 8987
// 22/06/2021 - Claudia - Carregado o campo B1_VARMAAL com 000000000 na c�pia de produto. GLPI: 10276
// 04/10/2021 - Claudia - Incluida valida��o de usuario manuten��o. GLPI: 10968
// 05/10/2021 - CLaudia - Incluida a valida��o do docigo GNRE para PA e MR. GLPI: 11017
// 08/10/2021 - Claudia - Incluida a valida��o para itens MC, conforme GLPI: 10845
// 10/06/2022 - Robert  - Validacao codigo final C x tipo MC: ignora grupo 2007 (contra-rotulos) - GLPI 12190
// 19/10/2022 - Robert  - Valida duplicidade do B1_CODBAR no 'tudo ok' - GLPI 12726
// 24/10/2022 - Robert  - Melhorada mensagem de validacao B1_TIPO x B1_GRTRIB
// 26/10/2022 - Robert  - Valida duplicidade de do B1_CODBAR somente "se nao for tudo zero".
// 15/12/2022 - Claudia - Incluidas valida��es de rastro e lote. GLPI: 12933
// 05/01/2023 - Robert  - Teste de desabilitacao de rastro e enderecamento
//                        considerava se jah estava habilitado ou nao no SB1.
// 20/02/2023 - Claudia - Transformado bloqueio em aviso. GLPI: 13193
// 09/08/2023 - Robert  - Valid.dupliciadade B1_CODBAR passa a permitir itens 'irmaos'.
//                        e tratamento especifico para itens 8146/8302/8531.
// 20/10/2023 - Robert  - Desabilitadas chamadas da U_PerfMon() por que nao estou usando para nada.
// 07/12/2023 - Claudia - Obrigar informar custo ao liberar um produto. GLPI: 14602
// 08/12/2023 - Claudia - N�o realizar a c�pia dos campos B1_RASTRO e B1_LOCALIZ. GLPI: 14607
// 08/03/2023 - Claudia - Retirada valida��o do campo b1_locprod
// 14/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 17/10/2024 - Claudia - Incluido mensagem de altera��o de custo. GLPI: 16026
// 25/11/2024 - Claudia - Retirados alguns campos conforme GLPI:16439
//
//---------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch" 
#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

User Function ITEM() 
	local oObj  := NIL
	local nOper := 0
	local _xRet := NIL
	private _nCnt := 0

	// Sugestao para obter o conteudo de ParamIXB: habilitar o parametro IXBLOG=LOGRUN no appserver.ini e consultar o log gerado na pasta \ixbpad
	if paramixb <> NIL

		// Devido ao fato deste P.E. ser chamado mais de uma vez para cada campo da tela, optei por tratar somente os casos necessarios
		// e deixar de usar um programa mais estruturado.
		if paramixb [2] == "MODELVLDACTIVE"  // Valida a abertura da tela (executa apenas uma vez na abertura da tela)
			_xRet = .T.
			oObj := paramixb [1]
			nOper := oObj:nOperation

			If nOper == 5  // Exclusao
				_xRet = _ValidExcl ()
			EndIf
			if _xRet
				// Cria lista de campos que o usuario pode alterar
				public _sCposAlt := ""  // Deixar com PUBLIC para ser visivel no X3_WHEN
				_VerAcesso ()
			endif

		elseif paramixb [2] == 'BUTTONBAR'  // Chamado uma vez apos montar os campos na tela, antes de montar a barra de botoes.
			oObj := paramixb [1]

			if oObj:IsCopy ()				
				_NaoCopia() // Limpa campos que nao devem ser copiados.
			endif
			_xRet := {}  // Nao quero criar nenhum botao

		elseif paramixb [2] == "MODELPOS"  //Valida��o 'tudo OK' ao clicar no Bot�o Confirmar
			_xRet := _A010TOk () 

		elseif paramixb [2] == "MODELCOMMITNTTS"  //Commit das opera��es (ap�s a grava��o)
			oObj := paramixb [1]
			nOper := oObj:nOperation

			if nOper == 3  // Inclusao
				// Envia atualizacao para o Mercanet
				if m->b1_tipo == 'PA'  // A principio nao temos intencao de vender outros tipos de itens.
					U_AtuMerc ('SB1', sb1 -> (recno ()))
				endif

			elseif nOper == 4  // ALteracao
				_MT010Alt ()
			endif
			_xRet = NIL

		elseif paramixb [2] == 'FORMPRE'  			// Chamado a cada campo que tiver validacao de usuario.
			_xRet = NIL

		ElseIf paramixb [2] == "FORMPOS"  			// P�s configura��es do Formul�rio
			_xRet := _A010FPOS () 		

		ElseIf paramixb [2] == "MODELCANCEL"  		// Quando o usuario cancela a edicao (tenta sair sem salvar)
			_xRet = .T.

		ElseIf paramixb [2] == "FORMCOMMITTTSPOS"  	// P�s valida��es do Commit
			_xRet = NIL

		ElseIf paramixb [2] == "MODELCOMMITTTS"  	// Commit das opera��es (antes da grava��o)
			_xRet = NIL

		ElseIf paramixb [2] == "FORMCOMMITTTSPRE"  	// Pr� valida��es do Commit
			_xRet = NIL

		EndIf 
	endif
Return _xRet
//
// --------------------------------------------------------------------------
// Limpa campos que nao devem ser copiados.
static function _NaoCopia ()
	Local oObj := paramixb [1]
		
	// Altera campos do modelo principal (tabela SB1)
	oModelB1 := oObj:GetModel("SB1MASTER")
	if ! U_msgnoyes ("Deseja copiar os dados de impostos?")
		oModelB1:LoadValue("B1_VLR_IPI",'')
		oModelB1:LoadValue("B1_IPI",'')
		oModelB1:LoadValue("B1_TAB_IPI",'')
	endif
	oModelB1:LoadValue("B1_CODBAR", '')
	oModelB1:LoadValue("B1_CODPAI", '')
	oModelB1:LoadValue("B1_OPERPAD",'')
	oModelB1:LoadValue("B1_CUSTD",'')
	oModelB1:LoadValue("B1_PRV1",'')
	oModelB1:LoadValue("B1_UPRC",'')
	oModelB1:LoadValue("B1_DATREF",'')
	oModelB1:LoadValue("B1_UCOM",'')
	oModelB1:LoadValue("B1_UREV",'')
	oModelB1:LoadValue("B1_DTREFP1",'')
	oModelB1:LoadValue("B1_CONINI",'')
	oModelB1:LoadValue("B1_REVATU",'')
	oModelB1:LoadValue("B1_UCALSTD",'')
	oModelB1:LoadValue("B1_VARMAAL",'00000000000000') // CARREGAR PADR�O
	oModelB1:LoadValue("B1_VAFULLW",'')
	oModelB1:LoadValue("B1_RASTRO",'')
	oModelB1:LoadValue("B1_LOCALIZ",'')
	// Atualiza campos na tela do usuario
	oView := FwViewActive()
	oView:Refresh ()


	// Altera campos do modelo de dados adicionais (tabela SB5)
	oModelB5 := oObj:GetModel("SB5DETAIL")
	oModelB5:LoadValue("B5_2CODBAR",'')
	oModelB5:LoadValue("B5_VACSD01",'')
	oModelB5:LoadValue("B5_VACSD03",'')
	oModelB5:LoadValue("B5_VACSD05",'')
	oModelB5:LoadValue("B5_VACSD06",'')
	oModelB5:LoadValue("B5_VACSD07",'')
	oModelB5:LoadValue("B5_VACSD08",'')
	oModelB5:LoadValue("B5_VACSD09",'')
	oModelB5:LoadValue("B5_VACSD10",'')
	oModelB5:LoadValue("B5_VACSD11",'')
	oModelB5:LoadValue("B5_VACSD12",'')
	oModelB5:LoadValue("B5_VACSD13",'')
	// Atualiza campos na tela do usuario
	oView := FwViewActive()
	oView:Refresh ()
	
return
//
// --------------------------------------------------------------------------
// Valida��o 'tudo OK' ao clicar no Bot�o Confirmar
static function _A010TOk ()
	local _lRet      := .T.
	local _lEhUva    := .F.
	local _aAreaSB1  := {}
	local _oEvento   := NIL
	local _oSQL      := NIL

	if m->b1_tipo $ "PA/PI/VD"
		if m->b1_litros == 0 .and. ! m->b1_grupo $ '0603/0706'
			u_help ("Campo '" + alltrim (RetTitle ("B1_LITROS")) + "' deve ser informado para este tipo de produto.")
			_lRet = .F.
		endif
	endif
		
	if ! m->b1_tipo $ "PA/MR"
		if alltrim (m->b1_tipo) != alltrim (m->b1_grtrib)
			_sMsg := "Campo '" + alltrim (RetTitle ("B1_TIPO")) + "' nao pode ser diferente de '" + alltrim (RetTitle ("B1_GRTRIB")) + "' para que TES inteligente / excecoes fiscais funcionem. Deseja continuar?"
			If msgyesno(_sMsg,"Verifica��o Tipo")
				_lRet = .T.
			Else			
				_lRet = .F.
			EndIf
		endif
	endif
		
	// Verifica se eh uva (materia prima)
	if m->b1_tipo == "MP" .and. ! alltrim (m->b1_cod) $ "9989/2852" ;  // Lenha
		.and. (! empty (m->b1_varuva) ;
		.or. m->b1_locpad == "50")
		_lEhUva = .T.
	else
		_lEhUva = .F.
	endif
		
	if _lRet .and. _lEhUva
		if 	empty (m->b1_VarUva)
			u_help ("Este item e� UVA: Os seguintes campos devem ser informados: " + chr (13) + chr (10) + ;
					alltrim (RetTitle ("B1_VARUVA")))
			_lRet = .F.
		endif
		if _lRet .and. ! m->b1_vacor $ "BRT"
			u_help ("Este item e� UVA: Campo '" + alltrim (RetTitle ("B1_VACOR")) + "' deve ser informado para este tipo de produto.")
			_lRet = .F.
		endif
	endif

	if _lRet
		if m->b1_vafullw == 'S'
			if empty (m->b1_codbar)
				u_help ("Produtos controlados pelo FullWMS (campo '" + alltrim (RetTitle ("B1_VAFULLW")) + "') devem ter codigo de barras da caixa informado, mesmo que seja composto de zeros, informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'.")
				_lRet = .F.
			endif
			if ! m->b1_um $ 'GF/CX/UN/FD'
				u_help ("Unidade de medida invalida para produtos controlados pelo FullWMS (campo '" + alltrim (RetTitle ("B1_VAFULLW")) + "').")
				_lRet = .F.
			endif
		endif
	endif

	if _lRet
		if m->b1_vlr_ipi != 0 .and. m->b1_ipi != 0
			u_help ("IPI deve ser informado somente por aliquota (campo '" + alltrim (RetTitle ("B1_IPI")) + "') ou por valor absoluto (campo '" + alltrim (RetTitle ("B1_VLR_IPI")) + "'), mas nao ambos.")
			_lRet = .F.
		endif
	endif

	if _lRet .and. ! empty (m->b1_codbar) .and. ! _SohZeros (m->b1_codbar)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT RTRIM (STRING_AGG (RTRIM (B1_COD) + '-' + RTRIM (B1_DESC), '; '))"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=    " AND SB1.B1_CODBAR  = '" + m->b1_codbar + "'"
		_oSQL:_sQuery +=    " AND SB1.B1_COD    != '" + m->b1_cod + "'"

		// Se for um item 'irmao' (mesmo pai) vou aceitar EAN igual, por que
		// trata-se de mesmo produto fisico, mas com codigo diferente para ser
		// usado em exportacoes ou licitacoes.
		_oSQL:_sQuery +=    " AND SB1.B1_CODPAI != '" + m->b1_codpai + "'"

		// Especificamente o item 8531 vai ser exportado em caixas de 6 unidades
		// em vez da tradicional caixa de 12 unidades. Robert, 09/08/2023
		if alltrim (m->b1_cod) $ '8146/8302/8531'
			_oSQL:_sQuery += " and not SB1.B1_COD in ('8146', '8302', '8531')"
		endif

		_oSQL:Log ('[' + procname () + ']')
		_sMsg = _oSQL:RetQry (1, .f.)
		if ! empty (_sMsg)
			U_Help ("Codigo de barras ja informado para o(s) seguinte(s) produto (s): " + _sMsg,, .t.)
			_lRet = .F.
		endif
	endif

	if m->b5_convdip != 0 .and. empty(m->b5_umdipi)
		u_help ("Fator de convers�o informado no complemento. A unidade DIPI deve ser informada no registro!")
		_lRet = .F.
	endif 

	// valida caracter espacial
	If paramixb [1]:nOperation == 3 // inclus�o
		_lRet = CaracEsp(m->b1_cod)
	EndIf
	
	if _lRet
		if m->b1_tipo == 'PA' .or. m->b1_tipo == 'MR' 
			if empty(m->b5_codgnre)
				u_help("Para produtos PA e/ou MR, � obrigat�rio inserir o Cod.Prod (C�digo GNRE)")
				_lRet := .F.
			endif 
		endif
	endif

	if _lRet
		if m->b1_tipo != 'MM' .and. m->b1_tipo != 'MC'
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SETOR "
			_oSQL:_sQuery += " FROM VA_FUNCIONARIO_SETOR('" + __CUSERID + "')"
			_sDados := aclone(_oSQL:Qry2Array (.f., .f.))

			if Len(_sDados)> 0
				if alltrim(_sDados[1, 1]) == '2008'
					u_help("Usu�rio sem permiss�o para alterar produto tipo " + m->b1_tipo)
					_lRet := .F.
				endif
			endif
		endif
	endif

	if _lRet 
		_sCaracter := SUBSTR(alltrim(m->b1_cod), -1, 1) 

		If _sCaracter == 'C' .and. m->b1_tipo <> 'MC'
			if m->b1_grupo != '2007'  // contra-rotulos
				u_help("Produto com final C deve ser obrigatoriamente do tipo MC.")
				_lRet := .F.
			endif
		else
			if _sCaracter <> 'C' .and. m->b1_tipo == 'MC'
				u_help("Produto do tipo MC deve ter obrigatoriamente C no seu final.")
				_lRet := .F.
			endif
		endif	
	endif

	// valida��es lote e rastro
	if _lRet .and. m->b1_rastro = 'N' .and. sb1 -> b1_rastro = 'L'  // Usuario tentou desabilitar o rastro
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT count (*)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SB8")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND B8_PRODUTO   = '" + m->b1_cod + "'"
		_oSQL:_sQuery += " AND B8_SALDO > 0"

		if _oSQL:RetQry (1, .F.) > 0
			u_help("Produto possui saldo em lote! N�o � poss�vel altera��o no cadastro.")
			_lRet := .F.
		endif
	endif

	U_Log2 ('debug', '[' + procname () + ']validando sb1->b1_cod=' + sb1 -> b1_cod)
	if _lRet .and. alltrim(m->b1_localiz) == 'N' .and. sb1 -> b1_localiz = 'S'  // Usuario tentou desabilitar a localizacao
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT count (*)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SBF")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND BF_PRODUTO   = '" + m->b1_cod + "'"
		_oSQL:_sQuery += " AND BF_QUANT > 0"

		if _oSQL:RetQry (1, .F.) > 0
			u_help("Produto possui saldo em endere�o! N�o � poss�vel altera��o no cadastro.")
			_lRet := .F.
		endif
	endif

	if _lRet .and. m->b1_msblql ='2' .and. empty(m->b1_custd) .and. m->b1_tipo=='PA'
		u_help("Custo Stand. � obrigat�rio em produtos liberados. Verifique!")
		_lRet := .F.
	endif

	if _lRet .and. paramixb [1]:nOperation == 4  // Se estou alterando um cadastro, gero evento de alteracao.
		_aAreaSB1 := sb1 -> (getarea ())
		sb1 -> (dbsetorder (1))
		if sb1 -> (dbseek (xfilial ("SB1") + m->b1_cod, .F.))  // SB1 chega aqui em BOF (vai entender...)
			_oEvento := ClsEvent():new ()
			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
		else
			u_log2 ('erro', "Nao encontrei o SB1 do produto '" + m->b1_cod + "' para gerar o evento.")
		endif
		restarea (_aAreaSB1)
	endif

return _lRet
//
// --------------------------------------------------------------------------
// valida��o de formulario - executa uma vez s�
Static Function _A010FPOS ()
	if sb1->b1_custd <> m->b1_custd .and. sb1 -> b1_tipo == 'PA'
		_sTitulo := "Altera��o de custo produto " + alltrim(m->b1_cod) + ' - ' + alltrim(m->b1_desc)
		_sMsg    := _sTitulo + " de " + cvaltochar(sb1->b1_custd) + " para " + cvaltochar(m->b1_custd)
		U_ZZUNU ({"161"}, "Altera��o de custo produto " + alltrim(m->b1_cod) + ' - ' + alltrim(m->b1_desc), _sMsg)
	endif
Return
//
// --------------------------------------------------------------------------
// valida��o de altera��o
static function _MT010Alt()
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL

	if sb1 -> b1_tipo == 'PA'  // A principio nao temos intencao de vender outros tipos de itens.
		U_AtuMerc ('SB1', sb1 -> (recno ()))
	endif

	// Avisos para logistica
	_AvisaLog ()
	
	// Atualiza descricao do item na tabela produtos X fornecedores.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " UPDATE " + RetSQLName ("SA5")
	_oSQL:_sQuery +=    " SET A5_NOMPROD = '" + alltrim (SB1->B1_DESC) + "'"
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND A5_FILIAL  = '" + xfilial ("SA5") + "'"
	_oSQL:_sQuery +=    " AND A5_PRODUTO = '" + SB1->B1_COD + "'"
	_oSQL:Exec ()

	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Avisos de interesse da logistica.
static function _AvisaLog ()
	local _sMsg := ""
	if (inclui .and. m->b1_vafullw == 'S') .or. (altera .and. sb1 -> b1_vafullw != 'S' .and. m->b1_vafullw == 'S')
		_sMsg += 'Novo produto com controle pelo FullWMS: ' + alltrim (m->b1_cod) + ' - ' + alltrim (m->b1_desc)
	endif
	if altera .and. sb1 -> b1_vafullw == 'S' .and. m->b1_codbar != sb1 -> b1_codbar
		_sMsg += "Produto '" + alltrim (m->b1_cod) + "' (" + alltrim (m->b1_desc) + "): cod.barras caixa (DUN14) alterado de '" + alltrim (sb1 -> b1_codbar) + "' para '" + alltrim (m->b1_codbar) + "'. Verifique cadastro do mesmo no FullWMS."
	endif
	if ! empty (_sMsg)
		U_ZZUNU ({"007"}, "Aviso manutencao cadastro Protheus X Fullsoft", _sMsg)
	endif
return
// --------------------------------------------------------------------------
// Verifica acessos do usuario e cria variavel para ser usada no X3_WHEN
static function _VerAcesso ()
	local _sPastas   := ""
	local i			 := 1
	public _sCposAlt := ""  // Deixar com PUBLIC para ser visivel no X3_WHEN

	// Se a variavel jah existir, nao preciso releitura dos acessos.
	if empty (_sCposAlt)

		// Cria antes uma lista de pastas para diminuir o numero de leituras do ZZU.
		if U_ZZUVL('060',__CUSERID,.F.)
			_sPastas += '2/'  // Impostos
		endif
		if U_ZZUVL('061',__CUSERID,.F.)
			_sPastas += '3/'  // MRP/Suprimentos
		endif
		if U_ZZUVL('062',__CUSERID,.F.)
			_sPastas += '9/'  // Uvas / vinhos
		endif
		if U_ZZUVL('063',__CUSERID,.F.)
			_sPastas += '5/8/'  // Atendimento + garantia estendica
		endif
		if U_ZZUVL('064',__CUSERID,.F.)
			_sPastas += '1/6/7/A/ /'  // Demais abas (inclusive 'outros')
		endif
		if U_ZZUVL('065',__CUSERID,.F.)
			_sPastas += '4/'  // C.Q.
		endif

		_aCpoSX3 := FwSX3Util():GetAllFields('SB1')
		
		For i:=1 To Len(_aCpoSX3)
		    If (alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO')) == 'SB1')
		    	If GetSx3Cache(_aCpoSX3[i], 'X3_FOLDER') $ _sPastas
		    		_sCposAlt += GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')
		    	EndIf
		    Endif
		Next i
	endif
Return
//
// --------------------------------------------------------------------------
// Valida se pode excluir o item.
static function _ValidExcl ()
	local _lRetExcl  := .T.
	local _oSQL      := ClsSQL ():New ()
	local _sLkSrvMer := U_LkServer ('Mercanet')
	local _sLkSrvNAW := U_LkServer ('naWeb')

	// Verifica se o item existe no Mercanet.
	_oSQL:_sQuery := "SELECT COUNT (*) FROM " + _sLkSrvMer + ".DB_PRODUTO where DB_PROD_CODIGO = '" + alltrim (sb1 -> b1_cod) + "'"
	_oSQL:Log ()
	if _oSQL:RetQry (1, .f.) > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema Mercanet.',, .t.)
		_lRetExcl = .F.
	endif

	// Verifica se o item existe no Fullsoft.
	_oSQL:_sQuery := "select (select count (*) from tb_wms_entrada where coditem  = '" + alltrim (sb1 -> b1_cod) + "')
	_oSQL:_sQuery +=     " + (select count (*) from tb_wms_lotes   where cod_item = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:Log ()
	if _oSQL:RetQry (1, .f.) > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema FullWMS.',, .t.)
		_lRetExcl = .F.
	endif

	// Verifica se o item existe no NaWeb.
	_oSQL:_sQuery := "select (select count (*) from " + _sLkSrvNAW + ".inspecaoproduto where produto_cod        = '" + alltrim (sb1 -> b1_cod) + "')
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".ColetaProdutos  where Coleta_produto_cod = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".SFInspCarga     where InspCargaVariedade = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".Rotulo          where RotuloProduto      = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:_sQuery +=     " + (select count (*) from " + _sLkSrvNAW + ".Sac             where sac_codigo_produto = '" + alltrim (sb1 -> b1_cod) + "')"
	_oSQL:Log ()
	if _oSQL:RetQry (1, .f.) > 0
		u_help ('Codigo nao pode ser excluido, pois existe(m) registro(s) no sistema NaWeb.',, .t.)
		_lRetExcl = .F.
	endif

return _lRetExcl
//
// --------------------------------------------------------------------------
// Caracteres especiais
Static Function CaracEsp(_sCampo)
    Local _i       := 0
    Local _lRet    := .T.
    Local _nExiste := 0
    Local _aCarac  := {}

    AADD(_aCarac,{"!"})
    AADD(_aCarac,{"@"})
    AADD(_aCarac,{"#"})
    AADD(_aCarac,{"$"})
    AADD(_aCarac,{"%"})
    AADD(_aCarac,{"*"})
    AADD(_aCarac,{"/"})
    AADD(_aCarac,{"("})
    AADD(_aCarac,{")"})
    AADD(_aCarac,{"+"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"="})
    AADD(_aCarac,{"~"})
    AADD(_aCarac,{"^"})
    AADD(_aCarac,{"]"})
    AADD(_aCarac,{"["})
    AADD(_aCarac,{"{"})
    AADD(_aCarac,{"}"})
    AADD(_aCarac,{";"})
    AADD(_aCarac,{":"})
    AADD(_aCarac,{">"})
    AADD(_aCarac,{"<"})
    AADD(_aCarac,{"?"})
    AADD(_aCarac,{"_"})
    AADD(_aCarac,{","})
    AADD(_aCarac,{" "})
    AADD(_aCarac,{"�"}) 
    AADD(_aCarac,{","}) 
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{"."})
    AADD(_aCarac,{"&"})
    AADD(_aCarac,{"|"})
    AADD(_aCarac,{"�"})
    AADD(_aCarac,{" "})

    For _i:= 1 to Len(_aCarac)
        If _aCarac[_i, 1] $ RTRIM(_sCampo) 
            _nExiste += 1
        EndIf
    Next

    If _nExiste > 0
        _lRet := .F.
        u_help("Produto "+ RTRIM(_sCampo) + " com caracteres especiais. Verifique!")
    EndIf
Return _lRet
//
// -------------------------------------------------------------------
// Verifica se o texto informado contem somente zeros.
static function _SohZeros (_sStrOrig)
	_lRetZeros := .T.

	do while ! empty (_sStrOrig)
		if left (_sStrOrig, 1) != '0'
			_lRetZeros = .F.
			exit
		endif
		_sStrOrig = substr (_sStrOrig, 2)
	enddo
return _lRetZeros
