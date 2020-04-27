// Programa:  VA_ZZ9P
// Autor:     Robert Koch
// Data:      30/07/2010
// Descricao: Atualiza precos de compra da uva nas pre-notas.
//
// Historico de alteracoes:
// 09/05/2011 - Robert - Criada possibilidade de precificar por tabelas fixas cfe. tipo de associado.
// 24/08/2012 - Robert - Criado parametro para selecionar qual dos precos deve ser buscado.
//                     - Criado parametro para regravar ou nao os registros com observacoes.
//                     - Criados parametros de filial de... ate.
// 20/05/2014 - Robert - Tratamentos para safra 2014.
//                     - Desabilitadas partes que interferem em grau om decimal.
// 22/04/2015 - Robert - Criado tratamento preco compra viniferas com baixo grau/desclassificadas na serra em 2015.
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 12/03/2016 - Robert - Ajustes para considerar classificacao ABD quando usa tabela de precos fixa (simulacoes 2016).
// 16/04/2016 - Robert - Ajustes safra 2016 para viniferas desclassificadas ou com pouco grau na serra gaucha.
// 19/04/2017 - Robert - Passa a buscar todos os precos na funcao U_PrecoUva(), independente de desclassificacao, etc.
// 26/03/2018 - Robert - Tratamentos para 2018 (mistura de variedades).
// 30/05/2019 - Robert - Tratamentos especificos para cargas em que o grau foi revisto - GPLI 5933
// 18/06/2019 - Robert - Quando nota de complemento, busca o preco da nota de origem e paga apenas a diferenca.
// 24/04/2020 - Robert - Melhorias para safra 2020
//

// --------------------------------------------------------------------------
User Function VA_ZZ9P (_lAuto)
	Local cCadastro := "Atualiza precos de compra da uva nas pre-notas."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	u_logID ()

	Private cPerg   := "VAZZ9P"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo atualizar os precos de compra da uva")
		AADD(aSays,"no arquivo de pre-notas, a partir das tabelas de precos da safra")
		AADD(aSays,"Processo util para os casos de alteracao nos precos apos a geracao das pre-notas.")
		AADD(aSays,"Pre-notas com nota de compra ja gerada nao serao atualizadas.")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _lRet := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _aRetPreco := {}
	local _nPreco    := 0
	local _nPrecoM1  := 0
	local _nPrecoM2  := 0
	local _nPrecoM3  := 0
//	local _sMsg      := ""
//	local _nDecimais := TamSX3 ("ZZ9_VUNIT")[2]
//	local _sProduto  := ""
	local _oSQL      := NIL
	local _sObs      := ''
	local _sMsgNF    := ''
	local _sPrcMist  := ''
//	local _sClasFina := ""
	private _sErros  := ""

	procregua (zz9 -> (reccount ()))

	u_logsx1 ()

	// Atualiza precos de compra das uvas no zz9, baseando-se no sd1 e listas de precos das uvas.
	sb1 -> (dbsetorder (1))
	zz9 -> (dbsetorder (1))  // ZZ9_FILIAL+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_PRODUT+ZZ9_GRAU+ZZ9_CLASSE
	zz9 -> (dbseek (xfilial ("ZZ9") + mv_par05, .T.))
	do while ! zz9 -> (eof ())
		incproc ()
		_nPreco = 0
		if zz9 -> zz9_filial < mv_par11 .or. zz9 -> zz9_filial > mv_par12
			zz9 -> (dbskip ())
			loop
		endif
		if zz9->ZZ9_SAFRA != mv_par05
			zz9 -> (dbskip ())
			loop
		endif
		if ! empty (zz9 -> zz9_nfcomp) .and. mv_par09 != 1
			zz9 -> (dbskip ())
			loop
		endif
		if zz9 -> zz9_vunit != 0 .and. mv_par15 != 1
			zz9 -> (dbskip ())
			loop
		endif
		if zz9 -> zz9_produt < mv_par06 .or. zz9 -> zz9_produt > mv_par07
			zz9 -> (dbskip ())
			loop
		endif
		if zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 .or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04
			zz9 -> (dbskip ())
			loop
		endif
		if ! sb1 -> (dbseek (xfilial ("SB1") + zz9 -> zz9_produt, .F.))
			u_help ("Produto '" + zz9 -> zz9_produt + "' nao cadastrado!")
			zz9 -> (dbskip ())
			loop
		endif
		if mv_par08 == 1 .and. sb1 -> b1_varuva != "C"
			zz9 -> (dbskip ())
			loop
		endif
		if mv_par08 == 2 .and. sb1 -> b1_varuva != "F"
			zz9 -> (dbskip ())
			loop
		endif
		if mv_par10 == 2 .and. ! empty (zz9 -> zz9_obs)
			zz9 -> (dbskip ())
			loop
		endif
		if zz9 -> zz9_parcel < mv_par13 .or. zz9 -> zz9_parcel > mv_par14
			zz9 -> (dbskip ())
			loop
		endif

		u_log (zz9 -> zz9_pre_nf)
		_sObs = ''
		_sMsgNF = ''		

