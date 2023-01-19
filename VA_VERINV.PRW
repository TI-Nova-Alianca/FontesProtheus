// Programa...: VA_VERINV
// Autor......: Cláudia Lionço
// Data.......: 19/01/2023
// Descricao..: Exporta planilha com divergencias de estoque fisico/lote/endereço
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Exporta planilha com divergencias de estoque fisico/lote/endereço
// #PalavasChave      #inventario #verificacao_estoque
// #TabelasPrincipais #SB2, SBF, SB8
// #Modulos           #EST
//
// Historico de alteracoes:
//
//
// --------------------------------------------------------------------------
User Function VA_VERINV(_lAutomat)
	Local cCadastro := "Exporta planilha com divergencias de estoque fisico/lote/endereço"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	//Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VA_VERINV"

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
		//AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If( _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
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

	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " exec VA_SP_VERIFICA_ESTOQUES null, null, null "
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .F.)
return
// //
// // --------------------------------------------------------------------------
// // Cria Perguntas no SX1
// Static Function _ValidPerg ()
// 	local _aRegsPerg := {}
// 	local _aDefaults := {}
	
// 	aadd (_aRegsPerg, {01, "Filial        ", "C", 02, 0,  ""   ,   "", {}, ""})
// 	aadd (_aRegsPerg, {02, "Produto       ", "C", 15, 0,  "SB1",   "", {}, ""})
// 	aadd (_aRegsPerg, {03, "Almox         ", "C", 02, 0,  "NNR",   "", {}, ""})

// 	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
// Return
