#include "rwmake.ch" 
#include "topconn.ch" 

/* 
����������������������������������������������������������������������������� 
����������������������������������������������������������������������������� 
�������������������������������������������������������������������������ͻ�� 
���Programa �FINA200   � Autor �      Junior        � Data � 02/07/12   ��� 
�������������������������������������������������������������������������͹�� 
���Descricao � O ponto de entrada FINA200 do CNAB a receber sera executado��� 
���          �apos carregar os dados do arquivo de recepcao bancaria e    ��� 
���          �sera utilizado para alterar os dados recebidos linha a linha��� 
�������������������������������������������������������������������������͹�� 
���Uso       � FINA200 - CNAB a receber ( < aValores> ) --> URET          ��� 
�������������������������������������������������������������������������ͼ�� 
����������������������������������������������������������������������������� 
����������������������������������������������������������������������������� 
*/ 


User Function FINA200()  
   
// esta programa��o est� no ponto de entrada F200VAR
//if SEE->EE_CODIGO == "041" .and. (nDespes > 0 .or. nJuros > 0) 
//     nValrec := (nValrec + nDespes + nJuros)
//endif 

return 
