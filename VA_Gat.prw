// Programa:  VA_Gat
// Autor:     Robert Koch
// Data:      29/09/2008
// Descricao: Gatilhos genericos (para campos diversos do sistema).
//
// Historico de alteracoes:
// 30/10/2008 - Robert - Busca custo repos. no C6_PRCVEN quando remessa para deposito.
// 17/01/2009 - Robert - Criado gatilho para buscar preco da uva pelo campo D1_GRAU.
// 26/01/2009 - Robert - Busca preco da uva pela funcao U_PrecoUva ().
//                     - Criado gatilho para preencher o grau da uva no D1_DESCRI.
// 19/02/2009 - Robert - Criado gatilho para preencher o campo ZZ5_SEQ.
// 23/02/2009 - Robert - Criado gatilho para preencher o campo UC_CODCONT.
// 24/02/2009 - Robert - Criado gatilho para preencher o campo D1_CLASFIS.
// 04/03/2009 - Robert - Criados tratamentos para que o armazem geral possa ser representado tambem por fornecedor e nao somente cliente.
// 12/03/2009 - Robert - Criado gatilho para preencher o campo ZZ7_SEQ.
// 28/03/2008 - Robert - Passa a verificar se estah usando base TOP ou nao (programa baixado no computador de Livramento)
// 02/04/2009 - Robert - F3 de almoxarifados ignorava selecao feita pelo usuario (campo C6_PRODUTO)
// 14/05/2009 - Robert - Criados gatilhos para alimentar o campo C6_VALTDCO
// 25/06/2009 - Robert - Unificados gatilhos para alimentar o campo C6_VALTDCO (C6_PRODUTO, C6_QTDVEN, )
// 27/07/2009 - Robert - Criados gatilhos para alimentar os campos ZW_FIMHIST e ZW_FIMPREV
// 05/10/2009 - Robert - Gatilho do C6_PRODUTO que atualiza o estoque na empresa 02.
// 14/10/2009 - Robert - Gatilhos para nome e UF do cliente no pedido de venda.
//                     - Gatilhos para calculo de ST no pedido de venda.
// 22/10/2009 - Robert - Passa a usar tabela 03 do ZX5 em lugar da tabela 77 do SX5.
//                     - Retorno dos gatilhos do C6_VALTDCO.
// 28/10/2009 - Robert - Novo parametro para funcao de calculo da ST.
// 19/01/2010 - Robert - Criados gatilhos para alimentar os campos da tabela SZF e campo D1_PRM99.
// 22/02/2010 - Robert - Passa a ler o campo ZX5_03FAT no gatilho do C6_PRODUTO.
// 03/05/2010 - Robert - Criados gatilhos para atualizar o campo C5_vaAltVP
// 17/06/2010 - Robert - Criados gatilhos para atualizar o campo B1_vaEanUn
// 22/09/2010 - Robert - Criados gatilhos para atualizar os campos C6_TES e C6_CF.
//                     - Parava de executar gatilhos (erro) quando tentava abrir telas em modo batch.
// 04/10/2010 - Robert - Criado gatilho para verificar estoque a partir do C6_QTDVEN.
// 05/10/2010 - Robert - Desabilitada tela de escolha do armazem externo por que ainda nao temos previsao de inicio de operacao.
// 17/10/2010 - Robert - TES '606' passa a buscar custo medio para alimentacao do C6_PRCVEN.
// 20/10/2010 - Robert - Alteracoes gatilho de verificacao de estoques do C6_QTDVEN para trabalhar com campo C5_vaFEmb.
// 28/10/2010 - Robert - Alteracoes parametros chamada funcao VerEstq.
// 01/11/2010 - Robert - Gatilho do C6_TES passa a prever embarque pela filia 04.
// 05/11/2010 - Robert - Novos parametros funcao VerEstq.
// 07/11/2010 - Robert - Gatilho do C6_QTDVEN nao verifica mais estoques quando chamado via rotina U_VA_GPDM.
// 10/01/2011 - Robert - Define vendedor 1 para pedido de venda cfe. a filial atual ('diretos' das novas unidades).
// 28/01/2011 - Robert - Busca custo medio para TES 534 e 558 no pedido de venda.
// 01/03/2011 - Robert - Gatilhos para campos do SZI.
// 21/06/2011 - Robert - Gatilho para buscar obs. do cliente (A1_OBSALI) para o pedido de venda.
// 07/07/2011 - Robert - Desabilitado gatilho do ZI_TM.
// 11/08/2011 - Robert - TES de remessa para deposito e transf. entre filiais passam a buscar custo medio para o SC6.
// 15/08/2011 - Robert - TES de remessa para deposito e transf. entre filiais voltam a buscar custo standard para o SC6 (somente quando matriz).
// 18/10/2011 - Robert - Campo C5_VAALTVP nao eh mais alterado pelos campos C5_VOLUME2 e C5_ESPECI2.
// 16/12/2011 - Robert - Funcao VerEstq passa a receber parametro de endereco de estoque.
// 28/12/2011 - Robert - Criacao de gatilhos para a tabela SZF.
// 02/01/2012 - Robert - Gat. p/ precificacao de transferencias feitas pela matriz voltam a buscar custo medio e nao mais de reposicao.
// 13/03/2012 - Robert - Gatilhos para calculo de ST na tabela de precos.
// 13/12/2012 - Elaine - Incluir tratamento para que vendedor não seja inativo
// 24/01/2013 - Elaine - Alterar tratamento para busca do TES para calculo do ST na Tabela de Precos
// 25/04/2013 - Elaine - Incluir tratamento para o campo M->ZQ_CLIFOR
// 09/05/2013 - Elaine - Passa a calcular ST chamando rotina unica VA_PROCST
// 21/05/2013 - Robert - Preparado para receber campos por parametro.
// 27/07/2013 - Robert - Passa a buscar preco de custo para o SC6 na funcao U_PrcCust().
// 04/10/2013 - Robert - Trata aliquota fixa de 17% para cálculo de ST na tabela de precos (DA0_VAST).
// 10/12/2013 - Robert - Novo parametro (simples nacional) na funcao de calculo de ST.
// 01/02/2014 - Robert - Gatilho que verifica estoque no ped.venda passa a chamar visualizacao de disponibilidade de estoque.
// 28/04/2014 - Marcelo- Tela para seleção de carga para os tickets da portaria.
// 19/05/2014 - Marcelo- Tela no pedido de venda que mostra registros do SC9 para o produto que esta sendo digitado.
// 25/06/2014 - Catia  - Tabela de preço, gatilho de recalculo da ST
//                     - Tabela de preço, novo gatilho DA1_ESTADO trazendo atribuição do DA1_ICMS
// 22/08/2014 - Robert - Funcao U_PrcCust parametrizada para buscar valor no SB2 e nao mais do SB9.
// 25/08/2014 - Catia  - ZA9 - busca transportadores que ja foram usadas para o cliente
// 17/09/2014 - Catia  - ZA9 - busca transportadores - dava erro quando nao tinha nenhum transportador
// 14/04/2015 - Robert - Desabilitados calculos de ST no ambiente TESTE.
// 07/08/2015 - Robert - Tratamentos gatilho D3_VAETIQ para OP de retrabalho.
// 25/08/2015 - Robert - Passa a exigir campo e sequencia como parametros, pois algumas rotinas nao deixam o SX7 posicionado.
//                     - Campos do DA1 precisam ser lidos ora com 'M->' ora com GDFieldGet (parece ter havido alteracao na rotina).
// 26/08/2015 - Robert - Melhoradas msg. de onde o produto encontra-se empenhado (C6_QTDVEN)
// 12/09/2015 - Robert - Passa a usar a funcao U_CalcST4 para gerar o DA1_VAST a partir do DA1_PRCVEN.
// 17/09/2015 - Robert - Verifica se existe 'VA_GAT' na regra do gatilho que vai ser executado.
// 24/09/2015 - Catia  - E2_CODBAR x  E2_LINDIG
// 23/10/2015 - Robert - Parametros novos (quantidade e TES) na funcao CalcST4().
// 06/11/2015 - Robert - Funcao VA_DISPONESTQ do SQL renomeada para VA_FDISPONESTQ.
//                     - Parametros cliente,loja nao estavam sendo passados como NIL para a funcao CalcST4.
// 18/11/2015 - Robert - Desabilitada leitura de cargas no campo ZZT_MOTIVO.
// 25/11/2015 - Catia  - Alterado teste do IPI nos itens para sugerir o TES a ser informado no pedido - contempla agora IPI de Pauta e de Aliquota
// 10/03/2015 - Catia  - SF6 - F6_TIPOIMP - F6_CODREC  
// 25/05/2016 - Robert - Ajustes gatilhos peso liquido controle portaria.
// 27/07/2016 - Robert - Criado gatilho para o campo ZAF_LOCALI.
// 28/10/2016 - Robert - Sugere preco de custo para o TES 697 (gatilho C6_TES -> C6_PRCVEN).
// 22/11/2016 - ProcData - Validação de exclusão/alteração para compatibilidade com sistema Mercanet.
// 08/12/206  - Robert - Removidos trechos comentariados; programa reindentado.
//                     - Removidos avisos ref. Mercanet no pedido de venda.
// 23/12/2016 - Catia  - Sugere preco de custo para o TES 630 (gatilho C6_TES -> C6_PRCVEN).
// 28/04/2017 - Robert - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 29/05/2017 - Catia  - Controle de regime especial ST no gatilho para TES dos produtos
// 21/06/2017 - Catia  - Alterado regime especial estava invetido alcoolicos e nao alcoolicos
// 26/06/2017 - Catia  - Alterado gatilho D1_TES contradominimo D1_CLASFIS estava acessando M->D1_TES
// 21/08/2017 - Catia  - Alterado gatilho DA1_PRCVEN contradominimo DA1_VAST - caso dos clientes SIMPLES SP - tabela 962
// 21/09/2017 - Catia  - Incluido TES 657 no teste para puxar o preço de custo
// 07/11/2017 - Robert - Passa a validar o parametro AL_TESPCUS para itens que devem sair a preco de custo.
// 09/01/2018 - Robert - Gatilho para alimentar o campo ZF_IDSZ9
// 24/04/2018 - Catia  - Desabilitado gatilho do C5_CLIENTE pro C5_VEND
// 19/10/2018 - Catia  - Gatilho para buscar o preço correto no sistema das lojas LR_PRODUTO
// 30/11/2018 - Catia  - TES defaul no pedido
// 04/12/2018 - Andre  - Adicionado validação dos campos E2_CODBAR e E2_LINDIG com a função VLDCODBAR
// 05/12/2018 - Catia  - Gatilhos de TES 
// 08/01/2019 - Robert - Gatilho ZF_CADVITI alimentando ZF_CADCPO.
// 02/05/2019 - Robert - GPLI 5814 - Gatilho do C6_TES para C6_PRCVEN passa a executar tambem a partir do C6_OPER (TES inteligente).
//                                 - Verifica estoque no C6_QTDVEN somente se o TES ja estiver preenchido.
// 26/07/2019 - Robert - Desabilitados gatilhos campo B1_VAEANUN (vamos usar campos padrao do sistema) - GLPI 6335.
// 01/08/2019 - Robert - Ajustes gatilhos C6_TES - caiu a ST de alcoolicos para RS. GLPI 6396
// 04/12/2019 - Andre  - Atualizada regra para novos TES (752 e 753) para consumidor final do RS em caso de Bonificação.
// 12/12/2019 - Robert - Transferencias para a filial 16 precisam usar tabela de precos e nao custo. GLPI 7208.
// 22/01/2020 - Robert - Ajustes gatilhos SZF.
// 20/02/2020 - Robert - Desabilitados gatilhos do ZF_IDSZ9 (cadastros estao desatualizados, nao ajuda em nada. Vai ser passado para NaWeb).
// 15/05/2020 - Robert - Nao verifica estoque do C6_PRODUTO quando executando via importacao do Mercanet.
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function VA_Gat (_sParCpo, _sParSeq)
local _xRet     := NIL
local _sCampo   := alltrim (ReadVar ())
local _sCDomin  := ""
local _sSeqGat  := ""
local _aAreaAnt := U_ML_SRArea ()
local _aAmbAnt  := U_SalvaAmb ()
local _sQuery   := ""
local _sAliasQ  := ""
local _aCampos  := {}
local _aAlmox   := {}
local _nF3      := 0
local _sCpo     := ""
local _nCpo     := 0
local _aDadosST := {}
local _aRetQry  := 0
local _sMsg     := ""
local _oEvento  := NIL
local _oAssoc   := NIL
local _oSQL     := NIL
local _sUvaF    := ""
local _oLivram  := NIL
local _lRecolST := .F.
local _sMsgErr  := ""
local _nLin     := 0
local _sProduto := ""
local _sAlmox   := ""
local _sEnderec := ""

