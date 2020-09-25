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

	u_logIni ()

	if _sModelo == 'Digitron'
		_sStrPorta = _sPorta + ":9600,n,8,1"
	elseif _sModelo == 'Saturno'
		_sStrPorta = _sPOrta + ":4800,n,8,1"
	else
		u_help ("Modelo de balanca desconhecido")
	endif
	u_log (_sStrPorta)

	// Testa se consegue abrir a porta serial.
	if ! MsOpenPort (_nHdl, _sStrPorta, .F.)
		u_help ("Impossivel comunicar com a porta " + _sPorta)
		MSCloseport (0)
		_lContinua = .F.
	endif
	
	// Loop para possibilitar ao usuario que faca nova tentativa.
	do while _lContinua

		// Loop para aguardar que a balanca se estabilize.
		_nTentativ = 0
		do while _nTentativ <= 5
			u_log ('Iniciando tentativa', _nTentativ)
			MSOpenPort (0, _sStrPorta)
//			MSOpenPort (_nHdl, _sStrPorta)
			sleep (500)      // ver o melhor tempo
			MSRead (_nHdl, @_sLeitura)
			mscloseport (0)
			u_log ('String lida da serial:', _sLeitura)
			if _sModelo == 'Digitron'
				if left (_sLeitura, 1) != 'D'
					u_log ('Peso nao estabilizado')
				else
					_nPeso = val (substr (_sLeitura, 2, 6))
					_lLeuOK = .T.
					u_log ('Peso estabilizado:', _nPeso)
					exit
				endif
			elseif _sModelo == 'Saturno'
				if substr (_sLeitura, 7, 3) != 'EL_'
					u_log ('Peso nao estabilizado')
				else
					_nPeso = val (left (_sLeitura, 6))
					_lLeuOK = .T.
					u_log ('Peso estabilizado:', _nPeso)
					exit
				endif
			else
				u_log ("Modelo de balanca sem tratamento.")
			endif
			_nTentativ ++
		enddo
		if ! _lLeuOK
			if msgyesno ("Leitura da balanca nao foi realizada ou o peso esta´ zerado. Deseja ler novamente?")
				loop
			else
				exit
			endif
		else
			exit
		endif
	enddo
	u_logFim ()
return _nPeso