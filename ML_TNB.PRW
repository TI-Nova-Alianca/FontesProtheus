/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³  ML_TNB  ³ Autor ³ Eleandro Casagrande ³ Data ³  Fev/2001  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Relatorio de Titulos Nao Baixados p/ estado                ³±±
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
//
// Historico de alteracoes:
// 05/06/2010 - Robert - Perguntas ajustadas para versao 10
// 18/06/2016 - Catia  - alterado nome da Cooperativa 

#include "rwmake.ch"
User Function ml_tnb()
	cString   := "SE1"
	cDesc1    := "Este Programa Tem Como Objetivo a Impressao do Relatorio de titulos"
	cDesc2    := "nao baixados p/estado especifico p/ Cooperativa Agroindustrial Nova Alianca."
	cDesc3    := ""
	tamanho   := "M"
	aReturn := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	nLastKey  := 0
	cPerg     := "ML_XXB"
	titulo    := "Relatorio Financeiro"
	wnrel     := "ML_TNB"
	nomeprog  := "ML_TNB"
	nTipo     := 0
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica as perguntas selecionadas                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	_ValidPerg()
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
	
	RptStatus({|| RptDetail()})
Return



Static Function RptDetail()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa regua de impressao                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SetRegua(LastRec())
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para Impressao do Cabecalho e Rodape    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria o cabecalho.                                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cabec1 := "Codigo  Nome do Cliente                      Municipio                 UF  Telefone           Titulo     Vencimento    Vlr Titulo "
	cabec2 := ""
	
	//@ li,000 PSAY CHR(15)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verificacao dos Dados                                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	DbSelectArea("SE1")      // Cabecalho da NF de Saida
	DbSetOrder(2)
	DbSeek(xFilial(),.T.)
	Do While !Eof() .And. xFilial()==SE1->E1_FILIAL
		IncRegua()
		If li>56
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		
		_xNUMTIT := SE1->E1_NUM
		_xCODCLI := SE1->E1_CLIENTE
		_xLOJCLI := SE1->E1_LOJA
		_xDBAIXA := SE1->E1_BAIXA
		_xSALTIT := SE1->E1_SALDO
		_xVENCTO := SE1->E1_VENCTO
		
		If _xDBAIXA = Ctod("")
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		
		DbSelectArea("SA1")      // Cadastro de Clientes
		DbSetOrder(1)
		DbSeek(xFilial()+_xCODCLI+_xLOJCLI)
		If Found()
			_xNOMCLI := Left(SA1->A1_NOME,35)
			_xMUNCLI := SA1->A1_MUN
			_xESTCLI := SA1->A1_EST
			_xFONCLI := SA1->A1_TEL
		Else
			_xNOMCLI := ""
			_xMUNCLI := ""
			_xESTCLI := ""
			_xFONCLI := ""
		Endif
			
		If _xESTCLI <> Mv_Par01
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		
		@ li, 001 PSAY _xCODCLI
		@ li, 009 PSAY _xNOMCLI
		@ li, 046 PSAY _xMUNCLI
		@ li, 072 PSAY _xESTCLI
		@ li, 076 PSAY _xFONCLI
		@ li, 095 PSAY _xNUMTIT
		@ li, 106 PSAY _xVENCTO
		@ li, 117 PSAY _xSALTIT    Picture "@E 99,999,999.99"
		li:=li+1
		
		DbSelectArea("SE1")
		DbSkip()
	Enddo
	
	If li!=0
		Roda(0,"",Tamanho)
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Retorna Indice Principal do Arquivo                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SE1")
	RetIndex("SE1")
	
	li:=li+1
	@ li,000 PSAY CHR(18)
	
	SetPrc(0,0)
	
	Set Device To Screen
	
	If aReturn[5] == 1
		Set Printer To
		DbCommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH() // libera fila de relatorios em spool (Tipo Rede Netware)
return


/*
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Perguntas no SX1                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Static Function ValidPerg()
cAlias := Alias()
aRegs  := {}

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
AADD(aRegs,{cPerg,"01","Estado             ?","","","mv_ch1","C",2,0,0,"G","","mv_par01","","","","","","","","","","","","","","",""})

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
*/
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Estado                        ", "C", 2,  0,  "",   "12 ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
