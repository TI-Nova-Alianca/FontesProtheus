// Programa...: MT100LOK
// Autor......: Jeferson Rech 
// Data.......: 10/2004
// Descricao..: Validacao LinhaOk da NF de Entrada 

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Validacao LinhaOK da NF de Entrada
// #PalavasChave      #Nf_de_entrada #linhaOK
// #TabelasPrincipais #SD1 #SA1 #SA2 #SD2
// #Modulos   		  #COM 

// Historico de alteracoes:
// 13/10/2008 - Robert - Nao exige mais pedido de compra quando tiver NF original informada.
// 16/10/2008 - Robert - Criada validacao de NF original/item/produto quando tipo NF = D.
//                     - Melhorado tratamento de retornos da funcao.
//                     - Validacoes ref. safra devem ser revistas.
// 22/10/2008 - Robert - Inconsistencias nas verificacoes da safra (causadas pela manutencao anterior).
// 12/01/2009 - Robert - Exigia pedido de compra para notas de recebimento de uva na safra.
// 15/01/2009 - Robert - Novas validacoes ref. campos obrigatorios para a safra.
// 21/01/2009 - Robert - Validava notas de associados sempre como safra (pode ser compra de lenha, etc.)
// 20/02/2009 - Robert - Exige preenchimento do D1_CLASFIS.
// ??/03/2009 - Robert - Pede confirmacao quando TES/valor/quantidade incoerente com NF original.
// 06/05/2009 - Robert - Nao exige mais pedido de compras quando TES de compra de uva da safra.
// 03/09/2009 - Robert - Validacao campo D1_vaForOr.
//                     - Compatibilizacao com base DBF para uso em Livramento.
// 23/09/2009 - Robert - Validacao NF tipo 'C' nao considerava especie 'CTR' corretamente.
// 19/10/2009 - Robert - Notas da filial de Livramento nao exigem mais pedido de compra.
//                     - Notas de retorno de deposito em armazem geral nao exigem mais pedido de compra.
// 24/11/2009 - Robert - Passa a pedir confirmacao quando nao encontra NF original (antes bloqueava).
// 14/01/2010 - Robert - Validacao NF orig. dava erro na versao DBF.
// 19/01/2010 - Robert - Passa a usar funcao U_Help para mensagens de erro.
//                     - Funcao _ClasseUva passada para arquivo proprio.
// 03/08/2010 - Robert - Testa se estah na opcao de 'retornar' antes de verificar volumes x expecies.
// 26/05/2010 - Robert - Nao exige pedido de compras para notas de importacao.
// 04/10/2010 - Robert - Nao exige pedido de compras para notas de compra de servicos (beneficiamento).
// 22/10/2010 - Robert - Nao verifica compAtibilidade com TES original quando chamado via rotina BatD04.
// 12/01/2011 - Robert - Desabilitado controle de area por variedade (safra 2011).
// 03/06/2011 - Robert - Permite entrada de outros produtos com TES de safra, mediante confirmacao.
// 07/06/2011 - Robert - Nao exige pedido de compra quando chamado via importacao de XML.
// 09/06/2011 - Robert - Nao exige pedido de compras para notas entre nossas filiais.
// 04/07/2011 - Robert - Nao pesquisava corretamente UF do fornecedor e exigia ped.compra em NF de importacao.
// 04/07/2011 - Robert - Desabilitados controles por patriarca (safra).
// 26/12/2011 - Robert - Amarracao associado X patriarca passa a considerar a safra.
// 14/02/2012 - Robert - Campo A2_ASSOC vai ser eliminado da base de dados.
// 11/04/2012 - Robert - Nao exige pedido de compra para especie CTE.
// 11/05/2012 - Robert - Passa a considerar especie CTE da mesma forma que CTR.
// 04/09/2012 - Robert - Validacao credito presumido ICMS passa a permitir NF orig. tanto de saida como entrada.
// 21/11/2012 - Robert - Soh exigia volumes e especies quando tipo N para formul.proprio. Agora exige em todos os tipos.
// 12/02/2013 - Elaine - Obriga informar D1_OP se Tipo do Produto for "BN" e TES estiver parametrizada para atualizar estoque
// 06/08/2013 - Robert - Nao exige mais especie e volume quando NF de importacao.
// 11/12/2014 - Robert - Verificacoes integracao Fullsoft.
// 27/01/2015 - Robert - Passa a validar parametros VA_ALMFULP, VA_ALMFULT, VA_ALMFULT
// 30/04/2015 - Robert - Produto deve ser do tipo BN quando CFOP de industrializacao.
// 08/05/2015 - Robert - Passa a bloquear entrada em almox. do FullWMS quando o produto nao eh controlado pelo FullWMS.
// 12/05/2015 - Robert - Exigencia de pedido de compra desabilitada (passamos a usar parametros MV_PCNF e MV_TESPCNF)
// 29/01/2016 - Robert - Somente ordens de producao do tipo 'externa' podem receber lancamentos de NF de entrada.
// 04/03/2016 - Robert - Desabilitadas validacoes de credito ICMS s/ativo.
// 03/05/2016 - Catia  - Validar campo F4_FRETE - so podem ser usados TES com F4_FRETE = 1(SIM) nas especies CTR e CTe
// 05/01/2017 - Catia  - Deletada funcao _ValPC - pq não eh mais usada
// 25/02/2017 - Robert - Verificacoes para quando houver controle de lote.
// 01/03/2016 - Robert - Verificacoes para quando houver controle de lote passa a considerar apenas nota tipo 'N'.
// 07/07/2017 - Catia  - possibilitar que digite o almox 93 nas devolucoes tambem
// 14/08/2018 - Robert - Nao exige c2_vaopesp = 'E' quando OS de manutencao.
// 15/08/2018 - Robert - Passa a usar a funcao U_AlmFull() para validar almox. de integracao com FullWMS.
// 27/08/2018 - Robert - Exige data de validadade quando controla lote.
// 05/12/2018 - Robert - Nao permite mudar data base quando TES movimenta estoque.
// 01/03/2019 - Robert - Bloqueio de movto.de TES que altera estoque com data retroativa estava retornando sempre .T.
// 23/03/2019 - Robert - ELiminada validacoes desnecessarias referentes a safra.
// 06/06/2019 - Robert - Permite mov.de estq.retroativo somente hoje e somente para Katia Nunes.
// 14/06/2019 - Robert - Nao valida lote fornecedor quando estiver usando opcao de 'retornar'.
// 17/06/2019 - Catia  - estava dando erro de tipo na rotina _VERLOTES (568) - Robert pediu para desabilitar o bloco todo
// 06/08/2019 - Robert - No bloueio de mov.estq. fora da data, nao verificava se o usuario pertence ao grupo 084.
// 23/09/2019 - Andre  - Adicionado tipo "F" na validação do campo C2_VAOPESP. 
// 30/03/2020 - Claudia - Ajuste nos campos de ITEM, conforme GLPI: 7737
// 02/04/2020 - Claudia - Voltada alteração GLPI: 7737
// 13/05/2020 - Robert  - Habilitada novamente validacao de safra, pois passaram notas sem sist.conducao, classificacao, etc. nesta safra.
// 19/06/2020 - Robert  - Na validacao de safra, quando espaldeira, exigia D1_PRM99 e nao atendia caso especifico de uva bordo em espaldeira.
// 10/05/2021 - Claudia - Retirada a chamada o programa MATA119. GLPI: 9996
// 25/08/2021 - Claudia - Incluido validação para a chamada do programa FBTRS006.GLPI: 10802
// 23/08/2022 - Robert  - Passa a aceitar CFOP de industrializacao para outros tipos alem de BN (GLPI 12509)
// 29/08/2022 - Robert  - Criada validacao para exigir F4_ESTOQUE=S quando tiver D1_ORDEM.
// 30/11/2022 - Robert  - Passa a exigir dados de rastreabilidade para tipos de nota (antes era apenas cTipo=N)
//

