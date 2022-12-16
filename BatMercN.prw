// Programa:   BatMercN
// Autor:      Robert Koch
// Data:       06/02/2018
// Descricao:  Exporta notas fiscais para o Mercanet. Nao faz a exportacao via ponto de 
//             entrada (saidas) por que, nesse momento, a chave pode ainda nao estar
//             gravada, e o Mercanet nao aceita.
//             Exporta tambem NF entrada por que podem ser excluidas mais tarde.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Rotinas de integracao de notas fiscais com o sistema Mercanet.
// #PalavasChave      #notas_fiscais #mercanet #integracao
// #TabelasPrincipais #SF1 #SF2 #SD1 #SD2
// #Modulos           #FAT

// Historico de alteracoes:
// 16/02/2018 - Robert - Passa a enviar também os deletados (NF cancelada).
// 14/06/2018 - Robert - Exporta tambem NF entrada por que podem ser excluidas mais tarde.
// 28/01/2019 - Andre  - Ajustado para enviar nota com serie diferente.
// 24/04/2019 - Andre  - Ajustado para verificar NOTAS DE DEVOLUCAO deletadas no Protheus
// 29/04/2019 - Andre  - Adicionado tratamento para TITULOS.
// 23/05/2019 - Andre  - Adicionado tratamento para itens de notas com TES que não geram faturamento.
// 16/08/2019 - Andre  - Adicionado tratamento para exportar as TES ao executar BAT.
// 08/06/2020 - Robert - Exportacao de titulos limitada a 365 dias retroativos.
//                     - Geracao de logs mais resumidos.
// 10/09/2020 - Robert - Ignora notas especie 'ND' no teste de notas de devolucao que nao deveriam estar no Mercanet.
//                     - Inseridas tags para catalogo de fontes.
// 07/10/2020 - Robert - Exportacao de titulos limitada de 365 para 180 dias retroativos.
//                     - Melhorados logs.
// 06/05/2021 - Robert - Filtrada somente F2_SERIE='10' para envio, pois existem outras series que nao sao de faturamento (GLPI 9984)
//                     - Melhoradas mensagens de retorno.
// 19/08/2021 - Robert - Ignorar NF de numero '00126.498' existente no SF1 (SQL nao converte para INT).
//

// --------------------------------------------------------------------------
user function BatMercN (_nQtDias)
	local _oSQL      := NIL
	local _nLock     := 0
	local _lContinua := .T.
	local _aDados    := {}
	local _nLinha    := 0
	local _sLinkSrv  := ""

	_oBatch:Retorno = 'N'

	// Define se deve apontar para o banco de producao ou de homologacao.
	_sLinkSrv = U_LkServer ('MERCANET')
	if empty (_sLinkSrv)
		u_help ("Sem definicao para comunicacao com banco de dados do Mercanet.",, .t.)
		_oBatch:Retorno = 'E'  // Erro
		_lContinua = .F.
	endif

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname (1) + procname ())
		if _nLock == 0
			u_log2 ('aviso', "Bloqueio de semaforo.")
			_oBatch:Mensagens += "Bloqueio de semaforo."
			_lContinua = .F.
		endif
	endif
	
	if _lContinua // Exporta TES
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
	   	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF4")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND F4_FILIAL = '" + xfilial ("SF4") + "'"  // Deixar esta opcao para poder ler os campos memo.
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'TES: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			sf4 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF4", sf4 -> (recno ()))
		next
		_oBatch:Mensagens += "SF4:ok."
	endif
	
	

	if _lContinua //Notas deveriam ir para Mercanet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT R_E_C_N_O_"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF2")
		// QUERO as deletadas tambem, pois o Mercanet precisa cancelar elas --> _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " WHERE F2_FILIAL = '" + xfilial ("SF2") + "'"
		_oSQL:_sQuery +=   " AND F2_EMISSAO >= '" + dtos (date () - _nQtDias) + "'"
