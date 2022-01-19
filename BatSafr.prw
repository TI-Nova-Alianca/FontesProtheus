// Programa:   BatSafr
// Autor:      Robert Koch
// Data:       28/12/2011
// Descricao:  Envia e-mail com inconsistencias encontradas durante a safra.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Verificacoes e processamentos diversos durante periodo de safra
// #PalavasChave      #safra0
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
// 12/03/2021 - Robert - Migrado e-mail diario de acompanhamento da safra do U_BatCSaf() para este programa.
//                     - Implementada geracao do SZI e verificacao de inconsistencias SZI x SE2 (GLPI 9592).
// 03/04/2021 - Robert - Recalcula saldo do SZI antes de enviar aviso de diferenca com o SE2.
// 07/05/2021 - Robert - Removidas algumas linhas comentariadas.
// 20/07/2021 - Robert - Removido e-mail paulo.dullius e inserido monica.rodrigues
// 12/01/2022 - Robert - Melhorias nomes arquivos de log, e-mail acompanhamento.
// 17/01/2022 - Robert - Ajuste nomes conselheiros.
// 19/01/2022 - Robert - Ajuste nomes e e-mail conselheiros.
//

// --------------------------------------------------------------------------
user function BatSafr (_sQueFazer, _lAjustar)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _aCols     := {}
	local _aSemNota  := {}
	local _oSQL      := NIL
	local _sArqLgOld := ''
	local _sArqLog2  := ''

	_sQueFazer = iif (_sQueFazer == NIL, '', _sQueFazer)
	_lAjustar = iif (_lAjustar == NIL, .F., _lAjustar)

	U_Log2 ('info', 'Iniciando ' + procname () + ' com _sQueFazer=' + _sQueFazer)

	// Como esta funcao faz diversas tarefas, vou gerar log em arquivos separados.
	_sArqLgOld = _sArqLog
	_sArqLog2 = procname () + '_opcao' + _sQueFazer + '_' + alltrim (cUserName) + "_" + dtos (date ()) + ".log"
	u_log2 ('info', 'Log da thread ' + cValToChar (ThreadID ()) + ' prossegue em outro arquivo: ' + _sArqLog2)
	_sArqLog = _sArqLog2

	// Procura cargas sem contranota.
	if _sQueFazer == '1'
		_aSemNota = {}
		dbselectarea ("SZE")
//		set filter to &('ZE_FILIAL=="' + xFilial("SZE") + '".And.ze_safra=="'+cvaltochar (year (date ()))+'".and.ze_coop$"000021".and.empty(ze_nfger).and.dtos(ze_data)<"' + dtos (ddatabase) + '".and.ze_aglutin!="O".and.ze_assoc!="003114"')
		set filter to &('ZE_FILIAL=="' + xFilial("SZE") + '".And.ze_safra=="'+cvaltochar (year (date ()))+'".and.ze_coop$"000021".and.empty(ze_nfger).and.dtos(ze_data)<"' + dtos (ddatabase) + '".and.ze_aglutin!="O".and.!ze_status$"C/D"')
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
			U_Log2 ('aviso', _sMsg)
			U_ZZUNU ({'045', '047'}, "Inconsistencias cargas safra", _sMsg)
		else
			U_Log2 ('info', 'Nenhuma inconsistencia encontrada.')
		endif

	// Verifica contranotas com cadastro viticola desatualizado
	// Em desuso. A partir de 2021 trabalha-se com codigo SIVIBE e os cadastros de propriedades
	// rurais (antigos cad.viticolas) estao no NaWeb
	elseif _sQueFazer == '2'
		U_Log2 ('aviso', 'Verificacao em desuso!')

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
		_oSQL:_sQuery +=    " AND TIPO_NF != 'V'"
		_oSQL:_sQuery +=    " AND (CARGA = '' OR CARGA IS NULL)"
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
		else
			U_Log2 ('info', 'Nenhuma inconsistencia encontrada.')
		endif

	// Verifica frete
	elseif _sQueFazer == '5'
		_ConfFrt ()
	
	// Envia e-mail de acompanhamento de totais de safra
	elseif _sQueFazer == '6'
		_MailAcomp ()
	
	// Gera titulos na conta corrente referentes as notas de compra (a partir de 2021 geramos direto como compra) - GLPI 9592
	// Esses titulos nao sao gerados no momento de emissao da contranota por que fica muito demorado.
	elseif _sQueFazer == '7'
		_GeraSZI ()

	// Confere conta corrente (SZI) x titulos referentes as notas de compra (a partir de 2021 geramos direto como compra) - GLPI 9592
	elseif _sQueFazer == '8'
		_ConfSZI ()

	// Transfere (das filiais para a matriz) os titulos de nao associados.
	elseif _sQueFazer == '9'
		_TransFil ()
	
	else
		u_help ("Sem definicao para o que fazer quando parametro = '" + _sQueFazer + "'.",, .T.)
		//_oBatch:Retorno += "Sem definicao para verificacao '" + _sQueFazer + "'."
	endif

	// Volta log para o nome original, apenas para 'fechar' o processo.
	_sArqLog = _sArqLgOld

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	U_Log2 ('info', 'Finalizando ' + procname ())
return .T.



