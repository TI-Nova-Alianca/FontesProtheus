// Programa...: VA_SZON
// Autor......: Robert Koch
// Data.......: 16/07/2008
// Cliente....: Alianca
// Descricao..: Rotina de geracao de ordens de ordens de embarque.
//
// Historico de alteracoes:
// 05/09/2008 - Robert - Ignora notas do varejo (almoxarifado 10)
// 24/10/2008 - Robert - Incluida possibilidade de pegar notas do varejo (alm=10)
// 10/11/2008 - Robert - Incluida possibilidade de pegar notas carregadas em armazem geral.
// 04/03/2009 - Robert - Criados tratamentos para que o armazem geral possa ser representado tambem por fornecedor e nao somente cliente.
// 23/10/2009 - Robert - Passa a usar tabela 03 do ZX5 em lugar da tabela 77 do SX5.
// 05/10/2010 - Robert - Criado tratamento tipo 3 para transportadoras que precisam uma ordem por regiao atendida.
// 06/09/2012 - Elaine - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                       da NF com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 05/08/2019 - Andre  - Alterada tabela SZN para CC2.
//

// --------------------------------------------------------------------------
User Function VA_SZON ()
	Local cCadastro  := "Geracao de ordens de ordens de embarque"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.  // Para controlar se o usuario acessou as perguntas.
	private cPerg    := "VASZON"
//	private _sarqlog := u_nomelog ()

	// Cria as perguntas na tabela SX1
	_validPerg()
	Pergunte(cPerg,.F.)

	AADD(aSays," ")
	AADD(aSays,"Este programa tem como objetivo gerar ordens de embarque para as NF")
	AADD(aSays,"de saida, especifico para a Cooperativa Alianca.")
	AADD(aSays,"")
	AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _BatchTOK() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	FormBatch( cCadastro, aSays, aButtons )
	If nOpca == 1
		processa ({|| _AndaLogo ()})
	EndIf
return



