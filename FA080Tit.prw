// Programa:   FA080Tit
// Autor:      Robert Koch
// Data:       26/02/2008
// Descricao:  P.E. de confirmacao da baixa manual de titulos a pagar.
//             Criado inicialmente para chamar impressao de cheques.
// 
// Historico de alteracoes:
// 05/03/2008 - Robert  - Impressao do cheque passa a ser feita em funcao externa.
// 02/03/2011 - Robert  - Atualizacao de saldo do arquivo SZI.
// 28/03/2011 - Robert  - Incluido tratamento pata ZI_TM = '03'.
// 07/07/2011 - Robert  - Nao olha mais o tipo de movimento do SZI.
// 18/06/2012 - Robert  - Avisa usuario se estiver fazendo baixa com data diferente da data base do sistema.
// 12/04/2013 - Leandro - verifica se o título a ser baixado possui alguma pendência na ZZN (controle de divergência de conhecimento de frete)
// 18/08/2016 - Catia   - Não permite baixar titulos com data de debito diferente da data de digitacao
// 16/02/2023 - Claudia - Retirada validações de datas. GLPI 12608
//
// --------------------------------------------------------------------------
user function fa080tit ()
	local _lRet     := .T.
	local _lRet2    := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	u_logIni ()
	
	// if _lRet .and. dBaixa != dDebito
	// 	u_help ('A data de baixa e data de debito devem ser iguais!')
	// 	_lRet := .F. // não permite a baixa a pagar se essas datas estiverem diferentes
	// endif
	
	// if _lRet .and. dBaixa != dDataBase
	// 	_lRet = U_msgnoyes ("Lembrete:" + chr (13) + chr (10) + "Voce esta fazendo uma baixa com data diferente da data base do sistema. Confirma assim mesmo?")
	// endif
		
	// if _lRet
	// 	if ! empty (cCheque) .and. U_msgyesno ("Deseja imprimir o cheque agora?")
	// 		U_ImpCheq (cCheque, cBenef, nValPgto, dBaixa, cBanco, alltrim (sm0 -> m0_cidcob), "1")
	// 	endif
	// endif

    // verifica se tem pendência na ZZN
	dbselectarea('ZZN')
	dbsetorder(1)
	dbseek(xFilial('ZZN')+SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_FORNECE+SE2->E2_LOJA)
	if found()
		while SE2->E2_PREFIXO+SE2->E2_NUM+SE2->E2_FORNECE+SE2->E2_LOJA == ZZN->ZZN_SERENT+ZZN->ZZN_DOCENT+ZZN->ZZN_FORN+ZZN->ZZN_LOJFOR
			if ZZN->ZZN_STATUS == '3' // bloqueado   
				_lRet := .F. // bloqueia a baixa do título a pagar						
			endif
			
			if ZZN->ZZN_STATUS == '1' // não revisado   
				_lRet2 := .F.	// não bloqueia a baixa do título a pagar...só mostra a mensagem					
			endif
			dbselectarea('ZZN')
			dbskip()
		enddo    
		
		if !_lRet
			u_help ('Existe registro bloqueado deste título no controle de divergência de conhecimento de frete !')
		endif
		
		if !_lRet2
			u_help ('Existe registro não verificado deste título no controle de divergência de conhecimento de frete !')
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	u_logFim ()
	
return _lRet
