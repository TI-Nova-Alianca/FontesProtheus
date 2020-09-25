// Programa:   SQLName
// Autor:      Robert Koch
// Data:       03/09/2010
// Cliente:    Alianca
// Descricao:  Retorna nome da tabela no SQL.
//             Criado para substituir a funcao padrao RetSQLName quando for necessario acessar tabelas
//             de outras empresas, por que algumas tabelas sao compartilhadas entre diferentes empresas.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SQLName (_sAlias, _sEmpresa)
	local _sRet     := "  "
	local _aAreaAnt := U_ML_SRArea ()

	if _sEmpresa == cEmpAnt
		_sRet = RetSQLName (_sAlias)
	else
		use ("SX2" + _sEmpresa  + "0") shared new alias "_sx2"
		if alias () != "_SX2"
			U_AvisaTI (ProcName () + ": Erro na abertura do SX2 da empresa '" + _sEmpresa + "'")
		else
			_sx2 -> (dbsetorder (1))
			if ! _sx2 -> (dbseek (_sAlias, .F.))
				U_AvisaTI (ProcName () + ": Arquivo '" + _sAlias + "' nao encontrado no SX2 da empresa '" + _sEmpresa + "'")
			else
				_sRet = _sx2 -> x2_arquivo
			endif
			dbselectarea ("_SX2")
			dbclosearea ()
			dbselectarea ("SX2")
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _sRet
