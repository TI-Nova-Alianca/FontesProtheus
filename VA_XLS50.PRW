// Programa...: VA_XLS50
// Autor......: Robert Koch
// Data.......: 17/03/2020
// Descricao..: Exporta planilha com entradas de MP/VD identificando se sao de associados ou nao.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Exporta planilha com entradas de MP/VD para classificacao entre ato cooperativo e nao cooperativo.
// #PalavasChave      #entradas #uva #materia-prima #ato_cooperativo #ato_nao_cooperativo #ato_cooperado #ato_nao_cooperado
// #TabelasPrincipais #SD1 #SZI
// #Modulos           #COOP #CTB

// Historico de alteracoes:
// 25/01/2021 - Robert  - Adicionada loja 02 do fornecedor 001369 como producao propria.
// 27/01/2021 - Robert  - Alteracao geral: deixa de ler view de notas e passa a buscar do SD1 (GLPI 9198).
// 17/09/2021 - Robert  - Exporta sucos concentrados apenas se forem de uva. (posterior encerramento GLPI 9198).
// 02/12/2021 - Claudia - Retirado os cfops de retorno de terceiros, transf.entre filiais e frete. GLPI: 11150
// 03/12/2021 - Claudia - Incluida validação de busca apenas itens do sisdevin. GLPI: 11150
// 13/04/2022 - Robert  - Nao desconsiderava registros deletados da tabela SD1.
//                      - Definido nome para o arquivo de destino.
//

// ----------------------------------------------------------------------------------------------------------------------------
User Function VA_XLS50 (_lAutomat)
	Local cCadastro := "Exporta com entradas de MP/VD para classificacao entre ato cooperativo e nao cooperativo."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)
		return
	endif

	Private cPerg   := "VAXLS50"
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
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Geraqção
Static Function _Gera()
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   SD1.D1_FILIAL AS FILIAL "
	_oSQL:_sQuery += "    ,SD1.D1_COD AS PRODUTO "
	_oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO "
	_oSQL:_sQuery += "    ,SD1.D1_TP AS TIPO_PRODUTO "
	_oSQL:_sQuery += "    ,FORMAT(CAST(SD1.D1_DTDIGIT AS DATETIME), 'dd/MM/yyyy') AS DT_MOVTO "
	_oSQL:_sQuery += "    ,SD1.D1_FORNECE AS FORNECEDOR "
	_oSQL:_sQuery += "    ,SD1.D1_LOJA AS LOJA "
	_oSQL:_sQuery += "    ,A2_NOME AS NOME "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 			WHEN dbo.VA_ASSOC_DT_ENTRADA(D1_FORNECE, D1_LOJA, D1_DTDIGIT) != '' THEN 'ASSOCIADO' "
	_oSQL:_sQuery += " 			ELSE 'NAO ASSOCIADO' "
	_oSQL:_sQuery += " 	   END AS TIPO_FORNECEDOR "
	_oSQL:_sQuery += "    ,SD1.D1_TIPO AS TIPO_NF "
	_oSQL:_sQuery += "    ,SD1.D1_TES AS TES "
	_oSQL:_sQuery += "    ,SD1.D1_CF AS CFOP "
	_oSQL:_sQuery += "    ,D1_DOC AS NF "
	_oSQL:_sQuery += "    ,SD1.D1_SERIE AS SERIE "
	_oSQL:_sQuery += "    ,SD1.D1_QUANT AS QUANTIDADE "
	_oSQL:_sQuery += "    ,SD1.D1_UM AS UN_MEDIDA "
	_oSQL:_sQuery += "    ,SD1.D1_TOTAL AS VL_TOTAL "
	_oSQL:_sQuery += "    ,SD1.D1_CUSTO AS CUSTO_MEDIO "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1 "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += " 			AND SB1.B1_COD    = SD1.D1_COD) "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB5") + " SB5 "
	_oSQL:_sQuery += " 	ON (SB5.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SB5.B5_FILIAL  = SB1.B1_FILIAL "
	_oSQL:_sQuery += " 			AND SB5.B5_COD     = SB1.B1_COD "
	_oSQL:_sQuery += " 			AND SB5.B5_VASISDE = 'S') "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery += " 			AND SA2.A2_COD    = SD1.D1_FORNECE "
	_oSQL:_sQuery += " 			AND SA2.A2_LOJA   = SD1.D1_LOJA) "
	_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery += " AND SD1.D1_TP IN ('MP', 'VD') "
	_oSQL:_sQuery += " AND SD1.D1_TIPO NOT IN ('B', 'D') "
	_oSQL:_sQuery += " AND SD1.D1_CF NOT IN ('1902', '1925', '1151', '2151', '1352', '1903', '2903', '2352','1352' ) "
    _oSQL:_sQuery += " AND (SD1.D1_CF <> '1949' OR (SD1.D1_CF = '1949' AND SD1.D1_FILIAL='03' AND SD1.D1_FORNECE='001369')) "
	_oSQL:Log ()
	_oSQL:ArqDestXLS = 'VA_XLS50'
	_oSQL:Qry2Xls ()
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Data inicial NF entrada       ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {02, "Data final NF entrada         ", "D", 8,             0,            "",   "   ",  {},                                            ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
