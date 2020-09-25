//  Programa...: Relatório SIGAMNT
//  Autor......: Andre Alves
//  Data.......: 09/08/2018
//  Descricao..: Relatório de Impressão Gráfica para O.S
//
//  Historico de alteracoes:
//  21/06/2019 - Andre  - Removido descrição da tarefa.
//


#include "MNTR675.ch"
#INCLUDE "PROTHEUS.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MNTR675  ³ Autor ³ NG Informatica        ³ Data ³   /06/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Ordem de Servico de Manutencao  (REFEITO 07/08/02 - In cio)³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/
user Function ImpOS(lVPERG, cDEPLANO, cATEPLANO, aMATOS, nTipo, avMatSX1, nRecOs)

	//+-----------------------------------------------+
	//| Armazena variaveis p/ devolucao (NGRIGHTCLICK)|
	//+-----------------------------------------------+
	Local aNGBEGINPRM := NGBEGINPRM()

	//Local vVETHORAS		:= {}
	//Local cString		:= "STJ"
	Local lPERGUN       := IIf(ValType(lVPERG) != "L",.T.,lVPERG)
	//Local cdesc1		:= STR0001 //"Emissao de Ordem de Servico de Manutencao. O Usuario pode selecionar"
	//Local cdesc2		:= STR0002 //"quais os campos que deverao ser mostrados na O.S., bem como informar"
	//Local cdesc3		:= STR0003 //"parametros de selecao para a impressao."
	//Local wnrel			:= "MNTR675"

	//Local cBARRAS		:= If(isSRVunix(),"/","\")
	//Local cRootPath		:= AllTrim(GetSrvProfString("RootPath",cBARRAS))
	//Local cStartPath	:= AllTrim(GetSrvProfString("StartPath",cBARRAS))
	//Local cDirExeTh		:= cRootPath+cStartPath
	Local aArea
    //Local _sArqPlt

	Private aReturn	:= {STR0004, 1,STR0005, 2, 2, 1, "",1} //"Zebrado"###"Administracao"
	Private nLastKey	:= 0
	Private Tamanho	:= "P"
	Private cPerg	:= "MNT675"
	Private Titulo	:= STR0006 //"Ordem De Servico De Manutencao"
	Private lSEQSTF	:= If(NGVerify("STF"),.T.,.F.)
	Private lSEQSTJ	:= If(NGVerify("STJ"),.T.,.F.)
	Private lSEQSTL	:= If(NGVerify("STL"),.T.,.F.)
	Private oPrint
	Private oDlgC,nTImpr,nOpca := 0
	Private lUSATAR := If(FindFunction("NGUSATARPAD"),NGUSATARPAD(),.f.)
	Private nB1		:= TAMSX3("B1_COD")[1]-15
	Private aMatSX1 := {}
	Private lQuebra := .F.
	Private nHorz	:= 100
	Private cTRB675	:= GetNextAlias()

	Default nRecOs   := 0
	Default avMatSX1 := {}

	aMatSX1 := aClone(avMatSX1)

	oFontPN := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFontMN := TFont():New("Courier New",13,13,,.T.,,,,.F.,.F.)
	oFontGN := TFont():New("Courier New",20,20,,.T.,,,,.F.,.F.)
	
	/*
	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	³ Variaveis utilizadas para parametros                         ³
	³ mv_par01     // De  Plano de Manutencao                      ³
	³ mv_par02     // Ate Plano de manutencao                      ³
	³ mv_par03     // Lista Descricao do Bem   S/N                 ³
	³ mv_par04     // Lista Detalhes do Bem    S/N                 ³
	³ mv_par05     // Lista Descricao Manut.   S/N                 ³
	³ mv_par06     // Lista Descricao Etapas   S/N                 ³
	³ mv_par07     // De  Centro de Custo                          ³
	³ mv_par08     // Ate Centro de Custo                          ³
	³ mv_par09     // De  Centro de Trabalho                       ³
	³ mv_par10     // Ate Centro de Trabalho                       ³
	³ mv_par11     // De  Area de Manutencao                       ³
	³ mv_par12     // Ate Area de Manutencao                       ³
	³ mv_par13     // De  Ordem de Servico                         ³
	³ mv_par14     // Ate Ordem de Servico                         ³
	³ mv_par15     // De  Data de Manutencao                       ³
	³ mv_par16     // Ate Data de manutencao                       ³
	³ mv_par17     // Classificacao (Ordem,Servico/Bem,            ³
	³                 Centro Custos,Data da O.S,Servico/Bem Pai)   ³
	³ mv_par18     // Lista descr. da O.S  (Nao, Sim)              ³
	³ mv_par19     // Lista pecas de reposicao(Nao,Sim)            ³
	³ mv_par20     // Lista Banco do Conhecimento(Nao, Sim)        ³
	³ mv_par21     // Banco do Conhecimento(Da OS, Da Manutencao,  ³
	³              // Ambos)                                       ³
	³ mv_par22     // Tipo de Impressao (Em Disco, Via Spool)      ³
	³ mv_par23     // Lista Opcoes da Etapa ? (Sim, Nao)           ³
	³ mv_par24     // Imprimir Localizacao : (Sim, Nao)			   ³
	³ mv_par25     // Imprimir O.S. ? : (Liberada, Pendente, Todas)³
	ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	*/

	cLogo := NGLOCLOGO()

	vVetMvP := NGSALVAMVPA()

	nTImpr := 4
	lPerg := Pergunte(cPerg, IIf((nTImpr == 2 .Or. nTImpr == 4) .And. lPERGUN,.T.,.F.))

	If !IsInCallStack("MNTA265")
		If ValType(nRecOs) == "N" .And. nRecOs > 0
			aArea := STJ->(GetArea())

			dbSelectArea("STJ")
			dbGoTo(nRecOs)

			aMATSX1 := 	{{'01',stj->tj_plano},{'02',stj->tj_plano},;
						 {'07',stj->tj_ccusto},{'08',stj->tj_ccusto},;
						 {'09',stj->tj_centrab},{'10',stj->tj_centrab},;
						 {'11',stj->tj_codarea},{'12',stj->tj_codarea},;
						 {'13',STJ->TJ_ORDEM},{'14',STJ->TJ_ORDEM},;
						 {'15',STJ->TJ_DTMPINI},{'16',STJ->TJ_DTMPINI},;
						 {'18',2}, {'24',1},{'25',3}} //Adicionada MV_PAR18 que é listar Descrição da OS.

			RestArea(aArea)
		EndIf
	EndIf

	If nTImpr = 2 .Or. nTImpr = 4

		If !lperg .And. lPERGUN
			Return
		EndIf

		oPrint  := TMSPrinter():New(OemToAnsi(STR0006))
		limpbol := oPrint:Setup()
		oPrint:SetPortrait() // Normal

		If !limpbol
			Return
		EndIf

		If ExistBlock("MNTR6752")
			ExecBlock("MNTR6752",.F.,.F.,{oPrint,cDEPLANO,cATEPLANO,aMATOS,nRecOs})
		Else
 			Processa({ |lEnd| _RW675Imp(oPrint,cDEPLANO,cATEPLANO,aMATOS,nRecOs)},STR0067)//"Aguarde... verificando alteracoes.."
		EndIf

	EndIf

	NGRETAUMVPA(vVetMvP)

	DbSelectArea("STI")

	//+-----------------------------------------------+
	//| Devolve variaveis armazenadas (NGRIGHTCLICK)  |
	//+-----------------------------------------------+
	NGRETURNPRM(aNGBEGINPRM)

