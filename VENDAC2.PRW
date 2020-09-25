#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function VENDAC2()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("_CALIAS,CCUSTO,")

* Programa..: VENDAC2.PRX
                 
_cAlias :=Alias()
DbselectArea("SF2")

Conta :=space(15)
_cVend := ALLTRIM(POSICIONE("SA1",1,XFILIAL("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_VEND"))

IF SF2->F2_FILIAL $ "01/02" .AND. ALLTRIM(SA1->A1_VEND) $ "060/118/119/120"  
   CCUSTO :="50121003"


ELSEIF  SF2->F2_FILIAL $ "01/02" .AND. ALLTRIM(SA1->A1_VEND)$ "117/001"
   CCUSTO :="50121002"


ELSEIF  SF2->F2_FILIAL $ "01/02" .AND. !ALLTRIM (SA1->A1_VEND)$ "117/001/060/118/119/120"
   CCUSTO :="50121001"


ELSEIF SF2->F2_FILIAL= "03" .AND. ALLTRIM(SA1->A1_VEND) $ "060/118/119/120"  
   CCUSTO :="50221003"


ELSEIF  SF2->F2_FILIAL= "03" .AND. ALLTRIM(SA1->A1_VEND)$ "117/001"
   CCUSTO :="50221002"


ELSEIF  SF2->F2_FILIAL= "03" .AND. !ALLTRIM(SA1->A1_VEND)$ "117/001/060/118/119/120"
   CCUSTO :="50221001"


ENDIF

DbselectArea(_cAlias)
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Conta)
Return(CCUSTO)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

