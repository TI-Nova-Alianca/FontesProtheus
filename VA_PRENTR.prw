//Relatório que mostra quais notas possuem previsão de entrega para o dia e
//quais notas deverão ser entregues nos dias seguintes (23.01.2014)

// Historico de alteracoes:
// 14/07/2014 - Catia - Não estava listando corretamente o intervalo de notas selecionado 
// 09/10/2014 - Catia - na opcao sintetica, trazia apenas as notas com status = 2 (expedida e faturada)
// 14/10/2014 - Catia - na opcao sintetica, desconsiderar as ja entregues
// 21/10/2014 - Catia - relatorio estava trazendo notas ja entregues - tirada opcao analitica
// 11/08/2015 - Catia - retirado da query a opcao que buscava o top1 - pelo que vimos eu e o Robert não esta correto

#include "protheus.ch"
#include "report.ch"
#include "topconn.ch"
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"
#include "rwmake.ch"

User Function VA_PRENTR()

Local oReport
//Local oSection1
//Local oBreak
//Local _nLin 	:= 0
private cPerg 	:= "VA_PRENTR"

_ValidPerg ()
If TRepInUse()
	Pergunte("VA_PRENTR",.T.)
	oReport := ReportDef()
	oReport:PrintDialog()
EndIf
Return

Static Function ReportDef()
Local oReport
Local oSection1
Local oBreak
Local cTitulo := "Previsão de entrega das notas emitidas de " +CVALTOCHAR(mv_par01)+ " até " +CVALTOCHAR(mv_par02)
cTitulo := cTitulo //+' - '+iif(mv_par09==1,"Analítico","Sintético")
oReport := TReport():New("VA_PRENTR",cTitulo,"VA_PRENTR",{|oReport| PrintReport(oReport)},"Relatório de previsão de entrega NFS")
oReport:SetTotalInLine(.F.)
oReport:SetLandScape()//LandScape()
oReport:SetTotalInLine(.T.)

oSection1 := TRSection():New(oReport,"Notas",{"SZN"})

