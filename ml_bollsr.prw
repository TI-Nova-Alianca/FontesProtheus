// Programa...: ML_BOLLSR
// Autor......: Alexandre Dalpiaz
// Data.......: 01/09/2003
// Cliente....: Alianca
// Descricao..: Emissao de boletos bancarios
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Geracao e impressao de boletos de cobranca.
// #PalavasChave      #boleto #nosso_numero #cobranca
// #TabelasPrincipais 
// #Modulos           #FAT #FIN
//
// Historico de alteracoes:
// 19/02/2008 - Robert  - Ajustes calculo Sicredi
// 10/03/2008 - Robert  - Nao imprimia desconto financeiro.
// 11/04/2008 - Robert  - Passa a usar a funcao U_PJurBol ().
// 24/04/2008 - Robert  - Passa a ler campo e1_vaDesco e nao mais o a1_DescFin.
//                      - Passa a ler campo e1_vaPJuro em lugar da funcao U_PJurBol.
// 25/04/2008 - Robert  - Valida parametro ML_CLIC19.
// 09/06/2008 - Robert  - Posicao 20 do cod.barras Sicredi alterada de 2 para 1 por solicitacao do banco.
// 03/09/2008 - Robert  - Troca de campos a1_muncob, a1_baicob, a1_estcob para campos padrao.
// 10/12/2008 - Robert  - Liberados bancos 001 e 399 para testes (somente com senha de Admin)
//                      - Separadas por banco as funcoes de nosso numero, cod. barras e linha digitavel.
// 29/12/2008 - Robert  - Banco 399 liberado para producao.
// 19/02/2009 - Robert  - Banco 001 liberado para producao.
//                      - Passa a verificar o parametro VA_BCOBOL.
// 24/02/2009 - Robert  - Envia e-mail de aviso ao financeiro em caso de troca de banco.
// 05/06/2009 - Robert  - Passa a buscar saldo do titulo.
//                      - Melhorados e-mails de aviso e gravacao de eventos ref. reimpressao de boletos.
// 22/06/2009 - Robert  - Geracao do cod. barras do BB eventualmente perdia 1 centavo.
// 07/07/2009 - Robert  - Reabilitada mensagem quando o cliente tem endereco de cobranca e entrega diferentes.
// 23/09/2009 - Robert  - Manda e-mail p/ setor financeiro avisando sobre emissao de boleto p/ cliente especifico.
// 15/10/2009 - Robert  - Busca valor do desconto financeiro em funcao externa usada para CNABs.
// 13/07/2010 - Robert  - Grava evento ao gerar 'nosso numero'.
// 02/02/2011 - Robert  - Implementacao de boleto BB para filial L.Jacinto (convenio BB de 7 posicoes).
//                      - Leitura de agencia e conta dos campos EE_vaBolAg e EE_vaBolCt.
//                      - Nao filtrava filial do SE1 no markbrowse!
// 08/02/2011 - Robert  - Passa a usar o campo E1_VENCREA em todas as situacoes e nao mais E1_VENCTO.
// 10/06/2011 - Robert  - Envia e-mail de aviso para Aline quando end.cobranca diferente do end.entrega.
// 18/07/2012 - Robert  - Eliminados trechos comentariados e ajuste destinatarios avisos antes implem. Banrisul.
// 06/09/2012 - Elaine  - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                        do Titulo com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 04/10/2012 - Elaine  - Alterada mensagem quando nao encontra o banco no VA_BCOBOL - na mensagem dizia que era o MV_BCOBOL
// 17/12/2012 - Elaine  - Incluida funcao de filtro do SE1 dentro da rotina montarel() pois no P11 ele perde o 
//                        filtro já realizado
//                        na _Gera - assim mandava imprimir todos boletos, não somente os filtrados
// 30/10/2014 - Catia   - Liberar para imprimir boletos na filial 13
// 10/12/2014 - Catia   - Boleto do banco SAFRA - correspondente BRADECO
// 23/12/2014 - Catia   - Boleto do banco SANTANDER 
// 30/12/2014 - Catia   - preparado para que a impressao do SAFRA busque do ano o campo composto no nosso numero 09/AA
// 08/06/2015 - Robert  - Passa a validar o campo A1_VAEBOL.
// 09/11/2015 - Catia   - Boleto da CAIXA ECONOMICA
// 02/03/2016 - Catia   - Alteracoes boleto SICREDI
// 18/04/2016 - Catia   - Boletos BB da filial 03 - Livramento
// 01/08/2016 - Catia   - alterado funcao de Trans para Transform
// 09/01/2017 - Catia   - Boletos Bradesco/HSBC - matriz
// 17/04/2017 - Catia   - Boletos Itau - matriz
// 22/06/2017 - Catia   - Verifica se o banco/agencia/conta esta não bloqueado
// 26/06/2017 - Catia   - Ajustes boleto Caixa
// 29/06/2017 - Catia   - Ajustes porque nao estava imprimindo o valor de juros quando FAT (e1_vapjuro)
// 09/08/2017 - Catia   - Boleto Banrisul - Filial 08
// 22/08/2017 - Catia   - Boleto Banrisul - Filial 08 - No recibo do pagador, imprimir o endereço completo com 
//                        cidade estado e cep
// 22/08/2017 - Catia   - Boleto Caixa - estava gerando o nosso numero com 1 digito a mais e mandava cortado pro banco
// 20/11/2017 - Robert  - Ajustes campo livre do codigo de barras da Caixa (bco.104) e formatacao da linha digitavel.
// 17/01/2018 - Robert  - Ajuste calculo DV geral cod barras bco 104 (ficava com valor 10 quando deveria alterar para 1).
// 11/07/2018 - Sandra  - Deabilitado o e-mail de aviso de reimpressão de boletos.
// 13/09/2018 - Sandra  - Deabilitado o e-mail de aviso de impressão de boletos.
// 25/09/2018 - Catia   - Criada opcao de imprimir boletos a partir da tela do funcoes do contas a receber 
//                      - manipula a funcao gera
// 20/11/2018 - Sandra  - Alterado e-mail de aline.trentin@novaalianca.coop.br para financeiro@novaalianca.coop.br
// 10/12/2018 - Catia   - Boletos para o "banco"  RED - RED ASSET - cobranca do bradesco 
// 03/05/2019 - Catia   - Boletos para o do brasil - novo convenio da MATRIZ
// 06/09/2019 - Claudia - Novo layout para boletos banco 422 - Safra
// 02/12/2019 - Robert  - Declaradas variaveis locais para for...next - tratamento para mensagem 
//                        [For variable is not Local]
// 02/12/2019 - Cláudia - Retirada a opção de imprimir boleto do banco 422 com modelo bradesco
// 27/03/2020 - Andre   - Validação de "nosso numero" para boletos de todos os bancos.
// 25/06/2020 - Claudia - Incluída validação para banco do brasil onde as filiais definidas terão CNPJ 
//                        e endereço da matriz. GLPI: 8103
// 26/06/2020 - Claudia - Definida as filiais para banco do brasil, conforme GLPI: 8103
// 02/09/2020 - Robert  - Buscava cod.empresa fixo '01571' ao gerar 'nosso numero' para Sicredi.
//                      - Inseridas tags para catalogo de fontes.
// 17/09/2020 - Sandra  - Alterado Agencia banco 104 de 2515 para 4312.
// 21/09/2020 - Claudia - Acrescentado para o banco sicredi, a filtragem de banco/agencia e conta 
//						  para busca de nosso numero duplicado. GLPI: 8413
// 13/05/2021 - Claudia - Criada uma variavel para o parametro VA_PJURBOL, para solucionar erro R27. GLPI: 8825
// 06/12/2021 - Claudia - Criada validação para nao permitir impressão de boleto quando tiver algum erro. 
//                        GLPI: 11283
// 25/02/2022 - Sandra  - Alterado agencia e conta do banco 041 para filial 08. GLPI: 11638.
// 18/02/2022 - Claudia - Criado modelo banrisul 240. GLPI: 11753
// 10/06/2022 - Claudia - Realizado ajustes conforme solicitado pelo banco banrisul. GLPI: 11638
// 22/07/2022 - Claudia - Criado modelo de boleto banco Daycoval. GLPI: 12365
// 02/09/2022 - Robert  - Chamadas da funcao u_log() trocadas para u_log2().
// 05/09/2022 - Robert  - Ajustes pequenos nos logs.
// 09/11/2022 - Claudia - Tratamento de parametros de agencia e conta. 
//

// --------------------------------------------------------------------------------------------------------------
User Function ML_BOLLSR (_aBoletos)
	local _nBoleto := 0

	cPerg := "BOLL" + cFilAnt
	_ValidPerg()
	Pergunte(cPerg,.F.)    // Pergunta no SX1

	oPrn:=TAVPrinter():New("Boleto Laser")
	if oPrn:Setup()      // Tela para selecao da impressora.
		oPrn:SetPortrait()     // ou SetLanscape()
		
		// Se recebi array com os titulos, nao preciso abrir markbrowse para selecao.
		// Farei uma chamada do programa para cada titulo.
		if type ("_aBoletos") == "A"
			for _nBoleto = 1 to len (_aBoletos)
				mv_par01 := _aBoletos [_nBoleto, 1]
				mv_par02 := _aBoletos [_nBoleto, 1]
				mv_par03 := _aBoletos [_nBoleto, 2]
				mv_par04 := _aBoletos [_nBoleto, 2]
				mv_par05 := _aBoletos [_nBoleto, 3]
				mv_par06 := _aBoletos [_nBoleto, 4]
				mv_par07 := _aBoletos [_nBoleto, 5]
				mv_par08 := _aBoletos [_nBoleto, 6]
				mv_par11 :=  1                     // Visualizar

				if _aBoletos [_nBoleto, 7] = "FA740BRW"
					_Gera (.f.)
				else
					_Gera (.t.)
				endif
			next
		else
			U_GravaSX1 (cPerg, "11", 1)  // Visualizar
			If Pergunte (cPerg,.T.)

//				// Alguns profiles de usuario comecaram a ser gravados sem
//				// os espacos no final dos campos, deixando-os menores do
//				// que o parametro original. Robert, 05/09/2022
//				mv_par05 = left (mv_par05 + space (5),   3)  // Manter consistencia de tamanho com a funcao _ValidPerg ()
//				mv_par06 = left (mv_par06 + space (5),   5)  // Manter consistencia de tamanho com a funcao _ValidPerg ()
//				mv_par07 = left (mv_par07 + space (10), 10)  // Manter consistencia de tamanho com a funcao _ValidPerg ()
//				mv_par08 = left (mv_par08 + space (3),   3)  // Manter consistencia de tamanho com a funcao _ValidPerg ()

				processa ({|| _Gera (.F.)})
			endif
		endif
		
		// --- verifica se o banco/conta esta bloqueada - se estiver nao deixa imprimir boletos
		if fbuscacpo ("SA6", 1, xfilial ("SA6") + mv_par05 + mv_par06 + mv_par07,  "A6_BLOCKED") == '1'
			u_help ("Banco/agencia/conta bloqueado, não permitida a impressão de boletos")
			return
		endif

		If mv_par11 == 1  //_lVisualizar
			oPrn:Preview()       // Visualiza antes de imprimir
		Else
			oPrn:Print()       // Visualiza antes de imprimir
		EndIf
		oPrn:End()
	endif
return
//
// --------------------------------------------------------------------------
// Geração
static function _Gera (_lAutomat)
	Local aCampos := {}

	aAdd(aCampos, {"E1_NOMCLI"  , "Cliente"    , "@!"              })
	aAdd(aCampos, {"E1_PREFIXO" , "Prefixo"    , "@!"              })
	aAdd(aCampos, {"E1_NUM"     , "Titulo"     , "@!"              })
	aAdd(aCampos, {"E1_PARCELA" , "Parcela"    , "@!"              })
	aAdd(aCampos, {"E1_VALOR"   , "Valor"      , "@E 9,999,999.99" })
	aAdd(aCampos, {"E1_VENCREA" , "Vencimento" ,                   })
	
	private _lAuto := _lAutomat
	Private Exec   := .F.
	_xBOL320	   := 0
	_xPRCSIC	   := ""
	_Xsai          := .F.
	
	cIndexName := Criatrab(Nil,.F.)
	cIndexKey  := "E1_PREFIXO + E1_NUM + E1_PARCELA"
	cFilter    := ""
	cFilter    += "E1_FILIAL='" + xfilial ("SE1") + "'.and."
	cFilter    += "E1_PREFIXO>='" + mv_par01 + "'.and."
	cFilter    += "E1_PREFIXO<='" + mv_par02 + "'.and."
	cFilter    += "E1_NUM>='" + mv_par03 + "'.and."
	cFilter    += "E1_NUM<='" + mv_par04 + "'.and."
	cFilter    += "E1_SALDO>0"
	
	IndRegua("SE1", cIndexName, cIndexKey,, cFilter, "Aguarde. Selecionando Registros....")
	DbSelectArea("SE1")
	
	DbGoTop()
	cMarca    := getmark()
	
	// Se for emissao automatica, marca os titulos como se tivessem sido selecionados no markbrowse.
	if _lAuto
		dbgotop ()
		do while ! eof ()
			reclock ("SE1", .F.)
			se1 -> e1_ok = cMarca
			msunlock ()
			dbskip ()
		enddo
		dbgotop ()
	endif
	
	// Se for modo automatico, imprime direto. Senao, abre markbrowse para conferencia.
	if _lAuto
		U__IMPTIT()
	else
		linverte  := .T.
		cCadastro := "Emissao de Titulos"
		aRotina   := {}
		aAdd( aRotina, { "Pesquisar"  , "AxPesqui"    , 0, 1})
		aAdd( aRotina, { "Imprimir"   , "U__IMPTIT()" , 0, 6})
		
		aCores := {}
		aAdd(aCores, {"E1_BOLIMP == 'N'",'BR_AZUL'})
		aAdd(aCores, {"E1_BOLIMP == 'C'",'DISABLE'})
		
		Markbrow("SE1","E1_OK",,,@linverte,@cmarca,,aCores)
	endif
	
	DbSelectArea("SE1")
	DbCloseArea()
	ChkFile('SE1')
Return
//
// --------------------------------------------------------------------------
User Function _IMPTIT()
	procregua (se5 -> (reccount ()))

	If ! mv_par05 $ GetMv ("VA_BCOBOL") .AND. ! upper (alltrim (GETENVSERVER ())) $ 'COMPILACAO3/TESTE/CATIA'
		u_help('Impressao de boletos para o banco ' + mv_par05 + ' ainda nao liberada no sistema (parametro VA_BCOBOL).')
		Return
	EndIf

	MontaRel()
	if ! _lAuto
		CloseBrowse ()
	endif