if valtype (_sParCpo) != "C" .or. valtype (_sParSeq) != "C"
	_sMsgErr = "Funcao " + procname () + " nao recebeu parametros de campo/sequencia. Gatilho nao vai ser executado. Caso ajude, o retorno da funcao READVAR eh '" + alltrim (ReadVar ()) + "'"
	u_help (_sMsgErr)
	u_AvisaTI (_sMsgErr)
else

	// Ajusta tamanho da variavel para nao dar problema no dbseek.
	_sParCpo = left (upper (alltrim (_sParCpo)) + '          ', 10)

	// Procura definicao do gatilho.
	sx7 -> (dbsetorder (1))  // X7_CAMPO + X7_SEQUENC
	if sx7 -> (dbseek (_sParCpo + _sParSeq, .F.))
		_sCampo  = 'M->' + alltrim (sx7 -> x7_campo)
		_sCDomin = alltrim (sx7 -> x7_cdomin)
		if ! "VA_GAT" $ upper (sx7 -> x7_regra)
			U_AvisaTI ("Gatilho do campo: '" + _sParCpo + "' seq.: '" + _sParSeq + "' nao contem 'VA_GAT' no campo x7_regra. Suspeito que isso seja um problema. Gatilho nao serah executado.")
			_sCampo = ''
			_sCDomin = ''
		endif
	else
		U_AvisaTI ("Gatilho nao encontrado no SX7. Campo: '" + _sParCpo + "' Seq.: '" + _sParSeq + "'. Gatilho nao serah executado.")
		_sCampo = ''
		_sCDomin = ''
	endif
endif

