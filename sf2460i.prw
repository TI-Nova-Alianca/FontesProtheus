// Programa..: SF2460I
// Autor.....: Jeferson Rech
// Data......: Maio/2004
// Descricao.: P.E. no final da geracao da NF de saida, mas ainda dentro da transacao.
//
// Tags de localização
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. no final da geracao da NF de saida, mas ainda dentro da transacao
// #PalavasChave      #PE #NF #notadesaida 
// #TabelasPrincipais #SF2 #SD2 
// #Modulos           #faturamento #FAT
//
// Historico de alteracoes:
// 15/02/2008 - Robert - Ajustes calculo subst.trib. estado de MG
// 18/02/2008 - Robert - Criado tratamento generico para subst.trib. (independente da UF)
// 07/03/2008 - Robert - Empresa 02 foi desativada. Nao precisa mais movimentar.
// 17/03/2008 - Robert - Geracao titulos na empresa 02 foi reativada.
// 17/04/2008 - Robert - Chamada rotina U_FrtNFS.
// 23/04/2008 - Robert - Criados logs para analise de performance
//                     - Eliminadas linhas comentariadas.
// 16/05/2008 - Robert - Gravacao substituicao tributaria no SF3.
// 19/05/2008 - Robert - Gravacao duplicata extra de substituicao tributaria passa a ser no GrvDupST.
// 23/05/2008 - Robert - Alteracoes diversas calculo e gravacao de ICMS retido (subst.tributaria).
// 05/06/2008 - Robert - Novos parametros funcao GrvDupST.
// 10/06/2008 - Robert - Criado tratamento para campo A1_VASTBON.
// 13/06/2008 - Robert - Ajustes gravacao ST
// 19/06/2008 - Robert - Chama verificacao de dados para NFE.
// 04/07/2008 - Robert - Geracao de titulos PVCond passa a ser executada via RPC.
// 10/07/2008 - Robert - Geracao de evento em formato 'Objeto'.
// 30/07/2008 - Robert - Gravacao de dados adicionais no ZZ4.
//                     - Nao testa mais os dados para NF-e
// 04/08/2008 - Robert - Gravacao titulos PVCond passa a ser em loop para casos de erro de conexao.
// 07/08/2008 - Robert - Gravacao eventos passa a incluir tambem o cliente.
//                     - Grava evento quando cliente nao gera cobranca de ST sobre bonificacoes.
// 13/08/2008 - Robert - Gravacao titulos PVCond passa a usar RPCSetType(3) para nao consumir licencas.
//                     - Eventos passam a ser gravados via metodo proprio.
//                     - Chamada da rotina de ajuste de estoques na empresa 01.
// 21/08/2008 - Robert - Rotina de ajuste de estoques na empresa 01 passa a usar o campo D3_vaDoc02.
// 28/08/2008 - Robert - Grava endereco de entrega, pedido e representante no ZZ4.
// 04/09/2008 - Robert - Grava NF originais no ZZ4 em caso de devolucao.
// 07/10/2008 - Robert - Grava NF de envio para armazem no ZZ4 em caso de venda pelo armazem.
// 23/10/2008 - Robert - Reduz valor fatura quando tem retencao de ST (gravacao
//                       da ST nos campos padrao faz com que o sistema some aos titulos gerados).
// 10/11/2008 - Robert - Zera campos do SD2, SFT e SF3 quando TES especifico para bonificacao.
// 27/11/2008 - Robert - Incluida mensagem de 'acompanha boleto'.
// 10/12/2008 - Robert - Nao levava a serie da NF para o prefixo do titulo PvCond na Vinicola.
// 17/02/2009 - Robert - Desabilitada gravacao de logs.
// 19/02/2009 - Robert - Passa a ler o parametro VA_BCOBOL.
// 25/02/2009 - Robert - Passa a subtrair o valor da ST do valor contabil do livro fiscal.
//                     - Eliminados varios trechos comentariados.
//                     - Nao considerava o D2_LOCAL na funcao _AjEstq01().
// 26/02/2009 - Robert - Ajuste de estoque na empresa 01 passa a trabalhar com processos batch (ZZ6).
//                     - Soh inclui msg "BOL.BANC.ANEXO...." nos dados adicionais quando gerou duplicatas.
// 11/03/2009 - Robert - Criados tratamentos para que o armazem geral possa ser representado tambem
//                       por fornecedor e nao somente por cliente.
//                     - Passa a gravar campo D3_VACHVEX nas transferencias de estoque ref. armazem externo.
// 31/03/2009 - Robert - Nao requisita mais o produto 9999 (generico) quando vende pela vinicola.
// 11/05/2009 - Robert - Gravacao do campo F2_vaDCO e inclusao de mensagem ref. DCO nos dados adicionais.
// 24/06/2009 - Robert - Novo numero de regime especial (16.000178297-01) para o estado de MG.
//                     - Desabilitado zeramento val.cont. do SF3 p/ NF compl. IPI por que falta
//                       tratamento no SFT. Alem disso, o parametro ML_ZECIPI estava como N.
// 20/08/2009 - Robert - Nao desconta mais o valor da ST do valor contabil dos livros fiscais.
// 17/09/2009 - Robert - Pasagem do campo C5_VAJST para a funcao GrvDupST.
// 29/09/2009 - Robert - Revisao para compatibilizacao com DBF, para uso tambem em Livramento.
// 27/10/2009 - Robert - Tratamento de ST passa a ser executado tambem na filial 03 (Livramento).
// 11/02/2010 - Robert - A reducao vl.titulos ref.ST jah retida considerava tb.itens bonificados.
// 06/06/2010 - Robert - Incluida chamada do A260Comum depois da chamada do A260Processa.
// 07/06/2010 - Robert - Envia e-mail de notificacao apos a geracao da nota, em determinados casos.
// 26/07/2010 - Robert - Gravacao do campo D2_vaPeRap.
// 01/10/2010 - Fabiano- Trocado email para envio de alexandra para contabilidade 
// 13/10/2010 - Robert - Alimenta campo F2_vaPeRap a partir do C5_vaPeRap e nao mais do A1_TxRapel.
// 17/10/2010 - Robert - Gravacao do campo F2_vaNFFD.
//                     - Tratamentos para NFs de envio/devolucao de deposito fechado (filial 04).
// 24/10/2010 - Robert - Melhorias tratamentos para NFs envolvidas com deposito fechado (filial 04).
// 25/10/2010 - Robert - Conexao RPC (tratamento PVCond) passa a ser feita no server 'localhost'.
// 01/11/2010 - Robert - Avisa quando faturar mais de um pedido na mesma nota ou faturar parcialmente um pedido.
// 11/11/2010 - Robert - Geracao de titulos PVCond passa a ser executada via Batch.
// 19/11/2010 - Robert - Regrava CD2_CST com '10' quando tiver calculo de ST ateh descobrirmos por que estah trazendo '00'
// 02/12/2010 - Robert - Passa data base a ser usada em algumas rotinas batch ref. deposito.
// 15/12/2010 - Robert - Criado tratamento para campo ZX5_MODO.
// 23/12/2010 - Robert - Envia e-mail de notificacao para contabilidade quando for feita venda de sucos para Santa Catarina.
// 29/12/2010 - Robert - Se tem muitas NF de origem, nao inclui as suas datas nos dados adicionais, para economizar espaco.
// 06/01/2011 - Robert - Gravacao dos campos F2_VEICUL1, 2 e 3 a partir de campos customizados do SC5.
// 11/01/2011 - Robert - Alterada leitura do ZZ2 para geracao de msg. para NF (novo formato do arquivo ZZ2).
// 21/02/2011 - Robert - Criado tratamento para quando der erro em rotina automatica, mas nao houver arquivo de log gerado.
// 17/03/2011 - Robert - Montagem das mensagens adicionais passa a usar a funcao _SomaMsg ().
//                     - Passa a considerar os parametros MV_NFEMSA1 e MV_NFEMSF4 para montagem de dados adicionais.
//                     - Incluidas mensagens adicionais para zona franca de Manaus / ALC.
// 28/03/2011 - Robert - Criado tratamento para gravacao do SZI (conta corrente associados).
// 01/04/2011 - Robert - Passa a alimentar o F2_TPFRETE com o conteudo do C5_TPFRETE.
// 19/05/2011 - Robert - Regravacao do campo CD2_ALIQ com a aliquota interna da UF destino quando tem ST.
// 11/08/2011 - Robert - Passa a verificar notas tipo 'B' na funcao de atualizacao do SZI.
// 08/09/2011 - Robert - Geracao do SZI passa a verificar apenas notas tipo 'B'. Passa a usar classe ClsCtaCorr.
// 13/10/2011 - Robert - Criado tratamento para o campo C5_VAOBSNF.
// 24/04/2012 - Robert - Agendamento de batch para incluir NF de entrada na filial destino quando transf. entre filiais.
// 30/09/2012 - Robert - Criados campos D3_VANFRD, D3_VASERRD e D3_VAITNRD para substituir o D3_VACHVEX no controle de armazens externos.
// 28/02/2013 - Robert - Desabilitado aviso de venda de sucos para SC.
// 21/06/2013 - Robert - Tratamento de armazem passa a usar a classe ClsAmzGer.
//                     - Remessa para armazem geral passa a ser via batch.
// 21/06/2013 - Leandro DWT - Retira reserva (SC0) dos produtos faturados
// 10/07/2013 - Leandro DWT - Alteração para que a filial de depósito não seja fixo '04', pegando da tebala ZS da SX5 
// 27/09/2013 - Leandro DWT - Grava informações adicionais na tabela SF2 e não mais na tabela ZZ4
// 13/11/2013 - Leandro DWT - Envia e-mail para responsável na filial para confirmar o recebimento da nota fiscal
// 15/01/2014 - Leandro DWT - grava evento para histórico de NF
// 17/12/2014 - Robert  - Notifica filial destino quando emitida NF transferencia.
// 30/06/2016 - Robert  - Nao busca mais inscricao do sibstituto tributario quando tem ST (vamos usar ST pelo padrao do sistema).
// 21/08/2015 - Robert  - Grava numero da carga do OMS nos dados adicionais da nota.
// 23/09/2015 - Robert  - Estabelece tempo limite de 10 minutos para o batch criado para geracao de pre-nota 
//						  de entrada de transferencia entre filiais.
// 28/10/2015 - Robert  - Nao gera batch de transf. filial para a propria filial (ex. notas de imposto, etc).
// 13/05/2016 - Robert  // nem entrou no ar --> Criada mensagem adicional do fundo de combate a pobreza.
//                      - Desabilitada gravacao do ZZ4 (dados adicionais fica apenas em campos memo do SF2).
//                      - Desabilitados ajustes ref. ST (CD2_CST, CD2_ALIQ, abatim.valor ST bonif. no SE1) pois 
//                        nao geravam nada ha tempo.
// 09/06/2017 - Catia   - alteração para gravacao dos valores de rapel no SF2 e no SE1 
// 20/06/2017 - Catia   - alterada opcao de envio por email de notas emitdas para UF's onde é necessaria GUIA de 
//                        recolhimento de ST
// 27/06/2017 - Catia   - alteração para gravacao do campo de desconto no SE1 conforme o valor do rapel do proprio E1
// 30/06/2017 - Robert  - Desabilitados tratamentos para PVCond, estoque02, armazem externo.
// 06/07/2017 - Robert  - Gravacao de observacao de redespacho nos dados adicionais.
// 11/07/2017 - Robert  - Removidos tratamentos para deposito fechado (filial 04) por ha tempos foi fechada.
// 15/09/2017 - Robert  - Regrava pesos e volumes no SF2 com base no SC6 para pegar casos de faturamento parcial.
// 10/11/2017 - Robert  - Gravacao do campo F2_Veicul1 a partir do C5_VEICULO (patrao Protheus) e nao mais do 
//                        C5_vaVeic1 (vai ser desativado).
//                      - Gravacao do campo F2_Veicul1 a partir do DAK quando faturado via carga do OMS.
// 23/11/2018 - Catia   - desabilitada a geracao do bat de transferencias entre filiais
// 21/01/2018 - Sandra  - Incluso estado RJ na emissão e-mail para notas com ST
// 05/03/2019 - Andre   - Na impressão da nota sai apenas itens sem bloqueios. C6_BLQ NOT IN ('B','S')
// 29/03/2019 - Andre   - Adicionado envio de e-mail quando tiver notas de devolução
// 01/04/2020 - Andre   - Gravacao dos campos F2_TRANSP e F2_FRETE para notas geradas pelo Ativo.
// 03/04/2020 - Andre   - Gravacao do campo F2_TRNAPS para notas geradas pela BAIXA DE ATIVOS FIXO.
// 07/07/2020 - Cláudia - Gravação de conta corrente para venda de mudas para associados. GLPI: 8120
// 15/07/2020 - Cláudia - Ajustes da conta corrente para venda de mudas para associados. GLPI: 8120
// 11/08/2020 - Robert  - Gravacao campos e1_nsutef, e1_adm, e1_tipo (venda c/ cartao credito) GLPI 8295
// 27/08/2020 - Cláudia - Gravação do campo e1_cartaut com c5 -> c5_vaaut. 
//                        Incluida verificação se campos do SC5 estao preenchidos para gravar na SE1
// 24/10/2020 - Robert  - Desabilitada gravacao SC0 (reservas) cfe. campo C5_VARESER (nao usamos mais desde 2014).
// 10/12/2020 - Claudia - Gravação do campo ID transação do pagar.me em títulos. GLPI: 9012
// 12/07/2021 - Robert  - Representante 328 nao quer que seja impresso seu nome nos dados adicionais (GLPI 10472).
// 11/08/2021 - Robert  - Grava obs do pedido na cta.corrente associados, quando compra de mudas (GLPI 10673).
// 10/09/2021 - Claudia - Gravação de conta corrente para venda de açucar mascavo para associados. GLPI: 10916
// 27/09/2021 - Claudia - Ajustadas validações para envio de email. GLPI: 10927
// 29/09/2021 - Claudia - Tratamento para venda de milho. GLPI: 10994
// 05/10/2021 - Claudia - Criado novo grupo para email de guia/st grupo 132. GLPI: 11028 
// 15/10/2021 - Robert  - Ajuste sintaxe teste NF venda milho p/ associados (estava assim --> case _sTProd := '2')
// 10/06/2022 - Claudia - Ajuste de lançamento para mudas. GLPI: 12191
// 28/07/2022 - Claudia - Incluida a gravação de historico para e-commerce/pagar-me. GLPI: 12392
// 30/08/2022 - Claudia - Incluida a gravação das contas para titulos pagar-me. GLPI: 12280
// 11/11/2022 - Robert  - Gera títulos e msg adicional cobranca ST para MG (GLPI 12779)
// 01/12/2022 - Robert  - Gravava E1_COMIS1...5 indevidamente na funcao _TitSTMG().
// 18/01/2023 - Robert  - Gravar E1_TIPO=IMP e nao mais DP na funcao _TitSTMG() - GLPI 12779
// 20/02/2023 - Robert  - Gravar rotina FINA040 e FINA050 nos titulos de ST para MG (GLPI 12779)
// 22/02/2023 - Cláudia - Retirada gravação de representante nas mensagens da NF. GLPI: 12951
// 27/02/2023 - Robert  - Gravar E1_TIPO=TRS e nao mais IMP na funcao _TitSTMG() - GLPI 12779
//                      - Gravar E1_VACHVEX e E2_VACHVEX na funcao _TitSTMG() - GLPI 12779
//                      - Melhorado E2_HIST na funcao _TitSTMG() - GLPI 12779
// 27/02/2023 - Sandra  - Gravar E2_TIPO=TRS e nao mais IMP na funcao _TitSTMG() - GLPI 12779
// 01/06/2023 - Claudia - Alterada data de vencimento para titulos a pagar ST. GLPI: 13653
// 20/10/2023 - Robert  - Criado tratamento para venda de tambores a associados (GLPI 14397)
// 20/11/2023 - Robert  - Verifica C6_QTDVEN antes de dar update no F2_PLIQUI, F2_PBRUTO, F2_VOLUME1
// 31/01/2024 - Claudia - Ajuste no email de devoluções. GLPI: 14830
// 21/03/2024 - Claudia - Criado parâmetro de exceção de UF. GLPI: 15112 
// 03/04/2024 - Claudia - Retirado campos. GLPI: 14763
//
// ---------------------------------------------------------------------------------------------------------------
User Function sf2460i ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nPJurBol  := 0
	local _wtotrapel := 0
	local _sSQL      := ""
	local _oSQL      := NIL
	
	// Verifica valor rapel
    _sSQL := ""
    _sSQL += " SELECT SUM (D2_VRAPEL)"
  	_sSQL += "   FROM " + RetSQLName ("SD2") + " AS SD2"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
   	_sSQL += "    AND SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
	_sSQL += "    AND SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
	_sSQL += "    AND SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
    aDados := U_Qry2Array(_sSQL)
	if len (aDados) > 0 
		_wtotrapel = aDados[1,1]
	endif
	
	// Grava campos adicionais na nota fiscal
	RecLock("SF2",.F.)
	//REPLACE SF2->F2_vaDCO   WITH SC5->C5_vaDCO
	REPLACE SF2->F2_vaPeRap WITH SC5->C5_vaPeRap
	REPLACE SF2->F2_VARAPEL WITH _wtotrapel
	REPLACE SF2->F2_vaNFFD  WITH SC5->C5_vaNFFD
	REPLACE SF2->F2_Veicul1 WITH SC5 -> C5_VEICULO  //SC5->C5_vaVeic1
	//REPLACE SF2->F2_Veicul2 WITH SC5->C5_vaVeic2
	//REPLACE SF2->F2_Veicul3 WITH SC5->C5_vaVeic3
	REPLACE SF2->F2_TPFRETE WITH SC5->C5_TPFRETE
	REPLACE SF2->F2_VAFEMB  WITH SC5->C5_VAFEMB
	REPLACE SF2->F2_VAUser  WITH cUserName
	MsUnlock()	
	
	//ATUALIZA CAMPOS DE TRANSPORTADORA E TIPO FRETE EM NOTAS GERADAS PELO ATIVO FIXO.
	if IsInCallStack ("ATFA060")
		RecLock("SF2",.F.)
		REPLACE SF2->F2_TRANSP  WITH FN9->FN9_TRANSP
		REPLACE SF2->F2_TPFRETE WITH FN9->FN9_TPFRETE
		//REPLACE SF2->F2_COND    WITH FN9->FN9_COND
		MsUnlock()
	endif
	
	//ATUALIZA CAMPO DE TRANSPORTADORA EM NOTAS GERADAS PELA BAIXA DE ATIVOS.
	if IsInCallStack ("ATFA036")
		REPLACE SF2->F2_TRANSP  WITH FN6->FN6_TRANSP
	endif
	
	// Busca veiculo da carga
	if IsInCallStack ("MATA460B")
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE SF2 "
		_oSQL:_sQuery += " SET F2_VEICUL1 = DAK_CAMINH"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2, "
		_oSQL:_sQuery +=            RetSQLName ("DAK") + " DAK " 
		_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SF2.F2_FILIAL  = '" + sf2 -> f2_filial + "'"
		_oSQL:_sQuery +=   " AND SF2.F2_DOC     = '" + sf2 -> f2_doc    + "'"
		_oSQL:_sQuery +=   " AND SF2.F2_SERIE   = '" + sf2 -> f2_serie  + "'"
		_oSQL:_sQuery +=   " AND DAK.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND DAK.DAK_FILIAL = SF2.F2_FILIAL"
		_oSQL:_sQuery +=   " AND DAK.DAK_COD    = SF2.F2_CARGA"
		_oSQL:Log ()
		_oSQL:Exec ()
	endif

	// Grava peso de acordo com o que foi informado nos itens do pedido.
	// A principio o padrao ficaria certo, pois faturamos sempre o pedido completo. Mas, se faturar parcial no SC9, pode dar diferenca.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "UPDATE SF2 "
	_oSQL:_sQuery += " SET F2_PLIQUI  = ITENS.PESOLIQ, "
	_oSQL:_sQuery +=     " F2_PBRUTO  = ITENS.PESOBRUTO, "
	_oSQL:_sQuery +=     " F2_VOLUME1 = ITENS.QTVOLUMES "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2 "
	_oSQL:_sQuery +=    " INNER JOIN (SELECT D2_FILIAL, D2_DOC, D2_SERIE,"
	_oSQL:_sQuery +=                       " SUM (CASE WHEN C6_QTDVEN > 0 THEN C6_VAPLIQ  * D2_QUANT / C6_QTDVEN ELSE 0 END) AS PESOLIQ,"
	_oSQL:_sQuery +=                       " SUM (CASE WHEN C6_QTDVEN > 0 THEN C6_VAPBRU  * D2_QUANT / C6_QTDVEN ELSE 0 END) AS PESOBRUTO,"
	_oSQL:_sQuery +=                       " SUM (CASE WHEN C6_QTDVEN > 0 THEN C6_VAQTVOL * D2_QUANT / C6_QTDVEN ELSE 0 END) AS QTVOLUMES"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC6") + " SC6, " 
	_oSQL:_sQuery +=                             RetSQLName ("SD2") + " SD2 " 
	_oSQL:_sQuery +=                 " WHERE SC6.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SC6.C6_FILIAL  = SD2.D2_FILIAL"
	_oSQL:_sQuery +=                   " AND SC6.C6_NUM     = SD2.D2_PEDIDO"
	_oSQL:_sQuery +=                   " AND SC6.C6_ITEM    = SD2.D2_ITEMPV"
	_oSQL:_sQuery +=                   " AND SC6.C6_BLQ NOT IN ('B','S')"
	_oSQL:_sQuery +=                   " AND SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                 " GROUP BY D2_FILIAL, D2_DOC, D2_SERIE"
	_oSQL:_sQuery +=                ") AS ITENS"
	_oSQL:_sQuery +=                " ON (ITENS.D2_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery +=                " AND ITENS.D2_DOC    = SF2.F2_DOC"
	_oSQL:_sQuery +=                " AND ITENS.D2_SERIE  = SF2.F2_SERIE)"
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SF2.F2_FILIAL  = '" + sf2 -> f2_filial + "'"
	_oSQL:_sQuery +=   " AND SF2.F2_DOC     = '" + sf2 -> f2_doc    + "'"
	_oSQL:_sQuery +=   " AND SF2.F2_SERIE   = '" + sf2 -> f2_serie  + "'"
	_oSQL:Exec ()

	// Grava dados adicionais nos titulos gerados.
	sa1 -> (dbsetorder (1))
	if sa1 -> (dbseek (xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, .F.))
		_nPJurBol = GetMv ("VA_PJURBOL")
		se1 -> (dbsetorder (1))  // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		se1 -> (dbseek (xfilial ("SE1") + sf2 -> f2_serie + sf2 -> f2_doc, .T.))
		do while ! se1 -> (eof ()) .and. se1 -> e1_filial == xfilial ("SE1") .and. se1 -> e1_prefixo == sf2 -> f2_serie .and. se1 -> e1_num == sf2 -> f2_doc
			reclock ("SE1", .F.)

			// Deixa desconto e juros gravados no titulo, por que existem titulos de subst.
			// tributaria, por exemplo, que nao tem desconto. Assim, nao fica calculando
			// nada no momento da impressao nem da geracao do CNAB.
			se1 -> e1_vaDesco = sa1 -> a1_DescFin
			se1 -> e1_vaPJuro = _nPJurBol

			// grava rapel proporcional
			se1 -> e1_varapel = ROUND(se1 -> e1_valor * _wtotrapel / sf2 -> f2_valbrut,2)

			// Campos customizados para venda com cartao de credito via modulo de faturamento (GLPI 8295)
			If !empty(sc5 -> c5_vansu)
				se1 -> e1_nsutef  = sc5 -> c5_vansu
				se1 -> e1_doctef  = sc5 -> c5_vansu
			EndIf
			If !empty(sc5 -> c5_vaadmin)
				se1 -> e1_adm     = sc5 -> c5_vaadmin
			EndIf
			If !empty(sc5 -> c5_vatipo)
				se1 -> e1_tipo    = sc5 -> c5_vatipo
			EndIf
			If !empty(sc5 -> c5_vaaut)
				se1 -> e1_cartaut = sc5 -> c5_vaaut
			EndIf
			If !empty(sc5 -> c5_vaidt) // pedidos e-commerce
				se1 -> e1_vaidt = sc5 -> c5_vaidt
				se1 -> e1_hist  = 'E-COMMERCE/PAGAR.ME'
				//
				If se1->e1_filial == '01'
					se1->e1_portado = '237'
					se1->e1_agedep  = '03471'
					se1->e1_conta   = '0000470'
				EndIf
				If se1->e1_filial == '13'
					se1->e1_portado = '041'
					se1->e1_agedep  = '0873 '
					se1->e1_conta   = '0619710901'
				EndIf
			EndIf
			msunlock ()
			se1 -> (dbskip ())
		enddo
	endif

	// Tratamento para controle de fretes.
	if cNumEmp == "0101"
		U_FrtNFS ("I", sc5 -> c5_num)
	endif

	// Grava dados adicionais para posterior uso na impressao da nota / envio para NF eletronica.
	_DadosAdic ()

	// Envia e-mail de notificacao em determinadas condicoes
	_Notifica ()

	// Verificacoes do pedido de venda
	_VerPed ()
	
	// Verifica devolucao de compra
	if sf2 -> f2_tipo = 'D'
		_VerDev ()
	endif
	
	// Atualiza conta corrente de associados - para compra de mudas
	_AtuSZIMudas ()

	// grava evento para histórico de NF
	if !sf2 -> f2_TIPO $ "B/D"
		_HistNf ()
	endif

	// Gera titulos antecipacao ST para MG
	_TitSTMG ()

	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Grava dados adicionais para posterior uso na impressao da nota / envio para NF eletronica.
