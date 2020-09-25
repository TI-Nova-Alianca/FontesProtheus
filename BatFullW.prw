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
//

#Include "Protheus.ch"
#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function BatFullW ()
	local _lRet      := .T.

	// Verifica entradas (Protheus enviando para FullWMS)
	u_log2 ('info', 'Iniciando processamento de entradas')
	_Entradas ()
	u_log2 ('info', 'Finalizou processamento de entradas')

	// Verifica saidas (FullWMS separando materiais para entregar ao Protheus)
	u_log2 ('info', 'Iniciando processamento de saidas')
	_Saidas ()
	u_log2 ('info', 'Finalizou processamento de saidas')
	u_log2 ('info', '')  // Apenas para gerar una linha vazia.

return _lRet


// ------------------------------------------------------------------------------------
// Processa entradas no FullWMS
static function _Entradas ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
//	local _aRet260   := {}
//	local _sChaveSD1 := ""
	local _nQtAUsar  := 0
	local _dData     := ctod ('')
//	local _Inspe     := ""
	local _sEtiq     := ''
	local _oTrEstq   := NIL
	local _sChaveEx  := ""
//	local _aRegsSD3  := {}
	local _lRet      := .T.

	// Variavel para erros de rotinas automaticas. Deixar tipo 'private'.
 	if type ("_sErroAuto") != 'C'
		private _sErroAuto := ""
	endif

	// Busca entradas finalizadas no Fullsoft.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " select tpdoc, codfor, entrada_id, coditem, qtde_exec, qtde_mov, dbo.VA_DatetimeToVarchar (dthr) as dthr"
	_oSQL:_sQuery +=   " from tb_wms_entrada"
	_oSQL:_sQuery +=  " where status = '3'"
	_oSQL:_sQuery +=    " and status_protheus != '3'"  // 3 = executado
	_oSQL:_sQuery +=    " and status_protheus != 'C'"  // C = cancelado: por que jah foi acertado manualmente, ou jah foi inventariado, etc.
	_oSQL:_sQuery +=    " and status_protheus != '5'"  // 5 = estornado
	_oSQL:_sQuery +=  " order by entrada_id"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		_sChaveEx = 'Full' + alltrim ((_sAliasQ) -> entrada_id)

		if (_sAliasQ) -> qtde_exec == 0 .and. (_sAliasQ) -> qtde_mov == 0
			u_log2 ('aviso', 'Chave ' + _sChaveEx + ': sem quantidade executada nem movimentada')
			(_sAliasQ) -> (dbskip ())
			loop
		endif

		do case
		
		// Entradas em geral com etiqueta
		case (_sAliasQ) -> tpdoc $ '1/2' .and. left ((_sAliasQ) -> entrada_id, 3) == 'ZA1' .and. substr ((_sAliasQ) -> entrada_id, 4, 2) == cFilAnt
			_sEtiq = substr ((_sAliasQ) -> entrada_id, 6, 10)
			za1 -> (dbsetorder(1))
			if ! za1 -> (dbseek (xfilial ("ZA1") + _sEtiq, .F.))
				u_help ("Etiqueta '" + _sEtiq + "' nao encontrada na tabela ZA1",, .t.)
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			
			if ! empty (za1 -> za1_idZAG)  // Trata-se de entrada gerada por solicitacao de transferencia
				u_log2 ('info', "Entrada gerada pelo ZAG")
				zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC
				if ! zag -> (dbseek (xfilial ("ZAG") + za1 -> za1_idZAG, .F.))
					u_log2 ('aviso', "Documento de transferencia '" + za1 -> za1_idZAG + "' nao encontrado na tabela ZAG")
				else
					// Chama a rotina de liberacao do docto. Se estiver em condicoes, a transferencia jah serah executada.
					u_log2 ('info', 'Chamando liberacao do ZAG')
					_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
					_oTrEstq:Etiqueta = za1 -> za1_codigo
					_oTrEstq:Libera (.F., 'FULLWMS')
					if _oTrEstq:Executado == 'S'
						_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
					elseif _oTrEstq:Executado == 'E'
						_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
					endif
				endif

			elseif ! empty (za1 -> za1_doce)  // Trata-se de entrada gerada por NF
				u_log2 ('info', "Entrada gerada por NF. Chave: " + xfilial ("SD1") + za1 -> za1_doce + za1 -> za1_seriee + za1 -> za1_fornec + za1 -> za1_lojaf + za1 -> za1_prod + za1 -> za1_item)
				sd1 -> (dbsetorder (1))  // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
				if ! sd1 -> (dbseek (xfilial ("SD1") + za1 -> za1_doce + za1 -> za1_seriee + za1 -> za1_fornec + za1 -> za1_lojaf + za1 -> za1_prod + za1 -> za1_item, .F.))
					_sMsg = "NF entrada '" + za1 -> za1_doce + "' referenciada pela entrada_id '" + (_sAliasQ) -> entrada_id +"' nao encontrada na tabela SD1"
					_AtuEntr ((_sAliasQ) -> entrada_id, '9')  // Atualiza a tabela do Fullsoft como 'cancelado no ERP'
					_oBatch:Mensagens += _sMsg + '; '
				else
					if sd1 -> d1_local == U_AlmFull (sd1 -> d1_cod, 'NE')
						u_log2 ('debug', 'achei SD1')
						if za1 -> za1_quant != (_sAliasQ) -> qtde_exec
							_sMsg := ""
							_sMsg += "Produto '" + alltrim (sd1 -> d1_cod) + "': problemas no recebimento da etiqueta '" + za1 -> za1_codigo + "':" + chr (10) + chr (13)
							_sMsg += "Quantidade da etiqueta: " + cvaltochar (sd1 -> d1_quant) + chr (10) + chr (13)
							_sMsg += "Quantidade recebida pelo FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec) + chr (10) + chr (13)
							_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
							_oBatch:Mensagens += _sMsg + '; '
						else
							if (_sAliasQ) -> qtde_mov < (_sAliasQ) -> qtde_exec
								_sMsg := ""
								_sMsg += "Produto '" + alltrim (sd1 -> d1_cod) + "': problemas no recebimento da etiqueta '" + za1 -> za1_codigo + "':" + chr (10) + chr (13)
								_sMsg += "Quantidade movimentada pelo FullWMS (" + cvaltochar ((_sAliasQ) -> qtde_mov) + ") menor que quantidade executada (" + cvaltochar ((_sAliasQ) -> qtde_exec) + ")"
								_AtuEntr ((_sAliasQ) -> entrada_id, '5')  // Atualiza a tabela do Fullsoft como 'qtde movimentada menor que executada'
								_oBatch:Mensagens += _sMsg + '; '
							else
								sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
								if ! sb2 -> (dbseek (xfilial ("SB2") + sd1 -> d1_cod + sd1 -> d1_local, .F.)) .or. sb2 -> b2_qatu < _nQtAUsar
									u_log2 ('aviso', 'Sem estoque para transferir')
									_AtuEntr ((_sAliasQ) -> entrada_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
								else
									if _GeraTran (sd1 -> d1_cod, sd1 -> d1_lotectl, za1 -> za1_quant, sd1 -> d1_local, '02', '', '', 'GUARDA NF ' + sd1 -> d1_doc, za1 -> za1_codigo, _sChaveEx)
										_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
									else
										_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
									endif
								endif
							endif
						endif
					else
						u_help ('Transf.da etiq ' + alltrim ((_sAliasQ) -> codfor) + ' ja realizada ou desnecessaria.',, .t.)
					endif
				endif
			else
				u_AvisaTI ("Sem tratamento para entrada_id '" + (_sAliasQ) -> entrada_id +"' no programa " + procname ())
			endif


		// Entrada de producao com etiqueta
		case (_sAliasQ) -> tpdoc == '6' .and. left ((_sAliasQ) -> entrada_id, 3) == 'ZA1' .and. substr ((_sAliasQ) -> entrada_id, 4, 2) == cFilAnt
			_sEtiq = substr ((_sAliasQ) -> entrada_id, 6, 10)
			u_log2 ('info', 'Entrada de producao pelo ZA1. Etiqueta: ' + _sEtiq)
			za1 -> (dbsetorder(1))
			if ! za1 -> (dbseek (xfilial ("ZA1") + _sEtiq, .F.))
				u_help ("Etiqueta '" + _sEtiq + "' nao encontrada na tabela ZA1",, .t.)
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			/* desabilitado durante migracao database protheus
			// Verifica se necessita de inspecao
			_Inspe = _VerInsp((_sAliasQ) -> coditem, (_sAliasQ) -> codfor)
			If "ERRO" $ _Inspe
				u_help ('Erro web service do NaWeb: ' + _Inspe + " Etiqueta: " + (_sAliasQ) -> codfor)
				(_sAliasQ) -> (dbskip ())
				loop
			elseIf _Inspe != 'INSPECAO NAO DEFINIDA'  // Indica que nao precisa inspecionar este item 
				u_help ("Etiqueta " + (_sAliasQ) -> codfor + " aguardando inspecao no NaWeb")
				(_sAliasQ) -> (dbskip ())
				loop
			EndIf
*/

			// Procura o apontamento de producao gerado por esta etiqueta no almox. de integracao
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=    " AND D3_VAETIQ  = '" + _sEtiq + "'"
			_oSQL:_sQuery +=    " AND D3_CF LIKE 'PR%'"
			_oSQL:_sQuery +=    " AND D3_ESTORNO != 'S'"
			_nRegSD3 = _oSQL:RetQry (1, .F.)
			if _nRegSD3 == 0
				u_help ("Apontamento de producao gerado pela etiqueta '" + _sEtiq + "' nao encontrado.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			sd3 -> (dbgoto (_nRegSD3))

			if sd3 -> d3_estorno == 'S'
				u_help ("Apontamento de producao gerado pela etiqueta '" + _sEtiq + "' encontra-se estornado no Protheus.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '9')  // Atualiza a tabela do Fullsoft como 'cancelado no ERP'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
				
			// Verifica se a quantidade apontada com esta etiqueta precisa ser transferida para o almox. 01
			if sd3 -> d3_local != U_AlmFull (sd3 -> d3_cod, 'PR')
				u_help ("Apontamento de producao gerado pela etiqueta '" + _sEtiq + "' foi feito no almox. '" + sd3 -> d3_local + "'. Esse nao eh um almox. reconhecido como entrada de producao para o Full.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif
			
			// Quando for OP de reprocesso, considera o campo D3_PERDA.
			if fBuscaCpo ("SC2", 1, xfilial ("SC2") + sd3->d3_op, "C2_VAOPESP") == 'R'  // OP de retrabalho.
				_nQtAUsar = sd3 -> d3_perda
			else
				_nQtAUsar = sd3 -> d3_quant
			endif
			if _nQtAUsar != (_sAliasQ) -> qtde_exec  // no futuro quero usar o campo "qtde_mov" mas o Full ainda nao ta gravando
				u_help ("Apontamento de producao gerado pela etiqueta '" + _sEtiq + "' tem quantidade = " + cvaltochar (_nQtAUsar) + ", mas a quant.movimentada no Full foi de " + cvaltochar ((_sAliasQ) -> qtde_exec),, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Verifica se jah tem movimento de guarda da etiqueta (o processo pode ter caido na execucao anterior
			// antes de conseguir atualizar o status na tabela de integracao)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT TOP 1 D3_NUMSEQ"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=    " AND D3_VAETIQ  = '" + _sEtiq + "'"
			_oSQL:_sQuery +=    " AND D3_CF      = 'RE4'"
			_oSQL:_sQuery +=    " AND D3_ESTORNO != 'S'"
			_oSQL:_sQuery +=    " AND D3_LOCAL   = '" + sd3 -> d3_local + "'"
			_oSQL:_sQuery +=    " AND D3_VACHVEX = '" + _sChaveEx + "'"
			//_oSQL:Log ()
			_sNumSeq := _oSQL:RetQry (1, .F.)
			if ! empty (_sNumSeq)
				u_help ("Guarda da producao gerada pela etiqueta '" + _sEtiq + "' ja realizada (D3_NUMSEQ = '" + _sNumSeq + "')",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'jah executado no ERP'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Verifica se vai ter estoque suficiente para transferir.
			sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
			if ! sb2 -> (dbseek (xfilial ("SB2") + sd3 -> d3_cod + sd3 -> d3_local, .F.)) .or. sb2 -> b2_qatu < _nQtAUsar
				u_help ("Apont.prod.etiq. '" + _sEtiq + "': sem saldo estoque produto '" + alltrim (sb2 -> b2_cod) + "' no ax. '" + sb2 -> b2_local + "' para transferir.",, .t.)
				_AtuEntr ((_sAliasQ) -> entrada_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Gera a transferencia.
			if _GeraTran (sd3 -> d3_cod, '', _nQtAUsar, sd3 -> d3_local, '01', '', '', 'GUARDA PALLET ' + alltrim ((_sAliasQ) -> codfor), alltrim ((_sAliasQ) -> codfor), _sChaveEx)
				_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'executado'
			else
				_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
			endif



//		case (_sAliasQ) -> tpdoc == '6'  // Entrada de producao
		// Entrada de producao com chave antiga (pelo SD3) a ser descontinuada, mas precido receber o que ainda consta em aberto.
		// ELIMINAR ESTE CASE DAQUI A ALGUM TEMPO POIS PRETENDO MUDAR O ENTRADA_ID PARA SEMPRE INICIAR POR 'ZA1'
		// ALTERACAO JAH FEITA NA VIEW v_wms_entrada NA BASE TESTE, FALTA TESTAR BEM E LEVAR PRA QUENTE. ROBERT, 29/10/18 
		case (_sAliasQ) -> tpdoc == '6' .and. left ((_sAliasQ) -> entrada_id, 3) == 'SD3' .and. substr ((_sAliasQ) -> entrada_id, 4, 2) == cFilAnt
			u_log2 ('info', 'Entrada de producao pelo SD3') 

			if empty ((_sAliasQ) -> codfor)
				u_help ('Tabela TB_WMS_ENTRADA: Campo CODFOR nao tem numero de etiqueta na ENTRADA_ID ' + (_sAliasQ) -> entrada_id,, .t.)
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			/* desabilitado durante migracao database protheus
			// Verifica se necessita de inspecao
			_Inspe = _VerInsp((_sAliasQ) -> coditem, (_sAliasQ) -> codfor)
			If "ERRO" $ _Inspe
				u_help ('Erro web service do NaWeb: ' + _Inspe + " Etiqueta: " + (_sAliasQ) -> codfor)
				(_sAliasQ) -> (dbskip ())
				loop
			elseIf _Inspe != 'INSPECAO NAO DEFINIDA'  // Indica que nao precisa inspecionar este item 
				u_help ("Etiqueta " + (_sAliasQ) -> codfor + " aguardando inspecao no NaWeb")
				(_sAliasQ) -> (dbskip ())
				loop
			EndIf
*/
			// Procura o apontamento de producao gerado por esta etiqueta no almox. de integracao
			if ! U_TemNick ("SD3", "D3_VAETIQ")
				u_help ("Problema no indice 'D3_VAETIQ' do arquivo SD3. Acione suporte.",, .t.)
				u_AvisaTI (procname () + ": Problema no indice 'D3_VAETIQ' do arquivo SD3.")
				_lRet = .F.
			else
				sd3 -> (dbOrderNickName ("D3_VAETIQ"))  // D3_FILIAL+D3_VAETIQ
				if sd3 -> (dbseek (xfilial ("SD3") + alltrim ((_sAliasQ) -> codfor), .F.))
					if sd3 -> d3_estorno == 'S'
						_sMsg := ""
						_sMsg += "Produto '" + alltrim (sd3 -> d3_cod) + "': problemas no recebimento da etiqueta '" + sd3 -> d3_vaetiq + "':" + chr (10) + chr (13)
						_sMsg += "Movimento de producao estornado no Protheus" + chr (10) + chr (13)
						_sMsg += "Quantidade recebida pelo FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec) + chr (10) + chr (13)
						_sMsg += "Impossivel fazer a transferencia no Protheus. Verifique!"
						_AtuEntr ((_sAliasQ) -> entrada_id, '9')  // Atualiza a tabela do Fullsoft como 'cancelado no ERP'
						_oBatch:Mensagens += _sMsg + '; '
					else
						// Verifica se a quantidade apontada com esta etiqueta precisa ser transferida para o almox. 01
						if sd3 -> d3_estorno != 'S' .and. sd3 -> d3_vafullw != 'S' .and. sd3 -> d3_local == U_AlmFull (sd3 -> d3_cod, 'PR')
							_nQtAUsar = 0
							if fBuscaCpo ("SC2", 1, xfilial ("SC2") + sd3->d3_op, "C2_VAOPESP") == 'R'  // OP de retrabalho.
								if sd3 -> d3_perda != (_sAliasQ) -> qtde_exec
									_sMsg := ""
									_sMsg += "Produto '" + alltrim (sd3 -> d3_cod) + "': problemas no recebimento da etiqueta '" + sd3 -> d3_vaetiq + "':" + chr (10) + chr (13)
									_sMsg += "Quantidade apontada na etiqueta: " + cvaltochar (sd3 -> d3_perda) + chr (10) + chr (13)
									_sMsg += "Quantidade recebida pelo FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec) + chr (10) + chr (13)
									_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
									_oBatch:Mensagens += _sMsg + '; '
								else
									_nQtAUsar = min (sd3 -> d3_perda, (_sAliasQ) -> qtde_exec)
								endif
							else							
								if sd3 -> d3_quant != (_sAliasQ) -> qtde_exec
									_sMsg := ""
									_sMsg += "Produto '" + alltrim (sd3 -> d3_cod) + "': problemas no recebimento da etiqueta '" + sd3 -> d3_vaetiq + "':" + chr (10) + chr (13)
									_sMsg += "Quantidade apontada na etiqueta: " + cvaltochar (sd3 -> d3_quant) + chr (10) + chr (13)
									_sMsg += "Quantidade recebida pelo FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec) + chr (10) + chr (13)
									_AtuEntr ((_sAliasQ) -> entrada_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
									_oBatch:Mensagens += _sMsg + '; '
								else
									_nQtAUsar = min (sd3 -> d3_quant, (_sAliasQ) -> qtde_exec)
								endif
							endif
							
							_dData = dDatabase
							sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
							if ! sb2 -> (dbseek (xfilial ("SB2") + sd3 -> d3_cod + sd3 -> d3_local, .F.)) .or. sb2 -> b2_qatu < _nQtAUsar
								_AtuEntr ((_sAliasQ) -> entrada_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
							else
								if _GeraTran (sd3 -> d3_cod, '', _nQtAUsar, sd3 -> d3_local, '01', '', '', 'GUARDA PALLET ' + alltrim ((_sAliasQ) -> codfor), alltrim ((_sAliasQ) -> codfor), 'FullZA1' + cFilAnt + alltrim ((_sAliasQ) -> codfor))
									_AtuEntr ((_sAliasQ) -> entrada_id, '3')  // Atualiza a tabela do Fullsoft como 'jah executado no ERP'
								else
									u_log2 ('erro', 'Nao transferiu etiq. ' + sd3 -> d3_vaetiq)
									if ! empty (_sErroAuto)
										u_log2 ('erro', _sErroAuto)
									endif
									_AtuEntr ((_sAliasQ) -> entrada_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
								endif
							endif
						else
							u_log2 ('aviso', 'Transf.da etiq. ' + alltrim ((_sAliasQ) -> codfor) + ' para alm 01 ja realizada ou desnecessaria.')
						endif
					endif
				else
					_sMsg := ""
					_sMsg += "Problema etiq.'" + alltrim ((_sAliasQ) -> codfor) + "' Produto (FullWMS): '" + alltrim ((_sAliasQ) -> coditem) + "' Movto producao desta etiq.nao encontrado no Protheus"
					_oBatch:Mensagens += _sMsg + '; '
					//u_AvisaTI (procname () + ": " + strtran (strtran (_sMsg, chr (10), '; '), chr (13), ''))
				endif
			endif

		otherwise
			u_help ("Sem tratamento para tpdoc / entrada_id '" + (_sAliasQ) -> tpdoc + (_sAliasQ) -> entrada_id + "' da tabela 'tb_wms_entradas'.",, .t.)
			u_avisaTI ("Sem tratamento para tpdoc / entrada_id '" + (_sAliasQ) -> tpdoc + (_sAliasQ) -> entrada_id + "' da tabela 'tb_wms_entradas'.")
		endcase

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())

return _lRet



// --------------------------------------------------------------------------------------------
// Atualiza status no FullWMS.
// Status 5 = ESTORNADO. Setado pelo Ponto de Entrada SD3250E.
static function _AtuEntr (_sEntrada, _sStatus)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " update tb_wms_entrada"
	_oSQL:_sQuery +=    " set status_protheus = '" + _sStatus + "'"
	_oSQL:_sQuery +=  " where entrada_id = '" + _sEntrada + "'"
	_oSQL:Exec ()
	if _sStatus != '3'  // 3=executado ok
		_oSQL:Log ()
	endif
return



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
	//u_log (_aItens)
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
		u_help ('Problemas na transferencia de estoque: ' + _sErroAuto,, .t.)
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


// ------------------------------------------------------------------------------------
// Processa saidas do FullWMS
static function _Saidas ()
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
	_oSQL:_sQuery +=  " where empresa = 2"  // Empresa 1 = logistica (onde usamos esta tabela apenas para consulta)
	_oSQL:_sQuery +=    " and status  = '6'"
	_oSQL:_sQuery +=    " and tpdoc   = '1'"
	_oSQL:_sQuery +=    " and status_protheus != '3'"  // 3 = executado
	_oSQL:_sQuery +=    " and status_protheus != 'C'"  // C = cancelado: por que jah foi acertado manualmente, ou jah foi inventariado, etc.
	_oSQL:_sQuery +=    " and status_protheus != '5'"  // 5 = estornado
	_oSQL:_sQuery +=  " order by saida_id"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		u_log2 ('info', 'Processando saida_id ' + (_sAliasQ) -> saida_id)
		do case
			case left ((_sAliasQ) -> saida_id, 3) == 'ZAG'
				_sChaveZAG = substr ((_sAliasQ) -> saida_id, 6, 10)  // Chave composta por ZAG + filial + chave_do_ZAG
				zag -> (dbsetorder (1))  // ZAG_FILIAL, ZAG_DOC
				if zag -> (dbseek (xfilial ("ZAG") + _sChaveZAG, .F.)) .and. zag -> zag_filori == substr ((_sAliasQ) -> saida_id, 4, 2)
					
					// Deixa objeto instanciado com a solicitacao original de transferencia
					_oTrOrig := ClsTrEstq ():New (zag -> (recno ()))
					if _oTrOrig:Executado == 'S'  // Se jah foi executado anteriormente...
						_AtuSaid ((_sAliasQ) -> saida_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
					else
						if zag -> zag_qtdsol != (_sAliasQ) -> qtde_exec
							_sMsg = "Quantidade solicitada: " + cvaltochar (zag -> zag_qtdsol) + "; Quantidade movimentada pelo FullWMS: " + cvaltochar ((_sAliasQ) -> qtde_exec)
							_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
							_oBatch:Mensagens += _sMsg + '; '
						else
							sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
							if ! sb2 -> (dbseek (xfilial ("SB2") + zag -> zag_prdori + zag -> zag_almori, .F.)) .or. sb2 -> b2_qatu < (_sAliasQ) -> qtde_exec
								u_log2 ('aviso', 'Sem estoque para transferir')
								_AtuSaid ((_sAliasQ) -> saida_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
							else
								// Verifica quais os lotes separado pelo Full. Se apenas um, atualiza na solicitacao original de transferencia;
								// Se mais de um, replica a solicitacao (uma para cada lote) visando manter os lotes no Protheus iguais aos do Full.
								_oSQL:_sQuery := ""
								_oSQL:_sQuery += " select substring (lote, 1, 10), qtde"
								_oSQL:_sQuery +=   " from tb_wms_lotes"
								_oSQL:_sQuery +=  " where empresa = 2"  // Empresa 1 = logistica (onde usamos esta tabela apenas para consulta)
								_oSQL:_sQuery +=    " and documento_id = '" + (_sAliasQ) -> saida_id + "'"
								_oSQL:_sQuery +=    " and tpdoc   = '1'"
								_oSQL:_sQuery +=  " order by lote"
								_oSQL:Log ()
								_aLotes = _oSQL:Qry2Array (.F., .F.)
								u_log2 ('info', 'Lotes separados pelo Full:')
								u_log2 ('info', _aLotes)

								// Faz algumas validacoes para saber se vai conseguir transferir todos os lotes.
								_lLotesOK = .T.
								if _lLotesOK
									_nSomaLote = 0
									for _nLote = 1 to len (_aLotes)
										_nSomaLote += _aLotes [_nLote, 2]
									next
									if _nSomaLote != (_sAliasQ) -> qtde_exec
										_sMsg = "Soma qt.separadas por lotes difere da qtde_exec"
										_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
										_oBatch:Mensagens += _sMsg + '; '
										_lLotesOK = .F.
									endif
								endif
								if _lLotesOK
									sb8 -> (dbsetorder (3)) // B8_FILIAL, B8_PRODUTO, B8_LOCAL, B8_LOTECTL, B8_NUMLOTE, B8_DTVALID, R_E_C_N_O_, D_E_L_E_T_
									for _nLote = 1 to len (_aLotes)
										if ! sb8 -> (dbseek (_oTrOrig:FilOrig + _oTrOrig:ProdOrig + _oTrOrig:AlmOrig + _aLotes [_nLote, 1], .F.))
											_sMsg = "Lote '" + _aLotes [_nLote, 1] + "' nao localizado para o produto '" + _oTrOrig:ProdOrig + "'"
											_AtuSaid ((_sAliasQ) -> saida_id, '4')  // Atualiza a tabela do Fullsoft como 'diferenca na quantidade'
											_oBatch:Mensagens += _sMsg + '; '
											_lLotesOK = .F.
											exit
										endif
										u_log2 ('debug', 'comparando b8_saldo = ' + cvaltochar (sb8 -> b8_saldo) + ' com _aLotes [_nLote, 2] = ' + cvaltochar (_aLotes [_nLote, 2]))
										if sb8 -> b8_saldo < _aLotes [_nLote, 2]
											_sMsg = "Saldo insuficiente lote '" + _aLotes [_nLote, 1] + "' do produto '" + _oTrOrig:ProdOrig + "'"
											_AtuSaid ((_sAliasQ) -> saida_id, '1')  // Atualiza a tabela do Fullsoft como 'falta estoque para fazer a transferencia'
											_oBatch:Mensagens += _sMsg + '; '
											_lLotesOK = .F.
											exit
										endif
									next
								endif

								if _lLotesOK
									for _nLote = 1 to len (_aLotes)

										// Se tiver mais de um lote, preciso gerar novo(s) registro(s) no ZAG (um para cada lote).
										if _nLote == 1  // Jah estou posicionado na solicitacao original gerada pelo Protheus
											u_log2 ('debug', 'Transferindo pelo ZAG original')
											_oTrEstq := _oTrOrig
											_oTrEstq:LoteOrig = _aLotes [_nLote, 1]
											_oTrEstq:QtdSOlic = _aLotes [_nLote, 2]
										else
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
										u_log2 ('info', 'Chamando liberacao do ZAG')
										_oTrEstq:Libera (.F., 'FULLWMS')
										if _oTrEstq:Executado == 'S'
											_AtuSaid ((_sAliasQ) -> saida_id, '3')  // Atualiza a tabela do Fullsoft como 'executado no ERP'
										elseif _oTrEstq:Executado == 'E'
											_AtuSaid ((_sAliasQ) -> saida_id, '2')  // Atualiza a tabela do Fullsoft como 'outro erro nao tratado na transferancia'
										endif
									next
								endif
							endif
						endif
					endif
				else
					u_log2 ('aviso', 'ZAG nao localizado com chave >>' + _sChaveZAG + '<< (ou nao se destina a esta filial).')
				endif
		otherwise
			u_help ("Sem tratamento para tpdoc / saida_id '" + (_sAliasQ) -> tpdoc + (_sAliasQ) -> saida_id + "' da tabela 'tb_wms_pedidos'.",, .t.)
		endcase
		u_log2 ('info', _sMsg)

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())

return _lRet



// --------------------------------------------------------------------------------------------
// Atualiza status no FullWMS.
// Status 5 = ESTORNADO. Setado pelo Ponto de Entrada SD3250E.
static function _AtuSaid (_sSaida, _sStatus)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " update tb_wms_pedidos"
	_oSQL:_sQuery +=    " set status_protheus = '" + _sStatus + "'"
	_oSQL:_sQuery +=  " where saida_id = '" + _sSaida + "'"
	_oSQL:Exec ()
	if _sStatus != '3'  // 3=executado ok
		_oSQL:Log ()
	endif
return

