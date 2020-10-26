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
//

// ----------------------------------------------------------------
user function BatLimp ()
	u_logIni ()
	u_logDH ()
	
	// Arquivos com sufixo _UNQ sao registros duplicados encontrados pela rotina CheckDupl e 'eliminados' pela mesma.
	// Limpar filial XX

	processa ({|| _Pack ()})
	processa ({|| _LimpaZZ6 ()})
	processa ({|| _LimpaZAB ()})
	u_logFim ()
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
		aadd (_aPack, {"SC8", "C8_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE1", "E1_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE2", "E2_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SE5", "E5_DATA    < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SD1", "D1_DTDIGIT < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SD2", "D2_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF1", "F1_DTDIGIT < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF2", "F2_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SF3", "F3_ENTRADA < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SFT", "FT_ENTRADA < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC1", "C1_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC7", "C7_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		// Totvs orienta (chamado 7124121 e https://tdn.totvs.com/pages/releaseview.action?pageId=6068533) a nunca executar pack nesta tabela -->  aadd (_aPack, {"CTK", "CTK_DATA   < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		// Totvs orienta (chamado 7124121 e https://tdn.totvs.com/pages/releaseview.action?pageId=6068533) a nunca executar pack nesta tabela -->  aadd (_aPack, {"CV3", "CV3_DTSEQ  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SD3", "D3_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC5", "C5_EMISSAO < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC6", "C6_ENTREG  < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"SC9", "C9_DATALIB < '" + dtos (date () - 365 * 1) + "'", '', 0, 0, 0, 0, ''})
		aadd (_aPack, {"ZAB", "ZAB_DTEMIS < '" + dtos (date () -  60 * 1) + "'"})
		aadd (_aPack, {"SC0", "C0_VALIDA  < '" + dtos (date () - 180 * 1) + "'", '', 0, 0, 0, 0, ''})

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
		_oSQL:_sQuery := "DELETE " + RetSQLName ('ZZ6') + " WHERE ZZ6_PERIOD != 'R' AND ZZ6_RODADO = 'S' AND ZZ6_DTINC <= '" + dtos (date () - 180) + "' AND ZZ6_DFUEXE <= '" + dtos (date () - 180) + "'"
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
