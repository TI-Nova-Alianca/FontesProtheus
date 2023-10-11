// Programa...: VA_XLS55
// Autor......: Sandra Sugari / Robert Koch
// Data.......: 19/05/2021
// Descricao..: Exporta Planilha CST/FISCAL.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta Planilha CST/FISCAL
// #PalavasChave      #CST #Arquivos_Fiscais
// #TabelasPrincipais #SD2 #SFT #SA1
// #Modulos 		  #FIS
//
// Historico de alteracoes:
// 19/05/2021 - Sandra  - Criado Exporta Planilha CST/FISCAL - GLPI 10037
// 15/09/2021 - Cláudia - Incluido os tipos D e B no relatorio. GLPI: 10942
// 12/04/2022 - Claudia - Incluido novos campos. GLPI: 11904
//
// -----------------------------------------------------------------------------------------------------
User Function VA_XLS55 (_lAutomat)
	Local cCadastro := "Exporta Planilha CST/FISCAL"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS55"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Gera arquivo
Static Function _Gera()
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D2_FILIAL AS FILIAL"
	_oSQL:_sQuery +=      " ,dbo.VA_DTOC(D2_EMISSAO) AS EMISSAO "
	_oSQL:_sQuery +=      " ,D2_DOC AS NF "
	_oSQL:_sQuery +=      " ,D2_SERIE AS SERIE "
	_oSQL:_sQuery +=      " ,D2_CLIENTE AS COD_CLIENTE "
	_oSQL:_sQuery +=      " ,D2_LOJA AS LOJA_CLIENTE "
	_oSQL:_sQuery +=      " ,RTRIM(A1_NOME) AS NOME_CLIENTE "
	_oSQL:_sQuery +=      " ,D2_EST AS UF "
	_oSQL:_sQuery += " ,CASE SA1.A1_TIPO "
	_oSQL:_sQuery +=      "  WHEN 'F' THEN 'Cons Final' "
	_oSQL:_sQuery +=	  "  WHEN 'L' THEN 'Prod Rural' "
	_oSQL:_sQuery +=	  "  WHEN 'R' THEN 'Revendedor' "
	_oSQL:_sQuery +=	  "  WHEN 'S' THEN 'Solidario' "
	_oSQL:_sQuery +=	  "  WHEN 'X' THEN 'Exportação' "
	_oSQL:_sQuery += " ELSE '' "
	_oSQL:_sQuery +=        " END AS TIPO "
	_oSQL:_sQuery += " ,CASE SA1.A1_PESSOA "
	_oSQL:_sQuery +=        " WHEN 'F' THEN 'FIS' "
	_oSQL:_sQuery += 		" WHEN 'J' THEN 'JUR' "
	_oSQL:_sQuery +=		" WHEN 'X' THEN 'EXT' "
	_oSQL:_sQuery += " ELSE '' "
	_oSQL:_sQuery += 		" END AS TIPO_PESSOA "
	_oSQL:_sQuery += 		" ,RTRIM(D2_COD) AS PRODUTO "
	_oSQL:_sQuery += 		" ,RTRIM(B1_DESC) AS DESCRICAO "
	_oSQL:_sQuery += 		" ,D2_UM AS UN_MEDIDA "
	_oSQL:_sQuery +=        " ,SB1.B1_TIPO AS TIPO_PROD "
	_oSQL:_sQuery += 		" ,SD2.D2_PRCVEN * SD2.D2_QUANT AS VLR_MERCADORIA "
	_oSQL:_sQuery += 		" ,D2_TOTAL + D2_VALIPI + D2_SEGURO + D2_DESPESA + D2_ICMSRET AS VLT_BRUTO "
	_oSQL:_sQuery += 		" ,SD2.D2_CF AS CFOP "
	_oSQL:_sQuery += 		" ,SD2.D2_TES AS TES "
	_oSQL:_sQuery += 		" ,SD2.D2_CLASFIS AS CST_ICMS "
	_oSQL:_sQuery += 		" ,SD2.D2_BASEICM AS BASE_ICMS "
	_oSQL:_sQuery += 		" ,SD2.D2_VALICM AS VALOR_ICMS "
	_oSQL:_sQuery += " ,ISNULL((SELECT "
	_oSQL:_sQuery += 		" FT_CSTPIS "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SFT") + " SFT "
	_oSQL:_sQuery += " WHERE SFT.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" AND SFT.FT_FILIAL = D2_FILIAL "
	_oSQL:_sQuery += 		" AND SFT.FT_NFISCAL = D2_DOC "
	_oSQL:_sQuery += 		" AND SFT.FT_SERIE = D2_SERIE "
	_oSQL:_sQuery += 		" AND SFT.FT_CLIEFOR = D2_CLIENTE "
	_oSQL:_sQuery += 		" AND SFT.FT_LOJA = SD2.D2_LOJA "
	_oSQL:_sQuery += 		" AND SFT.FT_ITEM = D2_ITEM) "
	_oSQL:_sQuery += 		" , '') AS CST_PIS "
	_oSQL:_sQuery += 		" ,D2_BASIMP6 AS BASE_PIS "
	_oSQL:_sQuery += 		" ,SD2.D2_ALQIMP6 AS ALIQ_PIS "
	_oSQL:_sQuery += 		" ,SD2.D2_VALIMP6 AS VALOR_PIS "
	_oSQL:_sQuery += 		" ,ISNULL((SELECT "
	_oSQL:_sQuery += 		" FT_CSTCOF "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SFT") + " SFT "
	_oSQL:_sQuery += 		" WHERE SFT.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" AND SFT.FT_FILIAL = D2_FILIAL "
	_oSQL:_sQuery += 		" AND SFT.FT_NFISCAL = D2_DOC "
	_oSQL:_sQuery += 		" AND SFT.FT_SERIE = D2_SERIE "
	_oSQL:_sQuery += 		" AND SFT.FT_CLIEFOR = D2_CLIENTE "
	_oSQL:_sQuery += 		" AND SFT.FT_LOJA = SD2.D2_LOJA "
	_oSQL:_sQuery += 		" AND SFT.FT_ITEM = D2_ITEM) "
	_oSQL:_sQuery += 		" , '') AS CST_COFINS "
	_oSQL:_sQuery += 		" ,D2_BASIMP5 AS BASE_COFINS "
	_oSQL:_sQuery += 		" ,SD2.D2_ALQIMP5 AS ALIQ_COFINS "
	_oSQL:_sQuery += 		" ,SD2.D2_VALIMP5 AS VALOR_COFINS "
	_oSQL:_sQuery += 		" ,SD2.D2_ICMSRET AS ICMSRET "
	_oSQL:_sQuery += " ,ISNULL((SELECT "
	_oSQL:_sQuery += 		" FT_CTIPI "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SFT") + " SFT "
	_oSQL:_sQuery += " WHERE SFT.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" AND SFT.FT_FILIAL = D2_FILIAL "
	_oSQL:_sQuery += 		" AND SFT.FT_NFISCAL = D2_DOC "
	_oSQL:_sQuery +=		" AND SFT.FT_SERIE = D2_SERIE "
	_oSQL:_sQuery += 		" AND SFT.FT_CLIEFOR = D2_CLIENTE "
	_oSQL:_sQuery += 		" AND SFT.FT_LOJA = SD2.D2_LOJA "
	_oSQL:_sQuery += 		" AND SFT.FT_ITEM = D2_ITEM) "
	_oSQL:_sQuery += 		" , '') AS CST_IPI "
	_oSQL:_sQuery += 		" ,SD2.D2_BASEIPI AS BASE_IPI "
	_oSQL:_sQuery += 		" ,SD2.D2_VALIPI AS VALOR_IPI "
	_oSQL:_sQuery += " ,CASE "
	_oSQL:_sQuery += 		" WHEN (B1_VAATO = 'S') THEN 'Cooperativo' "
	_oSQL:_sQuery += 		" WHEN (B1_VAATO = 'N') THEN 'Nao coop' "
	_oSQL:_sQuery += " ELSE ' ' "
	_oSQL:_sQuery += 		" END AS ATO "
	_oSQL:_sQuery +=        ",F2_ESPECIE AS ESPECIE "
	_oSQL:_sQuery +=        ",D2_CUSTO1 AS CUSTO "
	_oSQL:_sQuery +=        ",SF4.F4_VASITO AS OPER_SISDEVIN "
    _oSQL:_sQuery +=        ",ZX5_57DESC AS OPER_DESCR "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2 "
	_oSQL:_sQuery += " JOIN SA1010 SA1 "
	_oSQL:_sQuery += 		" ON (SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=		" AND SA1.A1_FILIAL = ' ' "
	_oSQL:_sQuery += 		" AND SA1.A1_COD = SD2.D2_CLIENTE "
	_oSQL:_sQuery += 		" AND SA1.A1_LOJA = SD2.D2_LOJA) "
	_oSQL:_sQuery += " JOIN SB1010 SB1 "
	_oSQL:_sQuery += 		" ON (SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" AND SB1.B1_FILIAL = ' ' "
	_oSQL:_sQuery += 		" AND SB1.B1_COD = SD2.D2_COD) "
	_oSQL:_sQuery += " JOIN SF2010 SF2 "
	_oSQL:_sQuery += 		"   ON (SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" 	AND SF2.F2_FILIAL  = SD2.D2_FILIAL "
	_oSQL:_sQuery += 		" 	AND SF2.F2_DOC     = SD2.D2_DOC "
	_oSQL:_sQuery += 		" 	AND SF2.F2_SERIE   = SD2.D2_SERIE "
	_oSQL:_sQuery += 		" 	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
	_oSQL:_sQuery += 		" 	AND SF2.F2_LOJA    = SD2.D2_LOJA) "
	_oSQL:_sQuery += " JOIN SF4010 SF4 "
	_oSQL:_sQuery += 		" 	ON (SF4.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" 	AND F4_CODIGO = SD2.D2_TES) "
	_oSQL:_sQuery += " 	JOIN ZX5010 ZX5_57 "
	_oSQL:_sQuery += 		" 	ON (ZX5_57.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" 	AND ZX5_57.ZX5_TABELA = '57' "
	_oSQL:_sQuery += 		" 	AND ZX5_57.ZX5_57COD = SF4.F4_VASITO) "
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += 		" AND SD2.D2_EMISSAO BETWEEN '"+ DTOS(mv_par01) +"' AND '"+ DTOS(mv_par02) +"' "
	//_oSQL:_sQuery += 		" AND SD2.D2_TIPO NOT IN ('B', 'D') "
	_oSQL:_sQuery += " ORDER BY EMISSAO, NF, PRODUTO "
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Data Final   ", "D", 8,  0,  "",   "   ", {},                   	""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
