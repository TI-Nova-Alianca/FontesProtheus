// Programa...: VA_DELSN4
// Autor......: Catia Cardoso
// Data.......: 17/04/2018
// Descricao..: Delete registros indevidos no SN4  
//
// Historico de alteracoes:

#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function VA_DELSN4()
	local i	:= 0
	
	_lRet = U_MsgNoYes ("Confirma rotina para deletar itens indevidos na tabela SN4 ?")
	if _lRet = .F.
		return
	endif
	
	// BUSCA OS ITENS QUE PRECISAM SER TRATADOS - OCORRENCIA 05 EM DUPLICIDADE E COM ORIGEM ATFA012
	_sSQL := ""	
	_sSQL += " WITH C AS ("
	_sSQL += " 		SELECT N4_CBASE"
	_sSQL += "  		 , N4_ITEM"
	_sSQL += "  		 , N4_TIPO"
	_sSQL += "  		 , N4_OCORR"
	_sSQL += "  		 , COUNT(R_E_C_N_O_) AS QUANTAS"
  	_sSQL += " 		  FROM SN4010"
 	_sSQL += " 		 WHERE D_E_L_E_T_ = ''"
   	_sSQL += " 		   AND N4_OCORR   = '05'"
   	_sSQL += " 		   AND N4_CBASE != '0000005721'"
   	_sSQL += " 		   AND N4_CBASE != '0000006095'"
   	_sSQL += " 		   AND N4_CBASE != '9000006356'"
   	_sSQL += " 		   AND N4_CBASE != '9000006357'"
   	_sSQL += " 		   AND N4_CBASE != '9000006358'"
   	_sSQL += " 		   AND N4_CBASE != '9000006359'"
   	_sSQL += " 		   AND N4_CBASE != '9000006360'"
   	_sSQL += " 		   AND N4_CBASE != '9000006361'"
   	_sSQL += " 		   AND N4_CBASE != '9000006362'"
   	_sSQL += " 		   AND N4_CBASE != '9000006363'"
   	_sSQL += " 		   AND N4_CBASE != '9000006364'"
   	_sSQL += " 		   AND N4_CBASE != '9000006365'"
   	_sSQL += " 		   AND N4_CBASE != '9000006366'"
   	_sSQL += " 		   AND N4_CBASE != '9000006367'"
	_sSQL += " 		GROUP BY N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR"
	_sSQL += " 	)"
	_sSQL += " SELECT C.N4_CBASE"
	_sSQL += "      , C.N4_ITEM"
	_sSQL += "  	, C.N4_TIPO"
	_sSQL += "  	, C.N4_OCORR"
  	_sSQL += "   FROM C"
 	_sSQL += "  WHERE C.QUANTAS > 1"
	_sSQL += " ORDER BY N4_CBASE, N4_ITEM"
	_aDados := U_Qry2Array(_sSQL )
	if len(_aDados) > 0 
		for i=1 to len(_aDados)
			_wcbase = _aDados [i,1]
			_witem  = _aDados [i,2]
			_wtipo  = _aDados [i,3] 
			_wocor  = _aDados [i,4]
			_sSQL := ""	
			_sSQL += " SELECT R_E_C_N_O_"
	  		_sSQL += "   FROM SN4010"
	 		_sSQL += "  WHERE N4_CBASE  = '" + _wcbase + "'" 
	   		_sSQL += "    AND N4_ITEM   = '" + _witem + "'"
	   		_sSQL += "    AND N4_TIPO   = '" + _wtipo + "'"
	   		_sSQL += "    AND N4_OCORR  = '" + _wocor + "'"
	   		_sSQL += "    AND N4_ORIGEM = 'ATFA012'"
	   		_aExclui := U_Qry2Array(_sSQL )
	   		if len(_aExclui) = 1
	   			_wrecno = _aExclui[1,1] 
	   		elseif len(_aExclui) > 1
	   			_sSQL := ""	
				_sSQL += " SELECT MAX(R_E_C_N_O_)"
	  			_sSQL += "   FROM SN4010"
	 			_sSQL += "  WHERE N4_CBASE  = '" + _wcbase + "'" 
	   			_sSQL += "    AND N4_ITEM   = '" + _witem + "'"
	   			_sSQL += "    AND N4_TIPO   = '" + _wtipo + "'"
	   			_sSQL += "    AND N4_OCORR  = '" + _wocor + "'"
	   			_sSQL += "    AND N4_ORIGEM = 'ATFA012'"
	   			_aExclui := U_Qry2Array(_sSQL )
	   			if len(_aExclui) = 1
	   				_wrecno = _aExclui[1,1]
				endif	   				 
	   		endif	
	   		// seleciona SN4
	   		dbSelectArea("SN4")
			dbgoto(_wrecno)
	   		// delete a registro
	   		reclock ("SN4", .F.)
				dbdelete ()
			msunlock ()
		next
	endif			   			
return
