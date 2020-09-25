// Programa...: VA_ZZ5I
// Autor......: Robert Koch
// Data.......: 20/02/2009
// Descricao..: Impressao de solicitacoes de transferencia de produtos da expedicao para a loja.
//
// Historico de alteracoes:
// 25/02/2009 - Robert - Permite reimpressao.
// 26/02/2009 - Robert - Permite selecionar o numero de vias.
//

// --------------------------------------------------------------------------
User Function VA_ZZ5I ()
	private cPerg := "VAZZ5I"
	private wnrel := "VA_ZZ5I"
	private nomeprog := "VA_ZZ5I"
	cString := "ZZ5"
	cDesc1  := "Este programa tem como objetivo imprimir relatorio de"
	cDesc2  := "solicitacoes de transferencia de produtos da expedicao para a loja"
	cDesc3  := ""
	tamanho := "M"
	aReturn := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	aOrd    := { }
	nLastKey:= 0
	titulo  := "Solic. transf. da expedicao para loja"
	cabec1 := "Produto (expedicao)                               Quantidades UM   Produto (loja)                                    Quantidades UM"
	cabec2 := ""
	limite := 132
	
	// Cria as perguntas na tabela SX1
	_validPerg()
	
	Pergunte(cPerg, .F.)

	wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., tamanho, NIL, .F.)
	If nLastKey == 27
		Return
	Endif
	fErase(__RelDir + wnrel + '.##r')
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	processa ({|| RptDetail()})
	MS_FLUSH()  // Libera fila de relatorios em spool (Tipo Rede Netware)
	If aReturn [5] == 1
		DbCommitAll ()
		ourspool(wnrel)
	Endif
Return



// --------------------------------------------------------------------------
Static Function RptDetail()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _aMuni     := {}
	local _nMuni     := 0
	local _nVia		 := 0
	private _nMaxLin := 60
	
	procRegua(LastRec())
	
	nTipo := 15
	li    := 80
	m_pag := 1
	
	// Monta arquivo de trabalho com dados das ordens a imprimir.
	incproc ("Buscando dados...")
	_sQuery := ""
	_sQuery += " Select ZZ5.*, SB1PAI.B1_DESC as DescPai, SB1LOJ.B1_DESC as DescLoj, SB1PAI.B1_QTDEMB, SB1PAI.B1_UM as UMPai, SB1LOJ.B1_UM as UMLoja"
	_sQuery += "   From " + RetSQLName ("ZZ5") + " ZZ5, "
	_sQuery +=              RetSQLName ("SB1") + " SB1PAI, "
	_sQuery +=              RetSQLName ("SB1") + " SB1LOJ "
	_sQuery += "  Where ZZ5.D_E_L_E_T_    = ''"
	_sQuery += "    And SB1PAI.D_E_L_E_T_ = ''"
	_sQuery += "    And SB1LOJ.D_E_L_E_T_ = ''"
	_sQuery += "    And ZZ5.ZZ5_FILIAL    = '" + xfilial ("ZZ5") + "'"
	_sQuery += "    And SB1PAI.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery += "    And SB1LOJ.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery += "    And SB1PAI.B1_COD     = ZZ5.ZZ5_CODPAI"
	_sQuery += "    And SB1LOJ.B1_COD     = ZZ5.ZZ5_CODLOJ"
	_sQuery += "    And ZZ5.ZZ5_DTSOLI    between '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	_sQuery += "    And ZZ5.ZZ5_CODLOJ    between '" + mv_par03 + "' and '" + mv_par04 + "'"
	_sQuery += "    And ZZ5.ZZ5_CODPAI    between '" + mv_par05 + "' and '" + mv_par06 + "'"
	if mv_par07 == 2
		_sQuery += "    And ZZ5.ZZ5_IMPRES    != 'S'"
	endif
	_sQuery += "    And ZZ5.ZZ5_DTATEN    = ''"
	_sQuery += "    And ZZ5.ZZ5_ESTORN    != 'S'"
	_sQuery += "  Order by SB1PAI.B1_GRPEMB, ZZ5_CODPAI"

 	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	TCSetField (alias (), "ZZ5_DTSOLI", "D")

	for _nVia = 1 to mv_par08
		titulo  := "Solic. transf. da expedicao para loja - de " + dtoc (mv_par01) + " a " + dtoc (mv_par02) + " - " + cvaltochar (_nVia) + "a. via"
		(_sAliasQ) -> (dbgotop ())
		Do While ! (_sAliasQ) -> (Eof ())
			
			// Calcula a quantidade minima do pai para atender `a quantidade solicitada pela
			// loja e, depois, calcula a quantidade obtida na loja.
			_nQtPai = int ((_sAliasQ) -> zz5_qtloja / (_sAliasQ) -> b1_QtdEmb)
			if (_sAliasQ) -> zz5_qtloja % (_sAliasQ) -> b1_QtdEmb > 0
				_nQtPai ++
			endif
			_nQtLoja = _nQtPai * (_sAliasQ) -> b1_QtdEmb
	
			if li > _nMaxLin
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay U_TamFixo (alltrim ((_sAliasQ) -> zz5_codpai) + " - " + (_sAliasQ) -> DescPai, 47) + " " + ;
			             transform (_nQtPai, "@E 99999") + " _______ " + ;
			             (_sAliasQ) -> UMPai + "   " + ;
			             U_TamFixo (alltrim ((_sAliasQ) -> zz5_codloj) + " - " + (_sAliasQ) -> DescLoj, 47) + " " + ;
			             transform (_nQtLoja, "@E 99999") + " _______ " + ;
			             (_sAliasQ) -> UMLoja
			li += 2
	
			// Marca como 'jah impressa'.
			zz5 -> (dbsetorder (1))
			if zz5 -> (dbseek (xfilial ("ZZ5") + dtos ((_sAliasQ) -> zz5_dtsoli) + (_sAliasQ) -> zz5_codloj + (_sAliasQ) -> zz5_seq, .F.))
				reclock ("ZZ5", .F.)
				zz5 -> zz5_impres = "S"
				msunlock ()
			endif
			(_sAliasQ) -> (dbskip())
		enddo
		li = _nMaxLin + 1
	next
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("ZZ5")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Data solicitacao de           ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {02, "Data solicitacao ate          ", "D", 8,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {03, "Produto (loja) de             ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {04, "Produto (loja) ate            ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {05, "Produto (expedicao) de        ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {06, "Produto (expedicao) ate       ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {07, "Reimprime jah impressas       ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {08, "Numero de vias                ", "N", 2,  0,  "",   "   ", {},             ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
