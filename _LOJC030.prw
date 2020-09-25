// Programa:  _LOJC030
// Autor:     Catia Cardoso	
// Data:      01/11/2018
// Descricao: Acessos para Listagem de caixa
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
USER FUNCTION _LOJC030 ()

	if ! u_zzuvl ('087', __cUserId, .T.)
		return
	else
		// Chama tela de pedidos padrao.
		LOJC030 ()
	endif
	
Return