// Programa..: M410LIOK
// Autor.....: Jeferson Rech
// Data......: 06/2003
// Descricao.: P.E. Validacao Linhas do Pedido de Venda
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida linha OK do pedido de venda.
// #PalavasChave      #validacao #Linha_OK #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT
//
// Historico de alteracoes:
// 10/04/2008 - Robert  - Comentariadas variaveis sem uso (_xEsp2 e 3, _xVol2 e 3)
// 02/07/2008 - Robert  - Alterada validacao do PVCond.
// 17/07/2008 - Robert  - Soh valida quando inclusao ou alteracao.
// 06/10/2008 - Robert  - Validacoes para controle de armazem geral (em outras UF)
// 21/11/2008 - Robert  - Validacoes de TES e tipo de cliente para estados com recolhimento de ST.
// 04/12/2008 - Robert  - Soh valida de TES e tipo de cliente para estados com recolhimento de ST e inscr. estadual.
// 20/01/2009 - Robert  - Validacao dos 3 ultimos digitos do CFO com o cadastro do TES.
// 09/03/2009 - Robert  - Novos parametros na funcao SaldoAmG.
// 17/04/2009 - Robert  - Valida TES de venda para entrega pelo Tumelero para um cliente de fora do estado.
// 25/06/2009 - Robert  - Nao permite informar litragem para DCO quando o TES nao gera faturamento.
// 01/07/2009 - Robert  - Verificacao de subst.trib. nao verifica mais se tem regime especial. Agora calcula a ST pelo produto.
// 22/07/2009 - Robert  - Passa a usar a funcao U_Help para as mensagens.
// 24/08/2009 - Robert  - Verificacao de ST nao considerava transferencia entre filiais.
// 31/08/2009 - Robert  - Novos parametros funcao de calculo da ST.
// 03/09/2009 - Robert  - Validacao campo C6_vaCliOr.
//                      - Compatibilizacao com base DBF para uso em Livramento.
// 08/10/2009 - Robert  - Funcao de calculo do peso e volumes nao era executada quando a linha estava deletada.
// 14/10/2009 - Robert  - Verificacao de ST: nao chama mais rot. de calculo: campos jah presentes no SC6.
// 22/10/2009 - Robert  - Passa a usar tabela 03 do ZX5 em lugar da tebeta 77 do SX5.
// 16/12/2009 - Robert  - Funcao VldProAti desabilitada (passada para VA_VCpo).
// 03/05/2010 - Robert  - Tratamento para campo C5_vaAltVP
// 15/10/2010 - Robert  - Tratamento para campo C5_vaTotST
// 16/11/2010 - Robert  - Ignora alguns testes quando chamado pela rotina de retorno simbolico do deposito para a matriz.
// 15/12/2010 - Robert  - Criado tratamento para campo ZX5_MODO.
// 28/10/2011 - Robert  - Criado tratamento para campo C6_VAPRCVE.
// 06/12/2011 - Robert  - Verifica TES X prouto com/sem IPI.
// 16/12/2011 - Robert  - Verifica produtos que usam controle de localizacao.
// 27/05/2014 - Claudia DWT - Adicionado desconto em cascata - Desconto em da linha + desconto quando frete FOB + 
//						  desconto Condição à vista.
// 02/12/2014 - Robert  - Criada validacao de almox. de inter]gracao com Fullsoft.
// 27/01/2015 - Robert  - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 14/04/2015 - Robert  - Desabilitados calculos de ST no ambiente TESTE.
// 10/07/2015 - Robert  - Desabilitada validacao de CFOP do TES X CFOP do pedido quando nao for consumidor final.
// 12/09/2015 - Robert  - Removidos tratamentos (jah desabilitados) de ST customizada.
// 14/09/2015 - Robert  - Desabilitado teste do parametro VA_TESVTUM (nao utilizamos mais vendas via Tumelero).
// 02/12/2015 - Robert  - Tratamento para IPI por aliquota e por valor absoluto.
// 04/08/2016 - Robert  - Desabilitados testes com campos C6_VACLIOR e C6_VALOJOR.
// 15/08/2016 - Robert  - Permite uso do almox.11 (integr.FullWMS) quando trata-se de devolucao.
// 22/11/2016 - ProcData (Suelen) - Validação de exclusão/alteração para compatibilidade com sistema Mercanet. 
// 12/12/2016 - Robert  - Ajuste validacoes Mercanet.
// 06/02/2017 - Robert  - Valida comissao estatica ou dinamica no representante.
// 21/02/2017 - Robert  - Valida comissao estatica pela tabela ZAV (linha / produto).
// 29/05/2017 - Catia   - Validar se o cliente obriga OC - S/N
// 04/09/2017 - Robert  - Desconsidera itens com residuo eliminado no calculo do peso e volumes.
// 09/09/2017 - Robert  - Passa a calcular pesos e volumes pelos campos C6_VAPBRU, C6_VAPLIQ e C6_VAQTVOL.
// 14/09/2017 - Robert  - Considerava apenas C6_BLQ = 'R'
// 29/09/2017 - Catia   - Validar C6_NUMPCOM e C6_ITEMPC - se no cliente o campo A1_VAOC = 1 // Obriga OC =SIM
// 26/02/2018 - Robert  - Aceita pos.IPI 22021000 calculando IPI.
// 07/03/2018 - Robert  - Ajustes validacao pos.IPI 22021000 calculando IPI.
// 15/08/2018 - Robert  - Validacao almox. integracao FullWMS: acrescentado tratamento para alm.22
// 07/12/2018 - Robert  - Valida campo C6_VAOPER.
// 13/12/2018 - Robert  - TES deve ser o mesmo do contrato de parceria.
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
// 28/07/2020 - Robert  - Acrescentado parametro .T. nas chamadas da funcao U_Help quando mensagens de erro.
//                      - Inseridas tags para catalogacao de fontes
// 10/08/2020 - Cláudia - Não permitir a inclusão de pedidos com problemas de TES que calcula IPI pelo 
//						  processo manual do BatMercP. GLPI: 8284
// 18/06/2021 - Sandra  - Desabilitado linha /M->C5_ESPECI1 := 'VOLUMES', para notas de exportação GLPI 10196
// 02/12/2021 - Claudia - Desabilitada a validação de motivo de bonificação. GLPI: 10580
// 22/03/2022 - Claudia - Criada validações de lote e localização. GLPI: 11590
// 24/03/2022 - Claudia - Validação se item controla ou não estoque. GLPI: 11802
//
// ----------------------------------------------------------------------------------------------------------------
User Function M410LIOK()
	local _aAreaAnt  := U_ML_SRArea ()
	local _xTIPO     := M->C5_TIPO
	local _xPEDCLI   := ""
	local _xC5PVCOND := M->C5_PVCOND
	local _xFim      := chr(13)+chr(10)
	local _lRet      := .T.
	local linha		 := .F.

	// Armazena Dados Para Recuperar Depois
	Public _aDadSA1_ := {}

	// Verifica preenchimento do campo C6_VAOPER (alimentado via gatilho do C6_OPER)
	if _lRet
		_lRet = _VerOper ()
	endif

	// Guarda (via gatilho) um 'backup' do preco de venda, quando digitado manualmente, no campo
	// C6_VAPRCVE, para posterior comparativo com o C6_PRCVEN. Isso foi montado por que, apos
	// atualizacao do sistema em out/2011, a validacao padrao do campo C5_CONDPAG passou a recalcular
	// o pedido, o que faz com que os precos sejam relidos na tabela de precos. Como o pessoal
	// jah tem o habito de alterar a condicao de pagamento, insistiram que os precos deveriam
	// ser mantidos. A forma que consegui montar foi esta...
	if _lRet .and. m->c5_tipo == "N" .and. (inclui .or. altera) .and. ! GDDeleted () .and. cNumEmp != '0201'
		if GDFieldGet ("C6_PRCVEN") != GDFieldGet ("C6_VAPRCVE")
			u_help ("Linha " + cvaltochar (N) + ": O preco unitario está diferente do preco digitado. Verifique!")
			_lRet = .T.
			linha:=.T.
		endif
	endif

	if _lRet .and. (inclui .or. altera)

		// Parametro Flag que identifica se Deve Fazer Tratamento Banco / Vendedor
		If GetNewPar("ML_ATUCLNF","S") == "S"
			If !(M->C5_TIPO $ "B/D")
				DbSelectArea("SA1")
				DbSetOrder(1)
				If MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
					Aadd (_aDadSA1_, {M->C5_CLIENTE,M->C5_LOJACLI,SA1->A1_BCO1,SA1->A1_VEND})
				Endif
			Endif
		Endif

		If !(M->C5_TIPO $ "B/D")
			DbSelectArea("SA1")
			DbSetOrder(1)
			If MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI)
				_xCLIENTE := SA1->A1_COD
				_xLOJA    := SA1->A1_LOJA
				_xRISCO   := SA1->A1_RISCO
				_xNOME    := SA1->A1_NOME
				If _xRISCO == "F"
					U_Help ("Cliente: "+_xCLIENTE+" "+_xLOJA+" "+Trim(_xNOME)+_xFim+;
					"Possui Risco financeiro "+_xRISCO+", portando nao sera permitido digitacao de Venda."+_xFim+;
					"Solucao: "+"Contate Setor Financeiro.",, .t.)
					_lRet      := .F.
					linha:=.T.
				Endif
			Endif
		Endif

		_xOC := fbuscacpo ("SA1", 1, xfilial ("SA1") + M->C5_CLIENTE + M->C5_LOJACLI, "A1_VAOC")
		// Valida se a Linha Nao estiver deletada
		If !GDDeleted( n )
			_xPEDCLI  := GDFieldGet( "C6_PEDCLI"  , n )
			_xTES     := GDFieldGet( "C6_TES"     , n )
			_xCF      := GDFieldGet( "C6_CF"      , n )
			_xBONIFIC := GDFieldGet( "C6_BONIFIC" , n )
			_xC6PVCOND:= GDFieldGet( "C6_PVCOND"  , n )
			_xNUMPCOM := GDFieldGet( "C6_NUMPCOM" , n )
			_xITEMPC  := GDFieldGet( "C6_ITEMPC" , n )
			
			// Verifica se esta preenchido o Pedido do Cliente x campo obriga OC no cliente
			If (_xOC=='1' .and. _xTIPO=='N' .And. Empty(_xPEDCLI))
				U_Help("Obrigatorio a informacao do Numero do Pedido do Cliente.",, .t.)
				_lRet := .F.
				linha:=.T.
			Endif
			
			// Verifica se esta preenchido o Numero da OC x campo obriga OC no cliente
			If (_xOC=='1' .and. _xTIPO=='N' .And. Empty(_xNUMPCOM))
				U_Help("Cliente obriga O.C. no XML. Informar o campo Num.Ped.Com (C6_NUMPCOM)",, .t.)
				_lRet := .F.
				linha:=.T.
			Endif
			
			// Verifica se esta preenchido o Numero da OC x campo obriga OC no cliente
			If (_xOC=='1' .and. _xTIPO=='N' .And. Empty(_xITEMPC))
				U_Help("Cliente obriga O.C. no XML. Informar o campo Item.Ped.Com (C6_ITEMPC)",, .t.)
				_lRet := .F.
				linha:=.T.
			Endif
			
			If _xc5pvcond == "S" .AND. _XC6PVCOND < GDFieldGet ("C6_PRCVEN")
				U_Help("PVCOND"+_xFim+"PV Condicao nao pode ser menor que Prc Unitario.",, .t.)
				_lRet := .F.
				linha:=.T.
			Endif

			// Verifica o TES
			DbSelectArea("SF4")
			DbSetOrder(1)
			DbSeek(xFilial("SF4")+_xTES,.F.)
			If Found()
				_xSF4CF   := SF4->F4_CF
				_XSF4BON  := SF4->F4_MARGEM
			Else
				_xSF4CF   := ""
				_XSF4BON  := ""
			Endif

			// IF _xSF4BON  == "3"   // BONIFICACAO
			// 	// Verifica o se foi informado o tipo de bonificacao
			// 	U_Help(" Informe  o tipo de bonificação.",, .t.)
			// 	_lRet := .F.
			// 	linha:=.T.
			// Endif
		Endif
	endif

	// Calcula peso total do pedido.
	_PesoPed()

	// Verificacoes para NF original
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("C6_NFORI")) .and. ! IsInCallStack ("U_VA_GPDM")
		_lRet = _VerNfOri ()
	endif

	// Verifica venda para entrega futura.
	if _lRet
		_lRet = _VerVEF ()
	endif

	// Validacoes gerais TES.
	if _lRet .and. ! GDDeleted () .and. cEmpAnt != "02" .and. ! IsInCallStack ("U_VA_GPDM")
		_lRet = _VerTES ()
	endif

	// Verifica integracao com Fullsoft
	if _lRet
		_lRet = _VerFull ()
	endif

	// Verifica integracao com Mercanet
	if _lRet
		_lRet = _VerMerc ()
	endif

	// Verifica comissao.
	if _lRet
		_lRet = _VerComis ()
	endif

	// Verifica tabela de precos
	if _lRet
		_lRet = _VerTbPrc ()
	endif

	// Quando item controla rastreabilidade, exigir lote e endereço 
	If _lRet
		_sProduto   := GDFieldGet("C6_PRODUTO")
		_sLote      := GDFieldGet("C6_LOTECTL")
		_sLocaliz   := GDFieldGet("C6_LOCALIZ")
		_sTES       := GDFieldGet("C6_TES")
		_sCtrEstoq  := Posicione("SF4",1 ,xFilial("SF4") + alltrim(_sTES),"F4_ESTOQUE")
		_sCtrRastro := Posicione("SB1",1 ,xFilial("SB1") + _sProduto,"B1_RASTRO")
		_sCtrLocal  := Posicione("SB1",1 ,xFilial("SB1") + _sProduto,"B1_LOCALIZ")

		If _sCtrEstoq == 'S' // controla estoque
			// exige lote
			If _sCtrRastro == 'L' .and. empty(_sLote)
				_lRet := .F.
				u_help("Informar lote!")
			EndIf

			// exigir localização
			If _sCtrLocal == 'S' .and. empty(_sLocaliz)
				_lRet := .F.
				u_help("Informar localização!")
			EndIf
		EndIf
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return _lRet
//
// --------------------------------------------------------------------------
// Funcao que Processa o Peso do Pedido
Static Function _PesoPed()
	Local _xTot_PBRT := 0
	Local _xTot_PLIQ := 0
	Local nLinha    := 0
	Local _xQVOL1   := 0

	_xTot_PBRT := _xTot_PLIQ := _xQVOL1 := 0
	For nLinha := 1 to Len(aCols)
		if ! GDDeleted (nLinha) .and. ! alltrim (GDFieldGet ("C6_BLQ", nLinha)) $ 'R/S'
			_xTot_PBRT += GDFieldGet ("C6_VAPBRU", nLinha)
			_xTot_PLIQ += GDFieldGet ("C6_VAPLIQ", nLinha)
			_xQVOL1    += GDFieldGet ("C6_VAQTVOL", nLinha)
		endif
	Next
	M->C5_VOLUME1 := _XQVOL1
	//M->C5_ESPECI1 := 'VOLUMES'
	M->C5_PBRUTO  := _xTOT_PBRT
	M->C5_PESOL   := _xTOT_PLIQ

	GETDREFRESH() // ATUALIZA OS CAMPOS DE MEMORIA

