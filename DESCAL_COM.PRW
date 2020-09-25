//  Programa...: DESCAL_COM	
//  Autor......: Catia Cardoso
//  Data.......: 03/02/2016
//  Descricao..: Descalcula Comissão
//
//  Alterações:

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function DESCAL_COM()
	Local i := 0
	cPerg   := "DESCAL_COM"
	
	if ! u_zzuvl ('048', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar estar rotina.")
		return
	endif
		
	_ValidPerg()
    if Pergunte(cPerg,.T.)
    	// gera array com os dados dos vendedores selecionados 
    	_sQuery := " "
    	_sQuery += " SELECT A3_COD, A3_FORNECE" 
   	 	_sQuery += "   FROM SA3010"
 		_sQuery += "  WHERE D_E_L_E_T_ = ''"
   		_sQuery += "    AND A3_COD BETWEEN'" + mv_par02 + "' AND'" + mv_par03 + "'"
   		
	    _aDados := U_Qry2Array(_sQuery)
	    if len(_aDados) > 0	    	
   		  	for i=1 to len(_aDados)
    			_wvendedor   = _aDados[i,1]
    			_wfornecedor = _aDados[i,2]
    			// testa se o titulos do financeiro ja não estão pagos
    			_sSQL := " "
    			_sSQL += " SELECT SUM(E2_SALDO)"
		    	_sSQL += "   FROM SE2010" // padrao
	 			_sSQL += "  WHERE E2_FILIAL  = '" + xFilial("SE3") + "'"
	   			_sSQL += "    AND E2_VENCTO  = '" + dtos (mv_par01) + "'"
	   			_sSQL += "    AND E2_FORNECE = '" + _wfornecedor + "'"
	   			_aSaldo := U_Qry2Array(_sQuery)
	   			if len(_aSaldo) > 0
					if val(_aSaldo[1,1]) = 0
						u_help ("Vendedor : " + _wvendedor + ", títulos de comissões já foram baixados. Não é possível descalcular a comissão.",, .t.)
						return
					endif						   			
	   			endif    		
				// zera data de comissão no SE3
		    	_sSQL := " "
		    	_sSQL += " UPDATE SE3010"  // padrao
	   			_sSQL += "    SET E3_DATA   = ''"
	 			_sSQL += "  WHERE E3_FILIAL = '" + xFilial("SE3") + "'"
	 			_sSQL += "    AND E3_DATA   = '" + dtos (mv_par01) + "'"
	   			_sSQL += "    AND E3_VEND   = '" + _wvendedor + "'"
	   			
	   			//u_showmemo(_sSQL)
	   			
	   			if TCSQLExec (_sSQL) < 0
             		return
       			endif
   			 	
   			 	// exclui titulos no SE2
	        	_sSQL := " "
		    	_sSQL += " DELETE SE2010" // padrao
	 			_sSQL += "  WHERE E2_FILIAL  = '" + xFilial("SE3") + "'"
	   			_sSQL += "    AND E2_VENCTO  = '" + dtos (mv_par01) + "'"
	   			_sSQL += "    AND E2_FORNECE = '" + _wfornecedor + "'"
	   			
	   			//u_showmemo(_sSQL)
	   			
	   			if TCSQLExec (_sSQL) < 0
             		return
       			endif
       			
        	next
		endif     	
	endif
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Data Prevista Pagamento      ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Representante de             ?", "C", 6, 0,  "",   "SA3", {},                        "Representante Inicial"})
    aadd (_aRegsPerg, {03, "Representante ate            ?", "C", 6, 0,  "",   "SA3", {},                        "Represenante Final"})
    
    U_ValPerg (cPerg, _aRegsPerg)
    
Return
