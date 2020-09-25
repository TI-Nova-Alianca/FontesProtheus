#include "protheus.ch"

// Programa:  MT360DEL
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Ponto de entrada utilizado para validar a exclusão de uma condição de pagamento.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT360DEL()
	local _lRet := .T.
		
	alert("Nenhum registro de condição de pagamento pode ser excluído em função da integração com o software Mercanet.")
	_lRet = .F.

Return _lRet