#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maur�cio C. Dani - TOTVS RS - 15/01/2021
User Function FBTRS101(aChaves, nTpEvento, cJustific)
	Local cXml 			:= ""
	Local cAmbiente 	:= ""
	Local aRet			:= {}
	Local cIdEnt 		:= U_FBTRS103()
	Local cURL			:= GetMV("MV_SPEDURL")
	Local cChavesMsg	:= ""
	Local cMsgManif		:= ""
	Local aItensCb      := {}
	Local lRetOk		:= .F.
	Local cRetorno		:= ""
	Local nX 			:= 0
	Local nZ 			:= 0
	Local aJust 		:= {}
	Local cDescEvent	:= ''
	Private oWs			:= NIL

	Default	cJustific 	:= ""

	AADD(aItensCb, '210200') // Confirma��o da Opera��o
	AADD(aItensCb, '210220') // Desconhecimento da Opera��o
	AADD(aItensCb, '210240') // Opera��o n�o Realizada
	AADD(aItensCb, '210210') // Ci�ncia da Opera��o
	
	oWs := WSMANIFESTACAODESTINATARIO():New()

	oWs:cUserToken   := "TOTVS"
	oWs:cIDENT	     := cIdEnt
	oWs:cAMBIENTE	 := ""
	oWs:cVERSAO      := ""
	oWs:_URL         := AllTrim(cURL)+"/MANIFESTACAODESTINATARIO.apw"
		
	If oWs:CONFIGURARPARAMETROS()
		cAmbiente := oWs:OWSCONFIGURARPARAMETROSRESULT:CAMBIENTE
		
		cXml+='<envEvento>'
		cXml+='<eventos>'
		
		For nX := 1 To Len(aChaves)
				cXml+='<detEvento>'
				cXml+='<tpEvento>' + aItensCb[nTpEvento] + '</tpEvento>'
				cXml+='<chNFe>'+Alltrim(aChaves[nX])+'</chNFe>'
				cXml+='<ambiente>'+cAmbiente+'</ambiente>'
	
				If '210240' $ aItensCb[nTpEvento] .and. !Empty(cJustific)
					aJust := StrToKarr(cJustific, Chr(10) + Chr(13))
					If Len(aJust) > 0
						cJustific := ''
						For _nN := 1 To Len(aJust)
							cJustific += aJust[_nN] + " "
						Next
					EndIf
					cXml+='<xJust>'+Alltrim(cJustific)+'</xJust>'
				EndIf
		
				cXml+='</detEvento>'
				cChavesMsg += aChaves[nX] + Chr(10) + Chr(13)
		Next

		cXml+='</eventos>'
		cXml+='</envEvento>'

		If Empty(cChavesMsg)
			Return
		EndIf
		cChavesMsg := ""
		lRetOk := U_FBTRS104(cXml,cIdEnt,cUrl,@aRet)

		If lRetOk .And. Len(aRet) > 0
			For nZ:=1 to Len(aRet)
				aRet[nZ] := Substr(aRet[nZ],9,44)
				cChavesMsg += aRet[nZ] + Chr(10) + Chr(13)
			Next

			If aItensCb[nTpEvento] 		== '210200'
				cDescEvent := ' - Confirma��o da opera��o'
			ElseIf aItensCb[nTpEvento] 	== '210210'
				cDescEvent := ' - Ci�ncia da opera��o'
			ElseIf aItensCb[nTpEvento] 	== '210220'
				cDescEvent := ' - Desconhecimento da opera��o'
			ElseIf aItensCb[nTpEvento] 	== '210240'
				cDescEvent := ' - Opera��o n�o realizada'
			EndIf

			cMsgManif := "Manifesta��o transmitida com sucesso!" + Chr(10) + Chr(13)
			cMsgManif += aItensCb[nTpEvento] + cDescEvent + Chr(10) + Chr(13)
			cMsgManif += "Chave(s): " + Chr(10) + Chr(13)
			cMsgManif += cChavesMsg
						
			cRetorno := Alltrim(cMsgManif)
						
		EndIf
	Else
		Aviso("SPED", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"OK"}, 3)
	EndIF
	
	If !Empty(cRetorno)
		MsgAlert(cRetorno)
	Else
		MsgAlert('N�o foi poss�vel transmitir o manifesto, verifique os eventos associados ao documento no Sefaz.')
	EndIf
	
Return lRetOk