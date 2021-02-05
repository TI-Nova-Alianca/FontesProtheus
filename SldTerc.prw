// Programa...: SldTerc
// Autor......: Robert Koch
// Data.......: 11/07/2016
// Descricao..: Tela de consulta de saldos de/em terceiros.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Tela de consulta de saldos de/em terceiros
// #PalavasChave      #saldos_de_terceiro 
// #TabelasPrincipais #VA_VSALDOS_TERCEIROS #SB6
// #Modulos           #EST
//
// Historico de alteracoes:
// 16/09/2016 - Robert  - Acrescentada a coluna B1_TIPO.
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
// 05/02/2021 - Claudia - Alteração do campo descrição, conforme view VA_VSALDOS_TERCEIROS. GLPI: 9297
// 
// --------------------------------------------------------------------------------------------------
User Function SldTerc ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "SLDTERC"
	private _sArqLog  := U_NomeLog ()
	u_logId ()
	u_logIni ()

	_ValidPerg ()
	Pergunte (cPerg, .T.)
	
	Processa ({|| _Tela ()})

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return
//
// --------------------------------------------------------------------------
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT B6_FILIAL AS FILIAL,"
	_oSQL:_sQuery += "        B6_IDENT AS IDENTIFICADOR,"
	_oSQL:_sQuery += "        CASE B6_TIPO WHEN 'D' THEN 'DE 3OS' WHEN 'E' THEN 'EM 3OS' ELSE B6_TIPO END AS TIPO,"
	_oSQL:_sQuery += "        dbo.VA_DTOC(B6_EMISSAO) AS EMISSAO,"
	_oSQL:_sQuery += "        B1_TIPO AS TP_PROD,"
	_oSQL:_sQuery += "        B6_PRODUTO AS PRODUTO,"
	_oSQL:_sQuery += "        V.DESCRICAO AS DESCRICAO,"
	_oSQL:_sQuery += "        B6_QUANT AS QT_ORIG,"
	_oSQL:_sQuery += "        B6_SALDO AS SALDO,"
	_oSQL:_sQuery += "        B6_PRUNIT AS P_UNIT,"
	_oSQL:_sQuery += "        B6_CLIFOR AS CLI_FORN,"
	_oSQL:_sQuery += "        B6_LOJA AS LOJA,"
	_oSQL:_sQuery += "        NOME,"
	_oSQL:_sQuery += "        B6_DOC AS NF,"
	_oSQL:_sQuery += "        B6_SERIE AS SERIE,"
	_oSQL:_sQuery += "        TIPO_NF,"
	_oSQL:_sQuery += "        TES,"
	_oSQL:_sQuery += "        ORIGEM"
	_oSQL:_sQuery +=   " FROM dbo.VA_VSALDOS_TERCEIROS V"
	_oSQL:_sQuery +=  " WHERE B6_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery +=    " AND B6_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery +=    " AND B6_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=    " AND B6_CLIFOR  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	if mv_par09 == 1
		_oSQL:_sQuery +=" AND B6_TIPO = 'D'"
	endif
	if mv_par09 == 2
		_oSQL:_sQuery +=" AND B6_TIPO = 'E'"
	endif
	_oSQL:_sQuery += " 	ORDER BY B6_EMISSAO, B6_DOC, B6_PRODUTO "
	
	U_lOG (_oSQL:_sQuery)
	
	_oSQL:F3Array ('Saldos de/em terceiros')
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                         Help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},                            ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},                            ""})
	aadd (_aRegsPerg, {03, "Data inicial                  ", "D", 8,  0,  "",   "",    {},                            ""})
	aadd (_aRegsPerg, {04, "Data final                    ", "D", 8,  0,  "",   "",    {},                            ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                            ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                            ""})
	aadd (_aRegsPerg, {07, "Cliente/fornecedor inicial    ", "C", 6,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {08, "Cliente/fornecedor final      ", "C", 6,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {09, "DE ou EM terceiros            ", "N", 1,  0,  "",   "   ", {'De 3os', 'Em 3os', 'Ambos'}, ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
