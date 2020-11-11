// Programa...: ZB2
// Autor......: Cláudia Lionço
// Data.......: 10/11/2020
// Descricao..: Tela de extrato de recebimento Banrisul
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de extrato de recebimento Banrisul
// #PalavasChave      #extrato #banrisul #recebimento #cartoes 
// #TabelasPrincipais #ZB2
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB2()
	Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private aCores    := {}
	Private cCadastro := "Extrato de recebimento Banrisul"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
		AADD(aRotina, {"&Visualizar" 	     , "AxVisual"       , 0, 1})
		AADD(aRotina, {"Importar"    	     , "U_ZB2_IMP()"    , 0, 4})
		AADD(aRotina, {"Conciliar Barisul"   , "U_ZB2_CON()"    , 0, 4})
		AADD(aRotina, {"Fechar Registro"     , "U_ZB2_FEC()"   , 0, 6})

		AADD(aCores,{ "ZB2_STAIMP == 'I'", 'BR_VERMELHO' }) // importado
        AADD(aCores,{ "ZB2_STAIMP == 'C'", 'BR_VERDE'    }) // conciliado
		AADD(aCores,{ "ZB2_STAIMP == 'F'", 'BR_PRETO'    }) // fechado
                      
		dbSelectArea ("ZB2")
		dbSetOrder (1)
		_sFiltrTop := "ZB2_FILIAL ='" + cFilAnt +"'"
		mBrowse(,,,,"ZB2",,,,,,aCores,,,,,,,,_sFiltrTop)
	EndIf

Return







