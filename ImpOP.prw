// Programa:   ImpOP
// Autor:      Robert Koch
// Data:       19/11/2014
// Descricao:  Impressao da OP em formato grafico.
//
// Historico de alteracoes:
// 10/02/2015 - Robert - Incluidas datas de fabricacao e de validade.
// 27/03/2015 - Robert - Passa a imprimir componentes tipo MO e BN.
// 14/08/2015 - Robert - Tratamentos impressao OP de retrabalho.
// 22/09/2015 - Robert - Impressao de estrutura (OP de reprocesso) desconsiderava data de inicio e fim da validade.
// 03/10/2015 - Robert - Imprime lote original (campo C2_VALTORI) quando OP de reprocesso.
// 07/10/2015 - Robert - Ajustes cabecalho, que estava sobrepondo codigo de barras.
//                     - Imprime observacoes em fonte maior, com possibilidade de quebra de linha.
//                     - Aumentada fonte da descricao do produto e da quantidade.
// 18/07/2016 - Robert - Incluidos dados de palletizacao (lastro X camadas) e codigo EAN do produto.
// 21/10/2016 - Robert - Leitura dos itens fantasmas da estrutura nao considerava data de inicio/fim de validade.
//                     - Passa a validar G1_TRT com C2_REVISAO.
// 01/11/2016 - Robert - Ajustado para validar G1_REVINI e G1_REVFIM com C2_REVISAO, e nao mais G1_TRT
// 23/11/2016 - Robert - Imprime OP mae e componente VD + revisao, quando houver.
// 28/11/2016 - Robert - Imprime lote e endereco componentes, quebra descricao componente.
//                     - Imprime espaco para informar tanques destino no cabecalho.
// 14/12/2016 - Robert - Imprime lote cfe. endereco sugerido no SD4; criado espaco para anotar endereco/lote efetivos.
// 05/04/2017 - Robert - Nao validava o campo C2_ROTEIRO na leitura do SG2.
// 17/08/2017 - Robert - OP de reprocesso assume dt valid do lote original (C2_VADVORI), cfe informada pelo usuario - GLPI 2981
// 25/08/2017 - Robert - Passa a imprimir a data de fabricacao = validade = C2_DATPRF+B1_PRVALID.
// 22/02/2018 - Robert - Reducao largura descricao e aumento lote dos componentes.
//                     - Tratamento para N linhas de descricao dos componentes
// 15/07/2019 - Andre  - Adicionado tabela com perdas de produção. SX5 tabela 43.
// 29/07/2019 - Andre  - Campo B1_VAEANUN substituido pelo campo B5_2CODBAR.
// 16/08/2019 - Robert - Campo B1_VADUNCX substituido pelo campo B1_CODBAR.
// 02/12/2021 - Robert - Acrescentados logs para depuracao de empenhos.
//

// para pensar: ler saldo empenho do SDC ?

// --------------------------------------------------------------------------
user function ImpOP (_sOPIni, _sOPFim)
	private cPerg := "ImpOP"

	_ValidPerg ()
	pergunte (cPerg, .F.)

	// Caso seja passado o numero da OP na chamada, preenche as perguntas
	If _sOPIni != NIL .and. _sOPFim != NIL
		mv_par01 = _sOPIni
		mv_par02 = _sOPFim
		mv_par03 = ctod ('')
		mv_par04 = stod ('20491231')
		processa ({|| _AndaLogo ()})
	else
		if pergunte (cPerg, .T.)
			processa ({|| _AndaLogo ()})
		endif
	endif