// --------------------------------------------------------------------------
static function _ConfFrt ()
	local _oSQL      := NIL
	local _sAliasQ   := ''
	local _sMsg      := ''

	U_Log2 ('info', 'Iniciando ' + procname ())

	sf1 -> (dbsetorder (1))  // F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, R_E_C_N_O_, D_E_L_E_T_

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, SUM (VALOR_FRETE) AS VLR_FRT"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF = 'C'"
	_oSQL:_sQuery +=    " AND FILIAL  = '" + cFilAnt + "'"
	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		if ! sf1 -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
			_sMsg += "Arquivo SF1 nao localizado" + chr (13) + chr (10)
		else
			if (_sAliasQ) -> vlr_frt != sf1 -> f1_despesa
				_sMsg += "Frete no ZF_VALFRET (" + cvaltochar ((_sAliasQ) -> vlr_frt) + ") diferente do campo F1_DESPESA (" + cvaltochar (sf1 -> f1_despesa) + ")" + chr (13) + chr (10)
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'Inconsistencia frete safra - filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado)
			U_Log2 ('erro', _sMsg)
			u_zzunu ({'999'}, 'Inconsistencia frete safra - F.' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado, _sMsg)

			// cai fora no primeiro erro encontrado (estou ainda ajustando)
			EXIT   // REMOVER DEPOIS !!!!!!!!!!!!!!!!!

		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
// Confere parcelas geradas nas notas de compra da safra.
static function _ConfParc (_lAjustar)
	local _sAliasQ   := ''
	local _oSQL      := NIL
	local _aParcPrev := {}
	local _sMsg      := ''
	local _aParcReal := {}
	local _nParc     := 0
	local _nSomaPrev := 0
	local _nSomaSE2  := 0

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO, SUM (VALOR_TOTAL) AS VLR_UVAS, SUM (VALOR_FRETE) AS VLR_FRT, DATA AS EMISSAO"
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=    " AND TIPO_NF IN ('C', 'V')"
	_oSQL:_sQuery +=    " AND FILIAL = '" + cFilAnt + "'"

	if _lAjustar  // Soh uso pra casos especiais
		_oSQL:_sQuery +=    " and FILIAL = '01'"
		_oSQL:_sQuery +=    " and ASSOCIADO = '002978'"
		_oSQL:_sQuery +=    " and DOC = '000023832'"
	endif

	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO, DATA"
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

				if se2 -> e2_valor != se2 -> e2_vlcruz
					_sMsg += 'Parcela ' + se2 -> e2_parcela + ' no SE2 diferenca entre e2_valor x e2_vlcruz' + chr (13) + chr (10)
				endif

				// Calcula o % de participacao de cada parcela sobre o total do valor das uvas
				aadd (_aParcReal, {se2 -> e2_vencto, se2 -> e2_valor * 100 / (_sAliasQ) -> vlr_uvas, se2 -> e2_valor, se2 -> e2_parcela})
				se2 -> (dbskip ())
			enddo

			// Gera array de parcelas previstas cfe. regras de pagamento.
			_aParcPrev = U_VA_RusPP ((_sAliasQ) -> safra, (_sAliasQ) -> grupo_pagto, (_sAliasQ) -> vlr_uvas, (_sAliasQ) -> vlr_frt, stod ((_sAliasQ) -> emissao))
			_nSomaPrev = 0
			for _nParc = 1 to len (_aParcPrev)
				_nSomaPrev += _aParcPrev [_nParc, 4]
			next

