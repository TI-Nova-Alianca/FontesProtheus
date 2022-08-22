// Programa...: SZI
// Autor......: Robert Koch
// Data.......: 25/02/2011
// Descricao..: Tela de manutencao de conta corrente de associados.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #associados #conta_corrente_associados
// #TabelasPrincipais #SZI
// #Modulos           #COOP

// Historico de alteracoes:
// 28/03/2011 - Robert - Grava sequencial em funcao separada, com bloqueio via semaforo.
// 30/03/2011 - Robert - Tratamento para ZI_TM passa a ser lido do SX5_10Gera.
// 29/04/2011 - Robert - Gravacao do PA deixava E5_TIPODOC como 'BA'.
// 01/07/2011 - Robert - Tratamento para campo memo (ZI_OBS).
//                     - tratamento para tipos de movimento 08 e 09.
//                     - Campo ZX510GERA dividido em ZX510GERI (Inclusao) e ZX510GERB (baixa).
//                     - Implementado controle de quota capital.
// 20/07/2011 - Robert - Funcao GeraSE2 passada para para 'user function'.
// 10/08/2011 - Robert - Filtragem inicial de movimentos normais / capital.
// 02/09/2011 - Robert - Passa a usar metodos Grava, PodeIncl, GeraAtrib da classe ClsCtaCorr.
// 20/01/2012 - Robert - Definicao de contas para contabilizacao de resgates de quota capital.
// 06/03/2012 - Robert - Quando baixa normal, nao manda conta a debito (pega depois do banco).
// 27/04/2012 - Robert - Incluida chamada do VA_PSA em 'outras consultas'.
// 04/05/2012 - Robert - Incluida chamada do fc050con em 'outras consultas'.
// 06/09/2012 - Robert - Incluida chamada da consulta de saldo atual em 'outras consultas'.
// 11/10/2012 - Robert - Implementado recalculo de saldo do lancamento atual.
//                     - Implementada chamada de metodo de transferencia de saldo para outra filial.
// 20/11/2012 - Robert - Criado tratamento para outros creditos com entrada de valor (gera SE5).
// 03/03/2016 - Robert - Criada opcao de recalculo geral de saldos do associado.
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 01/04/2016 - Robert - Desabilitada chamada do prog. CADASSOC() por foi removido do projeto.
// 12/09/2016 - Robert - Recalcula saldo lcto apos canc.baixa man. por que o P.E. generico FINA080 nao eh executado pela rot. de cancelamento.
// 26/09/2016 - Robert - Executa o U_FINA080() apos baixa manual sontabilizando off-line (o P.E. nao eh executado nesse caso).
// 03/01/2016 - Robert - Metodo AtuSaldo() da conta corrente nao recebe mais o saldo como parametro.
// 06/02/2017 - Robert - Transferencias de saldos recebidas de outras filiais nao sao consideradas como 'calculado nesta filial'.
// 05/09/2017 - Robert - Bloqueio emergencial para nao baixar movto 19
// 28/11/2017 - Robert - Validacoes de existencia de corr.mon. e inclusao de tipos 08 e 09 passadas para a classe ClsCtaCorr.
// 28/03/2018 - Catia  - Criada opção de fatura
// 08/04/2019 - Catia  - include TbiConn.ch 
// 21/01/2020 - Robert - Reabilitada consulta de cota capital.
// 12/03/2020 - Robert - Ajustados parametros de chamada do relatorio IRAssoc (dados para fins de IR) - GLPI 7614.
//                     - Comentariadas declaracoes de variaveis nao usadas; removidas algumas linhas jah comentariadas.
// 27/03/2020 - Robert - Permite compensar titulos transferidos (em bordero) para atender adto.safra enviados via CNAB.
// 01/04/2020 - Robert - Ajustados parametros de chamada do IRASSOC.PRW
// 22/06/2020 - Robert - Criado parametro de filtro adicional para selecao de titulos a compensar.
// 25/06/2020 - Robert - Para localizar o titulo no SE2 (baixar/canc.baixa), usa pref+num+parcela e nao nais o E2_VACHVEX.
// 17/07/2020 - Robert - Inseridas tags para catalogacao de fontes
//                     - Criada funcionalidade de alterar a data de vencimento (no finalceiro) do titulo correspondente (GLPI 8165).
// 21/07/2020 - Robert - Filtro do browse inicial migrado para TOP (permite ao usuario criar filtros adicionais dentro da tela).
// 23/07/2020 - Robert - Criada funcionalidade de cancelamento de fatura a pagar (GLPI 8221).
// 29/07/2020 - Robert - Criado atalho para relatorio de fechamento de safra.
// 13/08/2020 - Cláudia - Ajustado o valor das consultas de faturas. GLPI: 8255
// 16/10/2020 - Robert  - Baixa de titulos: Busca contas contabeis parra TM=29 iguais as do TM=01.
// 23/10/2020 - Claudia - Ajuste de visualização do cadastro de fornecedores. GLPI: 8683
// 11/01/2021 - Robert  - Melhorada msg. na rotina de transferencia de saldo para outra filial.
// 25/03/2021 - Robert  - Criada funcao _Pergunte para ler parametros de rotinas automaticas (GLPI 9697)
// 27/07/2021 - Robert  - Valida data base antes de chamar GeraSE2().
// 14/09/2021 - Robert  - Tratamentos para campo ZI_VCTOFOR (GLPI 10803).
// 16/09/2021 - Robert  - Criado submenu para chamar parametros de rotinas do financeiro (GLPI 10502).
//                      - Eliminado parametro 'contabiliza online' (passa a ler de cada rotina financeira)
// 27/02/2022 - Robert  - Adicionada coluna HIST na consulta de titulos agrupados numa fatura (GLPI 11678)
// 05/04/2022 - Robert  - Verifica valor do SE2 antes do recalculo manual de saldos.
// 22/08/2022 - Robert  - Consulta de movtos.vinculados passa a usar o metodo :RegRelac().
//

#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------------------------------
User Function szi()
	local _aCores      := U_SZILG (.T.)
	local _aRotSald    := {}
	local _aRotParF    := {}
	local _aRotAdic    := {}
	local _oCtaCorr    := ClsCtaCorr():New ()
	local _sFilTop     := ''
	private cString    := "SZI"
	private cCadastro  := "Conta corrente associados"
	private cPerg      := 'U_SZI'
	private cPerg2     := 'U_SZI2'
	private aRotina    := {}
	private _sChave    := "'SZI'+szi->zi_assoc+szi->zi_lojasso+szi->zi_seq"
	private _SZI_Bco   := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _SZI_Age   := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _SZI_Cta   := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _SZI_Cred  := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _SZI_Deb   := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _SZI_Hist  := NIL  // Deixar private para ser vista por inicializadores padrao de campos / contabilizacoes.
	private _aTipoTit  := {"NDF", "PA", "DP"}
	private _sTMCorrD  := _oCtaCorr:TMCorrMonD
	private _sTMCorrC  := _oCtaCorr:TMCorrMonC
