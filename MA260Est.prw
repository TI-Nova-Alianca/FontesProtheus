// Programa...: MA260Est
// Autor......: Robert Koch
// Data.......: 17/08/2018
// Descricao..: P.E. para validar o estorno na tela de transf. internas
//
// Historico de alteracoes:
//

// ----------------------------------------------------------------
user function MA260Est ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.

	// Valida estorno, quando tiver etiqueta informada.
	if ! empty (sd3 -> d3_vaetiq)
		_lRet = U_VlEsGP ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