//CursorWait ()
do case
//	case _sCampo $ "M->B1_VAEANUN" .and. _sCDomin == "B1_VAEANUN"
//		_xRet = U_ML_DVEAN (alltrim (m->B1_VAEANUN), .T.)

	case _sCampo $ "M->C5_CLIENTE/M->C5_LOJACLI" .and. _sCDomin == "C5_NOMECLI"
		if m->c5_tipo $ "BD"
			_xRet = fbuscacpo("SA2",1,xFilial("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_NOME")
		else
			_xRet = fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NOME")
		endif

	case _sCampo $ "M->C5_CLIENTE/M->C5_LOJACLI" .and. _sCDomin == "C5_VAEST"
		if m->c5_tipo $ "BD"
			_xRet = fbuscacpo("SA2",1,xFilial("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_EST")
		else
			_xRet = fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_EST")
		endif

	case _sCampo $ "M->C5_CLIENTE/M->C5_LOJACLI" .and. _sCDomin == "C5_VAMUN"
		if m->c5_tipo $ "BD"
			_xRet = fbuscacpo("SA2",1,xFilial("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_MUN")
		else
			_xRet = fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_MUN")
		endif


	case _sCampo $ "M->C5_PBRUTO/M->C5_PESOL" .and. _sCDomin == "C5_VAALTVP"
		_xRet = m->C5_VAALTVP  // Se nao encontrar nada, deixa valor pronto para retorno.
		if u_msgyesno ("Se voce informar este campo manualmente, os pesos deste pedido nao serao mais calculados automaticamente. Confirma?")
			if empty (m->c5_vaAltVP) .or. m->c5_vaAltVP == "N"
				_xRet = "P"
			elseif m->c5_vaAltVP == "V"
				_xRet = "A"
			endif
		endif


	case _sCampo $ "M->C5_VOLUME1/M->C5_ESPECI1" .and. _sCDomin == "C5_VAALTVP"
		_xRet = m->C5_VAALTVP  // Se nao encontrar nada, deixa valor pronto para retorno.
		if u_msgyesno ("Se voce informar este campo manualmente, os campos 'Volume 1' e 'Especie 1' deste pedido nao serao mais calculados automaticamente. Confirma?")
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven  = "SC5002"
			_oEvento:Texto    = "Campo volume1/especie1 digitado manualmente pelo usuario"
			_oEvento:PedVenda = m->c5_num
			_oEvento:Grava ()
	
			if empty (m->c5_vaAltVP) .or. m->c5_vaAltVP == "N"
				_xRet = "V"
			elseif m->c5_vaAltVP == "P"
				_xRet = "A"
			endif
		endif

/*
	case _sCampo $ "M->C5_CLIENTE" .and. _sCDomin == "C5_VEND1"
		if !empty (m->C5_VEND1) .and. ! m->c5_tipo $ 'DB'
			if fBuscaCpo ("SA3", 1, xfilial ("SA3") + M->C5_VEND1, "A3_ATIVO") != "S"   // Vendedor deve estar ativo
				U_Help ("Representante '" + M->C5_VEND1 + "' (cadastrado no cliente '" + m->c5_cliente + "') nao esta ativo. Voce devera informar um representante manualmente!")
				m->C5_VEND1 := ""
			endif
		endif
		_xRet = m->C5_VEND1  // Se nao encontrar nada, deixa valor pronto para retorno.
		do case
			case cNumEmp == "0105" ; _xRet = '179'
			case cNumEmp == "0106" ; _xRet = '179'
			case cNumEmp == "0107" ; _xRet = '176'
			case cNumEmp == "0108" ; _xRet = '176'
			case cNumEmp == "0109" ; _xRet = '178'
			case cNumEmp == "0110" ; _xRet = '177'
			case cNumEmp == "0111" ; _xRet = '177'
			case cNumEmp == "0112" ; _xRet = '176'
		endcase
*/		

/*
	case _sCampo $ "M->C6_VAPLIQ/M->C6_VAPBRU" .and. _sCDomin == "C6_VAALTVP"
		_xRet = GDFieldGet ('C6_VAALTVP')  // Se nao encontrar nada, deixa valor pronto para retorno.
		if u_msgyesno ("Se voce informar este campo manualmente, os pesos deste item nao serao mais calculados automaticamente. Confirma?", .T.)
			if empty (GDFieldGet ('C6_VAALTVP'))
				_xRet = "P"
			elseif GDFieldGet ('C6_VAALTVP') == "V"
				_xRet = "A"
			endif
		endif


	case _sCampo $ "M->C6_VAQTVOL" .and. _sCDomin == "C6_VAALTVP"
		_xRet = GDFieldGet ('C6_VAALTVP')  // Se nao encontrar nada, deixa valor pronto para retorno.
		if u_msgyesno ("Se voce informar este campo manualmente, a quantidade de volumes deste item nao sera mais calculados automaticamente. Confirma?", .T.)
			if empty (GDFieldGet ('C6_VAALTVP'))
				_xRet = "V"
			elseif GDFieldGet ('C6_VAALTVP') == "P"
				_xRet = "A"
			endif
		endif
*/

	case _sCampo == "M->C6_PRODUTO" .and. _sCDomin == "C6_CF"  // Necessario apos gatilho que gera o TES a partir do produto.
		_xRet = ""
		if ! empty (GDFieldGet ("C6_TES"))
			A410MultT ("M->C6_TES", GDFieldGet ("C6_TES"))
			_xRet = acols [N, GDFieldPos ("C6_CF")]
		endif


	case _sCampo == "M->C6_PRODUTO" .and. _sCDomin == "C6_TES"
		_xRet = ""
		_wRS       = fbuscacpo ("SA1", 1, xfilial ("SA1") + M->C5_CLIENTE + M->C5_LOJACLI , "A1_EST")
		_wregesp   = fbuscacpo ("SA1", 1, xfilial ("SA1") + M->C5_CLIENTE + M->C5_LOJACLI , "A1_VAREGE")
		_lBonif    = IIF(M->C5_CONDPAG = '098',.T.,.F.)
		_wNAOalcool= "S"
		SB1->(DBSETORDER(1))
		if ! SB1->(DBSEEK(xfilial ("SB1") + GDFieldGet ("C6_PRODUTO")))
			u_help('Produto não encontrado')
		else
		if SB1->B1_VLR_IPI == 0 .and. SB1->B1_IPI == 0 	// Nao alcoolicos
			_wNAOalcool= "N"
			if alltrim(SB1->B1_POSIPI) == '22029900' .and. SB1->B1_GRUPO == '1008'  //QUENTAO E SAGU
				_wNAOalcool= "Q"
			endif
		endif
		if SB1->B1_VLR_IPI == 0 .and. SB1->B1_IPI == 4 	// Nao alcoolicos
			if alltrim(SB1->B1_POSIPI) == '22021000' .and. SB1->B1_GRUPO == '1006'  //BEBIDAS MISTAS
				_wNAOalcool= "M"
			endif
		endif
		do case
			case m->c5_tipocli == "S"  // Solidario ('com ST')
				do case 
					case _wregesp = '0' // NAO INCIDE
						if _wNAOalcool = "S"
							_xRet = IIF(_lBonif,"530","501")
						else
							_xRet = IIF(_lBonif,"528","507")
						endif
						if _wNAOalcool = "M"
							_xRet = IIF(_lBonif,"530","501")
						endif
					case _wregesp = '1' // INCIDE
						if _wNAOalcool = "N"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"705","704")
							else
								_xRet = IIF(_lBonif,"828","807")
							endif
						elseif _wNAOalcool= "Q"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"709","708")
							else 
								_xRet = IIF(_lBonif,"528","790")
							endif
						elseif _wNAOalcool= "M"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"819","818")
							else 
								_xRet = IIF(_lBonif,"830","801")
								//_xRet = IIF(_lBonif,"830","501")
							endif
						else
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"706","703")
							else
								_xRet = IIF(_lBonif,"830","801")
							endif
						endif
					case _wregesp = '2' // INSIDE PARA NAO ALCOOLICOS
						if _wNAOalcool = "N"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"705","704")  // Caiu ST de alcoolicos para RS em 01/08/2019 ---> "807"
							else
								_xRet = IIF(_lBonif,"828","807")
							endif
						elseif _wNAOalcool= "Q"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"709","708")
							else 
								_xRet = IIF(_lBonif,"528","790")
							endif	
						elseif _wNAOalcool= "M"
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"819","818")
							else 
								_xRet = IIF(_lBonif,"830","801")
							endif
						else 
							if _wRS == "RS"
								_xRet = IIF(_lBonif,"706","703")  // Caiu ST de alcoolicos para RS em 01/08/2019 ---> "501"
							else
								_xRet = IIF(_lBonif,"530","501")
							endif
						endif	
					case _wregesp = '3' // INSIDE PARA ALCOOLICOS
						if _wNAOalcool = "N"
							_xRet = IIF(_lBonif,"528","507")
						else
							_xRet = IIF(_lBonif,"830","801")
						endif		
				endcase
			case m->c5_tipocli == "R" // REVENDEDOR
				if _wNAOalcool = "N"
					_xRet = "507"
				else
					_xRet = "501"
				endif
			
			case m->c5_tipocli == "F"  // CONSUMIDOR FINAL
				if _wNAOalcool = "N"
					if _wRS == "RS"
						//_xRet = IIF(_lBonif,"705","716")
						_xRet = IIF(_lBonif,"752","716")
					else
						_xRet = IIF(_lBonif,"528","790")
					endif
				elseif _wNAOalcool= "Q"
					if _wRS == "RS"
						//_xRet = IIF(_lBonif,"709","722")
						_xRet = IIF(_lBonif,"752","722")
					else 
						_xRet = IIF(_lBonif,"528","790")
					endif	
				else
					if _wRS == "RS"
						//_xRet = IIF(_lBonif,"706","715")
						_xRet = IIF(_lBonif,"753","715")
					else
						_xRet = IIF(_lBonif,"530","791")
					endif
				endif
		endcase
		endif


	case _sCampo == "M->C6_PRODUTO" .and. _sCDomin == "C6_VAQTVOL"
		_xRet = GDFieldGet ("C6_QTDVEN")


	case _sCampo == "M->C6_QTDVEN" .and. _sCDomin == "C6_QTDVEN"
		_xRet = GDFieldGet ("C6_QTDVEN")
	
		// Verifica saldo em estoque.
