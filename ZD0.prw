// Programa...: ZD0
// Autor......: Cl�udia Lion�o
// Data.......: 06/07/2022
// Descricao..: Tela de recebimentos Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de recebimentos Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// teste teste teste
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZD0()
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Receb�veis Pagar.me"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("N�o foi poss�vel obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
		AADD(aRotina, {"&Visualizar"      	, "AxVisual"       , 0, 1 })
		AADD(aRotina, {"Importar"       	, "U_BatZD0('2')"  , 0, 3 })
		AADD(aRotina, {"Gerar RA's"        	, "U_ZD0RAS('3')"  , 0 ,3 })
		AADD(aRotina, {"Compensa��o"        , "U_ZD0CMP()"     , 0 ,3 })				
		//AADD(aRotina, {"Conciliar "     	, "U_ZD0CON()"     , 0, 4 })				
		AADD(aRotina, {"Legenda"        	, "U_ZD0LGD(.F.)"  , 0 ,5 })
        AADD(aRotina, {"Extrato"     		, "U_ZD0EXT()"     , 0, 8 })
		AADD(aRotina, {"Consulta TItulos" 	, "U_ZD0CONS()"    , 0, 8 })	

		AADD(_aCores,{ "ZD0_STABAI == 'A'", 'BR_VERMELHO' }) // aberto
		AADD(_aCores,{ "ZD0_STABAI == 'B'", 'BR_VERDE'    }) // baixado
		AADD(_aCores,{ "ZD0_STABAI == 'R'", 'BR_AZUL'     }) // Gerada RA's
		AADD(_aCores,{ "ZD0_STABAI == 'E'", 'BR_PRETO'    }) // estorno RA'a
                      
		dbSelectArea ("ZD0")
		dbSetOrder (1)

		mBrowse(,,,,"ZD0",,,,,,_aCores,,,,,,,,)
	EndIf
Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZD0LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i      := 0
	
	aadd (aCores, {"ZD0->ZD0_STABAI=='A'", 'BR_VERMELHO' , 'Aberto'		})
	aadd (aCores, {"ZD0->ZD0_STABAI=='B'", 'BR_VERDE'	 , 'Baixado'	})
	aadd (aCores, {"ZD0->ZD0_STABAI=='R'", 'BR_AZUL'	 , 'Gerada RA'	})
	aadd (aCores, {"ZD0->ZD0_STABAI=='E'", 'BR_PRETO'	 , 'Estorno RA'	})

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
