// Programa...: VA_ZA6
// Autor......: Catia Cardoso
// Data.......: 11/10/2014
// Cliente....: Alianca
// Descricao..: Controle de Verbas - Contratos
//
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function VA_ZA6()
	private cCadastro  := "Contratos"
	private cString    := "ZA6"
    private aRotina     := {}
    private cPerg      := "ZA6"
   private _sarqlog   := U_NomeLog ()
	private _sQuery := ""
   private _aDados := {}
	
    u_logId ()
	
	// Menu principal
	aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0,1})
	aadd (aRotina, {"&Visualizar"       , "AxVisual", 0,2})
	aadd (aRotina, {"&Incluir"          , "U_ZA6_I" , 0,3})
    aadd (aRotina, {"&Alterar"         , "U_ZA6_A" , 0,4})
	aadd (aRotina, {"&Excluir"          , "U_ZA6_EX" , 0,5})
    
	dbselectarea (cString)
    dbSetOrder (1)
    mBrowse(,,,,cString,,,,,2)
    
return

// -------------------------------------------------------------------------
// Inclusao
User Function ZA6_I ()
local _oCtaCorr  := NIL
    private inclui   := .T.
    private altera   := .F.
    private aGets    := {}
    private aTela    := {}
    u_logIni ()
    RegToMemory ("ZA6", inclui, inclui)
    
    if axinclui ("ZA6", za6 -> (recno ()), 3, NIL, NIL, NIL, "U_ZA6_VI()") == 1
    
        RecLock ("ZA6",.F.)
        if za6 -> za6_tp='1'
            za6 -> za6_base =' '
            za6 -> za6_perc = 0
        else
            za6 -> za6_valor = 0
        endif    
        
        MsUnLock()
    endif

    u_logFim ()
return

// --------------------------------------------------------------------------
// alteracao
User Function ZA6_A()
   private inclui   := .F.
	private altera   := .T.
   private aGets    := {}
	private aTela    := {}

    u_logIni ()
	RegToMemory ("ZA6", inclui, .T.)
	
	// Apos a alteracao do registro, faz os tratamentos necessarios.
    if axaltera ("ZA6", za6 -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_ZA6_VA()") == 1
        RecLock ("ZA6",.F.)
        if za6 -> za6_tp='1'
            za6 -> za6_base =' '
            za6 -> za6_perc = 0
        else
            za6 -> za6_valor = 0
        endif
        MsUnLock()
    endif
    u_logFim ()
return

// --------------------------------------------------------------------------
// Excluir
User Function ZA6_EX()
    private inclui   := .F.
    private altera   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZA6", inclui, .T.)
    AxDeleta ("ZA6", za6 -> (recno ()), 5)
    u_logFim ()

return

// --------------------------------------------------------------------------
// Valida inclusao
User Function ZA6_VI()
    local _lRet := .T.
    
    if m->za6_tp='1'
        if empty(m->za6_valor)
            u_help ("Obrigatório informar o valor.")    
            _lRet = .F.
        endif
    endif
    
    if m->za6_tp='2'
        if empty(m->za6_perc)
            u_help ("Obrigatório informar o percentual.")    
            _lRet = .F.
        endif
        if empty(m->za6_base)
            u_help ("Obrigatório informar o base de calculo.")    
            _lRet = .F.
        endif
    endif
    
    if _lRet
        if DbSeek(xFilial("ZA6")+m->za6_cli+m->za6_loja+m->za6_cont+m->za6_codver,.F.)
            u_help ("Verba já informada, nessa contrato/vigência/cliente.")    
            _lRet = .F. 
        endif
    endif 
return _lRet

// --------------------------------------------------------------------------
// Valida alteracao
User Function ZA6_VA ()
    local _lRet := .T.
    
    if m->za6_tp='1'
        if empty(m->za6_valor)
            u_help ("Obrigatório informar o valor.")
			_lRet = .F.
        endif
    endif
    
    if m->za6_tp='2'
        if empty(m->za6_perc)
            u_help ("Obrigatório informar o percentual.")    
            _lRet = .F.
        endif
        if empty(m->za6_base)
            u_help ("Obrigatório informar o base de calculo.")    
            _lRet = .F.
        endif
    endif
    
return _lRet