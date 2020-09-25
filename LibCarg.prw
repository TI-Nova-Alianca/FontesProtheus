// Programa...: LibCarg
// Autor......: DWT
// Data.......: 2014
// Descricao..: Faz a 'liberacao' de um cargas do OMS para geracao de notas.
//
// Historico de alteracoes:
// 26/09/2014 - Robert - Removido do P.E. OM200US; passa a ser um fonte separado.
//                     - Caso nao receba o numero da carga como parametro, abre browse para selecao.
// 03/10/2015 - Robert - Removido botao 'Pegar da doca'.
//

// ----------------------------------------------------------------
User Function LibCarg (_sCarga)
	local _aAreaAnt   := U_ML_SRArea ()
	local _nLock      := 0
	local _lContinua  := .T.
//	local _aSepara    := {}
//	local _oSQL       := NIL
//	local _sMsg       := ""
//	local _aProd       := {}
//	local _nProd       := 0
	private _sWhere   := ""
	private cString   := "DAK"
	private cCadastro := "Liberacao de cargas para faturamento"
	private aRotina   := {}

	CursorWait ()

	// Se nao recebeu o numero da carga como parametro, abre browse para selecao
	// do usuario, chama a propria rotina, passando o numero da carga e retorna.
	if _lContinua
		if _sCarga == NIL
			aadd (aRotina, {"&Pesquisar"          , "AxPesqui", 0,1})
			aadd (aRotina, {"&Visualizar"         , "AxVisual", 0,1})
//			aadd (aRotina, {"Pegar da &doca"      , "U_CargDoca (dak->dak_cod)", 0,4})
			aadd (aRotina, {"&Envia p/ FullWMS"   , "U_CargFull ('E')", 0,4})
			aadd (aRotina, {"&Cancelar no FullWMS", "U_CargFull ('C')", 0,4})
			aadd (aRotina, {"&Liberar p/ fatur"   , "U_LibCarg (dak->dak_cod)", 0,4})
			mBrowse(,,,,cString,,,,,2)
			return
		endif
	endif

	U_LOG2 ('DEBUG', 'Iniciando liberacao da carga ' + _sCarga)

	// Controle de semaforo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("DAK") + _sCarga, .T.)
		if _nLock == 0
			_lContinua = .F.
		endif
	endif

	// Define clausula 'where' para o SQL, pois vai ser usada em mais de um local.
	if _lContinua
		_sWhere := ""
		_sWhere +=  " FROM " + RetSQLName ("SC9") + " SC9, "
		_sWhere +=             RetSQLName ("SB1") + " SB1, "
		_sWhere +=             RetSQLName ("DAI") + " DAI, "
		_sWhere +=             RetSQLName ("DAK") + " DAK "
		_sWhere += " WHERE SC9.D_E_L_E_T_ = ''"
		_sWhere +=   " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
		_sWhere +=   " AND SC9.C9_PEDIDO  = DAI.DAI_PEDIDO"
		_sWhere +=   " AND SB1.D_E_L_E_T_ = ''"
		_sWhere +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_sWhere +=   " AND SB1.B1_COD     = SC9.C9_PRODUTO"
		_sWhere +=   " AND DAI.D_E_L_E_T_ = ''"
		_sWhere +=   " AND DAI.DAI_FILIAL = '" + xfilial ("DAI") + "'"
		_sWhere +=   " AND DAI.DAI_COD    = DAK.DAK_COD"
		_sWhere +=   " AND DAK.D_E_L_E_T_ = ''"
		_sWhere +=   " AND DAK.DAK_FILIAL = '" + xfilial ("DAK") + "'"
		_sWhere +=   " AND DAK.DAK_COD    = '" + dak -> dak_cod + "'"
	endif

	// Chama as rotinas de liberacao tanto para itens separados pelo Fullsoft
	// como pelo Protheus. Cada uma vai verificar os produtos
	// correspondentes. Se as duas retornarem OK, libera a carga.
	if _lContinua
		_lContinua = _LibFull2 ()
		u_log2 ('debug', 'Retorno da funcao _LibFull2: ' + cvaltochar (_lContinua))
	endif
	if _lContinua
		_lContinua = _LibProt2 ()
		u_log2 ('debug', 'Retorno da funcao _LibProt2: ' + cvaltochar (_lContinua))
	endif
	if _lContinua
		reclock("DAK",.F.)
		DAK -> DAK_VALIBE = .T.
		msunlock()
	endif

	// Libera semaforo
	U_Semaforo (_nLock)

	CursorArrow ()

	U_ML_SRArea (_aAreaAnt)
Return



