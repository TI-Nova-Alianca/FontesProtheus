// Programa:  _MATA300
// Autor:     Robert Koch
// Data:      08/02/2023
// Descricao: Recalculo saldo atual

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Executa a rotina de recalculo de saldo atual de forma automatizada.
// #PalavasChave      #recalculo #saldo #atual #refaz
// #TabelasPrincipais #SB2 #SB8 #SBF
// #Modulos           #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function _MATA300 (_sProdIni, _sProdFim, _sAlmIni, _sAlmFim)
	local _oSQL     := NIL
	local _sUltExec := ''
	local _lRet300  := .T.
	local _aAreaAnt := U_ML_SRArea ()

	// Guarda ultimo log deste processo para posteriormente verificar se gerou novo log.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT MAX (CV8_DATA + CV8_HORA)"
	_oSQL:_sQuery += " FROM " + RetSQLName ("CV8")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CV8_FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery += " AND CV8_PROC = 'MATA300'"
	//_oSQL:Log ()
	_sUltExec = _oSQL:RetQry (1, .F.)

	// Atualiza perguntas da rotina e executa 'refaz saldo atual'.
	_sPerg := "MTA300"
	SetMVValue (_sPerg, "MV_PAR01", _sAlmIni)   // Alm. inicial
	SetMVValue (_sPerg, "MV_PAR02", _sAlmFim)   // Alm. final
	SetMVValue (_sPerg, "MV_PAR03", _sProdIni)  // Produto inicial
	SetMVValue (_sPerg, "MV_PAR04", _sProdFim)  // Produto final
	SetMVValue (_sPerg, "MV_PAR05", 1)       // Zera saldo dos produtos MOD = Sim
	SetMVValue (_sPerg, "MV_PAR06", 1)       // Zera CM dos produtos MOD = Sim
	SetMVValue (_sPerg, "MV_PAR07", 2)       // Trava registros do SB2 = Nao
	SetMVValue (_sPerg, "MV_PAR08", 2)       // Seleciona filiais = Nao
	U_Log2 ('info', "Executando MATA300 (refaz saldo atual)")
	MATA300 (.T.)

	// Verifica se rodou com sucesso.
	_oSQL:_sQuery := "SELECT CV8_DATA + ' ' + CV8_HORA + ' ' + rtrim (CV8_MSG)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV8")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CV8_FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery +=   " AND CV8_PROC   = 'MATA300'"
	_oSQL:_sQuery +=   " AND CV8_INFO   = '2'"
	_oSQL:_sQuery +=   " AND CV8_DATA + CV8_HORA > '" + _sUltExec + "'"
	_oSQL:_sQuery +=   " AND UPPER (CV8_USER) = '" + alltrim (upper (cUserName)) + "'"
	//_oSQL:Log ()
	_sUltExec = _oSQL:RetQry (1, .F.)
	if empty (_sUltExec)
		_lRet300 = .F.
		U_help ('Erro na execucao automatica do programa MATA300',, .t.)
	else
		U_Log2 ('info', '[' + procname () + ']' + _sUltExec)
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet300
