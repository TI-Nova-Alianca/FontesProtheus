#include "rwmake.ch"

// Programa:   F430BXA
// Autor:      Andre Alves
// Data:       20/02/2019
// Descricao:  P.E. tem como finalidade gravar complemento das baixas CNAB a pagar do retorno bancario.
//
// Historico de alteracoes:
// 20/02/2019 - Andre - Gravacao do usuário no retorno dos pagamentos CNAB.
//

// --------------------------------------------------------------------------

User Function F430BXA()

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