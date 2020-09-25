// Programa...: VA_XLS36
// Autor......: Robert Koch
// Data.......: 19/07/2018
// Descricao..: Exporta planilha com entradas e saidas (kardex) de itens no estoque.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS36 (_lAutomat)
	Local cCadastro := "Exporta planilha com entradas e saidas de estoque + variacao de custo."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS36"
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
	local _oSQL      := NIL
	local _lContinua := .T.
	local _dDataIni  := ctod ('')
	local _dDataFim  := ctod ('')

	u_help ("ATENCAO: Para analise das colunas QT_FINAL, VLR_FINAL, UNIT_FINAL e VARIACAO, este programa deve ser executado apos a execucao do recalculo do custo medio.")

	if _lContinua .and. empty (mv_par01)
		u_help ("Deve ser informada uma data valida de fechamento de estoque")
		_lContinua = .F.
	endif
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB9") + " SB9"
		_oSQL:_sQuery += " WHERE SB9.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SB9.B9_FILIAL   = '" + xfilial ("SB9") + "'"
		_oSQL:_sQuery +=   " AND SB9.B9_DATA     = '" + dtos (mv_par01) + "'"
		if _oSQL:RetQry () == 0
			u_help ("Nao foi encontrado nenhum fechamento de estoque na data informada.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (10)
		incproc ("Gerando arquivo de exportacao")

		_dDataIni = mv_par01 + 1
		_dDataFim = lastday (_dDataIni)

		// Monta lista dos tanques.
		incproc ("Buscando dados")
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " WITH C AS"
		_oSQL:_sQuery += " (SELECT"
		_oSQL:_sQuery += "   B1_TIPO"
		_oSQL:_sQuery += "     ,B1_COD"
		_oSQL:_sQuery += "     ,B1_DESC"
		_oSQL:_sQuery += "     ,B1_UM"
		_oSQL:_sQuery += "     ,ROUND(SUM(B9_QINI), 2) AS QT_INICIAL"
		_oSQL:_sQuery += "     ,ROUND(SUM(B9_VINI1), 2) AS VLR_INICIAL"
		_oSQL:_sQuery += "     ,ISNULL(ROUND(SUM(D1.ENT_SD1), 2), 0) AS ENT_SD1"
		_oSQL:_sQuery += "     ,ISNULL(ROUND(SUM(D2.SAI_SD2), 2), 0) AS SAI_SD2"
		_oSQL:_sQuery += "     ,ISNULL(ROUND(SUM(D3.ENT_SD3), 2), 0) AS ENT_SD3"
		_oSQL:_sQuery += "     ,ISNULL(ROUND(SUM(D3.SAI_SD3), 2), 0) AS SAI_SD3"
		_oSQL:_sQuery += "     ,ROUND(SUM(B2_QFIM), 2) AS QT_FINAL"
		_oSQL:_sQuery += "     ,ROUND(SUM(B2_VFIM1), 2) AS VLR_FINAL"
		_oSQL:_sQuery += "  FROM " + RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += "  LEFT JOIN (SELECT"
		_oSQL:_sQuery += "    D1_COD"
		_oSQL:_sQuery += "      ,SUM(D1_QUANT) AS ENT_SD1"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD1") + " SD1,"
		_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4"
		_oSQL:_sQuery += "   WHERE SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery += "   AND SD1.D1_DTDIGIT BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery += "   AND SF4.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
		_oSQL:_sQuery += "   AND SF4.F4_CODIGO = SD1.D1_TES"
		_oSQL:_sQuery += "   AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery += "   GROUP BY D1_COD) AS D1"
		_oSQL:_sQuery += "   ON (D1.D1_COD = SB1.B1_COD)"
		_oSQL:_sQuery += "  LEFT JOIN (SELECT"
		_oSQL:_sQuery += "    D3_COD"
		_oSQL:_sQuery += "      ,SUM(CASE"
		_oSQL:_sQuery += "     WHEN SD3.D3_TM < '5' THEN SD3.D3_QUANT"
		_oSQL:_sQuery += "     ELSE 0"
		_oSQL:_sQuery += "    END) AS ENT_SD3"
		_oSQL:_sQuery += "      ,SUM(CASE"
		_oSQL:_sQuery += "     WHEN SD3.D3_TM >= '5' THEN SD3.D3_QUANT"
		_oSQL:_sQuery += "     ELSE 0"
		_oSQL:_sQuery += "    END) AS SAI_SD3"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD3") + " SD3"
		_oSQL:_sQuery += "   WHERE SD3.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery += "   AND SD3.D3_ESTORNO != 'S'"
		_oSQL:_sQuery += "   AND SD3.D3_CF NOT IN ('RE4', 'DE4')"  // DESCONSIDERA TRANSFERENCIAS ENTRE ENDERECOS.
		_oSQL:_sQuery += "   AND SD3.D3_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery += "   GROUP BY D3_COD) AS D3"
		_oSQL:_sQuery += "   ON (D3.D3_COD = SB1.B1_COD)"
		_oSQL:_sQuery += "  LEFT JOIN (SELECT"
		_oSQL:_sQuery += "    D2_COD"
		_oSQL:_sQuery += "      ,SUM(D2_QUANT) AS SAI_SD2"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SD2") + " SD2, "
		_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4"
		_oSQL:_sQuery += "   WHERE SD2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   AND SD2.D2_FILIAL = '" + xfilial ("SD2") + "'"
		_oSQL:_sQuery += "   AND SD2.D2_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery += "   AND SF4.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
		_oSQL:_sQuery += "   AND SF4.F4_CODIGO = SD2.D2_TES"
		_oSQL:_sQuery += "   AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery += "   GROUP BY D2_COD) AS D2"
		_oSQL:_sQuery += "   ON (D2.D2_COD = SB1.B1_COD)"
		_oSQL:_sQuery += "  LEFT JOIN (SELECT"
		_oSQL:_sQuery += "    B9_COD"
		_oSQL:_sQuery += "      ,SUM(B9_QINI) AS B9_QINI"
		_oSQL:_sQuery += "      ,SUM(B9_VINI1) AS B9_VINI1"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SB9") + " SB9"
		_oSQL:_sQuery += "   WHERE SB9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "   AND (SB9.B9_QINI != 0"
		_oSQL:_sQuery += "   OR SB9.B9_VINI1 != 0)"
		_oSQL:_sQuery += "   AND SB9.B9_FILIAL = '" + xfilial ("SB9") + "'"
		_oSQL:_sQuery += "   AND SB9.B9_DATA = '" + dtos (mv_par01) + "'"
		_oSQL:_sQuery += "   GROUP BY B9_COD) AS B9"
		_oSQL:_sQuery += "   ON (B9.B9_COD = SB1.B1_COD)"
		_oSQL:_sQuery += "  LEFT JOIN (SELECT"
		_oSQL:_sQuery += "    B2_COD"
		_oSQL:_sQuery += "      ,SUM(B2_QFIM) AS B2_QFIM"
		_oSQL:_sQuery += "      ,SUM(B2_VFIM1) AS B2_VFIM1"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SB2") + " SB2"
		_oSQL:_sQuery += "   WHERE SB2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "   AND (SB2.B2_QFIM != 0"
		_oSQL:_sQuery += "   OR SB2.B2_VFIM1 != 0)"
		_oSQL:_sQuery += "   AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
		_oSQL:_sQuery += "   GROUP BY B2_COD) AS B2"
		_oSQL:_sQuery += "   ON (B2.B2_COD = SB1.B1_COD)"
		_oSQL:_sQuery += "  WHERE SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "  AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery += "  AND B1_TIPO NOT IN ('MO', 'AO', 'GF', 'AP')"
		_oSQL:_sQuery += "  GROUP BY B1_TIPO"
		_oSQL:_sQuery += "    ,B1_COD"
		_oSQL:_sQuery += "    ,B1_DESC"
		_oSQL:_sQuery += "    ,SB1.B1_UM),"
		_oSQL:_sQuery += " D"
		_oSQL:_sQuery += " AS"
		_oSQL:_sQuery += " (SELECT"
		_oSQL:_sQuery += "   B1_TIPO AS TIPO"
		_oSQL:_sQuery += "     ,B1_COD AS PRODUTO"
		_oSQL:_sQuery += "     ,B1_DESC AS DESCRICAO"
		_oSQL:_sQuery += "     ,B1_UM AS UM"
		_oSQL:_sQuery += "     ,QT_INICIAL"
		_oSQL:_sQuery += "     ,VLR_INICIAL"
		_oSQL:_sQuery += "     ,ROUND(VLR_INICIAL /"
		_oSQL:_sQuery += "          CASE QT_INICIAL"
		_oSQL:_sQuery += "           WHEN 0 THEN NULL"
		_oSQL:_sQuery += "           ELSE QT_INICIAL"
		_oSQL:_sQuery += "          END, 2) AS UNIT_INICIAL"
		_oSQL:_sQuery += "     ,ROUND(ENT_SD1 + ENT_SD3, 2) AS QT_ENTRADAS"
		_oSQL:_sQuery += "     ,ROUND(SAI_SD2 + SAI_SD3, 2) AS QT_SAIDAS"
		_oSQL:_sQuery += "     ,QT_FINAL"
		_oSQL:_sQuery += "     ,VLR_FINAL"
		_oSQL:_sQuery += "     ,ROUND(VLR_FINAL /"
		_oSQL:_sQuery += "        CASE QT_FINAL"
		_oSQL:_sQuery += "         WHEN 0 THEN NULL"
		_oSQL:_sQuery += "         ELSE QT_FINAL"
		_oSQL:_sQuery += "        END, 2) AS UNIT_FINAL"
		_oSQL:_sQuery += "  FROM C"
		_oSQL:_sQuery += "  WHERE QT_INICIAL IS NOT NULL"
		_oSQL:_sQuery += "  OR VLR_INICIAL IS NOT NULL"
		_oSQL:_sQuery += "  OR ENT_SD1 != 0"
		_oSQL:_sQuery += "  OR ENT_SD3 != 0"
		_oSQL:_sQuery += "  OR SAI_SD2 != 0"
		_oSQL:_sQuery += "  OR SAI_SD3 != 0"
		_oSQL:_sQuery += "  OR QT_FINAL IS NOT NULL"
		_oSQL:_sQuery += "  OR VLR_FINAL IS NOT NULL)"
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += "  D.*"
		_oSQL:_sQuery += "    ,ROUND(UNIT_FINAL * 100 /"
		_oSQL:_sQuery += "        CASE UNIT_INICIAL"
		_oSQL:_sQuery += "         WHEN 0 THEN NULL"
		_oSQL:_sQuery += "         ELSE UNIT_INICIAL"
		_oSQL:_sQuery += "        END - 100, 2) AS VARIACAO"
		_oSQL:_sQuery += " FROM D"
		_oSQL:_sQuery += " WHERE QT_INICIAL != 0"
		_oSQL:_sQuery += " OR VLR_INICIAL != 0"
		_oSQL:_sQuery += " OR QT_FINAL != 0"
		_oSQL:_sQuery += " OR VLR_FINAL != 0"
	//	_oSQL:_sQuery += " ORDER BY ABS(UNIT_FINAL * 100 / CASE UNIT_INICIAL WHEN 0 THEN NULL ELSE UNIT_INICIAL END - 100) DESC "
		_oSQL:_sQuery += " ORDER BY PRODUTO"
		_oSQL:Log ()
		_oSQL:Qry2XLS (.F., .F., .F.)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Fechto.estq.(p/saldo inicial) ", "D", 8, 0,  "",   "",    {}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
