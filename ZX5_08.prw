// Programa...: ZX5_08
// Autor......: Robert Koch
// Data.......: 01/08/2016
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_08 ()

	if U_ZZUVL ('058')
		U_ZX5A (4, "08", "U_ZX5_08LO ()", "allwaystrue ()")
	endif
return



// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_08LO ()
	local _lRet := .T.
	local _oSQL := NIL

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_08MARC"}, 4)
	endif

	if _lRet .and. GDDeleted ()
		CursorWait ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND B1_FILIAL = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery += " AND B1_VARMAAL = '" + GDFieldGet ("ZX5_08MARC") + "'"
		if _oSQL:RetQry () > 0
			u_help ("Registro encontra-se amarrado ao cadastro de produtos e nao pode ser excluido.")
			_lRet = .F. 
		endif
		CursorArrow ()
	endif

return _lRet
