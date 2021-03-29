// Programa:   SZI_Rel
// Autor:      Robert Koch
// Data:       29/04/2011
// Descricao:  Relatorio conta corrente associados.
//
// Historico de alteracoes:
// 13/07/2011 - Robert - Incluida coluna de filial.
// 20/07/2011 - Robert - Separadas colunas de valores entre debito e credito
//                     - Criadas colunas de juros e saldo.
//                     - Possibilidade de listar valor original ou saldo de cada movimento.
// 01/12/2011 - Robert - Passa a ler campo E5_FORNADT em lugar do E5_CLIFOR nas compensacoes.
//                     - Compensacao com outro fornecedor passa a ser considerada sempre, mesmo
//                       que o relatorio esteja parametrizado como 'resumido'.
// 16/01/2012 - Robert - Nao desconsiderava registros deletados do SE5 ao verificar estornados.
// 05/03/2012 - Robert - Passa a usar a funcao VA_SE5_ESTORNO do SQL.
// 02/05/2012 - Robert - Criada ordenacao por nome do associado.
// 18/09/2012 - Robert - Tratamento na leitura de dados de compensacoes para nao mais usar substrings
//                       do campo E5_DOCUMEN, prevendo futuro aumento do campo E1_NUMERO.
// 11/10/2012 - Robert - Revisao de queries para melhora de performance.
// 03/03/2016 - Robert - Removidos parametros da funcao SetPrint na chamada com interface com usuario (obrigava a gerar em disco local).
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 27/09/2017 - Robert - Melhorada mensagem quando compensado titulo com outro fornecedor.
// 18/02/2018 - Robert - Trazia deb/cred invertido quando TM=15 e transf.saldo para outra filial
// 20/04/2018 - Robert - Melhora performance: substituido [SZI.ZI_SEQ = SUBSTRING (SE5.E5_VACHVEX, 12, 6)] por [SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ] na query.
// 29/03/2021 - Robert - Buscava '' para simular E5_PARCELA por que nao tinha esse campo no SZI. Agora existe.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #PalavasChave      #extrato #conta_corrente #associado
// #TabelasPrincipais #SZI #SA2 #SE2 #SE5 #FK7 #FKA #FK2 #ZZM #ZX5

//
// MINHA INTENCAO EH PASSAR A GERAR ESTE RELATORIO A PARTIR DA CLASSE CLSEXTRCC, DA MESMA FORMA QUE O SZI_REL2.
// ESTOU APENAS AGUARDANDO MAIS ALGUM TEMPO ATEH QUE ESSA CLASSE ESTEJA CONSOLIDADA. ROBERT, 20/09/2019
//

// --------------------------------------------------------------------------
user function SZI_Rel (_lAutomat, _nOrdem)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Conta corrente associados"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SZI"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "SZI_REL"
	nomeprog := "SZI_REL"
	wnrel    := "SZI_REL"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {"Por codigo associado + filial", "Por tipo de movimento + filial", "Por nome associado + filial"}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
//		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString, ;  // Alias
		wnrel, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg, ;  // Parametros
		@titulo, ;  // Titulo do relatorio
		cDesc1, ;  // Descricao 1
		cDesc2, ;  // Descricao 2
		cDesc3, ;  // Descricao 3
		.F., ;  // .T. = usa dicionario
		aOrd, ;  // Array de ordenacoes para o usuario selecionar
		.T., ;  // .T. = comprimido
		tamanho, ;  // P/M/G
		NIL, ;  // Nao pude descobrir para que serve.
		.F., ;  // .T. = usa filtro
		NIL, ;  // lCrystal
		NIL, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T., ;  // .T. = NAO mostra interface para usuario
		.T., ;  // lServer
		NIL)    // cPortToPrint
		aReturn [8] = _nOrdem
	endif
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	
	processa ({|| _Imprime ()})
	MS_FLUSH ()
	DbCommitAll ()

	// Se era execucao via rotina automatica, converte o relatorio para TXT.
	if _lAuto
		U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
	else
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
return



