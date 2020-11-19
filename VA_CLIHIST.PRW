// Programa...: VA_CLIHIST
// Autor......: Catia Cardoso
// Data.......: 28/09/2015
// Descricao..: Historicos de Contatos de Clientes
//
// Historico de alteracoes:
// 
// 02/10/2015 - Catia - validar codigo e loja do cliente - deixou gravar loja em branco por isso nao trazia o nome do cliente
// 05/10/2015 - Catia - opcao de visualizac o cadastro do cliente
// 13/10/2015 - Catia - não estava atualizando ok os campos de proximo contato e tipo do proximo contato
// 02/05/2016 - Catia - criadas mais opcoes de indices e tirado o indice fixo que tinha no programa
// 03/05/2016 - Catia - erro nos indices - tirada a filial do indice 1
// 24/06/2016 - Catia - incluido campo justificativa
// 22/08/2016 - Catia - incluida a opcao de posicao do cliente 
// ------------------------------------------------------------------------------------------------------------------
User Function VA_CLIHIST ()
	private aRotina   := {}
	private cCadastro := "Historicos de Contatos de Clientes"
	
	chkfile("ZAC")

	aAdd(aRotina, {"Visualizar"           , "U_ZACA"      , 0, 2})
	aAdd(aRotina, {"Novo"                 , "U_ZACA"      , 0, 3})
	aAdd(aRotina, {"Proximo"              , "U_ZACA"      , 0, 4})
	aAdd(aRotina, {"Visualiza Cadastro"   , "U_VCLIZAC"   , 0, 2})
	aAdd(aRotina, {"Altera Telefone"      , "U_ALT_FONE"  , 0, 2})
	aAdd(aRotina, {"Altera Email"         , "U_ALT_EMAIL" , 0, 2})
	aadd(aRotina, {"&Posicao do Cliente"  , "U_POSCLIHIST", 0 ,5})
	
	
	_wfiltro := "ZAC_SEQ= '000001'"
	dbSelectArea ("ZAC")
	dbSetOrder(1)
	mBrowse(,,,, "ZAC",,,,,,,,,,,,,,_wfiltro)
return

