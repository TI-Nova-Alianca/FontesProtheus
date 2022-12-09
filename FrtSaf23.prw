// Programa...: FrtSaf23
// Autor......: Robert Koch
// Data.......: 07/12/2022
// Descricao..: Calcula valor de frete de entrega de safra, a ser pago aos associados, para a safra 2023.
//              Criado com base no FrtSaf22.prw

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Calcula valor de frete de entrega de safra 2023
// #PalavasChave      #safra #frete_safra
// #TabelasPrincipais #SZI #SZE #SZF
// #Modulos           #Coop

// Historico de alteracoes:
//

// ------------------------------------------------------------------------------------
User Function FrtSaf23 (_sNucleo, _sCadVit, _sFilDest, _nPesoFrt, _sCor, _sFilCarg)
	local _nDist    := 0
	local _nValFre  := 0
	local _oAviso   := NIL
	local _sLinkSrv := U_LkServer ('NAWEB')
	local _aDistKM  := {}
	local _sMetodo  := ''

	u_log2 ('info', '[' + procname () + '] Nucleo........: ' + _sNucleo)
	u_log2 ('info', '[' + procname () + '] Propr.rural...: ' + _sCadVit)
	u_log2 ('info', '[' + procname () + '] Filial entrega: ' + _sFilDest)
	u_log2 ('info', '[' + procname () + '] Peso..........: ' + cvaltochar (_nPesoFrt))
	u_log2 ('info', '[' + procname () + '] Cor da uva....: ' + _sCor)

	// Busca as distancias da propriedade rural de onde vem a uva
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""

	if _sFilDest == '03'
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF03"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	elseif _sFilDest == '07'
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF07"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	elseif _sFilDest $ '01/09'
		_oSQL:_sQuery += " SELECT distinct CCPropriedadeKMF01"  // Usa DISTINCT por que pode haver caso de propriedade explorada por mais de 1 grupo familiar
	else
		u_help ("Filial destino '" + _sFilDest + "' sem tratamento no programa " + procname (),, .T.)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'143'}  // 143 = grupo da agronomia
		_oAviso:Texto      = "Filial destino '" + _sFilDest + "' sem tratamento no programa de calculo de frete de safra."
		_oAviso:Origem     = procname ()
		_oAviso:Grava ()
	endif
	_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".CCPropriedade"
	_oSQL:_sQuery +=  " WHERE CCPropriedadeCod = " + cvaltochar (val (_sCadVit))  // NaWeb guarda em formato numerico.
	//_oSQL:Log ()
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
			_oAviso:DestinZZU  = {'143'}  // 143 = grupo da agronomia
			_oAviso:Texto      = "Distancia nao informada entre a propriedade " + _sCadVit + " e a filial " + _sFilDest + ". Frete de safra nao pode ser calculado."
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		endif
	endif
	//u_log2 ('info', '[' + procname () + '] Distancia Km..: ' + cvaltochar (_nDist))
	
	if _sCor == 'T' .and. _sNucleo $ 'PB/JC' .and. _sFilDest $ '01/09'
		_sMetodo = 'P-Tintas de Farroupilha entregues na matriz/F09'
		_nValFre = 0.07 * _nPesoFrt
	elseif _sCor == 'T' .and. _sNucleo $ 'SV/SG/FC/NP' .and. _sFilDest $ '07'
		_sMetodo = 'P-Tintas de Caxias/Flores entregues em Farroupilha'
		_nValFre = 0.07 * _nPesoFrt
	else
		_sMetodo = 'D-Caso geral (valor X ton X distancia)'
		_nValFre = 0.3 * _nPesoFrt / 1000 * _nDist
	endif
	_nValFre = round (_nValFre, 2)

	u_log2 ('info', '[' + procname () + '] Distancia Km..: ' + cvaltochar (_nDist) + ' Metodo: ' + _sMetodo + ' Frt. calculado: ' + cvaltochar (_nValFre))
return {_nValFre, _nDist, _sMetodo}