Return
//
// --------------------------------------------------------------------------
Static Function MontaRel()
	Local aDadosTit  := {}
	Local aDatSacado := {}
	Local aDadosEmp  := {}
	Local _aEmp      := {}
	Local sDadosEmp1 := ""
	local _lContinua := .T.
	local _sNumBco   := ""
	local _sQuery    := ""
	local _sBcoPed   := ""
	local _sSituaca  := ""
	local _nDescFin  := 0
	local _nPJurbol  := GetMv ("VA_PJURBOL") 
	Local _oSQL  	 := ClsSQL ():New ()
	Local _sDigVerif := ""
	private _nVlrTit := 0
	private CB_RN    := {}

	//Objetos para tamanho e tipo das fontes
	oFont8   := TFont():New("Times New Roman",,8 ,,.F.,,,,,.F.)
	oFont10CN:= TFont():New("Courier New",,10,,.T.,,,,,.F.)
	oFont10  := TFont():New("Times New Roman",,10,,.T.,,,,,.F.)
	oFont12  := TFont():New("Times New Roman",,12,,.T.,,,,,.F.)
	oFont16  := TFont():New("Times New Roman",,16,,.T.,,,,,.F.)
	oFont16n := TFont():New("Times New Roman",,15,,.T.,,,,,.F.)
	oFont24  := TFont():New("Times New Roman",,20,,.T.,,,,,.F.)
	
	If cFilAnt $ ("03/07/16/09") .and. alltrim(mv_par05) == '001' // para BB e filiais selecionadas, endreço e CNPJ serão da matriz
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 	  M0_NOMECOM"
		_oSQL:_sQuery += "    ,M0_CGC"
		_oSQL:_sQuery += "    ,TRIM(M0_ENDCOB) + ' - ' + TRIM(M0_CIDCOB) + ' - ' + TRIM(M0_ESTCOB) "
		_oSQL:_sQuery += "    ,TRIM(M0_CEPCOB)"
		_oSQL:_sQuery += "    ,M0_TEL"
		_oSQL:_sQuery += "    ,TRIM(M0_BAIRCOB) + ' - ' + TRIM(M0_CIDCOB) + ' - ' + TRIM(M0_ESTCOB) "
		_oSQL:_sQuery += "    ,M0_INSC"
		_oSQL:_sQuery += " FROM VA_SM0"
		_oSQL:_sQuery += " WHERE M0_CODIGO = '01'"
		_oSQL:_sQuery += " AND M0_CODFIL = '01'"
		_aEmp := _oSQL:Qry2Array ()
		
		_sEndereco := AllTrim(_aEmp[1,3])+ "-" + Subs(alltrim(_aEmp[1,4]),1,5) +"-" +Subs(alltrim(_aEmp[1,4]),6,3) + "," + alltrim(_aEmp[1,6]) 
		aAdd(aDadosEmp, alltrim(_aEmp[1,1]))
		// conforme solicitacao do banrisul - tem que sair o endereço completo
		aAdd(aDadosEmp, AllTrim(_aEmp[1,3])+ "  -  " + Subs(alltrim(_aEmp[1,4]),1,5) +"-" +Subs(alltrim(_aEmp[1,4]),6,3)) // endereço
		aAdd(aDadosEmp, alltrim(_aEmp[1,6]))															// Complemento
		aAdd(aDadosEmp, "CEP: "  + Subs(alltrim(_aEmp[1,4]),1,5) +"-" +Subs(alltrim(_aEmp[1,4]),6,3))	// CEP
		aAdd(aDadosEmp, "FONE: " + alltrim(_aEmp[1,5]))													// Telefones
		aAdd(aDadosEmp, "CNPJ: " + Transform(_aEmp[1,2], '@R 99.999.999/9999-99'))						// CNPJ
		aAdd(aDadosEmp, "I.E.: " + alltrim(_aEmp[1,7]))													// Inscrição estadual
		
	Else
		_sEndereco := AllTrim(SM0->M0_ENDCOB) + "  -  " + SM0->M0_ESTCOB + "  -  " + Subs(SM0->M0_CEPCOB,1,5) +"-" +Subs(SM0->M0_CEPCOB,6,3) + ". " + AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB
		aAdd(aDadosEmp, SM0->M0_NOMECOM)
		// conforme solicitacao do banrisul - tem que sair o endereço completo
		aAdd(aDadosEmp, AllTrim(SM0->M0_ENDCOB) + "  -  " + AllTrim(SM0->M0_CIDCOB) + "  -  " + SM0->M0_ESTCOB + "  -  " + Subs(SM0->M0_CEPCOB,1,5) +"-" +Subs(SM0->M0_CEPCOB,6,3))
		aAdd(aDadosEmp, AllTrim(SM0->M0_BAIRCOB)+",  "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB)	// Complemento
		aAdd(aDadosEmp, "CEP: "  + Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3))			// CEP
		aAdd(aDadosEmp, "FONE: " + SM0->M0_TEL)													    // Telefones
		aAdd(aDadosEmp, "CNPJ: " + Transform(SM0->M0_CGC, '@R 99.999.999/9999-99'))					// CNPJ
		aAdd(aDadosEmp, "I.E.: " + ALLTRIM(SM0->M0_INSC))											// Inscrição estadual
	
		// Para Boletos Safra
		sDadosEmp1 := ALLTRIM(SM0->M0_NOMECOM) + " - " + ALLTRIM(Transform(SM0->M0_CGC, '@R 99.999.999/9999-99'))	
	EndIf
	
	DbSelectArea("SA6")
	DbSetOrder(1)
	If !DbSeek(xFilial("SA6")+mv_par05 + PADR(alltrim(mv_par06),5) + mv_par07,.t.)
		u_help("Banco / Agencia / Conta nao cadastrados: " + mv_par05 + ' / ' + mv_par06 + ' / ' + mv_par07,, .t.)
		_lContinua = .F.
	Endif
	
	IndRegua("SE1", cIndexName, cIndexKey,, cFilter, "Aguarde. Selecionando Registros....")
	DbSelectArea("SE1")
	DbGoTop()

	Do While !Eof() .and. _lContinua

		incproc ()
		// Guarda Parametros Originais
		_xSlvpar05 := mv_par05
		_xSlvpar06 := PADR(alltrim(mv_par06),5)
		_xSlvpar07 := mv_par07
		_xSlvpar08 := mv_par08
		_aAreaSA6  := SA6->(GetArea())
		_aAreaSEE  := SEE->(GetArea())
		
		If ! _lAuto .and. !Marked("E1_OK")
			u_log2 ('debug', 'Titulo nao selecionado no markbrowse')
			se1 -> (DbSkip())
			Loop
		EndIf
		
		If SE1->E1_TIPO # "NF" .And. SE1->E1_TIPO # "DP"
			u_log2 ('debug', "Titulo do tipo " + SE1->E1_TIPO + " nao gera boleto.")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		EndIF
		
		// VERIFICA SE CLIENTE ESTA NO PARAMETRO ML_CLIC19 (cliente que exigem que o boleto seja impresso pelo banco)
		IF fBuscaCpo ("SA1", 1, xfilial ("SA1") + SE1->E1_CLIENTE + se1 -> e1_loja, "A1_VAEBOL") == "B"
			u_log2 ('debug', "Cliente " + SE1->E1_CLIENTE + "Nao recebe boleto - campo A1_VAEBOL")  //parametro ML_CLIC19")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		EndIF
		
		DbSelectArea("SA1")
		DbSetOrder(1)
		If !DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,.T.)
			u_help("Cliente " + SE1->E1_CLIENTE + "/" + SE1->E1_LOJA + " nao Cadastrado.")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		
		DbSelectArea("SEE")
		DbSetOrder(1)
		U_Log2 ('debug', '[' + procname () + '] pesquisando SEE >>' + xFilial("SEE") + mv_par05 +  PADR(alltrim(mv_par06),5) + mv_par07 + mv_par08 + '<<')
		If DbSeek(xFilial("SEE") + mv_par05 +  PADR(alltrim(mv_par06),5) + PADR(alltrim(mv_par07),10) + mv_par08,.f.)
			_nNumBco := SEE->EE_BOLATU
			_cBcoBol := see -> ee_codigo
			_cAgeBol := see -> ee_vaBolAg
			_cCtaBol := see -> ee_vaBolCt
			_cCodCart:= see -> ee_codcart 
			_cCodCart:= see -> ee_codcart 
			_cTabela := see -> ee_tabela
			if empty (_cAgeBol) .or. empty (_cCtaBol)
				u_help ("Nao ha definicao de conta/agencia para impressao neste banco.")
				se1 -> (dbskip ())
				_lContinua = .F.
				loop
			endif
		Else
			u_help("Nao Encontrado Dados Param. Bancos / Agencia / Conta / Sub-Conta CNAB " + chr(13) + mv_par05 + ' / ' +  PADR(alltrim(mv_par06),5) + ' / ' + mv_par07 + ' / ' + mv_par08)
			se1 -> (dbskip ())
			_lContinua = .F.
			loop
		EndIf
		
		// Verifica se o banco selecionado eh o mesmo do pedido de venda
		if ! empty (se1 -> e1_pedido) .and. empty (se1 -> e1_numbco)
			_sBcoPed = fBuscaCpo ("SC5", 1, xfilial ("SC5") + se1 -> e1_pedido, "C5_BANCO")
			if _sBcoPed != mv_par05
				if ! msgnoyes ("Titulo " + SE1->E1_NUM + ": banco diferente informado no pedido de venda (" + _sBcoPed + "). Confirma a impressao do boleto mesmo assim?","AVISO")
					u_log2 ('aviso', 'Boleto nao serah impresso por que o banco estah diferente do pedido de venda')
					se1 -> (DbSkip())
					Loop
				else
					// Grava evento para posterior consulta
					_oEvento := ClsEvent():new ()
					_oEvento:CodEven   = "SE1003"
					_oEvento:Texto     = "Gerando boleto para o banco '" + mv_par05 + "' e no pedido de venda consta '" + _sBcoPed + "' (parcela " + se1 -> e1_parcela + ")"
					_oEvento:NFSaida   = se1 -> e1_num
					_oEvento:SerieSaid = se1 -> e1_prefixo
					_oEvento:PedVenda  = se1 -> e1_pedido
					_oEvento:Cliente   = se1 -> e1_cliente
					_oEvento:LojaCli   = se1 -> e1_loja
					_oEvento:Grava ()
				endif
			endif
		endif
		
		// Verifica se o boleto jah foi impresso, se o usuario quer reimprimir, se jah foi para outro banco, se jah foi baixado, etc.
		_sNumBco := SE1->E1_NUMBCO
		If SE1->E1_BOLIMP == "S" .OR. !empty (_sNumBco)
			If SE1->E1_PORT2 != mv_par05
				u_help ("Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + se1 -> e1_prefixo + "/" + SE1->E1_NUM + "-" + se1 -> e1_parcela + " ja impresso no Banco '" + SE1->E1_PORT2 + "'." + chr(13) + chr (10) + "Este boleto nao sera reimpresso.")
				DbSelectArea("SE1")
				DbSkip()
				Loop
			else
				If ! Msgyesno("Boleto " + AllTrim(SE1->E1_NUMBCO) + " Titulo " + se1 -> e1_prefixo + "/" + SE1->E1_NUM + "-" + se1 -> e1_parcela + " ja impresso. Confirma reimpressao?","AVISO")
					u_log2 ('debug', 'Usuario nao confirmou reimpressao')
					DbSelectArea("SE1")
					DbSkip()
					Loop
				else
					// Grava evento para posterior consulta
					_oEvento := ClsEvent():new ()
					_oEvento:CodEven   = "SE1004"
					_oEvento:Texto     = "Reimpressao de boleto (Atualmente com nosso numero='" + se1 -> e1_numbco + "') - parcela " + se1 -> e1_parcela
					_oEvento:NFSaida   = se1 -> e1_num
					_oEvento:SerieSaid = se1 -> e1_prefixo
					_oEvento:PedVenda  = se1 -> e1_pedido
					_oEvento:Cliente   = se1 -> e1_cliente
					_oEvento:LojaCli   = se1 -> e1_loja
					_oEvento:Grava ()
				Endif
				if se1 -> e1_saldo != se1 -> e1_valor
					If ! MsgYesNo ("A T E N C A O: Titulo " + se1 -> e1_prefixo + "/" + SE1->E1_NUM + "-" + se1 -> e1_parcela + " parcial ou totalmente baixado. Confirma reimpressao do boleto?","AVISO")
						u_log2 ('debug', 'Usuario nao confirmou impressao de boleto para titulo parcial ou totalmente baixado')
						DbSelectArea("SE1")
						DbSkip()
						Loop
					Endif
				endif

				if se1 -> e1_situaca != "0"
					_sSituaca = AllTrim(X3Combo("E1_SITUACA",se1 -> e1_situaca))
					If ! MsgYesNo ("Titulo " + se1 -> e1_prefixo + "/" + SE1->E1_NUM + "-" + se1 -> e1_parcela + " se encontra em " + _sSituaca + ". Confirma impressao do boleto?","AVISO")
						DbSelectArea("SE1")
						DbSkip()
						Loop
					else
						// Grava evento para posterior consulta
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven   = "SE1004"
						_oEvento:Texto     = "Impressao boleto p/tit. em situacao " + se1 -> e1_situaca + "-" + _sSituaca + " (parcela " + se1 -> e1_parcela + ")"
						_oEvento:NFSaida   = se1 -> e1_num
						_oEvento:SerieSaid = se1 -> e1_prefixo
						_oEvento:PedVenda  = se1 -> e1_pedido
						_oEvento:Cliente   = se1 -> e1_cliente
						_oEvento:LojaCli   = se1 -> e1_loja
						_oEvento:Grava ()
					Endif
				endif

			endif
		EndIf

		// Busca valores na mesma rotina usada para gerar arquivos de CNAB.
		_nVlrTit  = U_FunCNAB (_cBcoBol, "VlrTit")
		_nDescFin = U_FunCNAB (_cBcoBol, "VlDesc")

		if _nVlrTit == 0
			u_help ("Titulo " + SE1->E1_NUM + " sem saldo." + chr(13) + chr (10) + "Este boleto nao sera impresso")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		endif

		// Se chegou ateh este ponto sem nosso numero, eh por que trata-se de um titulo novo e devo gerar o nosso numero.
		if empty (_sNumBco)
			do case
				case _cBcoBol == '001'
					_sNumBco = _NosNum001()
				case _cBcoBol == '033'
					_sNumBco = _NosNum033()
				case _cBcoBol == '041'
					_sNumBco = _NosNum041()
				case _cBcoBol == '104'
					_sNumBco = _NosNum104()
				case _cBcoBol == '237'
					_sNumBco = _NosNum237()
				case _cBcoBol == '341'
					_sNumBco = _NosNum341()
				case _cBcoBol == '399'
					_sNumBco = _NosNum399()
				case _cBcoBol == '422'
					_sNumBco = _NosNum422_422()
				case _cBcoBol == '707'
					_sNumBco = soma1 (strzero (see -> ee_bolatu, 10)) 
				case _cBcoBol == '748'
					_sNumBco = _NosNum748()
				case _cBcoBol == 'RED'
					_sNumBco = _NosNumRED_237()	
				otherwise
					u_help ("Sem tratamento para calculo de nosso numero para o banco " + _cBcoBol,, .t.)
					_lContinua = .f.
					loop
			endcase
			u_log2 ('info', 'Nosso numero gerado: >>' + _sNumBco + '<<')

			// Verifica se a numeracao atual encontra-se dentro da faixa liberada pelo banco.
			If _cBcoBol == '707'
				If val(_sNumBco) < val(SEE->EE_FAXINI) .Or. val(_sNumBco) > val(SEE->EE_FAXFIM)
					u_help("Valor gerado para 'nosso numero' (" + _sNumBco + ") fora da sequencia valida para o banco " + _cBcoBol,, .t.)
					_lContinua = .F.
					loop
				EndIF
			else
				If _sNumBco < SEE->EE_FAXINI .Or. _sNumBco > SEE->EE_FAXFIM
					u_help("Valor gerado para 'nosso numero' (" + _sNumBco + ") fora da sequencia valida para o banco " + _cBcoBol,, .t.)
					_lContinua = .F.
					loop
				EndIF
			endif
						
			If VAL (_sNumBco) < SEE->EE_BOLATU
				u_help("Valor gerado para 'nosso numero' (" + _sNumBco + ") e' menor que o ultimo gravado nos parametros do banco " + _cBcoBol + "(" + alltrim (str (see->ee_bolatu)) + "). Isso causaria repeticao de numeracao junto ao banco! Verifique!",, .t.)
				_lContinua = .F.
				loop
			EndIF

			// Verifica, por seguranca, se o 'nosso numero' jah existe em algum outro titulo.
			_sQuery := ""
			_sQuery +=  " select count (E1_NUMBCO)"
			_sQuery +=  " from " + RetSQLName ("SE1") + " SE1 "
			_sQuery +=  " where D_E_L_E_T_ = ''"
			_sQuery +=  " and E1_FILIAL = '" + xfilial ("SE1") + "'"
			_sQuery +=  " and E1_NUMBCO = '" + _sNumBco + "'"
			If alltrim(mv_par05) == '748' // verifica banco/agencia e conta para o sicred
				_sQuery +=  " and E1_PORT2  = '" + mv_par05 + "'"
				_sQuery +=  " and E1_AGEDEP = '" + PADR(alltrim(mv_par06),5) + "'"
				_sQuery +=  " and E1_CONTA  = '" + mv_par07 + "'"
			EndIf
 
			if U_RetSQL (_sQuery) > 0
				u_help ("Problemas na geracao do 'nosso numero' para o titulo '" + se1 -> e1_num + "': O numero '" + _sNumBco + "' ja existe no sistema.",, .t.)
				_lContinua = .F.
				loop
			endif

			// Grava portador e 'nosso numero' no titulo.
			If EMPTY (SE1->E1_NUMBCO)

				// Verifica tamanhos dos campos
				if len (alltrim (_sNumBco)) > TamSX3 ("E1_NUMBCO")[1]
					u_help ("Tamanho do campo E1_NUMBCO insuficiente para armazenar o nosso numero '" + _sNumBco + "'",, .t.)
					_lContinua = .F.
					loop
				endif
				if len (alltrim (_sNumBco)) > TamSX3 ("EE_BOLATU")[1]
					u_help ("Tamanho do campo EE_BOLATU insuficiente para armazenar o nosso numero '" + _sNumBco + "'",, .t.)
					_lContinua = .F.
					loop
				endif
				
				RecLock("SE1",.F.)
				SE1->E1_PORT2 := _cBcoBol
				SE1->E1_numbco := _sNumBco
				MsUnlock()
			
				// Atualiza no SEE a numeracao do ultimo boleto gerado para este banco.
				do case
					case _cBcoBol == "001"
						 do case
							case len (alltrim (see -> ee_codemp)) == 6
								RecLock("SEE",.F.)
								SEE->EE_BOLATU  := val (substr (se1 -> e1_numbco, 7, 5))
								MsUnlock()
							case len (alltrim (see -> ee_codemp)) == 7
								RecLock("SEE",.F.)
								SEE->EE_BOLATU  := val (substr (se1 -> e1_numbco, 8, 10))
								MsUnlock()
							otherwise
								u_help ("Banco '" + _cBcoBol + "': Sem tratamento para gravacao do campo EE_BOLATU para este tamanho de convenio.")
								_lContinua = .F.
								loop
							endcase
					case _cBcoBol == "033"
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 7))
						MsUnlock()							
					case _cBcoBol == "041"  
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 8))
						MsUnlock()
					case _cBcoBol == "104"
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (substr (se1 -> e1_numbco, 3, 15))
						u_log2 ('debug', 'Atualizei EE_BOLATU para ' + cvaltochar (SEE->EE_BOLATU))
						MsUnlock()
					case _cBcoBol == "237" .OR. _cBcoBol == "RED" 
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 11))
						MsUnlock()	
					case _cBcoBol == "341"
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 8))
						MsUnlock()						
					case _cBcoBol == "422"
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 8))
						MsUnlock()
					case _cBcoBol == "707"
						RecLock("SEE",.F.)
						SEE->EE_BOLATU = val (left (se1 -> e1_numbco, 10))
						MsUnlock()
					otherwise
						RecLock("SEE",.F.)
						SEE->EE_BOLATU  := val (se1 -> e1_numbco)
						MsUnlock()
				endcase

				// Grava evento para posterior consulta
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "SE1006"
				_oEvento:Texto     = "Gerado campo 'nosso numero' com conteudo '" + se1 -> e1_numbco + "' para o banco '" + se1 -> e1_port2 + "' (parcela " + se1 -> e1_parcela + ")"
				_oEvento:NFSaida   = se1 -> e1_num
				_oEvento:SerieSaid = se1 -> e1_prefixo
				_oEvento:PedVenda  = se1 -> e1_pedido
				_oEvento:Cliente   = se1 -> e1_cliente
				_oEvento:LojaCli   = se1 -> e1_loja
				_oEvento:Grava ()
			endif
		endif

		// Monta codigo de barras e linha digitavel para impressao.
		CB_RN := {"", ""}
		do case
			case _cBcoBol == '001'
				CB_RN [1] = _CodBar001 ()
				CB_RN [2] = _LinDig001 ()
			case _cBcoBol == '033'
                CB_RN [1] = _CodBar033 ()
                CB_RN [2] = _LinDig033 ()    
			case _cBcoBol == '041'
				CB_RN [1] = _CodBar041 ()
				CB_RN [2] = _LinDig041 ()
			case _cBcoBol == '104'
                CB_RN [1] = _CodBar104 ()
                CB_RN [2] = _LinDig104 ()    
			case _cBcoBol == '237'  
                CB_RN [1] = _CodBar237 ()
                CB_RN [2] = _LinDig237 ()
            case _cBcoBol == 'RED'
                CB_RN [1] = _CodBarRED_237 ()
                CB_RN [2] = _LinDigRED_237 ()
			case _cBcoBol == '341'
                CB_RN [1] = _CodBar341 ()
                CB_RN [2] = _LinDig341 ()                                
			case _cBcoBol == '399'
				CB_RN [1] = _CodBar399 ()
				CB_RN [2] = _LinDig399 ()
			case _cBcoBol == '422'
				CB_RN [1] = _CodBar422_422 ()
				CB_RN [2] = _LinDig422_422 ()	
			case _cBcoBol == '707'
				_sDigVerif := _DigVerif707(_sNumBco)
				CB_RN [1] = _CodBar707 (_sDigVerif)
				CB_RN [2] = _LinDig707 ()		
			case _cBcoBol == '748'
                CB_RN [1] = _CodBar748 ()
                CB_RN [2] = _LinDig748 ()
			otherwise
				u_help ("Sem tratamento para codigo de barras e linha digitavel para o banco " + _cBcoBol)
				_lContinua = .f.
				loop
		endcase
		
		// Prepara dados para impressao
		aDadosTit   := {}
		if _cBcoBol == 'RED'
			aAdd(aDadosTit, SE1->E1_NUM )
		elseif _cBcoBol == '707'
			aAdd(aDadosTit, SE1->E1_NUM + SE1->E1_PARCELA)
		else	
			aAdd(aDadosTit, se1 -> e1_prefixo + SE1->E1_NUM+SE1->E1_PARCELA)	// Número do título: BB exige identico ao arquivo de cobranca.
		endif
		aAdd(aDadosTit, SE1->E1_EMISSAO)						   	// Data da emissão do título
		aAdd(aDadosTit, Date())									   	// Data da emissão do boleto
		aAdd(aDadosTit, SE1->E1_VENCREA)   							// Data do vencimento
		aAdd(aDadosTit, _nVlrTit)									// Valor do título
		
		do case
			case _cBcoBol == '001'
				do case
					case len (alltrim (see -> ee_codemp)) == 6
						aAdd(aDadosTit, left (se1 -> e1_numbco, 11) + "-" + substr (se1 -> e1_numbco, 12, 1))
					case len (alltrim (see -> ee_codemp)) == 7
						aAdd(aDadosTit, left (se1 -> e1_numbco, 17))
					otherwise
					u_help ("Sem tratamento para este tamanho de convenio durante carga de aDadosTit.")
					_lContinua = .f.
					loop
				endcase
			case _cBcoBol == '033'
				aAdd(aDadosTit, left(ALLTRIM(SE1->E1_NUMBCO), 11))
			case _cBcoBol == '041'
				aAdd(aDadosTit, ALLTRIM(SE1->E1_NUMBCO))
			case _cBcoBol == '104'
				aAdd(aDadosTit, SUBSTR(ALLTRIM(SE1->E1_NUMBCO),1,LEN(SE1->E1_NUMBCO)-1) + "-" + substr(SE1->E1_NUMBCO,LEN(SE1->E1_NUMBCO),1) )
			case _cBcoBol == '237' .or. _cBcoBol == 'RED'  
				aAdd(aDadosTit, SUBSTR(ALLTRIM(SE1->E1_NUMBCO),1,11) + "-" + substr(SE1->E1_NUMBCO,12,1) )	
			case _cBcoBol == '341'
				aAdd(aDadosTit, SUBSTR(ALLTRIM(SE1->E1_NUMBCO),1,8) + "-" + substr(SE1->E1_NUMBCO,9,1) ) 				
			case _cBcoBol == '399'
				aAdd(aDadosTit, left(ALLTRIM(SE1->E1_NUMBCO), 11))
			case _cBcoBol == '422' 
				aAdd(aDadosTit, left(ALLTRIM(SE1->E1_NUMBCO), 9))
			case _cBcoBol == '707'
				aAdd(aDadosTit, left(ALLTRIM(SE1->E1_NUMBCO), 11))
          	case _cBcoBol == '748'
				aAdd(aDadosTit, left(ALLTRIM(SE1->E1_NUMBCO),2)+"/"+substr(ALLTRIM(SE1->E1_NUMBCO),3, 6)+"-"+substr(ALLTRIM(SE1->E1_NUMBCO),9, 1))
			otherwise
				u_help ("Sem tratamento para este banco X nosso numero durante carga de aDadosTit.")
				_lContinua = .f.
				loop
		endcase
			
		aAdd(aDadosTit, DDATABASE)								   // Data do Processamento
		aAdd(aDadosTit, iif(se1 -> e1_vaPJuro>0, se1 -> e1_vaPJuro, _nPJurbol )) // % juro para pagto em atraso.
		
		_xCGCCPF    := IIf(Len(AllTrim(SA1->A1_CGC))<>14,Transform(SA1->A1_CGC,"@R 999.999.999-99"),Transform(SA1->A1_CGC,"@R 99.999.999/9999-99"))
		
		aDatSacado  := {}
		aAdd(aDatSacado, AllTrim(SA1->A1_NOME))									// Razão Social
		aAdd(aDatSacado, AllTrim(SA1->A1_COD))  // Código
		
		// Se tem endereco de cobranca completo, otimo. Senao, assume o endereco principal.
		If !Empty(SA1->A1_ENDCOB) .and. !Empty(SA1->A1_MUNC) .and. !Empty(SA1->A1_ESTC) .and. !Empty(SA1->A1_CEPC)
			aAdd(aDatSacado, AllTrim(SA1->A1_ENDCOB )+" "+SA1->A1_BAIrroC)		// Endereço
			aAdd(aDatSacado, AllTrim(SA1->A1_MUNC))								// Cidade
			aAdd(aDatSacado, SA1->A1_ESTC)										// Estado
			aAdd(aDatSacado, LEFT(SA1->A1_CEPC,5)+"-"+RIGHT(SA1->A1_CEPC,3))	// CEP

			// Aviso para o usuario 'ficar esperto' e nao mandar o boleto junto com a nota
			if sa1 -> a1_endcob != sa1 -> a1_end
				u_help ("A T E N C A O" + chr (13) + char (10) + "Cliente " + sa1 -> a1_cod + " " + sa1 -> a1_nome + " tem endereco de cobranca diferente do endereco de entrega.")
			endif
		Else
			aAdd(aDatSacado, AllTrim(SA1->A1_END )+" "+SA1->A1_BAIRRO)		// Endereço
			aAdd(aDatSacado, AllTrim(SA1->A1_MUN))							// Cidade
			aAdd(aDatSacado, SA1->A1_EST)									// Estado
			aAdd(aDatSacado, LEFT(SA1->A1_CEP,5)+"-"+RIGHT(SA1->A1_CEP,3))	// CEP
		EndIf
			
		aAdd(aDatSacado, _xCGCCPF)											// CNPJ
		aAdd(aDatSacado, _nDescFin)  										// Desconto financeiro.
	
		// --------- IMPRESSÃO DO BOLETO ----------
		If _lContinua == .T.
			_Impress(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN, _sDigVerif)
				
			// Marca titulo como 'boleto jah impresso'.
			RecLock("SE1",.F.)
			SE1->E1_BOLIMP :="S"
			MsUnLock()
			
			// Manda aviso para o setor financeiro, especifico para cliente que quer os boletos por e-mail.
			if aDatSacado [2] $ "007496/010944/008783/011687/009309/006558"
				U_SendMail ("financeiro@novaalianca.coop.br", "Boleto " + se1 -> e1_prefixo + "/" + se1 -> e1_num + se1 -> e1_parcela + " emitido para cliente " + alltrim (aDatSacado [1]), "", {}, "")
			endif
		Else
			u_help("Boleto não impresso!",, .t.)
		EndIf

		// Retorna Parametros Originais
		RestArea (_aAreaSA6)
		RestArea (_aAreaSEE)
		mv_par05   := _xSlvpar05
		mv_par06   := _xSlvpar06
		mv_par07   := _xSlvpar07
		mv_par08   := _xSlvpar08

		DbSelectArea("SE1")
		dbSkip()
	Enddo