// --------------------------------------------------------------------------
static function _Imprime ()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _sQuebra   := ""
	local _xQuebra   := ""
	local _sNomeQbr  := ""
	local _aTotGer   := {}
	local _aSubTot   := {}
	//local _aObs      := {}
	//local _nObs      := 0
	local _sHist     := ""
	local _aHist     := {}
	local _nHist     := 0
	local _nTamHist  := 79
	private _nMaxLin := 68
	li = _nMaxLin + 1

	IF MV_PAR11 == 1	
		U_help ('Opcao RESUMIDO desabilitada por trazer total inconsistente.',, .t.)
		return
	endif

	procregua (3)

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	// Define titulo e cabecalhos
	do case
	case aReturn [8] == 1 .or. aReturn [8] == 3
		cCabec1 = "Filial         Data        Prf/titulo-parc  Tipo de movimento          Historico                                                                               Debito        Credito          Saldo"
	case aReturn [8] == 2
		cCabec1 = "Filial         Data        Prf/titulo-parc  Associado                  Historico                                                                               Debito        Credito          Saldo"
	otherwise
		u_help ('Ordenacao sem tratamento.')
	endcase

	procregua (10)
	incproc ("Lendo dados...")



	// Busca dados usando uma CTE para facilitar a uniao das consutas de diferentes tabelas.
	_sQuery := ""
	_sQuery += "WITH _CTE AS ("
	
	// Busca conta corrente
	_sQuery += "SELECT 'SZI' AS ORIGEM, ZI_FILIAL AS FILIAL, " + U_LeSM0 ('2', cEmpAnt, '', 'SZI', 'ZI_FILIAL', 'ZI_FILIAL') [2] + " AS DESCFIL, "
	_sQuery +=       " ZI_DATA AS DATA, ZI_TM AS TIPO_MOV, ZI_HISTOR AS HIST, ZI_ASSOC AS ASSOC, ZI_LOJASSO AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
	_sQuery +=       " ZI_VALOR AS VALOR, '' AS E5_RECPAG, ZI_DOC AS NUMERO, ZI_SERIE AS PREFIXO, '' AS DOCUMEN, '' AS E5_SEQ,"
//	_sQuery +=       " '' AS E5_MOTBX, '' AS E5_PARCELA, '' AS E5_TIPODOC, '' AS E5_FORNADT, '' AS E5_LOJAADT, '' AS E5_ORIGEM"
	_sQuery +=       " '' AS E5_MOTBX, ZI_PARCELA AS E5_PARCELA, '' AS E5_TIPODOC, '' AS E5_FORNADT, '' AS E5_LOJAADT, '' AS E5_ORIGEM"
	_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
	_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
	_sQuery +=   " AND SZI.ZI_ASSOC    BETWEEN '" + mv_par01 + "' AND '" + mv_par03 + "'"  // Para ganho de performance
	_sQuery +=   " AND SZI.ZI_ASSOC  + SZI.ZI_LOJASSO  BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery +=   " AND SZI.ZI_DATA     BETWEEN '" + dtos (mv_par07) + "' AND '" + dtos (mv_par08) + "'"
	_sQuery +=   " AND NOT EXISTS (SELECT *"  // Nao quero lcto que gerou movto bancario por que vai ser buscado posteriormente do SE5.
	_sQuery +=                     " FROM " + RETSQLNAME ("SE5") + " SE5 "
	_sQuery +=                    " WHERE SE5.D_E_L_E_T_ != '*'"
	_sQuery +=                      " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"
	_sQuery +=                      " AND SE5.E5_TIPODOC  = 'PA'"  // Acho que VL tambem vai interessar posteriormente...
	_sQuery +=                      " AND SE5.E5_SITUACA != 'C'"
	_sQuery +=                      " AND SE5.E5_FILIAL   = SZI.ZI_FILIAL"
	_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0)"

	// Busca movimento bancario ligado ao SZI.
	_sQuery += " UNION ALL "
	_sQuery += "SELECT 'SE5' AS ORIGEM, E5_FILIAL AS FILIAL, " + U_LeSM0 ('2', cEmpAnt, '', 'SE5', 'E5_FILIAL', 'E5_FILIAL') [2] + " AS DESCFIL, "
	_sQuery +=       " E5_DATA AS DATA, ZI_TM AS TIPO_MOV, E5_HISTOR AS HIST, E5_CLIFOR AS ASSOC, E5_LOJA AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
	_sQuery +=       " E5_VALOR AS VALOR, E5_RECPAG, E5_NUMERO AS NUMERO, E5_PREFIXO AS PREFIXO, E5_DOCUMEN AS DOCUMEN, E5_SEQ,"
	_sQuery +=       " E5_MOTBX, E5_PARCELA, E5_TIPODOC, E5_FORNADT, E5_LOJAADT, E5_ORIGEM"
	_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5, "
	_sQuery +=             RETSQLNAME ("SZI") + " SZI "
	_sQuery += " WHERE SE5.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SE5.E5_FILIAL   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
	_sQuery +=   " AND SZI.ZI_FILIAL   = SE5.E5_FILIAL"
	_sQuery +=   " AND SE5.E5_CLIFOR   BETWEEN '" + mv_par01 + "' AND '" + mv_par03 + "'"  // Para ganho de performance
	_sQuery +=   " AND SE5.E5_CLIFOR + SE5.E5_LOJA BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_sQuery +=   " AND SE5.E5_DATA     BETWEEN '" + dtos (mv_par07) + "' AND '" + dtos (mv_par08) + "'"
	_sQuery +=   " AND SE5.E5_SITUACA != 'C'"
