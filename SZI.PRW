// Programa...: SZI
// Autor......: Robert Koch
// Data.......: 25/02/2011
// Descricao..: Tela de manutencao de conta corrente de associados.
//
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
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

User Function szi()
	local _aCores      := U_SZILG (.T.)
	local _aRotSald    := {}
	local _aRotAdic    := {}
	local _oCtaCorr    := ClsCtaCorr():New ()
	local _aIndBrw     := {}  // Para filtragem no browse
	local _bFilBrw     := {|| Nil}  // Para filtragem no browse
	local _cCondicao   := ""  // Para filtragem no browse
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
	private _lCtOnLine := .F.
//	public  _sArqLog   := U_NomeLog ()
	u_logId ()

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Submenu de rotinas especificas para saldos.
	aadd (_aRotSald, {"Transf.saldo p/outra filial", "U_SZIT()",0,2})
	aadd (_aRotSald, {"Recalcular saldo deste lcto", "U_SZIRS(1)",0,2})
	if U_ZZUVL ('051', __cUserID, .F.)
		aadd (_aRotSald, {"Recalc.saldo geral associado", "U_SZIRS(2)",0,2})
	endif

	// Submenu de rotinas adicionais
	aadd (_aRotAdic, {"Extrato conta corrente",   "U_SZIR(1)",0,2})
	aadd (_aRotAdic, {"Extr.producao associado",  "U_SZIR(2)",0,2})
	aadd (_aRotAdic, {"Amarracoes c/ financeiro", "U_SZIR(3)",0,2})
	aadd (_aRotAdic, {"Posicao fornecedor",       "U_SZIR(4)",0,2})
	aadd (_aRotAdic, {"Cadastro fornecedor",      "U_SZIR(5)",0,2})
	aadd (_aRotAdic, {"Capital social",           "U_SZIR(6)",0,2})
//	aadd (_aRotAdic, {"Ficha cadastro associado", "U_SZIR(7)",0,2})
	aadd (_aRotAdic, {"Dados para fins de IR",    "U_SZIR(8)",0,2})
	aadd (_aRotAdic, {"Cons. titulos CP",         "U_SZIR(9)",0,2})
	aadd (_aRotAdic, {"Saldo na data base",       "U_SZIR(10)",0,2})
	aadd (_aRotAdic, {"Rel.saldos c.corr.",       "U_SZIR(11)",0,2})
	aadd (_aRotAdic, {"Consulta Fatura",          "U_SZIR(12)",0,2})
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
	aadd (aRotina, {"&Saldos"           , _aRotSald,  0,4})
	aadd (aRotina, {"&Outras consultas" , _aRotAdic,  0,4})
	aadd (aRotina, {"&Legenda"          , "U_SZILG (.F.)", 0,5})

	_ValidPerg ()
	if ! pergunte (cPerg, .T.)
		return
	endif

	_lCtOnLine = (mv_par02 == 1)

	// Filtra browse.
	if mv_par01 == 1
		_cCondicao := '!szi->zi_tm$"' + _oCtaCorr:TMCapital + '"'
	elseif mv_par01 == 2
		_cCondicao := 'szi->zi_tm$"' + _oCtaCorr:TMCapital + '"'
	elseif mv_par01 == 2
		_cCondicao := '.t.'
	endif
	_bFilBrw := {|| FilBrowse(cString,@_aIndBrw,@_cCondicao) }
	Eval(_bFilBrw)
	DbSelectArea(cString)
	mBrowse(,,,,cString,,,,,2, _aCores)
	EndFilBrw(cString,_aIndBrw)
	DbSelectArea(cString)
	DbSetOrder(1)	// Reaplica filtro no mbrowse.
	Eval(_bFilBrw)
	DbClearFilter()
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function SZILG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"zi_saldo==0",        'BR_VERMELHO', 'Baixado'})
	aadd (_aCores, {"zi_saldo==zi_valor", 'BR_VERDE',    'Aberto'})
	aadd (_aCores, {"zi_saldo< zi_valor", 'BR_AMARELO',  'Baix.parcial'})
	//aadd (_aCores, {"zi_saldo==zi_valor.and.zi_tm!='14'", 'BR_VERDE',    'Aberto'})
	//aadd (_aCores, {"zi_saldo< zi_valor.and.zi_tm!='14'", 'BR_AMARELO',  'Baix.parcial'})
	//aadd (_aCores, {"zi_saldo==zi_valor.and.zi_tm=='14'", 'BR_LARANJA',  'Corr.mon.cred.aberto'})
	//aadd (_aCores, {"zi_saldo< zi_valor.and.zi_tm=='14'", 'BR_BRANCO',   'Corr.mon.cred.baix.parcial'})
	
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
// Chama execucao de relatorios (devem estar preparados para isto).
User Function SZIR (_nQual)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local cPerg      := ""
//	local _aBkpSX1   := {}
	local _sQuery    := ""
	local _aRetQry   := {}
	local _aCols     := {}
	local _aAuto     := {}
//	local _oAssoc    := NIL
//	local _sCRLF     := chr (13) + chr (10)
//	local _aSaldo    := {}
//	local _sMsg      := ""
	local _oCtaCorr  := NIL
//	local _oSQL      := NIL
	local _oAssocRel := NIL

	do case
	case _nQual == 1
		cPerg = "SZI_REL"
		U_GravaSX1 (cPerg, "01", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "02", szi -> zi_lojasso)
		U_GravaSX1 (cPerg, "03", szi -> zi_assoc)
		U_GravaSX1 (cPerg, "04", szi -> zi_lojasso)
		U_SZI_Rel ()
	case _nQual == 2
		cPerg = "MLXPAS"
		U_GravaSX1 (cPerg, "03", szi -> zi_assoc)  // Associado inicial
		U_GravaSX1 (cPerg, "04", szi -> zi_assoc)  // Associado final
		U_ML_PAss ()
	case _nQual == 3
		CursorWait ()
		_sQuery := ""
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
		CursorArrow ()
		if len (_aRetQry) == 0
			u_help ("Nao foi encontrada no financeiro nenhuma movimentacao relacionada a este lancamento.")
		else
			_aCols = {}
			aadd (_aCols, {1,  "Origem",    50,  ""})
			aadd (_aCols, {2,  "Data",      40,  "@D"})
			aadd (_aCols, {3,  "Tipo",      25,  ""})
			aadd (_aCols, {4,  "Pref",      25,  ""})
			aadd (_aCols, {5,  "Numero",    30,  ""})
			aadd (_aCols, {6,  "Parc",      15,  ""})
			aadd (_aCols, {7,  "Valor",     50,  "@E 999,999.99"})
			aadd (_aCols, {8,  "Historico", 100, ""})
			aadd (_aCols, {9,  "Banco",     30,  ""})
			aadd (_aCols, {10, "Mot.Bx",    30,  ""})
			aadd (_aCols, {11, "Tipo doc",  30,  ""})
			aadd (_aCols, {12, "Numerario", 30,  ""})
			aadd (_aCols, {13, "Form.pag.", 30,  ""})
			U_F3Array (_aRetQry, "Movimento financeiro", _aCols, oMainWnd:nClientWidth - 50, NIL, "Movimentacao financeira relacionada a este lancamento")
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
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + szi -> zi_assoc + szi -> zi_lojasso, .F.))
			u_help ("Fornecedor nao encontrado!")
		else
			_aAuto := {}
			aadd (_aAuto, {"A2_COD",  szi -> zi_assoc,   nil})
			aadd (_aAuto, {"A2_NOME", szi -> zi_lojasso, nil})
			MSExecAuto ({|_x, _y| MATA020 (_x, _y)}, _aAuto, 2)
		endif

	case _nQual == 6
		_oAssocRel := ClsAssoc():New(szi -> zi_assoc, szi -> zi_lojasso)
		u_log (valtype (_oAssocRel))
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
			U_IRAssoc ()
		endif

	case _nQual == 9
		// Verifica se existe titulo correspondente no financeiro.
		if ! U_TemNick ("SE2", "E2_VACHVEX")
			u_help ("Problema nos indices de arquivos. Acione suporte.")
			U_AvisaTI ("Falta indice para pesquisa de movto da conta corrente de associados na rotina " + procname ())
		else
			se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
			if se2 -> (dbseek (xfilial ("SE2") + &(_sChave), .F.))
				FC050Con ()
			else
				u_help ("Nao foi encontrado titulo correspondente no contas a pagar.")
			endif
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
		_wfatura = fBuscaCpo ('SE2', 6, xfilial('SE2') + szi -> zi_assoc + szi -> zi_lojasso + szi -> zi_serie + szi -> zi_doc + szi -> zi_parcela, "E2_TIPO")
		if _wfatura = 'FAT'
			// MOSTRA NOTAS CONSTANTES NA FATURA
			_sQuery  = " "
			_sQuery += " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_EMIS1, E2_VENCREA, E2_VALOR"
	    	_sQuery += "      , E2_FATURA"
			_sQuery += "   FROM SE2010"
	 		_sQuery += "  WHERE E2_FILIAL  = '" + xfilial ("SE2")  + "'"
	 		_sQuery += "    AND D_E_L_E_T_ = ''"
	 		_sQuery += "    AND E2_FORNECE = '" + szi -> zi_assoc  + "'"
	 		_sQuery += "    AND E2_LOJA    = '" + szi -> zi_lojasso  + "'"
	   		_sQuery += "    AND E2_FATURA  = '" + szi -> zi_doc  + "'"
	   		
	   		_aDados := U_Qry2Array(_sQuery)
	    	if len(_aDados) > 0 
	    		_aCols = {}
	    	
		    	aadd (_aCols, {1, "PREFIXO"       	   ,  30,  "@!"})
		    	aadd (_aCols, {2, "NUMERO"         	   ,  50,  "@!"})
		    	aadd (_aCols, {3, "PARCELA"            ,  20,  "@!"})
		    	aadd (_aCols, {4, "TIPO"               ,  20,  "@!"})
		    	aadd (_aCols, {5, "EMISSAO"        	   ,  30,  "@D"})
				aadd (_aCols, {6, "VENCIMENTO"         ,  30,  "@D"})
		    	aadd (_aCols, {7, "VALOR"              ,  50,  "@E 999,999.99"})
		        
	    		U_F3Array (_aDados, "Consulta Notas Referentes a Fatura " + szi -> zi_doc , _aCols, oMainWnd:nClientWidth - 50, NIL, "" )
	    		
			else
				msgalert("Não foram encontratdos pra essa consulta")
			endif
		else
			msgalert("Documento selecionado não eh uma fatura.")								
		endif

	case _nQual == 97  // Gera SE2 - Especifico para manutencoes e testes.
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		u_logobj (_oCtaCorr)
		if ! _oCtaCorr:GeraSE2 (_oCtaCorr:OQueGera (), _oCtaCorr:DtMovto, .F.)
			u_help (_oCtaCorr:UltMsg)
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



