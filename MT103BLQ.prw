// Programa...: MT103BLQ
// Autor......: Cláudia Lionço
// Data.......: 07/01/2020
// Descricao..: Programa chamado no <modo de edição> dos campos:
//				D1_VALDESC, D1_DESPESA, D1_VALFRE, D1_SEGURO, não permitindo usuários não autorizados  
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
		u_help("Usuário sem permissão para alterar o valor do campo!")
	EndIf
	
	If cVar == "M->D1_VALDESC" .and. lRet == .T.
		A103VLDDSC()
	EndIf
Return lRet