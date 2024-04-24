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
#XTranslate .ItensNFProd     => 14
#XTranslate .ItensSNFProd    => 15
#XTranslate .ItensQtColunas  => 15

// --------------------------------------------------------------------------
User Function VA_GNF6(_lAutomat)
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
		_sSerie = GetMv("VA_SERSAFR", .F., '')
		if empty(_sSerie)
			u_help("Serie a ser usada nas NF de safra nao definida. Verifique se o parametro VA_SERSAFR existe e se contem uma serie de NF valida para esta filial.",, .t.)
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
		_sParcelas= alltrim(mv_par06)
		_sGrpZZ9  = mv_par07
		_sVarUva  = mv_par09
		_sTipoNF  = iif(mv_par10 == 1, "V", " ")
		_sCondPag = mv_par11
		_sVariSim = alltrim(mv_par12)
		_sVariNao = alltrim(mv_par13)
		_nTamDesc = tamsx3 ("D1_DESCRI")[1]
		_nTamItem = tamsx3 ("D1_ITEM")[1]
		_nTamItOr = tamsx3 ("D1_ITEMORI")[1]
	endif

	if _lContinua

		// Monta array com os fornecedores ordenados por nome, para facilitar a posterior separacao das notas,
		// e simula varias execucoes da rotina com associado inicial = associado final.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZ9.*, A2_NOME, B1_DESC "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2, "
		_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1  "
		_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '"+ xFilial("SA2") +"' "
		_oSQL:_sQuery +=    " AND SA2.A2_COD     = ZZ9_FORNEC"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = ZZ9_LOJA"
		_oSQL:_sQuery +=    " AND SA2.A2_CONTA  <> '' "
		_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '"+ xFilial("SB1") +"' "
		_oSQL:_sQuery +=    " AND SB1.B1_COD     = ZZ9_PRODUT "
		_oSQL:_sQuery +=    " AND ZZ9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZ9_FILIAL     = '" + xfilial ("ZZ9") + "'"
		_oSQL:_sQuery +=    " AND ZZ9_SAFRA      = '" + _sSafra + "'"
		_oSQL:_sQuery +=    " AND ZZ9_TIPONF     = '" + _sTipoNF + "'"
		if _sTipoNF == 'C'
			_oSQL:_sQuery +=    " AND ZZ9_NFORI <> '' "
		endif
		_oSQL:_sQuery +=    " AND ZZ9_NFCOMP     = ''"
		_oSQL:_sQuery +=    " AND ZZ9_FORNEC + ZZ9_LOJA BETWEEN '" + _sFornIni + _sLojaIni + "' AND '" + _sFornFim + _sLojaFim + "'"
		if ! empty(_sParcelas)
			_oSQL:_sQuery += " AND ZZ9_PARCEL     IN " + FormatIn (_sParcelas, '/')
		endif
		if ! empty(_sGrpZZ9)
			_oSQL:_sQuery += " AND ZZ9_GRUPO      = '" + _sGrpZZ9 + "'"
		endif
		if ! empty(_sVariSim)
			_oSQL:_sQuery += " AND RTRIM (ZZ9_PRODUT) IN " + FormatIn (_sVariSim, '/')
		endif
		if ! empty(_sVariNao)
			_oSQL:_sQuery += " AND RTRIM (ZZ9_PRODUT) NOT IN " + FormatIn (_sVariNao, '/')
		endif
		if mv_par14 == 1 		// Testa a situacao do fornecedor no final de marco (a safra jah deve ter finalizado nessa data)
			_oSQL:_sQuery += " AND ZZ9_TPFORN IN ('1', '3')"
		elseif mv_par14 == 2 	// Testa a situacao do fornecedor no final de marco (a safra jah deve ter finalizado nessa data)
			_oSQL:_sQuery += " AND ZZ9_TPFORN IN ('2')"
		endif
		if _sVarUva == 1 // COMUNS
			_oSQL:_sQuery += " AND B1_VARUVA = 'C' "
		endif
		if _sVarUva == 2 // FINAS
			_oSQL:_sQuery += " AND B1_VARUVA = 'F' "
		endif
		_oSQL:_sQuery +=    " AND ZZ9_GRAU   <> '' "
		_oSQL:_sQuery +=    " AND ZZ9_VUNIT   > 0  "
		_oSQL:_sQuery +=    " AND ZZ9_TES    <> '' "
		_oSQL:_sQuery +=    " AND ZZ9_CONDUC <> '' "
		_oSQL:_sQuery +=    " AND ((ZZ9_CONDUC == 'L' AND ZZ9_CLABD <>'' )OR (ZZ9_CONDUC == 'E' AND ZZ9_CLASSE <>'' )) "
		_oSQL:_sQuery +=  " ORDER BY A2_NOME, ZZ9_FORNEC, ZZ9_LOJA, ZZ9_NFORI, ZZ9_SERIOR "
		_oSQL:Log()
		_sAliasQ := _oSQL:Qry2Trb(.F.)

		if (_sAliasQ) -> (eof())
			u_help ("Nenhuma pre-nota encontrada.", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_lOK := Sx5NumNota(@_sSerie)   // Apresenta Tela para Confirmar o Numero da Primeira NF a Ser Gerada
		if ! _lOK .or. empty(_sSerie)  // Usuario cancelou ou nao confirmou em tempo habil
			U_Log2('info', "Usuario nao confirmou a numeracao da primeira nota.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua((_sAliasQ) -> (reccount()))
		
		do while ! (_sAliasQ) -> (eof())
			incproc()
		
			// Controla quebra por pre-nf, pois cada registro do ZZ9 equivale a um registro
			// de NF de entrada de uva do SD1, mas agora devo somar as quantidades das uvas
			// de mesmo grau e classificacao.
			_sFornece   = (_sAliasQ) -> zz9_fornec
			_sLoja      = (_sAliasQ) -> zz9_loja
			_sPreNF     = (_sAliasQ) -> zz9_pre_nf
			_sNfProd    = (_sAliasQ) -> zz9_nfProd
			_sSNFProd   = (_sAliasQ) -> zz9_snfpro
			_sZZ9NFOri  = (_sAliasQ) -> zz9_nfori
			_sZZ9SNFOri = (_sAliasQ) -> zz9_serior
			_sNfEntr    = ""
			_sCadVitic  = ""
			_sParcela   = (_sAliasQ) -> zz9_parcel

			_aItens     = {}
			_sMsgNfZZ9  = ''
			_aPreNF     = {}

			do while _lContinua .and. !(_sAliasQ) -> (eof ()) ;
				.and.  (_sAliasQ) -> zz9_filial == xfilial ("ZZ9") ;
				.and.  (_sAliasQ) -> zz9_fornec == _sFornece ;
				.and.  (_sAliasQ) -> zz9_loja   == _sLoja ;
				.and.  (_sAliasQ) -> zz9_safra  == _sSafra ;
				.and.  (_sAliasQ) -> zz9_parcel == _sParcela;
				//.and.  (_sAliasQ) -> zz9_nfori  == _sZZ9NFOri;
				//.and.  (_sAliasQ) -> zz9_serior == _sZZ9SNFOri // Em 25/05/18 a SEFAZ jah nao aceitou mais notas referenciando mais de uma NF origem (Rejeicao 255)

                // Existe a possibilidade de diferentes registros de uma mesma
                // variedade/grau/classificacao terem precos unitarios diferentes,
                // seja por mistura, multa, etc... entao preciso
                // acumular tudo em uma array para, depois, calcular o preco medio.
                _nItem = ascan (_aItens, {|_aVal| _aVal [.ItensProduto]    == (_sAliasQ) -> zz9_produt ;
                                            .and. _aVal [.ItensGrau]       == (_sAliasQ) -> zz9_grau ;
                                            .and. _aVal [.ItensClasEspald] == (_sAliasQ) -> zz9_classe ;
                                            .and. _aVal [.ItensClasLatada] == (_sAliasQ) -> zz9_clabd ;
                                            .and. _aVal [.ItensConducao]   == (_sAliasQ) -> zz9_conduc})
                if _nItem == 0
                    aadd (_aItens, array (.ItensQtColunas))
                    _nItem = len (_aItens)
                    _aItens [_nItem, .ItensProduto]    = (_sAliasQ) -> zz9_produt
                    _aItens [_nItem, .ItensDescricao]  = (_sAliasQ) -> b1_desc
                    _aItens [_nItem, .ItensGrau]       = (_sAliasQ) -> zz9_grau
                    _aItens [_nItem, .ItensClasEspald] = (_sAliasQ) -> zz9_classe
                    _aItens [_nItem, .ItensClasLatada] = (_sAliasQ) -> zz9_clabd
                    _aItens [_nItem, .ItensQuantidade] = 0
                    _aItens [_nItem, .ItensValorTotal] = 0
                    _aItens [_nItem, .ItensNFOri]      = (_sAliasQ) -> zz9_nfori
                    _aItens [_nItem, .ItensSerieOri]   = (_sAliasQ) -> zz9_serior
                    _aItens [_nItem, .ItensItemOri]    = (_sAliasQ) -> zz9_itemor
                    _aItens [_nItem, .ItensConducao]   = (_sAliasQ) -> zz9_conduc
                    _aItens [_nItem, .ItensTES]        = (_sAliasQ) -> zz9_tes
                    _aItens [_nItem, .ItensNFProd]     = (_sAliasQ) -> zz9_nfprod
                    _aItens [_nItem, .ItensSNFProd]    = (_sAliasQ) -> zz9_snfpro
                    _aItens [_nItem, .ItensRecnosZZ9]  = {}
                endif

                // Mantem uma lista dos registros do ZZ9 atendidos por este item da NF de complemento.
                aadd (_aItens [_nItem, .ItensRecnosZZ9], (_sAliasQ) -> (recno ()))

                _aItens [_nItem, .ItensValorTotal] += (_sAliasQ) -> zz9_vunit

                // Alimenta lista de mensagens para a nota.
                if ! empty (zz9 -> zz9_msgNF) .and. ! alltrim (zz9 -> zz9_msgNF) $ _sMsgNfZZ9
                    _sMsgNFZZ9 += ' ' + alltrim (zz9 -> zz9_msgNF)
                endif

				U_LOG2('DEBUG', _aitens)
					
                // Prepara dados adicionais
                _sMsgContr = ""
                if ! empty (_sMsgNfZZ9)
                    _sMsgContr += iif (! empty (_sMsgContr), "; ", "") + _sMsgNfZZ9
                endif

				_lGerouNF = _GeraNota (_sTipoNF, sa2 -> a2_cod, sa2 -> a2_loja, _aItens, _sMsgContr, _sSerie, sa2 -> a2_est, _sDCO, _aPreNF, _sSafra, _sCondPag, _sParcela, _sGrpZZ9)

                (_sAliasQ) -> (dbskip())
            enddo
		enddo
	endif

	if ! _lContinua
		u_help ("PROCESSO CANCELADO. Notas ja' geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	else
		u_help ("Processo finalizado. Notas geradas: de '" + _sNFIni + "' a '" + _sNFFim + "'")
	endif
		
	// Notifica interessados.
	if _sNFIni != _sNFFim
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
	local _sMemoAnt  := ""
	local _nPreNF    := 0
	local _nVlrUvas  := 0
	private _aParPgSaf := {}  // Parcelas pre calculadas. Deixar PRIVATE para ser lida pelo ponto de entrada MTCOLSE2().

	// Busca a Proxima NF da Sequencia
	if _lContinua
		_sNF = NxtSX5Nota (_sSerie)

		// Prepara campos do cabecalho da nota
		_aAutoSF1 := {}
		AADD( _aAutoSF1, { "F1_DOC"      , _sNF,           	Nil } )
		AADD( _aAutoSF1, { "F1_SERIE"    , _sSerie,        	Nil } )
		AADD( _aAutoSF1, { "F1_TIPO"     , "C",             Nil } )
		AADD( _aAutoSF1, { "F1_TPCOMPL"  , '1',             Nil } )
		AADD( _aAutoSF1, { "F1_FORMUL"   , "S",             Nil } )
		AADD( _aAutoSF1, { "F1_EMISSAO"  , dDataBase,       Nil } )
		AADD( _aAutoSF1, { "F1_FORNECE"  , _sFornece,       Nil } )
		AADD( _aAutoSF1, { "F1_LOJA"     , _sLoja,          Nil } )
		AADD( _aAutoSF1, { "F1_EST"      , _sUF,            Nil } )
		AADD( _aAutoSF1, { "F1_ESPECIE"  , "SPED",          Nil } )
		AADD( _aAutoSF1, { "F1_COND"     , _sCondPag,       Nil } )
		AADD( _aAutoSF1, { "F1_STATUS"   , 'A',             Nil } )
		AADD( _aAutoSF1, { "F1_VANFPRO"  , _aNFPRur [1, 1], Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASEPRO"  , _aNFPRur [1, 2], Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VASAFRA"  , _sSafra,         Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAGPSAF"  , _sGrpPagto,      Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I
		AADD( _aAutoSF1, { "F1_VAFLAG"   , 'G',             Nil } )  // Campo customizado, serah tratado pelo P.E. SF1100I. Indica 'nota ja gerada' para a rotina de manut. XML

		u_log ("Fornecedor:", _sFornece, _sLoja)

		// Prepara itens da nota
		_nVlrUvas = 0
		_aAutoSD1 = {}

		for _nItem = 1 to len (_aItens)

			sb1 -> (dbsetorder(1))
			sb1 -> (dbseek (xfilial("SB1") + _aItens [_nItem, .ItensProduto], .F.))
			
			// Monta descricao com grau e classificacao da uva. Inicia com o grau e classificacao, reduzindo o nome da uva caso necessario.
			_sDescri = " Gr:" + alltrim (_aItens [_nItem, .ItensGrau])
			if ! empty (_aItens [_nItem, 4])  // Classificacao espaldeira (DS/D/C/B/A/AA)
				_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasEspald])
			elseif ! empty (_aItens [_nItem, 5])  // Classificacao latada (A/B/D)
				_sDescri += " Clas.:" + alltrim (_aItens [_nItem, .ItensClasLatada])
			endif
			_sDescri = left (alltrim (_aItens [_nItem, .ItensDescricao]), _nTamDesc - len (_sDescri)) + _sDescri

			// Arredonda valor total p/ 2 casas p/ compatibilizar com SFT, SF3, SE2, contabilizacao, SPED, etc...
			if _sTipoNota == "N" // nf compras
				_nQuant = round (_aItens [_nItem, .ItensQuantidade], _nTamD1Qt)
				_nVlUni = _aItens [_nItem, .ItensValorTotal] / _nQuant
				_nVlTot = round (_nQuant * _nVlUni, 2)
			else
				_nQuant = 0
				_nVlUni = 0
				_nVlTot = round (_aItens [_nItem, .ItensValorTotal], 2)
			endif

            if fBuscaCpo ("SF4", 1, xfilial ("SF4") + _aItens [_nItem, .ItensTES], "F4_ESTOQUE") == 'S'
                _lContinua = u_msgnoyes ("Para notas de complemento, o TES (" + _aItens [_nItem, .ItensTES] + ") nao deve atualizar estoque, pois afeta o custo medio. Como eh comum gerarmos complemento depois que a uva nao tem mais estoque, usa-se uma funcao customizada para jogar o complemento de safra nos itens de granel. Confirma assim mesmo?")
                if ! _lContinua
                    exit
                endif
            endif

			// Prepara array com o item para a nota
			_aLinha = {}
			AADD(_aLinha , {"D1_COD"     , _aItens [_nItem, .ItensProduto]      , Nil } )
			AADD(_aLinha , {"D1_TES"     , _aItens [_nItem, .ItensTES]          , Nil } )
			AADD(_aLinha , {"D1_LOCAL"   , sb1 -> B1_LOCPAD                     , Nil } )
			AADD(_aLinha , {"D1_DESCRI"  , _sDescri                             , Nil } )
			AADD(_aLinha , {"D1_GRAU"    , _aItens [_nItem, .ItensGrau]         , Nil } )
			AADD(_aLinha , {"D1_PRM99"   , _aItens [_nItem, .ItensClasEspald]   , Nil } )
			AADD(_aLinha , {"D1_VACLABD" , _aItens [_nItem, .ItensClasLatada]   , Nil } )
			AADD(_aLinha , {"D1_TOTAL"   , _nVlTot                              , Nil } )
			AADD(_aLinha , {"D1_VAVOLES" , "KG"                                 , Nil } )
			AADD(_aLinha , {"D1_VACONDU" , _aItens [_nItem, .ItensConducao]     , Nil } )
			AADD(_aLinha , {"D1_VAVOLQT" , 1                                    , Nil } )
			AADD(_aLinha , {"D1_NFORI"   ,   _aItens [_nItem, .ItensNFOri]      , Nil } )
			AADD(_aLinha , {"D1_SERIORI" , _aItens [_nItem, .ItensSerieOri]     , Nil } )
			AADD(_aLinha , {"D1_ITEMORI" , right (_aItens [_nItem, .ItensItemOri], _nTamItOr) , '.t.'} )  // Se eu deixar NIL (validacao padrao), nao passa!!!

			_aLinha = aClone (U_OrdAuto (_aLinha))
			AADD(_aAutoSD1, _aLinha)
			U_Log2 ('debug', _aLinha)

			_nVlrUvas += _nVlTot
		next
	endif

	// Prepara valores e datas das parcelas do financeiro, para ser lida pelo P.E. MTColSE2
	// Eh importante manter a integridade do formato dessa array.
	if _lContinua

        _aParPgSaf := aclone (U_VA_RusPP (_sSafra, _sGrpPagto, _nVlrUvas, 0, dDataBase))
        if len (_aParPgSaf) == 0
            u_help ("Sem definicao de parcelamento para pagamento.",, .T.)
            _lContinua = .F.
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
			if ! sf1 -> (dbseek (xfilial ("SF1") + _sNF + _sSerie + _sFornece + _sLoja + "C", .f.))
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
					msmm(sf1 -> f1_vacmemc,,, _sMemoAnt + '; ' + _sMsgContr, 1,,,"SF1","F1_VACMEMC")
				endif
			endif
	        // u_log ('dados adicionais gravados')

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
				//	szh -> zh_Rateio  = zz9 -> ZZ9_QTORI * zz9 -> ZZ9_VUNIT - zz9 -> ZZ9_QTORI * zz9 -> ZZ9_VUNOLD  // Aqui eh melhor revisar sempre
					szh -> zh_Rateio  = zz9 -> ZZ9_VUNIT  // Aqui eh melhor revisar sempre. Deve ficar igual ao D1_TOTAL
					szh -> zh_TpDesp  = 'S'  // S=Safra
					msunlock ()

                    reclock ("ZZ9", .F.)
					zz9 -> zz9_nfComp = sf1 -> f1_doc
					zz9 -> zz9_serCom = sf1 -> f1_serie
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
			_oCtaCorr:Histor     = 'COMPL. COMPRA SAFRA ' + _sSafra + iif (! empty (_sGrpPagto), " GRP." + _sGrpPagto, '')
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
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                    Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},                                       "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "SA2", {},                                       "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},                                       "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "SA2", {},                                       "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},                                       "Safra (ano) para a qual serao geradas as notas de compra."})
	//aadd (_aRegsPerg, {06, "Parcelas sep.barras(bco=todas)", "C", 30, 0,  "",   "   ", {},                                       "Parcelas. Geralmente para separar tintorias, organicas, etc. Ex.: A/B/F"})
	aadd (_aRegsPerg, {06, "Sequencia(bco=todas)          ", "C", 30, 0,  "",   "   ", {},                                       "Parcelas. Geralmente para separar tintorias, organicas, etc. Ex.: A/B/F"})
	aadd (_aRegsPerg, {07, "Grupo pagamento               ", "C", 1,  0,  "",   "   ", {},                                       "Grupo de produtos (geralmente para gerar parcelamento)"})
	aadd (_aRegsPerg, {08, "PARAMETRO EM DESUSO           ", "C", 1,  0,  "",   "   ", {},          						     "Permite gerar separadamente as notas envolvidas em leilao da CONAB."})
	aadd (_aRegsPerg, {09, "Variedade de uva              ", "N", 1,  0,  "",   "   ", {"Comum", "Fina", "Todas"},               "Permite gerar separadamente as notas por tipo de uva."})
	aadd (_aRegsPerg, {10, "Tipo de nota a gerar          ", "N", 1,  0,  "",   "   ", {"Complemento"},                          "Compl.preco eh sobre as compras feitas a preco minimo do governo."})
	aadd (_aRegsPerg, {11, "Cond.pagto a usar             ", "C", 3,  0,  "",   "SE4", {},                                       ""})
	aadd (_aRegsPerg, {12, "Apenas as varied (separ.por /)", "C", 60, 0,  "",   "   ", {},                                       ""})
	aadd (_aRegsPerg, {13, "Exceto as varied (separ.por /)", "C", 60, 0,  "",   "   ", {},                                       ""})
	aadd (_aRegsPerg, {14, "Tipo de fornecedor            ", "N", 1,  0,  "",   "   ", {"Assoc/ex assoc", "Terceiros", "Todos"}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
return