//			U_Log2 ('aviso', 'como estah no SE2:')
//			U_Log2 ('aviso', _aParcReal)

			if len (_aParcReal) != len (_aParcPrev)
				_sMsg += 'Encontrei qt.diferente (' + cvaltochar (len (_aParcReal)) + ') de parcelas no SE2 do que o previsto (' + cvaltochar (len (_aParcPrev)) + ')' + chr (13) + chr (10)
			else

				// apenas verifica
				for _nParc = 1 to len (_aParcReal)

					// bah em 2021 gerei dia 30/03 em vez de 31/03!!!
					if _aParcReal [_nParc, 1] = stod ('20210330') .and. _aParcPrev [_nParc, 2] == stod ('20210331')
						// deixa quieto...
					else
						if _aParcReal [_nParc, 1] != _aParcPrev [_nParc, 2]
							_sMsg += "Diferenca nas datas - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
							_sMsg += "Real: " + dtoc (_aParcReal [_nParc, 1]) + ' X prev: ' + dtoc (_aParcPrev [_nParc, 2]) + chr (13) + chr (10)
						endif
					endif
					if round (_aParcReal [_nParc, 3], 2) != round (_aParcPrev [_nParc, 4], 2)
						_sMsg += "Diferenca nos valores de uva - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
						_sMsg += "Parcela real: " + cvaltochar (round (_aParcReal [_nParc, 3], 2)) + " prevista: " + cvaltochar (round (_aParcPrev [_nParc, 4], 2)) + chr (13) + chr (10)
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
								if se2 -> e2_saldo != se2 -> e2_valor
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
			u_zzunu ({'999'}, 'Inconsistencia parcelamento safra - F.' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc + ' forn: ' + (_sAliasQ) -> associado, _sMsg)

			// cai fora no primeiro erro encontrado (estou ainda ajustando)
			EXIT   // REMOVER DEPOIS !!!!!!!!!!!!!!!!!

		endif
//		U_Log2 ('info', 'Finalizando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc)
		(_sAliasQ) -> (dbskip ())
	enddo
	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
