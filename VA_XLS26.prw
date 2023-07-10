// Programa...: VA_XLS26
// Autor......: Robert Koch
// Data.......: 14/05/2015
// Descricao..: Exportacao de dados de OP para planilha.
//
// Historico de alteracoes:
// 29/05/2015 - Robert  - Criado parametro de exportacao de producoes/consumos/todos.
// 30/08/2017 - Robert  - Coluna TIPO_OP foi removida da view VA_VDADOS_OP.
// 28/02/2020 - Claudia - Incluido itens fantasmas, conforme GLPI ID 7558 
// 06/07/2023 - Robert  - Incluido campo LINHA_ENVASE (GLPI 8213)
//

// --------------------------------------------------------------------------
User Function VA_XLS26 (_lAutomat)
	Local cCadastro  := "Dados de OP"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg    := "VAXLS26"

	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"planilha excel com dados de ordens de producao.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch (cCadastro, aSays, aButtons)
		
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
	procregua (10)

	If mv_par11 == 1
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += " SELECT FILIAL, OP"
		_oSQL:_sQuery +=       ", dbo.VA_DTOC (DATA) AS DATA_MOVTO, TIPO_MOVTO, PROD_FINAL"
		_oSQL:_sQuery +=       ", DESC_PROD_FINAL, dbo.VA_DTOC (EMISSAO) AS EMISSAO_OP"
		_oSQL:_sQuery +=       ", dbo.VA_DTOC (ENCERRAMENTO) AS ENCER_OP"
		_oSQL:_sQuery +=       ", CODIGO, DESCRICAO, SUM(QUANT_REAL) AS QUANT_REAL"
		_oSQL:_sQuery +=       ", UN_MEDIDA, LOCAL AS ALMOX, TIPO_PRODUTO"
		_oSQL:_sQuery +=       ", SUM(LITROS) AS LITROS"
		_oSQL:_sQuery +=       ",ISNULL((SELECT H1_DESCRI"
		_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SH1") + " SH1 "
		_oSQL:_sQuery +=                " WHERE SH1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                  " AND SH1.H1_FILIAL = '" + xfilial ("SH1") + "'"
		_oSQL:_sQuery +=                  " AND SH1.H1_CODIGO = LINHA_ENVASE)"
		_oSQL:_sQuery +=       ", '') AS LINHA_ENVASE_REALIZADA"
		_oSQL:_sQuery +=   " FROM VA_VDADOS_OP"
		_oSQL:_sQuery +=  " WHERE FILIAL     BETWEEN '" + mv_par01        + "' AND '" + mv_par02        + "'"
		_oSQL:_sQuery +=    " AND DATA       BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
		_oSQL:_sQuery +=    " AND PROD_FINAL BETWEEN '" + mv_par05        + "' AND '" + mv_par06        + "'"
		_oSQL:_sQuery +=    " AND CODIGO     BETWEEN '" + mv_par07        + "' AND '" + mv_par08        + "'"
		_oSQL:_sQuery +=    " AND OP         BETWEEN '" + mv_par09        + "' AND '" + mv_par10        + "'"
		_oSQL:_sQuery +=    " AND SUBSTRING (OP, 7, 2) != 'OS'"
		_oSQL:_sQuery +=    " AND TIPO_MOVTO = 'P'"
		_oSQL:_sQuery +=  " GROUP BY FILIAL, OP, DATA, TIPO_MOVTO, PROD_FINAL, DESC_PROD_FINAL, EMISSAO, ENCERRAMENTO, CODIGO, DESCRICAO, UN_MEDIDA, LOCAL, TIPO_PRODUTO, LINHA_ENVASE"
		_oSQL:Log ('[' + procname () + ']')
		_oSQL:ArqDestXLS = 'VA_XLS26'
		_oSQL:Qry2XLS (.T., .F., .T.)

	Else

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += " WITH DADOS_OP (FILIAL, OP"
		_oSQL:_sQuery +=               ", DATA_MOVTO, TIPO_MOVTO, PROD_FINAL, DESC_PROD_FINAL"
		_oSQL:_sQuery +=               ", EMISSAO_OP, ENCER_OP, CODIGO, DESCRICAO, QUANT_REAL"
		_oSQL:_sQuery +=               ", UN_MEDIDA, ALMOX, TIPO_PRODUTO, LITROS, LINHA_ENVASE)"
		_oSQL:_sQuery += " AS"
		_oSQL:_sQuery += " (SELECT"
		_oSQL:_sQuery += "		FILIAL"
		_oSQL:_sQuery += "	   ,OP
		_oSQL:_sQuery += "	   ,DATA AS DATA_MOVTO"
		_oSQL:_sQuery += "	   ,TIPO_MOVTO"
		_oSQL:_sQuery += "	   ,PROD_FINAL"
		_oSQL:_sQuery += "	   ,DESC_PROD_FINAL"
		_oSQL:_sQuery += "	   ,EMISSAO AS EMISSAO_OP"
		_oSQL:_sQuery += "	   ,ENCERRAMENTO AS ENCER_OP"
		_oSQL:_sQuery += "	   ,CODIGO"
		_oSQL:_sQuery += "	   ,DESCRICAO"
		_oSQL:_sQuery += "	   ,SUM(QUANT_REAL) AS QUANT_REAL"
		_oSQL:_sQuery += "	   ,UN_MEDIDA"
		_oSQL:_sQuery += "	   ,LOCAL AS ALMOX"
		_oSQL:_sQuery += "	   ,TIPO_PRODUTO"
		_oSQL:_sQuery += "	   ,SUM(LITROS) AS LITROS"
		_oSQL:_sQuery += "	   ,LINHA_ENVASE"
		_oSQL:_sQuery += "	FROM VA_VDADOS_OP"
		_oSQL:_sQuery += "	WHERE FILIAL    BETWEEN '" + mv_par01        + "' AND '" + mv_par02        + "'"
		_oSQL:_sQuery += "	AND DATA 		BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
		_oSQL:_sQuery += "	AND PROD_FINAL  BETWEEN '" + mv_par05        + "' AND '" + mv_par06        + "'"
		_oSQL:_sQuery += "	AND CODIGO 		BETWEEN '" + mv_par07        + "' AND '" + mv_par08        + "'"
		_oSQL:_sQuery += "	AND OP 			BETWEEN '" + mv_par09        + "' AND '" + mv_par10        + "'"
		_oSQL:_sQuery += "	AND SUBSTRING (OP, 7, 2) != 'OS'"
		_oSQL:_sQuery += "	GROUP BY FILIAL"
		_oSQL:_sQuery += "			,OP"
		_oSQL:_sQuery += "			,DATA"
		_oSQL:_sQuery += "			,TIPO_MOVTO"
		_oSQL:_sQuery += "			,PROD_FINAL"
		_oSQL:_sQuery += "			,DESC_PROD_FINAL"
		_oSQL:_sQuery += "			,EMISSAO"
		_oSQL:_sQuery += "			,ENCERRAMENTO"
		_oSQL:_sQuery += "			,CODIGO"
		_oSQL:_sQuery += "			,DESCRICAO"
		_oSQL:_sQuery += "			,UN_MEDIDA"
		_oSQL:_sQuery += "			,LOCAL"
		_oSQL:_sQuery += "			,TIPO_PRODUTO"
		_oSQL:_sQuery += "			,LINHA_ENVASE"
		_oSQL:_sQuery += "	UNION ALL"
		_oSQL:_sQuery += "	SELECT"
		_oSQL:_sQuery += "		SC2.C2_FILIAL FILIAL"
		_oSQL:_sQuery += "	   ,SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN AS OP"
		_oSQL:_sQuery += "	   ,SC2.C2_EMISSAO AS DATA_MOVTO"
		_oSQL:_sQuery += "	   ,'F' AS TIPO_MOVTO"
		_oSQL:_sQuery += "	   ,SG1.G1_COD AS PROD_FINAL"
		_oSQL:_sQuery += "	   ,SB1PROD.B1_DESC AS DESC_PROD_FINAL"
		_oSQL:_sQuery += "	   ,SC2.C2_EMISSAO AS EMISSAO_OP"
		_oSQL:_sQuery += "	   ,SC2.C2_DATRF AS ENCER_OP"
		_oSQL:_sQuery += "	   ,SG1.G1_COMP AS CODIGO"
		_oSQL:_sQuery += "	   ,SB1.B1_DESC AS DESCRICAO"
		_oSQL:_sQuery += "	   ,SG1.G1_QUANT * SC2.C2_QUANT AS QUANT_REAL"
		_oSQL:_sQuery += "	   ,SB1.B1_UM AS UN_MEDIDA"
		_oSQL:_sQuery += "	   ,'' AS ALMOX"
		_oSQL:_sQuery += "	   ,SB1.B1_TIPO AS TIPO_PRODUTO"
		_oSQL:_sQuery += "	   ,0 AS LITROS"
		_oSQL:_sQuery += "	   ,SC2.C2_VALINEN AS LINHA_ENVASE"
		_oSQL:_sQuery += "	FROM " + RetSQLName ("SC2") + " SC2"
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SG1") + " SG1"
		_oSQL:_sQuery += "		ON ("
		_oSQL:_sQuery += "		SG1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "		AND SG1.G1_COD  BETWEEN '" + mv_par05 + "' AND '" + mv_par06  + "'"
		_oSQL:_sQuery += "		AND SG1.G1_COMP BETWEEN '" + mv_par07 + "' AND '" + mv_par08  + "'"
		_oSQL:_sQuery += "		AND G1_COD = SC2.C2_PRODUTO"
		_oSQL:_sQuery += "		AND G1_REVINI <= SC2.C2_REVISAO"
		_oSQL:_sQuery += "		AND G1_REVFIM >= SC2.C2_REVISAO)"
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "		AND B1_COD = SG1.G1_COMP"
		_oSQL:_sQuery += "		AND B1_FANTASM = 'S')"
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " SB1PROD"
		_oSQL:_sQuery += "		ON (SB1PROD.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "		AND SB1PROD.B1_COD = SG1.G1_COD)"
		_oSQL:_sQuery += "	WHERE SC2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	AND C2_FILIAL  BETWEEN '" + mv_par01        + "' AND '" + mv_par02        + "'"
		_oSQL:_sQuery += "	AND C2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
		_oSQL:_sQuery += "	AND C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		_oSQL:_sQuery += "	AND C2_ITEM != 'OS'"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += "	FILIAL"
		_oSQL:_sQuery += "   ,OP"
		_oSQL:_sQuery += "   ,CONVERT(VARCHAR, SUBSTRING(DATA_MOVTO, 7, 2) + '/' + SUBSTRING(DATA_MOVTO, 5, 2) + '/' + LEFT(DATA_MOVTO, 4), 110) AS DATA_MOVTO"
		_oSQL:_sQuery += "   ,TIPO_MOVTO"
		_oSQL:_sQuery += "   ,PROD_FINAL"
		_oSQL:_sQuery += "   ,DESC_PROD_FINAL"
		_oSQL:_sQuery += "   ,CONVERT(VARCHAR, SUBSTRING(EMISSAO_OP, 7, 2) + '/' + SUBSTRING(EMISSAO_OP, 5, 2) + '/' + LEFT(EMISSAO_OP, 4), 110) AS EMISSAO_OP"
		_oSQL:_sQuery += "   ,CONVERT(VARCHAR, SUBSTRING(ENCER_OP, 7, 2) + '/' + SUBSTRING(ENCER_OP, 5, 2) + '/' + LEFT(ENCER_OP, 4), 110) AS ENCER_OP"
		_oSQL:_sQuery += "   ,CODIGO"
		_oSQL:_sQuery += "   ,DESCRICAO"
		_oSQL:_sQuery += "   ,QUANT_REAL"
		_oSQL:_sQuery += "   ,UN_MEDIDA"
		_oSQL:_sQuery += "   ,ALMOX"
		_oSQL:_sQuery += "   ,TIPO_PRODUTO"
		_oSQL:_sQuery += "   ,LITROS"
		_oSQL:_sQuery += "   ,ISNULL((SELECT H1_DESCRI"
		_oSQL:_sQuery +=              " FROM " + RetSQLName ("SH1") + " SH1 "
		_oSQL:_sQuery +=             " WHERE SH1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=               " AND SH1.H1_FILIAL = '" + xfilial ("SH1") + "'"
		_oSQL:_sQuery +=               " AND SH1.H1_CODIGO = DADOS_OP.LINHA_ENVASE)"
		_oSQL:_sQuery +=     ", '') AS LINHA_ENVASE_REALIZADA"
		_oSQL:_sQuery += " FROM DADOS_OP"
		_oSQL:_sQuery += " ORDER BY FILIAL, OP, TIPO_MOVTO,CODIGO"
		_oSQL:Log ('[' + procname () + ']')
		_oSQL:ArqDestXLS = 'VA_XLS26'
		_oSQL:Qry2XLS (.T., .F., .T.)
	EndIf