Return NIL

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³ _RW675Imp ³ Autor ³ NG Informatica Ltda   ³ Data ³ 13.11.95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Chamada do Relat¢rio                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MNTR675                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
static Function _RW675Imp(oPrint,cDEPLANO,cATEPLANO,aMATOS,nRecOS)

	Local cCONDICAO := IIf(cDEPLANO = Nil,'stj->tj_situaca == "L"',;
					   IIf(MV_PAR25==1,'stj->tj_situaca == "L"',;
					   IIf(MV_PAR25==2,'stj->tj_situaca == "P"',;
					   			       'stj->tj_situaca <> "C"')))
					   
					   //IIf(MV_PAR25==1,'stj->tj_situaca == "L".And. stj->tj_termino == "N"',;
					   //IIf(MV_PAR25==2,'stj->tj_situaca == "P".And. stj->tj_termino == "N"',;
					   //			   'stj->tj_situaca <> "C".And. stj->tj_termino == "N"')))
	Local xk			:= 0
	Local xz			:= 0
	//Local nContador 	:= 0
	Local cLoc
	Local lIdent		:= .F.
	Local nContLinha	:= 1
	Local nLinha		:= 0
	Local lCabStl1		:= .T.
	Local cT5Sequen		:= Space(TAMSX3("T5_SEQUENC")[1])
	//Local cDescSint 	:= Space(TAMSX3("TTB_DESSIN")[1])
	//Local cBloqPort 	:= Space(TAMSX3("TTB_BLOQPT")[1])
	Local nIncrLin 		:= 0
	Local nBlankSpc
	Local lMNTR675G		:= ExistBlock("MNTR675G")

	//Variaveis utilizada p/ criação da tabela temporária.
	Local aIND675 := {}
	Local oARQTR675

	Private aBenseP	:= {}
	Private li			:= 4000 ,m_pag := 1
	Private nINDSTQ	:= 1
	Private cSEQWHI	:= If(lSEQSTL,"STL->TL_SEQRELA = '0  '","STL->TL_SEQUENC = 0")
	Private cSEQSTL	:= If(lSEQSTL,"0  ",Str(0,2))

	Default nRecOs := 0

	If Len(aMatSX1) > 0
		_fModParSX1(cPerg,aMatSX1)
	EndIf

	If !IsInCallStack("MNTA990")
		If MV_PAR25==2
			cCONDICAO := 'stj->tj_situaca == "P" .And. stj->tj_termino == "N"'
		EndIf
		cCONDICAO += ' .And. stj->tj_ccusto >= MV_PAR07 .And. stj->tj_ccusto <= MV_PAR08 .And. ';
		+'stj->tj_centrab >= MV_PAR09 .And. stj->tj_centrab <= MV_PAR10 .And. ';
		+'stj->tj_codarea >= MV_PAR11 .And. stj->tj_codarea <= MV_PAR12 .And.';
		+'stj->tj_ordem >= MV_PAR13 .And. stj->tj_ordem <= MV_PAR14 .And. ';
		+'stj->tj_dtmpini >= MV_PAR15 .And. stj->tj_dtmpini <= MV_PAR16'
	Else
		cCONDICAO := 'stj->tj_situaca <> "C".And. stj->tj_termino == "N" .And. stj->tj_ccusto >= MV_PAR07 .And. stj->tj_ccusto <= MV_PAR08 .And. ';
		+'stj->tj_centrab >= MV_PAR09 .And. stj->tj_centrab <= MV_PAR10 .And. ';
		+'stj->tj_codarea >= MV_PAR11 .And. stj->tj_codarea <= MV_PAR12 .And.';
		+'stj->tj_ordem >= MV_PAR13 .And. stj->tj_ordem <= MV_PAR14'
	EndIf

	aDBFR675 := {{"ORDEM"   ,"C", 06,0},;
				 {"PLANO"   ,"C", 06,0},;
				 {"SERVICO" ,"C", 06,0},;
				 {"CODBEM"  ,"C", 16,0},;
				 {"CCUSTO"  ,"C", Len(STJ->TJ_CCUSTO),0},;
				 {"DATAOS"  ,"D", 08,0},;
				 {"DIFFDT"  ,"N", 08,0},;
				 {"BEMPAI"  ,"C", 16,0}}

	//Criação Tabela Temporária
	oARQTR675 := NGFwTmpTbl(cTRB675, aDBFR675, aIND675)

	If FindFunction("NGSEQETA")
		nINDSTQ := NGSEQETA("STQ",nINDSTQ)
	EndIf

	lSEQETA := .F.
	DbSelectArea("STQ")
	If FieldPos("TQ_SEQETA") > 0
		lSEQETA := .T.
	EndIf

	If cDEPLANO == Nil .and. nRecOS == 0
		DbSelectArea("STI")
		DbSetOrder(01)
		DbSeek(xFilial("STI")+MV_PAR01)
		DbSelectArea("STJ")
		DbSetOrder(03)
		DbSeek(xFilial("STJ")+MV_PAR01,.T.)
		ProcRegua(LastRec())
		While !EoF() .And. STJ->TJ_FILIAL == xFilial("STJ") .And.;
		STJ->TJ_PLANO >= MV_PAR01 .And. STJ->TJ_PLANO <= MV_PAR02
			IncProc()
			If &(cCONDICAO)
				_MNTRW675GTRB()
			EndIf
			DbSelectArea("STJ")
			DbSkip()
		End
	Elseif cDEPLANO == Nil .and. nRecOS <> 0
		dbSelectArea("STJ")
		dbGoTo(nRecOS)
		_MNTRW675GTRB()
	Else
		DbSelectArea("STJ")
		DbSetOrder(03)
		DbSeek(xFilial("STJ")+cDEPLANO,.T.)
		ProcRegua(LastRec())
		While !EoF() .And. STJ->TJ_FILIAL == xFilial("STJ") .And.;
		STJ->TJ_PLANO <= cATEPLANO

			IncProc()
			If &(cCONDICAO)

				nPosOs := aSCAN(aMATOS, {|x| x[1]+x[2] == STJ->TJ_PLANO+STJ->TJ_ORDEM})
				If nPosOs > 0
					nDiff := Nil
					If Len(aMATOS[nPosOs]) >= 3
						nDiff := aMATOS[nPosOs,3] //Indica a quantidade de dias que as datas da OS serão deslocadas
					EndIf
					_MNTRW675GTRB( nDiff )
				EndIf

			EndIf
			DbSelectArea("STJ")
			DbSkip()
		EndDo
	EndIf

	DbSelectArea(cTRB675)
	DbGotop()
	ProcRegua(LastRec())
	While !EoF()
		IncProc()

		nPaG := 0
		DbSelectArea("STJ")
		DbSetOrder(01)
		If DbSeek(xFilial("STJ")+(cTRB675)->ORDEM+(cTRB675)->PLANO)

			DbSelectArea("STF")
			DbSetOrder(01)
			cSEQSTF := If(lSEQSTF,STJ->TJ_SEQRELA,STR(STJ->TJ_SEQUENC,3))
			DbSeek(xFilial('STF')+STJ->TJ_CODBEM+STJ->TJ_SERVICO+cSEQSTF)

			_MNTW675Somal(oPrint)

			oPrint:Say(li,nHorz+20,' |______________________________INFORMAÇÃO DO BEM_______________________________|',oFonTMN)
						
			_MNTW675Somal(oPrint)
			_MNTW675Somal(oPrint)
			
			If STJ->TJ_TIPOOS == "B"
				cLoc := NGLocComp(STJ->TJ_CODBEM,'1') //Bem
			Else
				cLoc := NGLocComp(STJ->TJ_CODBEM,'2') //Localização
			EndIf

			If cLoc <> AllTrim(STJ->TJ_CODBEM)
				lIdent := .T.
			Else
				lIdent := .F.
			EndIf

			If STJ->TJ_TIPOOS == "B"
				oPrint:Say(li,nHorz+050,STR0184+Space(1)+STJ->TJ_CODBEM; //"Bem......:"
				+Space(21-len(STJ->TJ_CODBEM))+NGSEEK('ST9',STJ->TJ_CODBEM,1,'ST9->T9_NOME'),oFonTPN)

				nAtual := ST9->(Recno())
				If !Empty((cTRB675)->BEMPAI)
					_MNTW675Somal(oPrint)

					oPrint:Say(li,nHorz+050,SubStr(STR0010,2,Len(STR0010))+" "+(cTRB675)->BEMPAI;
					+Space(21-len((cTRB675)->BEMPAI))+NGSEEK('ST9',(cTRB675)->BEMPAI,1,'ST9->T9_NOME'),oFonTPN)
					DbSelectArea("ST9")
					dbGoTo(nAtual)
				EndIf
			Else
				oPrint:Say(li,nHorz+050,STR0186+Space(1)+STJ->TJ_CODBEM; //"Código...:"
				+Space(21-len(STJ->TJ_CODBEM));
				+NGSEEK('TAF',"X2"+SubStr(STJ->TJ_CODBEM,1,3),7,"SubStr(TAF_NOMNIV,1,40)"),oFonTPN)
				oPrint:Say(li,nHorz+2020,STR0009+" "+NGSEEK('TQB',STJ->TJ_CODBEM,1,'TQB->TQB_PRIORI'),oFonTPN)
			EndIf
			
			_MNTW675Somal(oPrint)

			oPrint:Say(li,nHorz+050,'Horímetro:'+" "+cValtoChar(NGSEEK('ST9',STJ->TJ_CODBEM,1,'ST9->T9_POSCONT')),oFonTPN)
			oPrint:Say(li,nHorz+900,'Ultima Manutenção:'+" "+Dtoc(STJ->TJ_DTULTMA),oFonTPN)
			
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT MAX (TJ_ORDEM)"
			_oSQL:_sQuery += "			FROM " + RetSQLName ("STJ") + " STJ "
			_oSQL:_sQuery += "			WHERE TJ_CODBEM = '"+STJ->TJ_CODBEM+"'"
			_oSQL:_sQuery += "			AND TJ_ORDEM < '"+STJ->TJ_ORDEM+"'"
			_oSQL:_sQuery += "			AND STJ.TJ_FILIAL = '" + xFilial('STJ') + "'"
			_oSQL:_sQuery += "			AND D_E_L_E_T_ = ''"
			_oSQL:log()
			
			oPrint:Say(li,nHorz+1800 ,'O.S Anterior..:'+" "+_oSql:retqry(),oFonTPN)
			
			_MNTW675Somal(oPrint)
			_MNTW675Somal(oPrint)
