// Programa...: MonRevCh
// Autor......: Robert Koch
// Data.......: 20/11/2020
// Descricao..: Tela de consulta de logs de revalidacoes de chaves de NF-e e CT-e

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta mensagens das ultimas N revalidacoes de chaves de NF-e e CT-e junto a SEFAZ.
// #PalavasChave      #XML #revalidacao_chave #NFe #CTe
// #TabelasPrincipais #SZN
// #Modulos           #FIS

// Historico de alteracoes:
// 23/11/2020 - Robert - Permite filtrar as N ultimas execucoes.
//

// --------------------------------------------------------------------------
user function MonRevCh ()
//	local _aAreaAnt   := U_ML_SRArea ()
//	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "MONREVCH"

	_ValidPerg ()
	Pergunte (cPerg, .T.)
	
	if date () - mv_par01 > 30
		u_help ("Periodo muito grande")
		return
	endif
	if mv_par03 < 1
		u_help ("Informe o numero de ultimas execucoes.")
		return
	endif

	Processa ({|| _Tela ()})
	
//	U_SalvaAmb (_aAmbAnt)
//	U_ML_SRArea (_aAreaAnt)
Return

// --------------------------------------------------------------------------
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "WITH C AS ("
	_oSQL:_sQuery += "SELECT top 100 percent"  // usa TOP 100 PERCENT para poder usar ORDER BY dentro do WITH.
	_oSQL:_sQuery +=       " V.CHAVE, V.DATA, V.HORA, V.DESCRITIVO"
	_oSQL:_sQuery +=      " ,ROW_NUMBER () OVER(ORDER BY CHAVE) AS ORDEM_EXECUCAO"  // Contagem geral de lihas
	_oSQL:_sQuery +=  " FROM VA_VEVENTOS V"
	_oSQL:_sQuery += " WHERE FILIAL = '01'"  // Roda sempre pela matriz
	_oSQL:_sQuery +=   " AND DATA   >= '" + dtos (mv_par01) + "'"
	if ! empty (mv_par02)
		_oSQL:_sQuery +=   " AND CHAVE  LIKE '" + mv_par02 + "%'"
	endif
	_oSQL:_sQuery +=   " AND CODEVENTO = 'ZZX001'"
	_oSQL:_sQuery += " ORDER BY V.DATA, V.CHAVE, V.HORA"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM C"

	// Filtra as ultimas N execucoes
	_oSQL:_sQuery +=  " WHERE C.ORDEM_EXECUCAO >= (SELECT MIN (ORDEM_EXECUCAO)"
	_oSQL:_sQuery +=                               " FROM (SELECT TOP " + cvaltochar (mv_par03) + " ORDEM_EXECUCAO"
	_oSQL:_sQuery +=                                       " FROM C AS ULTIMA"
	_oSQL:_sQuery +=                                      " WHERE ULTIMA.CHAVE = C.CHAVE"
	_oSQL:_sQuery +=                                      " ORDER BY ULTIMA.ORDEM_EXECUCAO DESC) AS ULTIMAS)"

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
	aadd (_aRegsPerg, {03, "Ultimas N execucoes           ", "N", 2,  0,  "",   "",    {},                            ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
