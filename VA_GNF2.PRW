// Autor:     Robert Koch
// Data:      08/05/2009
// Descricao: Gera notas fiscais de compra/complemento de uva da safra cfe. previsao do arquivo ZZ9.
//            Criado com base no ML_GNFS de Jeferson Rech.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Gera notas fiscais de compra/complemento de uva da safra cfe. previsao do arquivo ZZ9.
// #PalavasChave      #contranotas #safra
// #TabelasPrincipais #ZZ9
// #Modulos           #COOP

// Historico de alteracoes:
// 06/07/2009 - Robert - Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
// 15/07/2009 - Robert - Tinha um dbskip indevido e perdia o primeiro registro de uma pre-nota quando nao houvesse sido
//                       gerada nenhuma nota para o fornecedor anterior.
// 30/07/2010 - Robert - Ajustes finos para safra 2010.
// 28/07/2011 - Robert - Ajustes para safra 2011.
//                     - Nao gravava campo ZZ9_NFCOMP apos a geracao das notas.
// 07/10/2012 - Robert - Ajustes particularidades safra 2012.
// 23/04/2015 - Robert - Melhorias safra 2015.
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 04/01/2016 - Robert - Tratamento para parametro VA_SERSAFR.
// 19/02/2016 - Robert - Criado tratamento para o atributo 'PARCELA' da classe ClsCtaCorr.
// 16/12/2016 - Robert - Revisada rotina de complemento de preco.
// 21/03/2017 - Robert - Ignora pre-notas zeradas sem mostrar mensagem (gera apenas log)
//                     - Melhoria regua processamento; eliminados alguns logs.
// 22/04/2017 - Robert - Gravava a serie no D1_NFORI para notas de complemento.
//                     - Nao concatena mais as duas classificacoes (Livram/Serra) na descricao. Agora verifica a filial.
// 27/03/2018 - Robert - Tratamento gravacao campo F1_VASAFRA, leitura de mensagens do ZZ9_MSGNF
// 25/05/2018 - Robert - Nao acumula mais de uma NF origem quando nota de complemento (SEFAZ nao autoriza mais).
// 23/03/2019 - Robert - Ajustes para compra 2019. Filtro pelo ZZ9_GRUPO, melhora mensagens.
// 18/04/2019 - Robert - Ajustes compl.preco uva propria Livramento 2019
// 25/04/2019 - Robert - Array de itens passa a usar nomes (XTranslate) para identificar posicoes.
//                     - Tratamento para o campo ZZ9_TES.
// 13/05/2020 - Robert - Ajustes para 2020: compra parcial (apenas bordo e bordo de bordadura). Refeito while principal (GLPI 7705)
//                     - Melhorados logs e mensagens de erro.
// 16/06/2020 - Robert - TInha um dbskip() a mais e perdia a pre-nf quando a mesma tivesse apenas um item.
// 15/02/2021 - Robert - Passa a prever parcelas via VA_RusPP.prw para manter consistencia com VA_RusN (GLPI 9389)
// 29/03/2021 - Robert - Novo parametro funcao VA_RusPP (GLPI 9592).
// 07/05/2021 - Robert - Gravacao campo ZI_SAFRA (GLPI 9891).
// 18/05/2021 - Robert - Melhorias diversas FUNRURAL e complemento safra 2021 (GLPI 9891 e 10007).
// 04/03/2022 - Robert - Valida se o TES de complemento estah atualizando estoque (GLPI 11708).
// 07/03/2022 - Robert - Permite (mediante confirmacao) TES que atualiza estoque nos complementos (GLPI 11721)
// 08/11/2022 - Robert - Passa a usar a funcao U_AmbTeste().
// 04/01/2023 - Robert - Novos codigos de retorno da funcao VA_FTIPO_FORNECEDOR_UVA
// 25/05/2023 - Robert - Versao complemento safra 2023A (maio) - GLPI 13532
// 16/06/2023 - Robert - Versao complemento safra 2023B (junho) - GLPI 13699
// 04/02/2024 - Robert - Versao complemento safra 2023C (fev/24) - GLPI 14483
//                     - Criada opcao de nao filtrar ZZ9_GRUPO
//

#XTranslate .ItensProduto    => 1
#XTranslate .ItensDescricao  => 2
#XTranslate .ItensGrau       => 3
#XTranslate .ItensClasEspald => 4
#XTranslate .ItensClasLatada => 5
#XTranslate .ItensQuantidade => 6
#XTranslate .ItensValorTotal => 7
#XTranslate .ItensNFOri      => 8
#XTranslate .ItensSerieOri   => 9
#XTranslate .ItensItemOri    => 10
#XTranslate .ItensConducao   => 11
#XTranslate .ItensTES        => 12
#XTranslate .ItensRecnosZZ9  => 13
#XTranslate .ItensQtColunas  => 13

// --------------------------------------------------------------------------
User Function VA_GNF2 (_lAutomat)
	Local cCadastro    := "Geracao NF compra / complemento de Uva"
	Local aSays        := {}
	Local aButtons     := {}
	Local nOpca        := 0
	Local lPerg        := .F.
	local _nLock       := 0
	local _lContinua   := .T.
	local _lAuto       := iif (_lAutomat == NIL, .F., _lAutomat)
	Private cPerg      := "VAGNF2"
	private _sOrigSZI  := "VA_GNF2"
	private _sErroAuto := ""  // Deixar private para ser vista pela funcao U_Help ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('045', __cUserID, .T.)
	endif

	// Controle de semaforo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_ValidPerg()
		Pergunte(cPerg,.F.)      // Pergunta no SX1
		
		AADD(aSays,"  Este programa tem como objetivo gerar as NFs de Compra de Uva,    ")
		AADD(aSays,"  com base no arquivo de pre-notas de compra de safra.              ")
		AADD(aSays,"")
		AADD(aSays,"")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		if _lAuto
			Processa( { |lEnd| _Gera03() } )
		else
			FormBatch( cCadastro, aSays, aButtons )
			If nOpca == 1
				Processa( { |lEnd| _Gera03() } )
			Endif
		endif
	
		// Libera semaforo
		U_Semaforo (_nLock)
	endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
Static Function _Gera03 ()
	local _lContinua := .T.
	local _sSerie    := ""
	local _sSafra    := ""
	local _sParcelas := ""
	local _sFornIni  := ""
	local _sFornFim  := ""
	local _sLojaIni  := ""
	local _sLojaFim  := ""
	local _sDCO      := ""
	local _sVarUva   := ""
	local _sPreNF    := ""
	local _sMsgContr := ""
	local _aItens    := {}
	local _sNfEntr   := {}
	local _sNfProd   := {}
	local _lPreNFOk  := .F.
	local _nPorDCO   := 0
	local _aPreNF    := {}
	local _sCondPag  := ""
	local _sParcela  := ""
	local _aFornec   := {}
	local _nFornec   := 0
	local _sCadVitic := ""
	local _sVitOrig  := ""
	local _sMsgNfZZ9 := ""
	local _sZZ9NFOri := ""
	local _sVariSim  := ''
	local _sVariNao  := ''
	local _nContForn := 0
	local _lGerouNF  := .F.
	private _nTamDesc := tamsx3 ("D1_DESCRI")[1]
	private _nTamItem := tamsx3 ("D1_ITEM")[1]
	private _nTamItOr := tamsx3 ("D1_ITEMORI")[1]
	private _nTamD1Qt := tamsx3 ("D1_QUANT")[1]
	private _sGrpZZ9  := ''
	private _sNFIni   := ""
	private _sNFFim   := ""

	u_logSX1 ()
	

	// Altera parametro "Mostra lctos contabeis" para "Nao" 
	// e 'Contabiliza online' para 'sim' na tela de NF de entrada
