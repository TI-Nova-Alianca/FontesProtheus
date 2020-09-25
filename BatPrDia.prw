// Programa:   BatPrDia
// Autor:      Robert Koch
// Data:       12/03/2014
// Descricao:  Envia e-mail com resumo da producao diaria.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 23/09/2015 - Robert - Pode receber como parametro a data de referencia.
// 12/04/2017 - Robert - Incluida coluna de total de perda (para OPs de reprocesso).
//

// --------------------------------------------------------------------------
user function BatPrDia (_dDtRef)
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _sMsg     := ""
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _sTitulo  := ""
	_sArqLog := procname () + '_filial_' + cFilAnt + '.log'
//	u_logId ()
//	u_logIni ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D3_OP AS OP, D3_COD AS PRODUTO, H1_DESCRI AS [LINHA ENVASE],"
	_oSQL:_sQuery +=        " B1_DESC AS DESCRICAO, SUM (D3_QUANT) AS PRODUZIDO, SUM (D3_PERDA) AS PERDA, B1_UM AS UM"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SD3" ) + " SD3,"
	_oSQL:_sQuery +=              RetSqlName( "SB1" ) + " SB1"
	_oSQL:_sQuery +=   " LEFT JOIN " + RetSqlName( "SH1" ) + " SH1 "
	_oSQL:_sQuery +=          " ON (SH1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=          " AND SH1.H1_CODIGO = B1_VALINEN "
	_oSQL:_sQuery +=          " AND SH1.H1_FILIAL = '" + xFilial("SH1") + "')"
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=    " AND B1_COD = D3_COD "
	_oSQL:_sQuery +=    " AND B1_FILIAL = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery +=    " AND B1_TIPO   IN ('PA', 'PI')"  // Por enquanto somente estes
	_oSQL:_sQuery +=    " AND SD3.D_E_L_E_T_ <> '*' "
	if valtype (_dDtRef) == 'D'
		_oSQL:_sQuery +=    " AND D3_EMISSAO = '" + dtos (_dDtRef) + "'"
	else
		_oSQL:_sQuery +=    " AND D3_EMISSAO = '" + dtos (date () - 1) + "'"
	endif
	_oSQL:_sQuery +=    " AND D3_FILIAL = '" + xFilial("SD3") + "' "
	_oSQL:_sQuery +=    " AND D3_TM = '010'"
	_oSQL:_sQuery +=    " AND D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=  " GROUP BY D3_OP, D3_COD, B1_DESC, B1_UM ,H1_DESCRI"
	_oSQL:_sQuery +=  " ORDER BY H1_DESCRI, B1_DESC"
	//u_log (_oSQL:_sQuery)
	if len (_oSQL:Qry2Array (.F., .T.)) > 1
		_sTitulo = 'Apontamento de producao - Data ' + dtoc (date () - 1) + ' - ' + sm0 -> m0_filial
		_sMsg = _oSQL:Qry2HTM (_sTitulo, NIL, "", .F., .T.)
		//u_log (_sMsg)
		U_ZZUNU ({'026'}, _sTitulo, _sMsg, .F., cEmpAnt, cFilAnt)
	endif

	U_ML_SRArea (_aAreaAnt)
	_sArqLog = _sArqLog2
Return .T. 
