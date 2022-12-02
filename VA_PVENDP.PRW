//  Programa...: VA_PVENDP
//  Autor......: Sandra Sugari
//  Data.......: 16/05/2022
//  Cliente....: Alianca
//  Descricao..: Produtos Vendidos no Periodo
//
//  #TipoDePrograma    #relatorio
//  #Descricao         #Produtos Vendidos no Periodo
//  #PalavasChave      #produtos#vendidos#
//  #TabelasPrincipais #BI_ALIANCA.dbo.VA_FATDADOS,#SB1,#ZX5 
//  #Modulos 		  #CONT
//
//  Historico de alteracoes:
//  11/07/2022 - Sandra/Rbert - Ajuste nos totais quando a divisão por "0".
//  29/11/2022 - Criado relatorio analítico. GLPI: 12846
//
// --------------------------------------------------------------------------
User Function VA_PVENDP (_lAutomat)
	Local cCadastro := "Produtos Vendidos no Periodo"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	//if ! U_ZZUVL ('045', __cUserID, .T.)
	//	return
	//endif

	Private cPerg   := "VAPVENDP"
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
// Geraqção
Static Function _Gera()
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")

    If mv_par09 == 1
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "	  FILIAL "
        _oSQL:_sQuery += "   ,TIPOPROD "
        _oSQL:_sQuery += "   ,PRODUTO AS COD_PROD "
        _oSQL:_sQuery += "   ,SB1.B1_DESC AS DESCRICAO "
        _oSQL:_sQuery += "   ,CODLINHA "
        _oSQL:_sQuery += "   ,RTRIM(ISNULL(ZX5_39.ZX5_39DESC, '')) AS LINHA "
        _oSQL:_sQuery += "   ,SUM(QUANTIDADE) AS QTDE "
        _oSQL:_sQuery += "   ,SB1.B1_UM AS UNIDADE "
        _oSQL:_sQuery += "   ,SUM(QTLITROS) AS LITROS "
        _oSQL:_sQuery += "   ,ROUND(SUM(TOTAL) / SUM(case when QUANTIDADE = 0 then 1 else QUANTIDADE end), 2) AS VRL_FATURADO_UN "  
        _oSQL:_sQuery += "   ,ROUND(SUM(TOTAL), 2) AS VRL_TOTAL "
        _oSQL:_sQuery += "   ,ROUND(SUM(CUSTOMEDIO), 2) AS CUSTO_TOTAL "
        _oSQL:_sQuery += "   ,ROUND(AVG(NULLIF(CUSTOMEDIO,0) / QUANTIDADE), 2) AS CUSTO_UN
        _oSQL:_sQuery += "   ,SB1.B1_CUSTD AS CUSTO_STANDER"
        _oSQL:_sQuery += "   ,ROUND((SUM(TOTAL) - SUM(CUSTOMEDIO)) / SUM(case when TOTAL = 0 then 1 else TOTAL end) * 100, 1) AS 'MARGEM' "
        _oSQL:_sQuery += "   ,ROUND(SUM(CUSTOMEDIO) / SUM(case when TOTAL = 0 then 1 else TOTAL end) * 100, 0) AS 'CPV' "
        _oSQL:_sQuery += " FROM BI_ALIANCA.dbo.VA_FATDADOS "
        _oSQL:_sQuery += " INNER JOIN SB1010 AS SB1 "
        _oSQL:_sQuery += "	    ON (SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "			AND SB1.B1_COD = PRODUTO) "
        _oSQL:_sQuery += " LEFT JOIN ZX5010 AS ZX5_39 "
        _oSQL:_sQuery += "	    ON (ZX5_39.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "			AND ZX5_39.ZX5_TABELA = '39' "
        _oSQL:_sQuery += "			AND ZX5_39.ZX5_39COD = CODLINHA) "
        _oSQL:_sQuery += " WHERE F4_MARGEM = '1' "
        _oSQL:_sQuery += " AND FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
        _oSQL:_sQuery += " AND EMISSAO BETWEEN '" + DTOS(mv_par03) + "' and '" + dtos(mv_par04) + "'"
        _oSQL:_sQuery += " AND PRODUTO BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
        _oSQL:_sQuery += " AND TIPOPROD BETWEEN '" + mv_par07 + "' and '" + mv_par08 + "'"
        _oSQL:_sQuery += " GROUP BY FILIAL "
        _oSQL:_sQuery += "	    ,TIPOPROD "
        _oSQL:_sQuery += "		,PRODUTO "
        _oSQL:_sQuery += "		,SB1.B1_DESC "
        _oSQL:_sQuery += "		,SB1.B1_UM "
        _oSQL:_sQuery += "		,SB1.B1_LINHA "
        _oSQL:_sQuery += "		,ZX5_39DESC "
        _oSQL:_sQuery += "		,CODLINHA "
        _oSQL:_sQuery += "		,SB1.B1_CUSTD "
        //_oSQL:Log ()
        _oSQL:ArqDestXLS = 'VA_PVENDP'
        _oSQL:Qry2Xls ()
    else
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " WITH C "
        _oSQL:_sQuery += " AS "
        _oSQL:_sQuery += " (SELECT "
        _oSQL:_sQuery += " 		FILIAL "
        _oSQL:_sQuery += " 	   ,CONCAT(RIGHT(REPLICATE('0', 2) + CONVERT(VARCHAR, MONTH(EMISSAO)), 2), '/', YEAR(EMISSAO)) AS DTEMISSAO "
        _oSQL:_sQuery += " 	   ,TIPOPROD "
        _oSQL:_sQuery += " 	   ,PRODUTO AS COD_PROD "
        _oSQL:_sQuery += " 	   ,SB1.B1_DESC AS DESCRICAO "
        _oSQL:_sQuery += " 	   ,CODLINHA "
        _oSQL:_sQuery += " 	   ,RTRIM(ISNULL(ZX5_39.ZX5_39DESC, '')) AS LINHA "
        _oSQL:_sQuery += " 	   ,SUM(QUANTIDADE) AS QTDE "
        _oSQL:_sQuery += " 	   ,SB1.B1_UM AS UNIDADE "
        _oSQL:_sQuery += " 	   ,SUM(QTLITROS) AS LITROS "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(TOTAL) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN QUANTIDADE = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE QUANTIDADE "
        _oSQL:_sQuery += " 		END), 2) AS VRL_FATURADO_UN "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(TOTAL), 2) AS VRL_TOTAL "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(CUSTOMEDIO), 2) AS CUSTO_TOTAL "
        _oSQL:_sQuery += " 	   ,ROUND(AVG(NULLIF(CUSTOMEDIO, 0) / QUANTIDADE), 2) AS CUSTO_UN "
        _oSQL:_sQuery += " 	   ,SB1.B1_CUSTD AS CUSTO_STANDER "
        _oSQL:_sQuery += " 	   ,ROUND((SUM(TOTAL) - SUM(CUSTOMEDIO)) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN TOTAL = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE TOTAL "
        _oSQL:_sQuery += " 		END) * 100, 1) AS 'MARGEM' "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(CUSTOMEDIO) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN TOTAL = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE TOTAL "
        _oSQL:_sQuery += " 		END) * 100, 0) AS 'CPV' "
        _oSQL:_sQuery += " 	   ,TOTAL "
        _oSQL:_sQuery += " 	   ,CUSTOMEDIO "
        _oSQL:_sQuery += " 	FROM BI_ALIANCA.dbo.VA_FATDADOS "
        _oSQL:_sQuery += " 	INNER JOIN SB1010 AS SB1 "
        _oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SB1.B1_COD = PRODUTO) "
        _oSQL:_sQuery += " 	LEFT JOIN ZX5010 AS ZX5_39 "
        _oSQL:_sQuery += " 		ON (ZX5_39.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND ZX5_39.ZX5_TABELA = '39' "
        _oSQL:_sQuery += " 		AND ZX5_39.ZX5_39COD = CODLINHA) "
        _oSQL:_sQuery += " 	WHERE F4_MARGEM = '1' "
        _oSQL:_sQuery += "  AND FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
        _oSQL:_sQuery += "  AND EMISSAO BETWEEN '" + DTOS(mv_par03) + "' and '" + dtos(mv_par04) + "'"
        _oSQL:_sQuery += "  AND PRODUTO BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
        _oSQL:_sQuery += "  AND TIPOPROD BETWEEN '" + mv_par07 + "' and '" + mv_par08 + "'"
        _oSQL:_sQuery += " 	GROUP BY FILIAL "
        _oSQL:_sQuery += " 			,EMISSAO "
        _oSQL:_sQuery += " 			,TIPOPROD "
        _oSQL:_sQuery += " 			,PRODUTO "
        _oSQL:_sQuery += " 			,SB1.B1_DESC "
        _oSQL:_sQuery += " 			,SB1.B1_UM "
        _oSQL:_sQuery += " 			,SB1.B1_LINHA "
        _oSQL:_sQuery += " 			,ZX5_39DESC "
        _oSQL:_sQuery += " 			,CODLINHA "
        _oSQL:_sQuery += " 			,SB1.B1_CUSTD "
        _oSQL:_sQuery += " 			,TOTAL "
        _oSQL:_sQuery += " 			,CUSTOMEDIO) "
        _oSQL:_sQuery += " 	SELECT "
        _oSQL:_sQuery += " 		FILIAL "
        _oSQL:_sQuery += " 	   ,DTEMISSAO "
        _oSQL:_sQuery += " 	   ,TIPOPROD "
        _oSQL:_sQuery += " 	   ,COD_PROD "
        _oSQL:_sQuery += " 	   ,DESCRICAO "
        _oSQL:_sQuery += " 	   ,CODLINHA "
        _oSQL:_sQuery += " 	   ,LINHA "
        _oSQL:_sQuery += " 	   ,SUM(QTDE) AS QTDE "
        _oSQL:_sQuery += " 	   ,UNIDADE "
        _oSQL:_sQuery += " 	   ,SUM(LITROS) AS LITROS "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(VRL_TOTAL) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN QTDE = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE QTDE "
        _oSQL:_sQuery += " 		END), 2) AS VRL_FATURADO_UNIT "
        _oSQL:_sQuery += " 	   ,SUM(VRL_TOTAL) AS VRL_TOTAL "
        _oSQL:_sQuery += " 	   ,SUM(CUSTO_TOTAL) AS CUSTO_TOTAL "
        _oSQL:_sQuery += " 	   ,SUM(CUSTO_TOTAL) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN QTDE = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE QTDE "
        _oSQL:_sQuery += " 		END) "
        _oSQL:_sQuery += " 		AS CUSTO_UNIT "
        _oSQL:_sQuery += " 	   ,CUSTO_STANDER AS CUSTO_STAND "
        _oSQL:_sQuery += " 	   ,ROUND((SUM(VRL_TOTAL) - SUM(CUSTO_TOTAL)) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN VRL_TOTAL = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE VRL_TOTAL "
        _oSQL:_sQuery += " 		END) * 100, 1) AS MARGEM "
        _oSQL:_sQuery += " 	   ,ROUND(SUM(CUSTO_TOTAL) / SUM(CASE "
        _oSQL:_sQuery += " 			WHEN VRL_TOTAL = 0 THEN 1 "
        _oSQL:_sQuery += " 			ELSE VRL_TOTAL "
        _oSQL:_sQuery += " 		END) * 100, 0) AS CPV "
        _oSQL:_sQuery += " 	FROM C "
        _oSQL:_sQuery += " 	GROUP BY FILIAL "
        _oSQL:_sQuery += " 			,DTEMISSAO "
        _oSQL:_sQuery += " 			,TIPOPROD "
        _oSQL:_sQuery += " 			,COD_PROD "
        _oSQL:_sQuery += " 			,DESCRICAO "
        _oSQL:_sQuery += " 			,CODLINHA "
        _oSQL:_sQuery += " 			,LINHA "
        _oSQL:_sQuery += " 			,UNIDADE "
        _oSQL:_sQuery += " 			,CUSTO_STANDER "
        _oSQL:_sQuery += " 	ORDER BY FILIAL, COD_PROD "
        //_oSQL:Log ()
        _oSQL:ArqDestXLS = 'VA_PVENDP'
        _oSQL:Qry2Xls ()
    EndIf
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
//                       PERGUNT                        TIPO TAM DEC VALID   F3     Opcoes                       Help
    aadd (_aRegsPerg, {01, "Filial de                 ", "C", 2, 0,  "",   "SM0", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial ate                ", "C", 2, 0,  "",   "SM0", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Data de                   ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data ate                  ", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {05, "Produto de                ", "C", 15, 0, "",   "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {06, "Produto ate               ", "C", 15, 0, "",   "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {07, "Tipo de Produto de        ", "C", 2, 0,  "",   "02 ", {},                         		 ""})
    aadd (_aRegsPerg, {08, "Tipo de Produto ate       ", "C", 2, 0,  "",   "02 ", {},                         		 ""})
    aadd (_aRegsPerg, {09, "Relatorio                 ", "N", 1, 0,  "",   "   ", {"Sintético","Analítico"},         ""})
    U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
    
Return
