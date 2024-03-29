#include "protheus.ch"

// Programa:  MT040VDE
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este ponto de entrada � executado durante a valida��o da exclus�o de um vendedor. 
//            Ele somente ser� chamado caso as valida��es do sistema permitam a exclus�o do vendedor, 
//            sendo um complemento a elas.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT040VDE()
	local _lRet := .T.
		
	u_help ("Nenhum registro de vendedor pode ser exclu�do em fun��o da integra��o com o software Mercanet.",, .t.)
	_lRet = .F.

Return _lRet
