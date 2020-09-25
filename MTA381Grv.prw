// Programa:   MTA381Grv
// Autor:      Robert Koch
// Data:       03/05/2017
// Descricao:  P.E. apos gravacao de alteracao manual de empenho de OP (modelo II)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MTA381Grv ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento  := NIL

	// Se o usuario selecionou opcao 'zerar empenhos'.
	if lZeraEmp
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven = "SD4001"
		_oEvento:OP      = cOP
		_oEvento:Texto   = "Zerados todos os empenhos da OP"
		_oEvento:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)
return
