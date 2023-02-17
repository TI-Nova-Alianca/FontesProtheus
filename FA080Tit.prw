// Programa.: FA080Tit
// Autor....: Robert Koch
// Data.....: 26/02/2008
// Descricao: P.E. de confirmacao da baixa manual de titulos a pagar.
// 
// Tags para automatizar catalogo de customizacoes:
// #Programa          #ponto_de_entrada
// #Descricao		  #P.E. de confirmacao da baixa manual de titulos a pagar.
// #PalavasChave      #transferencias #conta_transitoria #baixa #contas_a_pagar
// #TabelasPrincipais #ZA4 #ZA5 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 05/03/2008 - Robert  - Impressao do cheque passa a ser feita em funcao externa.
// 02/03/2011 - Robert  - Atualizacao de saldo do arquivo SZI.
// 28/03/2011 - Robert  - Incluido tratamento pata ZI_TM = '03'.
// 07/07/2011 - Robert  - Nao olha mais o tipo de movimento do SZI.
// 18/06/2012 - Robert  - Avisa usuario se estiver fazendo baixa com data diferente 
//                        da data base do sistema.
// 12/04/2013 - Leandro - verifica se o título a ser baixado possui alguma pendência na ZZN 
//                        (controle de divergência de conhecimento de frete)
// 18/08/2016 - Catia   - Não permite baixar titulos com data de debito diferente da data de digitacao
// 16/02/2023 - Claudia - Retirada validações de datas. GLPI 12608
// 17/02/2023 - Claudia - Incluida a transferencia de valores entre filiais. GLPI: 12671
//
// ------------------------------------------------------------------------------------------------------
User Function FA080Tit()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	u_logIni ()
	
	// Verifica se tem pendência na ZZN
	_lRet := VerificaZZN(SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_FORNECE, SE2->E2_LOJA)

	// Tranferencia entre filiais
	//If xFilial("SE2") <> '01' // Transferencia de valores das filiais para Matriz
	//	If msgyesno("Deseja realizar transferencia do valor para matriz?","Transferência entre filiais")
	//		U_VA_TRPGTO()
	//	EndIf
	//EndIf
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	u_logFim ()
	
Return _lRet
//
// ------------------------------------------------------------------------------------------
// Verifica se tem pendência na ZZN
Static Function VerificaZZN(sPrefixo, sNumero, sFornece, sLoja)
	local _lRet  := .T.
	local _lRet2 := .T.

	dbselectarea('ZZN')
	dbsetorder(1)
	dbseek(xFilial('ZZN') + sPrefixo + sNumero + sFornece + sLoja)
	if found()
		while sPrefixo + sNumero + sFornece + sLoja == ZZN->ZZN_SERENT+ZZN->ZZN_DOCENT+ZZN->ZZN_FORN+ZZN->ZZN_LOJFOR
			if ZZN->ZZN_STATUS == '3' 	// bloqueado   
				_lRet := .F. 			// bloqueia a baixa do título a pagar						
			endif
			if ZZN->ZZN_STATUS == '1' 	// não revisado   
				_lRet2 := .F.			// não bloqueia a baixa do título a pagar...só mostra a mensagem					
			endif
			dbselectarea('ZZN')
			dbskip()
		enddo    
		if !_lRet
			u_help('Existe registro bloqueado deste título no controle de divergência de conhecimento de frete!')
		endif
		if !_lRet2
			u_help('Existe registro não verificado deste título no controle de divergência de conhecimento de frete!')
		endif
	endif
Return _lRet