// --------------------------------------------------------------------------
// Tela de manutencao
user function ZACA ()
	//local   _aUser   := {}
	private _sRotina := ""
	private _sDescri := ""
	private aHeader  := {}
	private aCols    := {}
	private N        := 1
	private aGets    := {}
	private aTela    := {}

	nOpc := 2
	if inclui .or. altera
		nOpc = 4
	endif

	if inclui
		_sCli    = CriaVar ("ZAC_CLI")
		_sLoja   = CriaVar ("ZAC_LOJA")
		_sNome   = CriaVar ("ZAC_NOME")
		_sUCont  = CriaVar ("ZAC_UDATA")
		_sTCont  = CriaVar ("ZAC_UTP")
		_sUuser  = CriaVar ("ZAC_UUSER")
		_sBprox  = CriaVar ("ZAC_BPROX")
		_sBtppro = CriaVar ("ZAC_BTPPRO")
		_sFone   = CriaVar ("ZAC_FONE")
		_sEmail  = CriaVar ("ZAC_EMAIL")
	else
		_sCli   = zac -> ZAC_CLI
		_sLoja  = zac -> ZAC_LOJA
		_sNome  = fBuscaCpo ('SA1', 1, xfilial('SA1') + _sCli + _sLoja, "A1_NOME")
		_sUCont = zac -> ZAC_UDATA
		_sTCont = alltrim (X3Combo ("ZAC_UTP", zac -> ZAC_UTP))
		_sUuser = zac -> ZAC_UUSER
		_sBprox = zac -> ZAC_BPROX
		_sBtppro= alltrim (X3Combo ("ZAC_BTPPRO", zac -> ZAC_BTPPRO))
		_sFone  = fBuscaCpo ('SA1', 1, xfilial('SA1') + _sCli + _sLoja, "A1_TEL")
		_sEmail = fBuscaCpo ('SA1', 1, xfilial('SA1') + _sCli + _sLoja, "A1_EMAIL")
	endif

	// Gera aHeader e aCols.
	aHeader := U_GeraHead ("ZAC", .F., {"ZAC_CLI", "ZAC_LOJA", "ZAC_NOME", "ZAC_UDATA", "ZAC_UTP", "ZAC_UUSER", "ZAC_BPROX", "ZAC_BTPPRO","ZAC_FONE","ZAC_EMAIL"})
	if ! inclui
		aCols := U_GeraCols ("ZAC", ;  // Alias
		                         1, ;  // Indice
		                      ZAC -> ZAC_CLI, ;  // Seek inicial
		                      ' ZAC -> ZAC_CLI == "' + ZAC -> ZAC_CLI + '"', ;  // While
		                      aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
		                           .F.)  // Executa ou nao os gatilhos.
	else
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif

	// Variaveis do cabecalho da tela:
	aC:={}
	aadd (aC, {"_sCli"  , {15, 5  }, "Cliente"          , "@!", "U_ZAC_VIRT('1')", "SA1", inclui})
	aadd (aC, {"_sLoja" , {15, 100}, "Loja"             , "@!", "U_ZAC_VIRT('1')", "", inclui})
	aadd (aC, {"_sNome" , {15, 130}, "Nome"             , "@!", "", "", .F.})
	aadd (aC, {"_sFone" , {15, 450}, "Fone"             , "@!", "", "", .F.})
	aadd (aC, {"_sUCont", {30, 5  }, "Dt.Ult.Contato"   , "@!", "", "", .F.})
	aadd (aC, {"_sTCont", {30, 130}, "Tipo Ult.Contato" , "@!", "", "", .F.})
	aadd (aC, {"_sUUser", {30, 250}, "Usuario Ult.Cont" , "@!", "", "", .F.})
	aadd (aC, {"_sEmail", {30, 450}, "Email"            , "@!", "", "", .F.})
	aadd (aC, {"_sBprox", {45, 5  }, "Proximo Contato"  , "@!", "", "", .F.})
	aadd (aC, {"_sBtppro",{45, 130}, "Tipo Prox.Contato", "@!", "", "", .F.})
	
	aR := {}
	_aJanela := {100, 100, oMainWnd:nClientHeight - 100, oMainWnd:nClientWidth - 100}  // Janela (dialog) do modelo2
	aCGD := {100,20,118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		aC, ;  // Cabecalho
		aR, ;  // Rodape
		aCGD, ;  // Coordenadas da getdados
		nOpc, ;  // nOPC
		'U_ZAC_LOK()', ;  // Linha OK
		'U_ZAC_TOK()',; // Tudo OK
		, ;  // Gets editaveis
		, ;  // bloco codigo para tecla F4
		, ;  // Campos inicializados
		9999, ;  // Numero maximo de linhas
		_aJanela, ;  // Coordenadas da janela
		.F.)  // Linhas podem ser deletadas.

		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZAC_FILIAL" , xfilial ("ZAC")})
		aadd (_aCposFora, {"ZAC_CLI"    , _sCli          })
		aadd (_aCposFora, {"ZAC_LOJA"   , _sLoja         })
		aadd (_aCposFora, {"ZAC_UDATA"  , _sUCont        })
	    aadd (_aCposFora, {"ZAC_UTP"    , _sTCont        })
	    aadd (_aCposFora, {"ZAC_UUSER"  , _sUuser        })
	    aadd (_aCposFora, {"ZAC_BPROX"  , _sBprox        })
	    aadd (_aCposFora, {"ZAC_BTPPRO" , _sBtppro       })
	    
	    // Grava dados do aCols.
		ZAC -> (dbsetorder (5)) 
		for N = 1 to len (aCols)
			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if ZAC -> (dbseek (_sCli + _sLoja + dtos(GDFieldGet ("ZAC_DATA")) + GDFieldGet ("ZAC_HORA"), .F.))
			//if ZAC -> (dbseek ( _sCli + _sLoja , .F.))
				// Alteracao
				Reclock ("ZAC", .F.)
				U_GrvACols ("ZAC", N, _aCposFora)
				msunlock ("ZAC")
			else  // A linha ainda nao existe no arquivo
				reclock ("ZAC", .T.)
				U_GrvACols ("ZAC", N, _aCposFora)
				msunlock ("ZAC")
			endif
		next
		// verifica se existem dados alterados para atualizar
		_sSQL := ""
    	_sSQL += " SELECT ZAC_SEQ"
	 	_sSQL += "      , R_E_C_N_O_"
  		_sSQL += "   FROM ZAC010"
 		_sSQL += "  WHERE D_E_L_E_T_=''"
   		_sSQL += "    AND ZAC_CLI   = '" + _sCli + "'"
   		_sSQL += "    AND ZAC_LOJA  = '" + _sLoja + "'"
   		_sSQL += "    AND ZAC_SEQ    = '' "
		aAtualiza := U_Qry2Array(_sSQL)
    	if len(aAtualiza)>0
		
			// atualiza o ultimo contato, o ultimo tipo, o ultimo usuario
			_sSQL := ""
	    	_sSQL += " SELECT ZAC_DATA"
		 	_sSQL += "      , ZAC_TP"
		 	_sSQL += "      , ZAC_USER"
		 	_sSQL += "      , R_E_C_N_O_"
	  		_sSQL += "   FROM ZAC010"
	 		_sSQL += "  WHERE D_E_L_E_T_=''"
	   		_sSQL += "    AND ZAC_CLI   = '" + _sCli + "'"
	   		_sSQL += "    AND ZAC_LOJA  = '" + _sLoja + "'"
			_sSQL += "  ORDER BY R_E_C_N_O_ DESC"
	    	
	    	aDados := U_Qry2Array(_sSQL)
	    	if len(aDados)>0
	    		// atualiza os dados do ultimo contato
	    		_sSQL := ""
	    		_sSQL += " UPDATE " + RetSQLName ("ZAC")
				_sSQL += "    SET ZAC_UDATA  = '" + dtos(aDados[1,1]) + "'"
				_sSQL += "      , ZAC_UTP    = '" + aDados[1,2] + "'"
				_sSQL += "      , ZAC_UUSER  = '" + aDados[1,3] + "'"
				_sSQL += "  WHERE D_E_L_E_T_ = ''"
				_sSQL += "    AND ZAC_CLI    = '" + _sCli + "'"
	   			_sSQL += "    AND ZAC_LOJA   = '" + _sLoja + "'"
	   			if TCSQLExec (_sSQL) < 0
					u_help ("Nao foi possivel atualizar dados de ultimo contato (ZAC). Erro no UPDATE.")
				endif
				// atualiza a sequencia
				_sSQL := ""
	    		_sSQL += " UPDATE " + RetSQLName ("ZAC")
				_sSQL += "    SET ZAC_SEQ    = '" + strzero(len(aDados),6) + "'"
				_sSQL += "  WHERE D_E_L_E_T_ = ''"
				_sSQL += "    AND ZAC_CLI    = '" + _sCli + "'"
	   			_sSQL += "    AND ZAC_LOJA   = '" + _sLoja + "'"
	   			_sSQL += "    AND ZAC_SEQ    = '' "
	   			if TCSQLExec (_sSQL) < 0
					u_help ("Nao foi possivel atualizar dados de ultimo contato (ZAC). Erro no UPDATE.")
				endif
	    	endif
	    	
	    	// atualiza o proximo contato e o proximo tipo de contato
			_sSQL := ""
	    	_sSQL += " SELECT TOP 1 ZAC_PROX"
		 	_sSQL += "      , ZAC_TPPROX"
		 	_sSQL += "   FROM ZAC010"
	 		_sSQL += "  WHERE D_E_L_E_T_=''"
	   		_sSQL += "    AND ZAC_CLI   = '" + _sCli + "'"
	   		_sSQL += "    AND ZAC_LOJA  = '" + _sLoja + "'"
			_sSQL += "  ORDER BY R_E_C_N_O_ DESC"  // ALTERADO PARA QUE BUSQUE SEMPRE O ULTIMO CONTATO PARA ATUALIZAR O PROXIMO CONTATO
			aDados := U_Qry2Array(_sSQL)
			if len(aDados)>0
				// atualiza os dados do proximo contato
	    		_sSQL := ""
	    		_sSQL += " UPDATE " + RetSQLName ("ZAC")
				_sSQL += "    SET ZAC_BPROX  = '" + dtos(aDados[1,1]) + "'"
				_sSQL += "      , ZAC_BTPPRO = '" + aDados[1,2] + "'"
				_sSQL += "  WHERE D_E_L_E_T_ = ''"
				_sSQL += "    AND ZAC_CLI    = '" + _sCli + "'"
	   			_sSQL += "    AND ZAC_LOJA   = '" + _sLoja + "'"
	   			_sSQL += "    AND ZAC_SEQ= '000001'"
	   			if TCSQLExec (_sSQL) < 0
					u_help ("Nao foi possivel atualizar dados de ultimo contato (ZAC). Erro no UPDATE.")
				endif
			endif		
		endif
	endif
