// Programa...: VA_EtqPll
// Autor......: Leandro Perondi (DWT)
// Data.......: 11/12/2013
// Descricao..: Cadastro de etiquetas para os pallets

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

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
// 10/03/2017 - Júlio  - Criado todo o processo de geração, impressão e inutilização de etiquetas de rastreabilidade.
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
// 14/12/2020 - Robert - Rotina de inutilizacao (EtqPllIn) migrada para fonte proprio.
// 22/11/2021 - Robert - Verifica se tem campos B1_VAFULLW e B1_CODBAR antes de gerar etiquetas por OP.
// 24/01/2022 - Robert - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
//                     - Funcao EtqPllGN (interna) migrada para fonte externo ZA1GN.
// 31/03/2022 - Sandra - Comentariado campo ZA1_HORA GLPI 11862
// 07/04/2022 - Robert - Verifica classe ClsEtiq para ver se pode excluir etiquetas (GLPI 11825)
// 15/06/2022 - Robert - Exclusao passada para a classe ClsEtiq (GLPI 12220)
// 16/06/2022 - Robert - Melhorada interface com usuario na funcao EtqPllCT().
// 28/09/2022 - Robert - Melhorada leitura da tb_wms_entrada na rotina de abortar guarda do pallet.
// 05/10/2022 - Robert - Iniciada funcao U_ZA1SD5, para receber da MTA390MNU (GLPI 12651)
// 12/02/2023 - Robert - Chamada da funcao U_IncEtqPll substituida por criacao
//                       das etiquetas diretamente via metodo ClsEtiq:New() - GLPI 13134
// 22/03/2023 - Robert - Impressao de etiquetas passa a gerar todas num unico arquivo.
// 23/03/2023 - Robert - Removidos alguns logs.
// 12/04/2023 - Robert - Inclusao manual (via tela) passada para funcao ZA1Inc() no fonte ZA1.PRW
//                     - Passa a usar semaforo na geracao de etiquetas por grupo.
// 12/05/2023 - Robert - Criado botao p/impr.avulsa com cod.barras (GLPI 13561).
//

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

	// A ordem em que os itens são adicionados ao vetor influencia na ordem de exibição.
	aAdd(aRotina, {"Pesquisar"           , "AxPesqui"  , 0, 1})
	aAdd(aRotina, {"Visualizar"          , "AxVisual"  , 0, 2})
	aAdd(aRotina, {"Incluir"             , "U_ZA1Inc", 0, 3})
	aadd(aRotina, {"Imprimir - Avulso"   , "U_ZA1ImpAv (.f.)", 0, 2})

	// Botao de uso mais restrito.
	if U_ZZUVL ('047', __cUserID, .f.) .OR. U_ZZUVL ('122', __cUserID, .f.)
		aadd(aRotina, {"Imprimir c/cod.barra", "U_ZA1ImpAv (.t.)", 0, 2})
	endif

	aadd(aRotina, {"Imprimir - Grupo"    , "U_EtqPlltG(za1 -> za1_op, za1 -> za1_doce, za1 -> za1_seriee, za1 -> za1_fornec, za1 -> za1_lojaf, 'I')", 0, 2})
	aadd(aRotina, {"Enviar para FullWMS" , "processa ({||U_EnvEtFul (za1 -> za1_codigo, .T.)})", 0, 4})
	aadd(aRotina, {"Gera Etq NF entrada" , "U_ZA1GN ()", 0, 3})
	aadd(aRotina, {"Regerar Grupo"       , "U_EtqPllRG()", 0, 3})
	aadd(aRotina, {"Excluir Grupo"       , "U_EtqPlltG(za1 -> za1_op, za1 -> za1_doce, za1 -> za1_seriee, za1 -> za1_fornec, za1 -> za1_lojaf, 'E')", 0, 2})
	aadd(aRotina, {"Inutilizar"          , "U_ZA1In (ZA1->ZA1_CODIGO, .T.)", 0, 2})
	aAdd(aRotina, {"Excluir"             , "U_EtqPlltE (.T.)", 0, 5})
	aAdd(aRotina, {"Abortar transf.ax 01", "U_EtqPllCT (ZA1->ZA1_CODIGO)", 0, 5})
	aadd(aRotina, {"Legenda", "U_ZA1LG()", 0, 7})
	
	dbSelectArea(cString)
	dbSetOrder(1)
	mBrowse(,,,,cString,,,,,2,_aCores)