//		if !IsInCallStack ("U_EDIM1") .and. ! iif (type ("_lAuto") == "L", _lAuto, .F.) .and. !IsInCallStack ("U_VA_GPDM") .and. !IsInCallStack ("U_VA_GNF5")
		if !IsInCallStack ("U_EDIM1") .and. ! iif (type ("_lAuto") == "L", _lAuto, .F.) .and. !IsInCallStack ("U_VA_GPDM") .and. !IsInCallStack ("U_VA_GNF5") .and. !IsInCallStack ("U_BATMERCP")
			if ! empty (GDFieldGet ("C6_PRODUTO")) .and. ! empty (GDFieldGet ("C6_LOCAL")) .and. ! empty (GDFieldGet ("C6_QTDVEN")) .and. ! empty (GDFieldGet ("C6_TES"))
				_sMsg = U_VerEstq ("1", GDFieldGet ("C6_PRODUTO"), m->c5_vaFEmb, GDFieldGet ("C6_LOCAL"), GDFieldGet ("C6_QTDVEN"), GDFieldGet ("C6_TES"), GDFieldGet ("C6_LOCALIZ"), GDFieldGet ("C6_LOTECTL"), m->c5_num)
				if ! empty (_sMsg)
					if U_MsgYesNo (_sMsg + chr (13) + chr (10) + chr (13) + chr (10) + "Deseja visualizar disponibilidades desse produto?", .F.)
						MaViewSB2 (GDFieldGet ("C6_PRODUTO"))
					endif
		
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += "  SELECT C9_PEDIDO as Pedido , A1_COD AS Cod_Cliente, A1_NOME as Nome_Cliente, C9_QTDLIB as Quantidade, dbo.VA_DTOC (C9_DATALIB) as Data_liberacao, C9_CARGA as Carga_OMS"
					_oSQL:_sQuery +=		" FROM " + RetSQLName ("SC9") + " SC9, "
					_oSQL:_sQuery +=                   RetSQLName ("SA1") + " SA1 "
					_oSQL:_sQuery +=        " WHERE SC9.D_E_L_E_T_  = '' "
					_oSQL:_sQuery +=        " AND SA1.D_E_L_E_T_    = '' "
					_oSQL:_sQuery +=        " AND C9_NFISCAL        = '' "
					_oSQL:_sQuery +=        " AND C9_QTDLIB         > 0  "
					_oSQL:_sQuery +=        " AND C9_FILIAL         = '" + xfilial("SC9")+"'"
					_oSQL:_sQuery +=        " AND C9_PRODUTO        = '" + alltrim (GDFieldGet ("C6_PRODUTO")) +"'"
					_oSQL:_sQuery +=        " AND C9_CLIENTE        = A1_COD "
					_oSQL:_sQuery +=      " ORDER BY C9_PEDIDO "
					if len (_oSQL:Qry2Array ()) > 0
						if U_MsgYesNo ("Deseja visualizar pedido(s) com o produto "+ alltrim (GDFieldGet ("C6_PRODUTO")) + " ?", .F.)
							_oSQL:F3Array ("Quatidade Liberada do produto '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "'")
						endif
					endif
				endif
			endif
		endif


	case (_sCampo == "M->C6_TES" .and. _sCDomin == "C6_PRCVEN") .or. (_sCampo == "M->C6_OPER" .and. _sCDomin == "C6_PRCVEN")
		_xRet = GDFieldGet ("C6_PRCVEN")  // Se nao encontrar nada, deixa o valor original pronto para retorno.

		// Para a filial 16 precisamos usar tabela de precos (legislacao...) GLPI 7208
		if m->c5_cliente != '025023'

			// Se for TES de remessa para deposito, busca o custo do produto.
			if (_sCampo == "M->C6_TES" .and. m->c6_tes $ GetMv ("AL_TESPCUS")) ;
				.or. (_sCampo == "M->C6_OPER" .and. GDFieldGet ("C6_TES") $ GetMv ("AL_TESPCUS"))
				_xRet = U_PrcCust (GDFieldGet ("C6_PRODUTO"), GDFieldGet ("C6_LOCAL"))
			endif
		endif
		

	case _sCampo == "M->D1_COD" .and. _sCDomin == "D1_CLASFIS"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = GDFieldGet ("D1_CLASFIS")

		if ! empty (GDFieldGet ("D1_TES"))
			_xRet = substr (fBuscaCpo ("SB1", 1, xfilial ("SB1") + M->D1_COD, "B1_ORIGEM"), 1, 1) + substr (fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_SITTRIB"), 1, 2)
		endif


	case _sCampo == "M->D1_TES" .and. _sCDomin == "D1_CLASFIS"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = GDFieldGet ("D1_CLASFIS")
		if ! empty (GDFieldGet ("D1_COD"))
			_xRet = substr (fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_ORIGEM"), 1, 1) + substr (fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_SITTRIB"), 1, 2)
		endif

/*
	case _sCampo == "M->D1_GRAU" .and. _sCDomin == "D1_DESCRI"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = GDFieldGet ("D1_DESCRI")
	
		// Insere o grau da uva na descricao do produto. Se jah contiver informacao do
		// grau (usuario pode estar redigitando este campo), remove a informacao anterior.
		_xRet = alltrim (GDFieldGet ("D1_DESCRI"))
		if at (" Gr. ", _xRet) > 0
			_xRet = substr (_xRet, 1, at (" Gr. ", _xRet) - 1)
		endif
		_xRet += " Gr. " + m->d1_grau
*/


//	case _sCampo == "M->D1_GRAU" .and. _sCDomin == "D1_VUNIT"
//		_xRet = U_PrecoUva (ca100for, cLoja, GDFieldGet ("D1_COD"), m->d1_grau, left (dtos (dDataBase), 4))[1]
//		_xRet = U_PrecoUva (ca100for, cLoja, GDFieldGet ("D1_COD"), m->d1_grau, left (dtos (dDataBase), 4), m->d1_prm99, m->d1_vaClABD, 'E', cFilAnt)


/* vou detonar esse campo
	case _sCampo == "M->D3_LOCALIZ" .and. _sCDomin == "D3_VALAUDO"
		_xRet = ""
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX (ZAF_ENSAIO)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAF") + " ZAF, "
		_oSQL:_sQuery +=             RetSQLName ("SBF") + " SBF "
		_oSQL:_sQuery +=  " WHERE ZAF.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=  " AND ZAF_FILIAL = '" + xfilial ("ZAF") + "'"
		_oSQL:_sQuery +=  " AND ZAF_LOCALI = '" + GDFieldGet ("D3_LOCALIZ") + "'"
		_oSQL:_sQuery +=  " AND ZAF_PRODUT = '" + GDFieldGet ("D3_COD") + "'"
		_oSQL:_sQuery +=  " AND SBF.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=  " AND SBF.BF_FILIAL  = '" + xfilial ("SBF") + "'"
		_oSQL:_sQuery +=  " AND SBF.BF_LOCALIZ = ZAF_LOCALI"
		_oSQL:_sQuery +=  " AND SBF.BF_PRODUT  = ZAF_PRODUT"
		_oSQL:_sQuery +=  " AND SBF.BF_QUANT   > 0"
		_xRet = _oSQL:RetQry ()
*/


	case _sCampo == "M->D3_VAETIQ" .and. _sCDomin == "D3_VAETIQ"
		_xRet = M->D3_VAETIQ
	
		// Atualiza campos e executa respectivas validacoes e gatilhos padrao do sistema.
		// Vale ressaltar que, para isto funcionar, o campo D3_OP eh editavel somente
		// quando o campo D3_VAETIQ nao estiver informado.
		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
		if za1 -> (dbseek (xfilial ("ZA1") + m->d3_vaetiq, .F.))
			sx3 -> (dbsetorder (2))
			m->d3_op = za1 -> za1_op
			if sx3 -> (dbseek ('D3_OP', .F.))
				&(sx3 -> x3_valid)
				&(sx3 -> x3_vlduser)
				RunTrigger (1, nil, nil,, sx3 -> x3_campo)
			endif
			if fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_VAOPESP") == 'R'
				m->d3_perda = za1 -> za1_quant
				if sx3 -> (dbseek ('D3_PERDA', .F.))
					&(sx3 -> x3_valid)
					&(sx3 -> x3_vlduser)
					RunTrigger (1, nil, nil,, sx3 -> x3_campo)
				endif
				m->d3_quant = 0
				if sx3 -> (dbseek ('D3_QUANT', .F.))
					&(sx3 -> x3_valid)
					&(sx3 -> x3_vlduser)
					RunTrigger (1, nil, nil,, sx3 -> x3_campo)
				endif
			else
				m->d3_quant = za1 -> za1_quant
				if sx3 -> (dbseek ('D3_QUANT', .F.))
					&(sx3 -> x3_valid)
					&(sx3 -> x3_vlduser)
					RunTrigger (1, nil, nil,, sx3 -> x3_campo)
				endif
			endif
		endif



	case (_sCampo == "M->ZZZ_10END" .and. _sCDomin == "ZZZ_10LOTE") .or. (_sCampo == "M->D4_VAEND" .and. _sCDomin == "D4_LOTECTL")
		_xRet = ""
		if _sCampo == "M->D4_VAEND"
			_sProduto = GDFieldGet ("D4_COD")
			_sAlmox   = GDFieldGet ("D4_LOCAL")
			_sEnderec = M->D4_VAEND
		elseif _sCampo == "M->ZZZ_10END"
			_sProduto = GDFieldGet ("ZZZ_10COD")
			_sAlmox   = GDFieldGet ("ZZZ_10ALM")
			_sEnderec = M->ZZZ_10END
		endif
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT BF_LOTECTL AS LOTE, BF_QUANT AS SALDO, dbo.VA_DTOC (B8_DTVALID) AS VALIDADE"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SBF") + " SBF, "
		_oSQL:_sQuery +=             RetSQLName ("SB8") + " SB8 "
		_oSQL:_sQuery += " WHERE SBF.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND BF_FILIAL  = '" + xfilial ("SBF") + "'"
		_oSQL:_sQuery +=   " AND BF_LOCALIZ = '" + _sEnderec + "'"
		_oSQL:_sQuery +=   " AND BF_LOCAL   = '" + _sAlmox + "'"
		_oSQL:_sQuery +=   " AND BF_PRODUTO = '" + _sProduto + "'"
		_oSQL:_sQuery +=   " AND SBF.BF_QUANT   > 0"
		_oSQL:_sQuery +=   " AND SB8.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND B8_FILIAL  = BF_FILIAL"
		_oSQL:_sQuery +=   " AND B8_PRODUTO = BF_PRODUTO"
		_oSQL:_sQuery +=   " AND B8_LOCAL   = BF_LOCAL"
		_oSQL:_sQuery +=   " AND B8_LOTECTL = BF_LOTECTL"
		_oSQL:_sQuery +=   " AND B8_NUMLOTE = BF_NUMLOTE"
		_oSQL:_sQuery += " ORDER BY B8_DTVALID"
		_oSQL:Log ()
		_aRetSQL := aclone (_oSQL:Qry2Array ())
		if len (_aRetSQL) == 1
			_xRet = _aRetSQL [1, 1]
		elseif len (_aRetSQL) > 1
			_nF3 = _oSQL:F3Array ("O endereco informado tem mais de um lote.", .T.)
			if _nF3 != NIL .and. _nF3 >= 1 .and. _nF3 <= len (_aRetSQL)
				_xRet = _aRetSQL [_nF3, 1]
			else  // Usuario teclou ESC ou cancelou
				_xRet = ''
			endif
		endif



	case _sCampo $ "M->DA1_ESTADO" .and. _sCDomin $ "DA1_ICMS"
		_sMVAliqIcm = U_SeparaCpo (alltrim (getmv ("MV_ALIQICM",, "")), "/")
		_sMVNorte   = alltrim (GetMv ("MV_NORTE"))
		_sMVEstado  = alltrim (GetMv ("MV_ESTADO"))
		_nPiece      := 0
	
		// verifica se UF da tabela é RS
		if M->DA1_ESTADO = _sMVEstado
			// usa aliquota 3
			_nPiece :=  4
		else
			// verifica se estado esta na regiao norte
			_nNorte = at (M->DA1_ESTADO, _sMVNorte)
			if _nNorte >0
				// usa aliquota 1
				_nPiece := 2
			else
				// usa aliquota 2
				_nPiece := 3
			endif
		endif
		_xRet= val( _sMVAliqIcm [_nPiece] )



	case _sCampo == "M->DA1_PRCVEN" .and. _sCDomin $ "DA1_VAST"
		_xRet = 0
		_westado = GDFieldGet ("DA1_ESTADO")
		if empty (_westado)
			_westado = M->DA0_VAUF
		endif
	
		_xRet = U_CalcST4 (_westado, GDFieldGet ("DA1_CODPRO"), m->da1_prcven, GDFieldGet ("DA1_CLIENT"), GDFieldGet ("DA1_LOJA"), 1, '801')
	
	case _sCampo == "M->E2_CODBAR" .and. _sCDomin == "E2_CODBAR"
		_wcodbar = VldCodBar(M->E2_CODBAR)
		if _wcodbar = .T. 
			_xRET = M->E2_CODBAR
		else
			_xRET = ''
		end if
		
	case _sCampo == "M->E2_LINDIG" .and. _sCDomin == "E2_LINDIG"
		_wlindig = VldCodBar(M->E2_LINDIG)
		if _wlindig = .T. 
			_xRET = M->E2_LINDIG
			M->E2_CODBAR := SUBSTR(_xRET,1,4)+SUBSTR(_xRET,33,15)+SUBSTR(_xRET,5,5)+SUBSTR(_xRET,11,10)+SUBSTR(_xRET,22,10)
		else
			_xRET = ''
		end if

