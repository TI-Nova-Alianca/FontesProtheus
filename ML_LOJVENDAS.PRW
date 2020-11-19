//  Programa...: ML_LOJVENDAS
//  Autor......: Catia Cardoso
//  Data.......: 28/06/2018
//  Descricao..: VENDAS LOJAS - P/TIPO DE CLIENTE  
// 
//  Definiçoes das tabela enviadas pelo GIOVANI
//  01 - Preço Gôndola;
//  02 - Preço Caixa Fechada;
//  03 - Preço Associados e Funcionários;
//  04 - Preço Parceiros / Revenda / Eventos;
//  05 - Preço Festa de Comunidade / Feira Ponta de Estoque;
//  06 - Preço Promocional;
//  07 - Preço Representantes;
//  08 - Preço Tumelero;
//  09 - Preço Representantes;
//
//  Historico de alterações
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_LOJVENDAS()

	cPerg   := "ML_LOJVENDAS"
	
	if ! u_zzuvl ('083', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar estar rotina/relatório.")
		return
	endif
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 

			// gera array da temporaria para mostrar na tela
	   		_sQuery = ""
	   		_sQuery+= "SELECT 'VENDA NORMAL'      AS DESCRICAO"
     		_sQuery+= "		, ROUND(SUM(SL2.L2_VLRITEM),2) AS VALOR"
	 		_sQuery+= "		, ROUND((SUM(SL2.L2_VLRITEM) / ( SELECT SUM(SL1.L1_VLRTOT)"
		    _sQuery+= "  FROM SL1010 AS SL1"
		  	_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
		    _sQuery+= "	  AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery+= "   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		    _sQuery+= "   AND SL1.L1_SERIE IN ('001','002')"
			_sQuery+= "   AND SL1.L1_DOC    != '')*100),3) AS PER_TOT"
  			_sQuery+= "  FROM SL2010 AS SL2"
			_sQuery+= "		INNER JOIN SL1010 AS SL1"
			_sQuery+= "			ON (SL1.D_E_L_E_T_ = ''"
			_sQuery+= "				AND SL1.L1_FILIAL = SL2.L2_FILIAL"
			_sQuery+= "				AND SL1.L1_SERIE  = SL2.L2_SERIE"
			_sQuery+= "				AND SL1.L1_DOC    = SL2.L2_DOC"
			_sQuery+= "				AND SL1.L1_CONDPG != '997'"
			_sQuery+= "				AND SL1.L1_VACGC != ISNULL((SELECT TOP 1 SA2.A2_CGC"
			_sQuery+= "											  FROM SA2010 AS SA2"
			_sQuery+= "				  								INNER JOIN SZI010 AS SZI"
			_sQuery+= "													ON (SZI.D_E_L_E_T_ = ''"
			_sQuery+= "					    								AND SZI.ZI_TM    = '13'"
			_sQuery+= "														AND SZI.ZI_ASSOC = SA2.A2_COD)"
			_sQuery+= "			  								 WHERE SA2.A2_CGC = SL1.L1_VACGC"
			_sQuery+= "			    							   AND SA2.D_E_L_E_T_ = ''),1)   )"
			_sQuery+= "  WHERE SL2.D_E_L_E_T_ = ''"
   			_sQuery+= "	   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'" 
   			_sQuery+= "    AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   			_sQuery+= "    AND SL2.L2_SERIE IN ('001','002')"
   			_sQuery+= "    AND SL2.L2_DOC    != ''"
   			_sQuery+= "    AND SL2.L2_TABELA !='8'"
			_sQuery+= " UNION ALL "
			//-- VENDA TOTAL PARA FUNCIONARIOS POR PERIODO / FILIAL
			_sQuery+= " SELECT 'VENDA A FUNCIONARIOS'      AS DESCRICAO"
	 		_sQuery+= "      , ROUND(SUM(SL1.L1_VLRTOT),2) AS VALOR"
	 		_sQuery+= "      , ROUND((SUM(SL1.L1_VLRTOT) / ( SELECT SUM(SL1.L1_VLRTOT)"
		   	_sQuery+= "   									   FROM SL1010 AS SL1"
		  	_sQuery+= "  									  WHERE SL1.D_E_L_E_T_ = ''"
		    _sQuery+= "	   										AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery+= "    										AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery+= "    										AND SL1.L1_SERIE IN ('001','002')"
			_sQuery+= "    										AND SL1.L1_DOC    != '')*100),3) AS PER_TOT"
  			_sQuery+= "  FROM SL1010 AS SL1"
 			_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
   			_sQuery+= "   AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
   			_sQuery+= "   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   			_sQuery+= "   AND SL1.L1_SERIE IN ('001','002')"
   			_sQuery+= "   AND SL1.L1_DOC    != ''"
   			_sQuery+= "   AND SL1.L1_CONDPG = '997'"
			_sQuery+= " UNION ALL "
			//-- VENDA TOTAL PARA ASSOCIADOS POR PERIODO / FILIAL
			_sQuery+= "SELECT 'VENDA A ASSOCIADOS'        AS DESCRICAO"
	 		_sQuery+= "		, ROUND(SUM(SL1.L1_VLRTOT),2) AS VALOR"
	 		_sQuery+= "		, ROUND((SUM(SL1.L1_VLRTOT) / ( SELECT SUM(SL1.L1_VLRTOT)"
		   	_sQuery+= "  									  FROM SL1010 AS SL1"
		  	_sQuery+= " 									 WHERE SL1.D_E_L_E_T_ = ''"
		    _sQuery+= "										   AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery+= "										   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		    _sQuery+= "										   AND SL1.L1_SERIE IN ('001','002')"
			_sQuery+= "										   AND SL1.L1_DOC    != '')*100),3) AS PER_TOT"
  			_sQuery+= "  FROM SL1010 AS SL1"
 			_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
   			_sQuery+= "	  AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
   			_sQuery+= "	  AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   			_sQuery+= "	  AND SL1.L1_DOC    != ''"
   			_sQuery+= "	  AND SL1.L1_CONDPG != '997'"
   			_sQuery+= "	  AND SL1.L1_VACGC  != ''"
   			_sQuery+= "	  AND SL1.L1_VACGC   = (SELECT TOP 1 SA2.A2_CGC"
			_sQuery+= "					   	      FROM SA2010 AS SA2"
			_sQuery+= "				  				INNER JOIN SZI010 AS SZI"
			_sQuery+= "									ON (SZI.D_E_L_E_T_ = ''"
			_sQuery+= "					    				AND SZI.ZI_TM    = '13'"
			_sQuery+= "										AND SZI.ZI_ASSOC = SA2.A2_COD)"
			_sQuery+= "			  				 WHERE SA2.A2_CGC = SL1.L1_VACGC"
			_sQuery+= "			    			   AND SA2.D_E_L_E_T_ = '')"
			_sQuery+= " UNION ALL "
			//-- VENDAS PARA PARCEIROS (TUMELERO)
			_sQuery+= "SELECT 'VENDA A PARCEIROS'          AS DESCRICAO"
	 		_sQuery+= "		, ROUND(ISNULL(SUM(SL2.L2_VLRITEM),0),2)  AS VALOR"
	 		_sQuery+= "		, ROUND((SUM(SL2.L2_VLRITEM) / ( SELECT SUM(SL1.L1_VLRTOT)"
		   	_sQuery+= "  FROM SL1010 AS SL1"
		  	_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
		    _sQuery+= "	  AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery+= "   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		    _sQuery+= "   AND SL1.L1_SERIE IN ('001','002')"
			_sQuery+= "   AND SL1.L1_DOC    != '')*100),3) AS PER_TOT"
  			_sQuery+= "  FROM SL2010 AS SL2"
 			_sQuery+= " WHERE SL2.D_E_L_E_T_ = ''"
   			_sQuery+= "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
   			_sQuery+= "	  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   			_sQuery+= "	  AND SL2.L2_SERIE IN ('001','002')"
   			_sQuery+= "   AND SL2.L2_TABELA = '8'"
			_sQuery+= " UNION ALL "
			//--- VENDA TOTAL DO PERIODO / FILIAL
			_sQuery+= "SELECT 'VENDA TOTAL'      AS DESCRICAO"
	 		_sQuery+= "     , ROUND(SUM(SL1.L1_VLRTOT),2) AS VALOR"
	 		_sQuery+= "	    , ROUND((SUM(SL1.L1_VLRTOT) / ( SELECT SUM(SL1.L1_VLRTOT)"
		    _sQuery+= "  FROM SL1010 AS SL1"
		  	_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
			_sQuery+= "   AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery+= "   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		    _sQuery+= "   AND SL1.L1_SERIE IN ('001','002')"
			_sQuery+= "   AND SL1.L1_DOC    != '')*100),3) AS PER_TOT"
  			_sQuery+= "  FROM SL1010 AS SL1"
 			_sQuery+= " WHERE SL1.D_E_L_E_T_ = ''"
   			_sQuery+= "   AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
   			_sQuery+= "   AND SL1.L1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   			_sQuery+= "   AND SL1.L1_SERIE IN ('001','002')"
   			_sQuery+= "   AND SL1.L1_DOC    != ''"
	   		
	   		//u_showmemo (_sQuery)
	   		
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0 
				do while .t.
					_aCols = {}
					aadd (_aCols, {1, "Tipo de Venda"   , 100, "@!"})
					aadd (_aCols, {2, "Valor"        	,  40, "@E 9,999,999.99"})
	    			aadd (_aCols, {3, "Percentual"    	,  40, "@E 999.99"})
		
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
					 _wlinha = U_F3Array (_aDados, "Vendas Loja - P/Tipo de Cliente - " + _wperiodo + _wfiliais, _aCols, oMainWnd:nClientWidth - 50, NIL, "")
					if _wlinha = 0
						exit
					endif
				enddo				
			
			else
				u_help("Não foram encontrados dados para consulta")
			endif
						
		endif    		
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de Venda de    ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data de Venda até   ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Loja de                      ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {04, "Loja até                     ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
