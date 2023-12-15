// Programa:  MsgYesNo
// Autor:     Robert Koch
// Data:      01/02/2014
// Descricao: Substitui funcao padrao MsgYesNo, com recurso adicional de mostrar
//            a mensagem em tela somente quando houver interface com o usuario.
//            Criada inicialmente para compatibilidade com rotinas executadas em batch.
//
// Historico de alteracoes:
// 16/06/2015 - Robert - Passa a gravar a resposta (retorno) no arquivo de log.
// 06/07/2020 - Robert - Passa a usar U_LOG2(). Tambem passa a gravar log sempre (antes era apenas na falta de interface com o usuario).
// 16/02/2022 - Robert - Se existir a variavel _sErros, alimenta-a.
// 20/02/2022 - Robert - Variavel _sErros (publica do web service) renomeada para _sErroWS
// 05/01/2023 - Robert - Incluido tratamento para telnet.
//

// ---------------------------------------------------------------------------
User Function MsgYesNo (_sMsg, _lDefault)
	Local _lRet := .F.

	if type ("oMainWnd") == "O"  // Se tem interface com o usuario
//		_lRet = msgyesno (_sMsg, 'Pergunta')
		_lRet = msgyesno (_sMsg, procname (1) + ' => ' + procname (2))
	else
		if IsInCallStack ("SIGAACD")
			_lRet = VtYESNO(_sMsg,'Atencao',.t.)
		else
			_lRet = iif (valtype (_lDefault) == "L", _lDefault, .F.)
		endif
	endif

	// Se esta variavel estiver definida, eh por que estah sendo executada alguma rotina automatica, e a mensagem deve ser retornada atraves dela.
	if ! _lRet .and. type ("_sErroAuto") == "C"
		_sErroAuto += '[' + procname () + '] [' + cValToChar (_lRet) + '] ' + strtran (_sMsg, chr (10) + chr (13), ' ')
	endif

	// Se esta variavel estiver definida, eh por que estah sendo executada alguma rotina via web service, e a mensagem deve ser retornada atraves dela.
	if ! _lRet .and. type ("_sErroWS") == "C"
		_sErroWS += '[' + procname () + '] [' + cValToChar (_lRet) + '] ' + strtran (_sMsg, chr (10) + chr (13), ' ')
	endif

	if ExistBlock ("LOG2")  // Se pode gerar arquivo de log
		u_log2 ('INFO', '[' + procname () + '] [' + cValToChar (_lRet) + '] ' + strtran (_sMsg, chr (10) + chr (13), ' '))
	endif
Return _lRet
