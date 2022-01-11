// Programa:  ClUva22
// Autor:     Robert Koch
// Data:      15/12/2021
// Descricao: Determina a classificacao das uvas para a safra 2022.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Determina a classificacao das uvas para a safra 2022, com base nos demais dados de grau e inspecoes.
// #PalavasChave      #safra #classificacao_uva
// #TabelasPrincipais #ZX5
// #Modulos           #COOP

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function ClUva22 (_sVaried, _nGrau, _sConduc, _nPBotryt, _nPGlomer, _nPAsperg, _nPPodrAc, _nAcidVol)
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
	local _sSafraCl  := '2022'  // Ajustar caso seja copiado para o proximo ano!

	U_Log2 ('info', 'Iniciando ' + procname ())

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (msseek (xfilial ("SB1") + _sVaried, .F.))
			u_help ("Variedade '" + _sVaried + "' nao encontrada no cadastro.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		u_log2 ('info', '   Variedade..................:' + _sVaried + sb1 -> b1_desc)
		u_log2 ('info', '   Grau.......................:' + cvaltochar (_nGrau))
		u_log2 ('info', '   Sistema de conducao........:' + _sConduc)
		u_log2 ('info', '   % botrytis.................:' + cvaltochar (_nPBotryt))
		u_log2 ('info', '   % glomerella...............:' + cvaltochar (_nPGlomer))
		u_log2 ('info', '   % aspergillus..............:' + cvaltochar (_nPAsperg))
		u_log2 ('info', '   % podridao acida...........:' + cvaltochar (_nPPodrAc))
		u_log2 ('info', '   % acidez volatil...........:' + cvaltochar (_nAcidVol))
		u_log2 ('info', '   Soma das podridoes.........:' + cvaltochar (_nPBotryt + _nPGlomer + _nPAsperg + _nPPodrAc))
		if empty (_sConduc)
			u_help ("Sistema de conducao nao informado. Impossivel determinar a classificacao da uva.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. _sConduc == 'L'  // Latada
		
		// Busca tabela de classificacao de uvas latadas X grau
		_oSQL := ClsSQL ():New ()
/*
		_oSQL:_sQuery := "SELECT ZX5_52.ZX5_52GIA, ZX5_52.ZX5_52GIB, ZX5_52.ZX5_52GIC"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_52, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_53 "
		_oSQL:_sQuery += " WHERE ZX5_52.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_TABELA = '52'"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_52SAFR = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND ZX5_53.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_TABELA = '53'"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53SAFR = ZX5_52.ZX5_52SAFR"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53GRUP = ZX5_52.ZX5_52GRUP"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53PROD = '" + _sVaried + "'"
*/
		_oSQL:_sQuery := "SELECT LATADA_GRAU_MIN_A, LATADA_GRAU_MIN_B, LATADA_GRAU_MIN_C"
		_oSQL:_sQuery +=  " FROM VA_VFAIXAS_GRAU_UVAS"
		_oSQL:_sQuery += " WHERE SAFRA   = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND SIST_CONDUCAO = 'L'"
		_oSQL:_sQuery +=   " AND PRODUTO = '" + _sVaried + "'"
		_oSQL:Log ()
		_aGrupo52 := aclone (_oSQL:Qry2Array (.F., .F.))
		U_log2 ('debug', 'faixas de grau:', _aGrupo52)
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
		_sPrm03 = _Prm03 (_sConduc, _nAcidVol, _nPBotryt, _nPPodrAc, _nPGlomer, _nPAsperg)

		// Nas latadas nao se considera uniformidade de maturacao
		_sPrm04 = 'B'

		// Define classificacao por presenca de materiais estranhos: nao usaremos neste ano.
		_sPrm05 = 'B'
	endif

	if _lContinua .and. _sConduc == 'E'  // Espaldeira
	
		// Verifica limites de grau para esta variedade.
		_oSQL := ClsSQL ():New ()
/*
		_oSQL:_sQuery := "SELECT ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_17 "
		_oSQL:_sQuery += " WHERE ZX5_17.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_TABELA = '17'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17SAFR = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17PROD = '" + _sVaried + "'"
*/
		_oSQL:_sQuery := "SELECT ESPALD_GRAU_MIN_PR, ESPALD_GRAU_MIN_AA, ESPALD_GRAU_MIN_A, ESPALD_GRAU_MIN_B, ESPALD_GRAU_MIN_C, ESPALD_GRAU_MIN_D"
		_oSQL:_sQuery +=  " FROM VA_VFAIXAS_GRAU_UVAS"
		_oSQL:_sQuery += " WHERE SAFRA   = '" + _sSafraCl + "'"
		_oSQL:_sQuery +=   " AND SIST_CONDUCAO = 'E'"
		_oSQL:_sQuery +=   " AND PRODUTO = '" + _sVaried + "'"
		_oSQL:Log ()
		_aTab17 = aclone (_oSQL:Qry2Array (.F., .F.))
		u_log (_aTab17)
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
		endif
	
		// Define classificacao por sanidade/conformidade.
		_sPrm03 = _Prm03 (_sConduc, _nAcidVol, _nPBotryt, _nPPodrAc, _nPGlomer, _nPAsperg)

		// Define classificacao por uniformidade de maturacao.
		_sPrm04 = _sPrm02  // Assume a mesma do acucar, pois eh o melhor parametro para indicar maturacao da uva.

		// Define classificacao por presenca de materiais estranhos
		// Conforme normas de safra: "Materiais estranhos não terão valor de enquadramento da uva nas classes, apenas deverá ser apontada a natureza do material"
		// Portanto, deixarei PR para que nunca possa puxar as demais classificaoes para baixo.
		_sPrm05 = 'PR'
	endif

	if _lContinua

		// Gera a 'classificacao final' com base nas demais.
		_sPrm99 = U_ClassUva (_sConduc, _sPrm02, _sPrm03, _sPrm04, _sPrm05)
		
		_aRetClUva = {_sPrm02, _sPrm03, _sPrm04, _sPrm05, _sPrm99}
	else
		_aRetClUva = {'', '', '', '', ''}
	endif
	
	// u_log2 ('info', '   Acucar......: ' + _aRetClUva [1])
	// u_log2 ('info', '   Sanidade....: ' + _aRetClUva [2])
	// u_log2 ('info', '   Maturacao...: ' + _aRetClUva [3])
	// u_log2 ('info', '   Mat.estranho: ' + _aRetClUva [4])
	// u_log2 ('info', '   Clas.final..: ' + _aRetClUva [5])
	U_ML_SRArea (_aAreaAnt)
return _aRetClUva



// --------------------------------------------------------------------------
static function _Prm03 (_sConduc, _nAcidVol, _nPBotryt, _nPPodrAc, _nPGlomer, _nPAsperg)
	local _nSomaPerc := _nPBotryt + _nPGlomer + _nPAsperg + _nPPodrAc

	if _nAcidVol > 10
		_sRetP03 = 'DS'
		U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. acidez volatil (" + cvaltochar (_nAcidVol) + ' meq/L).')
	else
		if _nPBotryt > 12
			_sRetP03 = 'DS'
			U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. botrytis (" + cvaltochar (_nPBotryt) + ' %).')
		else
			if _nPPodrAc > 12
				_sRetP03 = 'DS'
				U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridao acide (" + cvaltochar (_nPPodrAc) + ' %).')
			else
				if _nPGlomer > 25
					_sRetP03 = 'DS'
					U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridao de uva madura/glomerella (" + cvaltochar (_nPGlomer) + ' %).')
				else
					if _nPAsperg > 6
						_sRetP03 = 'DS'
						U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. podridao aspergillus (" + cvaltochar (_nPAsperg) + ' %).')
					else

						// Define classificacao por estado sanitario somando os demais indicadores
						if _nSomaPerc > 12
							_sRetP03 = 'DS'
							U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. estado sanitario (" + cvaltochar (_nSomaPerc) + ").")
						elseif _nSomaPerc >= 6
							_sRetP03 = 'D '
							U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. estado sanitario (" + cvaltochar (_nSomaPerc) + ").")
						elseif _nSomaPerc >= 3
							_sRetP03 = 'C '
							U_Log2 ('info', "Classificacao de sanidade/conformidade = '" + _sRetP03 + "' cfe. estado sanitario (" + cvaltochar (_nSomaPerc) + ").")
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
