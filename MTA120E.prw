// Programa...: MTA120E
// Autor......: Robert Koch
// Data.......: 02/07/2012
// Descricao..: P.E. para validar a exclusao de pedido de compra / autorizacao de entrega.
//              Criado inicialmente para verificar amarracao com SE2.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MTA120E ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _lRet     := .T.

	// Verifica amarracao com financeiro.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT dbo.VA_DTOC (E2_EMISSAO) + ' (R$ ' + CAST (E2_VALOR AS VARCHAR) + ')'"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND E2_FILIAL  = '" + sc7 -> c7_filial + "'"
	_oSQL:_sQuery +=    " AND E2_VACHVEX = 'SC7" + sc7 -> c7_num + sc7 -> c7_item + "'"
	if ! empty (_oSQL:RetQry ())
		u_help ('Existem titulo(s) a pagar ligados a este pedido/aut.entrega: ' + _oSQL:Qry2Str (1, ','))
		_lRet = .F.
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
