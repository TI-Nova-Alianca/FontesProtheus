// Programa:  CTB390LOk
// Autor:     Robert Koch
// Data:      17/03/2016
// Descricao: P.E. 'Linha OK' da tela de orcamentos contabeis.
//
// Historico de alteracoes:
// 05/04/2016 - Robert - Verifica sobreposicao de intervalos de conta + CC
//

// --------------------------------------------------------------------------
user function CTB390LOk ()
	local _lRet    := .T.
	local _nReg    := 0
	local _sCT1Ini := ""
	local _sCT1Fim := ""
	local _sCTTIni := ""
	local _sCTTFim := ""
	local _sSeq    := tmp -> cv1_sequen

	// Pretendemos trabalhar com uma conta e um CC por linha.
	if _lRet .and. ! tmp -> cv1_flag  // Linha nao deletada
		if tmp -> cv1_ct1ini > tmp -> cv1_ct1fim
			u_help ("Verificando seq. " + _sSeq + ": Conta final menor que inicial.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. ! tmp -> cv1_flag  // Linha nao deletada
		if tmp -> cv1_cttini > tmp -> cv1_cttfim
			u_help ("Verificando seq. " + _sSeq + ": Centro de custo final menor que inicial.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. ! tmp -> cv1_flag  // Linha nao deletada
		if tmp -> cv1_ct1ini != tmp -> cv1_ct1fim
			u_help ("Verificando seq. " + _sSeq + ": Conta final deve ser igual `a conta inicial.")
			_lRet = .F.
		endif
	endif
	
	// Verifica linhas iguais / sobreposicao.
	if _lRet .and. ! tmp -> cv1_flag  // Linha nao deletada
		_nReg = tmp -> (recno ())
		_sCT1Ini = tmp -> cv1_ct1ini
		_sCT1Fim = tmp -> cv1_ct1fim
		_sCTTIni = tmp -> cv1_cttini
		_sCTTFim = tmp -> cv1_cttfim
		tmp -> (dbgotop ())
		do while ! tmp -> (eof ())
			if tmp -> (recno ()) != _nReg .and. ! tmp -> cv1_flag  // Linha nao deletada
				if tmp -> cv1_ct1ini == _sCT1Ini .and. tmp -> cv1_cttini == _sCTTIni // .and. ! tmp -> cv1_flag  // Linha nao deletada
					u_help ("Verificando seq. " + _sSeq + ": Combinacao conta / CC " + alltrim (_sCT1Ini) + " X " + alltrim (_sCTTIni) + " ja informada na sequencia " + tmp -> cv1_sequen)
					_lRet = .F.
					exit
				endif
			
				if   (tmp -> cv1_CT1INI + tmp -> cv1_cttini <= _sCT1Ini + _sCTTIni .and. tmp -> cv1_CT1FIM + tmp -> cv1_cttfim >= _sCT1Ini + _sCTTIni) ;
				.or. (tmp -> cv1_CT1FIM + tmp -> cv1_cttfim >= _sCT1Ini + _sCTTIni .and. tmp -> cv1_CT1INI + tmp -> cv1_cttini <= _sCT1Fim + _sCTTFim) ;
				.or. (tmp -> cv1_CT1INI + tmp -> cv1_cttini <= _sCT1Fim + _sCTTFim .and. tmp -> cv1_CT1INI + tmp -> cv1_cttini >= _sCT1Fim + _sCTTFim)
					u_help ("Verificando seq. " + _sSeq + ": Intervalo de conta + CC tem sobreposicao com a sequencia " + tmp -> cv1_sequen)
					_lRet = .F.
					exit
				endif
			endif
			tmp -> (dbskip ())
		enddo
		tmp -> (dbgoto (_nReg))
	endif

return _lRet
