// Programa:   BatSafr
// Autor:      Robert Koch
// Data:       28/12/2011
// Descricao:  Envia e-mail com inconsistencias encontradas durante a safra.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 06/03/2012 - Robert - Nao considerava cargas aglutinadas.
// 13/03/2012 - Robert - Criada verificacao de cadastros viticolas nao renovados.
// 06/02/2013 - Robert - Separados os tipos de verificacao via parametro na chamada da funcao.
//                     - Passa a validar a safra atual pela data doo sistema.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 18/01/2016 - Robert - Desconsidera fornecedor 003114 no teste de cargas (transferencias da linha Jacinto para matriz)
// 25/01/2016 - Robert - Envia avisos para o grupo 045.
// 16/01/2019 - Robert - Incluido grupo 047 no aviso de cargas sem contranota.
//

// --------------------------------------------------------------------------
user function BatSafr (_sQueFazer)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _aCols     := {}
	local _aSemNota  := {}
	//local _sDestin   := ""
	local _oSQL      := NIL

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
	endif

	// Verifica contranotas com cadastro viticola desatualizado
	if _sQueFazer == '2'
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
	endif

	// Verifica composicao das parcelas das notas. Em 2021 jah estamos fazendo 'compra' durante a safra.
	// Como as primeiras notas sairam erradas, optei por fazer esta rotina de novo a identifica-las
	// e manter monitoramento.
	if _sQueFazer == '3' .and. year (date ()) >= 2021
		_ConfParc ()
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return .T.



// --------------------------------------------------------------------------
static function _ConfParc ()
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
	
	// soh  pra ver como ele calcula
	_oSQL:_sQuery +=    " and V.DATA = '20210114'"
	//_oSQL:_sQuery +=    " and V.VALOR_FRETE = 0"
	//_oSQL:_sQuery +=    " and GRUPO_PAGTO = 'C'"

	
	_oSQL:_sQuery += " GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:_sQuery += " ORDER BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, GRUPO_PAGTO"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb (.F.)
	do while ! (_sAliasQ) -> (eof ())
		_sMsg = ''
		U_Log2 ('info', 'Iniciando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc)
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
				aadd (_aParcReal, {se2 -> e2_vencrea, se2 -> e2_valor * 100 / (_sAliasQ) -> vlr_uvas, se2 -> e2_valor})
				se2 -> (dbskip ())
			enddo

			// Gera array de parcelas previstas cfe. regras de pagamento.
			_aParcPrev = U_VA_RusPP ((_sAliasQ) -> safra, (_sAliasQ) -> grupo_pagto, (_sAliasQ) -> vlr_uvas, (_sAliasQ) -> vlr_frt)
			_nSomaPrev = 0
			for _nParc = 1 to len (_aParcPrev)
				aadd (_aParcPrev [_nParc], round ((_aParcPrev [_nParc, 3] * ((_sAliasQ) -> vlr_uvas + (_sAliasQ) -> vlr_frt) / 100), 2))
				_nSomaPrev += _aParcPrev [_nParc, 4]
			next

			U_Log2 ('aviso', 'como estah no SE2:')
			U_Log2 ('aviso', _aParcReal)

			if len (_aParcReal) != len (_aParcPrev)
				_sMsg += 'Encontrei qt.diferente (' + cvaltochar (len (_aParcReal)) + ') de parcelas no SE2 do que o previsto (' + cvaltochar (len (_aParcPrev)) + ')' + chr (13) + chr (10)
			else
				for _nParc = 1 to len (_aParcReal)
					if _aParcReal [_nParc, 1] != _aParcPrev [_nParc, 2]
						_sMsg += "Diferenca nas datas - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
					endif
					if round (_aParcReal [_nParc, 3], 0) != round (_aParcPrev [_nParc, 4], 0)
						_sMsg += "Diferenca nos valores de uva - linha " + cvaltochar (_nParc) + chr (13) + chr (10)
					endif
				next
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
			endif
		endif
		if ! empty (_sMsg)
			U_Log2 ('erro', 'Inconsistencia parcelamento safra - filial: ' + (_sAliasQ) -> filial + ' NF: ' + (_sAliasQ) -> doc)
			U_Log2 ('erro', _sMsg)
			U_Log2 ('aviso', 'como deveria estar no SE2:')
			U_Log2 ('aviso', _aParcPrev)
			//u_zzunu ({'122'}, 'Inconsistencia parcelamento safra', _sMsg)

			// cai fora no primeiro erro encontrado (estou ainda ajustando)
//			EXIT   // REMOVER DEPOIS !!!!!!!!!!!!!!!!!

		endif
		U_Log2 ('info', 'Finalizando F' + (_sAliasQ) -> filial + ' NF' + (_sAliasQ) -> doc)
		(_sAliasQ) -> (dbskip ())
	enddo
return
