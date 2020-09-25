//  Programa...: ML_CLIXBASE
//  Autor......: Catia Cardoso
//  Data.......: 16/06/2015
//  Descricao..: Consulta Clientes X Codigo Matriz ou codigo base 
// 
//  Historico de alterações
//  

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_CLIXBASE()

	cPerg   := "ML_CLIXBASE"
	_ValidPerg()
	
	if Pergunte(cPerg,.T.) 
		_wmatriz = fBuscaCpo ('SA1', 1, xfilial('SA1') + mv_par01 + '01', "A1_VACBASE")
    	// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
    	_sQuery := " "
    	_sQuery += " SELECT SA1.A1_COD       AS CLI_COD"
    	_sQuery += "      , SA1.A1_LOJA      AS CLI_LOJA"
    	_sQuery += "      , SA1.A1_NOME      AS CLI_NOME"
    	_sQuery += "      , SA1.A1_NREDUZ    AS CLI_REDUZ"
     	_sQuery += "      , SA1.A1_MUN       AS CLI_MUN"
		_sQuery += "      , SA1.A1_EST       AS CLI_RS"
		_sQuery += "	  , CASE WHEN SA1.A1_MSBLQL='1' THEN 'Sim'"
		_sQuery += "			 WHEN SA1.A1_MSBLQL='2' THEN 'Não'"
		_sQuery += "	    ELSE '' END AS CLI_ATIVO"
		_sQuery += "      , SA1.A1_VACBASE     AS MTZ_COD"
		_sQuery += "      , SA1.A1_VALBASE     AS MTZ_LOJA"
		_sQuery += "      , SBASE.A1_NOME      AS MTZ_NOME"
        _sQuery += "      , SBASE.A1_MUN       AS MTZ_MUN"
        _sQuery += "      , SBASE.A1_EST       AS MTZ_EST"
        _sQuery += "	  , CASE WHEN SBASE.A1_MSBLQL='1' THEN 'Sim'"
		_sQuery += "			 WHEN SBASE.A1_MSBLQL='2' THEN 'Não'"
		_sQuery += "	    ELSE '' END AS MTZ_ATIVO"
		_sQuery += "   FROM " + RetSQLName ("SA1") + " AS SA1 "
		_sQuery += "      LEFT JOIN SA1010 AS SBASE"
		_sQuery += "     	ON (SBASE.D_E_L_E_T_  = ''"
		_sQuery += "     		AND SBASE.A1_COD  = SA1.A1_VACBASE"
		_sQuery += "     		AND SBASE.A1_LOJA = SA1.A1_VALBASE)"
  	    _sQuery += "  WHERE SA1.D_E_L_E_T_ = ''"
  	    _sQuery += "    AND SA1.A1_VACBASE !=''"
  	    if mv_par02 == 2
  	    	_sQuery += "	AND SA1.A1_MSBLQL='2'"
  	    endif
  	    _sQuery += "	AND SA1.A1_COD = '" + mv_par01 + "'"
  	    if val(_wmatriz) > 0
  	    	_sQuery += " UNION ALL"
  	    	_sQuery += " SELECT SA1.A1_COD       AS CLI_COD"
    		_sQuery += "      , SA1.A1_LOJA      AS CLI_LOJA"
    		_sQuery += "      , SA1.A1_NOME      AS CLI_NOME"
    		_sQuery += "      , SA1.A1_NREDUZ    AS CLI_REDUZ"
     		_sQuery += "      , SA1.A1_MUN       AS CLI_MUN"
			_sQuery += "      , SA1.A1_EST       AS CLI_RS"
			_sQuery += "	  , CASE WHEN SA1.A1_MSBLQL='1' THEN 'Sim'"
			_sQuery += "			 WHEN SA1.A1_MSBLQL='2' THEN 'Não'"
			_sQuery += "	    ELSE '' END AS CLI_ATIVO"
			_sQuery += "      , SA1.A1_VACBASE     AS MTZ_COD"
			_sQuery += "      , SA1.A1_VALBASE     AS MTZ_LOJA"
			_sQuery += "      , SBASE.A1_NOME      AS MTZ_NOME"
        	_sQuery += "      , SBASE.A1_MUN       AS MTZ_MUN"
        	_sQuery += "      , SBASE.A1_EST       AS MTZ_EST"
        	_sQuery += "	  , CASE WHEN SBASE.A1_MSBLQL='1' THEN 'Sim'"
			_sQuery += "			 WHEN SBASE.A1_MSBLQL='2' THEN 'Não'"
			_sQuery += "	    ELSE '' END AS MTZ_ATIVO"
			_sQuery += "   FROM " + RetSQLName ("SA1") + " AS SA1 "
			_sQuery += "      LEFT JOIN SA1010 AS SBASE"
			_sQuery += "     	ON (SBASE.D_E_L_E_T_  = ''"
			_sQuery += "     		AND SBASE.A1_COD  = SA1.A1_VACBASE"
			_sQuery += "     		AND SBASE.A1_LOJA = SA1.A1_VALBASE)"
  	    	_sQuery += "  WHERE SA1.D_E_L_E_T_ = ''"
  	    	_sQuery += "    AND SA1.A1_VACBASE = '" + _wmatriz + "'"
		endif
		if mv_par02 == 2
  	    	_sQuery += "	AND SA1.A1_MSBLQL='2'"
  	    endif			  	    	 
   		_sQuery += " ORDER BY SA1.A1_VACBASE , SA1.A1_COD"
   		
    	//u_showmemo (_sQuery)
    	
    	_aDados := U_Qry2Array(_sQuery)
    	_aCols = {}
    	
    	aadd (_aCols, {1,  "Cliente"        	 ,  30,  "@!"})
    	aadd (_aCols, {2,  "LJ"           	     ,  10,  "@!"})
    	aadd (_aCols, {3,  "Razão Social"   	 , 120,  "@!"})
    	aadd (_aCols, {4,  "Nome Fantasia"   	 ,  90,  "@!"})
    	aadd (_aCols, {5,  "Cidade"       	     ,  90,  "@!"})
    	aadd (_aCols, {6,  "UF"         	     ,  20,  "@!"})
    	aadd (_aCols, {7,  "Bloqueado"     	     ,  30,  "@!"})
    	aadd (_aCols, {8,  "Matriz"              ,  30,  "@!"})
    	aadd (_aCols, {9,  "LJ"                  ,  10,  "@!"})
    	aadd (_aCols, {10,  "Razão Social Matriz" , 120,  "@!"})
		aadd (_aCols, {11, "Cidade"     	     ,  90,  "@!"})
    	aadd (_aCols, {12, "UF"          	     ,  20,  "@!"})
    	aadd (_aCols, {13, "Bloqueado"  	     ,  25,  "@!"})
    	U_F3Array (_aDados, "Consulta Clientes X REDES", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )

	endif
	
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
	aadd (_aRegsPerg, {01, "Cliente              ?", "C", 6, 0,  "!empty(mv_par01)",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Considera Bloqueados ?", "C", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return