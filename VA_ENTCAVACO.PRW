//  Programa...: VA_ENTCAVACO
//  Autor......: Catia Cardoso
//  Data.......: 06/06/2016
//  Descricao..: Consulta Entradas de Cavacos 
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ENTCAVACO()

	cPerg   := "VA_ENTCAVACO"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT SD1.D1_DOC     AS DOC"
    	_sQuery += " 	  , SD1.D1_SERIE   AS SERIE"
	 	_sQuery += " 	  , dbo.VA_DTOC(SD1.D1_DTDIGIT)  AS DT_DIGITACAO"
	 	_sQuery += " 	  , SD1.D1_FORNECE AS FORNECE"
     	_sQuery += " 	  , CASE WHEN D1_TIPO ='N' THEN SA2.A2_NOME ELSE SA1.A1_NOME END AS NOME"
     	_sQuery += " 	  , SD1.D1_COD     AS PRODUTO"
	 	_sQuery += " 	  , SB1.B1_DESC    AS DECRICAO"
	 	_sQuery += " 	  , SB1.B1_TIPO    AS TIPO"
	 	_sQuery += " 	  , SD1.D1_QUANT   AS QUANT"
	 	_sQuery += "      , ISNULL(ISNULL(ZZT.ZZT_PESLIQ,ZZT1.ZZT_PESLIQ),0) AS PESO"
  		_sQuery += "   FROM SD1010 AS SD1"
  		_sQuery += " 		INNER JOIN SF4010 AS SF4"
  		_sQuery += " 			ON (SF4.D_E_L_E_T_  = ''"
  		_sQuery += " 				AND SF4.F4_CODIGO = SD1.D1_TES
  		_sQuery += " 				AND SF4.F4_DUPLIC = 'S')"
		_sQuery += " 		LEFT JOIN SA2010 AS SA2"
		_sQuery += " 			ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA2.A2_COD  = SD1.D1_FORNECE"
		_sQuery += " 				AND SA2.A2_LOJA = SD1.D1_LOJA)"
		_sQuery += " 		LEFT JOIN SA1010 AS SA1"
		_sQuery += " 			ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA1.A1_COD  = SD1.D1_FORNECE"
		_sQuery += " 				AND SA1.A1_LOJA = SD1.D1_LOJA)"
		_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_sQuery += " 			ON (SB1.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SB1.B1_COD  = SD1.D1_COD)"
		_sQuery += " 		INNER JOIN SF1010 AS SF1"
 		_sQuery += " 			ON (SF1.D_E_L_E_T_  = ''"
 		_sQuery += " 				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
 		_sQuery += " 				AND SF1.F1_DOC     = SD1.D1_DOC"
		_sQuery += " 				AND SF1.F1_SERIE   = SD1.D1_SERIE"
		_sQuery += " 				AND SF1.F1_FORNECE = SD1.D1_FORNECE"
		_sQuery += " 				AND SF1.F1_LOJA    = SD1.D1_LOJA)"
		_sQuery += " 		LEFT JOIN ZZT010 AS ZZT"
		_sQuery += " 			ON (ZZT.D_E_L_E_T_ = ''"
		_sQuery += " 				AND ZZT.ZZT_FILIAL = SF1.F1_FILIAL"
		_sQuery += " 				AND ZZT.ZZT_CHVNFE = SF1.F1_CHVNFE)"
		_sQuery += " 		LEFT JOIN ZZT010 AS ZZT1"
		_sQuery += " 			ON (ZZT1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND ZZT1.ZZT_FILIAL = SF1.F1_FILIAL"
		_sQuery += " 				AND ZZT1.ZZT_FORN   = SF1.F1_FORNECE"
		_sQuery += " 				AND ZZT1.ZZT_LOJF   = SF1.F1_LOJA"
		_sQuery += " 				AND ZZT1.ZZT_NF     = SF1.F1_DOC)"
		_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''
 		_sQuery += "    AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'" 
	   	_sQuery += "    AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	   	_sQuery += "	AND SD1.D1_FORNECE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	   	_sQuery += "	AND SD1.D1_TIPO = 'N'"
	   	_sQuery += " 	AND SD1.D1_COD  = '2475'"
		_sQuery += " 	AND SD1.D1_PEDIDO != ''"
		_sQuery += " ORDER BY SD1.D1_DTDIGIT, SD1.D1_DOC"
   		
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, {1, "Num.Nota"       	   ,  30,  "@!"})
	    	aadd (_aCols, {2, "Serie"          	   ,  10,  "@!"})
	    	aadd (_aCols, {3, "Emissao Nota"       ,  30,  "@D"})
	    	aadd (_aCols, {4, "Destinatário"       ,  30,  "@!"})
	    	aadd (_aCols, {5, "Razão Social"   	   , 150,  "@!"})
			aadd (_aCols, {6, "Produto"            ,  30,  "@!"})
	    	aadd (_aCols, {7, "Descricao"          , 140,  "@!"})
	    	aadd (_aCols, {8, "Tipo"               ,  30,  "@!"})
			aadd (_aCols, {9, "Quantidade"    	   ,  50,  "@E 9,999,999.9999"})
			aadd (_aCols, {10, "Peso"    	       ,  50,  "@E 9,999,999.9999"})
	        
    		U_F3Array (_aDados, "Consulta Notas Entrada de Cavacos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Data Entrada de  ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Entrada até ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Fornecedor de    ?", "C", 6, 0,  "",   "SA2", {},  ""})
	aadd (_aRegsPerg, {04, "Fornecedor até   ?", "C", 6, 0,  "",   "SA2", {},  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return