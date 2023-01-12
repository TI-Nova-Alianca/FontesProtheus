// Programa...: LeBalan
// Autor......: Robert Koch
// Data.......: 19/10/2011
// Descricao..: Leitura de peso de balanca eletronica, via porta serial.
//
// Historico de alteracoes:
// 27/02/2014 - Robert - Criado tratamento para impressora Saturno (filial 13)
//

// --------------------------------------------------------------------------
User Function LeBalan (_sPorta, _sModelo)
	local _sLeitura  := ""
	local _nHdl      := 1
	local _sStrPorta := ""
	local _lContinua := .T.
	local _nTentativ := 0
	local _lLeuOK    := .F.
	local _nPeso     := 0

	if _sModelo == 'Digitron'
		_sStrPorta = _sPorta + ":9600,n,8,1"
	elseif _sModelo == 'Saturno'
		_sStrPorta = _sPOrta + ":4800,n,8,1"
	else
		u_help ("Modelo de balanca desconhecido",, .t.)
	endif
	U_Log2 ('debug', '[' + procname () + ']Modelo impressora: ' + _sModelo + '. Usando a seguinte string de leitura de porta serial: ' + _sStrPorta)

	// Testa se consegue abrir a porta serial.
	if ! MsOpenPort (_nHdl, _sStrPorta, .F.)
		u_help ("Impossivel comunicar com a porta " + _sPorta,, .t.)
		MSCloseport (0)
		_lContinua = .F.
	endif
	
	// Loop para possibilitar ao usuario que faca nova tentativa.
	do while _lContinua

		// Loop para aguardar que a balanca se estabilize.
		_nTentativ = 0
		do while _nTentativ <= 5
			U_Log2 ('debug', '[' + procname () + ']Iniciando tentativa ' + cvaltochar (_nTentativ))
			MSOpenPort (0, _sStrPorta)
			sleep (500)      // ver o melhor tempo
			MSRead (_nHdl, @_sLeitura)
			mscloseport (0)
			U_Log2 ('debug', '[' + procname () + ']String lida da serial: ' + cvaltochar (_sLeitura))
			if _sModelo == 'Digitron'
				if left (_sLeitura, 1) != 'D'
					U_Log2 ('debug', '[' + procname () + ']Peso nao estabilizado')
				else
					_nPeso = val (substr (_sLeitura, 2, 6))
					_lLeuOK = .T.
					U_Log2 ('debug', '[' + procname () + ']Peso estabilizado: ' + cvaltochar (_nPeso))
					exit
				endif
			elseif _sModelo == 'Saturno'
				if substr (_sLeitura, 7, 3) != 'EL_'
					U_Log2 ('debug', '[' + procname () + ']Peso nao estabilizado')
				else
					_nPeso = val (left (_sLeitura, 6))
					_lLeuOK = .T.
					U_Log2 ('debug', '[' + procname () + ']Peso estabilizado: ' + cvaltochar (_nPeso))
					exit
				endif
			else
				u_help ("Modelo de balanca sem tratamento.",, .t.)
			endif
			_nTentativ ++
		enddo
		if ! _lLeuOK
			if U_msgyesno ("Leitura da balanca nao foi realizada ou o peso esta zerado. Deseja ler novamente?")
				loop
			else
				exit
			endif
		else
			exit
		endif
	enddo
return _nPeso
