// Programa...: VA_RusMV
// Autor......: Robert Koch
// Data.......: 06/01/2021
// Descricao..: Verifica se, na carga, tem mistura de variedades e, nesse caso, qual a variedade de menor valor comercial.
//              Desmembrado do VA_RUSN.PRW
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_RusMV ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _sMenorVlr := ''
	local _aProdut   := {}
	local _nProdut   := 0
	local _lContinua := .T.
	local _aAux      := {}

	u_Log2 ('info', 'Iniciando ' + procname ())

	// Se existe mistura de variedades, precifica pela de menor valor.
	// Para isso, varre os itens, monta uma lista de codigos distintos e busca o preco de cada um
	// considerando um grau medio e classificacoes medias. Neste momento nao interessa a classificacao
	// por que quero saber apenas qual a de menor valor comercial.
	_aProdut = {}
	szf -> (dbsetorder (1))  // filial + safra + carga + item
	szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
	do while _lContinua ;
		.and. ! szf -> (eof ()) ;
		.and. szf -> zf_filial == xfilial ("SZF") ;
		.and. szf -> zf_safra  == sze -> ze_safra ;
		.and. szf -> zf_carga  == sze -> ze_carga

		if ascan (_aProdut, {|_aVal| _aVal [1] == szf -> zf_produto}) == 0
			aadd (_aProdut, {szf -> zf_produto, 0, szf -> zf_conduc})
		endif
		szf -> (dbskip ())
	enddo
		
	// Se tem apenas um produto, nem perde tempo buscando precos.
	if len (_aProdut) > 1
		for _nProdut = 1 to len (_aProdut)
			if sze -> ze_safra == '2019'
				_aProdut [_nProdut, 2] = U_PrcUva19 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3])[1]
			elseif sze -> ze_safra == '2020'
				_aProdut [_nProdut, 2] = U_PrcUva20 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F.)[5]  // pos.5=preco MOC
			elseif sze -> ze_safra == '2021'
				_aProdut [_nProdut, 2] = U_PrcUva21 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F., .T.)[2]  // pos.2=preco de compra
			else
				u_help (procname () + ": Sem tratamento para verificar precificacao em caso de mistura de variedades nesta safra.",, .t.)
				_lContinua = .F.
				exit
			endif
		next
		_aProdut = asort (_aProdut,,, {|_x, _y| _x[2] < _y [2]})
		u_log2 ('info', '_aProdut:')
		u_log2 ('info', _aProdut)
		
		// Elimina produtos com precos iguais.
		if _lContinua
			_aAux = {}
			for _nProdut = 1 to len (_aProdut)
				if ascan (_aAux, {|_aVal| _aVal [2] = _aProdut [_nProdut, 2]}) == 0
					aadd (_aAux, aclone (_aProdut [_nProdut]))
				endif
			next
			_aProdut = aclone (_aAux)
			if len (_aProdut) > 1  // Se ainda sobrou mais de um produto com diferentes precos
				_sMenorVlr = _aProdut [1, 1]
				u_log2 ('info', 'produto de menor valor: ' + _sMenorVlr)
			endif
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
return _sMenorVlr
