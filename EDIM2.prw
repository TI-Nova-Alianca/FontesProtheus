// Programa...: EDIM2
// Autor......: Robert Koch
// Data.......: 25/08/2008 (inicio)
// Descricao..: Exportacao de arquivo TXT com dados de notas fiscais para EDI no modelo Mercador.
//
// Historico de alteracoes:
// 17/01/2011 - Robert  - Soh exporta, em modo automatico, notas ainda nao exportadas.
// 10/05/2011 - Robert  - Grava evento apos exportacao da nota para EDI.
// 21/08/2012 - Robert  - Passa a gerar sequencia para nome de arquivo a partir do parametro VA_SEQEDIN.
// 10/09/2013 - Robert  - Criado tratamento para o campo a1_vacpedi
// 06/08/2014 - Robert  - Aglutina valores de um mesmo produto no SD2.
// 23/03/2016 - Robert  - Mesmo sem selecionar nenhuma NF, gerava arquivo vazio.
// 30/07/2019 - Andre   - Alterado utilização do campo B1_VADUNCX pelo campo padrão B1_CODBAR.
//					    - Alterado utilização do campo B1_VAEANUN pelo campo padrão B5_2CODBAR.
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
// 28/10/2019 - Robert  - Ajustado nome campo 
// --------------------------------------------------------------------------
User Function EDIM2 (_lAutomat, _dDataIni, _dDataFim, _sCliIni, _sCliFim, _sNFIni, _sNFFim, _sSerie, _sDirDest)
	Local cCadastro  := "Exportacao arquivos EDI de notas fiscais - padrao Mercador"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.  // Para controlar se o usuario acessou as perguntas.
	private cPerg    := "EDIM2_"
	private _lauto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	if alltrim (sm0 -> m0_cgc) != '88612486000160'
		u_help ("No momento, somente a matriz estah autorizada a usar EDI")
		return
	endif

	_validPerg()
	Pergunte(cPerg,.F.)

	if ! _lAuto
		// Cria as perguntas na tabela SX1
	
		AADD(aSays," ")
		AADD(aSays,"Este programa tem como objetivo gerar arquivo de EDI com dados de,")
		AADD(aSays,"notas fiscais, no padrao Mercador.")
		AADD(aSays,"")
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _BatchTOK() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			processa ({|| _AndaLogo ()})
		EndIf
	else
		mv_par01 = _dDataIni
		mv_par02 = _dDataFim
		mv_par03 = _sCliIni
		mv_par04 = _sCliFim
		mv_par05 = _sNFIni
		mv_par06 = _sNFFim
		mv_par07 = _sSerie
		mv_par08 = _sDirDest
		processa ({|| _AndaLogo ()})
	endif
return



// --------------------------------------------------------------------------
// Verifica 'Tudo OK' do FormBatch.
Static Function _BatchTOK ()
	Local _lRet    := .T.
	if empty (mv_par08) .or. right (alltrim (mv_par08), 1) != "\"
		u_help ("Caminho invalido para geracao do arquivo. Deve ser terminado por '\'")
		_lRet = .F.
	endif
Return _lRet



// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _lContinua  := .T.
	local _aArqTrb    := {}
	//local _aJahExist  := ""
	local _sSeqArq    := ""
	local _sQuery     := ""
	local _aColunas   := ""
	local _aOpcoes    := {}
	local _nOpcao     := 0
	local _sDtArq     := ""
	private _aGerados := {}

	// Monta um markbrowse com as notas fiscais que constam dentro dos parametros,
	// para que o usuario possa selecionar quais serao enviadas por EDI.
	if _lContinua
		_sQuery := ""
		_sQuery += " select '' as OK, F2_EMISSAO, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, A1_NOME, F2_TRANSP, A4_NOME"
		_sQuery += "   from " + RetSQLName ("SF2") + " SF2, "
		_sQuery +=              RetSQLName ("SA1") + " SA1, "
		_sQuery +=              RetSQLName ("SA4") + " SA4  "
		_sQuery += "  where SF2.D_E_L_E_T_ = ''"
		_sQuery += "    and SA1.D_E_L_E_T_ = ''"
		_sQuery += "    and SA4.D_E_L_E_T_ = ''"
		_sQuery += "    and F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sQuery += "    and A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sQuery += "    and A4_FILIAL  = '" + xfilial ("SA4") + "'"
		_sQuery += "    and A1_COD     = F2_CLIENTE"
		_sQuery += "    and A1_LOJA    = F2_LOJA"
		_sQuery += "    and A4_COD     = F2_TRANSP"
		_sQuery += "    and F2_TIPO    = 'N'"
		_sQuery += "    and F2_EMISSAO BETWEEN '" + DTOS (MV_PAR01) + "' AND '" + DTOS (MV_PAR02) + "'"
		_sQuery += "    and F2_CLIENTE BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "'"
		_sQuery += "    and F2_DOC     BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "'"
		_sQuery += "    and F2_SERIE   = '" + MV_PAR07 + "'"

		// Nao reexporta notas em modo automatico (batch)
		if _lAuto
			_sQuery += " and F2_VAEDIM != 'S'"
		endif

		_aOpcoes = aclone (U_Qry2Array (_sQuery))
		if len (_aOpcoes) == 0
			u_help ("Nao foram encontradas notas fiscais dentro dos parametros informados (clientes entre " + mv_par03 + ' e ' + mv_par04 + ")")
			_lContinua = .F.
		else

			// Varre a array de opcoes convertendo a primeira columa para tipo logico.
			// Se for execucao automatica, atribui .T. para todas as linhas.
			for _nOpcao = 1 to len (_aOpcoes)
				_aOpcoes [_nOpcao, 1] = _lAuto
			next
			
			if ! _lAuto
				_aColunas = {}
				aadd (_aColunas, {2,  "Emissao",        35, "@!"})
				aadd (_aColunas, {3,  "NF",             35, "@!"})
				aadd (_aColunas, {4,  "Serie",          20, "@!"})
				aadd (_aColunas, {5,  "Cliente",        35, "@!"})
				aadd (_aColunas, {6,  "Loja",           20, "@!"})
				aadd (_aColunas, {7,  "Nome cliente",   60, "@!"})
				aadd (_aColunas, {8,  "Transp",         45, "@!"})
				aadd (_aColunas, {9,  "Nome transp",    60, "@!"})
				
				// Markbrowse para o usuario selecionar os fretes
				U_MBArray (@_aOpcoes, "Notas fiscais aptas a serem exportadas", _aColunas, 1, oMainWnd:nClientWidth - 40, 400)
			endif
		endif
	endif

	if _lContinua
		_lContinua = .F.
		for _nOpcao = 1 to len (_aOpcoes)
			if _aOpcoes [_nOpcao, 1]
				_lContinua = .T.
				exit
			endif
		next
	endif

	if _lContinua

		// Gera nome para o arquivo (sequencial reinicia a cada dia). Busca a partir de parametro
		// do configurador em vez de ler o diretorio por que o client do Mercador remove os
		// arquivos depois de transmiti-los.
		//
		// Se ainda nao gerou arquivo hoje, pode iniciar pela sequencia 0001
		_sDtArq = left (GetMv ("VA_SEQEDIN"), 8)
		if _sDtArq < dtos (date ())
			_sSeqArq = '0001'
		else
			_sSeqArq = soma1 (substr (GetMv ("VA_SEQEDIN"), 9, 4))
		endif
		//
		// Salva esta data + sequencia como 'jah usada'.
		PutMv ("VA_SEQEDIN", dtos (date ()) + _sSeqArq)

		// Gera nome para o arquivo de saida e deleta o anterior, caso exista, para evitar que os dados sejam concatenados.
		_sArqDest = alltrim (mv_par08) + "NF" + dtos (dDataBase) + _sSeqArq + ".txt"
		delete file (_sArqDest)
		_lContinua = _Exporta (_aOpcoes, @_aArqTrb, _sArqDest)
		if _lContinua
			u_help ("Arquivo gerado:  " + _sArqDest)
		endif
	endif

	U_Arqtrb ("FechaTodos",,,, @_aArqTrb)