Return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,  0,  "",   "SM0",    {},    ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,  0,  "",   "SM0",    {},    ""})
	aadd (_aRegsPerg, {03, "Data inicial                  ", "D", 8,  0,  "",   "",       {},    ""})
	aadd (_aRegsPerg, {04, "Data final                    ", "D", 8,  0,  "",   "",       {},    ""})
	aadd (_aRegsPerg, {05, "Produto (produzido) inicial   ", "C", 15, 0,  "",   "SB1",    {},    ""})
	aadd (_aRegsPerg, {06, "Produto (produzido) final     ", "C", 15, 0,  "",   "SB1",    {},    ""})
	aadd (_aRegsPerg, {07, "Componente (consumido) inicial", "C", 15, 0,  "",   "SB1",    {},    ""})
	aadd (_aRegsPerg, {08, "Componente (consumido) final  ", "C", 15, 0,  "",   "SB1",    {},    ""})
	aadd (_aRegsPerg, {09, "Numero OP inicial             ", "C", 13, 0,  "",   "SC2",    {},    ""})
	aadd (_aRegsPerg, {10, "Numero OP final               ", "C", 13, 0,  "",   "SC2",    {},    ""})
	aadd (_aRegsPerg, {11, "Tipos de movimentos a exportar", "N",  1, 0,  "",   "   ",    {"Producao", "Consumo/devol", "Todos"}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return

