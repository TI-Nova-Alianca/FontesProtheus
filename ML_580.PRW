//  Programa...: ML_580
//  Autor......: Wagner Xavier
//  Data.......: 05/09/1991
//  Descricao..: Estatistica de Venda por Ordem de Vendedor
// 
// Historico de alteracoes:
// 29/07/2008 - Robert - Alterado nome do relatorio na variavel NomeProg
// 05/06/2010 - Robert - Perguntas ajustadas para versao 10
// 30/06/2010 - Robert - Nome das perguntas mudado de MTR580 para ML_580
// 10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Arquivo de trabalho
//
// -------------------------------------------------------------------------------------------------------
#INCLUDE "MATR580.CH"

User Function ML_580()

	// Define Variaveis                                             
	//Local CbTxt  := ""
	Local titulo := OemToAnsi(STR0001)	//"Faturamento por Vendedor"
	Local cDesc1 := OemToAnsi(STR0002)	//"Este relatorio emite a relacao de faturamento. Podera ser"
	Local cDesc2 := OemToAnsi(STR0003)	//"emitido por ordem de Cliente ou por Valor (Ranking).     "
	Local cDesc3 := OemToAnsi(STR0004)	//"Se no TES estiver gera duplicata (N), nao sera computado."
	//Local CbCont,cabec1,cabec2,wnrel
	Local tamanho:="M"
	//Local limite :=132
	Local cString:="SF2"
	//Local lContinua := .T.
	//Local cMoeda,nMoeda
	//Local cNFiscal
	
	PRIVATE aReturn := { STR0005, 1,STR0006, 1, 2, 1, "",1 }		//"Zebrado"###"Administracao"
	PRIVATE nomeprog:= "ML_580" //"MATR580"
	PRIVATE aLinha  := { },nLastKey := 0
	PRIVATE cPerg   := "ML_580"
	private wnrel   := "ML_580"            //Nome Default do relatorio em Disco
	
	_ValidPerg()
	Pergunte(cPerg,.F.)

	// Variaveis utilizadas para parametros                         
	// mv_par01         // A partir da data                         
	// mv_par02         // Ate a data                               
	// mv_par03         // Do Vendedor                              
	// mv_par04         // Ao Vendedor                              
	// mv_par05         // Por Codigo ou valor                      
	// mv_par06         // Moeda                                    
	// mv_par07         // Inclui Devolu‡„o                         
	// mv_par08         // TES Qto Faturamento                      
	// mv_par09         // TES Qto Estoque                          
	// mv_par10         // Devolucao                                
	// mv_par11         // CGC - Alianca                            
	
	// Envia controle para a funcao SETPRINT                        
	wnrel  := SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,"",,Tamanho)
	
	If nLastKey==27
		Set Filter to
		Return
	Endif
	
	SetDefault(aReturn,cString)
	
	If nLastKey == 27
		Set Filter to
		Return
	Endif
	
	RptStatus({|lEnd| C580Imp(@lEnd,wnRel,cString)},Titulo)
	
Return
// -----------------------------------------------------------------
// Chamada do Relatorio  
Static Function C580Imp(lEnd,WnRel,cString)
	Local titulo := OemToAnsi(STR0001)		//"Faturamento por Vendedor"
	//Local cDesc1 := OemToAnsi(STR0002)		//"Este relatorio emite a relacao de faturamento. Podera ser"
	//Local cDesc2 := OemToAnsi(STR0003)		//"emitido por ordem de Cliente ou por Valor (Ranking).     "
	//Local cDesc3 := OemToAnsi(STR0004)		//"Se no TES estiver gera duplicata (N), nao sera computado."
	Local CbCont,cabec1,cabec2
	Local tamanho:="M"
	//Local limite :=132
	//Local lContinua := .T.
	Local aCampos := {}
	Local aTam	  := {}
	Local nAg1:=0,nAg2:=0,nAg3:=0,nRank:=0,cVend
	//Local nMoeda, cMoeda:="", nValor1, nValor2, nValor3
	Local cEstoq := If( (MV_PAR09 == 1),"S",If( (MV_PAR09 == 2),"N","SN" ) )
	Local cDupli := If( (MV_PAR08 == 1),"S",If( (MV_PAR08 == 2),"N","SN" ) )
	
	Private aTamVal:= { 16, 2 }
	
	Private nDecs:=msdecimais(mv_par06)
	
	nTipo:=IIF(aReturn[4]==1,15,18)
	
	// Variaveis utilizadas para Impressao do Cabecalho e Rodape    
	cbtxt    := SPACE(10)
	cbcont   := 0
	li       :=80
	m_pag    :=1
	nMoeda := mv_par06
	cMoeda := GetMv("MV_MOEDA"+LTrim(STR(nMoeda)))
	
	IF mv_par05 = 1
		titulo := OemToAnsi(STR0007)+cMoeda	//"FATURAMENTO POR VENDEDOR  (CODIGO) - "
	Else
		titulo := OemToAnsi(STR0008)+cMoeda	//"FATURAMENTO POR VENDEDOR  (RANKING) - "
	EndIF
	
	cabec1 := OemToAnsi(STR0009)	//"CODIGO   NOME DO VENDEDOR                                FATURAMENTO          VALOR DA                 VALOR  RANKING"
	cabec2 := OemToAnsi(STR0010)	//"                                                           SEM ICM           MERCADORIA                TOTAL         "
	
	// Cria array para gerar arquivo de trabalho                    
	aTam:=TamSX3("F2_VEND1")
	AADD(aCampos,{ "TB_VEND"   ,"C",aTam[1],aTam[2] } )
	aTam:=TamSX3("F2_EMISSAO")
	AADD(aCampos,{ "TB_EMISSAO","D",aTam[1],aTam[2] } )
	aTam:=TamSX3("F2_VALFAT")
	AADD(aCampos,{ "TB_VALOR1 ","N",aTam[1],aTam[2] } )
	aTam:=TamSX3("F2_VALFAT")
	AADD(aCampos,{ "TB_VALOR2 ","N",aTam[1],aTam[2] } )
	aTam:=TamSX3("F2_VALFAT")
	AADD(aCampos,{ "TB_VALOR3 ","N",aTam[1],aTam[2] } )
	aTam:=TamSX3("F2_DOC")
	AADD(aCampos,{ "TB_DOC    ","C",aTam[1],aTam[2] } )

