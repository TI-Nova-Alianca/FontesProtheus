// Programa:   CpLaudo
// Autor:      Robert Koch
// Data:       05/04/2017
// Descricao:  Copia (duplica) laudo laboratorial.
//
// Historico de alteracoes:
// 27/05/2017 - Robert - Inclusao de laudos passa a ter controle de semaforo.
// 30/05/2017 - Robert - Nao posicionava no laudo origem antes de fazer a copia dos dados.
//

// --------------------------------------------------------------------------
user function CpLaudo (_sLaudoOri, _sProduto, _sLocal, _sLocaliz, _sLote, _nQtOri)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sCampo    := ""
	local _nCampo    := 0
	local _aCampos   := {}
	local _sNovo     := ""
	local _nLock     := 0
	local _lContinua := .T.

	u_logIni ()

	// Controla inclusao de laudos via semaforo por que desejamos manter numeracao unica entre
	// todas as filiais via 'SELECT MAX (ZAF_ENSAIO)' e o acesso concorrente nao respeita isso.
	if _lContinua
		_nLock := U_Semaforo ('Laudos')
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		zaf -> (dbsetorder (1))  // ZAF_FILIAL+ZAF_ENSAIO
		if ! zaf -> (dbseek (xfilial ("ZAF") + _sLaudoOri, .F.))
			u_help ("Laudo original '" + _sLaudoOri + "' nao localizado. Copia nao pode ser feita.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		for _nCampo = 1 to zaf -> (fcount ())
			_sCampo = alltrim (zaf -> (fieldname (_nCampo)))
			aadd (_aCampos, zaf -> &(_sCampo))
		next
		//u_log (_aCampos)
		_sNovo = CriaVar ("ZAF_ENSAIO")
		u_log ('copiando laudo ', _sLaudoOri, 'para', _sNovo)
		reclock ("ZAF", .T.)
		for _nCampo = 1 to zaf -> (fcount ())
			_sCampo = alltrim (zaf -> (fieldname (_nCampo)))
			zaf -> &(_sCampo) = _aCampos [_nCampo]
		//	u_log (_sCampo, _aCampos [_nCampo], zaf -> &(_sCampo))
		next
		zaf -> zaf_filial = xfilial ("ZAF")
		zaf -> zaf_ensaio = _sNovo
		zaf -> zaf_produt = _sProduto
		zaf -> zaf_local  = ''
		zaf -> zaf_locali = ''
		zaf -> zaf_op     = ''
		zaf -> zaf_lote   = _sLote
		zaf -> zaf_estq   = _nQtOri
		zaf -> zaf_EnsOri = _sLaudoOri
		zaf -> zaf_DtInc  = date ()
		zaf -> zaf_HrInc  = substr (time (), 1, 5)
		zaf -> zaf_user   = cUserName
		msunlock ()
		//u_logtrb ("ZAF", .F.)
	endif

	// Confirma sequenciais, se houver.
	do while __lSX8
		ConfirmSX8 ()
	enddo

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_logFim ()
	U_ML_SRArea (_aAreaAnt)
return
