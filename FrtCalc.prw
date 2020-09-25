// Programa...: FrtCalc
// Autor......: Robert Koch
// Data.......: 06/06/2008
// Descricao..: Calcula valor do frete.
//
// Historico de alteracoes:
// 28/06/2011 - Robert - Ajustes calculo por peso transp. Garibaldi
//                     - Ajustes calculo Ad Valorem (estava dividindo por 100)
//                     - Ajustes calculo pedagio quando peso em toneladas.
// 06/10/2014 - Catia  - Alterada a mensagem do "Valor do frete maior que o previsto", para que não de a mensagem quando usado pelo IMPCONH
// 18/10/2014 - Catia  - Alterada a mensagem do "Valor do frete maior que o previsto", para que não de a mensagem quando usado pelo EDICONH
// 18/07/2016 - Catia  - Alterada a mensagem do "Valor do frete maior que o previsto", para que não de a mensagem quando usado pelo ZZXG
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function FrtCalc (_aRegs, _lReentreg, _lValida, _nValReal)
	local _nReg   := 0
	local _lRet      := .T.
	local _nVlZZ1    := 0
	local _nTotZZ1   := 0
	local _nVlFrNego := 0
	local _nVlFrPeso := 0
	local _nVlFrPedg := 0
	local _nVlFrADVl := 0
	local _nVlFrCAT  := 0
	local _nVlFrDesp := 0
	local _nVlFrGRIS := 0
	local _aFretes   := {}
	local _aCampos   := {}
	local _nPeso     := 0
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nQtPedag  := 0

	_nTotZZ1 = 0
	_aFretes = {}
	for _nReg = 1 to len (_aRegs)
