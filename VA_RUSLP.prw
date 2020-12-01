// Programa...: VA_RUSLP
// Autor......: Robert Koch
// Data.......: 25/12/2011
// Cliente....: Nova Alianca
// Descricao..: Tela de leitura de parametros de recebimento de safra.
//              Foi criado um programa separado para possibilitar a releitura
//              dos parametros sem sair da tela.
//
// Historico de alteracoes:
// 12/01/2016 - Criado local de entrega GB (Vinicola Garibaldi) ligado a filial 01.
// 13/12/2019 - Robert - Adequacoes iniciais para safra 2020 (porta impressora ticket).
//

// --------------------------------------------------------------------------
User Function VA_RUSLP ()
	local _lRet := .F.

	do while .T.
		if ! pergunte (cPerg, .T.)
			exit
		endif

		u_logsx1 (cPerg)

		// Passa dados para variaveis especificas, pois algumas rotinas posteriores
		// usarao os nomes das variaveis padrao de parametros.
		_sBalanca  = mv_par01
		_lLeitBar  = (mv_par02 == 1)
		_lBalEletr = (mv_par03 == 1)
		_sPortaBal = mv_par04
		_sModelBal = {'Digitron', 'Toledo', 'Saturno'}[mv_par05]
		_nMultBal  = mv_par06
		_ZFEMBALAG = {'GRANEL', 'CAIXAS'} [mv_par07]
		_nPesoEmb  = mv_par08
		_lImpTick  = (mv_par09 == 1)
		_sPortTick = iif (_lImpTick, U_RetZX5 ('49', mv_par10, 'ZX5_49CAM'), '')
		_lLeBrix   = (mv_par11 == 1)
		_nQViasTk1 = mv_par12
		_nQViasTk2 = mv_par13
		_lTickPeso = (mv_par14 == 1)
		_lIntPort  = (mv_par15 == 1)

		// Verifica parametros
		if _nMultBal != 5 .and. _nMultBal != 10
			if _sBalanca != "LV"  // Livramento precisa fazer as divisoes do condominio.
				u_help ("Peso multiplo balanca invalido para esta balanca")
				loop
			endif
		endif
		if _xSAFRAJ <= '2014'
			if (cEmpAnt + cFilAnt == '0101' .and. ! _sBalanca $ 'AL/QL/GS') ;
				.or. (cEmpAnt + cFilAnt == '0103' .and. ! _sBalanca $ 'LV') ;
				.or. (cEmpAnt + cFilAnt == '0107' .and. ! _sBalanca $ 'JC') ;
				.or. (cEmpAnt + cFilAnt == '0109' .and. ! _sBalanca $ 'SP') ;
				.or. (cEmpAnt + cFilAnt == '0110' .and. ! _sBalanca $ 'SA') ;
				.or. (cEmpAnt + cFilAnt == '0111' .and. ! _sBalanca $ 'NP') ;
				.or. (cEmpAnt + cFilAnt == '0112' .and. ! _sBalanca $ 'PB/AP') ;
				.or. (cEmpAnt + cFilAnt == '0113' .and. ! _sBalanca $ 'LB')
				u_help ("Balanca invalida para esta filial ou filial nao autorizada a receber safra.")
				loop
			endif
		else
			if (cEmpAnt + cFilAnt == '0101' .and. ! _sBalanca $ 'LB/QL/GS/GB') ;
				.or. (cEmpAnt + cFilAnt == '0103' .and. ! _sBalanca $ 'LV') ;
				.or. (cEmpAnt + cFilAnt == '0107' .and. ! _sBalanca $ 'JC') ;
				.or. (cEmpAnt + cFilAnt == '0109' .and. ! _sBalanca $ 'SP') ;
				.or. (cEmpAnt + cFilAnt == '0110' .and. ! _sBalanca $ 'SA') ;
				.or. (cEmpAnt + cFilAnt == '0111' .and. ! _sBalanca $ 'NP') ;
				.or. (cEmpAnt + cFilAnt == '0112' .and. ! _sBalanca $ 'PB/AP') ;
				.or. (cEmpAnt + cFilAnt == '0113' .and. ! _sBalanca $ 'AL')
				u_help ("Balanca invalida para esta filial ou filial nao autorizada a receber safra.")
				loop
			endif
		endif
		
		if _nMultBal < 1
			u_help ("Peso multiplo para balanca nao pode ser menor que 1 Kg")
			loop
		endif
		
		_lRet = .T.
		exit
	enddo
	u_log2 ('debug', 'parametros lidos. porta de ticket >>' + _sPortTick + '<<')
return _lRet
