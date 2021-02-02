// Programa:   BatSafr
// Autor:      Robert Koch
// Data:       28/12/2011
// Descricao:  Envia e-mail com inconsistencias encontradas durante a safra.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Verificacoes diversas durante periodo de safra
// #PalavasChave      #safra
// #TabelasPrincipais #SF1 SD1 $SZE #SZF
// #Modulos           #COOP

// Historico de alteracoes:
// 06/03/2012 - Robert - Nao considerava cargas aglutinadas.
// 13/03/2012 - Robert - Criada verificacao de cadastros viticolas nao renovados.
// 06/02/2013 - Robert - Separados os tipos de verificacao via parametro na chamada da funcao.
//                     - Passa a validar a safra atual pela data doo sistema.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 18/01/2016 - Robert - Desconsidera fornecedor 003114 no teste de cargas (transferencias da linha Jacinto para matriz)
// 25/01/2016 - Robert - Envia avisos para o grupo 045.
// 16/01/2019 - Robert - Incluido grupo 047 no aviso de cargas sem contranota.
// 17/01/2021 - Robert - Criada verificacao tipo 3 (parcelamento das notas de compra).
// 01/02/2021 - Robert - Criado parametro que permite ajustar os titulos, para casos especificos de recalculo de frete (ainda nao testado/usado).
//

// --------------------------------------------------------------------------
user function BatSafr (_sQueFazer, _lAjustar)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _aCols     := {}
	local _aSemNota  := {}
	//local _sDestin   := ""
	local _oSQL      := NIL

	_sQueFazer = iif (_sQueFazer == NIL, '', _sQueFazer)
	_lAjustar = iif (_lAjustar == NIL, .F., _lAjustar)

	// Procura cargas sem contranota.
	if _sQueFazer == '1'
		_aSemNota = {}
		dbselectarea ("SZE")
		set filter to &('ZE_FILIAL=="' + xFilial("SZE") + '".And.ze_safra=="'+cvaltochar (year (date ()))+'".and.ze_coop$"000021".and.empty(ze_nfger).and.dtos(ze_data)<"' + dtos (ddatabase) + '".and.ze_aglutin!="O".and.ze_assoc!="003114"')
		dbgotop ()
		do while ! eof ()
			aadd (_aSemNota, {"Filial/carga '" + sze -> ze_filial + '/' + sze -> ze_carga + "' de " + dtoc (sze -> ze_data) + " sem contranota!", sze -> ze_nomasso})
			dbskip ()
		enddo
		set filter to
	
		if len (_aSemNota) > 0
			_aCols = {}
			aadd (_aCols, {"Mensagem",        "left",  "@!"})
			aadd (_aCols, {"Associado",       "left",  "@!"})
			_oAUtil := ClsAUtil():New (_aSemNota)
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			U_ZZUNU ({'045', '047'}, "Inconsistencias cargas safra", _sMsg)
		endif

	// Verifica contranotas com cadastro viticola desatualizado
	elseif _sQueFazer == '2'
		/* Em desuso. A partir de 2021 trabalha-se com codigo SIVIBE e os cadastros de propriedades
		   rurais (antigos cad.viticolas) estao no NaWeb
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT 'Filial:' + FILIAL + ' Assoc:' + ASSOCIADO + '-' + RTRIM (NOME_ASSOC) + ' Cad.vit:' + CAD_VITIC"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
		_oSQL:_sQuery +=    " AND TIPO_NF = 'E'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SZ2") + " SZ2 "
		_oSQL:_sQuery +=                     " WHERE SZ2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_FILIAL  = '" + xfilial ("SZ2") + "'"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_CADVITI = V.CAD_VITIC"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_SAFRVIT = V.SAFRA)"
		u_log (_oSQL:_sQuery)
		_aCols = {}
		aadd (_aCols, {"Mensagem",        "left",  "@!"})
		_oAUtil := ClsAUtil():New (_oSQL:Qry2Array ())
		if len (_oAUtil:_aArray) > 0
			_sMsg := "Contranotas com cadastro viticola inconsistente ou nao renovado:"
			_sMsg += "<BR>"
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			u_log (_smsg)
			U_ZZUNU ({'045'}, "Inconsistencias cadastro viticola", _sMsg)
		endif
		*/

	// Verifica composicao das parcelas das notas. Em 2021 jah estamos fazendo 'compra' durante a safra.
	// Como as primeiras notas sairam erradas, optei por fazer esta rotina de novo a identifica-las
	// e manter monitoramento.
	elseif _sQueFazer == '3' .and. year (date ()) >= 2021
		_ConfParc (_lAjustar)

	// Verifica contranotas "sem carga". Isso indica possivel problema nas amarracoes entre tabelas.
	elseif _sQueFazer == '4'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT 'Filial:' + FILIAL + ' Assoc:' + ASSOCIADO + '-' + RTRIM (NOME_ASSOC) + ' Contranota:' + DOC"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
		_oSQL:_sQuery +=    " AND (CARGA = '' OR CARGA IS NULL)
		u_log (_oSQL:_sQuery)
		_aCols = {}
		aadd (_aCols, {"Mensagem",        "left",  "@!"})
		_oAUtil := ClsAUtil():New (_oSQL:Qry2Array ())
		if len (_oAUtil:_aArray) > 0
			_sMsg := "Contranotas sem carga (provavel inconsistencia entre tabelas)"
			_sMsg += "<BR>"
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			u_log (_smsg)
			U_ZZUNU ({'999'}, "Contranotas sem carga", _sMsg)
		endif

	// Verifica frete
	elseif _sQueFazer == '5'
		_ConfFrt ()
	
	else
		u_help ("Sem definicao para verificacao '" + _sQueFazer + "'.",, .T.)
		//_oBatch:Retorno += "Sem definicao para verificacao '" + _sQueFazer + "'."
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return .T.