//	// Cria arquivo de trabalho                                     
//	cNomArq 	:= CriaTrab(aCampos,.T.)
//	dbUseArea( .T.,, cNomArq,"TRB", .T. , .F. )
//	
//	cNomArq1 := Subs(cNomArq,1,7)+"A"
//	
//	IndRegua("TRB",cNomArq1,"TB_VEND",,,STR0011)		//"Selecionando Registros..."
//	aTamVal 	:= TamSX3("F2_VALFAT")
//	cNomArq2 := Subs(cNomArq,1,7)+"B"
//	IndRegua("TRB",cNomArq2,"(STRZERO(TB_VALOR3,aTamVal[1],aTamVal[2]))",,,STR0011)		//"Selecionando Registros..."
//	dbClearIndex()
//	dbSetIndex(cNomArq1+OrdBagExt())
//	dbSetIndexc(cNomArq2+OrdBagExt())
	
	
	// Cria arquivo de trabalho
	_aArqTrb := {}
	U_ArqTrb ("Cria", "TRB", aCampos, {"TB_VEND"}, @_aArqTrb)	
		
	// Chamada da Funcao para gerar arquivo de Trabalho             
	GeraTrab(cEstoq,cDupli)
	
	dbSelectArea("TRB")
	SetRegua(LastRec())
	
	If ( MV_PAR05 = 2 )
		dbSetOrder(2)
	Else
		dbSetOrder(1)
	EndIF
	dbGoBottom()
	cNFiscal := TB_DOC
	While !Bof()
		
		IF lEnd
			@Prow()+1,001 PSAY STR0012		//"CANCELADO PELO OPERADOR"
			Exit
		Endif
		IncRegua()
		If li > 55
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		EndIF
		cVend := TB_VEND
		
		// Verifica se ‚ venda sem vendedor                             
		IF !Empty( cVend )
			dbSelectArea("SA3")
			dbSeek(xFilial()+cVend)
			
			@li,00 PSAY  Left(A3_COD + " " +A3_NOME,48)
		ELSE
			@li,00 PSAY "******" + " " + "Venda Sem Vendedor"
		ENDIF
		
		dbSelectArea("TRB")
		@li,50 PSAY TB_VALOR1 PicTure tm(TB_VALOR1,18,nDecs)
		@li,70 PSAY TB_VALOR2 PicTure tm(TB_VALOR2,18,nDecs)
		@li,90 PSAY TB_VALOR3 PicTure tm(TB_VALOR3,18,nDecs)
		
		IF mv_par05 == 2
			nRank++
			@li,111 PSAY nRank	PicTure "9999"
		EndIF
		li++
		
		nAg1 := nAg1 + TB_VALOR1
		nAg2 := nAg2 + TB_VALOR2
		nAg3 := nAg3 + TB_VALOR3
		
		cNFiscal := TB_DOC
		dbSkip(-1)
	EndDo
	
	IF li != 80
		@li,  0 PSAY STR0014		//"T O T A L --->"
		@li, 50 PSAY nAg1 PicTure tm(nAg1,18,nDecs)
		@li, 70 PSAY nAg2 PicTure tm(nAg2,18,nDecs)
		@li, 90 PSAY nAg3 PicTure tm(nAg3,18,nDecs)
		roda(cbcont,cbtxt)
	EndIF
	
	dbSelectArea( "TRB" )
	dbCloseArea()
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)
//	fErase(cNomArq+GetDBExtension())
//	fErase(cNomArq1+OrdBagExt())
//	fErase(cNomArq2+OrdBagExt())
	
	// Restaura a integridade dos dados                             
	dbSelectArea("SF2")
	Set Filter To
	dbSetOrder(1)
	
	// Se em disco, desvia para Spool                               
	If aReturn[5] == 1    // Se Saida para disco, ativa SPOOL
		Set Printer TO
		dbCommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH()
