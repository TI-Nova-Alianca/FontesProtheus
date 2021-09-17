// Programa...: VA_PLMMAT
// Autor......: Cláudia Lionço
// Data.......: 02/12/2019 
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
// 09/12/2019 - Cláudia - Ajuste da consulta para considerar componentes filhos. 
//						  A revisão listada será a contida no cadastro do produto
// 15/09/2021 - Claudia - Ajuste do b1_desc para descricao. GLPI: 10943
//
// ------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_PLMMAT()
	Private oReport
	Private cPerg   := "VA_PLMMAT"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ------------------------------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oSection3:= Nil
	Local oSection4:= Nil
	
	oReport := TReport():New("VA_PLMMAT","Relação de materiais - sintético",cPerg,{|oReport| PrintReport(oReport)},"Relação de materiais - sintético")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	oReport:HideHeader() 
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Componente"	,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"		,   ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Qtd.Total"		,	,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLJAN", 	"" ,"Jan"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLFEV", 	"" ,"Fev"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLMAR", 	"" ,"Mar"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLABR", 	"" ,"Abr"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLMAI", 	"" ,"Mai"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLJUN", 	"" ,"Jun"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLJUL", 	"" ,"Jul"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLAGO", 	"" ,"Ago"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLSET", 	"" ,"Set"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLOUT", 	"" ,"Out"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLNOV", 	"" ,"Nov"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLDEZ", 	"" ,"Dez"			,	,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Alx.02"		,	,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Alx.07"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Alx.08"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Alx.90"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"SC"			,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Pedido"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Terceiros"		,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"Final"			,	,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	If mv_par07 == 2 // detalhado
		// solicitação de compras
		oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
		TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA2", 	"" ,"Num.Solicit."	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA3", 	"" ,"Produto"		,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA4", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA5", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA6", 	"" ,"Solicitante"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection2,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
		
		// pedido de compras
		oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
		TRCell():New(oSection3,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA2", 	"" ,"Num.Pedido"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA3", 	"" ,"Produto"		,	,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA4", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA5", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA6", 	"" ,"Solicitante"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection3,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
		
		// em terceiros
		oSection4 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
		TRCell():New(oSection4,"COLUNA1", 	"" ,"Filial"		,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA2", 	"" ,"NF"			,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA3", 	"" ,"Série"			,	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA4", 	"" ,"Produto"		,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA5", 	"" ,"Descrição"		,	,50,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA6", 	"" ,"Dt.Emissão"	,	,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection4,"COLUNA7", 	"" ,"Saldo"			,	,20,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	EndIf
Return(oReport)
// ------------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local oSection3 := oReport:Section(3)
	Local oSection4 := oReport:Section(4)
	Local cQuery    := ""
	Local nAlx02 	:= 0
	Local nAlx07 	:= 0
	Local nAlx08 	:= 0
	Local nAlx90 	:= 0
	Local x			:= 0
	Local y			:= 0
	Local z		    := 0
	Local i			:= 0
	Local nJan		:= 0
	Local nFev		:= 0
	Local nMar		:= 0
	Local nAbr		:= 0
	Local nMai		:= 0
	Local nJun		:= 0
	Local nJul		:= 0
	Local nAgo		:= 0
	Local nSet		:= 0
	Local nOut		:= 0
	Local nNov		:= 0
	Local nDez		:= 0
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

   	cQuery += " WITH ESTRUT (CODIGO, COD_PAI, COD_COMP, QTD, DT_INI, DT_FIM, NIVEL, REVINI, REVFIM, GRPOPC)"
	cQuery += " AS"
	cQuery += " (SELECT"
	cQuery += " 		G1_COD PAI"
	cQuery += " 	   ,G1_COD"
	cQuery += " 	   ,G1_COMP"
	cQuery += " 	   ,G1_QUANT"
	cQuery += " 	   ,G1_INI"
	cQuery += " 	   ,G1_FIM"
	cQuery += " 	   ,1 AS NIVEL"
	cQuery += " 	   ,G1_REVINI"
	cQuery += " 	   ,G1_REVFIM"
	cQuery += " 	   ,G1_GROPC"
	cQuery += " 	FROM " + RetSqlName("SG1") + " SG1 "
	cQuery += " 	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery += " 	AND G1_FILIAL = '" + xfilial ("SG1") + "'" 
	cQuery += " 	AND SG1.G1_INI <= '" + dtos(mv_par01) + "'"
	cQuery += " 	AND SG1.G1_FIM >= '" + dtos(mv_par02) + "'"
	cQuery += " 	UNION ALL SELECT"
	cQuery += " 		CODIGO"
	cQuery += " 	   ,G1_COD"
	cQuery += " 	   ,G1_COMP"
	cQuery += " 	   ,QTD * G1_QUANT"
	cQuery += " 	   ,G1_INI"
	cQuery += " 	   ,G1_FIM"
	cQuery += " 	   ,NIVEL + 1"
	cQuery += " 	   ,G1_REVINI"
	cQuery += " 	   ,G1_REVFIM"
	cQuery += " 	   ,G1_GROPC"
	cQuery += " 	FROM " + RetSqlName("SG1") + " SG1 "
	cQuery += " 	INNER JOIN ESTRUT EST"
	cQuery += " 		ON G1_COD = COD_COMP"
	cQuery += " 	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery += " 	AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"  
	cQuery += " 	AND SG1.G1_INI <= '" + dtos(mv_par01) + "'"
	cQuery += " 	AND SG1.G1_FIM >= '" + dtos(mv_par02) + "')"
	cQuery += " SELECT"
	cQuery += " 	E1.COD_COMP AS COMPONENTE"
	cQuery += "    ,SUM(SHC.HC_QUANT) AS QTD_PLANEJ"
	cQuery += "    ,SUM(E1.QTD) AS QTD_EST"
	cQuery += "    ,SUM(E1.QTD * SHC.HC_QUANT) AS QNT_PROD"
	cQuery += " FROM ESTRUT E1"
	cQuery += " 	," + RetSqlName("SB1") + " SB1 "
	cQuery += " 	," + RetSqlName("SHC") + " SHC "
	cQuery += " WHERE SB1.D_E_L_E_T_ = ''"
	cQuery += " AND SHC.D_E_L_E_T_ = ''"
	cQuery += " AND SB1.B1_COD = COD_PAI"
	cQuery += " AND E1.REVINI <= SB1.B1_REVATU"
	cQuery += " AND E1.REVFIM >= SB1.B1_REVATU"
	cQuery += " AND SHC.HC_PRODUTO = CODIGO"
	cQuery += " AND SHC.HC_DATA BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
	cQuery += " AND SHC.HC_VAEVENT BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	cQuery += " AND SHC.HC_ANO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	cQuery += " AND E1.NIVEL BETWEEN '" + npar08 +"' AND '" + npar09 + "'"
	cQuery += " AND E1.GRPOPC = ''"
	cQuery += " GROUP BY E1.COD_COMP"
	cQuery += " UNION ALL"
	cQuery += " SELECT"
	cQuery += " 	ZBD.ZBD_CODOPC AS COMPONENTE"
	cQuery += "    ,SUM(SHC.HC_QUANT) AS QTD_PLANEJ"
	cQuery += "    ,SUM(SG1.G1_QUANT) AS QTD_EST"
	cQuery += "    ,SUM(SG1.G1_QUANT * SHC.HC_QUANT) AS QNT_PROD"
	cQuery += " FROM ZBD010 ZBD"
	cQuery += " LEFT JOIN SHC010 SHC"
	cQuery += " ON (SHC.D_E_L_E_T_ = ''"
	cQuery += " 	AND SHC.HC_PRODUTO = ZBD.ZBD_PROD"
	cQuery += " 	AND SHC.HC_DATA = ZBD.ZBD_DATA"
	cQuery += " 	AND SHC.HC_VAEVENT = ZBD.ZBD_VAEVE "
	cQuery += " 	AND SHC.HC_ANO = ZBD.ZBD_ANO)"
	cQuery += " LEFT JOIN " + RetSqlName("SB1") + " SB1 "
	cQuery += " 	ON (SB1.D_E_L_E_T_ = ''"
	cQuery += " 			AND SB1.B1_COD = ZBD.ZBD_PROD"
	cQuery += " 		)"
	cQuery += " LEFT JOIN " + RetSqlName("SG1") + " SG1 "
	cQuery += " 	ON (SG1.D_E_L_E_T_ = ''"
	cQuery += " 			AND SG1.G1_COD = ZBD.ZBD_PROD"
	cQuery += " 			AND SG1.G1_COMP = ZBD.ZBD_CODOPC"
	cQuery += " 			AND SG1.G1_REVINI <= SB1.B1_REVATU"
	cQuery += " 			AND SG1.G1_REVFIM >= SB1.B1_REVATU)"
	cQuery += " WHERE ZBD.D_E_L_E_T_ = ''"
	cQuery += " AND ZBD.ZBD_DATA BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
	cQuery += " AND ZBD.ZBD_VAEVE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	cQuery += " AND ZBD.ZBD_ANO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	cQuery += " GROUP BY ZBD.ZBD_CODOPC"
	cQuery += " ORDER BY COMPONENTE"
   
	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
	TRA->(DbGotop())

	nHandle := FCreate("c:\temp\va_plmmat.txt")
	FWrite(nHandle,cQuery )
	FClose(nHandle)

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)	

	While TRA->(!Eof())
		nQtdPro:= TRA->QNT_PROD 
		_BuscaDescProduto (TRA -> COMPONENTE, @sDesc, @sTipo)

		If alltrim(sTipo) == 'MO'
			nAlx02 := 0
			nAlx07 := 0
			nAlx08 := 0
			nAlx90 := 0
			nSC    := 0
			nPC    := 0
			nTerc  := 0
			nFinal := 0
		Else
			nAlx02 := _BuscaSaldo(TRA -> COMPONENTE ,'02')
			nAlx07 := _BuscaSaldo(TRA -> COMPONENTE ,'07')
			nAlx08 := _BuscaSaldo(TRA -> COMPONENTE ,'08')
			nAlx90 := _BuscaSaldo(TRA -> COMPONENTE ,'90')
			nSC    := _BuscaSC(TRA -> COMPONENTE)
			nPC    := _BuscaPC(TRA -> COMPONENTE)
			nTerc  := _BuscaTerc(TRA -> COMPONENTE)
			nFinal := (nAlx02 + nAlx07 + nAlx08 + nSC + nPC) - nQtdPro
		EndIf
		
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->COMPONENTE })
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| sDesc 	 		 })
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| nQtdPro		 })
		
		If mv_Par10 == 2
			// Define quantidade por mes
			
			nDifMes := DateDiffMonth( mv_par01 , mv_par02) 
			nQtdMes := nDifMes + 1
			dDt     := mv_par01
			
			If nQtdMes > 12
				u_help("A quantidade de meses para pesquisa não poderá ser mais que 12 meses. A quantidade por mês não será efetuada!")
			Else
			
			_sQuery := "dif datas:" + str(nDifMes) + " QtdMes:"+ str(nQtdMes) + chr (13) + chr (10)
			FWrite(nHandle,_sQuery )
				
			For i:= 1 to nQtdMes	
				
				If i == 1
					sAno := alltrim(str(Year(mv_par01)))
					sMes := PADL(alltrim(str(Month(mv_par01))),2,'0')
					
				Else
					dNewDt := MonthSum(dDt,1)
					sAno := alltrim(str(Year(dNewDt)))
					sMes := PADL(alltrim(str(Month(dNewDt))),2,'0')
					dDt  := dNewDt
				EndIf
				
				_sQuery := "* Ano:" + sAno + " Mes:" + sMes + chr (13) + chr (10)
				FWrite(nHandle,_sQuery )
				
				sDatIni := sAno+sMes+'01'
				sDatFin := DTOS(LastDate(stod(sDatIni)))
	
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
	
				Do Case
					Case sMes == '01'
						nJan := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '02'
						nFev := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '03'
						nMar := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '04'
						nAbr := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '05'
						nMai := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '06'
						nJun := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '07'
						nJul := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '08'
						nAgo := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '09'
						nSet := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '10'
						nOut := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '11'
						nNov := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
					Case sMes == '12'
						nDez := _BuscaQtdMes(TRA -> COMPONENTE, sMes, sAno, nPar08, nPar09)
				EndCase
				
				
			Next
			oSection1:Cell("COLJAN")	:SetBlock   ({|| nJan		 	 })
			oSection1:Cell("COLFEV")	:SetBlock   ({|| nFev		 	 })
			oSection1:Cell("COLMAR")	:SetBlock   ({|| nMar		 	 })
			oSection1:Cell("COLABR")	:SetBlock   ({|| nAbr			 })
			oSection1:Cell("COLMAI")	:SetBlock   ({|| nMai		 	 })
			oSection1:Cell("COLJUN")	:SetBlock   ({|| nJun		 	 })
			oSection1:Cell("COLJUL")	:SetBlock   ({|| nJul		 	 })
			oSection1:Cell("COLAGO")	:SetBlock   ({|| nAgo		 	 })
			oSection1:Cell("COLSET")	:SetBlock   ({|| nSet		 	 })
			oSection1:Cell("COLOUT")	:SetBlock   ({|| nOut		 	 })
			oSection1:Cell("COLNOV")	:SetBlock   ({|| nNov		 	 })
			oSection1:Cell("COLDEZ")	:SetBlock   ({|| nDez		 	 })
			EndIf
		EndIf
		
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| nAlx02			 })
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| nAlx07 		 })
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| nAlx08 		 })
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| nAlx90 		 })
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| nSC 		 	 })
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| nPC 		 	 })
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| nTerc 		 	 })
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| nFinal 		 })
	
		oSection1:PrintLine()

		DBSelectArea("TRA")
		dbskip()
	Enddo
	oSection1:Finish()
	TRA->(DbCloseArea())
	
	If mv_par07 == 2
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
		
		oSection4:Finish()

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
	FClose(nHandle)
	_ImpFiltros()
