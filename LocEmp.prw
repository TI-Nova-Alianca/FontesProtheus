// Programa...: LocEmp
// Autor......: Robert Koch
// Data.......: 25/10/2014
// Descricao..: Retorna o local (almox) onde o produto deve ser empenhado para a OP.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function LocEmp (_sProduto)
	local _aAreaAnt := U_ML_SRArea ()
	local _sRet     := ''
	local _sAlmEnv  := ""
	local _sAlmPrep := ""

	sb1 -> (dbsetorder (1))
	if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
		u_help ("Produto '" + _sProduto + "' nao cadastrado.")
	else
		_sRet = sb1 -> b1_locpad

		// Alguns materiais devem ser requisitados de almoxarifados especificos (de processo).
		if cEmpAnt + cFilAnt == '0101'  // Somente na matriz
			if sb1 -> b1_tipo == 'ME'
				_sAlmEnv = GetMv ("AL_ALMENV",, '')  // Se o parametro nao existir, retorna vazio.
				if ! empty (_sAlmEnv)
					_sRet = _sAlmEnv
				endif
			elseif (sb1 -> b1_tipo == 'PS' .or. sb1 -> b1_grupo == '0407')
				_sAlmPrep = GetMv ("AL_ALMPREP",, '')  // Se o parametro nao existir, retorna vazio.
				if ! empty (_sAlmPrep)
					_sRet = _sAlmPrep
				endif
			endif
		endif
	endif

return _sRet
