* Programa..: ML_LVDA.PRX
* Autor.....: Ricardo
* Data......: 9:39pm Abr 20,1999
* Nota......: ExecBlock Lancto Padrao Vendas
//
// Historico de alteracoes:
// 16/06/2008 - Robert - Passa a validar o parametro VA_SERIECF
// 29/07/2009 - Robert - Passa a somar d2_icmsret no valor retornado
// 18/03/2010 - Robert - TES 603 (venda sucata) retorna valor zerado.
//

#include "rwmake.ch"

User Function Ml_lvda()

SetPrvt("_WVAL,")

IF  SF4->F4_DUPLIC<>"S" .OR. SD2->D2_TIPO=="D" .OR. SD2->D2_TES$"518/510/603" .OR. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .OR.;
    SF4->F4_TOCON$('15/16')
    _wVAL:=0
ELSE
//   _wVAL:=SD2->D2_TOTAL+SD2->D2_VALIPI
_wVAL:=SD2->D2_TOTAL+SD2->D2_VALIPI+sd2->d2_icmsret
ENDIF

Return(_wVAL)