//		// Assume a classificacao da uva vinifera conforme o sistema de conducao.
//		if zz9 -> zz9_conduc == 'L'
//			_sClasFina = zz9 -> zz9_clABD
//		elseif zz9 -> zz9_conduc == 'E'
//			_sClasFina = zz9 -> zz9_classe
//		endif
			
		//		_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, zz9 -> zz9_clabd, 'C', zz9 -> zz9_filial)
		//	_aRetPreco = aclone (U_PrcUva19 (ZZ9 -> ZZ9_FILIAL, zz9 -> zz9_Produt, val (zz9 -> zz9_grau), _sClasFina, zz9 -> zz9_conduc, .F.))

		_aRetPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc)

		_nPreco = _aRetPreco [1]  //[2]
		_sObs += alltrim (_aRetPreco [2])  //[3])
		u_log (zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, _nPreco)
		_nPrecoM1 = 0
		_nPrecoM2 = 0
		_nPrecoM3 = 0
		_sPrcMist = ''
		

		// Quando houver mistura de variedades na carga, precifica pela de menor valor.
		if ! empty (zz9 -> zz9_mistu1)
			_sMsgNF += "Mistura: "
			_sMsgNF += alltrim (zz9 -> zz9_mistu1) + '-' + alltrim (fBuscaCpo ("SB5", 1, xfilial ("SB5") + zz9 -> zz9_mistu1, "B5_CEME"))
//			_nPrecoM1 = u_PrcUva19 (ZZ9 -> ZZ9_FILIAL, zz9 -> zz9_mistu1, val (zz9 -> zz9_grau), _sClasFina, zz9 -> zz9_conduc, .F.) [2]
			_nPrecoM1 = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_mistu1, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			if _nPrecoM1 == 0
				_Erro ('Sem preco para forn:' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja + ' filial:' + zz9 -> zz9_filial + ' prod:' + zz9 -> zz9_mistu1 + '(mistura)' + ' grau:' + zz9 -> zz9_grau + ' clas:' + zz9 -> zz9_classe + ' clas.ABD:' + zz9 -> zz9_clABD)
			endif
		endif
		if ! empty (zz9 -> zz9_mistu2)
			_sMsgNF += ';' + alltrim (zz9 -> zz9_mistu2) + '-' + alltrim (fBuscaCpo ("SB5", 1, xfilial ("SB5") + zz9 -> zz9_mistu2, "B5_CEME"))
//			_nPrecoM2 = u_PrcUva19 (ZZ9 -> ZZ9_FILIAL, zz9 -> zz9_mistu2, val (zz9 -> zz9_grau), _sClasFina, zz9 -> zz9_conduc, .F.) [2]
			_nPrecoM2 = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_mistu2, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			if _nPrecoM2 == 0
				_Erro ('Sem preco para forn:' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja + ' filial:' + zz9 -> zz9_filial + ' prod:' + zz9 -> zz9_mistu2 + '(mistura)' + ' grau:' + zz9 -> zz9_grau + ' clas:' + zz9 -> zz9_classe + ' clas.ABD:' + zz9 -> zz9_clABD)
			endif
		endif
		if ! empty (zz9 -> zz9_mistu3)
			_sMsgNF += ';' + alltrim (zz9 -> zz9_mistu3) + '-' + alltrim (fBuscaCpo ("SB5", 1, xfilial ("SB5") + zz9 -> zz9_mistu3, "B5_CEME"))