//			oPrint:Line(li,nHorz+15,li,nHorz+2335)
			
			
			If MV_PAR18 = 1 .And. !Empty(STJ->TJ_OBSERVA)
			nLinha := li
			lQuebra := .F.
			If lQuebra
				oPrint:Say(li,nHorz+20," |_____________________________DESCRIÇÃO DO PROBLEMA____________________________|",oFonTMN)
			Else
				li := nLinha
					
				_MNTW675Somal(oPrint)
				oPrint:Say(li,nHorz+20," |_____________________________DESCRIÇÃO DO PROBLEMA____________________________|",oFonTMN)
			EndIf

			// Impressao da Linha de Descricao da O.S.

			cOBSERVA := If(NGCADICBASE('TJ_MMSYP','A','STJ',.F.),;
			NGMEMOSYP(STJ->TJ_MMSYP),STJ->TJ_OBSERVA)
			nCol := 300
			nTOs := 65

			_NGMEMORW675('Observação :',cOBSERVA,nCol,nTOs,.T.)  //"Descricao da O.S:"
			_MNTW675Somal(oPrint)
			EndIf
			_MNTW675Somal(oPrint)
			
		DbSelectArea("STL")
		DbSetOrder(03)
		DbSeek(XFILIAL('STL')+STJ->TJ_ORDEM+STJ->TJ_PLANO+cSEQSTL)	
			
		oPrint:Say(li,nHorz+20,' |________________________________DATAS PREVISTAS_______________________________|',oFonTMN)
			_MNTW675Somal(oPrint)
			_MNTW675Somal(oPrint)
			//oPrint:Say(li,nHorz+050,'Data Inicial :'+"    "+Dtoc(STJ->TJ_DTMPINI+(cTRB675)->DIFFDT)+"        Hora Inicial: "+STJ->TJ_HOMPINI,oFonTPN)
			oPrint:Say(li,nHorz+050,'Data Inicial :'+"    "+Dtoc(STL->TL_DTINICI+(cTRB675)->DIFFDT)+"        Hora Inicial: "+STL->TL_HOINICI,oFonTPN)
			_MNTW675Somal(oPrint)
			//oPrint:Say(li,nHorz+050,'Data Final   :'+"    "+Dtoc(STJ->TJ_DTMPFIM+(cTRB675)->DIFFDT)+"        Hora Final  : "+STJ->TJ_HOMPFIM,oFonTPN)
			oPrint:Say(li,nHorz+050,'Data Final   :'+"    "+Dtoc(STL->TL_DTFIM+(cTRB675)->DIFFDT)  +"        Hora Final  : "+STL->TL_HOFIM,oFonTPN)
    		   		     			
			_MNTW675Somal(oPrint)
			If !Empty(STJ->TJ_CENTRAB)
				oPrint:Say(li,nHorz+050,SubStr(STR0012,2,Len(STR0012))+Space(1)+STJ->TJ_CENTRAB;
				+Space(21-len(STJ->TJ_CENTRAB))+NGSEEK('SHB',STJ->TJ_CENTRAB,1,'SHB->HB_NOME'),oFonTPN)
			EndIf

			If STJ->TJ_TIPOOS == "B"
				If mv_par04 = 1
					lPrimeiro := .F.
					dbSelectArea("STB")
					dbSetOrder(01)
					dbSeek(xFilial('STB')+ST9->T9_CODBEM)
					nIncrLin := 0
					nBlankSpc := if(TAMSX3("TB_INFO02")[1] > 15, 15, TAMSX3("TB_INFO02")[1])
     				While !EoF() .And. STB->TB_CODBEM = ST9->T9_CODBEM .And.;
					STB->TB_FILIAL == xFilial('STB')

						nIncrLin := nIncrLin+40

						dbSelectArea("STB")
						dbSkip()
					End

					_MNTW675Somal(oPrint)
