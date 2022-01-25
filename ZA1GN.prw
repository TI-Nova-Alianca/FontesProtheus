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
//

//#include "rwmake.ch"

// ----------------------------------------------------------------
User Function ZA1GN (_sNF, _sSerie, _sFornece, _sLoja)
	local _aEtiq     := {}
	local _nEtiq     := 0
	local _oSQL      := NIL
	local _aCols     := {}
	local _nQtPorPal := 0
	local _aPal      := {}
	local _lContinua := .T.
	local _i         := 0
	local _dDataIni  := date () - 7

	// Verifica se o usuario tem liberacao.
	if ! U_ZZUVL ('074', __cUserID, .T.)
		_lContinua = .F.
	endif

	if _lContinua
		_dDataIni = U_Get ("Buscar notas a partir de", "D", 8, "", "", _dDataIni, .F., '.T.')
		
		procregua (10)
		incproc ("Buscando notas sem etiqueta")

		_oSQL := ClsSQl ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "select " 
		_oSQL:_sQuery += " ' ' as OK, " 
		_oSQL:_sQuery += " D1_DOC     as NotaFiscal, " 
		_oSQL:_sQuery += " dbo.VA_DTOC(D1_EMISSAO) as Emissao, "
		_oSQL:_sQuery += " A2_NOME    as Fornecedor, "
		_oSQL:_sQuery += " D1_ITEM    as Linha, "
		_oSQL:_sQuery += " D1_LOTEFOR as LoteFor, "
		_oSQL:_sQuery += " D1_LOTECTL as Lote, "
		_oSQL:_sQuery += " B1_COD     as Codigo, " 
		_oSQL:_sQuery += " B1_DESC    as Item, "
		_oSQL:_sQuery += " B1_UM      as UM, "
		_oSQL:_sQuery += " D1_QUANT   as Quantidade, " 
		_oSQL:_sQuery += " A2_COD     as CodFornec, " 
		_oSQL:_sQuery += " A2_LOJA    as Loja, " 
		_oSQL:_sQuery += " D1_SERIE   as Serie " 
		_oSQL:_sQuery += "from "
		_oSQL:_sQuery += " " + RetSQLName ("SD1") + " as SD1, " 
		_oSQL:_sQuery += " " + RetSQLName ("SB1") + " as SB1, "
		_oSQL:_sQuery += " " + RetSQLName ("SA2") + " as SA2, "
		_oSQL:_sQuery += " " + RetSQLName ("SF4") + " as SF4 "
		_oSQL:_sQuery += "where "
		_oSQL:_sQuery += " D1_COD    = B1_COD     and "
		_oSQL:_sQuery += " A2_FILIAL = '" + xfilial ("SA2") + "' and "
		_oSQL:_sQuery += " A2_LOJA   = D1_LOJA    and "
		_oSQL:_sQuery += " A2_COD    = D1_FORNECE and "
		_oSQL:_sQuery += " B1_FILIAL = '" + xfilial ("SB1") + "' and "
		_oSQL:_sQuery += " B1_UM <> 'LT'                 and "  // Granel nao interessa ainda (eventalmente optemos por etiquetas os tanques ?)
		_oSQL:_sQuery += " B1_GRUPO != '0400'            and "  // Uvas
		_oSQL:_sQuery += " B1_RASTRO = 'L'               and "
		_oSQL:_sQuery += " D1_LOTECTL <> ''              and "
		_oSQL:_sQuery += " D1_FILIAL = '" + xfilial ("SD1") + "' and "
		_oSQL:_sQuery += " D1_QUANT  > 0                 and "
		_oSQL:_sQuery += " D1_DTDIGIT >= '" + dtos (_dDataIni) + "' and "
		if ! empty (_sNF) .and. ! empty (_sSerie) .and. ! empty (_sFornece) .and. ! empty (_sLoja)
			_oSQL:_sQuery += " D1_FORNECE = '" + _sFornece + "' and "
			_oSQL:_sQuery += " D1_LOJA    = '" + _sLoja    + "' and "
			_oSQL:_sQuery += " D1_DOC     = '" + _sNF      + "' and "
			_oSQL:_sQuery += " D1_SERIE   = '" + _sSerie   + "' and "
		endif
		_oSQL:_sQuery += " F4_CODIGO = D1_TES     and "
		_oSQL:_sQuery += " F4_ESTOQUE = 'S'              and "
