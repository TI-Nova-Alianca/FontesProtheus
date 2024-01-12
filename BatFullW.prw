// Programa:  BatFullW
// Autor:     Robert Koch
// Data:      10/12/2014
// Descricao: Batches de integracao com FullWMS
//            Devem ser observados os formatos de dados enviados para o Fullsoft nas views de integracao.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Rotinas de integracao com FullWMS
// #PalavasChave      #batch #agendamento #automacao #integracao #fullsoft #fullwms #etiqueta #apontamento_producao
// #TabelasPrincipais #SD3 #SD1 #ZA1 #ZAG #SB2 #SB8
// #Modulos           #EST #PCP #OMS #FAT

// Historico de alteracoes:
// 15/01/2015 - Robert - Passa a gravar chaves no campo D3_VACHVEX para os movtos. de origem.
//                     - Passa a gravar D3_VAETIQ quando transf. ref. guarda de pallet.
// 27/01/2015 - Robert - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT.
// 29/01/2015 - Robert - Passa a validar qt. do SD3 e qt_exec do WMS quando guarda de pallet.
//                     - Melhoradas mensagens de avisos de erros.
//                     - Passa a usar maior data (SD3 X WMS) quando guarda de pallet.
// 28/06/2015 - Robert - Criado tratamento para retornos do FullWMS com referencia ao ZAB (devolucoes).
// 14/08/2015 - Robert - Campo status_protheus passa a ser considerado no filtro principal.
// 30/09/2015 - Robert - Tratamento para OP de reprocesso (leitura do D3_PERDA em vez do D3_QUANT).
// 05/10/2015 - Robert - Leitura da tabela tb_wms_entradas nao considera mais datas. Apenas campos 'status' e 'status_protheus'
// 10/11/2015 - Robert - Inicio de tratamento para avarias (tabela tb_wms_movimentacoes).
// 11/01/2016 - Robert - Mensagens de erro passam a ser tratadas como Avisos_para_TI e nao mais enviadas por e-mail para a logistica.
// 31/05/2017 - Robert - Movimenta somente quando qt.executada no Full = qt do Protheus
//                     - Novas opcoes de gravacao de status (falta estq, outros erros, etc)
// 14/06/2017 - Robert - Passa a transferir (guardar) com a data base e nao mais com data do apontamento.
// 03/05/2018 - Robert - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 29/10/2018 - Robert - Criado tratamento para entrada por NF e por solic.manual (tabela ZAG)
//                     - Entradas de producao vao passar a ter entrada_id iniciando por ZA1 e nao mais SD3 para uniformizar.
// 28/01/2019 - Robert - Ajuste na verificacao se a guarda jah havia sido feita (retornava sempre vazio).
// 08/04/2019 - Catia  - include TbiConn.ch 
// 06/06/2019 - Robert - Se o produto ainda nao existe no almoxarifado destino, cria-o, para nao bloquear a transferencia de estoque.
// 15/07/2019 - Robert - Quando entrada por NF (almox.02) movimenta somente se ja consta no campo qtde_mov.
// 24/09/2019 - Robert - Passa a tratar tambem as saidas do Full (para quando o AX 02 alimenta a producao)
// 06/05/2020 - Robert - Ajuste nome variavel _sChaveEx em msg de aviso.
// 07/08/2020 - Robert - Melhorados logs e mensagens de erro.
// 10/12/2021 - Robert - Nao atualizava status_protheus quando nao tinha quantidade executada nem movimentada na tb_wns_entrada.
// 03/08/2022 - Robert - Criado controle de semaforo para evitar 2 execucoes simultaneas; melhorado log (GLPI 12427)
// 21/09/2022 - Robert - Desabilitadas algumas partes das entradas (melhorias para integracao com ZAG)
//                     - Passa a usar ClsAviso() para as notificacoes.
// 13/12/2022 - Robert - Habilitada liberacao de transf.estq gerada pelo ZAG.
// 19/01/2023 - Robert - ClsTrEstq:Libera() nao tenta mais executar a transferencia no final.
// 27/01/2023 - Robert - Reescrito tratamento para entradas, que passa a ser 100% com etiquetas.
// 01/02/2023 - Robert - Chamada metodo ClsTrEstq:Libera() passava usuario errado no processamento de saidas.
// 03/02/2023 - Robert - Nas saidas do Full, se o item  nao controla notes no Protheus, nem consulta tb_wms_lotes.
// 11/03/2023 - Robert - Tabela ZAG passa a ter o campo ZAG_SEQ fazendo parte da chave primaria.
// 28/03/2023 - Robert - Habilitadas transf. do ax.31 para 01 (etiq. envasadas em terceiros).
// 12/06/2023 - Robert - Melhorias logs - GLPI 13677
// 21/06/2023 - Robert - Passa a ter array de status e gravar descritivo junto no campo status_protheus.
// 24/07/2023 - Robert - Criado status 6 (entradas por sol.transf. que tenha 'aceite negado').
//                     - Valida saldo alm.orig.antes de tentar transferir solic.manuais.
// 30/10/2023 - Robert - Nao tenta nova execucao se estiver com ZAG_EXEC=E
//

