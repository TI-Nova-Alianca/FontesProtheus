// Programa...: VA_SZT
// Autor......: Cl�udia Lion�o
// Data.......: 21/11/2024
// Descricao..: Par�metros de Safra
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Tela
// #Descricao         #Par�metros de Safra
// #PalavasChave      #safra #tabelas_de_preco_uva #tabelas_de_preco 
// #TabelasPrincipais #SZT
// #Modulos   		  #COOP 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function VA_SZT()
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Par�metros de Safra"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("N�o foi poss�vel obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
        aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0,1})
		aadd (aRotina, {"&Visualizar"       , "AxVisual", 0,1})
                      
		dbSelectArea("SZT")
		dbSetOrder(1)	 
		mBrowse(6,1,22,75,"SZT")
	EndIf

Return





