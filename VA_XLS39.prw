// Programa...: VA_XLS39
// Autor......: Robert Koch
// Data.......: 18/12/2018
// Descricao..: Exportacao das previsoes de agenda de safra para planilha.
//
// Historico de alteracoes:

// --------------------------------------------------------------------------
User Function VA_XLS39 (_lAutomat)
	Local cCadastro := "Exportacao das previsoes de agenda de safra para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS39"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma planilha com")
		AADD(aSays,"associados / variedades esperadas para safra, junto com suas respectivas")
		AADD(aSays,"situacoes, para conferencia.")
		
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
	local _oSQL      := NIL
	local _sAliasQ   := NIL
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := "SELECT *"
	_oSQL:_sQuery += " FROM VA_VAGENDA_SAFRA"
	_oSQL:_sQuery += " WHERE ASSOCIADO + LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND GRPFAM BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery += " ORDER BY GRPFAM, CAD_VITIC, DESCRICAO"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SB2")
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3      Opcoes Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2",  {},    ""})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2",  {},    ""})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {05, "Grupo familiar inicial        ", "C", 6,  0,  "",   "ZAN",  {},    ""})
	aadd (_aRegsPerg, {06, "Grupo familiar final          ", "C", 6,  0,  "",   "ZAN",  {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
