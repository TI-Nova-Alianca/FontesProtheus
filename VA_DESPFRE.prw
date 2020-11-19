// Programa...: VA_DESPFRE
// Autor......: Catia Cardoso
// Data.......: 02/02/2018
// Descricao..: Altera tipo de despesa de frete
//
// Historico de alteracoes:
//
// 05/02/2018 - Catia - tratamento do tipo de despesa de frete 5=transferencia

#include 'totvs.ch'

User Function VA_DESPFRE()
	
	//Local cArqTRB  	:= ""
	//Local cInd1   	 := ""
	//Local nI       	:= 0
	//Local aStruct 	 := {}
	//Local aHead 	:= {}
	Local i			:= 0
	cPerg   := "VA_DESPFRE"
	
	if ! u_zzuvl ('032', __cUserId, .T.)
		return
	endif
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 
    
    	if mv_par12 = mv_par13
			msgalert ("Parametros de Tipo de Despesa não devem ser iguais.")
			_ValidPerg()
		endif
		
		if mv_par01 > mv_par02
			msgalert ("Intervalo de datas inválido.")
			_ValidPerg()
		endif
		
		do case
			case mv_par12 == 1
				_wdescold = "ENTREGA"
			case mv_par12 == 2
				_wdescold = "REENTREGA"
			case mv_par12 == 3
				_wdescold = "REDESPACHO"						
			case mv_par12 == 4
				_wdescold = "PALETIZAÇAO"
			case mv_par12 == 5
				_wdescold = "TRANSFERENCIA"
						
		endcase
		
		do case
			case mv_par13 == 1
				_wdescnew = "ENTREGA"
			case mv_par13 == 2
				_wdescnew = "REENTREGA"
			case mv_par13 == 3
				_wdescnew = "REDESPACHO"						
			case mv_par13 == 4
				_wdescnew = "PALETIZAÇAO"
			case mv_par12 == 5
				_wdescold = "TRANSFERENCIA"				
		endcase			    	    
    	    
    	_sQuery := ""
	    _sQuery += " SELECT ''"
	    _sQuery += "     , SZH.ZH_NFSAIDA   AS NOTA"
     	_sQuery += "     , SZH.ZH_SERNFS    AS SERIE"
     	_sQuery += "     , dbo.VA_DTOC(SD2.D2_EMISSAO)      AS DT_EMISSAO"
	 	_sQuery += "     , SD2.D2_CLIENTE   AS COD_CLI"
		_sQuery += "     , SD2.D2_LOJA      AS LOJA_CLI" 
		_sQuery += "     , SA1.A1_NOME      AS NOME_CLI"
		_sQuery += "	 , SZH.ZH_NFFRETE   AS NRO_CONH"
	    _sQuery += "  	 , SZH.ZH_SERFRET   AS SER_CONH"
	    _sQuery += "     , dbo.VA_DTOC(SF1.F1_EMISSAO)   AS EMI_CONH"
	    _sQuery += "	 , SZH.ZH_FORNECE   AS FORN_CONH"
		_sQuery += "	 , SZH.ZH_LOJA      AS LOJA_CONH"
		_sQuery += "	 , SA2.A2_NOME      AS NOME_FORN"
		_sQuery += "     , SA1.A1_MUN       AS CID_CLI"
		_sQuery += "     , SA1.A1_EST       AS UF_CLI"
		// 1=Entrega;2=Reentrega;3=Redespacho;4=Paletizacao;5=Frete sobre devolucoes
		_sQuery += "	 , CASE WHEN SZH.ZH_TPDESP='1' THEN 'ENTREGA' 
		_sQuery += "	        WHEN SZH.ZH_TPDESP='2' THEN 'REENTREGA'
		_sQuery += "	        WHEN SZH.ZH_TPDESP='3' THEN 'REDESPACHO'
		_sQuery += "	        WHEN SZH.ZH_TPDESP='4' THEN 'PALETIZACAO'
		_sQuery += "	   END AS DESPESA"
		_sQuery += "	 , SF2.F2_PBRUTO AS PESO_BRUTO"
		_sQuery += "	 , SUM(SZH.ZH_RATEIO) AS VLR_FRETE"
		_sQuery += "	 , SUM(SD2.D2_TOTAL)+SUM(SD2.D2_VALIPI)+SUM(SD2.D2_ICMSRET) AS VLR_BRUT"
		_sQuery += "	 , CASE WHEN SF2.F2_PBRUTO > 0 THEN ROUND( SUM(SZH.ZH_RATEIO) / SF2.F2_PBRUTO , 2) ELSE 0 END AS FRETE_KG"
		_sQuery += "	 , SZH.ZH_TPDESP"
		_sQuery += "  FROM " + RetSQLName ("SZH") + " AS SZH "
  	    _sQuery += "    INNER JOIN " + RetSQLName ("SD2") + " AS SD2 "
  		_sQuery += "		ON (SD2.D_E_L_E_T_ = ''"
		_sQuery += "			AND SD2.D2_FILIAL  = SZH.ZH_FILIAL"
		_sQuery += "			AND SD2.D2_DOC     = SZH.ZH_NFSAIDA"
		_sQuery += "			AND SD2.D2_SERIE   = SZH.ZH_SERNFS"
		_sQuery += "			AND SD2.D2_ITEM    = SZH.ZH_ITNFS"
		_sQuery += "		 	AND SD2.D2_CLIENTE BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
   		_sQuery += "            AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "')"
   		_sQuery += "    INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  		_sQuery += "		ON (SF2.D_E_L_E_T_ = ''"
		_sQuery += "			AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
		_sQuery += "			AND SF2.F2_DOC     = SD2.D2_DOC"
		_sQuery += "			AND SF2.F2_SERIE   = SD2.D2_SERIE"
		_sQuery += "		 	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
   		_sQuery += "            AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
   		_sQuery += "	INNER JOIN SF4010 AS SF4"
		_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES"
  		_sQuery += "			    AND SF4.F4_MARGEM IN ('1','3') )"
   		_sQuery += "    INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
  		_sQuery += "	 	ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += "		 	AND SA1.A1_COD  = SD2.D2_CLIENTE"
		if mv_par07 != '  ' .and. mv_par07 != 'zz' .and. mv_par07 != 'ZZ' 
			_sQuery += "        AND SA1.A1_EST = '" + mv_par07 + "'"
		endif	
		_sQuery += "		 	AND SA1.A1_LOJA = SD2.D2_LOJA )"
		_sQuery += "    INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
  		_sQuery += "	 	ON (SA2.D_E_L_E_T_ = ''"
		_sQuery += "		 	AND SA2.A2_COD  = SZH.ZH_FORNECE"
		_sQuery += "		 	AND SA2.A2_LOJA = SZH.ZH_LOJA )"
		_sQuery += "     LEFT JOIN " + RetSQLName ("SA4") + " AS SA4 "
  		_sQuery += "	 	ON (SA4.D_E_L_E_T_ = ''
		_sQuery += "		 	AND SA4.A4_VAFORN  = SZH.ZH_FORNECE"
     	_sQuery += "	     	AND SA4.A4_VALOJA  = SZH.ZH_LOJA"
     	_sQuery += "	     	AND SA4.A4_COD    != 704"
		_sQuery += "		 	AND SA4.A4_COD BETWEEN '" + mv_par08 + "' and '" + mv_par09 + "')"
   		_sQuery += "     LEFT JOIN " + RetSQLName ("SF1") + " AS SF1 "
  		_sQuery += "	 	ON (SF1.D_E_L_E_T_ = ''"
		_sQuery += "		 	AND SF1.F1_FILIAL  = SZH.ZH_FILIAL"
		_sQuery += "		 	AND SF1.F1_DOC     = SZH.ZH_NFFRETE"
		_sQuery += "		 	AND SF1.F1_SERIE   = SZH.ZH_SERFRET"
		_sQuery += "		 	AND SF1.F1_FORNECE = SZH.ZH_FORNECE)"
 		_sQuery += "  WHERE SZH.D_E_L_E_T_ = ''"
   		_sQuery += "	AND SZH.ZH_FILIAL  = '" + xfilial ("SZH") + "'"
   		_sQuery += "	AND SZH.ZH_NFSAIDA BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
    	_sQuery += "	AND SZH.ZH_NFFRETE BETWEEN '" + mv_par10 + "' and '" + mv_par11 + "'"
    	_sQuery += "	AND SZH.ZH_TPFRE  = 'S'"
    	_sQuery += "	AND SZH.ZH_TPDESP = '" + str(mv_par12,1) + "'"
    	_sQuery += " GROUP BY SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SD2.D2_EMISSAO, SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_MUN, SA1.A1_EST, SF2.F2_PBRUTO, SZH.ZH_NFFRETE, SZH.ZH_SERFRET, SZH.ZH_TPDESP, SF1.F1_EMISSAO, SZH.ZH_FORNECE, SZH.ZH_LOJA, SA2.A2_NOME, SA4.A4_COD, SA4.A4_NOME, SF1.F1_VAFLAG, SF1.F1_VAUSER"
	    
	    //u_showmemo(_sQuery)
	    
		_aDados := U_Qry2Array(_sQuery)
		_aColsMB = {}
		
		aadd (_aColsMB, {2,  "Num.Nota." 		, 30,  "@!"})
		aadd (_aColsMB, {3,  "Serie"   			, 10,  "@!"})
		aadd (_aColsMB, {4,  "Emissao Nota"     , 30,  "@D"})
		aadd (_aColsMB, {5,  "Cliente"      	, 30,  "@!"})
		aadd (_aColsMB, {6,  "Loja"    			, 10,  "@!"})
		aadd (_aColsMB, {7,  "Razao Social"  	, 70,  "@!"})
		aadd (_aColsMB, {8,  "CONH"     		, 30,  "@!"})
		aadd (_aColsMB, {9,  "Serie"    		, 10,  "@!"})
		aadd (_aColsMB, {10, "Emissao CONH"     , 40,  "@D"})
		aadd (_aColsMB, {11, "Fornecedor" 		, 30,  "@!"})
		aadd (_aColsMB, {12, "Loja"    			, 10,  "@!"})
		aadd (_aColsMB, {13, "Razao Social"  	, 70,  "@!"})
		aadd (_aColsMB, {14, "Cidade"        	, 30,  "@!"})
		aadd (_aColsMB, {15, "UF"     			, 10,  "@!"})
		aadd (_aColsMB, {16, "Tipo Despesa"     , 30,  "@!"})
		aadd (_aColsMB, {17, "Peso Nota"        , 50,  "@E 9,999,999.99"})
		aadd (_aColsMB, {18, "Valor Frete"      , 50,  "@E 9,999,999.99"})
		aadd (_aColsMB, {19, "Valor Nota"       , 50,  "@E 9,999,999.99"})
		aadd (_aColsMB, {20, "Frete_KG"      	, 50,  "@E 9,999,999.99"})
		
		for i=1 to len(_aDados)
			_aDados[i,1] = .F.
			if _aDados[i,11] = 'S'
				_aDados[i,1] = .T.
			endif
		next

		U_MBArray (@_aDados,"Conhecimentos a alterar TIPO DE DESPESA de:  " + _wdescold + "  para  " + _wdescnew, _aColsMB, 1,  oMainWnd:nClientWidth - 50 ,550, ".T.")
	
		for i=1 to len(_aDados)
			
			// os selecionados para alterar, alterar via UPDATE a SZH pq sao varios lctos
			if _aDados[i,1]= .T.
			
				_sSQL := ""
				_sSQL += " UPDATE SZH010"
				_sSQL += "    SET ZH_TPDESP  = '" + str(mv_par13,1) + "'"
				_sSQL += "  WHERE D_E_L_E_T_ = ''"
   				_sSQL += "    AND ZH_FILIAL  = '" + xfilial ("SZH") + "'"
   				_sSQL += "    AND ZH_FORNECE = '" + _aDados[i,11] + "'"
   				_sSQL += "    AND ZH_LOJA    = '" + _aDados[i,12] + "'"
   				_sSQL += "    AND ZH_NFFRETE = '" + _aDados[i,8]  + "'"
   				_sSQL += "    AND ZH_NFSAIDA = '" + _aDados[i,2]  + "'"
				
				if TCSQLExec (_sSQL) < 0
		            u_showmemo(_sSQL)
		            return
				endif	            
	        endif
	                    
		next
	endif		
Return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Emissao Notas de       ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Emissao Notas até      ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "NF de                       ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {04, "NF ate                      ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {05, "Cliente de                  ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {06, "Cliente ate                 ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {07, "UF                          ?", "C", 2, 0,  "",   "12 ", {},  ""})
	aadd (_aRegsPerg, {08, "Transportadora de           ?", "C", 6, 0,  "",   "SA4", {},  ""})
	aadd (_aRegsPerg, {09, "Transportadora ate          ?", "C", 6, 0,  "",   "SA4", {},  ""})
	aadd (_aRegsPerg, {10, "Conhecimento de             ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {11, "Conhecimento ate            ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {12, "Despesa Frete ATUAL         ?", "N", 1, 0,  "",   "   ", {"Entrega","Reentrega","Redespacho","Paletização","Transferência"},  ""})
	aadd (_aRegsPerg, {13, "Despesa Frete NOVA          ?", "N", 1, 0,  "",   "   ", {"Entrega","Reentrega","Redespacho","Paletização","Transferência"},  ""})
	
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