/*	case _sCampo == "M->E2_CODBAR" .and. _sCDomin == "E2_CODBAR"
		_wcodbar = M->E2_CODBAR
		if empty (_wcodbar)
			_xRet = ''
		endif
		else
			// se o valor esta nos ultimos caracteres do conteudo informado no campo - é a linha digitavel
			// converte linha digitavel para o codigo de barras - formato usado do CNAB pagamentos
			if (val(substr(_wcodbar,38,10))/100) == M->E2_VALOR
				M->E2_LINDIG = _wcodbar  
				_wcodbar := SUBSTR(_wcodbar,1,4)+SUBSTR(_wcodbar,33,15)+SUBSTR(_wcodbar,5,5)+SUBSTR(_wcodbar,11,10)+SUBSTR(_wcodbar,22,10)
			endif
			_xRet = _wcodbar
		endif			
		
	case _sCampo == "M->E2_LINDIG" .and. _sCDomin == "E2_LINDIG"
		_wlindig = M->E2_LINDIG
		if empty (_wLINDIG)
			_xRet = ''
		else
			// se o valor esta nos ultimos caracteres do conteudo informado no campo - é a linha digitavel
			// converte linha digitavel para o codigo de barras - formato usado do CNAB pagamentos
			if (val(substr(_wlindig,38,10))/100) == M->E2_VALOR
				M->E2_CODBAR = _wlindig  
			endif
			_xRet = _wlindig
		endif
*/
	case _sCampo == "M->F6_TIPOIMP" .and. _sCDomin == "F6_CODREC"
		_xRet = ''
		do case
			case M->F6_TIPOIMP == '1'
			_xRet = '0222'
			case M->F6_TIPOIMP == '3'
			_xRet = '100048'	
		endcase			



	case (_sCampo == "M->UC_VACLIEN" .or. _sCampo == "M->UC_VALOJA") .and. _sCDomin == "UC_CODCONT"
		if ! empty (m->uc_vaclien) .and. ! empty (m->uc_valoja)
			// Se nao encontrar nada, deixa o valor pronto para retorno.
			_xRet = m->uc_codcont
	
			_sQuery := ""
			_sQuery += " select U5_CODCONT, U5_CONTAT, U5_FONE"
			_sQuery +=   " from " + RetSQLName ("SU5") + " SU5, "
			_sQuery +=              RetSQLName ("SA1") + " SA1, "
			_sQuery +=              RetSQLName ("AC8") + " AC8  "
			_sQuery +=  " where SU5.D_E_L_E_T_ = ''"
			_sQuery +=    " and SA1.D_E_L_E_T_ = ''"
			_sQuery +=    " and AC8.D_E_L_E_T_ = ''"
			_sQuery +=    " and SU5.U5_FILIAL  = '" + xfilial ("SU5") + "'"
			_sQuery +=    " and AC8.AC8_FILIAL = '" + xfilial ("AC8") + "'"
			_sQuery +=    " and AC8.AC8_CODCON = SU5.U5_CODCONT"
			_sQuery +=    " and AC8.AC8_CODENT = SA1.A1_COD + SA1.A1_LOJA"
			_sQuery +=    " and AC8.AC8_FILENT = SA1.A1_FILIAL"
			_sQuery +=    " and AC8.AC8_ENTIDA = 'SA1'"
			_sQuery +=    " and AC8.AC8_CODENT = '" + m->uc_vaclien + m->uc_valoja + "'"
			_aF3 = aclone (U_Qry2Array (_sQuery))
	
			// Se soh encontrou um contato, eh esse mesmo. Se nao encontrou nenhum,
			// nao retorna nada. Senao, pede ao usuario que selecione.
			if len (_aF3) == 1
				_xRet = _aF3 [1, 1]
			elseif len (_aF3) > 1
				_aCampos = {}
				aadd (_aCampos, {1, "Codigo",    40, "@!"})
				aadd (_aCampos, {2, "Nome",      80, "@!"})
				aadd (_aCampos, {3, "Telefone",  60, "@!"})
	
				_nF3 = U_F3Array (_aF3, "", _aCampos, NIL, NIL, "Contatos ligados ao cliente", "", .F.)
				if _nF3 > 0
					_xRet = _aF3 [_nF3, 1]
				endif
			endif
		endif



	case _sCampo == "M->ZA1_OP" .and. _sCDomin == "ZA1_SEQ"
		if empty (m->za1_op)
			_xRet = 0
		else                                                                  
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA1")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND ZA1_OP     = '" + m->za1_op + "'"
			_xRet = _oSQL:RetQry () + 1
		endif



	case _sCampo == "M->ZA9_CLI" .and. _sCDomin == "ZA9_TRANSP"
		_xRet = ""
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT(F2_TRANSP)"
		_oSQL:_sQuery += "     , CASE WHEN SF2.F2_TRANSP != ' ' THEN (SELECT A4_NOME FROM SA4010 WHERE A4_COD = SF2.F2_TRANSP) ELSE ' ' END AS NOME"
		_oSQL:_sQuery += "  FROM " + RetSQLName ("SF2")  + " SF2 "
		_oSQL:_sQuery += " WHERE SF2.F2_FILIAL   = '" +xfilial ("SF2")+ "'"
		_oSQL:_sQuery += "   AND SF2.F2_EMISSAO >= '20140601'"
		_oSQL:_sQuery += "   AND SF2.F2_CLIENTE  = '" + M->ZA9_CLI + "'"
		_oSQL:_sQuery += "   AND SF2.F2_TRANSP  != ' ' "
	
		_aRetSQL := aclone (_oSQL:Qry2Array ())
		if len (_aRetSQL) > 0
			// so interessam 3 transportadoras
			for _nLin = 1 to len(_aRetSQL)
				do case
					case _nLin=1
					// atualiza dados do transportador no ZA9
					m->za9_ctra1  = _aRetSQL [_nLin,01]
					m->za9_trans1 = _aRetSQL [_nLin,02]
					case _nLin=2 // atualiza dados do transportador no ZA9
					m->za9_ctra2   = _aRetSQL [_nLin,01]
					m->za9_trans2  = _aRetSQL [_nLin,02]
					case _nLin=3 // atualiza dados do transportador no ZA9
					m->za9_ctra3   = _aRetSQL [_nLin,01]
					m->za9_trans3  = _aRetSQL [_nLin,02]
				endcase
			next _nLin
		endif



	case _sCampo == "M->ZAF_LOCALI" .and. _sCDomin $ "ZAF_PRODUT/ZAF_LOTE"
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT TOP 1 ISNULL (" + iif (_sCDomin == "ZAF_PRODUT", "BF_PRODUTO", "BF_LOTECTL") + ", '')"  // Soh deveria ter um, mas, para garantir...
		_oSQL:_sQuery += "  FROM " + RetSQLName ("SBF")  + " SBF "
		_oSQL:_sQuery += " WHERE SBF.BF_FILIAL   = '" + xfilial ("SBF") + "'"
		_oSQL:_sQuery += "   AND SBF.D_E_L_E_T_  = ''"
		_oSQL:_sQuery += "   AND SBF.BF_LOCAL    = '" + m->zaf_local  + "'"
		_oSQL:_sQuery += "   AND SBF.BF_LOCALIZ  = '" + m->zaf_locali + "'"
		_oSQL:_sQuery += "   AND SBF.BF_QUANT    > 0"
		_oSQL:Log ()
		_xRet = _oSQL:RetQry (1, .F.)



	case _sCampo $ "M->ZE_PLACA" .and. _sCDomin $ "ZE_PLACA"
		_xRet = M->ZE_PLACA  // Se nao encontrar nada, deixa o valor pronto para retorno.
		if alltrim (M->ZE_PLACA) $ '.,*+-/'
	
			// Busca placas de veiculos usados por qualquer associado ligado ao mesmo patriarca.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SZE.ZE_PLACA, COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZE") + " SZE "
			_oSQL:_sQuery +=  " WHERE SZE.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SZE.ZE_ASSOC   = '" + m->ze_assoc + "'"
			_oSQL:_sQuery +=    " AND SZE.ZE_LOJASSO = '" + m->ze_lojasso + "'"
			_oSQL:_sQuery +=    " AND SZE.ZE_SAFRA  >= '" + strzero (val (m->ze_safra) - 1, 4) + "'"  // Apenas na safra atual e anterior.
			_oSQL:_sQuery +=    " AND SZE.ZE_PLACA NOT IN ('.',',','')"
			_oSQL:_sQuery +=  " GROUP BY SZE.ZE_PLACA"
			_oSQL:_sQuery +=  " ORDER BY COUNT (*) DESC"
			_aF3 = aclone (_oSQL:Qry2Array ())
			if len (_aF3) == 0
				u_help ("Nao ha registro de placas de veiculos previamente utilizadas por este associado / fornecedor.")
			else
				_aCampos = {}
				aadd (_aCampos, {1,  "Placa",  50,  ""})
				_nF3 = U_F3Array (_aF3, "Placas informadas previamente", _aCampos, 200, 300, "Placas informadas previamente", "", .F.)
				if _nF3 > 0
					_xRet = _aF3 [_nF3, 1]
				endif
			endif
		endif



	case _sCampo $ "M->ZF_CADVITI" .and. _sCDomin $ "ZF_ITEMVIT"
		_xRet = 0  // Se nao encontrar nada, deixa o valor pronto para retorno.
	
		// Alimenta campo virtual que vai guardar qual linha da array de cadastros viticolas foi selecionada.
		// posteriormente esse campo serah usado em outros gatilhos.
		if empty (GDFieldGet ("ZF_ITEMVIT"))
			_aF3 = aclone (_aCadVitic)  // Variavel private do programa chamador.
			if len (_aF3) == 0
				u_help ("Nao ha cadastro viticola / variedades cadastradas para este associado. Verifique cadastro/renovacao do cadastro viticola e amarracao com grupos familiares.")
			else
				_aCampos = {}
				aadd (_aCampos, {.CadVitCodigo,     "Cad.viticola",    50,  ""})
				aadd (_aCampos, {.CadVitDescMun,    "Municipio",       80,  ""})
				aadd (_aCampos, {.CadVitProduto,    "Variedade",       50,  ""})
				aadd (_aCampos, {.CadVitDescPro,    "Descricao",      100,  ""})
				aadd (_aCampos, {.CadVitSafrVit,    "Renov.p/",        40,  ""})
				aadd (_aCampos, {.CadVitNomeGrpFam, "Grupo familiar",  60,  ""})
				aadd (_aCampos, {.CadVitSistCond,   "Conducao",        30,  ""})
				_nF3 = U_F3Array (_aF3, "Selecione cadastro viticola / variedade de uva", _aCampos, NIL, NIL, "Selecione cadastro viticola / variedade de uva", "", .F.)
				if _nF3 > 0
					_xRet = _nF3
				endif
			endif
		endif



