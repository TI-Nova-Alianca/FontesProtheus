// Programa:   GrvLibPV
// Autor:      Robert Koch
// Data:       21/06/2010
// Descricao:  Chamado por botao na tela de pedido de vendas. Grava campo C6_QTDLIB no aCols.
// 
// Historico de alteracoes:
// 04/10/2010 - Robert - Testa existencia da variavel oGetDad.
// 20/10/2010 - Robert - Testa preenchimento da filial de embarque.
// 25/10/2010 - Robert - Passa a verificar estoque dos produtos antes de liberar.
// 28/10/2010 - Robert - Alteracoes parametros chamada funcao VerEstq.
// 04/11/2010 - Robert - Nao verificava se a linha estava deletada no aCols.
// 05/11/2010 - Robert - Novos parametros funcao VerEstq.
// 11/11/2010 - Robert - Se alguma das linhas tinha problemas, nao libera nenhuma.
// 30/12/2010 - Robert - Recebe parametro indicando se libera ou se remove liberacao.
// 28/07/2011 - Robert - Verifica preenchimento do campo C6_BLQ.
// 21/09/2011 - Robert - Mostra mensagem com dados basicos do ultimo pedido do cliente.
// 16/12/2011 - Robert - Funcao U_VerEistq passa a receber parametro de endereco de estoque.
// 06/03/2012 - Robert - Verifica vendas com precos abaixo da venda anterior.
// 16/03/2012 - Robert - Passa a gravar o campo C5_VABLOQ.
// 15/05/2012 - Robert - Se o pedido jah tinha bloqueio gerencial, o bloqueio nunca mais era removido.
// 31/05/2012 - Robert - Nao restringe mais a leitura do ultimo pedido a 31/03/12 para bloqueio gerencial.
// 29/05/2013 - Elaine DWT  - Inclui tratamento para bloqueio gerencial caso o pedido for da tabela 151 e o preco informado estiver abaixo da mesma
// 21/08/2013 - Leandro DWT - Inclus�o de valida��o para que somente os usu�rios do par�metro possam liberar o pedido de venda
// 02/06/2015 - Catia  - Valida��o saldo em verbas a bonificar.
// 06/07/2015 - Catia  - Alterado para buscar a ST pela rotina MaFisRet na hora de somar o total do pedido
// 04/08/2015 - Robert - Nao valida mais o preco da ultima compra para pedidos tipo D/B
// 23/09/2015 - Robert - Quando misturava motivos de bonificao com e sem controle de verbas, nem todos os itens eram adicionados no MaFisAdd.
// 13/10/2015 - Catia  - Dava mensagem de que o cliente nao tinha saldo e bonificar mas mesmo assim liberava o pedido
// 22/10/2015 - Catia  - Alterado para no calculo do item bonificado - busque o IPI valor da planilia do MATFISRET
// 11/07/2016 - Robert - Chama consulta de margem de contribuicao e deixa campo C5_VABLOQ setado com 'M' caso esteja abaixo da margem minima.
// 25/10/2016 - Robert - Dados da ultima venda (preco menor) passa a ser em TXT e nao mais em HTML.
// 29/03/2017 - Catia  - Itens com elimina��o de Res�duo - ainda estava tentando liberar no estoque
// 28/04/2017 - Robert - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 22/05/2017 - Catia  - Alterado o parametro de margem para 1% para n�o bloquear nada no gerencial
// 13/10/2017 - Robert - Volta a fazer bloqueio por margem (agora via parametro VA_MCPED1).
// 16/10/2017 - Robert - Ignora bloqueio de margem para pedidos de granel.
// 23/10/2017 - Robert - Valida campo c5_vaPrPed.
// 30/10/2017 - Robert - Chama rotina de selecao de frete somente para frete tipo CIF.
// 19/02/2018 - Catia  - Valida rapel e base do cliente - nao deixa incluir pedido com dados conflitantes
// 25/04/2018 - Catia  - Valida��o da loja do codigo matriz quando o cliente controla verbas
// 19/06/2018 - Catia  - bloqueio por % de aumento
// 03/07/2018 - Robert - Funcao Va_McPed() tem novos parametros
//                     - Cotacao de frete passa a ser chamada diretamente pela funcao de calculo de margem de contribuicao.
// 17/08/2018 - Catia  - teste de caracteres especiais nas observa��es
// 14/11/2018 - Andre  - Adicionado verifica��o dos campos A1_VAMDANF e A2_VAMDANF para n�o liberar pedido com email LIXO@NOVAALIANCA.COOP.BR
// 04/12/2018 - Andre  - Adicionado valida��o nos CAMPOS A1_EMAIL e A2_EMAIL. Bloqueado inclus�o neste campos para conteudo LIXO@NOVA OU NOVALIANCA.
// 10/12/2018 - Andre  - Validacao para que itens com TES 630 e 657 apenas usu�rios dos grupos 069 e 066 possam liberar.
// 25/01/2019 - Andre  - Pesquisa ZX5 alterada de FBUSCACPO para U_RETZX5.
// 22/05/2019 - Robert - Liberados caracteres especiais no C5_OBS apenas em base teste (GLPI 5961)
// 27/05/2019 - Catia  - estava dando erro linha 418 e 427 _lTes 
// 28/05/2019 - Sandra - N�o valida mais caracteres especias no campo de observacoes conforme GLPI 5961
// 11/11/2019 - Robert - Revisado tratamento campo ZA5_FILIAL (tabela passar de compartilhada para exclusiva). GLPI 6987.
//                     - Passa a validar campo ZA4_FILIAL na query.
// 18/11/2019 - Robert - Iniciadas melhorias bloqueio pedido bonificado sem pedido faturado correspondente
// 09/04/2020 - Claudia - Incluido o controle de endere�o da linha do pedido de venda, conforme GLPI: 7765
// 20/07/2020 - Robert - Permissao para liberar pedido de baixa de estoque para ajustes passa a validar acesso 101 e nao mais 069+066.
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Valida se pode gravar o campo C6_QTDLIB durante a edicao do pedido de venda.
// #PalavasChave      #liberacao #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT
//

