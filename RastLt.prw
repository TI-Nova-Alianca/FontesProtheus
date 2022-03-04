// Programa.: RastLt
// Autor....: Robert Koch
// Data.....: 09/05/2017 (inicio)
// Descricao: Gera consulta de rastreabilidade de lote de produto.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Gera arvore de consulta de rastreabilidade
// #PalavasChave      #rastreabilidade
// #TabelasPrincipais #SD1 #SD2 #SD3
// #Modulos           #EST

// Historico de alteracoes:
// 15/08/2018 - Robert - Verifica o tamanho da string de retorno antes de fazer as chamadas recursivas.
//                     - Filtra uma OP da filial 09 que teve erro de apontamento.
// 24/08/2018 - Robert - Ignora NF 000016150 (transf.indevida filial 07 para 01).
// 20/02/2020 - Robert - Desabilitada leitura de talhao de terra quando NF de entrada de safra.
// 09/09/2021 - Robert - Nas NF de entrada, passa a desconsiderar retornos de industrializacao (GLPI 10913)
// 28/01/2022 - Robert - Ajuste na busca das cargas de safra.
//                     - Alimenta variavel _aLtXLS58 para relatorio CENECOOP (GLPI 11514)
// 14/02/2022 - Robert - Criado calculo de proporcionalizacao de quantidades entre niveis (GLPI 11514)
//                     - Transferencias entre lotes desconsideravam casos de outro item com mesmo numero de lote (GLPI 11620)
//                     - Tabela VA_SM0 (customizada) trocada para SYS_COMPANY.
//                     - Limite de tamanho para a string de retorno aumentado de 30000 para 50000 caracteres.
//                     - Passa a buscar transf. entre filiais na view VA_VTRANSF_ENTRE_FILIAIS (GLPI 11620)
// 23/02/2022 - Robert - Lista de cargas de safra (usada pelo VA_XLS58) passa a incluir filial e safra (GLPI 11664)
// 02/03/2022 - Robert - Melhoria logs diversos.
//                     - Aumentado nivel maximo de 10 para 11
//                     - Aumentado tamanho maximo da string de retorno de 50000 para 60000 caracteres.
//

// --------------------------------------------------------------------------
user function RastLT (_sFilial, _sProduto, _sLote, _nNivel, _aHist, _nQtProp)
	local _sDescri  := ""
	local _sAliasQ  := ""
	local _sRet     := ""
	local _aOP      := {}
	local _nOP      := 0
	local _aReqOP   := {}
	local _nReqOP   := 0
	local _aCons    := {}
	local _nCons    := 0
	local _aEntTrLt := {}
	local _aSaiTrLt := {}
	local _nTrLt    := 0
	local _aSD1     := {}
	local _nSD1     := 0
	local _aSD2     := {}
	local _nSD2     := 0
	local _sLaudo   := ''
	local _nNivFold := 10  // A partir deste nivel gera os nodos 'compactados' para nao ficar grande demais na visualizacao inicial.
	local _sQuebra  := "&#xa;"  // Representacao de uma quebra de linha na visualizacao do FreeMind
	local _aCarga   := ""
	local _nMaxStr  := 60000  // Limite para o tamanho da string de retorno (pelo que sei, o maximo eh 64K)
	static _sID     := '0000'  // Criado como STATIC para gerar sempre IDs unicos, mesmo com chamadas recursivas.

	U_Log2 ('info', 'Iniciando filial: ' + _sFilial + ' produto: ' + _sProduto + ' lote: ' + _sLote + ' nivel: ' + cvaltochar (_nNivel))