Return
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 001
Static Function _NosNum001 ()
	local _xDV       := NIL
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""

	do case
		case len (alltrim (see -> ee_codemp)) == 6

			// O 'nosso numero' eh composto pelo numero de nosso convenio (ee_codemp)
			// mais um sequecial mais o digito verificador (calculado por 'modulo 11').
			_sProxBol = soma1 (alltrim (see -> ee_codemp) + strzero (see -> ee_bolatu, 5))  // Tamanho: 11
			_nSoma = 0
			_nSoma += val (substr (_sProxBol, 1,  1)) * 7
			_nSoma += val (substr (_sProxBol, 2,  1)) * 8
			_nSoma += val (substr (_sProxBol, 3,  1)) * 9
			_nSoma += val (substr (_sProxBol, 4,  1)) * 2
			_nSoma += val (substr (_sProxBol, 5,  1)) * 3
			_nSoma += val (substr (_sProxBol, 6,  1)) * 4
			_nSoma += val (substr (_sProxBol, 7,  1)) * 5
			_nSoma += val (substr (_sProxBol, 8,  1)) * 6
			_nSoma += val (substr (_sProxBol, 9,  1)) * 7
			_nSoma += val (substr (_sProxBol, 10, 1)) * 8
			_nSoma += val (substr (_sProxBol, 11, 1)) * 9
			_nResto = _nSoma % 11

			if _nResto < 10
				_xDV = _nResto
			elseif _nResto == 10
				_xDV = "X"
			elseif _nResto == 0
				_xDV = 0
			endif
			_sRet = _sProxBol + cvaltochar (_xDV)

		case len (alltrim (see -> ee_codemp)) == 7

			// O 'nosso numero' eh composto pelo numero de nosso convenio (ee_codemp)
			// mais um sequecial mais o digito verificador (calculado por 'modulo 11').
			_sProxBol = alltrim (see -> ee_codemp) + soma1 (strzero (see -> ee_bolatu, 10))  // A funcao SOMA1 parece se atrapalhar com numeros grandes.
			_nSoma = 0
			_nSoma += val (substr (_sProxBol, 1,  1)) * 9
			_nSoma += val (substr (_sProxBol, 2,  1)) * 2
			_nSoma += val (substr (_sProxBol, 3,  1)) * 3
			_nSoma += val (substr (_sProxBol, 4,  1)) * 4
			_nSoma += val (substr (_sProxBol, 5,  1)) * 5
			_nSoma += val (substr (_sProxBol, 6,  1)) * 6
			_nSoma += val (substr (_sProxBol, 7,  1)) * 7
			_nSoma += val (substr (_sProxBol, 8,  1)) * 8
			_nSoma += val (substr (_sProxBol, 9,  1)) * 9
			_nSoma += val (substr (_sProxBol, 10, 1)) * 2
			_nSoma += val (substr (_sProxBol, 11, 1)) * 3
			_nSoma += val (substr (_sProxBol, 12, 1)) * 4
			_nSoma += val (substr (_sProxBol, 13, 1)) * 5
			_nSoma += val (substr (_sProxBol, 14, 1)) * 6
			_nSoma += val (substr (_sProxBol, 15, 1)) * 7
			_nSoma += val (substr (_sProxBol, 16, 1)) * 8
			_nSoma += val (substr (_sProxBol, 17, 1)) * 9
			_nResto = _nSoma % 11

			if _nResto < 10
				_xDV = _nResto
			elseif _nResto == 10
				_xDV = "X"
			elseif _nResto == 0
				_xDV = 0
			endif

			_sRet = _sProxBol + cvaltochar (_xDV)

		otherwise
			u_help ("Banco 001: Sem definicao de calculo de 'nosso numero' para este tamanho de convenio.")
		endcase
return _sRet
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 041 por 'modulo 10'.
Static Function _NosNum041 ()
	local _nDV1      := NIL  // Para dar erro caso nao encontre o DV.
	local _nDV2      := NIL  // Para dar erro caso nao encontre o DV.
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""
	local _nMult     := 0
	local _nPos      := 0
	local _nPeso     := 0
	
	// Busca a raiz do 'nosso numero' para o proximo boleto.
	_sProxBol = soma1 (strzero (see -> ee_bolatu, 8))

	// Calculo do primeiro digito verificador.
	_nSoma = 0
	_nPeso = 2

	for _nPos = len (_sProxBol) to 1 step -1
		_nMult = val (substr (_sProxBol, _nPos,  1)) * _nPeso
		if _nMult > 9
			_nMult -= 9
		endif
		_nSoma += _nMult
		_nPeso = iif (_nPeso == 2, 1, 2)
	next

	_nResto = _nSoma % 10
	if _nResto == 0
		_nDV1 = 0
	else
		_nDV1 = 10 - _nResto
	endif
	_sRet = _sProxBol + alltrim (str (_nDV1))
	
	// Calculo do segundo digito verificador em loop por que pode haver necessidade de recalcular.
	do while .T.
		_nSoma := 0
		_nPeso = 1
		for _nPos = len (_sRet) to 1 step -1
			_nPeso = iif (_nPeso >= 7, 2, _nPeso + 1)
			_nSoma += val (substr (_sRet, _nPos,  1)) * _nPeso
		next

		_nResto = _nSoma % 11
		if _nSoma < 11
			_nDV2 = _nSoma
			exit
		elseif _nResto == 1  // Considera-se invalido e refaz-se o calculo somando 1 ao primeiro DV.
			if _nDV1 == 9  // Se somar 1, fica 10 (invalido)
				_nDV1 = 0
			else
				_nDV1 ++
			endif
			// Atualiza o primeiro DV no 'nosso numero', para recalculo do segundo DV.
			_sRet = left (_sRet, 8) + alltrim (str (_nDV1))
			loop
		elseif _nResto == 0
			_nDV2 = _nResto
			exit
		else
			_nDV2 = 11 - _nResto
			exit
		endif
	enddo
	
	_sRet = _sRet + alltrim (str (_nDV2))
return _sRet
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 237
Static Function _NosNum237 ()
	local _nDV       := 0
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""
	
	_sProxBol = soma1 (strzero(see -> ee_bolatu,11))
	_nSoma = 0
	_nSoma += 0 * 2 // carteira 02
	_nSoma += 2 * 7
	_nSoma += val (substr (_sProxBol, 1,  1)) * 6
	_nSoma += val (substr (_sProxBol, 2,  1)) * 5
	_nSoma += val (substr (_sProxBol, 3,  1)) * 4
	_nSoma += val (substr (_sProxBol, 4,  1)) * 3
	_nSoma += val (substr (_sProxBol, 5,  1)) * 2
	_nSoma += val (substr (_sProxBol, 6,  1)) * 7
	_nSoma += val (substr (_sProxBol, 7,  1)) * 6
	_nSoma += val (substr (_sProxBol, 8,  1)) * 5
	_nSoma += val (substr (_sProxBol, 9,  1)) * 4
	_nSoma += val (substr (_sProxBol, 10, 1)) * 3
	_nSoma += val (substr (_sProxBol, 11, 1)) * 2
	
	_nResto = _nSoma % 11
	do case 
		case _nResto == 1
			_nDV = 'P'
		case _nResto == 0
			_nDV = '0' 			
		Otherwise
			_nDV = 11 - _nResto
			_nDV = cvaltochar (_nDV)
	endcase
	
	_sRet = _sProxBol + _nDV	
Return _sRet

// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco RED ASSET - Banco 237
Static Function _NosNumRED_237 ()
	local _nDV       := 0
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""

	_sProxBol = soma1 (strzero(see -> ee_bolatu,11))
	_nSoma = 0
	_nSoma += 0 * 2 
	_nSoma += 9 * 7
	_nSoma += val (substr (_sProxBol, 1,  1)) * 6
	_nSoma += val (substr (_sProxBol, 2,  1)) * 5
	_nSoma += val (substr (_sProxBol, 3,  1)) * 4
	_nSoma += val (substr (_sProxBol, 4,  1)) * 3
	_nSoma += val (substr (_sProxBol, 5,  1)) * 2
	_nSoma += val (substr (_sProxBol, 6,  1)) * 7
	_nSoma += val (substr (_sProxBol, 7,  1)) * 6
	_nSoma += val (substr (_sProxBol, 8,  1)) * 5
	_nSoma += val (substr (_sProxBol, 9,  1)) * 4
	_nSoma += val (substr (_sProxBol, 10, 1)) * 3
	_nSoma += val (substr (_sProxBol, 11, 1)) * 2
	
	_nResto = _nSoma % 11
	do case 
		case _nResto == 1
			_nDV = 'P'
		case _nResto == 0
			_nDV = '0' 			
		Otherwise
			_nDV = 11 - _nResto
			_nDV = cvaltochar (_nDV)
	endcase
	
	_sRet = _sProxBol + _nDV	
Return _sRet
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 341
Static Function _NosNum341 ()
	local _nDV       := 0
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""
	local _i         := 0
	local _n         := 0
	
	_sDadAux   = "1612" + "29011" + "109" 
	_sProxBol  = soma1 (str (see -> ee_bolatu, 8))
	_wNossoNum = _sDadAux + _sProxBol  
	_nSoma     = 0
	_wresu     = 0
	_wsomdig   = 0
	_wfator    = 1

	for _i=1 to 20
		_wresu = val (substr (_wNossoNum, _i,  1)) * _wfator
		_wsomdig = 0

		for _n=1 to len( str (_wresu))
			_wsomdig += val( substr ( str(_wresu), _n, 1))
		next

		_nSoma += _wsomdig 
		if _wfator = 1
			_wfator = 2
		else
			_wfator = 1
		endif						
	next
	
	_nResto = _nSoma % 10
	if _nResto = 0
		_nDV = 0	
	else 
		_nDV   = 10 - _nResto
	endif
	
	_sRet = _sProxBol + alltrim (str (_nDV))		
Return _sRet
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 399
Static Function _NosNum399 ()
	local _nDV       := 0
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""

	_sProxBol = soma1 (left (alltrim (str (see -> ee_bolatu)), 10))
	_nSoma = 0
	_nSoma += val (substr (_sProxBol, 1,  1)) * 5
	_nSoma += val (substr (_sProxBol, 2,  1)) * 4
	_nSoma += val (substr (_sProxBol, 3,  1)) * 3
	_nSoma += val (substr (_sProxBol, 4,  1)) * 2
	_nSoma += val (substr (_sProxBol, 5,  1)) * 7
	_nSoma += val (substr (_sProxBol, 6,  1)) * 6
	_nSoma += val (substr (_sProxBol, 7,  1)) * 5
	_nSoma += val (substr (_sProxBol, 8,  1)) * 4
	_nSoma += val (substr (_sProxBol, 9,  1)) * 3
	_nSoma += val (substr (_sProxBol, 10, 1)) * 2
	_nResto = _nSoma % 11

	if _nResto == 0 .or. _nResto == 1
		_nDV = 0
	else
		_nDV = 11 - _nResto
	endif
	
	_sRet = _sProxBol + alltrim (str (_nDV))
Return _sRet
//
// --------------------------------------------------------------------------
// Calcula 'Nosso numero' para o banco 104 - modelo 11 - 
Static Function _NosNum104 ()
	local _nDV       := 0
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""

	_sProxBol = soma1 (strzero (see -> ee_bolatu, 15)) // pq depois tem mais o digito verificador
	_sProxBol = '14' + _sProxBol
	
	_nSoma += val (substr (_sProxBol, 1,  1)) * 2
	_nSoma += val (substr (_sProxBol, 2,  1)) * 9
	_nSoma += val (substr (_sProxBol, 3,  1)) * 8
	_nSoma += val (substr (_sProxBol, 4,  1)) * 7
	_nSoma += val (substr (_sProxBol, 5,  1)) * 6
	_nSoma += val (substr (_sProxBol, 6,  1)) * 5
	_nSoma += val (substr (_sProxBol, 7,  1)) * 4
	_nSoma += val (substr (_sProxBol, 8,  1)) * 3
	_nSoma += val (substr (_sProxBol, 9,  1)) * 2
	_nSoma += val (substr (_sProxBol, 10, 1)) * 9
	_nSoma += val (substr (_sProxBol, 11, 1)) * 8
	_nSoma += val (substr (_sProxBol, 12, 1)) * 7
	_nSoma += val (substr (_sProxBol, 13, 1)) * 6
	_nSoma += val (substr (_sProxBol, 14, 1)) * 5
	_nSoma += val (substr (_sProxBol, 15, 1)) * 4
	_nSoma += val (substr (_sProxBol, 16, 1)) * 3
	_nSoma += val (substr (_sProxBol, 17, 1)) * 2

	_nResto = _nSoma % 11
	_nDV = 11 - _nResto
	
	if _nDV > 9 
		_nDV = 0
	endif
	
	_sRet = _sProxBol + alltrim (str (_nDV))	
Return _sRet
//
// --------------------------------------------------------------------------
// Gera 'nosso numero' para o banco 422 - Safra novo
Static Function _NosNum422_422 ()
    local _xDV       := NIL
    local _nResto    := 0
    local _nSoma     := 0
    local _sProxBol  := ""
    local _sRet      := ""
    public _nnrosafra:= ""

	// busca o proximo numero de boleto e soma um
    _sProxBol = soma1 (strzero (see -> ee_bolatu, 8))
    
    // monta nossa numero DV MODULO SAFRA
    _nSoma = 0
    _nSoma += val (substr (_sProxBol, 1,  1)) * 9
    _nSoma += val (substr (_sProxBol, 2,  1)) * 8
    _nSoma += val (substr (_sProxBol, 3,  1)) * 7
    _nSoma += val (substr (_sProxBol, 4,  1)) * 6
    _nSoma += val (substr (_sProxBol, 5,  1)) * 5
    _nSoma += val (substr (_sProxBol, 6,  1)) * 4
    _nSoma += val (substr (_sProxBol, 7,  1)) * 3
    _nSoma += val (substr (_sProxBol, 8,  1)) * 2
    
    _nResto = _nSoma % 11
    
    if _nResto == 0
        _xDV = 1
    elseif _nResto == 1
        _xDV = 0
    else
        _xDV = 11 - _nResto
    endif
    
    _nnrosafra = _sProxBol + cvaltochar (_xDV)
    
    // monta nossa numero - DV MODULO BRADESCO
    _nSoma  = 0
    _nSoma += 0                                * 2
    _nSoma += 9                                * 7
    _nSoma += val(substr(dtos(se1->e1_emissao),3,1))* 6
    _nSoma += val(substr(dtos(se1->e1_emissao),4,1))* 5
    _nSoma += val (substr (_nnrosafra, 1,  1)) * 4
    _nSoma += val (substr (_nnrosafra, 2,  1)) * 3
    _nSoma += val (substr (_nnrosafra, 3,  1)) * 2
    _nSoma += val (substr (_nnrosafra, 4,  1)) * 7
    _nSoma += val (substr (_nnrosafra, 5,  1)) * 6
    _nSoma += val (substr (_nnrosafra, 6,  1)) * 5
    _nSoma += val (substr (_nnrosafra, 7,  1)) * 4
    _nSoma += val (substr (_nnrosafra, 8,  1)) * 3
    _nSoma += val (substr (_nnrosafra, 9,  1)) * 2
    
    _nResto = _nSoma % 11
    
    if _nResto == 1
        _xDV = "P"
    elseif _nResto == 0
	     _xDV = 0
	else	     
    	_xDV = 11 - _nResto    
    endif
    
    _sRet = _nnrosafra + cvaltochar (_xDV)
return _sRet
//
// --------------------------------------------------------------------------
// Calcula Digito Verificador para o banco 707 por 'modulo 10'.
Static Function _DigVerif707 (_sNumBco)
	local _nDV1      := NIL  // Para dar erro caso nao encontre o DV.
	local _nResto    := 0
	local _nSoma     := 0
	local _sProxBol  := ""
	local _sRet      := ""
	local _nMult     := 0
	local _nPos      := 0
	local _nPeso     := 0

	//_sBanco    := see -> ee_codigo
	_sAgencia  := substr(see -> ee_agencia,1,4)
	_sSubConta := see -> ee_subcta
	
	// Busca a raiz do 'nosso numero' para o proximo boleto.
	If empty(_sNumBco)
		_sProxBol1 = soma1 (strzero (see -> ee_bolatu, 10))
	else
		_sProxBol1 = alltrim(_sNumBco)
	EndIf

	_sProxBol = _sAgencia + _sSubConta + _sProxBol1

	// Calculo do primeiro digito verificador.
	_nSoma = 0
	_nPeso = 2

	for _nPos = len(_sProxBol) to 1 step -1
		_nMult = val(substr(_sProxBol, _nPos, 1)) * _nPeso
		if _nMult > 9
			_nMult -= 9
		endif
		_nSoma += _nMult
		_nPeso = iif (_nPeso == 2, 1, 2)
	next

	_nResto = _nSoma % 10
	if _nResto == 0
		_nDV1 = 0
	else
		_nDV1 = 10 - _nResto
	endif
	_sRet = alltrim(str(_nDV1))

return _sRet
//
// --------------------------------------------------------------------------
// Gera 'nosso numero' para o banco 033
Static Function _NosNum033()
    local _xDV        := NIL
    local _nResto     := 0
    local _nSoma      := 0
    local _sProxBol   := ""
    local _sRet       := ""
    public _nnrosafra := ""
    
	// busca o proximo numero de boleto e soma um
    _sProxBol = soma1 (strzero (see -> ee_bolatu, 7))
    
    // monta nossa numero DV MODULO SAFRA
    _nSoma = 0
    _nSoma += val (substr (_sProxBol, 7,  1)) * 2
    _nSoma += val (substr (_sProxBol, 6,  1)) * 3
    _nSoma += val (substr (_sProxBol, 5,  1)) * 4
    _nSoma += val (substr (_sProxBol, 4,  1)) * 5
    _nSoma += val (substr (_sProxBol, 3,  1)) * 6
    _nSoma += val (substr (_sProxBol, 2,  1)) * 7
    _nSoma += val (substr (_sProxBol, 1,  1)) * 8
    
    _nResto = _nSoma % 11
    
    if _nResto == 0
        _xDV = 0
    elseif _nResto == 10
        _xDV = 0
    elseif _nResto == 1
        _xDV = 1
    else
        _xDV = 11 - _nResto
    endif
    
    _sRet = _sProxBol + cvaltochar (_xDV)