//		_oSQL:_sQuery +=   " AND F2_EMISSAO >= '20190601'"  // DATA INICIAL EXPORT P/ MERCANET
		_oSQL:_sQuery +=   " AND F2_TIPO != 'D'" //DIFERENTE DE DEVOLUCAO
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT * FROM " + _sLinkSrv + ".DB_NOTA_FISCAL"
		_oSQL:_sQuery +=   "                          WHERE DB_NOTA_NRO = CAST (F2_DOC AS INT)"
		_oSQL:_sQuery +=   "                          AND DB_NOTA_SERIE = F2_SERIE COLLATE DATABASE_DEFAULT )
		_oSQL:_sQuery += " ORDER BY R_E_C_N_O_"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'NF faturamento: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SF2 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF2", sf2 -> (recno ()))
		next
		_oBatch:Mensagens += "SF2:ok."
	endif
	
	if _lContinua //Notas que NÃO deveriam estar no Mercanet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".DB_NOTA_FISCAL,"
		_oSQL:_sQuery +=          RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery +=  " WHERE DATEDIFF (DAY, DB_NOTA_DT_EMISSAO,GETDATE()) < " + cValToChar (_nQtDias)
//		_oSQL:_sQuery +=  " WHERE DB_NOTA_DT_EMISSAO >= '20190601' "
		_oSQL:_sQuery +=    " AND DB_NOTA_SERIE NOT LIKE 'D%'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SF2")
		_oSQL:_sQuery +=                     " WHERE F2_DOC COLLATE DATABASE_DEFAULT = DB_NOTA_NRO"
		_oSQL:_sQuery +=                       " AND D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND F2_FILIAL  = '01'"
		_oSQL:_sQuery +=                       " AND F2_SERIE COLLATE DATABASE_DEFAULT = DB_NOTA_SERIE"
		_oSQL:_sQuery +=                    ")"
		_oSQL:_sQuery +=    " AND SF2.F2_DOC    = DB_NOTA_NRO"
		_oSQL:_sQuery +=    " AND SF2.F2_FILIAL = '" + xfilial ("SF2") + "'"
		_oSQL:_sQuery +=    " AND SF2.F2_SERIE  = '10'"  // A principio somente preciso exportar a serie de faturamento normal.
		_oSQL:_sQuery +=  " ORDER BY R_E_C_N_O_"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'NF fatur. que NAO deveriam estar no Mercanet: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SF2 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF2", sf2 -> (recno ()))
		next
		_oBatch:Mensagens += "NF que NAO devem estar no Merc.:ok."
	endif

	// Notas de devolucao: quando o Mercanet importa, vincula-as ao representante naquele momento. Entretando, as consultas de
	// faturamento buscam sempre pelo representante atual, entao precisamos que notas antigas sejam vinculadas ao repres.atual.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SF1.R_E_C_N_O_"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF1") + " SF1, "
		_oSQL:_sQuery +=            RetSQLName ("SA1") + " SA1 "								
		// QUERO as deletadas tambem, pois o Mercanet precisa cancelar elas --> _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " WHERE SF1.F1_FILIAL = '" + xfilial ("SF1") + "'"
		_oSQL:_sQuery +=   " AND SF1.F1_TIPO     = 'D'"
		_oSQL:_sQuery +=   " AND SF1.F1_DTDIGIT >= '" + dtos (date () - _nQtDias) + "'"
