// Programa:   VA_ECM
// Autor:      Robert Koch
// Data:       08/05/2008
// Descricao:  Relatorio de evolucao mensal do custo medio/standard dos produtos.
// 
// Historico de alteracoes:
// 20/05/2008 - Robert  - Criado parametro para filtrar pelo campo B1_MRP
// 13/10/2008 - Robert  - Criadas ordenacoes por linha e grupo.
// 08/01/2009 - Robert  - Criados parametros de almoxarifado de... ate.
// 27/07/2009 - Robert  - Funcao _SomaMes removida para classe externa.
// 30/09/2010 - Robert  - Campo B1_LINHAPR vai ser removido do cadastro.
// 09/03/2011 - Robert  - Criado parametro para listar custo medio ou standard.
//                      - Criada opcao de saida em relatorio ou planilha.
// 25/10/2018 - Robert  - Criada opcao de ignorar almoxarifados zerados.
// 28/02/2019 - Robert  - Criada selecao de filiais - Opcao de aglutinar por Filial+almox / Filial / Empresa
// 12/03/2020 - Cláudia - Incluido filtros no SQL retirando filtros AO,AP,GF e MO, conforme GLPI 7641
//
// --------------------------------------------------------------------------
user function VA_ECM () //(_lAutomat)
	local _aPeriodos := {}
	local _dData     := ctod ("")
	local _dDataIni  := ctod ("")
	local _dDataFim  := ctod ("")

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Evolucao de custos"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SB1"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := "Evolucao de custos"
	cPerg    := "VA_ECM"
	nomeprog := "VA_ECM"
	wnrel    := "VA_ECM"
	tamanho  := "G"
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	nTipo    := 15
	limite   := 220
	aOrd     := {"Linha produto + produto", "Grupo produto + produto"}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	// Loop para validar parametros
	Do while .t.	
		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., tamanho, NIL, .T., NIL, NIL, .F., .T., NIL)

		If nLastKey == 27
			Return
		Endif
		
		delete file (__reldir + wnrel + ".##r")
		SetDefault (aReturn, cString)
		
		If nLastKey == 27
			Return
		Endif
		
		if substr (mv_par01, 3, 1) != "/" .or. substr (mv_par02, 3, 1) != "/"
			u_help ("Periodo inicial e final devem ser informados mes e ano, no formato 'MM/AAAA'")
			loop
		endif

		// Monta array com as datas iniciais e finais de cada periodo (coluna a ser listada)
		// e jah aproveita para validar os parametros.
		_dDataIni  = ctod ("01/" + mv_par01)
		_dDataFim  = lastday (ctod ("01/" + mv_par02))
		_aPeriodos = {}
		_dData = _dDataIni
		_oDUtil := ClsDUtil():New ()
		
		do while left (dtos (_dData), 6) <= left (dtos (_dDataFim), 6)
			aadd (_aPeriodos, {_dData, ;
			                   lastday (_dData), ;
			                   "M_" + substr (dtos (_dData), 5, 2) + "_" + substr (dtos (_dData), 1, 4);
			                  })
			_dData = stod (_oDUtil:SomaMes (left (dtos (_dData), 6), 1) + "01")
		enddo
		
		if mv_par16 == 1 .and. len (_aPeriodos) > 12
			u_help ("Numero maximo de periodos (colunas) a listar nao pode ser maior que 12 periodos, quando destino for 'relatorio'")
			loop
		endif
		
		if len (_aPeriodos) < 1
			u_help ("Intervalo de periodos invalido (fim menor que inicio).")
			loop
		endif

		processa ({|| _Imprime (_aPeriodos)})
		If mv_par16 == 1 .and. aReturn [5] == 1
			DbCommitAll ()
			ourspool(wnrel)
		Endif
		exit
	enddo