return _sRet
//
// --------------------------------------------------------------------------
// Gera 'nosso numero' para o banco 748
Static Function _NosNum748 ()
	local _nNumBco := 0

	// Ignora o digito verificador do final para incrementar a numercao.
	_nNumBco = val (left (alltrim (str (see -> ee_bolatu)), len (alltrim (str (see -> ee_bolatu))) - 1)) + 1

	// A cada inicio de ano, o numero sequencial deve ser reinicializado.
	if substr (dtos (se1 -> e1_emissao), 3, 2) > substr (strzero (_nNumBco, 8), 1, 2)
		_nNumBco = val (substr (dtos (se1 -> e1_emissao), 3, 2) + "200001")
	endif
	_char2 := LEFT(SEE->EE_AGENCIA,4)  // Agencia
	_char2 += "98"  				   // posto
	_char2 += alltrim (see -> ee_codemp)
	_char2 += strzero (_nNumBco, 8) 
	
	// Calcula digito verificador
	_num3 := (val(subs(_char2,01,1)) * 4) +;
	(val(subs(_char2,02,1)) * 3) +;
	(val(subs(_char2,03,1)) * 2) +;
	(val(subs(_char2,04,1)) * 9) +;
	(val(subs(_char2,05,1)) * 8) +;
	(val(subs(_char2,06,1)) * 7) +;
	(val(subs(_char2,07,1)) * 6) +;
	(val(subs(_char2,08,1)) * 5) +;
	(val(subs(_char2,09,1)) * 4)
	_num3:=_num3+(val(subs(_char2,10,1)) * 3) +;
	(val(subs(_char2,11,1)) * 2) +;
	(val(subs(_char2,12,1)) * 9) +;
	(val(subs(_char2,13,1)) * 8) +;
	(val(subs(_char2,14,1)) * 7) +;
	(val(subs(_char2,15,1)) * 6) +;
	(val(subs(_char2,16,1)) * 5) +;
	(val(subs(_char2,17,1)) * 4) +;
	(val(subs(_char2,18,1)) * 3) +;
	(val(subs(_char2,19,1)) * 2)
	_num2 := mod(_num3,11)
	if _num2 == 0
		_num4 := 0
	else
		_num4 := 11 - _num2
	endif
	if _num4 == 10 .OR. _num4 == 11
		_num4 := 0
	endif
	
	_char2 := str(_num4,1)
	_sRet  := StrZero(_nNumBco,8,0) + _char2
Return _sRet
//
// --------------------------------------------------------------------------
// Gera codigo de barras para o banco 001
static function _CodBar001 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nSubtr    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""

	_aCodBar [1] = val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  									  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	do case
		case len (alltrim (see -> ee_codemp)) == 6
			// Passa nosso numero para a array do codigo de barras
			for _nPos = 1 to 11
				_aCodBar [_nPos + 19] = val (substr (se1 -> e1_numbco, _nPos, 1))
			next
			
			// Passa agencia e conta para a array do codigo de barras
			for _nPos = 1 to 4
				_aCodBar [_nPos + 30] = val (substr (_cAgeBol, _nPos, 1))
			next

			for _nPos = 1 to 8
				_aCodBar [_nPos + 34] = val (substr (_cCtaBol, _nPos, 1))
			next

		case len (alltrim (see -> ee_codemp)) == 7
			for _nPos = 20 to 25
				_aCodBar [_nPos] = 0
			next

			// Passa nosso numero para a array do codigo de barras
			for _nPos = 1 to 17
				_aCodBar [_nPos + 25] = val (substr (se1 -> e1_numbco, _nPos, 1))
			next

		otherwise
			u_help ("Banco 001: sem tratamento para geracao de codigo de barras para este tamanho de convenio.")
	endcase

	_aCodBar [43] = 1  // Codigo da carteira
	_aCodBar [44] = 7  // Codigo da carteira
	
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next

	_nResto = _nSoma % 11
	_nSubtr = 11 - _nResto
	_nDV = iif ((_nSubtr == 0 .or. _nSubtr == 10 .or. _nSubtr == 11), 1, _nSubtr)
	_aCodBar [5] = _nDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// --------------------------------------------------------------------------
// Gera codigo de barras para o banco 041, no padrao FEBRABAN.
static function _CodBar041 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nResto    := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	local _nDV1      := NIL  // Para dar erro caso nao encontre o DV.
	local _nDV2      := NIL  // Para dar erro caso nao encontre o DV.
	local _nMult     := 0
	local _nPeso     := 0

	_aCodBar [1] = val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next

	_aCodBar [20] = 2  // Produto: 1=cobr.normal,fichario emitido pelo Banrisul; 2=cobr.direta,fichario emitido pelo cliente.
	_aCodBar [21] = 1

	// Passa agencia e codigo do cedente (sem dig.controle) para a array do codigo de barras.
	for _nPos = 1 to 4
		_aCodBar [_nPos + 21] = val (substr (_cAgeBol, _nPos, 1))
	next

	for _nPos = 1 to 7
		_aCodBar [_nPos + 25] = val (substr (see -> ee_codemp, _nPos, 1))
	next

	// Passa nosso numero (sem digitos de controle) para a array do codigo de barras.
	for _nPos = 1 to 8
		_aCodBar [_nPos + 32] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
		
	_aCodBar [41] = 4
	_aCodBar [42] = 0
	
	// Calcula posicoes finais por modulo 10 e 11.
	// Calculo do primeiro digito verificador.
	_nSoma = 0
	_nPeso = 2
	for _nPos = 42 to 20 step -1
		_nMult = _aCodBar [_nPos] * _nPeso
		_nSoma += (_nMult - iif (_nMult > 9, 9, 0))
		_nPeso = iif (_nPeso == 2, 1, 2)
	next

	_nResto = _nSoma % 10
	if _nResto == 0
		_nDV1 = 0
	else
		_nDV1 = 10 - _nResto
	endif

	_aCodBar [43] = _nDV1
	
	// Calculo do segundo digito verificador em loop por que pode haver necessidade de recalcular.
	do while .T.
		_nSoma := 0
		_nPeso = 1
		for _nPos = 43 to 20 step -1
			_nPeso = iif (_nPeso >= 7, 2, _nPeso + 1)
			_nSoma += _aCodBar [_nPos] * _nPeso
		next

		_nResto = _nSoma % 11
		if _nSoma < 11
			_nDV2 = _nSoma
			exit
		elseif _nResto == 1  // Considera-se invalido e refaz-se o calculo somando 1 ao primeiro DV.
			if _nDV1 == 9  // Se somar 1, fica 10 (invalido)
				_nDV1 = 0
			else
				_nDV1 ++
			endif
			// Atualiza o primeiro DV na array, para recalculo do segundo DV.
			_aCodBar [43] = _nDV1
			loop
		elseif _nResto == 0
			_nDV2 = _nResto
			exit
		else
			_nDV2 = 11 - _nResto
			exit
		endif
	enddo
	_aCodBar [44] = _nDV2

	// Calcula o DAC (Digito de autoconferencia) usando modulo 11.
	_nSoma := 0
	_nPeso = 1
	for _nPos = 44 to 1 step -1
		if _nPos != 5
			_nPeso = iif (_nPeso >= 9, 2, _nPeso + 1)
			_nSoma += _aCodBar [_nPos] * _nPeso
		endif
	next

	_nResto = _nSoma % 11
	if _nResto == 0 .or. _nResto == 10 .or. _nResto == 1
		_nDV2 = 1
	else
		_nDV2 = 11 - _nResto
	endif
	_aCodBar [5] = _nDV2
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// --------------------------------------------------------------------------
// Gera codigo de barras para o banco 399
static function _CodBar399 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDAC      := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	_aCodBar [1] = val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  									  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	if se1 -> e1_vencrea >= stod ("20000703")
		_nFatorVct = se1 -> e1_vencrea - stod ("20000703") + 1000
	else
		_nFatorVct = 0
	endif
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 11
		_aCodBar [_nPos + 19] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	
	// Passa agencia e conta para a array do codigo de barras
	for _nPos = 1 to 4
		_aCodBar [_nPos + 30] = val (substr (see -> ee_agencia, _nPos + 1, 1))
	next

	for _nPos = 1 to 7
		_aCodBar [_nPos + 34] = val (substr (see -> ee_conta, _nPos + 3, 1))
	next
	
	_aCodBar [42] = 0  // Codigo da carteira
	_aCodBar [43] = 0  // Codigo da carteira
	_aCodBar [44] = 1  // Codigo do aplicativo de cobranca
	
	// Calculo do digito verificador ou DAC (Digito de AutoConferencia)
	_nSoma = 0
	_nPeso = 2
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next

	_nResto = _nSoma % 11
	_nDAC = iif ((_nResto == 0 .or. _nResto == 1 .or. _nResto == 10), 1, (11 - _nResto))
	_aCodBar [5] = _nDAC
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// --------------------------------------------------------------------------
// Gera codigo de barras para o banco 104
static function _CodBar104 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nResto    := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	local _nDV1      := NIL  // Para dar erro caso nao encontre o DV.
	local _nDV2      := NIL  // Para dar erro caso nao encontre o DV.
	local _nPeso     := 0

	_aCodBar [1] = val (substr (see -> ee_codigo, 1, 1))  	// Codigo do banco
	_aCodBar [2] = val (substr (see -> ee_codigo, 2, 1))  	// Codigo do banco
	_aCodBar [3] = val (substr (see -> ee_codigo, 3, 1))  	// Codigo do banco
	_aCodBar [4] = 9  										// Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	// codigo do beneficiario - posicao 20 a 25
	_aCodBar [20] = 6
	_aCodBar [21] = 1
	_aCodBar [22] = 8
	_aCodBar [23] = 6
	_aCodBar [24] = 9
	_aCodBar [25] = 1
	_aCodBar [26] = 2  	   // digito do codigo do beneficiario
	// sequencia 1
	_aCodBar [27] = val (substr(se1 -> e1_numbco , 3, 1))
	_aCodBar [28] = val (substr(se1 -> e1_numbco , 4, 1))
	_aCodBar [29] = val (substr(se1 -> e1_numbco , 5, 1))
	// constante 1
	_aCodBar [30] = 1  // 1a.posição do Nosso Numero - Tipo de Cobrança (1 - Registrada / 2 - Sem Registro)
	// sequencia 2
	_aCodBar [31] = val (substr(se1 -> e1_numbco , 6, 1))
	_aCodBar [32] = val (substr(se1 -> e1_numbco , 7, 1))
	_aCodBar [33] = val (substr(se1 -> e1_numbco , 8, 1))
	// constante 2	
	_aCodBar [34] = 4  // 2a.posição do Nosso Numero - Identificador de Emissão do Boleto(4-Beneficiário)
	// sequencia 3
	_aCodBar [35] = val (substr(se1 -> e1_numbco , 9, 1))	
	_aCodBar [36] = val (substr(se1 -> e1_numbco ,10, 1))
	_aCodBar [37] = val (substr(se1 -> e1_numbco ,11, 1))
	_aCodBar [38] = val (substr(se1 -> e1_numbco ,12, 1))
	_aCodBar [39] = val (substr(se1 -> e1_numbco ,13, 1))
	_aCodBar [40] = val (substr(se1 -> e1_numbco ,14, 1))
	_aCodBar [41] = val (substr(se1 -> e1_numbco ,15, 1))
	_aCodBar [42] = val (substr(se1 -> e1_numbco ,16, 1))
	_aCodBar [43] = val (substr(se1 -> e1_numbco ,17, 1))

	// calculo do digito verificador do campo livre
	_nSoma = 0
	_nPeso = 2
	for _nPos = 43 to 20 step -1
		_nSoma += _aCodBar [_nPos] * _nPeso
		_nPeso = iif (_nPeso == 9, 2, _nPeso + 1)
	next

	_nResto = _nSoma % 11
	_nDV1 = 11 - _nResto
	if _nDV1 > 9
	   _nDV1 = 0		
	endif 
	_aCodBar [44] = _nDV1

	// calcula DV geral do codigo de barras
	_nSoma := 0
	_nPeso = 1
	for _nPos = 44 to 1 step -1
		if _nPos != 5
			_nPeso = iif (_nPeso >= 9, 2, _nPeso + 1)
			_nSoma += _aCodBar [_nPos] * _nPeso
		endif
	next

	_nResto = _nSoma % 11
	_nDV2   = 11 - _nResto
	if _nDV2 == 0 .or. _nDV2 > 9
		_nDV2 = 1
	endif
	_aCodBar [5] = _nDV2

	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next

	if len (_sRet) > 44
		u_help ("ERRO na montagem do codigo de barras para o boleto " + se1 -> e1_num + '/' + se1 -> e1_parcela)
		_sRet = ''
	endif
return _sRet
//
// ---------------------------------------
// Monta codigo de barras para o banco 237
Static Function _CodBar237 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	_aCodBar [1] = 2 //val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = 3 //val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = 7 ///val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	// Passa agencia e conta para a array do codigo de barras
	for _nPos = 1 to 4
		_aCodBar [_nPos + 19] = val (substr ('3471', _nPos, 1))
	next
	
	_aCodBar [24] = 0  // Codigo da carteira
	_aCodBar [25] = 2  // Codigo da carteira
	
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 11
		_aCodBar [_nPos + 25] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	
	for _nPos = 1 to 7
		_aCodBar [_nPos + 36] = val (substr ('0000481', _nPos, 1))
	next

	_aCodBar [44] = 0
	
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	_nResto = _nSoma % 11
	
	if _nResto == 0 .or. _nResto == 1 .or. _nResto > 9
        _nDV = 1
    else
        _nDV = 11 - _nResto
    endif
		
	_aCodBar [5] = _nDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
	
	_campolivre = ""
	for _nPos = 20 to 44
		_campolivre  += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// ---------------------------------------
// Monta codigo de barras para o banco 237
Static Function _CodBarRED_237 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	_aCodBar [1] = 2 //val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = 3 //val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = 7 ///val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	// Passa agencia e conta para a array do codigo de barras
	for _nPos = 1 to 4
		_aCodBar [_nPos + 19] = val (substr ('3391', _nPos, 1))
	next
	
	_aCodBar [24] = 0  // Codigo da carteira
	_aCodBar [25] = 9  // Codigo da carteira
	
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 11
		_aCodBar [_nPos + 25] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	
	for _nPos = 1 to 7
		_aCodBar [_nPos + 36] = val (substr ('0006332', _nPos, 1))
	next

	_aCodBar [44] = 0
	
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	_nResto = _nSoma % 11
	
	if _nResto == 0 .or. _nResto == 1 .or. _nResto > 9
        _nDV = 1
    else
        _nDV = 11 - _nResto
    endif
		
	_aCodBar [5] = _nDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
	
	_campolivre = ""
	for _nPos = 20 to 44
		_campolivre  += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// ---------------------------------------
// Monta codigo de barras para o banco 341
Static Function _CodBar341 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0    
	local _nResto    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""

	// monta codigo de barras = 44 posicoes (menos a posicao 5 que eh o DAC)
	// banco
	for _nPos = 1 to 3
		_aCodBar [_nPos] = val (substr ('341', _nPos, 1))
	next
	// moeda
	_aCodBar [4] = 9
	// fator de vencimento
	_nFatorVct = se1 -> e1_vencrea - stod ("20000703") + 1000
	_sFatorVct = strzero (_nFatorVct, 4)
	for _nPos = 1 to 4
		_aCodBar [_nPos + 5] = val (substr (_sFatorVct, _nPos, 1))
	next
	// valor do titulo
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	// carteira
	for _nPos = 1 to 3
		_aCodBar [_nPos + 19] = val (substr ('109', _nPos, 1))
	next
	// nosso numero
	for _nPos = 1 to 8
		_aCodBar [_nPos + 22] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	// DAC calculado do nosso numero
	_aCodBar [31] = val(substr (alltrim(se1 -> e1_numbco), len(alltrim(se1 -> e1_numbco)), 1))
	// agencia
	for _nPos = 1 to 4
		_aCodBar [_nPos + 31] = val (substr ('1612', _nPos, 1))
	next
	// conta
	for _nPos = 1 to 6
		_aCodBar [_nPos + 35] = val (substr ('290112', _nPos, 1))
	next
	//zeros
	for _nPos = 1 to 3
		_aCodBar [_nPos + 41] = 0
	next
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	_nResto = _nSoma % 11
	if _nResto == 0 .or. _nResto == 1 .or. _nResto > 9
        _nDV = 1
    else
        _nDV = 11 - _nResto
    endif
	_aCodBar [5] = _nDV
	
	// monta codigo de barras completo
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
	
	// monta campo livre
	_campolivre = ""
	for _nPos = 20 to 44
		_campolivre  += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// --------------------------------------------------------------------------
// Monta codigo de barras para o banco 707 - daycoval
Static Function _CodBar707(_sDigVerif)
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	// agencia
	_sAgencia  := substr(see->ee_agencia,1,4)
	_sCarteira := alltrim(see->ee_subcta)
	_sOper     := alltrim(see->ee_oper)
	
	// banco
	_aCodBar [1] = val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9 //Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("20000703") + 1000
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	// Passa agencia 
	for _nPos = 1 to 4
		_aCodBar [_nPos + 19] = val (substr (_sAgencia, _nPos, 1))
	next
	
	// passa carteira
	for _nPos = 1 to 3
		_aCodBar [_nPos + 23] = val (substr (_sCarteira, _nPos, 1))
	next

	// passa operacao
	for _nPos = 1 to 7
		_aCodBar [_nPos + 26] = val (substr (_sOper, _nPos, 1))
	next

	_sNumBcoDV := alltrim(se1 -> e1_numbco) + _sDigVerif
	u_log2 ('debug', "Nosso num + DV >>" + _sNumBcoDV + "<<")
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 11
		_aCodBar [_nPos + 33] = val (substr (_sNumBcoDV, _nPos, 1))
	next

	_nPeso := 2
	// Calculo do digito verificador
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	_nResto = _nSoma % 11
	_nSub = 11 - _nResto

	if _nSub == 0 .or. _nSub == 1 .or. _nSub > 9
        _nDV = 1
    else
        _nDV = _nSub
    endif
		
	_aCodBar [5] = _nDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
	
	_campolivre = ""
	for _nPos = 20 to 44
		_campolivre  += alltrim (str (_aCodBar [_nPos]))
	next
	u_log2 ('debug', "Codigo de barra >>" + _sRet + "<<")
return _sRet
//
// --------------------------------------------------------------------------
// Monta codigo de barras para o banco 422 - Safra Novo
Static Function _CodBar422_422 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDV       := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	// agencia
	_422Agencia := '03900'
	_422Conta   := '002009960'
	
	// banco
	_aCodBar [1] = 4 //val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = 2 //val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = 2 //val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9 //Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	// campo "F"
	_aCodBar [20] = 7
	
	// Passa agencia 
	for _nPos = 1 to 5
		_aCodBar [_nPos + 20] = val (substr (_422Agencia, _nPos, 1))
		//_aCodBar [_nPos + 19] = val (substr (mv_par06, _nPos, 1))
	next
	
	// passa conta
	for _nPos = 1 to 9
		_aCodBar [_nPos + 25] = val (substr (_422Conta, _nPos, 1))
	next
	
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 9
		_aCodBar [_nPos + 34] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	
	_aCodBar [44] = 2
	
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	_nResto = _nSoma % 11
	
	if _nResto == 0 .or. _nResto == 1 .or. _nResto == 10
        _nDV = 1
    else
        _nDV = 11 - _nResto
    endif
		
	_aCodBar [5] = _nDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
	
	_campolivre = ""
	for _nPos = 20 to 44
		_campolivre  += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// ---------------------------------------
// Monta codigo de barras para o banco 033
Static Function _CodBar033 ()
	local _sRet      := ""
	local _aCodBar   := afill (array (44), 0)
	local _nPos      := 0
	local _sValTit   := ""
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nFatorVct := 0
	local _sFatorVct := ""
	
	_aCodBar [1] = 0 //val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aCodBar [2] = 3 //val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aCodBar [3] = 3 ///val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aCodBar [4] = 9  // Moeda: Reais
	
	// Passa o fator de vencimento para as devidas posicoes da array.
	_nFatorVct = se1 -> e1_vencrea - stod ("19971007")
	_sFatorVct = strzero (_nFatorVct, 4)
	
	_aCodBar [6] = val (substr (_sFatorVct, 1, 1))
	_aCodBar [7] = val (substr (_sFatorVct, 2, 1))
	_aCodBar [8] = val (substr (_sFatorVct, 3, 1))
	_aCodBar [9] = val (substr (_sFatorVct, 4, 1))
	
	// Passa o valor do titulo para as devidas posicoes na array do codigo de barras.
	_sValTit = strzero (_nVlrTit * 100, 10)
	for _nPos = 1 to 10
		_aCodBar [_nPos + 9] = val (substr (_sValTit, _nPos, 1))
	next
	
	_aCodBar [20] = 9
	
	// Passa codigo do cedente para a array do codigo de barras
	for _nPos = 1 to 7
		_aCodBar [_nPos + 20] = val (substr ('6953808', _nPos, 1))
	next
	
	_aCodBar [28] = 0
	_aCodBar [29] = 0
	_aCodBar [30] = 0
	_aCodBar [31] = 0
	_aCodBar [32] = 0
	
	// Passa nosso numero para a array do codigo de barras
	for _nPos = 1 to 8
		_aCodBar [_nPos + 32] = val (substr (se1 -> e1_numbco, _nPos, 1))
	next
	
	_aCodBar [41] = 0
	_aCodBar [42] = 1
	_aCodBar [43] = 0
	_aCodBar [44] = 1
	
	// Calculo do digito verificador
	_nSoma = 0
	_nPeso = 2
	
	for _nPos = 44 to 1 step -1
		if _nPos != 5  // Esta posicao nao participa do calculo.
			_nSoma += _aCodBar [_nPos] * _nPeso
			_nPeso++
			if _nPeso > 9
				_nPeso = 2
			endif
		endif
	next
	
	_nSoma = _nSoma * 10
	_nResto = _nSoma % 11
	
	if _nResto == 0
        _xDV = 1
    elseif _nResto == 1
        _xDV = 1
    elseif _nResto == 10
        _xDV = 1
    else
        _xDV = _nResto
    endif
	
	_aCodBar [5] = _xDV
	
	// Converte a array para string, para retorno de dados da funcao.
	_sRet = ""
	for _nPos = 1 to 44
		_sRet += alltrim (str (_aCodBar [_nPos]))
	next
