// Programa...: MT103BLQ
// Autor......: Cl�udia Lion�o
// Data.......: 07/01/2020
// Descricao..: Programa chamado no <modo de edi��o> dos campos:
//				D1_VALDESC, D1_DESPESA, D1_VALFRE, D1_SEGURO, n�o permitindo usu�rios n�o autorizados  
//				de alterar o valor.
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MT103BLQ()
	Local cVar   := READVAR() 
	Local lRet   := .T.
	
	
	If ! U_ZZUVL ('095', __cUserId, .F.) 
		lRet := .F.
		u_help("Usu�rio sem permiss�o para alterar o valor do campo!")
	EndIf
	
	If cVar == "M->D1_VALDESC" .and. lRet == .T.
		A103VLDDSC()
	EndIf
Return lRet