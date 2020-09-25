// Programa...: VA_XLS27
// Autor......: Robert Koch
// Data.......: 04/09/2015
// Descricao..: Exporta planilha com quantidades vendidas, para indicador da qualidade (vendas X devolucoes)
//
// Historico de alteracoes:
// 23/09/2015 - Robert  - Incluida coluna de linha de envase.
// 03/06/2016 - Catia   - Usar VA_VFAT ao inves do antigo exporta dados
// 25/02/2020 - Claudia - Alterado o uso da view VA_VFAT para a tabela BI_ALIANCA.dbo.VA_FATDADOS
//
//
// --------------------------------------------------------------------------
User Function VA_XLS27 (_lAutomat)
	Local cCadastro := "Exporta quant.venda/bonif (descons.devolucoes) p/indicador qualidade"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lSelCol := .F.  // Para controlar se jah chamou as opcoes.
	private _sOpcoes := ""   // Opcoes (colunas) selecionadas pelo usuario, em formato string para guardar nos parametros do SX1.
	private _aOpcoes := {}   // Opcoes (colunas) selecionadas pelo usuario.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS27"
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
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _aArqTrb   := {}
	local _nOpcao    := 0

	procregua (10)

	// Busca dados
	incproc ("Buscando dados")
	_sQuery := " select FILIAL, dbo.VA_DTOC (EMISSAO) AS EMISSAO, PRODUTO, B1_DESC AS DESCRICAO, SUM (QUANTIDADE) AS QUANTIDADE, UMPROD,"
	_sQuery +=        " SUM (QTCAIXAS) AS QTCAIXAS,"
	_sQuery +=        " SUM (QTLITROS) AS LITROS,"
//	_sQuery +=        " RTRIM (ISNULL (ZX5_50.X5_DESCRI, '')) AS EMBALAGEM,"
	_sQuery +=        " RTRIM (SB1.B1_VALINEN) + ' - ' + RTRIM (ISNULL (SH1.H1_DESCRI, '')) AS LINHA_ENVASE"
	_sQuery +=   " from " + RetSQLName ("SB1") + " SB1 "
	_sQuery +=            " LEFT JOIN " + RetSQLName ("SH1") + " SH1"
	_sQuery +=                 " ON (SH1.D_E_L_E_T_ = ''"
	_sQuery +=                 " AND SH1.H1_FILIAL = '" + xfilial ("SH1") + "'"
	_sQuery +=                 " AND SH1.H1_CODIGO = SB1.B1_VALINEN),
	_sQuery +=            " BI_ALIANCA.dbo.VA_FATDADOS as V "
//	_sQuery +=            " left join " + RetSQLName ("ZX5") + " ZX5_50 "
//	_sQuery +=                 " on (ZX5_50.D_E_L_E_T_ != '*'"
//	_sQuery +=                 " and ZX5_50.X5_FILIAL   = '" + xfilial ("ZX5") + "'"
//	_sQuery +=                 " and ZX5_50.X5_TABELA   = '50'"
//	_sQuery +=                 " and ZX5_50.X5_CHAVE    = V.GRPEMB)"
	_sQuery +=  " where SB1.D_E_L_E_T_    != '*'"
	_sQuery +=    " and SB1.B1_FILIAL      = '" + xfilial ("SB1") + "'"
	_sQuery +=    " and SB1.B1_COD         = V.PRODUTO"
    _sQuery +=    " and V.TIPONFSAID      != 'B'"  // Beneficiamento
    _sQuery +=    " and V.TIPONFSAID      != 'D'"  // Devolucao de compra
	_sQuery +=    " AND V.F4_MARGEM       in ('1', '3')"
	_sQuery +=    " AND V.F4_ESTOQUE       = 'S'"
	_sQuery +=    " AND V.TIPOPROD         = 'PA'"
	_sQuery +=    " AND V.ORIGEM           = 'SD2'"
 	_sQuery +=    " and V.EMPRESA          = '" + cEmpAnt + "'"
	_sQuery +=    " and V.EMISSAO         between '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	_sQuery += " GROUP BY FILIAL, EMISSAO, PRODUTO, B1_DESC, UMPROD, SB1.B1_VALINEN, SH1.H1_DESCRI"
//	_sQuery += " GROUP BY FILIAL, EMISSAO, PRODUTO, B1_DESC, UMPROD, ZX5_50.X5_DESCRI, SB1.B1_VALINEN, SH1.H1_DESCRI"

	u_log (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)

	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SD2")
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Data inicial do faturamento  ?", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final do faturamento    ?", "D", 08, 0,  "",   "   ", {},                ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return