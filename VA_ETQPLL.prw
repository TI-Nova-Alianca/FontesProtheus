// Programa...: VA_EtqPll
// Autor......: Leandro Perondi (DWT)
// Data.......: 11/12/2013
// Descricao..: Cadastro de etiquetas para os pallets
//
// Historico de alteracoes:
// 14/07/2014 - Robert - Criada opcao de regerar grupo de etiquetas (por OP, inicialmente).
//                     - Criada funcao EtqPllGO para ser chamada a partir de P.E. na geracao de O.P.
// 21/08/2014 - Robert - Alteracoes diversas no layout de impressao (descr.produto, lote, etc.)
//                     - Criado markbrowse para selecao de impressao/exclusao de grupo de etiquetas.
// 17/10/2014 - Robert - Criada opcao de posicionamento transversal na bobina de etiquetas.
// 23/10/2014 - Robert - Opcao de 'regerar grupo' passa a permitir produtos PI via confirmacao do usuario.
// 26/11/2014 - Robert - Passa a chamar a funcao U_GeraLote() para impressao de lote.
// 05/12/2014 - Robert - Criado tratamento para integracao com Fullsoft.
// 22/01/2015 - Robert - Volta a imprimir o codigo de barras com o numero do lote.
// 31/01/2015 - Robert - Criado controle de sequencia de etiqueta dentro do documento (OP/NF)
// 10/02/2015 - Robert - Avisa quando campo B1_VADUNCX estiver vazio, no momento da impressao.
// 27/04/2015 - Robert - Mesmo informando qt.manual de etiq., nao gerava nada quando item nao tinha palletizacao no cadastro.
// 10/03/2017 - J�lio  - Criado todo o processo de gera��o, impress�o e inutiliza��o de etiquetas de rastreabilidade.
// 03/05/2017 - Robert - Valida se o usuario tem permissao para incluir/excluir etiquetas.
// 28/06/2017 - Robert - Soh alimenta tabela tb_wms_etiquetas apos impressao (temos muitas etiq. que nem chegam a ser impressas).
// 20/07/2017 - Robert - Alimentava tabela tb_wms_etiquetas somente para etiquetas com codigo iniciado por '9'.
//                     - Nao permite excluir etiquetas jah vistas pelo FullWMS (tb_wms_etiquetas.status = 'S').
// 01/08/2017 - Robert - Gravacao da tabela tb_wms_etiquetas mudada para o P.E. A250ETran (apos apontamento de producao).
// 17/08/2017 - Robert - Label 'emissao:' alterada para 'impressa em:'
// 17/11/2017 - Robert - Funcoes de exclusao recebem parametro de 'com tela' para possibilitar chamada externa (P.E. MTA650AE).
// 05/02/2018 - Sandra - Alterado tamanho campo Confirme a quantidade por pallet de 999 para 99999
// 22/02/2018 - Robert - Desconsidera uvas (grupo 0400) na geracao de etiquetas de insumos.
// 03/03/2018 - Robert - Impressao etiq.NF em impressora Argox
//                     - Nao localizava item do SD1 (tamanho campo ZA1_PROD incorreto)
//                     - Melhoria query geracao etiq para NF
// 07/08/2018 - Robert - Ajustes impressao etiq.NF em impressora Argox/Datamax
// 16/08/2018 - Robert - Gera etiq.NF entrada somente para itens ja exportados para o Full (v_wms_item)
// 27/08/2018 - Robert - Ajuste pesquisa SB8 na impressao etiq. de NF
// 04/09/2018 - Robert - Criado botao de exportacao para Full
//                     - Exporta para Full apos impressao (quando etiq. de NF)
// 27/09/2018 - Robert - Passa a ler parametros das impressoras na tabela 49 do ZX5
// 02/10/2018 - Robert - Gera etiq. de NF lendo quantidades no A5_VAQTPAL
// 19/10/2018 - Robert - Gravacao do campo ZA1_IdZAG.
//                     - Rotina de impressao movida para fonte externo (ImpZA1)
// 07/11/2018 - Robert - Criada rotina para alterar tb_wms_entrada.status_protheus para 'C'
// 24/07/2019 - Sandra - ncluido grupo 069 - Custos para poder cancelar etiquetas
// 07/05/2020 - Sandra - Melhorada msg quando o usuario nao tem acesso a 'cancelar a transf. para FullWMS'.
// 20/07/2020 - Robert - Cancelamento de guarda de etiqueta passa a validar acesso 100 e nao mais 069.
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

