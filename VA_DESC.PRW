#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

//GATILHO C6_DESCONT

User Function VA_DESC()

preco     := 0
// se alterou o % de desconto pra zero, soma o valor do desconto no preco e zera o valor do desconto
if GDFieldGet("C6_DESCONT") = 0
    preco := GDFieldGet("C6_PRCVEN") + GDFieldGet("C6_VALDESC")
    GDFieldPut("C6_VALDESC", 0)
else
    // se alterou informou um % de desconto, calcula o valor do desconto e diminui do preco de venda
    GDFieldPut("C6_VALDESC", GDFieldGet("C6_VAPRCVE") * (GDFieldGet("C6_DESCONT")/100) )
    preco :=  GDFieldGet("C6_VAPRCVE") - GDFieldGet("C6_VALDESC")
endif
                                                                                        
Return preco