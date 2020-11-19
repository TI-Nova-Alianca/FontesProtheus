// Programa...: VA_PAGBAN
// Autor......: Andre Alves
// Data.......: 03/08/2018
// Descricao..: Consultas Recebimentos por Banco
//
// ------------------------------------------------------------------------------------------------
// Historico de alteracoes:

// ------------------------------------------------------------------------------------------------
User Function VA_PAGBAN ()
    cPerg    := "VA_PAGBAN"
    
    _ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
	    
	    _sQuery := ""
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL, SE5.E5_DATA AS DATA,"
	  	_sQuery += "   	  (SELECT TOP 1 A6_NOME"
	  	_sQuery += " 	  FROM " + RetSQLName ("SA6") + " AS SA6"
	  	_sQuery += " 	  	WHERE A6_COD = SE5.E5_BANCO"
	  	_sQuery += " 	    AND A6_BLOCKED = '2') AS DESCRICAO,"
	  	_sQuery += " 	    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	  	_sQuery += " 	    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	  	_sQuery += " 	  FROM " + RetSQLName ("SE5") + " AS SE5"
	  	_sQuery += "      	WHERE SE5.D_E_L_E_T_ = ''"
	  	_sQuery += "        AND SE5.E5_DATA     BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	  	_sQuery += "        AND SE5.E5_RECPAG  = 'P'"
	  	_sQuery += "        AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	  	_sQuery += "	    AND SE5.E5_BANCO   NOT IN ('', 'CX1','999','C/C') "
     	_sQuery += "		AND SE5.E5_CONTA   !='.'"
	  	_sQuery += "		AND SE5.E5_MOEDA   != 'M1'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'DESP BANC'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'VERBAS'"
	  	_sQuery += "		AND SE5.E5_TIPODOC != 'TR'"
	  	_sQuery += "		AND SE5.E5_TIPO    != 'NCC'"
	  	_sQuery += "   GROUP BY SE5.E5_FILIAL, SE5.E5_DATA, SE5.E5_BANCO"
   
	    _sQuery += " UNION ALL"
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL, '99'  AS DATA ,   'TOTAL DA FILIAL',"
	  	_sQuery += " 	    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	  	_sQuery += " 	    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	  	_sQuery += " 	  FROM " + RetSQLName ("SE5") + " AS SE5"
	  	_sQuery += "      	WHERE SE5.D_E_L_E_T_ = ''"
	  	_sQuery += "        AND SE5.E5_DATA     BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	  	_sQuery += "        AND SE5.E5_RECPAG  = 'P'"
	  	_sQuery += "        AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	  	_sQuery += "	    AND SE5.E5_BANCO   NOT IN ('', 'CX1','999','C/C') "
     	_sQuery += "		AND SE5.E5_CONTA   !='.'"
	  	_sQuery += "		AND SE5.E5_MOEDA   != 'M1'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'DESP BANC'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'VERBAS'"
	  	_sQuery += "		AND SE5.E5_TIPODOC != 'TR'"
	  	_sQuery += "		AND SE5.E5_TIPO    != 'NCC'"
	  	_sQuery += "   GROUP BY SE5.E5_FILIAL"
	    	    
	    _sQuery += " UNION ALL "
	    _sQuery += " SELECT '99' AS FILIAL, ''  AS DATA ,   'TOTAL GERAL',"
	  	_sQuery += " 	    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	  	_sQuery += " 	    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	  	_sQuery += " 	  FROM " + RetSQLName ("SE5") + " AS SE5"
	  	_sQuery += "      	WHERE SE5.D_E_L_E_T_ = ''"
	  	_sQuery += "        AND SE5.E5_DATA     BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	  	_sQuery += "        AND SE5.E5_RECPAG  = 'P'"
	  	_sQuery += "        AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	  	_sQuery += "	    AND SE5.E5_BANCO   NOT IN ('', 'CX1','999','C/C') "
     	_sQuery += "		AND SE5.E5_CONTA   !='.'"
	  	_sQuery += "		AND SE5.E5_MOEDA   != 'M1'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'DESP BANC'"
	  	_sQuery += "		AND SE5.E5_NATUREZ != 'VERBAS'"
	  	_sQuery += "		AND SE5.E5_TIPODOC != 'TR'"
	  	_sQuery += "		AND SE5.E5_TIPO    != 'NCC'"
	  	_sQuery += "   ORDER BY SE5.E5_FILIAL, SE5.E5_DATA" 
    
    	//u_showmemo (_sQuery)
    	
    	_aDados := U_Qry2Array(_sQuery)
	    if len(_aDados) > 0 
	    	_aCols = {}
	    	
		   	aadd (_aCols, {1,  "Filial"       	   ,  10,  "@!"})
		   	aadd (_aCols, {2,  "Data"       	   ,  20,  "@D"})
		   	aadd (_aCols, {3,  "Banco"      	   ,  30,  "@D"})
		   	aadd (_aCols, {4,  "Titulos"           ,  10,  "@!"})
		   	aadd (_aCols, {5,  "Vlr Movimentado"   ,  50,  "@E 99,999,999.99"})
		   			    	
	    	U_F3Array (_aDados, "Consulta pagamentos por Bancos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
		else
			u_help("Não foram encontrados dados para consulta")
		endif
	endif	
return     
     
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Data emissao de              ?", "D", 8, 0,  "",   "   ", {},                        "Data inicial de digitacao dos conhecimentos de frete"})
	aadd (_aRegsPerg, {02, "Data emissao ate             ?", "D", 8, 0,  "",   "   ", {},                        "Data final de digitacao dos conhecimentos de frete"})
	U_ValPerg (cPerg, _aRegsPerg)
Return
