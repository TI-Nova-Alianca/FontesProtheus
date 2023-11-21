// Programa...: AdmOP
// Autor......: Robert Koch
// Data.......: 21/10/2014
// Descricao..: Tela de fechamento de ordem de producao.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Bancada de trabalho com atalhos para diversos programas relacionados a ordens de producao.
// #PalavasChave      #ordens_de_producao #administrar
// #TabelasPrincipais #SD2 #SD3
// #Modulos           #PCP

// Historico de alteracoes:
// 31/01/2015 - Robert  - Mostra tipo de OP e de produto
//                      - Componentes nao movimentados aparecem como linhas deletadas.
// 01/04/2015 - Robert  - Criada opcao de reabertura de OP (somente usuarios do grupo 009)
// 06/04/2015 - Robert  - Criado bota para verificar disponibilidade de estoque dos itens empenhados.
// 03/06/2015 - Robert  - Implementada consulta de documentos vinculados.
// 07/08/2015 - Robert  - Tratamento para campo C2_VAOPESP
//                      - Incluido campo qt.perda.
// 05/10/2015 - Robert  - Incluido botao de atalho para kardex Alianca.
//                      - Incluida consulta de movimentacao de etiquetas em 'doc vinculados'.
// 17/10/2015 - Robert  - Rotina renomeada de FechOP para AdmOP.
//                      - Datas de primeira e ultima movimentacao da OP passam a verificar tambem tabela SD1.
//                      - Criada opcao de ajuste de empenhos para qt.produzida diferente da prevista (por 'regra de 3').
//                      - Criados botoes de consulta de estoque e eventos de OP.
// 28/10/2015 - Robert  - Nao passava quantidades na inclusao de empenhos na rotina de ajuste de OPs formulacao.
// 04/11/2015 - Robert  - Criado botao de atalho para a tela de liberacao de OP para producao.
// 06/11/2015 - Robert  - Na leitura da estrutura, lia o campo B1_QB do componente e nao do pai da estrutura.
// 28/06/2016 - Robert  - Atalho para o monitor de integracao com FullWMS.
// 23/07/2016 - Robert  - Ajustes de posicionamento de tela para Protheus 12.
// 16/09/2016 - Robert  - Movimentos RE9/DE9 passam a ser considerados 'req/dev automatica' e nao mais 'manual'.
// 21/10/2016 - Robert  - Campo C2_VATIPO vai ser removido do sistema.
// 22/02/2017 - Robert  - Melhorado log eventos; desconsidera tipos AO e MO no ajuste de empenhos da formulação.
// 04/04/2017 - Robert  - Volta a considerar todos os empenhos no ajuste empenhos formulacao.
//                      - Tratamento para componentes com lote no ajuste empenhos formulacao.
// 06/04/2017 - Robert  - Tratamento para a mao de obra ficar igual `a qt. final no ajuste empenhos formulacao.
//                      - Regra processamento, aumento campo qt.final no ajuste empenhos formulacao.
// 07/04/2017 - Robert  - Incluido botao para tela Saldos por endereco.
//                      - Ajustes tela empenhos formulacao.
// 28/04/2017 - Robert  - Acrescentada consulta de etiquetas nao guardadas.
// 03/05/2017 - Robert  - Nao considerava a revisao (c2_revisao) na leitura da estrutura.
// 05/05/2017 - Robert  - Consulta de lotes e enderecos movimentados.
// 18/05/2017 - Robert  - Criada chamada para consulta de rastreabilidade de lotes.
// 07/06/2017 - Robert  - Mostra tambem obs. da OP e qt.acima do previsto apontada como 'ganho' e como 'a maior'.
// 06/04/2018 - Robert  - Nao limpava filtros ao retornar de outras telas (apont/etiq/empenhos/etc...)
// 04/05/2018 - Robert  - Liberado acesso de alteracao para grupo 000006 (contabilidade).
// 29/05/2019 - Andre   - Adicionado grupo do manutencao (000063) para ter acesso aos recursos de Administrar OP.
// 16/12/2019 - Robert  - Tratamento para variavel de controle de lacos for...next
// 24/01/2020 - Claudia - Ajustada a leitura do SX3 conforme solicitação da R25
// 20/07/2020 - Robert  - Reabertura de OP passa a validar acesso 099 e nao mais 009.
//                      - Inseridas tags para catalogacao de fontes
// 04/08/2020 - Robert  - Usuario deve pertencer ao grupo 117 do ZZU para permitir alteracoes (nao mais pelos grupos do configurador).
// 20/04/2022 - Robert  - Removidos logs desnecessarios.
// 04/05/2022 - Robert  - Desabilitado botao 'ajuste empenhos formulacao' (ninguem mais usa e nunca funcionou bem) - GLPI 11997
// 29/11/2022 - Robert  - Botao 'imprime OP' passa a ser liberado para todos os usuarios.
// 17/04/2023 - Robert  - Ordena os botoes de 'outras acoes' alfabeticamente.
//                      - Criada opcao de apontar diversas etiquetas da OP atomaticamente (util para terceirizacoes)
// 24/05/2023 - Robert  - Ajuste tratamento verificacao Alianca 24 na consulta de etiquetas nao guardadas.
//

#include "rwmake.ch"
#include "colors.ch"
#Include "totvs.ch"

