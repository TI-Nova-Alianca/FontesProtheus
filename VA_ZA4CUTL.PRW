//  Programa...: VA_ZA4CUTL
//  Autor......: Catia Cardoso
//  Data.......: 24/01/2018
//  Descricao..: Controle de Verbas - Consulta Verbas UTILIZADAS POR CLIENTE 
//
//  Alterações:
//  10/04/2018 - Catia - Incluir o campo Supervisor na tela de grade
//  07/05/2018 - Catia - Não estava trazendo o supervisor em alguns casos
//  15/08/2018 - Catia - Tinha um u_showmemo aberto
//  15/11/2018 - Andre - Acrescentado campo Data Vencimento
//  10/12/2018 - Catia - tratamento para vendedor do SF2 e do SE1
//  14/01/2019 - Catia - teste pq segundo o cesar estavam aparecendo verbas duplicadas e nao estava fechando com o NAWEB 
//                     - mas o NAWEB estava fazendo filtro pelo NOME do cliente e nao estava usando o conceito de codigo matriz
//                     - expliquei mais uma vez pro Guilherme espero que ele arrume isso - o exemplo tipico de erro é o ZAFFARI por exemplo
//  08/02/2019 - Catia - correcao verbas duplicadas quando fazia o join no se1
//  18/12/2018 - Catia - tratamento para vendedores pelo do SE1 e do SA1
//  03/08/2020 - Cláudia - Alterada a consulta incluindo vendedor da verba e vendedor da NF. GLPI: 8251
//
// ----------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ZA4CUTL()

	cPerg   := "ZA4CUTL"
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.)
		// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
    	_sQuery := ""
    	_sQuery += " WITH C AS ( SELECT ZA5.ZA5_NUM"
		_sQuery += " 				  , ZA5.ZA5_CLI"	 
		_sQuery += " 				  , ZA5.ZA5_LOJA"	 
		_sQuery += " 				  , SA1.A1_NOME"	 
		_sQuery += " 				  , SA1.A1_EST"	 
		_sQuery += " 				  , SA1.A1_VACBASE"
		_sQuery += " 				  , SA1.A1_VALBASE"
		//_sQuery += "				  , ISNULL(SE1.E1_VEND1, SA1.A1_VEND) AS VEND"
	    //_sQuery += "				  , IIF(SE1.E1_VEND1 != '', SA3T.A3_NOME, SA3C.A3_NOME) AS NVEND"
	    //_sQuery += "				  , IIF(SE1.E1_VEND1 != '', SA3T.A3_VAGEREN, SA3C.A3_VAGEREN) AS SUP"
	    If mv_par11 == 1 .or. mv_par11==3
	    	_sQuery += " 				  ,ZA4.ZA4_VEND AS VENDVERBA
			_sQuery += " 				  ,SA3V.A3_NOME AS NVENDVERBA
			_sQuery += " 				  ,SA3V.A3_VAGEREN AS SUPVERBA
		EndIf
		If mv_par11 == 2 .or. mv_par11==3
			_sQuery += " 				  ,ZA5.ZA5_VENNF AS VENDNF
			_sQuery += " 				  ,SA3NF.A3_NOME AS NVENDNF
			_sQuery += " 				  ,SA3NF.A3_VAGEREN AS SUPNF
		EndIf
		_sQuery += " 				  , ZA4.ZA4_COD	 , ZA3.ZA3_DES"	 
		_sQuery += " 				  , CASE WHEN ZA3.ZA3_IND='1' THEN 'Anual'			WHEN ZA3.ZA3_IND='2' THEN 'Trimestral'			WHEN ZA3.ZA3_IND='3' THEN 'Mensal'			WHEN ZA3.ZA3_IND='4' THEN 'Semestral'			WHEN ZA3.ZA3_IND='5' THEN 'Eventual Contato'			WHEN ZA3.ZA3_IND='9' THEN 'Acordo Isolado'	   ELSE '' END AS TIPO"  	
		_sQuery += " 				  , CASE WHEN ZA4.ZA4_CTB='1' THEN 'Encartes/ponto extra'    	   WHEN ZA4.ZA4_CTB='2' THEN 'Feiras'    	   WHEN ZA4.ZA4_CTB='3' THEN 'Fretes'    	   WHEN ZA4.ZA4_CTB='4' THEN 'Campanhas de vendas'    	   WHEN ZA4.ZA4_CTB='5' THEN 'Abert/reinaugur.loja'    	   WHEN ZA4.ZA4_CTB='6' THEN 'Multa contratual'	   ELSE '' END AS CTB"	
		_sQuery += "				  , CASE WHEN ZA4.ZA4_TLIB='1' THEN 'Bonificação'    	   WHEN ZA4.ZA4_TLIB='2' THEN 'Desconto'    	   WHEN ZA4.ZA4_TLIB='3' THEN 'Boleto'    	   WHEN ZA4.ZA4_TLIB='4' THEN 'Deposito'    	   WHEN ZA4.ZA4_TLIB='5' THEN 'NAO AUTORIZADA'      ELSE 'NAO LIBERADA' END AS TIPO_LIB"    
		_sQuery += " 				  , CASE WHEN ZA4.ZA4_SUTL='0' THEN 'Não' WHEN ZA4.ZA4_SUTL='1'  THEN 'Parcial' WHEN ZA4.ZA4_SUTL='2'  THEN 'Sim'  ELSE '***' END AS UTILIZADA" 	
 		_sQuery += " 				  , ZA4.ZA4_DLIB 	, ZA4.ZA4_ULIB 	 , ZA4.ZA4_VENCTO"
 		_sQuery += " 				  , ZA5.ZA5_DTA"
 		_sQuery += " 				  , ZA5.ZA5_USU"
 		_sQuery += " 				  , ZA5.ZA5_DOC" 
 		_sQuery += " 				  , ZA5.ZA5_VLR"
 		_sQuery += "                  , ZA5.ZA5_PARC"
 		If mv_par11 == 2
 			_sQuery += " 				  ,ZA4.ZA4_VEND AS VENDVERBA
 		EndIf
 		_sQuery += " 			   FROM ZA5010 AS ZA5" 	
 		_sQuery += " 					INNER JOIN SA1010 AS SA1"    	
		_sQuery += " 						ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += " 							AND SA1.A1_EST  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		_sQuery += " 							AND SA1.A1_COD  = ZA5.ZA5_CLI" 	   		
		_sQuery += " 							AND SA1.A1_LOJA = ZA5.ZA5_LOJA)" 	
 		_sQuery += " 					INNER JOIN ZA4010 AS ZA4"
		_sQuery += " 						ON (ZA4.ZA4_NUM     = ZA5.ZA5_NUM"
		_sQuery += " 							AND ZA4.ZA4_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery += " 		      				AND ZA4.ZA4_CLI BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "')"
		_sQuery += " 					INNER JOIN ZA3010 AS ZA3"    	
 		_sQuery += " 						ON (ZA3.D_E_L_E_T_  = ''"        	
 		_sQuery += " 							AND ZA3.ZA3_COD  = ZA4.ZA4_COD)"
 		_sQuery += "					LEFT JOIN SE1010 AS SE1"
 		_sQuery += "						ON (SE1.D_E_L_E_T_ = ''"
 		_sQuery += "						    AND SE1.E1_NUM     = ZA5.ZA5_DOC"
 		_sQuery += "                            AND SE1.E1_PARCELA = ZA5.ZA5_PARC"
		_sQuery += "	                        AND SE1.E1_CLIENTE = ZA5.ZA5_CLI"
		_sQuery += "	                        AND SE1.E1_LOJA    = ZA5.ZA5_LOJA)"
		_sQuery += " 					LEFT JOIN SA3010 AS SA3V" 	    
 		_sQuery += "						ON (SA3V.D_E_L_E_T_ = ''"
 		_sQuery += "							AND SA3V.A3_COD = ZA4.ZA4_VEND)"
		//_sQuery += " 					LEFT JOIN SA3010 AS SA3T" 	    
 		//_sQuery += "						ON (SA3T.D_E_L_E_T_ = ''"
 		//_sQuery += "							AND SA3T.A3_COD = SE1.E1_VEND1)"
 		_sQuery += "					LEFT JOIN SF2010 AS SF2"
 		_sQuery += "						ON (SF2.D_E_L_E_T_ = ''"
 		_sQuery += "						    AND SF2.F2_DOC     = ZA5.ZA5_DOC"
 		_sQuery += "						    AND SF2.F2_SERIE     = '10'"
		_sQuery += "	                        AND SF2.F2_CLIENTE = ZA5.ZA5_CLI"
		_sQuery += "	                        AND SF2.F2_LOJA    = ZA5.ZA5_LOJA)"
		_sQuery += "	                LEFT JOIN SA3010 AS SA3NF"
		_sQuery += "	                	ON (SA3NF.D_E_L_E_T_ = ''"
		_sQuery += "	                	AND SA3NF.A3_COD = ZA5.ZA5_VENNF)"
		//_sQuery += " 					LEFT JOIN SA3010 AS SA3C" 	    
 		//_sQuery += "						ON (SA3C.D_E_L_E_T_ = ''"
 		//_sQuery += "							AND SA3C.A3_COD = SA1.A1_VEND)"
 		_sQuery += " 			WHERE ZA5.D_E_L_E_T_ = ''"
 		_sQuery += " 			  AND ZA5.ZA5_DTA    BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
  		_sQuery += " )"   
 		_sQuery += " SELECT *"   
 		_sQuery += "   FROM C"
 		_sQuery += "  WHERE C.VENDVERBA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
 		_sQuery += "   UNION ALL"
 		_sQuery += "   SELECT DISTINCT '' AS ZA5_NUM"
		_sQuery += "   , '999999' AS ZA5_CLI" 
		_sQuery += "   , '' AS ZA5_LOJA" 
		_sQuery += "   , 'TOTAL EM VERBAS' AS A1_NOME" 
		_sQuery += "   , '' AS A1_EST" 
		_sQuery += "   , '' AS A1_VACBASE"
		_sQuery += "   , '' AS A1_VALBASE"
		If mv_par11 == 1 .or. mv_par11==3
		 	_sQuery += "   , '' AS VENDVERBA
		 	_sQuery += "   , '' AS NVENDVERBA
		 	_sQuery += "   , '' AS SUPVERBA
		EndIf
		If mv_par11 == 2 .or. mv_par11==3
			_sQuery += "   , '' AS VENDNF
			_sQuery += "   , '' AS NVENDNF
			_sQuery += "   , '' AS SUPNF
		EndIf
		//_sQuery += "   , '' AS VEND" 
		//_sQuery += "   , 'TOTAL EM VERBAS' AS NVEND" 
		//_sQuery += "   , '' AS SUP"
		_sQuery += "   , '' AS ZA4_COD	 , '' AS ZA3_DES" 
		_sQuery += "   , '' AS TIPO" 	
		_sQuery += "   , 'TOTAL EM VERBAS' AS CTB"
		_sQuery += "   , '' AS TIPO_LIB"
 		_sQuery += "   , '' AS UTILIZADA"	
 		_sQuery += "   , '' AS ZA4_DLIB 	, '' AS ZA4_ULIB     , '' AS ZA4_VENCTO"
 		_sQuery += "   , '' AS DT_UTLIZACAO"
 		_sQuery += "   , '' AS ZA5_USU"
 		_sQuery += "   , '' AS ZA5_DOC"
 		_sQuery += "   , (SELECT SUM(C.ZA5_VLR)"
	  	_sQuery += "   FROM C 
	  	_sQuery += "  WHERE C.VENDVERBA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "') AS ZA5_VLR"
	  	_sQuery += "   ,' ' AS ZA5_PARCELA"
	  	If mv_par11 == 2
 			_sQuery += " 				  ,'' AS VENDVERBA
 		EndIf
		_sQuery += "   FROM C"
 		_sQuery += "  ORDER BY  C.ZA5_CLI, C.ZA5_DTA"
    	u_log (_sQuery)
    	_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0
    	
    		_aCols = {}
    		If mv_par11 == 3
		    	aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
		    	aadd (_aCols, {02, "Cliente"        	,  30,  "@!"})
		    	aadd (_aCols, {03, "Loja"           	,  10,  "@!"})
		    	aadd (_aCols, {04, "Razão Social"   	, 140,  "@!"})
		    	aadd (_aCols, {05, "UF"             	,  10,  "@!"})
		    	aadd (_aCols, {06, "Matriz"        	    ,  30,  "@!"})
		    	aadd (_aCols, {07, "Lj Matriz"        	,  10,  "@!"})
		    	aadd (_aCols, {08, "Vend. Verba"       	,  30,  "@!"})
		    	aadd (_aCols, {09, "Nome vend.Verba"  	, 140,  "@!"})
		    	aadd (_aCols, {10, "Supervisor Verba"   ,  30,  "@!"})
		    	aadd (_aCols, {11, "Vend. NF"       	,  30,  "@!"})
		    	aadd (_aCols, {12, "Nome Vend.NF"  		, 140,  "@!"})
		    	aadd (_aCols, {13, "Supervisor NF"     	,  30,  "@!"})
		    	aadd (_aCols, {14, "Verba"       	  	,  20,  "@!"})
		    	aadd (_aCols, {15, "Descricao"         	,  90,  "@!"})
		    	aadd (_aCols, {16, "Tipo"     			,  70,  "@!"})
		    	aadd (_aCols, {17, "Contabilizar"  	    ,  70,  "@!"})
		    	aadd (_aCols, {18, "Tipo Liberacao"    	,  40,  "@!"})
		    	aadd (_aCols, {19, "Utilizada"          ,  30,  "@!"})
		    	aadd (_aCols, {20, "Data Liberacao"    	,  20,  "@D"})
		    	aadd (_aCols, {21, "Usuario Liberacao"  ,  60,  "@!"})
		    	aadd (_aCols, {22, "Data Vencimento"    ,  20,  "@D"})
			    aadd (_aCols, {23, "Data Utilizacao"    ,  20,  "@D"})
			    aadd (_aCols, {24, "Usuário Utilizacao" ,  60,  "@!"})
			    aadd (_aCols, {25, "Documento" 		    ,  50,  "@!"})
				aadd (_aCols, {26, "Valor"       	    ,  60,  "@E 999,999.99"})
			Else		
		    	aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
		    	aadd (_aCols, {02, "Cliente"        	,  30,  "@!"})
		    	aadd (_aCols, {03, "Loja"           	,  10,  "@!"})
		    	aadd (_aCols, {04, "Razão Social"   	, 140,  "@!"})
		    	aadd (_aCols, {05, "UF"             	,  10,  "@!"})
		    	aadd (_aCols, {06, "Matriz"        	    ,  30,  "@!"})
		    	aadd (_aCols, {07, "Lj Matriz"        	,  10,  "@!"})
		    	If mv_par11 == 1
			    	aadd (_aCols, {08, "Vend. Verba"       	,  30,  "@!"})
			    	aadd (_aCols, {09, "Nome vend.Verba"  	, 140,  "@!"})
			    	aadd (_aCols, {10, "Supervisor Verba"   ,  30,  "@!"})
		    	EndIf
		    	If mv_par11 == 2
			    	aadd (_aCols, {08, "Vend. NF"       	,  30,  "@!"})
			    	aadd (_aCols, {09, "Nome Vend.NF"  		, 140,  "@!"})
			    	aadd (_aCols, {10, "Supervisor NF"     	,  30,  "@!"})
		    	EndIf
		    	aadd (_aCols, {11, "Verba"       	  	,  20,  "@!"})
		    	aadd (_aCols, {12, "Descricao"         	,  90,  "@!"})
		    	aadd (_aCols, {13, "Tipo"     			,  70,  "@!"})
		    	aadd (_aCols, {14, "Contabilizar"  	    ,  70,  "@!"})
		    	aadd (_aCols, {15, "Tipo Liberacao"    	,  40,  "@!"})
		    	aadd (_aCols, {16, "Utilizada"          ,  30,  "@!"})
		    	aadd (_aCols, {17, "Data Liberacao"    	,  20,  "@D"})
		    	aadd (_aCols, {18, "Usuario Liberacao"  ,  60,  "@!"})
		    	aadd (_aCols, {19, "Data Vencimento"    ,  20,  "@D"})
			    aadd (_aCols, {20, "Data Utilizacao"    ,  20,  "@D"})
			    aadd (_aCols, {21, "Usuário Utilizacao" ,  60,  "@!"})
			    aadd (_aCols, {22, "Documento" 		    ,  50,  "@!"})
				aadd (_aCols, {23, "Valor"       	    ,  60,  "@E 999,999.99"})
				
				
			EndIf
			
		    //U_F3Array (_aDados, "Consulta Verbas Utilizadas: ", _aCols, oMainWnd:nClientWidth - 300, oMainWnd:nClientHeight -200 , "", "", .T., 'C' )
		    U_F3Array (_aDados, "Consulta Verbas Utilizadas:", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -30 , "", "", .T., 'C' )
			
		else
			msgalert("Não foram encontrados dados para consulta")			
		endif			
			    	
	endif
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes    Help
    aadd (_aRegsPerg, {01, "Cliente de          ?", "C", 6, 0,  "",   "SA1", {}					,  ""})
	aadd (_aRegsPerg, {02, "Cliente ate         ?", "C", 6, 0,  "",   "SA1", {}					,  ""})
	aadd (_aRegsPerg, {03, "Data Utilizacao de  ?", "D", 8, 0,  "",   "   ", {}					,  ""})
    aadd (_aRegsPerg, {04, "Data Utilizacao até ?", "D", 8, 0,  "",   "   ", {}					,  ""})
    aadd (_aRegsPerg, {05, "Verba de            ?", "C", 3, 0,  "",   "ZA3", {}					,  ""})
	aadd (_aRegsPerg, {06, "Verba até           ?", "C", 3, 0,  "",   "ZA3", {}					,  ""})
	aadd (_aRegsPerg, {07, "Vendedor de         ?", "C", 3, 0,  "",   "SA3", {}					,  ""})
	aadd (_aRegsPerg, {08, "Vendedor até        ?", "C", 3, 0,  "",   "SA3", {}					,  ""})
	aadd (_aRegsPerg, {09, "UF de               ?", "C", 2, 0,  "",   "12" , {}					,  ""})
	aadd (_aRegsPerg, {10, "UF até              ?", "C", 2, 0,  "",   "12" , {}					,  ""})
	aadd (_aRegsPerg, {11, "Tipo vendedor       ?", "N", 1, 0,  "",   "   ", {"Verba","Nota","Ambos"}	,  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