static function _MailAcomp ()
	local _sMsg   := ""
	local _sDest  := ""
	local _oSQL   := NIL
	local _sSafra := U_IniSafra ()
	local _aCols  := {}

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT FILIAL, PRODUTO, DESCRICAO, GRAU, PESO_LIQ"
	_oSQL:_sQuery += " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '" + _sSafra + "'"
	_oSQL:_sQuery += " AND STATUS != 'C'"  // Cancelada
	_oSQL:_sQuery += " AND AGLUTINACAO != 'O'"  // Aglutinada em outra carga
	_oSQL:_sQuery += " AND PESO_LIQ > 0"  // Para evitar cargas 'em recebimento'
	_oSQL:_sQuery += " AND NF_DEVOLUCAO = ''"  // Para evitar cargas devolvidas'
	_oSQL:_sQuery += " )"
	
	// Agrupado por variedade
	_oSQL:_sQuery += " SELECT PRODUTO, DESCRICAO"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F07"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " GROUP BY PRODUTO, DESCRICAO"
	
	// Linha com totais no final
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT 'TOTAIS', 'ZZZZZZZZZZZZZZ'"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01'), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03'), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07'), 0), 1) AS GRAU_F07"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09'), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
//	_oSQL:_sQuery += " , 0 AS GRAU_GERAL"
	_oSQL:_sQuery += " , ROUND(ISNULL((SELECT SUM(PESO_LIQ * GRAU) / SUM(PESO_LIQ) FROM C AS C2), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"

	_oSQL:_sQuery += " ORDER BY DESCRICAO"
	_oSQL:Log ()

	_aCols = {}
	aadd (_aCols, {'Variedade',  'left' ,  ''})
	aadd (_aCols, {'Descricao',  'left' ,  ''})
	aadd (_aCols, {'Kg F01',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F01',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F03',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F03',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F07',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F07',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F09',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F09',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg geral',   'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau geral', 'right',  '@E 99.9'})

	_sMsg = _oSQL:Qry2HTM ("Acompanhamento cargas safra " + _sSafra, _aCols, "", .T., .F.)
	if len (_oSQL:_xRetQry) > 1
		u_log2 ('debug', _sMsg)
		_sDest := ""

		// Internos - direcao
		_sDest += "alceu.dallemolle@novaalianca.coop.br;"
		_sDest += "joel.panizzon@novaalianca.coop.br;"
		_sDest += "jocemar.dalcorno@novaalianca.coop.br;"
		_sDest += "rodrigo.colleoni@novaalianca.coop.br;"

		// Conselho administracao titulares
		_sDest += "boldrindarci@gmail.com;"
		_sDest += "diegowaiss@hotmail.com;"
		_sDest += "gilbertoverdi@gmail.com;"
		_sDest += "joel.caldart@hotmail.com;"
		_sDest += "marciogirelli.st@gmail.com;"
		_sDest += "marcioferrar@gmail.com;"
		_sDest += "rodrigovdebona@gmail.com;"
		_sDest += "romildowferrari@hotmail.com;"

		// Conselho administracao suplentes
		_sDest += "juninhosalton@outlook.com;"
		_sDest += "marcosparisotto6@gmail.com;"
		_sDest += "roberto.pagliarin@novaalianca.coop.br;"
		_sDest += "drcioato@hotmail.com;"
		_sDest += "ledacioato@hotmail.com;"

		// Conselho fiscal titulares
		_sDest += "daniederbof@hotmail.com;"
		_sDest += "leandrochiarani@hotmail.com;"  // Gilmar Chiarani recebe no e-mail 'leandrochiarani@hotmail.com'
		_sDest += "kleitonguareze@gmail.com;"

		// Conselho fiscal suplentes
		_sDest += "cesardegregori47@gmail.com;"
		_sDest += "robertocbusetti@hotmail.com;"
		_sDest += "leandrobassani@hotmail.com;"  // Vitorino Sganzerla recebe no e-mail 'leandrobassani@hotmail.com'

		// Internos - gestores
		_sDest += "rodimar.vizentin@novaalianca.coop.br;"

		// Internos - tecnico / enologia / operacao
		_sDest += "talison.brisotto@novaalianca.coop.br;"
		_sDest += "eliane.lopes@novaalianca.coop.br;"
		_sDest += "pedro.toniolo@novaalianca.coop.br;"
		_sDest += "anderson.felten@novaalianca.coop.br;"
		_sDest += "alex.cervinski@novaalianca.coop.br;"
		_sDest += "eduardo.guarche@novaalianca.coop.br;"
		_sDest += "renan.mascarello@novaalianca.coop.br;"
		_sDest += "sergio.pereira@novaalianca.coop.br;"
		_sDest += "deise.demori@novaalianca.coop.br;"

		// Internos - agronomia
		_sDest += "leonardo.reffatti@novaalianca.coop.br;"
		_sDest += "monica.rodrigues@novaalianca.coop.br;"
		_sDest += "waldir.schu@novaalianca.coop.br;"
		_sDest += "odinei.cardoso@novaalianca.coop.br;"

		// Internos - TI (monitoramento)
		_sDest += "sandra.sugari@novaalianca.coop.br;"
		_sDest += "robert.koch@novaalianca.coop.br;"

		U_SendMail (_sDest, "Acompanhamento cargas safra", _sMsg)
	endif
return



