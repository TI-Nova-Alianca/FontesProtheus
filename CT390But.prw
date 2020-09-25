// Programa:  CT390But
// Autor:     Robert Koch
// Data:      25/02/2016
// Descricao: P.E. para criar botoes no browse da tela de orcamentos contabeis.
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
user function CT390But ()
	local _aRet := {}

	aadd (_aRet, {"Insere ctas", "processa ({||U_CV1Ctas ()})", 0, 7})

return _aRet
