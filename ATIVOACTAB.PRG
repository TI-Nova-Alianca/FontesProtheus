// Programa...: ATIVOACTAB
// Autor......: Catia Cardoso
// Data.......: 15/05/2017
// Descricao..: acerta tabelas do ativo quando cai o processo no meio de um calculo ou descalculo  
//
// Historico de alteracoes:
//

#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ATIVOACTAB()

	_lRet = U_MsgNoYes ("Confirma verificação arquivos de saldos do Ativo na filial atual ?")
	
	if _lRet = .F.
		return
	else
    	_wULTDEPR = GetMv ("MV_ULTDEPR")
    	
    	// DELETE REGISTROS QUE "SOBRARAM" NO CALCULO OU DESCALCULO E POR ISSO FICA DANDO A MENSAGEM
		_sSQL := " "
		_sSQL += " DELETE SN4010"
 		_sSQL += "  WHERE D_E_L_E_T_ = ''"
   		_sSQL += "    AND N4_FILIAL  = '"  + xfilial ("SN4")+ "'"
   		_sSQL += "    AND N4_DATA    > '" + dtos(_wULTDEPR) + "'"
   		if TCSQLExec (_sSQL) < 0
   			msgalert ("Erro ao executar UPDATE. Comunique a TI")
            return
       	endif
       	  
       	_sSQL := " "
		_sSQL += " DELETE SN5010"
 		_sSQL += "  WHERE D_E_L_E_T_ = ''"
   		_sSQL += "    AND N5_FILIAL  = '"  + xfilial ("SN5") + "'"
   		_sSQL += "    AND N5_DATA    > '" + dtos(_wULTDEPR) + "'"
   		if TCSQLExec (_sSQL) < 0
   			msgalert ("Erro ao executar UPDATE. Comunique a TI")
			return
       	endif  
	endif
		 								
return