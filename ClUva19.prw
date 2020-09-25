// Programa:  ClUva19
// Autor:     Robert Koch
// Data:      15/01/2019
// Descricao: Determina a classificacao das uvas viniferas para a safra 2019.
//
// Historico de alteracoes:
// 25/01/2019 - Robert - Ajustes materiais estranhos para uvas latadas.
//

// --------------------------------------------------------------------------
user function ClUva19 (_sVaried, _nGrau, _sConduc, _nPBotryt, _nPGlomer, _nPAsperg, _nPPodrAc, _nAcidVol, _sMatEstr, _nPDesunif)
	local _lContinua   := .T.
	local _aAreaAnt    := U_ML_SRArea ()
	local _nSomaPodr   := _nPBotryt + _nPGlomer + _nPAsperg + _nPPodrAc
	local _sMtEstrOK   := 'AUSENTE,MINIMO,MUITO BAIXO,BAIXO,MEDIO,ALTO'
	local _oSQL        := NIL
	local _aTab17      := {}
	local _sPrm02 := ''
	local _sPrm03 := ''
	local _sPrm04 := ''
	local _sPrm05 := ''
	local _sPrm99 := ''
	local _aRet := {}
//	private _aRet := {'', ''}
//	private _sConduc   := _sSistCond

	//u_logIni ()
	//u_log (_sVaried, _nGrau, _sConduc, _nPBotryt, _nPGlomer, _nPAsperg, _nPPodrAc, _nAcidVol, _sMatEstr, _nPDesunif)

	_sMatEstr = upper (U_NoAcento (alltrim (_sMatEstr)))
	if _lContinua .and. ! empty (_sMatEstr) .and. ! _sMatEstr $ _sMtEstrOK
		u_help ("Parametro de presenca de materiais estranho: recebi '" + _sMatEstr + "', mas os valores permitidos sao: " + _sMtEstrOK)
		_lContinua = .F.
	endif

	if _lContinua
//		u_log ('Variedade..................:', _sVaried, fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sVaried, "B1_DESC"))
//		u_log ('Grau.......................:', _nGrau)
//		u_log ('Sistema de conducao........:', _sConduc)
//		u_log ('% botrytis.................:', _nPBotryt)
//		u_log ('% glomerella...............:', _nPGlomer)
//		u_log ('% aspergillus..............:', _nPAsperg)
//		u_log ('% podridao acida...........:', _nPPodrAc)
//		u_log ('% soma de podridoes........:', _nSomaPodr)
//		u_log ('% acidez volatil...........:', _nAcidVol)
//		u_log ('materiais estranhos........:', _sMatEstr)
//		u_log ('% desuniformidade maturacao:', _nPDesunif)
	endif

	if _lContinua

		if _sConduc == 'L'
		
			// Nas latadas nao se considera grau para gerar classificacao.
			_sPrm02 = 'B'
			
			// Define classificacao por sanidade
			if _nSomaPodr < 5 .and. _nAcidVol < 20
				_sPrm03 = 'A'
			elseif _nSomaPodr >= 5 .and. _nSomaPodr < 20 .and. _nAcidVol < 20
				_sPrm03 = 'B'
//			elseif _nSomaPodr > 20 .or. _nAcidVol >= 20
			elseif _nSomaPodr >= 20 .or. _nAcidVol >= 20
				_sPrm03 = 'D'
			else
				u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por sanidade.   Soma de podridoes: " + cvaltochar (_nSomaPodr) + "   Acidez volatil: " + cvaltochar (_nAcidVol))
			endif
	
			// Nas latadas nao se considera uniformidade de maturacao
			_sPrm04 = 'B'
	
			// Define classificacao por presenca de materiais estranhos
			if _sMatEstr $ 'AUSENTE/MINIMO/MUITO BAIXO/BAIXO'
				_sPrm05 = 'A'
			elseif _sMatEstr == 'MEDIO'
				_sPrm05 = 'B'
			elseif _sMatEstr == 'ALTO'
				_sPrm05 = 'D'
			else
				u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por presenca de materiais estranhos.")
			endif

		elseif _lContinua .and. _sConduc == 'E'
	
			// Define classificacao por grau.
//			if _nGrau > 0
	
				// Verifica limites de grau para esta variedade.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID, ZX5_17GIDS"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_17 "
				_oSQL:_sQuery += " WHERE ZX5_17.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZX5_17.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
				_oSQL:_sQuery +=   " AND ZX5_17.ZX5_TABELA = '17'"
				_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17SAFR = '2019'"
				_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17PROD = '" + _sVaried + "'"
				//_oSQL:Log ()
				_aTab17 = aclone (_oSQL:Qry2Array (.F., .F.))
				//u_log (_aTab17)
				if len (_aTab17) == 0
					u_help ("Variedade '" + _sVaried + "' nao localizada na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.")
				elseif len (_aTab17) > 1
					u_help ("Variedade '" + _sVaried + "' aparece mais de uma vez na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.")
				else
					if _nGrau >= val (_aTab17 [1, 1])
						_sPrm02 = 'PR'
					elseif _nGrau >= val (_aTab17 [1, 2])
						_sPrm02 = 'AA'
					elseif _nGrau >= val (_aTab17 [1, 3])
						_sPrm02 = 'A'
					elseif _nGrau >= val (_aTab17 [1, 4])
						_sPrm02 = 'B'
					elseif _nGrau >= val (_aTab17 [1, 5])
						_sPrm02 = 'C'
					elseif _nGrau >= val (_aTab17 [1, 6])
						_sPrm02 = 'D'
					elseif _nGrau >= val (_aTab17 [1, 7])
						_sPrm02 = 'DS'
					else
						u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por grau.")
					endif
				endif