//	_sQuery +=   " AND SE5.E5_VACHVEX  LIKE 'SZI%'"  // Para ganho de performance: todo SE5 que me interessar aqui terah chave externa com o SZI.

	// Resumido nao eh mais usado --> // Se for relatorio resumido, ignora as compensacoes, mas somente as compensacoes do proprio associado,
	// Resumido nao eh mais usado --> // pois podem existir compensacoes contra outros associados.
	// Resumido nao eh mais usado --> if mv_par11 == 1
	// Resumido nao eh mais usado --> 	_sQuery += " AND NOT (SE5.E5_MOTBX = 'CMP' AND SE5.E5_FORNADT = SZI.ZI_ASSOC AND SE5.E5_LOJAADT = SZI.ZI_LOJASSO)"
	// Resumido nao eh mais usado --> endif

	_sQuery +=   " AND SZI.ZI_ASSOC    = SE5.E5_CLIFOR"
	_sQuery +=   " AND SZI.ZI_LOJASSO  = SE5.E5_LOJA"
//	_sQuery +=   " AND SZI.ZI_SEQ      = SUBSTRING (SE5.E5_VACHVEX, 12, 6)"
	_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"

	_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"

	_sQuery += ") SELECT _CTE.*, A2_NOME AS NOME, ZX5_10DESC AS DESC_TM, ZX5_10DC AS DEB_CRED"
	_sQuery +=    " FROM _CTE,"
	_sQuery +=           RETSQLNAME ("ZX5") + " ZX5, "
	_sQuery +=           RETSQLNAME ("SA2") + " SA2 "
	_sQuery +=   " WHERE SA2.A2_COD      = _CTE.ASSOC"
	_sQuery +=     " AND SA2.A2_LOJA     = _CTE.LOJASSO"
	_sQuery +=     " AND SA2.D_E_L_E_T_ != '*'"
	_sQuery +=     " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
	_sQuery +=     " AND ZX5.D_E_L_E_T_ != '*'"
	_sQuery +=     " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
	_sQuery +=     " AND ZX5.ZX5_TABELA  = '10'"
	_sQuery +=     " AND ZX5.ZX5_10COD   = _CTE.TIPO_MOV"
	if mv_par09 == 2
		_sQuery +=   " AND ZX5.ZX5_10CAPI = 'S'"
	else
		_sQuery +=   " AND ZX5.ZX5_10CAPI != 'S'"
	endif
	if ! empty (mv_par10)
		_sQuery +=     " AND SA2.A2_VACORIG IN " + FormatIn (alltrim (mv_par10), '/')
	endif
	do case
	case aReturn [8] == 1
		// Ordenacao por varios campos por que, do contrario, a cada vez o relariorio traz uma nova ordenacao e fica dificil fazer comparativos...
