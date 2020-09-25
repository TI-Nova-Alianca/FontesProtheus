// Programa...: VA_FRETES
// Autor......: Catia Cardoso
// Data.......: 08/12/2015
// Descricao..: Consultas Fretes que ainda nao foram digitados no sistema
//
// ------------------------------------------------------------------------------------------------
// Historico de alteracoes:

// ------------------------------------------------------------------------------------------------
User Function VA_FRETES ()
    cPerg    := "VA_FRETES"
    
    _ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
        
	    _sQuery := ""
	    _sQuery += " WITH C AS ("
	    _sQuery += " SELECT SD2.D2_DOC          AS NOTA"
	  	_sQuery += "   	  , SD2.D2_SERIE        AS SERIE"
	  	_sQuery += " 	  , dbo.VA_DTOC(SD2.D2_EMISSAO)  AS DT_EMISSAO"
	  	_sQuery += " 	  , SD2.D2_CLIENTE      AS CLIENTE"
	  	_sQuery += " 	  , SD2.D2_LOJA         AS LOJA"
	  	_sQuery += " 	  , SA1.A1_NOME         AS NOME_CLI"
	  	_sQuery += " 	  , SF2.F2_TRANSP       AS TRANSPORTADOR"
	  	_sQuery += " 	  , SA4.A4_NOME         AS NOMETRANSP"
	  	_sQuery += "      , SF2.F2_TPFRETE      AS TPFRETE"
	  	_sQuery += "      , ISNULL(SUM(SZH1.RATEIO),0)    AS VLR_FRETE"
	  	_sQuery += "      , SZH1.ZH_NFSAIDA     AS NF_FRETE"
	  	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
	  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	  	_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
	  	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
	  	_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
	  	_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
	  	_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
	  	_sQuery += "				AND SF2.F2_LOJA    = SD2.D2_LOJA"
	  	_sQuery += "				AND SF2.F2_TRANSP != '032'"
	  	_sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
		_sQuery += "	INNER JOIN SF4010 AS SF4"
		_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES"
	  	_sQuery += "			    AND SF4.F4_MARGEM IN ('1','3') )"
	  	_sQuery += "	 LEFT JOIN SA1010 AS SA1"
		_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
		_sQuery += "				AND SA1.A1_LOJA  = SD2.D2_LOJA)"
		_sQuery += "     LEFT JOIN (SELECT SUM(SZH.ZH_RATEIO) AS RATEIO"
		_sQuery += "     			     , SZH.ZH_FILIAL"
		_sQuery += "     				 , SZH.ZH_NFSAIDA"
		_sQuery += "     				 , SZH.ZH_SERNFS"
		_sQuery += "     				 , SZH.ZH_ITNFS"
		_sQuery += "                  FROM " + RetSQLName ("SZH") + " SZH"
		_sQuery += "			     WHERE SZH.D_E_L_E_T_ = ''"
		_sQuery += "		  		 GROUP BY SZH.ZH_FILIAL, SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SZH.ZH_ITNFS) AS SZH1"
		_sQuery += "             ON (SZH1.ZH_FILIAL        = SD2.D2_FILIAL"		  		 
		_sQuery += "    			 AND SZH1.ZH_NFSAIDA   = SD2.D2_DOC"
		_sQuery += "    			 AND SZH1.ZH_SERNFS    = SD2.D2_SERIE"
		_sQuery += "    			 AND SZH1.ZH_ITNFS     = SD2.D2_ITEM)"
		_sQuery += "	LEFT JOIN SA4010 AS SA4"
		_sQuery += "			ON (SA4.D_E_L_E_T_ = ''"
		_sQuery += "				AND SA4.A4_COD     = SF2.F2_TRANSP)"
		_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	    _sQuery += "   AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
	    _sQuery += "   AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    _sQuery += " GROUP BY SD2.D2_FILIAL, SD2.D2_DOC ,SD2.D2_SERIE, SD2.D2_EMISSAO, SD2.D2_CLIENTE , SD2.D2_LOJA, SA1.A1_NOME, SF2.F2_TRANSP, SA4.A4_NOME, SF2.F2_TPFRETE, SZH1.ZH_NFSAIDA"
	    _sQuery += " )"
	    _sQuery += " SELECT *"
	    _sQuery += " FROM C"
	    _sQuery += " WHERE C.VLR_FRETE = 0"
	    _sQuery += "   AND C.NF_FRETE IS NULL"
	    _sQuery += "   AND C.TPFRETE   = 'C'"
    
    	//u_showmemo(_sQuery)
    	
    	_aDados := U_Qry2Array(_sQuery)
	    if len(_aDados) > 0 
	    	_aCols = {}
	    	
		   	aadd (_aCols, {1,  "Num.Nota"       	   ,  30,  "@!"})
		   	aadd (_aCols, {2,  "Serie"          	   ,  10,  "@!"})
		   	aadd (_aCols, {3,  "Emissao Nota"      	   ,  30,  "@D"})
		   	aadd (_aCols, {4,  "Cliente"        	   ,  30,  "@!"})
		   	aadd (_aCols, {5,  "Loja"           	   ,  10,  "@!"})
		   	aadd (_aCols, {6,  "Razão Social"   	   , 150,  "@!"})
			aadd (_aCols, {7,  "Transportador da NF"   ,  30,  "@!"})
			aadd (_aCols, {8,  "Razão Social"   	   , 150,  "@!"})
		    	
	    	U_F3Array (_aDados, "Consulta Notas X Conhecimentos FALTANTES", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
		else
			msgalert("Não foram encontrados dados para consulta")
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