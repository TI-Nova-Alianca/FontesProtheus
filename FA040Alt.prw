// Programa:   FINA040
// Autor:      Robert Koch
// Data:       14/02/2011
// Descricao:  P.E. 'Tudo OK' na alteracao de contas a receber.
//             Criado inicialmente para gravar evento de alteracao manual.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA040ALT ()
	local _lRet    := .T.
	local _oEvento := NIL

	// Verifica quais campos foram alterados.
	_oEvento := ClsEvent():new ()
	if alltrim (m->e1_tipo) == "NF" .or. ! empty (m->e1_numnota)
		_oEvento:NFSaida   = se1 -> e1_num
		_oEvento:SerieSaid = se1 -> e1_prefixo
		_oEvento:PedVenda  = se1 -> e1_pedido
		_oEvento:Cliente   = se1 -> e1_cliente
		_oEvento:LojaCli   = se1 -> e1_loja
		_oEvento:ParcTit   = se1 -> e1_parcela
	endif
	_oEvento:AltCadast ("SE1", m->e1_prefixo + m->e1_num + m->e1_parcela, se1 -> (recno ()))
return _lRet
