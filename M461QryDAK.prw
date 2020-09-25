// Programa...: M461QryDAK
// Autor......: Robert Koch
// Data.......: 03/10/2015
// Descricao..: P.E. na entrada da tela de faturamento por carga. Permite alterar filtragem de cargas/pedidos.
//
// Historico de alteracoes:
// 20/08/2019 - Robert - Faltava clausula "SC9.C9_CARGA = DAK.DAK_COD" na query. Nao sei se a linha foi deletada sem querer em algum momento...
//

// ----------------------------------------------------------------
user function M461QRYDAK (_a)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sRet      := paramixb [1]
	local _oSQL      := NIL
	local _aProblem  := {}
	local _nProblem  := 0
	local _sMsg      := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT DAK.DAK_COD"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("DAK") + " DAK, "
	_oSQL:_sQuery +=              RetSQLName ("SC9") + " SC9 "
	_oSQL:_sQuery +=  " WHERE DAK.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SC9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SC9.C9_FILIAL  = DAK.DAK_FILIAL"
	_oSQL:_sQuery +=    " AND SC9.C9_CARGA   = DAK.DAK_COD"
	_oSQL:_sQuery +=    " AND DAK.DAK_FEZNF != '1'"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT * "
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC5") + " SC5 "
	_oSQL:_sQuery +=                 " WHERE SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SC5.C5_FILIAL  = SC9.C9_FILIAL"
	_oSQL:_sQuery +=                   " AND SC5.C5_NUM     = SC9.C9_PEDIDO"
	_oSQL:_sQuery +=                   " AND SC5.C5_TRANSP != DAK.DAK_VATRAN)"
	_oSQL:_sQuery +=    " AND " + ParamIXB [1]
	_oSQL:Log ()
	_aProblem := aclone (_oSQL:Qry2Array ())
	if len (_aProblem) > 0
		_sRet += " AND DAK_COD NOT IN ("
		_sMsg = ""
		for _nProblem = 1 to len (_aProblem)
			_sRet += "'" + _aProblem [_nProblem, 1] + "'" + iif (_nProblem < len (_aProblem), ',', '')
			_sMsg += _aProblem [_nProblem, 1] + iif (_nProblem < len (_aProblem), ', ', '')
		next
		_sRet += ")"
		u_log ('retornando:', _sRet)
		u_help ("Aviso: as seguintes cargas contem pedidos sem transportadora (ou transportadora diferente da carga) e nao serao faturadas: " + _sMsg)
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _sRet
