#include "protheus.ch"

// Programa:  MT035EXC
// Autor:     ProcData
// Data:      18/11/2016
// Descricao: Este Ponto de Entrada est� localizado na fun��o Mata035Ex (valida��o de exclus�o do Grupo de Produtos)
//            S� ser� executado AP�S a confirma��o da exclus�o e a sua finalidade � validar ou n�o a exclus�o do grupo de produtos.
//            Criado inicialmente para compatibilidade com sistema Mercanet.

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function MT035EXC()
	local _lRet := .T.
		
	u_help ("Nenhum registro de grupo de produto pode ser exclu�do em fun��o da integra��o com o software Mercanet.",, .t.)
	_lRet = .F.

Return _lRet
