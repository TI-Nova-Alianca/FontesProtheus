// Programa...: VA_XLS71
// Autor......: Claudia Lionço
// Data.......: 09/09/2024
// Descricao..: Relatório custo de uva
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
User Function VA_XLS71(_lAutomat)
	Local cCadastro := "Exporta planilha com custo de uva"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif(valtype(_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VA_XLS71"
	
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
    _oSQL:_sQuery += "     PRODUTO "
    _oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO "
    _oSQL:_sQuery += "    ,AVG(VUNIT_EFETIVO) AS MEDIA_PRECO "
    _oSQL:_sQuery += "    ,B1_CUSTD AS CUSTD "
    _oSQL:_sQuery += "    ,SUM(V.PESO_LIQ) AS PESO "
    _oSQL:_sQuery += " FROM VA_VPRECO_EFETIVO_SAFRA V "
    _oSQL:_sQuery += " 	    ," + RetSQLName("SB1") + " SB1 "
    _oSQL:_sQuery += " WHERE SAFRA = '"+ mv_par01 +"' "
    _oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SB1.B1_FILIAL = '  ' "
    _oSQL:_sQuery += " AND SB1.B1_COD = V.PRODUTO "
    _oSQL:_sQuery += " GROUP BY PRODUTO "
    _oSQL:_sQuery += " 		   ,B1_CUSTD "
    _oSQL:_sQuery += " 		   ,B1_DESC "
    _oSQL:Qry2Xls (.T., .F., .F.)    

return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//               Ordem Descri                  tipo tam                      dec valid  F3    opcoes (combo)  help
	aadd(_aRegsPerg, {01, "Ano Safra            ", "C", 4,                       0,  "",   "", {},             "" })
	U_ValPerg(cPerg, _aRegsPerg, {}, _aDefaults)
Return
