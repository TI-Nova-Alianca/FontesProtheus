// Programa...: MTA410
// Autor......: Robert Koch
// Data.......: 18/04/2008
// Descricao..: P.E. 'Tudo OK' da tela de pedidos de vendas
//              Criado inicialmente para verificar CFO
//
// Tags de localização
// #TipoDePrograma    #PontoDeEntrada
// #PalavasChave      #PE #pontodeentrada #pedido #venda #pedidosdevendas #TudoOK
// #TabelasPrincipais #SC5 #SC6 
// #Modulos 		  #faturamento #FAT
//
// Historico de alteracoes:
// 03/06/2008 - Robert  - Passa a avisar quando tem item do grupo ML_CARTU sem qt. volumes.
// 11/06/2008 - Robert  - Aviso sobre volumes passa a ser apenas em pedidos do tipo 'normal'.
// 18/06/2008 - Robert  - Chama verificacao de dados para NFe.
// 10/07/2008 - Robert  - Verificacao de dados para NFe passa a bloquear a gravacao do pedido.
// 25/08/2008 - Robert  - Nao verifica fretes quando for geracao de pedidos por EDI.
// 02/09/2008 - Robert  - Na validacao de CFO nao considerava tipo do pedido.
// 17/09/2008 - Robert  - Criadas validacoes para campanhas de venda.
// 19/11/2008 - Robert  - Verifica estoque quando informada a quantidade liberada.
// 02/03/2009 - Robert  - Vendas para SP com geracao de ST bloqueadas temporariamente.
// 04/03/2009 - Robert  - Criados tratamentos para que o armazem geral possa ser representado tambem por fornecedor e nao somente cliente.
// 19/08/2009 - Robert  - Revisao para nao mostrar nada em tela quando executar sem interface com o usuario.
// 16/09/2009 - Robert  - Pedidos com frete FOB passam a ser permitidos em DCOs.
// 22/09/2009 - Robert  - Produtos a granel passam a ser permitidos nos DCOs.
// 22/10/2009 - Robert  - Passa a usar tabela 03 do ZX5 em lugar da tabela 77 do SX5.
// 16/12/2009 - Robert  - Removidas validacoes por DCO
// 10/06/2010 - Robert  - Criadas validacoes para representantes externos.
// 17/10/2010 - Robert  - Criadas validacoes para deposito fechado (filial 04).
//                      - Nao consiste volumes para geracao via batch.
// 29/10/2010 - Robert  - Passa a usar a funcao VerEstq para verificacao de estoques.
// 01/11/2010 - Robert  - Verificacao de TES X Filial de embarque
// 05/11/2010 - Robert  - Novos parametros funcao VerEstq.
// 16/11/2010 - Robert  - Ignora alguns testes quando chamado pela rotina de retorno simbolico do deposito para a matriz.
// 15/12/2010 - Robert  - Criado tratamento para campo ZX5_MODO.
// 06/07/2011 - Robert  - Nao permite vendedor inativo.
// 11/08/2011 - Robert  - Criadas consistencias ref. transferencias entre filiais (usar custo medio).
// 08/09/2011 - Robert  - Avisa usuario para usar pedido tipo 'B' em caso de venda para associados.
// 17/10/2011 - Robert  - Valida preenchimento de volume2 em qualquer tipo de pedido (antes era soh para tipo N).
// 16/12/2011 - Robert  - Funcao VerEstq passa a receber parametro de endereco de estoque.
// 02/01/2012 - Robert  - Transferencias feitas pela matriz voltam a ser pelo custo medio e nao mais pelo de reposicao.
// 14/01/2012 - Robert  - Verificacao de envio de bags para dispenser sem os copos descartaveis.
// 01/03/2012 - Robert  - Verificacao especifica para pedidos importados via EDI (por enquanto, apenas itens com e sem ST).
// 10/05/2012 - Robert  - Verificacao de venda para associado passa a usar a classe ClsAssoc.
// 24/10/2012 - Robert  - Nao permite mais filial embarque inconsistente com TES de embarque no deposito (antes apenas avisava).
// 22/11/2012 - Elaine  - Incluir tratamento para tabela de preco - validar tipo de frete CIF/FOB com o tipo de frete do pedido
// 05/02/2013 - Elaine  - Nao permitir incluir pedido se informar cfop de transferência e o cliente não for uma das filiais da Alianca
// 21/05/2013 - Robert  - Tratamento da variavel _sErroEDI desabilitado, pois a funcao U_Help passa a ter tratamento para rot.automaticas.
// 27/07/2013 - Robert  - Passa a buscar preco de custo na funcao U_PrcCust().
// 14/08/2013 - Robert  - Verifica remessa para deposito embarcando em filial diferente da matriz.
// 25/03/2014 - Robert  - Verifica pedido embarcado pela filial 13 (temporario).
// 21/05/2014 - Robert  - Verifica se houve liberacao parcial do pedido.
// 23/05/2014 - Robert  - Verifica consistencias quanto a utilizar ou nao as cargas do OMS.
// 11/07/2014 - Robert  - Verifica almoxarifado dos produtos quando utiliza carga.
// 06/08/2014 - Robert  - Bloqueia uso de TES que nao movimenta estoque em pedido que utiliza carga do OMS.
// 22/08/2014 - Robert  - Funcao U_PrcCust parametrizada para buscar valor no SB2 e nao mais do SB9.
// 16/11/2014 - Robert  - Exige endereco quando usa carga=Nao e poduto controla localizacao.
// 01/12/2014 - Robert  - Verificacoes para integracao com Fullsoft.
// 17/09/2015 - Robert  - Volta a verificar se pedidos importador via EDI contem itens com e sem ST (desab. quando migramos para ST padrao do sistema).
// 19/09/2015 - Robert  - Funcao CalcST4 passa a aceitar cliente/loja como parametros.
// 23/10/2015 - Robert  - Parametros novos (quantidade e TES) na funcao CalcST4().
// 17/05/2016 - Robert  - Verificacoes para DCO eliminadas (nao usamos mais leiloes da CONAB e, de qquer forma, sao especificos para cada ano).
// 01/06/2016 - Robert  - Funcao U_PrcCust nao tem mais opcao de buscar do SB9.
// 14/06/2016 - Catia   - Se condicao 097 AVISTA que o banco deve ser CX1
// 14/06/2016 - Catia   - Se condicao 098 BONIFICACAO que o TES nao deve gerar FINANCEIRO
// 28/10/2016 - Robert  - Exige preco de custo para o TES 697
// 02/12/2016 - Robert  - Melhoria geral nas mensagens de aviso.
// 23/12/2016 - Catia   - Exige preco de custo para o TES 630
// 29/03/2017 - Catia   - Itens com eliminação de Resíduo - ainda estava tentando liberar no estoque
// 11/04/2017 - Catia   - Resolvido GAP nas validações de rastreabilidade - so deve obrigar a digitacao do endereço se o TES movimenta estoque
// 28/04/2017 - Robert  - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 25/09/2017 - Catia   - Valida C6_NUMPCOM e C6_ITEMPC - se o A1_VAOC estiver como 1 (SIM) - obriga informar o nro da OC
// 07/11/2017 - Robert  - Passa a validar o parametro AL_TESPCUS para itens que devem sair a preco de custo.
//                      - Recalcula (mesmo que o pedido nao tenha sido liberado) valor previsto 
//                        para a nota fiscal e margem por que ficam persistidos em campos do SC5 que sao consultados fora desta tela. 
// 22/10/2018 - Andre   - testes do vendedor ativo
// 17/04/2019 - Catia   - incluido mais um IF do tipo do pedido no teste do vendedor ativo 
// 17/04/2019 - Andre   - Incluida validacao para item 2325 questionar para quantidade (C6_QTDVEN) diferente de multiplo de 1.000
// ??/09/2019 - Robert  - Permite pedido usando carga fora do AX.01, mediante confirmacao do usuario.
// 16/09/2019 - Andre   - Nao testa pedido usando carga fora do AX.01, quando importacao do Mercanet.
// 12/12/2019 - Robert  - Transferencias para a filial 16 precisam usar tabela de precos e nao custo. GLPI 7208.
// 13/01/2020 - Andre   - Desabilistada chamada da função _VerSTEDI.
// 07/04/2020 - Claudia - Busca de parametro fora de laço de repetição, conforme R25. GLPI: 7339
// 09/04/2020 - Claudia - Retirado o controle de endereço da linha do pedido de venda, conforme GLPI: 7765
// 14/05/2020 - Robert  - Passa a enviar o parametro de 'erro=.T.' nas chamadas da funcao u_help().
// 17/06/2020 - Claudia - Não considerar erro de "Pedido utiliza carga" quando chamado pelo BATMERCP. GLPI: 8010
// 30/06/2020 - Robert  - Liberado para usar montagem de carga na filial 16.
// 15/07/2020 - Cláudia - Retirado o lembrete de associado e tipo de nota.
// 14/08/2020 - Robert  - Desabilitada validacao do 'custo para transferencia' quando chamado a partir do MATA310 (GLPI 8077)
// 18/01/2021 - Claudia - GLPI: 8966 - Incluida validação de forma de pagamento CC e CD
// 25/01/2021 - Robert  - Melhorada msg. de cond.pag. bonificacao com TES gerando financeiro (GLPI 9128).
// 10/03/2021 - Claudia - Alterado o parametro da função VA_McPed para calcular frete. GLPI: 9581
// 19/08/2021 - Robert  - Desabilitado UPDATE SC9010 SET C9_BLCRED = '01' por que tinha sintaxe incorreta e nunca executou.
// 10/09/2021 - Claudia - Não permitir vender mudas de uva e açucar no mesmo pedido para associados. GLPI: 10916
// 29/09/2021 - Claudia - Tratamento para venda de milho. GLPI: 10994
// 10/06/2022 - Claudia - Ajuste de lançamento para mudas. GLPI: 12191
// 13/06/2022 - Claudia - Ajuste de validação de carga e AX01. GLPI: 12172
// 22/06/2022 - Claudia - Passada validações de NSU/Id pagarme e indenização e bonificações no p.e Mta410. GLPI: 11600
// 24/06/2022 - Claudia - Incluida validação para vendedor incluir/não incluir pedido dereto no Protheus. GLPI: 12249
//
// ---------------------------------------------------------------------------------------------------------------------------
User Function MTA410 ()
	local _lRet      := .T.
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _sQueroCFO := ""
	local _sCartu    := ""
	local _N         := 0
	
	// Verifica se a liberacao dos itens foi totalmente feita.
	if _lRet
		_lRet = _VerLib ()
	endif
 
	if _lRet
		if m->c5_tipo == 'N'
			if fBuscaCpo("SA3", 1, xfilial("SA3") + m->c5_vend1, "A3_ATIVO") != "S"
				u_help ("Vendedor " + m->c5_vend1 + " nao consta como 'Ativo'",, .t.)
				_lRet = .F.
			endif
			if ! empty(m->c5_vend2) .and. fBuscaCpo("SA3", 1, xfilial("SA3") + m->c5_vend2, "A3_ATIVO") != "S"
				u_help ("Vendedor " + m->c5_vend2 + " nao consta como 'Ativo'",, .t.)
				_lRet = .F.
			endif
			if (fBuscaCpo("SA3", 1, xfilial("SA3") + m->c5_vend1, "A3_VAIPED") != "S") .and. !IsInCallStack("U_BATMERCP")
				u_help ("Vendedor " + m->c5_vend1 + " sem permissão para incluir pedido!",, .t.)
				_lRet = .F.
			endif
		endif	
	endif
	
	if _lRet
		// se condicao de pagamento A VISTA - deve ser sempre CX1
		if m->c5_condpag = '097' .and. m->c5_banco != 'CX1'
			u_help ("Para condicao A VISTA, informar banco CX1 (caixa).",, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet
		if m->c5_condpag = '098'
			// verifica todos os TES usados no pedido - se bonificacao TES não deve gerar DUPLICATA
			for _N = 1 to len (aCols)
				N := _N
				if ! GDDeleted () .and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES"), "F4_DUPLIC") = "S"
					u_help ("Para condicao de pagamento '" + m->c5_condpag + "' (bonificacao), o TES (" + GDFieldGet ("C6_TES") + ") nao deve gerar finaneiro.",, .t.)
					_lRet = .F.
					exit
				endif
			next	
		endif
	endif

	// Verifica CFO
	if _lRet .and. ! IsInCallStack ("U_VA_GPDM")
		if m->c5_tipo $ "BD"
			do case
				case fBuscaCpo ("SA2", 1, xfilial ("SA2") + m->c5_cliente + m->c5_lojacli, "A2_EST") == "EX"
					_sQueroCFO = "7"
				case fBuscaCpo ("SA2", 1, xfilial ("SA2") + m->c5_cliente + m->c5_lojacli, "A2_EST") == getmv ("MV_ESTADO")
					_sQueroCFO = "5"
				otherwise
					_sQueroCFO = "6"
			endcase
		else
			do case
				case fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->c5_cliente + m->c5_lojacli, "A1_EST") == "EX"
					_sQueroCFO = "7"
				case fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->c5_cliente + m->c5_lojacli, "A1_EST") == getmv ("MV_ESTADO")
					_sQueroCFO = "5"
				otherwise
					_sQueroCFO = "6"
			endcase
		endif
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				if left (GDFieldGet ("C6_CF"), 1) != _sQueroCFO
					u_help ("Erro no item " + GDFieldGet ("C6_ITEM") + ": CFO invalido para o estado de destino.",, .t.)
					_lRet = .F.
					exit
				endif
			endif
		next
	endif

	// Consistencias simples ref. volumes
	if _lRet 
		_sCartu = GETMV("ML_CARTU")
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				if alltrim (GDFieldGet ("C6_PRODUTO")) $ _sCartu
					if m->c5_Volume2 == 0
						u_help ("Este pedido contem itens sem calculo automatico de quantidade de volumes (" + alltrim (GDFieldGet ("C6_PRODUTO")) + "). O campo '" + alltrim (RetTitle ("C5_VOLUME2")) + "' deve ser preenchido.",, .t.)
						_lRet = .F.
						exit
					endif
				endif
			endif
		next
	endif
	
	// Consistencias para envio de NF-e
	if _lRet .and. ! IsInCallStack ("U_VA_GPDM") .and. cNumEmp != '0201'
		_lRet = U_VerNFe ("PV")
	endif
	
	// Consistencias referentes a saldos em estoques.
	if _lRet .and. ! IsInCallStack ("U_VA_GPDM")
		_lRet = _VerEstq ()
	endif

	// Consistencias referentes a pedidos digitados por representantes externos.
	if _lRet .and. type ("_sCodRep") == "C"  // Representantes externos nao validam.
		_lRet = _VerRepr ()
	endif

	// Consistencias ref. transferencias entre filiais.
	if _lRet
		_lRet = _VerTrFil ()
	endif

	// Consiste vendas de produtos a associados.
	if _lRet .and. cNumEmp != '0201'
		_lRet = _VerAssoc ()
	endif

	// Consiste remessas de bags para dispenser sem os copos descartaveis. Ateh isso me pedem...
	if _lRet
		_lRet = _VerCopos ()
	endif

	// Valida Tipo de Frete do Pedido com o Tipo de Frete da Tabela de Precos
	if _lRet .and. ! IsInCallStack ("U_VA_GPDM") .and. ! IsInCallStack ("U_EDIM1")
		_lRet = _VerTPFre ()
	endif

	// Validacoes ref. cargas OMS.
	if _lRet
		_lRet = _VerCarga ()
	endif
	
	// Recalcula valor previsto para a nota fiscal e margem por que ficam persistidos em campos do SC5 que sao consultados fora desta tela. 
	if _lRet
		m->c5_vaVlFat = Ma410Impos (iif (inclui, 3, 4), .T.)  // (nOpc, lRetTotal, aRefRentab)
		processa ({|| U_VA_McPed (.F., .T.), "Calculando margem de contribuicao"})
	endif

	// validação condição de pagamento/forma de pagamento
	if _lRet
		if alltrim(m->c5_vatipo) == 'CD'
			if !(m->c5_condpag $ GetMv("VA_PGTOCD")) 
				_lRet := .F.
				u_help("Forma de pgto " + m->c5_condpag + " não é a correta para a forma de pgto " + m->c5_vatipo + ". Verifique!")
			endif
		endif
		if alltrim(m->c5_vatipo) == 'CC'
			if !(m->c5_condpag $  GetMv("VA_PGTOCC")) 
				_lRet := .F.
				u_help("Forma de pgto " + m->c5_condpag + " não é a correta para a forma de pgto " + m->c5_vatipo + ". Verifique!")
			endif
		endif
	endif

	// validação de pedido de associado com mudas + açucar
	If _lRet
		// Verifica se o cliente eh um associado
		_sCGC    :=  fbuscacpo("SA1",1,xfilial("SA1")+ m->c5_cliente + m->c5_lojacli ,"A1_CGC") // busca cpf para localizar o associado na A2
		_sFornec :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_COD")  // busca por cnpj/cpf
		_sLojFor :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_LOJA") // busca por cnpj/cpf

		_oAssoc := ClsAssoc():New (_sFornec, _sLojFor) 
		if valtype (_oAssoc) == "O" .and. _oAssoc:EhSocio ()
			_sMuda   := 'N'
			_sAcucar := 'N'
			_sMilho  := 'N'

			for _N = 1 to len (aCols)
				N := _N
				if ! GDDeleted ()
					if alltrim (GDFieldGet ("C6_PRODUTO")) $ '7206/7207'// mudinhas
						_sMuda := 'S'					
					endif
					if alltrim (GDFieldGet ("C6_PRODUTO")) $ '5446' 	// açucar
						_sAcucar := 'S'					
					endif
					if alltrim (GDFieldGet ("C6_PRODUTO")) $ '5456' 	// milho
						_sMilho := 'S'					
					endif 
				endif
			next

			If (_sMuda == 'S' .and. _sAcucar == 'S') 
				_lRet := .F.
				u_help("Não é permitido vender mudas e açúcar mascavo para associados no mesmo pedido. Verifique!")
			EndIf	
			If (_sMuda == 'S' .and. _sMilho == 'S') 
				_lRet := .F.
				u_help("Não é permitido vender mudas e milho para associados no mesmo pedido. Verifique!")
			EndIf		
		endif
	EndIf

	If _lRet .and. ! IsInCallStack("U_BATMERCP")
		_lBonif := .T.
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				if ! sf4 -> (msseek (xfilial ("SF4") + GDFieldGet("C6_TES"), .F.))
					u_help ("Cadastro do TES '" + GDFieldGet("C6_TES") + "' nao localizado!")
					_lRet = .F.
				else
					_lBonif  := (sf4 -> f4_margem == '3')
					if _lBonif
						if empty(m->c5_vabtpo)
							u_help(" Pedido de bonificação exige preenchimento do tipo de bonificação!")
							_lRet := .F.
						endif

						if m->c5_vabtpo == '1' .and. (empty(m->c5_vabfil) .or. empty(m->c5_vabref))
							u_help(" Pedido de bonificação de tipo 'Negociação comercial' exige preenchimento de filial e pedido de venda origem!")
							_lRet := .F.
						endif
						exit
					EndIf
				endif
			Endif
		next
	EndIf

	// Obriga a informar NSU e Id Pagar-me em pedidos e-commerce
	If _lRet
		If !Empty(M->C5_PEDECOM)
			If Empty(M->C5_VANSU)
				u_help("Para pedidos e-commerce, informar NSU!")
				_lRet := .F.
			EndIf
			If Empty(M->C5_VAIDT)
				u_help("Para pedidos e-commerce, informar Id Pagar-me!")
				_lRet := .F.
			EndIf
		EndIf
	EndIf

		// Verifica se é pedido exportação e se pode dar desconto no cabeçalho 
	If _lRet
		_sCliEst  := fBuscaCpo('SA1', 1, xfilial('SA1') + M->C5_CLIENTE + M->C5_LOJACLI, "A1_EST")

		If alltrim(_sCliEst) <> 'EX' .and. !Empty(m->c5_descont)
			u_help("Desconto <indenização> só pode ser usado para clientes de exportação!")
			_lRet := .F.
		EndIf
	EndIf

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log2 ('debug', procname () + " retornando " + cvaltochar (_lRet))
return _lRet
//
// --------------------------------------------------------------------------
// Verifica se a liberacao dos itens foi totalmente feita.
static function _VerLib ()
	local _lRet    := .T.
	local _lTemLib := .F.
	local _n       := N
	local _sMsg    := ""

	for _N = 1 to len (aCols)
		N := _N
		if ! GDDeleted () .and. GDFieldGet ("C6_QTDLIB") > 0
			_lTemLib = .T.
			exit
		endif
	next
	if _lTemLib
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted () .and. alltrim (GDFieldGet ("C6_BLQ")) != "R" .and. GDFieldGet ("C6_QTDLIB") < GDFieldGet ("C6_QTDVEN")
				_sMsg += "Item " + GDFieldGet ("C6_ITEM") + " (" + alltrim (GDFieldGet ("C6_PRODUTO")) + "): Quantidade liberada nao pode ser menor que quantidade vendida." + chr (13) + chr (10)
				_lRet = .F.
			endif
		next
	endif
	if ! empty (_sMsg)
		u_help (_sMsg,, .t.)
	endif
	N = _n
