// Programa:   FI290GE5
// Autor:      Andre Alves
// Data:       19/08/2019
// Descricao:  Ponto de entrada executado após a gravação da movimentação bancária (SE5).
//
// Historico de alteracoes:
// 
// 19/08/2019 - Andre  - Gravacao do campo E5_VAUSER.

// --------------------------------------------------------------------------

#include "rwmake.ch"
User Function FI290GE5()

local _aArea    := GetArea()
Local _aAreaSE5 := SE5->(GetArea())
	
	//grava tabela SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif	
	
	RestArea(_aAreaSE5)
	RestArea(_aArea)
	
Return