//	private _lCtOnLine := .F.
	private _sFilZI340 := ''  // Variavel private para ser vista pelo P.E. F340FCPTOP

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Submenu de rotinas especificas para saldos.
	aadd (_aRotSald, {"Transf.saldo p/outra filial", "U_SZIT()",0,2})
	aadd (_aRotSald, {"Recalcular saldo deste lcto", "U_SZIRS(1)",0,2})
	if U_ZZUVL ('051', __cUserID, .F.)
		aadd (_aRotSald, {"Recalc.saldos acum.(anuais) associado", "U_SZIRS(2)",0,2})
		aadd (_aRotSald, {"Recalc.saldo diversos lctos.do associado", "U_SZIRS(3)",0,2})
	endif

	// Submenu de rotinas especificas para atualizar parametros (principalmente 'contabiliza online') de telas padrao que vao ser chamadas via rotinas automatica.
	aadd (_aRotParF, {"Incl/excl.ctas.pagar", 'Pergunte ("FIN050", .t.)', 0,4})
	aadd (_aRotParF, {"Baixas pagar manuais", 'Pergunte ("FIN080", .t.)', 0,4})
	aadd (_aRotParF, {"Baixas pagar autom.",  'Pergunte ("FIN090", .t.)', 0,4})
	aadd (_aRotParF, {"Compensacao c.pagar",  'Pergunte ("AFI340", .t.)', 0,4})
	aadd (_aRotParF, {"Movimento bancario",   'Pergunte ("AFI100", .t.)', 0,4})

	// Submenu de rotinas adicionais
	aadd (_aRotAdic, {"Extrato conta corrente",   "U_SZIR(1)",0,2})
	aadd (_aRotAdic, {"Extr.producao associado",  "U_SZIR(2)",0,2})
	aadd (_aRotAdic, {"Registros relacionados",   "U_SZIR(3)",0,2})
	aadd (_aRotAdic, {"Posicao fornecedor",       "U_SZIR(4)",0,2})
	aadd (_aRotAdic, {"Cadastro fornecedor",      "U_SZIR(5)",0,2})
	aadd (_aRotAdic, {"Capital social",           "U_SZIR(6)",0,2})
//	aadd (_aRotAdic, {"Ficha cadastro associado", "U_SZIR(7)",0,2})
	aadd (_aRotAdic, {"Dados para fins de IR",    "U_SZIR(8)",0,2})
	aadd (_aRotAdic, {"Cons. titulos CP",         "U_SZIR(9)",0,2})
	aadd (_aRotAdic, {"Saldo na data base",       "U_SZIR(10)",0,2})
	aadd (_aRotAdic, {"Rel.saldos c.corr.",       "U_SZIR(11)",0,2})
	aadd (_aRotAdic, {"Consulta Fatura",          "U_SZIR(12)",0,2})
	aadd (_aRotAdic, {"Rel.fechamento safra",     "U_SZIR(13)",0,2})
	if alltrim (upper (cUserName)) $ "ROBERT.KOCH"
		aadd (_aRotAdic, {"Robert-teste compensacoes", "U_SZIR(98)",0,2})
		aadd (_aRotAdic, {"Robert-gera SE2",           "U_SZIR(97)",0,2})
	endif

	// Menu principal
	aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0,1})
	aadd (aRotina, {"&Visualizar"       , "AxVisual", 0,1})
	aadd (aRotina, {"&Incluir"          , "U_SZII",   0,3})
	aadd (aRotina, {"&Alterar"          , "U_SZIA",   0,4})
	aadd (aRotina, {"&Excluir"          , "U_SZIE",   0,4})
	aadd (aRotina, {"&Baixar"           , "U_SZIB",   0,4})
	aadd (aRotina, {"&Canc.baixa"       , "U_SZIC",   0,4})
	aadd (aRotina, {"Al&terar dt.vencto", "U_SZIADV", 0,4})
	aadd (aRotina, {"Cancelar &fatura"  , "U_SZICF (.F.)",  0,4})
	aadd (aRotina, {"&Saldos"           , _aRotSald,  0,4})
	aadd (aRotina, {"Parametros financ.", _aRotParF,  0,4})
	aadd (aRotina, {"&Outras consultas" , _aRotAdic,  0,4})
	aadd (aRotina, {"&Legenda"          , "U_SZILG (.F.)", 0,5})

	_ValidPerg ()
	if ! pergunte (cPerg, .T.)
		return
	endif

	//_lCtOnLine = (mv_par02 == 1)
	_sFilZI340 = alltrim (mv_par03)  // Variavel private para ser vista pelo P.E. F340FCPTOP

	// Monta filtro conforme parametrizacao do usuario.
	if mv_par01 == 1  // Movimentos normais
		_sFilTop = ' ZI_TM NOT IN ' + FormatIn (_oCtaCorr:TMCapital, '/')
	elseif mv_par01 == 2  // Movimentos de capital social
		_sFilTop = ' ZI_TM IN ' + FormatIn (_oCtaCorr:TMCapital, '/')
	endif
	mBrowse(,,,,cString,,,,,2, _aCores,,,,,,,,_sFilTop)
return
//
// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function SZILG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"zi_saldo==0",        'BR_VERMELHO', 'Baixado'})
	aadd (_aCores, {"zi_saldo==zi_valor", 'BR_VERDE',    'Aberto'})
	aadd (_aCores, {"zi_saldo< zi_valor", 'BR_AMARELO',  'Baix.parcial'})
	
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
//
// --------------------------------------------------------------------------
// Chama execucao de relatorios (devem estar preparados para isto).
User Function SZIR (_nQual)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local cPerg      := ""
	local _sQuery    := ""
	local _aRetQry   := {}
	local _aCols     := {}
	local _oCtaCorr  := NIL
	local _oAssocRel := NIL
	local _aColsRel  := {}
	local _aRegRel   := {}
	local _nRegRel   := 0

	do case
	case _nQual == 1
		cPerg = "SZI_REL2"
		U_GravaSX1 (cPerg, "01", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "02", szi -> zi_lojasso)
		U_GravaSX1 (cPerg, "03", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "04", szi -> zi_lojasso)
		U_SZI_Rel2 ()
	case _nQual == 2
		cPerg = "MLXPAS"
		U_GravaSX1 (cPerg, "03", szi -> zi_assoc)  // Associado inicial
		U_GravaSX1 (cPerg, "04", szi -> zi_assoc)  // Associado final
		U_ML_PAss ()
	case _nQual == 3
		CursorWait ()
