// Programa:  VA_XLS41
// Descricao: Exporta planilha com detalhamento das medicoes de grau.
// Autor:     Robert Koch
// Data:      04/03/2019
//
// Historico de alteracoes:
// 19/02/2020 - Robert - Passa a buscar medicoes no database BL01 (agora temos importacao automatica dos dados da Maselli).
//

// --------------------------------------------------------------------------
user function VA_XLS41 (_lAutomat)
	Local cCadastro := "Exportacao de planilha com amostras de medicao de grau safra"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para ver valores.
	if ! U_ZZUVL ('045', __cUserID, .F., cEmpAnt, cFilAnt)
		u_help ("Usuario sem liberacao para esta rotina.")
		return
	endif

	Private cPerg   := "VAXLS41"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de planilha com as amostras colhidas pelo")
		AADD(aSays,"sistema de medicao de grau da uva no recebimento de safra.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet


	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	u_logId ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery +=  "SELECT ZAN.ZAN_COD, ZAN.ZAN_DESCRI, C.FILIAL, C.SAFRA, C.CARGA, C.ASSOCIADO, C.LOJA_ASSOC, C.NOME_ASSOC, C.PRODUTO, C.DESCRICAO,"
    _oSQL:_sQuery +=        " C.CLAS_ABD AS CLAS_LATADA, C.CLAS_FINAL AS CLAS_ESPALDEIRA,""
    _oSQL:_sQuery +=        " CAST (C.GRAU AS FLOAT) AS GRAU_FINAL,"
	_oSQL:_sQuery +=        " ISNULL (ZZA.ZZA_INIST1,'') AS HORA_PRIM_PESAGEM, ISNULL (ZZA.ZZA_INIST2,'') AS HORA_SELECION_PARA_DESCARGA, ISNULL (ZZA.ZZA_INIST3,'') AS HORA_ARMAZENAMENTO_GRAU,"
	_oSQL:_sQuery +=        " ISNULL (SAMPLES.SAMPLE, 0) AS AMOSTRA, ISNULL (SAMPLES.RESULT, 0) AS RESULT"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZAN") + " ZAN, "
	_oSQL:_sQuery +=              RetSQLName ("ZAK") + " ZAK, "
	_oSQL:_sQuery +=              " VA_VCARGAS_SAFRA C"
	_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("ZZA") + " ZZA "
	_oSQL:_sQuery +=            " ON (ZZA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=            " AND ZZA.ZZA_FILIAL = C.FILIAL AND ZZA.ZZA_SAFRA = C.SAFRA AND ZZA.ZZA_CARGA = C.CARGA AND ZZA.ZZA_PRODUT = C.ITEMCARGA)"
	_oSQL:_sQuery +=       " LEFT JOIN BL01.dbo.SQL_BL01_SAMPLES AS SAMPLES"
	_oSQL:_sQuery +=            " ON (SAMPLES.ZZA_FILIAL = C.FILIAL AND SAMPLES.ZZA_SAFRA = C.SAFRA AND SAMPLES.ZZA_CARGA = C.CARGA AND SAMPLES.ZZA_PRODUT = C.ITEMCARGA)"
	_oSQL:_sQuery +=  " WHERE ZAN.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZAN.ZAN_FILIAL = '  '"
	_oSQL:_sQuery +=    " AND ZAK.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZAK.ZAK_FILIAL = '  '"
	_oSQL:_sQuery +=    " AND ZAK.ZAK_IDZAN = ZAN.ZAN_COD"
	_oSQL:_sQuery +=    " AND C.ASSOCIADO = ZAK.ZAK_ASSOC"
	_oSQL:_sQuery +=    " AND C.ASSOCIADO + C.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND C.SAFRA = '" + mv_par05 + "'"
	_oSQL:_sQuery +=    " AND ZAN_COD BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	_oSQL:_sQuery +=    " AND C.FILIAL BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
	_oSQL:_sQuery +=    " AND C.CARGA BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	_oSQL:_sQuery +=    " AND C.DATA BETWEEN '" + dtos (mv_par12) + "' AND '" + dtos (mv_par13) + "'"
//	_oSQL:_sQuery +=  " ORDER BY C.FILIAL, C.SAFRA, C.CARGA, C.ITEMCARGA, SZS.ZS_DATA, SZS.ZS_HORA" 
	_oSQL:_sQuery +=  " ORDER BY C.FILIAL, C.SAFRA, C.CARGA, C.ITEMCARGA, SAMPLES.SAMPLE"
    _oSQL:Log ()
    _oSQL:Qry2XLS (.F., .F., .T.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,             0,            "",   "SA2",  {},                                            ""})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,             0,            "",   "SA2",  {},                                            ""})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {06, "Grupo familiar inicial        ", "C", 6,             0,            "",   "ZAN",  {},                                            ""})
	aadd (_aRegsPerg, {07, "Grupo familiar final          ", "C", 6,             0,            "",   "ZAN",  {},                                            ""})
	aadd (_aRegsPerg, {08, "Filial inicial                ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {09, "Filial final                  ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {10, "Carga inicial                 ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {11, "Carga final                   ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {12, "Data recebimento inicial      ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {13, "Data recebimento final        ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
