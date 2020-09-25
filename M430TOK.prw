// Programa:   MA430PEX
// Autor:      Leandro Perondi (DWT)
// Data:       10/07/2013
// Descricao:  Ponto de entrada na valida��o de inclus�o ou altera��o de reservas
//
// Historico de alteracoes:
//
#INCLUDE "Protheus.ch"    

User Function M430TOK()

lRet := .T.

if altera
	if !Empty(C0_VAPEDID) .or. !Empty(acols[1][12])
		msgalert("Reserva n�o pode ser alterada, pois foi gerada a partir de um pedido de venda !")
		lRet := .F.
	endif 
endif

Return lRet