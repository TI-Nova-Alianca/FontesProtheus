// Programa:   VA_RBN
// Autor:      Robert Koch
// Data:       06/10/2008
// Cliente:    Alianca
// Descricao:  Relatorio de bonificacoes.
// 
// Historico de alteracoes:
// 22/01/2009 - Robert  - Valorizacao por preco de venda passa a ler D2_PRUNIT
// 02/02/2009 - Robert  - Soh considera ST quando o cliente nao paga ST das bonificacoes.
// 12/05/2015 - Catia   - Alterado tabela SX5-Z3 para ZX5-22 - motivos de bonificacao
// 03/06/2016 - Catia   - Usar VA_VFAT ao inves do antigo exporta dados
// 07/06/2016 - Robert  - Campo PRODPAI em desuso. Passa a usar apenas o campo PRODUTO da view VA_VFAT.
// 31/07/2018 - André   - Alterado o relatório validando com o análise de saídas.
// 25/01/2019 - Andre   - Pesquisa ZX5 alterada de FBUSCACPO para U_RETZX5.
// 09/07/2019 - Andre   - Adicionado campo de filial para todas as tabelas da query.
// 05/09/2019 - Andre   - Adicionado filtro por filiais.
//
// --------------------------------------------------------------------------
user function VA_RBN (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Variaveis obrigatorias dos programas de relatorio
	Titulo   := "Relatorio de bonificacoes"
	cDesc1   := Titulo
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SD2"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	cPerg    := "VA_RBN"
	nomeprog := "VA_RBN"
	wnrel    := "VA_RBN"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := "NF/serie      Emissao     Pedido  Cliente/loja/nome                                UF  Produto  Descrição                                                Vl.total  Valor ST    IPI   Valor BRT  Motivo bonificacao"
	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
		
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString	, ;  // Alias
		wnrel						, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg						, ;  // Parametros
		@titulo						, ;  // Titulo do relatorio
		cDesc1						, ;  // Descricao 1
		cDesc2						, ;  // Descricao 2
		cDesc3						, ;  // Descricao 3
		.F.							, ;  // .T. = usa dicionario
		aOrd						, ;  // Array de ordenacoes para o usuario selecionar
		.T.							, ;  // .T. = comprimido
		tamanho						, ;  // P/M/G
		NIL							, ;  // Nao pude descobrir para que serve.
		.F.							, ;  // .T. = usa filtro
		NIL							, ;  // lCrystal
		NIL							, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T.							, ;  // .T. = NAO mostra interface para usuario
		.T.							, ;  // lServer
		NIL							)    // cPortToPrint
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
	local _aAliasQ   := ""
	local _aMotivos  := {}
	local _nMotivo   := 0
	local _nValor    := 0
	local _aTotVend  := {}
	local _aTotGer   := {}

	li = _nMaxLin + 1
	procregua (3)
	Titulo += " entre " + dtoc (mv_par05) + " e " + dtoc (mv_par06) + " - valorizado pelo "

	_sQuery := ""
	_sQuery += " SELECT SD2.D2_CLIENTE AS CLIENTE, SD2.D2_LOJA AS LOJA, SD2.D2_COD AS PRODUTO, SD2.D2_QUANT AS QUANT,"
	_sQuery += 	      " SD2.D2_DOC AS NOTA, SD2.D2_SERIE AS SERIE, SD2.D2_EMISSAO AS EMISSAO, SD2.D2_PEDIDO AS PEDIDO,"
	_sQuery +=        " SF2.F2_VEND1 AS VEND1, SD2.D2_EST AS UF, SD2.D2_PRCVEN * SD2.D2_QUANT AS VLR_MERC, SD2.D2_VALIPI AS VLR_IPI,"
	_sQuery +=        " SD2.D2_ICMSRET AS VLR_ST, SD2.D2_VALBRUT AS VLR_BRT, SC6.C6_BONIFIC AS MOTIVO"
	_sQuery +=  " FROM " + RETSQLNAME ("SD2") + " SD2 "
	_sQuery +=         " INNER JOIN " + RETSQLNAME ("SF2") + " SF2 "
	_sQuery +=			" ON (SF2.D_E_L_E_T_ = ''"
	_sQuery +=			" AND SF2.F2_FILIAL = SD2.D2_FILIAL
	_sQuery +=		 	" AND SF2.F2_DOC = SD2.D2_DOC"
	_sQuery +=		 	" AND SF2.F2_SERIE = SD2.D2_SERIE"
	_sQuery +=		 	" AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
	_sQuery +=		 	" AND SF2.F2_LOJA = SD2.D2_LOJA"
	_sQuery +=		 	" AND SF2.F2_VEND1 BETWEEN '" + mv_par03          + "' and '" + mv_par04          + "'"  // INTERVALO DE VENDEDOR
	_sQuery +=		 	" AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery +=		   " INNER JOIN " + RETSQLNAME ("SF4") + " SF4 "
	_sQuery +=			" ON (SF4.D_E_L_E_T_ = ''"
	_sQuery +=			" AND SF4.F4_FILIAL = '" + xfilial ("SF4")  + "'"
	_sQuery +=          " AND SF4.F4_MARGEM = '3'"
	_sQuery +=		    " AND SF4.F4_CODIGO = SD2.D2_TES)"
	_sQuery +=         " INNER JOIN " + RETSQLNAME ("SC6") + " SC6 "
	_sQuery +=          " ON (SC6.D_E_L_E_T_ = ''"
	_sQuery +=			" AND SC6.C6_FILIAL = SD2.D2_FILIAL
	_sQuery +=			" AND SC6.C6_NUM = SD2.D2_PEDIDO"
    _sQuery +=          " AND SC6.C6_BONIFIC  BETWEEN '" + mv_par07          + "' and '" + mv_par08          + "'" // parametro do motivo de bonificacao
	_sQuery +=		    " AND SC6.C6_ITEM = SD2.D2_ITEMPV)"
	if mv_par17 == 2  // Nao listar bugigangas (cartuchos, rotulos, etc.)
		_sQuery +=     " INNER JOIN " + RETSQLNAME ("SB1") + " SB1 "
		_sQuery +=      " ON (SB1.D_E_L_E_T_ = ''"
		_sQuery +=		" AND SB1.B1_FILIAL = '" + xfilial ("SB1")  + "'"
		_sQuery +=   	" AND SB1.B1_COD = SD2.D2_COD"
		_sQuery +=   	" AND SB1.B1_TIPO != 'GG'"
		_sQuery +=   	" AND SB1.B1_TIPO != 'ME')"
	endif
	_sQuery +=		"WHERE SD2.D_E_L_E_T_ = ''"
	_sQuery += 			"AND SD2.D2_FILIAL  BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
	_sQuery += 			"AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par05)   + "' and '" + dtos (mv_par06)   + "'"
	_sQuery += 			"AND SD2.D2_EST     BETWEEN '  ' AND 'ZZ'"
	_sQuery += 			"AND SD2.D2_CLIENTE BETWEEN '" + mv_par09 + "' and '" + mv_par11 + "'"
	_sQuery += 			"AND SD2.D2_LOJA    BETWEEN '" + mv_par10 + "' and '" + mv_par12 + "'"
	_sQuery += 			"AND SD2.D2_COD     BETWEEN '" + mv_par13          + "' and '" + mv_par14          + "'"
    	
	_sQuery += " order by SF2.F2_VEND1, SD2.D2_CLIENTE, SD2.D2_LOJA, SD2.D2_EMISSAO"
	
	//u_showmemo ( _sQuery)
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "EMISSAO", "D")
	_aTotGer = {0,0,0,0,0,0}
	do while ! (_sAliasQ) -> (eof ())
		
		if li > _nMaxLin .or. mv_par15 == 1  // Quebra pagina por vendedor.
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif

		// Controla quebra por vendedor.
		_sVend     = (_sAliasQ) -> vend1
		_sNomeVend = fBuscaCpo ("SA3", 1, xfilial ("SA3") + _sVend, "A3_NOME")
		if mv_par17 == 2  // Detalhado
			@ li, 0 psay "Vendedor: " + _sVend + " - " + _sNomeVend
			li += 2
		endif
		_aTotVend = {0,0,0,0,0,0}
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> vend1 == _sVend

			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif

			_wnome   = left(fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CLIENTE + (_sAliasQ) -> loja , "A1_NOME"),34)
			_wmotdev = left (u_RetZX5 ('22', (_sAliasQ) -> MOTIVO , "ZX5_22DESC"),23)
			_wdesc   = left(fBuscaCpo ("SB1", 1, xfilial ("SB1") + (_sAliasQ) -> PRODUTO   , "B1_DESC"),50)
			if mv_par16 == 2  // Detalhado
				@ li, 0 psay (_sAliasQ) -> nota + "/" + (_sAliasQ) -> serie + " " + ;
				             dtoc ( (_sAliasQ) -> emissao)+ "  " + ;
				             (_sAliasQ) -> PEDIDO + "  " + (_sAliasQ) -> serie + " " + ;
				             (_sAliasQ) -> cliente + "/" + (_sAliasQ) -> loja + " " + _wnome + " " + (_sAliasQ) -> uf + "  " + ;
				             left(alltrim((_sAliasQ) -> PRODUTO),30) + '     ' + _wdesc 
				@ li, 151 psay transform ((_sAliasQ) -> VLR_MERC, "@E 999,999.99")
				@ li, 161 psay transform ((_sAliasQ) -> VLR_ST,   "@E 99,999.99")
				@ li, 171 psay transform ((_sAliasQ) -> VLR_IPI,  "@E 99,999.99")
				@ li, 181 psay transform ((_sAliasQ) -> VLR_BRT,  "@E 99,999.99") + '  ' + (_sAliasQ) -> MOTIVO + '-' + _wmotdev 
	            	            
				li ++
			endif
			_aTotVend [1] += (_sAliasQ) -> VLR_MERC
			_aTotVend [2] += (_sAliasQ) -> VLR_ST
			_aTotVend [3] += (_sAliasQ) -> VLR_IPI
			_aTotVend [4] += (_sAliasQ) -> VLR_BRT
			_aTotGer  [1] += (_sAliasQ) -> VLR_MERC
			_aTotGer  [2] += (_sAliasQ) -> VLR_ST
			_aTotGer  [3] += (_sAliasQ) -> VLR_IPI
			_aTotGer  [4] += (_sAliasQ) -> VLR_BRT
			
			// Acrescenta esta bonificacao `a array para posterior totalizacao por motivo.
			_nMotivo = ascan (_aMotivos, {|_aVal| _aVal [1] == (_sAliasQ) -> MOTIVO})
			if _nMotivo == 0
				aadd (_aMotivos, {(_sAliasQ) -> MOTIVO, _wmotdev, 0,0,0,0})
				_nMotivo = len (_aMotivos)
			endif
			_aMotivos [_nMotivo, 3] += (_sAliasQ) -> VLR_MERC
			_aMotivos [_nMotivo, 4] += (_sAliasQ) -> VLR_ST
			_aMotivos [_nMotivo, 5] += (_sAliasQ) -> VLR_IPI
			_aMotivos [_nMotivo, 6] += (_sAliasQ) -> VLR_BRT
	
			(_sAliasQ) -> (dbskip ())
		enddo
		if mv_par16 == 2  // Detalhado
			@ li, 144 psay "          --------  --------  --------  -------- "
			li ++
		endif
		@ li, 70 psay "Totais vendedor " + _sVend + " - " + alltrim(_sNomeVend)
		@ li, 151 psay transform (_aTotVend [1], "@E 999,999.99")
		@ li, 161 psay transform (_aTotVend [2], "@E 99,999.99")
		@ li, 171 psay transform (_aTotVend [3], "@E 99,999.99")
		@ li, 181 psay transform (_aTotVend [4], "@E 99,999.99")
				               
		li ++
		if mv_par16 == 2  // Detalhado
			@ li, 0 psay __PrtThinLine ()
			li += 2
		endif
	enddo
	(_sAliasQ) -> (dbclosearea ())

	// Imprime totais gerais
	if li > _nMaxLin - 2
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	
	@ li,  70 psay "Totais gerais"
	@ li, 151 psay transform (_aTotGer [1], "@E 999,999.99")
	@ li, 160 psay transform (_aTotGer [2], "@E 999,999.99")
	@ li, 170 psay transform (_aTotGer [3], "@E 999,999.99")
	@ li, 180 psay transform (_aTotGer [4], "@E 999,999.99")
				               
	// Gera nova pagina com totais por motivo.
	if len (_aMotivos) > 0
		_aMotivos = asort (_aMotivos,,, {|_x, _y| _x [3] < _y [3]})
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		@ li, 0 psay "Totais por motivo de bonificacao:"
		li += 2
		@ li, 0 psay "Motivo                                                Valor Merc      Valor ST         IPI         Valor Bruto"
		li ++
		@ li, 0 psay "---------------------------------------------------  ------------   ------------  -------------  -------------"
		li ++
		for _nMotivo = 1 to len (_aMotivos)
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li,   0 psay _aMotivos [_nMotivo, 1] + " - " + left (_aMotivos [_nMotivo, 2], 45)
			@ li,  51 psay transform (_aMotivos [_nMotivo, 3], "@E 999,999,999.99")
			@ li,  66 psay transform (_aMotivos [_nMotivo, 4], "@E 999,999,999.99")
			@ li,  81 psay transform (_aMotivos [_nMotivo, 5], "@E 999,999,999.99")
			@ li,  96 psay transform (_aMotivos [_nMotivo, 6], "@E 999,999,999.99")
			li ++
		next
		@ li, 0 psay "---------------------------------------------------  ------------   ------------  -------------  -------------"
		li ++
		@ li,  51 psay transform (_aTotGer [1], "@E 999,999,999.99") // valor total
		@ li,  66 psay transform (_aTotGer [2], "@E 999,999,999.99") // ST
		@ li,  81 psay transform (_aTotGer [3], "@E 999,999,999.99") // ipi
		@ li,  96 psay transform (_aTotGer [4], "@E 999,999,999.99") // Bruto

		li += 2
	endif
	// Imprime parametros usados na geracao do relatorio
	U_ImpParam (_nMaxLin)
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                         Help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},							  ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},    						  ""})
	aadd (_aRegsPerg, {03, "Vendedor inicial              ", "C", 4,  0,  "",   "SA3", {},                            ""})
	aadd (_aRegsPerg, {04, "Vendedor final                ", "C", 4,  0,  "",   "SA3", {},                            ""})
	aadd (_aRegsPerg, {05, "Data movimentacao inicial     ", "D", 8,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {06, "Data movimentacao final       ", "D", 8,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {07, "Motivo bonificacao inicial    ", "C", 6,  0,  "",   "Z3 ", {},                            ""})
	aadd (_aRegsPerg, {08, "Motivo bonificacao final      ", "C", 6,  0,  "",   "Z3 ", {},                            ""})
	aadd (_aRegsPerg, {09, "Cliente inicial               ", "C", 6,  0,  "",   "SA1", {},                            ""})
	aadd (_aRegsPerg, {10, "Loja cliente inicial          ", "C", 2,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {11, "Cliente final                 ", "C", 6,  0,  "",   "SA1", {},                            ""})
	aadd (_aRegsPerg, {12, "Loja cliente final            ", "C", 2,  0,  "",   "   ", {},                            ""})
	aadd (_aRegsPerg, {13, "Produto de                    ", "C", 15, 0,  "",   "SB1", {},                            "Produto inicial a ser considerado."})
	aadd (_aRegsPerg, {14, "Produto ate                   ", "C", 15, 0,  "",   "SB1", {},                            "Produto final a ser considerado."})
	aadd (_aRegsPerg, {15, "Quebra pagina por vendedor?   ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                "Indique se deseja quebrar pagina a cada vendedor."})
	aadd (_aRegsPerg, {16, "Resumido / detalhado?         ", "N", 1,  0,  "",   "   ", {"Resumido", "Detalhado"},     "Indique se deseja listar nota a nota ou apenas totais do vendedor."})
    aadd (_aRegsPerg, {17, "Incluir rotulos,cartuchos,etc?", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                "Indique se deseja listar materiais de menor valor como rotulos, cartuchos, caixas, etc."})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return