return

user function ZAC_TOK()
	local _lRet    := .T.
	if empty(_sCli)
		u_help ("Informe o cliente.")
		_lRet = .F.
	endif
	if _lRet .and. empty(_sLoja)
		u_help ("Informe a loja do cliente.")
		_lRet = .F.
	endif
	if _lRet .and. len(alltrim(_sLoja)) != 2
		u_help ("Loja do cliente inválida.")
		_lRet = .F.
	endif
return _lRet

user function ZAC_LOK()
	local _lRet    := .T.
	//local _nLinha  := 0

	if ! empty(GDFieldGet ("ZAC_TPPROX")) .and. empty(GDFieldGet ("ZAC_PROX"))
		u_help ("Informe data do proximo contato.")
		_lRet = .F.
	endif
					
	if _lRet .and. ! empty(GDFieldGet ("ZAC_PROX"))
		if _lRet .and. empty(GDFieldGet ("ZAC_TPPROX"))
			u_help ("Informetipo do proximo contato.")
			_lRet = .F.
		endif			 
		if _lRet
			if GDFieldGet ("ZAC_PROX") <= GDFieldGet ("ZAC_DATA")
				u_help ("Data do proximo contato invalida. Menor que a data do contato.")
				_lRet = .F.
			endif
		endif
	endif	
	
	if _lRet .and. empty(GDFieldGet ("ZAC_CONT"))
		u_help ("Deve ser informado o nome da pessoa do contato")
		_lRet = .F.
	endif
	
	if _lRet .and. empty(GDFieldGet ("ZAC_DESC"))
		u_help ("Deve ser informado a descricao do contato")
		_lRet = .F.
	endif
	
	if _lRet .and. empty(GDFieldGet ("ZAC_TP"))
		u_help ("Deve ser informado o tipo do contato")
		_lRet = .F.
	endif
	
