// Programa...: ZX5_42
// Autor......: Júlio Pedroni
// Data.......: 14/03/2017
// Descricao..: Edicao de registros do ZX5 com chave especifica.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function ZX5_42 ()
	U_ZX5A (4, "42", "U_ZX5_42LO ()", "allwaystrue ()")
return

// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_42LO ()
	local _lRet := .T.
	local _oSQL := NIL

	// Verifica linha duplicada.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_42COD"}, 4)
	endif

	if _lRet .and. GDDeleted ()
		CursorWait ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SN1") + " SN1"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND N1_FILIAL  = '" + xfilial ("SN1") + "'"
		_oSQL:_sQuery += " AND N1_VAZX542 = '" + GDFieldGet ("ZX5_42COD") + "'"
		if _oSQL:RetQry () > 0
			u_help ("Registro encontra-se amarrado ao cadastro de Ativos / Maquinas e nao pode ser excluido.")
			_lRet = .F. 
		endif
		CursorArrow ()
	endif
	
return _lRet