Return

// --------------------------------------------------------------------------
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

/*
// --------------------------------------------------------------------------
// Inclusão
User Function EtqPlltI ()
	local _lRetIncl := .F.
	local _oEtiq    := NIL
	private altera  := .F.
	private inclui  := .T.
	private aGets   := {}
	private aTela   := {}

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		return
	endif
	if ! U_ZZUVL ('074', __cUserID, .T.)
		return
	endif

	// Cria variáveis 'M->' aqui para serem vistas depois da inclusão.
	RegToMemory ("ZA1", inclui, inclui)

	// Apos a inclusao do registro, faz os tratamentos necessarios.
	if axinclui ("ZA1", za1 -> (recno ()), 3, NIL, NIL, NIL, "allwaystrue ()") == 1
		CursorWait ()
		_oEtiq := ClsEtiq():New ()
		_oEtiq:GeraAtrib ('M')  // Gerar a partir das variaveis M-> da tela.
		u_logobj (_oEtiq, .t., .f.)
		if _oEtiq:PodeIncl ()
			_lRetIncl = _oEtiq:Grava ()
		else
			_lRetIncl = .F.
		endif
		CursorArrow ()
		if ! _lRetIncl
			u_help (_oEtiq:UltMsg,, .t.)
		else
			u_help ("Etiqueta '" + _oEtiq:Codigo + "' gerada.")
		endif
	endif
return _lRetIncl
*/

// --------------------------------------------------------------------------
// Exclusão
User Function EtqPlltE (_lComTela)
	local _lContinua := .T.
	local _oEtiq     := NIL
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	_oEtiq := ClsEtiq ():New (za1 -> za1_codigo)

	// Verifica se o usuario tem liberacao.
	if ! empty (za1 -> za1_op) .and. ! IsInCallStack ("U_MTA650AE") .and. ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif
	if ! empty (za1 -> za1_doce) .and. ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_lContinua = _oEtiq:PodeExcluir (_lComTela)
	endif
	
//	if ! empty (ZA1 -> ZA1_DOCE)
//		u_help ("A etiqueta '" + alltrim(ZA1 -> ZA1_CODIGO) + "' não pode ser excluída." + chr(13) + "Motivo: É uma etiqueta de nota fiscal (rastreabilidade).")
//		_lContinua := .F.
//	endif

	if _lContinua
		if _lComTela
		
			// Cria variaveis M->... para a enchoice (a função não cria sozinha)
			RegToMemory ("ZA1", inclui, inclui)
	
			if AxDeleta ("ZA1", za1 -> (recno ()), 5) == 2
				//_AtuFull ('E')
				_oEtiq:Exclui ()
			endif
		else
			//reclock ("ZA1", .F.)
			//za1 -> (dbdelete ())
			//msunlock ()
			//_AtuFull ('E')
			_oEtiq:Exclui ()
		endif
	endif
return



// --------------------------------------------------------------------------
// Atualiza dados para integracao com Fullsoft.
static function _AtuFull (_sQueFazer)
	local _oSQL      := NIL

	//if left (za1 -> za1_codigo, 1) > '0' .and. ! empty (za1 -> za1_op)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		if _sQueFazer == 'E'
			_oSQL:_sQuery += " delete tb_wms_etiquetas"
			_oSQL:_sQuery += " where id = " + cvaltochar (za1 -> za1_codigo)
			_oSQL:Exec ()
		endif
	//endif
return

// --------------------------------------------------------------------------
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
			_lContinua = U_MsgYesNo ("Já existem " + AllTrim(cvaltochar(_nEtiq)) + " etiquetas para a OP informada. Considere exclui-las antes para evitar duplicidades. Deseja gerar assim mesmo?")
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