//	U_Log2 ('debug', '[' + procname () + ']Alias() = ' + alias ())
	_aHist := iif (_aHist == NIL, {}, _aHist)

	// Com tantas chamadas recursivas, parece que chega um momento em que fico sem ALIAS() e tenho problemas com funcoes como FBuscaCpo().
	dbselectarea ("SB1")

	if _nNivel == 0
		procregua (1000)
	else
		incproc ('Item ' + alltrim (_sProduto) + ' lote ' + alltrim (_sLote) + ' nivel ' + cvaltochar (_nNivel))
	endif

	// Limita a 'profundidade' de pesquisa.
	if abs (_nNivel) > 15  // 10
		U_Log2 ('aviso', "Limite de 'profundidade de pesquisa' atingido.")
		_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) nivel maximo atingido"></node>'
	else
		
		// Encontramos muitos casos onde um lote A foi transferido para o lote B, que novamente foi transferido para o lote A
		if ascan (_aHist, _sFilial + _sProduto + _sLote)
			U_Log2 ('aviso', 'Detectada recursividade na movimentacao para filial/produto/lote ' + _sFilial + _sProduto + _sLote)
			_sDescri := "Recurs." + _sQuebra //Detectada recursividade na movimentacao" + _sQuebra
			_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="' + _sDescri + '"></node>'
		else
			aadd (_aHist, _sFilial + _sProduto + _sLote)
			sb1 -> (dbsetorder (1))
			if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
		
				// Chamada inicial: preciso gerar todo o arquivo de saida.
				if _nNivel == 0
					_sID = soma1 (_sID)
					_sDescri := ""
					_sDescri += alltrim (_sProduto) + '-' + U_NoAcento (alltrim (sb1 -> b1_desc)) + _sQuebra
					_sDescri += 'Filial ' + _sFilial + ' - Lote ' + _sLote + _sQuebra
					_sDescri += 'Qt. base: ' + alltrim (transform (_nQtProp, '@E 999,999,999,999.99')) + ' ' + sb1 -> b1_um
					_sRet := ""
					_sRet += '<map version="1.0.1">'
					_sRet += '<node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" TEXT="' + _sDescri + '">'

					// Abre o nodo das entradas
					_sID = soma1 (_sID)
					_sRet += '<node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" POSITION="left" TEXT="ENTRADAS">'
				endif
		
				// Busca entradas por OP
				// - Se o item controla rastreabilidade pelo Protheus, usa o campo do lote.
				// - Senao, assume o numero da OP como sendo o lote. Quando a rastreabilidade for completa pelo Protheus, isso vai ser desnecessario.
				if _nNivel <= 0 .and. (sb1 -> b1_rastro == 'L' .or. (sb1 -> b1_rastro == 'N' .and. sb1 -> b1_tipo == 'PA'))  
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D3_OP, SUM (D3_QUANT), D3_UM, MAX (D3_EMISSAO)"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
					_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=   " AND SD3.D3_TM      < '5'"
					_oSQL:_sQuery +=   " AND SD3.D3_OP     != ''"
					_oSQL:_sQuery +=   " AND SD3.D3_CF      like 'PR%'"
					_oSQL:_sQuery +=   " AND SD3.D3_QUANT   > 0"
					_oSQL:_sQuery +=   " AND NOT (SD3.D3_FILIAL = '09' AND SD3.D3_OP = '00332501001')"  // OP que teria jogado vinho dentro do mosto e deve ser desconsiderada
					_oSQL:_sQuery +=   " AND SD3.D3_COD     = '" + _sProduto + "'"
					if sb1 -> b1_rastro == 'L'
						_oSQL:_sQuery +=   " AND SD3.D3_LOTECTL = '" + _sLote + "'"
					else
						_oSQL:_sQuery +=   " AND SD3.D3_OP      like '" + _sLote + "%'"
					endif
					_oSQL:_sQuery += " GROUP BY D3_OP, D3_UM"
					// _oSQL:Log ()
					_aOP := aclone (_oSQL:Qry2Array (.F., .F.))
					for _nOP = 1 to len (_aOP)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Aqui trata-se da quantidade final produzida pela OP (de 1 para 1)

						_sID = soma1 (_sID)
						_sDescri := 'O.P. ' + alltrim (_aOP [_nOP, 1]) + _sQuebra
						_sDescri += dtoc (stod (_aOP [_nOP, 4])) + _sQuebra
						_sDescri += _FmtQt (_aOP [_nOP, 2], _aOP [_nOP, 3], _nQtProp2) + _sQuebra
						_sRet += '<node BACKGROUND_COLOR="#cccc00" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
					
						// Busca requisicoes da OP.
						_oSQL := ClsSQL ():New ()
						_oSQL:_sQuery := "SELECT D3_COD, D3_LOTECTL, SUM (D3_QUANT), D3_UM, B1_DESC"
						_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3, "
						_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
						_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
						_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
						_oSQL:_sQuery +=   " AND SB1.B1_COD     = SD3.D3_COD"
						_oSQL:_sQuery +=   " AND SD3.D_E_L_E_T_ = ''"
						_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + _sFilial + "'"
						_oSQL:_sQuery +=   " AND SD3.D3_CF      LIKE 'RE%'"
						_oSQL:_sQuery +=   " AND SD3.D3_QUANT   > 0"
						_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
						_oSQL:_sQuery +=   " AND SD3.D3_TIPO    NOT IN ('MO','AP','GF')"
						_oSQL:_sQuery +=   " AND SD3.D3_OP      = '" + _aOP [_nOP, 1] + "'"
						_oSQL:_sQuery += " GROUP BY D3_COD, D3_LOTECTL, D3_UM, B1_DESC"
						_oSQL:_sQuery += " ORDER BY D3_COD, D3_LOTECTL"
						// _oSQL:Log ()
						_aCons := aclone (_oSQL:Qry2Array (.F., .F.))
						for _nCons = 1 to len (_aCons)

							// Calcula a quantidade proporcional para ser passada na chamada recursiva.
							_nQtProp2 = (_nQtProp * _aCons [_nCons, 3]) / _aOP [_nOP, 2]
							
							_sID = soma1 (_sID)
							_sDescri = ''
							_sDescri += alltrim (_aCons [_nCons, 1]) + '-' + U_NoAcento (alltrim (left (_aCons [_nCons, 5], 40))) + _sQuebra
							if ! empty (_aCons [_nCons, 2])
								_sDescri += 'Lote ' + alltrim (_aCons [_nCons, 2]) + _sQuebra
							endif
							_sDescri += _FmtQt (_aCons [_nCons, 3], _aCons [_nCons, 4], _nQtProp2)
							_sRet += '<node BACKGROUND_COLOR="#ffffcc" CREATED="1493031071766" ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
					
							// Adiciona rastreabilidade do produto consumido.
							if ! empty (_aCons [_nCons, 2])
								if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
									_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
								else
									_sRet += U_RastLt (_sFilial, _aCons [_nCons, 1], _aCons [_nCons, 2], _nNivel - 1, _aHist, _nQtProp2)
								endif
							endif
					
							_sRet += '</node>'
						next

						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos entradas em OP temos Alias() = ' + alias ())


				// Busca entradas por transferencia entre lotes.
				if _nNivel <= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL AS LOTEORI,"
					_oSQL:_sQuery +=       " SUM (CONTRAPARTIDA.D3_QUANT) AS QUANT"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
					_oSQL:_sQuery +=  " INNER JOIN " + RetSQLName ("SD3") + " CONTRAPARTIDA "  // ORIGEM/DESTINO, QUANDO FOR TRANSFERENCIA
					_oSQL:_sQuery +=       " ON (CONTRAPARTIDA.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_FILIAL   = SD3.D3_FILIAL"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_NUMSEQ   = SD3.D3_NUMSEQ"