// --------------------------------------------------------------------------
User Function AdmOP (_sOrdProd, _lAltera)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _lContinua  := .T.
	local _aCores     := U_AdmOPLg (.T.)
	local _aIndBrw    := {}  // Para filtragem no browse
	local _bFilBrw    := {|| Nil}  // Para filtragem no browse
	local _cCondicao  := ""  // Para filtragem no browse
	private cString   := "SC2"
	private cCadastro := "Administracao de ordens de producao"
	private aRotina   := {}
	private _sOP      := _sOrdProd

	_lAltera := iif (_lAltera == NIL, .T., _lAltera)

	// Verifica se o usuario atual pode fazer manutencoes na OP
	if _lAltera
		_lAltera = u_ZZUVL ('117', __cUserId, .f.)
	endif

	// Se nao recebeu o numero da OP como parametro, abre browse para selecao
	// do usuario, chama a propria rotina, passando o numero da OP e retorna.
	if _sOrdProd == NIL
		aadd (aRotina, {"&Pesquisar",   "AxPesqui", 0,1})
		aadd (aRotina, {"&Visualizar",  "AxVisual", 0,2})
		aadd (aRotina, {"&Administrar", "U_AdmOP (sc2->c2_num+sc2->c2_item+sc2->c2_sequen+sc2->c2_itemgrd,.T.)", 0,2})
		aadd (aRotina, {"&Legenda",     "U_AdmOPLg (.F.)", 0,2})
		_bFilBrw := {|| FilBrowse(cString,@_aIndBrw,@_cCondicao)}
		Eval(_bFilBrw)
		DbSelectArea(cString)
		mBrowse(,,,,cString,,,,,2, _aCores)
		EndFilBrw(cString,_aIndBrw)
		DbSelectArea(cString)
		DbSetOrder(1)	// Reaplica filtro no mbrowse.
		Eval(_bFilBrw)
		DbClearFilter()
		return
	endif

	if _lContinua
		processa ({|| _Tela (_lAltera)})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function AdmOPLg (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"! empty (sc2 -> c2_datrf)", 'BR_VERMELHO',                               'Encerrada'})
	aadd (_aCores, {"  empty (sc2 -> c2_datrf) .and. sc2 -> c2_quje > 0",       'BR_LARANJA', 'Iniciada'})
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
static function _Tela (_lAltera)
	local _lContinua   := .T.
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _aSize       := {}  // Para posicionamento de objetos em tela
	local _oCour24     := TFont():New("Courier New",,24,,.T.,,,,,.F.)
	local _oCour20     := TFont():New("Courier New",,20,,.T.,,,,,.F.)
	local _oCour18     := TFont():New("Courier New",,18,,.T.,,,,,.F.)
	local _oDlg        := NIL
	local _aHead1      := {}
	local _aCols1      := {}
	local _aCampos     := {}
	local i			   := 0
	private _dPrimMov  := ctod ('')  // Deixar private para ser vista em outras rotinas.
	private _dUltMov   := ctod ('')  // Deixar private para ser vista em outras rotinas.
	private _oGetD1    := NIL  // Deixar private para ser vista em outras rotinas.
	private _oTxtBrw1  := NIL
	private _oTxtBrw2  := NIL
	private _oTxtBrw3  := NIL
	private _oTxtBrw4  := NIL
	private _oTxtBrw5  := NIL
	private _oTxtBrw6  := NIL
	private _oTxtBrw7  := NIL
	private _sRevEstru := ""
	private _nQtAMaior := 0
	private _nQtGanho  := 0 
	private aGets      := {}
	private aTela      := {}
	private aRotina    := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido pela MSGetDados!!!
	private aHeader    := {}
	private aCols      := {}
	private N          := 0

	sc2 -> (dbsetorder (1))  // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD
	if ! sc2 -> (dbseek (xfilial ("SC2") + _sOP, .F.))
		u_help ("Ordem de producao '" + _sOP + "' nao cadastrada.")
		_lContinua = .F.
	endif

	if _lContinua
		_sRevEstru = sc2 -> c2_revisao

		// Cria aHeader somente com os campos necessarios
		_aCampos = {}
		_aCpoSX3 := FwSX3Util():GetAllFields('ZZZ')
		For i:=1 To Len(_aCpoSX3)
			If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .And. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL') .and. left(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'),6) == 'ZZZ_08')
				aadd (_aCampos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
			Endif
		Next i
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, _aCampos, .T.))
		aCols = {}
		_LeDados ()
	endif
	
	_aHead1 := aclone (aHeader)
	_aCols1 := aclone (aCols)

	// Define tamanho da tela
	if _lContinua
		_aSize := MsAdvSize()

		define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Fechamento de OP"

		// Textos variaveis
		//                        Linha Coluna  bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                          altura
		_oTxtBrw1 := tSay ():New (32,   5,      NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
//		_oTxtBrw2 := tSay ():New (43,   5,      NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw2 := tSay ():New (45,   5,      NIL, _oDlg, NIL, _oCour20, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw3 := tSay ():New (57,   5,      NIL, _oDlg, NIL, _oCour18, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw4 := tSay ():New (65,   5,      NIL, _oDlg, NIL, _oCour18, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw5 := tSay ():New (73,   5,      NIL, _oDlg, NIL, _oCour18, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw6 := tSay ():New (81,   5,      NIL, _oDlg, NIL, _oCour18, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
		_oTxtBrw7 := tSay ():New (89,   5,      NIL, _oDlg, NIL, _oCour18, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,           15)
	
		_oGetD1 := MsNewGetDados ():New (99, ; //85, ; //55, ;                       // Limite superior
	                                5, ;                             // Limite esquerdo
	                                _oDlg:nClientHeight / 2 - 30, ;  // Limite inferior
	                                _oDlg:nClientWidth / 2 - 10, ;   // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
                                    2, ; //GD_INSERT + GD_UPDATE, ;         // [ nStyle ]
                                    "AllwaysTrue ()", ;              // [ uLinhaOk ]
                                    "AllwaysTrue ()", ;              // [ uTudoOk ]
                                    NIL, ; //[cIniCpos]
                                    NIL,; //[ aAlter ]
                                    NIL,; // [ nFreeze ]
                                    NIL,; // [ nMax ]
                                    NIL,; // [ cFieldOk ]
                                    NIL,; // [ uSuperDel ]
                                    NIL,; // [ uDelOk ]
                                    _oDlg,; // [ oWnd ]
                                    _aHead1,; // [ ParHeader ]
                                    _aCols1) // [ aParCols ]

		// Define botoes para a barra de ferramentas
		_bBotaoOK  = {|| _oDlg:End ()}
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}
		aadd (_aBotAdic, {"", {|| U_ImpOP (_sOP, _sOP)}, "&Imprime OP"})
		if _lAltera
			aadd (_aBotAdic, {"", {|| processa ({|| U_LibOpPr (_sOP, _sOP)})},     "Liberar p/producao"})
			aadd (_aBotAdic, {"", {|| U_AdmOPAE ()},         "&Empenhos"})
			aadd (_aBotAdic, {"", {|| U_AdmOPAP ()},         "&Perdas"})
			aadd (_aBotAdic, {"", {|| U_AdmOPIM ()},         "&Req/devol"})
			aadd (_aBotAdic, {"", {|| U_AdmOPEn ()},         "&Apont/Encer.OP"})
			if U_ZZUVL ('140', __cUserId, .F.)
				aadd (_aBotAdic, {"", {|| processa ({|| U_EtqPlltG (_sOP, '', '', '', '', 'A')})}, "Apontar multiplas etiquetas"})
			endif
			aadd (_aBotAdic, {"", {|| U_AdmOPEt ()},         "E&tiquetas"})
			if u_ZZUVL ('099', __cUserId, .f.)
				aadd (_aBotAdic, {"", {|| U_AdmOPRe ()},     "Reabre OP"})
			endif
		endif
		aadd (_aBotAdic, {"", {|| U_VA_SZNC ('OP',,,,, _sOP)}, "Even&tos"})
		aadd (_aBotAdic, {"", {|| U_AdmOPEP ()},             "&Etq nao guardadas"})
		aadd (_aBotAdic, {"", {|| MaViewSB2 (sc2 -> c2_produto)}, "Estoques"})
		aadd (_aBotAdic, {"", {|| U_AdmOPDV (_sOP)},         "&Doc vinculados"})
		aadd (_aBotAdic, {"", {|| U_DispComp (_sOP, .F.)},   "Di&spon.compon"})
	// migrado para NaWeb	aadd (_aBotAdic, {"", {|| U_Kardex ()},              "&Kardex Alianca"})
		aadd (_aBotAdic, {"", {|| U_MonFullW (cFilAnt, sc2 -> c2_produto, _sOP)}, "&Integracao FullWMS"})
		aadd (_aBotAdic, {"", {|| aHeader := aclone (_oGetD1:aHeader), aCols := aclone (_oGetD1:aCols), U_aColsXLS ()}, "Exp.planilha"})
		aadd (_aBotAdic, {"", {|| MATA226 ()},              "Saldos atuais por endereco"})
		aadd (_aBotAdic, {"", {|| U_AdmOPEM (_sOP)},        "Lotes/ender.consumidos"})

		// Ordena os botoes alfabeticamente
		_aBotAdic = asort (_aBotAdic,,,{|_x, _y| upper (strtran (_x [3], '&', '')) < upper (strtran (_y [3], '&', ''))})

		activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), U_AdmOPAt (.F.))
	endif
