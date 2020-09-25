// Programa: MT120MAK
// Autor:    Robert Koch
// Data:     28/05/2012
// Funcao:   PE para inclusao de campos no markbrowse de selecao de solicitacoes/contratos de parceria.
//           Criado inicialmente para buscar o campo C3_VAOBRA.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MT120MAK ()
	local _aRet := {}

	if nTipoPed != 2  // Ped. compra
		aadd (_aRet, "C1_VAPROSE")
		//aadd (_aRet, "C1_VAOBRA")
		//aadd (_aRet, "C1_VAVLUNI")
	else  // Aut.entrega
		aadd (_aRet, "C3_VADESCR")
		aadd (_aRet, "C3_VAPROSE")
		aadd (_aRet, "C3_VAOBRA")
	endif

return _aRet