#Include "Protheus.ch"
#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function BatFullW (_sQueFazer, _sEntrID, _sSaidID)
	local _lRet      := .T.
	local _nLock     := 0
	private _aStatProt := {}  // Deixar PRIVATE para ser vista pelas funcoes de entradas e saidas.

	// Define os possiveis valores para os campos 'status_protheus'.
	// Manter compatibilidade entre as tabelas tb_wms_entrada e tb_wms_pedidos !!!
	aadd (_aStatProt, {'1', 'Falta estq ERP'})
	aadd (_aStatProt, {'2', 'Outros erros'})
	aadd (_aStatProt, {'3', 'Executado no ERP'})
	aadd (_aStatProt, {'4', 'Qt Full # qt ERP'})
	aadd (_aStatProt, {'5', 'qtde_mov < qtde_exec'})  // (no caso de recebimento de producao)
	aadd (_aStatProt, {'6', 'solic.c/nao aceite'})
	aadd (_aStatProt, {'C', 'Cancelado no ERP'})

	// Define o que deve fazer: [E]ntradas, [S]aidas ou [A]mbas.
	_sQueFazer = iif (_sQueFazer == NIL, 'A', upper (_sQueFazer))

	// Abre a possibilidade de informar uma entrada_id ou saida_id especifica a ser processada.
	_sEntrID = iif (_sEntrID == NIL, '', _sEntrID)
	_sSaidID = iif (_sSaidID == NIL, '', _sSaidID)

	_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt + _sQueFazer, .F.)
	if _nLock == 0
		u_log2 ('erro', "Bloqueio de semaforo.")
	else

		// Verifica entradas (Protheus enviando para FullWMS)
		if _sQueFazer $ 'EA'
			u_log2 ('info', 'Iniciando processamento de entradas (Protheus -> FullWMS)')
			_Entradas (_sEntrID)
			u_log2 ('info', 'Finalizou processamento de entradas (Protheus -> FullWMS)')
		endif

		// Verifica saidas (FullWMS separando materiais para entregar ao Protheus)
		if _sQueFazer $ 'SA'
			u_log2 ('info', 'Iniciando processamento de saidas (FullWMS -> Protheus)')
			_Saidas (_sSaidID)
			u_log2 ('info', 'Finalizou processamento de saidas (FullWMS -> Protheus)')
		endif
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_log2 ('info', '----------- Final de execucao do ' + procname () + ' -----------')
return _lRet


