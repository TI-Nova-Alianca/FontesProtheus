//  Programa...: VA_VALRAPEL
//  Autor......: Catia Cardoso
//  Data.......: 05/03/2018
//  Descricao..: Consulta Saidas de Residuos 
// 
//  Historico de alterações
//
//
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_VALRAPEL()

	cPerg   := "VA_VALRAPEL"
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += "WITH C AS ("
		_sQuery += "	SELECT SA1.A1_COD AS CODIGO"
     	_sQuery += "		 , SA1.A1_LOJA AS LOJA"
	 	_sQuery += "		 , SA1.A1_NOME AS NOME"
	 	_sQuery += "		 , SA1.A1_VACBASE AS CODIGO_BASE"
	 	_sQuery += "		 , SA1.A1_VALBASE AS LOJA_BASE"
     	_sQuery += "		 , SA1.A1_EST AS UF"
     	_sQuery += "		 , SA1.A1_VEND AS VEND"
	 	_sQuery += "		 , CASE WHEN SA1.A1_VABARAP='1' THEN 'BASE NOTA'"
	    _sQuery += "    		    WHEN SA1.A1_VABARAP='2' THEN 'BASE MERCADORIA'"
		_sQuery += "				WHEN SA1.A1_VABARAP='3' THEN 'BASE NOTA - ST'"
	   	_sQuery += "		   ELSE '' END AS BASE_RAPEL"
	 	_sQuery += "		 ,(SELECT ZAX_PRAPEL"
	    _sQuery += "  			 FROM ZAX010"
        _sQuery += " 			WHERE D_E_L_E_T_ = ''"
		_sQuery += "   			  AND ZAX_CLIENT = SA1.A1_COD"
        _sQuery += "   			  AND ZAX_LOJA   = SA1.A1_LOJA"
        _sQuery += "   			  AND ZAX_ITEM   = ''"
        _sQuery += "   			  AND ZAX_LINHA  = '') AS PERC_RAPEL"
		_sQuery += "		 , (SELECT COUNT(ZAX_CLIENT)"
	    _sQuery += "  			  FROM ZAX010"
        _sQuery += " 			 WHERE D_E_L_E_T_ = ''"
        _sQuery += "   			   AND ZAX_CLIENT = SA1.A1_COD"
        _sQuery += "   			   AND ZAX_LOJA   = SA1.A1_LOJA"
        _sQuery += "   			   AND ZAX_LINHA  = '') AS DIFERENTES"
 		_sQuery += " 	 FROM SA1010 AS SA1"
 		_sQuery += "	WHERE SA1.A1_MSBLQL   = '2'"
 		_sQuery += "      AND SA1.A1_VEND BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sQuery += "      AND SA1.A1_EST BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sQuery += "	  AND SA1.A1_VABARAP != ''"
   		_sQuery += "	  AND SA1.A1_VABARAP != '0'" 
   		_sQuery += " )"
		_sQuery += " SELECT C.CODIGO, C.LOJA, C.NOME, C.CODIGO_BASE, C.LOJA_BASE, C.UF, C.VEND, SA3.A3_NOME"
     	_sQuery += "      , C.BASE_RAPEL" 
	 	_sQuery += "	  , C.PERC_RAPEL"
	 	_sQuery += "	  , CASE WHEN C.DIFERENTES > 1 THEN 'SIM'" 
	    _sQuery += "             WHEN C.DIFERENTES = 1 THEN 'NAO'" 
	   	_sQuery += "        ELSE 'ERRO DE CADASTRO' END AS PERC_DIFERENTES"
	 	_sQuery += "	  , CASE WHEN C.PERC_RAPEL IS NULL THEN 'ERRO CADASTRO'"
	    _sQuery += "    		 WHEN C.PERC_RAPEL = 0 THEN 'VERIFICAR PERCENTUAL'"
	    _sQuery += "		ELSE ' ' END AS OBSERVACOES" 
  		_sQuery += " FROM C"
		_sQuery += "	INNER JOIN SA3010 AS SA3"
		_sQuery += "		ON (SA3.D_E_L_E_T_ = ''"
		_sQuery += "    		AND SA3.A3_COD = C.VEND)"
		_sQuery += " ORDER BY C.CODIGO_BASE, C.LOJA_BASE"

    	//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, {1, "Cliente"       ,  30,  "@!"})
	    	aadd (_aCols, {2, "Loja"          ,  10,  "@!"})
	    	aadd (_aCols, {3, "Nome"          , 150,  "@!"})
	    	aadd (_aCols, {4, "Cod.Base"      ,  20,  "@!"})
	    	aadd (_aCols, {5, "Loja Base"     ,  10,  "@!"})
			aadd (_aCols, {6, "UF"            ,  20,  "@!"})
	    	aadd (_aCols, {7, "Vendedor"      ,  30,  "@!"})
	    	aadd (_aCols, {8, "Nome"          , 120,  "@!"})
			aadd (_aCols, {9, "Base Rapel"    ,  50,  "@!"})
			aadd (_aCols, {10, "%Rapel"    	  ,  40,  "@E 99.99"})
			aadd (_aCols, {11, "%Diferentes"  ,  30,  "@!"})
			aadd (_aCols, {12, "Observações"  , 120,  "@!"})
	        
    		U_F3Array (_aDados, "Consulta Clientes com Rapel - Valida Informações", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Representante de  ?", "C", 3, 0,  "",   "SA3", {},  ""})
    aadd (_aRegsPerg, {02, "Representante até ?", "C", 3, 0,  "",   "SA3", {},  ""})
    aadd (_aRegsPerg, {03, "UF de             ?", "C", 2, 0,  "",   "12 ", {},  "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate            ?", "C", 2, 0,  "",   "12 ", {},  "UF final do cliente"})
	
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
