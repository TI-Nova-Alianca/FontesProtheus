//  Programa...: ML_LOJFATTAB
//  Autor......: Catia Cardoso
//  Data.......: 14/01/2019
//  Descricao..: VENDAS POR TABELA DE PREÇO  
// 
// 	Definiçoes das tabela enviadas pelo GIOVANI
//  01 - Preço Gôndola;
//  02 - Preço Caixa Fechada;
//  03 - Preço Associados e Funcionários;
//  04 - Preço Parceiros / Revenda / Eventos;
//  05 - Preço Festa de Comunidade / Feira Ponta de Estoque;
//  06 - Preço Representantes;
//  07 - Preço Representantes;
//  08 - Preço Tumelero;
//  09 - Preço Representantes;
//
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_LOJFATTAB()

	
	cPerg   := "ML_LOJFATTAB"
	
	if ! u_zzuvl ('083', __cUserId, .T.)
		return
	endif
    
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
		_lContinua = .T.
		
		// Controle de semaforo.
		_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SA1"))
		if _nLock == 0
			msgalert ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
		
		if _lContinua
			_sQuery = ""
			if mv_par05 <> 3
				// gera array para visualizar dados
	   			_sQuery += "WITH C AS ( "
	   			if mv_par05 == 1
	   				_sQuery += "SELECT SL2.L2_FILIAL AS FILIAL"
		   			_sQuery += "     , SL2.L2_DOC AS CUPOM"
		   			_sQuery += "     , SL2.L2_SERIE AS SERIE" 
		   			_sQuery += "     , SL1.L1_CLIENTE AS CLIENTE"
		   			_sQuery += "     , SA1.A1_NOME AS NOME"
		   			_sQuery += "     , IIF(SA1.A1_LOJAS='F','FUNCIONARIO',IIF(SA1.A1_LOJAS='A','ASSOCIADO','')) AS TIPO_CLIENTE"
		   			_sQuery += "     , SL2.L2_TABELA AS TABELA"
		   			_sQuery += "     , CASE WHEN SL2.L2_TABELA = 1 THEN 'Gôndola'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 2 THEN 'Caixa Fechada'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 3 THEN 'Associados e Funcionários'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 4 THEN 'Parceiros/Revenda/Eventos'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 5 THEN 'Festa de Comunidade/Feira Ponta de Estoque'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 6 THEN 'Representantes'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 7 THEN 'Representantes'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 8 THEN 'Tumelero'"
		   			_sQuery += "			WHEN SL2.L2_TABELA = 9 THEN 'Representantes'"
		   			_sQuery += "	   END AS DESCRICAO_TAB"
	       			_sQuery += "     , SUM(SL2.L2_VLRITEM) AS VALOR"
	       			_sQuery += "	 , ROUND(SUM(SL2.L2_VLRITEM) / (SELECT SUM(L2_VLRITEM)" 
					_sQuery += "									 FROM SL2010 "
					_sQuery += "			   						WHERE D_E_L_E_T_ = ''"
					_sQuery += "   									  AND L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
					_sQuery += "   									  AND L2_SERIE  != '999'"
					_sQuery += "                                      AND L2_DOC    != ''"
		   			_sQuery += "   									  AND L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "')*100,2) AS PERC "
					_sQuery += "  FROM SL2010 AS SL2"
		   			_sQuery += " 	INNER JOIN SL1010 AS SL1"
		   			_sQuery += " 		ON (SL1.D_E_L_E_T_ = ''"
		   			_sQuery += " 			AND SL1.L1_FILIAL = SL2.L2_FILIAL"
		   			_sQuery += " 			AND SL1.L1_NUM    = SL2.L2_NUM"
		   			_sQuery += " 			AND SL1.L1_DOC    = SL2.L2_DOC"
		   			_sQuery += " 			AND SL1.L1_SERIE  = SL2.L2_SERIE)"
		   			_sQuery += " 	INNER JOIN SA1010 AS SA1"
		   			_sQuery += " 		ON (SA1.D_E_L_E_T_  = ''"
		   			_sQuery += " 			AND SA1.A1_COD  = SL1.L1_CLIENTE"
		   			_sQuery += " 			AND SA1.A1_LOJA = SL1.L1_LOJA)"
		   			_sQuery += " WHERE SL2.D_E_L_E_T_ = ''"
		   			_sQuery += "   AND SL2.L2_DOC    != ''"
		   			_sQuery += "   AND SL2.L2_SERIE  != '999'"
		   			_sQuery += "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		   			_sQuery += "   AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		   			_sQuery += "GROUP BY SL2.L2_FILIAL, SL2.L2_DOC, SL2.L2_SERIE, SL1.L1_CLIENTE, SA1.A1_NOME, SA1.A1_LOJAS, SL2.L2_TABELA "
		   			_sQuery += "UNION ALL "
		   		endif	
	   			_sQuery += "SELECT '##'  AS FILIAL" 
	   			_sQuery += "     , '##'  AS CUPOM"
	   			_sQuery += "  	 , '##'  AS SERIE"
	   			_sQuery += "	 , '##'  AS CLIENTE"
	   			_sQuery += "	 , 'TOTAL'  AS NOME"
	   			_sQuery += "	 , 'TOTAL'  AS TIPO_CLIENTE"
	   			_sQuery += "	 , SL2.L2_TABELA AS TABELA"
	   			_sQuery += "	 , CASE WHEN SL2.L2_TABELA = 1 THEN 'Gôndola'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 2 THEN 'Caixa Fechada'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 3 THEN 'Associados e Funcionários'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 4 THEN 'Parceiros/Revenda/Eventos'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 5 THEN 'Festa de Comunidade/Feira Ponta de Estoque'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 6 THEN 'Representantes'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 7 THEN 'Representantes'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 8 THEN 'Tumelero'"
	   			_sQuery += "			WHEN SL2.L2_TABELA = 9 THEN 'Representantes'"
	   			_sQuery += "	   END AS DESCRICAO_TAB"
	   			_sQuery += "	 , SUM(SL2.L2_VLRITEM) AS VALOR"
	   			_sQuery += "	 , ROUND(SUM(SL2.L2_VLRITEM) / (SELECT SUM(L2_VLRITEM)" 
				_sQuery += "									 FROM SL2010 "
				_sQuery += "			   						WHERE D_E_L_E_T_ = ''"
				_sQuery += "   									  AND L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sQuery += "   									  AND L2_SERIE  != '999'"
				_sQuery += "   									  AND L2_DOC    != ''"
	   			_sQuery += "   									  AND L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "')*100,2) AS PERC "
				_sQuery += "  FROM SL2010 AS SL2"
				_sQuery += " WHERE SL2.D_E_L_E_T_ = ''"
				_sQuery += "   AND SL2.L2_DOC    != ''"
				_sQuery += "   AND SL2.L2_SERIE  != '999'"
				_sQuery += "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "   AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "GROUP BY SL2.L2_TABELA "
				_sQuery += "UNION ALL "
				_sQuery += "SELECT '##' AS FILIAL"
				_sQuery += "     , '####'  AS CUPOM"
				_sQuery += "  	 , '####'  AS SERIE"
				_sQuery += "	 , '####'  AS CLIENTE"
				_sQuery += "	 , 'TOTAL'  AS NOME"
				_sQuery += "	 , '####'  AS TIPO_CLIENTE"
				_sQuery += "	 , ''       AS TABELA"
				_sQuery += "	 , '## TOTAL GERAL' AS DESCRICAO_TAB"
				_sQuery += "	 , SUM(SL2.L2_VLRITEM) AS VALOR"
				_sQuery += "	 , '100.00' AS PERC"
				_sQuery += "  FROM SL2010 AS SL2"
				_sQuery += " WHERE SL2.D_E_L_E_T_ = ''"
				_sQuery += "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "   AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "   AND SL2.L2_DOC    != ''"
				_sQuery += "   AND SL2.L2_SERIE  != '999')"
				_sQuery += "SELECT *"
				_sQuery += "  FROM C"
				//u_showmemo( _sQuery )
	   			_aDados := U_Qry2Array(_sQuery)
				if len(_aDados) > 0 
					do while .t.
						_aCols = {}
						aadd (_aCols, { 1, "Filial"      		,  15, "@!"})
						aadd (_aCols, { 2, "Cupom"     	 		,  30, "@!"})
		    			aadd (_aCols, { 3, "Serie"       		,  15, "@!"})
		    			aadd (_aCols, { 4, "Cliente"     		,  20, "@!"})
		    			aadd (_aCols, { 5, "Nome"        		,  80, "@!"})
		    			aadd (_aCols, { 6, "Tipo Cliente"  		,  40, "@!"})
		    			aadd (_aCols, { 7, "Tabela"      		,  20, "@!"})
		    			aadd (_aCols, { 8, "Descrição Tabela" 	,  60, "@!"})
		    			aadd (_aCols, { 9, "Valor"       	  	,  60, "@E 999,999.99"})
		    			aadd (_aCols, {10, "Percentual"     	,  50, "@E 999.99%"})
						if mv_par01 == mv_par02
							_wperiodo = "Dia : " + dtoc(mv_par01)
						else
							_wperiodo = "Periodo de : " + dtoc(mv_par01) + " até " + dtoc (mv_par02) 											
						endif
						if mv_par03 == mv_par04
							_wfiliais = " - Filial : " + mv_par03
						else
							_wfiliais = " - Filiais de : " + mv_par03 + " até " + mv_par04 											
						endif
						if mv_par05 == 1
							_wopcao = 'Analitica '
						else
							_wopcao = 'Sintética '
						endif	
						 _wlinha = U_F3Array (_aDados, "Vendas Loja p/Tabelas de preço - " +_wopcao + _wperiodo + _wfiliais, _aCols, oMainWnd:nClientWidth - 50, NIL, "")
						if _wlinha = 0
							exit
						endif
					enddo
  				else
					msgalert("Não foram encontrados dados para consulta")
				endif
			else
				// se for opcao do resumo por data
				_sQuery = ""
				_sQuery += "WITH C AS ( SELECT dbo.VA_DTOC(SL2.L2_EMISSAO) AS DATA"
	   			_sQuery += "				 , SL2.L2_TABELA AS TABELA"
	   			_sQuery += "				 , CASE WHEN SL2.L2_TABELA = 1 THEN 'Gôndola'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 2 THEN 'Caixa Fechada'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 3 THEN 'Associados e Funcionários'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 4 THEN 'Parceiros/Revenda/Eventos'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 5 THEN 'Festa de Comunidade/Feira Ponta de Estoque'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 6 THEN 'Representantes'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 7 THEN 'Representantes'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 8 THEN 'Tumelero'"
	   			_sQuery += "						WHEN SL2.L2_TABELA = 9 THEN 'Representantes'"
	   			_sQuery += "				   END AS DESCRICAO_TAB"
	   			_sQuery += "				 , SUM(SL2.L2_VLRITEM) AS VALOR"
	   			_sQuery += "				 , ROUND(SUM(SL2.L2_VLRITEM) /(SELECT SUM(L2_VLRITEM)" 
				_sQuery += "												 FROM SL2010 "
				_sQuery += "			   									WHERE D_E_L_E_T_ = ''"
				_sQuery += "    		  									  AND L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sQuery += "   												  AND L2_DOC    != ''"
				_sQuery += "   												  AND L2_SERIE  != '999'"
				_sQuery += "				 								  AND L2_EMISSAO = SL2.L2_EMISSAO)*100,2) AS PERC_DAT"
				_sQuery += "				 , ROUND(SUM(SL2.L2_VLRITEM) /(SELECT SUM(L2_VLRITEM) "
				_sQuery += "												 FROM SL2010 "
				_sQuery += "			   									WHERE D_E_L_E_T_ = ''"
				_sQuery += "   												  AND L2_SERIE  != '999'"
				_sQuery += "    		  									  AND L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sQuery += "    		  									  AND L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
				_sQuery += "			     								  AND L2_DOC    != '')*100,2) AS PERC_TOT"
				_sQuery += "			 FROM SL2010 AS SL2"
				_sQuery += "		    WHERE SL2.D_E_L_E_T_ = ''"
				_sQuery += "    		  AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "    		  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "			  AND SL2.L2_DOC    != ''"
	   			_sQuery += "   			  AND SL2.L2_SERIE  != '999'"
				_sQuery += " GROUP BY SL2.L2_TABELA, SL2.L2_EMISSAO"
				_sQuery += " UNION ALL"
				_sQuery += " SELECT dbo.VA_DTOC(SL2.L2_EMISSAO) AS DATA"
				_sQuery += " 	  , 'T' AS TABELA"
				_sQuery += "	  , '## TOTAL' AS DESCRICAO_TAB"
				_sQuery += "      , SUM(SL2.L2_VLRITEM) AS VALOR"
				_sQuery += "	  , '100.00' AS PERC_DAT"
				_sQuery += "	  , ROUND(SUM(SL2.L2_VLRITEM) / (SELECT SUM(L2_VLRITEM)" 
				_sQuery += "							  		   FROM SL2010"
				_sQuery += "			   						  WHERE D_E_L_E_T_ = ''"
				_sQuery += "   										AND L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "   										AND L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "   										AND L2_SERIE  != '999'"
				_sQuery += "			     						AND L2_DOC    != '')*100,2) AS PERC_TOT"
				_sQuery += "  FROM SL2010 AS SL2"
				_sQuery += " WHERE SL2.D_E_L_E_T_ = ''"
				_sQuery += "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "   AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "   AND SL2.L2_DOC    != ''"
	   			_sQuery += "   AND SL2.L2_SERIE  != '999'"
				_sQuery += " GROUP BY SL2.L2_EMISSAO"
				_sQuery += " UNION ALL"
				_sQuery += " SELECT 'TOTAL' AS DATA"
				_sQuery += "	  , '#'     AS TABELA"
				_sQuery += "	  , '## TOTAL GERAL' AS DESCRICAO_TAB"
				_sQuery += "	  , SUM(SL2.L2_VLRITEM) AS VALOR"
				_sQuery += "	  , '100.00' AS PERC_DAT"
				_sQuery += "	  , '100.00' AS PERC_TOT"
				_sQuery += "   FROM SL2010 AS SL2"
				_sQuery += "  WHERE SL2.D_E_L_E_T_ = ''"
				_sQuery += "    AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   			_sQuery += "    AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   			_sQuery += "    AND SL2.L2_SERIE  != '999'"
	   			_sQuery += "	AND SL2.L2_DOC    != '')"
				_sQuery += " SELECT *"
				_sQuery += "   FROM C"
				_sQuery += " ORDER BY C.DATA, C.TABELA"
				//u_showmemo( _sQuery )
				_aDados := U_Qry2Array(_sQuery)
				if len(_aDados) > 0 
					do while .t.
						_aCols = {}
						aadd (_aCols, { 1, "Data"         		,  30, "@!"})
						aadd (_aCols, { 2, "Tabela"      		,  20, "@!"})
		    			aadd (_aCols, { 3, "Descrição Tabela" 	,  60, "@!"})
		    			aadd (_aCols, { 4, "Valor"       	  	,  60, "@E 999,999.99"})
		    			aadd (_aCols, { 5, "%Data"     	        ,  50, "@E 999.99%"})
		    			aadd (_aCols, { 6, "%Total"    	        ,  50, "@E 999.99%"})
						if mv_par01 == mv_par02
							_wperiodo = "Dia : " + dtoc(mv_par01)
						else
							_wperiodo = "Periodo de : " + dtoc(mv_par01) + " até " + dtoc (mv_par02) 											
						endif
						if mv_par03 == mv_par04
							_wfiliais = " - Filial : " + mv_par03
						else
							_wfiliais = " - Filiais de : " + mv_par03 + " até " + mv_par04 											
						endif
						_wopcao = 'Resumo por Data'
						 _wlinha = U_F3Array (_aDados, "Vendas Loja p/Tabelas de preço - " +_wopcao + _wperiodo + _wfiliais, _aCols, oMainWnd:nClientWidth - 50, NIL, "")
						if _wlinha = 0
							exit
						endif
					enddo
  				else
					msgalert("Não foram encontrados dados para consulta")
				endif
			endif	
		endif
	endif			
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de Venda de         ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data de Venda até        ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Loja de                  ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {04, "Loja até                 ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {05, "Consulta                 ?", "N", 1,  0,  "",   "   ", {"Analitica","Sintetica","Resumo p/Data"}, ""})
	
    
    U_ValPerg (cPerg, _aRegsPerg)
Return