//					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_COD      = SD3.D3_COD"
//					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_LOTECTL != SD3.D3_LOTECTL"
					_oSQL:_sQuery +=       " AND NOT (CONTRAPARTIDA.D3_COD = SD3.D3_COD AND CONTRAPARTIDA.D3_LOTECTL = SD3.D3_LOTECTL)"  // transferencia de endereco
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_CF       = 'RE4'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.R_E_C_N_O_ != SD3.R_E_C_N_O_)"
					_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_FILIAL   = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=   " AND SD3.D3_OP       = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_CF       = 'DE4'"
					_oSQL:_sQuery +=   " AND SD3.D3_QUANT   > 0"
					_oSQL:_sQuery +=   " AND SD3.D3_COD      = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_LOTECTL  = '" + _sLote + "'"
					_oSQL:_sQuery += " 	GROUP BY CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL"
					_oSQL:_sQuery += " 	ORDER BY CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL"
					// _oSQL:Log ()
					_aEntTrLt = aclone (_oSQL:Qry2Array (.F., .F.))
					dbselectarea ("SD3")  // Por algum motivo estah chegando aqui sem nenhum 'alias'.
					for _nTrLt = 1 to len (_aEntTrLt)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Transferencia eh sempre de 1 para 1

						_sID = soma1 (_sID)
						if _aEntTrLt [_nTrLt, 1] == _sProduto
							_sDescri := 'Tr.do Lote ' + _aEntTrLt [_nTrLt, 2] + _sQuebra
						else
							_sDescri := 'Tr.do item ' + alltrim (_aEntTrLt [_nTrLt, 1]) + ' - ' + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + _aEntTrLt [_nTrLt, 1] , 'B1_DESC')) + _sQuebra
							_sDescri += 'Lote origem ' + _aEntTrLt [_nTrLt, 2] + _sQuebra
						endif
						_sDescri += _FmtQt (_aEntTrLt [_nTrLt, 3], sb1 -> b1_um, _nQtProp2)
						_sRet += '<node BACKGROUND_COLOR="#ffcccc" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
						
						// Chamada recursiva para buscar a 'origem do lote de origem'
						if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
							_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
						else
							_sRet += U_RastLt (_sFilial, _aEntTrLt [_nTrLt, 1], _aEntTrLt [_nTrLt, 2], _nNivel - 1, _aHist, _nQtProp2)
						endif
						
						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos entradas por transf.entre lotes temos Alias() = ' + alias ())


				// Busca outras entradas por movimentos internos.
				if _nNivel <= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT SD3.D3_DOC, SD3.D3_CF, SD3.D3_UM, SD3.D3_QUANT"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
					_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_FILIAL   = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=   " AND SD3.D3_OP       = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_TM       < '5'"
					_oSQL:_sQuery +=   " AND SD3.D3_CF      != 'DE4'"
					_oSQL:_sQuery +=   " AND SD3.D3_QUANT   > 0"
					_oSQL:_sQuery +=   " AND SD3.D3_COD      = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_LOTECTL  = '" + _sLote + "'"
					_oSQL:_sQuery += " 	ORDER BY D3_DOC"
					// _oSQL:Log ()
					_sAliasQ = _oSQL:Qry2Trb (.F.)
					do while ! (_sAliasQ) -> (eof ())

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Movimentacao por entrada normal eh sempre de 1 para 1

						_sID = soma1 (_sID)
						_sDescri = 'Mov.interno doc ' + (_sAliasQ) -> d3_doc + _sQuebra
						_sDescri += _FmtQt ((_sAliasQ) -> d3_quant, (_sAliasQ) -> d3_um, _nQtProp2)
						_sRet += '<node BACKGROUND_COLOR="#669900" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
						_sRet += '</node>'
						(_sAliasQ) -> (dbskip ())
					enddo	
					(_sAliasQ) -> (dbclosearea ())
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos entradas por mov.internos temos Alias() = ' + alias ())
		

				// Busca possiveis entradas via NF.
				if _nNivel <= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D1_DOC, D1_LOTEFOR, D1_QUANT, D1_UM,"
					_oSQL:_sQuery +=  " RTRIM (CASE WHEN D1_TIPO IN ('D', 'B') THEN A1_NOME ELSE A2_NOME END), "
					_oSQL:_sQuery +=  " D1_SERIE, D1_FORNECE, D1_LOJA, D1_ITEM"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1") + " SD1 "
					_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
					_oSQL:_sQuery +=        " ON (SA1.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=        " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
					_oSQL:_sQuery +=        " AND SA1.A1_COD     = SD1.D1_FORNECE"
					_oSQL:_sQuery +=        " AND SA1.A1_LOJA    = SD1.D1_LOJA)"
					_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
					_oSQL:_sQuery +=        " ON (SA2.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
					_oSQL:_sQuery +=        " AND SA2.A2_COD     = SD1.D1_FORNECE"
					_oSQL:_sQuery +=        " AND SA2.A2_LOJA    = SD1.D1_LOJA)"
					_oSQL:_sQuery +=      ", " + RetSQLName ("SF4") + " SF4 "
					_oSQL:_sQuery += " WHERE SF4.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
					_oSQL:_sQuery +=   " AND SF4.F4_CODIGO  = SD1.D1_TES"
					_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE = 'S'"
					_oSQL:_sQuery +=   " AND SD1.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SD1.D1_FILIAL  = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD1.D1_COD     = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD1.D1_LOTECTL = '" + _sLote + "'"
					_oSQL:_sQuery +=   " AND SD1.D1_QUANT   > 0"

					// Ignora retornos de remessa para industrializacao
					_oSQL:_sQuery +=   " AND NOT (SD1.D1_NFORI != '' AND SF4.F4_PODER3 IN ('R', 'D'))"

					// Ignora transferencias de filiais
					_oSQL:_sQuery +=   " AND SD1.D1_FORNECE NOT IN ('000021','001094','001369','003150','003402','003114','003209','003111','003108','003266','003195','004565','004734')"

				//	_oSQL:_sQuery += " GROUP BY D1_DOC, D1_LOTEFOR, D1_UM, CASE WHEN D1_TIPO IN ('D', 'B') THEN A1_NOME ELSE A2_NOME END, D1_SERIE, D1_FORNECE, D1_LOJA"
					// _oSQL:Log ()
					_aSD1 = aclone (_oSQL:Qry2Array (.F., .F.))
					for _nSD1 = 1 to len (_aSD1)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Movimentacao por NF eh sempre de 1 para 1

						_sID = soma1 (_sID)
						_sDescri := 'NF entr.' + alltrim (_aSD1 [_nSD1, 1]) + ' de ' + alltrim (_aSD1 [_nSD1, 5]) + _sQuebra
						_sDescri += 'Lote forn:' + alltrim (_aSD1 [_nSD1, 2]) + _sQuebra
						_sDescri += _FmtQt (_aSD1 [_nSD1, 3], _aSD1 [_nSD1, 4], _nQtProp2) + _sQuebra
						if ! empty (_sLote)
							_sLaudo = U_LaudoEm (_sProduto, _sLote, stod (_aSD1 [_nSD1, 5]))
							if ! empty (_sLaudo)
								_sDescri += 'Laudo labor:' + _sLaudo + _sQuebra
							endif
						endif
						
						// Se for contranota de entrada de safra, busca dados da carga.
						if sb1 -> b1_grupo == '0400' .and. _aSD1 [_nSD1, 6] == '30 '
							_oSQL := ClsSQL ():New ()
							_oSQL:_sQuery := "SELECT CARGA, DATA, CAD_VITIC, GRAU, NF_PRODUTOR, SAFRA"
							_oSQL:_sQuery +=  " FROM VA_VNOTAS_SAFRA"
							_oSQL:_sQuery += " WHERE FILIAL     = '" + _sFilial + "'"
							_oSQL:_sQuery +=   " AND DOC        = '" + _aSD1 [_nSD1, 1] + "'"
							_oSQL:_sQuery +=   " AND SERIE      = '" + _aSD1 [_nSD1, 6] + "'"
							_oSQL:_sQuery +=   " AND ASSOCIADO  = '" + _aSD1 [_nSD1, 7] + "'"
							_oSQL:_sQuery +=   " AND LOJA_ASSOC = '" + _aSD1 [_nSD1, 8] + "'"
							_oSQL:_sQuery +=   " AND ITEM_NOTA  = '" + _aSD1 [_nSD1, 9] + "'"
							_oSQL:_sQuery +=   " AND PRODUTO    = '" + _sProduto + "'"
							_oSQL:Log ()
							_aCarga = aclone (_oSQL:Qry2Array ())
							if len (_aCarga) == 1  // Nao deveria encontrar mais de um registro
						//		_sDescri += 'Carga safra: ' + _aCarga [1, 1] + ' de ' + dtoc (stod (_aCarga [1, 2])) + _sQuebra
								_sDescri += 'Carga: ' + _aCarga [1, 1] + '  Grau: ' + _aCarga [1, 4] + _sQuebra
								_sDescri += 'NF produtor: ' + _aCarga [1, 5] + _sQuebra

								// Alimenta array private da rotina chamadora com os dados de cargas de safra.
								// Especifico para relatorio de envio de mosto para a CENECOOP
								if type ('_aLtXLS58') == 'A'
									aadd (_aLtXLS58, {_sProduto, ;  // Codigo do produto
													  _sLote, ;  // Nosso lote interno
													  _aSD1 [_nSD1, 3], ;  // Quantidade
													   _aCarga [1, 1], ;  // Numero da carga ('numero da pesagem')
													   _aCarga [1, 2], ;  // Data da carga
													   _aCarga [1, 4], ;  // Grau da uva
													   _nQtProp, ;  // Quantidade proporcional a quantidade original vendida na NF
													   _sFilial, ;  // Filial onde foi recebida a carga
													   _aCarga [1, 6]})  // Safra referente a carga
									U_Log2 ('debug', '[' + procname () + ']_aLtXLS58 ficou assim:')
									U_Log2 ('debug', _aLtXLS58)
								endif
							endif
						endif
						
						_sRet += '<node BACKGROUND_COLOR="#ccffff" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos entradas por NF temos Alias() = ' + alias ())
		

				// Busca entradas por transferencias de filiais
				if _nNivel <= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D1_DOC, D2_LOTECTL, SUM (D1_QUANT), FILORIG"
					_oSQL:_sQuery +=  " FROM VA_VTRANSF_ENTRE_FILIAIS V"
					_oSQL:_sQuery += " WHERE FILDEST    = '" + _sFilial  + "'"
					_oSQL:_sQuery +=   " AND D1_COD     = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND D1_LOTECTL = '" + _sLote    + "'"
					_oSQL:_sQuery +=   " AND D1_QUANT   > 0"
					_oSQL:_sQuery += " GROUP BY D1_DOC, D2_LOTECTL, FILORIG"
					// _oSQL:Log ()
					_aSD1 = aclone (_oSQL:Qry2Array (.F., .F.))
					for _nSD1 = 1 to len (_aSD1)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Aqui nao ha conversao de quantidades como numa OP ou numa desmontagem.

						_sID = soma1 (_sID)
	
						// NF lancada com problemas e que deve ser ignorada.
						if alltrim (_aSD1 [_nSD1, 4]) == '07' .and. alltrim (_aSD1 [_nSD1, 1]) == '000016150' .and. alltrim (_aSD1 [_nSD1, 2]) == '00107501a'
							//u_log ('ignorando nota 000016150')
							_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
						else
							_sDescri := 'Transf. da filial ' + _aSD1 [_nSD1, 4] + ' - NF ' + alltrim (_aSD1 [_nSD1, 1]) + _sQuebra
							_sDescri += 'Lote orig:' + alltrim (_aSD1 [_nSD1, 2]) + _sQuebra
							_sDescri += _FmtQt (_aSD1 [_nSD1, 3], sb1 -> b1_um, _nQtProp2) + _sQuebra
							if ! empty (_sLote)
								_sLaudo = U_LaudoEm (_sProduto, _sLote, stod (_aSD1 [_nSD1, 4]))
								if ! empty (_sLaudo)
									_sDescri += 'Laudo labor:' + _sLaudo + _sQuebra
								endif
							endif
							_sRet += '<node BACKGROUND_COLOR="#009999" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
	
							// Chamada recursiva para buscar a rastreabilidade do lote na filial origem.
							if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
								_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
							else
								_sRet += U_RastLt (_aSD1 [_nSD1, 4], _sProduto, _aSD1 [_nSD1, 2], _nNivel - 1, _aHist, _nQtProp2)
							endif
							_sRet += '</node>'
						endif
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos entradas por tr.filiais temos Alias() = ' + alias ())


				// ------------------------------------------------------ Fim entradas
				// Fecha o nodo das entradas e abre o das saidas.
				if _nNivel == 0
					_sRet += '</node><node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" TEXT="SAIDAS">'
				endif


				// Busca saidas por consumo em OP
				if _nNivel >= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D3_OP, SUM (D3_QUANT + D3_PERDA), D3_UM, C2_PRODUTO, B1_DESC, SUM (C2_QUJE + C2_PERDA)"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3, "
					_oSQL:_sQuery +=             RetSQLName ("SC2") + " SC2, "
					_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
					_oSQL:_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = SD3.D3_FILIAL"
					_oSQL:_sQuery +=   " AND SC2.C2_NUM     = SUBSTRING (SD3.D3_OP, 1, 6)"
					_oSQL:_sQuery +=   " AND SC2.C2_ITEM    = SUBSTRING (SD3.D3_OP, 7, 2)"
					_oSQL:_sQuery +=   " AND SC2.C2_SEQUEN  = SUBSTRING (SD3.D3_OP, 9, 3)"
					_oSQL:_sQuery +=   " AND SC2.C2_ITEMGRD = SUBSTRING (SD3.D3_OP, 12, 2)"
					_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
					_oSQL:_sQuery +=   " AND SB1.B1_COD     = SC2.C2_PRODUTO"
					_oSQL:_sQuery +=   " AND SD3.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=   " AND SD3.D3_TM      >= '5'"
					_oSQL:_sQuery +=   " AND NOT (SD3.D3_FILIAL = '09' AND SD3.D3_OP = '00332501001')"  // OP que teria jogado vinho dentro do mosto e deve ser desconsiderada
					_oSQL:_sQuery +=   " AND SD3.D3_OP      != ''"
					_oSQL:_sQuery +=   " AND SD3.D3_CF      like 'RE%'"
					_oSQL:_sQuery +=   " AND SD3.D3_COD     = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_LOTECTL = '" + _sLote + "'"
					_oSQL:_sQuery += " GROUP BY D3_OP, D3_UM, C2_PRODUTO, B1_DESC"
					// _oSQL:Log ()
					_aReqOP := aclone (_oSQL:Qry2Array (.F., .F.))
					for _nReqOP = 1 to len (_aReqOP)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = (_nQtProp * _aReqOP [_nReqOP, 2]) / _aReqOP [_nReqOP, 6]

						_sID = soma1 (_sID)
						_sDescri := 'Consumo na OP ' + alltrim (_aReqOP [_nReqOP, 1]) + _sQuebra
						_sDescri += _FmtQt (_aReqOP [_nReqOP, 2], _aReqOP [_nReqOP, 3], _nQtProp2) + _sQuebra
						_sDescri += 'Prod.final: ' + alltrim (_aReqOP [_nReqOP, 4]) + '-' + alltrim (left (_aReqOP [_nReqOP, 5], 40))
						_sRet += '<node BACKGROUND_COLOR="#cccc00" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'
						if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
							_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
						else
							_sRet += U_RastLt (_sFilial, _aReqOP [_nReqOP, 4], left (_aReqOP [_nReqOP, 1], 8), _nNivel + 1, _aHist, _nQtProp2)
						endif
						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos saidas por consumo em OP temos Alias() = ' + alias ())


				// Busca saidas por NF (ignora filiais)
				if _nNivel >= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D2_DOC, D2_QUANT, D2_UM,"
					_oSQL:_sQuery +=  " CASE WHEN D2_TIPO IN ('D', 'B') THEN A2_NOME ELSE A1_NOME END,"
					_oSQL:_sQuery +=  " D2_CLIENTE"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD2") + " SD2 "
					_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
					_oSQL:_sQuery +=        " ON (SA1.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=        " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
					_oSQL:_sQuery +=        " AND SA1.A1_COD     = SD2.D2_CLIENTE"
					_oSQL:_sQuery +=        " AND SA1.A1_LOJA    = SD2.D2_LOJA)"
					_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
					_oSQL:_sQuery +=        " ON (SA2.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
					_oSQL:_sQuery +=        " AND SA2.A2_COD     = SD2.D2_CLIENTE"
					_oSQL:_sQuery +=        " AND SA2.A2_LOJA    = SD2.D2_LOJA)"
					_oSQL:_sQuery +=      ", " + RetSQLName ("SF4") + " SF4 "
					_oSQL:_sQuery += " WHERE SF4.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
					_oSQL:_sQuery +=   " AND SF4.F4_CODIGO  = SD2.D2_TES"
					_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE = 'S'"
					_oSQL:_sQuery +=   " AND SD2.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND SD2.D2_FILIAL  = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD2.D2_COD     = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD2.D2_LOTECTL = '" + _sLote + "'"
					_oSQL:_sQuery +=   " AND SD2.D2_QUANT   > 0"
					_oSQL:_sQuery +=   " AND SD2.D2_CLIENTE NOT IN ('002940','006164','007811','011863','012553','012717','012558','012675','012542','012528','012707','012855','015446','015165')"
					// _oSQL:Log ()
					_aSD2 = aclone (_oSQL:Qry2Array (.F., .F.))
					for _nSD2 = 1 to len (_aSD2)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Movimentacao por NF eh sempre de 1 para 1

						_sID = soma1 (_sID)
						_sDescri := 'NF saida ' + alltrim (_aSD2 [_nSD2, 1]) + ' p/ ' + _aSD2 [_nSD2, 5] + '-' + alltrim (left (_aSD2 [_nSD2, 4], 30)) + _sQuebra
						_sDescri += _FmtQt (_aSD2 [_nSD2, 2], _aSD2 [_nSD2, 3], _nQtProp2) + _sQuebra
						if ! empty (_sLote)
							_sLaudo = U_LaudoEm (_sProduto, _sLote, stod (_aSD2 [_nSD2, 5]))
							if ! empty (_sLaudo)
								_sDescri += 'Laudo labor:' + _sLaudo + _sQuebra
							endif
						endif
						_sRet += '<node BACKGROUND_COLOR="#ccffff" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'
						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos saidas por NF temos Alias() = ' + alias ())


				// Busca saidas por NF (transferencia para filiais)
				if _nNivel >= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT D2_DOC, SUM (D2_QUANT), FILDEST, D1_LOTECTL"
					_oSQL:_sQuery +=  " FROM VA_VTRANSF_ENTRE_FILIAIS V"
					_oSQL:_sQuery += " WHERE FILORIG    = '" + _sFilial  + "'"
					_oSQL:_sQuery +=   " AND D2_COD     = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND D2_LOTECTL = '" + _sLote    + "'"
					_oSQL:_sQuery +=   " AND D1_QUANT   > 0"
					_oSQL:_sQuery += " GROUP BY D2_DOC, FILDEST, D1_LOTECTL"
					// _oSQL:Log ()
					_aSD2 = aclone (_oSQL:Qry2Array (.F., .F.))
					for _nSD2 = 1 to len (_aSD2)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Transferencia eh sempre de 1 para 1

						_sID = soma1 (_sID)
						_sDescri := 'Transf. para filial ' + _aSD2 [_nSD2, 3] + ' - NF ' + alltrim (_aSD2 [_nSD2, 1]) + _sQuebra
						_sDescri += _FmtQt (_aSD2 [_nSD2, 2], sb1 -> b1_um, _nQtProp2) + _sQuebra
						_sDescri += 'Lote gerado na filial:' + alltrim (_aSD2 [_nSD2, 4]) + _sQuebra
						_sRet += '<node BACKGROUND_COLOR="#009999" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'

						// Chamada recursiva para buscar a rastreabilidade do lote na filial destino.
						if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
							_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
						else
							_sRet += U_RastLt (_aSD2 [_nSD2, 3], _sProduto, _aSD2 [_nSD2, 4], _nNivel + 1, _aHist, _nQtProp2)
						endif

						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos saidas por tr.filiais temos Alias() = ' + alias ())


				// Busca saidas por transferencia entre lotes.
				if _nNivel >= 0 .and. sb1 -> b1_rastro == 'L'
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := "SELECT CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL AS LOTEORI,"
					_oSQL:_sQuery +=       " SUM (SD3.D3_QUANT) AS QUANT"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
					_oSQL:_sQuery +=  " INNER JOIN " + RetSQLName ("SD3") + " CONTRAPARTIDA "  // ORIGEM/DESTINO, QUANDO FOR TRANSFERENCIA
					_oSQL:_sQuery +=       " ON (CONTRAPARTIDA.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_FILIAL   = SD3.D3_FILIAL"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_NUMSEQ   = SD3.D3_NUMSEQ"
