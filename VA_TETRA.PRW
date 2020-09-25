//  Programa...: VA_TETRA
//  Autor......: Catia Cardoso
//  Data.......: 27/06/2016
//  Descricao..: Conciliação BONUS Tetra Pack 
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_TETRA()

	cPerg   := "VA_TETRA"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT dbo.VA_DTOC(SD1.D1_DTDIGIT)  AS DTDIGIT"
	 	_sQuery += " 	  , dbo.VA_DTOC(SD1.D1_EMISSAO)  AS EMISSAO"
     	_sQuery += " 	  , SD1.D1_DOC, SD1.D1_FORNECE"
	 	_sQuery += " 	  , SD1.D1_COD, SD1.D1_DESCRI"
	 	_sQuery += " 	  , SD1.D1_UM, SD1.D1_QUANT"
	 	_sQuery += " 	  , SD1.D1_TOTAL, SD1.D1_VALIPI"
	 	_sQuery += "   FROM SD1010 AS SD1"
		_sQuery += "		INNER JOIN SF4010 AS SF4"
		_sQuery += "			ON (SF4.D_E_L_E_T_    = ''"
		_sQuery += "				AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += "				AND SF4.F4_DUPLIC = 'S' )"
 		_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
   		_sQuery += "	AND SD1.D1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   		_sQuery += "	AND SD1.D1_TIPO = 'N'"
   		_sQuery += "	AND SD1.D1_FORNECE IN ('004098', '004613', '005030')"
   		_sQuery += "	AND SD1.D1_DESCRI LIKE '%CARTONADA%'"
   		
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    		aadd (_aCols, { 1, "Diditação"  ,  40,  "@D"})
    		aadd (_aCols, { 2, "Emissao"    ,  40,  "@D"})
	    	aadd (_aCols, { 3, "Num.Nota"   ,  40,  "@!"})
	    	aadd (_aCols, { 4, "Fornecedor" ,  40,  "@!"})
	    	aadd (_aCols, { 5, "Produto"    ,  40,  "@D"})
	    	aadd (_aCols, { 6, "Descrição"  , 180,  "@!"})
	    	aadd (_aCols, { 7, "UM"         ,  20,  "@D"})
	    	aadd (_aCols, { 8, "Quantidade" ,  80,  "@E 99,999,999.99"})
	    	aadd (_aCols, { 9, "Vlr.Total"  ,  80,  "@E 99,999,999.99"})
			aadd (_aCols, {10, "Vlr.IPI"    ,  80,  "@E 99,999,999.99"})
	    	
    		U_F3Array (_aDados, "Consulta Notas de Resíduos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Emissao de       ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Emissao até      ?", "D", 8, 0,  "",   "   ", {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return