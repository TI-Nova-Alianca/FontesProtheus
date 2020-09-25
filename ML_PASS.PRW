// Programa..: ML_PASS.PRX
// Autor.....: Ricardo
// Data......: 9:39pm Jan 18,1999
// Nota......: Rel. Producao P/ Associados
//
// Historico de alteracoes:
// 27/03/2008 - Robert  - Nao verifica mais se eh formulario proprio (precisa listar recebtos de cooperativas)
// 26/01/2009 - Robert  - Ajuste leitura do SZ1, pois agora vai trabalhar ligado ao SZA.
// 24/06/2009 - Robert  - Ajustes do ValidPerg para Protheus10.
//                      - Impressao dos parametros no final do relatorio.
// 21/08/2009 - Robert  - Criado parametro para imprimir ou nao as colunas de valores.
// 24/08/2009 - Robert  - Passa a usar a funcao U_PrecoUva()
//                      - Passa a considerar a classificacao das uvas finas.
// 06/10/2009 - Robert  - Soh calcula o preco da uva (funcao PrecoUva) quando nao buscar da nota (calculava por nada)
//                      - TES 009 nao participa mais das notas de compra de uva.
// 11/05/2011 - Robert  - Convertido para SQL.
//                      - Multifilial.
//                      - Selecao de tipos de associados a listar.
//                      - Passa a considerar situacao do associado na safra em questao (tabela SZ7).
// 02/03/2012 - Robert  - Criados parametros de tipo de produto de...ate (ex.: separar vinho de cantinas rurais).
// 07/05/2012 - Robert  - Ajustes pequenos no layout.
// 19/06/2012 - Robert  - Criada opcao de listar producao propria.
//                      - Tratamento para prod.propria 2007, que entrou com TES diferenciado.
// 15/10/2012 - Robert  - Passa a desconsiderar notas de compra safra 2012 que foram devolvidas posteriormente.
// 22/11/2012 - Elaine  - Ajustes de layout, nf que ficou desconfigurada e totais que nao estao alinhados
// 08/04/2013 - Robert  - Desconsiderar notas de entrada estornadas safra 2013 (000002408 e 000002843)
// 18/06/2015 - Robert  - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 26/01/2016 - Robert  - Verifica se o usuario tem acesso, pela tabela ZZU, a ver valores.
// 18/04/2017 - Robert  - Novo parametro funcao U_PrecoUva().
// 23/11/2018 - Robert  - Nao trata mais tipo de associado (tabela SZ7) a partir de 2019.
// 01/03/2019 - Robert  - Busca sempre valor de nota (desabilitada busca de valor por tabela de precos)
//                      - Abre sempre a tela de selecao de filliais
// 09/03/2020 - Claudia - Ajustada criação de arquivo de trabalho conforme solicitação da release 12.1.25
// 27/03/2020 - Andre   - Removido antigo parametro MV_PAR11 e tb parametros descontinuados.
// --------------------------------------------------------------------------
User Function ML_PASS()
	cString  := "SF1"
	cDesc1   := "Este programa tem como objetivo, imprimir relatorio de"
	cDesc2   := "Producao P/ Associados"
	cDesc3   := ""
	tamanho  := "M"
	aReturn  := { "Zebrado", 1,"Administracao", 1, 2, 1, "",1 }
	aLinha   := { }
	nLastKey := 0
	cPerg    := "MLXPAS"
	titulo   := "Relatorio Producao p/ Associado"
	wnrel    := "ML_PASS"
	nTipo    := 0
	private _sArqLog := U_NomeLog ()
	
	U_LogId ()

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1
	
	// Envia controle para a funcao SETPRINT                        
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
	delete file (__reldir + wnrel + ".##r")

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
	local _sQuery   := ""
	local _sAliasQ  := ""
	local _sFiliais := ""
	local _aFiliais := {}
	local _i        := 0
	local _sTpForn  := ''
	local _aArqTrb  := {}

	// Verifica se o usuario tem liberacao para ver valores.
	if mv_par09 == 1
		if ! U_ZZUVL ('051', __cUserID, .F., cEmpAnt, cFilAnt)
			u_help ("Usuario nao pertence ao grupo 051. Opcao SIM nao permitida no parametro 'lista valores'.")
			return
		endif
	endif
