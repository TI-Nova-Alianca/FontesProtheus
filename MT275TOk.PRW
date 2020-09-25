// Programa...: MT275TOk
// Autor......: Robert Koch
// Data.......: 31/07/2014
// Descricao..: P.E. 'Tudo OK' na liberacao de lotes.
//              Criado inicialmente para validar usuarios.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MT275TOk ()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	
	if ! inclui
		_lRet = U_ZZUVL ('021')
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet