//  Programa...: ML_PRPEDIDOS
//  Autor......: Catia Cardoso
//  Data.......: 22/09/2015
//  Descricao..: Consulta preços praticados nos pedidos 
// 
//  Historico de alterações
//
// -------------------------------------------------------------------------------------  
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_PRPEDIDOS()

	cPerg   := "ML_PRPEDIDOS"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	// seleciona clientes com dta de vencimento de credito igual informada no parametro 01 
    	_sQuery := ""
    	_sQuery += " SELECT SC6.C6_CLI, SA1.A1_NOME AS NOM_CLI, dbo.VA_DTOC(SC6.C6_DATFAT) as DTFAT"
		_sQuery += "      , SC6.C6_NUM, SC6.C6_PRODUTO, SC6.C6_DESCRI, SC6.C6_PRCVEN, SC6.C6_NOTA"
     	_sQuery += "      , SF2.F2_TPFRETE"
     	_sQuery += "      , CASE WHEN SC6.C6_DATFAT = '' THEN '0' ELSE '1' END AS ORDEN"
  		_sQuery += "   FROM SC6010 AS SC6"
		_sQuery += " 		INNER JOIN SA1010 AS SA1"
		_sQuery += " 			ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SA1.A1_COD  = SC6.C6_CLI"
		_sQuery += " 				AND SA1.A1_LOJA = SC6.C6_LOJA)"
		_sQuery += " 		LEFT JOIN SF2010 AS SF2"
		_sQuery += " 			ON (SF2.D_E_L_E_T_ =''"
		_sQuery += " 				AND SF2.F2_FILIAL  = SC6.C6_FILIAL"
		_sQuery += " 				AND SF2.F2_DOC     = SC6.C6_NOTA"
		_sQuery += " 				AND SF2.F2_CLIENTE = SC6.C6_CLI"
		_sQuery += " 				AND SF2.F2_LOJA    = SC6.C6_LOJA)"
 		_sQuery += " WHERE SC6.D_E_L_E_T_ = ''"
 		_sQuery += "   AND (SC6.C6_DATFAT='' OR SC6.C6_DATFAT   BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "')"
 		_sQuery += "   AND SC6.C6_CLI      BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
   		_sQuery += "   AND SC6.C6_PRODUTO  BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
    	_sQuery += " ORDER BY ORDEN, SC6.C6_CLI, SC6.C6_DATFAT DESC, SC6.C6_PRODUTO"
    	
    	//u_showmemo (_sQuery)
    	
    	_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		_aCols = {}
    	
	    	aadd (_aCols, {1,  "Cliente"       	       ,  30,  "@!"})
	    	aadd (_aCols, {2,  "Razão Social"      	   , 150,  "@!"})
	    	aadd (_aCols, {3,  "Emissao"      	       ,  50,  "@D"})
	    	aadd (_aCols, {4,  "Pedido"        	       ,  50,  "@!"})
	    	aadd (_aCols, {5,  "Produto"           	   ,  30,  "@!"})
	    	aadd (_aCols, {6,  "Descricao"   	       , 150,  "@!"})
			aadd (_aCols, {7,  "Preço Venda"   	  	   ,  80,  "@E 9,999,999.99"})
			aadd (_aCols, {8,  "Num Nota"          	   ,  50,  "@!"})
	    	aadd (_aCols, {9,  "Tipo Frete"      	   ,  10,  "@D"})
	    
    		U_F3Array (_aDados, "Consulta Preços Praticados nos Pedidos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
		else
			msgalert("Não foram encontrados dados no intervalo digitado.")
		endif    		
	endif
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Faturamento      ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Fturamento       ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Cliente de            ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {04, "Cliente ate           ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {05, "Produto de            ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {06, "Produto ate           ?", "C", 6, 0,  "",   "SB1", {},  ""})
	
	
    U_ValPerg (cPerg, _aRegsPerg)
Return