// -------------------------------------------------------------------------------------------------------------------------
User Function MT100LOK()
	local _aAreaAnt    := U_ML_SRArea ()
	Local _lRet        := ParamIxb[1]
	local _lVA_Retor   := .F.
	local _lTransFil   := .F.
	Private _xLOJAPAT  := ""

	If !IsInCallStack("MATA119") 
		
		// Como este ponto de entrada eh executado tanto durante o 'retornar' como durante o preenchimento
		// manual da nota, preciso verificar em qual dos momentos estah sendo executado.
		// Testa se passou pela rotina MSGETDAUTO, o que indica que o usuario clicou em 'retornar' e, neste
		// momento, o sistema estah fazendo a leitura da nota original e preenchendo a array aCols.
		// As linhas ainda serao verificadas novamente, em nova passagem por este ponto de entrada.
		_lVA_Retor = IsInCallStack ("MSGETDAUTO")
		
		// Verifica se eh transferencia de filial
		if cTipo $ 'B/D'
			if left (fBuscaCpo ("SA1", 1, xfilial ("SA1") + ca100For + cLoja, "A1_CGC"), 8) == left (sm0 -> m0_cgc, 8)
				_lTransFil = .T.
			endif
		else
			if left (fBuscaCpo ("SA2", 1, xfilial ("SA2") + ca100For + cLoja, "A2_CGC"), 8) == left (sm0 -> m0_cgc, 8)
				_lTransFil = .T.
			endif
		endif

		if _lRet .and. !GDDeleted () .and. cTipo == 'D' .and. ! _lVA_Retor .and. empty(GdFieldGet('D1_MOTDEV'))
			u_help ('Para nota fiscal de devolução informar motivo da devolução.')
			_lRet = .F.
		EndIf
		
		if _lRet .and. GDFieldGet ("D1_PESBRT") < GDFieldGet ("D1_TARA")
			u_help ("Peso bruto nao pode ser menor que a tara.")
			_lRet = .F.
		endif

		// valida TES de FRETE apenas para documento do tipo CTE ou CTR
		if _lRet 
			_wfrete = fBuscaCpo ('SF4', 1, xfilial('SF4') + GDFieldGet ("D1_TES"), "F4_FRETE")
			if alltrim (cEspecie) $ "CTR/CTE"
				if _wfrete != '1'
					u_help ("Tipo de documento é FRETE, porém TES não é de FRETE. Verifique!")
					_lRet = .F.
				endif
			else
				if _wfrete = '1'
					u_help ("Tipo de documento NÃO é FRETE, porém TES é de FRETE. Verifique!")
					_lRet = .F.
				endif
			endif
		endif

		// Validacoes para notas de entrada de safra
		if _lRet //.and. !GDDeleted ()
			_lRet = _ValSafra ()
		endif

		// Validacoes ref. nota fiscal original.
		if _lRet .and. ! GDDeleted () .and. ! _lVA_Retor //.and. ! IsInCallStack ("ZZX")
			_lRet = _ValNFOri ()
		endif

		// Verifica especies (volumes) e quantidades.
		if _lRet .and. ! GDDeleted () .and. ! _lVA_Retor
			if (! empty (GDFieldGet ("D1_VAVOLES")) .and. empty (GDFieldGet ("D1_VAVOLQT"))) .or. (empty (GDFieldGet ("D1_VAVOLES")) .and. ! empty (GDFieldGet ("D1_VAVOLQT")))
				u_help ("Os campos '" + alltrim (RetTitle ("D1_VAVOLES")) + "' e '" + alltrim (rettitle ("D1_VAVOLQT")) + "' devem estar ambos informados ou ambos vazios.")
				_lRet = .F.
			endif
			if _lRet .and. cFormul == "S" .and. (empty (GDFieldGet ("D1_VAVOLES")) .or. empty (GDFieldGet ("D1_VAVOLQT")))
				if cTipo == 'N' .and. fBuscaCpo ("SA2", 1, xfilial ("SA2") + ca100For + cLoja, "A2_EST") == "EX"
					_lRet = U_msgyesno ("Para NF de entrada com formulario proprio os campos '" + alltrim (RetTitle ("D1_VAVOLES")) + "' e '" + alltrim (rettitle ("D1_VAVOLQT")) + "' deveriam ser informados. Confirma?")
				else
					u_help ("Para NF de entrada com formulario proprio os campos '" + alltrim (RetTitle ("D1_VAVOLES")) + "' e '" + alltrim (rettitle ("D1_VAVOLQT")) + "' devem ser informados.")
					_lRet = .F.
				endif
			endif
		endif

		// Validacoes adicionais
		if _lRet .and. ! GDDeleted ()
			if len (alltrim (GDFieldGet ("D1_CLASFIS"))) < 3
				u_help ("Campo '" + alltrim (RetTitle ("D1_CLASFIS")) + "' nao esta' completo. Verifique cadastro do produto e do TES.")
				_lRet = .F.
			endif
		endif

		// Validacoes OP e produto BN
		if _lRet .and. ! GDDeleted ()
			_lRet = _VerOPBN ()
		endif

		// Verifica integracao com Fullsoft
		if _lRet .and. ! GDDeleted () .and. ! _lVA_Retor .and. cTipo $ 'N/D'
			_lRet = _VerFull (_lTransFil)
		endif

		// Verificacoes para controle de lotes.
		if _lRet .and. ! GDDeleted () //.and. ! IsInCallStack ("ZZX")
			_lRet = _VerLotes (_lTransFil, _lVA_Retor)
		endif

		// Verificacoes para data retroativa
		if _lRet .and. ! GDDeleted ()
			_lRet = _VerData ()
		endif

		// Validacoes OS (de manutencao)
		if _lRet .and. ! GDDeleted ()
			_lRet = _VerOSMan ()
		endif

	EndIf
	U_ML_SRArea (_aAreaAnt)
