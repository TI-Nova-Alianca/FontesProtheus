// Programa...: RBatch
// Autor......: Robert Koch
// Data.......: 27/05/2009
// Descricao..: Executa em 'batch' as rotinas agendadas na tabela ZZ6.
//              Deverah existir uma chamada (via schedule do Windows) para cada emp/filial onde for necessario.
// Historico de alteracoes:
// 15/06/2009 - Robert - Implementado tratamento para processo tipo 05.
// 19/08/2009 - Robert - Passa a validar dias da semana.
// 31/08/2009 - Robert - Nao olhava campo ZZ6_HRFIM
// 25/08/2013 - Robert - Criado tratamento para tempo de retentativa (zz6_minret).
// 05/12/2013 - Robert - Passa a controlar rodizio entre empresas e filiais.
// 09/01/2015 - Robert - Passa a controlar data e hora de ultima execucao em cada filial.
// 01/09/2015 - Robert - Passa a calcular a data e hora da proxima execucao via SQL.
// 08/09/2015 - Robert - Query de leitura da data/hora de ultima execucao nao considerava a filial atual.
// 23/09/2015 - Robert - Nao tenta mais executar processos com status 'K'.
// 20/10/2015 - Robert - Passa a usar a funcao VA_FPROX_EXEC_BATCH do SQL para verificar batches a executar.
// 02/12/2016 - Robert - Verifica se o batch foi inativado depois de gerar a lista de batches pendentes.
// 21/03/2017 - Robert - Verifica se o batch encontra-se fora do horario limite depois de gerar a lista de batches pendentes.
// 04/10/2017 - Robert - Desabilitadas empresas/filiais em desuso
// 26/06/2019 - Robert - Define mais variaveis de ambiente (reldir), seta century on
//                     - Instancia objeto da classe ClsBatch e executa-o em vez de chamar o VA_ZZ6EX
// 11/11/2019 - Robert - Incluida a filial 16 para execucao.
// 28/11/2019 - Robert - Grava aviso quando encontrar bloqueio de semaforo.
// 18/12/2019 - Robert - Pequenos ajustes para filial 16
//

#include "tbiconn.ch"

// --------------------------------------------------------------------------
User Function RBatch (_sEmp, _sFil)
	local _lContinua  := .T.
	local _aSeq       := {}
	local _nSeq       := 0
	//local _aProxAvis  := {}
	//local _lExecuta   := .F.
	//local _sLogAnt    := ""
	local _nLock      := 0
	local _sModulo    := ""
	local _sArqModul  := ""
//	local _aProxExec  := {}
	local _nHdl       := 0
	local _sArqEmpFi  := ""
//	local _sUltEmpFi  := ""
	local _aUltEmpFi  := {}
	local _nUltEmpFi  := 0
//	local _dDtUExe    := ctod ('')
//	local _sHrUExe    := ""
	local _nTenta     := 0
	local _lGlbOK     := .F.
	local _sVarGlob   := ""
