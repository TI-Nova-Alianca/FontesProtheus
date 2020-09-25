// Programa...: VA_CUSTPER
// Autor......: Catia Cardoso
// Data.......: 18/08/2015
// Descricao..: Custo de itens no perído
//
// Historico de alteracoes:

#include 'totvs.ch'

user function VA_CUSTPER()
	
	cPerg   := "VA_LMCRED"
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 
	
		_sSQL := " "
		_sSQL += " SELECT SB9.B9_FILIAL"
     	_sSQL += "      , ' ' + SB9.B9_COD"
	 	_sSQL += "      , SB1.B1_DESC"
	 	_sSQL += "      , SB1.B1_UM"
	 	_sSQL += "      , SB1.B1_TIPO"
	 	_sSQL += "      , SB9.B9_QINI"
	 	_sSQL += "      , ROUND(B9_VINI1/B9_QINI,7)"
  		_sSQL += "   FROM SB9010 AS SB9"
		_sSQL += "      INNER JOIN SB1010 AS SB1"
   		_sSQL += "         ON (SB1.D_E_L_E_T_ = ''"
       	_sSQL += "             AND SB1.B1_COD           = SB9.B9_COD"
	    _sSQL += "             AND SB1.B1_TIPO IN ('ME', 'PS', 'MP') )"
 		_sSQL += "  WHERE SB9.D_E_L_E_T_ = ''"
   		_sSQL += "    AND SB9.B9_DATA = '" + dtos(mv_par01) + "'"
   		_sSQL += "    AND SB9.B9_QINI > 0"
    
		_aDados := U_Qry2Array(_sSQL)
    	_aCols = {}
    	aadd (_aCols, {1,  "Filial"        , 30,  "@!"})
	    aadd (_aCols, {2,  "Produto"       , 30,  "@!"})
	    aadd (_aCols, {3,  "Descricao"     , 140, "@!"})
	    aadd (_aCols, {4,  "Unidade"       , 30,  "@!"})
	    aadd (_aCols, {5,  "Tipo"          , 40,  "@!"})
	    aadd (_aCols, {6,  "Quantidade"    , 40,  "@E 999,999.9999"})
	    aadd (_aCols, {7,  "Custo Periodo" , 20,  "@E 999,999.999999999"})
	    
    	U_F3Array (_aDados, "Consulta Custo do Período", _aCols, oMainWnd:nClientWidth - 50, NIL, "")
	endif    	
	
return   

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data final Período        ?", "D", 8, 0,  "",   "   ", {},""})
    U_ValPerg (cPerg, _aRegsPerg)
Return

