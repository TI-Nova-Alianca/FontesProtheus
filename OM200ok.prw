// Programa...: OM200ok
// Autor......: Robert Koch
// Data.......: 01/12/2014
// Descricao..: P.E. 'Tudo OK' da tela de montagem de cargas do OMS.
//              Criado inicialmente para impedir cargas misturadas Fullsoft + Protheus.
//
// Historico de alteracoes:
// 21/03/2017 - Robert - Eliminada gravacao de logs.
// 06/06/2018 - Robert - Refeita validacao de mais de um pedido com frete FOB e transportadoras
//                       diferentes na mesma carga, agora apenas pedindo confirmacao ao usuario.
//

// --------------------------------------------------------------------------
user function OM200ok ()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt := U_SalvaAmb ()
	u_logIni ()

	if _lRet
		_lRet = _VerFOB ()
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _lRet



// --------------------------------------------------------------------------
// Verifica se ha pedido(s) com frete FOB e transportadora ja selecionada.
static function _VerFOB ()
	local _oSQL    	:= NIL
	local _lRet    	:= .T.
	//local _sFrom   	:= ""
	//local _sTransp 	:= ""
	local _aPed 	:= {}
	local _nPed 	:= 0
	local _sMsg 	:= ""
	local _oEvento 	:= NIL
	local _nLinPed 	:= 0
	local _nTransp	:= 0
	public _aEvtTrFOB := {}  // Deixar PUBLIC para ser gravada pelo P.E. OM200Fim()

/*	if _lRet
		_sFrom :=  " FROM " + RetSQLName ("SC5") + " SC5, "
		_sFrom +=             RetSQLName ("DAI") + " DAI "
		_sFrom += " WHERE SC5.D_E_L_E_T_ = ''"
		_sFrom +=   " AND SC5.C5_FILIAL  = '" + xfilial ("SC5") + "'"
		_sFrom +=   " AND SC5.C5_TRANSP != ''"
		_sFrom +=   " AND SC5.C5_NUM     = DAI.DAI_PEDIDO"
		_sFrom +=   " AND SC5.C5_TPFRETE = 'F'"
		_sFrom +=   " AND DAI.D_E_L_E_T_ = ''"
		_sFrom +=   " AND DAI.DAI_FILIAL = SC5.C5_FILIAL"
		_sFrom +=   " AND DAI.DAI_COD    = '" + dak -> dak_cod + "'"
	
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (DISTINCT C5_TRANSP)"
		_oSQL:_sQuery += _sFrom
		_oSQL:Log ()
		_nQuantas = _oSQL:RetQry ()
		if _nQuantas > 1
			if U_MsgYesNo ("Montagem de carga nao permitida: Entre os pedidos selecionados existe mais de um pedido com frete FOB e diferentes transportadoras selecionadas. Deseja visualizar?")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT C5_NUM AS PEDIDO, C5_TRANSP AS TRANSPORTADORA"
				_oSQL:_sQuery += _sFrom
				_oSQL:F3Array ("Pedidos com frete FOB")
			endif
			_lRet = .F.
		elseif _nQuantas == 1
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT DISTINCT C5_TRANSP"
			_oSQL:_sQuery += _sFrom
			_sTransp = _oSQL:RetQry ()
			_lRet = U_MsgYesNo ("Aviso: Entre os pedidos selecionados existe pelo menos um com frete FOB e transportadora '" + _sTransp + "'. Nao serah permitido, posteriormente, informar outra transportadora para esta carga. Deseja continuar assim mesmo?")
		endif
	endif
*/
	if _lRet
		// Busca lista de pedidos selecionados
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT C5_TRANSP, C5_NUM, C5_CLIENTE, C5_LOJACLI"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC5") + " SC5 "
		_oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SC5.C5_FILIAL  = '" + xfilial ("SC5") + "'"
		_oSQL:_sQuery +=   " AND SC5.C5_TRANSP != ''"
		_oSQL:_sQuery +=   " AND SC5.C5_NUM    IN ("
		
		// Busca da array em memoria, pois os arquivos ainda nao foram gravados.
		for _nLinPed = 1 to len (paramixb [1])
			_oSQL:_sQuery += "'" + paramixb [1, _nLinPed, 5] + "'" + iif (_nLinPed < len (paramixb [1]), ',', '')
		next
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery +=   " AND SC5.C5_TPFRETE = 'F'"
		_aPed = aclone (_oSQL:Qry2Array (.F., .F.))

		// Monta lista de transportadoras, qt. pedidos encontrados e lista dos pedidos selecionados para elas.
		_aTransp = {}
		for _nPed = 1 to len (_aPed)
			_nTransp = ascan (_aTransp, {|_aVal| _aVal [1] == _aPed [_nPed, 1]})
			if _nTransp == 0
				aadd (_aTransp, {_aPed [_nPed, 1], 0, ''})
				_nTransp = len (_aTransp)
			endif
			_aTransp [_nTransp, 2] ++
			_aTransp [_nTransp, 3] += iif (empty (_aTransp [_nTransp, 3]), '', ', ') + _aPed [_nPed, 1]
		next
		
		// Verifica quantas transportadoras diferentes existem entre os pedidos selecionados.
		if len (_aTransp) > 1
			_sMsg = ''
			for _nTransp = 1 to len (_aTransp)
				_sMsg += 'Transp:' + alltrim (_aTransp [_nTransp, 1]) + ' - pedido(s):' + alltrim (_aTransp [_nTransp, 2]) + chr (13) + chr (10)
			next
			if U_MsgNoYes ("ATENCAO: Entre os pedidos selecionados para esta carga existe mais de um pedido com frete FOB e diferentes transportadoras selecionadas:" + chr (13) + chr (10) + chr (13) + chr (10) + _sMsg + chr (13) + chr (10) + "Confirma assim mesmo?", .F.)
				
				// Deixa um evento gerado para cada pedido envolvido.
				// A gravacao dos eventos serah feita no P.E. OM200Fim
				_aEvtTrFOB = {}
				for _nPed = 1 to len (_aPed)
					_oEvento := ClsEvent():new ()
					_oEvento:CodEven   = "DAK002"
					_oEvento:Texto     = "Montagem de carga com pedidos que tem frete FOB e transportadoras diferentes." + chr (13) + chr (10) + _sMsg
					_oEvento:PedVenda  = _aPed [_nPed, 2]
					_oEvento:Cliente   = _aPed [_nPed, 3]
					_oEvento:LojaCli   = _aPed [_nPed, 4] 
					aadd (_aEvtTrFOB, _oEvento)
				next
				_lRet = .T.
			else
				_lRet = .F.
			endif
		endif
	endif
return _lRet
