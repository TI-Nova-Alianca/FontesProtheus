// Programa...: VA_XLS56
// Autor......: Cláudia Lionço
// Data.......: 22/09/2021
// Descricao..: Exporta Planilha CST/FISCAL - NF's Entrada
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta Planilha CST/FISCAL - NF's Entrada
// #PalavasChave      #CST #Arquivos_Fiscais
// #TabelasPrincipais #SD1 #SFT #SA2 #SF4
// #Modulos 		  #FIS
//
// Historico de alteracoes:
// 27/09/2021 - Claudia - Adicionado campo F4_CSTPIS
// 19/10/2021 - Claudia - Alterada a data de emissão para data de digitação.
// 12/04/2022 - Claudia - Incluido novos campos. GLPI: 11904
//
// -----------------------------------------------------------------------------------------------------
User Function VA_XLS56 ()
	Local cCadastro := "Exporta CST/FISCAL-NFs Entrada"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	Private cPerg   := "VAXLS56"
    
	_ValidPerg()
	Pergunte(cPerg,.F.)

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

    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   D1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,dbo.VA_DTOC(D1_DTDIGIT) AS DTDIGIT "
    _oSQL:_sQuery += "    ,D1_DOC AS NF "
    _oSQL:_sQuery += "    ,D1_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SD1.D1_FORNECE AS COD_FORNECE "
    _oSQL:_sQuery += "    ,D1_LOJA AS LOJA_FORNECE "
    _oSQL:_sQuery += "    ,RTRIM(A2_NOME) AS NOME_FORNECE "
    _oSQL:_sQuery += "    ,SA2.A2_EST AS UF "
    _oSQL:_sQuery += "    ,RTRIM(D1_COD) AS PRODUTO "
    _oSQL:_sQuery += "    ,RTRIM(B1_DESC) AS DESCRICAO "
    _oSQL:_sQuery += "    ,D1_UM AS UN_MEDIDA "
    _oSQL:_sQuery += "    ,SB1.B1_TIPO AS TIPO_PROD "
    _oSQL:_sQuery += "    ,SD1.D1_VUNIT * SD1.D1_QUANT AS VLR_MERCADORIA "
    _oSQL:_sQuery += "    ,D1_TOTAL + D1_VALIPI + D1_SEGURO + D1_DESPESA + D1_ICMSRET AS VLT_BRUTO "
    _oSQL:_sQuery += "    ,SD1.D1_CF AS CFOP "
    _oSQL:_sQuery += "    ,SD1.D1_TES AS TES "
    _oSQL:_sQuery += "    ,SD1.D1_CLASFIS AS CST_ICMS "
    _oSQL:_sQuery += "    ,SD1.D1_BASEICM AS BASE_ICMS "
    _oSQL:_sQuery += "    ,SD1.D1_VALICM AS VALOR_ICMS "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CSTPIS "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_PIS "
    _oSQL:_sQuery += "    ,D1_BASIMP6 AS BASE_PIS "
    _oSQL:_sQuery += "    ,SD1.D1_ALQIMP6 AS ALIQ_PIS "
    _oSQL:_sQuery += "    ,SD1.D1_VALIMP6 AS VALOR_PIS "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CSTCOF "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_COFINS "
    _oSQL:_sQuery += "    ,D1_BASIMP5 AS BASE_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_ALQIMP5 AS ALIQ_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_VALIMP5 AS VALOR_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_ICMSRET AS ICMSRET "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CTIPI "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_IPI "
    _oSQL:_sQuery += "    ,SD1.D1_BASEIPI AS BASE_IPI "
    _oSQL:_sQuery += "    ,SD1.D1_VALIPI AS VALOR_IPI "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN (B1_VAATO = 'S') THEN 'Cooperativo' "
    _oSQL:_sQuery += " 		    WHEN (B1_VAATO = 'N') THEN 'Nao coop' "
    _oSQL:_sQuery += " 		    ELSE ' ' "
    _oSQL:_sQuery += " 	        END AS ATO "
    _oSQL:_sQuery += "    ,F4_PISCRED AS CRED_PIS_COF "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'P' THEN 'PIS' "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'C' THEN 'COFINS' "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'A' THEN 'AMBOS' "
    _oSQL:_sQuery += " 		    ELSE 'Nenhum dos dois impostos' "
    _oSQL:_sQuery += " 	    END AS PIS_COFINS "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '0' THEN '0=Operacao de venda' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '1' THEN '1=Operacao de venda' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '2' THEN '2=Operacao de compra' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '3' THEN '3=Operacao de compra' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '4' THEN '4=Transf.produtos acabados' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '5' THEN '5=Transf.produtos em elaboracao ' "
    _oSQL:_sQuery += " 		    ELSE '9=Outras' "
    _oSQL:_sQuery += " 	    END AS IND_NAT_FRET "
    _oSQL:_sQuery += "    ,F4_CODBCC AS CODBC "
    _oSQL:_sQuery += "    ,D1_CONTA AS CONTA "
    _oSQL:_sQuery += "    ,F4_CSTPIS AS SIT_TRIB_PIS "
    _oSQL:_sQuery += "    ,F4_CSTCOF AS SIT_TRIB_COF "
    _oSQL:_sQuery += "    ,D1_CUSTO AS CUSTO "
    _oSQL:_sQuery += "    ,F1_ESPECIE AS ESPECIE "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			MAX(SE2.E2_NATUREZ) "
    _oSQL:_sQuery += " 		FROM SE2010 SE2 "
    _oSQL:_sQuery += " 		WHERE SE2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE2.E2_FILIAL    = SD1.D1_FILIAL "
    _oSQL:_sQuery += " 		AND SE2.E2_PREFIXO   = SD1.D1_SERIE "
    _oSQL:_sQuery += " 		AND SE2.E2_NUM       = SD1.D1_DOC "
    _oSQL:_sQuery += " 		AND SE2.E2_FORNECE   = SD1.D1_FORNECE "
    _oSQL:_sQuery += " 		AND SE2.E2_LOJA      = SD1.D1_LOJA) "
    _oSQL:_sQuery += "  AS NATUREZA "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " SA2 "
    _oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA2.A2_FILIAL = ' ' "
    _oSQL:_sQuery += " 			AND SA2.A2_COD = SD1.D1_FORNECE "
    _oSQL:_sQuery += " 			AND SA2.A2_LOJA = SD1.D1_LOJA) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SB1.B1_FILIAL = ' ' "
    _oSQL:_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " SF4 "
    _oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SF4.F4_CODIGO = D1_TES) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF1") + " SF1 "
	_oSQL:_sQuery += " ON (SF1.D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " 	        AND SF1.F1_FILIAL  = SD1.D1_FILIAL "
	_oSQL:_sQuery += " 	        AND SF1.F1_DOC     = SD1.D1_DOC "
	_oSQL:_sQuery += " 	        AND SF1.F1_SERIE   = SD1.D1_SERIE "
	_oSQL:_sQuery += " 	        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
	_oSQL:_sQuery += " 	        AND SF1.F1_LOJA    = SD1.D1_LOJA) "
    _oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SD1.D1_DTDIGIT BETWEEN '"+ DTOS(mv_par01) +"' AND '"+ DTOS(mv_par02) +"' "
    _oSQL:_sQuery += " AND SD1.D1_TIPO <> 'D' "

    _oSQL:_sQuery += " UNION ALL "
    
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   D1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,dbo.VA_DTOC(D1_DTDIGIT) AS DTDIGIT "
    _oSQL:_sQuery += "    ,D1_DOC AS NF "
    _oSQL:_sQuery += "    ,D1_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SD1.D1_FORNECE AS COD_FORNECE "
    _oSQL:_sQuery += "    ,D1_LOJA AS LOJA_FORNECE "
    _oSQL:_sQuery += "    ,RTRIM(A1_NOME) AS NOME_FORNECE "
    _oSQL:_sQuery += "    ,SA1.A1_EST AS UF "
    _oSQL:_sQuery += "    ,RTRIM(D1_COD) AS PRODUTO "
    _oSQL:_sQuery += "    ,RTRIM(B1_DESC) AS DESCRICAO "
    _oSQL:_sQuery += "    ,D1_UM AS UN_MEDIDA "
    _oSQL:_sQuery += "    ,SB1.B1_TIPO AS TIPO_PROD "
    _oSQL:_sQuery += "    ,SD1.D1_VUNIT * SD1.D1_QUANT AS VLR_MERCADORIA "
    _oSQL:_sQuery += "    ,D1_TOTAL + D1_VALIPI + D1_SEGURO + D1_DESPESA + D1_ICMSRET AS VLT_BRUTO "
    _oSQL:_sQuery += "    ,SD1.D1_CF AS CFOP "
    _oSQL:_sQuery += "    ,SD1.D1_TES AS TES "
    _oSQL:_sQuery += "    ,SD1.D1_CLASFIS AS CST_ICMS "
    _oSQL:_sQuery += "    ,SD1.D1_BASEICM AS BASE_ICMS "
    _oSQL:_sQuery += "    ,SD1.D1_VALICM AS VALOR_ICMS "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CSTPIS "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_PIS "
    _oSQL:_sQuery += "    ,D1_BASIMP6 AS BASE_PIS "
    _oSQL:_sQuery += "    ,SD1.D1_ALQIMP6 AS ALIQ_PIS "
    _oSQL:_sQuery += "    ,SD1.D1_VALIMP6 AS VALOR_PIS "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CSTCOF "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_COFINS "
    _oSQL:_sQuery += "    ,D1_BASIMP5 AS BASE_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_ALQIMP5 AS ALIQ_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_VALIMP5 AS VALOR_COFINS "
    _oSQL:_sQuery += "    ,SD1.D1_ICMSRET AS ICMSRET "
    _oSQL:_sQuery += "    ,ISNULL((SELECT "
    _oSQL:_sQuery += " 			FT_CTIPI "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SFT") + " SFT "
    _oSQL:_sQuery += " 		WHERE SFT.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SFT.FT_FILIAL = D1_FILIAL "
    _oSQL:_sQuery += " 		AND SFT.FT_NFISCAL = D1_DOC "
    _oSQL:_sQuery += " 		AND SFT.FT_SERIE = D1_SERIE "
    _oSQL:_sQuery += " 		AND SFT.FT_CLIEFOR = D1_CLIENTE "
    _oSQL:_sQuery += " 		AND SFT.FT_LOJA = SD1.D1_LOJA "
    _oSQL:_sQuery += " 		AND SFT.FT_ITEM = D1_ITEM) "
    _oSQL:_sQuery += " 	, '') AS CST_IPI "
    _oSQL:_sQuery += "    ,SD1.D1_BASEIPI AS BASE_IPI "
    _oSQL:_sQuery += "    ,SD1.D1_VALIPI AS VALOR_IPI "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN (B1_VAATO = 'S') THEN 'Cooperativo' "
    _oSQL:_sQuery += " 		    WHEN (B1_VAATO = 'N') THEN 'Nao coop' "
    _oSQL:_sQuery += " 		    ELSE ' ' "
    _oSQL:_sQuery += " 	        END AS ATO "
    _oSQL:_sQuery += "    ,F4_PISCRED AS CRED_PIS_COF "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'P' THEN 'PIS' "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'C' THEN 'COFINS' "
    _oSQL:_sQuery += " 		    WHEN F4_PISCOF = 'A' THEN 'AMBOS' "
    _oSQL:_sQuery += " 		    ELSE 'Nenhum dos dois impostos' "
    _oSQL:_sQuery += " 	    END AS PIS_COFINS "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '0' THEN '0=Operacao de venda' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '1' THEN '1=Operacao de venda' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '2' THEN '2=Operacao de compra' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '3' THEN '3=Operacao de compra' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '4' THEN '4=Transf.produtos acabados' "
    _oSQL:_sQuery += " 		    WHEN F4_INDNTFR = '5' THEN '5=Transf.produtos em elaboracao ' "
    _oSQL:_sQuery += " 		    ELSE '9=Outras' "
    _oSQL:_sQuery += " 	    END AS IND_NAT_FRET "
    _oSQL:_sQuery += "    ,F4_CODBCC AS CODBC "
    _oSQL:_sQuery += "    ,D1_CONTA AS CONTA "
    _oSQL:_sQuery += "    ,F4_CSTPIS AS SIT_TRIB_PIS "
    _oSQL:_sQuery += "    ,F4_CSTCOF AS SIT_TRIB_COF
    _oSQL:_sQuery += "    ,D1_CUSTO AS CUSTO "
    _oSQL:_sQuery += "    ,F1_ESPECIE AS ESPECIE "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			MAX(SE2.E2_NATUREZ) "
    _oSQL:_sQuery += " 		FROM SE2010 SE2 "
    _oSQL:_sQuery += " 		WHERE SE2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE2.E2_FILIAL    = SD1.D1_FILIAL "
    _oSQL:_sQuery += " 		AND SE2.E2_PREFIXO   = SD1.D1_SERIE "
    _oSQL:_sQuery += " 		AND SE2.E2_NUM       = SD1.D1_DOC "
    _oSQL:_sQuery += " 		AND SE2.E2_FORNECE   = SD1.D1_FORNECE "
    _oSQL:_sQuery += " 		AND SE2.E2_LOJA      = SD1.D1_LOJA) "
    _oSQL:_sQuery += "  AS NATUREZA "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = ' ' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SD1.D1_FORNECE "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SD1.D1_LOJA) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SB1.B1_FILIAL = ' ' "
    _oSQL:_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " SF4 "
    _oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SF4.F4_CODIGO = D1_TES) "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF1") + " SF1 "
	_oSQL:_sQuery += " ON (SF1.D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " 	        AND SF1.F1_FILIAL  = SD1.D1_FILIAL "
	_oSQL:_sQuery += " 	        AND SF1.F1_DOC     = SD1.D1_DOC "
	_oSQL:_sQuery += " 	        AND SF1.F1_SERIE   = SD1.D1_SERIE "
	_oSQL:_sQuery += " 	        AND SF1.F1_FORNECE = SD1.D1_FORNECE "
	_oSQL:_sQuery += " 	        AND SF1.F1_LOJA    = SD1.D1_LOJA) "
    _oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SD1.D1_DTDIGIT BETWEEN '"+ DTOS(mv_par01) +"' AND '"+ DTOS(mv_par02) +"' "
    _oSQL:_sQuery += " AND SD1.D1_TIPO = 'D' "
    _oSQL:_sQuery += " ORDER BY DTDIGIT, NF, PRODUTO  "

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
