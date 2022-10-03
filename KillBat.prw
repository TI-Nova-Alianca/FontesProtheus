// Programa...: KillBat
// Autor......: Robert Koch
// Data.......: 19/03/2015
// Descricao..: Finaliza a execucao de batches que ficaram 'pendurados'.
//              Criado para ser executado, evidentemente, via batch...
//
// Historico de alteracoes:
// 01/09/2022 - Robert - Melhorias ClsAviso.
// 02/10/2022 - Robert - Removido atributo :DiasDeVida da classe ClsAviso.
//

#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function KillBat ()
	local _aThreads   := {}
	local _nThread    := 0
	local _sVarGlob   := ""
	local _nRegZZ6    := 0
	local _nTmpExec   := 0
	local _oAviso     := NIL

	// Abre arquivos, etc.
	prepare environment empresa '01' filial '01'

	u_LogId ()
	u_logIni ()
	u_logDH ()

	// aInfo[x][01] = (C) Nome de usu�rio
	// aInfo[x][02] = (C) Nome da m�quina local
	// aInfo[x][03] = (N) ID da Thread
	// aInfo[x][04] = (C) Servidor (caso esteja usando Balance; caso contr�rio � vazio)
	// aInfo[x][05] = (C) Nome da fun��o que est� sendo executada
	// aInfo[x][06] = (C) Ambiente(Environment) que est� sendo executado
	// aInfo[x][07] = (C) Data e hora da conex�o
	// aInfo[x][08] = (C) Tempo em que a thread est� ativa (formato hh:mm:ss)
	// aInfo[x][09] = (N) N�mero de instru��es
	// aInfo[x][10] = (N) N�mero de instru��es por segundo
	// aInfo[x][11] = (C) Observa��es
	// aInfo[x][12] = (N) (*) Mem�ria consumida pelo processo atual, em bytes
	// aInfo[x][13] = (C) (**) SID - ID do processo em uso no TOPConnect/TOTVSDBAccess, caso utilizado.
	_aThreads := GetUserInfoArray ()
	u_log (_aThreads)
	for _nThread = 1 to len (_aThreads)
		_sVarGlob = 'Batch_' + alltrim (str (_aThreads [_nThread, 3]))
		_nRegZZ6  = val (GetGlbValue (_sVarGlob))
		_nTmpExec = TimeGlbValue (_sVarGlob)
		u_log ('Verificando thread', _nThread, ' -> Tempo de execucao:', _nTmpExec)

		// Se estah sendo executado ha mais de X tempo, verifica do que se trata.
		if _nTmpExec > 10 .and. _nRegZZ6 > 0
			zz6 -> (dbgoto (_nRegZZ6))
			u_log ('Encontrei thread', _aThreads [_nThread, 3], 'executando batch do recno', _nRegZZ6, 'do ZZ6 (' + alltrim (zz6 -> zz6_cmd) + ') ha', _nTmpExec, 'segundos. Tempo limite =', 60 * zz6 -> zz6_tmplim, 'segundos.')
			if ! 'U_KILLBAT' $ upper (alltrim (zz6 -> zz6_cmd))

				// Se estiver sendo executado ha mais tempo do que o limite informado, encerra o processo.
				if _nTmpExec > 60 * zz6 -> zz6_tmplim
					u_log ('Encerrando thread', zz6 -> zz6_cmd)

					// Gera aviso para acompanhamento
					_oAviso := ClsAviso ():New ()
					_oAviso:Tipo       = 'A'
					_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
					_oAviso:Texto      = 'Nao deveria ser necessario aplicar kill no batch com seq.' + zz6 -> zz6_seq + ' ' + alltrim (zz6 -> zz6_cmd)
					_oAviso:Origem     = procname ()
					_oAviso:Grava ()
					
					// Elimina o processo.
					KillUser (_aThreads [_nThread, 1], _aThreads [_nThread, 2], _aThreads [_nThread, 3], _aThreads [_nThread, 4])
					reclock ("ZZ6", .F.)
					zz6 -> zz6_rodado = 'K'
					msunlock ()
				endif
			else
				u_log ('Eh o killbat. nao me interessa')
			endif
		endif 
	next

	u_logFim ()
return
