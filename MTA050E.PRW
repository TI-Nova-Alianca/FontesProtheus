#include "protheus.ch"

// Programa:  MTA050E
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este ponto de entrada pertence � rotina de manuten��o do cadastro de transportadoras, MATA050(). 
//            Ele permite que o usu�rio valide a exclus�o da transportadora.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MTA050E()
	local _lRet := .T.
		
	u_help ("Nenhum registro de transportadora pode ser exclu�do em fun��o da integra��o com o software Mercanet.",, .t.)
	_lRet = .F.

Return _lRet