//	if "TESTE" $ upper (GetEnvServer())  // na base teste nao quero contabilizar
	if U_AmbTeste ()
		U_GravaSX1 ("MTA103", "01", "2")
		U_GravaSX1 ("MTA103", "06", "2")
	else
		U_GravaSX1 ("MTA103", "01", "2")
		U_GravaSX1 ("MTA103", "06", "1")
	endif

	// A partir de 2016 teremos uma serie especifica para NF de safra.
	// Fica fixo no programa para nem precisar abrir tela para o usuario.
	if _lContinua
		_sSerie = GetMv ("VA_SERSAFR", .F., '')
		if empty (_sSerie)
			u_help ("Serie a ser usada nas NF de safra nao definida. Verifique se o parametro VA_SERSAFR existe e se contem uma serie de NF valida para esta filial.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
	
		// Guarda parametros em variaveis especificas por que as chamadas de rotinas automaticas vai sobregrava-los.
		_sFornIni = mv_par01
		_sLojaIni = mv_par02
		_sFornFim = mv_par03
		_sLojaFim = mv_par04
		_sSafra   = mv_par05
		_sParcelas = alltrim (mv_par06)
		_sGrpZZ9  = mv_par07
		_nPorDCO  = mv_par08
		_sVarUva  = mv_par09
		_sTipoNF  = iif (mv_par10 == 1, "N", "C")
		_sCondPag = mv_par11
		_sVariSim = alltrim (mv_par12)
		_sVariNao = alltrim (mv_par13)
		_nTamDesc = tamsx3 ("D1_DESCRI")[1]
		_nTamItem = tamsx3 ("D1_ITEM")[1]
		_nTamItOr = tamsx3 ("D1_ITEMORI")[1]
	endif

	if _lContinua

		// Monta array com os fornecedores ordenados por nome, para facilitar a posterior separacao das notas,
		// e simula varias execucoes da rotina com associado inicial = associado final.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT ZZ9_FORNEC, ZZ9_LOJA, A2_NOME, A2_VACORIG"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SA2.A2_COD     = ZZ9_FORNEC"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = ZZ9_LOJA"
		_oSQL:_sQuery +=    " AND ZZ9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZ9_FILIAL     = '" + xfilial ("ZZ9") + "'"
		_oSQL:_sQuery +=    " AND ZZ9_SAFRA      = '" + _sSafra + "'"
		if ! empty (_sParcelas)
			_oSQL:_sQuery +=    " AND ZZ9_PARCEL     IN " + FormatIn (_sParcelas, '/')
		endif
		_oSQL:_sQuery +=    " AND ZZ9_TIPONF     = '" + _sTipoNF + "'"
		if ! empty (_sGrpZZ9)
			_oSQL:_sQuery +=    " AND ZZ9_GRUPO      = '" + _sGrpZZ9 + "'"
		endif
		_oSQL:_sQuery +=    " AND ZZ9_FORNEC + ZZ9_LOJA BETWEEN '" + _sFornIni + _sLojaIni + "' AND '" + _sFornFim + _sLojaFim + "'"
		_oSQL:_sQuery +=    " AND ZZ9_NFCOMP     = ''"
		if ! empty (_sVariSim)
			_oSQL:_sQuery +=" AND RTRIM (ZZ9_PRODUT) IN " + FormatIn (_sVariSim, '/')
		endif
		if ! empty (_sVariNao)
			_oSQL:_sQuery +=" AND RTRIM (ZZ9_PRODUT) NOT IN " + FormatIn (_sVariNao, '/')
		endif
		if mv_par14 == 1
//			// Testa a situacao do fornecedor no final de marco (a safra jah deve ter finalizado nessa data)
//			_oSQL:_sQuery +=" AND SUBSTRING (dbo.VA_FTIPO_FORNECEDOR_UVA (ZZ9_FORNEC, ZZ9_LOJA, '" + _sSafra + "0331'), 1, 1) IN ('1', '3')"
			_oSQL:_sQuery +=" AND ZZ9_TPFORN IN ('1', '3')"
		elseif mv_par14 == 2
//			// Testa a situacao do fornecedor no final de marco (a safra jah deve ter finalizado nessa data)
//			_oSQL:_sQuery +=" AND dbo.VA_FTIPO_FORNECEDOR_UVA (ZZ9_FORNEC, ZZ9_LOJA, '" + _sSafra + "0331') LIKE '2%'"
			_oSQL:_sQuery +=" AND ZZ9_TPFORN IN ('2')"
		endif
		_oSQL:_sQuery +=  " ORDER BY A2_VACORIG, A2_NOME, ZZ9_FORNEC, ZZ9_LOJA"
		_oSQL:Log ()
		_aFornec = aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aFornec) == 0
			u_help ("Nenhuma pre-nota encontrada.", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_lOK := Sx5NumNota (@_sSerie)   // Apresenta Tela para Confirmar o Numero da Primeira NF a Ser Gerada
		if ! _lOK .or. empty (_sSerie)  // Usuario cancelou ou nao confirmou em tempo habil
			U_Log2 ('info', "Usuario nao confirmou a numeracao da primeira nota.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (len (_aFornec))
		for _nFornec = 1 to len (_aFornec)
			_sFornIni := _sFornFim := _aFornec [_nFornec, 1]
			_sLojaIni := _sLojaFim := _aFornec [_nFornec, 2]

			u_log2 ('info', '[' + cvaltochar (_nFornec) + ' de ' + cvaltochar (len (_aFornec)) + ']Iniciando fornecedor ' + _sFornIni + ' ' + _aFornec [_nFornec, 3])
			incproc ('Fornecedor ' + _sFornIni + '/' + _sLojaIni + '(' + cvaltochar (_nFornec) + ' de ' + cvaltochar (len (_aFornec)) + ')')

			// Tenho casos em que preciso quebrar a pre-nota, por que o sistema
			// nao permite referenciar a mesma NF original mais de uma vez. Como
			// as pre-notas jah estao geradas, achei melhor processar o 
			// fornecedor mais de uma vez, ateh terminar de gerar todas as notas.
			_nContForn = 1
			do while .t.
		//		U_Log2 ('debug', '[' + procname () + ']Iniciando passagem ' + cvaltochar (_nContForn) + ' pelo fornecedor.')

				// Que vergonha ter que fazer este tipo de controle, neh?
				if _nContForn > 10
					U_Log2 ('erro', '[' + procname () + ']Jah processei este fornecedor ' + cvaltochar (_nContForn) + ' vezes. Deve ter alguma coisa errada!')
					_lContinua = .F.
					exit
				endif
				_lGerouNF = .F.
				
				// Busca pre-notas para geracao das nf de compra da uva.
				zz9 -> (dbsetorder (3))  // ZZ9_FILIAL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_PRE_NF
				zz9 -> (dbseek (xfilial ("ZZ9") + _sFornIni + _sLojaIni + _sSafra, .T.))
				do while _lContinua ;
					.and. !zz9 -> (eof ()) ;
					.and. zz9 -> zz9_filial == xfilial ("ZZ9") ;
					.and. zz9 -> zz9_fornec + zz9 -> zz9_loja <= _sFornFim + _sLojaFim ;
					.and. zz9 -> zz9_safra == _sSafra

					// Controla quebra por pre-nf, pois cada registro do ZZ9 equivale a um registro
					// de NF de entrada de uva do SD1, mas agora devo somar as quantidades das uvas
					// de mesmo grau e classificacao.
					_sFornece  = zz9 -> zz9_fornec
					_sLoja     = zz9 -> zz9_loja
					_sPreNF    = zz9 -> zz9_pre_nf
					_sNfProd   = zz9 -> zz9_nfProd
					_sZZ9NFOri = zz9 -> zz9_nfori
					_sNfEntr   = ""
					_sCadVitic = ""
					_sDCO      = zz9 -> zz9_dco
					_sParcela  = zz9 -> zz9_parcel
					_aItens    = {}
					_lPreNFOk  = .T.
					_sMsgNfZZ9 = ''
					_aPreNF    = {}
					do while _lContinua .and. !zz9 -> (eof ()) ;
						.and.  zz9 -> zz9_filial == xfilial ("ZZ9") ;
						.and.  zz9 -> zz9_fornec == _sFornece ;
						.and.  zz9 -> zz9_loja   == _sLoja ;
						.and.  zz9 -> zz9_safra  == _sSafra ;
						.and.  zz9 -> zz9_parcel == _sParcela //;
			//			.and.  zz9 -> zz9_nfori  == _sZZ9NFOri  // Em 25/05/18 a SEFAZ jah nao aceitou mais notas referenciando mais de uma NF origem (Rejeicao 255)

						if empty (zz9 -> zz9_grau)
							u_help ("Grau nao informado na pre-nf '" + zz9 -> zz9_pre_nf + "'.",, .t.)
							zz9 -> (dbskip ())
							loop
						endif
						if zz9 -> zz9_vunit <= 0
							u_log2 ('aviso', "Pre-nf '" + zz9 -> zz9_pre_nf + "' sem valor unitario (ou negativo). A mesma vai ser ignorada.")
							zz9 -> (dbskip ())
							loop
						endif
						if ! empty (zz9 -> zz9_nfcomp)  // Nota jah gerada.
					//		u_log2 ('debug', "Pre-nf " + zz9 -> zz9_pre_nf + " item " + zz9 -> zz9_produt + ' jah tem NF gerada.')
							zz9 -> (dbskip ())
							loop
						endif
						if zz9 -> zz9_fornec + zz9 -> zz9_loja < _sFornIni + _sLojaIni .or. zz9 -> zz9_fornec + zz9 -> zz9_loja > _sFornFim + _sLojaFim
							u_log2 ('debug', 'zz9_fornec fora da faixa selecionada.')
							zz9 -> (dbskip ())
							loop
						endif
						if zz9 -> zz9_safra != _sSafra
							u_log2 ('debug', 'zz9_safra fora da faixa selecionada.')
							zz9 -> (dbskip ())
							loop
						endif
						if ! empty (_sParcelas) .and. ! zz9 -> zz9_parcel $ _sParcelas
					//		u_log2 ('debug', "zz9_parcel '" + zz9 -> zz9_parcel + "' fora da faixa selecionada.")
							zz9 -> (dbskip ())
							loop
						endif
						if ! empty (_sGrpZZ9) .and. zz9 -> zz9_grupo != _sGrpZZ9
					//		u_log2 ('debug', 'zz9_grupo fora da faixa selecionada.')
							zz9 -> (dbskip ())
							loop
						endif
						if zz9 -> zz9_tiponf != _sTipoNF
							u_log2 ('debug', 'zz9_tiponf fora da faixa selecionada.')
							zz9 -> (dbskip ())
							loop
						endif
						if empty (zz9 -> zz9_tes)
							u_help ("TES para geracao da nota deve ser informado.",, .t.)
							zz9 -> (dbskip ())
							loop
						endif

						// Verifica fornecedor.
						sa2 -> (dbsetorder (1))
						if ! sa2 -> (dbseek (xfilial ("SA2") + zz9 -> zz9_fornec + zz9 -> zz9_loja, .F.))
							u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' nao cadastrado.",, .t.)
							zz9 -> (dbskip ())
							loop
						endif
						if empty (sa2 -> a2_conta)
							u_help ("Fornecedor '" + zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja + "' sem conta contabil.")
							zz9 -> (dbskip ())
							loop
						endif

						// Verifica produto
						if ! empty (_sVariNao) .and. alltrim (zz9 -> zz9_produt) $ _sVariNao
							u_log2 ('debug', "Variedade consta no parametro 'nao gerar para estas variedades'.")
							zz9 -> (dbskip ())
							loop
						endif
						if ! empty (_sVariSim) .and. ! alltrim (zz9 -> zz9_produt) $ _sVariSim
							u_log2 ('debug', "Variedade nao consta no parametro 'gerar apenas estas variedades'.")
							zz9 -> (dbskip ())
							loop
						endif
						sb1 -> (dbsetorder (1))
						if ! sb1 -> (dbseek (xfilial ("SB1") + zz9 -> zz9_produt, .F.))
							u_help ("Produto '" + zz9 -> zz9_produt + "' nao cadastrado.")
							_lPreNFOk = .F.
							zz9 -> (dbskip ())
							loop
						endif
						if _sVarUva == 1 .and. sb1 -> b1_varuva != "C"
							u_log2 ('debug', 'Tipo de uva (fina/comum) fora dos parametros selecionados.')
							zz9 -> (dbskip ())
							loop
						endif
						if _sVarUva == 2 .and. sb1 -> b1_varuva != "F"
							u_log2 ('debug', 'Tipo de uva (fina/comum) fora dos parametros selecionados.')
							zz9 -> (dbskip ())
							loop
						endif
						if empty (zz9 -> zz9_conduc)
							u_help ("Sistema de conducao nao informado.")
							_lPreNFOk = .F.
							zz9 -> (dbskip ())
							loop
						else
							if zz9 -> zz9_conduc == 'L'
								if empty (zz9 -> zz9_clabd)
									u_help ("Sistema de conducao 'latada': classificacao da uva nao informada.")
									_lPreNFOk = .F.
									zz9 -> (dbskip ())
									loop
								endif
							elseif zz9 -> zz9_conduc == 'E'
								if empty (zz9 -> zz9_classe)
									u_help ("Sistema de conducao 'espaldeira': classificacao da uva nao informada.")
									_lPreNFOk = .F.
									zz9 -> (dbskip ())
									loop
								endif
							else
								u_help ("Sistema de conducao sem tratamento: '" + zz9 -> zz9_conduc + "'.",, .t.)
								_lPreNFOk = .F.
								zz9 -> (dbskip ())
								loop
							endif
						endif
		
						// Verificacoes ref. DCO (Documento Comprobatorio de Origem para leilao de compra da CONAB)
						if (_nPorDCO == 1 .and. empty (zz9 -> zz9_dco)) .or. (_nPorDCO == 2 .and. !empty (zz9 -> zz9_dco))
							zz9 -> (dbskip ())
							loop
						endif
						if ! empty (zz9 -> zz9_dco) .and. empty (zz9 -> zz9_nfprod) .and. zz9 -> zz9_tipoNF != "C"
							if zz9 -> zz9_safra != '2012'  // Em 2012 usamos o campo para outras coisas...
								u_help ("NF de produtor deve ser informada quando houver DCO (pre-nf '" + zz9 -> zz9_pre_nf + "' / fornecedor '" + zz9 -> zz9_fornec + "').")
								_lPreNFOk = .F.
								zz9 -> (dbskip ())
								loop
							endif
						endif
							
						if zz9 -> zz9_tiponf == "C" .and. empty (zz9 -> zz9_nfori)
							u_help ("NF de complemento sem NF origem (pre-nf '" + zz9 -> zz9_pre_nf + "').")
							_lPreNFOk = .F. 
							zz9 -> (dbskip ())
							loop
						endif

						// Em maio/2023, gerando complemento de preco, o sistema nao
						// aceitou mais usar duas vezes a mesma nota de origem (por
						// exemplo, quando a NF original tinha mais de uma variedade)
						if ascan (_aItens, {|_aVal| _aVal [.ItensNFOri] == zz9 -> zz9_nfori .and. _aVal [.ItensSerieOri] == zz9 -> zz9_serior}) > 0
					//		U_Log2 ('debug', '[' + procname () + ']NF origem ' + zz9 -> zz9_nfori + ' jah consta nos itens desta nota. Vou deixar para gerar na proxima.')
							zz9 -> (dbskip ())
							loop
						endif

						// Existe a possibilidade de diferentes registros de uma mesma
						// variedade/grau/classificacao terem precos unitarios diferentes,
						// seja por mistura, multa, etc... entao preciso
						// acumular tudo em uma array para, depois, calcular o preco medio.
						_nItem = ascan (_aItens, {|_aVal| _aVal [.ItensProduto]    == zz9 -> zz9_produt ;
													.and. _aVal [.ItensGrau]       == zz9 -> zz9_grau ;
													.and. _aVal [.ItensClasEspald] == zz9 -> zz9_classe ;
													.and. _aVal [.ItensClasLatada] == zz9 -> zz9_clabd ;
													.and. _aVal [.ItensConducao]   == zz9 -> zz9_conduc})
						if _nItem == 0
							aadd (_aItens, array (.ItensQtColunas))
							_nItem = len (_aItens)
							_aItens [_nItem, .ItensProduto]    = zz9 -> zz9_produt
							_aItens [_nItem, .ItensDescricao]  = sb1 -> b1_desc
							_aItens [_nItem, .ItensGrau]       = zz9 -> zz9_grau
							_aItens [_nItem, .ItensClasEspald] = zz9 -> zz9_classe
							_aItens [_nItem, .ItensClasLatada] = zz9 -> zz9_clabd
							_aItens [_nItem, .ItensQuantidade] = 0
							_aItens [_nItem, .ItensValorTotal] = 0
							if zz9 -> zz9_tipoNF == 'N'  // Nota normal de compra
								_aItens [_nItem, .ItensNFOri]      = ''
								_aItens [_nItem, .ItensSerieOri]   = ''
								_aItens [_nItem, .ItensItemOri]    = ''
							elseif zz9 -> zz9_tipoNF == 'C'  // Nota de complemento
								_aItens [_nItem, .ItensNFOri]    = zz9 -> zz9_nfori
								_aItens [_nItem, .ItensSerieOri] = zz9 -> zz9_serior
								_aItens [_nItem, .ItensItemOri]  = zz9 -> zz9_itemor
							endif
							_aItens [_nItem, .ItensConducao]   = zz9 -> zz9_conduc
							_aItens [_nItem, .ItensTES]        = zz9 -> zz9_tes
							_aItens [_nItem, .ItensRecnosZZ9]  = {}
						endif

						// Mantem uma lista dos registros do ZZ9 atendidos por este item da NF de complemento.
						aadd (_aItens [_nItem, .ItensRecnosZZ9], zz9 -> (recno ()))

						_aItens [_nItem, .ItensQuantidade] += zz9 -> zz9_quant
						if zz9 -> zz9_tipoNF == 'N'  // Nota normal de compra
							_aItens [_nItem, .ItensValorTotal] += zz9 -> zz9_quant * zz9 -> zz9_vunit
						elseif zz9 -> zz9_tipoNF == 'C'  // Nota de complemento

							// Eita safrinha complicada pra pagar!
							if zz9 -> zz9_safra == '2023'
								if left (dtos (date ()), 6) $ '202305/202306'
									_aItens [_nItem, .ItensValorTotal] += (zz9 -> zz9_qtori * zz9 -> zz9_vunit) - (zz9 -> zz9_qtori * zz9 -> zz9_vunold)
								elseif left (dtos (date ()), 6) == '202402'  // Siiiiim, estou complementando 2023 soh agora!
									_aItens [_nItem, .ItensValorTotal] += (zz9 -> zz9_qtori * zz9 -> zz9_vunit4) - (zz9 -> zz9_qtori * zz9 -> zz9_vunold)
								endif
							else
								_aItens [_nItem, .ItensValorTotal] += zz9 -> zz9_vunit
							endif
						endif
						
						if _aItens [_nItem, .ItensValorTotal] <= 0
							U_Log2 ('erro', '[' + procname () + ']Valor total zerado ou negativo para a pre-nota ' + _sPreNF)
							_lPreNFOk = .F.
						endif

						// Alimenta lista das notas de entrada
						if ! empty (zz9 -> zz9_nfentr) .and. ! alltrim (zz9 -> zz9_nfentr) $ _sNFEntr
							_sNFEntr += alltrim (zz9 -> zz9_nfentr) + ","
						endif
						
						// Alimenta lista de cadastros viticolas das notas de entrada.
						if ! empty (zz9 -> zz9_nfentr)
							_oSQL := ClsSQL ():New ()
							_oSQL:_sQuery := ""
							_oSQL:_sQuery += " SELECT DISTINCT CAD_VITIC"
							_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
							_oSQL:_sQuery +=  " WHERE FILIAL        = '" + zz9 -> zz9_filial + "'"
							_oSQL:_sQuery +=    " AND SAFRA         = '" + zz9 -> zz9_safra  + "'"
							_oSQL:_sQuery +=    " AND ASSOCIADO     = '" + zz9 -> zz9_fornec + "'"
							_oSQL:_sQuery +=    " AND LOJA_ASSOC    = '" + zz9 -> zz9_loja   + "'"
							_oSQL:_sQuery +=    " AND DOC           = '" + zz9 -> zz9_nfentr + "'"
							_oSQL:_sQuery +=    " AND PRODUTO       = '" + zz9 -> zz9_produt + "'"
							_oSQL:_sQuery +=    " AND GRAU          = '" + zz9 -> zz9_grau   + "'"
							_oSQL:_sQuery +=    " AND CLAS_FINAL    = '" + zz9 -> zz9_classe + "'"
							_oSQL:_sQuery +=    " AND CLAS_ABD      = '" + zz9 -> zz9_clabd  + "'"
							_oSQL:_sQuery +=    " AND SIST_CONDUCAO = '" + zz9 -> zz9_conduc + "'"
							_sVitOrig = _oSQL:Qry2Str ()
							if ! empty (_sVitOrig) .and. ! alltrim (_sVitOrig) $ _sCadVitic
								_sCadVitic += alltrim (_sVitOrig) + ","
							endif
						endif
		
						// Alimenta lista de mensagens para a nota.
						if ! empty (zz9 -> zz9_msgNF) .and. ! alltrim (zz9 -> zz9_msgNF) $ _sMsgNfZZ9
							_sMsgNFZZ9 += ' ' + alltrim (zz9 -> zz9_msgNF)
						endif

						// Alimenta lista de registros do ZZ9 atendidos, para atualizar depois que terminar de gerar a nota.
						if ascan (_aPreNF, zz9 -> (recno ())) == 0
							aadd (_aPreNF, zz9 -> (recno ()))
						endif
		
						zz9 -> (dbskip ())
					enddo

				//	u_log2 ('DEBUG', "Itens da pre-nf " + _sPreNF + ": ")
				//	U_LOG2 ('DEBUG', _aitens)
					
					// A nota pode jah ter sido gerada em processamento anterior ou pode ter sido detectado algum erro na pre-nf.
					if len (_aItens) == 0 .or. ! _lPreNFOk
				//		u_log2 ('debug', 'Nenhum item a gerar para a pre-nota ' + _sPreNF)
						loop
					endif
		
					// Prepara dados adicionais
					_sMsgContr = ""
					if ! empty (_sNfProd)
						_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Ref.NF produtor " + alltrim (_sNfProd) + " de " + dtoc (dDataBase)
					endif
					if ! empty (_sNfEntr)
						_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Ref.NNF entrada " + substr (_sNfEntr, 1, len (_sNfEntr) - 1)
					endif
					if ! empty (_sCadVitic)
						_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + "Cad.vitic:" + substr (_sCadVitic, 1, len (_sCadVitic) - 1)
					endif
					if ! empty (_sMsgNfZZ9)
						_sMsgContr += iif (! empty (_sMsgContr), "; ", "") + _sMsgNfZZ9
					endif

					_lGerouNF = _GeraNota (_sTipoNF, sa2 -> a2_cod, sa2 -> a2_loja, _aItens, _sMsgContr, _sSerie, sa2 -> a2_est, _sDCO, _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpZZ9)

				enddo

				// Se nao gerou nota (nao tinha mais nenhuma pre-nota a
				// processar), posso cair fora do loop deste fornecedor.
				if ! _lGerouNF
			//		U_Log2 ('debug', '[' + procname () + ']Nao havia nais nada a processar para este fornecedor.')
					exit
				endif

				// Esta variavel eh apenas um contadorzinho para saber quantas
				// quebras tive que fazer para este fornecedor
				_nContForn ++
			enddo
		next

	endif

	if ! _lContinua
		u_help ("PROCESSO CANCELADO. Notas ja' geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	else
		u_help ("Processo finalizado. Notas geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	endif
		
	// Notifica interessados.
	if _sNFIni != _sNFFim
	//	U_ZZUNU ({'019', '023', '116', '052'}, ;  // Fiscal, RH e custos.
		U_ZZUNU ({'019', '116', '052', '068'}, ;  // Fiscal, custos, contabilidade, direcao/ger.financeiro
		          "Geracao nota(s) de compra / complemento preco safra", ;
		         "Aviso do sistema: foram geradas nesta data notas de compra / complemento de preco de safra na filial " + cFilAnt + chr (13) + chr (10) + ;
		         "Sugere-se emitir o relatorio 'CONTRANOTAS SAFRA' (VA_XLS30) no modulo Cooperativa, filtrando esta data, para maiores detalhes.")
	endif
Return


// --------------------------------------------------------------------------
// Gera a nota de entrada com os dados informados.
Static Function _GeraNota (_sTipoNota, _sFornece, _sLoja, _aItens, _sMsgContr, _sSerie, _sUF, _sDCO, _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpPagto)
	local _sNF       := ""
	local _nItem     := 0
	local _nQuant    := 0
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _lContinua := .T.
	local _oCtaCorr  := NIL
	local _aNFPRur   := {}
	local _oSQL      := NIL
	local _sMemoAnt  := ""
	local _nPreNF    := 0
	local _nVlrUvas  := 0
	private _aParPgSaf := {}  // Parcelas pre calculadas. Deixar PRIVATE para ser lida pelo ponto de entrada MTCOLSE2().


	// A partir de 2012 preciso informar uma NF de produtor rural referenciada. Como aqui sao misturadas
	// diversas notas, pegarei a primeira nota deste associado na safra em questao.
	if _lContinua
		if _sTipoNota == 'N'
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT TOP 1 NF_PRODUTOR, SERIE_NF_PRODUTOR"
			_oSQL:_sQuery +=   " FROM dbo.VA_VNOTAS_SAFRA V"
			_oSQL:_sQuery +=  " WHERE V.SAFRA      = '" + _sSafra + "'"
			_oSQL:_sQuery +=    " AND V.FILIAL     = '" + cFilAnt + "'"
			_oSQL:_sQuery +=    " AND V.ASSOCIADO  = '" + _sFornece + "'"
			_oSQL:_sQuery +=    " AND V.LOJA_ASSOC = '" + _sLoja + "'"
			_oSQL:_sQuery +=    " AND V.TIPO_NF    in ('E', 'C')"
			_oSQL:_sQuery +=    " AND V.PRODUTO    = '" + _aItens [1, .ItensProduto] + "'"
			_aNFPRur = aclone (_oSQL:Qry2Array (.f., .f.))
		elseif _sTipoNota == 'C'
			// Precisarei gravar a tabela CDD ("NF referenciadas" para geracao do XML).
			// Entao vou aproveitar para tentar usar NF de produtor referenciada pela
			// mesma contranota de origem.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT top 1 ZZ9_NFORI, ZZ9_SERIOR, NF_PRODUTOR, SERIE_NF_PRODUTOR, F1_CHVNFE"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZ9") + " ZZ9"
			_oSQL:_sQuery +=      ", dbo.VA_VNOTAS_SAFRA V"
			_oSQL:_sQuery +=      ", " + RetSQLName ("SF1") + " SF1"
			_oSQL:_sQuery += " WHERE ZZ9.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZZ9.R_E_C_N_O_ = " + cvaltochar (_aPreNF [1])  // Vou pegar sempre a primeira pre-nota.
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9") + "'"    // Vou validar uns campos a mais soh pra garantir
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_SAFRA  = '" + _sSafra    + "'"          // Vou validar uns campos a mais soh pra garantir
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_FORNEC = '" + _sFornece  + "'"          // Vou validar uns campos a mais soh pra garantir
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_LOJA   = '" + _sLoja     + "'"          // Vou validar uns campos a mais soh pra garantir
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_PARCEL = '" + _sParcela  + "'"          // Vou validar uns campos a mais soh pra garantir
			if ! empty (_sGrpPagto)
				_oSQL:_sQuery +=   " AND ZZ9.ZZ9_GRUPO  = '" + _sGrpPagto + "'"          // Vou validar uns campos a mais soh pra garantir
			endif
			_oSQL:_sQuery +=   " AND ZZ9.ZZ9_NFCOMP = ''"
			_oSQL:_sQuery +=   " AND V.SAFRA        = ZZ9_SAFRA"
			_oSQL:_sQuery +=   " AND V.FILIAL       = ZZ9_FILIAL"
			_oSQL:_sQuery +=   " AND V.ASSOCIADO    = ZZ9_FORNEC"
			_oSQL:_sQuery +=   " AND V.LOJA_ASSOC   = ZZ9_LOJA"
			_oSQL:_sQuery +=   " AND V.DOC          = ZZ9_NFORI"
			_oSQL:_sQuery +=   " AND V.SERIE        = ZZ9_SERIOR"
			_oSQL:_sQuery +=   " AND V.ITEM_NOTA    = ZZ9_ITEMOR"
			_oSQL:_sQuery +=   " AND SF1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SF1.F1_FILIAL  = ZZ9.ZZ9_FILIAL"
			_oSQL:_sQuery +=   " AND SF1.F1_VASAFRA = ZZ9.ZZ9_SAFRA"
			_oSQL:_sQuery +=   " AND SF1.F1_FORNECE = ZZ9.ZZ9_FORNEC"
			_oSQL:_sQuery +=   " AND SF1.F1_LOJA    = ZZ9.ZZ9_LOJA"
			_oSQL:_sQuery +=   " AND SF1.F1_DOC     = ZZ9.ZZ9_NFORI"
			_oSQL:_sQuery +=   " AND SF1.F1_SERIE   = ZZ9.ZZ9_SERIOR"
		//	_oSQL:Log ('[' + procname () + ']')
			_aNFPRur = aclone (_oSQL:Qry2Array (.f., .f.))
		endif
		if len (_aNFPRur) == 0
			u_help ("Nao encontrei nenhuma NF de produtor para referenciar.", _oSQL:_sQuery, .T.)
			_lContinua = .F.
		endif
	endif

	// Busca a Proxima NF da Sequencia
	if _lContinua
		_sNF = NxtSX5Nota (_sSerie)

		// Prepara campos do cabecalho da nota
		_aAutoSF1 := {}
		AADD( _aAutoSF1, { "F1_DOC"      , _sNF,           Nil } )
		AADD( _aAutoSF1, { "F1_SERIE"    , _sSerie,        Nil } )
		AADD( _aAutoSF1, { "F1_TIPO"     , _sTipoNota,     Nil } )
		if _sTipoNota == 'C'
			AADD( _aAutoSF1, { "F1_TPCOMPL"  , '1',     Nil } )
		endif
		AADD( _aAutoSF1, { "F1_FORMUL"   , "S",            Nil } )
		AADD( _aAutoSF1, { "F1_EMISSAO"  , dDataBase,      Nil } )
		AADD( _aAutoSF1, { "F1_FORNECE"  , _sFornece,      Nil } )
		AADD( _aAutoSF1, { "F1_LOJA"     , _sLoja,         Nil } )
		AADD( _aAutoSF1, { "F1_EST"      , _sUF,           Nil } )
		AADD( _aAutoSF1, { "F1_ESPECIE"  , "SPED",         Nil } )
		AADD( _aAutoSF1, { "F1_COND"     , _sCondPag,      Nil } )
		AADD( _aAutoSF1, { "F1_STATUS"   , 'A',            Nil } )
		AADD( _aAutoSF1, { "F1_VADCO"    , _sDCO,          Nil } )  // Cpo customizado: serah tratado no P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VANFPRO"  , _aNFPRur [1, 1], Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASEPRO"  , _aNFPRur [1, 2], Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASAFRA"  , _sSafra,        Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAGPSAF"  , _sGrpPagto,     Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAFLAG"   , 'G',            Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I. Indica 'nota ja gerada' para a rotina de manut. XML

		u_log ("Fornecedor:", _sFornece, _sLoja)
	//	u_log ("Msg.:", _sMsgContr)
	//	u_log ("Pre-notas:", _aPreNF)
	//	u_log2 ("debug", _aAutoSF1)
	//	u_log2 ('DEBUG', _aitens)

		// Prepara itens da nota
		_nVlrUvas = 0
		_aAutoSD1 = {}
		for _nItem = 1 to len (_aItens)

			sb1 -> (dbsetorder (1))
			sb1 -> (dbseek (xfilial ("SB1") + _aItens [_nItem, .ItensProduto], .F.))
			
			// Monta descricao com grau e classificacao da uva. Inicia com o grau e classificacao, reduzindo o nome da uva caso necessario.
			_sDescri = " Gr:" + alltrim (_aItens [_nItem, .ItensGrau])
			if ! empty (_aItens [_nItem, 4])  // Classificacao espaldeira (DS/D/C/B/A/AA)
				_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasEspald])
			elseif ! empty (_aItens [_nItem, 5])  // Classificacao latada (A/B/D)
				_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasLatada])
			endif
			_sDescri = left (alltrim (_aItens [_nItem, .ItensDescricao]), _nTamDesc - len (_sDescri)) + _sDescri

			// Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
			if _sTipoNota == "N"
				_nQuant = round (_aItens [_nItem, .ItensQuantidade], _nTamD1Qt)
				_nVlUni = _aItens [_nItem, .ItensValorTotal] / _nQuant
				_nVlTot = round (_nQuant * _nVlUni, 2)
			else
				_nQuant = 0
				_nVlUni = 0
				_nVlTot = round (_aItens [_nItem, .ItensValorTotal], 2)
			endif

			if _sTipoNota == 'C'
				if fBuscaCpo ("SF4", 1, xfilial ("SF4") + _aItens [_nItem, .ItensTES], "F4_ESTOQUE") == 'S'
					_lContinua = u_msgnoyes ("Para notas de complemento, o TES (" + _aItens [_nItem, .ItensTES] + ") nao deve atualizar estoque, pois afeta o custo medio. Como eh comum gerarmos complemento depois que a uva nao tem mais estoque, usa-se uma funcao customizada para jogar o complemento de safra nos itens de granel. Confirma assim mesmo?")
					if ! _lContinua
						exit
					endif
				endif
			endif

			// Prepara array com o item para a nota
			_aLinha = {}
			AADD(_aLinha , {"D1_COD"     , _aItens [_nItem, .ItensProduto]  , Nil } )
			AADD(_aLinha , {"D1_TES"     , _aItens [_nItem, .ItensTES]    , Nil } )
			AADD(_aLinha , {"D1_LOCAL"   , sb1 -> B1_LOCPAD     , Nil } )
			AADD(_aLinha , {"D1_DESCRI"  , _sDescri             , Nil } )
			AADD(_aLinha , {"D1_GRAU"    , _aItens [_nItem, .ItensGrau]  , Nil } )
			AADD(_aLinha , {"D1_PRM99"   , _aItens [_nItem, .ItensClasEspald]  , Nil } )
			AADD(_aLinha , {"D1_VACLABD" , _aItens [_nItem, .ItensClasLatada]  , Nil } )
			AADD(_aLinha , {"D1_TOTAL"   , _nVlTot              , Nil } )
			AADD(_aLinha , {"D1_VAVOLES" , "KG"                 , Nil } )
			AADD(_aLinha , {"D1_VACONDU" , _aItens [_nItem, .ItensConducao] , Nil } )
			if _sTipoNota == "N"
				AADD(_aLinha , {"D1_UM"      , sb1 -> B1_UM         , Nil } )
				AADD(_aLinha , {"D1_TP"      , sb1 -> B1_TIPO       , Nil } )
				AADD(_aLinha , {"D1_QUANT"   , _nQuant              , Nil } )
				AADD(_aLinha , {"D1_VUNIT"   , _nVlUni              , Nil } )
				AADD(_aLinha , {"D1_PESBRT"  , _nQuant              , Nil } )
				AADD(_aLinha , {"D1_VAVOLQT" , _nQuant              , Nil } )
			else
				AADD(_aLinha , {"D1_VAVOLQT", 1                    , Nil } )
				AADD(_aLinha , {"D1_NFORI",   _aItens [_nItem, .ItensNFOri]  , Nil } )
				AADD(_aLinha , {"D1_SERIORI", _aItens [_nItem, .ItensSerieOri]  , Nil } )
				AADD(_aLinha , {"D1_ITEMORI", right (_aItens [_nItem, .ItensItemOri], _nTamItOr) , '.t.'} )  // Se eu deixar NIL (validacao padrao), nao passa!!!
			endif

			_aLinha = aClone (U_OrdAuto (_aLinha))
			AADD(_aAutoSD1, _aLinha)
		//	U_Log2 ('debug', _aLinha)

			_nVlrUvas += _nVlTot
		next
	endif

	// Prepara valores e datas das parcelas do financeiro, para ser lida pelo P.E. MTColSE2
	// Eh importante manter a integridade do formato dessa array.
	if _lContinua
		
		// Estamos gerando complemento de valor neste momento, com condicoes de pagamento especificas.
		if left (dtos (date ()), 6) == '202305'
			_aParPgSaf = _ParCpl23A (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcela, _sGrpPagto)
		elseif left (dtos (date ()), 6) == '202306'
