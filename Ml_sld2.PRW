// Validacao da quantidade no pre-pedido
// Historico de alteracoes:
// 07/10/2008 - Robert - Nao bloqueia mais a digitacao. Apenas avisa.
//

#include "rwmake.ch"

User Function Ml_sld2()

Local _aArea    := GetArea()
Local _xPRODUTO := TMP1->CK_PRODUTO
Local _xLOCAL   := TMP1->CK_LOCAL
Local _xQtdven   :=TMP1->CK_QTDVEN
_XLRET:= .T.

DbSelectArea("SB2")
DbSetOrder(1)
DbSeek(xFILIAL("SB2")+_xPRODUTO+_xLOCAL)
If Found()
   If Round(SB2->B2_QATU-(_xQtdven+SB2->B2_RESERVA),3)<0
      MsgBox("Nao ha Saldo em Estoque p/ este Produto Saldo Atual: "+STR(SB2->B2_QATU,9,3)+" Qtde Reservada : "+STR(SB2->B2_RESERVA,9,3)+" ****** FAVOR PROGRAMAR C/ DPTO COMERCIAL.******","ML_ERRO","STOP")
      // Apenas avisa.  _XLRET:= .F.
   Endif
Else
   MsgBox("Aten‡Æo!! Nao ha' Saldo em Estoque p/ este Produto!","ML_ERRO","STOP")
   // Apenas avisa.  _XLRET:= .F.
EndIF

RestArea(_aArea)
Return(_XLRET)