// --------------------------------------------------------------------------
// Gera etiquetas para a OP informada.
User Function EtqPllGO (_sProduto, _sOP, _nQuant, _dData)
	local _aPal      := {}
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _nQtPorPal := 0
	local _nPal      := 0
	local _oEtiq     := NIL
	local _nLock     := 0

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('073', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua .and. cEmpAnt + cFilAnt != '0101'  // Nao temos FullWMS nas filiais
		_lContinua = .F.
	endif
	if _lContinua
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (xfilial ("SC2") + _sOP, .F.))
			u_help ("OP '" + _sOP + "' não cadastrada.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Produto '" + alltrim (_sProduto) + "' nao localidado no cadastro. Etiquetas nao serao geradas.")
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. sb1 -> b1_vafullw != 'S'
		u_help ("Produto '" + alltrim (_sProduto) + "' nao configurado para integracao com FullWMS. Etiquetas nao serao geradas.")
		_lContinua = .F.
	endif
	if _lContinua .and. empty (sb1 -> b1_codbar)
		u_help ("Produto '" + alltrim (_sProduto) + "' nao tem codigo de barras informado no campo '" + alltrim (RetTitle ("B1_CODBAR")) + "'. Etiquetas nao serao geradas.")
		_lContinua = .F.
	endif
	if _lContinua

		// Calcula palletizacao pelo padrao do produto.
		_aPal := aclone (U_VA_QTDPAL (_sProduto, _nQuant))
		if len (_aPal) == 0
			if IsInCallStack ("U_VA_ETQPLL")  // Somente na tela de etiquetas, para nao atrapalhar na inclusao de OP.
				u_help ("Nao há paletização cadastrada para o produto da OP.")
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

		// Controla semaforo de gravacao, por que a numeracao deve ser unica.
		U_Log2 ('debug', '[' + procname () + ']Criando semaforo para numeracao de etiquetas.')
		_nLock := U_Semaforo ('GeraNumeroZA1', .T.)  // Usar a mesma chave em todas as chamadas!
		if _nLock == 0
			u_help ("Bloqueio de semaforo na geracao de numeracao de etiquetas.",, .t.)
		else
			For _nPal=1 to len (_aPal)
				_oEtiq := ClsEtiq ():New ()
				_oEtiq:OP         = _sOP
				_oEtiq:Produto    = _sProduto
				_oEtiq:Quantidade = _aPal [_nPal, 2]
				_oEtiq:QtEtqGrupo = len (_aPal)
				_oEtiq:SeqNoGrupo = _nPal
				if ! _oEtiq:Grava ((_nLock != 0))
					u_help (_oEtiq:UltMsg += "Nao foi possivel gravar a etiqueta.",, .t.)
					exit
				endif
			next
		endif

		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif

//		reclock ("SC2", .F.)
//		sc2 -> c2_vaqtetq = len (_aPal)  // ELIMINAR ISTO QUANDO O CAMPO ZA1_QTGRUP JAH ESTIVER SENDO POPULADO.
//		msunlock ()
	endif

	U_ML_SRArea (_aAreaAnt)
return len (_aPal)


/*
// --------------------------------------------------------------------------
// Inclusão automática (para ser chamada de outra rotina).
// Minha intencao eh migrar esta funcao para o metodo :Grava() da ClsEtiq.
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
	za1 -> za1_idZAG  = _sIdZAG 
	msunlock()
	u_log2 ('info', 'Etiqueta ' + za1 -> za1_codigo + ' gravada. Produto: ' + alltrim (za1 -> za1_prod) + ' OP: ' + alltrim (za1 -> za1_op))

	do while __lSX8
		ConfirmSX8 ()
	enddo

	U_ML_SRArea (_aAreaAnt)
Return _sNextNum
*/


