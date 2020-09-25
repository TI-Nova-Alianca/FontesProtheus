// Programa:   A410BPrc
// Autor:      Robert Koch
// Data:       10/06/2010
// Cliente:    Alianca
// Descricao:  P.E. que permite bloquear o acesso ao botao de formacao de precos na tela de pedidos de venda.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function A410BPRC ()
	local _lRet := .T.
	if type ("_sCodRep") == "C"  // Representantes externos nao visualizam este botao.
		_lRet = .F.
	endif
return _lRet
