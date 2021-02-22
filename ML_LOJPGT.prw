// Programa...: ML_LOJPGT
// Autor......: Cláudia Lionço
// Data.......: 30/08/2019
// Descricao..: Relatorio de vendas de lojas com listagem de tipo de de pagamentos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de vendas de lojas com listagem de tipo de de pagamentos
// #PalavasChave      #vendas_loja #movimentos_diarios
// #TabelasPrincipais #SL1 #SL4 #SF2 #SE1 #SC5 
// #Modulos   		  #LOJA
//
// Historico de alteracoes:
// 23/09/2019 - Claudia - Incluidas alterações conforme GLPI 6312
// 25/09/2019 - Claudia - Incluida opção sintética do relatório
// 10/12/2019 - Claudia - Incluido filtro de itens deletados e cancelados na tabela SE5
// 22/02/2021 - Cláudia - GLPI: 9444 - Incluido todos tipos de NF's
//
// -----------------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch
#include "report.ch"
#include "rwmake.ch"
#INCLUDE 'TOPCONN.CH'

User Function ML_LOJPGT
	cPerg   := "ML_LOJPGT"
	_ValidPerg()
	
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
	
Return
//
// -----------------------------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oSection3:= Nil
	Local oSection4:= Nil
	Local oSection5:= Nil
	Local oSection6:= Nil
	Local oSection7:= Nil
	Local oSection8:= Nil

	oReport := TReport():New("ML_LOJPGT","Movimentos diários",cPerg,{|oReport| PrintReport(oReport)},"Movimentos diários")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()

	//SESSÃO 1 CUPONS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)	
	TRCell():New(oSection1,"COLUNA1", 	" ","Cupom"				,	    			, 8,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA2", 	" ","Série"				,       			, 6,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA3", 	" ","Emissão"			,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA4", 	" ","Valor Total"		,"@E 99,999,999.99" ,30,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.T.)
	oSection1:SetPageBreak(.T.)
	oSection1:SetTotalText(" ")	

	//SESSÃO2 - PAGAMENTOS
	oSection2 := TRSection():New(oReport," ",{""}, , , , , ,.T.,.F.,.F.) 
	
	oSection2:SetTotalInLine(.F.)
	TRCell():New(oSection2,"COLUNA ", 	" "," "							,					,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA1", 	" ","Forma de Pagamento"		,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	" ","Administradora(cartão)"	,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	" ","Valor"						,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	" ","NSU"						,					,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	" ","Nº Vale"					,					,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	

	//SESSÃO3 - TOTAIS
	oSection3 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
	oSection3:SetTotalInLine(.F.)
	TRCell():New(oSection3,"COLUNA ", 	" "," "							,					,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA1", 	" ","Forma de Pagamento"     	,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA2", 	" ","Valor total"		        ,"@E 99,999,999.99"	,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	
	//SESSÃO4 - RESUMO
	oSection4 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
	oSection4:SetTotalInLine(.F.)
	TRCell():New(oSection4,"COLUNA ", 	" "," "							,					,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA1", 	" ","Forma de Pagamento"     	,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA2", 	" ","Valor total"		        ,"@E 99,999,999.99" ,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	
	If mv_par10 == 1
		//SESSÃO4 - DEPÓSITOS
		oSection5 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
		oSection5:SetTotalInLine(.F.)
		TRCell():New(oSection5,"COLUNA1", 	" ","Data"			,					,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection5,"COLUNA2", 	" ","Natureza"     	,					,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection5,"COLUNA3", 	" ","Descrição"		,					,40,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
		TRCell():New(oSection5,"COLUNA4", 	" ","Valor"		    ,"@E 99,999,999.99" ,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
		//TRFunction():New(oSection5:Cell("COLUNA4"),,"SUM"	,,"Total dos depósitos" , "@E 99,999,999.99", NIL, .F., .T.)
	EndIf		

	//SESSÃO 6 NOTAS
	oSection6 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	oSection6:SetTotalInLine(.F.)	
	TRCell():New(oSection6,"COLUNA1", 	" ","Título"			,	    			, 8,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA2", 	" ","Série"				,       			, 6,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA3", 	" ","Emissão"			,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA4", 	" ","Valor Total"		,"@E 99,999,999.99" ,30,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection6,"COLUNA5", 	" ","NSU"				,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA6", 	" ","Autorização"		,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection6,"COLUNA7", 	" ","Tipo"				,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	//oSection6:SetPageBreak(.T.)
	//oSection6:SetTotalText(" ")	

	//SESSÃO 7 - TOTAIS NOTAS
	oSection7 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
	oSection7:SetTotalInLine(.F.)
	TRCell():New(oSection7,"COLUNA1", 	" "," "							,					,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection7,"COLUNA2", 	" ","Forma de Pagamento"     	,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection7,"COLUNA3", 	" ","Valor total"		        ,"@E 99,999,999.99"	,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)	

	//SESSÃO 8 - TOTAIS GERAIS
	oSection8 := TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 
	oSection8:SetTotalInLine(.F.)
	TRCell():New(oSection8,"COLUNA1", 	" ","Forma de Pagamento"     	,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection8,"COLUNA2", 	" ","Valor total"		        ,"@E 99,999,999.99"	,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
Return(oReport)
//
// -----------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)	 
	Local oSection3 := oReport:Section(3)	
	Local oSection4 := oReport:Section(4)
	Local oSection5 := oReport:Section(5)
	Local oSection6 := oReport:Section(6)
	Local oSection7 := oReport:Section(7)
	Local oSection8 := oReport:Section(8)
	Local cQuery    := ""		
	Local cQuery2   := ""
	Local cQuery3   := ""
	Local cQuery4   := ""
	Local aForPgt   :={}
	Local sForPgt   := ""
	Local sNatExc   := ""
	Local aNatExc   := {}
	Local nTResumo  := 0
	Local nTFPgto   := 0
	Local nTDeposito:= 0
	Local aNFs      := {}
	Local aTNFs     := {}
	Local x			:= 0
	Local i         := 0
	
	If mv_par13 == 1
		If !empty(mv_par09)
			aForPgt := StrToKarr( mv_par09 , ';')
			
			For x := 1 to len(aForPgt)
				sForPgt += "'"+ upper(alltrim(aForPgt[x])) + "'"
				If x != len(aForPgt)
					sForPgt += ","
				EndIf
			Next
		EndIf
		
		cQuery += " SELECT" 
		cQuery += "	   SL1.L1_DOC AS DOC" 
		cQuery += "   ,SL1.L1_SERIE AS SERIE" 
		cQuery += "   ,SL1.L1_EMISNF AS EMISSAO" 
		cQuery += "   ,SL1.L1_VLRTOT AS VLRTOT" 
		cQuery += "   ,SL4.L4_FORMA AS FORMA" 
		cQuery += "   ,SL4.L4_ADMINIS AS ADM" 
		cQuery += "   ,SL4.L4_VALOR AS VALOR" 
		cQuery += "   ,SL4.L4_NSUTEF AS NSU" 
		cQuery += "	  ,SL4.L4_NUMCART AS NUMVALE"
		cQuery += " FROM " + RetSQLName ("SL1") + "  AS SL1" 
		cQuery += " INNER JOIN " + RetSQLName ("SL4") + "  SL4" 
		cQuery += "	 ON (SL1.D_E_L_E_T_ = ''" 
		cQuery += "			AND SL4.D_E_L_E_T_ = ''" 
		cQuery += "			AND SL1.L1_FILIAL = SL4.L4_FILIAL" 
		cQuery += "			AND SL1.L1_NUM = SL4.L4_NUM"
		If !empty(mv_par09)
			cQuery += "			AND SL4.L4_FORMA IN ("+ alltrim(sForPgt) + ")"
		EndIf
		cQuery += "			)" 
		cQuery += " WHERE SL1.D_E_L_E_T_ = ''" 
		cQuery += " AND SL1.L1_FILIAL ='" + xFilial("SL1") +"'"
		cQuery += " AND SL1.L1_SERIE != '999'" 
		cQuery += " AND SL1.L1_DOC <> ''"
		cQuery += " AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		If ! empty (mv_par03)
			cQuery += " AND SL1.L1_DOC BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
		EndIf
		If ! empty (mv_par05)
			cQuery += " AND SL1.L1_SERIE BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
		EndIf
		If ! empty (mv_par07)
			cQuery += " AND SL1.L1_NUM BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
		EndIf
		Do Case
			Case mv_par12 == 1
				cQuery += " ORDER BY SL1.L1_DOC, SL1.L1_SERIE, SL1.L1_EMISNF, SL1.L1_NUM" 
			Case mv_par12 == 2
				cQuery += " ORDER BY SL4.L4_FORMA ,SL4.L4_ADMINIS, SL1.L1_DOC,  SL1.L1_SERIE, SL1.L1_EMISNF"
			Case mv_par12 == 3
				cQuery += " ORDER BY SL1.L1_SERIE, SL1.L1_DOC, SL1.L1_EMISNF, SL1.L1_NUM" 
		EndCase
				
		tcquery cQuery new alias _trb
		_trb -> (dbgotop ())
	
		// imprime cupons fiscais
		oReport:SkipLine(1) 
		oReport:PrintText(" *** CUPONS FISCAIS ***",,1000)
		oReport:SkipLine(1) 

		Do While !Eof()
			If oReport:Cancel()
				Exit
			EndIf
			oSection1:Init()			
			IncProc("Imprimindo cupom "+alltrim(_trb -> DOC))
			
			sCupom := _trb -> DOC
						
			oSection1:Cell("COLUNA1"):SetValue(_trb -> DOC)
			oSection1:Cell("COLUNA2"):SetValue(_trb -> SERIE)		
			oSection1:Cell("COLUNA3"):SetValue(STOD(_trb -> EMISSAO))	
			oSection1:Cell("COLUNA4"):SetValue(_trb -> VLRTOT)		
			oSection1:Printline()
			
			While alltrim(_trb -> DOC) == alltrim(sCupom)
				oSection2:init()
	
				cPgtDesdri := Posicione("SX5",1,xFilial("SX5") + "06" + alltrim(_trb -> FORMA),"X5_DESCRI") // Busca descrição da forma de pagamento
				
				oSection2:Cell("COLUNA1"):SetValue(alltrim(_trb -> FORMA) + "-" + alltrim(cPgtDesdri))
				oSection2:Cell("COLUNA2"):SetValue(_trb -> ADM  )
				oSection2:Cell("COLUNA3"):SetValue(_trb -> VALOR)			
				oSection2:Cell("COLUNA4"):SetValue(_trb -> NSU  )	
				oSection2:Cell("COLUNA5"):SetValue(_trb -> NUMVALE  )			
				oSection2:Printline()
				
				sCupom := alltrim(_trb -> DOC) 
				
				DbSelectArea("_trb")
				DBSkip()
			EndDo
			oReport:ThinLine()
		EndDo
		_trb -> (DBCloseArea())
	EndIf
	
	// ------------------------ TOTAIS
	cQuery2 += " SELECT"
	cQuery2 += "	L4_FORMA AS TFORMA"
	cQuery2 += "   ,SUM(L4_VALOR) AS TVALOR"
	cQuery2 += " FROM " + RetSQLName ("SL1") + " AS SL1"
	cQuery2 += " INNER JOIN " + RetSQLName ("SL4") + " AS SL4"
	cQuery2 += "	ON (SL1.D_E_L_E_T_ = ''"
	cQuery2 += "			AND SL4.D_E_L_E_T_ = ''"
	cQuery2 += "			AND SL1.L1_FILIAL = SL4.L4_FILIAL"
	cQuery2 += "			AND SL1.L1_NUM = SL4.L4_NUM"
	If !empty(mv_par09)
		cQuery2 += "		AND SL4.L4_FORMA IN ("+ alltrim(sForPgt) + ")"
	EndIf
	cQuery2 += "			)"
	cQuery2 += " WHERE SL1.D_E_L_E_T_ = ''"
	cQuery2 += " AND SL1.L1_FILIAL ='" + xFilial("SL1") +"'"
	cQuery2 += " AND SL1.L1_SERIE != '999'"
	cQuery2 += " AND SL1.L1_DOC <> ''"
	cQuery2 += " AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	If ! empty (mv_par03)
		cQuery2 += " AND SL1.L1_DOC BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	EndIf
	If ! empty (mv_par05)
		cQuery += " AND SL1.L1_SERIE BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
	EndIf
	If ! empty (mv_par07)
		cQuery2 += " AND SL1.L1_NUM BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
	EndIf
	cQuery2 += " GROUP BY L4_FORMA"
	
	tcquery cQuery2 new alias _trbTot
	_trbTot -> (dbgotop ())
	
	oReport:PrintText(" " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:PrintText("TOTAIS POR TIPO DE PAGAMENTO - CUPONS:" ,,50)
	oReport:ThinLine()
	
	Do While !Eof()
			
		Do Case
			Case alltrim(_trbTot -> TFORMA) == 'CC'
				sDescForma := 'Cartão de crédito'
			Case alltrim(_trbTot -> TFORMA) == 'CD'
				sDescForma := 'Cartão de débito'
			Case alltrim(_trbTot -> TFORMA) == 'CH'
				sDescForma := 'Cheque'
			Case alltrim(_trbTot -> TFORMA) == 'CO'		
				sDescForma := 'Convênio' 
			Case alltrim(_trbTot -> TFORMA) == 'R$'
				sDescForma := 'Dinheiro' 
			Case alltrim(_trbTot -> TFORMA) == 'VP'
				sDescForma := 'Vale' 
			Otherwise
				sDescForma :=''
		EndCase
				
		oSection3:init()
		oSection3:Cell("COLUNA1"):SetValue(alltrim(_trbTot -> TFORMA)  +' - ' + alltrim(sDescForma))
		oSection3:Cell("COLUNA2"):SetValue(_trbTot -> TVALOR)		
		oSection3:Printline()
		
		nTFPgto += _trbTot -> TVALOR
		
		DbSelectArea("_trbTot")
		DBSkip()
	EndDo
	
	oReport:PrintText(" " ,,50)
	oReport:PrintText("TOTAL POR TIPOS DE PAGAMENTO: R$" + alltrim(STR(nTFPgto)) ,,50)
	_trbTot -> (DBCloseArea())
	
	
	// ------------------------ RESUMO
	cQuery3 += " SELECT"
	cQuery3 += "	 L4_FORMA AS FORMA"
    cQuery3 += "	,L4_ADMINIS AS ADM"
    cQuery3 += "	,SUM(L4_VALOR) AS VLR"
	cQuery3 += " FROM " + RetSQLName ("SL1") + " AS SL1"
	cQuery3 += " INNER JOIN " + RetSQLName ("SL4") + " AS SL4"
	cQuery3 += "	ON (SL1.D_E_L_E_T_ = ''"
	cQuery3 += "			AND SL4.D_E_L_E_T_ = ''"
	cQuery3 += "			AND SL1.L1_FILIAL = SL4.L4_FILIAL"
	cQuery3 += "			AND SL1.L1_NUM = SL4.L4_NUM"
	If !empty(mv_par09)
		cQuery3 += "		AND SL4.L4_FORMA IN ("+ alltrim(sForPgt) + "))"
	Else
		cQuery3 += "		AND SL4.L4_FORMA IN ('CC', 'CD','CO'))"
	EndIf
	cQuery3 += " WHERE SL1.D_E_L_E_T_ = ''"
	cQuery3 += " AND SL1.L1_FILIAL ='" + xFilial("SL1") +"'"
	cQuery3 += " AND SL1.L1_SERIE != '999'"
	cQuery3 += " AND SL1.L1_DOC <> ''"
	cQuery3 += " AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	If ! empty (mv_par03)
		cQuery3 += " AND SL1.L1_DOC BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	EndIf
	If ! empty (mv_par05)
		cQuery += " AND SL1.L1_SERIE BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
	EndIf
	If ! empty (mv_par07)
		cQuery3 += " AND SL1.L1_NUM BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
	EndIf
	cQuery3 += " GROUP BY L4_FORMA, L4_ADMINIS"
	
	tcquery cQuery3 new alias _trbRes
	_trbRes -> (dbgotop ())
	
	oReport:PrintText(" " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:PrintText(" " ,,50)
	oReport:PrintText("RESUMO - CUPONS:" ,,50)
	oReport:ThinLine()
	
	Do While !Eof()
		
		oSection4:init()
		oSection4:Cell("COLUNA1"):SetValue(alltrim(_trbRes -> FORMA)  +' - ' + alltrim(_trbRes -> ADM))
		oSection4:Cell("COLUNA2"):SetValue(_trbRes -> VLR)		
		oSection4:Printline()
		nTResumo += _trbRes -> VLR
		DbSelectArea("_trbRes")
		DBSkip()
	EndDo
	
	oReport:PrintText(" " ,,50)
	oReport:PrintText("TOTAL DO RESUMO: R$" + alltrim(STR(nTResumo)) ,,50)
	
	_trbRes -> (DBCloseArea())
	
	// ------------------------ DEPÓSITOS
	If mv_par10 == 1 // imprime depósitos
		If !empty(mv_par11)
			aNatExc := StrToKarr( mv_par11 , ';')
			
			For x := 1 to len(aNatExc)
				sNatExc += "'"+ upper(alltrim(aNatExc[x])) + "'"
				If x != len(aNatExc)
					sNatExc += ","
				EndIf
			Next
		EndIf
		//
		cQuery4 += " SELECT"
		cQuery4 += " 	 E5_DATA AS DTE5"
		cQuery4 += "    ,E5_NATUREZ AS NATUREZA"
		cQuery4 += "    ,E5_HISTOR AS HISTORICO"
		cQuery4 += "    ,E5_VALOR AS VLRE5"
		cQuery4 += " FROM " + RetSQLName ("SE5") + " AS SE5"
		cQuery4 += " WHERE D_E_L_E_T_ = '' 
		cQuery4 += " AND E5_FILIAL = '" + xFilial("SE5") +"'"
		cQuery4 += " AND E5_SITUACA <> 'C'"
		cQuery4 += " AND E5_MOEDA = 'M1'"
		cQuery4 += " AND E5_BANCO = 'CL1'"
		If !empty(mv_par11)
			cQuery4 += " AND E5_NATUREZ NOT IN ("+ alltrim(sNatExc) + ")"
		EndIf
		cQuery4 += " AND E5_DATA BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery4 += " UNION ALL "
		cQuery4 += " SELECT"
		cQuery4 += " 	 E5_DATA AS DTE5"
		cQuery4 += "    ,E5_NATUREZ AS NATUREZA"
		cQuery4 += "    ,E5_HISTOR AS HISTORICO"
		cQuery4 += "    ,E5_VALOR AS VLRE5"
		cQuery4 += " FROM " + RetSQLName ("SE5") + " AS SE5"
		cQuery4 += " WHERE D_E_L_E_T_ = '' 
		cQuery4 += " AND E5_FILIAL = '" + xFilial("SE5") +"'"
		cQuery4 += " AND E5_SITUACA <> 'C'"
		//cQuery4 += " AND E5_MOEDA = 'R$'"
		cQuery4 += " AND E5_BANCO = 'CL1'"
		cQuery4 += " AND E5_NATUREZ IN ('120643')"
		If !empty(mv_par11)
			cQuery4 += " AND E5_NATUREZ NOT IN ("+ alltrim(sNatExc) + ")"
		EndIf
		cQuery4 += " AND E5_DATA BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
		cQuery4 += " ORDER BY E5_DATA, E5_NATUREZ"
		
		tcquery cQuery4 new alias _trbNat
		_trbNat -> (dbgotop ())
		
		oReport:PrintText(" " ,,50)
		oReport:PrintText(" " ,,50)
		oReport:PrintText(" " ,,50)
		oReport:PrintText("VALORES DE DEPÓSITOS:" ,,50)
		oReport:ThinLine()
		
		Do While !Eof()
			oSection5:init()
			oSection5:Cell("COLUNA1"):SetValue(STOD(_trbNat -> DTE5))
			oSection5:Cell("COLUNA2"):SetValue(_trbNat -> NATUREZA)	
			oSection5:Cell("COLUNA3"):SetValue(_trbNat -> HISTORICO)	
			oSection5:Cell("COLUNA4"):SetValue(_trbNat -> VLRE5)		
			oSection5:Printline()
			
			nTDeposito += _trbNat -> VLRE5
			
			DbSelectArea("_trbNat")
			DBSkip()
		EndDo
		
		oReport:PrintText(" " ,,50)
		oReport:PrintText("TOTAL DE DEPÓSITOS: R$"+ alltrim(str(nTDeposito)) ,,50)
		
		_trbNat -> (DBCloseArea())
		oSection5:Finish()
	EndIf
		
	// Finaliza seções
	oSection4:Finish()
	oSection3:Finish()
	oSection2:Finish() 
	oSection1:Finish()


	// ------------------------------------------------------------------------------------------------------------
	// imprime notas fiscais
	oReport:SkipLine(3) 
	oReport:PrintText(" *** NOTAS FISCAIS ***",,1000)
	oReport:SkipLine(1) 

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 	SF2.F2_DOC AS TITULO"
	_oSQL:_sQuery += "    ,SF2.F2_SERIE AS SERIE"
	_oSQL:_sQuery += "    ,SF2.F2_EMISSAO AS DTEMISSAO"
	_oSQL:_sQuery += "    ,SUM(SE1.E1_VALOR) AS VALOR"
	_oSQL:_sQuery += "    ,SE1.E1_NSUTEF AS NSU"
	_oSQL:_sQuery += "    ,SE1.E1_CARTAUT AS AUT"
	_oSQL:_sQuery += "    ,SE1.E1_TIPO AS TIPO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " AS SF2"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC5") + " AS SC5"
	_oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SC5.C5_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SC5.C5_NOTA = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SC5.C5_SERIE = SF2.F2_SERIE"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO <> ''"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO IN ('CC', 'CD', 'R$','BOL')"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " AS SE1"
	_oSQL:_sQuery += " 	ON (SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SE1.E1_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SE1.E1_NUM = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SE1.E1_PREFIXO = SF2.F2_SERIE"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SF2.F2_FILIAL = '" + xFilial("SF2") +"'"
	_oSQL:_sQuery += " AND SF2.F2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	_oSQL:_sQuery += " GROUP BY SF2.F2_DOC"
	_oSQL:_sQuery += " 		,SF2.F2_SERIE"
	_oSQL:_sQuery += " 		,SF2.F2_EMISSAO"
	_oSQL:_sQuery += " 		,SE1.E1_CARTAUT"
	_oSQL:_sQuery += " 		,SE1.E1_NSUTEF"
	_oSQL:_sQuery += " 		,SE1.E1_TIPO "
	Do Case
		Case mv_par12 == 1
			_oSQL:_sQuery += " ORDER BY SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO" 
		Case mv_par12 == 2
			_oSQL:_sQuery += " ORDER BY SE1.E1_TIPO ,SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO"
		Case mv_par12 == 3
			_oSQL:_sQuery += " ORDER BY SF2.F2_SERIE, SF2.F2_DOC, SF2.F2_EMISSAO" 
	EndCase
	aNFs := aclone (_oSQL:Qry2Array ())

	For i:=1 to Len(aNFs)
		oSection6:init()
		oSection6:Cell("COLUNA1"):SetValue(aNFs[i,1])
		oSection6:Cell("COLUNA2"):SetValue(aNFs[i,2])	
		oSection6:Cell("COLUNA3"):SetValue(STOD(aNFs[i,3]))	
		oSection6:Cell("COLUNA4"):SetValue(aNFs[i,4])	
		oSection6:Cell("COLUNA5"):SetValue(aNFs[i,5])
		oSection6:Cell("COLUNA6"):SetValue(aNFs[i,6])
		oSection6:Cell("COLUNA7"):SetValue(aNFs[i,7])	

		oSection6:Printline()
	Next
	If Len(aNFs) > 0
		oSection6:Finish()
	EndIf

	// imprime TOTAIS notas fiscais
	oReport:SkipLine(3) 
	oReport:PrintText("TOTAIS - NOTAS FISCAIS",,50)
	oReport:SkipLine(1) 

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 	   SE1.E1_TIPO AS TIPO"
	_oSQL:_sQuery += "    ,SUM(SE1.E1_VALOR) AS VALOR"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " AS SF2"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC5") + " AS SC5"
	_oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SC5.C5_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SC5.C5_NOTA = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SC5.C5_SERIE = SF2.F2_SERIE"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO <> ''"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO IN ('CC', 'CD', 'R$','BOL')"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " AS SE1"
	_oSQL:_sQuery += " 	ON (SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SE1.E1_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SE1.E1_NUM = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SE1.E1_PREFIXO = SF2.F2_SERIE"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SF2.F2_FILIAL = '" + xFilial("SF2") +"'"
	_oSQL:_sQuery += " AND SF2.F2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	_oSQL:_sQuery += " GROUP BY  SE1.E1_TIPO "
	_oSQL:Log ()

	aTNFs := aclone (_oSQL:Qry2Array ())

	If Len(aTNFs) > 0
		oSection7:init()
		nTotNF := 0
	EndIf

	For i:=1 to Len(aTNFs)
		oSection7:Cell("COLUNA1"):SetValue(" ")
		oSection7:Cell("COLUNA2"):SetValue(aTNFs[i,1])	
		oSection7:Cell("COLUNA3"):SetValue(aTNFs[i,2])	
		nTotNF += aTNFs[i,2]
		oSection7:Printline()
	Next
	If Len(aTNFs) > 0
		oReport:PrintText(" " ,,50)
		oReport:PrintText("TOTAL DE NOTAS FISCAIS: R$ "+ alltrim(str(nTotNF)) ,,50)
		oReport:SkipLine(1) 
		oSection7:Finish()
	EndIf
	//
	// Totais gerais --------------------------------------------------------------------------------
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " 	WITH C"
	_oSQL:_sQuery += " 	AS"
	_oSQL:_sQuery += " 	(SELECT"
	_oSQL:_sQuery += " 			L4_FORMA AS TFORMA"
	_oSQL:_sQuery += " 		   ,L4_VALOR AS TVALOR"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SL1") + " AS SL1"
	_oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SL4") + " AS SL4"
	_oSQL:_sQuery += " 			ON (SL1.D_E_L_E_T_ = ''
	_oSQL:_sQuery += " 			AND SL4.D_E_L_E_T_ = ''
	_oSQL:_sQuery += " 			AND SL1.L1_FILIAL = SL4.L4_FILIAL
	_oSQL:_sQuery += " 			AND SL1.L1_NUM = SL4.L4_NUM
	If !empty(mv_par09)
		_oSQL:_sQuery += " AND SL4.L4_FORMA IN IN ("+ alltrim(sForPgt) + ")"
	EndIf
	_oSQL:_sQuery += " 			)"
	_oSQL:_sQuery += " 		WHERE SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SL1.L1_FILIAL = '" + xFilial("SL1") +"'"
	_oSQL:_sQuery += " 		AND SL1.L1_SERIE != '999'"
	_oSQL:_sQuery += " 		AND SL1.L1_DOC <> ''"
	_oSQL:_sQuery += " 		AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	If ! empty (mv_par03)
		_oSQL:_sQuery += " 	 AND SL1.L1_DOC BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	EndIf
	If ! empty (mv_par05)
		_oSQL:_sQuery += " 	 AND SL1.L1_SERIE BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"'"
	EndIf
	If ! empty (mv_par07)
		_oSQL:_sQuery += " 	 AND SL1.L1_NUM BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"'"
	EndIf
	_oSQL:_sQuery += " 		UNION ALL"
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SE1.E1_TIPO  AS TFORMA"
	_oSQL:_sQuery += " 		   ,SE1.E1_VALOR AS TVALOR"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SF2") + " AS SF2"
	_oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SC5") + " AS SC5"
	_oSQL:_sQuery += " 			ON (SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SC5.C5_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SC5.C5_NOTA = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SC5.C5_SERIE = SF2.F2_SERIE"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO <> ''"
	//_oSQL:_sQuery += " 			AND SC5.C5_VATIPO IN ('CC', 'CD', 'R$', 'BOL')"
	_oSQL:_sQuery += " 			)"
	_oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SE1") + " AS SE1"
	_oSQL:_sQuery += " 			ON (SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SE1.E1_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 			AND SE1.E1_NUM = SF2.F2_DOC"
	_oSQL:_sQuery += " 			AND SE1.E1_PREFIXO = SF2.F2_SERIE"
	_oSQL:_sQuery += " 			)"
	_oSQL:_sQuery += " 		WHERE SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SF2.F2_FILIAL = '" + xFilial("SF2") +"'"
	_oSQL:_sQuery += " 		AND SF2.F2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		TFORMA"
	_oSQL:_sQuery += " 	  ,SUM(TVALOR)"
	_oSQL:_sQuery += " 	FROM C"
	_oSQL:_sQuery += " 	GROUP BY TFORMA"
	_oSQL:Log ()

	aTotaisG := aclone (_oSQL:Qry2Array ())
		
	If Len(aTotaisG)
		oReport:ThinLine()
		oReport:ThinLine()
		oReport:PrintText(" " ,,50)
		oReport:PrintText("TOTAIS GERAIS (CUPONS + NOTAS):" ,,50)
		oReport:PrintText(" " ,,50)
		oReport:ThinLine()

		oSection8:init()
		
		nTG:= 0
	EndIf
	For i:=1 to Len(aTotaisG)
			
		Do Case
			Case alltrim(aTotaisG[i,1]) == 'CC'
				sDescForma := 'Cartão de crédito'
			Case alltrim(aTotaisG[i,1]) == 'CD'
				sDescForma := 'Cartão de débito'
			Case alltrim(aTotaisG[i,1]) == 'CH'
				sDescForma := 'Cheque'
			Case alltrim(aTotaisG[i,1]) == 'CO'		
				sDescForma := 'Convênio' 
			Case alltrim(aTotaisG[i,1]) == 'R$'
				sDescForma := 'Dinheiro' 
			Case alltrim(aTotaisG[i,1]) == 'VP'
				sDescForma := 'Vale' 
			Case alltrim(aTotaisG[i,1]) == 'BOL'
				sDescForma := 'Boleto' 
			Otherwise
				sDescForma :=''
		EndCase
					

		oSection8:Cell("COLUNA1"):SetValue(alltrim(aTotaisG[i,1])  +' - ' + alltrim(sDescForma))
		oSection8:Cell("COLUNA2"):SetValue(aTotaisG[i,2])		
		oSection8:Printline()
			
		nTG += aTotaisG[i,2]

	Next
		
	If Len(aTotaisG)
		oReport:PrintText(" " ,,50)
		oReport:PrintText("TOTAL GERAL: R$" + alltrim(STR(nTG)) ,,50)
		oSection8:Finish()
	EndIf
Return
//
// -----------------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes         Help
    aadd (_aRegsPerg, {01, "Emissao de       :", "D", 8, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {02, "Emissao até      :", "D", 8, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {03, "Cupom de         :", "C", 9, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {04, "Cupom até        :", "C", 9, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {05, "Série de         :", "C", 3, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {06, "Série até        :", "C", 3, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {07, "Orçamento de     :", "C", 6, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {08, "Orçamento até    :", "C", 6, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {09, "Formas de pgto   :", "C",80, 0,  "",  "   ", {}, 			"Separar por ;"})
    aadd (_aRegsPerg, {10, "Imprimir pgtos   ?", "N", 1, 0,  "",  "   ", {"Sim","Não"}, ""})
    aadd (_aRegsPerg, {11, "Excluir naturezas:", "C",80, 0,  "",  "   ", {}, 		    "Separar por ;"})
    aadd (_aRegsPerg, {12, "Ordem            :", "C",80, 0,  "",  "   ", {"Doc.+Série+Emissão","Pgt+Adm.+Doc.+Série+Emissão","Série+Doc.+Emissão"}, 		    "Separar por ;"})
    aadd (_aRegsPerg, {13, "Consulta         :", "N", 1, 0,  "",  "   ", {"Analítica","Sintética"}, })
     U_ValPerg (cPerg, _aRegsPerg)
Return
