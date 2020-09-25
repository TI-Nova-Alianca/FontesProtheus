// Programa...: MT103LCF
// Autor......: Cláudia Lionço
// Data.......: 06/01/2020
// Descricao..: P.E. permite que os campos: Descontos, Vlr.Frete, Vlr.Despesas, Vlr.Seguro da Aba: Descontos / Fretes / Despesas, 
//				sejam bloqueados a fim de que não se possa incluir informações no momento da inclusão de um Documento de Entrada.
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MT103LCF()
	Local cCampo := UPPER(PARAMIXB[1]) 
	Local lRet   := .T.
	
	If ! U_ZZUVL ('095', __cUserId, .F.) 
			
		Do Case	
			Case cCampo == "F1_DESCONT"	     
				lRet = .F.	
			Case cCampo == "F1_FRETE"	     
				lRet = .F.	
			Case cCampo == "F1_DESPESA"	     
				lRet = .F.	
			Case cCampo == "F1_SEGURO"	     
				lRet = .F.
		EndCase 
		
	Endif
	
Return (lRet)