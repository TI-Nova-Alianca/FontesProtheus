#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maurício C. Dani - TOTVS RS - 15/01/2021
User Function FBTRS106(aRet, lShowMsg, lCompleta)

	Local aArea 		:= GetArea()
//	Local aChaveNfe 	:= {}
	Local aChaveNfe 	:= {sf1 -> f1_chvnfe}
	Local lRetManif		:= .F.
	//Local cIdEnt   		:= U_FBTRS103()
	//Local cURL    		:= PadR(GetNewPar("MV_SPEDURL","http://"), 250)
	Local aMsg 			:= {}
	Local lMsg 			:= .F.

	Default lShowMsg 	:= .T.
	Default lCompleta 	:= .F.

	If lCompleta
		AADD(aMsg, "Deseja enviar a Confirmação da operação via Manifesto?"	)
	EndIf
	AADD(aMsg, "Deseja enviar o Desconhecimento da operação via Manifesto?"	)
	AADD(aMsg, "Deseja enviar a Rejeição da operação via Manifesto?"		)

	If lShowMsg
		lMsg := MsgYesNo(aMsg[aRet[1]])
	Else
		lMsg := .T.
	EndIf
	If lMsg
		If !lCompleta
			aRet[1]++
		EndIf
		U_Log2 ('debug', '[' + procname () + ']Vou chamar U_FBTRS101 passando a seguinte array de chaves:')
		U_Log2 ('debug', aChaveNfe)
		lRetManif := U_FBTRS101(aChaveNfe, aRet[1], aRet[2]) // Faz o manifesto

	Else
		MsgInfo("O status continuará inalterado para este documento!!")
	EndIf

	RestArea(aArea)
Return lRetManif
