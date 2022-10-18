// Programa...: MT250GrEst
// Autor......: Robert Koch
// Data.......: 15/12/2014
// Descricao..: P.E. apos gravacao do estorno de apontamento de producao.
//              Criado inicialmente para atualizar arquivo de etiquetas.
//
// Historico de alteracoes:
// 17/08/2018 - Robert - Grava evento de estorno, se existir.
// 05/10/2022 - Robert - Eliminados alguns logs
//

// ----------------------------------------------------------------
user function MT250GrEst ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()

	_AtuZA1 ()

	// Verifica se deve gravar evento gerado em P.E. anterior.
	if type ('_oEvtEstF') == 'O'
		_oEvtEstF:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet



// --------------------------------------------------------------------------
static function _AtuZA1 ()
	if ! empty (sd3 -> d3_vaetiq)
		za1 -> (dbsetorder (1))  // ZA1_FILIAL+ZA1_CODIGO+ZA1_DATA+ZA1_OP
		if za1 -> (dbseek (xfilial ("ZA1") + sd3 -> d3_vaetiq, .F.))
			U_Log2 ('info', '[' + procname () + ']Estornando etiqueta ' + sd3 -> d3_vaetiq)
			reclock ("ZA1", .F.)
			za1 -> za1_apont = 'E'
			msunlock ()
		endif
	endif
return