// --------------------------------------------------------------------------
static function _ConfFrt ()
	local _oSQL      := NIL
	local _sAliasQ   := ''
	local _sMsg      := ''

	sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, SUM (VALOR_FRETE) AS VLR_FRT"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF = 'C'"
	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		if ! sf1 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
			_sMsg += "Arquivo SF1 nao localizado" + chr (13) + chr (10)
		else
			u_log2 ('debug', cvaltochar ((_sAliasQ) -> vlr_frt) + '   ' + cvaltochar (sf1 -> f1_despesa))
			if (_sAliasQ) -> vlr_frt != sf1 -> f1_despesa
				_sMsg += "Frete no ZF_VALFRET (" + cvaltochar ((_sAliasQ) -> vlr_frt) + ") diferente do campo F1_DESPESA (" + cvaltochar (sf1 -> f1_despesa) + ")" + chr (13) + chr (10)
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'Inconsistencia frete safra - filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado)
			U_Log2 ('erro', _sMsg)
			u_zzunu ({'122'}, 'Inconsistencia frete safra - F.' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado, _sMsg)

			// cai fora no primeiro erro encontrado (estou ainda ajustando)
		//	EXIT   // REMOVER DEPOIS !!!!!!!!!!!!!!!!!

		endif
		(_sAliasQ) -> (dbskip ())
	enddo
return



// --------------------------------------------------------------------------
static function _ConfParc (_lAjustar)
	local _sAliasQ   := ''
	local _oSQL      := NIL
	local _aParcPrev := {}
	local _sMsg      := ''
	local _aParcReal := {}
	local _nParc     := 0
	local _nSomaPrev := 0
	local _nSomaSE2  := 0

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO, SUM (VALOR_TOTAL) AS VLR_UVAS, SUM (VALOR_FRETE) AS VLR_FRT"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF = 'C'"
	
	// alguns casos especiais
	//_oSQL:_sQuery +=    " and V.DATA = '20210115'"
	//_oSQL:_sQuery +=    " and V.VALOR_FRETE = 0"
	//_oSQL:_sQuery +=    " and GRUPO_PAGTO = 'C'"
	//_oSQL:_sQuery +=    " and FILIAL = '09'"
