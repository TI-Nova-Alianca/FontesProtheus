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
// 29/03/2022 - Robert - Adicionado dbselectarea("SB1") no final (parece que muitas chamadas recursivas deixam sem ALIAS).
// 29/04/2022 - Robert - Transf. lote p/outro proporcionalizava de 1 para 1, quando o correto eh usar a quantidade absoluta transferida - GLPI 11980
//                     - Nao salvava area de trabalho entre as chamadas e, com isso, retornava com o SB1 desposicionado.
//                     - Melhorado log, para identificacao de niveis.
// 24/05/2022 - Robert - Leitura de todas as entradas passa a buscar na function VA_FKARDEX_LOTE (GLPI 11980)
// 27/05/2022 - Robert - Leitura de todas as movimentacoes passa a buscar na function VA_FKARDEX_LOTE (GLPI 11980)
// 27/09/2023 - Robert - Voltado contorno para ler lote=OP quando item PA nao coltrola lotes pelo Protheus (GLPI 14299)
//

// --------------------------------------------------------------------------
user function RastLT (_sFilial, _sProduto, _sLote, _nNivel, _aHist, _nQtProp, _sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _sDescri   := ""
	local _sAliasQ   := ""
	local _sRet      := ""
	local _aOP       := {}
	local _nOP       := 0
	local _aReqOP    := {}
	local _nReqOP    := 0
	local _aCons     := {}
	local _nCons     := 0
	local _aEntTrLt  := {}
	local _aSaiTrLt  := {}
	local _nTrLt     := 0
	local _aSD1      := {}
	local _nSD1      := 0
	local _aSD2      := {}
	local _nSD2      := 0
	// nao estah buscando laudo (falta passar a data) ---> local _sLaudo    := ''
	local _nNivFold  := 15 //10  // A partir deste nivel gera os nodos 'compactados' para nao ficar grande demais na visualizacao inicial.
	local _sQuebra   := "&#xa;"  // Representacao de uma quebra de linha na visualizacao do FreeMind
	local _aCarga    := ""
	local _nMaxStr   := 400000 //200000  // Limite para o tamanho da string de retorno (pelo que sei, o maximo eh 64K)
	local _nLimNivel := 20 //15  // Limite maximo de niveis de pesquisa
	local _sStrLog   := ''
	local _lContinua := .T.
	local _sKardex   := ''
	static _sID      := '0000'  // Criado como STATIC para gerar sempre IDs unicos, mesmo com chamadas recursivas.

	// Prepara substring para manter padrao em todos os logs
	_sStrLog := space (min (8, abs (_nNivel)))  // Se deixar muito espaco para todos os niveis, acabo usando a linha toda
	_sStrLog += iif (_nNivel > 0, '+' + cvaltochar (abs (_nNivel)), iif (_nNivel < 0, '-' + cvaltochar (abs (_nNivel)), '0'))
	_sStrLog  = U_TamFixo (_sStrLog, 11, ' ')
	_sStrLog += ' F' + _sFilial
	_sStrLog += ' Cod:' + _sProduto
	_sStrLog += ' Lt:' + _sLote + ' '
	U_Log2 ('info', _sStrLog)
	
	// Variavel para acumular o historico de lotes pelos quais jah passei, para detectar recursividade.
	_aHist := iif (_aHist == NIL, {}, _aHist)

	if _nNivel == 0
		procregua (1000)
	else
		incproc ('Item ' + alltrim (_sProduto) + ' lote ' + alltrim (_sLote) + ' nivel ' + cvaltochar (_nNivel))
	endif

	// Limita a 'profundidade' de pesquisa.
	if abs (_nNivel) > _nLimNivel
		U_Log2 ('aviso', _sStrLog + "Limite de 'profundidade de pesquisa' atingido.")
		_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) nivel maximo atingido"></node>'
		_lContinua = .F.
	endif

	// Encontramos muitos casos onde um lote A foi transferido para o lote B, que novamente foi transferido para o lote A
	if _lContinua .and. ascan (_aHist, _sFilial + _sProduto + _sLote)
		U_Log2 ('aviso', _sStrLog + 'Detectada recursividade na movimentacao')
		_sDescri := "Recurs." + _sQuebra //Detectada recursividade na movimentacao" + _sQuebra
		_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="' + _sDescri + '"></node>'
		_lContinua = .F.
	endif

	// Acrescenta chave <filial + produto + lote> na array de historico, para detectar possivel recursividade de movimentacao.
	if _lContinua
		aadd (_aHist, _sFilial + _sProduto + _sLote)
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Produto '" + _sProduto + "' nao encontrado na tabela SB1",, .t.)
			_lContinua = .F.
		endif
	endif
	
	// Chamada inicial: preciso criar o arquivo de saida com o 'nodo' central.
	if _lContinua .and. _nNivel == 0
		_sID = soma1 (_sID)
		_sDescri := ""
		_sDescri += alltrim (_sProduto) + '-' + U_NoAcento (alltrim (sb1 -> b1_desc)) + _sQuebra
		_sDescri += 'Filial ' + _sFilial + ' - Lote ' + _sLote + _sQuebra
		_sDescri += 'Qt. base: ' + alltrim (transform (_nQtProp, '@E 999,999,999,999.99')) + ' ' + sb1 -> b1_um
		_sRet := ""
		_sRet += '<map version="1.0.1">'
		_sRet += '<node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" TEXT="' + _sDescri + '">'
	endif


	// Monta array com todos os movimentos do item/lote no nivel atual, a serem
	// lidos posteriormente para gerar os nodos e, havendo necessidade, poderao
	// ser expandidos recursivamente.
	// Preciso desta leitura no inicio para saber, por exemplo, o total de
	// quantidade recebida por um lote via transferencia de outro, e poder usar
	// esse total no momento de calcular proporcionalidade para outros niveis.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT TABELA_ORIGEM as TBL_ORIG, DATA AS DTMOVTO, OP, QT_ENTRADA, QT_SAIDA, CFOP"
		_oSQL:_sQuery +=      ", PRODUTO_ORIGEM as PROD_ORIG, LOTE_ORIGEM as LOTE_ORIG"
		_oSQL:_sQuery +=      ", PRODUTO_DESTINO as PROD_DEST, LOTE_DESTINO as LOTE_DEST"
		_oSQL:_sQuery +=      ", DOC, TES, LOTE_FORNECEDOR as LOTEFOR"
		_oSQL:_sQuery +=      ", LOTE_FILIAL_ORIGEM as LTFILORI, LOTE_FILIAL_DESTINO as LTFILDEST"
		_oSQL:_sQuery +=      ", SERIENF, CLIFOR, LOJA, TIPONF, ITEMNF, FILIAL_ORIGEM as FILORIG"
		_oSQL:_sQuery +=      ", FILIAL_DESTINO as FILDEST"
		_oSQL:_sQuery +=  " FROM VA_FKARDEX_LOTE ('" + _sFilial + "'"
		_oSQL:_sQuery +=                        ",'" + _sProduto + "'"
		_oSQL:_sQuery +=                        ",'" + _sLote + "'"
		_oSQL:_sQuery +=                        ",''"  // Data inicial
		_oSQL:_sQuery +=                        ",'z')"  // Data final
		//_oSQL:Log (_sStrLog)
		
		// Gera um arquivo temporario que vai ser gravado na tabela TEMPDB do
		// SQLServer, de modo que eu possa fazer queries nessa tabela.
		_oSQL:Copy2Trb (.f., 4, '_kdx', {'OP'})
		_kdx -> (dbclosearea ())
		_sKardex = _oSQL:GetRealName ()
	endif


	if _lContinua .and. _nNivel == 0
		// Abre o nodo das entradas
		_sID = soma1 (_sID)
		_sRet += '<node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" POSITION="left" TEXT="ENTRADAS">'
	endif
	
	// Busca entradas por OP (apontamentos de producao)
	_aOP = {}
	if _lContinua .and. _nNivel <= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'EA'  // [E]ntradas ou [A]mbas
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT OP, SUM (QT_ENTRADA), '" + sb1 -> b1_um + "', MAX (DTMOVTO)"
		_oSQL:_sQuery +=  " FROM " + _sKardex + ' K'
		_oSQL:_sQuery += " WHERE K.OP != ''"
		_oSQL:_sQuery +=   " AND K.TBL_ORIG = 'SD3'"
		_oSQL:_sQuery +=   " AND K.QT_ENTRADA > 0"
		if _sFilial == '09'  // OP que teria jogado vinho dentro do mosto e deve ser desconsiderada
			_oSQL:_sQuery +=   " AND K.OP != '00332501001'"
		endif
		_oSQL:_sQuery += " GROUP BY K.OP"
		_oSQL:_sQuery += " ORDER BY K.OP"
		//_oSQL:Log (_sStrLog)
		_aOP := aclone (_oSQL:Qry2Array (.F., .F.))


		// INICIO BACA   INICIO BACA   INICIO BACA   INICIO BACA   INICIO BACA
		// Se o item controla rastreabilidade pelo Protheus, jah tenho as OPs que
		// produziram o lote, atraves do kardex do lote. Entretanto, ainda temos a
		// maioria dos PAs que nao usam lote no Protheus, entao terei que assumir
		// o numero da OP como sendo o lote. Quando a rastreabilidade for completa
		// no Protheus, isso vai ser desnecessario.
		if len (_aOP) == 0 .and. sb1 -> b1_rastro == 'N' .and. sb1 -> b1_tipo == 'PA'
			U_Log2 ('aviso', '[' + procname () + ']Produto eh PA e nao controla rastro pelo Protheus. Vou tentar buscar por lote=OP')
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
			_oSQL:_sQuery +=   " AND SD3.D3_OP      like '" + alltrim (_sLote) + "%'"
			_oSQL:_sQuery += " GROUP BY D3_OP, D3_UM"
			_oSQL:_sQuery += " ORDER BY D3_OP"
			_oSQL:Log (_sStrLog)
			_aOP := aclone (_oSQL:Qry2Array (.F., .F.))
			U_Log2 ('debug', _aOP)
		endif
		// FIM BACA   FIM BACA   FIM BACA   FIM BACA   FIM BACA   FIM BACA   FIM BACA


		for _nOP = 1 to len (_aOP)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _nQtProp  // Aqui trata-se da quantidade final produzida pela OP (de 1 para 1)

			_sID = soma1 (_sID)
			_sDescri := 'O.P. ' + alltrim (_aOP [_nOP, 1]) + _sQuebra
			_sDescri += dtoc (stod (_aOP [_nOP, 4])) + _sQuebra
			// _sDescri += _FmtQt (_aOP [_nOP, 2], _aOP [_nOP, 3], _nQtProp2) + _sQuebra
			_sDescri += _FmtQt (_aOP [_nOP, 2], _aOP [_nOP, 3], _nQtProp2)
			_sRet += '<node BACKGROUND_COLOR="#cccc00" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
		
			// Busca requisicoes desta OP.
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
						_sRet += U_RastLt (_sFilial, _aCons [_nCons, 1], _aCons [_nCons, 2], _nNivel - 1, _aHist, _nQtProp2, _sQueFazer)
					endif
				endif
		
				_sRet += '</node>'
			next

			_sRet += '</node>'
		next
	endif


	// Busca entradas por transferencia entre lotes.
	_aEntTrLt = {}
	if _lContinua .and. _nNivel <= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'EA'  // [E]ntradas ou [A]mbas
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT PROD_ORIG, LOTE_ORIG, SUM (QT_ENTRADA), SB1.B1_DESC"
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery +=      ", " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " WHERE K.OP            = ''"
		_oSQL:_sQuery +=   " AND K.TBL_ORIG      = 'SD3'"
		_oSQL:_sQuery +=   " AND K.CFOP          = 'DE4'"
		
		// Se for o mesmo produto e lote, trata-se apenas de trasf. de endereco.
		_oSQL:_sQuery +=   " AND NOT (K.PROD_ORIG = '" + _sProduto + "' AND K.LOTE_ORIG = '" + _sLote + "')"
		
		_oSQL:_sQuery +=   " AND K.QT_ENTRADA   > 0"
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD      = K.PROD_ORIG"
		_oSQL:_sQuery += " GROUP BY PROD_ORIG, LOTE_ORIG, SB1.B1_DESC"
		_oSQL:_sQuery += " ORDER BY PROD_ORIG, LOTE_ORIG"
		//_oSQL:Log (_sStrLog)
		_aEntTrLt := aclone (_oSQL:Qry2Array (.F., .F.))

		for _nTrLt = 1 to len (_aEntTrLt)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _aEntTrLt [_nTrLt, 3]  // Transferencia eh sempre a propria quantidade transferida.

			_sID = soma1 (_sID)
			if _aEntTrLt [_nTrLt, 1] == _sProduto
				_sDescri := 'Tr.do Lote ' + _aEntTrLt [_nTrLt, 2] + _sQuebra
			else
				_sDescri := 'Tr.do item ' + alltrim (_aEntTrLt [_nTrLt, 1]) + ' - ' + alltrim (_aEntTrLt [_nTrLt, 4]) + _sQuebra
				_sDescri += 'Lote origem ' + _aEntTrLt [_nTrLt, 2] + _sQuebra
			endif
			_sDescri += _FmtQt (_aEntTrLt [_nTrLt, 3], sb1 -> b1_um, _nQtProp2)
			_sRet += '<node BACKGROUND_COLOR="#ffcccc" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
			
			// Chamada recursiva para buscar a 'origem do lote de origem'
			if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
				_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
			else
				_sRet += U_RastLt (_sFilial, _aEntTrLt [_nTrLt, 1], _aEntTrLt [_nTrLt, 2], _nNivel - 1, _aHist, _nQtProp2, _sQueFazer)
			endif
			
			_sRet += '</node>'
		next
	endif


	// Busca outras entradas por movimentos internos.
	if _lContinua .and. _nNivel <= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'EA'  // [E]ntradas ou [A]mbas
		_oSQL:_sQuery := "SELECT DOC, '" + sb1 -> b1_um + "' AS UM, QT_ENTRADA AS QUANT"
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery += " WHERE K.OP     = ''"
		_oSQL:_sQuery +=   " AND K.TBL_ORIG = 'SD3'"
		_oSQL:_sQuery +=   " AND K.CFOP  != 'DE4'"
		_oSQL:_sQuery +=   " AND K.TES < '5'"
		_oSQL:_sQuery += " ORDER BY DOC"
		//_oSQL:Log (_sStrLog)
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		do while ! (_sAliasQ) -> (eof ())

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _nQtProp  // Movimentacao por entrada normal eh sempre de 1 para 1

			_sID = soma1 (_sID)
			_sDescri = 'Mov.interno doc ' + (_sAliasQ) -> doc + _sQuebra
			_sDescri += _FmtQt ((_sAliasQ) -> quant, (_sAliasQ) -> um, _nQtProp2)
			_sRet += '<node BACKGROUND_COLOR="#669900" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
			_sRet += '</node>'
			(_sAliasQ) -> (dbskip ())
		enddo	
		(_sAliasQ) -> (dbclosearea ())
	endif


	// Busca entradas via NF.
	if _lContinua .and. _nNivel <= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'EA'  // [E]ntradas ou [A]mbas
		_oSQL:_sQuery := "SELECT K.DOC"         // 1
		_oSQL:_sQuery +=      ", K.LOTEFOR"     // 2
		_oSQL:_sQuery +=      ", K.QT_ENTRADA"  // 3
		_oSQL:_sQuery +=      ", '" + sb1 -> b1_um + "' AS UM "  // 4
		_oSQL:_sQuery +=      ", RTRIM (CASE WHEN K.TIPONF IN ('D', 'B') THEN A1_NOME ELSE A2_NOME END) "  // 5
		_oSQL:_sQuery +=      ", K.SERIENF"     // 6
		_oSQL:_sQuery +=      ", K.CLIFOR"      // 7
		_oSQL:_sQuery +=      ", K.LOJA"        // 8
		_oSQL:_sQuery +=      ", K.ITEMNF"      // 9
		_oSQL:_sQuery +=      ", K.FILORIG"     // 10
		_oSQL:_sQuery +=      ", K.LTFILORI"    // 11
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=        " ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=        " AND SA1.A1_COD     = K.CLIFOR"
		_oSQL:_sQuery +=        " AND SA1.A1_LOJA    = K.LOJA)"
		_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=        " ON (SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=        " AND SA2.A2_COD     = K.CLIFOR"
		_oSQL:_sQuery +=        " AND SA2.A2_LOJA    = K.LOJA)"
		_oSQL:_sQuery += " WHERE K.TBL_ORIG = 'SD1'"
		_oSQL:_sQuery +=   " AND K.QT_ENTRADA > 0"
		if _sFilial == '07'  // NF lancada com problemas e que deve ser ignorada.
			_oSQL:_sQuery +=   " AND NOT (K.DOC = '000016150' AND K.LOTEFOR = '00107501a')"
		endif
		_oSQL:_sQuery += " ORDER BY K.CLIFOR, K.DOC"
		//_oSQL:Log (_sStrLog)
		_aSD1 = aclone (_oSQL:Qry2Array (.F., .F.))

		for _nSD1 = 1 to len (_aSD1)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _nQtProp  // Movimentacao por NF eh sempre de 1 para 1

			_sID = soma1 (_sID)
			if ! empty (_aSD1 [_nSD1, 10])  // Filial origem
				_sDescri := 'Transf. da filial ' + _aSD1 [_nSD1, 10] + ' - NF ' + alltrim (_aSD1 [_nSD1, 1]) + _sQuebra
				_sDescri += 'Lote orig.(na filial ' + _aSD1 [_nSD1, 10] + '):' + alltrim (_aSD1 [_nSD1, 11]) + _sQuebra
			else
				_sDescri := 'NF entr.' + alltrim (_aSD1 [_nSD1, 1]) + ' de ' + alltrim (_aSD1 [_nSD1, 5]) + _sQuebra
				_sDescri += 'Lote forn:' + alltrim (_aSD1 [_nSD1, 2]) + _sQuebra
			endif
			// _sDescri += _FmtQt (_aSD1 [_nSD1, 3], _aSD1 [_nSD1, 4], _nQtProp2) + _sQuebra
			_sDescri += _FmtQt (_aSD1 [_nSD1, 3], _aSD1 [_nSD1, 4], _nQtProp2)
			// nao estah buscando laudo (falta passar a data) ---> if ! empty (_sLote)
			// nao estah buscando laudo (falta passar a data) ---> 	_sLaudo = U_LaudoEm (_sProduto, _sLote, stod (_aSD1 [_nSD1, 5]))
			// nao estah buscando laudo (falta passar a data) ---> 	if ! empty (_sLaudo)
			// nao estah buscando laudo (falta passar a data) ---> 		_sDescri += 'Laudo labor:' + _sLaudo + _sQuebra
			// nao estah buscando laudo (falta passar a data) ---> 	endif
			// nao estah buscando laudo (falta passar a data) ---> endif
			
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
				//_oSQL:Log (_sStrLog)
				_aCarga = aclone (_oSQL:Qry2Array ())
				if len (_aCarga) == 1  // Nao deveria encontrar mais de um registro
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
					endif
				endif
			endif
			
			if ! empty (_aSD1 [_nSD1, 10])  // Filial origem
				_sRet += '<node BACKGROUND_COLOR="#009999" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'

				// Chamada recursiva para buscar a rastreabilidade do lote na filial origem.
				if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
					_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
				else
					_sRet += U_RastLt (_aSD1 [_nSD1, 10], _sProduto, _aSD1 [_nSD1, 11], _nNivel - 1, _aHist, _nQtProp2, _sQueFazer)
				endif
			else
				_sRet += '<node BACKGROUND_COLOR="#ccffff" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
			endif
			_sRet += '</node>'
		next
	endif


	// ----------------------------------------------------------
	// ----------------------------------------------------------
	// ----------------------------------------------------------
	// Fim da leitura das entradas
	// ----------------------------------------------------------
	// ----------------------------------------------------------
	// ----------------------------------------------------------


	// Fecha o nodo das entradas e abre o das saidas.
	if _lContinua .and. _nNivel == 0
		_sRet += '</node><node CREATED="1493030990433" ID="' + _sID + '" STYLE="bubble" TEXT="SAIDAS">'
	endif


	// Busca saidas por consumo em OP ou OS
	_aReqOP = {}
	if _lContinua .and. _nNivel >= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'SA'  // [S]aidas ou [A]mbas
		_oSQL:_sQuery := "SELECT K.OP"         // 1
		_oSQL:_sQuery +=      ", SUM (K.QT_SAIDA)"     // 2
		_oSQL:_sQuery +=      ", '" + sb1 -> b1_um + "' AS UM "  // 3
		_oSQL:_sQuery +=      ", SC2.C2_PRODUTO "  // 4
		_oSQL:_sQuery +=      ", SB1_FINAL.B1_DESC"     // 5
		_oSQL:_sQuery +=      ", SUM (SC2.C2_QUJE + SC2.C2_PERDA)"      // 6
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery +=      ", " + RetSQLName ("SC2") + " SC2 "
		_oSQL:_sQuery +=      ", " + RetSQLName ("SB1") + " SB1_FINAL "
		_oSQL:_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = '" + xfilial ("SC2") + "'"
		_oSQL:_sQuery +=   " AND SC2.C2_NUM     = SUBSTRING (K.OP, 1, 6)"
		_oSQL:_sQuery +=   " AND SC2.C2_ITEM    = SUBSTRING (K.OP, 7, 2)"
		_oSQL:_sQuery +=   " AND SC2.C2_SEQUEN  = SUBSTRING (K.OP, 9, 3)"
		_oSQL:_sQuery +=   " AND SC2.C2_ITEMGRD = SUBSTRING (K.OP, 12, 2)"
		_oSQL:_sQuery +=   " AND SB1_FINAL.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1_FINAL.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=   " AND SB1_FINAL.B1_COD     = SC2.C2_PRODUTO"
		if cFilAnt == '09'
			_oSQL:_sQuery +=   " AND K.OP != '00332501001'"  // OP que teria jogado vinho dentro do mosto e deve ser desconsiderada
		endif
		_oSQL:_sQuery +=   " AND K.TBL_ORIG = 'SD3'"
		_oSQL:_sQuery +=   " AND K.QT_SAIDA > 0"
		_oSQL:_sQuery +=   " AND K.OP != ''"
		_oSQL:_sQuery +=   " AND K.CFOP LIKE 'RE%'"
		_oSQL:_sQuery += " GROUP BY K.OP, SC2.C2_PRODUTO, SB1_FINAL.B1_DESC"
		_oSQL:_sQuery += " ORDER BY K.OP"
		//_oSQL:Log (_sStrLog)
		_aReqOP = aclone (_oSQL:Qry2Array (.F., .F.))

		for _nReqOP = 1 to len (_aReqOP)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = (_nQtProp * _aReqOP [_nReqOP, 2]) / _aReqOP [_nReqOP, 6]

			_sID = soma1 (_sID)
			_sDescri := 'Consumo na OP ' + alltrim (_aReqOP [_nReqOP, 1]) + _sQuebra
			// _sDescri += _FmtQt (_aReqOP [_nReqOP, 2], _aReqOP [_nReqOP, 3], _nQtProp2) + _sQuebra
			_sDescri += _FmtQt (_aReqOP [_nReqOP, 2], _aReqOP [_nReqOP, 3], _nQtProp2)
			_sDescri += 'Prod.final: ' + alltrim (_aReqOP [_nReqOP, 4]) + '-' + alltrim (left (_aReqOP [_nReqOP, 5], 40)) + _sQuebra
			_sDescri += 'Podia incluir aqui o lote gerado pela OP...'
			_sRet += '<node BACKGROUND_COLOR="#cccc00" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'
			if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
				_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
			else
				_sRet += U_RastLt (_sFilial, _aReqOP [_nReqOP, 4], left (_aReqOP [_nReqOP, 1], 8), _nNivel + 1, _aHist, _nQtProp2, _sQueFazer)
			endif
			_sRet += '</node>'
		next
	endif


	// Busca saidas por NF
	_aSD2 := {}
	if _lContinua .and. _nNivel >= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'SA'  // [S]aidas ou [A]mbas
		_oSQL:_sQuery := "SELECT K.DOC"         // 1
		_oSQL:_sQuery +=      ", K.QT_SAIDA"     // 2
		_oSQL:_sQuery +=      ", '" + sb1 -> b1_um + "' AS UM "  // 3
		_oSQL:_sQuery +=      ", RTRIM (CASE WHEN K.TIPONF IN ('D', 'B') THEN A2_NOME ELSE A1_NOME END) "  // 4
		_oSQL:_sQuery +=      ", K.CLIFOR"     // 5
		_oSQL:_sQuery +=      ", K.FILDEST"     // 6
		_oSQL:_sQuery +=      ", K.LTFILDEST"     // 7
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=        " ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=        " AND SA1.A1_COD     = K.CLIFOR"
		_oSQL:_sQuery +=        " AND SA1.A1_LOJA    = K.LOJA)"
		_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=        " ON (SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=        " AND SA2.A2_COD     = K.CLIFOR"
		_oSQL:_sQuery +=        " AND SA2.A2_LOJA    = K.LOJA)"
		_oSQL:_sQuery += " WHERE K.TBL_ORIG = 'SD2'"
		_oSQL:_sQuery +=   " AND K.QT_SAIDA > 0"
		_oSQL:_sQuery += " ORDER BY K.DOC"
		//_oSQL:Log (_sStrLog)
		_aSD2 = aclone (_oSQL:Qry2Array (.F., .F.))

		for _nSD2 = 1 to len (_aSD2)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _nQtProp  // Movimentacao por NF eh sempre de 1 para 1

			_sID = soma1 (_sID)
			if ! empty (_aSD2 [_nSD2, 6])  // Filial destino
				_sDescri := 'Transf. para filial ' + _aSD2 [_nSD2, 6] + ' - NF ' + alltrim (_aSD2 [_nSD2, 1]) + _sQuebra
				// _sDescri += _FmtQt (_aSD2 [_nSD2, 2], sb1 -> b1_um, _nQtProp2) + _sQuebra
				_sDescri += _FmtQt (_aSD2 [_nSD2, 2], sb1 -> b1_um, _nQtProp2)
				_sDescri += 'Lote gerado na filial:' + alltrim (_aSD2 [_nSD2, 7]) + _sQuebra
				_sRet += '<node BACKGROUND_COLOR="#009999" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'

				// Chamada recursiva para buscar a rastreabilidade do lote na filial destino.
				if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
					_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
				else
					_sRet += U_RastLt (_aSD2 [_nSD2, 6], _sProduto, _aSD2 [_nSD2, 7], _nNivel + 1, _aHist, _nQtProp2, _sQueFazer)
				endif
			else
				_sDescri := 'NF saida ' + alltrim (_aSD2 [_nSD2, 1]) + ' p/ ' + _aSD2 [_nSD2, 5] + '-' + alltrim (left (_aSD2 [_nSD2, 4], 30)) + _sQuebra
				// _sDescri += _FmtQt (_aSD2 [_nSD2, 2], _aSD2 [_nSD2, 3], _nQtProp2) + _sQuebra
				_sDescri += _FmtQt (_aSD2 [_nSD2, 2], _aSD2 [_nSD2, 3], _nQtProp2)
				_sRet += '<node BACKGROUND_COLOR="#ccffff" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="right" TEXT="' + _sDescri + '">'
			endif
			// nao estah buscando laudo (falta passar a data) ---> if ! empty (_sLote)
			// nao estah buscando laudo (falta passar a data) ---> 	_sLaudo = U_LaudoEm (_sProduto, _sLote, stod (_aSD2 [_nSD2, 5]))
			// nao estah buscando laudo (falta passar a data) ---> 	if ! empty (_sLaudo)
			// nao estah buscando laudo (falta passar a data) ---> 		_sDescri += 'Laudo labor:' + _sLaudo + _sQuebra
			// nao estah buscando laudo (falta passar a data) ---> 	endif
			// nao estah buscando laudo (falta passar a data) ---> endif
			_sRet += '</node>'
		next
	endif


	// Busca saidas por transferencia para outros lotes.
	_aSaiTrLt = {}
	if _lContinua .and. _nNivel >= 0 .and. ! empty (_sKardex) .and. _sQueFazer $ 'SA'  // [S]aidas ou [A]mbas
		_oSQL:_sQuery := "SELECT K.PROD_DEST"         // 1
		_oSQL:_sQuery +=      ", K.LOTE_DEST"     // 2
		_oSQL:_sQuery +=      ", SUM (K.QT_SAIDA)"     // 3
		_oSQL:_sQuery +=      ", RTRIM (SB1.B1_DESC) "  // 4
		_oSQL:_sQuery +=  " FROM " + _sKardex + " K "
		_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=        " ON (SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SB1.B1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=        " AND SB1.B1_COD     = K.PROD_DEST)"
		_oSQL:_sQuery += " WHERE K.TBL_ORIG = 'SD3'"
		_oSQL:_sQuery +=   " AND K.QT_SAIDA > 0"
		_oSQL:_sQuery +=   " AND K.OP       = ''"
		_oSQL:_sQuery +=   " AND NOT (PROD_DEST = '" + _sProduto + "' AND LOTE_DEST = '" + _sLote + "')"  // transferencia de endereco nao interessam aqui.
		_oSQL:_sQuery +=   " AND K.CFOP     = 'RE4'"
		_oSQL:_sQuery += " GROUP BY K.PROD_DEST, K.LOTE_DEST, SB1.B1_DESC"
		_oSQL:_sQuery += " ORDER BY K.PROD_DEST, K.LOTE_DEST"
		//_oSQL:Log (_sStrLog)
		_aSaiTrLt = aclone (_oSQL:Qry2Array (.F., .F.))

		for _nTrLt = 1 to len (_aSaiTrLt)

			// Calcula a quantidade proporcional para ser passada na chamada recursiva.
			_nQtProp2 = _nQtProp  // Transferencia eh sempre de 1 para 1

			_sID = soma1 (_sID)
			if _aSaiTrLt [_nTrLt, 1] == _sProduto
				_sDescri := 'Tr.para o Lote ' + _aSaiTrLt [_nTrLt, 2] + _sQuebra
			else
				_sDescri := 'Tr.para o item ' + alltrim (_aSaiTrLt [_nTrLt, 1]) + ' - ' + alltrim (_aSaiTrLt [_nTrLt, 4]) + _sQuebra
				_sDescri += 'Lote destino ' + _aSaiTrLt [_nTrLt, 2] + _sQuebra
			endif
			_sDescri += _FmtQt (_aSaiTrLt [_nTrLt, 3], sb1 -> b1_um, _nQtProp2)
			_sRet += '<node BACKGROUND_COLOR="#ffcccc" CREATED="1493031071766" ' + iif (abs (_nNivel) >= _nNivFold, 'FOLDED="true" ', '') + 'ID="' + _sID + '" POSITION="left" TEXT="' + _sDescri + '">'
			
			// Chamada recursiva para buscar a 'origem do lote de origem'
			if len (_sRet) > _nMaxStr  // Antes que alcance o tamanho maximo de uma string, vou parar a busca.
				_sRet += '<node BACKGROUND_COLOR="#ff00cc" CREATED="1493031071766" ID="MAXNIVEIS" POSITION="left" TEXT="(...) limite de memoria excedido"></node>'
			else
				_sRet += U_RastLt (_sFilial, _aSaiTrLt [_nTrLt, 1], _aSaiTrLt [_nTrLt, 2], _nNivel + 1, _aHist, _nQtProp2, _sQueFazer)
			endif
			
			_sRet += '</node>'
		next
	endif


	// Se for a chamada inicial (nivel 0), preciso finalizar o arquivo de saida.
	if _lContinua .and. _nNivel == 0
		_sRet += '</node>'
		_sRet += '</node>'
		_sRet += '</map>'
		
		// Gera quebras de linha no final dos nodos, para interpretacao no NAWeb (creio que esteja em desuso)
		_sRet = strtran (_sRet, '>', '>' + chr (13) + chr (10))
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

	U_ML_SRArea (_aAreaAnt)
return _sRet



// --------------------------------------------------------------------------
// Formata quantidades
static function _FmtQt (_nValor, _sUM, _nQtProp)
return 'Qt: ' + alltrim (transform (_nValor, '@E 999,999,999,999.99')) + ' ' + _sUM + iif (empty (_nQtProp), '', ' (qt.proporcional: ' + alltrim (transform (_nQtProp, '@E 999,999,999,999.9999')) + ')') + "&#xa;"
//return ''  // excepcionalmente quero gerar SEM mostrar as quantidades.
