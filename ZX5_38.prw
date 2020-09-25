// Programa...: ZX5_38
// Autor......: Robert Koch
// Data.......: 31/08/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_38 ()

	if U_ZZUVL ('006')
		U_ZX5A (4, "38", "U_ZX5_38LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_38LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_38COD"}, 4)
	endif

return _lRet
