// Programa:  Help
// Autor:     Robert Koch
// Data:      22/07/2009
// Descricao: Direciona mensagens conforme o ambiente em uso.
//            Criada inicialmente para uso em rotinas sem interface com o usuario.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #PalavasChave      #auxiliar #avisos #mensagem #tela #uso_generico
// #TabelasPrincipais 
// #Modulos           

// Historico de alteracoes:
// 19/01/2010 - Robert  - Testa variavel oMainWnd para ver se existe interf. com usuario,
//                        pois a funcao IsBlind () nao atendeu rotinas automaticas.
// 26/10/2012 - Robert  - Possibilidade de mostrar dados adicionais.
// 21/05/2013 - Robert  - Criado tratamento para alimentar a variavel _sErroAuto, caso exista.
// 12/09/2014 - Robert  - Criado tratamento para modulo ACD.
// 09/08/2015 - Robert  - Passa a usar cValToChar () quando concatenar dados, pois nao se sabe o que vai ser recebido.
// 26/10/2015 - Robert  - Gravava os dados adicionais antes da mensagem (no arquivo de log).
// 04/01/2016 - Robert  - Grava na console somente quendo nao puder gerar arquivo de log.
// 24/05/2016 - Robert  - Grava mensagem no objeto _oBatch, caso exista.
// 07/05/2019 - Robert  - Concatena mensagem no objeto _oBatch somente se ainda nao constar no mesmo.
// 03/01/2020 - Robert  - Novo parametro _lErro usado para alimentar variaveis private. 
// 13/01/2020 - Robert  - Melhoria tratamento erros.
// 19/05/2020 - Robert  - Quebra texto quando muito long, para caber em tela.
// 09/06/2020 - Robert  - Tratamento para usar a funcao U_Log2.
// 09/07/2020 - Robert  - Desabilitadas chamadas da funcao U_LOG().
// 21/07/2020 - Robert  - Passa a gravar log e console sempre.
// 24/09/2021 - Claudia - Incluido o tratamento para retorno de mensagem WS.
//
// --------------------------------------------------------------------------
user function Help (_sMsg, _sDAdic, _lHlpErro)
	local _nQuebra := 0
	local _sMsgLog := ''

	// Gera arquivo de log, se possivel.
	if ExistBlock ("LOG2")  // Se pode gerar arquivo de log
		
		// Verifica necessidade de formatar a mensagem para gravacao de log
		_sMsgLog = _sMsg
		if valtype (_sDAdic) == "C" .and. ! empty (_sDAdic)
			_sMsgLog += chr (13) + chr (10) + "Dados adicionais: " + _sDAdic
		endif
		_sMsgLog = strtran (_sMsgLog, chr (10), chr (13) + chr (10))  // Erros do SQL, por exemplo, tem apenas chr(10)
		_sMsgLog = strtran (_sMsgLog, chr (13) + chr (10), chr (13) + chr (10) + space (32))
		
		U_Log2 (iif (_lHlpErro, 'ERRO', 'Info'), '[' + procname () + '] ' + _sMsgLog)
	endif
	
	// Grava na console do servico
	//ConOut (iif (_lHlpErro, '[ERRO]', '') + '[' + procname (1) + '] ' + cValToChar (_sMsg))
	if valtype (_sDAdic) == "C" .and. ! empty (_sDAdic)
		//ConOut ("Dados adicionais: " + _sDAdic)
	endif

	if ! _lHlpErro
		if type('_sMsgRetWS') == 'C'
			_sMsgRetWS := cValToChar(_sMsg)
		endif
	endif
	// Tratamentos em caso de mensagem de erro.
	_lHlpErro := iif (_lHlpErro == NIL, .F., _lHlpErro)
	if _lHlpErro != NIL .and. _lHlpErro
		if type ("_sErroAuto") == "C"  // Variavel private (customizada) para retorno de erros em rotinas automaticas.
			_sErroAuto += iif (empty (_sErroAuto), '', '; ') + cValToChar (_sMsg) + iif (valtype (_sDAdic) == "C", _sDAdic, "")
		endif
		if type ('_sErros') == 'C'  // Variavel private (customizada) geralmente usada em chamadas via web service.
			_sErros += iif (empty (_sErros), '', '; ') + cValToChar (_sMsg)
		endif
	endif

	if type ("_oBatch") == "O"
		_oBatch:Mensagens += iif (alltrim (_sMsg) $ _oBatch:Mensagens, '', '; ' + alltrim (_sMsg))
	endif

	if type ("oMainWnd") == "O"  // Se tem interface com o usuario
		if valtype (_sDAdic) == "C" .and. ! empty (_sDAdic) .and. existblock ("SHOWMEMO")
			U_ShowMemo (cValToChar (_sMsg) + chr (13) + chr (10) + chr (13) + chr (10) + "Dados adicionais:" + chr (13) + chr (10) + _sDAdic, procname (1) + " => " + procname (2))
		else
			// Se a mensagem for muito grande, quebra-a em varias linhas.
			if len (_sMsg) > 400 .and. ! chr (13) + chr (10) $ _sMsg
		//		u_log ('vou quebrar msg --> tamanho msg=', len(_sMsg))
				_nQuebra = 400
				do while _nQuebra < len (_sMsg)
		//			u_log (_nQuebra)
					_sMsg = left (_sMsg, _nQuebra) + chr (13) + chr (10) + substr (_sMsg, _nQuebra + 1)
		//			u_log (_sMsg)
					_nQuebra += 400
				enddo
		//		u_log ('fim quebra')
			endif
			msgalert (_sMsg, procname (1) + " => " + procname (2) + " => " + procname (3))
		endif
	else
		if cModulo == "ACD"
			vtalert (cValToChar (_sMsg))
		endif
	//	_sMsg = procname () + " ==> " + procname (1) + ": " + procname (2) + ": " + procname (3) + ": " + cvaltochar (_sMsg)
	endif

return
