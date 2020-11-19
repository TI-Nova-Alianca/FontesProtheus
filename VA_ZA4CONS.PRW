// Programa...: VA_ZA4CONS
// Autor......: Catia Cardoso
// Data.......: 08/04/2015
// Descricao..: Controle de Verbas - Consulta Verbas 
//
// Alterações:
// 14/05/2015 - Catia   - Alterado Tipos de Verbas
// 23/06/2015 - Catia   - Incluido campo ZA4_CTB
// 08/07/2015 - Catia   - Erro quando consultava uma verba utilizada ao abrir a subconsulta
// 10/01/2018 - Catia   - Chamado 3304 - solicitacao para incluir o estado e o vendedor na consulta de verbas
// 15/11/2018 - Andre   - Acrescentado campo Data Vencimento
// 29/08/2019 - Robert  - Consulta em loop para nao sair da tela entre uma execucao e outra.
// 06/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
// 29/07/2020 - Cláudia - Ajustada a consulta conforme GLPI: 8198
// 18/08/2020 - Cláudia - Adicionado combo de seleção do tipo de vendedor. GLPI:8344
// -------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ZA4CONS()
	local i	:= 0
	cPerg   := "ZA4CONS"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	//do while Pergunte(cPerg,.T.)
	// ajusta mv_par13 - tipos de verba
	if mv_par13 != '123456'
		_wtipos_verba = ''
		for i=1 to len(mv_par13)
			if substr(mv_par13,i,i) != '*'
				if substr(mv_par13,i,i) = '6'
					_wtipos_verba = _wtipos_verba + "'9',"
				else
					_wtipos_verba = _wtipos_verba + "'" + substr(mv_par13,i,1) + "',"
				endif
			endif
		next
		_wtipos_verba = substr(_wtipos_verba, 1 ,len(_wtipos_verba)-1 )
	endif		
	// ajusta mv_par15 - tipos de liberacao
	if mv_par15 != '123456'
		_wtipos_lib = ''
		for i=1 to len(mv_par15)
			if substr(mv_par15,i,i) != '*'
				_wtipos_lib = _wtipos_lib + "'" + substr(mv_par15,i,1) + "',"
			endif
		next
		_wtipos_lib = substr(_wtipos_lib, 1 ,len(_wtipos_lib)-1 )
	endif			
	// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " ("
	_oSQL:_sQuery += "  SELECT"
	_oSQL:_sQuery += " 	   ZA4.ZA4_NUM AS NUMVERBA"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DGER AS EMISSAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_CLI AS CLIENTE"
	_oSQL:_sQuery += "    ,ZA4.ZA4_LOJA AS LOJA"
	_oSQL:_sQuery += "    ,SA1.A1_NOME AS RAZAO_SOCIAL"
	_oSQL:_sQuery += "    ,SA1.A1_EST AS UF"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VEND AS VENDVERBA"
	_oSQL:_sQuery += "    ,SA3_VERB.A3_NOME AS NOME_VENDVERBA"
	_oSQL:_sQuery += "    ,ZA5.ZA5_VENNF AS VENDNF"
	_oSQL:_sQuery += "    ,SA3_NF.A3_NOME AS NOME_VENDNF"
	_oSQL:_sQuery += "    ,ZA4.ZA4_COD AS VERBA"
	_oSQL:_sQuery += "    ,ZA3.ZA3_DES AS DESCVERBA"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '1' THEN 'Anual'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '2' THEN 'Trimestral'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '3' THEN 'Mensal'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '4' THEN 'Semestral'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '5' THEN 'Eventual Contato'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '9' THEN 'Acordo Isolado'"
	_oSQL:_sQuery += " 		ELSE ''"
	_oSQL:_sQuery += " 	END AS TIPO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '1' THEN 'Encartes/ponto extra'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '2' THEN 'Feiras'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '3' THEN 'Fretes'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '4' THEN 'Campanhas de vendas'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '5' THEN 'Abert/reinaugur.loja'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '6' THEN 'Multa contratual'"
	_oSQL:_sQuery += " 		ELSE ''"
	_oSQL:_sQuery += " 	END AS CTB"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DOC AS DOCUMENTO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '1' THEN 'Bonificação'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '2' THEN 'Desconto'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '3' THEN 'Boleto'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '4' THEN 'Deposito'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '5' THEN 'NAO AUTORIZADA'"
	_oSQL:_sQuery += " 		ELSE 'NAO LIBERADA'"
	_oSQL:_sQuery += " 	END AS TIPO_LIB"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VLR AS VALOR"
	_oSQL:_sQuery += "    ,ROUND(ZA4.ZA4_VLR - SUM(ZA5_VLR), 2) AS SALDO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '0' THEN 'Não'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '1' THEN 'Parcial'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '2' THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE '***'"
	_oSQL:_sQuery += " 	END AS UTILIZADA"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DLIB AS DTLIBERACAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_ULIB AS USULIBERACAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VENCTO AS DTVENCIMENTO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZA4") + " AS ZA4 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZA5") + " AS ZA5 "
	_oSQL:_sQuery += " 	ON (ZA5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND ZA5.ZA5_NUM = ZA4.ZA4_NUM"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA1.A1_COD = ZA4.ZA4_CLI"
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
	_oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("SA3") + " AS SA3_VERB " 
	_oSQL:_sQuery += " 	ON (SA3_VERB.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA3_VERB.A3_COD = ZA4.ZA4_VEND)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3_NF " 
	_oSQL:_sQuery += " 	ON (SA3_NF.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA3_NF.A3_COD = ZA5.ZA5_VENNF)"
	_oSQL:_sQuery += " INNER JOIN  " + RetSQLName ("ZA3") + " AS ZA3 " 
	_oSQL:_sQuery += " 	ON (ZA3.D_E_L_E_T_ = ''"
	if mv_par13 != '123456'
		_oSQL:_sQuery += "          AND ZA3.ZA3_IND IN (" + _wtipos_verba  + ")"
	endif	
	_oSQL:_sQuery += " 			AND ZA3.ZA3_COD = ZA4.ZA4_COD)"
	_oSQL:_sQuery += " WHERE ZA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZA4.ZA4_NUM  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_CLI  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_DGER BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_COD  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if mv_par15 != '123456'
		_oSQL:_sQuery += "  AND ZA4.ZA4_TLIB IN (" + _wtipos_lib  + ")"
	endif		
	if mv_par16 != 1
		if mv_par16 ==2
			_oSQL:_sQuery += "  AND ZA4.ZA4_SUTL != '0' " 
		else
			_oSQL:_sQuery += "  AND ZA4.ZA4_SUTL = '0' "
		endif	
	endif
	_oSQL:_sQuery += " GROUP BY ZA4.ZA4_NUM"
	_oSQL:_sQuery += " 		,ZA4.ZA4_DGER"
	_oSQL:_sQuery += " 		,ZA4.ZA4_CLI"
	_oSQL:_sQuery += " 		,ZA4.ZA4_LOJA"
	_oSQL:_sQuery += " 		,SA1.A1_NOME"
	_oSQL:_sQuery += " 		,SA1.A1_EST"
	_oSQL:_sQuery += " 		,SA1.A1_VEND"
	_oSQL:_sQuery += " 		,ZA4.ZA4_COD"
	_oSQL:_sQuery += " 		,ZA3.ZA3_DES"
	_oSQL:_sQuery += " 		,ZA4.ZA4_DOC"
	_oSQL:_sQuery += " 		,ZA4.ZA4_VLR"
	_oSQL:_sQuery += " 		,ZA4.ZA4_VEND"
	_oSQL:_sQuery += " 		,ZA4.ZA4_DLIB"
	_oSQL:_sQuery += " 		,ZA4.ZA4_ULIB"
	_oSQL:_sQuery += " 		,ZA4.ZA4_VENCTO"
	_oSQL:_sQuery += " 		,ZA4.ZA4_TLIB"
	_oSQL:_sQuery += " 		,ZA3.ZA3_IND"
	_oSQL:_sQuery += " 		,SA3_NF.A3_NOME"
	_oSQL:_sQuery += " 		,SA3_VERB.A3_NOME"
	_oSQL:_sQuery += " 		,ZA4_CTB"
	_oSQL:_sQuery += " 		,ZA4_SUTL"
	_oSQL:_sQuery += " 		,ZA5.ZA5_VENVER"
	_oSQL:_sQuery += " 		,ZA5.ZA5_VENNF"
	_oSQL:_sQuery += " 		,ZA4.ZA4_VEND"
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	ZA4.ZA4_NUM AS NUMVERBA"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DGER AS EMISSAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_CLI AS CLIENTE"
	_oSQL:_sQuery += "    ,ZA4.ZA4_LOJA AS LOJA"
	_oSQL:_sQuery += "    ,SA1.A1_NOME AS RAZAO_SOCIAL"
	_oSQL:_sQuery += "    ,SA1.A1_EST AS UF"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VEND AS VENDVERBA"
	_oSQL:_sQuery += "    ,SA3_VERB.A3_NOME AS NOME_VENDVERBA"
	_oSQL:_sQuery += "    ,'-' AS VENDNF"
	_oSQL:_sQuery += "    ,'-' AS NOME_VENDNF"
	_oSQL:_sQuery += "    ,ZA4.ZA4_COD AS VERBA"
	_oSQL:_sQuery += "    ,ZA3.ZA3_DES AS DESCVERBA"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '1' THEN 'Anual'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '2' THEN 'Trimestral'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '3' THEN 'Mensal'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '4' THEN 'Semestral'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '5' THEN 'Eventual Contato'"
	_oSQL:_sQuery += " 		WHEN ZA3.ZA3_IND = '9' THEN 'Acordo Isolado'"
	_oSQL:_sQuery += " 		ELSE ''"
	_oSQL:_sQuery += " 	END AS TIPO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '1' THEN 'Encartes/ponto extra'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '2' THEN 'Feiras'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '3' THEN 'Fretes'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '4' THEN 'Campanhas de vendas'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '5' THEN 'Abert/reinaugur.loja'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_CTB = '6' THEN 'Multa contratual'"
	_oSQL:_sQuery += " 		ELSE ''"
	_oSQL:_sQuery += " 	END AS CTB"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DOC"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '1' THEN 'Bonificação'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '2' THEN 'Desconto'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '3' THEN 'Boleto'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '4' THEN 'Deposito'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_TLIB = '5' THEN 'NAO AUTORIZADA'"
	_oSQL:_sQuery += " 		ELSE 'NAO LIBERADA'"
	_oSQL:_sQuery += " 	END AS TIPO_LIB"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VLR AS VALOR"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VLR AS SALDO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '0' THEN 'Não'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '1' THEN 'Parcial'"
	_oSQL:_sQuery += " 		WHEN ZA4.ZA4_SUTL = '2' THEN 'Sim'"
	_oSQL:_sQuery += " 		ELSE '***'"
	_oSQL:_sQuery += " 	END AS UTILIZADA"
	_oSQL:_sQuery += "    ,ZA4.ZA4_DLIB AS DTLIBERACAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_ULIB AS USULIBERACAO"
	_oSQL:_sQuery += "    ,ZA4.ZA4_VENCTO AS DTVENCIMENTO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZA4") + " AS ZA4 " 
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 " 
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA1.A1_COD = ZA4.ZA4_CLI"
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3_VERB "   
	_oSQL:_sQuery += " 	ON (SA3_VERB.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA3_VERB.A3_COD = ZA4.ZA4_VEND)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZA3") + " AS ZA3 " 
	_oSQL:_sQuery += " 	ON (ZA3.D_E_L_E_T_ = ''"
	if mv_par13 != '123456'
		_oSQL:_sQuery += "          AND ZA3.ZA3_IND IN (" + _wtipos_verba  + ")"
	endif	
	_oSQL:_sQuery += " 			AND ZA3.ZA3_COD = ZA4.ZA4_COD)"
	_oSQL:_sQuery += " WHERE ZA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZA4.ZA4_NUM  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_CLI  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_DGER BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery += " AND ZA4.ZA4_COD  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if mv_par15 != '123456'
		_sQu_oSQL:_sQueryery += "  AND ZA4.ZA4_TLIB IN (" + _wtipos_lib  + ")"
	endif		
	if mv_par16 != 1
		if mv_par16 ==2
			_oSQL:_sQuery += "  AND ZA4.ZA4_SUTL != '0' " 
		else
			_oSQL:_sQuery += "  AND ZA4.ZA4_SUTL = '0' "
		endif	
	endif
	_oSQL:_sQuery += " AND ZA4.ZA4_NUM NOT IN (SELECT"
	_oSQL:_sQuery += " 		ZA5.ZA5_NUM"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZA5") + " AS ZA5 " 
	_oSQL:_sQuery += " 	WHERE ZA5.D_E_L_E_T_ = '')"
	_oSQL:_sQuery += " 	)"
	_oSQL:_sQuery += " 	SELECT "
	_oSQL:_sQuery += " 		NUMVERBA"
	_oSQL:_sQuery += " 	   ,CONVERT(DATE, EMISSAO, 103) AS EMISSAO "
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,RAZAO_SOCIAL"
	_oSQL:_sQuery += " 	   ,UF"
	If mv_par19 == 3 .or. mv_par19 == 1
		_oSQL:_sQuery += " 	   ,VENDVERBA"
		_oSQL:_sQuery += " 	   ,NOME_VENDVERBA"
	EndIf
	If mv_par19 == 3 .or. mv_par19 == 2
		_oSQL:_sQuery += " 	   ,VENDNF"
		_oSQL:_sQuery += " 	   ,NOME_VENDNF"
	EndIf
	_oSQL:_sQuery += " 	   ,VERBA"
	_oSQL:_sQuery += " 	   ,DESCVERBA"
	_oSQL:_sQuery += " 	   ,TIPO"
	_oSQL:_sQuery += " 	   ,CTB"
	_oSQL:_sQuery += " 	   ,DOCUMENTO"
	_oSQL:_sQuery += " 	   ,TIPO_LIB"
	_oSQL:_sQuery += " 	   ,VALOR"
	_oSQL:_sQuery += " 	   ,SALDO"
	_oSQL:_sQuery += " 	   ,UTILIZADA"
	_oSQL:_sQuery += " 	   ,CONVERT(DATE, DTLIBERACAO, 103) AS DTLIBERACAO "
	_oSQL:_sQuery += " 	   ,USULIBERACAO"
	_oSQL:_sQuery += " 	   ,CONVERT(DATE, DTVENCIMENTO, 103) AS DTVENCIMENTO "
	_oSQL:_sQuery += " 	FROM C"
	if mv_par18 = 1
		_oSQL:_sQuery += " 	WHERE C.SALDO > 0"
	endif
	_oSQL:_sQuery += " 	ORDER BY "
	do case
		case mv_par17 = 1
			_oSQL:_sQuery += " 	C.NUMVERBA"
		case mv_par17 = 2
			_oSQL:_sQuery += " 	C.EMISSAO"
		case mv_par17 = 3
			_oSQL:_sQuery += " 	C.CLIENTE, C.LOJA, C.EMISSAO"
		case mv_par17 = 4
			_oSQL:_sQuery += " 	C.VERBA"
		case mv_par17 = 5
			_oSQL:_sQuery += " 	C.TIPO_LIB"
	endcase
	
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array ()

	if len(_aDados) > 0
	
		_aCols = {}
	
		If mv_par19 == 3 
			aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
	    	aadd (_aCols, {02, "Emissao"        	,  30,  "@D"})
	    	aadd (_aCols, {03, "Cliente"        	,  30,  "@!"})
	    	aadd (_aCols, {04, "Loja"           	,  10,  "@!"})
	    	aadd (_aCols, {05, "Razão Social"   	, 140,  "@!"})
	    	aadd (_aCols, {06, "UF"             	,  10,  "@!"})
			aadd (_aCols, {07, "Vendedor Verba"     ,  20,  "@!"})
			aadd (_aCols, {08, "Nome Vendedor"  	, 140,  "@!"})
			aadd (_aCols, {09, "Vendedor Nota"      ,  20,  "@!"})
			aadd (_aCols, {10, "Nome Vendedor"  	, 140,  "@!"})
	    	aadd (_aCols, {11, "Verba"       	  	,  20,  "@!"})
	    	aadd (_aCols, {12, "Descricao"         	,  90,  "@!"})
	    	aadd (_aCols, {13, "Tipo"     			,  70,  "@!"})
	    	aadd (_aCols, {14, "Contabilizar"  	    ,  70,  "@!"})
	    	aadd (_aCols, {15, "Documento"      	,  50,  "@!"})
	    	aadd (_aCols, {16, "Tipo Liberacao"    	,  40,  "@!"})
	    	aadd (_aCols, {17, "Valor"       	    ,  50,  "@E 999,999,999.99"})
	    	aadd (_aCols, {18, "Saldo"       	    ,  50,  "@E 999,999,999.99"})
	    	aadd (_aCols, {19, "Utilizada"          ,  30,  "@!"})
	    	aadd (_aCols, {20, "Data Liberacao"    	,  20,  "@D"})
	    	aadd (_aCols, {21, "Usuario Liberacao"  ,  60,  "@!"})
	    	aadd (_aCols, {22, "Data Vencimento"  	,  20,  "@D"})
    	else
	    	aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
	    	aadd (_aCols, {02, "Emissao"        	,  30,  "@D"})
	    	aadd (_aCols, {03, "Cliente"        	,  30,  "@!"})
	    	aadd (_aCols, {04, "Loja"           	,  10,  "@!"})
	    	aadd (_aCols, {05, "Razão Social"   	, 140,  "@!"})
	    	aadd (_aCols, {06, "UF"             	,  10,  "@!"})
	    	If mv_par19 == 1
	    		aadd (_aCols, {07, "Vendedor Verba"     ,  20,  "@!"})
	    		aadd (_aCols, {08, "Nome Vendedor"  	, 140,  "@!"})
	    	EndIf
	    	If mv_par19 == 2
	    		aadd (_aCols, {07, "Vendedor Nota"    ,  20,  "@!"})
	    		aadd (_aCols, {08, "Nome Vendedor"  	, 140,  "@!"})
	    	EndIf
	    	aadd (_aCols, {09, "Verba"       	  	,  20,  "@!"})
	    	aadd (_aCols, {10, "Descricao"         	,  90,  "@!"})
	    	aadd (_aCols, {11, "Tipo"     			,  70,  "@!"})
	    	aadd (_aCols, {12, "Contabilizar"  	    ,  70,  "@!"})
	    	aadd (_aCols, {13, "Documento"      	,  50,  "@!"})
	    	aadd (_aCols, {14, "Tipo Liberacao"    	,  40,  "@!"})
	    	aadd (_aCols, {15, "Valor"       	    ,  50,  "@E 999,999,999.99"})
	    	aadd (_aCols, {16, "Saldo"       	    ,  50,  "@E 999,999,999.99"})
	    	aadd (_aCols, {17, "Utilizada"          ,  30,  "@!"})
	    	aadd (_aCols, {18, "Data Liberacao"    	,  20,  "@D"})
	    	aadd (_aCols, {19, "Usuario Liberacao"  ,  60,  "@!"})
	    	aadd (_aCols, {20, "Data Vencimento"  	,  20,  "@D"})
	    EndIf
    	
    	_wlinha = U_F3Array (_aDados, "Consulta Verbas de Clientes", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -30 , "", "", .T., 'C' )
    	
    	if _wlinha > 0
    		if ALLTRIM(_aDados[_wlinha,19]) != 'NAO'
				_sQuery1 := ""
    			_sQuery1 += "SELECT ZA5.ZA5_NUM"
	    		_sQuery1 += "	  , ZA5.ZA5_SEQ"
	     		_sQuery1 += "	  , ZA5.ZA5_CLI"
		 		_sQuery1 += "	  , ZA5.ZA5_LOJA"
		 		_sQuery1 += "	  , SA1.A1_NOME"
		 		_sQuery1 += " 	  , ZA5.ZA5_DTA"
				_sQuery1 += "     , CASE WHEN ZA5.ZA5_TLIB='1' THEN 'Bonificação'"
				_sQuery1 += "      	     WHEN ZA5.ZA5_TLIB='2' THEN 'Desconto'"
				_sQuery1 += "     	     WHEN ZA5.ZA5_TLIB='3' THEN 'Boleto'"
				_sQuery1 += "     	     WHEN ZA5.ZA5_TLIB='4' THEN 'Deposito'"
				_sQuery1 += "    	     WHEN ZA5.ZA5_TLIB='5' THEN 'NAO AUTORIZADA'"
				_sQuery1 += "    	     WHEN ZA5.ZA5_TLIB='9' THEN 'Zeramento Saldo'"
				_sQuery1 += "       ELSE 'NAO LIBERADA' END"
				_sQuery1 += "	  , ZA5.ZA5_VLR"
				_sQuery1 += "	  , ZA5.ZA5_DOC" 
				_sQuery1 += " 	  , ZA5.ZA5_USU"
				_sQuery1 += "  FROM ZA5010 AS ZA5"
				_sQuery1 += " 	  INNER JOIN SA1010 AS SA1"
				_sQuery1 += "    	    ON (SA1.D_E_L_E_T_  = ''"
				_sQuery1 += "        	    AND SA1.A1_COD = ZA5.ZA5_CLI"
				_sQuery1 += "               AND SA1.A1_LOJA   = ZA5.ZA5_LOJA)"
				_sQuery1 += " WHERE ZA5.D_E_L_E_T_ = ''
	 			_sQuery1 += "   AND ZA5.ZA5_NUM = " + _aDados[_wlinha,1]
	 			_sQuery1 += " ORDER BY ZA5_NUM, ZA5_SEQ"
				    				    		
	    		_aDados1 := U_Qry2Array(_sQuery1)
	    		
				if len(_aDados1) > 0
	    			_aCols1 = {}
	    	
	    			aadd (_aCols1, {01, "Num.Verba"       	,  10,  "@!"})
		    		aadd (_aCols1, {02, "SEQ"        	 	,  10,  "@D"})
		    		aadd (_aCols1, {03, "Cliente"        	,  30,  "@!"})
		    		aadd (_aCols1, {04, "Loja"           	,  10,  "@!"})
		    		aadd (_aCols1, {05, "Razão Social"   	, 140,  "@!"})
		    		aadd (_aCols1, {06, "Data" 	     	  	,  30,  "@!"})
		    		aadd (_aCols1, {07, "Liberacao"        	,  30,  "@!"})
		    		aadd (_aCols1, {08, "Valor"       	    ,  60,  "@E 999,999.99"})
		    		aadd (_aCols1, {09, "Documento" 		,  50,  "@!"})
		    		aadd (_aCols1, {10, "Usuário"	 		,  60,  "@!"})
	    	
	    			U_F3Array (_aDados1, "Consulta Utilizacao da Verba: "+_aDados[_wlinha,6] +" - "+_aDados[_wlinha,7], _aCols1, oMainWnd:nClientWidth - 300, oMainWnd:nClientHeight -200 , "", "", .T., 'C' )
				endif    		 
	    	endif
		endif
	else
		u_help("Não foram encontrados dados para consulta")			
	endif			    	
