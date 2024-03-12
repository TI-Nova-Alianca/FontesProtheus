// Programa:  VA_GNF1
// Autor:     Robert Koch
// Data:      30/04/2009
// Descricao: Gera arquivo ZZ9 (previa das notas de compra de uva da safra)
//            Criado com base no ML_GNFS de Jeferson Rech
//
// Historico de alteracoes:
// 29/06/2009 - Robert - Criada a versao para uso sem DCO da CONAB.
// 29/04/2010 - Robert - Criada opcao de selecionar qual dos precos da uva deve ser levado.
// 06/09/2012 - Elaine - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                       da NF com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 20/05/2014 - Robert - Passa a ler notas da view VA_VNOTAS_SAFRA e nao mais do SD1.
//                     - Criados parametros de filial de...ate
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 12/03/2016 - Robert - Criados filtros por grupo de variedades, coop.origem e tintoreas.
// 21/03/2016 - Robert - Criado filtro por tipo (organica/em conversao/etc.)
// 27/03/2018 - Robert - Criado tratamento para gravar campos de mistura de variedades e mensagens para NF.
// 22/04/2020 - Robert - Criado tratamento para gravar campo ZZ9_TES
// 22/04/2021 - Robert - Passa a usar a funcao U_TESSafra() para definicao do TES a usar (GLPI 9891)
//