Return
//
// --------------------------------------------------------------------------
// Verificacoes para NF original.
static function _VerNFOri ()
	local _lRet    := .T.

	// Complemento de IPI sobre vendas com cupom fiscal.
	if _lRet .and. ! GDDeleted () .and. m->c5_tipo == "P" .and. alltrim (GDFieldGet ("C6_TES")) == "541"
		if empty (GDFieldGet ("C6_VACLIOR")) .or. empty (GDFieldGet ("C6_VALOJOR"))
			u_help ("Para notas de complemento de IPI sobre vendas com cupom fiscal devem ser informados os campos '" + alltrim (RetTitle ("C6_VACLIOR")) + " e '" + alltrim (RetTitle ("C6_VALOJOR")) + "'.",, .t.)
			_lRet = .F.
		endif
	endif

	// Transferencia de credito de ICMS.
	if _lRet .and. ! GDDeleted () .and. m->c5_tipo == "I" .and. alltrim (GDFieldGet ("C6_CF")) == "5602"
		if empty (GDFieldGet ("C6_VACLIOR")) .or. empty (GDFieldGet ("C6_VALOJOR"))
			u_help ("Para notas de transferencia de credito de ICMS devem ser informados os campos '" + alltrim (RetTitle ("C6_VACLIOR")) + " e '" + alltrim (RetTitle ("C6_VALOJOR")) + "'.",, .t.)
			_lRet = .F.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes de venda para entrega futura (deve ter contrato e o TES deve ser igual)