//		_sQuery += " ORDER BY ASSOC, LOJASSO, DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, HIST, PREFIXO, NUMERO, E5_PARCELA"
		_sQuery += " ORDER BY ASSOC, LOJASSO, DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, PREFIXO, NUMERO, E5_PARCELA, HIST"
	case aReturn [8] == 2
		_sQuery += " ORDER BY TIPO_MOV, ASSOC, LOJASSO, ORIGEM DESC, E5_SEQ"
	case aReturn [8] == 3
		// Ordenacao por varios campos por que, do contrario, a cada vez o relariorio traz uma nova ordenacao e fica dificil fazer comparativos...
		_sQuery += " ORDER BY A2_NOME, ASSOC, LOJASSO, DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, HIST, PREFIXO, NUMERO, E5_PARCELA"
	otherwise
		u_help ('Ordenacao sem tratamento.')
	endcase
	
//	u_showmemo(_squery)
	
	u_log2 ('debug', _squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "DATA", "D")
	
	procregua ((_sAliasQ) -> (reccount ()))

	_aTotGer = {0, 0, 0}
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		incproc ()

		if li > _nMaxLin - 6 .or. mv_par12 == 1
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		
		// Define criterio de quebra conforme ordenacao selecionada pelo usuario e imprime cabecalho da quebra.

		do case
		case aReturn [8] == 1 .or. aReturn [8] == 3 // Por [codigo ou nome] associado + filial
			_sQuebra  = "ASSOC + '/' + LOJASSO"
			_xQuebra = (_sAliasQ) -> &(_sQuebra)
			_sNomeQbr = (_sAliasQ) -> nome
			@ li, 0 psay "Associado: " + _xQuebra + ' - ' + _sNomeQbr
			li += 2
		case aReturn [8] == 2  // Por tipo de movimento + filial
			_sQuebra = "TIPO_MOV"
			_xQuebra = (_sAliasQ) -> &(_sQuebra)
			_sNomeQbr = (_sAliasQ) -> Desc_TM
			@ li, 0 psay "Tipo de movimento: " + _xQuebra + ' - ' + _sNomeQbr
			li += 2
		otherwise
			u_help ('Ordenacao sem tratamento.')
		endcase
	
		// Controla quebra
		_aSubTot = {0, 0, 0}
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> &(_sQuebra) == _xQuebra
			incproc ()

			// Verifica se o movimento deve ser tratado como debito ou como credito.
			_sDC = (_sAliasQ) -> deb_cred
			if (_sAliasQ) -> origem == 'SE5'
				_lInverte = .F.
				if _sDC == "D" .and. (_sAliasQ) -> e5_recpag == "R"
					_lInverte = ! _lInverte
				elseif _sDC == "C" .and. (_sAliasQ) -> e5_recpag == "P"
					_lInverte = ! _lInverte
				endif
				if (_sAliasQ) -> e5_motbx == "CMP" .and. (_sAliasQ) -> e5_tipodoc != 'CP'
					_lInverte = ! _lInverte
				endif
				if (_sAliasQ) -> e5_motbx == "NOR" .and. (_sAliasQ) -> tipo_mov == '15' .and. (_sAliasQ) -> e5_origem = 'SZI_TSF' 
					_lInverte = ! _lInverte
				endif

				if _lInverte
					if _sDC == "D"
						_sDC = "C"
					elseif _sDC == "C"
						_sDC = "D"
					endif
				endif
			endif

			_sHist = alltrim ((_sAliasQ) -> hist)

			// Quando for baixa por compensacao, monta historico um pouco mais elaborado.
			if (_sAliasQ) -> e5_motbx == "CMP" .and. ! empty ((_sAliasQ) -> documen)
				_sHist = _HistComp ((_sAliasQ) -> filial, (_sAliasQ) -> documen, (_sAliasQ) -> assoc, (_sAliasQ) -> lojasso, (_sAliasQ) -> e5_fornadt, (_sAliasQ) -> e5_lojaadt, (_sAliasQ) -> valor)
			endif

			// Observacoes sao concatenadas com o historico.
			if mv_par15 == 1 .and. ! empty ((_sAliasQ) -> codmemo)
				_sObs = alltrim (msmm ((_sAliasQ) -> codmemo,,,,3,,,'SZI'))
				if ! empty (_sObs)
					_sHist += chr (13) + chr (10) + "Obs.:" + _sObs
				endif
			endif

			// Quebra o historico em quantas linhas forem necessarias (pelo menos uma).
			_aHist = U_QuebraTXT (_sHist, _nTamHist)
			if len (_aHist) == 0
				aadd (_aHist, "")
			endif

			// Monta linha para impressao
			_sLinImp = ""
			_sLinImp += U_TamFixo ((_sAliasQ) -> DescFil, 13) + "  "
			_sLinImp += U_TamFixo (dtoc ((_sAliasQ) -> data), 10) + "  "
			_sLinImp += U_TamFixo ((_sAliasQ) -> prefixo + '/' + (_sAliasQ) -> numero + '-' + (_sAliasQ) -> e5_parcela, 15) + '  '
			do case
			case aReturn [8] == 1 .or. aReturn [8] == 3  // Por [codigo ou nome] associado
				_sLinImp += U_TamFixo ((_sAliasQ) -> tipo_mov + "-" + (_sAliasQ) -> desc_tm, 25) + "  "
			case aReturn [8] == 2  // Por tipo de movimento
				_sLinImp += U_TamFixo ((_sAliasQ) -> assoc + "/" + (_sAliasQ) -> lojasso + " " + (_sAliasQ) -> nome, 24) + "   "
			otherwise
				u_help ('Ordenacao sem tratamento.')
			endcase
			
			// Primeira linha do historico
			_sLinImp += U_TamFixo (_aHist [1], _nTamHist) + " "
			
			if _sDC == 'D'
				_sLinImp += transform ((_sAliasQ) -> valor, "@E 999,999,999.99") + space (15)
				_aSubTot [1] += (_sAliasQ) -> valor
				_aTotGer [1] += (_sAliasQ) -> valor
				_aSubTot [3] -= (_sAliasQ) -> valor
				_aTotGer [3] -= (_sAliasQ) -> valor
			elseif _sDC == 'C'
				_sLinImp += space (15) + transform ((_sAliasQ) -> valor, "@E 999,999,999.99")
				_aSubTot [2] += (_sAliasQ) -> valor
				_aTotGer [2] += (_sAliasQ) -> valor
				_aSubTot [3] += (_sAliasQ) -> valor
				_aTotGer [3] += (_sAliasQ) -> valor
			else
				_sLinImp += space (29)
			endif
			_sLinImp += " " + transform (_aSubTot [3], "@E 999,999,999.99")

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay _sLinImp
			li ++

			// Imprime as linhas restantes do historico.
			for _nHist = 2 to len (_aHist)
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 71 psay _aHist [_nHist]
				li ++
		//		u_log (_aHist [_nHist])
			next

			(_sAliasQ) -> (dbskip ())
		enddo
		if li > _nMaxLin - 3
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay space (151) + "--------------  -------------  -------------"
		li ++
		@ li, 0 psay space (113) + "Totais " + U_TamFixo (_sNomeQbr, 30) + ' ' + transform (_aSubTot [1], "@E 999,999,999.99") + " " + transform (_aSubTot [2], "@E 999,999,999.99") + " " + transform (_aSubTot [3], "@E 999,999,999.99")
		li += 2
		@ li, 0 psay __PrtThinLine ()
		li += 2
	enddo
	(_sAliasQ) -> (dbclosearea ())

	if li > _nMaxLin - 3
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	@ li, 0 psay space (133) + "TOTAIS GERAIS:    " + transform (_aTotGer [1], "@E 999,999,999.99") + " " + transform (_aTotGer [2], "@E 999,999,999.99") + " " + transform (_aTotGer [3], "@E 999,999,999.99")
	li += 2

	// Imprime parametros usados na geracao do relatorio
	if li > _nMaxLin - 2
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	U_ImpParam (_nMaxLin)
return



