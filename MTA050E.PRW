#include "protheus.ch"

// Programa:  MTA050E
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este ponto de entrada pertence à rotina de manutenção do cadastro de transportadoras, MATA050(). 
//            Ele permite que o usuário valide a exclusão da transportadora.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MTA050E()
	local _lRet := .T.
		
	alert("Nenhum registro de transportadora pode ser excluído em função da integração com o software Mercanet.")
	_lRet = .F.

Return _lRet