Return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local   _oSQL      := NIL
	//local   _nCompAux  := 0
	local   _aCompon   :={}  // Array com os componentes da OP
	local   _nCompon   := 0
	local   _aFant     := {}
	local   _nFant     := 0
	local   _sLinImp   := ""
	local   _aOper     := {} 
	local   _nOper     := 0
	local   _nMotPer   := 0  
	local   _aRetQry   := {}
	local   _sDescComp := ""
	local   _nTamDescC := 25
	local   _lPrimeira := .F.
	private _nViaAtual := 0  // Contador de vias (determinadas oper. sao impressas em vias separadas)
	private _nPagAtual := 0  // Contador de paginas da via atual
	private _nMargSup  := 90  // Margem superior da pagina
	private _nMargEsq  := 50   // Margem esquerda da pagina
	private _nAltPag   := 3100  // Altura maxima da pagina
	private _nLargPag  := 2400  // Largura maxima da pagina
	private _nAltLin   := 50  // Altura de cada linha em pontos (para trabalhar de forma semelhante a impressao caracter)
	private li         := 0
	private _sOP       := ""
	private limite     := 132
	private _sOPMae    := ""
	private _sProdMae  := ""

	// Objetos para tamanho e tipo das fontes
	private _oCour8N  := TFont():New("Courier New",,8,,.T.,,,,,.F.)  // Aproximadamente 132 caracteres por linha
	private _oCour12N := TFont():New("Courier New",,12,,.T.,,,,,.F.) 

	_oPrn:=TAVPrinter():New("OP")
	_oPrn:Setup()           // Tela para usuario selecionar a impressora
	_oPrn:SetPortrait()     // ou SetLanscape()

	procregua (val (mv_par02) - val (mv_par01))
	sc2 -> (dbsetorder (1))
	sc2 -> (dbseek (xfilial ("SC2") + mv_par01, .T.))
	do while ! sc2 -> (eof ()) ;
			.and. sc2 -> c2_filial == xfilial ("SC2") ;
			.and. sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd <= mv_par02
	
		incproc ()
	
		if sc2 -> c2_datprf < mv_par03 .or. sc2 -> c2_datprf > mv_par04 //.or. (! empty (sc2 -> c2_DatRF) .and. mv_par05 == 2)
			sc2 -> (dbSkip ())
			Loop
		Endif
	
		_sOP = sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd
		
		dbSelectArea("SB1")
		dbsetorder (1)
		if ! sb1 -> (dbSeek (xfilial ("SB1") + sc2 -> c2_produto))
			u_help ("Produto da OP '" + _sOP + "' nao cadastrado!")
			return
		endif

		// Verifica se existe OP mae.
		_sOPMae   = ""
		_sProdMae = ""
		if sc2 -> c2_sequen > '001'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT TOP 1 D4_OP, ISNULL (C2_PRODUTO, '')"
			_oSQL:_sQuery +=   " FROM  " + RetSQLName ("SD4") + " SD4 "
			_oSQL:_sQuery +=   " LEFT JOIN " + RetSQLName ("SC2") + " SC2 "
			_oSQL:_sQuery +=        " ON (SC2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=       " AND SC2.C2_FILIAL   = '" + xfilial ("SC2") + "'"
			_oSQL:_sQuery +=       " AND SC2.C2_NUM      = SUBSTRING (SD4.D4_OP, 1, 6)"
			_oSQL:_sQuery +=       " AND SC2.C2_ITEM     = SUBSTRING (SD4.D4_OP, 7, 2)"
			_oSQL:_sQuery +=       " AND SC2.C2_SEQUEN   = SUBSTRING (SD4.D4_OP, 9, 3)"
			_oSQL:_sQuery +=       " AND SC2.C2_ITEMGRD  = SUBSTRING (SD4.D4_OP, 12, 2))"
			_oSQL:_sQuery +=  " WHERE SD4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
			_oSQL:_sQuery +=    " AND SD4.D4_OP   LIKE '" + left (_sOP, 8) + "%'"
			_oSQL:_sQuery +=    " AND SD4.D4_OPORIG  = '" + _sOP + "'"
			_oSQL:Log ()
			_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
			if len (_aRetQry) > 0
				_sOPMae = _aRetQry [1, 1]
				if ! empty (_sOPMae)
					_sProdMae = _aRetQry [1, 2]
				endif
			endif
		endif
		
		// OP de retrabalho nao deve ter empenhos. Serao listados os componentes
		// da estrutura apenas para orientar o operador sobre quais itens ele deve revisar.
		if sc2 -> c2_vaOpEsp == "R"
			U_Log2 ('info', 'OP de retrabalho nao costuma ter empenhos. Serao listados os componentes da estrutura apenas para orientar o operador sobre quais itens ele deve revisar.')
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT B1_COD, '(Revisao) ' + B1_DESC,"
			_oSQL:_sQuery +=        " CASE SB1.B1_QB WHEN 0 THEN 1 ELSE SB1.B1_QB END * G1_QUANT * " + cvaltochar (sc2 -> c2_quant) + ","
			_oSQL:_sQuery +=        " B1_UM, '  ' AS ALMOX, '          ' as LOTE, '               ' as D4_VAEND"
			_oSQL:_sQuery +=   " FROM  " + RetSQLName ("SG1") + " SG1, "
			_oSQL:_sQuery +=               RetSQLName ("SB1") + " SB1 "
			_oSQL:_sQuery +=  " WHERE SG1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SG1.G1_FILIAL  = '" + xfilial ("SG1") + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_COD     = '" + SC2 -> C2_PRODUTO + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_TRT     = '" + SC2 -> C2_revisao + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_INI    <= '" + dtos (sc2 -> c2_emissao) + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_FIM    >= '" + dtos (sc2 -> c2_emissao) + "'"
			_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=    " AND SB1.B1_COD     = SG1.G1_COMP"
			_oSQL:_sQuery +=    " AND SB1.B1_TIPO    NOT IN ('MO', 'BN')"
			_oSQL:_sQuery +=  " ORDER BY G1_COMP"
			_oSQL:Log ()
			_aFant := aclone (_oSQL:Qry2Array ())
			for _nFant = 1 to len (_aFant)
				if ascan (_aCompon, {| _aVal | _aVal [1] == _aFant [_nFant, 1]}) == 0
					aadd (_aCompon, aclone (_aFant [_nFant]))
				endif
			next
		else
			// Monta lista de componentes a partir dos empenhos.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT D4_COD, B1_DESC, D4_QTDEORI, B1_UM, D4_LOCAL, "
			_oSQL:_sQuery +=        " (SELECT TOP 1 ISNULL (BF_LOTECTL, '')"
			_oSQL:_sQuery +=           " FROM  " + RetSQLName ("SBF") + " SBF "
			_oSQL:_sQuery +=          " WHERE SBF.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=            " AND SBF.BF_FILIAL  = '" + xfilial ("SBF") + "'"
			_oSQL:_sQuery +=            " AND SBF.BF_LOCAL   = SD4.D4_LOCAL"
			_oSQL:_sQuery +=            " AND SBF.BF_LOCALIZ = SD4.D4_VAEND"
			_oSQL:_sQuery +=            " AND SBF.BF_PRODUTO = SD4.D4_COD) AS LOTE,"
			_oSQL:_sQuery +=        " D4_VAEND"
			_oSQL:_sQuery +=   " FROM  " + RetSQLName ("SD4") + " SD4, "
			_oSQL:_sQuery +=               RetSQLName ("SB1") + " SB1 "
			_oSQL:_sQuery +=  " WHERE SD4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
			_oSQL:_sQuery +=    " AND SD4.D4_OP      = '" + _sOP + "'"
			_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=    " AND SB1.B1_COD     = SD4.D4_COD"
			_oSQL:_sQuery +=  " ORDER BY D4_COD"
			_aCompon := aclone (_oSQL:Qry2Array ())
			
			// Adiciona produtos fantasmas da estrutura `a lista de componentes.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT B1_COD, '(Fantasma) ' + B1_DESC,"
			_oSQL:_sQuery +=        " CASE SB1.B1_QB WHEN 0 THEN 1 ELSE SB1.B1_QB END * G1_QUANT * " + cvaltochar (sc2 -> c2_quant) + ","
			_oSQL:_sQuery +=        " B1_UM, '  ' AS ALMOX, '          ' as LOTE, '               ' as D4_VAEND"
			_oSQL:_sQuery +=   " FROM  " + RetSQLName ("SG1") + " SG1, "
			_oSQL:_sQuery +=               RetSQLName ("SB1") + " SB1 "
			_oSQL:_sQuery +=  " WHERE SG1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SG1.G1_FILIAL  = '" + xfilial ("SG1") + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_COD     = '" + SC2 -> C2_PRODUTO + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_REVINI <= '" + sc2 -> c2_revisao + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_REVFIM >= '" + sc2 -> c2_revisao + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_INI    <= '" + dtos (sc2 -> c2_emissao) + "'"
			_oSQL:_sQuery +=    " AND SG1.G1_FIM    >= '" + dtos (sc2 -> c2_emissao) + "'"
			_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=    " AND SB1.B1_COD     = SG1.G1_COMP"
			_oSQL:_sQuery +=    " AND SB1.B1_FANTASM = 'S'"
			_oSQL:_sQuery +=    " AND SB1.B1_TIPO    NOT IN ('MO', 'BN')"
			_oSQL:_sQuery +=  " ORDER BY G1_COMP"
			_oSQL:Log ()
			_aFant := aclone (_oSQL:Qry2Array ())
			for _nFant = 1 to len (_aFant)
				if ascan (_aCompon, {| _aVal | _aVal [1] == _aFant [_nFant, 1]}) == 0
					aadd (_aCompon, aclone (_aFant [_nFant]))
				endif
			next
		endif

		// Imprime cabecalho da OP
		_nPagAtual = 1
		_Cabec ()
		
		// Imprime componentes da OP
		For _nCompon = 1 to len (_aCompon)
			if _nCompon == 1
				_CabecComp ()
			endif
			if Li > _nAltPag
				li = 0
				_nPagAtual ++
				_Cabec ()
				_CabecComp ()
			endif
