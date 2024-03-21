// Programa:  FBTRS101
// Autor:     Mauricio Dani - TRS
// Data:      15/01/2021
// Descricao: Monta XML de eventos (ciencia/desconhecimento/etc.) de operacao para a SEFAZ.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Interface
// #Descricao         #Monta XML de eventos (ciencia/desconhecimento/etc.) de operacao para a SEFAZ.
// #PalavasChave      #XML NFe SEFAZ evento operacao
// #TabelasPrincipais #SF1
// #Modulos           #COM #EST

// Historico de alteracoes:
// 02/08/2022 - Robert - Gravacao evento(interno do Protheus) ao final da operacao (GLPI 12418)
//

#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maurício C. Dani - TOTVS RS - 15/01/2021
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
	Local _nN           := 0
	Local aJust 		:= {}
	Local cDescEvent	:= ''
	local _oEvento      := NIL
	Private oWs			:= NIL

	Default	cJustific 	:= ""

//	U_Log2 ('debug', '[' + procname () + ']Chaves recebidas:')
//	U_Log2 ('debug', aChaves)

	AADD(aItensCb, '210200') // Confirmação da Operação
	AADD(aItensCb, '210220') // Desconhecimento da Operação
	AADD(aItensCb, '210240') // Operação não Realizada
	AADD(aItensCb, '210210') // Ciência da Operação
	
	oWs := WSMANIFESTACAODESTINATARIO():New()

	oWs:cUserToken   := "TOTVS"
	oWs:cIDENT	     := cIdEnt
	oWs:cAMBIENTE	 := ""
	oWs:cVERSAO      := ""
	oWs:_URL         := AllTrim(cURL)+"/MANIFESTACAODESTINATARIO.apw"
		
	If oWs:CONFIGURARPARAMETROS()
//		U_Log2 ('debug', '[' + procname () + '] oWs:CONFIGURARPARAMETROS = .t.')
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

//		U_Log2 ('debug', '[' + procname () + '] cXML = ' + cXml)

		If Empty(cChavesMsg)
			Return
		EndIf
		cChavesMsg := ""
		lRetOk := U_FBTRS104(cXml,cIdEnt,cUrl,@aRet)
//		U_Log2 ('debug', '[' + procname () + '] retorno do U_FBTRS104 = ' + cvaltochar (lRetOk))
//		U_Log2 ('debug', '[' + procname () + '] aRet:')
//		U_Log2 ('debug', aRet)

		If lRetOk .And. Len(aRet) > 0

			If aItensCb[nTpEvento] 		== '210200'
				cDescEvent := ' - Confirmação da operação'
			ElseIf aItensCb[nTpEvento] 	== '210210'
				cDescEvent := ' - Ciência da operação'
			ElseIf aItensCb[nTpEvento] 	== '210220'
				cDescEvent := ' - Desconhecimento da operação'
			ElseIf aItensCb[nTpEvento] 	== '210240'
				cDescEvent := ' - Operação não realizada'
			EndIf

			For nZ:=1 to Len(aRet)
				aRet[nZ] := Substr(aRet[nZ],9,44)
				cChavesMsg += aRet[nZ] + Chr(10) + Chr(13)

				// Grava evento temporario para posterior rastreamento da chave da nota.
				_oEvento := ClsEvent ():New ()
				_oEvento:CodEven   = "ZZX002"
				_oEvento:Texto     = "Enviado evento '" + aItensCb[nTpEvento] + cDescEvent + "' para a SEFAZ."
				_oEvento:ChaveNFe  = aRet[nZ]
				_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
				_oEvento:Grava ()

			Next

			cMsgManif := "Manifestação transmitida com sucesso!" + Chr(10) + Chr(13)
			cMsgManif += aItensCb[nTpEvento] + cDescEvent + Chr(10) + Chr(13)
			cMsgManif += "Chave(s): " + Chr(10) + Chr(13)
			cMsgManif += cChavesMsg
						
			cRetorno := Alltrim(cMsgManif)
//			U_Log2 ('debug', '[' + procname () + '] cRetorno = ' + cRetorno)
		EndIf
	Else
		Aviso("SPED", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"OK"}, 3)
	EndIF
	
	If !Empty(cRetorno)
		MsgAlert(cRetorno)
	Else
		MsgAlert('Não foi possível transmitir o manifesto, verifique os eventos associados ao documento no Sefaz.')
	EndIf
	
Return lRetOk
