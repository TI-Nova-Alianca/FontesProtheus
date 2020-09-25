// Programa...: ZX5_17
// Autor......: Robert Koch
// Data.......: 14/12/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
// 14/01/2019 - Robert - Passa a safra como filtro para a funcao de alteracao do ZX5.
//                     - Passa campos para ordenacao do aCols.
// 03/01/2020 - Robert - Campo ZX5_17COND vai ser excluido (a tabela 17 serve somente para espaldeira, entao nao ha motivo para manter o campo).
//

// --------------------------------------------------------------------------
User Function ZX5_17 ()
	local _sSafra := space (4)
	local _aOrd   := {'ZX5_17SAFR', 'ZX5_17GIPR', 'ZX5_17GIAA', 'ZX5_17GIA', 'ZX5_17GIB', 'ZX5_17GIC', 'ZX5_17GID', 'ZX5_17GIES', 'ZX5_17GFES', 'ZX5_17DESC'}

	if U_ZZUVL ('051')
		do while .t.
			_sSafra = U_Get ('Safra (vazio=todas)', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
			if _sSafra == NIL .or. empty (_sSafra)
				U_ZX5A (4, "17", "U_ZX5_17LO ()", "allwaystrue ()", .T.,NIL, _aOrd)
			else
				U_ZX5A (4, "17", "U_ZX5_17LO ()", "allwaystrue ()", .T., "zx5_17safr=='" + _sSafra + "'", _aOrd)
			endif
			if ! u_msgyesno ("Deseja abrir a tela novamente?")
				exit
			endif
		enddo
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_17LO ()
	local _lRet := .T.
return _lRet
