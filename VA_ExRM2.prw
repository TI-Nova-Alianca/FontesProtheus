// Programa:  VA_ExRM2
// Autor:     Robert Koch
// Data:      24/10/2008
// Cliente:   Alianca
// Descricao: Conecta matriz e solicita importacao de arquivos do replica, que
//            foram transferidos por FTP por rotina anterior.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function VA_ExRM2 ()
	Local cCadastro  := "Verifica importacao do replica na matriz."
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.  // Para controlar se o usuario acessou as perguntas.
	private cPerg := "EXRM_2"
	
	if cNumEmp != "0103"
		u_help ("Programa especifico para uso na filial de Livramento. Para uso em outras filiais, solicite manutencao do mesmo.")
	else
	
		// Cria as perguntas na tabela SX1
		_validPerg()
		Pergunte(cPerg,.F.)
		
		AADD(aSays," ")
		AADD(aSays,"Este programa deve ser executado na filial e tem como objetivo")
		AADD(aSays,"verificar a importacao do REPLICA na matriz.")
		AADD(aSays,"")
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _BatchTOK() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			processa ({|| _AndaLogo ()})
		EndIf
	endif
return



// --------------------------------------------------------------------------
// Verifica 'Tudo OK' do FormBatch.
Static Function _BatchTOK ()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _lContinua := .T.
	local _oServer   := NIL
	local _aRPCRet   := {}

	if _lContinua
		incproc ("Conectando matriz")
		_oServer := RpcConnect (mv_par01, mv_par02, mv_par03, cEmpAnt, cFilAnt)
		If valtype (_oServer) != "O"
			u_help ("Nao foi possivel conectar com a matriz.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_oServer:CallProc ("RPCSetType", 3)  // Nao consome licenca
		if _oServer == NIL
			u_help ("Erro ao conectar com a matriz.")
		else
			_aRPCRet := _oServer:CallProc("U_RPCMat05", cNumEmp)
			RpcDisconnet(_oServer)
			if valtype (_aRPCRet) != "A" .or. (valtype (_aRPCRet) == "A" .and. len (_aRPCRet) != 2)
				u_help ("Matriz retornou dados em formato desconhecido. Provavel erro de processamento na matriz.")
				_lContinua = .F.
			else
				// A posicao 1 do retorno indica o sucesso ou nao da operacao.
				if ! _aRPCRet [1]
					u_help ("Erro no processamento na matriz: " + chr (13) + chr (10) + _aRPCRet [2])
					_lContinua = .F.
				else
					u_help ("Dados importados com sucesso na matriz.")
				endif
			endif
		endif
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Endereco IP servidor matriz   ", "C", 15, 0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Porta no servidor matriz      ", "N", 5,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Ambiente no servidor matriz   ", "C", 30, 0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