//		_oSQL:_sQuery +=   " AND SF1.F1_DTDIGIT >= '20190601'"  // DATA INICIAL EXPORT P/ MERCANET
		_oSQL:_sQuery +=   " AND SA1.A1_COD  = SF1.F1_FORNECE "
	    _oSQL:_sQuery +=   " AND SA1.A1_LOJA = SF1.F1_LOJA "
		//Adicionado filtro para itens de notas com TES q não geram faturamento.
		_oSQL:_sQuery +=   " AND EXISTS (SELECT * " 
		_oSQL:_sQuery +=   " 	FROM " + RetSQLName ("SD1") + " SD1A, "
		_oSQL:_sQuery +=          	     RetSQLName ("SF4") + " SF4A "
		_oSQL:_sQuery +=   "	 WHERE SD1A.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=   " 		AND SD1A.D1_FILIAL = SF1.F1_FILIAL "
		_oSQL:_sQuery +=   " 		AND SD1A.D1_TES = SF4A.F4_CODIGO "
		_oSQL:_sQuery +=   " 		AND SF4A.F4_MARGEM IN ('1','2','3') "
		_oSQL:_sQuery +=   " 		AND SF1.F1_DOC = SD1A.D1_DOC "
		_oSQL:_sQuery +=   " 		AND SF1.F1_SERIE = SD1A.D1_SERIE "
		_oSQL:_sQuery +=   " 		AND SF1.F1_FORNECE = SD1A.D1_FORNECE "
		_oSQL:_sQuery +=   " 		AND SF1.F1_LOJA = SD1A.D1_LOJA) "
		_oSQL:_sQuery +=   " 		AND (NOT EXISTS (SELECT * FROM " + _sLinkSrv + ".DB_NOTA_FISCAL WHERE DB_NOTA_NRO = CAST (SF1.F1_DOC AS INT))"
		_oSQL:_sQuery +=   " OR EXISTS (SELECT * FROM " + _sLinkSrv + ".DB_NOTA_FISCAL" 
		_oSQL:_sQuery +=   "	WHERE DB_NOTA_NRO = CAST (SF1.F1_DOC AS INT) AND DB_NOTA_REPRES != SA1.A1_VEND)
		_oSQL:_sQuery +=   " )"
		_oSQL:_sQuery += " ORDER BY SF1.R_E_C_N_O_"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'NF devol.: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SF1 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF1", sf1 -> (recno ()))
		next
		_oBatch:Mensagens += "NF devol:ok."
	endif
	
	if _lContinua //Notas de DEVOLUCAO que NÃO deveriam estar no Mercanet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " WITH SF1 AS ("
		_oSQL:_sQuery +=     " SELECT CAST(F1_DOC AS INT) AS F1_DOC, F1_FORNECE, R_E_C_N_O_ "
		_oSQL:_sQuery +=       " FROM " + RetSQLName ("SF1") + " SF1 "
		_oSQL:_sQuery +=      " WHERE F1_DTDIGIT >= '20180101'"  // Data em que comecamos a exportar notas para o Mercanet
		_oSQL:_sQuery +=        " AND F1_ESPECIE not in ('ND')"
		_oSQL:_sQuery +=        " AND F1_FILIAL = '" + xfilial ("SF1") + "'"
		_oSQL:_sQuery +=        " AND F1_DOC    != '000038/23'"  // Nota-monstro que o SQL nao converte para INT.
		_oSQL:_sQuery +=        " AND F1_DOC    != '00126.498'"  // Nota-monstro que o SQL nao converte para INT.
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".DB_NOTA_FISCAL, SF1"
		_oSQL:_sQuery +=  " WHERE DATEDIFF (DAY, DB_NOTA_DT_EMISSAO,GETDATE()) < " + cValToChar (_nQtDias)
