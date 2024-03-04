// Programa...: NxtZA1
// Autor......: Robert Koch
// Data.......: 04/12/2014
// Descricao..: Gera numero da proxima etiqueta de pallet.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processamento
// #Descricao         #Gera numero da proxima etiqueta de pallet.
// #PalavasChave      #sequencial #etiqueta #proxima #gera_numeracao
// #TabelasPrincipais #ZA1
// #Modulos           #EST #PCP

// Historico de alteracoes:
// 19/07/2017 - Robert - Faixa de numeracao do Full so podia iniciar por 9. Agora aceita entre 1 e 9.
// 20/07/2017 - Robert - Faixa de numeracao do Full so passa a ser entre 2 e 9.
// 15/12/2017 - Robert - Faltava nome do campo na chamada da funcao GetSXeNum ()
// 12/04/2023 - Robert - Implementado controle de semaforo (inclusive externo).
// 04/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------
user function NxtZA1 (_sProduto, _lSemafExt)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sRet      := ""
	local _oSQL      := NIL
	local _lContinua := .T.
	local _nLock     := 0

	_lSemafExt := iif (_lSemafExt == NIL, .F., _lSemafExt)

	// Controla semaforo de gravacao, por que a numeracao deve ser unica.
	//
	// Se a funcao chamadora jah implementou um semaforo de gravacao, nao
	// preciso mais me preocupar aqui.
	if _lContinua .and. ! _lSemafExt  // Semaforo nao foi criado externamente.
//		U_Log2 ('debug', '[' + procname () + ']Semaforo externo: ainda nao tem. Vou criar um agora.')
		_nLock := U_Semaforo ('GeraNumeroZA1', .T.)  // Usar a mesma chave em todas as chamadas!
		if _nLock == 0
			u_help ("Bloqueio de semaforo na geracao de numero de etiqueta.",, .t.)
			_lContinua = .F.
		endif
//	else
//		U_Log2 ('debug', '[' + procname () + ']Semaforo externo: jah tem.')
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Cadastro do produto '" + _sProduto + "' nao localizado.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Itens da Fullsoft geram "codigo de pallet".
		// No inicio da operacao comecamos a gerar as etiquetas iniciando por 9, mas em
		// 19/07/2017 a nova versao do FullWMS permitiu gerar qualquer numero acima de 0
		// entao
		if sb1 -> b1_vafullw == 'S'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT MAX (ZA1_CODIGO)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA1") + " ZA1 "
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND ZA1_FILIAL = '" + xfilial ("ZA1") + "'"
			_oSQL:_sQuery +=    " AND ZA1_CODIGO between '2000000000' and '8999999998'" // Quando atingir 8999999999 aumentar este parametro para 9999999999 para usar o restante da sequencia 9.
			//_oSQL:Log ()
			_sRet = _oSQL:RetQry (1, .f.)
			if _sRet > '8999999997'
				U_help ("A sequencia de numeracao de pallets para Fullsoft terminou. Verifique!")
				U_AvisaTI ("A sequencia de numeracao de pallets para Fullsoft terminou. Verifique!")
			else
				if empty (_sRet)
					_sRet = '2000000000'
				endif
				if _sRet > '8999999000'
					u_help ("Sequencia de numeracao de etiquetas proxima do fim! Solicite manutencao.")
				endif
				_sRet = soma1 (_sRet)
			endif
		else
			_sRet = GETSX8NUM("ZA1", "ZA1_CODIGO")
		endif
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	U_ML_SRArea (_aAreaAnt)
return _sRet
