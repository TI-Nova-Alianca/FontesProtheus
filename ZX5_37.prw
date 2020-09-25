// Programa...: ZX5_37
// Autor......: Robert Koch
// Data.......: 31/08/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_37 ()

	if U_ZZUVL ('058')
		U_ZX5A (4, "37", "U_ZX5_37LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_37LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_37COD"}, 4)
	endif

return _lRet
