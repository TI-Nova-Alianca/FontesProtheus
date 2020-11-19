// Programa...: SD3250E
// Autor......: Robert Koch
// Data.......: 03/09/2015
// Descricao..: P.E. apos exclusao apontamento producao (dentro da transacao).
//              Criado inicialmente para tratamento de OP de reprocesso.
//
// Historico de alteracoes:
//
// 30/05/2019 - Andre  - Removida a execução da rotina _AtuReproc

// ------------------------------------------------------------------------------------
User Function SD3250E()
	Local _aAreaAnt := U_ML_SRArea ()
	
	u_logIni ()
	
	// Atualizacoes especificas para OP de reprocessamento.
    //_AtuReproc () PRECISO ESTORNAR MANUALMENTE
    
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return



// // ------------------------------------------------------------------------------------
// // Atualizacoes para OP de reprocessamento.
// static function _AtuReproc ()
// 	//local _sAlmRetr := GetMv ("VA_ALMREPR")
// 	local _sAlmFull := GetMv ("VA_ALMFULP",, '')
// 	local _aRecnos  := {}
// 	local _oSQL     := NIL
// 	local _sMsgErr  := ""

// //	if fBuscaCpo ("SC2", 1, xfilial ("SC2") + m->d3_op, "C2_VAOPESP") == 'R'
// //		u_log ('Eh op de reproc.')
// //		u_logtrb ('SD3')
// //		u_log (m->d3_op)
// //		u_log (m->d3_vaetiq)
// //		u_log (m->d3_doc)
// 		// Busca os recnos dos registros de transf. para almox. do Full gerados no momento do apontamento desta producao.
// 		_oSQL := ClsSQL ():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += "SELECT R_E_C_N_O_"
// 		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3")
// 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
// 		_oSQL:_sQuery +=   " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
// 		_oSQL:_sQuery +=   " AND D3_COD     = '" + m->d3_cod + "'"
// 		_oSQL:_sQuery +=   " AND D3_CF IN ('RE4','DE4')"
// //		_oSQL:_sQuery +=   " AND ("
// //		_oSQL:_sQuery +=        "(D3_CF = 'RE4' AND D3_LOCAL = '" + _sAlmRetr + "')"
// //		_oSQL:_sQuery +=        " OR "
// //		_oSQL:_sQuery +=        "(D3_CF = 'DE4' AND D3_LOCAL = '" + _sAlmFull + "')"
// //		_oSQL:_sQuery +=        ")"
// 		_oSQL:_sQuery +=   " AND D3_ESTORNO != 'S'"
// 		_oSQL:_sQuery +=   " AND D3_VAETIQ   = '" + m->d3_vaetiq + "'"
// //		_oSQL:_sQuery +=   " AND D3_VACHVEX  = 'SD3" + m->d3_doc + "'"
// 		u_log (_oSQL:_sQuery)
// 		_aRecnos = _oSQL:Qry2Array ()
// 		if len (_aRecnos) == 2
// 			begin transaction
// 			if ! u_A260Proc (NIL, NIL, NIL, NIL, NIL, NIL, {_aRecnos [1, 1], _aRecnos [2, 1]}, NIL)
// 				_sMsgErr = "Nao foi possivel estornar a transferencia feita para o almoxarifado de integracao com FullWMS no momento do apontamento desta producao. Verifique manualmente os estoques dos almoxarifados '" + _sAlmRepr + "' e '" + _sAlmFull + "'."
// 				u_help (_sMsgErr)
// 				u_AvisaTI (_sMsgErr + " Query para leitura dos recnos a estornar: " + _oSQL:_sQuery)
// 				_AtuEstor ((_sAliasQ) -> entrada_id, '6')  // Atualiza a tabela do Fullsoft como 'Erro no estorno'
// 			else
// 				u_log ('estorno da transf. OK')
// 				_AtuEstor ((_sAliasQ) -> entrada_id, '5')  // Atualiza a tabela do Fullsoft como 'Estornado'
// 			endif
// 			end transaction
// 		else
// 			if len (_aRecnos) == 0
// 				u_log ('Nao encontrei transferencia a estornar.')
// 			else
// 				u_AvisaTI ("Query retornou mais de um par de registros para estornar: " + _oSQL:_sQuery)
// 			endif
// 		endif
// //	else
// //		u_log ('Nao eh op de reproc.')
// //	endif
// return

// // --------------------------------------------------------------------------------------------
// // Atualiza status no FullWMS.
// static function _AtuEstor (_sEntrada, _sStatus)
// 	local _oSQL := ClsSQL ():New ()
// 	_oSQL:_sQuery := " update tb_wms_entrada"
// 	_oSQL:_sQuery +=    " set status_protheus = '" + _sStatus + "'"
// 	_oSQL:_sQuery +=  " where entrada_id = 'ZA1" + sd3->d3_filial + sd3->d3_vaetiq + "'"
// 	_oSQL:Log()
// 	_oSQL:Exec ()
	
// return
