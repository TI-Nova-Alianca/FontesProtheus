//  Programa...: VA_ENTINS
//  Autor......: Catia Cardoso
//  Data.......: 29/01/2018
//  Descricao..: Consulta Entradas de Insumos - Auxiliar IBAMA 
// 
//  Historico de alterações
//
//  05/02/2018 - Catia - alterado para que considere notas de uso e consumo tambem
//  01/03/2018 - Catia - criado parametro para poder listar por grupo - no caso grupo de uvas
//  09/03/2018 - Catia - listar por grupo na grade

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_ENTINS()

	cPerg   := "VA_ENTINS"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += "SELECT SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_DTDIGIT, SD1.D1_FORNECE"
    	_sQuery += "     , SA2.A2_NOME"
    	_sQuery += "     , SD1.D1_COD, SD1.D1_DESCRI"
    	_sQuery += "     , SB1.B1_GRUPO"
    	_sQuery += "     , SBM.BM_DESC"
    	_sQuery += "     , SD1.D1_UM, SD1.D1_QUANT"
  		_sQuery += "  FROM SD1010 AS SD1"
		_sQuery += "	INNER JOIN SF4010 AS SF4"
		_sQuery += "		ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "			AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += "			AND SF4.F4_MARGEM IN ('1','8'))"
		_sQuery += "	INNER JOIN SA2010 AS SA2"
		_sQuery += "		ON (SA2.D_E_L_E_T_ = ''"
		_sQuery += "            AND SA2.A2_COD = SD1.D1_FORNECE)"
		_sQuery += "	INNER JOIN SB1010 AS SB1"
		_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "            AND B1_GRUPO BETWEEN  '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery += "            AND B1_COD = SD1.D1_COD)"
		_sQuery += "	INNER JOIN SBM010 AS SBM"
		_sQuery += "		ON (SBM.D_E_L_E_T_ = ''"
		_sQuery += "		    AND SBM.BM_GRUPO = SB1.B1_GRUPO)"
 		_sQuery += " WHERE SD1.D_E_L_E_T_ = ''" 
   		_sQuery += "   AND SD1.D1_FILIAL  = '"  + xfilial ("SD2") + "'" 
   		_sQuery += "   AND SD1.D1_QUANT > 0"
   		_sQuery += "   AND SD1.D1_DTDIGIT BETWEEN  '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   		_sQuery += "   AND SD1.D1_COD     BETWEEN  '" + mv_par03 + "' AND '" + mv_par04 + "'"

   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, { 1, "Num.Nota"       	,  30,  "@!"})
	    	aadd (_aCols, { 2, "Serie"          	,  10,  "@!"})
	    	aadd (_aCols, { 3, "Data Digitacao"     ,  30,  "@D"})
	    	aadd (_aCols, { 4, "Fornecedor"         ,  30,  "@!"})
	    	aadd (_aCols, { 5, "Razão Social"   	, 150,  "@!"})
			aadd (_aCols, { 6, "Produto"            ,  30,  "@!"})
	    	aadd (_aCols, { 7, "Descricao"          , 140,  "@!"})
	    	aadd (_aCols, { 8, "Grupo"              ,  30,  "@!"})
	    	aadd (_aCols, { 9, "Descricao"          ,  90,  "@!"})
	    	aadd (_aCols, {10, "UM Produto"         ,  30,  "@!"})
			aadd (_aCols, {11, "Quantidade"    	    ,  50,  "@E 9,999,999.9999"})
	        
    		U_F3Array (_aDados, "Consulta Entrada de Insumos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Data entrada de  ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data entrada até ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Item de          ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {04, "Item até         ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {05, "Grupo de         ?", "C", 4, 0,  "",   "SBM", {},  ""})
	aadd (_aRegsPerg, {06, "Grupo até        ?", "C", 4, 0,  "",   "SBM", {},  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return