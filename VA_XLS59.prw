// Programa...: VA_XLS59
// Autor......: Robert Koch
// Data.......: 30/05/2022
// Descricao..: Exporta Planilha planilha comparativa qt.movimentadas em OP x qt.estrutura (GLPI 11540)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planilha comparativa qt.movimentadas em OP x qt.estrutura
// #PalavasChave      #EST #PCP #AdmOP #Administracao_OP #Previsto_x_realizado #GLPI_11540
// #TabelasPrincipais #SD3 #SC2 #SG1
// #Modulos           #PCP
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS59 (_lAutomat)
	Local cCadastro := "Exporta planilha comparativa qt.movimentadas em OP x qt.estrutura"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS59"
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
	_oSQL:_sQuery += "SELECT *"
	_oSQL:_sQuery +=  " FROM VA_FAdmOP ('" + mv_par01 + "'"
	_oSQL:_sQuery +=                 ", '" + mv_par02 + "'"
	_oSQL:_sQuery +=                 ", '" + dtos (mv_par03) + "'"
	_oSQL:_sQuery +=                 ", '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery +=                 ", '" + mv_par05 + "'"
	_oSQL:_sQuery +=                 ", '" + mv_par06 + "')"
	_oSQL:_sQuery += " ORDER BY FILIAL"
	_oSQL:_sQuery +=         ", OP"
	_oSQL:_sQuery +=         ", PRODUCAO_QT"  // PARA A PRODUCAO FICAR NO FINAL DA LISTA
	_oSQL:_sQuery +=         ", COMP"
	_oSQL:ArqDestXLS = 'VA_XLS59'
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri                          tipo tam dec valid F3     opcoes (combo)        help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},                   ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},                   ""})
	aadd (_aRegsPerg, {03, "Data movimentacao inicial     ", "D", 8,  0,  "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {04, "Data movimentacao final       ", "D", 8,  0,  "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {05, "OP inicial                    ", "C", 14, 0,  "",   "SC2", {},                   ""})
	aadd (_aRegsPerg, {06, "OP final                      ", "C", 14, 0,  "",   "SC2", {},                   ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
