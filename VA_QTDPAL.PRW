// Programa:   VA_QTDPAL
// Autor:      Marcelo Minuzzo (DWT)
// Data:       19/03/2014
// Descricao:  Calcula a quantidade de etiquetas e de caixas.
//
// Historico de alteracoes:
// 12/11/2014 - Robert - Array de retorno passa a trazer mais 2 posicoes: lastro e qt.camadas.
// 31/03/2015 - Robert - Passa a ler campos b1_vaPlLas e b1_vaPlCam em lugar de DC2_LASTRO e DC2_CAMADA.
// 10/04/2015 - Robert - Passa a aceitar parametro para informar quantas caixas se deseja por pallet.
//

// ----------------------------------------------------------------
user function VA_QTDPAL (_cCod, _nQtTot, _nQtPorPal)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aPal      := {}
	local _nQtdPal   := 0
	local _nPallet   := 0
	local _nUmPallet := 0
	local _nLastro   := 0
	local _nCamadas  := 0

	// Se foi informada a quantidade por pallet, eh por que deseja-se trabalhar fora do padrao de cadastro.
	if _nQtPorPal != NIL .and. _nQtPorPal > 0
		_nLastro   = 0
		_nCamadas  = 0
		_nUmPallet = _nQtPorPal
	else
		sb1 -> (dbsetorder (1))
		if sb1 -> (dbseek (xfilial ("SB1") + _cCod, .F.))
			_nLastro   = sb1 -> b1_vaPlLas
			_nCamadas  = sb1 -> b1_vaPlCam
			_nUmPallet = _nLastro * _nCamadas
		endif
	endif
	if _nUmPallet > 0
		_nQtdPal = _nQtTot / _nUmPallet
		for _nPallet = 1 to int (_nQtdPal)
			aadd (_aPal, {_cCod, _nUmPallet, _nLastro, _nCamadas})
		next
		if _nQtdPal <> int(_nQtdPal)
			_nResto := (_nQtdPal - int(_nQtdPal)) * _nUmPallet
			aadd (_aPal, {_cCod, _nResto, _nLastro, _nCamadas})
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _aPal