// --------------------------------------------------------------------------
// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro.
static function _GeraSZI ()
	local _sAliasQ   := ''
	local _oCtaCorr  := NIL
	local _sSafrComp := strzero (year (dDataBase), 4)

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO"
	_oSQL:_sQuery +=        ",E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA, V.GRUPO_PAGTO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2, "
	_oSQL:_sQuery +=          " VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_VACHVEX = ''"
	_oSQL:_sQuery +=    " AND V.SAFRA        = '" + _sSafrComp + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL       = SE2.E2_FILIAL"
	_oSQL:_sQuery +=    " AND V.ASSOCIADO    = SE2.E2_FORNECE"
	_oSQL:_sQuery +=    " AND V.LOJA_ASSOC   = SE2.E2_LOJA"
	_oSQL:_sQuery +=    " AND V.SERIE        = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=    " AND V.DOC          = SE2.E2_NUM"
	_oSQL:_sQuery +=    " AND V.TIPO_NF      IN ('C', 'V')"
	_oSQL:_sQuery +=    " AND V.TIPO_FORNEC  = 'ASSOCIADO'"
	_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"  // Ainda nao deve existir na conta corrente
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                 " WHERE SZI.ZI_FILIAL  = SE2.E2_FILIAL"
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC   = SE2.E2_FORNECE"
	_oSQL:_sQuery +=                   " AND SZI.ZI_LOJASSO = SE2.E2_LOJA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_SERIE   = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=                   " AND SZI.ZI_DOC     = SE2.E2_NUM"
	_oSQL:_sQuery +=                   " AND SZI.ZI_PARCELA = SE2.E2_PARCELA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_TM      = '13')"
	_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.T.)
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Quero gerar tudo com a mesma data de emissao da nota
		dDataBase = (_sAliasQ) -> e2_EMISSAO

		//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)

		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc      = (_sAliasQ) -> e2_fornece
		_oCtaCorr:Loja       = (_sAliasQ) -> e2_loja
		_oCtaCorr:TM         = '13'
		_oCtaCorr:DtMovto    = (_sAliasQ) -> e2_EMISSAO
		_oCtaCorr:Valor      = (_sAliasQ) -> e2_valor
		_oCtaCorr:SaldoAtu   = (_sAliasQ) -> e2_saldo
		_oCtaCorr:Usuario    = cUserName
		_oCtaCorr:Histor     = (_sAliasQ) -> e2_hist
		_oCtaCorr:MesRef     = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
		_oCtaCorr:Doc        = (_sAliasQ) -> e2_num
		_oCtaCorr:Serie      = (_sAliasQ) -> e2_prefixo
		_oCtaCorr:Parcela    = (_sAliasQ) -> e2_parcela
		_oCtaCorr:Origem     = 'BATSAFR'
		_oCtaCorr:Safra      = _sSafrComp
		_oCtaCorr:GrpPgSafra = (_sAliasQ) -> GRUPO_PAGTO
		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			else
				se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
				if empty (se2 -> e2_vachvex)  // Soh pra garantir...
					reclock ("SE2", .F.)
					se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
					msunlock ()
				endif

				// Se gerei conta corrente numa filial, preciso transferir esse lcto para a matriz, pois todos os pagamentos sao centralizados.
				if cFilAnt != '01' //.and. 'TESTE' $ upper (getenvserver ())  // por enqto apenas na base teste
					_oCtaCorr:FilDest = '01'
					U_Log2 ('info', 'Solicitando transferencia do saldo deste movimento para a matriz.')
					if ! _oCtaCorr:TransFil (_oCtaCorr:DtMovto)
						u_help ("A transferencia para outra filial nao foi possivel. " + _oCtaCorrT:UltMsg,, .T.)
					endif
				endif
			endif
		else
			U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
			_lContinua = .F.
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SZE")
	U_Log2 ('info', 'Finalizando ' + procname ())
return