// --------------------------------------------------------------------------
// Monta historico a ser listado em caso de compensacao de titulos.
Static Function _HistComp (_sFilial, _sDocumen, _sCliFor, _sLoja, _sFornAdt, _sLojaAdt, _nValor)
	local _sRet     := ""
	local _aRetQry  := {}
	local _oSQL     := NIL

	_sRet = 'Compens.tit. '

	// Busca dados do movimento atual amarrado ao movimento 'par' da compensacao para, a
	// partir deste, buscar dados da conta corrente (SZI).
	// Busca dados com TOP 1 por causa do problema na forma de gravacao do E5_DOCUMEN (ver comentario abaixo).
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT TOP 1 SE5_ORIG.E5_PREFIXO, SE5_ORIG.E5_NUMERO, SE5_ORIG.E5_PARCELA, ZI_HISTOR"
	_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5_ORIG, "
	_oSQL:_sQuery +=             RETSQLNAME ("SE5") + " SE5_COMP, "
	_oSQL:_sQuery +=             RETSQLNAME ("SZI") + " SZI "
	_oSQL:_sQuery += " WHERE SE5_COMP.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_FILIAL   = '" + _sFilial + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_DOCUMEN  = '" + _sDocumen + "'"  // Registro atual do SE5
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_CLIFOR   = '" + _sCliFor + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_LOJA     = '" + _sLoja + "'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_MOTBX    = 'CMP'"
	_oSQL:_sQuery +=   " AND SE5_COMP.E5_SITUACA != 'C'"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5_COMP.R_E_C_N_O_) = 0"
	_oSQL:_sQuery +=   " AND SE5_ORIG.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_FILIAL   = SE5_COMP.E5_FILIAL"

	// o Registro que faz o 'par' da compensacao parece estar, algumas vezes, sem o codigo de fornecedor
	// dentro do campo E5_DOCUMEN. Parece ser em casos onde foi usado filtro 'considera titulos de
	// outros fornecedores' no momento da compensacao.
	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_DOCUMEN LIKE SE5_COMP.E5_PREFIXO + SE5_COMP.E5_NUMERO + SE5_COMP.E5_PARCELA + SE5_COMP.E5_TIPO + '%'"  // Para ganho de performance.
	_oSQL:_sQuery +=   " AND (SE5_ORIG.E5_DOCUMEN  = SE5_COMP.E5_PREFIXO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_NUMERO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_PARCELA"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_TIPO"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_CLIFOR"
	_oSQL:_sQuery +=                             " + SE5_COMP.E5_LOJA"
	_oSQL:_sQuery +=   " OR (SE5_ORIG.E5_DOCUMEN  = SE5_COMP.E5_PREFIXO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_NUMERO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_PARCELA"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_TIPO"
	_oSQL:_sQuery +=                            " + SE5_COMP.E5_LOJA"
	_oSQL:_sQuery +=       " AND SE5_ORIG.E5_CLIFOR = SE5_COMP.E5_CLIFOR"
	_oSQL:_sQuery +=       " AND SE5_ORIG.E5_VALOR  = " + cvaltochar (_nValor)
	_oSQL:_sQuery +=   " ))"

	_oSQL:_sQuery +=   " AND SE5_ORIG.E5_SEQ      = SE5_COMP.E5_SEQ"
	_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5_ORIG.R_E_C_N_O_) = 0"
	_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = SE5_ORIG.E5_FILIAL"
	_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = SE5_ORIG.E5_CLIFOR"
	_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = SE5_ORIG.E5_LOJA"
	_oSQL:_sQuery +=   " AND SZI.ZI_SEQ      = SUBSTRING (SE5_ORIG.E5_VACHVEX, 12, 6)"
