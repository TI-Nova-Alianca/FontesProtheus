// Programa...: ZB1
// Autor......: Cláudia Lionço
// Data.......: 21/08/2020
// Descricao..: Tela de extrato de recebimento Cielo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de extrato de recebimento Cielo
// #PalavasChave      #extrato #cielo #recebimento #cartoes 
// #TabelasPrincipais #ZB1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB1()
	Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private aCores    := {}
	Private cCadastro := "Extrato de recebimento Cielo"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
		AADD(aRotina, {"&Visualizar" 	     , "AxVisual"      , 0, 1})
		AADD(aRotina, {"Importar"    	     , "U_ZB1_IMP()"   , 0, 4})
		AADD(aRotina, {"Conciliar Cielo Loja", "U_ZB1_CON('1')", 0, 4})
		AADD(aRotina, {"Conciliar Cielo Link", "U_ZB1_CON('2')", 0, 4})
		AADD(aRotina, {"Relatorio de titulos", "U_ZB1RTIT()"   , 0, 4})
		AADD(aRotina, {"Fechar Registro"     , "U_ZB1_FEC()"   , 0, 6})

		AADD(aCores,{ "ZB1_STAIMP == 'I'", 'BR_VERMELHO' }) // importado
        AADD(aCores,{ "ZB1_STAIMP == 'C'", 'BR_VERDE'    }) // conciliado
		AADD(aCores,{ "ZB1_STAIMP == 'F'", 'BR_PRETO'    }) // fechado
                      
		dbSelectArea ("ZB1")
		dbSetOrder (1)
		_sFiltrTop := "ZB1_FILIAL ='" + cFilAnt +"'"
		mBrowse(,,,,"ZB1",,,,,,aCores,,,,,,,,_sFiltrTop)
	EndIf

Return







