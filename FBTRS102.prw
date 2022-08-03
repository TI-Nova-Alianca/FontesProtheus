#Include "RwMake.ch" 
#Include "Protheus.ch"
#Include "TBICoNN.ch"
#Include "FILEIo.ch"
#Include "TopCoNN.ch"
#Include 'Totvs.ch'
#Include "Ap5Mail.ch"
#INCLUDE "COLORS.CH"

//Criado por Maurício C. Dani - TOTVS RS - 15/01/2021
User Function FBTRS102(lCompleta)
	Local aStatus 	:= {}
	Local aPerg  	:= {}
	Local _aRet 	:= {}
	Local lRet 		:= .F.

	Private _lAuto		:= .F.
	Private _CCGCSM0 	:= Nil

	Default lCompleta := .F.

	If lCompleta
		AADD(aStatus, 'Confirmação da operação')
	EndIf

	AADD(aStatus, 'Desconhecimento da operação')
	AADD(aStatus, 'Operação não realizada')
	AADD(aStatus, 'Não informar status definitivo para este documento')

	AADD(aPerg, {03, 'Informe Status'	, 1  	, aStatus	, 150	, '.T.', .T., '.T.' } )
	AADD(aPerg, {09, ''					, 50  	, 20		, .F.						} )
	AADD(aPerg, {11, 'Justificativa' 	, ''	, '.T.' 	, '.T.'	, .F.				} )

	If Parambox(aPerg, "Manifesto do Destinatário", @_aRet, , , , , , , , .T.)
		If (_aRet[1] == 3 .And. !lCompleta) .Or. (_aRet[1] == 4 .And. lCompleta)
			lRet := .T.
			MsgInfo("O status continuará inalterado para este documento!!")			
		Else
			If ((_aRet[1] == 2 .And. !lCompleta) .Or. (_aRet[1] == 3 .And. lCompleta)) .And. (Empty(AllTrim(_aRet[3])))
				MsgInfo('Como se trata de uma rejeição, o preenchimento do campo Justificativa é obrigatório!')
				Return .F.
			EndIf
			U_Log2 ('debug', '[' + procname () + ']Vou chamar U_FBTRS106')
			lRet := U_FBTRS106({_aRet[1], _aRet[3]}, .T., lCompleta)
		EndIf
	Else
		MsgInfo("O status continuará inalterado para este documento!")
	EndIf
Return lRet
