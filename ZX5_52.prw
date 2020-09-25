// Programa...: ZX5_52
// Autor......: Robert Koch
// Data.......: 03/01/2020
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_52 ()
	local _sSafra := space (4)
	local _aOrd   := {'ZX5_52SAFR', 'ZX5_52GRUP'}

	if U_ZZUVL ('051')
		_sSafra = U_Get ('Safra (vazio=todas)', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
		if _sSafra == NIL .or. empty (_sSafra)
			U_ZX5A (4, "52", "U_ZX5_52LO ()", "allwaystrue ()", .T., NIL, _aOrd)
		else
			U_ZX5A (4, "52", "U_ZX5_52LO ()", "allwaystrue ()", .T., "zx5_52safr=='" + _sSafra + "'", _aOrd)
		endif
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_52LO ()
	local _lRet := .T.
return _lRet
