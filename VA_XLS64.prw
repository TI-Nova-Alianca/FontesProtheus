// Programa...: VA_XLS64
// Autor......: Cláudia Lionço
// Data.......: 10/02/2023
// Descricao..: Exporta Planilha com custo std
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta Planilha com custo std
// #PalavasChave      #EST #CUSTO #CUSTO_STD
// #TabelasPrincipais #SB1 
// #Modulos           #EST
//
// Historico de alteracoes:
//
//
// --------------------------------------------------------------------------
User Function VA_XLS64 (_lAutomat)
	Local cCadastro := "Exporta planilha custo std"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VA_XLS64"
	
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
// Gera planilha
Static Function _Gera()
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     B1_CODLIN AS LINHA_COML "
    _oSQL:_sQuery += "    ,RTRIM(ZX5_39.ZX5_39DESC) AS DESCR_LINHA "
    _oSQL:_sQuery += "    ,B1_COD AS PRODUTO "
    _oSQL:_sQuery += "    ,B1_DESC AS DESCRICAO "
    _oSQL:_sQuery += "    ,B1_GRUPO AS GRUPO "
    _oSQL:_sQuery += "    ,BM_DESC AS DESC_GRUPO  "
    _oSQL:_sQuery += "    ,B1_CUSTD AS CUSTO_STD_ATUAL "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += "  LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_39 "
    _oSQL:_sQuery += " 	    ON (ZX5_39.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND ZX5_39.ZX5_FILIAL = '' "
    _oSQL:_sQuery += " 			AND ZX5_39.ZX5_TABELA = '39' "
    _oSQL:_sQuery += " 			AND ZX5_39.ZX5_39COD = SB1.B1_CODLIN ) "
    _oSQL:_sQuery += "  LEFT JOIN " + RetSQLName ("SBM") + " SBM "
    _oSQL:_sQuery += " 	    ON (SBM.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SBM.BM_GRUPO = SB1.B1_GRUPO) "
    _oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND B1_TIPO BETWEEN '" + mv_par01 +"' AND '"+ mv_par02 +"'"
    if mv_par03 == 1
        _oSQL:_sQuery += " AND B1_VAFORAL = 'N'
    else
        _oSQL:_sQuery += " AND B1_VAFORAL = 'S'
    endif
    _oSQL:_sQuery += " AND B1_MSBLQL = '2'

	_oSQL:ArqDestXLS = 'VA_XLS64'
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri              tipo tam dec valid F3  opcoes (combo)        help
	aadd (_aRegsPerg, {01, "Tipo de           ", "C", 2,  0,  "",   "02", {},                   ""})
	aadd (_aRegsPerg, {02, "Tipo até          ", "C", 2,  0,  "",   "02", {},                   ""})
	aadd (_aRegsPerg, {03, "Fora de linha     ", "N", 1,  0,  "",    "" , {'Não', 'Sim'},       ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
