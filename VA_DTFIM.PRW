// Programa...: VA_DTFIM
// Autor......: Robert Koch
// Data.......: 08/03/2012
// Descricao..: Edicao de parametro do configurador.
//
// Historico de alteracoes:
// 30/11/2014 - Robert - Passa a validar usuario pela tabela ZZU.
//

// --------------------------------------------------------------------------
User Function VA_DTFIM ()
	local _sAntigo  := ""
	local _sNovo    := ""
	local _oEvento  := NIL
	local _sNomePar := "MV_DATAFIN"

	if U_ZZUVL ('028')
		_sAntigo = GetMv (_sNomePar)
		_sNovo = U_Get ("Data limite para mov.financeiros nesta filial", "D", 8, "@D", "", _sAntigo, .F., '.t.')
		if _sNovo != NIL .and. ! empty (_sNovo)
			PutMv (_sNomePar, _sNovo)
			u_help ("Alteracao efetuada com sucesso")

			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SX6001"
			_oEvento:Texto     = "Alteracao parametro " + _sNomePar + " de '" + cvaltochar (_sAntigo) + "' para '" + cvaltochar (_sNovo) + "'"
			_oEvento:Grava ()
		endif
	endif
return
