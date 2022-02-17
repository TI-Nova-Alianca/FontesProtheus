// Programa...: VA_XLS31
// Autor......: Robert Koch
// Data.......: 16/05/2017
// Descricao..: Exporta planilha com mapa de tanques (estoque / endereco / laudo)
//
// Historico de alteracoes:
// 17/10/2017 - Robert         - Ajustados nomes de colunas (entendia g/ml como uma formula, eu acho).
// 14/03/2018 - Robert         - Incluida coluna de composicao de safras do laudo
// 28/08/2019 - Cláudia        - Incluída a coluna CODIGO_CR, campo B8_VACRSIS
// 13/11/2019 - Robert         - Melhorados titulos das colunas.
// 30/01/2020 - Cláudia        - Incluida coluna de saldo de pedidos, conforme GLPI 7423
// 04/02/2020 - Claudia        - Incluida a soma do saldo dos pedidos.
// 17/02/2022 - Claudia/Sandra - Incluso campo validade, conforme chamado CLPI 11510
// 
// --------------------------------------------------------------------------
User Function VA_XLS31 (_lAutomat)
	Local cCadastro := "Exporta mapa de estoques a granel"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS31"
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

	// Monta lista dos tanques com saldo
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT BF_FILIAL AS FILIAL, BF_LOCAL AS ALMOX, BF_LOCALIZ AS TANQUE,"
	_oSQL:_sQuery +=        " BF_PRODUTO AS PRODUTO, RTRIM (B1_DESC) AS DESCRICAO, BF_LOTECTL AS LOTE, B8_DTVALID AS VALIDADE,"
	_oSQL:_sQuery +=        " BF_QUANT AS [ESTQ_ATUAL_TANQUE],"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_STATUS") + " AS [STATUS_TANQUE], "
	_oSQL:_sQuery +=        " ISNULL (" + _oSQL:CaseX3CBox ("B8_VADESTI") + ", '') AS [DESTINACAO_LOTE], "
	_oSQL:_sQuery +=        " ISNULL (" + _oSQL:CaseX3CBox ("B8_VASTVEN") + ", '') AS [STATUS_VENDA_LOTE], "
	_oSQL:_sQuery +=        " B8_VACLIEN + '/' + B8_VALOJA + '-' + RTRIM (ISNULL (A1_NOME, '')) AS [CLIENTE],"
	_oSQL:_sQuery +=        " B8_VACRSIS AS [CODIGO_CR]," 
	_oSQL:_sQuery +=        " ISNULL((SELECT TOP 1 ZAF_ENSAIO"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("ZAF") + " ZAF "
	_oSQL:_sQuery +=                 " WHERE ZAF.D_E_L_E_T_ = ''" 
	_oSQL:_sQuery +=                   " AND ZAF.ZAF_FILIAL = SBF.BF_FILIAL"
	_oSQL:_sQuery +=                   " AND ZAF.ZAF_PRODUT = SBF.BF_PRODUTO"
	_oSQL:_sQuery +=                   " AND ZAF.ZAF_LOTE   = SBF.BF_LOTECTL"
	_oSQL:_sQuery +=                   " AND ZAF.ZAF_DATA  <= '" + dtos (dDataBase) + "'"
	_oSQL:_sQuery +=                   " AND ZAF.ZAF_VALID >= '" + dtos (dDataBase) + "'"
	_oSQL:_sQuery +=                   " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                                     " FROM " + RetSQLName ("ZAF") + " MAIS_RECENTE "
	_oSQL:_sQuery +=                                    " WHERE MAIS_RECENTE.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                                      " AND MAIS_RECENTE.ZAF_FILIAL = ZAF.ZAF_FILIAL"
	_oSQL:_sQuery +=                                      " AND MAIS_RECENTE.ZAF_LOTE   = ZAF.ZAF_LOTE"
	_oSQL:_sQuery +=                                      " AND MAIS_RECENTE.ZAF_ENSAIO > ZAF.ZAF_ENSAIO)"
	_oSQL:_sQuery +=                  " ORDER BY ZAF.ZAF_ENSAIO DESC), '') AS ENSAIO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBF") + " SBF, "
	_oSQL:_sQuery +=              RetSQLName ("SB8") + " SB8 "
	_oSQL:_sQuery +=              " LEFT JOIN " + RetSQLName ("SA1") + " SA1"
	_oSQL:_sQuery +=                   " ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=                   " AND SA1.A1_COD     = SB8.B8_VACLIEN"
	_oSQL:_sQuery +=                   " AND SA1.A1_LOJA    = SB8.B8_VALOJA),"
	_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=              RetSQLName ("SBE") + " SBE "
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = SBF.BF_PRODUTO"
	_oSQL:_sQuery +=    " AND SBE.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SBE.BE_FILIAL  = SBF.BF_FILIAL"
	_oSQL:_sQuery +=    " AND SBE.BE_LOCAL   = SBF.BF_LOCAL"
	_oSQL:_sQuery +=    " AND SBE.BE_LOCALIZ = SBF.BF_LOCALIZ"
	_oSQL:_sQuery +=    " AND SBE.BE_VATANQ  = 'S'"
	_oSQL:_sQuery +=    " AND SB8.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB8.B8_FILIAL  = SBF.BF_FILIAL"
	_oSQL:_sQuery +=    " AND SB8.B8_LOCAL   = SBF.BF_LOCAL"
	_oSQL:_sQuery +=    " AND SB8.B8_PRODUTO = SBF.BF_PRODUTO"
	_oSQL:_sQuery +=    " AND SB8.B8_LOTECTL = SBF.BF_LOTECTL"
	_oSQL:_sQuery +=    " AND SBF.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SBF.BF_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=    " AND SBF.BF_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery +=    " AND SUBSTRING (SBF.BF_LOCALIZ, 4, 4) BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND SBF.BF_QUANT != 0"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT " //C.*,"
	_oSQL:_sQuery +=        "  C.FILIAL,"
	_oSQL:_sQuery +=        " C.ALMOX,"
	_oSQL:_sQuery +=        " C.TANQUE,"
	_oSQL:_sQuery +=        " C.PRODUTO,"
	_oSQL:_sQuery +=        " C.DESCRICAO,"
	_oSQL:_sQuery +=        " C.LOTE,"
	_oSQL:_sQuery +=        " CONVERT(VARCHAR, SUBSTRING(C.VALIDADE, 7, 2) + '/' + SUBSTRING(C.VALIDADE, 5, 2) + '/' + LEFT(C.VALIDADE, 4), 110) AS VALIDADE,"
	_oSQL:_sQuery +=        " C.ESTQ_ATUAL_TANQUE,"
	_oSQL:_sQuery +=        " SUM(ISNULL(C6_QTDVEN - C6_QTDENT,0)) AS [SALDO_PEDVENDAS],"
	_oSQL:_sQuery +=        " C.STATUS_TANQUE,"
	_oSQL:_sQuery +=        " C.DESTINACAO_LOTE,"
	_oSQL:_sQuery +=        " C.STATUS_VENDA_LOTE,"
	_oSQL:_sQuery +=        " C.CLIENTE,"
	_oSQL:_sQuery +=        " C.CODIGO_CR,"
	_oSQL:_sQuery +=        " C.ENSAIO,"
	_oSQL:_sQuery +=        " dbo.VA_DTOC (ISNULL (ZAF_DATA, '')) AS [DATA_ENSAIO],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_ESTQ,   0) AS [ESTQ_ENSAIADO],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_ACTOT,  0) AS [ACIDEZ_TOTAL],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_ACVOL,  0) AS [ACIDEZ_VOLATIL],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_ACRED,  0) AS [ACUCARES_REDUTORES],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_ALCOOL, 0) AS [ALCOOL],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_DENSID, 0) AS [DENSIDADE],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_EXTRSE, 0) AS [EXTRATO_SECO],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_SO2LIV, 0) AS [SO2_LIVRE],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_SO2TOT, 0) AS [SO2_TOTAL],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_BRIX,   0) AS [BRIX],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_PH,     0) AS [pH],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_TURBID, 0) AS [TURBIDEZ],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_COR420, 0) AS [COR_420],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_COR520, 0) AS [COR_520],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_COR620, 0) AS [COR_620],"
	_oSQL:_sQuery +=        " ISNULL ((ISNULL (ZAF_COR420, 0) + ISNULL (ZAF_COR520, 0) + ISNULL (ZAF_COR620, 0)), 0) AS [INTENSIDADE],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_BOLOR,  0) AS [BOLORES],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_COLIF,  0) AS [COLIFORMES_TOTAIS],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_COR,    0) AS [COR],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_SABOR,  0) AS [SABOR],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_AROMA,  0) AS [AROMA],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_CRQRES, '') AS [CRQ_RESPONS],"
	_oSQL:_sQuery +=        " dbo.VA_DTOC (ISNULL (ZAF_VALID, '')) AS VALIDADE,"
	_oSQL:_sQuery +=        " ISNULL (ZAF_OBS, '') AS [OBSERVACAO],"
	_oSQL:_sQuery +=        " ISNULL (ZAF_SAFRA1 + '(' + RTRIM (CAST (ZAF_PSAFR1 AS NCHAR)) + '%)' +"
	_oSQL:_sQuery +=                " CASE WHEN ZAF_SAFRA2 = '' THEN '' ELSE ';' + ZAF_SAFRA2 + '(' + RTRIM (CAST (ZAF_PSAFR2 AS NCHAR)) + '%)' END +"
	_oSQL:_sQuery +=                " CASE WHEN ZAF_SAFRA3 = '' THEN '' ELSE ';' + ZAF_SAFRA3 + '(' + RTRIM (CAST (ZAF_PSAFR3 AS NCHAR)) + '%)' END +"
	_oSQL:_sQuery +=                " CASE WHEN ZAF_SAFRA4 = '' THEN '' ELSE ';' + ZAF_SAFRA4 + '(' + RTRIM (CAST (ZAF_PSAFR4 AS NCHAR)) + '%)' END, '') AS SAFRA,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("ZAF_STOPER") + " AS [SIT_OPERACIONAL_LAUDO], "
	_oSQL:_sQuery +=        " ISNULL (ZAF_CLASS, '') AS [CLASSIF_LAUDO],"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("ZAF_PADRAO") + " AS [PADRAO_LAUDO], "
	_oSQL:_sQuery +=        " ISNULL (ZAF_ACETAL, '') AS [ACETALDEIDO]"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery +=   " LEFT JOIN " + RetSQLName ("ZAF") + " ZAF"
	_oSQL:_sQuery +=        " ON (ZAF.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND ZAF.ZAF_FILIAL = C.FILIAL"
	_oSQL:_sQuery +=        " AND ZAF.ZAF_ENSAIO = C.ENSAIO)"
	_oSQL:_sQuery +=   " LEFT JOIN " + RetSQLName ("SC6") + " SC6"
	_oSQL:_sQuery +=        " ON(SC6.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND SC6.C6_PRODUTO = PRODUTO"
	_oSQL:_sQuery +=        " AND SC6.C6_QTDVEN - SC6.C6_QTDENT > 0"
	_oSQL:_sQuery +=        " AND SC6.C6_LOTECTL = LOTE"
	_oSQL:_sQuery +=        " AND SC6.C6_LOCALIZ = TANQUE
	_oSQL:_sQuery +=        " AND SC6.C6_BLQ = '')"
	_oSQL:_sQuery += " GROUP BY C.FILIAL,C.ALMOX,C.TANQUE,C.PRODUTO,C.DESCRICAO,C.LOTE, C.VALIDADE,C.ESTQ_ATUAL_TANQUE,C.STATUS_TANQUE,C.DESTINACAO_LOTE,C.STATUS_VENDA_LOTE,C.CLIENTE,C.CODIGO_CR,C.ENSAIO"
    _oSQL:_sQuery += " ,ZAF_DATA,ZAF_ESTQ,ZAF_ACTOT,ZAF_ACVOL,ZAF_ACRED,ZAF_ALCOOL,ZAF_DENSID,ZAF_EXTRSE,ZAF_SO2LIV,ZAF_SO2TOT,ZAF_BRIX,ZAF_PH,ZAF_TURBID,ZAF_COR420,ZAF_COR520"
    _oSQL:_sQuery += " ,ZAF_COR620,ZAF_COR420,ZAF_BOLOR,ZAF_COLIF,ZAF_COR,ZAF_SABOR,ZAF_AROMA,ZAF_CRQRES,ZAF_VALID,ZAF_OBS,ZAF_SAFRA1,ZAF_PSAFR1,ZAF_SAFRA2,ZAF_PSAFR2,ZAF_SAFRA3"
    _oSQL:_sQuery += " ,ZAF_PSAFR3,ZAF_SAFRA4,ZAF_PSAFR4,ZAF_STOPER,ZAF_CLASS,ZAF_PADRAO,ZAF_ACETAL"
	_oSQL:_sQuery +=  " ORDER BY FILIAL, ALMOX, TANQUE, PRODUTO"
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))

//	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 02, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 02, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {03, "Numero tanque inicial         ", "C", 4,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {04, "Numero tanque final           ", "C", 4,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {}, ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 15, 0,  "",   "SB1", {}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
