// Gatilho no cadastro no campo C5_CLIENTE que vefirica se o campo A1_SATIV1 no cadastro do cliente está preenchido.

# include "protheus.ch"                                                                 	

User Function VA_SC5CLI()
_RET := .T.
If Empty(Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI, "A1_SATIV1"))  
	if m->c5_tipo == 'N'
   		u_help("Para finalizar o pedido, favor informar o Segmento(A1_SATIV1) do cliente "+C5_CLIENTE+" no seu cadastro.") 
   	   //	_RET := .F.
   ENDIF
EndIf

Return (_RET)