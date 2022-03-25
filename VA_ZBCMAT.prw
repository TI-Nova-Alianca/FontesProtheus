// Programa...: VA_ZBCMAT
// Autor......: Cláudia Lionço
// Data.......: 18/12/2019 
// Descricao..: Relatório de materias no planejamento de produção.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Relatório de materias no planejamento de produção.
// #PalavasChave      #materiais #planejamento_de_produção 
// #TabelasPrincipais #ZBC
// #Modulos   		  #PCP 
//
// Historico de alteracoes:
// 15/09/2021 - Claudia - Ajuste do b1_desc para descricao. GLPI: 10943
// 17/09/2021 - Claudia - Incluido tipo de produto e escondido o cabeçalho. GLPI: 10950
// 11/10/2021 - Claudia - Incluida coluna do almox 03. GLPI: 11036
// 25/03/2022 - Claudia - Incluido novo filtro para valores por filial/todas filiais. GLPI: 11818
//
// ------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_ZBCMAT()
	Private oReport
	Private cPerg   := "VA_ZBCMAT"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ------------------------------------------------------------------------------------------------
//
Static Function ReportDef()
	Local oReport  := Nil
	
	oReport := TReport():New("VA_ZBCMAT","Relação de materiais do planejamento",cPerg,{|oReport| PrintReport(oReport)},"Relação de materiais do planejamento")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	//oReport:ShowHeader()
	oReport:HideHeader() 
	
