// Programa...: VA_ZZ6
// Autor......: Robert Koch
// Data.......: 19/06/2008
// Descricao..: Tela de manutencao de processos batch

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Manutencao de rotinas batch
// #PalavasChave      #batches
// #TabelasPrincipais #ZZ6
// #Modulos           

// Historico de alteracoes:
// 04/05/2009 - Robert - Implementado processo 03 (replica produtos da matriz para a Vinicola)
// 11/05/2009 - Robert - Verifica se o produto jah existe antes de replicar para a vinicola.
// 15/06/2009 - Robert - Implementacao do processo tipo 05.
// 18/08/2009 - Robert - Implementacao do processo tipo 07.
// 24/08/2009 - Robert - Implementacao execucao via campo ZZ6_CMD.
// 23/09/2009 - Robert - Importacao do replica passa a gerar um batch para cada arquivo.
// 14/06/2010 - Robert - Gravacao de data e hora de termino da ultima execucao.
// 07/07/2010 - Robert - Envia e-mail para livramento confirmando importacao do arquivo.
// 04/11/2010 - Robert - Rotina de chamada da replica passada deste programa para o BatRep.
// 01/11/2010 - Robert - Verificacao dos campos DtBase, AnoMes e Modulo do ZZ6.
// 02/12/2010 - Robert - Criado bloqueio via semaforo para cada processo, para evitar execucao
//                       em paralelo no servidor (batch agendado) e na estacao (metoto Executa).
//                     - Criadas teclas de atalho para alterar o status do processo.
// 21/02/2011 - Robert - Criado tratamento para quando der erro em rotina automatica, mas nao houver arquivo de log gerado.
// 25/03/2011 - Robert - Funcao 07 (e-mail com titulos atrasados) passada para funcao externa.
// 16/05/2011 - Robert - Criada funcao VA_ZZ6ER para execucao remota de batches.
// 25/07/2012 - Robert - Gravacao campos zz6_ExAcum e zz6_HrAcum.
// 27/09/2012 - Robert - Passa a verificar tamanho do campo D2_DOC nas funcoes _Exec01 e _Exec02.
// 12/10/2012 - Robert - Passa a gravar arquivo com o modulo preferencial para a proxima execucao.
// 15/04/2015 - Robert - Passa a deixar objeto _oBatch disponivel para os processos agendados lerem/gravarem dados.
//                     - Chamada da funcao U_ZZ6Ex passa a ter regua de processamento.
// 11/05/2015 - Robert - Criada opcao de copia de registro.
// 09/09/2015 - Robert - Desabilitadas funcoes _Exec01, _Exec02, _Exec03 e _Exec06 por nao serem mais usadas.
// 28/09/2015 - Robert - Gravacao do campo ZZ6_MSG.
// 30/12/2015 - Robert - Atualiza o 'monitor' com o comando que vai ser executado, para ajudar no acompanhamento dos processos.
// 25/01/2016 - Robert - Melhoria na legenda.
// 19/06/2017 - Robert - Liberadas rotinas de custo medio para Liane e Diuli.
// 15/12/2017 - Robert - Valida usuarios pelo grupo 000000 (admin). 
// 17/05/2019 - Robert - Tratamento para rodar na base de testes (verifica campo zz6_AmbTst).
// 07/06/2019 - Robert - Tratamento para o campo ZZ6_ARQLOG
// 10/06/2019 - Robert - Ajustes geracao nome arquivo de log
//                     - Criada opcao de visualizar o log do batch em questao.
// 17/06/2019 - Catia  - alterado rotinas de custo medio para a rotina ZZU 69 - estava fixo usuario da liane
// 24/09/2019 - Robert - Mostra mensagens do objeto no final da execucao.
// 18/12/2019 - Robert - Melhoradas mensagens de 'destina-se a outra filial'.
// 11/05/2020 - Robert - Acrescentada empresa e filial ao nome do arquivo de log.
// 02/06/2020 - Robert - Arquivos de log passaram a ser gravados em pasta especifica.
// 27/07/2020 - Robert - Verificacao de acesso para desabilitar batch custo médio: passa a validar acesso 113 e nao mais 069.
//                     - Inseridas tags para catalogacao de fontes
//