return


// --------------------------------------------------------------------------
// Leitura dos dados para alimentar o aCols.
static function _LeDados ()
//	local _aCampos     := {}
	local _oSQL        := NIL
	local _sAliasQ     := ""
	local _aRetQry     := {}
	local _nQtBase     := 0

	procregua (10)
	incproc ()

	aCols = {}
	/*
	Tipo RE/DE
	0 Operação Manual (custo médio no estoque)
	1 Operação Automática (custo médio no estoque)
	2 Operação Automática (apropriação interna)
	3 Operação Manual (Apropriação Interna)
	4 Transferência (custo médio no estoque por local físico)
	5 Requisição para OP na NF (usa o custo do documento fiscal)
	6 Requisição Valorizada
	7 Transferência Múltipla (desmontagem de produtos)
	8 Integração com modulo Importação
	9 Movimentos para OP sem agreg. Custo
	A Movimentos de Reavaliação de Custo
	*/

	// Busca primeira e ultima datas de movimentacao da OP. 
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT MIN (D3_EMISSAO), MAX (D3_EMISSAO)"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SD3" ) + " SD3 "
	
	// Nao sei por que motivo o otimizador do SQL decidiu usar o indice 6,
	// passando de 1 para 44 segundos o tempo desta query. Vou obrigar o
	// uso do indice 1 ateh descobrir se talvez tenho estatisticas desatualizadas,
	// sei lah. Robert, 28/02/2023.
	_oSQL:_sQuery +=   " WITH (INDEX (SD30101)) "

	_oSQL:_sQuery +=  " WHERE SD3.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=    " AND SD3.D3_FILIAL   = '" + xFilial("SD3") + "' "
	_oSQL:_sQuery +=    " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=    " AND SD3.D3_OP       = '" + _sOP + "'"
	//_oSQL:PerfMon = .T.  // Habilitar somente para tratar problemas de lentidao
	//_oSQL:Log ()
	_aRetQry  = aclone (_oSQL:Qry2Array ())
	_dPrimMov = stod (_aRetQry [1, 1])
	_dUltMov  = stod (_aRetQry [1, 2])
	//
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT MIN (D1_DTDIGIT), MAX (D1_DTDIGIT)"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SD1" ) + " SD1 "
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL   = '" + xFilial("SD1") + "' "
	_oSQL:_sQuery +=    " AND SD1.D1_OP       = '" + _sOP + "'"
	//_oSQL:PerfMon = .T.  // Habilitar somente para tratar problemas de lentidao
	//_oSQL:Log ()
	_aRetQry  = aclone (_oSQL:Qry2Array ())
	_dPrimMov = iif (empty (_aRetQry [1, 1]), _dPrimMov, min (_dPrimMov, stod (_aRetQry [1, 1])))
	_dUltMov  = max (_dUltMov,  stod (_aRetQry [1, 2]))

	// Busca os movimentos do SD3 para o aCols. 
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT B1_DESC, B1_UM, MOVTOS.D3_COD, "
	_oSQL:_sQuery +=        " SUM (CASE WHEN MOVTOS.ORIGEM = 'REQAUT' THEN MOVTOS.D3_QUANT ELSE 0 END +"
	_oSQL:_sQuery +=             " CASE WHEN MOVTOS.ORIGEM = 'DEVAUT' THEN MOVTOS.D3_QUANT * -1 ELSE 0 END"
	_oSQL:_sQuery +=             " ) AS REQAUT,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN MOVTOS.ORIGEM = 'REQMAN' THEN MOVTOS.D3_QUANT ELSE 0 END +"
	_oSQL:_sQuery +=             " CASE WHEN MOVTOS.ORIGEM = 'DEVMAN' THEN MOVTOS.D3_QUANT * -1 ELSE 0 END"
	_oSQL:_sQuery +=             ") AS REQMAN,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN MOVTOS.ORIGEM = 'PERDA' THEN MOVTOS.D3_QUANT ELSE 0 END"
	_oSQL:_sQuery +=             ") AS PERDA"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SB1") + " SB1, "
	_oSQL:_sQuery +=        " (SELECT D3_COD, D3_QUANT," 
	_oSQL:_sQuery +=                " CASE WHEN SD3.D3_VAPEROP = 'S'
	_oSQL:_sQuery +=                " THEN 'PERDA' ELSE "
	_oSQL:_sQuery +=                   " CASE WHEN D3_CF IN ('RE1', 'RE2', 'RE5', 'RE9') THEN 'REQAUT' ELSE "
	_oSQL:_sQuery +=                      " CASE WHEN D3_CF IN ('DE1', 'DE2', 'DE5', 'DE9') THEN 'DEVAUT' ELSE "
	_oSQL:_sQuery +=                         " CASE WHEN D3_CF IN ('RE0', 'RE3', 'RE6') THEN 'REQMAN' ELSE "
	_oSQL:_sQuery +=                            " CASE WHEN D3_CF IN ('DE0', 'DE3', 'DE6') THEN 'DEVMAN' ELSE "
	_oSQL:_sQuery +=                               " '?'"
	_oSQL:_sQuery +=                            " END"
	_oSQL:_sQuery +=                         " END"
	_oSQL:_sQuery +=                      " END"
	_oSQL:_sQuery +=                   " END"
	_oSQL:_sQuery +=                " END AS ORIGEM"
	_oSQL:_sQuery +=           " FROM " + RetSqlName( "SD3" ) + " SD3"
	_oSQL:_sQuery +=          " WHERE SD3.D_E_L_E_T_ != '*' "
	_oSQL:_sQuery +=            " AND SD3.D3_FILIAL   = '" + xFilial("SD3") + "' "
	_oSQL:_sQuery +=            " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=            " AND SD3.D3_OP       = '" + _sOP + "'"
	_oSQL:_sQuery +=            " AND (SD3.D3_CF      LIKE 'RE%' OR SD3.D3_CF LIKE 'DE%')"
	_oSQL:_sQuery +=          " ) AS MOVTOS"
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ != '*' "
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL   = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery +=    " AND SB1.B1_COD      = MOVTOS.D3_COD"
	_oSQL:_sQuery +=  " GROUP BY MOVTOS.D3_COD, B1_DESC, B1_UM"
	//_oSQL:PerfMon = .T.  // Habilitar somente para tratar problemas de lentidao
	//_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	_aLinVazia := aclone (U_LinVazia (aHeader))
	(_sAliasQ) -> (dbgotop ())
	do while !(_sAliasQ) -> (Eof())
		aadd (aCols, aclone (_aLinVazia))
		N = len (aCols)
		GDFieldPut ("ZZZ_08COD",  (_sAliasQ) -> d3_cod)
		GDFieldPut ("ZZZ_08DESC", (_sAliasQ) -> b1_desc)
		GDFieldPut ("ZZZ_08UM",   (_sAliasQ) -> b1_um)
		GDFieldPut ("ZZZ_08RQA",  (_sAliasQ) -> reqaut)
		GDFieldPut ("ZZZ_08RQM",  (_sAliasQ) -> reqman)
		GDFieldPut ("ZZZ_08PER",  (_sAliasQ) -> perda)
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SC2")

	// Busca quantidades apontadas acima do previsto. 
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM (D3_QTGANHO), SUM (D3_QTMAIOR)"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SD3" ) + " SD3"
	_oSQL:_sQuery +=  " WHERE SD3.D_E_L_E_T_ != '*' "
	_oSQL:_sQuery +=    " AND SD3.D3_FILIAL   = '" + xFilial("SD3") + "' "
	_oSQL:_sQuery +=    " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=    " AND SD3.D3_OP       = '" + _sOP + "'"
	_oSQL:_sQuery +=    " AND SD3.D3_CF      LIKE 'PR%'"
	//_oSQL:PerfMon = .T.  // Habilitar somente para tratar problemas de lentidao
	//_oSQL:Log ()
	_aRetQry := aclone (_oSQL:Qry2Array (.F., .F.))
	_nQtGanho = _aRetQry [1, 1]
	_nQtMaior = _aRetQry [1, 2]

	// Busca quantidade da estrutura.
	_nQtBase = fBuscaCpo ("SB1", 1, xfilial ("SB1") + sc2 -> c2_produto, "B1_QB")
	_nQtBase = iif (_nQtBase == 0, 1, _nQtBase)
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT G1_COMP, B1_DESC, B1_UM, "
	_oSQL:_sQuery +=        " SUM (CASE SG1.G1_FIXVAR"
	_oSQL:_sQuery +=                  " WHEN 'V' THEN SG1.G1_QUANT / " + cvaltochar (_nQtBase) + " + SG1.G1_QUANT * SG1.G1_PERDA / 100"
	_oSQL:_sQuery +=                  " ELSE SG1.G1_QUANT + SG1.G1_QUANT * SG1.G1_PERDA / 100"
	_oSQL:_sQuery +=             " END) * " + cvaltochar (sc2 -> c2_quje + sc2 -> c2_perda) + " AS QT_ESTRU"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SG1" ) + " SG1,"
	_oSQL:_sQuery +=              RetSqlName( "SB1" ) + " SB1 "
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL   = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery +=    " AND SB1.B1_COD      = SG1.G1_COMP"
	_oSQL:_sQuery +=    " AND SB1.B1_FANTASM != 'S'"
	_oSQL:_sQuery +=    " AND SG1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery +=    " AND SG1.G1_FILIAL   = '" + xFilial("SG1") + "' "
	_oSQL:_sQuery +=    " AND SG1.G1_COD      = '" + sc2 -> c2_produto + "'"
	_oSQL:_sQuery +=    " AND SG1.G1_INI     <= '" + dtos (sc2 -> c2_datpri) + "' AND SG1.G1_FIM >= '" + dtos (sc2 -> c2_datpri) + "'"
	_oSQL:_sQuery +=    " AND SG1.G1_REVINI  <= '" + _sRevEstru + "' AND SG1.G1_REVFIM >= '" + _sRevEstru + "'"
	_oSQL:_sQuery +=  " GROUP BY G1_COMP, B1_DESC, B1_UM"
	//_oSQL:PerfMon = .T.  // Habilitar somente para tratar problemas de lentidao
	//_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	(_sAliasQ) -> (dbgotop ())
	_aLinVazia := aclone (U_LinVazia (aHeader))
	Do While !(_sAliasQ) -> (Eof())
		N = ascan (aCols, {|_aVal| _aVal [GDFieldPos ("ZZZ_08COD")] == (_sAliasQ) -> g1_comp})
		if N == 0
			aadd (aCols, aclone (_aLinVazia))
			N = len (aCols)
			GDFieldPut ("ZZZ_08COD", (_sAliasQ) -> g1_comp)
			GDFieldPut ("ZZZ_08DESC", (_sAliasQ) -> b1_desc)
			GDFieldPut ("ZZZ_08UM", (_sAliasQ) -> b1_um)
		endif
		GDFieldPut ("ZZZ_08QEST", (_sAliasQ) -> qt_estru)
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SC2")

	// Ordena aCols pela coluna do codigo do componente.
	aCols = asort (aCols,,, {|_x, _y| _x [GDFieldPos ("ZZZ_08COD")] < _y [GDFieldPos ("ZZZ_08COD")]})