static function _VerVEF ()
	local _lRet     := .T.
	local _sContrat := ""

	// Se usar nat.opr. de venda/remessa futura, deve ter contrato.
	if _lRet .and. ! GDDeleted () .and. substr (GDFieldGet ("C6_CF"), 2, 3) $ '922/116'
		if GDFieldPos ("C6_CONTRAT") == 0 .or. GDFieldPos ("C6_ITEMCON") == 0
			u_help ("Campos " + alltrim (RetTitle ("C6_CONTRAT")) + " e " + alltrim (RetTitle ("C6_ITEMCON")) + " referentes a contrato de parceria devem estar 'em uso' para validar operacoes de venda para entrega futura.",, .t.)
			_lRet = .F.
		endif
		if inclui
			_sContrat = GDFieldGet ("C6_CONTRAT")
		elseif altera
			_sContrat = fBuscaCpo ("SC6", 1, xfilial ("SC6") + m->c5_num + GDFieldGet ("C6_ITEM") + GDFieldGet ("C6_PRODUTO"), "C6_CONTRAT")
		endif
		if empty (_sContrat)
			u_help ("Venda / remessa de entrega futura: pedido deve ser gerado a partir de um contrato de parceria do CRM.",, .t.)
			_lRet = .F.
		endif
	endif
	
	// TES deve ser o mesmo do contrato
	if _lRet .and. altera .and. ! empty (GDFieldGet ("C6_CONTRAT"))
		if GDFieldGet ('C6_TES') != fBuscaCpo ("ADB", 1, xfilial ("ADB") + GDFieldGet ("C6_CONTRAT") + GDFieldGet ("C6_ITEMCON"), "ADB_TES")
			U_Help ("Pedido originado por contrato de parceria. Alteracao de TES nao permitida.",, .t.)
			_lRet = .F.
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes gerais TES.
static function _VerTES ()
	local _lRet    := .T.
	local _sMsg    := ""

	sb1 -> (dbsetorder (1))
	if sb1 -> (DbSeek (xFilial ("SB1") + GDFieldGet ("C6_PRODUTO"), .F.))
		sf4 -> (dbsetorder (1))
		if sf4 -> (DbSeek (xFilial ("SF4") + GDFieldGet ("C6_TES"), .F.))
			If SubStr(SB1->B1_POSIPI,1,4) $ "2204/2206/2207/2208" .and. sf4 -> f4_ipi != 'S' .and. ! substr (GDFieldGet ("C6_CF"), 2, 3) $ "901/151/905/906"
				_sMsg = "TES deveria calcular IPI para este produto."
				if type ("oMainWnd") == "O"  // Se tem interface com o usuario
					_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				else
					u_help (_sMsg,, .t.)
					_lRet = .F.
				endif
			endif
			If ((sb1 -> B1_VLR_IPI == 0 .and. sb1 -> b1_ipi == 0) .or. (! SubStr(SB1->B1_POSIPI,1,4) $ "2204/2206/2207/2208" .and. ! SubStr(SB1->B1_POSIPI,1,8) $ "22021000")) .and. sf4 -> f4_ipi == 'S'
				if IsInCallStack ("U_BATMERCP") // na importação por bat não permitir importação
					_sMsg = "TES nao deveria calcular IPI para este produto, ou o IPI esta informado incorretamente no produto. Pedido não será importado"
					u_help (_sMsg,, .t.)
					_lRet = .F.
				else
					_sMsg = "TES nao deveria calcular IPI para este produto, ou o IPI esta informado incorretamente no produto."
					if type ("oMainWnd") == "O"  // Se tem interface com o usuario
						_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					else
						if !IsInCallStack ("U_BATMERC")  // Para nao bloquear a integracao com Mercanet.
							u_help (_sMsg,, .t.)
							_lRet = .F.
						endif
					endif
				endif
			endif
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificacoes integracao com Fullsoft.
static function _VerFull ()
	local _lRet     := .T.
	local _sMsg     := ""

	if ! GDDeleted () .and. GDFieldGet ("C6_LOCAL") $ U_AlmFull (NIL, 'TODOS')
		_sMsg = "Almoxarifado '" + GDFieldGet ("C6_LOCAL") + "' destina-se exclusivamente a integracao de dados com Fullsoft e nao deve ser usado para faturamento."
		u_help (_sMsg,, .t.)
		_lRet = .F.
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Validação de exclusão/alteração para compatibilidade com sistema Mercanet.
static function _VerMerc ()
	local _lRet := .T.

	if _lRet .and. ! empty (M->C5_VAPDMER) .and. GDDeleted () .and. ! empty (GDFieldGet ("C6_VAITPME"))
		U_Help ("Pedido importado do sistema Mercanet. Itens nao podem ser excluidos. Caso necessario, utilize rotina de 'eliminacao de residuos'.",, .t.)
		_lRet = .F.
	endif
	
	if _lRet .and. ! empty (M->C5_VAPDMER) .and. ! GDDeleted () .and. empty (GDFieldGet ("C6_VAITPME"))
		U_Help ("Pedido importado do sistema Mercanet. Inclusao de itens nao permitida.",, .t.)
		_lRet = .F.
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Validacao da comissao.
static function _VerComis ()
	local _lRet     := .T.
	local _lTemZAV  := .F.
	local _sLinProd := ""

	if _lRet .and. ! GDDeleted ()
		sa3 -> (dbsetorder (1))
		if sa3 -> (dbseek (xfilial ("SA3") + m->c5_vend1, .F.))

			// Verifica antes no arquivo de comissoes por linha / produto.
			zav -> (dbsetorder (2))  // ZAV_FILIAL+ZAV_VEND +ZAV_ITEM
			if zav -> (dbseek (xfilial ("ZAV") + m->c5_vend1 + GDFieldGet ("C6_PRODUTO"), .F.))
				_lTemZAV = .T.
				if sa3 -> a3_vaTpCom == 'E' .and. GDFieldGet ("C6_COMIS1") != zav -> zav_pcom
					u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao estatica de " + cvaltochar (zav -> zav_pcom) + "% para o produto '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "'.",, .t.)
					_lRet = .F.
				elseif sa3 -> a3_vaTpCom == 'D' .and. GDFieldGet ("C6_COMIS1") > zav -> zav_pcom
					u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao dinamica limitada a " + cvaltochar (zav -> zav_pcom) + "% para o produto '" + alltrim (GDFieldGet ("C6_PRODUTO")) + "'.",, .t.)
					_lRet = .F.
				endif
			else
				_sLinProd = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C6_PRODUTO"), 'B1_CLINF')
				if ! empty (_sLinProd)
					zav -> (dbsetorder (1))  // ZAV_FILIAL+ZAV_VEND +ZAV_LINHA
					if zav -> (dbseek (xfilial ("ZAV") + m->c5_vend1 + _sLinProd, .F.))
						_lTemZAV = .T.
						if sa3 -> a3_vaTpCom == 'E' .and. GDFieldGet ("C6_COMIS1") != zav -> zav_pcom
							u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao estatica de " + cvaltochar (zav -> zav_pcom) + "% para a linha de produtos '" + _sLinProd + "' (" + alltrim (fBuscaCpo ("ZAZ", 1, xfilial ("ZAZ") + _sLinProd, "ZAZ_NLINF")) + ").",, .t.)
							_lRet = .F.
						elseif sa3 -> a3_vaTpCom == 'D' .and. GDFieldGet ("C6_COMIS1") > zav -> zav_pcom
							u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao dinamica limitada a " + cvaltochar (zav -> zav_pcom) + "% para a linha de produtos '" + _sLinProd + "' (" + alltrim (fBuscaCpo ("ZAZ", 1, xfilial ("ZAZ") + _sLinProd, "ZAZ_NLINF")) + ").",, .t.)
							_lRet = .F.
						endif
					endif
				endif
			endif
			
			// Se nao tinha nada especifico por linha / produto que tenha 'dado na trave'...
			if _lRet .and. ! _lTemZAV
				if sa3 -> a3_vaTpCom == 'E' .and. GDFieldGet ("C6_COMIS1") != sa3 -> a3_comis
					u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao estatica de " + cvaltochar (sa3 -> a3_comis) + "%",, .t.)
					_lRet = .F.
				elseif sa3 -> a3_vaTpCom == 'D' .and. GDFieldGet ("C6_COMIS1") > sa3 -> a3_comis
					u_help ("Repres. '" + alltrim (sa3 -> a3_cod) + "' tem comissao dinamica limitada a " + cvaltochar (sa3 -> a3_comis) + "%",, .t.)
					_lRet = .F.
				endif
			endif
		endif
	endif 
