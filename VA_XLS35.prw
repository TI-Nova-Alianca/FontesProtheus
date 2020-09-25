// Programa...: VA_XLS35
// Autor......: Robert Koch
// Data.......: 27/03/2018
// Descricao..: Exporta planilha com dados de cargas recebidas na safra.
//
// Historico de alteracoes:
// 19/03/2019 - Robert - Liberado a todos os usuarios (antes era apenas para o grupo 045)
// 21/02/2020 - Robert - Removida tabela SZ9 da query (vai ser descontinuada).
//

// --------------------------------------------------------------------------
User Function VA_XLS35 (_lAutomat)
	Local cCadastro := "Exporta cargas de recebimento de safra"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS35"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
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
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT V.*,"
	_oSQL:_sQuery +=        " PROPRIEDADE.ZA8_DESCRI AS DESCR_PROPRIEDADE,"
	_oSQL:_sQuery +=        " PROPRIEDADE.ZA8_STATUS as STATUS_PROPRIEDADE,"
	_oSQL:_sQuery +=        " PROPRIEDADE.ZA8_KMF01 AS DISTANCIA_FILIAL01,"
	_oSQL:_sQuery +=        " PROPRIEDADE.ZA8_KMF03 AS DISTANCIA_FILIAL03,"
	_oSQL:_sQuery +=        " PROPRIEDADE.ZA8_KMF07 AS DISTANCIA_FILIAL07"
//	_oSQL:_sQuery +=        " TALHOES.Z9_DESCRI,"
//	_oSQL:_sQuery +=        " TALHOES.Z9_AREA,"
//	_oSQL:_sQuery +=        " TALHOES.Z9_STATUS,"
//	_oSQL:_sQuery +=        " TALHOES.Z9_SUSTENT"
	_oSQL:_sQuery +=   " FROM VA_VCARGAS_SAFRA V"
	_oSQL:_sQuery +=     " LEFT JOIN (SELECT ZA8.ZA8_COD, ZA8.ZA8_DESCRI, ZA8.ZA8_CODMUN, ZA8.ZA8_STATUS, ZA8.ZA8_KMF01, ZA8.ZA8_KMF03, ZA8.ZA8_KMF07" //, SZ9.Z9_SEQ, SZ9.Z9_DESCRI, SZ9.Z9_AREA, SZ9.Z9_STATUS, SZ9.Z9_SUSTENT"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("ZA8") + " ZA8 "
//	_oSQL:_sQuery +=                             RetSQLName ("SZ9") + " SZ9 "
	_oSQL:_sQuery +=                 " WHERE " //SZ9.D_E_L_E_T_ = ''"
//	_oSQL:_sQuery +=                   " AND SZ9.Z9_FILIAL  = ZA8.ZA8_FILIAL"
//	_oSQL:_sQuery +=                   " AND SZ9.Z9_IDZA8   = ZA8.ZA8_COD"
	_oSQL:_sQuery +=                   " ZA8.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND ZA8.ZA8_FILIAL = '" + xfilial ("ZA8") + "') AS PROPRIEDADE"
	_oSQL:_sQuery +=        " ON (PROPRIEDADE.ZA8_COD = V.PROPR_RURAL)" // AND TALHOES.Z9_SEQ = V.TALHAO)"
	_oSQL:_sQuery += " WHERE SAFRA        = '" + mv_par05 + "'"
	_oSQL:_sQuery +=   " AND AGLUTINACAO != 'O'"
	_oSQL:_sQuery +=   " AND CARGA       BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
	_oSQL:_sQuery +=   " AND NF_PRODUTOR BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
	_oSQL:_sQuery +=   " AND FILIAL      BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	_oSQL:_sQuery +=   " AND ASSOCIADO + LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	if mv_par10 == 1
		_oSQL:_sQuery += " AND VARUVA = 'C'"
	elseif mv_par10 == 2
		_oSQL:_sQuery += " AND VARUVA = 'F'"
	endif
	if mv_par13 == 1
		_oSQL:_sQuery += " AND STATUS != 'C'"
		_oSQL:_sQuery += " AND STATUS != 'D'"
	endif
	_oSQL:_sQuery += " ORDER BY CARGA, ITEMCARGA"
	_oSQL:Log ()
	_oSQL:Qry2Xls ()
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,             0,            "",   "SA2",  {},                                            "Codigo do produtor (fornecedor) inicial para filtragem"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,             0,            "",   "   ",  {},                                            "Loja do produtor (fornecedor) inicial para filtragem"})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,             0,            "",   "SA2",  {},                                            "Codigo do produtor (fornecedor) final para filtragem"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,             0,            "",   "   ",  {},                                            "Loja do produtor (fornecedor) final para filtragem"})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,             0,            "",   "   ",  {},                                            "Safra (ano) para filtragem"})
	aadd (_aRegsPerg, {06, "Filial inicial                ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {07, "Filial final                  ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {08, "Carga inicial                 ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {09, "Carga final                   ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {10, "Comum / vinifera              ", "N", 1,             0,            "",   "   ",  {"Comuns", "Viniferas", "Todas"},              ""})
	aadd (_aRegsPerg, {11, "NF produtor inicial           ", "C", 9,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {12, "NF produtor final             ", "C", 9,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {13, "Canceladas / redirecionadas   ", "N", 1,             0,            "",   "   ",  {"Ignorar", "Listar"},                         ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
