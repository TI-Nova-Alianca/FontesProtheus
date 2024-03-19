// Programa:   BatFisc
// Autor:      Robert Koch
// Data:       03/05/2012
// Descricao:  Verifica inconsistencias fiscais.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 08/04/2019 - Catia - Include "TbiConn.ch"
// 19/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------
#include "rwmake.ch"     
#include "colors.ch"
#Include "Protheus.ch"
#Include "TbiConn.ch"

user function BatFisc ()
	local _sMsg     := ""
	//local _sQuery   := ""
	//local _sQryBase := ""
	//local _aCampos  := {}
	//local _nCampo   := 0
	//local _aCols    := {}
	local _oSQL     := NIL
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

	// Verifica consistencias entre as diversas tabelas do fiscal.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT B1_COD, B1_DESC, B1_VAORGAN, B1_CODPAI"
	_oSQL:_sQuery +=   " From " + RetSQLName ("SB1") + " SB1"
	_oSQL:_sQuery +=  " Where SB1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " And B1_GRUPO = '0400'"
	_oSQL:_sQuery +=    " And B1_VAORGAN NOT IN (' ', 'C')"
	_oSQL:_sQuery +=    " And not exists (SELECT * FROM " + RetSQLName ("SB1") + " PAI"
	_oSQL:_sQuery +=                     " WHERE PAI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                       " And PAI.B1_GRUPO    = '0400'"
	_oSQL:_sQuery +=                       " And PAI.B1_VAORGAN  = 'C'"
	_oSQL:_sQuery +=                       " And PAI.B1_COD      = SB1.B1_CODPAI)"
	_oSQL:_sQuery +=  " Order by B1_COD"
	u_log (_oSQL:_sQuery)
	if len (_oSQL:Qry2Array (.f., .f.)) > 0
		_sMsg = 'Uvas nao convencionais sem informacao do produto "pai" (uva convencional) ou o produto informado como pai nao eh uva, ou nao eh convencional:' + _oSQL:Qry2HTM ("Uvas nao convencionais sem 'pai' (convencional)", NIL, "", .F.)
		u_log (_sMsg)
		_sDest := ""
		_sDest += "robert.koch@novaalianca.coop.br;"
		//U_SendMail (_sDest, "Verificacao diaria do sistema - cadastros uvas", _sMsg)
	endif

	u_logFim ()
	_sArqLog = _sArqLog2
return