Return
// -----------------------------------------------------------------------------
// Gera arquivo de Trabalho para emissao de Estat.de Fatur.
Static Function GeraTrab(cEstoq,cDupli)
	Local nContador,nTOTAL,nVALICM,nVALIPI
	Local nVendedor:= Fa440CntVen()
	Local cVendedor:= ""
	Local aVend    := {}
	Local cVend    := ""
	Local aImpostos:= {}
	Local nImpos	:=0.00
	//Local lContinua:= .F.
	Local nMoedNF	 :=	1
	Local nTaxa		:=	0
	Local cNameSD1  :=	""
	Local cNameSF1  :=	""
	Local cNameSD2  :=	""
	Local cNameSF2  :=	""
	Local cNameSF4  :=	""
	Local cFilterQry:=	""
	Local cAddField	:=	""
	Local cQuery	:=	""
	Local cQryAd    :=  ""
	Local cName     :=  ""
	Local aCampos	:=	{}
	Local nCampo	:=	0
	Local cCampo	:=	""
	Local cAliasSD2	:=	""
	Local cAliasSD1	:=	""
	Local cSD2Old	:=	""
	Local cSD1Old	:=	""
	Local aStru		:=	{}
	Local nStru		:=	0
	Local nPos		:=	0
	//Local nValor	:=	0
	Local nX		:=  0
	Local nY		:=  0
	
	Private cCampImp
	
	#IFDEF TOP
		dbSelectArea("SD2")
		dbSetOrder(5)
		dbSelectArea("SD1")
		dbSetOrder(6)
		
		cAliasSD2:=	CriaTrab(,.F.)
		
		cNameSD2 := RetSqlName("SD2")
		cNameSF2 := RetSqlName("SF2")
		cNameSF4 := RetSqlName("SF4")
		
		cAddField	:=	""
		
		If SF2->(FieldPos("F2_TXMOEDA")) > 0
			cAddField += ", F2_TXMOEDA"
		EndIf
		
		If SF2->(FieldPos("F2_MOEDA")) > 0
			cAddField += ", F2_MOEDA"
		EndIf
		
		For nCampo := 0 To 35
			cCampo := "F2_VEND"+Soma1(AllTrim(Str(nCampo)),1)
			If SF2->(FieldPos(cCampo)) > 0
				cFilterQry += "(" + cCampo + " between '" + mv_par03 + "' and '" + mv_par04 + "') or "
				cAddField += ", " + cCampo
			EndIf
		Next nCampo
		
		cQuery := "SELECT  SD2.*, F2_EMISSAO, F2_TIPO, F2_DOC, F2_FRETE, F2_SEGURO, F2_DESPESA, F2_FRETAUT, F2_ICMSRET" + cAddField
		
		// Esta Rotina adiciona a cQuery os campos selecionados pelo usuario  
		// no filtro do usuario.                                              
		aStru := SF2->(dbStruct())
		If !Empty(aReturn[7])
			For nX := 1 To SF2->(FCount())
				cName := SF2->(FieldName(nX))
				If AllTrim( cName ) $ aReturn[7]
					If aStru[nX,2] <> "M"
						If !cName $ cQuery .And. !cName $ cQryAd
							cQryAd += ","+cName
						Endif
					EndIf
				EndIf
			Next nX
		Endif
		cQuery += cQryAd
		
		cQuery += " FROM " + cNameSD2 + " SD2, " + cNameSF4 + " SF4, " + cNameSF2 + " SF2 "
		cQuery += " where D2_FILIAL  = '" + xFilial("SD2") + "'"
		cQuery += " and D2_EMISSAO between '" + DTOS(mv_par01) + "' and '" + DTOS(mv_par02) + "'"
		cQuery += " and D2_TIPO NOT IN ('D', 'B')"
		cQuery += " and F2_FILIAL  = '" + xFilial("SF2") + "'"
		cQuery += " and (" + Left(cFilterQry,Len(cFilterQry)-4) + ")"
		cQuery += " and D2_DOC     = F2_DOC"
		cQuery += " and D2_SERIE   = F2_SERIE"
		cQuery += " and D2_CLIENTE = F2_CLIENTE"
		cQuery += " and D2_LOJA    = F2_LOJA"
		cQuery += " and F4_FILIAL  = '" + xFilial("SF4") + "'"
		cQuery += " and F4_CODIGO  = D2_TES"
		cQuery += " and F4_DUPLIC  = 'S'"
		cQuery += " and SD2.D_E_L_E_T_ = ' '"
		cQuery += " and SF2.D_E_L_E_T_ = ' '"
		cQuery += " and SF4.D_E_L_E_T_ = ' '"
		cQuery += " ORDER BY " + SQLORDER (SD2->(INDEXKEY()))
		
		cQuery := ChangeQuery(cQuery)
		
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD2,.T.,.T.)
		
		aStru := SD2->(dbStruct())
		For nStru := 1 To Len(aStru)
			If aStru[nStru,2] <> "C"
				TcSetField(cAliasSD2,aStru[nStru,1],aStru[nStru,2],aStru[nStru,3],aStru[nStru,4])
			EndIf
		Next nStru
		
		aStru	:= SF2->(dbStruct())
		aCampos	:= {"F2_EMISSAO","F2_FRETE","F2_SEGURO","F2_DESPESA","F2_FRETAUT","F2_ICMSRET"}
		For nCampo := 1 To Len(aCampos)
			nPos := aScan(aStru,{|x|AllTrim(x[1])==aCampos[nCampo]})
			If aStru[nPos,2] <> "C"
				TcSetField(cAliasSD2,aStru[nPos,1],aStru[nPos,2],aStru[nPos,3],aStru[nPos,4])
			EndIf
		Next nCampo
		
		SetRegua(SD2->(LastRec())+SD1->(LastRec()))
		
		// Processa Faturamento                                                    
		While !Eof()
			
			// Processa Filtro do Usuario para Query                                   
			If !Empty(aReturn[7]).And.!&(aReturn[7])
				dbSelectArea(cAliasSD2)
				dbSkip()
				Loop
			Endif
			
			IncRegua()
			nTOTAL :=0
			nVALICM:=0
			nVALIPI:=0
			
			nTaxa	:=	IIf((cAliasSD2)->(FieldPos("F2_TXMOEDA"))>0,(cAliasSD2)->F2_TXMOEDA,0)
			nMoedNF	:=	IIf((cAliasSD2)->(FieldPos("F2_MOEDA"))>0,(cAliasSD2)->F2_MOEDA,0)
			
			If AvalTes((cAliasSD2)->D2_TES,cEstoq,cDupli)
				If cPaisLoc	==	"BRA"
					nVALICM += xMoeda((cAliasSD2)->D2_VALICM,1,mv_par06,(cAliasSD2)->D2_EMISSAO,nDecs+1)
					nVALIPI += xMoeda((cAliasSD2)->D2_VALIPI,1,mv_par06,(cAliasSD2)->D2_EMISSAO,nDecs+1)
				Endif
				nTotal	+=	xMoeda((cAliasSD2)->D2_TOTAL,nMoedNF,mv_par06,(cAliasSD2)->D2_EMISSAO,nDecs+1,nTaxa)
				
				If ( nTotal <> 0 )
					cVendedor := "1"
					For nContador := 1 To nVendedor
						dbSelectArea("TRB")
						dbSetOrder(1)
						cVend := (cAliasSD2)->(FieldGet(FieldPos("F2_VEND"+cVendedor)))
						cVendedor := Soma1(cVendedor,1)
						If cVend >= mv_par03 .And. cVend <= mv_par04
						
							//Se vendedor em branco, considera apenas 1 vez        
							If Empty(cVend) .and. nContador > 1
								Loop
							Endif
							
							If ( aScan(aVend,cVend)==0 )
								Aadd(aVend,cVend)
							EndIf
							If (dbSeek( cVend ))
								RecLock("TRB",.F.)
							Else
								RecLock("TRB",.T.)
							EndIF
							Replace TB_VEND    With cVend
							Replace TB_EMISSAO With (cAliasSD2)->F2_EMISSAO
							Replace TB_VALOR2  With TB_VALOR2+IIF((cAliasSD2)->F2_TIPO == "P",0,nTOTAL)
							If ( cPaisLoc=="BRA" )
								Replace TB_VALOR1  With TB_VALOR1+(nTOTAL-nVALICM)
								Replace TB_VALOR3  With TB_VALOR3+IIF((cAliasSD2)->F2_TIPO == "P",0,nTotal)+nVALIPI
							Else
								Replace TB_VALOR1  With TB_VALOR1+nTOTAL
								Replace TB_VALOR3  With TB_VALOR3+IIF((cAliasSD2)->F2_TIPO == "P",0,nTotal)

								// Pesquiso pelas caracteristicas de cada imposto               
								aImpostos:=TesImpInf((cAliasSD2)->D2_TES)
								For nY:=1 to Len(aImpostos)
									cCampImp:= (cAliasSD2)+"->"+(aImpostos[nY][2])
									nImpos	:=	xMoeda(&cCampImp.,nMoedNF,mv_par06,(cAliasSD2)->D2_EMISSAO,nDecs+1,nTaxa)
									If ( aImpostos[nY][3]=="1" )
										Replace TB_VALOR3  With TB_VALOR3 + nImpos
									Else
										Replace TB_VALOR1  With TB_VALOR1 - nImpos
									EndIf
								Next
							EndIf
							Replace TB_DOC	    With (cAliasSD2)->F2_DOC
							MsUnlock()
						Endif
					Next nContador
				EndIf
			EndIf
			
			dbSelectArea(cAliasSD2)
			cSD2Old	:= (cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA
			nValor3 := xMoeda((cAliasSD2)->F2_FRETE+(cAliasSD2)->F2_SEGURO+(cAliasSD2)->F2_DESPESA+(cAliasSD2)->F2_FRETAUT+(cAliasSD2)->F2_ICMSRET,nMoedNF,mv_par06,(cAliasSD2)->F2_EMISSAO,nDecs+1,nTaxa)
			dbSkip()
			If Eof() .Or. ( (cAliasSD2)->D2_DOC+(cAliasSD2)->D2_SERIE+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA!= cSD2Old )
				For nContador := 1 To Len(aVend)
					dbSelectArea("TRB")
					dbSetOrder(1)
					dbSeek(aVend[1])
					RecLock("TRB",.F.)
					TRB->TB_VALOR3	+= nValor3
					nValor3 		:= 0
					MsUnLock()
				Next nContador
				aVend := {}
			EndIf
			dbSelectArea(cAliasSD2)
		EndDo
		dbCloseArea(cAliasSD2)
		
		// Processa Devolucao                                                      
		If ( MV_PAR07 == 1 )
			
			cAliasSD1:=	CriaTrab(,.F.)
			
			cNameSD1 := RetSqlName("SD1")
			cNameSF1 := RetSqlName("SF1")
			
			cAddField	:=	""
			
			If cPaisLoc == "BRA"
				For nCampo := 0 To 35
					cCampo := "F2_VEND"+Soma1(AllTrim(Str(nCampo)),1)
					If SF2->(FieldPos(cCampo)) > 0
						cFilterQry += "(" + cCampo + " between '" + mv_par03 + "' and '" + mv_par04 + "') or "
						cAddField	+= ", " + cCampo
					EndIf
				Next nCampo
			Else
				For nCampo := 0 To 35
					cCampo := "F1_VEND"+Soma1(AllTrim(Str(nCampo)),1)
					If SF1->(FieldPos(cCampo)) > 0
						cFilterQry += "(" + cCampo + " between '" + mv_par03 + "' and '" + mv_par04 + "') or "
						cAddField	+= ", " + cCampo
					EndIf
				Next nCampo
				If SF1->(FieldPos("F1_TXMOEDA")) > 0
					cAddField += ", F1_TXMOEDA"
				EndIf
				If SF1->(FieldPos("F1_MOEDA")) > 0
					cAddField += ", F1_MOEDA"
				EndIf
				If SF1->(FieldPos("F1_FRETINC")) > 0
					cAddField += ", F1_FRETINC"
				EndIf
			EndIf
			
			cQuery := "select SD1.*, F1_EMISSAO, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_FRETE, F1_DESPESA, F1_SEGURO, F1_ICMSRET, F1_DTDIGIT" + cAddField
			cQuery += " from " + cNameSD1 + " SD1, " + cNameSF4 + " SF4, " + cNameSF2 + " SF2, " + cNameSF1 + " SF1 "
			cQuery += " where D1_FILIAL  = '" + xFilial("SD1") + "'"
			cQuery += " and D1_DTDIGIT between '" + DTOS(mv_par01) + "' and '" + DTOS(mv_par02) + "'"
			cQuery += " and D1_TIPO = 'D'"
			cQuery += " and F4_FILIAL  = '" + xFilial("SF4") + "'"
			cQuery += " and F4_CODIGO  = D1_TES"
			cQuery += " and F4_DUPLIC  = 'S'"
			cQuery += " and F2_FILIAL  = '" + xFilial("SF2") + "'"
			cQuery += " and F2_DOC     = D1_NFORI   "
			cQuery += " and F2_SERIE   = D1_SERIORI "
			cQuery += " and F2_CLIENTE = D1_FORNECE "
			cQuery += " and F2_LOJA    = D1_LOJA "
			cQuery += " and F1_FILIAL  = '" + xFilial("SF1") + "'"
			cQuery += " and F1_DOC     = D1_DOC     "
			cQuery += " and F1_SERIE   = D1_SERIE"
			cQuery += " and F1_FORNECE = D1_FORNECE"
			cQuery += " and F1_LOJA    = D1_LOJA"
			cQuery += " and SD1.D_E_L_E_T_ = ' '"
			cQuery += " and SF4.D_E_L_E_T_ = ' '"
			cQuery += " and SF2.D_E_L_E_T_ = ' '"
			cQuery += " and SF1.D_E_L_E_T_ = ' '"
			cQuery += " and (" + Left(cFilterQry,Len(cFilterQry)-4) + ")"
			cQuery += " ORDER BY " + SQLORDER (SD1->(INDEXKEY()))
			
			cQuery := ChangeQuery(cQuery)
			
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD1,.T.,.T.)
			
			aStru := SD1->(dbStruct())
			For nStru := 1 To Len(aStru)
				If aStru[nStru,2] <> "C"
					TcSetField(cAliasSD1,aStru[nStru,1],aStru[nStru,2],aStru[nStru,3],aStru[nStru,4])
				EndIf
			Next nStru
			
			aStru	:= SF1->(dbStruct())
			aCampos	:= {"F1_EMISSAO","F1_FRETE","F1_DESPESA","F1_SEGURO","F1_ICMSRET","F1_DTDIGIT"}
			For nCampo := 1 To Len(aCampos)
				nPos := aScan(aStru,{|x|AllTrim(x[1])==aCampos[nCampo]})
				If aStru[nPos,2] <> "C"
					TcSetField(cAliasSD1,aStru[nPos,1],aStru[nPos,2],aStru[nPos,3],aStru[nPos,4])
				EndIf
			Next nCampo
			
			While !Eof()
				IncRegua()
				nTOTAL :=0
				nVALICM:=0
				nVALIPI:=0
				
				If cPaisLoc == "BRA"
					If AvalTes((cAliasSD1)->D1_TES,cEstoq,cDupli)
						nVALICM := xMoeda((cAliasSD1)->D1_VALICM,1,mv_par06,(cAliasSD1)->D1_DTDIGIT,nDecs+1)
						nVALIPI := xMoeda((cAliasSD1)->D1_VALIPI,1,mv_par06,(cAliasSD1)->D1_DTDIGIT,nDecs+1)
						nTOTAL  := xMoeda(((cAliasSD1)->D1_TOTAL - (cAliasSD1)->D1_VALDESC),1,mv_par06,(cAliasSD1)->D1_DTDIGIT,nDecs+1)
						cVendedor := "1"
						For nContador := 1 TO nVendedor
							dbSelectArea("TRB")
							dbSetOrder(1)
							cVend := (cAliasSD1)->(FieldGet((cAliasSD1)->(FieldPos("F2_VEND"+cVendedor))))
							cVendedor := Soma1(cVendedor,1)
							If cVend >= MV_PAR03 .And. cVend <= MV_PAR04
								If Empty(cVend) .and. nContador > 1
									Loop
								EndIf
								If ( aScan(aVend,cVend) == 0 )
									AADD(aVend,cVend)
								EndIf
								If nTOTAL > 0
									If (dbSeek( cVend ))
										RecLock("TRB",.F.)
									Else
										RecLock("TRB",.T.)
									EndIf
									Replace TB_VEND    With cVend
									Replace TB_EMISSAO With (cAliasSD1)->F1_EMISSAO
									Replace TB_VALOR2  With TB_VALOR2-nTOTAL
									Replace TB_VALOR1  With TB_VALOR1-(nTOTAL-nVALICM)
									Replace TB_VALOR3  With TB_VALOR3-nTOTAL-nVALIPI
									Replace TB_DOC	    With (cAliasSD1)->F1_DOC
									MsUnlock()
								EndIf
							Endif
						Next nContador
					EndIf
				Else
					If AvalTes((cAliasSD1)->D1_TES,cEstoq,cDupli)
						nTaxa	:=	IIf((cAliasSD1)->(FieldPos("F1_TXMOEDA"))>0,(cAliasSD1)->F1_TXMOEDA,0)
						nMoedNF	:=	IIF((cAliasSD1)->(FieldPos("F1_MOEDA"))>0,(cAliasSD1)->F1_MOEDA,1)
						nTOTAL	:= xMoeda(((cAliasSD1)->D1_TOTAL - (cAliasSD1)->D1_VALDESC),nMoedNF,mv_par06,(cAliasSD1)->D1_DTDIGIT,nDecs+1,nTaxa)
						cVendedor := "1"
						For nContador := 1 TO 1
							dbSelectArea("TRB")
							dbSetOrder(1)
							cVend := (cAliasSD1)->(FieldGet((cAliasSD1)->(FieldPos("F1_VEND"+cVendedor))))
							cVendedor := Soma1(cVendedor,1)
							If cVend >= MV_PAR03 .And. cVend <= MV_PAR04
								If Empty(cVend) .and. nContador > 1
									Loop
								EndIf
								If ( aScan(aVend,cVend) == 0 )
									AADD(aVend,cVend)
								EndIf
								If nTOTAL > 0
									If (dbSeek( cVend ))
										RecLock("TRB",.F.)
									Else
										RecLock("TRB",.T.)
									EndIf
									Replace TB_VEND    With cVend
									Replace TB_EMISSAO With (cAliasSD1)->F1_EMISSAO
									Replace TB_VALOR2  With TB_VALOR2-nTOTAL
									Replace TB_VALOR1  With TB_VALOR1-nTOTAL
									Replace TB_VALOR3  With TB_VALOR3-nTotal

									// Pesquiso pelas caracteristicas de cada imposto               
									aImpostos:=TesImpInf((cAliasSD1)->D1_TES)
									For nY:=1 to Len(aImpostos)
										cCampImp:="SD1->"+(aImpostos[nY][2])
										nImpos	:=	xMoeda(&cCampImp.,nMoedNF,mv_par06,(cAliasSD1)->D1_DTDIGIT,nDecs+1,nTaxa)
										If ( aImpostos[nY][3]=="1" )
											Replace TB_VALOR3  With TB_VALOR3 - nImpos
										Else
											Replace TB_VALOR1  With TB_VALOR1 + nImpos
										EndIf
									Next nY
									Replace TB_DOC	    With (cAliasSD1)->F1_DOC
								Endif
								MsUnlock()
							EndIf
						Next nContador
					Endif
				Endif
				
				dbSelectArea(cAliasSD1)
				cSD1Old := (cAliasSD1)->D1_DOC+(cAliasSD1)->D1_SERIE+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA
				If ( cPaisLoc=="BRA")
					nValor3	:= xMoeda((cAliasSD1)->F1_FRETE+(cAliasSD1)->F1_DESPESA+(cAliasSD1)->F1_SEGURO+(cAliasSD1)->F1_ICMSRET,1,mv_par06,(cAliasSD1)->F1_DTDIGIT,nDecs+1)
				Else
					nValor3	:= xMoeda(IIf((cAliasSD1)->(FieldPos("F1_FRETINC"))>0.And.(cAliasSD1)->F1_FRETINC<> "S",;
					(cAliasSD1)->F1_FRETE,0);
					+(cAliasSD1)->F1_DESPESA,nMoedNF,mv_par06,(cAliasSD1)->F1_DTDIGIT,nDecs+1,nTaxa)
				EndIf
				dbSkip()
				
				If Eof() .Or. ( (cAliasSD1)->D1_DOC+(cAliasSD1)->D1_SERIE+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA != cSD1Old)
					FOR nContador := 1 TO Len(aVend)
						dbSelectArea("TRB")
						dbSetOrder(1)
						cVend := aVend[nContador]
						dbSeek( cVend )
						RecLock("TRB",.F.)
						Replace TB_VALOR3  With TB_VALOR3-nValor3
						nValor3	:= 0
						MsUnlock()
					Next nContador
					aVend:={}
				EndIf
				dbSelectArea(cAliasSD1)
			EndDo
			dbCloseArea(cAliasSD1)
		EndIf
	#ELSE
		dbSelectArea("SD2")
		dbSetOrder(5)
		dbSeek(xFilial("SD2")+Dtos(MV_PAR01),.T.)
		SetRegua(SD2->(LastRec())+SD1->(LastRec()))
		
		// Processa Faturamento                                                    
		While ( !Eof() .And. xFilial("SD2")  == SD2->D2_FILIAL .And.;
			SD2->D2_EMISSAO <= MV_PAR02 )
			IncRegua()
			nTOTAL :=0
			nVALICM:=0
			nVALIPI:=0
			
			//
			DbSelectArea("SA1")   // Cadastro de Clientes
			DbSetOrder(1)
			DbSeek(xFilial()+SD2->D2_CLIENTE+SD2->D2_LOJA)
			If Found()
				_xCNPJ := SA1->A1_CGC
			Else
				_xCNPJ := Replicate("Z",14)
			Endif
			
			If !Empty(mv_par11)
				_xlenpar := Len(Alltrim(mv_par11))
				If !(Left(mv_par11,_xlenpar) $ _xCNPJ )
					DbSelectArea("SD2")
					DbSkip()
					Loop
				Endif
			Endif

			If ( !SD2->D2_TIPO $ "DB" )
				dbSelectArea("SF2")
				dbSetOrder(1)
				lContinua := dbSeek(xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA)
				
				dbSelectArea("SF4")
				dbSetOrder(1)
				dbSeek(xFilial("SF2")+SD2->D2_TES)
				nTaxa		:=	IIf(Type("SF2->F2_TXMOEDA")=="U",0,SF2->F2_TXMOEDA)
				nMoedNF	:=	IIF(Type("SF2->F2_MOEDA")  =="U",1,SF2->F2_MOEDA)
				dbSelectArea("SD2")
				If lContinua .And. AvalTes(D2_TES,cEstoq,cDupli)
					
					If SF4->F4_DUPLIC=="S"
						If cPaisLoc	==	"BRA"
							nVALICM += xMoeda(SD2->D2_VALICM,1,mv_par06,SD2->D2_EMISSAO,nDecs+1)
							nVALIPI += xMoeda(SD2->D2_VALIPI,1,mv_par06,SD2->D2_EMISSAO,nDecs+1)
						Endif
						nTotal	+=	xMoeda(SD2->D2_TOTAL,nMoedNF,mv_par06,SD2->D2_EMISSAO,nDecs+1,nTaxa)
					Endif
					
					If ( nTotal <> 0 )
						cVendedor := "1"
						For nContador := 1 To nVendedor
							dbSelectArea("TRB")
							dbSetOrder(1)
							cVend := SF2->(FieldGet( FieldPos("F2_VEND"+cVendedor)))
							cVendedor := Soma1(cVendedor,1)
							If cVend >= mv_par03 .And. cVend <= mv_par04
							
								//Se vendedor em branco, considera apenas 1 vez        
								If Empty(cVend) .and. nContador > 1
									Loop
								Endif
								
								If ( aScan(aVend,cVend)==0 )
									Aadd(aVend,cVend)
								EndIf
								If (dbSeek( cVend ))
									RecLock("TRB",.F.)
								Else
									RecLock("TRB",.T.)
								EndIF
								Replace TB_VEND    With cVend
								Replace TB_EMISSAO With SF2->F2_EMISSAO
								Replace TB_VALOR2  With TB_VALOR2+IIF(SF2->F2_TIPO == "P",0,nTOTAL)
								If ( cPaisLoc=="BRA" )
									Replace TB_VALOR1  With TB_VALOR1+(nTOTAL-nVALICM)
									Replace TB_VALOR3  With TB_VALOR3+IIF(SF2->F2_TIPO == "P",0,nTotal)+nVALIPI
								Else
									Replace TB_VALOR1  With TB_VALOR1+nTOTAL
									Replace TB_VALOR3  With TB_VALOR3+IIF(SF2->F2_TIPO == "P",0,nTotal)
									
									// Pesquiso pelas caracteristicas de cada imposto               
									aImpostos:=TesImpInf(SD2->D2_TES)
									For nY:=1 to Len(aImpostos)
										cCampImp:="SD2->"+(aImpostos[nY][2])
										nImpos	:=	xMoeda(&cCampImp.,nMoedNF,mv_par06,SD2->D2_EMISSAO,nDecs+1,nTaxa)
										If ( aImpostos[nY][3]=="1" )
											Replace TB_VALOR3  With TB_VALOR3 + nImpos
										Else
											Replace TB_VALOR1  With TB_VALOR1 - nImpos
										EndIf
									Next
								EndIf
								Replace TB_DOC	    With SF2->F2_DOC
								MsUnlock()
							Endif
						Next nContador
					EndIf
				EndIf
			EndIf
			dbSelectArea("SD2")
			dbSkip()
			If lContinua .And. ( xFilial("SF2")+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA!=;
				SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA )
				For nContador := 1 To Len(aVend)
					dbSelectArea("TRB")
					dbSetOrder(1)
					dbSeek(aVend[1])
					RecLock("TRB",.F.)
					TRB->TB_VALOR3 += xMoeda(SF2->F2_FRETE+SF2->F2_SEGURO+SF2->F2_DESPESA+SF2->F2_FRETAUT+SF2->F2_ICMSRET,nMoedNF,mv_par06,SF2->F2_EMISSAO,nDecs+1,nTaxa)
					MsUnLock()
				Next nContador
				aVend := {}
			EndIf
			dbSelectArea("SD2")
		EndDo

		//Processa Devolucao                                                      
		If ( MV_PAR07 == 1 )
			dbSelectArea("SD1")
			dbSetOrder(6)
			dbSeek(xFilial("SD1")+Dtos(MV_PAR01),.T.)
			While ( !Eof() .And. xFilial("SD1")  == SD1->D1_FILIAL .And.;
				SD1->D1_DTDIGIT <= MV_PAR02 )
				IncRegua()
				nTOTAL :=0
				nVALICM:=0
				nVALIPI:=0
				
				dbSelectArea("SF4")
				dbSetOrder(1)
				dbSeek(xFilial("SF4")+SD1->D1_TES)
				
				If cPaisLoc == "BRA"
					dbSelectArea("SD1")
					If AvalTes(D1_TES,cEstoq,cDupli)
						If ( SD1->D1_TIPO $ "D" )
							dbSelectArea("SF1")
							dbSetOrder(1)
							dbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA)
							nVALICM := xMoeda(SD1->D1_VALICM,1,mv_par06,SD1->D1_DTDIGIT,nDecs+1)
							nVALIPI := xMoeda(SD1->D1_VALIPI,1,mv_par06,SD1->D1_DTDIGIT,nDecs+1)
							nTOTAL  := xMoeda((SD1->D1_TOTAL - SD1->D1_VALDESC),1,mv_par06,SD1->D1_DTDIGIT,nDecs+1)
							cVendedor := "1"
							dbSelectArea("SF2")
							dbSetOrder(1)
							If ( dbSeek(xFilial()+SD1->D1_NFORI+SD1->D1_SERIORI) )
								For nContador := 1 TO nVendedor
									dbSelectArea("TRB")
									dbSetOrder(1)
									cVend := SF2->(FieldGet(FieldPos("F2_VEND"+cVendedor)))
									cVendedor := Soma1(cVendedor,1)
									If cVend >= MV_PAR03 .And. cVend <= MV_PAR04
										If Empty(cVend) .and. nContador > 1
											Loop
										EndIf
										If ( aScan(aVend,cVend) == 0 )
											AADD(aVend,cVend)
										EndIf
										If nTOTAL > 0
											If (dbSeek( cVend ))
												RecLock("TRB",.F.)
											Else
												RecLock("TRB",.T.)
											EndIf
											Replace TB_VEND    With cVend
											Replace TB_EMISSAO With SF1->F1_EMISSAO
											Replace TB_VALOR2  With TB_VALOR2-nTOTAL
											Replace TB_VALOR1  With TB_VALOR1-(nTOTAL-nVALICM)
											Replace TB_VALOR3  With TB_VALOR3-nTOTAL-nVALIPI
											Replace TB_DOC	    With SF1->F1_DOC
											MsUnlock()
										EndIf
									Endif
								Next nContador
							EndIf
						EndIf
					EndIf
				Else
					If AvalTes(SD1->D1_TES,cEstoq,cDupli)
						If ( SD1->D1_TIPO $ "D" )
							dbSelectArea("SF1")
							dbSetOrder(1)
							dbSeek(xFilial("SF1")+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA)
							nTaxa		:=	IIf(Type("SF1->F1_TXMOEDA")=="U",0,SF1->F1_TXMOEDA)
							nMoedNF	:=	IIF(Type("SF1->F1_MOEDA")  =="U",1,SF1->F1_MOEDA)
							
							nTOTAL  := xMoeda((SD1->D1_TOTAL - SD1->D1_VALDESC),nMoedNF,mv_par06,SD1->D1_DTDIGIT,nDecs+1,nTaxa)
							cVendedor := "1"
							For nContador := 1 TO 1
								dbSelectArea("TRB")
								dbSetOrder(1)
								cVend := SF1->(FieldGet(FieldPos("F1_VEND"+cVendedor)))
								cVendedor := Soma1(cVendedor,1)
								If cVend >= MV_PAR03 .And. cVend <= MV_PAR04
									If Empty(cVend) .and. nContador > 1
										Loop
									EndIf
									If ( aScan(aVend,cVend) == 0 )
										AADD(aVend,cVend)
									EndIf
									If nTOTAL > 0
										If (dbSeek( cVend ))
											RecLock("TRB",.F.)
										Else
											RecLock("TRB",.T.)
										EndIf
										Replace TB_VEND    With cVend
										Replace TB_EMISSAO With SF1->F1_EMISSAO
										Replace TB_VALOR2  With TB_VALOR2-nTOTAL
										Replace TB_VALOR1  With TB_VALOR1-nTOTAL
										Replace TB_VALOR3  With TB_VALOR3-nTotal
										
										// Pesquiso pelas caracteristicas de cada imposto               
										aImpostos:=TesImpInf(SD1->D1_TES)
										For nY:=1 to Len(aImpostos)
											cCampImp:="SD1->"+(aImpostos[nY][2])
											nImpos	:=	xMoeda(&cCampImp.,nMoedNF,mv_par06,SD1->D1_DTDIGIT,nDecs+1,nTaxa)
											If ( aImpostos[nY][3]=="1" )
												Replace TB_VALOR3  With TB_VALOR3 - nImpos
											Else
												Replace TB_VALOR1  With TB_VALOR1 + nImpos
											EndIf
										Next nY
										Replace TB_DOC	    With SF1->F1_DOC
									Endif
									MsUnlock()
								EndIf
							Next nContador
						EndIf
					Endif
				Endif
				dbSelectArea("SD1")
				dbSkip()
				If ( SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA !=;
					xFilial("SF1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA )
					FOR nContador := 1 TO Len(aVend)
						dbSelectArea("TRB")
						dbSetOrder(1)
						cVend := aVend[nContador]
						dbSeek( cVend )
						RecLock("TRB",.F.)
						If ( cPaisLoc=="BRA")
							Replace TB_VALOR3  With TB_VALOR3-xMoeda(SF1->F1_FRETE+SF1->F1_DESPESA+SF1->F1_SEGURO+SF1->F1_ICMSRET,1,mv_par06,SF1->F1_DTDIGIT,nDecs+1)
						Else
							Replace TB_VALOR3  With TB_VALOR3-xMoeda(IIf(Type("SF1->F1_FRETINC")#"U".And.SF1->F1_FRETINC<> "S",;
							SF1->F1_FRETE,0);
							+SF1->F1_DESPESA,nMoedNF,mv_par06,SF1->F1_DTDIGIT,nDecs+1,nTaxa)
						EndIf
						MsUnlock()
					Next nContador
					aVend:={}
				EndIf
				dbSelectArea("SD1")
			EndDo
		EndIf
	#ENDIF
	
Return .T.
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Da data                       ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Ate a data                    ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Do vendedor                   ", "C", 6,  0,  "",   "SA3", {},    ""})
	aadd (_aRegsPerg, {04, "Ate o vendedor                ", "C", 6,  0,  "",   "SA3", {},    ""})
	aadd (_aRegsPerg, {05, "Ordem (decrescente)           ", "N", 1,  0,  "",   "   ", {"Vendedor", "Rankig"},                                  ""})
	aadd (_aRegsPerg, {06, "Moeda                         ", "N", 1,  0,  "",   "   ", {"Moeda 1", "Moeda 2", "Moeda 3", "Moeda 4", "Moeda 5"}, ""})
	aadd (_aRegsPerg, {07, "Inclui devolucao              ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"},                                          ""})
	aadd (_aRegsPerg, {08, "TES quanto a faturamento      ", "N", 1,  0,  "",   "   ", {"Gera", "Nao gera", "Ambos"},                           ""})
	aadd (_aRegsPerg, {09, "TES quanto a estoque          ", "N", 1,  0,  "",   "   ", {"Movimenta", "Nao movimenta", "Ambos"},                 ""})
	aadd (_aRegsPerg, {10, "Converte moeda devolucao      ", "N", 1,  0,  "",   "   ", {"Pela devolucao", "Pela dt.NF orig"},                   ""})
	aadd (_aRegsPerg, {11, "CNPJ Cliente                  ", "C", 14, 0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
