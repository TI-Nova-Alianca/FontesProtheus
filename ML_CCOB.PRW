#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function ML_Ccob()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("XCEPCOB,")

* Autor : Rogerio
* Data  : 03/06/98
* Nota  : ExecBlock p/ Padrao Cnab - Chama do Arquivo Cnab Configurador
//
// Historico de alteracoes:
// 03/09/2008 - Robert - Troca de campos a1_muncob, a1_baicob, a1_estcob para campos padrao.
//

xCEPCOB:=SA1->A1_CEP
If !Empty(SA1->A1_CEPC)
   xCEPCOB:=SA1->A1_CEPC
EndIf
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(xCEPCOB)
Return(xCEPCOB)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01
