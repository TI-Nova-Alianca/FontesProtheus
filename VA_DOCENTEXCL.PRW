//  Programa...: VA_EXCENT
//  Autor......: Catia Cardoso
//  Data.......: 03/10/2018
//  Descricao..: Consulta Documentos de Entrada EXCLUIDOS p/Periodo 
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_EXCENT()

	cPerg   := "VA_EXCENT"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	_sQuery := ""
    	_sQuery += " SELECT ZBA.ZBA_FILIAL"
    	_sQuery += " 	  , ZBA.ZBA_FORNEC, SA2.A2_NOME, SA2.A2_EST"
    	_sQuery += " 	  , ZBA.ZBA_CHAVE"
    	_sQuery += " 	  , ZBA.ZBA_DOC, ZBA.ZBA_SERIE, ZBA.ZBA_ESPEC"
    	_sQuery += " 	  , ZBA.ZBA_DATA, ZBA.ZBA_HORA"
    	_sQuery += " 	  , ZBA.ZBA_MOT, ZBA.ZBA_JUSTIF"
    	_sQuery += " 	  , ZBA.ZBA_USER"
    	_sQuery += "   FROM ZBA010 AS ZBA"
    	_sQuery += " 	  INNER JOIN SA2010 AS SA2"
		_sQuery += " 		ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += " 			AND SA2.A2_COD  = ZBA.ZBA_FORNEC"
		_sQuery += " 			AND SA2.A2_LOJA = ZBA.ZBA_LOJA)"
		_sQuery += " 	  INNER JOIN ZX5010 AS ZX5"
		_sQuery += " 		ON (ZX5.D_E_L_E_T_     = ''"
		_sQuery += " 			AND ZX5.ZX5_TABELA = '48'"
        _sQuery += "     		AND ZX5.ZX5_48MOT  = ZBA.ZBA_MOT)"
        _sQuery += "  WHERE ZBA.D_E_L_E_T_ = ''"
        _sQuery += "    AND ZBA.ZBA_DATA BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
        _sQuery += " ORDER BY ZBA_DATA, ZBA.ZBA_DOC, ZBA.ZBA_SERIE"
    	
   		//u_showmemo (_sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
    		aadd (_aCols, { 1, "Filial"         	,  30,  "@!"})
    		aadd (_aCols, { 2, "Fornecedor"         ,  30,  "@!"})
	    	aadd (_aCols, { 3, "Razão Social"   	, 150,  "@!"})
			aadd (_aCols, { 4, "Estado"       	    ,  20,  "@!"})
			aadd (_aCols, { 5, "Chave"          	, 150,  "@!"})
    		aadd (_aCols, { 6, "Num.Nota"       	,  30,  "@!"})
    		aadd (_aCols, { 7, "Serie"          	,  10,  "@!"})
    		aadd (_aCols, { 8, "Especie"       	    ,  30,  "@!"})
	    	aadd (_aCols, { 9, "Data"               ,  30,  "@D"})
	    	aadd (_aCols, {10, "Hora"               ,  30,  "@!"})
	    	aadd (_aCols, {11, "Motivo"             ,  30,  "@!"})
			aadd (_aCols, {12, "Justificativa" 	    , 100,  "@!"})
			aadd (_aCols, {13, "Usuário" 	        ,  50,  "@!"})
	        
    		U_F3Array (_aDados, "Consulta Documentos de Entrada Excluídos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
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
    aadd (_aRegsPerg, {01, "Data Inicial     ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Final       ?", "D", 8, 0,  "",   "   ", {},  ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return