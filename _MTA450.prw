// Programa...: _MTA450
// Autor......: Robert Koch
// Data.......: 01/12/2015
// Descricao..: Valida usuario e chama tela padrao MATA450 (an.credito ped.venda)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function _MTA450 ()
 
	if u_zzuvl ('055', __cUserId, .T.)
		MATA450 ()
	endif

return