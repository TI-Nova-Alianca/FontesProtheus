// Programa...: FrtSaf21
// Autor......: Robert Koch
// Data.......: 06/01/2021
// Descricao..: Calcula valor de frete de entrega de safra, a ser pago aos associados, para a safra 2021.
//              Criado com base no FrtSaf20.prw
//
// Historico de alteracoes:
// 20/01/2020 - Robert - Erro ao mostrar mensagem de propriedade rural sem distancia informada.
// 23/01/2020 - Robert - Gera aviso para agronomia quando falta cadastro.
// 01/07/2020 - Robert - Calcula frete independente de distancia - GLPI 8131.
// 06/01/2021 - Robert - Busca as distancias na tabela CCPropriedade do NaWeb e nao mais no ZA8.
// 11/01/2021 - Robert - Manda e-mail de aviso quando nao tiver distancia cadastrada.
// 12/01/2021 - Robert - NaWeb guarda o cadastro da propriedade (que eu trato por cad.viticola) em formato numerico.
// 15/01/2021 - Robert - Novo parametro metodo :RetFixo da classe ClsSQL().
// 03/02/2021 - Robert - Melhorada mensagem de aviso por e-mail.
//

// ------------------------------------------------------------------------------------
User Function FrtSaf21 (_sNucleo, _sCadVit, _sFilDest, _nPesoFrt, _sCor, _sFilCarg)
	local _nDist    := 0
	local _nValFre  := 0
	local _oAviso   := NIL
	local _sLinkSrv := U_LkServer ('NAWEB')
	local _aDistKM  := {}

//	u_log2 ('info', '[' + procname () + '] Nucleo........: ' + _sNucleo)
//	u_log2 ('info', '[' + procname () + '] Propr.rural...: ' + _sCadVit)
//	u_log2 ('info', '[' + procname () + '] Filial entrega: ' + _sFilDest)
//	u_log2 ('info', '[' + procname () + '] Peso..........: ' + cvaltochar (_nPesoFrt))
//	u_log2 ('info', '[' + procname () + '] Cor da uva....: ' + _sCor)

/*
	// Busca as distancias da propriedade rural de onde vem a uva
	za8 -> (dbsetorder (1))  // ZA8_FILIAL + ZA8_COD
	if ! za8 -> (msseek (xfilial ("ZA8") + _sCadVit, .F.))
		u_help ("Nao foi possivel localizar o cadastro da propriedade rural '" + _sCadVit + "'. Impossivel calcular distancias.",, .t.)
	else
		if _sFilDest == '03'
			_nDist = 2 * za8 -> za8_kmf03
		elseif _sFilDest == '07'
			_nDist = 2 * za8 -> za8_kmf07
		elseif _sFilDest $ '01/09'
			_nDist = 2 * za8 -> za8_kmf01
		else
			u_help ("Filial destino '" + _sFilDest + "' sem tratamento no programa " + procname (),, .T.)
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:Destinatar = 'grpAgronomia'
			_oAviso:Texto      = "Filial destino '" + _sFilDest + "' sem tratamento no programa de calculo de frete de safra."
			_oAviso:Origem     = procname ()
			_oAviso:CodAviso   = '011'
			_oAviso:Grava ()
		endif
	endif
	*/

	// Busca as distancias da propriedade rural de onde vem a uva
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""

	if _sFilDest == '03'
	//	_oSQL:_sQuery += " SELECT CCPropriedadeKMF03"
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF03"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	elseif _sFilDest == '07'
	//	_oSQL:_sQuery += " SELECT CCPropriedadeKMF07"
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF07"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	elseif _sFilDest $ '01/09'
	//	_oSQL:_sQuery += " SELECT CCPropriedadeKMF01"
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF01"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	else
		u_help ("Filial destino '" + _sFilDest + "' sem tratamento no programa " + procname (),, .T.)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:Destinatar = 'grpAgronomia'
		_oAviso:Texto      = "Filial destino '" + _sFilDest + "' sem tratamento no programa de calculo de frete de safra."
		_oAviso:Origem     = procname ()
		_oAviso:CodAviso   = '011'
		_oAviso:Grava ()
	endif
	_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".CCPropriedade"
//	_oSQL:_sQuery +=  " WHERE CCPropriedadeCod = '" + _sCadVit + "'"
	_oSQL:_sQuery +=  " WHERE CCPropriedadeCod = " + cvaltochar (val (_sCadVit))  // NaWeb guarda em formato numerico.
	_oSQL:Log ()
	_aDistKM = aclone (_oSQL:RetFixo (1, "ao consultar a distancia da propriedade rural '" + _sCadVit + "'. Verifique cadastro no NaWeb.", .T.))
	if len (_aDistKM) == 1
		_nDist = _aDistKM [1, 1] * 2  // ida e volta
	else
		_lContinua = .F.
	endif

	if _nDist <= 0
		u_help ("Distancia nao informada entre a propriedade " + _sCadVit + " e a filial " + _sFilDest + ". Frete de safra nao pode ser calculado.",, .t.)
		if IsInCallStack ("U_VA_RUSN")
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:Destinatar = 'grpAgronomia'
		//	_oAviso:Texto      = "Sem distancias cadastradas na propriedade " + _sCadVit + " para calculo de frete."
			_oAviso:Texto      = "Distancia nao informada entre a propriedade " + _sCadVit + " e a filial " + _sFilDest + ". Frete de safra nao pode ser calculado."
			_oAviso:Origem     = procname ()
			_oAviso:CodAviso   = '011'
		//	_oAviso:Grava ()
			// como ainda nao estamos usando os avisos, vou mandar por e-mail
			U_ZZUNU ({'075'}, ;  // 075=agronomia
			          "Sem distancias prop.rural " + _sCadVit, ;
			          "Distancia nao informada entre a propriedade " + _sCadVit + " e a filial " + _sFilDest + ". Frete de safra nao pode ser calculado para a carga " + sze -> ze_carga + ' da filial ' + cFilAnt + ".")
		endif
	endif
	u_log2 ('info', '[' + procname () + '] Distancia Km..: ' + cvaltochar (_nDist))
	
	if _sCor == 'T' .and. _sNucleo $ 'PB/JC' .and. _sFilDest $ '01/09'
		u_log2 ('info', '[' + procname () + '] Metodo: Tintas de Farroupilha entregues na matriz/F09')
		_nValFre = 0.07 * _nPesoFrt
	elseif _sCor == 'T' .and. _sNucleo $ 'SV/SG/FC/NP' .and. _sFilDest $ '07'
		u_log2 ('info', '[' + procname () + '] Metodo: Tintas de Caxias/Flores entregues em Farroupilha')
		_nValFre = 0.07 * _nPesoFrt
	else
		u_log2 ('info', '[' + procname () + '] Metodo: Caso geral (valor X ton X distancia)')
		_nValFre = 0.2 * _nPesoFrt / 1000 * _nDist
	endif
	_nValFre = round (_nValFre, 2)

	u_log2 ('info', '[' + procname () + '] Frt. calculado: ' + cvaltochar (_nValFre))
return _nValFre
