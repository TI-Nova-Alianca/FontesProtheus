// Programa...: _MTA450A
// Autor......: Robert Koch
// Data.......: 01/12/2015
// Descricao..: Valida usuario e chama tela padrao MATA450A (an.credito cliente)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function _MTA450A ()
 
	if u_zzuvl ('055', __cUserId, .T.)
		MATA450A ()
	endif

return