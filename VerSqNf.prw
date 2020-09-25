// Programa...: VerSqNf
// Autor......: Robert Koch
// Descricao..: Impressao de laudos de analises de laboratorio.
// Data.......: 20/04/2008
// Descricao..: Verificacoes sequencia de numeracao da NF.
//              Deve ser chamado antes da emissao da nota.
//
// Historico de alteracoes:
// 01/07/2010 - Robert  - Verifica se a NF anterior (entradas) encontra-se cancelada.
//                      - Grava cliente ou fornecedor no evento, cfe. tipo de nota.
// 18/02/2011 - Robert  - Verificacao de nota jah transmitida para a SEFAZ passada do
//                        P.E. M460Mark para ca.
//                      - Gera avisos via funcao U_Help quando nao tiver interface com o usuario.
// 10/06/2011 - Robert  - Geracao de nota jah existindo notas em datas posteriores passa a exigir liberacao.
// 01/11/2012 - Robert  - Portado parcialmente para SQL
//                      - Ajustes para tamanho de 9 posicoes no numero da nota (saida).
// 14/11/2012 - Robert  - Ajustes para tamanho de 9 posicoes no numero da nota, quando NF de entrada.
// 05/01/2017 - Catia   - estava buscando sempre na serie 10 pra ver se existia a nota 
// 19/10/2017 - Robert  - Evita validar o SF1 contra notas antigas de 6 digitos.
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - parametro em looping
//
// --------------------------------------------------------------------------
user function VerSqNf (_sEntSai, _sSerie, _sNF, _dData, _sCliFor, _sLoja, _sPedVenda, _sProduto, _sTipoNF)
	local _lRet       := .T.
	local _aAreaAnt   := U_ML_SRArea ()
	local _sAviso     := ""
	local _lAntCanc   := .F.
	local _oSQL       := NIL

	//	u_logIni ()

	// Os testes vao pesando mais gradativamente, para evitar o uso de indices extras e filtros.
	//
	// Verifica se estah sendo gerada uma NF no meio da sequencia jah existente (saidas).
	if _lRet .and. _sEntSai == "S"
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_oSQL:_sQuery +=   " AND F2_SERIE   = '" + _sSerie + "'"
		_oSQL:_sQuery +=   " AND F2_DOC    >= '" + _sNF + "'"

		// O teste abaixo foi necessario por causa da existencia de notas anteriores com 6 posicoes
		if cEmpAnt == '01'
			_oSQL:_sQuery +=   " AND len (rtrim (F2_DOC)) = " + cvaltochar (tamsx3 ("F2_DOC") [1])
		endif
		u_log (_oSQL:_sQuery)

		if _oSQL:RetQry (1, .f.) > 0
			if type ("oMainWnd") == "O"  // Se tem interface com o usuario
				if aviso ("Numero NF fora de sequencia", "Ja existe(m) no sistema nota(s) de saida com serie '" + _sSerie + "' e com numeracao igual ou acima da informada. Tem certeza que deseja usar este numero?", {"Sim", "Nao"}) == 1
					_sAviso += " Usuario confirmou geracao de nota mesmo existindo notas com numeracao maior na mesma serie."
				else
					_lRet = .F.
				endif
			else
				u_help ("Ja existe(m) no sistema nota(s) de saida com serie '" + _sSerie + "' e com numeracao igual ou acima da informada.")
				_lRet = .F.
			endif
		endif
	endif

	// Verifica se estah sendo gerada uma NF com data retroativa, com outras posteriores emitidas (saidas).
	if _lRet .and. _sEntSai == "S"
		if U_TemNick ("SF2", "F2_EMISSAO")
			sf2 -> (dbOrderNickName ("F2_EMISSAO"))
			sf2 -> (dbseek (xfilial ("SF2") + dtos (_dData + 1), .T.))
			
			_MainWnd := type ("oMainWnd")
			
			do while ! sf2 -> (eof ()) .and. sf2 -> f2_filial == xfilial ("SF2") .and. sf2 -> f2_emissao > _dData
				if sf2 -> f2_serie == _sSerie
					//if type ("oMainWnd") == "O"  // Se tem interface com o usuario
					If alltrim(_MainWnd) == "O"  // Se tem interface com o usuario
						if aviso ("Numero NF fora de sequencia", "Ja existe(m) no sistema nota(s) de saida da serie '" + _sSerie + "' com data de emissao maior que a data informada. Tem certeza que deseja usar este numero?", {"Sim", "Nao"}) == 1
							if _Libera ()
								_sAviso += " Usuario confirmou a geracao de NF mesmo com outra(s) existentes em datas posteriores."
							else
								_lRet = .F.
							endif
						else
							_lRet = .F.
						endif
					else
						u_help ("Ja existe(m) no sistema nota(s) de saida da serie '" + _sSerie + "' com data de emissao maior que a data informada.")
						_lRet = .F.
					endif
					exit
				endif
				sf2 -> (dbskip ())
			enddo
		endif
	endif

	if _lRet .and. _sEntSai == "E"
		dbselectarea ("SF1")