// --------------------------------------------------------------------------
// Confere consistencia da conta corrente de associados X parcelas geradas nas notas de compra da safra.
static function _ConfSZI ()
	local _sAliasQ   := ''
	local _oSQL      := NIL
	local _sMsg      := ''
	local _aRegSZI   := {}
	// local _nRegSZI   := 0
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _oCtaCorr  := NIL
	local _nQtErros  := 0

	U_Log2 ('info', 'Iniciando ' + procname ())

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_VALOR, E2_HIST,E2_SALDO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2"
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT *"  // Precisa ser nota de safra
	_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=                 " WHERE V.SAFRA       = '" + _sSafrComp + "'"
	_oSQL:_sQuery +=                   " AND V.FILIAL      = SE2.E2_FILIAL"
	_oSQL:_sQuery +=                   " AND V.ASSOCIADO   = SE2.E2_FORNECE"
	_oSQL:_sQuery +=                   " AND V.LOJA_ASSOC  = SE2.E2_LOJA"
	_oSQL:_sQuery +=                   " AND V.SERIE       = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=                   " AND V.DOC         = SE2.E2_NUM"
	_oSQL:_sQuery +=                   " AND V.TIPO_NF     IN ('C', 'V')"
	_oSQL:_sQuery +=                   " AND V.TIPO_FORNEC = 'ASSOCIADO')"
	_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.T.)
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.ZI_FILIAL  = '" + (_sAliasQ) -> e2_filial + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + (_sAliasQ) -> e2_fornece + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + (_sAliasQ) -> e2_loja + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = '" + (_sAliasQ) -> e2_prefixo + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = '" + (_sAliasQ) -> e2_num + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_PARCELA = '" + (_sAliasQ) -> e2_parcela + "'"
		_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '13'"
		// _oSQL:Log ()
		_aRegSZI = _oSQL:RetFixo (1, 'Procurando registro no SZI ref. titulo NF compra safra', .F.)
		if len (_aRegSZI) == 0
			_sMsg += "Nao localizado registro na tabela SZI para parcela da nota de compra." + chr (13) + chr (10)
			_sMsg += _oSQL:_sQuery
		else
			szi -> (dbgoto (_aRegSZI [1,1]))
		//	U_Log2 ('info', "Verificando SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela)
			if szi -> zi_valor != (_sAliasQ) -> e2_valor
				_sMsg += "Valor do SZI (" + cvaltochar (szi -> zi_valor) + ") diferente do SE2 (" + cvaltochar ((_sAliasQ) -> e2_valor) + ")." + chr (13) + chr (10)
				_sMsg += _oSQL:_sQuery
			endif
			if szi -> zi_saldo != (_sAliasQ) -> e2_saldo
				// Tenta recalcular o saldo do SZI. Se ainda continuar errado, temos problemas.
				_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
				_oCtaCorr:AtuSaldo ()
				if szi -> zi_saldo != (_sAliasQ) -> e2_saldo
					_sMsg += "Saldo do SZI (" + cvaltochar (szi -> zi_saldo) + ") diferente do SE2 (" + cvaltochar ((_sAliasQ) -> e2_saldo) + ")." + chr (13) + chr (10)
					_sMsg += _oSQL:_sQuery
				endif
			endif
			if (_sAliasQ) -> e2_filial != '01'
				if szi -> zi_saldo > 0
					_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " deveria ter sido transferido para a matriz." + chr (13) + chr (10)
				else
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := " SELECT count (*) "
					_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZI") + " SZI "
					_oSQL:_sQuery +=  " WHERE SZI.ZI_FILIAL  = '01'"
					_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + szi -> zi_assoc + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + szi -> zi_lojasso + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = '" + szi -> zi_serie + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = '" + szi -> zi_doc + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_PARCELA = '" + szi -> zi_parcela + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_FILORIG = '" + szi -> zi_filial + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '13'"
					// _oSQL:Log ()
					if _oSQL:RetQry (1, .f.) == 0
						_sMsg += "SZI: FILIAL/DOC/SERIE/PARC " + szi -> zi_filial + ' ' + szi -> zi_doc + '/' + szi -> zi_serie + '-' + szi -> zi_parcela + " transferencia nao apareceu na matriz." + chr (13) + chr (10)
					endif
				endif
			endif
		endif

		if ! empty (_sMsg)
			_nQtErros ++
			U_Log2 ('erro', 'Inconsistencia SZI x SE2 safra - filial: ' + (_sAliasQ) -> e2_filial + ' NF: ' + (_sAliasQ) -> e2_num + ' forn: ' + (_sAliasQ) -> e2_fornece)
			U_Log2 ('erro', _sMsg)
			u_zzunu ({'999'}, 'Inconsistencia SZI x SE2 safra - filial: ' + (_sAliasQ) -> e2_filial + ' NF: ' + (_sAliasQ) -> e2_num + ' forn: ' + (_sAliasQ) -> e2_fornece, _sMsg)
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	U_Log2 ('info', 'Quantidade de inconsistencias encontradas: ' + cvaltochar (_nQtErros))
	U_Log2 ('info', 'Finalizando ' + procname ())
return



