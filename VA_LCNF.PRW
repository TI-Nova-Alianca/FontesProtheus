// Programa...: VA_LCNF
// Autor......: Robert Koch
// Data.......: 01/10/2010
// Descricao..: Libera recontabilizacao de notas fiscais.
//
// Historico de alteracoes:
// 24/02/2011 - Robert - Implementada recontabilizacao do SE5.
// 06/09/2012 - Elaine - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                       da NF com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 11/06/2014 - Robert - Possibilita selecionar CNAB quando movto. bancario.
// 02/09/2019 - Robert - Criado parametro que possibilita simular antes de executar.
// 02/08/2021 - Robert - Nao considerava param. de numero doc. na filtragem do SE5 (GLPI 10644)
// 04/08/2021 - Robert - Nao tinha tratamento para tabelas FK2 e FK5 (GLPI 10644).
// 08/11/2022 - Robert - Passa a usar a funcao U_AmbTeste().
//

// --------------------------------------------------------------------------
User Function VA_LCNF (_lAuto)
	Local cCadastro := "Libera recontabilizacao de NF / movto.bancario"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private cPerg := "ML_LCNF"
	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	AADD(aSays, "Este programa tem como objetivo limpar o flag de contabilizacao")
	AADD(aSays, "das NF e mov.bancario, permitindo que sejam contabilizados novamente.")
	AADD(aSays, "")
	
	if _lAuto == NIL .or. ! _lAuto
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	else
		Processa( { |lEnd| _Gera() } )
	endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _lRet := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oEvento := NIL
	local _sNick   := ""
	local _nAlter  := 0
	local _sIdFKA  := ''

	procregua (1000)
	U_logSX1 (cPerg)

	do case
	case mv_par01 == 1
		_sNick = "F1_DTDIGIT"
		if U_TemNick ("SF1", _sNick)
			sf1 -> (dbOrderNickName (_sNick))  // F1_FILIAL+DTOS(F1_DTDIGIT)
			sf1 -> (dbseek (xfilial ("SF1") + dtos (mv_par02), .T.))
			do while ! sf1 -> (eof ()) .and. sf1 -> f1_filial == xfilial ("SF1") .and. sf1 -> f1_dtdigit <= mv_par03
				incproc (cvaltochar (sf1 -> f1_dtdigit))
				if sf1 -> f1_doc >= mv_par04 .and. sf1 -> f1_doc <= mv_par05 .and. ! empty (sf1 -> f1_dtlanc)
					if mv_par13 == 2  // Executar
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven   = "SF1010"
						_oEvento:Texto     = "Alterando data contabilizacao de '" + dtoc (sf1 -> f1_dtlanc) + "' para ' / / '"
						_oEvento:NFEntrada = sf1 -> f1_doc
						_oEvento:SerieEntr = sf1 -> f1_serie
						_oEvento:Fornece   = sf1 -> f1_fornece
						_oEvento:LojaFor   = sf1 -> f1_loja
						_oEvento:Grava ()
						reclock ("SF1", .F.)
						sf1 -> f1_dtlanc = ctod ("")
						msunlock ()
					endif
					_nAlter ++
				endif
				sf1 -> (dbskip ())
			enddo
		else
			u_help ("Indice '" + _sNick + "' nao existe.")
		endif

	case mv_par01 == 2
		_sNick = "F2_EMISSAO"
		if U_TemNick ("SF2", _sNick)
			sf2 -> (dbOrderNickName (_sNick))  // f2_FILIAL+DTOS(F2_EMISSAO)
			sf2 -> (dbseek (xfilial ("SF2") + dtos (mv_par02), .T.))
			do while ! sf2 -> (eof ()) .and. sf2 -> f2_filial == xfilial ("SF2") .and. sf2 -> f2_emissao <= mv_par03
				incproc (cvaltochar (sf2 -> f2_emissao))
				if sf2 -> f2_doc >= mv_par04 .and. sf2 -> f2_doc <= mv_par05 .and. ! empty (sf2 -> f2_dtlanc)
					if mv_par13 == 2  // Executar
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven   = "SF2010"
						_oEvento:Texto     = "Alterando data contabilizacao de '" + dtoc (sf2 -> f2_dtlanc) + "' para ' / / '"
						_oEvento:NFSaida   = sf2 -> f2_doc
						_oEvento:SerieSaid = sf2 -> f2_serie
						_oEvento:Cliente   = sf2 -> f2_cliente
						_oEvento:LojaCli   = sf2 -> f2_loja
						_oEvento:Grava ()
						reclock ("SF2", .F.)
						sf2 -> f2_dtlanc = ctod ("")
						msunlock ()
					endif
					_nAlter ++
				endif
				sf2 -> (dbskip ())
			enddo
		else
			u_help ("Indice '" + _sNick + "' nao existe.")
		endif

	case mv_par01 == 3
		se5 -> (dbsetorder (1)) // E5_FILIAL+DTOS(E5_DATA)+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ
		se5 -> (dbseek (xfilial ("SE5") + dtos (mv_par02), .T.))
		do while ! se5 -> (eof ()) .and. se5 -> e5_filial == xfilial ("SE5") .and. se5 -> e5_data <= mv_par03
			incproc (cvaltochar (se5 -> e5_data))
			if alltrim (se5 -> e5_la)   == "S" ;
					.and. se5 -> e5_banco   >= mv_par06 .and. se5 -> e5_banco   <= mv_par07 ;
					.and. se5 -> e5_agencia >= mv_par08 .and. se5 -> e5_agencia <= mv_par09 ;
					.and. se5 -> e5_conta   >= mv_par10 .and. se5 -> e5_conta   <= mv_par11 ;
					.and. se5 -> e5_numero  >= mv_par04 .and. se5 -> e5_numero  <= mv_par05
				if (mv_par12 == 1 .and. empty (se5 -> e5_arqcnab)) .or. (mv_par12 == 2 .and. !empty (se5 -> e5_arqcnab))
					se5 -> (dbskip ())
					loop
				endif
				if mv_par13 == 2  // Executar
				//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
					if ! U_AmbTeste ()
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven   = "SE5001"
						_oEvento:Texto     = "Limpando campo E5_LA"
						_oEvento:Recno     = se5 -> (recno ())
						_oEvento:Alias     = 'SE5'
						_oEvento:CodAlias  = se5 -> e5_prefixo + se5 -> e5_numero + se5 -> e5_parcela
						_oEvento:Grava ()
					endif
					reclock ("SE5", .F.)
					se5 -> e5_la = ""
					msunlock ()
				endif	

				// Se encontrar relacionamento nas novas tabelas do financeiro, limpa tambem.
				if ! empty (se5 -> e5_idorig)
					// PROVAVELMENTE PRECISE FAZER A MESMA COISA NO FK1, MAS NO MOMENTO TO COM PRESSA... ROBERT, 03/08/2021 (GLPI 10644)
					fk2 -> (dbsetorder (1))  // FK2_FILIAL, FK2_IDFK2, R_E_C_N_O_, D_E_L_E_T_
					if fk2 -> (dbseek (xfilial ("FK2") + se5 -> e5_idorig, .F.))
						if mv_par13 == 2  // Executar
							U_Log2 ('debug', 'Encontrei FK2')
						//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
							if ! U_AmbTeste ()
								_oEvento := ClsEvent():new ()
								_oEvento:CodEven   = "FK2001"
								_oEvento:Texto     = "Limpando campo FK2_LA"
								_oEvento:Recno     = fk2 -> (recno ())
								_oEvento:Alias     = 'FK2'
								_oEvento:CodAlias  = fk2 -> fk2_idfk2
								_oEvento:Grava ()
							endif
							reclock ("FK2", .f.)
							fk2 -> fk2_la = ''
							msunlock ()
						endif
					
						fka -> (dbsetorder (3))  // FKA_FILIAL, FKA_TABORI, FKA_IDORIG, R_E_C_N_O_, D_E_L_E_T_
						if fka -> (dbseek (xfilial ("FKA") + 'FK2' + fk2 -> fk2_idfk2, .F.))
							U_Log2 ('debug', 'Encontrei FKA')
							_sIdFKA = fka -> fka_idproc
							fka -> (dbsetorder (2))  // FKA_FILIAL, FKA_IDPROC, FKA_IDORIG, FKA_TABORI, R_E_C_N_O_, D_E_L_E_T_
							fka -> (dbseek (xfilial ("FKA") + _sIdFKA, .T.))
							do while ! fka -> (eof ()) .and. fka -> fka_filial == xfilial ("FKA") .and. fka -> fka_idproc == _sIdFKA
								if fka -> fka_tabori == 'FK5'
									U_Log2 ('debug', 'Procurando FK5 com ID = ' + fka -> fka_idorig)
									fk5 -> (dbsetorder (1))  // FK5_FILIAL, FK5_IDMOV, R_E_C_N_O_, D_E_L_E_T_
									if fk5 -> (dbseek (xfilial ("FK5") + fka -> fka_idorig, .F.))
										U_Log2 ('debug', 'Encontrei FK5')
										if mv_par13 == 2  // Executar
										//	if ! "TESTE" $ upper (GetEnvServer ())  // Por questao de performance
											if ! U_AmbTeste ()
												_oEvento := ClsEvent():new ()
												_oEvento:CodEven   = "FK5001"
												_oEvento:Texto     = "Limpando campo FK5_LA"
												_oEvento:Recno     = fk5 -> (recno ())
												_oEvento:Alias     = 'FK5'
												_oEvento:CodAlias  = fk5 -> fk5_idmov
												_oEvento:Grava ()
											endif
											reclock ("FK5", .f.)
											fk5 -> fk5_la = ''
											msunlock ()
										endif
									endif
								endif
								fka -> (dbskip ())
							enddo
						endif
					endif
				endif
				_nAlter ++
			endif
			se5 -> (dbskip ())
		enddo
	endcase

	u_help ("Processo concluido. " + cvaltochar (_nAlter) + " documento(s) " + iif (mv_par13 == 1, "teria(m) sido ", "") + "alterado(s).")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM           DEC           VALID   F3     Opcoes                                        Help
	aadd (_aRegsPerg, {01, "Recontabilizar o que          ", "N", 1,            0,            "",   "   ",  {"NF Entrada", "NF Saida", "Movto.bancario"}, ""})
	aadd (_aRegsPerg, {02, "Data inicial                  ", "D", 8,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {03, "Data final                    ", "D", 8,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {04, "Nro (docto/NF/titulo) inicial ", "C", _aTamDoc [1], _aTamDoc [2], "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {05, "Nro (docto/NF/titulo) final   ", "C", _aTamDoc [1], _aTamDoc [2], "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {06, "Banco (quando mov.banc)inicial", "C", 3,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {07, "Banco (quando mov.banc)final  ", "C", 3,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {08, "Agen. (quando mov.banc)inicial", "C", 5,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {09, "Agen. (quando mov.banc)final  ", "C", 5,            0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {10, "Conta (quando mov.banc)inicial", "C", 10,           0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {11, "Conta (quando mov.banc)final  ", "C", 10,           0,            "",   "   ",  {},                                           ""})
	aadd (_aRegsPerg, {12, "Apenas CNAB (quando mov.banc) ", "N", 1,            0,            "",   "   ",  {"So CNAB", "Exceto CNAB", "Todos"},          ""})
	aadd (_aRegsPerg, {13, "Simular ou Executar           ", "N", 1,            0,            "",   "   ",  {"Simular", "Executar"},                      ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
