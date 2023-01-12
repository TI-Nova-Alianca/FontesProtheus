// Programa:  ClUva23
// Autor:     Robert Koch
// Data:      15/12/2021
// Descricao: Determina a classificacao das uvas para a safra 2023.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Determina a classificacao das uvas para a safra 2023, com base nos demais dados de grau e inspecoes.
// #PalavasChave      #safra #classificacao_uva
// #TabelasPrincipais #ZX5
// #Modulos           #COOP

// Historico de alteracoes:
// 07/12/2022 - Robert - Replicada versao da safra 2022 para 2023.
//

// --------------------------------------------------------------------------
user function ClUva23 (_sVaried, _nGrau, _sConduc, _sBotrytis, _sGlomer, _sAspergil, _sPodrid, _sAcidVol)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _aTab17    := {}
	local _sPrm02    := ''
	local _sPrm03    := ''
	local _sPrm04    := ''
	local _sPrm05    := ''
	local _sPrm99    := ''
	local _aRetClUva := {}
	local _aGrupo52  := {}
	local _sSafraCl  := '2023'  // Ajustar caso seja copiado para o proximo ano!

//	U_Log2 ('info', 'Iniciando ' + procname ())

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (msseek (xfilial ("SB1") + _sVaried, .F.))
			u_help ("Variedade '" + _sVaried + "' nao encontrada no cadastro.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		u_log2 ('info', '[' + procname () + ']Variedade............: ' + _sVaried + sb1 -> b1_desc)
		u_log2 ('info', '[' + procname () + ']Grau.................: ' + cvaltochar (_nGrau))
		u_log2 ('info', '[' + procname () + ']Sistema de conducao..: ' + _sConduc)
		u_log2 ('info', '[' + procname () + ']Botrytis.............: ' + cvaltochar (_sBotrytis))
		u_log2 ('info', '[' + procname () + ']Glomerella...........: ' + cvaltochar (_sGlomer))
		u_log2 ('info', '[' + procname () + ']Aspergillus..........: ' + cvaltochar (_sAspergil))
		u_log2 ('info', '[' + procname () + ']Podridoes............: ' + cvaltochar (_sPodrid))
		u_log2 ('info', '[' + procname () + ']Acidez volatil.......: ' + cvaltochar (_sAcidVol))
//		u_log2 ('info', '[' + procname () + ']Soma das podridoes.....:' + cvaltochar (_sBotrytis + _sGlomer + _sAspergil + _sPodrid))
		if empty (_sConduc)
			u_help ("Sistema de conducao nao informado. Impossivel determinar a classificacao da uva.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. _sConduc == 'L'  // Latada
		
		// Busca tabela de classificacao de uvas latadas X grau
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT LATADA_GRAU_MIN_A, LATADA_GRAU_MIN_B, LATADA_GRAU_MIN_C"
		_oSQL:_sQuery +=  " FROM VA_VFAIXAS_GRAU_UVAS"
		_oSQL:_sQuery += " WHERE SAFRA   = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND SIST_CONDUCAO = 'L'"
		_oSQL:_sQuery +=   " AND PRODUTO = '" + _sVaried + "'"
//		_oSQL:Log ('[' + procname () + ']' + _oSQL:_sQuery)
		_aGrupo52 := aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aGrupo52) == 0
			u_help ("Produto '" + alltrim (_sVaried) + "' nao encontrado na view VA_VFAIXAS_GRAU_UVAS para a safra '" + _sSafraCl + "'", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		elseif len (_aGrupo52) > 1
			u_help ("Produto '" + alltrim (_sVaried) + "' encontrado MAIS DE UMA VEZ na view VA_VFAIXAS_GRAU_UVAS para a safra '" + _sSafraCl + "'", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		else
			if _nGrau >= val (_aGrupo52 [1, 1])
				_sPrm02 = 'A'
			elseif _nGrau >= val (_aGrupo52 [1, 2])
				_sPrm02 = 'B'
			elseif _nGrau >= val (_aGrupo52 [1, 3])
				_sPrm02 = 'C'
			else
				_sPrm02 = 'DS'
			endif
		endif
		
		// Define classificacao por sanidade/conformidade.
		_sPrm03 = _Prm03 (_sConduc, _sAcidVol, _sBotrytis, _sPodrid, _sGlomer, _sAspergil)

		// Nas latadas nao se considera uniformidade de maturacao
		_sPrm04 = 'B'

		// Define classificacao por presenca de materiais estranhos: nao usaremos neste ano.
		_sPrm05 = 'B'
	endif

	if _lContinua .and. _sConduc == 'E'  // Espaldeira
	
		// Verifica limites de grau para esta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ESPALD_GRAU_MIN_PR, ESPALD_GRAU_MIN_AA, ESPALD_GRAU_MIN_A, ESPALD_GRAU_MIN_B, ESPALD_GRAU_MIN_C, ESPALD_GRAU_MIN_D"
		_oSQL:_sQuery +=  " FROM VA_VFAIXAS_GRAU_UVAS"
		_oSQL:_sQuery += " WHERE SAFRA   = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND SIST_CONDUCAO = 'E'"
		_oSQL:_sQuery +=   " AND PRODUTO = '" + _sVaried + "'"
		_oSQL:Log ('[' + procname () + ']')
		_aTab17 = aclone (_oSQL:Qry2Array (.F., .F.))
		U_Log2 ('debug', '[' + procname () + ']Resultado da tabela 17:')
		u_log2 ('debug', _aTab17)
		if len (_aTab17) == 0
			u_help ("Variedade '" + _sVaried + "' nao localizada na view VA_VFAIXAS_GRAU_UVAS (graus X classes uvas viniferas) para a safra '" + _sSafraCl + "'", _oSQL:_sQuery, .t.)
		elseif len (_aTab17) > 1
			u_help ("Variedade '" + _sVaried + "' aparece mais de uma vez na view VA_VFAIXAS_GRAU_UVAS (graus X classes uvas viniferas) para a safra '" + _sSafraCl + "'", _oSQL:_sQuery, .t.)
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
			else
				_sPrm02 = 'DS'
			endif
			u_log2 ('info', '[' + procname () + ']Classificacao de acucar cfe.faixa de grau: ' + _sPrm02)
		endif
	
		// Define classificacao por sanidade/conformidade.
		_sPrm03 = _Prm03 (_sConduc, _sAcidVol, _sBotrytis, _sPodrid, _sGlomer, _sAspergil)

		// Define classificacao por uniformidade de maturacao.
		_sPrm04 = _sPrm02  // Assume a mesma do acucar, pois eh o melhor parametro para indicar maturacao da uva.
		u_log2 ('info', '[' + procname () + ']Classificacao por uniformidade de maturacao: ' + _sPrm04 + ' (assume a mesma do acucar, pois eh o melhor parametro para indicar maturacao da uva).')

		// Define classificacao por presenca de materiais estranhos
		// Conforme normas de safra: "Materiais estranhos não terão valor de enquadramento da uva nas classes, apenas deverá ser apontada a natureza do material"
		// Portanto, deixarei PR para que nunca possa puxar as demais classificaoes para baixo.
		_sPrm05 = 'PR'
		u_log2 ('info', '[' + procname () + ']Classificacao por presenca de materiais estranhos: ' + _sPrm05 + ' (conforme normas de safra: "Materiais estranhos nao terao valor de enquadramento da uva nas classes, apenas devera ser apontada a natureza do material". Portanto, deixarei PR para que nunca possa puxar as demais classificaoes para baixo.')
	endif

	if _lContinua

		// Gera a 'classificacao final' com base nas demais.
		_sPrm99 = U_ClassUva (_sConduc, _sPrm02, _sPrm03, _sPrm04, _sPrm05)
		
		_aRetClUva = {_sPrm02, _sPrm03, _sPrm04, _sPrm05, _sPrm99}
	else
		_aRetClUva = {'', '', '', '', ''}
	endif
	
	U_Log2 ('info', '[' + procname () + ']Resultado da classificacao da uva:')
	u_log2 ('info', '[' + procname () + ']   Acucar......: ' + _aRetClUva [1])
	u_log2 ('info', '[' + procname () + ']   Sanidade....: ' + _aRetClUva [2])
	u_log2 ('info', '[' + procname () + ']   Maturacao...: ' + _aRetClUva [3])
	u_log2 ('info', '[' + procname () + ']   Mat.estranho: ' + _aRetClUva [4])
	u_log2 ('info', '[' + procname () + ']   Clas.final..: ' + _aRetClUva [5])

	U_ML_SRArea (_aAreaAnt)
return _aRetClUva



// --------------------------------------------------------------------------
static function _Prm03 (_sConduc, _sAcidVol, _sBotrytis, _sPodrid, _sGlomer, _sAspergil)
	local _nSomaPerc := 0

//	U_Log2 ('debug', '[' + procname () + ']ENTREI EM ' + procname () + ' com ' + _sConduc + _sAcidVol + _sBotrytis + _sPodrid + _sGlomer + _sAspergil)

	// 'Presente' entende-se como 'acima do aceitavel'
	if upper (_sAcidVol) = 'PRESENTE' .or. val (_sAcidVol) > 10
		_sRetP03 = 'DS'
		U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. acidez volatil (" + _sAcidVol + ").")
	else
		if upper (_sBotrytis) = 'PRESENTE' .or. val (_sBotrytis) > 12
			_sRetP03 = 'DS'
			U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. botrytis (" + _sBotrytis + ').')
		else
			if upper (_sPodrid) = 'PRESENTE' .or. val (_sPodrid) > 12
				_sRetP03 = 'DS'
				U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridoes (" + _sPodrid + ').')
			else
				if upper (_sGlomer) = 'PRESENTE' .or. val (_sGlomer) > 25
					_sRetP03 = 'DS'
					U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridao de uva madura/glomerella (" + _sGlomer + ').')
				else
					if upper (_sAspergil) = 'PRESENTE' .or. val (_sAspergil) > 6
						_sRetP03 = 'DS'
						U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridao aspergillus (" + _sAspergil + ').')
					else

						// Define classificacao por estado sanitario somando os demais indicadores
						// Quando 'presente' entende-se 'acima do aceitavel'; 'ausente' = 0 (foi feita inspecao); caso contrario vai ter o valor.
						_nSomaPerc := 0
						_nSomaPerc += iif (upper (_sBotrytis) = 'AUSENTE', 0, val (_sBotrytis))
						_nSomaPerc += iif (upper (_sGlomer)   = 'AUSENTE', 0, val (_sGlomer))
						_nSomaPerc += iif (upper (_sAspergil) = 'AUSENTE', 0, val (_sAspergil))
						_nSomaPerc += iif (upper (_sPodrid)   = 'AUSENTE', 0, val (_sPodrid))
						if _nSomaPerc > 12
							_sRetP03 = 'DS'
							U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. soma dos % de estado sanitario (" + cvaltochar (_nSomaPerc) + "%).")
						elseif _nSomaPerc >= 6
							_sRetP03 = 'D '
							U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. soma dos % de estado sanitario (" + cvaltochar (_nSomaPerc) + "%).")
						elseif _nSomaPerc >= 3
							_sRetP03 = 'C '
							U_Log2 ('info', '[' + procname (1) + "]Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. soma dos % de estado sanitario (" + cvaltochar (_nSomaPerc) + "%).")
						else
							// Assume PR para nao puxar as demais classificacoes para baixo.
							_sRetP03 = 'PR'
						endif
					endif
				endif
			endif
		endif
	endif
return _sRetP03