//					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_COD      = SD3.D3_COD"
//					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_LOTECTL != SD3.D3_LOTECTL"
					_oSQL:_sQuery +=       " AND NOT (CONTRAPARTIDA.D3_COD = SD3.D3_COD AND CONTRAPARTIDA.D3_LOTECTL = SD3.D3_LOTECTL)"  // transferencia de endereco
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.D3_CF       = 'DE4'"
					_oSQL:_sQuery +=       " AND CONTRAPARTIDA.R_E_C_N_O_ != SD3.R_E_C_N_O_)"
					_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_FILIAL   = '" + _sFilial + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
					_oSQL:_sQuery +=   " AND SD3.D3_OP       = ''"
					_oSQL:_sQuery +=   " AND SD3.D3_CF       = 'RE4'"
					_oSQL:_sQuery +=   " AND SD3.D3_QUANT   > 0"
					_oSQL:_sQuery +=   " AND SD3.D3_COD      = '" + _sProduto + "'"
					_oSQL:_sQuery +=   " AND SD3.D3_LOTECTL  = '" + _sLote + "'"
					_oSQL:_sQuery += " 	GROUP BY CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL"
					_oSQL:_sQuery += " 	ORDER BY CONTRAPARTIDA.D3_COD, CONTRAPARTIDA.D3_LOTECTL"
					// _oSQL:Log ()
					_aSaiTrLt = aclone (_oSQL:Qry2Array (.F., .F.))
					for _nTrLt = 1 to len (_aSaiTrLt)

						// Calcula a quantidade proporcional para ser passada na chamada recursiva.
						_nQtProp2 = _nQtProp  // Transferencia eh sempre de 1 para 1

						_sID = soma1 (_sID)
