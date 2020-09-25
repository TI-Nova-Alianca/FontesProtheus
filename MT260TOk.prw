// Programa:   MT260TOk
// Autor:      Robert Koch
// Data:       19/12/2011
// Descricao:  P.E. 'Tudo OK' na tela de transferencias de estoques.
//
// Historico de alteracoes:
// 15/03/2018 - Robert - Data nao pode mais ser diferente de date().
// 02/04/2018 - Robert - Movimentacao retroativa habilitada para o grupo 084.
//

// --------------------------------------------------------------------------
user function MT260TOk ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	local _sJahTem  := ""

	// Nao pode ter mais de um produto no mesmo tanque.
	if ! empty (cLoclzDest)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT BF_PRODUTO "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SBF") + " SBF, "
		_oSQL:_sQuery +=             RetSQLName ("SBE") + " SBE "
		_oSQL:_sQuery += " WHERE SBF.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SBF.BF_FILIAL   = '" + xfilial ("SBF") + "'"
		_oSQL:_sQuery +=   " AND SBF.BF_LOCALIZ  = '" + cLoclzDest + "'"
		_oSQL:_sQuery +=   " AND SBF.BF_PRODUTO != '" + cCodDest + "'"
		_oSQL:_sQuery +=   " AND SBF.BF_QUANT   != 0"
		_oSQL:_sQuery +=   " AND SBE.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SBE.BE_FILIAL   = SBF.BF_FILIAL"
		_oSQL:_sQuery +=   " AND SBE.BE_LOCALIZ  = SBF.BF_LOCALIZ"
		_oSQL:_sQuery +=   " AND SBE.BE_VATANQ   = 'S'"
		_sJahTem = _oSQL:RetQry ()
		if ! empty (_sJahTem)
			u_help ("Tanque '" + cLoclzDest + "' ja ocupado com o produto '" + alltrim (_sJahTem) + "'. Verifique!")
			_lRet = .F.
		endif
	endif
	
	if _lRet .and. (dEmis260 != date () .or. dDataBase != date ())
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
