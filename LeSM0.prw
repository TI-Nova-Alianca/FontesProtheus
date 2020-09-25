// Programa...: LeSM0
// Autor......: Robert Koch
// Data.......: 12/05/2011
// Cliente....: Alianca
// Descricao..: Leitura do arquivo SM0 (sigamat.emp) e retorno de informacoes diversas.
//              Usado principalmente para montagem de listas das empresas/filiais do sistema.
//
// Historico de alteracoes:
// 19/06/2011 - Robert - Implementado retorno tipo 5
// 22/06/2011 - Robert - Implementado retorno tipo 6
//

// --------------------------------------------------------------------------
User Function LeSM0 (_sQueFazer, _sEmpSim, _sEmpNao, _sAliasSQL, _sCpoEmp, _sCpoFil)
	local _aAreaAnt := U_ML_SRArea ()
	local _aRet     := {}
	local _xRet     := NIL
	local _sCaseEmp := ""
	local _sCaseFil := ""
	local _aCols    := {}
	local _nEmpFil  := 0
	local _sEmpresa := ""
	local _sNomeEmp := ""
	local _aFiliais := {}
	local _sFiliais := ""

	if valtype (_sAliasSQL) == "C" .and. valtype (_sCpoEmp) == "C" .and. valtype (_sCpoFil) == "C"
		_sCaseEmp := " CASE " + _sAliasSQL + "." + _sCpoEmp + " "
		_sCaseFil := " CASE " + _sAliasSQL + "." + _sCpoFil + " "
	endif

	// Loop em todas as empresas/filiais.
	sm0 -> (dbgotop ())
	do while ! sm0 -> (eof ())

		// Filtragens
		if (! empty (_sEmpSim) .and. ! sm0 -> m0_codigo $ _sEmpSim) .or. (! empty (_sEmpNao) .and. sm0 -> m0_codigo $ _sEmpNao)
			sm0 -> (dbskip ())
			loop
		endif

		do case
		case _sQueFazer == '1' // Lista simples das empresas.
			if ascan (_aRet, sm0 -> m0_codigo) == 0
				aadd (_aRet, sm0 -> m0_codigo)
			endif

		case _sQueFazer == '2'  // Monta string em SQL para buscar o nome da empresa e filial, conforme cadastro no Sigamat.

			// Nao faz novo tratamento se esta empresa jah consta no case.
			if at ("'" + sm0 -> m0_codigo + "'", _sCaseEmp) == 0
				_sCaseEmp += " WHEN '" + sm0 -> m0_codigo + "' THEN '" + upper (alltrim (sm0 -> m0_nome)) + "' "
			endif

			// Nao faz novo tratamento se esta filial jah consta no case.
			if at ("'" + sm0 -> m0_codfil + "'", _sCaseFil) == 0
				_sCaseFil += " WHEN '" + sm0 -> m0_codfil + "' THEN '" + upper (alltrim (sm0 -> m0_filial)) + "' "
			endif

		case _sQueFazer $ '3/4/6'  // Monta array de opcoes para selecao multipla.
			
			// Nao faz novo tratamento se esta empresa/filial jah consta na array.
			if ascan (_aRet, {|_aVal| _aVal [2] == sm0 -> m0_codigo .and. _aVal [4] == sm0 -> m0_codfil}) == 0
				aadd (_aRet, {.F., sm0 -> m0_codigo, sm0 -> m0_nome, sm0 -> m0_codfil, sm0 -> m0_filial})
			endif

		case _sQueFazer == '5'  // Array com todas as empresas e filiais.
			aadd (_aRet, {sm0 -> m0_codigo, sm0 -> m0_nome, sm0 -> m0_codfil, sm0 -> m0_filial})

		otherwise
			u_help ("Opcao '" + _sQueFazer + "' nao implementada na rotina " + procname ())
		endcase

		sm0 -> (dbskip ())
	enddo

	_sCaseEmp += " END "
	_sCaseFil += " END "

	_aCols = {}
	aadd (_aCols, {2, "Empresa",      20, ""})
	aadd (_aCols, {3, "Nome empresa", 80, ""})
	aadd (_aCols, {4, "Filial",       20, ""})
	aadd (_aCols, {5, "Nome filial",  80, ""})

	// Monta retorno conforme solicitado pelo usuario.
	do case
	case _sQueFazer == '1'
		_xRet = aclone (_aRet)

	
	// 'Case' para SQL
	case _sQueFazer == '2'
		_xRet = {_sCaseEmp, _sCaseFil}

	
	// Markbrowse (selecao multipla)
	case _sQueFazer == '3'

		U_MBArray (@_aRet, "Selecione empresas/filial", _aCols, 1, 600, 400, , ".T.")
		_xRet = aclone (_aRet)

	
	// F3 (selecao unica)
	case _sQueFazer == '4'

		_xRet = U_F3Array (_aRet, "Selecione empresa/filial", _aCols, 600, 400)
		if _xRet > 0
			_xRet = _aRet [_xRet]
		else
			_xRet = {}
		endif

	
	case _sQueFazer == '5'
		_xRet := aclone (_aRet)


	// Retornar array com empresas selecionadas e, dentro da linha de cada
	// empresa, uma subarray com as filiais selecionadas para essa empresa
	// e uma string com as filiais separadas por barras.
	case _sQueFazer == '6'
		_xRet = {}
		U_MBArray (@_aRet, "Selecione empresas/filial", _aCols, 1, 600, 400, , ".T.")
		_nEmpFil = 1
		do while _nEmpFil <= len (_aRet)
			_sEmpresa = _aRet [_nEmpFil, 2]
			_sNomeEmp = _aRet [_nEmpFil, 3]
			_aFiliais = {}
			_sFiliais = ""
			do while _nEmpFil <= len (_aRet) .and. _aRet [_nEmpFil, 2] == _sEmpresa
				if _aRet [_nEmpFil, 1]
					aadd (_aFiliais, _aRet [_nEmpFil, 4])
					_sFiliais += _aRet [_nEmpFil, 4] + '/'
				endif
				_nEmpFil ++
			enddo
			if len (_aFiliais) > 0
				// Remove barra no final.
				if right (_sFiliais, 1) == '/'
					_sFiliais = substr (_sFiliais, 1, len (_sFiliais) - 1)
				endif
				aadd (_xRet, {_sEmpresa, aclone (_aFiliais), _sFiliais, _sNomeEmp})
			endif
		enddo


	otherwise
		u_help ("Opcao '" + _sQueFazer + "' sem retorno definido na rotina " + procname ())
	endcase

	U_ML_SRArea (_aAreaAnt)
return _xRet
