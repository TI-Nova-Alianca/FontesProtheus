//  Programa...: ML_VCRPG
//  Autor......: Catia Cardoso
//  Data.......: 01/03/2016
//  Descricao..: Vencidos e a Vencer - P/PRAZO - Receber e a Pagar 
// 
//  Historico de alterações
//  
//  10/03/2016 - Catia - Alterado para que considere titulos emitidos ate o dia anterior
//  10/03/2016 - Catia - Alterado para que nos titulos a vencer, deixe fora o dia
//  19/04/2018 - Catia/Robert - foi deletado o indice no SE5, muito provavelmente vai dar erro nesse relatorio mas ate onde vimos não eh mais usado
//
// ---------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_VCRPG()

	_lContinua = .T.
	
	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SE1"))
	if _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
		_lContinua = .F.
	endif
	
	if _lContinua
		// drop table TMP_SE1
		tcsqlexec ('DROP TABLE TMP_SE1')
		// contas a receber - tabela temporaria
	   	_sSQL := " "
	   	_sSQL += " SELECT E1_VENCREA     AS DATA"
     	_sSQL += "      , SUM(E1_SALDO)  AS VALOR"
	 	_sSQL += "      , COUNT(E1_NUM)  AS QTDE"
  		_sSQL += "   INTO TMP_SE1"	
  		_sSQL += "   FROM SE1010"
 		_sSQL += "  WHERE D_E_L_E_T_ = ''"
   		_sSQL += "    AND E1_FILIAL = '01'"
   		_sSQL += "    AND E1_SALDO  > 0"
   		_sSQL += "    AND E1_TIPO  != 'NCC'"
   		_sSQL += "    AND E1_TIPO  != 'RA'"
   		_sSQL += "    AND E1_EMISSAO BETWEEN '1980101' AND dbo.VA_DatetimeToVarchar(getDATE()-1)"  // titulos emitidos ate ontem
   		_sSQL += "  GROUP BY E1_VENCREA"  
		if TCSQLExec (_sSQL) < 0
			u_help("Erro na criacao da tabela temporária - SE1")
            return
        endif 
        _sSQL := " "
        // drop table TMP_SE2
        tcsqlexec ('DROP TABLE TMP_SE2')
        // contas a pagar - tabela temporaria
	   	_sSQL := " "
	   	_sSQL += " SELECT E2_VENCREA    AS DATA"
     	_sSQL += "      , SUM(E2_SALDO) AS VALOR"
	 	_sSQL += "      , COUNT(E2_NUM) AS QTDE"
	 	_sSQL += "   INTO TMP_SE2"
  		_sSQL += "   FROM SE2010"
  		_sSQL += "  WHERE D_E_L_E_T_ = ''"
   		_sSQL += "    AND E2_FILIAL  = '01'"
   		_sSQL += "    AND E2_SALDO   > 0"
   		_sSQL += "    AND E2_TIPO   != 'PA'"
   		_sSQL += "    AND E2_TIPO   != 'NDF'"
   		_sSQL += "    AND E2_EMISSAO BETWEEN '1980101' AND dbo.VA_DatetimeToVarchar(getDATE()-1)" // titulos emitidos ate ontem
   		_sSQL += " GROUP BY E2_VENCREA"
		if TCSQLExec (_sSQL) < 0
			u_help("Erro na criacao da tabela temporária - SE2")
            return
        endif 
        
		// monta query 
   		_sQuery := " "
	   	// contas a receber - vencidos
	   	_sQuery += " WITH C AS (
	   	_sQuery += " SELECT '1A' AS ORDEM" 
	   	_sQuery += "     , 'VENCIDOS:  ATE 30DD' AS DESCR"
	   	_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "     , 0 AS VLR2"
	    _sQuery += "     , 0 AS QTDE2"
	  	_sQuery += "  FROM TMP_SE1"
	 	_sQuery += " WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-30) AND dbo.VA_DatetimeToVarchar(getDATE()-1)"
		
		_sQuery += " UNION ALL"
	    _sQuery += " SELECT '1B' AS ORDEM" 
	   	_sQuery += "      , '            DE 31DD A  60DD' AS DESCR"
	   	_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-60) AND dbo.VA_DatetimeToVarchar(getDATE()-31)"
		
        _sQuery += " UNION ALL"
		_sQuery += " SELECT '1C' AS ORDEM" 
	   	_sQuery += "      , '            DE 61DD A  90DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-90) AND dbo.VA_DatetimeToVarchar(getDATE()-61)"
		
        _sQuery += " UNION ALL"
		_sQuery += " SELECT '1D' AS ORDEM" 
	   	_sQuery += "      , '            DE 91DD A 180DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-180) AND dbo.VA_DatetimeToVarchar(getDATE()-91)"
		
		_sQuery += " UNION ALL"
       	_sQuery += " SELECT '1E' AS ORDEM" 
	   	_sQuery += "      , '            DE 181DD A 365DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-365) AND dbo.VA_DatetimeToVarchar(getDATE()-181)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1F' AS ORDEM" 
	   	_sQuery += "      , '            MAIS  DE  365DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA < dbo.VA_DatetimeToVarchar(getDATE()-366)"
		
		_sQuery += " UNION ALL"
		    _sQuery += " SELECT '1G' AS ORDEM" 
	   	_sQuery += "      , 'TOTAL VENCIDOS' AS DESCR"
	    _sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA < dbo.VA_DatetimeToVarchar(getDATE())"
		_sQuery += " UNION ALL"
		
        // contas a receber a vencer
		_sQuery += " SELECT '1H' AS ORDEM" 
	   	_sQuery += "      , 'A VENCER :  ATE 365DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()+1) AND dbo.VA_DatetimeToVarchar(getDATE()+365)"
		
        
        _sQuery += " UNION ALL"
		_sQuery += " SELECT '1I' AS ORDEM" 
	   	_sQuery += "      , '            MAIS  DE  365DD' AS DESCR"
		_sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA > dbo.VA_DatetimeToVarchar(getDATE()+365)"
		

        _sQuery += " UNION ALL"
		_sQuery += " SELECT '1J' AS ORDEM" 
	   	_sQuery += "      , 'TOTAL A VENCER' AS DESCR"
	    _sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	_sQuery += "  WHERE DATA >= dbo.VA_DatetimeToVarchar(getDATE())"
	 	
        _sQuery += " UNION ALL"
		_sQuery += " SELECT '1K' AS ORDEM" 
	   	_sQuery += "      , 'TOTAL GERAL' AS DESCR"
	    _sQuery += "     , SUM(VALOR) AS VLR1"
	    _sQuery += "     , SUM(QTDE) AS QTDE1"
	    _sQuery += "      , 0 AS VLR2"
	    _sQuery += "      , 0 AS QTDE2"
	  	_sQuery += "   FROM TMP_SE1"
	 	
	   	// contas a pagar
	   	// vencidos
	   	_sQuery += " UNION ALL"
	   	_sQuery += " SELECT '1A' AS ORDEM" 
	   	_sQuery += "     , 'VENCIDOS:  ATE 30DD' AS DESCR"
	   	_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "  FROM TMP_SE2"
	 	_sQuery += " WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-30) AND dbo.VA_DatetimeToVarchar(getDATE()-1)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1B' AS ORDEM" 
	   	_sQuery += "     , '            DE 31DD A  60DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-60) AND dbo.VA_DatetimeToVarchar(getDATE()-31)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1C' AS ORDEM" 
	   	_sQuery += "     , '            DE 61DD A  90DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-90) AND dbo.VA_DatetimeToVarchar(getDATE()-61)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1D' AS ORDEM" 
	   	_sQuery += "     , '            DE 91DD A 180DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()-180) AND dbo.VA_DatetimeToVarchar(getDATE()-91)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1E' AS ORDEM" 
	   	_sQuery += "     , '            MAIS  DE  365DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA < dbo.VA_DatetimeToVarchar(getDATE()-366)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1F' AS ORDEM" 
	   	_sQuery += "     , 'TOTAL VENCIDOS' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA < dbo.VA_DatetimeToVarchar(getDATE())"
		
		// A vencer 
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1G' AS ORDEM" 
	   	_sQuery += "     , 'A VENCER :  ATE 30DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()+1) AND dbo.VA_DatetimeToVarchar(getDATE()+30)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1H' AS ORDEM" 
	   	_sQuery += "     , '            DE 31DD A  60DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()+31) AND dbo.VA_DatetimeToVarchar(getDATE()+60)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1I' AS ORDEM" 
	   	_sQuery += "     , '            DE 61DD A  90DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()+61) AND dbo.VA_DatetimeToVarchar(getDATE()+90)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1J' AS ORDEM" 
	   	_sQuery += "     ,'            DE 91DD A 180DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA BETWEEN dbo.VA_DatetimeToVarchar(getDATE()+91) AND dbo.VA_DatetimeToVarchar(getDATE()+180)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1K' AS ORDEM" 
	   	_sQuery += "     , '            MAIS  DE  365DD' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA > dbo.VA_DatetimeToVarchar(getDATE()+365)"
		
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1L' AS ORDEM" 
	   	_sQuery += "     , 'TOTAL A VENCER' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += "  WHERE DATA >= dbo.VA_DatetimeToVarchar(getDATE())"
	 	
		_sQuery += " UNION ALL"
		_sQuery += " SELECT '1M' AS ORDEM" 
	   	_sQuery += "     , 'TOTAL GERAL' AS DESCR"
		_sQuery += "     , 0 AS VLR1"
	    _sQuery += "     , 0 AS QTDE1"
	  	_sQuery += "     , SUM(VALOR) AS VLR2"
	    _sQuery += "     , SUM(QTDE) AS QTDE2"
	    _sQuery += "   FROM TMP_SE2"
	 	_sQuery += " ) "
	   	_sQuery += " SELECT C.DESCR      AS DESCR"
	    _sQuery += "      , SUM(C.VLR1)  AS VLR1"
	  	_sQuery += "	  , SUM(C.QTDE1) AS QTDE1"
	  	_sQuery += "      , SUM(C.VLR2)  AS VLR2"
	  	_sQuery += "      , SUM(C.QTDE2) AS QTDE2"
	  	_sQuery += "      , C.ORDEM      AS ORDEM"
	  	_sQuery += " FROM C"
	    _sQuery += " GROUP BY C.DESCR, C.ORDEM"
	    _sQuery += " ORDER BY C.ORDEM
    
   		//u_showmemo(_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
		if len(_aDados) > 0 
			do while .t.
				_aCols = {}
	
    			aadd (_aCols, {1, "Descricao"       	   ,  120, "@!"})
    			aadd (_aCols, {2, "Receber"    			   ,   80, "@E 99,999,999,999.99"})
    			aadd (_aCols, {3, ""      			       ,   30, "@E 99999"})
    			aadd (_aCols, {4, "Pagar"    			   ,   80, "@E 99,999,999,999.99"})
    			aadd (_aCols, {5, ""      	               ,   30, "@E 99999"})
	
				_wlinha = U_F3Array (_aDados, "Vencidos e a Vencer", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
	
Return
