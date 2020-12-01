// Programa:   BatGLT
// Autor:      Robert Koch
// Data:       12/03/2014
// Descricao:  Verificacoes diarias de guias de livre transito.
//             Criado para ser executado via batch.
//
// #TipoDePrograma    #batch
// #Descricao         #Envia e-mail de aviso sobre pendencias relativas a guias de livre transito.
// #PalavasChave      #guia_livre_transito #guia #entrada #saida
// #TabelasPrincipais #SF1 #SF2 #SD1 #SD2
// #Modulos 		  #FAT #COM
//
// Historico de alteracoes:
// 23/02/2016 - Robert  - Desconsidera especie CTE nas notas de entrada.
//                      - Considera somente B1_SISDEC = 'S'.
// 17/05/2016 - Robert  - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 06/11/2017 - Robert  - Desconsidera notas de transferencia simbolicas feitas em out/2017 para 
//                        equalizacao de custos entre filiais.
// 09/08/2018 - Robert  - Estabelace litragem minima (GLPI 1499).
// 12/09/2018 - Robert  - Desconsidera serie 99 (notas de cobertura de operacao triangular).
// 20/07/2020 - Claudia - Criada uma nova consulta para contemplar os novos campos solicitados. GLPI: 8164.
// 11/09/2020 - Robert  - Melhorados logs.
// 24/11/2020 - Claudia - Ajustadas as consultas conforme GLPI: 8768
// 01/12/2020 - Robert  - Faltava clausula AND F1_FILIAL = D1_FILIAL na query, deixando-a muio lenta.
//