/*
	// Nao pretendo mais usar a tabela SZ7 a partir de 2019
	if mv_par01 >= stod ('20190101') .and. mv_par11 != '*****'
		u_help ("A partir da safra 2019 o parametro 'Tipos de associados' deve ser deixado em branco.")
		return
	endif
*/	
	_aFiliais = U_LeSM0 ('3', cEmpAnt, '', '')
	_sFiliais = ''
	for _i = 1 to len (_aFiliais)
		if _aFiliais [_i, 1]
			_sFiliais += ALLTRIM (_aFiliais [_i, 4]) + '/'
		endif
	next
	// Remove barra no final.
	if right (_sFiliais, 1) == '/'
		_sFiliais = substr (_sFiliais, 1, len (_sFiliais) - 1)
	endif

	SetRegua(LastRec())
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	
	cabec1 := "Data        NF      Filial Produto                               Grau  Classif     Qtde  " + iif (mv_par09 == 1, "Prc Unit      Valor Total", "")
	cabec2 := ""
	cabec3 := "  Associado                             Produto                               Grau  Classif     Qtde     " + iif (mv_par09 == 1, "Valor Total", "")
	cabec4 := "  Produto                                Grau  Classif     Qtde     " + iif (mv_par09 == 1, "Valor Total", "")
	
	// Gera arquivo de Trabalho                                     
	aCampos := {}
	AADD(aCampos,{"_FILIAL"  ,"C",2,0})
	AADD(aCampos,{"_FLAG"    ,"C",1,0})
	aTam:=TamSX3("F1_FORNECE")
	AADD(aCampos,{"_ASSOC"   ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("A2_NOME")
	AADD(aCampos,{"_NOME"    ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("F1_EMISSAO")
	AADD(aCampos,{"_DTA"    ,"D",aTam[1],aTam[2]})
	aTam:=TamSX3("F1_DOC")
	AADD(aCampos,{"_NOTA"    ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("F1_SERIE")
	AADD(aCampos,{"_SERIE"   ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("D1_COD")
	AADD(aCampos,{"_PRODUTO" ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("B1_DESC")
	AADD(aCampos,{"_DESCRI"  ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("D1_GRAU")
	AADD(aCampos,{"_GRAU"    ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("D1_PRM99")
	AADD(aCampos,{"_CLASSE"  ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("D1_QUANT")
	AADD(aCampos,{"_QUANT"   ,"N",aTam[1],aTam[2]})
	aTam:=TamSX3("D1_VUNIT")
	AADD(aCampos,{"_VUNIT"   ,"N",aTam[1],aTam[2]})
	AADD(aCampos,{"_VTOTAL"  ,"N",12,3})
	
//	cArqTra := CriaTrab(aCampos)
//	DbUseArea( .T.,, cArqTra,cArqTra, .T. , .F. )
//	cArqTra1:=Substr(cArqTra,1,7)+"1"
//	
//	DbSelectArea(cArqTra)
//	Index on _FLAG+_ASSOC+DTOS(_DTA)+_NOTA+_SERIE+_PRODUTO+_GRAU+_Classe to &cArqTra1

	U_ArqTrb ("Cria", "TRB", aCampos, {"_FLAG + _ASSOC + _DTA + _NOTA + _SERIE + _PRODUTO + _GRAU + _Classe"}, @_aArqTrb)	
/*
	// Monta clausula com os tipos de fornecedores.
	_sTpForn = ''
	_sTpForn += iif ('1' $ mv_par11, 'A', '')
	_sTpForn += iif ('2' $ mv_par11, 'C', '')
	_sTpForn += iif ('3' $ mv_par11, 'O', '')
	_sTpForn += iif ('4' $ mv_par11, 'E', '')
	_sTpForn += iif ('5' $ mv_par11, 'P', '')
	_sTpForn = FormatIn (strtran (_sTpForn, '*', ''),, 1)
*/
	// Gera dados em arquivo de trabalho.
	_sQuery += " SELECT FILIAL AS D1_FILIAL, DOC AS D1_DOC, SERIE AS D1_SERIE, ASSOCIADO AS D1_FORNECE, LOJA_ASSOC AS D1_LOJA, "
	_sQuery +=        " NOME_ASSOC AS A2_NOME, PRODUTO AS D1_COD, PESO_LIQ AS D1_QUANT, GRAU AS D1_GRAU, CLAS_FINAL AS D1_PRM99, "
	_sQuery +=        " DESCRICAO AS B1_DESC, VALOR_UNIT AS D1_VUNIT, VALOR_TOTAL AS D1_TOTAL, DATA AS D1_DTDIGIT"
	_sQuery +=   " FROM VA_VNOTAS_SAFRA V,"
	_sQuery +=          RetSQLName ("SB1") + " SB1 "
	_sQuery +=  " WHERE V.FILIAL   IN " + FormatIn (_sFiliais, '/')
	
	If mv_par08 == 1 // NF de Entrada
		_sQuery +=    " AND TIPO_NF IN ('E', 'P')"
	Elseif mv_par08 == 2  // NF de Compra
		_sQuery +=    " AND TIPO_NF IN ('C')"
	Elseif mv_par08 == 3  // NF de Compl.preco
		_sQuery +=    " AND TIPO_NF IN ('V')"
	endif
	
	_sQuery +=    " AND V.DATA         BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery +=    " AND V.ASSOCIADO    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery +=    " AND V.PRODUTO      BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	//_sQuery +=    " AND V.TIPO_FORNEC  IN " + _sTpForn
	_sQuery +=    " AND SB1.B1_TIPO    BETWEEN '" + mv_par10 + "' AND '" + mv_par11 + "'"
	_sQuery +=    " AND SB1.B1_COD     = V.PRODUTO"
	_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"

	u_log (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "D1_DTDIGIT", "D")
	count to _nRecCount
	
	if _nRecCount == 0
		u_help ("Nao ha dados selecionados")
	endif
	
	procregua (_nRecCount)
	(_sAliasQ) -> (dbgotop ())
	
	do while ! (_sAliasQ) -> (eof ())
		incproc ()

		// Busca preco da uva cfe. parametrizacao do usuario.
		_wVUNIT :=(_sAliasQ)->D1_VUNIT
		_wVTOTAL:=(_sAliasQ)->D1_TOTAL
		
		IF mv_par07==1
			DbSelectArea("TRB")
			Reclock("TRB",.T.)
			_FLAG    = "1"
			_Filial  = (_sAliasQ) -> d1_Filial
			_ASSOC   = (_sAliasQ) -> d1_FORNECE
			_Nome    = (_sAliasQ) -> a2_nome
			_DTA     = (_sAliasQ) -> d1_dtdigit
			_NOTA    = (_sAliasQ) -> d1_DOC
			_SERIE   = (_sAliasQ) -> d1_SERIE
			_PRODUTO = (_sAliasQ)->D1_COD
			_Descri  = (_sAliasQ)->b1_desc
			_GRAU    = (_sAliasQ)->D1_GRAU
			_Classe  = (_sAliasQ)->D1_prm99
			_QUANT   = (_sAliasQ)->D1_QUANT
			_VUNIT   = _wVUNIT
			_VTOTAL  = _wVTOTAL
			MsUnLock()
		EndIf
		
		If mv_par07==1 .Or. mv_par07==2
			DbSelectArea("TRB")
			DbSeek("2"+(_sAliasQ)->d1_FORNECE+SPACE(08)+SPACE(06)+SPACE(03)+(_sAliasQ)->D1_COD+(_sAliasQ)->D1_GRAU+(_sAliasQ)->d1_prm99)
			
			If Found()
				Reclock("TRB",.F.)
				_QUANT   = _QUANT +(_sAliasQ)->D1_QUANT
				_VUNIT   = _VUNIT+_wVUNIT
				_VTOTAL  = _VTOTAL+_wVTOTAL
				MsUnLock()
			Else
				Reclock("TRB",.T.)
				_FLAG    = "2"
				_FILIAL  = (_sAliasQ) -> d1_Filial
				_ASSOC   = (_sAliasQ) -> d1_FORNECE
				_Nome    = (_sAliasQ) -> a2_nome
				_PRODUTO = (_sAliasQ)->D1_COD
				_Descri  = (_sAliasQ)->b1_desc
				_GRAU    = (_sAliasQ)->D1_GRAU
				_Classe  = (_sAliasQ)->D1_prm99
				_QUANT   = (_sAliasQ)->D1_QUANT
				_VUNIT   = _wVUNIT
				_VTOTAL  = _wVTOTAL
				MsUnLock()
			EndIf
		EndIf
		
		If mv_par07==1 .Or. mv_par07==3
			DbSelectArea("TRB")
			DbSeek("3"+SPACE(06)+SPACE(08)+SPACE(06)+SPACE(03)+(_sAliasQ)->D1_COD+(_sAliasQ)->D1_GRAU+(_sAliasQ)->d1_prm99)
			
			If Found()
				Reclock("TRB",.F.)
				_QUANT   = _QUANT +(_sAliasQ)->D1_QUANT
				_VUNIT   = _VUNIT+_wVUNIT
				_VTOTAL  = _VTOTAL+_wVTOTAL
				MsUnLock()
			Else
				Reclock("TRB",.T.)
				_FLAG    = "3"
				_PRODUTO = (_sAliasQ)->D1_COD
				_Descri  = (_sAliasQ)->b1_desc
				_GRAU    = (_sAliasQ)->D1_GRAU
				_Classe  = (_sAliasQ)->D1_prm99
				_QUANT   = (_sAliasQ)->D1_QUANT
				_VUNIT   = _wVUNIT
				_VTOTAL  = _wVTOTAL
				MsUnLock()
			EndIf
		EndIf
		(_sAliasQ) -> (DbSkip())
	Enddo

	// Impressao.
	DbSelectArea("TRB")
	DBGoTop()
	
	_x_ASSOC:="######"
	_w_ASSOC:="######"
	_xVEZ1  := _xVEZ2 := _xVEZ3 :=0
	_TQTD1  := _TQTD2 := _TQTD3 :=0
	_TVALOR1:=_TVALOR2:=_TVALOR3:=0
	_TASSQTD:=0
	_TASSVLR:=0
	
	Do While !Eof()
		IncRegua()              // Termometro de Impressao
		x_FLAG   :=_FLAG
		x_Filial :=_filial
		x_ASSOC  :=_ASSOC
		_x_DESC  := left (_Nome, 30)
		x_DTA    :=_DTA
		x_NOTA   :=_NOTA
		x_SERIE  :=_SERIE
		x_PRODUTO:=_PRODUTO
		_x_DESC1 :=Left(_Descri,30)
		x_GRAU   :=_GRAU
		x_Classe :=_Classe
		x_QUANT  :=_QUANT
		x_VUNIT  :=_VUNIT
		x_VTOTAL :=_VTOTAL
		
		IF x_ASSOC<>_x_ASSOC .And. x_FLAG=="1"
			If _TASSQTD > 0 .Or. _TASSVLR > 0
				li:=li+1
				@ li, 020 PSAY "* * * * Total ==> "
				@ li, 077 PSAY _TASSQTD   Picture "@E 999,999,999"
				if mv_par09 == 1
					@ li, 098 PSAY _TASSVLR   Picture "@E 999,999,999.999"
				endif
				li:=li+2
				_TASSQTD:=0
				_TASSVLR:=0
				li:=60
			Endif
			
			If li>58
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			
			If _xVEZ3<>0
				li:=li+1
			EndiF
			_xVEZ3:=1
			@ li, 002 PSAY "Associado : "+x_ASSOC+" - "+_x_DESC
			li:=li+1
			_x_ASSOC:=x_ASSOC
		EndIf
		
		If x_FLAG=="1"
			If li>58
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@ li, 000 PSAY u_tamfixo (DTOC(x_DTA), 10)
			@ li, 012 PSAY x_NOTA
			@ li, 022 PSAY x_Filial
			@ li, 027 PSAY Left(x_PRODUTO,7)
			@ li, 035 PSAY Left(_x_DESC1,30)
			@ li, 066 PSAY x_GRAU
			@ li, 070 PSAY x_Classe
			@ li, 077 PSAY x_QUANT  Picture "@E 999,999,999"
			if mv_par09 == 1
				@ li, 088 PSAY x_VUNIT  Picture "@E  999.999"
				@ li, 098 PSAY x_VTOTAL Picture "@E 999,999,999.999"
			endif
			_TQTD1  :=_TQTD1  +x_QUANT
			_TVALOR1:=_TVALOR1+x_VTOTAL
			_TASSQTD:=_TASSQTD+x_QUANT
			_TASSVLR:=_TASSVLR+x_VTOTAL
		Endif
		
		If x_FLAG=="2"
			If li>58
				cabec(titulo,cabec3,cabec2,wnrel,tamanho,nTipo)
			Endif
			If _xVEZ1==0 .And. mv_par07==1
				li:=li+1
				@ li, 022 PSAY "* * * * Total ==> "
				@ li, 077 PSAY _TASSQTD   Picture "@E 999,999,999"
				if mv_par09 == 1
					@ li, 098 PSAY _TASSVLR   Picture "@E 999,999,999.999"
				endif
				
				li:=60
				If li>58
					cabec(titulo,cabec3,cabec2,wnrel,tamanho,nTipo)
				Endif
				@ li, 002 PSAY Left(Replicate("-",50)+" Resumo Assoc. "+Replicate("-",128),128)
				li:=li+1
				@ li, 000 PSAY cabec3
				li:=li+1
				@ li, 002 PSAY Replicate("-",128)
				li:=li+1
			EndIf
			_xVEZ1:=1
			
			If li>58
				cabec(titulo,cabec3,cabec2,wnrel,tamanho,nTipo)
			Endif
			
			If x_ASSOC<>_w_ASSOC
				@ li, 002 PSAY x_ASSOC+" "+_x_DESC
				_w_ASSOC:=x_ASSOC
			EndIf
			
			@ li, 040 PSAY Left(x_PRODUTO,7)
			@ li, 048 PSAY Left(_x_DESC1,30)
			@ li, 080 PSAY x_GRAU
			@ li, 084 PSAY x_Classe
			@ li, 091 PSAY x_QUANT  Picture "@E 999,999,999"
			
			if mv_par09 == 1
				@ li, 103 PSAY x_VTOTAL Picture "@E 999,999,999.999"
			endif
			
			_TQTD2  :=_TQTD2  +x_QUANT
			_TVALOR2:=_TVALOR2+x_VTOTAL
		Endif
		
		If x_FLAG=="3"
			If li>58
				cabec(titulo,cabec4,cabec2,wnrel,tamanho,nTipo)
			Endif
			
			If _xVEZ2==0 .And. mv_par07==1
				li:=li+1
				@ li, 020 PSAY "* * Total ==> "
				@ li, 091 PSAY _TQTD2   Picture "@E 999,999,999"
				if mv_par09 == 1
					@ li, 103 PSAY _TVALOR2 Picture "@E 999,999,999.999"
				endif
				li:=60
				If li>58
					cabec(titulo,cabec4,cabec2,wnrel,tamanho,nTipo)
				Endif
				@ li, 002 PSAY Left(Replicate("-",50)+" Resumo Produto "+Replicate("-",128),128)
				li:=li+1
				@ li, 000 PSAY cabec4
				li:=li+1
				@ li, 002 PSAY Replicate("-",128)
				li:=li+1
			EndIf
			
			_xVEZ2:=1
			If li>58
				cabec(titulo,cabec4,cabec2,wnrel,tamanho,nTipo)
			Endif
			@ li, 002 PSAY Left(x_PRODUTO,7)
			@ li, 010 PSAY Left(_x_DESC1,30)
			@ li, 043 PSAY x_GRAU
			@ li, 047 PSAY x_Classe
			@ li, 054 PSAY x_QUANT  Picture "@E 999,999,999"
			if mv_par09 == 1
				@ li, 066 PSAY x_VTOTAL Picture "@E 999,999,999.999"
			endif
			_TQTD3  :=_TQTD3  +x_QUANT
			_TVALOR3:=_TVALOR3+x_VTOTAL
		Endif
		
		li:=li+1
		DbSelectArea("TRB")
		DbSkip()
	Enddo
	
	If mv_par07==1 .And. (_TQTD1 != 0 .or. _TVALOR1 != 0)
		If li>58
			cabec(titulo,cabec4,cabec2,wnrel,tamanho,nTipo)
		Endif
		li:=li+1
		@ li, 020 PSAY "* Total ==> "
		@ li, 054 PSAY _TQTD1   Picture "@E 999,999,999"
		if mv_par09 == 1
			@ li, 066 PSAY _TVALOR1 Picture "@E 999,999,999.999"
		endif
		li:=li+1
	EndIf

	If mv_par07==2 .And. (_TQTD2 != 0 .or. _TVALOR2 != 0)
		If li>58
			cabec(titulo,cabec3,cabec2,wnrel,tamanho,nTipo)
		Endif
		li:=li+1
		@ li, 020 PSAY "* * Total ==> "
		@ li, 091 PSAY _TQTD2   Picture "@E 999,999,999"
		if mv_par09 == 1
			@ li, 103 PSAY _TVALOR2 Picture "@E 999,999,999.999"
		endif
		li:=li+1
	EndIf

	If mv_par07==3 .And. (_TQTD3 != 0 .or. _TVALOR3 != 0)
		If li>58
			cabec(titulo,cabec4,cabec2,wnrel,tamanho,nTipo)
		Endif
		li:=li+1
		@ li, 020 PSAY "* * * Total ==> "
		@ li, 054 PSAY _TQTD3   Picture "@E 999,999,999"
		if mv_par09 == 1
			@ li, 103 PSAY _TVALOR3 Picture "@E 999,999,999.999"
		endif
		li:=li+1
	EndIf

	li ++
	U_ImpParam (58)
	@ li, 0 psay "Filiais consideradas: " + _sFiliais
	li ++

	IF li!=80
		Roda(0,"",Tamanho)
	Endif
	
	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH() //Libera fila de relatorios em spool (Tipo Rede Netware)
	
	DbSelectArea("TRB")
	DbCloseArea()
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)     
//	cDelArq:=cArqTra+".DBF"
//	FERASE(cDelArq)
//	cDelArq:=SubStr(cArqTra,1,7)+"*"+OrdBagExt()
//	FERASE(cDelArq)
return
//
// --------------------------------------------------------------------------
// Monta tela semelhante a um MarkBrowse para o usuario selecionar opcoes
// diversas. Usado na validacao das perguntas do relatorio.
/*
user function ML_PASS1 ()
	local _sMvPar    := ''
	local _sMvParDef := ""
	local _aOpcoes   := {}
	
	// Carrega array de opcoes
	aadd (_aOpcoes, '1 - ' + alltrim (X3Combo ('Z7_TIPO', '1')))
	aadd (_aOpcoes, '2 - ' + alltrim (X3Combo ('Z7_TIPO', '2')))
	aadd (_aOpcoes, '3 - ' + alltrim (X3Combo ('Z7_TIPO', '3')))
	aadd (_aOpcoes, '4 - ' + alltrim (X3Combo ('Z7_TIPO', '4')))
	aadd (_aOpcoes, '5 - ' + alltrim (X3Combo ('Z7_TIPO', '5')))

	f_Opcoes (@_sMvPar, ;  // Variavel para resultado
	          "Selecione tipos de associados", ;  // Titulo da janela
	          _aOpcoes, ;  // Opcoes
	          "12345", ;  // Inicializa posicoes
	          12, 49, ;  // ?
	          .F.)  // Nao exclusivo (permite selecionar mais de 1 opcao)
	&(ReadVar ()) := _smvpar  // Devolve Resultado para o parametro do relatorio.
Return .T.
*/
//
// --------------------------------------------------------------------------
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID           F3        Opcoes                                   Help
	aadd (_aRegsPerg, {01, "Data Inicial                  ", "D", 8,  0,  "",             "   ",    {},                                      "Data de emissao inicial das NFs a serem consideradas"})
	aadd (_aRegsPerg, {02, "Data Final                    ", "D", 8,  0,  "",             "   ",    {},                                      "Data de emissao final das NFs a serem consideradas"})
	aadd (_aRegsPerg, {03, "Associado Inicial             ", "C", 6,  0,  "",             "SA2_AS", {},                                      "Codigo do associado (fornecedor) inicial a ser listado"})
	aadd (_aRegsPerg, {04, "Associado Final               ", "C", 6,  0,  "",             "SA2_AS", {},                                      "Codigo do associado (fornecedor) final a ser listado"})
	aadd (_aRegsPerg, {05, "Produto Inicial               ", "C", 15, 0,  "",             "SB1",    {},                                      "Codigo do produto inicial a ser listado"})
	aadd (_aRegsPerg, {06, "Produto Final                 ", "C", 15, 0,  "",             "SB1",    {},                                      "Codigo do produto final a ser listado"})
	aadd (_aRegsPerg, {07, "Formato                       ", "N", 1,  0,  "",             "",       {"Geral","Res.I","Res.II"},              "Geral = nota a nota + resumos; Res.I = totais por associado + produto; Res.II = totais por produto"})
//	aadd (_aRegsPerg, {08, "[Parametro descontinuado]     ", "N", 1,  0,  "",             "",       {},                                      ""})
	aadd (_aRegsPerg, {08, "Considera NF de               ", "N", 1,  0,  "",             "",       {"Entrada","Compra","Compl.preco"},      "Indica se devem ser consideradas as notas de recebimento ou de compra da uva"})
	aadd (_aRegsPerg, {09, "Lista valores                 ", "N", 1,  0,  "",             "",       {"Sim","Nao"},                           "Indica se as colunas de valores devem ser impressas"})
//	aadd (_aRegsPerg, {11, "Tipos de associados a listar  ", "C", 5,  0,  "U_ML_PASS1()", "",       {},                                      ""})
//	aadd (_aRegsPerg, {11, "[Parametro descontinuado]     ", "N", 1,  0,  "",             "",       {},                                      ""})
	aadd (_aRegsPerg, {10, "Tipo produto inicial          ", "C", 2,  0,  "",             "02",     {},                                      ""})
	aadd (_aRegsPerg, {11, "Tipo produto final            ", "C", 2,  0,  "",             "02",     {},                                      ""})
	
//	aadd (_aDefaults, {"11", '12345'})
//	aadd (_aDefaults, {"09", 1})
	aadd (_aDefaults, {"10", ''})
	aadd (_aDefaults, {"11", 'zz'})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