static function _DadosAdic ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _sMsgFisco := ""
	local _sMsgContr := ""
	local _sEndEnt   := ""
	local _sMsgST    := ""
	local _sQuery    := ""
	local _aNFOri    := {}
	local _sNFOri    := ""
	local _aRetSQL   := {}
	local _MVNFEMSA1 := AllTrim(GetNewPar("MV_NFEMSA1",""))
	local _MVNFEMSF4 := AllTrim(GetNewPar("MV_NFEMSF4",""))
	local _lInfAdZF  := GetNewPar("MV_INFADZF",.F.)
	local _oSQL      := NIL
	local _nFormula	 := 0
	local _nNFOri	 := 0

	if sf2 -> f2_icmsret != 0
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select distinct ZZ2_MSGNF"
		_oSQL:_sQuery += " from " + RetSQLName ("ZZ2") + " ZZ2 "
		_oSQL:_sQuery += " where ZZ2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_FILIAL  = '" + xfilial ("ZZ2")   + "'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_FILI   LIKE '%" + cFilAnt + "%'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_UF      = '" + sf2 -> f2_est + "'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_DTINI  <= '" + dtos (sf2 -> f2_emissao) + "'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_DTFIM  >= '" + dtos (sf2 -> f2_emissao) + "'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_ATIVO   = 'S'"
		_oSQL:_sQuery += "   and ZZ2.ZZ2_MSGNF  != ''"
		_sMsgST = _oSQL:RetQry ()
		if ! empty (_sMsgST)
			_SomaMsg (@_sMsgFisco, _sMsgST)
		endif
	endif

	// Mensagens do pedido de venda.
	if ! empty (sc5 -> c5_menpad)
		_SomaMsg (@_sMsgFisco, formula (sc5 -> c5_menpad))
	endif
	if ! empty (sc5 -> c5_mennota)
		_SomaMsg (@_sMsgContr, sc5 -> c5_mennota)
	endif

	// Mensagens cfe. formulas dos TES dos itens.
	if ! empty (_MVNFEMSF4)
		_sQuery := ""
		_sQuery += " select distinct F4_FORMULA "
		_sQuery += " from " + RetSQLName ("SD2") + " SD2,"
		_sQuery +=            RetSQLName ("SF4") + " SF4 "
		_sQuery += " where SD2.D_E_L_E_T_ != '*'"
		_sQuery += "   and SF4.D_E_L_E_T_ != '*'"
		_sQuery += "   and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
		_sQuery += "   and SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
		_sQuery += "   and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
		_sQuery += "   and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
		_sQuery += "   and SF4.F4_CODIGO   = SD2.D2_TES"
		_sQuery += "   and SF4.F4_FORMULA != ''"
		_aFormulas = aclone (U_Qry2Array (_sQuery))
		for _nFormula = 1 to len (_aFormulas)
			if _MVNFEMSF4 == "F"
				_SomaMsg (@_sMsgFisco, Formula (_aFormulas [_nFormula, 1]))
			elseif _MVNFEMSF4 == "C"
				_SomaMsg (@_sMsgContr, Formula (_aFormulas [_nFormula, 1]))
			endif
		next
    endif

	_SomaMsg (@_sMsgContr, "Pedido: " + alltrim (sc5 -> c5_num))

	if ! empty (sf2 -> f2_carga)
		_SomaMsg (@_sMsgContr, "Carga: " + sf2 -> f2_carga)
	endif
	if ! empty (sc5 -> c5_pedcli)
		_SomaMsg (@_sMsgContr, "OC: " + alltrim (sc5 -> c5_pedcli))
	endif

	// Busca notas originais, em caso de devolucao.
	if sf2 -> f2_tipo == "D"
		_sQuery := ""
		_sQuery += " select distinct D2_NFORI, "
		_sQuery +=                 " (select F1_EMISSAO "
		_sQuery +=                    " from " + RetSQLName ("SF1") + " SF1"
		_sQuery +=                   " where SF1.D_E_L_E_T_ != '*'"
		_sQuery +=                     " and SF1.F1_FILIAL   = '" + xfilial ("SF1") + "'"
		_sQuery +=                     " and SF1.F1_DOC      = SD2.D2_NFORI"
		_sQuery +=                     " and SF1.F1_SERIE    = SD2.D2_SERIORI"
		_sQuery +=                     " and SF1.F1_FORNECE  = SD2.D2_CLIENTE"
		_sQuery +=                     " and SF1.F1_LOJA     = SD2.D2_LOJA)"
		_sQuery += " from " + RetSQLName ("SD2") + " SD2"
		_sQuery += " where SD2.D_E_L_E_T_ != '*'"
		_sQuery += "   and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
		_sQuery += "   and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
		_sQuery += "   and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
		_aNFOri = aclone (U_Qry2Array (_sQuery))
		if len (_aNFOri) > 0
			_sNFOri = "Devol.NF "

			// Se tem muitas notas originais, nao inclui a data, pois a mensagem ficaria longa demais.
			if len (_aNFOri) > 10
				for _nNFOri = 1 to len (_aNFOri)
					_sNFOri += alltrim (_aNFOri [_nNFOri, 1]) + iif (_nNFOri < len (_aNFOri), ",", "")
				next
			else
				for _nNFOri = 1 to len (_aNFOri)
					_sNFOri += alltrim (_aNFOri [_nNFOri, 1]) + " de " + dtoc (stod (_aNFOri [_nNFOri, 2])) + iif (_nNFOri < len (_aNFOri), ",", "")
				next
			endif

			_SomaMsg (@_sMsgContr, _sNFOri)
		endif
	endif

	// Mensagens cfe. cadastro do cliente e endereco de entrega.
	sa1 -> (dbsetorder (1))
	if sa1 -> (dbseek (xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, .F.))
		if ! empty (sa1 -> a1_mensage) .and. ! empty (_MVNFEMSA1)
			if _MVNFEMSA1 == "F"
				_SomaMsg (@_sMsgFisco, Formula (sa1 -> a1_mensage))
			elseif _MVNFEMSA1 == "C"
				_SomaMsg (@_sMsgContr, Formula (sa1 -> a1_mensage))
			endif
    	endif
		if ! empty (sa1 -> a1_endent) .and. alltrim (sa1 -> a1_endent) != alltrim (sa1 -> a1_end)
			_sEndEnt = "End.entrega: " + alltrim (sa1 -> a1_endent)
			if ! empty (sa1 -> a1_bairroe)
				_sEndEnt += "-bairro:" + alltrim (sa1 -> a1_bairroe)
			endif
			if ! empty (sa1 -> a1_mune)
				_sEndEnt += "-" + alltrim (sa1 -> a1_mune)
			endif
			if ! empty (sa1 -> a1_este)
				_sEndEnt += "-" + alltrim (sa1 -> a1_este)
			endif
			if ! empty (sa1 -> a1_cepe)
				_sEndEnt += "-" + alltrim (sa1 -> a1_cepe)
			endif
		endif
	endif
	if ! empty (_sEndEnt)
		_SomaMsg (@_sMsgContr, _sEndEnt)
	endif

	// Adiciona mensagem ref. boleto, conforme o banco informado no pedido.
	if cNumEmp == "0101" .and. sc5 -> c5_banco $ GetMv ("VA_BCOBOL")  // Por enquanto soh geramos boletos para estes bancos.
		_sQuery := ""
		_sQuery += " select sum (E1_VALOR)"
		_sQuery += "   from " + RetSQLName ("SE1") + " SE1 "
		_sQuery += "  where D_E_L_E_T_ != '*'"
		_sQuery += "    and E1_FILIAL  =  '" + xfilial ("SE1")   + "'"
		_sQuery += "    and E1_NUM     =  '" + sf2 -> f2_doc     + "'"
		_sQuery += "    and E1_PREFIXO =  '" + sf2 -> f2_serie   + "'"
		_sQuery += "    and E1_CLIENTE =  '" + sf2 -> f2_cliente + "'"
		_sQuery += "    and E1_LOJA    =  '" + sf2 -> f2_loja    + "'"
		if U_RetSQL (_sQuery) > 0  // Gerou contas a receber
			_SomaMsg (@_sMsgContr, "BOL.BANC.ANEXO(" + sc5 -> c5_banco + ")C/PROTESTO " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS VCTO")
		endif
	endif

	// Msg Zona Franca de Manaus / ALC
	sf3 -> (dbSetOrder(4))  // F3_FILIAL+F3_CLIEFOR+F3_LOJA+F3_NFISCAL+F3_SERIE
	If sf3 -> (MsSeek(xFilial("SF3")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_DOC+SF2->F2_SERIE))
		If !SF3->F3_DESCZFR == 0 
			_sQuery := ""
			_sQuery += " select sum (D2_DESCZFP), sum (D2_DESCZFC)"
			_sQuery +=   " from " + RetSQLName ("SD2") + " SD2"
			_sQuery +=  " where SD2.D_E_L_E_T_ != '*'"
			_sQuery +=    " and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
			_sQuery +=    " and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
			_sQuery +=    " and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
			_aRetSQL = U_Qry2Array (_sQuery)
			_nValPisZF = _aRetSQL [1, 1]
			_nValCofZF = _aRetSQL [1, 2]
			If _lInfAdZF .And. (_nValPisZF > 0 .Or. _nValCofZF > 0)
				_SomaMsg (@_sMsgFisco, "Descontos Ref. a Zona Franca de Manaus / ALC. ICMS - R$ "+str(SF3->F3_VALOBSE-SF2->F2_DESCONT-_nValPisZF-_nValCofZF,13,2)+", PIS - R$ "+ str(_nValPisZF,13,2) +"e COFINS - R$ " +str(_nValCofZF,13,2))
			ElseIF !_lInfAdZF .And. (_nValPisZF > 0 .Or. _nValCofZF > 0) 
				_SomaMsg (@_sMsgFisco, "Desconto Ref. ao ICMS - Zona Franca de Manaus / ALC. R$ "+str(SF3->F3_VALOBSE-SF2->F2_DESCONT-_nValPisZF-_nValCofZF,13,2))
		    Else
		    	_SomaMsg (@_sMsgFisco, "Total do desconto Ref. a Zona Franca de Manaus / ALC. R$ "+str(SF3->F3_VALOBSE-SF2->F2_DESCONT,13,2))
		    EndIF
		EndIf 			
	EndIf	

	// Verifica se a observacao do pedido deve ser levada para a nota.
	if sc5 -> c5_vaobsnf == 'S'
		_SomaMsg (@_sMsgContr, alltrim (sc5 -> c5_obs))
	endif                                                                                                       

	// Transportadora redespacho.
	if ! empty (sf2 -> f2_redesp)
		sa4 -> (dbsetorder (1))
		if sa4 -> (dbseek (xfilial ("SA4") + sf2 -> f2_redesp, .F.))
			_SomaMsg (@_sMsgContr, "Redesp:CNPJ " + sa4 -> a4_cgc + " " + alltrim (sa4 -> a4_nome))
		endif
	endif

	// Grava dados adicionais completos em campos memo.
	msmm(,,,_sMsgFisco,1,,,"SF2","F2_VACMEMF")
	msmm(,,,_sMsgContr,1,,,"SF2","F2_VACMEMC")

	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Acrescenta texto `a mensagem.
static function _SomaMsg (_sVariav, _sTexto)
	_sVariav += iif (! empty (_sVariav), "; ", "") + alltrim (_sTexto)
return
//
// --------------------------------------------------------------------------
// Envia e-mail de notificacao em determinadas condicoes.
static function _Notifica ()
	Local _oSQL     := ClsSQL ():New ()
	Local _sMsg     := ""
	Local _aDados   := {}
	Local _x        := 0
	Local _nVfcpdif := 0
	Local _nDifal   := 0
	Local _nIcmsRet := 0

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   F3_VFCPDIF "
	_oSQL:_sQuery += "    ,F3_DIFAL "
	_oSQL:_sQuery += "    ,F3_ICMSRET "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " AS SF2 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF3") + " AS SF3 "
	_oSQL:_sQuery += " 		ON SF3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SF3.F3_FILIAL  = SF2.F2_FILIAL "
	_oSQL:_sQuery += " 			AND SF3.F3_NFISCAL = SF2.F2_DOC "
	_oSQL:_sQuery += " 			AND SF3.F3_SERIE   = SF2.F2_SERIE "
	_oSQL:_sQuery += " 			AND SF3.F3_CLIEFOR = SF2.F2_CLIENTE "
	_oSQL:_sQuery += " 			AND SF3.F3_LOJA    = SF2.F2_LOJA "
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SF2.F2_EST NOT IN ('RS', 'RJ', 'PR', 'SC', 'MG', 'SP') "
	_oSQL:_sQuery += " AND SF2.F2_FILIAL  = '" + sf2 -> f2_filial  + "'"
	_oSQL:_sQuery += " AND SF2.F2_DOC     = '" + sf2 -> f2_doc     + "'"
	_oSQL:_sQuery += " AND SF2.F2_SERIE   = '" + sf2 -> f2_serie   + "'"
	_oSQL:_sQuery += " AND SF2.F2_CLIENTE = '" + sf2 -> f2_cliente + "'"
	_oSQL:_sQuery += " AND SF2.F2_LOJA    = '" + sf2 -> f2_loja    + "'"
	_aDados := aclone (_oSQL:Qry2Array ())

	For _x := 1 to Len(_aDados)
		If _aDados[_x, 1] > 0
			_nVfcpdif += 1
		EndIf

		If _aDados[_x, 2] > 0
			_nDifal += 1
		EndIf

		If _aDados[_x, 3] > 0
			_nIcmsRet += 1
		EndIf
	Next

	If _nVfcpdif > 0 .or. _nDifal > 0 .or. _nIcmsRet > 0 
		if !(alltrim(sf2 -> f2_est) $ GetMv("VA_UFGUIA"))
			_sMsg = "NF " + sf2 -> f2_doc + " emitida para " + sf2 -> f2_est + " Verifique GUIA/ST"
 			U_ZZUNU({'132'}, _sMsg, _sMsg)
		endif
	EndIf
Return
//
// --------------------------------------------------------------------------
// Verificacoes no pedido de venda.
static function _VerPed ()
	local _sQuery    := ""

	_sQuery := ""
	_sQuery += " SELECT COUNT (DISTINCT D2_PEDIDO)"
	_sQuery += " from " + RetSQLName ("SD2") + " SD2 "
	_sQuery += " where SD2.D_E_L_E_T_ != '*'"
	_sQuery += "   and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
	_sQuery += "   and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
	_sQuery += "   and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
	if U_RetSQL (_sQuery) > 1
		u_help ("A nota fiscal '" + sf2 -> f2_doc + "' faturou mais de um pedido. Se isso estiver correto, apenas ignore esta mensagem.")
	endif

	_sQuery := ""
	_sQuery += " SELECT COUNT (*)"
	_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9 "
	_sQuery +=  " WHERE SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
	_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
	_sQuery +=    " AND SC9.C9_NFISCAL = ''"
	_sQuery +=    " AND SC9.C9_PEDIDO IN (SELECT DISTINCT D2_PEDIDO"
	_sQuery +=                            " FROM " + RETSQLName ("SD2") + " SD2"
	_sQuery +=                           " WHERE SD2.D_E_L_E_T_ != '*'"
	_sQuery +=                             " and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
	_sQuery +=                             " and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
	_sQuery +=                             " and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "')"
	if U_RetSQL (_sQuery) > 1
		u_help ("A nota fiscal '" + sf2 -> f2_doc + "' NAO faturou todos os itens do pedido. Se isso estiver correto, apenas ignore esta mensagem.")
	endif
return
//
// --------------------------------------------------------------------------
// Verifica devolucao de compra.
static function _VerDev ()
	local _sMsg := ""
	local _x    := 0

	// Avisa interessados sobre devolucoes de compras.
	_oSQL:= ClsSQL():New()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT
	_oSQL:_sQuery += " 	   SD2.D2_CLIENTE AS FORNECEDOR	"	// 01
	_oSQL:_sQuery += "    ,SA2.A2_NOME"						// 02
	_oSQL:_sQuery += "    ,SD2.D2_COD AS PRODUTO"			// 03
	_oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO"		// 04
	_oSQL:_sQuery += "    ,SD2.D2_UM AS UNIDADE_MEDIDA"		// 05
	_oSQL:_sQuery += "    ,SD2.D2_QUANT AS QUANTIDADE"		// 06
	_oSQL:_sQuery += "    ,SD2.D2_PRCVEN AS PRECO_VENDA"	// 07
	_oSQL:_sQuery += "    ,SD2.D2_TOTAL AS VALOR_TOTAL"		// 08
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1"
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SB1.B1_COD = D2_COD"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " SA2"
	_oSQL:_sQuery += " 	ON SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SA2.A2_COD  = SD2.D2_CLIENTE"
	_oSQL:_sQuery += " 		AND SA2.A2_LOJA = SD2.D2_LOJA"
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SD2.D2_FILIAL   = '" + xfilial("SD2")    + "'"
	_oSQL:_sQuery += " AND SD2.D2_DOC      = '" + sf2 -> f2_doc     + "'"
	_oSQL:_sQuery += " AND SD2.D2_SERIE    = '" + sf2 -> f2_serie   + "'"
	_oSQL:_sQuery += " AND SD2.D2_CLIENTE  = '" + sf2 -> f2_cliente + "'"
	_oSQL:_sQuery += " AND SD2.D2_LOJA     = '" + sf2 -> f2_loja    + "'"
	_aDev := aclone(_oSQL:Qry2Array())

	if len(_aDev) > 0
		_sMsg := "<html>"
		_sMsg += "<b>Fornecedor:</b> " + _aDev[1,1] + " - " + _aDev[1,2] + " <br>"
		_sMsg += "<b>Nota Fiscal:</b> " + sf2 -> f2_doc+ "/" + sf2 -> f2_serie + " <br>"
		_sMsg += "<br>"
		_sMsg += "<table border='1'>"
		_sMsg += "	<tr> "
		_sMsg += "		<td> Produto </td>"
		_sMsg += "		<td> Unidade Medida </td>"
		_sMsg += "		<td> Quantidade </td>"
		_sMsg += "		<td> Preço de Venda </td>"
		_sMsg += "		<td> Total </td>"
		_sMsg += "	</tr>"
		for _x:=1 to Len(_aDev)
			_sMsg += "	<tr> "
			_sMsg += "		<td> " + _aDev[_x,3] + " - "+ _aDev[_x,4] + " </td>"
			_sMsg += "		<td> " + _aDev[_x,5] + " </td>"
			_sMsg += "		<td> " + alltrim(str(_aDev[_x,6])) + " </td>"
			_sMsg += "		<td> " + alltrim(str(_aDev[_x,7])) + " </td>"
			_sMsg += "		<td> " + alltrim(str(_aDev[_x,8])) + " </td>"
			_sMsg += "	</tr>"
		next
		_sMsg += "</table>"
	endif
	if !empty(_sMsg)
		U_ZZUNU({"072"}, "NF devolucao de compra", _sMsg, .F., cEmpAnt, cFilAnt)
	endif
return
//
// --------------------------------------------------------------------------
// Atualiza conta corrente de associados, quando for o caso.
static function _AtuSZIMudas ()
	local _lContinua := .T.
	local _oCtaCorr  := NIL
	local _oAssoc    := NIL
	Local i          := 0
	Local x          := 0
	local _sTProd    := ''
	local _sHist     := ''
	local _oEvento   := NIL
	local _sTxtEvent := ''

	// Verifica se o cliente eh um associado
	if _lContinua 
		_sCGC    :=  fbuscacpo("SA1",1,xfilial("SA1")+ sf2 -> f2_cliente + sf2 -> f2_loja ,"A1_CGC") // busca cpf para localizar o associado na A2
		_sFornec :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_COD")  // busca por cnpj/cpf
		_sLojFor :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_LOJA") // busca por cnpj/cpf

		_oAssoc := ClsAssoc():New (_sFornec, _sLojFor) 
		if valtype (_oAssoc) == "O" .and. _oAssoc:EhSocio ()
			
			// verifica se tem as mudas/açucar produtos na NF 
			_oSQL    := ClsSQL ():New ()  
			_oSQL:_sQuery := ""                                                                                        
			_oSQL:_sQuery += " SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_COD"
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2 "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery += "   and SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
			_oSQL:_sQuery += "   and SD2.D2_DOC      = '" + sf2 -> f2_doc   + "'"
			_oSQL:_sQuery += "   and SD2.D2_SERIE    = '" + sf2 -> f2_serie + "'"
			_oSQL:_sQuery += "   and SD2.D2_COD      in ('7206','7207','5446','5456','2722')"
			_aProdOK := aclone (_oSQL:Qry2Array ())
			
			_sTProd := '0'
			_sHist  := ""
			if len(_aProdOK) > 0
				For x:= 1 to Len(_aProdOK)
					Do Case
						Case alltrim(_aProdOK[x,4]) $ '5446' 		// açucar
							_sTProd := '1'
						Case alltrim(_aProdOK[x,4]) $ '7206/7207' 	// mudinha
							_sTProd := '2' 
						Case alltrim(_aProdOK[x,4]) $  '5456' 		// milho
							_sTProd := '3' 
						Case alltrim(_aProdOK[x,4]) $  '2722' 		// Tambores
							_sTProd := '4'
					EndCase
				Next

				Do Case
					Case _sTProd == '1'		// açucar
						_sTM   := '23'
						_sHist := 'VENDA AÇÚCAR MASCAVO CFE.NF.'
						_sSerie:= 'INS'
					Case _sTProd == '2' 	// mudinha
						_sTM   := '24'
						_sHist := 'VENDA MUDAS DE UVA CFE.NF.'
						_sSerie:= 'MUD'
					Case _sTProd == '3'		// milho
						_sTM   := '23'
						_sHist := 'VENDA MILHO CFE.NF.'
						_sSerie:= 'INS'
					Case _sTProd == '4'  // Outros produtos
						_sTM   := '23'
						_sHist := 'VENDA DIVERSOS CFE.NF.'
						_sSerie:= 'INS'
				EndCase
			
				_oSQL:= ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT"
				_oSQL:_sQuery += "     SE1.E1_FILIAL"
				_oSQL:_sQuery += "    ,SE1.E1_PREFIXO" 
				_oSQL:_sQuery += "    ,SE1.E1_NUM"
				_oSQL:_sQuery += "    ,SE1.E1_PARCELA"
				_oSQL:_sQuery += "    ,SE1.E1_VALOR"
				_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"
				_oSQL:_sQuery += "    ,SE1.E1_LOJA"
				_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"
				_oSQL:_sQuery += "    ,SE1.E1_VENCTO"
				_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
				_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + sf2 -> f2_filial  + "'"
				_oSQL:_sQuery += " AND SE1.E1_NUM     = '" + sf2 -> f2_doc     + "'"
				_oSQL:_sQuery += " AND SE1.E1_PREFIXO = '" + sf2 -> f2_serie   + "'"
				_oSQL:_sQuery += " AND SE1.E1_CLIENTE = '" + sf2 -> f2_cliente + "'"
				_oSQL:_sQuery += " AND SE1.E1_LOJA    = '" + sf2 -> f2_loja    + "'"
				_aSE1:= aclone (_oSQL:Qry2Array ())
				
				if len(_aSE1)> 0
					for i:=1 to len(_aSE1)	
						// -------------------------------------------------------
						// Lança na conta corrente associados
						_oCtaCorr := ClsCtaCorr():New ()
						_oCtaCorr:Assoc    = _sFornec
						_oCtaCorr:Loja     = _sLojFor
						_oCtaCorr:TM       = _sTM
						_oCtaCorr:DtMovto  = _aSE1[i,8]
						_oCtaCorr:Valor    = _aSE1[i,5]
						_oCtaCorr:SaldoAtu = _aSE1[i,5]
						_oCtaCorr:Usuario  = cUserName
						_oCtaCorr:Histor   = _sHist + _aSE1[i,3] +'/'+ _aSE1[i,2]
						_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
						_oCtaCorr:Doc      = _aSE1[i,3]
						_oCtaCorr:Serie    = _sSerie // _aSE1[i,2]
						_oCtaCorr:Parcela  = _aSE1[i,4]
						_oCtaCorr:Origem   = 'SF2460I'
						_oCtaCorr:Obs      = alltrim (sc5 -> c5_obs)
						_oCtaCorr:VctoSE2  = _aSE1[i,9]
						
						_sTxtEvent = ''
						if _oCtaCorr:PodeIncl ()
							if ! _oCtaCorr:Grava (.F., .F.)
				//				U_AvisaTI ("Erro na atualizacao da conta corrente de associados ao gerar a NF '" + sf2 -> f2_doc + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
								_sTxtEvent = "Erro na atualizacao da conta corrente de associados ao gerar a NF '" + sf2 -> f2_doc + "'. Ultima mensagem do objeto:" + alltrim (_oCtaCorr:UltMsg)
							endif
						else
					//		U_AvisaTI ("Gravacao do SZI nao permitida na atualizacao da conta corrente de associados ao gerar a NF '" + sf2 -> f2_doc + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
							_sTxtEvent = "Gravacao do SZI nao permitida na atualizacao da conta corrente de associados ao gerar a NF '" + sf2 -> f2_doc + "'. Ultima mensagem do objeto:" + alltrim (_oCtaCorr:UltMsg)
						endif

						if ! empty (_sTxtEvent)
							_oEvento := ClsEvent():new ()
							_oEvento:CodEven    = 'SF2020'
							_oEvento:Texto      = _sTxtEvent
							_oEvento:Recno      = sf2 -> (recno ())
							_oEvento:Alias      = 'SF2'
							_oEvento:NFSaida    = sf2 -> f2_doc
							_oEvento:SerieSaid  = sf2 -> f2_serie
							_oEvento:Cliente    = sf2 -> f2_cliente
							_oEvento:LojaCli    = sf2 -> f2_loja
							_oEvento:ParcTit    = _aSE1[i,4]
							_oEvento:AvisarZZU  = {'122'}  // 122 = grupo da TI
							_oEvento:Grava ()
						endif
					next
				endif
			endif	
		endif
	endif
return

// --------------------------------------------------------------------------
// Histórico NF
Static Function _HistNf()
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SZN001"
	_oEvento:Texto     = "Emissao de NF"
	_oEvento:NFSaida   = sf2 -> f2_doc
	_oEvento:SerieSaid = sf2 -> f2_serie
	_oEvento:PedVenda  = sc5 -> c5_num
	_oEvento:Cliente   = sf2 -> f2_cliente
	_oEvento:LojaCli   = sf2 -> f2_loja
	_oEvento:Hist	   = "1"
	_oEvento:Status	   = "1"
	_oEvento:Sub       = ""
	_oEvento:Prazo     = 0
	_oEvento:Flag      = .T.
	_oEvento:Grava ()
Return
//
// --------------------------------------------------------------------------
// Gera mensagem e titulos referente a cobranca 'em separado' da ST para MG (GLPI 12779)
static function _TitSTMG ()
	local _oSQL      := NIL
	local _nST_MG    := 0
	local _aAutoSE1  := {}
	local _aAutoSE2  := {}
	local _sMsgContr := ""
	local _sFornRec  := '000092'  // Fornecedor 'ICMS'
	local _sLojaRec  := '01'
	local _oEvento   := NIL
	local _sChvEx    := 'COBRANCA_ST'  // Manter consistencia com P.E. SF2520E, que faz a exclusao destes titulos (ainda a ser implementado)
	local _sHistSE2  := ''

	if ! empty (GetNewPar ("VA_COBSTMG", ''))
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SUM (D2_ICMSRET)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD2") + " SD2"
		_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
		_oSQL:_sQuery +=   " AND SD2.D2_DOC     = '" + sf2 -> f2_doc   + "'"
		_oSQL:_sQuery +=   " AND SD2.D2_SERIE   = '" + sf2 -> f2_serie + "'"
		_oSQL:_sQuery +=   " AND SD2.D2_TES     IN " + FormatIn (alltrim (GetNewPar ("VA_COBSTMG", '')), '/')
		_oSQL:Log ('[' + procname () + ']')
		_nST_MG = _oSQL:RetQry (1, .f.)
	endif

	// Gera mensagem nos dados adicionais da nota
	if _nST_MG > 0
		_SomaMsg (@_sMsgContr, "Valor ST MG antecipacao " + GetMv ("MV_SIMB1") + " " + alltrim (transform (_nST_MG, "@E 999,999,999.99")))
		msmm(,,,_sMsgContr,1,,,"SF2","F2_VACMEMC")
	endif

	// Geracao dos titulos
	if _nST_MG > 0

		// Titulo a receber para termos controle se a ST foi cobrada do cliente
		//
		// Encontra a proxima parcela para esta nota
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select IsNull (max (E1_PARCELA), '0')"
		_oSQL:_sQuery +=   " from " + RetSQLName ("SE1") + " SE1 "
		_oSQL:_sQuery +=  " where SE1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " and SE1.E1_FILIAL   = '" + xfilial ("SE1")   + "'"
		_oSQL:_sQuery +=    " and SE1.E1_CLIENTE  = '" + sf2 -> f2_cliente + "'"
		_oSQL:_sQuery +=    " and SE1.E1_LOJA     = '" + sf2 -> f2_loja + "'"
		_oSQL:_sQuery +=    " and SE1.E1_NUM      = '" + sf2 -> f2_doc + "'"
		_oSQL:_sQuery +=    " and SE1.E1_PREFIXO  = '" + sf2 -> f2_serie + "'"
		_sProxParc = _oSQL:RetQry (1, .f.)
		if empty (_sProxParc)
			_sProxParc = '1'
		else
			_sProxParc = soma1 (_sProxParc)
		endif

		// Busca vencimento do titulo
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 		SE1.E1_VENCREA"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
		_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SE1.E1_FILIAL    = '" + xfilial ("SE1")   + "'"
		_oSQL:_sQuery += " AND SE1.E1_CLIENTE   = '" + sf2 -> f2_cliente + "'"
		_oSQL:_sQuery += " AND SE1.E1_LOJA      = '" + sf2 -> f2_loja    + "'"
		_oSQL:_sQuery += " AND SE1.E1_NUM       = '" + sf2 -> f2_doc     + "'"
		_oSQL:_sQuery += " AND SE1.E1_PREFIXO   = '" + sf2 -> f2_serie   + "'"
		_oSQL:_sQuery += " AND SE1.E1_TIPO     <> 'TRS' "
		_sDtVencReal := _oSQL:RetQry (1, .f.)
		if empty(_sDtVencReal)
			_dDataReal := sf2 -> f2_emissao + 15
		else
			_dDataReal := stod(_sDtVencReal)
		endif

		_aAutoSE1 = {}
		aAdd(_aAutoSE1, {"E1_PREFIXO"  , sf2 -> f2_serie       		, Nil})
		aAdd(_aAutoSE1, {"E1_NUM"      , sf2 -> f2_doc         		, Nil})
		aAdd(_aAutoSE1, {"E1_PARCELA"  , _sProxParc            		, Nil})
		aAdd(_aAutoSE1, {"E1_TIPO"     , 'TRS'                 		, Nil})  // tipo IMP parece dar pau no retorno de CNAB.
		aAdd(_aAutoSE1, {"E1_NATUREZ"  , '110198'              		, Nil})
		aAdd(_aAutoSE1, {"E1_CLIENTE"  , sf2 -> f2_cliente     		, Nil})
		aAdd(_aAutoSE1, {"E1_LOJA"     , sf2 -> f2_loja        		, Nil})
		aAdd(_aAutoSE1, {"E1_VALOR"    , _nST_MG               		, Nil})
		aAdd(_aAutoSE1, {"E1_VLCRUZ"   , _nST_MG               		, Nil})
		aAdd(_aAutoSE1, {"E1_MOEDA"    , 1                     		, Nil})
		aAdd(_aAutoSE1, {"E1_ORIGEM"   , 'FINA040'             		, Nil})
		aAdd(_aAutoSE1, {"E1_EMISSAO"  , sf2 -> f2_emissao     		, Nil})
		aAdd(_aAutoSE1, {"E1_VENCTO"   , _dDataReal					, Nil})
		aAdd(_aAutoSE1, {"E1_COMIS1"   , 0                     		, Nil})
		aAdd(_aAutoSE1, {"E1_COMIS2"   , 0                     		, Nil})
		aAdd(_aAutoSE1, {"E1_COMIS3"   , 0                     		, Nil})
		aAdd(_aAutoSE1, {"E1_COMIS4"   , 0                     		, Nil})
		aAdd(_aAutoSE1, {"E1_COMIS5"   , 0                     		, Nil})
		aAdd(_aAutoSE1, {"E1_VENCREA"  , DataValida(_dDataReal)		, Nil})
		aAdd(_aAutoSE1, {"E1_HIST"     , 'Valor ST MG antecipacao' 	, Nil})
		aAdd(_aAutoSE1, {"E1_VACHVEX"  , _sChvEx               		, Nil})
		_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))
		lMsErroAuto := .F.
		
		MSExecAuto({|x,y| FINA040(x,y)}, _aAutoSE1, 3)
		
		if lMsErroAuto
			MostraErro()
			U_Log2 ('erro', GetAutoGRLog())
		else
			u_log2 ("info", "Gravado E1_NUM/E1_PREFIXO/E1_PARCELA " + se1 -> e1_num + '/' + se1 -> e1_prefixo + '/' + se1 -> e1_parcela + " ref.antecipacao ST")

			// Grava evento para posterior consulta/rastreamento
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = 'SF2017'
			_oEvento:Texto     = 'Geracao tit.a receber ref.antecipacao ST da NF saida ' + sf2 -> f2_doc
			_oEvento:Recno     = SE1 -> (recno ())
			_oEvento:Alias     = 'SE1'
			_oEvento:Chave     = SE1 -> e1_filial + se1 -> e1_num + se1 -> e1_prefixo + se1 -> e1_parcela
			_oEvento:NFSaida   = sf2 -> f2_doc
			_oEvento:SerieSaid = sf2 -> f2_serie
			_oEvento:Cliente   = sf2 -> f2_cliente
			_oEvento:LojaCli   = sf2 -> f2_loja
			_oEvento:ParcTit   = se1 -> e1_parcela
			_oEvento:Grava ()
		endif

		// Titulo a pagar que seria o controle de recolhimento da guia.
		//
		// Encontra a proxima parcela para esta nota
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select IsNull (max (E2_PARCELA), '0')"
		_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + _sFornRec + "'"
		_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '" + _sLojaRec + "'"
		_oSQL:_sQuery +=    " and SE2.E2_NUM      = '" + sf2 -> f2_doc + "'"
		_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + sf2 -> f2_serie + "'"
		_sProxParc = _oSQL:RetQry (1, .f.)
		if empty (_sProxParc)
			_sProxParc = '1'
		else
			_sProxParc = soma1 (_sProxParc)
		endif
		_sHistSE2 := 'Valor ST MG antecipacao'
		_sHistSE2 += ' ref.NF ' + sf2 -> f2_doc
		_sHistSE2 += ' de ' + alltrim (fBuscaCpo ("SA1", 1, xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, "A1_NOME"))

		_aAutoSE2 = {}
		aAdd(_aAutoSE2, {"E2_PREFIXO"  , sf2 -> f2_serie       , Nil})
		aAdd(_aAutoSE2, {"E2_NUM"      , sf2 -> f2_doc         , Nil})
		aAdd(_aAutoSE2, {"E2_PARCELA"  , _sProxParc            , Nil})
		aAdd(_aAutoSE2, {"E2_TIPO"     , 'TRS'                 , Nil})
		aAdd(_aAutoSE2, {"E2_NATUREZ"  , '110198'              , Nil})
		aAdd(_aAutoSE2, {"E2_FORNECE"  , _sFornRec             , Nil})
		aAdd(_aAutoSE2, {"E2_LOJA"     , _sLojaRec             , Nil})
		aAdd(_aAutoSE2, {"E2_VALOR"    , _nST_MG               , Nil})
		aAdd(_aAutoSE2, {"E2_VLCRUZ"   , _nST_MG               , Nil})
		aAdd(_aAutoSE2, {"E2_MOEDA"    , 1                     , Nil})
		aAdd(_aAutoSE2, {"E2_ORIGEM"   , 'FINA050'             , Nil})
		aAdd(_aAutoSE2, {"E2_EMISSAO"  , sf2 -> f2_emissao     , Nil})
		aAdd(_aAutoSE2, {"E2_VENCTO"   , sf2 -> f2_emissao     , Nil})
		aAdd(_aAutoSE2, {"E2_VENCREA"  , DataValida (sf2 -> f2_emissao), Nil})
		aAdd(_aAutoSE2, {"E2_HIST"     , _sHistSE2             , Nil})
		aAdd(_aAutoSE2, {"E2_VACHVEX"  , _sChvEx               , Nil})
		_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
		lMsErroAuto := .F.
		MSExecAuto({|x,y| FINA050(x,y)}, _aAutoSE2, 3)
		if lMsErroAuto
			MostraErro()
			U_Log2 ('erro', GetAutoGRLog())
		else
			u_log2 ("info", "Gravado E2_NUM/E2_PREFIXO/E2_PARCELA " + sE2 -> E2_num + '/' + sE2 -> E2_prefixo + '/' + sE2 -> E2_parcela + " ref.recolhimento ST")

			// Grava evento para posterior consulta/rastreamento
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = 'SF2017'
			_oEvento:Texto     = 'Geracao tit.a pagar ref.antecipacao ST da NF saida ' + sf2 -> f2_doc
			_oEvento:Recno     = SE2 -> (recno ())
			_oEvento:Alias     = 'SE2'
			_oEvento:Chave     = SE2 -> e2_filial + se2 -> e2_num + se2 -> e2_prefixo + se2 -> e2_parcela
			_oEvento:NFSaida   = sf2 -> f2_doc
			_oEvento:SerieSaid = sf2 -> f2_serie
			_oEvento:Cliente   = sf2 -> f2_cliente
			_oEvento:LojaCli   = sf2 -> f2_loja
			_oEvento:ParcTit   = se2 -> e2_parcela
			_oEvento:Fornece   = se2 -> e2_fornece
			_oEvento:LojaFor   = se2 -> e2_loja
			_oEvento:Grava ()
		endif
	endif
return
