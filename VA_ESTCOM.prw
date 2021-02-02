// Programa:  VA_ESTCOM
// Autor:     Cláudia Lionço
// Data:      26/03/2020
// Descricao: Relatório para conferência de compra com estoque
//
// Historico de alteracoes:
// 27/03/2020 - Claudia - Alterado o modelo TREPORT para exportação direto para planilha
// 05/01/2021 - Cláudia - Retirada as CFOP's '1151', '1557', '2151'. GLPI: 9076
// 12/01/2021 - Cláudia - GLPI: 9105 Incluido o CFOP na rotina. 
// 28/01/2021 - Cláudia - GLPI: 9242 - Incluida coluna de TES
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_ESTCOM()
	Private cPerg   := "VA_ESTCOM"
	
	_ValidPerg()
	If Pergunte(cPerg,.T.)
		EstComExp() // Exporta dados
	EndIf
Return
//
// -------------------------------------------------------------------------
Static Function EstComExp()
	Local cQuery      := ""	
	Local cQuery1     := ""	
	Local sPeriodo    := ""
	Local _aCtb       := {}
	Local _aEnt       := {}
	Local aItensExcel := {}
	Local x			  := 0
	Local y           := 0
	
	sPeriodo := mv_par02 + PADL(mv_par01,2,'0')
	
	cQuery += " SELECT"
	cQuery += " 	A.D1_FILIAL AS FILIAL_CTB"
	cQuery += "    ,A.D1_DOC AS DOCUMENTO_CTB"
	cQuery += "    ,CASE"
	cQuery += " 		WHEN A.D1_TP = 'II' THEN 'MA'"
	cQuery += " 		ELSE A.D1_TP"
	cQuery += " 	END AS TIPO_CTB"
	cQuery += "    ,SUM(A.D1_CUSTO) AS CUSTO_CTB"
	//cQuery += "    ,A.D1_CF AS CFOP"
	//cQuery += "    ,A.D1_TES AS TES"
	cQuery += " FROM SD1010 AS A"
	cQuery += " LEFT JOIN SF4010 AS B"
	cQuery += " 	ON B.F4_CODIGO = A.D1_TES"
	cQuery += " LEFT JOIN SB1010 AS C"
	cQuery += " 	ON A.D1_COD = C.B1_COD"
	cQuery += " WHERE (B.F4_ESTOQUE = 'S')"
	cQuery += " AND A.D_E_L_E_T_ = ''"
	cQuery += " AND SUBSTRING(A.D1_DTDIGIT, 1, 6) = '" + sPeriodo + "'"
	cQuery += " AND A.D1_TIPO != 'D'"
	//cQuery += " AND A.D1_CF NOT IN ('1151', '1557', '2151')"
	cQuery += " AND ((A.D1_CF NOT LIKE '19%'"
	cQuery += " AND A.D1_CF NOT LIKE '29%'))"
	cQuery += " AND B.D_E_L_E_T_ = ''"
	cQuery += " AND C.D_E_L_E_T_ = ''"
	cQuery += " GROUP BY A.D1_FILIAL"
	cQuery += " 		,A.D1_TP"
	cQuery += " 		,A.D1_DOC"
	//cQuery += "         ,A.D1_CF"
	//cQuery += "         ,A.D1_TES"
	cQuery += " ORDER BY A.D1_FILIAL"
	cQuery += " 		,A.D1_TP"
	cQuery += " 		,A.D1_DOC"
	_aEnt:= U_Qry2Array(cQuery)
	
	cQuery1 += " SELECT"
	cQuery1 += "    CT.CT2_FILIAL AS FILIAL_ENT"
	cQuery1 += "    ,CASE"
	cQuery1 += " 		WHEN SUBSTRING(CT.CT2_KEY, 3, 9) = '' THEN SUBSTRING(CT.CT2_HIST, CHARINDEX('NR ', CT.CT2_HIST) + 3, 9)"
	cQuery1 += " 		ELSE SUBSTRING(CT.CT2_KEY, 3, 9)"
	cQuery1 += " 	END AS DOCUMENTO_ENT"
	cQuery1 += "    ,CASE"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301008' THEN 'CL'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301002' THEN 'MM'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301006' THEN 'MB'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301005' THEN 'EP'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301001' THEN 'UC'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101016' THEN 'ME'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101011' THEN 'PA'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301004' THEN 'MA'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101014' THEN 'MP'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101015' THEN 'PS'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101025' THEN 'MR'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101013' THEN 'VD'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301007' THEN 'MT'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030101023' THEN 'BN'"
	cQuery1 += " 		WHEN CT.CT2_DEBITO = '101030301009' THEN 'IA'"
	cQuery1 += " 		ELSE ''"
	cQuery1 += " 	END AS TIPO_ENT"
	cQuery1 += "    ,ROUND(SUM(CASE"
	cQuery1 += " 		WHEN CT.CT2_DEBITO != '' THEN CT.CT2_VALOR"
	cQuery1 += " 		WHEN CT.CT2_CREDIT != '' THEN -CT.CT2_VALOR"
	cQuery1 += " 		ELSE ''"
	cQuery1 += " 	END), 2) AS VALOR_ENT"
	cQuery1 += " FROM CT2010 AS CT"
	cQuery1 += " WHERE CT.D_E_L_E_T_ = ''"
	cQuery1 += " AND CT.CT2_ROTINA IN ('MATA103', 'MATA100', 'CTBANFE')"
	cQuery1 += " AND SUBSTRING(CT.CT2_DATA, 1, 6) = '" + sPeriodo + "'"
	cQuery1 += " AND (CT.CT2_DEBITO != ''"
	cQuery1 += " OR CT.CT2_CREDIT != '')"
	cQuery1 += " AND CT.CT2_HIST NOT LIKE '%DEVOL%'"
	cQuery1 += " AND (CT.CT2_DEBITO NOT LIKE '4%'"
	cQuery1 += " AND CT.CT2_DEBITO NOT LIKE '7%')"
	cQuery1 += " AND CT.CT2_DEBITO LIKE '101030%'"
	cQuery1 += " GROUP BY CT.CT2_FILIAL"
	cQuery1 += " 		,CT.CT2_DEBITO"
	cQuery1 += " 		,CT.CT2_HIST"
	cQuery1 += " 		,SUBSTRING(CT.CT2_KEY, 3, 9)"
	_aCtb:= U_Qry2Array(cQuery1)	
	

	AADD(aItensExcel,{"Filial Ent","Doc.Ent","Tipo Ent","Valor Ent","Filial.Ctb","Doc.Ctb","Tipo.Ctb","Valor.Ctb"})
	
	For x:=1 to len(_aEnt)
		_nAchou := 0
		For y:=1 to len (_aCtb)
			If _aEnt[x,1] == _aCtb[y,1] .and. _aEnt[x,2] == _aCtb[y,2] .and. _aEnt[x,3] == _aCtb[y,3]
				AADD(aItensExcel,{_aEnt[x,1],_aEnt[x,2],_aEnt[x,3],_aEnt[x,4],_aCtb[y,1],_aCtb[y,2],_aCtb[y,3],_aCtb[y,4]})
				
				_nAchou := 1
			EndIf
		Next
		If _nAchou == 0
			AADD(aItensExcel,{_aEnt[x,1],_aEnt[x,2],_aEnt[x,3],_aEnt[x,4],'','','',0})
		EndIf
	Next
	
	For x:=1 to len(_aCtb)
		_nAchou := 0
		For y:=1 to len (_aEnt)
			If _aCtb[x,1] == _aEnt[y,1] .and. _aCtb[x,2] == _aEnt[y,2] .and. _aCtb[x,3] == _aEnt[y,3]
				_nAchou := 1
			EndIf
		Next
		If _nAchou == 0
			AADD(aItensExcel,{'','','',0,'',_aCtb[x,1],_aCtb[x,2],_aCtb[x,3],_aCtb[x,4]})
		EndIf
	Next

	u_aColsXLS (aItensExcel,.T.)
Return
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT    TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Mês    	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Ano    	", "C", 4, 0,  "",  "   ", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