/*
			_sDescComp = alltrim (_aCompon [_nCompon, 2]) + " com mais coisa emendada so pra ver como fica a quebra de texto"
			_sLinImp := ""
			//_sLinImp += U_TamFixo (alltrim (_aCompon [_nCompon, 1]) + ' ' + alltrim (_aCompon [_nCompon, 2]), 74)
			_sLinImp += '|' + U_TamFixo (alltrim (_aCompon [_nCompon, 1]), 9)  // Por enquanto nao temos codigo maior que isso...
			_sLinImp += '|' + U_TamFixo (_sDescComp, _nTamDescC)  // cod+descr
			_sLinImp += '|' + transform (_aCompon [_nCompon, 3], "@E 99,999,999.9999")  // quant
			_sLinImp += '|' + _aCompon [_nCompon, 4]  // unid.medida
			_sLinImp += '|' + _aCompon [_nCompon, 5] + ' '  // almox
			_sLinImp += '|' + _aCompon [_nCompon, 7]  // endereco
			_sLinImp += '|               '  // endereco real
//			_sLinImp += '|' + _aCompon [_nCompon, 6]  // lote
			_sLinImp += '|' + _aCompon [_nCompon, 6] + space (10)  // lote
			_sLinImp += '|          '  //qt real
			_sLinImp += '|        '  //qt perda
			_sLinImp += '|'
			_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
			
			// Continua a descricao nas linhas abaixo, caso necessario.
			//if len (alltrim (_aCompon [_nCompon, 2])) > _nTamDescC
			do while ! empty (_sDescComp)
				u_log ('ini >>' + _sDescComp + '<<')
				_sLinImp := '|         |' 
				_sLinImp += U_TamFixo (substr (_sDescComp, _nTamDescC + 1), _nTamDescC)
//				_sLinImp += '|               |  |   |               |               |          |          |        |'  // completa pipes de endereco, lote, quantidades, etc.
				_sLinImp += '|               |  |   |               |               |                    |          |        |'  // completa pipes de endereco, lote, quantidades, etc.
				u_log (_sLinImp)
				li += int (_nAltLin * .5)
				_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
				
				// Remove da variavel a parte jah impressa da descricao.
				_sDescComp = substr (_sDescComp, _nTamDescC)
				
				u_log ('fim >>' + _sDescComp + '<<')
				u_log ('')
			enddo
*/

			_sDescComp = alltrim (_aCompon [_nCompon, 2])
			_lPrimeira = .T.
			// Continua a descricao nas linhas abaixo, caso necessario.
			do while ! empty (_sDescComp)
				_sLinImp := ""
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, _aCompon [_nCompon, 1], ''), 9)  // Por enquanto nao temos codigo maior que isso...
				_sLinImp += '|' + U_TamFixo (_sDescComp, _nTamDescC)  // cod+descr
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, transform (_aCompon [_nCompon, 3], "@E 99,999,999.9999"), ''), 15)  // quant
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, _aCompon [_nCompon, 4], ''), 2)  // unid.medida
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, _aCompon [_nCompon, 5], ''), 3)  // almox
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, _aCompon [_nCompon, 7], ''), 15)  // endereco
				_sLinImp += '|               '  // endereco real
				_sLinImp += '|' + U_TamFixo (iif (_lPrimeira, _aCompon [_nCompon, 6], ''), 20)  // lote
				_sLinImp += '|          '  //qt real
				_sLinImp += '|        '  //qt perda
				_sLinImp += '|'
				_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
				li += int (_nAltLin * .5)
				
				// Remove da variavel a parte jah impressa da descricao.
				_sDescComp = substr (_sDescComp, _nTamDescC + 1)
				
				_lPrimeira = .F.
			enddo

