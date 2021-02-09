// Programa...:  VA_ESTCOM
// Autor......:  Cláudia Lionço
// Data.......:  26/03/2020
// Descricao..:  Relatório para conferência de compra com estoque
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório para conferência de compra com estoque
// #PalavasChave      #compra_com_estoque 
// #TabelasPrincipais #SE1 
// #Modulos 		  #EST
//
// Historico de alteracoes:
// 27/03/2020 - Claudia - Alterado o modelo TREPORT para exportação direto para planilha
// 05/01/2021 - Cláudia - Retirada as CFOP's '1151', '1557', '2151'. GLPI: 9076
// 12/01/2021 - Cláudia - GLPI: 9105 Incluido o CFOP na rotina. 
// 28/01/2021 - Cláudia - GLPI: 9242 - Incluida coluna de TES
// 08/02/2021 - Cláudia - GLPI: 9300 - Alterada as querys e retiradas bonificações/transferencias
//
// ------------------------------------------------------------------------------------------------
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
	Local sPeriodo    := ""
	Local _aCtb       := {}
	Local _aEnt       := {}
	Local aItensExcel := {}
	Local x			  := 0
	Local y           := 0
	
	sPeriodo := mv_par02 + PADL(mv_par01,2,'0')
	
	// DADOS NOTAS DE ENTRADA
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	SD1.D1_FILIAL AS FILIAL_ENT"
	_oSQL:_sQuery += "    ,SD1.D1_DOC AS DOCUMENTO_ENT"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN SD1.D1_TP = 'II' THEN 'MA'"
	_oSQL:_sQuery += " 		ELSE SD1.D1_TP"
	_oSQL:_sQuery += " 	END AS TIPO_ENT"
	_oSQL:_sQuery += "    ,SUM(SD1.D1_CUSTO) AS CUSTO_ENT"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " AS SD1" 
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SF4") + " AS SF4"
	_oSQL:_sQuery += " 	ON SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SF4.F4_CODIGO = SD1.D1_TES"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SB1") + " AS SB1"
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SD1.D1_COD = SB1.B1_COD"
	_oSQL:_sQuery += " WHERE (SF4.F4_ESTOQUE = 'S')"
	_oSQL:_sQuery += " AND SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SUBSTRING(SD1.D1_DTDIGIT, 1, 6) = '" + sPeriodo + "'"
	_oSQL:_sQuery += " AND SD1.D1_TIPO != 'D'"
	_oSQL:_sQuery += " AND SD1.D1_CF NOT IN ('1910', '2910', '1151', '1152', '1552', '1557', '2151', '2152', '2552', '2557')"
	_oSQL:_sQuery += " AND ((SD1.D1_CF NOT LIKE '19%'"
	_oSQL:_sQuery += " AND SD1.D1_CF NOT LIKE '29%'))"
	_oSQL:_sQuery += " GROUP BY SD1.D1_FILIAL"
	_oSQL:_sQuery += " 		,SD1.D1_TP"
	_oSQL:_sQuery += " 		,SD1.D1_DOC"
	_oSQL:_sQuery += " ORDER BY SD1.D1_FILIAL"
	_oSQL:_sQuery += " , SD1.D1_TP"
	_oSQL:_sQuery += " , SD1.D1_DOC"
	_aEnt := _oSQL:Qry2Array ()

	//nHandle := FCreate("c:\temp\log1.txt")
	//FWrite(nHandle,_oSQL:_sQuery )
	//FClose(nHandle)

	// DADOS CTB
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		CT.CT2_FILIAL AS FILIAL_CTB"
	_oSQL:_sQuery += " 	   ,CASE"
	_oSQL:_sQuery += " 			WHEN SUBSTRING(CT.CT2_KEY, 3, 9) = '' THEN SUBSTRING(CT.CT2_HIST, CHARINDEX('NR ', CT.CT2_HIST) + 3, 9)"
	_oSQL:_sQuery += " 			ELSE SUBSTRING(CT.CT2_KEY, 3, 9)"
	_oSQL:_sQuery += " 		END AS DOCUMENTO_CTB"
	_oSQL:_sQuery += " 	   ,CASE"
	_oSQL:_sQuery += " 			WHEN SUBSTRING(CT.CT2_KEY, 12, 2) = '' THEN SUBSTRING(CT.CT2_HIST, CHARINDEX('NR ', CT.CT2_HIST) + 12, 2)"
	_oSQL:_sQuery += " 			ELSE SUBSTRING(CT.CT2_KEY, 12, 2)"
	_oSQL:_sQuery += " 		END AS SERIE_CTB"
	_oSQL:_sQuery += " 	   ,CASE"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301008' THEN 'CL'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301002' THEN 'MM'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301006' THEN 'MB'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301005' THEN 'EP'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301001' THEN 'UC'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101016' THEN 'ME'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101011' THEN 'PA'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301004' THEN 'MA'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101014' THEN 'MP'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101015' THEN 'PS'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101025' THEN 'MR'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101013' THEN 'VD'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301007' THEN 'MT'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030101023' THEN 'BN'"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO = '101030301009' THEN 'IA'"
	_oSQL:_sQuery += " 			ELSE ''"
	_oSQL:_sQuery += " 		END AS TIPO_CTB"
	_oSQL:_sQuery += " 	   ,ROUND(SUM(CASE"
	_oSQL:_sQuery += " 			WHEN CT.CT2_DEBITO != '' THEN CT.CT2_VALOR"
	_oSQL:_sQuery += " 			WHEN CT.CT2_CREDIT != '' THEN -CT.CT2_VALOR"
	_oSQL:_sQuery += " 			ELSE ''"
	_oSQL:_sQuery += " 		END), 2) AS VALOR_CTB"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("CT2") + " AS CT"    
	_oSQL:_sQuery += " 	WHERE CT.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND CT.CT2_ROTINA IN ('MATA103', 'MATA100', 'CTBANFE')"
	_oSQL:_sQuery += " 	AND SUBSTRING(CT.CT2_DATA, 1, 6) = '" + sPeriodo + "'"
	_oSQL:_sQuery += " 	AND (CT.CT2_DEBITO != ''"
	_oSQL:_sQuery += " 	OR CT.CT2_CREDIT != '')"
	_oSQL:_sQuery += " 	AND CT.CT2_HIST NOT LIKE '%DEVOL%'"
	_oSQL:_sQuery += " 	AND (CT.CT2_DEBITO NOT LIKE '4%'"
	_oSQL:_sQuery += " 	AND CT.CT2_DEBITO NOT LIKE '7%')"
	_oSQL:_sQuery += " 	AND CT.CT2_DEBITO LIKE '101030%'"
	_oSQL:_sQuery += " 	GROUP BY CT.CT2_FILIAL"
	_oSQL:_sQuery += " 			,CT.CT2_DEBITO"
	_oSQL:_sQuery += " 			,CT.CT2_HIST"
	_oSQL:_sQuery += " 			,SUBSTRING(CT.CT2_KEY, 3, 9)"
	_oSQL:_sQuery += "          ,SUBSTRING(CT.CT2_KEY,12, 2))"
	_oSQL:_sQuery += " SELECT DISTINCT"
	_oSQL:_sQuery += " 	FILIAL_CTB"
	_oSQL:_sQuery += "    ,DOCUMENTO_CTB"
	_oSQL:_sQuery += "    ,TIPO_CTB" 
	_oSQL:_sQuery += "    ,VALOR_CTB"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SD1") + " AS SD1" 
	_oSQL:_sQuery += " 	ON (SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND SD1.D1_FILIAL=FILIAL_CTB"
	_oSQL:_sQuery += " 			AND SD1.D1_DOC = DOCUMENTO_CTB"
	_oSQL:_sQuery += "          AND SUBSTRING(SD1.D1_EMISSAO, 1, 6) = '" + sPeriodo + "'"
	_oSQL:_sQuery += " 			)"
	_oSQL:_sQuery += " WHERE SD1.D1_CF NOT IN ('1910', '2910', '1151', '1152', '1552', '1557', '2151', '2152', '2552', '2557')"
	_oSQL:_sQuery += " ORDER BY FILIAL_CTB, TIPO_CTB, DOCUMENTO_CTB"
	_aCtb := _oSQL:Qry2Array ()

	//nHandle := FCreate("c:\temp\log2.txt")
	//FWrite(nHandle,_oSQL:_sQuery )
	//FClose(nHandle)
	// -------------------------------------------------------------------------------------------------------------
	// IMPRESSÃO DOS DADOS

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
			AADD(aItensExcel,{'','','',0,_aCtb[x,1],_aCtb[x,2],_aCtb[x,3],_aCtb[x,4]})
		EndIf
	Next

	u_aColsXLS (aItensExcel,.T.)
Return
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT    TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Mês    	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Ano    	", "C", 4, 0,  "",  "   ", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
