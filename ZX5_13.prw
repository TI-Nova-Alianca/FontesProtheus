// Programa...: ZX5_13
// Autor......: Robert Koch
// Data.......: 17/04/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
// 24/12/2018 - Robert - Passa a safra como filtro para a funcao de alteracao do ZX5.
// 08/01/2019 - Robert - Passa campos para ordenacao do aCols.
//

// --------------------------------------------------------------------------
User Function ZX5_13 ()
	local _sSafra := space (4)
	local _aOrd   := {'ZX5_13SAFR', 'ZX5_13GRUP'}

	if U_ZZUVL ('051')
		do while .t.
			_sSafra = U_Get ('Safra (vazio=todas)', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
			if _sSafra == NIL .or. empty (_sSafra)
				U_ZX5A (4, "13", "U_ZX5_13LO ()", "allwaystrue ()", .T., NIL, _aOrd)
			else
				U_ZX5A (4, "13", "U_ZX5_13LO ()", "allwaystrue ()", .T., "zx5_13safr=='" + _sSafra + "'", _aOrd)
			endif
			if ! u_msgyesno ("Deseja abrir a tela novamente?")
				exit
			endif
		enddo
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_13LO ()
	local _lRet := .T.
return _lRet