//			_nPrecoM3 = u_PrcUva19 (ZZ9 -> ZZ9_FILIAL, zz9 -> zz9_mistu3, val (zz9 -> zz9_grau), _sClasFina, zz9 -> zz9_conduc, .F.) [2]
			_nPrecoM3 = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_mistu3, zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			if _nPrecoM3 == 0
				_Erro ('Sem preco para forn:' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja + ' filial:' + zz9 -> zz9_filial + ' prod:' + zz9 -> zz9_mistu3 + '(mistura)' + ' grau:' + zz9 -> zz9_grau + ' clas:' + zz9 -> zz9_classe + ' clas.ABD:' + zz9 -> zz9_clABD)
			endif
		endif
		if _nPrecoM1 > 0 .and. _nPrecoM1 < _nPreco
			_nPreco = _nPrecoM1
			_sPrcMist = 'Usando prc.de ' + alltrim (zz9 -> zz9_mistu1)
		endif
		if _nPrecoM2 > 0 .and. _nPrecoM2 < _nPreco
			_nPreco = _nPrecoM2
			_sPrcMist = 'Usando prc.de ' + alltrim (zz9 -> zz9_mistu2)
		endif
		if _nPrecoM3 > 0 .and. _nPrecoM3 < _nPreco
			_nPreco = _nPrecoM3
			_sPrcMist = 'Usando prc.de ' + alltrim (zz9 -> zz9_mistu3)
		endif
		if ! empty (_sPrcMist) .and. ! alltrim (_sPrcMist) $ _sMsgNF
			_sMsgNF = alltrim (_sMsgNF) + ';' + _sPrcMist
		endif


		// Tratamentos especificos para cargas que foram feitas com produto errado.
		if zz9 -> zz9_safra == '2018' .and. zz9 -> zz9_filial == '01'
			if zz9 -> zz9_nfentr == '000011876' .and. alltrim (zz9 -> zz9_produt) == '9901'
				_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, '9923           ', zz9 -> zz9_grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, zz9 -> zz9_clabd, 'C', zz9 -> zz9_filial)
				_sMsgNF += ' Produto correto: 9923 (Seibel 2)'
			endif
			if zz9 -> zz9_nfentr == '000012676' .and. alltrim (zz9 -> zz9_produt) == '9901'
				_sMsgNF += ' Produto correto: 9918 (Mosc.Embrapa)'
				_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, '9918           ', zz9 -> zz9_grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, zz9 -> zz9_clabd, 'C', zz9 -> zz9_filial)
			endif
			if zz9 -> zz9_nfentr == '000012811' .and. alltrim (zz9 -> zz9_produt) == '9901'
				_sMsgNF += ' Produto correto: 9923 (Seibel 2)'
				_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, '9923           ', zz9 -> zz9_grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, zz9 -> zz9_clabd, 'C', zz9 -> zz9_filial)
			endif
		endif

		// Tratamentos especificos para cargas em que o grau foi revisto - GPLI 5933
		if zz9 -> zz9_safra == '2019'
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00027401' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000177700005' .and. alltrim (zz9 -> zz9_produt) == '9918' .and. zz9 -> zz9_grau = '14.4'  // Moscato Embrapa de Oscar Crocoli
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 16.4, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '16.4', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00062401' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000178020003' .and. alltrim (zz9 -> zz9_produt) == '9901' .and. zz9 -> zz9_grau = '11.8'  // Isabel de Valderes Pagliosa
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 12.6, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '12.6', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00222901' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000175180001' .and. alltrim (zz9 -> zz9_produt) == '9909' .and. zz9 -> zz9_grau = '11.3'  // Couderc tta de Daniel / Cesar Boff
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 13.2, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '13.2', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00261201' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000179880001' .and. alltrim (zz9 -> zz9_produt) == '9901' .and. zz9 -> zz9_grau = '12.9'  // Isabel de Eliane / Wilham Canalli
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 13.8, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '13.8', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00278501' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000179630004' .and. alltrim (zz9 -> zz9_produt) == '9918' .and. zz9 -> zz9_grau = '12.6'  // Moscato Embrapa de Leonir Mascarello
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 15.0, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '15.0', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00318301' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000180170001' .and. alltrim (zz9 -> zz9_produt) == '9901' .and. zz9 -> zz9_grau = '12.6'  // Isabel de Eliane / Wilham Canalli
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 13.8, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '13.8', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00079301' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000114070001' .and. alltrim (zz9 -> zz9_produt) == '9908' .and. zz9 -> zz9_grau = '13.2'  // Cabernet de Osmar / Dulci Salton
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 14.0, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '14.0', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '09' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00324101' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000026810001' .and. alltrim (zz9 -> zz9_produt) == '9904' .and. zz9 -> zz9_grau = '12.1'  // Niagara bca de Idalino Pan
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 14.0, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '14.0', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
			if zz9 -> zz9_filial == '09' .and. zz9 -> zz9_fornece + zz9 -> zz9_loja == '00324101' .and. ZZ9 -> zz9_nfori + zz9 -> zz9_itemor == '0000026810002' .and. alltrim (zz9 -> zz9_produt) == '9905' .and. zz9 -> zz9_grau = '12.1'  // Niagara bca de Idalino Pan
				u_log ('Precificando com grau revisado')
			//	_nPreco = U_PrcUva19 (zz9 -> zz9_filial, zz9 -> zz9_produt, 14.0, zz9 -> zz9_clabd, zz9 -> zz9_conduc, .F.) [2]
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, zz9 -> zz9_produt, '14.0', zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
			endif
		endif

		// Tratamentos especificos para esta safra
		if zz9 -> zz9_safra == '2020'
			// GLPI 7714: manter A VARIEDADE merlot, mas pagar a preco de isabel
			if zz9 -> zz9_filial == '07' .and. ZZ9 -> ZZ9_FORNEC = '002495' .AND. ALLTRIM (ZZ9 -> ZZ9_PRODUT) == '9917' .AND. ZZ9 -> ZZ9_GRAU = '15.4'
				U_LOG ('Merlot 4100 Kg de Joao Fagherazzi: precificando como isabel.')
				_nPreco = _BuscaPrc (zz9 -> zz9_filial, '9901           ', zz9 -> zz9_grau, zz9 -> zz9_classe, zz9 -> zz9_clabd, zz9 -> zz9_conduc) [1]
				_Obs += 'Varied.correta:isabel(GLPI 7714)'
				_sMsgNF += 'Varied.correta:isabel'
			endif
		endif


		if _nPreco == 0
			_Erro ('Sem preco para forn:' + zz9 -> zz9_fornec + '/' + zz9 -> zz9_loja + ' filial:' + zz9 -> zz9_filial + ' prod:' + zz9 -> zz9_Produt + sb1 -> b1_desc + ' grau:' + zz9 -> zz9_grau + ' clas:' + zz9 -> zz9_classe + ' clas.ABD:' + zz9 -> zz9_clABD)
		endif

		// Se for nota de complemento, devo buscar o preco da nota de origem e pagar apenas a diferenca.
		if zz9 -> zz9_tiponf == 'C'
			u_help ('acho melhor mudar isto aqui: primeiro busca o valor da nota original. Se nao achar, jah dah erro e finaliza. Senao calcula a diferenca.')
			return
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT (PESO_LIQ * " + cvaltochar (_nPreco) + ") - VALOR_TOTAL"
			_oSQL:_sQuery +=  " FROM VA_VNOTAS_SAFRA"
			_oSQL:_sQuery += " WHERE SAFRA      = '" + zz9 -> zz9_safra + "'"
			_oSQL:_sQuery +=   " AND TIPO_NF    = 'C'"
			_oSQL:_sQuery +=   " AND ASSOCIADO  = '" + zz9 -> zz9_fornec + "'"
			_oSQL:_sQuery +=   " AND LOJA_ASSOC = '" + zz9 -> zz9_loja   + "'"
			_oSQL:_sQuery +=   " AND FILIAL     = '" + zz9 -> zz9_filial + "'"
			_oSQL:_sQuery +=   " AND DOC        = '" + zz9 -> zz9_nfori  + "'"
			_oSQL:_sQuery +=   " AND SERIE      = '" + zz9 -> zz9_serior + "'"
			_oSQL:_sQuery +=   " AND ITEM_NOTA  = '" + zz9 -> zz9_itemor + "'"
			_oSQL:Log ()
			_nPreco = _oSQL:RetQry (1, .F.)
		endif

		// u_log ("Safra " + zz9 -> zz9_safra, "Pre-NF:", zz9 -> zz9_pre_nf, "Forn.:",zz9 -> zz9_fornec + "/" + zz9 -> zz9_loja, "Produto/grau/classe:", zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Classe, "Preco anterior:", TRAnsform (zz9->zz9_vunit, "@E 999.9999"), " preco novo:",TRAnsform (_nPreco, "@E 999.9999"), "qt:",trans(zz9->zz9_quant, "@E 99999"))
		reclock ("ZZ9", .F.)
		zz9 -> zz9_vunit = _nPreco
		if ! alltrim (_sObs) $ zz9 -> zz9_obs
			zz9 -> zz9_obs = alltrim (zz9 -> zz9_obs) + ' ' + _sObs
		endif
		if ! alltrim (_sMsgNF) $ zz9 -> zz9_msgNF
			zz9 -> zz9_msgNF = alltrim (zz9 -> zz9_msgNF) + ' ' + _sMsgNF
		endif
		msunlock ()
		zz9 -> (dbskip ())
	enddo

	u_LOG (_sErros)
	if ! empty (_sErros)
		u_help (_sErros)
	endif

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Busca o preco para cada situacao (geralmente a cada safra temos novas regras).
static function _BuscaPrc (_sFilial, _sVaried, _sGrau, _sClEspald, _sClLatada, _sConduc)
	local _aRetPrc   := {0, ''}  // [Preco, observacoes]
	local _sClasFina := ''

	// Assume a classificacao da uva vinifera conforme o sistema de conducao.
	if zz9 -> zz9_conduc == 'L'
		_sClasFina = _sClLatada
	elseif zz9 -> zz9_conduc == 'E'
		_sClasFina = _sClEspald
	endif

	if zz9 -> zz9_safra == '2019'
		_aRetPrc = aclone (U_PrcUva19 (_sFilial, _sVaried, val (_sGrau), _sClasFina, _sConduc, .F.))
	elseif zz9 -> zz9_safra == '2020'
		_aRetPrc = aclone (U_PrcUva20 (_sFilial, _sVaried, val (_sGrau), _sClasFina, _sConduc, .F.))
		
		
		u_log ('to so simulando com preco MOC')
		_aRetPrc [2] = _aRetPrc [5]


	else
		u_help ("Sem tratamento de precificacao para esta safra.",, .t.)
	endif

	// A funcao retorna diferentes valores, mas aqui quero apenas o valor de compra.
	_aRetPrc = {_aRetPrc[2], _aRetPrc [3]}

