#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function LAN016()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//� Declaracao de variaveis utilizadas no programa atraves da funcao    �
//� SetPrvt, que criara somente as variaveis definidas pelo usuario,    �
//� identificando as variaveis publicas do sistema utilizadas no codigo �
//� Incluido pelo assistente de conversao do AP5 IDE                    �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

SetPrvt("_CALIAS,CONTA,")

* Programa..: LAN016.PRX
* Autor.....: Fernando
* Data......: 10:30am Fev 16,1999
* Nota......: Informa Contas D괷ito Folha de Pagamento
                 
_cAlias :=Alias()
DbselectArea("SRZ")

/*.....
       LAN016.prx
       Lan놹mento Contabil de Folha de Pagamento - a D괷ito
.....*/
Conta :=space(15)

IF SRZ->RZ_FILIAL == "02"
   Conta :="3220323"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50111001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50111002"
   Conta := "3210117"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50121002" .AND. ALLTRIM(SRZ->RZ_CC) <= "50121004"
   Conta := "3220117"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50131001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50132002"
   Conta := "3120320"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50231001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50241001"
   Conta := "3120320"
ENDIF

DbselectArea(_cAlias)
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Conta)
Return(Conta)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