TRCell():New(oSection1,"FILIAL"			,"","Filial",      	/*Picture*/    ,04,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"DATA"			,"","Data",     	/*Picture*/    ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"USUARIO"		,"","Usuário",     	/*Picture*/    ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"NOTA_FISCAL"	,"","NFS", 			/*Picture*/    ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"SERIES"			,"","Serie",		/*Picture*/    ,05,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"PED_VENDA"		,"","Transp.",		/*Picture*/	   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"TEXTO"			,"","Texto",	 	/*Picture*/    ,50,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"CLIENTE"		,""	,"Cód.Cliente",	/*Picture*/    ,08,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"LOJA_CLIENTE"	,"","Lj.Cli.",		/*Picture*/    ,05,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"NOME_CLIENTE"	,"","Nome CLiente",	/*Picture*/    ,25,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"CIDADE_CLIENTE"	,"","Cidade",		/*Picture*/    ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"UF_CLIENTE"		,"","UF",	 		/*Picture*/    ,03,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"STATUS"			,"","Status",	 	/*Picture*/    ,35,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"SUBSTS"			,"","Substatus", 	/*Picture*/    ,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
TRCell():New(oSection1,"PREV_ENTREGA"	,"","Prev.Entr.",	/*Picture*/    ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)

oBreak := TRBreak():New(oSection1,oSection1:Cell("PREV_ENTREGA"),,.F.)

Return oReport

Static Function PrintReport(oReport)
local _nLin		:= 0
private _sQuery := ""
private _aDados := {}

oSection1 := oReport:Section(1)

_sQuery := "SELECT SZN.ZN_FILIAL"
_sQuery += "     , SZN.ZN_DATA"
_sQuery += "     , SZN.ZN_USUARIO"
_sQuery += "     , SZN.ZN_NFS"
_sQuery += "     , SZN.ZN_SERIES"
_sQuery += "     , SZN.ZN_PEDVEND" 
_sQuery += "     , SZN.ZN_TEXTO" 
_sQuery += "     , SZN.ZN_CLIENTE"
_sQuery += "     , SZN.ZN_LOJACLI"
_sQuery += "     , SA1.A1_NREDUZ"
_sQuery += "     , SA1.A1_MUN"
_sQuery += "     , SA1.A1_EST"
_sQuery += "     , SZN.ZN_STATUS"
_sQuery += "     , SZN.ZN_SUBSTS"
_sQuery += "     , SX5.X5_DESCRI"
_sQuery += "  FROM " + RetSQLName ("SZN") + " AS SZN"
_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
_sQuery += "        ON (SA1.D_E_L_E_T_ = ''" 
_sQuery += "            AND SA1.A1_COD     = SZN.ZN_CLIENTE"
_sQuery += "            AND SA1.A1_LOJA    = SZN.ZN_LOJACLI)" 
_sQuery += " INNER JOIN " + RetSQLName ("SX5") + " AS SX5"
_sQuery += "        ON (SX5.D_E_L_E_T_ = ''" 
_sQuery += "            AND SX5.X5_TABELA  = 'ZT'"
_sQuery += "            AND SX5.X5_CHAVE   = SZN.ZN_STATUS)" 
_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " AS SF2"
_sQuery += "        ON (SF2.D_E_L_E_T_ = ''"
_sQuery += "            AND SF2.F2_CLIENTE = SZN.ZN_CLIENTE"
_sQuery += "            AND SF2.F2_LOJA    = SZN.ZN_LOJACLI"
_sQuery += "            AND SF2.F2_DOC     = SZN.ZN_NFS"
_sQuery += "            AND SF2.F2_SERIE   = SZN.ZN_SERIES"
_sQuery += "            AND SF2.F2_EMISSAO BETWEEN '" + DtoS(mv_par01) + "' AND '" + DtoS(mv_par02) + "' )"
_sQuery += " WHERE SZN.D_E_L_E_T_ = ' '"
_sQuery += "   AND SZN.ZN_FILIAL  = '" + xFilial("SZN") + "' "
_sQuery += "   AND SZN.ZN_NFS     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
_sQuery += "   AND SZN.ZN_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
_sQuery += "   AND SA1.A1_EST     BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
_sQuery += "   AND SZN.ZN_NFS     <> ''"
_sQuery += "   AND SZN.ZN_HISTNF  = '1'"
_sQuery += "   AND NOT EXISTS (SELECT SZN.ZN_FILIAL"
_sQuery += "                     FROM SZN010 AS SZN1"
_sQuery += "                     WHERE SZN1.ZN_FILIAL  = SZN.ZN_FILIAL"
_sQuery += "                       AND SZN1.ZN_NFS     = SZN.ZN_NFS"
_sQuery += "                       AND SZN1.ZN_SERIES  = SZN.ZN_SERIES"
_sQuery += "                       AND SZN1.ZN_CLIENTE = SZN.ZN_CLIENTE"
_sQuery += "                       AND SZN1.ZN_LOJACLI = SZN.ZN_LOJACLI"
_sQuery += "                       AND SZN1.ZN_STATUS IN ( '4','5','6','7','8','9','10','11','12'))"
/*
_sQuery += "   AND SZN.R_E_C_N_O_ = (SELECT TOP 1 R_E_C_N_O_"
_sQuery += "                           FROM SZN010 AS ULT"
_sQuery += "                          WHERE ULT.ZN_FILIAL  = SZN.ZN_FILIAL"
_sQuery += "                            AND ULT.ZN_DATA    = SZN.ZN_DATA"
_sQuery += "                            AND ULT.ZN_NFS     = SZN.ZN_NFS"
_sQuery += "                            AND ULT.ZN_SERIES  = SZN.ZN_SERIES"
_sQuery += "                            AND ULT.ZN_CLIENTE = SZN.ZN_CLIENTE"
_sQuery += "                            AND ULT.ZN_LOJACLI = SZN.ZN_LOJACLI)"
*/
_sQuery += "ORDER BY SZN.ZN_NFS, SA1.A1_EST, SA1.A1_MUN "

//u_showmemo(_sQuery)

_aDados := U_Qry2Array (_sQuery)

//Monta arquivo de trabalho que vai receber os resutados do Select
aCampos := {}

aTam:=TamSX3("ZN_FILIAL")
AADD(aCampos,{"FILIAL" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("ZN_DATA")
AADD(aCampos,{"DT_REF" ,"D",aTam[1],aTam[2]})
AADD(aCampos,{"USUARIO" ,"C",15,0})
aTam:=TamSX3("ZN_NFS")
AADD(aCampos,{"NFS" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("ZN_SERIES")
AADD(aCampos,{"SERIES" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("ZN_PEDVEND")
AADD(aCampos,{"PEDVEND" ,"C",20,0})
aTam:=TamSX3("ZN_TEXTO")
AADD(aCampos,{"TEXTO" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("ZN_CLIENTE")
AADD(aCampos,{"CLIENTE" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("ZN_LOJACLI")
AADD(aCampos,{"LOJA_CLI" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("A1_NREDUZ")
AADD(aCampos,{"NOME_CLI" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("A1_MUN")
AADD(aCampos,{"CID_CLI" ,"C",aTam[1],aTam[2]})
aTam:=TamSX3("A1_EST")
AADD(aCampos,{"UF_CLI" ,"C",aTam[1],aTam[2]})
AADD(aCampos,{"_STATUS" ,"C",30,0})
AADD(aCampos,{"SUBSTS" ,"C",30,0})
aTam:=TamSX3("ZN_DATA")
AADD(aCampos,{"DT_PREV" ,"D",aTam[1],aTam[2]})

cArqTrab := CriaTrab(aCampos,.T.)
DbUseArea(.T.,__LocalDriver,cArqTrab,"TRB",.F.,.F.) // Abre o Arquivo

cArqTra1:=Substr(cArqTrab,1,7)+"1"

DbSelectArea("TRB")

Index on DTOS(DT_PREV)+UF_CLI+CID_CLI to &cArqTrab

//Joga os resutados so select no TRB para depois aplicar o indice
If Len (_aDados) > 0
	for _nLin = 1 to len (_aDados)
	
			_sStatus :=	_aDados[_nLin,13]
			_sStatus2 := _aDados[_nLin,15]
			_sSubsTs :=	_aDados[_nLin,14]
			_sSubsTs2 := IIF(empty(_aDados[_nLin,14]),"",Posicione("SX5",1 ,xFilial("SX5")+"ZU"+alltrim(_sSubsTs),"X5_DESCRI"))
			_sUF := Alltrim(_aDados[_nLin,12])
			_dDtEnt := _aDados[_nLin,2]
			_sPrazo := Val(Posicione("SX5",1 ,xFilial("SX5")+"ZV"+alltrim(_sUF),"X5_DESCRI"))
			_dPrev := SomaDiaUt(_dDtEnt,_sPrazo)
			
			RecLock("TRB",.T.)
				
			TRB->FILIAL := _aDados[_nLin,1]
			TRB->DT_REF := _aDados[_nLin,2]
			TRB->USUARIO := _aDados[_nLin,3]
			TRB->NFS := _aDados[_nLin,4]
			TRB->SERIES := _aDados[_nLin,5]
				
			_transp := alltrim(Posicione("SF2",1,xFilial("SF2") + _aDados[_nLin,4] + _aDados[_nLin,5], "F2_TRANSP"))
			TRB->PEDVEND := alltrim(Posicione("SA4",1,xFilial("SA4") + _transp, "A4_NREDUZ"))  //_aDados[_nLin,6]   
				
			TRB->TEXTO := _aDados[_nLin,7]
			TRB->CLIENTE := _aDados[_nLin,8]
			TRB->LOJA_CLI := _aDados[_nLin,9]
			TRB->NOME_CLI := _aDados[_nLin,10]
			TRB->CID_CLI := _aDados[_nLin,11]
			TRB->UF_CLI := _aDados[_nLin,12]
			TRB->_STATUS := _sStatus2
			TRB->SUBSTS := _sSubsTs2
			TRB->DT_PREV := _dPrev
			
			MsUnLock()
	
	next _nLin
	
EndIf

// Joga os valores na ordem correta para dentro relatório
DbSelectArea("TRB")
DBGOTOP()
oReport:SetMeter(TRB->(RECCOUNT()))
For _nLin = 1 to TRB->(RECCOUNT())
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	If oReport:Cancel()
		MsgAlert("Operação interrompida pelo usuário.")
		Exit
	EndIf
	
	oSection1:Cell("FILIAL")		:SetBlock({|| FILIAL})
	oSection1:Cell("DATA")			:SetBlock({|| DT_REF})
	oSection1:Cell("USUARIO") 		:SetBlock({|| USUARIO})
	oSection1:Cell("NOTA_FISCAL") 	:SetBlock({|| NFS})
	oSection1:Cell("SERIES")        :SetBlock({|| SERIES})
	oSection1:Cell("PED_VENDA") 	:SetBlock({|| PEDVEND})
	oSection1:Cell("TEXTO") 		:SetBlock({|| TEXTO})
	oSection1:Cell("CLIENTE") 	 	:SetBlock({|| CLIENTE})
	oSection1:Cell("LOJA_CLIENTE")  :SetBlock({|| LOJA_CLI})
	oSection1:Cell("NOME_CLIENTE")  :SetBlock({|| NOME_CLI})
	oSection1:Cell("CIDADE_CLIENTE"):SetBlock({|| CID_CLI})
	oSection1:Cell("UF_CLIENTE")    :SetBlock({|| UF_CLI})
	oSection1:Cell("STATUS")    	:SetBlock({|| _STATUS})
	oSection1:Cell("SUBSTS")    	:SetBlock({|| SUBSTS})
	oSection1:Cell("PREV_ENTREGA")  :SetBlock({|| DT_PREV})
	
	oSection1:PrintLine()
	oReport:IncMeter()
	
	DbSelectArea("TRB")
	DbSkip()
Next
oSection1:Finish()
DbSelectArea("TRB")
dbCloseArea()

Return


Static Function SomaDiaUt (_dDataIni, _nDias)
local _i         := 0
local _dNovaData := _dDataIni
//local _dDataAux  := ctod ("")

if valtype (_nDias) != "N"
	msgbox ("Metodo SomaDiaUt recebeu parametro(s) invalido(s)" +_nDias)
	return NIL
endif
if valtype (_dDataIni) != "D"
	msgbox ("Metodo SomaDiaUt recebeu parametro(s) invalido(s) "+_dDataIni)
	return NIL
endif

for _i = 1 to abs (_nDias)
	if _nDias > 0  // Somar dias
		_dNovaData = datavalida (_dNovaData + 1)
	else  // Subtrair dias
		_dNovaData --
		do while datavalida (_dNovaData) != _dNovaData
			_dNovaData --
		enddo
	endif
next
return _dNovaData

Static Function _ValidPerg ()
local _aRegsPerg := {}

//                     PERGUNT                TIPO TAM DEC VALID  F3    Opcoes                        Help
aadd (_aRegsPerg, {01, "Data Emissao de  ?",  "D", 08, 0,  "",   "   ", {},                           ""})
aadd (_aRegsPerg, {02, "Data Emissao até ?", "D", 08, 0,  "",   "   ", {},                           ""})
aadd (_aRegsPerg, {03, "Nota de	?",           "C", 09, 0,  "",   "SZN", {},                           ""})
aadd (_aRegsPerg, {04, "Nota até ?",          "C", 09, 0,  "",   "SZN", {},                           ""})
aadd (_aRegsPerg, {05, "Cliente de  ?", 	  "C", 06, 0,  "",   "SA1", {},                           ""})
aadd (_aRegsPerg, {06, "Cliente ate ?", 	  "C", 06, 0,  "",   "SA1", {},                        	  ""})
aadd (_aRegsPerg, {07, "UF de ?", 	 		  "C", 02, 0,  "",   "12 ", {},                        	  ""})
aadd (_aRegsPerg, {08, "UF até ?", 			  "C", 02, 0,  "",   "12 ", {},                        	  ""})
//aadd (_aRegsPerg, {09, "Analitico/Sintetico?","N", 01, 0,  "",   "   ", {"Analitico","Sintetico"},	  ""})

U_ValPerg (cPerg, _aRegsPerg)
Return
