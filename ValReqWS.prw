// Programa:  ValReqWS
// Autor:     Robert Koch
// Data:      10/05/2019
// Descricao: Validacoes basicas de requisicoes recebidas por web service.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
// Converte string recebida para XML.
user function ValReqWS (_sOrigem, _sXmlOri, _sErros, _sWS_Empr, _sWS_Filia, _sAcao)
	local _sUTF8     := ""
	local _sError    := ""
	local _sWarning  := ""
	local _sUser     := ""
	local _aUsers    := {}
	local _nUser     := 0
	local _aPswRet   := {}
//	local _sDocZAG   := ''
//	local _oSQL      := NIL

	u_log2 ('debug', 'XML recebido: ' + _sXmlOri)

	if empty (_sErros) .and. empty (_sOrigem)
		_sErros += "Origem da conexao nao identificada"
	endif
	if empty (_sErros) .and. empty (_sXmlOri)
		_sErros += "Recebido XML vazio"
	endif

	if empty (_sErros)

		// Converte para conjunto de caracteres padrao (remove letras acentuadas, etc.).
		_sUTF8 = EncodeUTF8 (_sXMLOri)
		if ! empty (_sUTF8)

			// Em alguns casos a conversao para UTF-8 aparecem caracteres especiais no inicio da string...
			if upper (substr (_sUTF8, 7, 1)) == '<'
				_sUTF8 = substring (_sUTF8, 7, len (_sUTF8))
			endif
			_sXMLOri = _sUTF8
		endif

		// Cria objeto XML para leitura dos dados.
		_oXML := XmlParser(_sXMLOri, "_", @_sError, @_sWarning )
		If !Empty (_sError)
			_sErros  += "CONTEUDO XML INVALIDO - Error: " + _sError
		EndIf
		If !Empty (_sWarning)
			_sErros  += "CONTEUDO XML INVALIDO - Warning: " + _sWarning
		EndIf
	endif

	if empty (_sErros)
		_ExtraiTag ("_oXML:_WSAlianca", .T.)  // Para ver se consta a tag
	endif
	if empty (_sErros)
		_sWS_Empr  = _ExtraiTag ("_oXML:_WSAlianca:_Empresa", .T.)
	endif
/*
	// Em caso de liberacao de transferencia de estoques, sendo o arquivo compartilhado, basta o ID da solicitacao,
	// e com isso consigo encontrar a filial.
	_sDocZAG = _ExtraiTag ("_oXML:_WSAlianca:_DocTransf", .F.)
	_sAcao = _ExtraiTag ("_oXML:_WSAlianca:_Acao", .F.)
	if empty (_sErros) .and. ! empty (_sDocZAG) .and. _sAcao == 'TransfEstqAutoriza'
		u_log2 ('debug', 'Trata-se de liberacao de transferencia de estoques. Vou buscar filial original pelo ZAG.')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZAG_FILORI"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZAG") + " ZAG "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZAG_FILIAL   = '" + xfilial ("ZAG") + "'"
		_oSQL:_sQuery += " AND ZAG_DOC      = '" + _sDocZAG + "'"
		_oSQL:Log ()
		_sWS_Filia = _oSQL:RetQry (1, .f.)
	else
*/		if empty (_sErros)
			_sWS_Filia = _ExtraiTag ("_oXML:_WSAlianca:_Filial",  .T.)
		endif
//	endif

	// Valida aplicacao
	//u_log ('Vou validar ID de aplicacao com origem =', _sOrigem)
	if empty (_sErros) .and. _sOrigem == 'WS_ALIANCA'
		if alltrim (_ExtraiTag ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'gg2gj256y5f2c5b89'
			_sErros += 'ID de aplicacao inconsistente com objeto WS'
		endif
	elseif empty (_sErros) .and. _sOrigem == 'WS_NAMOB'
		if alltrim (_ExtraiTag ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'ghdf743j689fj4889'
			_sErros += 'ID de aplicacao inconsistente com objeto WS'
		endif
	else
		_sErros += "Origem da requisicao desconhecida ou sem tratamento: " + _sOrigem
	endif
	//u_log ('ID de aplicacao validado:', _sErros)

	if empty (_sErros)
		_sAcao = _ExtraiTag ("_oXML:_WSAlianca:_Acao", .T.)
	endif

	// Valida usuario.
	if empty (_sErros)
		// Quando acesso externo (associados) e nao vai ter usuario Protheus.
		if _sOrigem == 'WS_EXTERNO'
			__cUserId = ''
			cUserName = 'NaMob'
		else
			_sUser = _ExtraiTag ('_oXML:_WSAlianca:_User', .T.)
		
			// Tenta buscar ID do usuario no Protheus, pelo nome de usuario.
			if empty (_sErros) .and. ! empty (_sUser)
				_aUsers := aclone (FwSfAllUsers ())
				//u_log (_aUsers)
				_nUser = ascan (_aUsers, {|_x| alltrim (upper (_x [3])) == alltrim (upper (_sUser))})
				//u_log ('Achei user na posicao ', _nUser)
				if _nUser > 0
					__cUserId = _aUsers [_nUser, 2]
					cUserName = _aUsers [_nUser, 3]
					PswOrder (1)  // 1 - ID do usuário/grupo; 2 - Nome do usuário/grupo; 3 - Senha do usuário; 4 - E-mail do usuário
					if PswSeek (__cUserId, .T.)
						_aPswRet := PswRet ()
						if _aPswRet [1, 17]
							_sErros += "Conta do usuario '" + __cUserId + "' encontra-se bloqueada no Protheus."
						endif
					else
						_sErros += "Conta do usuario '" + __cUserId + "' nao localizada no Protheus."
					endif
				else
					_sErros += "Conta do usuario '" + _sUser + "' nao localizada no Protheus."
				endif
		//		u_log2 ('debug', 'Usuario identificado: ' + __cUserId + '/' + cUserName)
			endif
		endif
	endif
return



// --------------------------------------------------------------------------
static function _ExtraiTag (_sTag, _lObrig)
	local _sRet := ""
	if type (_sTag) != "O"
		if _lObrig
			_sErros += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
	endif
return _sRet