#include "rwmake.ch"

// ----------------------------------------------------------------
User Function VA_ETQPLL()
	local _aCores     := U_ZA1LG (.T.)
	Private cCadastro := "Cadastro de Etiquetas dos Pallets"
	Private cDelFunc  := ".T."
	Private cString   := "ZA1"
	private aRotina   := {}
	private aImprim   := {}
	private aOutros   := {}

	//===Montagem do Menu===//
	// A ordem em que os itens s�o adicionados ao vetor influencia na ordem de exibi��o.
	aAdd(aRotina, {"Pesquisar"          , "AxPesqui"  , 0, 1})
	aAdd(aRotina, {"Visualizar"         , "AxVisual"  , 0, 2})
	aAdd(aRotina, {"Incluir"            , "U_EtqPlltI", 0, 3})
	aadd(aRotina, {"Imprimir - Avulso"  , "U_ImpZA1 (ZA1->ZA1_CODIGO)", 0, 2})
	aadd(aRotina, {"Imprimir - Grupo"   , "U_EtqPlltG(za1 -> za1_op, za1 -> za1_doce, za1 -> za1_seriee, za1 -> za1_fornec, za1 -> za1_lojaf, 'I')", 0, 2})
	aadd(aRotina, {"Enviar para FullWMS", "processa ({||U_EnvEtFul (za1 -> za1_codigo, .T.)})", 0, 4})
	aadd(aRotina, {"Gera Etq NF entrada", "processa ({||U_EtqPllGN ()})", 0, 3})
	aadd(aRotina, {"Regerar Grupo"      , "U_EtqPllRG()", 0, 3})
	aadd(aRotina, {"Excluir Grupo"      , "U_EtqPlltG(za1 -> za1_op, za1 -> za1_doce, za1 -> za1_seriee, za1 -> za1_fornec, za1 -> za1_lojaf, 'E')", 0, 2})
	aadd(aRotina, {"Inutilizar"         , "U_EtqPllIn(ZA1->ZA1_CODIGO,.T.)", 0, 2})
	aAdd(aRotina, {"Excluir"            , "U_EtqPlltE (.T.)", 0, 5})
	aAdd(aRotina, {"Cancela transf.Full", "U_EtqPllCT (ZA1->ZA1_CODIGO)", 0, 5})
	aadd(aRotina, {"Legenda", "U_ZA1LG()", 0, 7})
	
	dbSelectArea(cString)
	dbSetOrder(1)
	mBrowse(,,,,cString,,,,,2,_aCores)
Return

//
// Mostra legenda ou retorna array de cores, conforme o caso.
user function ZA1LG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"ZA1_APONT=='S'",                       'BR_AZUL',     'Apontada'})
	aadd (_aCores, {"ZA1_APONT=='E'",                       'BR_PRETO',    'Apont.estornado'})
	aadd (_aCores, {"empty(ZA1_APONT).and.ZA1_IMPRES=='S'", 'BR_VERMELHO', 'Impressa'})
	aadd (_aCores, {"empty(ZA1_APONT).and.ZA1_IMPRES!='S'", 'BR_VERDE',    'Nao impressa'})
	aadd (_aCores, {"ZA1_APONT=='I'",                       'BR_AMARELO',  'Inutilizada'})

	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		return _aCores
	endif
return


// --------------------------------------------------------------------------
// Inclus�o
User Function EtqPlltI ()
	private altera   := .F.
	private inclui   := .T.
	private aGets    := {}
	private aTela    := {}

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		return
	endif
	if ! U_ZZUVL ('074', __cUserID, .T.)
		return
	endif

	// Cria vari�veis 'M->' aqui para serem vistas depois da inclus�o.
	RegToMemory ("ZA1", inclui, inclui)
	u_log ('vou chamar axinclui')
	if axinclui ("ZA1", za1 -> (recno ()), 3, NIL, NIL, NIL, "allwaystrue ()") == 1
		u_log ('exinclui deu certo')
	endif

return