return _lRet
//
// --------------------------------------------------------------------------
// Verifica saldos em estoques.
static function _VerEstq ()
	local _lRet     := .T.
	local _n        := N
	local _aItens   := {}
	local _nItem    := 0
	local _sMsg     := ""
	local _sRetEstq := ""

	// Monta lista dos totais por produto por que pode haver o mesmo produto em mais de uma linha do pedido.
	_aItens = {}
	for _N = 1 to len (aCols)
		N := _N
		if ! GDDeleted () .and. GDFieldGet ("C6_QTDLIB") > 0
			_nItem = ascan (_aItens, {|_aVal| _aVal [1] == GDFieldGet ("C6_PRODUTO") .and. _aVal [2] == GDFieldGet ("C6_LOCAL") .and. _aVal [3] == GDFieldGet ("C6_TES") .and. _aVal [5] == GDFieldGet ("C6_ENDPAD")})
			if _nItem == 0
				aadd (_aItens, {GDFieldGet ("C6_PRODUTO"), GDFieldGet ("C6_LOCAL"), GDFieldGet ("C6_TES"), GDFieldGet ("C6_QTDLIB"), GDFieldGet ("C6_ENDPAD"), GDFieldGet ("C6_LOTECTL")})
			else
				_aItens [_nItem, 4] += GDFieldGet ("C6_QTDLIB")
			endif
		endif
	next

	// Verifica item a item
	_sMsg = ""
	for _nItem = 1 to len (_aItens)
		_sRetEstq = U_VerEstq ("2", _aItens [_nItem, 1], m->c5_vaFEmb, _aItens [_nItem, 2], _aItens [_nItem, 4], _aItens [_nItem, 3], _aItens [_nItem, 5], _aItens [_nItem, 6], m->c5_num)
		if ! empty (_sRetEstq)
			_sMsg += _sRetEstq + chr (13) + chr (10)
		endif
	next
	if ! empty (_sMsg)
		_lRet = U_msgyesno ("Problemas de estoque:" + chr (13) + chr (10) + _sMsg + chr (13) + chr (10) + "Deseja informar quantidade liberada mesmo assim?")

		// Grava evento para posterior consulta.
		if _lRet
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SC9001"
			_oEvento:Texto     = "Liberacao pedido sem estoque suficiente."
			_oEvento:Cliente   = sc5 -> c5_cliente
			_oEvento:LojaCli   = sc5 -> c5_lojacli
			_oEvento:PedVenda  = sc5 -> c5_num
			_oEvento:Grava ()
		endif
	endif

	N = _n
