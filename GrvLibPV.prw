// Programa.:  GrvLibPV
// Autor....:  Robert Koch
// Data.....:  21/06/2010
// Descricao:  Chamado por botao na tela de pedido de vendas. Grava campo C6_QTDLIB no aCols.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Valida se pode gravar o campo C6_QTDLIB durante a edicao do pedido de venda.
// #PalavasChave      #liberacao #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT
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
// 29/05/2013 - Elaine DWT  - Inclui tratamento para bloqueio gerencial caso o pedido for da tabela 151 e o preco 
//                            informado estiver abaixo da mesma
// 21/08/2013 - Leandro DWT - Inclusão de validação para que somente os usuários do parâmetro possam liberar o pedido de venda
// 02/06/2015 - Catia   - Validação saldo em verbas a bonificar.
// 06/07/2015 - Catia   - Alterado para buscar a ST pela rotina MaFisRet na hora de somar o total do pedido
// 04/08/2015 - Robert  - Nao valida mais o preco da ultima compra para pedidos tipo D/B
// 23/09/2015 - Robert  - Quando misturava motivos de bonificao com e sem controle de verbas, nem todos os 
//                        itens eram adicionados no MaFisAdd.
// 13/10/2015 - Catia   - Dava mensagem de que o cliente nao tinha saldo e bonificar mas mesmo assim liberava o pedido
// 22/10/2015 - Catia   - Alterado para no calculo do item bonificado - busque o IPI valor da planilia do MATFISRET
// 11/07/2016 - Robert  - Chama consulta de margem de contribuicao e deixa campo C5_VABLOQ setado com 'M' 
//                        caso esteja abaixo da margem minima.
// 25/10/2016 - Robert  - Dados da ultima venda (preco menor) passa a ser em TXT e nao mais em HTML.
// 29/03/2017 - Catia   - Itens com eliminação de Resíduo - ainda estava tentando liberar no estoque
// 28/04/2017 - Robert  - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 22/05/2017 - Catia   - Alterado o parametro de margem para 1% para não bloquear nada no gerencial
// 13/10/2017 - Robert  - Volta a fazer bloqueio por margem (agora via parametro VA_MCPED1).
// 16/10/2017 - Robert  - Ignora bloqueio de margem para pedidos de granel.
// 23/10/2017 - Robert  - Valida campo c5_vaPrPed.
// 30/10/2017 - Robert  - Chama rotina de selecao de frete somente para frete tipo CIF.
// 19/02/2018 - Catia   - Valida rapel e base do cliente - nao deixa incluir pedido com dados conflitantes
// 25/04/2018 - Catia   - Validação da loja do codigo matriz quando o cliente controla verbas
// 19/06/2018 - Catia   - bloqueio por % de aumento
// 03/07/2018 - Robert  - Funcao Va_McPed() tem novos parametros
//                      - Cotacao de frete passa a ser chamada diretamente pela funcao de calculo de margem de contribuicao.
// 17/08/2018 - Catia   - teste de caracteres especiais nas observações
// 14/11/2018 - Andre   - Adicionado verificação dos campos A1_VAMDANF e A2_VAMDANF para não liberar pedido 
//                        com email LIXO@NOVAALIANCA.COOP.BR
// 04/12/2018 - Andre   - Adicionado validação nos CAMPOS A1_EMAIL e A2_EMAIL. Bloqueado inclusão neste campos 
//                        para conteudo LIXO@NOVA OU NOVALIANCA.
// 10/12/2018 - Andre   - Validacao para que itens com TES 630 e 657 apenas usuários dos grupos 069 e 066 possam liberar.
// 25/01/2019 - Andre   - Pesquisa ZX5 alterada de FBUSCACPO para U_RETZX5.
// 22/05/2019 - Robert  - Liberados caracteres especiais no C5_OBS apenas em base teste (GLPI 5961)
// 27/05/2019 - Catia   - estava dando erro linha 418 e 427 _lTes 
// 28/05/2019 - Sandra  - Não valida mais caracteres especias no campo de observacoes conforme GLPI 5961
// 11/11/2019 - Robert  - Revisado tratamento campo ZA5_FILIAL (tabela passar de compartilhada para exclusiva). 
//                        GLPI 6987.
//                      - Passa a validar campo ZA4_FILIAL na query.
// 18/11/2019 - Robert  - Iniciadas melhorias bloqueio pedido bonificado sem pedido faturado correspondente
// 09/04/2020 - Claudia - Incluido o controle de endereço da linha do pedido de venda, conforme GLPI: 7765
// 20/07/2020 - Robert  - Permissao para liberar pedido de baixa de estoque para ajustes passa a validar 
//                        acesso 101 e nao mais 069+066.
//                      - Inseridas tags para catalogacao de fontes
// 09/03/2021 - Claudia - Bloqueio de bonificação. GLPI: 9070
// 12/03/2021 - Claudia - Retirado caracteres especiais " e ' da gravação da OBS. GLPI: 9634
// 05/10/2021 - Claudia - Incluida validação para não permitir liberara pedido sem gravar antes. GLPI: 11009
// 03/01/2021 - Claudia - Ajustado para permitir desconto no cabeçalho da NF. GLPI: 11370
// 04/01/2021 - Claudia - Incluida validação para ser obrigatorio informar NSU e Id Pagar-me em pedidos e-commerce.
// 22/06/2022 - Claudia - Passada validações de NSU/Id pagarme e indenização e bonificações no p.e Mta410. GLPI: 11600
// 02/02/2023 - Claudia - Liberação e-mail nfe@novaalianca.coop.br campo A2_E-MAIL - GLPI 13137
// 11/07/2023 - Claudia - Chamada a função de limpeza de caracteres especiais. GLPI: 13865
// 12/01/2024 - Claudia - Validação para desconsiderar tipo de pedido "utiliza fornecedor" para rapel. GLPI: 14706
// 24/01/2024 - Claudia - Ultimo preço de venda será buscado diretamente da ultima NF faturada. GLPI: 14796
// 25/01/2024 - Claudia - Melhorias no layout dos e-mails. GLPI: 14805
// 31/01/2024 - Claudia - Validação para não enviar e-mail de preço abaixo quando bloqueio por residuo. GLPI: 14838 
// 31/01/2024 - Claudia - Envio de e-mail com preço minimo apenas para operações de venda. GLPI: 14837
// 01/02/2024 - Claudia - Excluidos produtos tipo RE de envio de email de preço abaixo de venda. GLPI: 14812
// 29/02/2024 - Robert  - Gerar bloqueio gerencial tipo S especifico de sucos - GLPI 14980
// 04/03/2024 - Robert  - Bloqueio gerencial tipo S estava pegando TES que nao gera duplicata.
// 11/03/2024 - Robert  - Melhorada msg de bloqueio gerencial tipo S
//                      - Nao fazia leitura da linha correta na GDFieldGet, nos testes de bloqueio gerencial tipo S
// 21/03/2024 - Robert  - Arredonda casas decimais antes de testar preco sucos (bloqueio gerencial tipo S)
// 28/03/2024 - Robert  - Nao ignorava linhas com bloqueio manual e eliminacao de residuos no bloqueio preco sucos (bloqueio gerencial tipo S)
// 06/05/2024 - Claudia - Ajustada validação de contratos rapel, verificando % em contratos inativos.
// 22/05/2024 - Claudia - E-mail de bloqueio de sucos - eliminado por resíduo. GLPI: 15502
// 17/07/2024 - Claudia - Validação de rapel. GLPI: 15375
//
// -------------------------------------------------------------------------------------------------------------------------
user function GrvLibPV(_lLiberar)
	local _aAreaAnt  := U_ML_SRArea ()
	local _n         := N
	local _sErro     := ""
	local _nQtdEnt   := 0
	local _sQuery    := ""
	local _aUltPrc   := {}
	local _nUltPrc   := 0
	local _sMsg      := ""
	local _nOpcao    := 0
	local _sRetEstq  := ""
	local _nLinAnt   := 0
	local _nAcumAnt  := 0
	local _lFaturado := .F.
	local _lBonific  := .F.
	local _lSoGranel := .F.
	local _sGeraDupl := ""
	local _lBloq     := .F.
	local _nLinha    := 0
	local _nPrcLitro := 0
	local _lBloqSup  := .F.
	local _sMsgBlSup := ''
	local _nPrMinLtr := 0
	local _x         := 0

	// verifica se o pedido esta salvo antes de fazer a liberação
	_oSQL := ClsSQL():New()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 		C5_NUM "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SC5")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND C5_FILIAL    = '" + m->c5_filial  + "'"
	_oSQL:_sQuery += " AND C5_NUM       = '" + m->c5_num     + "'"
	_oSQL:_sQuery += " AND C5_CLIENTE   = '" + m->c5_cliente + "'"
	_oSQL:_sQuery += " AND C5_LOJACLI   = '" + m->c5_lojacli + "'"
	_aPedido := aclone (_oSQL:Qry2Array (.f., .f.))

	if Len(_aPedido) <= 0
		_lLiberar := .F.
		u_help("A liberação deve ocorrer após a gravação do pedido!")
	endif

	if _lLiberar .and. empty (m->c5_vaFEmb)
		u_help ("Antes de liberar o pedido, o campo '" + alltrim (RetTitle ("C5_VAFEMB")) + "' deve ser informado.")
		return
	endif
	
	if ! U_ZZUVL ('005')
		_lLiberar := .F.
	endif
	
	if _lLiberar .and. M->C5_CONDPAG = '997' // DESCONTO EM FOLHA - NAO PODE USAR
		_sErro += "Condição de pagamento exclusiva para venda nas lojas."
		_lLiberar = .F.
	endif
	
	// Validacoes de e-mail DANFE
	if _lLiberar	
		if M-> C5_TIPO = 'N'
			_wEmailA1 = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_VAMDANF")
			if 'lixo@nova' $ _wEmailA1
				_sErro += "E-mail para DANFE inválido. Por favor, verifique!'"
				_lLiberar = .F.
			endif
			_wEmailA1 = fBuscaCpo ('SA1', 1, xfilial('SA1') + m->c5_cliente + m->c5_lojacli, "A1_EMAIL")
			if 'lixo@nova' $ _wEmailA1
				_sErro += "E-mail para DANFE inválido. Por favor, verifique!'"
				_lLiberar = .F.
			endif
		else
			_wEmailA2 = fBuscaCpo ('SA2', 1, xfilial('SA2') + m->c5_cliente + m->c5_lojacli, "A2_VAMDANF")
			if  'lixo' $ _wEmailA2
			   	_sErro += "E-mail para DANFE inválido. Por favor, verifique!"
				_lLiberar = .F.
			endif
			if  _wEmailA2 != 'associados@novaalianca.coop.br' .and. 'novaalianca' $ _wEmailA2
				If alltrim(_wEmailA2) =='nfe@novaalianca.coop.br'
					_lLiberar = .T.
				else                                                          
			   		_sErro += "E-mail para DANFE inválido. Por favor, verifique!"
					_lLiberar = .F.
				endif
			endif
    		_wEmailA2 = fBuscaCpo ('SA2', 1, xfilial('SA2') + m->c5_cliente + m->c5_lojacli, "A2_EMAIL")
			if  'lixo' $ _wEmailA2
			   	_sErro += "E-mail para DANFE inválido. Por favor, verifique!"
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
 						u_help ("Usuário sem permissão para emissão de nota fiscal de baixa de estoque",, .t.)
 						_sErro += "Usuário sem permissão para emissão de nota fiscal de baixa de estoque. Rotina 101"
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
	
	// verifica se controla endereço e lote
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

			if ! GDDeleted()                                                        
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
				
				_lBloq     := iif(alltrim(GDFieldGet("C6_BLQ")) $ "SR" ,.T.,.F.)						// Bloqueio por residuos
				_sGeraDupl := fBuscaCpo("SF4", 1, xfilial("SF4") + GDFieldGet("C6_TES"), "F4_DUPLIC") 	// Gera duplicata
				_sOper     := alltrim(GDFieldGet("C6_VAOPER")) 											// Operação de vendas
				_sTipoProd := fBuscaCpo("SB1", 1, xfilial("SB1") + GDFieldGet("C6_PRODUTO"), "B1_TIPO")
				
				// Valida preco de venda com ultimo pedido do cliente.
				if empty(_sErro) .and. ! m->c5_tipo $ 'DB' .and. cNumEmp == '0101' .and. _sGeraDupl == "S" .and. _lBloq == .F. .and. _sOper == '01' .and. _sTipoProd <> 'RE'
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
					_sQuery +=   " AND SD2.D2_TIPO     = '" + m->c5_tipo    + "'"
					_sQuery +=   " AND SD2.D2_COD      = '" + GDFieldGet ("C6_PRODUTO") + "'"
					_sQuery += " ORDER BY D2_EMISSAO DESC"
					_aRetQry = aclone (U_Qry2Array (_sQuery, .F., .F.))

					if len(_aRetQry) > 0 .and. round(_aRetQry[1, 1], 2) > round(GDFieldGet("C6_PRCVEN"), 2)

						aadd (_aUltPrc, {	alltrim (GDFieldGet ("C6_PRODUTO"))	, ;
											alltrim (GDFieldGet ("C6_DESCRI"))	, ;
											GDFieldGet ("C6_PRCVEN")			, ; 
											_aRetQry [1, 1]						, ; 
											_aRetQry [1, 2]						, ;
											dtoc (stod (_aRetQry [1, 3]))		, ;
											_aRetQry [1, 4]						, ;
											_aRetQry [1, 5]						 })
					endif
				endif
			endif
		next
              
		if len (_aUltPrc) > 0

   			// Prepara mensagem para visualizacao
			_sMsg := "<html>"
			_sMsg += "<b>Pedido de venda:</b> " + m->c5_num + "<br>" 
			_sMsg += "<b>Cliente:</b> " + m->c5_cliente + " - " + m->c5_nomecli + "<br>"
			_sMsg += "<b>Representante:</b> " + m->c5_vend1 + " - " + fBuscaCpo ("SA3", 1, xfilial ("SA3") + m->c5_vend1, "A3_NOME") + "<br>"
			_sMsg += "<b>Produtos:</b> <br><br>"
			for _nUltPrc = 1 to len (_aUltPrc)
				_sMsg += "<b>"+ _aUltPrc [_nUltPrc, 1] + " </b> - " + _aUltPrc [_nUltPrc, 2] + "(preco atual: " + cvaltochar (_aUltPrc [_nUltPrc, 3]) + " - ult.venda: " + cvaltochar (_aUltPrc [_nUltPrc, 4]) + ")<br>"
			next
			_sMsg += "</html>"

			_nOpcao = aviso ("Precos abaixo da regras de estabelecidas pelo comercial", ;
				"Estao sendo vendidos produtos com precos abaixo das regras estabelecidas pelo comercial!" + chr (13) + chr (10) + "Se confirmar assim mesmo, o pedido ficara com bloqueio gerencial.", ;
				{"Sim", "Nao", "Verificar"}, ;
				3, ;
				"Precos abaixo da venda anterior/Tabela de Precos/ Precos abaixo do aumento especificado")
			if _nOpcao == 1

				// Bloqueia o pedido.
				// Lembrar de manter consistencia com a view GX0064_LIB_GERENC_PEDIDOS que vai ser lida pelo NaWeb!
				m->c5_vaBloq = iif ('P' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'P')
				U_LOG ('M->C5_VABLOQ ficou com', m->c5_vaBloq)

				// Grava a maior variacao
				u_log (_aUltPrc)
				for _nUltPrc = 1 to len (_aUltPrc)
					u_log ('linha', _nUltPrc)

					u_log (m->c5_vaPrPed, 100 - _aUltPrc [_nUltPrc, 3] * 100 / _aUltPrc [_nUltPrc, 4])
					m->c5_vaPrPed = max (m->c5_vaPrPed, 100 - _aUltPrc [_nUltPrc, 3] * 100 / _aUltPrc [_nUltPrc, 4])
					u_log ('var=', m->c5_vaPrPed)
				next
			
				// verifica se o bloqueio é por ser menor que o aumento
				for _nUltPrc = 1 to len (_aUltPrc)
					if _aUltPrc [_nUltPrc, 3] < _aUltPrc [_nUltPrc, 4]		
						// bloqueia por preço menor que o aumento estabelecido				
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
		if _lLiberar 
			N = _n
			if _lFaturado .and. ! _lSoGranel  // Ignora bloqueio de margem para pedidos de granel
				//processa ({|| U_VA_McPed (.F., .T.), "Calculando margem de contribuicao"})
				processa ({|| U_VA_PEDMRG('GrvLibPV'), "Calculando margem de contribuicao"})
				
				_nMargMin = GetMv ("VA_MCPED1")
				if m->c5_vaMCont < _nMargMin
					_nOpcao = aviso ("Margem de contribuicao muito baixa", ;
					                 "Margem de " + cvaltochar (m->c5_vaMCont) + "% (abaixo de " + cvaltochar (_nMargMin) + "%). Pedido vai ficar com bloqueio gerencial. Confirma assim mesmo?", ;
					                 {"Sim", "Nao"}, ;
					                 3, ;
					                 "Margem minima")
					if _nOpcao == 1
						// Lembrar de manter consistencia com a view GX0064_LIB_GERENC_PEDIDOS que vai ser lida pelo NaWeb!
						m->c5_vaBloq = iif ('M' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'M')
						U_LOG ('M->C5_VABLOQ ficou com', m->c5_vaBloq)
					elseif _nOpcao == 2
						_sErro = "Pedido nao confirmado."
					endif
				endif
				
				if cFilAnt == '01' .and. empty (m->c5_vabloq) .and. m->c5_tpfrete == 'C' .and. m->c5_mvfre == 0 .and. GetMv ("VA_BLPSF") == 'S'
					_sErro += "Parametro VA_BLPSF: Pedido com frete CIF, mas sem valor de frete para calculo de margem. Liberacao nao sera´ feita. Cadastre rota valida no entregou.com ou informe frete negociado no cadastro do cliente."
				endif
			endif
		endif

		// validacoes RAPEL
		if _lLiberar .and. m->c5_tipo <> 'B'
			_wbaserapel = fBuscaCpo ('SA1', 1, xfilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI, "A1_VABARAP")
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT dbo.VA_FRAPELPADRAO ('" + M->C5_CLIENTE + "','" + M->C5_LOJACLI + "', '')"
			_oSQL:Log ()
			_wRapel = _oSQL:RetQry (1, .F.)
		
			if _wbaserapel != '0' 
				if _wrapel = 0
					u_help ("Tabela de rapel não cadastrada para esse cliente. Verifique!")
					_lLiberar = .F.	
				else
					_sCodBase  := fBuscaCpo ('SA1', 1, xfilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI, "A1_VACBASE")
					_sLojaBase := fBuscaCpo ('SA1', 1, xfilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI, "A1_VALBASE")

					_sQuery := ""
					_sQuery += " SELECT
					_sQuery += " 	 ZA7_CONT"
					_sQuery += " 	,ZA7_VIGENT"
					_sQuery += " FROM ZA7010"
					_sQuery += " WHERE D_E_L_E_T_ = ''"
					_sQuery += " AND ZA7_CLI      = '" + _sCodBase          + "'"
					_sQuery += " AND ZA7_LOJA     = '" + _sLojaBase         + "'"
					_sQuery += " AND ZA7_VINI    <= '" + DTOS(m->c5_emissao) + "'"
					_sQuery += " AND ZA7_VFIM    >= '" + DTOS(m->c5_emissao) + "'"
					aContrato := U_Qry2Array(_sQuery)

					if Len(aContrato) <= 0
						u_help("Cliente sem contrato e/ou contrato válido. Verifique!")
						_lLiberar = .F.
					else
						for _x := 0 to len(aContrato)
							if aContrato[_x, 2] == '2'
								u_help("Cliente sem contrato e/ou contrato válido. Verifique!")
								_lLiberar = .F.
							endif
						next
					endif									
				endif
			endif
		endif

		// se pedido é bonificação
		If _lLiberar
			If _lBonif // É bonificação
				// Lembrar de manter consistencia com a view GX0064_LIB_GERENC_PEDIDOS que vai ser lida pelo NaWeb!
				m->c5_vaBloq = iif ('B' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'B')
			EndIf
		EndIf

		// Bloqueio a nivel de superintendencia. Situacao especifica (GLPI ?)
		if _lLiberar
			
			// Jah vou preparando msg para envio, caso caia em bloqueio.
			_sMsgBlSup := "<html>"
			_sMsgBlSup += "<b>Pedido de venda:</b> " + m->c5_num + "<br>" 
			_sMsgBlSup += "<b>Cliente:</b> " + m->c5_cliente + " - " + alltrim (m->c5_nomecli) + "<br>"
			_sMsgBlSup += "<b>Representante:</b> " + m->c5_vend1 + " - " + alltrim (fBuscaCpo ("SA3", 1, xfilial ("SA3") + m->c5_vend1, "A3_NOME")) + "<br>"
			_sMsgBlSup += "<b>Produtos:</b><br><br>"
			
			_lBloqSup = .F.  // Todos sao inocentes ateh prova em contrario.
			sb1 -> (dbsetorder (1))
			for _nLinha = 1 to len (aCols)
				U_Log2 ('debug', '[' + procname () + ']Verificando item ' + GDFieldGet ("C6_ITEM", _nLinha) + ' ' + GDFieldGet ("C6_PRODUTO", _nLinha))
				if ! GDDeleted (_nLinha) ;
					.and. ! alltrim (GDFieldGet ("C6_BLQ")) $ "SR";  // bloqueio manual ou por eliminacao de residuo
					.and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES", _nLinha), "F4_ESTOQUE") == 'S';
					.and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES", _nLinha), "F4_DUPLIC") == 'S';
					.and. GDFieldGet ("C6_BLQ", _nLinha) <> 'R'
					
					if ! sb1 -> (dbseek (xfilial ("SB1") + GDFieldGet ("C6_PRODUTO", _nLinha), .f.))
						u_help ("Produto '" + GDFieldGet ("C6_PRODUTO", _nLinha) + "' nao localizado no cadastro!",, .t.)
						_lLiberar = .F.
					else
						_nPrcLitro = GDFieldGet ("C6_PRCVEN", _nLinha) / sb1 -> b1_litros
						U_Log2 ('debug', '[' + procname () + ']b1_cod = ' + sb1 -> b1_cod)
						U_Log2 ('debug', '[' + procname () + ']b1_litros = ' + cvaltochar (sb1 -> b1_cod))
						U_Log2 ('debug', '[' + procname () + ']_nPrcLitro = ' + cvaltochar (_nPrcLitro))
						if sb1 -> b1_codlin == '06'  // sucos integrais
							if sb1 -> b1_grpemb $ '23/24'  // cx 6x1,5/gfa 1,5
								_nPrMinLtr = 8
							elseif sb1 -> b1_grpemb $ '03/04/13'  // cx 6x1/cx 12x1/gfa 1000
								_nPrMinLtr = 11.73
							elseif sb1 -> b1_grpemb $ '42/44'  // cx12x1TP / TP 1000
								_nPrMinLtr = 7.9
							elseif sb1 -> b1_grpemb $ '05/09/12/51/52/55'  // cx 12x500/cx 2x450 / gfa 450 / CX 12X450 / gfa 450
								_nPrMinLtr = 14.96
							elseif sb1 -> b1_grpemb $ '41/43'  // cx24x200TP / tp200 / lata
								_nPrMinLtr = 11
							else
								_nPrMinLtr = 0
								u_help ("Produto '" + sb1 -> b1_cod + "': sem definicao de preco minimo por litro de sucos (grupo de embalagem '" + sb1 -> b1_grpemb + "')",, .t.)
								_lLiberar = .F.
							endif

							// Se este item vai ser bloqueado, adiciona-o na string da mensagem
							if round (_nPrcLitro, 1) < round (_nPrMinLtr, 1)
								_lBloqSup = .T.
								_sMsgBlSup += alltrim (sb1 -> b1_cod) + " - " + alltrim (sb1 -> b1_desc)
								_sMsgBlSup += " a <b>R$ " + alltrim (transform (_nPrcLitro, '@E 999,999,999.99')) + " /litro</b>"
								_sMsgBlSup += " (abaixo do valor minimo de R$ " + alltrim (transform (_nPrMinLtr, '@E 999,999,999.99')) + ") desta linha de produtos.<br>"
							endif
						endif
					endif
				else
					U_Log2 ('debug', '[' + procname () + ']Linha deletada, ou TES nao gera estq/dupl.')
				endif
			next

			_sMsgBlSup += "</html>"
			U_Log2 ('debug', '[' + procname () + ']_sMsgBlSup: ' + _sMsgBlSup)
			U_Log2 ('debug', '[' + procname () + ']_lBloqSup = ' + cvaltochar (_lBloqSup))

			if _lBloqSup
				if U_MsgYesNo ("Bloqueio especifico sucos: vai ficar com bloqueio tipo S para liberacao pela direcao. Confirma?")

					// Lembrar de manter consistencia com a view GX0064_LIB_GERENC_PEDIDOS que vai ser lida pelo NaWeb!
					m->c5_vaBloq = iif ('S' $ m->c5_vaBloq, m->c5_vaBloq, alltrim (m->c5_vaBloq) + 'S')  // Tipo S = Superintendente

					// Cria variavel publica com mensagem, para posterior envio pelo P.E. M410STTS se o usuario vier a gravar o pedido.
					public _sMsgPBSup := _sMsgBlSup
				else
					_lLiberar = .F.
				endif
			endif
		endif

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

	// retira caracteres especiais do campo de OBS
	m->c5_obs := U_LimpaEsp(m->c5_obs)

	U_ML_SRArea (_aAreaAnt)
return
