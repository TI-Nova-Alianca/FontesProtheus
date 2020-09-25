#include "protheus.ch"
#include "report.ch"
#include "rwmake.ch"

//rotina de geração de cabeçalho personalizado TREPORT
//tipo: 1-retrato 2 = paisagem
User Function CabTReport(oReport,lin1,lin2,lin3,titulo,logo,fonte,tipo)
	Local cLogo         := logo
	Local oBox
	Local nPrinLin  := 0
	Local nInicio   := 25
	oReport:HideHeader()// Nao imprime cabecalho padrao do Protheus
	oReport:SkipLine()
    
	if tipo==1
		oReport:Box(20,20,250,2300,oBox) 
	elseif tipo==2
		oReport:Box(20,20,250,2800,oBox) 
	endif

	nPrinLin := nInicio
	oReport:OFONTBODY:NHEIGHT := 9  
	oReport:oFontHeader:NHEIGHT := 16
	oReport:OFONTBODY:NAME := fonte

	oReport:PrintText("",nPrinLin,10)
	//Logo da empresa
	oReport:SayBitmap(070,050,cLogo,440,130)
	nPrinLin += 40
	oReport:PrintText(lin1,nPrinLin,700)
	oReport:PrintText(lin1,nPrinLin,700)
	nPrinLin += 30
	oReport:PrintText(lin2,nPrinLin,700)
	nPrinLin += 30
	oReport:PrintText(lin3,nPrinLin,700)
	nPrinLin += 70
	oReport:PrintText(titulo,nPrinLin,1000) 
	oReport:PrintText(titulo,nPrinLin,1000)
	oReport:SkipLine()

Return( .T. )