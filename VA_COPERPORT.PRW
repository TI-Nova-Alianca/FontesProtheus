//  Programa...: VA_COPERPORT
//  Autor......: Catia Cardoso
//  Data.......: 12/03/2019
//  Descricao..: Consulta de Opera��es Portaria 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Consulta de Opera��es Portaria 
// #PalavasChave      #operacoes_portaria 
// #TabelasPrincipais #SD1 #ZAF #SF1 #ZZT 
// #Modulos   		  #EST #COM 
//
//  Historico de altera��es
//  02/10/2019 - ROBERT/SANDRA - AND SF1.F1_CHVNFE <> '')"  /* PARA EVITAR LEITURA DE TICKETS SEM CHAVE */
//  02/10/2019 - ROBERT/SANDRA - Para n�o aceitar Pre nota.
//  25/06/2020 - Cl�udia - Incluida coluna de placa e alterado o nome do cliente/fornecedor para nome reduzido. GLPI:8027
//  10/07/2020 - Cl�udia - Voltada a altera��o pois Segundo a Deise mesmo com a altera��o n�o vai ajudar no processo.
//  18/02/2021 - Cl�udia - Incluida colunas referentes ao laudo. GLPI: 9283
//  19/01/2022 - Claudia - Incluido novos campos de brix e solidos. GLPI: 11490
//
// --------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_COPERPORT()
	
	_cPerg   := "VA_COPERPORT"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
	if Pergunte(_cPerg,.T.) 
		_sQuery := ""
		If mv_par09 == 1 .or. mv_par09 == 3
			_sQuery += " SELECT "
			_sQuery += "       'ENTRADA' AS TP "
			_sQuery += " 	  , SD1.D1_FILIAL   AS FILIAL"
			_sQuery += " 	  , ZZT.ZZT_COD	    AS TICKET"
			_sQuery += " 	  , dbo.VA_DTOC(ZZT.ZZT_DATA) AS DT_TICKET"
			_sQuery += " 	  , SF1.F1_VAGUIA   AS GUIA"
			_sQuery += "      , IIF(ZZT.ZZT_PLACA <> '',ZZT.ZZT_PLACA,(SELECT C5_VEICULO FROM SC5010 WHERE D_E_L_E_T_='' AND C5_FILIAL=SF1.F1_FILIAL AND C5_NOTA=SF1.F1_DOC AND C5_SERIE=SF1.F1_SERIE))  AS PLACA "
			_sQuery += " 	  , dbo.VA_DTOC(SF1.F1_DTDIGIT) AS DT_DIG_NF"
			_sQuery += " 	  , SF1.F1_DOC      AS NOTA"
			_sQuery += " 	  , SF1.F1_SERIE    AS SERIE"
			_sQuery += " 	  , SF1.F1_FORNECE  AS FORN_COD"
			_sQuery += " 	  , IIF(SF1.F1_TIPO = 'N', A2_NREDUZ, A1_NREDUZ) AS FORN_NOME "
			_sQuery += " 	  , SD1.D1_COD      AS PROD_COD"
			_sQuery += " 	  , SB1.B1_DESC     AS PROD_DESCR"
			_sQuery += " 	  , SD1.D1_UM       AS PROD_UM"
			_sQuery += " 	  , SD1.D1_QUANT    AS QUANT"
			_sQuery += " 	  , ZZT.ZZT_PESENT  AS PES_BRUTO"
			_sQuery += " 	  , ZZT.ZZT_PESSAI  AS TARA"
			_sQuery += " 	  , ZZT.ZZT_PESENT - ZZT.ZZT_PESSAI AS PESO_LIQUIDO"
			_sQuery += "      , SF1.F1_VADENS   AS DENSIDADE"
			_sQuery += "      , IIF (SF1.F1_VADENS>0,(ZZT.ZZT_PESENT - ZZT.ZZT_PESSAI) / SF1.F1_VADENS,0) AS VOLUME"
			_sQuery += "      , SD1.D1_QUANT - IIF (SF1.F1_VADENS>0,(ZZT.ZZT_PESENT - ZZT.ZZT_PESSAI) / SF1.F1_VADENS,0) AS DIFERENCA"
			_sQuery += "      , ZAF.ZAF_EXTRSE AS EXTRATO_SECO"
			_sQuery += "      , ZAF.ZAF_BRIX AS BRIX"
			_sQuery += "      , ZAF.ZAF_BRIX1 AS BRIX1"
			_sQuery += "      , ZAF.ZAF_BRIX2 AS BRIX2"
			_sQuery += "      , ZAF.ZAF_COR AS COR"
			_sQuery += "      , ZAF.ZAF_COR420 AS COR420"
			_sQuery += "      , ZAF.ZAF_COR520 AS COR520"
			_sQuery += "      , ZAF.ZAF_COR620 AS COR620"
			_sQuery += "      , ZAF.ZAF_DENSID AS DENSIDADE_LAUDO"
			_sQuery += "      , ZAF.ZAF_SOLID AS SOLIDO"
			_sQuery += "      , ZAF.ZAF_SOLID1 AS SOLIDO1"
			_sQuery += "      , ZAF.ZAF_SOLID2 AS SOLIDO2"
			_sQuery += "   FROM SD1010 AS SD1"
			_sQuery += " 		INNER JOIN SF1010 AS SF1"
			_sQuery += " 			ON (SF1.D_E_L_E_T_ = ''"
			_sQuery += " 				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
			_sQuery += " 				AND SF1.F1_DOC     = SD1.D1_DOC"
			_sQuery += " 				AND SF1.F1_SERIE   = SD1.D1_SERIE"
			_sQuery += " 				AND SF1.F1_FORNECE = SD1.D1_FORNECE"
			_sQuery += " 				AND SF1.F1_LOJA    = SD1.D1_LOJA
			_sQuery += "				AND SF1.F1_CHVNFE <> '')"  /* PARA EVITAR LEITURA DE TICKETS SEM CHAVE */
			_sQuery += " 		INNER JOIN SB1010 AS SB1"
			_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += " 				AND SB1.B1_COD = SD1.D1_COD)"
			_sQuery += " 		INNER JOIN ZZT010 AS ZZT"
			_sQuery += " 			ON (ZZT.D_E_L_E_T_ = ''"
			_sQuery += " 				AND ZZT.ZZT_CHVNFE = SF1.F1_CHVNFE)"
			_sQuery += " 		LEFT JOIN SA2010 AS SA2"
			_sQuery += " 			ON (SA2.D_E_L_E_T_ = ''"
			_sQuery += " 				AND SA2.A2_COD  = SF1.F1_FORNECE"
			_sQuery += " 				AND SA2.A2_LOJA = SF1.F1_LOJA)"
			_sQuery += " 		LEFT JOIN SA1010 AS SA1"
			_sQuery += " 			ON (SA1.D_E_L_E_T_  = ''"
			_sQuery += " 				AND SA1.A1_COD  = SF1.F1_FORNECE"
			_sQuery += " 				AND SA1.A1_LOJA = SF1.F1_LOJA)"
			_sQuery += " 		LEFT JOIN ZAF010 ZAF"
			_sQuery += " 			ON ZAF.D_E_L_E_T_ = ''"
			_sQuery += " 				AND ZAF.ZAF_FILIAL = SD1.D1_FILIAL"
			_sQuery += " 				AND ZAF.ZAF_PRODUT = SD1.D1_COD"
			_sQuery += " 				AND ZAF.ZAF_LOTE = SD1.D1_LOTECTL"
			_sQuery += " 				AND ZAF.ZAF_DATA <= SD1.D1_EMISSAO"
			_sQuery += " 				AND ZAF.ZAF_VALID >= SD1.D1_EMISSAO"
			_sQuery += " 				AND NOT EXISTS (SELECT"
			_sQuery += " 						*"
			_sQuery += " 					FROM ZAF010 MAIS_RECENTE"
			_sQuery += " 					WHERE MAIS_RECENTE.D_E_L_E_T_ = ''"
			_sQuery += " 					AND MAIS_RECENTE.ZAF_FILIAL = ZAF.ZAF_FILIAL"
			_sQuery += " 					AND MAIS_RECENTE.ZAF_LOTE = ZAF.ZAF_LOTE"
			_sQuery += " 					AND MAIS_RECENTE.ZAF_ENSAIO > ZAF.ZAF_ENSAIO)"
			_sQuery += "   WHERE SD1.D_E_L_E_T_ = ''"
			_sQuery += " 	 AND SD1.D1_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
			_sQuery += " 	 AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
			_sQuery += " 	 AND SD1.D1_GRUPO   = '3000' 
			_sQuery += " 	 AND SD1.D1_FORNECE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " 	 AND SD1.D1_COD BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
			_sQuery += "     AND SD1.D1_TES <> ''"
		EndIf

		If mv_par09 == 3
			_sQuery += " UNION ALL "
		EndIf

		If mv_par09 == 2 .or. mv_par09 == 3			
			_sQuery += " SELECT "
			_sQuery += "    'SAIDA' AS TP "
			_sQuery += " 	,SD2.D2_FILIAL AS FILIAL "
			_sQuery += "    ,ZZT.ZZT_COD AS TICKET "
			_sQuery += "    ,dbo.VA_DTOC(ZZT.ZZT_DATA) AS DT_TICKET "
			_sQuery += "    ,SF2.F2_VAGUIA AS GUIA "
			_sQuery += "    ,IIF(ZZT.ZZT_PLACA <> '', ZZT.ZZT_PLACA, (SELECT "
			_sQuery += " 			C5_VEICULO "
			_sQuery += " 		FROM SC5010 "
			_sQuery += " 		WHERE D_E_L_E_T_ = '' "
			_sQuery += " 		AND C5_FILIAL = SF2.F2_FILIAL "
			_sQuery += " 		AND C5_NOTA = SF2.F2_DOC "
			_sQuery += " 		AND C5_SERIE = SF2.F2_SERIE) "
			_sQuery += " 	) AS PLACA "
			_sQuery += "    ,dbo.VA_DTOC(SF2.F2_DTDIGIT) AS DT_DIG_NF "
			_sQuery += "    ,SF2.F2_DOC AS NOTA "
			_sQuery += "    ,SF2.F2_SERIE AS SERIE "
			_sQuery += "    ,SF2.F2_CLIENTE AS FORN_COD "
			_sQuery += "    ,IIF(SF2.F2_TIPO = 'N', A2_NREDUZ, A1_NREDUZ) AS FORN_NOME "
			_sQuery += "    ,SD2.D2_COD AS PROD_COD "
			_sQuery += "    ,SB1.B1_DESC AS PROD_DESCR "
			_sQuery += "    ,SD2.D2_UM AS PROD_UM "
			_sQuery += "    ,SD2.D2_QUANT AS QUANT "
			_sQuery += "    ,ZZT.ZZT_PESENT AS PES_BRUTO "
			_sQuery += "    ,ZZT.ZZT_PESSAI AS TARA "
			_sQuery += "    ,ZZT.ZZT_PESENT - ZZT.ZZT_PESSAI AS PESO_LIQUIDO "
			_sQuery += "    ,0 AS DENSIDADE "
			_sQuery += "    ,0 AS VOLUME "
			_sQuery += "    ,0 AS DIFERENCA "
			_sQuery += "    ,ZAF.ZAF_EXTRSE AS EXTRATO_SECO "
			_sQuery += "    ,ZAF.ZAF_BRIX AS BRIX "
			_sQuery += "    ,ZAF.ZAF_BRIX1 AS BRIX1 "
			_sQuery += "    ,ZAF.ZAF_BRIX2 AS BRIX2 "
			_sQuery += "    ,ZAF.ZAF_COR AS COR "
			_sQuery += "    ,ZAF.ZAF_COR420 AS COR420 "
			_sQuery += "    ,ZAF.ZAF_COR520 AS COR520 "
			_sQuery += "    ,ZAF.ZAF_COR620 AS COR620 "
			_sQuery += "    ,ZAF.ZAF_DENSID AS DENSIDADE_LAUDO "
			_sQuery += "    ,ZAF.ZAF_SOLID AS SOLIDO "
			_sQuery += "    ,ZAF.ZAF_SOLID1 AS SOLIDO1 "
			_sQuery += "    ,ZAF.ZAF_SOLID2 AS SOLIDO2 "
			_sQuery += " FROM SD2010 AS SD2 "
			_sQuery += " INNER JOIN SF2010 AS SF2 "
			_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
			_sQuery += " 			AND SF2.F2_FILIAL = SD2.D2_FILIAL "
			_sQuery += " 			AND SF2.F2_DOC = SD2.D2_DOC "
			_sQuery += " 			AND SF2.F2_SERIE = SD2.D2_SERIE "
			_sQuery += " 			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
			_sQuery += " 			AND SF2.F2_LOJA = SD2.D2_LOJA "
			_sQuery += " 			AND SF2.F2_CHVNFE <> '') "
			_sQuery += " INNER JOIN SB1010 AS SB1 "
			_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
			_sQuery += " 			AND SB1.B1_COD = SD2.D2_COD) "
			_sQuery += " INNER JOIN ZZT010 AS ZZT "
			_sQuery += " 	ON (ZZT.D_E_L_E_T_ = '' "
			_sQuery += " 			AND ZZT.ZZT_CHVNFE = SF2.F2_CHVNFE) "
			_sQuery += " LEFT JOIN SA2010 AS SA2 "
			_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
			_sQuery += " 			AND SA2.A2_COD = SF2.F2_CLIENTE "
			_sQuery += " 			AND SA2.A2_LOJA = SF2.F2_LOJA) "
			_sQuery += " LEFT JOIN SA1010 AS SA1 "
			_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
			_sQuery += " 			AND SA1.A1_COD = SF2.F2_CLIENTE "
			_sQuery += " 			AND SA1.A1_LOJA = SF2.F2_LOJA) "
			_sQuery += " LEFT JOIN ZAF010 ZAF "
			_sQuery += " 	ON ZAF.D_E_L_E_T_ = '' "
			_sQuery += " 		AND ZAF.ZAF_FILIAL = SD2.D2_FILIAL "
			_sQuery += " 		AND ZAF.ZAF_PRODUT = SD2.D2_COD "
			_sQuery += " 		AND ZAF.ZAF_LOTE = SD2.D2_LOTECTL "
			_sQuery += " 		AND ZAF.ZAF_DATA <= SD2.D2_EMISSAO "
			_sQuery += " 		AND ZAF.ZAF_VALID >= SD2.D2_EMISSAO "
			_sQuery += " 		AND NOT EXISTS (SELECT "
			_sQuery += " 				* "
			_sQuery += " 			FROM ZAF010 MAIS_RECENTE "
			_sQuery += " 			WHERE MAIS_RECENTE.D_E_L_E_T_ = '' "
			_sQuery += " 			AND MAIS_RECENTE.ZAF_FILIAL = ZAF.ZAF_FILIAL "
			_sQuery += " 			AND MAIS_RECENTE.ZAF_LOTE = ZAF.ZAF_LOTE "
			_sQuery += " 			AND MAIS_RECENTE.ZAF_ENSAIO > ZAF.ZAF_ENSAIO) "
			_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
			_sQuery += " AND SD2.D2_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
			_sQuery += " AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
			_sQuery += " AND SD2.D2_GRUPO = '3000' "
			_sQuery += " AND SD2.D2_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " AND SD2.D2_COD BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
			_sQuery += " AND SD2.D2_TES <> '' "
		EndIf
		u_log2 ('debug', _sQuery)
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
		//u_log (_aDados)
    	if len(_aDados) > 0 
    		
    		do while .t. 
	    		_aCols = {}
	    	
				aadd (_aCols, { 1, "Tipo NF"           ,  10,  "@!"})
	    		aadd (_aCols, { 2, "Filial"            ,  10,  "@!"})
	    		aadd (_aCols, { 3, "Ticket"            ,  30,  "@!"})
	    		aadd (_aCols, { 4, "Dt.Ticket"         ,  30,  "@!"})
	    		aadd (_aCols, { 5, "Guia"              ,  30,  "@!"})
	    		aadd (_aCols, { 6, "Placa do Ve�culo"  ,  50,  "@!"})
	    		aadd (_aCols, { 7, "Dt.Digita��o"      ,  30,  "@!"})
	    		aadd (_aCols, { 8, "Num.Nota"          ,  30,  "@!"})
		    	aadd (_aCols, { 9, "Serie"             ,  10,  "@!"})
		    	aadd (_aCols, {10, "Fornecedor"        ,  30,  "@D"})
		    	aadd (_aCols, {11, "Raz�o Social"      , 100,  "@!"})
		    	aadd (_aCols, {12, "Produto"           ,  30,  "@!"})
		    	aadd (_aCols, {13, "Descricao"         , 100,  "@!"})
		    	aadd (_aCols, {14, "UM"          	   ,  10,  "@!"})
		    	aadd (_aCols, {15, "Quantidade"    	   ,  50,  "@E 9,999,999.9999"})
		    	aadd (_aCols, {16, "Peso Bruto"    	   ,  50,  "@E 9,999,999.9999"})
		    	aadd (_aCols, {17, "Tara"    	       ,  50,  "@E 9,999,999.9999"})
		    	aadd (_aCols, {18, "Peso Liquido"      ,  50,  "@E 9,999,999.9999"})
		    	aadd (_aCols, {19, "Densidade NF"      ,  20,  "@E 9.9999"		  })
		    	aadd (_aCols, {20, "Volume"   	       ,  50,  "@E 9,999,999.9999"})
		    	aadd (_aCols, {21, "Diferen�a" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {22, "Extrato Seco" 	   ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {23, "Brix" 	       	   ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {24, "Brix 2" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {25, "Brix 3" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {26, "Cor" 	           ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {27, "Cor 420nm" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {28, "Cor 520nm" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {29, "Cor 620nm" 	       ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {30, "Densidade Laudo"   ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {31, "Solido"   		   ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {32, "Solido 2"          ,  50,  "@E 9,999,999.9999"})
				aadd (_aCols, {33, "Solido 3"          ,  50,  "@E 9,999,999.9999"})
		        
		    	_wlinha = U_F3Array (_aDados, "Consulta X Guias Transito", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
		    	
		    	if _wlinha > 0
		    		_ConsNF (_aDados[_wlinha,5], _aDados[_wlinha,6], _aDados[_wlinha,7] )
		    	else
	 	    		exit	
		    	endif
		    enddo
		    	
		else
			u_help("N�o foram encontrados dados para consulta")
		endif    		
	endif
	
return
// --------------------------------------------------------------------------
// Consulta detalhes da movimentacao.
static function _ConsNF ( _wDoc, _wSerie, _wFornece)
	// Variaveis para a rotina de visualizacao da nota.
	Private aRotina    := {{ , , 0 , 2 }}
	Private l103Auto   := .F.
	Private aAutoCab   := {}
	Private aAutoItens := {}

	sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	if sf1 -> (dbseek ( xFilial("SF1") + _wDoc + _wSerie + _wFornece + '01', .F.))
		A103NFiscal ('SF1', recno (), 1)
	else
		u_help ("NF '" + _wDoc + "' nao encontrada.")
	endif
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de	       ", "C", 2, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Filial at�	       ", "C", 2, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Data Entrada de    ", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {04, "Data Entrada at�   ", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {05, "Fornecedor de	   ", "C", 6, 0,  "",   "SA2", {},  ""})
    aadd (_aRegsPerg, {06, "Fornecedor at�	   ", "C", 6, 0,  "",   "SA2", {},  ""})
	aadd (_aRegsPerg, {07, "Produto de         ", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {08, "Produto at�        ", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {09, "Tipo de nota       ", "N", 1, 0,  "",   "   ", {"Entradas", "Saidas", "Ambos"},  ""})
	
	U_ValPerg (_cPerg, _aRegsPerg) 
Return