//	u_log (_oSQL:_sQuery)
	_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
	
	// Se conseguir os dados pela query, eu prefiro.
	if len (_aRetQry) > 0
		_sRet += _aRetQry [1, 1] + '/' + _aRetQry [1, 2] + '-' + _aRetQry [1, 3]

		// Se foi compensacao contra outro fornecedor, busca seus dados.
		if _sFornAdt + _sLojaAdt != _sCliFor + _sLoja
//			_sRet += ' [de ' + _sFornAdt + '/' + _sLojaAdt + ']'
			_sRet += ' #### de ' + _sFornAdt + '/' + _sLojaAdt + ' ' + alltrim (left (fBuscaCpo ('SA2', 1, xfilial ('SA2') + _sFornAdt + _sLojaAdt, 'A2_NOME'), 20))
		endif

		// Acrescenta o historico do lancamento original da conta corrente.
		if ! empty (_aRetQry [1, 4])
			_sRet += " (" + alltrim (_aRetQry [1, 4]) + ")"
		endif
	else
		_sRet += left (_sDocumen, 13)

		// Se foi compensacao contra outro fornecedor, busca seus dados.
		if _sFornAdt + _sLojaAdt != _sCliFor + _sLoja
//			_sRet += ' [de ' + _sFornAdt + '/' + _sLojaAdt + ']'
			_sRet += ' #### de ' + _sFornAdt + '/' + _sLojaAdt + ' ' + alltrim (left (fBuscaCpo ('SA2', 1, xfilial ('SA2') + _sFornAdt + _sLojaAdt, 'A2_NOME'), 20))
		endif
	endif
