// Programa...: SZI_TCC
// Autor......: Robert Koch
// Data.......: 04/01/2012
// Descricao..: Transferencia de saldo de quota capital entre associados.
//
// Historico de alteracoes:
// 14/02/2012 - Robert - Deixava os movimentos com saldo.
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 03/01/2016 - Robert - Metodo AtuSaldo() da conta corrente nao recebe mais o saldo como parametro.
// 21/01/2020 - Robert - Melhoria mensagens e regua de processamento.
//

// --------------------------------------------------------------------------
user Function SZI_TCC ()
	local _aIndBrw    := {}  // Para filtragem no browse
	local _bFilBrw    := {|| Nil}  // Para filtragem no browse
	local _cCondicao  := ""  // Para filtragem no browse
	local _nLock      := 0

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Somente uma estacao por vez, por causa da geracao de documentos sequenciais.
	// Ok, ok, eu sei que o certo teria sido usar GetSXeNum()...
	_nLock := U_Semaforo (procname (), .F.)
	if _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
		return
	endif

	private cPerg     := "SZI_TCC"
	private aRotina   := {}
//	private _sarqlog  := U_NomeLog ()
	u_logId ()

	_ValidPerg ()

	aadd (aRotina, {"&Pesquisar" , "AxPesqui",   0, 1})
	aadd (aRotina, {"&Visualizar", "AxVisual",   0, 1})
	aadd (aRotina, {"&Transferir", "U_SZI_TCCT", 0, 3})
	aadd (aRotina, {"&Excluir"   , "U_SZI_TCCE", 0, 5})

	private cString   := "SZI"
	private cCadastro := "Transferencia de saldo de quota capital entre associados"

	// Filtra browse.
	_cCondicao := 'szi->zi_tm$"17/18"'
	_bFilBrw := {|| FilBrowse(cString,@_aIndBrw,@_cCondicao) }
	Eval(_bFilBrw)
	DbSelectArea(cString)
	mBrowse(,,,,cString,,,,,2)
	EndFilBrw(cString,_aIndBrw)
	DbSelectArea(cString)
	DbSetOrder(1)	// Reaplica filtro no mbrowse.
	Eval(_bFilBrw)
	DbClearFilter()

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return



// --------------------------------------------------------------------------
// Inclusao de movimento de transferencia.
User Function SZI_TCCT ()
	processa ({|| _GeraT ()})
return



// --------------------------------------------------------------------------
static function _GeraT ()
	local _oAssocOr  := NIL
	local _oAssocDs  := NIL
	local _oCCorrOr  := NIL
	local _oCCorrDs  := NIL
	local _lContinua := .T.

	u_logIni ()

	_lContinua = Pergunte (cPerg, .T.)
	
	// Instancia e verifica associados.
	if _lContinua
		_oAssocOr := ClsAssoc():New (mv_par01, mv_par02)
		_oAssocDs := ClsAssoc():New (mv_par03, mv_par04)
		if valtype (_oAssocOr) != 'O' .or. valtype (_oAssocDs) != 'O'
			_lContinua = .F.
		endif
	endif

	// Gera documento sequencial para facilitar a amarracao entre os registros.
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT MAX (SUBSTRING (ZI_DOC, 4, 3))"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZI_TM      IN ('17','18')"
		_oSQL:_sQUery +=   " AND ZI_DOC     LIKE 'TCC%'"
		u_log (_oSQL:_squery)
		_sDoc = _oSQL:RetQry ()
		if empty (_sDoc)
			_sDoc = '000'
		endif
		_sDoc = 'TCC' + soma1 (_sDoc)
	endif

	// Instancia e verifica movimentos.
	if _lContinua
		// Prepara lancamento de saida
		_oCCorrOr := ClsCtaCorr():New ()
		_oCCorrOr:Assoc    = _oAssocOr:Codigo
		_oCCorrOr:Loja     = _oAssocOr:Loja
		_oCCorrOr:DtMovto  = dDataBase
		_oCCorrOr:TM       = '17'
		_oCCorrOr:Histor   = 'TR.SALDO QUOTA CAP.PARA ' + _oAssocDs:Codigo + '/' + _oAssocDs:Loja + ' ' + _oAssocDs:Nome
		_oCCorrOr:MesRef   = strzero(month(_oCCorrOr:DtMovto),2)+strzero(year(_oCCorrOr:DtMovto),4)
		_oCCorrOr:Doc      = _sDoc  //GravaData (_oCCorrOr:DtMovto, .f., 1)
		_oCCorrOr:Valor    = mv_par05
