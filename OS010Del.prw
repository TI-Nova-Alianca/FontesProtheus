// Programa:  OS010Del
// Autor:     Robert Koch
// Data:      18/08/2008
// Cliente:   Alianca
// Descricao: P.E. que permite ou nao a exclusao de tabela de precos.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function OS010Del ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet := .T.
	local _sQuery := ""
	_sQuery := ""
	_sQuery += " Select count (*)"
	_sQuery += "   from " + RetSQLName ("SZY")
	_sQuery += "  Where D_E_L_E_T_ = ''"
	_sQuery += "    And ZY_FILIAL  = '" + xfilial ("SZY")   + "'"
	_sQuery += "    And ZY_FILTAB  = '" + da0 -> da0_filial + "'"
	_sQuery += "    And ZY_CODTAB  = '" + da0 -> da0_codtab + "'"
	if U_RetSQL (_sQuery) > 0
		msgalert ("Tabela possui amarracao com vendedor(es). Nao pode ser excluida.")
		_lRet = .F.
	endif
	U_ML_SRArea (_aAreaAnt)
Return _lRet