//			endif
	
			// Define classificacao por sanidade
			if _nSomaPodr == 0 .and. _nAcidVol < 20
				_sPrm03 = 'PR'
			elseif _nSomaPodr > 0 .and. _nSomaPodr < 3 .and. _nAcidVol < 20
				_sPrm03 = 'B'
			elseif _nSomaPodr >= 3 .and. _nSomaPodr < 6 .and. _nAcidVol < 20
				_sPrm03 = 'C'
			elseif _nSomaPodr >= 6 .and. _nSomaPodr < 12 .and. _nAcidVol < 20
				_sPrm03 = 'D'
			elseif _nSomaPodr > 12 .or. _nAcidVol >= 20
				_sPrm03 = 'DS'
			else
				u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por sanidade.   Soma de podridoes: " + cvaltochar (_nSomaPodr) + "   Acidez volatil: " + cvaltochar (_nAcidVol))
			endif
	
			// Define classificacao por uniformidade de maturacao.
			if _nPDesunif == 0
				_sPrm04 = 'PR'
			elseif _nPDesunif > 0 .and. _nPDesunif < 3
				_sPrm04 = 'A'
			elseif _nPDesunif >= 3 .and. _nPDesunif < 6
				_sPrm04 = 'B'
			elseif _nPDesunif >= 6 .and. _nPDesunif < 12
				_sPrm04 = 'C'
			elseif _nPDesunif >= 12 .and. _nPDesunif < 25
				_sPrm04 = 'D'
			elseif _nPDesunif > 25
				_sPrm04 = 'DS'
			else
				u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por desuniformidade de maturacao.")
			endif
	
			// Define classificacao por presenca de materiais estranhos
			if _sMatEstr == 'AUSENTE'
				_sPrm05 = 'PR'
			elseif _sMatEstr == 'MINIMO'
				_sPrm05 = 'A'
			elseif _sMatEstr == 'MUITO BAIXO'
				_sPrm05 = 'B'
			elseif _sMatEstr == 'BAIXO'
				_sPrm05 = 'C'
			elseif _sMatEstr == 'MEDIO'
				_sPrm05 = 'D'
			elseif _sMatEstr == 'ALTO'
				_sPrm05 = 'DS'
			else
				if ! empty (_sMatEstr)
					u_help ("Sistema de conducao '" + _sConduc + "': sem definicao de classificacao por presenca de materiais estranhos.")
				endif
			endif
	
		else
			u_help ("Sem tratamento para sistema de conducao '" + _sConduc + "'")
		endif
	endif

	if _lContinua
		_sPrm99 = U_ClassUva (_sConduc, _sPrm02, _sPrm03, _sPrm04, _sPrm05)
		_aRet = {_sPrm02, _sPrm03, _sPrm04, _sPrm05, _sPrm99}
	else
		_aRet = {'', '', '', '', ''}
	endif
	//u_log (_aRet)
	
	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return _aRet



