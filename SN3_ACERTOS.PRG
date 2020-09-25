// Programa...: SN3_ACERTOS
// Autor......: Catia Cardoso
// Data.......: 11/04/2019
// Descricao..: acerta tabelas do ativo quando cai o processo no meio de um calculo ou descalculo  
//
// Historico de alteracoes:
// 17/06/2019 - Catia - Continuidade aos acertos da SN3

#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function SN3_ACERTOS()
	local i	:= 0
	local T := 0

	_lRet = U_MsgNoYes ("Confirma acerto de saldos tabela SN3 valor de depreciacao acumulada com base na tabela SN4 ?")
	
	if _lRet = .F.
		return
	else
	
		FOR T = 1 TO 4
		 	DO CASE
		 	   CASE T = 1
		 	   		_WTPSLD = '10'
		 	   		_WOCORR = '20'
		 	   	CASE T = 2
		 	   		_WTPSLD = '12'
		 	   		_WOCORR = '20'
		 	   	CASE T = 3	
		 	   		_WTPSLD = '01'
		 	   		_WOCORR = '06'
		 	   	 CASE T = 4
		 	   		_WTPSLD = '02'
		 	   		_WOCORR = '06'	
		 	ENDCASE
		 	
		 	u_help("Processa Tipo SALDO :" + _WTPSLD)
		 	
	    	_sSQL := ""
			_sSQL += "WITH C AS ("
			_sSQL += "	SELECT SN1.N1_FILIAL" 
			_sSQL += "			, SN1.N1_CBASE"
			_sSQL += "			, SN1.N1_ITEM"
			_sSQL += "			, SN3.N3_FIMDEPR AS DT_FIM_DEPR"
			_sSQL += "			, SN1.N1_BAIXA   AS DT_BAIXA"
			_sSQL += "			, (SELECT TOP 1 SN4D.N4_VLROC1"
		  	_sSQL += "	  			 FROM SN4010 AS SN4D"
	        _sSQL += " 	 			WHERE SN4D.D_E_L_E_T_ = ''"
	        _sSQL += "     			  AND SN4D.N4_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "     			  AND SN4D.N4_OCORR   = '" + _WOCORR + "'"
			_sSQL += "     			  AND SN4D.N4_FILIAL  = SN3.N3_FILIAL"
			_sSQL += "     			  AND SN4D.N4_ITEM    = SN3.N3_ITEM"
			_sSQL += "     			  AND SN4D.N4_CBASE   = SN3.N3_CBASE"
			_sSQL += " 				ORDER BY SN4D.N4_DATA DESC  ) AS VLR_DEPR_MENSAL"
			_sSQL += "			, SN3.N3_VRDACM1 AS VLR_SN3"
			_sSQL += "			, (SELECT ROUND(SUM( SN4D.N4_VLROC1),2)"
			_sSQL += "  			 FROM SN4010 AS SN4D"
			_sSQL += "			    WHERE SN4D.N4_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "   			  AND SN4D.D_E_L_E_T_ = ''"
			_sSQL += "   			  AND SN4D.N4_FILIAL  = SN3.N3_FILIAL"
			_sSQL += "   			  AND SN4D.N4_OCORR   = '" + _WOCORR + "'"
			_sSQL += "   			  AND SN4D.N4_TIPOCNT = '4'"
			_sSQL += "   			  AND SN4D.N4_ITEM    = SN3.N3_ITEM"
			_sSQL += "   			  AND SN4D.N4_CBASE   = SN3.N3_CBASE) AS VLR_SN4"
			_sSQL += "	FROM SN3010 AS SN3"
			_sSQL += "		INNER JOIN SN1010 AS SN1"
			_sSQL += "			ON (SN1.D_E_L_E_T_ = ''"
			_sSQL += "    			AND SN1.N1_FILIAL = SN3.N3_FILIAL"
			_sSQL += "				AND SN1.N1_CBASE  = SN3.N3_CBASE"
			_sSQL += "				AND SN1.N1_ITEM   = SN3.N3_ITEM)"
			_sSQL += " WHERE SN3.D_E_L_E_T_ = ''"
			_sSQL += "   AND SN3.N3_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "   )"
			_sSQL += " SELECT C.N1_FILIAL, C.N1_CBASE, C.N1_ITEM"
			_sSQL += "		, C.VLR_DEPR_MENSAL"
			_sSQL += "		, C.VLR_SN3, C.VLR_SN4"
			_sSQL += "		, ROUND(C.VLR_SN3-C.VLR_SN4,2) AS DIFERENCA"
			_sSQL += "		, CASE WHEN C.VLR_DEPR_MENSAL > 0 THEN ROUND((VLR_SN3-C.VLR_SN4),2) / C.VLR_DEPR_MENSAL"
			_sSQL += "		  ELSE 0 END  AS MESES"
			_sSQL += "	FROM C"
			_sSQL += "	WHERE ROUND(C.VLR_SN3,2) <> ROUND(C.VLR_SN4,2)"
			_sSQL += "	  AND ( SELECT COUNT(SN3U.N3_CBASE)"
			_sSQL += "   		  FROM SN3010 AS SN3U"
	        _sSQL += "  		 WHERE SN3U.D_E_L_E_T_ = ''"
			_sSQL += "    		   AND SN3U.N3_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "    		   AND SN3U.N3_CBASE   = C.N1_CBASE ) = 1"
			_sSQL += "	  AND C.DT_FIM_DEPR = ''"
			_sSQL += "	  AND C.DT_BAIXA = ''"
			_sSQL += "	  AND C.VLR_DEPR_MENSAL > 0 "
			_sSQL += "  ORDER BY C.N1_CBASE, C.N1_ITEM, C.N1_FILIAL"
	
	   		_aAcertos := U_Qry2Array(_sSQL)
			if len(_aAcertos) > 0
				for i=1 to len(_aAcertos)
		    		_sSQL := ""
		    		_sSQL += " UPDATE SN3010"
		    		_sSQL += "    SET N3_VRDACM1 = " + cvaltochar( _aAcertos[i,6] )
		    		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		    		_sSQL += "    AND N3_FILIAL  = '" + _aAcertos[i,1] + "'"
		    		_sSQL += "    AND N3_CBASE   = '" + _aAcertos[i,2] + "'"
		    		_sSQL += "    AND N3_ITEM    = '" + _aAcertos[i,3] + "'"
		    		_sSQL += "    AND N3_TIPO    = '" + _WTPSLD + "'"
		    		if TCSQLExec (_sSQL) < 0
		    			u_help ("Erro ao executar UPDATE tabela SN3. Comunique a TI")
		    			return
		    		endif
			    next
			endif
			// -- trata 100% depreciados
			_sSQL := ""
			_sSQL += "WITH C AS ("
			_sSQL += "	SELECT SN1.N1_FILIAL" 
			_sSQL += "			, SN1.N1_CBASE"
			_sSQL += "			, SN1.N1_ITEM"
			_sSQL += "			, SN3.N3_FIMDEPR AS DT_FIM_DEPR"
			_sSQL += "			, SN1.N1_BAIXA   AS DT_BAIXA"
			_sSQL += "			, (SELECT TOP 1 SN4D.N4_VLROC1"
		  	_sSQL += "	  			 FROM SN4010 AS SN4D"
	        _sSQL += " 	 			WHERE SN4D.D_E_L_E_T_ = ''"
			_sSQL += "     			  AND SN4D.N4_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "     			  AND SN4D.N4_OCORR   = '" + _WOCORR + "'"
			_sSQL += "     			  AND SN4D.N4_FILIAL  = SN3.N3_FILIAL"
			_sSQL += "     			  AND SN4D.N4_ITEM    = SN3.N3_ITEM"
			_sSQL += "     			  AND SN4D.N4_CBASE   = SN3.N3_CBASE"
			_sSQL += " 				ORDER BY SN4D.N4_DATA DESC  ) AS VLR_DEPR_MENSAL"
			_sSQL += "			, SN3.N3_VRDACM1 AS VLR_SN3"
			_sSQL += "			, (SELECT ROUND(SUM( SN4D.N4_VLROC1),2)"
			_sSQL += "  			 FROM SN4010 AS SN4D"
	        _sSQL += "			    WHERE SN4D.N4_TIPO    = '" + _WTPSLD + "'" 
			_sSQL += "   			  AND SN4D.D_E_L_E_T_ = ''"
			_sSQL += "   			  AND SN4D.N4_FILIAL  = SN3.N3_FILIAL"
			_sSQL += "   			  AND SN4D.N4_OCORR   = '" + _WOCORR + "'"
			_sSQL += "   			  AND SN4D.N4_TIPOCNT = '4'"
			_sSQL += "   			  AND SN4D.N4_ITEM    = SN3.N3_ITEM"
			_sSQL += "   			  AND SN4D.N4_CBASE   = SN3.N3_CBASE) AS VLR_SN4"
			_sSQL += "	FROM SN3010 AS SN3"
			_sSQL += "		INNER JOIN SN1010 AS SN1"
			_sSQL += "			ON (SN1.D_E_L_E_T_ = ''"
			_sSQL += "    			AND SN1.N1_FILIAL = SN3.N3_FILIAL"
			_sSQL += "				AND SN1.N1_CBASE  = SN3.N3_CBASE"
			_sSQL += "				AND SN1.N1_ITEM   = SN3.N3_ITEM)"
			_sSQL += " WHERE SN3.D_E_L_E_T_ = ''"
			_sSQL += "   AND SN3.N3_TIPO    = '" + _WTPSLD + "')"
			_sSQL += " SELECT C.N1_FILIAL, C.N1_CBASE, C.N1_ITEM"
			_sSQL += "		, C.VLR_DEPR_MENSAL"
			_sSQL += "		, C.VLR_SN3, C.VLR_SN4"
			_sSQL += "		, ROUND(C.VLR_SN3-C.VLR_SN4,2) AS DIFERENCA"
			_sSQL += "		, CASE WHEN C.VLR_DEPR_MENSAL > 0 THEN ROUND((VLR_SN3-C.VLR_SN4),2) / C.VLR_DEPR_MENSAL"
			_sSQL += "		  ELSE 0 END  AS MESES"
			_sSQL += "	FROM C"
			_sSQL += "	WHERE ROUND(C.VLR_SN3,2) <> ROUND(C.VLR_SN4,2)"
			_sSQL += "	  AND ( SELECT COUNT(SN3U.N3_CBASE)"
			_sSQL += "   		  FROM SN3010 AS SN3U"
	        _sSQL += "  		 WHERE SN3U.D_E_L_E_T_ = ''"
			_sSQL += "    		   AND SN3U.N3_TIPO    = '" + _WTPSLD + "'"
			_sSQL += "    		   AND SN3U.N3_CBASE   = C.N1_CBASE ) = 1"
			_sSQL += "	  AND C.DT_FIM_DEPR != ''"
			_sSQL += "	  AND C.DT_BAIXA = ''"
			_sSQL += "	  AND C.VLR_DEPR_MENSAL > 0 "
			_sSQL += "  ORDER BY C.N1_CBASE, C.N1_ITEM, C.N1_FILIAL"
	
	   		//u_showmemo(_sSQL)
			_aAcertos := U_Qry2Array(_sSQL)
			if len(_aAcertos) > 0
				for i=1 to len(_aAcertos)// --------------------------------------------------------------------------
		    		_sSQL := ""
		    		_sSQL += " UPDATE SN3010"
		    		_sSQL += "    SET N3_VRDACM1 = " + cvaltochar( _aAcertos[i,6] )
		    		_sSQL += "      , N3_FIMDEPR = ''"
		    		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		    		_sSQL += "    AND N3_FILIAL  = '" + _aAcertos[i,1] + "'"
		    		_sSQL += "    AND N3_CBASE   = '" + _aAcertos[i,2] + "'"
		    		_sSQL += "    AND N3_ITEM    = '" + _aAcertos[i,3] + "'"
		    		_sSQL += "    AND N3_TIPO    = '" + _WTPSLD + "'"
		    		if TCSQLExec (_sSQL) < 0
		    			u_help ("Erro ao executar UPDATE tabela SN3. Comunique a TI")
		    			return
		    		endif
			    next
			endif
		NEXT	
	endif
	
	u_help("Acerto finalizado com sucesso")
		 								
return