Return
// ----------------------------------------------------------------------------------
// Imprime os filtros utilizados
Static Function _ImpFiltros()
	
	oReport:PrintText("",,50)
	oReport:FatLine() 
	oReport:PrintText("",,50)
	
	// Filtros
	sTexto := "Período de " + DTOC(mv_par01)+ " até " + DTOC(mv_par02) 
	oReport:PrintText(sTexto,,50)
	sTexto := "Evento de " + alltrim(mv_par03) + " até " + alltrim(mv_par04)
	oReport:PrintText(sTexto,,50)
	sTexto := "Nível da estrutura " + alltrim(mv_par08)
	oReport:PrintText(sTexto,,50)
Return
//
// ----------------------------------------------------------------------------------
// Busca o saldo nos almoxarifados correspondentes
Static Function _BuscaSaldo(sComp, sAlx)
	Local nQtdAlx := 0
	Local cQuery1 := ""
	
	cQuery1 += " SELECT"
	cQuery1 += " 		B2_COD"
	cQuery1 += " 	   ,B2_LOCAL "
	cQuery1 += " 	   ,SUM(B2_QATU) AS QTD"
	cQuery1 += " 	FROM " + RetSqlName("SB2")
	cQuery1 += " 	WHERE D_E_L_E_T_ = ''"
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
Static Function _BuscaSC(sComp)
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
Static Function _BuscaPC(sComp)
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
Static Function _BuscaTerc(sComp)
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
// ----------------------------------------------------------------------------------
// Busca descrição do componente
Static Function _BuscaDescProduto(sComp,sDesc,sTipo)
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
// ----------------------------------------------------------------------------------
// Busca Quantidade por mes do componente
Static Function _BuscaQtdMes(sComp, sMes, sAno, nPar08, nPar09)
	Local nQtdMes := 0
	Local cQuery6 := ""
	
	cQuery6 += " WITH ESTRUT (CODIGO, COD_PAI, COD_COMP, QTD, DT_INI, DT_FIM, NIVEL, REVINI, REVFIM, GRPOPC)"
	cQuery6 += " AS"
	cQuery6 += " (SELECT"
	cQuery6 += " 		G1_COD PAI"
	cQuery6 += " 	   ,G1_COD"
	cQuery6 += " 	   ,G1_COMP"
	cQuery6 += " 	   ,G1_QUANT"
	cQuery6 += " 	   ,G1_INI"
	cQuery6 += " 	   ,G1_FIM"
	cQuery6 += " 	   ,1 AS NIVEL"
	cQuery6 += " 	   ,G1_REVINI"
	cQuery6 += " 	   ,G1_REVFIM"
	cQuery6 += " 	   ,G1_GROPC"
	cQuery6 += " 	FROM " + RetSqlName("SG1") + " SG1 "
	cQuery6 += " 	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery6 += " 	AND G1_FILIAL = '" + xfilial ("SG1") + "'" 
	cQuery6 += " 	AND SG1.G1_INI <= '" + dtos(mv_par01) + "'"
	cQuery6 += " 	AND SG1.G1_FIM >= '" + dtos(mv_par02) + "'"
	cQuery6 += " 	UNION ALL SELECT"
	cQuery6 += " 		CODIGO"
	cQuery6 += " 	   ,G1_COD"
	cQuery6 += " 	   ,G1_COMP"
	cQuery6 += " 	   ,QTD * G1_QUANT"
	cQuery6 += " 	   ,G1_INI"
	cQuery6 += " 	   ,G1_FIM"
	cQuery6 += " 	   ,NIVEL + 1"
	cQuery6 += " 	   ,G1_REVINI"
	cQuery6 += " 	   ,G1_REVFIM"
	cQuery6 += " 	   ,G1_GROPC"
	cQuery6 += " 	FROM " + RetSqlName("SG1") + " SG1 "
	cQuery6 += " 	INNER JOIN ESTRUT EST"
	cQuery6 += " 		ON G1_COD = COD_COMP"
	cQuery6 += " 	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery6 += " 	AND SG1.G1_FILIAL = '" + xfilial ("SG1") + "'"  
	cQuery6 += " 	AND SG1.G1_INI <= '" + dtos(mv_par01) + "'"
	cQuery6 += " 	AND SG1.G1_FIM >= '" + dtos(mv_par02) + "')"
	cQuery6 += " SELECT"
	cQuery6 += " 	E1.COD_COMP AS COMPONENTE"
	cQuery6 += "    ,SUM(SHC.HC_QUANT) AS QTD_PLANEJ"
	cQuery6 += "    ,SUM(E1.QTD) AS QTD_EST"
	cQuery6 += "    ,SUM(E1.QTD * SHC.HC_QUANT) AS QNT_PROD"
	cQuery6 += " FROM ESTRUT E1"
	cQuery6 += " 	," + RetSqlName("SB1") + " SB1 "
	cQuery6 += " 	," + RetSqlName("SHC") + " SHC "
	cQuery6 += " WHERE SB1.D_E_L_E_T_ = ''"
	cQuery6 += " AND SHC.D_E_L_E_T_ = ''"
	cQuery6 += " AND SB1.B1_COD = COD_PAI"
	cQuery6 += " AND E1.REVINI <= SB1.B1_REVATU"
	cQuery6 += " AND E1.REVFIM >= SB1.B1_REVATU"
	cQuery6 += " AND SHC.HC_PRODUTO = CODIGO"
	cQuery6 += " AND SHC.HC_DATA BETWEEN '" + sDatIni + "' AND '" + sDatFin + "'"
	cQuery6 += " AND SHC.HC_VAEVENT BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	cQuery6 += " AND SHC.HC_ANO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	cQuery6 += " AND E1.NIVEL BETWEEN '" + npar08 +"' AND '" + npar09 + "'"
	cQuery6 += " AND E1.GRPOPC = ''"
	cQuery6 += " AND E1.COD_COMP = '" + sComp + "'"
	cQuery6 += " GROUP BY E1.COD_COMP"
	cQuery6 += " UNION ALL"
	cQuery6 += " SELECT"
	cQuery6 += " 	ZBD.ZBD_CODOPC AS COMPONENTE"
	cQuery6 += "    ,SUM(SHC.HC_QUANT) AS QTD_PLANEJ"
	cQuery6 += "    ,SUM(SG1.G1_QUANT) AS QTD_EST"
	cQuery6 += "    ,SUM(SG1.G1_QUANT * SHC.HC_QUANT) AS QNT_PROD"
	cQuery6 += " FROM ZBD010 ZBD"
	cQuery6 += " LEFT JOIN SHC010 SHC"
	cQuery6 += " ON (SHC.D_E_L_E_T_ = ''"
	cQuery6 += " 	AND SHC.HC_PRODUTO = ZBD.ZBD_PROD"
	cQuery6 += " 	AND SHC.HC_DATA = ZBD.ZBD_DATA"
	cQuery6 += " 	AND SHC.HC_VAEVENT = ZBD.ZBD_VAEVE "
	cQuery6 += " 	AND SHC.HC_ANO = ZBD.ZBD_ANO)"
	cQuery6 += " LEFT JOIN " + RetSqlName("SB1") + " SB1 "
	cQuery6 += " 	ON (SB1.D_E_L_E_T_ = ''"
	cQuery6 += " 			AND SB1.B1_COD = ZBD.ZBD_PROD"
	cQuery6 += " 		)"
	cQuery6 += " LEFT JOIN " + RetSqlName("SG1") + " SG1 "
	cQuery6 += " 	ON (SG1.D_E_L_E_T_ = ''"
	cQuery6 += " 			AND SG1.G1_COD = ZBD.ZBD_PROD"
	cQuery6 += " 			AND SG1.G1_COMP = ZBD.ZBD_CODOPC"
	cQuery6 += " 			AND SG1.G1_REVINI <= SB1.B1_REVATU"
	cQuery6 += " 			AND SG1.G1_REVFIM >= SB1.B1_REVATU)"
	cQuery6 += " WHERE ZBD.D_E_L_E_T_ = ''"
	cQuery6 += " AND ZBD.ZBD_DATA BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "'"
	cQuery6 += " AND ZBD.ZBD_VAEVE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	cQuery6 += " AND ZBD.ZBD_ANO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	cQuery6 += " AND ZBD.ZBD_CODOPC = '" + sComp + "'"
	cQuery6 += " GROUP BY ZBD.ZBD_CODOPC"
	cQuery6 += " ORDER BY COMPONENTE"
    nHandle := FCreate("c:\temp\plmmat_QTDPROD.txt")
	FWrite(nHandle,cQuery6 )
	FClose(nHandle)

	DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery6), "TRG", .F., .T.)
	TRG->(DbGotop())
	
	While TRG->(!Eof())	
		nQtdMes := TRG -> QNT_PROD
		
		DBSelectArea("TRG")
		dbskip()
	Enddo
	TRG->(DbCloseArea())

Return nQtdMes
//
// ----------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT           TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Data de      		", "D", 8, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {02, "Data até    		", "D", 8, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {03, "Evento de       	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {04, "Evento até      	", "C", 3, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {05, "Ano de           	", "C", 4, 0,  "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {06, "Ano até           	", "C", 4, 0,  "",  "   ", {}                         				,""})   
    aadd (_aRegsPerg, {07, "Tipo            	", "N", 1, 0,  "",  "   ", {"Sintético","Analítico"}				,""})
    aadd (_aRegsPerg, {08, "Nivel estrutura de  ", "C", 1, 0,  "",  "   ", {}										,""})
    aadd (_aRegsPerg, {09, "Nivel estrutura ate ", "C", 1, 0,  "",  "   ", {}										,""})
    aadd (_aRegsPerg, {10, "Imprime mensal  	", "N", 1, 0,  "",  "   ", {"Não","Sim"}							,""})
    
	U_ValPerg (cPerg, _aRegsPerg)
Return
