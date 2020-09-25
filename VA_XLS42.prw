// Programa:   VA_XLS42
// Autor:      Robert Koch
// Data:       29/03/2019
// Descricao:  Exporta notas de compra para fins de comprovacao junto a bancos, para emprestimos EGF
//             Criado com base em consulta equivalente que existia no 'consultas web'
//
// Historico de alteracoes:
// 26/08/2019 - Robert - Incluidas notas de complemento, coluna identificando safra e tipo de nota.
//

// --------------------------------------------------------------------------
user function VA_XLS42 (_lAutomat)
	Local cCadastro := "Relatorio auxiliar para financiamentos EGF"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para ver valores.
	if ! U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt)
		u_help ("Usuario sem liberacao para esta rotina (grupo 051).")
		return
	endif

	Private cPerg   := "VAXLS42"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays, cCadastro)
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet


	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += " SELECT SAFRA, TIPO_NF, RTRIM (V.NOME_ASSOC) AS NOME_ASSOCIADO,"
	_oSQL:_sQuery +=        " dbo.VA_FORMATA_CGC (SA2.A2_CGC) AS CPF,"
	_oSQL:_sQuery +=        " SM0.M0_FILIAL AS FILIAL,"
	_oSQL:_sQuery +=        " V.DOC AS NF,"
	_oSQL:_sQuery +=        " V.PRODUTO AS PRODUTO,"
	_oSQL:_sQuery +=        " RTRIM (V.DESCRICAO) AS DESCRICAO,"
	_oSQL:_sQuery +=        " V.DATA AS EMISSAO,"
	_oSQL:_sQuery +=        " CASE V.FINA_COMUM WHEN 'C' THEN 'COMUM' WHEN 'F' THEN 'FINA' ELSE '' END AS TIPO_UVA,"
	_oSQL:_sQuery +=        " CASE V.COR WHEN 'T' THEN 'TINTA' WHEN 'B' THEN 'BRANCA' WHEN 'R' THEN 'ROSADA' ELSE '' END AS COR_UVA,"
	_oSQL:_sQuery +=        " V.GRAU AS GRAU,"
	_oSQL:_sQuery +=        " CASE WHEN V.SIST_CONDUCAO = 'L' THEN V.CLAS_ABD ELSE CASE WHEN V.SIST_CONDUCAO = 'E' THEN V.CLAS_FINAL ELSE '' END END AS CLASSIFICACAO,"
	_oSQL:_sQuery +=        " V.PESO_LIQ AS QUANTIDADE,"
	_oSQL:_sQuery +=        " RTRIM (A2_MUN) AS MUNICIPIO,"
	_oSQL:_sQuery +=        " V.DOC AS NF_COMPRA,"
	_oSQL:_sQuery +=        " V.VALOR_TOTAL AS VALOR, "
	_oSQL:_sQuery +=        " SF1.F1_CHVNFE, "
	_oSQL:_sQuery +=        " A2_COD_MUN, A2_VANRDAP"
	_oSQL:_sQuery +=  " FROM dbo.VA_VNOTAS_SAFRA V,"
	_oSQL:_sQuery +=       " VA_SM0 SM0, "
	_oSQL:_sQuery +=         RetSQLName ("SA2") + " SA2, "
	_oSQL:_sQuery +=         RetSQLName ("SF1") + " SF1 "
	_oSQL:_sQuery += " WHERE V.SAFRA = '" + mv_par01 + "'"
	_oSQL:_sQuery +=   " AND V.DATA BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery +=   " AND V.TIPO_NF in ('C', 'V')"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_COD = V.ASSOCIADO"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA = V.LOJA_ASSOC"
	_oSQL:_sQuery +=   " AND SM0.M0_CODIGO = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=   " AND SM0.M0_CODFIL = V.FILIAL"
	_oSQL:_sQuery +=   " AND SM0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SF1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SF1.F1_FILIAL = V.FILIAL"
	_oSQL:_sQuery +=   " AND SF1.F1_DOC = V.DOC"
	_oSQL:_sQuery +=   " AND SF1.F1_SERIE = V.SERIE"
	_oSQL:_sQuery +=   " AND SF1.F1_FORNECE = V.ASSOCIADO"
	_oSQL:_sQuery +=   " AND SF1.F1_LOJA = V.LOJA_ASSOC"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT SAFRA, 
	_oSQL:_sQuery +=        " CASE TIPO_NF WHEN 'C' THEN 'COMPRA' WHEN 'V' THEN 'COMPLEMENTO' ELSE TIPO_NF END AS TIPO_NF,"
	_oSQL:_sQuery +=        " CPF,NOME_ASSOCIADO, RTRIM (A2_COD_MUN) + '-' + MUNICIPIO AS MUNICIPIO,"
//	_oSQL:_sQuery += " RTRIM (FILIAL) AS FILIAL,NF_ENTRADA,dbo.VA_DTOC (EMISSAO) AS EMISSAO,TIPO_UVA,COR_UVA,RTRIM (PRODUTO) AS PRODUTO, RTRIM (DESCRICAO) AS DESCRICAO,GRAU,CLASSIFICACAO,"
	_oSQL:_sQuery += " RTRIM (FILIAL) AS FILIAL,NF, dbo.VA_DTOC (EMISSAO) AS EMISSAO,TIPO_UVA,COR_UVA,RTRIM (PRODUTO) AS PRODUTO, RTRIM (DESCRICAO) AS DESCRICAO,GRAU,CLASSIFICACAO,"
	_oSQL:_sQuery += " SUM(QUANTIDADE) AS QUANT,"
	_oSQL:_sQuery += " CASE WHEN TIPO_NF = 'V' THEN 0 ELSE SUM(VALOR) / SUM(QUANTIDADE) END AS VLR_UNIT,"
	_oSQL:_sQuery += " SUM(VALOR) AS VALOR,"
	_oSQL:_sQuery += " '''' + F1_CHVNFE AS CHAVE_NFE, A2_VANRDAP"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " WHERE F1_CHVNFE != ''"
//	_oSQL:_sQuery += " GROUP BY NOME_ASSOCIADO,CPF,FILIAL,PRODUTO,DESCRICAO,TIPO_UVA,COR_UVA,GRAU,MUNICIPIO,NF_ENTRADA,EMISSAO,F1_CHVNFE,A2_COD_MUN, CLASSIFICACAO"
	_oSQL:_sQuery += " GROUP BY SAFRA, TIPO_NF, NOME_ASSOCIADO,CPF,FILIAL,PRODUTO,DESCRICAO,TIPO_UVA,COR_UVA,GRAU,MUNICIPIO,NF,EMISSAO,F1_CHVNFE,A2_COD_MUN, CLASSIFICACAO,A2_VANRDAP"
	_oSQL:Log ()
	_oSQL:Qry2Xls ()
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {02, "Data contranota inicial       ", "D", 8,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {03, "Data contranota final         ", "D", 8,  0,  "",   "      ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