//	local _sSQLUExe   := ""
//	local _sSQLIntRp  := ""
//	local _sSQLProx   := ""
	local _oSQL       := NIL
	local _oAviso     := NIL 

	set century on
	
	//ConOut (procname () + ' ' + dtoc (date ()) + ' ' + time ())
	if _lContinua
		if _sEmp == NIL .or. _sFil == NIL
			u_log2 ('erro', "Parametros de emp/filial nao definidos.")
			_lContinua = .F.
		endif
	endif

	// Grava arquivo indicando qual a ultima empresa/filial para a qual a rotina foi executada, para poder fazer um rodizio.
	// Se for aberta uma nova filial, deve ser incluida aqui.
	_sArqEmpFi = 'Batches_ultima_empresa_filial.txt'
	_aUltEmpFi = {}
	aadd (_aUltEmpFi, '0101')
	aadd (_aUltEmpFi, '0103')
	aadd (_aUltEmpFi, '0105')// ; aadd (_aUltEmpFi, '0101') //; aadd (_aUltEmpFi, '0113')
	aadd (_aUltEmpFi, '0106')
	aadd (_aUltEmpFi, '0107')
	aadd (_aUltEmpFi, '0108')
	aadd (_aUltEmpFi, '0109')// ; aadd (_aUltEmpFi, '0101') //; aadd (_aUltEmpFi, '0113')
	aadd (_aUltEmpFi, '0110')
	aadd (_aUltEmpFi, '0111')
	//aadd (_aUltEmpFi, '0112')
	aadd (_aUltEmpFi, '0113')
	aadd (_aUltEmpFi, '0116')

	if file (_sArqEmpFi)
		_nUltEmpFi = val(alltrim (memoread (_sArqEmpFi)))
	else
		_nUltEmpFi = 1
	endif
	if valtype (_nUltEmpFi) != "N" .or. _nUltEmpFi < 0 .or. _nUltEmpFi > len (_aUltEmpFi)
		_nUltEmpFi = 1
	endif
	_sEmp = substr (_aUltEmpFi [_nUltEmpFi], 1, 2)
	_sFil = substr (_aUltEmpFi [_nUltEmpFi], 3, 2)
	delete file (_sArqEmpFi)
	if file (_sArqEmpFi)
		_nHdl = fopen(_sArqEmpFi, 1)
	else
		_nHdl = fcreate(_sArqEmpFi, 0)
	endif
	fwrite (_nHdl, cvaltochar (iif (_nUltEmpFi >= len (_aUltEmpFi), 1, _nUltEmpFi + 1)))
	fclose (_nHdl)


	private _sArqLog := procname () + '_' + dtos (date ()) + ".log"

	// Como alguns batches exigem ser executados em determinados modulos, na primeira tentativa de execucao
	// em modulo diferente eles vao gerar um arquivo contendo o modulo que precisam. Assim, na proxima
	// execucao desta rotina, tentarei acessar o modulo desejado.
	_sArqModul = 'Modulo_preferencial_para_batches_empfil_' + _sEmp + _sFil + '.txt'
	if file (_sArqModul)
		_sModulo = ALLTRIM (memoread (_sArqModul))
		if ! IsDigit (left (_sModulo, 1)) // $ "ATF/COM/FAT/FIN/EST"
			u_log2 ('info', 'Vou usar o modulo preferencial ' + _sModulo)
		else
			u_log2 ('info', 'Modulo preferencial desconhecido: ' + cvaltochar (_sModulo))
			_sModulo = ''
		endif
		// Deleta arquivo para que a proxima execucao volte a ser 'generica'.
		delete file (_sArqModul)
	endif

	if _lContinua
	
		// Prepara ambiente. Abre arquivos, cria variaveis, etc.
		if ! empty (_sModulo)
			prepare environment empresa _sEmp filial _sFil modulo _sModulo
		else
			prepare environment empresa _sEmp filial _sFil
		endif
		private __cUserId := "000000"
		private cUserName := "ADMINISTRADOR"
		private __RelDir  := "c:\temp\spool_protheus\"
		set century on
	endif
//	u_log2 ('debug', '[' + procname () + '] ambiente preparado para emp/filial ' + _sEmp + _sFil)
	PtInternal (1, 'Iniciando emp/filial ' + _sEmp + _sFil)

	// Gera log soh depois de inicializar ambiente.
