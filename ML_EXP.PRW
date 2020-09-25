#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 11/10/00
#IFNDEF WINDOWS
   #DEFINE PSAY SAY
#ENDIF

User Function ml_exp()        // incluido pelo assistente de conversao do AP5 IDE em 11/10/00

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("CSTRING,CDESC1,CDESC2,CDESC3,TAMANHO,ARETURN")
SetPrvt("ALINHA,NLASTKEY,CPERG,TITULO,WNREL,NTIPO")
SetPrvt("NLIN,NTAMNF,LI,M_PAG,_ZMAT,_XMAT")
SetPrvt("_XFUNCAO,_XSAL,CALIAS,AREGS,I,J")

// Programa..: ML_EXP.PRX
// Autor.....: Rosmari Arboit   
// Data......: 26/04/2001
// Nota......: Emissao Relatorio Contrato de Experiencia 

#IFNDEF WINDOWS
// Movido para o inicio do arquivo pelo assistente de conversao do AP5 IDE em 11/10/00 ==>    #DEFINE PSAY SAY
#ENDIF

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01     // Matricula De                                 ³
//³ mv_par02     // Matricula Ate                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis obrigatorias dos programas de relatorio            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cString :="SRA"
cDesc1  :="Este programa tem como objetivo, Imprimir o Contrato   "
cDesc2  :="de Experiencia             "
cDesc3  :=""
tamanho :="P"
aReturn :={ "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
aLinha  :={ }
nLastKey:=0
cPerg   :="ML_XPE"
titulo  :="Contrato de Experiencia        "
wnrel   :="ML_EXP"
nTipo   :=0
nLin    :=0
nTamNf  :=32

ValidPerg()
Pergunte(cPerg,.F.)      // Pergunta no SX1

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

#IFDEF WINDOWS
   RptStatus({|| RptDetail()})// Substituido pelo assistente de conversao do AP5 IDE em 11/10/00 ==>    RptStatus({|| Execute(RptDetail)})
   Return
// Substituido pelo assistente de conversao do AP5 IDE em 11/10/00 ==>    Function RptDetail
Static Function RptDetail()
#ENDIF

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa  regua de impressao                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SetRegua(LastRec())

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa os codigos de caracter Comprimido/Normal da impressora ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nTipo := IIF(aReturn[4]==1,15,18)
li    := 0
m_pag := 1

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Posiciona o Arquivo na ordem correta.                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

_zMAT:="######"
DbSelectArea("SRA")                // * Cadastro de Funcionarios
DbSetOrder(1)
DbSeek(xFilial()+mv_par01,.T.)
Do While !Eof() .and. xFilial() == SRA->RA_FILIAL .And. SRA->RA_MAT <= mv_par02
_xMat:=SRA->RA_MAT
_xFuncao:=SRA->RA_CODFUNC
_xCcusto:=SRA->RA_CC
_xTurno:=SRA->RA_TNOTRAB
_xSal:=IIF(SRA->RA_CATFUNC="H",(SRA->RA_SALARIO * SRA->RA_HRSMES),SRA->RA_SALARIO)
      If _zMAT <> _xMAT
         If _zMAT <> "######" 
           li := 0
         Endif
         _zMAT:=_xMAT
      Endif
           li := li + 3
           @ li, 020 PSAY "CONTRATO DE TRABALHO A TITULO DE EXPERIENCIA"
           li := li + 3
           @ LI, 000 PSAY "Por este instrumento particular, que entre si fazem a firma "+SUBSTR(SM0->M0_NOMECOM,1,23)
           li := li + 1
           @ li, 000 PSAY SUBSTR(SM0->M0_NOMECOM,24,7)+", com sede em "+AllTrim(SM0->M0_CIDCOB)+" a "+AllTrim(SM0->M0_ENDCOB)+" neste  ato  denominada"
           li := li + 1
           @ li, 000 PSAY "simplesmente  'EMPREGADORA', e o Sr.(a) "+SRA->RA_NOME+" portador  da"
           li := li + 1
           @ li, 000 PSAY "CTPS "+SRA->RA_NUMCP+", SERIE "+SRA->RA_SERCP+" doravante chamado simplesmente 'EMPREGADO', firmam o pre-"
           li := li + 1
           @ li, 000 PSAY "sente Contrato Individual de Trabalho, em carater de Experiencia, conforme  a letra" 
           li := li + 1
           @ li, 000 PSAY "'C', paragrafo 2 do Artigo 443 da C.L.T., mediante as seguintes condicoes:"
           li := li + 2
DbSelectArea("SRJ")                // * Funcao
DbSetOrder(1)
DbSeek(xFilial()+_xFuncao,.T.)
DbSelectArea("SI3")                // * Centro de Custo
DbSetOrder(1)
DbSeek(xFilial()+_xCcusto,.T.)
DbSelectArea("SR6")                // * Turno
DbSetOrder(1)
DbSeek(xFilial()+_xTurno,.T.)
           @ li, 000 PSAY "1-) O Empregado trabalhara para a Empregadora, exercendo as funcoes de "+SUBSTR(SRJ->RJ_DESC,1,12)
           li := li + 1
           @ li, 000 PSAY "    "+SUBSTR(SRJ->RJ_DESC,13,8)+"  na   secao  "+SI3->I3_DESC+" , percebendo   o   salario   de"                                                                 
           li := li + 1
           @ li, 000 PSAY "    R$"+str(_xSal,9,2) +"("+Substr(EXTENSO(_xSal),1,67)+Replicate("*",67-Len(EXTENSO(_xSal))) 
           li := li + 1
           @ li, 000 PSAY "    "+Substr(EXTENSO(_xSal),45,80)+Replicate("*",67-Len(EXTENSO(_xSal)))+") por mes de trabalho."
           li := li + 1
           @ li, 000 PSAY "2-) O horario a ser obedecido sera o seguinte: "+SUBSTR(SR6->R6_DESC,1,36)                                    
           li := li + 1
           @ li, 000 PSAY "    "+SUBSTR(SR6->R6_DESC,37,27) 
           li := li + 1
           @ li, 000 PSAY "3-) Este contrato tem inicio a partir de "+DTOC(SRA->RA_ADMISSA)+ ", vencendo-se  em "+ DTOC(SRA->RA_VCTOEXP)+" podendo" 
           li := li + 1
           @ li, 000 PSAY "    ser prorrogado, obedecido os Artigos 445 e 451 da C.L.T.                       "
           li := li + 1
           @ li, 000 PSAY "4-) O Empregado se compromete a trabalhar em regime de compensacao e de prorrogacao"
           li := li + 1
           @ li, 000 PSAY "    de horas, inclusive em periodo noturno, sempre que a necessidade assim o exigir"
           li := li + 1
           @ li, 000 PSAY "    observadas as formalidades legais.                                             "
           li := li + 1
           @ li, 000 PSAY "5-) Obriga-se o Empregado, alem de executar com dedicacao e lealdade o seu servico,"
           li := li + 1
           @ li, 000 PSAY "    a cumprir o Regulamento Intermo da Empregadora, as instrucoes  de sua  Adminis-"    
           li := li + 1
           @ li, 000 PSAY "    tradora e as ordens de seus chefes e superiores hierarquicos, relativas as  pe-"
           li := li + 1
           @ li, 000 PSAY "    culiaridades dos servicos que lhe forem confiados."
           li := li + 1
           @ li, 000 PSAY "6-) Se qualquer das partes quiser rescindir este contrato antes do termino previsto"
           li := li + 1
           @ li, 000 PSAY "    no item 3, aplicar-se-a o disposto nos artigos 479 e 480 da  CLT, isto e,  sera"
           li := li + 1
           @ li, 000 PSAY "    devida a indenizacao por metade que resultaria ate o  termo  final do  presente"
           li := li + 1
           @ li, 000 PSAY "    contrato.                                                                      " 
           li := li + 1
           @ li, 000 PSAY "7-) Alem dos descontos de lei, reserva-se o  Empregador o direito de  descontar  do"
           li := li + 1
           @ li, 000 PSAY "    empregado os prejuizos ou danos causados por dolo, imprudencia,  negligencia ou"
           li := li + 1
           @ li, 000 PSAY "    ou impericia.                                                                  "
           li := li + 1
           @ li, 000 PSAY "8-) O presente contrato reger-se-a pelas normas constituidas  na  Consolidacao  das"
           li := li + 1
           @ li, 000 PSAY "    Leis do Trabalho e na Legislacao Trabalhista nao consolidada.                  "
           li := li + 1
           @ li, 000 PSAY "9-) Vencido o periodo de experiencia e continuando o empregado a prestar servicos a"
           li := li + 1
           @ li, 000 PSAY "    Empregadora, por tempo indeterminado, ficam prorrogadas todas as clausulas aqui" 
           li := li + 1
           @ li, 000 PSAY "    estabelecidas, enquanto nao se rescindir o Contrato de Trabalho.               "
           li := li + 2
           @ li, 000 PSAY "E por estarem de pleno acordo, assinam ambas as partes, em duas vias de igual teor."
           li := li + 1
//         @ li, 000 PSAY SPACE(40)+SM0->M0_CIDCOB+", "+right(STR(DAY(DDATABASE)),2)+" de "+MESEXTENSO(MONTH(DDATABASE))+" de "+right(STR(year(ddatabase)),4)
           li := li + 3
           @ li, 000 PSAY "---------------------------"+SPACE(11)+"-------------------------------------------"
           li := li + 1
           @ li, 000 PSAY "            DATA           "+SPACE(11)+"     ASSINATURA RESPONSAVEL QUANDO MENOR   "
           li := li + 3
           @ li, 000 PSAY "---------------------------"+SPACE(11)+"-------------------------------------------"
           li := li + 1
           @ li, 000 PSAY "        EMPREGADORA        "+SPACE(11)+"              EMPREGADO                    "
           li := li + 4
           @ li, 000 PSAY  "                        T E R M O   D E   P R O R R O G A C A O                      "
           li := li + 1
           @ li, 000 PSAY "Por mutuo acordo entre as partes,fica o presente Contrato de Experencia,que deveria"
           li := li + 1
           @ li, 000 PSAY "vencer nesta data, prorrogado ate___/___/_____."
           li := li + 3
           @ li, 000 PSAY SM0->M0_CIDCOB+","+"___/ de __________________ de ______."
           li := li + 4
           @ li, 000 PSAY "---------------------------"+SPACE(11)+"-------------------------------------------"
           li := li + 1
           @ li, 000 PSAY "         EMPREGADORA       "+SPACE(11)+"              EMPREGADO"                     
           li := li + 3
   DbSelectArea("SRA")
   DbSkip()
Enddo

Set Device To Screen

If aReturn[5]==1
   Set Printer TO
   dbcommitAll()
   ourspool(wnrel)
Endif

MS_FLUSH() //Libera fila de relatorios em spool (Tipo Rede Netware)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Perguntas no SX1                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
// Substituido pelo assistente de conversao do AP5 IDE em 11/10/00 ==> Function ValidPerg
Static Function ValidPerg()
local i := 0
local j := 0
cAlias  := Alias()
aRegs   := {}

// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
AADD(aRegs,{cPerg,"01","Matricula De          ?","mv_ch1","C",06 ,0,0,"G","","mv_par01","","","","","","","","","","","","","","","SRA"})
AADD(aRegs,{cPerg,"02","Matricula Ate         ?","mv_ch2","C",06 ,0,0,"G","","mv_par02","","","","","","","","","","","","","","","SRA"})

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