//
// Exclus�o
User Function EtqPlltE (_lComTela)
	local _lContinua := .T.
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	// Verifica se o usuario tem liberacao.
	if ! empty (za1 -> za1_op) .and. ! IsInCallStack ("U_MTA650AE") .and. ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif
	if ! empty (za1 -> za1_doce) .and. ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_lContinua = _PodeExcl (_lComTela)
	endif
	
	if ! empty (ZA1 -> ZA1_DOCE)
		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' n�o pode ser exclu�da." + chr(13) + "Motivo: � uma etiqueta de nota fiscal (rastreabilidade).")
		_lContinua := .F.
	endif

	if _lContinua

		if _lComTela
		
			// Cria variaveis M->... para a enchoice (a fun��o n�o cria sozinha)
			RegToMemory ("ZA1", inclui, inclui)
	
			if AxDeleta ("ZA1", za1 -> (recno ()), 5) == 2
				_AtuFull ('E')
			endif
		else
			reclock ("ZA1", .F.)
			za1 -> (dbdelete ())
			msunlock ()
			_AtuFull ('E')
		endif
	endif                                                                                                          
return



// --------------------------------------------------------------------------
// Atualiza dados para integracao com Fullsoft.
static function _AtuFull (_sQueFazer)
	local _oSQL      := NIL

	if left (za1 -> za1_codigo, 1) > '0' .and. ! empty (za1 -> za1_op)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		if _sQueFazer == 'E'
			_oSQL:_sQuery += " delete tb_wms_etiquetas"
			_oSQL:_sQuery += " where id = " + cvaltochar (za1 -> za1_codigo)
			_oSQL:Exec ()
		endif
	endif
return

//
// Regera grupo de etiquetas.
User Function EtqPllRG ()
	local _aAreaAnt  := U_ML_SRArea ()
//	local _aEtiq     := {}
	local _nEtiq     := 0
	local _oSQL      := NIL
	local _lContinua := .T.
	private cPerg    := "ETQPLLRG"	

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_lContinua = U_MsgYesNo ("Esta rotina destina-se a gerar um determinado grupo de etiquetas de uma OP. Deseja continuar?")
	endif
	if _lContinua
		_ValidPerg ()
		_lContinua = Pergunte (cPerg)
	endif
	if _lContinua
		_oSQL := ClsSQl ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA1")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZA1_OP     = '" + mv_par01 + "'"
		_oSQL:_sQuery +=    " AND ZA1_OP    <> ''"
		_nEtiq = _oSQL:RetQry ()
		if _nEtiq > 0
			_lContinua = U_MsgYesNo ("J� existem " + AllTrim(cvaltochar(_nEtiq)) + " etiquetas para a OP informada. Considere exclui-las antes para evitar duplicidades. Deseja gerar assim mesmo?")
		endif
	endif
	if _lContinua
		sc2 -> (dbsetorder (1))  // C2_FILIAL + C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD
		if sc2 -> (dbseek (xfilial ("SC2") + mv_par01, .F.))
			processa ({||U_EtqPllGO (sc2 -> c2_produto, sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd, sc2 -> c2_quant, sc2 -> c2_datprf)})
		else
			u_help ("OP nao encontrada.")
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return

//
// Gera etiquetas para a OP informada.
User Function EtqPllGO (_sProduto, _sOP, _nQuant, _dData)
	local _aPal      := {}
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _nQtPorPal := 0
	local _i         := 0

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua .and. cEmpAnt + cFilAnt != '0101'
		_lContinua = .F.
	endif
	if _lContinua .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_TIPO") != 'PA'
		_lContinua = U_MsgNoYes ("Produto desta OP n�o � do tipo PA. Confirma a gera��o das etiquetas assim mesmo?")
	endif
	if _lContinua
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (xfilial ("SC2") + _sOP, .F.))
			u_help ("OP '" + _sOP + "' n�o cadastrada.")
			_lContinua = .F.
		endif
	endif
	if _lContinua

		// Calcula palletizacao pelo padrao do produto.
		_aPal := aclone (U_VA_QTDPAL (_sProduto, _nQuant))
		if len (_aPal) == 0
			if IsInCallStack ("U_VA_ETQPLL")  // Somente na tela de etiquetas, para nao atrapalhar na inclusao de OP.
				u_help ("Nao h� paletiza��o cadastrada para o produto da OP.")
			endif
			_nQtPorPal = 0
		else
			_nQtPorPal = _aPal [1, 2]  // Qtid. do primeiro pallet gerado.
		endif

		// Permite ao usuario informar uma quantidade de caixas por pallet diferente do padrao.
		_nQtPorPal = U_Get ("Confirme quantidade por pallet", "N", 3, "999", "", _nQtPorPal, .F., '.t.')

		// Se o usuario informou algo diferente, preciso recalcular.
		if len (_aPal) == 0 .or. _nQtPorPal != _aPal [1, 2]
			_aPal := aclone (U_VA_QTDPAL (_sProduto, _nQuant, _nQtPorPal))
		endif
		
		For _i=1 to len (_aPal)
			U_IncEtqPll (_sProduto, _sOP, _aPal[_i, 2], '', '', '', '', _dData, '', '')
		next
		
		reclock ("SC2", .F.)
		sc2 -> c2_vaqtetq = len (_aPal)
		msunlock ()
	endif

	U_ML_SRArea (_aAreaAnt)
