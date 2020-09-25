// Programa...: VA_RUSAI
// Autor......: Robert Koch
// Data.......: 12/02/2020
// Descricao..: Atualiza sistema de agenda/inspecoes (desmembrado do VA_RUS1P)
//
// Historico de alteracoes:
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function va_rusAI (_sStatDe, _sStatPara)
	local _lContinua   := .T.
	local _aAreaAnt    := U_ML_SRArea ()
	local _sLinkSrv    := ''

	u_logIni ()

	// Nao posso estragar a variavel caso ela venha populada de rotinas anteriores.
	if _lContinua
		if type ("_aRusInsp") != 'A' .or. len (_aRusInsp) < .InspecoesSafraQtColunas
//			u_log ('Declarando _aRusInsp')
			private _aRusInsp  := {}  // Deixar private para ser vista e alimentada por outras rotinas.
			_lContinua = U_VA_RusLI (1)
//		else
//			u_log ('_aRusInsp jah existia:', _aRusInsp)
		endif
	endif

	if _lContinua
		if _aRusInsp [.InspecoesSafraSituacao] $ _sStatDe
			if "TESTE" $ upper (GetEnvServer())
				_sLinkSrv = "LKSRV_NAWEB_TESTE.naweb_teste.dbo"
			else
				_sLinkSrv = "LKSRV_NAWEB.naweb.dbo"
			endif
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + _sLinkSrv + ".TrnAgeAgenda"
			_oSQL:_sQuery +=    " set TrnAgeAgendaSit = '" + _sStatPara + "'"
			_oSQL:_sQuery +=  " where TrnAgeAgendaOri = " + cValToChar (_aRusInsp [.InspecoesSafraAgendaOri])
			_oSQL:Log ()
			_oSQL:Exec ()
		else
			u_log ('Nao vou alterar a situacao da inspecao para ' + _sStatPara + ' por que encontra-se com situacao ' + _aRusInsp [.InspecoesSafraSituacao] + ' (na chamada da funcao foi especificado que somente devo alterar se for ' + _sStatDe + ').')
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
