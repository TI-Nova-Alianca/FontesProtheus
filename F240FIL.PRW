// Programa:   F240Fil
// Autor:      Catia Cardoso
// Data:       11/01/2016
// Descricao:  P.E. para filtragem do bordero a pagar
//
// Historico de alteracoes:
// 01/12/2017 - Robert - Criada possibilidade de informar expressao de filtro adicional.
//

#include "rwmake.ch"                                                                       
#include "protheus.ch"        

User Function F240fil()
	local _sAdic   := ''
	local _cFiltro := ''

	If cModPgto == "30" 
	    // liquidação de titulos do proprio banco
	    _cFiltro := " !EMPTY(E2_CODBAR)" 
	    //_cFiltro += " .AND. SUBSTR(E2_CODBAR,1,3)==" + "‘"+cPort240+"‘"
	    _cFiltro += " .AND. SUBSTR(E2_CODBAR,1,3)== '" + cPort240 + "'"
	    
	ElseIf cModPgto == "31"
	   // liquidação de titulos de outros bancos
	   _cFiltro := " !EMPTY(E2_CODBAR)" 
	   _cFiltro += " .AND. SUBSTR(E2_CODBAR,1,3)<>  '" + cPort240 + "'"
	   
	ElseIf cModPgto == "01"
	   // Transferencia conta corrente do proprio banco	 
	   _cFiltro := " EMPTY(E2_CODBAR)" 
	   _cFiltro += " .AND. fBuscaCpo ('SA2', 1, xfilial('SA2') + E2_FORNECE + E2_LOJA, 'A2_BANCO') == '" + cPort240 + "'" 
	
	ElseIf cModPgto == "03" 
	   // Transferencias para outros bancos, comissoes, ...
	   _cFiltro := " EMPTY(E2_CODBAR)"
	   _cFiltro += " .AND. val(fBuscaCpo ('SA2', 1, xfilial('SA2') + E2_FORNECE + E2_LOJA, 'A2_BANCO')) > 0 "
	   _cFiltro += " .AND. fBuscaCpo ('SA2', 1, xfilial('SA2') + E2_FORNECE + E2_LOJA, 'A2_BANCO') != '" + cPort240 + "'"
	   
	/*
	ElseIf cModPgto == "41" .or. cModPgto == "43" 
	   _cFiltro := " Empty(E2_CODBAR) .and. " 
	   _cFiltro += " E2_SALDO >= 3000 .and. "    
	   _cFiltro += " ( !Empty(GetAdvFval(‘SA2‘,‘A2_BANCO‘,xFilial(‘SA2‘)+E2_FORNECE+E2_LOJA,1)) " 
	   _cFiltro += " .and. GetAdvFval(‘SA2‘,‘A2_BANCO‘ ,xFilial(‘SA2‘)+E2_FORNECE+E2_LOJA,1) <>"+"‘"+cPort240+"‘ )" 
	
	ElseIf cModPgto == "13" //--- Concessionarias 
	   _cFiltro := " !EMPTY(E2_CODBAR) .AND. SUBS(E2_CODBAR,1,1)==‘8‘" 
	
	ElseIf cModPgto == "16" //--- Darf Normal - Selecionar com codigo de retencao e tipo TX              
	   _cFiltro := " ( !Empty(E2_CODRET) .OR. !Empty(E2_CODREC) ) .AND. E2_TIPO == ‘TX ‘" 
	
	ElseIf cModPgto == "11" //--- FGTS / GFIP 
	   _cFiltro := " (E2_TIPO == ‘FGT‘)" 
	
	ElseIf cModPgto == "17" //--- GPS 
	   _cFiltro := " (E2_TIPO == ‘INS‘)" 
	
	ElseIf cModPgto == "19" //--- ISS 
	   _cFiltro := " E2_TIPO == ‘ISS‘ .or. E2_TIPO == ‘TX ‘ " 
	*/
	EndIf

	_sAdic = u_get ('Informe aqui, caso necessario, expressao para filtro adicional', 'C', 250, '', '', space (250), .F., '.T.')
	if ! empty (_sAdic)
		_cFiltro += '.and.' + alltrim (_sAdic)
	endif
	//msgalert(_cFiltro)
Return(_cFiltro)
     