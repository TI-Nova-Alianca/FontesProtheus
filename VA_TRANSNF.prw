// Programa:  VA_TRANSNF
// Autor:     Cláudia Lionço
// Data:      27/03/2020
// Descricao: Relatório de conferência de transferências
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_TRANSNF()
	Private cPerg   := "VA_TRANSNF"
	
	_ValidPerg()
	If Pergunte(cPerg,.T.)
		TNFExp() // Exporta dados
	EndIf
Return
//
// -------------------------------------------------------------------------
Static Function TNFExp()
	Local _oSQL := NIL
	
	procregua (10)
	incproc ("Gerando arquivo de exportacao")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH FILIAIS"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		M0_CODFIL AS COD_FILIAL"
	_oSQL:_sQuery += " 	   ,A1_COD AS COD_CLIENTE"
	_oSQL:_sQuery += " 	   ,A2_COD AS COD_FORNECEDOR"
	_oSQL:_sQuery += " 	FROM VA_SM0"
	_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") 
	_oSQL:_sQuery += " 		ON A1_CGC = M0_CGC"
	_oSQL:_sQuery += " 		AND SA1010.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND VA_SM0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA2") 
	_oSQL:_sQuery += " 		ON M0_CGC = A2_CGC"
	_oSQL:_sQuery += " 		AND SA2010.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND VA_SM0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	WHERE VA_SM0.D_E_L_E_T_ = ''),"
	_oSQL:_sQuery += " SAIDAS"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		D2_DOC"
	_oSQL:_sQuery += " 	   ,D2_COD"
	_oSQL:_sQuery += " 	   ,D2_EMISSAO"
	_oSQL:_sQuery += " 	   ,D2_FILIAL"
	_oSQL:_sQuery += " 	   ,D2_TP"
	_oSQL:_sQuery += " 	   ,D2_CF"
	_oSQL:_sQuery += " 	   ,D2_TES"
	_oSQL:_sQuery += " 	   ,D2_CLIENTE"
	_oSQL:_sQuery += " 	   ,ROUND(SUM(D2_CUSTO1), 2) AS D2CUSTO"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("SD2") 
	_oSQL:_sQuery += " 	WHERE D2_TES IN (SELECT"
	_oSQL:_sQuery += " 			F4_CODIGO"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SF4") 
	_oSQL:_sQuery += " 		WHERE F4_TRANFIL = '1')"
	_oSQL:_sQuery += " 	AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND D2_EMISSAO BETWEEN '" + DTOS(MV_PAR01)+ "' AND '" + DTOS(MV_PAR02) + "'"
	_oSQL:_sQuery += " 	GROUP BY D2_DOC"
	_oSQL:_sQuery += " 			,D2_COD"
	_oSQL:_sQuery += " 			,D2_EMISSAO"
	_oSQL:_sQuery += " 			,D2_FILIAL"
	_oSQL:_sQuery += " 			,D2_TP"
	_oSQL:_sQuery += " 			,D2_CF"
	_oSQL:_sQuery += " 			,D2_TES"
	_oSQL:_sQuery += " 			,D2_CLIENTE),"
	_oSQL:_sQuery += " ENTRADAS"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		D1_DOC"
	_oSQL:_sQuery += " 	   ,D1_COD"
	_oSQL:_sQuery += " 	   ,D1_EMISSAO"
	_oSQL:_sQuery += " 	   ,D1_FILIAL"
	_oSQL:_sQuery += " 	   ,D1_TP"
	_oSQL:_sQuery += " 	   ,D1_CF"
	_oSQL:_sQuery += " 	   ,D1_TES"
	_oSQL:_sQuery += " 	   ,D1_FORNECE"
	_oSQL:_sQuery += " 	   ,ROUND(SUM(D1_CUSTO), 2) AS D1CUSTO"
	_oSQL:_sQuery += " 	   ,D1_DTDIGIT"
	_oSQL:_sQuery += " 	FROM SD1010"
	_oSQL:_sQuery += " 	WHERE D1_TES IN (SELECT"
	_oSQL:_sQuery += " 			F4_CODIGO"
	_oSQL:_sQuery += " 		FROM SF4010"
	_oSQL:_sQuery += " 		WHERE F4_TRANFIL = '1'"
	_oSQL:_sQuery += " 		OR F4_CODIGO IN ('148', '151', '548', '081'))"
	_oSQL:_sQuery += " 	AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND D1_DTDIGIT BETWEEN '" + DTOS(MV_PAR01) + "' AND '" + DTOS(MV_PAR02)+ "'"
	_oSQL:_sQuery += " 	GROUP BY D1_DOC"
	_oSQL:_sQuery += " 			,D1_COD"
	_oSQL:_sQuery += " 			,D1_EMISSAO"
	_oSQL:_sQuery += " 			,D1_FILIAL"
	_oSQL:_sQuery += " 			,D1_TP"
	_oSQL:_sQuery += " 			,D1_CF"
	_oSQL:_sQuery += " 			,D1_TES"
	_oSQL:_sQuery += " 			,D1_FORNECE"
	_oSQL:_sQuery += " 			,D1_DTDIGIT)"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	FIL.COD_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,FIL.COD_CLIENTE AS CLIENTE"
	_oSQL:_sQuery += "    ,FIL.COD_FORNECEDOR AS FORNECEDOR"
	_oSQL:_sQuery += "    ,F42.F4_ESTOQUE AS ESTOQUE_SAIDA"
	_oSQL:_sQuery += "    ,D2_FILIAL AS SAIDA_FILIAL"
	_oSQL:_sQuery += "    ,D2_DOC AS SAIDA_DOC"
	_oSQL:_sQuery += "    ,D2_COD AS SAIDA_COD"
	_oSQL:_sQuery += "    ,D2_EMISSAO AS SAIDA_EMISSAO"
	_oSQL:_sQuery += "    ,D2_TP AS SAIDA_TP"
	_oSQL:_sQuery += "    ,D2_CF AS SAIDA_CF"
	_oSQL:_sQuery += "    ,D2_TES AS SAIDA_TES"
	_oSQL:_sQuery += "    ,D2_CLIENTE AS SAIDA_CLIENTE"
	_oSQL:_sQuery += "    ,F41.F4_ESTOQUE AS ESTOQUE_ENTRADA"
	_oSQL:_sQuery += "    ,D1_FILIAL AS ENT_FILIAL"
	_oSQL:_sQuery += "    ,D1_DOC AS ENT_DOC"
	_oSQL:_sQuery += "    ,D1_COD AS ENT_COD"
	_oSQL:_sQuery += "    ,D1_EMISSAO AS ENT_EMISSAO"
	_oSQL:_sQuery += "    ,D1_TP AS ENT_TP"
	_oSQL:_sQuery += "    ,D1_CF AS ENT_CF"
	_oSQL:_sQuery += "    ,D1_TES AS ENT_TES"
	_oSQL:_sQuery += "    ,D1_FORNECE AS ENT_FORNECEDOR"
	_oSQL:_sQuery += "    ,D1_DTDIGIT AS ENT_DTDIGIT"
	_oSQL:_sQuery += "    ,isnull(D2CUSTO,0) AS CUSTO_SAIDA"
	_oSQL:_sQuery += "    ,isnull(D1CUSTO,0) AS CUSTO_ENTRADA"
	_oSQL:_sQuery += "    ,isnull(D1CUSTO,0) - isnull(D2CUSTO,0) AS DIFERENCA_CUSTO"
	_oSQL:_sQuery += " FROM FILIAIS FIL"
	_oSQL:_sQuery += " LEFT JOIN SAIDAS SAI"
	_oSQL:_sQuery += " 	ON FIL.COD_FILIAL = SAI.D2_FILIAL"
	_oSQL:_sQuery += " LEFT JOIN ENTRADAS ENT"
	_oSQL:_sQuery += " 	ON FIL.COD_FORNECEDOR = ENT.D1_FORNECE"
	_oSQL:_sQuery += " 		AND ENT.D1_DOC = SAI.D2_DOC"
	_oSQL:_sQuery += " 		AND ENT.D1_EMISSAO = SAI.D2_EMISSAO"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SF4") +" F42"
	_oSQL:_sQuery += " 	ON F42.F4_CODIGO = SAI.D2_TES"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SF4") + " F41"
	_oSQL:_sQuery += " 	ON F41.F4_CODIGO = ENT.D1_TES"
	_oSQL:_sQuery += " ORDER BY D1_DOC"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .T.)

Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Data inicial                 ?", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final                   ?", "D", 08, 0,  "",   "   ", {},                ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return