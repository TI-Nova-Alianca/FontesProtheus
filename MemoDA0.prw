// Programa...: MemoDA0
// Autor......: Robert Koch
// Data.......: 11/11/2015
// Descricao..: Manutencao de campos memo do DA0 (P.E. OM010Mem simplesmente parou de funcionar no release 9)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MemoDA0 (_nRecno, _sQueFazer, _sCpoCod, _sCpoMemo)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sTextoOld := ""
	local _sTexto    := ""
	
	da0 -> (dbgoto (_nRecno))
	if _sQueFazer == "A"
		if ! empty (da0 -> &(_sCpoCod))
			_sTextoOld = msmm (da0 -> &(_sCpoCod),,,,3)
			_sTexto = _sTextoOld
		endif
		_sTexto = U_ShowMemo (_sTexto, RetTitle (_sCpoMemo))
		if empty (_sTexto) .and. ! empty (_sTextoOld)
			// Exclui.
			msmm (da0 -> &(_sCpoCod),,,, 2,,, "DA0", _sCpoCod)
		else
			// Inclui / altera.
			msmm (,,, _sTexto, 1,,, "DA0", _sCpoCod)
		endif
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return