// --------------------------------------------------------------------------
// Verifica 'Tudo OK' do FormBatch.
Static Function _BatchTOK ()
	Local _lRet    := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _sWhere    := ""
	local _sSQL      := ""
	local _sQuery    := ""
	local _sAliasQ1  := ""
	local _sAliasQ2  := ""
	local _nLock     := 0
	local _aCampos   := {}
	local _aArqtrb   := {}  // Para arquivos de trabalho
	local _nQtOrdens := 0
	local _lContinua := .T.
	local _sRegiao   := ""

	// Bloqueia semaforo por que a geracao eh feita em sequencia e nao posso
	// permitir que dois usuarios trabalhem em paralelo, pois gerariam ordens
	// alternadas, causando confusao. Tambem nao podem pegar a mesma nota em
	// diferentes ordens de embarque.
	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		_lContinua = .F.
	endif

	// Se a carga vai ser embarcada em armazem geral e houver mais de um armazem na
	// tabela, abre browse para o usuario selecionar o armazem.
	if _lContinua .and. mv_par17 == 2
		_sQuery := ""
		_sQuery += " select ZX5_03ARMZ"
		_sQuery +=   " from " + RETSQLNAME ("ZX5")
		_sQuery +=  " where D_E_L_E_T_ != '*'"
		_sQuery +=    " and ZX5_TABELA  = '03'"
		_sQuery +=    " and ZX5_FILIAL  = '" + xfilial ("ZX5") + "'"
		_aArmazens = aclone (U_Qry2Array (_sQuery))
		if len (_aArmazens) == 0
			u_help ("Nao foi encontrado nenhum armazem geral no sistema. Verifique tabela 03 das tabelas customizadas (sigaCFG).",, .t.)
			_lContinua = .F.
		else
			_nArmazem = 1  // Se tiver apenas um armazem, jah estah resolvido.
			if len (_aArmazens) > 1
				_nArmazem = U_F3Array (_aArmazens, "Selecione armazem", NIL, NIL, NIL, "Selecione armazem onde sera' feito o carregamento", NIL, .F.)
				if _nArmazem == 0
					_lContinua = .F.
				endif
			endif
		endif
	endif


	if _lContinua
	
		// Gera arquivo de trabalho com as numeracoes previstas das ordens. Sao numeracoes
		// ficticias. Me interessa, por enquanto, apenas gerar ordenadamente, mesmo que
		// tenha numeracao salteada. Mais adiante serah gerada a numeracao definitiva.
		_aCampos = {}
		aadd (_aCampos, {"Numero",     "C", 5,  0})
		aadd (_aCampos, {"F2_TRANSP",  "C", 6,  0})
		aadd (_aCampos, {"F2_CLIENTE", "C", 6,  0})
		aadd (_aCampos, {"F2_LOJA",    "C", 2,  0})
        // 20120919 Elaine Alteracoes NF Alianca
		aadd (_aCampos, {"F2_DOC",     "C", tamsx3 ("F2_DOC")[1],  0})
		aadd (_aCampos, {"F2_SERIE",   "C", 3,  0})
		aadd (_aCampos, {"A1_COD_MUN", "C", 5,  0})
		U_ArqTrb ("Cria", "_trb", _aCampos, {"Numero"}, @_aArqTrb)

		// Monta clausula 'where' com as notas aptas a gerar ordem de embarque.

		_sWhere := ""
		_sWhere += "   From " + RetSQLName ("SF2") + " SF2, "
		_sWhere +=              RetSQLName ("SA4") + " SA4, "
		_sWhere +=              RetSQLName ("SA1") + " SA1  "
		_sWhere += "  Where SF2.D_E_L_E_T_ = ''"
		_sWhere += "    And SA4.D_E_L_E_T_ = ''"
		_sWhere += "    And SA1.D_E_L_E_T_ = ''"
		_sWhere += "    And F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sWhere += "    And A4_FILIAL  = '" + xfilial ("SA4") + "'"
		_sWhere += "    And A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sWhere += "    And A4_COD     = F2_TRANSP"
		_sWhere += "    And A1_COD     = F2_CLIENTE"
		_sWhere += "    And A1_LOJA    = F2_LOJA"
		_sWhere += "    And A1_COD_MUN between '" + mv_par14 + "' and '" + mv_par15 + "'"
		_sWhere += "    And F2_EMISSAO between '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
		_sWhere += "    And F2_CLIENTE between '" + mv_par05 + "' and '" + mv_par07 + "'"
		_sWhere += "    And F2_LOJA    between '" + mv_par06 + "' and '" + mv_par08 + "'"
		_sWhere += "    And F2_EST     between '" + mv_par09 + "' and '" + mv_par10 + "'"
		_sWhere += "    And F2_DOC     between '" + mv_par11 + "' and '" + mv_par12 + "'"
		_sWhere += "    And F2_SERIE   = '" + mv_par13 + "'"
		_sWhere += "    And F2_ORDEMB  = ''"
