// Programa...: VA_RUSCA
// Autor......: Robert Koch
// Data.......: 27/01/2012
// Descricao..: Consulta de aglutinacoes de cargas.
//
// Historico de alteracoes:
// 22/04/2013 - Robert - Criada possibilidade de retornar string com as cargas relacionadas.
//

// --------------------------------------------------------------------------
User Function VA_RusCA (_nQual, _lRetCarg)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _sCargas   := ""

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. _nQual == 1 .and. ! sze -> ze_aglutin $ 'D/O'
		u_help ("Esta nao e´ uma carga aglutinada / aglutinadora",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. _nQual == 1
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT CASE WHEN SZE.ZE_CARGA = ZZD.ZZD_CARORI THEN 'Aglutinada'"
		_oSQL:_sQuery +=             " WHEN SZE.ZE_CARGA = ZZD.ZZD_CARDES THEN 'Aglutinadora'"
		_oSQL:_sQuery +=             " ELSE ''"
		_oSQL:_sQuery +=        " END AS TIPO_CARGA, "
		_oSQL:_sQuery +=        " SZE.ZE_CARGA AS CARGA,"
		_oSQL:_sQuery +=        " ZZD.ZZD_ITORI AS ITEM,"
		_oSQL:_sQuery +=        " SUBSTRING (SZE.ZE_DATA, 7, 2) + '/' + SUBSTRING (SZE.ZE_DATA, 5, 2) + '/' + SUBSTRING (SZE.ZE_DATA, 1, 4) AS DATA,"
		_oSQL:_sQuery +=        " SZE.ZE_HORA AS HORA"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SZE") + " SZE, "
		_oSQL:_sQuery +=            RetSQLName ("ZZD") + " ZZD "
		_oSQL:_sQuery += " WHERE SZE.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZD.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SZE.ZE_FILIAL  = '" + xfilial ("SZE") + "'"
		_oSQL:_sQuery +=   " AND ZZD.ZZD_FILIAL = '" + xfilial ("ZZD") + "'"
		_oSQL:_sQuery +=   " AND SZE.ZE_SAFRA   = '" + sze -> ze_safra + "'"
		_oSQL:_sQuery +=   " AND ZZD.ZZD_SAFRA  = '" + sze -> ze_safra + "'"
		if sze -> ze_aglutin == 'D'
			_oSQL:_sQuery +=   " AND ZZD.ZZD_CARDES = '" + sze -> ze_carga + "'"
			_oSQL:_sQuery +=   " AND SZE.ZE_CARGA   = ZZD.ZZD_CARORI"
		elseif sze -> ze_aglutin == 'O'
			_oSQL:_sQuery +=   " AND ZZD.ZZD_CARORI = '" + sze -> ze_carga + "'"
			_oSQL:_sQuery +=   " AND SZE.ZE_CARGA   = ZZD.ZZD_CARDES"
		endif
		u_log (_oSQL:_sQuery)
		if _lRetCarg
			_sCargas = _oSQL:Qry2Str (2, '/')
		else
			U_F3Array (_oSQL:Qry2Array (.T., .T.), 'Aglutinacao de cargas', NIL, NIL, NIL, '', '', .F., '')
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _sCargas
