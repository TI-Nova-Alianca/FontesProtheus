// Programa:   REGIAO
// Autor:      Andre Alves
// Data:       01/08/2019
// Descricao:  Criado para compor a regiao com seus estados.
//
// Historico de alteracoes:
// 

// --------------------------------------------------------------------------


User Function _Regiao(_xEST)

Local _aArea    := GetArea()
Local _xRetorna := ""

If _xEST $ "RS/SC/PR"
	_xRetorna := "SUL"
ElseIf _xEST $ "SP/RJ/ES/MG"
	_xRetorna := "SUD"
ElseIf _xEST $ "MT/MS/GO/DF"
	_xRetorna := "CEN"
ElseIf _xEST $ "TO/PA/AM/AC/RO/RR/AP"
	_xRetorna := "NOR"
ElseIf _xEST $ "EX"
	_xRetorna := "EXT"
Else
	_xRetorna := "NRD"
Endif

RestArea(_aArea)
Return(_xRetorna)