//  Programa...: VA_CEST
//  Autor......: Catia Cardoso
//  Data.......: 30/01/2018
//  Descricao..: Altera CEST dos produtos 
// 
//  Historico de alterações

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_CEST()
	local i	:= 0
	
	cPerg   := "VA_CEST"
	
	if ! u_zzuvl ('019', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina.")
		return
	endif
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.) 
    	_sQuery := " "
		_sQuery += "SELECT B1_COD"
  		_sQuery += "  FROM SB1010
 		_sQuery += " WHERE B1_CEST = '" + mv_par01 + "'"
 
 		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		for i=1 to len(_aDados)
    			_wproduto = _aDados[i,1]
		    	// grava log de alteração
				_oEvento:= ClsEvent():new ()
				_oEvento:CodEven   = "ALT001"
				_oEvento:Texto	   = "Alterado CEST, rotina VA_CEST" 
				_oEvento:Texto     += " De " + mv_par01 + " para " + mv_par02
				_oEvento:Produto   = _wproduto
				_oEvento:Alias     = "SB1"
				_oEvento:Hist	   = "1"
				_oEvento:Status	   = "4"
				_oEvento:Sub	   = ""
				_oEvento:Prazo	   = 0
				_oEvento:Flag	   = .T.
				_oEvento:Grava ()
				// atualiza cadastro do produtos
				DbSelectArea("SB1")
				DbSetOrder(1)
				if DbSeek(xFilial("SB1")+ _wproduto,.F.)
					reclock("SB1", .F.)
						SB1->B1_CEST   = mv_par02  
			    	MsUnLock()
				endif	    	
			next
			Alert("Alteração de CEST concluída.")
		else
			Alert("Não foi encontrado nenhum produto com essa CEST.")													
		endif
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "CEST Atual      ?", "C", 10, 0,  "",   "F0G", {},  ""})
    aadd (_aRegsPerg, {02, "Novo CEST       ?", "C", 10, 0,  "",   "F0G", {},  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
