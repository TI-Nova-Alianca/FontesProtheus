// Programa...: VA_ZBCMDI
// Autor......: Cláudia Lionço
// Data.......: 27/12/2019 
// Descricao..: Relatório de materias no planejamento de produção - Por dia
// GLPI.......: 7260
// ------------------------------------------------------------------------------------------------
//
#include 'protheus.ch'
#include 'parmtype.ch'

user function VA_ZBCMDI()
	Private oReport
	Private cPerg   := "VA_ZBCMDI"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
return
//
Static Function ReportDef()
	Local oReport  := Nil

	oReport := TReport():New("VA_ZBCMDI","Relação de materiais do planejamento - Por dia",cPerg,{|oReport| PrintReport(oReport)},"Relação de materiais do planejamento - Por dia")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
Return(oReport)
//
Static Function PrintReport(oReport)
	Local oSection1 := Nil
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
	//
	// Converte datas do mes selecionado
	sMes   := PADL(mv_par01,2,'0')
	sAno   := mv_par02
	sDtIni := sAno+sMes+'01'
	dDtIni := STOD(sDtIni)
	dDtFim := lastDate(dDtIni)
	sDtFim := DTOS(dDtFim)
	//
	//u_help("dtini:"+sDtIni+" Dtfin:"+sDtFim)
	//
	_aSC := {}
	_aPC := {}
	_aTC := {}
	//
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
	//
	If _lContinua == .T.
		oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
		
		TRCell():New(oSection1,"COLUNA1", 	"" ,"Componente"	,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"		,   ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)	
		TRCell():New(oSection1,"DIA01", 	"" ,"01"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA02", 	"" ,"02"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA03", 	"" ,"03"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA04", 	"" ,"04"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA05", 	"" ,"05"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA06", 	"" ,"06"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA07", 	"" ,"07"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA08", 	"" ,"08"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA09", 	"" ,"09"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA10", 	"" ,"10"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA11", 	"" ,"11"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA12", 	"" ,"12"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA13", 	"" ,"13"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA14", 	"" ,"14"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA15", 	"" ,"15"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA16", 	"" ,"16"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA17", 	"" ,"17"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA18", 	"" ,"18"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA19", 	"" ,"19"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA20", 	"" ,"20"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA21", 	"" ,"21"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA22", 	"" ,"22"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA23", 	"" ,"23"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA24", 	"" ,"24"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA25", 	"" ,"25"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA26", 	"" ,"26"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA27", 	"" ,"27"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA28", 	"" ,"28"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA29", 	"" ,"29"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA30", 	"" ,"30"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"DIA31", 	"" ,"31"		,   ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
		TRCell():New(oSection1,"COLUNA4", 	"" ,"Alx.02"		,	,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA5", 	"" ,"Alx.07"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA6", 	"" ,"Alx.08"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA7", 	"" ,"Alx.90"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA8", 	"" ,"SC"			,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA9", 	"" ,"Pedido"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
		TRCell():New(oSection1,"COLUNA10", 	"" ,"Terceiros"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)


		cQuery := " SELECT"
		cQuery += " 	COMPONENTE"
		cQuery += "    ,DIA01 = SUM(CASE WHEN DAY(DTPLANEJ)  =  1 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA02 = SUM(CASE WHEN DAY(DTPLANEJ)  =  2 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA03 = SUM(CASE WHEN DAY(DTPLANEJ)  =  3 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA04 = SUM(CASE WHEN DAY(DTPLANEJ)  =  4 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA05 = SUM(CASE WHEN DAY(DTPLANEJ)  =  5 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA06 = SUM(CASE WHEN DAY(DTPLANEJ)  =  6 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA07 = SUM(CASE WHEN DAY(DTPLANEJ)  =  7 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA08 = SUM(CASE WHEN DAY(DTPLANEJ)  =  8 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA09 = SUM(CASE WHEN DAY(DTPLANEJ)  =  9 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA10 = SUM(CASE WHEN DAY(DTPLANEJ)  = 10 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA11 = SUM(CASE WHEN DAY(DTPLANEJ)  = 11 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA12 = SUM(CASE WHEN DAY(DTPLANEJ)  = 12 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA13 = SUM(CASE WHEN DAY(DTPLANEJ)  = 13 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA14 = SUM(CASE WHEN DAY(DTPLANEJ)  = 14 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA15 = SUM(CASE WHEN DAY(DTPLANEJ)  = 15 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA16 = SUM(CASE WHEN DAY(DTPLANEJ)  = 16 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA17 = SUM(CASE WHEN DAY(DTPLANEJ)  = 17 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA18 = SUM(CASE WHEN DAY(DTPLANEJ)  = 18 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA19 = SUM(CASE WHEN DAY(DTPLANEJ)  = 19 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA20 = SUM(CASE WHEN DAY(DTPLANEJ)  = 20 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA21 = SUM(CASE WHEN DAY(DTPLANEJ)  = 21 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA22 = SUM(CASE WHEN DAY(DTPLANEJ)  = 22 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA23 = SUM(CASE WHEN DAY(DTPLANEJ)  = 23 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA24 = SUM(CASE WHEN DAY(DTPLANEJ)  = 24 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA25 = SUM(CASE WHEN DAY(DTPLANEJ)  = 25 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA26 = SUM(CASE WHEN DAY(DTPLANEJ)  = 26 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA27 = SUM(CASE WHEN DAY(DTPLANEJ)  = 27 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA28 = SUM(CASE WHEN DAY(DTPLANEJ)  = 28 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA29 = SUM(CASE WHEN DAY(DTPLANEJ)  = 29 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA30 = SUM(CASE WHEN DAY(DTPLANEJ)  = 30 THEN QNT_PROD ELSE 0 END)"
		cQuery += "    ,DIA31 = SUM(CASE WHEN DAY(DTPLANEJ)  = 31 THEN QNT_PROD ELSE 0 END)"
		cQuery += " FROM dbo.VA_ZBCMAT('"+ DTOS(dDtIni) +"', '"+ DTOS(dDtFim) + "', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+ mv_par05 +"', '"+mv_par06+"', '"+nPar08+"', '"+nPar09+"')"
		cQuery += " GROUP BY COMPONENTE"
		cQuery += " ORDER BY COMPONENTE"
		
		DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		TRA->(DbGotop())
	
		oSection1:Init()
		oSection1:SetHeaderSection(.T.)	
	
		While TRA->(!Eof())
			_BuscaDescProduto (TRA -> COMPONENTE, @sDesc, @sTipo)
	
			If alltrim(sTipo) == 'MO'
				nAlx02 := 0
				nAlx07 := 0
				nAlx08 := 0
				nAlx90 := 0
				nSC    := 0
				nPC    := 0
				nTerc  := 0
			Else
				nAlx02 := U_ZBCBSaldo(TRA -> COMPONENTE ,'02')
				nAlx07 := U_ZBCBSaldo(TRA -> COMPONENTE ,'07')
				nAlx08 := U_ZBCBSaldo(TRA -> COMPONENTE ,'08')
				nAlx90 := U_ZBCBSaldo(TRA -> COMPONENTE ,'90')
				nSC    := U_ZBCBSC(TRA -> COMPONENTE)
				nPC    := U_ZBCBPC(TRA -> COMPONENTE)
				nTerc  := U_ZBCBTer(TRA -> COMPONENTE)
			EndIf
			
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->COMPONENTE })
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| sDesc 	 		 })
			oSection1:Cell("DIA01")		:SetBlock   ({|| TRA->DIA01 	 })
			oSection1:Cell("DIA02")		:SetBlock   ({|| TRA->DIA02 	 })
			oSection1:Cell("DIA03")		:SetBlock   ({|| TRA->DIA03 	 })
			oSection1:Cell("DIA04")		:SetBlock   ({|| TRA->DIA04 	 })
			oSection1:Cell("DIA05")		:SetBlock   ({|| TRA->DIA05 	 })
			oSection1:Cell("DIA06")		:SetBlock   ({|| TRA->DIA06 	 })
			oSection1:Cell("DIA07")		:SetBlock   ({|| TRA->DIA07 	 })
			oSection1:Cell("DIA08")		:SetBlock   ({|| TRA->DIA08 	 })
			oSection1:Cell("DIA09")		:SetBlock   ({|| TRA->DIA09 	 })
			oSection1:Cell("DIA10")		:SetBlock   ({|| TRA->DIA10 	 })
			oSection1:Cell("DIA11")		:SetBlock   ({|| TRA->DIA11 	 })
			oSection1:Cell("DIA12")		:SetBlock   ({|| TRA->DIA12 	 })
			oSection1:Cell("DIA13")		:SetBlock   ({|| TRA->DIA13 	 })
			oSection1:Cell("DIA14")		:SetBlock   ({|| TRA->DIA14 	 })
			oSection1:Cell("DIA15")		:SetBlock   ({|| TRA->DIA15 	 })
			oSection1:Cell("DIA16")		:SetBlock   ({|| TRA->DIA16 	 })
			oSection1:Cell("DIA17")		:SetBlock   ({|| TRA->DIA17 	 })
			oSection1:Cell("DIA18")		:SetBlock   ({|| TRA->DIA18 	 })
			oSection1:Cell("DIA19")		:SetBlock   ({|| TRA->DIA19 	 })
			oSection1:Cell("DIA20")		:SetBlock   ({|| TRA->DIA20 	 })
			oSection1:Cell("DIA21")		:SetBlock   ({|| TRA->DIA21 	 })
			oSection1:Cell("DIA22")		:SetBlock   ({|| TRA->DIA22 	 })
			oSection1:Cell("DIA23")		:SetBlock   ({|| TRA->DIA23 	 })
			oSection1:Cell("DIA24")		:SetBlock   ({|| TRA->DIA24 	 })
			oSection1:Cell("DIA25")		:SetBlock   ({|| TRA->DIA25 	 })
			oSection1:Cell("DIA26")		:SetBlock   ({|| TRA->DIA26 	 })
			oSection1:Cell("DIA27")		:SetBlock   ({|| TRA->DIA27 	 })
			oSection1:Cell("DIA28")		:SetBlock   ({|| TRA->DIA28 	 })
			oSection1:Cell("DIA29")		:SetBlock   ({|| TRA->DIA29 	 })
			oSection1:Cell("DIA30")		:SetBlock   ({|| TRA->DIA30 	 })
			oSection1:Cell("DIA31")		:SetBlock   ({|| TRA->DIA31 	 })
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| nAlx02			 })
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| nAlx07 		 })
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| nAlx08 		 })
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| nAlx90 		 })
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| nSC 		 	 })
			oSection1:Cell("COLUNA9")	:SetBlock   ({|| nPC 		 	 })
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| nTerc 		 	 })
		
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
			//
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
			//
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
		EndIf // If mv_par07 == 2
		
		_ImpFiltros()
	EndIf
