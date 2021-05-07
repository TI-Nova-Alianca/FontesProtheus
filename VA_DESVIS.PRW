// Programa...: VA_DESVIS
// Autor......: -
// Data.......: -
// Descricao..: Percentual de desconto a vista - Gatilho campo C6_DESCVIS
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Percentual de desconto a vista - Gatilho campo C6_DESCVIS
// #PalavasChave      #gatilho #desconto_a_vista
// #TabelasPrincipais #SC5 #SC6
// #Modulos 		  #FAT         
//      
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User Function VA_DESVIS()
	Local condpag := M->C5_CONDPAG
	Local preco   := 0

	IF condpag <> '097'
		
		MSGINFO("Percentual de desconto permitido apenas para Vendas À Vista!")
		GDFieldPut("C6_VALVIST", 0)
		GDFieldPut("C6_DESCVIS", 0)
	else
		// se alterou o % de desconto pra zero, tem que desfazer o desconto dado 
		// soma o valor do desconto no preco e zera o valor do desconto
	
		if GDFieldGet("C6_DESCVIS") = 0
			preco := GDFieldGet("C6_PRCVEN") + GDFieldGet("C6_VALVIST")
			GDFieldPut("C6_VALVIST", 0)
		else
			// se alterou informou um % de desconto
			// calcula o valor do desconto a vista e diminui do preco de venda
			GDFieldPut("C6_VALVIST", GDFieldGet("C6_VAPRCVE") * (GDFieldGet("C6_DESCVIS")/100) )
			preco :=  GDFieldGet("C6_VAPRCVE") - GDFieldGet("C6_VALVIST")
		endif
	Endif
Return preco
