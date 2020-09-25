#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function Lan017()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

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


IF SRZ->RZ_FILIAL == "02"
   Conta :="3220119"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50111001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50111002"
   Conta := "3210118"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50121002" .AND. ALLTRIM(SRZ->RZ_CC) <= "50121004"
   Conta := "3220119"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50131001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50132002"
   Conta := "3120323"
ELSEIF  ALLTRIM(SRZ->RZ_CC) >= "50231001" .AND. ALLTRIM(SRZ->RZ_CC) <= "50241001"
   Conta := "3120323"
ENDIF

DbselectArea(_cAlias)
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Conta)
Return(Conta)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