return



// --------------------------------------------------------------------------
// Geracao de arquivos temporarios com os dados de notas para exportacao e
// posterior repasse para o arquivo TXT.
Static Function _Exporta (_aOpcoes, _aArqTrb, _sArqDest)
	local _aCampos   := {}
	local _lContinua := .T.
	local _nOpcao    := 0

	// Monta arquivos de trabalho para a exportacao do arquivo de EDI
	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"FunMsg"     , "C", 3 , 0})
		aadd (_aCampos, {"TpNota"     , "C", 3 , 0})
		aadd (_aCampos, {"NF"         , "C", 9 , 0})
		aadd (_aCampos, {"Serie"      , "C", 3 , 0})
		aadd (_aCampos, {"SubSerie"   , "C", 2 , 0})
		aadd (_aCampos, {"DtHrEmis"   , "C", 12, 0})
		aadd (_aCampos, {"DtHrDespac" , "C", 12, 0})
		aadd (_aCampos, {"DtHrEntreg" , "C", 12, 0})
		aadd (_aCampos, {"CFO"        , "C", 5 , 0})
		aadd (_aCampos, {"PedCli"     , "C", 20, 0})
		aadd (_aCampos, {"PdSisEmis"  , "C", 20, 0})
		aadd (_aCampos, {"Contrato"   , "C", 15, 0})
		aadd (_aCampos, {"ListaPreco" , "C", 15, 0})
		aadd (_aCampos, {"EANLocComp" , "C", 13, 0})
		aadd (_aCampos, {"EANLocCobr" , "C", 13, 0})
		aadd (_aCampos, {"EANLocEntr" , "C", 13, 0})
		aadd (_aCampos, {"EANLocForn" , "C", 13, 0})
		aadd (_aCampos, {"EANLocEmis" , "C", 13, 0})
		aadd (_aCampos, {"CNPJComp"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJCobr"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJEntr"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJForn"   , "C", 14, 0})
		aadd (_aCampos, {"CNPJEmis"   , "C", 14, 0})
		aadd (_aCampos, {"Estado"     , "C", 2 , 0})
		aadd (_aCampos, {"Inscr"      , "C", 20, 0})
		aadd (_aCampos, {"TpCodTrans" , "C", 3 , 0})
		aadd (_aCampos, {"CodTrans"   , "C", 14, 0})
		aadd (_aCampos, {"NomeTrans"  , "C", 30, 0})
		aadd (_aCampos, {"TpFrete"    , "C", 3 , 0})
		U_ArqTrb ("Cria", "_cabec", _aCampos, {}, @_aArqTrb)
	
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"CondPag"    , "C", 3 , 0})
		aadd (_aCampos, {"RefData"    , "C", 3 , 0})
		aadd (_aCampos, {"RefTmpData" , "C", 3 , 0})
		aadd (_aCampos, {"TpPeriodo"  , "C", 3 , 0})
		aadd (_aCampos, {"QtPeriodos" , "N", 3 , 0})
		aadd (_aCampos, {"DtVencto"   , "D", 8 , 0})
		aadd (_aCampos, {"TpPercent"  , "C", 3 , 0})
		aadd (_aCampos, {"Percentual" , "N", 5 , 2})
		aadd (_aCampos, {"TpValor"    , "C", 3 , 0})
		aadd (_aCampos, {"Valor"      , "N", 15, 2})
		U_ArqTrb ("Cria", "_pagtos", _aCampos, {}, @_aArqTrb)
	
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"PerDescFin" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescFin" , "N", 15, 2})
		aadd (_aCampos, {"PerDescCom" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescCom" , "N", 15, 2})
		aadd (_aCampos, {"PerDescPro" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescPro" , "N", 15, 2})
		aadd (_aCampos, {"PerEncFin"  , "N", 5 , 2})
		aadd (_aCampos, {"VlrEncFin"  , "N", 15, 2})
		aadd (_aCampos, {"PerEncFre"  , "N", 5 , 2})
		aadd (_aCampos, {"VlrEncFre"  , "N", 15, 2})
		aadd (_aCampos, {"PerEncSeg"  , "N", 5 , 2})
		aadd (_aCampos, {"VlrEncSeg"  , "N", 15, 2})
		U_ArqTrb ("Cria", "_descont", _aCampos, {}, @_aArqTrb)
	
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"NumSeq"     , "N", 4 , 0})
		aadd (_aCampos, {"NumItem"    , "N", 5 , 0})
		aadd (_aCampos, {"TpCodProd"  , "C", 3 , 0})
		aadd (_aCampos, {"CodProd"    , "C", 14, 0})
		aadd (_aCampos, {"RefProd"    , "C", 20, 0})
		aadd (_aCampos, {"UM"         , "C", 3 , 0})
		aadd (_aCampos, {"QtUnidCons" , "N", 5 , 0})
		aadd (_aCampos, {"Quant"      , "N", 15, 2})
		aadd (_aCampos, {"TipoEmbal"  , "C", 3 , 0})
		aadd (_aCampos, {"VlBrutoTot" , "N", 15, 2})
		aadd (_aCampos, {"VlLiqTot"   , "N", 15, 2})
		aadd (_aCampos, {"VlBrutoUni" , "N", 15, 2})
		aadd (_aCampos, {"VlLiqUni"   , "N", 15, 2})
		aadd (_aCampos, {"NumLote"    , "C", 20, 0})
		aadd (_aCampos, {"PedCli"     , "C", 20, 0})
		aadd (_aCampos, {"PesoBruto"  , "N", 15, 2})
		aadd (_aCampos, {"VolBruto"   , "N", 15, 2})
		aadd (_aCampos, {"ClasFiscal" , "C", 14, 0})
		aadd (_aCampos, {"SitTrib"    , "C", 5 , 0})
		aadd (_aCampos, {"CFOP"       , "C", 5 , 0})
		aadd (_aCampos, {"PerDescFin" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescFin" , "N", 15, 2})
		aadd (_aCampos, {"PerDescCom" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescCom" , "N", 15, 2})
		aadd (_aCampos, {"PerDescPro" , "N", 5 , 2})
		aadd (_aCampos, {"VlrDescPro" , "N", 15, 2})
		aadd (_aCampos, {"PerEncFin"  , "N", 5 , 2})
		aadd (_aCampos, {"VlrEncFin"  , "N", 15, 2})
		aadd (_aCampos, {"AliqIPI"    , "N", 5 , 2})
		aadd (_aCampos, {"VlUniIPI"   , "N", 15, 2})
		aadd (_aCampos, {"AliqICM"    , "N", 5 , 2})
		aadd (_aCampos, {"VlUniICM"   , "N", 15, 2})
		aadd (_aCampos, {"AliqICMST"  , "N", 5 , 2})
		aadd (_aCampos, {"VlUniICMST" , "N", 15, 2})
		aadd (_aCampos, {"AliqRBICM"  , "N", 5 , 2})
		aadd (_aCampos, {"VlRBICM"    , "N", 15, 2})
		aadd (_aCampos, {"PerDRepICM" , "N", 5 , 2})
		aadd (_aCampos, {"VlDRepICM"  , "N", 15, 2})
		U_ArqTrb ("Cria", "_itens", _aCampos, {"NumSeq"}, @_aArqTrb)
	
		_aCampos = {}
		aadd (_aCampos, {"TpReg"      , "C", 2 , 0})
		aadd (_aCampos, {"QtLinhas"   , "N", 4 , 0})
		aadd (_aCampos, {"QtTotEmbal" , "N", 15, 2})
		aadd (_aCampos, {"PBruTot"    , "N", 15, 2})
		aadd (_aCampos, {"PLiqTot"    , "N", 15, 2})
		aadd (_aCampos, {"CubagemTot" , "N", 15, 2})
		aadd (_aCampos, {"VlTotLin"   , "N", 15, 2})
		aadd (_aCampos, {"VlTotDesc"  , "N", 15, 2})
		aadd (_aCampos, {"VlTotEnc"   , "N", 15, 2})
		aadd (_aCampos, {"VlTotAbat"  , "N", 15, 2})
		aadd (_aCampos, {"VlTotFret"  , "N", 15, 2})
		aadd (_aCampos, {"VlTotSeg"   , "N", 15, 2})
		aadd (_aCampos, {"VlTotDesp"  , "N", 15, 2})
		aadd (_aCampos, {"BCICM"      , "N", 15, 2})
		aadd (_aCampos, {"TotICM"     , "N", 15, 2})
		aadd (_aCampos, {"BCICMST"    , "N", 15, 2})
		aadd (_aCampos, {"TotICMST"   , "N", 15, 2})
		aadd (_aCampos, {"BCICMRed"   , "N", 15, 2})
		aadd (_aCampos, {"TotICMRed"  , "N", 15, 2})
		aadd (_aCampos, {"BCIPI"      , "N", 15, 2})
		aadd (_aCampos, {"TotIPI"     , "N", 15, 2})
		aadd (_aCampos, {"TotNF"      , "N", 15, 2})
		U_ArqTrb ("Cria", "_sumario", _aCampos, {}, @_aArqTrb)
	endif

	_nOpcao = 1
	do while _lContinua .and. _nOpcao <= len (_aOpcoes)
		if _aOpcoes [_nOpcao, 1]

			// Le dados e exporta para o arquivo de EDI.
			_lContinua = _GeraTXT (_aOpcoes [_nOpcao, 3], _aOpcoes [_nOpcao, 4], _sArqDest)
		endif
		_nOpcao ++
	enddo

return _lContinua



// --------------------------------------------------------------------------
Static Function _GeraTXT (_sNF, _sSerie, _sArqDest)
	local _lContinua := .T.
	local _sPedCli   := ""
	local _oEvento   := NIL
	local _sProduto  := ""
	local _nNumSeq   := 0

	// Limpa arquivos temporarios a cada nota exportada.
	dbselectarea ("_cabec") ; zap
	dbselectarea ("_pagtos") ; zap
	dbselectarea ("_descont") ; zap
	dbselectarea ("_itens") ; zap
	dbselectarea ("_sumario") ; zap

	if _lContinua
		sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL
		if ! sf2 -> (dbseek (xfilial ("SF2") + _sNF + _sSerie, .F.))
			_Erro ("Nota fiscal " + _sNF + "/" + _sSerie + " nao encontrada!")
			_lContinua = .F.
		endif
	endif

	// Posiciona no cliente.
	if _lContinua
		sa1 -> (dbsetorder (1))
		if ! sa1 -> (dbseek (xfilial ("SA1") + sf2 -> f2_cliente + sf2 -> f2_loja, .F.))
			_Erro ("Cliente " + sf2 -> f2_cliente + "/" + sf2 -> f2_loja + " nao encontrado!")
			_lContinua = .F.
		endif
	endif

	// Posiciona na transportadora.
	if _lContinua
		sa4 -> (dbsetorder (1))
		if ! sa4 -> (dbseek (xfilial ("SA4") + sf2 -> f2_transp, .F.))
			_Erro ("Transportadora " + sf2 -> f2_transp + " nao encontrada!")
			_lContinua = .F.
		endif
	endif

	// Posiciona no primeiro item da nota para ter um CFO para o cabecalho.
	if _lContinua
		sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		if ! sd2 -> (dbseek (xfilial ("SD2") + _sNF + _sSerie, .F.))
			_Erro ("Nota fiscal " + _sNF + "/" + _sSerie + " nao tem nenhum item!")
			_lContinua = .F.
		endif
	endif

	// Posiciona no pedido, para preenchimento do cabecalho.
	_sPedCli = ""
	if _lContinua
		if sc5 -> (dbseek (xfilial ("SC5") + sd2 -> d2_pedido, .F.))
			_sPedCli = sc5 -> c5_pedcli
		endif
	endif

	// Monta cabecalho
	if _lContinua
		reclock ("_cabec", .T.)
		_cabec -> TpReg      = "01"
		_cabec -> FunMsg     = "9"
		_cabec -> TpNota     = "380"
		_cabec -> nf         = sf2 -> f2_doc
		_cabec -> serie      = sf2 -> f2_serie
		_cabec -> DtHrEmis   = dtos (sf2 -> f2_emissao) + "0000"
		_cabec -> DtHrDespac = dtos (sf2 -> f2_emissao) + "0000"
		_cabec -> DtHrEntreg = dtos (sf2 -> f2_emissao) + "0000"
		_cabec -> cfo        = sd2 -> d2_cf
		_cabec -> PedCli     = _sPedCli
		_cabec -> EANLocComp = sa1 -> a1_vaEAN
		_cabec -> EANLocCobr = sa1 -> a1_vaEAN
//		_cabec -> EANLocEntr = iif (alltrim (sa1 -> a1_vaEAN) == '7891986000008', '7891986095004', sa1 -> a1_vaEAN) 
		_cabec -> EANLocEntr = sa1 -> a1_vaEANLE 
		_cabec -> EANLocForn = GetMv ("VA_EANLOC")
		_cabec -> EANLocEmis = GetMv ("VA_EANLOC")
		_cabec -> CNPJComp   = sa1 -> a1_cgc
		_cabec -> CNPJCobr   = sa1 -> a1_cgc
		_cabec -> CNPJEntr   = sa1 -> a1_cgc
		_cabec -> CNPJForn   = sm0 -> m0_cgc
		_cabec -> CNPJEmis   = sm0 -> m0_cgc
		_cabec -> Estado     = getmv ("MV_ESTADO")
		_cabec -> Inscr      = sm0 -> m0_insc
		_cabec -> TpCodTrans = "251"
		_cabec -> CodTrans   = sa4 -> a4_cgc
		_cabec -> NomeTrans  = sa4 -> a4_nome
		_cabec -> TpFrete    = iif (sf2 -> f2_tpfrete == "C", "CIF", "FOB")
		msunlock ()
	endif

	// Monta duplicatas
	if _lContinua
		se1 -> (dbsetorder (1))  // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		se1 -> (dbseek (xfilial ("SE1") + sf2 -> f2_serie + sf2 -> f2_doc, .T.))
		do while ! se1 -> (eof ()) .and. se1 -> e1_prefixo == sf2 -> f2_serie .and. se1 -> e1_num == sf2 -> f2_doc
			if alltrim (se1 -> e1_tipo) == "NF"
				reclock ("_pagtos", .T.)
				_pagtos -> TpReg      = "02"
				_pagtos -> CondPag    = "1"
				_pagtos -> RefData    = "66"
				_pagtos -> RefTmpData = "1"
				_pagtos -> TpPeriodo  = "D"
				_pagtos -> QtPeriodos = 1
				_pagtos -> DtVencto   = se1 -> e1_vencrea
				_pagtos -> TpPercent  = "16"  // Juros
				_pagtos -> Percentual = se1 -> e1_vapjuro
				_pagtos -> TpValor    = "262"
				_pagtos -> Valor      = se1 -> e1_valor
				msunlock ()
			endif
			se1 -> (dbSkip ())
		enddo
	endif

	// Monta itens
	if _lContinua
		sb1 -> (dbsetorder (1))
		sc5 -> (dbsetorder (1))
		sb5 -> (dbsetorder (1))
		sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		sd2 -> (dbseek (xfilial ("SD2") + _sNF + _sSerie, .F.))
		do while ! sd2 -> (eof ()) .and. sd2 -> d2_doc == sf2 -> f2_doc .and. sd2 -> d2_serie == sf2 -> f2_serie

			_sProduto = sd2 -> d2_cod
			_nNumSeq  = 1

			// Posiciona produto.
			if ! sB1 -> (dbseek (xfilial ("SB1") + sd2 -> d2_cod, .F.))
				_Erro ("Produto " + sd2 -> d2_cod + " nao cadastrado!")
				_lContinua = .F.
			endif

			// Posiciona pedido.
			if ! sc5 -> (dbseek (xfilial ("SC5") + sd2 -> d2_pedido, .F.))
				_Erro ("Pedido de venda " + sd2 -> d2_pedido + " nao cadastrado!")
				_lContinua = .F.
			endif
			
			// Posiciona SB5.
			if ! sB5 -> (dbseek (xfilial ("SB5") + sd2 -> d2_cod, .F.))
				_Erro ("Produto " + sd2 -> d2_cod + " sem cadastro na tabela SB5.!")
				_lContinua = .F.
			endif
			
			reclock ("_itens", .T.)
			_itens -> TpReg      = "04"
			_itens -> NumSeq     = _nNumSeq
			_itens -> TpCodProd  = "EN"
//			_itens -> CodProd    = iif (sa1 -> a1_vacpedi == "D", sb1 -> B1_VADUNCX, iif (sa1 -> a1_vacpedi == "E", sb1 -> b1_vaEANUn, '?'))
			_itens -> CodProd    = iif (sa1 -> a1_vacpedi == "D", sb1 -> b1_codbar, iif (sa1 -> a1_vacpedi == "E", sb5 -> b5_2codbar, '?'))
			_itens -> UM         = iif (sd2 -> d2_um $ "UN/CX/GF", "EA", "")
			_itens -> QtUnidCons = sb1 -> b1_qtdemb 
			_itens -> TipoEmbal  = iif (sd2 -> d2_um == "UN", "PK", iif (sd2 -> d2_um == "CX", "BX", iif (sd2 -> d2_um == "GF", "BO", "")))
			_itens -> PedCli     = sc5 -> c5_pedcli
			_itens -> ClasFiscal = sb1 -> b1_posipi
			_itens -> SitTrib    = sd2 -> d2_clasfis
			_itens -> CFOP       = sd2 -> d2_cf
			_itens -> AliqICM    = sd2 -> d2_picm

			// Aglutina produto (pode aparecer mais que uma vez na nota por causa dos lotes).
			do while ! sd2 -> (eof ()) .and. sd2 -> d2_doc == sf2 -> f2_doc .and. sd2 -> d2_serie == sf2 -> f2_serie .and. sd2 -> d2_cod == _sProduto
				_itens -> Quant      += sd2 -> d2_quant
				_itens -> VlBrutoTot += sd2 -> d2_total + sd2 -> d2_valipi
				_itens -> VlLiqTot   += sd2 -> d2_total
				_itens -> VlBrutoUni += (sd2 -> d2_total + sd2 -> d2_valipi) / sd2 -> d2_quant
				_itens -> VlLiqUni   += sd2 -> d2_total / sd2 -> d2_quant
				_itens -> PesoBruto  += sd2 -> d2_quant * sb1 -> b1_pesbru
				_itens -> VlrDescFin += sd2 -> d2_descon
				_itens -> VlrEncFin  += sd2 -> d2_despesa
				_itens -> VlUniIPI   += sd2 -> d2_valipi
				_itens -> VlUniICM   += sd2 -> d2_valicm
				_itens -> VlUniICMST += sd2 -> d2_ICMSRet

				sd2 -> (dbSkip ())
			enddo
			msunlock ()
			_nNumSeq ++
		enddo
	endif

	// Monta sumario.
	if _lContinua
		reclock ("_sumario", .T.)
		_sumario -> TpReg      = "09"
		_sumario -> QtLinhas   = _itens -> (reccount ())
		_sumario -> QtTotEmbal = 0
		_sumario -> PBruTot    = sf2 -> f2_pbruto
		_sumario -> PLiqTot    = sf2 -> f2_pliqui
		_sumario -> CubagemTot = 0
		_sumario -> VlTotLin   = sf2 -> f2_valmerc
		_sumario -> VlTotDesc  = 0
		_sumario -> VlTotEnc   = 0
		_sumario -> VlTotAbat  = 0
		_sumario -> VlTotFret  = 0
		_sumario -> VlTotSeg   = 0
		_sumario -> VlTotDesp  = 0
		_sumario -> BCICM      = sf2 -> f2_baseicm
		_sumario -> TotICM     = sf2 -> f2_valicm
		_sumario -> BCICMST    = sf2 -> f2_bricms
		_sumario -> TotICMST   = sf2 -> f2_icmsret
		_sumario -> BCICMRed   = 0
		_sumario -> TotICMRed  = 0
		_sumario -> BCIPI      = sf2 -> f2_baseipi
		_sumario -> TotIPI     = sf2 -> f2_valipi
		_sumario -> TotNF      = sf2 -> f2_valmerc
		msunlock ()
	endif

	// Exporta para TXT
	if _lContinua
		_lContinua = U_DBF2TXT ("_cabec", _sArqDest, .F., .F., 8, .t.)
	endif
	if _lContinua
		_lContinua = U_DBF2TXT ("_pagtos", _sArqDest, .F., .F., 8, .t.)
	endif
	if _lContinua
		_lContinua = U_DBF2TXT ("_descont", _sArqDest, .F., .F., 8, .t.)
	endif
	if _lContinua
		_lContinua = U_DBF2TXT ("_itens", _sArqDest, .F., .F., 8, .t.)
	endif
	if _lContinua
		_lContinua = U_DBF2TXT ("_sumario", _sArqDest, .F., .F., 8, .t.)
	endif

	// Marca a nota como exportada.
	if _lContinua
		reclock ("SF2", .F.)
		sf2 -> f2_vaEDIM = "S"
		msunlock ()

		// Grava evento para posterior consulta.
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SF2011"
		_oEvento:Texto     = "Exportacao via EDI (arq. '" + _sArqDest + "'"
		_oEvento:NFSaida   = sf2 -> f2_doc
		_oEvento:SerieSaid = sf2 -> f2_serie
		_oEvento:Cliente   = sf2 -> f2_cliente
		_oEvento:LojaCli   = sf2 -> f2_loja
		_oEvento:Grava ()
	endif

return _lContinua



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM           DEC           VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Data emissao NF de            ", "D", 8,            0,            "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Data emissao NF ate           ", "D", 8,            0,            "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Cliente de                    ", "C", 6,            0,            "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {04, "Cliente ate                   ", "C", 6,            0,            "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {05, "NF de                         ", "C", _aTamDoc [1], _aTamDoc [2], "",   "SF2", {},    ""})
	aadd (_aRegsPerg, {06, "NF ate                        ", "C", _aTamDoc [1], _aTamDoc [2], "",   "SF2", {},    ""})
	aadd (_aRegsPerg, {07, "Serie notas                   ", "C", 3,            0,            "",   "   ", {},    ""})
	aadd (_aRegsPerg, {08, "Diretorio destino             ", "C", 60,           0,            "",   "DIR", {},    "Diretorio onde sera' gerado o arquivo para envio."})
	U_ValPerg (cPerg, _aRegsPerg)
Return
