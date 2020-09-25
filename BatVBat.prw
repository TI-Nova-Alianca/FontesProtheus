// Programa:   BatVBat
// Autor:      Robert Koch
// Data:       25/03/2011 (baseado no VA_ZZ6 de 18/08/2009)
// Cliente:    Alianca
// Descricao:  Verificacoes gerais rotinas batch.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 13/05/2011 - Robert - Verifica horaio de inicio maior que horario de termino.
// 16/11/2012 - Robert - Verifica representante sem batch agendado para envio de dados.
// 17/11/2015 - Robert - Executa limpeza de batches antigos (tabela ZZ6).
//

// --------------------------------------------------------------------------
user function BatVBat ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _sQuery   := ""
	local _sMsg     := ""
	local _aRetQry  := {}
	local _i        := 0
	local _oSQL     := NIL
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

	// Verifica horarios.
	_sQuery := ""
	_sQuery += " SELECT rtrim (ZZ6_DADOS) + ' - ' + rtrim (ZZ6_CMD) + ' Fil.dest.:' + ZZ6_FILDES"
	_sQuery +=   " FROM " + RetSQLName ("ZZ6")
	_sQuery +=  " WHERE ZZ6_FILIAL  = '" + xfilial ("ZZ6") + "'"
	_sQuery +=    " AND D_E_L_E_T_  = ''"
	_sQuery +=    " AND ZZ6_HRINI  >= ZZ6_HRFIM"
	_sQuery +=    " AND ZZ6_ATIVO  != 'N'"
	_sQuery +=    " AND ZZ6_SEQ    != '" + zz6 -> zz6_seq + "'"  // Este proprio processo certamente estarah em execucao.
	_sQuery +=    " AND (ZZ6_PERIOD = 'R' OR (ZZ6_PERIOD = 'U' AND ZZ6_RODADO NOT IN ('S', 'C') AND ZZ6_QTTENT < ZZ6_MAXTEN))"
	u_log (_sQuery)
	_aRetQry = aclone (U_Qry2Array (_sQuery))
	for _i = 1 to len (_aRetQry)
		U_AvisaTI ("Processo com horario de termino menor que horario de inicio: " + _aRetQry [_i, 1])
	next

/* Nao usamos mais. Robert, 27/09/18
	// Verifica representantes sem agendamento de envio de dados.
	_sMsg = ""
	_sQuery := ""
	_sQuery += " SELECT A3_COD + ' - ' + A3_NOME"
	_sQuery +=   " FROM " + RetSQLName ("SA3") + " SA3 "
	_sQuery +=  " WHERE SA3.A3_FILIAL  = '" + xfilial ("SA3") + "'"
	_sQuery +=    " AND SA3.D_E_L_E_T_ = ''"
	_sQuery +=    " AND SA3.A3_ATIVO   = 'S'"
	_sQuery +=    " AND SA3.A3_COD NOT IN ('001','005','136','090','031')"  // Desabilitados
	_sQuery +=    " AND NOT EXISTS (SELECT *"
	_sQuery +=                      " FROM " + RetSQLName ("ZZ6") + " ZZ6 "
	_sQuery +=                     " WHERE ZZ6_FILIAL  = '" + xfilial ("ZZ6") + "'"
	_sQuery +=                       " AND ZZ6.D_E_L_E_T_  = ''"
	_sQuery +=                       " AND ZZ6.ZZ6_CMD     = 'U_BATEREP(''' + RTRIM (SA3.A3_COD) + ''',''' + RTRIM (SA3.A3_COD) + ''')'"
	_sQuery +=                       " AND ZZ6.ZZ6_ATIVO   = 'S')"
	u_log (_sQuery)
	_aRetQry = aclone (U_Qry2Array (_sQuery))
	for _i = 1 to len (_aRetQry)
		U_AvisaTI ("Representante sem batch agendado para geracao de dados: " + _aRetQry [_i, 1])
	next
*/

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