// ---------------------------------------------------------------------------------------------------------
user function BatGLT ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _sMsg     := ""
	local _nDias    := 30

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " ("
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	'Tipo:' +"
	_oSQL:_sQuery += " 	CASE"
	_oSQL:_sQuery += " 		WHEN D2_TIPO IN ('D', 'B') THEN 'FORNECEDOR'"
	_oSQL:_sQuery += " 		ELSE 'CLIENTE'"
	_oSQL:_sQuery += " 	END AS TIPO"
	_oSQL:_sQuery += "    ,(SELECT"
	_oSQL:_sQuery += " 			M0_FILIAL"
	_oSQL:_sQuery += " 		FROM VA_SM0"
	_oSQL:_sQuery += " 		WHERE M0_CODIGO = '01'"
	_oSQL:_sQuery += " 		AND M0_CODFIL = SD2.D2_FILIAL)"
	_oSQL:_sQuery += " 	AS EMITENTE"
	_oSQL:_sQuery += "    ,IIF(D2_TIPO IN ('D', 'B'), A2_NREDUZ, A1_NREDUZ) AS DESTINATARIO"
	_oSQL:_sQuery += "    ,dbo.VA_DTOC(D2_EMISSAO) AS DT_EMISSAO"
	_oSQL:_sQuery += "    ,X5_DESCRI AS TIPO_OPERACAO"
	_oSQL:_sQuery += "    ,'NF:' + D2_DOC + '/' + D2_SERIE AS NF"
	_oSQL:_sQuery += "    ,F2_TRANSP + '- ' + SA4.A4_NREDUZ AS TRANSPORTADOR"
	_oSQL:_sQuery += "    ,IIF(ZZT.ZZT_PLACA <> '', ZZT.ZZT_PLACA, (SELECT"
	_oSQL:_sQuery += " 			C5_VEICULO"
	_oSQL:_sQuery += " 		FROM " + RetSqlName( "SC5" ) 
	_oSQL:_sQuery += " 		WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND C5_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 		AND C5_NOTA = SF2.F2_DOC"
	_oSQL:_sQuery += " 		AND C5_SERIE = SF2.F2_SERIE)"
	_oSQL:_sQuery += " 	) AS PLACA"
	_oSQL:_sQuery += "    ,RTRIM(B1_DESC) AS PRODUTO"
	_oSQL:_sQuery += "    ,SD2.D2_QUANT AS QUANTIDADE "
	_oSQL:_sQuery += " FROM " + RetSqlName( "SD2" ) + " SD2"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName( "SB5" ) + " SB5"
	_oSQL:_sQuery += " 	ON (SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND B5_COD = D2_COD"
	_oSQL:_sQuery += " 			AND B5_FILIAL = '  '"
	_oSQL:_sQuery += " 			AND B5_VASISDE = 'S')"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName( "SB1" ) + " SB1"
	_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND (B1_GRPEMB = '18'"
	_oSQL:_sQuery += " 				OR B5_VATPSIS IN ('24', '40'))"
	_oSQL:_sQuery += " 			AND B1_COD = SB5.B5_COD"
	_oSQL:_sQuery += " 			AND B1_FILIAL = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery += " 			AND (B1_LITROS = 0 OR D2_QUANT * B1_LITROS >= 10))"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName( "SF2" ) + " SF2"
	_oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND F2_VAGUIA = ' '"
	_oSQL:_sQuery += " 			AND F2_SERIE = D2_SERIE""
	_oSQL:_sQuery += " 			AND F2_DOC = D2_DOC"
	_oSQL:_sQuery += " 			AND F2_FILIAL = D2_FILIAL)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSqlName( "SA2" ) + " SA2"
	_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA2.A2_COD = SF2.F2_CLIENTE"
	_oSQL:_sQuery += " 			AND SA2.A2_LOJA = SF2.F2_LOJA)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSqlName( "SA1" ) + " SA1"
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA1.A1_COD = SF2.F2_CLIENTE"
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF2.F2_LOJA)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSqlName( "ZZT" ) + " ZZT"
	_oSQL:_sQuery += " 	ON (ZZT.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND ZZT.ZZT_CHVNFE = SF2.F2_CHVNFE)"
	_oSQL:_sQuery += " INNER JOIN SX5010 AS SX5"
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SX5.X5_TABELA = '13'"
	_oSQL:_sQuery += " 			AND SX5.X5_CHAVE = SD2.D2_CF)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSqlName( "SA4" ) + " SA4"
	_oSQL:_sQuery += " ON (SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SA4.A4_COD = SF2.F2_TRANSP)"
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND D2_EMISSAO BETWEEN '" + dtos (date () - _nDias) + "' AND '" + dtos (date ()) + "'"
	_oSQL:_sQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "' "
	_oSQL:_sQuery += " AND D2_SERIE != '99 '"

	// Desconsidera notas de transferencia simbolicas feitas em out/2017 para equalizacao de custos entre filiais.
	_oSQL:_sQuery +=    " AND NOT (SD2.D2_EMISSAO between '20171020' and '20171031'"
	_oSQL:_sQuery +=             " AND ((D2_FILIAL = '01' AND D2_DOC BETWEEN '000129625' AND '000129630')"
	_oSQL:_sQuery +=               " OR (D2_FILIAL = '01' AND D2_DOC BETWEEN '000130225' AND '000130225')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '01' AND D2_DOC BETWEEN '000130243' AND '000130243')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '07' AND D2_DOC BETWEEN '000015721' AND '000015722')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '07' AND D2_DOC BETWEEN '000015724' AND '000016734')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '09' AND D2_DOC BETWEEN '000013136' AND '000013137')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '09' AND D2_DOC BETWEEN '000013140' AND '000013142')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '10' AND D2_DOC BETWEEN '000010709' AND '000010739')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '10' AND D2_DOC BETWEEN '000010747' AND '000010757')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '11' AND D2_DOC BETWEEN '000004459' AND '000004477')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '11' AND D2_DOC BETWEEN '000004479' AND '000004480')"
	_oSQL:_sQuery +=               " or (D2_FILIAL = '13' AND D2_DOC BETWEEN '000007444' AND '000007450')"
	_oSQL:_sQuery +=             "))"

	//_oSQL:_sQuery += "  ORDER BY D2_DOC"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += "	TIPO"
	_oSQL:_sQuery += "   ,EMITENTE"
	_oSQL:_sQuery += "   ,DESTINATARIO"
	_oSQL:_sQuery += "   ,DT_EMISSAO
	_oSQL:_sQuery += "   ,TIPO_OPERACAO"
	_oSQL:_sQuery += "   ,NF
	_oSQL:_sQuery += "   ,TRANSPORTADOR"
	_oSQL:_sQuery += "   ,PLACA"
	_oSQL:_sQuery += "   ,PRODUTO"
	_oSQL:_sQuery += "   ,SUM(QUANTIDADE)"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " GROUP BY TIPO"
	_oSQL:_sQuery += "		,EMITENTE
	_oSQL:_sQuery += "		,DESTINATARIO"
	_oSQL:_sQuery += "		,DT_EMISSAO"
	_oSQL:_sQuery += "		,TIPO_OPERACAO"
	_oSQL:_sQuery += "		,NF"
	_oSQL:_sQuery += "		,TRANSPORTADOR"
	_oSQL:_sQuery += "		,PLACA"
	_oSQL:_sQuery += "		,PRODUTO"
	_oSQL:_sQuery += " ORDER BY NF"

	_oSQL:Log ()
	if len (_oSQL:Qry2Array (.F., .F.)) > 0
		_aCols := {}
		
	   aadd (_aCols, {'TIPO'  			,    'left' ,  ''})
	   aadd (_aCols, {'EMITENTE'    	,    'left' ,  ''})
	   aadd (_aCols, {'DESTINATÁRIO'  	,    'left' ,  ''})
	   aadd (_aCols, {'DATA DE EMISSÃO'	,    'left' ,  ''})
	   aadd (_aCols, {'TIPO DE OPERAÇÃO',    'left' ,  ''})
	   aadd (_aCols, {'NOTA'     		,    'left' ,  ''})
	   aadd (_aCols, {'TRANSPORTADOR'   ,    'left' ,  ''})
	   aadd (_aCols, {'PLACA'          	,    'left' ,  ''})
	   aadd (_aCols, {'PRODUTO'  		,    'left' ,  ''})
	   aadd (_aCols, {'QUANTIDADE'  	,    'right',  ''})
		
		_sMsg = _oSQL:Qry2HTM ("Notas de SAIDA nos ultimos " + cvaltochar (_nDias) + " dias faltando gerar guia de livre transito", _aCols, "", .F.,.T.)
		//u_log2 ('info', _sMsg)
		U_ZZUNU ({'018'}, 'Filial ' + cFilAnt + '-verif. guias livre transito saida', _sMsg, .F., cEmpAnt, cFilAnt)
	endif


	// Verifica notas de entrada
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " ("
	_oSQL:_sQuery += "  SELECT DISTINCT D1_DOC AS DOC, D1_SERIE AS SERIE, dbo.VA_DTOC (D1_DTDIGIT) AS DT_ENTRADA, B1_DESC AS PRODUTO, D1_FORNECE + '/' + D1_LOJA AS FORNECEDOR"
	_oSQL:_sQuery +=   " FROM " + RetSqlName( "SB1" ) + " SB1,"
	_oSQL:_sQuery +=              RetSqlName( "SB5" ) + " SB5,"
	_oSQL:_sQuery +=              RetSqlName( "SF1" ) + " SF1,"
	_oSQL:_sQuery +=              RetSqlName( "SD1" ) + " SD1"
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery += "    AND SB5.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery += "    AND (B1_GRPEMB = '18' OR B5_VATPSIS IN ('24', '40'))"  // Borra ou acucar.
	_oSQL:_sQuery += "    AND B1_COD = D1_COD "
	_oSQL:_sQuery += "    AND B5_COD = B1_COD "
	_oSQL:_sQuery += "    AND B5_VASISDE = 'S' "
	_oSQL:_sQuery += "    AND B1_FILIAL = '" + xFilial("SB1") + "' "
	_oSQL:_sQuery += "    AND B5_FILIAL = '" + xFilial("SB5") + "' "
	_oSQL:_sQuery += "    AND SB1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery += "    AND F1_FILIAL = D1_FILIAL"
	_oSQL:_sQuery += "    AND F1_FORNECE = D1_FORNECE"
	_oSQL:_sQuery += "    AND F1_LOJA = D1_LOJA"
	_oSQL:_sQuery += "    AND F1_DOC = D1_DOC"
	_oSQL:_sQuery += "    AND F1_SERIE = D1_SERIE"
	_oSQL:_sQuery += "    AND F1_VAGUIA = ' ' "
	_oSQL:_sQuery += "    AND F1_ESPECIE NOT IN ('CTE')"
	_oSQL:_sQuery += "    AND SF1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery += "    AND SD1.D_E_L_E_T_ <> '*' "
	_oSQL:_sQuery += "    AND D1_DTDIGIT BETWEEN '" + dtos (date () - _nDias) + "' AND '" + dtos (date ()) + "'"
	_oSQL:_sQuery += "    AND D1_FILIAL = '" + xFilial("SD1") + "' "
	_oSQL:_sQuery += "    AND D1_SERIE != '99 '"  // Notas de cobertura de operacao triangular

	// Desconsidera notas de transferencia simbolicas feitas em out/2017 para equalizacao de custos entre filiais.
	_oSQL:_sQuery +=    " AND NOT (SD1.D1_EMISSAO between '20171020' and '20171031'"
	_oSQL:_sQuery +=             " AND ((D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000129625' AND '000129630')"
	_oSQL:_sQuery +=               " OR (D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000130225' AND '000130225')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '000021' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000130243' AND '000130243')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003114' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000015721' AND '000015722')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003114' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000015724' AND '000016734')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003111' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000013136' AND '000013137')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003111' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000013140' AND '000013142')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003108' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000010709' AND '000010739')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003108' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000010747' AND '000010757')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003266' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000004459' AND '000004477')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '003266' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000004479' AND '000004480')"
	_oSQL:_sQuery +=               " or (D1_FORNECE = '004565' AND D1_LOJA = '01' AND D1_SERIE = '10' AND D1_DOC BETWEEN '000007444' AND '000007450')"
	_oSQL:_sQuery +=             "))"

	//_oSQL:_sQuery += "  ORDER BY D1_DOC, D1_FORNECE"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 	   DOC"
	_oSQL:_sQuery += "    ,SERIE"
	_oSQL:_sQuery += "    ,DT_ENTRADA"
	_oSQL:_sQuery += "    ,PRODUTO"
	_oSQL:_sQuery += "    ,FORNECEDOR"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " ORDER BY DOC, SERIE, FORNECEDOR"

	_oSQL:Log ()
	if len (_oSQL:Qry2Array (.F., .F.)) > 0
		_sMsg = _oSQL:Qry2HTM ("Notas de ENTRADA nos ultimos " + cvaltochar (_nDias) + " dias faltando informar guia de livre transito", NIL, "", .F.)
		//u_log2 ('info', _sMsg)
		U_ZZUNU ({'018'}, 'Filial ' + cFilAnt + '-verif. guias livre transito entrada', _sMsg, .F., cEmpAnt, cFilAnt)
	endif

	U_ML_SRArea (_aAreaAnt)
Return 
