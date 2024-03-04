// Programa:  RetZX5
// Autor:     Robert Koch
// Data:      10/03/2011
// Descricao: Retorna campos da tabela ZX5.
//
// Historico de alteracoes:
// 16/05/2012 - Robert - Criado tratamento para a tabela 12.
// 21/03/2012 - Robert - Criado tratamento para tabelas 23 a 34.
// 19/05/2016 - Robert - Procura sempre pelo campo <Tabela> + 'COD' por default.
// 08/07/2019 - Robert - Criado tratamento para a tabela 02.
// 04/01/2020 - Robert - Criado tratamento para a tabela 52.
// 03/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------
User Function RetZX5 (_sTabela, _sChave, _sCampo)
	local _aAreaAnt := U_ML_SRArea ()
	local _sFilial  := ""
	local _xRet     := NIL
	local _sCpoChav := ""
	local _oSQL     := NIL
	local _nCpoCod  := 0

//	u_log ('[' + procname () + '] ', _sTabela, _sChave, _sCampo)

	if _sCampo == NIL .or. zx5 -> (fieldpos (_sCampo)) == 0
		u_help ("Campo '" + cvaltochar (_sCampo) + "' inexistente na tabela ZX5.")
	else

		// Verifica se a tabela em compartilhada ou exclusiva.
		zx5 -> (dbsetorder (1))  // ZX5_FILIAL+ZX5_TABELA+ZX5_CHAVE
		if ! zx5 -> (dbseek ("  " + "00" + _sTabela, .F.))
			u_help ("Tabela '" + _sTabela + "' nao cadastrada no arquivo ZX5.")
			_lRet = .F.
		else
			_sFilial  = iif (zx5 -> zx5_modo == "C", "  ", cFilAnt)
			
			// Se tem indice especifico para esta tabela, usa-o. Senao, busca via query.
			if U_TemNick ("ZX5", "TAB" + _sTabela)
				zx5 -> (DBOrderNickName ("TAB" + _sTabela))
				if zx5 -> (dbseek (_sFilial + _sTabela + _sChave, .F.))
					_xRet = zx5 -> &(_sCampo)
				endif
			else
				// Determina o campo chave conforme a tabela em questao.
				_sCpoChav = ""
				do case
					case _sTabela == '02'
						_sCpoChav = 'ZX5_02MOT'
					case _sTabela == '09'
						_sCpoChav = 'ZX5_09SAFR + ZX5_09LOCA'
					case _sTabela == '11'
						_sCpoChav = 'ZX5_11SAFR + ZX5_11COD'
					case _sTabela == '13'
						_sCpoChav = 'ZX5_13SAFR + ZX5_13GRUP'
					case _sTabela == '15'
						_sCpoChav = 'ZX5_15PLAN + ZX5_15COD'
					case _sTabela == '16'
						_sCpoChav = 'ZX5_16PLAN + ZX5_16ITEM'
					case _sTabela == '20'
						_sCpoChav = 'ZX5_20CRQ'
					case _sTabela == '52'
						_sCpoChav = 'ZX5_52SAFR + ZX5_52GRUP'
					otherwise
						// Procura campo 'COD' na tabela, pois atende a maioria dos casos.
						_sCpoChav = 'ZX5_' + _sTabela + 'COD'
	 					_nCpoCod = zx5 -> (fieldpos (_sCpoChav))
	 					if _nCpoCod = 0
	 						_sCpoChav = ''
		 					u_AvisaTI ("Tabela '" + _sTabela + "' nao prevista no programa " + procname () + ". Verificacao da chave '" + _sChave + "' nao sera possivel.")
							u_help ("Tabela nao prevista no programa " + procname () + ". Verificacao do campo nao sera possivel.")
							_lRet = .F.
						endif
				endcase
	
				if ! empty (_sCpoChav)
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " select " + upper (alltrim (_sCampo))
					_oSQL:_sQuery += "   from " + RetSQLName ("ZX5")
					_oSQL:_sQuery += "  where D_E_L_E_T_ = ''"
					_oSQL:_sQuery += "    and ZX5_FILIAL = '" + _sFilial + "'"
					_oSQL:_sQuery += "    and ZX5_TABELA = '" + _sTabela + "'"
					_oSQL:_sQuery +=    " AND " + _sCpoChav + " = '" + _sChave + "'"
					//_oSQL:Log ()
					_xRet = _oSQL:RetQry (1, .f.)
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _xRet
