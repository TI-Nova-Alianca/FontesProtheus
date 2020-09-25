// Programa...: LibOpPr
// Autor......: Robert Koch
// Data.......: 04/11/2015
// Descricao..: Tela de liberacao de OP para producao.
//
// Historico de alteracoes:
// 31/08/2018 - Robert - Quebra qt solicitdas ao FullWMS pela qt.embalagem (B1_QB).
// 02/10/2018 - Robert - Busca lote (quant) a solicitar no A5_VAQSOLW e solicita ao FullWMS em multiplos desse lote.
//

#XTranslate .SolicProduto      => 1
#XTranslate .SolicDescricao    => 2
#XTranslate .SolicAlmox        => 3
#XTranslate .SolicLote         => 4
#XTranslate .SolicQtOriginal   => 5
#XTranslate .SolicSaldoEstoque => 6
#XTranslate .SolicEmpenhos     => 7
#XTranslate .SolicQtSolicitada => 8
#XTranslate .SolicObs          => 9
#XTranslate .SolicQtColunas    => 9

// --------------------------------------------------------------------------
User Function LibOpPr (_sOPIni, _sOPFim)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _aCores     := U_LibOpPrL (.T.)
	private cString   := "SC2"
	private cCadastro := "Liberar OP para producao"
	private aRotina   := {}
	private cPerg     := "LIBOPPR"

	u_logIni ()

	// Monta interface conforme os parametros recebidos.
	do case
	case _sOPIni == NIL .or. _sOPFim == NIL
		aadd (aRotina, {"&Pesquisar",        "AxPesqui", 0,1})
		aadd (aRotina, {"&Visualizar",       "AxVisual", 0,2})
