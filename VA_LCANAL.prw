/* *********************************************************************************************************
***************************** RELATÓRIO DE LISTA POR CANAL X ESTADO ****************************************
***** Módulo: faturamento ********************************************************************************** 
***** Data de Criação: 30/04/2014 **************************************************************************
***** Alterações: ******************************************************************************************
// - 18/06/2016 - Catia - alterada razao social que esta fixa
************************************************************************************************************ */
#include "protheus.ch"
#include "rwmake.ch"

User Function VA_LCANAL()

	cPerg   := "VA_LCANAL"
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
	
Return
 
static function ReportDef()
	local oReport
	Local oSection1
	Local oSection2
	Local cCodTab := ""
	Local cTitulo := 'Lista de Preços Por Canal x Estado'
	Local aArray  := {}
	Local oBreak
 
	oReport := TReport():New("VA_LCANAL", cTitulo, cPerg, {|oReport| PrintReport(oReport)},"Este relatorio ira emitir a lista de valores por canal.")
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
   //	oReport:ShowHeader()  
	
    //SESSÃO 1 - LISTA
	oSection1 := TRSection():New(oReport,"Lista",{""})
	oSection1:SetTotalInLine(.F.)
	TRCell():New(oSection1,"CODPRO", " ","Produto"				,"999999"		,10,/*lPixel*/,{|| aLista[a, 1] },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"DESC"  , " ","Descrição do Produto",""				,70,/*lPixel*/,{|| aLista[a, 2] },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"VALOR" , " ","Valor",				"999,999,999.99",15,/*lPixel*/,{|| aLista[a, 3] },"RIGHT",,,,,,,,.T.)
	TRCell():New(oSection1,"VALST" , " ","Valor ST",			"999,999,999.99",15,/*lPixel*/,{|| aLista[a, 4] },"RIGHT",,,,,,,,.T.)
	TRCell():New(oSection1,"ESTADO", " ","Estado",				""				,5,/*lPixel*/,{|| aLista[a, 5] },"RIGHT",,,,,,,,.T.)
      
return (oReport)
 
Static Function PrintReport(oReport)
     
	Local aLista    := {}
	Local oSection1 := oReport:Section(1)
	Local nTitulo	:="                                          CANAL "+MV_PAR01+" - " +AllTrim(MV_PAR04)
	Local nLinhaB   := ""
	Local nCIF		:= "					Quando Frete CIF: até " + AllTrim(MV_PAR02) + "%"
	Local nFOB		:= "					Quando Frete FOB: até " + AllTrim(MV_PAR03) + "%"
	Local a			:= 0
    
    //declaração do cabeçalho
	lin1:="COOPERATIVA AGROINDUSTRIAL NOVA ALIANCA LTDA"
	lin2:="RUA JEIJÓ JÚNIOR Nr. 164 - Bairro SÃO PELEGRINO - CEP 95.034-160 - CAXIAS DO SUL - RS -Fone/faz:55+ (54) 4009-4255"
	lin3:="E-mail: alianca@novaalianca.coop.br - http://www.novaalianca.coop.br"
	logo:="logo2.jpg"
	fonte:="ARIAL"
	titulo:="TABELA DE PREÇOS POR CANAL"
 
	U_CabTReport(oReport,lin1,lin2,lin3,titulo,logo,fonte)
	oReport:PrintText("",350,50)
    
	cQuery := " SELECT DA1_CANAL, DA1_ESTADO, DA1_CODPRO, B1_DESC, DA1_PRCVEN, DA1_VAST "
	cQuery += " FROM DA1010 DA1, SB1010 SB1 "
	cQuery += " WHERE "
	cQuery += " DA1.DA1_FILIAL='01' "
	cQuery += " AND SB1.B1_FILIAL='' "
	cQuery += " AND SB1.D_E_L_E_T_='' "
	cQuery += " AND DA1.D_E_L_E_T_='' "
	cQuery += " AND SB1.B1_COD=DA1.DA1_CODPRO "
	cQuery += " AND DA1.DA1_CODTAB='"+MV_PAR01+"'"
	cQuery += " AND DA1.DA1_ESTADO BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'
	cQuery += " AND DA1_CODPRO BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"' "
	cQuery += " ORDER BY DA1_ESTADO, DA1_CODPRO "
	LISTA = U_Qry2Array(cQuery)
    
	oReport:PrintText(nTitulo,,,,,,)
	oReport:PrintText(nLinhaB,,,,,,)
	oReport:PrintText(nLinhaB,,,,,,)
	oReport:PrintText(nCIF,,,,,,)
	oReport:PrintText(nFOB,,,,,,)
	oReport:PrintText("					Para pagamento à vista antecipado: desconto adicional de 3%",,,,,,)
	oReport:PrintText("					* Os valores abaixo não consideram IPI e ST.",,,,,,)
	oReport:PrintText("					Vigência: à partir de 01/04/2014 com validade indeterminada.",,,,,,)
	oReport:PrintText(nLinhaB,,,,,,)
	oReport:PrintText(nLinhaB,,,,,,)
	oReport:PrintText(nLinhaB,,,,,,)

        
	For a:=1 to len(LISTA)
	
		oSection1:Init()
		oSection1:SetHeaderSection(.T.)
		AADD(aLista, {LISTA[a,3], LISTA[a,4],LISTA[a,5],LISTA[a,6],LISTA[a,2]})
		oSection1:Cell("CODPRO"):SetBlock({|| aLista[a, 1]})
		oSection1:Cell("DESC")	:SetBlock({|| aLista[a, 2]})
		oSection1:Cell("VALOR")	:SetBlock({|| aLista[a, 3]})
		oSection1:Cell("VALST")	:SetBlock({|| aLista[a, 4]})
		oSection1:Cell("ESTADO"):SetBlock({|| aLista[a, 5]})
		oSection1:PrintLine()
		
		If oReport:Row() > 2800
			oSection1:Finish()
			oReport:EndPage(.T.)
			oSection1:Init()
			U_CabTReport(oReport,lin1,lin2,lin3,titulo,logo,fonte)
			oReport:PrintText("",350,50)
		Endif
	next
	oSection1:Finish()

	oReport:IncMeter()
Return


//---------------------------------------------------------------------------------------------------------------

Static Function _ValidPerg ()
	local _aRegsPerg := {}

//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                        Help
	aadd (_aRegsPerg, {01, "Tabela		   		  ", "C",  3, 0,  "",    "DA0", {},                           ""})
	aadd (_aRegsPerg, {02, "Frete CIF   	      ", "C", 10, 0,  "",    "", 	{},                           ""})
	aadd (_aRegsPerg, {03, "Frete FOB    	      ", "C", 10, 0,  "",    "", 	{},                           ""})
	aadd (_aRegsPerg, {04, "Regiao           	  ", "C", 30, 0,  "",    "", 	{},                           ""})
	aadd (_aRegsPerg, {05, "Uf de   	          ", "C",  2, 0,  "",    "12", 	{},                           ""})
	aadd (_aRegsPerg, {06, "Uf ate           	  ", "C",  2, 0,  "",    "12", 	{},                           ""})
	aadd (_aRegsPerg, {07, "Produto de   	      ", "C",  6, 0,  "",    "SB1", {},                           ""})
	aadd (_aRegsPerg, {08, "Produto ate           ", "C",  6, 0,  "",    "SB1", {},                           ""})

	U_ValPerg (cPerg, _aRegsPerg)

Return