// Programa...: VA_XLS10
// Autor......: Robert Koch
// Data.......: 05/09/2011
// Cliente....: Nova Alianca
// Descricao..: Exportacao de transferencias entre filiais para planilha.
//
// Historico de alteracoes:
// 15/05/2012 - Robert  - Ajustes diversos para casos de entradas mal digitadas.
//                      - Criada coluna de contabilizacao para comparativos.
// 22/11/2018 - Robert  - Incluida coluna D1_TOTAL.
// 27/03/2020 - Claudia - Incluida validação se parametros mv_par01 ou mv_par02
//                        estiverem vazios, serão verificadas todas as filiais
//
// --------------------------------------------------------------------------
User Function VA_XLS10 (_lAutomat)
	Local cCadastro := "Exportacao de transferencias entre filiais para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS10"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de transferencias entre filiais para planilha")
		AADD(aSays,"")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	//local _lContinua   := .T.
	//local _sQuery      := ""
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT V.D2_FILIAL + '-' + RTRIM (SM0_ORIG.M0_FILIAL) AS FILIAL_ORIGEM,"
	_oSQL:_sQuery +=       " V.D1_FILIAL + '-' + RTRIM (SM0_DEST.M0_FILIAL) AS FILIAL_DESTINO,"
	_oSQL:_sQuery +=       " dbo.VA_DTOC (V.D2_EMISSAO) AS DT_SAIDA, V.D2_CLIENTE AS CLI_SAIDA, D2_DOC AS NF_SAIDA, V.D2_ITEM AS ITEM_SAIDA, D2_TP AS TP_PRD_SAIDA, D2_COD AS PROD_SAIDA, V.D2_QUANT AS QT_SAIDA, D2_TES AS TES_SAIDA, D2_CF AS CFOP_SAIDA, D2_TIPO AS TP_NF_SAIDA, V.D2_CUSTO1 AS CUSTO_SAIDA,"
	_oSQL:_sQuery +=       " dbo.VA_DTOC (V.D1_DTDIGIT) AS DT_ENTR, V.D1_FORNECE AS FORN_ENTR, D1_DOC AS NF_ENTR, V.D1_ITEM AS ITEM_ENTR, V.D1_TP AS TP_PRD_ENTR, D1_COD AS PROD_ENTR, V.D1_QUANT AS QT_ENTR, D1_TES AS TES_ENTR, D1_CF AS CFOP_ENTR, D1_TIPO AS TP_NF_ENTR, V.D1_CUSTO AS CUSTO_ENTR, V.D1_TOTAL AS VALOR_ENTR"
	_oSQL:_sQuery +=  " FROM VA_VTRANSF_ENTRE_FILIAIS V"
	_oSQL:_sQuery +=     " LEFT JOIN VA_SM0 SM0_ORIG"
	_oSQL:_sQuery +=       " ON (SM0_ORIG.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SM0_ORIG.M0_CODIGO = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=       " AND SM0_ORIG.M0_CODFIL = V.FILORIG)"
	_oSQL:_sQuery +=     " LEFT JOIN VA_SM0 SM0_DEST"
	_oSQL:_sQuery +=       " ON (SM0_DEST.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SM0_DEST.M0_CODIGO = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=       " AND SM0_DEST.M0_CODFIL = V.FILDEST)"
	_oSQL:_sQuery +=   " WHERE D2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	If !empty(mv_par01)
		_oSQL:_sQuery += " AND FILORIG    IN " + alltrim (FormatIn (mv_par01, '/'))
	EndIf
	If !empty(mv_par02)
		_oSQL:_sQuery +=   " AND FILDEST    IN " + alltrim (FormatIn (mv_par02, '/'))
	EndIf
	_oSQL:_sQuery +=   " AND (D1_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' OR D2_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_oSQL:_sQuery +=   " AND ((D1_CF BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "') or (D2_CF BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'))"
	_oSQL:_sQuery += " ORDER BY D2_FILIAL, D2_EMISSAO, D2_DOC, D2_ITEM"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Filiais origem (separ.barras) ", "C", 60, 0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Filiais dest. (separ.barras)  ", "C", 60, 0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Data inicial                  ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Data final                    ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {07, "CFOP (entrada) inicial        ", "C", 4,  0,  "",   "13 ", {},    ""})
	aadd (_aRegsPerg, {08, "CFOP (entrada) final          ", "C", 4,  0,  "",   "13 ", {},    ""})
	aadd (_aRegsPerg, {09, "CFOP (entrada) inicial        ", "C", 4,  0,  "",   "13 ", {},    ""})
	aadd (_aRegsPerg, {10, "CFOP (entrada) final          ", "C", 4,  0,  "",   "13 ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