return


// --------------------------------------------------------------------------
// Atualiza toda a tela. Chamada principalmente por gatilhos.
user function AdmOPAt (_lLeDados)
	local _xDado     := &(readvar ()) // Para retorno dos gatilhos.
	local _nLinGD    := 0
	local _sTipoOP   := ''

	aHeader := aclone (_oGetD1:aHeader)
	aCols   := aclone (_oGetD1:aCols)

	if _lLeDados
		processa ({|| _LeDados ()})
	endif

	for _nLinGD = 1 to len (aCols)
		//N := _n
		GDFieldPut ("ZZZ_08TRQ",  GDFieldGet ("ZZZ_08RQA", _nLinGD) + GDFieldGet ("ZZZ_08RQM", _nLinGD) + GDFieldGet ("ZZZ_08PER", _nLinGD), _nLinGD) 
		GDFieldPut ("ZZZ_08VARQ", GDFieldGet ("ZZZ_08TRQ", _nLinGD) - GDFieldGet ("ZZZ_08QEST", _nLinGD), _nLinGD) 
		if GDFieldGet ("ZZZ_08QEST", _nLinGD) != 0
			GDFieldPut ("ZZZ_08VARP", GDFieldGet ("ZZZ_08TRQ", _nLinGD) / GDFieldGet ("ZZZ_08QEST", _nLinGD) - 1, _nLinGD)
		else
			GDFieldPut ("ZZZ_08VARP", 0, _nLinGD)
		endif

		// Linhas sem quantidade movimentada ficam como deletadas.
		if GDFieldGet ("ZZZ_08TRQ", _nLinGD) == 0
			aCols [_nLinGD, len (aCols [_nLinGD])] = .T.
		endif
	next

	_sTipoOP = ''
	if ! sc2 -> c2_vaOpEsp $ 'N '
		_sTipoOP = alltrim (X3Combo ("C2_VAOPESP", sc2 -> c2_vaOpEsp))
	endif

	_oGetD1:aHeader := aclone (aHeader)
	_oGetD1:aCols   := aclone (aCols)

	// Atualiza browse de totais na tela
	_oGetD1:oBrowse:Refresh()
	_oGetD1:Show ()

	sb1 -> (dbsetorder (1))
	if ! sb1 -> (dbseek (xfilial ("SB1") + sc2 -> c2_produto, .F.))
		_oTxtBrw1:SetText ("OP: " + substr (_sOP, 1, 6) + '.' + substr (_sOP, 7, 2) + '.' + substr (_sOP, 9) + "    Produto: " + alltrim (sc2 -> c2_produto) + ' *** Nao encontrado no cadastro!')
	else
		_oTxtBrw1:SetText ("OP: " + substr (_sOP, 1, 6) + '.' + substr (_sOP, 7, 2) + '.' + substr (_sOP, 9) + "    Produto: " + alltrim (sc2 -> c2_produto) + ' - ' + sb1 -> b1_desc)
		_oTxtBrw2:SetText ('Rev.estrutura.: ' + _sRevEstru + '  ' + iif (! empty (_sTipoOP), 'Tipo OP: ' + _sTipoOP, ''))
		_oTxtBrw3:SetText ('Qt.prevista...: ' + transform (sc2 -> c2_quant, "@E 999,999,999.99") + ' ' + sb1 -> b1_um + ' (' + transform (sc2 -> c2_quant * sb1 -> b1_litros, "@E 9999999") + ' litros)   Emissao.....: ' + dtoc (sc2 -> c2_emissao) + '   Prim.moviment.: ' + dtoc (_dPrimMov))
		_oTxtBrw4:SetText ('Qt.produzida..: ' + transform (sc2 -> c2_quje,  "@E 999,999,999.99") + ' ' + sb1 -> b1_um + ' (' + transform (sc2 -> c2_quje  * sb1 -> b1_litros, "@E 9999999") + ' litros)   Encerramento: ' + dtoc (sc2 -> c2_datrf)   + '   Ult.moviment..: ' + dtoc (_dUltMov))
		_oTxtBrw5:SetText ('Qt.perda......: ' + transform (sc2 -> c2_perda, "@E 999,999,999.99") + ' ' + sb1 -> b1_um + ' (' + transform (sc2 -> c2_perda * sb1 -> b1_litros, "@E 9999999") + ' litros)   Tipo produto: ' + sb1 -> b1_tipo)
		_oTxtBrw6:SetText ('Qt.prod. maior: ' + transform (_nQtAMaior,      "@E 999,999,999.99") + ' ' + sb1 -> b1_um + ' (' + transform (_nQtAMaior      * sb1 -> b1_litros, "@E 9999999") + ' litros)   Obs. da OP..: ' + alltrim (sc2 -> c2_obs)) 
		_oTxtBrw7:SetText ('Qt.ganho prod.: ' + transform (_nQtGanho,       "@E 999,999,999.99") + ' ' + sb1 -> b1_um + ' (' + transform (_nQtGanho       * sb1 -> b1_litros, "@E 9999999") + ' litros)')
	endif
