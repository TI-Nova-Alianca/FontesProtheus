// Programa...: VA_ZAE
// Autor......: Catia Cardoso
// Data.......: 19/04/2016
// Descricao..: Parametros de Comissao de Coordenadores / Externos
//
// ------------------------------------------------------------------------------------
//
// Historico de alteracoes:
//
#include "rwmake.ch"
User Function VA_ZAE()
	
	if ! u_zzuvl ('067', __cUserId, .T.)
		return
	endif
	
	AxCadastro("ZAE","Comissões Específicas",".T.",".T.")
Return
