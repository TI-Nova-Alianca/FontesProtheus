//  Programa...: ML_LOJTOP20
//  Autor......: Catia Cardoso
//  Data.......: 28/06/2018
//  Descricao..: VENDAS LOJAS - TOP 20  
// 
//  Historico de alterações
//  

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_LOJTOP20()
	Local i := 0
	
	cPerg   := "ML_LOJTOP"
	
	if ! u_zzuvl ('083', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina/relatório.")
		return
	endif
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 

		_lContinua = .T.
		
		// Controle de semaforo.
		_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SA1"))
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
		
		if _lContinua
			// drop table TMP_TOPLJ
			tcsqlexec ('DROP TABLE TMP_TOP')
			// contas a receber - gera a tabela TMP com os dados da filial 13
		   	_sSQL := " "
		   	_sSQL += " SELECT TOP 20 ROW_NUMBER() OVER(ORDER BY SL2.L2_FILIAL) AS RECNO" 
		   	_sSQL += "      , SL2.L2_FILIAL  AS LOJA13"
	     	_sSQL += "      , SL2.L2_PRODUTO        AS PRODUTO13
		 	_sSQL += "		, SB1.B1_DESC           AS DESCR13  
		 	_sSQL += "		, SUM(SL2.L2_QUANT)     AS QUANT13
		 	_sSQL += "		, SPACE(2)   AS LOJA10"
	     	_sSQL += "		, SPACE(15)  AS PRODUTO10"
		 	_sSQL += "		, SPACE(60)  AS DESCR10"
		 	_sSQL += "		, 0   AS QUANT10"
		 	_sSQL += "		, SPACE(2)  AS LOJA08"
	     	_sSQL += "		, SPACE(15) AS PRODUTO08"
		 	_sSQL += "		, SPACE(60) AS DESCR08"
		 	_sSQL += "		, 0   AS QUANT08"
		 	_sSQL += "		, SPACE(2)  AS LOJA03"
	     	_sSQL += "		, SPACE(15)  AS PRODUTO03"
		 	_sSQL += "		, SPACE(60)  AS DESCR03"
		 	_sSQL += "		, 0   AS QUANT03"
	  		_sSQL += "	 INTO TMP_TOP"
	  		_sSQL += "	 FROM SL2010 AS SL2"
			_sSQL += "		INNER JOIN SB1010 AS SB1"
			_sSQL += "			ON (SB1.D_E_L_E_T_ = ''"
			_sSQL += "				AND SB1.B1_COD = SL2.L2_PRODUTO)"
	 		_sSQL += "	WHERE SL2.D_E_L_E_T_ = ''"
	   		_sSQL += "	  AND SL2.L2_FILIAL = '13'"
	   		_sSQL += "	  AND SL2.L2_SERIE IN ('001','002')"
	   		_sSQL += "	  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sSQL += " GROUP BY SL2.L2_FILIAL, SL2.L2_PRODUTO, SB1.B1_DESC"
			_sSQL += " ORDER BY SUM(SL2.L2_QUANT) DESC" 
		   	if TCSQLExec (_sSQL) < 0
				u_help("Erro na criacao da tabela temporária - TMP_TOP")
	            return
	        endif 
	        // gera array com os dados da filial 10 e atualiza tabela temporaria
	        _sQuery := " "
		   	_sQuery += " SELECT TOP 20 SL2.L2_FILIAL
	     	_sQuery += "      , SL2.L2_PRODUTO      
		 	_sQuery += "		, SB1.B1_DESC           
		 	_sQuery += "		, SUM(SL2.L2_QUANT)   
		 	_sQuery += "	 FROM SL2010 AS SL2"
			_sQuery += "		INNER JOIN SB1010 AS SB1"
			_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += "				AND SB1.B1_COD = SL2.L2_PRODUTO)"
	 		_sQuery += "	WHERE SL2.D_E_L_E_T_ = ''"
	   		_sQuery += "	  AND SL2.L2_FILIAL = '10'"
	   		_sQuery += "	  AND SL2.L2_SERIE IN ('001','002')"
	   		_sQuery += "	  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY SL2.L2_FILIAL, SL2.L2_PRODUTO, SB1.B1_DESC"
			_sQuery += " ORDER BY SUM(SL2.L2_QUANT) DESC"
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0
				for i = 1 to len(_aDados)
					_sSQL = ""
					_sSQL += " UPDATE TMP_TOP"
					_sSQL += "	  SET LOJA10    = '" + ALLTRIM(_aDados[i,1]) + "'"
	     			_sSQL += "		, PRODUTO10 = '" + ALLTRIM(_aDados[i,2]) + "'"
		 			_sSQL += "		, DESCR10   = '" + ALLTRIM(_aDados[i,3]) + "'"
		 			_sSQL += "		, QUANT10   = "  + TRANSF(_aDados[i,4], "@ 99999")
		 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 99")
		 			if TCSQLExec (_sSQL) < 0
		 				u_help("Erro ao atualizar a tabela temporária - TMP_TOP (10)")
	            		return
	        		endif 
				next
			endif 
		   	// gera array com os dados da filial 08 e atualiza tabela temporaria
		   	_sQuery := " "
		   	_sQuery += " SELECT TOP 20 SL2.L2_FILIAL
	     	_sQuery += "      , SL2.L2_PRODUTO      
		 	_sQuery += "		, SB1.B1_DESC           
		 	_sQuery += "		, SUM(SL2.L2_QUANT)   
		 	_sQuery += "	 FROM SL2010 AS SL2"
			_sQuery += "		INNER JOIN SB1010 AS SB1"
			_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += "				AND SB1.B1_COD = SL2.L2_PRODUTO)"
	 		_sQuery += "	WHERE SL2.D_E_L_E_T_ = ''"
	   		_sQuery += "	  AND SL2.L2_FILIAL = '08'"
	   		_sQuery += "	  AND SL2.L2_SERIE IN ('001','002')"
	   		_sQuery += "	  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY SL2.L2_FILIAL, SL2.L2_PRODUTO, SB1.B1_DESC"
			_sQuery += " ORDER BY SUM(SL2.L2_QUANT) DESC"
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0
				for i = 1 to len(_aDados)
					_sSQL = ""
					_sSQL += " UPDATE TMP_TOP"
					_sSQL += "	  SET LOJA08    = '" + ALLTRIM(_aDados[i,1]) + "'"
	     			_sSQL += "		, PRODUTO08 = '" + ALLTRIM(_aDados[i,2]) + "'"
		 			_sSQL += "		, DESCR08   = '" + ALLTRIM(_aDados[i,3]) + "'"
		 			_sSQL += "		, QUANT08   = "  + TRANSF(_aDados[i,4], "@ 99999")
		 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 99")
		 			if TCSQLExec (_sSQL) < 0
		 				u_showmemo(_sSQL)
		 				u_help("Erro ao atualizar a tabela temporária - TMP_TOP (08)")
	            		return
	        		endif 
				next
			endif
	        // gera array com os dados da filial 03 e atualiza tabela temporaria
	        _sQuery := " "
		   	_sQuery += " SELECT TOP 20 SL2.L2_FILIAL
	     	_sQuery += "      , SL2.L2_PRODUTO      
		 	_sQuery += "		, SB1.B1_DESC           
		 	_sQuery += "		, SUM(SL2.L2_QUANT)   
		 	_sQuery += "	 FROM SL2010 AS SL2"
			_sQuery += "		INNER JOIN SB1010 AS SB1"
			_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += "				AND SB1.B1_COD = SL2.L2_PRODUTO)"
	 		_sQuery += "	WHERE SL2.D_E_L_E_T_ = ''"
	   		_sQuery += "	  AND SL2.L2_FILIAL = '03'"
	   		_sQuery += "	  AND SL2.L2_SERIE IN ('001','002')"
	   		_sQuery += "	  AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += " GROUP BY SL2.L2_FILIAL, SL2.L2_PRODUTO, SB1.B1_DESC"
			_sQuery += " ORDER BY SUM(SL2.L2_QUANT) DESC"
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0
				for i = 1 to len(_aDados)
					_sSQL = ""
					_sSQL += " UPDATE TMP_TOP"
					_sSQL += "	  SET LOJA03    = '" + ALLTRIM(_aDados[i,1]) + "'"
	     			_sSQL += "		, PRODUTO03 = '" + ALLTRIM(_aDados[i,2]) + "'"
		 			_sSQL += "		, DESCR03   = '" + ALLTRIM(_aDados[i,3]) + "'"
		 			_sSQL += "		, QUANT03   = "  + TRANSF(_aDados[i,4], "@ 99999")
		 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 99")
		 			if TCSQLExec (_sSQL) < 0
		 				u_help("Erro ao atualizar a tabela temporária - TMP_TOP (03)")
	            		return
	        		endif 
				next
			endif
			// gera array da temporaria para mostrar na tela
	   		_sQuery = ''
	   		_sQuery+= 'SELECT *'
	   		_sQuery+= '  FROM TMP_TOP'
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0 
				do while .t.
					_aCols = {}
					aadd (_aCols, {1, "Ranking"     ,  10, "@!"})
					// filial 13
	    			aadd (_aCols, {2, "Loja"        ,  10, "@!"})
	    			aadd (_aCols, {3, "Produto"    	,  20, "@!"})
	    			aadd (_aCols, {4, "Descricao"   ,  70, "@!"})
	    			aadd (_aCols, {5, "Quantidade"  ,  30, "@E 999999"})
					// filial 10
					aadd (_aCols, {6, "Loja"        ,  10, "@!"})
	    			aadd (_aCols, {7, "Produto"    	,  20, "@!"})
	    			aadd (_aCols, {8, "Descricao"   ,  70, "@!"})
	    			aadd (_aCols, {9, "Quantidade"  ,  30, "@E 9999999"})
	    			// filial 08
	    			aadd (_aCols, {10, "Loja"       ,  10, "@!"})
	    			aadd (_aCols, {11, "Produto"   	,  20, "@!"})
	    			aadd (_aCols, {12, "Descricao"  ,  70, "@!"})
	    			aadd (_aCols, {13, "Quantidade" ,  30, "@E 9999999"})
	    			// filial 03
	    			aadd (_aCols, {14, "Loja"       ,  10, "@!"})
	    			aadd (_aCols, {15, "Produto"   	,  20, "@!"})
	    			aadd (_aCols, {16, "Descricao"  ,  70, "@!"})
	    			aadd (_aCols, {17, "Quantidade" ,  30, "@E 9999999"})
		
					if mv_par01 == mv_par02
						_wperiodo = "Dia : " + dtoc (mv_par01)
					else
						_wperiodo = "Periodo de : " + dtoc (mv_par01) + " até " + dtoc (mv_par02) 											
					endif
					 _wlinha = U_F3Array (_aDados, "Vendas - Produtos mais Vendidos p/Loja - " + _wperiodo, _aCols, oMainWnd:nClientWidth - 50, NIL, "")
					if _wlinha = 0
						exit
					endif
				enddo				
			
			else
				u_help("Não foram encontrados dados para consulta")
			endif
						
		endif    		
		
		// Libera semaforo
		U_Semaforo (_nLock)
	endif	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de Venda de    ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data de Venda até   ?", "D", 8, 0,  "",   "   ", {},  ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