Return
// --------------------------------------------------------------------------
// Geracao do arquivo de trabalho p/ impressao
Static function _Imprime (_aPeriodos)
	local _nMaxLin   := 63
	local _aCampos   := {}
	local _nPeriodo  := 0
	local _dData     := ctod ("")
	local _dDataIni  := _aPeriodos [1, 1]
	local _dDataFim  := _aPeriodos [len (_aPeriodos), 2]
	local _aArqTrb   := {}
	local _lTemValor := .F.
	local _lContinua := .T.
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _aFiliais  := {}
	local _nFilial   := 0
	local _sFiliais  := ''

	u_log (_aPeriodos)
	
	If ! Empty(aReturn[7])
		u_help ("Este relatorio nao permite filtro de usuario")
		return
	endif

	Titulo   := "Evolucao do custo " + iif (mv_par15 == 1, "medio", "standard")

	// Define filiais a serem lidas.
	if _lContinua
		_aFiliais = U_LeSM0 ('6', cEmpAnt, '', '')
		u_log (_aFiliais)
		if len (_aFiliais) == 0
			_lContinua = .F.
		else
			_sFiliais = ''
			for _nFilial = 1 to len (_aFiliais)
				_sFiliais += alltrim (_aFiliais [_nFilial, 3]) + iif (_nFilial < len (_aFiliais), '/', '')
			next
		endif
	endif

	procregua (sb1 -> (reccount ()))
	incproc ("Buscando dados")
	
	if _lContinua
		// Monta campos cfe. o numero de periodos.
		_aCampos = {}
		aadd (_aCampos, {"Linha",     "C", tamsx3 ("B1_CODLIN")[1], 0})
		aadd (_aCampos, {"Grupo",     "C", tamsx3 ("B1_GRUPO")[1], 0})
		aadd (_aCampos, {"Tipo",      "C", tamsx3 ("B1_TIPO")[1], 0})
		aadd (_aCampos, {"Produto",   "C", 15, 0})
		aadd (_aCampos, {"Descricao", "C", 47, 0})
		aadd (_aCampos, {"Filial",    "C", 2,  0})
		aadd (_aCampos, {"ALMOX",     "C", 2,  0})
		for _nPeriodo = 1 to len (_aPeriodos)
			aadd (_aCampos, {_aPeriodos [_nPeriodo, 3], "N", 18, 2})
		next
		aadd (_aCampos, {"Medio_Atu", "N", 18, 2})
		aadd (_aCampos, {"Stand_Atu", "N", 18, 2})

		// Cria arquivo de trabalho para acumular a movimentacao encontrada.
		U_ArqTrb ("Cria", "_trb", _aCampos, {"Linha + Produto + Filial + Almox", "Grupo + Produto + Filial + Almox"}, @_aArqtrb)
		
