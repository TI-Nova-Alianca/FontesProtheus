// Programa...: TXT2DBF
// Autor......: Robert Koch
// Data.......: 21/08/2008
// Cliente....: Generico
// Descricao..: Recebe um alias e uma string. Importa a string para os campos do arquivo.
//              A soma dos tamanhos dos campos deve ser igual ou menor que o tamanho da string.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
// Parametros recebidos:
// 1 - Alias do arquivo para onde a string deve ser importada.
// 2 - String a ser importada para os campos do arquivo.
// --------------------------------------------------------------------------
User Function TXT2DBF (_sAlias, _sString)
	local _aCampos := (_sAlias) -> (dbstruct ())
	local _nCampo  := 0
	local _nPos    := 1
	local _xDado   := NIL
	reclock ((_sAlias), .T.)
	for _nCampo = 1 to len (_aCampos)
		do case
		case _aCampos [_nCampo, 2] == "C"
			_xDado = substr (_sString, _nPos, _aCampos [_nCampo, 3])
			_nPos += _aCampos [_nCampo, 3]
		case _aCampos [_nCampo, 2] == "N"
			_xDado  = substr (_sString, _nPos, _aCampos [_nCampo, 3] - _aCampos [_nCampo, 4] - 1)
			_nPos += len (_xDado) + 1
			if _aCampos [_nCampo, 4] > 0
				_xDado += "." + substr (_sString, _nPos - 1, _aCampos [_nCampo, 4])
				_nPos  += _aCampos [_nCampo, 4] - 1
			endif
			_xDado = val (_xDado)
		case _aCampos [_nCampo, 2] == "D"
			_xDado = substr (_sString, _nPos, 8)
			_xDado = stod (_xDado)
			_nPos += 8
		endcase
		(_sAlias) -> (FieldPut (_nCampo, _xDado))
	next
	msunlock ()
return
