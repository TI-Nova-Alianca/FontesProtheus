// Programa:  CV1Ctas
// Autor:     Robert Koch
// Data:      29/02/2016
// Descricao: Insere contas nos itens de orcamentos (tabela CV1).
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
user function CV1Ctas ()
	local _oSQL      := NIL
	local _sOrig     := ''
	local _sOrcmto   := ''
	local _sDescri   := ''
	local _sCalend   := ''
	local _sMoeda    := ''
	local _sRevisa   := ''
	local _sNovaRev  := ''
	local _nCampo    := 0
	local _sCampo    := ''
	local _lContinua := .T.
	local _sAno      := ""
	local _nMes      := 0
	local _sMes      := ""
	local _sSeq      := ''
	private cPerg := "CV1ITE"

	u_logId ()
	u_logIni ()
	_ValidPerg ()
	
	if _lContinua
		if ! Pergunte (cPerg, .T.)
			_lContinua = .F.
		endif
	endif

	// Estou assumindo que vai ser orcado sempre 12 meses.
	if _lContinua .and. year (mv_par05) != year (mv_par06)
		u_help ("Data final deve estar no mesmo ano da data inicial.")
		_lContinua = .F.
	endif

	if _lContinua
		_sOrcmto = cv2 -> cv2_orcmto
		_sDescri = cv2 -> cv2_descri
		_sCalend = cv2 -> cv2_calend
		_sMoeda  = cv2 -> cv2_moeda
		_sRevisa = cv2 -> cv2_revisa
/*
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT CV1_FILIAL, CV1_ORCMTO, CV1_CALEND, CV1_MOEDA, CV1_REVISA, CV1_SEQUEN, CV1_CT1INI, CV1_CTTINI"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV1") + " CV1 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND CV1_FILIAL = '" + xfilial ("CV1") + "'"
		_oSQL:_sQuery +=   " AND CV1_ORCMTO = '" + _sOrcmto + "'"
		_oSQL:_sQuery +=   " AND CV1_CALEND = '" + _sCalend + "'"
		_oSQL:_sQuery +=   " AND CV1_MOEDA  = '" + _sMoeda  + "'"
		_oSQL:_sQuery +=   " AND CV1_REVISA = '" + _sRevisa + "'"
		_oSQL:_sQuery += " ORDER BY CV1_CT1INI, CV1_CTTINI"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb ()
		u_log ((_sAliasQ), .t.)
*/		
		// Cria nova revisao para o orcamento.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT MAX (CV2_REVISA)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV2") + " CV2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND CV2_FILIAL = '" + xfilial ("CV2") + "'"
		_oSQL:_sQuery +=   " AND CV2_ORCMTO = '" + _sOrcmto + "'"
		_oSQL:_sQuery +=   " AND CV2_CALEND = '" + _sCalend + "'"
		_oSQL:_sQuery +=   " AND CV2_MOEDA  = '" + _sMoeda  + "'"
		_oSQL:Log ()
		_sNovaRev = soma1 (_oSQL:RetQry ())
		reclock ("CV2", .T.)
		cv2 -> cv2_filial = xfilial ("CV2")
		cv2 -> cv2_orcmto = _sOrcmto
		cv2 -> cv2_descri = _sDescri
		cv2 -> cv2_status = '1'  // 1=Aberto;2=Gerado Saldo;3=Revisado
		cv2 -> cv2_calend = _sCalend
		cv2 -> cv2_moeda  = _sMoeda
		cv2 -> cv2_revisa = _sNovaRev
		cv2 -> cv2_aprova = cUserName
		msunlock ()
		
		// Copia detalhes da revisao original.
//		(_sAliasQ) -> (dbgotop ())
//		do while ! (_sAliasQ) -> (eof ())
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT *"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV1") + " CV1 "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND CV1_FILIAL = '" + xfilial ("CV1") + "'"
			_oSQL:_sQuery +=   " AND CV1_ORCMTO = '" + _sOrcmto + "'"
			_oSQL:_sQuery +=   " AND CV1_CALEND = '" + _sCalend + "'"
			_oSQL:_sQuery +=   " AND CV1_MOEDA  = '" + _sMoeda  + "'"
			_oSQL:_sQuery +=   " AND CV1_REVISA = '" + _sRevisa + "'"
			_oSQL:_sQuery +=   " ORDER BY CV1_PERIOD"
//			_oSQL:Log ()
			_sOrig = _oSQL:Qry2Trb (.T.)
			u_logtrb (_sOrig, .T.)
//			_sSeq = '0001'
			(_sOrig) -> (dbgotop ())
			do while ! (_sOrig) -> (eof ())
				reclock ("CV1", .T.)
				for _nCampo = 1 to cv1 -> (fcount ())
					_sCampo = cv1 -> (fieldname (_nCampo))
//					if alltrim (upper (_sCampo)) == 'CV1_SEQUEN'
//						cv1 -> &(_sCampo) = _sSeq
					if alltrim (upper (_sCampo)) == 'CV1_REVISA'
						cv1 -> &(_sCampo) = _sNovaRev
					else 
						cv1 -> &(_sCampo) = (_sOrig) -> &(_sCampo)
					endif
				next
				msunlock ()
//				_sSeq = soma1 (_sSeq)
				(_sOrig) -> (dbskip ())
			enddo
	
