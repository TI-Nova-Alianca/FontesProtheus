// Programa:  ClUva21
// Autor:     Robert Koch
// Data:      15/12/2020
// Descricao: Determina a classificacao das uvas para a safra 2021.
//
// Historico de alteracoes:
// 01/02/2021 - Robert - Comentariadas linhas de log.
//

// --------------------------------------------------------------------------
user function ClUva21 (_sVaried, _nGrau, _sConduc, _nPBotryt, _nPGlomer, _nPAsperg, _nPPodrAc, _nAcidVol)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _nSomaPodr := _nPBotryt + _nPGlomer + _nPAsperg + _nPPodrAc
	local _oSQL      := NIL
	local _aTab17    := {}
	local _sPrm02    := ''
	local _sPrm03    := ''
	local _sPrm04    := ''
	local _sPrm05    := ''
	local _sPrm99    := ''
	local _aRetClUva := {}
	//local _oSQL      := NIL
	local _aGrupo52  := {}

	U_Log2 ('info', 'Iniciando ' + procname ())

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (msseek (xfilial ("SB1") + _sVaried, .F.))
			u_help ("Variedade '" + _sVaried + "' nao encontrada no cadastro.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// u_log2 ('info', '   Variedade..................:' + _sVaried + sb1 -> b1_desc)
		// u_log2 ('info', '   Grau.......................:' + cvaltochar (_nGrau))
		// u_log2 ('info', '   Sistema de conducao........:' + _sConduc)
		// u_log2 ('info', '   % botrytis.................:' + cvaltochar (_nPBotryt))
		// u_log2 ('info', '   % glomerella...............:' + cvaltochar (_nPGlomer))
		// u_log2 ('info', '   % aspergillus..............:' + cvaltochar (_nPAsperg))
		// u_log2 ('info', '   % podridao acida...........:' + cvaltochar (_nPPodrAc))
		// u_log2 ('info', '   % soma de podridoes........:' + cvaltochar (_nSomaPodr))
		// u_log2 ('info', '   % acidez volatil...........:' + cvaltochar (_nAcidVol))
		// u_log2 ('info', '   Soma das podridoes.........:' + cvaltochar (_nSomaPodr))
		if empty (_sConduc)
			u_help ("Sistema de conducao nao informado. Impossivel determinar a classificacao da uva.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. _sConduc == 'L'  // Latada
		
		// Busca tabela de classificacao de uvas latadas X grau
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_52.ZX5_52GIA, ZX5_52.ZX5_52GIB, ZX5_52.ZX5_52GIC"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_52, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_53 "
		_oSQL:_sQuery += " WHERE ZX5_52.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_TABELA = '52'"
		_oSQL:_sQuery +=   " AND ZX5_52.ZX5_52SAFR = '2020'"
		_oSQL:_sQuery +=   " AND ZX5_53.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_TABELA = '53'"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53SAFR = ZX5_52.ZX5_52SAFR"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53GRUP = ZX5_52.ZX5_52GRUP"
		_oSQL:_sQuery +=   " AND ZX5_53.ZX5_53PROD = '" + _sVaried + "'"
		_oSQL:Log ()
		_aGrupo52 := aclone (_oSQL:Qry2Array (.F., .F.))
//		U_log ('faixas de grau:', _aGrupo52)
		if len (_aGrupo52) == 0
			u_help ("Produto '" + alltrim (_sVaried) + "' nao encontrado na combinacao das tabelas 52 e 53 do arquivo ZX5 para esta safra.",, .t.)
			_lContinua = .F.
		elseif len (_aGrupo52) > 1
			u_help ("Produto '" + alltrim (_sVaried) + "' encontrado MAIS DE UMA VEZ na combinacao das tabelas 52 e 53 do arquivo ZX5 para esta safra.",, .t.)
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
		
		// Define classificacao por sanidade
		if _nAcidVol > 10
			_sPrm03 = 'DS'
		else
			_sPrm03 = 'PR'  // Assume PR para nao puxar as demais classificacoes para baixo.
		endif

		// Nas latadas nao se considera uniformidade de maturacao
		_sPrm04 = 'B'

		// Define classificacao por presenca de materiais estranhos: nao usaremos em 2020.
		_sPrm05 = 'B'
	endif

	if _lContinua .and. _sConduc == 'E'  // Espaldeira
	
		// Verifica limites de grau para esta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_17 "
		_oSQL:_sQuery += " WHERE ZX5_17.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_TABELA = '17'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17SAFR = '2020'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17PROD = '" + _sVaried + "'"
		_oSQL:Log ()
		_aTab17 = aclone (_oSQL:Qry2Array (.F., .F.))
		//u_log (_aTab17)
		if len (_aTab17) == 0
			u_help ("Variedade '" + _sVaried + "' nao localizada na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.",, .t.)
		elseif len (_aTab17) > 1
			u_help ("Variedade '" + _sVaried + "' aparece mais de uma vez na tabela 17 do arquivo ZX5 (graus X classes uvas viniferas) para esta safra.",, .t.)
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
	
		// Define classificacao por sanidade
		if _nAcidVol > 10
			_sPrm03 = 'DS'
		else
			_sPrm03 = 'PR'  // Assume PR para nao puxar as demais classificacoes para baixo.
		endif

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
