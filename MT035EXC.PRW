#include "protheus.ch"

// Programa:  MT035EXC
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este Ponto de Entrada está localizado na função Mata035Ex (validação de exclusão do Grupo de Produtos)
//            Só será executado APÓS a confirmação da exclusão e a sua finalidade é validar ou não a exclusão do grupo de produtos.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT035EXC()
	local _lRet := .T.
		
	alert("Nenhum registro de grupo de produto pode ser excluído em função da integração com o software Mercanet.")
	_lRet = .F.

Return _lRet