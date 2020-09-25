#include "protheus.ch"

// Programa:  MT040VDE
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este ponto de entrada é executado durante a validação da exclusão de um vendedor. 
//            Ele somente será chamado caso as validações do sistema permitam a exclusão do vendedor, 
//            sendo um complemento a elas.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT040VDE()
	local _lRet := .T.
		
	alert("Nenhum registro de vendedor pode ser excluído em função da integração com o software Mercanet.")
	_lRet = .F.

Return _lRet