/*
		u_logIni ("Registro " + cvaltochar (_nReg))
		u_log ("DocS           : ", _aRegs [_nReg, .FreteDocS])
		u_log ("SerieS         : ", _aRegs [_nReg, .FreteSerieS])
		u_log ("VlNegociado    : ", _aRegs [_nReg, .FreteVlNegociado])
		u_log ("UMPeso         : ", _aRegs [_nReg, .FreteUMPeso])
		u_log ("PesoMinimo     : ", _aRegs [_nReg, .FretePesoMinimo])
		u_log ("FreteMinimo    : ", _aRegs [_nReg, .FreteFreteMinimo])
		u_log ("FretePeso      : ", _aRegs [_nReg, .FreteFretePeso])
		u_log ("Pedagio        : ", _aRegs [_nReg, .FretePedagio])
		u_log ("AdValorem      : ", _aRegs [_nReg, .FreteAdValorem])
		u_log ("Despacho       : ", _aRegs [_nReg, .FreteDespacho])
		u_log ("CAT            : ", _aRegs [_nReg, .FreteCAT])
		u_log ("GRIS           : ", _aRegs [_nReg, .FreteGRIS])
		u_log ("Transportadora : ", _aRegs [_nReg, .FreteTransportadora])
		u_log ("Cliente        : ", _aRegs [_nReg, .FreteCliente])
		u_log ("Loja           : ", _aRegs [_nReg, .FreteLoja])
		u_log ("TipoNF         : ", _aRegs [_nReg, .FreteTipoNF])
		u_log ("ValorFatura    : ", _aRegs [_nReg, .FreteValorFatura])
		u_log ("PesoBruto      : ", _aRegs [_nReg, .FretePesoBruto])
		u_log ("MinimoAdValorem: ", _aRegs [_nReg, .FreteMinimoAdValorem])
		u_log ("PesoFixo1      : ", _aRegs [_nReg, .FretePesoFixo1])
		u_log ("PesoFixo2      : ", _aRegs [_nReg, .FretePesoFixo2])
		u_log ("PesoFixo3      : ", _aRegs [_nReg, .FretePesoFixo3])
		u_log ("PesoFixo4      : ", _aRegs [_nReg, .FretePesoFixo4])
		u_log ("PesoFixo5      : ", _aRegs [_nReg, .FretePesoFixo5])
		u_log ("PesoFixo6      : ", _aRegs [_nReg, .FretePesoFixo6])
		u_log ("PesoFixo7      : ", _aRegs [_nReg, .FretePesoFixo7])
		u_log ("PesoFixo8      : ", _aRegs [_nReg, .FretePesoFixo8])
		u_log ("PesoFixo9      : ", _aRegs [_nReg, .FretePesoFixo9])
		u_log ("PesoFixo10     : ", _aRegs [_nReg, .FretePesoFixo10])
		u_log ("ValorFixo1     : ", _aRegs [_nReg, .FreteValorFixo1])
		u_log ("ValorFixo2     : ", _aRegs [_nReg, .FreteValorFixo2])
		u_log ("ValorFixo3     : ", _aRegs [_nReg, .FreteValorFixo3])
		u_log ("ValorFixo4     : ", _aRegs [_nReg, .FreteValorFixo4])
		u_log ("ValorFixo5     : ", _aRegs [_nReg, .FreteValorFixo5])
		u_log ("ValorFixo6     : ", _aRegs [_nReg, .FreteValorFixo6])
		u_log ("ValorFixo7     : ", _aRegs [_nReg, .FreteValorFixo7])
		u_log ("ValorFixo8     : ", _aRegs [_nReg, .FreteValorFixo8])
		u_log ("ValorFixo9     : ", _aRegs [_nReg, .FreteValorFixo9])
		u_log ("ValorFixo10    : ", _aRegs [_nReg, .FreteValorFixo10])
		u_log ("ItemZZ3        : ", _aRegs [_nReg, .FreteItemZZ3])
*/
		_nVlZZ1    = 0
		_nVlFrNego = 0
		_nVlFrPeso = 0
		_nVlFrPedg = 0
		_nVlFrADVl = 0
		_nVlFrCAT  = 0
		_nVlFrDesp = 0
		_nVlFrGRIS = 0
		if _aRegs [_nReg, 3] > 0
			_nVlFrNego = _aRegs [_nReg, .FreteVlNegociado]
		else
			if _aRegs [_nReg, .FreteUMPeso] == "K"
				_nPeso = _aRegs [_nReg, .FretePesoBruto]
			elseif _aRegs [_nReg, .FreteUMPeso] == "T"
				_nPeso = _aRegs [_nReg, .FretePesoBruto] / 1000
			else
				msgalert ("Unidade de medida de peso sem tratamento: " + _aRegs [_nReg, .FreteUMPeso])
				_lRet = .F.
			endif

			// Trata o conceito valor fixo pode faixa de peso (Ex.: transportadora 2001)
			if _aRegs [_nReg, .FretePesoFixo1] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo1] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo1], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 1")
			elseif _aRegs [_nReg, .FretePesoFixo2] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo2] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo2], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 2")
			elseif _aRegs [_nReg, .FretePesoFixo3] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo3] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo3], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 3")
			elseif _aRegs [_nReg, .FretePesoFixo4] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo4] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo4], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 4")
			elseif _aRegs [_nReg, .FretePesoFixo5] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo5] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo5], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 5")
			elseif _aRegs [_nReg, .FretePesoFixo6] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo6] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo6], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 6")
			elseif _aRegs [_nReg, .FretePesoFixo7] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo7] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo7], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 7")
			elseif _aRegs [_nReg, .FretePesoFixo8] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo8] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo8], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 8")
			elseif _aRegs [_nReg, .FretePesoFixo9] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo9] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo9], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 9")
			elseif _aRegs [_nReg, .FretePesoFixo10] >= _aRegs [_nReg, .FretePesoBruto] .and. _aRegs [_nReg, .FreteValorFixo10] > 0
				_nVlFrPeso += round (_aRegs [_nReg, .FreteValorFixo10], 2)
				_nPeso = 0  // Para nao calcular nada por tonelagem, mais adiante.
				// u_log ("Enquadrou no preco fixo 10")
			endif


			// Trata o conceito de frete / peso minimo
			if _aRegs [_nReg, .FretePesoMinimo] > 0 .and. _aRegs [_nReg, .FreteFreteMinimo] > 0 .and. _nPeso <= _aRegs [_nReg, .FretePesoMinimo]
				_nVlFrPeso += round (_aRegs [_nReg, .FreteFreteMinimo], 2)
				// u_log ("Considerando frete pelo peso minimo:", _nVlFrPeso)
			else
				_nVlFrPeso += round (_aRegs [_nReg, .FreteFretePeso] * _nPeso, 2)
				// u_log ("Frete peso: ", _nVlFrPeso)
			endif

			// Valor do pedagio eh cobrado uma vez a cada 100 Kg de peso
//			_nQtPedag = _nPeso / 100
			if _aRegs [_nReg, .FreteUMPeso] == "T"
				_nQtPedag = _nPeso
				if _nQtPedag != int (_nPeso)
					_nQtPedag = int (_nQtPedag) + 1
				endif
			else
				_nQtPedag = _nPeso / 100
				if _nQtPedag != int (_nPeso / 100)
					_nQtPedag = int (_nQtPedag) + 1
				endif
			endif
			// u_log ("Quantidade de pedagios: ", _nQtPedag)
			_nVlFrPedg  = round (_nQtPedag * _aRegs [_nReg, .FretePedagio], 2)
			// u_log ("Frete pedagio: ", _nVlFrPedg)

			if _aRegs [_nReg, .FreteValorFatura] > _aRegs [_nReg, .FreteMinimoAdValorem]