//			li += int (_nAltLin * .5)

			if _nCompon < len (_aCompon)
//				_oPrn:Say (_nMargSup + li, _nMargEsq, "|---------|-----------------------------------|---------------|--|---|---------------|---------------|----------|----------|--------|", _oCour8N, 100)
				_oPrn:Say (_nMargSup + li, _nMargEsq, "|---------|-------------------------|---------------|--|---|---------------|---------------|--------------------|----------|--------|", _oCour8N, 100)
				li += _nAltLin * .5
			endif
		
			IF li > _nAltPag
				Li := 0
				_nPagAtual ++
				_Cabec()  // imprime cabecalho da OP
			endif
		Next

		// Fecha a grade de componentes.
		if len (_aCompon) > 0
			_oPrn:Say (_nMargSup + li, _nMargEsq, " -----------------------------------------------------------------------------------------------------------------------------------", _oCour8N, 100)
			li += _nAltLin * .5
		endif
	
		li += _nAltLin

		// Le as operacoes do produto da OP
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT G2_OPERAC, G2_DESCRI"
		_oSQL:_sQuery +=   " FROM  " + RetSQLName ("SG2") + " SG2 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND G2_FILIAL  = '" + xfilial ("SG2") + "'"
		_oSQL:_sQuery +=    " AND G2_PRODUTO = '" + sc2 -> c2_produto + "'"
		_oSQL:_sQuery +=    " AND G2_CODIGO  = '" + sc2 -> c2_roteiro + "'"
		_oSQL:_sQuery +=  " ORDER BY G2_OPERAC"
		_oSQL:Log ()
		_aOper := aclone (_oSQL:Qry2Array ())
		//U_LOG (_aOper)

		// Imprime roteiro de operacoes
		li += _nAltLin
		for _nOper = 1 to len (_aOper)
			if _nOper == 1
				_CabecOper ()
			endif
			if Li > _nAltPag
				li = 0
				_nPagAtual ++
				_Cabec ()
				_CabecOper ()
			endif
			
					
			_oPrn:Say (_nMargSup + li, _nMargEsq, _aOper [_nOper, 1] + " " + _aOper [_nOper, 2])
			li += _nAltLin
		
			// Alocacoes e tempos reais das operacoes
			_oPrn:Say (_nMargSup + li, _nMargEsq, "INI REAL: ____/ ____/ ____ - ____:____    TERM REAL: ____/ ____/ ____ - ____:____", _oCour8N, 100)
			li += _nAltLin
			
			_oPrn:Say (_nMargSup + li, _nMargEsq, replicate ("-", 131), _oCour8N, 100)
			li += _nAltLin
		next
	
		if sc2 -> c2_vaOpEsp == 'R'
			if Li + _nAltLin * 2 > _nAltPag
				li = 0
				_nPagAtual ++
				_Cabec ()
				_CabecOper ()
			endif
			_sLinImp := "Horas de retrabalho: __________   Quant. de pessoas: _________   Setor: _______________________________________________________"
			_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
			li += _nAltLin
			_sLinImp := "Horas de retrabalho: __________   Quant. de pessoas: _________   Setor: _______________________________________________________"
			_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
			li += _nAltLin
		endif
		
		//Imprime grade de motivos de perda
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT X5_CHAVE, X5_DESCRI "
		_oSQL:_sQuery += " FROM  " + RetSQLName ("SX5") + " SX5 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND X5_TABELA = '43' "
		_aMotPer := aclone (_oSQL:Qry2Array ())
