// Programa...: NxtZA1
// Autor......: Robert Koch
// Data.......: 04/12/2014
// Descricao..: Gera numero da proxima etiqueta de pallet.
//
// Historico de alteracoes:
// 19/07/2017 - Robert - Faixa de numeracao do Full so podia iniciar por 9. Agora aceita entre 1 e 9.
// 20/07/2017 - Robert - Faixa de numeracao do Full so passa a ser entre 2 e 9.
// 15/12/2017 - Robert - Faltava nome do campo na chamada da funcao GetSXeNum ()
//

// --------------------------------------------------------------------------
user function NxtZA1 (_sProduto)
	local _aAreaAnt := U_ML_SRArea ()
	local _sRet     := ""
	local _oSQL     := NIL
//	u_logIni ()
		
	sb1 -> (dbsetorder (1))
	if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))

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
//			_oSQL:_sQuery +=    " AND ZA1_CODIGO LIKE '9%'"
			_oSQL:_sQuery +=    " AND ZA1_CODIGO between '2000000000' and '8999999998'" // Quando atingir 8999999999 aumentar este parametro para 9999999999 para usar o restante da sequencia 9.
			//_oSQL:Log ()
			_sRet = _oSQL:RetQry ()
			//if empty (_sRet)
			//	_sRet = '9000000000'
			//endif
			//if _sRet >= '9099999999'
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

	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return _sRet