//				_nVlFrADVl  = round (_aRegs [_nReg, .FreteAdValorem] / 100 * _aRegs [_nReg, .FreteValorFatura], 2)
				_nVlFrADVl  = round (_aRegs [_nReg, .FreteAdValorem] * _aRegs [_nReg, .FreteValorFatura], 2)
			endif
			// u_log ("Frete Ad Valor: ", _nVlFrAdVl)
			_nVlFrDesp  = round (_aRegs [_nReg, .FreteDespacho], 2)
			// u_log ("Frete despacho: ", _nVlFrDesp)
			_nVlFrCAT   = round (_aRegs [_nReg, .FreteCAT], 2)
			// u_log ("Frete CAT: ", _nVlFrCAT)
			_nVlFrGRIS  = round (_aRegs [_nReg, .FreteGRIS] / 100 * _aRegs [_nReg, .FreteValorFatura], 2)
			// u_log ("Frete gris: ", _nVlFrGris)
		endif

		// Se for reentrega, cada transportadora tem um tratamento.
		if _lReentreg
			// u_log ("Eh reentrega.")
			sa4 -> (dbsetorder (1))
			if sa4 -> (dbseek (xfilial ("SA4") + _aRegs [_nReg, .FreteTransportadora], .F.))
				_nVlFrNego *= sa4 -> a4_vaPReen / 100
				_nVlFrPeso *= sa4 -> a4_vaPReen / 100
				_nVlFrPedg *= sa4 -> a4_vaPReen / 100
				_nVlFrADVl *= sa4 -> a4_vaPReen / 100
				_nVlFrCAT  *= sa4 -> a4_vaPReen / 100
				_nVlFrDesp *= sa4 -> a4_vaPReen / 100 
				_nVlFrGRIS *= sa4 -> a4_vaPReen / 100
			endif
		endif
		_nVlZZ1 = _nVlFrNego + _nVlFrPeso + _nVlFrPedg + _nVlFrADVl + _nVlFrDesp + _nVlFrcat + _nVlFrGRIS
//		u_log ("Parciais:", _nVlFrNego , _nVlFrPeso , _nVlFrPedg , _nVlFrADVl , _nVlFrDesp , _nVlFrcat , _nVlFrGRIS)
		// u_log ("Valor total para este registro: ", _nvlzz1)
		_nTotZZ1 += _nVlZZ1
		// u_log ("Valor acumulado para o frete total: ", _nTotZZ1)

		// Monta array para mostrar calculo na tela.
		if _lValida
			_sNCliFor = iif (_aRegs [_nReg, .FreteTipoNF] $ "BD", fBuscaCpo ("SA2", 1, xfilial ("SA2") + _aRegs [_nReg, .FreteCliente] + _aRegs [_nReg, .FreteLoja], "A2_NOME"), fBuscaCpo ("SA1", 1, xfilial ("SA1") + _aRegs [_nReg, .FreteCliente] + _aRegs [_nReg, .FreteLoja], "A1_NOME"))
			aadd (_aFretes, {_aRegs [_nReg, .FreteDocS], ;
			_aRegs [_nReg, .FreteSerieS], ;
			_aRegs [_nReg, .FreteCliente], ;
			_aRegs [_nReg, .FreteLoja], ;
			_sNCliFor, ;
			_aRegs [_nReg, .FretePesoBruto], ;
			_aRegs [_nReg, .FreteValorFatura], ;
			_nVlFrPeso, ;
			_nVlFrPedg, ;
			_nVlFrADVl, ;
			_nVlFrDesp, ;
			_nVlFrcat, ;
			_nVlFrGRIS, ;
			_nVlFrNego, ;
			_nVlZZ1})
		endif
		// u_logFim ("Registro " + cvaltochar (_nReg))
	next
	if _lValida
		if _nvalReal > _nTotZZ1 + _nTotZZ1 * GetMv ("VA_PVARFRT") / 100
			if len (_aFretes) > 0
				aadd (_aCampos, {1,  "NF orig.",     25, "@!"})
				aadd (_aCampos, {2,  "Serie",        15, "@!"})
				aadd (_aCampos, {3,  "Cliente",      25, "@!"})
				aadd (_aCampos, {4,  "Loja",         15, "@!"})
				aadd (_aCampos, {5,  "Nome",         50, "@!"})
				aadd (_aCampos, {6,  "Peso bruto",   35, "@E 999,999"})
				aadd (_aCampos, {7,  "Vl.mercadoria", 35, "@E 999,999.99"})
				aadd (_aCampos, {8,  "Frete peso",   35, "@E 999,999.99"})
				aadd (_aCampos, {9,  "Pedagio",      35, "@E 999,999.99"})
				aadd (_aCampos, {10, "Frete valor",  35, "@E 999,999.99"})
				aadd (_aCampos, {11, "Despacho",     35, "@E 999,999.99"})
				aadd (_aCampos, {12, "CAT",          35, "@E 999,999.99"})
				aadd (_aCampos, {13, "GRIS",         35, "@E 999,999.99"})
				aadd (_aCampos, {14, "Vl.negociado", 35, "@E 999,999.99"})
				aadd (_aCampos, {15, "Valor total",  35, "@E 999,999.99"})
				U_F3Array (_aFretes, "Valor frete acima do previsto", _aCampos, NIL, nil, "Valor frete acima do previsto. Confira abaixo os valores previstos para este frete" + iif (_lReentreg, " (REENTREGA):", ":"), "Valor total previsto: " + cValToChar (_nTotZZ1) + "       valor digitado: " + cValToChar (_nValReal), .F.)
			endif
			if ! isincallstack ("U_IMPCONH") .and. ! isincallstack ("U_EDICONH") .and. ! isincallstack ("U_ZZXG")
			     _lRet = u_msgyesno ("Valor do frete maior que o previsto. Confirma assim mesmo?", .T.)
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return iif (_lValida, _lRet, _nTotZZ1)