//		_oSQL:_sQuery += " B1_COD not in (select ZA1_PROD from ZA1010 where ZA1_FILIAL = D1_FILIAL and ZA1_DOCE = D1_DOC and ZA1_SERIEE = D1_SERIE and ZA1_PROD = D1_COD and ZA1_APONT <> 'I' and D1_ITEM = ZA1_ITEM and ZA1010.D_E_L_E_T_ = '') and "
		_oSQL:_sQuery += " NOT EXISTS (select *"
		_oSQL:_sQuery +=               " FROM " + RetSQLName ("ZA1") + " ZA1 "
		_oSQL:_sQuery +=              " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                " AND ZA1_FILIAL = SD1.D1_FILIAL"
		_oSQL:_sQuery +=                " AND ZA1_DOCE   = SD1.D1_DOC"
		_oSQL:_sQuery +=                " AND ZA1_SERIEE = SD1.D1_SERIE"
		_oSQL:_sQuery +=                " AND ZA1_FORNEC = SD1.D1_FORNECE"
		_oSQL:_sQuery +=                " AND ZA1_LOJAF  = SD1.D1_LOJA"
		_oSQL:_sQuery +=                " AND ZA1_ITEM   = SD1.D1_ITEM"
		_oSQL:_sQuery +=                " AND ZA1_APONT != 'I') AND"

		// Nao vamos integrar com FullWMS ainda ---> _oSQL:_sQuery += "	EXISTS (SELECT * FROM v_wms_item I WHERE I.coditem = B1_COD) and"
		_oSQL:_sQuery += " SD1.D_E_L_E_T_ = '' and "
		_oSQL:_sQuery += " SB1.D_E_L_E_T_ = '' and "
		_oSQL:_sQuery += " SA2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "Order By "
		_oSQL:_sQuery += " D1_FILIAL, " 
		_oSQL:_sQuery += " D1_EMISSAO, "
		_oSQL:_sQuery += " D1_DOC "
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
			_aEtiq [_nEtiq, 1] = .F.
		next
		
		_aCols = {}
		aadd (_aCols, {2, 'Nota Fiscal',     40, ''})
		aadd (_aCols, {3, 'Emissão',       40, ''})
		aadd (_aCols, {4, 'Fornecedor', 70, ''})
		aadd (_aCols, {5, 'Linha', 30, ''})
		aadd (_aCols, {6, 'Lote Forn.', 40, ''})
		aadd (_aCols, {7, 'Lote Interno', 40, ''})
		aadd (_aCols, {8, 'Produto', 20, ''})
		aadd (_aCols, {9, 'Descrição', 150, ''})
		aadd (_aCols, {10,'UM', 10, ''})
		aadd (_aCols, {11,'Quant.', 30, ''})
		aadd (_aCols, {12,'Cod.forn.', 30, ''})
		aadd (_aCols, {13,'Loja', 30, ''})
		
		U_MBArray (@_aEtiq, 'Selecione as notas para gerar etiquetas', _aCols, 1)
		
		for _nEtiq = 1 to len (_aEtiq)
			if _aEtiq [_nEtiq, 1]
			
				// Busca quantidade por pallet no relacionamento produto X fornecedor.
				sa5 -> (dbsetorder (2))
				if ! sa5 -> (dbseek (xfilial ("SA5") + _aEtiq [_nEtiq, 8] + _aEtiq [_nEtiq, 12] + _aEtiq [_nEtiq, 13], .F.))
					u_help ("Nao encontrei relacionamento do produto '" + alltrim(_aEtiq [_nEtiq, 8]) + "' com o fornecedor '" + _aEtiq [_nEtiq, 12] + '/' + _aEtiq [_nEtiq, 13] + "' para buscar o padrao de palletizacao.")
					loop
				elseif sa5 -> a5_vaqtpal == 0
					u_help ("Quantidade por pallet nao informada para o produto '" + alltrim(_aEtiq [_nEtiq, 8]) + "' no fornecedor '" + _aEtiq [_nEtiq, 12] + '/' + _aEtiq [_nEtiq, 13] + "'. Verifique o campo '" + alltrim (RetTitle ("A5_VAQTPAL")) + "' na amarracao produto X fornecedor.")
					loop
				else
					_nQtPorPal = sa5 -> a5_vaqtpal
				endif
				u_log2 ('debug', '_nQtPorPal:' + cvaltochar (_nQtPorPal))

				// Usa a funcao padrao de palletizacao para manter compatibilidade com outras rotinas.
				_aPal := aclone (U_VA_QTDPAL (_aEtiq [_nEtiq, 8], _aEtiq [_nEtiq, 11], _nQtPorPal))
				u_log2 ('debug', _aPal)

				if U_MsgYesNo ("Serao geradas " + cvaltochar (len (_aPal)) + " etiquetas (" + cvaltochar (_nQtPorPal) + " cada) para este item. Confirma?")
					procregua (len (_aPal))
					for _i=1 to len(_aPal)
						incproc ("Gerando etiqueta " + cvaltochar (_i) + " de " + cvaltochar (len (_aPal)))
						U_IncEtqPll (_aEtiq [_nEtiq, 8], '', _aPal[_i, 2], _aEtiq [_nEtiq, 12], _aEtiq [_nEtiq, 13], _aEtiq [_nEtiq, 2], _aEtiq [_nEtiq, 14], date(), _aEtiq [_nEtiq, 5], '')
					next
					u_log2 ('debug', 'etiq.geradas')
					U_EtqPlltG ('', _aEtiq [_nEtiq, 2], _aEtiq [_nEtiq, 14], _aEtiq [_nEtiq, 12], _aEtiq [_nEtiq, 13], 'I')
					u_log2 ('debug', 'retornou do U_EtqPlltG')
				endif
			endif
		next
	endif
return
