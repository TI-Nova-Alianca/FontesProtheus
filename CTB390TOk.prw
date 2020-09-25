// Programa:  CTB390TOk
// Autor:     Robert Koch
// Data:      17/03/2016
// Descricao: P.E. 'Tudo OK' da tela de orcamentos contabeis.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function CTB390TOk ()
	local _lRet    := .T.
	local _nReg    := 0

	// Aplica a validacao 'linka OK' para todas as linhas. Isso foi necessario por que, quando o P.E. 'linha ok'
	// foi implementado, os orcamentos jah encontravam-se gravados com erros.
	if _lRet .and. ExistBlock ("CTB390LOK")
		_nReg = tmp -> (recno ())
		tmp -> (dbgotop ())
		do while ! tmp -> (eof ())
			if ! U_CTB390LOk ()
				_lRet = .F.
				exit
			endif
			tmp -> (dbskip ())
		enddo
		tmp -> (dbgoto (_nReg))
	endif
return _lRet
