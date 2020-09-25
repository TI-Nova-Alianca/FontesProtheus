// Programa:   BatXML
// Autor:      Robert Koch
// Data:       01/08/2012
// Descricao:  Rotinas automatica ref. XML de notas de entrada.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 01/09/2012 - Robert - Passa a verificar chaves na SEFAZ.
// 21/02/2015 - Catia  - Revalidação passou para o REVALXML
// 23/09/2015 - Robert - Criada regua de processamento.
// 04/11/2019 - Robert - Nao chama mais a rotina de recepcao de e-mail (migrada para 'batch' separado).
//

// --------------------------------------------------------------------------
user function BatXML (_sPath, _nMaxArq) //, _lLeMail)
//	local _lRet      := .T.
//	local _aAreaAnt  := {}
//	local _aAmbAnt   := {}
	local _nArq      := 0
	local _aDir      := {}
	local _nQtArq    := 0
//	local _oSQL      := NIL
//	local _aRecnos   := {}
//	local _nRecno    := 0
//	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	private _sArqLog := procname () + "_" + dtos (date ()) + ".log"
	U_logIni ()
	u_logDH ()

	procregua (10)

	// Importa arquivos que estiverem na pasta de importacao.
	//if ! _lLeMail
		_aDir = directory (_sPath + '*.xml')
		u_log(len (_aDir), 'arquivos para importar na pasta', _sPath)
	
		_nMaxArq := iif (_nMaxArq == NIL, 50, _nMaxArq)
	
		procregua (min (_nMaxArq, len (_aDir)))
		for _nArq = 1 to min (_nMaxArq, len (_aDir))  // Por enquanto, somente alguns arquivos por vez.
			incproc (_aDir [_nArq, 1])
			if _aDir [_nArq, 2] < 500000  // Limite de tamanho cfe. layout da SEFAZ
				u_log("Importacao diretorio - arquivo ", _nArq, "de", len (_aDir), _aDir [_nArq, 1])
				U_ZZXI (_sPath + _aDir [_nArq, 1])
				_nQtArq ++
			else
				U_AvisaTI ("Arquivo muito grande na pasta de importacao de XML: " + _aDir [_nArq, 1])
			endif
		next

		_oBatch:Mensagens += cvaltochar (_nQtArq) + " arquivos importados."
	//endif

	// Migrado para 'batch' separado.
	//if _lLeMail
	//	u_log ('chamando recmail')
	//	_lRet = u_recmail(.T.) // baixa xml pelo e-mail - parametro (T=batch, F=Manual)
	//	u_log ('retornou do recmail com:', _lRet)
	//endif

	u_logFim ()
return .t.
