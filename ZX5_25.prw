// Programa...: ZX5_25
// Autor......: Robert Koch
// Data.......: 18/03/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_25 ()

	if U_ZZUVL ('058')
		U_ZX5A (4, "25", "U_ZX5_25LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_25LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_25COD"}, 4)
	endif

return _lRet