return _lRet                                                   
//
// --------------------------------------------------------------------------
// Verificacoes ref. pedidos digitados por representantes externos.
static function _VerRepr ()
	local _lRet   := .T.
	local _nLinha := 0

	for _nLinha = 1 to len (aCols)
		if ! GDDeleted (_nLinha) .and. GDFieldGet ("C6_QTDLIB", _nLinha) > 0
			u_help ("Item " + GDFieldGet ("C6_ITEM", _nLinha) + ": campo de 'Quantidade liberada' deve estar zerado.",, .t.)
			_lRet = .F.
			exit
		endif
	next
return _lRet
//
// --------------------------------------------------------------------------
// Consistencias referentes a transferencias entre filiais.
static function _VerTrFil ()
	local _lRet     := .T.
	local _nCusto   := 0
	local _N        := N
	
	_TESPCUS := GetMv ("AL_TESPCUS")
	for _N = 1 to len (aCols)
		N := _N
		if ! GDDeleted () .and. GDFieldGet ("C6_TES") $ _TESPCUS .and. m->c5_cliente != '025023'
			if ! IsInCallStack ("MATA310")  // TESTE ROBERT: Tela padrao transf. entre filiais
				_nCusto = U_PrcCust (GDFieldGet ("C6_PRODUTO"), GDFieldGet ("C6_LOCAL"))
				
				if _nCusto <= 0
					u_help ("Problema no item " + GDFieldGet ("C6_ITEM") + ": o produto tem valor " + cvaltochar (_nCusto) + " como 'preco de custo', impossibilitando a transferencia entre filiais e remessas para benef/deposito (parametro AL_TESPCUS). Contate setor de custos.",, .t.)
					_lRet = .F.
					exit
				endif

				// Se tem custo, o mesmo deve ser usado.
				if _lRet
					if GDFieldGet ("C6_PRCVEN") != _nCusto
						U_Help ("Aviso no item " + GDFieldGet ("C6_ITEM") + ": produto deve ser enviado a preco de custo ($ " + cvaltochar (_nCusto) + ") conforme parametro AL_TESPCUS. Contate setor de custos.",, .t.)
						_lRet = .F.
						exit
					endif
				endif
			endif
		endif     

        // Verifica se existe cfop de transferencia sendo usado para clientes que não sejam filiais da Aliança
   	    IF  ! m->c5_tipo $ "BD"    // Se nao for beneficiamento nem devoluçao
    	    _sCNPJ    := left(SM0->M0_CGC,14) 
    	    _sCliCNPJ := fBuscaCpo ("SA1", 1, xfilial ("SA1") + M->C5_CLIENTE + M->C5_LOJACLI, "A1_CGC")
    	    if substr(_sCNPJ,1,8) <> substr(_sCliCNPJ,1,8) // Se não for uma de nossas filiais, não pode ter CFOP de transferência
  	           if ! GDDeleted () .and. substr(GDFieldGet ("C6_CF"),2,3) $ '151/152' // /552/557'                      
				  u_help ("Aviso no item " + GDFieldGet ("C6_ITEM") + ": Para TES de Transferência, necessariamente o cliente precisa ser Filial da Aliança. Verifique!",, .t.)
				  _lRet = .F.
				  exit
    	       endif 
    	    endif   
		ENDIF                                                                                   
	next
	N = _n
