// Programa..: MT110TOK	
// Autor.....: Catia Cardoso
// Data......: 23/04/2019
// Funcao....: PE 'tudo OK' na manutencao de solicitacoes de compra.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE 'tudo OK' na manutencao de solicitacoes de compra.
// #PalavasChave      #ponto_de_entrada #solicitacao_de_compra
// #TabelasPrincipais #SC1 
// #Modulos           #COM 
//
// Historico de alteracoes:
// 24/04/2019 - Catia   - Testar data de necessidade 
// 22/03/2021 - Robert  - Teste com empty () do C1_DATPRF estava desconsiderando a variavel _nLinha.
// 12/04/2021 - Claudia - Validação Centro de Custo X Conta Contábil - GLPI: 9120
// 03/05/2021 - Claudia - Validação de centro de custo X filial. GLPI 9945
// 02/06/2021 - Claudia - Validação de centro de custo x filial apenas para quando for informado o CC.
// 15/06/2021 - Claudia - Incluida novas validações C.custo X C.contabil. GLPI: 10224
//
// -----------------------------------------------------------------------------------------------------
User Function MT110TOK ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _nLinha	:= 0
	
	For _nLinha := 1 to Len(aCols)
		// valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
		// if ! empty (GDFieldGet ("C1_DATPRF"), _nLinha)
		if ! empty (GDFieldGet ("C1_DATPRF", _nLinha))
			if  ! GDDeleted (_nLinha) 
				if dtos(GDFieldGet ("C1_DATPRF", _nLinha) ) < dtos( DATE() )
					u_help ("Data de necessidade deve ser obrigatoriamente maior ou igual a data de digitação da solicitação.")
					_lRet = .F.
					exit
				endif	
			endif
		endif
	next	

	// realiza a validação de amarração centro de custo x conta contábil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as validações
		for _nLinha := 1 to Len(aCols)
			_sConta := GDFieldGet("C1_CONTA", _nLinha)
			_sCC    := GDFieldGet("C1_CC"   , _nLinha)

			if empty(_sConta)
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
			// _sConta := U_VA_CUSXCON(GDFieldGet("C1_CONTA", _nLinha),'1')
			// _sCC    := U_VA_CUSXCON(GDFieldGet("C1_CC"   , _nLinha),'2')
			// if !empty(GDFieldGet("C1_CC"   , _nLinha)) .and. !empty(GDFieldGet("C1_CONTA", _nLinha))
			// if _lRet .and. alltrim(_sConta) != alltrim(_sCC)
			// 	u_help ("Divergencia no cadastro de Amarração C.Custo X C.Contabil. Grupo C.Custo:" + alltrim(_sCC) + " Grupo C.Contabil:" + alltrim(_sConta))
			// 	_lRet = .F.
			// endif
			//endif
		next	
	endif
	
	// valida a centro de custo X filial
	if _lRet 
		for _nLinha := 1 to Len(aCols)
			_sCC := SUBSTRING(alltrim(GDFieldGet("C1_CC", _nLinha)), 1, 2)

			if !empty(_sCC) .and. _sCC <> cFilAnt
				u_help ("Obrigatório informar centro de custo da filial logada!")
				_lRet = .F.
			endif	
		next	
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
Return _lRet
