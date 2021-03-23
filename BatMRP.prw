
// Programa:   BatMRP
// Autor:      Robert Koch
// Data:       10/06/2015
// Descricao:  Execucao automatica do calculo do MRP.
//
// Historico de alteracoes:
// 23/09/2015 - Robert - Recebe parametros com qt. periodos a processar
// 15/10/2015 - Robert - Incluidos parametros 31 e 32.
// 04/08/2016 - Robert - Novos parametros MATA710 no Protheus 12.
//

// --------------------------------------------------------------------------
user function BatMRP (_nQtPeriod)
	local _oSQL     := NIL
	local _sMsg     := ""
	local _lRet     := .T.
	local _aParAuto := {}
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog ()
	u_logIni ()
	u_logDH ()

	_nQtPeriod := iif (_nQtPeriod == NIL, 150, _nQtPeriod)

	// Ajusta parametros da rotina
	cPerg := "MTA712"
	U_GravaSX1 (cPerg, "01", 2)  // Processamento do MRP? (Prev Venda/PMP)
	U_GravaSX1 (cPerg, "02", 2)  // Geracao de S.Compra? (Por OP/pornecessidade)
	U_GravaSX1 (cPerg, "03", 1)  // Geracao OP PIs? (Por OP/pornecessidade)
	U_GravaSX1 (cPerg, "04", 1)  // Selecao para geracao OP/SC (Junto/separado)
	U_GravaSX1 (cPerg, "05", stod ('20180101'))  // PMP/Prev. Venda De?
	U_GravaSX1 (cPerg, "06", stod ('20211231'))  // PMP/Prev. Venda Ate?
	U_GravaSX1 (cPerg, "07", 1)  // Incrementa Numeracao OP? (por item/por numero)
	U_GravaSX1 (cPerg, "08", '')  // De  Armazem?
	U_GravaSX1 (cPerg, "09", 'zz')  // Ate Armazem?
	U_GravaSX1 (cPerg, "10", 2)  // Gera OPs/SCs? (Firmes/previstas)
	U_GravaSX1 (cPerg, "11", 1)  // Apaga OPs/SCs Previstas? (Sim/Nao)
	U_GravaSX1 (cPerg, "12", 1)  // Considera Sab.Dom.? (sim/nao)
	U_GravaSX1 (cPerg, "13", 2)  // Cons. OPs Suspensas? (sim/nao)
	U_GravaSX1 (cPerg, "14", 1)  // Cons. OPs Sacramentadas? (sim/nao)
	U_GravaSX1 (cPerg, "15", 1)  // Recalcula Niveis estrut? (sim/nao)
	U_GravaSX1 (cPerg, "16", 1)  // Gera OPs Agluts.? (sim/nao)
	U_GravaSX1 (cPerg, "17", 1)  // Ped.venda colocados? (subtrai/nao subtrai)
	U_GravaSX1 (cPerg, "18", 1)  // Saldo estoque? (atual/movimento)
	U_GravaSX1 (cPerg, "19", 1)  // Ao atingir estq max (qt.orig/ajusta estq.max)
	U_GravaSX1 (cPerg, "20", 2)  // Qt. nossa poder 3os? (soma/ignora)
	U_GravaSX1 (cPerg, "21", 2)  // Qt. 3os nosso poder? (subtrai/ignora)
	U_GravaSX1 (cPerg, "22", 2)  // Saldo rejeitado pelo CQ.? (subtrai/nao subtrai)
	U_GravaSX1 (cPerg, "23", '')  // De doc. PV/PMP
	U_GravaSX1 (cPerg, "24", 'zzzzzz')  // Ate doc. PV/PMP
	U_GravaSX1 (cPerg, "25", 2)  // Saldo bloqueado lote (subtrai/nao subtrai)
	U_GravaSX1 (cPerg, "26", 1)  // Considera estq.seguranca (sim/nao/so necessidade)
	U_GravaSX1 (cPerg, "27", 1)  // Ped.venda bloq.credito (sim/nao)
	U_GravaSX1 (cPerg, "28", 1)  // Mostra saldos resumidos (sim/nao)
	U_GravaSX1 (cPerg, "29", 2)  // Detalha lotes vencidos (sim/nao)
	U_GravaSX1 (cPerg, "30", 2)  // Ped.venda faturados (subtrai da prev/nao subtrai)
	U_GravaSX1 (cPerg, "31", 1)  // Considera ponto de pedido (sim/nao)
	U_GravaSX1 (cPerg, "32", 1)  // Gera tabela necessidades (sim/nao)
	U_GravaSX1 (cPerg, "33", stod ('20180101'))  // Dt.ini.ped.faturados
	U_GravaSX1 (cPerg, "34", stod ('20201231'))  // Dt.fim.ped.faturados
	pergunte (cPerg, .F.)
	
	// Alimenta array da tela de interface do usuario (que nao vai aparecer).
	aadd (_aParAuto, 1)   // Periodo diario
	aadd (_aParAuto, _nQtPeriod)  // Quantidade de Periodos analisados
	aadd (_aParAuto, .F.) // Considera pedidos em carteira
	aadd (_aParAuto, .F.) // Log eventos
	aadd (_aParAuto, .F.) // Inverter selecao (tipos)
	aadd (_aParAuto, NIL) // Tipos
	aadd (_aParAuto, .F.) // Inverter selecao (grupos)
	aadd (_aParAuto, NIL) // Grupos
	
	// Executa o MRP
	u_log ('Executando MATA710 --> ', time ())
	MATA710 (.T., _aParAuto)
	u_log ('MATA710 executado --> ', time ())

	// Procura status de 'processo encerrado' no log da ultima execucao.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT COUNT (*)"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("CV8") + " FIM "
	_oSQL:_sQuery +=  " WHERE FIM.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND FIM.CV8_FILIAL = '" + xfilial ("CV8") + "'"
	_oSQL:_sQuery +=    " AND FIM.CV8_PROC   = 'MATA710'"
	_oSQL:_sQuery +=    " AND FIM.CV8_INFO   = '2'"
	_oSQL:_sQuery +=    " AND FIM.CV8_DATA + FIM.CV8_HORA >= "
	_oSQL:_sQuery +=        " (SELECT MAX (INICIO.CV8_DATA + INICIO.CV8_HORA)"
	_oSQL:_sQuery +=           " FROM " + RetSQLName ("CV8") + " INICIO "
	_oSQL:_sQuery +=          " WHERE INICIO.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=            " AND INICIO.CV8_FILIAL = FIM.CV8_FILIAL"
	_oSQL:_sQuery +=            " AND INICIO.CV8_PROC   = FIM.CV8_PROC"
	_oSQL:_sQuery +=            " AND INICIO.CV8_INFO   = '1')"
	u_log (_oSQL:_sQuery)
	if _oSQL:RetQry () == 0
		_sMsg := "O ultimo recalculo automatico do MRP nao foi finalizado corretamente na filial '" + cFilAnt + "'. Execute-o manualmente e verifique possiveis mensagens."
		_sMsg += "Parametros utilizados:" + chr (13) + chr (10) + U_LogSX1 (cPerg) + chr (13) + chr (10) + "Quantidade de periodos: " + cvaltochar (_nQtPeriod)
		u_log ('enviando a seguinte msg para os usuarios:', _sMsg)
		if type ("oMainWnd") == "O"  // Se tem interface com o usuario
			u_help (_sMsg)
		else
			U_ZZUNU ({'999'}, "Erro recalc. MRP filial " + cFilAnt, _sMsg)
		endif
		_lRet = .F.
	else
		_sMsg := "Calculo automatico do MRP finalizado com sucesso em " + dtoc (date ()) + " - " + time () + chr (13) + chr (10)
		_sMsg += "Parametros utilizados:" + chr (13) + chr (10) + U_LogSX1 (cPerg) + chr (13) + chr (10) + "Quantidade de periodos: " + cvaltochar (_nQtPeriod)
		U_ZZUNU ({'047'}, "Resumo calculo MRP filial " + cFilAnt, _sMsg)
	endif

	u_logFim ()
	_sArqLog = _sArqLog2
return _lRet
