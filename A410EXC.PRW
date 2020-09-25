#include "protheus.ch"

// Programa:  A410EXC
// Autor:     Suelen - ProcData
// Data:      21/11/2016
// Descricao: Retornar se deve excluir o pedido de vendas. Chamado no programa de exclusão de Pedidos de Venda

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function A410EXC()
	local _lRet := .T.

	if ! empty (M->C5_VAPDMER) 
		U_Help ("Pedido importado do sistema Mercanet. Exclusao nao permitida. Caso necessario, utilize 'eliminacao de residuos'.")
		_lRet = .F.
	endif

Return _lRet