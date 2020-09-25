// Programa...: SPEDAut
// Autor......: Robert Koch
// Data.......: 29/04/2015
// Descricao..: Programa auxiliar a ser chamado apos a geracao de notas de saida (modulos de faturamento e OMS)
//              e de entrada (com formulario proprio). Verifica se as notas estao autorizadas e chama impressao de DANFe.
//
// Historico de alteracoes:
// 

#include "rwmake.ch"  // Deixar este include para aparecerem os botoes da tela de acompanhamento do SPED

// --------------------------------------------------------------------------
User Function SPEDH020()
Local aRet := {}
Local nPos := 0
Local cProduto := PARAMIXB[1]

dbSelectArea("SB1")
SB1->(dbSetOrder(1))
If SB1->(MsSeek( xFilial("SB1") + cProduto))
Aadd(aRet,{})
nPos := Len(aRet)
Aadd(aRet[nPos], "010") // CST ICMS
Aadd(aRet[nPos], 10.00) // Base de cálculo do ICMS (Unitário)
Aadd(aRet[nPos],1.80) // VAlor do ICMS (Unitário)
EndIF

Return aRet