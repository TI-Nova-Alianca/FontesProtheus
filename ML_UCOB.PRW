#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function ML_Ucob()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//� Declaracao de variaveis utilizadas no programa atraves da funcao    �
//� SetPrvt, que criara somente as variaveis definidas pelo usuario,    �
//� identificando as variaveis publicas do sistema utilizadas no codigo �
//� Incluido pelo assistente de conversao do AP5 IDE                    �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

SetPrvt("XESTCOB,")

* Autor : Rogerio
* Data  : 03/06/98
* Nota  : ExecBlock p/ Padrao Cnab - Chama do Arquivo Cnab Configurador
//
// Historico de alteracoes:
// 03/09/2008 - Robert - Troca de campos a1_muncob, a1_baicob, a1_estcob para campos padrao.
//

xESTCOB:=SA1->A1_EST
If !Empty(SA1->A1_ESTC)
   xESTCOB:=SA1->A1_ESTC
EndIf
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(xESTCOB)
Return(xESTCOB)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01