Return(oReport)
//
// ------------------------------------------------------------------------------------------------
//
Static Function PrintReport(oReport)
	Local oSection1 := Nil
	Local oSection2 := Nil
	Local oSection3 := Nil
	Local oSection4 := Nil
	Local cQuery    := ""	
	Local nAlx02 	:= 0
	Local nAlx07 	:= 0
	Local nAlx08 	:= 0
	Local nAlx90 	:= 0
	Local x			:= 0
	Local y			:= 0
	Local z		    := 0
	Local _lContinua:= .T.
	Private sDesc
	Private sTipo
	
	_aSC := {}
	_aPC := {}
	_aTC := {}
	If alltrim(mv_par08) == ''
		nPar08 := '0'
	Else
		nPar08 := mv_par08
	EndIf
	
	If alltrim(mv_par09) == 'Z' .or. alltrim(mv_par09) == 'z'
		nPar09 := '9'
	Else
		nPar09 := mv_par09
	EndIf
	// verifica se a pesquisa de meses é maior que 12 meses. Não é permitida essa alteração
	If mv_par10 == 2 // mes
		nDifMes := DateDiffMonth( mv_par01 , mv_par02) 
		nQtdMes := nDifMes + 1
		dDt     := mv_par01
		
		If nQtdMes > 12
			u_help("A quantidade de meses para pesquisa não poderá ser mais que 12 meses. A quantidade por mês não será efetuada!")
			_lContinua := .F.
		EndIf
	EndIf
	If _lContinua == .T.
		oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
		
		TRCell():New(oSection1,"COLUNA1", 	"" ,"Componente"	,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"		,   ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA2_1", "" ,"Tipo"		    ,   ,05,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		If mv_par10 == 1 // total
			TRCell():New(oSection1,"COLUNA3", 	"" ,"Qtd.Total"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
		Else // mensal
			TRCell():New(oSection1,"COL01", 	"" ,"Jan"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL02", 	"" ,"Fev"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL03", 	"" ,"Mar"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL04", 	"" ,"Abr"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL05", 	"" ,"Mai"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL06", 	"" ,"Jun"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL07", 	"" ,"Jul"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL08", 	"" ,"Ago"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL09", 	"" ,"Set"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL10", 	"" ,"Out"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL11", 	"" ,"Nov"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
			TRCell():New(oSection1,"COL12", 	"" ,"Dez"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
		EndIf
		TRCell():New(oSection1,"COLUNA4", 	"" ,"Alx.02"		,	,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA4_1", "" ,"Alx.03"		,	,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA5", 	"" ,"Alx.07"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA6", 	"" ,"Alx.08"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA7", 	"" ,"Alx.90"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA8", 	"" ,"SC"			,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA9", 	"" ,"Pedido"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA10", 	"" ,"Terceiros"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		If mv_par10 == 1 // total
			TRCell():New(oSection1,"COLUNA11", 	"" ,"Final"			,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		EndIf

		If mv_par10 == 1 // total
			cQuery := " WITH C (COMPONENTE, QTD_PLANEJ, QTD_ESTRUT, QNT_PROD)"
			cQuery += " AS"
			cQuery += " (SELECT"
			cQuery += " 		COMPONENTE"
			cQuery += " 	   ,SUM(QTD_PLANEJ)"
			cQuery += " 	   ,SUM(QTD_ESTRUT)"
			cQuery += " 	   ,SUM(QNT_PROD)"
			cQuery += " 	FROM dbo.VA_PLANCOMP('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) + "', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+ mv_par05 +"', '"+mv_par06+"', '"+nPar08+"', '"+nPar09+"')"
			cQuery += " 	GROUP BY COMPONENTE"
			cQuery += " 	UNION ALL"
			cQuery += " 	SELECT"
			cQuery += " 		COMPONENTE"
			cQuery += " 	   ,SUM(QTD_PLANEJ)"
			cQuery += " 	   ,SUM(QTD_ESTRUT)"
			cQuery += " 	   ,SUM(QNT_PROD)"
			cQuery += " 	FROM dbo.VA_PLANOPC('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) +"', '"+mv_par03+"', '"+mv_par04+"', '"+mv_par05+"', '"+mv_par06+"')"
			cQuery += " 	GROUP BY COMPONENTE)"
			cQuery += " SELECT"
			cQuery += " 	COMPONENTE"
			cQuery += "    ,SB1.B1_TIPO AS TIPOPROD "
			cQuery += "    ,SB1.B1_DESC AS DESCPROD "
			cQuery += "    ,SUM(QTD_PLANEJ) AS QTD_PLANEJ"
			cQuery += "    ,SUM(QTD_ESTRUT) AS QTD_ESTRUT"
			cQuery += "    ,SUM(QNT_PROD) AS QNT_PROD"
			cQuery += " FROM C"
			cQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			cQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			cQuery += " 		AND B1_COD = COMPONENTE "
			cQuery += " 		AND B1_TIPO BETWEEN '"+ mv_par11 + "' AND '" + mv_par12 +"' "
			cQuery += " 		)"
			cQuery += " GROUP BY COMPONENTE, SB1.B1_TIPO, SB1.B1_DESC "
			cQuery += " ORDER BY COMPONENTE, SB1.B1_TIPO"
		Else // mensal
			cQuery := " WITH C AS ("
			cQuery += " SELECT"
			cQuery += " 	COMPONENTE"
			cQuery += "    ,MES01 = SUM(CASE WHEN MES = 1 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES02 = SUM(CASE WHEN MES = 2 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES03 = SUM(CASE WHEN MES = 3 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES04 = SUM(CASE WHEN MES = 4 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES05 = SUM(CASE WHEN MES = 5 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES06 = SUM(CASE WHEN MES = 6 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES07 = SUM(CASE WHEN MES = 7 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES08 = SUM(CASE WHEN MES = 8 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES09 = SUM(CASE WHEN MES = 9 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES10 = SUM(CASE WHEN MES = 10 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES11 = SUM(CASE WHEN MES = 11 THEN QNT_PROD ELSE 0 END)"
			cQuery += "    ,MES12 = SUM(CASE WHEN MES = 12 THEN QNT_PROD ELSE 0 END)"
			cQuery += " FROM dbo.VA_ZBCMAT('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) + "', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+ mv_par05 +"', '"+mv_par06+"', '"+nPar08+"', '"+nPar09+"')"
			cQuery += " GROUP BY COMPONENTE"
			cQuery += " ) "
			cQuery += " SELECT "
			cQuery += " 	* "
			cQuery += " 	,SB1.B1_TIPO AS TIPOPROD "
			cQuery += "     ,SB1.B1_DESC AS DESCPROD "
			cQuery += " FROM C "
			cQuery += " INNER JOIN SB1010 SB1 "
			cQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			cQuery += " 		AND SB1.B1_COD = COMPONENTE "
			cQuery += " 		AND B1_TIPO BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
			cQuery += " )"
			cQuery += " ORDER BY COMPONENTE"
		EndIf

		DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		TRA->(DbGotop())
	
		oSection1:Init()
		oSection1:SetHeaderSection(.T.)	
	
		While TRA->(!Eof())
			If alltrim(TRA->TIPOPROD) == 'MO'
				nAlx02 := 0
				nAlx03 := 0
				nAlx07 := 0
				nAlx08 := 0
				nAlx90 := 0
				nSC    := 0
				nPC    := 0
				nTerc  := 0
				If mv_par10 == 1 // total
					nFinal := 0
				EndIf
			Else
				nAlx02 := U_ZBCBSaldo(TRA -> COMPONENTE ,'02', mv_par13)
				nAlx03 := U_ZBCBSaldo(TRA -> COMPONENTE ,'03', mv_par13)
				nAlx07 := U_ZBCBSaldo(TRA -> COMPONENTE ,'07', mv_par13)
				nAlx08 := U_ZBCBSaldo(TRA -> COMPONENTE ,'08', mv_par13)
				nAlx90 := U_ZBCBSaldo(TRA -> COMPONENTE ,'90', mv_par13)
				nSC    := U_ZBCBSC(TRA -> COMPONENTE, mv_par13)
				nPC    := U_ZBCBPC(TRA -> COMPONENTE, mv_par13)
				nTerc  := U_ZBCBTer(TRA -> COMPONENTE, mv_par13)
				If mv_par10 == 1 // total
					nFinal := (nAlx02 + nAlx07 + nAlx08 + nSC + nPC) - TRA->QNT_PROD
				EndIf
			EndIf
			
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->COMPONENTE })
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->DESCPROD	 })
			oSection1:Cell("COLUNA2_1")	:SetBlock   ({|| TRA->TIPOPROD 	 })
			If mv_par10 == 1 // total
				oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->QNT_PROD	 })
			Else
				oSection1:Cell("COL01")	:SetBlock   ({|| TRA->MES01			 })
				oSection1:Cell("COL02")	:SetBlock   ({|| TRA->MES02			 })
				oSection1:Cell("COL03")	:SetBlock   ({|| TRA->MES03			 })
				oSection1:Cell("COL04")	:SetBlock   ({|| TRA->MES04			 })
				oSection1:Cell("COL05")	:SetBlock   ({|| TRA->MES05			 })
				oSection1:Cell("COL06")	:SetBlock   ({|| TRA->MES06			 })
				oSection1:Cell("COL07")	:SetBlock   ({|| TRA->MES07			 })
				oSection1:Cell("COL08")	:SetBlock   ({|| TRA->MES08			 })
				oSection1:Cell("COL09")	:SetBlock   ({|| TRA->MES09			 })
				oSection1:Cell("COL10")	:SetBlock   ({|| TRA->MES10			 })
				oSection1:Cell("COL11")	:SetBlock   ({|| TRA->MES11			 })
				oSection1:Cell("COL12")	:SetBlock   ({|| TRA->MES12			 })
			EndIf
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| nAlx02			 })
			oSection1:Cell("COLUNA4_1")	:SetBlock   ({|| nAlx03			 })
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| nAlx07 		 })
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| nAlx08 		 })
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| nAlx90 		 })
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| nSC 		 	 })
			oSection1:Cell("COLUNA9")	:SetBlock   ({|| nPC 		 	 })
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| nTerc 		 	 })
			If mv_par10 == 1 // total
				oSection1:Cell("COLUNA11")	:SetBlock   ({|| nFinal 		 })
			EndIf
		
			oSection1:PrintLine()
	
			DBSelectArea("TRA")
			dbskip()
		Enddo
		oSection1:Finish()
		TRA->(DbCloseArea())
		
		If mv_par07 == 2
			// SOLICITAÇÃO DE COMPRAS
			oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
			TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA2", 	"" ,"Num.Solicit."	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA3", 	"" ,"Produto"		,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA4", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA5", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA6", 	"" ,"Solicitante"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection2,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
			
			oReport:PrintText(" ",,100)
			oReport:PrintText(" ",,100)
			oReport:PrintText("------------------------------------- SOLICITAÇÕES DE COMPRA ",,5)
			oSection2:Init()
			
			For x:=1 to len(_aSC)
				oSection2:Cell("COLUNA1"):SetBlock({|| _aSC[x,1]})
				oSection2:Cell("COLUNA2"):SetBlock({|| _aSC[x,2]})
				oSection2:Cell("COLUNA3"):SetBlock({|| _aSC[x,3]})
				oSection2:Cell("COLUNA4"):SetBlock({|| _aSC[x,4]})
				oSection2:Cell("COLUNA5"):SetBlock({|| STOD(_aSC[x,5])})
				oSection2:Cell("COLUNA6"):SetBlock({|| _aSC[x,6]})
				oSection2:Cell("COLUNA7"):SetBlock({|| _aSC[x,7]})
				
				oSection2:PrintLine()
			Next
			oSection2:Finish()
			
			// PEDIDO DE COMPRAS
			oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
			TRCell():New(oSection3,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA2", 	"" ,"Num.Pedido"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA3", 	"" ,"Produto"		,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA4", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA5", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA6", 	"" ,"Solicitante"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection3,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	
			oReport:PrintText(" ",,100)
			oReport:PrintText(" ",,100)
			oReport:PrintText("------------------------------------- PEDIDOS DE COMPRA ",,5)
			oSection3:Init()
			
			For y:=1 to len(_aPC)
				oSection3:Cell("COLUNA1"):SetBlock({|| _aPC[y,1]})
				oSection3:Cell("COLUNA2"):SetBlock({|| _aPC[y,2]})
				oSection3:Cell("COLUNA3"):SetBlock({|| _aPC[y,3]})
				oSection3:Cell("COLUNA4"):SetBlock({|| _aPC[y,4]})
				oSection3:Cell("COLUNA5"):SetBlock({|| STOD(_aPC[y,5])})
				oSection3:Cell("COLUNA6"):SetBlock({|| _aPC[y,6]})
				oSection3:Cell("COLUNA7"):SetBlock({|| _aPC[y,7]})
				
				oSection3:PrintLine()
			Next	
			oSection3:Finish()
			
			// EM TERCEIROS
			oSection4 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
			TRCell():New(oSection4,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA2", 	"" ,"NF"			,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA3", 	"" ,"Série"			,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA4", 	"" ,"Produto"		,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA5", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA6", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
			TRCell():New(oSection4,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	
			oReport:PrintText(" ",,100)
			oReport:PrintText(" ",,100)
			oReport:PrintText("------------------------------------- EM TERCEIROS ",,5)
			oSection4:Init()
			
			For z:=1 to len(_aTC)
				oSection4:Cell("COLUNA1"):SetBlock({|| _aTC[z,1]})
				oSection4:Cell("COLUNA2"):SetBlock({|| _aTC[z,2]})
				oSection4:Cell("COLUNA3"):SetBlock({|| _aTC[z,3]})
				oSection4:Cell("COLUNA4"):SetBlock({|| _aTC[z,4]})
				oSection4:Cell("COLUNA5"):SetBlock({|| _aTC[z,5]})
				oSection4:Cell("COLUNA6"):SetBlock({|| _aTC[z,6]})
				oSection4:Cell("COLUNA7"):SetBlock({|| _aTC[z,7]})
				
				oSection4:PrintLine()
			Next
			oSection4:Finish()
		EndIf
	EndIf
Return
//
// ----------------------------------------------------------------------------------
// Busca o saldo nos almoxarifados correspondentes
User Function ZBCBSaldo(sComp, sAlx, _sParFil)
	Local nQtdAlx := 0
	Local cQuery1 := ""
	
	cQuery1 += " SELECT"
	cQuery1 += " 		B2_COD"
	cQuery1 += " 	   ,B2_LOCAL "
	cQuery1 += " 	   ,SUM(B2_QATU) AS QTD"
	cQuery1 += " 	FROM " + RetSqlName("SB2")
	cQuery1 += " 	WHERE D_E_L_E_T_ = ''"
	If _sParFil == 1
		cQuery1 += " 	AND B2_FILIAL = '" + xfilial ("SB2") + "'"
	EndIf
	cQuery1 += " 	AND B2_COD = '" + sComp + "'"
	cQuery1 += " 	AND B2_LOCAL ='" + sAlx + "'"
	cQuery1 += " 	GROUP BY B2_COD"
	cQuery1 += " 			,B2_LOCAL"
	cQuery1 += " 	ORDER BY B2_COD, B2_LOCAL  "
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery1), "TRB", .F., .T.)
	TRB->(DbGotop())
	
	While TRB->(!Eof())	
		nQtdAlx := TRB -> QTD
		
		DBSelectArea("TRB")
		dbskip()
	Enddo
	TRB->(DbCloseArea())
	
Return nQtdAlx
//
// ----------------------------------------------------------------------------------
// Busca o saldo das solicitações de compras
User Function ZBCBSC(sComp, _sParFil)
	Local nQtdSC  := 0
	Local cQuery2 := ""
	
	cQuery2 += " SELECT"
	cQuery2 += " 	 C1_FILIAL AS FILIAL
    cQuery2 += " 	,C1_NUM AS SOLICITACAO
    cQuery2 += " 	,C1_PRODUTO AS PRODUTO
    cQuery2 += " 	,C1_DESCRI AS DESCRICAO
    cQuery2 += " 	,C1_EMISSAO AS EMISSAO
    cQuery2 += " 	,C1_SOLICIT AS SOLICITANTE
    cQuery2 += " 	,C1_QUANT
    cQuery2 += " 	,C1_QUJE
    cQuery2 += " 	,(C1_QUANT - C1_QUJE) AS SALDO
	cQuery2 += " FROM " + RetSqlName("SC1")
	cQuery2 += " WHERE D_E_L_E_T_ = ''"
	If _sParFil == 1
		cQuery2 += " 	AND C1_FILIAL = '" + xfilial ("SC1") + "'"
	EndIf
	cQuery2 += " AND C1_PRODUTO = '" + sComp + "'"
	cQuery2 += " AND (C1_QUANT - C1_QUJE) > 0"
	cQuery2 += " AND C1_RESIDUO = ''"
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery2), "TRC", .F., .T.)
	TRC->(DbGotop())
	
	While TRC->(!Eof())	
		AADD(_aSC,{TRC->FILIAL, TRC->SOLICITACAO, TRC->PRODUTO, TRC->DESCRICAO, TRC->EMISSAO, TRC->SOLICITANTE, TRC->SALDO})
		
		nQtdSC += TRC -> SALDO
		
		DBSelectArea("TRC")
		dbskip()
	Enddo
	TRC->(DbCloseArea())
