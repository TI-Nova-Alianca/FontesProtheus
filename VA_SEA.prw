// Programa:   VA_SEA
// Autor:      Robert Koch
// Data:       16/04/2009
// Cliente:    Alianca
// Descricao:  Relatorio de saldos em estoque por almoxarifado.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function VA_SEA (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	
	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Saldo ATUAL por almoxarifado"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SB2"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := "Saldo ATUAL por almoxarifado"
	cPerg    := "VA_SEA"
	nomeprog := "VA_SEA"
	wnrel    := "VA_SEA"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
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
		_sErroConv = U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
		if ! empty (_sErroConv)
			u_help (_sErroConv)
		endif
	else
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
return




// --------------------------------------------------------------------------
// Geracao do arquivo de trabalho p/ impressao
static function _Imprime ()
	local _nMaxLin   := 63
	local _sQuery    := ""
	local _sQuery2   := ""
    local _aAlmox    := {}
    local _nAlmox    := 0
	local _lContinua := .T.
	local _sAliasQ   := ""
	local _sLinImp   := ""

	procregua (3)

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		_lContinua = .F.
	EndIf	

	// Selecao de produtos e almoxarifados a serem impressos.
	if _lContinua
		_sQuery := ""
		_sQuery +=  " from " + RETSQLNAME ("SB2") + " SB2, "
		_sQuery +=             RETSQLNAME ("SB1") + " SB1 "
		_sQuery += " where SB2.D_E_L_E_T_ != '*'"
		_sQuery +=   " and SB2.B2_FILIAL  =       '" + xfilial ("SB2")  + "'"
		_sQuery +=   " and SB1.B1_TIPO    between '" + mv_par05  + "' and '" + mv_par06 + "'"
		_sQuery +=   " and SB2.B2_COD     between '" + mv_par03         + "' and '" + mv_par04        + "'"
		_sQuery +=   " and SB1.B1_COD     = SB2.B2_COD"
		_sQuery +=   " and SB2.B2_LOCAL   between '" + mv_par01         + "' and '" + mv_par02        + "'"
		if mv_par07 == 2
			_sQuery +=   " and SB2.B2_QATU != 0"
		endif
	endif


	// Verifica quais os almoxarifados a serem impressos e monta titulo do relatorio.
	if _lContinua
		_sQuery2 := ""
		_sQuery2 += " select B2_LOCAL, count (*)"
		_sQuery2 += _sQuery
		_sQuery2 += " group by B2_LOCAL"
		_aAlmox = aclone (U_Qry2Array (_sQuery2))
		if len (_aAlmox) == 0
			u_help ("Nenhum almoxarifado encontrado dentro dos parametros informados.")
			_lContinua = .F.
		endif
		if len (_aAlmox) > 12
			u_help ("Foram encontrados " + cvaltochar (len (_aAlmox)) + " almoxarifados a listar. Numero maximo permitido = 12.")
			_lContinua = .F.
		endif
	endif
	if _lContinua
		cCabec1 = "Produto                                                       UM"
		for _nAlmox = 1 to len (_aAlmox)
			cCabec1 += "      Alm. " + _aAlmox [_nAlmox, 1] + ""
		next
	endif


	// Busca dados para impressao
	if _lContinua
		_sQuery2 := ""
		_sQuery2 += " select B1_TIPO, B2_COD, "
		for _nAlmox = 1 to len (_aAlmox)
			_sQuery2 +=    " SUM (CASE B2_LOCAL WHEN '" + _aAlmox [_nAlmox, 1] + "' THEN B2_QATU ELSE 0 END) AS ALM" + _aAlmox [_nAlmox, 1] + ", "
		next
		_sQuery2 += " B1_DESC, B1_UM "
		_sQuery2 += _sQuery
		_sQuery2 += " GROUP BY B1_TIPO, B2_COD, B1_DESC, B1_UM"
		_sQuery2 += " order by B1_TIPO, B2_COD"
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery2), _sAliasQ,.F.,.F.)
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif

			// Monta linha para impressao
			_sLinImp := ""
			_sLinImp += U_TamFixo (alltrim ((_sAliasQ) -> b2_cod) + " - " + (_sAliasQ) -> b1_desc, 61) + " " + (_sAliasQ) -> b1_UM + " "
			for _nAlmox = 1 to len (_aAlmox)
				_sLinImp += transform ((_sAliasQ) -> &("ALM" + _aAlmox [_nAlmox, 1]), "@E 9,999,999.99") + " "
			next
			@ li, 0 psay _sLinImp
			li ++
			if mv_par08 == 2
				li ++
			endif

			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea (cString)

		// Imprime lista dos almoxarifados encontrados
		li ++
		if li > _nMaxLin - 3
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay "Descricao dos almoxarifados listados:"
		li ++
		for _nAlmox = 1 to len (_aAlmox)
			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay _aAlmox [_nAlmox, 1] + " - " + Tabela ("AL", _aAlmox [_nAlmox, 1])
			li ++
		next
		
		// Imprime parametros usados na geracao do relatorio
		li ++
		U_ImpParam (_nMaxLin)

	endif
	
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Almoxarifado inicial          ", "C", 2,  0,  "",   "AL ", {},                        "Almoxarifado inicial a ser considerado."})
	aadd (_aRegsPerg, {02, "Almoxarifado final            ", "C", 2,  0,  "",   "AL ", {},                        "Almoxarifado final a ser considerado."})
	aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                        "Produto inicial a ser considerado."})
	aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                        "Produto final a ser considerado."})
	aadd (_aRegsPerg, {05, "Tipo produto inicial          ", "C", 2,  0,  "",   "02 ", {},                        "Tipo de produto inicial a ser considerado."})
	aadd (_aRegsPerg, {06, "Tipo produto final            ", "C", 2,  0,  "",   "02 ", {},                        "Tipo de produto final a ser considerado."})
	aadd (_aRegsPerg, {07, "Listar itens com saldo zerado?", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},            "Indique se deseja listar itens com saldo zerado"})
	aadd (_aRegsPerg, {08, "Linha vazia entre os itens?   ", "N", 1,  0,  "",   "   ", {"Nao", "Sim"},            "Deixar una linha vazia entre os itens para facilitar anotacoes"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
