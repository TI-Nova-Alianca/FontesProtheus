//  Programa...: VA_PRODVD
//  Autor......: Catia Cardoso
//  Data.......: 29/01/2018
//  Descricao..: Consulta Producao de VD - Auxiliar IBAMA 
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_PRODVD()

	cPerg   := "VA_PRODVD"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT SD3.D3_COD"
	 	_sQuery += "      , SB1.B1_DESC"
     	_sQuery += "      , SD3.D3_TIPO"
	 	_sQuery += "      , SUM(SD3.D3_QUANT) AS QUANTPROD"
  		_sQuery += "   FROM SD3010 AS SD3"
		_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SB1.B1_COD = SD3.D3_COD)"
 		_sQuery += "  WHERE SD3.D_E_L_E_T_   = ''"
   		_sQuery += "    AND SD3.D3_FILIAL    = '"  + xfilial ("SD2") + "'"
   		_sQuery += "    AND D3_EMISSAO BETWEEN  '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   		_sQuery += "    AND SD3.D3_CF LIKE '%PR%'"
   		_sQuery += "    AND SD3.D3_TIPO = 'VD'"
		_sQuery += " GROUP BY SD3.D3_COD, SB1.B1_DESC, SD3.D3_TIPO"
    	
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
			aadd (_aCols, {1, "Produto"            ,  30,  "@!"})
	    	aadd (_aCols, {2, "Descricao"          , 140,  "@!"})
	    	aadd (_aCols, {3, "Tipo"               ,  30,  "@!"})
			aadd (_aCols, {4, "Quantidade"    	   ,  50,  "@E 9,999,999.9999"})
	        
    		U_F3Array (_aDados, "Consulta Itens Produzidos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Data produção de  ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data producao até ?", "D", 8, 0,  "",   "   ", {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return