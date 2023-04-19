// Programa.:  BatRecebidos
// Autor....:  Catia Cardoso       
// Data.....:  06/05/2015     
// Descricao:  Verificacoes diarias -  Email de Produtos Recebidos no dia anterior
//             Criado para ser executado via batch.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #validacao
// #Descricao         #Verifica se a Inscricao Estadual e valida 
// #PalavasChave      #inscricao_estadual #validação
// #TabelasPrincipais #SF1 #SF2 #SD1 #SD2 #SA1 #SA2 #SD3 
// #Modulos   		  #CON 
//
// Historico de alteracoes:
// 07/05/2015 -         -  alterado para que nao liste as notas com TES 184 - que sao serviço
// 28/11/2016 - Robert  -  Envia e-mail para compras@... e nao mais para o grupo 017.
// 30/11/2016 - Catia   -  Incluido rotina 022 - PCP/QUALIDADE e ALMOX - para receber essa notificacao
// 28/08/2019 - Andre   -  Incluido campo TIPO de Produto, para que usuários do grupo 042 
//                         recebam apenas emails destes produtos.
// 21/05/2020 - Sandra  -  Retirado e-mail de compras@...  Para não mais receber o e-mail conforme 
//                         chamado GLPI 7962.
// 14/09/2021 - Claudia -  Incluso campos local e usuário grupo 042 - GLPI 10652
// 15/09/2021 - Claudia -  Incluida busca de registros das notas de saida, movimentos e transferencias 
//                         de produtos da manutenção. GLPI 10652.
// 15/09/2021 - Claudia -  Inclusão campo Entrada/Saida tipos de movimentos GLPI 10652.
// 03/01/2021 - Claudia -  Incluida busca de registros das notas de saida, movimentos e transferencias 
//                         de produtos do Almox 02. GLPI 8153.
// 27/01/2023 - Claudia -  Incluidas colunas de lote e endereço. GLPI: 13088
// 12/04/2023 - Claudia -  Incluidas novas colunas de Usr.Autorização Origem' e Usr.Autorização Destino'. GLPI: 13316
// 19/04/2023 - Claudia -  Incluido no tipo a definicção se é o mov. é pelo NAWEB ou OS. GLPI 1316
//
// ---------------------------------------------------------------------------------------------------------------------
user function BatRecebidos (_sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	local _lContinua := .T.
	local _sMsg     := ""
	local _aCols    := {}
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

   	if alltrim (upper (_sQueFazer)) == "OC"	
	   	//	
		// ITENS RECEBIDOS NO DIA ANTERIOR
	   	if _lContinua
			// le todas as notas que entraram no dia anterior
			_aCols = {}
			aadd (_aCols, {'Dt.Entrega'  ,    'left' ,  ''})
			aadd (_aCols, {'Cod.Forn'    ,    'left' ,  ''})
			aadd (_aCols, {'Fornecedor'  ,    'left' ,  ''})
			aadd (_aCols, {'Nota Fiscal' ,    'left' ,  ''})
			aadd (_aCols, {'Produto'     ,    'left' ,  ''})
			aadd (_aCols, {'Descrição'   ,    'left' ,  ''})
			aadd (_aCols, {'UN'          ,    'left' ,  ''})
			aadd (_aCols, {'Quantidade'  ,    'right',  ''})
			aadd (_aCols, {'Tipo'   	 ,    'right',  ''})

			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SD1.D1_DTDIGIT, SD1.D1_FORNECE"
			_oSQL:_sQuery += "	   	, SA2.A2_NOME"
			_oSQL:_sQuery += "		, SD1.D1_DOC, SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_UM"
			_oSQL:_sQuery += "		, dbo.FormataValor (SD1.D1_QUANT, 4, 15) AS QUANT"
			_oSQL:_sQuery += "		, SB1.B1_TIPO AS TIPO"
			_oSQL:_sQuery += "    FROM " + RetSQLName ("SD1") + " AS SD1 "
			_oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
			_oSQL:_sQuery += "				ON (SF1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "					AND SF1.F1_FILIAL   = SD1.D1_FILIAL"
			_oSQL:_sQuery += "					AND SF1.F1_EMISSAO  = SD1.D1_EMISSAO"
			_oSQL:_sQuery += "					AND SF1.F1_FORNECE  = SD1.D1_FORNECE"
			_oSQL:_sQuery += "					AND SF1.F1_LOJA     = SD1.D1_LOJA"
			_oSQL:_sQuery += "					AND SF1.F1_DOC      = SD1.D1_DOC"
			_oSQL:_sQuery += "					AND SF1.F1_SERIE    = SD1.D1_SERIE"
			_oSQL:_sQuery += "					AND SF1.F1_TIPO    != 'D'"
			_oSQL:_sQuery += "					AND SF1.F1_TIPO    != 'C'"
			_oSQL:_sQuery += "					AND SF1.F1_TIPO    != 'B'"
			_oSQL:_sQuery += "					AND SF1.F1_ESPECIE !='CTR'"
			_oSQL:_sQuery += "					AND SF1.F1_ESPECIE !='CTE')"
			_oSQL:_sQuery += "			INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += "				ON (SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "					AND SB1.B1_COD = SD1.D1_COD)"
			_oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
			_oSQL:_sQuery += "				ON (SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "					AND SA2.A2_COD    = SD1.D1_FORNECE"
			_oSQL:_sQuery += "					AND SA2.A2_LOJA   = SD1.D1_LOJA"
			_oSQL:_sQuery += "					AND SA2.A2_CGC NOT LIKE '%88612486%')" // desprezar as transferencias
			_oSQL:_sQuery += "			INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
			_oSQL:_sQuery += "				ON (SF4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "					AND SF4.F4_CODIGO = SD1.D1_TES"
			_oSQL:_sQuery += "					AND SF4.F4_ESTOQUE = 'S')"
			_oSQL:_sQuery += "	WHERE SD1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "	  AND SD1.D1_FILIAL = '01'"	
			_oSQL:_sQuery += "	  AND SD1.D1_DTDIGIT = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += "	  AND SD1.D1_COD != 'FR01'"
			_oSQL:_sQuery += "	  AND SD1.D1_COD != 'FR02'"
			_oSQL:_sQuery += "	  AND SD1.D1_COD != '9996'"
			_oSQL:_sQuery += "	  AND SD1.D1_COD != '9997'"
			_oSQL:_sQuery += "	  AND SD1.D1_COD != '9998'"
			_oSQL:_sQuery += "	  AND SD1.D1_TES != '184'"
			_oSQL:_sQuery += "  ORDER BY SA2.A2_NOME,SD1.D1_DESCRI"

			u_log (_oSQL:_sQuery)
			if len (_oSQL:Qry2Array (.T., .F.)) > 0

				_sMsg = _oSQL:Qry2HTM ("Itens recebidos em: " + dtoc(date()-1), _aCols, "", .F.)
				u_log (_sMsg)

				//U_SendMail ('claudia.lionco@novaalianca.coop.br', "Itens recebidos no dia anterior", _sMsg, {})
				U_ZZUNU ({'022'}, "Itens recebidos no dia anterior", _sMsg, .F., cEmpAnt, cFilAnt, "") // PCP/QUALIDADE/ALMOX
			 
	      	endif
      	endif
       
	    //	
		// ITENS RECEBIDOS NO DIA ANTERIOR - MANUTENÇÃO
       	if _lContinua
			_aCols = {}
			aadd (_aCols, {'Dt.Entrega'   			,    'left' ,  ''})
			aadd (_aCols, {'Tipo'         			,    'left' ,  ''})
			aadd (_aCols, {'Entrada/Saida'			,    'left' ,  ''})
			aadd (_aCols, {'Cli/for'      			,    'left' ,  ''})
			aadd (_aCols, {'Nome'         			,    'left' ,  ''})
			aadd (_aCols, {'Documento'    			,    'left' ,  ''})
			aadd (_aCols, {'Produto'     			,    'left' ,  ''})
			aadd (_aCols, {'Descrição'    			,    'left' ,  ''})
			aadd (_aCols, {'Tipo'   	  			,    'right',  ''})
			aadd (_aCols, {'UN'           			,    'left' ,  ''})
			aadd (_aCols, {'Local'        			,    'left' ,  ''})
			aadd (_aCols, {'Usuario'      			,    'left' ,  ''})
			aadd (_aCols, {'Quantidade'   			,    'right',  ''})
			aadd (_aCols, {'Lote'         			,    'right',  ''})
			aadd (_aCols, {'Endereço'     			,    'right',  ''})
			aadd (_aCols, {'Usr.Autorização Origem' ,    'right',  ''})
			aadd (_aCols, {'Usr.Autorização Destino',    'right',  ''})
			

			// le todas as notas que entraram no dia anterior
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SD1.D1_DTDIGIT AS DT "
			_oSQL:_sQuery += " 		,'NF' AS TP "
			_oSQL:_sQuery += "      ,'ENTRADA' AS ENTSAI " 
			_oSQL:_sQuery += " 		,SD1.D1_FORNECE AS CLIFOR "
			_oSQL:_sQuery += " 		,SA2.A2_NOME AS NOME "
			_oSQL:_sQuery += " 		,SD1.D1_DOC AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD1.D1_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SD1.D1_DESCRI AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPOPROD "
			_oSQL:_sQuery += " 		,SD1.D1_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,SD1.D1_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SF1.F1_VAUSER AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD1.D1_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += "      ,CASE "
			_oSQL:_sQuery += "       	WHEN SB1.B1_LOCALIZ = 'S' THEN BF_LOTECTL "
			_oSQL:_sQuery += " 		 	ELSE '' "
			_oSQL:_sQuery += "       END AS LOTECTL "
   			_oSQL:_sQuery += " 		,CASE "
			_oSQL:_sQuery += " 			WHEN SB1.B1_LOCALIZ = 'S' THEN BF_LOCALIZ "
			_oSQL:_sQuery += " 			ELSE '' "
			_oSQL:_sQuery += " 		END AS LOCALIZ "
			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_ORIGEM "
   			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " AS SD1 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
			_oSQL:_sQuery += " 	ON (SF1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF1.F1_FILIAL = SD1.D1_FILIAL "
			_oSQL:_sQuery += " 			AND SF1.F1_EMISSAO = SD1.D1_EMISSAO "
			_oSQL:_sQuery += " 			AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			_oSQL:_sQuery += " 			AND SF1.F1_LOJA = SD1.D1_LOJA "
			_oSQL:_sQuery += " 			AND SF1.F1_DOC = SD1.D1_DOC "
			_oSQL:_sQuery += " 			AND SF1.F1_SERIE = SD1.D1_SERIE "
			_oSQL:_sQuery += " 			AND SF1.F1_TIPO NOT IN ('D', 'C', 'B') "
			_oSQL:_sQuery += " 			AND SF1.F1_ESPECIE NOT IN ('CTR', 'CTE') "
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
			_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA2.A2_COD = SD1.D1_FORNECE "
			_oSQL:_sQuery += " 			AND SA2.A2_LOJA = SD1.D1_LOJA) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
			_oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD1.D1_TES "
			_oSQL:_sQuery += " 			AND SF4.F4_ESTOQUE = 'S') "
			_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SBF") + " AS SBF "
			_oSQL:_sQuery += "		ON  (RTRIM(D1_COD) = RTRIM(SBF.BF_PRODUTO) "
			_oSQL:_sQuery += "		AND RTRIM(SD1.D1_LOCAL) = RTRIM(BF_LOCAL) "
			_oSQL:_sQuery += "		AND RTRIM(SD1.D1_FILIAL) = RTRIM(BF_FILIAL) "
			_oSQL:_sQuery += "		AND SBF.D_E_L_E_T_ = '') "
			_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' " 
			_oSQL:_sQuery += " AND SD1.D1_FILIAL = '01' "
			_oSQL:_sQuery += " AND SD1.D1_DTDIGIT = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND SD1.D1_COD NOT IN ('FR01', 'FR02', '9996', '9997', '9998') "
			_oSQL:_sQuery += " AND SD1.D1_TES != '184' "
			_oSQL:_sQuery += " AND SB1.B1_TIPO IN ('MM', 'MC') "

			_oSQL:_sQuery += " UNION ALL "

			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SD2.D2_EMISSAO AS DT "
			_oSQL:_sQuery += " 		,'NF' AS TP "
			_oSQL:_sQuery += "      ,'SAIDA' AS ENTSAI "
			_oSQL:_sQuery += " 		,SD2.D2_CLIENTE AS CLIFOR "
			_oSQL:_sQuery += " 		,SA1.A1_NOME AS NOME "
			_oSQL:_sQuery += " 		,SD2.D2_DOC AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD2.D2_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SB1.B1_DESC AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPO "
			_oSQL:_sQuery += " 		,SD2.D2_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,SD2.D2_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SF2.F2_VAUSER AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD2.D2_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += " 		,SD2.D2_LOTECTL AS LOTECTL "
   			_oSQL:_sQuery += "      ,SD2.D2_LOCALIZ AS LOCALIZ "
			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_ORIGEM "
   			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " AS SD2 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
			_oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF2.F2_FILIAL = SD2.D2_FILIAL "
			_oSQL:_sQuery += " 			AND SF2.F2_EMISSAO = SD2.D2_EMISSAO "
			_oSQL:_sQuery += " 			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
			_oSQL:_sQuery += " 			AND SF2.F2_LOJA = SD2.D2_LOJA "
			_oSQL:_sQuery += " 			AND SF2.F2_DOC = SD2.D2_DOC "
			_oSQL:_sQuery += " 			AND SF2.F2_SERIE = SD2.D2_SERIE "
			_oSQL:_sQuery += " 			AND SF2.F2_TIPO NOT IN ('D', 'C', 'B') "
			_oSQL:_sQuery += " 			AND SF2.F2_ESPECIE NOT IN ('CTR', 'CTE') "
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_COD = SD2.D2_COD) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
			_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA1.A1_COD = SD2.D2_CLIENTE "
			_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SD2.D2_LOJA) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
			_oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD2.D2_TES "
			_oSQL:_sQuery += " 			AND SF4.F4_ESTOQUE = 'S') "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND SD2.D2_FILIAL = '01' "
			_oSQL:_sQuery += " AND SD2.D2_EMISSAO = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND SD2.D2_COD NOT IN ('FR01', 'FR02', '9996', '9997', '9998') "
			_oSQL:_sQuery += " AND SD2.D2_TES != '184' "
			_oSQL:_sQuery += " AND SB1.B1_TIPO IN ('MM', 'MC') "

			_oSQL:_sQuery += " UNION ALL "

			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		 SD3.D3_EMISSAO AS DT "
			//_oSQL:_sQuery += " 		,'MOV./TRANSF.' AS TP "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN 'MOV/TRANSF NAWEB' "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN 'MOV/TRANSF OS' "
			_oSQL:_sQuery += "		END AS TP "
			_oSQL:_sQuery += " 		,CASE "
            _oSQL:_sQuery += "   		WHEN D3_CF = 'DE4' THEN 'ENTRADA' "
            _oSQL:_sQuery += " 			ELSE 'SAIDA' "
            _oSQL:_sQuery += " 		END AS ENTSAI " 
			_oSQL:_sQuery += " 		,'-' AS CLIFOR "
			_oSQL:_sQuery += " 		,'-' AS NOME "
			//_oSQL:_sQuery += " 		,SD3.D3_DOC AS DOCUMENTO "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN ZAG.ZAG_DOC "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN SD3.D3_OP "
			_oSQL:_sQuery += "		END AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD3.D3_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SB1.B1_DESC AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPOPROD "
			_oSQL:_sQuery += " 		,SB1.B1_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,D3_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SD3.D3_USUARIO AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD3.D3_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += "		,SD3.D3_LOTECTL AS LOTECTL "
   			_oSQL:_sQuery += "		,SD3.D3_LOCALIZ AS LOCALIZ "
			_oSQL:_sQuery += " 		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTO IS NOT NULL THEN ZAG.ZAG_UAUTO "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN DADOS.SOLICITANTE "
			_oSQL:_sQuery += "		END AS USR_AUTORIZACAO_ORIGEM "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN ZAG.ZAG_UAUTD "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN DADOS.MANUTENTOR1 "
			_oSQL:_sQuery += "		END AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD3") + " AS SD3 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 		AND B1_COD = D3_COD "
			_oSQL:_sQuery += " 		AND SB1.B1_TIPO IN ('MM', 'MC') "
			_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZAG") + " AS ZAG "
			_oSQL:_sQuery += "  ON ZAG.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += "      AND D3_VACHVEX = 'ZAG' + ZAG.ZAG_DOC + ZAG.ZAG_SEQ "
			_oSQL:_sQuery += " LEFT JOIN VA_VDADOS_OS DADOS "
			_oSQL:_sQuery += "  ON SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' "
			_oSQL:_sQuery += "      AND ORDEM = SUBSTRING(SD3.D3_OP, 1, 6) "
			_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND D3_EMISSAO = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND D3_CF IN ('RE0', 'DE4') "

			u_log (_oSQL:_sQuery)
			if len (_oSQL:Qry2Array (.T., .F.)) > 0

				_sMsg = _oSQL:Qry2HTM ("Itens recebidos em: " + dtoc(date()-1), _aCols, "", .F.)
				u_log (_sMsg)
				
				//U_SendMail ('claudia.lionco@novaalianca.coop.br', "Itens da manutencao recebidos no dia anterior", _sMsg, {})
				U_ZZUNU ({'042'}, "Itens da manutencao recebidos no dia anterior", _sMsg, .F., cEmpAnt, cFilAnt, "") // MANUTENCAO
			endif
       	endif

		//	
		// ITENS RECEBIDOS NO DIA ANTERIOR - ALMOX 02
       	if _lContinua
			_aCols = {}
			aadd (_aCols, {'Dt.Entrega'   ,    'left' ,  ''})
			aadd (_aCols, {'Tipo'         ,    'left' ,  ''})
			aadd (_aCols, {'Entrada/Saida',    'left' ,  ''})
			aadd (_aCols, {'Cli/for'      ,    'left' ,  ''})
			aadd (_aCols, {'Nome'         ,    'left' ,  ''})
			aadd (_aCols, {'Documento'    ,    'left' ,  ''})
			aadd (_aCols, {'Produto'      ,    'left' ,  ''})
			aadd (_aCols, {'Descrição'    ,    'left' ,  ''})
			aadd (_aCols, {'Tipo'   	  ,    'right',  ''})
			aadd (_aCols, {'UN'           ,    'left' ,  ''})
			aadd (_aCols, {'Local'        ,    'left' ,  ''})
			aadd (_aCols, {'Usuario'      ,    'left' ,  ''})
			aadd (_aCols, {'Quantidade'   ,    'right',  ''})
			aadd (_aCols, {'Lote'         ,    'right',  ''})
			aadd (_aCols, {'Endereço'     ,    'right',  ''})
			aadd (_aCols, {'Usr.Autorização Origem' ,    'right',  ''})
			aadd (_aCols, {'Usr.Autorização Destino',    'right',  ''})
			

			// le todas as notas que entraram no dia anterior
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SD1.D1_DTDIGIT AS DT "
			_oSQL:_sQuery += " 		,'NF' AS TP "
			_oSQL:_sQuery += "      ,'ENTRADA' AS ENTSAI " 
			_oSQL:_sQuery += " 		,SD1.D1_FORNECE AS CLIFOR "
			_oSQL:_sQuery += " 		,SA2.A2_NOME AS NOME "
			_oSQL:_sQuery += " 		,SD1.D1_DOC AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD1.D1_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SD1.D1_DESCRI AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPOPROD "
			_oSQL:_sQuery += " 		,SD1.D1_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,SD1.D1_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SF1.F1_VAUSER AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD1.D1_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += "      ,CASE "
			_oSQL:_sQuery += "       	WHEN SB1.B1_LOCALIZ = 'S' THEN BF_LOTECTL "
			_oSQL:_sQuery += " 		 	ELSE '' "
			_oSQL:_sQuery += "       END AS LOTECTL "
   			_oSQL:_sQuery += " 		,CASE "
			_oSQL:_sQuery += " 			WHEN SB1.B1_LOCALIZ = 'S' THEN BF_LOCALIZ "
			_oSQL:_sQuery += " 			ELSE '' "
			_oSQL:_sQuery += " 		END AS LOCALIZ "
			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_ORIGEM "
   			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " AS SD1 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
			_oSQL:_sQuery += " 	ON (SF1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF1.F1_FILIAL = SD1.D1_FILIAL "
			_oSQL:_sQuery += " 			AND SF1.F1_EMISSAO = SD1.D1_EMISSAO "
			_oSQL:_sQuery += " 			AND SF1.F1_FORNECE = SD1.D1_FORNECE "
			_oSQL:_sQuery += " 			AND SF1.F1_LOJA = SD1.D1_LOJA "
			_oSQL:_sQuery += " 			AND SF1.F1_DOC = SD1.D1_DOC "
			_oSQL:_sQuery += " 			AND SF1.F1_SERIE = SD1.D1_SERIE "
			_oSQL:_sQuery += " 			AND SF1.F1_TIPO NOT IN ('D', 'C', 'B') "
			_oSQL:_sQuery += " 			AND SF1.F1_ESPECIE NOT IN ('CTR', 'CTE') "
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
			_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA2.A2_COD = SD1.D1_FORNECE "
			_oSQL:_sQuery += " 			AND SA2.A2_LOJA = SD1.D1_LOJA) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
			_oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD1.D1_TES "
			_oSQL:_sQuery += " 			AND SF4.F4_ESTOQUE = 'S') "
			_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SBF") + " AS SBF "
			_oSQL:_sQuery += "		ON  (RTRIM(D1_COD) = RTRIM(SBF.BF_PRODUTO) "
			_oSQL:_sQuery += "		AND RTRIM(SD1.D1_LOCAL) = RTRIM(BF_LOCAL) "
			_oSQL:_sQuery += "		AND RTRIM(SD1.D1_FILIAL) = RTRIM(BF_FILIAL) "
			_oSQL:_sQuery += "		AND SBF.D_E_L_E_T_ = '') "
			_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND SD1.D1_FILIAL = '01' "
			_oSQL:_sQuery += " AND SD1.D1_DTDIGIT = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND SD1.D1_COD NOT IN ('FR01', 'FR02', '9996', '9997', '9998') "
			_oSQL:_sQuery += " AND SD1.D1_TES != '184' "
			_oSQL:_sQuery += " AND SD1.D1_LOCAL IN ('02') "

			_oSQL:_sQuery += " UNION ALL "

			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SD2.D2_EMISSAO AS DT "
			_oSQL:_sQuery += " 		,'NF' AS TP "
			_oSQL:_sQuery += "      ,'SAIDA' AS ENTSAI "
			_oSQL:_sQuery += " 		,SD2.D2_CLIENTE AS CLIFOR "
			_oSQL:_sQuery += " 		,SA1.A1_NOME AS NOME "
			_oSQL:_sQuery += " 		,SD2.D2_DOC AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD2.D2_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SB1.B1_DESC AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPO "
			_oSQL:_sQuery += " 		,SD2.D2_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,SD2.D2_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SF2.F2_VAUSER AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD2.D2_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += " 		,SD2.D2_LOTECTL AS LOTECTL "
   			_oSQL:_sQuery += "      ,SD2.D2_LOCALIZ AS LOCALIZ "
			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_ORIGEM "
   			_oSQL:_sQuery += "		,'-' AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " AS SD2 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
			_oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF2.F2_FILIAL = SD2.D2_FILIAL "
			_oSQL:_sQuery += " 			AND SF2.F2_EMISSAO = SD2.D2_EMISSAO "
			_oSQL:_sQuery += " 			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
			_oSQL:_sQuery += " 			AND SF2.F2_LOJA = SD2.D2_LOJA "
			_oSQL:_sQuery += " 			AND SF2.F2_DOC = SD2.D2_DOC "
			_oSQL:_sQuery += " 			AND SF2.F2_SERIE = SD2.D2_SERIE "
			_oSQL:_sQuery += " 			AND SF2.F2_TIPO NOT IN ('D', 'C', 'B') "
			_oSQL:_sQuery += " 			AND SF2.F2_ESPECIE NOT IN ('CTR', 'CTE') "
			_oSQL:_sQuery += " 		) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SB1.B1_COD = SD2.D2_COD) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
			_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SA1.A1_COD = SD2.D2_CLIENTE "
			_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SD2.D2_LOJA) "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
			_oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD2.D2_TES "
			_oSQL:_sQuery += " 			AND SF4.F4_ESTOQUE = 'S') "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND SD2.D2_FILIAL = '01' "
			_oSQL:_sQuery += " AND SD2.D2_EMISSAO = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND SD2.D2_COD NOT IN ('FR01', 'FR02', '9996', '9997', '9998') "
			_oSQL:_sQuery += " AND SD2.D2_TES != '184' "
			_oSQL:_sQuery += " AND SD2.D2_LOCAL IN ('02') "

			_oSQL:_sQuery += " UNION ALL "

			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		SD3.D3_EMISSAO AS DT "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN 'MOV/TRANSF NAWEB' "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN 'MOV/TRANSF OS' "
			_oSQL:_sQuery += "		END AS TP "
			//_oSQL:_sQuery += " 		,'MOV./TRANSF.' AS TP "
			_oSQL:_sQuery += " 		,CASE "
            _oSQL:_sQuery += "   		WHEN D3_CF = 'DE4' THEN 'ENTRADA' "
            _oSQL:_sQuery += " 			ELSE 'SAIDA' "
            _oSQL:_sQuery += " 		END AS ENTSAI " 
			_oSQL:_sQuery += " 		,'-' AS CLIFOR "
			_oSQL:_sQuery += " 		,'-' AS NOME "
			//_oSQL:_sQuery += " 		,SD3.D3_DOC AS DOCUMENTO "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN ZAG.ZAG_DOC "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN SD3.D3_OP "
			_oSQL:_sQuery += "		END AS DOCUMENTO "
			_oSQL:_sQuery += " 		,SD3.D3_COD AS PRODUTO "
			_oSQL:_sQuery += " 		,SB1.B1_DESC AS DESCRICAO "
			_oSQL:_sQuery += " 		,SB1.B1_TIPO AS TIPOPROD "
			_oSQL:_sQuery += " 		,SB1.B1_UM AS UNIDADE "
			_oSQL:_sQuery += " 		,D3_LOCAL AS ALMOX "
			_oSQL:_sQuery += " 		,SD3.D3_USUARIO AS USUARIO "
			_oSQL:_sQuery += " 		,dbo.FormataValor(SD3.D3_QUANT, 4, 15) AS QUANT "
			_oSQL:_sQuery += "		,SD3.D3_LOTECTL AS LOTECTL "
   			_oSQL:_sQuery += "		,SD3.D3_LOCALIZ AS LOCALIZ "
			_oSQL:_sQuery += " 		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTO IS NOT NULL THEN ZAG.ZAG_UAUTO "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN DADOS.SOLICITANTE "
			_oSQL:_sQuery += "		END AS USR_AUTORIZACAO_ORIGEM "
			_oSQL:_sQuery += "		,CASE "
			_oSQL:_sQuery += "			WHEN ZAG.ZAG_UAUTD IS NOT NULL THEN ZAG.ZAG_UAUTD "
			_oSQL:_sQuery += "			WHEN SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' THEN DADOS.MANUTENTOR1 "
			_oSQL:_sQuery += "		END AS USR_AUTORIZACAO_DESTINO "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD3") + " AS SD3 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
			_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 		AND B1_COD = D3_COD "
			_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZAG") + " AS ZAG "
			_oSQL:_sQuery += "  ON ZAG.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += "      AND D3_VACHVEX = 'ZAG' + ZAG.ZAG_DOC + ZAG.ZAG_SEQ "
			_oSQL:_sQuery += " LEFT JOIN VA_VDADOS_OS DADOS "
			_oSQL:_sQuery += "  ON SUBSTRING(SD3.D3_OP, 7, 2) = 'OS' "
			_oSQL:_sQuery += "      AND ORDEM = SUBSTRING(SD3.D3_OP, 1, 6) "
			_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND D3_FILIAL = '01' "
			_oSQL:_sQuery += " AND D3_EMISSAO = '" + dtos (date()-1) + "'"
			_oSQL:_sQuery += " AND D3_CF IN ('RE0', 'DE4') "
			_oSQL:_sQuery += " AND D3_LOCAL IN ('02') "

			u_log (_oSQL:_sQuery)
			if len (_oSQL:Qry2Array (.T., .F.)) > 0

				_sMsg = _oSQL:Qry2HTM ("Itens recebidos em: " + dtoc(date()-1), _aCols, "", .F.)
				u_log (_sMsg)
				
				//U_SendMail ('claudia.lionco@novaalianca.coop.br', "Itens recebidos no dia anterior - ALMOX.02", _sMsg, {})
				U_ZZUNU ({'A09'}, "Itens recebidos no dia anterior - ALMOX.02", _sMsg, .F., cEmpAnt, cFilAnt, "") 
			endif
       	endif
   	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
	
return .T.