//					oPrint:Line(li,nHorz+15,li,nHorz+2335)
				EndIf

				// Impressao da Linha de Descricao
				If mv_par03 = 1
					_NGMEMORW675(STR0014,ST9->T9_DESCRIC,300,70,.T.)
				EndIf
			EndIf

			nLinha := li+nIncrLin
			lQuebra := .F.
			For nContLinha := 1 to 5
				
			Next
			
/*			If lQuebra
				oPrint:Say(li,nHorz+20," |_____________________________DESCRIÇÃO DAS TAREFAS____________________________|",oFonTMN)
			Else
				li := nLinha
				
				oPrint:Say(li,nHorz+20," |_____________________________DESCRIÇÃO DAS TAREFAS____________________________|",oFonTMN)
				
			EndIf
*/
			If STJ->TJ_TIPOOS == "B"

				// Linha da descricao da manutencao
				If mv_par05 == 1
					_NGMEMORW675("TAREFAS",STF->TF_DESCRIC,300,70,.T.)

				EndIf

			EndIf

			aARTAREFAS := {}

			DbSelectArea("STL")
			DbSetOrder(03)
			DbSeek(XFILIAL('STL')+STJ->TJ_ORDEM+STJ->TJ_PLANO+cSEQSTL)

			While !EoF() .And. Xfilial("STL") == STL->TL_FILIAL .And.;
			STJ->TJ_ORDEM == STL->TL_ORDEM .And. STJ->TJ_PLANO == STL->TL_PLANO;
			.AND. If(lSEQSTL,STL->TL_SEQRELA == "0  ",STL->TL_SEQUENC = 0)

				DbSelectArea("ST5")
				DbSetOrder(1)
				If DbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STL->TL_TAREFA)
					cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))

				EndIf

				nPOS := Ascan(aARTAREFAS,{|x| x[1] == stl->tl_tarefa})
				If nPOS = 0
					Aadd(aARTAREFAS,{stl->tl_tarefa,stl->tl_dtinici,stl->tl_hoinici,;
					stl->tl_dtfim,stl->tl_hofim,cT5Sequen})

				Else
					If stl->tl_dtinici < aARTAREFAS[nPOS][2]
						aARTAREFAS[nPOS][2] := stl->tl_dtinici
						aARTAREFAS[nPOS][3] := stl->tl_hoinici
					ElseIf stl->tl_dtinici == aARTAREFAS[nPOS][2] .And. stl->tl_hoinici < aARTAREFAS[nPOS][3]
						aARTAREFAS[nPOS][3] := stl->tl_hoinici
					EndIf

					If STL->TL_DTFIM > aARTAREFAS[nPOS][4]
						aARTAREFAS[nPOS][4] := stl->tl_dtfim
						aARTAREFAS[nPOS][5] := stl->tl_hofim
					ElseIf stl->tl_dtfim == aARTAREFAS[nPOS][4] .And. stl->tl_hofim > aARTAREFAS[nPOS][5]

					EndIf
					aARTAREFAS[nPOS][6] := cT5Sequen
				EndIf
				DbSelectArea("STL")
				Dbskip()
			End

			aARETAPAS := {}
			DbSelectArea("STQ")
			DbSetOrder(01)
			DbSeek(XFILIAL('STQ')+STJ->TJ_ORDEM+STJ->TJ_PLANO)
			While !EoF() .And. Xfilial("STQ") = STQ->TQ_FILIAL .And.;
			STQ->TQ_ORDEM == STJ->TJ_ORDEM .And. STQ->TQ_PLANO == STJ->TJ_PLANO

				DbSelectArea("ST5")
				DbSetOrder(1)
				If DbSeek(xFilial("ST5")+STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA+STQ->TQ_TAREFA)
					cT5Sequen := cValToChar(STRZERO(T5_SEQUENC,TAMSX3("T5_SEQUENC")[1]))

				EndIf

				Aadd(aARETAPAS,{stq->tq_tarefa,stq->tq_etapa,stq->tq_seqeta,cT5Sequen})

				If Empty(aARTAREFAS)
					Aadd(aARTAREFAS,{STQ->TQ_TAREFA,STJ->TJ_DTMPINI,STJ->TJ_HOMPINI,;
					STJ->TJ_DTMPFIM,STJ->TJ_HOMPFIM,cT5Sequen})
				EndIf

				DbSelectArea("STQ")
				DbSkip()
			End While

			If !Empty(aARETAPAS)
				If Len(aARETAPAS[1]) >= 4
					aSort(aARETAPAS ,,, {|x,y| x[4]+x[1]+x[2] < y[4]+y[1]+Y[2] })
				Else
					aSort(aARETAPAS ,,, {|x,y| x[1]+x[2] < y[1]+y[2] })
				EndIf
			EndIf

			If !Empty(aARTAREFAS)
				If Len(aARTAREFAS[1]) >= 6
					aSort(aARTAREFAS ,,, {|x,y| x[6]+x[1] < y[6]+y[1] })
				EndIf
			EndIf

			_MNTW675Somal(oPrint)
			For xk := 1 To Len(aARTAREFAS)
			
				/*_MNTW675Somal(oPrint)

				If AllTrim(aARTAREFAS[xk][1]) == "0"
					oPrint:Say(li,nHorz+050,STR0030,oFonTPN)
				Else
					If !lUSATAR
						oPrint:Say(li,nHorz+050,'Descrição Tarefa:'+" "+NGSEEK('ST5',STJ->TJ_CODBEM+STJ->TJ_SERVICO+;
						If (lSEQSTJ,STJ->TJ_SEQRELA,Str(STJ->TJ_SEQUENC,3))+;
						aARTAREFAS[xk][1],1,'T5_DESCRIC'),oFonTPN)
						_MNTW675Somal(oPrint)
						
	//					(STR0014,ST9->T9_DESCRIC,300,70,.T.)
					Else
						lCORRET := If(Val(stj->tj_plano) = 0,.T.,.F.)
						oPrint:Say(li,nHorz+050,'Descrição Tarefa:'+" "+NGNOMETAR(STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA,;
						aARTAREFAS[xk][1]),oFonTPN)
					EndIf
				EndIf 
				_MNTW675Somal(oPrint)*/
				If MV_PAR06 == 1      // mostra etapas da tarefa
					DbSelectArea("STQ")
					DbSetOrder(nINDSTQ)
					If DbSeek(XFILIAL('STQ')+STJ->TJ_ORDEM+STJ->TJ_PLANO+aARTAREFAS[xk][1])

						_MNTW675Somal(oPrint)
						_MNTW675Somal(oPrint) 
						
