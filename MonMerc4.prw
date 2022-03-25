// Programa...: MonMerc4
// Autor......: Robert Koch
// Data.......: 26/04/2017
// Descricao..: Tela de monitoramento de logs (gerados pelo Mercanet) na integracao com sistema Mercanet

// #TipoDePrograma    #Consulta
// #Descricao         #Tela de monitoramento de logs (gerados pelo Mercanet) na integracao com sistema Mercanet
// #PalavasChave      #Mercanet #integracao
// #TabelasPrincipais #
// #Modulos           #FAT

// Historico de alteracoes:
// 25/03/2022 - Robert  - Passa a buscar caminho do banco de dados via funcao U_LkServer() - GLPI 11770
//

// --------------------------------------------------------------------------
user function MonMerc4 ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _dDataIni   := date ()

	_dDataIni = U_Get ("A partir da data", "D", 8, "@D", "", _dDataIni, .F., ".T.")

	if _dDataIni != NIL
		processa ({|| _Tela (_dDataIni)})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
static function _Tela (_dDataIni)
	local _oSQL := NIL
	local _sLinkSrv := ""

	_sLinkSrv = U_LkServer ('MERCANET')
	if empty (_sLinkSrv)
		u_help ("Sem definicao para comunicacao com banco de dados do Mercanet.",, .t.)
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT *"
	//	_oSQL:_sQuery += " FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DBS_ERROS_TRIGGERS"
		_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DBS_ERROS_TRIGGERS"
		_oSQL:_sQuery += " WHERE DBS_ERROS_DATA >= '" + dtos (_dDataIni) + "'"
		_oSQL:Log ()
		_oSQL:F3Array ('Monitor de envio de dados para o sistema Mercanet')
	endif
return
