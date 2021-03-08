// Programa...: ZB5
// Autor......: Cláudia Lionço
// Data.......: 24/02/2021
// Descricao..: Tela de Transferencia na comunicação bancária
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Tela de Transferencia na comunicação bancária
// #PalavasChave      #conta_bancaria #conta_transitoria #transferencia_entre_filiais
// #TabelasPrincipais #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB5()
	Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Transferência na comunicação bancária"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
        // Rotinas
        //AADD(aRotina, {"Transferir"  , "U_ZB5TRANSF('" + cFilAnt + "')"  , 0, 6})
        AADD(aRotina, {"Legenda"     , "U_ZB5LGD (.F.)" , 0 ,5})

        //Legendas
	    AADD(_aCores,{ "ZB5_STATUS == 'A'", 'BR_VERDE'    }) // ABERTO
		AADD(_aCores,{ "ZB5_STATUS == 'P'", 'BR_AMARELO'  }) // PARCIAL
		AADD(_aCores,{ "ZB5_STATUS == 'F'", 'BR_VERMELHO' }) // FECHADO
                      
		dbSelectArea ("ZB5")
		dbSetOrder (1)

		If cFilAnt <> '01'
			_sFiltrTop := "ZB5_FILIAL ='" + cFilAnt +"'"
			mBrowse(,,,,"ZB5",,,,,,_aCores,,,,,,,,_sFiltrTop)
		Else
			mBrowse(,,,,"ZB5",,,,,,_aCores)
		EndIf
	EndIf
Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZB5LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
	aadd (aCores, {"ZB5->ZB5_STATUS=='A'", 'BR_VERDE'   , 'Reg. Aberto'	})
	aadd (aCores, {"ZB5->ZB5_STATUS=='P'", 'BR_AMARELO' , 'Reg. Parcial'})
	aadd (aCores, {"ZB5->ZB5_STATUS=='F'", 'BR_VERMELHO', 'Reg. Fechado'})

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



