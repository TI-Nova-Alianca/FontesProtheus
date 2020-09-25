// Programa:   MT220GRV
// Autor:      Robert Koch
// Data:       30/07/2019
// Descricao:  P.E. apos inclusao de saldos iniciais (tabela SB9)
//             Criado inicialmente para gravar evento para historico de movimentacoes.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MT220GRV ()
	local _oEvento  := NIL
	_oEvento := ClsEvent():new ()
	_oEvento:Produto = sb9 -> b9_cod
	_oEvento:Texto   = "Inclusao de saldo inicial AX '" + sb9 -> b9_local + "' Qt = " + cvaltochar (sb9 -> b9_qini) + " Vlr = " + cvaltochar (sb9 -> b9_vini1)
	_oEvento:Grava ()
return