// --------------------------------------------------------------------------
// Alteracao.
User Function SZIA ()
	private altera   := .T.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	RegToMemory ("SZI", inclui, .T.)

	// Apos a alteracao do registro, faz os tratamentos necessarios.
	if axaltera ("SZI", szi -> (recno ()), 4) == 1//, NIL, NIL, NIL, "U_SZI1 ()") == 1
		u_log ('usuario confirmou alt.')
		u_log (m->zi_obs)

		// Grava campo memo.
		msmm (,,, m->zi_obs, 1,,, "SZI", "ZI_CODMEMO")

	endif
	u_logFim ()
return



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
		_oCtaCorr:Obs = m->zi_obs  // Os demais atributos jah estavam gravados no SZI.
		_lRet = _oCtaCorr:Grava (.T., .F.)
		CursorArrow ()
	endif
	u_logFim ()
return



// --------------------------------------------------------------------------
// Gera sequencial para novo registro do SZI. Faz bloqueio de semaforo para garantir sequencia exclusiva.
User Function SZISeq ()
	local _lRet     := .F.
	local _oCtaCorr := NIL
	_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
	_lRet = _oCtaCorr:GeraSeq ()
return _lRet



// --------------------------------------------------------------------------
// Valida inclusao.
User Function SZI1 ()
	local _lRet     := .T.
	local _aBcos    := {}
	local _aNaoBcos := {}
//	local _sQuery   := ""
//	local _sRetQry  := ""
//	local _dAniver  := ctod ("")
//	local _oDUtil   := NIL
//	local _oAssoc   := NIL
//	local _lEhSocio := .F.
	local _oCtaCorr := NIL

	if _lRet .and. m->zi_tm == '04'
		u_help ("Este tipo de movimento deve ser gerado via nota fiscal.")
		_lRet = .F.
	endif

//	_oAssoc := ClsAssoc():New (m->zi_assoc, m->zi_lojasso)
//	_lEhSocio := _oAssoc:EhSocio (m->zi_data)