// --------------------------------------------------------------------------
// Operações com grupo de etiquetas (por OP ou por NF).
User Function EtqPlltG (_sOP, _sNF, _sSerie, _sFornece, _sLoja, _sQueFazer)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aEtiq      := {}
	local _aEtiq2     := {}
	local _nEtiq      := 0
	local _oSQL       := NIL
	local _aCols      := {}
	local _bSegue     := .F.
	local _bInutil    := .F.
	local _oEtiq      := NIL
	local _dDtApont   := ctod ('')
	local _sImpr      := '  '
	local _sCmdImpT   := ''  // Comandos de impressao 'totais' (todas as etiq)
	local _sCmdImp    := ''  // Comando de impressao de cada etiqueta
	local _sArq       := ''
	local _nHdl       := ''
	static _sPortaImp := ""  // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.
	static _nModelImp := 0   // Tipo STATIC para que o programa abra as perguntas apenas na primeira execucao.

	_oSQL := ClsSQl ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ' ' AS OK, ZA1_CODIGO, ZA1_PROD, ZA1_QUANT, ZA1_IMPRES, ZA1_APONT, ZA1_DOCE, '' AS MSG"
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
	aadd (_aCols, {2, 'Etiqueta',         60, ''})
	aadd (_aCols, {3, 'Produto',          60, ''})
	aadd (_aCols, {4, 'Quant',            30, ''})
	aadd (_aCols, {5, 'Ja impressa',      30, ''})
	aadd (_aCols, {6, 'Ja apontada',      30, ''})
	aadd (_aCols, {8, 'Mensagens/erros', 250, ''})
	U_MBArray (@_aEtiq, 'Selecione as etiquetas a ' + iif (_sQueFazer == 'I', 'imprimir', iif (_sQueFazer == 'E', 'excluir', iif (_sQueFazer == 'A', 'apontar producao', '...Ah, nao sei o que voce quer fazer.'))), _aCols, 1)
	
	do case
	case _sQueFazer == "I"  // Imprimir

		// Se jah definido na execucao anterior (por isso a variavel eh STATIC), nao pergunto mais.
		if empty (_sPortaImp) .or. empty (_nModelImp)
			_sImpr = U_Get ("Selecione impressora", 'C', 2, '', 'ZX549', _sImpr, .f., '.t.')
			if ! empty (_sImpr)
				_sPortaImp = U_RetZX5 ('49', _sImpr, 'ZX5_49CAM')
				_nModelImp = val (U_RetZX5 ('49', _sImpr, 'ZX5_49LING'))
//				U_Log2 ('debug', '[' + procname () + ']porta: ' + _sPortaImp)
//				U_Log2 ('debug', '[' + procname () + ']modelo: ' + cvaltochar (_nModelImp))
			else
				u_help ("Impressao cancelada.")
				_aEtiq = {}
			endif
		endif

		// Passa todas as etiquetas selecionadas para uma nova lista, para que
		// fique mais facil, posteriormente, saber informar para a funcao que
		// gera comandos de impressao se vai ser a primeira ou a ultima.
		_aEtiq2 = {}
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, 1]
				if _aEtiq [_nEtiq, 6] == 'S'
					if U_MsgYesNo ("Etiqueta '" + _aEtiq [_nEtiq, 2] + "' ja gerou apontamento de producao. Deseja reimprimir mesmo assim?")
						aadd (_aEtiq2, _aEtiq [_nEtiq, 2])
					endif
				else
					aadd (_aEtiq2, _aEtiq [_nEtiq, 2])
				endif
			endif
		next

		// Gera string com os comandos de impressao para todas as etiquetas juntas.
		_sCmdImpT = ''
		for _nEtiq = 1 to len (_aEtiq2)
			_oEtiq := ClsEtiq ():New (_aEtiq2 [_nEtiq])
			if empty (_oEtiq:Codigo)
				u_help ("Etiqueta '" + _aEtiq2 [_nEtiq] + "' invalida." + _oEtiq:UltMsg,, .t.)
				_sCmdImpT = ''  // Aborta toda a impressao.
				exit
			else
				_sCmdImp = _oEtiq:CmdImpr (_nModelImp, empty (_sCmdImpT))
//				U_Log2 ('debug', '[' + procname () + ']Comando retornado para esta etiq: ' + _sCmdImp)
				if empty (_sCmdImp)
					u_help ("Problema na impressao da etiqueta '" + _oEtiq:Codigo + "': " + _oEtiq:UltMsg)
					_sCmdImpT = ''  // Aborta toda a impressao.
					exit
				else
					_sCmdImpT += _sCmdImp
				endif
			endif
		next
