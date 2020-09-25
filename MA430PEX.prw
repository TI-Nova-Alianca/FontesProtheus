// Programa:   MA430PEX
// Autor:      Leandro Perondi (DWT)
// Data:       10/07/2013
// Descricao:  Este ponto de entrada é executado antes da exclusao da reserva de produto (SC0)
//
// Historico de alteracoes:
//

#INCLUDE "Protheus.ch"    

User Function MA430PEX()       

lRet := .T. 

if !Empty(C0_VAPEDID) .or. !Empty(acols[1][12])
	msgalert("Reserva não pode ser excluída, pois foi gerada a partir de um pedido de venda !")
	lRet := .F.
endif

Return lRet