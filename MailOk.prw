// Programa:  MailOk
// Autor:     Robert Koch
// Data:      28/02/2011
// Descricao: Valida endereco de e-mail.
//
// Historico de alteracoes:
// 25/09/2017 - Robert - Permite ponto-e-virgula (e mais de uma arroba) para casos de mais de um e-mail no mesmo campo.
//

// --------------------------------------------------------------------------
user function MailOk (_sEMail)
	local _lRet     := .T.
//	local _sValidos := '-.0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'
	local _sValidos := '-.0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_;'
	local _sNaoIni  := "@."
	local _sNaoFim  := "@."
	local _nChar    := 0
	local _sLixo    := "LIXO@NOVAALIANCA.COOP.BR"
	local _sNFE     := "NFE@NOVAALIANCA.COOP.BR"

	_sEMail = rtrim (_sEMail)  // Remove somente espacos da direita (peguei um caso com espaco na esquerda).
	
	for _nChar = 1 to len (_sEMail)
		if ! substr (_sEMail, _nChar, 1) $ _sValidos
			u_help ("Caracter '" + substr (_sEMail, _nChar, 1) + "' invalido no endereco de e-mail. Os caracteres permitidos sao: " + _sValidos)
			_lRet = .F.
			exit
		endif
	next
		
	if _lRet .and. at ("@", _sEMail) == 0
		u_help ("Endereco de e-mail deve conter '@'")
		_lRet = .F.
	endif
//	if _lRet .and. at ("@", substr (_sEMail, at ("@", _sEMail) + 1)) > 0
//		u_help ("Endereco de e-mail nao deve conter mais de um '@'")
//		_lRet = .F.
//	endif
	if _lRet .and. at (".", _sEMail) == 0
		u_help ("Endereco de e-mail deve conter pelo menos um ponto (.)")
		_lRet = .F.
	endif
	if _lRet .and. at ("..", _sEMail) > 0
		u_help ("Endereco de e-mail nao deve conter pontos repetidos (..)")
		_lRet = .F.
	endif
	if _lRet .and. left (_sEMail, 1) $ _sNaoIni
		u_help ("Endereco de e-mail nao deve iniciar por caracteres contidos em '" + _sNaoIni + "'")
		_lRet = .F.
	endif
	if _lRet .and. right (_sEMail, 1) $ _sNaoFim
		u_help ("Endereco de e-mail nao deve terminar por caracteres contidos em '" + _sNaoIni + "'")
		_lRet = .F.
	endif
	if _lRet .and. "LIXO@" $ upper (_sEMail) .and. ! _sLixo $ upper (_sEMail)
		u_help ("Endereco de e-mail para 'lixo' deve ser '" + _sLixo + "'")
		_lRet = .F.
	endif
	if _lRet .and. ("DANFE@VINHOS-ALIANCA" $ upper (alltrim (_sEMail)) .or. "DANFE@NOVAALIANCA" $ upper (alltrim (_sEMail)))
		u_help ("Nosso endereco para envio de arquivos XML e DANFe e´ '" + _sNFE + "'")
		_lRet = .F.
	endif
	if _lRet .and. at ("@.", _sEMail) > 0
		u_help ("Endereco de e-mail nao deve conter @ seguido de ponto (@.)")
		_lRet = .F.
	endif
return _lRet