//						oPrint:Line(li,nHorz+20,li,nHorz+2330)
						oPrint:Say(li,nHorz+20," |___________________________________ETAPAS_____________________________________|",oFonTMN)
						_MNTW675Somal(oPrint)
						
						While !EoF() .And. Xfilial("STQ") = STQ->TQ_FILIAL .And.;
						STQ->TQ_ORDEM == STJ->TJ_ORDEM .And.;
						STQ->TQ_PLANO == STJ->TJ_PLANO .And.;
						STQ->TQ_TAREFA == aARTAREFAS[xk][1]

							_NGWIMPETAPA(stq->tq_ok,stq->tq_etapa)
//						_MNTW675Somal(oPrint)
							// Deletar as etapas da array aARETAPAS
							nPOS2 := Ascan(aARETAPAS,{|x| x[1] == stq->tq_tarefa .And. x[2] == stq->tq_etapa})
							If nPOS2 > 0
								Adel(aARETAPAS,nPOS2)
								Asize(aARETAPAS,Len(aARETAPAS)-1)
							EndIf
							DbSelectArea("STQ")
							DbSkip()
						End While
					EndIf
				EndIf 

				nLinha := li
				lQuebra := .F.
				For nContLinha := 1 to 3
//					_MNTW675Somal(oPrint)
				Next
					
				DbSelectArea("STL")
				DbSetOrder(03)
				DbSeek(XFILIAL('STL')+STJ->TJ_ORDEM+STJ->TJ_PLANO+cSEQSTL+aARTAREFAS[xk][1])
				
				While !EoF() .And. Xfilial("STL") = STL->TL_FILIAL .And.;
				STJ->TJ_ORDEM == STL->TL_ORDEM .And. STJ->TJ_PLANO == STL->TL_PLANO;
				.And. &(cSEQWHI) .And. STL->TL_TAREFA == aARTAREFAS[xk][1]
			
					If lCabStl1
						If lQuebra
