// Programa...: ExTagXML
// Autor......: Robert Koch
// Data.......: 20/02/2022
// Descricao..: Extrai valor de uma tag de um XML
//              Usado inicialmente como auxiliar para web service.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Extrai valor de uma tag de um XML
// #PalavasChave      #TAG #XML
// #TabelasPrincipais 
// #Modulos           
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
// Deve ser passado todo o caminho da tag. Ex:
// _dDtProd   = stod (U_ExTagXML ("_oXML:_WSAlianca:_DtProd", .T., .T.))
// Retorna erros na variavel publica _sErroWS
user function ExTagXML (_sTag, _lObrig, _lValData)
	local _sRet    := ""
	local _lDataOK := .T.
	local _nPos    := 0

//	U_Log2 ('debug', '[' + procname () + ']Tentando ler a tag ' + _sTag)
//	U_Log2 ('debug', '[' + procname () + ']Type:' + type (_sTag))
	if type (_sTag) != "O"
		if _lObrig
			_sErroWS += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
//		U_Log2 ('debug', '[' + procname () + ']Li a tag ' + _sTag + ' e obtive: ' + _sRet)
		if empty (_sRet) .and. _lObrig
			if type ('_sErroWS') == 'C'
				_sErroWS += "XML invalido: valor da tag '" + _sTag + "' deve ser informado."
			endif
		endif
		if _lValData  // Preciso validar formato da data
			if ! empty (_sRet)
				if len (_sRet) != 8
					_lDataOK = .F.
				else
					for _nPos = 1 to len (_sRet)
						if ! IsDigit (substr (_sRet, _nPos, 1))
							_lDataOK = .F.
							exit
						endif
					next
				endif
				if ! _lDataOK
					if type ('_sErroWS') == 'C'
						_sErroWS += "Data deve ser informada no formato AAAAMMDD"
					endif
				endif
			endif
		endif
	endif
return _sRet
