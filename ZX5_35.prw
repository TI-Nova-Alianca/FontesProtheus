// Programa...: ZX5_35
// Autor......: Robert Koch
// Data.......: 29/03/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_35 ()

	if U_ZZUVL ('058')
		U_ZX5A (4, "35", "U_ZX5_35LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_35LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_35COD"}, 4)
	endif

return _lRet