/*
		_sWhere := ""
		_sWhere +=   " From " + RetSQLName ("SF2") + " SF2, "
		_sWhere +=              RetSQLName ("SA4") + " SA4, "
		_sWhere +=              RetSQLName ("SA1") + " SA1 "
		_sWhere +=  " Where SF2.D_E_L_E_T_ = ''"
		_sWhere +=    " And SA4.D_E_L_E_T_ = ''"
		_sWhere +=    " And SA1.D_E_L_E_T_ = ''"
		_sWhere +=    " And F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sWhere +=    " And A4_FILIAL  = '" + xfilial ("SA4") + "'"
		_sWhere +=    " And A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sWhere +=    " And A4_COD     = F2_TRANSP"
		_sWhere +=    " And A1_COD     = F2_CLIENTE"
		_sWhere +=    " And A1_LOJA    = F2_LOJA"
		_sWhere +=    " And A1_CMUN    between '" + mv_par14 + "' and '" + mv_par15 + "'"
		_sWhere +=    " And F2_EMISSAO between '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
		_sWhere +=    " And F2_CLIENTE between '" + mv_par05 + "' and '" + mv_par07 + "'"
		_sWhere +=    " And F2_LOJA    between '" + mv_par06 + "' and '" + mv_par08 + "'"
		_sWhere +=    " And F2_EST     between '" + mv_par09 + "' and '" + mv_par10 + "'"
		_sWhere +=    " And F2_DOC     between '" + mv_par11 + "' and '" + mv_par12 + "'"
		_sWhere +=    " And F2_SERIE   = '" + mv_par13 + "'"
		_sWhere +=    " And F2_ORDEMB  = ''"
*/		
		if mv_par17 == 2  // Considerar notas carregadas em armazem geral
			_sWhere +=    " And Not Exists (select *"
			_sWhere +=                      " From " + RetSQLName ("SD2") + " SD2 "
			_sWhere +=                     " Where SF2.D_E_L_E_T_ = ''"
			_sWhere +=                       " And D2_FILIAL  = '" + xfilial ("SD2") + "'"
			_sWhere +=                       " And D2_DOC     = F2_DOC"
			_sWhere +=                       " And D2_SERIE   = F2_SERIE"
			_sWhere +=                       " And D2_LOCAL  != '" + alltrim (_aArmazens [_nArmazem, 1]) + "')"
		else
			_sWhere +=    " And Not Exists (select *"
			_sWhere +=                      " From " + RetSQLName ("SD2") + " SD2 "
			_sWhere +=                     " Where SF2.D_E_L_E_T_ = ''"
			_sWhere +=                       " And D2_FILIAL = '" + xfilial ("SD2") + "'"
			_sWhere +=                       " And D2_DOC    = F2_DOC"
			_sWhere +=                       " And D2_SERIE  = F2_SERIE"
			_sWhere +=                       " And D2_LOCAL  in (Select ZX5_03ARMZ"
			_sWhere +=                                           " From " + RetSQLName ("ZX5") + " ZX5 "
			_sWhere +=                                          " Where ZX5.D_E_L_E_T_ = ''"
			_sWhere +=                                            " And ZX5_FILIAL  = '" + xfilial ("ZX5") + "'"
			_sWhere +=                                            " And ZX5_TABELA  = '03'))"

			if mv_par16 == 1  // Considerar notas do varejo / parcialmente do varejo
				_sWhere +=    " And Not Exists (select *"
				_sWhere +=                      " From " + RetSQLName ("SD2") + " SD2 "
				_sWhere +=                     " Where SF2.D_E_L_E_T_ = ''"
				_sWhere +=                       " And D2_FILIAL  = '" + xfilial ("SD2") + "'"
				_sWhere +=                       " And D2_DOC     = F2_DOC"
				_sWhere +=                       " And D2_SERIE   = F2_SERIE"
				_sWhere +=                       " And D2_LOCAL   = '10')"
			endif
		endif

		// Faz uma selecao inicial para obter as transportadoras que participarao desta
		// geracao. Isso por que algumas exigem tratamento diferenciado. Assim, gerarei
		// um loop por transportadora e, internamente, outro loop com as notas.
		_sQuery := ""
		_sQuery += " Select distinct F2_TRANSP, A4_NOME, A4_VAOREMB"
		_sQuery += _sWhere
		_sQuery += " And F2_TRANSP  between '" + mv_par01 + "' and '" + mv_par02 + "'"
		_sQuery += " Order by F2_TRANSP"
		// u_log (_SQUERY)
		_sAliasQ1 = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ1, .f., .t.)
		Do While ! (_sAliasQ1) -> (Eof()) .and. _lContinua
	
			// Limpa arquivo de trabalho (caso tenha sido gerado algo para a transportadora anterior)
			// e gera novas ordens previstas para a transportadora atual.
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				reclock ("_trb", .F.)
				_trb -> (dbdelete ())
				msunlock ()
				_trb -> (dbskip ())
			enddo

			// Busca dados das NF da transportadora atual.
			_sQuery := ""
			_sQuery += " Select F2_EST, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, A1_VAOREMB, A1_COD_MUN, A1_MUN "