/* MIGRADO para ClsCtaCorr em 28/11/2017
	// Verifica periodo fechado (correcao monetaria jah calculada).
	if _lRet
		_sQuery := ""
		_sQuery += "SELECT COUNT (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"  // O calculo eh feito separadamente por filial.
		_sQuery +=   " AND ZI_TM      IN " + FormatIn (_sTMCorrC + "/" + _sTMCorrD, '/')
		_sQuery +=   " AND ZI_DATA    > '" + dtos (m->zi_data) + "'"  // Eh gerada no dia 1 do mes subsequente.
		_sQuery +=   " AND ZI_FILORIG = ''"  // Transferencias de saldos recebidas de outras filiais nao sao consideradas como 'calculado nesta filial'.
		u_log (_squery)
		if U_RetSQL (_sQuery) > 0
			u_help ("Ja' existe calculo de correcao monetaria para este mes (ou posterior).")
			_lRet = .F.
		endif
	endif
*/
	// Associar / desassociar.
//	if _lRet .and. m->zi_tm $ '08/09'
//		if m->zi_tm == '08' .and. _lEhSocio
//			u_help ("Ja' consta como associado nesta data.")
//			_lRet = .F.
//		endif
//		if m->zi_tm == '09' .and. ! _lEhSocio
//			u_help ("Nao consta como associado nesta data.")
//			_lRet = .F.
//		endif
//	endif

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



// --------------------------------------------------------------------------
// Baixa do movimento. Gera movimentacao financeira caso necessario.
User Function SZIB ()
	local _nForma    := 0
	local _aBkpSX1   := {}
	local cPerg      := ""
	local _sOutrIni  := ""
	local _sOutrFim  := ""
//	local _oCtaCorr  := NIL
	local _lContinua := .T.

	u_logIni ()
	
	// Acho que o certo eh eliminar os titulos do SE2, mas agora nao tenho tempo para verificar. Robert, 05/09/2017
	if _lContinua .and. szi -> zi_tm == '19'
		u_help ('Este movimento so deve ser baixado ao resgatar cotas')
		_lContinua = .F.
	endif
	
	if _lContinua .and. szi -> zi_saldo <= 0
		u_help ("Nao ha saldo a ser baixado para este lancamento.")
		_lContinua = .F.
	endif

	if _lContinua

		// Verifica se existe titulo correspondente no financeiro.
		if ! U_TemNick ("SE2", "E2_VACHVEX")
			u_help ("Problema nos indices de arquivos. Acione suporte.")
			U_AvisaTI ("Falta indice para exclusao de movto da conta corrente de associados na rotina " + procname ())
		else
			se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
			if se2 -> (dbseek (xfilial ("SE2") + &(_sChave), .F.))

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
				case szi -> zi_tm == '01'
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
				u_log ("Variaveis private preparadas para as outras rotinas:")
				u_log ('   _SZI_Hist:', _SZI_Hist)
				u_log ('   _SZI_Deb: ', _SZI_Deb)
				u_log ('   _SZI_Cred:', _SZI_Cred)

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
					cPerg = 'FIN080'
					_aBkpSX1 = U_SalvaSX1 (cPerg)
					if _lCtOnLine
						U_GravaSX1 (cPerg, "01", 1)
						U_GravaSX1 (cPerg, "02", 2)
						U_GravaSX1 (cPerg, "03", 1)
					else
						U_GravaSX1 (cPerg, "03", 2)
					endif
					u_log ('Vou chamar FINA080')
					FINA080 (NIL, 3, .T.)
					u_log ('Retornou do FINA080')
					U_SalvaSX1 (cPerg, _aBkpSX1)
					
					// O P.E. generico FINA080 nao eh executado quando contabiliza on-line=NAO
					// (pelo menos quando executado da forma como chamei o FINA080 aqui).
					if ! _lCtOnLine
						U_FINA080 ()
					endif

				elseif _nForma == 2 .or. _nForma == 3
					cPerg = 'AFI340'
					_aBkpSX1 = U_SalvaSX1 (cPerg)
					U_GravaSX1 (cPerg, "01", 1)  // Considera loja: sim.
					if _nForma == 2
						U_GravaSX1 (cPerg, "02", 1)  // Considera fornecedor: original.
					elseif _nForma == 3
						U_GravaSX1 (cPerg, "02", 2)  // Considera fornecedor: original.
						U_GravaSX1 (cPerg, "03", _sOutrIni)  // Fornecedor nao original inicial.
						U_GravaSX1 (cPerg, "04", _sOutrFim)  // Fornecedor nao original final.
					endif
					U_GravaSX1 (cPerg, "05", 2)  // Considera filiais abaixo: nao (talvez permita compensar entre filiais, mas, por enquanto, preferimos nao tentar).
					U_GravaSX1 (cPerg, "10", 1)  // Compensa titulos: normais.
					U_GravaSX1 (cPerg, "12", 2)  // Compensa transferidos: nao.
					if _lCtOnLine
						U_GravaSX1 (cPerg, "08", 2)
						U_GravaSX1 (cPerg, "09", 1)
						U_GravaSX1 (cPerg, "11", 1)
					else
						U_GravaSX1 (cPerg, "11", 2)
					endif
					fina340 (3)
					U_SalvaSX1 (cPerg, _aBkpSX1)
				endif
				CursorArrow ()
			else
				u_help ("Nao encontrei titulo correspondente no financeiro.")
			endif
		endif
	endif
	u_logFim ()
