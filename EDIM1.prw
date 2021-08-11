// Programa...: EDIM1
// Autor......: Robert Koch
// Data.......: 21/08/2008 (inicio)
// Descricao..: Recepcao de arquivo de pedidos de venda via EDI e geracao de pedidos.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #EDI #integracao
// #Descricao         #Recepcao de arquivo de pedidos de venda via EDI e geracao de pedidos.
// #PalavasChave      #pedido_de_venda #EDI #geracao_de_pedidos 
// #TabelasPrincipais #SM0 #ZZS #SC5 #SC6 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 15/06/2009 - Robert  - Envio de mensagens por e-mail quando executado via batch.
//                      - Passa a usar o campo de preco unitario bruto para informar no C6_PRCVEN.
// 23/07/2009 - Robert  - Passa a aceitar tipo de embalagem '' (vazio).
// 18/08/2009 - Robert  - Criado parametro para TES de venda com ST dentro do RS.
// 31/08/2009 - Robert  - Novos parametros funcao de calculo da ST.
// 14/10/2009 - Robert  - Novos parametros funcao de calculo da ST.
// 28/10/2009 - Robert  - Novo parametro para funcao de calculo da ST.
// 01/03/2010 - Robert  - Envia e-mail com o resultado tambem p/ Franciele.
// 14/07/2010 - Robert  - Busca produtos tambem pelo codigo DUN-14 (caixa).
//                      - Grava msg. com data de entrega no campo C5_MENNOTA.
// 21/09/2010 - Robert  - Nao grava mais o TES no pedido por que foram criados gatilhos para isso.
//                      - Manda aviso ao usuario em caso de pedido bonificado.
// 21/02/2011 - Robert  - Criado tratamento para quando der erro em rotina automatica, mas nao houver arquivo de log gerado.
// 12/05/2011 - Robert  - Melhoradas mensagens de log.
// 19/05/2011 - Robert  - Filtra produtos filhos (avulsos) na pesquisa do SB1 pelo codigo EAN.
// 28/07/2011 - Robert  - Produtos sem preco sao importados 'bloqueados' e gera observacao no pedido.
// 19/12/2011 - Robert  - CNPJ do Makro assume sempre frete CIF.
// 30/12/2012 - Robert  - Filtra determinadas filiais do Makro.
// 01/03/2012 - Robert  - Disponibilizacao da variavel private _sErroEDI para retorno de msg por pontos de entrada posteriores.
// 27/07/2012 - Robert  - Nao preenche mais o campo A1_VAEAN com dados lidos do pedido.
// 21/08/2012 - Robert  - Passa a considerar o campo A1_VAEDING para filtragem de cliente.
// 21/05/2013 - Robert  - Tratamento da variavel _sErroEDI desabilitado, passa a usar _sErroAuto, que jah tem tratamento na funcao U_Help.
// 11/07/2013 - Robert  - Removido bloqueio de filiais do cliente Makro.
// 18/10/2013 - Robert  - Passa a gravar dados na tabela ZZS, quando chamado a partir dessa rotina.
//                      - Passa a enviar notificacoes via rotina U_ZZUNU.
// 07/08/2014 - Robert  - Consiste tipo de pedido (normal/bonif) com campos de quant.normal/bonificada.
// 19/11/2014 - Robert  - Em vez de gravar C6_QTDLIB=0, sugere quantidade liberada no pedido = Nao.
// 03/12/2014 - Robert  - Desconsidera unidade de medida '  ' (modelo 'WMS sul convertido' traz em branco).
// 30/06/2015 - Robert  - Desabilitado campo C5_CALCST (vamos usar ST pelo padrao do sistema).
// 12/09/2015 - Robert  - Removidos tratamentos (jah desabilitados) de ST customizada.
// 18/11/2015 - Robert  - Produtos inativos e bloqueados passam a ser desconsiderados na busca de codigos a partir do cod.barras.
// 01/03/2017 - Robert  - Chamada da funcao ConfirmSXC8() apos o MATA410 para tentar eliminar perda se sequencia de numero de pedidos.
// 14/09/2017 - Robert  - Removido indice 1 (por recno()) dos arquivos de trabalho, pois era desnecessario e dava erro na funcao U_ArqTrb().
// 22/09/2017 - Catia   - alterado para que grave C6_NUMPCOM e o C6_ITEMPC, para geracao da tag XPED
// 26/09/2017 - Robert  - Inserido campo de filler apos o numero da ordem de compra no arquivo _cabec.
// 05/12/2018 - Robert  - Importa como representante 001 quando itens de 'marca propria' (GLPI 4664).
// 10/12/2018 - Robert  - Desabilitado tratamento de marca propria para cliente Cencosud.
// 04/07/2019 - Catia   - tirado o tratamento do campo B1 _ SITUACA
// 30/07/2019 - Andre   - Alterado utilização do campo B1_VADUNCX pelo campo padrão B1_CODBAR.
//					    - Alterado utilização do campo B1_VAEANUN pelo campo padrão B5_2CODBAR.
// 28/10/2019 - Robert  - Passa a validar retorno da funcao U_ArqTrb().
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 10/11/2020 - Robert  - Passa a alimentar o campo C6_VAPOER para gerar TES via gatilhos do TES inteligente (GLPI 8785).
// 11/08/2021 - Claudia - Validação de nome do cliente, conforme GLPI: 10710

// --------------------------------------------------------------------------
User Function EDIM1 (_lAutomat, _sArq, _nRegZZS)
	Local cCadastro   := "Importacao de arquivos EDI padrao Mercador"
	Local aSays       := {}
	Local aButtons    := {}
	Local nOpca       := 0
	Local lPerg       := .F.  // Para controlar se o usuario acessou as perguntas.
	private _sErroZZS := ""
	private cPerg     := "EDIM1_"
	private _lauto    := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	_validPerg()
	Pergunte(cPerg,.F.)

	if empty (_sArq)
		AADD(aSays," ")
		AADD(aSays,"Este programa tem como objetivo importar arquivos EDI no padrao Mercador,")
		AADD(aSays,"gerando pedidos de vendas.")
		AADD(aSays,"")
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _BatchTOK() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			processa ({|| _AndaLogo (_nRegZZS)})
		EndIf
	else
		mv_par01 = _sArq
		processa ({|| _AndaLogo (_nRegZZS)})
	endif
