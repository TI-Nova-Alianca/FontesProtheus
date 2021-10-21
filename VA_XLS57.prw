// Programa...: VA_XLS57
// Autor......: Robert Koch
// Data.......: 21/10/2021
// Descricao..: Exporta Planilha com saldos por conta contabil x CC (GLPI 11034)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planilha com saldos por conta contabil x CC
// #PalavasChave      #CTB #contabilidade #saldos_conta_CC
// #TabelasPrincipais #CT1 #CQ2 #CTT
// #Modulos 		  #CTB
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function VA_XLS57 (_lAutomat)
	Local cCadastro := "Exporta planilha com saldos por conta contabil x CC"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS57"
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

	_oSQL:_sQuery += " SELECT CQ2_FILIAL AS FILIAL"
	_oSQL:_sQuery +=       ", SUBSTRING (CQ2_DATA, 1, 4) AS ANO"
	_oSQL:_sQuery +=       ", SUBSTRING (CQ2_DATA, 5, 2) AS MES"
	_oSQL:_sQuery +=       ", CQ2_CONTA AS CONTA"
	_oSQL:_sQuery +=       ", RTRIM (CT1_DESC01) AS DESCR_CONTA"
	_oSQL:_sQuery +=       ", CQ2_CCUSTO AS CC"
	_oSQL:_sQuery +=       ", RTRIM (CTT_DESC01) AS DESCR_CC"
	_oSQL:_sQuery +=       ", CQ2_DEBITO AS DEBITO"
	_oSQL:_sQuery +=       ", CQ2_CREDIT AS CREDITO"
	_oSQL:_sQuery +=       ", CQ2_DEBITO - CQ2_CREDIT AS SALDO"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("CQ2") + " CQ2 "
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("CT1") + " CT1 "
	_oSQL:_sQuery +=        " ON (CT1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND CT1_FILIAL = '" + xfilial ("CT1") + "'"
	_oSQL:_sQuery +=        " AND CT1_CONTA = CQ2_CONTA)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("CTT") + " CTT "
	_oSQL:_sQuery +=        " ON (CTT.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND CTT_FILIAL = '" + xfilial ("CTT") + "'"
	_oSQL:_sQuery +=        " AND CTT_CUSTO = CQ2_CCUSTO)"
	_oSQL:_sQuery += " WHERE CQ2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CQ2_DATA       between '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=   " AND CQ2_TPSALD     = '1'"
	_oSQL:_sQuery +=   " AND CQ2_MOEDA      = '01'"
	_oSQL:_sQuery +=   " ORDER BY CQ2_DATA, CQ2_FILIAL, CQ2_CONTA, CQ2_CCUSTO"
	_oSQL:ArqDestXLS = 'VA_XLS57'
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//                 Ordem Descri                          tipo tam           dec          valid    F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Data Final   ", "D", 8,  0,  "",   "   ", {},                   	""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