return _xDado


// --------------------------------------------------------------------------
// Ajuste de empenhos.
user function AdmOPAE ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt := U_SalvaAmb ()
 	dbselectarea ("SD4")
 	set filter to d4_filial = cFilAnt .and. d4_op = _sOP
 	aHeader := NIL
 	aCols := NIL
 	N := 1
 	aRotina := NIL
	MATA381 ()
 	dbselectarea ("SD4")
 	set filter to
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Etiquetas com problemas.
user function AdmOPEP ()
	local _oVerif   := NIL
//	local _oEtqNG   := NIL

	_oVerif := ClsVerif():New (24)
	_oVerif:SetParam ('01', _sOP)
	_oVerif:SetParam ('02', _sOP)
	_oVerif:SetParam ('03', '')
	_oVerif:SetParam ('04', 'zzzzzzzzzzzzzzz')
	_oVerif:Executa (.f.)
	if len (_oVerif:Result) > 0

//		// A primeira linha contem nomes de colunas, mas quero usar a funcao F3Array, que nao vai gostar disso.
//		_oEtqNG := ClsAUtil ():New (_oVerif:Result)
//		_oEtqNG:Del (1)

		_sMsgSup = "As seguintes etiquetas geraram apontamentos para esta OP, mas ainda nao foram guardadas"
		U_F3Array (_oVerif:Result, "Etiquetas nao guardadas", _oVerif:aColsF3, , , _sMsgSup, '', .T., 'C')
	else
		u_help ("Nao foram encontradas etiquetas pendentes para esta OP")
	endif
