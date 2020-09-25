// Programa:   _SRF194
// Autor:      Robert Koch
// Data:       10/09/2010
// Descricao:  Customizacao da rotina SRF194 para geracao do arquivo de exportacao
//             de notas fiscais para a DIPI.
//             Deve ser chamado pelo arquivo SRF325A.INI via rotina de Instrucoes Normativas.
//             Criado com base no SRF194 de Eduardo Riera.
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
user Function _SRF194(nTipo,dDataIni,dDataFim,aControle,nSrf, nVersao)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³SRF194    ³ Autor ³Eduardo Riera          ³ Data ³23.01.2003³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Preparacao dos arquivos para serem utilizados na SRF194     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: [1] Inicializacao                                    ³±±
±±³          ³       [2] Finalizacao                                      ³±±
±±³          ³ExpD2: Data Inicial                                         ³±±
±±³          ³ExpD3: Data Final                                           ³±±
±±³          ³ExpA4: Array de Controle                                    ³±±
±±³          ³ExpN5: [1] SRF194 - DIF CIGARROS                            ³±±
±±³          ³       [2] SRF325 - DIF BEBIDAS                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Local aArea     := GetArea()
Local aStruSF3  := SF3->(dbStruct())
Local aStruSD1  := SD1->(dbStruct())
Local aStruSD2  := SD2->(dbStruct())
Local cAliasSD1 := "SD1"
Local cAliasSD2 := "SD2"
Local cAliasSF3 := "SF3"
Local cAliasSB1 := "SB1"
Local cKey      := ""
Local cArqSF3   := ""
Local cQuery    := ""
Local cChave    := ""
Local lQuery    := .F.
Local lGravou   := .F.
Local lValido   := .F.
Local nX        := 0
Local nItem     := 0
Local cPosIPI   := ""
#IFDEF TOP
	Local cAliasSB5 := "SB5"
#ENDIF	
nSrf    := iif (nSrf == NIL, 1, nSrf)
nVersao := iif (nVersao == NIL, 0, nVersao)