//		li += _nAltLin
		for _nMotPer = 1 to len (_aMotPer)
			if _nMotPer == 1
				_CabecPer ()
			endif
			if Li > _nAltPag
				li = 0
				_nPagAtual ++
				_Cabec ()
				_CabecPer ()
			endif
			
			_sMotPer = alltrim (_aMotPer [_nMotPer, 2])
			
		    _oPrn:Say (_nMargSup + li, _nMargEsq,"|  " + _aMotPer [_nMotPer, 1] + "|  " +substr (_aMotPer [_nMotPer, 2],1,47) + "|  LT  " + "|" + "        |")
			li += _nAltLin * .5
			
			_oPrn:Say (_nMargSup + li, _nMargEsq, replicate ("-", 131), _oCour8N, 100)
			li += _nAltLin * .5
		next
		
		_oPrn:EndPage()   // Encerra página
	
		sc2 -> (dbskip ())
	enddo
	_oPrn:Preview()       // Visualiza antes de imprimir
	_oPrn:End()
Return



// --------------------------------------------------------------------------
// Cabecalho da OP
static function _Cabec ()
	local _aObs    := {}
	local _nObs    := 0
	local _sLinImp := ""
	local _sDUN14  := sb1 -> b1_codbar  //b1_vaduncx

	if _nViaAtual > 1 .or. _nPagAtual > 1
		_oPrn:EndPage ()    // Encerra pagina
	endif
	_oPrn:StartPage ()  // Inicia uma nova pagina

	li = 60
	_sLinImp := left (sm0 -> m0_nome, 20)
	if sc2 -> c2_vaOpEsp == 'R'
		_sLinImp += "     O R D E M    D E    R E P R O C E S S O     "
	else
		_sLinImp += "       O R D E M    D E    P R O D U C A O       "
	endif
	_sLinImp += substr (_sOP, 1, 6) + '.' + substr (_sOP, 7, 2) + '.' + substr (_sOP, 9)
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour12N, 100)
	li += _nAltLin
	_oPrn:Say (_nMargSup + li, _nMargEsq, replicate ("-", limite), _oCour8N, 100)
	li += _nAltLin
	_sLinImp := space (125) + "Pag: " + cValToChar (_nPagAtual)
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin //* 2

	// Imprime lote de acordo com o tipo de OP.
	_sLinImp := U_TamFixo ("Produto: " + alltrim (sc2 -> c2_produto), 71)
	_sLinImp += iif (sc2 -> c2_vaOPEsp == 'R', " Lote orig.: " + sc2 -> c2_valtori, " Lote: " + substr (_sOP, 1, 8))
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour12N, 100)

	// Imprime descricao do produto em mais de uma linha.
	_sLinImp := space (22) + substr (sb1 -> b1_desc, 1, 40)
	_oPrn:Say (_nMargSup + li + 5, _nMargEsq, _sLinImp, _oCour12N, 100)
	_sLinImp := space (22) + substr (sb1 -> b1_desc, 41, 40)
	_oPrn:Say (_nMargSup + li + 45, _nMargEsq, _sLinImp, _oCour12N, 100)