Return(_lRet)


// ----------------------------------------------------------------------------------------
// Validacoes ref. nota fiscal original.
static function _ValNFOri ()
	local _lRet      := .T.
	local _sQuery    := ""
	local _aNfOri    := {}
	local _nSaldoRet := 0
	
	if _lRet .and. cTipo $ "ND" .and. ! empty (GDFieldGet ("D1_NFORI"))
		_sQuery := ""
		_sQuery += " select D2_QUANT, D2_PRCVEN, D2_TES "
		_sQuery +=   " from " + RetSQLName ("SD2")
		_sQuery +=  " where D_E_L_E_T_ = ''"
		_sQuery +=    " and D2_FILIAL  = '" + xfilial ("SD2") + "'"
		_sQuery +=    " and D2_DOC     = '" + GDFieldGet ("D1_NFORI") + "'"
		_sQuery +=    " and D2_SERIE   = '" + GDFieldGet ("D1_SERIORI") + "'"
		_sQuery +=    " and D2_CLIENTE = '" + ca100For + "'"
		_sQuery +=    " and D2_LOJA    = '" + cLoja + "'"
		_sQuery +=    " and D2_COD     = '" + GDFieldGet ("D1_COD") + "'"
		_sQuery +=    " and D2_ITEM    = '" + GDFieldGet ("D1_ITEMORI") + "'"
		_aNfOri = aclone (U_Qry2Array (_sQuery))
		
		if len (_aNFOri) == 0 
			If !ISINCALLSTACK("U_FBTRS006")
				_lRet = U_MsgNoYes ("NF origem - Nao foi encontrada a nota fiscal original numero '" + GDFieldGet ("D1_NFORI") + "' para o cliente/fornecedor '" + ca100For + "/" + cLoja + "'." + chr (13) + chr (10) + "Verifique preenchimento dos seguintes campos: " + alltrim (RetTitle ("D1_COD")) + ", " + alltrim (RetTitle ("D1_NFORI")) + ", " + alltrim (RetTitle ("D1_SERIORI")) + ", " + alltrim (RetTitle ("D1_ITEMORI")) + chr (13) + chr (10) + chr (13) + chr (10) + "Confirma mesmo assim?")
			else
				_lRet = .T.
			EndIf
		endif
		
		if _lRet .and. len (_aNFOri) > 0 .and. GDFieldGet ("D1_VUNIT") != _aNfOri [1, 2]
			u_help ("Preco unitario deve ser igual ao da NF de origem (" + cvaltochar (_aNfOri [1, 2]) + ").")
			_lRet = .F.
		endif

		if _lRet .and. len (_aNFOri) > 0 // .and. ! IsInCallStack ("U_BATD04")
			if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") != fBuscaCpo ("SF4", 1, xfilial ("SF4") + _aNFOri [1, 3], "F4_ESTOQUE")
				_lRet = U_MsgNoYes ("Incompatibilidade entre o TES atual e o TES usado na nota original: ambos deveriam ter a mesma configuracao quanto a atualizar estoques." + chr (13) + chr (10) + "Confirma a digitacao assim mesmo?")
			endif
		endif
		
		// Verifica o saldo a retornar. Isso por que o TES pode nao estar controlando poder de terceiros...
		if _lRet .and. len (_aNFOri) > 0

			// Desconta outras devolucoes, caso jah existam.
			_sQuery := ""
			_sQuery += " select sum (D1_QUANT) "
			_sQuery +=   " from " + RetSQLName ("SD1")
			_sQuery +=  " where D_E_L_E_T_ = ''"
			_sQuery +=    " and D1_FILIAL  = '" + xfilial ("SD1") + "'"
			_sQuery +=    " and D1_NFORI   = '" + GDFieldGet ("D1_NFORI") + "'"
			_sQuery +=    " and D1_SERIORI = '" + GDFieldGet ("D1_SERIORI") + "'"
			_sQuery +=    " and D1_ITEMORI = '" + GDFieldGet ("D1_ITEMORI") + "'"
			_sQuery +=    " and D1_FORNECE = '" + ca100For + "'"
			_sQuery +=    " and D1_LOJA    = '" + cLoja + "'"
			_sQuery +=    " and D1_COD     = '" + GDFieldGet ("D1_COD") + "'"
			_sQuery +=    " and D1_TIPO    IN ('N', 'D')"
			_nSaldoRet = _aNFOri [1, 1] - U_RetSQL (_sQuery)
			if GDFieldGet ("D1_QUANT") > _nSaldoRet
				_lRet = U_MsgNoYes ("Quantidade maior que o saldo a retornar da NF de origem para este produto (" + cvaltochar (_nSaldoRet) + "). Confirma assim mesmo?")
			endif
		endif
	endif

	if _lRet .and. ! GDDeleted () .and. cTipo $ "C" .and. ! alltrim (cEspecie) $ "CTR/CTE"  // Complemento de preco
		_sQuery := ""
		_sQuery += " select count (*) "
		_sQuery +=   " from " + RetSQLName ("SD1")
		_sQuery +=  " where D_E_L_E_T_ = ''"
		_sQuery +=    " and D1_FILIAL  = '" + xfilial ("SD1") + "'"
		_sQuery +=    " and D1_DOC     = '" + GDFieldGet ("D1_NFORI") + "'"
		_sQuery +=    " and D1_SERIE   = '" + GDFieldGet ("D1_SERIORI") + "'"
		_sQuery +=    " and D1_FORNECE = '" + ca100For + "'"
		_sQuery +=    " and D1_LOJA    = '" + cLoja + "'"
		_sQuery +=    " and D1_COD     = '" + GDFieldGet ("D1_COD") + "'"

		// Faz um acoxambramento por causa da simpatica incompatibilidade de tamanho entre os campos D1_ITEM e D1_ITEMORI...
		_sQuery +=    " and (SUBSTRING (D1_ITEM, 1, 2) = '" + GDFieldGet ("D1_ITEMORI") + "' or D1_ITEM = '" + iif (len (alltrim (GDFieldGet ("D1_ITEMORI"))) == 1, '00', '') + GDFieldGet ("D1_ITEMORI") + "')"
		
		if U_RetSQL (_sQuery) < 1
			u_help ("Validacao conh.frete: Nao foi encontada a nota fiscal original numero '" + ;
			        GDFieldGet ("D1_NFORI") + "' para o fornecedor/loja '" + ca100For + "/" + cLoja + "'." + ;
			        chr (13) + chr (10) + "Verifique preenchimento dos seguintes campos: " + ;
			        alltrim (RetTitle ("D1_COD")) + ", " + ;
			        alltrim (RetTitle ("D1_NFORI")) + ", " + ;
			        alltrim (RetTitle ("D1_SERIORI")) + ", " + ;
			        alltrim (RetTitle ("D1_ITEMORI")), ;
			        "Criterio de busca: " + _sQuery)
			_lRet = .F.
		endif
	endif
	
	if _lRet .and. cTipo == 'D'
		if  empty (GDFieldGet ("D1_NFORI"))  
			u_help ("Nota Fiscal Origem não informada")
			_lRet = .F.
		endif
	
		if _lRet
			_sQuery = ""
			_sQuery += " SELECT D2_TES "
			_sQuery += "   FROM " + RetSQLName ("SD2")
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "    AND D2_FILIAL  = '" + xfilial ("SD2") + "'"
			_sQuery += "    AND D2_DOC     = '" + GDFieldGet ("D1_NFORI") + "'"
			_sQuery += "    AND D2_SERIE   = '" + GDFieldGet ("D1_SERIORI") + "'"
			_aDados := U_Qry2Array(_sQuery)

			if len(_aDados) = 0
				u_help ("Nota/Serie Original Informada não existe.")
				_lRet = .F.				
			endif

			if _lRet 
				_sQuery = ""
				_sQuery += " SELECT D2_TES "
				_sQuery += "   FROM " + RetSQLName ("SD2")
				_sQuery += "  WHERE D_E_L_E_T_ = ''"
				_sQuery += "    AND D2_FILIAL  = '" + xfilial ("SD2") + "'"
				_sQuery += "    AND D2_DOC     = '" + GDFieldGet ("D1_NFORI") + "'"
				_sQuery += "    AND D2_SERIE   = '" + GDFieldGet ("D1_SERIORI") + "'"
				_sQuery += "    AND D2_CLIENTE = '" + ca100For + "'"
				_sQuery += "    AND D2_LOJA    = '" + cLoja + "'"
				_aDados := U_Qry2Array(_sQuery)
				if len(_aDados) = 0
					u_help ("Nota/Serie Original não é desse cliente.")
					_lRet = .F.
				endif
			endif
		endif
	endif
