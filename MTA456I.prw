// Programa:   MTA456I
// Autor:      Robert Koch
// Data:       01/09/2008
// Cliente:    Alianca
// Descricao:  P.E. apos gravacao da liberacao de credito/estoque do pedido.
//             Criado, inicialmente, para gravar evento.
//
// Historico de alteracoes:
// 15/12/2008 - Robert - Incluido banco e cond.pagto. no evento.
//

// --------------------------------------------------------------------------
user function MTA456I ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento  := NIL

	_oEvento := ClsEvent():new ()
	_oEvento:CodEven = "SC9001"
	_oEvento:Texto     = "Liberacao manual de credito/estoque. Quant=" + cvaltochar (sc9 -> c9_qtdlib) + "; banco=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_BANCO") + "; cond.pagto.=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_CONDPAG")
	_oEvento:PedVenda  = sc9 -> c9_pedido
	_oEvento:Cliente   = sc9 -> c9_cliente
	_oEvento:LojaCli   = sc9 -> c9_loja
	_oEvento:Produto   = sc9 -> c9_produto
	_oEvento:Grava ()

	U_ML_SRArea (_aAreaAnt)
return
