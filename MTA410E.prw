// Programa:  MTA410E
// Autor:     Robert Koch
// Data:      17/04/2008
// Descricao: P.E. apos a exclusao do SC6 e antes da exclusao do SC5 na tela de pedidos de venda.
//
// Historico de alteracoes:
// 21/06/2013 - Leandro - exclui reservas quando exclui o pedido
// 23/03/2014 - Robert  - Limpa campo C5_VAPEMB correspondente na filial 01.
// 09/03/2017 - Robert  - Limpeza campo C5_VAPEMB desabilitada, pois nao temos mais deposito fechado.
//

// --------------------------------------------------------------------------
User Function MTA410E ()
	local _aAreaAnt := U_ML_SRArea ()

	// Atualiza controle de fretes
	U_FrtPV ("E")

	// Exclui reservas feitas para este pedido, quando o mesmo tiver 'flag' de 'reservar produtos'.
	_DelSC0 ()

	// Desvincula pedidos originais quando este for um pedido de embarque orginado por outra filial.
	// desabilitar depois que a filial 13 virar 01.
	// Robert, 09/03/2017 --> _DelPOri ()

	U_ML_SRArea (_aAreaAnt)
return



// -------------------------------------------------------------------------
// Exclui reservas feitas para este pedido, quando o mesmo tiver 'flag' de 'reservar produtos'.
static function _DelSC0 ()
	dbselectarea("SC0")
	dbsetorder(3)
	dbseek(SC5->C5_VAFEMB + SC5->C5_NUM)
	if found()
		While !EOF() .and. SC0->C0_VAPEDID == SC5->C5_NUM
			// deleta todas reservas do pedido em questão e depois inclui de novo, para passar por todas validações novamente
			reclock ("SC0", .F.)
			SC0 -> (dbdelete ())
			msunlock ()
			
			dbselectarea("SB2")
			dbsetorder(1)
			dbseek(SC5->C5_VAFEMB + SC0->C0_PRODUTO)
			reclock("SB2")
			Replace SB2->B2_RESERVA With SB2->B2_RESERVA - SC0->C0_QUANT 
			msunlock()
				
			dbselectarea("SC0")
			dbskip()
		enddo
	endif
Return


/*
// -------------------------------------------------------------------------
// Desvincula pedidos originais quando este for um pedido de embarque orginado por outra filial.
static function _DelPOri ()
	local _oSQL := NIL
	u_logIni ()

	// Inicialmente vai ser usado apenas enquanto a filial 01 precisar expedir pela 13.
	if cEmpAnt + cFilAnt == '0113' .and. sc5 -> c5_cliente == '002940'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE " + RetSQLName ("SC5")
		_oSQL:_sQuery += " SET C5_VAPEMB = ''"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND C5_FILIAL = '01'"
		//_oSQL:_sQuery += " AND C5_VAFEMB = '01'"
		_oSQL:_sQuery += " AND C5_EMISSAO >= '20140101'"  // Para nao perder tempo lendo pedidos antigos.
		_oSQL:_sQuery += " AND C5_VAPEMB = '" + m->c5_num + "'"
		u_log (_oSQL:_sQuery)
		_oSQL:Exec ()
	endif
	u_logFim ()
return
*/