// Programa...: VA_XLS37
// Autor......: Robert Koch
// Data.......: 05/11/2018
// Descricao..: Exporta planilha com resumo do kardex.
//
// Historico de alteracoes:
// 07/11/2018 - Robert - validacoes iniciais na filial 01, periodos entre 31/12/2016 e 31/08/18
// 25/11/2022 - Robert - Adequacao para passar parametro de inidices para _oSQL:Copy2Trb()
//

// --------------------------------------------------------------------------
User Function VA_XLS37 (_lAutomat)
	Local cCadastro := "Exporta planilha com resumo do kardex (quantidades nos meses em colunas)"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS37"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"A intencao desta planilha eh fornecer um meio de conferir se o saldo")
		AADD(aSays,"esta sendo composto corretamente ao longo do tempo.")
		AADD(aSays,"Pode-se compor o saldo via formulas na planilha e comparar com a coluna final.")
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _dDataIni  := ctod ('')
	local _dDataFim  := ctod ('')
	local _nMes		 := 0
	local _nPer		 := 0

	if _lContinua .and. empty (mv_par01)
		u_help ("Deve ser informada uma data (inicial) valida de fechamento de estoque")
		_lContinua = .F.
	endif
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB9") + " SB9"
		_oSQL:_sQuery += " WHERE SB9.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SB9.B9_FILIAL   = '" + xfilial ("SB9") + "'"
		_oSQL:_sQuery +=   " AND SB9.B9_DATA     = '" + dtos (mv_par01) + "'"
		if _oSQL:RetQry () == 0
			u_help ("Nao foi encontrado nenhum fechamento de estoque na data (inicial) informada.")
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. mv_par02 <= 0
		u_help ("Deve ser gerado pelo menos 1 mes.")
		_lContinua = .F.
	endif

	// Calcula meses envolvidos e gera arq. trabalho.
	if _lContinua
		_oDUtil := ClsDUtil ():New ()
		_sAnoMes = left (dtos (mv_par01 + 1), 6)
		_aPer := {}
		for _nMes = 1 to mv_par02
			aadd (_aPer, {stod (_sAnoMes + '01'), lastday (stod (_sAnoMes + '01'))})
			_sAnoMes = _oDUtil:SomaMes (_sAnoMes, 1)
		next
		_dDataIni = _aPer [1, 1]
		_dDataFim = _aPer [len (_aPer), 2]
	endif

	// Cria arquivo de trabalho, ja com produtos e saldos iniciais.
	if _lContinua
		procregua (len (_aPer) + 1)
		incproc ("Buscando saldos iniciais")
		
		// Selecao de produtos (a ser usada em mais de um local)
		_sWhereSB1 := " WHERE SB1.D_E_L_E_T_ = ''"
		_sWhereSB1 += " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
		_sWhereSB1 += " AND B1_COD BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'" 
		_sWhereSB1 += " AND B1_TIPO NOT IN " + FormatIn (alltrim (mv_par05), '/')

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT B1_TIPO AS TIPO, B1_COD AS PRODUTO, RTRIM (B1_DESC) AS DESCRICAO "
		if mv_par06 == 1
			_oSQL:_sQuery +=   " ,B1_UM AS UN_MED"
		else
			_oSQL:_sQuery +=   " ,'" + GetMv('MV_SIMB1') + "' AS UN_MED"
		endif
		_oSQL:_sQuery +=       " ,ISNULL (ROUND(SUM(B9INICIAL), 4), 0) AS " + iif (mv_par06 == 1, "QT", "VL") + "_INICIAL"
		
		// Gera colunas para os meses
		for _nPer = 1 to len (_aPer)
			_sAnoMes = left (dtos (_aPer [_nPer, 1]), 6)
			_oSQL:_sQuery +=    " ,0 AS ENT_" + _sAnoMes
			_oSQL:_sQuery +=    " ,0 AS SAI_" + _sAnoMes
			_oSQL:_sQuery +=    " ,0 AS SLD_" + _sAnoMes
		next
		_oSQL:_sQuery +=    " ,0 AS SB9_FINAL"
		
		_oSQL:_sQuery +=    " FROM " + RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += " LEFT JOIN (SELECT B9_COD, SUM(" + iif (mv_par06 == 1, "B9_QINI", "B9_VINI1") + ") AS B9INICIAL"
		_oSQL:_sQuery +=              " FROM " + RetSQLName ("SB9") + " SB9"
		_oSQL:_sQuery +=             " WHERE SB9.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=               " AND (SB9.B9_QINI != 0 OR SB9.B9_VINI1 != 0)"
		_oSQL:_sQuery +=               " AND SB9.B9_FILIAL = '" + xfilial ("SB9") + "'"
		_oSQL:_sQuery +=               " AND SB9.B9_DATA = '" + dtos (mv_par01) + "'"
		_oSQL:_sQuery +=             " GROUP BY B9_COD) AS B9"
		_oSQL:_sQuery +=                " ON (B9.B9_COD = SB1.B1_COD)"
		_oSQL:_sQuery += _sWhereSB1
		_oSQL:_sQuery += " group by B1_TIPO, B1_COD, B1_DESC, B1_UM"
		_oSQL:_sQuery += " order by B1_DESC"
		_oSQL:Log ()
		_oSQL:Copy2Trb (.F., 4,, {'produto'})
		u_log ('estrutura do _trb:', _trb -> (dbstruct ()))
//		Index on produto to &(criatrab ({}, .F.))
		//u_logtrb ('_trb', .T.)
	endif

	// Busca entradas e saidas de cada periodo.
	if _lContinua
		for _nPer = 1 to len (_aPer)
			incproc ("Buscando movtos. periodo " + cvaltochar (_nPer) + " de " + cvaltochar (len (_aPer)))

			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT B1_COD"
			_oSQL:_sQuery +=        " ,ISNULL(ROUND(SUM(D1.ENT_SD1), 4), 0) AS ENT_SD1"
			_oSQL:_sQuery +=        " ,ISNULL(ROUND(SUM(D2.SAI_SD2), 4), 0) AS SAI_SD2"
			_oSQL:_sQuery +=        " ,ISNULL(ROUND(SUM(D3.ENT_SD3), 4), 0) AS ENT_SD3"
			_oSQL:_sQuery +=        " ,ISNULL(ROUND(SUM(D3.SAI_SD3), 4), 0) AS SAI_SD3"
			_oSQL:_sQuery +=    " FROM " + RetSQLName ("SB1") + " SB1"
			_oSQL:_sQuery += " LEFT JOIN (SELECT D1_COD, SUM(" + iif (mv_par06 == 1, "D1_QUANT", "D1_CUSTO") + ") AS ENT_SD1"
			_oSQL:_sQuery +=              " FROM " + RetSQLName ("SD1") + " SD1,"
			_oSQL:_sQuery +=                         RetSQLName ("SF4") + " SF4"
			_oSQL:_sQuery +=             " WHERE SD1.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=               " AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
			_oSQL:_sQuery +=               " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (_aPer [_nPer, 1]) + "' AND '" + dtos (_aPer [_nPer, 2]) + "'"
			_oSQL:_sQuery +=               " AND SF4.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=               " AND SF4.F4_FILIAL   = '" + xfilial ("SF4") + "'"
			_oSQL:_sQuery +=               " AND SF4.F4_CODIGO   = SD1.D1_TES"
			_oSQL:_sQuery +=               " AND SF4.F4_ESTOQUE  = 'S'"
			_oSQL:_sQuery +=             " GROUP BY D1_COD) AS D1"
			_oSQL:_sQuery +=                " ON (D1.D1_COD = SB1.B1_COD)"
			_oSQL:_sQuery += " LEFT JOIN (SELECT D2_COD, SUM (" + iif (mv_par06 == 1, "D2_QUANT", "D2_CUSTO1") + ") AS SAI_SD2"
			_oSQL:_sQuery +=               " FROM " + RetSQLName ("SD2") + " SD2, "
			_oSQL:_sQuery +=                          RetSQLName ("SF4") + " SF4"
			_oSQL:_sQuery +=              " WHERE SD2.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=                " AND SD2.D2_FILIAL = '" + xfilial ("SD2") + "'"
			_oSQL:_sQuery +=                " AND SD2.D2_EMISSAO BETWEEN '" + dtos (_aPer [_nPer, 1]) + "' AND '" + dtos (_aPer [_nPer, 2]) + "'"
			_oSQL:_sQuery +=                " AND SF4.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=                " AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
			_oSQL:_sQuery +=                " AND SF4.F4_CODIGO = SD2.D2_TES"
			_oSQL:_sQuery +=                " AND SF4.F4_ESTOQUE = 'S'"
			_oSQL:_sQuery +=              " GROUP BY D2_COD) AS D2"
			_oSQL:_sQuery +=                 " ON (D2.D2_COD = SB1.B1_COD)"
			_oSQL:_sQuery += "  LEFT JOIN (SELECT D3_COD"
			_oSQL:_sQuery +=                    " ,SUM(CASE WHEN SD3.D3_TM <  '5' THEN SD3." + iif (mv_par06 == 1, "D3_QUANT", "D3_CUSTO1") + " ELSE 0 END) AS ENT_SD3"
			_oSQL:_sQuery +=                    " ,SUM(CASE WHEN SD3.D3_TM >= '5' THEN SD3." + iif (mv_par06 == 1, "D3_QUANT", "D3_CUSTO1") + " ELSE 0 END) AS SAI_SD3"
			_oSQL:_sQuery +=               " FROM " + RetSQLName ("SD3") + " SD3"
			_oSQL:_sQuery +=              " WHERE SD3.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=                " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=                " AND SD3.D3_ESTORNO != 'S'"
			// NAO DESCONSIDERA POR QUE ASSIM PEGA TRANSFORMACOES _oSQL:_sQuery +=                " AND SD3.D3_CF NOT IN ('RE4', 'DE4')"  // DESCONSIDERA TRANSFERENCIAS ENTRE ENDERECOS.
			_oSQL:_sQuery +=                " AND SD3.D3_EMISSAO BETWEEN '" + dtos (_aPer [_nPer, 1]) + "' AND '" + dtos (_aPer [_nPer, 2]) + "'"
			_oSQL:_sQuery +=                " AND not (SD3.D3_EMISSAO = '20171117' and D3_FILIAL = '01' AND D3_COD = '0040' AND D3_NUMSEQ = 'ADAGY5' AND D3_LOCAL = '25')"  // TRANSF INCONSISTENTE POR QUE O SISTEMA ESTAVA COM SALDO ERRADO NAQUELA DATA.
			_oSQL:_sQuery +=                " AND not (SD3.D3_EMISSAO = '20180201' and D3_FILIAL = '01' AND D3_COD = '4007' AND D3_NUMSEQ = 'x019LL' AND D3_LOCAL = '07' AND D3_CF = 'DE4')"  // SISTEMA NAO CONSIDEROU TRANSFERENCIA AO GRAVAR SB9 EM 20180231
			_oSQL:_sQuery +=                " AND not (SD3.D3_EMISSAO = '20180201' and D3_FILIAL = '01' AND D3_COD = '3047' AND D3_NUMSEQ = 'x019LK' AND D3_LOCAL = '07' AND D3_CF = 'DE4')"  // SISTEMA NAO CONSIDEROU TRANSFERENCIA AO GRAVAR SB9 EM 20180231
			_oSQL:_sQuery +=              " GROUP BY D3_COD) AS D3"
			_oSQL:_sQuery +=                 " ON (D3.D3_COD = SB1.B1_COD)"
			_oSQL:_sQuery += _sWhereSB1
			_oSQL:_sQuery += " GROUP BY B1_COD"
			_oSQL:Log ()
			_sAliasQ := _oSQL:Qry2Trb (.F.)
			do while ! (_sAliasQ) -> (eof ())
				if _trb -> (dbseek ((_sAliasQ) -> b1_cod, .F.))
					_sAnoMes = left (dtos (_aPer [_nPer, 1]), 6)
					reclock ("_trb", .F.)
					_trb -> &('Ent_' + _sAnoMes) = (_sAliasQ) -> ENT_SD1 + (_sAliasQ) -> ENT_SD3
					_trb -> &('Sai_' + _sAnoMes) = (_sAliasQ) -> SAI_SD2 + (_sAliasQ) -> SAI_SD3
					
					// Sistema desconsiderou desmontagem D3_NUMSEQ=x00XRS e gravou SB9 negativo para ax.90
					if cFilAnt == '01' .and. alltrim (_trb -> produto) == '4014' .and. _sAnoMes == '201801'
						_trb -> &('Ent_' + _sAnoMes) -= 35
					endif
					msunlock ()
				else
					u_help ("Produto " + (_sAliasQ) -> b1_cod + " nao encontrado no ar. de trabalho")
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
		next
		//u_logtrb ('_trb', .T.)
	endif

	// Limpa linhas zeradas
	if _lContinua
		_trb -> (dbgotop ())
		do while ! _trb -> (eof ())
			_nTotEnt = 0
			_nTotSai = 0
			for _nPer = 1 to len (_aPer)
				_sAnoMes = left (dtos (_aPer [_nPer, 1]), 6)
				_nTotEnt += _trb -> &('Ent_' + _sAnoMes)
				_nTotSai += _trb -> &('Sai_' + _sAnoMes)
			next
			reclock ("_trb", .F.)
			if _trb -> &(iif (mv_par06 == 1, "QT", "VL") + "_inicial") == 0 .and. _nTotEnt == 0 .and. _nTotSai == 0
				_trb -> (dbdelete ())
			endif
			msunlock ()
			_trb -> (dbskip ())
		enddo
		//u_logtrb ('_trb', .T.)
	endif



	// confere com SB9 na ultima coluna, para ajudar na conferencia.
	if _lContinua
		_trb -> (dbgotop ())
		do while ! _trb -> (eof ())
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SUM (" + iif (mv_par06 == 1, "B9_QINI", "B9_VINI1") + ")"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB9") + " SB9"
			_oSQL:_sQuery +=  " WHERE SB9.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SB9.B9_FILIAL  = '" + xfilial ("SB9") + "'"
			_oSQL:_sQuery +=    " AND SB9.B9_COD     = '" + _trb -> produto + "'"
			_oSQL:_sQuery +=    " AND SB9.B9_DATA    = '" + dtos (_aPer [len (_aPer), 2]) + "'"
			_nRetSB9 = _oSQL:RetQry ()
			reclock ("_trb", .F.)
			_trb -> SB9_FINAL = _nRetSB9
			msunlock ()
			_trb -> (dbskip ())
		enddo
	endif

	// Exportacao para planilha
	if _lContinua
		U_TRB2XLS ('_trb', .F., .T.)
		_trb -> (dbclosearea ())
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                 Ordem Descri                          tipo tam dec valid F3     opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Data inicial(p/saldo inicial) ", "D", 8,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {02, "Qt.meses                      ", "N", 2,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {}, ""})
	aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1", {}, ""})
	aadd (_aRegsPerg, {05, "Tipos a ignorar (sep.barras)  ", "C", 60, 0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {06, "Listar quantidade ou custo?   ", "N", 1,  0,  "",   "",    {"Quantidade", "Custo"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
