// Programa...: ZC0
// Autor......: Cláudia Lionço
// Data.......: 20/05/2022
// Descricao..: Conta corrente Rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Conta corrente Rapel
// #PalavasChave      #rapel #conta_corrente 
// #TabelasPrincipais #ZC0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZC0()
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Conta corrente rapel"

    AADD(aRotina, {"&Visualizar"    , "AxVisual"      , 0, 1})
    AADD(aRotina, {"&Legenda"       , "U_ZC0LGD (.F.)", 0 ,5})

    AADD(_aCores,{ "ZC0_TM == '01'" , 'BR_AMARELO'   }) // Inclusão de saldo manual
    AADD(_aCores,{ "ZC0_TM == '02'" , 'BR_VERDE'     }) // Crédito
    AADD(_aCores,{ "ZC0_TM == '03'" , 'BR_VERMELHO'  }) // Débito

    dbSelectArea ("ZC0")
    dbSetOrder (1)
    mBrowse(,,,,"ZC0",,,,,,_aCores,,,,,,,,)

Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZC0LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
    aadd (aCores, {"ZC0->ZC0_TM == '01'" , 'BR_AMARELO' , 'Inclusão de saldo manual'	})
    aadd (aCores, {"ZC0->ZC0_TM == '02'" , 'BR_VERDE'   , 'Crédito'	})
    aadd (aCores, {"ZC0->ZC0_TM == '03'" , 'BR_VERMELHO', 'Débito'	})

	if ! _lRetCores
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 2], aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", aCores2)
	else
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 1], aCores [_i, 2]})
		next
		return aCores
	endif
return
