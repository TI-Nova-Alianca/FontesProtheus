// Programa...: ZB3
// Autor......: Cláudia Lionço
// Data.......: 16/12/2020
// Descricao..: Tela de recebimentos Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de recebimentos Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce 
// #TabelasPrincipais #ZB3
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 12/07/2021 - Cláudia - Incluido estatus recusado/devolvido
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB3()
	//Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Extrato de recebimento Pagar.me"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
		AADD(aRotina, {"&Visualizar" 	     , "AxVisual"        , 0, 1 })
		AADD(aRotina, {"Conciliar "          , "U_ZB3CON()"      , 0, 4 })
		AADD(aRotina, {"Importar"            , "U_BatPagar('2')" , 0, 4 })
		AADD(aRotina, {"&Legenda"        	 , "U_ZB3LGD(.F.)"   , 0 ,5 })
		AADD(aRotina, {"Relatorio importação", "U_ZB3REL()"      , 0, 6 })
		AADD(aRotina, {"Fechar Registro"     , "U_ZB3FEC()"      , 0, 6 })

		AADD(_aCores,{ "ZB3_STAIMP == 'I'", 'BR_VERMELHO' }) // importado
		AADD(_aCores,{ "ZB3_STAIMP == 'C'", 'BR_VERDE'    }) // conciliado
		AADD(_aCores,{ "ZB3_STAIMP == 'F'", 'BR_PRETO'    }) // fechado
		AADD(_aCores,{ "ZB3_STAIMP == 'R'", 'BR_AMARELO'  }) // devolvido/recusado
                      
		dbSelectArea ("ZB3")
		dbSetOrder (3)

		mBrowse(,,,,"ZB3",,,,,,_aCores,,,,,,,,)
	EndIf
Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZB3LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
	aadd (aCores, {"ZB3->ZB3_STAIMP=='I'", 'BR_VERMELHO' , 'Importados'			})
	aadd (aCores, {"ZB3->ZB3_STAIMP=='C'", 'BR_VERDE'	 , 'Baixados'			})
	aadd (aCores, {"ZB3->ZB3_STAIMP=='F'", 'BR_PRETO'	 , 'Fechados'			})
	aadd (aCores, {"ZB3->ZB3_STAIMP=='R'", 'BR_AMARELO'	 , 'Devolvido/recusado'	})

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
Return





