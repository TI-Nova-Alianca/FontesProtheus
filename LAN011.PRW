#include "rwmake.ch"        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

User Function Lan011()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//� Declaracao de variaveis utilizadas no programa atraves da funcao    �
//� SetPrvt, que criara somente as variaveis definidas pelo usuario,    �
//� identificando as variaveis publicas do sistema utilizadas no codigo �
//� Incluido pelo assistente de conversao do AP5 IDE                    �
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

SetPrvt("_CALIAS,CONTA,")

* Programa..: LAN011.PRX
* Autor.....: Fernando
* Data......: 10:30am Fev 16,1999
* Nota......: Informa Contas D괷ito Folha de Pagamento
                 
_cAlias :=Alias()
DbselectArea("SRZ")

/*.....
       LAN011.prx
       Lan놹mento Contabil de Folha de Pagamento - a D괷ito
.....*/
Conta :=space(15)     

IF  left (SRZ->RZ_CC, 5) >= "50111" .AND. left (SRZ->RZ_CC, 5) <= "50121"  // adm/coml
   Conta := '403010103002'
ELSEIF  left (SRZ->RZ_CC, 5) >= "50131" .AND. left (SRZ->RZ_CC, 5) <= "50132"  // indl
   Conta := '701010203002'
ELSEIF  left (SRZ->RZ_CC, 5) >= "50231" .AND. left (SRZ->RZ_CC, 5) <= "50241"  // livramento
   Conta := '701010203002'
ENDIF

DbselectArea(_cAlias)
Return(Conta)        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01