//						_sDescri := 'Tr.para o lote ' + _aSaiTrLt [_nTrLt, 2] + _sQuebra
						if _aSaiTrLt [_nTrLt, 1] == _sProduto
							_sDescri := 'Tr.para o Lote ' + _aSaiTrLt [_nTrLt, 2] + _sQuebra
						else
							_sDescri := 'Tr.para o item ' + alltrim (_aSaiTrLt [_nTrLt, 1]) + ' - ' + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + _aSaiTrLt [_nTrLt, 1] , 'B1_DESC')) + _sQuebra
							_sDescri += 'Lote destino ' + _aSaiTrLt [_nTrLt, 2] + _sQuebra
						endif
						_sDescri += _FmtQt (_aSaiTrLt [_nTrLt, 3], sb1 -> b1_um, _nQtProp2)
						_sRet += '<node BACKGROUND_COLOR="#ffcccc" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
						
						// Chamada recursiva para buscar a 'origem do lote de origem'
						if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
							_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
						else
							_sRet += U_RastLt (_sFilial, _aSaiTrLt [_nTrLt, 1], _aSaiTrLt [_nTrLt, 2], _nNivel + 1, _aHist, _nQtProp2)
						endif
						
						_sRet += '</node>'
					next
				endif
				// U_Log2 ('debug', '[' + procname () + ']Apos saidas por tr.internas temos Alias() = ' + alias ())


				// Chamada inicial: preciso finalizar o arquivo de saida.
				if _nNivel == 0
					_sRet += '</node>'
					_sRet += '</node>'
					_sRet += '</map>'
					
					// Gera quebras de linha no final dos nodos, para interpretacao no NAWeb.
					_sRet = strtran (_sRet, '>', '>' + chr (13) + chr (10))
				endif
			endif
		endif
	endif

