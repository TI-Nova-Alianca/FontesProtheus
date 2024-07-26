// Programa...: VA_XLS30
// Autor......: Robert Koch
// Data.......: 15/04/2017
// Descricao..: Exporta planilha com dados de contranotas de safra.
//              Migrado do Reporting Services para ca por que estava faltando memoria no SSRS para renderizar.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Exportacao_planilha
// #Descricao         #Exporta planilha com dados de contranotas de safra.
// #PalavasChave      #safra #contranotas
// #TabelasPrincipais #SD1 #SF1 #SA2 #SZI
// #Modulos           #COOP

// Historico de alteracoes:
// 13/09/2018 - Robert  - Incluída coluna TIPO_ORGANICO.
// 22/10/2018 - Andre   - Incluído campos MUNICIPIO, BAIRRO e VALOR_UNIT. Também adicionado pergunta para TIPO DE NOTA.
// 15/04/2020 - Robert  - Acrescentadas colunas CLAS_LATADA e SIST_CONDUCAO
// 25/02/2021 - Robert  - Passa a buscar grupo familiar na view VA_VASSOC_GRP_FAM (GLPI 8804).
//                      - Abertos parametros para selecionar se vai exportar cada tipo de contranota (GLPI 9489).
// 11/08/2021 - Robert  - View VA_VASSOC_GRP_FAM migrada do database do Protheus para o NaWeb (GLPI 10673).
// 08/09/2021 - Robert  - Incluida coluna de FUNRURAL.
// 23/02/2022 - Robert  - Incluida coluna VALOR_FRETE (GLPI 11665)
// 24/02/2023 - Robert  - Removidas linhas comentariadas.
// 26/07/2024 - Claudia - Incluidos novos campos e versão implificada para financeiro. GLPI:15781
//
// --------------------------------------------------------------------------------------------------------------------
User Function VA_XLS30(_lAutomat)
	Local cCadastro := "Exporta contranotas de safra"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif(valtype(_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	Private cPerg := "VAXLS30"
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
// Geração
Static Function _Gera()
	local _oSQL := NIL

	procregua(10)
	incproc("Gerando arquivo de exportacao")

	// Busca dados
	incproc("Buscando dados")
	_oSQL:= ClsSQL():New()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS (SELECT"
	_oSQL:_sQuery += " NOTAS.SAFRA"
	_oSQL:_sQuery += " ,CASE NOTAS.TIPO_NF"
	_oSQL:_sQuery += " WHEN 'E' THEN 'ENTRADA'"
	_oSQL:_sQuery += " WHEN 'P' THEN 'PROD_PROPRIA'"
	_oSQL:_sQuery += " WHEN 'C' THEN 'COMPRA'"
	_oSQL:_sQuery += " WHEN 'V' THEN 'COMPL DE VALOR'"
	_oSQL:_sQuery += " ELSE NOTAS.TIPO_NF"
	_oSQL:_sQuery += " END AS TIPO_NF"
	_oSQL:_sQuery += " ,NOTAS.FILIAL"
	_oSQL:_sQuery += " ,NOTAS.ASSOCIADO"
	_oSQL:_sQuery += " ,NOTAS.LOJA_ASSOC AS LOJA"
	_oSQL:_sQuery += " ,RTRIM (NOTAS.NOME_ASSOC) AS NOME_ASSOC"
	_oSQL:_sQuery += " ,NOTAS.TIPO_FORNEC"
	_oSQL:_sQuery += " ,NOTAS.PRODUTO"
	_oSQL:_sQuery += " ,CASE NOTAS.FINA_COMUM"
	_oSQL:_sQuery += " WHEN 'F' THEN 'FINA'"
	_oSQL:_sQuery += " WHEN 'C' THEN 'COMUM'"
	_oSQL:_sQuery += " ELSE NOTAS.FINA_COMUM"
	_oSQL:_sQuery += " END AS TIPO"
	_oSQL:_sQuery += " ,CASE NOTAS.COR"
	_oSQL:_sQuery += " WHEN 'T' THEN 'TINTA'"
	_oSQL:_sQuery += " WHEN 'B' THEN 'BRANCA'"
	_oSQL:_sQuery += " WHEN 'R' THEN 'ROSADA'"
	_oSQL:_sQuery += " ELSE NOTAS.COR"
	_oSQL:_sQuery += " END AS COR"
	_oSQL:_sQuery += " ,NOTAS.TINTOREA"
	_oSQL:_sQuery += " ,RTRIM (NOTAS.DESCRICAO) AS DESCRICAO"
	_oSQL:_sQuery += " ,NOTAS.GRAU"
	_oSQL:_sQuery += " ,NOTAS.ACUCAR"
	_oSQL:_sQuery += " ,NOTAS.SANIDADE"
	_oSQL:_sQuery += " ,NOTAS.MATURACAO"
	_oSQL:_sQuery += " ,NOTAS.MAT_ESTRANHO"
	_oSQL:_sQuery += " ,NOTAS.CLAS_FINAL"
	_oSQL:_sQuery += " ,NOTAS.CLAS_ABD"
	_oSQL:_sQuery += " ,NOTAS.SIST_CONDUCAO"
	_oSQL:_sQuery += " ,NOTAS.CAD_VITIC"
	_oSQL:_sQuery += " ,SUM(NOTAS.PESO_LIQ) AS PESO_LIQ"
	_oSQL:_sQuery += " ,NOTAS.VALOR_UNIT AS VALOR_UNIT
	_oSQL:_sQuery += " ,NOTAS.VALOR_TOTAL"
	_oSQL:_sQuery += " ,NOTAS.DOC AS CONTRANOTA, TIPO_ORGANICO"
	_oSQL:_sQuery += " ,dbo.VA_DTOC(NOTAS.DATA) AS DATA,"
	_oSQL:_sQuery += " ISNULL((SELECT TOP 1 CARGA"  // BUSCA CARGA COM 'TOP' POR QUE PODE HAVER MAIS DE UM PRODUTO NA MESMA CARGA.
	_oSQL:_sQuery +=           " FROM VA_VCARGAS_SAFRA CARGAS"
	_oSQL:_sQuery +=          " WHERE CARGAS.FILIAL = NOTAS.FILIAL"
	_oSQL:_sQuery +=            " AND CARGAS.SAFRA = NOTAS.SAFRA"
	_oSQL:_sQuery +=            " AND CARGAS.ASSOCIADO = NOTAS.ASSOCIADO"
	_oSQL:_sQuery +=            " AND CARGAS.LOJA_ASSOC = NOTAS.LOJA_ASSOC"
	_oSQL:_sQuery +=            " AND CARGAS.CONTRANOTA = NOTAS.DOC"
	_oSQL:_sQuery +=            " AND CARGAS.SERIE_CONTRANOTA = NOTAS.SERIE"
	_oSQL:_sQuery +=            " AND CARGAS.PRODUTO = NOTAS.PRODUTO), '') AS CARGA,"
	_oSQL:_sQuery += " ISNULL((SELECT TOP 1 NF_PRODUTOR"  // BUSCA NF PRODUTOR COM 'TOP' POR QUE PODE HAVER MAIS DE UM PRODUTO NA MESMA CARGA.
	_oSQL:_sQuery +=           " FROM VA_VCARGAS_SAFRA CARGAS"
	_oSQL:_sQuery +=          " WHERE CARGAS.FILIAL = NOTAS.FILIAL"
	_oSQL:_sQuery +=            " AND CARGAS.SAFRA = NOTAS.SAFRA"
	_oSQL:_sQuery +=            " AND CARGAS.ASSOCIADO = NOTAS.ASSOCIADO"
	_oSQL:_sQuery +=            " AND CARGAS.LOJA_ASSOC = NOTAS.LOJA_ASSOC"
	_oSQL:_sQuery +=            " AND CARGAS.CONTRANOTA = NOTAS.DOC"
	_oSQL:_sQuery +=            " AND CARGAS.SERIE_CONTRANOTA = NOTAS.SERIE) , '') AS NF_PRODUTOR"
	_oSQL:_sQuery += " , SUM (VLR_FUNRURAL) as VLR_FUNRURAL"
	_oSQL:_sQuery += " , SUM (VALOR_FRETE) as VALOR_FRETE"
	_oSQL:_sQuery += " FROM VA_VNOTAS_SAFRA NOTAS"
	_oSQL:_sQuery += " WHERE SAFRA = '" + mv_par05 + "'"
	if mv_par15 == 2
		_oSQL:_sQuery += " AND TIPO_NF != 'E'"
	endif 
	if mv_par16 == 2
		_oSQL:_sQuery += " AND TIPO_NF != 'P'"
	endif 
	if mv_par17 == 2
		_oSQL:_sQuery += " AND TIPO_NF != 'C'"
	endif 
	if mv_par18 == 2
		_oSQL:_sQuery += " AND TIPO_NF != 'V'"
	endif 
	_oSQL:_sQuery += " AND FILIAL BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	_oSQL:_sQuery += " AND DATA   BETWEEN '" + dtos(mv_par13) + "' AND '" + dtos(mv_par14) + "'"
	_oSQL:_sQuery += " AND ASSOCIADO + LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	if mv_par10 == 1
		_oSQL:_sQuery += " AND FINA_COMUM = 'C'"
	elseif mv_par10 == 2
		_oSQL:_sQuery += " AND FINA_COMUM = 'F'"
	endif
	_oSQL:_sQuery += " GROUP BY	NOTAS.SAFRA, NOTAS.TIPO_FORNEC, NOTAS.FILIAL, NOTAS.ASSOCIADO, NOTAS.LOJA_ASSOC, NOTAS.NOME_ASSOC,"
	_oSQL:_sQuery +=          " NOTAS.PRODUTO, NOTAS.FINA_COMUM, NOTAS.COR, NOTAS.TINTOREA, NOTAS.DESCRICAO,"
	_oSQL:_sQuery +=          " NOTAS.GRAU, NOTAS.ACUCAR, NOTAS.SANIDADE, NOTAS.MATURACAO, NOTAS.MAT_ESTRANHO, NOTAS.CLAS_FINAL,"
	_oSQL:_sQuery +=          " NOTAS.CLAS_ABD, NOTAS.SIST_CONDUCAO, "
	_oSQL:_sQuery +=          " NOTAS.DOC, NOTAS.SERIE, NOTAS.DATA, NOTAS.CAD_VITIC, NOTAS.VALOR_UNIT, NOTAS.VALOR_TOTAL, TIPO_NF, TIPO_ORGANICO"
	_oSQL:_sQuery += ")"
	if mv_par19 == 1
		_oSQL:_sQuery += " SELECT SAFRA ,FILIAL ,SA2.A2_VANUCL AS NUCLEO, "
		_oSQL:_sQuery +=        " RTRIM (ISNULL((SELECT ZX5_36.ZX5_36DESC"
		_oSQL:_sQuery +=                         " FROM " + RetSQLName("ZX5") + " ZX5_36"
		_oSQL:_sQuery +=                        " WHERE ZX5_36.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                          " AND ZX5_36.ZX5_FILIAL = '  '"
		_oSQL:_sQuery +=                          " AND ZX5_36.ZX5_TABELA = '36'"
		_oSQL:_sQuery +=                          " AND ZX5_36.ZX5_36COD = SA2.A2_VASUBNU), '')) AS SUBNUCLEO, SA2.A2_MUN AS MUNICIPIO, SA2.A2_BAIRRO AS BAIRRO, A2_EST AS ESTADO, "

		_oSQL:_sQuery +=        " RTRIM (ISNULL ((SELECT TOP 1 CCAssociadoGrpFamCod + '-' + CCAssociadoGrpFam" // TOP 1 PARA EVITAR POSSIVEL CASO DO ASSOCIADO ESTAR LIGADO A MAIS DE UM GRUPO FAMILIAR"
		_oSQL:_sQuery +=                          " FROM " + U_LkServer('NAWEB') + ".VA_VASSOC_GRP_FAM"
		_oSQL:_sQuery +=                         " WHERE CCAssociadoCod  = C.ASSOCIADO"
		_oSQL:_sQuery +=                           " AND CCAssociadoLoja = C.LOJA), '')) AS GRP_FAMILIAR, "

		_oSQL:_sQuery +=        " TIPO_NF, ASSOCIADO, LOJA ,NOME_ASSOC, A2_CGC AS CPF_CNPJ,"
		_oSQL:_sQuery +=        " TIPO_FORNEC, PRODUTO ,TIPO ,COR ,TINTOREA ,DESCRICAO ,GRAU ,ACUCAR ,SANIDADE ,MATURACAO ,MAT_ESTRANHO, "
		_oSQL:_sQuery +=        " CLAS_FINAL as CLAS_ESPALDEIRA, CLAS_ABD AS CLAS_LATADA, SIST_CONDUCAO, CAD_VITIC ,PESO_LIQ ,CONTRANOTA, VALOR_UNIT, VALOR_TOTAL, DATA ,CARGA ,NF_PRODUTOR,"
		_oSQL:_sQuery +=        " CASE TIPO_ORGANICO WHEN 'C' THEN 'CONVENCIONAL' "
		_oSQL:_sQuery +=                           " WHEN 'E' THEN 'EM CONVERSAO' "
		_oSQL:_sQuery +=                           " WHEN 'B' THEN 'BORDADURA' "
		_oSQL:_sQuery +=                           " WHEN 'O' THEN 'ORGANICA' "
		_oSQL:_sQuery +=        " END AS TIPO_ORGANICO, "
		_oSQL:_sQuery +=        " VLR_FUNRURAL,"
		_oSQL:_sQuery +=        " VALOR_FRETE"
		_oSQL:_sQuery += " FROM	C,"
		_oSQL:_sQuery +=        RetSQLName("SA2") + " SA2"
		_oSQL:_sQuery += " WHERE CARGA BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
		_oSQL:_sQuery += " AND NF_PRODUTOR BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
		_oSQL:_sQuery += " AND SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SA2.A2_FILIAL = '  '"
		_oSQL:_sQuery += " AND SA2.A2_COD = C.ASSOCIADO"
		_oSQL:_sQuery += " AND SA2.A2_LOJA = C.LOJA"
		_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, CONTRANOTA"
	else
		_oSQL:_sQuery += " SELECT SAFRA ,FILIAL, "
		_oSQL:_sQuery += "        SA2.A2_MUN AS MUNICIPIO, A2_EST AS ESTADO, "
		_oSQL:_sQuery += "        ASSOCIADO, LOJA ,NOME_ASSOC AS NOME, A2_CGC AS CPF_CNPJ,"
		_oSQL:_sQuery += "        PESO_LIQ ,CONTRANOTA, VALOR_UNIT, VALOR_TOTAL, DATA "
		_oSQL:_sQuery += " FROM	C,"
		_oSQL:_sQuery +=        RetSQLName("SA2") + " SA2"
		_oSQL:_sQuery += " WHERE CARGA BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
		_oSQL:_sQuery += " AND NF_PRODUTOR BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
		_oSQL:_sQuery += " AND SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SA2.A2_FILIAL = '  '"
		_oSQL:_sQuery += " AND SA2.A2_COD = C.ASSOCIADO"
		_oSQL:_sQuery += " AND SA2.A2_LOJA = C.LOJA"
		_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, DATA"
	EndIf
	_oSQL:Log()
	_oSQL:Qry2Xls()
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                    help
	aadd(_aRegsPerg, {01, "Produtor inicial              ", "C", 6,             0,            "",   "SA2",  {},                               "Codigo do produtor (fornecedor) inicial para filtragem"})
	aadd(_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,             0,            "",   "   ",  {},                               "Loja do produtor (fornecedor) inicial para filtragem"})
	aadd(_aRegsPerg, {03, "Produtor final                ", "C", 6,             0,            "",   "SA2",  {},                               "Codigo do produtor (fornecedor) final para filtragem"})
	aadd(_aRegsPerg, {04, "Loja produtor final           ", "C", 2,             0,            "",   "   ",  {},                               "Loja do produtor (fornecedor) final para filtragem"})
	aadd(_aRegsPerg, {05, "Safra referencia              ", "C", 4,             0,            "",   "   ",  {},                               "Safra (ano) para filtragem"})
	aadd(_aRegsPerg, {06, "Filial inicial                ", "C", 2,             0,            "",   "SM0",  {},                               ""})
	aadd(_aRegsPerg, {07, "Filial final                  ", "C", 2,             0,            "",   "SM0",  {},                               ""})
	aadd(_aRegsPerg, {08, "Carga inicial                 ", "C", 4,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {09, "Carga final                   ", "C", 4,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {10, "Comum / vinifera              ", "N", 1,             0,            "",   "   ",  {"Comuns", "Viniferas", "Todas"}, ""})
	aadd(_aRegsPerg, {11, "NF produtor inicial           ", "C", 9,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {12, "NF produtor final             ", "C", 9,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {13, "Data contranota inicial       ", "D", 8,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {14, "Data contranota final         ", "D", 8,             0,            "",   "   ",  {},                               ""})
	aadd(_aRegsPerg, {15, "Notas de entrada/recebimento? ", "N", 1,             0,            "",   "   ",  {"Sim", "Nao"},                   ""})
	aadd(_aRegsPerg, {16, "Notas de producao propria?    ", "N", 1,             0,            "",   "   ",  {"Sim", "Nao"},                   ""})
	aadd(_aRegsPerg, {17, "Notas de compra?              ", "N", 1,             0,            "",   "   ",  {"Sim", "Nao"},                   ""})
	aadd(_aRegsPerg, {18, "Notas de complemento de valor?", "N", 1,             0,            "",   "   ",  {"Sim", "Nao"},                   ""})
	aadd(_aRegsPerg, {19, "Relatório                     ", "N", 1,             0,            "",   "   ",  {"Completo", "Simplificado"},     ""})
	U_ValPerg(cPerg, _aRegsPerg, {}, _aDefaults)
Return
