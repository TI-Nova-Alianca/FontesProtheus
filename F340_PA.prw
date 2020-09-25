// Programa:   F340_PA
// Autor:      Robert Koch
// Data:       02/03/2011
// Cliente:    Alianca
// Descricao:  P.E. apos rotina de compensacao de contas a pagar (executado uma vez para cada titulo selecionado).
//             Criado inicialmente para atualizar saldo do arquivo SZI.
// 
// Historico de alteracoes:
// 28/07/2011 - Robert - Gravacao de chave externa nos registros do SE5.
//                     - Soh atualizava o saldo de um dos registros do SZi envolvidos.
// 17/07/2012 - Robert - Gravacao campo E5_vaUser.
// 07/02/2018 - Robert - Metodo AtuSaldo da Classe ClsAssoc nao recebe mais a filial por parametro.
// 12/07/2019 - Andre  - Grava campo E5_VAUSER dentro da query.
// 30/10/2019 - Robert - Passa a gravar avisos e erros usando a classe ClsAviso().
// 17/07/2020 - Robert - Inseridas tags para catalogacao de fontes
//                     - Melhorada chamada de reprocessamento de saldo associado (chamava 2 vezes sem necessidade).
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #PalavasChave      #compensacao #contas_a_pagar
// #TabelasPrincipais #SE5 #FK2
// #Modulos           #FIN

// --------------------------------------------------------------------------
user function F340_PA ()
	local _aAreaAnt := U_ML_SRArea ()

//	u_log2 ('debug', 'Iniciando ' + procname ())

	// Atualiza chaves externas dos arquivos.
	_AtuChv ()
	
	U_ML_SRArea (_aAreaAnt)
//	u_log2 ('debug', 'Finalizando ' + procname ())
return .t.



// --------------------------------------------------------------------------
// Atualiza (se for o caso) o arquivo SZI e demais relacionados.
static function _AtuChv ()
	local _sChvComp  := ""
	local _sChvOrig  := ""
	local _sSQL      := ""
	local _nValor    := 0
	local _sDocumen  := ""
	local _dDtMovto  := ctod ('')
	local _oAssoc    := NIL
	local _dMenorSZI := ctod ('')

//	u_logIni ()
//	u_logtrb ("SE2", .F.)
//	u_log ('')
//	u_logtrb ("SE5", .F.)
//	u_log ('')
//	u_log ("aTitulos:", atitulos)
//	u_log ("strlctpad:", STRLCTPAD)
//	u_log ("Valor que estah sendo compensado:", _nValor)

	// O registro atual do SE2 eh um dos registros que foram selecionados para compansacao (este
	// ponto de entrada eh executado uma vez para cada titulo selecionado).
	_sChvComp = se2 -> e2_vaChvEx
//	u_log ("Chave externa do SE2 que estah sendo compensado....:", _sChvComp)

	// O SE5 posicionado eh o registro correspondente ao movimento de compensacao de um dos titulos
	// que foram selecionados para compensacao.
	_nValor   = se5 -> e5_valor
	_dDtMovto = se5 -> e5_data
	_sDocumen = se5 -> e5_prefixo + se5 -> e5_numero + se5 -> e5_parcela + se5 -> e5_tipo + se5 -> e5_clifor + se5 -> e5_loja
	reclock ("SE5", .F.)
	se5 -> e5_vachvex = _sChvComp
	se5 -> e5_vaUser  = iif (empty (se5 -> e5_vaUser), cUserName, se5 -> e5_vaUser)
	msunlock ()

	// Para encontrar o registro original (aquele em que o usuario estava posicionado quando
	// clicou em 'compensar' usa-se uma variavel private do FINA340 contendo os dados do titulo original.
	se2 -> (dbsetorder (1))  // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	if se2 -> (dbseek (xfilial ("SE2") + StrLctPad, .F.))
		_sChvOrig = se2 -> e2_vachvex
