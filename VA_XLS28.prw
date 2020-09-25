// Programa...: VA_XLS28
// Autor......: Robert Koch
// Data.......: 15/09/2016
// Descricao..: Exporta planilha com movimentos de/para terceiros.
//
// Historico de alteracoes:
// 27/09/2016 - Robert - Incluida coluna com CFOP.
// 13/09/2018 - Robert - Passa a mostrar a serie 99 para ajudar nas conferencias.
//

// --------------------------------------------------------------------------
User Function VA_XLS28 (_lAutomat)
	Local cCadastro := "Exporta detalhamento de movimentacoes com terceiros"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS28"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
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
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS("
	_oSQL:_sQuery += " SELECT 'SD1' AS ORIGEM,D1_FILIAL AS FILIAL,dbo.VA_DTOC(D1_DTDIGIT) AS DATA,D1_TIPO AS TIPO_NF,D1_DOC AS NF,"
	_oSQL:_sQuery +=        " D1_SERIE AS SERIE,D1_FORNECE AS CLI_FOR,D1_LOJA AS LOJA,D1_COD AS PRODUTO,SD1.D1_TP AS TIPO_PROD,SD1.D1_GRUPO AS GRUPO_PROD,D1_TES AS TES, D1_CF AS CFOP, SD1.D1_QUANT AS QUANT,"
	_oSQL:_sQuery +=        " SD1.D1_CUSTO AS CUSTO,SD1.D1_TOTAL AS VALOR_NF,SF4.F4_PODER3"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1,"
	_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4"
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery +=    " AND D1_DTDIGIT     BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SD1.D1_TES"
	_oSQL:_sQuery +=    " AND SF4.F4_PODER3 != 'N'"
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT 'SD2' AS ORIGEM,D2_FILIAL,dbo.VA_DTOC(D2_EMISSAO),D2_TIPO,D2_DOC,D2_SERIE,D2_CLIENTE,D2_LOJA,D2_COD,D2_TP,D2_GRUPO,D2_TES,D2_CF,D2_QUANT,D2_CUSTO1,SD2.D2_TOTAL,SF4.F4_PODER3"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") + " SD2,"
	_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4"
	_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery +=    " AND D2_EMISSAO    BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SD2.D2_TES"
	_oSQL:_sQuery +=    " AND SF4.F4_PODER3 != 'N'"
	//_oSQL:_sQuery +=    " AND D2_SERIE      != '99 '" // NOTAS VINCULADAS PARA ATENDER LEGISLACAO
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT C.*, B1_DESC"
	_oSQL:_sQuery +=   " FROM C,"
	_oSQL:_sQuery +=          RetSQLName ("SB1") + " SB1"
	_oSQL:_sQuery +=  " WHERE SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = C.PRODUTO"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .T.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Data inicial                 ?", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final                   ?", "D", 08, 0,  "",   "   ", {},                ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