//		_oSQL:_sQuery +=  " WHERE DB_NOTA_DT_EMISSAO >= '20190601'"
		_oSQL:_sQuery +=    " AND DB_NOTA_SERIE LIKE 'D%' "
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT * "
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SD1") + " SD1, "
		_oSQL:_sQuery +=							   + RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery +=                     " WHERE D1_DOC COLLATE DATABASE_DEFAULT = DB_NOTA_NRO"
		_oSQL:_sQuery +=                       " AND SD1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=                       " AND SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=                       " AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery +=        			   " AND SD1.D1_TES = SF4.F4_CODIGO" 
		_oSQL:_sQuery +=        		       " AND SF4.F4_MARGEM IN ('1','2','3')" 
		_oSQL:_sQuery +=					   " AND SD1.D1_FORNECE COLLATE DATABASE_DEFAULT = DB_NOTA_CLIENTE"
		_oSQL:_sQuery +=				       " AND SD1.D1_TIPO = 'D'"
		_oSQL:_sQuery +=					   " AND SD1.D1_DTDIGIT >= '20180101'"
		_oSQL:_sQuery +=                    ")"
		_oSQL:_sQuery +=    " AND DB_NOTA_NRO = SF1.F1_DOC"
		_oSQL:_sQuery +=  " ORDER BY R_E_C_N_O_"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'NF devol. que NAO deveriam estar no Mercanet: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SF1 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF1", sf1 -> (recno ()))
		next
		_oBatch:Mensagens += "NF devol.que NAO devem estar no Merc:ok."
	endif

	// Titulos que devem ser enviados para MERCANET.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "	SELECT "
		_oSQL:_sQuery += "		SE5A.R_E_C_N_O_"
		_oSQL:_sQuery += "		,SE5A.E5_FILIAL "
		_oSQL:_sQuery += "		,SE5A.E5_TIPODOC"
		_oSQL:_sQuery += "		,RTRIM( SE5A.E5_NUMERO) + '-' +  SE5A.E5_PARCELA AS TITULO"
		_oSQL:_sQuery += "		,SE5A.E5_CLIFOR"
		_oSQL:_sQuery += "		,SE5A.E5_SEQ"
		_oSQL:_sQuery += "		,CAST( SE5A.E5_DATA AS DATETIME) AS DT_LCTO"
		_oSQL:_sQuery += "		,SE5A.E5_VALOR"
		_oSQL:_sQuery += "		,CAST( SE5A.E5_DTDIGIT AS DATETIME) AS DT_DIGIT"
		_oSQL:_sQuery += "		,(SELECT"
		_oSQL:_sQuery += "			SUM(E5_VALOR)"
		_oSQL:_sQuery += "			FROM " + RetSQLName ("SE5") + " SE5B ""
		_oSQL:_sQuery += "			WHERE SE5B.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "				AND SE5B.E5_FILIAL = SE5A.E5_FILIAL"
		_oSQL:_sQuery += "				AND SE5B.E5_CLIFOR = SE5A.E5_CLIFOR"
		_oSQL:_sQuery += "				AND SE5B.E5_NUMERO = SE5A.E5_NUMERO"
		_oSQL:_sQuery += "				AND SE5B.E5_TIPODOC = 'DC')"
		_oSQL:_sQuery += "			AS VLR_DESCONTO"
		_oSQL:_sQuery += "		,(SELECT"
		_oSQL:_sQuery += "			SUM(E5_VALOR)"
		_oSQL:_sQuery += "			FROM " + RetSQLName ("SE5") + " SE5B ""
		_oSQL:_sQuery += "			WHERE SE5B.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "				AND SE5B.E5_FILIAL = SE5A.E5_FILIAL"
		_oSQL:_sQuery += "				AND SE5B.E5_CLIFOR = SE5A.E5_CLIFOR"
		_oSQL:_sQuery += "				AND SE5B.E5_NUMERO = SE5A.E5_NUMERO"
		_oSQL:_sQuery += "				AND SE5B.E5_TIPODOC = 'JR')"
		_oSQL:_sQuery += "			AS VLR_JUROS"
		_oSQL:_sQuery += "		,SE5A.E5_NUMERO"
		_oSQL:_sQuery += "		,SE5A.E5_PREFIXO"
		_oSQL:_sQuery += "		,SE5A.E5_PARCELA"
		_oSQL:_sQuery += "	FROM " + RetSQLName ("SE5") + " SE5A ""
		_oSQL:_sQuery += "	    INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
		_oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "			AND SA1.A1_COD = SE5A.E5_CLIFOR"
		_oSQL:_sQuery += "			AND SA1.A1_LOJA = SE5A.E5_LOJA)"
		_oSQL:_sQuery += "	    INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
		_oSQL:_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "			AND SA3.A3_COD = SA1.A1_VEND"
		_oSQL:_sQuery += "			AND SA3.A3_VAMERC = 'S'	)"
		_oSQL:_sQuery += "	WHERE SE5A.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	AND  SE5A.E5_FILIAL = '01'"
		_oSQL:_sQuery += "	AND  SE5A.E5_RECPAG = 'R'"
		_oSQL:_sQuery += "	AND  SE5A.E5_DATA  >= '20180101'"
	//	_oSQL:_sQuery += "	AND  SE5A.E5_DATA  >= '" + dtos (date () - 365) + "'"  // Robert 08/06/2020
		// _oSQL:_sQuery += "	AND  SE5A.E5_DATA  >= '" + dtos (date () - 180) + "'"
		_oSQL:_sQuery += "	AND  SE5A.E5_DATA  >= '" + dtos (date () - _nQtDias) + "'"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'Baixas titulos a receber: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SE5 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SE5", se5 -> (recno ()))
		next
		_oBatch:Mensagens += "Baixas SE5:ok."
	endif
		
	if _lContinua
		
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "	SELECT "
		_oSQL:_sQuery += "		SE1.R_E_C_N_O_"
		_oSQL:_sQuery += "		, E1_NUM"
		_oSQL:_sQuery += "		, E1_PREFIXO"
		_oSQL:_sQuery += "		, E1_PARCELA"
		_oSQL:_sQuery += "		, RTRIM( E1_NUM) + '-' +  E1_PARCELA AS TITULO"
		_oSQL:_sQuery += "	FROM " + RetSQLName ("SE1") + " SE1 ""
		_oSQL:_sQuery += "	    INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
		_oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "			AND SA1.A1_COD  = SE1.E1_CLIENTE"
		_oSQL:_sQuery += "			AND SA1.A1_LOJA = SE1.E1_LOJA)"
		_oSQL:_sQuery += "	    INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
		_oSQL:_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "			AND SA3.A3_COD = SA1.A1_VEND"
		_oSQL:_sQuery += "			AND SA3.A3_VAMERC = 'S')"
		_oSQL:_sQuery += "	WHERE SE1.D_E_L_E_T_  = ''"
		_oSQL:_sQuery += "	AND SE1.E1_FILIAL = '01'"
		_oSQL:_sQuery += "	AND SE1.E1_VENCTO >= '20180101'"
		// _oSQL:_sQuery += "	AND SE1.E1_EMISSAO >= '" + dtos (date () - 365) + "'"  // Robert 08/06/2020
		_oSQL:_sQuery += "	AND SE1.E1_EMISSAO >= '" + dtos (date () - _nQtDias) + "'"  // Robert 08/06/2020
		_oSQL:_sQuery += "	AND SE1.E1_SALDO <> SE1.E1_VALOR"
		
		_oSQL:Log ()
		
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'Titulos a receber: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SE1 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SE1", se1 -> (recno ()))
		next
		_oBatch:Mensagens += "SE1:ok."
	endif
	
	//Titulos que NAO DEVERIAM estar no Mercanet
	if _lContinua
	
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "	SELECT SE1.R_E_C_N_O_" 
		_oSQL:_sQuery += "	FROM " + _sLinkSrv + ".MCR01"
		_oSQL:_sQuery += "	    INNER JOIN " + RetSQLName ("SE1") + " AS SE1 "
		_oSQL:_sQuery += "			ON (SE1.D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += "			AND SE1.E1_FILIAL   = '01'"
		_oSQL:_sQuery += "			AND SE1.E1_CLIENTE = REPLICATE('0', 6 - LEN(CR01_CLIENTE)) + RTRIM(CR01_CLIENTE)"
		_oSQL:_sQuery += "			AND SE1.E1_EMISSAO >= '20180101'"
		_oSQL:_sQuery += "			AND SE1.E1_NUM + '-' + SE1.E1_PARCELA COLLATE database_default = CR01_TITULO"
		_oSQL:_sQuery += "			AND SE1.E1_TIPO COLLATE database_default = CR01_TIPODOC"
		_oSQL:_sQuery += "			   )"
		_oSQL:_sQuery += "  WHERE CR01_EMPRESA = '01'"
		_oSQL:Log ()
		
		_aDados = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'Titulos a receber que NAO deveriam estar no Mercanet: enviando ' + cvaltochar (len (_aDados)) + ' registros.')
		For _nLinha := 1 To Len(_aDados)
			SE1 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SE1", se1 -> (recno ()))
		next
		_oBatch:Mensagens += "SE1 que NAO devem estar no Merc:ok."
	endif
	

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	if _lContinua
		_oBatch:Retorno = 'S'
	endif

	u_log2 ('info', 'Finalizando ' + procname ())
return .T.
