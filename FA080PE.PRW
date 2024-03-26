// Programa:   FA080PE
// Autor:      Andre Alves
// Data:       16/08/2019
// Descricao:  O ponto de entrada FA080PE sera executado na saida da funcao de baixa, apos gravar todos os dados e após a contabilização.
//
// Historico de alteracoes:
// 
// 16/09/2019 - Andre  - Gravacao do campo E5_VAUSER.

// --------------------------------------------------------------------------

#include "rwmake.ch"
User Function FA080PE()

	if empty (se5 -> e5_vaUser)
		RECLOCK("SE5",.F.)
		SE5->E5_VAUSER  := alltrim(cUserName)
		MsUnlock()
	endif
	
Return()

