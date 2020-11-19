// Programa:  VA_AMBRES
// Autor:     Cláudia Lionço
// Data:      10/09/2019
// Descricao: Relatorio para quantidade e valor de resíduos
//
// Historico de alteracoes:

#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function VA_AMBRES()
	Private oReport
	Private cPerg   := "VA_AMBRES"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return

Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oSection2:= Nil
	Local oBreak1
	//Local oFunction
	
	oReport := TReport():New("VA_AMBRES","Entradas/saídas de resíduos por fornecedor/cliente",cPerg,{|oReport| PrintReport(oReport)},"Entradas/saídas de resíduos por fornecedor/cliente")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	If mv_par06 = 1
		//SESSÃO 1 ENTRADA DE MATERIAL
		oSection1 := TRSection():New(oReport,"ENTRADA DE MATERIAL",{"SD1","SA2","SB1"}, , , , , ,.F.,.T.,.T.) 
	Else
		oSection1 := TRSection():New(oReport,"SAÍDA DE MATERIAL",{"SD2","SA1","SB1"}, , , , , ,.F.,.T.,.T.) 
	EndIf
		oSection1:SetTotalInLine(.F.)
		
		TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"	,	    				, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		//TRCell():New(oSection1,"COLUNA2", 	"" ,"Cód."		,       				, 8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		//TRCell():New(oSection1,"COLUNA3", 	"" ,"Fornecedor",       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA4", 	"" ,"Produto"	,	    				,10,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA5", 	"" ,"Descrição"	,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA6", 	"" ,"Tipo"		,    					, 5,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA7", 	"" ,"Unidade"	,       				, 8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA8", 	"" ,"Quantidade","@E 999,999,999.99"	,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA9", 	"" ,"Valor"		,"@E 999,999,999.99"	,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
		
		oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
		TRFunction():New(oSection1:Cell("COLUNA8")	,,"SUM"	,oBreak1,"Quantidade " , "@E 99,999,999.99", NIL, .F., .T.)
		TRFunction():New(oSection1:Cell("COLUNA9")	,,"SUM"	,oBreak1,"Valor total ", "@E 99,999,999.99", NIL, .F., .T.)
Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""		
    
    If mv_par06 = 1 //ENTRADA DE MATERIAL
    	cQuery += " SELECT"
    	cQuery += " 	 SD1.D1_FILIAL  AS FILIAL"
    	cQuery += " 	,SD1.D1_FORNECE AS DESTINATARIO"
    	cQuery += " 	,SA2.A2_NOME    AS NOME"
    	cQuery += " 	,SD1.D1_COD     AS PRODUTO"
    	cQuery += " 	,SB1.B1_DESC    AS DESCRI"
    	cQuery += " 	,SB1.B1_TIPO    AS TIPO"
    	cQuery += " 	,SB1.B1_UM      AS UM"
    	cQuery += " 	,SUM(SD1.D1_QUANT) AS QTD"
    	cQuery += " 	,SUM(SD1.D1_TOTAL) AS VLR"
    	cQuery += " FROM " + RetSqlName("SD1") + " AS SD1"
    	cQuery += " INNER JOIN " + RetSqlName("SF1") + " AS SF1"
    	cQuery += "		ON (SF1.D_E_L_E_T_ = ''"
		cQuery += "			AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
		cQuery += "			AND SF1.F1_FORNECE = SD1.D1_FORNECE"
		cQuery += "			AND SF1.F1_LOJA    = SD1.D1_LOJA"
		cQuery += "			AND SF1.F1_DOC     = SD1.D1_DOC)"
		cQuery += "	INNER JOIN " + RetSqlName("SB1") + " AS SB1"
		cQuery += "		ON (SB1.D_E_L_E_T_ = ''"
		//cQuery += "			AND SB1.B1_TIPO IN ('RE', 'VA', 'UC', 'MB')"
		cQuery += "			AND SB1.B1_COD = SD1.D1_COD)"
		cQuery += " INNER JOIN " + RetSqlName("SA2") + " AS SA2"
		cQuery += "		ON (SA2.D_E_L_E_T_=''"
		cQuery += "			AND SD1.D1_FORNECE = SA2.A2_COD)"
		cQuery += "	WHERE SD1.D_E_L_E_T_ = '' "
		cQuery += " AND SD1.D1_COD = SB1.B1_COD "
		cQuery += " AND SD1.D1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
		cQuery += " AND SD1.D1_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery += " AND SD1.D1_FORNECE = '" + mv_par05 +"'"
		cQuery += " GROUP BY SD1.D1_FILIAL "
		cQuery += " 		,SD1.D1_FORNECE "
		cQuery += " 		,SA2.A2_NOME "
		cQuery += " 		,SD1.D1_COD "
		cQuery += " 		,SB1.B1_DESC "
		cQuery += " 		,SB1.B1_TIPO "
		cQuery += " 		,SB1.B1_UM "
		cQuery += " ORDER BY SD1.D1_FILIAL, SD1.D1_FORNECE, SD1.D1_COD "
    Else // SAIDA DE MATERIAL
    	cQuery += " SELECT"
    	cQuery += " 	 SD2.D2_FILIAL	AS FILIAL"
    	cQuery += " 	,SD2.D2_CLIENTE AS DESTINATARIO"
    	cQuery += " 	,SA1.A1_NOME	AS NOME"
    	cQuery += " 	,SD2.D2_COD		AS PRODUTO"
    	cQuery += " 	,SB1.B1_DESC	AS DESCRI"
    	cQuery += " 	,SB1.B1_TIPO	AS TIPO"
    	cQuery += " 	,SB1.B1_UM		AS UM"
    	cQuery += " 	,SUM(SD2.D2_QUANT) AS QTD"
    	cQuery += " 	,SUM(SD2.D2_TOTAL) AS VLR"
    	cQuery += " FROM " + RetSqlName("SD2") + " AS SD2"
    	cQuery += " INNER JOIN " + RetSqlName("SF2") + " AS SF2"
    	cQuery += "		ON (SF2.D_E_L_E_T_ = ''"
		cQuery += "			AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
		cQuery += "			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
		cQuery += "			AND SF2.F2_LOJA    = SD2.D2_LOJA"
		cQuery += "			AND SF2.F2_DOC     = SD2.D2_DOC)"
		cQuery += "	INNER JOIN " + RetSqlName("SB1") + " AS SB1"
		cQuery += "		ON (SB1.D_E_L_E_T_ = ''"
		//cQuery += "			AND SB1.B1_TIPO IN ('RE', 'VA', 'UC', 'MB')"
		cQuery += "			AND SB1.B1_COD = SD2.D2_COD)"
		cQuery += " INNER JOIN " + RetSqlName("SA1") + " AS SA1"
		cQuery += "		ON (SA1.D_E_L_E_T_=''"
		cQuery += "			AND SD2.D2_CLIENTE = SA1.A1_COD)"
		cQuery += "	WHERE SD2.D_E_L_E_T_ = '' "
		cQuery += " AND SD2.D2_COD = SB1.B1_COD "
		cQuery += " AND SD2.D2_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
		cQuery += " AND SD2.D2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery += " AND SD2.D2_CLIENTE = '" + mv_par05 +"'"
		cQuery += " GROUP BY SD2.D2_FILIAL "
		cQuery += " 		,SD2.D2_CLIENTE "
		cQuery += " 		,SA1.A1_NOME "
		cQuery += " 		,SD2.D2_COD "
		cQuery += " 		,SB1.B1_DESC "
		cQuery += " 		,SB1.B1_TIPO "
		cQuery += " 		,SB1.B1_UM "
		cQuery += " ORDER BY SD2.D2_FILIAL, SD2.D2_CLIENTE, SD2.D2_COD "
    	
    EndIf
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
	TRA->(DbGotop())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	//
	// IMPRIME FORNECEDOR
	oReport:PrintText(" ",,50)
	If mv_par06 = 1 
		oReport:PrintText("ENTRADA DE MATERIAL",,1000)
	Else
		oReport:PrintText("SAÍDA DE MATERIAL",,1000)
	EndIf
	oReport:PrintText(" ",,50)
	oReport:PrintText(" ",,50)
	
	sDestinatario:= ALLTRIM(TRA->DESTINATARIO) + ' - ' + ALLTRIM(TRA->NOME)
	oReport:PrintText(" ",,50)
	oReport:PrintText(sDestinatario,,50)
	oReport:ThinLine()
		
	While TRA->(!Eof())	
		sFilial := TRA -> FILIAL
		While sFilial = TRA -> FILIAL
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->FILIAL  	})
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->PRODUTO 	})
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->DESCRI 	})
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->TIPO		})
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->UM   		})
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| TRA->QTD 		})
			oSection1:Cell("COLUNA9")	:SetBlock   ({|| TRA->VLR  		})

			oSection1:PrintLine()
			
			DBSelectArea("TRA")
			dbskip()
		enddo
		DBSelectArea("TRA")
		oReport:PrintText(" ",,50)
	enddo
	oSection1:Finish()
	TRA->(DbCloseArea())
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                      TIPO TAM DEC VALID F3     Opcoes                      					Help
    aadd (_aRegsPerg, {01, "Emissao de      	:", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Emissao até     	:", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Filial de       	:", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Filial até      	:", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "Fornecedor/cliente  :", "C", 6, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {06, "Tipo   				:", "N", 1, 0,  "",  "   ", {"Fornecedor", "Cliente"},   					""})
     U_ValPerg (cPerg, _aRegsPerg)
Return
