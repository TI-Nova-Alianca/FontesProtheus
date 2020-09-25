//  Programa...: VA_ZA5ZERASLD	
//  Autor......: Catia Cardoso
//  Data.......: 24/04/2018
//  Descricao..: Zera saldos a bonificar 
//
//  Alterações:
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ZA5ZERASLD()
	local j	:= 0
	local i	:= 0
	cPerg   := "ZA5ZERASLD"
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.)
		// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
    	_sQuery := ""
    	_sQuery += "WITH C"
		_sQuery += "	AS"
		_sQuery += "	(SELECT  SA14.A1_VACBASE AS CLIENTE"
		_sQuery += "		,SA14.A1_VALBASE     AS LOJA"
		_sQuery += "		,SUM(ZA4.ZA4_VLR) AS VALOR"
		_sQuery += "		,ISNULL((SELECT"
		_sQuery += "			ROUND(SUM(ZA5_VLR), 2)"
		_sQuery += "		FROM ZA5010 AS ZA5"
		_sQuery += "			INNER JOIN SA1010 AS SA15"
		_sQuery += "				ON (SA15.D_E_L_E_T_     = ''"
		_sQuery += "					AND SA15.A1_COD     = ZA5_CLI"
		_sQuery += "					AND SA15.A1_LOJA    = ZA5_LOJA"
		_sQuery += "					AND SA15.A1_VACBASE = SA14.A1_VACBASE"
		_sQuery += "					AND SA15.A1_VALBASE = SA14.A1_VALBASE)"
		_sQuery += "		WHERE ZA5.D_E_L_E_T_ = '' "
		_sQuery += "		  AND ZA5.ZA5_TLIB = '1'), 0) AS VLR_UTILIZADO"
		_sQuery += "	,ISNULL((SELECT"
		_sQuery += "			ROUND(SUM(ZA5_VLR), 2)"
		_sQuery += "		FROM ZA5010 AS ZA5"
		_sQuery += "			INNER JOIN SA1010 AS SA15"
		_sQuery += "				ON (SA15.D_E_L_E_T_     = ''"
		_sQuery += "					AND SA15.A1_COD     = ZA5_CLI"
		_sQuery += "					AND SA15.A1_LOJA    = ZA5_LOJA"
		_sQuery += "					AND SA15.A1_VACBASE = SA14.A1_VACBASE"
		_sQuery += "					AND SA15.A1_VALBASE = SA14.A1_VALBASE)"
		_sQuery += "		WHERE ZA5.D_E_L_E_T_ = '' "
		_sQuery += "		  AND ZA5.ZA5_TLIB = '9'), 0) AS VLR_ZERAMENTO_SALDO"
		_sQuery += "	FROM ZA4010 AS ZA4"
		_sQuery += "		INNER JOIN SA1010 AS SA14"
		_sQuery += "			ON (SA14.D_E_L_E_T_ = ''"
		_sQuery += "				AND SA14.A1_COD     = ZA4.ZA4_CLI"
		_sQuery += "				AND SA14.A1_LOJA    = ZA4.ZA4_LOJA)"
		_sQuery += "	WHERE ZA4.D_E_L_E_T_ = ''"
		_sQuery += "	  AND ZA4.ZA4_CLI    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sQuery += "	  AND ZA4.ZA4_NUM    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sQuery += "	  AND ZA4.ZA4_TLIB = '1'"
		_sQuery += "	GROUP BY	SA14.A1_VACBASE"
	    _sQuery += "				,SA14.A1_VALBASE)"
		_sQuery += " SELECT C.CLIENTE"
		_sQuery += "	  , C.LOJA"
		_sQuery += "	  , ROUND(C.VALOR - (C.VLR_UTILIZADO + C.VLR_ZERAMENTO_SALDO) ,2)  AS VLR_SALDO"
		_sQuery += "   FROM C"
   		_sQuery += "  WHERE ROUND(C.VALOR - (C.VLR_UTILIZADO + C.VLR_ZERAMENTO_SALDO) ,2) <> 0"
		_sQuery += "  ORDER BY C.CLIENTE, C.LOJA" 
		//u_showmemo (_sQuery)
    	_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0
    		for i=1 to len(_aDados)
    			_wcliente  = _aDados[i, 1]
    			_wloja     = _aDados[i, 2]
    			_wsaldo    = _aDados[i, 3]
				
				if _wsaldo > 0 .and. val(_wcliente) > 0    		
					// BUSCA AS VERBAS QUE DEVEM SER ZERADO O SALDO
					_sQuery := ""
					_sQuery += " WITH C AS (SELECT ZA4.ZA4_NUM     AS NUM"
					_sQuery += "    			 , SA1.A1_VACBASE  AS CLIENTE"
					_sQuery += "    			 , SA1.A1_VALBASE  AS LOJA"
     				_sQuery += "    			 , ZA4.ZA4_VLR     AS VALOR"
     				_sQuery += " 				 , ISNULL( ( SELECT ROUND(SUM(ZA5.ZA5_VLR),2)"
				   	_sQuery += " 							   FROM ZA5010 AS ZA5"
				  	_sQuery += " 							  WHERE ZA5.D_E_L_E_T_ = ''"
					_sQuery += " 								AND ZA5.ZA5_NUM = ZA4.ZA4_NUM) ,0) AS VLR_UTILIZADO"
					_sQuery += " 			 FROM ZA4010 AS ZA4"
  					_sQuery += "				INNER JOIN SA1010 AS SA1"
					_sQuery += "					ON (SA1.D_E_L_E_T_ = ''"
					_sQuery += "						AND SA1.A1_COD     = ZA4.ZA4_CLI"
					_sQuery += "						AND SA1.A1_LOJA    = ZA4.ZA4_LOJA)"
					_sQuery += " 			WHERE ZA4.D_E_L_E_T_ = ''"
   					_sQuery += " 			  AND ZA4.ZA4_TLIB = '1' )"
					_sQuery += " SELECT C.CLIENTE, C.LOJA, C.NUM, C.VALOR"
     				_sQuery += "      , ROUND (C.VALOR - C.VLR_UTILIZADO,2) AS VLR_SALDO"
  					_sQuery += "   FROM C"
 					_sQuery += "  WHERE ROUND (C.VALOR - C.VLR_UTILIZADO,2) > 0"
 					_sQuery += "    AND C.CLIENTE = '" + _wcliente + "'"
 					_sQuery += "    AND C.LOJA    = '" + _wloja + "'"
 					_sQuery += "  ORDER BY C.CLIENTE, C.LOJA"
 					_aVerbas := U_Qry2Array(_sQuery)
 					if len(_aVerbas) > 0
 						for j=1 to len(_aVerbas)
    						_wnumverba  = _aVerbas[j, 3]
    						_wsldverba  = _aVerbas[j, 5]
    						// BUSCA TODAS AS VERBAS DO CLIENTE QUE AINDA TEM SALDO E DEVEM SER ZERADAS
							_sQuery := ""
							_sQuery += " SELECT MAX(ZA5.ZA5_SEQ)"
							_sQuery += "   FROM " + RetSQLName ("ZA5") + " AS ZA5 "
							_sQuery += "  WHERE ZA5.D_E_L_E_T_   = ''"
							_sQuery += "    AND ZA5.ZA5_NUM  = '" + _wnumverba + "'"
							
							_aSeq := U_Qry2Array(_sQuery)
							_wseq := 0
							if len(_aSeq) > 0
								_wseq = _aSeq[1,1]
							endif	
			
				    		// grava tabela ZA5
			    			//msgalert("GRAVA ZA5")
							RecLock ("ZA5",.T.)
								za5 -> za5_num     = _wnumverba
								za5 -> za5_seq     = _wseq+1
								za5 -> za5_vlr     = _wsldverba 
								za5 -> za5_doc     = ''
								za5 -> za5_cli	   = _wcliente
								za5 -> za5_loja    = _wloja
								za5 -> za5_tlib    = '9'
								za5 -> za5_usu     = cusername
								za5 -> za5_dta     = date()
								za5 -> za5_pedido  = ''
								za5 -> za5_nota    = ''
								za5 -> za5_serie   = ''
								za5 -> za5_filial  = xFilial("ZA5") 
							MsUnLock()
							
							_sQuery := ""
							_sQuery += " SELECT ZA4.ZA4_NUM"
							_sQuery += "      , SUM(ZA4.ZA4_VLR) - ISNULL( ( SELECT ROUND(SUM(ZA5_VLR),2)"
							_sQuery += "         			      		       FROM ZA5010"
							_sQuery += "       				  		          WHERE D_E_L_E_T_ = ''"
							_sQuery += "         						        AND ZA5_NUM    = ZA4.ZA4_NUM) ,0) AS VLR_SLD"
							_sQuery += "   FROM " + RetSQLName ("ZA4") + " AS ZA4"
							_sQuery += "  WHERE D_E_L_E_T_   = ''"
							_sQuery += "    AND ZA4.ZA4_NUM  = '" + _wnumverba + "'"
							_sQuery += "    AND ZA4.ZA4_CLI  = '" + _wcliente + "'"
							_sQuery += "    AND ZA4.ZA4_LOJA = '" + _wloja + "'"
							_sQuery += "  GROUP BY ZA4.ZA4_NUM"
							_aSaldo := U_Qry2Array(_sQuery)
				   				
				   			_wsaldo := 0
				   			if len(_aSaldo) = 1
								if _aSaldo[1,2] = 0 
									// grava status de utilizacao
									DbSelectArea("ZA4")
									DbSetOrder(1)
									DbSeek(xFilial("ZA4") + _wnumverba,.F.)
									RecLock ("ZA4",.F.)
										ZA4 -> ZA4_SUTL = '3'
									MsUnLock()
								endif							        					
			        		endif
						next
					endif
				endif												        		
			next        		
		endif        		        				    	
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Cliente de      ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate     ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Numero Verba    ?", "C", 6, 0,  "",   "", {},  ""})
	aadd (_aRegsPerg, {04, "Numero Verba    ?", "C", 6, 0,  "",   "", {},  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return