//			if (_sAliasQ1) -> a4_vaOrEmb == '3'
//				_sQuery += " ,ISNULL ((SELECT ZZ0_ITEM FROM " + RetSQLName ("ZZ0") + " ZZ0 "
//				_sQuery +=    " WHERE ZZ0.D_E_L_E_T_ = ''"
//				_sQuery +=      " And ZZ0_FILIAL  = '" + xfilial ("ZZ0") + "'"
//				_sQuery +=      " And ZZ0_DESTIN  = SA1.A1_COD_MUN"
//				_sQuery +=      " And ZZ0_TRANSP  = SF2.F2_TRANSP), '') AS REGIAO"
//			endif
			_sQuery += _sWhere
			_sQuery +=    " And F2_TRANSP = '" + (_sAliasQ1) -> f2_transp + "'"
			if (_sAliasQ1) -> a4_vaOrEmb == '1'  // Normal
				_sQuery += "  Order by F2_EST, A1_VAOREMB, F2_CLIENTE, F2_LOJA, F2_DOC"
			elseif (_sAliasQ1) -> a4_vaOrEmb == '2'  // Transportadora exige uma ordem para cada NF
				_sQuery += "  Order by F2_DOC"
			elseif (_sAliasQ1) -> a4_vaOrEmb == '3'  // Uma ordem de carga por regiao atendida.
				_sQuery += "  Order by REGIAO, F2_EST, A1_VAOREMB, F2_CLIENTE, F2_LOJA, F2_DOC"
			else
				alert ("Transportadora " + (_sAliasQ1) -> f2_transp + ": tipo de geracao de ordens nao previsto: '" + (_sAliasQ1) -> a4_vaOrEmb + "'.")
				_lContinua = .F.
			endif
			// u_log (_squery)
			_sAliasQ2 = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ2, .f., .t.)

			// Trata transportadoras conforme modalidade de geracao de ordem de embarque: 1=Todas NF na mesma ordem de embarque;2=Uma NF por ordem de embarque;3=Uma ordem por regiao de atendimento
			if (_sAliasQ1) -> a4_vaOrEmb == '1'  // Normal
				_sNumero = "00001"
				(_sAliasQ2) -> (dbgotop ())
				Do While ! (_sAliasQ2) -> (Eof())
	
					// Controla quebra por estado
					_sEst = (_sAliasQ2) -> f2_est
					Do While ! (_sAliasQ2) -> (Eof()) .and. (_sAliasQ2) -> f2_est == _sEst
	
						// Se for um cliente que nao deve ser misturado com outros, jah avanca a numeracao.
						if (_sAliasQ2) -> a1_vaOrEmb == "2" // 1=Pode juntar com outros clientes na mesma ordem;2=Uma ordem so para este cliente
							_trb -> (dbseek (_sNumero, .T.))
							do while ! _trb -> (eof ()) .and. _trb -> numero == _sNumero
			
								// Verifica se nesta mesma ordem tem algum outro cliente.
								if _trb -> f2_cliente != (_sAliasQ2) -> f2_cliente .or. _trb -> f2_loja != (_sAliasQ2) -> f2_loja
									_sNumero = soma1 (_sNumero)
									exit
								endif
								_trb -> (dbskip ())
							enddo
						endif

						reclock ("_trb", .T.)
						_trb -> numero     = _sNumero
						_trb -> f2_doc     = (_sAliasQ2) -> f2_doc
						_trb -> f2_serie   = (_sAliasQ2) -> f2_serie
						_trb -> f2_cliente = (_sAliasQ2) -> f2_cliente
						_trb -> f2_loja    = (_sAliasQ2) -> f2_loja
						_trb -> f2_transp  = (_sAliasQ1) -> f2_transp
						_trb -> a1_cod_mun = (_sAliasQ2) -> a1_cod_mun
						msunlock ()
	
						(_sAliasQ2) -> (dbskip())
					enddo

					// Ao mudar o estado, cria nova ordem
					_sNumero = soma1 (_sNumero)
				enddo

			elseif (_sAliasQ1) -> a4_vaOrEmb == '2'

				_sNumero = "00001"
				(_sAliasQ2) -> (dbgotop ())
				Do While ! (_sAliasQ2) -> (Eof())
	
					// Controla quebra por nota
					_sNF = (_sAliasQ2) -> f2_doc
					Do While ! (_sAliasQ2) -> (Eof()) .and. (_sAliasQ2) -> f2_doc == _sNF

						reclock ("_trb", .T.)
						_trb -> numero     = _sNumero
						_trb -> f2_doc     = (_sAliasQ2) -> f2_doc
						_trb -> f2_serie   = (_sAliasQ2) -> f2_serie
						_trb -> f2_cliente = (_sAliasQ2) -> f2_cliente
						_trb -> f2_loja    = (_sAliasQ2) -> f2_loja
						_trb -> f2_transp  = (_sAliasQ1) -> f2_transp
						_trb -> a1_cod_mun = (_sAliasQ2) -> a1_cod_mun
						msunlock ()
	
						(_sAliasQ2) -> (dbskip())
					enddo

					// Ao mudar a nota fiscal, cria nova ordem
					_sNumero = soma1 (_sNumero)
				enddo

			elseif (_sAliasQ1) -> a4_vaOrEmb == '3'

				_sNumero = "00001"
				(_sAliasQ2) -> (dbgotop ())
				Do While ! (_sAliasQ2) -> (Eof())
	
					// Controla quebra por regiao de atendimento
					_sRegiao = (_sAliasQ2) -> regiao
					Do While ! (_sAliasQ2) -> (Eof()) .and. (_sAliasQ2) -> regiao == _sRegiao

						// Controla quebra por estado
						_sEst = (_sAliasQ2) -> f2_est
						Do While ! (_sAliasQ2) -> (Eof()) .and. (_sAliasQ2) -> regiao == _sRegiao .and. (_sAliasQ2) -> f2_est == _sEst
	
							// Se for um cliente que nao deve ser misturado com outros, jah avanca a numeracao.
							if (_sAliasQ2) -> a1_vaOrEmb == "2" // 1=Pode juntar com outros clientes na mesma ordem;2=Uma ordem so para este cliente
								_trb -> (dbseek (_sNumero, .T.))
								do while ! _trb -> (eof ()) .and. _trb -> numero == _sNumero
			
									// Verifica se nesta mesma ordem tem algum outro cliente.
									if _trb -> f2_cliente != (_sAliasQ2) -> f2_cliente .or. _trb -> f2_loja != (_sAliasQ2) -> f2_loja
										_sNumero = soma1 (_sNumero)
										exit
									endif
									_trb -> (dbskip ())
								enddo
							endif

							reclock ("_trb", .T.)
							_trb -> numero     = _sNumero
							_trb -> f2_doc     = (_sAliasQ2) -> f2_doc
							_trb -> f2_serie   = (_sAliasQ2) -> f2_serie
							_trb -> f2_cliente = (_sAliasQ2) -> f2_cliente
							_trb -> f2_loja    = (_sAliasQ2) -> f2_loja
							_trb -> f2_transp  = (_sAliasQ1) -> f2_transp
							_trb -> a1_cod_mun = (_sAliasQ2) -> a1_cod_mun
							msunlock ()
		
							(_sAliasQ2) -> (dbskip())
						enddo

						// Ao mudar o estado, cria nova ordem.
						_sNumero = soma1 (_sNumero)
					enddo

					// Ao mudar a regiao de atendimento, cria nova ordem.
					_sNumero = soma1 (_sNumero)
				enddo

			else
				u_help ("Forma de geracao de ordem de embarque desconhecida. Solicite manutencao do programa.")
			endif
			(_sAliasQ2) -> (dbclosearea ())
	

			// Agora que tenho as previsoes de ordens para esta transportadora, jah posso gera-las.
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ()) .and. _lContinua

				_sNumero = GetSXENum ("SZO", "ZO_NUMERO")
				reclock ("SZO", .T.)
				szo -> zo_filial  = xfilial ("SZO")
				szo -> zo_numero  = _sNumero
				szo -> zo_transp  = _trb -> f2_transp
				szo -> zo_emissao = dDataBase
				szo -> zo_usuario = cUserName
				msunlock ()
				do while __lSX8
					ConfirmSX8 ()
				enddo
				_nQtOrdens ++

				// Controla quebra por ordem prevista
				_sNumero = _trb -> numero
				do while ! _trb -> (eof ()) .and. _trb -> numero == _sNumero
					_sSQL := ""
					_sSQL += " Update " + RetSQLName ("SF2")
					_sSQL += "    Set F2_ORDEMB  = '" + szo -> zo_numero + "'"
					_sSQL += "  Where F2_ORDEMB  = ''"
					_sSQL +=    " And F2_SERIE   = '" + _trb -> f2_serie + "'"
					_sSQL +=    " And F2_DOC     = '" + _trb -> f2_doc   + "'"
					_sSQL +=    " And F2_FILIAL  = '" + xfilial ("SF2")  + "'"
					_sSQL +=    " And D_E_L_E_T_ = ''"
					if TCSQLExec (_sSQL) < 0
						u_help ("ERRO na gravacao do numero da ordem nas notas.",, .t.)
						_lContinua = .F.
						exit
					endif
					_trb -> (dbskip ())
				enddo
			enddo

			// Avanca para proxima transportadora.
			(_sAliasQ1) -> (dbskip())
		enddo

	endif

	// Libera semaforo
	U_Semaforo (_nLock)

	U_ArqTrb ("FechaTodos",,,, @_aArqtrb)
	u_help (cvaltochar (_nQtOrdens) + " ordem(s) gerada(s).")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM            DEC          VALID   F3    Opcoes                       Help
	aadd (_aRegsPerg, {01, "Transportadora de             ", "C", 6,              0,           "",   "SA4", {},                           ""})
	aadd (_aRegsPerg, {02, "Transportadora ate            ", "C", 6,              0,           "",   "SA4", {},                           ""})
	aadd (_aRegsPerg, {03, "Data emissao NF de            ", "D", 8,              0,           "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {04, "Data emissao NF ate           ", "D", 8,              0,           "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {05, "Cliente de                    ", "C", 6,              0,           "",   "SA1", {},                           ""})
	aadd (_aRegsPerg, {06, "Loja de                       ", "C", 2,              0,           "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {07, "Cliente ate                   ", "C", 6,              0,           "",   "SA1", {},                           ""})
	aadd (_aRegsPerg, {08, "Loja ate                      ", "C", 2,              0,           "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {09, "Estado de                     ", "C", 2,              0,           "",   "12 ", {},                           ""})
	aadd (_aRegsPerg, {10, "Estado ate                    ", "C", 2,              0,           "",   "12 ", {},                           ""})
	aadd (_aRegsPerg, {11, "NF de                         ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "SF2", {},                           ""})
	aadd (_aRegsPerg, {12, "NF ate                        ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "SF2", {},                           ""})
	aadd (_aRegsPerg, {13, "Serie NF                      ", "C", 3,              0,           "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {14, "Municipio de                  ", "C", 5,              0,           "",   "CC2", {},                           ""})
	aadd (_aRegsPerg, {15, "Municipio ate                 ", "C", 5,              0,           "",   "CC2", {},                           ""})
	aadd (_aRegsPerg, {16, "Incluir NFs do varejo/mistas? ", "N", 1,              0,           "",   "   ", {"Nao", "Sim"},               ""})
	aadd (_aRegsPerg, {17, "Local de carregamento         ", "N", 1,              0,           "",   "   ", {"Alianca", "Armazem geral"}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