return


// --------------------------------------------------------------------------
// Etiquetas pallets.
user function AdmOPEt ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt := U_SalvaAmb ()
 	dbselectarea ("ZA1")
	set filter to za1_filial = cFilAnt .and. za1_op = _sOP
	U_VA_ETQPLL ()
 	dbselectarea ("ZA1")
 	set filter to
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Inclui movimento na OP.
user function AdmOPIM ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt := U_SalvaAmb ()

 	dbselectarea ("SD3")
 	set filter to d3_filial = cFilAnt .and. d3_op = _sOP .and. ! d3_tm $ '001/004/010'
 	aHeader := NIL
 	aCols := NIL
 	N := 1
 	aRotina := NIL
	MATA241 ()
 	dbselectarea ("SD3")
 	set filter to
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Inclui apontamento de perda na OP.
user function AdmOPAP ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt := U_SalvaAmb ()

 	aHeader := NIL
 	aCols := NIL
 	N := 1
 	aRotina := NIL
 	dbselectarea ("SBC")
 	set filter to bc_filial = cFilAnt .and. bc_op = _sOP
	MATA685 ()
 	dbselectarea ("SBC")
 	set filter to
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Apontamentos/ encerramento.
user function AdmOPEn ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt := U_SalvaAmb ()

 	aHeader := NIL
 	aCols := NIL
 	N := 1
 	aRotina := NIL
 	dbselectarea ("SD3")
 	set filter to d3_filial = cFilAnt .and. d3_op = _sOP .and. d3_tm $ '001/004/010'
	MATA250 ()
 	dbselectarea ("SD3")
 	set filter to
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Reabre OP.
user function AdmOPRe ()
	local _aAreaAnt := U_ML_SRArea ()
 	local _aAmbAnt  := U_SalvaAmb ()
 	local _oEvento  := NIL

	sc2 -> (dbsetorder (1))
	if sc2 -> (dbseek (xfilial ("SC2") + _sOP, .F.))
		if ! empty (sc2 -> c2_datrf)
			if sc2 -> c2_datrf < GetMv ("MV_ULMES")
				u_help ("Periodo ja fechado no estoque. OP nao pode ser reaberta.")
			else
			 	if U_msgnoyes ("Confirma reabertura desta OP?")
			 		reclock ("SC2", .F.)
			 		sc2 -> c2_datrf = ctod ('')
			 		msunlock ()

					_oEvento := ClsEvent():new ()
					_oEvento:CodEven = "SC2001"
					_oEvento:OP      = _sOP
					_oEvento:Texto   = "Reabertura OP"
					_oEvento:Grava ()
		 		endif
		 	endif
		else
			u_help ("OP nao encontra-se encerrada.")
		endif
	else
		u_help ("OP nao encontrada!")
 	endif
 	U_SalvaAmb (_aAmbAnt)
 	U_ML_SRArea (_aAreaAnt)
	U_AdmOPAt (.T.)
