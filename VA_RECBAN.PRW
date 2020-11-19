// Programa...: VA_	RECBAN
// Autor......: Andre Alves
// Data.......: 03/08/2018
// Descricao..: Consultas Recebimentos em Banco
//
// ------------------------------------------------------------------------------------------------
// Historico de alteracoes:

// ------------------------------------------------------------------------------------------------
User Function VA_RECBAN ()
    cPerg    := "VA_RECBAN"
    
    _ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
        
/*	    _sQuery := ""
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL, SE5.E5_DATA AS DATA,"
	    _sQuery += " 	(SELECT TOP 1 A6_NOME"
	    _sQuery += "    FROM " + RetSQLName ("SA6") + " AS SA6"
	    _sQuery += "	WHERE A6_COD = SE5.E5_BANCO"
	    _sQuery += "    AND A6_BLOCKED = '2') AS DESCRICAO,"
	    _sQuery += "    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	    _sQuery += "    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	    _sQuery += "	    FROM " + RetSQLName ("SE5") + " AS SE5"
	    _sQuery += "		WHERE SE5.D_E_L_E_T_  = ''"
	    _sQuery += "		AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += "		AND SE5.E5_RECPAG   = 'R'"
	    _sQuery += "		AND SE5.E5_ARQCNAB != ''"
	    _sQuery += "		AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	    _sQuery += "    GROUP BY SE5.E5_FILIAL, SE5.E5_DATA, SE5.E5_BANCO"
	    
	    _sQuery += " UNION ALL"
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL, '99'  AS DATA,  'TOTAL DA FILIAL',"
	    _sQuery += "    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	    _sQuery += "    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	    _sQuery += "	    FROM " + RetSQLName ("SE5") + " AS SE5"
	    _sQuery += "		WHERE SE5.D_E_L_E_T_  = ''"
	    _sQuery += "		AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += "		AND SE5.E5_RECPAG   = 'R'"
	    _sQuery += "		AND SE5.E5_ARQCNAB != ''"
	    _sQuery += "		AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	    _sQuery += "    GROUP BY SE5.E5_FILIAL"
	    
	    _sQuery += " UNION ALL"
	    _sQuery += " SELECT '99' AS FILIAL, ''  AS DATA ,   'TOTAL GERAL',"
	    _sQuery += "    COUNT(R_E_C_N_O_) AS QTDE_TITULOS,"
	    _sQuery += "    SUM(E5_VALOR) AS VLO_MOVIMENTADO"
	    _sQuery += "	    FROM " + RetSQLName ("SE5") + " AS SE5"
	    _sQuery += "		WHERE SE5.D_E_L_E_T_  = ''"
	    _sQuery += "		AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += "		AND SE5.E5_RECPAG   = 'R'"
	    _sQuery += "		AND SE5.E5_ARQCNAB != ''"
	    _sQuery += "		AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	    _sQuery += " ORDER BY SE5.E5_FILIAL, SE5.E5_DATA" */
	    
	    _sQuery := ""
	    _sQuery := "WITH C AS("
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL,SE5.E5_DATA AS DATA,"
	    _sQuery += " 	(SELECT TOP 1 A6_NOME"
	    _sQuery += "    FROM " + RetSQLName ("SA6") + " AS SA6"
	    _sQuery += "	WHERE A6_COD = SE5.E5_BANCO"
	    _sQuery += "    AND A6_BLOCKED = '2') AS DESCRICAO,"
	    _sQuery += "    COUNT(R_E_C_N_O_) AS QTDE_TIT_COBR,"
	    _sQuery += "    SUM(E5_VALOR)     AS VLR_MOV_COBR, 0 AS QTDE_TIT_DEP, 0 AS VLR_MOV_DEP"
	    _sQuery += "	    FROM " + RetSQLName ("SE5") + " AS SE5"
	    _sQuery += "		WHERE SE5.D_E_L_E_T_  = ''"
	    _sQuery += "		AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += "		AND SE5.E5_RECPAG   = 'R'"
	    _sQuery += "		AND SE5.E5_ARQCNAB != ''"
	    _sQuery += "		AND SE5.E5_TIPODOC NOT IN ('DC','JR')"
	    _sQuery += "    GROUP BY SE5.E5_FILIAL, SE5.E5_DATA, SE5.E5_BANCO"
	    
	    _sQuery += " UNION ALL"
	    _sQuery += " SELECT SE5.E5_FILIAL AS FILIAL, SE5.E5_DATA AS DATA,"
	    _sQuery += "   (SELECT TOP 1 A6_NOME"
	    _sQuery += "	  FROM " + RetSQLName ("SA6") + " AS SA6"
	    _sQuery += "      WHERE A6_COD = SE5.E5_BANCO"
    	_sQuery += "        AND A6_BLOCKED = '2')"
    	_sQuery += "        AS DESCRICAO,0 AS QTDE_TIT_COBR, 0 AS VLR_MOV_COBR, "
	    _sQuery += "		COUNT(R_E_C_N_O_) AS QTDE_TIT_DEP,"
	    _sQuery += "		SUM(E5_VALOR)     AS VLR_MOV_DEP"
	    _sQuery += "	  FROM " + RetSQLName ("SE5") + " AS SE5"
	    _sQuery += "        WHERE SE5.D_E_L_E_T_ = ''"
	    _sQuery += "		AND SE5.E5_DATA    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += "        AND SE5.E5_VALOR > 0"
        _sQuery += "        AND SE5.E5_RECPAG = 'R'"
        _sQuery += "        AND SE5.E5_ARQCNAB = ''"
        _sQuery += "        AND SE5.E5_BANCO != 'CX1'"
        _sQuery += "        AND SE5.E5_CLIENTE != ''"
        _sQuery += "        AND SE5.E5_TIPO NOT IN ('R$','NCC','VP')"
        _sQuery += "        AND SE5.E5_TIPODOC NOT IN ('DC','JR','TR','BA','CP','ES')"
        _sQuery += "    GROUP BY SE5.E5_FILIAL, SE5.E5_DATA, SE5.E5_BANCO)"
	    _sQuery += " SELECT C.FILIAL, C.DATA, C.DESCRICAO,"
	    _sQuery += "    SUM(C.QTDE_TIT_COBR) AS QTDE_TIT_COBR,"
	    _sQuery += "    SUM(C.VLR_MOV_COBR)  AS VLR_MOV_COBR,"
	    _sQuery += "    SUM(C.QTDE_TIT_DEP)  AS QTDE_TIT_DEP,"
	    _sQuery += "    SUM(C.VLR_MOV_DEP)   AS VLR_MOV_DEP"
	    _sQuery += "    FROM C "
	    _sQuery += "	GROUP BY C.FILIAL, C.DATA, C.DESCRICAO"
   	    
	    _aDados := U_Qry2Array(_sQuery)
	    if len(_aDados) > 0 
	    	_aCols = {}
	    	
		   	aadd (_aCols, {1,  "Filial"       	   ,  10,  "@!"})
		   	aadd (_aCols, {2,  "Data"              ,  10,  "@!"})
		   	aadd (_aCols, {3,  "Banco"      	   ,  30,  "@D"})
		   	aadd (_aCols, {4,  "Qtde Tit Cobr"     ,  10,  "@!"})
		   	aadd (_aCols, {5,  "Vlr Mov Cobr"      ,  50,  "@E 99,999,999.99"})
		   	aadd (_aCols, {6,  "Qtde Tit Dep"      ,  50,  "@E 99,999,999.99"})
		   	aadd (_aCols, {7,  "Vlr Mov Dep"       ,  50,  "@E 99,999,999.99"})
		    	
	    	U_F3Array (_aDados, "Consulta valores de recebimento em bancos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
	aadd (_aRegsPerg, {01, "Data emissao de              ?", "D", 8, 0,  "",   "   ", {},                        "Data inicial"})
	aadd (_aRegsPerg, {02, "Data emissao ate             ?", "D", 8, 0,  "",   "   ", {},                        "Data final"})
	U_ValPerg (cPerg, _aRegsPerg)
Return