// --------------------------------------------------------------------------------------------------------
user function GrvLibPV (_lLiberar)
	local _aAreaAnt  := U_ML_SRArea ()
	local _n         := N
	local _sErro     := ""
	local _nQtdEnt   := 0
	local _sQuery    := ""
//	local _sUltPed   := ""
	local _aUltPrc   := {}
	local _nUltPrc   := 0
	local _sMsg      := ""
	local _nOpcao    := 0
	local _sRetEstq  := ""
	local _nLinAnt   := 0
	local _nAcumAnt  := 0
//	local _wbonif    := .F.
//	local _nQtItens  := 0
	local _lFaturado := .F.
	local _lBonific  := .F.
	local _lSoGranel := .F.
	local _wdtreajuste   := dtos(GetMv ("VA_DTREAJ"))
	local _wpercreajuste := GetMv ("VA_PERCREA")
	local _nLinha    := 0

	if _lLiberar .and. empty (m->c5_vaFEmb)
		u_help ("Antes de liberar o pedido, o campo '" + alltrim (RetTitle ("C5_VAFEMB")) + "' deve ser informado.")
		return
	endif
	
	if ! U_ZZUVL ('005')
		_lLiberar := .F.
	endif
	
	if _lLiberar .and. M->C5_CONDPAG = '997' // DESCONTO EM FOLHA - NAO PODE USAR
		_sErro += "Condi��o de pagamento exclusiva para venda nas lojas."
		_lLiberar = .F.
	endif
	
	// Validacoes de e-mail DANFE
	if _lLiberar	
		if M-> C5_TIPO = 'N'
			_wEmailA1 = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_VAMDANF")
			if 'lixo@nova' $ _wEmailA1
				_sErro += "E-mail para DANFE inv�lido. Por favor, verifique!'"
				_lLiberar = .F.
			endif
			_wEmailA1 = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_EMAIL")
			if 'lixo@nova' $ _wEmailA1
				_sErro += "E-mail para DANFE inv�lido. Por favor, verifique!'"
				_lLiberar = .F.
			endif
		else
			_wEmailA2 = fBuscaCpo ('SA2', 1, xfilial('SA2') + m->c5_cliente + m->c5_lojacli, "A2_VAMDANF")
			if  'lixo' $ _wEmailA2
			   	_sErro += "E-mail para DANFE inv�lido. Por favor, verifique!"
				_lLiberar = .F.
			endif
			if  _wEmailA2 != 'associados@novaalianca.coop.br' .and. 'novaalianca' $ _wEmailA2
			   	_sErro += "E-mail para DANFE inv�lido. Por favor, verifique!"
				_lLiberar = .F.
			endif
			_wEmailA2 = fBuscaCpo ('SA2', 1, xfilial('SA2') + m->c5_cliente + m->c5_lojacli, "A2_EMAIL")
			if  'lixo' $ _wEmailA2
			   	_sErro += "E-mail para DANFE inv�lido. Por favor, verifique!"
				_lLiberar = .F.
			endif
			
		endif
	endif

	// Validacao da TES por item do pedido, libera somente grupos autorizados.
	if _lLiberar
		_lTes = .F.
		for _nLinha = 1 to len (aCols)
			N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
			if ! GDDeleted ()
			    IF GDFieldGet ("C6_TES") $ '630/657'
					if ! U_ZZUVL ('101', __cUserId, .F.)
 						u_help ("Usu�rio sem permiss�o para emiss�o de nota fiscal de baixa de estoque",, .t.)
 						_sErro += "Usu�rio sem permiss�o para emiss�o de nota fiscal de baixa de estoque"
						_lTes = .T.
						exit
					endif
				ENDIF	
			endif
		next
		if _lTes = .T.
			_lLiberar = .F.
		endif
	endif
	
	// verifica se controla endere�o e lote
	if _lLiberar
		for _nLinha = 1 to len (aCols)
			N := _nLinha  
			if ! GDDeleted ()
				if fBuscaCpo("SF4",1,xFilial("SF4")+GDFieldGet ("C6_TES"),"F4_ESTOQUE") = 'S'
					if m->c5_tpcarga == '2' .and. Localiza (GDFieldGet ("C6_PRODUTO")) .and. (empty (GDFieldGet ("C6_LOCALIZ")) .or. empty (GDFieldGet ("C6_ENDPAD")))
						u_help ("Item " + GDFieldGet ("C6_ITEM") + ": Pedido nao utiliza carga, mas o produto '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "' controla localizacao. Informe endereco para retirada nos campos '" + alltrim (RetTitle ("C6_LOCALIZ")) + "' e '" + alltrim (RetTitle ("C6_ENDPAD")) + "'." )
						_lLiberar := .F.
					endif
				endif
			endif
		next
	endif

	// Grava valor previsto para a nota fiscal. Vai ser usado posteriormente nos calculos de frete e margem de contribuicao.
	if _lLiberar
		m->c5_vaVlFat = Ma410Impos (iif (inclui, 3, 4), .T.)  // (nOpc, lRetTotal, aRefRentab)
	endif
	
	if _lLiberar
		CursorWait ()

		// Caso o pedido jah esteja com bloqueio, remove o bloqueio antes de efetuar nova verificacao.
		m->c5_vaBloq = ''

		_n = N
		for _nLinha = 1 to len (aCols)
			N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.

			if ! GDDeleted ()
                                                        
				// Busca quantidade jah entregue (possivel faturamento parcial)
				if inclui
					_nQtdEnt = 0
				else
					_nQtdEnt = fBuscaCpo ("SC6", 1, xfilial ("SC6") + m->c5_num + GDFieldGet ("C6_ITEM") + GDFieldGet ("C6_PRODUTO"), "C6_QTDENT")
				endif

				// Acumula quantidades deste produto em linhas anteriores do mesmo pedido.
				_nAcumAnt = 0
				for _nLinAnt = 1 to len (aCols)
					if ! GDDeleted (_nLinAnt) ;
							.and. GDFieldGet ("C6_PRODUTO", _nLinAnt) == GDFieldGet ("C6_PRODUTO") ;
							.and. GDFieldGet ("C6_LOCAL", _nLinAnt)   == GDFieldGet ("C6_LOCAL") ;
							.and. GDFieldGet ("C6_LOCALIZ", _nLinAnt) == GDFieldGet ("C6_LOCALIZ") ;
							.and. (fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES", _nLinAnt), "F4_ESTOQUE") == 'S' ;
							.or.  fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES", _nLinAnt), "F4_VAFDEP") == 'S')
						_nAcumAnt += GDFieldGet ("C6_QTDLIB", _nLinAnt)
					endif
				next
				
				// Verifica estoque desta linha
				if ! alltrim (GDFieldGet ("C6_BLQ")) $ "SR"  // bloqueio manual ou por eliminacao de residuo
					_sRetEstq = U_VerEstq ("2", GDFieldGet ("C6_PRODUTO"), m->c5_vaFEmb, GDFieldGet ("C6_LOCAL"), (GDFieldGet ("C6_QTDVEN") - _nQtdEnt + _nAcumAnt), GDFieldGet ("C6_TES"), GDFieldGet ("C6_ENDPAD"), GDFieldGet ("C6_LOTECTL"), m->c5_num)
					if ! empty (_sRetEstq)
						_sErro += "Item " + GDFieldGet ("C6_ITEM") + ": " + _sRetEstq + chr (13) + chr (10)
					else
						GDFieldPut ("C6_QTDLIB", GDFieldGet ("C6_QTDVEN") - _nQtdEnt)
					endif
				endif
				
				// Valida preco de venda com ultimo pedido do cliente.
				if empty (_sErro) .and. ! m->c5_tipo $ 'DB' .and. cNumEmp == '0101' .and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES"), "F4_DUPLIC") == "S"

					_sQuery := ""
					_sQuery += " SELECT TOP 1 D2_PRCVEN, "
					_sQuery +=              " D2_FILIAL, "
					_sQuery +=              " D2_EMISSAO, "
					_sQuery +=              " D2_DOC, "
					_sQuery +=              " D2_PEDIDO"
					_sQuery +=  " FROM " + RetSQLName ("SD2") + " SD2 "
					_sQuery += " WHERE SD2.D_E_L_E_T_  = ''"
					_sQuery +=   " AND SD2.D2_CLIENTE  = '" + m->c5_cliente + "'"
					_sQuery +=   " AND SD2.D2_LOJA     = '" + m->c5_lojacli + "'"
					_sQuery +=   " AND SD2.D2_TIPO     = '" + m->c5_tipo + "'"
					_sQuery +=   " AND SD2.D2_COD      = '" + GDFieldGet ("C6_PRODUTO") + "'"
					_sQuery += " ORDER BY D2_EMISSAO DESC"
					_aRetQry = aclone (U_Qry2Array (_sQuery, .F., .F.))
					if len (_aRetQry) > 0 .and. round (_aRetQry [1, 1], 2) > round (GDFieldGet ("C6_PRCVEN"), 2)

						aadd (_aUltPrc, {alltrim (GDFieldGet ("C6_PRODUTO")), ;
							alltrim (GDFieldGet ("C6_DESCRI")), ;
							GDFieldGet ("C6_PRCVEN"), ; //alltrim (transform (GDFieldGet ("C6_PRCVEN"), "@E 999,999,999.99")), ;
							_aRetQry [1, 1], ; // alltrim (transform (_aRetQry [1, 1], "@E 999,999,999.99")), ;
							_aRetQry [1, 2], ;
							dtoc (stod (_aRetQry [1, 3])), ;
							_aRetQry [1, 4], ;
							_aRetQry [1, 5]})
					endif
	
					if len (_aRetQry) > 0 .and. round (GDFieldGet ("C6_PRCVEN"), 2) < round (_aRetQry [1, 1]+(_aRetQry [1, 1]*_wpercreajuste/100), 2) // substituir por parametros
						if  _aRetQry [1, 3] <= _wdtreajuste  // substituir pelo parametro
							aadd (_aUltPrc, {alltrim (GDFieldGet ("C6_PRODUTO")), ;
							alltrim (GDFieldGet ("C6_DESCRI")), ;
							GDFieldGet ("C6_PRCVEN"), ; //alltrim (transform (GDFieldGet ("C6_PRCVEN"), "@E 999,999,999.99")), ;
							round (_aRetQry [1, 1]+(_aRetQry [1, 1]*_wpercreajuste/100), 2), ; // alltrim (transform (_aRetQry [1, 1], "@E 999,999,999.99")), ;
							_aRetQry [1, 2], ;
							dtoc (stod (_aRetQry [1, 3])), ;
							_aRetQry [1, 4], ;
							_aRetQry [1, 5]})
						endif						
					endif
					
					if m->c5_tabela == "151"  // Se for tabela 151 e o preco informado for menor que da tabela, deve ser bloqueado
						_sQuery := ""
						_sQuery += " SELECT DA1_PRCVEN, DA1_FILIAL "
						_sQuery +=  " FROM " + RetSQLName ("DA1") + " DA1 "
						_sQuery += " WHERE DA1.D_E_L_E_T_  = ''"
						_sQuery +=   " AND DA1_CODTAB = '151' "
						_sQuery +=   " AND DA1_CODPRO = '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "'"
						_sQuery +=   " AND DA1_FILIAL = '" + xfilial ("DA1")  + "'"
						_aRetQry = aclone (U_Qry2Array (_sQuery, .F., .F.))
        

						if len (_aRetQry) > 0 .and. round (_aRetQry [1, 1], 2) > round (GDFieldGet ("C6_PRCVEN"), 2)

							aadd (_aUltPrc, {alltrim (GDFieldGet ("C6_PRODUTO")), ;
								alltrim (GDFieldGet ("C6_DESCRI")), ;
								GDFieldGet ("C6_PRCVEN"), ; // alltrim (transform (GDFieldGet ("C6_PRCVEN"), "@E 999,999,999.99")), ;
								_aRetQry [1, 1], ; // alltrim (transform (_aRetQry [1, 1], "@E 999,999,999.99")), ;
								_aRetQry [1, 2], ;
								dtoc(date()), ;
								"TAB PRC", ;
								"151"})
						endif

					endif

				endif

			endif
		next

                                                
		if len (_aUltPrc) > 0

   			// Prepara mensagem para visualizacao
			_sMsg := ""
			_sMsg += "Pedido de venda '" + m->c5_num + "' com precos menores que a ultima venda/tabela de precos" + chr (13) + chr (10)
			_sMsg += "Cliente: " + m->c5_cliente + " - " + m->c5_nomecli + chr (13) + chr (10)
			_sMsg += "Representante: " + m->c5_vend1 + " - " + fBuscaCpo ("SA3", 1, xfilial ("SA3") + m->c5_vend1, "A3_NOME") + chr (13) + chr (10)
			_sMsg += 'Produtos:' + chr (13) + chr (10)
			for _nUltPrc = 1 to len (_aUltPrc)
//				_sMsg += _aUltPrc [_nUltPrc, 1] + ' - ' + _aUltPrc [_nUltPrc, 2] + ' (preco atual: ' + _aUltPrc [_nUltPrc, 3] + ' - ult.venda: ' + _aUltPrc [_nUltPrc, 4] + ')' + chr (13) + chr (10) 
				_sMsg += _aUltPrc [_nUltPrc, 1] + ' - ' + _aUltPrc [_nUltPrc, 2] + ' (preco atual: ' + cvaltochar (_aUltPrc [_nUltPrc, 3]) + ' - ult.venda: ' + cvaltochar (_aUltPrc [_nUltPrc, 4]) + ')' + chr (13) + chr (10) 
			next

			_nOpcao = aviso ("Precos abaixo da regras de estabelecidas pelo comercial", ;
				"Estao sendo vendidos produtos com precos abaixo das regras estabelecidas pelo comercial!" + chr (13) + chr (10) + "Se confirmar assim mesmo, o pedido ficara� com bloqueio gerencial.", ;
				{"Sim", "Nao", "Verificar"}, ;
				3, ;
				"Precos abaixo da venda anterior/Tabela de Precos/ Precos abaixo do aumento especificado")
			if _nOpcao == 1

				// Bloqueia o pedido.
			//	m->c5_vaBloq = 'P'
				m->c5_vaBloq = iif ('P' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'P')
				U_LOG ('M->C5_VABLOQ ficou com', m->c5_vaBloq)

				// Grava a maior variacao
				u_log (_aUltPrc)
				for _nUltPrc = 1 to len (_aUltPrc)
					u_log ('linha', _nUltPrc)

					u_log (m->c5_vaPrPed, 100 - _aUltPrc [_nUltPrc, 3] * 100 / _aUltPrc [_nUltPrc, 4])
					m->c5_vaPrPed = max (m->c5_vaPrPed, 100 - _aUltPrc [_nUltPrc, 3] * 100 / _aUltPrc [_nUltPrc, 4])
					u_log ('var=', m->c5_vaPrPed)
					//_aUltPrc [_nUltPrc, 4] = 100%
					//_aUltPrc [_nUltPrc, 3] = X
					//X = 100 - _aUltPrc [_nUltPrc, 3] * 100 / _aUltPrc [_nUltPrc, 4]
				next
			
				// verifica se o bloqueio � por ser menor que o aumento
				for _nUltPrc = 1 to len (_aUltPrc)
					if _aUltPrc [_nUltPrc, 3] < _aUltPrc [_nUltPrc, 4]
//						m->c5_vaBloq = 'A'  /// bloqueia por pre�o menor que o aumento estabelecido				
						// bloqueia por pre�o menor que o aumento estabelecido				
						m->c5_vaBloq = iif ('A' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'A')
						U_LOG ('M->C5_VABLOQ ficou com', m->c5_vaBloq)
					endif
				next									

				// Cria variavel publica com mensagem, para posterior envio pelo P.E. M410STTS se o usuario vier a gravar o pedido.
				public _sMsgPUltV := _sMsg

			elseif _nOpcao == 2
				_sErro = "Venda nao confirmada - preco abaixo do preco anterior/tabela de precos."
				_lLiberar = .F.

			elseif _nOpcao == 3
				U_ShowMemo (_sMsg)
				_sErro = "Venda nao confirmada - preco abaixo do preco anterior/tabela de precos."
				_lLiberar = .F.
			endif
			
		endif
		N = _n


		// Prepara algumas variaveis para validacoes posteriores.
		if _lLiberar
			_lFaturado = .F.
			_lBonific  = .F.
			_lSoGranel = .T.
			sf4 -> (dbsetorder (1))
			_n = N
			for _nLinha = 1 to len (aCols)
				N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
				if ! GDDeleted ()
					if ! sf4 -> (msseek (xfilial ("SF4") + GDFieldGet ("C6_TES"), .F.))
						u_help ("Cadastro do TES '" + GDFieldGet ("C6_TES") + "' nao localizado!")
						_lLiberar = .F.
					else
						_lFaturado = (sf4 -> f4_margem == '1')
						_lBonif    = (sf4 -> f4_margem == '3')
					endif
					if _lSoGranel .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C6_PRODUTO"), "B1_GRPEMB") != '18'
						_lSoGranel = .F.
					endif
				endif
			next
			u_log ('contem itens faturados:', _lFaturado, 'contem itens bonificados:', _lBonific, 'contem apenas itens a granel:', _lSoGranel)
		endif


		// Valida margem de contribuicao.
		if _lLiberar //.and. empty (m->c5_vaBloq) // .and. cFilAnt == '01'
//			_lFaturado = .F.
//			_lSoGranel = .T.
//			_n = N
//			for _nLinha = 1 to len (aCols)
//				N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
//				if ! GDDeleted ()
//					if ! _lFaturado .and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES"), "F4_MARGEM") == '1'
//						_lFaturado = .T.
//					endif
//					if _lSoGranel .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C6_PRODUTO"), "B1_GRPEMB") != '18'
//						_lSoGranel = .F.
//					endif
//				endif
//			next
			//u_log ('faturado:', _lFaturado, 'so granel:', _lSoGranel)

			N = _n
			if _lFaturado .and. ! _lSoGranel  // Ignora bloqueio de margem para pedidos de granel

				processa ({|| U_VA_McPed (.F., .T.), "Calculando margem de contribuicao"})
				//_nMargMin = 21  // alterado de 27 para 21 em 31/08/2016.  --> 27
				// desabilitado o bloqueio gerencia - solicitado fernando - 19/05/2017 - deixado margem = 1%
				//_nMargMin = 1
				_nMargMin = GetMv ("VA_MCPED1")
				if m->c5_vaMCont < _nMargMin
					_nOpcao = aviso ("Margem de contribuicao muito baixa", ;
					                 "Margem de " + cvaltochar (m->c5_vaMCont) + "% (abaixo de " + cvaltochar (_nMargMin) + "%). Pedido vai ficar com bloqueio gerencial. Confirma assim mesmo?", ;
					                 {"Sim", "Nao"}, ;
					                 3, ;
					                 "Margem minima")
					if _nOpcao == 1
//						if m->c5_vaBloq = 'A'   // se ja parou no % de ajuste
//							m->c5_vabloq = 'N'  // % de ajuste e margem
//						else
//							m->c5_vabloq = 'M'
//						endif							
						m->c5_vaBloq = iif ('M' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'M')
						U_LOG ('M->C5_VABLOQ ficou com', m->c5_vaBloq)
					elseif _nOpcao == 2
						_sErro = "Pedido nao confirmado."
					endif
				endif
				
//				if cFilAnt == '01' .and. empty (m->c5_vabloq) .and. m->c5_tpfrete == 'C' .and. m->c5_mvfre == 0
				if cFilAnt == '01' .and. empty (m->c5_vabloq) .and. m->c5_tpfrete == 'C' .and. m->c5_mvfre == 0 .and. GetMv ("VA_BLPSF") == 'S'
					_sErro += "Parametro VA_BLPSF: Pedido com frete CIF, mas sem valor de frete para calculo de margem. Liberacao nao sera� feita. Cadastre rota valida no entregou.com ou informe frete negociado no cadastro do cliente."
				endif

			endif
		endif

		// validacoes RAPEL
		if _lLiberar
			_wbaserapel = fBuscaCpo ('SA1', 1, xfilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI, "A1_VABARAP")
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT dbo.VA_FRAPELPADRAO ('" + M->C5_CLIENTE + "','" + M->C5_LOJACLI + "', '')"
			_oSQL:Log ()
			_wRapel = _oSQL:RetQry (1, .F.)
		
			if _wbaserapel != '0' 
				if _wrapel = 0
					u_help ("Tabela de rapel n�o cadastrada para esse cliente. Verifique!")
					_lLiberar = .F.										
				endif
			else
				_sQuery := ""
				_sQuery += " SELECT 1"
				_sQuery += "   FROM ZAX010 AS ZAX"
				_sQuery += "  WHERE ZAX.D_E_L_E_T_  = ''"
				_sQuery += "    AND ZAX_CLIENT      = '" + M->C5_CLIENTE + "'"
				_sQuery += "    AND ZAX_LOJA        = '" + M->C5_LOJACLI + "'"
				aDados := U_Qry2Array(_sQuery)
     			if len (aDados) > 0
     				u_help ("Cliente sem base de rapel e com percentuais de rapel cadastrados. Verifique!")
					_lLiberar = .F.
    			endif
			endif
		endif
		
/* nao usamos mais por esta rotina. GLPI 7001
		// Validacoes controle de verbas
		If _lLiberar
			_wverbas = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_VERBA")
			if _wverbas = '1'
				_wmatriz = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_VACBASE")
				_wljmatriz = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_VALBASE")
				if _wmatriz=''
					_sErro += "Cliente sem codigo MATRIZ informado"
					_lLiberar = .F.
				endif
				if _wljmatriz=''
					_sErro += "Cliente sem codigo LOJA MATRIZ informado"
					_lLiberar = .F.
				endif
						
				// se o cliente controla verbas - verifica se tem bonificacao nesse pedido
				if _lLiberar
					for _nLinha = 1 to len (aCols)
						N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
						if ! GDDeleted ()
							if alltrim (GDFieldGet ("C6_BLQ")) != "R"
								if alltrim (GDFieldGet ("C6_BONIFIC")) != ""
									// busca na ZX5 se este tipo de bonificacao abate do saldo de verbas
									//if fBuscaCpo ('ZX5', 1, xfilial('ZX5') + '22' + GDFieldGet ("C6_BONIFIC"), "ZX5_22CONT") = 'S'
									if u_RetZX5 ('22', GDFieldGet ("C6_BONIFIC"), "ZX5_22CONT") = 'S'   
										_wbonif = .T.
										exit
									endif
								endif
							endif								
						endif
					next
					// se tem bonificacao no pedido atual - verifica saldo a bonificar
					if _wbonif
						_wSldBonif = 0
						// busca saldo a bonificar
						_sQuery := ""
						_sQuery += " SELECT SUM(ZA4.ZA4_VLR) - ISNULL( ( SELECT SUM(ZA5_VLR)"
						_sQuery += "         			      		       FROM ZA5010"
						_sQuery += "       				  		          WHERE D_E_L_E_T_ = ''"
						// eu QUERO todas as filiais para compor o saldo da verba --> _oSQL:_sQuery +=    " AND ZA5.ZA5_FILIAL = '" + xfilial ("ZA5") + "'"
						_sQuery += "       				  		            AND ZA5_TLIB = '1'"
						_sQuery += "         						        AND ZA5_CLI  = ZA4.ZA4_CLI
						_sQuery += "                                        AND ZA5_LOJA = ZA4.ZA4_LOJA) ,0)"
						_sQuery += "  FROM ZA4010 AS ZA4"
						_sQuery += " WHERE ZA4.D_E_L_E_T_ = ''
						_sQuery +=   " AND ZA4.ZA4_FILIAL = '" + xfilial ("ZA4") + "'"
						_sQuery += "   AND ZA4.ZA4_CLI    = '" + _wmatriz + "'"
						_sQuery += "   AND ZA4.ZA4_TLIB   = '1'"
						_sQuery += " GROUP BY ZA4.ZA4_CLI, ZA4.ZA4_LOJA"
						u_log (_sQuery)
						_aDados := U_Qry2Array(_sQuery)
						if len(_aDados) > 0
							_wSldBonif = _aDados[1,1]
						endif
						
						//msgalert(_wSldBonif)
						
						if _wSldBonif =0
							_sErro += "Cliente sem saldo a bonificar"
							_lLiberar = .F.
						endif
		
						// monta total a bonifica neste pedido (todos os itens)
						_wTotBonPed = 0
						_wipiprod = 0
						if _lLiberar
							// inicializa MAFISINI para poder bucar o valor da ST
							MaFisIni(M->C5_CLIENTE,;						// 1-Codigo Cliente/Fornecedor
							M->C5_LOJACLI,;						// 2-Loja do Cliente/Fornecedor
							IIf(M->C5_TIPO$'DB',"F","C"),;			// 3-C:Cliente , F:Fornecedor
							M->C5_TIPO,;							// 4-Tipo da NF
							M->C5_TIPOCLI,;						// 5-Tipo do Cliente/Fornecedor
							MaFisRelImp("MTR700",{"SC5","SC6"}),;	// 6-Relacao de Impostos que suportados no arquivo
							,;						   				// 7-Tipo de complemento
							,;										// 8-Permite Incluir Impostos no Rodape .T./.F.
							"SB1",;								// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
							"MTR700")								// 10-Nome da rotina que esta utilizando a funcao

							// tem que ler todos os itens do pedido
							_lTes = .F.
							_nQtItens = 0
							for _nLinha = 1 to len (aCols)
								N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
								if ! GDDeleted ()
									if alltrim (GDFieldGet ("C6_BONIFIC")) != ""
										// le todos os itens do pedido e calcula total a bonificar no pedido
										//if fBuscaCpo ('ZX5', 1, xfilial('ZX5') + '22' + GDFieldGet ("C6_BONIFIC"), "ZX5_22CONT") = 'S'
										if u_RetZX5 ('22', GDFieldGet ("C6_BONIFIC"), "ZX5_22CONT") = 'S'
											// busca IPI do item
											MaFisAdd( GDFieldGet ("C6_PRODUTO"),;
												GDFieldGet ("C6_TES"),;
												GDFieldGet ("C6_QTDVEN"),;
												GDFieldGet ("C6_PRCVEN"),;
												0,;
												"",;
												"",;
												"",;
												0,;
												0,;
												0,;
												0,;
												( GDFieldGet ("C6_QTDVEN")* GDFieldGet ("C6_PRCVEN") ),;
												0,;
												0,;
												0)
											_nQtItens ++
											
											_nValSol := MaFisRet(_nQtItens, "IT_VALSOL")
											_nValIpi := MaFisRet(_nQtItens, "IT_VALIPI")
											_wTotBonPed = _wTotBonPed + GDFieldGet ("C6_VALOR") + _nValSol + _nValIPI 
										endif
									endif
//									if GDFieldGet ("C6_TES") $ '630/657'
//										lTes = .T.
//									endif
								endif
							next
							_wSldOutBon = 0
							//msgalert("SALDO OUTROS PEDIDOS")
							//msgalert(_wSldOutBon)
							//msgalert("SALDO A BONIFICAR")
							//msgalert(_wSldBonif)
							//msgalert("TOTAL A BONIFICAR NO PEDIDO")
							//msgalert(_wTotBonPed)
						
							if _lLiberar 
								if  _wSldBonif < (_wTotBonPed + _wSldOutBon)
									_sErro += "Saldo a bonificar � insuficiente para libera��o dos itens bonificados. Verifique!"
									_lLiberar = .F.
								else
									u_help ("Pedido com itens a bonificar, ir� abater saldo em verbas." )
									_lLiberar = .T.
								endif
							endif								
						endif
					endif
				endif
			endif
		endif
*/
		// Se alguma das linhas tinha problemas, nao libera nenhuma.
		if ! empty (_sErro)
			u_help (_sErro)
			for _nLinha = 1 to len (aCols)
				N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
				if ! GDDeleted ()
					GDFieldPut ("C6_QTDLIB", 0)
				endif
			next
		endif
		CursorArrow ()
		

	else  // Remover liberacao
		if ! empty (_sErro)
			u_help (_sErro)
		endif
		CursorWait ()
		for _nLinha = 1 to len (aCols)
			N := _nLinha  // No R23 nao permite mais usar variavel nao-local como contador no FOR.
			if ! GDDeleted ()
				GDFieldPut ("C6_QTDLIB", 0)
			endif
		next
		CursorArrow ()

	endif

	N := _n
	if type ("oGetDad") == "O"
		oGetDad:oBrowse:Refresh ()
	endif

	U_ML_SRArea (_aAreaAnt)
return