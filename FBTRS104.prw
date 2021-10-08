#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maurício C. Dani - TOTVS RS - 15/01/2021
User Function FBTRS104(cXmlReceb,cIdEnt,cUrl,aRetorno,cModel)

	Local lRetOk		:= .T.

	Default cURL		:= GetMV("MV_SPEDURL")
	Default cIdEnt		:= U_FBTRS103()
	Default aRetorno	:= {}
	Default cModel		:= ""
	
		oWs:= WsNFeSBra():New()
		oWs:cUserToken	:= "TOTVS"
		oWs:cID_ENT		:= cIdEnt
		oWs:cXML_LOTE	:= cXmlReceb
		oWS:_URL		:= AllTrim(cURL)+"/NFeSBRA.apw"
		
		If !Empty(cModel)
			oWS:cModelo := cModel
		EndIf
		
		If oWs:RemessaEvento()
			U_Log2 ('debug', '[' + procname () + '] oWs:RemessaEvento() = .t.')
			If Type("oWS:oWsRemessaEventoResult:cString") <> "U"
				If Type("oWS:oWsRemessaEventoResult:cString") <> "A"
					aRetorno:={oWS:oWsRemessaEventoResult:cString}
				Else
					aRetorno:=oWS:oWsRemessaEventoResult:cString
				EndIf
			EndIf
		Else
			lRetOk := .F.
			Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
		Endif
	 
Return lRetOk
