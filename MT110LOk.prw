// Programa: MT110LOk
// Autor:    Robert Koch
// Data:     30/12/2008
// Funcao:   PE 'Linha OK' na manutencao de solicitacoes de compra.
//           Criado inicialmente para validacao de justificativa de encaminhamento.
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
// 12/01/2018 - Catia  - Desobrigatoriedade de centro de custo para tipos 'MM' - pois os itens da manutenção passam a gerar estoque
// 07/02/2018 - Catia  - Tratamentos para produtos que sao considerados excessao dentros do tipo GG
// 07/02/2018 - Catia  - Desabilitado o teste no campo C1_VAOBRA que foi tirado de uso e da tela
// 21/03/2018 - Catia  - Incluido mais itens GG para serem tratados como exceção nao sendo obrigada a digitar o centro de custo nas contas transitorias
// 26/11/2018 - Sandra - Validação campo C1_DATPRF para não aceitar data menor que a data base.
// 12/12/2018 - Andre/Sandra - valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
// 23/04/2019 - Catia/Sandra - ajustes na validação data de necessidade
// 01/07/2019 - Andre        - tirado tipo de produto MM
// 01/07/2019 - Andre        - Criado parametro VA_GRPSB1 contendo grupos de produto.
// ----------------------------------------------------------------------------------------------------------------------------------------------------
user function mt110lok ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
//	local _lUsaRat  := .F.

	if _lRet .and. ! GDDeleted () .and. GDFieldGet ("C1_VAENCAM") == "S"
		if _lRet .and. empty (GDFieldGet ("C1_VAJENC"))
			msgalert ("Solicitacoes ja' encaminhadas devem ter justificativa para o encaminhamento.")
			_lRet = .F.
		endif
		if _lRet .and. GDFieldGet ("C1_VAVLUNI") == 0
			msgalert ("Solicitacoes ja' encaminhadas devem ter valor informado.")
			_lRet = .F.
		endif
	endif
	

	// valida a centro de custo e o campo destino para as peças - itens 7117 e 7017
	if _lRet .and. ! GDDeleted ()
		if GDFieldGet ("C1_PRODUTO") = '7117' .or. GDFieldGet ("C1_PRODUTO") = '7017'
			if empty(GDFieldGet ("C1_CC"))
				msgalert ("Obrigatório informar centro de custo para solicitação de pecas.")
				_lRet = .F.
			endif
			if _lRet .and. empty(GDFieldGet ("C1_VADESTI"))
				msgalert ("Obrigatório informar o equipamento no destino")
				_lRet = .F.
			endif
		endif			
	endif
	
	// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("C1_CC"))
		_wtpprod = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C1_PRODUTO"), 'B1_TIPO' )
		//if ! _wtpprod $ 'MR/MP/PS/ME/PP/PI/VD/PA/SP/MA/UC/EP/ML/MX/MB/MT/CL/II'
		//if ! _wtpprod $ GetMV ("VA_GRPSB1")
			//if _wtpprod = 'GG' .and. alltrim(GDFieldGet ("C1_PRODUTO")) $'7103/7110/7082/7087/7066/7159/7012/7013/7050/7048/7122/7061'
			if ! substr(alltrim(GDFieldGet ("C1_CONTA")),1,1) $ "4/7"
				// produtos considerados excessao - chamado 
				_lRet = .T.	
			else 
				msgalert ("Obrigatório informar centro de custo para este item.")
				_lRet = .F.
			endif				
		//endif
	endif


	// valida data de necessidade que obrigatoriamente tem que ser maior ou igual a data do sistema
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("C1_DATPRF"))
		if dtos(GDFieldGet ("C1_DATPRF")) < dtos( DATE() )
		 	msgalert ("Data de necessidade deve ser obrigatóriamente maior ou igual a data de digitação da solicitação.")
			_lRet = .F.
		endif
	endif
	// Valida o cadastro produto x fornecedor
/*	if ! empty (GDFieldGet ("C1_FORNECE")) .and. empty (GDFieldGet ("C1_CODPRF")) 
	/*	msgalert ("Preencher cadastro Produto x Fornecedor - Entrar em contato com departamento de Compras") 
		_lRet = .F.
	endif  
*/	
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet
