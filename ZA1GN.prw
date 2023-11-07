// Programa...: ZA1GN
// Autor......: Robert Koch (fonte original U_EtqPllGN de Julio Pedroni 10/03/2017)
// Data.......: 24/01/2022
// Descricao..: Gera etiquetas com base em NF de entrada (inicialmente para insumos e embalagens)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #etiquetas #pallets #nf_entrada
// #TabelasPrincipais #ZA1 #SD1
// #Modulos           #EST

// Historico de alteracoes:
// 24/01/2022 - Robert - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
//                     - Funcao EtqPllGN (interna) migrada para fonte externo ZA1GN.
// 02/02/2022 - Robert - Melhoria mensagens e tela que possibilita alterar qt.por embalagem (GLPI 11557)
// 24/02/2023 - Robert - Filtrar D1_TP='VD' em vez de B1_UM='LT' por que temos insumos recebidos em litros.
//                     - Gera etiquetas pelo metodo ClsEtiq:Grava() e nao mais por U_IncEtqPll()
// 12/04/2023 - Robert - Passa a gerar etiquetas com controle de semaforo.
// 06/11/2023 - Robert - Incluida coluna com a data de emissao da NF
//

// Como tem muitas colunas na array, vou usar nomes mais amigaveis.
#XTranslate .OK        => 1
#XTranslate .NF        => 2
#XTranslate .DtEmis    => 3
#XTranslate .DtDigit   => 4
#XTranslate .NomeFor   => 5
#XTranslate .ItemNF    => 6
#XTranslate .LoteFor   => 7
#XTranslate .LoteCtl   => 8
#XTranslate .CodItem   => 9
#XTranslate .DescItem  => 10
#XTranslate .UnMedida  => 11
#XTranslate .Quant     => 12
#XTranslate .Fornece   => 13
#XTranslate .Loja      => 14
#XTranslate .Serie     => 15
#XTranslate .DtFabric  => 16
#XTranslate .DtValid   => 17
#XTranslate .QtPorEmb  => 18
#XTranslate .CodNoFor  => 19
#XTranslate .DescNoFor => 20

// ----------------------------------------------------------------
User Function ZA1GN (_sNF, _sSerie, _sFornece, _sLoja)
	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	processa ({|| _AndaLogo ()})
return


// ----------------------------------------------------------------
static function _AndaLogo (_sNF, _sSerie, _sFornece, _sLoja)
	local _aEtiq     := {}
	local _nEtiq     := 0
	local _oSQL      := NIL
	local _aCols     := {}
	local _nQtPorPal := 0
	local _aPal      := {}
	local _lContinua := .T.
	local _nPal      := 0
	local _dDataIni  := date () - 7
	local _oEtiq     := NIL
	local _nLock     := 0

	if _lContinua
		_dDataIni = U_Get ("Buscar notas a partir de", "D", 8, "", "", _dDataIni, .F., '.T.')
		if valtype (_dDataIni) == 'U'
			u_help ("Processo cancelado",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		
		procregua (10)
		incproc ("Buscando notas sem etiqueta")

		_oSQL := ClsSQl ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "select ' '        AS OK,"  // Manter a mesma ordem dos campos que foi definida nos includes XTranslate mais acima
		_oSQL:_sQuery +=       " D1_DOC     as NotaFiscal," 
		_oSQL:_sQuery +=       " dbo.VA_DTOC(D1_EMISSAO) as DtEmis,"
		_oSQL:_sQuery +=       " dbo.VA_DTOC(D1_DTDIGIT) as DtDigit,"
		_oSQL:_sQuery +=       " A2_NOME    as Fornecedor,"
		_oSQL:_sQuery +=       " D1_ITEM    as Linha,"
		_oSQL:_sQuery +=       " D1_LOTEFOR as LoteFor,"
		_oSQL:_sQuery +=       " D1_LOTECTL as Lote,"
		_oSQL:_sQuery +=       " B1_COD     as CodItem,"
		_oSQL:_sQuery +=       " B1_DESC    as Item,"
		_oSQL:_sQuery +=       " B1_UM      as UM,"
		_oSQL:_sQuery +=       " D1_QUANT   as Quantidade,"
		_oSQL:_sQuery +=       " A2_COD     as CodFornec,"
		_oSQL:_sQuery +=       " A2_LOJA    as Loja,"
		_oSQL:_sQuery +=       " D1_SERIE   as Serie,"
		_oSQL:_sQuery +=       " dbo.VA_DTOC (B8_DFABRIC) as DtFabric,"
		_oSQL:_sQuery +=       " dbo.VA_DTOC (B8_DTVALID) as DtValid,"
		_oSQL:_sQuery +=       " ISNULL (SA5.A5_VAQTPAL, 0),"
		_oSQL:_sQuery +=       " ISNULL (SA5.A5_CODPRF, ''),"
		_oSQL:_sQuery +=       " ISNULL (SA5.A5_NOMPROD, '')"
		_oSQL:_sQuery += " from " + RetSQLName ("SD1") + " as SD1 "
		_oSQL:_sQuery +=          " LEFT JOIN " + RetSQLName ("SA5") + " SA5 "
			_oSQL:_sQuery +=               " ON (SA5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=               " AND SA5.A5_FILIAL  = '" + xfilial ("SA5") + "'"
		_oSQL:_sQuery +=               " AND SA5.A5_FORNECE = SD1.D1_FORNECE"
		_oSQL:_sQuery +=               " AND SA5.A5_LOJA    = SD1.D1_LOJA"
		_oSQL:_sQuery +=               " AND SA5.A5_PRODUTO = SD1.D1_COD),"
		_oSQL:_sQuery +=            RetSQLName ("SB1") + " as SB1, "
		_oSQL:_sQuery +=            RetSQLName ("SA2") + " as SA2, "
		_oSQL:_sQuery +=            RetSQLName ("SF4") + " as SF4, "
		_oSQL:_sQuery +=            RetSQLName ("SB8") + " as SB8 "
		_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD1.D1_LOTECTL != ''"
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_QUANT   > 0"
		_oSQL:_sQuery +=   " AND SD1.D1_DTDIGIT >= '" + dtos (_dDataIni) + "'"
		if ! empty (_sNF) .and. ! empty (_sSerie) .and. ! empty (_sFornece) .and. ! empty (_sLoja)
			_oSQL:_sQuery += " AND SD1.D1_FORNECE = '" + _sFornece + "'"
			_oSQL:_sQuery += " AND SD1.D1_LOJA    = '" + _sLoja    + "'"
			_oSQL:_sQuery += " AND SD1.D1_DOC     = '" + _sNF      + "'"
			_oSQL:_sQuery += " AND SD1.D1_SERIE   = '" + _sSerie   + "'"
		endif
		_oSQL:_sQuery +=   " AND SD1.D1_COD      = B1_COD"
		_oSQL:_sQuery +=   " AND SD1.D1_TP != 'VD'"  // Nao queremos, ainda, etiquetar material a granel
		_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = D1_LOJA"
		_oSQL:_sQuery +=   " AND SA2.A2_COD      = D1_FORNECE"
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
		// _oSQL:_sQuery +=   " AND SB1.B1_UM      != 'LT'"  // Granel nao interessa ainda (eventalmente optemos por etiquetas nos tanques ?)
		_oSQL:_sQuery +=   " AND SB1.B1_GRUPO   != '0400'"  // Uvas
		_oSQL:_sQuery +=   " AND SB1.B1_RASTRO   = 'L'"
		_oSQL:_sQuery +=   " AND SF4.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
		_oSQL:_sQuery +=   " AND SF4.F4_CODIGO   = D1_TES"
		_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE  = 'S'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (select *"
		_oSQL:_sQuery +=                   " FROM " + RetSQLName ("ZA1") + " ZA1 "
		_oSQL:_sQuery +=                  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                    " AND ZA1_FILIAL = SD1.D1_FILIAL"
		_oSQL:_sQuery +=                    " AND ZA1_DOCE   = SD1.D1_DOC"
		_oSQL:_sQuery +=                    " AND ZA1_SERIEE = SD1.D1_SERIE"
		_oSQL:_sQuery +=                    " AND ZA1_FORNEC = SD1.D1_FORNECE"
		_oSQL:_sQuery +=                    " AND ZA1_LOJAF  = SD1.D1_LOJA"
		_oSQL:_sQuery +=                    " AND ZA1_ITEM   = SD1.D1_ITEM"
		_oSQL:_sQuery +=                    " AND ZA1_APONT != 'I')"
		_oSQL:_sQuery +=   " AND SB8.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB8.B8_FILIAL  = SD1.D1_FILIAL"
		_oSQL:_sQuery +=   " AND SB8.B8_PRODUTO = SD1.D1_COD"
		_oSQL:_sQuery +=   " AND SB8.B8_LOTECTL = SD1.D1_LOTECTL"
		// Nao vamos integrar com FullWMS ainda ---> _oSQL:_sQuery += "	EXISTS (SELECT * FROM v_wms_item I WHERE I.coditem = B1_COD) and"
		_oSQL:_sQuery += " Order By D1_DTDIGIT, D1_DOC"
		_oSQL:Log ()
		
		_aEtiq = aclone(_oSQL:Qry2Array ())
		if len (_aEtiq) == 0
			u_help ("Nao encontrei nenhum item de nota de entrada precisando gerar etiquetas.", _oSQL:_sQuery, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		
		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _nEtiq = 1 to len (_aEtiq)
			_aEtiq [_nEtiq, .Ok] = .F.
		next
		u_log (_aetiq)

		_aCols = {}
		aadd (_aCols, {.NF,        'Nota Fiscal',       40, ''})
		aadd (_aCols, {.DtEmis,    'Emissao NF',        40, ''})
		aadd (_aCols, {.DtDigit,   'Digitacao NF',      40, ''})
		aadd (_aCols, {.NomeFor,   'Nome fornecedor',   60, ''})
		aadd (_aCols, {.LoteFor,   'Lote Forn.',        40, ''})
		aadd (_aCols, {.LoteCtl,   'Lote Interno',      40, ''})
		aadd (_aCols, {.DtFabric,  'Dt.fabric.',        30, ''})
		aadd (_aCols, {.DtValid,   'Dt.valid.',         30, ''})
		aadd (_aCols, {.CodItem,   'Produto',           20, ''})
		aadd (_aCols, {.DescItem,  'Descrição',        170, ''})
		aadd (_aCols, {.Quant,     'Quant.',            30, ''})
		aadd (_aCols, {.UnMedida,  'UM',                10, ''})
		aadd (_aCols, {.QtPorEmb,  'Qt.embalag',        35, ''})
		aadd (_aCols, {.Fornece,   'Fornecedor',        30, ''})
		aadd (_aCols, {.Loja,      'Loja',              30, ''})
		aadd (_aCols, {.CodNoFor,  'Cod.no fornec.',    50, ''})
		aadd (_aCols, {.DescNoFor, 'Descr.no fornec.', 150, ''})
		
		U_MBArray (@_aEtiq, 'Selecione as notas para gerar etiquetas', _aCols, 1)
		
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, .Ok]
			
				// Busca quantidade por embalagem no relacionamento produto X fornecedor.
				_aPal = {}
				sa5 -> (dbsetorder (2))
				if ! sa5 -> (dbseek (xfilial ("SA5") + _aEtiq [_nEtiq, .CodItem] + _aEtiq [_nEtiq, .Fornece] + _aEtiq [_nEtiq, .Loja], .F.))
					u_help ("Nao encontrei relacionamento do produto '" + alltrim(_aEtiq [_nEtiq, .CodItem]) + "' - " + alltrim(_aEtiq [_nEtiq, .DescItem]) + " com o fornecedor '" + _aEtiq [_nEtiq, .Fornece] + '/' + _aEtiq [_nEtiq, .Loja] + "' (" + alltrim(_aEtiq [_nEtiq, .NomeFor]) + ") para buscar o tamanho padrao de embalagens.",, .t.)
					loop
				elseif sa5 -> a5_vaqtpal == 0
					u_help ("Quantidade por embalagem nao informada para o produto '" + alltrim(_aEtiq [_nEtiq, .CodItem]) + "' - " + alltrim(_aEtiq [_nEtiq, .DescItem]) + " no fornecedor '" + _aEtiq [_nEtiq, .Fornece] + '/' + _aEtiq [_nEtiq, .Loja] + "'. Verifique o campo '" + alltrim (RetTitle ("A5_VAQTPAL")) + "' na amarracao produto X fornecedor.",, .t.)
					loop
				else
					_nQtPorPal = sa5 -> a5_vaqtpal
				endif
				u_log2 ('debug', '_nQtPorPal:' + cvaltochar (_nQtPorPal))

				// Permite ao usuario alteracao na quantidade por embalagem, para casos de granel onde a quantidade por vir um pouco diferente do cadastro.
				do while .t.
					// Usa a funcao padrao de palletizacao para manter compatibilidade com outras rotinas.
					_aPal := aclone (U_VA_QTDPAL (_aEtiq [_nEtiq, .CodItem], _aEtiq [_nEtiq, .Quant], _nQtPorPal))
					u_log2 ('debug', _aPal)

					if U_MsgYesNo ("Serao geradas " + cvaltochar (len (_aPal)) + " etiquetas (" + cvaltochar (_nQtPorPal) + " cada) para o produto '" + alltrim(_aEtiq [_nEtiq, .CodItem]) + "' (" + alltrim(_aEtiq [_nEtiq, .DescItem]) + "). Confirma?")
						exit
					endif
					if U_MsgYesNo ("Deseja informar uma quantidade diferente por embalagem?")
						_nQtPorPal = U_Get ("Quantidade por embalagem", "N", 6, "", "", _nQtPorPal, .F., '.T.')
						if empty (_nQtPorPal)
							loop
						endif
						if 100 - (abs (_nQtPorPal * 100) / abs (_aEtiq [_nEtiq, .QtPorEmb])) > 10
							u_help ("Variacao acima do permitido em relacao ao cadastro de produto x fornecedor",, .t.)
							loop
						endif
					else
						_aPal = {}
						exit
					endif
				enddo

				if len (_aPal) > 0
					procregua (len (_aPal))

					// Controla semaforo, por que a numeracao deve ser unica.
					_nLock := U_Semaforo ('GeraNumeroZA1', .T.)  // Usar a mesma chave em todas as chamadas!
					if _nLock == 0
						u_help ("Bloqueio de semaforo na geracao de numero de etiqueta.",, .t.)
					else
						for _nPal = 1 to len (_aPal)
							incproc ("Gerando etiqueta " + cvaltochar (_nPal) + " de " + cvaltochar (len (_aPal)))

							_oEtiq := ClsEtiq ():New ()
							_oEtiq:DtEmis       = date ()
							_oEtiq:Produto      = _aEtiq [_nEtiq, .CodItem]
							_oEtiq:Quantidade   = _aPal [_nPal, 2]
							_oEtiq:DocEntrForn  = _aEtiq [_nEtiq, .Fornece]
							_oEtiq:DocEntrLoja  = _aEtiq [_nEtiq, .Loja]
							_oEtiq:DocEntrNum   = _aEtiq [_nEtiq, .nf]
							_oEtiq:DocEntrSerie = _aEtiq [_nEtiq, .Serie]
							_oEtiq:DocEntrItem  = _aEtiq [_nEtiq, 5]
							_oEtiq:QtEtqGrupo   = len (_aPal)
							_oEtiq:SeqNoGrupo   = _nPal
							if ! _oEtiq:Grava ((_nLock != 0))
								u_help (_oEtiq:UltMsg += "Nao foi possivel gravar a etiqueta.",, .t.)
								exit
							endif

						next
					endif

					// Libera semaforo.
					if _nLock > 0
						U_Semaforo (_nLock)
					endif

					u_log2 ('debug', 'etiq.geradas')
					U_EtqPlltG ('', _aEtiq [_nEtiq, .nf], _aEtiq [_nEtiq, .Serie], _aEtiq [_nEtiq, .Fornece], _aEtiq [_nEtiq, .Loja], 'I')
					u_log2 ('debug', 'retornou do U_EtqPlltG')
				else
					u_help ("Nenhuma etiqueta gerada para o produto '" + alltrim(_aEtiq [_nEtiq, .CodItem]) + "' - " + alltrim(_aEtiq [_nEtiq, .DescItem]))
				endif
			endif
		next
	endif
return
