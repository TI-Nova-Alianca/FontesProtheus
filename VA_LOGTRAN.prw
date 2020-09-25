// Programa:  VA_LOGTRAN
// Autor:     Cláudia Lionço
// Data:      13/02/2020
// Descricao: Relatório de transferencia entre almoxarifados
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_LOGTRAN()
	Private oReport
	Private cPerg   := "VA_LOGTRAN"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return

Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oBreak1
	Local oFunction

	oReport := TReport():New("VA_LOGTRAN","Transferencias de estoque",cPerg,{|oReport| PrintReport(oReport)},"Transferencias de estoque")
	
	oReport:SetPortrait()
	oReport:ShowHeader()
	//oReport:ShowParamPage() // imprime parametros
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Produto"			,   ,20,/*lPixel*/,{||  },"LEFT",,"LEFT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"			,   ,40,/*lPixel*/,{|| 	},"LEFT",,"LEFT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Emissão"			,   ,20,/*lPixel*/,{|| 	},"LEFT",,"LEFT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Unidade"		    , 	,10,/*lPixel*/,{|| 	},"LEFT",,"LEFT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Quantidade"		,	,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Almox.Origem"		,   ,16,/*lPixel*/,{|| 	},"CENTER",,"CENTER",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Almox.Destino"		,   ,16,/*lPixel*/,{|| 	},"CENTER",,"CENTER",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Motivo"			,   ,30,/*lPixel*/,{|| 	},"LEFT",,"LEFT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Usuário"			,   ,20,/*lPixel*/,{|| 	},"LEFT",,"LEFT",,,,,,.F.)
	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA6"),"Total Por Almox.Origem")
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Quantidade " , , NIL, .F., .T.)
Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery1   := ""	

    // SECTION 1 ------------------------------------------------------------------------------------------------------------------------------------------------
    // TOTAIS DAS LOJAS
    
	cQuery1 += " SELECT "
	cQuery1 += " 	SD3.D3_COD AS PRODUTO "
	cQuery1 += "    ,SB1.B1_DESC AS DESCRICAO "
	cQuery1 += "    ,SD3.D3_EMISSAO AS EMISSAO "
	cQuery1 += "    ,SD3.D3_UM AS UNIDADE "
	cQuery1 += "    ,SD3.D3_QUANT AS QUANTIDADE "
	cQuery1 += "    ,SD3.D3_LOCAL AS LOCAL_ORIGEM "
	cQuery1 += "    ,SD3_1.D3_LOCAL AS LOCAL_DESTINO "
	cQuery1 += "    ,SD3_1.D3_VAMOTIV AS MOTIVO "
	cQuery1 += "    ,SD3_1.D3_USUARIO AS USUARIO "
	cQuery1 += " FROM " + RetSQLName ("SD3") + " SD3 " 
	cQuery1 += " INNER JOIN " + RetSQLName ("SD3") + " SD3_1 "     
	cQuery1 += " 	ON ("
	cQuery1 += " 			SD3_1.D_E_L_E_T_ = '' "
	cQuery1 += " 			AND SD3_1.D3_CF = 'DE4' "
	cQuery1 += " 			AND SD3_1.D3_DOC = SD3.D3_DOC "
	cQuery1 += " 			AND SD3_1.D3_EMISSAO = SD3.D3_EMISSAO "
	cQuery1 += " 			AND SD3_1.D3_COD = SD3.D3_COD " 
	If !empty(mv_par06)
		cQuery1 += " 			AND SD3_1.D3_LOCAL = '" + mv_par06 + "'"
	EndIf
	cQuery1 += " 		)"
	cQuery1 += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
	cQuery1 += " 	ON (SB1.D_E_L_E_T_ = '' "
	cQuery1 += " 			AND SB1.B1_COD = SD3.D3_COD) "
	cQuery1 += " WHERE SD3.D_E_L_E_T_ = '' "
	cQuery1 += " AND SD3.D3_CF = 'RE4' "
	If !empty(mv_par05)
		cQuery1 += " AND SD3.D3_LOCAL = '" + mv_par05 + "'"
	EndIf
	cQuery1 += " AND SD3.D3_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery1 += " AND SD3.D3_COD BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery1 += " ORDER BY LOCAL_ORIGEM, EMISSAO "

    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery1), "TRA", .F., .T.)
	TRA->(DbGotop())

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	dDT := DTOC(STOD(TRA -> EMISSAO)) 
	While TRA->(!Eof())	
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA -> PRODUTO 		})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA -> DESCRICAO		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| dDT 					})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA -> UNIDADE 		})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA -> QUANTIDADE		})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA -> LOCAL_ORIGEM	})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA -> LOCAL_DESTINO	})
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| TRA -> MOTIVO			})
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| TRA -> USUARIO			})
		oSection1:PrintLine()
		
		DBSelectArea("TRA")
		dbskip()
	Enddo
	
	oSection1:Finish()
	TRA->(DbCloseArea())
	
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNTA           TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Emissão de     	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Emissão até    	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Produto de      ", "C",15, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Produto até    	", "C",15, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "Almox.Origem   	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {06, "Almox.Destino   ", "C", 2, 0,  "",  "   ", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