//			_aParPgSaf = _ParCpl23B (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcela, _sGrpPagto, _nVlrUvas)
			_aParPgSaf = _ParCpl23C (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcela, _sGrpPagto, _nVlrUvas)
		elseif left (dtos (date ()), 6) == '202402'  // Siiiiim, estou complementando 2023 soh agora!
			_aParPgSaf = _ParCpl23D (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcela, _sGrpPagto, _nVlrUvas)
		else
			_aParPgSaf := aclone (U_VA_RusPP (_sSafra, _sGrpPagto, _nVlrUvas, 0, dDataBase))
			if len (_aParPgSaf) == 0
				u_help ("Sem definicao de parcelamento para pagamento.",, .T.)
				_lContinua = .F.
			endif
		endif
	//	U_Log2 ('debug', '_aParPgSaf dentro do VA_GNF2:')
	//	U_Log2 ('debug', _aParPgSaf)
	endif

	if _lContinua .and. len (_aParPgSaf) == 0
		u_help ("Problema na definicao das parcelas.",, .t.)
		_lContinua = .F.
	endif

	// Abre uma transacao para garantir a gravacao de todas as tabelas adicionais.
	begin transaction

	// Gera a NF de Compra
	if _lContinua
		_sErroAuto = ""
		lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
		lMsErroAuto := .F.  // necessario a criacao
		DbSelectArea("SF1")
		dbsetorder (1)
		u_log2 ('info', '[' + procname () + ']Chamando MATA103 para gerar a nota ' + _sNF)
		MsExecAuto({|x,y,z|MATA103(x,y,z)},_aAutoSF1,_aAutoSD1,3)
		If lMsErroAuto
			u_help (_sErroAuto, iif (!empty (NomeAutoLog ()), U_LeErro (memoread (NomeAutoLog ())), ''), .t.)
			_lContinua = .F.
		else
			U_LOG2 ('info', "MATA103 retornou OK.")

			// Apos atualizacao de versao para 22.10 em maio/23 o SF1 deixou de vir posicionado.
			sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
			if ! sf1 -> (dbseek (xfilial ("SF1") + _sNF + _sSerie + _sFornece + _sLoja + _sTipoNota, .f.))
				u_help ("Parece que a nota '" + _sNF + "' nao foi gerada para o fornecedor '" + _sFornece + "'",, .t.)
				_lContinua = .F.
			endif
		endif

		if _lContinua
			U_LOG2 ('info', "NF " + sf1 -> f1_doc + " gerada")

			// Grava dados adicionais na nota.
			if ! empty (_sMsgContr)
				if empty (sf1 -> f1_vacmemc)
					//u_log ('Incluindo memo no SF1:', _sMsgContr)
					msmm(,,,_sMsgContr,1,,,"SF1","F1_VACMEMC")
				else
					_sMemoAnt = alltrim (MSMM (sf1->f1_vacmemc,,,,3))
					//u_log ("Acrescentando '" + _sMsgContr + "' ao memo do SF1, que continha '" + _sMemoAnt + "'")
					msmm (sf1 -> f1_vacmemc,,, _sMemoAnt + '; ' + _sMsgContr, 1,,,"SF1","F1_VACMEMC")
				endif
			endif
	//		u_log ('dados adicionais gravados')

			// Grava no ZZ9 o numero da nota gerada, para evitar geracao em duplicidade.
			dbselectarea ("ZZ9")
			_aAreaZZ9 := GetArea ()
			for _nPreNF = 1 to len (_aPreNF)
				zz9 -> (dbgoto (_aPreNF [_nPreNF]))
				if empty (zz9 -> zz9_nfcomp)
				//	u_log ('Atualizando ZZ9 recno', zz9 -> (recno ()))
					reclock ("ZZ9", .F.)
					zz9 -> zz9_nfComp = sf1 -> f1_doc
					zz9 -> zz9_serCom = sf1 -> f1_serie
					msunlock ()
				else
					u_log2 ("ERRO", 'Tentando atualizar ZZ9, mas ja tem zz9_nfcomp')
				endif
			next
			RestArea (_aAreaZZ9)
	//		u_log ('ZZ9 atualizado')

			// Gera um registro na tabela CDD ("NF referenciadas") que vai ser
			// usado pelo programa NFESEFAZ para geracao do XML para enviar para
			// a SEFAZ. Isso por que a SEFAZ nao aceita NF complementar fazendo
			// referencia a mais de uma NF origem, o que me obrigaria a gerar
			// uma nota de complemento para cada contranota/carga de safra.
			// Entao vou deixar apenas a primeira NF de origem na tabela CDD
			// para que o programa que gera o XML monte a tag <NFRef> a partir
			// dessa tabela, e nao pelos campos D1_NFORI,D1_SERIORI e D1_ITEMORI
		//	U_Log2 ('debug', '[' + procname () + ']Dados para gravar tabela CDD:')
		//	U_Log2 ('debug', _aNFPRur)
			if len (_aNFPRur) != 1
				u_help ("Problemas nos dados para gravar tabela CDD: eu deveria ter apenas 1 linha na array. Verifique log do programa.",, .t.)
				_lContinua = .F.
			else
				reclock ("CDD", .t.)
				cdd -> cdd_filial = xfilial ("CDD")
				cdd -> cdd_tpmov  = 'E'
				cdd -> cdd_doc    = sf1 -> f1_doc
				cdd -> cdd_serie  = sf1 -> f1_serie
				cdd -> cdd_clifor = sf1 -> f1_fornece
				cdd -> cdd_loja   = sf1 -> f1_loja
				cdd -> cdd_chvnfe = _aNFPRur [1, 5]
				msunlock ()
			endif

			// Gera registros na tabela SZH amarrando NF original com NF de
			// complemento. Isso pelos seguintes motivos:
			// - SEFAZ nao aceita NF de complemento referenciando mais de uma NF de origem
			// - Temos muitos casos de um fornecedor trazer diversas cargas de
			//   determinada variedade/grau, e nao quero gerar uma NF complemento
			//   para cada uma. Basta complementar o valor total, reduzindo muito
			//   a quantidade de notas de complemento. Mas isso me faz perder a
			//   amarracao padrao do sistema pelo D1_NFORI+D1_SERIORI+D1_ITEMORI
			//   entao optei por usar a tabela SZH para essa amarracao, de forma
			//   que consigo ainda usar a view VA_VPRECO_EFETIVO_SAFRA.
			for _nItem = 1 to len (_aItens)
		//		U_Log2 ('debug', '[' + procname () + ']Para o item ' + cvaltochar (_nItem) + ' de _aItens eu estaria atendendo os seguintes registros do ZZ9:')
				for _nPreNF = 1 to len (_aItens [_nItem, .ItensRecnosZZ9])
		//			U_Log2 ('debug', '[' + procname () + ']' + cvaltochar (_aItens [_nItem, .ItensRecnosZZ9, _nPreNF]))
					zz9 -> (dbgoto (_aItens [_nItem, .ItensRecnosZZ9, _nPreNF]))
					reclock ("SZH", .T.)
					szh -> zh_filial  = zz9 -> zz9_filial
					szh -> zh_NFSAIDA = 'SAFRA' + zz9 -> zz9_safra
					szh -> zh_fornece = zz9 -> zz9_fornec
					szh -> zh_loja    = zz9 -> zz9_loja
					szh -> zh_Data    = sf1 -> f1_emissao
					szh -> zh_NFFrete = sf1 -> f1_doc
					szh -> zh_SerFret = sf1 -> f1_serie
					szh -> zh_ItNFs   = strzero (_nItem, 2)  // Siiiim, eh um aproveitamento de campos muito descarado!
					szh -> zh_TpFre   = 'E'
					szh -> zh_NFentr  = zz9 -> zz9_nfori
					szh -> zh_Srnfent = zz9 -> zz9_serior
					szh -> zh_ItNFE   = zz9 -> zz9_itemor
					szh -> zh_TpNFEnt = 'N'
					szh -> zh_CliFor  = sf1 -> f1_fornece
					szh -> zh_LjCliFo = sf1 -> f1_loja
					szh -> zh_SeqEntr = "1"
					szh -> zh_Rateio  = zz9 -> ZZ9_QTORI * zz9 -> ZZ9_VUNIT - zz9 -> ZZ9_QTORI * zz9 -> ZZ9_VUNOLD  // Aqui eh melhor revisar sempre
					szh -> zh_TpDesp  = 'S'  // S=Safra
					msunlock ()
				next
			next

			// Guarda intervalo de numeracao para mostrar em mensagem no final do processo.
			if empty (_sNFIni)
				_sNFIni = sf1 -> f1_doc
			endif
			_sNFFim = sf1 -> f1_doc
		endif
	endif

	// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro.
	if _lContinua
		_sQuery := ""
		_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO, E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA"
		_sQuery +=       ", ROW_NUMBER () OVER (ORDER BY E2_PARCELA) AS NUM_PARC"
		_sQuery +=       ", COUNT (*) OVER () AS QT_PARC"
		_sQuery +=   " FROM " + RetSQLName ("SE2")
		_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_sQuery +=    " AND E2_TIPO    = 'NF'"
		_sQuery +=    " AND E2_FORNECE = '" + sf1 -> f1_fornece + "'"
		_sQuery +=    " AND E2_LOJA    = '" + sf1 -> f1_loja    + "'"
		_sQuery +=    " AND E2_PREFIXO = '" + sf1 -> f1_serie   + "'"
		_sQuery +=    " AND E2_NUM     = '" + sf1 -> f1_doc     + "'"
		_sQuery +=    " AND E2_VACHVEX = ''"
		_sQuery +=    " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
