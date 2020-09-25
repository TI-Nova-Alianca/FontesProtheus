//  Programa...: ML_ULTCOM
//  Autor......: Catia Cardoso
//  Data.......: 01/09/2016
//  Descricao..: Dados de ultimas compras de ME por perído 
// 
//  Historico de alterações
//
// ---------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_ULTCOM()
	cPerg   := "ML_ULTCOM"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	
    	_sQuery := " "
    	_sQuery += " WITH C AS ( SELECT B1_COD AS PRODUTO, B1_DESC DESCRICAO, B1_TIPO AS TIPO, B1_UCOM AS DATA"
		_sQuery += " 			      , (SELECT TOP 1 SD1.D1_DOC"
		_sQuery += " 		 			   FROM SD1010 AS SD1"
		_sQuery += "						 INNER JOIN SF4010 AS SF4"
		_sQuery += "							ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "								AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += "								AND SF4.F4_DUPLIC = 'S'"
		_sQuery += "								AND SF4.F4_ESTOQUE = 'S')"
  		_sQuery += "			 		  WHERE SD1.D1_COD     = SB1.B1_COD"
		_sQuery += "		  	   		    AND SD1.D1_DTDIGIT = SB1.B1_UCOM"
		_sQuery += "		       		    AND SD1.D_E_L_E_T_ = ''"
		_sQuery += "		     		  ORDER BY D1_DTDIGIT DESC) AS NOTA"
		_sQuery += "			  FROM SB1010 AS SB1"
		_sQuery += "   			 WHERE SB1.D_E_L_E_T_ = ''"
		_sQuery += "			   AND SB1.B1_TIPO = 'ME'"
		_sQuery += "			   AND SB1.B1_UCOM BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "')" 
		_sQuery += " SELECT C.PRODUTO"
     	_sQuery += "	  , C.DESCRICAO"
	 	_sQuery += "	  , C.TIPO"
	 	_sQuery += "	  , dbo.VA_DTOC(C.DATA) AS ULT_COMP, C.NOTA"
	 	_sQuery += "	  , SD1.D1_SERIE AS SERIE"
     	_sQuery += "	  , SD1.D1_VUNIT AS VLR_UNIT"
	 	_sQuery += "	  , SD1.D1_IPI AS ALIQ_IPI"
	 	_sQuery += "	  , SD1.D1_PICM AS ALIQ_ICM"
	 	_sQuery += "	  , SD1.D1_FORNECE AS FORNECEDOR"
	 	_sQuery += "	  , SA2.A2_NOME AS NOME_FOR"
  		_sQuery += "   FROM C AS C"
		_sQuery += "	  	INNER JOIN SD1010 AS SD1"
		_sQuery += "			ON (SD1.D_E_L_E_T_ = ''"
		_sQuery += "				AND SD1.D1_DOC     = C.NOTA"
		_sQuery += "				AND SD1.D1_DTDIGIT = C.DATA"
		_sQuery += "				AND SD1.D1_COD     = C.PRODUTO)"
		_sQuery += "		INNER JOIN SA2010 AS SA2"
		_sQuery += "			ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += "				AND SA2.A2_COD  = SD1.D1_FORNECE"
		_sQuery += "				AND SA2.A2_LOJA = SD1.D1_LOJA)"
		_sQuery += "   ORDER BY C.DATA"
    	_aDados := U_Qry2Array(_sQuery)
    	
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, { 1,  "Produto" 	      	   ,  30,  "@!"})
	    	aadd (_aCols, { 2,  "Descricao"            ,  90,  "@!"})
	    	aadd (_aCols, { 3,  "Tipo"             	   ,  10,  "@!"})
	    	aadd (_aCols, { 4,  "Ultima Compra"        ,  30,  "@D"})
	    	aadd (_aCols, { 5,  "Nota"       	  	   ,  30,  "@!"})
	    	aadd (_aCols, { 6,  "Serie"          	   ,  10,  "@!"})
	    	aadd (_aCols, { 7,  "Valor Unit"    	   ,  50,  "@E 9,999,999.99"})
	    	aadd (_aCols, { 8,  "Aliq IPI"       	   ,  35,  "@E 999.99"})
	    	aadd (_aCols, { 9,  "Aliq ICM"       	   ,  35,  "@E 999.99"})
	    	aadd (_aCols, {10,  "Fornecedor"           ,  30,  "@!"})
	    	aadd (_aCols, {11,  "Razão Social"         , 100,  "@!"})
			
    		U_F3Array (_aDados, "Consulta Ultimas Compras de ME por Perído", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
		else
			msgalert("Não foram encontrados dados para consulta")
		endif    		
	endif
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Ultima Compra de       ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Ultima Compra até      ?", "D", 8, 0,  "",   "   ", {},  ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return