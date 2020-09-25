// Programa...: ZX5_45
// Autor......: Júlio Pedroni
// Data.......: 19/08/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_45 ()
	U_ZX5A (4, "45", "U_ZX5_45LO ()", "allwaystrue ()")
return

// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_45LO ()
	local _lRet := .T.

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_45COD"}, 4)
	endif
return _lRet
//