//	_oSQL:_sQuery +=    " and ASSOCIADO = '003003'"

	
	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		U_Log2 ('info', 'Iniciando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc + ' forn:' + (_sAliasQ) -> associado)
		if empty ((_sAliasQ) -> grupo_pagto)
			_sMsg += 'Contranota safra sem grupo para pagamento - Filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + chr (13) + chr (10)
		else
			
			// Gera array de parcelas reais (SE2)
			_aParcReal = {}
			_nSomaSE2 = 0
			se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
			se2 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc + (_sAliasQ) -> serie + (_sAliasQ) -> doc, .T.))
			do while ! se2 -> (eof ()) ;
				.and. se2 -> e2_filial  == (_sAliasQ) -> filial ;
				.and. se2 -> e2_fornece == (_sAliasQ) -> associado ;
				.and. se2 -> e2_loja    == (_sAliasQ) -> loja_assoc ;
				.and. se2 -> e2_prefixo == (_sAliasQ) -> serie ;
				.and. se2 -> e2_num     == (_sAliasQ) -> doc

				_nSomaSE2 += se2 -> e2_valor

				if se2 -> e2_valor != se2 -> e2_saldo .or. se2 -> e2_valor != se2 -> e2_vlcruz
					_sMsg += 'Parcela ' + se2 -> e2_parcela + ' no SE2 diferenca entre e2_valor x e2_saldo x e2_vlcruz' + chr (13) + chr (10)
				endif
				if se2 -> e2_vencto != se2 -> e2_vencrea
					_sMsg += 'Parcela ' + se2 -> e2_parcela + ' no SE2 diferenca entre e2_vencto x e2_vencrea' + chr (13) + chr (10)
				endif

				// Calcula o % de participacao de cada parcela sobre o total do valor das uvas
				aadd (_aParcReal, {se2 -> e2_vencrea, se2 -> e2_valor * 100 / (_sAliasQ) -> vlr_uvas, se2 -> e2_valor, se2 -> e2_parcela})
				se2 -> (dbskip ())
			enddo

			// Gera array de parcelas previstas cfe. regras de pagamento.
			_aParcPrev = U_VA_RusPP ((_sAliasQ) -> safra, (_sAliasQ) -> grupo_pagto, (_sAliasQ) -> vlr_uvas, (_sAliasQ) -> vlr_frt)
			_nSomaPrev = 0
			for _nParc = 1 to len (_aParcPrev)
		//		aadd (_aParcPrev [_nParc], round ((_aParcPrev [_nParc, 3] * ((_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt) / 100), 2))
				_nSomaPrev += _aParcPrev [_nParc, 4]
			next

