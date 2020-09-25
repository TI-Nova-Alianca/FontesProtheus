// Programa:   MTA450I
// Autor:      Robert Koch
// Data:       04/12/2008
// Cliente:    Alianca
// Descricao:  P.E. apos inclusao (por item) do SC9 na liberacao de pedido (credito).
//             Criado inicialmente para gravar log de eventos.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MTA450I ()
	local _oEvento  := NIL
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SC9002"
	_oEvento:Texto     = "Liberacao credito pedido c/ Banco=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_BANCO") + " e cond.pagto.=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_CONDPAG")
	_oEvento:Cliente   = sc9 -> c9_cliente
	_oEvento:LojaCli   = sc9 -> c9_loja
	_oEvento:PedVenda  = sc9 -> c9_pedido
	_oEvento:Produto   = sc9 -> c9_produto
	_oEvento:Grava ()
return
