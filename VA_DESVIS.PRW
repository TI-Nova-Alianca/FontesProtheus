#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

//GATILHO C6_DESCVIS // PERCENTUAL DE DESCONTO A VISTA

User Function VA_DESVIS()

Local condpag	  := M->C5_CONDPAG
preco     := 0

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



	//se inserido percentual maior que o de tabela
  //	if PercDesc > DescVista
 //		MSGINFO("Percentual de desconto maior que o permitido em tabela")
 //		GDFieldPut("C6_DESCVIS",0)
 //		GDFieldPut("C6_VALVIST",0)
//	else 
/*
		DescVista:=PercDesc
		if DescVista>0
			prunit:=	GDFieldGet("C6_PRCVEN",) - GDFieldGet("C6_PRCVEN",)* (DescVista/100)
			GDFieldPut("C6_VALVIST",GDFieldGet("C6_PRCVEN",)* (DescVista/100))
			GDFieldPut("C6_PRCVEN",ROUND(prunit,2))
			qnt		:=GDFieldGet("C6_QTDVEN",)
			tot		:=qnt*prunit
			ROUND(GDFieldPut("C6_VALOR",tot),2)
		endif
		*/
//	Endif
//Endif
//Return DescVista
