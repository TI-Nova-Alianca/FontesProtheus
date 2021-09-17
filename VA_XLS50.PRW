// Programa...: VA_XLS50
// Autor......: Robert Koch
// Data.......: 17/03/2020
// Descricao..: Exporta planilha com entradas de MP/VD identificando se sao de associados ou nao.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Exporta planilha com entradas de MP/VD para classificacao entre ato cooperativo e nao cooperativo.
// #PalavasChave      #entradas #uva #materia-prima #ato_cooperativo #ato_nao_cooperativo #ato_cooperado #ato_nao_cooperado
// #TabelasPrincipais #SD1 #SZI
// #Modulos           #COOP #CTB

// Historico de alteracoes:
// 25/01/2021 - Robert - Adicionada loja 02 do fornecedor 001369 como producao propria.
// 27/01/2021 - Robert - Alteracao geral: deixa de ler view de notas e passa a buscar do SD1 (GLPI 9198).
// 17/09/2021 - Robert - Exporta sucos concentrados apenas se forem de uva. (posterior encerramento GLPI 9198).
//

// --------------------------------------------------------------------------
User Function VA_XLS50 (_lAutomat)
	Local cCadastro := "Exporta com entradas de MP/VD para classificacao entre ato cooperativo e nao cooperativo."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)
		return
	endif

	Private cPerg   := "VAXLS50"
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



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL   := NIL
//	local _sSafra := ''

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	/* Versao original (ateh 27/01/2021)
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS"
	_oSQL:_sQuery += "( SELECT SAFRA, TIPO_NF, TIPO_FORNEC"
	_oSQL:_sQuery +=        ", SUM (PESO_LIQ) AS PESO"
	_oSQL:_sQuery +=        ", SUM (" + iif (U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt), "VALOR_TOTAL", "0") + ") AS VALOR"
	_oSQL:_sQuery +=    " FROM VA_VNOTAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=   " AND FILIAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery += " GROUP BY SAFRA, TIPO_NF, TIPO_FORNEC"
	
	// Busca possiveis notas de devolucao
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT SAFRA, TIPO_NF, TIPO_FORNEC"
	_oSQL:_sQuery +=       ", SUM (PESO_LIQ) AS PESO"
	_oSQL:_sQuery +=       ", SUM (" + iif (U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt), "VALOR_TOTAL", "0") + ") AS VALOR"
	_oSQL:_sQuery +=  " FROM (SELECT SAFRA, 'D' AS TIPO_NF"
	_oSQL:_sQuery +=              " ,CASE WHEN FORNECEDOR + LOJA IN ('00136901', '00136902', '00109401', '00311401')"
	_oSQL:_sQuery +=                    " THEN 'PROD_PROPRIA'"
	_oSQL:_sQuery +=                    " ELSE CASE WHEN dbo.VA_ASSOC_DT_ENTRADA (FORNECEDOR, LOJA, SD2.D2_EMISSAO) != ''"
	_oSQL:_sQuery +=                              " THEN 'ASSOCIADO'"
	_oSQL:_sQuery +=                              " ELSE 'NAO_ASSOC'"
	_oSQL:_sQuery +=                         " END"
	_oSQL:_sQuery +=               " END AS TIPO_FORNEC"
	_oSQL:_sQuery +=              ", SD2.D2_QUANT * -1 AS PESO_LIQ"
	_oSQL:_sQuery +=              ", SD2.D2_TOTAL * -1 AS VALOR_TOTAL"
	_oSQL:_sQuery +=          " FROM VA_VNOTAS_SAFRA_DEVOLVIDAS V"
	_oSQL:_sQuery +=               " LEFT JOIN SD2010 SD2"
	_oSQL:_sQuery +=               " ON (SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=               " AND SD2.D2_FILIAL  = V.FILIAL"
	_oSQL:_sQuery +=               " AND SD2.D2_DOC     = V.NF_DEVOLUCAO"
	_oSQL:_sQuery +=               " AND SD2.D2_SERIE   = V.SERIE_DEVOLUCAO)"
	_oSQL:_sQuery +=         " WHERE SAFRA  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=           " AND FILIAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=        ") AS DEVOL"
	_oSQL:_sQuery +=  " GROUP BY SAFRA, TIPO_NF, TIPO_FORNEC"
	_oSQL:_sQuery += "), D AS"

	// Cria colunas para dar nomes amigaveis aos tipos de nota e para ajudar na ordenacao cronologica de como as operacoes ocorrem.
	_oSQL:_sQuery += "( SELECT *"
	_oSQL:_sQuery +=        ", CASE TIPO_NF WHEN 'E' THEN 'ENTRADA'"
	_oSQL:_sQuery +=                      " WHEN 'P' THEN 'ENTRADA'"
	_oSQL:_sQuery +=                      " WHEN 'C' THEN 'COMPRA'"
	_oSQL:_sQuery +=                      " WHEN 'V' THEN 'COMPL.VALOR'"
	_oSQL:_sQuery +=                      " WHEN 'D' THEN 'DEVOLUCAO'"
	_oSQL:_sQuery +=                      " ELSE TIPO_NF END AS TIPO_NOTA"
	_oSQL:_sQuery +=        ", CASE TIPO_NF WHEN 'E' THEN '1'"
	_oSQL:_sQuery +=                      " WHEN 'P' THEN '2'"
	_oSQL:_sQuery +=                      " WHEN 'D' THEN '3'"
	_oSQL:_sQuery +=                      " WHEN 'C' THEN '4'"
	_oSQL:_sQuery +=                      " WHEN 'V' THEN '5'"
	_oSQL:_sQuery +=                      " ELSE TIPO_NF END AS OPERACAO"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery += "), E AS "
	
	// Monta duas consultas e depois junta as duas de modo a mostrar quantidades e valores separadamente.
	_oSQL:_sQuery += "(SELECT TIPO_FORNEC, TIPO_NOTA, OPERACAO, 'VALORES' AS QUANT_OU_VALOR"
	
	_sSafra = mv_par01
	do while _sSafra <= mv_par02
		_oSQL:_sQuery +=       ", SUM (CASE WHEN SAFRA = '" + _sSafra + "' THEN VALOR ELSE 0 END) AS SAFRA_" + _sSafra
		_sSafra = soma1 (_sSafra)
	enddo
	_oSQL:_sQuery +=  " FROM D"
	_oSQL:_sQuery += " GROUP BY TIPO_FORNEC, TIPO_NOTA, OPERACAO"

	_oSQL:_sQuery += " UNION ALL"

	_oSQL:_sQuery += " SELECT TIPO_FORNEC, TIPO_NOTA, OPERACAO, 'QUANTIDADES' AS QUANT_OU_VALOR
	_sSafra = mv_par01
	do while _sSafra <= mv_par02
		_oSQL:_sQuery +=       ", SUM (CASE WHEN SAFRA = '" + _sSafra + "' THEN PESO ELSE 0 END) AS SAFRA_" + _sSafra
		_sSafra = soma1 (_sSafra)
	enddo
	_oSQL:_sQuery +=  " FROM D"
	_oSQL:_sQuery += " GROUP BY TIPO_FORNEC, TIPO_NOTA, OPERACAO"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=  " FROM E"
	_oSQL:_sQuery += " ORDER BY QUANT_OU_VALOR DESC, TIPO_FORNEC, OPERACAO"
*/
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SD1.D1_FILIAL AS FILIAL"
	_oSQL:_sQuery +=       ",SD1.D1_COD AS PRODUTO"
	_oSQL:_sQuery +=       ",SB1.B1_DESC AS DESCRICAO"
	_oSQL:_sQuery +=       ",SD1.D1_TP AS TIPO_PRODUTO"
	_oSQL:_sQuery +=       ",FORMAT (CAST (SD1.D1_DTDIGIT AS DATETIME), 'dd/MM/yyyy') AS DT_MOVTO"
	_oSQL:_sQuery +=       ",SD1.D1_FORNECE AS FORNECEDOR"
	_oSQL:_sQuery +=       ",SD1.D1_LOJA AS LOJA"
	_oSQL:_sQuery +=       ",A2_NOME AS NOME"
	_oSQL:_sQuery +=       ",CASE WHEN dbo.VA_ASSOC_DT_ENTRADA(D1_FORNECE, D1_LOJA, D1_DTDIGIT) != ''"
	_oSQL:_sQuery +=       "    THEN 'ASSOCIADO'"
	_oSQL:_sQuery +=       "    ELSE 'NAO ASSOCIADO'"
	_oSQL:_sQuery +=       "END AS TIPO_FORNECEDOR"
	_oSQL:_sQuery +=       ",SD1.D1_TIPO AS TIPO_NF"
	_oSQL:_sQuery +=       ",SD1.D1_TES AS TES"
	_oSQL:_sQuery +=       ",SD1.D1_CF AS CFOP"
	_oSQL:_sQuery +=       ",D1_DOC AS NF"
	_oSQL:_sQuery +=       ",SD1.D1_SERIE AS SERIE"
	_oSQL:_sQuery +=       ",SD1.D1_QUANT AS QUANTIDADE"
	_oSQL:_sQuery +=       ",SD1.D1_UM AS UN_MEDIDA"
	_oSQL:_sQuery +=       ",SD1.D1_TOTAL AS VL_TOTAL"
	_oSQL:_sQuery +=       ",SD1.D1_CUSTO AS CUSTO_MEDIO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1 "
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=            " ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=           " AND SB1.B1_COD = SD1.D1_COD)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=            " ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=           " AND SA2.A2_COD = SD1.D1_FORNECE"
	_oSQL:_sQuery +=           " AND SA2.A2_LOJA = SD1.D1_LOJA)"
	_oSQL:_sQuery += " WHERE SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_TP IN ('MP', 'VD')"
	_oSQL:_sQuery +=   " AND SD1.D1_TIPO NOT IN ('B', 'D')"
	_oSQL:_sQuery +=   " AND NOT (SD1.D1_GRUPO = '4000' AND SD1.D1_DESCRI NOT LIKE '%UVA%')"  // Se forem concentrados, quero apenas de uva.
	_oSQL:Log ()
	_oSQL:Qry2Xls ()
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Data inicial NF entrada       ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {02, "Data final NF entrada         ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
