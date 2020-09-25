// Programa...: MA103But
// Autor......: Jererson Rech
// Data.......: 12/2004
// Descricao..: P.E. acrescenta opcoes no menu da NF de entrada
//
// Historico de alteracoes:
// 05/05/2008 - Robert - Inclusao botao para selecao de frete.
// 05/09/2008 - Robert - Inclusao botao para consulta de eventos.
// 26/12/2011 - Robert - Desabilitada consulta de limites producao patriarca.
//

// --------------------------------------------------------------------------
User Function MA103BUT()
	Local _aArea  := GetArea()
	Local _aRet   := {}

	aadd (_aRet, {"CARGA",    {|| U_FrtSelFr ()}                                                                     , "Frete"})

	RestArea(_aArea)
Return(_aRet)