//			U_Log2 ('aviso', 'como estah no SE2:')
//			U_Log2 ('aviso', _aParcReal)

			if len (_aParcReal) != len (_aParcPrev)
				_sMsg += 'Encontrei qt.diferente (' + cvaltochar (len (_aParcReal)) + ') de parcelas no SE2 do que o previsto (' + cvaltochar (len (_aParcPrev)) + ')' + chr (13) + chr (10)
			else

				// apenas verifica
				for _nParc = 1 to len (_aParcReal)
					if _aParcReal [_nParc, 1] != _aParcPrev [_nParc, 2]
						_sMsg += "Diferenca nas datas - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
					endif
					if round (_aParcReal [_nParc, 3], 2) != round (_aParcPrev [_nParc, 4], 2)
						_sMsg += "Diferenca nos valores de uva - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
					endif
				next

				// Ajusta valores e datas. A safra 2021 iniciou usando cond.pagto.invalida, e tive
				// diversas notas para ajustar. Espero nao precisar mais disto...
				if _lAjustar
					if cUserName != 'robert.koch'
						u_help ("Ajuste liberado somente para o maluco que criou a rotina.",, .t.)
					else
						se2 -> (dbsetorder (6))  // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
						for _nParc = 1 to len (_aParcReal)
							// Posiciona SE2 para o caso de precisar mexer.
							if ! se2 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc + (_sAliasQ) -> serie + (_sAliasQ) -> doc + chr (64 + _nParc), .F.))  // Localiza a parcela somando 64 ao _nParc, pois as parcelas iniciam na letra 'A'.
								U_Log2 ('aviso', 'Nao encontrei a parcela ' + chr (64 + _nParc) + ' para ajustar.')
							else
								if e2_saldo != e2_valor
									u_help ("Saldo diferente do valor do titulo. Nao farei ajustes.",, .T.)
								else
									reclock ("SE2", .F.)
									if se2 -> e2_valor != _aParcPrev [_nParc, 4]
										u_log2 ('info', "Ajustando parcela " + se2 -> e2_parcela + ' de ' + cvaltochar (se2 -> e2_valor) + ' para ' + cvaltochar (_aParcPrev [_nParc, 4]))
										se2 -> e2_valor = _aParcPrev [_nParc, 4]
										se2 -> e2_saldo = _aParcPrev [_nParc, 4]
										se2 -> e2_vlcruz = _aParcPrev [_nParc, 4]
									endif
									if ! alltrim (_aParcPrev [_nParc, 5]) $ se2 -> e2_hist
										u_log2 ('info', "Ajustando parcela " + se2 -> e2_parcela + ' de ' + se2 -> e2_hist + ' para ' + _aParcPrev [_nParc, 5])
										se2 -> e2_hist = alltrim (_aParcPrev [_nParc, 5])
									endif
									if se2 -> e2_vencto != _aParcPrev [_nParc, 2]
										u_log2 ('info', "Ajustando parcela " + se2 -> e2_parcela + ' de ' + cvaltochar (se2 -> e2_vencto) + ' para ' + cvaltochar (_aParcPrev [_nParc, 2]))
										se2 -> e2_vencto = _aParcPrev [_nParc, 2]
										se2 -> e2_vencrea = _aParcPrev [_nParc, 2]
									endif
									msunlock ()
								endif
							endif
						next
					endif
				endif
			endif

			if _nSomaSE2 != (_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt
				_sMsg += "Soma dos titulos no SE2 (" + cvaltochar (_nSomaSE2) + ") diferente de valor das uvas + frete (" + cvaltochar ((_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt) + ")" + chr (13) + chr (10)
			endif

			sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_
			if ! sf1 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
				_sMsg += "Arquivo SF1 nao localizado" + chr (13) + chr (10)
			else
				if _nSomaSE2 != sf1 -> f1_valbrut
					_sMsg += "Soma dos titulos no SE2 (" + cvaltochar (_nSomaSE2) + ") diferente do F1_VALBRUT (" + cvaltochar (sf1 -> f1_valbrut) + ")" + chr (13) + chr (10)
				endif
				if (_sAliasQ) -> vlr_frt != sf1 -> f1_despesa
					_sMsg += "Frete no ZF_VALFRET (" + cvaltochar ((_sAliasQ) -> vlr_frt) + ") diferente do campo F1_DESPESA (" + cvaltochar (sf1 -> f1_despesa) + ")" + chr (13) + chr (10)
				endif
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'Inconsistencia parcelamento safra - filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado)
			U_Log2 ('erro', _sMsg)
			U_Log2 ('aviso', 'como deveria estar no SE2:')
			U_Log2 ('aviso', _aParcPrev)
			u_zzunu ({'122'}, 'Inconsistencia parcelamento safra - F.' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado, _sMsg)

			// cai fora no primeiro erro encontrado (estou ainda ajustando)
//			EXIT   // REMOVER DEPOIS !!!!!!!!!!!!!!!!!

		endif
		U_Log2 ('info', 'Finalizando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc)
		(_sAliasQ) -> (dbskip ())
	enddo
return
