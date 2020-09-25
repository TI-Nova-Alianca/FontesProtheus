// Programa:  MC090Mnu
// Autor:     Robert Koch
// Data:      04/09/2008
// Cliente:   Alianca
// Descricao: P.E. antes de montar MBrowse na consulta de NF de saida.
//
// Historico de alteracoes:
// 20/11/2011 - Robert - Adicionada opcao de impressao do DANFe no menu.
// 18/09/2013 - Robert - Criado submenu, adicionada opcao de consultar eventos da NF-e.
//

// --------------------------------------------------------------------------
user function MC090Mnu ()
	local _aRotAdic := {}
	aadd (_aRotAdic, {"Eventos Alianca",  "U_VA_SZNC ('NFSAIDA', sf2 -> f2_doc, sf2 -> f2_serie)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Eventos NF-e",     "U_EvtNFe ('S', sf2 -> f2_doc, sf2 -> f2_serie)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Dados adicionais", "U_NFDaDicC ('S', sf2 -> f2_doc, sf2 -> f2_serie)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Historico NF",     "U_VARASTRO (sf2 -> f2_doc, sf2 -> f2_serie)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Lotes",            "U_VA_LtNF (sf2 -> f2_doc, sf2 -> f2_serie)", 0, 6, 0, NIL})
	aadd (aRotina, {"Especificos"           , _aRotAdic, 0, 6, 0, NIL})
return
