// Programa...: FrtSaf20
// Autor......: Robert Koch
// Data.......: 03/01/2020
// Descricao..: Calcula valor de frete de entrega de safra, a ser pago aos associados, para a safra 2020.
//              Criado com base no FrtSafra.prw, que era rodado apos a safra. Agora pretendemos calcular a cada NF de entrada.
//
// Historico de alteracoes:
// 20/01/2020 - Robert - Erro ao mostrar mensagem de propriedade rural sem distancia informada.
// 23/01/2020 - Robert - Gera aviso para agronomia quando falta cadastro.
// 01/07/2020 - Robert - Calcula frete independente de distancia - GLPI 8131.
// 01/09/2022 - Robert - Melhorias ClsAviso.
// 09/09/2022 - Robert - Criado grupo 143 no ZZU para notificar agronomia.
//

// ------------------------------------------------------------------------------------
User Function FrtSaf20 (_sNucleo, _sCadVit, _sFilDest, _nPesoFrt, _sCor)
	local _nDist   := 0
	local _nValFre := 0
	local _oAviso  := NIL

	u_log2 ('info', 'Nucleo........: ' + _sNucleo)
	u_log2 ('info', 'Propr.rural...: ' + _sCadVit)
	u_log2 ('info', 'Filial entrega: ' + _sFilDest)
	u_log2 ('info', 'Peso..........: ' + cvaltochar (_nPesoFrt))
	u_log2 ('info', 'Cor da uva....: ' + _sCor)

	// Encontra a propriedade rural de onde vem a uva
	za8 -> (dbsetorder (1))  // ZA8_FILIAL + ZA8_COD
	if ! za8 -> (msseek (xfilial ("ZA8") + _sCadVit, .F.))
		u_help ("Nao foi possivel localizar o cadastro da propriedade rural '" + _sCadVit + "'. Impossivel calcular distancias.",, .t.)
	else
//			_nDist = 2 * iif (_sFilDest == '03', _trb -> km_f03, iif (_sFilDest == '07', _trb -> km_f07, iif (_sFilDest $ '01/09', _trb -> km_f01, 0)))
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
			_oAviso:DestinZZU  = {'143'}
			_oAviso:Texto      = "Filial destino '" + _sFilDest + "' sem tratamento no programa de calculo de frete de safra."
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		endif
	endif
	if _nDist <= 0
		u_help ("Distancia nao informada entre a propriedade " + _sCadVit + " e a filial " + _sFilDest + ". Frete de safra nao pode ser calculado.",, .t.)
		if IsInCallStack ("U_VA_RUSN")
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'143'}
			_oAviso:Texto      = "Sem distancias cadastradas na propriedade " + _sCadVit + " para calculo de frete."
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
		endif
	endif
	u_log2 ('info', 'Distancia Km..: ' + cvaltochar (_nDist))
	
	// Calcula independente de distancia - GLPI 8131
	//if _nDist < 20  // Considerar ida + volta
	//	u_log2 ('info', 'Distancia calculada (' + cvaltochar (_nDist) + ') abaixo da distancia minima')
	//else
		if _sCor == 'T' .and. _sNucleo $ 'PB/JC' .and. _sFilDest $ '01/09'
			u_log2 ('info', 'Metodo: Tintas de Farroupilha entregues na matriz/F09')
			_nValFre = 0.05 * _nPesoFrt
		elseif _sCor == 'T' .and. _sNucleo $ 'SV/SG/FC/NP' .and. _sFilDest $ '07'
			u_log2 ('info', 'Metodo: Tintas de Caxias/Flores entregues em Farroupilha')
			_nValFre = 0.05 * _nPesoFrt
		else
			u_log2 ('info', 'Metodo: Caso geral (valor X ton X distancia)')
			_nValFre = 0.15 * _nPesoFrt / 1000 * _nDist
		endif
		_nValFre = round (_nValFre, 2)
	//endif

	u_log2 ('info', 'Frt. calculado: ' + cvaltochar (_nValFre))
return _nValFre
