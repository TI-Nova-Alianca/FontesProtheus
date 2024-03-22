// Programa...: OM200Fim
// Autor......: Leandro Perondi (DWT)
// Data.......: 2013
// Descricao..: P.E. apos a montagem de carga no modulo OMS.
//
// Historico de alteracoes:
// 31/05/2014 - Robert - Gravacao campo DAK_VAUSER
//                     - Gravacao evento inclusao carga para cada pedido.
// 22/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// ------------------------------------------------------------------------------------
User Function OM200FIM ()
	local _aAreaAnt := U_ML_SRArea ()
	u_logIni ()

	// Tela de selecao de frete.
	U_FrtSelPV ()

	// Grava campos adicionais.
	reclock ("DAK", .F.)
	dak -> dak_vauser = cUserName
	msunlock ()
	
	// Grava eventos para posterior consulta.
	_GeraEvt ()

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return



// --------------------------------------------------------------------------
// Grava eventos para posterior consulta.
static function _GeraEvt ()
	local _oEvento  := NIL
	local _oSQL     := NIL
	local _aPed     := {}
	local _nPed     := 0
	local _nEvento	:= 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT DAI_CLIENT, DAI_LOJA, DAI_PEDIDO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("DAI") + " DAI"
	_oSQL:_sQuery +=  " WHERE DAI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND DAI.DAI_FILIAL = '" + xfilial ("DAI") + "'"
	_oSQL:_sQuery +=    " AND DAI.DAI_COD    = '" + dak -> dak_cod + "'"
	_aPed = aclone (_oSQL:Qry2Array (.f., .f.))
	for _nPed = 1 to len (_aPed)
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "DAK001"
		_oEvento:Texto     = "Montagem da carga '" + dak -> dak_cod + "' para embarque"
		_oEvento:Cliente   = _aPed [_nPed, 1]
		_oEvento:LojaCli   = _aPed [_nPed, 2] 
		_oEvento:PedVenda  = _aPed [_nPed, 3]
		_oEvento:Grava ()
	next
	
	// Se estiver definida uma variavel com eventos gerados em ponto de entrada anterior, grava-os.
	if type ("_aEvtTrFOB") == 'A'
		u_log ('Tem ', len (_aEvtTrFOB), ' eventos anteriores PARA GRAVAR')
		for _nEvento = 1 to len (_aEvtTrFOB)
			_oEvento = _aEvtTrFOB [_nEvento]
			_oEvento:Grava ()
		next
	endif
return