//		u_log ('Atributos:', ClassDataArr (_oCCorrOr))

		// Prepara lancamento de entrada
		_oCCorrDs := ClsCtaCorr():New ()
		_oCCorrDs:Assoc    = _oAssocDs:Codigo
		_oCCorrDs:Loja     = _oAssocDs:Loja
		_oCCorrDs:DtMovto  = dDataBase
		_oCCorrDs:TM       = '18'
		_oCCorrDs:Histor   = 'TR.SALDO QUOTA CAP.DE ' + _oAssocOr:Codigo + '/' + _oAssocOr:Loja + ' ' + _oAssocOr:Nome
		_oCCorrDs:MesRef   = strzero(month(_oCCorrDs:DtMovto),2)+strzero(year(_oCCorrDs:DtMovto),4)
		_oCCorrDs:Doc      = _sDoc  //GravaData (_oCCorrDs:DtMovto, .f., 1)
		_oCCorrDs:Valor    = mv_par05
//		u_log ('Atributos:', ClassDataArr (_oCCorrDs))
	endif

	if _lContinua
		if ! _oCCorrOr:PodeIncl ()
			_lContinua = .F.
			u_help ("Nao foi possivel fazer a movimentacao do associado " + _oAssocOr:Codigo,, .t.)
		endif
	endif
	if _lContinua
		if ! _oCCorrDs:PodeIncl ()
			_lContinua = .F.
			u_help ("Nao foi possivel fazer a movimentacao do associado " + _oAssocDs:Codigo,, .t.)
		endif
	endif

	if _lContinua
		if _oCCorrOr:Grava (.F., .F.)	
			_lContinua = _oCCorrOr:AtuSaldo ()
		else
			u_help ("Nao foi possivel fazer a movimentacao do associado " + _oAssocOr:Codigo,, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		if _oCCorrDs:Grava (.F., .F.)	
			_lContinua = _oCCorrDs:AtuSaldo ()
		else
			u_help ("Nao foi possivel fazer a movimentacao do associado " + _oAssocDs:Codigo,, .t.)
			_lContinua = .F.
			
			// Se nao gravou o lancamento de destino, exclui tambem o de origem.
			if ! _oCCorrOr:Exclui ()
				u_help ("ATENCAO: Nao foi possivel estornar a saida de valor do associado " + _oAssocOr:Codigo + ". Verifique sua conta corrente!",, .t.)
				_lContinua = .F.
			endif
		endif
	endif
	if _lContinua
		u_help ("Processo concluido.")
	endif
		
	u_logFim ()
return



// --------------------------------------------------------------------------
// Exclusao de movimento de transferencia.
User Function SZI_TCCE ()
	processa ({|| _DelT ()})
return



// --------------------------------------------------------------------------
static function _DelT ()
	local _oCCorrOr  := NIL
	local _lContinua := .T.

	u_help ("LEMBRETE: A exclusao deste tipo de movimento deve ser feita tanto para o associado de origem como para o associado de destino!")
	u_logIni ()
	_oCCorrOr := ClsCtaCorr():New (szi -> (recno ()))
	u_log ('Atributos:', ClassDataArr (_oCCorrOr))
	if ! _oCCorrOr:PodeExcl ()
		_lContinua = .F.
		u_help ("Exclusao nao permitida.",, .t.)
	else
		if ! _oCCorrOr:Exclui ()
			u_help ("Erro durante a exclusao do movimento.",, .t.)
			_lContinua = .f.
		endif
	endif
	if _lContinua
		u_help ("Processo concluido.")
	endif
		
	u_logFim ()
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM                  DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Associado origem              ", "C", 6,                   0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {02, "Loja associado origem         ", "C", 2,                   0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {03, "Associado destino             ", "C", 6,                   0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {04, "Loja associado destino        ", "C", 2,                   0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {05, "Valor a transferir            ", "N", 18,                  2,  "",   "      ", {},                                  ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
