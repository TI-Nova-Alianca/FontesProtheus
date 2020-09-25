// Programa...: VA_ZZG
// Autor......: Robert Koch
// Data.......: 07/08/2012
// Descricao..: Tela de cadastro de valores financiamentos obra unidade Flores da Cunha.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_ZZG ()
	private _sArqLog := U_NomeLog ()
	AXCadastro ("ZZG", "Valores financiamentos obra Flores da Cunha", "U_VA_ZZGEK ()", "U_VA_ZZGIK ()")
return



// --------------------------------------------------------------------------
// Valida inclusao e alteracao.
User Function VA_ZZGIK ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()

	zzg -> (dbsetorder (1))
	if inclui .and. zzg -> (dbseek (xfilial ("ZZG") + m->zzg_plano + m->zzg_cod + m->zzg_contr, .F.))
		u_help ("Ja existe registro com esta combinacao de plano + item + contrato.")
		_lRet = .F.
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet



// --------------------------------------------------------------------------
// Valida exclusao.
User Function VA_ZZGEK ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _sMsg     := ""

	CursorWait ()

	if zzg -> zzg_plano == '1'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH C AS ("
		_oSQL:_sQuery += " SELECT COUNT (*) AS QUANTOS, CAST (COUNT (*) AS VARCHAR (9)) + ' Contratos de parceria' AS MSG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC3")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND C3_FILIAL  = '" + xfilial ("SC3")  + "'"
		_oSQL:_sQuery +=    " AND C3_VAZZG   = '" + zzg -> zzg_cod   + "'"
		_oSQL:_sQuery +=    " AND C3_VAZZGC  = '" + zzg -> zzg_contr + "'"
		_oSQL:_sQuery += " UNION ALL"
		_oSQL:_sQuery += " SELECT COUNT (*) AS QUANTOS, CAST (COUNT (*) AS VARCHAR (9)) + ' Pedidos de compra' AS MSG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC7")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND C7_FILIAL  = '" + xfilial ("SC7")  + "'"
		_oSQL:_sQuery +=    " AND C7_VAZZG   = '" + zzg -> zzg_cod   + "'"
		_oSQL:_sQuery +=    " AND C7_VAZZGC  = '" + zzg -> zzg_contr + "'"
		_oSQL:_sQuery += " UNION ALL"
		_oSQL:_sQuery += " SELECT COUNT (*) AS QUANTOS, CAST (COUNT (*) AS VARCHAR (9)) + ' NF de entrada' AS MSG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND D1_FILIAL  = '" + xfilial ("SD1")  + "'"
		_oSQL:_sQuery +=    " AND D1_VAZZG   = '" + zzg -> zzg_cod   + "'"
		_oSQL:_sQuery +=    " AND D1_VAZZGC  = '" + zzg -> zzg_contr + "'"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT MSG, SUM (QUANTOS) OVER ()"
		_oSQL:_sQuery += " FROM C"
		u_log (_oSQL:_sQuery)
		if _oSQL:RetQry (2) > 0
			u_help ("Este relacionamento item X contrato nao pode ser excluido pois foi usado em: " + chr (13) + chr (10) + _oSQL:Qry2Str (1, chr (13) + chr (10)))
			_lRet = .F.
		endif
	elseif zzg -> zzg_plano == '2'
		u_help ('sem validacao de exclusao para este plano')
		_lRet = .F.
	else
		u_help ('sem validacao de exclusao para este plano')
		_lRet = .F.
	endif

	CursorArrow ()
return _lRet