return
//
// -------------------------------------------------------------------------------------------------------------
User Function ZA4CONS1 ()
    local _sMvPar    := ''
    //local _sMvParDef := ""
    local _aOpcoes   := {}
    
    // Carrega array de opcoes
    aadd (_aOpcoes, '1 - Anual' )
    aadd (_aOpcoes, '2 - Trimestral' )
    aadd (_aOpcoes, '3 - Mensal' )
    aadd (_aOpcoes, '4 - Semestral' )
    aadd (_aOpcoes, '5 - Eventual' )
    aadd (_aOpcoes, '6 - Acordo Comercial' )
    f_Opcoes (@_sMvPar, ;  // Variavel para resultado
              "Selecione tipos de Verba", ;  // Titulo da janela
              _aOpcoes, ;  // Opcoes
              "123456", ;  // Inicializa posicoes
              12, 49, ;  // ?
              .F.)  // Nao exclusivo (permite selecionar mais de 1 opcao)
    &(ReadVar ()) := _smvpar  // Devolve Resultado para o parametro do relatorio.
Return .T.
//
// -------------------------------------------------------------------------------------------------------------
User Function ZA4CONS2 ()
    local _sMvPar    := ''
    //local _sMvParDef := ""
    local _aOpcoes   := {}
    
    // Carrega array de opcoes
    aadd (_aOpcoes, '1 - Bonificação' )
    aadd (_aOpcoes, '2 - Desconto' )
    aadd (_aOpcoes, '3 - Boleto' )
    aadd (_aOpcoes, '4 - Depósito' )
    aadd (_aOpcoes, '5 - NÃO AUTORIZADAS' )
    aadd (_aOpcoes, '6 - NÃO LIBERADAS' )
    f_Opcoes (@_sMvPar, ;  // Variavel para resultado
              "Selecione tipos de Verba", ;  // Titulo da janela
              _aOpcoes, ;  // Opcoes
              "123456", ;  // Inicializa posicoes
              12, 49, ;  // ?
              .F.)  // Nao exclusivo (permite selecionar mais de 1 opcao)
    &(ReadVar ()) := _smvpar  // Devolve Resultado para o parametro do relatorio.