return



// --------------------------------------------------------------------------
// Cancelar baixas
User Function SZIC ()
	local _nQueTipo := 0
	local _aBaixas  := {}
	local _oCtaCorr := NIL

	u_logIni ()
	if szi -> zi_saldo == szi -> zi_valor
		u_help ("Nao ha baixas para este lancamento.")
		return
	endif

	// Verifica se existe registro relacionado no financeiro.
	if ! U_TemNick ("SE2", "E2_VACHVEX")
		u_help ("Problema nos indices de arquivos. Acione suporte.")
		U_AvisaTI ("Falta indice para exclusao de movto da conta corrente de associados na rotina " + procname ())
	else
		// Verifica se existe titulo correspondente no financeiro.
		se2 -> (dbOrderNickName ("E2_VACHVEX"))  // E2_FILIAL+E2_VACHVEX
		if se2 -> (dbseek (xfilial ("SE2") + &(_sChave), .F.))
			u_log ("Achei SE2")
			_nQueTipo = aviso ("Forma de baixa", ;
			                   "Selecione o tipo de de baixa a ser cancelado", ;
			                   {"Normal", "Compensacao", "Cancelar"}, ;
			                   3, ;
			                   "Forma de baixa")
			u_log ("Usar tipo:", _nQueTipo)
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
		endif
	endif
	u_logFim ()
return



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
			u_help ("A transferencia para outra filial nao foi possivel:" + chr (13) + char (10) + _oCtaCorrT:UltMsg)
		endif
		CursorArrow ()
	endif

	//u_logFim ()
return



// --------------------------------------------------------------------------
// Recalcula saldo atual do lancamento.
User Function SZIRS (_nQual)
//	local _lContinua := .T.
	local _oCtaCorr  := NIL
	local _nSaldoAnt := 0
	local _oAssoc    := ""
	local _dDataIni  := ctod ('')

	if _nQual == 1  // Atualiza sando deste lcto.
		_oCtaCorr := ClsCtaCorr():New (szi -> (recno ()))
		_nSaldoAnt = szi -> zi_saldo
		_oCtaCorr:AtuSaldo ()

		if _nSaldoAnt != szi -> zi_saldo
			u_help ("Saldo alterado de " + cvaltochar (_nSaldoAnt) + " para " + cvaltochar (szi -> zi_saldo))
		endif

	elseif _nQual == 2  // Atualiza saldo geral do associado.
		_dDataIni = U_Get ('Data inicial para recalculo de saldos do associado', 'D', 8, '@D', '', date (), .F., '.T.')
		if ! empty (_dDataIni)
			u_log ('Recalculando saldo do associado')
			_oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
			if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
			else
				MsgRun ("Aguarde...", "Processando...", {|| _oAssoc:AtuSaldo (_dDataIni)})
			endif
		endif
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                 Help
	aadd (_aRegsPerg, {01, "Tipo de contas a visualizar   ", "N", 1,  0,  "",   "",    {"Normal", "Capital social", "Todas"}, "Tipo de conta corrente a ser visualizada"})
	aadd (_aRegsPerg, {02, "Contabiliza online            ", "N", 1,  0,  "",   "",    {"Sim", "Nao"},                        ""})
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
