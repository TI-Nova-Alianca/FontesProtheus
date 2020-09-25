#include "totvs.ch"
#include "protheus.ch"

User Function DL200BRW()

Local aRet := PARAMIXB

Aadd(aRet,{"PED_MUN",,"Cidade"})
Aadd(aRet,{"PED_EST",,"Estado"})

Return aRet