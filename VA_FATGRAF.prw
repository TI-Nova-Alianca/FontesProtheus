// Programa:  VA_FATGRAF
// Autor:     Cláudia Lionço
// Data:      10/02/2020
// Descricao: Relatorio gráfico de faturamento das lojas/vendas black friday - CUPONS
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'msgraphi.ch' 

User Function VA_FATGRAF()
	Local oScroll
    //Local nGrafico := BARCOMPCHART
	Private cPerg  := "VA_FATGRAF"
	
	_ValidPerg()
	Pergunte(cPerg,.t.)

	Static oMonitor
	
	If mv_par06 == 1
		DEFINE MSDIALOG oMonitor TITLE "Vendas por hora" FROM 0,0  TO 600,900 COLORS 0, 16777215 PIXEL 
	Else
		DEFINE MSDIALOG oMonitor TITLE "Vendas por dia da semana" FROM 0,0  TO 600,900 COLORS 0, 16777215 PIXEL 
	EndIf
	
	
	oScroll := TScrollArea():New(oMonitor,01,01,400,700)
	oScroll:Align := CONTROL_ALIGN_ALLCLIENT    

	//_FatGraf(oScroll,nGrafico)

	oMenu := TBar():New( oMonitor, 48, 48, .T., , ,"CONTEUDO_BODY-FUNDO", .T. )
	//DEFINE BUTTON RESOURCE "FW_PIECHART_1"     OF oMenu  ACTION _FatGraf(oScroll,PIECHART)     PROMPT " "  TOOLTIP "Pizza"      
	//DEFINE BUTTON RESOURCE "FW_LINECHART_1"    OF oMenu  ACTION _FatGraf(oScroll,LINECHART)    PROMPT " "  TOOLTIP "Linha"      
	DEFINE BUTTON RESOURCE "FW_BARCHART_1"     OF oMenu  ACTION _FatGraf(oScroll,BARCHART)     PROMPT " "  TOOLTIP "Barra"      
	DEFINE BUTTON RESOURCE "FW_BARCOMPCHART_2" OF oMenu  ACTION _FatGraf(oScroll,BARCOMPCHART) PROMPT " "  TOOLTIP "Barra"      

	ACTIVATE MSDIALOG oMonitor CENTERED
Return
// ------------------------------------------------------------------------------------------------------------------------------------------
// Imprime gráfico
Static Function _FatGraf(oScroll,nGrafico)
	Local x		  := 0
	Local _aDados := {}
	Local oChart
	//Local cQuery  := ""

	If Valtype(oChart)=="O"
		FreeObj(@oChart) //Usando a função FreeObj liberamos o objeto para ser recriado novamente, gerando um novo gráfico
	Endif

	oChart := FWChartFactory():New()
	oChart := oChart:getInstance( nGrafico ) 
	oChart:init( oScroll )
	//oChart:SetTitle("Venda por hora", CONTROL_ALIGN_LEFT)
	oChart:SetMask( "R$ *@*")
	oChart:SetPicture("@E 999,999,999,999.99")
	oChart:setColor("Random") //Deixamos o protheus definir as cores do gráfico
	//oChart:SetLegend( CONTROL_ALIGN_BOTTOM ) 
	oChart:nTAlign := CONTROL_ALIGN_ALLCLIENT

	If mv_par06 == 1
		_PorDiaDaSemana(_aDados)
	Else
		_PorHora(_aDados)
	EndIf

	For x:=1 to Len(_aDados)
		if nGrafico==LINECHART .OR. nGrafico==BARCOMPCHART 
			oChart:addSerie(_aDados[x,1],{{_aDados[x,1], _aDados[x,2]}})//(Titulo, {{ Descrição, Valor }})
		Else 	
			oChart:AddSerie(_aDados[x,1],_aDados[x,2]) //(Titulo, Valor)	
		Endif
	Next

	oChart:build()
