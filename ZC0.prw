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

    AADD(aRotina, {"&Visualizar"       , "AxVisual"       , 0, 1})
    AADD(aRotina, {"&Legenda"          , "U_ZC0LGD (.F.)" , 0 ,5})
	AADD(aRotina, {"&Rel.Rapel"        , "U_ZC0REL()"     , 0 ,6})
	AADD(aRotina, {"&Consulta Saldos"  , "U_ZC0SAL(ZC0->ZC0_CODRED, ZC0->ZC0_LOJRED)"     , 0 ,6})

    AADD(_aCores,{ "ZC0_TM == '01'"         , 'BR_AMARELO'   }) // Inclusão de saldo manual
    AADD(_aCores,{ "ZC0_TM $ '02/05/06/08'" , 'BR_VERDE'     }) // Crédito
    AADD(_aCores,{ "ZC0_TM $ '03/04/07'"    , 'BR_VERMELHO'  }) // Débito

    dbSelectArea("ZC0")
    dbSetOrder(2)
    mBrowse(,,,,"ZC0",,,,,,_aCores,,,,,,,,)

Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZC0LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
    aadd (aCores, {"ZC0->ZC0_TM == '01'" 						, 'BR_AMARELO' 	, 'Inclusão de saldo inicial/manual'	})
    aadd (aCores, {"ZC0->ZC0_TM $ '02/05/06/08'" 				, 'BR_VERDE'   	, 'Crédito'	})
    aadd (aCores, {"ZC0->ZC0_TM $ '03/04/07'" 					, 'BR_VERMELHO'	, 'Débito'	})
	//aadd (aCores, {"ZC0->ZC0_TM == '09'" 					    , 'BR_PRETO'	, 'Saldo fechamento'	})

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
//
// --------------------------------------------------------------------------
// Retorna Saldo Rapel da Rede selecionada
User Function ZC0SAL(_sRede, _sLoja)
	Local oButton1
	Local oSay1
	Local oSay2
	Local oSay3
	//Local oSay4
	Local oSay5
	Static oDlg

	_oCtaRapel := ClsCtaRap():New ()
	_sSaldo    := "R$ " + alltrim(str(_oCtaRapel:BuscaSaldo(_sRede, _sLoja)))
	_sNome     := _oCtaRapel:RetNomeRede(_sRede, _sLoja)
	_sRed      := _sRede + " - " + _sNome


  DEFINE MSDIALOG oDlg TITLE "Saldo de Rapel da Rede" FROM 000, 000  TO 150, 500 COLORS 0, 16777215 PIXEL

    @ 020, 012 SAY oSay1 PROMPT "Rede:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 020, 045 SAY oSay2 PROMPT _sRed SIZE 195, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 035, 012 SAY oSay3 PROMPT "Saldo Atual:" SIZE 030, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //@ 005, 085 SAY oSay4 PROMPT "RAPEL - SALDO ATUAL DA REDE" SIZE 067, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 035, 045 SAY oSay5 PROMPT _sSaldo SIZE 100, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 053, 197 BUTTON oButton1 PROMPT "Ok" SIZE 037, 012 OF oDlg ACTION  oDlg:End ()  PIXEL

  ACTIVATE MSDIALOG oDlg CENTERED
Return
