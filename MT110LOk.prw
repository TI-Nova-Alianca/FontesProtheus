// Programa.: MT110LOk
// Autor....: Robert Koch
// Data.....: 30/12/2008
// Funcao...: PE 'Linha OK' na manutencao de solicitacoes de compra.
//            Criado inicialmente para validacao de justificativa de encaminhamento.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE 'Linha OK' na manutencao de solicitacoes de compra.
// #PalavasChave      #ponto_de_entrada #solicitacao_de_compra #linha_OK
// #TabelasPrincipais #SC1 
// #Modulos           #COM 
//
// Historico de alteracoes:
//
// 07/01/2009 - Robert - Solicitacoes jah encaminhadas devem ter valor informado.
// 28/05/2012 - Robert - Valida preenchimento do campo C1_VAOBRA.
// 07/05/2015 - Catia  - Validacao de peças - obrigar que informe centro de custo e destino
// 11/11/2015 - Catia  - Obrigar digitação de centros de custos para itens que nao sejam ME, MP e PS
// 03/12/2015 - Robert - Validacoes de CC com campo B1_VARATEI.
// 30/09/2016 - Robert - Desobrigatoriedade de centro de custo para tipos 'MR/ME/PS/MP/VD/EP/PI/VD/PA/SP/MA/CL/II'
// 08/12/2016 - Catia  - Alterado os tipos de produtos que nao obrigam centro de custo
// 12/01/2018 - Catia  - Desobrigatoriedade de centro de custo para tipos 'MM' - pois os itens da manutenção 
//                       passam a gerar estoque
// 07/02/2018 - Catia  - Tratamentos para produtos que sao considerados excessao dentros do tipo GG
// 07/02/2018 - Catia  - Desabilitado o teste no campo C1_VAOBRA que foi tirado de uso e da tela
// 21/03/2018 - Catia  - Incluido mais itens GG para serem tratados como exceção nao sendo obrigada a digitar 
//                       o centro de custo nas contas transitorias
// 26/11/2018 - Sandra - Validação campo C1_DATPRF para não aceitar data menor que a data base.
// 12/12/2018 - Andre/Sandra - valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
// 23/04/2019 - Catia/Sandra - ajustes na validação data de necessidade
// 01/07/2019 - Andre   - tirado tipo de produto MM
// 01/07/2019 - Andre   - Criado parametro VA_GRPSB1 contendo grupos de produto.
// 03/05/2021 - Claudia - Validação de centro de custo X filial. GLPI 9945
// 15/06/2021 - Claudia - Incluida novas validações C.custo X C.contabil. GLPI: 10224
// 13/09/2021 - Robert  - Valida B1_TIPO MM/MC x grupo 131 (GLPI 10651).
//

// ----------------------------------------------------------------------------------------------------------------------------
user function mt110lok ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	// Deixa o SB1 posicionado para validacoes posteriores.
	sb1 -> (dbsetorder (1))
	if ! sb1 -> (dbseek (xfilial ("SB1") + GDFieldGet ("C1_PRODUTO"), .F.))
		u_help ("Produto '" + GDFieldGet ("C1_PRODUTO") + "' nao encontrado no cadastro!")
		_lRet = .F.
	endif

	if _lRet .and. ! GDDeleted () .and. GDFieldGet ("C1_VAENCAM") == "S"
		if _lRet .and. empty (GDFieldGet ("C1_VAJENC"))
			u_help ("Solicitacoes ja' encaminhadas devem ter justificativa para o encaminhamento.")
			_lRet = .F.
		endif
		if _lRet .and. GDFieldGet ("C1_VAVLUNI") == 0
			u_help ("Solicitacoes ja' encaminhadas devem ter valor informado.")
			_lRet = .F.
		endif
	endif

	// valida a centro de custo e o campo destino para as peças - itens 7117 e 7017
	if _lRet .and. ! GDDeleted ()
		if GDFieldGet ("C1_PRODUTO") = '7117' .or. GDFieldGet ("C1_PRODUTO") = '7017'
			if empty(GDFieldGet ("C1_CC"))
				u_help ("Obrigatório informar centro de custo para solicitação de pecas.")
				_lRet = .F.
			endif
			if _lRet .and. empty(GDFieldGet ("C1_VADESTI"))
				u_help ("Obrigatório informar o equipamento no destino")
				_lRet = .F.
			endif
		endif			
	endif
	
	// valida a centro de custo X filial
	if _lRet .and. ! GDDeleted ()
		_sCC := SUBSTRING(alltrim(GDFieldGet ("C1_CC")), 1, 2)    
		if !empty(_sCC) .and. _sCC <> cFilAnt
			u_help ("Obrigatório informar centro de custo da filial logada!")
			_lRet = .F.
		endif		
	endif

	// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("C1_CC"))
		_wtpprod = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C1_PRODUTO"), 'B1_TIPO' )
		if ! substr(alltrim(GDFieldGet ("C1_CONTA")),1,1) $ "4/7"
			// produtos considerados excessao - chamado 
			_lRet = .T.	
		else 
			u_help ("Obrigatório informar centro de custo para este item.")
			_lRet = .F.
		endif
	endif


	// valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("C1_DATPRF"))
		if dtos(GDFieldGet ("C1_DATPRF")) < dtos( DATE() )
		 	u_help ("Data de necessidade deve ser obrigatóriamente maior ou igual a data de digitação da solicitação.")
			_lRet = .F.
		endif
	endif

	// realiza a validação de amarração centro de custo x conta contábil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as validações
		_sConta := GDFieldGet("C1_CONTA")
		_sCC    := GDFieldGet("C1_CC")

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
	endif

	// Valida se o usuario pode solicitar compra deste tipo de material.
	if _lRet .and. ! GDDeleted ()
		if sb1 -> b1_tipo $ 'MC/MM'
			if ! U_ZZUVL ('131', __cUserID, .T.)
				u_help ("Solicitacao de compra de itens tipo '" + sb1 -> b1_tipo + "' restrita ao pessoal de manutencao e relacionados.")
				_lRet = .F.
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet
