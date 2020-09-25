// Programa:  PrecoUva
// Autor:     Robert Koch
// Data:      26/01/2009
// Descricao: Retorna os diferentes precos da uva, conforme tabelas SA2, SZA e SZ1.
//
// Historico de alteracoes:
// 25/06/2009 - Robert - Calcula % de desconto ou acrescimo do preco de compra para uvas finas.
// 29/10/2009 - Robert - Passa a usar a funcao U_Help em vez de msgalert.
// 19/01/2009 - Robert - Nao verificava se a lista de precos se referia `a safra solicitada.
// 20/01/2010 - Robert - Criada tabela SZ2 (lista preco X fornecedor X safra)
// 17/05/2010 - Robert - Nao considerava classif.uvas finas no calc.descontos preco recebimento.
// 07/07/2010 - Robert - Acrescentado dbSelectArea apenas para evitar erros de 'Alias does not exist'.
// 04/01/2011 - Robert - Busca amarracao fornecedor X safra no SZ7 e nao mais no SZ2.
// 20/05/2014 - Robert - Criado tratamento para classificacao ABD de uvas finas.
// 18/04/2017 - Robert - Incluido tratamento para precificacao (compra) de viniferas desclassificadas na serra.
//                     - Novo parametro para indicar qual o preco desejado.
// 27/03/2018 - Robert - Regras para preco de compra safra 2018.
//

// --------------------------------------------------------------------------
user function PrecoUva (_sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse, _sClasABD, _sQualPrc, _sFilial)
	local _aAreaAnt  := U_ML_SRArea ()
	local _nRet      := 0
	local _nPrcRec   := 0
	local _nPrcCom   := 0
	local _lContinua := .T.
	local _lTabDS    := .F.
	local _nGMinB    := 0
	local _nGMinT    := 0
	local _sTabDS    := ''
	local _sGrpDS    := ''

	//u_log ('Buscando preco:', _sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse, _sClasABD, _sQualPrc, _sFilial)

	if _sSafra >= '2018' .AND. _sQualPrc == 'C'
		u_help ('Revisar U_PRECOUVA por que nao foram corretamente considerados os precos de compra 2018 para uva em espaldeira. Eu simplesmente considerei a filial 03, mas existem associados plantando em espaldeira na serra.')
	endif

	if _sSafra > '2018' .AND. _sQualPrc == 'C'
		u_help ("Revisar U_PRECOUVA para esta safra, pois em 2018 foi incluido tratamento para precificacao (compra) de viniferas desclassificadas na serra")
	endif

	// Para evitar erros desagradaveis de 'alias does not exist' quando a funcao chamadora for mal feita.
	dbselectarea ("SA2")

	// A partir de 2014 teremos o grau com uma casa decimal, mas as tabelas de precos variam em 0.5 graus.
	if _sSafra >= '2014' .and. at ('.', _sGrau) == 0
		u_help ("Para esta safra o grau deve ser informado com ponto decimal")
		_lContinua = .F.
	endif
	
	if _lContinua
		do case
			case right (_sGrau, 1) $ '012'
				_sGrau = substr (_sGrau, 1, len (_sGrau) - 1) + '0'
			case right (_sGrau, 1) $ '34567'
				_sGrau = substr (_sGrau, 1, len (_sGrau) - 1) + '5'
			case right (_sGrau, 1) $ '89'
				_sGrau = strzero (val (substr (_sGrau, 1, 2)) + 1, 2) + '.0'
		endcase
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Produto '" + _sProduto + "' nao encontrado.")
			_lContinua = .F.
		endif
	endif

	// Nao foi feita classificacao de uvas na serra nesta safra.
	if _lContinua .and. _sQualPrc == 'C' .and. _sSafra == '2017'
		_sClasABD = ''
	endif

	if _lContinua

		// Preco de compra: antes de mais nada verifica se eh um caso de uva desclassificada na regiao da serra.
		if _sQualPrc == 'C' .and. _sFilial != '03' .and. _sSafra >= '2015'

			// Viniferas recebidas na matriz e F09: precifica sempre a preco de isabel (tintas) ou niagara (brancas)
			if sb1 -> b1_varuva == 'F' .and. _sFilial $ '01/09'
				u_log ('vinifera entregue em Flores')
				_lTabDS = .T.  // Para nao fazer leituras posteriores de outras tabelas.
				_sTabDS = ''
				do case
				case _sSafra == '2018'
					_sTabDS = '002018'
				otherwise
					u_log ('Tabela nao definida para viniferas recebidas na matriz.')
				endcase
				if ! empty (_sTabDS)
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT Z1_PRCCOM"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZ1") + " SZ1 "
					_oSQL:_sQuery +=  " WHERE SZ1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_FILIAL   = '" + xFilial ("SZ1") + "'"
					_oSQL:_sQuery +=    " AND SZ1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_TABELA   = '" + _sTabDS + "'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_CODPRD   = '" + iif (sb1 -> b1_vacor == 'T', '9901', '9904') + "'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_GRAU     = '" + _sGrau + "'"
					_oSQL:Log ()
					_nRet = _oSQL:RetQry ()
				endif

			else
			
				// Mesmo que tenham sido recebidas como 'finas com classificacao' as uvas da serra serao precificadas como 'finas sem classificacao'.
				if sb1 -> b1_varuva == 'F' .and. sb1 -> b1_vaFCUva == 'F'
					_sProduto = u_tamfixo (alltrim (_sProduto) + 'A', 15, ' ')
					u_log ('Variedade vai ser precificada como sem classificacao (' + alltrim (_sProduto) + ')')
	
					// Reposiciona SB1 apos troca de codigo de produto.
					sb1 -> (dbsetorder (1))
					if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
						u_help ("Produto '" + _sProduto + "' nao encontrado apos troca para 'sem classificacao'.")
						_lContinua = .F.
					endif
				endif
	
				do case
				case _sSafra == '2015'
					_nGMinB = 12  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
					_nGMinT = 14  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
					_sTabDS = 'BASE15'
					_sGrpDS = '221'
				case _sSafra == '2016'
					_nGMinB = 11  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
					_nGMinT = 13  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
					_sTabDS = 'BASE16'
					_sGrpDS = '221'
				case _sSafra == '2017'
					_nGMinB = 10  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
					_nGMinT = 12  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
					_sTabDS = 'BASE17'
					_sGrpDS = '221'
				case _sSafra >= '2018'
					_nGMinB = 11  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
					_nGMinT = 14  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
					_sTabDS = 'DESC18'
					_sGrpDS = '000'
				otherwise
					u_help ("Tabela de preco para uvas desclassificadas nao foi encontrada para esta safra. Sugere-se cadastrar com nome DESC + AA onde AA=ano safra.")
					_lContinua = .F.
				endcase
	
				//u_log (_nGMinB, _nGMinT, _sTabDS, _sGrpDS)
	
				// Grau abaixo do minimo ou desclassificadas busca de tabela fixa.
				if _lContinua
					_lTabDS = .F.
					if sb1 -> b1_varuva == 'F'
						if sb1 -> b1_vaFCUva == 'F' .and. (alltrim (_sClasse) $ 'D/DS' .or. alltrim (_sClasABD) $ 'D')
							u_log ('Desclassificada')
							_lTabDS = .T.
						endif
						if sb1 -> b1_vacor $ 'B/R' .and. val (_sGrau) < _nGMinB
							u_log ('Abaixo do grau minimo')
							_lTabDS = .T.
						endif
						if sb1 -> b1_vacor $ 'T' .and. val (_sGrau) < _nGMinT
							u_log ('Abaixo do grau minimo')
							_lTabDS = .T.
						endif
					endif
	
					//u_log (_lTabDS)
	
					if _lTabDS
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " SELECT Z1_PRCCOM"
						_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZ1") + " SZ1 "
						_oSQL:_sQuery +=  " WHERE SZ1.D_E_L_E_T_ != '*'"
						_oSQL:_sQuery +=    " AND SZ1.Z1_FILIAL   = '" + xFilial ("SZ1") + "'"
						_oSQL:_sQuery +=    " AND SZ1.D_E_L_E_T_ != '*'"
						_oSQL:_sQuery +=    " AND SZ1.Z1_TABELA   = '" + _sTabDS + "'"
						_oSQL:_sQuery +=    " AND SZ1.Z1_CODPRD   = '" + _sGrpDS + "'"
						_oSQL:_sQuery +=    " AND SZ1.Z1_GRAU     = '" + _sGrau + "'"
						_oSQL:Log ()
						_nRet = _oSQL:RetQry ()
					endif
				endif
			endif
		endif
	endif

	//u_log ('_lTabDS:', _lTabDS)
	
	if _lContinua .and. !_lTabDS
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + _sFornece + _sLoja, .F.))
			u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao encontrado.")
		else
			sz7 -> (dbsetorder (1))  // Z7_FILIAL+Z7_FORNECE+Z7_LOJA+Z7_SAFRA
			if ! sz7 -> (dbseek (xfilial ("SZ7") + _sFornece + _sLoja + _sSafra, .F.))
				u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao amarrado `a safra '" + _sSafra + "'")
			else
				sza -> (dbsetorder (1))
				if ! sza -> (dbseek (xfilial ("SZA") + sz7 -> z7_tabprc, .F.))
					u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao foi encontrada!")
				else
					if sza -> za_safra != _sSafra
						u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao se refere a essa safra")
					else
						sz1 -> (dbsetorder (1))
						if ! sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto + _sGrau, .F.))
							u_help ("Preco nao encontrado para variedade '" + _sProduto + "' e grau '" + _sGrau + "' na tabela '" + sza -> za_cod + "'. Verifique tabelas de precos de safra.")
						else
	
							_nPrcRec = sz1 -> z1_prcrec
							_nPrcCom = sz1 -> z1_prccom
	
							// O preco de compra, para uvas finas, varia conforme a sua classificacao final.
							if sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "F"
								do case
								case alltrim (_sClasse) == "AA"
									_nPrcRec *= 1.4
									_nPrcCom *= 1.4
								case alltrim (_sClasse) == "A"
									_nPrcRec *= 1.2
									_nPrcCom *= 1.2
								case alltrim (_sClasse) == "B"
									_nPrcRec *= 1
									_nPrcCom *= 1
								case alltrim (_sClasse) == "C"
									_nPrcRec *= 0.8
									_nPrcCom *= 0.8
								case alltrim (_sClasse) == "D"
									_nPrcRec *= 0.6
									_nPrcCom *= 0.6
								case alltrim (_sClasse) == "DS"
									_nPrcRec *= 0.5
									_nPrcCom *= 0.5
								otherwise
									do case
									case alltrim (_sClasABD) == "A"
										_nPrcRec *= 1.1
										_nPrcCom *= 1.1
									case alltrim (_sClasABD) == "B"
										_nPrcRec *= 1
										_nPrcCom *= 1
									case alltrim (_sClasABD) == "D"
										_nPrcRec *= 0.9
										_nPrcCom *= 0.9
									otherwise
										_nPrcCom = 0
									endcase
								endcase
							elseif sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "C"  // A partir de 2018
								if alltrim (_sClasABD) == 'A'
									_nPrcCom *= 1.1
								endif
							endif
		
							_nRet = iif (_sQualPrc == 'E', _nPrcRec, iif (_sQualPrc == 'C', _nPrcCom, iif (_sQualPrc == 'D', _nPrcDCO, 0)))
						endif
					endif
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _nRet

/* Versao usada na safra 2017
user function PrecoUva (_sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse, _sClasABD, _sQualPrc, _sFilial)
	local _aAreaAnt  := U_ML_SRArea ()
	local _nRet      := 0
	local _nPrcRec   := 0
	local _nPrcCom   := 0
	local _lContinua := .T.
	local _lTabDS    := .F.
	local _nGMinB    := 0
	local _nGMinT    := 0
	local _sTabDS    := ''
	local _sGrpDS    := ''

	//u_log ('Buscando preco:', _sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse, _sClasABD, _sQualPrc, _sFilial)

	if _sSafra > '2017' .AND. _sQualPrc == 'C'
		u_help ("Revisar U_PRECOUVA para esta safra, pois em 2017 foi incluido tratamento para precificacao (compra) de viniferas desclassificadas na serra")
	endif

	// Para evitar erros desagradaveis de 'alias does not exist' quando a funcao chamadora for mal feita.
	dbselectarea ("SA2")

	// A partir de 2014 teremos o grau com uma casa decimal, mas as tabelas de precos variam em 0.5 graus.
	if _sSafra >= '2014' .and. at ('.', _sGrau) == 0
		u_help ("Para esta safra o grau deve ser informado com ponto decimal")
		_lContinua = .F.
	endif
	
	if _lContinua
		do case
			case right (_sGrau, 1) $ '012'
				_sGrau = substr (_sGrau, 1, len (_sGrau) - 1) + '0'
			case right (_sGrau, 1) $ '34567'
				_sGrau = substr (_sGrau, 1, len (_sGrau) - 1) + '5'
			case right (_sGrau, 1) $ '89'
				_sGrau = strzero (val (substr (_sGrau, 1, 2)) + 1, 2) + '.0'
		endcase
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Produto '" + _sProduto + "' nao encontrado.")
			_lContinua = .F.
		endif
	endif

	// Nao foi feita classificacao de uvas na serra nesta safra.
	if _lContinua .and. _sQualPrc == 'C' .and. _sSafra == '2017'
		_sClasABD = ''
	endif

	if _lContinua

		// Preco de compra: antes de mais nada verifica se eh um caso de uva desclassificada na regiao da serra.
		if _sQualPrc == 'C' .and. _sFilial != '03' .and. _sSafra >= '2015'

			// Mesmo que tenham sido recebidas como 'finas com classificacao' as uvas da serra serao precificadas como 'finas sem classificacao'.
			if sb1 -> b1_varuva == 'F' .and. sb1 -> b1_vaFCUva == 'F'
				_sProduto = u_tamfixo (alltrim (_sProduto) + 'A', 15, ' ')
				u_log ('Variedade vai ser precificada como sem classificacao (' + alltrim (_sProduto) + ')')

				// Reposiciona SB1 apos troca de codigo de produto.
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
					u_help ("Produto '" + _sProduto + "' nao encontrado apos troca para 'sem classificacao'.")
					_lContinua = .F.
				endif
			endif

			do case
			case _sSafra == '2015'
				_nGMinB = 12  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
				_nGMinT = 14  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
				_sTabDS = 'BASE15'
				_sGrpDS = '221'
			case _sSafra == '2016'
				_nGMinB = 11  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
				_nGMinT = 13  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
				_sTabDS = 'BASE16'
				_sGrpDS = '221'
			case _sSafra == '2017'
				_nGMinB = 10  // Grau minimo para uva branca escapar da vala comum definida pelas variaveis abaixo.
				_nGMinT = 12  // Grau minimo para uva tinta escapar da vala comum definida pelas variaveis abaixo.
				_sTabDS = 'BASE17'
				_sGrpDS = '221'
			otherwise
				u_help ("Sem grau minimo para uvas desclassificadas nesta safra")
				_lContinua = .F.
			endcase

			//u_log (_nGMinB, _nGMinT, _sTabDS, _sGrpDS)

			// Grau abaixo do minimo ou desclassificadas busca de tabela fixa.
			if _lContinua
				_lTabDS = .F.
				if sb1 -> b1_varuva == 'F'
					if sb1 -> b1_vaFCUva == 'F' .and. (alltrim (_sClasse) $ 'D/DS' .or. alltrim (_sClasABD) $ 'D')
						u_log ('Desclassificada')
						_lTabDS = .T.
					endif
					if sb1 -> b1_vacor $ 'B/R' .and. val (_sGrau) < _nGMinB
						u_log ('Abaixo do grau minimo')
						_lTabDS = .T.
					endif
					if sb1 -> b1_vacor $ 'T' .and. val (_sGrau) < _nGMinT
						u_log ('Abaixo do grau minimo')
						_lTabDS = .T.
					endif
				endif

				//u_log (_lTabDS)

				if _lTabDS
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT Z1_PRCCOM"
					_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZ1") + " SZ1 "
					_oSQL:_sQuery +=  " WHERE SZ1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_FILIAL   = '" + xFilial ("SZ1") + "'"
					_oSQL:_sQuery +=    " AND SZ1.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_TABELA   = '" + _sTabDS + "'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_CODPRD   = '" + _sGrpDS + "'"
					_oSQL:_sQuery +=    " AND SZ1.Z1_GRAU     = '" + _sGrau + "'"
					//_oSQL:Log ()
					_nRet = _oSQL:RetQry ()
				endif
			endif
		endif
	endif

//	u_log ('_lTabDS:', _lTabDS)
	
	if _lContinua .and. !_lTabDS
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + _sFornece + _sLoja, .F.))
			u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao encontrado.")
		else
			sz7 -> (dbsetorder (1))  // Z7_FILIAL+Z7_FORNECE+Z7_LOJA+Z7_SAFRA
			if ! sz7 -> (dbseek (xfilial ("SZ7") + _sFornece + _sLoja + _sSafra, .F.))
				u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao amarrado `a safra '" + _sSafra + "'")
			else
				sza -> (dbsetorder (1))
				if ! sza -> (dbseek (xfilial ("SZA") + sz7 -> z7_tabprc, .F.))
					u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao foi encontrada!")
				else
					if sza -> za_safra != _sSafra
						u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao se refere a essa safra")
					else
						sz1 -> (dbsetorder (1))
						if ! sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto + _sGrau, .F.))
							u_help ("Preco nao encontrado para variedade '" + _sProduto + "' e grau '" + _sGrau + "' na tabela '" + sza -> za_cod + "'. Verifique tabelas de precos de safra.")
						else
	
							_nPrcRec = sz1 -> z1_prcrec
							_nPrcCom = sz1 -> z1_prccom
	
							// O preco de compra, para uvas finas, varia conforme a sua classificacao final.
//							if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VARUVA") == "F" .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VAFCUVA") == "F"
							if sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "F"
								do case
								case alltrim (_sClasse) == "AA"
									_nPrcRec *= 1.4
									_nPrcCom *= 1.4
								case alltrim (_sClasse) == "A"
									_nPrcRec *= 1.2
									_nPrcCom *= 1.2
								case alltrim (_sClasse) == "B"
									_nPrcRec *= 1
									_nPrcCom *= 1
								case alltrim (_sClasse) == "C"
									_nPrcRec *= 0.8
									_nPrcCom *= 0.8
								case alltrim (_sClasse) == "D"
									_nPrcRec *= 0.6
									_nPrcCom *= 0.6
								case alltrim (_sClasse) == "DS"
									_nPrcRec *= 0.5
									_nPrcCom *= 0.5
								otherwise
									do case
									case alltrim (_sClasABD) == "A"
										_nPrcRec *= 1.1
										_nPrcCom *= 1.1
									case alltrim (_sClasABD) == "B"
										_nPrcRec *= 1
										_nPrcCom *= 1
									case alltrim (_sClasABD) == "D"
										_nPrcRec *= 0.9
										_nPrcCom *= 0.9
									otherwise
										_nPrcCom = 0
									endcase
								endcase
							endif
		
