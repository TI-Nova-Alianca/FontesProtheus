// Programa:  ML_LOJPGT
// Autor:     Cláudia Lionço
// Data:      30/08/2019
// Descricao: Relatorio de vendas de lojas com listagem de tipo de de pagamentos
//
// Historico de alteracoes:
// 23/09/2019 - Claudia - Incluidas alterações conforme GLPI 6312
// 25/09/2019 - Claudia - Incluida opção sintética do relatório
// 10/12/2019 - Claudia - Incluido filtro de itens deletados e cancelados na tabela SE5
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
	Local oBreak
	Local oFunction
	Local oBreak1

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
Return(oReport)
//
// -----------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)	 
	Local oSection3 := oReport:Section(3)	
	Local oSection4 := oReport:Section(4)
	Local oSection5 := oReport:Section(5)
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
	Local x			:= 0
	
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
	oReport:PrintText("TOTAIS POR TIPO DE PAGAMENTO:" ,,50)
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
	oReport:PrintText("RESUMO:" ,,50)
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
