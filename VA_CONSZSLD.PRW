//  Programa...: VA_CONSZSLD
//  Autor......: Catia Cardoso
//  Data.......: 24/04/2018
//  Descricao..: Controle de Verbas - Consulta Verbas que tiveram o saldo a bonificar zerado 
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_CONSZSLD()

	cPerg   := "CONSZSLD"
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.)
	
		// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
    	_sQuery := ""
    	_sQuery += " SELECT ZA5.ZA5_DTA, ZA5.ZA5_NUM, ZA5.ZA5_CLI, ZA5.ZA5_LOJA"
	 	_sQuery += "      , ( SELECT A1_NOME"
	    _sQuery += "   			FROM SA1010 AS SA1"
		_sQuery += "  		   WHERE SA1.D_E_L_E_T_  = ''"
		_sQuery += "    		 AND SA1.A1_COD  = ZA5.ZA5_CLI"
		_sQuery += "    		 AND SA1.A1_LOJA = ZA5.ZA5_LOJA) AS CLIENTE"
		
     	_sQuery += "	  , ( SELECT ZA4.ZA4_VLR"
	    _sQuery += "   			FROM ZA4010 AS ZA4"
	    _sQuery += " 				INNER JOIN SA1010 AS SA1"
		_sQuery += "    				ON (SA1.D_E_L_E_T_      = ''"
		_sQuery += "        				AND SA1.A1_COD      = ZA5.ZA5_CLI"
		_sQuery += "        				AND SA1.A1_VACBASE  = ZA4.ZA4_CLI"
		_sQuery += "        				AND SA1.A1_VALBASE  = ZA4.ZA4_LOJA"
		_sQuery += " 	   					AND SA1.A1_LOJA     = ZA5.ZA5_LOJA)"
 		_sQuery += "  		   WHERE ZA4.D_E_L_E_T_  = ''"
		_sQuery += "    		 AND ZA4.ZA4_NUM  = ZA5.ZA5_NUM) AS VLR_VERBA"
		_sQuery += "	  , ZA5_VLR"
		_sQuery += "	  , ZA5_USU"
  		_sQuery += "   FROM ZA5010 AS ZA5"
 		_sQuery += "  WHERE ZA5.ZA5_TLIB = '9'"
    	 
    	 //u_showmemo (_sQuery)
    	_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0
    	
    		_aCols = {}
    	
    		aadd (_aCols, {01, "Data Zeramento"    		,  20,  "@D"})
	    	aadd (_aCols, {02, "Num.Verba"       		,  10,  "@!"})
	    	aadd (_aCols, {03, "Cliente"        		,  30,  "@!"})
	    	aadd (_aCols, {04, "Loja"           		,  10,  "@!"})
	    	aadd (_aCols, {05, "Razão Social"   		, 140,  "@!"})
	    	aadd (_aCols, {06, "Valor da Verba"	    	,  60,  "@E 999,999.99"})
	    	aadd (_aCols, {07, "Valor do Zeramento Sld" ,  60,  "@E 999,999.99"})
	    	aadd (_aCols, {08, "Usuário"                ,  80,  "@!"})
			    		
		    U_F3Array (_aDados, "Consulta Verbas que tirevam saldos zerado", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
			
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
    aadd (_aRegsPerg, {01, "Cliente de          ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate         ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Data Zeramento Sld  ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {04, "Data Zeramento Sld  ?", "D", 8, 0,  "",   "   ", {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
