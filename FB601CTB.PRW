#Include "ATFR080.CH"
#Include "Protheus.ch"
#Include "fwcommand.ch"
#INCLUDE "REPORT.CH"

// Autor:     TOTVS Serra Gaúcha
// Data:      19/07/2019
// Descricao: Relatório de Depreciação por Conta e Centro de Custo
//
// Historico de alteracoes:
// 07/07/2023 - Robert - Na leitura do SN4, filtrar campo N4_CODBAIX para
//                       desconsiderar situacao de 'aquisicao por transferencia' (GLPI 13856)
//


User Function FB601CTB()
	Local oReport
	Private aSelFil	:= {}

	oReport := ReportDef()

	If oReport <> nil
		oReport:PrintDialog()
	EndIf

Return

//A função estática ReportDef deverá ser criada para todos os relatórios que poderão ser agendados pelo usuário
Static Function ReportDef
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oSection3:= Nil
	Local oReport
	Local cReport  := "FB601ATF"
	Local cTitulo  := "Resumo por Conta e Centro de Custo"
	Local cDescri  := "Emissão de Resumo do Ativo Imobilizado por Conta" + " " +;
	STR0002 + " " //Contábil e Centro de Custos
	Local bReport  := { |oReport|	ReportPrint( oReport ) }

	Private nValBai := 0 //Baixa
	Private nValTde := 0 //Trabsferência de
	Private nValTpa := 0 //Transferência para
	Private nValDef := 0 //Depreciação Fiscal
	Private nValDeg := 0 //Depreciação Gerencial

	Pergunte( "FB601ATF" , .F. )

	If mv_par15 == 1 .And. Len( aSelFil ) <= 0 .And. !IsBlind() //SELECIONA FILIAIS
		aSelFil := AdmGetFil()
		//Caso nenhuma filial seja selecionada
		If Len( aSelFil ) <= 0
			Return 	//Retorna o objeto oReport vazio
		EndIf
	EndIf

	oReport  := TReport():New( cReport, cTitulo, "FB601ATF" , bReport, cDescri )
	oReport:SetPortrait()
	oReport:SetTotalInLine(.T.)

	oSection1 := TRSection():New( oReport, "Conta Contábil", {"SN4"}, , .F., .T.)//Filial + Cod. Conta + Descrição Conta
	TRCell():New(oSection1, "N4_FILIAL" ,"TRB","FILIAL"         ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "N4_CONTA" ,"TRB","COD. CONTA"     ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1, "CT1_DESC01","TRB","DESCRIÇÃO CONTA",/*Picture*/,40,/*lPixel*/,/*{|| code-block de impressao }*/)
	oBreak := TRBreak():New(oSection1,oSection1:Cell("N4_CONTA"),"Total por Conta" )

	oSection1:SetHeaderSection(.T.)

	oSection2 := TRSection():New( oSection1, "Centro de Custo", {"SN4"}, , .F., .T.) //Centro de Custo
	TRCell():New( oSection2, "N4_CCUSTO"  , "TRB","CENTRO DE CUSTO",/*Picture*/, 14 ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New( oSection2, "CTT_DESC01" , ,"DESCRIÇÃO CC"  ,"@!" /*Picture*/, 40 ,/*lPixel*/,/*{|| code-block de impressao }*/)

	oSection3 := TRSection():New( oSection2, "Dados", {"SN4"} , , .F., .T.) //Valores
	TRCell():New( oSection3, "N4_DATA"		, "TRB"	 ,"PERÍODO",/*Picture*/, 14  ,/*lPixel*/,/*{|| code-block de impressao }*/) //Moeda	
	TRCell():New( oSection3, "N4_VLRBAI"	, "TRB"  ,"BAIXAS","@E 999,999,999.99", 14 ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New( oSection3, "N4_VLRTDE"	, "TRB"	 ,"TRANSFERÊNCIA DE","@E 999,999,999.99", 14 ,/*lPixel*/,/*{|| code-block de impressao }*/) //Depreciação
	TRCell():New( oSection3, "N4_VLRTPA"	, "TRB"  ,"TRANSFERÊNCIA PARA","@E 999,999,999.99", 14 ,/*lPixel*/,/*{|| code-block de impressao }*/)

	TRCell():New( oSection3, "N4_VLRDFI"	, "TRB"  ,"DEPRECIAÇÃO FISCAL","@E 999,999,999.99", 14 ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New( oSection3, "N4_VLRDGE"	, "TRB"	 ,"DEPRECIAÇÃO GERENCIAL","@E 999,999,999.99", 14 ,/*lPixel*/,/*{|| code-block de impressao }*/) //Depr. Acumulada
	
	oSection1:SetHeaderPage(.T.)
	oSection1:SetColSpace(1)
	oSection2:SetHeaderPage(.T.)
	oSection2:SetColSpace(1)
	oSection3:SetHeaderPage(.T.)
	oReport:SetUseGC(.F.)

	oTotGrp1 := TRFunction():New(oSection3:Cell("N4_VLRBAI"),,"SUM",oBreak/*oBreak*/,/*Titulo*/,"@E 999,999,999.99",;
	{ || nValBai },.F.,.F.,.F.,oSection1)
	oTotGrp1 := TRFunction():New(oSection3:Cell("N4_VLRTDE"),,"SUM",oBreak/*oBreak*/,/*Titulo*/,"@E 999,999,999.99",;
	{ || nValTde},.F.,.F.,.F.,oSection1)
	oTotGrp1 := TRFunction():New(oSection3:Cell("N4_VLRTPA"),,"SUM",oBreak/*oBreak*/,/*Titulo*/,"@E 999,999,999.99",;
	{ || nValTpa},.F.,.F.,.F.,oSection1)
	oTotGrp1 := TRFunction():New(oSection3:Cell("N4_VLRDFI"),,"SUM",oBreak/*oBreak*/,/*Titulo*/,"@E 999,999,999.99",;
	{ || nValDef},.F.,.F.,.F.,oSection1)
	oTotGrp1 := TRFunction():New(oSection3:Cell("N4_VLRDGE"),,"SUM",oBreak/*oBreak*/,/*Titulo*/,"@E 999,999,999.99",;
	{ || nValDeg},.F.,.F.,.F.,oSection1)

	oSection3:SetHeaderBreak(.T.)

Return oReport

//Impressão do relatório
Static Function ReportPrint(oReport)

	Local oSection1	  := oReport:Section(1)
	Local oSection2   := oReport:Section(1):Section(1)
	Local oSection3   := oReport:Section(1):Section(1):Section(1)
	Local nA          := 0
	Local nX		  := 0
	Local nInc		  := 0
	Local aSM0		  := FWLoadSM0()
	Local cTpGerenc	  := ""
	Local nTamEmp	  := 0
	Local lTotEmp	  := .F.
	Local aEmpMoeda	  := {}
	Local nValor      := 0
	Local cFilDe
	Local cFilAte
	Local aGeralMoeda  // Total Geral
	

	IF mv_par16 == 1 //EXIBE INFORMAÇÕES - fiscal
		cTpGerenc	:= ATFXTpBem(1) //01/02/03/04/05/06/07/11
	ElseIf mv_par16 == 2 //EXIBE INFORMAÇÕES - gerencial
		cTpGerenc	:= ATFXTpBem(2) //10/12/13/14/15/66/17
	Else
		cTpGerenc	:= ATFXTpBem(1)
		cTpGerenc	+= ATFXTpBem(2)
	EndIf

	aTpGer := StrTokArr(cTpGerenc,"/")

	//Atribui valores as variáveis ref a filiais
	If mv_par12 == 2
		cFilDe  := cFilAnt
		cFilAte := cFilAnt

	ELSE
		cFilDe := mv_par13	//Todas as filiais
		cFilAte:= mv_par14

	Endif

	If mv_par15 == 1 .And. !IsBlind() //SELECIONA FILIAIS
		If Empty(aSelFil)
			If  FindFunction("AdmSelecFil")
				AdmSelecFil("FB601ATF",22,.F.,@aSelFil,"SN4",.F.)
			Else
				aSelFil := AdmGetFil(.F.,.F.,"SN4")
				If Empty(aSelFil)
					Aadd(aSelFil,cFilAnt)
				Endif
			Endif
		Endif
	Endif

	If Empty(aSelFil)
		Aadd(aSelFil, cFilAnt)
	EndIf
	nLenSelFil := Len(aSelFil)
	cFilDe := aSelFil[1]
	cFilAte := aSelFil[nLenSelFil]
	nTamEmp := Len(FWSM0LayOut(,1))
	lTotEmp := .F.
	aEmpMoeda := aClone(aGeralMoeda)
	nInc := 0

	//Deixa na aSM0 somente as filiais selecionas para impressão
	nLenSelFil := Len(aSM0)
	For nA := nLenSelFil To 1 Step(-1)
		If  Ascan(aSelFil,aSM0[nA,SM0_CODFIL]) == 0
			Adel(aSM0,nA)
			nInc++
		Endif
	Next
	If nInc > 0
		Asize(aSM0,Len(aSM0) - nInc)
	Endif

	//Verifico se e necessário a impressão de total por empresa: se as filiais selecionadas pertencem a empresas distintas
	nLenSelFil := Len(aSM0)
	nA := 1
	While nA < nLenSelFil .And. !lTotEmp
		nA++
		lTotEmp := !(aSM0[nA - 1,SM0_EMPRESA] == aSM0[nA,SM0_EMPRESA])
	Enddo
	nLenSelFil := Len(aSelFil)

	For nInc := 1 To Len( aSM0 )
		If aSM0[nInc][SM0_GRPEMP] == cEmpAnt .AND. aSM0[nInc][SM0_CODFIL] >= cFilDe .AND. aSM0[nInc][SM0_CODFIL] <= cFilAte
			cFilAnt := aSM0[nInc][SM0_CODFIL]

			cQuery := " SELECT N4_FILIAL, N4_CONTA, N4_CCUSTO, N4_OCORR, N4_TIPO, SUBSTRING(N4_DATA,1,6) AS DATA, SUM(N4_VLROC1) AS VLROC1, SUM(N4_VLROC2) AS VLROC2, SUM(N4_VLROC3) AS VLROC3, SUM(N4_VLROC4) AS VLROC4, SUM(N4_VLROC5) AS VLROC5 "
			cQuery += " FROM " + RetSQLName ("SN4") + " SN4 "
			cQuery += " WHERE SN4.D_E_L_E_T_ = ''""
			cQuery += " AND SUBSTRING(N4_DATA,1,6) BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'" //Data Inicial - Data Final
			If mv_par15 == 1 
				cQuery += " AND N4_FILIAL =  '"+ cFilAnt+ "'"
			Else
				cQuery += " AND N4_FILIAL >=  '"+ cFilDe+ "'"
				cQuery += " AND N4_FILIAL >=  '"+ cFilAte+ "'"
			EndIf
			cQuery += " AND N4_CONTA <> '' "
			//cQuery += " AND N4_CCUSTO <> '' " //Considerar també os Centros de Custo em Branco
			cQuery += " AND N4_CONTA BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'" //Conta Contábil de - Conta Contábil Até
			cQuery += " AND N4_CCUSTO BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'" //Centro de Custo de = Centro de Custo Até
			cQuery += " AND N4_OCORR  IN ('01','03','04','06','20')"
			
			// Desconsiderar situacao de 'aquisicao por transferencia' (divide ou aglutina bens)
			cQuery += " AND N4_CODBAIX = ''"
			
			cQuery += "  AND ( "
			For nX := 1 to Len(aTpGer)
				If nX == Len(aTpGer)
					cQuery += " N4_TIPO = '" + AllTrim(aTpGer[nX]) + "' )"
				Else
					cQuery += " N4_TIPO = '" + AllTrim(aTpGer[nX]) + "' OR"
				EndIf	
			Next nX	
			cQuery += " GROUP BY N4_FILIAL, N4_CONTA, N4_CCUSTO, N4_DATA, N4_OCORR, N4_TIPO  "
			if mv_par05 == 1
				cQuery += " ORDER BY N4_FILIAL, N4_CONTA, N4_CCUSTO, N4_DATA, N4_OCORR, N4_TIPO "

			elseif mv_par05 == 2
				cQuery+= " ORDER BY N4_FILIAL, N4_CONTA, N4_DATA"
			endif

			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRB", .F., .T.)

			Memowrite("C:\temp\Query_ativo.txt",cQuery)

			DbSelectArea("TRB")
			DbGoTop()

			WHILE !TRB->(EoF())


				cConta := TRB->N4_CONTA
				oSection1:Init()
				dbSelectArea("CT1")
				dbSetOrder(1)
				MsSeek(xFilial("CT1")+TRB->N4_CONTA,.T.)
				cDescCT := CT1->CT1_DESC01

				//oSection1
				oSection1:Cell("N4_FILIAL"):SetValue(TRB->N4_FILIAL)
				oSection1:Cell("N4_CONTA"):SetValue(TRB->N4_CONTA)
				oSection1:Cell("CT1_DESC01"):SetBlock( {|| cDescCT } )
				oSection1:Printline()

				While !TRB->(EoF()) .AND. TRB->N4_CONTA == cConta
					If oReport:Cancel()
						Exit
					EndIf

					dbSelectArea("CTT")
					dbSetOrder(1)
					
					cDescCC := ""
					
					if CTT->(MSSeek(xFilial("CTT")+TRB->N4_CCUSTO))
						cDescCC := CTT->CTT_DESC01
					endif
					
					cDescBR := ""
					oReport:IncMeter()

					cCCusto := TRB->N4_CCUSTO

					//oSection2
					oSection2:Init()
					if mv_par05 == 2 
						oSection2:hide()
					endif
					oReport:IncMeter()
					oSection2:Cell("N4_CCUSTO"):SetValue(TRB->N4_CCUSTO)
					If cCCusto <> ''
						
						oSection2:Cell("CTT_DESC01"):SetBlock( {|| cDescCC } )
					Else
						oSection2:Cell("CTT_DESC01"):Disable()
					EndIF

					oSection2:Printline()

					If mv_par11 == 2 
						oSection3:hide()
					EndIf
					oSection3:Init()

					nValor	:= 0
					nValBai := 0
					nValTde := 0
					nValTpa := 0
					nValDef := 0
					nValDeg := 0

					cData := SUBSTRING(TRB->DATA,1,6)

					While !TRB->(EoF()) .AND. (TRB->N4_CCUSTO == cCCusto .AND. TRB->N4_CONTA == cConta) .OR. (MV_PAR05 == 2 .and. TRB->N4_CONTA == cConta) 

						cData := SUBSTRING(TRB->DATA,1,6)
						If SUBSTRING(cData,5,6) = '01'
							nData := "Jan/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '02'
							nData := "Fev/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '03'
							nData := "Mar/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '04'
							nData := "Abr/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '05'
							nData := "Mai/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '06'
							nData := "Jun/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '07'
							nData := "Jul/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '08'
							nData := "Ago/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '09'
							nData := "Set/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '10'
							nData := "Out/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '11'
							nData := "Nov/" + SUBSTRING(cData,1,4)
						ElseIf SUBSTRING(cData,5,6) = '12'
							nData := "Dez/" + SUBSTRING(cData,1,4)
						EndIF
						oSection3:Cell("N4_DATA"):SetBlock( {|| nData } )

						If mv_par08 = 1 //Moeda 1
							nValor := TRB->VLROC1
						EndIf
						If mv_par08 = 2 //Moeda 2
							nValor := TRB->VLROC2
						EndIf
						If mv_par08 = 3 //Moeda 3
							nValor := TRB->VLROC3
						EndIf
						If mv_par08 = 4 //Moeda 4
							nValor := TRB->VLROC4
						EndIf
						If mv_par08 = 5  //Moeda 5
							nValor := TRB->VLROC5
						EndIf

						If TRB->N4_OCORR = '01' //Baixa
							nValBai += nValor
						EndIf
						If TRB->N4_OCORR = '03' //Trabsferência de
							nValTde += nValor
						EndIf
						If TRB->N4_OCORR = '04' //Transferência para
							nValTpa += nValor
						EndIf
						If TRB->N4_OCORR = '06' //Depreciação Fiscal
							nValDef += nValor
						EndIf
						If TRB->N4_OCORR = '20' //Depreciação Gerencial
							nValDeg += nValor
						EndIf

						If mv_par10 = 1 //Considera Baixas
							oSection3:Cell("N4_VLRBAI"):SetBlock( {|| nValBai } )
						Else
							oSection3:Cell("N4_VLRBAI"):Disable()
						EndIf
						
						If mv_par09 = 1 //Considera Transferências
							oSection3:Cell("N4_VLRTDE"):SetBlock( {|| nValTde } )
							oSection3:Cell("N4_VLRTPA"):SetBlock( {|| nValTpa } )
						Else
							oSection3:Cell("N4_VLRTDE"):Disable()
							oSection3:Cell("N4_VLRTPA"):Disable()
						EndIF
						
	
						oSection3:Cell("N4_VLRDFI"):SetBlock( {|| nValDef } )
						oSection3:Cell("N4_VLRDGE"):SetBlock( {|| nValDeg } )

						TRB->(dbSkip())

						If (mv_par05 == 2 .and. (cConta <> TRB->N4_CONTA .or. cData <> SUBSTRING(TRB->DATA,1,6)) ) .or. (mv_par05 == 1 .and. (cConta <> TRB->N4_CONTA .OR. cCCusto <> TRB->N4_CCUSTO .OR. cData <> SUBSTRING(TRB->DATA,1,6)))
							oSection3:Printline()
							nValor  := 0
							nValBai := 0
							nValTde := 0
							nValTpa := 0
							nValDef := 0
							nValDeg := 0
							cData := SUBSTRING(TRB->DATA,1,6)
						EndIf
					EndDo
					oSection3:Finish()
					oSection2:Finish()
				EndDo
				oSection1:Finish()
			EndDo
		EndIF
		TRB->(dbCloseArea())
	Next
Return Nil
