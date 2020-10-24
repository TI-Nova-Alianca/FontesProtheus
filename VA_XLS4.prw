// Programa...: VA_XLS4
// Autor......: Robert Koch
// Data.......: 04/11/2009
// Descricao..: Exportacao de dados de producao para o Excel.
//
// #TipoDePrograma    #Consulta
// #Descricao         #Exportacao de dados de producao para o Excel
// #PalavasChave      #boletos #geracao_NF #SEFAZ 
// #TabelasPrincipais #SD3 #SB1 #SH1 
// #Modulos 		  #PCP #EST
//
// Historico de alteracoes:
// 04/07/2018 - Robert  - Incluidos campos de linha de envase, perda, data/hora digitacao e usuario.
// 01/04/2019 - Andre   - Alterado busca da linha de envase do B1_CLINF pelo B1_VALINEN, descrição também passa a ser buscada na tabela SH1 e não mais ZAZ.
// 07/06/2019 - Andre   - Adicionado campos D3_VATURNO e D3_VADTPRD.
// 22/10/2020 - Cláudia - Ajuste de formatação de data. GLPI: 8694
//
//
// --------------------------------------------------------------------------
User Function VA_XLS4 (_lAutomat)
	Local cCadastro := "Exportacao de saldos em estoque para o Excel"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	u_logID ()

	Private cPerg   := "VAXLS4"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo exportar producao em litros")
		AADD(aSays,"para planilha eletronica")
		AADD(aSays,"")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons)
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return
//
// --------------------------------------------------------------------------
// Tudo OK
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet	
//
// --------------------------------------------------------------------------
// Gera os dados
Static Function _Gera()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _nRecCount := 0
	local _lContinua := .T.

	procregua (10)
	incproc ("Buscando dados")
	
	// Monta clausula 'where' em separado para poder usar em duas queries diferentes.
	if _lContinua
		_sQuery := ""
		_sQuery += " SELECT D3_OP as OP, D3_COD as Produto, B1_DESC as Descri, D3_UM as Un_medida,"
		_sQuery +=        " isnull ((select H1_DESCRI "
		_sQuery +=                   " from " + RetSQLName ("SH1") + " SH1 "
		_sQuery +=                  " WHERE SH1.D_E_L_E_T_ != '*'"
		_sQuery +=                    " and SH1.H1_FILIAL  = '" + xfilial ("SH1") + "'"
		_sQuery +=                    " and SH1.H1_CODIGO  = B1_VALINEN), '') AS LINHA_ENVASE,"
		_sQuery +=        " D3_QUANT as Qt_produzida, D3_QUANT * B1_LITROS as Litros_produzidos,"
		_sQuery +=        " D3_PERDA as Qt_perda, D3_PERDA * B1_LITROS as Litros_perda,"
		_sQuery +=        " D3_EMISSAO as Dt_Movto, D3_VADTINC AS Dt_digitacao, D3_VAHRINC as Hr_digitacao,"
		_sQuery +=        " D3_VATURNO AS Turno, D3_VADTPRD AS Dt_Prd, D3_USUARIO as Usuario"
		_sQuery +=   " from " + RetSQLName ("SD3") + " SD3, "
		_sQuery +=              RetSQLName ("SB1") + " SB1 "
		_sQuery +=  " WHERE SB1.D_E_L_E_T_  != '*'"
		_sQuery +=    " and SB1.B1_FILIAL    = '" + xfilial ("SB1") + "'"
		_sQuery +=    " and SB1.B1_CODLIN    between '" + mv_par03 + "' and '" + mv_par04 + "'"
		_sQuery +=    " and SB1.B1_TIPO      between '" + mv_par01 + "' and '" + mv_par02 + "'"
		_sQuery +=    " and SB1.B1_COD       = D3_COD"
		_sQuery +=    " and SD3.D_E_L_E_T_ != '*'"
		_sQuery +=    " and SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
		_sQuery +=    " and SD3.D3_COD       between '" + mv_par05 + "' and '" + mv_par06 + "'"
		_sQuery +=    " and SD3.D3_OP        between '" + mv_par09 + "' and '" + mv_par10 + "'"
		_sQuery +=    " and SD3.D3_EMISSAO   between '" + dtos (mv_par07) + "' and '" + dtos (mv_par08) + "'"
		_sQuery +=    " and SD3.D3_CF      LIKE 'PR%'"
		_sQuery +=    " and SD3.D3_ESTORNO != 'S'"
		u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		TCSetField (alias (), "Dt_Prd", "D")
		TCSetField (alias (), "Dt_Movto", "D")
		TCSetField (alias (), "Dt_digitacao", "D")
		count to _nRecCount
		if _nRecCount == 0
			u_help ("Nao ha dados gerados. Verifique parametros!")
		else
			procregua (_nRecCount)
			incproc ("Gerando arquivo de exportacao")
			DbGoTop()
			processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		endif
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SD2")
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Tipo Produto Inicial         ?", "C", 2,  0,  "",   "02 ", {},    ""})
	aadd (_aRegsPerg, {02, "Tipo Produto Final           ?", "C", 2,  0,  "",   "02 ", {},    ""})
	aadd (_aRegsPerg, {03, "Linha Inicial                ?", "C", 2,  0,  "",   "88 ", {},    ""})
	aadd (_aRegsPerg, {04, "Linha Final                  ?", "C", 2,  0,  "",   "88 ", {},    ""})
	aadd (_aRegsPerg, {05, "Produto Inicial              ?", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {06, "Produto Final                ?", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {07, "Data inicial                 ?", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {08, "Data final                   ?", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {09, "OP Inicial                   ?", "C", 13, 0,  "",   "SC2", {},    ""})
	aadd (_aRegsPerg, {10, "OP Final                     ?", "C", 13, 0,  "",   "SC2", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