//		set filter to &('F1_FILIAL=="' + xFilial("SF1") + '".And.F1_formul=="S".and.f1_serie=="' + _sSerie + '"')
                                   
		//u_log("Dentro if nota de entrada a testar se já existe NF no meio da sequencia")
		// Verifica se estah sendo gerada uma NF no meio da sequencia jah existente (entradas).
		if _lRet
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT COUNT (*)"
			_oSQL:_sQuery += " FROM " + RetSQLName ("SF1") + " SF1 "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND F1_FILIAL  = '" + xfilial ("SF1") + "'"
			_oSQL:_sQuery +=   " AND F1_SERIE   = '" + _sSerie + "'"
			_oSQL:_sQuery +=   " AND F1_DOC    >= '" + _sNF + "'"
			_oSQL:_sQuery +=   " AND len (F1_DOC) = 9"  // Para evitar validar contra notas antigas de 6 digitos.
			_oSQL:_sQuery +=   " AND F1_FORMUL  = 'S' "
	
			// O teste abaixo foi necessario por causa da existencia de notas anteriores com 6 posicoes
			if cEmpAnt == '01'
				_oSQL:_sQuery +=   " AND len (rtrim (F1_DOC)) = " + cvaltochar (tamsx3 ("F1_DOC") [1])
			endif

            //u_log("Query do Teste")
			//u_log (_oSQL:_sQuery)
	
			if _oSQL:RetQry (1, .f.) > 0
				if type ("oMainWnd") == "O"  // Se tem interface com o usuario
					if aviso ("Numero NF fora de sequencia", "Ja existe(m) no sistema nota(s) de entrada com serie '" + _sSerie + "' e com numeracao igual ou acima da informada. Tem certeza que deseja usar este numero?", {"Sim", "Nao"}) == 1
						_sAviso += " Usuario confirmou geracao de nota mesmo existindo notas com numeracao maior na mesma serie."
                       u_log("if aviso nf fora de seq ")
					else
                        u_log("else do aviso nf fora de seq ")
						_lRet = .F.
					endif
				else
					u_help ("Ja existe(m) no sistema nota(s) de entrada com serie '" + _sSerie + "' e com numeracao igual ou acima da informada.")
					_lRet = .F.
				endif
			endif
		endif

		// Verifica se estah sendo gerada uma NF com data retroativa, com outras posteriores jah emitidas (entradas).
		if _lRet
			if U_TemNick ("SF1", "F1_EMISSAO")
				sf1 -> (dbOrderNickName ("F1_EMISSAO"))
				sf1 -> (dbseek (xfilial ("SF1") + dtos (_dData + 1), .T.))
				_MainWnd := type ("oMainWnd")
				
				do while ! sf1 -> (eof ()) .and. sf1 -> f1_filial == xfilial ("SF1") .and. sf1 -> f1_emissao > _dData
					if sf1 -> f1_serie == _sSerie
						// if type ("oMainWnd") == "O"  // Se tem interface com o usuario
						if alltrim(_MainWnd) == "O"  // Se tem interface com o usuario

							if aviso ("Numero NF fora de sequencia", "Ja existe(m) no sistema nota(s) da serie '" + _sSerie + "' com data de emissao maior que a data informada. Tem certeza que deseja usar este numero?", {"Sim", "Nao"}) == 1
								_sAviso += " Usuario confirmou a geracao de NF mesmo com outra(s) existentes em datas posteriores."
							else
								_lRet = .F.
							endif
						else
							u_help ("Ja existe(m) no sistema nota(s) da serie '" + _sSerie + "' com data de emissao maior que a data informada.")

							_lRet = .F.
						endif
						exit
					endif
					sf1 -> (dbskip ())
				enddo
			endif
		endif
		dbselectarea ("SF1")
 //		set filter to
	endif

	// Verifica se estah sendo deixada lacuna na numeracao.
	if _lRet .and. _sEntSai == "S"
		if val (_sNF) > 1  // Se nao for a primeira nota desta serie
			sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL
			
			// Se nao achar a NF anterior nas saidas...
			if ! sf2 -> (dbseek (xfilial ("SF2") + Tira1 (_sNF) + _sSerie, .F.))

				// ... verifica se estah cancelada.
				sf3 -> (dbsetorder (5))  // F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT
				if sf3 -> (dbseek (xfilial ("SF3") + _sSerie + Tira1 (_sNF), .F.)) .and. ! empty (sf3 -> f3_dtcanc)
					_lAntCanc = .T.
				endif

				// Se nao estava cancelada, tenta nas entradas
				if ! _lAntCanc
					sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
					if ! sf1 -> (dbseek (xfilial ("SF1") + Tira1 (_sNF) + _sSerie, .T.))
						if type ("oMainWnd") == "O"  // Se tem interface com o usuario
							if aviso ("Numero NF fora de sequencia", "Nao foi encontrada na serie '" + _sSerie + "' a NF anterior `a nota(s) informada. Esta movimentacao deixaria uma lacuna na sequencia de notas. Tem certeza que deseja usar este numero?", {"Sim", "Nao"}) == 1
								_sAviso += " Usuario confirmou geracao de nota mesmo deixando lacuna na numeracao."
							else
								_lRet = .F.
							endif
						else
							u_help ("Nao foi encontrada na serie '" + _sSerie + "' a NF anterior `a nota(s) informada. Esta movimentacao deixaria uma lacuna na sequencia de notas.")
							_lRet = .F.
						endif
					endif
				endif
			endif
		endif
	endif

	// Verifica geracao de NF eletronica com numeracao jah existente na SEFAZ
	if _lRet
		_lRet = _VerSEFAZ (_sSerie, _sNF)
	endif

	if ! empty (_sAviso)
		_oEvento := ClsEvent():new ()
		_oEvento:Texto     = _sAviso
		_oEvento:Produto   = _sProduto
		//_oEvento:MailTo    = "liane.lenzi@novaalianca.coop.br"
		_oEvento:MailToZZU   = {'050'}
		if _sEntSai == "S"
			_oEvento:CodEven   = "SF2008"
			_oEvento:NFSaida   = _sNF
			_oEvento:SerieSaid = _sSerie
			if _sTipoNF $ "BD"
				_oEvento:Fornece   = _sCliFor
				_oEvento:LojaFor   = _sLoja
			else
				_oEvento:Cliente   = _sCliFor
				_oEvento:LojaCli   = _sLoja
			endif
			_oEvento:PedVenda  = _sPedVenda
		else
			_oEvento:CodEven   = "SF1001"
			_oEvento:NFEntrada = _sNF
			_oEvento:SerieEntr = _sSerie
			if _sTipoNF $ "BD"
				_oEvento:Cliente   = _sCliFor
				_oEvento:LojaCli   = _sLoja
			else
				_oEvento:Fornece   = _sCliFor
				_oEvento:LojaFor   = _sLoja
			endif
		endif
		_oEvento:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)