// --------------------------------------------------------------------------
User Function VA_GNF1 (_lAuto)
	Local cCadastro  := "Geracao Pre-NF Compra de Uva"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.

	u_logID ()
	Private cPerg   := "VAGNF1"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt)//, cFilAnt)
		return
	endif

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"  Este programa tem como objetivo gerar o arquivo de previsao       ")
		AADD(aSays,"  de notas de compra de uva, para posterior conferencia.            ")
		AADD(aSays,"  Este processo eh Gerado uma Vez por Safra, ao Final da Safra.     ")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk ()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return(_lRet)
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _lContinua := .T.
	local _sFilial   := ""
	local _sFornece  := ""
	local _sLoja     := ""
	local _sPreNF    := ""
	local _nItem     := 0
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _sMsg      := ""
	local _aMistura  := {}
	local _sObs      := ""
	local _sMsgNF    := ""
	local _sConduc   := ""
	private _sErros  := ""

	U_LogSX1 (cPerg)
	
	// Verifica se jah existem pre-notas e, se for o caso, confirma exclusao das mesmas.
	_sWhere := ""
	_sWhere += " WHERE D_E_L_E_T_ = ''"
	_sWhere +=   " AND ZZ9_FILIAL BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_sWhere +=   " AND ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sWhere +=   " AND ZZ9_NFCOMP = ''"
	_sWhere +=   " AND ZZ9_PARCEL = '" + mv_par11 + "'"
	_sWhere +=   " AND ZZ9_FILIAL BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if U_RetSQL ("SELECT COUNT (*) FROM " + RetSQLName ("ZZ9") + _sWhere) > 0
		if U_msgyesno ("Ja' existem pre-notas (sem nota de compra gerada) na parcela " + mv_par11 + ". Deseja excluir essas pre-notas antes de continuar o processo? Lembrando que a nao exclusao pode duplicar os dados.", .F.)
			_sSQL := ""
			_sSQL += " UPDATE " + RetSQLName ("ZZ9")
			_sSQL += " SET D_E_L_E_T_ = '*'"
			_sSQL += _sWhere
			U_Log (_sSQL)
			if TCSQLExec (_sSQL) < 0
				u_help ("Erro na exclusao das pre-notas anteriores.",, .t.)
				_lContinua = .F.
			endif
		endif
	endif


	// Leitura de notas de entrada de uva.
	if _lContinua
		_sQuery := ""
		_sQuery += " SELECT FILIAL, DOC, ASSOCIADO AS FORNECE, LOJA_ASSOC AS LOJA, PRODUTO, PESO_LIQ,"
		_sQuery +=        " GRAU, CLAS_FINAL AS PRM99, FINA_COMUM AS VARUVA,"
		_sQuery +=        " FORMA_CLAS_UVA_FINA AS FCUVA, V.CLAS_ABD, SIST_CONDUCAO AS SIST_COND"
		_sQuery +=        ",dbo.VA_FTIPO_FORNECEDOR_UVA (V.ASSOCIADO, V.LOJA_ASSOC, FORMAT(getdate(), 'yyyyMMdd')) AS TP_FORNEC"
		_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_sQuery +=  " WHERE V.TIPO_NF      = 'E'"  // Nao temos mais 'prod.propria' na F07 ---> OR (V.TIPO_NF = 'P' AND V.FILIAL = '07'))"
		_sQuery +=    " AND V.SAFRA         = '" + mv_par05 + "'"
		_sQuery +=    " AND V.ASSOCIADO + V.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_sQuery +=    " AND V.DOC           BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery +=    " AND V.SERIE         = '" + mv_par08 + "'"
		_sQuery +=    " AND V.FILIAL        BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		if mv_par12 == 1
			_sQuery +=    " AND V.FINA_COMUM = 'C'"
		elseif mv_par12 == 2
			_sQuery +=    " AND V.FINA_COMUM = 'F'"
		endif
		if mv_par13 == 1
			_sQuery +=    " AND V.COR = 'T'"
		elseif mv_par13 == 2
			_sQuery +=    " AND V.COR IN ('B', 'R')"
		endif
		if ! empty (mv_par14)
			_sQuery +=    " AND V.PRODUTO IN " + FormatIn (alltrim (mv_par14), "/")
		endif
		if ! empty (mv_par15)
			_sQuery +=    " AND V.PRODUTO NOT IN " + FormatIn (alltrim (mv_par15), "/")
		endif
		if ! empty (mv_par16)
			_sQuery +=    " AND V.COOP_ORIGEM IN " + FormatIn (alltrim (mv_par16), "/")
		endif
		if mv_par17 == 1
			_sQuery +=    " AND V.TINTOREA = 'S'"
		elseif mv_par17 == 2
			_sQuery +=    " AND V.TINTOREA != 'S'"
		endif
		_sQuery +=    " AND V.TIPO_ORGANICO IN " + FormatIn (alltrim (mv_par18),, 1)
		if mv_par20 == 1
			_sQuery +=    " AND V.SIST_CONDUCAO = 'L'"
		elseif mv_par20 == 2
			_sQuery +=    " AND V.SIST_CONDUCAO = 'E'"
		endif

		_sQuery +=    " ORDER BY V.ASSOCIADO, V.LOJA_ASSOC, V.PRODUTO, V.GRAU, V.CLAS_FINAL, SIST_CONDUCAO"
		u_log (_sQuery)

		_sAliasQ = GetNextAlias ()
		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
		count to _nRecCount
		if _nRecCount == 0
			u_help ("Nao foi encontrada nenhuma NF de entrada de uva. Verifique parametros.")
			_lContinua = .F.
		endif


		// Varre o arquivo procurando inconsistencias
		_sMsg = ""
		procregua (_nRecCount)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			incproc ("Verificando dados...")
			if empty ((_sAliasQ) -> varuva)
				_sMsg += "Produto '" + (_sAliasQ) -> produto + "': variedade de uva (comum/fina) nao informada." + chr (13) + chr (10)
				_lContinua = .F.
			endif
			if (_sAliasQ) -> varuva == "F" .and. empty ((_sAliasQ) -> fcuva) 
				_sMsg += "Produto '" + (_sAliasQ) -> produto + "': uva fina: campo '" + alltrim (RetTitle ("B1_VAFCUVA")) + "' nao informado." + chr (13) + chr (10)
				_lContinua = .F.
			endif
			if empty ((_sAliasQ) -> grau)
				_sMsg += "NF '" + (_sAliasQ) -> doc + "': grau nao nao informado." + chr (13) + chr (10)
				_lContinua = .F.
			endif
			if (_sAliasQ) -> varuva == "F" .and. (_sAliasQ) -> fcuva == "F" .and. empty ((_sAliasQ) -> prm99) .and. empty ((_sAliasQ) -> clas_ABD)
				_sMsg += "NF '" + (_sAliasQ) -> doc + "': classificacao da uva nao nao informada para o produto " + alltrim ((_sAliasQ) -> produto) + chr (13) + chr (10)
				_lContinua = .F.
			endif
			(_sAliasQ) -> (dbskip ())
        enddo
        if ! empty (_sMsg)
        	_Erro (_sMsg)
        	//U_ShowMemo (_sMsg)
        endif
	endif

	// Geracao das pre-notas
	if _lContinua
		procregua (_nRecCount)
		incproc ('Gerando dados...')
	    _sPreNF := "000000"
		(_sAliasQ) -> (dbgotop ())
		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			
			// Controla quebra por fornecedor, para gerar nova pre-nota a cada troca de fornecedor.
			_sFilial  = (_sAliasQ) -> filial
			_sFornece = (_sAliasQ) -> Fornece
			_sLoja    = (_sAliasQ) -> Loja
			_sPreNF   = _IncPreNF (_sPreNF)
			_nItem    = 1
			//u_logIni ("forn " + _sfornece + _sloja)
			do while _lContinua ;
				.and. !(_sAliasQ) -> (eof ()) ;
				.and.  (_sAliasQ) -> Filial  == _sFilial ;
				.and.  (_sAliasQ) -> Fornece == _sFornece ;
				.and.  (_sAliasQ) -> Loja    == _sLoja

				// Controla quebra por fornecedor, produto, grau e classificacao, pois as quantidades
				// serao somadas na nota final e preciso controlar o numero de itens por NF de produtor.
				_sProduto = (_sAliasQ) -> produto
				_sGrau    = (_sAliasQ) -> Grau
				_sClasse  = (_sAliasQ) -> prm99
				_sClasABD = (_sAliasQ) -> clas_abd
				_sConduc  = (_sAliasQ) -> sist_cond
				u_log ("Iniciando filial/forn/prod/grau/clas/tp forn", (_sAliasQ) -> filial, _sfornece,_sloja,_sProduto,_sGrau,_sClasse, _sClasABD, (_sAliasQ) -> tp_fornec)

				do while _lContinua ;
					.and. !(_sAliasQ) -> (eof ()) ;
					.and.  (_sAliasQ) -> Filial    == _sFilial ;
					.and.  (_sAliasQ) -> Fornece   == _sFornece ;
					.and.  (_sAliasQ) -> Loja      == _sLoja ;
					.and.  (_sAliasQ) -> produto   == _sProduto ;
					.and.  (_sAliasQ) -> Grau      == _sGrau ;
					.and.  (_sAliasQ) -> prm99     == _sClasse ;
					.and.  (_sAliasQ) -> clas_abd  == _sClasABD ;
					.and.  (_sAliasQ) -> sist_cond == _sConduc
					incproc ()

					_sObs = ""
					_sMsgNF = ""
					

					// Verifica se houve mistura de variedades na mesma carga e grava as
					// demais variedades (posteriormente vai precificar pela de menor valor).
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT DISTINCT PRODUTO, DESCRICAO"
					_oSQL:_sQuery +=   " FROM VA_VCARGAS_SAFRA"
					_oSQL:_sQuery +=  " WHERE SAFRA            = '" + mv_par05   + "'"
					_oSQL:_sQuery +=    " AND FILIAL           = '" + _sFilial  + "'"
					_oSQL:_sQuery +=    " AND CONTRANOTA       = '" + (_sAliasQ) -> doc     + "'"
					_oSQL:_sQuery +=    " AND SERIE_CONTRANOTA = '" + mv_par08   + "'"
					_oSQL:_sQuery +=    " AND ASSOCIADO        = '" + _sFornece + "'"
					_oSQL:_sQuery +=    " AND LOJA_ASSOC       = '" + _sLoja    + "'"
					_oSQL:_sQuery +=    " AND PRODUTO         != '" + (_sAliasQ) -> produto + "'"
					//_oSQL:Log ()
					_aMistura = aclone (_oSQL:Qry2Array ())
					

					// Tratamento especifico para cargas que foram feitas com produto errado. Vou simular a mistura
					// de variedades, pois nao posso mais alterar o produto na nota de entrada. Ajustar o preco manualmente no ZZ9 depois.
					if mv_par05 == '2018' .and. _sFilial == '01' .and. (_sAliasQ) -> doc == '000011876' .and. alltrim ((_sAliasQ) -> produto) == '9901'
						//aadd (_aMistura, {u_TamFixo ('9923', 15, ' ')})
						_sMsgNF += "Produto correto: 9923 (Seibel 2)"
					endif
					if mv_par05 == '2018' .and. _sFilial == '01' .and. (_sAliasQ) -> doc == '000012676' .and. alltrim ((_sAliasQ) -> produto) == '9901'
						//aadd (_aMistura, {u_TamFixo ('9918', 15, ' ')})
						_sMsgNF += "Produto correto: 9918 (Mosc.Embrapa)"
					endif
					if mv_par05 == '2018' .and. _sFilial == '01' .and. (_sAliasQ) -> doc == '000012811' .and. alltrim ((_sAliasQ) -> produto) == '9901'
						//aadd (_aMistura, {u_TamFixo ('9923', 15, ' ')})
						_sMsgNF += "Produto correto: 9923 (Seibel 2)"
					endif

					// Definicao de TES: usar a mesma regra do VA_RUSN
					_sTes = U_TESSafra (mv_par05, _sFornece, _sLoja, 'V')
					if empty (_sTES)
						_lContinua = .F.
					endif

					if _lContinua
						if len (_aMistura) > 3
							u_help ("Este programa nao tem tratamento para cargas com mistura de mais de 3 variedades.")
						else
							reclock ("ZZ9", .T.)
							zz9 -> zz9_filial = _sFilial
							zz9 -> zz9_pre_nf = _sPreNF
							zz9 -> zz9_safra  = mv_par05
							zz9 -> zz9_parcel = mv_par11
							zz9 -> zz9_fornec = _sFornece
							zz9 -> zz9_loja   = _sLoja
							zz9 -> zz9_TipoNF = "N"
							zz9 -> zz9_produt = (_sAliasQ) -> produto
							zz9 -> zz9_grau   = (_sAliasQ) -> grau
							zz9 -> zz9_classe = (_sAliasQ) -> prm99
							zz9 -> zz9_clabd  = (_sAliasQ) -> clas_abd
							zz9 -> zz9_quant  = (_sAliasQ) -> peso_liq
							zz9 -> zz9_vunit  = 0  // Deixa o preco para a rotina de atualizacao de precos.
							zz9 -> zz9_nfentr = (_sAliasQ) -> doc
							zz9 -> zz9_mistu1 = iif (len (_aMistura) >= 1, _aMistura [1, 1], '')
							zz9 -> zz9_mistu2 = iif (len (_aMistura) >= 2, _aMistura [2, 1], '')
							zz9 -> zz9_mistu3 = iif (len (_aMistura) >= 3, _aMistura [3, 1], '')
							zz9 -> zz9_obs    = _sObs
							zz9 -> zz9_msgNF  = _sMsgNF
							zz9 -> zz9_conduc = _sConduc
							zz9 -> zz9_grupo  = mv_par19
							zz9 -> zz9_tes    = _sTES
							msunlock ()
						endif
					endif
					(_sAliasQ) -> (dbskip ())
				enddo
				_nItem ++
			enddo
			//u_logFim ("forn " + _sfornece + _sloja)
		enddo
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SD1")
		u_help ("Processo concluido.")
	else
		u_help ("Processo cancelado.")
	endif

	if ! empty (_sErros)
		u_help (_sErros)
	endif

	/* sugestao de query para testar se gerou ZZ9 de todas as notas de entrada:
	WITH C AS (
	SELECT SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, NOME_ASSOC, PRODUTO, DESCRICAO, SIST_CONDUCAO,CLAS_FINAL, SUM (PESO_LIQ) AS QT_NOTAS, 
	ISNULL ((SELECT SUM (ZZ9_QUANT)
	           FROM ZZ9010
			  WHERE D_E_L_E_T_ = '' AND ZZ9_FILIAL = FILIAL AND ZZ9_SAFRA = SAFRA
	            AND ZZ9_FORNEC = ASSOCIADO AND ZZ9_LOJA = LOJA_ASSOC AND ZZ9_PRODUT = PRODUTO AND ZZ9_CLASSE = CLAS_FINAL and ZZ9_CONDUC = SIST_CONDUCAO), 0) AS QT_ZZ9
	 FROM VA_VNOTAS_SAFRA
	WHERE SAFRA = '2019' AND TIPO_NF = 'E'
	and DATA <= '20190321'

	--AND PRODUTO in ('9925','9822','9948','9959')  -- bordo
	--AND TINTOREA = 'S' AND PRODUTO NOT in ('9925','9822','9948','9959')  -- TINTORIAS (SEM BORDO)
	--AND FINA_COMUM = 'F' AND SIST_CONDUCAO = 'E'
	--AND FINA_COMUM = 'F' AND SIST_CONDUCAO = 'L'
	
	AND NOT (PRODUTO in ('9925','9822','9948','9959')  -- bordo
		     AND TINTOREA = 'S' AND PRODUTO NOT in ('9925','9822','9948','9959')  -- TINTORIAS (SEM BORDO)
	         AND FINA_COMUM = 'F' AND SIST_CONDUCAO = 'E'
	         AND FINA_COMUM = 'F' AND SIST_CONDUCAO = 'L')
			 
	GROUP BY SAFRA, FILIAL, ASSOCIADO, LOJA_ASSOC, NOME_ASSOC, PRODUTO, DESCRICAO, SIST_CONDUCAO, CLAS_FINAL
	)
	SELECT * FROM C
	WHERE QT_NOTAS != QT_ZZ9
	*/

	/* Sugestao de query para testar se gerou os agrupamentos para pagamento de acordo com as regras (ver metodo FechSafr da classe ClsAssoc):
	;WITH C AS (
	SELECT ZZ9_GRUPO AS GRUPO_PAGTO, SB1.B1_VAORGAN, SB1.B1_VATTR, SB1.B1_VARUVA, SB1.B1_VAFCUVA, ZZ9.ZZ9_CONDUC, ZZ9_PRODUT, SB1.B1_DESC
	, SUM (ZZ9.ZZ9_QUANT) AS QUANT, SUM (ZZ9.ZZ9_QUANT * ZZ9.ZZ9_VUNIT) AS VALOR
	FROM ZZ9010 ZZ9
	INNER JOIN SB1010 SB1 ON (SB1.D_E_L_E_T_ = '' AND SB1.B1_FILIAL = '  ' AND SB1.B1_COD = ZZ9.ZZ9_PRODUT)
	WHERE ZZ9.D_E_L_E_T_ = '' AND ZZ9.ZZ9_SAFRA = '2020'
	GROUP BY ZZ9_GRUPO, SB1.B1_VAORGAN, SB1.B1_VATTR, SB1.B1_VARUVA, SB1.B1_VAFCUVA, ZZ9.ZZ9_CONDUC, ZZ9_PRODUT, SB1.B1_DESC
	)
	SELECT *, SUM (VALOR) OVER (PARTITION BY GRUPO_PAGTO) AS VLR_TOT_GRUPO
	FROM C
	ORDER BY GRUPO_PAGTO, B1_VAORGAN, B1_VATTR, B1_VARUVA, B1_VAFCUVA, ZZ9_CONDUC, B1_DESC
	*/
