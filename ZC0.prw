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
// 16/12/2022 - Cláudia - Incluida validação de NF na gravação. GLPI: 12943
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZC0()
	Local _aRotAdic   := {}
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Conta corrente rapel"

	AADD(_aRotAdic, {"&Provisão Rapel"   , "U_ZC0PRO()"     							, 0, 6})
	AADD(_aRotAdic, {"&Registros Rapel"  , "U_ZC0REL()"     							, 0, 6})
	AADD(_aRotAdic, {"&Saldos Rapel"     , "U_ZC0SALDO()"     							, 0, 6})
	AADD(_aRotAdic, {"&Consulta Saldos"  , "U_ZC0SAL(ZC0->ZC0_CODRED, ZC0->ZC0_LOJRED)"	, 0, 6})

    AADD(aRotina, {"&Visualizar"       	, "AxVisual"       								, 0, 1})
	AADD(aRotina, {"Incluir"    		, "U_ZC0INC()"  	  							, 0, 3})
	AADD(aRotina, {"Excluir"    		, "U_ZC0EXC()"  		    					, 0, 6})
    AADD(aRotina, {"&Legenda"          	, "U_ZC0LGD (.F.)" 								, 0, 5})
	AADD(aRotina, {"Relatorios"         , _aRotAdic										, 0, 2})
	//AADD(aRotina, {"&Rapel Previsto"   , "U_ZC0PRE()"     							, 0, 6})
	//AADD(aRotina, {"&Fechamento"       , "U_ZC0FEC()"     							, 0, 6})
	//AADD(aRotina, {"&Abertura  "       , "U_ZC0ABE()"     							, 0, 6})

    AADD(_aCores,{ "ZC0_TM == '01'         .AND. ZC0_STATUS='A' " , 'BR_AMARELO'   }) // Inclusão de saldo manual
    AADD(_aCores,{ "ZC0_TM $ '02/05/06/08' .AND. ZC0_STATUS='A' " , 'BR_VERDE'     }) // Crédito
    AADD(_aCores,{ "ZC0_TM $ '03/04/07'    .AND. ZC0_STATUS='A' " , 'BR_VERMELHO'  }) // Débito
	AADD(_aCores,{ "ZC0_TM $ '09'          .AND. ZC0_STATUS='A' " , 'BR_PINK'      }) // saldo de fechamento
	AADD(_aCores,{ "ZC0_STATUS ='F'                             " , 'BR_PRETO'     }) // Fechados

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
	
    aadd (aCores, {"ZC0->ZC0_TM == '01'         .AND. ZC0_STATUS='A' " , 'BR_AMARELO' 	, 'Inclusão de saldo inicial/manual'})
    aadd (aCores, {"ZC0->ZC0_TM $ '02/05/06/08' .AND. ZC0_STATUS='A' " , 'BR_VERDE'   	, 'Crédito'							})
    aadd (aCores, {"ZC0->ZC0_TM $ '03/04/07'    .AND. ZC0_STATUS='A' " , 'BR_VERMELHO'	, 'Débito'							})
	aadd (aCores, {"ZC0->ZC0_TM $ '09'          .AND. ZC0_STATUS='A' " , 'BR_PINK'      , 'Saldo de fechamento '	        }) 
	aadd (aCores, {"ZC0_STATUS ='F'                                  " , 'BR_PRETO'     , 'Reg.Fechados'					}) 

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
// Incluir AxCadastro
User Function ZC0INC()
	AxInclui("ZC0",,,,,,"U_ZC0TDOK()")
Return
//
// --------------------------------------------------------------------------
// Excluir cadastro
User Function ZC0EXC()
	_oCtaRapel:= ClsCtaRap():New ()
	_oCtaRapel:Exclui(zc0 -> (recno ()), zc0 -> zc0_tm)