//		U_Log2 ('debug', '[' + procname () + ']Acumulado de comandos: ' + _sCmdImpT)

		// Envia para a impressora (ou arquivo, caso porta = caminho de arquivo).
		if ! empty (_sCmdImpT)
			_sArq = criatrab (NIL, .F.)
			_nHdl = fcreate (_sArq, 0)
			fwrite (_nHdl,_sCmdImpT)
			fclose (_nHdl)
			copy file (_sArq) to (_sPortaImp)
			delete file (_sArq)
			u_log2 ('debug', '[' + procname () + ']Copiei comandos para ' + _sPortaImp)
				
			// Marca etiquetas como jah impressas.
			za1 -> (dbsetorder (1))  // ZA1_FILIAL, ZA1_CODIGO, R_E_C_N_O_, D_E_L_E_T_
			for _nEtiq = 1 to len (_aEtiq2)
				if ! za1 -> (dbseek (xfilial ("ZA1") + _aEtiq2 [_nEtiq], .F.))
					u_help ("Nao encontrei mais a etiqueta '" + _aEtiq2 [_nEtiq] + "' para marcar ela como jah impressa.",, .t.)
				else
					if za1 -> za1_impres != 'S'
						reclock ("ZA1", .F.)
						za1 -> za1_impres = 'S'
						msunlock ()
					endif
				endif
			next
			if 'TXT' $ upper (_sPortaImp)
				u_help ("Arquivo de comandos de impressao gerado em " + _sPortaImp)
			endif
		endif

	case _sQueFazer == "E"  // Excluir
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
					_oEtiq := ClsEtiq ():New (_aEtiq[_nEtiq, 2])
					if _aEtiq [_nEtiq, 1] .and. _aEtiq [_nEtiq, 7] != ''
						if _oEtiq:PodeExcluir (.T.)
							U_ZA1In(_aEtiq[_nEtiq, 2], .F.)
						endif
					else
						if _aEtiq [_nEtiq, 1] .and. za1 -> (dbseek (xfilial ("ZA1") + _aEtiq [_nEtiq, 2], .F.))
							if _oEtiq:PodeExcluir (.T.)
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

	case _sQueFazer == "A"  // Apontar producao

		// Confere se as etiquetas selecionadas podem ser apontadas.
		procregua (len (_aEtiq))
		for _nEtiq = 1 to len (_aEtiq)
			incproc ("Verificando etiqueta " + _aEtiq [_nEtiq, 2])
			if _aEtiq [_nEtiq, 1]
				if _aEtiq [_nEtiq, 5] != 'S'
					_aEtiq [_nEtiq, 8] += 'Etiqueta ainda nao impressa.'
				endif
				if _aEtiq [_nEtiq, 6] == 'S'
					_aEtiq [_nEtiq, 8] += 'Etiqueta ja gerou apontamento de producao.'
				endif
				if _aEtiq [_nEtiq, 6] == 'I'
					_aEtiq [_nEtiq, 8] += 'Etiqueta inutilizada.'
				endif

				// Se chegou ateh aqui sem mensagens, instancia objeto para testes mais efetivos.
				if empty (_aEtiq [_nEtiq, 8])
					_oEtiq := ClsEtiq ():New (_aEtiq [_nEtiq, 2])
					if ! _oEtiq:PodeApont (_aEtiq [_nEtiq, 4], 0)
						_aEtiq [_nEtiq, 8] += _oEtiq:UltMsg
					endif
				endif
			endif
		next
		if ascan (_aEtiq, {|_aVal| _aVal [1] == .T. .and. ! empty (_aVal [8])}) > 0
			u_help ("Ha etiqueta(s) seleciona(s) que nao pode(m) gerar apontamento de producao. Processo nao vai ser executado.",, .t.)
//			u_F3Array (_aEtiq, "Problemas", _aCols,,, "Problemas", '', .t., 'C', nil)
//			u_help ("Apontamento cancelado.",, .t.)
		else
			_dDtApont = U_Get ('Data da producao', 'D', 8, '@D', '', dDataBase, .f., '.t.')
			if empty (_dDtApont)
				u_help ("Data nao informada. Apontamento cancelado.",, .t.)
			else
				procregua (len (_aEtiq))
				for _nEtiq = 1 to len (_aEtiq)
					incproc ("Apontando etiqueta " + _aEtiq [_nEtiq, 2])
					if _aEtiq [_nEtiq, 1] .and. empty (_aEtiq [_nEtiq, 8])
						_oEtiq := ClsEtiq ():New (_aEtiq [_nEtiq, 2])
						if ! _oEtiq:ApontaOP (dDataBase, '1')  // Aqui poderia, na proxima melhoria, perguntar o turno de producao
							_aEtiq [_nEtiq, 8] += _oEtiq:UltMsg
						else
							_aEtiq [_nEtiq, 8] += 'Apontamento OK'
						endif
					endif
				next
