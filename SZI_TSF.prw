// Programa...: SZI_TSF
// Autor......: Robert Koch
// Data.......: 28/04/2015
// Cliente....: Nova Alianca
// Descricao..: Transferencia de saldo de conta corrente entre filiais.
//
// Historico de alteracoes:
// 23/10/2015 - Robert - Habilitado para todos os tipos de movimentos.
//                     - Verifica se o usuario tem acesso via tabela ZZU.
// 26/04/2016 - Robert - Nao permite mais transferir saldo de movto tipo 07 entre filiais.
// 22/06/2020 - Robert - Filtro por tipos de movimento.
//

// --------------------------------------------------------------------------
user Function SZI_TSF ()
	local _nLock      := 0
	local _lContinua  := .T.
	private cPerg     := "SZI_TSF"
	private aRotina   := {}
	u_logId ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
	endif

	// Somente uma estacao por vez, para evitar maiores transtornos.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_ValidPerg ()
		if pergunte (cPerg, .T.)
			processa ({|| _AndaLogo ()})
		endif
	
		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif
return



// --------------------------------------------------------------------------
// Geracao de movimento de transferencia.
static function _AndaLogo ()
//	local _lContinua := .T.
	local _oSQL      := NIL
	local _aLctos    := {}
	local _nLcto     := 0
	local _aCols     := {}
	local _sFilDest  := mv_par05  // As subrotinas mudam os parametros.

	u_logIni ()
	procregua (10)
	incproc ('Lendo dados...')

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ' ' as ok, R_E_C_N_O_, ZI_ASSOC, ZI_LOJASSO, ZI_NOMASSO, ZI_VALOR, ZI_SALDO, ZI_HISTOR"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL  = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_SALDO   > 0"
	_oSQL:_sQuery +=   " AND SZI.ZI_TM     != '07'"  // Adtos geram PA no financeiro. por enquanto nao tenho geracao automatica de PA noutra filial (que bco/ag/cta utilizaria?)
	if ! empty (mv_par06)
		_oSQL:_sQuery +=   " AND SZI.ZI_TM IN " + FormatIn (mv_par06, '/')
	endif
	_oSQL:_sQuery += " ORDER BY ZI_NOMASSO"
	u_log (_oSQL:_sQuery)
	_aLctos := aclone (_oSQL:Qry2Array ())

	// Cria browse para o usuario selecionar os titulos a transferir.
	for _nLcto = 1 to len (_aLctos)
		_aLctos [_nLcto, 1] = .F.
	next
	_aCols = {}
	aadd (_aCols, {3, 'Codigo',    40,  ''})
	aadd (_aCols, {4, 'Loja',      20,  ''})
	aadd (_aCols, {5, 'Nome',      100, ''})
	aadd (_aCols, {6, 'Valor',     60,  '@E 999,999,999.99'})
	aadd (_aCols, {7, 'Saldo',     60,  '@E 999,999,999.99'})
	aadd (_aCols, {8, 'Historico', 200, ''})
	U_MbArray (@_aLctos, 'Selecione titulos a transferir para a filial ' + _sFilDest, _aCols, 1)
//	u_log (_aLctos)
	
	procregua (len (_aLctos))
	for _nLcto = 1 to len (_aLctos)
		incproc ('Transferindo...')
		if _aLctos [_nLcto, 1]
			szi -> (dbgoto (_aLctos [_nLcto, 2]))
			U_SZIT (_sFilDest)
		endif
	next
	
	u_logFim ()
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM                  DEC VALID F3          Opcoes Help
	aadd (_aRegsPerg, {01, "Associado inicial             ", "C", 6,             0,            "",   "SA2 ", {},    "Codigo do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {02, "Loja associado inicial        ", "C", 2,             0,            "",   "    ", {},    "Loja do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {03, "Associado final               ", "C", 6,             0,            "",   "SA2 ", {},    "Codigo do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {04, "Loja associado final          ", "C", 2,             0,            "",   "    ", {},    "Loja do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {05, "Filial destino                ", "C", 2,             0,            "",   "SM0 ", {},    ""})
	aadd (_aRegsPerg, {06, "TMs Ex:01/02/13 (vazio=todos) ", "C", 30,            0,            "",   "ZX51", {},    ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