//		_sQuery +=    " AND dbo.VA_FTIPO_FORNECEDOR_UVA ('" + sF1 -> F1_FORNECE + "', '" + sF1 -> F1_LOJA + "', '" + dtos (sF1-> F1_EMISSAO) + "') IN ('ASSOCIADO', 'EX ASSOCIADO')"
		_sQuery +=    " AND SUBSTRING (dbo.VA_FTIPO_FORNECEDOR_UVA ('" + sF1 -> F1_FORNECE + "', '" + sF1 -> F1_LOJA + "', '" + dtos (sF1-> F1_EMISSAO) + "'), 1, 1) IN ('1', '3')"  // 1=ASSOCIADO; 3=EX ASSOCIADO
		_sQuery +=  " ORDER BY E2_PARCELA"
		//u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		U_TCSetFld (alias ())
		do while ! (_sAliasQ) -> (eof ())
			//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)
	
			_oCtaCorr := ClsCtaCorr():New ()
			_oCtaCorr:Assoc      = (_sAliasQ) -> e2_fornece
			_oCtaCorr:Loja       = (_sAliasQ) -> e2_loja
			_oCtaCorr:TM         = '13'
			_oCtaCorr:DtMovto    = (_sAliasQ) -> e2_EMISSAO
			_oCtaCorr:Valor      = (_sAliasQ) -> e2_valor
			_oCtaCorr:SaldoAtu   = (_sAliasQ) -> e2_saldo
			_oCtaCorr:Usuario    = cUserName
			_oCtaCorr:Histor     = iif (_sTipoNota == "C", 'COMPL.', '') + 'COMPRA SAFRA ' + _sSafra + iif (! empty (_sGrpPagto), " GRP." + _sGrpPagto, '')
			_oCtaCorr:MesRef     = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
			_oCtaCorr:Doc        = (_sAliasQ) -> e2_num
			_oCtaCorr:Serie      = (_sAliasQ) -> e2_prefixo
			_oCtaCorr:Parcela    = (_sAliasQ) -> e2_parcela
			_oCtaCorr:Origem     = _sOrigSZI
			_oCtaCorr:Safra      = _sSafra
			_oCtaCorr:GrpPgSafra = _sGrpPagto
			if _oCtaCorr:PodeIncl ()
				if ! _oCtaCorr:Grava (.F., .F., ((_sAliasQ) -> num_parc == (_sAliasQ) -> qt_parc))  // Atualiza saldo soh na ultima parcela, para agilizar.
					U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
					_lContinua = .F.
				else
					se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
					if empty (se2 -> e2_vachvex)  // Soh pra garantir...
						reclock ("SE2", .F.)
						se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
						msunlock ()
					endif
				endif
			else
				U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			endif

			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	end transaction