Return nQtdSC
//
// ----------------------------------------------------------------------------------
// Busca o saldo dos pedidos de compras
User Function ZBCBPC(sComp, _sParFil)
	Local nQtdPC  := 0
	Local cQuery3 := ""
	
	cQuery3 += " SELECT"
	cQuery3 += "  C7_FILIAL AS FILIAL"
	cQuery3 += " ,C7_NUM AS SOLICITACAO"
	cQuery3 += " ,C7_PRODUTO AS PRODUTO"
	cQuery3 += " ,C7_DESCRI AS DESCRICAO"
	cQuery3 += " ,C7_EMISSAO AS EMISSAO"
	cQuery3 += " ,C7_SOLICIT AS SOLICITANTE"
	cQuery3 += " ,C7_QUANT"
	cQuery3 += " ,C7_QUJE"
	cQuery3 += " ,(C7_QUANT - C7_QUJE) AS SALDO"
	cQuery3 += " FROM " + RetSqlName("SC7")
	cQuery3 += " WHERE D_E_L_E_T_ = ''"
	If _sParFil == 1
		cQuery3 += " 	AND C7_FILIAL = '" + xfilial ("SC7") + "'"
	EndIf
	cQuery3 += " AND C7_PRODUTO = '" + sComp + "'"
	cQuery3 += " AND (C7_QUANT - C7_QUJE) > 0"
	cQuery3 += " AND C7_RESIDUO = ''"
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery3), "TRD", .F., .T.)
	TRD->(DbGotop())
	
	While TRD->(!Eof())	
		AADD(_aPC,{TRD->FILIAL, TRD->SOLICITACAO, TRD->PRODUTO, TRD->DESCRICAO, TRD->EMISSAO, TRD->SOLICITANTE, TRD->SALDO})
		nQtdPC += TRD -> SALDO
		
		DBSelectArea("TRD")
		dbskip()
	Enddo
	TRD->(DbCloseArea())
