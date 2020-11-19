//  Programa...: VA_CTABMASTER
//  Autor......: Catia Cardoso
//  Data.......: 03/11/2016
//  Descricao..: Compara tabela do cliente com a tabela MASTER 
// 
//  Historico de alterações
//  09/06/2017 - Catia - rotina desabilitada - a principio não é mais usada
//  06/03/2019 - Catia - alterado para que busque o percentual de rapel da tabela nova e nao do cadastro de cliente  
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_CTABMASTER()

	cPerg   := "VA_CTABMASTER"
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.)
    	if mv_par01 = ''
    		u_help("Necessario informar o cliente")
    		return
		endif   
		_wcliente = mv_par01
    	_wloja    = mv_par02
    	if _wloja = ''
    		 _wloja = '01'
    	endif
    	
		// define tabela do cliente
    	_wclitab   = fBuscaCpo ('SA1', 1, xfilial('SA1') + _wcliente + _wloja, "A1_TABELA")
    	if _wclitab = ''
    		u_help("Cliente sem tabela de preço para comparação")
    		return
		endif
		
		// monta consulta  
		//_pfrete     := FBuscaCpo("SA1",1,XFILIAL("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VAPFRE")
		  		
    	_sQuery := " "
    	_sQuery += " SELECT CLI.DA1_CODPRO AS PROD_COD"
    	_sQuery += " 	  , SB1.B1_DESC AS PROD_DESC"
    	_sQuery += " 	  , SB1.B1_CUSTD AS PROD_CUSTO"
		_sQuery += " 	  , ZX5.ZX5_39PERC AS MARGEM"
		_sQuery += "      , dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) AS CLI_RAPEL" 
	 	_sQuery += "      , SA3.A3_COMIS AS COMIS"
	 	_sQuery += "      , CASE WHEN SA1.A1_EST IN (' " + GETMV("MV_NORTE") + " ') THEN 7 WHEN SA1.A1_EST = 'RS' THEN 18 WHEN SA1.A1_EST != 'RS' THEN 12 END AS CRED_ICMS"
	 	_sQuery += " 	  , 3.2 AS PISFOC"
		_sQuery += " 	  , A1_VAPFRE"
		_sQuery += " 	  , 1.5 AS FINAN"
		_sQuery += "      , ( 100 - (ZX5.ZX5_39PERC + SA1.A1_VAPFRE + dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) + SA3.A3_COMIS  + (CASE WHEN SA1.A1_EST IN (' " + GETMV("MV_NORTE") + " ') THEN 7 WHEN SA1.A1_EST = 'RS' THEN 18 WHEN SA1.A1_EST != 'RS' THEN 12 END) + 3.2 + 1.5))/100 AS MARKUP"
		_sQuery += "      , SB1.B1_CUSTD / ((100 - (ZX5.ZX5_39PERC + SA1.A1_VAPFRE + dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) + SA3.A3_COMIS  + (CASE WHEN SA1.A1_EST IN (' " + GETMV("MV_NORTE") + " ') THEN 7 WHEN SA1.A1_EST = 'RS' THEN 18 WHEN SA1.A1_EST != 'RS' THEN 12 END) + 3.2 + 1.5))/100) AS PR_MIN"
		_sQuery += " 	  , CLI.DA1_PRCVEN AS CLI_PR"
		_sQuery += " 	  , TMPSC6.PR_PRATICADO"
    	//_sQuery += " 	  , MAST.DA1_PRCVEN AS MAST_PR"
    	//_sQuery += " 	  , (1 - ((SB1.B1_CUSTD / (( 100 - (ZX5.ZX5_39PERC + SA1.A1_VAPFRE + dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) + SA3.A3_COMIS + (CASE WHEN SA1.A1_EST IN (' " + GETMV("MV_NORTE") + " ') THEN 7 WHEN SA1.A1_EST = 'RS' THEN 18 WHEN SA1.A1_EST != 'RS' THEN 12 END) + 3.2 + 1.5))/100)) / MAST.DA1_PRCVEN)) * 100 AS DESCONTO"
    	_sQuery += " 	  , dbo.VA_DTOC(TMPSC6.ULT_VENDA)"
    	_sQuery += " 	  , CASE WHEN (SB1.B1_CUSTD / (( 100 - (ZX5.ZX5_39PERC + SA1.A1_VAPFRE + dbo.VA_FRAPELPADRAO (SA1.A1_COD, SA1.A1_LOJA, SB1.B1_COD) + SA3.A3_COMIS + (CASE WHEN SA1.A1_EST IN (' AC/AL/AM/AP/BA/CE/DF/ES/GO/MA/MS/MT/PA/PB/PE/PI/SE/RN/RO/RR/TO ') THEN 7 WHEN SA1.A1_EST = 'RS' THEN 18 WHEN SA1.A1_EST != 'RS' THEN 12 END) + 3.2 + 1.5))/100)) > CLI.DA1_PRCVEN THEN 'REVER PR TABELA CLIENTE' END AS CONSID" 	  
  		_sQuery += "      , CASE WHEN CLI.DA1_PRCVEN > TMPSC6.PR_PRATICADO THEN 'REVER PRECO PRATICADO' ELSE ' ' END AS CONSID1"
    	_sQuery += " 	  , SA1.A1_COD AS CLI_COD"
    	_sQuery += " 	  , SA1.A1_NOME AS CLI_NOME"
    	_sQuery += " 	  , CLI.DA1_CODTAB AS CLI_TAB"
    	_sQuery += "   FROM DA1010 AS CLI"
		_sQuery += " 		LEFT JOIN DA1010 AS MAST"
		_sQuery += " 			ON (MAST.D_E_L_E_T_ = ''"
		_sQuery += " 				AND MAST.DA1_CODTAB = '990'"
		_sQuery += " 				AND MAST.DA1_CODPRO = CLI.DA1_CODPRO)"
		_sQuery += " 		INNER JOIN SB1010 AS SB1"
		_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "				AND SB1.B1_COD = CLI.DA1_CODPRO)
		_sQuery += "   		INNER JOIN ZX5010 AS ZX5"
		_sQuery += "   			ON (ZX5.ZX5_TABELA = '39'"
		_sQuery += "   				AND ZX5.ZX5_39COD = SB1.B1_CODLIN)"
		_sQuery += " 		INNER JOIN SA1010 AS SA1"
		_sQuery += " 			ON (SA1.A1_COD = '" + _wcliente  + "'"
		_sQuery += "				AND SA1.A1_LOJA = '" + _wloja  + "'"
		_sQuery += "				AND SA1.D_E_L_E_T_ = '')"
		_sQuery += "		INNER JOIN SA3010 AS SA3"
		_sQuery += "			ON (SA3.A3_COD = SA1.A1_VEND"
		_sQuery += "				AND SA3.D_E_L_E_T_ = '')"
		_sQuery += "		LEFT JOIN (SELECT MAX(SC6.C6_PRCVEN)  AS PR_PRATICADO"
		_sQuery += "                         , SC6.C6_PRODUTO"
		_sQuery += "                         , MAX(SC6.C6_DATFAT)  AS ULT_VENDA"
		_sQuery += "					  FROM SC6010 AS SC6"
		_sQuery += "					 WHERE SC6.C6_CLI    = '" + _wcliente  + "'"
		_sQuery += "					   AND SC6.C6_DATFAT > '20151101'"
		_sQuery += "					GROUP BY SC6.C6_PRODUTO) AS TMPSC6"
		_sQuery += " 			ON (TMPSC6.C6_PRODUTO = CLI.DA1_CODPRO)"
		_sQuery += "  WHERE CLI.D_E_L_E_T_ = ''"
   		_sQuery += "    AND CLI.DA1_CODTAB = '" + _wclitab + "'"
		_sQuery += " ORDER BY SB1.B1_COD"
		
		//u_showmemo(_sQuery)
		
		_aDados := U_Qry2Array(_sQuery)
		if len(_aDados) > 0 
			do while .t.
				_aCols = {}
	
    			aadd (_aCols, {1,  "PRODUTO"        ,  30,  "@!"})
		    	aadd (_aCols, {2,  "DESCRICAO"      , 100,  "@!"})
		    	aadd (_aCols, {3,  "CUSTO"          ,  50,  "@E 9,999,999.99"})
		    	aadd (_aCols, {4,  "MARGEM"         ,  35,  "@E 999.99"})
		    	aadd (_aCols, {5,  "RAPEL(26.13)"   ,  35,  "@E 999.99"})
		    	aadd (_aCols, {6,  "COMIS(10)"      ,  35,  "@E 999.99"})
		    	aadd (_aCols, {7,  "ICMS(18)"       ,  35,  "@E 999.99"})
		    	aadd (_aCols, {8,  "PISCOF(3.2)"    ,  35,  "@E 999.99"})
		    	aadd (_aCols, {9,  "FRETE(8)"       ,  35,  "@E 999.99"})
		    	aadd (_aCols,{10,  "FINANC(1.5)"    ,  35,  "@E 999.99"})
		    	aadd (_aCols,{11,  "MARKUP"         ,  35,  "@E 99.9999"})
		    	aadd (_aCols,{12,  "PR_MINIMO_CLI"  ,  50,  "@E 9,999,999.99"})
		    	aadd (_aCols,{13,  "PR_TAB_ATUAL_CLI" ,  50, "@E 9,999,999.99"})
		    	aadd (_aCols,{14,  "PR_PRATICADO"   ,  50, "@E 9,999,999.99"})
		    	//aadd (_aCols,{15,  "PR_TAB_MASTER"  ,  50,  "@E 9,999,999.99"})
		    	//aadd (_aCols,{16,  "%DESCONTO_CLI"  ,  50,  "@E 9999.99"})
		    	aadd (_aCols,{15,  "ULT.VENDA"      ,  50,  "@D"})
		    	aadd (_aCols,{16,  "CONSIDERAR"     , 100,  "@!"})
		    	aadd (_aCols,{17,  "CONSIDERAR"     , 100,  "@!"})
		    	aadd (_aCols,{18,  "CLIENTE"        ,  50,  "@!"})
		    	aadd (_aCols,{19,  "NOME"           , 150,  "@!"})
		    	aadd (_aCols,{20,  "TAB ATUAL CLIENTE" ,  50,  "@!"})
		    	
				_wlinha = U_F3Array (_aDados, "Compara Tabela Master X Tabela Cliente", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )

				if _wlinha = 0
					exit
				endif
			enddo				
		
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
    aadd (_aRegsPerg, {01, "Codigo do Cliente      ?", "C", 6, 0,  "",   "SA1", {},  ""})
    aadd (_aRegsPerg, {02, "Loja                   ?", "C", 2, 0,  "",   ""   , {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
