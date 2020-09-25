// Programa:   MT380Alt
// Autor:      Robert Koch
// Data:       03/05/2017
// Descricao:  P.E. apos gravacao de alteracao manual de empenho de OP (nao modelo II)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MT380Alt ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento  := NIL

	// Se o usuario selecionou opcao 'zerar empenhos'.
	if lZeraEmp
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven = "SD4001"
		_oEvento:OP      = sd4 -> d4_op
		_oEvento:Texto   = "Zerado empenho da OP"
		_oEvento:Produto = sd4 -> d4_cod
		_oEvento:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)
return
