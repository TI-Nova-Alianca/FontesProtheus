// Programa...: VA_XLS53
// Autor......: Robert Koch
// Data.......: 27/08/2020
// Descricao..: Exporta planiha com rateios de estocagem e complemento preco uva.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planiha com rateios de estocagem e complemento preco uva
// #PalavasChave      #rateio_estocagem #complemento_preco_uva
// #TabelasPrincipais #SD3
// #Modulos 		  #CTB #EST

// Historico de alteracoes:
// 15/10/2020 - Robert - Passa a considerar TM=304 (ainda em testes de novo metodo de rateios).
//                     - Mostra movimentos, mesmo que com custo zerado.
// 22/02/2021 - Robert - Mostrava fixos os CC da matriz. Agora pega o D3_FILIAL como inicio do codigo do CC (GLPI 9453).
// 19/03/2021 - Robert - Criado tratamento para mov. 414 (FUNRURAL)
//

// --------------------------------------------------------------------------
User Function VA_XLS53 (_lAutomat)
	Local cCadastro := "Exporta planiha com rateios de estocagem e complemento preco uva"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS53"
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
	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += " SELECT SD3.D3_FILIAL AS FILIAL"
	_oSQL:_sQuery +=       ", SUBSTRING (SD3.D3_EMISSAO, 1, 6) AS ANO_MES"
	_oSQL:_sQuery +=       ", SD3.D3_TM AS TIPO_MOVTO"
	_oSQL:_sQuery +=       ", CASE SD3.D3_TM WHEN '300' THEN SD3.D3_FILIAL + '1101'"
	_oSQL:_sQuery +=                       " WHEN '301' THEN SD3.D3_FILIAL + '1102'"
	_oSQL:_sQuery +=                       " WHEN '302' THEN SD3.D3_FILIAL + '1201'"
	_oSQL:_sQuery +=                       " WHEN '303' THEN SD3.D3_FILIAL + '1202'"
	_oSQL:_sQuery +=                       " WHEN '304' THEN 'PROVISAO UVA'"
	_oSQL:_sQuery +=                       " WHEN '413' THEN 'COMPLEMENTO UVA'"
	_oSQL:_sQuery +=                       " WHEN '414' THEN 'FUNRURAL'"
	_oSQL:_sQuery +=                       " WHEN '513' THEN 'ESTORNO UVA'"
	_oSQL:_sQuery +=                       " ELSE 'TM ' + SD3.D3_TM END AS CC"
	_oSQL:_sQuery +=       ", SD3.D3_COD, SB1.B1_TIPO, SB1.B1_DESC"
	_oSQL:_sQuery +=       ", CASE WHEN D3_TM >= '5' THEN -1 ELSE 1 END * D3_CUSTO1 AS CUSTO"
	_oSQL:_sQuery +=       ", dbo.VA_SALDOESTQ (SD3.D3_FILIAL, SD3.D3_COD, SD3.D3_LOCAL, SD3.D3_EMISSAO) AS ESTQ_NA_DATA"
	_oSQL:_sQuery +=       ", SB1.B1_UM AS UNID_MEDIDA"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD3") + " SD3 "
	_oSQL:_sQuery +=    " LEFT JOIN " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=       " ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=       " AND SB1.B1_COD     = SD3.D3_COD)"
	_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
	// Quero listar todas as filiais  --> _oSQL:_sQuery +=   " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + mv_par01 + "0101' AND '" + mv_par02 + "1231'"
//	_oSQL:_sQuery +=   " AND SD3.D3_TM      IN ('300', '301', '302', '303', '304', '413', '513')"
	_oSQL:_sQuery +=   " AND SD3.D3_TM      IN ('300', '301', '302', '303', '304', '413', '414', '513')"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += "SELECT FILIAL, ANO_MES, TIPO_MOVTO, CC, RTRIM (ISNULL (CTT_DESC01, '')) AS DESCR_CC"
	_oSQL:_sQuery +=      ", CUSTO, B1_TIPO AS TIPO_PROD_DESTINO"
	_oSQL:_sQuery +=      ", D3_COD AS PRODUTO_DESTINO, RTRIM (B1_DESC) AS DESCR_PROD_DESTINO"
	_oSQL:_sQuery +=      ", ESTQ_NA_DATA, UNID_MEDIDA"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery +=    " LEFT JOIN " + RetSQLName ("CTT") + " CTT "
	_oSQL:_sQuery +=       " ON (CTT.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND CTT.CTT_FILIAL = '" + xfilial ("CTT") + "'"
	_oSQL:_sQuery +=       " AND CTT.CTT_CUSTO  = C.CC)"
	_oSQL:_sQuery += " ORDER BY FILIAL, ANO_MES, CC, TIPO_PROD_DESTINO, PRODUTO_DESTINO"
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
