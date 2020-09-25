#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function VENDASD1()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Declaracao de variaveis utilizadas no programa atraves da funcao    ³
//³ SetPrvt, que criara somente as variaveis definidas pelo usuario,    ³
//³ identificando as variaveis publicas do sistema utilizadas no codigo ³
//³ Incluido pelo assistente de conversao do AP5 IDE                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

SetPrvt("_CALIAS,CCUSTO,")

* Programa..: VENDASD1.PRX
                 
_cAlias :=Alias()
DbselectArea("SD1")

ccusto :=space(09)
_cVend := ALLTRIM(POSICIONE("SA1",1,XFILIAL("SA1")+SD1->D1_CLIENTE+SD1->D1_LOJA,"A1_VEND"))
POSICIONE("SB1",1,XFILIAL("SB1")+SD1->D1_COD,"B1_COD")
_ctpvend := POSICIONE("SA3",1,XFILIAL("SA3")+_cvend,"A3_TIPVEND")
_cCod :=  SD1->D1_COD

IF SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND="1" .AND. SB1->B1_LOCPROD $ "1/2" .AND. SB1->B1_TIPO == "PA"
   CCUSTO :="50121003"
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="2".AND. SB1->B1_LOCPROD == "1".AND.SB1->B1_TIPO=="PA"
   CCUSTO :="50121001"
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="3".AND. SB1->B1_LOCPROD == "1".AND.SB1->B1_TIPO=="PA"
   CCUSTO :="50121002"                                                                   
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="4".AND. SB1->B1_LOCPROD == "1".AND.SB1->B1_TIPO=="PA" 
   CCUSTO :="50121002"                                                                   
ELSEIF  SD1->D1_FILIAL $ "01"       .AND. SB1->B1_TIPO <> "PA"
   CCUSTO :="50121001"   
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="2".AND. SB1->B1_LOCPROD == "2" .AND.SB1->B1_TIPO=="PA"
   CCUSTO :="50221001"
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="3".AND. SB1->B1_LOCPROD == "2".AND.SB1->B1_TIPO=="PA"
   CCUSTO :="50221002"                                                                   
ELSEIF  SD1->D1_FILIAL $ "01/02/03" .AND. SA3->A3_TIPVEND=="4".AND. SB1->B1_LOCPROD == "2".AND.SB1->B1_TIPO=="PA" 
   CCUSTO :="50221002"                                                                   
ELSEIF  SD1->D1_FILIAL $ "02"       .AND. SB1->B1_TIPO <> "PA"
   CCUSTO :="50221001"   



ENDIF

DbselectArea(_cAlias)
// Substituido pelo assistente de conversao do AP5 IDE em 25/01/01 ==> __Return(Conta)
Return(CCUSTO)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

