// Programa:   SelInd
// Autor:      Robert Koch
// Data:       06/02/2013
// Descricao:  Seleciona o primeiro indice do arquivo que contiver os campos passados como parametro.
//             Criado para tentar escapar das simpaticas trocas de ordem dos indices padrao quando
//             ha atualizacao de versao do sistema.
//
// Parametros: par01: alias do arquivo.
//             par02: array com os nomes dos campos que devem constar no indice.
//                    A ordem dos campos na array eh importante.
//                    Obs.: campos tipo data geralmente tem DTOS().
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SelInd (_sAlias, _aCampos)
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .F.
	local _lServe   := .F.
	local _nIndice  := 0
	local _nCampo	:= 0

	if ! empty (_sAlias) .and. len (_aCampos) > 0
		// Varre todos os indices do arquivo.
		_nIndice = 1
		do while .t.
			_sIndice = (_sAlias) -> (IndexKey (_nIndice))
			
			// Se nao ha mais indices...
			if empty (_sIndice)
				exit
			endif
			
			// Separa os campos usados na chave do indice
			_aIndice = U_SeparaCpo (_sIndice, '+')
			
			// Verifica campo a campo
			_lServe = .T.
			for _nCampo = 1 to min (len (_aCampos), len (_aIndice))
				if strtran (upper (alltrim (_aIndice [_nCampo])), ' ', '') != strtran (upper (alltrim (_aCampos [_nCampo])), ' ', '')
					_lServe = .F.
					exit
				endif
			next
			
			if _lServe
				_lRet = .T.
				exit
			endif

			_nIndice ++
		enddo
	endif

	U_ML_SRArea (_aAreaAnt)

	// Se encontrou um indice, seta-o no arquivo. Faz isso depois de restaurar o ML_SRArea.
	if _lRet
		(_sAlias) -> (dbsetorder (_nIndice))
	else
		u_help ("Nao foi encontrado nenhum indice na tabela '" + _sAlias + "' que atenda a chave especificada. Verifique o programa!")
	endif
return _lRet
