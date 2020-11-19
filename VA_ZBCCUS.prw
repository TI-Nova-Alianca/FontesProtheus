// Programa...: VA_ZBCCUS
// Autor......: Cláudia Lionço
// Data.......: 30/12/2019 
// Descricao..: Relatório de custo de materias do planejamento.
// ------------------------------------------------------------------------------------------------
//
#include 'protheus.ch'
#include 'parmtype.ch'

user function VA_ZBCCUS()
	Private oReport
	Private cPerg   := "VA_ZBCCUS"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
return
//
Static Function ReportDef()
	Local oReport  := Nil

	oReport := TReport():New("VA_ZBCCUS","Custo dos materiais do planejamento (Custo Standard)",cPerg,{|oReport| PrintReport(oReport)},"Custo dos materiais do planejamento (Custo Standard)")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := Nil
	//Local oSection2 := Nil
	//Local oSection3 := Nil
	//Local oSection4 := Nil
	Local cQuery    := ""	
	//Local nAlx02 	:= 0
	//Local nAlx07 	:= 0
	//Local nAlx08 	:= 0
	//Local nAlx90 	:= 0
	//Local x			:= 0
	//Local y			:= 0
	//Local z		    := 0
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
		If mv_par10 == 1 // total
			TRCell():New(oSection1,"COLUNA3", 	"" ,"Custo Total"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
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
		
		If mv_par10 == 1 // total

			cQuery := " WITH C (COMPONENTE, QTD_PLANEJ, QTD_ESTRUT, QNT_PROD)"
			cQuery += " AS"
			cQuery += " (SELECT"
			cQuery += "		 COMPONENTE"
			cQuery += "	    ,SUM(QTD_PLANEJ)"
			cQuery += "	    ,SUM(QTD_ESTRUT)"
			cQuery += "	    ,SUM(QNT_PROD)"
			cQuery += " 	FROM dbo.VA_PLANCOMP('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) + "', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+ mv_par05 +"', '"+mv_par06+"', '"+nPar08+"', '"+nPar09+"')"
			cQuery += "	 GROUP BY COMPONENTE"
			cQuery += "	 UNION ALL"
			cQuery += "	 SELECT"
			cQuery += "	 	COMPONENTE"
			cQuery += "	    ,SUM(QTD_PLANEJ)"
			cQuery += "	    ,SUM(QTD_ESTRUT)"
			cQuery += "	    ,SUM(QNT_PROD)"
			cQuery += " 	FROM dbo.VA_PLANOPC('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) +"', '"+mv_par03+"', '"+mv_par04+"', '"+mv_par05+"', '"+mv_par06+"')"
			cQuery += "	 GROUP BY COMPONENTE)"
			cQuery += " SELECT"
			cQuery += " 	COMPONENTE"
			cQuery += "    ,SUM(QTD_PLANEJ) AS QTD_PLANEJ"
			cQuery += "    ,SUM(QTD_ESTRUT) AS QTD_ESTRUT"
			cQuery += "    ,SUM(QNT_PROD) AS QNT_PROD"
			cQuery += "    ,SUM(QNT_PROD * SB1.B1_CUSTD) AS CUSTO"
			cQuery += " FROM C"
			cQuery += " 	,SB1010 SB1"
			cQuery += " WHERE SB1.D_E_L_E_T_ = ''"
			cQuery += " AND SB1.B1_COD = COMPONENTE"
			cQuery += " GROUP BY COMPONENTE"

		Else // mensal
			cQuery := " SELECT"
			cQuery += " 	COMPONENTE"
			cQuery += "    ,MES01 = SUM(CASE WHEN MES = 1 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES02 = SUM(CASE WHEN MES = 2 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES03 = SUM(CASE WHEN MES = 3 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES04 = SUM(CASE WHEN MES = 4 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES05 = SUM(CASE WHEN MES = 5 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES06 = SUM(CASE WHEN MES = 6 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES07 = SUM(CASE WHEN MES = 7 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES08 = SUM(CASE WHEN MES = 8 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES09 = SUM(CASE WHEN MES = 9 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES10 = SUM(CASE WHEN MES = 10 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES11 = SUM(CASE WHEN MES = 11 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += "    ,MES12 = SUM(CASE WHEN MES = 12 THEN QNT_PROD * SB1.B1_CUSTD ELSE 0 END)"
			cQuery += " FROM dbo.VA_ZBCMAT('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) + "', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+ mv_par05 +"', '"+mv_par06+"', '"+nPar08+"', '"+nPar09+"')"
			cQuery += " 	,SB1010 SB1"
			cQuery += " WHERE COMPONENTE = SB1.B1_COD"
			cQuery += " GROUP BY COMPONENTE"
			cQuery += " ORDER BY COMPONENTE"
		EndIf
		
		DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		TRA->(DbGotop())
	
		oSection1:Init()
		oSection1:SetHeaderSection(.T.)	
	
		While TRA->(!Eof())
			_BuscaDescProduto (TRA -> COMPONENTE, @sDesc, @sTipo)
			
			oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->COMPONENTE })
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| sDesc 	 		 })
			If mv_par10 == 1 // total
				oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->CUSTO	 })
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
		
			oSection1:PrintLine()
	
			DBSelectArea("TRA")
			dbskip()
		Enddo
		oSection1:Finish()
		TRA->(DbCloseArea())
		
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
	sTexto := "Período de " + DTOC(mv_par01)+ " até " + DTOC(mv_par02) 
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
    aadd (_aRegsPerg, {01, "Data de      		", "D", 8, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {02, "Data até    		", "D", 8, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {03, "Evento de       	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {04, "Evento até      	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {05, "Ano de           	", "C", 4, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {06, "Ano até           	", "C", 4, 0,  "",  "   ", {}                         				,""})   
    aadd (_aRegsPerg, {07, "Tipo            	", "N", 1, 0,  "",  "   ", {"Sintético"}							,""})
    aadd (_aRegsPerg, {08, "Nivel estrutura de  ", "C", 1, 0,  "",  "   ", {}										,""})
    aadd (_aRegsPerg, {09, "Nivel estrutura ate ", "C", 1, 0,  "",  "   ", {}										,""})
    aadd (_aRegsPerg, {10, "Imprime mensal  	", "N", 1, 0,  "",  "   ", {"Não","Sim"}							,""})
     U_ValPerg (cPerg, _aRegsPerg)
Return
