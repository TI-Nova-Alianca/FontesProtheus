// Programa...: MA330Fim
// Autor......: Robert Koch
// Data.......: 10/10/2017
// Descricao..: P.E. apos o termino do recalculo do custo medio.
//              Criado inicialmente para ajustar campo 'origem' da contabilizacao.
//              conforme era feito no CUSMED.prw.
//
// Historico de alteracoes:
// 28/07/2018 - Robert  - Gravacao do campo B1_VACUSTR.
// 04/12/2018 - Robert  - Chama o U_CtbMedio() em lugar de static function para ajustar o campo CT2_ROTINA.
// 26/08/2019 - Robert  - Atualizava o campo B2_VACUSTR apenas para a filial atual, desconsiderando as demais quando roda o calculo consolidado.
// --------------------------------------------------------------------------
user function MA330FIM ()
	local _aAreaAnt := U_ML_SRArea ()

	Processa({|| U_CtbMedio (.T.)}, "Ajustando lctos contabeis")

	// Libera semaforo que deve ter sido criado no P.E. MA330OK
	if type ("_nLock") == 'N' .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

	// Atualiza no SB2 o valor para transferencia entre filiais.
	_AtuSB2 ()

	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Atualiza no SB2 o valor para transferencia entre filiais.
static function _AtuSB2 ()
	local _oSQL   := NIL
	
  	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "UPDATE " + RetSQLName ("SB2")
	_oSQL:_sQuery +=       " SET B2_VACUSTR = ROUND (B2_VFIM1 / B2_QFIM, 4)"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND B2_QFIM    > 0"
	if mv_par20 == 1  // Apenas a filial atual
		_oSQL:_sQuery +=   " AND B2_FILIAL  = '" + xfilial ("SB2") + "'"
	endif
	_oSQL:Log ('[' + procname () + ']')
	if ! _oSQL:Exec ()
		U_help ("Erro atualizando custo para transferencia. SQL: " + _oSQL:_sQuery)
	endif
return
