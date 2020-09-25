// Programa...: VA_RAPEL
// Autor......: Catia Cardoso
// Data.......: 08/06/2017
// Descricao..: Função que busca o rapel do cliente
//
// Historico de alteracoes:
// 06/11/2017 - Robert - Passa a buscar via funcao do SQL para compatibilidade com views do banco.
//

//#include "protheus.ch"                       
//#include 'totvs.ch'

User Function VA_RAPEL (_wcliente,_wloja,_wproduto)
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _wrapel   := 0
/*
    // busca a linha do produto
    _wlinha = fBuscaCpo ('SB1', 1, xfilial('SB1') + _wproduto, "B1_CLINF")
    if _wlinha != ''
	    // procura rapel por cliente/linha/item
	    _sSQL := ""
	    _sSQL += " SELECT ZAX_PRAPEL"
	  	_sSQL += "   FROM ZAX010"
	 	_sSQL += "  WHERE ZAX_CLIENT = '" + _wcliente + "'"
	   	_sSQL += "    AND ZAX_LOJA   = '" + _wloja + "'"
	   	_sSQL += "    AND ZAX_LINHA  = '" + _wlinha + "'"
	   	_sSQL += "    AND ZAX_ITEM   = '" + _wproduto + "'"
	   	aDados := U_Qry2Array(_sSQL)
    	if len (aDados) = 1
    		_wrapel = aDados[1,1] 
    	endif
    	if _wrapel = 0
		    // procura rapel por cliente/linha
		    _sSQL := ""
		    _sSQL += " SELECT ZAX_PRAPEL"
		  	_sSQL += "   FROM ZAX010"
		 	_sSQL += "  WHERE ZAX_CLIENT = '" + _wcliente + "'"
		   	_sSQL += "    AND ZAX_LOJA   = '" + _wloja + "'"
		   	_sSQL += "    AND ZAX_LINHA  = '" + _wlinha + "'"
		   	_sSQL += "    AND ZAX_ITEM   = ''"
		   	aDados := U_Qry2Array(_sSQL)
	    	if len (aDados) = 1
	    		_wrapel = aDados[1,1] 
	    	endif
		endif	    	
    endif
    if _wrapel = 0
	    // procura rapel por cliente/item
	    _sSQL := ""
	    _sSQL += " SELECT ZAX_PRAPEL"
	  	_sSQL += "   FROM ZAX010"
	 	_sSQL += "  WHERE ZAX_CLIENT = '" + _wcliente + "'"
	   	_sSQL += "    AND ZAX_LOJA   = '" + _wloja + "'"
	   	_sSQL += "    AND ZAX_LINHA  = ''"
		_sSQL += "    AND ZAX_ITEM   = '" + _wproduto + "'"
	   	aDados := U_Qry2Array(_sSQL)
    	if len (aDados) = 1
    		_wrapel = aDados[1,1] 
    	endif
    endif
    if _wrapel = 0
	    // procura rapel por cliente
	    _sSQL := ""
	    _sSQL += " SELECT ZAX_PRAPEL"
	  	_sSQL += "   FROM ZAX010"
	 	_sSQL += "  WHERE ZAX_CLIENT = '" + _wcliente + "'"
	   	_sSQL += "    AND ZAX_LOJA   = '" + _wloja + "'"
	   	_sSQL += "    AND ZAX_LINHA  = ''"
		_sSQL += "    AND ZAX_ITEM   = ''"
	   	aDados := U_Qry2Array(_sSQL)
    	if len (aDados) = 1
    		_wrapel = aDados[1,1] 
    	endif
    endif
*/
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_FRAPELPADRAO ('" + _wcliente + "','" + _wloja + "','" + _wproduto + "')"
	//_oSQL:Log ()
	_wRapel = _oSQL:RetQry (1, .F.)

	U_ML_SRArea (_aAreaAnt)
Return _wrapel