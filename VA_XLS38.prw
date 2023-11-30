// Programa...: VA_XLS38
// Autor......: Robert Koch
// Data.......: 19/11/2018
// Descricao..: Exportacao para planilha de um kardex resumido por CR (cod.Sisdeclara)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Exportacao para planilha de um kardex resumido por CR (cod.Sisdeclara)
// #PalavasChave      #SISDEVIN #SISDECLARA 
// #TabelasPrincipais #VA_FKARDEX_SISDEVIN
// #Modulos   		  #EST 
//
// Historico de alteracoes:
// 27/09/2019 - Robert - Passa a usar uma funcao do SQL.
// 05/05/2021 - Robert - Passa a usar o metodo :Qry2XLS da classe ClsSQL em vez do programa U_Trb2XLS(). (GLPI 9973).
// 28/11/2023 - Claudia - Incluida busca de insumos. GLPI: 13780
//
// --------------------------------------------------------------------------
User Function VA_XLS38 (_lAutomat)
	Local cCadastro := "Exportacao de planilha de movimentos com resumo por codigo Sisdeclara"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS38"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de movimentos de estoque, com codigo de Sisdeclara,")
		AADD(aSays,"para planilha eletronica.")
		
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
// 'Tudo OK' do FormBatch
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Executa procedure
Static Function _Gera()
	local _oSQL      := NIL
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

	u_logsx1 (cPerg)

	if mv_par04 == 1
		_sInsumos := 'N'
	else
		_sInsumos := 'S'
	endif

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := "SELECT * FROM dbo.VA_FKARDEX_SISDEVIN ('" + cFilAnt + "', '" + mv_par03 + "', '" + dtos (mv_par01) + "', '" + dtos (mv_par02) + "', '" + _sInsumos + "')
	_oSQL:Log ()

	incproc ("Gerando arquivo de exportacao")

	processa ({ || _oSQL:Qry2XLS (.t., .f., .t.)})

	dbselectarea ("SB2")
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                          Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "      ", {},                             ""})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "      ", {},                             ""})
	aadd (_aRegsPerg, {03, "Codigo CR (Sisdeclara)        ", "C", 15, 0,  "",   "SB5   ", {},                             ""})
	aadd (_aRegsPerg, {04, "Busca Insumos?                ", "N", 1 , 0,  "",   "      ", {"Nao", "Sim"},                 ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
