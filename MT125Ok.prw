// Programa: MT125Ok
// Autor:    Robert Koch
// Data:     13/08/2012
// Funcao:   PE 'Tudo OK' na manutencao de contratos de parceria.
//           Criado inicialmente para validacao dos campos ref. obra unidade Flores da Cunha.
//
// Historico de alteracoes:
// 06/09/2012 - Robert - Considerava duas vezes o contrato atual na verificacao de saldos PIF.
//

// --------------------------------------------------------------------------
user function MT125Ok ()
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	private _sArqLog := U_NomeLog ()

	if _lRet
		_lRet = _ValObra ()
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet



// --------------------------------------------------------------------------
// Validacoes ref. obra unidade Flores da Cunha.
static function _ValObra ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _aSaldos  := 0
	local _aCpos    := {'C3_VAZZG', 'C3_VAZZGC', 'C3_VAZZG2', 'C3_VAFCOBR', 'C3_VAMTINV'}
	local _nCpo     := 0
	local _sMsg     := ""
	local _nLinha   := 0
	local _n        := N

	if _lRet
		for N = 1 to len (aCols)
			if ! GDDeleted ()
				if GDFieldGet ("C3_VAOBRA") == 'S'
					for _nCpo = 1 to len (_aCpos)
						if empty (GDFieldGet (_aCpos [_nCpo]))
							_sMsg += "Campo '" + alltrim (RetTitle (_aCpos [_nCpo])) + "' deve ser informado para contratos da obra." + chr (13) + chr (10)
						endif
					next
				else
					for _nCpo = 1 to len (_aCpos)
						if !empty (GDFieldGet (_aCpos [_nCpo]))
							_sMsg += "Campo '" + alltrim (RetTitle (_aCpos [_nCpo])) + "' somente deve ser informado para contratos da obra." + chr (13) + chr (10)
						endif
					next
				endif
				if ! empty (_sMsg)
					u_help ("Erro no item " + GDFieldGet ("C3_ITEM") + ":" + chr (13) + chr (10) + _sMsg)
					_lRet = .F.
					exit
				endif

				// Verifica limites PIF
				if _lRet .and. ! empty (GDFieldGet ("C3_VAZZG")) .and. ! empty (GDFieldGet ("C3_VAZZGC"))
					CursorWait ()
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT ISNULL (SUM (CASE V.ORIGEM WHEN 'ZZG' THEN VALOR ELSE 0 END), 0) AS PREVISTO,"
					_oSQL:_sQuery +=        " ISNULL (SUM (CASE V.ORIGEM WHEN 'SC3' THEN VALOR ELSE 0 END), 0) AS REALIZADO"
					_oSQL:_sQuery +=   " FROM VA_OBRA_SALDOS1 V"
					_oSQL:_sQuery +=  " WHERE V.PLANO          = '1'"
					_oSQL:_sQuery +=    " AND V.ITEM_PLANO     = '" + GDFieldGet ("C3_VAZZG") + "'"
					_oSQL:_sQuery +=    " AND V.CONTRATO_PLANO = '" + GDFieldGet ("C3_VAZZGC") + "'"
					_oSQL:_sQuery +=    " AND V.ORIGEM         IN ('ZZG', 'SC3')"
					_oSQL:_sQuery +=    " AND V.CONTR_PARCERIA != '" + ca125Num + "'"
					u_log (_oSQL:_sQuery)
					_aSaldos = _oSQL:Qry2Array (.F., .F.)
					
					// Verifica se outros itens deste contrato estao usando a mesma combinacao de PIF x contrato.
					for _nLinha = 1 to len (aCols)
						if _nLinha != N .and. GDFieldGet ("C3_VAZZG", _nLinha) == GDFieldGet ("C3_VAZZG", N) .and. GDFieldGet ("C3_VAZZGC", _nLinha) == GDFieldGet ("C3_VAZZGC", N)
							_aSaldos [1, 2] += GDFieldGet ("C3_QUANT", _nLinha) * GDFieldGet ("C3_PRECO", _nLinha)
						endif
					next
					
					CursorArrow ()
					if _aSaldos [1, 1] < _aSaldos [1, 2] + GDFieldGet ("C3_QUANT") * GDFieldGet ("C3_PRECO")
						u_help ("Erro no item " + GDFieldGet ("C3_ITEM") + ": valor excede o saldo previsto para esta combinacao PIF x Contrato." + chr (13) + chr (10) + ;
						        "Saldo previsto: " + alltrim (transform (_aSaldos [1, 1], "@E 999,999,999.99")) + chr (13) + chr (10) + ;
						        "Saldo ja usado: " + alltrim (transform (_aSaldos [1, 2], "@E 999,999,999.99")) + chr (13) + chr (10) + ;
						        "Valor do item em questao:  " + alltrim (transform (GDFieldGet ("C3_QUANT") * GDFieldGet ("C3_PRECO"), "@E 999,999,999.99")) + chr (13) + chr (10) + chr (13) + chr (10) + ;
						        "* Saldo ja usado = outros contratos e outros itens deste mesmo contrato")
						_lRet = .F.
					endif
				endif
			endif
		next
	endif

	N := _n
return _lRet