//	_sLinImp := space (102) + "Data fabricacao: " + dtoc (date ())
	if sc2 -> c2_vaopesp == 'R'  // OP de reprocesso assume do lote original, cfe informada pelo usuario.
		_sLinImp := space (102) + "Dt.fabric.orig.: " + dtoc (sc2 -> c2_vadflor)
	else
//		_sLinImp := space (102) + "Data fabricacao: " + dtoc (date ())
		_sLinImp := space (102) + "Data fabricacao: " + dtoc (sc2 -> c2_datprf)
	endif

	_oPrn:Say (_nMargSup + li + 30, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin

//	_oPrn:Say (_nMargSup + li + 30, _nMargEsq, _sLinImp, _oCour8N, 100)
	if sc2 -> c2_vaopesp == 'R'  // OP de reprocesso assume do lote original, cfe informada pelo usuario.
		_sLinImp := space (102) + "Dt.valid.orig..: " + dtoc (sc2 -> c2_vadvori)
	else
//		_sLinImp := space (102) + "Data validade..: " + dtoc (date () + sb1 -> b1_prvalid)
//		_sLinImp := space (102) + "Data validade..: " + dtoc (sc2 -> c2_datpri + sb1 -> b1_prvalid)
		_sLinImp := space (102) + "Data validade..: " + dtoc (sc2 -> c2_datprf + sb1 -> b1_prvalid)
	endif
	_oPrn:Say (_nMargSup + li + 30, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin

	if ! empty (_sOPMae) .or. ! empty (sc2 -> c2_vaCodVD)
		if ! empty (_sOPMae)
			_sLinImp := "OP mae: " + _sOPMae + "  produto final: " + alltrim (_sProdMae) + iif (empty (_sProdMae), '', " - " + fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProdMae, "B1_DESC"))
			_oPrn:Say (_nMargSup + li + 30, _nMargEsq, _sLinImp, _oCour8N, 100)
			li += _nAltLin
		endif
	
		if ! empty (sc2 -> c2_vaCodVD)
			_sLinImp := U_TamFixo ("Compon.principal: " + alltrim (sc2 -> c2_vaCodVD) + " (rev.estrut.: " + sc2 -> c2_vaRevVD + ' - ' + alltrim (fBuscaCpo ("SG5", 1, xfilial ("SG5") + sc2 -> c2_vaCodVD + sc2 -> c2_vaRevVD, "G5_OBS")) + ")", limite)
			_oPrn:Say (_nMargSup + li + 30, _nMargEsq, _sLinImp, _oCour8N, 100)
			li += _nAltLin
		endif
		li += _nAltLin
	endif

//	_sLinImp := "Quantidade a produzir:                              Emissao..: " + dtoc (sc2 -> c2_emissao)
	_sLinImp := "Saldo a produzir:                                   Emissao..: " + dtoc (sc2 -> c2_emissao)
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	_sLinImp := space (13) + transform (SC2->C2_QUANT - SC2->C2_QUJE, "@E 999,999,999.99") + " " + sb1 -> b1_um
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour12N, 100)
	li += _nAltLin

	_sLinImp := "                                                    Impressao: " + dtoc (date ()) + " - " + left (time (), 5)
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	if sc2 -> c2_vaOpEsp == 'R'
		_sLinImp := "Quantidade recuperada:"
	else
		_sLinImp := "Quantidade produzida: "
	endif

	if sb1 -> b1_vaPlLas > 0 .and. sb1 -> b1_vaPlCam > 0
		_sLinImp += "                              Pallet: " + cvaltochar (sb1 -> b1_vaPlLas) + " (lastro) X " + cvaltochar (sb1 -> b1_vaPlCam) + " camadas"
	else
		_sLinImp += "                              Pallet: sem dados"
	endif
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin * 2

	if sb1 -> b1_tipo == 'VD'
		_sLinImp := "Tanque(s) destino: ______________ / ______________ / ______________ / ______________"
		_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
		li += _nAltLin * 2
	endif

	_sLinImp := "Ini/fim prev.:" + DTOC(SC2->C2_DATPRI) + " - " + DTOC(SC2->C2_DATPRF)
	_sLinImp += "        Real: ____/____/____ - ____/____/____"
	if ! empty (_sDUN14)
		_sLinImp += "     Cod.barras caixa:        " + _sDUN14
	endif
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)