//	case _sCampo $ "M->ZF_CADVITI" .and. _sCDomin $ "ZF_CADVITI/ZF_PRODUTO/ZF_DESCRI/ZF_IDSZ9/ZF_CADCPO/ZF_CONDUC"
	case _sCampo $ "M->ZF_CADVITI" .and. _sCDomin $ "ZF_CADVITI/ZF_PRODUTO/ZF_DESCRI/ZF_CADCPO/ZF_CONDUC"
		_xRet = GDFieldGet (_sCDomin)  // Se nao encontrar nada, deixa o valor pronto para retorno.
		if GDFieldGet ("ZF_ITEMVIT") > 0 .and. GDFieldGet ("ZF_ITEMVIT") <= len (_aCadVitic)
			if _sCDomin == "ZF_CADVITI"
				_xRet = _aCadVitic [GDFieldGet ("ZF_ITEMVIT"), .CadVitCodigo]
			elseif _sCDomin == "ZF_PRODUTO"
				_xRet = _aCadVitic [GDFieldGet ("ZF_ITEMVIT"), .CadVitProduto]
			elseif _sCDomin == "ZF_DESCRI"
				_xRet = _aCadVitic [GDFieldGet ("ZF_ITEMVIT"), .CadVitDescPro]
			elseif _sCDomin == "ZF_CONDUC"
				_xRet = _aCadVitic [GDFieldGet ("ZF_ITEMVIT"), .CadVitSistCond]
			endif
		endif


	case _sCampo $ "M->ZF_GRAU" .and. _sCDomin $ "ZF_PRM02"
		_xRet = GDFieldGet (_sCDomin)  // Se nao encontrar nada, deixa o valor pronto para retorno.
		if m->ze_safra == '2019'
			_xRet = U_ClUva19 (GDFieldGet ("ZF_PRODUTO"), val (m->zf_grau), GDFieldGet ("ZF_CONDUC"), 0, 0, 0, 0, 0, '', 0) [1]
		elseif m->ze_safra == '2020'
			_xRet = U_ClUva20 (GDFieldGet ("ZF_PRODUTO"), val (m->zf_grau), GDFieldGet ("ZF_CONDUC"), 0, 0, 0, 0, 0) [1]
		else
			u_help ("Sem tratamento para gerar o campo '" + _sCDomin + "' para esta safra.",, .T.)
		endif



	case _sCampo $ "M->ZF_GRAU" .and. _sCDomin $ "ZF_PRM99"
		_xRet = GDFieldGet (_sCDomin)  // Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = U_ClassUva (GDFieldGet ("ZF_CONDUC"), GDFieldGet ("ZF_PRM02"), GDFieldGet ("ZF_PRM03"), GDFieldGet ("ZF_PRM04"), GDFieldGet ("ZF_PRM05"))



	case (_sCampo == "M->ZW_QTMESES" .or. _sCampo == "M->ZW_INIPREV" .or. _sCampo == "M->ZW_INIHIST") .and. _sCDomin $ "ZW_FIMHIST/ZW_FIMPREV"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = ctod ("")
	
		if _sCDomin == "ZW_FIMHIST" .and. ! empty (m->zw_inihist) .and. m->zw_qtmeses > 0
			_oDUtil := ClsDUtil():New ()
			_xRet = lastday (stod (_oDUtil:SomaMes (left (dtos (m->zw_inihist), 6), m->zw_qtmeses - 1) + "01"))
		endif
		if _sCDomin == "ZW_FIMPREV" .and. ! empty (m->zw_iniprev) .and. m->zw_qtmeses > 0
			_oDUtil := ClsDUtil():New ()
			_xRet = lastday (stod (_oDUtil:SomaMes (left (dtos (m->zw_iniprev), 6), m->zw_qtmeses - 1) + "01"))
		endif



	case _sCampo == "M->ZZ5_CODLOJ" .and. _sCDomin == "ZZ5_SEQ"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = 0
	
		_sQuery := ""
		_sQuery += " select max (ZZ5_SEQ)"
		_sQuery +=   " from " + RetSQLName ("ZZ5") + " ZZ5 "
		_sQuery +=  " where ZZ5.D_E_L_E_T_ = ''"
		_sQuery +=    " and ZZ5.ZZ5_FILIAL = '" + xfilial ("ZZ5") + "'"
		_sQuery +=    " and ZZ5.ZZ5_DTSOLI = '" + dtos (m->ZZ5_DTSOLI) + "'"
		_sQuery +=    " and ZZ5.ZZ5_CODLOJ = '" + M->ZZ5_CODLOJ + "'"
		_xRet = U_RetSQL (_sQuery)
		if empty (_xRet)
			_xRet = strzero (0, tamsx3 ("ZZ5_SEQ")[1])
		endif
		_xRet = Soma1 (_xRet)



	case _sCampo $ "M->ZZ7_CONTAT/M->ZZ7_DATA" .and. _sCDomin == "ZZ7_SEQ"
		// Se nao encontrar nada, deixa o valor pronto para retorno.
		_xRet = 0
	
		_sQuery := ""
		_sQuery += " select max (ZZ7_SEQ)"
		_sQuery +=   " from " + RetSQLName ("ZZ7") + " ZZ7 "
		_sQuery +=  " where ZZ7.D_E_L_E_T_ = ''"
		_sQuery +=    " and ZZ7.ZZ7_FILIAL = '" + xfilial ("ZZ7") + "'"
		_sQuery +=    " and ZZ7.ZZ7_CONTAT = '" + M->ZZ7_CONTAT + "'"
		_sQuery +=    " and ZZ7.ZZ7_DATA   = '" + dtos (M->ZZ7_DATA) + "'"
		_xRet = U_RetSQL (_sQuery)
		if empty (_xRet)
			_xRet = strzero (0, tamsx3 ("ZZ7_SEQ")[1])
		endif
		_xRet = Soma1 (_xRet)



	case _sCampo == "M->ZZT_MOTIVO" .and. _sCDomin == "ZZT_CARGA"
		_xRet = ""
		if m->zzt_motivo == '4'
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select DISTINCT CARGA, PLACA, NOME_ASSOC, DESCRICAO "
			_oSQL:_sQuery +=   " from dbo.VA_VFILA_DESCARGA_SAFRA V"
			_oSQL:_sQuery +=  " where V.SAFRA  = '" + m->zzt_safra + "'"
			_oSQL:_sQuery +=    " and V.FILIAL = '" + xfilial ("ZZT") + "'"
			_oSQL:_sQuery +=    " and SUBSTRING (V.STATUS, 1, 1) = '1'"
			_oSQL:_sQuery +=    " order by CARGA"
			_aRetSQL := aclone (_oSQL:Qry2Array ())
			if len (_aRetSQL) > 0
				_xRet = _aRetSQL [_oSQL:F3Array (), 1]
			endif
		endif



	case _sCampo $ "M->ZZT_QPCISP/M->ZZT_QTPBR/M->ZZT_QCHTEX/M->ZZT_PESONF/M->ZZT_PESENT/M->ZZT_PESSAI" .and. _sCDomin $ "ZZT_QPCISP/ZZT_QTPBR/ZZT_QCHTEX/ZZT_PESONF/ZZT_PESENT/ZZT_PESSAI/ZZT_PESLIQ"
		_xRet = &(readvar ())
	
		// Campos atualizados via programa: a funcao readvar() retorna o nome de algum outro campo onde o cursor estah posicionado, e isso nao me serve para nada.
		if _sCDomin == 'ZZT_PESONF'
			_xRet = m->zzt_pesonf
		elseif _sCDomin == 'ZZT_PESENT'
			_xRet = m->zzt_pesent
		elseif _sCDomin == 'ZZT_PESSAI'
			_xRet = m->zzt_pessai
		else
			_xRet = &(readvar ())
		endif
		m->zzt_pespal = 0
		m->zzt_pespal += m->zzt_qpcisp * 18
		m->zzt_pespal += m->zzt_qtpbr * 25
		m->zzt_pespal += m->zzt_qchtex * 4.158
		m->zzt_pesliq = iif(m->zzt_pesent==0 .or. m->zzt_pessai==0, 0, abs (m->zzt_pesent - m->zzt_pessai) - m->zzt_pespal)
		m->zzt_difpes = m->zzt_pesliq - m->zzt_pesoNF
		m->zzt_pdifpe = m->zzt_difpes / m->zzt_pesliq * 100
		if abs (m->zzt_pdifpe) > 3
			m->zzt_blqpes = 'B'
		endif
	
	case _sCampo == "M->C6_PRCVEN" .and. _sCDomin == "C6_PRCVEN"
		_xRet = GDFieldGet ("C6_PRCVEN")

