// Programa...: MonMerc
// Autor......: Robert Koch
// Data.......: 26/04/2017
// Descricao..: Tela de monitoramento de erros na integracao com sistema Mercanet
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MonMerc4 ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _dDataIni   := date ()

	u_logId ()
	u_logIni ()

	_dDataIni = U_Get ("A partir da data", "D", 8, "@D", "", _dDataIni, .F., ".T.")

	if _dDataIni != NIL
		processa ({|| _Tela (_dDataIni)})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _Tela (_dDataIni)
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery += " FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DBS_ERROS_TRIGGERS"
	_oSQL:_sQuery += " WHERE DBS_ERROS_DATA >= '" + dtos (_dDataIni) + "'"
	_oSQL:Log ()
	_oSQL:F3Array ('Monitor de envio de dados para o sistema Mercanet')
return
