#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function Lan039()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("_CALIAS,CONTA,")

* Programa..: LAN007.PRX
* Autor.....: Fernando
* Data......: 10:30am Fev 16,1999
* Nota......: Informa Contas D‚bito Folha de Pagamento
                 
_cAlias :=Alias()
DbselectArea("SRZ")


/*.....
       LAN007.prx
       Lan‡amento Contabil de Folha de Pagamento - a D‚bito
.....*/
Conta :=space(15)




IF  LEFT(SRZ->RZ_CC,4)$ "5011/5021"
   Conta := POSICIONE ("SRV", 1, XFILIAL ("SRV")+SRZ->RZ_PD, "RV_CTAADM")
ELSEIF  LEFT(SRZ->RZ_CC,4)$ "5012/5022"
   Conta := POSICIONE ("SRV", 1, XFILIAL ("SRV")+SRZ->RZ_PD, "RV_CTACOM")
ELSEIF  LEFT(SRZ->RZ_CC,4)$ "5013/5014/5023/5024"
   Conta := POSICIONE ("SRV", 1, XFILIAL ("SRV")+SRZ->RZ_PD, "RV_CTAIND")
ENDIF

DbselectArea(_cAlias)
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Conta)
Return(Conta)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

