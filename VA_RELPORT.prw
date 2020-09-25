// Programa:  VA_RELPORT
// Autor:     Cláudia Lionço
// Data:      14/10/2019
// Descricao: Relatorio de emissão por portador
//
// Historico de alteracoes:
// 15/10/2019 - Cláudia - Adicionada versão sintetica do relatório. GLPI:6808
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function VA_RELPORT()
	Private oReport
	Private cPerg   := "VA_RELPORT"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction
	//Local oBreak1
	//Local oBreak2

	oReport := TReport():New("VA_RELPORT","Emissão por portador X UF",cPerg,{|oReport| PrintReport(oReport)},"Emissão por portador X UF")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Portador"		,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Descrição"		,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Estado"		,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Quantidade"	,	    				,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Valor total"	, "@E 999,999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""	
	//Local nTotal 	:= 0
	Local oBreak1
	Local oBreak2

	_ValidPerg()
	Pergunte(cPerg,.F.)

	If mv_par09 == 1
		oBreak1 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA1"):uPrint+oSection1:Cell("COLUNA2"):uPrint },"Total por portador")
		TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1, "Quantidade " , 					, NIL, .F., .T.)
		TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak1, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .T.)
	EndIf
	
	oBreak2 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA1"):uPrint},"Total por filial")
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak2, "Quantidade " , 					, NIL, .F., .T.)
	TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak2, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .T.)
	
	If mv_par09 == 1
		cQuery += " SELECT"
		cQuery += " 	SE1A.E1_FILIAL AS FILIAL"
		cQuery += "    ,CASE"
		cQuery += " 		WHEN SE1A.E1_PORTADO = '' THEN 'CX1'"
		cQuery += " 		ELSE SE1A.E1_PORTADO"
		cQuery += " 	END AS PORTADOR"
		cQuery += " 	,ISNULL((SELECT TOP 1"
		cQuery += " 			A6_NOME"
		cQuery += " 		FROM " + RetSqlName("SA6") + "  SA6"
		cQuery += " 		WHERE SA6.D_E_L_E_T_ = ''"
		cQuery += " 		    AND SA6.A6_FILIAL  = SE1A.E1_FILIAL"
		cQuery += " 		    AND SA6.A6_COD     = SE1A.E1_PORTADO"
		cQuery += " 		    AND SA6.A6_AGENCIA = SE1A.E1_AGEDEP"
		cQuery += " 		    AND SA6.A6_NUMCON  = SE1A.E1_CONTA"
		cQuery += " 		ORDER BY R_E_C_N_O_)"
		cQuery += "    , 'CAIXA') AS DESCRICAO"
		cQuery += "    ,ROUND(SUM(SE1A.E1_VALOR), 2) AS TOTAL"
		cQuery += "    ,COUNT(SE1A.R_E_C_N_O_) AS QUANTIDADE"
		cQuery += "    ,SA1A.A1_EST AS ESTADO"
		cQuery += " FROM " + RetSqlName("SE1") + "  SE1A"
		cQuery += " 	," + RetSqlName("SA1") + "  SA1A"
		cQuery += " WHERE SE1A.D_E_L_E_T_ = ''"
		cQuery += " AND SA1A.D_E_L_E_T_ = ''"
		cQuery += " AND SE1A.E1_CLIENTE = SA1A.A1_COD"
		cQuery += " AND SE1A.E1_LOJA = SA1A.A1_LOJA"
		cQuery += " AND SE1A.E1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
		cQuery += " AND SE1A.E1_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery += " AND SE1A.E1_TIPO = 'NF'"
		cQuery += " AND SE1A.E1_PORTADO BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
		cQuery += " AND SA1A.A1_EST BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
		cQuery += " GROUP BY SE1A.E1_FILIAL"
		cQuery += " 		,SE1A.E1_PORTADO"
		cQuery += " 		,SA1A.A1_EST"
		cQuery += " 		,SE1A.E1_AGEDEP"
		cQuery += " 		,SE1A.E1_CONTA"
		cQuery += " ORDER BY SE1A.E1_FILIAL"
		cQuery += " , SE1A.E1_PORTADO"
		cQuery += " , SA1A.A1_EST"
	Else
		cQuery += " SELECT"
		cQuery += " 	SE1A.E1_FILIAL AS FILIAL"
		cQuery += "    ,CASE"
		cQuery += " 		WHEN SE1A.E1_PORTADO = '' THEN 'CX1'"
		cQuery += " 		ELSE SE1A.E1_PORTADO"
		cQuery += " 	END AS PORTADOR"
		cQuery += " 	,ISNULL((SELECT TOP 1"
		cQuery += " 			A6_NOME"
		cQuery += " 		FROM " + RetSqlName("SA6") + "  SA6"
		cQuery += " 		WHERE SA6.D_E_L_E_T_ = ''"
		cQuery += " 		    AND SA6.A6_FILIAL  = SE1A.E1_FILIAL"
		cQuery += " 		    AND SA6.A6_COD     = SE1A.E1_PORTADO"
		cQuery += " 		    AND SA6.A6_AGENCIA = SE1A.E1_AGEDEP"
		cQuery += " 		    AND SA6.A6_NUMCON  = SE1A.E1_CONTA"
		cQuery += " 		ORDER BY R_E_C_N_O_)"
		cQuery += "    , 'CAIXA') AS DESCRICAO"
		cQuery += "    ,ROUND(SUM(SE1A.E1_VALOR), 2) AS TOTAL"
		cQuery += "    ,COUNT(SE1A.R_E_C_N_O_) AS QUANTIDADE"
		cQuery += " FROM " + RetSqlName("SE1") + "  SE1A"
		cQuery += " 	," + RetSqlName("SA1") + "  SA1A"
		cQuery += " WHERE SE1A.D_E_L_E_T_ = ''"
		cQuery += " AND SA1A.D_E_L_E_T_ = ''"
		cQuery += " AND SE1A.E1_CLIENTE = SA1A.A1_COD"
		cQuery += " AND SE1A.E1_LOJA = SA1A.A1_LOJA"
		cQuery += " AND SE1A.E1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
		cQuery += " AND SE1A.E1_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery += " AND SE1A.E1_TIPO = 'NF'"
		cQuery += " AND SE1A.E1_PORTADO BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
		cQuery += " AND SA1A.A1_EST BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
		cQuery += " GROUP BY SE1A.E1_FILIAL"
		cQuery += " 		,SE1A.E1_PORTADO"
		cQuery += " 		,SE1A.E1_AGEDEP"
		cQuery += " 		,SE1A.E1_CONTA"
		cQuery += " ORDER BY SE1A.E1_FILIAL"
		cQuery += " , SE1A.E1_PORTADO"
	EndIf
	
//	    nHandle := FCreate("c:\temp\banco.txt")
//	    FWrite(nHandle,cQuery )
//	    FClose(nHandle)
	    
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
	TRA->(DbGotop())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While TRA->(!Eof())	
		If mv_par09 == 1
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->FILIAL  	})
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->PORTADOR 	})
			oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->DESCRICAO	})
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->ESTADO   	})
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->QUANTIDADE})
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->TOTAL 	})
		Else
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->FILIAL  	})
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->PORTADOR 	})
			oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->DESCRICAO	})
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| "TODOS"   		})
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->QUANTIDADE})
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->TOTAL 	})
		EndIf

		oSection1:PrintLine()
		
		DBSelectArea("TRA")
		dbskip()
	Enddo
	oSection1:Finish()
	TRA->(DbCloseArea())
Return
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Emissao de      	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Emissao até     	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Filial de       	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Filial até      	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "Portador de       	", "C", 3, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {06, "Portador até       	", "C", 3, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {07, "Estado de        	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {08, "Estado até        	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {09, "Impressão       	", "N", 1, 0,  "",  "   ", {"Analítico","Sintético"},                   ""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
