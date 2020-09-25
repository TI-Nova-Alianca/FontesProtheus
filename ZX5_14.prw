// Programa...: ZX5_14
// Autor......: Robert Koch
// Data.......: 17/04/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
// 24/12/2018 - Robert - Passa a safra como filtro para a funcao de alteracao do ZX5.
// 08/01/2019 - Robert - Passa campos para ordenacao do aCols.
//

// --------------------------------------------------------------------------
User Function ZX5_14 ()
	local _sSafra := space (4)
	local _aOrd   := {'ZX5_14SAFR', 'ZX5_14GRUP', 'ZX5_14DESC'}

	if U_ZZUVL ('051')
		do while .t.
			_sSafra = U_Get ('Safra (vazio=todas)', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
			if _sSafra == NIL .or. empty (_sSafra)
				U_ZX5A (4, "14", "U_ZX5_14LO ()", "allwaystrue ()", .T.,NIL, _aOrd)
			else
				U_ZX5A (4, "14", "U_ZX5_14LO ()", "allwaystrue ()", .T., "zx5_14safr=='" + _sSafra + "'", _aOrd)
			endif
			if ! u_msgyesno ("Deseja abrir a tela novamente?")
				exit
			endif
		enddo
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_14LO ()
	local _lRet := .T.
return _lRet