return _lContinua


// --------------------------------------------------------------------------
// Gera array de parcelamento especifico para complemento em maio/2023
Static Function _ParCpl23A (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcel, _sGrpPag)
	local _aParcel   := {}
	local _nParcel   := 0
	local _oSQL      := NIL
	local _aTotForn  := {}
	local _nTotCompl := 0
	local _nPreNF    := 0
	
	// Monta array no mesmo formato gerado pelo VA_RusPP() e que vai ser lido
	// posteriormente pelo P.E. MTColSE2.
	// Eh importante manter a integridade do formato dessa array.
	// As datas jah foram definidas no SE2 durante a safra.
	// Vou gerar os complementos com vencimento um dia antes.
	aadd (_aParcel, {0, stod ('20230530'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'A'})
	aadd (_aParcel, {0, stod ('20230630'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'B'})
	aadd (_aParcel, {0, stod ('20230728'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'C'})
	aadd (_aParcel, {0, stod ('20230830'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'D'})
	aadd (_aParcel, {0, stod ('20230928'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'E'})
	aadd (_aParcel, {0, stod ('20231030'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'F'})
	aadd (_aParcel, {0, stod ('20231129'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'G'})
	aadd (_aParcel, {0, stod ('20231228'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'H'})
	aadd (_aParcel, {0, stod ('20240130'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'I'})
	aadd (_aParcel, {0, stod ('20240228'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'J'})
	// mar/24 eh aux.comb.; nao vou gerar parcela de uva nesse mes. aadd (_aParcel, {0, stod ('20240328'), 0, 0, '', '?'})
	aadd (_aParcel, {0, stod ('20240429'), 0, 0, 'COMPL.SAFRA GRP ' + _sGrpPag, 'K'})

	// Busca o total da safra deste fornecedor (nesta filial) e o valor da
	// parcela jah existente para este mes, de forma que possa, depois,
	// ajustar as parcelas do complemento e pagar 10% do total da safra
	// na primeira parcela (original + complemento).
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "WITH C AS ("
	_oSQL:_sQuery += "SELECT COUNT (ZZ9.ZZ9_PRE_NF) AS QT_PRE_NF"
	_oSQL:_sQuery +=      ", round (SUM (ZZ9_QTORI * ZZ9_VUNIT), 2) AS TOT_NOVO"
	_oSQL:_sQuery +=      ", round (SUM (ZZ9_QTORI * ZZ9_VUNOLD), 2) AS TOT_ORIG"
	_oSQL:_sQuery +=      ", round (SUM (ZZ9_QTORI * ZZ9_VUNOLD * 0.1), 2) AS PARCELA_ORIG"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZ9") + " ZZ9"
	_oSQL:_sQuery += " WHERE ZZ9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9") + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_SAFRA  = '" + _sSafra + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_FORNEC = '" + _sFornece + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_LOJA   = '" + _sLoja + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_PARCEL = '" + _sParcel + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_GRUPO  = '" + _sGrpPag + "'"
	_oSQL:_sQuery +=   " AND ZZ9.ZZ9_NFCOMP = ''"
	
	// Soh quero considerar aqui as mesmas pre-notas que estarei complementando.
	_oSQL:_sQuery +=   " AND ZZ9.R_E_C_N_O_ in ("
	for _nPreNF = 1 to len (_aPreNF)
		_oSQL:_sQuery += cvaltochar (_aPreNF [_nPreNF]) + iif (_nPreNF < len (_aPreNF), ",", "")
	next
	_oSQL:_sQuery += ")"

	_oSQL:_sQuery += " GROUP BY ZZ9_SAFRA, ZZ9_FORNEC, ZZ9_LOJA, ZZ9_NFORI, ZZ9_SERIOR"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " select SUM (QT_PRE_NF), SUM (TOT_NOVO) AS TOT_NOVO, SUM (TOT_ORIG) AS TOT_ORIG, SUM (PARCELA_ORIG) AS PARCELA_ORIG"
	_oSQL:_sQuery += " FROM C"
	//_oSQL:Log ('[' + procname () + ']')
	_aTotForn := aclone (_oSQL:Qry2Array (.f., .f.))
	//U_Log2 ('debug', _aTotForn)

	if _aTotForn [1, 1] != len (_aPreNF)
		u_help ("Nao li a mesma quantidade de pre-notas! Para fechar os 10% do total da safra, tenho que considerar os mesmos registros do ZZ9.",, .t.)
		_aParcel = {}
	else
		// Tot.a pagar em maio = [1a.parc.das NF orig. de safra] + [1a.parc.da NF que estou gerando agora]
		// Esse total a pagar em maio deve representar 10% do total da safra de cada fornecedor.
		//
		// Valor 1a.parc vai ser o total da safra * 10% - o que jah tem (1a.parc.orig)
		_aParcel [1, 4] = round (_aTotForn [1, 2] * 0.1, 2) - _aTotForn [1, 4]
		//
		// O restante do valor desta NF de complemento, vou distribuir nas demais parcelas.
		_nTotCompl = _aTotForn [1, 2] - _aTotForn [1, 3]
		_nTotCompl -= _aParcel [1, 4]
		_nTotDist = 0
		for _nParcel = 2 to len (_aParcel)
			_aParcel [_nParcel, 4] = round (_nTotCompl / (len (_aParcel)-1), 2)
			_nTotDist += _aParcel [_nParcel, 4]
		next
		// Ajusta diferencas na ultima parcela.
		_aParcel [len (_aParcel), 4] += _nTotCompl - _nTotDist
	//	U_Log2 ('debug', '[' + procname () + ']Como ficaram as parcelas:')
	//	U_Log2 ('debug', _aParcel)
	endif
	for _nParcel = 1 to len (_aParcel)
		if _aParcel [_nParcel, 4] <= 0
			u_help ("Parcela negativa ou zerada!",, .t.)
			U_Log2 ('debug', _aParcel)
			_aParcel = {}
			exit
		endif
	next
return _aParcel


// --------------------------------------------------------------------------
// Gera array de parcelamento especifico para complemento em junho/2023
Static Function _ParCpl23B (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcel, _sGrpPag, _nVlrUvas)
	local _aParcel   := {}
	local _nParcel   := 0
	local _nTotCompl := 0

	_nVlrUvas = round (_nVlrUvas, 2)

	// Monta array no mesmo formato gerado pelo VA_RusPP() e que vai ser lido
	// posteriormente pelo P.E. MTColSE2.
	// Eh importante manter a integridade do formato dessa array.
	// As datas jah foram definidas no SE2 durante a safra.
	// Vou gerar os complementos com vencimento um dia antes.
	aadd (_aParcel, {0, stod ('20230630'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'A'})
	aadd (_aParcel, {0, stod ('20230728'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'B'})
	aadd (_aParcel, {0, stod ('20230830'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'C'})
	aadd (_aParcel, {0, stod ('20230928'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'D'})
	aadd (_aParcel, {0, stod ('20231030'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'E'})
	aadd (_aParcel, {0, stod ('20231129'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'F'})
	aadd (_aParcel, {0, stod ('20231228'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'G'})
	aadd (_aParcel, {0, stod ('20240130'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'H'})
	aadd (_aParcel, {0, stod ('20240228'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'I'})
	// mar/24 eh aux.comb.; nao vou gerar parcela de uva nesse mes. aadd (_aParcel, {0, stod ('20240328'), 0, 0, '', '?'})
	aadd (_aParcel, {0, stod ('20240429'), 0, round (_nVlrUvas / 10, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'J'})

	// Ajusta diferencas na ultima parcela.
	_nTotCompl = 0
	for _nParcel = 1 to len (_aParcel)
		_nTotCompl += _aParcel [_nParcel, 4]
	next
	_aParcel [len (_aParcel), 4] += _nVlrUvas - _nTotCompl
	for _nParcel = 1 to len (_aParcel)
		if _aParcel [_nParcel, 4] <= 0
			u_help ("Parcela negativa ou zerada!",, .t.)
			U_Log2 ('debug', _aParcel)
			_aParcel = {}
		endif
	next
return _aParcel


// --------------------------------------------------------------------------
// Gera array de parcelamento especifico para complemento em junho/2023 (Alicante)
Static Function _ParCpl23C (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcel, _sGrpPag, _nVlrUvas)
	local _aParcel   := {}
	local _nParcel   := 0
	local _nTotCompl := 0

	_nVlrUvas = round (_nVlrUvas, 2)

	// Monta array no mesmo formato gerado pelo VA_RusPP() e que vai ser lido
	// posteriormente pelo P.E. MTColSE2.
	// Eh importante manter a integridade do formato dessa array.
	// As datas jah foram definidas no SE2 durante a safra.
	// Vou gerar os complementos com vencimento um dia antes.
	aadd (_aParcel, {0, stod ('20230630'), 0, round (_nVlrUvas / 5    , 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'A'})
	aadd (_aParcel, {0, stod ('20230728'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'B'})
	aadd (_aParcel, {0, stod ('20230830'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'C'})
	aadd (_aParcel, {0, stod ('20230928'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'D'})
	aadd (_aParcel, {0, stod ('20231030'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'E'})
	aadd (_aParcel, {0, stod ('20231129'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'F'})
	aadd (_aParcel, {0, stod ('20231228'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'G'})
	aadd (_aParcel, {0, stod ('20240130'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'H'})
	aadd (_aParcel, {0, stod ('20240228'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'I'})
	// mar/24 eh aux.comb.; nao vou gerar parcela de uva nesse mes. aadd (_aParcel, {0, stod ('20240328'), 0, 0, '', '?'})
	aadd (_aParcel, {0, stod ('20240429'), 0, round (_nVlrUvas / 11.25, 2), 'COMPL.SAFRA GRP ' + _sGrpPag, 'J'})

	// Ajusta diferencas na ultima parcela.
	_nTotCompl = 0
	for _nParcel = 1 to len (_aParcel)
		_nTotCompl += _aParcel [_nParcel, 4]
	next
//	U_Log2 ('debug', '[' + procname () + ']_nTotCompl: ' + cvaltochar (_nTotCompl))
//	U_Log2 ('debug', '[' + procname () + ']_nVlrUvas : ' + cvaltochar (_nVlrUvas))
//	U_Log2 ('debug', '[' + procname () + ']_aParcel antes de ajustar na ultima:')
//	U_Log2 ('debug', _aParcel)
	_aParcel [len (_aParcel), 4] += _nVlrUvas - _nTotCompl
//	U_Log2 ('debug', '[' + procname () + ']_aParcel depois de ajustar na ultima:')
//	U_Log2 ('debug', _aParcel)
	for _nParcel = 1 to len (_aParcel)
		if _aParcel [_nParcel, 4] <= 0
			u_help ("Parcela negativa ou zerada!",, .t.)
			U_Log2 ('debug', _aParcel)
			_aParcel = {}
		endif
	next
return _aParcel


// --------------------------------------------------------------------------
// Gera array de parcelamento especifico para complemento da safra 2023
// cujas notas estao sendo geradas em fev/24 e, portanto, numa unica parcela.
Static Function _ParCpl23D (_aPreNF, _sSafra, _sFornece, _sLoja, _sParcel, _sGrpPag, _nVlrUvas)
	local _aParcel   := {}

	_nVlrUvas = round (_nVlrUvas, 2)

	// Monta array no mesmo formato gerado pelo VA_RusPP() e que vai ser lido
	// posteriormente pelo P.E. MTColSE2.
	// Eh importante manter a integridade do formato dessa array.
	// As datas jah foram definidas no SE2 durante a safra.
	// Vou gerar os complementos com vencimento um dia antes.
	aadd (_aParcel, {0, stod ('20240227'), 0, _nVlrUvas, 'COMPL.SAFRA 2023', 'A'})

return _aParcel


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                    Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},                                       "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "SA2", {},                                       "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},                                       "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "SA2", {},                                       "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},                                       "Safra (ano) para a qual serao geradas as notas de compra."})
	aadd (_aRegsPerg, {06, "Parcelas sep.barras(bco=todas)", "C", 30, 0,  "",   "   ", {},                                       "Parcelas. Geralmente para separar tintorias, organicas, etc. Ex.: A/B/F"})
	aadd (_aRegsPerg, {07, "Grupo pagamento (bco=todos)   ", "C", 1,  0,  "",   "   ", {},                                       "Grupo de produtos (geralmente para gerar parcelamento)"})
	aadd (_aRegsPerg, {08, "Geracao por DCO               ", "C", 1,  0,  "",   "   ", {"Com DCO", "Sem DCO", "Todos"},          "Permite gerar separadamente as notas envolvidas em leilao da CONAB."})
	aadd (_aRegsPerg, {09, "Variedade de uva              ", "N", 1,  0,  "",   "   ", {"Comum", "Fina", "Todas"},               "Permite gerar separadamente as notas por tipo de uva."})
	aadd (_aRegsPerg, {10, "Tipo de nota a gerar          ", "N", 1,  0,  "",   "   ", {"Normais", "Compl.preco"},               "Compl.preco eh sobre as compras feitas a preco minimo do governo."})
	aadd (_aRegsPerg, {11, "Cond.pagto a usar             ", "C", 3,  0,  "",   "SE4", {},                                       ""})
	aadd (_aRegsPerg, {12, "Apenas as varied (separ.por /)", "C", 60, 0,  "",   "   ", {},                                       ""})
	aadd (_aRegsPerg, {13, "Exceto as varied (separ.por /)", "C", 60, 0,  "",   "   ", {},                                       ""})
	aadd (_aRegsPerg, {14, "Tipo de fornecedor            ", "N", 1,  0,  "",   "   ", {"Assoc/ex assoc", "Terceiros", "Todos"}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
return