/*		_sQuery := ""
		_sQuery += " SELECT 'Ctas. pagar' AS ORIGEM, E2_EMISSAO, E2_TIPO, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_VALOR, E2_HIST, '', '', '', '', ''"
		_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2"
		_sQuery +=  " WHERE E2_FILIAL   = '" + xfilial ("SE2") + "'"
		_sQuery +=    " AND E2_VACHVEX  = '" + &(_sChave) + "'"
		_sQuery +=    " AND D_E_L_E_T_  = ''"
		_sQuery += " UNION ALL "
		_sQuery += " SELECT 'Mov.bancario' AS ORIGEM, E5_DATA, E5_TIPO, E5_PREFIXO, E5_NUMERO, E5_PARCELA, E5_VALOR, E5_HISTOR, E5_BANCO, E5_MOTBX, E5_TIPODOC, E5_MOEDA, E5_VASZIFP"
		_sQuery +=   " FROM " + RetSQLName ("SE5") + " SE5"
		_sQuery +=  " WHERE E5_FILIAL   = '" + xfilial ("SE5") + "'"
		_sQuery +=    " AND E5_VACHVEX  = '" + &(_sChave) + "'"
		_sQuery +=    " AND E5_SITUACA != 'C'"
		_sQuery +=    " AND D_E_L_E_T_  = ''"
		u_log (_sQuery)
		_aRetQry = U_Qry2Array (_sQuery, .T., .F.)
*/
		_aCols = {}
		aadd (_aCols, {1,  "Origem",     50, ""})
		aadd (_aCols, {2,  "Emissao",    30, "@D"})
		aadd (_aCols, {3,  "Tipo",       25, ""})
		aadd (_aCols, {4,  "Pref",       25, ""})
		aadd (_aCols, {5,  "Numero",     30, ""})
		aadd (_aCols, {6,  "Parc",       15, ""})
		aadd (_aCols, {7,  "Valor",      50, "@E 999,999.99"})
		aadd (_aCols, {8,  "Historico", 100, ""})
		aadd (_aCols, {9,  "Banco",      30, ""})
		aadd (_aCols, {10, "Mot.Bx",     30, ""})
		aadd (_aCols, {11, "Tipo doc",   30, ""})
		aadd (_aCols, {12, "Numerario",  30, ""})
		aadd (_aCols, {13, "Form.pag.",  30, ""})
		aadd (_aCols, {14, "Vencto",     30, ""})
		aadd (_aCols, {15, "Fornecedor", 40, ""})
		aadd (_aCols, {16, "Nome",       60, ""})
		_aColsRel = {}
		_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
		_aRegRel := aclone (_oCtaCorr:RegRelac ())
		//U_Log2 ('debug', _aRegRel)
		for _nRegRel = 1 to len (_aRegRel)
			if _aRegRel [_nRegRel, 1] == 'SE2'
				se2 -> (dbgoto (_aRegRel [_nRegRel, 2]))
				aadd (_aColsRel, {'Ctas.pagar',;
								se2 -> e2_emissao,;
								se2 -> e2_tipo,;
								se2 -> e2_prefixo,;
								se2 -> e2_num,;
								se2 -> e2_parcela,;
								se2 -> e2_valor,;
								se2 -> e2_hist,;
								'', '', '', '', '',;
								se2 -> e2_vencrea,;
								se2 -> e2_fornece + '/' + se2 -> e2_loja,;
								se2 -> e2_nomfor})

			elseif _aRegRel [_nRegRel, 1] == 'SE5'
				se5 -> (dbgoto (_aRegRel [_nRegRel, 2]))
				aadd (_aColsRel, {'Mov.bancario',;
								se5 -> e5_data,;
								se5 -> e5_tipo,;
								se5 -> e5_prefixo,;
								se5 -> e5_numero,;
								se5 -> e5_parcela,;
								se5 -> e5_valor,;
								se5 -> e5_histor,;
								se5 -> e5_banco,;
								se5 -> e5_motbx,;
								se5 -> e5_tipodoc,;
								se5 -> e5_moeda,;
								se5 -> e5_vaszifp,;
								ctod (''),;
								se5 -> e5_clifor + '/' + se5 -> e5_loja,;
								se5 -> e5_benef})
			else
				u_help ("Sem tratamento para origem '" + _aRegRel [_nRegRel, 1] + "' na consulta de movimentos relacionados.",, .t.)
			endif
		next
		CursorArrow ()
		//U_Log2 ('debug', _aColsRel)
		if len (_aColsRel) == 0
			u_help ("Nao foi encontrado nenhum movimento relacionado a este lancamento.")
		else
			U_F3Array (_aColsRel, "Registros relacionados", _aCols, oMainWnd:nClientWidth - 50, NIL, "Registros relacionados a este lancamento")
		endif

	case _nQual == 4
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + szi -> zi_assoc + szi -> zi_lojasso, .F.))
			u_help ("Fornecedor nao encontrado!")
		else
			if pergunte ("FIC030", .T.)
				FinC030 ("Fc030Con")
			endif
		endif

	case _nQual == 5

		dbSelectArea("SA2")
		sa2 -> (dbsetorder (1))

		if sa2 -> (dbseek (xfilial ("SA2") + szi -> zi_assoc + szi -> zi_lojasso, .F.))
			A020Visual("SA2", , 2)
		else
			u_help ("Fornecedor nao encontrado!")
		endif
	
	case _nQual == 6
		_oAssocRel := ClsAssoc():New(szi -> zi_assoc, szi -> zi_lojasso)
		if valtype (_oAssocRel) != "O"
			u_help ("Nao foi possivel instanciar classe ClsAssoc.",, .t.)
		else
			U_ShowMemo (_oAssocRel:SldQuotCap (dDataBase, .T.) [.QtCapRetTXT], "DADOS DE CAPITAL")
		endif

	case _nQual == 8
		_oAssocRel := ClsAssoc():New(szi -> zi_assoc, szi -> zi_lojasso)
		if valtype (_oAssocRel) != "O"
			u_help ("Nao foi possivel instanciar classe ClsAssoc.",, .t.)
		else
			cPerg = "IRASSOC"
			U_GravaSX1 (cPerg, "01", _oAssocRel:CPF)
			U_GravaSX1 (cPerg, "02", _oAssocRel:CPF)
			U_GravaSX1 (cPerg, "04", _oAssocRel:Codigo)
			U_GravaSX1 (cPerg, "05", _oAssocRel:Loja)
			U_GravaSX1 (cPerg, "06", _oAssocRel:Codigo)
			U_GravaSX1 (cPerg, "07", _oAssocRel:Loja)
			U_GravaSX1 (cPerg, "08", _oAssocRel:Nucleo)

			U_IRAssoc ()
		endif

	case _nQual == 9
		se2 -> (dbsetorder (6))  // E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, R_E_C_N_O_, D_E_L_E_T_
		u_log2 ('debug', 'pesquisando SE2 com >>' + xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela + '<<')
		if ! se2 -> (dbseek (xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela, .F.))
			u_help ("Nao consegui localizar nenhum titulo no contas a pagar com este prefixo / numero / parcela.",, .t.)
		else
				FC050Con ()
		endif

	case _nQual == 10
		CursorWait ()
		_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
		CursorArrow ()
		u_help ('Saldo calculado na data base do sistema:' + chr (13) + chr (10) + cvaltochar (_oCtaCorr:SaldoEm (dDataBase)))

	case _nQual == 11
		cPerg = "SZI_LCS"
		U_GravaSX1 (cPerg, "01", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "02", szi -> zi_lojasso)
		U_GravaSX1 (cPerg, "03", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "04", szi -> zi_lojasso)
		U_SZI_LCS ()
		
	case _nQual == 12 // CONSULTA FATURAS
		// VERIFICA SE O REGISTRO POSICIONADO É UMA FATURA
		if fBuscaCpo ('SE2', 6, xfilial('SE2') + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela, "E2_TIPO") = 'FAT'
			// MOSTRA NOTAS CONSTANTES NA FATURA

			_sQuery  = " "
			_sQuery += " SELECT "
			_sQuery += " 	E2_PREFIXO"
			_sQuery += "    ,E2_NUM"
			_sQuery += "    ,E2_PARCELA"
			_sQuery += "    ,E2_TIPO"
			_sQuery += "    ,E2_EMIS1"
			_sQuery += "    ,E2_VENCREA"
			_sQuery += "    ,ISNULL((SELECT"
			_sQuery += " 			SUM(FK2_VALOR)"
			_sQuery += " 		FROM " + RetSQLName ("FK7") + " AS FK7 "
			_sQuery += " 			," + RetSQLName ("FK2") + " AS FK2 "
			_sQuery += " 		WHERE FK7.D_E_L_E_T_ = ''"
			_sQuery += " 		AND FK7.FK7_FILIAL = SE2.E2_FILIAL"
			_sQuery += " 		AND FK7.FK7_ALIAS  = 'SE2'"
			_sQuery += " 		AND FK7.FK7_CHAVE  = SE2.E2_FILIAL + '|' + SE2.E2_PREFIXO + '|' + SE2.E2_NUM + '|' + SE2.E2_PARCELA + '|' + SE2.E2_TIPO + '|' + SE2.E2_FORNECE + '|' + SE2.E2_LOJA"
			_sQuery += " 		AND FK2.D_E_L_E_T_ = ''"
			_sQuery += " 		AND FK2.FK2_FILIAL = FK7.FK7_FILIAL"
			_sQuery += " 		AND FK2.FK2_IDDOC  = FK7.FK7_IDDOC"
			_sQuery += " 		AND FK2.FK2_MOTBX  = 'FAT'"
			_sQuery += " 		AND FK2.FK2_TPDOC != 'ES'" 
			_sQuery += " 		AND dbo.VA_FESTORNADO_FK2(FK2.FK2_FILIAL, FK2.FK2_IDFK2) = 0)"
			_sQuery += " 	, 0) AS E2_VALOR"
			_sQuery += "    ,E2_SALDO"
			_sQuery += "    ,E2_FATURA"
			_sQuery +=    " ,E2_HIST"
			_sQuery += " FROM " + RetSQLName ("SE2") + " AS SE2 "
			_sQuery += " WHERE SE2.D_E_L_E_T_ = ''"
			_sQuery += " AND SE2.E2_FILIAL   = '" + szi -> zi_filial  + "'" 
			_sQuery += " AND SE2.E2_FORNECE  = '" + szi -> zi_assoc   + "'"
			_sQuery += " AND SE2.E2_LOJA     = '" + szi -> zi_lojasso + "'"
			_sQuery += " AND SE2.E2_FATURA   = '" + szi -> zi_doc     + "'"
			_sQuery += " ORDER BY E2_PREFIXO, E2_NUM"
			U_Log2 ('debug', '[' + procname () + ']' + _sQuery)
			_aDados := U_Qry2Array(_sQuery)
			
			if len(_aDados) > 0 
				_aCols = {}
				aadd (_aCols, {1,  "PREFIXO"   ,  30,  "@!"})
				aadd (_aCols, {2,  "NUMERO"    ,  50,  "@!"})
				aadd (_aCols, {3,  "PARCELA"   ,  20,  "@!"})
				aadd (_aCols, {4,  "TIPO"      ,  20,  "@!"})
				aadd (_aCols, {5,  "EMISSAO"   ,  30,  "@D"})
				aadd (_aCols, {6,  "VENCIMENTO",  30,  "@D"})
				aadd (_aCols, {7,  "VALOR"     ,  50,  "@E 999,999.99"})
				aadd (_aCols, {8,  "SALDO"     ,  50,  "@E 999,999.99"})
				aadd (_aCols, {9,  "FATURA"    ,  40,  ""})
				aadd (_aCols, {10, "HIST"      ,  140, ""})
				U_F3Array (_aDados, "Titulos agrupados na fatura " + szi -> zi_doc , _aCols, oMainWnd:nClientWidth - 50, NIL, "" )
			else
				u_help ("Nao foram encontrados titulos relacionados a essa fatura.")
			endif
		else
			u_help ("Documento selecionado nao eh uma fatura.")
		endif

	case _nQual == 13
		cPerg = "ML_FECHASA"
		U_GravaSX1 (cPerg, "02", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "03", szi -> zi_lojasso)
		U_ML_FechaSafra ()

	case _nQual == 97  // Gera SE2 - Especifico para manutencoes e testes.
		if U_MsgNoYes ("Esta rotina vai gerar SE2 para o registro atual do SZI. Usar quando deu algum problema na gravacao do SE2. Deseja continuar?")
			if dDataBase != szi -> zi_data
				u_help ("Use data base igual a data do SZI.")
			else
				_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
				//u_log2 ('debug', _oCtaCorr)
				if ! _oCtaCorr:GeraSE2 (_oCtaCorr:OQueGera (), _oCtaCorr:DtMovto, .F.)
					u_help (_oCtaCorr:UltMsg,, .t.)
				else
					u_help ('SE2 gerado.' + _oCtaCorr:UltMsg)
				endif
			endif
		endif

	case _nQual == 98  // Especifico para manutencoes e testes.
		CursorWait ()
		_sQuery := ""
		_sQuery += " SELECT V.*"
		_sQuery +=   " FROM " + RetSQLName ("SE5") + " SE5, "
		_sQuery +=        " dbo.VA_COMPENSACOES V"  // Nao sei se vale a pena manter esta view...
		_sQuery +=  " WHERE V.FILIAL   = SE5.E5_FILIAL"
		_sQuery +=    " AND V.CLIFOR   = SE5.E5_CLIFOR"
		_sQuery +=    " AND V.LOJA     = SE5.E5_LOJA"
		_sQuery +=    " AND V.NUMERO   = SE5.E5_NUMERO"
		_sQuery +=    " AND V.PREFIXO  = SE5.E5_PREFIXO"
		_sQuery +=    " AND V.PARCELA  = SE5.E5_PARCELA"
		_sQuery +=    " AND V.SEQ      = SE5.E5_SEQ"
		_sQuery +=    " AND SE5.E5_FILIAL   = '" + xfilial ("SE5") + "'"
		_sQuery +=    " AND SE5.E5_VACHVEX  = '" + &(_sChave) + "'"
		_sQuery +=    " AND SE5.E5_SITUACA != 'C'"
		_sQuery +=    " AND SE5.D_E_L_E_T_  = ''"
		u_log (_sQuery)
		_aRetQry = U_Qry2Array (_sQuery, .T., .T.)
		CursorArrow ()
		if len (_aRetQry) == 0
			u_help ("Nao foi encontrada no financeiro nenhuma movimentacao relacionada a este lancamento.")
		else
			u_showarray (_aRetQry)
		endif
	otherwise
		u_help ("Consulta / relatorio nao previsto.")
	endcase

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Alteracao.
User Function SZIA ()
	private altera   := .T.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	RegToMemory ("SZI", inclui, .T.)

	// Apos a alteracao do registro, faz os tratamentos necessarios.
	if axaltera ("SZI", szi -> (recno ()), 4) == 1//, NIL, NIL, NIL, "U_SZI1 ()") == 1