//	u_log ('retornando', _lRet)
//	u_logFim ()
return _lRet
// --------------------------------------------------------------------------
// Verifica geracao de NF eletronica com numeracao jah existente na SEFAZ
static function _VerSEFAZ (_sSerie, _sNF)
	Local cURL       := PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
	Local oWS        := NIL
	local _lRet      := .T.
	local _sEntidade := ""
	local _sProtEmis := ""
	local _sProtCanc := ""
	local _sXML      := ""
	local nX		 := 0

	// Determina entidade cfe. jah consultado na tabela SPED001B via SQL.
	_sEntidade := U_RetSQL ("SELECT ID_ENT FROM SPED001 WHERE CNPJ = '" + sm0 -> m0_cgc + "' AND D_E_L_E_T_ = ''")
	if empty (_sEntidade)
		U_AvisaTI ("Estah sendo gerada NF na emp/fil '" + cNumEmp + "' e nao sei qual a entidade dela no SPED, entao nao consigo fazer as verificacoes para NF-e.")
	else
		oWS:= WSNFeSBRA():New()
		oWS:cUSERTOKEN        := "TOTVS"
		oWS:cID_ENT           := _sEntidade
		oWS:oWSNFEID          := NFESBRA_NFES2():New()
		oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
		aadd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
		Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := _sSerie + _sNF

		oWS:nDIASPARAEXCLUSAO := 0
		oWS:_URL := AllTrim(cURL)+"/NFeSBRA.apw"
		If oWS:RETORNANOTAS()
	
			// Precisa ler toda a array por que o mesmo numero de nota pode retornar
			// em producao/homologacao, ou em modo normal/contingencia
			_MainWnd := type ("oMainWnd")
			For nX := 1 To Len(oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3)
				if valtype (oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE) == "O"
					_sProtEmis = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CPROTOCOLO
				endif
				if valtype (oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFECANCELADA) == "O"
					_sProtCanc = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFECANCELADA:CPROTOCOLO
				endif
				
				// Se tem autorizacao para emissao ou para cancelamento...
				if ! empty (_sProtEmis) .or. ! empty (_sProtCanc)

					_sXml = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CXML

					if at ("<tpAmb>1</tpAmb>", _sXml) > 0  // Ambiente: 1=producao, 2=homologacao
						if __cUserId != "000000"
							u_help ("INCLUSAO DE NOTA NAO PERMITIDA." + chr (13) + chr (10) + chr (13) + chr (10) + "Numero de NF '" + _sNF + "': " + iif (! empty (_sProtEmis), "emissao ja' autorizada", "cancelamento ja' autorizado") + " pela SEFAZ. Somente o ADMINISTRADOR podera' reutiliza-lo em casos especiais.")

							_lRet = .F.
							exit
						else
							//if type ("oMainWnd") == "O"  // Se tem interface com o usuario
							If alltrim(_MainWnd) == "O"  // Se tem interface com o usuario
								_lRet = msgnoyes ("Numero de NF '" + _sNF + "': " + iif (! empty (_sProtEmis), "emissao ja' autorizada", "cancelamento ja' autorizado") + " pela SEFAZ. Deseja gerar assim mesmo?")
							else
								u_help ("Numero de NF '" + _sNF + "': " + iif (! empty (_sProtEmis), "emissao ja' autorizada", "cancelamento ja' autorizado") + " pela SEFAZ.")
								_lRet = .F.
							endif
							exit
						endif
					endif
				endif
			Next nX
		EndIf
	endif
//	u_log ('retornando', _lRet)
//	u_logFim ()
Return _lRet
// --------------------------------------------------------------------------
// Exige liberacao via senha.
static function _Libera ()
	local _lRet := .F.
	
	_lRet = U_ZZUVL ('050', __cUserId, .T., cEmpAnt, cFilAnt)
	
return _lRet //_aLiber [1]
