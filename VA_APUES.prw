// Programa...: VA_APUES
// Autor......: Cláudia Lionço
// Data.......: 16/03/2020
// Descricao..: Apuração de entradas e saídas do estoque. GLPI: 7636
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_APUES()
	Local _cQry1	 := ""
	Local _oSQL      := NIL
	Private oReport
	Private cPerg   := "VA_APUES"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	_AnoRef 	:= mv_par01
	_MesRef 	:= PADL(mv_par02,2,'0')
	_DtRefIni   := STOD(_AnoRef + _MesRef + '01')
	_DtRefFin	:= LastDate(_DtRefIni)
	
	_DtAntIni   := MonthSub(_DtRefIni,1)
	_DtAntFin	:= LastDate(_DtAntIni)
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += " 	WITH entSaida (VALOR, COD, FILIAL, MOVIMENTO, DOC, AX, QTD)"
	_oSQL:_sQuery += " 	AS"
	_oSQL:_sQuery += " 	("
	//	--Saldo Inicial - OK
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(B9_VINI1)"
	_oSQL:_sQuery += " 		   ,B9_COD"
	_oSQL:_sQuery += " 		   ,B9_FILIAL"
	_oSQL:_sQuery += " 		   ,'01-Saldo_Inicial'"
	_oSQL:_sQuery += " 		   ,'SI' AS DOC"
	_oSQL:_sQuery += " 		   ,B9_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,SUM(B9_QINI) AS QTD"
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SB9")  
	_oSQL:_sQuery += " 		WHERE B9_DATA BETWEEN '" + dtos(_DtAntIni) + "' AND '" + dtos(_DtAntFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		GROUP BY B9_COD"
	_oSQL:_sQuery += " 				,B9_FILIAL"
	_oSQL:_sQuery += " 				,B9_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--Saldo final - OK
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			-SUM(B9_VINI1)"
	_oSQL:_sQuery += " 		   ,B9_COD"
	_oSQL:_sQuery += " 		   ,B9_FILIAL"
	_oSQL:_sQuery += " 		   ,'13-Saldo_Final'"
	_oSQL:_sQuery += " 		   ,'SF' AS DOC"
	_oSQL:_sQuery += " 		   ,B9_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,-SUM(B9_QINI) AS QTD"
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SB9")   
	_oSQL:_sQuery += " 		WHERE B9_DATA BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		GROUP BY B9_COD"
	_oSQL:_sQuery += " 				,B9_FILIAL"
	_oSQL:_sQuery += " 				,B9_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--compras - OK - Está somando as entradas de transferencias
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(D1_CUSTO)"
	_oSQL:_sQuery += " 		   ,D1_COD"
	_oSQL:_sQuery += " 		   ,D1_FILIAL"
	_oSQL:_sQuery += " 		   ,'02-Compras'"
	_oSQL:_sQuery += " 		   ,D1_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D1_LOCAL"
	_oSQL:_sQuery += "		   ,SUM(D1_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM SD1010"
	_oSQL:_sQuery += " 		WHERE D1_DTDIGIT BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D1_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4")  
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_PODER3 = 'N'"
	_oSQL:_sQuery += " 			AND F4_TRANFIL != '1'"
	_oSQL:_sQuery += " 			AND F4_TIPO = 'E')"
	_oSQL:_sQuery += " 		GROUP BY D1_COD"
	_oSQL:_sQuery += " 				,D1_FILIAL"
	_oSQL:_sQuery += " 				,D1_DOC"
	_oSQL:_sQuery += " 				,D1_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--Vendas - OK - ver tranfil pois deve estar contabilizando as transferencias como se fossem compra
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			-SUM(D2_CUSTO1)"
	_oSQL:_sQuery += " 		   ,D2_COD"
	_oSQL:_sQuery += " 		   ,D2_FILIAL"
	_oSQL:_sQuery += " 		   ,'12-Saida_Vendas'"
	_oSQL:_sQuery += " 		   ,D2_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D2_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,-SUM(D2_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD2")  
	_oSQL:_sQuery += " 		WHERE D2_COD IN (SELECT"
	_oSQL:_sQuery += " 				B1_COD"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SB1")  
	_oSQL:_sQuery += " 			WHERE D_E_L_E_T_ = '')"
	_oSQL:_sQuery += " 		AND D2_EMISSAO BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D2_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4")  
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_PODER3 = 'N'"
	_oSQL:_sQuery += " 			AND F4_TRANFIL != '1'"
	_oSQL:_sQuery += " 			AND F4_TIPO = 'S')"
	_oSQL:_sQuery += " 		GROUP BY D2_COD"
	_oSQL:_sQuery += " 				,D2_FILIAL"
	_oSQL:_sQuery += " 				,D2_DOC"
	_oSQL:_sQuery += " 				,D2_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(D1_CUSTO)"
	_oSQL:_sQuery += " 		   ,D1_COD"
	_oSQL:_sQuery += " 		   ,D1_FILIAL"
	_oSQL:_sQuery += " 		   ,'05-Entrada_transf'"
	_oSQL:_sQuery += " 		   ,D1_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D1_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(D1_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM SD1010"
	_oSQL:_sQuery += " 		WHERE D1_COD IN (SELECT"
	_oSQL:_sQuery += " 				B1_COD"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SB1") 
	_oSQL:_sQuery += " 			WHERE D_E_L_E_T_ = '')"
	_oSQL:_sQuery += " 		AND D1_DTDIGIT BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D1_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4")  
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_TRANFIL = '1')"
	_oSQL:_sQuery += " 		GROUP BY D1_COD"
	_oSQL:_sQuery += " 				,D1_FILIAL"
	_oSQL:_sQuery += " 				,D1_DOC"
	_oSQL:_sQuery += " 				,D1_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--Saídas TRANSFERENCIAS
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			-SUM(D2_CUSTO1)"
	_oSQL:_sQuery += " 		   ,D2_COD"
	_oSQL:_sQuery += " 		   ,D2_FILIAL"
	_oSQL:_sQuery += " 		   ,'06-Saida_transf'"
	_oSQL:_sQuery += " 		   ,D2_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D2_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,-SUM(D2_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM SD2010"
	_oSQL:_sQuery += " 		WHERE D2_EMISSAO BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D2_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4")  
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_CONTERC != 'S'"
	_oSQL:_sQuery += " 			AND F4_TRANFIL = '1')"
	_oSQL:_sQuery += " 		GROUP BY D2_COD"
	_oSQL:_sQuery += " 				,D2_FILIAL"
	_oSQL:_sQuery += " 				,D2_DOC"
	_oSQL:_sQuery += " 				,D2_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--compras Terceiros - OK
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(D1_CUSTO)"
	_oSQL:_sQuery += " 		   ,D1_COD"
	_oSQL:_sQuery += " 		   ,D1_FILIAL"
	_oSQL:_sQuery += " 		   ,'07-Entradas_Terceiros'"
	_oSQL:_sQuery += " 		   ,D1_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D1_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,SUM(D1_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD1")  
	_oSQL:_sQuery += " 		WHERE D1_DTDIGIT BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D1_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4") 
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_PODER3 != 'N'"
	_oSQL:_sQuery += " 			AND F4_TRANFIL != '1')"
	_oSQL:_sQuery += " 		GROUP BY D1_COD"
	_oSQL:_sQuery += " 				,D1_FILIAL"
	_oSQL:_sQuery += " 				,D1_DOC"
	_oSQL:_sQuery += " 				,D1_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--Saídas Terceiros - OK
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			-SUM(D2_CUSTO1)"
	_oSQL:_sQuery += " 		   ,D2_COD"
	_oSQL:_sQuery += " 		   ,D2_FILIAL"
	_oSQL:_sQuery += " 		   ,'08-Saidas_Terceiros'"
	_oSQL:_sQuery += " 		   ,D2_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D2_LOCAL AS AX"
	_oSQL:_sQuery += "		   ,-SUM(D2_QUANT) AS QTD"
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD2")   
	_oSQL:_sQuery += " 		WHERE D2_EMISSAO BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D2_TES IN (SELECT"
	_oSQL:_sQuery += " 				F4_CODIGO"
	_oSQL:_sQuery += " 			FROM " + RetSqlName("SF4")  
	_oSQL:_sQuery += " 			WHERE F4_ESTOQUE = 'S'"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F4_PODER3 != 'N'"
	_oSQL:_sQuery += " 			AND F4_TRANFIL != '1')"
	_oSQL:_sQuery += " 		GROUP BY D2_COD"
	_oSQL:_sQuery += " 				,D2_FILIAL"
	_oSQL:_sQuery += " 				,D2_DOC"
	_oSQL:_sQuery += " 				,D2_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	-- MOVIMENTOações internas
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(CASE"
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_CUSTO1"
	_oSQL:_sQuery += " 				ELSE D3_CUSTO1"
	_oSQL:_sQuery += " 			END)"
	_oSQL:_sQuery += " 		   ,D3_COD"
	_oSQL:_sQuery += " 		   ,D3_FILIAL"
	_oSQL:_sQuery += " 		   ,'09-Movimento_Interno'"
	_oSQL:_sQuery += " 		   ,D3_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D3_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(CASE
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_QUANT
	_oSQL:_sQuery += " 				ELSE D3_QUANT
	_oSQL:_sQuery += " 		   	END) as QTD
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD3")  
	_oSQL:_sQuery += " 		WHERE D3_OP = ''"
	_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D3_ESTORNO = ''"
	_oSQL:_sQuery += " 		AND D3_CF != 'PR0'"
	_oSQL:_sQuery += " 		AND D3_CF NOT LIKE '%4'"
	_oSQL:_sQuery += " 		GROUP BY D3_COD"
	_oSQL:_sQuery += " 				,D3_FILIAL"
	_oSQL:_sQuery += " 				,D3_DOC"
	_oSQL:_sQuery += " 				,D3_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	-- REQUISIÇÃO PARA OP - erro
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(CASE"
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_CUSTO1"
	_oSQL:_sQuery += " 				ELSE D3_CUSTO1"
	_oSQL:_sQuery += " 			END)"
	_oSQL:_sQuery += " 		   ,D3_COD"
	_oSQL:_sQuery += " 		   ,D3_FILIAL"
	_oSQL:_sQuery += " 		   ,'10-Requisicao_OP'"
	_oSQL:_sQuery += " 		   ,D3_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D3_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(CASE
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_QUANT
	_oSQL:_sQuery += " 				ELSE D3_QUANT
	_oSQL:_sQuery += " 		   	END) as QTD
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD3") 
	_oSQL:_sQuery += " 		WHERE D3_OP != ''"
	_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D3_ESTORNO = ''"
	_oSQL:_sQuery += " 		AND D3_CF != 'PR0'"
	_oSQL:_sQuery += " 		AND D3_CF NOT LIKE '%4'"
	_oSQL:_sQuery += " 		GROUP BY D3_COD"
	_oSQL:_sQuery += " 				,D3_FILIAL"
	_oSQL:_sQuery += " 				,D3_DOC"
	_oSQL:_sQuery += " 				,D3_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	-- Produção Por OP - OK
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(CASE"
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_CUSTO1"
	_oSQL:_sQuery += " 				ELSE D3_CUSTO1"
	_oSQL:_sQuery += " 			END)"
	_oSQL:_sQuery += " 		   ,D3_COD"
	_oSQL:_sQuery += " 		   ,D3_FILIAL"
	_oSQL:_sQuery += " 		   ,'11-Produção_OP'"
	_oSQL:_sQuery += " 		   ,D3_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D3_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(CASE
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_QUANT
	_oSQL:_sQuery += " 				ELSE D3_QUANT
	_oSQL:_sQuery += " 		   	END) as QTD
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD3") 
	_oSQL:_sQuery += " 		WHERE D3_OP != ''"
	_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D3_ESTORNO = ''"
	_oSQL:_sQuery += " 		AND D3_CF = 'PR0'"
	_oSQL:_sQuery += " 		AND D3_CF NOT LIKE '%4'"
	_oSQL:_sQuery += " 		GROUP BY D3_COD"
	_oSQL:_sQuery += " 				,D3_FILIAL"
	_oSQL:_sQuery += " 				,D3_DOC"
	_oSQL:_sQuery += " 				,D3_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--transferencias internas--
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(CASE"
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_CUSTO1"
	_oSQL:_sQuery += " 				ELSE D3_CUSTO1"
	_oSQL:_sQuery += " 			END)"
	_oSQL:_sQuery += " 		   ,D3_COD"
	_oSQL:_sQuery += " 		   ,D3_FILIAL"
	_oSQL:_sQuery += " 		   ,'04-Saida_Transf_Interna'"
	_oSQL:_sQuery += " 		   ,D3_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D3_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(CASE
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_QUANT
	_oSQL:_sQuery += " 				ELSE D3_QUANT
	_oSQL:_sQuery += " 		   	END) as QTD
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD3") 
	_oSQL:_sQuery += " 		WHERE D3_OP = ''"
	_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D3_ESTORNO = ''"
	_oSQL:_sQuery += " 		AND D3_CF != 'PR0'"
	_oSQL:_sQuery += " 		AND D3_CF LIKE 'RE4'"
	_oSQL:_sQuery += " 		GROUP BY D3_COD"
	_oSQL:_sQuery += " 				,D3_FILIAL"
	_oSQL:_sQuery += " 				,D3_DOC"
	_oSQL:_sQuery += " 				,D3_LOCAL"
	_oSQL:_sQuery += " 		UNION"
	//	--transferencia interna--
	_oSQL:_sQuery += " 		SELECT"
	_oSQL:_sQuery += " 			SUM(CASE"
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_CUSTO1"
	_oSQL:_sQuery += " 				ELSE D3_CUSTO1"
	_oSQL:_sQuery += " 			END)"
	_oSQL:_sQuery += " 		   ,D3_COD"
	_oSQL:_sQuery += " 		   ,D3_FILIAL"
	_oSQL:_sQuery += " 		   ,'03-Entrada_Transf_Interna'"
	_oSQL:_sQuery += " 		   ,D3_DOC AS DOC"
	_oSQL:_sQuery += " 		   ,D3_LOCAL AS AX"
	_oSQL:_sQuery += " 		   ,SUM(CASE
	_oSQL:_sQuery += " 				WHEN D3_CF LIKE 'RE%' THEN -D3_QUANT
	_oSQL:_sQuery += " 				ELSE D3_QUANT
	_oSQL:_sQuery += " 		   	END) as QTD
	_oSQL:_sQuery += " 		FROM " + RetSqlName("SD3") 
	_oSQL:_sQuery += " 		WHERE D3_OP = ''"
	_oSQL:_sQuery += " 		AND D3_EMISSAO BETWEEN  '" + dtos(_DtRefIni) + "' AND '" + dtos(_DtRefFin) + "'"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND D3_ESTORNO = ''"
	_oSQL:_sQuery += " 		AND D3_CF != 'PR0'"
	_oSQL:_sQuery += " 		AND D3_CF LIKE 'DE4'"
	_oSQL:_sQuery += " 		GROUP BY D3_COD"
	_oSQL:_sQuery += " 				,D3_FILIAL"
	_oSQL:_sQuery += " 				,D3_DOC"
	_oSQL:_sQuery += " 				,D3_LOCAL)"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		B1_TIPO"
	_oSQL:_sQuery += " 	   ,COD"
	_oSQL:_sQuery += " 	   ,SUM(VALOR) AS VALOR"
	_oSQL:_sQuery += " 	   ,DOC"
	_oSQL:_sQuery += " 	   ,MOVIMENTO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,AX"
	_oSQL:_sQuery += "     ,SUM(QTD) AS QTD"
	_oSQL:_sQuery += " 	FROM entSaida"
	_oSQL:_sQuery += " 	LEFT JOIN SB1010"
	_oSQL:_sQuery += " 		ON entSaida.COD = B1_COD"
	_oSQL:_sQuery += " 			AND D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	GROUP BY B1_TIPO"
	_oSQL:_sQuery += " 			,MOVIMENTO"
	_oSQL:_sQuery += " 			,DOC"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,COD"
	_oSQL:_sQuery += " 			,AX"
	_oSQL:Log ()
	
	_oSQL:Qry2Xls ()
	
Return
// --------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Ano de referência      	", "C", 4, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Mês de referência   	", "C", 2, 0,  "",  "   ", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return