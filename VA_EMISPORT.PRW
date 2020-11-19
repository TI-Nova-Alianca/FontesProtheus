//  Programa...: VA_EMISPORT
//  Autor......: Catia Cardoso
//  Data.......: 21/05/2019
//  Descricao..: Consulta Emissoes por portador 
// 
//  Historico de alterações
// 
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_EMISPORT()
	
	_cPerg   := "VA_EMISPORT"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
	if Pergunte(_cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " WITH C AS (SELECT E1_FILIAL AS FILIAL"
    	_sQuery += " 				 , CASE WHEN E1_PORTADO = '' THEN 'CX1'"
	    _sQuery += " 				   ELSE E1_PORTADO END  AS PORTADOR"
	    _sQuery += " 				 , ROUND(SUM(E1_VALOR),2) AS TOTAL"
	    _sQuery += " 				 , COUNT(R_E_C_N_O_) AS QUANTIDADE"
	    _sQuery += " 			  FROM SE1010"
	    _sQuery += " 			 WHERE D_E_L_E_T_ = ''"
	    _sQuery += " 			   AND E1_FILIAL BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	    _sQuery += " 			   AND E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += " 			   AND E1_TIPO = 'NF'"
	    _sQuery += " 			 GROUP BY E1_FILIAL, E1_PORTADO"
	    _sQuery += " 			 UNION ALL"
	    _sQuery += " 			SELECT E1_FILIAL AS FILIAL"
	    _sQuery += " 				 , '*** TOTAL DA FILIAL' AS PORTADOR"
	    _sQuery += " 				 , ROUND(SUM(E1_VALOR),2) AS TOTAL"
	    _sQuery += " 				 , COUNT(R_E_C_N_O_) AS QUANTIDADE"
	    _sQuery += " 		      FROM SE1010"
	    _sQuery += " 			 WHERE D_E_L_E_T_ = ''"
	    _sQuery += " 			   AND E1_FILIAL BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	    _sQuery += " 			   AND E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += " 			   AND E1_TIPO = 'NF'"
	    _sQuery += " 			 GROUP BY E1_FILIAL"
	    _sQuery += " 			 UNION ALL"
	    _sQuery += " 			SELECT '**' AS FILIAL"
	    _sQuery += " 				 , '*** TOTAL GERAL' AS PORTADOR"
	    _sQuery += " 				 , ROUND(SUM(E1_VALOR),2) AS TOTAL"
	    _sQuery += " 				 , COUNT(R_E_C_N_O_) AS QUANTIDADE"
	    _sQuery += " 			  FROM SE1010"
	    _sQuery += " 			 WHERE D_E_L_E_T_ = ''"
	    _sQuery += " 			   AND E1_FILIAL BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	    _sQuery += " 			   AND E1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += " 			   AND E1_TIPO = 'NF')"
	    _sQuery += "   SELECT C.FILIAL, C.PORTADOR"
	    _sQuery += " 		, ISNULL((SELECT TOP 1 A6_NOME FROM SA6010 WHERE A6_FILIAL = C.FILIAL AND A6_COD = C.PORTADOR ORDER BY R_E_C_N_O_),'TOTAL')"
	    _sQuery += " 		, C.QUANTIDADE"
	    _sQuery += " 		, C.TOTAL"
	    _sQuery += "     FROM C"
	    _sQuery += " 	ORDER BY C.FILIAL, C.TOTAL DESC, C.PORTADOR"
    	
    	//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
		//u_log (_aDados)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, {1, "Filial"      , 20,  "@!"})
	    	aadd (_aCols, {2, "Portador"    , 20,  "@!"})
	    	aadd (_aCols, {3, "Descrição"   , 50,  "@!"})
			aadd (_aCols, {4, "Quantidade"  , 50,  "@E 9999"})
	    	aadd (_aCols, {5, "Total"       , 50,  "@E 99,999,999.99"})
	        
    		U_F3Array (_aDados, "Consulta Emissoes por Portador", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Emissao de       ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Emissao até      ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Filial  de       ?", "C", 2, 0,  "",   "SM0", {},  ""})
	aadd (_aRegsPerg, {04, "Filial  até      ?", "C", 2, 0,  "",   "SM0", {},  ""})
	U_ValPerg (_cPerg, _aRegsPerg)
    
Return