// ------------------------------------------------------------------------------------
// Processa entradas no FullWMS
static function _Entradas (_sEntrID)
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nQtAUsar  := 0
	local _sEtiq     := ''
	local _oTrEstq   := NIL
	local _sChaveEx  := ""
	local _lRet      := .T.
	local _oEtiq     := NIL

	// Variavel para erros de rotinas automaticas. Deixar tipo 'private'.
 	if type ("_sErroAuto") != 'C'
		private _sErroAuto := ""
	endif

	za1 -> (dbsetorder(1))

	// Busca entradas finalizadas no Fullsoft.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " select tpdoc, codfor, entrada_id, coditem, qtde_exec, qtde_mov, dbo.VA_DatetimeToVarchar (dthr) as dthr, status"
	_oSQL:_sQuery +=   " from tb_wms_entrada"
	_oSQL:_sQuery +=  " where status = '3'"
	_oSQL:_sQuery +=    " and status_protheus not like '3%'"  // 3 = executado
	_oSQL:_sQuery +=    " and status_protheus not like 'C%'"  // C = cancelado: por que jah foi acertado manualmente, ou jah foi inventariado, etc.
	_oSQL:_sQuery +=    " and status_protheus not like '5%'"  // 5 = qtd.movimentada diferente qt.executada
	_oSQL:_sQuery +=    " and status_protheus not like '6%'"  // 6 = solicitacao de transferencia com nao aceite.
	if ! empty (_sEntrID)
		_oSQL:_sQuery += " and entrada_id = '" + _sEntrID + "'"
	endif
	_oSQL:_sQuery +=  " order by entrada_id"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		U_Log2 ('info', '[' + procname () + "]Verificando tb_wms_entrada.entrada_id = '" + (_sAliasQ) -> entrada_id + "'")

		// Alimenta variavel auxiliar para geracao de alquivo de log
		_sPrefLog = 'EntradaID ' + alltrim ((_sAliasQ) -> entrada_id)

		if (_sAliasQ) -> tpdoc != '6'
			u_help ("Sem tratamento para tpdoc = " + (_sAliasQ) -> tpdoc,, .t.)
			(_sAliasQ) -> (dbskip ())
			loop
		endif
		if (_sAliasQ) -> qtde_exec == 0 .and. (_sAliasQ) -> qtde_mov == 0
			u_help ("Sem quantidade executada nem movimentada",, .t.)
			(_sAliasQ) -> (dbskip ())
			loop
		endif

		// ACHO QUE ESTA AQUI AINDA NAO VOU PODER HABILITAR
		// if (_sAliasQ) -> qtde_exec < (_sAliasQ) -> qtde_mov
		// 	u_log2 ('aviso', 'Quant.movimentada menor que executada (no FullWMS).')
		// 	_AtuEntr ((_sAliasQ) -> entrada_id, '5')  // 5 = 'qtde movimentada menor que executada'
		// 	(_sAliasQ) -> (dbskip ())
		// 	loop
		// endif

		if left ((_sAliasQ) -> entrada_id, 3) != 'ZA1'
			u_help ("Sem tratamento para entrada_id diferente de ZA1 (sem etiqueta)",, .t.)
			(_sAliasQ) -> (dbskip ())
			loop
		endif

		_sEtiq = substr ((_sAliasQ) -> entrada_id, 6, 10)
	//	u_log2 ('debug', 'Identifiquei codigo de etiqueta = ' + _sEtiq)
		_oEtiq = ClsEtiq ():New (_sEtiq)
		if empty (_oEtiq:Codigo)
			u_help ("Etiqueta '" + _sEtiq + "' invalida." + _oEtiq:UltMsg,, .t.)
			(_sAliasQ) -> (dbskip ())
			loop
		endif
	//	U_Log2 ('debug', '[' + procname () + '] etiqueta instanciada.')

		// Se for uma etiqueta de apontamento de producao
		if ! empty (_oEtiq:OP)
			if _oEtiq:QtRE4 > 0 .or. _oEtiq:QtDE4 > 0
				u_help ("Guarda da producao gerada pela etiqueta '" + _oEtiq:Codigo + "' ja iniciada/realizada.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'jah executado no ERP'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			if _oEtiq:QtApontada == 0 .and. _oEtiq:QtPerdida == 0
				u_help ("Qt.apontada e qt.perdida(em caso de reprocesso) zeradas para a etiqueta " + _oEtiq:Codigo,, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Verifica se a quantidade apontada com esta etiqueta precisa ser transferida para o almox. 01
			if ! _oEtiq:AlmApontOP $ '11/31'
				u_help ("Apontamento de producao gerado pela etiqueta '" + _oEtiq:Codigo + "' foi feito no almox. '" + _oEtiq:AlmApontOP + "', para o qual nao tenho tratamento aqui.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Quando for OP de reprocesso, considera o campo D3_PERDA.
			if _oEtiq:FinalidOP == 'R'  // OP de retrabalho.
				_nQtAUsar = _oEtiq:QtPerdida
			else
				_nQtAUsar = _oEtiq:QtApontada
			endif
			if _nQtAUsar != (_sAliasQ) -> qtde_exec  // no futuro quero usar o campo "qtde_mov" mas o Full ainda nao ta gravando
				u_help ("Apontamento de producao gerado pela etiqueta '" + _oEtiq:Codigo + "' tem quantidade = " + cvaltochar (_nQtAUsar) + ", mas a quant.movimentada no Full foi de " + cvaltochar ((_sAliasQ) -> qtde_exec),, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
		
			// Verifica se vai ter estoque suficiente para transferir.
			sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
	//		U_Log2 ('debug', '[' + procname () + ']produto = ' + _oEtiq:Produto)
	//		U_Log2 ('debug', '[' + procname () + '] alm.apont.op = ' + _oEtiq:AlmApontOP)
	//		U_Log2 ('debug', '[' + procname () + '] _nQtAUsar = ' + cvaltochar (_nQtAUsar))
			if ! sb2 -> (dbseek (xfilial ("SB2") + _oEtiq:Produto + _oEtiq:AlmApontOP, .F.)) .or. sb2 -> b2_qatu < _nQtAUsar
				u_help ("Apont.prod.etiq. '" + _oEtiq:Codigo + "': sem saldo estoque produto '" + alltrim (_oEtiq:Produto) + "' no ax. '" + _oEtiq:AlmApontOP + "' para transferir.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Gera a transferencia.
			_sChaveEx = 'Full' + alltrim ((_sAliasQ) -> entrada_id)
			if _GeraTran (_oEtiq:Produto, '', _nQtAUsar, _oEtiq:AlmApontOP, '01', '', '', 'GUARDA PALLET ' + alltrim ((_sAliasQ) -> codfor), alltrim ((_sAliasQ) -> codfor), _sChaveEx)
				_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'executado'
			else
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
			endif

		// Etiqueta gerada para atender a uma solicitacao de transferencia de outro almox.
		elseif ! empty (_oEtiq:IdZAG)
			
			// Deixa objeto instanciado com a solicitacao original de transferencia
			_oTrEstq := ClsTrEstq ():New (xfilial ("ZAG") + _oEtiq:IdZAG)
			if empty (_oTrEstq:Docto)
				u_help ("Nao foi possivel instanciar objeto _oTrEstq com base no ID '" + _oEtiq:IdZAG + "'",, .t.)
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			
	//		U_Log2 ('debug', '[' + procname () + ']sol.transf.instanciada')
	//		u_logObj (_oTrEstq)

			if _oTrEstq:Executado == 'S'  // Se jah foi executado anteriormente...
				u_log2 ('aviso', 'Transferencia consta como jah executada na tabela ZAG.')
				_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			if _oTrEstq:Executado == 'E'  // Erro na execucao
				u_log2 ('aviso', 'Transferencia consta como ERRO na execucao anterior.')
			//	_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outros erros'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			
			if ! empty (_oTrEstq:MotNAc)
				U_Log2 ('debug', '[' + procname () + ']Solicitacao de transferencia com NAO ACEITE (motivo = ' + cvaltochar (_oTrEstq:MotNAc))
				_AtuEntr ((_sAliasQ) -> entrada_id, '6')  // Atualiza a tabela do Fullsoft como 'nao aceite'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
	
			// Verifica se pode fazer a liberacao do almox.destino (01) cfe. retorno do FullWMS.
			if ! _oTrEstq:AlmUsaFull (_oTrEstq:AlmDest)
				u_log2 ('aviso', 'Alm.destino nao usa FullWMS e, portanto, nao tem tratamento aqui.')
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Verifica se tem estoque disponivel no almox origem.
	//		U_Log2 ('debug', '[' + procname () + ']produto = ' + _oTrEstq:ProdOrig)
	//		U_Log2 ('debug', '[' + procname () + '] alm.orig = ' + _oTrEstq:AlmOrig)
	//		U_Log2 ('debug', '[' + procname () + '] QtdSolic = ' + cvaltochar (_oTrEstq:QtdSolic))
			sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
			if ! sb2 -> (dbseek (xfilial ("SB2") + _oTrEstq:ProdOrig + _oTrEstq:AlmOrig, .F.)) .or. sb2 -> b2_qatu < _oTrEstq:QtdSolic
				u_help ("Solic.transf. '" + _oTrEstq:Docto + "': sem saldo estoque produto '" + alltrim (_oTrEstq:ProdOrig) + "' no ax. '" + _oTrEstq:AlmOrig + "' para transferir.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Verifica se ha necessidade de fazer liberacao pelo lado do FullWMS.
			if empty (_oTrEstq:UsrAutDst)
				U_Log2 ('debug', '[' + procname () + ']Falta liberacao do almox.destino')
				if (_sAliasQ) -> qtde_exec != _oTrEstq:QtdSolic
					u_log2 ('aviso', 'Quant.executada (no FullWMS) diferente da solicitada.')
					_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // 4 = diferenca na quantidade
					(_sAliasQ) -> (dbskip ())
					loop
				else
					_oTrEstq:Libera (.T., 'FULLWMS')
				endif
			endif

			// Tenta executar a transferencia.
			if ! _oTrEstq:Executa (.t.)
				U_Log2 ('debug', '[' + procname () + ']Ultima mensagem do objeto _oTrEstq = ' + cvaltochar (_oTrEstq:UltMsg))
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // 2 = outros erros
			endif
		endif

		// Limpa variavel auxiliar para geracao de alquivo de log
		_sPrefLog = ''

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())


return _lRet


// ------------------------------------------------------------------------------------
// Processa saidas do FullWMS
static function _Saidas (_sSaidID)
	local _lRet      := .T.
	local _sMsg      := ""
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _oTrEstq   := NIL
	local _sChaveZAG := ''
	local _aLotes    := {}
	local _nLote     := 0
	local _lLotesOK  := .T.
	local _nSomaLote := 0
	local _oTrOrig   := NIL

	// Variavel para erros de rotinas automaticas. Deixar tipo 'private'.
 	if type ("_sErroAuto") != 'C'
		private _sErroAuto := ""
	endif

	// Busca separacoes finalizadas no Fullsoft.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " select saida_id, coditem, qtde_exec"
	_oSQL:_sQuery +=   " from tb_wms_pedidos"
	_oSQL:_sQuery +=  " where empresa = 1"
	_oSQL:_sQuery +=    " and saida_id not like 'DAK%'"  // As separacoes de cargas OMS sao simplesmente faturadas via NF.
	_oSQL:_sQuery +=    " and saida_id like 'ZAG%'"
	_oSQL:_sQuery +=    " and status  = '6'"
	_oSQL:_sQuery +=    " and tpdoc   = '1'"
	_oSQL:_sQuery +=    " and status_protheus not like '3%'"  // 3 = executado
	_oSQL:_sQuery +=    " and status_protheus not like 'C%'"  // C = cancelado: por que jah foi acertado manualmente, ou jah foi inventariado, etc.
	_oSQL:_sQuery +=    " and status_protheus not like '5%'"  // 5 = estornado
	if ! empty (_sSaidID)
		_oSQL:_sQuery += " and saida_id = '" + _sSaidID + "'"
	endif
	_oSQL:_sQuery +=  " order by saida_id"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		U_Log2 ('info', '[' + procname () + "]Verificando tb_wms_pedidos.saida_id = '" + (_sAliasQ) -> saida_id + "'")
		do case
		case left ((_sAliasQ) -> saida_id, 3) == 'ZAG'

			// Alimenta variavel auxiliar para geracao de alquivo de log
			_sPrefLog = 'SaidaID ' + alltrim ((_sAliasQ) -> saida_id)

			_sChaveZAG = substr ((_sAliasQ) -> saida_id, 6, 12)  // Chave composta por ZAG + filial + chave_do_ZAG cfe. view v_wms_pedido
			zag -> (dbsetorder (1))  // ZAG_FILIAL, ZAG_DOC, ZAG_SEQ
			if ! zag -> (dbseek (xfilial ("ZAG") + _sChaveZAG, .F.))
				_sMsg = 'ZAG nao localizado com chave >>' + _sChaveZAG + '<<'
				u_help (_sMsg,, .t.)
				_oBatch:Mensagens += _sMsg + '; '
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			if zag -> zag_filori != cFilAnt
				_sMsg = 'Sol.transf.gerada na filial ' + zag -> zag_filori + ' e deve ser executada la.'
				u_help (_sMsg,, .t.)
				_oBatch:Mensagens += _sMsg + '; '
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Deixa objeto instanciado com a solicitacao original de transferencia
			_oTrOrig := ClsTrEstq ():New (zag -> (recno ()))
			if empty (_oTrOrig:Docto)
				u_help ("Nao foi possivel instanciar objeto _oTrEstq",, .t.)
				loop
			endif
			if _oTrOrig:Executado == 'S'  // Se jah foi executado anteriormente...
				u_log2 ('aviso', 'Transferencia consta como jah executada na tabela ZAG.')
				_AtuSaid ((_sAliasQ) -> saida_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			if _oTrOrig:Executado == 'E'  // Erro na execucao
				u_log2 ('aviso', 'Transferencia consta como ERRO na execucao anterior. Nao tentarei novamente de forma automatica.')
				// _AtuSaid ((_sAliasQ) -> saida_id, '2')  // Atualiza a tabela do Fullsoft como 'outros erros'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			
			sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
			if ! sb2 -> (dbseek (xfilial ("SB2") + zag -> zag_prdori + zag -> zag_almori, .F.)) .or. sb2 -> b2_qatu < (_sAliasQ) -> qtde_exec
				_sMsg = 'Falta estq prod. ' + alltrim (zag -> zag_prdori) + ' alm. ' + zag -> zag_almori + '. Saldo=' + cvaltochar (sb2 -> b2_qatu) + ' Qt.solicitada:' + cvaltochar (zag -> zag_qtdsol)
				_AtuSaid ((_sAliasQ) -> saida_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
				u_help (_sMsg,, .t.)
				_oBatch:Mensagens += _sMsg + '; '
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			if zag -> zag_qtdsol != (_sAliasQ) -> qtde_exec
				_sMsg = "Diferenca! Qt.solicitada: " + cvaltochar (zag -> zag_qtdsol) + "; Qt.movim.FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec)
				_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
				u_help (_sMsg,, .t.)
				_oBatch:Mensagens += _sMsg + '; '
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Se o produto controla lotes no Protheus, quero manter
			// consistencia com os lotes separados pelo Full.
			//
			// Futuramente pretendo ler SEMPRE a tabela tb_wms_lotes,
			// pois quando estah vazia indica que a forçaram o
			// encerramento da separacao no Full.
			if _oTrOrig:CtrLotOrig
				// Verifica quais os lotes separado pelo Full. Se apenas um, atualiza na solicitacao original de transferencia;
				// Se mais de um, replica a solicitacao (uma para cada lote) visando manter os lotes no Protheus iguais aos do Full.
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " select substring (lote, 1, 10), qtde"
				_oSQL:_sQuery +=   " from tb_wms_lotes"
				_oSQL:_sQuery +=  " where empresa = 1"
				_oSQL:_sQuery +=    " and documento_id = '" + (_sAliasQ) -> saida_id + "'"
				_oSQL:_sQuery +=  " order by lote"
				_oSQL:Log ()
				_aLotes = _oSQL:Qry2Array (.F., .F.)
				u_log2 ('info', 'Lotes separados pelo Full:')
				u_log2 ('info', _aLotes)

				// Faz algumas validacoes para saber se vai conseguir transferir todos os lotes.
				_lLotesOK = .T.
				_nSomaLote = 0
				for _nLote = 1 to len (_aLotes)
					_nSomaLote += _aLotes [_nLote, 2]
				next
				if _nSomaLote != (_sAliasQ) -> qtde_exec
					_lLotesOK = .F.
					_sMsg = "Inconsistencia no FulLWMS: Soma qt.separadas por lotes difere da qtde_exec"
					_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
					u_help (_sMsg,, .t.)
					_oBatch:Mensagens += _sMsg + '; '
					(_sAliasQ) -> (dbskip ())
					loop
				endif

				// Se o produto controla lotes, confere saldos (no Protheus) dos lotes separados.
				if _lLotesOK .and. _oTrOrig:CtrLotOrig
					sb8 -> (dbsetorder (3)) // B8_FILIAL, B8_PRODUTO, B8_LOCAL, B8_LOTECTL, B8_NUMLOTE, B8_DTVALID, R_E_C_N_O_, D_E_L_E_T_
					for _nLote = 1 to len (_aLotes)
						if ! sb8 -> (dbseek (_oTrOrig:FilOrig + _oTrOrig:ProdOrig + _oTrOrig:AlmOrig + _aLotes [_nLote, 1], .F.))
							_sMsg = "Lote '" + _aLotes [_nLote, 1] + "' nao localizado para o produto '" + _oTrOrig:ProdOrig + "'"
							_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
							u_help (_sMsg,, .t.)
							_oBatch:Mensagens += _sMsg + '; '
							_lLotesOK = .F.
							exit
						endif
						u_log2 ('debug', 'comparando b8_saldo = ' + cvaltochar (sb8 -> b8_saldo) + ' com _aLotes [_nLote, 2] = ' + cvaltochar (_aLotes [_nLote, 2]))
						if sb8 -> b8_saldo < _aLotes [_nLote, 2]
							_sMsg = "Saldo insuficiente lote " + _aLotes [_nLote, 1] + " do produto " + _oTrOrig:ProdOrig
							_AtuSaid ((_sAliasQ) -> saida_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
							u_help (_sMsg,, .t.)
							_oBatch:Mensagens += _sMsg + '; '
							_lLotesOK = .F.
							exit
						endif
					next
				endif
			else
				// Cria um lote de faz-de-conta para processar a transferencia.
				_aLotes = {{'', _oTrOrig:QtdSOlic}}
			endif
			if ! _lLotesOK
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			if _lLotesOK
				for _nLote = 1 to len (_aLotes)

					// Se tiver mais de um lote, preciso gerar novo(s) registro(s) no ZAG (um para cada lote).
					if _nLote == 1  // Jah estou posicionado na solicitacao original gerada pelo Protheus
						U_Log2 ('debug', '[' + procname () + ']Transferindo pelo ZAG original')
						_oTrEstq := _oTrOrig
						_oTrEstq:LoteOrig = _aLotes [_nLote, 1]
						_oTrEstq:QtdSolic = _aLotes [_nLote, 2]
					else
						u_help ("AQUI DEVE SER ALIMENTADO O CAMPO DE SEQUENCIA PRA MANTER AMARRACAO COM SOLICITACAO ORIGINAL",, .T.)
						u_log2 ('debug', 'Gerando novo ZAG')
						_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
						_oTrEstq:Filial    = _oTrOrig:Filial
						_oTrEstq:FilOrig   = _oTrOrig:FilOrig
						_oTrEstq:FilDest   = _oTrOrig:FilDest
						_oTrEstq:DtEmis    = _oTrOrig:DtEmis
						_oTrEstq:OP        = _oTrOrig:OP
						_oTrEstq:Motivo    = alltrim (_oTrOrig:Motivo) + "-lote adicional"
						_oTrEstq:ProdOrig  = _oTrOrig:ProdOrig
						_oTrEstq:ProdDest  = _oTrOrig:ProdDest
						_oTrEstq:AlmOrig   = _oTrOrig:AlmOrig
						_oTrEstq:AlmDest   = _oTrOrig:AlmDest
						_oTrEstq:FullWOrig = _oTrOrig:FullWOrig
						_oTrEstq:FullWDest = _oTrOrig:FullWDest
						_oTrEstq:LoteOrig  = _oTrOrig:_aLotes [_nLote, 1]
						_oTrEstq:QtdSolic  = _oTrOrig:_aLotes [_nLote, 2]
					endif

					// Chama a rotina de liberacao do docto. Se estiver em condicoes, a transferencia jah serah executada.
					U_Log2 ('debug', '[' + procname () + ']Chamando liberacao do ZAG')
					_oTrEstq:Libera (.F., 'FULLWMS')
					_oTrEstq:Executa ()  // Tenta executar, pois as liberacoes podem ter tido exito.
					U_Log2 ('debug', '[' + procname () + ']Transf.retornou com :EXECUTADO = ' + _oTrEstq:Executado)
					if _oTrEstq:Executado == 'S'
						_AtuSaid ((_sAliasQ) -> saida_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
					elseif _oTrEstq:Executado == 'E'
						_AtuSaid ((_sAliasQ) -> saida_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
					endif
				next
			endif

			// Limpa variavel auxiliar para geracao de alquivo de log
			_sPrefLog = ''

		otherwise
			u_help ("Sem tratamento para tpdoc / saida_id '" + (_sAliasQ) -> tpdoc + (_sAliasQ) -> saida_id + "' da tabela 'tb_wms_pedidos'.",, .t.)
		endcase
		u_log2 ('info', _sMsg)

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())

return _lRet


// --------------------------------------------------------------------------------------------
// Atualiza status (entradas) no FullWMS.
// Procurar manter, aqui, os mesmos codigos de status em todos os programas BatFull*, apesar de serem tabelas diferentes
static function _AtuEntr (_sEntrada, _sStatus)
	local _oSQL  := NIL
	local _nStat := 0
	local _lRet  := .F.

	_nStat = ascan (_aStatProt, {|_aVal| _aVal [1] == _sStatus})
	if _nStat == 0
		u_help ("Tentativa de gravar um status desconhecido ('" + cvaltochar (_sStatus) + "') na tabela tb_wms_entrada",, .t.)
		_lRet = .F.
	else
		// Concatena o descritivo do status, por que eh sempre uma complicacao
		// na hora de consultar essa tabela, sem saber o significado de cada um.
		// Vou habilitar compactacao da tabela no SQL, entao a existencia de
		// muitos registros com dados semelhantes vai reduzir o tamanho.
		_sStatus += '-' + _aStatProt [_nStat, 2]

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " update tb_wms_entrada"
		_oSQL:_sQuery +=    " set status_protheus = '" + _sStatus + "'"
		_oSQL:_sQuery +=  " where entrada_id = '" + _sEntrada + "'"
		_lRet = _oSQL:Exec ()
		if _sStatus != '3'  // 3=executado ok
			_oSQL:Log ()
		endif
	endif
return _lRet


// --------------------------------------------------------------------------------------------
// Atualiza status (saidas) no FullWMS.
// Procurar manter, aqui, os mesmos codigos de status em todos os programas BatFull*, apesar de serem tabelas diferentes
static function _AtuSaid (_sSaida, _sStatus)
	local _oSQL  := NIL
	local _nStat := 0
	local _lRet  := .F.

	_nStat = ascan (_aStatProt, {|_aVal| _aVal [1] == _sStatus})
	if _nStat == 0
		u_help ("Tentativa de gravar um status desconhecido ('" + cvaltochar (_sStatus) + "') na tabela tb_wms_pedidos",, .t.)
		_lRet = .F.
	else
		// Concatena o descritivo do status, por que eh sempre uma complicacao
		// na hora de consultar essa tabela, sem saber o significado de cada um.
		// Vou habilitar compactacao da tabela no SQL, entao a existencia de
		// muitos registros com dados semelhantes vai reduzir o tamanho.
		_sStatus += '-' + _aStatProt [_nStat, 2]

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " update tb_wms_pedidos"
		_oSQL:_sQuery +=    " set status_protheus = '" + _sStatus + "'"
		_oSQL:_sQuery +=  " where saida_id = '" + _sSaida + "'"
		_lRet = _oSQL:Exec ()
		if _sStatus != '3'  // 3=executado ok
			_oSQL:Log ()
		endif
	endif
return _lRet


// --------------------------------------------------------------------------------------------
// Gera transferencia de estoque.
static function _GeraTran (_sProduto, _sLote, _nQuant, _sAlmOrig, _sAlmDest, _sEndOrig, _sEndDest, _sMotivo, _sEtiq, _sChvEx)
	local _lRet      := .T.
	local _sDocTrans := ''
	local _aAuto261  := {}
	local _aItens    := {}
	local _oSQL      := NIL
	local _aRegsSD3  := {}
	private lMsErroAuto := .F.

//	u_log2 ('debug', '[' + procname () + '] param recebidos: ' + cvaltochar ( _sProduto) + cvaltochar ( _sLote) + cvaltochar ( _nQuant) + cvaltochar ( _sAlmOrig) + cvaltochar ( _sAlmDest) + cvaltochar ( _sEndOrig) + cvaltochar ( _sEndDest) + cvaltochar ( _sMotivo) + cvaltochar ( _sEtiq) + cvaltochar ( _sChvEx))

	// Se o produto ainda nao existe no almoxarifado destino, cria-o, para nao bloquear a transferencia de estoque.
	sb2 -> (dbsetorder (1))
	if ! sb2 -> (dbseek (xfilial ("SB2") + _sProduto + _sAlmDest))
		u_log2 ('info', 'Criando saldos iniciais')
		CriaSB2 (_sProduto, _sAlmDest)
	endif

	_sErroAuto := ""  // Variavel para erros de rotinas automaticas. Deixar tipo 'private'.
	_sDocTrans := CriaVar ("D3_DOC")
	aadd(_aAuto261,{_sDocTrans,dDataBase})
	aadd(_aItens, _sProduto)   // Produto origem
	aadd(_aItens,'')           //D3_DESCRI			Descricao do Produto Origem
	aadd(_aItens,'')           //D3_UM				Unidade de Medida Origem
	aadd(_aItens,_sAlmOrig)    //Almox origem
	aadd(_aItens,_sEndOrig)    //Endereco origem
	aadd(_aItens,_sProduto)    //Codigo do produto destino (inicilmente a ideia eh sempre transferir para o mesmo produto)
	aadd(_aItens,'')           //D3_DESCRI			Descricao do Produto de Destino
	aadd(_aItens,'')           //D3_UM				Unidade de Medida de Destino
	aadd(_aItens,_sAlmDest)    //Almox destino
	aadd(_aItens,_sEndDest)    //Endereco destino
	aadd(_aItens,"")           //D3_NUMSERI			Numero de Serie
	aadd(_aItens,_sLote)       //Lote origem
	aadd(_aItens,"")           //D3_NUMLOTE			Numero do lote
	aadd(_aItens,ctod(""))     //D3_DTVALID			Validade Origem
	aadd(_aItens,0)            //D3_POTENCI			PotÍncia
	aadd(_aItens,_nQuant)      // Quantidade
	aadd(_aItens,0)            //D3_QTSEGUM			Segunda Quantidade
	aadd(_aItens,criavar("D3_ESTORNO"))  //D3_ESTORNO			Estorno
	aadd(_aItens,criavar("D3_NUMSEQ"))   //D3_NUMSEQ 			Numero de Sequencia
	aadd(_aItens,_sLote)                 // Lote destino
	aadd(_aItens,ctod(""))               // D3_DTVALID			Validade de Destino
	aadd(_aItens,criavar("D3_ITEMGRD"))  // D3_ITEMGRD			Item Grade
	aadd(_aItens,'')                     // D3_OBSERVA
	aadd(_aItens,_sMotivo)               // motivo
	aadd(_aItens,ctod (''))              // dt digit (vai ser gravado pelo SQL)
	aadd(_aItens,'')                     // hr digit (vai ser gravado pelo SQL)
	aadd(_aItens,_sEtiq)                 // D3_VAETIQ Etiqueta
	aadd(_aItens,_sChvEx)                // Chave externa D3_VACHVEX
//	U_Log2 ('debug', '[' + procname () + ']_aItens:')
//	U_Log2 ('debug', _aItens)
	aadd(_aAuto261, aclone (_aItens))
	
	lMsErroAuto := .F.
	MSExecAuto({|x,y| mata261(x,y)},_aAuto261,3) //INCLUSAO

	// Ja tive casos de nao gravar e tambem nao setar a variavel lMsErroAuto. Por isso vou conferir a gravacao.
	if ! lMsErroAuto
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=    " AND D3_VAETIQ  = '" + _sEtiq + "'"
		_oSQL:_sQuery +=    " AND D3_VACHVEX = '" + _sChvEx + "'"
		_aRegsSD3 := aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aRegsSD3) != 2
			u_help ("Problemas na gravacao da transferencia. Nao encontrei os dois registros que deveriam ter sido gravados. Query para conferencia: " + _oSQL:_sQuery,, .t.)
			lMsErroAuto = .T.
		endif
	endif

	if lMsErroAuto
		if ! empty (NomeAutoLog ())
			_sErroAuto += U_LeErro (memoread (NomeAutoLog ()))
		endif
		u_help ('Problemas rot.aut.transf.estoque: ' + _sErroAuto,, .t.)
		_lRet = .F.
	else
		U_LOG2 ('info', 'Transf. estq gerada. D3_VACHVEX: ' + _sChvEx + ' Prod.: ' + alltrim (_sProduto) + ' AX ' + _sAlmOrig + '->' + _sAlmDest + ' qt: ' + cvaltochar (_nQuant))
	endif
return _lRet


/* Por enquanto nem estamos usando
// --------------------------------------------------------------------------------------------
// Consulta NaWeb para ver se tem (ou necessita) inspecao.
static function _VerInsp(_sProduto, _sEtiqueta)
	Local _sXML := ""
	Local _sRet := ""

	_sXML += '<SdtNucParametro xmlns="NAWeb">'
	_sXML += '    <SdtNucParametroItem>'
	_sXML += '        <SdtNucParametroNome>Funcionalidade</SdtNucParametroNome>'
	_sXML += '        <SdtNucParametroValor>VERIFICA_INSPECAO</SdtNucParametroValor>'
	_sXML += '    </SdtNucParametroItem>'
	_sXML += '    <SdtNucParametroItem>'
	_sXML += '        <SdtNucParametroNome>TrnPcpInspProdProCod</SdtNucParametroNome>'
	_sXML += '        <SdtNucParametroValor>' + _sProduto + '</SdtNucParametroValor>'
	_sXML += '    </SdtNucParametroItem>'
	_sXML += '    <SdtNucParametroItem>'
	_sXML += '        <SdtNucParametroNome>TrnPcpInspTipoMom</SdtNucParametroNome>'
	_sXML += '        <SdtNucParametroValor>ATL</SdtNucParametroValor>'
	_sXML += '    </SdtNucParametroItem>'
	_sXML += '    <SdtNucParametroItem>'
	_sXML += '        <SdtNucParametroNome>TrnPcpInspProdChaTip</SdtNucParametroNome>'
	_sXML += '        <SdtNucParametroValor>ETQ</SdtNucParametroValor>'
	_sXML += '    </SdtNucParametroItem>'
	_sXML += '    <SdtNucParametroItem>'
	_sXML += '        <SdtNucParametroNome>TrnPcpInspProdCha</SdtNucParametroNome>'
	_sXML += '        <SdtNucParametroValor>' + _sEtiqueta + '</SdtNucParametroValor>'
	_sXML += '    </SdtNucParametroItem>'
	_sXML += '</SdtNucParametro>'		

	oAnexo := WSPrcNucWebService():New()
	oAnexo:cEntrada := _sXML
	oAnexo:Execute()
	_sRet = oAnexo:cSaida
	
return _sRet
*/
