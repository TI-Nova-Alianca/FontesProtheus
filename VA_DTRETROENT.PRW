//  Programa...: VA_DTRETROENT
//  Autor......: Catia Cardoso
//  Data.......: 01/03/2019
//  Descricao..: Consulta documentos de entrada com data retroativa 
// 
//  Historico de alterações
//
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_DTRETROENT()
	
	_cPerg   := "VA_DTRETROENT"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
	if Pergunte(_cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT SF1.F1_FILIAL AS FILIAL"
    	_sQuery += "	  , dbo.VA_DTOC(SF1.F1_VADTINC) AS INCLUSAO"
    	_sQuery += "	  , dbo.VA_DTOC(SF1.F1_DTDIGIT) AS DTDIGIT"
    	_sQuery += "	  , dbo.VA_DTOC(SF1.F1_EMISSAO) AS EMISSAO"
    	_sQuery += "	  , SF1.F1_ESPECIE"
    	_sQuery += "	  , SF1.F1_TIPO"
    	_sQuery += "	  , SF1.F1_DOC"
    	_sQuery += "	  , SF1.F1_SERIE"
    	_sQuery += "	  , SF1.F1_FORNECE"
    	_sQuery += "	  , IIF (SF1.F1_TIPO = 'N', SA2.A2_NOME, SA1.A1_NOME) AS TIPO"
    	_sQuery += "	  , SD1.D1_TES"
    	_sQuery += "	  , SF4.F4_ESTOQUE"
    	_sQuery += "	  , SD1.D1_COD"
    	_sQuery += "	  , SD1.D1_DESCRI AS PRIMEIRO_PRODUTO_NF"
    	_sQuery += "	  , SD1.D1_QUANT"
    	_sQuery += "	  , SF1.F1_VALBRUT"
    	_sQuery += "	  , SF1.F1_VAUSER"
    	_sQuery += "   FROM SF1010 AS SF1"
    	_sQuery += "		LEFT JOIN SA2010 AS SA2"
		_sQuery += "			ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += "    			AND SA2.A2_COD  = SF1.F1_FORNECE"
		_sQuery += "				AND SA2.A2_LOJA = SF1.F1_LOJA)"
		_sQuery += "		LEFT JOIN SA1010 AS SA1"
		_sQuery += "			ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += "    			AND SA1.A1_COD  = SF1.F1_FORNECE"
		_sQuery += "				AND SA1.A1_LOJA = SF1.F1_LOJA)"
		_sQuery += "		INNER JOIN SD1010 AS SD1"
		_sQuery += "			ON (SD1.D_E_L_E_T_ = ''"
		_sQuery += "				AND SD1.D1_DOC     = SF1.F1_DOC"
		_sQuery += "				AND SD1.D1_SERIE   = SF1.F1_SERIE"
		_sQuery += "				AND SD1.D1_FORNECE = SF1.F1_FORNECE"
		_sQuery += "				AND SD1.D1_LOJA    = SF1.F1_LOJA"
		_sQuery += "				AND SD1.D1_EMISSAO = SF1.F1_EMISSAO"
		_sQuery += "				AND SD1.D1_ITEM    = ( SELECT MIN(SD1ITEM.D1_ITEM)"
		_sQuery += "							 			 FROM SD1010 AS SD1ITEM "
		_sQuery += "						    			WHERE SD1ITEM .D_E_L_E_T_ = ''"
		_sQuery += "							  			  AND SD1ITEM .D1_DOC     = SD1.D1_DOC"
		_sQuery += "							  			  AND SD1ITEM .D1_SERIE   = SD1.D1_SERIE"
		_sQuery += "							    		  AND SD1ITEM .D1_FORNECE = SD1.D1_FORNECE"
		_sQuery += "							  			  AND SD1ITEM .D1_LOJA    = SD1.D1_LOJA"
		_sQuery += "							              AND SD1ITEM .D1_EMISSAO = SD1.D1_EMISSAO"
		_sQuery += "										GROUP BY SD1ITEM.D1_DOC, SD1ITEM.D1_SERIE, SD1ITEM.D1_FORNECE, SD1ITEM.D1_FORNECE, SD1ITEM.D1_LOJA, SD1ITEM.D1_EMISSAO ) )"
		_sQuery += "		INNER JOIN SF4010 AS SF4"
		_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "				AND SF4.F4_CODIGO = SD1.D1_TES)"
		_sQuery += "  WHERE SF1.D_E_L_E_T_ = ''"
		_sQuery += "    AND SF1.F1_DTDIGIT < SF1.F1_VADTINC"
		_sQuery += "    AND SF1.F1_VADTINC >= '" + dtos (mv_par01) + "'"
		_sQuery += "  ORDER BY SF1.F1_VADTINC DESC, SF1.F1_EMISSAO"
    	
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
		//u_log (_aDados)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
    		aadd (_aCols, { 1, "Filial"       	   			,  10,  "@!"})
    		aadd (_aCols, { 2, "Dt.Inclusao"       			,  30,  "@D"})
    		aadd (_aCols, { 3, "Dt.Digitacao"      			,  30,  "@D"})
    		aadd (_aCols, { 4, "Dt.Emissao"        			,  30,  "@D"})
    		aadd (_aCols, { 5, "Especie"           			,  20,  "@!"})
    		aadd (_aCols, { 6, "Tipo"              			,  10,  "@!"})
    		aadd (_aCols, { 7, "Num.Nota"          			,  30,  "@!"})
	    	aadd (_aCols, { 8, "Serie"             			,  10,  "@!"})
	    	aadd (_aCols, { 9, "Fornecdor"         			,  30,  "@!"})
	    	aadd (_aCols, {10, "Razão Social"      			, 150,  "@!"})
	    	aadd (_aCols, {11, "TES"               			,  10,  "@!"})
	    	aadd (_aCols, {12, "Estoque"           		  	,  10,  "@!"})
			aadd (_aCols, {13, "Produto"           		  	,  30,  "@!"})
	    	aadd (_aCols, {14, "Descricao(Primeiro item)" 	, 140,  "@!"})
	    	aadd (_aCols, {15, "Quantidade"    	   		  	,  50,  "@E 999,999.9999"})
	    	aadd (_aCols, {16, "Total da NF"       		  	,  50,  "@E 999,999.9999"})
	    	aadd (_aCols, {17, "Usuario"      	   		  	, 150,  "@!"})
	    	
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
    aadd (_aRegsPerg, {01, "Data Inclusao >= ?", "D", 8, 0,  "",   "   ", {},  ""})
	U_ValPerg (_cPerg, _aRegsPerg)
    
Return
