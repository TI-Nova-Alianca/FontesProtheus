// Programa...: ZX5_46
// Autor......: Robert Koch
// Data.......: 20/11/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_46 ()
	U_ZX5A (4, "46", "U_ZX5_46LO ()", "allwaystrue ()")
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_46LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_46COD"}, 4)
	endif

return _lRet
