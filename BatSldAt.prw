// Programa:   BatSldAt
// Autor:      Robert Koch
// Data:       16/02/2010
// Descricao:  Executa o recalculo de saldo atual em batch.
//             Este programa deve ser executado a partir do agendamento (customizado) de procesos em batch
//
// Historico de alteracoes:
// 17/02/2010 - Robert - Executa, tambem, o processo MATA216.
// 22/03/2012 - Robert - Separado do MATA216, para poder agendar em separado.
// 07/08/2013 - Robert - Passa a usar SIM nos parametros 'zera saldo MOD' e 'zera CM MOD'.
// 05/07/2022 - Robert - Melhoria gravacao de logs (GLPI 12312)
//

//#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function BatSldAt ()
//	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	_sArqLog := U_NomeLog (.t., .f.)
//	u_logIni ()
//	u_log (date(), time())

	// Atualiza perguntas da rotina e executa 'refaz saldo atual'.
	cPerg := "MTA300"
	U_GravaSX1 (cPerg, "01", "")      // Alm. inicial
	U_GravaSX1 (cPerg, "02", "zz")    // Alm. final
	U_GravaSX1 (cPerg, "03", "")  // Produto inicial
	U_GravaSX1 (cPerg, "04", "zzzzzzzzzzzzzzz")  // Produto final
	U_GravaSX1 (cPerg, "05", 1)       // Zera saldo dos produtos MOD = Sim
	U_GravaSX1 (cPerg, "06", 1)       // Zera CM dos produtos MOD = Sim
	U_GravaSX1 (cPerg, "07", 2)       // Trava registros do SB2 = Nao
	U_GravaSX1 (cPerg, "08", 2)       // Seleciona filiais = Nao
	U_Log2 ('info', '[' + procname () + ']Iniciando MATA300 (refaz saldo atual)')
	MATA300 (.T.)
	U_Log2 ('info', '[' + procname () + ']Finalizou MATA300 (refaz saldo atual)')
//	u_logFim ()
//	_sArqLog = _sArqLog2
return .t.