return _aRetPrc



// --------------------------------------------------------------------------
// Acumula mensagens de erro.
static function _Erro (_sMsg)
	u_log (_sMsg)
	if ! _sMsg $ _sErros
		_sErros += _sMsg + chr (13) + chr (10)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},                         "Codigo do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "   ", {},                         "Loja do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},                         "Codigo do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "   ", {},                         "Loja do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},                         "Safra (ano) a ser processada"})
	aadd (_aRegsPerg, {06, "Variedade (produto) inicial   ", "C", 15, 0,  "",   "SB1", {},                         ""})
	aadd (_aRegsPerg, {07, "Variedade (produto) final     ", "C", 15, 0,  "",   "SB1", {},                         ""})
	aadd (_aRegsPerg, {08, "Tipos de uvas                 ", "N", 1,  0,  "",   "   ", {"Comuns","Finas","Todas"}, ""})
	aadd (_aRegsPerg, {09, "Regrava quando NF ja gerada   ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},             ""})
	aadd (_aRegsPerg, {10, "Pre-NF com observacoes        ", "N", 1,  0,  "",   "   ", {"Regrava","Nao altera"},   ""})
	aadd (_aRegsPerg, {11, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},                         ""})
	aadd (_aRegsPerg, {12, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},                         ""})
	aadd (_aRegsPerg, {13, "Parcela inicial ZZ9           ", "C", 1,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {14, "Parcela final ZZ9             ", "C", 1,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {15, "Regrava quando ja tem preco   ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},             ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
