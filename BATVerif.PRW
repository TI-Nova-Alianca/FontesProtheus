// Programa:   BatVerif
// Autor:      Robert Koch
// Data:       01/11/2016
// Descricao:  Batch de verificacoes gerais e envio por e-mail.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Execucao de verificacoes e envio de avisos
// #PalavasChave      #verificacoes #validacoes #avisos
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 18/06/2019 - Robert - Incluido tratamento para setor CML (comercial)
//                     - Removido tratamento de nome de arquivo de log (jah vem pronto da rotina que dispara os batches).
// 06/10/2020 - Robert - Criado tratamento para envio de avisos para a informatica
//                     - Melhorados logs
//                     - Inseridas tags para catalogo de fontes.
// 18/11/2020 - Robert - Maioria das validacoes estava desabilitada (para testes) desde 10/09/2020 e esqueci assim.
// 31/08/2021 - Robert - Melhorias controle de loop de execucao e monitor de performance (GLPI 10876).
// 23/08/2022 - Robert - Apenas alguns desvios condigionais para simulacoes (GLPI 12134)
// 18/11/2022 - Robert - Verificacoes do setor INF passam a ser enviadas para o NaWeb e nao mais por e-mail.
// 24/10/2023 - Robert - Guarda tempos de execucoes em array para mostrar todos juntos no final.
//                     - Passa a mandar todas as notificacoes para o NaWeb e nao mais por e-mail.
// 29/10/2023 - Robert - Passa a aceitar parametros d verificacao inicial e final.
//                     - Criado envio para auditoria (grupo 015)
// 09/12/2023 - Robert - Melhorados logs
//

// --------------------------------------------------------------------------
user function BatVerif (_nVerifIni, _nVerifFim)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _oVerif    := NIL
	local _nVerif    := 0
	local _sMsg      := ""
	local _aTempos   := {}
	local _oAviso    := NIL
	local _oAUtil    := NIL

	u_log2 ('info', 'Iniciando execucao das verificacoes')

	_nVerifIni = iif (_nVerifIni == NIL, 1, _nVerifIni)
	if _nVerifFim == NIL
		_oVerif := ClsVerif ():New ()
		_nVerifFim = _oVerif:UltVerif
	endif

	// Executa cada verificacao e envia o resultado aos setores interessados.
	_nVerif = _nVerifIni

	aadd (_aTempos, {'Verif', 'Tempo', 'Descricao', 'Query', 'Avisos'})

	do while _nVerif <= _nVerifFim
		U_Log2 ('info', 'Vou ver se devo executar a verificacao ' + cvaltochar (_nVerif))
		_oVerif := ClsVerif ():New (_nVerif)
		if ! _oVerif:Ativa
			U_Log2 ('debug', '[' + procname () + ']Verificacao inativa.')
			_nVerif ++
			loop
		endif
		if ! _oVerif:ViaBatch
			U_Log2 ('debug', '[' + procname () + ']Verificacao nao deve ser executada via batch.')
			_nVerif ++
			loop
		endif
		if _oVerif:Filiais != '*' .and. !cFilAnt $ _oVerif:Filiais
			U_Log2 ('debug', '[' + procname () + ']Verificacao nao se destina a esta filial.')
			_nVerif ++
			loop
		endif

		u_log2 ('info', 'Verificacao ' + cvaltochar (_oVerif:Numero) + ' (' + _oVerif:Descricao + ') --> ' + _oVerif:Query)
			
		// Acompanhamento de performance de execucao de rotinas.
		aadd (_aTempos, {_nVerif, seconds (), _oVerif:Descricao, _oVerif:Query, 0})

		if _oVerif:Executa ()

			// Vou persistir o tempo de execucao somente se a verificacao foi mesmo executada.
			_aTempos [len (_aTempos), 2] = round (seconds () - _aTempos [len (_aTempos), 2], 2)
			_aTempos [len (_aTempos), 5] = _oVerif:QtErros

			if _oVerif:QtErros > 0

				// Prepara mensagem em formato HTM para envio por e-mail.
				_sMsg := _oVerif:ConvHTM (100)  // Converte poucas linhas para as mensagens nao ficarem pesadas demais.

				// Envia aos setores interessados.
				if 'ENG' $ _oVerif:Setores
					_Notif (_oVerif, {'070'}, _sMsg)
				endif
				if 'CUS' $ _oVerif:Setores
				//	_Envia (_oVerif, {'069'}, _sMsg)
					_Notif (_oVerif, {'069'}, _sMsg)
				endif
				if 'SAF' $ _oVerif:Setores
					_Notif (_oVerif, {'075'}, _sMsg)
				endif
				if 'FIS' $ _oVerif:Setores
					_Notif (_oVerif, {'019'}, _sMsg)
				endif
				if 'PCP' $ _oVerif:Setores
				//	_Envia (_oVerif, {'047'}, _sMsg)
					_Notif (_oVerif, {'047'}, _sMsg)
				endif
				if 'CML' $ _oVerif:Setores
					_Notif (_oVerif, {'003'}, _sMsg)
				endif
				if 'AUD' $ _oVerif:Setores
					_Notif (_oVerif, {'015'}, _sMsg)
				endif
				if 'INF' $ _oVerif:Setores
					_Notif (_oVerif, {'122'}, _sMsg)
				endif
			endif
		else
			U_help ("Problemas ao executar a verificacao '" + _oVerif:Descricao + ": " + _oVerif:UltMsg,, .T.)
			_aTempos [len (_aTempos), 2] = 'ERRO'
		endif
		FreeObj (_oVerif)
		_nVerif ++
	enddo

	// Mando um aviso pra mim mesmo, nos primeiros dias, para acompanhar o processo.
	_oAUtil := ClsAUtil ():New (_aTempos)
	//
	// Como pretendo enviar para o NaWeb via web service, preciso 'escapar' alguns
	// caracteres especiais das queries.
	for _nVerif = 1 to len (_aTempos)
		_oAUtil:_aArray [_nVerif, 4] = strtran (_oAUtil:_aArray [_nVerif, 4], "'", "&#39;")  // Aspas simples
		_oAUtil:_aArray [_nVerif, 4] = strtran (_oAUtil:_aArray [_nVerif, 4], '"', "&#34;")  // Aspas duplas
		_oAUtil:_aArray [_nVerif, 4] = strtran (_oAUtil:_aArray [_nVerif, 4], '<', "&lt;")  // Menor que
		_oAUtil:_aArray [_nVerif, 4] = strtran (_oAUtil:_aArray [_nVerif, 4], '>', "&gt;")  // Maior que
	next
	U_Log2 ('debug', _oAUtil:_aArray)
	_oAviso := ClsAviso():new ()
	_oAviso:Tipo       = 'I'  // I=Info;A=Aviso;E=Erro
	_oAviso:Titulo     = "Acomp.verif.em batch F" + cFilAnt
	_oAviso:Texto      = _oAUtil:ConvHTM ()
	_oAviso:DestinAvis = 'robert.koch'
	_oAviso:Origem     = 'Verificacoes diarias'
	_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
	_oAviso:Grava ()

	_oBatch:Retorno = 'S'
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log2 ('info', 'Finalizando execucao das verificacoes')
return



// --------------------------------------------------------------------------
// Envia resultado da verificacao por e-mail.
static function _Envia (_oVerif, _aGrupos, _sMsg)
	local _nGrupo  := 0
	local _aDest   := 0
	local _aIDs    := {}
	local _nID     := 0
	local _aEMails := {}
	local _nLiber  := 0

	if "ROBERT" $ upper (GetEnvServer()) .and. dtos (date ()) == '20220823'  // Simulacoes
		U_Log2 ('debug', 'Agora estaria enviando aviso para:')
		U_Log2 ('debug', _aGrupos)
		U_Log2 ('debug', _sMsg)
		return
	endif

	// Se a verificacao nao tem restricao de grupo, ja pode enviar para todos. 
	if empty (_oVerif:LiberZZU)
		U_ZZUNU (_aGrupos, "Verif.Protheus " + cvaltochar (_oVerif:Numero) + '-' + _oVerif:Descricao, _sMsg, .F.)
	else
	
		for _nGrupo = 1 to len (_aGrupos)

			// Verifica se cada usuario do grupo tem liberacao para esta verificacao.
			_aDest = aclone (U_ZZULD (_aGrupos [_nGrupo]))
			_aEMails = aclone (_aDest [2])
			_aIDs = aclone (_aDest [3])
			for _nID = 1 to len (_aIDs)
				for _nLiber = 1 to len (_oVerif:LiberZZU)
					if U_ZZUVL (_oVerif:LiberZZU [_nLiber], _aIDs [_nID], .F.)
						U_SendMail (_aEMails [_nID], "Verif.Protheus " + _oVerif:Descricao, _sMsg, {}, NIL, _aGrupos [_nGrupo])
						exit
					endif
				next
				u_log2 ('info', '')
			next
		next
	endif
return


// --------------------------------------------------------------------------
// Envia resultado da verificacao via notificacao no NaWeb.
static function _Notif (_oVerif, _aGrupos, _sMsg)
	local _oAviso  := NIL
	local _nGrupo  := 0
	local _aDest   := {}

	U_Log2 ('debug', '[' + procname () + ']Vou mandar notificacao pelo naweb')
	// Monta lista de destinatarios.
	for _nGrupo = 1 to len (_aGrupos)
		
		// Verifica se cada grupo recebido no parametro tem liberacao para ver esta verificacao.
		if empty (_oVerif:LiberZZU) .or. _aGrupos [_nGrupo] $ _oVerif:LiberZZU
			aadd (_aDest, _aGrupos [_nGrupo])
		endif
	next
	U_Log2 ('debug', _aDest)
	if len (_aDest) > 0
		_oAviso := ClsAviso():new ()
		_oAviso:Tipo       = 'A'  // I=Info;A=Aviso;E=Erro
		_oAviso:Titulo     = "Verif.Protheus " + cvaltochar (_oVerif:Numero) + '-' + _oVerif:Descricao
		_oAviso:Texto      = _sMsg
		_oAviso:DestinZZU  = _aDest  // Codigos de um grupo da tabela ZZU no formato {grp1, grp2, ...}
		_oAviso:Origem     = 'Verificacoes diarias'
		_oAviso:Formato    = 'H'  // [T]exto ou [H]tml
		_oAviso:Grava ()

		// Quero uma copia para acompanhamento (pelo menos nos primeiros dias)
		if valtype (_aDest) == 'A' .and. len (_aDest) >= 1 .and. _aDest [1] != '122'
			_oAviso:DestinZZU  = {}
			_oAviso:DestinAvis = 'robert.koch'
			_oAviso:Titulo     = "(Copia de)" + _oAviso:Titulo + ' enviado a ' + _aDest [1]
			_oAviso:Grava ()
		endif

	endif
return