return _sRet
//
// --------------------------------------------------------------------------
// Monta codigo de barras para o banco 748
Static Function _CodBar748 ()
	Local i:=1
	
	_xCodbar := ""
	_ccodbar := ""
	
	str_num := afill (array (44), 0)
	STR_NUM[1]:=7
	STR_NUM[2]:=4
	STR_NUM[3]:=8
	STR_NUM[4]:=9    // MOEDA
	_XX := str(SE1->E1_VENCREA-ctod('07/10/1997'),4) + strzero(_nVlrTit*100,10,0)
	STR_NUM[6]:=VAL(SUBSTR(_XX,1,1))
	STR_NUM[7]:=VAL(SUBSTR(_XX,2,1))
	STR_NUM[8]:=VAL(SUBSTR(_XX,3,1))
	STR_NUM[9]:=VAL(SUBSTR(_XX,4,1))
	STR_NUM[10]:=VAL(SUBSTR(_XX,5,1))
	STR_NUM[11]:=VAL(SUBSTR(_XX,6,1))
	STR_NUM[12]:=VAL(SUBSTR(_XX,7,1))
	STR_NUM[13]:=VAL(SUBSTR(_XX,8,1))
	STR_NUM[14]:=VAL(SUBSTR(_XX,9,1))
	STR_NUM[15]:=VAL(SUBSTR(_XX,10,1))
	STR_NUM[16]:=VAL(SUBSTR(_XX,11,1))
	STR_NUM[17]:=VAL(SUBSTR(_XX,12,1))
	STR_NUM[18]:=VAL(SUBSTR(_XX,13,1))
	STR_NUM[19]:=VAL(SUBSTR(_XX,14,1))
	
	STR_NUM[20]:=1  // 2 // era 3 antes.   3  // Tipo de cobranca: 3 = Sicredi
	STR_NUM[21]:=1  // Carteira: 1=simples
	
	_XX:=left(SE1->E1_NUMBCO,8)  + right(alltrim(SE1->E1_NUMBCO),1)
	STR_NUM[22]:=VAL(SUBSTR(_XX,1,1))
	STR_NUM[23]:=VAL(SUBSTR(_XX,2,1))
	STR_NUM[24]:=VAL(SUBSTR(_XX,3,1))
	STR_NUM[25]:=VAL(SUBSTR(_XX,4,1))
	STR_NUM[26]:=VAL(SUBSTR(_XX,5,1))
	STR_NUM[27]:=VAL(SUBSTR(_XX,6,1))
	STR_NUM[28]:=VAL(SUBSTR(_XX,7,1))
	STR_NUM[29]:=VAL(SUBSTR(_XX,8,1))
	STR_NUM[30]:=VAL(SUBSTR(_XX,9,1))
	
	_XX:=substr(SEE->EE_AGENCIA,1,4)
	STR_NUM[31]:=VAL(SUBSTR(_XX,1,1))
	STR_NUM[32]:=VAL(SUBSTR(_XX,2,1))
	STR_NUM[33]:=VAL(SUBSTR(_XX,3,1))
	STR_NUM[34]:=VAL(SUBSTR(_XX,4,1))
	
	STR_NUM[35]:= 9 // 1  // 0  // 'posto'
	STR_NUM[36]:= 8 // 2  // 6  // 'posto'
	
	_XX:=substr(SEE->EE_CODEMP,1,5)
	STR_NUM[37]:=VAL(SUBSTR(_XX,1,1))
	STR_NUM[38]:=VAL(SUBSTR(_XX,2,1))
	STR_NUM[39]:=VAL(SUBSTR(_XX,3,1))
	STR_NUM[40]:=VAL(SUBSTR(_XX,4,1))
	STR_NUM[41]:=VAL(SUBSTR(_XX,5,1))
	STR_NUM[42]:=1  // 0 = sem valor; 1 = com valor
	
	//-------------------------------------------- DIG MOD 11
	
	_xx:=43
	_yy:=2
	_ZZ:=0
	do while _XX>=20
		if _yy>9
			_YY:=2
		Endif
		_ZZ:=_ZZ+(STR_NUM[_xx]*_YY)
		_YY:=_YY+1
		_XX:=_XX-1
	enddo
	IF _ZZ<11
		_XX2:=_ZZ
	ELSE
		_XX2:=MOD(_ZZ,11)
	ENDIF
	iF _XX2<=1
		_XX2:=0
	Else
		_XX2:=11-_XX2
	ENDIF
	STR_NUM[44]:=_XX2
	
	// --------------------------------------------------- dig 5
	// Calcula digito verificador geral do codigo de barras
	_Pos:=44
	_Peso:=2
	_Acum:=0
	do while _Pos<>0
		if _Peso>9
			_Peso:=2
		Endif
		IF _Pos==5
			_Pos:=_Pos-1
			loop
		ENDIF
		_Acum:=_Acum+(STR_NUM[_Pos]*_Peso)
		_Peso:=_Peso+1
		_Pos:=_Pos-1
	enddo
	IF _Acum<11
		_DIG5:=_Acum
	ELSE
		_DIG5:=MOD(_Acum,11)
	ENDIF
	IF _DIG5<>0
		_DIG5:=11-_DIG5
	ENDIF
	IF _DIG5==10 .or. _Dig5 == 11 .or. _Dig5 == 0
		_DIG5:=1
	ENDIF
	STR_NUM[5]:=_DIG5
	
	//----------------------------------- DIGITO VERIFICADOR 1
	_XX:=(2*2)+(3*1)+(5)+(9*1)
	_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),1,1))*2
	IF _wX1>9
		_wY1:=LEFT(STR(_wX1,2,0),1)
		_wY2:=RIGHT(STR(_wX1,2,0),1)
		_XX:=_XX+VAL(_wY1)+VAL(_wY2)
	ELSE
		_XX:=_XX+_wX1
	ENDIF
	_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),2,1))*1
	IF _wX1>9
		_wY1:=LEFT(STR(_wX1,2,0),1)
		_wY2:=RIGHT(STR(_wX1,2,0),1)
		_XX:=_XX+VAL(_wY1)+VAL(_wY2)
	ELSE
		_XX:=_XX+_wX1
	ENDIF
	_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),3,1))*2
	IF _wX1>9
		_wY1:=LEFT(STR(_wX1,2,0),1)
		_wY2:=RIGHT(STR(_wX1,2,0),1)
		_XX:=_XX+VAL(_wY1)+VAL(_wY2)
	ELSE
		_XX:=_XX+_wX1
	ENDIF
	_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),4,1))*1
	IF _wX1>9
		_wY1:=LEFT(STR(_wX1,2,0),1)
		_wY2:=RIGHT(STR(_wX1,2,0),1)
		_XX:=_XX+VAL(_wY1)+VAL(_wY2)
	ELSE
		_XX:=_XX+_wX1
	ENDIF
	_wX1:=VAL(SUBS(SUBSTR(SE1->E1_NUMBCO,1,11),5,1))*2
	IF _wX1>9
		_wY1:=LEFT(STR(_wX1,2,0),1)
		_wY2:=RIGHT(STR(_wX1,2,0),1)
		_XX:=_XX+VAL(_wY1)+VAL(_wY2)
	ELSE
		_XX:=_XX+_wX1
	ENDIF
	IF _XX<10
		_YY:=_XX
	ELSE
		_YY:=mod(_XX,10)
	ENDIF
	IF _YY==0
		_XX:=0
	ELSE
		_XX:=10-_YY
	ENDIF
	//---------------------------------- DIGITO VERIFICADOR 2
	_AA1:=25
	_XX1:=0
	_BB1:=1
	DO WHILE _AA1<=34
		IF STR_NUM[_AA1]*_BB1>9
			_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
			_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
			_XX1:=_XX1+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX1:=_XX1+(STR_NUM[_AA1]*_BB1)
		ENDIF
		IF _BB1==1
			_BB1:=2
		ELSE
			_BB1:=1
		ENDIF
		_AA1:=_AA1+1
	ENDDO
	IF _XX1<10
		_YY:=_XX1
	ELSE
		_YY:=mod(_XX1,10)
	ENDIF
	IF _YY==0
		_XX1:=0
	ELSE
		_XX1:=10-_YY
	ENDIF
	//---------------------------------- DIGITO VERIFICADOR 3
	_AA1:=35
	_XX2:=0
	_BB1:=1
	DO WHILE _AA1<=44
		IF STR_NUM[_AA1]*_BB1>9
			_wY1:=LEFT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
			_wY2:=RIGHT(STR(STR_NUM[_AA1]*_BB1,2,0),1)
			_XX2:=_XX2+VAL(_wY1)+VAL(_wY2)
		ELSE
			_XX2:=_XX2+(STR_NUM[_AA1]*_BB1)
		ENDIF
		IF _BB1==1
			_BB1:=2
		ELSE
			_BB1:=1
		ENDIF
		_AA1:=_AA1+1
	ENDDO
	IF _XX2<10
		_YY:=_XX2
	ELSE
		_YY:=mod(_XX2,10)
	ENDIF
	IF _YY==0
		_XX2:=0
	ELSE
		_XX2:=10-_YY
	ENDIF
	
	_Flag1:=1
	_ccodbar:=""
	FOR I:=1 to 44
		_ccodbar:=_ccodbar+STR(STR_NUM[i],1,0)
	NEXT
	
