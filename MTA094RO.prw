// Programa...: MTA094RO
// Autor......: Robert Koch
// Data.......: 23/11/2017
// Descricao..: P.E. na tela de liberacao de documentos (MATA094) para inclusao de botoes.
//              Criado inicialmente para chamar consulta de divergencias.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MTA094RO ()
	local _aRet := PARAMIXB[1]  // Nao usar aClone() por que precisa pegar por referencia. 

	aadd (_aRet, {"Divergencias",  "iif(scr->cr_tipo=='NF',U_GEmailPreNF (substr (scr -> cr_num, 13, 6), substr (scr -> cr_num, 19, 2), substr (scr -> cr_num, 1, 9), substr (scr -> cr_num, 10, 3), .T.), msgalert ('Documento nao e´ NF'))",0,4})
return _aRet
