// Programa:   F080Est
// Autor:      Robert Koch
// Data:       27/07/2011
// Descricao:  P.E. apos cancelamento de baixa manual de titulos a pagar.
//             Criado inicialmente para alimentar o campo E5_VACHVEX.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function f080est ()
	local _aAreaAnt := U_ML_SRArea ()
	//local _aAmbAnt  := U_SalvaAmb ()
	u_logIni ()
	
	if empty (se5 -> e5_vaUser)
		reclock ("SE5", .F.)
		se5->e5_vachvex = se2 -> e2_vachvex
		SE5->E5_VAUSER  := alltrim(cUserName)
		msunlock ()
	endif
	U_ML_SRArea (_aAreaAnt)
	//U_SalvaAmb (_aAmbAnt)
	u_logFim ()
return .t.