Return
// ------------------------------------------------------------------------------------------------------------------------------------------
// Consulta por dia da semana
Static Function _PorDiaDaSemana(_aDados)
	Local cQuery := ""

	cQuery := " WITH C "
	cQuery += " AS"
	cQuery += " (SELECT"
	cQuery += " 		CASE DATEPART(DW, L1_EMISNF)"
	cQuery += " 			WHEN 1 THEN 'DOMINGO'
	cQuery += " 			WHEN 2 THEN 'SEGUNDA'"
	cQuery += " 			WHEN 3 THEN 'TERCA'
	cQuery += " 			WHEN 4 THEN 'QUARTA'"
	cQuery += " 			WHEN 5 THEN 'QUINTA'"
	cQuery += " 			WHEN 6 THEN 'SEXTA'"
	cQuery += " 			WHEN 7 THEN 'SABADO'"
	cQuery += " 		END AS DIA_SEMANA"
	cQuery += " 	   ,SUM(L1_VLRTOT) AS VALOR"
	cQuery += "       ,L1_NUM AS  CUPONS"
	cQuery += " 	  ,CASE DATEPART(DW, L1_EMISNF)"
	cQuery += " 			WHEN 1 THEN '1'
	cQuery += " 			WHEN 2 THEN '2'"
	cQuery += " 			WHEN 3 THEN '3'
	cQuery += " 			WHEN 4 THEN '4'"
	cQuery += " 			WHEN 5 THEN '5'"
	cQuery += " 			WHEN 6 THEN '6'"
	cQuery += " 			WHEN 7 THEN '7'"
	cQuery += " 		END AS DIA"
	cQuery += " 	FROM " + RetSQLName ("SL1") + " SL1 "
	cQuery += " 	WHERE D_E_L_E_T_ = ''"
	cQuery += " 	AND L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery += " 	AND L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery += " 	AND L1_SERIE != '999'"
	cQuery += " 	AND L1_SITUA = 'OK'"
	If !empty(mv_par05)
			cQuery += " AND L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	cQuery += " 	GROUP BY L1_EMISNF, L1_NUM )"
	cQuery += " SELECT"
	cQuery += " 	DIA_SEMANA"
	cQuery += "    ,SUM(VALOR) AS VALOR"
	cQuery += "    ,COUNT(CUPONS) AS CUPONS"
	cQuery += " FROM C"
	cQuery += " GROUP BY DIA_SEMANA, DIA"
	cQuery += " ORDER BY DIA"
	_aDados := U_Qry2Array(cQuery)

Return _aDados
// ------------------------------------------------------------------------------------------------------------------------------------------
// Consulta por hora
Static Function _PorHora(_aDados)
	Local cQuery   := ""
	//Local _aHora   := {}
	//Local _aQCupom := {}
	//Local x        := 0
	
	cQuery += " SELECT"
	cQuery += " 	HORA"
	cQuery += "    ,VALOR"
	cQuery += " FROM (SELECT"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '00:00' AND '00:59' THEN L1_VALBRUT ELSE 0 END) AS [00],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '01:00' AND '01:59' THEN L1_VALBRUT ELSE 0 END) AS [01],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '02:00' AND '02:59' THEN L1_VALBRUT ELSE 0 END) AS [02],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '03:00' AND '03:59' THEN L1_VALBRUT ELSE 0 END) AS [03],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '04:00' AND '04:59' THEN L1_VALBRUT ELSE 0 END) AS [04],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '05:00' AND '05:59' THEN L1_VALBRUT ELSE 0 END) AS [05],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '06:00' AND '06:59' THEN L1_VALBRUT ELSE 0 END) AS [06],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '07:00' AND '07:59' THEN L1_VALBRUT ELSE 0 END) AS [07],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '08:00' AND '08:59' THEN L1_VALBRUT ELSE 0 END) AS [08],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '09:00' AND '09:59' THEN L1_VALBRUT ELSE 0 END) AS [09],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '10:00' AND '10:59' THEN L1_VALBRUT ELSE 0 END) AS [10],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '11:00' AND '11:59' THEN L1_VALBRUT ELSE 0 END) AS [11],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '12:00' AND '12:59' THEN L1_VALBRUT ELSE 0 END) AS [12],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '13:00' AND '13:59' THEN L1_VALBRUT ELSE 0 END) AS [13],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '14:00' AND '14:59' THEN L1_VALBRUT ELSE 0 END) AS [14],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '15:00' AND '15:59' THEN L1_VALBRUT ELSE 0 END) AS [15],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '16:00' AND '16:59' THEN L1_VALBRUT ELSE 0 END) AS [16],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '17:00' AND '17:59' THEN L1_VALBRUT ELSE 0 END) AS [17],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '18:00' AND '18:59' THEN L1_VALBRUT ELSE 0 END) AS [18],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '19:00' AND '19:59' THEN L1_VALBRUT ELSE 0 END) AS [19],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '20:00' AND '20:59' THEN L1_VALBRUT ELSE 0 END) AS [20],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '21:00' AND '21:59' THEN L1_VALBRUT ELSE 0 END) AS [21],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '22:00' AND '22:59' THEN L1_VALBRUT ELSE 0 END) AS [22],"
	cQuery += " 		SUM(CASE WHEN L1_HORA BETWEEN '23:00' AND '23:59' THEN L1_VALBRUT ELSE 0 END) AS [23] "
	cQuery += " 	FROM " + RetSQLName ("SL1") + " SL1 "
	cQuery += " 	WHERE D_E_L_E_T_ = ''"
	cQuery += " 	AND L1_FILIAL BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
	cQuery += " 	AND L1_EMISNF BETWEEN  '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
	cQuery += " 	AND L1_SERIE != '999'"
	If !empty(mv_par05)
			cQuery += " AND L1_SERIE = '" + alltrim(mv_par05) + "' "
	EndIf
	cQuery += " 	AND L1_SITUA = 'OK') p"
	cQuery += " UNPIVOT"
	cQuery += " (VALOR FOR HORA IN"
	cQuery += " ([00],[01],[02],[03],[04],[05],[06],[07],[08],[09],[10],[11],[12],"
	cQuery += " [13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23]) "
	cQuery += " ) AS TOTAL_HORAS"
	_aDados  := U_Qry2Array(cQuery)	

