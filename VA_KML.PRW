// Programa:   VA_ZML
// Autor:      Robert Koch
// Data:       25/11/2017
// Descricao:  Funcoes e tratamentos para dados KML (arquivos de georeferenciamento Google)
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function VA_KML (_sQueFazer, _sAlias, _sCampo, _sNomeArq)
	processa ({||_AgoraVai (_sQueFazer, _sAlias, _sCampo, _sNomeArq)})
return


// --------------------------------------------------------------------------
static function _AgoraVai (_sQueFazer, _sAlias, _sCampo, _sNomeArq)
	local _aAreaAnt := U_ML_SRArea ()
	local _sArq      := ""
	local _sKML      := ""
	local _lContinua := .T.
	local _nHdl      := 0
	local _sTmpPath  := ''
	
	procregua (10)

	if _sQueFazer == 'I'
		
		// Importa conteudo do arquivo e grava-o no campo informado (deve ser um campo tipo memo real).
		if ! empty (_sNomeArq)
			if ! file (_sNomeArq)
				u_help ("Arquivo '" + _sNomeArq + "' nao encontrado.")
				_lContinua = .F.
			else
				_sArq = _sNomeArq
			endif
		else
			_sArq = cGetFile ("Arquivos tipo KML|*.KML", "Selecione arquivo", 0, 'C:\', .T., GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_NETWORKDRIVE)
			if empty (_sArq)
				_lContinua = .F.
			endif
		endif
		if _lContinua
			incproc ("Lendo arquivo")
			u_log ('vou ler arq')
			FT_FUSE(_sArq)
			FT_FGOTOP()
			While !FT_FEOF()
				_sKML += FT_FREADLN ()
				FT_FSKIP()
				if len (_sKML) > 500000
					u_help ("Tamanho do arquivo nao deve exceder 500.000 bytes")
					_lContinua = .F.
					exit
				endif 
			EndDo
			if empty (_sKML)
			 	u_help ("Arquivo vazio.")
				_lContinua = .F.
			endif
			FT_FUSE()  // Fecha o arquivo
		endif
		if _lContinua
			reclock (_sAlias, .F.)
			(_sAlias) -> &(_sCampo) = _sKML
			msunlock ()
		endif

	elseif _sQueFazer == 'V'

		// Extrai o conteudo do arquivo, grava em arquivo temporario, copia esse arquivo
		// para a pasta temporaria da estacao e deleta-o da pasta de documentos
		incproc ("Exportando arquivo")
		_sNomeArq += iif ('.KML' $ upper (_sNomeArq), '', '.KML')
		_sArq := MsDocPath () + "\" + _sNomeArq
		_nHdl := MsfCreate (_sArq, 0)
		if fWrite (_nHdl, alltrim ((_sAlias) -> &(_sCampo))) == 0
			u_help ("Erro na criacao de arquivo temporario para gravacao do KML")
			_lContinua := .F.
		endif
		fClose (_nHdl)
		if _lContinua
			incproc ("Copiando para pasta temporaria")
			_sTmpPath = AllTrim (GetTempPath ())
			CpyS2T (_sArq, _sTmpPath, .T.)
			delete file (_sArq)
			ShellExecute ("Open", _sTmpPath + _sNomeArq, "", "", 1 )
		endif
	else
		u_help ("Sem tratamento para opcao '" + _sQueFazer + "'")
	endif

	U_ML_SRArea (_aAreaAnt)
return
