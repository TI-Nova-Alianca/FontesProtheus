// Programa...: ZX5_12
// Autor......: Robert Koch
// Data.......: 18/03/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
// 25/01/2019 - Robert - Verificacao de chave duplicada passa a ser feita pela propria classe ClsTabGen.
//
	

// --------------------------------------------------------------------------
User Function ZX5_12 ()

	if U_ZZUVL ('058')
		U_ZX5A (4, "12", "U_ZX5_12LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_12LO ()
	local _lRet := .T.

	// Verificacao passada para a propria classe ClsTabGen.
	//// Verifica linha duplicada.
	//if _lRet .and. ! GDDeleted ()
	//	_lRet = GDCheckKey ({"ZX5_12COD"}, 4)
	//endif

return _lRet