If nTipo == 1
	// u_log ("tipo 1")
	// u_log ("Antes da query: F3Filial ('SD1'):",F3Filial("SD1"))
	// u_log ("Antes da query: F3Filial ('SF3'):",F3Filial("SF3"))
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria os arquivo temporarios para a normativa - SRF194        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aadd(aStruSD1,{"D1_POSIPI","C",10,0})
	aadd(aStruSD2,{"D2_POSIPI","C",10,0})
	If nSrf == 2
		aadd(aStruSD1,{"D1_ITEMNF","C",03,0})
		aadd(aStruSD2,{"D2_ITEMNF","C",03,0})
	Endif
	aControle := {}
	
	aadd (aStruSF3, {"F3_FILA1", "C", 2, 0})
	aadd (aStruSF3, {"F3_FILA2", "C", 2, 0})
	aadd (aStruSF3, {"F3_FILF1", "C", 2, 0})
	aadd (aStruSF3, {"F3_FILF2", "C", 2, 0})

	aadd(aControle,{"TRB",CriaTrab(aStruSF3,.T.)})
	dbUseArea(.T.,__LocalDrive,aControle[1,2],"TRB")
	IndRegua("TRB",aControle[1,2],"F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+Dtos(F3_EMISSAO)")	
	aadd(aControle,{"TR2",CriaTrab(aStruSD2,.T.)})
	dbUseArea(.T.,__LocalDrive,aControle[2,2],"TR2")
	IndRegua("TR2",aControle[2,2],"D2_SERIE+D2_DOC+D2_CLIENTE+D2_LOJA+D2_POSIPI")

	aadd (aStruSD1, {"D1_FILB1", "C", 2, 0})
	aadd (aStruSD1, {"D1_FILB5", "C", 2, 0})

	aadd(aControle,{"TR3",CriaTrab(aStruSD1,.T.)})
	dbUseArea(.T.,__LocalDrive,aControle[3,2],"TR3")
	If nSrf == 1
		IndRegua("TR3",aControle[3,2],"D1_SERIE+D1_DOC+D1_FORNECE+D1_LOJA+D1_POSIPI")
	ElseIf nSrf == 2
		IndRegua("TR3",aControle[3,2],"D1_SERIE+D1_DOC+D1_FORNECE+D1_LOJA+D1_POSIPI+D1_CF+D1_ITEM")
	Endif
	dbSelectArea("SF3")
	cKey   := "F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+Dtos(F3_EMISSAO)"
	#IFDEF TOP
		cAliasSF3 := "SRF194SF3"
		
		lQuery := .T.
		cQuery := "SELECT * "
		cQuery += "FROM "+RetSqlName("SF3")+" SF3 "
		cQuery += "WHERE "
		cQuery += "F3_FILIAL = '"+xFilial("SF3")+"' AND "
		cQuery += "F3_ENTRADA >= '"+Dtos(dDataIni)+"' AND "
		cQuery += "F3_ENTRADA <= '"+Dtos(dDataFim)+"' AND "
		cQuery += "SF3.D_E_L_E_T_=' ' "
		
		cQuery := ChangeQuery(cQuery)
		// u_log (cquery)
	
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSF3)	
		For nX := 1 To Len(aStruSF3)
			If aStruSF3[nX][2]<>"C"
				TcSetField(cAliasSF3,aStruSF3[nX][1],aStruSF3[nX][2],aStruSF3[nX][3],aStruSF3[nX][4])
			EndIf
		Next nX
	#ELSE
		cQuery := "F3_FILIAL=='"+xFilial("SF3")+"' .AND. "
		cQuery += "DTOS(F3_ENTRADA) >= '"+Dtos(dDataIni)+"' .AND. "
		cQuery += "DTOS(F3_ENTRADA) <= '"+Dtos(dDataFim)+"' "
		cArqSF3 := CriaTrab(,.F.)
		IndRegua("SF3",cArqSF3,cKey,,cQuery)
		dbGotop()
	#ENDIF
	// u_log ("Depois da query: F3Filial ('SD1'):",F3Filial("SD1"))
	// u_log ("Depois da query: F3Filial ('SF3'):",F3Filial("SF3"))
	// u_logtrb (cAliasSF3, .t.)
	dbSelectArea(cAliasSF3)
	dbgotop ()
	While !Eof()
		lGravou := .F.
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se eh entrada ou saida                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If SubStr((cAliasSF3)->F3_CFO,1,1) < "5"
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Tratamento para Entrada                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			#IFDEF TOP
				lQuery := .T.
				cAliasSB1 := "SRF194SD1"
				cAliasSD1 := "SRF194SD1"
				cAliasSB5 := "SRF194SD1"
				
			    cQuery := "SELECT SD1.*,SB1.B1_POSIPI "
			    cQuery += "FROM "+RetSqlName("SD1")+" SD1, "
			    cQuery += RetSqlName("SB1")+" SB1,"
			    cQuery += RetSqlName("SB5")+" SB5 "
			    //cQuery += "WHERE SD1.D1_FILIAL='"+F3Filial("SD1")+"' AND "
			    cQuery += "WHERE SD1.D1_FILIAL='"+xFilial("SD1")+"' AND "
			    cQuery += "SD1.D1_DOC='"+(cAliasSF3)->F3_NFISCAL+"' AND "
			    cQuery += "SD1.D1_SERIE='"+(cAliasSF3)->F3_SERIE+"' AND "
			    cQuery += "SD1.D1_FORNECE='"+(cAliasSF3)->F3_CLIEFOR+"' AND "
			    cQuery += "SD1.D1_LOJA='"+(cAliasSF3)->F3_LOJA+"' AND "
			    cQuery += "SD1.D_E_L_E_T_=' ' AND "
			    cQuery += "SB1.B1_FILIAL='"+xFilial("SB1")+"' AND "
			    cQuery += "SB1.B1_COD=SD1.D1_COD AND "
	   		    If nSrf == 1
		   		    If nVersao==30
		   		    	cQuery += "SB1.B1_POSIPI IN('39202019', '39202090','55020010','56012190','56012291','48132000','48139000','76072000') AND "
		   		    	cQuery += "SD1.D1_TIPO NOT IN ('C','I','P') AND "
		   		    Else
			   		    cQuery += "SB1.B1_POSIPI IN('39202019', '24022000','39202090','55020010','56012190','56012291','48132000','48139000','76072000') AND "
		   		    EndIf
	   		    ElseIf nSrf == 2
		   		    cQuery += "(SB1.B1_POSIPI IN('39011010','39011091','39011092','39012011','39012019','39012021','39012029') OR "
		   		    cQuery += "SB1.B1_POSIPI IN('39021010','39021020','39023000','39076000','39232110','39232190','39233000') OR "
					cQuery += "SB1.B1_POSIPI IN('39235000','45031000','48115122','48115923','70109011','70109021','70109090') OR "
					cQuery += "SB1.B1_POSIPI IN('73102110','73102910','76129019','83091000','83099000') ) AND "
	   		    Endif	
			    cQuery += "SB1.D_E_L_E_T_=' ' AND "
			    cQuery += "SB5.B5_FILIAL='"+xFilial("SB5")+"' AND "
	   		    cQuery += "SB5.B5_COD=SD1.D1_COD AND "
	   		    cQuery += "SB5.D_E_L_E_T_=' '  "
	   		    
	   		    cQuery := ChangeQuery(cQuery)
	   		    // u_log (cquery)
	   		    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD1)
	   		    if ! eof ()
	   		    	// u_log ("Achou algo no SD1")
	   		    endif
	   		    For nX := 1 To Len(aStruSD1)
	   		    	If aStruSD1[nX][2]<>"C"
						TcSetField(cAliasSD1,aStruSD1[nX][1],aStruSD1[nX][2],aStruSD1[nX][3],aStruSD1[nX][4])
					EndIf
	   		    Next nX
			
			#ELSE		
				dbSelectArea("SD1")
				dbSetOrder(1)		
				MsSeek(F3Filial("SD1")+(cAliasSF3)->F3_NFISCAL+(cAliasSF3)->F3_SERIE+(cAliasSF3)->F3_CLIEFOR+(cAliasSF3)->F3_LOJA)
			#ENDIF
			nItem := 1
			While !Eof() .And. ; //F3Filial("SD1") == xFilial("SD1") .And.;
				(cAliasSF3)->F3_NFISCAL == (cAliasSD1)->D1_DOC .And.;
				(cAliasSF3)->F3_SERIE == (cAliasSD1)->D1_SERIE .And.;
				(cAliasSF3)->F3_CLIEFOR == (cAliasSD1)->D1_FORNECE .And.;
				(cAliasSF3)->F3_LOJA == (cAliasSD1)->D1_LOJA
				lValido := .F.
				// u_log ("No while da query")
				If !lQuery
					dbSelectArea("SB1")
					dbSetOrder(1)
					MsSeek(xFilial("SB1")+(cAliasSD1)->D1_COD)
					dbSelectArea("SB5")
					dbSetOrder(1)
					lValido := MsSeek(xFilial("SB5")+(cAliasSD1)->D1_COD)
				    If nVersao==30
						cPosIPI	:=	"39202019#39202090#55020010#56012190#56012291#48132000#48139000#76072000"
						If ((cAliasSD1)->D1_TIPO$"CIP")
							lValido	:=	.F.
						EndIf
					Else
						cPosIPI	:=	"39202019#24022000#39202090#55020010#56012190#56012291#48132000#48139000#76072000"
					EndIf
				    If nSrf == 1 .And. !AllTrim((cAliasSB1)->B1_POSIPI) $ cPosIPI ;
				        .And. lValido
						lValido := .F.
					ElseIf nSrf == 2 .And. lValido 	.And. ; 
					    !Alltrim((cAliasSB1)->B1_POSIPI) $ "39011010#39011091#39011092#39012011#39012019#39012021#39012029" .And.;
			   		    !Alltrim((cAliasSB1)->B1_POSIPI) $ "39021010#39021020#39023000#39076000#39232110#39232190#39233000" .And.;
						!Alltrim((cAliasSB1)->B1_POSIPI) $ "39235000#45031000#48115122#48115923#70109011#70109021#70109090" .And.;
						!Alltrim((cAliasSB1)->B1_POSIPI) $ "73102110#73102910#76129019#83091000#83099000"
						lValido := .F.
					Endif	
				Else
					lValido := .T.
				EndIf
				If nSrf == 2 .And. (cAliasSD1)->D1_TIPO == 'C' .And. Left((cAliasSD1)->D1_ORIGLAN,1) == 'F' 
					lValido := .F.
				Endif

				If lValido 
				
					dbSelectArea("TR3")
					If nSrf == 1
						cChave := (cAliasSD1)->D1_SERIE+(cAliasSD1)->D1_DOC+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA+(cAliasSB1)->B1_POSIPI
					ElseIf nSrf == 2
						cChave := (cAliasSD1)->D1_SERIE+(cAliasSD1)->D1_DOC+(cAliasSD1)->D1_FORNECE+(cAliasSD1)->D1_LOJA+(cAliasSB1)->B1_POSIPI+(cAliasSD1)->D1_CF+(cAliasSD1)->D1_ITEM
					Endif
					If !MsSeek(cChave)
						RecLock("TR3",.T.)
						For nX := 1 To Len(aStruSD1)
							If (cAliasSD1)->(FieldPos(aStruSD1[nX][1]))<>0
								FieldPut(nX,(cAliasSD1)->(FieldGet(FieldPos(aStruSD1[nX][1]))))
							EndIf
						Next nX
						TR3->D1_POSIPI  := (cAliasSB1)->B1_POSIPI
						If nSrf == 2
							TR3->D1_ITEMNF  := StrZero(nItem,3)
						Endif	
					Else
						If nSrf == 1
							RecLock("TR3",.F.)					
							TR3->D1_QUANT   += (cAliasSD1)->D1_QUANT
							TR3->D1_TOTAL   += (cAliasSD1)->D1_TOTAL
							TR3->D1_VALDESC += (cAliasSD1)->D1_VALDESC
							TR3->D1_VALIPI  += (cAliasSD1)->D1_VALIPI
						Endif
					EndIf					
					lGravou := .T.					
					nItem ++
					MsUnLock()
	            EndIf
				dbSelectArea(cAliasSD1)
				dbSkip()
			EndDo
			If lQuery
				dbSelectArea(cAliasSD1)
				dbCloseArea()
				dbSelectArea("SD1")
			EndIf
		Else
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Tratamento para Saida                                        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If nSrf == 1
				#IFDEF TOP
					lQuery := .T.
					cAliasSB1 := "SRF194SD2"
					cAliasSD2 := "SRF194SD2"
					cAliasSB5 := "SRF194SD2"
					
				    cQuery := "SELECT SD2.*,SB1.B1_POSIPI "
				    cQuery += "FROM "+RetSqlName("SD2")+" SD2, "
				    cQuery += RetSqlName("SB1")+" SB1,"
				    cQuery += RetSqlName("SB5")+" SB5 "
				    cQuery += "WHERE SD2.D2_FILIAL='"+F3Filial("SD2")+"' AND "
				    cQuery += "SD2.D2_DOC='"+(cAliasSF3)->F3_NFISCAL+"' AND "
				    cQuery += "SD2.D2_SERIE='"+(cAliasSF3)->F3_SERIE+"' AND "
				    cQuery += "SD2.D2_CLIENTE='"+(cAliasSF3)->F3_CLIEFOR+"' AND "
				    cQuery += "SD2.D2_LOJA='"+(cAliasSF3)->F3_LOJA+"' AND "
				    cQuery += "SD2.D_E_L_E_T_=' ' AND "
				    cQuery += "SB1.B1_FILIAL='"+xFilial("SB1")+"' AND "
				    cQuery += "SB1.B1_COD=SD2.D2_COD AND "
				    If nVersao==30
					    cQuery += "SB1.B1_POSIPI IN('24022000') AND "
					    cQuery += "SD2.D2_TIPO NOT IN ('C','I','P') AND "
		   		    Else
		   		    	cQuery += "SB1.B1_POSIPI IN('39202019','24022000','39202090','55020010','56012190','56012291','48132000','48139000','76072000') AND "
		   		    EndIf
				    cQuery += "SB1.D_E_L_E_T_=' ' AND "
				    cQuery += "SB5.B5_FILIAL='"+xFilial("SB5")+"' AND "
		   		    cQuery += "SB5.B5_COD=SD2.D2_COD AND "
		   		    cQuery += "SB5.D_E_L_E_T_=' '  "
		   		    
		   		    cQuery := ChangeQuery(cQuery)
		   		    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSD2)
		   		    For nX := 1 To Len(aStruSD2)
		   		    	If aStruSD2[nX][2]<>"C"
							TcSetField(cAliasSD2,aStruSD2[nX][1],aStruSD2[nX][2],aStruSD2[nX][3],aStruSD2[nX][4])
						EndIf
		   		    Next nX		
				#ELSE		
					dbSelectArea("SD2")
					dbSetOrder(3)		
					MsSeek(F3Filial("SD2")+(cAliasSF3)->F3_NFISCAL+(cAliasSF3)->F3_SERIE+(cAliasSF3)->F3_CLIEFOR+(cAliasSF3)->F3_LOJA)
				#ENDIF
	
				While !Eof() .And. F3Filial("SD2") == xFilial("SD2") .And.;
					(cAliasSF3)->F3_NFISCAL == (cAliasSD2)->D2_DOC .And.;
					(cAliasSF3)->F3_SERIE == (cAliasSD2)->D2_SERIE .And.;
					(cAliasSF3)->F3_CLIEFOR == (cAliasSD2)->D2_CLIENTE .And.;
					(cAliasSF3)->F3_LOJA == (cAliasSD2)->D2_LOJA
					lValido := .F.
					If !lQuery
						dbSelectArea("SB1")
						dbSetOrder(1)
						MsSeek(xFilial("SB1")+(cAliasSD2)->D2_COD)
						dbSelectArea("SB5")
						dbSetOrder(1)
						lValido := MsSeek(xFilial("SB5")+(cAliasSD2)->D2_COD)
					Else
						lValido	:=	.T.
					EndIf
					//
					If nVersao==30
						cPosIPI	:=	"#24022000#"
						If ((cAliasSD2)->D2_TIPO$"CIP")
							lValido	:=	.F.
						EndIf
					Else
						cPosIPI	:=	"39202019#24022000#39202090#55020010#56012190#56012291#48132000#48139000#76072000"
					EndIf
					//
					If lValido .And. AllTrim((cAliasSB1)->B1_POSIPI) $ cPosIPI
						dbSelectArea("TR2")
						If !MsSeek((cAliasSD2)->D2_SERIE+(cAliasSD2)->D2_DOC+(cAliasSD2)->D2_CLIENTE+(cAliasSD2)->D2_LOJA+(cAliasSB1)->B1_POSIPI)
							RecLock("TR2",.T.)
							For nX := 1 To Len(aStruSD2)
								If (cAliasSD2)->(FieldPos(aStruSD2[nX][1]))<>0
									FieldPut(nX,(cAliasSD2)->(FieldGet(FieldPos(aStruSD2[nX][1]))))
								EndIf
							Next nX
							TR2->D2_POSIPI  := (cAliasSB1)->B1_POSIPI
						Else
							RecLock("TR2",.F.)
							TR2->D2_QUANT   += (cAliasSD2)->D2_QUANT
							TR2->D2_PRCVEN  += (cAliasSD2)->D2_PRCVEN
							TR2->D2_TOTAL   += (cAliasSD2)->D2_TOTAL
							TR2->D2_VALIPI  += (cAliasSD2)->D2_VALIPI
						EndIf					
						lGravou := .T.
						MsUnLock()
		            EndIf
					dbSelectArea(cAliasSD2)
					dbSkip()
				EndDo
				If lQuery
					dbSelectArea(cAliasSD2)
					dbCloseArea()
					dbSelectArea("SD1")
				EndIf
			Endif
		EndIf
		If lGravou .Or. !Empty((cAliasSF3)->F3_DTCANC) .Or. "CANCEL"$(cAliasSF3)->F3_OBSERV
			dbSelectArea("TRB")
			If !MsSeek((cAliasSF3)->F3_SERIE+(cAliasSF3)->F3_NFISCAL+(cAliasSF3)->F3_CLIEFOR+(cAliasSF3)->F3_LOJA+Dtos((cAliasSF3)->F3_EMISSAO))
				RecLock("TRB",.T.)
				For nX := 1 To Len(aStruSF3)
					//If !Empty((cAliasSF3)->(FieldName(nX)))
					If !Empty((cAliasSF3)->(FieldName(nX))) .and. !Empty(sf3->(FieldName(nX)))
						FieldPut(nX,(cAliasSF3)->(FieldGet(FieldPos(aStruSF3[nX][1]))))
					EndIf
				Next nX
			Else
				RecLock("TRB",.F.)
				TRB->F3_VALIPI  += (cAliasSF3)->F3_VALIPI
				TRB->F3_VALCONT += (cAliasSF3)->F3_VALCONT				
			EndIf
			trb -> f3_filf1 = xfilial ("SF1")
			trb -> f3_filf2 = xfilial ("SF2")
			MsUnLock()
		EndIf
		dbSelectArea(cAliasSF3)
		dbSkip()
	EndDo
	If lQuery
		dbSelectArea(cAliasSF3)
		dbCloseArea()
		dbSelectArea("SF3")
	Else
		SF3->(RetIndex("SF3"))
		FErase(cArqSF3+OrdBagExt())
	EndIf
Else
	For nX := 1 To Len(aControle)
		dbSelectArea(aControle[nX][1])
		dbCloseArea()
		FErase(aControle[nX][2]+GetDbExtension())
		FErase(aControle[nX][2]+OrdBagExt())
	Next nX
	dbSelectArea("SX1")
EndIf

// u_log ("Arquivo TRB para retorno:")
// u_logtrb ("trb", .t.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura area                                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
RestArea(aArea)
Return(.T.)