return len (_aPal)



// --------------------------------------------------------------------------
// Inclus�o autom�tica (para ser chamada de outra rotina).
User Function IncEtqPll(_sCodPro, _sNumOP, _nQtd, _sFornece, _sLoja, _sNF, _sSerie, _dData, _sItem, _sIdZAG)
	local _aAreaAnt := U_ML_SRArea ()
	local _sNextNum := ''
	local _nSeqEtq  := 0

	// Gera sequencial da etiqueta dentro do grupo (OP ou NF) a que pertence.
	if ! empty (_sNumOP) .or. ! empty (_sNF)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA1")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZA1_OP     = '" + _sNumOP + "'"
		_oSQL:_sQuery +=    " AND ZA1_DOCE   = '" + _sNF + "'"
		_oSQL:_sQuery +=    " AND ZA1_SERIEE = '" + _sSerie + "'"
		_oSQL:_sQuery +=    " AND ZA1_ITEM = '"   + _sItem + "'"
		_oSQL:_sQuery +=    " AND ZA1_FORNEC = '" + _sFornece + "'"
		_oSQL:_sQuery +=    " AND ZA1_LOJAF  = '" + _sLoja + "'"
		_nSeqEtq = _oSQL:RetQry () + 1
	endif

	_sNextNum = U_NxtZA1 (_sCodPro)
	reclock("ZA1",.T.)
	ZA1 -> ZA1_FILIAL = xFilial("ZA1")
	ZA1 -> ZA1_CODIGO = _sNextNum
	ZA1 -> ZA1_DATA   = _dData
	ZA1 -> ZA1_OP     = _sNumOP
	ZA1 -> ZA1_PROD   = _sCodPro
	ZA1 -> ZA1_QUANT  = _nQtd
	za1 -> za1_doce   = _sNF
	za1 -> za1_seriee = _sSerie
	za1 -> za1_item   = _sItem
	za1 -> za1_fornec = _sFornece
	za1 -> za1_lojaf  = _sLoja
	za1 -> za1_seq    = _nSeqEtq
	za1 -> za1_usrinc = cUserName
	za1 -> za1_hora   = left (time (), 5)
	za1 -> za1_idZAG  = _sIdZAG 
	msunlock()
	u_log2 ('info', 'Etiqueta ' + za1 -> za1_codigo + ' gravada. Produto: ' + alltrim (za1 -> za1_prod) + ' OP: ' + alltrim (za1 -> za1_op))
	//u_logtrb ('ZA1')

	do while __lSX8
		ConfirmSX8 ()
	enddo

	U_ML_SRArea (_aAreaAnt)
Return _sNextNum