/*
	// Usado para gerar tabela de rastreamento de cargas de safra 2018.
	if _nNivel == 0 .and. type ('_aTodasCar') == 'A'
		u_log ('_aHist:', _aHist)
		if ascan (_aTodasCar,,, {|_x| _x [1] == _sCargaUva .and. _x [2] == substr (_aHist [_nHist], 1, 2) .and. _x [3] == substr (_aHist [_nHist], 3, 15) .and. _x [4] == substr (_aHist [_nHist], 18, 10)}) == 0
			for _nHist = 1 to len (_aHist)
				aadd (_aTodasCar, {_sCargaUva, substr (_aHist [_nHist], 1, 2), substr (_aHist [_nHist], 3, 15), substr (_aHist [_nHist], 18, 10), '', 0})
			next
		endif
	endif
*/

	U_Log2 ('info', 'Finalizando ' + _sFilial + _sProduto + _sLote + ' nivel ' + cvaltochar (_nNivel))
return _sRet



// --------------------------------------------------------------------------
// Formata quantidades
static function _FmtQt (_nValor, _sUM, _nQtProp)
//return 'Qt: ' + alltrim (transform (_nValor, '@E 999,999,999,999.99')) + ' ' + _sUM
return 'Qt: ' + alltrim (transform (_nValor, '@E 999,999,999,999.99')) + ' ' + _sUM + iif (empty (_nQtProp), '', ' (qt.proporcional: ' + alltrim (transform (_nQtProp, '@E 999,999,999,999.9999')) + ')')
