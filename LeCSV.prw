// Programa:  LeCSV
// Autor:     Robert Koch
// Data:      18/07/2016
// Descricao: Leitura de arquivos CSV.
//
// Historico de alteracoes:
// 13/10/2017  - Robert - Alterado separador padrao de virgula para ponto e virgula.
//

// --------------------------------------------------------------------------
user function LeCSV (_sArq, _sSeparad)
	local _aRet := {}
	processa ({|| _aRet := _AndaLogo (_sArq, _sSeparad)})
return _aRet



// --------------------------------------------------------------------------
static function _AndaLogo (_sArq, _sSeparad)
	local _sLinha := ""
	local _aLinha := {}
	local _aRet   := {}

	if ! file (_sArq)
		u_help ("Arquivo nao encontrado: " + _sArq)
	endif
	
	FT_FUSE(_sArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()
		IncProc("Lendo arquivo " + _sArq)
		_sLinha := FT_FReadLN()
		_aLinha = U_SeparaCpo (_sLinha, iif (empty (_sSeparad), ';', _sSeparad))
		if len (_aLinha) > 0
			aadd (_aRet, aclone (_aLinha))
		endif
		FT_FSKIP()
	End
	FT_FUSE()
return _aRet
