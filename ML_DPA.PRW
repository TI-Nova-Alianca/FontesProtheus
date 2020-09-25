#include "rwmake.ch"

User Function ML_DPA()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ML_DPA   ³ Autor ³  MICROSIGA CAXIAS     ³ Data ³ 09.09.94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Emissao de Duplicatas                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define Variaveis.                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
titulo  := "Emissao de Duplicatas"
cDesc1  := "Este programa ir  emitir as Duplicatas conforme"
cDesc2  := "parametros especificados da"
cDesc3  := "Cooperativa Agroindustrial Nova Alianca Ltda"
cString := "SE1"
aReturn := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
cPerg   := "ML_DPA"
nLastKey:= 0
tamanho := "M"
wnrel   := "ML_DPA"
nomeprog:= "ML_DPA"
nTipo   := 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros        ³
//³ mv_par01      // Duplicata de               ³
//³ mv_par02      // Duplicata ate              ³
//³ mv_par03      // Serie                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ValidPerg()
Pergunte(cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia controle para a funcao SETPRINT                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

If nLastKey == 27
	Return
Endif
SetDefault(aReturn,cString)
If nLastKey == 27
	Return
Endif

RptStatus({|| Imprimir()})
Return

Static Function Imprimir()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa regua de impressao                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SetRegua(LastRec())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nTipo := IIF(aReturn[4]==1,15,18)
li    := 0
m_pag := 1
_xCOUNT := 0

DbSelectArea("SE1")
DbSetOrder(1)
DbSeek(xFilial()+mv_par03+mv_par01,.T.)
Do While !Eof() .And. xFilial()==SE1->E1_FILIAL .And. SE1->E1_NUM <= mv_par02
	If SE1->E1_PREFIXO <> mv_par03
		DbSelectArea("SE1")
		DbSkip()
		Loop
	Endif
	cNumNF     :=SE1->E1_NUM                 // Numero Fatura/Duplicata
	cPrefixo   :=SE1->E1_PREFIXO             // Prefixo Duplicata
	
	cCF        := " "
	DbSelectArea("SD2")
	DbSetOrder(3)
	DbSeek(xfilial()+cNumNF+cPrefixo,.T.)
	Do While xFilial("SD2")+cNumNF+cPrefixo==SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE .AND. !EOF()
		If !SD2->D2_CF$cCF
			cCF   := cCF + IIF(EMPTY(cCF),SD2->D2_CF,"/"+SD2->D2_CF)
		Endif
		dbSelectArea("SD2")
		dbSkip()
	Enddo
	
	cTipoNF :=""
	dbSelectArea("SF2")
	dbSetOrder(1)
	dbSeek(xfilial()+cNumNF+cPrefixo,.T.)
	cTipoNF:=IIF(FOUND(),SF2->F2_TIPO,"U")
	cCodTrans:=SF2->F2_TRANSP
	cTRANSP  := " "
	xVALFAT :=SF2->F2_VALFAT
	If !Empty(cCodTrans)
		dbSelectArea("SA4")
		dbSetOrder(1)
		dbSeek(xfilial("SA4")+cCodTrans)
		cTRANSP :=SA4->A4_VIA
	Endif
	
	dbSelectArea("SE1")
	XX:=1
	xE1_NUM:=SE1->E1_NUM
	Do While !Eof() .And. SE1->E1_PREFIXO ==cPrefixo .And. SE1->E1_NUM == xE1_NUM
		IncRegua()
		If xE1_NUM<>SE1->E1_NUM
			XX:=1
			xE1_NUM:=SE1->E1_NUM
			Exit
		Endif
		If SE1->E1_TIPO == "IR-"
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		li:= 06
                @ li,000 PSAY CHR(18)
		@ li,058 PSAY SE1->E1_EMISSAO
		li:= li + 5
		@ li,002 PSAY xVALFAT  Picture"@E 999,999.99"
		@ li,016 PSAY SE1->E1_NUM
		@ li,027 PSAY SE1->E1_VALOR Picture"@E 999,999.99"
		@ li,040 PSAY SE1->E1_NUM
		@ li,046 PSAY "-"
		@ li,047 PSAY XX
		@ li,052 PSAY SE1->E1_VENCTO
                @ li,000 PSAY CHR(15)
		li:= li + 7
		DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial()+SE1->E1_CLIENTE+SE1->E1_LOJA)
		If Found()
			@ li,046 PSAY SA1->A1_NOME
			li:= li + 1
			@ li,046 PSAY SA1->A1_END
			li:= li +1
			@ li,046 PSAY SA1->A1_MUN
			@ li,104 PSAY SA1->A1_CEP Picture"@R 99999-999"
			@ li,122 PSAY SA1->A1_EST
			li := li + 1
			@ li,046 PSAY SA1->A1_ENDCOB
			li := li + 1
			@ li,046 PSAY SA1->A1_CGC Picture"@R 99.999.999/9999-99"
			@ li,107 PSAY SA1->A1_INSCR
			li := li + 3
		Endif
		DbSelectArea("SE1")
		_wVALOR := SE1->E1_VALOR
		DbSelectArea("SE1")
		DbSkip()
		@ li,047 PSAY Subs(RTRIM(SUBS(EXTENSO(_wVALOR),01,80)) + REPLICATE("*",80),1,80)
		li:= li + 1
		@ li,047 PSAY Subs(RTRIM(SUBS(EXTENSO(_wVALOR),81,80)) + REPLICATE("*",80),1,80)
                _xCOUNT += 1
                If _xCOUNT == 1
                        li:= li + 9
                Else
                        li:= li + 10
                Endif
                @ li,044 PSAY "."
		XX:=XX+1
                SetPrc(0,0)
	Enddo
	DbSelectArea("SE1")
Enddo

DbSelectArea("SE1")
DbSetOrder(1)
DbSelectArea("SA1")
DbSetOrder(1)

Set Device To Screen

SetPgEject(.F.)

If aReturn[5]==1
	Set Printer TO
	dbcommitAll()
	ourspool(wnrel)
Endif

MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Perguntas no SX1                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ValidPerg()
local j := 0
local i := 0
cAlias  := Alias()
aRegs   := {}

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
AADD(aRegs,{cPerg,"01","Da Duplicata       ?","mv_ch1","C",6,0,0,"G","","mv_par01","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"02","Ate a Duplicata    ?","mv_ch2","C",6,0,0,"G","","mv_par02","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"03","Prefixo            ?","mv_ch3","C",3,0,0,"G","","mv_par03","","","","","","","","","","","","","","",""})

DbSelectArea("SX1")
DbSetOrder(1)
For i:=1 to Len(aRegs)
	If !DbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j<=Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
DbSelectArea(cAlias)
Return
