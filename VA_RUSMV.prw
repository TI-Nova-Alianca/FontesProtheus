// Programa...: VA_RusMV
// Autor......: Robert Koch
// Data.......: 06/01/2021
// Descricao..: Verifica se, na carga, tem mistura de variedades e, nesse caso, qual a variedade de menor valor comercial.
//              Desmembrado do VA_RUSN.PRW
//
// Historico de alteracoes:
// 22/01/2022 - Robert - Retorna vazio em caso de erro, assim a funcao chamadora pode saber se executou normal.
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

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	// Se existe mistura de variedades, precifica pela de menor valor.
	// Para isso, varre os itens, monta uma lista de codigos distintos e busca o preco de cada um
	// considerando um grau medio e classificacoes medias. Neste momento nao interessa a classificacao
	// por que quero saber apenas qual a de menor valor comercial.
	if _lContinua
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
	endif
		
	// Se tem apenas um produto, nem perde tempo buscando precos.
	if _lContinua
		if len (_aProdut) > 1
			for _nProdut = 1 to len (_aProdut)

				// Manter aqui sempre a mesma politica do VA_RUSN !!!
				if sze -> ze_safra == '2019'
					_aProdut [_nProdut, 2] = U_PrcUva19 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3])[1]
				elseif sze -> ze_safra == '2020'
					_aProdut [_nProdut, 2] = U_PrcUva20 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F.)[5]  // pos.5=preco MOC
				elseif sze -> ze_safra == '2021'
					_aProdut [_nProdut, 2] = U_PrcUva21 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F., .T.)[2]  // pos.2=preco de compra
				elseif sze -> ze_safra == '2022'
					_aProdut [_nProdut, 2] = U_PrcUva22 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F., .T.)[2]  // pos.2 = preco de compra.
				elseif sze -> ze_safra == '2023'
					//_aProdut [_nProdut, 2] = U_PrcUva23 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F., .T.)[2]  // pos.2 = preco de compra.
					// Safra 2023 faremos compra a preco de tabela MOC2022 cfe.e-mail Colleoni 12/12/2022
					_aProdut [_nProdut, 2] = U_PrcUva22 (sze -> ze_filial, _aProdut [_nProdut, 1], 15.0, 'B', _aProdut [_nProdut, 3], .F., .T.)[5]  // pos.5 = preco MOC
				else
					u_help (procname () + ": Sem tratamento para verificar precificacao em caso de mistura de variedades nesta safra.",, .t.)
					_lContinua = .F.
					exit
				endif
			next
			_aProdut = asort (_aProdut,,, {|_x, _y| _x[2] < _y [2]})
		//	u_log2 ('info', '_aProdut:')
		//	u_log2 ('info', _aProdut)
			
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
	endif
	
	U_ML_SRArea (_aAreaAnt)
return iif (_lContinua, _sMenorVlr, NIL)  // Retorna vazio em caso de erro, assim a funcao chamadora pode saber se executou normal.
