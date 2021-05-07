
//  Programa...: ML_RICM
//  Autor......: Jeferson Rech
//  Data.......: 05/2006
//  Descricao..: Relatorio de Venda de Vinho - RS - Credito Presumido ICMS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de Venda de Vinho - RS - Credito Presumido ICMS
// #PalavasChave      #venda_de_vinho
// #TabelasPrincipais #SB1 #SD2 #SA1
// #Modulos   		  #FIS #FAT #EST 
//
// Historico de alteracoes:
// 29/07/2009 - Robert  - Parametros atualizados para Protheus10
//                      - Criados parametros para informar grupos a listar
//                      - Portado para SQL
//                      - Imprime parametros no final
// 01/09/2009 - Robert  - Ignora transf. entre filiais.
// 04/11/2015 - Robert  - Selecao de produtos passa a ser pelo campo B1_VAGCPI e nao mais pelo B1_PROD.
// 06/05/2021 - Claudia - Incluido tags de customizações
//
//
// --------------------------------------------------------------------------
User Function ML_RICM()
	cString := "SD2"
	cDesc1  := "Este programa tem como objetivo, Imprimir o Relatorio"
	cDesc2  := "de Vendas dentro do estado, para calculo de credito"
	cDesc3  := "presumido de ICMS"
	tamanho := "P"
	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha  := {}
	nLastKey:= 0
	cPerg   := "MLRICM"
	titulo  := "Vendas no estado (cred.presum.ICMS)"
	wnrel   := "ML_RICM"
	nTipo   := 0
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	If nLastKey == 27
		Return
	Endif
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	
	RptStatus({|| RptDetail()})
Return
//
// --------------------------------------------------------------------------
Static Function RptDetail()
	local _sQuery    := ""
	local _sAliasQ   := ""

	SetRegua(LastRec())
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	cabec1:="Data     Documento  Serie  Produto  Cliente/Lj        Base ICMS  Vlr Mercadoria "
	cabec2:="                                                                                "
	_xTTOTAL   := 0
	_xTBASEICM := 0

	// Busca dados para impressao
	_sQuery := " select D2_EMISSAO, D2_DOC, D2_SERIE, D2_COD, D2_CLIENTE, D2_LOJA, D2_BASEICM, D2_TOTAL"
	_sQuery +=  " from " + RETSQLNAME ("SB1") + " SB1, "
	_sQuery +=             RETSQLNAME ("SD2") + " SD2, "
	_sQuery +=             RETSQLNAME ("SA1") + " SA1  "
	_sQuery += " where SA1.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SD2.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SB1.D_E_L_E_T_ != '*'"
	_sQuery +=   " and SA1.A1_FILIAL  = '" + xfilial ("SA1")  + "'"
	_sQuery +=   " and SB1.B1_FILIAL  = '" + xfilial ("SB1")  + "'"
	_sQuery +=   " and SD2.D2_FILIAL  = '" + xfilial ("SD2")  + "'"
	_sQuery +=   " and SA1.A1_COD     = D2_CLIENTE"
	_sQuery +=   " and SA1.A1_LOJA    = D2_LOJA"
	_sQuery +=   " and SB1.B1_COD     = D2_COD"
	_sQuery +=   " and SD2.D2_EMISSAO between '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	_sQuery +=   " and SD2.D2_EST     = '" + GetMv ("MV_ESTADO") + "'"
	_sQuery +=   " and SD2.D2_TIPO   != 'D'"
	_sQuery +=   " and SD2.D2_TIPO   != 'B'"
	_sQuery +=   " and SD2.D2_CF     != '5151'"  // Transf. entre filiais
	_sQuery +=   " and SB1.B1_VAGCPI = '" + cvaltochar (mv_par04) + "'"
	_sQuery +=   " and SA1.A1_INSCR  != ''"
	if mv_par05 == 2
		_sQuery +=   " and SA1.A1_INSCR  != 'ISENTO'"
	endif
	_sQuery +=   " ORDER BY D2_EMISSAO, D2_DOC, D2_COD"

	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "D2_EMISSAO", "D")
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		If li>58
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif
		@ li, 000 PSAY (_sAliasQ)->D2_EMISSAO
		@ li, 009 PSAY (_sAliasQ)->D2_DOC
		@ li, 020 PSAY (_sAliasQ)->D2_SERIE
		@ li, 027 PSAY Left((_sAliasQ)->D2_COD,6)
		@ li, 036 PSAY (_sAliasQ)->D2_CLIENTE+" "+SD2->D2_LOJA
		@ li, 050 PSAY (_sAliasQ)->D2_BASEICM  Picture "@E 999,999,999.99"
		@ li, 065 PSAY (_sAliasQ)->D2_TOTAL    Picture "@E 999,999,999.99"
		li:=li + 1
		_xTTOTAL   += (_sAliasQ)->D2_TOTAL
		_xTBASEICM += (_sAliasQ)->D2_BASEICM
		
		(_sAliasQ) -> (dbskip ())
	Enddo
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SD2")

	If _xTTOTAL > 0 .Or. _xTBASEICM > 0
		If li>58
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif
		li:=li + 2
		@ li, 000 PSAY "Totais  -> "+"Ref - "+Dtoc(mv_par01)+" / "+Dtoc(mv_par02)
		@ li, 050 PSAY _xTBASEICM  Picture "@E 999,999,999.99"
		@ li, 065 PSAY _xTTOTAL    Picture "@E 999,999,999.99"
		li:=li + 2
		@ li, 000 PSAY "% De Credito Presumido: "+Transf(mv_par03,"@E 9999.99")
		_xVALORCP := ( ( _xTBASEICM * mv_par03 ) / 100 )
		@ li, 065 PSAY _xVALORCP    Picture "@E 999,999,999.99"
		li ++
	Endif

	li ++
	U_ImpParam (58)
	Roda(0,"",Tamanho)

	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif
	MS_FLUSH()
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Data inicial emissao NF       ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Data final emissao NF         ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "% credito presumido           ", "N", 6,  2,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Grupo a considerar            ", "C", 1,  0,  "",   "   ", {'Sucos', 'Vinhos'}, ""})
	aadd (_aRegsPerg, {05, "Considera inscr.est. ISENTO  ?", "N", 1,  0,  "",   "   ", {'Sim', 'Nao'},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