// --------------------------------------------------------------------------
// Transfere o titulo para a matriz (quando nao associado)
static function _TransFil ()
	local _lContinua := .T.
	local _aTit      := afill (array (8), '')
	local _oSQL      := NIL
	local _aBanco    := {}
	local _sAliasQ   := ''
	local _sSafrComp := strzero (year (dDataBase), 4)
	local _sFilDest  := '01'
	local _dDtBxTran := ctod ('')
	local _sHistSE5  := ''
	local _sTxtJSON  := ''
	local _oBatchDst := NIL
	Private lMsErroAuto := .F.
	
	u_log2 ('info', 'Iniciando ' + procname ())
	
	if _lContinua .and. cFilAnt == '01'
		U_Log2 ('erro', 'Transf.de titulos nao se aplica a matriz.')
		_lContinua = .F.
	endif

	// Procura a conta transitoria (eh diferente para cada filial).
	if _lContinua

		// Ajusta parametros de contabilizacao para NAO, pois a rotina automatica nao aceita.
		cPerg = 'FIN090'
		_aBkpSX1 = U_SalvaSX1 (cPerg)
		U_GravaSX1 (cPerg, "03", 2)  // Contabiliza online = nao

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=" SELECT TOP 1 A6_COD, A6_AGENCIA, A6_NUMCON"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA6") + " SA6 "
		_oSQL:_sQuery += " WHERE SA6.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SA6.A6_FILIAL  = '" + xfilial ("SA6") + "'"
		_oSQL:_sQuery +=   " AND SA6.A6_CONTA   = '101010201099'"
		_aBanco := aclone (_oSQL:Qry2Array (.f., .f.))
		if len (_aBanco) == 0
			U_Log2 ('erro', 'Registro ref.bco/conta transitoria entre filiais nao encontrado na tabela SA6 para esta filial.')
			_lContinua = .F.
		endif
	endif

	// Busca titulos a pagar de notas de compra de safra de fornecedores NAO ASSOCIADOS.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SE2.R_E_C_N_O_ as REGSE2, E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_VALOR, E2_HIST,E2_SALDO"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2"
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_oSQL:_sQuery +=    " AND EXISTS (SELECT *"  // Precisa ser nota de safra
		_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=                 " WHERE V.SAFRA       = '" + _sSafrComp + "'"
		_oSQL:_sQuery +=                   " AND V.FILIAL      = SE2.E2_FILIAL"
		_oSQL:_sQuery +=                   " AND V.ASSOCIADO   = SE2.E2_FORNECE"
		_oSQL:_sQuery +=                   " AND V.LOJA_ASSOC  = SE2.E2_LOJA"
		_oSQL:_sQuery +=                   " AND V.SERIE       = SE2.E2_PREFIXO"
		_oSQL:_sQuery +=                   " AND V.DOC         = SE2.E2_NUM"
		_oSQL:_sQuery +=                   " AND V.TIPO_NF     IN ('C', 'V')"
		_oSQL:_sQuery +=                   " AND V.TIPO_FORNEC = 'NAO ASSOCIADO')"
		_oSQL:_sQuery +=    " AND SE2.E2_SALDO = E2_VALOR"
		_oSQL:_sQuery +=  " ORDER BY SE2.E2_FORNECE, SE2.E2_LOJA, SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_PARCELA"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.T.)
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			se2 -> (dbgoto ((_sAliasQ) -> RegSE2))
			_dDtBxTran = se2 -> e2_emissao  // Quero transferir para a matriz na mesma data da emissao
			ddatabase = se2 -> e2_emissao  // Quero transferir para a matriz na mesma data da emissao

			U_Log2 ('info', 'Registro do SE2 a ser baixado via conta transitoria: ' + cvaltochar (se2 -> (recno ())) + ' ' + se2 -> e2_num + '/' + se2 -> e2_prefixo + '-' + se2 -> e2_parcela + ' de ' + se2 -> e2_fornece + '/' + se2 -> e2_loja)
			if se2 -> e2_saldo <= 0 .or. se2 -> e2_saldo != se2 -> e2_valor
				U_Log2 ('erro', 'Titulo sem saldo no financeiro ou saldo diferente do valor original.')
				(_sAliasQ) -> (dbskip ())
				loop
			endif

			// Documentacao cfe. TDN -->  http://tdn.totvs.com/pages/releaseview.action?pageId=6070725
			// Deve ser passado um array (aTitulos), com oito posicoes, sendo que cada posicao devera conter a seguinte composicao:
			// aTitulos [1]:= aRecnos   (array contendo os Recnos dos registros a serem baixados)
			// aTitulos [2]:= cBanco     (Banco da baixa)
			// aTitulos [3]:= cAgencia   (Agencia da baixa)
			// aTitulos [4]:= cConta     (Conta da baixa)
			// aTitulos [5]:= cCheque   (Cheque da Baixa)
			// aTitulos [6]:= cLoteFin    (Lote Financeiro da baixa)
			// aTitulos [7]:= cNatureza (Natureza do movimento bancario)
			// aTitulos [8]:= dBaixa     (Data da baixa)
			// Caso a contabilizacao seja online e a tela de contabilizacao possa ser mostrada em caso de erro no lancamento (falta de conta, debito/credito nao batem, etc) a baixa automatica em lote nao podera ser utilizada.
			// Somente sera processada se: 
			// MV_PRELAN = S
			// MV_CT105MS = N
			// MV_ALTLCTO = N

			_aTit [1] = {se2 -> (recno ())}  // Formato de array por que pode baixar mais de um titulo por vez.
			_aTit [2] = _aBanco [1, 1]
			_aTit [3] = _aBanco [1, 2]
			_aTit [4] = _aBanco [1, 3]
			
			// A transferencia de saldo entre filiais eh feita atraves de conta financeira transitoria. Para isso,
			// o saldo deve ser baixado na filial de origem atraves de conta transitoria e deve ser feita inclusao
			// de novo movimento na filial destino.
			_aTit [8] = _dDtBxTran
			
			_sHistSE5 = 'TR.SLD.P/FIL.' + _sFilDest + ' REF.' + se2 -> e2_hist

			lMsErroAuto = .F.
			MSExecAuto({|x,y| Fina090(x,y)},3,_aTit)
			If lMsErroAuto
				_lContinua = .F.
				U_Log2 ('erro', u_LeErro (memoread (NomeAutoLog ())))
			else

				// Arquivo SE5 vem, algumas vezes, desposicionado. Robert, 20/12/2016.
				se2 -> (dbgoto (_aTit [1, 1]))
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT MAX (R_E_C_N_O_)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE5") + " SE5 "
				_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND E5_FILIAL      = '" + se2 -> e2_filial  + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR  = '" + se2 -> e2_fornece + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_LOJA    = '" + se2 -> e2_loja    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO = '" + se2 -> e2_prefixo + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_NUMERO  = '" + se2 -> e2_num     + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_PARCELA = '" + se2 -> e2_parcela + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_TIPO    = '" + se2 -> e2_tipo    + "'"
				_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX = ''"
				//_oSQL:Log ()
				_nRegSE5 = _oSQL:RetQry ()
				if _nRegSE5 > 0
					se5 -> (dbgoto (_nRegSE5))
					reclock ('SE5', .F.)
					se5 -> e5_vachvex = se2 -> e2_vachvex
					se5 -> e5_histor  = left (_sHistSE5, tamsx3 ("E5_HISTOR")[1])
					msunlock ()
					u_log2 ('info', 'Regravei historico do SE5 para: ' + se5 -> e5_histor)
				else
					u_log2 ('erro', 'Nao encontrei SE5 para atualizar historico e chave externa.')
				endif
				
				if fk2 -> fk2_valor == se2 -> e2_valor .and. fk2 -> fk2_motbx == 'NOR'  // Para ter mais certeza de que estah posicionado no registro correto.
					reclock ('FK2', .F.)
					fk2 -> fk2_histor = left (alltrim (fk2 -> fk2_histor) + ' ' + _sHistSE5, tamsx3 ("FK2_HISTOR")[1])
					msunlock ()
					u_log2 ('info', 'Regravei historico do FK2 para: ' + fk2 -> fk2_histor)
				endif

				// Prepara dados para geracao de objeto JSON para posterior gravacao de batch.
				_sTxtJSON := '{"EmpDest":"'    + cEmpAnt           + '"'
				_sTxtJSON += ',"FilDest":"'    + _sFilDest         + '"'
				_sTxtJSON += ',"DtBxTran":"'   + dtos (_dDtBxTran) + '"'
				_sTxtJSON += ',"e2_filial":"'  + se2 -> e2_filial  + '"'
				_sTxtJSON += ',"e2_num":"'     + se2 -> e2_num     + '"'
				_sTxtJSON += ',"e2_prefixo":"' + se2 -> e2_prefixo + '"'
				_sTxtJSON += ',"e2_parcela":"' + se2 -> e2_parcela + '"'
				_sTxtJSON += ',"e2_fornece":"' + se2 -> e2_fornece + '"'
				_sTxtJSON += ',"e2_loja":"'    + se2 -> e2_loja    + '"'
				_sTxtJSON += ',"e2_valor":"'   + cvaltochar (se2 -> e2_valor) + '"'  // Este eh mais por garantia de encontrar o titulo certo...
				_sTxtJSON += '}'

				// Se fez a baixa na filial de origem, agenda rotina batch para a inclusao na filial de destino.
				_oBatchDst := ClsBatch():new ()
				_oBatchDst:Dados    = 'Transf.sld.SE2 fil.' + cFilAnt + ' p/' + _sFilDest + '-Forn.' + se2 -> e2_fornece + '/' + se2 -> e2_loja
				_oBatchDst:EmpDes   = cEmpAnt
				_oBatchDst:FilDes   = _sFilDest
				_oBatchDst:DataBase = se2 -> e2_emissao
				_oBatchDst:Modulo   = 6  // Campo E2_VACHVEX nao eh gravado em alguns modulos... vai saber...
				_oBatchDst:Comando  = "U_BatTrSE2()"
				_oBatchDst:JSON     = _sTxtJSON
				if ! _oBatchDst:Grava ()
					_oBatch:Mensagens += "Erro gravacao batch filial destino"
					_oBatch:Retorno = 'N'
					_lContinua = .F.
				endif
				
				
				// durante testes
//				EXIT


			endif
			(_sAliasQ) -> (dbskip ())
		enddo
	endif
	U_Log2 ('info', 'Finalizando ' + procname ())
return
