// Programa...: OM010Mnu
// Autor......: Robert Koch
// Data.......: 11/11/2015
// Descricao..: P.E. apos definicao de manu da tela de listas de precos (OMSA010)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function OM010Mnu ()
	aadd (aRotina, {"Obs.internas",  "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACME2', 'DA0_VAOBS')",0,4,32,NIL})
	aadd (aRotina, {"Obs.impressas", "U_MemoDA0 (da0 -> (recno ()), 'A', 'DA0_VACMEM', 'DA0_VAINST')",0,4,32,NIL})
return
