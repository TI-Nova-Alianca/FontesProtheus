// Programa:   MT440Gr
// Autor:      Robert Koch
// Data:       19/11/2008
// Descricao:  P.E. 'Tudo OK' na tela de liberacao de pedidos.
//             Criado, inicialmente, para avisar quando nao hah estoque suficiente.
//
// Historico de alteracoes:
// 05/10/2009 - Robert - Passa a verificar estoque tambem na empresa 02.
// 22/03/2021 - Robert - Adequacao para usar variaveis locais em lacos FOR...NEXT
//

// --------------------------------------------------------------------------
user function mt440gr ()
	local _lRet := .T.
	if paramixb [1] == 1  // Usuario confirmou liberacao
		_lRet = _VerEstq ()
	endif
return _lRet



// --------------------------------------------------------------------------
// Verifica saldos em estoques.
static function _VerEstq ()
	local _lRet    := .T.
	local _n       := N
	local _aItens  := {}
	local _sMsg    := ""
	local _oEvento := NIL
	local _nItem   := 0
	local _nLinha  := 0

	// Monta lista dos totais por produto por que pode haver o mesmo produto em mais de uma linha do pedido.
	sf4 -> (dbsetorder (1))
	_aItens = {}
	for _nLinha = 1 to len (aCols)
		N = _nLinha
		if ! GDDeleted () .and. GDFieldGet ("C6_QTDLIB") > 0 .and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES"), "F4_ESTOQUE") == "S"
			_nItem = ascan (_aItens, {|_aVal| _aVal [1] == GDFieldGet ("C6_PRODUTO") .and. _aVal [2] == GDFieldGet ("C6_LOCAL")})
			if _nItem == 0
				aadd (_aItens, {GDFieldGet ("C6_PRODUTO"), GDFieldGet ("C6_LOCAL"), GDFieldGet ("C6_QTDLIB")})
			else
				_aItens [_nItem, 3] += GDFieldGet ("C6_QTDLIB")
			endif
		endif
	next

	sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
	for _nItem = 1 to len (_aItens)
		if ! sb2 -> (dbseek (xfilial ("SB2") + _aItens [_nItem, 1] + _aItens [_nItem, 2], .F.))
			_sMsg += _aItens [_nItem, 1] + chr (13) + chr (10) //msgalert ("Produto '" + alltrim (_aItens [_nItem, 1]) + "' sem saldo no almoxarifado '" + _aItens [_nItem, 2] + "'. Informe quantidade liberada menor.")
		else
			// Busca a quantidade que este pedido estava empenhando antes de ser alterado.
			_sQuery := ""
			_sQuery += " select sum (C9_QTDLIB)"
			_sQuery +=   " from " + RetSQLName ("SC9") + " SC9 "
			_sQuery +=  " where SC9.D_E_L_E_T_ = ''"
			_sQuery +=    " and SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
			_sQuery +=    " and SC9.C9_PEDIDO  = '" + m->c5_num + "'"
			_sQuery +=    " and SC9.C9_PRODUTO = '" + _aItens [_nItem, 1] + "'"
			if _aItens [_nItem, 3] > (sb2 -> b2_qatu - sb2 -> b2_qemp - sb2 -> b2_reserva + U_RetSQL (_sQuery))
				_sMsg += _aItens [_nItem, 1] + chr (13) + chr (10) //msgalert ("Produto '" + alltrim (_aItens [_nItem, 1]) + "' saldo insuficiente no almoxarifado '" + _aItens [_nItem, 2] + "'. Informe quantidade liberada menor.")
			endif
		endif
	next
	
	if ! empty (_sMsg)
		_lRet = msgyesno ("O(s) seguinte(s) produto(s) nao tem estoque suficiente:" + chr (13) + chr (10) + _sMsg + chr (13) + chr (10) + "Deseja liberar o pedido mesmo assim?","Pedido")

		// Grava evento para posterior consulta.
		if _lRet
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven  = "SC9001"
			_oEvento:Texto    = "Liberacao pedido sem estoque suficiente."
			_oEvento:Cliente  = sc5 -> c5_cliente
			_oEvento:LojaCli  = sc5 -> c5_lojacli
			_oEvento:PedVenda = sc5 -> c5_num
			_oEvento:Grava ()
		endif
	endif

	N = _n
return _lRet