//		u_log ('usuario confirmou alt.')
//		u_log (m->zi_obs)

		// Grava campo memo.
		msmm (,,, m->zi_obs, 1,,, "SZI", "ZI_CODMEMO")

	endif
return
//
// --------------------------------------------------------------------------
// Alteracao da data de vencimento do titulo no financeiro.
User Function SZIADV ()
	local _aAreaAnt := U_ML_SRArea ()
	local _dNovoVcto := ctod ('')

	se2 -> (dbsetorder (1))
	if se2 -> (dbseek (SZI->ZI_FILIAL + SZI->ZI_SERIE + SZI->ZI_DOC + SZI->ZI_PARCELA, .F.))
		if se2 -> e2_valor != szi -> zi_valor
			u_help ("Valor encontrado no financeiro (" + cvaltochar (se2 -> e2_valor) + ") nao corresponde ao valor da conta corrente. Verifique se o titulo correto existe no financeiro.",, .t.)
		else
			_dNovoVcto = se2 -> e2_vencto
			do while .T.
				_dNovoVcto = U_Get ("Informe nova data de vencto", 'D', 8, '@D', '', _dNovoVcto, .F., '.t.')
				if ! empty (_dNovoVcto)
					if _dNovoVcto < date ()
						// No momento estou criando esta funcionalidade para permitir ao usuario 'empurrar' o vencimento dos titulos das notas
						// de compra de safra, como forma de reservar dinheiro para compensar Unimed da linha Jacinto, que é compensada em setembro. GLPI 8165.
						u_help ("Data de vencimento nao pode ser retroativa.",, .t.)
						loop
					else
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven   = "SE2001"
						_oEvento:Texto     = "Alterando vcto. de " + dtoc (se2 -> e2_vencto) + " para " + dtoc (_dNovoVcto)
						_oEvento:NFEntrada = se2 -> e2_num
						_oEvento:SerieEntr = se2 -> e2_prefixo
						_oEvento:ParcTit   = se2 -> e2_parcela
						_oEvento:Fornece   = se2 -> e2_fornece
						_oEvento:LojaFor   = se2 -> e2_loja
						_oEvento:Grava ()
						reclock ("SE2", .F.)
						se2 -> e2_vencto  = _dNovoVcto
						se2 -> e2_vencrea = DataValida (_dNovoVcto)
						msunlock ()
						exit
					endif
				else
					u_help ("Processo cancelado.")
					exit
				endif
			enddo
		endif
	else
		u_help ("Nao encontrei, no financeiro, o titulo correspondente.",, .t.)
	endif
	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Cancela a fatura relacionada a este titulo.
