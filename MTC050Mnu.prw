// Programa:  Mtc050Mnu
// Autor:     Robert Koch
// Data:      03/09/2015
// Descricao: P.E. para acrescentar opcoes no menu da consulta de produtos.
//
// Historico de alteracoes:
// 06/10/2015 - Robert - Passa extensao na chamada da visualizacao de especificacoes / imagem do produto.
//

// --------------------------------------------------------------------------
user function MTC050Mnu ()
	local _aRotAdic := {}
	aadd (_aRotAdic, {'Especif.tecnicas', "U_EspPrd (sb1->b1_cod, 'PDF')", 0 , 2, 0, NIL})
	aadd (_aRotAdic, {'Imagem produto',   "U_EspPrd (sb1->b1_cod, 'JPG')", 0 , 2, 0, NIL})
	aadd (aRotina, {"Especificos"           , _aRotAdic, 0, 6, 0, NIL})
return
