// Programa:  ReplSafr
// Autor:     Robert Koch
// Data:      07/01/2013
// Descricao: Replica cadastros de uma safra para outra, pois muitas informacoes permanecem
//            iguais em todas as safras.
//
// Historico de alteracoes:
// 26/01/2014 - Robert - Replica patriarca mesmo que jah existam (outros, claro...) patriarcas na safra destino.
// 08/01/2015 - Robert - Replica tabela 17 do ZX5.
// 26/01/2016 - Robert - Rotina restrita ao grupo 045 do ZZU.
// 03/11/2017 - Robert - Nao replica mais o SZ7 para associados inativos.
// 14/11/2018 - Robert - Desabilitada replicacao do SZ7 e SZ8.
//                     - Replicacao das tabelas 13 e 14 do ZX5.
// 20/11/2019 - Robert - Ajustes para safra 2020 (novos campos tabela 17 do ZX5)
// 03/01/2020 - Robert - Campo ZX5_17COND vai ser excluido (a tabela 17 serve somente para espaldeira, entao nao ha motivo para manter o campo).
//

// --------------------------------------------------------------------------
User Function ReplSafr ()
	Local cCadastro  := "Replicacao de cadastros para nova safra"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	local _nLock     := 0
	local _lContinua := .T.
	private _lSelCol := .F.  // Para controlar se jah chamou as opcoes.
	private _aOpcoes := {}   // Opcoes (colunas) selecionadas pelo usuario.
	Private cPerg    := "REPLSAFR"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	_ValidPerg ()

	// Controle de semaforo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt)
		if _nLock == 0
			msgalert ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		u_logId ()
		_sOpcoes = mv_par03
		
		AADD(aSays,"Este programa tem como objetivo replicar cadastros usados pelas rotinas")
		AADD(aSays,"de safra de um ano para outro.")
		AADD(aSays,"")
		
		AADD(aButtons, { 1,.T.,{|| nOpca := If(_TudoOk(), 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 11,.T.,{|| _Opcoes ()}})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa ({|lEnd| _AndaLogo ()})
		Endif

		// Libera semaforo
		U_Semaforo (_nLock)
	endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
	// Local _aArea    := GetArea()
	Local _lRet     := .T.
	if ! _lSelCol
		_Opcoes ()
	endif
	// RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
// Seleciona opcoes especificas do relatorio.
Static Function _Opcoes ()
	local _aCols     := {}
	local _nOpcao    := 0

	// Monta array de opcoes.
	_aOpcoes = {}
	aadd (_aOpcoes, {.F., "Tabela de nao conformidades uvas",    "ZX5_11"})
	aadd (_aOpcoes, {.F., "Grupos de uvas p/tabela precos",      "ZX5_13"})
	aadd (_aOpcoes, {.F., "Faixas calculo grau uvas viniferas",  "ZX5_17"})

	// Pre-seleciona opcoes cfe. conteudo anterior
	for _nOpcao = 1 to len (_aOpcoes)
		_aOpcoes [_nOpcao, 1] = (substr (_sOpcoes, _nOpcao, 1) ==  "S")
	next

	// Browse para usuario selecionar as opcoes
	_aCols = {}
	aadd (_aCols, {2, "Cadastro",  280,  ""})
	U_MBArray (@_aOpcoes, "Selecione os cadastros a replicar", _aCols, 1, 700, 450, , ".T.")

	// Indica que as opcoes jah foram selecionadas ou, pelo menos, visualizadas.
	_lSelCol = .T.
Return



// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _lContinua := .T.
	local _nOpcao    := 0
	for _nOpcao = 1 to len (_aOpcoes)
		if _aOpcoes [_nOpcao, 1]
			do case
				case _aOpcoes [_nOpcao, 3] == "ZX5_11"
					u_help ("Rotina ainda nao desenvolvida. Use rotina de 'tabelas especificas' (tabela 11)")
				case _aOpcoes [_nOpcao, 3] == "ZX5_13"
					processa ({|| _ReplZX513 ()})
				case _aOpcoes [_nOpcao, 3] == "ZX5_17"
					processa ({|| _ReplZX517 ()})
				otherwise
					u_help ("Opcao sem tratamento: '" + _aOpcoes [_nOpcao, 3] + "'.")
			endcase
		endif
	next
return _lContinua



// --------------------------------------------------------------------------
static function _ReplZX513 ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nCopiado  := 0
	local _aDados    := {}
	local _lContinua := .T.
	private cPerg    := "REPLSAFR"

	if ! msgyesno ("Esta rotina permite copiar varios registros de determinada safra para uma nova safra (grupos de uvas para tabela de preco). Deseja continuar?")
		_lContinua = .F.
	endif

	if _lContinua .and. ! pergunte (cPerg, .T.)
		_lContinua = .F.
	endif
	
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5 "
		_oSQL:_sQuery +=  " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ((ZX5.ZX5_TABELA  = '13' AND ZX5.ZX5_13SAFR  = '" + mv_par02 + "')"
		_oSQL:_sQuery +=     " OR  (ZX5.ZX5_TABELA  = '14' AND ZX5.ZX5_14SAFR  = '" + mv_par02 + "'))"
		if _oSQL:RetQry () > 0
			if U_MsgNoYes ("Ja existe cadastro desta tabela para a safra '" + mv_par02 + "'. Deseja sobrepor?")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSqlName ("ZX5")
				_oSQL:_sQuery +=    " SET D_E_L_E_T_ = '*'"
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
				_oSQL:_sQuery +=    " AND ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
				_oSQL:_sQuery +=    " AND ((ZX5_TABELA  = '13' AND ZX5_13SAFR  = '" + mv_par02 + "')"
				_oSQL:_sQuery +=     " OR  (ZX5_TABELA  = '14' AND ZX5_14SAFR  = '" + mv_par02 + "'))"
				if ! _oSQL:Exec ()
					u_help ("Erro na exclusao dos dados anteriores.")
					_lContinua = .F.
				endif
			else
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		CursorWait ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZX5_13.ZX5_13GRUP, ZX5_13.ZX5_13DESC, ISNULL (ZX5_14.ZX5_14SAFR, '') ZX5_14SAFR,"
		_oSQL:_sQuery +=        " ISNULL (ZX5_14.ZX5_14PROD, '') ZX5_14PROD, ISNULL (ZX5_14.ZX5_14GRUP, '') ZX5_14GRUP,"
		_oSQL:_sQuery +=        " ISNULL (ZX5_14.ZX5_14GRMO, '') ZX5_14GRMO, ISNULL (ZX5_14.ZX5_14EXPL, '') ZX5_14EXPL, ISNULL (SB1.B1_DESC, '') B1_DESC"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_13 "
		_oSQL:_sQuery +=   " LEFT JOIN " + RetSqlName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery +=        " JOIN " + RetSqlName ("SB1") + " SB1 "
		_oSQL:_sQuery +=               " ON (SB1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=               " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=               " AND SB1.B1_COD = ZX5_14.ZX5_14PROD)"
		_oSQL:_sQuery +=          " ON (ZX5_14.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_FILIAL = ZX5_13.ZX5_FILIAL"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
		_oSQL:_sQuery +=          " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP)"
		_oSQL:_sQuery +=  " WHERE ZX5_13.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_TABELA  = '13'"
		_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13SAFR  = '" + mv_par01 + "'"
		_oSQL:_sQuery +=  " ORDER BY ZX5_13.ZX5_13GRUP, SB1.B1_DESC"
		u_log (_oSQL:_sQuery)
		_sAliasQ := _oSQL:Qry2Trb ()
		do while ! (_sAliasQ) -> (eof ())
			_sGrupo = (_sAliasQ) -> zx5_13grup
			u_log ((_sAliasQ) -> zx5_13grup, (_sAliasQ) -> zx5_13desc, (_sAliasQ) -> zx5_14GRUP, (_sAliasQ) -> zx5_14prod, (_sAliasQ) -> b1_desc)
			
			// Insere o grupo, se ainda nao existir.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_13 "
			_oSQL:_sQuery +=  " WHERE ZX5_13.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_TABELA  = '13'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13SAFR  = '" + mv_par02 + "'"
			_oSQL:_sQuery +=    " AND ZX5_13.ZX5_13GRUP  = '" + (_sAliasQ) -> zx5_13grup + "'"
			//u_log (_oSQL:_sQuery)
			if _oSQL:RetQry () == 0
				u_log ('inserindo grupo na tabela 13')
				_aDados = {}
				aadd (_aDados, {'ZX5_13SAFR', mv_par02})
				aadd (_aDados, {'ZX5_13GRUP', (_sAliasQ) -> zx5_13grup})
				aadd (_aDados, {'ZX5_13DESC', (_sAliasQ) -> zx5_13desc})
				//u_log (_aDados)
				_oTab := ClsTabGen ():New ('13')
				if ! _oTab:Insere (_aDados)
					u_help (_oTab:UltMsg)
					return
				endif
			else
				u_log ('Grupo ja existe')
			endif
	
			// Insere os itens do grupo
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zx5_13grup == _sGrupo
				u_log ((_sAliasQ) -> zx5_13grup, (_sAliasQ) -> zx5_13desc, (_sAliasQ) -> zx5_14GRUP, (_sAliasQ) -> zx5_14prod, (_sAliasQ) -> b1_desc)
				
				// Pode haver grupo (sinteticas, por exemplo) sem item relacionado.
				if ! empty ((_sAliasQ) -> zx5_14prod) .and. ! empty ((_sAliasQ) -> zx5_14grup)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5_14 "
					_oSQL:_sQuery +=  " WHERE ZX5_14.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_TABELA  = '14'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14SAFR  = '" + mv_par02 + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14GRUP  = '" + (_sAliasQ) -> zx5_14grup + "'"
					_oSQL:_sQuery +=    " AND ZX5_14.ZX5_14PROD  = '" + (_sAliasQ) -> zx5_14prod + "'"
					//u_log (_oSQL:_sQuery)
					if _oSQL:RetQry () == 0
						u_log ('inserindo produto na tabela 14')
						_aDados = {}
						aadd (_aDados, {'ZX5_14SAFR', mv_par02})
						aadd (_aDados, {'ZX5_14GRUP', (_sAliasQ) -> zx5_14grup})
						aadd (_aDados, {'ZX5_14PROD', (_sAliasQ) -> zx5_14prod})
						//u_log (_aDados)
						_oTab := ClsTabGen ():New ('14')
						if ! _oTab:Insere (_aDados)
							u_help (_oTab:UltMsg)
							return
						endif
					else
						u_log ('Item ja existe')
					endif
				endif
				(_sAliasQ) -> (dbskip ())
				_nCopiado ++
			enddo
		enddo
	
		CursorArrow ()
		msginfo ("Processo concluido. " + cvaltochar (_nCopiado) + " registro(s) copiado(s).")
		dbselectarea ("SB1")
	endif
return




// --------------------------------------------------------------------------
static function _ReplZX517 ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nCopiado  := 0
	local _sChave    := ""
	local _lContinua := .T.
	private cPerg    := "REPLSAFR"
	
	if ! msgyesno ("Esta rotina permite copiar varios registros de determinada safra para uma nova safra (faixas de grau para determinar classificacao de uvas viniferas). Registros ja existentes nao serao copiados. Deseja continuar?")
		_lContinua = .F.
	endif

	if _lContinua .and. ! pergunte (cPerg, .T.)
		_lContinua = .F.
	endif
	
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5 "
		_oSQL:_sQuery +=  " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_TABELA  = '17'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_17SAFR  = '" + mv_par02 + "'"
		if _oSQL:RetQry () > 0
			if U_MsgNoYes ("Ja existe cadastro desta tabela para a safra '" + mv_par02 + "'. Deseja sobrepor?")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE " + RetSqlName ("ZX5")
				_oSQL:_sQuery +=    " SET D_E_L_E_T_  = '*'"
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
				_oSQL:_sQuery +=    " AND ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
				_oSQL:_sQuery +=    " AND ZX5_TABELA  = '17'"
				_oSQL:_sQuery +=    " AND ZX5_17SAFR  = '" + mv_par02 + "'"
				if ! _oSQL:Exec ()
					u_help ("Erro na exclusao dos dados anteriores.")
					_lContinua = .F.
				endif
			else
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		CursorWait ()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZX5_17PROD, ZX5_17COND, ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID, ZX5_17GIDS, ZX5_17GIES, ZX5_17GFES," // ZX5_17LSAN, ZX5_17LMAT, ZX5_17LEST"
		_oSQL:_sQuery +=        " max (ZX5_CHAVE) over () as MaxChv"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZX5") + " ZX5 "
		_oSQL:_sQuery +=  " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_FILIAL  = '" + xFilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_TABELA  = '17'"
		_oSQL:_sQuery +=    " AND ZX5.ZX5_17SAFR  = '" + mv_par01 + "'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=              " FROM " + RetSqlName ("ZX5") + " NOVA "
		_oSQL:_sQuery +=             " WHERE NOVA.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=               " AND NOVA.ZX5_FILIAL  = ZX5.ZX5_FILIAL"
		_oSQL:_sQuery +=               " AND NOVA.ZX5_17SAFR  = '" + mv_par02 + "'"
		_oSQL:_sQuery +=               " AND NOVA.ZX5_17PROD  = ZX5.ZX5_17PROD)"
		_oSQL:_sQuery +=  " ORDER BY ZX5_17PROD"
		u_log (_oSQL:_sQuery)
		_sAliasQ := _oSQL:Qry2Trb ()
		_sChave = (_sAliasQ) -> MaxChv
		do while ! (_sAliasQ) -> (eof ())
			_sChave = soma1 (_sChave)
			reclock ("ZX5", .T.)
			zx5 -> zx5_filial = xfilial ("ZX5")
			zx5 -> zx5_tabela = '17'
			zx5 -> zx5_CHAVE  = _sChave
			zx5 -> zx5_17safr = mv_par02
			zx5 -> zx5_17prod = (_sAliasQ) -> zx5_17prod
			//zx5 -> zx5_17COND = (_sAliasQ) -> zx5_17cond
			zx5 -> zx5_17GIPR = (_sAliasQ) -> zx5_17gipr
			zx5 -> zx5_17GIAA = (_sAliasQ) -> zx5_17giaa
			zx5 -> zx5_17GIA  = (_sAliasQ) -> zx5_17gia
			zx5 -> zx5_17GIB  = (_sAliasQ) -> zx5_17gib
			zx5 -> zx5_17GIC  = (_sAliasQ) -> zx5_17gic
			zx5 -> zx5_17GID  = (_sAliasQ) -> zx5_17gid
//			zx5 -> zx5_17GIDS = (_sAliasQ) -> zx5_17gids
			zx5 -> zx5_17GIEs = (_sAliasQ) -> zx5_17gies
			zx5 -> zx5_17GFEs = (_sAliasQ) -> zx5_17gfes
//			zx5 -> zx5_17LSan = (_sAliasQ) -> zx5_17LSan
//			zx5 -> zx5_17LMat = (_sAliasQ) -> zx5_17LMat
//			zx5 -> zx5_17LEst = (_sAliasQ) -> zx5_17LEst
			msunlock ()
			_nCopiado ++
			(_sAliasQ) -> (dbskip ())
		enddo
		CursorArrow ()
		msginfo ("Processo concluido. " + cvaltochar (_nCopiado) + " registro(s) copiado(s).")
		dbselectarea ("SB1")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	// Cria diferentes grupos de perguntas para diferentes rotinas.
	cPerg = "REPLSAFR"
	_aRegsPerg = {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Safra origem                  ", "C", 4,  0,  "",   "   ", {},    "Safra (ano) da qual os cadastros serao copiados."})
	aadd (_aRegsPerg, {02, "Safra nova                    ", "C", 4,  0,  "",   "   ", {},    "Safra (ano) para a qual serao replicados os cadastros."})
	U_ValPerg (cPerg, _aRegsPerg)

	cPerg = "REPLSAFR1"
	_aRegsPerg = {}
	aadd (_aRegsPerg, {01, "Safra de origem               ", "C", 4,  0,  "",   "   ", {},                  ""})
	aadd (_aRegsPerg, {02, "Tabela de precos de origem    ", "C", 6,  0,  "",   "SZA", {},                  ""})
	aadd (_aRegsPerg, {03, "Tipo associado (bco=todos)    ", "C", 1,  0,  "",   "   ", {},                  ""})
	aadd (_aRegsPerg, {04, "Nova safra                    ", "C", 4,  0,  "",   "   ", {},                  ""})
	aadd (_aRegsPerg, {05, "Nova tabela de precos         ", "C", 6,  0,  "existcpo('SZA')", "SZA", {},                  ""})
	U_ValPerg (cPerg, _aRegsPerg)
return