User Function SZICF (_lBatch)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _aTitOriF  := {}
	local _nTitOriF  := 0
	local _sMsgCanF  := ''
	local _aFatCanc  := {}
	local _nTotVlFat := 0
	local _oSQL      := NIL
	local _oCtaCorr  := NIL
	local _oEvento   := NIL
	local _aRegFat   := {}
	local _nRegFat   := 0
	local _aRegSZI   := {}
	local _nRegSZI   := 0
	local _sWhere    := ''
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto  := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	if _lContinua
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		_lContinua = _oCtaCorr:PodeExcl ()
	endif

	// A tabela SE2 deve estar posicionada em um dos titulos gerados pela fatura para a rotina automatica.
	if _lContinua
		se2 -> (dbsetorder (1))  // E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, R_E_C_N_O_, D_E_L_E_T_
//		u_log2 ('debug', '>>' + szi -> zi_filial + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela + 'FAT' + szi -> zi_assoc + szi -> zi_lojasso + '<<')
		if ! se2 -> (dbseek (szi -> zi_filial + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela + 'FAT' + szi -> zi_assoc + szi -> zi_lojasso, .F.))
			u_help ("Titulo correspondente nao encontrado no financeiro, ou nao se trata de uma fatura.",, .t.)
			_lContinua = .F.
		endif
		if se2 -> e2_saldo != se2 -> e2_valor
			u_help ("Titulo ja sofreu baixas.")
			_lContinua = .F.
		endif
	endif

	// Sendo uma fatura, a mesma pode ter gerado mais de um titulo, conforme a condicao de pagamento usada.
	// Preciso verificar se todos podem ser excluidos.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SE2.R_E_C_N_O_, isnull (SZI.R_E_C_N_O_, 0), SE2.E2_SALDO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " ON (SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=      " AND ZI_FILIAL  = E2_FILIAL"
		_oSQL:_sQuery +=      " AND ZI_ASSOC   = E2_FORNECE"
		_oSQL:_sQuery +=      " AND ZI_LOJASSO = E2_LOJA"
		_oSQL:_sQuery +=      " AND ZI_DOC     = E2_NUM"
		_oSQL:_sQuery +=      " AND ZI_SERIE   = E2_PREFIXO"
		_oSQL:_sQuery +=      " AND ZI_PARCELA = E2_PARCELA)"
		_oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND E2_FILIAL  = '" + se2 -> e2_filial + "'"
		_oSQL:_sQuery +=   " AND E2_FORNECE = '" + se2 -> e2_fornece + "'"
		_oSQL:_sQuery +=   " AND E2_LOJA    = '" + se2 -> e2_loja + "'"
		_oSQL:_sQuery +=   " AND E2_NUM     = '" + se2 -> e2_num + "'"
		_oSQL:_sQuery +=   " AND E2_PREFIXO = '" + se2 -> e2_prefixo + "'"
		_oSQL:_sQuery +=   " AND E2_TIPO    = '" + se2 -> e2_tipo + "'"
		_oSQL:Log ()
		_aRegFAT := aclone (_oSQL:Qry2Array ())
		u_log2 ('debug', 'recnos dos titulos da fatura:')
		u_log2 ('debug', _aRegFat)
		_nTotVlFat = 0
		for _nRegFAT = 1 to len (_aRegFAT)
			_nTotVlFat += _aRegFat [_nRegFAT, 3]
			if _aRegFat [_nRegFAT, 2] != 0
				_oCtaCorr := ClsCtaCorr ():New (_aRegFat [_nRegFAT, 2])
				if ! _oCtaCorr:PodeExcl ()
					_lContinua = .F.
					exit
				endif
			endif
		next
	endif

	// Gera array com os titulos originais agrupados na fatura.
	// Aproveita para guardar os recnos do SZI relacionados a eles.
	if _lContinua
		_sWhere += "  WHERE SE2.D_E_L_E_T_ = ''"
		_sWhere += "    AND E2_FILIAL  = '" + se2 -> e2_filial + "'"
		_sWhere += "    AND E2_FORNECE = '" + se2 -> e2_fornece + "'"
		_sWhere += "    AND E2_LOJA    = '" + se2 -> e2_loja + "'"
		_sWhere += "    AND E2_FATURA  = '" + se2 -> e2_num + "'"
		_sWhere += "    AND E2_FATPREF = '" + se2 -> e2_prefixo + "'"

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, '' "
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery += _sWhere
		_oSQL:Log ()
		_aTitOriF := aclone (_oSQL:Qry2Array ())
		u_log2 ('debug', _aTitOriF)
		if len (_aTitOriF) == 0
			u_help ("Nao encontrei os titulos originais que teriam sido agrupados nesta fatura.",, .t.)
			_lContinua = .F.
		else
			_oSQL:_sQuery := " SELECT isnull (SZI.R_E_C_N_O_, 0)"
			_oSQL:_sQuery += "   FROM " + RetSQLName ("SE2") + " SE2 "
			_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SZI") + " SZI "
			_oSQL:_sQuery +=  " ON (SZI.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=      " AND ZI_FILIAL  = E2_FILIAL"
			_oSQL:_sQuery +=      " AND ZI_ASSOC   = E2_FORNECE"
			_oSQL:_sQuery +=      " AND ZI_LOJASSO = E2_LOJA"
			_oSQL:_sQuery +=      " AND ZI_DOC     = E2_NUM"
			_oSQL:_sQuery +=      " AND ZI_SERIE   = E2_PREFIXO"
			_oSQL:_sQuery +=      " AND ZI_PARCELA = E2_PARCELA)"
			_oSQL:_sQuery += _sWhere
			_aRegSZI := aclone (_oSQL:Qry2Array ())