Return nQtdPC
//
// ----------------------------------------------------------------------------------
// Busca saldo de terceiros
User Function ZBCBTer(sComp, _sParFil)
	Local nQtdTerc := 0
	Local cQuery4  := ""
	
	cQuery4 += " SELECT"
	cQuery4 += " 	 B6_FILIAL AS FILIAL"
    cQuery4 += " 	,B6_DOC AS NF"
    cQuery4 += " 	,B6_SERIE AS SERIE"
    cQuery4 += " 	,B6_PRODUTO AS PRODUTO"
    cQuery4 += " 	,V.DESCRICAO AS DESCRICAO"
    cQuery4 += " 	,dbo.VA_DTOC(B6_EMISSAO) AS EMISSAO"
    cQuery4 += " 	,B6_SALDO AS SALDO"
	cQuery4 += " FROM dbo.VA_VSALDOS_TERCEIROS V"
	cQuery4 += " WHERE B6_PRODUTO = '" + sComp + "'"
	If _sParFil == 1
		cQuery4 += " 	AND B6_FILIAL = '" + xfilial ("SB6") + "'"
	EndIf
	cQuery4 += " ORDER BY B6_EMISSAO, B6_DOC, B6_PRODUTO "
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery4), "TRE", .F., .T.)
	TRE->(DbGotop())
	
	While TRE->(!Eof())	
		AADD(_aTC,{TRE->FILIAL, TRE->NF, TRE->SERIE, TRE->PRODUTO, TRE->DESCRICAO, TRE->EMISSAO, TRE->SALDO})
		nQtdTerc += TRE -> SALDO
		
		DBSelectArea("TRE")
		dbskip()
	Enddo
	TRE->(DbCloseArea())