Return
// ----------------------------------------------------------------------------------
// Imprime os filtros utilizados
Static Function _ImpFiltros()
	
	oReport:PrintText("",,50)
	oReport:FatLine() 
	oReport:PrintText("",,50)
	//
	// Filtros
	sTexto := "Período de " + DTOC(dDtIni)+ " até " + DTOC(dDtFim) 
	oReport:PrintText(sTexto,,50)
	sTexto := "Evento de " + alltrim(mv_par03) + " até " + alltrim(mv_par04)
	oReport:PrintText(sTexto,,50)
	sTexto := "Nível da estrutura " + alltrim(mv_par08)
	oReport:PrintText(sTexto,,50)
Return
// ----------------------------------------------------------------------------------
// Busca descrição do componente
Static Function _BuscaDescProduto(sComp)
	//Local sDesPro := ""
	Local cQuery5 := ""
	
	cQuery5 += " SELECT "
	cQuery5 += " 	B1_DESC AS DESC_PRO"
	cQuery5 += " 	,B1_TIPO AS TIPO"
	cQuery5 += " FROM " + RetSqlName("SB1")
	cQuery5 += " WHERE B1_COD = '" + sComp + "'"
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery5), "TRF", .F., .T.)
	TRF->(DbGotop())
	
	While TRF->(!Eof())	
		sDesc := TRF -> DESC_PRO
		sTipo := TRF -> TIPO
		DBSelectArea("TRF")
		dbskip()
	Enddo
	TRF->(DbCloseArea())
Return 
//
//---------------------- PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT           TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Mês         		", "C", 2, 0,  "",  "   ", {},""})
    aadd (_aRegsPerg, {02, "Ano        		    ", "C", 4, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {03, "Evento de       	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {04, "Evento até      	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {05, "Ano de           	", "C", 4, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {06, "Ano até           	", "C", 4, 0,  "",  "   ", {}                         				,""})   
    aadd (_aRegsPerg, {07, "Tipo            	", "N", 1, 0,  "",  "   ", {"Sintético","Analítico"}				,""})
    aadd (_aRegsPerg, {08, "Nivel estrutura de  ", "C", 1, 0,  "",  "   ", {}										,""})
    aadd (_aRegsPerg, {09, "Nivel estrutura ate ", "C", 1, 0,  "",  "   ", {}										,""})
   // aadd (_aRegsPerg, {10, "Imprime mensal  	", "N", 1, 0,  "",  "   ", {"Não","Sim"}							,""})
     U_ValPerg (cPerg, _aRegsPerg)
Return