return _sRet



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {02, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {03, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {04, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {05, "Tipo de movimento inicial     ", "C", 2,  0,  "",   "ZX510 ", {},                                  ""})
	aadd (_aRegsPerg, {06, "Tipo de movimento final       ", "C", 2,  0,  "",   "ZX510 ", {},                                  ""})
	aadd (_aRegsPerg, {07, "Data digitacao inicial        ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {08, "Data digitacao final          ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {09, "Tipo de conta corrente        ", "N", 1,  0,  "",   "      ", {"Normal", "Capital social"},        ""})
	aadd (_aRegsPerg, {10, "Coop.orig(AL/SV/...) bco=todas", "C", 18, 0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {11, "Resumido/detalhado            ", "N", 1,  0,  "",   "      ", {"Resumido", "Detalhado"},           ""})
	aadd (_aRegsPerg, {12, "Quebra pag. associado/tipo mov", "N", 1,  0,  "",   "      ", {"Sim", "Nao"},                      ""})
	aadd (_aRegsPerg, {13, "Filial inicial                ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
	aadd (_aRegsPerg, {14, "Filial final                  ", "C", 2,  0,  "",   "SM0   ", {},                                  ""})
	aadd (_aRegsPerg, {15, "Listar observacoes            ", "N", 1,  0,  "",   "      ", {"Sim", "Nao"},                      ""})

	aadd (_aDefaults, {"03", "zzzzzz"})
	aadd (_aDefaults, {"04", "zz"})
	aadd (_aDefaults, {"06", "zz"})
	aadd (_aDefaults, {"08", stod ("20491231")})
	aadd (_aDefaults, {"10", "122049"})
	aadd (_aDefaults, {"11", 3})
	aadd (_aDefaults, {"12", 2})
	aadd (_aDefaults, {"13", ''})
	aadd (_aDefaults, {"14", 'zz'})
	aadd (_aDefaults, {"15", 2})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
