// Programa:  NomeLog
// Autor:     Robert Koch
// Data:      23/04/2008
// Cliente:   Alianca
// Descricao: Gera nome para arquivo de log.
//
// Historico de alteracoes:
// 23/05/2008 - Robert - Apenas alterado nome de variavel...
// 08/03/2011 - Robert - Opcao de incluir a data no nome do arquivo.
//

// --------------------------------------------------------------------------
user function NomeLog (_lDeleta, _lComData)
	local _sRet := ""

	if _lComData != NIL .and. _lComData
		_sRet = procname (1) + "_" + dtos (date ()) + ".log"
	else
		_sRet = procname (1) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + ".log"
	endif
	if _lDeleta == NIL .or. _lDeleta
		delete file (_sRet)
	endif
return _sRet
