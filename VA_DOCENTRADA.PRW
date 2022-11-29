// Programa...: VA_DOCENTRADA
// Autor......: Andre Alves
// Data.......: 13/08/2018
// Descricao..: Consultas Documentos de Entrada por Especie e Tipo
//
// #TipoDePrograma    #consulta
// #Descricao         #Consultas Documentos de Entrada por Especie e Tipo
// #PalavasChave      #ponto_de_entrada
// #TabelasPrincipais #SF1 
// #Modulos 		  #COM
//
// Historico de alteracoes:
// 03/10/2018 - Catia   - Incluido os % e o total geral
// 28/11/2022 - Cláudia - Incluídas colunas referentes ao painel XML. GLPI: 12844
//
// ------------------------------------------------------------------------------------------------
User Function VA_DOCENTRADA ()
    cPerg := "VA_DOCENTRADA"
    
    _ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	do case
    	case mv_par03 = 1

			_sQuery := " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,0 AS EDI_TIPO "
			_sQuery += "    ,0 AS XML_TIPO "
			_sQuery += "    ,0 AS SAFRA_TIPO "
			_sQuery += "    ,0 AS DIG_TIPO "
			_sQuery += "    ,0 AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "

			_sQuery += " UNION ALL "
			_sQuery += " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,COUNT(*) AS EDI_TIPO "
			_sQuery += "    ,0 AS XML_TIPO "
			_sQuery += "    ,0 AS SAFRA_TIPO "
			_sQuery += "    ,0 AS DIG_TIPO "
			_sQuery += "    ,0 AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " AND F1_VAFLAG = 'S' "
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "

			_sQuery += " UNION ALL "
			_sQuery += " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,0 AS EDI_TIPO "
			_sQuery += "    ,COUNT(*) AS XML_TIPO "
			_sQuery += "    ,0 AS SAFRA_TIPO "
			_sQuery += "    ,0 AS DIG_TIPO "
			_sQuery += "    ,0 AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " AND F1_VAFLAG = 'X' "
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "

			_sQuery += " UNION ALL "
			_sQuery += " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,0 AS EDI_TIPO "
			_sQuery += "    ,0 AS XML_TIPO "
			_sQuery += "    ,COUNT(*) AS SAFRA_TIPO "
			_sQuery += "    ,0 AS DIG_TIPO "
			_sQuery += "    ,0 AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " AND F1_VAFLAG = 'G' "
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "

			_sQuery += " UNION ALL "
			_sQuery += " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,0 AS EDI_TIPO "
			_sQuery += "    ,0 AS XML_TIPO "
			_sQuery += "    ,0 AS SAFRA_TIPO "
			_sQuery += "    ,COUNT(*) AS DIG_TIPO "
			_sQuery += "    ,0 AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " AND F1_VAFLAG = '' "
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "

			_sQuery += " UNION ALL "
			_sQuery += " SELECT "
			_sQuery += " 	 F1_ESPECIE AS ESPECIE "
			_sQuery += "    ,F1_TIPO AS TIPO "
			_sQuery += "    ,0 AS EDI_TIPO "
			_sQuery += "    ,0 AS XML_TIPO "
			_sQuery += "    ,0 AS SAFRA_TIPO "
			_sQuery += "    ,0 AS DIG_TIPO "
			_sQuery += "    ,COUNT(*) AS PAINEL_TIPO "
			_sQuery += " FROM SF1010 AS F1 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " AND F1_VAFLAG = 'P' "
			_sQuery += " GROUP BY F1_ESPECIE "
			_sQuery += " 		,F1_TIPO "	
			u_log(_sQuery)
			
			//u_showmemo(_sQuery)
			   
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0 
				_aCols = {}
				
			   	aadd (_aCols, {1,  "ESPECIE"       	   ,  30,  "@!"})
			   	aadd (_aCols, {2,  "TIPO"              ,  20,  "@!"})
			   	aadd (_aCols, {3,  "VIA EDI"      	   ,  30,  "@!"})
			   	aadd (_aCols, {4,  "VIA XML"           ,  30,  "@!"})
			   	aadd (_aCols, {5,  "GER SAFRA"         ,  30,  "@!"})
			   	aadd (_aCols, {6,  "DIGITADOS"         ,  30,  "@!"})
				aadd (_aCols, {7,  "PAINEL"            ,  30,  "@!"})
			    	
				U_F3Array (_aDados, "Consulta documentos de entrada, periodo: " + dtoc (mv_par01) + " a " + dtoc (mv_par02), _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			else
				u_help("Não foram encontrados dados para consulta")
			endif
		case mv_par03 = 2
			_sQuery := ""
			_sQuery += " SELECT SUBSTRING(F1_DTDIGIT, 1 , 6) AS MES_ANO_DIGITACAO"
			_sQuery += "      , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += "      , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += "	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY SUBSTRING(F1_DTDIGIT, 1 , 6)"
			_sQuery += " UNION ALL"
			_sQuery += " SELECT 'TOTAL' AS MESA_ANO_DIGITACAO
			_sQuery += "      , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += "      , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += "	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " ORDER BY SUBSTRING(F1_DTDIGIT, 1 , 6)"
			u_log(_sQuery)
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0 
				_aCols = {}
				
			   	aadd (_aCols, {1,  "ANOMES"            ,  40,  "@!"})
			   	aadd (_aCols, {2,  "VIA EDI"      	   ,  30,  "@!"})
			   	aadd (_aCols, {3,  "%EDI"      	       ,  30,  "@E 999"})
			   	aadd (_aCols, {4,  "VIA XML"           ,  30,  "@!"})
			   	aadd (_aCols, {5,  "%XML"      	       ,  30,  "@E 999"})
			   	aadd (_aCols, {6,  "VIA SAFRA"         ,  30,  "@!"})
			   	aadd (_aCols, {7,  "%SAFRA"   	       ,  30,  "@E 999"})
			   	aadd (_aCols, {8,  "DIGITADOS"         ,  30,  "@!"})
			   	aadd (_aCols, {9,  "%DIG"      	       ,  30,  "@E 999"})
				aadd (_aCols, {10,  "PAINEL"           ,  30,  "@!"})
			   	aadd (_aCols, {11,  "%PAINEL"      	   ,  30,  "@E 999"})
			   	aadd (_aCols, {12,  "TOTAL DOC"        ,  30,  "@!"})
			    	
				U_F3Array (_aDados, "Consulta documentos de entrada, periodo: " + dtoc (mv_par01) + " a " + dtoc (mv_par02), _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			else
				u_help("Não foram encontrados dados para consulta")
			endif
			
		case mv_par03 = 3
			_sQuery := ""
			_sQuery += " SELECT UPPER(F1_VAUSER) AS USUARIO"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += "	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY F1_VAUSER"
			_sQuery += " UNION ALL"
			_sQuery += " SELECT '** TOTAL' AS USUARIO"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += "	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += "	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " ORDER BY UPPER(F1_VAUSER)"
			u_log(_sQuery)
			_aDados := U_Qry2Array(_sQuery)
			
			if len(_aDados) > 0 
				_aCols = {}
				
			   	aadd (_aCols, {1,  "USUARIO"           	, 100, "@!"})
			   	aadd (_aCols, {2,  "VIA EDI"      	   	,  30, "@!"})
			   	aadd (_aCols, {3,  "%EDI"      	       	,  30, "@E 999"})
			   	aadd (_aCols, {4,  "VIA XML"           	,  30, "@!"})
			   	aadd (_aCols, {5,  "%XML"      	       	,  30, "@E 999"})
			   	aadd (_aCols, {4,  "VIA SAFRA"         	,  30, "@!"})
			   	aadd (_aCols, {5,  "%SAFRA"   	       	,  30, "@E 999"})
			   	aadd (_aCols, {6,  "DIGITADOS"         	,  30, "@!"})
			   	aadd (_aCols, {7,  "%DIG"      	       	,  30, "@E 999"})
				aadd (_aCols, {8,  "PAINEL"         	,  30, "@!"})
			   	aadd (_aCols, {9,  "%PAINEL"      	    ,  30, "@E 999"})
			   	aadd (_aCols, {10, "TOTAL DOC"          ,  30, "@!"})
			    	
				U_F3Array (_aDados, "Consulta documentos de entrada, periodo: " + dtoc (mv_par01) + " a " + dtoc (mv_par02), _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			else
				u_help("Não foram encontrados dados para consulta")
			endif
			
		case mv_par03 = 4
			_sQuery := ""
			_sQuery += " SELECT SUBSTRING(F1_DTDIGIT, 1 , 6) AS MES_ANO_DIGITACAO"
			_sQuery += "      , UPPER(F1_VAUSER) AS USUARIO"
			_sQuery += " 	  , F1_ESPECIE AS ESPECIE"
			_sQuery += " 	  , F1_TIPO AS TIPO"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += " 	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY SUBSTRING(F1_DTDIGIT, 1 , 6), F1_ESPECIE, F1_TIPO, UPPER(F1_VAUSER)"
			_sQuery += " UNION ALL "
			_sQuery += " SELECT 'TOTAL' AS MES_ANO_DIGITACAO"
			_sQuery += "      , '' AS USUARIO"
			_sQuery += " 	  , '' AS ESPECIE"
			_sQuery += " 	  , '' AS TIPO"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) AS TEDI"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'S'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_EDI"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) AS TXML"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'X'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_XML"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) AS TGER"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'G'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_GER"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) AS TDIG"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_DIG"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) AS TPAINEL"
			_sQuery += " 	  , sum(CASE WHEN F1_VAFLAG = 'P'  THEN 1 ELSE 0 END) * 100 / count(*) AS POR_PAINEL"
			_sQuery += " 	  , count(*) AS TOTAL_DOCS_MES"
			_sQuery += "   FROM SF1010"
			_sQuery += "  WHERE D_E_L_E_T_ = ''"
			_sQuery += "	AND F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " ORDER BY SUBSTRING(F1_DTDIGIT, 1 , 6), UPPER(F1_VAUSER), F1_ESPECIE, F1_TIPO"
			_aDados := U_Qry2Array(_sQuery)
			u_log(_sQuery)
			
			if len(_aDados) > 0 
				_aCols = {}
				
			   	aadd (_aCols, { 1,  "ANOMES"            ,  30, "@!"})
			   	aadd (_aCols, { 2,  "USUARIO"           ,  50, "@!"})
			   	aadd (_aCols, { 3,  "ESPECIE"           ,  40, "@!"})
			   	aadd (_aCols, { 4,  "TIPO"              ,  30, "@!"})
			   	aadd (_aCols, { 5,  "VIA EDI"      	    ,  30, "@!"})
			   	aadd (_aCols, { 6,  "%EDI"      	    ,  30, "@E 999"})
			   	aadd (_aCols, { 7,  "VIA XML"           ,  30, "@!"})
			   	aadd (_aCols, { 8,  "%XML"      	    ,  30, "@E 999"})
			   	aadd (_aCols, { 9,  "VIA SAFRA"         ,  30, "@!"})
			   	aadd (_aCols, {10,  "%SAFRA"     	    ,  30, "@E 999"})
			   	aadd (_aCols, {11,  "DIGITADOS"         ,  30, "@!"})
			   	aadd (_aCols, {12,  "%DIG"      	    ,  30, "@E 999"})
				aadd (_aCols, {13,  "PAINEL"            ,  30, "@!"})
			   	aadd (_aCols, {14,  "%PAINEL"      	    ,  30, "@E 999"})
			   	aadd (_aCols, {15,  "TOTAL DOC"         ,  30, "@!"})
			    	
				U_F3Array (_aDados, "Consulta documentos de entrada, periodo: " + dtoc (mv_par01) + " a " + dtoc (mv_par02), _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			else
				u_help("Não foram encontrados dados para consulta")
			endif
			
		endcase	
	endif	
return     
//     
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Data digitação de             ?", "D", 8, 0,  "",   "   ", {},                        "Data inicial"})
	aadd (_aRegsPerg, {02, "Data digitação até            ?", "D", 8, 0,  "",   "   ", {},                        "Data final"})
	aadd (_aRegsPerg, {03, "Tipo Estatística              ?", "N", 1,  0,  "",   "   ", {"Especie/Tipo", "Total p/Mes","P/Usuario","Mes/Usuario/Especie"}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
