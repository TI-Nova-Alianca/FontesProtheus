// Programa:   TamFixo
// Autor:      Robert Koch
// Data:       14/01/2009
// Descricao:  Recebe dado e retorna com tamanho fixo. Util para usar em relatorios,
//             onde varios campos sao concatenados.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function TamFixo (_sDado, _nTamanho, _sFilChar)
	local _sRet := left (padr (_sDado, _nTamanho, iif (_sFilChar == NIL, " ", _sFilChar)), _nTamanho)
return _sRet
