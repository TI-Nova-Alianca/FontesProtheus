// Programa...: VA_RUS1P
// Autor......: Robert Koch
// Data.......: 04/01/2017
// Descricao..: Primeira pesagem (jah apos a inclusao da carga)
//
// Historico de alteracoes:
// 09/01/2018 - Gravacao tabela ZZA
// 20/01/2020 - Robert - Novos parametros chamada geracao ticket safra.
// 31/01/2020 - Robert - Atualiza sistema de agendamento com status de 'LIB' (significa que jah encontra-se 'pesado e liberado para descarga'.
// 01/02/2020 - Robert - Sobreescrevia inspecoes quando chamado a partir da rotina de portaria.
// 21/02/2020 - Robert - Alteracoes na tabela ZZA passam a ser feitas em rotina externa (U_AtuZZA).
// 11/03/2022 - Robert - Novos parametros funcao U_VA_RusLI() - GLPI 11745.
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function va_rus1P (_lPortaria)
	local _lContinua   := .T.
	local _aAreaAnt    := U_ML_SRArea ()
	private _nPLidoBal := 0  // Deixar private senao a funcao MsgRun nao altera.
	
	u_log2 ('info', '[' + procname () + '][Carga:' + sze -> ze_carga + ']   Assoc:' + sze -> ze_assoc + '/' + sze -> ze_lojasso)
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif

	_lPortaria = iif (_lPortaria == NIL, .F., _lPortaria)
	
	// Nao posso estragar a variavel caso ela venha populada de rotinas anteriores.
	if type ("_aRusInsp") != 'A'
		private _aRusInsp  := {}  // Deixar private para ser vista e alimentada por outras rotinas.
	endif

	if _lContinua .and. sze -> ze_pesotar != 0
		u_help ("Segunda pesagem ja realizada.",, .t.)
		_lContinua = .F.
	endif

	// Verifica situacao do agendamento / inspecoes.
	if _lContinua
		if ! IsInCallStack ("U_VA_CPORT")  // Se chamado a partir da portaria, a leitura das inspecoes jah foi feita.
			_lContinua = U_VA_RusLI (1, .f.)
		endif
	endif

	// Se nao estou dentro da rotina de portaria, preciso buscar (e tratar) o peso.
	if ! _lPortaria
		if _lContinua
			if _lBalEletr
				MsgRun ("Aguarde, lendo dados da balanca", "Leitura balanca", {|| _nPLidoBal := U_LeBalan (_sPortaBal, _sModelBal)})
			else
				_nPLidoBal = U_Get ("Sem comunic.c/balanca. Informe peso (Kg) manualmente", 'N', 6, '999999', '', sze -> ze_pesobru, .F., '.T.')
			endif
		endif
	
		if _lContinua .and. _nPLidoBal != NIL .and. _nPLidoBal > 0
			// Faz arredondamento cfe. parametrizacao do usuario.
			_nPLidoBal = round (_nPLidoBal / _nMultBal, 0)
			_nPLidoBal *= _nMultBal
		
			reclock ("SZE", .F.)
			sze->ze_pesoBru = _nPLidoBal
			msunlock ()
	
			if _lImpTick .and. _lTickPeso .and. ! _lIntPort
				U_VA_RUSTk (1, _sPortTick, _nQViasTk1, {}, 'Bematech', .t.)
			endif
		endif
	endif

	// Atualiza itens da carga (SZF) e status para medicao de grau (ZZA).
	if _lContinua
		U_Log2 ('debug', '[' + procname () + '][Carga:' + sze -> ze_carga + ']Chamando AtuZZA')
		U_AtuZZA (sze -> ze_safra, sze -> ze_carga)
	endif

	// Atualiza sistema de agendamento com status de 'LIB' (significa que jah encontra-se 'pesado e liberado para descarga'.
	if _lContinua .and. sze->ze_pesoBru > 0
		U_VA_RusAI ('INS/AGE', 'LIB')
	endif

	U_ML_SRArea (_aAreaAnt)
return
