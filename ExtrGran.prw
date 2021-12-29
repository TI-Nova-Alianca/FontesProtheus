// Programa...: ExtrGran
// Autor......: Robert Koch
// Data.......: 17/03/2015
// Descricao..: Tela de consulta de extrato de movimentacao a granel.
//
// Historico de alteracoes:
// 03/12/2015 - Robert  - Incluida coluna MOVIM_3OS.
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
// 29/12/2021 - Claudia - Incluidas colunas de placa e chave CTE. GLPI: 9559
//
// --------------------------------------------------------------------------------------
User Function ExtrGran ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "EXTRGRAN"

	_ValidPerg ()
	if Pergunte (cPerg, .T.)
		processa ({|| _Tela ()})
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Emite consulta
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   FILIAL "
	_oSQL:_sQuery += "    ,ENTSAI "
	_oSQL:_sQuery += "    ,TIPO_NF "
	_oSQL:_sQuery += "    ,TES "
	_oSQL:_sQuery += "    ,MOVIM_ESTQ "
	_oSQL:_sQuery += "    ,MOVIM_3OS "
	_oSQL:_sQuery += "    ,DOC "
	_oSQL:_sQuery += "    ,RTRIM(PRODUTO) AS PRODUTO "
	_oSQL:_sQuery += "    ,RTRIM(DESCRICAO) AS DESCRICAO "
	_oSQL:_sQuery += "    ,QUANT "
	_oSQL:_sQuery += "    ,UM "
	_oSQL:_sQuery += "    ,dbo.VA_DTOC(DT_MOVTO) AS DT_MOVTO "
	_oSQL:_sQuery += "    ,CLI_FORN "
	_oSQL:_sQuery += "    ,LOJA "
	_oSQL:_sQuery += "    ,RTRIM(NOME) AS NOME "
	_oSQL:_sQuery += "    ,GUIA_TRANSITO "
	_oSQL:_sQuery += "    ,NUM_LABORAT_GUIA "
	_oSQL:_sQuery += "    ,RTRIM(NOME_TRANSP) AS NOME_TRANSP "
	_oSQL:_sQuery += "    ,PLACA "
	_oSQL:_sQuery += "    ,CTE "
	_oSQL:_sQuery += "    ,SERIE_CTE "
	_oSQL:_sQuery += "    ,CHAVE_CTE "
	_oSQL:_sQuery += " FROM dbo.VA_VMOVTO_GRANEL V"
	_oSQL:_sQuery += " WHERE CLI_FORN BETWEEN '" + mv_par07 		+ "' AND '" + mv_par08 			+ "'"
	_oSQL:_sQuery += " AND PRODUTO  BETWEEN   '" + mv_par05 		+ "' AND '" + mv_par06 			+ "'"
	_oSQL:_sQuery += " AND DT_MOVTO BETWEEN   '" + dtos (mv_par03) 	+ "' AND '" + dtos (mv_par04) 	+ "'"
	_oSQL:_sQuery += " AND FILIAL   BETWEEN   '" + mv_par01 		+ "' AND '" + mv_par02 			+ "'"
	if mv_par09 == 1
		_oSQL:_sQuery += " AND ENTSAI = 'ENTRADA'"
	endif
	if mv_par09 == 2
		_oSQL:_sQuery += " AND ENTSAI = 'SAIDA'"
	endif
	_oSQL:_sQuery += " 	ORDER BY DT_MOVTO, DOC, PRODUTO "
	_oSQL:Log ()
	_oSQL:F3Array ('Movimentacao de NOTAS FISCAIS contendo produtos a granel')
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                          Help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},                             ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},                             ""})
	aadd (_aRegsPerg, {03, "Dt.movto.inicial              ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {04, "Dt.movto.final                ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                             ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                             ""})
	aadd (_aRegsPerg, {07, "Cliente/fornecedor inicial    ", "C", 6,  0,  "",   "   ", {},                             ""})
	aadd (_aRegsPerg, {08, "Cliente/fornecedor final      ", "C", 6,  0,  "",   "   ", {},                             ""})
	aadd (_aRegsPerg, {09, "Entradas / saidas             ", "N", 1,  0,  "",   "   ", {'Entradas', 'Saida', 'Ambos'}, ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