return _lRet


// -------------------------------------------------------------------------------------------------
// Validacoes ref. notas de entrada/compra de safra de uva.
Static Function _ValSafra ()
	local _lRetSafr := .T.

	// Verifica se eh uma nota de entrada de uva.
	if _lRetSafr .and. ! GDDeleted () .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_GRUPO") == "0400"

		if empty (GDFieldGet ("D1_GRAU"))
			u_help ("Notas de uva: Grau deve ser informado no campo '" + alltrim (RetTitle ("D1_GRAU")) + "'.",, .t.)
			_lRetSafr = .F.
		endif
		if empty (GDFieldGet ("D1_VAVITIC")) .and. ! IsInCallStack ("U_VA_GNF2")  // Para notas de compra vai apenas nas obs da nota, pois acumula varias notas de entrada.
			u_help ("Notas de uva: Numero do cadastro viticola deve ser informado no campo '" + alltrim (RetTitle ("D1_VAVITIC")) + "'.",, .t.)
			_lRetSafr = .F.
		endif
		if empty (GDFieldGet ("D1_VACONDU"))
			u_help ("Notas de uva: Sistema de conducao/sustentacao deve ser informado no campo '" + alltrim (RetTitle ("D1_VACONDU")) + "'.",, .t.)
			_lRetSafr = .F.
		else
			if GDFieldGet ("D1_VACONDU") == 'L'
				if empty (GDFieldGet ("D1_VACLABD"))
					u_help ("Notas de uva: Quando sistema 'latada', a classificacao deve ser informada no campo '" + alltrim (RetTitle ("D1_VACLABD")) + "'.",, .t.)
					_lRetSafr = .F.
				endif
			elseif GDFieldGet ("D1_VACONDU") == 'E'
				if fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_VARUVA") == 'F'
					if empty (GDFieldGet ("D1_PRM99"))
						u_help ("Notas de uva: Quando sistema 'espaldeira', a classificacao deve ser informada no campo '" + alltrim (RetTitle ("D1_PRM99")) + "'.",, .t.)
						_lRetSafr = .F.
					endif
					if empty (GDFieldGet ("D1_PRM02")) .and. ! IsInCallStack ("U_VA_GNF2")  // Para notas de compra vai apenas a classificacao final.
						u_help ("Notas de uva: Quando sistema 'espaldeira', a classificacao por acucar deve ser informada no campo '" + alltrim (RetTitle ("D1_PRM02")) + "'.",, .t.)
						_lRetSafr = .F.
					endif
					if empty (GDFieldGet ("D1_PRM03")) .and. ! IsInCallStack ("U_VA_GNF2")  // Para notas de compra vai apenas a classificacao final.
						u_help ("Notas de uva: Quando sistema 'espaldeira', a classificacao por sanidade deve ser informada no campo '" + alltrim (RetTitle ("D1_PRM03")) + "'.",, .t.)
						_lRetSafr = .F.
					endif
					if empty (GDFieldGet ("D1_PRM04")) .and. ! IsInCallStack ("U_VA_GNF2")  // Para notas de compra vai apenas a classificacao final.
						u_help ("Notas de uva: Quando sistema 'espaldeira', a classificacao por maturacao deve ser informada no campo '" + alltrim (RetTitle ("D1_PRM04")) + "'.",, .t.)
						_lRetSafr = .F.
					endif
					if empty (GDFieldGet ("D1_PRM05")) .and. ! IsInCallStack ("U_VA_GNF2")  // Para notas de compra vai apenas a classificacao final.
						u_help ("Notas de uva: Quando sistema 'espaldeira', a classificacao por materiais estranhos deve ser informada no campo '" + alltrim (RetTitle ("D1_PRM05")) + "'.",, .t.)
						_lRetSafr = .F.
					endif
				endif
			else
				u_help ("Notas de uva: Programa sem tratamento para sistema de conducao '" + GDFieldGet ("D1_VACONDU") + "'.",, .t.)
				_lRetSafr = .F.
			endif
		endif
	endif
