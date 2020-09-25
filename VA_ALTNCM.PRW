//  Programa...: VA_POSIPI
//  Autor......: Catia Cardoso
//  Data.......: 25/04/2017
//  Descricao..: Altera NCM dos produtos 
// 
//  Historico de alterações
//  04/02/2020 - Andre  - Adicionado filtro por Produto. B1_COD.
//

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_POSIPI()
	local i	:= 0

	cPerg   := "VA_POSIPI"
	
	if ! u_zzuvl ('019', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina.")
		return
	endif
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.) 
    	_sQuery := " "
		_sQuery += "SELECT B1_COD"
  		_sQuery += "  FROM SB1010
 		_sQuery += " WHERE B1_COD    = '" + mv_par01 + "'" 
 		_sQuery += "   AND B1_POSIPI = '" + mv_par02 + "'"
 		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
    		for i=1 to len(_aDados)
    			_wproduto = _aDados[i,1]
		    	// grava log de alteração
				_oEvento:= ClsEvent():new ()
				_oEvento:CodEven   = "ALT001"
				_oEvento:Texto	   = "Alterado NCM, rotina VA_ALTNCM" 
				_oEvento:Texto     += " De " + mv_par02 + " para " + mv_par03
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
						SB1->B1_POSIPI   = mv_par03  
			    	MsUnLock()
				endif	    	
			next
			Alert("Alteração de NCM's concluída.")
		else
			Alert("Não foi encontrado nenhum produto com essa NCM.")													
		endif
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Produto        ?", "C", 15, 0,  "",   "SB1", {},  ""})
    aadd (_aRegsPerg, {02, "NCM Atual      ?", "C", 10, 0,  "",   "SYD", {},  ""})
    aadd (_aRegsPerg, {03, "Nova NCM       ?", "C", 10, 0,  "",   "SYD", {},  ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
