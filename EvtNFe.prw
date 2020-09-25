// Programa:  EvtNFe
// Autor:     Robert Koch
// Data:      18/09/2013
// Descricao: Consulta eventos da NF-e
//
// Historico de alteracoes:
// 07/02/2014 - Passa a usar a view VA_VEVENTOS_NFE.
//

// --------------------------------------------------------------------------
user function EvtNFe (_sEntSai, _sDoc, _sSerie, _sFornece, _sLoja)
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT dbo.VA_DTOC (DATE_EVEN) AS DATA,"
	_oSQL:_sQuery +=        " TIME_EVEN AS HORA,"
	_oSQL:_sQuery +=        " RTRIM (CMOTEVEN) AS MOTIVO, "
	_oSQL:_sQuery +=        " RTRIM (DESC_EVENTO) AS DESCRI, "
	_oSQL:_sQuery +=        " RTRIM (TEXTO_CORRECAO) AS TEXTO, "
	_oSQL:_sQuery +=        " RTRIM (TEXTO_JUSTIFICATIVA) AS JUSTIF, "
	_oSQL:_sQuery +=        " PROTOCOLO"
	_oSQL:_sQuery +=   " FROM VA_VEVENTOS_NFE"
	_oSQL:_sQuery +=  " WHERE AMBIENTE = '1'"  // Producao
	if _sEntSai == 'E'
		_oSQL:_sQuery += " AND F1_FILIAL  = '" + xfilial ("SF1") + "'"
		_oSQL:_sQuery += " AND F1_DOC     = '" + _sDoc + "'"
		_oSQL:_sQuery += " AND F1_SERIE   = '" + _sSerie + "'"
		_oSQL:_sQuery += " AND F1_FORNECE = '" + _sFornece + "'"
		_oSQL:_sQuery += " AND F1_LOJA    = '" + _sLoja + "'"
	elseif _sEntSai == 'S'
		_oSQL:_sQuery += " AND F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_oSQL:_sQuery += " AND F2_DOC     = '" + _sDoc + "'"
		_oSQL:_sQuery += " AND F2_SERIE   = '" + _sSerie + "'"
	endif
	_oSQL:_sQuery +=  " ORDER BY DATE_EVEN, TIME_EVEN"
	u_log (_oSQL:_sQuery)
	_oSQL:F3Array ("Eventos da NF-e " + _sDoc)
	U_ML_SRArea (_aAreaAnt)
return

/* versao ateh 07/02/2014
user function EvtNFe (_sChave)
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
 
	if empty (_sChave)
		u_help ("Chave da NF-e nao informada, ou nao se trata de NF eletronica.")
	else
		// Possivelmente exista algum metodo da classe WSNFeSBRA, mas desconheco...
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT TPEVENTO,"
		_oSQL:_sQuery +=        " CASE TPEVENTO WHEN '110111' THEN 'CANCELAMENTO NFE'"
		_oSQL:_sQuery +=                      " WHEN '110110' THEN 'CARTA DE CORRECAO'"
		_oSQL:_sQuery +=                      " ELSE '?'"
		_oSQL:_sQuery +=        " END AS DESCRICAO,"
		_oSQL:_sQuery +=        " SEQEVENTO, DHREGEVEN, CMOTEVEN, PROTOCOLO"
		_oSQL:_sQuery +=   " FROM SPED150"
		_oSQL:_sQuery +=  " WHERE NFE_CHV = '" + _sChave + "'"
		_oSQL:_sQuery +=  " ORDER BY DHREGEVEN"
		u_showarray (_oSQL:Qry2Array (.f., .t.))
	endif
	U_ML_SRArea (_aAreaAnt)
return
*/
