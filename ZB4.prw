// Programa...: ZB4
// Autor......: Cláudia Lionço
// Data.......: 24/02/2021
// Descricao..: Tela de conta bancaria x conta transitória
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Tela de conta bancaria x conta transitória
// #PalavasChave      #conta_bancaria #conta_transitoria #transferencia_entre_filiais
// #TabelasPrincipais #ZB4
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB4()
	//Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Conta Bancária X Conta Transitória"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
        aAdd(aRotina, {"Pesquisar"   , "AxPesqui"       , 0, 1})
        aAdd(aRotina, {"Visualizar"  , "AxVisual"       , 0, 2})
        aAdd(aRotina, {"Incluir"     , "AxInclui"       , 0, 3})
        aAdd(aRotina, {"Alterar"     , "AxAltera"       , 0, 4})
        aAdd(aRotina, {"Excluir"     , "AxDeleta"       , 0, 5})
		    
        dbSelectArea ("ZB4")
		dbSetOrder (1)
		//_sFiltrTop := "ZB4_FILIAL ='" + cFilAnt +"'"
		mBrowse(,,,,"ZB4",,,,,,,,,,,,,,)
	EndIf

Return