return _lRet

user function ZAC_VIRT(_wcampo)
	_lret = ''
	if _wcampo = '1'
		_sNome = fbuscacpo ("SA1", 1, xfilial ("SA1") + _sCli, "A1_NOME")
	endif		
return _lret

user function VCLIZAC()
	// posiciona o SA1 e chama função visualizar
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial('SA1')+ ZAC->ZAC_CLI + ZAC->ZAC_LOJA)
	A030Visual('SA1',1,2)
return	

// posicao do cliente
user function POSCLIHIST()
	// posicioina o SA1 no cliente do browse
	if ! u_zzuvl ('036', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina.")
	else
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial('SA1')+ ZAC->ZAC_CLI + ZAC->ZAC_LOJA)
		// chama função padrao da posicao de cliente
		a450F4Con()
	endif		
return

user function ALT_FONE()
	local _aAreaAnt  := U_ML_SRArea ()
	_lContinua = .T.
	// -- posiciona no SA1
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial('SA1')+ ZAC->ZAC_CLI + ZAC->ZAC_LOJA)
	do while _lContinua
		_wFone = U_Get ("Informe o Telefone:    ", "C", 15, "@R (99)9999.99999999", "", sa1 -> a1_tel, .F., '.t.')
		if _wFone = NIL  // Usuario cancelou
			_lContinua = .F.
		else
			exit			
		endif
	enddo		
	
	if _lContinua
		reclock ("SA1", .F.)
			sa1 -> a1_tel   =  _wFone
		msunlock ()      
		
		_ntexto:= 'Alterado Telefone do Cliente'          
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SA1004"
		_oEvento:Texto	   = _ntexto
		_oEvento:Filial	   = xfilial("ZAC")
		_oEvento:Cliente   = zac -> zac_cli
		_oEvento:LojaCli   = zac -> zac_loja
		_oEvento:Grava ()
	endif
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return

user function ALT_EMAIL()
	local _aAreaAnt  := U_ML_SRArea ()
	_lContinua = .T.
	// -- posiciona no SA1
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial('SA1')+ ZAC->ZAC_CLI + ZAC->ZAC_LOJA)
	do while _lContinua
		_wEmail = U_Get ("Informe o Email:    ", "C", 60, "", "", sa1 -> a1_email, .F., '.t.')
		if _wEmail = NIL  // Usuario cancelou
			_lContinua = .F.
		else
			exit			
		endif
	enddo		

	if _lContinua
		reclock ("SA1", .F.)
			sa1 -> a1_email =  _wEmail	 
		msunlock ()      
		
		_ntexto:= 'Alterado Email do Cliente'          
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SA1004"
		_oEvento:Texto	   = _ntexto
		_oEvento:Filial	   = xfilial("ZAC")
		_oEvento:Cliente   = zac -> zac_cli
		_oEvento:LojaCli   = zac -> zac_loja
		_oEvento:Grava ()
	endif
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
