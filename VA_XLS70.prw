// Programa...: VA_XLS70
// Autor......: Claudia Lionço
// Data.......: 12/07/2024
// Descricao..: Exporta planilha com complementos de associados
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planilha com complementos de associados
// #PalavasChave      #complemento_de_safra #safra #nf_complemento
// #TabelasPrincipais #SF1 #SA2
// #Modulos           #COOP
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function VA_XLS70(_lAutomat)
	Local cCadastro := "Exporta planilha com complementos de associados"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif(valtype(_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VA_XLS70"
	
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
Static Function _Gera()
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	_oSQL := ClsSQL():New()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     F1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SA2.A2_NOME AS NOME "
    _oSQL:_sQuery += "    ,F1_FORNECE AS CODIGO "
    _oSQL:_sQuery += "    ,SF1.F1_LOJA AS LOJA "
    _oSQL:_sQuery += "    ,SF1.F1_DOC AS NOTA "
    _oSQL:_sQuery += "    ,SF1.F1_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SUBSTRING(SF1.F1_EMISSAO, 7, 2) + '/' + SUBSTRING(SF1.F1_EMISSAO, 5, 2) + '/' + SUBSTRING(SF1.F1_EMISSAO, 1, 4) AS EMISSAO "
    _oSQL:_sQuery += "    ,SF1.F1_VALMERC AS VALOR "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF1") + " SF1"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " SA2"
    _oSQL:_sQuery += " 	ON SA2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA2.A2_COD = SF1.F1_FORNECE "
    _oSQL:_sQuery += " 		AND SA2.A2_LOJA = SF1.F1_LOJA "
    _oSQL:_sQuery += " WHERE SF1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND F1_DTDIGIT BETWEEN '" + dtos(mv_par01) + "' AND '" + dtos(mv_par02) + "' "
    _oSQL:_sQuery += " AND F1_SERIE = '30' "
    _oSQL:_sQuery += " AND F1_TIPO  = 'C' "
    _oSQL:_sQuery += " ORDER BY SF1.F1_FILIAL, A2_NOME "
    _oSQL:Qry2Xls (.T., .F., .F.)    

return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri                          tipo tam                      dec valid  F3    opcoes (combo)  help
	aadd(_aRegsPerg, {01, "Data inicial                ", "D", 8,                       0,  "",   "SM0", {},             ""})
    aadd(_aRegsPerg, {02, "Data final                  ", "D", 8,                       0,  "",   "SM0", {},             ""})
	U_ValPerg(cPerg, _aRegsPerg, {}, _aDefaults)
Return
