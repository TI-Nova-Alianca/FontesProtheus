// Programa:   BatSld3
// Autor:      Robert Koch
// Data:       17/02/2010
// Descricao:  Executa o recalculo de poder de terceiros em batch.
//             Este programa deve ser executado a partir do agendamento (customizado) de procesos em batch
//
// Historico de alteracoes:
// 25/01/2016 - Robert - Verifica resultado na tabela CV8 e grava mensagem em caso de erro.
// 06/01/2020 - Robert - Melhorado retorno.
//

#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function BatSld3 ()
//	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	_sArqLog := procname () + "_EmpFil_" + cNumEmp + ".log"  // U_NomeLog (.t., .f.)
	u_logIni ()
	u_log ("Iniciando em", date (), time ())

	cPerg := "MTA216"
	U_GravaSX1 (cPerg, "01", "")  // Produto inicial
	U_GravaSX1 (cPerg, "02", "zzzzzzzzzzzzzzz")  // Produto final
	U_GravaSX1 (cPerg, "03", 2)   // Seleciona filiais = Nao
	u_log ("Iniciando MATA216 (refaz poder de 3os)")
	MATA216 (.T.)

	// Verifica status da ultima execucao.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT COUNT (*)"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("CV8") + " FIM "
	_oSQL:_sQuery +=  " WHERE FIM.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND FIM.CV8_FILIAL = '" + xfilial ("CV8") + "'"
	_oSQL:_sQuery +=    " AND FIM.CV8_PROC   = 'MATA216'"
	_oSQL:_sQuery +=    " AND FIM.CV8_INFO   = '2'"
	_oSQL:_sQuery +=    " AND FIM.CV8_DATA + FIM.CV8_HORA >= "
	_oSQL:_sQuery +=        " (SELECT MAX (INICIO.CV8_DATA + INICIO.CV8_HORA)"
	_oSQL:_sQuery +=           " FROM " + RetSQLName ("CV8") + " INICIO "
	_oSQL:_sQuery +=          " WHERE INICIO.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=            " AND INICIO.CV8_FILIAL = FIM.CV8_FILIAL"
	_oSQL:_sQuery +=            " AND INICIO.CV8_PROC   = FIM.CV8_PROC"
	_oSQL:_sQuery +=            " AND INICIO.CV8_INFO   = '1')"
	u_log (_oSQL:_sQuery)
	if _oSQL:RetQry () == 0
		_oBatch:Mensagens = 'Processo nao foi finalizado corretamente'
		_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	else
		_oBatch:Retorno = 'S'
	endif

	u_logFim ()
//	_sArqLog = _sArqLog2
return