//			u_log2 ('debug', 'recnos do SZI dos titulos aglutinados na fatura:')
//			u_log2 ('debug', _aRegSZI)
		endif
	endif
	
	if _lContinua .and. ! _lBatch
		_lContinua = U_MsgNoYes ("Esta fatura contem " + cvaltochar (len (_aRegFat)) + " parcelas somando R$ " + alltrim (transform (_nTotVlFat, "@E 999,999,999.99")) + " (todas serao excluidas tambem da conta corrente). A fatura foi gerada a partir de " + cvaltochar (len (_aTitOriF)) + " titulos, cujo saldo vai retornar para a conta corrente. Confirma o cancelamento da fatura?")
	endif

	// Deixa dados prontos para gravacao do evento.
	if _lContinua
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SE2002"
		_oEvento:Texto     = "Cancelamento fatura '" + se2 -> e2_num + '/' + se2 -> e2_prefixo + '-' + se2 -> e2_parcela
		_oEvento:NFEntrada = se2 -> e2_num
		_oEvento:SerieEntr = se2 -> e2_prefixo
		_oEvento:Fornece   = se2 -> e2_fornece
		_oEvento:LojaFor   = se2 -> e2_loja
	endif

	// Monta uma array com os dados da fatura a cancelar.
	if _lContinua
		_aFatCanc = {}
		// seta campos do array da fatura
		Aadd(_aFatCanc, se2 -> e2_prefixo)        //-- Prefixo
		Aadd(_aFatCanc, se2 -> e2_tipo)           //-- Tipo
		Aadd(_aFatCanc, se2 -> e2_num)            //-- Numero da Fatura (se o numero estiver em branco obtem pelo FINA290)
		Aadd(_aFatCanc, se2 -> e2_naturez)        //-- Natureza
		Aadd(_aFatCanc, se2 -> e2_emissao)        //-- Data emissao inicial
		Aadd(_aFatCanc, se2 -> e2_emissao)        //-- Data emissao final
		Aadd(_aFatCanc, se2 -> e2_fornece)        //-- Fornecedor
		Aadd(_aFatCanc, se2 -> e2_Loja)           //-- Loja
		Aadd(_aFatCanc, se2 -> e2_fornece)        //-- Fornecedor para geracao
		Aadd(_aFatCanc, se2 -> e2_loja)           //-- Loja do fornecedor para geracao
		Aadd(_aFatCanc, '')                       //-- Condicao de pagto
		Aadd(_aFatCanc, 01)                       //-- Moeda
		Aadd(_aFatCanc, aclone(_aTitOriF))        //-- ARRAY com os titulos da fatura (Prefixo,Numero,Parcela,Tipo,Título localizado na geracao de fatura (lógico). Iniciar com falso.)
		Aadd(_aFatCanc, 0)                        //-- Valor de decrescimo
		Aadd(_aFatCanc, 0)                        //-- Valor de acrescimo
		//u_log2 ('debug', _aFatCanc)
		dbselectarea("SE2")
		lMsErroAuto  := .F.
		MsExecAuto( { |x,y| FINA290(x,y)},4,_aFatCanc,)
		
		// Em meus testes a variavel lMsErroAuto permanece sempre .F., entao vou procurar a fatura,
		// para ver se foi excluida.
		_nRegFAT = 1
		do while _lContinua .and. _nRegFAT <= len (_aRegFat)
			u_log2 ('debug', 'Verificando se a fatura recno ' + cvaltochar (_aRegFAT [_nRegFAT, 1]) + ' foi excluida.')
			se2 -> (dbgoto (_aRegFAT [_nRegFAT, 1]))
			u_log2 ('debug', se2 -> (deleted ()))
			
			// Se excluiu a fatura e esta tinha lancamento correspondente no SZI, o SZI deve ser excluido tambem.
			if se2 -> (deleted ())
				if _aRegFat [_nRegFAT, 2] != 0
					szi -> (dbgoto (_aRegFAT [_nRegFAT, 2]))
					_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
					_lContinua = _oCtaCorr:Exclui ()
				endif
			else
				u_help ('Fatura ' + se2 -> e2_num + '/' + se2 -> e2_prefixo + '-' + se2 -> e2_parcela + ' nao foi cancelada.',, .t.)
				_lContinua = .F.
				exit
			endif
			_nRegFAT ++
		enddo
	endif

	// Atualiza no SZI os saldos dos registros relacionados aos titulos que estavam agrupados na fatura.
	if _lContinua
		_oEvento:Grava ()
	
		for _nRegSZI = 1 to len (_aRegSZI)
			szi -> (dbgoto (_aRegSZI [_nRegSZI, 1]))
			_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
			_oCtaCorr:AtuSaldo ()
		next

		// Monta mensagem para retorno.
		_sMsgCanF := "Fatura " + _aFatCanc [3] + " cancelada." + chr (13) + chr (10)
		_sMsgCanF += "Saldos retornados para os seguintes titulos:" + chr (13) + chr (10)
		for _nTitOriF = 1 to len (_aTitOriF)
			_sMsgCanF += _aTitOriF [_nTitOriF, 2] + '/' + _aTitOriF [_nTitOriF, 1] + '-' + _aTitOriF [_nTitOriF, 3] + chr (13) + chr (10)
		next
		u_help (_sMsgCanF)
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua
//
// --------------------------------------------------------------------------
// Inclusao
User Function SZII ()
	local _oCtaCorr  := NIL
	private altera   := .F.
	private inclui   := .T.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	RegToMemory ("SZI", inclui, inclui)

	// Apos a inclusao do registro, faz os tratamentos necessarios.
	if axinclui ("SZI", szi -> (recno ()), 3, NIL, NIL, NIL, "U_SZI1 ()") == 1
		CursorWait ()
		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:GeraAtrib ('SZI')
		_oCtaCorr:VctoSE2For = m->zi_vctoFor  // Campo virtual.
		_oCtaCorr:Obs        = m->zi_obs      // Os demais atributos jah estavam gravados no SZI.
		_lRet = _oCtaCorr:Grava (.T., .F.)
		CursorArrow ()
	endif
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Gera sequencial para novo registro do SZI. Faz bloqueio de semaforo para garantir sequencia exclusiva.
User Function SZISeq ()
	local _lRet     := .F.
	local _oCtaCorr := NIL
	_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
	_lRet = _oCtaCorr:GeraSeq ()
return _lRet
//
// --------------------------------------------------------------------------
// Valida inclusao.
User Function SZI1 ()
	local _lRet     := .T.
	local _aBcos    := {}
	local _aNaoBcos := {}
	local _oCtaCorr := NIL

	if _lRet .and. m->zi_tm == '04'
		u_help ("Este tipo de movimento deve ser gerado via nota fiscal.")
		_lRet = .F.
	endif

	// Validacoes estao sendo passadas para a classe de conta corrente.
	if _lRet
		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:GeraAtrib ('M')
		_lRet = _oCtaCorr:PodeIncl ()
	endif
	

	if _lRet .and. ! empty (m->zi_fornece) .and. ! sa2 -> (dbseek (xfilial ("SA2") + M->zi_fornece + m->zi_lojafor, .F.))
		U_Help ("Fornecedor '" + m->zi_fornece + "' nao cadastrado.")
		_lRet = .F.
	endif

	// Verifica preenchimento de campos
	if _lRet
		_aBcos = {}
		_aNaoBcos = {'ZI_DOC'}
		if m->zi_tm $ '08/09'
			aadd (_aBcos, 'ZI_VALOR')
		else
			aadd (_aNaoBcos, 'ZI_VALOR')
		endif
		_lRet = _VerCpos (_aBcos, _aNaoBcos)
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verifica preenchimento dos campos, conforme tipo de movimentacao.
static function _VerCpos (_aBcos, _aNaoBcos)
	local _lRet := .T.
	local _nCampo := 0
	for _nCampo = 1 to len (_aBcos)
		if ! empty (m->&(_aBcos [_nCampo]))
			u_help ("Campo '" + alltrim (RetTitle (_aBcos [_nCampo])) + "' NAO deve ser informado para este tipo de movimentacao.")
			_lRet = .F.
			exit
		endif
	next
	for _nCampo = 1 to len (_aNaoBcos)
		if empty (m->&(_aNaoBcos [_nCampo]))
			u_help ("Campo '" + alltrim (RetTitle (_aNaoBcos [_nCampo])) + "' DEVE ser informado para este tipo de movimentacao.")
			_lRet = .F.
			exit
		endif
	next
return _lRet
//
// --------------------------------------------------------------------------
// Exclusao de movimento da conta corrente.
User Function SZIE ()
	local _lContinua := .T.