//							oPrint:Line(li,nHorz+20,li,nHorz+2330)
//					_MNTW675Somal(oPrint)
							oPrint:Say(li,nHorz+20,' |______________________________INSUMOS PREVISTOS_______________________________|',oFonTMN)
							
						Else
							
							li := nLinha
//							oPrint:Line(li,nHorz+20,li,nHorz+2330)
//							_MNTW675Somal(oPrint)
							oPrint:Say(li,nHorz+20,' |______________________________INSUMOS PREVISTOS_______________________________|',oFonTMN)
						EndIf

						_MNTW675Somal(oPrint)
						_MNTW675Somal(oPrint)
						
						oPrint:Say(li,nHorz+050,STR0120,oFonTPN) 	//Codigo
						oPrint:Say(li,nHorz+700,STR0108,oFonTPN)	//Quant.
						oPrint:Say(li,nHorz+1150,STR0033,oFonTPN)	//Nome

						lCabStl1 := .F.
					EndIf

					aTIPNOM := NGNOMINSUM(stl->tl_tiporeg,stl->tl_codigo,30)
					If Len(aTIPNOM) > 0
						oPrint:Say(li,nHorz+1260,SubStr( aTIPNOM[1][2],1,30),oFonTPN) //Descricao

					EndIf

					oPrint:Say(li,nHorz+205,Substr(STL->TL_CODIGO,1,30),oFonTPN) //Codigo
					oPrint:Say(li,nHorz+810,Str(STL->TL_QUANTID,3),oFonTPN) //Quant.
					oPrint:Say(li,nHorz+890,Substr(STL->TL_UNIDADE,1),oFonTPN) //Unidade.
					
					vVETHORAS := NGTQUATINS(STL->TL_CODIGO,STL->TL_TIPOREG,STL->TL_USACALE,;
					STL->TL_QUANTID,STL->TL_TIPOHOR,STL->TL_DTINICI,	STL->TL_HOINICI,;
					STL->TL_DTFIM,STL->TL_HOFIM,STL->TL_UNIDADE)

					nQTDHORAS := vVETHORAS[1]

					_MNTW675Somal(oPrint)

					DbSelectArea("STL")
					DbSkip()
				End While
				lCabStl1 := .T.
			Next xk
			
			
			// Imprime as etapas nao relacionadas com insumos
			If MV_PAR06 == 1      // mostra etapas da tarefa
				If Len(aARETAPAS) > 0
					nLinha := li
					lQuebra := .F.
/*					For nContLinha := 1 to 5
						_MNTW675Somal(oPrint)
					Next
					If lQuebra
						oPrint:Say(li,nHorz+700,"ETAPAS NAO RELACIONADAS",oFonTMN)
					Else
						li := nLinha
						_MNTW675Somal(oPrint)
						_MNTW675Somal(oPrint)
						oPrint:Say(li,nHorz+700,"ETAPAS NAO RELACIONADAS",oFonTMN)
					EndIf
					_MNTW675Somal(oPrint)
					_MNTW675Somal(oPrint)

					oPrint:Line(li,nHorz+10,li,nHorz+2335)
*/
					If !Empty(aARETAPAS)
						If lSEQETA
							If Len(aARETAPAS[1]) >= 4
								aARCLASS := Asort(aARETAPAS,,,{|x,y| x[4]+x[1]+x[3]+x[2] < y[4]+y[1]+y[3]+y[2]})
							Else
								aARCLASS := Asort(aARETAPAS,,,{|x,y| x[1]+x[3]+x[2] < y[1]+y[3]+y[2]})
							EndIf
						Else
							If Len(aARETAPAS[1]) >= 4
								aARCLASS := Asort(aARETAPAS,,,{|x,y| x[4]+x[1]+x[2] < y[4]+y[1]+y[2]})
							Else
								aARCLASS := Asort(aARETAPAS,,,{|x,y| x[1]+x[2] < y[1]+y[2]})
							EndIf
						EndIf
					EndIf

					cAUXTAR := 'XXXXXX'
					For xz := 1 To Len(aARCLASS)
						If cAUXTAR <> aARCLASS[xz][1]
