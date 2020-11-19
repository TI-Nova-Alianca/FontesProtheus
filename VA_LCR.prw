// Programa...: VA_LCR
// Autor......: Robert Koch
// Data.......: 24/06/2008
// Cliente....: Alianca
// Descricao..: Rotina de atualizacao da data de vencimento do limite de credito dos clientes.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_LCR ()
	Local cCadastro  := "Alteracao vencimento limite de credito"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.  // Para controlar se o usuario acessou as perguntas.
	private cPerg := "VA_LCR"
	
	// Cria as perguntas na tabela SX1
	_validPerg()
	Pergunte(cPerg,.F.)
	
	AADD(aSays," ")
	AADD(aSays,"  Este programa tem como objetivo alterar o campo de vencimento")
	AADD(aSays,"  do limite de credito no cadastro de clientes.")
	AADD(aSays,"  Serao alterados apenas os clientes selecionados nos parametros.")
	AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _BatchTOK() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	FormBatch( cCadastro, aSays, aButtons )
	If nOpca == 1
			processa ({|| _AndaLogo ()})
	EndIf
return



// --------------------------------------------------------------------------
// Verifica 'Tudo OK' do FormBatch.
Static Function _BatchTOK ()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _sSQL := ""
	_sSQL := ""
	_sSQL += " Update " + RetSQLName ("SA1")
	_sSQL += "    Set A1_VENCLC  = '" + dtos (mv_par05) + "'"
	_sSQL += "  Where A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_sSQL += "    And D_E_L_E_T_ = ''"
	_sSQL += "    And A1_REGIAO  = '" + mv_par01 + "'"
	_sSQL += "    And A1_RISCO   = '" + {"A","B","C","D","E"}[mv_par02] + "'"
	_sSQL += "    And A1_COD     between '" + mv_par03 + "' and '" + mv_par04 + "'"
	if TCSQLExec (_sSQL) < 0
		u_help ("ERRO na execucao do processo.")
	else
		u_help ("Processo executado.")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Regiao                        ", "C", 3,  0,  "",   "82 ", {},                         "Qual a regiao a ser considerada"})
	aadd (_aRegsPerg, {02, "Tipo de risco                 ", "C", 1,  0,  "",   "   ", {"A","B","C","D","E"},      "Qual tipo de risco a ser considerado"})
	aadd (_aRegsPerg, {03, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},                         "Cliente inicial a ser considerado"})
	aadd (_aRegsPerg, {04, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},                         "Cliente final a ser considerado"})
	aadd (_aRegsPerg, {05, "Novo vencto. limite credito   ", "D", 8,  0,  "",   "   ", {},                         "Nova data a ser gravada no vencimento do limite de credito dos clientes selecionados."})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
