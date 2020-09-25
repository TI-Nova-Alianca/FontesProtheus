// Programa:   EhAssoc
// Autor:      Robert Koch
// Data:       19/03/2012
// Descricao:  Retorna .T. se o codigo passado for de um associado.
//             Criado inicialmente para uso em lancamentos padrao da contabilidade.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function EhAssoc (_sCodigo, _sLoja, _dData)
	local _oAssoc    := NIL
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := .F.

	_oAssoc := ClsAssoc():New (_sCodigo, _sLoja)
	if valtype (_oAssoc) == "O"
		if _oAssoc:EhSocio (_dData)
			_lRet = .T.
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