return


// --------------------------------------------------------------------------
// Consulta documentos vinculados.
user function AdmOPDV (_sOP)
 	local _aAmbAnt := U_SalvaAmb ()
 	local _oSQL    := NIL
 	local _nOpcao  := 0

  	_nOpcao = aviso ("Selecione o que deseja consultar", ;
  	                 "NF - Notas de beneficiamento relacionadas a esta OP" + chr (13) + chr (10) + ;
	                 "Etiquetas - Rastreia movto.estoque etiquetas da OP", ;
	                 {"NF", "Etiquetas"}, 3, "Selecione consulta")
	if _nOpcao == 1
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT 'NF ENTRADA' AS ORIGEM_MOVIMENTO, dbo.VA_DTOC (D1_DTDIGIT) AS DATA_MOVTO, D1_DOC AS NOTA_FISCAL, D1_SERIE AS SERIE, D1_FORNECE AS FORNECEDOR, D1_LOJA AS LOJA, A2_NOME AS NOME"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SD1") + " SD1"
		_oSQL:_sQuery +=   " LEFT JOIN " + RetSqlName( "SA2" ) + " SA2 "
		_oSQL:_sQuery +=         " ON (SA2.D_E_L_E_T_ <> '*'"
		_oSQL:_sQuery +=         " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=         " AND SA2.A2_COD      = SD1.D1_FORNECE"
		_oSQL:_sQuery +=         " AND SA2.A2_LOJA     = SD1.D1_LOJA"
		_oSQL:_sQuery +=         ")"
		_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SD1.D1_FILIAL   = '" + xFilial ("SD1") + "'"
		_oSQL:_sQuery +=    " AND SD1.D1_OP       = '" + _sOP + "'"
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SD3.D3_VAETIQ AS ETIQUETA, SD3.D3_EMISSAO AS DATA_MOVTO, SD3.D3_QUANT AS QUANTIDADE, D3_PERDA AS QT_PERDA, SD3.D3_LOCAL AS ALMOX, D3_CF AS MOVIMENTO, SD3.D3_VAMOTIV AS MOTIVO, SD3.D3_USUARIO AS USUARIO"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SD3") + " SD3 "
		_oSQL:_sQuery +=  " WHERE SD3.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SD3.D3_FILIAL   = '" + xFilial ("SD3") + "'"
		_oSQL:_sQuery +=    " AND SD3.D3_ESTORNO != 'S'"
		_oSQL:_sQuery +=    " AND SD3.D3_VAETIQ  IN (SELECT DISTINCT ZA1_CODIGO
		_oSQL:_sQuery +=                             " FROM " + RetSqlName ("ZA1") + " ZA1 "
		_oSQL:_sQuery +=                            " WHERE ZA1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                              " AND ZA1.ZA1_FILIAL  = SD3.D3_FILIAL"
		_oSQL:_sQuery +=                              " AND ZA1.ZA1_OP      = '" + _sOP + "')"
		_oSQL:_sQuery +=  " ORDER BY SD3.D3_VAETIQ, SD3.D3_EMISSAO, SD3.D3_DOC"
	endif
	CursorWait ()
	_oSQL:F3Array ()
	CursorArrow ()
 	U_SalvaAmb (_aAmbAnt)