Return
//
// --------------------------------------------------------------------------
// Verifica 'Tudo OK' do FormBatch.
Static Function _BatchTOK ()
	Local _lRet    := .T.
	if ! file (mv_par01)
		u_help ("Arquivo '" + mv_par01 + "' nao encontrado.",, .t.)
		_lRet = .F.
	endif
Return _lRet
//
// --------------------------------------------------------------------------
Static Function _AndaLogo (_nRegZZS)
	local _lContinua   := .T.
	local _aArqTrb     := {}
	local _sSeqPed     := ""
	local _aCpos       := {}
	local _sMsg        := ""
	local _nGerado     := 0
	local _va_eanloc   := GetMv ("VA_EANLOC")
	private _sArqTXT   := alltrim (mv_par01)
	private _aGerados  := {}

	if _lContinua
		_lContinua = _LeArq (@_aArqTrb)
	endif

	if _lContinua
		//_cabec    -> (dbsetorder (2))
		//_pagtos   -> (dbsetorder (2))
		//_descont  -> (dbsetorder (2))
		//_itens    -> (dbsetorder (2))
		//_grade    -> (dbsetorder (2))
		//_crossdoc -> (dbsetorder (2))
		//_sumario  -> (dbsetorder (2))

		// O controle de 'quebra' por pedidos eh feito com base no arquivo de cabecalhos (reg. tipo 01).
		_cabec -> (dbgotop ())
		do while _lContinua .and. ! _cabec -> (eof ())
			_sSeqPed = _cabec -> seqped
			do while _lContinua .and. ! _cabec -> (eof ()) .and. _cabec -> seqped == _sSeqPed
				if _sSeqPed == "000"
					_Erro (_sSeqPed, "Encontrado(s) pedido(s) sem o registro 01 (cabecalho).")
					_lContinua = .F.
					exit
				endif
				if ! _sumario -> (dbseek (_sSeqPed, .F.))
					_Erro (_sSeqPed, "Sequencia de pedido sem registro tipo 'sumario'.")
					_cabec -> (dbskip ())
					loop
				endif

				// Verifica se o pedido eh realmente para esta empresa.
				if alltrim (_cabec -> CNPJForn) != alltrim (sm0 -> m0_cgc) .and. alltrim (_cabec -> EANLocForn) != alltrim (_va_eanloc)
					_Erro (_sSeqPed, "Pedido destina-se a outro fornecedor (CNPJ '" + _cabec -> CNPJForn + "').")
					_cabec -> (dbskip ())
					loop
				endif

				// Valida tipo de mensagem
				do case
					case alltrim (_cabec -> FunMsg) == "9"  // Transmissao original.
					case alltrim (_cabec -> FunMsg) == "16"
						_Erro (_sSeqPed, "Transmissao do tipo 'proposta': nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> FunMsg) == "31"
						_Erro (_sSeqPed, "Transmissao do tipo 'copia de original ja' enviado': nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> FunMsg) == "42"
						_Erro (_sSeqPed, "Transmissao do tipo 'confirmacao de pedido enviado por outros meios': nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> FunMsg) == "46"
						_Erro (_sSeqPed, "Transmissao do tipo 'provisoria': nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					otherwise
						_Erro (_sSeqPed, "Tipo de transmissao desconhecido: '" + _cabec -> FunMsg + "'.")
						_lContinua = .F.
						exit
				endcase

				// Valida tipo de Pedido
				do case
					case alltrim (_cabec -> TpPed) $ "001/002"  // Venda ou bonificacao
					case alltrim (_cabec -> TpPed) == "000"
						_Erro (_sSeqPed, "Pedido do tipo 'condicoes especiais' sem tratamento. Nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> TpPed) == "003"
						_Erro (_sSeqPed, "Pedido do tipo 'consignacao' sem tratamento. Nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> TpPed) == "004"
						_Erro (_sSeqPed, "Pedido do tipo 'vendor' sem tratamento. Nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> TpPed) == "005"
						_Erro (_sSeqPed, "Pedido do tipo 'compror' sem tratamento. Nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					case alltrim (_cabec -> TpPed) == "006"
						_Erro (_sSeqPed, "Pedido do tipo 'demonstracao' sem tratamento. Nao sera' gerado pedido de venda.")
						_cabec -> (dbskip ())
						loop
					otherwise
						_Erro (_sSeqPed, "Tipo de pedido desconhecido: '" + _cabec -> TpPed + "'.")
						_lContinua = .F.
						exit
				endcase

				// Se chegou ateh aqui, faz a importacao desta sequencia de pedido.
				if _lContinua
					_lContinua = _GeraPed (_sSeqPed)
				endif

				_cabec -> (dbskip ())
			enddo
		enddo
	endif

	// Se o arquivo foi importado, move-o para outro diretorio.
	if _lContinua .and. _nRegZZS == NIL
		_Move (_sArqTXT, "Importados")
	else
		if ! _lAuto .and. _nRegZZS == NIL 
			if aviso ("Mover arquivo", "Deseja mover este arquivo para a pasta de arquivos ignorados?", {"Sim", "Não"}) == 1
				_Move (_sArqTxt, "Ignorados")
			endif
		else
			if _nRegZZS == NIL
				_Move (_sArqTxt, "Ignorados")
			endif
		endif
	endif

	U_Arqtrb ("FechaTodos",,,, @_aArqTrb)
	if len (_aGerados) > 0
		// Se foi chamado a partir do arquivo de importacoes de pedidos, atualiza-o.
		if _nRegZZS != NIL .and. _nRegZZS > 0
			zzs -> (dbgoto (_nRegZZS))
			reclock("ZZS", .F.)
			ZZS -> ZZS_NUMPED = _aGerados [1, 1]  // Grava o numero do primeiro pedido gerado (um mesmo arquivo pode gerar mais de um pedido)
			ZZS -> ZZS_MOTIVO = ''
			msunlock()
		endif
		if _lAuto .or. _nRegZZS != NIL
			_sMsg = "Pedido(s) de venda importados por EDI:" + chr (13) + chr (10)
			for _nGerado = 1 to len (_aGerados)
				_sMsg += " Nosso pedido: " + _aGerados [_nGerado, 1] + "   Pedido do cliente: " + _aGerados [_nGerado, 2] + "   Nome cliente: " + _aGerados [_nGerado, 3] + chr (13) + chr (10)
			next
			u_log2 ('info', _sMsg)
			U_ZZUNU ('001', "Importacao EDI Mercador - Resultado", _sMsg)
		else
			_aCpos = {}
			aadd (_aCpos, {1, "Nosso pedido",       70, "@!"})
			aadd (_aCpos, {2, "Pedido do cliente",  70, "@!"})
			aadd (_aCpos, {3, "Nome cliente",      100, "@!"})
			U_F3Array (_aGerados, "Pedidos gerados", _aCpos)
		endif
	else
		// Se foi chamado a partir do arquivo de importacoes de pedidos, atualiza-o.
		if _nRegZZS != NIL .and. _nRegZZS > 0
			zzs -> (dbgoto (_nRegZZS))
			reclock("ZZS", .F.)
			ZZS -> ZZS_NUMPED = ''
			ZZS -> ZZS_MOTIVO = _sErroZZS
			msunlock()
		endif
		if ! _lAuto
			u_help ("Nao foram gerados pedidos no sistema.")
		endif
	endif
Return
//
// --------------------------------------------------------------------------
// Gera pedido de venda para determinada sequencia de pedido lida do arquivo de EDI.
Static Function _GeraPed (_sSeqPed)
	local _lContinua := .T.
	local _sQuery    := ""
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _aLinhaSC6 := {}
	local _sTransp   := ""
	local _oEvento   := NIL
	local _i		 := 0
//	local _lAvisaST  := .F.
//	local _lAvisaBon := .F.
	local _sB1Cod    := ""
	local _sCodNovo  := ""
	local _sObsPed   := ""
	local _sTpFrete  := ""
	local _sMsgErro  := ""
	local _lMarcaPro := .F.
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	if ! _sumario -> (dbseek (_sSeqPed, .F.))
		_Erro (_sSeqPed, "Registro tipo 'sumario' nao encontrado para a seq. de pedido '" + _sSeqPed + "'.")
		_lContinua = .F.
	endif

	// Encontra o cliente.
	if _lContinua         
		sa1 -> (dbsetorder (3))  // A1_FILIAL+A1_CGC
		if ! sa1 -> (dbseek (xfilial ("SA1") + _cabec -> CNPJEntr, .F.))
			sa1 -> (dbgotop ())  // Para nao buscar um cliente qualquer na funcao de geracao de erro.
			_Erro (_sSeqPed, "Cliente nao encontrado com CNPJ '" + _cabec -> CNPJEntr + "' (busquei pelo CNPJ de entrega).")
			_lContinua = .F.
		endif
		if _lContinua .and. sa1 -> a1_vaEAN != _cabec -> EANLocCobr
			_Erro (_sSeqPed, "Campos 'CNPJ' e '" + alltrim (RetTitle ("A1_VAEAN")) + "' no cadastro do cliente '" + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " inconsistentes com dados do pedido." + chr (13) + chr (10) + ;
			                 "No arquivo constam CNPJ de cobranca = '" + _cabec -> CNPJCobr + "' e GLN de cobranca = '" + _cabec -> EANLocCobr + "'. Verifique!")
			_lContinua = .F.
		endif
		if _lContinua .and. sa1 -> a1_vaEANLE != _cabec -> EANLocEntr
			_Erro (_sSeqPed, "Campos 'CNPJ' e '" + alltrim (RetTitle ("A1_VAEANLE")) + "' no cadastro do cliente '" + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " inconsistentes com dados do pedido." + chr (13) + chr (10) + ;
			                 "No arquivo constam CNPJ de entrega = '" + _cabec -> CNPJEntr + "' e GLN de entrega = '" + _cabec -> EANLocEntr + "'. Verifique!")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Filtra clientes cfe. campo especifico.
		if ! sa1 -> a1_vaeding $ '2/3'
			_Erro (_sSeqPed, "Nao recebemos pedidos do cliente " + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " - " + alltrim (sa1 -> a1_nome) + " por EDI (verifique campo '" + alltrim (RetTitle ("A1_VAEDING")) + "')")
			_lContinua = .F.
		endif
		if sa1 -> a1_msblql == "1"
			_Erro (_sSeqPed, "Cliente bloqueado: " + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " - " + alltrim (sa1 -> a1_nome))
			_lContinua = .F.
		endif
		if empty (sa1 -> a1_transp)
			_Erro (_sSeqPed, "Cliente nao tem transportadora informada no seu cadastro: " + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " - " + alltrim (sa1 -> a1_nome))
			_lContinua = .F.
		endif
		if empty (sa1 -> a1_cond)
			_Erro (_sSeqPed, "Cliente nao tem condicao de pagamento informada no seu cadastro: " + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " - " + alltrim (sa1 -> a1_nome))
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (_cabec -> PedCompr)
		_sQuery := ""
		_sQuery += " select count (C5_FILIAL)"
		_sQuery += "   from " + RetSQLName ("SC5")
		_sQuery += "  where D_E_L_E_T_ = ''"
		_sQuery += "    and C5_FILIAL  = '" + xfilial ("SC5") + "'"
		_sQuery += "    and C5_CLIENTE = '" + sa1 -> a1_cod + "'"
		_sQuery += "    and C5_LOJACLI = '" + sa1 -> a1_loja + "'"
		_sQuery += "    and C5_PEDCLI  = '" + _cabec -> PedCompr + "'"
		//u_log (_sQuery)
		if U_RetSQL (_sQuery) > 0
			_Erro (_sSeqPed, "Ordem de compra '" + alltrim (_cabec -> PedCompr) + "' ja' existe para o cliente " + sa1 -> a1_cod + "/" + sa1 -> a1_loja + " - " + alltrim (sa1 -> a1_nome))
			_lContinua = .F.
		endif
	endif

	_sTpFrete = substr(_cabec -> TpFrete,1,1)
   		if left (sa1 -> a1_cgc, 8) == '47427653'  // Makro manda vazio, mas eh sempre frete CIF.
	  	_sTpFrete = 'C'
	endif

	// Encontra a transportadora: frete CIF eh por nossa conta. FOB assume a transportadora informada pelo cliente.
	if _lContinua
		if _sTpFrete == "C"
			_sTransp = sa1 -> a1_transp

		else
			if alltrim (_cabec -> TpCodTrans) == "251"
				sa4 -> (dbsetorder (3))  // A4_FILIAL+A4_CGC
				if ! sa4 -> (dbseek (xfilial ("SA4") + _cabec -> CodTrans, .F.))
					_Erro (_sSeqPed, "Transportadora nao encontrada com CNPJ '" + _cabec -> CodTrans + "'." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
					_lContinua = .F.
				else
					_sTransp = sa4 -> a4_cod
				endif
			endif
		endif
	endif

	// Monta array de cabecalho para geracao do pedido.
	if _lContinua
		_sObsPed = ""
		_aAutoSC5 = {}
		aadd (_aAutoSC5, {"C5_PEDCLI",  _cabec -> PedCompr, NIL})
		aadd (_aAutoSC5, {"C5_EMISSAO", stod (left (_cabec -> DtHrEmis, 8)), NIL})
		aadd (_aAutoSC5, {"C5_CLIENTE", sa1 -> a1_cod, NIL})
		aadd (_aAutoSC5, {"C5_LOJACLI", sa1 -> a1_loja, NIL})
		aadd (_aAutoSC5, {"C5_TPFRETE", _sTpFrete, NIL})
		aadd (_aAutoSC5, {"C5_CONDPAG", sa1 -> a1_cond, NIL})
		if left (sa1->a1_cgc,8) =="45543915" //Testa se o pedido é do carrefour
			aadd (_aAutoSC5, {"C5_PARC1", 100, NIL})
			aadd (_aAutoSC5, {"C5_DATA1", _pagtos -> dtvencto, NIL})
		endif
		aadd (_aAutoSC5, {"C5_TIPO",    "N", NIL})
		aadd (_aAutoSC5, {"C5_VAUSER",  "EDI", NIL})
		aadd (_aAutoSC5, {"C5_MENNOTA", "ENTREGAR ATE " + dtoc (stod (left (_cabec -> DtHrFimPE, 8))), NIL})

		// Ordena campos cfe. dicionario de dados.
		_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
	endif

	// Varre os itens e monta array de itens para geracao do pedido.
	//u_logtrb ('_cabec')
	//u_logtrb ('_itens')
	_lMarcaPro = .F.
	_aAutoSC6 = {}
	_itens -> (dbseek (_sSeqPed, .T.))
	do while _lContinua .and. ! _itens -> (eof ()) .and. _itens -> SeqPed == _sSeqPed
		if ! empty (_itens -> QualifAlt)
			_Erro (_sSeqPed, "Campo 'qualificador de alteracao' sem tratamento." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
			_lContinua = .F.
			exit
		endif
		if alltrim (_itens -> TpCodProd) != "EN"
			_Erro (_sSeqPed, "Tipo de codigo do produto deve ser 'EN' (formato EAN-8, EAN-13 ou DUN-14)" + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
			_lContinua = .F.
			exit
		endif

		if alltrim (_itens -> UM) != "EA" .and. _itens -> UM != '  '  // Modelo 'WMS sum convertido' nao tem un.medida.
			_Erro (_sSeqPed, "Unidade de medida '" + alltrim (_itens -> UM) + "' desconhecida." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
			_lContinua = .F.
			exit
		endif

		// Tratamento para codigos EAN, pois no arquivo do WMS muitas vezes vem com o codigo interno deles.
		if left (sa1 -> a1_CGC, 8) == "93209765"
			_sCodNovo = ""
			do case
				case _itens -> CodProd == "147783        " ; _sCodNovo = "7896100500785"
				case _itens -> CodProd == "147784        " ; _sCodNovo = "7896100500792"
				case _itens -> CodProd == "147785        " ; _sCodNovo = "7896100500815"
				case _itens -> CodProd == "2800001080791 " ; _sCodNovo = "7896100501133"
				case _itens -> CodProd == "2800001080777 " ; _sCodNovo = "7896100501140"
				case _itens -> CodProd == "2800001080890 " ; _sCodNovo = "7896100501171"
				case _itens -> CodProd == "2800001143540 " ; _sCodNovo = "7896100501348"
				case _itens -> CodProd == "2800002534194 " ; _sCodNovo = "27896100501724"
				case _itens -> CodProd == "2700006305113 " ; _sCodNovo = "7896100501515"
				case _itens -> CodProd == "7896100500907 " ; _sCodNovo = "7896100500792"
				case _itens -> CodProd == "7896100500877 " ; _sCodNovo = "7896100500815"
				case _itens -> CodProd == "7896508401035 " ; _sCodNovo = "7896100501539"
				case _itens -> CodProd == "2700006305045 " ; _sCodNovo = "7896100501546"
			endcase
			if ! empty (_sCodNovo)
				//u_log ("Convertendo codigo EAN de '" + _itens -> CodProd + "' para '" + _sCodNovo + "'")
				reclock ("_itens", .F.)
				_itens -> CodProd = _sCodNovo
				msunlock ()
			endif
		endif

		// Encontra o produto pelo codigo EAN-13 ou DUN-14
		if _lContinua
			_sQuery := ""
			_sQuery += " select B1_COD"
			_sQuery += "   from " + RetSQLName ("SB1") + " SB1, "
			_sQuery +=            + RetSQLName ("SB5") + " SB5 "
			_sQuery += "  where SB1.D_E_L_E_T_ = ''"
			_sQuery += "    and SB5.D_E_L_E_T_ = ''"
			_sQuery += "    and SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_sQuery += "    and SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
			_sQuery += "    and SB1.B1_COD = SB5.B5_COD"
			_sQuery += "    and SB5.B5_2CODBAR = '" + iif (left (_itens -> CodProd, 1) == "0", substr (_itens -> CodProd, 2), _itens -> CodProd) + "'"
			_sQuery += "    and SB1.B1_CODPAI  = ''"  // Para nao pegar itens da loja
			_sQuery += "    and SB1.B1_MSBLQL != '1'"  // Bloqueado
			_sB1Cod = U_RetSQL (_sQuery)

			// Se nao achou pelo codigo da unidade (EAN-13), tenta pela caixa (DUN-14)
			if empty (_sB1Cod)
				_sQuery := ""
				_sQuery += " select B1_COD"
				_sQuery += "   from " + RetSQLName ("SB1")
				_sQuery += "  where D_E_L_E_T_ = ''"
				_sQuery += "    and B1_FILIAL  = '" + xfilial ("SB1") + "'"
				_sQuery += "    and B1_CODBAR  = '" + _itens -> CodProd + "'"
				_sQuery += "    and B1_CODPAI  = ''"  // Para nao pegar itens da loja
				_sB1Cod = U_RetSQL (_sQuery)
			endif
			if empty (_sB1Cod)
				_Erro (_sSeqPed, "Produto nao encontrado pelo codigo EAN '" + _itens -> CodProd + "' (tanto unidade como caixa)." + chr (13) + chr (10) + "Descricao fornecida no arquivo: " + alltrim (_itens -> DescriProd) + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
				_lContinua = .F.
				exit
			else
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sB1Cod, .F.))
					_Erro (_sSeqPed, "Produto nao foi encontrado pelo codigo retornado pela query (" + _sB1Cod + "). Solicite manutencao do programa!" + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
					_lContinua = .F.
					exit
				endif
			endif
			if sb1 -> b1_msblql == '1'
				_Erro (_sSeqPed, "Produto inativo ou bloqueado: '" + alltrim (sb1 -> b1_cod) + "' - " + alltrim (sb1 -> b1_desc) + " (cod.barras '" + _itens -> CodProd + "')." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
				_lContinua = .F.
				exit
			endif
		endif

		if _lContinua
			if _cabec -> TpPed == "001" .and. _itens -> QuantPed <= 0
				_Erro (_sSeqPed, "Layout inválido. Pedido tipo 001 (normal): quantidade deve ser informada no campo 'QuantPed'." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
				_lContinua = .F.
				exit
			endif
			if _cabec -> TpPed == "002" .and. _itens -> QuantBonif <= 0
				_Erro (_sSeqPed, "Layout inválido. Pedido tipo 002 (bonificado): quantidade deve ser informada no campo 'QuantBonif'." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
				_lContinua = .F.
				exit
			endif
		endif
		
//		// Define o TES a ser usado
//		if _lContinua
//			if _cabec -> TpPed == "001"  // Normal (venda)
//				_lAvisaBon = .F.
//			elseif _cabec -> TpPed == "002"  // Bonificacao
//				_lAvisaBon = .T.
//			endif
//		endif

		// Valida embalagem
		if alltrim (_itens -> TipoEmbal) != "BX" .and. ! empty (_itens -> TipoEmbal)
			_Erro (_sSeqPed, "Tipo de embalagem sem tratamento: '" + alltrim (_itens -> TipoEmbal) + "'." + chr (13) + chr (10) + "Pedido do cliente " + alltrim (sa1 -> a1_nome) + " nao sera' importado.")
			_lContinua = .F.
			exit
		endif

		// Verifica se trata-se de pedido de produtos 'de marca propria'. Ocorre que, quando grandes redes enviam pedidos com produtos
		// de marca propria, precisamos importar o pedido com representante 001, pois geralmente nao ha comissionamento.
		// Eh procedimento padrao das redes enviarem esses pedidos separados dos pedidos que contem produtos Alianca.
		if sb1 -> b1_vaMarcm == '10'  // Terceios
			_lMarcaPro = .T.
		endif
		
		// Gera linha da array para rotina automatica
		if _lContinua
			_aLinhaSC6 = {}
			aadd (_aLinhaSC6, {"C6_ITEM",    strzero (len (_aAutoSC6) + 1, tamsx3 ("C6_ITEM")[1]), NIL})
			aadd (_aLinhaSC6, {"C6_ENTREG",  stod (left (_cabec -> DtHrFimPE, 8)), NIL})
			aadd (_aLinhaSC6, {"C6_PRODUTO", sb1 -> b1_cod, NIL})
			if _cabec -> TpPed == "001"  // Normal (venda)
				aadd (_aLinhaSC6, {"C6_QTDVEN", _itens -> QuantPed, NIL})

				// Ainda meio 'em teste' (GLPI 8785)
				aadd (_aLinhaSC6, {"C6_VAOPER",  '01', NIL})

			elseif _cabec -> TpPed == "002"  // Bonificacao
				aadd (_aLinhaSC6, {"C6_QTDVEN", _itens -> QuantBonif, NIL})
				aadd (_aLinhaSC6, {"C6_BONIFIC", "08" , NIL})

				// Ainda meio 'em teste' (GLPI 8785)
				aadd (_aLinhaSC6, {"C6_VAOPER",  '04', NIL})

			endif
			// validar essa alteracao
			aadd (_aLinhaSC6, {"C6_NUMPCOM", _cabec -> PedCompr, NIL})
			aadd (_aLinhaSC6, {"C6_ITEMPC" , strzero (len (_aAutoSC6) + 1, tamsx3 ("C6_ITEM")[1]), NIL})

			// Produtos sem valor ficam bloqueados.
			if _itens -> PrUnitLiq > 0
				aadd (_aLinhaSC6, {"C6_PRCVEN", _itens -> PrUnitLiq, NIL})
			else
				aadd (_aLinhaSC6, {"C6_BLQ", 'S', NIL})
				_sObsPed += iif (!empty (_sObsPed), chr (13) + chr (10), "") + "Produto " + alltrim (sb1 -> b1_cod) + " importado sem valor pelo EDI"
			endif

			// Ordena campos cfe. dicionario de dados
			_aLinhaSC6 = aclone (U_OrdAuto (_aLinhaSC6))
			aadd (_aAutoSC6, aclone (_aLinhaSC6))
		endif

		_itens -> (dbskip ())
	enddo

	// Se forem produtos 'de marca propria', assume vendedor 001 (interno) por que nao envolve comissao. GLPI4664
	if _lMarcaPro .and. ! sa1 -> a1_cod $ '005026/014233/013521'  // Carrefour SP / Cencosud
			_sObsPed += " Pedido contem itens de marca propria. Assumindo vendedor 001."
		aadd (_aAutoSC5, {"C5_VEND1",   "001", NIL})
	endif

	// Se for gerada observacao durante a leitura dos itens, inclui-a na array do SC5.
	if ! empty (_sObsPed)
		aadd (_aAutoSC5,  {"C5_OBS",  _sObsPed, NIL})
		_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))  // Ordena campos cfe. dicionario de dados.
	endif

	// Inclui pedido via rotina automatica.
	if _lContinua .and. len (_aAutoSC5) > 0 .and. len (_aAutoSC6) > 0

		// Grava arrays no arquivo de log
		for _i = 1 to len (_aAutoSC6)
			//u_log (_aAutoSC6 [_i])
		next

		U_GravaSX1 ("MTA410", "01", 2)  // Sugere quantidade liberada no pedido = Nao

		lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
		lMsErroAuto := .F.  // necessario a criacao
		_sErroAuto  := ""   // Erros e mensagens customizadss serao gravados aqui
		sc5 -> (dbsetorder (1))
		DbSelectArea("SC5")
		MATA410(_aAutoSC5,_aAutoSc6,3)

		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo

		If lMsErroAuto
			_sMsgErro += "Erro nivel 1: " + _sErroAuto + chr (13) + chr (10)
			if ! empty (NomeAutoLog ())
				_sMsgErro += "Erro nivel 2: " + U_LeErro (memoread (NomeAutoLog ())) + chr (13) + chr (10) + chr (13) + chr (10)
				_sMsgErro += "Erro nivel 3: " + memoread (NomeAutoLog ()) + chr (13) + chr (10) + chr (13) + chr (10)
			else
				_sMsgErro += "Nao foi possivel ler o arquivo de log de erros." + chr (13) + chr (10)
			endif
			_Erro (_sSeqPed, _sMsgErro)
			_lContinua = .F.
		else
			u_log2 ('info', "Pedido gerado: " + sc5 -> c5_num + " ref.ped.cliente:" + sc5 -> c5_pedcli)
			aadd (_aGerados, {sc5 -> c5_num, sc5 -> c5_pedcli, sa1 -> a1_nome})
			_oEvento = ClsEvent():New ()
			_oEvento:Texto    = "Ped. importado via EDI - arq.original: " + _sArqTXT
			_oEvento:CodEven  = "SC5001"
			_oEvento:PedVenda = sc5 -> c5_num
			_oEvento:Cliente  = sc5 -> c5_cliente
			_oEvento:LojaCli  = sc5 -> c5_lojacli
			_oEvento:Grava ()

// Nao precisa mais, pois usaremos TES inteligente			// Manda avisos ao usuario
// Nao precisa mais, pois usaremos TES inteligente			if _lAvisaST
// Nao precisa mais, pois usaremos TES inteligente				U_ZZUNU ('001', "Importacao EDI Mercador - Verifique ST pedido " + sc5 -> c5_num + "Pedido de venda " + sc5 -> c5_num + " foi gerado automaticamente SEM cobranca de substituicao tributaria. Verifique-o.")
// Nao precisa mais, pois usaremos TES inteligente			endif
// Nao precisa mais, pois usaremos TES inteligente			if _lAvisaBon
// Nao precisa mais, pois usaremos TES inteligente				U_ZZUNU ('001', "Importacao EDI Mercador - Verifique pedido BONIFICADO " + sc5 -> c5_num, ;
// Nao precisa mais, pois usaremos TES inteligente				                "Pedido de venda " + sc5 -> c5_num + " veio como 'bonificado', mas entrou no sistema como pedido normal. Verifique os TES do pedido.")
// Nao precisa mais, pois usaremos TES inteligente			endif
		endif

	endif
Return _lContinua
//
// --------------------------------------------------------------------------
// Trata erros encontrados no processamento.
Static Function _Erro (_sSeqPed, _sErro, _sCompleto)
	_sErroZZS += _sErro
	_sCompleto := iif (_sCompleto == NIL, "", _sCompleto)
	if type ('_sArqLog') == 'C'
		_sErro += chr (13) + chr (10) + "Mais detalhes no arquivo de log '" + _sArqLog + "'"
	endif
	if _lAuto
		U_Help ("Erro durante a importacao do arquivo " + _sArqTXT + chr (13) + char (10) + "Pedido/ordem de compra de sequencia " + _sSeqPed + ":" + chr (13) + chr (10) + _sErro,, .t.)

		_sDescCli := ""
		If alltrim(sa1 -> a1_cod) == '000000'
			_sDescCli := sa1 -> a1_cod + '/' + sa1 -> a1_loja 
		else
			_sDescCli := sa1 -> a1_cod + '/' + sa1 -> a1_loja + ' - ' + alltrim (sa1 -> a1_nome)
		EndIf

		U_ZZUNU ('001', ;
		            "Importacao EDI Mercador - ERRO(S)", ;
		            "Erro durante a importacao do arquivo " + _sArqTXT + chr (13) + char (10) + ;
		            "Cliente: " + _sDescCli + chr (13) + chr (10) + ;
		            "Pedido/ordem de compra de sequencia " + _sSeqPed + ":" + chr (13) + chr (10) + ;
		            _sErro + chr (13) + chr (10) + ;
		            _sCompleto)
	else
		U_Help ("Erro durante a importacao do arquivo " + _sArqTXT + chr (13) + char (10) + "Pedido/ordem de compra de sequencia " + _sSeqPed + ":" + chr (13) + chr (10) + _sErro,, .t.)
	endif
Return
//
// --------------------------------------------------------------------------
// Leitura do arquivo TXT para arquivos de trabalho.
Static Function _LeArq (_aArqTrb)
	local _aCampos   := {}
	local _sSeqPed   := ""
	local _lContinua := .T.
	local _sAlias    := ""

	// Monta arquivo temporario para leitura linha a linha do arquivo texto.
	_aCampos = {}
	aadd (_aCampos, {"Campo1", "C", 250, 0})
	aadd (_aCampos, {"Campo2", "C", 250, 0})
	_lContinua = U_ArqTrb ("Cria", "_txt", _aCampos, {}, @_aArqTrb)
	if _lContinua
		append from (_sArqTXT) sdf
		_txt -> (dbgotop ())
		if _txt -> (eof ())
			u_help ("Arquivo vazio!",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"FunMsg"     , "C", 3 , 0})
		aadd (_aCampos, {"TpPed"      , "C", 3 , 0})
		aadd (_aCampos, {"PedCompr"   , "C", 15, 0})
		aadd (_aCampos, {"Filler"     , "C", 5,  0})
		aadd (_aCampos, {"PdSisEmis"  , "C", 20, 0})
		aadd (_aCampos, {"DtHrEmis"   , "C", 12, 0})
		aadd (_aCampos, {"DtHrIniPE"  , "C", 12, 0})
		aadd (_aCampos, {"DtHrFimPE"  , "C", 12, 0})
		aadd (_aCampos, {"Contrato"   , "C", 15, 0})
		aadd (_aCampos, {"ListaPreco" , "C", 15, 0})
		aadd (_aCampos, {"EANLocForn" , "C", 13, 0})
		aadd (_aCampos, {"EANLocComp" , "C", 13, 0})
		aadd (_aCampos, {"EANLocCobr" , "C", 13, 0})
		aadd (_aCampos, {"EANLocEntr" , "C", 13, 0})
		aadd (_aCampos, {"CNPJForn"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJComp"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJCobr"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJEntr"   , "C", 14, 0})
		aadd (_aCampos, {"TpCodTrans" , "C", 3 , 0})
		aadd (_aCampos, {"CodTrans"   , "C", 14, 0})
		aadd (_aCampos, {"NomeTrans"  , "C", 30, 0})
		aadd (_aCampos, {"TpFrete"    , "C", 3 , 0})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_cabec", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"CondPag"    , "C", 3 , 0})
		aadd (_aCampos, {"RefData"    , "C", 3 , 0})
		aadd (_aCampos, {"RefTmpData" , "C", 3 , 0})
		aadd (_aCampos, {"TpPeriodo"  , "C", 3 , 0})
		aadd (_aCampos, {"QtPeriodos" , "N", 3 , 0})
		aadd (_aCampos, {"DtVencto"   , "D", 8 , 0})
		aadd (_aCampos, {"Valor"      , "N", 16, 2})
		aadd (_aCampos, {"Percentual" , "N", 6 , 2})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_pagtos", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"PerDescFin" , "N", 6 , 2})
		aadd (_aCampos, {"VlrDescFin" , "N", 16, 2})
		aadd (_aCampos, {"PerDescCom" , "N", 6 , 2})
		aadd (_aCampos, {"VlrDescCom" , "N", 16, 2})
		aadd (_aCampos, {"PerDescPro" , "N", 6 , 2})
		aadd (_aCampos, {"VlrDescPro" , "N", 16, 2})
		aadd (_aCampos, {"PerEncFin"  , "N", 6 , 2})
		aadd (_aCampos, {"VlrEncFin"  , "N", 16, 2})
		aadd (_aCampos, {"PerEncFre"  , "N", 6 , 2})
		aadd (_aCampos, {"VlrEncFre"  , "N", 16, 2})
		aadd (_aCampos, {"PerEncSeg"  , "N", 6 , 2})
		aadd (_aCampos, {"VlrEncSeg"  , "N", 16, 2})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_descont", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"NumSeq"     , "C", 4 , 0})
		aadd (_aCampos, {"NumItem"    , "C", 5 , 0})
		aadd (_aCampos, {"QualifAlt"  , "C", 3 , 0})
		aadd (_aCampos, {"TpCodProd"  , "C", 3 , 0})
		aadd (_aCampos, {"CodProd"    , "C", 14, 0})
		aadd (_aCampos, {"DescriProd" , "C", 40, 0})
		aadd (_aCampos, {"RefProd"    , "C", 20, 0})
		aadd (_aCampos, {"UM"         , "C", 3 , 0})
		aadd (_aCampos, {"QtUnidCons" , "N", 5 , 0})
		aadd (_aCampos, {"QuantPed"   , "N", 16, 2})
		aadd (_aCampos, {"QuantBonif" , "N", 16, 2})
		aadd (_aCampos, {"QuantTroca" , "N", 16, 2})
		aadd (_aCampos, {"TipoEmbal"  , "C", 3 , 0})
		aadd (_aCampos, {"QtEmbalag"  , "N", 5 , 0})
		aadd (_aCampos, {"VlBruto"    , "N", 16, 2})
		aadd (_aCampos, {"VlLiq"      , "N", 16, 2})
		aadd (_aCampos, {"PrUnitBrt"  , "N", 16, 2})
		aadd (_aCampos, {"PrUnitLiq"  , "N", 16, 2})
		aadd (_aCampos, {"BasePrUnit" , "N", 5 , 0})
		aadd (_aCampos, {"UMBasPrUni" , "C", 3 , 0})
		aadd (_aCampos, {"VlUniDesc"  , "N", 16, 2})
		aadd (_aCampos, {"PerDesc"    , "N", 6 , 2})
		aadd (_aCampos, {"VlUniIPI"   , "N", 16, 2})
		aadd (_aCampos, {"AliqIPI"    , "N", 6 , 2})
		aadd (_aCampos, {"DespAcTrib" , "N", 16, 2})
		aadd (_aCampos, {"DespAcNTri" , "N", 16, 2})
		aadd (_aCampos, {"VlEncFrete" , "N", 16, 2})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_itens", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"TpCodProd"  , "C", 3 , 0})
		aadd (_aCampos, {"CodProd"    , "C", 14, 0})
		aadd (_aCampos, {"QuantPed"   , "N", 16, 2})
		aadd (_aCampos, {"UM"         , "C", 3 , 0})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_grade", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"EANLocEnt"  , "C", 13, 0})
		aadd (_aCampos, {"CNPJLocEnt" , "C", 14, 0})
		aadd (_aCampos, {"DtHrIniPE"  , "C", 12, 0})
		aadd (_aCampos, {"DtHrFimPE"  , "C", 12, 0})
		aadd (_aCampos, {"QuantPed"   , "N", 16, 2})
		aadd (_aCampos, {"UM"         , "C", 3 , 0})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_crossdoc", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"VlTotMerc"  , "N", 16, 2})
		aadd (_aCampos, {"TotIPI"     , "N", 16, 2})
		aadd (_aCampos, {"TotAbatim"  , "N", 16, 2})
		aadd (_aCampos, {"TotEncarg"  , "N", 16, 2})
		aadd (_aCampos, {"TotDescCom" , "N", 16, 2})
		aadd (_aCampos, {"TotDespTri" , "N", 16, 2})
		aadd (_aCampos, {"TotDespNTr" , "N", 16, 2})
		aadd (_aCampos, {"TotPedido"  , "N", 16, 2})
		aadd (_aCampos, {"SeqPed"     , "C", 3 , 0})
		_lContinua = U_ArqTrb ("Cria", "_sumario", _aCampos, {"SeqPed"}, @_aArqTrb)
	endif

	// Varre o arquivo importado fazendo a separacao linha a linha, pois pode
	// haver mais de um pedido por arquivo.
	_sSeqPed = "000"
	do while _lContinua .and. ! _txt -> (eof ())

		// Linhas vazias sao ignoradas.
		if empty (_txt -> campo1)
			_txt -> (dbskip ())
			loop
		endif

		// Define para qual arquivo esta linha deve ser importada.
		_sAlias = ""
		do case

			// O registro tipo 01 indica que, a partir desta linha, estah sendo iniciado
			// um novo pedido (pode haver varios pedidos em um mesmo arquivo).
			case left (_txt -> campo1, 2) == "01"
				_sSeqPed = soma1 (_sSeqPed)
				_sAlias = "_cabec"

			case left (_txt -> campo1, 2) == "02"
				_sAlias = "_pagtos"

			case left (_txt -> campo1, 2) == "03"
				_sAlias = "_descont"

			case left (_txt -> campo1, 2) == "04"
				_sAlias = "_itens"

			case left (_txt -> campo1, 2) == "05"
				_sAlias = "_grade"

			case left (_txt -> campo1, 2) == "06"
				_sAlias = "_crossdoc"

			case left (_txt -> campo1, 2) == "09"
				_sAlias = "_sumario"

		endcase

		// Se definiu qual o arquivo de destino, importa a linha para esse arquivo e
		// jah grava a sequencia do pedido.
		if ! empty (_sAlias)
			U_Txt2DBF (_sAlias, _txt -> campo1 + _txt -> campo2)
			reclock (_sAlias, .F.)
			(_sAlias) -> SeqPed = _sSeqPed
			msunlock ()
		endif

		_txt -> (dbskip ())
	enddo

	//	Habilitar este trecho para verificacao de erros:
	//  u_logtrb ("_cabec")
	//	u_showtrb ("_pagtos")
	//	u_showtrb ("_descont")
	//	u_showtrb ("_itens")
	//	u_showtrb ("_grade")
	//	u_showtrb ("_crossdoc")
	//	u_showtrb ("_sumario")

Return _lContinua
//
// --------------------------------------------------------------------------
// Move o arquivo importado para uma subpasta, para evitar nova tentativa de importacao.
Static Function _Move (_sArq, _sDest)
	local _sDrvRmt  := ""
	local _sDirRmt  := ""
	local _sArqRmt  := ""
	local _sExtRmt  := ""
	local _sArqDest := ""
	local _nSeqNome := 0

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArq, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )

	// Cria diretorio, caso nao exista
	makedir (_sDirRmt + _sDest)

	// Copia o arquivo e depois deleta do local original.
	//
	// Se o arquivo destino jah existir, renomeia-o acrescentando numeros no final.
	_sArqDest = _sArqRmt
	_nSeqNome = 1
	do while file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		_sArqDest = _sArqRmt + "(" + cvaltochar (_nSeqNome++) + ")"
	enddo
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)

	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		if funname() == 'ZZS'
			delete file (_sDirRmt + _sArqRmt + _sExtRmt)
		else
			u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt,, .t.)
		endif
	else
		delete file (_sDirRmt + _sArqRmt + _sExtRmt)
	endif
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Arquivo a importar            ", "C", 60, 0,  "",   "DIR", {},    "Caminho e nome da arquivo a ser importado"})
	U_ValPerg (cPerg, _aRegsPerg)
Return