//	li += _nAltLin * 2
	li += _nAltLin
//	_sLinImp := "                                                                                       Cod.EAN produto: " + sb1 -> b1_vaEANun

	_sLinImp := "                                                                                       Cod.EAN produto: " + POSICIONE("SB5",1,XFILIAL("SB5")+SB1->B1_COD,"B5_2CODBAR")
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	
	if ! empty (sc2 -> c2_obs)
		_aObs = aclone (U_QuebraTXT (alltrim (sc2 -> c2_obs), 80))
		//u_log (_aobs)
		for _nObs = 1 to len (_aObs)
			_oPrn:Say (_nMargSup + li, _nMargEsq, iif (_nObs == 1, "Observacoes: ", "             ") + _aObs [_nObs], _oCour12N, 100)
			li += _nAltLin
		next
		li += _nAltLin
	endif

	// Liberacoes
	_sLinImp := "_________________________   ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	_sLinImp := "  Liberacao eng.produto     ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	_sLinImp := "                            ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
//	_sLinImp := "                            ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
//	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
//	li += _nAltLin
	_sLinImp := replicate ('-', limite)
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	_sLinImp := "_________________________   ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
	_sLinImp := "   Liberacao qualidade      ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
	li += _nAltLin
//	_sLinImp := "                            ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
//	_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
//	li += _nAltLin

	if sb1 -> b1_tipo == 'VD'
		_sLinImp := replicate ('-', limite)
		_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
		li += _nAltLin
		_sLinImp := "_________________________   ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
		_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
		li += _nAltLin
		_sLinImp := "   Liberacao formulacao     ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
		_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
		li += _nAltLin