return _lRet
//
// --------------------------------------------------------------------------
// Consistencias referentes a vendas de produtos para associados.
static function _VerAssoc ()
	local _lRet   := .T.
	local _oAssoc := NIL
	
	// Verifica se o cliente eh um associado
	if m->c5_tipo $ 'NPI'
		sa1 -> (dbsetorder (1))
		if sa1 -> (dbseek (xfilial ("SA1") + m->c5_cliente + m->c5_lojacli, .F.))
			sa2 -> (dbsetorder (3))  // A2_FILIAL+A2_CGC
			if sa2 -> (dbseek (xfilial ("SA2") + sa1 -> a1_cgc, .F.))
				_oAssoc := ClsAssoc():New (sa2 -> a2_cod, sa2 -> a2_loja)
				if _oAssoc:EhSocio (dDataBase)
				endif
			endif
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verifica envio de bag para dispenser sem os copos descartaveis.
static function _VerCopos ()
	local _lRet     := .T.
	local _nLinha   := 0
	local _lBags    := .F.
	local _lCopos   := .F.

	if m->c5_tipo $ 'NPI'
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha)
				if alltrim (GDFieldGet ("C6_PRODUTO", _nLinha)) $ "0430/0431/0432/0496"
					_lBags = .T.
				endif
				if alltrim (GDFieldGet ("C6_PRODUTO", _nLinha)) $ "2325" .or. (alltrim (GDFieldGet ("C6_PRODUTO", _nLinha)) $ "9999" .and. "COPO" $ upper (GDFieldGet ("C6_DESCRI", _nLinha)))
					_lCopos = .T.
				endif
			endif
		next
	
		if _lBags .and. ! _lCopos
			_lRet = U_msgnoyes ("Verifiquei que estao sendo enviados bags para dispenser sem copos descartaveis. Confirma?", .T.)
		endif
		
		for _nLinha = 1 to len (aCols)
			if alltrim (GDFieldGet ("C6_PRODUTO", _nLinha)) $ "2325" .and. GDFieldGet ("C6_QTDVEN", _nLinha) % 1000 <> 0  
				_lRet = U_msgnoyes ("Verifiquei que estao sendo enviados copos com quantidade diferente de 1000. Confirma?", .T.)
			endif
		 next
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Valida o tipo de Frete do Pedido de acordo com o Tipo de Frete da Tabela de Precos
static function _VerTPFre()
	local _lRet     := .T.
    local _cTpFrete := ""

	// Descobre o Tipo de Frete da Tabela de Preco
    DbSelectArea("DA0")
    DbSetOrder(1)
    DbSeek(xFilial("DA0")+m->c5_tabela)
                                                 
    if !Eof()                                       
       _cTpFrete := DA0_VATPFR
    endif
       
	// Somente realiza a validacao se o tipo de frete do pedido for CIF ou FOB
    if m->c5_tpfrete $ 'C|F' .AND. ! empty (_cTpFrete) // _cTpFrete <> "" 
       if _cTpFrete <> m->c5_tpfrete
          _lRet = U_MsgNoYes ("Tipo de Frete do Pedido (" + m->c5_tpfrete + ") diferente do informado na Tabela de Precos (" + _cTpFrete + "). Continua?", .T.) 
       endif
    endif