return _lRet
//
// --------------------------------------------------------------------------
// Validacao de tabela de precos tipo 'estatica'
static function _VerTbPrc ()
	local _lRet    := .T.
	local _oSQL    := NIL

	if _lRet .and. ! empty (m->c5_tabela) .and. ! GDDeleted ()
		if fBuscaCpo ("DA0", 1, xfilial ("DA0") + m->c5_tabela, "DA0_VAESDI") == "E"
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT TOP 1 DA1_PRCVEN"
			_oSQL:_sQuery += " FROM "  + RetSQLName ("DA1")
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " AND DA1_FILIAL = '" + xfilial ("DA1") + "'"
			_oSQL:_sQuery += " AND DA1_CODTAB = '" + m->c5_tabela + "'"
			_oSQL:_sQuery += " AND DA1_CODPRO = '" + GDFieldGet ("C6_PRODUTO") + "'"
			_oSQL:_sQuery += " AND (DA1_ESTADO = '" + m->c5_vaest + "' OR DA1_ESTADO = '  ')"
			_oSQL:Log ()
			_nPrcTab = _oSQL:RetQry ()
			if GDFieldGet ("C6_PRCVEN") != _nPrcTab
				u_help ("Tabela de precos '" + m->c5_tabela + "' marcada como estatica. Preco deve ser igual ($" + cvaltochar (_nPrcTab) + ")",, .t.)
				_lRet = .F.
			endif
		endif
	endif 
return _lRet
//
// --------------------------------------------------------------------------
// Verificacao preenchimento campo C6_VAOPER.
static function _VerOper ()
	local _lRet     := .T.

	if ! GDDeleted () .and. empty (GDFieldGet ("C6_VAOPER")) .and. GDFieldGet ("C6_TES") $ "630/657"
		u_help ("Para TES de baixa de estoques, deve ser informada a operacao (campos " + alltrim (RetTitle ("C6_OPER")) + " e " + alltrim (RetTitle ("C6_VAOPER")) + ")",, .t.)
		_lRet = .F.
	endif
return _lRet

