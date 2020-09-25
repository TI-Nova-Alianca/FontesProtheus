// Programa...: VA_XLS45
// Autor......: Cláudia Lionço
// Data.......: 18/09/2019
// Descricao..: Verificar diferenças entre estrutura e OP
//
// Historico de alteracoes:
// 14/01/2020 - Claudia - Alterado o While do perfunte por if devido a validação de release 25
// 
// --------------------------------------------------------------------------
User Function VA_XLS45 ()
	Local cCadastro := "Verificar diferenças entre estrutura e OP"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	Private cPerg   := "VAXLS45"
	
	_ValidPerg()
	If Pergunte (cPerg, .T.)
		Processa( { |lEnd| _Gera() } )
	EndIf
return
//
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	OP"
	_oSQL:_sQuery += "    ,FILIAL"
	_oSQL:_sQuery += "    ,PRODUTO"
	_oSQL:_sQuery += "    ,COMPONENTE"
	_oSQL:_sQuery += "    ,SUM(QTD_PROD) AS QTD_PROD"
	_oSQL:_sQuery += "    ,SUM(QTD_EST) AS QTD_EST"
	_oSQL:_sQuery += "    ,SUM(QTD_OP) AS TOTAL_OP"
	_oSQL:_sQuery += "    ,SUM(QTD_TOTEST) AS TOTAL_ESTRUTURA"
	_oSQL:_sQuery += "    ,DT_EMISSAO"
	_oSQL:_sQuery += "    ,REVISAO"
	_oSQL:_sQuery += " FROM (SELECT"
	_oSQL:_sQuery += " 		SD3.D3_OP AS OP"
	_oSQL:_sQuery += " 	   ,SD3.D3_FILIAL AS FILIAL"
	_oSQL:_sQuery += " 	   ,SC2.C2_PRODUTO AS PRODUTO"
	_oSQL:_sQuery += " 	   ,SD3.D3_COD AS COMPONENTE"
	_oSQL:_sQuery += " 	   ,0 AS QTD_PROD"
	_oSQL:_sQuery += " 	   ,0 AS QTD_EST"
	_oSQL:_sQuery += " 	   ,0 AS QTD_TOTEST"
	_oSQL:_sQuery += " 	   ,SUM(SD3.D3_QUANT) AS QTD_OP"
	_oSQL:_sQuery += " 	   ,SC2.C2_EMISSAO AS DT_EMISSAO"
	_oSQL:_sQuery += " 	   ,SC2.C2_REVISAO AS REVISAO"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("SD3") + " SD3"
	_oSQL:_sQuery += " 	RIGHT JOIN " + RetSQLName ("SC2") + " AS SC2"
	_oSQL:_sQuery += " 		ON ((SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD) = SD3.D3_OP"
	_oSQL:_sQuery += " 		AND SC2.C2_FILIAL = SD3.D3_FILIAL"
	_oSQL:_sQuery += " 		AND SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " AS SB1"
	_oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND B1_TIPO = 'PA'"
	_oSQL:_sQuery += " 		AND SB1.B1_COD = SC2.C2_PRODUTO)"
	_oSQL:_sQuery += " 	FULL OUTER JOIN " + RetSQLName ("SG1") + " AS SG1"
	_oSQL:_sQuery += " 		ON (SG1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SG1.G1_COD = SC2.C2_PRODUTO"
	_oSQL:_sQuery += " 		AND SG1.G1_COMP = SD3.D3_COD"
	_oSQL:_sQuery += " 		AND SD3.D3_CF LIKE 'RE%'"
	_oSQL:_sQuery += " 		AND G1_REVINI <= SC2.C2_REVISAO"
	_oSQL:_sQuery += " 		AND G1_REVFIM >= SC2.C2_REVISAO"
	_oSQL:_sQuery += " 		AND SG1.G1_INI <= SD3.D3_EMISSAO"
	_oSQL:_sQuery += " 		AND SG1.G1_FIM >= SD3.D3_EMISSAO"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " 	WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND D3_FILIAL BETWEEN '"+mv_par03+"' AND '"+mv_par04+"'"
	_oSQL:_sQuery += " 	AND D3_CF LIKE 'RE%'"
	_oSQL:_sQuery += " 	AND D3_ESTORNO != 'S'"
	_oSQL:_sQuery += " 	AND D3_COD NOT LIKE '%AO%'"
	_oSQL:_sQuery += " 	AND D3_COD NOT LIKE '%AP%'"
	_oSQL:_sQuery += " 	AND D3_COD NOT LIKE '%GF%'"
	_oSQL:_sQuery += " 	GROUP BY SD3.D3_OP"
	_oSQL:_sQuery += " 			,SD3.D3_FILIAL"
	_oSQL:_sQuery += " 			,SC2.C2_PRODUTO"
	_oSQL:_sQuery += " 			,SD3.D3_COD"
	_oSQL:_sQuery += " 			,SC2.C2_QUJE"
	_oSQL:_sQuery += " 			,SG1.G1_QUANT"
	_oSQL:_sQuery += " 			,SC2.C2_QUJE * SG1.G1_QUANT"
	_oSQL:_sQuery += " 			,SC2.C2_EMISSAO"
	_oSQL:_sQuery += " 			,SC2.C2_REVISAO"
	_oSQL:_sQuery += " 	UNION"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD AS OP2"
	_oSQL:_sQuery += " 	   ,SC2.C2_FILIAL AS FILIAL"
	_oSQL:_sQuery += " 	   ,SG1.G1_COD AS PRODUTO"
	_oSQL:_sQuery += " 	   ,SG1.G1_COMP AS COMPONENTE"
	_oSQL:_sQuery += " 	   ,SC2.C2_QUJE AS QTD_PROD"
	_oSQL:_sQuery += " 	   ,ISNULL(SG1.G1_QUANT, 0) AS QTD_EST"
	_oSQL:_sQuery += " 	   ,ISNULL(SC2.C2_QUJE * SG1.G1_QUANT, 0) AS QTD_TOTEST"
	_oSQL:_sQuery += " 	   ,0 AS QTD_OP"
	_oSQL:_sQuery += " 	   ,SC2.C2_EMISSAO AS DT_EMISSAO"
	_oSQL:_sQuery += " 	   ,SC2.C2_REVISAO AS REVISAO"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("SG1") + " SG1"
	_oSQL:_sQuery += " 		,SC2010 SC2"
	_oSQL:_sQuery += " 		 INNER JOIN " + RetSQLName ("SB1") + " AS SB1"
	_oSQL:_sQuery += " 			 ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			 AND B1_TIPO = 'PA'"
	_oSQL:_sQuery += " 			 AND SB1.B1_COD = SC2.C2_PRODUTO)"
	_oSQL:_sQuery += " 	WHERE SG1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SC2.C2_FILIAL BETWEEN '01' AND '13'"
	_oSQL:_sQuery += " 	AND SC2.C2_PRODUTO = SG1.G1_COD"
	_oSQL:_sQuery += " 	AND SG1.G1_REVINI <= SC2.C2_REVISAO"
	_oSQL:_sQuery += " 	AND SG1.G1_REVFIM >= SC2.C2_REVISAO"
	_oSQL:_sQuery += " 	AND SG1.G1_INI <= SC2.C2_EMISSAO"
	_oSQL:_sQuery += " 	AND SG1.G1_FIM >= SC2.C2_EMISSAO) RETORNO"
	_oSQL:_sQuery += " WHERE RETORNO.FILIAL BETWEEN '"+mv_par03+"' AND '"+mv_par04+"'"
	_oSQL:_sQuery += " AND RETORNO.DT_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"   
	_oSQL:_sQuery += " AND RETORNO.OP BETWEEN '"+ALLTRIM(mv_par05)+"' AND '"+ALLTRIM(mv_par06)+"'"
	_oSQL:_sQuery += " GROUP BY OP"
	_oSQL:_sQuery += " 		,FILIAL"
	_oSQL:_sQuery += " 		,PRODUTO"
	_oSQL:_sQuery += " 		,COMPONENTE"
	_oSQL:_sQuery += " 		,DT_EMISSAO"
	_oSQL:_sQuery += " 		,REVISAO"
	_oSQL:_sQuery += " HAVING SUM(QTD_TOTEST) - SUM(QTD_OP) <> 0"
	_oSQL:_sQuery += " ORDER BY RETORNO.FILIAL, RETORNO.OP, RETORNO.PRODUTO, RETORNO.COMPONENTE"

	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Data emissao inicial   ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Data emissao final     ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {03, "Filial inicial         ", "C", 2,  0,  "",   "   ", {}, 					""})
	aadd (_aRegsPerg, {04, "Filial final           ", "C", 2,  0,  "",   "   ", {}, 					""})
	aadd (_aRegsPerg, {05, "OP inicial             ", "C",14,  0,  "",   "   ", {}, 					""})
	aadd (_aRegsPerg, {06, "OP final               ", "C",14,  0,  "",   "   ", {}, 					""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return

