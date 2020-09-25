//  Programa...: VA_NFFOBXCONH
//  Autor......: Catia Cardoso
//  Data.......: 28/02/2019
//  Descricao..: Consulta Saidas AMARRACAO DE CONH X NOTAS SAIDA FRETE FOB 
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_NFFOBXCONH()
	
	_sQuery := ""
	_sQuery += " SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, SF2.F2_VALBRUT"
    _sQuery += "  	  , SF2.F2_TPFRETE"
    _sQuery += "  	  , SF2.F2_TRANSP"
	_sQuery += "  	  , SA4.A4_NOME"
	_sQuery += "  	  , SF1.F1_DOC"
	_sQuery += "  	  , SF1.F1_SERIE"
	_sQuery += "  	  , SF1.F1_FORNECE"
	_sQuery += "  	  , SA2.A2_NOME"
	_sQuery += "  	  , SF1.F1_VALBRUT"
	_sQuery += "   FROM SF2010 AS SF2"
	_sQuery += " 		INNER JOIN SZH010 AS SZH"
	_sQuery += " 			ON (SZH.D_E_L_E_T_ = ''"
	_sQuery += " 	    		AND SZH.ZH_FILIAL  = SF2.F2_FILIAL"
	_sQuery += " 				AND SZH.ZH_TPFRE  = 'S'"
	_sQuery += " 				AND SZH.ZH_NFSAIDA = SF2.F2_DOC"
	_sQuery += " 				AND SZH.ZH_SERNFS  = SF2.F2_SERIE"
	_sQuery += " 				AND SZH.ZH_ITNFS   = '01')"
	_sQuery += " 		INNER JOIN SA4010 AS SA4"
	_sQuery += " 			ON (SA4.D_E_L_E_T_ = ''"
	_sQuery += " 				AND SA4.A4_COD     = SF2.F2_TRANSP)"
	_sQuery += " 		INNER JOIN SF1010 AS SF1"
	_sQuery += " 			ON (SF1.D_E_L_E_T_ = ''"
	_sQuery += " 				AND SF1.F1_FILIAL  = SZH.ZH_FILIAL"
	_sQuery += " 				AND SF1.F1_DOC     = SZH.ZH_NFFRETE"
	_sQuery += " 				AND SF1.F1_SERIE   = SZH.ZH_SERFRET"
	_sQuery += " 				AND SF1.F1_FORNECE = SZH.ZH_FORNECE"
	_sQuery += " 				AND SF1.F1_LOJA    = SZH.ZH_LOJA)"
	_sQuery += " 		INNER JOIN SA2010 AS SA2"
	_sQuery += " 			ON (SA2.D_E_L_E_T_ = ''"
	_sQuery += " 				AND SA2.A2_COD     = SF1.F1_FORNECE"
	_sQuery += " 				AND SA2.A2_LOJA    = SF1.F1_LOJA)"
	_sQuery += "   WHERE SF2.D_E_L_E_T_ = ''"
	_sQuery += " 	 AND SF2.F2_FILIAL  = '01'"
	_sQuery += "     AND SF2.F2_TPFRETE = 'F'
	_sQuery += " 	 AND SF2.F2_EMISSAO >= '20190101'"	
	//u_showmemo (_sQuery)
	
	_aDados := U_Qry2Array(_sQuery)
	if len(_aDados) > 0 
		_aCols = {}
	
    	aadd (_aCols, { 1, "Num.Nota"      	   ,  30,  "@!"})
    	aadd (_aCols, { 2, "Serie"         	   ,  10,  "@!"})
    	aadd (_aCols, { 3, "Emissao Nota"      ,  30,  "@D"})
    	aadd (_aCols, { 4, "Total Nota"    	   ,  50,  "@E 9,999,999.9999"})
    	aadd (_aCols, { 5, "Tp.Frete"          ,  10,  "@!"})
    	aadd (_aCols, { 6, "Transportador"     ,  10,  "@!"})
    	aadd (_aCols, { 7, "Transp.Nome"       ,  40,  "@!"})
    	aadd (_aCols, { 8, "Conhecimento"  	   ,  30,  "@!"})
    	aadd (_aCols, { 9, "Serie"         	   ,  10,  "@!"})
    	aadd (_aCols, {10, "Fornecedor"        ,  30,  "@!"})
    	aadd (_aCols, {11, "Fornec.Nome"   	   ,  40,  "@!"})
		aadd (_aCols, {12, "Vlr.Conhecimento"  ,  50,  "@E 9,999,999.9999"})
        
		U_F3Array (_aDados, "Consulta Conhecimentos em NF Frete FOB", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
	else
		msgalert("Não foram encontrados dados para consulta")
	endif    		
	
return