// --------------------------------------------------------------------------
user function VA_ZZ6 ()
	local _aCores    := U_VA_ZZ6LG (.T.)
	local _sFiltrTop := ""
	private aRotina  := {}

	aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0, 1})
	aadd (aRotina, {"&Visualizar"       , "AxVisual", 0, 2})
	aadd (aRotina, {"&Incluir"          , "AxInclui", 0, 3})
	aadd (aRotina, {"&Alterar"          , "AxAltera", 0, 4})
	aadd (aRotina, {"&Excluir"          , "AxDeleta", 0, 5})
	aadd (aRotina, {"Visualizar &Log"   , "U_VA_ZZ6VL ()", 0, 2})
	aadd (aRotina, {"E&xecutar local"   , "U_VA_ZZ6EL ()", 0, 5})
	aadd (aRotina, {"&Copiar"           , "U_VA_ZZ6C ()", 0,5})
	aadd (aRotina, {"&Legenda"          , "U_VA_ZZ6LG (.F.)", 0,5})
	private cString   := "ZZ6"
	private cCadastro := "Manutencao de processos batch"

	if ascan (UsrRetGrp (__cUserId), '000000') > 0
		_sFiltrTop := ""
	elseif u_zzuvl ('113', __cUserId, .T.)
		_sFiltrTop := " UPPER(ZZ6_CMD) LIKE '%U_BATCMED%'"
	else
		u_help ("Usuario sem acesso.",, .t.)
		return
	endif
	
	mBrowse(,,,,"ZZ6",,,,,, _aCores,,,,,,,,_sFiltrTop)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function VA_ZZ6LG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"zz6_ativo != 'S'",                         'BR_PRETO',    'Inativo'})
	aadd (_aCores, {"zz6_ativo == 'S' .and. zz6_rodado == 'S'", 'BR_VERMELHO', 'S=Executado'})
	aadd (_aCores, {"zz6_ativo == 'S' .and. zz6_rodado == ' '", 'BR_VERDE',    'N=Pendente'})
	aadd (_aCores, {"zz6_ativo == 'S' .and. zz6_rodado == 'I'", 'BR_AMARELO',  'I=Iniciado'})
	aadd (_aCores, {"zz6_ativo == 'S' .and. zz6_rodado == 'C'", 'BR_MARRON',   'C=Cancelado (mantido apenas para historico)'})
	aadd (_aCores, {"zz6_ativo == 'S' .and. zz6_rodado == 'E'", 'BR_AZUL',     'E=Encerrado por tempo'})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return



// --------------------------------------------------------------------------
// Chama execucao local dos processos. Criado apenas para poder usar regua de processamento.
user function VA_ZZ6EL ()
	// Algumas rotinas esperam encontrar este objeto para ler/atualizar dados.
	private _oBatch := ClsBatch ():New (zz6 -> (recno ()))

	processa ({|| U_VA_ZZ6Ex ()})
return



