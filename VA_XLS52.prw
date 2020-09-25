// Programa...: VA_XLS52
// Autor......: Robert Koch
// Data.......: 27/08/2020
// Descricao..: Exporta planiha com mao de obra apropriada por OP

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planiha com mao de obra apropriada por OP
// #PalavasChave      #apropriacao_de_mao_de_obra #ordem_de_producao
// #TabelasPrincipais #SD3 #SC2
// #Modulos 		  #CTB #EST

// Historico de alteracoes:
// 10/09/2020 - Claudia - Incluída coluna de quantidade produzida em litros. GLPI: 8459

// --------------------------------------------------------------------------
User Function VA_XLS52 (_lAutomat)
	Local cCadastro := "Exporta planiha com mao de obra apropriada por OP"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS52"
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
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SD3.D3_FILIAL AS FILIAL, SUBSTRING (SD3.D3_EMISSAO, 1, 6) AS ANO_MES"
	_oSQL:_sQuery +=       " ,SUBSTRING (SD3.D3_COD, 4, 9) AS CC, RTRIM (CTT.CTT_DESC01) AS DESCR_CC"
	_oSQL:_sQuery +=       " ,SUM (CASE WHEN SD3.D3_TIPO = 'AP' THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_AP"
	_oSQL:_sQuery +=       " ,SUM (CASE WHEN SD3.D3_TIPO = 'MO' THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_MO"
	_oSQL:_sQuery +=       " ,SUM (CASE WHEN SD3.D3_TIPO = 'GF' THEN D3_CUSTO1 ELSE 0 END) AS CUSTO_GF"
	_oSQL:_sQuery +=       " ,SB1_FINAL.B1_TIPO AS TIPO_PRODUTO_DESTINO, SC2.C2_PRODUTO AS PRODUTO_DESTINO"
	_oSQL:_sQuery +=       " ,RTRIM (SB1_FINAL.B1_DESC) AS DESC_PROD_DESTINO, SC2.C2_QUJE AS QT_PRODUZIDA"
	_oSQL:_sQuery +=       " ,SC2.C2_QUJE * B1_LITROS QT_PRODUZIDA_LITROS"
	_oSQL:_sQuery +=       " ,SC2.C2_PERDA AS QT_PERDIDA, SB1_FINAL.B1_UM AS UN_MEDIDA, '''' + D3_OP AS OP"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD3") + " SD3 "
	_oSQL:_sQuery +=    " LEFT JOIN " + RetSQLName ("CTT") + " CTT "
	_oSQL:_sQuery +=        " ON (CTT.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND CTT.CTT_FILIAL  = '" + xfilial ("CTT") + "'"
	_oSQL:_sQuery +=       " AND CTT.CTT_CUSTO   = SUBSTRING (SD3.D3_COD, 4, 9))"
	_oSQL:_sQuery +=    " LEFT JOIN " + RetSQLName ("SC2") + " SC2 "
	_oSQL:_sQuery +=          " LEFT JOIN " + RetSQLName ("SB1") + " SB1_FINAL "
	_oSQL:_sQuery +=             " ON (SB1_FINAL.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=             " AND SB1_FINAL.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=             " AND SB1_FINAL.B1_COD = SC2.C2_PRODUTO)"
	_oSQL:_sQuery +=       " ON (SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SC2.C2_FILIAL = SD3.D3_FILIAL"
	_oSQL:_sQuery +=       " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = SD3.D3_OP)"
	_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
	// Quero listar todas as filiais  --> _oSQL:_sQuery +=   " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + mv_par01 + "0101' AND '" + mv_par02 + "1231'"
	_oSQL:_sQuery +=   " AND SD3.D3_TIPO IN ('AP', 'MO', 'GF')"
	_oSQL:_sQuery +=   " AND SD3.D3_CUSTO1 != 0"
	_oSQL:_sQuery += " GROUP BY SD3.D3_FILIAL, SUBSTRING (SD3.D3_EMISSAO, 1, 6), SUBSTRING (SD3.D3_COD, 4, 9),"
	_oSQL:_sQuery +=          " CTT.CTT_DESC01, SB1_FINAL.B1_TIPO, SC2.C2_PRODUTO, SB1_FINAL.B1_DESC, SC2.C2_QUJE,"
	_oSQL:_sQuery +=          " SC2.C2_PERDA, SB1_FINAL.B1_UM, SD3.D3_OP,SB1_FINAL.B1_LITROS"
	_oSQL:_sQuery += " ORDER BY SD3.D3_FILIAL, SUBSTRING (SD3.D3_EMISSAO, 1, 6), CTT.CTT_DESC01"
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Ano Inicial ", "C", 4,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Ano Final   ", "C", 4,  0,  "",   "   ", {},                   	""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