//	local _sTipoMov  := szi -> zi_tm
//	local _sOQueGera := ""
//	local _sCodmemo  := szi -> zi_CodMemo
	local _oCtaCorr  := NIL
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	if _lContinua
		_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
		_lContinua = _oCtaCorr:PodeExcl ()
	endif

	if _lContinua

		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("SZI", inclui, inclui)

		if AxDeleta ("SZI", szi -> (recno ()), 5) == 2
			_oCtaCorr:Exclui ()
		endif
	endif                                                                                                          
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Baixa do movimento. Gera movimentacao financeira caso necessario.
User Function SZIB ()
	local _nForma    := 0
	local _aBkpSX1   := {}
	local cPerg      := ""
	local _sOutrIni  := ""
	local _sOutrFim  := ""
	local _lContinua := .T.

	// Acho que o certo eh eliminar os titulos do SE2, mas agora nao tenho tempo para verificar. Robert, 05/09/2017
	if _lContinua .and. szi -> zi_tm == '19'
		u_help ('Este movimento so deve ser baixado ao resgatar cotas')
		_lContinua = .F.
	endif
	
	if _lContinua .and. szi -> zi_saldo <= 0
		u_help ("Nao ha saldo a ser baixado para este lancamento.")
		_lContinua = .F.
	endif

	// Para fazer uma baixa, o título precisa existir no financeiro.
	if _lContinua
		se2 -> (dbsetorder (6))  // E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, R_E_C_N_O_, D_E_L_E_T_
		u_log2 ('debug', 'pesquisando SE2 com >>' + xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela + '<<')
		if ! se2 -> (dbseek (xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela, .F.))
			u_help ("Nao localizar nenhum titulo no contas a pagar com este prefixo / numero / parcela.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_nForma = aviso ("Forma de baixa", ;
							"Selecione a forma de baixa deste lançamento:" + chr (13) + chr (10) +;
							"- Normal: direto contra banco/caixa" + chr (13) + chr (10) + ;
							"- Compensacao: entre titulos do mesmo associado" + chr (13) + chr (10) + ;
							"- Comp.outros: entre titulos do associado contra titulos de outros associados", ;
							{"&Normal", "Co&mpensacao", "Comp.&outros", "&Cancelar"}, ;
							3, ;
							"Forma de baixa")

		// Prepara dados para inicializadores padrao dos campos. Estas variaveis
		// sao lidas pelos lancamentos padronizados da contabilidade, por isso
		// devem ser inicializadas em branco ou com NIL para evitar a geracao
		// de lancamentos indevidos.
		_SZI_Hist = ''
		_SZI_Deb  = NIL
		_SZI_Cred = NIL
		_SZI_Hist = NIL
		do case
		case szi -> zi_tm $ '01/29'  // == '01'
			_SZI_Hist = "REEMB.UNIMED " +  transform (szi -> zi_MesRef, "@R 99/9999")
			_SZI_Deb  = iif (_nForma == 1, NIL, '201030101001')
			_SZI_Cred = iif (cFilAnt $ '07/08/12', '201030103001', '101020101003')
		case szi -> zi_tm == '02'
			_SZI_Hist = "REEMB.CELULAR " + transform (szi -> zi_MesRef, "@R 99/9999")
			if _nForma == 2 .or. _nForma == 3
				_SZI_Deb  = "201030101001"
			else
				_SZI_Deb = NIL  // Vai pegar a conta do banco posteriormente.
			endif
			_SZI_Cred = "101020101004"
		case szi -> zi_tm == '03'
			_SZI_Hist = "REEMB.AN.SOLO " + transform (szi -> zi_MesRef, "@R 99/9999")
			_SZI_Deb  = NIL
			_SZI_Cred = '101020101002'
		case szi -> zi_tm == '05'
			_SZI_Hist = "REEMB.INSUMOS " + transform (szi -> zi_MesRef, "@R 99/9999")
			_SZI_Deb  = NIL
			_SZI_Cred = '201030101001'
		case szi -> zi_tm == '06'
			_SZI_Hist = "REEMB.SEMENTES " + transform (szi -> zi_MesRef, "@R 99/9999")
			_SZI_Deb  = NIL
			_SZI_Cred = '201030101001'
		case szi -> zi_tm == '07'
			_SZI_Hist = "REEMB.ADTO.SAFRA " + transform (szi -> zi_MesRef, "@R 99/9999")
			_SZI_Deb  = NIL
			_SZI_Cred = '201030101001'
		case szi -> zi_tm == '11'
			_SZI_Hist = "RESG.CTA.CAP."
			_SZI_Deb  = '201030102001'
			_SZI_Cred = NIL
		case szi -> zi_tm == '12'  // Cap. social a integralizar
			_SZI_Cred = '204010102001'
		case szi -> zi_tm == '14'
			_SZI_Hist = "VLR.PAGTO.JUROS"
			_SZI_Deb  = NIL
			_SZI_Cred = '201030101001'
		case szi -> zi_tm == '15'
			_SZI_Hist = "VLR.RECEBTO.JUROS"
			_SZI_Deb  = '101020101002'
			_SZI_Cred = NIL
		case szi -> zi_tm == '20'  // Cap. social a integralizar
			_SZI_Cred = '204010102001'

		endcase

		// Se compensar com titulos de outros associados, o usuario deve confirmar estes parametros.
		if _nForma == 3
			if ! Pergunte (cPerg2, .T.)
				return
			else
				_sOutrIni = mv_par01
				_sOutrFim = mv_par02
			endif
		endif

		// Chama rotinas de baixa ou compensacao, conforme selecao do usuario.
		// O saldo do SZI serah atualizado via pontos de entrada.
		CursorWait ()
		if _nForma == 1
			//_Pergunte ('FIN080')
			//_lCtOnLine = (MV_PAR03 == 1)

			u_log2 ('debug', 'Vou chamar FINA080')
			FINA080 (NIL, 3, .T.)
			
			// O P.E. generico FINA080 nao eh executado quando contabiliza on-line=NAO, mas preciso que ele atualize alguns campos.
			pergunte ('FIN080', .F.)
			if mv_par03 != 1
				U_Log2 ('debug', 'Chamando a rotina U_FINA080() por que nao ex executada quando contabiliza online')
				U_FINA080 ()
			endif

		elseif _nForma == 2 .or. _nForma == 3
			//_Pergunte ('AFI340')
			u_log2 ('debug', 'Vou chamar FINA340')
			fina340 (3)
			U_SalvaSX1 (cPerg, _aBkpSX1)
		endif
		CursorArrow ()
	endif