//							_MNTW675Somal(oPrint)
//							oPrint:Say(li,nHorz+050 ,STR0051,oFonTPN)
//							oPrint:Say(li,nHorz+200,aARCLASS[xz,1],oFonTPN)

						/*	If !lUSATAR
								oPrint:Say(li,nHorz+380,If(AllTrim(aARCLASS[xz,1]) == "0",STR0030,;
								NGSEEK('ST5',STJ->TJ_CODBEM+STJ->TJ_SERVICO;
								+If(lSEQSTJ,STJ->TJ_SEQRELA,Str(STJ->TJ_SEQUENC,3))+;
								aARCLASS[xz,1],1,'ST5->T5_DESCRIC')),oFonTPN)
							Else
								lCORRET := If(Val(stj->tj_plano) = 0,.T.,.F.)
								oPrint:Say(li,nHorz+380,NGNOMETAR(STJ->TJ_CODBEM+STJ->TJ_SERVICO+STJ->TJ_SEQRELA,;
								aARCLASS[xz][1]),oFonTPN)
							EndIf */
						EndIf
						cAUXTAR := aARCLASS[xz][1]
						_NGWIMPETAPA("  ",aARCLASS[xz][2])
					Next xz 
				EndIf
			EndIf  
			
			If lMNTR675G //Parâmetro {1} indica que o relatório é do MNTR675
				ExecBlock("MNTR675G",.F.,.F.,{1})
				oPrint:EndPage()
			EndIf

		EndIf
		
		_sArqPlt	:="\Andre\"+Alltrim(STJ->TJ_CODBEM)+".jpg"     //20180810 - Adicionado busca de desenho pelo codigo do desenho
	
		oPrint:EndPage()
		if file(_sArqPlt)
			
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Define que a impressao deve ser RETRATO³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//oPrint:SetLandScape()
		oPrint:StartPage()
		oPrint:SayBitmap(20,010,_sArqPlt,2300,3100)
		oPrint:EndPage()
		endif		
	
		DbSelectArea(cTRB675)
		dbSkip()
		li := 4000

	End While

	If GetNewPar("MV_NGMNTCC","N") == "S" //Ve se utiliza template Construção Civil para impressão de detalhes material rodante
		MNTR688MR(oPrint,STJ->TJ_CODBEM)
	EndIf

	//Deleta o arquivo temporario fisicamente
	oARQTR675:Delete()

	oPrint:EndPage()
	RetIndex('STJ')
	Set Filter To
	DbSetOrder(01)

	If MV_PAR22 = 1 //Em Disco
		oPrint:Preview()
	Else // Via Spool
		oPrint:Print()
	EndIf

Return NIL

/*/

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o   ³__MNTW675Somal³ Autor ³ In cio Luiz Kolling   ³ Data ³28/05/2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o³ Incrementa Linha,Cabecalho e Salto de Pagina                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MNTR675                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/
Static Function _MNTRW675GTRB( nDiffDias )
	DbSelectArea(cTRB675)
	(cTRB675)->(DbAppend())
	(cTRB675)->ORDEM   := STJ->TJ_ORDEM
	(cTRB675)->PLANO   := STJ->TJ_PLANO
	(cTRB675)->SERVICO := STJ->TJ_SERVICO
	(cTRB675)->CODBEM  := STJ->TJ_CODBEM
	(cTRB675)->CCUSTO  := STJ->TJ_CCUSTO
	(cTRB675)->DATAOS  := STJ->TJ_DTMPINI
	If ValType(nDiffDias) == "N"
		(cTRB675)->DIFFDT := nDiffDias
	EndIf
	nPosBP := aSCAN(aBenseP,{|x| x[1] == (cTRB675)->CODBEM})
	If nPosBP = 0
		(cTRB675)->BEMPAI := NGBEMPAI((cTRB675)->CODBEM)
		Aadd(aBenseP,{(cTRB675)->CODBEM,(cTRB675)->BEMPAI})
	Else
		(cTRB675)->BEMPAI := aBenseP[nPosBP,2]
	EndIf
Return

//---------------------------------------------------------------------
/*/{Protheus.doc} NGMEMORW675
Imprime campo memo ( especifica p/ mntr675 )

@type function

@source MNTR675.prx

@author Inácio Luiz Kolling
@since 13/08/2002

@param cTITULO	, Caracter	, Titulo do relátorio.
@param cDESCRI	, Caracter	, Descrição do relatório.
@param nCOLU	, Numérico	, Numero de colunas.
@param nTAM		, Numérico	, Tamanho do relatório.
@param lSOMLI	, Lógico	, Determina se pula linha.

@sample NGMEMORW675("Retorno","Descrição",1,2,.T.)