/* portado para SQL
		sb1 -> (dbsetorder (1))
		sb9 -> (dbsetorder (1))  // B9_FILIAL+B9_COD+B9_LOCAL+DTOS(B9_DATA)
		sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
		sb1 -> (dbseek (xfilial ("SB1") + mv_par05, .T.))
		do while ! sb1 -> (eof ()) .and. sb1 -> b1_filial == xfilial ("SB1") .and. sb1 -> b1_cod <= mv_par06

			if sb1 -> b1_tipo < mv_par03 .or. sb1 -> b1_tipo > mv_par04 .or. sb1 -> b1_grupo < mv_par08 .or. sb1 -> b1_grupo > mv_par09 .or. sb1 -> b1_codlin < mv_par11 .or. sb1 -> b1_codlin > mv_par12
				sb1 -> (dbskip ())
				loop
			endif
			
			// Valida filtro do usuario
			dbselectarea (cString)
			If !Empty(aReturn[7]) .And. !&(aReturn[7])
				dbSkip()
				Loop
			EndIf	

			// Busca custo dos meses jah fechados.
			sb9 -> (dbseek (xfilial ("SB9") + sb1 -> b1_cod, .T.))
			do while ! sb9 -> (eof ()) .and. sb9 -> b9_filial == xfilial ("SB9") .and. sb9 -> b9_cod == sb1 -> b1_cod

				if sb9 -> b9_local < mv_par13 .or. sb9 -> b9_local > mv_par14
					sb9 -> (dbskip ())
					loop
				endif
				
				// Determina em qual periodo esta data deve ser considerada.
				_nPeriodo = ascan (_aPeriodos, {|_aVal| _aVal [1] <= sb9 -> b9_data .and. _aVal [2] >= sb9 -> b9_data})

				if _nPeriodo == 0  // Fora do periodo solicitado
					sb9 -> (dbskip ())
					loop
				endif

				if ! _trb -> (dbseek (sb1 -> b1_codlin + sb1 -> b1_cod + sb9 -> b9_local, .F.))
					reclock ("_trb", .T.)
					_trb -> Linha     = sb1 -> b1_codlin
					_trb -> Grupo     = sb1 -> b1_grupo
					_trb -> Produto   = sb1 -> b1_cod
					_trb -> Tipo      = sb1 -> b1_tipo
					_trb -> Descricao = sb1 -> b1_desc
					_trb -> Stand_Atu = sb1 -> b1_custd
					_trb -> filial    = sb9 -> b9_filial
					_trb -> almox     = sb9 -> b9_local
				else
					reclock ("_trb", .F.)
				endif
				if mv_par15 == 1  // medio
					_trb -> &(_aPeriodos [_nPeriodo, 3]) = sb9 -> b9_vini1 / sb9 -> b9_qini
				elseif mv_par15 == 2  // standard
					_trb -> &(_aPeriodos [_nPeriodo, 3]) = sb9 -> b9_custd
				endif
				msunlock ()
				sb9 -> (dbskip ())
			enddo


			// Busca custo atual
			sb2 -> (dbseek (xfilial ("SB2") + sb1 -> b1_cod, .T.))
			do while ! sb2 -> (eof ()) .and. sb2 -> b2_filial == xfilial ("SB2") .and. sb2 -> b2_cod == sb1 -> b1_cod
				if sb2 -> b2_local < mv_par13 .or. sb2 -> b2_local > mv_par14
					sb2 -> (dbskip ())
					loop
				endif
				if ! _trb -> (dbseek (sb1 -> b1_codlin + sb1 -> b1_cod + sb2 -> b2_local, .F.))
					reclock ("_trb", .T.)
					_trb -> Linha     = sb1 -> b1_codlin
					_trb -> Grupo     = sb1 -> b1_grupo
					_trb -> Produto   = sb1 -> b1_cod
					_trb -> Tipo      = sb1 -> b1_tipo
					_trb -> Descricao = sb1 -> b1_desc
					_trb -> Stand_Atu = sb1 -> b1_custd
					_trb -> filial    = sb2 -> b2_filial
					_trb -> almox     = sb2 -> b2_local
				else
					reclock ("_trb", .F.)
				endif
				_trb -> Medio_Atu = sb2 -> b2_vfim1 / sb2 -> b2_qfim
				msunlock ()
				sb2 -> (dbskip ())
			enddo

			sb1 -> (dbskip ())
		enddo
*/

		// Busca custo dos meses jah fechados.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += "SELECT B1_CODLIN, B1_GRUPO, B1_COD, B1_DESC, B1_TIPO, B1_CUSTD,"
		_oSQL:_sQuery +=       " B2_FILIAL, B2_LOCAL, B2_VFIM1, B2_QFIM,"
		_oSQL:_sQuery +=       " ISNULL (B9_DATA, '') AS B9_DATA, ISNULL (B9_VINI1, 0) AS B9_VINI1, ISNULL (B9_QINI, 0) AS B9_QINI, ISNULL (B9_CUSTD, 0) AS B9_CUSTD"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1, "
		_oSQL:_sQuery +=             RetSQLName ("SB2") + " SB2 "
		_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SB9") + " SB9 "
		_oSQL:_sQuery +=         " ON (SB9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND SB9.B9_FILIAL  = SB2.B2_FILIAL"
		_oSQL:_sQuery +=         " AND SB9.B9_COD     = SB2.B2_COD"
		_oSQL:_sQuery +=         " AND SB9.B9_LOCAL   = SB2.B2_LOCAL"
		_oSQL:_sQuery +=         " AND SB9.B9_DATA    BETWEEN '" + dtos (_aPeriodos [1, 1]) + "' AND '" + dtos (_aPeriodos [len (_aPeriodos), 2]) + "'"
		_oSQL:_sQuery +=         ")"
		_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD     BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		if ! empty (mv_par07)
			_oSQL:_sQuery += " AND SB1.B1_COD IN " + FormatIn (mv_par07, '/')
		endif
		_oSQL:_sQuery +=   " AND SB1.B1_GRUPO   BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_CODLIN  BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
		_oSQL:_sQuery +=   " AND SB2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB2.B2_FILIAL IN " + FormatIn (_sFiliais, '/')
		_oSQL:_sQuery +=   " AND SB2.B2_COD     = SB1.B1_COD"
		_oSQL:_sQuery +=   " AND SB2.B2_LOCAL   BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
		_oSQL:_sQuery += ")"
		if mv_par17 == 1
			_oSQL:_sQuery += " SELECT *"
			_oSQL:_sQuery +=   " FROM C"
			_oSQL:_sQuery +=   " WHERE B1_COD  NOT like  'AO%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'AP%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'GF%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'MO%' "
			//_oSQL:_sQuery +=   " Where B1_COD NOT IN ('AO-011303','AP-091401','AP-091403')"
		elseif mv_par17 == 2
			_oSQL:_sQuery += "SELECT B1_CODLIN, B1_GRUPO, B1_COD, B1_DESC, B1_TIPO, B1_CUSTD,"
			_oSQL:_sQuery +=       " B2_FILIAL, '**' AS B2_LOCAL, SUM (B2_VFIM1) AS B2_VFIM1, SUM (B2_QFIM) AS B2_QFIM,"
			_oSQL:_sQuery +=       " B9_DATA, SUM (B9_VINI1) AS B9_VINI1, SUM (B9_QINI) AS B9_QINI, AVG (B9_CUSTD) AS B9_CUSTD"
			_oSQL:_sQuery +=   " FROM C"
			_oSQL:_sQuery +=   " WHERE B1_COD  NOT like  'AO%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'AP%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'GF%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'MO%' "
			//_oSQL:_sQuery +=   " Where B1_COD NOT IN ('AO-011303','AP-091401','AP-091403')"
			_oSQL:_sQuery +=  " GROUP BY B2_FILIAL, B1_CODLIN, B1_GRUPO, B1_COD, B1_DESC, B1_TIPO, B1_CUSTD, B9_DATA"
			
		else
			_oSQL:_sQuery += "SELECT B1_CODLIN, B1_GRUPO, B1_COD, B1_DESC, B1_TIPO, B1_CUSTD,"
			_oSQL:_sQuery +=       " '**' AS B2_FILIAL, '**' AS B2_LOCAL, SUM (B2_VFIM1) AS B2_VFIM1, SUM (B2_QFIM) AS B2_QFIM,"
			_oSQL:_sQuery +=       " B9_DATA, SUM (B9_VINI1) AS B9_VINI1, SUM (B9_QINI) AS B9_QINI, AVG (B9_CUSTD) AS B9_CUSTD"
			_oSQL:_sQuery +=   " FROM C"
			_oSQL:_sQuery +=   " WHERE B1_COD  NOT like  'AO%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'AP%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'GF%' "
			_oSQL:_sQuery +=   " AND   B1_COD  NOT like  'MO%' "
			//_oSQL:_sQuery +=   " Where B1_COD NOT IN ('AO-011303','AP-091401','AP-091403')"
			_oSQL:_sQuery +=  " GROUP BY B1_CODLIN, B1_GRUPO, B1_COD, B1_DESC, B1_TIPO, B1_CUSTD, B9_DATA"
		endif
		_oSQL:_sQuery +=  " ORDER BY B1_CODLIN, B1_COD, B2_FILIAL,B9_DATA "
		
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.T.)
		(_sAliasQ) -> (dbgotop ())
		
		do while ! (_sAliasQ) -> (eof ())	
			// Grava o custo atual
			if ! _trb -> (dbseek ((_sAliasQ) -> b1_codlin + (_sAliasQ) -> b1_cod + (_sAliasQ) -> b2_filial + (_sAliasQ) -> b2_local, .F.))
				reclock ("_trb", .T.)
				_trb -> Linha     = (_sAliasQ) -> b1_codlin
				_trb -> Grupo     = (_sAliasQ) -> b1_grupo
				_trb -> Produto   = (_sAliasQ) -> b1_cod
				_trb -> Tipo      = (_sAliasQ) -> b1_tipo
				_trb -> Descricao = (_sAliasQ) -> b1_desc
				_trb -> Stand_Atu = (_sAliasQ) -> b1_custd
				_trb -> filial    = (_sAliasQ) -> b2_filial
				_trb -> almox     = (_sAliasQ) -> b2_local
				_trb -> Medio_Atu = (_sAliasQ) -> b2_vfim1 / (_sAliasQ) -> b2_qfim
				
			else
				reclock ("_trb", .F.)
			endif

			// Se tem dados no SB9, atualiza no respectivo periodo.
			if ! empty ((_sAliasQ) -> b9_data)
				// Determina em qual periodo esta data deve ser considerada.
				_nPeriodo = ascan (_aPeriodos, {|_aVal| _aVal [1] <= (_sAliasQ) -> b9_data .and. _aVal [2] >= (_sAliasQ) -> b9_data})
				
				if _nPeriodo > 0 // Nao pode estar fora do periodo solicitado
					if mv_par15 == 1  // medio		
						_trb -> &(_aPeriodos [_nPeriodo, 3]) = (_sAliasQ) -> b9_vini1 / (_sAliasQ) -> b9_qini
					elseif mv_par15 == 2  // standard
						_trb -> &(_aPeriodos [_nPeriodo, 3]) = (_sAliasQ) -> b9_custd
					endif
				endif
			endif

			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
	
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ('_trb')
	endif

	// Elimina linhas com valores zerados.
	if mv_par10 == 1
		_trb -> (dbgotop ())
		do while ! _trb -> (eof ())
			_lTemValor = .F.
			for _nPeriodo = 1 to len (_aPeriodos)
				if _trb -> &(_aPeriodos [_nPeriodo, 3]) != 0 .or. _trb -> medio_atu != 0
					_lTemValor = .T.
					exit
				endif
			next
			if ! _lTemValor
				reclock ("_trb", .F.)
				_trb -> (dbdelete ())
				msunlock ()
			endif
			_trb -> (dbskip ())
		enddo
	endif
	u_logtrb ('_trb', .f.)

	// Estando com os dados prontos, vamos para a impressao / exportacao para planilha.
	if mv_par16 == 1  // relatorio

		// Ajusta cabecalho do relatorio cfe. parametros.
		if _lContinua
			cCabec1  := "Tipo Produto        Descricao                             Fil Ax   "
			cCabec2  := "                                                                  "
			for _nPeriodo = 1 to len (_aPeriodos)
				cCabec1 += "     " + left (MesExtenso (month (_aPeriodos [_nPeriodo, 1])), 3) + "   "
				cCabec2 += "     " + strzero (year (_aPeriodos [_nPeriodo, 1]), 4) + "  "
			next
			cCabec1 += "   medio   standard"
			cCabec2 += "    atual      atual"
		endif
	
		// Impressao. Ordena e quebra conforme parametrizacao.
		if _lContinua
			
			do case
			case aReturn [8] == 1
				_sQuebra = "Linha"
			case aReturn [8] == 2
				_sQuebra = "Grupo"
			endcase
	
			incproc ("Montando relatorio")
			procregua (_trb -> (reccount ()))
			_trb -> (dbsetorder (aReturn [8]))
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
		
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
	
				// Controla quebra cfe. ordenacao do usuario.
				_xQuebra = _trb -> &(_sQuebra)
				do case
					case aReturn [8] == 1
						@ li, 0 psay "Linha: " + _xQuebra + " - " + Tabela ("88", _xQuebra)
						li += 2
					case aReturn [8] == 2
						@ li, 0 psay "Grupo: " + _xQuebra + " - " + fBuscaCpo ("SBM", 1, xfilial ("SBM") + _xQuebra, "BM_DESC")
						li += 2
				endcase
	
				do while ! _trb -> (eof ()) .and. _trb -> &(_sQuebra) == _xQuebra
	
					if li > _nMaxLin
						cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
					endif
		
					// Monta linha para impressao
					_sLinhaImp := ""
					_sLinhaImp += _trb -> Tipo + "  "
					_sLinhaImp += _trb -> Produto + " "
					_sLinhaImp += left (_trb -> Descricao, 38) + " "
					_sLinhaImp += _trb -> Filial + " "
					_sLinhaImp += _trb -> Almox + " "
					for _nPeriodo = 1 to len (_aPeriodos)
						_slinhaImp += transform (_trb -> &(_aPeriodos [_nPeriodo, 3]), "@E 999,999.99") + " "
					next
					_slinhaImp += transform (_trb -> Medio_Atu, "@E 999,999.99") + " "
					_slinhaImp += transform (_trb -> Stand_Atu, "@E 999,999.99")
					
					@ li, 0 psay _sLinhaImp
					li ++
					_trb -> (dbskip ())
				enddo
				@ li, 0 psay __PrtThinLine ()
				li ++
			enddo
		endif
		li += 2
		U_ImpParam (_nMaxLin)
		
		MS_FLUSH ()
	elseif mv_par16 == 2  // planilha
		U_Trb2XLS ("_trb", .T.)
	endif
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                 Help
	aadd (_aRegsPerg, {01, "Mes inicial (MM/AAAA)         ", "C", 7,  0,  "",   "   ", {},                                    "Mes inicial para analise. Informe mes e ano separados por barra. Ex.: 11/2007"})
	aadd (_aRegsPerg, {02, "Mes final (MM/AAAA)           ", "C", 7,  0,  "",   "   ", {},                                    "Mes final para analise. Informe mes e ano separados por barra. Ex.: 12/2007"})
	aadd (_aRegsPerg, {03, "Tipo produtos de              ", "C", 2,  0,  "",   "02 ", {},                                    "Tipo de produtos inicial a ser considerado"})
	aadd (_aRegsPerg, {04, "Tipo produtos ate             ", "C", 2,  0,  "",   "02 ", {},                                    "Tipo de produtos final a ser considerado"})
	aadd (_aRegsPerg, {05, "Produto de                    ", "C", 15, 0,  "",   "SB1", {},                                    "Produto inicial a ser considerado"})
	aadd (_aRegsPerg, {06, "Produto ate                   ", "C", 15, 0,  "",   "SB1", {},                                    "Produto final a ser considerado"})
	aadd (_aRegsPerg, {07, "Produtos especif.(sep.barras) ", "C", 60, 0,  "",   "   ", {},                                    ""})
	aadd (_aRegsPerg, {08, "Grupo de                      ", "C", 4,  0,  "",   "SBM", {},                                    "Grupo de produto inicial a ser considerado"})
	aadd (_aRegsPerg, {09, "Grupo ate                     ", "C", 4,  0,  "",   "SBM", {},                                    "Grupo de produto final a ser considerado"})
	aadd (_aRegsPerg, {10, "Ignorar almox.zerados         ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                        ""})
	aadd (_aRegsPerg, {11, "Linha produtos de             ", "C", 4,  0,  "",   "88 ", {},                                    "Linha de produtos inicial a ser considerada"})
	aadd (_aRegsPerg, {12, "Linha produtos ate            ", "C", 4,  0,  "",   "88 ", {},                                    "Linha de produtos final a ser considerada"})
	aadd (_aRegsPerg, {13, "Almoxarifado de               ", "C", 2,  0,  "",   "AL ", {},                                    "Almoxarifado (local) inicial a ser considerado"})
	aadd (_aRegsPerg, {14, "Almoxarifado ate              ", "C", 2,  0,  "",   "AL ", {},                                    "Almoxarifado (local) final a ser considerado"})
	aadd (_aRegsPerg, {15, "Qual custo?                   ", "N", 1,  0,  "",   "   ", {"Medio", "Standard"},                 ""})
	aadd (_aRegsPerg, {16, "Destino                       ", "N", 1,  0,  "",   "   ", {"Relatorio", "Planilha"},             ""})
	aadd (_aRegsPerg, {17, "Agrupar por                   ", "N", 1,  0,  "",   "   ", {"Filial+almox", "Filial", "Empresa"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