//				if ascan (_aEtiq, {|_aVal| _aVal [1] == .T. .and. ! empty (_aVal [8]) .and. alltrim (_aVal [8]) != 'Apontamento OK'}) > 0
//					u_help ("Houve problema no apontamento de alguma etiqueta. Verifique!",, .t.)
//					_aCols = {}
//					aadd (_aCols, {2, 'Etiqueta',         60, ''})
//					aadd (_aCols, {8, 'Mensagens/erros', 250, ''})
//					u_F3Array (_aEtiq, "Houve problema no apontamento de alguma etiqueta.", _aCols,,, "Problemas", '', .t., 'C', nil)
//				else
//					u_F3Array (_aEtiq, "Resultado", _aCols,,, "Resultado", '', .t., 'C', nil)
//					u_help ("Apontamento concluido.")
//				endif
			endif
		endif
		u_F3Array (_aEtiq, "Resultado do apontamento", _aCols,,, "Resultado do apontamento", '', .t., 'C', nil)

	otherwise
		u_help ("Sem tratamento para opcao '" + _sQueFazer + "' na funcao " + procname (),, .t.)
	endcase

	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Aborta transferencia para almox. do FullWMS
User Function EtqPllCT (_sCodigo)
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sJustif   := ""
	local _aEntr_ID  := {}
	local _sEntr_ID  := ""
	local _sStat_pro := ''
	local _oEventoCG := NIL
	local _sMsgConf  := ''

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('100',,.F.)
		U_HELP('Usuário sem acesso a este tipo de operacao!',, .t.)
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
		_oSQL:_sQuery += " select entrada_id, status_protheus"
		_oSQL:_sQuery +=   " from tb_wms_entrada"
		_oSQL:_sQuery +=  " where codfor = '" + _sCodigo + "'"
//		_oSQL:_sQuery +=    " and status_protheus != '3'"
//		_oSQL:_sQuery +=    " and status_protheus != 'C'"
		_oSQL:Log ('[' + procname () + ']')
		_aEntr_ID = _oSQL:Qry2Array ()
		if len (_aEntr_ID) == 0
			u_help ("Entrada nao existe na tabela de transferencias para o FullWMS (pode sem ter sido enviada para o FullWMS). Nao ha transferencia pendente que possa ser abortada.", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		elseif len (_aEntr_ID) == 1
			_sEntr_ID  = _aEntr_ID [1, 1]
			_sStat_pro = _aEntr_ID [1, 2]
		elseif len (_aEntr_ID) > 1
			u_help ("Encontrei MAIS DE UMA entrada na tabela de transferencias para o FullWMS referindo essa etiqueta. Suspeita de problemas na view v_wms_entrada! Query para verificacao: " + _oSQL:_sQuery, .T.)
			_lContinua = .F.
		endif
	endif
	
//	if _lContinua .and. _sStat_pro == '3'
//		u_help ("Esta etiqueta encontra-se com status_protheus=" + _sStat_pro + " na tabela de integracao tb_wms_entrada, indicando que ja foi feita transferencia para o almox. do FullWMS. Estorne, antes essa transferencia. Query para verificacao: " + _oSQL:_sQuery, .T.)
//		_lContinua = .F.
//	endif

	if _lContinua .and. _sStat_pro == 'C'
		u_help ("Esta etiqueta encontra-se com status_protheus=" + _sStat_pro + " na tabela de integracao tb_wms_entrada, indicando que a guarda Da etiqueta ja foi abortada.")
		_lContinua = .F.
	endif

	if _lContinua
		_sMsgConf := "Este procedimento altera o campo status_protheus na tabela "
		_sMsgConf += "tb_wms_entrada para 'C' de forma que o batch de integracao "
		_sMsgConf += "nao tente mais efetuar a transferencia de estoques entre "
		_sMsgConf += "os almoxarifados envolvidos no processo. Deve ser usado nos "
		_sMsgConf += "casos em que houve algum problema na integracao e os estoques "
		_sMsgConf += "ja tenham sido ajustados manualmente. Confirma?"
		if U_MsgNoYes (_sMsgConf)

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
				
				u_help ("Pendencia cancelada.")
			endif
		endif
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
