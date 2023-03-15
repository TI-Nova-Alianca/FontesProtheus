// Programa...: BatLimp
// Autor......: Robert Koch
// Data.......: 09/04/2015
// Descricao..: Limpeza de arquivos do Protheus.
//              Programa criado para ser executado em batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Elimina registros deletados ou obsoletos de algumas tabelas do Protheus.
// #PalavasChave      #pack #limpeza
// #TabelasPrincipais 
// #Modulos           #

// Historico de alteracoes:
// 27/05/2017 - Robert - Nao executa para DROP de tabelas vazias por que jah tivemos caso de procedure padrao referenciando essas tabelas.
// 11/11/2019 - Robert - Desabilitado pack tabelas CV3 e CTK cfe. GLPI 6772 e chamado Totvs 7124121.
// 24/10/2020 - Robert - Adicionada tabela SC0
//                     - Inseridas tags para catalogo de programas.
// 30/06/2021 - Robert - Limpeza do ZZ6 para nao-repetitivos reduzida de 180 para 90 dias.
// 29/11/2021 - Robert - Criada rotina de compactacao (no SQL) de algumas tabelas especificas.
// 20/07/2022 - Robert - Iniciada limpeza da tabela SZN (GLPI 12336)
// 22/07/2022 - Robert - Finalizada funcao de limpeza da tabela SZN (GLPI 12336)
// 05/08/2022 - Robert - Adicionada tabela SZN a lista para compactacao via SQL.
// 08/08/2022 - Robert - Adicionadas tabelas CV3 e CTK (GLPI 12412).
// 09/08/2022 - Robert - Adicionada tabela SBK para compactacao.
// 14/09/2022 - Robert - Adicionada tabela SC2 para compactacao.
// 10/10/2022 - Robert - Adicionada tabela SX3 para compactacao.
//                     - Envia aviso para TI quando vai compactar uma tabela.
// 13/10/2022 - Robert - Adicionadas tabelas SFT e CD2 para compactacao.
// 14/11/2022 - Robert - Adicionada tabela SCHDTSK.
// 30/01/2023 - Robert - Adicionadas tabelas SZE, SZF, ZX5, SDA, SDB para compactacao.
// 13/03/2023 - Robert - Adicionada tabela SZN para pack apos 365 dias.
//

// ----------------------------------------------------------------
user function BatLimp ()
	U_Log2 ('info', 'Iniciando ' + procname ())

	// Arquivos com sufixo _UNQ sao registros duplicados encontrados pela rotina CheckDupl e 'eliminados' pela mesma.
	// Limpar filial XX

	// A execucao de pack eu ateh vou fazer todas as tabelas numa unica rotina,
	// mas a 'limpeza' profiro uma funcao para cada tabela.
	processa ({|| _Pack ()})
	processa ({|| _LimpaZZ6 ()})
	processa ({|| _LimpaZAB ()})
	processa ({|| _Compact ()})
	processa ({|| _LimpaSZN ()})
	processa ({|| _LimpaWF3 ()})
	processa ({|| _SCHDTSK ()})
return