//	u_log2 ('info', 'Iniciando execucao de batches para emp_filial ' + _sEmp + _sFil + ' Thread ' + cvaltochar (ThreadId ()))

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname () + _sEmp + _sFil, .F.)
		if _nLock == 0
			u_log2 ('erro', "Bloqueio de semaforo.")
			_lContinua = .F.

			// Gera aviso para monitoramento
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'A'
			_oAviso:Destinatar = 'grpTI'
			_oAviso:Texto      = 'Bloqueio de semaforo para execucao de batches na empresa/filial ' + _sEmp + _sFil
			_oAviso:Origem     = procname ()
			_oAviso:DiasDeVida = 5
			_oAviso:Grava ()
		endif
	endif

	if _lContinua

		// Busca batches a executar. Relaciona com o SM0 para casos de ter mais de uma filial de destino no batch.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "WITH CTE AS ("
		_oSQL:_sQuery += "SELECT ZZ6.R_E_C_N_O_, ZZ6.ZZ6_PRIOR, dbo.VA_FPROX_EXEC_BATCH (ZZ6.R_E_C_N_O_, SM0.M0_CODIGO, SM0.M0_CODFIL) AS PROX_EXEC"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZ6") + " ZZ6, "
		_oSQL:_sQuery +=       " VA_SM0 SM0 "
		_oSQL:_sQuery += " WHERE ZZ6.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SM0.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SM0.M0_CODIGO = ZZ6_EMPDES"
		_oSQL:_sQuery +=   " AND ZZ6.ZZ6_FILDES LIKE '%' + SM0.M0_CODFIL + '%'"
		_oSQL:_sQuery +=   " AND SM0.M0_CODFIL  = '" + cFilAnt + "'"
		_oSQL:_sQuery +=   " AND ZZ6.ZZ6_EMPDES = '" + cEmpAnt + "'"
		_oSQL:_sQuery +=   " AND dbo.VA_FPROX_EXEC_BATCH (ZZ6.R_E_C_N_O_, SM0.M0_CODIGO, SM0.M0_CODFIL) IS NOT NULL"
		_oSQL:_sQuery += ") SELECT *"
		_oSQL:_sQuery += " FROM CTE"
		_oSQL:_sQuery += " WHERE PROX_EXEC <= CURRENT_TIMESTAMP"
		_oSQL:_sQuery += " ORDER BY ZZ6_PRIOR, PROX_EXEC"
		//_oSQL:Log ()
		_aSeq := aclone (_oSQL:Qry2Array ())
		for _nSeq = 1 to len (_aSeq)
			zz6 -> (dbgoto (_aSeq [_nSeq, 1]))

        	// Verifica se o batch ainda encontra-se ativo (pode ter havido alteracao manual depois que gerei a array de batches pendentes)
        	if zz6 -> zz6_ativo != 'S'
        		u_log2 ('aviso', 'batch inativo.')
        		loop
        	endif

        	// Verifica se jah passou o horario limite (pode ter havido alteracao manual depois que gerei a array de batches pendentes ou demora no batch anterior)
        	if zz6 -> zz6_hrfim < left (time (), 5)
        		u_log2 ('aviso', 'Fora do horario limite de execucao para este batch.')
        		loop
        	endif

        	// Cria uma variavel global indicando o inicio da execucao deste batch.
			_nTenta := 0
			_lGlbOK := .F.
			_sVarGlob := 'Batch_' + alltrim (str (ThreadId ()))
			do while _nTenta++ <= 5
				if GlbLock ()
					PutGlbValue (_sVarGlob, str (zz6 -> (recno ())))
					GlbUnlock ()
					_lGlbOk = .T.
					exit
				else
					u_log2 ('debug', 'Tentativa ' + cvaltochar (_nTenta) + ' de acesso a lista de variaveis globais.')
					sleep (500)
				endif
			enddo
			if ! _lGlbOk
				u_help ('Nao foi possivel gravar variavel global de controle de batches.',, .t.)
			else
			
				// Endereca monitor
				PtInternal (1, "Emp :"+cEmpAnt+"/"+cFilAnt+" - " + alltrim (zz6 -> zz6_cmd))

				// Chama a execucao.
				//U_VA_ZZ6Ex ()
				//conout (zz6 -> zz6_cmd)
				_oBatch := ClsBatch ():New (zz6 -> (recno ()))
				_oBatch:Executa ()
				
				// Limpa variavel global.
				ClearGlbValue (_sVarGlob)
			endif
		next
	endif

	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

//	u_log2 ('info', 'Finalizando execucao para emp_filial ' + _sEmp + _sFil + ' Thread ' + cvaltochar (ThreadId ()))
	u_log2 ('info', '')  // Apenas para dar uma linha vazia
return