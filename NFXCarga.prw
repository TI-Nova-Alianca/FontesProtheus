// Programa...: NFXCarga
// Autor......: Robert Koch
// Data.......: 19/08/2015
// Descricao..: Tela de consulta de relacionamento NF X carga do OMS.
//              Criada inicialmente para ajudar na rastreabilidade de lotes vendidos.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function NFXCarga (_sProdIni, _sProdFim)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "NFXCARGA"
	private _sArqLog  := U_NomeLog ()
	u_logId ()
	u_logIni ()

	_ValidPerg ()
	if _sProdIni != NIL
		U_GravaSX1 (cPerg, '05', _sProdIni)
	endif
	if _sProdFim != NIL
		U_GravaSX1 (cPerg, '06', _sProdFim)
	endif
	if Pergunte (cPerg, .T.)
		processa ({|| _Tela ()})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SF2.F2_DOC AS NOTA_FISCAL,"
	_oSQL:_sQuery +=        " dbo.VA_DTOC (F2_EMISSAO) AS DATA_EMISSAO,"
	_oSQL:_sQuery +=        " C9_PRODUTO AS PRODUTO,"
	_oSQL:_sQuery +=        " RTRIM(B1_DESC) AS DESCRICAO_PRODUTO,"
	_oSQL:_sQuery +=        " SUM(SC9.C9_QTDLIB) AS QUANTIDADE,"
	_oSQL:_sQuery +=        " SB1.B1_UM AS UN_MEDIDA,"
	_oSQL:_sQuery +=        " SF2.F2_TIPO AS TIPO_NF,"
	_oSQL:_sQuery +=        " C9_CARGA AS NUMERO_CARGA,"
	_oSQL:_sQuery +=        " RTRIM(CASE"
	_oSQL:_sQuery +=                 " WHEN SF2.F2_TIPO IN ('D', 'B') THEN SA2.A2_NOME"
	_oSQL:_sQuery +=                 " ELSE SA1.A1_NOME"
	_oSQL:_sQuery +=              " END) AS NOME_DESTINATARIO"
	_oSQL:_sQuery += " FROM	" + RetSQLName ("SC9") + " SC9, "
	_oSQL:_sQuery +=            RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=            RetSQLName ("SF2") + " SF2 "
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1"
	_oSQL:_sQuery +=           " ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SA1.A1_FILIAL  = '  '"
	_oSQL:_sQuery +=           " AND SA1.A1_COD     = SF2.F2_CLIENTE"
	_oSQL:_sQuery +=           " AND SA1.A1_LOJA    = SF2.F2_LOJA)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2"
	_oSQL:_sQuery +=           " ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SA2.A2_FILIAL  = '  '"
	_oSQL:_sQuery +=           " AND SA2.A2_COD     = SF2.F2_CLIENTE"
	_oSQL:_sQuery +=           " AND SA2.A2_LOJA    = SF2.F2_LOJA)"
	_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
	_oSQL:_sQuery +=   " AND SF2.F2_EMISSAO between '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=   " AND SF2.F2_DOC     between '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND SC9.C9_PRODUTO between '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery +=   " AND SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SF2.F2_FILIAL  = SC9.C9_FILIAL"
	_oSQL:_sQuery +=   " AND SF2.F2_DOC     = SC9.C9_NFISCAL"
	_oSQL:_sQuery +=   " AND SF2.F2_SERIE   = SC9.C9_SERIENF"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '  '"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     = SC9.C9_PRODUTO"
	_oSQL:_sQuery += " GROUP BY	SF2.F2_DOC, SF2.F2_EMISSAO, SC9.C9_PRODUTO, SC9.C9_CARGA, SB1.B1_DESC, SB1.B1_UM, SA1.A1_NOME, SA2.A2_NOME, SF2.F2_TIPO"
	_oSQL:_sQuery += " ORDER BY SF2.F2_DOC, SC9.C9_PRODUTO"
	U_lOG (_oSQL:_sQuery)
	_oSQL:F3Array ('NF de saida X cargas modulo OMS')
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                          Help
	aadd (_aRegsPerg, {01, "Data inicial emissao NF       ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {02, "Data final emissao NF         ", "D", 8,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {03, "NF inicial                    ", "C", 9,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {04, "NF final                      ", "C", 9,  0,  "",   "",    {},                             ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                             ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                             ""})
//	aadd (_aRegsPerg, {07, "Cliente/fornecedor inicial    ", "C", 6,  0,  "",   "   ", {},                             ""})
//	aadd (_aRegsPerg, {08, "Cliente/fornecedor final      ", "C", 6,  0,  "",   "   ", {},                             ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
