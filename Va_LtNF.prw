// Programa...: VA_LtNF
// Autor......: Robert Koch
// Data.......: 03/11/2014
// Descricao..: Consulta lotes aglutinados por NF
//
// Historico de alteracoes:

// ----------------------------------------------------------------------
user function VA_LtNF (_sNF, _sSerie)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	u_logIni ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D2_LOCAL AS ALMOX, D2_COD AS PRODUTO, B1_DESC AS DESCRICAO,"
	_oSQL:_sQuery +=        " D2_PEDIDO AS PEDIDO, D2_LOTECTL AS LOTE_NF,"
	_oSQL:_sQuery +=        " ISNULL (ZA0_LTORIG, '') AS LOTE_ORIG, ISNULL (D3_QUANT, 0) AS QUANT"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SB1") + " SB1,"
	_oSQL:_sQuery +=              RetSqlName ("SD2") + " SD2"
	_oSQL:_sQuery +=   " LEFT JOIN " + RetSqlName ("ZA0") + " ZA0"
	_oSQL:_sQuery +=        " LEFT JOIN " + RetSqlName ("SD3") + " SD3"
	_oSQL:_sQuery +=              " ON (SD3.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=              " AND SD3.D3_FILIAL   = ZA0.ZA0_FILIAL"
	_oSQL:_sQuery +=              " AND SD3.D3_COD      = ZA0.ZA0_PRODUT"
	_oSQL:_sQuery +=              " AND SD3.D3_DOC      = ZA0.ZA0_DOCSD3"
	_oSQL:_sQuery +=              " AND SD3.D3_CF       = 'DE4'"
	_oSQL:_sQuery +=              " )"
	_oSQL:_sQuery +=         " ON (ZA0.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=         " AND ZA0.ZA0_FILIAL  = SD2.D2_FILIAL"
	_oSQL:_sQuery +=         " AND ZA0.ZA0_PEDIDO  = SD2.D2_PEDIDO"
	_oSQL:_sQuery +=         " AND ZA0.ZA0_ITEMPV  = SD2.D2_ITEMPV"
	_oSQL:_sQuery +=         " )"
	_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SD2.D2_FILIAL   = '" + xFilial("SD2") + "' "
	_oSQL:_sQuery +=    " AND SD2.D2_DOC      = '" + _sNF + "' "
	_oSQL:_sQuery +=    " AND SD2.D2_SERIE    = '" + _sSerie + "' "
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL   = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery +=    " AND SB1.B1_COD      = SD2.D2_COD"
	_oSQL:_sQuery +=  " ORDER BY D2_COD, D2_PEDIDO, D2_ITEMPV, ZA0_SQITPV"
	u_log (_oSQL:_sQuery)
//	_aRetSQL := _oSQL:Qry2Array (.T., .T.)
//	u_log (_aRetSQL)
	_oSQL:F3Array ("Lotes aglutinados na NF " + _sNF)

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
