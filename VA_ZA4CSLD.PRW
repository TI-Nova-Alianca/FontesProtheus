//  Programa...: VA_ZA4CSLD
//  Autor......: Catia Cardoso
//  Data.......: 08/05/2015
//  Descricao..: Controle de Verbas - Consulta Saldos a Bonificar 
//
//  28/05/2015 - Catia - parametro novo para ver se lista os com saldo zerado ou nao.
//  15/06/2015 - Catia - alterado status de utilizacao - testando pelo saldo da verba
//  03/05/2018 - Catia - incluido campo de valor zerado considerado no saldo

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ZA4CSLD()

	cPerg   := "ZA4CSLD"
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.) 
	
		_sQuery := ""
		_sQuery += " 	WITH C AS (SELECT SA1B.A1_VACBASE"
		_sQuery += " 		,SA1B.A1_VALBASE"
		_sQuery += " 		,SUM(ZA4.ZA4_VLR) AS VLR_LIB"
		_sQuery += " 		,ISNULL((SELECT"
		_sQuery += " 				ROUND(SUM(ZA5.ZA5_VLR), 2)"
		_sQuery += " 			FROM ZA5010 ZA5"
		_sQuery += " 			INNER JOIN SA1010 AS SA1"
		_sQuery += " 				ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 					AND SA1.A1_COD  = ZA5.ZA5_CLI"
		_sQuery += " 					AND SA1.A1_LOJA = ZA5.ZA5_LOJA"
		_sQuery += " 					AND SA1.A1_VACBASE = SA1B.A1_VACBASE"
		_sQuery += " 					AND SA1.A1_VALBASE = SA1B.A1_VALBASE)"
		_sQuery += " 			WHERE ZA5.D_E_L_E_T_ = ''"
		_sQuery += " 			  AND ZA5.ZA5_TLIB IN ('1'))"
		_sQuery += " 		, 0) AS VLR_UTIL"
		_sQuery += " 		,ISNULL((SELECT"
		_sQuery += " 				ROUND(SUM(ZA5.ZA5_VLR), 2)"
		_sQuery += " 			FROM ZA5010 ZA5"
		_sQuery += " 			INNER JOIN SA1010 AS SA1"
		_sQuery += " 				ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 					AND SA1.A1_COD  = ZA5.ZA5_CLI"
		_sQuery += " 					AND SA1.A1_LOJA = ZA5.ZA5_LOJA"
		_sQuery += " 					AND SA1.A1_VACBASE = SA1B.A1_VACBASE"
		_sQuery += " 					AND SA1.A1_VALBASE = SA1B.A1_VALBASE)"
		_sQuery += " 			WHERE ZA5.D_E_L_E_T_ = ''"
		_sQuery += " 			  AND ZA5.ZA5_TLIB IN ('9'))"
		_sQuery += " 		, 0) AS VLR_ZERADO"
		_sQuery += " 		, ROUND (SUM(ZA4.ZA4_VLR) - ISNULL((SELECT"
		_sQuery += " 				ROUND(SUM(ZA5.ZA5_VLR), 2)"
		_sQuery += " 			FROM ZA5010 ZA5"
		_sQuery += " 			INNER JOIN SA1010 AS SA1"
		_sQuery += " 				ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 					AND SA1.A1_COD  = ZA5.ZA5_CLI"
		_sQuery += " 					AND SA1.A1_LOJA = ZA5.ZA5_LOJA"
		_sQuery += " 					AND SA1.A1_VACBASE = SA1B.A1_VACBASE"
		_sQuery += " 					AND SA1.A1_VALBASE = SA1B.A1_VALBASE)"
		_sQuery += " 			WHERE ZA5.D_E_L_E_T_ = ''"
		_sQuery += " 			  AND ZA5.ZA5_TLIB IN ('1','9'))"
		_sQuery += " 		, 0)"
		_sQuery += " 		  , 2) AS VLR_SLD"
		_sQuery += " 	FROM ZA4010 AS ZA4"
		_sQuery += " 	INNER JOIN SA1010 AS SA1B"
		_sQuery += " 		ON (SA1B.D_E_L_E_T_ = ''"
		_sQuery += " 		AND SA1B.A1_COD     = ZA4.ZA4_CLI"
		_sQuery += " 		AND SA1B.A1_LOJA    = ZA4.ZA4_LOJA)"
		_sQuery += " 	WHERE ZA4.D_E_L_E_T_ = ''"
		_sQuery += " 	AND ZA4.ZA4_CLI BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
		_sQuery += " 	AND ZA4.ZA4_TLIB = '1'"
		_sQuery += " 	GROUP BY	SA1B.A1_VACBASE"
		_sQuery += " 				,SA1B.A1_VALBASE)"
		_sQuery += " 	SELECT C.A1_VACBASE, C.A1_VALBASE"
		_sQuery += " 	 , SA1.A1_NOME"
		_sQuery += " 	 , C.VLR_LIB"
		_sQuery += " 	 , C.VLR_UTIL"
		_sQuery += " 	 , C.VLR_ZERADO"
		_sQuery += " 	 , C.VLR_SLD"
		_sQuery += " 	FROM C"
		_sQuery += " 	INNER JOIN SA1010 AS SA1"
		_sQuery += " 		ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += " 			AND SA1.A1_COD  = C.A1_VACBASE"
		_sQuery += " 			AND SA1.A1_LOJA = C.A1_VALBASE)"
		if mv_par03 = 1
			_sQuery += " WHERE C.VLR_SLD <> 0"
		endif			
		//u_showmemo (_sQuery)
			
		_aDados := U_Qry2Array(_sQuery)
		if len(_aDados) > 0
    	
    		_aCols = {}
    	
	    	aadd (_aCols, {01, "Cliente"        	,  50,  "@!"})
	    	aadd (_aCols, {02, "Loja"           	,  20,  "@!"})
	    	aadd (_aCols, {03, "Razão Social"   	, 200,  "@!"})
	    	aadd (_aCols, {04, "Total Liberado"	    ,  80,  "@E 999,999,999,999.99"})
	    	aadd (_aCols, {05, "Total Utilizado"	,  80,  "@E 999,999,999,999.99"})
	    	aadd (_aCols, {06, "Total Zerado"	    ,  80,  "@E 999,999,999,999.99"})
	    	aadd (_aCols, {07, "Saldo"       	    ,  80,  "@E 999,999,999,999.99"})
	    	
	    	_wlinha = U_F3Array (_aDados, "Consulta Saldos a Bonificar", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
	    	
	    	if _wlinha == 1
		    
				// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
		    	_sQuery := ""
		    	_sQuery += "SELECT ZA4.ZA4_NUM"
		     	_sQuery += "	 , ZA4.ZA4_DGER"
			 	_sQuery += "	 , ZA4.ZA4_CLI"
			 	_sQuery += "	 , ZA4.ZA4_LOJA"
			 	_sQuery += "	 , SA1.A1_NOME"
			 	_sQuery += "	 , ZA4.ZA4_CONT"
			 	_sQuery += "	 , ZA4.ZA4_SEQCON"
			 	_sQuery += "	 , ZA4.ZA4_COD"
			 	_sQuery += "	 , ZA3.ZA3_DES"
			 	_sQuery += "	 , ZA4.ZA4_VLR"
				_sQuery += " 	 , ZA4.ZA4_DLIB"
				_sQuery += " 	 , ZA4.ZA4_ULIB"
				_sQuery += " 	 , CASE WHEN ZA4.ZA4_SUTL='0'  THEN 'NAO'"
				_sQuery += " 	        WHEN ZA4.ZA4_SUTL='1'  THEN 'PARCIAL'"
				_sQuery += " 	        WHEN ZA4.ZA4_SUTL='2'  THEN 'SIM'"
				_sQuery += "       ELSE '***' END"
				_sQuery += "     , ZA4.ZA4_VLR - ISNULL( ( SELECT SUM(ZA5_VLR)"
		  		_sQuery += "        			   		    FROM ZA5010"
		 		_sQuery += "       				  		   WHERE D_E_L_E_T_ = ''"
		   		_sQuery += "         						 AND ZA5_NUM    = ZA4.ZA4_NUM) ,0)"
				_sQuery += " FROM ZA4010 AS ZA4"
				_sQuery += " 	INNER JOIN SA1010 AS SA1"
				_sQuery += "    	ON (SA1.D_E_L_E_T_  = ''"
				_sQuery += "        	AND SA1.A1_COD  = ZA4.ZA4_CLI"
				_sQuery += " 	   		AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
				_sQuery += " 	INNER JOIN ZA3010 AS ZA3"
				_sQuery += "    	ON (ZA3.D_E_L_E_T_  = ''"
				_sQuery += "        	AND ZA3.ZA3_COD  = ZA4.ZA4_COD )"
				_sQuery += "WHERE ZA4.D_E_L_E_T_ = ''
		 		_sQuery += "  AND ZA4.ZA4_CLI  =  '" + _aDados[_wlinha,1] + "'"
		 		_sQuery += "  AND ZA4.ZA4_LOJA =  '" + _aDados[_wlinha,2] + "'"
		    	_sQuery += "  AND ZA4.ZA4_TLIB = '1'"
			
				_aDados1 := U_Qry2Array(_sQuery)
	    		
				_aCols = {}
		
		    	aadd (_aCols, {01, "Num.Verba"       	,  10,  "@!"})
		    	aadd (_aCols, {02, "Emissao"        	,  30,  "@D"})
		    	aadd (_aCols, {03, "Cliente"        	,  30,  "@!"})
		    	aadd (_aCols, {04, "Loja"           	,  10,  "@!"})
		    	aadd (_aCols, {05, "Razão Social"   	, 140,  "@!"})
		    	aadd (_aCols, {06, "Contrato"      	  	,  25,  "@!"})
		    	aadd (_aCols, {07, "Seq" 	        	,  10,  "@!"})
		    	aadd (_aCols, {08, "Verba"       	  	,  20,  "@!"})
		    	aadd (_aCols, {09, "Descricao"         	,  90,  "@!"})
		    	aadd (_aCols, {10, "Valor"       	    ,  50,  "@E 999,999.99"})
		    	aadd (_aCols, {11, "Data Liberacao"    	,  20,  "@D"})
		    	aadd (_aCols, {12, "Usuario Liberacao"  ,  60,  "@!"})
		    	aadd (_aCols, {13, "Utilizada"          ,  30,  "@!"})
		    	aadd (_aCols, {14, "Saldo"       	    ,  50,  "@E 999,999.99"})
		    	
	    		U_F3Array (_aDados1, "Detalhamento Verbas Bonificadas", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			endif	    			    	
	    	
	    else
			msgalert("Não foram encontrados dados para consulta")
		endif			
	endif
	
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Cliente de                  ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate                 ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Lista Saldo Zero            ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return