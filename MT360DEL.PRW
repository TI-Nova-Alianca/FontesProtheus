#include "protheus.ch"

// Programa:  MT360DEL
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Ponto de entrada utilizado para validar a exclus�o de uma condi��o de pagamento.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT360DEL()
	local _lRet := .T.
		
	u_help ("Nenhum registro de condi��o de pagamento pode ser exclu�do em fun��o da integra��o com o software Mercanet.",, .t.)
	_lRet = .F.

Return _lRet