return _lRet
//
// --------------------------------------------------------------------------
// Ver carga
static function _VerCarga ()
	local _lRet     := .T.
	local _n        := N
	local _sMsg     := ""

	if _lRet .and. ! cEmpAnt + cFilAnt $ '0101/0116' .and. m->c5_tpcarga == '1'
		u_help ("Pedido nao deve utilizar carga para esta filial (campo '" + alltrim (RetTitle ("C5_TPCARGA")) + "')",, .t.)
		_lRet = .F. 
	endif

	if _lRet .and. m->c5_gerawms != '2'
		_sMsg += "Pelo nosso metodo atual de trabalho, o campo '" + alltrim (RetTitle ("C5_GERAWMS")) + "' deve estar configurado para gerar servico na montagem da carga." + chr (13) + chr (10)
		_lRet = .F.
	endif

	if _lRet
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				posicione ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C6_PRODUTO"), "B1_LOCALIZ")
				if m->c5_tpcarga == '1' .and. empty (GDFieldGet ("C6_SERVIC")) .and. sb1 -> b1_localiz == 'S'
					_sMsg += "Pedido utiliza carga. Item " + GDFieldGet ("C6_ITEM") + ": Produto '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "' usa controle de enderecamento. O campo '" + alltrim (RetTitle ("C6_SERVIC")) + "' deve ser informado." + chr (13) + chr (10)
					_lRet = .F.
				endif

				if m->c5_tpcarga == '2' .and. ! empty (GDFieldGet ("C6_SERVIC"))
					_sMsg += "Pedido nao utiliza carga. Item " + GDFieldGet ("C6_ITEM") + ": O campo '" + alltrim (RetTitle ("C6_SERVIC")) + "' nao deve ser informado." + chr (13) + chr (10)
					_lRet = .F.
				endif

				if m->c5_tpcarga == '1' .and. fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("C6_TES"), "F4_ESTOQUE") != 'S'
					_sMsg += "Quando o pedido utiliza carga, todos os TES devem movimentar estoque para nao gerar tarefas de separacao indevidamente (Item " + GDFieldGet ("C6_ITEM") + ": TES '" + GDFieldGet ("C6_TES") + "' nao movimenta estoque)." + chr (13) + chr (10)
					_lRet = .F.
				endif

				if m->c5_tpcarga == '1' .and. (!empty (GDFieldGet ("C6_LOCALIZ")) .or. !empty (GDFieldGet ("C6_ENDPAD")))
					_sMsg += "Item " + GDFieldGet ("C6_ITEM") + ": Pedido utiliza carga. Campos '" + alltrim (RetTitle ("C6_LOCALIZ")) + "' e '" + alltrim (RetTitle ("C6_ENDPAD")) + "' nao devem ser informados." + chr (13) + chr (10)
					_lRet = .F.
				endif 	
			endif
		next
	endif
	
	if ! empty (_sMsg)
		u_help (_sMsg,, .t.)
	endif

	// if _lRet .and. !IsInCallStack ("U_BATMERCP")
	// 	for _N = 1 to len (aCols)
	// 		N := _N
	// 		if ! GDDeleted ()
	// 			posicione ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C6_PRODUTO"), "B1_LOCALIZ")
	// 			if m->c5_tpcarga == '1' .and. GDFieldGet ("C6_LOCAL") != '01'
	// 				_lRet = U_MsgNoYes ("Pedido utiliza carga. Item " + GDFieldGet ("C6_ITEM") + ": O campo '" + alltrim (RetTitle ("C6_LOCAL")) + "' deveria ser '01'. Confirma assim mesmo?")
	// 				if ! _lRet
	// 					exit  // Nem pergunta para os proximos itens
	// 				endif
	// 			endif
	// 		endif
	// 	next
	// endif
	if _lRet .and. !IsInCallStack("U_BATMERCP")
		for _N = 1 to len (aCols)
			N := _N
			if !GDDeleted()
				if m->c5_tpcarga == '1' .and. GDFieldGet("C6_LOCAL") != '01'
					u_help("Pedido utiliza carga. Item " + GDFieldGet ("C6_ITEM") + ": O campo '" + alltrim (RetTitle ("C6_LOCAL")) + "' deve ser '01'.")
					_lRet = .F.
				endif
			endif
		next
	endif
	N = _n
return _lRet