// --------------------------------------------------------------------------
// Opera��es com grupo de etiquetas (por OP ou por NF).
User Function EtqPlltG (_sOP, _sNF, _sSerie, _sFornece, _sLoja, _sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _aEtiq    := {}
	local _nEtiq    := 0
	local _oSQL     := NIL
	local _aCols    := {}
	local _bSegue   := .F.
	local _bInutil  := .F.
	
	u_logIni ()

	_oSQL := ClsSQl ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ' ' AS OK, ZA1_CODIGO, ZA1_PROD, ZA1_QUANT, ZA1_IMPRES, ZA1_APONT, ZA1_DOCE"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA1")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZA1_OP     = '" + _sOP + "'"
	_oSQL:_sQuery +=    " AND ZA1_DOCE   = '" + _sNF + "'"
	_oSQL:_sQuery +=    " AND ZA1_SERIEE = '" + _sSerie + "'"
	_oSQL:_sQuery +=    " AND ZA1_FORNEC = '" + _sFornece + "'"
	_oSQL:_sQuery +=    " AND ZA1_LOJAF  = '" + _sLoja + "'"
	_oSQL:_sQuery +=    " AND ZA1_APONT != 'I'"
	_oSQL:_sQuery +=  " ORDER BY ZA1_CODIGO"
	_aEtiq = _oSQL:Qry2Array ()

	// Inicializa coluna de selecao com .F. ('nao selecionada').
	for _nEtiq = 1 to len (_aEtiq)
		_aEtiq [_nEtiq, 1] = .F.
	next

	_aCols = {}
	aadd (_aCols, {2, 'Etiqueta',    60, ''})
	aadd (_aCols, {3, 'Produto',     60, ''})
	aadd (_aCols, {4, 'Quant',       30, ''})
	aadd (_aCols, {5, 'Ja impressa', 30, ''})
	aadd (_aCols, {6, 'Ja apontada', 30, ''})
	U_MBArray (@_aEtiq, 'Selecione as etiquetas a ' + iif (_sQueFazer == 'I', 'imprimir', 'excluir'), _aCols, 1)
	
	if _sQueFazer == "I"
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, 1]
				if _aEtiq [_nEtiq, 6] == 'S'
					if U_MsgYesNo ("Etiqueta '" + _aEtiq [_nEtiq, 2] + "' ja gerou apontamento de producao. Deseja reimprimir mesmo assim?")
						U_ImpZA1 (_aEtiq [_nEtiq, 2], mv_par01)
					endif
				else
					U_ImpZA1 (_aEtiq [_nEtiq, 2], mv_par01)
				endif
			endif
		next
	endif

	if _sQueFazer == "E"
		//Testa se algum item foi selecionado
		_bSegue = .F.
		_bInutil = .F.
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, 7] != ''
				_bInutil = .T.
			endif
			if _aEtiq [_nEtiq, 1]
				_bSegue = .T.
				exit
			endif
		endfor
		//
		if _bSegue		
			_bSegue = .F.
			if _bInutil
				if U_MsgNoYes("Confirma a exclusao / inutilizacao?")
					_bSegue = .T.
				endif
			else
				if U_MsgNoYes("Confirma a exclusao?")
					_bSegue = .T.
				endif
			endif
			if _bSegue
				za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
				for _nEtiq = 1 to len (_aEtiq)
					if _aEtiq [_nEtiq, 1] .and. _aEtiq [_nEtiq, 7] != ''
						if _PodeExcl (.T.)
							U_EtqPllIn(_aEtiq[_nEtiq, 2], .F.)
						endif
					else
						if _aEtiq [_nEtiq, 1] .and. za1 -> (dbseek (xfilial ("ZA1") + _aEtiq [_nEtiq, 2], .F.))
							if _PodeExcl (.T.)
								reclock ("ZA1", .F.)
								za1 -> (dbdelete ())
								msunlock ()
								_AtuFull ('E')
							endif
						endif
					endif
				next
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return