// -------------------------------------------------------------------------------------
// Libera carga separada pelo Protheus
static function _LibProt2 ()
	local _lLib       := .T.
	local _cMens      := "Execute os servicos da carga antes de libera-la para faturamento. Produtos:  "
	local _sAliasQ    := ""
	local _aPedidos   := {}
	local _nPedido    := 0
	local _lContinua  := .T.
	local _lLotesOK   := .F.
	local _oSQL       := NIL

	//20140517 - confere se a carga toda esta ok - somente sera liberada se estiver toda executada
	//somente libera o pedido se todos os itens estiverem com C9_STSERV = 3 e C9_BLWMS = 05 ou C9_STSERV = ''
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT C9_STSERV, C9_BLWMS, C9_PRODUTO"
		_oSQL:_sQuery += _sWhere
		_oSQL:_sQuery += " AND B1_VAFULLW != 'S'"
		_sAliasQ = _oSQL:Qry2Trb ()
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			if (_sAliasQ) -> c9_stserv == '3' .and. (_sAliasQ)->C9_BLWMS == '05' .or. ;
			   (Empty(Alltrim((_sAliasQ) -> c9_stserv)) .and. Empty(Alltrim((_sAliasQ)->C9_BLWMS)) ) .or. ;
			   ((_sAliasQ) -> c9_stserv == '3' .and. Empty(Alltrim((_sAliasQ)->C9_BLWMS)) ) 	
			else
				_lLib := .F.
				_cMens += (_sAliasQ) -> c9_produto + " tem pendencias -> Status " + Alltrim((_sAliasQ) -> c9_stserv) + ;
				          "  Blq WMS '" +  Alltrim((_sAliasQ)->C9_BLWMS) + "'. " + chr(13)+ chr(10)
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
		
		//20140517 - laco para efetivamente ajustar o SC9 para permitir faturamento, apagando o C9_BLWMS
		//           somente acontecera isso se todos estiverem ok
		if ! _lLib
			u_help (_cMens,, .t.)
		else
	
			// Unifica lotes de produtos em um unico lote, para que nao exista repeticao de
			// produtos na nota fiscal. Para rastreabilidade, gera novo lote amarrado com cada pedido.
			// Busca registros do SC9 para a carga atual, desprezando os lotes e acumulando as
			// quantidades. Mantive fora do agrupamento alguns campos que nao sei exatamente a
			// utilizacao, para tentar minimizar a possibilidade de problemas.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DISTINCT C9_PEDIDO, ''"
			_oSQL:_sQuery += _sWhere
			_oSQL:_sQuery += " AND B1_RASTRO = 'L'"
			_aPedidos := aclone (_oSQL:Qry2Array ())
			for _nPedido = 1 to len (_aPedidos)
				processa ({|| _lLotesOK := U_LtPedido (_aPedidos [_nPedido, 1], "U")})
				if _lLotesOK
					_aPedidos [_nPedido, 2] = .T.
					
					// Libera itens do pedido.
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " UPDATE SC9 SET C9_BLWMS = '', C9_VABLOQ = 'N'"
					_oSQL:_sQuery += _sWhere
					_oSQL:_sQuery += " AND SC9.C9_PEDIDO = '" + _aPedidos [_nPedido, 1] + "'"
					if ! _oSQL:Exec ()
						_aPedidos [_nPedido, 2] = .F.
						u_help ("Erro no SQL ao liberar pedido '" + _aPedidos [_nPedido, 1] + "'.",, .t.)
					endif
				else
					_aPedidos [_nPedido, 2] = .F.
					u_help ("Nao foi possivel unificar os lotes do pedido '" + _aPedidos [_nPedido, 1] + "'.",, .t.)
				endif

				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT COUNT (*)"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC9") + " SC9 "
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery +=    " AND C9_PEDIDO  = '" + _aPedidos [_nPedido, 1] + "'"
				_oSQL:_sQuery +=    " AND C9_SEQUEN  > '01'"
				if _oSQL:RetQry () > 0
					u_help ("Itens repetidos no pedido " + _aPedidos [_nPedido, 1],, .t.)
					_aPedidos [_nPedido, 2] = .F.
				endif

				// Verifica se o SC9 estah de acordo com o SC6 (ainda nao confio muito na aglutinacao que fiz...)
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "WITH C AS ("
				_oSQL:_sQuery += " SELECT C6_ITEM, C6_QTDVEN,"
				_oSQL:_sQuery +=        " (SELECT SUM (C9_QTDLIB)"
				_oSQL:_sQuery +=           " FROM " + RetSQLName ("SC9") + " SC9 "
				_oSQL:_sQuery +=          " WHERE SC9.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=            " AND SC9.C9_FILIAL  = SC6.C6_FILIAL"
				_oSQL:_sQuery +=            " AND SC9.C9_PEDIDO  = SC6.C6_NUM"
				_oSQL:_sQuery +=            " AND SC9.C9_ITEM    = SC6.C6_ITEM) AS QT_SC9"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC6") + " SC6 "
				_oSQL:_sQuery +=  " WHERE SC6.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND SC6.C6_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery +=    " AND SC6.C6_NUM     = '" + _aPedidos [_nPedido, 1] + "'"
				_oSQL:_sQuery += " )"
				_oSQL:_sQuery += " SELECT *"
				_oSQL:_sQuery +=   " FROM C"
				_oSQL:_sQuery +=   " WHERE C6_QTDVEN != QT_SC9"
				if len (_oSQL:Qry2Array ()) > 0
					u_help ("Inconsistencia entre a quantidade do pedido e a quantidade liberada no pedido " + _aPedidos [_nPedido, 1],, .t.)
					_aPedidos [_nPedido, 2] = .F.
				endif

			next
			if ascan (_aPedidos, {| _aVal| _aVal [2] == .F.}) > 0
				u_help ("Nao foi possivel liberar todos os pedidos.",, .t.)
				_lLib = .F.
			endif
		endif
	endif