Return nQtdTerc
//
// ------------------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      			     	Help
    aadd (_aRegsPerg, {01, "Data de      	   ", "D", 8, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {02, "Data até    	   ", "D", 8, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {03, "Evento de          ", "C", 3, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {04, "Evento até         ", "C", 3, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {05, "Ano de             ", "C", 4, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {06, "Ano até            ", "C", 4, 0,    "",  "   ", {}                         				,""})   
    aadd (_aRegsPerg, {07, "Tipo Rel.          ", "N", 1, 0,    "",  "   ", {"Sintético","Analítico"}				,""})
    aadd (_aRegsPerg, {08, "Nivel estr. de     ", "C", 1, 0,    "",  "   ", {}										,""})
    aadd (_aRegsPerg, {09, "Nivel estr. ate    ", "C", 1, 0,    "",  "   ", {}										,""})
    aadd (_aRegsPerg, {10, "Imprime mensal     ", "N", 1, 0,    "",  "   ", {"Não","Sim"}							,""})
	aadd (_aRegsPerg, {11, "Tipo prod.de       ", "C", 2, 0,    "",  "02" , {}                         				,""})
	aadd (_aRegsPerg, {12, "Tipo prod.ate      ", "C", 2, 0,    "",  "02" , {}                         				,""})
	aadd (_aRegsPerg, {13, "Agrupa vlrs.filial ", "N", 1, 0,    "",  "   ", {"Filial logada","Todas filiais"}		,""})
    
	U_ValPerg (cPerg, _aRegsPerg)
Return
