// Programa:  ValReqWS
// Autor:     Robert Koch
// Data:      10/05/2019
// Descricao: Validacoes basicas de requisicoes recebidas por web service.
//
// Historico de alteracoes:
// 03/02/2022 - Robert - Variavel _sErros era local nesta funcao e, portanto, nao visivel na funcao _ExtraiTag().
//                     - Estava permitindo continuar mesmo com a tag <User> vazia.
// 20/02/2022 - Robert - Funcao _ExtraiTag() migrada para U_ExTagXML().
// 12/05/2023 - Robert - Alterados alguns logs de INFO para DEBUG e vice-versa.
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
//	private _sErroWS := ''

	u_log2 ('info', '[porta ' + cvaltochar (GetServerPort ()) + ']XML recebido: ' + _sXmlOri)

	if empty (_sErroWS) .and. empty (_sOrigem)
		_sErroWS += "Origem da conexao nao identificada"
	endif
	if empty (_sErroWS) .and. empty (_sXmlOri)
		_sErroWS += "Recebido XML vazio"
	endif

	if empty (_sErroWS)

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
			_sErroWS  += "CONTEUDO XML INVALIDO - Error: " + _sError
		EndIf
		If !Empty (_sWarning)
			_sErroWS  += "CONTEUDO XML INVALIDO - Warning: " + _sWarning
		EndIf
	endif

	// Para ver se consta a tag principal
//	if empty (_sErroWS)
//		U_ExTagXML ("_oXML:_WSAlianca", .T.)
	if empty (_sErroWS) .and. type ("_oXML:_WSAlianca") != "O"
		_sErroWS += "XML invalido: a tag WSAlianca deve estar presente."
	endif
	if empty (_sErroWS)
		_sWS_Empr  = U_ExTagXML ("_oXML:_WSAlianca:_Empresa", .T.)
	endif
	if empty (_sErroWS)
		_sWS_Filia = U_ExTagXML ("_oXML:_WSAlianca:_Filial",  .T.)
	endif

	// Valida aplicacao
	if empty (_sErroWS)
		if _sOrigem == 'WS_ALIANCA'
			if alltrim (U_ExTagXML ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'gg2gj256y5f2c5b89'
				_sErroWS += 'ID de aplicacao inconsistente com objeto WS'
			endif
		elseif _sOrigem == 'WS_NAMOB'
			if alltrim (U_ExTagXML ("_oXML:_WSAlianca:_IdAplicacao", .T.)) != 'ghdf743j689fj4889'
				_sErroWS += 'ID de aplicacao inconsistente com objeto WS'
			endif
		else
			_sErroWS += "Origem da requisicao desconhecida ou sem tratamento: " + _sOrigem
		endif
	endif

	if empty (_sErroWS)
		_sAcao = U_ExTagXML ("_oXML:_WSAlianca:_Acao", .T.)
	endif

	// Valida usuario.
	if empty (_sErroWS)
		// Quando acesso externo (associados) e nao vai ter usuario Protheus.
		if _sOrigem == 'WS_EXTERNO'
			__cUserId = ''
			cUserName = 'NaMob'
		else
			_sUser = U_ExTagXML ('_oXML:_WSAlianca:_User', .T.)
		
			// Tenta buscar ID do usuario no Protheus, pelo nome de usuario.
			if empty (_sErroWS) .and. ! empty (_sUser)
				_aUsers := aclone (FwSfAllUsers ())
				_nUser = ascan (_aUsers, {|_x| alltrim (upper (_x [3])) == alltrim (upper (_sUser))})
				if _nUser > 0
					__cUserId = _aUsers [_nUser, 2]
					cUserName = _aUsers [_nUser, 3]
					PswOrder (1)  // 1 - ID do usu�rio/grupo; 2 - Nome do usu�rio/grupo; 3 - Senha do usu�rio; 4 - E-mail do usu�rio
					if PswSeek (__cUserId, .T.)
						_aPswRet := PswRet ()
						if _aPswRet [1, 17]
							_sErroWS += "Conta do usuario '" + __cUserId + "' encontra-se bloqueada no Protheus."
						endif
					else
						_sErroWS += "Conta do usuario '" + __cUserId + "' nao localizada no Protheus."
					endif
				else
					_sErroWS += "Conta do usuario '" + _sUser + "' nao localizada no Protheus."
				endif
			endif
		endif
	endif

//	// Alimenta variavel local que vai ser retornada por referencia para a rotina chamadora.
//	_sErros = _sErroWS
return


/*
// --------------------------------------------------------------------------
static function U_ExTagXML (_sTag, _lObrig)
	local _sRet := ""
/*
	if type (_sTag) != "O"
		if _lObrig
			_sErroWS += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
	endif
*/
	if type (_sTag) != "O"
		if _lObrig
			_sErroWS += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
		if empty (_sRet)
			_sErroWS += "XML invalido: valor da tag '" + _sTag + "' deve ser informado."
		endif
	endif
return _sRet
*/
