#include "rwmake.ch"

// Programa:   F300SE5
// Autor:      Andre Alves
// Data:       06/02/2019
// Descricao:  P.E. após a gravação do registro referente a movimentação bancaria de baixa via retorno SISPAG.
//
// Historico de alteracoes:
// 06/02/2019 - Andre - Gravacao do usuário após a gravação do registro referente a movimentação bancaria de baixa via retorno SISPAG.
//

// --------------------------------------------------------------------------

User Function F300SE5()

local _aArea     := GetArea()
Local _aAreaSE5  := SE5->(GetArea())

DbSelectArea("SE5")
	
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER  := alltrim(cUserName)
		MsUnlock()
	endif
	
DbSelectArea("SE5")
DbSkip()

RestArea(_aAreaSE5)
RestArea(_aArea)
Return