//		aadd (aRotina, {"Libera &esta OP",   "U_LibOpPr (sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd, sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd, .T.)", 0,2})
		aadd (aRotina, {"Libera &esta OP",   "processa ({||U_LibOpPr (sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd, sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd)})", 0,2})
		aadd (aRotina, {"Libera va&rias OP", "U_LibOpPr ('', '')", 0,2})
		aadd (aRotina, {"&Administrar OP",   "U_AdmOP (sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd, .F.)", 0,2})
		aadd (aRotina, {"&Legenda",          "U_LibOpPrL (.F.)", 0,2})
		DbSelectArea(cString)
		mBrowse(,,,,cString,,,,,2, _aCores)
		DbSelectArea(cString)
		DbSetOrder(1)	// Reaplica filtro no mbrowse.

	// Se nao recebeu parametros de numero de OP, abre tela para o usuario selecionar.
	case empty (_sOPIni) .and. empty (_sOPFim)
		_ValidPerg (cPerg)
		if pergunte (cPerg, .T.)
			processa ({|| _Tela ()})
		endif

	case _sOPIni == _sOPFim
		sc2 -> (dbsetorder (1))  // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD
		if ! sc2 -> (dbseek (xfilial ("SC2") + _sOPIni, .F.))
			u_help ("OP '" + _sOPIni + "' nao encontrada!")
		else
			if ! empty (sc2 -> c2_datrf)
				u_help ("OP '" + _sOPIni + "' ja encontra-se encerrada.")
			else
				if sc2 -> c2_valibpr != 'S' .or. U_MsgYesNo ("OP '" + _sOPIni + "' ja encontra-se liberada para producao. Deseja verificar se falta gerar rancho para o almoxarifado?", .T.)

					// Varre empenhos da OP e gera solicitacao ao almoxarifado, quando necessario.
					if _GeraZAG (sc2 -> C2_NUM + sc2 -> C2_ITEM + sc2 -> C2_SEQUEN + sc2 -> C2_ITEMGRD)
						reclock ("SC2", .F.)
						sc2 -> c2_vaLibPr = 'S'
						msunlock ()
					else
						u_help ("Nao foi possivel solicitar as transferencias de estoque necessarias a esta OP. Verifique!")
					endif
				endif
			endif
		endif
	otherwise
		u_help ("Funcao " + procname () + " recebeu parametros invalidos.")
	endcase

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function LibOpPrL (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i	   := 0
	
	aadd (_aCores, {"! empty (sc2 -> c2_datrf)", 'BR_VERMELHO',                             'Encerrada'})
	aadd (_aCores, {"  empty (sc2 -> c2_datrf) .and. sc2 -> c2_valibpr != 'S'", 'BR_VERDE',   'Em aberto (nao liberada para producao)'})
	aadd (_aCores, {"  empty (sc2 -> c2_datrf) .and. sc2 -> c2_valibpr == 'S'", 'BR_AMARELO', 'Em aberto (liberada para producao)'})
	
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
static function _Tela ()
	local _aOP    := {}
	local _nOP    := 0
	local _aCols    := {}
	local _oSQL := ClsSQL ():New ()

	procregua (10)

	// Busca OPs candidatas a serem liberadas.
	incproc ('Buscando OPs para liberar')
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ' ' as OK,"
	_oSQL:_sQuery +=       " C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD,"
	_oSQL:_sQuery +=       " SB1.B1_DESC, "
	_oSQL:_sQuery +=       " dbo.VA_DTOC (C2_DATPRF),"
	_oSQL:_sQuery +=       " C2_QUANT - C2_QUJE,"
	_oSQL:_sQuery +=       " B1_UM, "
	_oSQL:_sQuery +=         _oSQL:CaseX3CBox ("C2_VAOPESP") + ", "
	_oSQL:_sQuery +=       " C2_OBS"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC2") + " SC2, "
	_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE SC2.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SC2.C2_FILIAL   = '" + xfilial ("SC2") + "'"
	_oSQL:_sQuery +=   " AND SC2.C2_DATRF    = ''"
	_oSQL:_sQuery +=   " AND SC2.C2_VALIBPR != 'S'"
	_oSQL:_sQuery +=   " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD      = SC2.C2_PRODUTO"
	_oSQL:_sQuery += " ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN, C2_ITEMGRD"
	_oSQL:Log ()
	_aOP = aclone (_oSQL:Qry2Array ())
	
	if len (_aOP) == 0
		u_help ("Nenhuma OP encontrada no intervalo informado.")
	else

		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _nOP = 1 to len (_aOP)
			_aOP [_nOP, 1] = .F.
		next
		
		_aCols = {}
		aadd (_aCols, {2, 'OP',           50, ''})
		aadd (_aCols, {3, 'Produto',     140, ''})
		aadd (_aCols, {4, 'Data prev.',   35, ''})
		aadd (_aCols, {5, 'Quantidade',   40, ''})
		aadd (_aCols, {6, 'Un.med.',      30, ''})
		aadd (_aCols, {7, 'Finalidade',   60, ''})
		aadd (_aCols, {8, 'Observacoes', 200, ''})
		U_MBArray (@_aOP, 'Selecione as OPs a liberar para producao', _aCols, 1)
		for _nOP = 1 to len (_aOP)
			if _aOP [_nOP, 1]
				U_LibOpPr (_aOP [_nOP, 2], _aOP [_nOP, 2])
			endif
		next
	endif
return



// --------------------------------------------------------------------------
// Varre empenhos da OP e gera solicitacao ao almoxarifado, quando necessario.
static function _GeraZAG (_sOP)
	local _oSQL      := NIL
	local _lZAG_OK   := .T.
	local _sMsg      := ""
	local _oTrEstq   := NIL
	local _nQtGerad  := 0
	local _sAliasQ   := ""
	local _nTamLote  := 0
	local _nQtLotes  := 0
	local _aSolic    := {}
	local _nSolic    := 0
	local _nJaRequis := 0
	local _nNecessid := 0
	local _nOutrEmp  := 0
	local _nDispon   := 0
	local _sErros    := ""
	local _aCols     := {}
	private _sErroAuto := ''

	u_logIni ()
	CursorWait ()

	incproc ('Gerando solicitacoes ao almoxarifado')
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT D4_COD, D4_QUANT, D4_LOCAL, D4_LOTECTL, B1_GRUPO, B1_DESC"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=             RetSQLName ("SD4") + " SD4 "
	_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SD4.D4_FILIAL   = '" + xfilial ("SD4") + "'"
	_oSQL:_sQuery +=   " AND SD4.D4_QUANT    = D4_QTDEORI"  // Por enquanto so pegarei empenhos nao mexidos
	_oSQL:_sQuery +=   " AND SD4.D4_LOCAL   != '02'"  // Nao adianta tentar transferir para o proprio almoxarifado...
	_oSQL:_sQuery +=   " AND SD4.D4_OP       = '" + _sOP + "'"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD      = SD4.D4_COD"
	_oSQL:_sQuery +=   " AND SB1.B1_VAFULLW  = 'S'"
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("ZAG") + " ZAG "
	_oSQL:_sQuery +=                    " WHERE ZAG.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                      " AND ZAG.ZAG_FILIAL = '" + xfilial ("ZAG") + "'"
	_oSQL:_sQuery +=                      " AND ZAG.ZAG_OP     = '" + _sOP + "'"
	_oSQL:_sQuery +=                      " AND ZAG.ZAG_PRDORI = SD4.D4_COD"
	_oSQL:_sQuery +=                      " AND ZAG.ZAG_LOTORI = SD4.D4_LOTECTL)"
	_oSQL:_sQuery += " ORDER BY D4_COD, D4_LOTECTL"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)

	// Varre os empenhos da OP e gera array de solicitacoes.
	incproc ("Verificando palletizacao / multiplos dos itens.")
	_aSolic = {}
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		
		// Posiciona SB2 para posteriormente calcular a necessidade abatendo o estoque disponivel.
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		if ! sb2 -> (dbseek (xfilial ("SB2") + (_sAliasQ) -> d4_cod + (_sAliasQ) -> d4_local, .F.))
			_sErros += "Produto '" + alltrim ((_sAliasQ) -> d4_cod) + "' nao encontrado no almoxarifado '" + (_sAliasQ) -> d4_local + "'. Requisicao nao pode ser gerada."
			_lZAG_OK = .F.
		endif
		_nOutrEmp = sb2 -> b2_qemp - (_sAliasQ) -> d4_quant
		_nNecessid = (_sAliasQ) -> d4_quant - (sb2 -> b2_qatu - _nOutrEmp)

		u_log ('componente:', (_sAliasQ) -> d4_cod, '   outros empenhos:', _nOutrEmp, '   necessidade:', _nNecessid)

		// Solicitar usando o menor multiplo disponivel (cada fornecedor me manda produtos em diferentes embalagens)
		// pois o WMS vai estar configurado para permitir ao operador separar acima da quantidade solicitada.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT MIN (A5_VAQSOLW)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA5") + " SA5 "
		_oSQL:_sQuery += " WHERE SA5.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SA5.A5_FILIAL   = '" + xfilial ("SA5") + "'"
		_oSQL:_sQuery +=   " AND SA5.A5_PRODUTO  = '" + (_sAliasQ) -> d4_cod + "'"
		_oSQL:_sQuery +=   " AND SA5.A5_VAQSOLW != 0"
		_oSQL:Log ()
		_nTamLote = _oSQL:RetQry (1, .F.)
		u_log ('tam lote:', _nTamLote)

		if _nTamLote == 0
			_sErros += "Produto '" + alltrim ((_sAliasQ) -> d4_cod) + "': nao foi possivel definir o multiplo para separacao. Verifique se o produto tem amarracao com algum fornecedor e se o campo '" + alltrim (RetTitle ("A5_VAQSOLW")) + "' foi informado." + chr (13) + chr (10)
			_lZAG_OK = .F.
		else
			// Quando garrafas, solicita 'de lote em lote', pois nao tem espaco fisico na fabrica
			// para separar tudo de uma vez, e o Full so me retorna a quantidade separada depois de finalizar a onda.
			if (_sAliasQ) -> b1_grupo == '2000'
				u_log ('Trata-se de garrafa! vou particionar em ', _nTamLote)
				_nJaRequis = 0
				do while _nJaRequis < _nNecessid
					aadd (_aSolic, afill (array (.SolicQtColunas), 0))
					_aSolic [len (_aSolic), .SolicProduto]      = (_sAliasQ) -> d4_cod
					_aSolic [len (_aSolic), .SolicDescricao]    = (_sAliasQ) -> b1_desc
					_aSolic [len (_aSolic), .SolicAlmox]        = (_sAliasQ) -> d4_local
					_aSolic [len (_aSolic), .SolicLote]         = (_sAliasQ) -> d4_lotectl
					_aSolic [len (_aSolic), .SolicQtOriginal]   = (_sAliasQ) -> d4_quant
					_aSolic [len (_aSolic), .SolicSaldoEstoque] = sb2 -> b2_qatu
					_aSolic [len (_aSolic), .SolicEmpenhos]     = _nOutrEmp
					_aSolic [len (_aSolic), .SolicQtSolicitada] = _nTamLote
					_aSolic [len (_aSolic), .SolicObs]          = 'Garrafas: particionando pelo menor lote de separacao (' + cvaltochar (_nTamLote) + ')'
					_nJaRequis += _nTamLote
				enddo
			else
				// Quebra a requisicao em 'multiplos de lotes'.
				_nQtLotes = int (_nNecessid / _nTamLote)
				if _nQtLotes < _nNecessid / _nTamLote
					_nQtLotes ++
				endif
				u_log ('produto ', (_sAliasQ) -> d4_cod, 'necessidade:', _nNecessid, 'tam.lote:', _nTamLote, 'qt lotes:', _nQtLotes)

				aadd (_aSolic, afill (array (.SolicQtColunas), 0))
				_aSolic [len (_aSolic), .SolicProduto]      = (_sAliasQ) -> d4_cod
				_aSolic [len (_aSolic), .SolicDescricao]    = (_sAliasQ) -> b1_desc
				_aSolic [len (_aSolic), .SolicAlmox]        = (_sAliasQ) -> d4_local
				_aSolic [len (_aSolic), .SolicLote]         = (_sAliasQ) -> d4_lotectl
				_aSolic [len (_aSolic), .SolicQtOriginal]   = (_sAliasQ) -> d4_quant
				_aSolic [len (_aSolic), .SolicSaldoEstoque] = sb2 -> b2_qatu
				_aSolic [len (_aSolic), .SolicEmpenhos]     = _nOutrEmp
				_aSolic [len (_aSolic), .SolicQtSolicitada] = _nTamLote * _nQtLotes
				_aSolic [len (_aSolic), .SolicObs]          = 'Agrupando ' + cvaltochar (_nQtLotes) + ' lotes multiplos de ' + cvaltochar (_nTamLote)
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	u_log ('solicitacoes a gerar:', _aSolic)

	if _lZAG_OK .and. len (_aSolic) > 0
		if len (_aSolic) > 200 // Talvez este valor ainda precise ser ajustado.
			u_help ("Simulei a geracao de uma quantidade excessiva de solicitacoes ao FullWMS. Verifique produtos na tela a seguir e ajuste as quantidades informadas no campo '" + alltrim (RetTitle ("A5_VAQSOLW")) + "' na amarracao produto X fornecedor.")
			_lZAG_OK = .F.
		endif

		// Mostra tela para conferencia do usuario.
		_aCols = {}
		aadd (_aCols, {.SolicProduto, 'Codigo', 50, ''})
		aadd (_aCols, {.SolicDescricao, 'Descricao', 150, ''})
		aadd (_aCols, {.SolicAlmox, 'Almox', 30, ''})
		aadd (_aCols, {.SolicLote, 'Lote', 50, ''})
		aadd (_aCols, {.SolicQtOriginal, 'Empenho desta OP', 50, '@E 999,999,999.9999'})
		aadd (_aCols, {.SolicSaldoEstoque, 'Estoque', 60, '@E 999,999,999.9999'})
		aadd (_aCols, {.SolicEmpenhos, 'Outros emp.', 60, '@E 999,999,999.9999'})
		aadd (_aCols, {.SolicQtSolicitada, 'Qt.a solicitar', 60, '@E 999,999,999.9999'})
		aadd (_aCols, {.SolicObs, 'Observacoes', 160, ''})
		if U_F3Array (_aSolic, 'Soliciacoes ao almoxarifado', _aCols,,, 'Solicitacoes ao almoxarifado', '', .T., 'C', NIL) == 0  // Se retornar 0 eh por que o usuario cancelou
			_lZAG_OK = .F.
		endif
	endif

	if _lZAG_OK
		procregua (len (_aSolic))
		for _nSolic = 1 to len (_aSolic)
			incproc ("Gerando solicitacao ao WMS - " + _aSolic [_nSolic, .SolicProduto])
			_oTrEstq := ClsTrEstq ():New ()
			_oTrEstq:FilOrig  = cFilAnt
			_oTrEstq:FilDest  = cFilAnt
			_oTrEstq:DtEmis   = dDataBase
			_oTrEstq:OP       = _sOP
			_oTrEstq:Motivo   = 'Rancho OP ' + _sOP
			_oTrEstq:ProdOrig = _aSolic [_nSolic, .SolicProduto]
			_oTrEstq:ProdDest = _aSolic [_nSolic, .SolicProduto]
			_oTrEstq:AlmOrig  = '02'
			_oTrEstq:AlmDest  = _aSolic [_nSolic, .SolicAlmox]
			if ! empty (_aSolic [_nSolic, .SolicLote])
				_oTrEstq:LoteOrig = _aSolic [_nSolic, .SolicLote]
			endif
			_oTrEstq:QtdSolic  = _aSolic [_nSolic, .SolicQtSolicitada]
			_oTrEstq:UsrIncl   = cUserName
			_oTrEstq:LibNaIncl = .F.  // Nao tenta fazer liberacoes no momento da inclusao, pois vai precisar do Ok do FullWMS antes.
			if _oTrEstq:Grava ()
				_nQtGerad ++
			else
				_sMsg += "Erro ao solicitar produto '" + alltrim (_aSolic [_nSolic, .SolicProduto]) + "': " + _oTrEstq:UltMsg + chr (13) + chr (10)
				_lZAG_OK = .F.
			endif
		next
	endif

	if ! _lZAG_OK .or. ! empty (_sErros)
		u_help ("Erros na geracao de solicitacoes ao almoxarifado:" + chr (13) + chr (10) + _sErros)
	endif

	CursorArrow ()
	u_logFim ()
return _lZAG_OK



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3          Opcoes Help
	aadd (_aRegsPerg, {01, "OP inicial                    ", "C", 13, 0,  "",   "SC2 ", {},                              ""})
	aadd (_aRegsPerg, {02, "OP final                      ", "C", 13, 0,  "",   "SC2 ", {},                              ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
