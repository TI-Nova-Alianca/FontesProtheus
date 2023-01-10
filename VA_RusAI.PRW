// Programa...: VA_RUSAI
// Autor......: Robert Koch
// Data.......: 12/02/2020
// Descricao..: Atualiza sistema de agenda/inspecoes (desmembrado do VA_RUS1P)
//
// Historico de alteracoes:
// 11/03/2022 - Robert - Novos parametros funcao U_VA_RusLI() - GLPI 11745.
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function va_rusAI (_sStatDe, _sStatPara)
	local _lContinua   := .T.
	local _aAreaAnt    := U_ML_SRArea ()
//	local _sLinkSrv    := U_LkServer ('NAWEB')

	u_Log2 ('info', 'Iniciando ' + procname ())

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	// Nao posso estragar a variavel caso ela venha populada de rotinas anteriores.
	if _lContinua
		if type ("_aRusInsp") != 'A' .or. len (_aRusInsp) < .InspecoesSafraQtColunas
			private _aRusInsp  := {}  // Deixar private para ser vista e alimentada por outras rotinas.
			_lContinua = U_VA_RusLI (1, .f.)
		endif
	endif

	if _lContinua
		if _aRusInsp [.InspecoesSafraSituacao] $ _sStatDe
			/*
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE " + _sLinkSrv + ".TrnAgeAgenda"
			_oSQL:_sQuery +=    " set TrnAgeAgendaSit = '" + _sStatPara + "'"
			_oSQL:_sQuery +=  " where TrnAgeAgendaOri = " + cValToChar (_aRusInsp [.InspecoesSafraAgendaOri])
			_oSQL:Log ()
			_oSQL:Exec ()
			*/
			if ! _oCarSaf:AtuAgenda (_sStatPara)
				U_Log2 ('erro', '[' + procname () + ']Ao tentar atualizar a agenda de ' + _sStatDe + ' para ' + _sStatPara + ' retornou erro: ' + _oCarSaf:UltMsg,, .t.)
			endif
		else
			u_log2 ('info', '[' + procname () + '] Nao vou alterar a situacao da inspecao para ' + _sStatPara + ' por que encontra-se com situacao ' + _aRusInsp [.InspecoesSafraSituacao] + ' (na chamada da funcao foi especificado que somente devo alterar se for ' + _sStatDe + ').')
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
