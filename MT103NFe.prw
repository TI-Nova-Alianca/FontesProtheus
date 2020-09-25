// Programa...: MT103NFe
// Autor......: Robert Koch
// Data.......: 13/10/2014
// Descricao..: P.E. antes da abertura da tela de inclusao de NF de entrada.
//              Criado inicialmente para alimentar objeto ClsFrtFr.
//
// Historico de alteracoes:
//
// 18/10/2014 - alterado o teste do IMPCONH, incluido tambem o EDICONH
// --------------------------------------------------------------------------
user function MT103NFE ()
	local _aArea   := U_ML_SRArea ()
	local _aAmbAnt := U_SalvaAmb ()

	//u_help (procname ())
	if type ("_oClsFrtFr") == "O" .and. type ("_CA100FOR") == "C" .and. type ("_CLOJA") == "C" .and. (IsInCallStack ("U_IMPCONH") .or. IsInCallStack ("U_EDICONH")) 
		//u_help ("vou setar fornevcedors")
        _oClsFrtFr:_sFornece  = _ca100for
        _oClsFrtFr:_sLoja     = _cLoja
                 //msgalert('_CA100For = ' + _Ca100For)
                 //msgalert('_CLoja    = ' + _cLoja)
                 //msgalert('_oClsFrtFr:_sFornece = ' + _oClsFrtFr:_sFornece)
                 //msgalert('_oClsFrtFr:_sLoja    = ' + _oClsFrtFr:_sLoja)
	endif

	U_ML_SRArea (_aArea)
	U_SalvaAmb (_aAmbAnt)
return