//		_sLinImp := "                            ____/____/____ - ____:____  Obs.:_______________________________________________________________________"
//		_oPrn:Say (_nMargSup + li, _nMargEsq, _sLinImp, _oCour8N, 100)
//		li += _nAltLin
	endif

	// Codigo de barras com o numero da OP
	MSBAR ("CODE128", ;  // tipo do codigo de barras ("EAN13","EAN8","UPCA" ,"SUP5"   ,"CODE128" INT25","MAT25,"IND25","CODABAR" ,"CODE3_9")
	0.7, ;        // Pos. vertical em Cm
	16, ;       // Pos. horiz. em Cm
	alltrim (_sOP), ;     // Conteudo
	_oPrn, ;    // Objeto printer
	.F., ;      // .T. = calcula digito de controle
	Nil, ;      // Numero da Cor, utilize a "common.ch"
	.T., ;      // .T. = imprime na horizontal
	0.03, ;     // Tamanho da barra
	0.7, ;      // Altura da barra
	.F., ;      // .T. = imprime o dado abaixo da barra
	Nil, ;      // String com o tipo de fonte
	"", ;    // Modo do codigo de barras CODE128
	.F.,  ;  // .T. = manda direto para a impressora, sem visualizar.
	2,  ;    // Numero do indice de ajuste da largura da fonte
	2)       // Numero do indice de ajuste da altura da fonte

	// Codigo de barras com DUN14 da caixa
	if ! empty (_sDUN14)
		MSBAR ("CODE128", ;  // tipo do codigo de barras ("EAN13","EAN8","UPCA" ,"SUP5"   ,"CODE128" INT25","MAT25,"IND25","CODABAR" ,"CODE3_9")
		4.5, ;        // Pos. vertical em Cm
		16.0, ;       // Pos. horiz. em Cm
		alltrim (_sDUN14), ;     // Conteudo
		_oPrn, ;    // Objeto printer
		.F., ;      // .T. = calcula digito de controle
		Nil, ;      // Numero da Cor, utilize a "common.ch"
		.T., ;      // .T. = imprime na horizontal
		0.03, ;     // Tamanho da barra
		0.6, ;      // Altura da barra
		.F., ;      // .T. = imprime o dado abaixo da barra
		Nil, ;      // String com o tipo de fonte
		"", ;    // Modo do codigo de barras CODE128
		.F.,  ;  // .T. = manda direto para a impressora, sem visualizar.
		2,  ;    // Numero do indice de ajuste da largura da fonte
		2)       // Numero do indice de ajuste da altura da fonte
	endif
return



// --------------------------------------------------------------------------
Static Function _CabecComp ()
	_oPrn:Say (_nMargSup + li, _nMargEsq, padc ("  COMPONENTES  ", limite, "*"), _oCour8N, 100)
	li += _nAltLin
// 	_oPrn:Say (_nMargSup + li, _nMargEsq, " Compon.   Descricao                               Quant.prev.|UM|Alm| Ender.previsto| Endereco real |   Lote   |  Qt.real | Perdas |", _oCour8N, 100)
 	_oPrn:Say (_nMargSup + li, _nMargEsq, " Compon.   Descricao                     Quant.prev.|UM|Alm| Ender.previsto| Endereco real |        Lote        |  Qt.real | Perdas |", _oCour8N, 100)
	li += _nAltLin * .5
//	_oPrn:Say (_nMargSup + li, _nMargEsq, "|---------|-----------------------------------|---------------|--|---|---------------|---------------|----------|----------|--------|", _oCour8N, 100)
	_oPrn:Say (_nMargSup + li, _nMargEsq, "|---------|-------------------------|---------------|--|---|---------------|---------------|--------------------|----------|--------|", _oCour8N, 100)
	li += _nAltLin * .5
return



 // --------------------------------------------------------------------------
Static Function _CabecOper ()
	_oPrn:Say (_nMargSup + li, _nMargEsq, padc ("  OPERACOES  ", limite, "*"), _oCour8N, 100)
	li += _nAltLin
	_oPrn:Say (_nMargSup + li, _nMargEsq, replicate ('-', limite), _oCour8N, 100)
	li += _nAltLin * 0.5
return


 // --------------------------------------------------------------------------
Static Function _CabecPer ()
	_oPrn:Say (_nMargSup + li, _nMargEsq, padc ("  PERDAS  ", limite, "*"), _oCour8N, 100)
	li += _nAltLin
	_oPrn:Say (_nMargSup + li, _nMargEsq, "|_MOTIVO_|____________________DESCRICAO____________________|__UN__|__Qtd.__|______________________OBSERVACAO_______________________", _oCour8N, 100)
	li += _nAltLin
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "OP inicial                    ", "C", 13, 0,  "",   "SC2", {},    ""})
	aadd (_aRegsPerg, {02, "OP final                      ", "C", 13, 0,  "",   "SC2", {},    ""})
	aadd (_aRegsPerg, {03, "Data prevista encerramento de ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Data prevista encerramento ate", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Imprime roteiro de operacoes? ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