return _lRetSafr


// -----------------------------------------------------------------------------------------------
// Verificacoes sobre OP / item tipo BN
static function _VerOPBN ()
	local _lRet      := .T.
	local _sTpPrdInd := ''

	if _lRet .and. empty (GDFieldGet ("D1_OP")) .and. ;
		fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_TIPO") == "BN"    .AND. ;
		fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") == "S"
		
		u_help ("Campo '" + alltrim (RetTitle ("D1_OP")) + "' deve ser preenchido quando produto for do Tipo 'BN' e TES atualizar estoque.")
		_lRet = .F.
	endif

	if _lRet .and. ! empty (GDFieldGet ("D1_OP"))
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (xfilial ("SC2") + GDFieldGet ("D1_OP"), .F.))
			u_help ("OP '" + GDFieldGet ("D1_OP") + "' nao encontrada.")
			_lRet = .F.
		else
			if _lRet .and. sc2 -> c2_produto == GDFieldGet ("D1_COD")
				u_help ("O produto informado nao pode ser o mesmo a ser produzido pela OP, pois seria requisitado na propria OP, gerando uma referencia circular.")
				_lRet = .F.
			endif

			if _lRet .and. ! sc2 -> c2_vaopesp $ 'E/F' .and. sc2 -> c2_item != 'OS'  // Ignora OS da manutencao.
				u_help ("Somente ordens de producao do tipo 'externa' podem receber lancamentos de NF de entrada.")
				_lRet = .F.
			endif
			if _lRet
				if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") == 'S'  // Soh gera SD3 se o TES movimentar estoque.
					sd4 -> (dbsetorder (1))  // D4_FILIAL+D4_COD+D4_OP+D4_TRT+D4_LOTECTL+D4_NUMLOTE
					if sd4 -> (dbseek (xfilial ("SD4") + GDFieldGet ("D1_COD") + GDFieldGet ("D1_OP"), .F.)) .and. sd4 -> d4_quant != 0
						u_help ("O produto '" + alltrim (GDFieldGet ("D1_COD")) + "' encontra-se empenhado na OP '" + alltrim (GDFieldGet ("D1_OP")) + "'. Providencie a remocao do empenho, pois do contrario o mesmo sera´ requisitado novamente ao apontar a OP.")
						_lRet = .F.
					endif
				endif
			endif
		endif
	endif

	if _lRet .and. alltrim (GDFieldGet ("D1_CF")) $ '1124/2124'
