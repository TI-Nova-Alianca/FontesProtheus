// Programa..:  SendMail
// Autor.....:  Robert Koch
// Data......:  15/01/2004
// Descricao.:  Rotina de envio de e-mail
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #rotina
// #Descricao         #Rotina de envio de e-mail
// #PalavasChave      #email #email_padrao #html #sendmail 
// #TabelasPrincipais #
// #Modulos   		  #TODOS 
//
// Exemplo de uso:
// processa ({||U_SendMail ("robert.koch@novaalianca.coop.br", "teste", "teste de envio de e-mail pelo Siga", {"arq1.txt", "arq2.txt"}, "conta_para_envio")})
//
// Historico de alteracoes:
// 05/06/2006 - Robert  - Passa a enviar tambem por WorkFlow (versao 8)
// 18/07/2006 - Robert  - Criada possibilidade de anexar arquivos
// 31/05/2008 - Robert  - Ajustado caminho do arquivo HTML.
// 24/06/2008 - Robert  - Removida parte que nao usava workflow.
//                      - Converte quebras de linha do texto original para <p> em HTML.
// 21/07/2008 - Robert  - Tratamento para chamadas com parametros incompletos.
//                      - Grava alguns dados adicionais no html.
// 30/07/2008 - Robert  - Nao continua se nao conseguir criar objeto HTML.
// 24/06/2009 - Robert  - Criada possibilidade de definir endereco de retorno (ReplyTo).
// 07/06/2010 - Robert  - Verifica a existencia do arquivo HTML.
// 10/11/2010 - Robert  - Passa a informar a empresa/filial no e-mail.
// 02/06/2011 - Robert  - Quebras de linha eram trocadas por tags de paragrafo no HTML. 
//                        Agora sao trocadas por tags de nova linha.
// 22/06/2012 - Robert  - Habilitado para Livramento (nao trabalha mais off-line).
//                      - Grava log quando nao conseguir enviar e-mail.
// 05/02/2013 - Robert  - Tratamento para usar diferentes contas de envio de e-mail.
// 22/03/2013 - Robert  - Quando ambiente de testes, somente envia com confirmacao do usuario.
// 25/06/2014 - Robert  - Acrescentado tratamento para o campo GrupoZZU no HTML.
// 27/11/2018 - Robert  - Valida a existencia da conta de envio, bem como deve estar ativa.
// 22/06/2020 - Robert  - Passa a usar a funcao U_LOG2 em vez da U_LOG.
// 16/07/2021 - Claudia - Retirado trecho de "texto recebido tem quebras de linha" 
//                        devido a má formação da tabela no html
// 14/12/2021 - Robert  - Verifica se eh ambiente R33 (testes release) e pede confirmacao para envio do e-mail.
// 28/01/2022 - Robert  - Criada opcao de envio em copia oculta.
// 08/09/2022 - Robert  - Melhorada mensagem de 'conta nao cadastrada'.
// 21/09/2022 - Robert  - Passa a usar a classe ClsAviso() para notificar problemas.
// 08/11/2022 - Robert  - Passa a usar a funcao U_AmbTeste().
//

// ----------------------------------------------------------------------------------------------
User Function SendMail (_sTo, _sSubject, _sBody, _aArq, _sCtaMail, _sGrupoZZU, _sBCC)
	local _lContinua := .T.
	local _oHtml     := NIL
	local _oProcess  := NIL
	local _sArqHTM   := "\fontes\Email_generico.htm"
	local _nArq      := 0
	local _sMsgErro  := ""
	local _aAreaAnt  := {}
	local _sArqMail  := ""
	local _oAviso    := NIL
	
	if _lContinua
		_aArq      := iif (_aArq      == NIL, {}, _aArq)
		_sSubject  := iif (_sSubject  == NIL, "", _sSubject)
		_sBody     := iif (_sBody     == NIL, "", _sBody)
		_sGrupoZZU := iif (_sGrupoZZU == NIL, "", _sGrupoZZU)
		_sBCC      := iif (_sBCC      == NIL, "", _sBCC)

		if empty (_sTo)
			u_help ("[" + procname () + "]: Nao foi especificado destinatario do e-mail",, .t.)
			_lContinua = .F.
		endif
	endif

//	if _lContinua .and. ("TESTE" $ upper (GetEnvServer()) .or. "R33" $ upper (GetEnvServer()))
	if _lContinua .and. U_AmbTeste ()
		if type ("oMainWnd") == "O"  // Se tem interface com o usuario
			_lContinua = U_msgnoyes ("Ambiente de TESTE. Confirme se deseja enviar a mensagem abaixo:" + chr (13) + chr (10) + chr (13) + chr (10) + alltrim (_sSubject))
		else
			u_help ("[" + procname () + "]: Ambiente de TESTES. O envio de e-mail deve ser confirmado pelo usuario, quando houver interface em uso.")
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! file (_sArqHTM)
		_lContinua = .F.
		u_help ("[" + procname () + "]: Arquivo '" + _sArqHTM + "' necessario para o envio de e-mail nao foi encontrado." + iif (type ("_sArqLog") == "C", " Mais detalhes no arquivo de log '" + _sArqLog + "'.", ""),, .t.)

		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = "Arquivo " + _sArqHTM + " (necessario para o envio de e-mail) nao foi encontrado."
		_oAviso:Texto      = "Para montagem do e-mail, eh necessario acesso ao arquivo " + _sArqHTM + ", que contem o HTML para formatar o corpo da mensagem."
		_oAviso:Origem     = procname ()
		_oAviso:InfoSessao = .T.  // Incluir informacoes adicionais de sessao na mensagem.
		_oAviso:Grava ()

