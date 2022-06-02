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
// 27/03/2020 - Andre   - Adicionada validação para data de entrega não ser menor que data atual.
// 12/04/2021 - Claudia - Validação Centro de Custo X Conta Contábil - GLPI: 9120
// 15/06/2021 - Claudia - Incluida novas validações C.custo X C.contabil. GLPI: 10224
// 15/10/2021 - Claudia - Validação MC da tetra pak. GLPI: 10765
// 21/03/2022 - Claudia - Ajustada a validação de obrigação do centro de custo. GLPI: 11780
// 02/06/2022 - Claudia - Incluida validação de rateio. GLPI: 11937
//
// -----------------------------------------------------------------------------------------------------
User Function MT120LOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted() .and. empty (GDFieldGet("C7_CC"))
		_wtpprod = fBuscaCpo("SB1", 1, xfilial ("SB1") + GDFieldGet("C7_PRODUTO"), 'B1_TIPO' )

		if ! substr(alltrim(GDFieldGet("C7_CONTA")),1,1) $ "4/7"
			_lRet = .T.		// produtos considerados excessao - chamado 
		else 
			If GDFieldGet("C7_RATEIO") == '1'
				_lRet = .T.	// rateio. Chamado GLPI: 11937
			Else
				u_help ("Obrigatório informar centro de custo para este item.")
				_lRet = .F.
			EndIf
		endif				
	endif

	if !empty(GDFieldGet ("C7_CC")) .and. empty(GDFieldGet ("C7_OBS"))
		u_help ("Obrigatório informar a observação para este item.")
		_lRet = .F.
	endif

	if _lRet .and. ! GDDeleted() .and. (GDFieldGet("C7_DATPRF") < DATE()) .and. (GDFieldGet("C7_ENCER") = 'E' )
		U_Help ("Data de entrega não pode ser menor que data atual.")
		_lRet = .F.
	endif

	//validação de Centro de custo X conta contábil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as validações
		_sConta := GDFieldGet("C7_CONTA")
		_sCC    := GDFieldGet("C7_CC")

		if Empty(_sConta) 
			u_help("Conta contábil é obrigatória!")
			_lRet = .F.
		endif

		_sPConta := SubStr( _sConta, 1, 1 )
		if _lRet .and. (_sPConta == '4' .or. _sPConta == '7') .and. empty(_sCC)  // obrigatorio CC
			u_help("Contas iniciadas em 4 e 7 é obrigatório inserir o centro de custo!")
			_lRet = .F.
		endif

		if _lRet .and. (_sPConta == '1' .or. _sPConta == '2') .and. !empty(_sCC)
			u_help("Conta contábil iniciada em 1, não é necessário a informação do centro de custo! Retire o Centro de custo.")
			_lRet = .F.
		endif
			// if !empty(GDFieldGet("C7_CONTA")) .and. !empty(GDFieldGet("C7_CC"))
			// if _lRet .and. alltrim(_sConta) != alltrim(_sCC)
			// 	u_help ("Divergencia no cadastro de Amarração C.Custo X C.Contabil. Grupo C.Custo:" + alltrim(_sCC) + " Grupo C.Contabil:" + alltrim(_sConta))
			// 	_lRet = .F.
			// endif
			//endif
	endif

	// valida a centro de custo X filial
	if _lRet 
		_sCC := GDFieldGet("C7_CC")

		if !empty(_sCC) .and. _sCC <> cFilAnt
			u_help ("Obrigatório informar centro de custo da filial logada!")
			_lRet = .F.
		endif	
	endif

	// verifica item MC que deve ser comprado do fornecedore tetra
	if _lRet .and. ! GDDeleted ()
		_sTpProd  := fBuscaCpo("SB1", 1, xfilial("SB1") + GDFieldGet("C7_PRODUTO"), 'B1_TIPO' )
		_sNomeFor := fBuscaCpo("SA2", 1, xfilial("SA2") + CA120FORN + CA120LOJ, 'A2_NOME')

		if alltrim(_sTpProd) == 'MC' .and. !('TETRA PAK' $ alltrim(_sNomeFor))
			u_help ("Itens do tipo MC devem ser adquiridos do fornecedor Tetra Pak!")
			_lRet = .F.
		endif		
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
Return _lRet