Return .T.
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Cliente de                  ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate                 ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Data Emissao de             ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {04, "Data Emissao até            ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {05, "Data Liberacao de           ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {06, "Data Liberacao até          ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {07, "Numero de Verba de          ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {08, "Numero de Verba até         ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {09, "Código de Verba de          ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {10, "Código de Verba até         ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {11, "Contrato de                 ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {12, "Contrato até                ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {13, "Tipos de Verba              ?", "C", 6,  0,  "U_ZA4CONS1()", "",    {},  ""})
	aadd (_aRegsPerg, {14, "Tipo Inclusao               ?", "N", 1,  0,  "",   "   ", {"Todas","Inc.Manual","Ger.Contrato"},   ""})
	aadd (_aRegsPerg, {15, "Tipos de Liberação          ?", "C", 6,  0,  "U_ZA4CONS2()", "",    {},  ""})
	aadd (_aRegsPerg, {16, "Utilizadas/Pagas            ?", "N", 1,  0,  "",   "   ", {"Todas","Utilizadas","Não Utilizadas"},   ""})
	aadd (_aRegsPerg, {17, "Ordenar por                 ?", "N", 1,  0,  "",   "   ", {"Numero","Emissao","Cliente","Verba","Tipo Liberação"},   ""})
	aadd (_aRegsPerg, {18, "Lista Saldo Zero            ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   ""})
	aadd (_aRegsPerg, {19, "Tipo vendedor               ?", "N", 1,  0,  "",   "   ", {"Verba","Nota","Ambos"}	,  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
// ---------------------------------------------------------------------------------------------------------------------------
//#include "rwmake.ch"
//#include "VA_INCLU.prw"
//
//User function VA_ZA4CONS()
//	local i	:= 0
//	cPerg   := "ZA4CONS"
//	
//	_ValidPerg()
//	Pergunte(cPerg,.T.)
//	
//	//do while Pergunte(cPerg,.T.)
//	// ajusta mv_par13 - tipos de verba
//	if mv_par13 != '123456'
//		_wtipos_verba = ''
//		for i=1 to len(mv_par13)
//			if substr(mv_par13,i,i) != '*'
//				if substr(mv_par13,i,i) = '6'
//					_wtipos_verba = _wtipos_verba + "'9',"
//				else
//					_wtipos_verba = _wtipos_verba + "'" + substr(mv_par13,i,1) + "',"
//				endif
//			endif
//		next
//		_wtipos_verba = substr(_wtipos_verba, 1 ,len(_wtipos_verba)-1 )
//	endif		
//	// ajusta mv_par15 - tipos de liberacao
//	if mv_par15 != '123456'
//		_wtipos_lib = ''
//		for i=1 to len(mv_par15)
//			if substr(mv_par15,i,i) != '*'
//				_wtipos_lib = _wtipos_lib + "'" + substr(mv_par15,i,1) + "',"
//			endif
//		next
//		_wtipos_lib = substr(_wtipos_lib, 1 ,len(_wtipos_lib)-1 )
//	endif			
//	// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
//	_sQuery := ""
//	_sQuery += " WITH C AS ( SELECT ZA4.ZA4_NUM"
// 	_sQuery += "	 , ZA4.ZA4_DGER"
// 	_sQuery += "	 , ZA4.ZA4_CLI"
// 	_sQuery += "	 , ZA4.ZA4_LOJA"
// 	_sQuery += "	 , SA1.A1_NOME"
// 	_sQuery += "	 , SA1.A1_EST"    
// 	_sQuery += "	 , SA1.A1_VEND"
// 	_sQuery += "	 , SA3.A3_NOME"
// 	_sQuery += "	 , ZA4.ZA4_COD"
// 	_sQuery += "	 , ZA3.ZA3_DES"
// 	_sQuery += "	 , CASE WHEN ZA3.ZA3_IND='1' THEN 'Anual'"
//	_sQuery += "			WHEN ZA3.ZA3_IND='2' THEN 'Trimestral'"
//	_sQuery += "			WHEN ZA3.ZA3_IND='3' THEN 'Mensal'"
//	_sQuery += "			WHEN ZA3.ZA3_IND='4' THEN 'Semestral'"
//	_sQuery += "			WHEN ZA3.ZA3_IND='5' THEN 'Eventual Contato'"
//	_sQuery += "			WHEN ZA3.ZA3_IND='9' THEN 'Acordo Isolado'"
//	_sQuery += "	   ELSE '' END AS TIPO"
//	_sQuery += "  	, CASE WHEN ZA4.ZA4_CTB='1' THEN 'Encartes/ponto extra'"
//	_sQuery += "    	   WHEN ZA4.ZA4_CTB='2' THEN 'Feiras'"
//	_sQuery += "    	   WHEN ZA4.ZA4_CTB='3' THEN 'Fretes'"
//	_sQuery += "    	   WHEN ZA4.ZA4_CTB='4' THEN 'Campanhas de vendas'"
//	_sQuery += "    	   WHEN ZA4.ZA4_CTB='5' THEN 'Abert/reinaugur.loja'"
//	_sQuery += "    	   WHEN ZA4.ZA4_CTB='6' THEN 'Multa contratual'"
//	_sQuery += "	   ELSE '' END AS CTB"
//	_sQuery += "	, ZA4.ZA4_DOC"
//	_sQuery += "  	, CASE WHEN ZA4.ZA4_TLIB='1' THEN 'Bonificação'"
//	_sQuery += "    	   WHEN ZA4.ZA4_TLIB='2' THEN 'Desconto'"
//	_sQuery += "    	   WHEN ZA4.ZA4_TLIB='3' THEN 'Boleto'"
//	_sQuery += "    	   WHEN ZA4.ZA4_TLIB='4' THEN 'Deposito'"
//	_sQuery += "    	   WHEN ZA4.ZA4_TLIB='5' THEN 'NAO AUTORIZADA'"
//	_sQuery += "      ELSE 'NAO LIBERADA' END AS TIPO_LIB"
//	_sQuery += "	, ZA4.ZA4_VLR"
//	_sQuery += "    , ROUND(ZA4.ZA4_VLR - ISNULL( ( SELECT SUM(ZA5_VLR)" 
//	_sQuery += "        			   		    FROM ZA5010"
//	_sQuery += "       				  		   WHERE D_E_L_E_T_ = ''"
//	_sQuery += "         						 AND ZA5_NUM    = ZA4.ZA4_NUM) ,0),2) AS VLR_SLD"
//	_sQuery += " 	, CASE WHEN ZA4.ZA4_SUTL='0'  THEN 'Não'"
//	_sQuery += " 	       WHEN ZA4.ZA4_SUTL='1'  THEN 'Parcial'"
//	_sQuery += " 	       WHEN ZA4.ZA4_SUTL='2'  THEN 'Sim'"
//	_sQuery += "      ELSE '***' END AS UTILIZADA"
//	_sQuery += " 	, ZA4.ZA4_DLIB"
//	_sQuery += " 	, ZA4.ZA4_ULIB"
//	_sQuery += " 	, ZA4.ZA4_VENCTO"
//	_sQuery += " 	, ZA4.ZA4_TLIB AS ZA4_TLIB"
//	_sQuery += " FROM ZA4010 AS ZA4"
//	_sQuery += " 	INNER JOIN SA1010 AS SA1"
//	_sQuery += "    	ON (SA1.D_E_L_E_T_  = ''"
//	_sQuery += "        	AND SA1.A1_COD  = ZA4.ZA4_CLI"
//	_sQuery += " 	   		AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
//	_sQuery += " 	INNER JOIN SA3010 AS SA3"
//	_sQuery += " 	    ON (SA3.D_E_L_E_T_ = ''"
//	_sQuery += " 	        AND SA3.A3_COD = SA1.A1_VEND)"
//	_sQuery += " 	INNER JOIN ZA3010 AS ZA3"
//	_sQuery += "    	ON (ZA3.D_E_L_E_T_  = ''"
//	if mv_par13 != '123456'
//		_sQuery += "            AND ZA3.ZA3_IND IN (" + _wtipos_verba  + ")"
//	endif			
//	_sQuery += "        	AND ZA3.ZA3_COD  = ZA4.ZA4_COD )"
//	_sQuery += "WHERE ZA4.D_E_L_E_T_ = ''
//	_sQuery += "  AND ZA4.ZA4_NUM    BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
//	_sQuery += "  AND ZA4.ZA4_CLI    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
//	_sQuery += "  AND ZA4.ZA4_DGER   BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
//	_sQuery += "  AND ZA4.ZA4_COD    BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
//	if mv_par15 != '123456'
//		_sQuery += "  AND ZA4.ZA4_TLIB IN (" + _wtipos_lib  + ")"
//	endif		
//	if mv_par16 != 1
//		if mv_par16 ==2
//			_sQuery += "  AND ZA4.ZA4_SUTL != '0' " 
//		else
//			_sQuery += "  AND ZA4.ZA4_SUTL = '0' "
//		endif	
//	endif
//	_sQuery += "  ) "
//	_sQuery += "  SELECT * "
//	_sQuery += "  FROM C "
//	if mv_par18 = 1
//		_sQuery += " WHERE C.VLR_SLD > 0"
//	endif
//	_sQuery += " ORDER BY "
//	do case
//		case mv_par17 = 1
//			_sQuery += " C.ZA4_NUM"
//		case mv_par17 = 2
//			_sQuery += " C.ZA4_DGER"
//		case mv_par17 = 3
//			_sQuery += " C.ZA4_CLI, C.ZA4_DGER"
//		case mv_par17 = 4
//			_sQuery += " C.ZA4_COD"
//		case mv_par17 = 5
//			_sQuery += " C.ZA4_TLIB"
//	endcase
//				
//	nHandle := FCreate("c:\temp\va_za4cons.txt")
//	FWrite(nHandle,_sQuery )
//	FClose(nHandle)
//	//u_showmemo (_sQuery)
//	
//	_aDados := U_Qry2Array(_sQuery)
//	if len(_aDados) > 0
//	
//		_aCols = {}
//	
//    	aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
//    	aadd (_aCols, {02, "Emissao"        	,  30,  "@D"})
//    	aadd (_aCols, {03, "Cliente"        	,  30,  "@!"})
//    	aadd (_aCols, {04, "Loja"           	,  10,  "@!"})
//    	aadd (_aCols, {05, "Razão Social"   	, 140,  "@!"})
//    	aadd (_aCols, {06, "UF"             	,  10,  "@!"})
//    	aadd (_aCols, {07, "Vendedor"       	,  30,  "@!"})
//    	aadd (_aCols, {08, "Nome Vendedor"  	, 140,  "@!"})
//    	aadd (_aCols, {09, "Verba"       	  	,  20,  "@!"})
//    	aadd (_aCols, {10, "Descricao"         	,  90,  "@!"})
//    	aadd (_aCols, {11, "Tipo"     			,  70,  "@!"})
//    	aadd (_aCols, {12, "Contabilizar"  	    ,  70,  "@!"})
//    	aadd (_aCols, {13, "Documento"      	,  50,  "@!"})
//    	aadd (_aCols, {14, "Tipo Liberacao"    	,  40,  "@!"})
//    	aadd (_aCols, {15, "Valor"       	    ,  50,  "@E 999,999,999.99"})
//    	aadd (_aCols, {16, "Saldo"       	    ,  50,  "@E 999,999,999.99"})
//    	aadd (_aCols, {17, "Utilizada"          ,  30,  "@!"})
//    	aadd (_aCols, {18, "Data Liberacao"    	,  20,  "@D"})
//    	aadd (_aCols, {19, "Usuario Liberacao"  ,  60,  "@!"})
//    	aadd (_aCols, {20, "Data Vencimento"  	,  20,  "@D"})
//    	
//    	_wlinha = U_F3Array (_aDados, "Consulta Verbas de Clientes", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -30 , "", "", .T., 'C' )
//    	
//    	if _wlinha > 0
//    		if ALLTRIM(_aDados[_wlinha,14]) != 'NAO'
//				_sQuery1 := ""
//    			_sQuery1 += "SELECT ZA5.ZA5_NUM"
//	    		_sQuery1 += "	  , ZA5.ZA5_SEQ"
//	     		_sQuery1 += "	  , ZA5.ZA5_CLI"
//		 		_sQuery1 += "	  , ZA5.ZA5_LOJA"
//		 		_sQuery1 += "	  , SA1.A1_NOME"
//		 		_sQuery1 += " 	  , ZA5.ZA5_DTA"
//				_sQuery1 += "     , CASE WHEN ZA5.ZA5_TLIB='1' THEN 'Bonificação'"
//				_sQuery1 += "      	     WHEN ZA5.ZA5_TLIB='2' THEN 'Desconto'"
//				_sQuery1 += "     	     WHEN ZA5.ZA5_TLIB='3' THEN 'Boleto'"
//				_sQuery1 += "     	     WHEN ZA5.ZA5_TLIB='4' THEN 'Deposito'"
//				_sQuery1 += "    	     WHEN ZA5.ZA5_TLIB='5' THEN 'NAO AUTORIZADA'"
//				_sQuery1 += "    	     WHEN ZA5.ZA5_TLIB='9' THEN 'Zeramento Saldo'"
//				_sQuery1 += "       ELSE 'NAO LIBERADA' END"
//				_sQuery1 += "	  , ZA5.ZA5_VLR"
//				_sQuery1 += "	  , ZA5.ZA5_DOC" 
//				_sQuery1 += " 	  , ZA5.ZA5_USU"
//				_sQuery1 += "  FROM ZA5010 AS ZA5"
//				_sQuery1 += " 	  INNER JOIN SA1010 AS SA1"
//				_sQuery1 += "    	    ON (SA1.D_E_L_E_T_  = ''"
//				_sQuery1 += "        	    AND SA1.A1_COD = ZA5.ZA5_CLI"
//				_sQuery1 += "               AND SA1.A1_LOJA   = ZA5.ZA5_LOJA)"
//				_sQuery1 += " WHERE ZA5.D_E_L_E_T_ = ''
//	 			_sQuery1 += "   AND ZA5.ZA5_NUM = " + _aDados[_wlinha,1]
//	 			_sQuery1 += " ORDER BY ZA5_NUM, ZA5_SEQ"
//
//				//u_showmemo(_sQuery1)
//				    				    		
//	    		_aDados1 := U_Qry2Array(_sQuery1)
//	    		
//	    		//u_showarray(_aDados1)
//	    		
//				if len(_aDados1) > 0
//	    			_aCols1 = {}
//	    	
//	    			aadd (_aCols1, {01, "Num.Verba"       	,  10,  "@!"})
//		    		aadd (_aCols1, {02, "SEQ"        	 	,  10,  "@D"})
//		    		aadd (_aCols1, {03, "Cliente"        	,  30,  "@!"})
//		    		aadd (_aCols1, {04, "Loja"           	,  10,  "@!"})
//		    		aadd (_aCols1, {05, "Razão Social"   	, 140,  "@!"})
//		    		aadd (_aCols1, {06, "Data" 	     	  	,  30,  "@!"})
//		    		aadd (_aCols1, {07, "Liberacao"        	,  30,  "@!"})
//		    		aadd (_aCols1, {08, "Valor"       	    ,  60,  "@E 999,999.99"})
//		    		aadd (_aCols1, {09, "Documento" 		,  50,  "@!"})
//		    		aadd (_aCols1, {10, "Usuário"	 		,  60,  "@!"})
//	    	
//	    			U_F3Array (_aDados1, "Consulta Utilizacao da Verba: "+_aDados[_wlinha,6] +" - "+_aDados[_wlinha,7], _aCols1, oMainWnd:nClientWidth - 300, oMainWnd:nClientHeight -200 , "", "", .T., 'C' )
//				endif    		 
//	    	endif
//		endif
//	else
//		msgalert("Não foram encontrados dados para consulta")			
//	endif			    	
////	enddo
//return
////
//// -------------------------------------------------------------------------------------------------------------
//User Function ZA4CONS1 ()
//    local _sMvPar    := ''
//    local _sMvParDef := ""
//    local _aOpcoes   := {}
//    
//    // Carrega array de opcoes
//    aadd (_aOpcoes, '1 - Anual' )
//    aadd (_aOpcoes, '2 - Trimestral' )
//    aadd (_aOpcoes, '3 - Mensal' )
//    aadd (_aOpcoes, '4 - Semestral' )
//    aadd (_aOpcoes, '5 - Eventual' )
//    aadd (_aOpcoes, '6 - Acordo Comercial' )
//    f_Opcoes (@_sMvPar, ;  // Variavel para resultado
//              "Selecione tipos de Verba", ;  // Titulo da janela
//              _aOpcoes, ;  // Opcoes
//              "123456", ;  // Inicializa posicoes
//              12, 49, ;  // ?
//              .F.)  // Nao exclusivo (permite selecionar mais de 1 opcao)
//    &(ReadVar ()) := _smvpar  // Devolve Resultado para o parametro do relatorio.
//Return .T.
////
//// -------------------------------------------------------------------------------------------------------------
//User Function ZA4CONS2 ()
//    local _sMvPar    := ''
//    local _sMvParDef := ""
//    local _aOpcoes   := {}
//    
//    // Carrega array de opcoes
//    aadd (_aOpcoes, '1 - Bonificação' )
//    aadd (_aOpcoes, '2 - Desconto' )
//    aadd (_aOpcoes, '3 - Boleto' )
//    aadd (_aOpcoes, '4 - Depósito' )
//    aadd (_aOpcoes, '5 - NÃO AUTORIZADAS' )
//    aadd (_aOpcoes, '6 - NÃO LIBERADAS' )
//    f_Opcoes (@_sMvPar, ;  // Variavel para resultado
//              "Selecione tipos de Verba", ;  // Titulo da janela
//              _aOpcoes, ;  // Opcoes
//              "123456", ;  // Inicializa posicoes
//              12, 49, ;  // ?
//              .F.)  // Nao exclusivo (permite selecionar mais de 1 opcao)
//    &(ReadVar ()) := _smvpar  // Devolve Resultado para o parametro do relatorio.
//Return .T.
//// --------------------------------------------------------------------------
//// Cria Perguntas no SX1
//Static Function _ValidPerg ()
//    local _aRegsPerg := {}
//    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
//    aadd (_aRegsPerg, {01, "Cliente de                  ?", "C", 6, 0,  "",   "SA1", {},  ""})
//	aadd (_aRegsPerg, {02, "Cliente ate                 ?", "C", 6, 0,  "",   "SA1", {},  ""})
//	aadd (_aRegsPerg, {03, "Data Emissao de             ?", "D", 8, 0,  "",   "   ", {},  ""})
//    aadd (_aRegsPerg, {04, "Data Emissao até            ?", "D", 8, 0,  "",   "   ", {},  ""})
//    aadd (_aRegsPerg, {05, "Data Liberacao de           ?", "D", 8, 0,  "",   "   ", {},  ""})
//    aadd (_aRegsPerg, {06, "Data Liberacao até          ?", "D", 8, 0,  "",   "   ", {},  ""})
//    aadd (_aRegsPerg, {07, "Numero de Verba de          ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {08, "Numero de Verba até         ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {09, "Código de Verba de          ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {10, "Código de Verba até         ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {11, "Contrato de                 ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {12, "Contrato até                ?", "C", 9, 0,  "",   "   ", {},  ""})
//	aadd (_aRegsPerg, {13, "Tipos de Verba              ?", "C", 6,  0,  "U_ZA4CONS1()", "",    {},  ""})
//	aadd (_aRegsPerg, {14, "Tipo Inclusao               ?", "N", 1,  0,  "",   "   ", {"Todas","Inc.Manual","Ger.Contrato"},   ""})
//	aadd (_aRegsPerg, {15, "Tipos de Liberação          ?", "C", 6,  0,  "U_ZA4CONS2()", "",    {},  ""})
//	aadd (_aRegsPerg, {16, "Utilizadas/Pagas            ?", "N", 1,  0,  "",   "   ", {"Todas","Utilizadas","Não Utilizadas"},   ""})
//	aadd (_aRegsPerg, {17, "Ordenar por                 ?", "N", 1,  0,  "",   "   ", {"Numero","Emissao","Cliente","Verba","Tipo Liberação"},   ""})
//	aadd (_aRegsPerg, {18, "Lista Saldo Zero            ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   ""})
//	
//    U_ValPerg (cPerg, _aRegsPerg)
//Return
