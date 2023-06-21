// Programa.: VA_FATLOJ
// Autor....: Cláudia Lionço / Sandra Sugari
// Data.....: 27/12/2019
// Descricao: Relatorio de faturamento das lojas/vendas black friday - CUPONS
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de faturamento das lojas/vendas black friday - CUPONS
// #PalavasChave      #faturamento #lojas  #black_friday
// #TabelasPrincipais #SL1 
// #Modulos 		  #LOJA
//
// Historico de alteracoes:
// 04/02/2020 - Claudia - Incluído parametro de série/PDV
// 21/06/2023 - Claudia - Incluido PIX. GLPI: 13750
//
// ------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function VA_FATLOJ()
	Private oReport
	Private cPerg   := "VA_FATLOJ"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return

Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oSection3:= Nil
	Local oSection4:= Nil
	Local oSection5:= Nil
	Local oSection6:= Nil

	oReport := TReport():New("VA_FATLOJ","Lojas - Faturamento Detalhado de Cupons",cPerg,{|oReport| PrintReport(oReport)},"Lojas - Faturamento Detalhado de Cupons")
	
	oReport:SetPortrait()
	oReport:ShowHeader()
	//oReport:ShowParamPage() // imprime parametros
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Qnt.Cupons"		,               	    ,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Vlr.Total"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2_1", "" ,"Vlr.PIX"		    , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Vlr.Vales"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Cheques"		, "@E 999,999,999.99"	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Dinheiro"		, "@E 999,999,999.99"	,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Vlr.Convênio"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Vlr.Cartão CC"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Vlr.Cartão DB"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	//TRCell():New(oSection1,"COLUNA9", 	"" ,"Vlr.Médio Cupons"	, 	                 	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	 oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	 
	 oSection2:SetTotalInLine(.F.)
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"    		,               	    ,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.) 
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Qnt.Cupons"		,               	    ,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Vlr.Total"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3_1", "" ,"Vlr.PIX"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Vlr.Vales"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"Vlr.Cheques"		, "@E 999,999,999.99"	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"Vlr.Dinheiro"		, "@E 999,999,999.99"	,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"Vlr.Convênio"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA8", 	"" ,"Vlr.Cartão CC"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA9", 	"" ,"Vlr.Cartão DB"		, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	//TRCell():New(oSection2,"COLUNA10", 	"" ,"Qnt.Média Cupons"	, 	                 	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	 
	 oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	 
	 oSection3:SetTotalInLine(.F.)
	//TRCell():New(oSection3,"COLUNA1", 	"" ,"Emissão"    		,               	    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.) 
	TRCell():New(oSection3,"COLUNA2", 	"" ,"Produto"		    ,               	    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA3", 	"" ,"Descrição"			,                       ,80,/*lPixel*/,{|| 	},"LEFT" ,,"LEFT" ,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA4", 	"" ,"Unidade"			,                       ,06,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA5", 	"" ,"Quantidade"		, "@E 999,999,999.99"	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA6", 	"" ,"Valor"     		, "@E 999,999,999.99"	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	//TRCell():New(oSection3,"COLUNA7", 	"" ,"Tabela"	    	,                       ,06,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	 oSection4 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	 
	 oSection4:SetTotalInLine(.F.)
	//TRCell():New(oSection4,"COLUNA1", 	"" ,"Emissão"    		,               	    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.) 
	TRCell():New(oSection4,"COLUNA2", 	"" ,"Produto"		    ,               	    ,15,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection4,"COLUNA3", 	"" ,"Descrição"			,                       ,80,/*lPixel*/,{|| 	},"LEFT" ,,"LEFT" ,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA4", 	"" ,"Unidade"			,                       ,06,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection4,"COLUNA5", 	"" ,"Quantidade"		, "@E 999,999,999.99"	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection4,"COLUNA6", 	"" ,"Valor"     		, "@E 999,999,999.99"	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	//TRCell():New(oSection4,"COLUNA7", 	"" ,"Tabela"	    	,                       ,06,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	 oSection5 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	 
	oSection5:SetTotalInLine(.F.)
	TRCell():New(oSection5,"COLUNA1", 	"" ,"Hora"    		,               	    ,30,/*lPixel*/,{||  },"LEFT"  ,,"LEFT"  ,,,,,,.F.) 
	TRCell():New(oSection5,"COLUNA2", 	"" ,"Valor Venda"	, "@E 999,999,999.99"   ,25,/*lPixel*/,{||  },"LEFT"  ,,"LEFT"  ,,,,,,.F.)
	TRCell():New(oSection5,"COLUNA3", 	"" ,"Qnt. Cupons"	,                       ,20,/*lPixel*/,{|| 	},"RIGHT" ,,"RIGHT" ,,,,,,.F.)
	
	oSection6 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	 
	oSection6:SetTotalInLine(.F.)
	TRCell():New(oSection6,"COLUNA1", 	"" ,"Dia da semana" ,               	    ,30,/*lPixel*/,{||  },"LEFT"  ,,"LEFT"  ,,,,,,.F.) 
	TRCell():New(oSection6,"COLUNA2", 	"" ,"Valor Venda"	, "@E 999,999,999.99"   ,25,/*lPixel*/,{||  },"LEFT"  ,,"LEFT"  ,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA3", 	"" ,"Qnt. Cupons"	,                       ,20,/*lPixel*/,{|| 	},"RIGHT" ,,"RIGHT" ,,,,,,.F.)
	 
Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local oSection3 := oReport:Section(3)
	Local oSection4 := oReport:Section(4)
	Local oSection5 := oReport:Section(5)
	Local oSection6 := oReport:Section(6)
	Local cQuery1   := ""	
	Local cQuery2   := ""	
    Local cQuery3   := ""
    Local cQuery4   := ""
    Local cQuery5   := ""
    Local cQuery6   := ""
    Local cQuery7   := ""
    Local _aHora    := {}
    Local _aQCupom  := {}
    Local _aDados   := {}
    Local _aSemana  := {}
    Local nVendaTot := 0
    Local nTMaisV   := 0
    Local nTMaisVQ  := 0
    Local x         := 0
    Local y			:= 0
      
    // imprime os parametros
    oReport:PrintText(" ",,100)
    oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" Período de venda:" + dtoc(mv_par01) + " até " + dtoc(mv_par02),,100)
    oReport:PrintText(" Filial da venda :" + alltrim(mv_par03) + " até " + alltrim(mv_par04),,100)
    oReport:PrintText(" PDV             :" + alltrim(mv_par05),,100)
    oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
    oReport:PrintText(" ",,100)
    
    // SECTION 1 ------------------------------------------------------------------------------------------------------------------------------------------------
    // TOTAIS DAS LOJAS
    cQuery1 += " SELECT "
	cQuery1 += " 	 COUNT(*) AS EMITIDOS " 
	cQuery1 += "    ,ROUND(SUM(SL1.L1_VALBRUT), 2) AS VENDA_TOTAL "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_VALES), 2) AS VLR_VALES "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_CHEQUES), 2) AS VLR_CHEQUES "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_DINHEIR), 2) AS VLR_DINHEIRO "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_CONVENI), 2) AS VLR_CONVENIO "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_CARTAO), 2) AS VLR_CC "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_VLRDEBI), 2) AS VLR_DB "
	cQuery1 += "    ,ROUND(SUM(SL1.L1_OUTROS), 2) AS VLR_PIX "
	//cQuery1 += "    ,ROUND(SUM(SL1.L1_VALBRUT) / COUNT(*), 0) AS MEDIA_P_CUPOM "
	cQuery1 += " FROM " + RetSQLName ("SL1") + " SL1 "  
	cQuery1 += " WHERE SL1.D_E_L_E_T_ = '' "
	cQuery1 += " AND SL1.L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery1 += " AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery1 += " AND SL1.L1_SERIE != '999' "
	cQuery1 += " AND SL1.L1_SITUA = 'OK' "
	If !empty(mv_par05)
		cQuery1 += " AND SL1.L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery1), "TRA", .F., .T.)
	TRA->(DbGotop())

	oSection1:Init()
	oReport:PrintText(" VENDAS TOTAIS DAS LOJAS",,100)
	oReport:PrintText(" ",,800)
	
	oSection1:SetHeaderSection(.T.)
	
	While TRA->(!Eof())	
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->EMITIDOS  	})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->VENDA_TOTAL 	})
		oSection1:Cell("COLUNA2_1")	:SetBlock   ({|| TRA->VLR_PIX 		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->VLR_VALES		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->VLR_CHEQUES   })
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->VLR_DINHEIRO	})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->VLR_CONVENIO 	})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->VLR_CC 		})
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| TRA->VLR_DB 		})
		

		oSection1:PrintLine()
		
		nVendaTot += TRA->VENDA_TOTAL
		
		DBSelectArea("TRA")
		dbskip()
	Enddo
	
	oSection1:Finish()
	TRA->(DbCloseArea())
	
	// SECTION 2 ------------------------------------------------------------------------------------------------------------------------------------------------
	// TOTAIS POR LOJA
  	cQuery2 += " SELECT "
	cQuery2 += " SL1.L1_FILIAL AS FILIAL "
    cQuery2 += "    ,COUNT(*) AS EMITIDOS "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_VALBRUT), 2) AS VENDA_FILIAL "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_VALES), 2) AS VLR_VALES "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_CHEQUES), 2) AS VLR_CHEQUES "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_DINHEIR), 2) AS VLR_DINHEIRO "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_CONVENI), 2) AS VLR_CONVENIO "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_CARTAO), 2) AS VLR_CC "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_VLRDEBI), 2) AS VLR_DB "
	cQuery2 += "    ,ROUND(SUM(SL1.L1_OUTROS), 2) AS VLR_PIX "
    //cQuery2 += " ,ROUND(SUM(SL1.L1_VALBRUT) / COUNT(*), 0) AS MEDIA_P_CUPOM "
    cQuery2 += " FROM " + RetSQLName ("SL1") + " SL1 "
    cQuery2 += " WHERE SL1.D_E_L_E_T_ = '' "
    cQuery2 += " AND SL1.L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	cQuery2 += " AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
    cQuery2 += " AND SL1.L1_SERIE != '999' "
    cQuery2 += " AND SL1.L1_SITUA = 'OK' "
    If !empty(mv_par05)
		cQuery2 += " AND SL1.L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
    cQuery2 += " GROUP BY SL1.L1_FILIAL "
    cQuery2 += " ORDER BY VENDA_FILIAL DESC "
	
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery2), "TRB", .F., .T.)
	TRB->(DbGotop())

	oSection2:Init()
	oReport:PrintText(" ",,800)
	oReport:PrintText(" ",,800)
	oReport:PrintText(" VENDAS TOTAIS POR LOJAS",,100)
	oReport:PrintText(" ",,800)
	
	oSection2:SetHeaderSection(.T.)
	
	While TRB->(!Eof())	
	    oSection2:Cell("COLUNA1")	:SetBlock   ({|| TRB->FILIAL    	})
		oSection2:Cell("COLUNA2")	:SetBlock   ({|| TRB->EMITIDOS  	})
		oSection2:Cell("COLUNA3")	:SetBlock   ({|| TRB->VENDA_FILIAL 	})
		oSection2:Cell("COLUNA3_1")	:SetBlock   ({|| TRB->VLR_PIX 		})
		oSection2:Cell("COLUNA4")	:SetBlock   ({|| TRB->VLR_VALES		})
		oSection2:Cell("COLUNA5")	:SetBlock   ({|| TRB->VLR_CHEQUES   })
		oSection2:Cell("COLUNA6")	:SetBlock   ({|| TRB->VLR_DINHEIRO	})
		oSection2:Cell("COLUNA7")	:SetBlock   ({|| TRB->VLR_CONVENIO 	})
		oSection2:Cell("COLUNA8")	:SetBlock   ({|| TRB->VLR_CC 		})
		oSection2:Cell("COLUNA9")	:SetBlock   ({|| TRB->VLR_DB 		})
		
		//oSection2:Cell("COLUNA10")	:SetBlock   ({|| TRB->MEDIA_P_CUPOM })
		oSection2:PrintLine()
		
		DBSelectArea("TRB")
		dbskip()
	Enddo
	
	oSection2:Finish()
	TRB->(DbCloseArea())
	
	oReport:PrintText(" ",,100)
   	oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
    
    // SECTION 3 ------------------------------------------------------------------------------------------------------------------------------------------------
    // PRODUTOS MAIS VENDIDOS POR VALOR
	cQuery3 += " SELECT TOP 20 "
    cQuery3 += "  	SL2.L2_PRODUTO AS PRODUTO "
    cQuery3 += " 	,B1_DESC AS DESCRICAO"
    cQuery3 += " 	,L2_UM AS UM "
    cQuery3 += " 	,SUM(L2_QUANT) AS QUANTIDADE "
    cQuery3 += " 	,SUM(L2_VLRITEM) AS VALOR"
    cQuery3 += " FROM " + RetSQLName ("SL2") + " SL2 "
    cQuery3 += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
	cQuery3 += " 	ON (SB1.D_E_L_E_T_ = ''"
	cQuery3 += " 		AND B1_COD = L2_PRODUTO)"
    cQuery3 += " WHERE SL2.D_E_L_E_T_ = '' "
    cQuery3 += " 	AND L2_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	cQuery3 += " 	AND L2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
    cQuery3 += " 	AND L2_DOC <> '' "
    cQuery3 += " 	AND L2_SERIE <> '999' "
    If !empty(mv_par05)
    	cQuery3 += " AND L2_SERIE='" +alltrim(mv_par05)+ "'"
    EndIf
    cQuery3 += " GROUP BY "
	cQuery3 += "  	L2_PRODUTO "
	cQuery3 += " 	,B1_DESC "
	cQuery3 += " 	,L2_UM "
    cQuery3 += " ORDER BY SUM(L2_VLRITEM) DESC "
	
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery3), "TRC", .F., .T.)
	TRC->(DbGotop())

	oSection3:Init()
	oReport:PrintText(" ",,800)
	oReport:PrintText(" PRODUTOS MAIS VENDIDOS POR VALOR",,100)
	oReport:PrintText(" ",,800)
	
	oSection3:SetHeaderSection(.T.)
	
	While TRC->(!Eof())	
		//oSection3:Cell("COLUNA1")	:SetBlock   ({|| TRC->EMISSAO   	})
		oSection3:Cell("COLUNA2")	:SetBlock   ({|| TRC->PRODUTO    	})
		oSection3:Cell("COLUNA3")	:SetBlock   ({|| TRC->DESCRICAO 	})
		oSection3:Cell("COLUNA4")	:SetBlock   ({|| TRC->UM    		})
		oSection3:Cell("COLUNA5")	:SetBlock   ({|| TRC->QUANTIDADE    })
		oSection3:Cell("COLUNA6")	:SetBlock   ({|| TRC->VALOR     	})
		//oSection3:Cell("COLUNA7")	:SetBlock   ({|| TRC->TABELA    	})
		oSection3:PrintLine()
		
		nTMaisV	+= 	TRC->VALOR 
		DBSelectArea("TRC")
		dbskip()
	Enddo
	nPercMaisV := (nTMaisV * 100) /nVendaTot
	
	oReport:PrintText(" ",,100)
	oReport:PrintText(" * Percentual de valor dos produtos mais vendidos sobre o total vendido: " + Transform(nPercMaisV, "@E 999.99") +" %" ,,100)
	oReport:PrintText(" ",,100)
   	oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
	
	oSection3:Finish()
	TRC->(DbCloseArea())
	
	// SECTION 4 ------------------------------------------------------------------------------------------------------------------------------------------------
	// PRODUTOS MAIS VENDIDOS POR QUANTIDADE
	cQuery4 += " SELECT TOP 20 "
    cQuery4 += " 	 L2_PRODUTO AS PRODUTO "
    cQuery4 += " 	,B1_DESC AS DESCRICAO "
    cQuery4 += " 	,L2_UM AS UM "
    cQuery4 += " 	,SUM(L2_QUANT) AS QUANTIDADE "
    cQuery4 += " 	,SUM(L2_VLRITEM) AS VALOR "
    cQuery4 += " FROM " + RetSQLName ("SL2") + " SL2 "
    cQuery4 += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
	cQuery4 += " 	ON (SB1.D_E_L_E_T_ = ''"
	cQuery4 += " 		AND B1_COD = L2_PRODUTO)"
    cQuery4 += " WHERE SL2.D_E_L_E_T_ = '' "
    cQuery4 += " 	AND L2_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
	cQuery4 += " 	AND L2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
    cQuery4 += " 	AND L2_DOC <> '' "
    cQuery4 += " 	AND L2_SERIE <> '999' "
    If !empty(mv_par05)
    	cQuery4 += " AND L2_SERIE='" + alltrim(mv_par05) + "'"
    EndIf
    cQuery4 += " GROUP BY "
	cQuery4 += "  	L2_PRODUTO "
	cQuery4 += " 	,B1_DESC "
	cQuery4 += " 	,L2_UM "
    cQuery4 += " ORDER BY SUM(L2_QUANT) DESC "
	
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery4), "TRD", .F., .T.)
	TRD->(DbGotop())

	oSection4:Init()
	oReport:PrintText(" ",,800)
	oReport:PrintText(" PRODUTOS MAIS VENDIDOS POR QUANTIDADE",,100)
	oReport:PrintText(" ",,800)
	
	oSection4:SetHeaderSection(.T.)
	
	While TRD->(!Eof())	
		//oSection4:Cell("COLUNA1")	:SetBlock   ({|| TRD->EMISSAO   	})
		oSection4:Cell("COLUNA2")	:SetBlock   ({|| TRD->PRODUTO    	})
		oSection4:Cell("COLUNA3")	:SetBlock   ({|| TRD->DESCRICAO 	})
		oSection4:Cell("COLUNA4")	:SetBlock   ({|| TRD->UM    		})
		oSection4:Cell("COLUNA5")	:SetBlock   ({|| TRD->QUANTIDADE    })
		oSection4:Cell("COLUNA6")	:SetBlock   ({|| TRD->VALOR     	})
		//oSection4:Cell("COLUNA7")	:SetBlock   ({|| TRD->TABELA    	})
		oSection4:PrintLine()
		
		nTMaisVQ += TRD->VALOR 
		
		DBSelectArea("TRD")
		dbskip()
	Enddo
	nPercMaisQ := (nTMaisVQ * 100) /nVendaTot
	oReport:PrintText(" ",,100)
	oReport:PrintText(" * Percentual de valor dos produtos mais vendidos sobre o total vendido: " + Transform(nPercMaisQ, "@E 999.99") +" %" ,,100)
	oReport:PrintText(" ",,100)
   	oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
	
	oSection4:Finish()
	TRD->(DbCloseArea())
	
	oReport:EndPage()
	
   	// SECTION 5 ------------------------------------------------------------------------------------------------------------------------------------------------
	// VENDAS POR HORA
	cQuery5 += " SELECT"
	cQuery5 += " 	HORA"
	cQuery5 += "    ,VALOR"
	cQuery5 += " FROM (SELECT"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '00:00' AND '00:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_00,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '01:00' AND '01:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_01,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '02:00' AND '02:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_02,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '03:00' AND '03:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_03,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '04:00' AND '04:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_04,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '05:00' AND '05:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_05,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '06:00' AND '06:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_06,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '07:00' AND '07:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_07,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '08:00' AND '08:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_08,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '09:00' AND '09:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_09,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '10:00' AND '10:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_10,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '11:00' AND '11:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_11,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '12:00' AND '12:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_12,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '13:00' AND '13:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_13,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '14:00' AND '14:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_14,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '15:00' AND '15:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_15,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '16:00' AND '16:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_16,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '17:00' AND '17:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_17,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '18:00' AND '18:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_18,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '19:00' AND '19:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_19,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '20:00' AND '20:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_20,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '21:00' AND '21:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_21,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '22:00' AND '22:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_22,"
	cQuery5 += " 		SUM(CASE WHEN L1_HORA BETWEEN '23:00' AND '23:59' THEN L1_VALBRUT ELSE 0 END) AS HORA_23"
	cQuery5 += " 	FROM " + RetSQLName ("SL1") + " SL1 "
	cQuery5 += " 	WHERE D_E_L_E_T_ = ''"
	cQuery5 += " 	AND L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery5 += " 	AND L1_EMISNF BETWEEN  '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery5 += " 	AND L1_SERIE != '999'"
	If !empty(mv_par05)
			cQuery5 += " AND L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	cQuery5 += " 	AND L1_SITUA = 'OK') p"
	cQuery5 += " UNPIVOT"
	cQuery5 += " (VALOR FOR HORA IN"
	cQuery5 += " (HORA_00, HORA_01, HORA_02, HORA_03, HORA_04, HORA_05, HORA_06, HORA_07, HORA_08, HORA_09, HORA_10, HORA_11, HORA_12,"
	cQuery5 += " HORA_13, HORA_14, HORA_15, HORA_16, HORA_17, HORA_18, HORA_19, HORA_20, HORA_21, HORA_22, HORA_23)"
	cQuery5 += " ) AS TOTAL_HORAS"
	_aHora  := U_Qry2Array(cQuery5)	
		
		
	cQuery6 += " SELECT
	cQuery6 += " 	HORA
	cQuery6 += "    ,QTD_CUPONS
	cQuery6 += " FROM (SELECT"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '00:00' AND '00:59' THEN 1 ELSE 0 END) AS CUPONS_00,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '01:00' AND '01:59' THEN 1 ELSE 0 END) AS CUPONS_01,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '02:00' AND '02:59' THEN 1 ELSE 0 END) AS CUPONS_02,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '03:00' AND '03:59' THEN 1 ELSE 0 END) AS CUPONS_03,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '04:00' AND '04:59' THEN 1 ELSE 0 END) AS CUPONS_04,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '05:00' AND '05:59' THEN 1 ELSE 0 END) AS CUPONS_05,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '06:00' AND '06:59' THEN 1 ELSE 0 END) AS CUPONS_06,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '07:00' AND '07:59' THEN 1 ELSE 0 END) AS CUPONS_07,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '08:00' AND '08:59' THEN 1 ELSE 0 END) AS CUPONS_08,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '09:00' AND '09:59' THEN 1 ELSE 0 END) AS CUPONS_09,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '10:00' AND '10:59' THEN 1 ELSE 0 END) AS CUPONS_10,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '11:00' AND '11:59' THEN 1 ELSE 0 END) AS CUPONS_11,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '12:00' AND '12:59' THEN 1 ELSE 0 END) AS CUPONS_12,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '13:00' AND '13:59' THEN 1 ELSE 0 END) AS CUPONS_13,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '14:00' AND '14:59' THEN 1 ELSE 0 END) AS CUPONS_14,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '15:00' AND '15:59' THEN 1 ELSE 0 END) AS CUPONS_15,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '16:00' AND '16:59' THEN 1 ELSE 0 END) AS CUPONS_16,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '17:00' AND '17:59' THEN 1 ELSE 0 END) AS CUPONS_17,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '18:00' AND '18:59' THEN 1 ELSE 0 END) AS CUPONS_18,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '19:00' AND '19:59' THEN 1 ELSE 0 END) AS CUPONS_19,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '20:00' AND '20:59' THEN 1 ELSE 0 END) AS CUPONS_20,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '21:00' AND '21:59' THEN 1 ELSE 0 END) AS CUPONS_21,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '22:00' AND '22:59' THEN 1 ELSE 0 END) AS CUPONS_22,"
	cQuery6 += " 		SUM(CASE WHEN L1_HORA BETWEEN '23:00' AND '23:59' THEN 1 ELSE 0 END) AS CUPONS_23"
	cQuery6 += " 	FROM " + RetSQLName ("SL1") + " SL1 "
	cQuery6 += " 	WHERE D_E_L_E_T_ = ''"
	cQuery6 += " 	AND L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery6 += " 	AND L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery6 += " 	AND L1_SERIE != '999'"
	If !empty(mv_par05)
			cQuery6 += " AND L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	cQuery6 += " 	AND L1_SITUA = 'OK') p"
	cQuery6 += " UNPIVOT"
	cQuery6 += " (QTD_CUPONS FOR HORA IN"
	cQuery6 += " (CUPONS_00, CUPONS_01, CUPONS_02, CUPONS_03, CUPONS_04, CUPONS_05, CUPONS_06, CUPONS_07, CUPONS_08, CUPONS_09, CUPONS_10, CUPONS_11, CUPONS_12,"
	cQuery6 += " CUPONS_13, CUPONS_14, CUPONS_15, CUPONS_16, CUPONS_17, CUPONS_18, CUPONS_19, CUPONS_20, CUPONS_21, CUPONS_22, CUPONS_23)"
	cQuery6 += " ) AS TOTAL_CUPONS"	
	_aQCupom :=  U_Qry2Array(cQuery6)	
		
	For x:=1 to Len(_aHora)	
		_hora := x - 1
	
		If  _aHora[x,2] > 0
			aadd (_aDados,{ _hora, _aHora[x,2], _aQCupom[x,2] }) 
		EndIf
	Next
	
	ASORT(_aDados, , , { | x,y | x[2] > y[2] } )
	
	oSection5:Init()
	oReport:PrintText(" ",,800)
	oReport:PrintText(" VENDAS POR HORA",,100)
	oReport:PrintText(" ",,800)
	
	oSection5:SetHeaderSection(.T.)

	For y:=1 to len(_aDados)
		_horario := PADL(alltrim(str(_aDados[y,1])),2,'0') + ":00 até " +  PADL(alltrim(str(_aDados[y,1])),2,'0') + ":59"
		oSection5:Cell("COLUNA1")	:SetBlock   ({|| _horario     })
		oSection5:Cell("COLUNA2")	:SetBlock   ({|| _aDados[y,2] })
		oSection5:Cell("COLUNA3")	:SetBlock   ({|| _aDados[y,3] })
		oSection5:PrintLine()
	Next
	
	oReport:PrintText(" ",,100)
   	oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
    
	oSection5:Finish()
	
	// SECTION 6 ------------------------------------------------------------------------------------------------------------------------------------------------
	// VENDAS POR DIA DA SEMANA
	cQuery7 += " WITH C "
	cQuery7 += " AS"
	cQuery7 += " (SELECT"
	cQuery7 += " 		CASE DATEPART(DW, L1_EMISNF)"
	cQuery7 += " 			WHEN 1 THEN 'DOMINGO'
	cQuery7 += " 			WHEN 2 THEN 'SEGUNDA'"
	cQuery7 += " 			WHEN 3 THEN 'TERCA'
	cQuery7 += " 			WHEN 4 THEN 'QUARTA'"
	cQuery7 += " 			WHEN 5 THEN 'QUINTA'"
	cQuery7 += " 			WHEN 6 THEN 'SEXTA'"
	cQuery7 += " 			WHEN 7 THEN 'SABADO'"
	cQuery7 += " 		END DIA_SEMANA"
	cQuery7 += " 	   ,SUM(L1_VLRTOT) AS VALOR"
	cQuery7 += "       ,L1_NUM AS  CUPONS"
	cQuery7 += " 	FROM " + RetSQLName ("SL1") + " SL1 "
	cQuery7 += " 	WHERE D_E_L_E_T_ = ''"
	cQuery7 += " 	AND L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery7 += " 	AND L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery7 += " 	AND L1_SERIE != '999'"
	cQuery7 += " 	AND L1_SITUA = 'OK'"
	If !empty(mv_par05)
			cQuery7 += " AND L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	cQuery7 += " 	GROUP BY L1_EMISNF, L1_NUM )"
	cQuery7 += " SELECT"
	cQuery7 += " 	DIA_SEMANA"
	cQuery7 += "    ,SUM(VALOR) AS VALOR"
	cQuery7 += "    ,COUNT(CUPONS) AS CUPONS"
	cQuery7 += " FROM C"
	cQuery7 += " GROUP BY DIA_SEMANA"
	cQuery7 += " ORDER BY VALOR DESC"
	_aSemana :=  U_Qry2Array(cQuery7)	

	oSection6:Init()
	oReport:PrintText(" ",,800)
	oReport:PrintText(" ",,800)
	oReport:PrintText(" VENDAS POR DIA DA SEMANA",,100)
	oReport:PrintText(" ",,800)
	
	oSection6:SetHeaderSection(.T.)
	
	For x:=1 to Len(_aSemana)
		oSection6:Cell("COLUNA1")	:SetBlock   ({|| _aSemana[x,1]})
		oSection6:Cell("COLUNA2")	:SetBlock   ({|| _aSemana[x,2]})
		oSection6:Cell("COLUNA3")	:SetBlock   ({|| _aSemana[x,3]})
		oSection6:PrintLine()
	Next
	
	oReport:PrintText(" ",,100)
   	oReport:PrintText("-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
    oReport:PrintText(" ",,100)
	
	oSection6:Finish()
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Dt.venda de      	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Dt.venda até     	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Loja de       	    ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Loja até      	    ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "PDV         	    ", "C", 3, 0,  "",  "   ", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
