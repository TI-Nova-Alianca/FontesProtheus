// Programa.: MT120LOk
// Autor....: Andre Alves
// Data.....: 25/07/2019
// Funcao...: PE 'Linha OK' na manutencao de pedidos de compra.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE 'Linha OK' na manutencao de pedidos de compra.
// #PalavasChave      #ponto_de_entrada #pedido_de_compra
// #TabelasPrincipais #SC7
// #Modulos           #COM 
//
// Historico de alteracoes:
// 27/03/2020 - Andre   - Adicionada valida��o para data de entrega n�o ser menor que data atual.
// 12/04/2021 - Claudia - Valida��o Centro de Custo X Conta Cont�bil - GLPI: 9120
// 15/06/2021 - Claudia - Incluida novas valida��es C.custo X C.contabil. GLPI: 10224
//
// -----------------------------------------------------------------------------------------------------
User Function MT120LOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("C7_CC"))
		_wtpprod = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C7_PRODUTO"), 'B1_TIPO' )

		if ! substr(alltrim(GDFieldGet ("C1_CONTA")),1,1) $ "4/7"
			_lRet = .T.		// produtos considerados excessao - chamado 
		else 
			u_help ("Obrigat�rio informar centro de custo para este item.")
			_lRet = .F.
		endif				
	endif
	
	if _lRet .and. ! GDDeleted () .and. (GDFieldGet ("C7_DATPRF") < DATE()) .and. (GDFieldGet ("C7_ENCER") = 'E' )
		U_Help ("Data de entrega n�o pode ser menor que data atual.")
		_lRet = .F.
	endif

	//valida��o de Centro de custo X conta cont�bil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as valida��es
		_sConta := GDFieldGet("C7_CONTA")
		_sCC    := GDFieldGet("C7_CC")

		if Empty(_sConta) 
			u_help("Conta cont�bil � obrigat�ria!")
			_lRet = .F.
		endif

		_sPConta := SubStr( _sConta, 1, 1 )
		if _lRet .and. (_sPConta == '4' .or. _sPConta == '7') .and. empty(_sCC)  // obrigatorio CC
			u_help("Contas iniciadas em 4 e 7 � obrigat�rio inserir o centro de custo!")
			_lRet = .F.
		endif

		if _lRet .and. (_sPConta == '1' .or. _sPConta == '2') .and. !empty(_sCC)
			u_help("Conta cont�bil iniciada em 1, n�o � necess�rio a informa��o do centro de custo! Retire o Centro de custo.")
			_lRet = .F.
		endif
			// if !empty(GDFieldGet("C7_CONTA")) .and. !empty(GDFieldGet("C7_CC"))
			// if _lRet .and. alltrim(_sConta) != alltrim(_sCC)
			// 	u_help ("Divergencia no cadastro de Amarra��o C.Custo X C.Contabil. Grupo C.Custo:" + alltrim(_sCC) + " Grupo C.Contabil:" + alltrim(_sConta))
			// 	_lRet = .F.
			// endif
			//endif
	endif

	// valida a centro de custo X filial
	if _lRet 
		_sCC := GDFieldGet("C7_CC")

		if !empty(_sCC) .and. _sCC <> cFilAnt
			u_help ("Obrigat�rio informar centro de custo da filial logada!")
			_lRet = .F.
		endif	
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
Return _lRet
