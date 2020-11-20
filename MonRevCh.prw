// Programa...: MonRevCh
// Autor......: Robert Koch
// Data.......: 20/11/2020
// Descricao..: Tela de consulta de logs de revalidacoes de chaves de NF-e e CT-e


// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MonRevCh ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "MONREVCH"

	_ValidPerg ()
	Pergunte (cPerg, .T.)
	
	Processa ({|| _Tela ()})

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return

// --------------------------------------------------------------------------
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT V.CHAVE, V.DATA, V.HORA, V.DESCRITIVO"
	_oSQL:_sQuery +=  " FROM VA_VEVENTOS V"
	_oSQL:_sQuery += " WHERE FILIAL = '01'"  // Roda sempre pela matriz
	_oSQL:_sQuery +=   " AND DATA   >= '" + dtos (mv_par01) + "'"
	if ! empty (mv_par02)
		_oSQL:_sQuery +=   " AND CHAVE  LIKE '" + mv_par02 + "'"
	endif
	_oSQL:_sQuery +=   " AND CODEVENTO = 'ZZX001'"
	_oSQL:_sQuery += " ORDER BY V.DATA, V.CHAVE, V.HORA"
	_oSQL:F3Array ('Revalidacoes de chaves de NFe/CTe')
Return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                         Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "",    {},                            ""})
	aadd (_aRegsPerg, {02, "UF (vazio=todas)              ", "C", 2,  0,  "",   "",    {},                            ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