// --------------------------------------------------------------------------
// Chama execucao dos processos. Esta rotina tambem eh executada via schedule
// e deve estar preparada para isso.
user function VA_ZZ6Ex ()
	local _lExecOK   := .F.
	local _lContinua := .T.
	local _nLock     := 0
	local _sDtHrIni  := ""
	local _nPosFLog  := 0
	local _sNomeLog  := ""
	static _lAmbProd := (U_RetSQL ("SELECT CASE WHEN db_name() = 'protheus' THEN 1 ELSE 0 END") == 1)

	procregua (10)
	incproc (alltrim (zz6 -> zz6_cmd))

	if _lContinua .and. ! _lAmbProd
		u_log2 ('aviso', 'Nao estou no ambiente de producao')
		if zz6 -> zz6_ambtst != 'S'
			u_help ("Processo " + ZZ6 -> ZZ6_SEQ + " liberado para executar somente na base de producao.",,.t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. (zz6 -> zz6_EmpDes != cEmpAnt .or. ! alltrim (cFilAnt) $ zz6 -> zz6_FilDes)
		u_help ("Processo destinado a outra empresa (" + alltrim (zz6 -> zz6_EmpDes) + ") ou filial (" + alltrim (zz6 -> zz6_FilDes) + "). Estou logado na " + cEmpAnt + '/' + cFilAnt + '.',, .t.)
		_lContinua = .F.
	endif
	
	if _lContinua .and. zz6 -> zz6_rodado == "S" .and. zz6 -> zz6_Period == "U"
		u_help ("Processo ja' executado.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. zz6 -> zz6_agwf == "S"
		u_help ("Processo aguardando liberacao por retorno de workflow.",, .t.)
		_lContinua = .F.
	endif

	// Altera data base conforme exigido pelo processo.
	if _lContinua
		if ! empty (zz6 -> zz6_DtBase) .and. zz6 -> zz6_DtBase != dDataBase
			dDataBase = zz6 -> zz6_DtBase
			u_help ("Alterando data base para " + cvaltochar (dDataBase) + " conforme data base exigida pelo batch")
		else
			if ! empty (zz6 -> zz6_AnoMes) .and. zz6 -> zz6_AnoMes != left (dtos (dDataBase), 6)
				dDataBase = lastday (stod (zz6 -> zz6_AnoMes + "01"))
				u_help ("Alterando data base para " + cvaltochar (dDataBase) + " conforme ano/mes exigido pelo batch")
			endif
		endif
	endif
	if _lContinua .and. zz6 -> zz6_Modulo != 0 .and. zz6 -> zz6_Modulo != nModulo
		u_help ("Processo '" + zz6 -> zz6_seq + "' deve ser executado dentro do modulo " + cvaltochar (zz6 -> zz6_modulo) + ' e nao no modulo ' + cvaltochar (nModulo),, .t.)
		_Preferen (zz6 -> zz6_modulo)
		_lContinua = .F.
	endif

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname () + zz6 -> zz6_EmpDes + zz6 -> zz6_FilDes + zz6 -> zz6_seq, .F.)
		if _nLock == 0
			u_help ("Bloqueio de semaforo. Processo jah estah sendo executado.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Se ainda nao existe objeto da classe ClsBatch, cria-o para acompanhamento do processo,
		// pois algumas rotinas esperam encontra-lo para ler/atualizar dados.
		if type ("_oBatch") != "O"
			private _oBatch := ClsBatch ():New (zz6 -> (recno ()))
		endif

		// Define nome para o arquivo de log a ser gravado pela rotina.
		if ! empty (zz6 -> zz6_cmd)
			_nPosFLog = at ('(', zz6 -> zz6_cmd) - 1
			_nPosFLog = len (alltrim (left (zz6 -> zz6_cmd, _nPosFLog)))
			_sArqLog2 := iif (type ("_sArqLog") == 'C', _sArqLog, '')  // Salva nome do arquivo de log corrente
			_sNomeLog := alltrim (left (zz6 -> zz6_cmd, _nPosFLog)) + "_" + alltrim (cusername) + '_' + dtos (date ()) + ".log"

			// Algumas rotinas quero gerar logs mais especificos
			if 'U_BATREVCH' $ upper (zz6 -> zz6_cmd)
				_sNomeLog := alltrim (left (zz6 -> zz6_cmd, _nPosFLog))
				_sNomeLog += "_" + substr (zz6 -> zz6_cmd, 14, 2) + "_" + substr (zz6 -> zz6_cmd, 20, 3)  // Tah bom, eu sei que um espacinho na cahamada vai avacalhar tudo...
				_sNomeLog += "_" + alltrim (cusername) + '_' + dtos (date ()) + ".log"
			endif
		endif

		// Antes de iniciar a execucao, marca o processo como 'iniciado' para poder
		// saber, depois, se teve problemas na execucao.
		// Grava data e hora de inicio da ultima execucao pois, se der erro durante
		// o processamento, nao vai mais poder gravar esses dados.
		// Testa se consegue bloquear o registro, para pegar casos de chamada via
		// metodo :Exec da classe ClsBatch, ainda da transacao que gravou o registro do ZZ6.
		if softlock ("ZZ6")
			reclock ("ZZ6", .F.)
			zz6 -> zz6_rodado = "I"
			zz6 -> zz6_DtUExe = date ()
			zz6 -> zz6_HrUExe = time ()
			zz6 -> &("ZZ6_DUEF" + cFilAnt) = date ()
			zz6 -> &("ZZ6_HUEF" + cFilAnt) = time ()
			zz6 -> zz6_arqlog = _sNomeLog
			msunlock ()
		else
			u_log2 ('erro', 'Processo em execucao: Insucesso no softlock.')
		endif
		_sDtHrIni = dtos (date ()) + time ()

		// Conta as tentativas antes de executar, pois existem casos de processos
		// que ficam pendurados e acabariam nunca incrementando a qt. de tentativas.
		if zz6 -> zz6_Period == "U"
			
			// Para nao 'estourar' o tamanho do campo, pois o usuario pode ficar insistindo em executar.
			if len (cvaltochar (zz6 -> zz6_QtTent + 1)) < TamSX3 ("ZZ6_QTTENT")[1]
				reclock ("ZZ6", .F.)
				zz6 -> zz6_QtTent ++
				msunlock ()
			else
				u_log2 ('erro', "Estourou o campo de quantidade de tentativas.")
			endif
		endif

		_lExecOK = .F.
		//u_log ("[" + procname () + "]", time (), "Executando seq.", zz6 -> zz6_seq, zz6 -> zz6_cmd)
		u_log2 ('info', "[" + procname () + "] Executando batch " + zz6 -> zz6_seq + ' ' + zz6 -> zz6_cmd)

		// Define nome para o arquivo de log a ser gravado pela rotina.
		if ! empty (zz6 -> zz6_cmd)
			private _sArqLog := _sNomeLog
		endif

		do case
		case ! empty (zz6 -> zz6_cmd)
			_sComando = alltrim (zz6 -> zz6_cmd)
			if right (_sComando, 1) != ")"
				U_help ("Comando incompleto no agendamento de batches: " + _sComando,, .t.)
				_oBatch:Retorno = 'C'
				_lExecOK = .F.
			else

				// Endereca monitor
				PtInternal (1, "Emp :"+cEmpAnt+"/"+cFIlAnt+" - " + _sComando)

				_lExecOK = (&_sComando)
				_lExecOk = iif (valtype (_lExecOk) != "L", .T., _lExecOk)
			endif
		otherwise
			u_help ("Execucao do processo batch tipo '" + zz6 -> zz6_CodPro + "' ainda nao implementada.",, .t.)
		endcase
		_sArqLog := _sArqLog2  // Restaura nome do arquivo de log corrente


		if _lExecOK  // O processo foi executado ateh o final
			reclock ("ZZ6", .F.)
			
			// A maioria dos processos retorna apenas .T. indicando que chegou ao final.
			if ! empty (_oBatch:Retorno)
				zz6 -> zz6_rodado = _oBatch:Retorno
			else
				zz6 -> zz6_rodado = "S"
			endif
			zz6 -> zz6_msg = alltrim (_oBatch:Mensagens)
			zz6 -> zz6_DFUExe = date ()
			zz6 -> zz6_HFUExe = time ()
			msunlock ()
		endif
	endif
	dbselectarea ("ZZ6")

	// Libera semaforo.
	if _nLock != 0
		U_Semaforo (_nLock)
	endif

	if ! empty (_oBatch:Mensagens)
		u_help (_oBatch:Mensagens)
	endif

return _lExecOK



// --------------------------------------------------------------------------
// Copia registro.
user function VA_ZZ6C ()
	local _oNova := ClsBatch ():New (zz6 -> (recno ()))
	_oNova:Seq = ""
	_oNova:Ativo = 'N'  // Quando copiado, inicializa como inativo.
	_oNova:Dados = 'COPIA DE ' + _oNova:Dados
	_oNova:Grava()
	zz6 -> (dbsetorder (1))  // ZZ6_FILIAL+ZZ6_SEQ
	u_help ("Gerado novo batch com sequencia '" + _oNova:Seq + "'.")
return



// --------------------------------------------------------------------------
// Chama visualizacao do arquivo de log, quando possivel.
user function VA_ZZ6VL ()
	local _sNomeArq := ''
	if empty (zz6 -> zz6_arqlog)
		u_help ("Nome do arquivo de log nao definido para esta rotina.",, .t.)
	else
		_sNomeArq = "s:\protheus12\protheus_data\logs\" + alltrim (zz6 -> zz6_arqlog)
		winexec ("cmd /c start " + _sNomeArq)
	endif
return


/*
// --------------------------------------------------------------------------
// Calcula quantidade de horas entre dois momentos.
static function _Horas (_sIni, _sFim)
	local _nRet   := 0
	local _nHrIni := val (substr (_sIni, 9, 2)) + val (substr (_sIni, 12, 2)) / 60 + val (substr (_sIni, 15, 2)) / 3600
	local _nHrFim := val (substr (_sFim, 9, 2)) + val (substr (_sFim, 12, 2)) / 60 + val (substr (_sFim, 15, 2)) / 3600
	local _nDias  := val (substr (_sFim, 1, 8)) - val (substr (_sIni, 1, 8))
	_nRet = _nHrFim - _nHrIni + _nDias * 24
return _nRet
*/


// --------------------------------------------------------------------------
// Grava arquivo com o modulo preferencial para usar na proxima execucao.
static function _Preferen (_nModulo)
	local _nHdl      := 0
	local _sArqModul := ""
	local _sModulo   := {'ATF', 'COM', '3', 'EST', 'FAT', 'FIN', '7', '8', '9', '10', '11', '12', '13'} [_nModulo]  // Os que tem numeros eu nao sei quais sao...

	_sArqModul = 'Modulo_preferencial_para_batches_empfil_' + cNumEmp + '.txt'

	u_log2 ('info', 'gerando arq. modulo preferencial ' + cvaltochar (_nModulo) + cvaltochar (_sModulo))
	if file (_sArqModul)
		_nHdl = fopen(_sArqModul, 1)
	else
		_nHdl = fcreate(_sArqModul, 0)
	endif
	fwrite (_nHdl, _sModulo)
	fclose (_nHdl)
return
