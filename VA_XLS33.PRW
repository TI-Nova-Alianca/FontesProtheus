// Programa...: VA_XLS33
// Autor......: Robert Koch
// Data.......: 20/12/2017
// Descricao..: Exporta planilha para conferencia de agrupamentos de precos de uvas.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS33 (_lAutomat)
	Local cCadastro := "Exporta planilha para conferencia de agrupamentos de precos de uvas"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('051', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	Private cPerg   := "VAXLS33"
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

	// Monta lista dos tanques.
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT SZ1.Z1_CODPRD,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '07.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU07,"  // Ajustar aqui se precisar graus menores
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '08.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU08,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '09.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU09,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '10.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU10,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '11.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU11,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '12.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU12,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '13.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU13,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '14.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU14,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '15.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU15,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '16.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU16,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '17.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU17,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '18.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU18,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '19.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU19,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '20.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU20,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '21.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU21,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '22.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU22,"
	_oSQL:_sQuery +=        " MAX (CASE WHEN SZ1.Z1_GRAU = '23.0' THEN " + iif (mv_par02 == 1, "Z1_PRCREC", "Z1_PRCCOM") + " ELSE 0 END) AS GRAU23"    // Ajustar aqui se precisar graus maiores
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZ1") + " SZ1 "
	_oSQL:_sQuery += " WHERE SZ1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SZ1.Z1_TABELA  = '" + mv_par01 + "'"
	//_oSQL:_sQuery +=  " AND SZ1.Z1_CODPRD IN (SELECT DISTINCT PRODUTO FROM VA_VNOTAS_SAFRA WHERE SAFRA = '2017' AND TIPO_NF = 'E' and TIPO_ORGANICO NOT IN ('B', 'E', 'O'))"
	_oSQL:_sQuery += " GROUP BY SZ1.Z1_CODPRD"
	_oSQL:_sQuery +=  " ), G1 AS ("
	_oSQL:_sQuery +=  " SELECT DISTINCT GRAU07, GRAU08, GRAU09, GRAU10, GRAU11, GRAU12, GRAU13, GRAU14, GRAU15, GRAU16, GRAU17, GRAU18, GRAU19, GRAU20, GRAU21, GRAU22, GRAU23"
	_oSQL:_sQuery +=  " FROM C"
	_oSQL:_sQuery +=  " ), GRUPOS AS ("
	_oSQL:_sQuery +=  " SELECT ROW_NUMBER () OVER (ORDER BY GRAU07, GRAU08, GRAU09, GRAU10, GRAU11, GRAU12, GRAU13, GRAU14, GRAU15, GRAU16, GRAU17, GRAU18, GRAU19, GRAU20, GRAU21, GRAU22, GRAU23) AS AGRUP, *"
	_oSQL:_sQuery +=  " FROM G1),"
	_oSQL:_sQuery +=  " FINAL AS ("
	_oSQL:_sQuery +=  " SELECT CASE WHEN B1_VARUVA = 'C' THEN 'COMUNS'"
	_oSQL:_sQuery +=         " ELSE CASE WHEN B1_VAFCUVA = 'F' THEN 'FINAS_LIVRAMENTO'"
	_oSQL:_sQuery +=         " ELSE 'FINAS_SERRA'"
	_oSQL:_sQuery +=         " END END AS FORMA_CLASSIF,"
	_oSQL:_sQuery +=         " B1_VACOR AS COR,"
	_oSQL:_sQuery +=         " SB1.B1_VATTR AS TINTOREA,"
	_oSQL:_sQuery +=         " Z1_CODPRD AS PRODUTO,"
	_oSQL:_sQuery +=         " RTRIM (SB1.B1_DESC) AS DESCRICAO,"
	_oSQL:_sQuery +=         " GRUPOS.*"
	_oSQL:_sQuery +=    " FROM GRUPOS, C, " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=   " WHERE SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=     " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=     " AND SB1.B1_COD     = C.Z1_CODPRD"
	_oSQL:_sQuery +=     " AND C.GRAU07 = GRUPOS.GRAU07"
	_oSQL:_sQuery +=     " AND C.GRAU08 = GRUPOS.GRAU08"
	_oSQL:_sQuery +=     " AND C.GRAU09 = GRUPOS.GRAU09"
	_oSQL:_sQuery +=     " AND C.GRAU10 = GRUPOS.GRAU10"
	_oSQL:_sQuery +=     " AND C.GRAU11 = GRUPOS.GRAU11"
	_oSQL:_sQuery +=     " AND C.GRAU12 = GRUPOS.GRAU12"
	_oSQL:_sQuery +=     " AND C.GRAU13 = GRUPOS.GRAU13"
	_oSQL:_sQuery +=     " AND C.GRAU14 = GRUPOS.GRAU14"
	_oSQL:_sQuery +=     " AND C.GRAU15 = GRUPOS.GRAU15"
	_oSQL:_sQuery +=     " AND C.GRAU16 = GRUPOS.GRAU16"
	_oSQL:_sQuery +=     " AND C.GRAU17 = GRUPOS.GRAU17"
	_oSQL:_sQuery +=     " AND C.GRAU18 = GRUPOS.GRAU18"
	_oSQL:_sQuery +=     " AND C.GRAU19 = GRUPOS.GRAU19"
	_oSQL:_sQuery +=     " AND C.GRAU20 = GRUPOS.GRAU20"
	_oSQL:_sQuery +=     " AND C.GRAU21 = GRUPOS.GRAU21"
	_oSQL:_sQuery +=     " AND C.GRAU22 = GRUPOS.GRAU22"
	_oSQL:_sQuery +=     " AND C.GRAU23 = GRUPOS.GRAU23"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM FINAL"
	_oSQL:_sQuery +=  " WHERE GRAU07 + GRAU08 + GRAU09 + GRAU10 + GRAU11 + GRAU12 + GRAU13 + GRAU14 + GRAU15 + GRAU16 + GRAU17 + GRAU18 + GRAU19 + GRAU20 + GRAU21 + GRAU22 + GRAU23 != 0"  // Nao traz os sem preco
	_oSQL:_sQuery +=  " ORDER BY FORMA_CLASSIF, AGRUP, DESCRICAO"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Tabela de precos              ", "C", 6, 0,  "",   "SZA", {}, ""})
	aadd (_aRegsPerg, {02, "Qual preco                    ", "N", 1, 0,  "",   "",    {"Entrada", "Compra"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