return
//
// --------------------------------------------------------------------------
// Cancelar baixas
User Function SZIC ()
	local _nQueTipo  := 0
	local _aBaixas   := {}
	local _oCtaCorr  := NIL
	local _lContinua := .T.

	u_logIni ()
	if szi -> zi_saldo == szi -> zi_valor
		u_help ("Nao ha baixas para este lancamento.")
		return
	endif

	// Para cancelar uma baixa, o título precisa existir no financeiro.
	if _lContinua
		se2 -> (dbsetorder (6))  // E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, R_E_C_N_O_, D_E_L_E_T_
		u_log2 ('debug', 'pesquisando SE2 com >>' + xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela + '<<')
		if ! se2 -> (dbseek (xfilial ("SE2") + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela, .F.))
			u_help ("Nao localizar nenhum titulo no contas a pagar com este prefixo / numero / parcela.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
//	// Verifica se existe registro relacionado no financeiro.
//	if ! U_TemNick ("SE2", "E2_VACHVEX")
//		u_help ("Problema nos indices de arquivos. Acione suporte.")
//		U_AvisaTI ("Falta indice para exclusao de movto da conta corrente de associados na rotina " + procname ())
//	else
//		// Verifica se existe titulo correspondente no financeiro.
//		se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
//		if se2 -> (dbseek (xfilial ("SE2") + &(_sChave), .F.))
			u_log2 ('debug', "Achei SE2 para cancelar baixa")
			_nQueTipo = aviso ("Forma de baixa", ;
			                   "Selecione o tipo de de baixa a ser cancelado", ;
			                   {"Normal", "Compensacao", "Cancelar"}, ;
			                   3, ;
			                   "Forma de baixa")

			if _nQueTipo == 1

				// Verifica se o titulo tem baixas.
				nTotAdto   := 0    // Variavel usada pelo Sel080Baixa
				lBaixaAbat := .t.  // Variavel usada pelo Sel080Baixa
				lBxCEC     := .t.  // Variavel usada pelo Sel080Baixa
				aBaixaSE5  := {}   // Variavel usada pelo Sel080Baixa
				_aBaixas   := Sel080Baixa ("VL /BA /CP /",se2 -> e2_Prefixo, se2 -> e2_Num, se2 -> e2_Parcela, se2 -> e2_Tipo,@nTotAdto,@lBaixaAbat,se2 -> e2_Fornece, se2 -> e2_Loja,@lBxCEC)
				if len (_aBaixas) == 0
					u_help ("Titulo nao parece ter baixas manuais. Verifique se houve baixa por compensacao.")
				else

					// Prepara dados para inicializadores padrao dos campos.
					_SZI_Hist = ''
					_SZI_Deb  = NIL
					_SZI_Hist = NIL
					do case
					case szi -> zi_tm == '11'
						_SZI_Hist = "ESTORNO RESG.CTA.CAP " + szi -> zi_nomasso
						_SZI_Deb  = NIL
						_SZI_Cred = '201030102001'
					endcase
					u_log ("Variaveis private preparadas para as outras rotinas:")
					u_log ('   _SZI_Hist:', _SZI_Hist)
					u_log ('   _SZI_Deb: ', _SZI_Deb)
					u_log ('   _SZI_Cred:', _SZI_Cred)

					fina080 (NIL, 5, .T.)  // Usa estorno por que o P.E. F080Est nao eh executado em caso de exclusao de baixa.
					
					// Recalcula o saldo do lancamento por que o P.E. generico FINA080 nao eh executado pela rot. de cancelamento.
					_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
					_oCtaCorr:AtuSaldo ()
				endif

			elseif _nQueTipo == 2
				fina340 (4)
			endif
//		endif
	endif
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Transferencia de saldo para outra filial.
User Function SZIT (_sFilDest)
	local _lContinua := .T.
	local _oCtaCorrT := NIL
	local _nValor    := 0

	//u_logIni ()
	if _sFilDest == NIL
		_sFilDest = U_Get ("Zerar o saldo do lcto, transferindo-o para a seguinte filial:", "C", 2, "", "SM0", "  ", .f., '.t.')
	endif
	if _sFilDest == NIL
		_lContinua = .F.
	endif

	if _lContinua
		CursorWait ()
		_oCtaCorrT := ClsCtaCorr():New (szi -> (recno ()))
		_oCtaCorrT:FilDest = _sFilDest
		_oCtaCorrT:Origem  = FunName ()
		if ! _oCtaCorrT:TransFil (_nValor)
			u_help ("A transferencia para outra filial nao foi possivel. " + _oCtaCorrT:UltMsg,, .T.)
		endif
		CursorArrow ()
	endif

	//u_logFim ()
return
//
// --------------------------------------------------------------------------
// Recalcula alguns saldos.
User Function SZIRS (_nQual)
	// Apenas para ter regua de processamento, pois alguns recalculos podem demorar.
	processa ({ || _SZIRS2 (_nQual)})
return
//
// --------------------------------------------------------------------------
static function _SZIRS2 (_nQual)
	local _oCtaCorr  := NIL
	local _nSaldoAnt := 0
	local _oAssoc    := ""
	local _dDataIni  := ctod ('')
	local _oSQL      := NIL
	local _aDados    := {}
	local _nDado     := 0
	local _nRegSE2   := 0
	local _lContinua := .T.

	if _nQual == 1  // Atualiza saldo deste lcto.
		_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))

		// Jah peguei casos em que o valor (nao o saldo) estava diferente do SE2
		_nRegSE2 := _oCtaCorr:RecnoSE2 ()
		if _nRegSE2 > 0
			se2 -> (dbgoto (_nRegSE2))
			if se2 -> e2_valor != szi -> zi_valor
				u_help ("Impossivel continuar: Verifiquei na tabela SE2 (contas a pagar) que o valor deste titulo encontra-se diferente (" + GetMv ('MV_SIMB1') + cvaltochar (se2 -> e2_valor) + ").",, .t.)
				_lContinua = .F.
			endif
		endif
		if _lContinua
			_nSaldoAnt = szi -> zi_saldo
			_oCtaCorr:AtuSaldo ()

			if _nSaldoAnt != szi -> zi_saldo
				u_help ("Saldo deste lcto alterado de " + cvaltochar (_nSaldoAnt) + " para " + cvaltochar (szi -> zi_saldo))
			endif
		endif

	elseif _nQual == 2  // Atualiza saldo geral do associado.
		_dDataIni = U_Get ('Data inicial (cada ano pode demorar bastante)', 'D', 8, '@D', '', date (), .F., '.T.')
		if ! empty (_dDataIni)
			procregua (10)
			u_log2 ('info', 'Recalculando saldo acum.associado ' + szi -> zi_assoc + '/' + szi -> zi_lojasso)
			_oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
			if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
			else
				processa ({ || _oAssoc:AtuSaldo (_dDataIni)})
			endif
		endif
	elseif _nQual == 3  // Atualiza saldo de cada lcto deste associado
		_dDataIni = U_Get ('Data emissao inicial para recalculo', 'D', 8, '@D', '', date (), .F., '.T.')
		if ! empty (_dDataIni)
			u_log2 ('info', 'Recalculando saldo de cada lcto.do associado ' + szi -> zi_assoc + '/' + szi -> zi_lojasso)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
			_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC    = '" + szi -> zi_assoc   + "'"
			_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO  = '" + szi -> zi_lojasso + "'"
			_oSQL:_sQuery +=    " AND SZI.ZI_DATA    >= '" + dtos (_dDataIni)  + "'"
			_oSQL:_sQuery +=  " ORDER BY ZI_FILIAL, ZI_SEQ"
			_oSQL:Log ()
			_aDados = _oSQL:Qry2Array ()
			procregua (len (_aDados))
			for _nDado = 1 to len (_aDados)
				szi -> (dbgoto (_aDados [_nDado, 1]))
				u_log2 ('info', 'Verificando saldo ' + szi -> zi_assoc + '/' + szi -> zi_lojasso + ' seq.' + szi -> zi_seq + ' ' + szi -> zi_histor)
				incproc ('Verificando saldo docto: ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela)
				_nSaldoAnt = szi -> zi_saldo
				_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
				_oCtaCorr:AtuSaldo ()
				if szi -> zi_saldo != _nSaldoAnt
					u_help ("Saldo do lcto alterado de " + cvaltochar (_nSaldoAnt) + " para " + cvaltochar (szi -> zi_saldo))
				endif
			next
		endif
	endif
return


/*
// --------------------------------------------------------------------------
// Chama a funcao padrao pergunte() para rotinas que serao executadas via rot.automatica.
Static Function _Pergunte (_sPerg)
	static _sPergLida := ''

	// Pergunta apenas uma vez por sessao
	if ! _sPerg $ _sPergLida
		u_help ('Confirme, a seguir, os parametros da subrotina ' + _sPerg + ' relacionada, que serao ocupados durante o processo.')
		if pergunte (_sPerg, .t.)
			_sPergLida += _sPerg + '/'
		endif
	endif
return
*/


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                 Help
	aadd (_aRegsPerg, {01, "Tipo de contas a visualizar   ", "N", 1,  0,  "",   "",    {"Normal", "Capital social", "Todas"}, "Tipo de conta corrente a ser visualizada"})
	aadd (_aRegsPerg, {02, "(desativado). Use OUTRAS ACOES", "C", 1,  0,  "",   "",    {},                        ""})
	aadd (_aRegsPerg, {03, "Filtro(SQL) sel.tit.p/compens.", "C", 60, 0,  "",   "",    {},                                    "Expressao (sintaxe SQL) para adicionar ao filtro de selecao de titulos a compensar."})
	aadd (_aDefaults, {"01", 1})
	aadd (_aDefaults, {"02", 2})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)

	
	// Perguntas para a compensacao entre associados.
	_aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes  Help
	aadd (_aRegsPerg, {01, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},     ""})
	aadd (_aRegsPerg, {02, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},     ""})
	aadd (_aDefaults, {"01", ''})
	aadd (_aDefaults, {"02", 'zzzzzz'})
	U_ValPerg (cPerg2, _aRegsPerg, {}, _aDefaults)
Return