@return Sempre verdadeiro.
/*/
//---------------------------------------------------------------------
Static Function _NGMEMORW675(cTITULO,cDESCRI,nCOLU,nTAM,lSOMLI)
	Local lPrimeiro := .T.
	Local lSOMEILI  := lSOMLI,linhacorrente
	nLinhasMemo := MLCOUNT(cDESCRI,nTAM)
	For LinhaCorrente := 1 To nLinhasMemo
		If lSOMEILI
			_MNTW675Somal(oPrint)
			lSOMEILI := .T.
		Else
			If Len(AllTrim(MemoLine(cDESCRI,nTAM,LinhaCorrente))) > 0
				_MNTW675Somal(oPrint)
			EndIf
		EndIf
		If lPrimeiro
			If !Empty(cTITULO)
				oPrint:Say(li+nTAM,nHorz+50 ,cTITULO,oFonTPN)
			EndIf
			lPrimeiro := .F.
		EndIf
		oPrint:Say(li+nTAM,nHorz+nCOLU,(MemoLine(cDESCRI,nTAM,LinhaCorrente)),oFonTPN)
		//Caso seja a ultima linha que será impressa.
		If  LinhaCorrente == nLinhasMemo
			_MNTW675Somal(oPrint)
			Exit
		EndIf
	Next
Return .T.
/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o   ³NGWIMPETAPA³ Autor ³ NG Informatica Ltda   ³ Data ³   /06/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o³Imprime a etapas                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MNTR675                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

static Function _NGWIMPETAPA(cVOK,cVETAPA)
		
	If Empty(cVOK)
		//Realizar a quebra de página para exibir corretamente Etapas Genéricas
		If li > 3010
			li := 3201
		EndIf
		_MNTW675Somal(oPrint)

		oPrint:Say(li,nHorz+050,'Etapa:'+" "+cVETAPA,oFonTPN)
		dbSelectArea("TPA")
		dbSetOrder(01)
		If dbSeek(xFilial('TPA') + cVETAPA)
			_NGMEMOEW675(TPA->TPA_DESCRI,320,75)
			_MNTW675Somal(oPrint)
			oPrint:Say(li,nHorz+320,'OK ( )  NOK ( )',oFonTPN)
 			_MNTW675Somal(oPrint)
//			If MV_PAR23 == 1
//				_MNT675OPE(oPrint,cVETAPA)
//			EndIf
		EndIf
	EndIf
Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o   ³NGMEMOEW675³ Autor ³In cio Luiz Kolling    ³ Data ³29/05/2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o³Imprime campo memo etapa                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MNTR675                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

static Function _NGMEMOEW675(cDESCRI,nCOLU,nTAM)
	Local lLin
	nLinhasMemo := MLCOUNT(AllTrim(cDESCRI),nTAM)
	For lLin := 1 To nLinhasMemo
		If !Empty((MemoLine(cDESCRI,nTAM,lLin)))
			If lLin > 1
				_MNTW675Somal(oPrint)
			EndIf
			oPrint:Say(li,nHorz+nCOLU,(MemoLine(cDESCRI,nTAM,lLin)),oFonTPN)
		EndIf
	Next LinhaCorrente
Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o   ³__MNTW675Somal³ Autor ³ In cio Luiz Kolling   ³ Data ³28/05/2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o³ Incrementa Linha,Cabecalho e Salto de Pagina                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MNTR675                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/
Static Function _MNTW675Somal(oPrint)
	Private cNomFil  := SM0->M0_FILIAL

	li += 50
	If li > 3100
		lQuebra := .T.
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
		oPrint:Box(li,nHorz+10,3200,nHorz+2335)
		li += 20
		//
		If File(cLogo)
			oPrint:SayBitMap(li,nHorz+40,cLogo,250,73)
		EndIf

		//
		oPrint:Say(li,nHorz+780,STR0006,oFonTMN)

//		oPrint:Say(li-10,nHorz+1880,cNomFil,oFonTPN)
		oPrint:Say(li+45,nHorz+2050,STR0076+" "+Str(nPag,2),oFonTPN)

		If !Empty(stj->tj_solici)
			Li += 90
			oPrint:Say(li,nHorz+15,STR0056+"  "+STJ->TJ_SOLICI+Space(5)+STR0095+; //"Solicitante: "
			SubStr(UsrRetName(NGSEEK('TQB',STJ->TJ_SOLICI,1,'TQB->TQB_CDSOLI')),1,15))
			Li += 60
			oPrint:Say(li,nHorz+15,STR0096+; //"Dt.Solic.: "
			DtoC(NGSEEK('TQB',STJ->TJ_SOLICI,1,'TQB->TQB_DTABER'))+;
			Space(4)+STR0097+; //"Hr.Solic.: "
			NGSEEK('TQB',STJ->TJ_SOLICI,1,'TQB->TQB_HOABER'),oFonTPN)
		EndIf

		Li += 100
		oPrint:Say(li,nHorz+050  ,"N° O.S:  ",oFonTMN)
		oPrint:Say(li,nHorz+250, STJ->TJ_ORDEM,oFonTMN)
		oPrint:Say(li,nHorz+1650,STR0046+" "+Dtoc(Date())+" "+STR0087+" "+(SubStr(Time(),1,5)),oFonTPN)

		_MNTW675Somal(oPrint)
		
//		oPrint:Line(li,nHorz+15,li,nHorz+2335)

		Li += 100
	EndIf
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} fModParSX1
Carrega as variaveis das perguntas a partir do SX1 e Altera os conteúdos

@author  Maicon André Pinheiro
@since   27/02/2018
@version P12
/*/
//-------------------------------------------------------------------
Static Function _fModParSX1(cPerg,aMNT675)

	Local aArea     := GetArea()
	Local cPergC    := Alltrim(cPerg)+Space(len(SX1->X1_GRUPO)-Len(Alltrim(cPerg)))
	Local nTotSX1   := Len(aMNT675)
	Local nInd      := 0
	Local nTamanho  := 0
	Local cTipo     := ""
	Local xConteudo := ""

	For nInd := 1 To nTotSX1

		cTipo    := Posicione("SX1",1,cPergC + aMNT675[nInd][1],"X1_TIPO")
		nTamanho := Posicione("SX1",1,cPergC + aMNT675[nInd][1],"X1_TAMANHO")
		If nTamanho > 0 //Caso encontrou a pergunta.
			
			Do Case
				Case cTipo == "N"
					xConteudo := aMNT675[nInd,2]
				Case cTipo == "C"
					xConteudo := SubStr(aMNT675[nInd,2],1,nTamanho)
				Case cTipo == "D"
					If ValType(aMNT675[nInd,2]) == "C"
						xConteudo := CtoD(aMNT675[nInd,2])
					Else
						xConteudo := aMNT675[nInd,2]
					EndIf
			End Case

			&("MV_PAR"+aMNT675[nInd][1]) := xConteudo

		EndIf

	Next nInd

	RestArea(aArea)

Return
