#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function Ml_ecob()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("XENDCOB,")

* Autor : Rogerio
* Data  : 03/06/98
* Nota  : ExecBlock p/ Padrao Cnab - Chama do Arquivo Cnab Configurador

xENDCOB:=SA1->A1_END
If !Empty(SA1->A1_ENDCOB)
   xENDCOB:=SA1->A1_ENDCOB
EndIf
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Left(xENDCOB,38)+'  ')
Return(Left(xENDCOB,38)+'  ')        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01
