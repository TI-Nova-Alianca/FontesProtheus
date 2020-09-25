// Programa.: InspObj
// Autor....: Robert Koch
// Data.....: 01/02/2018
// Descricao: Busca datas de programas, semelhante ao inspetor de objetos do TDS
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function InspObj ()
	processa ({|| _AndaLogo ()})
return

// --------------------------------------------------------------------------
// Gera lista de programas e datas.
static function _AndaLogo ()
	local _nFunc   := 0
	local _aRet    := {}
	local _aTipos  := {}
	local _aArq    := {}
	local _aLinhas := {}
	local _aDatas  := {}
	local _aHoras  := {}
	local _aLista  := GetFuncArray ('*', @_aTipos, @_aArq, @_aLinhas, @_aDatas, @_aHoras)
	for _nFunc = 1 to len (_aLista)
		aadd (_aRet, {_aLista [_nFunc], _aTipos [_nFunc], _aArq [_nFunc], _aLinhas [_nFunc], _aDatas [_nFunc], _aHoras [_nFunc]})
	next
	u_showarray (_aRet)
return _aRet
