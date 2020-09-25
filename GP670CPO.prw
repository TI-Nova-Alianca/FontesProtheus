// Programa:  GP670CPO
// Autor:     Fernando Possoli
// Data:      05/11/2014
// Descricao: Grava E2_HIST 
//
// Historico de alteracoes:
//

#include "rwmake.ch"
#include "topconn.ch"

//Grava E2_HIST

User Function GP670CPO()

_cAlias:=Alias()

_cDesc:=RC1->RC1_DESCRI
_aGrvSe2 := {}

RECLOCK("SE2",.F.)
	SE2->E2_HIST:=alltrim(_cDesc)+"Ref Mes " + MESEXTENSO(MONTH(DDATABASE))+"/"+ALLTRIM(STR(YEAR(DDATABASE)))
MsUnlock()

DbSelectArea(_cAlias)
RecLock("RC1",.F.,.F.)

Return