Return _cCodBar  
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 001
static function _LinDig001 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig001 (_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig001 (_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig001 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)  // digito verificador do código de barras
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// valor
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 104
static function _LinDig104 ()
	local _sRet    := ""
	local _sCampo1 := ""
	local _sCampo2 := ""
	local _sCampo3 := ""
	local _sCampo4 := ""

	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig104(_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig104 (_sCampo2)

	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig104 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)
	_sRet := Transform (_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 041
static function _LinDig041 ()
	local _sRet    := ""
	local _sCampo1 := ""
	local _sCampo2 := ""
	local _sCampo3 := ""
	local _sCampo4 := ""

	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig041 (_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig041 (_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig041 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,15) 
	_sRet := Transform (_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')

return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 399
static function _LinDig399 ()
	local _sRet      := ""
	local _aLinDig   := afill (array (47), 0)
	local _nPos      := 0
	local _nMult     := 0
	local _nSoma     := 0
	local _nPeso     := 0
	local _nResto    := 0
	local _nDV       := 0
	local _nCampo    := 0
	local _nPosIni   := 0
	local _nPosFim   := 0
	local _nPosDV    := 0
	
	_aLinDig [1]  = val (substr (see -> ee_codigo, 1, 1))  // Codigo do banco
	_aLinDig [2]  = val (substr (see -> ee_codigo, 2, 1))  // Codigo do banco
	_aLinDig [3]  = val (substr (see -> ee_codigo, 3, 1))  // Codigo do banco
	_aLinDig [4]  = 9  // Moeda: Reais
	_aLinDig [5]  = val (substr (se1 -> e1_numbco, 1,  1))  // Primeira parte do 'nosso numero'
	_aLinDig [6]  = val (substr (se1 -> e1_numbco, 2,  1))  // Primeira parte do 'nosso numero'
	_aLinDig [7]  = val (substr (se1 -> e1_numbco, 3,  1))  // Primeira parte do 'nosso numero'
	_aLinDig [8]  = val (substr (se1 -> e1_numbco, 4,  1))  // Primeira parte do 'nosso numero'
	_aLinDig [9]  = val (substr (se1 -> e1_numbco, 5,  1))  // Primeira parte do 'nosso numero'
	_aLinDig [11] = val (substr (se1 -> e1_numbco, 6,  1))  // Final do 'nosso numero'
	_aLinDig [12] = val (substr (se1 -> e1_numbco, 7,  1))  // Final do 'nosso numero'
	_aLinDig [13] = val (substr (se1 -> e1_numbco, 8,  1))  // Final do 'nosso numero'
	_aLinDig [14] = val (substr (se1 -> e1_numbco, 9,  1))  // Final do 'nosso numero'
	_aLinDig [15] = val (substr (se1 -> e1_numbco, 10, 1))  // Final do 'nosso numero'
	_aLinDig [16] = val (substr (se1 -> e1_numbco, 11, 1))  // Final do 'nosso numero'
	_aLinDig [17] = val (substr (CB_RN [1], 31, 1))  // Codigo da agencia
	_aLinDig [18] = val (substr (CB_RN [1], 32, 1))  // Codigo da agencia
	_aLinDig [19] = val (substr (CB_RN [1], 33, 1))  // Codigo da agencia
	_aLinDig [20] = val (substr (CB_RN [1], 34, 1))  // Codigo da agencia
	_aLinDig [22] = val (substr (CB_RN [1], 35, 1))  // Codigo da conta
	_aLinDig [23] = val (substr (CB_RN [1], 36, 1))  // Codigo da conta
	_aLinDig [24] = val (substr (CB_RN [1], 37, 1))  // Codigo da conta
	_aLinDig [25] = val (substr (CB_RN [1], 38, 1))  // Codigo da conta
	_aLinDig [26] = val (substr (CB_RN [1], 39, 1))  // Codigo da conta
	_aLinDig [27] = val (substr (CB_RN [1], 40, 1))  // Codigo da conta
	_aLinDig [28] = val (substr (CB_RN [1], 41, 1))  // Codigo da conta
	_aLinDig [29] = 0  // Codigo da carteira (00)
	_aLinDig [30] = 0  // Codigo da carteira (00)
	_aLinDig [31] = 1  // Codigo do aplicativo de cobranca.
	_aLinDig [33] = val (substr (CB_RN [1], 5, 1))  // Digito verificador (DAC) do codigo de barras.
	
	// Busca no codigo de barras o fator de vencimento e valor do titulo.
	for _nPos = 34 to 47
		_aLinDig [_nPos] = val (substr (CB_RN [1], _nPos - 28, 1))
	next
	
	// Calculo do digito verificador dos campos 1 a 3 (partes da linha digitavel) (posicoes 1 a 10)
	for _nCampo = 1 to 3
		do case
			case _nCampo == 1
				_nPosIni = 1
				_nPosFim = 9
				_nPosDV  = 10
			case _nCampo == 2
				_nPosIni = 11
				_nPosFim = 20
				_nPosDV  = 21
			case _nCampo == 3
				_nPosIni = 22
				_nPosFim = 31
				_nPosDV  = 32
		endcase
		
		_nSoma = 0
		_nPeso = 2
		for _nPos = _nPosFim to _nposIni step -1
			_nMult = _aLinDig [_nPos] * _nPeso
			_nPeso = iif (_nPeso == 2, 1, 2)
			if _nMult >= 10  // Se maior ou igual a 10, soma os valores dos algarismos do produto.
				_nSoma += int (_nMult / 10) + _nMult % 10
			else
				_nSoma += _nMult
			endif
		next
		if _nSoma < 10
			_nDV = 10 - _nSoma
		else
			_nResto = _nSoma % 10
			if _nResto == 0
				_nDV = 0
			else
				_nDV = 10 - _nResto
			endif
		endif
		_aLinDig [_nPosDV] = _nDV
	next
	
	// Monta string para retorno
	_sRet = ""
	for _nPos = 1 to 47
		_sRet += alltrim (str (_aLinDig [_nPos]))
		if _nPos == 5 .or. _nPos == 15 .or. _nPos == 26
			_sRet += "."
		endif
		if _nPos == 10 .or. _nPos == 21 .or. _nPos == 32 .or. _nPos == 33
			_sRet += "  "
		endif
	next
return _sRet
//
// -------------------------------------
// Gera linha digitavel para o banco 237_RED
static function _LinDigRED_237 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig001 (_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig001 (_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig001 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)  // digito verificador do código de barras
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// valor
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// -------------------------------------
// Gera linha digitavel para o banco 237
static function _LinDig237 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig001 (_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig001 (_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig001 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)  // digito verificador do código de barras
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// valor
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// -------------------------------
// linha digitavel - 341
static function _LinDig341 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)
	_sCampo1 += _DvDig001 (_sCampo1)
	_sCampo2 := substr(CB_RN [1],25,10)
	_sCampo2 += _DvDig001 (_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig001 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 422 - Safra Novo
static function _LinDig422_422 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + '7' + substr(CB_RN [1],21,4) //banco+M+F+ 4 digitos da agencia
	_sCampo1 += _DvDig422(_sCampo1) // DV
	_sCampo2 := substr(CB_RN [1],25,1)   //ultimo digito da conta
	_sCampo2 += substr(CB_RN [1],26,9)  // conta
	_sCampo2 += _DvDig422(_sCampo2)
	_sCampo3 := substr(CB_RN [1],35,10)
	_sCampo3 += _DvDig422(_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)  // digito verificador do código de barras
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// valor
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 707 - DAYCOVAL
static function _LinDig707()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + substr(CB_RN [1],20,5)  // banco + M + 5 primeiros digitos do campo livre
	_sCampo1 += _DvDig422(_sCampo1) 							// DV
	
	_sCampo2 := substr(CB_RN [1],25,10)   						// posiçoes 6 até 15
	_sCampo2 += _DvDig422(_sCampo2)

	_sCampo3 := substr(CB_RN [1],35,10)							// posições 15 ate 25 
	_sCampo3 += _DvDig422(_sCampo3)
	
	_sCampo4 := substr(CB_RN [1],5,1)  							// digito verificador do código de barras

	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// fator de vencimento + valor

	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 033
static function _LinDig033 ()
	local _sCampo1 := _sCampo2 := _sCampo3 := _sCampo4 := _sCampo5 := ""
	
	_sCampo1 := substr(CB_RN [1],1,4) + '9' + '6953'
	_sCampo1 += _DvDig001 (_sCampo1)
	_sCampo2 := '808' + '00000' + substr(strzero(val(se1 -> e1_numbco),8),1,2)
	_sCampo2 += _DvDig001 (_sCampo2)
	_sCampo3 := substr(strzero(val(se1 -> e1_numbco),8),3,8) + '0' + '101' 
	_sCampo3 += _DvDig001 (_sCampo3)
	_sCampo4 := substr(CB_RN [1],5,1)  // digito verificador do código de barras
	_sCampo5 := substr(CB_RN [1],6,4) + substr(CB_RN [1],10,10)	// valor
	_sRet := Transform(_sCampo1 + _sCampo2 + _sCampo3 + _sCampo4 + _sCampo5,'@R 99999.99999 99999.999999 99999.999999 9 99999999999999')
return _sRet
//
// --------------------------------------------------------------------------
// Gera linha digitavel para o banco 748
Static Function _LinDig748 ()
	local _cCampo1 := _cCampo2 := _cCampo3 := _cCampo4 := _cCampo5 := _xCodBar := ""

	_cCampo1 := '7489' + substr(CB_RN [1],20,5)  	+ _DvDig748('7489' + substr(CB_RN [1],20,5))
	_cCampo2 := substr(CB_RN [1],25,10)			 	+ _DvDig748(substr(CB_RN [1],25,10))
	_cCampo3 := substr(CB_RN [1],35,10) 			+ _DvDig748(substr(CB_RN [1],35,10))
	_cCampo4 := substr(CB_RN [1],5,1)					// digito verificador do código de barras
	_cCampo5 := substr(CB_RN [1],6,4) + strzero(_nVlrTit*100,10)	// valor
	_xCodBar := Transform(_cCampo1 + _cCampo2 + _cCampo3 + _cCampo4 + _cCampo5,'@R 99999.99999  99999.999999  99999.999999  9  99999999999999')
return _xCodBar
//
// --------------------------------------------------------------------------
// calcula o digito verificador da linha digitavel para o banco 001
Static Function _DvDig001 (_sCampo)
	local _sRet    := ""
	local _nSoma   := 0
	local _nFator  := 2
	local _nDezSup := 0
	local _nJ 	   := 1
	local _nI	   := 0

	For _nI := len(_sCampo) to 1 step -1
		_nMult := _nFator * val(substr(_sCampo,_nI,1))
		If _nMult > 9
			_nMult := 0
			For _nJ := 1 to 2
				_nMult += val(substr(strzero(_nFator * val(substr(_sCampo,_nI,1)),2),_nJ,1))
			Next
		EndIf
		_nSoma += _nMult
		_nFator := iif(_nFator == 1,2,1)
	Next

	// Determina a dezena imediatamente superior
	_nDezSup = 10
	do while _nDezSup < _nSoma
		_nDezSup += 10
	enddo

	_sRet = alltrim (str (_nDezSup - _nSoma))
Return _sRet
//
// --------------------------------------------------------------------------
// calcula o digito verificador da linha digitavel para o banco 422
Static Function _DvDig422 (_sCampo)
	local _nSoma  := 0
	local _nMult  := 0
	local _nPos   := 0
	local _sRet   := ""
	local _nResto := 0
	local _nPeso  := 0

	_nSoma = 0
	_nPeso = 2
	
	for _nPos = len (_sCampo) to 1 step -1
		_nMult = val (substr (_sCampo, _nPos, 1)) * _nPeso

		if _nMult > 9
			_nMult = strzero(_nMult,2)
			_nMult = val (substr (_nMult, 1, 1) ) + val (substr (_nMult, 2, 1)) 
		endif

		_nSoma += _nMult
		_nPeso = iif (_nPeso == 2, 1, 2)
	next
	
	_nResto = _nSoma % 10
	if _nResto == 0
		_sRet = '0'
	else
		_sRet = alltrim (str (10 - _nResto))
	endif
Return _sRet
//
// --------------------------------------------------------------------------
// calcula o digito verificador da linha digitavel para o banco 041 via 'modulo 10'.
Static Function _DvDig041 (_sCampo)
	local _nSoma  := 0
	local _nMult  := 0
	local _nPos   := 0
	local _sRet   := ""
	local _nResto := 0
	local _nPeso  := 0

	_nSoma = 0
	_nPeso = 2
	for _nPos = len (_sCampo) to 1 step -1
		_nMult = val (substr (_sCampo, _nPos, 1)) * _nPeso
		_nSoma += (_nMult - iif (_nMult > 9, 9, 0))
		_nPeso = iif (_nPeso == 2, 1, 2)
	next

	_nResto = _nSoma % 10
	if _nResto == 0
		_sRet = '0'
	else
		_sRet = alltrim (str (10 - _nResto))
	endif
Return _sRet
//
// --------------------------------------------------------------------------
// calcula o digito verificador da linha digitavel para o banco 104 via 'modulo 10'.
Static Function _DvDig104 (_sCampo)
	local _nSoma  := 0
	local _nMult  := 0
	local _nPos   := 0
	local _sRet   := ""
	local _nResto := 0
	local _nPeso  := 0

	_nSoma = 0
	_nPeso = 2
	for _nPos = len (_sCampo) to 1 step -1
		
		_nMult = val (substr (_sCampo, _nPos, 1)) * _nPeso
		if _nMult > 9
			_nMult = strzero(_nMult,2)
			_nMult = val (substr (_nMult, 1, 1) ) + val (substr (_nMult, 2, 1)) 
		endif
		_nSoma += _nMult
		_nPeso = iif (_nPeso == 2, 1, 2)
	next

	_nResto = _nSoma % 10
	if _nResto == 0
		_sRet = '0'
	else
		_sRet = alltrim (str (10 - _nResto))
	endif
Return _sRet
//
// --------------------------------------------------------------------------
// calcula o digito verificador da linha digitavel para o banco 748
Static Function _DvDig748(_cCampo)
	Local _nJ := 1
	Local _nI := 0
	
	_cRet   := ' '
	_nSoma  := 0
	_nFator := 2
	For _nI := len(_cCampo) to 1 step -1
		_nMult := _nFator * val(substr(_cCampo,_nI,1))
		If _nMult > 9
			_nMult := 0
			For _nJ := 1 to 2
				_nMult += val(substr(strzero(_nFator * val(substr(_cCampo,_nI,1)),2),_nJ,1))
			Next
		EndIf
		_nSoma += _nMult
		_nFator := iif(_nFator == 1,2,1)
	Next

	_cRet := '0'
	For _nI := 10 to 100 step 10
		If _nSoma <= _nI
			_cRet := str( _nI - _nSoma,1)
			exit
		EndIf
	Next
Return(_cRet)
//
// --------------------------------------------------------------------------
// Rotina de impressao do boleto
Static Function _Impress(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN, _sDigVerif)
	local _nLinIni  := 0
	local _sNumComp := ""  // Numero de compensacao
	local i 	    := 0
	
	aCoords1 := {2100,1900,2200,2300}
	aCoords2 := {2370,1900,2440,2300}
	
	//-------------------------------------- IMPRESSÃO DO RECIBO DO PAGADOR
	
	if _cBcoBol == '422' //.and. mv_par12 = 1 // modelo novo safra
		_Impress422(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN)
	elseif _cBcoBol == '041' .and. cFilAnt == '08' 		// banrisul da filial 8 - 240 posições
		_ImpLayout240(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN)
	else
		oPrn:StartPage()       // Inicia uma Nova Página
		oPrn:Line(_nLinIni+0100 , 0100 , _nLinIni+0100 , 2300)
		oPrn:Line(_nLinIni      , 0550 , _nLinIni+0100 , 0550)
		oPrn:Line(_nLinIni      , 0800 , _nLinIni+0100 , 0800)
		
		// Logotipo canto esq. superior
		_sArqLogo := alltrim (see -> ee_logobol)
		if ! empty (_sArqLogo)
			oPrn:SayBitMap (_nLinIni + 20	, ;  // Linha
			100								, ;  // Coluna
			_sArqLogo						, ;  // Arquivo
			450								, ;  // Largura
			80								  )  // Altura
		endif
		
		oPrn:Say(_nLinIni+0034 , 2020 ,"Recibo do Pagador"	,oFont10)			
		
		// Define numero de compensacao a ser impresso em negrito ao lado do logotipo do banco.
		do case
		case _cBcoBol == '001'
			_sNumComp = "001-9"
		case _cBcoBol == '041'
			_sNumComp = "041-8"
		case _cBcoBol == '104'
			_sNumComp = "104-0"
		case _cBcoBol == '237'
			_sNumComp = "237-2"
		case _cBcoBol == '341'
			_sNumComp = "341-7"
		case _cBcoBol == '399'
			_sNumComp = "399-9"
		case _cBcoBol == '422' //banco correspondente bradesco
			_sNumComp = "237-2"
		case _cBcoBol == '033'
			_sNumComp = "033-7"
		case _cBcoBol == '748'
			_sNumComp = "748-X"
		case _cBcoBol == '707'
			_sNumComp = "707-2"
		case _cBcoBol == 'RED'
			_sNumComp = "237-2"	
		otherwise
			u_help ("Sem definicao de numero de compensacao para este banco.")
			return
		endcase
		if _cBcoBol == '237' .or. _cBcoBol == '422' .or. _cBcoBol == 'RED' //banco correspondente bradesco
			oPrn:Say(_nLinIni+0028 , 0250, "Bradesco" ,oFont24 )
		elseif _cBcoBol == '033'
			oPrn:Say(_nLinIni+0028 , 0200, "Santander" ,oFont24 )
		endif
		
		oPrn:Say(_nLinIni+0028 , 0600, _sNumComp ,oFont24 )
		
		oPrn:Say(_nLinIni+0034 , 0850 ,CB_RN[2]    ,oFont12)
		oPrn:Say(_nLinIni+0150 , 0100 ,"Beneficiário     :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0200 , 0100 ,"Endereço         :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0250 , 0100 ,"Nro.Documento    :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0250 , 1100 ,"Nosso Número     :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0300 , 0100 ,"Data do Documento:"                             ,oFont8 )
		oPrn:Say(_nLinIni+0300 , 1100 ,"Vencimento       :"                             ,oFont8 )
		if _cBcoBol == '001'
			oPrn:Say(_nLinIni+0300 , 1700 ,"Valor do Documento:"                        ,oFont8 )
		else
			oPrn:Say(_nLinIni+0300 , 1700 ,"Valor " + GetMv('MV_SIMB1') + ":"               ,oFont8 )
		endif
		oPrn:Say(_nLinIni+0350 , 0100 ,"Pagador          :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0250 , 1700 ,"Carteira         :"                             ,oFont8 )
		oPrn:Say(_nLinIni+0350 , 1700 ,"CNPJ   :"                                       ,oFont8 )
		if _cBcoBol == '104' .or. (_cBcoBol == '041' .and. cNumEmp == '0108')
			oPrn:Say(_nLinIni+0400 , 0100 ,"Agencia/Beneficiario:"                      ,oFont8 )
		endif	
		// dados
		if _cBcoBol == 'RED'
			oPrn:Say(_nLinIni+0150 , 0400 ,"RED S.A. - CNPJ: 67.915.785/0001-01 - AV.CIDADE JARDIM 400 - 14o.and. SÃO PAULO - SP"    ,oFont10)
		else
			oPrn:Say(_nLinIni+0150 , 0400 ,aDadosEmp[1] + '     ' + aDadosEmp[6]            ,oFont10)
		endif	
		oPrn:Say(_nLinIni+0200 , 0400 ,aDadosEmp[2]                                     ,oFont10)
		oPrn:Say(_nLinIni+0250 , 0400 ,aDadosTit[1]                              		,oFont10)
		oPrn:Say(_nLinIni+0250 , 1325 ,aDadosTit[6]                              		,oFont10)
		if _cBcoBol == '001'
			if cfilAnt $ ("03/07/16/09")	
				oPrn:Say(_nLinIni+0250 , 1900 , alltrim(_cTabela) + "/" + alltrim(_cCodCart),oFont10)
			else
				oPrn:Say(_nLinIni+0250 , 1900 , '17'		                              	,oFont10)
			endif
		endif
		oPrn:Say(_nLinIni+0300 , 0400 ,_Dtoc(aDadosTit[2])                        		,oFont10)
		oPrn:Say(_nLinIni+0300 , 1325 ,_Dtoc(aDadosTit[4])                        		,oFont10)
		oPrn:Say(_nLinIni+0300 , 2000 ,alltrim(Transform(aDadosTit[5],"@E 9,999,999.99")) 	,oFont10)
		oPrn:Say(_nLinIni+0350 , 0400 ,aDatSacado[1] + " (" + aDatSacado[2] + ")" 		,oFont10)
		oPrn:Say(_nLinIni+0350 , 1900 ,aDatSacado[7]                    				,oFont10)
		
		if _cBcoBol == '422'
			oPrn:Say(_nLinIni+0400 , 0180 ,"ESTE BOLETO REPRESENTA DUPLICATA CEDIDA FIDUCIARIAMENTE AO BANCO SAFRA S/A," ,oFont8 ) 
			oPrn:Say(_nLinIni+0430 , 0180 ,"FICANDO VEDADO O PAGAMENTO DE QUALQUER OUTRA FORMA QUE NÃO ATRAVÉS DO PRESENTE BOLETO" ,oFont8 )
		endif
		if _cBcoBol == '104'
			oPrn:Say(_nLinIni+0400 , 0400 , "4312/618691-2" ,oFont10 ) 
			oPrn:Say(_nLinIni+0430 , 0930 ,"SAC CAIXA 0800 726 0101, Ouvidoria 0800 725 7474, Para pessoas com deficiencia auditiva ou de fala 0800 726 2492 e wwww.caixa.gov.br",oFont8 )				
		endif
		
		if _cBcoBol == '041' .and. cNumEmp == '0108'  // dados de agencia/conta do beneficiario da filial 08 - banrisul
			oPrn:Say(_nLinIni+0400 , 0400 ,  "0873 856682386"	,oFont10)
			oPrn:Say(_nLinIni+0430 , 0930 ,"                                                                       SAC BANRISUL 0800 646 1515, OUVIDORIA BANRISUL 0800 644 2200",oFont8 )				
		endif
		
		oPrn:Line(_nLinIni+0470 , 0100 ,_nLinIni+0470 ,2300)
		
		oPrn:Say( _nLinIni+0500 , 2000 ,"Autenticação Mecânica"                         ,oFont8 )
		
		For i := 100 to 2300 step 50
			oPrn:Line(_nLinIni+0600 ,i ,_nLinIni+0600 ,i+30)
		Next i
		
		oPrn:Line(_nLinIni+0700 , 100 ,_nLinIni+0700 , 2300)
		oPrn:Line(_nLinIni+0620 , 550 ,_nLinIni+0700 , 0550)
		oPrn:Line(_nLinIni+0620 , 800 ,_nLinIni+0700 , 0800)
	
		//-------------------------------------- IMPRESSÃO DO RECIBO DO BOLETO
		// Logotipo no meio da altura do boleto
		//_sArqLogo := alltrim (see -> ee_logobol)
		if ! empty (_sArqLogo)
			oPrn:SayBitMap (_nLinIni + 620	, ;  // Linha
			100								, ;  // Coluna
			_sArqLogo						, ;  // Arquivo
			450								, ;  // Largura
			80								  )  // Altura
		endif
		
		if _cBcoBol == '237' .or. _cBcoBol == '422' //banco correspondente bradesco
			oPrn:Say(_nLinIni+0620 , 0250, "Bradesco" ,oFont24 )
		elseif _cBcoBol == '033' // santander
			oPrn:Say(_nLinIni+0620 , 0200, "Santander" ,oFont24 )
		endif
		
		oPrn:Say( _nLinIni+0620 , 600 , _sNumComp, oFont24)
		oPrn:Say(_nLinIni+0640 ,850 ,CB_RN[2]    ,oFont16n)
		oPrn:Line(_nLinIni+0780 , 0100 , _nLinIni+0780 , 2300)
		oPrn:Line(_nLinIni+0860 , 0100 , _nLinIni+0860 , 2300)
		oPrn:Line(_nLinIni+0930 , 0100 , _nLinIni+0930 , 2300)
		oPrn:Line(_nLinIni+1000 , 0100 , _nLinIni+1000 , 2300)
		
		oPrn:Line(_nLinIni+0860 , 0500 , _nLinIni+1000 , 0500)
		oPrn:Line(_nLinIni+0930 , 0750 , _nLinIni+1000 , 0750)
		oPrn:Line(_nLinIni+0860 , 1000 , _nLinIni+1000 , 1000)
		oPrn:Line(_nLinIni+0860 , 1350 , _nLinIni+0930 , 1350)
		oPrn:Line(_nLinIni+0860 , 1550 , _nLinIni+1000 , 1550)
		
		oPrn:Say(_nLinIni+0705 , 0100 ,"Local de Pagamento"                         							,oFont8 )
		if _cBcoBol == '001'
			oPrn:Say(_nLinIni+0735 , 0100 ,"PAGAVEL EM QUALQUER BANCO"											, oFont10)
		Elseif _cBcoBol == '104'
			oPrn:Say(_nLinIni+0735 , 0100 ,"PREFERENCIALMENTE NAS CASAS LOTERICAS ATE O VALOR LIMITE"			, oFont10)
		Elseif _cBcoBol == '237'
			oPrn:Say(_nLinIni+0735 , 0100 ,"Pagável preferencialmente na rede Bradesco ou no Bradesco expresso"	, oFont10)
		Elseif _cBcoBol == '399'
			oPrn:Say(_nLinIni+0735 , 0100 ,"Pagável preferencialmente em qualquer Agência do Banco HSBC"		, oFont10)
		Elseif _cBcoBol == '422'
			oPrn:Say(_nLinIni+0735 , 0100 ,"PAGAVEL EM QUALQUER BANCO ATE O VENCIMENTO"							, oFont10)
		Elseif _cBcoBol == '748'
			oPrn:Say(_nLinIni+0735 , 0100 ,"Pagável preferencialmente nas cooperativas de crédito do Sicredi"	, oFont10)
		Elseif _cBcoBol == '707'
			oPrn:Say(_nLinIni+0735 , 0100 ,"PAGAVEL EM QUALQUER REDE BANCÁRIA, MESMO APÓS VENCIMENTO"			, oFont10)
		Elseif _cBcoBol == 'RED'
			oPrn:Say(_nLinIni+0735 , 0100 ,"Pagável preferencialmente na Rede Bradesco ou Bradesco Expresso"	, oFont10)
		else
			oPrn:Say(_nLinIni+0735 , 0100 ,"ATE O VENCIMENTO PAGAR NA REDE BANCARIA" 	,oFont10)
		endif
		
		oPrn:Say(_nLinIni+0705 , 1910 ,"Vencimento"                                     ,oFont8 )
		oPrn:Say(_nLinIni+0735 , 2010 ,_Dtoc(aDadosTit[4])                          	,oFont10)
		
		do case
			case _cBcoBol == '001'
				oPrn:Say(_nLinIni+0785 , 0100 ,"Nome do Beneficiário"                   ,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    ,oFont10)
			case _cBcoBol == '104'
				oPrn:Say(_nLinIni+0785 , 0100 ,"Cedente"                             	,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    ,oFont10)
				oPrn:Say(_nLinIni+0785 , 1910 ,"Agência/Código do Cedente"              ,oFont8)
			case _cBcoBol == '237'
				oPrn:Say(_nLinIni+0785 , 0100 ,"Nome do Beneficiário CPF/CNPJ/Endereço" ,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    ,oFont10)
			case _cBcoBol == 'RED'
				oPrn:Say(_nLinIni+0785 , 0100 ,"Nome do Beneficiário CPF/CNPJ/Endereço" ,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,"RED S.A. - CNPJ: 67.915.785/0001-01 - AV.CIDADE JARDIM 400 - 14o.and. SÃO PAULO - SP"    ,oFont10)
			case _cBcoBol == '422'
				oPrn:Say(_nLinIni+0785 , 0100 ,"Nome do Beneficiário CPF/CNPJ/Endereço" ,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,"BANCO SAFRA"                            ,oFont10)											
			otherwise  // outros bancos						
				oPrn:Say(_nLinIni+0785 , 0100 ,"Beneficiário"                           ,oFont8 )
				oPrn:Say(_nLinIni+0815 , 0100 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    ,oFont10)
		endcase			
			
		If _cBcoBol != '104'
			oPrn:Say(_nLinIni+0785 , 1910 ,"Agência/Código do Beneficiário"              ,oFont8)
		endif		
		
		If cNumEmp == '0101' .and. _cBcoBol == '748'
			oPrn:Say(_nLinIni+0815 , 1960 ,"0101.98/24210" 			,oFont10)
		ElseIf _cBcoBol == '104'
			oPrn:Say(_nLinIni+0815 , 1960 ,"4312/618691-2" 			,oFont10)			
		ElseIf _cBcoBol == '422'
			oPrn:Say(_nLinIni+0815 , 1960 ,"3114-3/0176300-8" 		,oFont10)			
		ElseIf _cBcoBol == '237'
			oPrn:Say(_nLinIni+0815 , 1960 ,"3471-1/0000481-2" 		,oFont10)
		ElseIf _cBcoBol == 'RED'
			oPrn:Say(_nLinIni+0815 , 1960 ,"3391-0/0006332-0" 		,oFont10)	
		ElseIf _cBcoBol == '041' .and. cNumEmp == '0108'  // dados de agencia/conta do beneficiario da filial 08 - banrisul 
			oPrn:Say(_nLinIni+0815 , 1960 ,"0873 856682386"	,oFont10)
		Else
			oPrn:Say(_nLinIni+0815 , 1960 ,alltrim(_cAgeBol) +" / " + alltrim(_cCtaBol),oFont10)
		EndiF
		
		oPrn:Say(_nLinIni+0865 , 0100 ,"Data do Documento"                         	,oFont8 )
		oPrn:Say(_nLinIni+0895, 0100 ,_DTOC(aDadosTit[2])                          	,oFont10)
		
		oPrn:Say(_nLinIni+0865 , 0505 ,"Nro.Documento"                             	,oFont8 )
		oPrn:Say(_nLinIni+0895 , 0605 ,aDadosTit[1]                                	,oFont10)
		
		oPrn:Say(_nLinIni+0865 , 1005 ,"Espécie Doc."                              	,oFont8 )
		If _cBcoBol == '399'
			oPrn:Say(_nLinIni+0895 , 1105 ,"PD"    		                            ,oFont10)
		else
			oPrn:Say(_nLinIni+0895 , 1105 ,"DM"    		                            ,oFont10)
		endif
		
		oPrn:Say(_nLinIni+0865 , 1355 ,"Aceite"                                    	,oFont8 )
		oPrn:Say(_nLinIni+0895 , 1455 ,"N" 		                                	,oFont10)
		oPrn:Say(_nLinIni+0865 , 1555 ,"Data do Processamento"                     	,oFont8 )
		oPrn:Say(_nLinIni+0895 , 1655 ,_Dtoc(aDadosTit[7])                         	,oFont10)
		
		oPrn:Say(_nLinIni+0865 , 1910 ,"Nosso Número"                              	,oFont8 )
		if _cBcoBol == '422'
	        _wano := substr(dtos(se1->e1_emissao),3,2)
			oPrn:Say(_nLinIni+0895 , 1960 , "09/" + _wano + aDadosTit[6]            ,oFont10)
		elseif _cBcoBol == '237'
			oPrn:Say(_nLinIni+0895 , 1960 , "02/" + aDadosTit[6]            	    ,oFont10)
		elseif _cBcoBol == '341'				
			oPrn:Say(_nLinIni+0895 , 1960 , "109/" + aDadosTit[6]                   ,oFont10)
		elseif _cBcoBol == 'RED'
			oPrn:Say(_nLinIni+0895 , 1960 , "09/" + aDadosTit[6]            	    ,oFont10)	
		elseif _cBcoBol == '707'
			_sNum707 := alltrim(_cAgeBol)+'/'+ alltrim(see->ee_subcta)+'/'+aDadosTit[6] + '-' + _sDigVerif
			oPrn:Say(_nLinIni+0885 , 1960 , _sNum707								,oFont10)	
		else		
			oPrn:Say(_nLinIni+0895 , 1960 ,aDadosTit[6]                           	,oFont10)
		endif		
		oPrn:Say(_nLinIni+0935 , 0100 ,"Uso do Banco"                              	,oFont8 )
		
		if _cBcoBol == '422' .or. _cBcoBol == '237'
			oPrn:Say(_nLinIni+0935 , 0400 ,"CIP"                              		,oFont8 )
			oPrn:Say(_nLinIni+0965,  0400 ,"000"                                	,oFont10)
		endif
		
		oPrn:Say(_nLinIni+0935 , 0505 ,"Carteira"                                  	,oFont8 )
		If _cBcoBol == '001'
			if cFilAnt $ ("03/07/16/09")
				// 202006
				oPrn:Say(_nLinIni+0965, 0605 ,alltrim(_cTabela) + "/" + alltrim(_cCodCart),oFont10)
			else
				if cNumEmp =  '0101'
					oPrn:Say(_nLinIni+0965, 0605 ,"17/035"                                     	,oFont10)
				else
					oPrn:Say(_nLinIni+0965, 0605 ,"17/019"                                     	,oFont10)
				endif	
			endif
		elseif _cBcoBol == '104'
			oPrn:Say(_nLinIni+0965, 0605 ,"RG"                                       	,oFont10)
		elseif _cBcoBol == '237'
			oPrn:Say(_nLinIni+0965, 0605 ,"02"                                       	,oFont10)
		elseif _cBcoBol == 'RED'
			oPrn:Say(_nLinIni+0965, 0605 ,"09"                                       	,oFont10)	
		elseif _cBcoBol == '341'
			oPrn:Say(_nLinIni+0965, 0605 ,"109"                                       	,oFont10)
		elseif _cBcoBol == '422'
			oPrn:Say(_nLinIni+0965, 0605 ,"09"                                       	,oFont10)	
		elseif _cBcoBol == '399'
			oPrn:Say(_nLinIni+0965, 0605 ,"CSB"                                       	,oFont10)
		elseif _cBcoBol == '707'
			oPrn:Say(_nLinIni+0965, 0605 ,"121"                                       	,oFont10)
		endif
		
		oPrn:Say(_nLinIni+0935 , 0755 ,"Espécie"                                   	,oFont8 )
		oPrn:Say(_nLinIni+0965 , 0805 ,GetMv('MV_SIMB1')                            ,oFont10)
		
		oPrn:Say(_nLinIni+0935 , 1005 ,"Quantidade"                                	,oFont8 )
		oPrn:Say(_nLinIni+0935 , 1555 ,"Valor"                                     	,oFont8 )
		
		oPrn:Say(_nLinIni+0935 , 1910 ,"(=)Valor do Documento"                     	,oFont8 )
		oPrn:Say(_nLinIni+0965 , 2010 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)
		
		if _cBcoBol == "422"
			oPrn:Say(_nLinIni+1005 , 0100 ,"Instruções/Todas as informações deste boleto são de reponsabilidade do pagador avalista" ,oFont8 )
		else
			if _cBcoBol == "104" .or. _cBcoBol == '237' .or. _cBcoBol == 'RED'
				oPrn:Say(_nLinIni+1005 , 0100 ,"Instruções/Texto de responsabilidade do beneficiario" ,oFont8 )
			else
				if _cBcoBol == "707" 
					oPrn:Say(_nLinIni+1005 , 0100 ,"Informações de responsabilidade do Beneficiário" ,oFont8 )
				else
					oPrn:Say(_nLinIni+1005 , 0100 ,"Instruções/Texto de responsabilidade do cedente" ,oFont8 )
				endif
			endif			
		endif
		
		if	_cBcoBol == "RED"
			oPrn:Say(_nLinIni+1050 , 0100 ,"COBRAR MULTA DE 2% APOS VENCMENTO ",oFont12)
			oPrn:Say(_nLinIni+1100 , 0100 ,"MORA DE 8% AO MES",oFont12)
		else	
			oPrn:Say(_nLinIni+1050 , 0100 ,"COBRAR JUROS DE " + GetMv('MV_SIMB1') + " " + alltrim (transform (Round(aDadosTit [5] * (aDadosTit [8] / 30 / 100),2), "@E 999,999,999.99")) + " AO DIA"		,oFont12)
			if _cBcoBol == "001"
				oPrn:Say(_nLinIni+1100 , 0100 ,"PROTESTAR " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS CORRIDOS DO VENCIMENTO",oFont12)
			else
				oPrn:Say(_nLinIni+1110 , 0100 ,"PROTESTAR " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS DO VENCIMENTO" ,oFont12)
			endif
			do case
				case _cBcoBol == '001'
					oPrn:Say(_nLinIni+1170 , 0100 ,"APÓS O VENCIMENTO, PAGÁVEL SOMENTE NAS AGÊNCIAS DO BANCO DO BRASIL" ,oFont12)
				case _cBcoBol == '399'
					oPrn:Say(_nLinIni+1170 , 0100 ,"APÓS O VENCIMENTO, PAGÁVEL SOMENTE NAS AGÊNCIAS DO HSBC"			,oFont12)
				case _cBcoBol == '748'
					oPrn:Say(_nLinIni+1170 , 0100 ,"APÓS O VENCIMENTO, PAGÁVEL SOMENTE NAS AGÊNCIAS DO SICREDI"			,oFont12)
			endcase
		endif	
		oPrn:Say(_nLinIni+1230 , 0100 ,mv_par10                                   ,oFont12)
		oPrn:Line(_nLinIni+0700 , 1900 ,_nLinIni+1350 , 1900)
		oPrn:Line(_nLinIni+1070 , 1900 ,_nLinIni+1070 , 2300)
		oPrn:Line(_nLinIni+1140 , 1900 ,_nLinIni+1140 , 2300)
		oPrn:Line(_nLinIni+1210 , 1900 ,_nLinIni+1210 , 2300)
		oPrn:Line(_nLinIni+1280 , 1900 ,_nLinIni+1280 , 2300)
		
		oPrn:Say(_nLinIni+1005 , 1910 ,"(-)Desconto/Abatimento"                    ,oFont8 )
		oPrn:Say(_nLinIni+1035 , 2010 ,Transform(aDatSacado[8],"@EZ 9,999,999.99") ,oFont10)
		
		oPrn:Say(_nLinIni+1075 , 1910 ,"(-)Outras Deduções"                        ,oFont8 )
		if _cBcoBol = '104'
			oPrn:Say(_nLinIni+1145 , 1910 ,"(+)Mora/Multa/Juros"                   ,oFont8 )
		else
			oPrn:Say(_nLinIni+1145 , 1910 ,"(+)Mora/Multa"                         ,oFont8 )
		endif		
		oPrn:Say(_nLinIni+1215 , 1910 ,"(+)Outros Acréscimos"                      ,oFont8 )
		oPrn:Say(_nLinIni+1285 , 1910 ,"(-)Valor Cobrado"                          ,oFont8 )
	
		oPrn:Line(_nLinIni+1350 , 0100 ,_nLinIni+1350 , 2300)

		oPrn:Say(_nLinIni+1355 , 0100 , "Pagador"                      ,oFont8 )
		if _cBcoBol = '707'
			oPrn:Say(_nLinIni+1355 , 0350 ,aDatSacado[1]+" ("+aDatSacado[2]+")"         				,oFont10)
			oPrn:Say(_nLinIni+1355 , 1800 ,"CNPJ/CPF:"  + aDatSacado[7] 								,oFont10)
			oPrn:Say(_nLinIni+1395 , 0350 ,aDatSacado[3]                                                ,oFont10)
			oPrn:Say(_nLinIni+1435 , 0350 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oPrn:Say(_nLinIni+1475 , 0350 ,aDatSacado[6]                                                ,oFont10)
		else
			oPrn:Say(_nLinIni+1355 , 0350 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
			oPrn:Say(_nLinIni+1395 , 0350 ,aDatSacado[3]                                                ,oFont10)
			oPrn:Say(_nLinIni+1435 , 0350 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
			oPrn:Say(_nLinIni+1475 , 0350 ,aDatSacado[6]                                                ,oFont10)
		endif
		
		if _cBcoBol = '422' .or. _cBcoBol = 'RED' .or. _cBcoBol = '104' 
		    oPrn:Say(_nLinIni+1510 , 0100 , "Sacador/Avalista"            			,oFont8 )
			oPrn:Say(_nLinIni+1512 , 0350 , aDadosEmp[1]                            ,oFont10)
		endif
		if _cBcoBol = '707' 
			oPrn:Say(_nLinIni+1510 , 0100 , "Sacador/Avalista"            			,oFont8 )
			oPrn:Say(_nLinIni+1512 , 0350 , aDadosEmp[1]                            ,oFont10)
			oPrn:Say(_nLinIni+1512 , 1800 , aDadosEmp[6]              				,oFont10)
		endif	

		oPrn:Line(_nLinIni+1550 , 0100 ,_nLinIni+1550 , 2300)
		
		oPrn:Say(_nLinIni+1550 , 1580 ,"Autenticação Mecânica"                     ,oFont8 )
		oPrn:Say(_nLinIni+1550 , 1910 ,"Ficha de Compensação"                      ,oFont10)
		
		If _cBcoBol <> "999"  // Carteira
			If _nLinIni == 0
				if _cBcoBol = '104'
					// medida dos boletos da caixa tem que ser 13 mm altura X 103 mm largura
					MSBAR("INT25",13.60,1.10,CB_RN[1],oPrn,.F.,,,0.02900,1.3,,,,.F.)
				else
			    	MSBAR("INT25",13.60,1.10,CB_RN[1],oPrn,.F.,,,0.02300,1.2,,,,.F.)
				endif 
			Else
				MSBAR("INT25",29.10,1.10,CB_RN[1],oPrn,.F.,,,0.02300,1.2,,,,.F.)
			EndIf
		Endif
		oPrn:EndPage()       // Finaliza a página
	Endif
Return
//
// --------------------------------------------------------------------------
// Impressão do boleto Safra - novo layout
Static function _Impress422(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN)
	local _nLinIni  := 0
	local _sNumComp := ""  // Numero de compensacao
	local i 	    := 0
	
	aCoords1 := {2100,1900,2200,2300}
	aCoords2 := {2370,1900,2440,2300}
	
	//-------------------------------------- IMPRESSÃO DO RECIBO DO PAGADOR	
	oPrn:StartPage()       // Inicia uma Nova Página
	
	oPrn:Line(_nLinIni+0100 , 0100 , _nLinIni+0100 , 2300) // horizontal
	oPrn:Line(_nLinIni+0100 , 0100 , _nLinIni+0520 , 0100)  // vertical
	oPrn:Line(_nLinIni+0100 , 2300 , _nLinIni+0520 , 2300) // vertical
	oPrn:Line(_nLinIni+0520 , 0100 , _nLinIni+0520 , 2300) // horizontal
	
	_sNumComp   := "422-7"
	_422Agencia := "03900"
	_422Conta   := "002009960"
	
	oPrn:Say (_nLinIni+0035 ,  0110 ,"Banco Safra S.A."   			,oFont16)
	oPrn:Say (_nLinIni+0035 ,  1950 ,"Recibo do Pagador"			,oFont12)
	oPrn:Say (_nLinIni+0100 ,  0110 ,"Beneficiário"			    	,oFont10)
	oPrn:Say (_nLinIni+0150 ,  0110 ,sDadosEmp1  					,oFont8)
	oPrn:Line(_nLinIni+0100 ,  1200 , _nLinIni+0290 , 1200) // vertical
	oPrn:Say (_nLinIni+0100 ,  1210 ,"Nosso Número"			    	,oFont10)
	//_wano := substr(dtos(se1->e1_emissao),3,2)	
	oPrn:Say (_nLinIni+0150 ,  1210 ,alltrim(aDadosTit[6])  		,oFont10)
	oPrn:Line(_nLinIni+0100 ,  1700 ,_nLinIni+0290 , 1700)  // vertical
	oPrn:Say (_nLinIni+0100 ,  1720 ,"Vencimento"			    	,oFont10)
	oPrn:Say (_nLinIni+0150 ,  1720 ,alltrim(_Dtoc(aDadosTit[4]))  	,oFont10)
	oPrn:Line(_nLinIni+0190 ,  0100 ,_nLinIni+0190 , 2300)  // horizontal
	oPrn:Say (_nLinIni+0200 ,  0110 ,"Data do Docto"		 		,oFont10)
	oPrn:Say (_nLinIni+0250 ,  0110 ,alltrim(_Dtoc(aDadosTit[2]))	,oFont10)
	oPrn:Line(_nLinIni+0190 ,  0400 , _nLinIni+0290 , 0400) // vertical
	oPrn:Say (_nLinIni+0200 ,  0410 ,"Número do documento"	 		,oFont10)
	oPrn:Say (_nLinIni+0250 ,  0410 ,alltrim(aDadosTit[1])	 		,oFont10)
	oPrn:Line(_nLinIni+0190 ,  0850 , _nLinIni+0290 , 0850) // vertical
	oPrn:Say (_nLinIni+0200 ,  0860 ,"Carteira"	 					,oFont10)
	oPrn:Say (_nLinIni+0250 ,  0860 ,"02"			     			,oFont10)
	oPrn:Line(_nLinIni+0190 ,  0850 , _nLinIni+0290 , 0850)  // vertical
	oPrn:Say (_nLinIni+0200 ,  1210 ,"Agência/Código Beneficiário"	,oFont10)
	oPrn:Say (_nLinIni+0250 ,  1210 ,_422Agencia +"/"+_422Conta		,oFont10)
	oPrn:Say (_nLinIni+0200 ,  1720 ,"Valor"	 					,oFont10)
	oPrn:Say (_nLinIni+0250 ,  1720 ,alltrim(Transform(aDadosTit[5],"@E 9,999,999.99"))		,oFont10)
	oPrn:Line(_nLinIni+0290 ,  0100 , _nLinIni+0290 , 2300) // horizontal
	oPrn:Say (_nLinIni+0300 ,  0110 ,"Pagador"			    ,oFont10)
	oPrn:Say (_nLinIni+0350 ,  0110 ,alltrim(aDatSacado[1]) + " - "	+alltrim(aDatSacado[7]) ,oFont8)
	oPrn:Line(_nLinIni+0390 ,  0100 , _nLinIni+0390 , 2300) // horizontal
	oPrn:Say (_nLinIni+0400 ,  0110 ,"Instruções(Todas as informações deste bloqueto são de exclusiva responsabilidade do Beneficiário)",oFont8)
	oPrn:Say (_nLinIni+0450 ,  0110 ,"*  ESTE BOLETO REPRESENTA DUPLICATA CEDIDA FIDUCIARIAMENTE AO BANCO SAFRA S/A, FICANDO   VEDADO O PAGAMENTO DE QUALQUER OUTRA FORMA",oFont8)
	oPrn:Say (_nLinIni+0480 ,  0110 ,"  QUE NÃO ATRAVÉS DO PRESENTE BOLETO.",oFont8)
	
	For i := 100 to 2300 step 40
		oPrn:Line(_nLinIni+0550 ,i ,_nLinIni+0550 ,i+30)
	Next i
	
	//-------------------------------------- IMPRESSÃO DO BOLETO
	oPrn:Say (_nLinIni+0640 , 0110 , "Banco Safra S.A." 	,oFont16)
	oPrn:Say (_nLinIni+0640 , 0600 , _sNumComp				,oFont16)
	oPrn:Say (_nLinIni+0640 , 1000 , CB_RN[2]    			,oFont12)
	oPrn:Line(_nLinIni+0700 , 0100 , _nLinIni+0700 , 2300)
	oPrn:Line(_nLinIni+0580 , 0780 , _nLinIni+0700 , 0780)
	
	oPrn:Line(_nLinIni+0700 , 0100 , _nLinIni+1550 , 0100) 
	oPrn:Line(_nLinIni+0700 , 2300 , _nLinIni+1600 , 2300) //1510
	
	oPrn:Line(_nLinIni+0780 , 0100 , _nLinIni+0780 , 2300)
	oPrn:Line(_nLinIni+0860 , 0100 , _nLinIni+0860 , 2300) 
	oPrn:Line(_nLinIni+0930 , 0100 , _nLinIni+0930 , 2300)
	oPrn:Line(_nLinIni+1000 , 0100 , _nLinIni+1000 , 2300)
	
	oPrn:Line(_nLinIni+0860 , 0500 , _nLinIni+1000 , 0500)
	oPrn:Line(_nLinIni+0930 , 0750 , _nLinIni+1000 , 0750)
	oPrn:Line(_nLinIni+0860 , 1000 , _nLinIni+1000 , 1000)
	oPrn:Line(_nLinIni+0860 , 1350 , _nLinIni+0930 , 1350)
	oPrn:Line(_nLinIni+0860 , 1550 , _nLinIni+1000 , 1550)
	
	oPrn:Say(_nLinIni+0705 , 0110 ,"Local de Pagamento"                         ,oFont8 )
	oPrn:Say(_nLinIni+0735 , 0110 ,"Pagável em qualquer banco" 					,oFont10)
	
	oPrn:Say(_nLinIni+0705 , 1910 ,"Vencimento"                                 ,oFont8 )
	oPrn:Say(_nLinIni+0735 , 1950 ,_Dtoc(aDadosTit[4])                          ,oFont10)	
					
	oPrn:Say(_nLinIni+0785 , 0110 ,"Beneficiário"                            	,oFont8)
	oPrn:Say(_nLinIni+0815 , 0110 ,sDadosEmp1							    	,oFont10)	
	
	oPrn:Say(_nLinIni+0785 , 1910 ,"Agência/Código do Beneficiário"             ,oFont8)
	oPrn:Say(_nLinIni+0815 , 1950 ,_422Agencia +"/"+_422Conta					,oFont10)		
	
	oPrn:Say(_nLinIni+0865 , 0110 ,"Data do Docto" 	                        	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 0110 ,_DTOC(aDadosTit[2])                          ,oFont10)
	
	oPrn:Say(_nLinIni+0865 , 0510 ,"Nº do Documento"                            ,oFont8 )
	oPrn:Say(_nLinIni+0895 , 0650 ,aDadosTit[1]                                	,oFont10)
	
	oPrn:Say(_nLinIni+0865 , 1005 ,"Espécie Docto"                              ,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1150 ,"DM"    		                                ,oFont10)
	
	oPrn:Say(_nLinIni+0865 , 1355 ,"Aceite"                                    	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1450 ,"N" 		                                	,oFont10)
	
	oPrn:Say(_nLinIni+0865 , 1555 ,"Data Movto"                     	        ,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1660 ,_Dtoc(aDadosTit[7])                         	,oFont10)
	
	oPrn:Say(_nLinIni+0865 , 1910 ,"Nosso Número"                              	,oFont8 )
	//oPrn:Say(_nLinIni+0895 , 1950 , aDadosTit[6]            					,oFont10)
    //_wano := substr(dtos(se1->e1_emissao),3,2)
	oPrn:Say(_nLinIni+0895 , 1950 , aDadosTit[6]            			,oFont10)
	
	oPrn:Say(_nLinIni+0935 , 0110 ,"Data da Oper"                              	,oFont8 )

	oPrn:Say(_nLinIni+0935 , 0510 ,"Carteira"                                  	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 0610 ,"02"                                       	,oFont10)	
	
	oPrn:Say(_nLinIni+0935 , 0760 ,"Espécie"                                   	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 0850 ,GetMv('MV_SIMB1')                            ,oFont10)
	
	oPrn:Say(_nLinIni+0935 , 1005 ,"Quantidade"                                	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 1555 ,"Valor"                                     	,oFont8 )
	
	oPrn:Say(_nLinIni+0935 , 1910 ,"(=)Valor do Documento"                     	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 1950 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)
	
	oPrn:Say(_nLinIni+1005 , 0110 ,"Instruções (Todas as informações deste bloqueto são de exclusiva responsabilidade do Beneficiário)" ,oFont8 )
	
	oPrn:Say(_nLinIni+1050 , 0110 ,"COBRAR JUROS DE " + GetMv('MV_SIMB1') + " " + alltrim (transform (Round(aDadosTit [5] * (aDadosTit [8] / 30 / 100),2), "@E 999,999,999.99")) + " AO DIA"		,oFont12)
	oPrn:Say(_nLinIni+1110 , 0110 ,"PROTESTAR " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS DO VENCIMENTO",oFont12)
	
	oPrn:Say(_nLinIni+1300 , 0100 ,alltrim(mv_par10)                ,oFont12)
	
	oPrn:Line(_nLinIni+0700 , 1900 ,_nLinIni+1350 , 1900)
	oPrn:Line(_nLinIni+1070 , 1900 ,_nLinIni+1070 , 2300)
	oPrn:Line(_nLinIni+1140 , 1900 ,_nLinIni+1140 , 2300)
	oPrn:Line(_nLinIni+1210 , 1900 ,_nLinIni+1210 , 2300)
	oPrn:Line(_nLinIni+1280 , 1900 ,_nLinIni+1280 , 2300)
	
	oPrn:Say(_nLinIni+1005 , 1910 ,"(-)Desconto/Abatimento"                    ,oFont8 )
	oPrn:Say(_nLinIni+1035 , 1950 ,Transform(aDatSacado[8],"@EZ 9,999,999.99") ,oFont10)
	
	oPrn:Say(_nLinIni+1075 , 1910 ,"(-)Outras Deduções"                        ,oFont8 )
	oPrn:Say(_nLinIni+1145 , 1910 ,"(+)Mora/Multa"                             ,oFont8 )		
	oPrn:Say(_nLinIni+1215 , 1910 ,"(+)Outros Acréscimos"                      ,oFont8 )
	oPrn:Say(_nLinIni+1285 , 1910 ,"(-)Valor Cobrado"                          ,oFont8 )
	
	oPrn:Line(_nLinIni+1350 , 0100 ,_nLinIni+1350 , 2300)

	oPrn:Say(_nLinIni+1355 , 0110 , "Pagador"                      								,oFont8 )
	oPrn:Say(_nLinIni+1355 , 0350 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont8)
	oPrn:Say(_nLinIni+1395 , 0110 , "Endereço"                      ,oFont8 )
	oPrn:Say(_nLinIni+1395 , 0350 ,aDatSacado[3]                                                ,oFont8)
	oPrn:Say(_nLinIni+1435 , 0350 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont8)
	oPrn:Say(_nLinIni+1475 , 0350 ,aDatSacado[6]                                                ,oFont8)
	
	oPrn:Say(_nLinIni+1510 , 0110 , "Sacador/Avalista"         ,oFont8 )
	oPrn:Line(_nLinIni+1550 , 0100 ,_nLinIni+1550 , 2300)
	
	oPrn:Say (_nLinIni+1550 , 1940 ,"Autenticação Mecânica"     ,oFont8 )
	oPrn:Line(_nLinIni+1600 , 1850 , _nLinIni+1600 , 2300)
	oPrn:Say (_nLinIni+1600 , 1910 ,"Ficha de Compensação"      ,oFont10)
	
	If _cBcoBol <> "999"  // Carteira
		If _nLinIni == 0
		    MSBAR("INT25",13.60,1.10,CB_RN[1],oPrn,.F.,,,0.02300,1.2,,,,.F.)
		Else
			MSBAR("INT25",29.10,1.10,CB_RN[1],oPrn,.F.,,,0.02300,1.2,,,,.F.)
		EndIf
	Endif
	
	oPrn:EndPage()       // Finaliza a página
Return
//
// --------------------------------------------------------------------------
// Impressão do boleto 240 posições - novo layout
Static function _ImpLayout240(oPrn,aDadosEmp,sDadosEmp1,aDadosTit,aDatSacado, CB_RN)
	local _nLinIni  := 0
	local _sNumComp := ""  // Numero de compensacao
	local i 	    := 0
	
	aCoords1 := {2100,1900,2200,2300}
	aCoords2 := {2370,1900,2440,2300}
	
	oPrn:StartPage()       // Inicia uma Nova Página
	
	//-------------------------------------- IMPRESSÃO DO RECIBO DO PAGADOR
	// Logotipo canto esq. superior
	_sArqLogo := alltrim (see -> ee_logobol)
	if ! empty (_sArqLogo)
		oPrn:SayBitMap (_nLinIni + 80	, ;  // Linha
		100								, ;  // Coluna
		_sArqLogo						, ;  // Arquivo
		450								, ;  // Largura
		80								  )  // Altura
	endif
		
	// Define numero de compensacao a ser impresso em negrito ao lado do logotipo do banco.
	do case
		case _cBcoBol == '041'
			_sNumComp = "041-8"
		otherwise
			u_help ("Sem definicao de numero de compensacao para este banco.")
			return
	endcase

	_nLinIni := -500
	oPrn:Line(_nLinIni+0700 , 100 ,_nLinIni+0700 , 2300)
	oPrn:Line(_nLinIni+0620 , 550 ,_nLinIni+0700 , 0550)
	oPrn:Line(_nLinIni+0620 , 800 ,_nLinIni+0700 , 0800)

	oPrn:Say( _nLinIni+0620 ,  600 , _sNumComp   , oFont24)
	_sSac    := "SAC BANRISUL: 0800 646 1515"
	_sSac2   := "OUVIDORIA BANRISUL: 0800 644 2200"
	_sRecibo := "RECIBO DO PAGADOR"
	oPrn:Say( _nLinIni+0610 ,  850 , _sSac    ,oFont8)
	oPrn:Say( _nLinIni+0650 ,  850 , _sSac2   ,oFont8)
	oPrn:Say( _nLinIni+0640 , 2000 , _sRecibo ,oFont10)
	oPrn:Line(_nLinIni+0780 , 0100 , _nLinIni+0780 , 2300)
	oPrn:Line(_nLinIni+0860 , 0100 , _nLinIni+0860 , 2300)
	oPrn:Line(_nLinIni+0930 , 0100 , _nLinIni+0930 , 2300)
	oPrn:Line(_nLinIni+1000 , 0100 , _nLinIni+1000 , 2300)
	
	oPrn:Line(_nLinIni+0860 , 0500 , _nLinIni+0930 , 0500)
	oPrn:Line(_nLinIni+0930 , 0750 , _nLinIni+1000 , 0750)
	oPrn:Line(_nLinIni+0860 , 1000 , _nLinIni+1000 , 1000)
	oPrn:Line(_nLinIni+0860 , 1350 , _nLinIni+0930 , 1350)
	oPrn:Line(_nLinIni+0860 , 1550 , _nLinIni+1000 , 1550)
	
	oPrn:Say(_nLinIni+0705 , 0100 ,"Local de Pagamento"                         			,oFont8 )
	oPrn:Say(_nLinIni+0735 , 0100 ,"PAGÁVEL PREFERENCIALMENTE NA REDE INTEGRADA BANRISUL" 	,oFont10)
	oPrn:Say(_nLinIni+0705 , 1910 ,"Vencimento"                                     		,oFont8 )
	oPrn:Say(_nLinIni+0735 , 2010 ,_Dtoc(aDadosTit[4])                          			,oFont10)
	oPrn:Say(_nLinIni+0785 , 0100 ,"Beneficiário"                            				,oFont8 )
	oPrn:Say(_nLinIni+0785 , 0250 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    				,oFont8)	
	oPrn:Say(_nLinIni+0825 , 0250 ,_sEndereco                               				,oFont8)		
	oPrn:Say(_nLinIni+0785 , 1910 ,"Agência/Código do Beneficiário"                    		,oFont8)		
	
	If _cBcoBol == '041' .and. cNumEmp == '0108'  // dados de agencia/conta do beneficiario da filial 08 - banrisul 
		oPrn:Say(_nLinIni+0815 , 1960 ,"0873 856682386"	,oFont10)
	Else
		oPrn:Say(_nLinIni+0815 , 1960 ,_cAgeBol+"  /  "+_cCtaBol,oFont10)
	EndiF
	
	oPrn:Say(_nLinIni+0865 , 0100 ,"Data do Documento"                         	,oFont8 )
	oPrn:Say(_nLinIni+0895, 0100 ,_DTOC(aDadosTit[2])                          	,oFont10)
	oPrn:Say(_nLinIni+0865 , 0505 ,"Nro.Documento"                             	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 0605 ,aDadosTit[1]                                	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1005 ,"Espécie Doc."                              	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1105 ,"DM"    		                                ,oFont10)
	oPrn:Say(_nLinIni+0865 , 1355 ,"Aceite"                                    	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1455 ,"N" 		                                	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1555 ,"Data do Processamento"                     	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1655 ,_Dtoc(aDadosTit[7])                         	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1910 ,"Nosso Número"                              	,oFont8 )		
	oPrn:Say(_nLinIni+0895 , 1960 ,aDadosTit[6]                           	    ,oFont10)		
	oPrn:Say(_nLinIni+0935 , 0100 ,"Uso do Banco"                              	,oFont8 )	
	oPrn:Say(_nLinIni+0935 , 0755 ,"Espécie"                                   	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 0805 ,GetMv('MV_SIMB1')                            ,oFont10)
	oPrn:Say(_nLinIni+0935 , 1005 ,"Quantidade"                                	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 1555 ,"Valor"                                     	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 1910 ,"(=)Valor do Documento"                     	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 2010 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)
	oPrn:Say(_nLinIni+1005 , 0100 ,"Informações de responsabilidade do beneficiário" ,oFont8 )
	oPrn:Say(_nLinIni+1050 , 0100 ,"COBRAR JUROS DE " + GetMv('MV_SIMB1') + " " + alltrim (transform (Round(aDadosTit [5] * (aDadosTit [8] / 30 / 100),2), "@E 999,999,999.99")) + " AO DIA"		,oFont12)
	oPrn:Say(_nLinIni+1110 , 0100 ,"PROTESTAR " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS DO VENCIMENTO",oFont12)
	If aDatSacado[8] > 0
		oPrn:Say(_nLinIni+1170 , 0100 ,"POR OCASIÃO DO PAGAMENTO, ABATER R$ " + Transform(aDatSacado[8],"@EZ 9,999,999.99"),oFont12) // 20220610
	EndIf
	
	oPrn:Say(_nLinIni+1230 , 0100 ,mv_par10                                 	,oFont12)
	oPrn:Line(_nLinIni+0700 , 1900 ,_nLinIni+1350 , 1900)
	oPrn:Line(_nLinIni+1070 , 1900 ,_nLinIni+1070 , 2300)
	oPrn:Line(_nLinIni+1140 , 1900 ,_nLinIni+1140 , 2300)
	oPrn:Line(_nLinIni+1210 , 1900 ,_nLinIni+1210 , 2300)
	oPrn:Line(_nLinIni+1280 , 1900 ,_nLinIni+1280 , 2300)
	
	oPrn:Say(_nLinIni+1005 , 1910 ,"(-)Desconto/Abatimento"                    ,oFont8 )
	oPrn:Say(_nLinIni+1035 , 2010 ,Transform(aDatSacado[8],"@EZ 9,999,999.99") ,oFont10)
	oPrn:Say(_nLinIni+1075 , 1910 ,"(-)Outras Deduções"                        ,oFont8 )
	oPrn:Say(_nLinIni+1145 , 1910 ,"(+)Mora/Multa"                             ,oFont8 )		
	oPrn:Say(_nLinIni+1215 , 1910 ,"(+)Outros Acréscimos"                      ,oFont8 )
	oPrn:Say(_nLinIni+1285 , 1910 ,"(-)Valor Cobrado"                          ,oFont8 )
	oPrn:Line(_nLinIni+1350 , 0100 ,_nLinIni+1350 , 2300)
	oPrn:Say(_nLinIni+1355 , 0100 , "Pagador"                      ,oFont8 )

	oPrn:Say(_nLinIni+1355 , 0350 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
	oPrn:Say(_nLinIni+1395 , 0350 ,aDatSacado[3]                                                ,oFont10)
	oPrn:Say(_nLinIni+1435 , 0350 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
	oPrn:Say(_nLinIni+1475 , 0350 ,aDatSacado[6]                                                ,oFont10)
		
	oPrn:Line(_nLinIni+1550 , 0100 ,_nLinIni+1550 , 2300)
	oPrn:Say(_nLinIni+1550 , 1580 ,"Autenticação Mecânica"                     ,oFont8 )

	For i := 100 to 2300 step 50
		oPrn:Line(_nLinIni+1800 ,i ,_nLinIni+1800 ,i+30)
	Next i

	//-------------------------------------- IMPRESSÃO DA FICHA DE COMPENSAÇÃO 
	// Logotipo canto esq. superior
	_nLinIni := 800

	_sArqLogo := alltrim (see -> ee_logobol)
	if ! empty (_sArqLogo)
		oPrn:SayBitMap (_nLinIni +0600	, ;  // Linha
		100								, ;  // Coluna
		_sArqLogo						, ;  // Arquivo
		450								, ;  // Largura
		80								  )  // Altura
	endif
		
	// Define numero de compensacao a ser impresso em negrito ao lado do logotipo do banco.
	do case
		case _cBcoBol == '041'
			_sNumComp = "041-8"
		otherwise
			u_help ("Sem definicao de numero de compensacao para este banco.")
			return
	endcase

	oPrn:Line(_nLinIni+0700 , 100 ,_nLinIni+0700 , 2300)
	oPrn:Line(_nLinIni+0620 , 550 ,_nLinIni+0700 , 0550)
	oPrn:Line(_nLinIni+0620 , 800 ,_nLinIni+0700 , 0800)

	oPrn:Say( _nLinIni+0620 , 600 , _sNumComp, oFont24)
	oPrn:Say(_nLinIni+0640 ,850 ,CB_RN[2]    ,oFont16n)
	oPrn:Line(_nLinIni+0780 , 0100 , _nLinIni+0780 , 2300)
	oPrn:Line(_nLinIni+0860 , 0100 , _nLinIni+0860 , 2300)
	oPrn:Line(_nLinIni+0930 , 0100 , _nLinIni+0930 , 2300)
	oPrn:Line(_nLinIni+1000 , 0100 , _nLinIni+1000 , 2300)
	
	oPrn:Line(_nLinIni+0860 , 0500 , _nLinIni+0930 , 0500)
	oPrn:Line(_nLinIni+0930 , 0750 , _nLinIni+1000 , 0750)
	oPrn:Line(_nLinIni+0860 , 1000 , _nLinIni+1000 , 1000)
	oPrn:Line(_nLinIni+0860 , 1350 , _nLinIni+0930 , 1350)
	oPrn:Line(_nLinIni+0860 , 1550 , _nLinIni+1000 , 1550)
	
	oPrn:Say(_nLinIni+0705 , 0100 ,"Local de Pagamento"                         			,oFont8 )
	oPrn:Say(_nLinIni+0735 , 0100 ,"PAGÁVEL PREFERENCIALMENTE NA REDE INTEGRADA BANRISUL" 	,oFont10)
	oPrn:Say(_nLinIni+0705 , 1910 ,"Vencimento"                                     		,oFont8 )
	oPrn:Say(_nLinIni+0735 , 2010 ,_Dtoc(aDadosTit[4])                          			,oFont10)		
	oPrn:Say(_nLinIni+0785 , 0100 ,"Beneficiário"                            				,oFont8 )
	oPrn:Say(_nLinIni+0815 , 0100 ,aDadosEmp[1] + '     ' + aDadosEmp[6]    				, oFont10)		
	oPrn:Say(_nLinIni+0785 , 1910 ,"Agência/Código do Beneficiário"                    	,oFont8)		
	
	If _cBcoBol == '041' .and. cNumEmp == '0108'  // dados de agencia/conta do beneficiario da filial 08 - banrisul 
		oPrn:Say(_nLinIni+0815 , 1960 ,"0873 856682386"	,oFont10)
	Else
		oPrn:Say(_nLinIni+0815 , 1960 ,_cAgeBol+"  /  "+_cCtaBol,oFont10)
	EndiF
	
	oPrn:Say(_nLinIni+0865 , 0100 ,"Data do Documento"                         	,oFont8 )
	oPrn:Say(_nLinIni+0895, 0100 ,_DTOC(aDadosTit[2])                          	,oFont10)
	oPrn:Say(_nLinIni+0865 , 0505 ,"Nro.Documento"                             	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 0605 ,aDadosTit[1]                                	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1005 ,"Espécie Doc."                              	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1105 ,"DM"    		                                ,oFont10)
	oPrn:Say(_nLinIni+0865 , 1355 ,"Aceite"                                    	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1455 ,"N" 		                                	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1555 ,"Data do Processamento"                     	,oFont8 )
	oPrn:Say(_nLinIni+0895 , 1655 ,_Dtoc(aDadosTit[7])                         	,oFont10)
	oPrn:Say(_nLinIni+0865 , 1910 ,"Nosso Número"                              	,oFont8 )		
	oPrn:Say(_nLinIni+0895 , 1960 ,aDadosTit[6]                           	    ,oFont10)		
	oPrn:Say(_nLinIni+0935 , 0100 ,"Uso do Banco"                              	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 0755 ,"Espécie"                                   	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 0805 ,GetMv('MV_SIMB1')                            ,oFont10)
	oPrn:Say(_nLinIni+0935 , 1005 ,"Quantidade"                                	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 1555 ,"Valor"                                     	,oFont8 )
	oPrn:Say(_nLinIni+0935 , 1910 ,"(=)Valor do Documento"                     	,oFont8 )
	oPrn:Say(_nLinIni+0965 , 2010 ,Transform(aDadosTit[5],"@E 9,999,999.99")   	,oFont10)
	oPrn:Say(_nLinIni+1005 , 0100 ,"Informações de responsabilidade do beneficiário" ,oFont8 )
	oPrn:Say(_nLinIni+1050 , 0100 ,"COBRAR JUROS DE " + GetMv('MV_SIMB1') + " " + alltrim (transform (Round(aDadosTit [5] * (aDadosTit [8] / 30 / 100),2), "@E 999,999,999.99")) + " AO DIA"		,oFont12)
	oPrn:Say(_nLinIni+1110 , 0100 ,"PROTESTAR " + cvaltochar (GetMv ("VA_PROTBOL")) + " DIAS DO VENCIMENTO",oFont12)
	If aDatSacado[8] > 0
		oPrn:Say(_nLinIni+1170 , 0100 ,"POR OCASIÃO DO PAGAMENTO, ABATER R$ " + Transform(aDatSacado[8],"@EZ 9,999,999.99"),oFont12) // 20220610
	EndIf

	oPrn:Say(_nLinIni+1230 , 0100 ,mv_par10                                 	,oFont12)
	oPrn:Line(_nLinIni+0700 , 1900 ,_nLinIni+1350 , 1900)
	oPrn:Line(_nLinIni+1070 , 1900 ,_nLinIni+1070 , 2300)
	oPrn:Line(_nLinIni+1140 , 1900 ,_nLinIni+1140 , 2300)
	oPrn:Line(_nLinIni+1210 , 1900 ,_nLinIni+1210 , 2300)
	oPrn:Line(_nLinIni+1280 , 1900 ,_nLinIni+1280 , 2300)
	oPrn:Say(_nLinIni+1005 , 1910 ,"(-)Desconto/Abatimento"                    ,oFont8 )
	oPrn:Say(_nLinIni+1035 , 2010 ,Transform(aDatSacado[8],"@EZ 9,999,999.99")   	,oFont10)
	oPrn:Say(_nLinIni+1075 , 1910 ,"(-)Outras Deduções"                        ,oFont8 )
	oPrn:Say(_nLinIni+1145 , 1910 ,"(+)Mora/Multa"                             ,oFont8 )		
	oPrn:Say(_nLinIni+1215 , 1910 ,"(+)Outros Acréscimos"                      ,oFont8 )
	oPrn:Say(_nLinIni+1285 , 1910 ,"(-)Valor Cobrado"                          ,oFont8 )
	oPrn:Line(_nLinIni+1350 , 0100 ,_nLinIni+1350 , 2300)
	oPrn:Say(_nLinIni+1355 , 0100 , "Pagador"                      ,oFont8 )

	oPrn:Say(_nLinIni+1355 , 0350 ,aDatSacado[1]+" ("+aDatSacado[2]+")"+SPACE(15)+aDatSacado[7] ,oFont10)
	oPrn:Say(_nLinIni+1395 , 0350 ,aDatSacado[3]                                                ,oFont10)
	oPrn:Say(_nLinIni+1435 , 0350 ,aDatSacado[4]+" - "+aDatSacado[5]                            ,oFont10)
	oPrn:Say(_nLinIni+1475 , 0350 ,aDatSacado[6]                                                ,oFont10)
		
	oPrn:Line(_nLinIni+1550 , 0100 ,_nLinIni+1550 , 2300)
	
	oPrn:Say(_nLinIni+1550 , 1580 ,"Autenticação Mecânica"                     ,oFont8 )
	oPrn:Say(_nLinIni+1550 , 1910 ,"Ficha de Compensação"                      ,oFont10)

	// Código de barras
	MSBAR("INT25",21.10,1.10,CB_RN[1],oPrn,.F.,,,0.02300,1.2,,,,.F.)

	oPrn:EndPage()       // Finaliza a página
Return
//
// --------------------------------------------------------------------------
// Formata datas com 4 digitos no ano, por que o BB eh enjoadinho.
Static Function _DTOC (_dData)
	local _sRet := strzero (day (_dData), 2) + "/" + strzero (month (_dData), 2) + "/" + strzero (year (_dData), 4)
return _sRet
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("E1_NUM"))
	//                     PERGUNT                   TIPO TAM            DEC          VALID   F3    Opcoes                      Help
	aadd (_aRegsPerg, {01, "Prefixo inicial       ", "C", 3,             0,            "",   "   ", {},                         "Prefixo inicial a ser considerado"})
	aadd (_aRegsPerg, {02, "Prefixo final         ", "C", 3,             0,            "",   "   ", {},                         "Prefixo final a ser considerado"})
	aadd (_aRegsPerg, {03, "Titulo inicial        ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ", {},                         "Numero do titulo inicial a ser impresso"})
	aadd (_aRegsPerg, {04, "Titulo final          ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ", {},                         "Numero do titulo final a ser impresso"})
	aadd (_aRegsPerg, {05, "Banco para emissao    ", "C", 3,             0,            "",   "SEE", {},                         "Codigo do banco para o qual os boletos serao gerados"})
	aadd (_aRegsPerg, {06, "Agencia               ", "C", 5,             0,            "",   "   ", {},                         "Codigo da agencia bancaria"})
	aadd (_aRegsPerg, {07, "Conta                 ", "C", 10,            0,            "",   "   ", {},                         "Numero da conta bancaria"})
	aadd (_aRegsPerg, {08, "Sub-conta             ", "C", 3,             0,            "",   "   ", {},                         "Sub-conta bancaria"})
	aadd (_aRegsPerg, {09, "Tipo de impressora    ", "N", 1,             0,            "",   "   ", {"Jato tinta", "Laser"},    "Tipo de impressora. Deve estar de acordo com a impressora selecionada no Windows."})
	aadd (_aRegsPerg, {10, "Mensagem adicional 1  ", "C", 60,            0,            "",   "   ", {},                         "Mensagem adicional que pode ser impressa na seccao de instrucoes"})
	aadd (_aRegsPerg, {11, "Visualizar / imprimir ", "N", 1,             0,            "",   "   ", {"Visualizar", "Imprimir"}, "Indique se deseja visualizar a impressao em tela ou enviar diretamente para a impressora."})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