// --------------------------------------------------------------------------
// Verifica se permite a exclusao da etiqueta.
static function _PodeExcl (_lComTela)
	local _lRet := .T.
	local _oSQL := NIL

	if za1 -> za1_apont == 'S'
		if _lComTela
			u_help("Etiqueta '" + AllTrim(za1 -> za1_codigo) + "' gerou apontamento de produ��o e n�o pode ser exclu�da ou inutilizada.")
		endif
		_lRet = .F.
	endif

	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " select count (*)"
		_oSQL:_sQuery +=   " from tb_wms_etiquetas"
		_oSQL:_sQuery +=  " where id = '" + cvaltochar (za1 -> za1_codigo) + "'" 
		_oSQL:_sQuery +=    " and status != 'N'" 
		if _oSQL:RetQry () > 0
			if _lComTela
				u_help ("Etiqueta '" + AllTrim (za1 -> za1_codigo) + "' ja vista pelo FullWMS. Nao pode ser excluida ou inutilizada. Exclua, antes, o recebimento dela no FullWMS.")
			endif
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Cancela transferencia para almox. do FullWMS
User Function EtqPllCT (_sCodigo)
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sJustif   := ""
	local _aEntr_ID  := {}
	local _sEntr_ID  := ""
	local _oEventoCG := NIL

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('100',,.F.)
		U_HELP('Usu�rio sem acesso a este tipo de operacao!',, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		za1 -> (dbsetorder(1))
		if ! za1 -> (dbseek(xFilial("ZA1") + AllTrim(_sCodigo), .F.))
			u_help ("Etiqueta '" + _sCodigo + "' nao encontrada!")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select entrada_id"
		_oSQL:_sQuery +=   " from tb_wms_entrada"
		_oSQL:_sQuery +=  " where codfor = '" + _sCodigo + "'"
		_oSQL:_sQuery +=    " and status_protheus != '3'"
		_oSQL:_sQuery +=    " and status_protheus != 'C'"
		_oSQL:Log ()
		_aEntr_ID = _oSQL:Qry2Array ()
		if len (_aEntr_ID) == 0
			u_help ("Entrada nao existe (ou ja foi executada ou cancelada) na tabela de transferencias para o FullWMS. Nao ha transferencia a cancelar.")
			_lContinua = .F.
		elseif len (_aEntr_ID) == 1
			_sEntr_ID = _aEntr_ID [1, 1] 
		elseif len (_aEntr_ID) > 1
			u_help ("Encontrei MAIS DE UMA entrada na tabela de transferencias para o FullWMS referindo essa etiqueta. Query para verificacao: " + _oSQL:_sQuery)
			_lContinua = .F.
		endif
	endif
	
	if _lContinua
		if U_MsgNoYes ("Confirma o cancelamento da transferencia para o ax. do FullWMS?")

			// Abre tela para justificativa
			do while .T.
				_sJustif = U_Get ('Justificativa', 'C', 250, '', '', space (250), .F., '.T.')
				if _sJustif == NIL
					loop
				endif
				exit
			enddo
	
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " update tb_wms_entrada"
			_oSQL:_sQuery +=    " set status_protheus = 'C'"
			_oSQL:_sQuery +=  " where codfor     = '" + _sCodigo + "'"
			_oSQL:_sQuery +=    " and entrada_id = '" + _sEntr_ID + "'"
			_oSQL:Log ()
			if _oSQL:Exec ()

				// Grava evento dedo-duro
				_oEventoCG := ClsEvent ():New ()
				_oEventoCG:CodEven   = 'ZA1001'
				_oEventoCG:Texto     = 'Cancelamento necessidade de guardar etiq ' + alltrim (_sCodigo) + '. Justif: ' + _sJustif
				_oEventoCG:Produto   = za1 -> za1_prod
				_oEventoCG:Etiqueta  = za1 -> za1_codigo
				_oEventoCG:OP        = za1 -> za1_op
				_oEventoCG:NFEntrada = za1 -> za1_doce
				_oEventoCG:SerieEntr = za1 -> za1_seriee
				_oEventoCG:Grava ()
				
				u_help ("Cancelamento gravado.")
			endif
		endif
	endif
return


// --------------------------------------------------------------------------
// Inutiliza Etiqueta
User Function EtqPllIn (_sCodigo, _bMostraMsg)
	local _oSQL      := NIL
	local _lContinua := .T.
	
	// Verifica se o usuario tem liberacao.
	if ! empty (za1 -> za1_op) .and. ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif
	if ! empty (za1 -> za1_doce) .and. ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	za1 -> (dbsetorder(1))
	if ! za1 -> (dbseek(xFilial("ZA1") + AllTrim(_sCodigo), .F.))
		u_help ("Etiqueta '" + _sCodigo + "' nao encontrada!",, .t.)
		_lContinua = .F.
	endif
	
	if ! empty (ZA1 -> ZA1_OP) .and. _lContinua
		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' nao pode ser inutilizada por ser uma etiqueta de ordem de producao.",, .t.)
		_lContinua := .F.
	endif

	if (ZA1 -> ZA1_APONT == 'I') .and. _lContinua
		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' ja encontra-se inutilizada.",, .t.)
		_lContinua := .F.
	endif

	if _lContinua
		if _bMostraMsg
			_lContinua = .F.
			_lContinua = U_MsgNoYes ("Confirma a inutiliza��o da etiqueta?")
		endif
		
		if _lContinua
		
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZA1")
			_oSQL:_sQuery += " SET ZA1_APONT = 'I'" 
			_oSQL:_sQuery += " WHERE ZA1_CODIGO = '" + ZA1 -> ZA1_CODIGO + "'"
			_oSQL:_sQuery += " AND D_E_L_E_T_ = ''"
			_oSQL:Exec ()
			
			u_help ("Etiqueta '" + alltrim(_sCodigo) + "' inutilizada!" + chr(13) + "(Remover do Recipiente)")
		endif
	endif
return _lContinua


// --------------------------------------------------------------------------
// Gera etique a partir da NF de Entrada
User Function EtqPllGN ()
	local _aEtiq     := {}
	local _nEtiq     := 0
	local _oSQL      := NIL
	local _aCols     := {}
//	local _nQuant    := 0
	local _nQtPorPal := 0
//	local _Msg       := ""
	local _aPal      := {}
//	local _nPal      := 0
	local _lContinua := .T.
	local _i         := 0
	local _dDataIni  := date () - 7

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_dDataIni = U_Get ("Buscar notas a partir de", "D", 8, "", "", _dDataIni, .F., '.T.')
		
		procregua (10)
		incproc ("Buscando notas sem etiqueta")

		_oSQL := ClsSQl ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "select " 
		_oSQL:_sQuery += "	' ' as OK, " 
		_oSQL:_sQuery += "	D1_DOC     as NotaFiscal, " 
		_oSQL:_sQuery += "	dbo.VA_DTOC(D1_EMISSAO) as Emissao, "
		_oSQL:_sQuery += "	A2_NOME    as Fornecedor, "
		_oSQL:_sQuery += "	D1_ITEM    as Linha, "
		_oSQL:_sQuery += "	D1_LOTEFOR as LoteFor, "
		_oSQL:_sQuery += "	D1_LOTECTL as Lote, "
		_oSQL:_sQuery += "	B1_COD     as Codigo, " 
		_oSQL:_sQuery += "	B1_DESC    as Item, "
		_oSQL:_sQuery += "	B1_UM      as UM, "
		_oSQL:_sQuery += "	D1_QUANT   as Quantidade, " 
		_oSQL:_sQuery += "	A2_COD     as CodFornec, " 
		_oSQL:_sQuery += "	A2_LOJA    as Loja, " 
		_oSQL:_sQuery += "	D1_SERIE   as Serie " 
		_oSQL:_sQuery += "from "
		_oSQL:_sQuery += "	" + RetSQLName ("SD1") + " as SD1, " 
		_oSQL:_sQuery += "	" + RetSQLName ("SB1") + " as SB1, "
		_oSQL:_sQuery += "	" + RetSQLName ("SA2") + " as SA2, "
		_oSQL:_sQuery += "	" + RetSQLName ("SF4") + " as SF4 "
		_oSQL:_sQuery += "where "
		_oSQL:_sQuery += "	D1_COD    = B1_COD     and "
		_oSQL:_sQuery += "	A2_FILIAL = '" + xfilial ("SA2") + "' and "
		_oSQL:_sQuery += "	A2_LOJA   = D1_LOJA    and "
		_oSQL:_sQuery += "	A2_COD    = D1_FORNECE and "
		_oSQL:_sQuery += "	B1_FILIAL = '" + xfilial ("SB1") + "' and "
		_oSQL:_sQuery += "	B1_UM <> 'LT'                 and "
		_oSQL:_sQuery += "	B1_GRUPO != '0400'            and "  // Uvas
		// Inicialmente nao vamos exigir rastreabilidade no Protheus --> _oSQL:_sQuery += "	B1_RASTRO = 'L'               and "
		// Inicialmente nao vamos exigir rastreabilidade no Protheus --> _oSQL:_sQuery += "	D1_LOTECTL <> ''              and "
		_oSQL:_sQuery += "	D1_FILIAL = '" + xfilial ("SD1") + "' and "
		_oSQL:_sQuery += "	D1_QUANT  > 0                 and "
		_oSQL:_sQuery += "	D1_DTDIGIT >= '" + dtos (_dDataIni) + "' and "
		_oSQL:_sQuery += "	F4_CODIGO = D1_TES     and "
		_oSQL:_sQuery += "	F4_ESTOQUE = 'S'              and "
		_oSQL:_sQuery += "	B1_COD not in (select ZA1_PROD from ZA1010 where ZA1_FILIAL = D1_FILIAL and ZA1_DOCE = D1_DOC and ZA1_SERIEE = D1_SERIE and ZA1_PROD = D1_COD and ZA1_APONT <> 'I' and D1_ITEM = ZA1_ITEM and ZA1010.D_E_L_E_T_ = '') and "
		_oSQL:_sQuery += "	EXISTS (SELECT * FROM v_wms_item I WHERE I.coditem = B1_COD) and"
		_oSQL:_sQuery += "	SD1.D_E_L_E_T_ = '' and "
		_oSQL:_sQuery += "	SB1.D_E_L_E_T_ = '' and "
		_oSQL:_sQuery += "	SA2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "Order By "
		_oSQL:_sQuery += "	D1_FILIAL, " 
		_oSQL:_sQuery += "	D1_EMISSAO, "
		_oSQL:_sQuery += "	D1_DOC "
		_oSQL:Log ()
		
		_aEtiq = aclone(_oSQL:Qry2Array ())
		
		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _nEtiq = 1 to len (_aEtiq)
			_aEtiq [_nEtiq, 1] = .F.
		next
		
		_aCols = {}
		aadd (_aCols, {2, 'Nota Fiscal',     40, ''})
		aadd (_aCols, {3, 'Emiss�o',       40, ''})
		aadd (_aCols, {4, 'Fornecedor', 70, ''})
		aadd (_aCols, {5, 'Linha', 30, ''})
		aadd (_aCols, {6, 'Lote Forn.', 40, ''})
		aadd (_aCols, {7, 'Lote Interno', 40, ''})
		aadd (_aCols, {8, 'Produto', 20, ''})
		aadd (_aCols, {9, 'Descri��o', 150, ''})
		aadd (_aCols, {10,'UM', 10, ''})
		aadd (_aCols, {11,'Quant.', 30, ''})
		aadd (_aCols, {12,'Cod.forn.', 30, ''})
		aadd (_aCols, {13,'Loja', 30, ''})
		
		U_MBArray (@_aEtiq, 'Selecione as notas para gerar etiquetas', _aCols, 1)
		
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, 1]
			
				// Busca quantidade por pallet no relacionamento produto X fornecedor.
				sa5 -> (dbsetorder (2))
				if ! sa5 -> (dbseek (xfilial ("SA5") + _aEtiq [_nEtiq, 8] + _aEtiq [_nEtiq, 12] + _aEtiq [_nEtiq, 13], .F.))
					u_help ("Nao encontrei relacionamento do produto '" + alltrim(_aEtiq [_nEtiq, 8]) + "' com o fornecedor '" + _aEtiq [_nEtiq, 12] + '/' + _aEtiq [_nEtiq, 13] + "' para buscar o padrao de palletizacao.")
					loop
				elseif sa5 -> a5_vaqtpal == 0
					u_help ("Quantidade por pallet nao informada para o produto '" + alltrim(_aEtiq [_nEtiq, 8]) + "' no fornecedor '" + _aEtiq [_nEtiq, 12] + '/' + _aEtiq [_nEtiq, 13] + "'. Verifique o campo '" + alltrim (RetTitle ("A5_VAQTPAL")) + "' na amarracao produto X fornecedor.")
					loop
				else
					_nQtPorPal = sa5 -> a5_vaqtpal
				endif
				u_log ('_nQtPorPal', _nQtPorPal)

				// Usa a funcao padrao de palletizacao para manter compatibilidade com outras rotinas.
				_aPal := aclone (U_VA_QTDPAL (_aEtiq [_nEtiq, 8], _aEtiq [_nEtiq, 11], _nQtPorPal))
				u_log ('_aPal:', _aPal)

				if U_MsgYesNo ("Serao geradas " + cvaltochar (len (_aPal)) + " etiquetas (" + cvaltochar (_nQtPorPal) + " cada) para este item. Confirma?")
					procregua (len (_aPal))
					for _i=1 to len(_aPal)
						incproc ("Gerando etiqueta " + cvaltochar (_i) + " de " + cvaltochar (len (_aPal)))
						U_IncEtqPll (_aEtiq [_nEtiq, 8], '', _aPal[_i, 2], _aEtiq [_nEtiq, 12], _aEtiq [_nEtiq, 13], _aEtiq [_nEtiq, 2], _aEtiq [_nEtiq, 14], date(), _aEtiq [_nEtiq, 5], '')
					next
					u_log ('etiq.geradas')
					U_EtqPlltG ('', _aEtiq [_nEtiq, 2], _aEtiq [_nEtiq, 14], _aEtiq [_nEtiq, 12], _aEtiq [_nEtiq, 13], 'I')
					u_log ('retornou do U_EtqPlltG')
				endif
			endif
		next
	endif
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "OP                            ", "C", 13, 0,  "",   "SC2", {},                         ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
