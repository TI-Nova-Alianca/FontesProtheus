// Programa:  ClassUva
// Autor:     Robert Koch
// Data:      19/01/2010
// Descricao: Retorna a classificacao final das uvas finas, de acordo com as diferentes avaliacoes.
//            Royalties: Jeferson Rech
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function ClassUva (_sConduc, _xPrm02, _xPrm03, _xPrm04, _xPrm05)
	local _sRet := ""

	_xPrm02 = alltrim (_xPrm02)
	_xPrm03 = alltrim (_xPrm03)
	_xPrm04 = alltrim (_xPrm04)
	_xPrm05 = alltrim (_xPrm05)

	// Latada: gatilho direto no SX7.
	if _sConduc == 'L'
		u_log2 ('info', '[' + procname () + ']', 'Classif. p/latada: existe gatilho na tabela SX7.')

	elseif _sConduc == 'E'
		// Obs. Precisa ser nessa ordem os testes, pois vale sempre a menor classificacao
		If _xPrm02=="PR" .Or. _xPrm03=="PR" .Or. _xPrm04=="PR" .Or. _xPrm05=="PR"
			_sRet = "PR"
		Endif
		If _xPrm02=="AA" .Or. _xPrm03=="AA" .Or. _xPrm04=="AA" .Or. _xPrm05=="AA"
			_sRet = "AA"
		Endif
		If _xPrm02=="A" .Or. _xPrm03=="A" .Or. _xPrm04=="A" .Or. _xPrm05=="A"
			_sRet = "A"
		Endif
	 	If _xPrm02=="B" .Or. _xPrm03=="B" .Or. _xPrm04=="B" .Or. _xPrm05=="B"
			_sRet = "B"
		Endif
		If _xPrm02=="C" .Or. _xPrm03=="C" .Or. _xPrm04=="C" .Or. _xPrm05=="C"
			_sRet = "C"
		Endif
		If _xPrm02=="D" .Or. _xPrm03=="D" .Or. _xPrm04=="D" .Or. _xPrm05=="D"
			_sRet = "D"
		Endif
		If _xPrm02=="DS" .Or. _xPrm03=="DS" .Or. _xPrm04=="DS" .Or. _xPrm05=="DS"
			_sRet = "DS"
		Endif
		u_log2 ('info', '[' + procname () + ']Classif. em espaldeira: vale a pior classificacao entre {' + _xPrm02 + ',' + _xPrm03 + ',' + _xPrm04 + ',' + _xPrm05 + '} ---> ' + _sRet)
	else
		u_help ("Sem tratamento para sistema de conducao '" + _sConduc + "' no programa " + procname (),, .t.)
	endif

return _sRet

/* versao ateh a safra 2019
user function ClassUva (_sConduc, _xPrm02, _xPrm03, _xPrm04, _xPrm05)
	local _sRet := ""

	_xPrm02 = alltrim (_xPrm02)
	_xPrm03 = alltrim (_xPrm03)
	_xPrm04 = alltrim (_xPrm04)
	_xPrm05 = alltrim (_xPrm05)

	// Obs. Precisa ser nessa ordem os testes, pois vale sempre a menor classificacao
	if _sConduc == 'L'

		If _xPrm03=="A" .Or. _xPrm05=="A"
			_sRet = "A"
		Endif
	 	If _xPrm03=="B" .Or. _xPrm05=="B"
			_sRet = "B"
		Endif
		If _xPrm03=="D" .Or. _xPrm05=="D"
			_sRet = "D"
		Endif

	elseif _sConduc == 'E'

		If _xPrm02=="PR" .Or. _xPrm03=="PR" .Or. _xPrm04=="PR" .Or. _xPrm05=="PR"
			_sRet = "PR"
		Endif
		If _xPrm02=="AA" .Or. _xPrm03=="AA" .Or. _xPrm04=="AA" .Or. _xPrm05=="AA"
			_sRet = "AA"
		Endif
		If _xPrm02=="A" .Or. _xPrm03=="A" .Or. _xPrm04=="A" .Or. _xPrm05=="A"
			_sRet = "A"
		Endif
	 	If _xPrm02=="B" .Or. _xPrm03=="B" .Or. _xPrm04=="B" .Or. _xPrm05=="B"
			_sRet = "B"
		Endif
		If _xPrm02=="C" .Or. _xPrm03=="C" .Or. _xPrm04=="C" .Or. _xPrm05=="C"
			_sRet = "C"
		Endif
		If _xPrm02=="D" .Or. _xPrm03=="D" .Or. _xPrm04=="D" .Or. _xPrm05=="D"
			_sRet = "D"
		Endif
		If _xPrm02=="DS" .Or. _xPrm03=="DS" .Or. _xPrm04=="DS" .Or. _xPrm05=="DS"
			_sRet = "DS"
		Endif

	endif

	//u_log ('[' + procname () + ']', _xPrm02, _xPrm03, _xPrm04, _xPrm05, '--->', _sRet)
return _sRet
*/



/* versao ate a safra 2018
user function ClassUva (_xPrm02, _xPrm03, _xPrm04, _xPrm05, _sClasABD)
	local _sRet := ""

	if ! empty (_sClasABD)
		if _sClasABD == 'A'
			_sRet = 'B '
		elseif _sClasABD == 'B'
			_sRet = 'C '
		elseif _sClasABD == 'D'
			_sRet = 'D '
		endif
	else
		// Obs. Precisa ser nessa ordem os testes, pois vale sempre a menor classificacao
		If _xPrm02=="AA" .Or. _xPrm03=="AA" .Or. _xPrm04=="AA" .Or. _xPrm05=="AA"
			_sRet = "AA"
		Endif
		If _xPrm02=="A " .Or. _xPrm03=="A " .Or. _xPrm04=="A " .Or. _xPrm05=="A "
			_sRet = "A "
		Endif
	 	If _xPrm02=="B " .Or. _xPrm03=="B " .Or. _xPrm04=="B " .Or. _xPrm05=="B "
			_sRet = "B "
		Endif
		If _xPrm02=="C " .Or. _xPrm03=="C " .Or. _xPrm04=="C " .Or. _xPrm05=="C "
			_sRet = "C "
		Endif
		If _xPrm02=="D " .Or. _xPrm03=="D " .Or. _xPrm04=="D " .Or. _xPrm05=="D "
			_sRet = "D "
		Endif
		If _xPrm02=="DS" .Or. _xPrm03=="DS" .Or. _xPrm04=="DS" .Or. _xPrm05=="DS"
			_sRet = "DS"
		Endif
	endif
return _sRet
*/