//		_sTpPrdInd = "BN/ME/PS/MP/VD"  // GLPI 12509
		_sTpPrdInd = "BN/ME/PS/MP/VD/PP"  // GLPI 12509
		if ! fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_TIPO") $ _sTpPrdInd
			u_help ("CFOP de industrializacao: o produto deve ser do tipo " + _sTpPrdInd,, .t.)
			_lRet = .F.
		endif
	endif
return _lRet


// ---------------------------------------------------------------------------------------------------
// Verificacoes integracao com Fullsoft.
static function _VerFull (_lTransFil)
	local _lRet     := .T.
	local _sMsg     := ""
	local _sAlmFull := ""

	if GDFieldGet ("D1_QUANT") != 0
		if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") == "S"
			_sMsg = ""

			// Verifica em qual almox. deve entrar.
			if _lTransFil
				_sAlmFull = U_AlmFull (GDFieldGet ("D1_COD"), 'TF')  // Entrada transf de filial
			elseif cTipo == 'D'
				_sAlmFull = U_AlmFull (GDFieldGet ("D1_COD"), 'DV')  // Devol de venda
			else
				_sAlmFull = U_AlmFull (GDFieldGet ("D1_COD"), 'NE')  // Nota de entrada normal
			endif

			if ! empty (_sAlmFull)
				if !GDFieldGet ("D1_LOCAL") $ _sAlmFull
					_sMsg = "Produto '" + alltrim (GDFieldGet ("D1_COD")) + "' controla armazenagem via FullWMS nesta filial. Entradas deste tipo de nota devem ser feitas no almoxarifado '" + _sAlmFull + "'."
				endif

			else  // Produto NAO DEVE entrar em nenhum almox. de integracao com FullWMS.
				if GDFieldGet ("D1_LOCAL") $ U_AlmFull (NIL, 'TODOS')
					_sMsg = "Produto '" + alltrim (GDFieldGet ("D1_COD")) + "' nao controla armazenagem via FullWMS nesta filial. Entradas deste tipo de nota NAO devem ser feitas em almoxarifados de integracao com FullWMS."
				endif
			endif
	
			// Se chegou ateh aqui com retorno negativo, eh por que teve alguma inconsistencia.
			// Sobra, ainda, o recurso do usuario ter liberacao para movimentar assim mesmo.
			if ! empty (_sMsg)
				if u_zzuvl ('029', __cUserId, .F.)
					_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				else
					u_help (_sMsg)
					_lret = .F.
				endif
			endif
		endif
	endif
