// Programa:  CT390Bte
// Autor:     Robert Koch
// Data:      23/02/2016
// Descricao: P.E. para criar botoes na tela de orcamentos contabeis.
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
user function CT390Bte ()
	local _aRet := {}
	
	aadd (_aRet, {"", {|| U_CV1Ite ()}, "Reordena",    "Reordena"})

return _aRet