//		u_AvisaTI ("[" + procname () + "]: Arquivo '" + _sArqHTM + "' necessario para o envio de e-mail nao foi encontrado." + iif (type ("_sArqLog") == "C", " Mais detalhes no arquivo de log '" + _sArqLog + "'.", ""))
	endif

	// Se foi especificado um endereco para retorno, preciso usar essa mesma conta para autenticacao no envio do e-mail.
	if _lContinua
		if valtype (_sCtaMail) == "C" .and. ! empty (_sCtaMail)
			_sCtaMail = upper (alltrim (_sCtaMail))
			wf7 -> (dbsetorder (1))  // WF7_FILIAL+WF7_PASTA
			if ! wf7 -> (dbseek (xfilial ("WF7") + _sCtaMail, .F.))
				_sMsgErro = "Conta de correio '" + _sCtaMail + "' nao cadastrada na tabela WF7. O e-mail sera´ enviado usando a conta padrao"
				_sCtaMail = "PROTHEUS"
			else
				_sCtaMail = wf7 -> wf7_pasta
			endif
		else
			_sCtaMail = "PROTHEUS"
		endif
	endif

	// Confirma se a conta a ser usada (mesmo que seja a padrao) existe e encontra-se ativa.
	if _lContinua
		wf7 -> (dbsetorder (1))  // WF7_FILIAL+WF7_PASTA
		if ! wf7 -> (dbseek (xfilial ("WF7") + _sCtaMail, .F.))
			_sMsgErro = "Conta de correio '" + _sCtaMail + "' nao cadastrada na tabela WF7. E-mail NAO sera enviado."
			_lContinua = .F.
		else
			if ! wf7 -> wf7_ativo
				_sMsgErro = "Conta de correio '" + _sCtaMail + "' encontra-se INATIVA na tabela WF7. E-mail NAO sera enviado."
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		procregua (2)
		incproc ("Aguarde, enviando e-mail...")
		
		// Se o texto recebido tem quebras de linha, troca-as por tags de nova linha em HTML.
		//_sBody = '<p><font face="Courier New" size="2">' + _sBody
		//_sBody = strtran (_sBody, chr(10), "")
		//_sBody = strtran (_sBody, chr(13), "<br>")
		//_sBody = _sBody + "</p>"
		
		// Cria processo de envio via workflow. O primeiro parametro vai ser gravado
		// no campo WF3_PROC, permitindo rastreamento (no caso, nao me interessa)
		_oProcess := Nil
		_oProcess := TWFProcess():New("SendMail", "Envio de e-mail generico" )
		_oProcess:oWF:cMailBox = _sCtaMail
		_oProcess:NewTask ("SendMail", _sArqHTM)

		for _nArq = 1 to len (_aArq)
			_oProcess:AttachFile (_aArq [_nArq])
		next

		_oProcess:cSubject := _sSubject
		_oHtml :=_oProcess:oHTML

		if valtype (_oHtml) == "O"
			_oHtml:ValByName ("TITULO", _sSubject)
			_oHtml:ValByName ("TEXTO", _sBody)
			_oHtml:ValByName ("DataHora", dtoc (date ()) + " - " + time ())
			_oHtml:ValByName ("Usuario", cUserName)
			_oHtml:ValByName ("Rotina", FunName ())
			_oHtml:ValByName ("Environment", GetEnvServer () + " Emp/filial: " + sm0 -> m0_codigo + '/' + sm0 -> m0_codfil)
			_oHtml:ValByName ("GrupoZZU", _sGrupoZZU)
			_oProcess:cTo  = _sTo
			_oProcess:cBCC = _sBCC
			_sArqMail = _oProcess:Start()
		endif
		_oProcess:Free()
		
		// Se nao for a conta padrao do sistema, os e-mails nao sao enviados automaticamente.
		StartJob( "WFLauncher", GetEnvServer(), .f., { "WFSndMsg", { cEmpAnt, cFilAnt, AllTrim( _sCtaMail ), .t. } } )

		u_log2 ('info', "[" + procname () + "] e-mail enviado para '" + _sTo + "': " + _sSubject + iif (! empty (_sBCC), ' BCC: ' + _sBCC, ''))
	endif

	if ! empty (_sMsgErro)
		//_sMsgErro += "[" + procname () + "]: Processo: " + _sArqMail + " " + _sMsgErro
		_sMsgErro = "[" + procname () + "]" + _sMsgErro + "[Processo WF:" + _sArqMail + "]"
		U_Help (_sMsgErro,, .t.)
//		U_AvisaTI (_sMsgErro)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = _sMsgErro
		_oAviso:Texto      = _sMsgErro
		_oAviso:Origem     = procname ()
		_oAviso:InfoSessao = .T.  // Incluir informacoes adicionais de sessao na mensagem.
		_oAviso:Grava ()
	endif

	if ! _lContinua
		u_log2 ('aviso', "[" + procname () + "]: Envio de e-mail CANCELADO! To: " + _sTo + ' Subject: ' + _sSubject)
	endif

	U_ML_SRArea (_aAreaAnt)
Return