Return



// --------------------------------------------------------------------------
// Gera as notas com 'vazios' entre elas para poder inserir alguma pre-nf manualmente depois, se precisar.
Static Function _IncPreNF (_sPreNF)
return soma1 (soma1 (soma1 (soma1 (soma1 (_sPreNF)))))



// --------------------------------------------------------------------------
// Acumula mensagens de erro.
static function _Erro (_sMsg)
	u_log (_sErro)
	if ! _sMsg $ _sErros
		_sErros += _sMsg + chr (13) + chr (10)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM           DEC           VALID   F3     Opcoes                                         Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,             0,            "",   "SA2",  {},                                            "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,             0,            "",   "   ",  {},                                            "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,             0,            "",   "SA2",  {},                                            "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,             0,            "",   "   ",  {},                                            "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,             0,            "",   "   ",  {},                                            "Safra (ano) para a qual serao geradas as notas de compra."})
	aadd (_aRegsPerg, {06, "Contranota entrada uva inicial", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},                                            "Nota fiscal inicial para leitura das entradas de uva."})
	aadd (_aRegsPerg, {07, "Contranota entrada uva final  ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ",  {},                                            "Nota fiscal final para leitura das entradas de uva."})
	aadd (_aRegsPerg, {08, "Serie das NF de entrada de uva", "C", 3,             0,            "",   "   ",  {},                                            "Serie das notas fiscais de entradas de uva."})
	aadd (_aRegsPerg, {09, "Filial inicial                ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {10, "Filial final                  ", "C", 2,             0,            "",   "SM0",  {},                                            ""})
	aadd (_aRegsPerg, {11, "Gerar com qual parcela        ", "C", 1,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {12, "Comum / vinifera              ", "N", 1,             0,            "",   "   ",  {"Comuns", "Viniferas", "Todas"},              ""})
	aadd (_aRegsPerg, {13, "Cor da uva                    ", "N", 1,             0,            "",   "   ",  {"Tintas", "Bca+rose", "Todas"},               ""})
	aadd (_aRegsPerg, {14, "Apenas varied (separ.por /)   ", "C", 60,            0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {15, "Exceto varied (separ.por /)   ", "C", 60,            0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {16, "Coop.origem (branco=todas)    ", "C", 30,            0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {17, "Tintoreas                     ", "N", 1,             0,            "",   "   ",  {"So Tintoreas", "Exceto tintoreas", "Todas"}, ""})
	aadd (_aRegsPerg, {18, "[O]rg/[E]m con/[C]onven/[B]ord", "C", 4,             0,            "",   "   ",  {},                                            "Informar letra indicando qual(is) deve(m) ser considerada(s): [O]rganicas, [E]m conversao, [C]conencional, [B]ordadura"})
	aadd (_aRegsPerg, {19, "Gerar qual grupo pagamento?   ", "C", 1,             0,            "",   "   ",  {},                                            ""})
	aadd (_aRegsPerg, {20, "Forma de conducao             ", "C", 1,             0,            "",   "   ",  {"Latada", "Espaldeira", "Todas"},             ""})
	U_ValPerg (cPerg, _aRegsPerg)

return
