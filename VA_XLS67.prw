// Programa...: VA_XLS67
// Autor......: Cláudia Lionço
// Data.......: 14/05/2024
// Descricao..: Relatório de custos por tipo de item consumido em OP
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #custos #item_consumido #op
// #TabelasPrincipais #SC2 #SD3 #ZX5
// #Modulos           #EST 
//
// Historico de alteracoes:
// 
// --------------------------------------------------------------------------
User Function VA_XLS67 (_lAutomat)
	Local cCadastro := "Relatório de custos por tipo de item consumido em OP"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS67"
	_ValidPerg()
	If Pergunte(cPerg,.T.)

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
    EndIf
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Execução da consulta
Static Function _Gera()
	local _oSQL  := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	_oSQL := ClsSQL():New()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SD3.D3_FILIAL AS FILIAL "
    _oSQL:_sQuery += " 	   ,SD3.D3_OP AS OP "
    _oSQL:_sQuery += " 	   ,SC2.C2_PRODUTO AS PRODUTO_FINAL "
    _oSQL:_sQuery += " 	   ,SC2.C2_DATRF AS ENCERRAMENTO_OP "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'PR%' THEN D3_QUANT "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS QT_PRODUZIDA "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'PR%' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS CUSTO_TOT_PRODUCAO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'AP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_AP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'MO' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_MO_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'GF' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_GF_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'MP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_MP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'VD' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_VD_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'ME' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_ME_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'PP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_PP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'UC' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_UC_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'BN' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_BN_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP != 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO NOT IN ('AP', 'MO', 'GF', 'MP', 'VD', 'ME', 'PP', 'UC', 'BN') THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS REQ_OUTROS_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'AP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_AP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'MO' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_MO_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'GF' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_GF_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'MP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_MP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'VD' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_VD_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'ME' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_ME_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'PP' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_PP_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'UC' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_UC_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO = 'BN' THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_BN_CUSTO "
    _oSQL:_sQuery += " 	   ,SUM(CASE "
    _oSQL:_sQuery += " 			WHEN SD3.D3_CF LIKE 'RE%' AND "
    _oSQL:_sQuery += " 				SD3.D3_VAPEROP = 'S' AND "
    _oSQL:_sQuery += " 				SD3.D3_TIPO NOT IN ('AP', 'MO', 'GF', 'MP', 'VD', 'ME', 'PP', 'UC', 'BN') THEN D3_CUSTO1 "
    _oSQL:_sQuery += " 			ELSE 0 "
    _oSQL:_sQuery += " 		END) AS PERDA_OUTROS_CUSTO "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SD3") + " SD3 " // Nao sei por que motivo o otimizador do SQL costuma escolher indices ruins para o SD3 "
    _oSQL:_sQuery += " 		 WITH (INDEX (SD30106)) "
    _oSQL:_sQuery += " 		," + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 		," + RetSQLName ("SC2") + " SC2 "
    _oSQL:_sQuery += " 	WHERE SD3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND SD3.D3_FILIAL = '"+ xFilial("SD3")+"' "
    _oSQL:_sQuery += " 	AND SD3.D3_EMISSAO >= '20240101'  " // NAO QUERO LER OPS ANTIGAS DEMAIS
    _oSQL:_sQuery += " 	AND SD3.D3_ESTORNO = ''
    _oSQL:_sQuery += " 	AND SD3.D3_OP != '' " "
    _oSQL:_sQuery += " 	AND SB1.D_E_L_E_T_ = ''
    _oSQL:_sQuery += " 	AND SB1.B1_FILIAL = '  ' "
    _oSQL:_sQuery += " 	AND SB1.B1_COD = SD3.D3_COD "
    _oSQL:_sQuery += " 	AND SC2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND SC2.C2_FILIAL = SD3.D3_FILIAL "
    _oSQL:_sQuery += " 	AND SC2.C2_NUM = SUBSTRING(SD3.D3_OP, 1, 6) "
    _oSQL:_sQuery += " 	AND SC2.C2_ITEM = SUBSTRING(SD3.D3_OP, 7, 2) "
    _oSQL:_sQuery += " 	AND SC2.C2_SEQUEN = SUBSTRING(SD3.D3_OP, 9, 3) "
    _oSQL:_sQuery += " 	AND SC2.C2_ITEMGRD = SUBSTRING(SD3.D3_OP, 12, 2) "
    _oSQL:_sQuery += " 	AND SC2.C2_PRODUTO != 'MANUTENCAO' "
    _oSQL:_sQuery += " 	AND SD3.D3_EMISSAO BETWEEN '"+ dtos(mv_par01)+"' AND '"+dtos(mv_par02)+"' "
    _oSQL:_sQuery += " 	GROUP BY SD3.D3_FILIAL "
    _oSQL:_sQuery += " 			,SD3.D3_OP "
    _oSQL:_sQuery += " 			,SC2.C2_PRODUTO "
    _oSQL:_sQuery += " 			,SC2.C2_DATRF) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	RTRIM(ZX5_39.ZX5_39DESC) AS LINHA_COML "
    _oSQL:_sQuery += "    ,B1_TIPO AS TIPO_PROD_FINAL "
    _oSQL:_sQuery += "    ,PRODUTO_FINAL "
    _oSQL:_sQuery += "    ,RTRIM(B1_DESC) AS DESC_PROD_FINAL "
    _oSQL:_sQuery += "    ,FILIAL "
    _oSQL:_sQuery += "    , OP "
    _oSQL:_sQuery += "    ,FORMAT(CAST(ENCERRAMENTO_OP + ' 00:00' AS DATETIME), 'dd/MM/yyyy') AS ENCERRAMENTO_OP "
    _oSQL:_sQuery += "    ,QT_PRODUZIDA "
    _oSQL:_sQuery += "    ,B1_UM AS UN_MEDIDA "
    _oSQL:_sQuery += "    ,C.QT_PRODUZIDA * SB1.B1_LITROS AS LITROS_PRODUZIDOS "
    _oSQL:_sQuery += "    ,REQ_AP_CUSTO "
    _oSQL:_sQuery += "    ,REQ_MO_CUSTO "
    _oSQL:_sQuery += "    ,REQ_GF_CUSTO "
    _oSQL:_sQuery += "    ,REQ_MP_CUSTO "
    _oSQL:_sQuery += "    ,REQ_VD_CUSTO "
    _oSQL:_sQuery += "    ,REQ_ME_CUSTO "
    _oSQL:_sQuery += "    ,REQ_PP_CUSTO "
    _oSQL:_sQuery += "    ,REQ_UC_CUSTO "
    _oSQL:_sQuery += "    ,REQ_BN_CUSTO "
    _oSQL:_sQuery += "    ,REQ_OUTROS_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_AP_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_MO_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_GF_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_MP_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_VD_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_ME_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_PP_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_UC_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_BN_CUSTO "
    _oSQL:_sQuery += "    ,PERDA_OUTROS_CUSTO "
    _oSQL:_sQuery += "    ,CUSTO_TOT_PRODUCAO "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " 	," + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 	 LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_39 " 
    _oSQL:_sQuery += " 		 ON (ZX5_39.ZX5_TABELA = '39' "
    _oSQL:_sQuery += " 				 AND ZX5_39.ZX5_39COD = SB1.B1_CODLIN) "
    _oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SB1.B1_FILIAL = '  ' "
    _oSQL:_sQuery += " AND SB1.B1_COD = C.PRODUTO_FINAL "
    _oSQL:_sQuery += " ORDER BY FILIAL, PRODUTO_FINAL, OP "

    _oSQL:Log()
    _oSQL:ArqDestXLS = 'VA_XLS67'
    _oSQL:Qry2XLS (.F., .F., .F.)

return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Dt Inicial      ", "D", 8, 0,  "",   "   ", {}, ""})
    aadd (_aRegsPerg, {02, "Dt.Final        ", "D", 8, 0,  "",   "   ", {}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
