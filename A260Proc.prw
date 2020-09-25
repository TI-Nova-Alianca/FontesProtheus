// Programa:  A260Proc
// Autor:     Robert Koch
// Data:      20/06/2013
// Descricao: Gera transferencia de estoque, com base na rotina A260Processa.
//
// Historico de alteracoes:
// 21/09/2013 - Robert - Implementado estorno de transferencia.
// 08/08/2014 - Robert - Passa a receber parametros de lote e endereco.
// 30/09/2015 - Robert - Aborta movimentacao quando quantidade negativa ou zerada.
// 08/10/2015 - Robert - Grava campos D3_HADTINC e D3_VAHRINC.
// 27/01/2016 - Robert - Posiciona SB1 antes de gerar a transferencia.
// 28/02/2017 - Robert - Gravacao dos campos D3_VAMOTIV e D3_VACHVEX.
// 06/03/2017 - Robert - Gravacao do campo D3_VALAUDO.
// 10/04/2017 - Robert - Nao validava se o endereco destino existia no almoxarifado destino.
// 11/04/2017 - Robert - Campos D3_VADTINC e D3_VAHRINC passam a ser alimentados via default do SQL.
//

// --------------------------------------------------------------------------
user function A260Proc (_sProdOri, _sAlmOri, _nQuant, _dData, _sProdDest, _sAlmDest, _aRecnEst, _sLoteOri, _sLoteDest, _sEndOri, _sEndDest, _sMotivo, _sChvEx)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _lContinua := .T.
	local _aAutoSB9  := {}
	local _aAutoSD3  := {}
	local _sDocSD3   := ""
	local _xRet      := NIL
	local _oSQL      := NIL
	local _sLaudo    := ""
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.

//	u_logIni ()
	_sMotivo := iif (_sMotivo == NIL, "", _sMotivo)
	_sChvEx := iif (_sChvEx == NIL, "", _sChvEx)
	