//	//Validação de alteração para ompatibilidade com sistema Mercanet
//	if SC5->C5_VAPDMER <> ""  
//		if _sCampo = 'M->C6_PRCVEN'
//			alert("O valor unitário não pode ser alterado em função da integração com o software Mercanet.")
//			_xRet = 0 
//		endif
//	endif
	/*
	case _sCampo == "M->LR_PRODUTO" .and. _sCDomin == "TABELA" 
		_wtipocli = fBuscaCpo("SA1",1,xFilial("SA1") + M->LQ_CLIENTE + M->LQ_LOJA, "A1_LOJAS" )
		u_help("PASSOU PELO GATILHO - PELO L2_PRODUTO RETORNANDO L2_TABELA")
		do case
			case _wtipocli = 'A' // associados
			 	_xRet = '3'
			case _wtipocli = 'F' // funcionarios
				_xRet = '3'
		otherwise
			_xRet = '1'
				
		endcase
		u_help(_xRet)
	
	case _sCampo == "M->L2_PRODUTO" .and. _sCDomin == "L2_VRUNIT" 
		_xRet    := 0
		_wpreco  := 'B0_PRV1'
		_wtipocli = fBuscaCpo("SA1",1,xFilial("SA1") + M->LQ_CLIENTE + M->LQ_LOJA, "A1_LOJAS" )
		u_help("PASSOU PELO GATILHO - PELO L2_PRODUTO - RETORNANDO O L2_VRUNIT")
		do case
			case _wtipocli = 'A' // associados
			 	_wpreco = 'B0_PRV3'
			case _wtipocli = 'F' // funcionarios
				_wpreco = 'B0_PRV3'
		endcase
		_xRet    = fBuscaCpo("SB0",1,xFilial("SB0") + M->L2_PRODUTO, _wpreco )
		u_help(_xRet)	
		
	case _sCampo == "M->L2_PRODUTO" .and. _sCDomin == "L2_PRCTAB" 
		_xRet    := 0
		_wpreco  := 'B0_PRV1'
		_wtipocli = fBuscaCpo("SA1",1,xFilial("SA1") + M->LQ_CLIENTE + M->LQ_LOJA, "A1_LOJAS" )
		u_help("PASSOU PELO GATILHO - PELO L2_PRODUTO - RETORNANDO O L2_PRCTAB")
		do case
			case _wtipocli = 'A' // associados
			 	_wpreco = 'B0_PRV3'
			case _wtipocli = 'F' // funcionarios
				_wpreco = 'B0_PRV3'
		endcase
		_xRet    = fBuscaCpo("SB0",1,xFilial("SB0") + M->L2_PRODUTO, _wpreco )
		u_help(_xRet)
    */	
	otherwise

	// Se o gatilho foi chamado a partir de um campo nao previsto, verifica o contra-dominio do
	// gatilho no SX7 e retorna o valor original que estava nesse campo (seria como se o
	// gatilho nao tivesse sido executado).
	if ! empty (_sCampo)
		U_Log ("Campo '" + _sCampo + "' nao previsto na rotina " + procname () + " --> Contra dominio: '" + _sCDomin + "'  --> sequencia: " + _sParSeq)
		// Incluir aqui a geracao de um aviso no ZAB
	endif
	if type ("aHeader") == "A" .and. type ("aCols") == "A" .and. type ("N") == "N"
		if GDFieldPos (sx7 -> x7_cdomin) > 0
			_xRet = GDFieldGet (sx7 -> x7_cdomin)
		endif
	elseif type ("M->" + _sCDomin) != "U"
		_xRet = &("M->" + _sCDomin)
	endif

endcase
//CursorArrow ()

U_SalvaAmb (_aAmbAnt)
U_ML_SRArea (_aAreaAnt)

return _xRet
