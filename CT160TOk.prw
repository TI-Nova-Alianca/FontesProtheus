// Programa:  CT160TOk
// Autor:     Robert Koch
// Data:      31/03/2016
// Descricao: P.E. 'Tudo OK' da tela de consultas gerenciais da contabilidade.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function CT160TOK ()
	local _aAmbAnt   := U_SalvaAmb ()
	private _lRet      := .T.

	processa ({|| _lRet := _Sobrepos ()})
	U_SalvaAmb (_aAmbAnt)
return _lRet


// --------------------------------------------------------------------------
// Verifica sobreposicao de contas / CC no mesmo plano.
static function _Sobrepos ()
	local _oSQL      := NIL
	local _sSobrep   := ""
	local _aSobrep   := {}
	local _nLinha    := 0
	local _n		 := 0
	private aHeader  := aclone (oGDItens:aHeader)
	private aCols    := aclone (oGDItens:aCols)
	private N        := oGDItens:nAt

	for _n = 1 to len (aCols)
		N := _n
		if ! GDDeleted () .and. ! empty (GDFieldGet ("CTS_CT1INI")) .and. ! empty (GDFieldGet ("CTS_CT1INI"))
			
			// Verifica sobreposicao entre as linhas desta 'ordem'.
			for _nLinha = 1 to len (aCols)
				if _nLinha != N .and. ! GDDeleted (_nLinha)

					// Verifica sobreposicao de conta
					if   ((GDFieldGet ("CTS_CT1INI", _nLinha) <= GDFieldGet ("CTS_CT1INI") .and. GDFieldGet ("CTS_CT1FIM", _nLinha) >= GDFieldGet ("CTS_CT1INI")) ;
					.or.  (GDFieldGet ("CTS_CT1FIM", _nLinha) >= GDFieldGet ("CTS_CT1INI") .and. GDFieldGet ("CTS_CT1INI", _nLinha) <= GDFieldGet ("CTS_CT1FIM")) ;
					.or.  (GDFieldGet ("CTS_CT1INI", _nLinha) <= GDFieldGet ("CTS_CT1FIM") .and. GDFieldGet ("CTS_CT1INI", _nLinha) >= GDFieldGet ("CTS_CT1FIM"))) ;
					.and.((GDFieldGet ("CTS_CTTINI", _nLinha) <= GDFieldGet ("CTS_CTTINI") .and. GDFieldGet ("CTS_CTTFIM", _nLinha) >= GDFieldGet ("CTS_CTTINI")) ;
					.or.  (GDFieldGet ("CTS_CTTFIM", _nLinha) >= GDFieldGet ("CTS_CTTINI") .and. GDFieldGet ("CTS_CTTINI", _nLinha) <= GDFieldGet ("CTS_CTTFIM")) ;
					.or.  (GDFieldGet ("CTS_CTTINI", _nLinha) <= GDFieldGet ("CTS_CTTFIM") .and. GDFieldGet ("CTS_CTTINI", _nLinha) >= GDFieldGet ("CTS_CTTFIM")))
						u_help ("Linha '" + GDFieldGet ("CTS_LINHA") + "': Sobreposicao da linha " + GDFieldGet ("CTS_LINHA", _nLinha))
						_lRet = .F.
						exit
					endif
				endif
			next

			// Verifica sobreposicao com outras ordens do plano.
			if _lRet
				// Verifica sobreposicao de conta
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT top 1 CTS_ORDEM + ' / ' + CTS_LINHA"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("CTS")"
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_  = ''"
				_oSQL:_sQuery +=    " AND CTS_FILIAL  = '" + xfilial ("CTS") + "'"
				_oSQL:_sQuery +=    " AND CTS_CODPLA  = '" + m->cts_codpla + "'"
				_oSQL:_sQuery +=    " AND CTS_ORDEM  != '" + m->cts_ordem  + "'"
				_oSQL:_sQuery +=    " AND ((CTS_CT1INI <= '" + GDFieldGet ("CTS_CT1INI") + "' AND CTS_CT1FIM >= '" + GDFieldGet ("CTS_CT1INI") + "')"
				_oSQL:_sQuery +=     " OR  (CTS_CT1FIM >= '" + GDFieldGet ("CTS_CT1INI") + "' AND CTS_CT1INI <= '" + GDFieldGet ("CTS_CT1FIM") + "')"
				_oSQL:_sQuery +=     " OR  (CTS_CT1INI <= '" + GDFieldGet ("CTS_CT1FIM") + "' AND CTS_CT1INI >= '" + GDFieldGet ("CTS_CT1FIM") + "'))"
				_oSQL:_sQuery +=    " AND ((CTS_CTTINI <= '" + GDFieldGet ("CTS_CTTINI") + "' AND CTS_CTTFIM >= '" + GDFieldGet ("CTS_CTTINI") + "')"
				_oSQL:_sQuery +=     " OR  (CTS_CTTFIM >= '" + GDFieldGet ("CTS_CTTINI") + "' AND CTS_CTTINI <= '" + GDFieldGet ("CTS_CTTFIM") + "')"
				_oSQL:_sQuery +=     " OR  (CTS_CTTINI <= '" + GDFieldGet ("CTS_CTTFIM") + "' AND CTS_CTTINI >= '" + GDFieldGet ("CTS_CTTFIM") + "'))"
//				_oSQL:Log ()
				_sSobrep = _oSQL:RetQry ()
				if ! empty (_sSobrep)
					u_help ("Linha '" + GDFieldGet ("CTS_LINHA") + "': Sobreposicao da ordem/linha " + _sSobrep)
					_lRet = .F.
					exit
				endif
			endif
		endif
	next
return _lRet
