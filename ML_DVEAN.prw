// Programa:   ML_DVEAN
// Autor:      Robert Koch
// Data:       nem lembro mais... provavelmente antes de 2010.
// Descricao:  Calcula digito verificador para codugo EAN13.
//
// Historico de alteracoes:
// 05/08/2016 - Robert - Melhorado tratamento para retorno (tinha diversos 'returns' no corpo do programa).
//

// --------------------------------------------------------------------------
user function ML_DVEAN (_sCodSemDV, _lRetTudo)
	local _nPos      := 0
	//local _sMultiplo := 0
	local _nSoma     := 0
	local _nMult10   := 0
	local _sRet      := ""
//	private _sArqLog := iif (type ('_sArqLog') == 'C', _sArqLog, U_NomeLog ())
//	u_logIni ()
	
	if len (alltrim (_sCodSemDV)) != 7 ;
		.and. len (alltrim (_sCodSemDV)) != 11 ;
		.and. len (alltrim (_sCodSemDV)) != 12 ;
		.and. len (alltrim (_sCodSemDV)) != 13 ;
		.and. len (alltrim (_sCodSemDV)) != 17
		u_help ("Tamanho de codigo invalido para EAN")
	else
	
		// Mutiplica cada posicao do codigo por valor fixo (3 ou 1).
		_nMultiplo = 3
		_nSoma     = 0
		for _nPos = len (_sCodSemDV) to 1 step -1
			_nSoma += val (substr (_sCodSemDV, _nPos, 1)) * _nMultiplo
			_nMultiplo = iif (_nMultiplo == 1, 3, 1)
		next
		
		// Multiplo de 10 superior mais proximo da soma:
		_nMult10 = (int (_nSoma / 10) + 1) * 10
		
		_nDV = _nMult10 - _nSoma
		if _nDv == 10
			_nDV = 0
		endif
		
		if _lRetTudo != NIL .and. _lRetTudo
			//return _sCodSemDV + alltrim (str (_nDV))
			_sRet = _sCodSemDV + alltrim (str (_nDV))
		else
			_sRet = alltrim (str (_nDV))
		endif
	endif
//	u_log ('Retornando:  >>' + _sRet + '<<')
//	u_logFim ()
return _sRet
