// Programa...: VA_RUSLP
// Autor......: Robert Koch
// Data.......: 25/12/2011
// Cliente....: Nova Alianca
// Descricao..: Tela de leitura de parametros de recebimento de safra.
//              Foi criado um programa separado para possibilitar a releitura
//              dos parametros sem sair da tela.
//
// Historico de alteracoes:
// 12/01/2016 - Robert - Criado local de entrega GB (Vinicola Garibaldi) ligado a filial 01.
// 13/12/2019 - Robert - Adequacoes iniciais para safra 2020 (porta impressora ticket).
// 03/02/2021 - Robert - Criado parametro para mostrar ou nao as perguntas para o usuario.
// 28/10/2022 - Robert - Removidos alguns parametros em desuso.
// 07/12/2022 - Robert - Removidos mais alguns parametros em desuso.
// 10/02/2024 - Robert - Varieval _lLeBrix (par.11) desabilitada (assume default .T.)
//

// --------------------------------------------------------------------------
User Function VA_RUSLP (_lMostra)
	local _lRet := .T.

	if ! _lMostra
		pergunte (cPerg, _lMostra)
	else
		if ! pergunte (cPerg, _lMostra)
			U_Log2 ('aviso', '[' + procname () + ']Usuario cancelou a tela de parametros.')
			_lRet = .F.
		endif
	endif
	if _lRet
		u_logsx1 (cPerg)

		// Passa dados para variaveis especificas, pois algumas rotinas posteriores
		// usarao os nomes das variaveis padrao de parametros.
		_sBalanca  = mv_par01
		_lLeitBar  = (mv_par02 == 1)
		_lBalEletr = (mv_par03 == 1)
		_sPortaBal = mv_par04
		_sModelBal = iif (_oCarSaf:Filial == '01', 'Saturno', iif (_oCarSaf:Filial == '07', 'Digitron', ''))
		_nMultBal  = 10
		_ZFEMBALAG = iif (_oCarSaf:CXouGranel == 'G', 'GRANEL', iif (_oCarSaf:CXouGranel == 'C', 'CAIXAS', ''))  //{'GRANEL', 'CAIXAS'} [mv_par07]
		_nPesoEmb  = 21  // Peso por caixa aprox 21 Kg
	//	_lLeBrix   = (mv_par11 == 1)
		_nQViasTk1 = 1
		_nQViasTk2 = 2
		_lIntPort  = (cFilAnt == '01')
		_oCarSaf:Log ()
		if ! _oCarSaf:Filial $ '01/03/07'
			u_help ("Filial nao autorizada a receber safra.")
			_lRet = .f.
		endif
	endif
	if _lRet
		_lRet = _oCarSaf:DefImprTk (cFilAnt, alltrim (U_RetZX5 ('49', mv_par10, 'ZX5_49CAM')))
	endif

return _lRet
