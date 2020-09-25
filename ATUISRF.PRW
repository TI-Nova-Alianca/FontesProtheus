#include "rwmake.ch"

User Function ATUISRF()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³  ATUISRF ³ Autor ³     Jeferson Rech     ³ Data ³ Jul/2003 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Atualizacao do Codigo ISRF - DIF Bebidas -Prod. e NF Saida ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Cooperativa Nova Alianca                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Local cCadastro := "Atualizacao da Codigo ISRF - DIF-Bebidas"
Local aSays     := {}
Local aButtons  := {}
Local nOpca     := 0
Local lPerg     := .F.

Private cPerg   := "ATISRF"
ValidPerg()
Pergunte(cPerg,.F.)      // Pergunta no SX1

AADD(aSays,"  Este programa tem como objetivo realizar Atualizacao do Codigo      ")
AADD(aSays,"  ISRF - DIF-Bebidas no Cadastro de de Produtos e Itens de NFs Saida, ")
AADD(aSays,"  com base no Cadastro de Complemento de Produtos.                    ")

AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )

FormBatch( cCadastro, aSays, aButtons )

If nOpca == 1
	Processa( { |lEnd| Continua() } )
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Funcao atualiza CODISRF                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function Continua()

DbSelectArea("SB5")
Processa({|| ML_CNT2()},"Processando ...")
Return
Static Function ML_CNT2()
ProcRegua(RecCount())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Processando                                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("SB5")
DbSetOrder(1)
DbSeek(xFilial("SB5")+mv_par01,.T.)
Do While !Eof() .And. SB5->B5_FILIAL==xFilial("SB5") .And. SB5->B5_COD <= mv_par02
	IncProc("Processando Produto: "+SB5->B5_COD)
	_xCOD     := SB5->B5_COD
	_xCODISRF := SB5->B5_CODISRF
	_xINSUMO  := SB5->B5_INSUMO
	
	// Cadastro de Produtos
	DbSelectArea("SB1")
	DbSetOrder(1)
	DbSeek(xFilial("SB1")+_xCOD,.F.)
	If Found()
		RecLock("SB1",.F.)
		SB1->B1_CODISRF := _xCODISRF
		SB1->B1_INSUMO  := _xINSUMO
		MsUnLock()
	Endif
	
	// Cadastro de Itens NF de Saida
	DbSelectArea("SD2")
	DbSetOrder(1)
	DbSeek(xFilial("SD2")+_xCOD)
	Do While !Eof() .And. SD2->D2_FILIAL+SD2->D2_COD == xFilial("SD2")+_xCOD
		
		RecLock("SD2",.F.)
		SD2->D2_CODISRF := _xCODISRF
		MsUnLock()
		
		DbSelectArea("SD2")
		DbSkip()
	EndDo
	
	// Cadastro de Itens NF de Entrada
	DbSelectArea("SD1")
	DbSetOrder(2)
	DbSeek(xFilial("SD1")+_xCOD)
	Do While !Eof() .And. SD1->D1_FILIAL+SD1->D1_COD == xFilial("SD1")+_xCOD
		
		RecLock("SD1",.F.)
		SD1->D1_INSUMO  := _xINSUMO
		MsUnLock()
		
		DbSelectArea("SD1")
		DbSkip()
	EndDo
	
	DbSelectArea("SB5")
	DbSkip()
Enddo

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Retorna Indice Principal                                     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DbSelectArea("SB5")
RetIndex("SB5")
DbSelectArea("SB1")
RetIndex("SB1")
DbSelectArea("SD2")
RetIndex("SD2")
DbSelectArea("SD1")
RetIndex("SD1")

Return(.T.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Perguntas no SX1                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ValidPerg()
Local j := 0
Local i := 0

cAlias := Alias()
aRegs  := {}

//          Grupo/Ordem/Pergunta             /PE/PI/Variavel/Tip/T/D/P/GSC/Vl/Var01
AADD(aRegs,{cPerg,"01","Produto Inicial    ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1",""})
AADD(aRegs,{cPerg,"02","Produto Final      ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1",""})

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

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Valida o TudoOk do Processamento                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function _TudoOk()

Local _aArea    := GetArea()
Local _lRet     := .T.

RestArea(_aArea)
Return(_lRet)