return _lLib



// -------------------------------------------------------------------------------------
// Libera carga separada pelo Fullsoft
static function _LibFull2 ()
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sNroDoc   := ""
	local _lContinua := .T.
	local _aDifer    := {}
	local _aCols     := {}
	local _sMsg      := ""

	// Monta chave de leitura da tabela de retornos do Fullsoft.
	// Importante: manter aqui o campo Saida_Id igual `a view V_WMS_PEDIDOS
	//_sSaida_Id = 'DAK' + dak -> dak_filial + dak -> dak_cod + dak -> dak_seqcar
	_sNroDoc = '20' + dak -> dak_filial + dak -> dak_cod

	// Verifica se tem produtos controlados pelo Fullsoft.
	if _lContinua .and. _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery += _sWhere
		_oSQL:_sQuery += " AND B1_VAFULLW = 'S'"
		if _oSQL:RetQry () == 0
			u_log2 ('info', 'Carga nao tem itens controlados pelo FullWMS.')
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select count (*)"
		_oSQL:_sQuery +=   " from tb_wms_pedidos"
		_oSQL:_sQuery +=  " where nrodoc   = '" + _sNroDoc + "'"
		_oSQL:_sQuery +=    " and status  != '6'"
		if _oSQL:RetQry () > 0
			_sMsg = "Separacao ainda nao encerrada no Fullsoft"
			if U_ZZUVL ('029', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg,, .t.)
				_lRet = .F.
			endif
		endif
	endif

	// Confere totais separados
	if _lContinua .and. _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " WITH C AS ("
		_oSQL:_sQuery += " SELECT C9_PRODUTO, B1_DESC, SUM (C9_QTDLIB) AS QT_CARGA,"
		_oSQL:_sQuery +=        " isnull("
		_oSQL:_sQuery +=               " (select qtde_exec"
		_oSQL:_sQuery +=                  " from tb_wms_pedidos"
		_oSQL:_sQuery +=                 " where nrodoc   = '" + _sNroDoc + "'"
		_oSQL:_sQuery +=                   " and status   = '6'"
		_oSQL:_sQuery +=                   " and coditem  = RTRIM (SC9.C9_PRODUTO))"
		_oSQL:_sQuery +=        ", 0) AS QT_SEPARADA"
		_oSQL:_sQuery += _sWhere
		_oSQL:_sQuery += " AND B1_VAFULLW = 'S'"
		_oSQL:_sQuery += " GROUP BY C9_PRODUTO, B1_DESC"
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT *"
		_oSQL:_sQuery +=   " FROM C"
		_oSQL:_sQuery +=  " WHERE QT_CARGA != QT_SEPARADA"
		_aDifer := aclone (_oSQL:Qry2Array ())
		if len (_aDifer) > 0
			_aCols = {}
			aadd (_aCols, {1, 'Produto',        60, ''})
			aadd (_aCols, {2, 'Descricao',     100, ''})
			aadd (_aCols, {3, 'Qt solicitada',  60, '@E 999,999.99'})
			aadd (_aCols, {4, 'Qt separada',    60, '@E 999,999.99'})
			U_F3Array (_aDifer, 'Diferencas', _aCols, nil, nil, "Quantidade solicitada diferente da separada no Fullsoft:", '', .T., 'C')
			if U_ZZUVL ('029', __cUserId, .F.)
				_lRet = U_MsgNoYes ("Deseja liberar a carga mesmo com as diferencas apontadas?")
			else
				_lRet = .F.
			endif
		endif
	endif

	// Libera itens dos pedidos.
	if _lContinua .and. _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("SC9") + " SET C9_BLWMS = '', C9_VABLOQ = 'N', C9_STSERV = '3'"
		_oSQL:_sQuery += _sWhere
		_oSQL:Exec ()
	endif

return _lRet
