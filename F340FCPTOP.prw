// Programa:  F340FCPTOP
// Autor:     Robert Koch
// Data:      22/06/2020
// Descricao: P.E. para alterar filtro de titulos a compensar.
//            Criado inicialmente para facilitar filtragens via conta corrente de associados.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function F340FCPTOP ()
	local _sCond340  := PARAMIXB[1] //Query padrão
	local _nPosOrder := 0
	
	// Verifica se a compensacao estah sendo chamada a partir da tela de manutencao da conta corrente
	// de associados, e se foi definida alguma expressao para filtro de titulos.
	if IsInCallStack ("U_SZIB") .and. type ("_sFilZI340") == 'C' .and. ! empty (_sFilZI340)
		
		// Encontra a posicao, dentro da query, onde pode inserir clausula adicional.
		_nPosOrder = at (' ORDER BY ', _sCond340)

		if _nPosOrder == 0
			u_help ('[' + procname () + ']: Nao encontrei a clausula ORDER BY na query, conforme esperado. Nao vou acrescentar filtro para a selecao de titulos.')
		else
			u_log2 ('info', 'Acrescentando filtro na query de selecao de titulos: ' + _sFilZI340)
			_sCond340 = left (_sCond340, _nPosOrder) + ' ' + _sFilZI340 + ' ' + substr (_sCond340, _nPosOrder + 1)
		//	u_log2 ('info', _sCond340)
		endif
	endif
return _sCond340