/*
	if _lContinua .and. _sConduc == 'L'
		// Inicia com a melhor classificacao e vai reduzindo conforme encontra inconformidades.
		_aRet = {'A', ''}
		if _nSomaPodr >= 5 .and. _nSomaPodr <= 20
			_Reduz ('B', 'podridoes')
		endif
		if _nSomaPodr > 20
			_Reduz ('D', 'podridoes')
		endif
		if _nAcidVol >= 20
			_Reduz ('D', 'acidez volatil')
		endif
		if _sMatEstr == 'MEDIO'
			_Reduz ('B', 'materiais estranhos')
		endif
		if _sMatEstr == 'ALTO'
			_Reduz ('D', 'materiais estranhos')
		endif

	elseif _lContinua .and. _sConduc == 'E'
		// Inicia com a melhor classificacao e vai reduzindo conforme encontra inconformidades.
		_aRet = {'PR', ''}
		if _nSomaPodr > 0 .and. _nSomaPodr < 3
			_Reduz ('B', 'podridoes')
		endif
		if _nSomaPodr >= 3 .and. _nSomaPodr < 6
			_Reduz ('C', 'podridoes')
		endif
		if _nSomaPodr >= 6 .and. _nSomaPodr < 12
			_Reduz ('D', 'podridoes')
		endif
		if _nSomaPodr > 12
			_Reduz ('DS', 'podridoes')
		endif
		if _nAcidVol >= 20
			_Reduz ('DS', 'materiais estranhos')
		endif
		if _sMatEstr == 'MINIMO'
			_Reduz ('A', 'materiais estranhos')
		endif
		if _sMatEstr == 'MUITO BAIXO'
			_Reduz ('B', 'materiais estranhos')
		endif
		if _sMatEstr == 'BAIXO'
			_Reduz ('C', 'materiais estranhos')
		endif
		if _sMatEstr == 'MEDIO'
			_Reduz ('D', 'materiais estranhos')
		endif
		if _sMatEstr == 'ALTO'
			_Reduz ('DS', 'materiais estranhos')
		endif
		if _nPDesunif > 0 .and. _nPDesunif < 3
			_Reduz ('A', 'desuniformidade de maturacao')
		endif
		if _nPDesunif >= 3 .and. _nPDesunif < 6
			_Reduz ('B', 'desuniformidade de maturacao')
		endif
		if _nPDesunif >= 6 .and. _nPDesunif < 12
			_Reduz ('C', 'desuniformidade de maturacao')
		endif
		if _nPDesunif >= 12 .and. _nPDesunif < 25
			_Reduz ('D', 'desuniformidade de maturacao')
		endif
		if _nPDesunif >25
			_Reduz ('DS', 'desuniformidade de maturacao')
		endif

		// Verifica limites de grau para esta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID, ZX5_17GIDS"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_17 "
		_oSQL:_sQuery += " WHERE ZX5_17.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_TABELA = '17'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17SAFR = '2019'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17PROD = '" + _sVaried + "'"
//		_oSQL:Log ()
		_aTab17 = aclone (_oSQL:Qry2Array (.F., .F.))
		u_log (_aTab17)
		if len (_aTab17) == 0
			u_help ("Variedade '" + _sVaried + "' nao localizada na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.")
			_lContinua = .F.
		elseif len (_aTab17) > 1
			u_help ("Variedade '" + _sVaried + "' aparece mais de uma vez na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.")
			_lContinua = .F.
		else
			if _aRet [1] == 'PR' .and. _nGrau < val (_aTab17 [1, 1])
				_Reduz ('AA', 'grau abaixo de ' + _aTab17 [1, 1])
			endif
			if _aRet [1] == 'AA' .and. _nGrau < val (_aTab17 [1, 2])
				_Reduz ('A', 'grau abaixo de ' + _aTab17 [1, 2])
			endif
			if _aRet [1] == 'A' .and. _nGrau < val (_aTab17 [1, 3])
				_Reduz ('B', 'grau abaixo de ' + _aTab17 [1, 3])
			endif
			if _aRet [1] == 'B' .and. _nGrau < val (_aTab17 [1, 4])
				_Reduz ('C', 'grau abaixo de ' + _aTab17 [1, 4])
			endif
			if _aRet [1] == 'C' .and. _nGrau < val (_aTab17 [1, 5])
				_Reduz ('D', 'grau abaixo de ' + _aTab17 [1, 5])
			endif
			if _aRet [1] == 'D' .and. _nGrau < val (_aTab17 [1, 6])
				_Reduz ('DS', 'grau abaixo de ' + _aTab17 [1, 6])
			endif
			if _aRet [1] == 'DS' .and. _nGrau < val (_aTab17 [1, 7])
				_aRet = {'', 'Grau abaixo do aceitavel para DS: ' + _aTab17 [1, 7]}
			endif
		endif

	elseif _lContinua
		u_help ("Sem tratamento para sistema de conducao '" + _sConduc + "'")
	endif

	if ! _lContinua
		_aRet = {'', ''}
	endif
	u_log (_aRet)
	
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _aRet



// --------------------------------------------------------------------------
// Reduz a classificacao (se a classificacao recebida for menor que a anterior).
static function _Reduz (_sClasNova, _sMotivo)
	local _sResult := ""
	local _sClasAnt  := _aRet [1]
	
	if _sConduc == 'L'
		if _aRet [1] == 'A' .and. _sClasNova $ 'B/D'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'B' .and. _sClasNova $ 'D'
			_aRet = {_sClasNova, _sMotivo}
		endif

	elseif _sConduc == 'E'
		if _aRet [1] == 'PR' .and. _sClasNova $ 'AA/A/B/C/D/DS'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'AA' .and. _sClasNova $ 'A/B/C/D/DS'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'A' .and. _sClasNova $ 'B/C/D/DS'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'B' .and. _sClasNova $ 'C/D/DS'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'C' .and. _sClasNova $ 'D/DS'
			_aRet = {_sClasNova, _sMotivo}
		elseif _aRet [1] == 'D' .and. _sClasNova $ 'DS'
			_aRet = {_sClasNova, _sMotivo}
		endif
	endif
	u_log ('Entre', _sClasAnt, 'e', _sClasNova, 'ficou', _aRet [1], '  (' + _aRet [2] + ')')
return
*/
