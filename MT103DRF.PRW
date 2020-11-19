// Programa :  MT103DRF
// Autor    :  Catia Cardoso
// Data     :  20/02/2018
// Descricao:  P.E. nota fiscal de entrada - para setar o campo da DIRF e codigo de retenção de impostos
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function MT103DRF()
//Local nCombo  := PARAMIXB[1] 
//Local cCodRet := PARAMIXB[2] 
Local aImpRet := {}

aadd(aImpRet,{"IRR",1,"1708"})
aadd(aImpRet,{"PIS",1,"5952"})
aadd(aImpRet,{"COF",1,"5952"})              
aadd(aImpRet,{"CSL",1,"5952"})

Return aImpRet