//			(_sAliasQ) -> (dbskip ())
//		enddo

		// Busca contas movimentadas em determinado periodo e adiciona-as 
		dbselectarea ("CT3")
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT CT3_CONTA, CT1_DESC01, CT3_CUSTO, "
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '01' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES01,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '02' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES02,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '03' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES03,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '04' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES04,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '05' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES05,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '06' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES06,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '07' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES07,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '08' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES08,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '09' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES09,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '10' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES10,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '11' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES11,"
		_oSQL:_sQuery +=        " SUM (CASE WHEN SUBSTRING (CT3_DATA, 5, 2) = '12' THEN CT3_DEBITO - CT3_CREDIT ELSE 0 END) AS MES12"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("CT3") + " CT3, "
		_oSQL:_sQuery +=              RetSQLName ("CT1") + " CT1 "
		_oSQL:_sQuery +=  " WHERE CT1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND CT1.CT1_FILIAL = '" + xfilial ("CT1") + "'"
		_oSQL:_sQuery +=    " AND CT1.CT1_CONTA  = CT3.CT3_CONTA"
		_oSQL:_sQuery +=    " AND CT3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND CT3.CT3_FILIAL = '" + xfilial ("CT3") + "'"
		_oSQL:_sQuery +=    " AND CT3.CT3_CONTA  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_oSQL:_sQuery +=    " AND CT3.CT3_CUSTO  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_oSQL:_sQuery +=    " AND CT3.CT3_DATA   BETWEEN '" + dtos (mv_par05) + "' AND '" + dtos (mv_par06) + "'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("CV1") + " CV1 "
		_oSQL:_sQuery +=                     " WHERE CV1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=                       " AND CV1.CV1_FILIAL = '" + xfilial ("CV1") + "'"
		_oSQL:_sQuery +=                       " AND CV1.CV1_CT1INI = CT3.CT3_CONTA"
		_oSQL:_sQuery +=                       " AND CV1.CV1_ORCMTO = '" + _sOrcmto  + "'"
		_oSQL:_sQuery +=                       " AND CV1.CV1_CALEND = '" + _sCalend  + "'"
		_oSQL:_sQuery +=                       " AND CV1.CV1_MOEDA  = '" + _sMoeda   + "'"
		_oSQL:_sQuery +=                       " AND CV1.CV1_REVISA = '" + _sNovaRev + "')"
		_oSQL:_sQuery +=   " GROUP BY CT3_CONTA, CT1_DESC01, CT3_CUSTO"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.T.)
	
		// Busca proxima sequencia
		if ! (_sAliasQ) -> (eof ())
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT MAX (CV1_SEQUEN)"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV1") + " CV1 "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND CV1_FILIAL = '" + xfilial ("CV1") + "'"
			_oSQL:_sQuery +=   " AND CV1_ORCMTO = '" + _sOrcmto  + "'"
			_oSQL:_sQuery +=   " AND CV1_CALEND = '" + _sCalend  + "'"
			_oSQL:_sQuery +=   " AND CV1_MOEDA  = '" + _sMoeda   + "'"
			_oSQL:_sQuery +=   " AND CV1_REVISA = '" + _sNovaRev + "'"
			_oSQL:Log ()
			_sSeq = soma1 (_oSQL:RetQry ())
		endif
		
		// Busca o ano.
		_sAno = fBuscaCpo ('CTG', 1, xfilial ("CTG") + _sCalend, "CTG_EXERC")  // CTG_FILIAL+CTG_CALEND+CTG_EXERC+CTG_PERIOD

	/*
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			u_log ('Criando seq =', _sSeq, '  para a conta', (_sAliasQ) -> ct3_conta)
			for _nMes = 1 to 12
				_sMes = strzero (_nMes, 2)
				reclock ("CV1", .T.)
				cv1 -> cv1_filial = xfilial ("CV1")
				cv1 -> cv1_orcmto = _sOrcmto
				cv1 -> cv1_descri = cv2 -> cv2_descri
				cv1 -> cv1_status = '1'
				cv1 -> cv1_calend = _sCalend
				cv1 -> cv1_moeda  = _sMoeda
				cv1 -> cv1_revisa = _sNovaRev
				cv1 -> cv1_sequen = _sSeq
				cv1 -> cv1_ct1ini = (_sAliasQ) -> ct3_conta
				cv1 -> cv1_ct1fim = (_sAliasQ) -> ct3_conta
				cv1 -> cv1_cttini = (_sAliasQ) -> ct3_custo
				cv1 -> cv1_cttfim = (_sAliasQ) -> ct3_custo
				cv1 -> cv1_vadesc = (_sAliasQ) -> ct1_desc01
				cv1 -> cv1_period = strzero (_nMes, 2)
				cv1 -> cv1_dtini  = stod (_sAno + _sMes + '01') 
				cv1 -> cv1_dtfim  = lastday (stod (_sAno + _sMes + '01'))
				cv1 -> cv1_valor  = ABS ((_sAliasQ) -> &('MES' + _sMes))  // NAO SEI SE O ERRO EH POR CAUSA DOS NEGATIVOS.
				cv1 -> cv1_aprova = cUserName
				msunlock ()
			next
			_sSeq = soma1 (_sSeq)
			(_sAliasQ) -> (dbskip ())
		enddo
*/
		u_help ("Revisao gerada: '" + _sNovaRev + "'.")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Conta inicial                 ", "C", 20, 0,  "",   "CT1   ", {},                                  ""})
	aadd (_aRegsPerg, {02, "Conta final                   ", "C", 20, 0,  "",   "CT1   ", {},                                  ""})
	aadd (_aRegsPerg, {03, "CC inicial                    ", "C", 9,  0,  "",   "CTT   ", {},                                  ""})
	aadd (_aRegsPerg, {04, "CC final                      ", "C", 9,  0,  "",   "CTT   ", {},                                  ""})
	aadd (_aRegsPerg, {05, "Data inicial                  ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {06, "Data final                    ", "D", 8,  0,  "",   "      ", {},                                  ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
