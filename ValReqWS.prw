// Programa:  ValReqWS
// Autor:     Robert Koch
// Data:      10/05/2019
// Descricao: Validacoes basicas de requisicoes recebidas por web service.
//
// Historico de alteracoes:
// 03/02/2022 - Variavel _sErros era local nesta funcao e, portanto, nao visivel na funcao _ExtraiTag().
//            - Estava permitindo continuar mesmo com a tag <User> vazia.
//

// --------------------------------------------------------------------------
// Converte string recebida para XML.
user function ValReqWS (_sOrigem, _sXmlOri, _sErros, _sWS_Empr, _sWS_Filia, _sAcao)
	local _sUTF8       := ""
	local _sError      := ""
	local _sWarning    := ""
	local _sUser       := ""
	local _aUsers      := {}
	local _nUser       := 0
	local _aPswRet     := {}
	private _sErrValRq := ''

	u_log2 ('debug', 'XML recebido: ' + _sXmlOri)

	if empty (_sErrValRq) .and. empty (_sOrigem)
		_sErrValRq += "Origem da conexao nao identificada"
	endif
	if empty (_sErrValRq) .and. empty (_sXmlOri)
		_sErrValRq += "Recebido XML vazio"
	endif

	if empty (_sErrValRq)

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
			_sErrValRq  += "CONTEUDO XML INVALIDO - Error: " + _sError
		EndIf
		If !Empty (_sWarning)
			_sErrValRq  += "CONTEUDO XML INVALIDO - Warning: " + _sWarning
		EndIf
	endif

	// Para ver se consta a tag principal
//	if empty (_sErrValRq)
//		_ExtraiTag ("_oXML:_WSAlianca", .T.)
	if empty (_sErrValRq) .and. type ("_oXML:_WSAlianca") != "O"
		_sErrValRq += "XML invalido: a tag WSAlianca deve estar presente."
	endif
	if empty (_sErrValRq)
		_sWS_Empr  = _ExtraiTag ("_oXML:_WSAlianca:_Empresa", .T.)
	endif
	if empty (_sErrValRq)
		_sWS_Filia = _ExtraiTag ("_oXML:_WSAlianca:_Filial",  .T.)
	endif

	// Valida aplicacao
	if empty (_sErrValRq)
		if _sOrigem == 'WS_ALIANCA'
			if alltrim (_ExtraiTag ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'gg2gj256y5f2c5b89'
				_sErrValRq += 'ID de aplicacao inconsistente com objeto WS'
			endif
		elseif _sOrigem == 'WS_NAMOB'
			if alltrim (_ExtraiTag ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'ghdf743j689fj4889'
				_sErrValRq += 'ID de aplicacao inconsistente com objeto WS'
			endif
		else
			_sErrValRq += "Origem da requisicao desconhecida ou sem tratamento: " + _sOrigem
		endif
	endif

	if empty (_sErrValRq)
		_sAcao = _ExtraiTag ("_oXML:_WSAlianca:_Acao", .T.)
	endif

	// Valida usuario.
	if empty (_sErrValRq)
		// Quando acesso externo (associados) e nao vai ter usuario Protheus.
		if _sOrigem == 'WS_EXTERNO'
			__cUserId = ''
			cUserName = 'NaMob'
		else
			_sUser = _ExtraiTag ('_oXML:_WSAlianca:_User', .T.)
		
			// Tenta buscar ID do usuario no Protheus, pelo nome de usuario.
			if empty (_sErrValRq) .and. ! empty (_sUser)
				_aUsers := aclone (FwSfAllUsers ())
				_nUser = ascan (_aUsers, {|_x| alltrim (upper (_x [3])) == alltrim (upper (_sUser))})
				if _nUser > 0
					__cUserId = _aUsers [_nUser, 2]
					cUserName = _aUsers [_nUser, 3]
					PswOrder (1)  // 1 - ID do usuário/grupo; 2 - Nome do usuário/grupo; 3 - Senha do usuário; 4 - E-mail do usuário
					if PswSeek (__cUserId, .T.)
						_aPswRet := PswRet ()
						if _aPswRet [1, 17]
							_sErrValRq += "Conta do usuario '" + __cUserId + "' encontra-se bloqueada no Protheus."
						endif
					else
						_sErrValRq += "Conta do usuario '" + __cUserId + "' nao localizada no Protheus."
					endif
				else
					_sErrValRq += "Conta do usuario '" + _sUser + "' nao localizada no Protheus."
				endif
			endif
		endif
	endif

	// Alimenta variavel local que vai ser retornada por referencia para a rotina chamadora.
	_sErros = _sErrValRq
return



// --------------------------------------------------------------------------
static function _ExtraiTag (_sTag, _lObrig)
	local _sRet := ""
/*
	if type (_sTag) != "O"
		if _lObrig
			_sErrValRq += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
	endif
*/
	if type (_sTag) != "O"
		if _lObrig
			_sErrValRq += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
		if empty (_sRet)
			_sErrValRq += "XML invalido: valor da tag '" + _sTag + "' deve ser informado."
		endif
	endif
return _sRet