// --------------------------------------------------------------------------
static function _Pack ()
	local _oSQL    := NIL
	local _aPack   := {}
	local _nPack   := 0
	local _lContinua := .T.

	// Elimina registros deletados
	if _lContinua
		_aPack = {}
		aadd (_aPack, {"SC8", "C8_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE1", "E1_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE2", "E2_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE5", "E5_DATA     < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SD1", "D1_DTDIGIT  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SD2", "D2_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF1", "F1_DTDIGIT  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF2", "F2_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF3", "F3_ENTRADA  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SFT", "FT_ENTRADA  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC1", "C1_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC7", "C7_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		// CV3: Totvs orienta (chamado 7124121 e https://tdn.totvs.com/pages/releaseview.action?pageId=6068533) a nunca executar pack nesta tabela
		// CTK: Totvs orienta (chamado 7124121 e https://tdn.totvs.com/pages/releaseview.action?pageId=6068533) a nunca executar pack nesta tabela
		aadd (_aPack, {"SD3", "D3_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC5", "C5_EMISSAO  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC6", "C6_ENTREG   < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC9", "C9_DATALIB  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"ZAB", "ZAB_DTEMIS  < '" + dtos (date () -  60 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC0", "C0_VALIDA   < '" + dtos (date () - 180 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"WF3", "WF3_DATA    < '" + dtos (date () - 180 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SBK", "BK_DATA     < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SCHDTSK", "TSK_DIA < '" + dtos (date () - 30  * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SZN", "ZN_DATA     < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})

		procregua (len (_aPack))
	endif
	
	// Executa pack.
	if _lContinua
		for _nPack = 1 to len (_aPack)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "DELETE " + RetSQLName (_aPack [_nPack, 1]) + " WHERE D_E_L_E_T_ = '*' AND " + _aPack [_nPack, 2]
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				_oBatch:Mensagens += _oSQL:UltMsg
				_lContinua = .F.
				exit
			endif
		next
	endif
	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif

return



// --------------------------------------------------------------------------
// Limpa arquivo ZZ6 (batches)
static function _LimpaZZ6 ()
	local _oSQL    := NIL
	local _lContinua := .T.

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "DELETE " + RetSQLName ('ZZ6') + " WHERE ZZ6_PERIOD != 'R' AND ZZ6_RODADO = 'C' AND ZZ6_DTINC <= '" + dtos (date () - 180) + "'"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
	//	_oSQL:_sQuery := "DELETE " + RetSQLName ('ZZ6') + " WHERE ZZ6_PERIOD != 'R' AND ZZ6_RODADO = 'S' AND ZZ6_DTINC <= '" + dtos (date () - 180) + "' AND ZZ6_DFUEXE <= '" + dtos (date () - 180) + "'"
		_oSQL:_sQuery := "DELETE " + RetSQLName ('ZZ6') + " WHERE ZZ6_PERIOD != 'R' AND ZZ6_RODADO = 'S' AND ZZ6_DTINC <= '" + dtos (date () -  90) + "' AND ZZ6_DFUEXE <= '" + dtos (date () -  90) + "'"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return



// --------------------------------------------------------------------------
// Limpa arquivo ZAB (avisos)
static function _LimpaZAB ()
	local _oSQL    := NIL
	local _lContinua := .T.

	// Apaga avisos cuja validade jah expirou
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "DELETE " + RetSQLName ('ZAB') + " WHERE ZAB_TIPO != 'E' AND DATEADD (DAY, ZAB_VALID, CAST (ZAB_DTEMIS + ' ' + ZAB_HREMIS AS DATETIME)) < GETDATE ()"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return



// --------------------------------------------------------------------------
// Aplica compactacao do SQL em algumas tabelas do sistema, para as quais jah fiz um estudo
// e achei que vale a pena (ex: EXEC sp_estimate_data_compression_savings 'dbo', 'MPMENU_ITEM', 1, NULL, 'PAGE')
// A compactacao do SQL eh eliminada a cada vez que se roda um UPDDISTR ou se cria campos no configurador, etc.
static function _Compact ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _aArqComp  := {}
	local _nArqComp  := 0
	local _oAviso    := NIL

	aadd (_aArqComp, 'XAM010')  // Configuracao de campos (dados sensiveis) para LGPD
	aadd (_aArqComp, 'MPMENU_I18N')
	aadd (_aArqComp, 'MPMENU_ITEM')
	aadd (_aArqComp, 'SE2010')  // Verifiquei reducao de metade do tempo de execucao do extrato de conta corrente
	aadd (_aArqComp, 'SE5010')  // Verifiquei reducao de metade do tempo de execucao do extrato de conta corrente
	aadd (_aArqComp, 'SZI010')  // Verifiquei reducao de metade do tempo de execucao do extrato de conta corrente
	aadd (_aArqComp, 'SZN010')  // Estimativa (em 05/08/2022) de reducao de tamanho de 7GB para 2.5GB
	aadd (_aArqComp, 'CV3010')  // Criados campos grandes (IDORIG e IDDEST) e vazios - GLPI 12412
	aadd (_aArqComp, 'CTK010')  // Criados campos grandes (IDORIG e IDDEST) e vazios - GLPI 12412
	aadd (_aArqComp, 'SBK010')  // Uso pouco frequente, nao vejo problemas em compactar.
	aadd (_aArqComp, 'SC2010')  // Tem alguns campos de observacoes, etc que geralmente ficam vazios.
	aadd (_aArqComp, 'SX3010')  // Tabela bastante usada, quero ver se melhora performance.
	aadd (_aArqComp, 'SFT010')  // Teste inicial reduziu 70% do tamanho, e considero uma tabela que tem muito mais leituras do que gravacoes.
	aadd (_aArqComp, 'CD2010')  // Teste inicial reduziu 35% do tamanho, e considero uma tabela que tem muito mais leituras do que gravacoes.
	aadd (_aArqComp, 'SZE010')  // Apesar de nao ser grande, tem pouca movimentacao e muitos campos vazios.
	aadd (_aArqComp, 'SZF010')  // Apesar de nao ser grande, tem pouca movimentacao e muitos campos vazios.
	aadd (_aArqComp, 'ZX5010')  // Apesar de nao ser grande, tem pouca movimentacao e muitos campos vazios.
	aadd (_aArqComp, 'SDA010')  // Estimativa de reduzir 60% do tamanho. Tem muito poucas alteracoes e muitos campos vazios.
	aadd (_aArqComp, 'SDB010')  // Estimativa de reduzir 80% do tamanho. Tem muito poucas alteracoes e muitos campos vazios.

	for _nArqComp = 1 to len (_aArqComp)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select p.data_compression_desc"
		_oSQL:_sQuery +=  " from sys.partitions p"
		_oSQL:_sQuery += " where index_id = 1"
		_oSQL:_sQuery +=   " and p.object_id = (select object_id from sys.tables where name = '" + _aArqComp [_nArqComp] + "')"
		_oSQL:Log ()
		if alltrim (_oSQL:RetQry (1, .F.)) == 'NONE'  // Tabela nao encontra-se compactada
			_oSQL:_sQuery := "ALTER TABLE [dbo].[" + _aArqComp [_nArqComp] + "] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)"
			_oSQL:Log ()

			// Gera notificacao para monitoramento.
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'I'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Compactando tabela ' + _aArqComp [_nArqComp] + ' no SQL'
			_oAviso:Texto      = _oSQL:_sQuery
			_oAviso:Origem     = procname ()
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()

			if ! _oSQL:Exec ()
				_oBatch:Mensagens += _oSQL:UltMsg
				_lContinua = .F.
			endif
		endif
	next

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return



// --------------------------------------------------------------------------
// Limpa arquivo SZN (eventos)
static function _LimpaSZN ()
	local _oSQL    := NIL
	local _lContinua := .T.

	// Apaga eventos cuja validade jah expirou.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE " + RetSQLName ('SZN') + " SET D_E_L_E_T_ = '*' WHERE ZN_DIASVLD > 0 AND DATEADD (DAY, ZN_DIASVLD, CAST (ZN_DATA + ' ' + ZN_HORA AS DATETIME)) < GETDATE ()"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return



// --------------------------------------------------------------------------
// Limpa arquivo WF3 (rastreamento workflow)
static function _LimpaWF3 ()
	local _oSQL    := NIL
	local _lContinua := .T.

	// Apaga workflows de envio de e-mail generico (rotina customizada que usa
	// algumas facilidades do workflow para envio de e-mails, mas que nao precisa
	// manter rastreabilidade disso.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE " + RetSQLName ('WF3') + " SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND WF3_PROC   = 'SendMa'"  // Gerado pelo U_SendMail()
		_oSQL:_sQuery +=   " AND WF3_DATA  <= '" + dtos (date () - 180) + "'"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return


// --------------------------------------------------------------------------
// Limpa arquivo SCHDTSK (tarefas do schedule do Protheus)
static function _SCHDTSK ()
	local _oSQL    := NIL
	local _lContinua := .T.

	// Tarefas jah executadas ha tempos nao vejo necessidade de guardar.
	// TSK_STATUS: 0=Aguardando execucao;1=Executando;2=Finalizada;3=Falhou;4=Permanente;5=Descartada
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "UPDATE SCHDTSK SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery +=                  ", R_E_C_D_E_L_ = R_E_C_N_O_"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND TSK_DIA    < '" + dtos (date () - 15) + "'"
		_oSQL:_sQuery +=   " AND TSK_STATUS IN ('2', '3', '5')"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			_oBatch:Mensagens += _oSQL:UltMsg
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return