Return _aDados

//User Function VA_FATGRAF()
//    local lGraph3D 		:= .F. // .F. Grafico 2 dimensoes - .T. Grafico 3 dimensoes
//    local lMenuGraph 	:= .t. // .F. Nao exibe menu - .T. Exibe menu para mudar o tipo de grafico
//    local lMudaCor 		:= .t.
//    local nTipoGraph 	:= 2
//    local nCorDefault 	:= 1
//    local _aDados 		:= {}
//    local x				:= 0
//	Private cPerg   := "VA_FATGRAF"
//	
//	_ValidPerg()
//	Pergunte(cPerg,.t.)
//	
//	If mv_par06 == 1
//		_PorDiaDaSemana(_aDados)
//		DEFINE DIALOG oDlg TITLE "VENDA POR DIA DA SEMANA" FROM 180,180 TO 750, 1200 PIXEL
//	Else
//		_PorHora(_aDados)
//		DEFINE DIALOG oDlg TITLE "VENDA POR HORA" FROM 180,180 TO 750, 1200 PIXEL
//	EndIf
//  
//    // Cria o gráfico
//    oGraphic := TMSGraphic():New( 01,01,oDlg,,,RGB(239,239,239),500,284)   
//    oGraphic:SetTitle("Período de:" + dtoc(mv_par01) + " até " + dtoc(mv_par02), "Loja de:" + alltrim(mv_par03)+" até "+ alltrim(mv_par04), CLR_HRED, A_LEFTJUST, GRP_TITLE )
//    oGraphic:SetMargins(2,6,6,6)
//    oGraphic:SetLegenProp(GRP_SCRRIGHT, CLR_LIGHTGRAY, GRP_AUTO, .T.)
//      
//    // 	Tipo do Gráfico
//	Do Case
//    	Case mv_par07 == 1 
//    		nSerie := oGraphic:CreateSerie( GRP_LINE )
//    	Case mv_par07 == 2 
//    		nSerie := oGraphic:CreateSerie( GRP_AREA )
//    	Case mv_par07 == 3 
//    		nSerie := oGraphic:CreateSerie( GRP_POINT )
//    	Case mv_par07 == 4 
//    		nSerie := oGraphic:CreateSerie( GRP_BAR )
//    	Case mv_par07 == 5 
//    		nSerie := oGraphic:CreateSerie( GRP_PIE ) 
//    EndCase
//    
//    For x:=1 to Len(_aDados)
//    	Do Case
//    		Case x == 1 .or. x == 9  .or. x == 17
//    			sColor := CLR_HCYAN    			
//    		Case x == 2 .or. x == 10 .or. x == 18
//    			sColor := CLR_CYAN    			
//    		Case x == 3 .or. x == 11 .or. x == 19
//    			sColor := CLR_HBLUE    			
//    		Case x == 4 .or. x == 12 .or. x == 20
//    			sColor := CLR_HGRAY    			
//    		Case x == 5 .or. x == 13 .or. x == 21
//    			sColor := CLR_HMAGENTA    			
//    		Case x == 6 .or. x == 14 .or. x == 22
//    			sColor := CLR_MAGENTA    			
//    		Case x == 7 .or. x == 15 .or. x == 23
//    			sColor := CLR_BROWN
//    		Case x == 8 .or. x == 16 .or. x == 24
//    			sColor := CLR_GRAY 
//    		
//    	EndCase
//    	oGraphic:Add(nSerie, _aDados[x,2], _aDados[x,1], sColor ) 
//    Next
//    ACTIVATE DIALOG oDlg CENTERED 
//  
//Return
//
//---------------------- PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Dt.venda de      	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Dt.venda até     	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Loja de       	    ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Loja até      	    ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "PDV         	    ", "C", 3, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {06, "Tipo             	", "N", 1, 0,  "",  "   ", {"Por Dia Semana","Por Hora"},               ""})
    //aadd (_aRegsPerg, {07, "Gráfico         	", "N", 1, 0,  "",  "   ", {"Linha","Área","Ponto","Barra","Pizza"},    ""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
