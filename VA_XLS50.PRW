// Programa...: VA_XLS50
// Autor......: Robert Koch
// Data.......: 17/03/2020
// Descricao..: Exporta planilha com totais de contranotas de safra.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS50 (_lAutomat)
	Local cCadastro := "Exporta comparativo contranotas de safra por tipo de fornecedor / operacao"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
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
	local _sSafra := ''

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
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
	_oSQL:_sQuery +=              " ,CASE WHEN FORNECEDOR + LOJA IN ('00136901', '00109401', '00311401')"
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

	_oSQL:Log ()
	_oSQL:Qry2Xls ()
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Safra inicial                 ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {02, "Safra final                   ", "C", 4,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {03, "Filial inicial                ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {04, "Filial final                  ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