//		u_log ("Chave externa do SE2 orig. (que disparou o movto)..:", _sChvOrig)

		// Atualiza registro do SE5 correspondente ao movimento de compensacao do titulo que originou
		// a compensacao
		_sSQL := ""
		_sSQL += "UPDATE " + RetSQLName ("SE5")
		_sSQL +=   " SET E5_VACHVEX = '" + _sChvOrig + "'"
		_sSQL +=      ", E5_VAUSER  = '" + alltrim(cUserName) + "'"
		_sSQL += " WHERE D_E_L_E_T_ = ''"
		_sSQL +=   " AND E5_FILIAL  = '" + xfilial ("SE5")   + "'"
		_sSQL +=   " AND E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
		_sSQL +=   " AND E5_NUMERO  = '" + se2 -> e2_num     + "'"
		_sSQL +=   " AND E5_PARCELA = '" + se2 -> e2_parcela + "'"
		_sSQL +=   " AND E5_TIPO    = '" + se2 -> e2_tipo    + "'"
		_sSQL +=   " AND E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
		_sSQL +=   " AND E5_LOJA    = '" + se2 -> e2_loja    + "'"
		_sSQL +=   " AND E5_DATA    = '" + dtos (_dDtMovto)  + "'"
		_sSQL +=   " AND E5_DOCUMEN LIKE '" + _sDocumen + "%'"
		_sSQL +=   " AND E5_MOTBX   = 'CMP'"
		_sSQL +=   " AND E5_VACHVEX = ''"
		//u_log2 ('info', _sSQL)
		if TCSQLExec (_sSQL) < 0
		//	U_GrvAviso ('E', 'grpTI', "Erro na atualizacao do SE5 - rotina " + procname () + " - comando: " + _sSQL)
			_oAviso := ClsAviso ():New ()
			_oAviso:CodAviso   = '013'
			_oAviso:Tipo       = 'E'
			_oAviso:Destinatar = 'grpTI'
			_oAviso:Texto      = 'Erro na atualizacao do SE5 compensacao cta.corr. ' + _sSQL
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()
			_lContinua = .F.
		endif
	endif


	// Atualiza no SZI os saldos dos registros envolvidos.
	szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
	if left (_sChvOrig, 3) == "SZI" .and. szi -> (dbseek (xfilial ("SZI") + substr (_sChvOrig, 4), .F.))
//		u_log ("Achei SZI que originou a compensacao. Saldo atual:", szi -> zi_saldo)
		reclock ("SZI", .F.)
		szi -> zi_saldo -= _nValor
		msunlock ()

		// Deixa informacoes prontas para, em seguida, atualizar o saldo do Associado.
		_oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
		_dMenorSZI = iif (empty (_dMenorSZI), szi -> zi_data, min (_dMenorSZI, szi -> zi_data))
//		if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
//		else
//			_oAssoc:AtuSaldo (szi -> zi_data)
//		endif
	endif

	if left (_sChvComp, 3) == "SZI" .and. szi -> (dbseek (xfilial ("SZI") + substr (_sChvComp, 4), .F.))
//		u_log ("Achei SZI que estah sendo compensado. Saldo atual:", szi -> zi_saldo)
		reclock ("SZI", .F.)
		szi -> zi_saldo -= _nValor
		msunlock ()

		// Deixa informacoes prontas para, em seguida, atualizar o saldo do Associado.
		_oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
		_dMenorSZI = iif (empty (_dMenorSZI), szi -> zi_data, min (_dMenorSZI, szi -> zi_data))
//		if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
//		else
//			_oAssoc:AtuSaldo (szi -> zi_data)
//		endif
	endif

	// Se instanciou o associado, recalcula seu saldo.
	if valtype (_oAssoc) == "O" .and. ! empty (_dMenorSZI)
		processa ({ || _oAssoc:AtuSaldo (_dMenorSZI)})
	endif
return
