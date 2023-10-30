// Programa...: MT275TOk
// Autor......: Robert Koch
// Data.......: 31/07/2014
// Descricao..: P.E. 'Tudo OK' na liberacao de lotes.
//              Criado inicialmente para validar usuarios.
//
// Historico de alteracoes:
// 20/10/2023 - Robert - Validacoes para itens com controle pelo FullWMS.
//

// --------------------------------------------------------------------------
User Function MT275TOk ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _sLinkSrv := ''
	local _aSldFull := {}
	local _aAreaAnt := U_ML_SRArea ()
	
	if ! inclui
		_lRet = U_ZZUVL ('021')
	endif

	if _lRet .and. m->dd_local == '01'
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + m->dd_produto, .f.))
			u_help ("Cadastro do produto nao localizado!",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. m->dd_local == '01' .and. sb1 -> b1_vafullw == 'S'
		_sLinkSrv = U_LkServer ('FULLWMS_AX01')
		if empty (_sLinkSrv)
			u_help ("Linked server para o FullWMS nao definido. Impossivel continuar.",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. m->dd_local == '01' .and. sb1 -> b1_vafullw == 'S'
		if empty (m->dd_vaposf) //.or. empty (m->dd_lotectl)
//			u_help ("Para itens controlados pelo FullWMS, os campos '" + alltrim (RetTitle ("DD_VAPOSF")) + "' e '" + alltrim (RetTitle ("DD_VALOTEF")) + "' devem ser informados.",, .t.)
			u_help ("Para itens controlados pelo FullWMS, o campo '" + alltrim (RetTitle ("DD_VAPOSF")) + "' deve ser informado.",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. m->dd_local == '01' .and. sb1 -> b1_vafullw == 'S'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "select QTD, SITUACAO_LOTE"
		_oSQL:_sQuery += " FROM openquery (" + _sLinkSrv + ","
		_oSQL:_sQuery += " 'select QTD, SITUACAO_LOTE"
		_oSQL:_sQuery +=    " from v_alianca_estoques"
		_oSQL:_sQuery +=   " where empr_codemp       = 1"
		_oSQL:_sQuery +=     " and item_cod_item_log = ''" + alltrim (m->dd_produto) + "''"
		_oSQL:_sQuery +=     " and lote              = ''" + alltrim (m->dd_lotectl) + "''"
		_oSQL:_sQuery +=     " and endereco          = ''" + alltrim (m->dd_vaposf)  + "''"
		_oSQL:_sQuery += " ')"
		_oSQL:Log ('[' + procname () + ']')
		_aSldFull := aclone (_oSQL:Qry2Array (.f., .f.))
		U_Log2 ('debug', _aSldFull)
		if _lRet .and. len (_aSldFull) == 0
			u_help ("Produto/lote/endereco nao consta no FullWMS",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. _aSldFull [1, 1] != m->dd_quant
			u_help ("Saldo do endereco no FullWMS = " + cvaltochar (_aSldFull [1, 1]) + ". Voce deve informar a mesma quantidade, pois o FullWMS nao faz bloqueio parcial de enderecos.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. left (_aSldFull [1, 2], 1) == 'B'
			u_help ("Endereco ja se encontra bloqueado no FullWMS.",, .t.)
			_lRet = .F.
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