Return
//
// --------------------------------------------------------------------------
// Sequencia do incluir 
User Function ZC0SEQ(_sRede)
	Local _sQuery := ""

	_sQuery := " SELECT MAX (ZC0_SEQ)"
	_sQuery += " FROM " + RetSQLName ("ZC0")
	_sQuery += " WHERE ZC0_CODRED = '" + _sRede + "'"
	_sSeqZC0:= U_RetSQL (_sQuery)
	if empty (_sSeqZC0)
		_sSeqZC0 = '000000'
	endif
	
	_sSeqZC0 = soma1(_sSeqZC0)
Return _sSeqZC0
//
// --------------------------------------------------------------------------
// Retorna Saldo Rapel da Rede selecionada
User Function ZC0SAL(_sRede, _sLoja)
	Local oButton1
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay5
	Static oDlg

	_oCtaRapel := ClsCtaRap():New ()
	_sSaldo    := "R$ " + alltrim(str(_oCtaRapel:RetSaldo(_sRede, _sLoja)))
	_sNome     := _oCtaRapel:RetNomeRede(_sRede, _sLoja)
	_sRed      := _sRede + " - " + _sNome

	DEFINE MSDIALOG oDlg TITLE "Saldo de Rapel da Rede" FROM 000, 000  TO 150, 500 COLORS 0, 16777215 PIXEL

	@ 020, 012 SAY oSay1 PROMPT "Rede:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 020, 045 SAY oSay2 PROMPT _sRed SIZE 195, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 035, 012 SAY oSay3 PROMPT "Saldo Atual:" SIZE 030, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 035, 045 SAY oSay5 PROMPT _sSaldo SIZE 100, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 053, 197 BUTTON oButton1 PROMPT "Ok" SIZE 037, 012 OF oDlg ACTION  oDlg:End ()  PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED
Return
//
// --------------------------------------------------------------------------
// Realiza o fechamento dos registros
User Function ZC0FEC()
	Local _lContinua := .F.
	Private cPerg    := "ZC0FEC"

	If U_ZZUVL("137", __cUserID, .T.)
		_sMsg = "Esse processo realiza o fechamento de registros de rapel."
		_lContinua =  U_msgnoyes(_sMsg + " Deseja continuar?")

		If _lContinua
			_ValidPerg1()
			If Pergunte(cPerg,.T.)
				_oCtaRapel:= ClsCtaRap():New ()
				_oCtaRapel:FecharPeriodo(mv_par01, mv_par02)
			Else
				u_help("Processo cancelado!")
			EndIf
		EndIf		
	Else
		u_help("Usuário sem permissão para a rotina. Rotina: 137")
	EndIf
Return
//
// --------------------------------------------------------------------------
// Realiza a abertura dos registros
User Function ZC0ABE()
	Local _lContinua := .F.
	Private cPerg    := "ZC0ABE"

	If U_ZZUVL("137", __cUserID, .T.)
		_sMsg = "Esse processo realiza a abertura de registros de rapel, do ultimo período fechado."
		_lContinua =  U_msgnoyes(_sMsg + " Deseja continuar?")

		If _lContinua
			_oCtaRapel:= ClsCtaRap():New ()
			_oCtaRapel:AbrirPeriodo()
		Else
			u_help("Processo cancelado!")
		EndIf
	Else
		u_help("Usuário sem permissão para a rotina. Rotina: 137")
	EndIf
Return
//
// --------------------------------------------------------------------------
// valida NF digitada
User Function ZC0TDOK()
	Local _oSQL := ClsSQL ():New ()
	Local _lRet := .T.

    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT * FROM SF2010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
	_oSQL:_sQuery += " AND F2_FILIAL   ='"+ xfilial("ZC0") +"'"
	_oSQL:_sQuery += " AND F2_DOC      ='"+ M->ZC0_DOC    +"'"
	_oSQL:_sQuery += " AND F2_SERIE    ='"+ M->ZC0_SERIE  +"'"
	_aNFe := aclone (_oSQL:Qry2Array ())

	If Len(_aNFe) > 0
		_lRet := .T.
	else
		u_help(" Nota fiscal não encontrada!")
		_lRet := .F.
	EndIf
	
Return _lRet
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg1 ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de          ", "D", 8, 0,  "",   "   "     , {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data até         ", "D", 8, 0,  "",   "   "     , {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return