return


// --------------------------------------------------------------------------
// Consulta enderecos (de estoque) movimentados pela OP.
user function AdmOPEM (_sOP)
 	local _aAmbAnt := U_SalvaAmb ()
 	local _oSQL    := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DB_PRODUTO AS PRODUTO, RTRIM (B1_DESC) AS DESCRICAO, DB_LOTECTL AS LOTE, DB_LOCAL AS ALMOX,"
	_oSQL:_sQuery +=        " DB_LOCALIZ AS ENDERECO, DB_QUANT AS QUANTIDADE, B1_UM AS UN_MED, dbo.VA_DTOC (DB_DATA) AS DATA, DB_HRINI AS HORA"
 	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SDB") + " SDB, "
 	_oSQL:_sQuery +=              RetSqlName ("SB1") + " SB1 "
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = SDB.DB_PRODUTO"
	_oSQL:_sQuery +=    " AND SDB.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SDB.DB_FILIAL  = '" + xfilial ("SDB") + "'"
	_oSQL:_sQuery +=    " AND SDB.DB_ORIGEM  = 'SC2'"
	_oSQL:_sQuery +=    " AND SDB.DB_ATUEST  = 'S'"
	_oSQL:_sQuery +=    " AND SDB.DB_DOC IN (SELECT D3_DOC"
	_oSQL:_sQuery +=                         " FROM " + RetSqlName ("SD3") + " SD3 "
	_oSQL:_sQuery +=                        " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                          " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=                          " AND SD3.D3_OP      = '" + _sOP + "'"
	_oSQL:_sQuery +=                          " AND SD3.D3_ESTORNO != 'S')"
	_oSQL:_sQuery +=  " ORDER BY DB_PRODUTO, DB_LOTECTL, DB_LOCALIZ"
	CursorWait ()
	_oSQL:F3Array ()
	CursorArrow ()
 	U_SalvaAmb (_aAmbAnt)
return


// --------------------------------------------------------------------------
// Usa validacao do campo da q.final para ajustar empenho da mao de obra.
user function ADMOPVQF ()
	local _Nbkp := N
	local _nLinha :=0
	local _oGetD := CallMod2Obj()
	for _nLinha = 1 to len (aCols)
		N := _nLinha
		if left (GDFieldGet ("ZZZ_10COD"), 3) == 'MMM'
			GDFieldPut ("ZZZ_10QTD", _nQtFinal)  // Mao de obra deve ficar sempre igual `a litragem produzida.
		endif
	next
	N = 1
	_oGetD:oBrowse:Refresh ()
	N = _Nbkp
return .T.


// --------------------------------------------------------------------------
// Valida 'Linha OK' da tela de manutencao de empenhos.
user function AdmOPE3L ()
	local _lRet := .T.
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZZZ_10COD"}, 4)
	endif
return _lRet


// --------------------------------------------------------------------------
// Valida 'Tudo OK' da tela de manutencao de empenhos.
user function AdmOPE3T ()
	local _lRet := .T.
	if _lRet .and. _nQtFinal <= 0
		u_help ("Quantidade final da OP (seja produzida ou perdida) deve ser informada.")
		_lRet = .F.
	endif
return _lRet