return _lRet


// ------------------------------------------------------------------------------------------
// Verificacoes para quando houver controle de lote.
static function _VerLotes (_lTransFil, _lVA_Retor)
	local _lRet    := .T.

//	if _lRet .and. ! _lVA_Retor .and. cTipo == 'N' .and. (empty (GDFieldGet ("D1_LOTEFOR")) .or. empty (GDFieldGet ("D1_DTVALID"))) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_RASTRO") == "L" 
	if _lRet .and. ! _lVA_Retor .and. ! cTipo $ 'ICP' .and. (empty (GDFieldGet ("D1_LOTEFOR")) .or. empty (GDFieldGet ("D1_DTVALID"))) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D1_COD"), "B1_RASTRO") == "L" 
		if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") == "S"
			u_help ("O produto '" + GDFieldGet ("D1_COD") + "' possui controle de lotes. O lote do fornecedor (campo '" + alltrim (RetTitle ("D1_LOTEFOR")) + "') e data de validade (campo '" + alltrim (RetTitle ("D1_DTVALID")) + "') devem ser informados para possibilitar a rastreabilidade.",, .t.)
			_lRet = .F.
		endif
	endif
return _lRet


// -------------------------------------------------------------------------------------------------------
// Verificacoes para datas.
static function _VerData ()
	local _lRet    := .T.
	local _sMsg    := ""

	if dDataBase != date () .and. ! empty (GDFieldGet ("D1_TES")) .and. GDFieldGet ("D1_QUANT") != 0
		if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") == 'S'
			_sMsg = "Movimentacao fora da data de hoje nao permitida para TES que movimenta estoques."
			if U_ZZUVL ('084', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg)
				_lRet = .F.
			endif
		endif
	endif
return _lRet


// -----------------------------------------------------------------------------------------------
// Verificacoes para OS (de manutencao).
static function _VerOSMan ()
	local _lRet      := .T.

	if _lRet .and. ! empty (GDFieldGet ("D1_ORDEM"))
		if fBuscaCpo ("SF4", 1, xfilial ("SF4") + GDFieldGet ("D1_TES"), "F4_ESTOQUE") != "S"
			u_help ("Quando informada ordem de manutencao (campo D1_ORDEM - '" + alltrim (RetTitle ("D1_ORDEM")) + "), o TES deve atualizar estoque, para que seja possivel requisitar o material direto para a OS.")
			_lRet = .F.
		endif
	endif

return _lRet