//	u_log ('param.:', 'prodori:', _sProdOri, 'almori:', _sAlmOri, 'qunt:', _nQuant, 'data:', _dData, 'prodest:', _sProdDest, 'amdest:', _sAlmDest, 'aRecnEst:', _aRecnEst, 'loteori:', _sLoteOri, 'lotedest:', _sLoteDest, 'endori:', _sEndOri, 'enddest:', _sEndDest, 'motivo:', _sMotivo, 'chvext:', _sChvEx)

	_sErroAuto  := ""  // Variavel para erros de rotinas automaticas. Deixar tipo 'private'.

	if valtype (_aRecnEst) == "A"  // Estornar transferencia
		if len (_aRecnEst) != 2
			u_help ("Array de 'recnos' a estornar com tamanho invalido.")
		else
			u_log ('vou estornar os seguintes registros do SD3:', _aRecnEst)
	
			// Variaveis necessarias para a rotina de transferencias
			PRIVATE cCusMed   := GetMv("MV_CUSMED")  // Identifica se o calculo do custo eh: O = On-Line ou M = Mensal
			PRIVATE cCadastro := "Transferencias"
			PRIVATE aRegSD3   := {}
			If cCusMed == "O"
				PRIVATE nHdlPrv // Endereco do arquivo de contra prova dos lanctos cont.
				PRIVATE lCriaHeader := .T. // Para criar o header do arquivo Contra Prova
				PRIVATE cLoteEst 	// Numero do lote para lancamentos do estoque
				
				// Posiciona numero do Lote para Lancamentos do Faturamento
				dbSelectArea("SX5")
				dbSeek(xFilial()+"09EST")
				cLoteEst:=IIF(Found(),Trim(X5Descri()),"EST ")
				PRIVATE nTotal := 0 	// Total dos lancamentos contabeis
				PRIVATE cArquivo	// Nome do arquivo contra prova
			EndIf
	
			// Para estorno passar o 15o. parametro com .T.
			_xRet = a260Processa (NIL, ;  // Produto origem
			NIL, ;  // Almox origem
			NIL, ;  // Quantidade a transferir
			NIL, ;
			NIL, ;
			NIL, ;  // Quant segunda UM
			NIL, ;  // Sub-lote
			_sLoteOri, ;  // Lote origem
			NIL, ;  // Validade
			NIL, ;  // Numero de serie
			NIL, ;  // Localizacao origem
			NIL, ;  // Produto destino
			NIL, ;  //  Localizacao destino
			NIL, ;
			.T., ;    // Indica se eh estorno
			_aRecnEst [1], _aRecnEst [2], "MATA260",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,0, ;  // Dados para APDL
			NIL)  // Lote destino
			A260Comum ()
		endif

	else  // Transferir
	
		if _lContinua .and. _nQuant <= 0
			u_help ("Quantidade a transferir zerada ou negativa. Verifique a rotina que solicitou a transferencia.")
			_lContinua = .F.
		endif
		
		if _lContinua .and. ! empty (_sEndDest)
			sbe -> (dbsetorder (1))  // BE_FILIAL+BE_LOCAL+BE_LOCALIZ
			//u_log ('procurando SBE com chave >>' + xfilial ("SBE") + _sAlmDest + _sEndDest + '<<')
			if ! sbe -> (dbseek (xfilial ("SBE") + _sAlmDest + _sEndDest, .F.))
				u_help ("Local / endereco destino nao cadastrado.")
				_lContinua = .F.
			endif
		endif
	
		// Se o produto ainda nao existe no almoxarifado destino, cria-o, para nao bloquear a transferencia de estoque.
		if _lContinua
			sb2->(dbsetorder(1))
			if ! sb2 -> (dbseek (xfilial ("SB2") + _sProdDest + _sAlmDest))
				CriaSB2 (_sProdDest, _sAlmDest)
			endif
		endif
	
		// Posiciona SB1 (tive casos de gravar o D3_TIPO errado... creio que pode ser isso)
		if _lContinua
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + _sProdOri, .F.))
				u_help ("Cadastro do produto '" + _sProdOri + "' nao encontrado. Transferencia nao sera' realizada.")
				_lContinua = .F.
			endif
		endif

		if _lContinua
	
			// Busca laudo do tanque, caso exista.
			if _sLoteDest != _sLoteOri .and. ! empty (_sEndOri)
				_sLaudo = U_LaudoEm (_sProdOri, _sLoteOri, _dData)
			endif

			// Nao gera a transferencia atraves de rotina automatica por que a mesma nao permite
			// gravar campos adicionais. Da forma como foi montado aqui, pode-se obter os
			// 'recnos' do SD3 para posterior gravacao de dados adicionais.
	
			// Variaveis necessarias para a rotina de transferencias
			PRIVATE cCusMed   := GetMv("MV_CUSMED")  // Identifica se o calculo do custo eh: O = On-Line ou M = Mensal
			PRIVATE cCadastro := "Transferencias"
			PRIVATE aRegSD3   := {}
			private cCodOrig  := _sProdOri   // Necessaria para o P.E. A260Grv
			private cCodDest  := _sProdDest  // Necessaria para o P.E. A260Grv
			If cCusMed == "O"
				PRIVATE nHdlPrv // Endereco do arquivo de contra prova dos lanctos cont.
				PRIVATE lCriaHeader := .T. // Para criar o header do arquivo Contra Prova
				PRIVATE cLoteEst 	// Numero do lote para lancamentos do estoque
				
				// Posiciona numero do Lote para Lancamentos do Faturamento
				dbSelectArea("SX5")
				dbSeek(xFilial()+"09EST")
				cLoteEst:=IIF(Found(),Trim(X5Descri()),"EST ")
				PRIVATE nTotal := 0 	// Total dos lancamentos contabeis
				PRIVATE cArquivo	// Nome do arquivo contra prova
			EndIf
	
			// Gera numero para proximo documento.
			_sDocSD3 := nextnumero ("SD3", 2, "D3_DOC", .t.)
	
			// Para estorno passar o 15o. parametro com .T.
			a260Processa (;
			_sProdOri, ;              // Produto origem
			_sAlmOri, ;               // Local (almox) origem
			_nQuant, ;                // Quantidade a transferir
			_sDocSD3, ;               // Docto
			_dData, ;                 // Data emissao
			NIL, ;                    // Quant segunda UM
			NIL, ;                    // Sub-lote
			_sLoteOri, ;              // Lote origem
			criavar("D3_DTVALID"), ;  // Validade
			NIL, ;                    // Numero de serie
			_sEndOri, ;               // Localizacao (endereco) origem
			_sProdDest, ;             // Produto destino
			_sAlmDest, ;              //  Local (almox) destino
			_sEndDest, ;              // Localizacao (endereco) destino
			.F., ;                    // Indica se eh estorno
			NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL, ;  // Dados para APDL
			_sLoteDest)               // Lote destino
			A260Comum ()

			// Recnos dos registros gravados no SD3.
			_xRet = aclone (aRegSD3)

			if len (_xRet) == 2
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " UPDATE " + RetSQLName ("SD3")
				_oSQL:_sQuery += " SET D3_VACHVEX = '" + _sChvEx + "',"
				_oSQL:_sQuery +=     " D3_VAMOTIV = '" + alltrim (left (_sMotivo, TamSX3 ("D3_VAMOTIV")[1])) + "'"
				//_oSQL:_sQuery +=     " D3_VALAUDO = '" + _sLaudo + "'"
				_oSQL:_sQuery += " WHERE R_E_C_N_O_ IN (" + cvaltochar (_xRet [1]) + " , " + cvaltochar (_xRet [2]) + ")"
				//u_log (_oSQL:_sQuery)
				_oSQL:Exec ()

				// Se existe laudo no endereco origem, cria um novo no endereco destino para manter a rastreabilidade.
				if _sLoteDest != _sLoteOri .and. ! empty (_sLaudo)
					U_CpLaudo (_sLaudo, _sProdDest, _sAlmDest, _sEndDest, _sLoteDest, _nQuant)
				endif

			else
				u_log ('[' + procname () + ']: Transferencia nao foi realizada.')
			endif
		endif
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return _xRet