//							_aRet = {_nPrcRec, _nPrcCom, sz1 -> z1_prcDCO}
							_nRet = iif (_sQualPrc == 'E', _nPrcRec, iif (_sQualPrc == 'C', _nPrcCom, iif (_sQualPrc == 'D', _nPrcDCO, 0)))
						endif
					endif
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _nRet
*/

/* VERSAO USADA ATEH A SAFRA 2013, ANTES DE TRABALHARMOS COM CASA DECIMAL NO GRAU.
user function PrecoUva (_sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse)
	local _aAreaAnt := U_ML_SRArea ()
	local _aRet     := {0, 0, 0}
	local _nPrcRec  := 0
	local _nPrcCom  := 0

	// Para evitar erros desagradaveis de 'alias does not exist' quando a funcao chamadora for mal feita.
	dbselectarea ("SA2")

	sa2 -> (dbsetorder (1))
	if ! sa2 -> (dbseek (xfilial ("SA2") + _sFornece + _sLoja, .F.))
		u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao encontrado.")
	else
		sz7 -> (dbsetorder (1))  // Z7_FILIAL+Z7_FORNECE+Z7_LOJA+Z7_SAFRA
		if ! sz7 -> (dbseek (xfilial ("SZ7") + _sFornece + _sLoja + _sSafra, .F.))
			u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao amarrado `a safra '" + _sSafra + "'")
		else
			sza -> (dbsetorder (1))
			if ! sza -> (dbseek (xfilial ("SZA") + sz7 -> z7_tabprc, .F.))
				u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao foi encontrada!")
			else
				if sza -> za_safra != _sSafra
					u_help ("Tabela de precos '" + sz7 -> z7_tabprc + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao se refere a essa safra")
				else
					sz1 -> (dbsetorder (1))
					if ! sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto + _sGrau, .F.))
						u_help ("Preco nao encontrado para variedade '" + _sProduto + "' e grau '" + _sGrau + "' na tabela '" + sza -> za_cod + "'. Verifique tabelas de precos de safra.")
					else

						_nPrcRec = sz1 -> z1_prcrec
						_nPrcCom = sz1 -> z1_prccom

						// O preco de compra, para uvas finas, varia conforme a sua classificacao final.
//						if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VARUVA") == "F"
						if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VARUVA") == "F" .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VAFCUVA") == "F"
							do case
								case alltrim (_sClasse) == "AA"
									_nPrcRec *= 1.4
									_nPrcCom *= 1.4
								case alltrim (_sClasse) == "A"
									_nPrcRec *= 1.2
									_nPrcCom *= 1.2
								case alltrim (_sClasse) == "B"
									_nPrcRec *= 1
									_nPrcCom *= 1
								case alltrim (_sClasse) == "C"
									_nPrcRec *= 0.8
									_nPrcCom *= 0.8
								case alltrim (_sClasse) == "D"
									_nPrcRec *= 0.6
									_nPrcCom *= 0.6
								case alltrim (_sClasse) == "DS"
									_nPrcRec *= 0.5
									_nPrcCom *= 0.5
								otherwise
									_nPrcCom = 0
							endcase
						endif
	
						_aRet = {_nPrcRec, _nPrcCom, sz1 -> z1_prcDCO}
					endif
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _aRet
*/
/* versao utilizada ateh a safra 2010
user function PrecoUva (_sFornece, _sLoja, _sProduto, _sGrau, _sSafra, _sClasse)
	local _aAreaAnt := U_ML_SRArea ()
	local _aRet     := {0, 0, 0}
	local _nPrcRec  := 0
	local _nPrcCom  := 0

	// Para evitar erros desagradaveis de 'alias does not exist' quando a funcao chamadora for mal feita.
	dbselectarea ("SA2")

	sa2 -> (dbsetorder (1))
	if ! sa2 -> (dbseek (xfilial ("SA2") + _sFornece + _sLoja, .F.))
		u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao encontrado.")
	else
		sz2 -> (dbsetorder (1))  // Z2_FILIAL+Z2_FORNECE+Z2_LOJA+Z2_SAFRA
		if ! sz2 -> (dbseek (xfilial ("SZ2") + _sFornece + _sLoja + _sSafra, .F.))
			u_help ("Fornecedor '" + _sFornece + "/" + _sLoja + "' nao ligado a nenhuma tabela de precos para a safra de " + _sSafra)
		else
			sza -> (dbsetorder (1))
			if ! sza -> (dbseek (xfilial ("SZA") + sz2 -> z2_tabela, .F.))
				u_help ("Tabela de precos '" + sz2 -> z2_tabela + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao foi encontrada!")
			else
				if sza -> za_safra != _sSafra
					u_help ("Tabela de precos '" + sz2 -> z2_tabela + "' (ligada ao fornecedor para a safra de " + _sSafra + ") nao se refere a essa safra")
				else
					sz1 -> (dbsetorder (1))
					if ! sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto + _sGrau, .F.))
						u_help ("Preco nao encontrado para variedade '" + _sProduto + "' e grau '" + _sGrau + "' na tabela '" + sza -> za_cod + "'. Verifique tabelas de precos de safra.")
					else
	
						_nPrcRec = sz1 -> z1_prcrec
						_nPrcCom = sz1 -> z1_prccom
	
						// O preco de compra, para uvas finas, varia conforme a sua classificacao final.
						if fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VARUVA") == "F"
							do case
								case alltrim (_sClasse) == "AA"
									_nPrcRec *= 1.4
									_nPrcCom *= 1.4
								case alltrim (_sClasse) == "A"
									_nPrcRec *= 1.2
									_nPrcCom *= 1.2
								case alltrim (_sClasse) == "B"
									_nPrcRec *= 1
									_nPrcCom *= 1
								case alltrim (_sClasse) == "C"
									_nPrcRec *= 0.8
									_nPrcCom *= 0.8
								case alltrim (_sClasse) == "D"
									_nPrcRec *= 0.6
									_nPrcCom *= 0.6
								case alltrim (_sClasse) == "DS"
									_nPrcRec *= 0.5
									_nPrcCom *= 0.5
								otherwise
									_nPrcCom = 0
							endcase
						endif
	
						_aRet = {_nPrcRec, _nPrcCom, sz1 -> z1_prcDCO}
					endif
				endif
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _aRet
*/
