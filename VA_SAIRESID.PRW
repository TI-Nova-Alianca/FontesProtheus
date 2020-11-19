//  Programa...: VA_SAIRESID
//  Autor......: Catia Cardoso
//  Data.......: 11/04/2016
//  Descricao..: Consulta Saidas de Residuos 
// 
//  Historico de alterações
//  18/04/2016 - Catia - alterado para buscar o nome do cliente tb - as vezes as saidas de residuos sao venda e usa SA1
//  05/05/2016 - Catia - alterado para que considere RE (Residuos) e VA (Vasiliames) tb
//  10/05/2016 - Catia - incluido o tipo do produto e liberado que sejam consultados todos os tipos de produto
//  06/06/2016 - Catia - alterado liste todos os tipos de produtos exceto PA
//  12/02/2019 - Andre - Listar apenas produtos tipo ('RE','VA','UC'). Opção de pesquisar por Cliente ou Fornecedores.
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_SAIRESID()
	
	_cPerg   := "VA_SAIRESID"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
	if Pergunte(_cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT SD2.D2_DOC     AS DOC"
    	_sQuery += " 	  , SD2.D2_SERIE   AS SERIE"
	 	_sQuery += " 	  , dbo.VA_DTOC(SD2.D2_EMISSAO)  AS DT_EMISSAO"
	 	_sQuery += " 	  , SD2.D2_CLIENTE AS DEST"
     	_sQuery += " 	  , CASE WHEN D2_TIPO IN ('B','D') THEN 'FORNECEDOR' ELSE 'CLIENTE' END AS DESTINATARIO"
     	_sQuery += " 	  , CASE WHEN D2_TIPO IN ('B','D') THEN SA2.A2_NOME ELSE SA1.A1_NOME END AS NOME"
     	_sQuery += " 	  , SD2.D2_COD     AS PRODUTO"
	 	_sQuery += " 	  , SB1.B1_DESC    AS DECRICAO"
	 	_sQuery += " 	  , SB1.B1_TIPO    AS TIPO"
	 	_sQuery += " 	  , SD2.D2_QUANT   AS QUANT"
  		_sQuery += "   FROM SD2010 AS SD2"
		_sQuery += " 		LEFT JOIN SA1010 AS SA1"
		_sQuery += " 			ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA1.A1_COD  = SD2.D2_CLIENTE"
		_sQuery += " 				AND SA1.A1_LOJA = SD2.D2_LOJA)"
		_sQuery += " 		LEFT JOIN SA2010 AS SA2"
		_sQuery += " 			ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA2.A2_COD  = SD2.D2_CLIENTE"
		_sQuery += " 				AND SA2.A2_LOJA = SD2.D2_LOJA)"
		_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_sQuery += " 			ON (SB1.D_E_L_E_T_  = ''"
		//_sQuery += " 				AND SB1.B1_TIPO != 'PA'
		_sQuery += " 				AND SB1.B1_TIPO IN ('RE','VA','UC')"
		_sQuery += " 				AND SB1.B1_COD  = SD2.D2_COD)"
 		_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''
 		_sQuery += "    AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'" 
	   	_sQuery += "    AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   		_sQuery += "	AND SD2.D2_COD BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
		_sQuery += " ORDER BY SD2.D2_EMISSAO, SD2.D2_DOC"
   		
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
		//u_log (_aDados)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, {1, "Num.Nota"       	   ,  30,  "@!"})
	    	aadd (_aCols, {2, "Serie"          	   ,  10,  "@!"})
	    	aadd (_aCols, {3, "Emissao Nota"       ,  30,  "@D"})
	    	aadd (_aCols, {4, "Destinatário"       ,  30,  "@!"})
	    	aadd (_aCols, {5, "Cliente/Fornecedor" ,  30,  "@!"})
	    	aadd (_aCols, {6, "Razão Social"   	   , 150,  "@!"})
			aadd (_aCols, {7, "Produto"            ,  30,  "@!"})
	    	aadd (_aCols, {8, "Descricao"          , 140,  "@!"})
	    	aadd (_aCols, {9, "Tipo"               ,  30,  "@!"})
			aadd (_aCols, {10, "Quantidade"    	   ,  50,  "@E 9,999,999.9999"})
	        
    		U_F3Array (_aDados, "Consulta Notas de Resíduos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {03, "Produto de       ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {04, "Produto até      ?", "C", 6, 0,  "",   "SB1", {},  ""})
	U_ValPerg (_cPerg, _aRegsPerg)
    
Return
