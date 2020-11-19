// Programa...: VA_ZA7
// Autor......: Catia Cardoso
// Data.......: 11/10/2014
// Cliente....: Alianca
// Descricao..: Controle de Verbas - Vigencias de Contratos
//
// Historico de alteracoes:
// 09/09/2019 - Claudia - Na alteração de um registro, será verificada a quantidade de contratos vigentes, 
//                        com exceção do contrato que está sendo alterado. Conforme solicitação ID: 6623

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function VA_ZA7()
	private cCadastro  	:= "Contratos"
	private cString    	:= "ZA7"
    private aRotina     := {}
    private cPerg      	:= "ZA7"
    private _sarqlog   	:= U_NomeLog ()
	private _sQuery 	:= ""
    private _aDados 	:= {}

    u_logId ()
    
    // Menu principal
    aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0,1})
    aadd (aRotina, {"&Visualizar"       , "AxVisual", 0,2})
    aadd (aRotina, {"&Incluir"          , "U_ZA7_I" , 0,3})
    aadd (aRotina, {"&Alterar"          , "U_ZA7_A" , 0,4})
    aadd (aRotina, {"&Excluir"          , "U_ZA7_EX" , 0,5})
    
    dbselectarea (cString)
    dbSetOrder (1)
    mBrowse(,,,,cString,,,,,2)
    
return

// -------------------------------------------------------------------------
// Inclusao
User Function ZA7_I ()
    //local _oCtaCorr  := NIL
    private inclui   := .T.
    private altera   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZA7", inclui, inclui)
    
    if axinclui ("ZA7", za7 -> (recno ()), 3, NIL, NIL, NIL, "U_ZA7_VI()") == 1
    
        RecLock ("ZA7",.F.)
        MsUnLock()
    endif

    u_logFim ()
return

// --------------------------------------------------------------------------
// alteracao
User Function ZA7_A()
   private inclui   := .F.
   private altera   := .T.
   private aGets    := {}
   private aTela    := {}

    u_logIni ()
	RegToMemory ("ZA7", inclui, .T.)
	
	// Apos a alteracao do registro, faz os tratamentos necessarios.
    if axaltera ("ZA7", za7 -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_ZA7_VA()") == 1
        RecLock ("ZA7",.F.)
        MsUnLock()
    endif
    u_logFim ()
return

// --------------------------------------------------------------------------
// Excluir
User Function ZA7_EX()
    private inclui   := .F.
    private altera   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZA7", inclui, .T.)
    AxDeleta ("ZA7", za7 -> (recno ()), 5)
    u_logFim ()

return

// --------------------------------------------------------------------------
// Valida inclusao
User Function ZA7_VI()
    local _lRet := .T.
    
    if fbuscacpo ("SA1", 1, xfilial ("SA1") + m->za7_cli + m->za7_loja,  "A1_VERBA") != '1'
       u_help ("Cliente não controla verbas. Inclusao não permitida.")    
       _lRet = .F. 
    endif
    
    if DbSeek(xFilial("ZA7")+m->za7_cli+m->za7_loja+m->za7_cont+m->za7_seq,.F.)
       u_help ("Sequência ja informada para este contrato.")    
       _lRet = .F. 
    endif
    
    if dtos(m->za7_dbase) > dtos(m->za7_vini) 
         u_help ("Data base não deve ser maior que data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_vini) > dtos(m->za7_vfim) 
         u_help ("Data final da vigência não deve ser maior que a data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_pini) > dtos(m->za7_vfim) 
         u_help ("Data inicial do perido de apuracao deve ser menor que a data final da vigência do contrato.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_pini) > dtos(m->za7_pfim) 
         u_help ("Data final do periodo de apuração não deve ser maior que a data final do periodo de apuração..")    
         _lRet = .F.
    endif
    
    // valida se ja existe validade vigente para o cliente
    if m->za7_vigent = '1'
        // buscando contrato conforme cliente e vigencia informada
        _sQuery := ""
        _sQuery += " SELECT COUNT(*) AS JA_TEM"
        _sQuery += "   FROM " + RetSQLName ("ZA7") + " ZA7"
        _sQuery += "  WHERE ZA7.D_E_L_E_T_ != '*'"
        _sQuery += "    AND ZA7_CLI         = "+ m->za7_cli  
        _sQuery += "    AND ZA7_LOJA        = "+ m->za7_loja  
        _sQuery += "    AND ZA7_VIGENT      = '1'"
        _aDados := U_Qry2Array (_sQuery)
        if _aDados[1,1] > 0
            u_help ("Já existe Contrato vigente para este cliente.")    
            _lRet = .F.    
        endif
    endif
return _lRet

// --------------------------------------------------------------------------
// Valida alteracao
User Function ZA7_VA()
    local _lRet := .T.
    
    if dtos(m->za7_dbase) > dtos(m->za7_vini) 
         u_help ("Data base não deve ser maior que data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_vini) > dtos(m->za7_vfim) 
         u_help ("Data final da vigência não deve ser maior que a data inicial da vigência.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_pini) > dtos(m->za7_vfim) 
         u_help ("Data inicial do perido de apuracao deve ser menor que a data final da vigência do contrato.")    
         _lRet = .F.
    endif
    
    if dtos(m->za7_pini) > dtos(m->za7_pfim) 
         u_help ("Data final do periodo de apuração não deve ser maior que a data final do periodo de apuração..")    
         _lRet = .F.
    endif
    
    // valida se ja existe validade vigente para o cliente
    if m->za7_vigent = '1'       
        
        // buscando contrato conforme cliente e vigencia informada
        _sQuery := ""
        _sQuery += " SELECT COUNT(*) AS JA_TEM"
        _sQuery += "   FROM " + RetSQLName ("ZA7") + " ZA7"
        _sQuery += "  WHERE ZA7.D_E_L_E_T_ != '*'"
        _sQuery += "    AND ZA7_CLI         = "+ m->za7_cli  
        _sQuery += "    AND ZA7_LOJA        = "+ m->za7_loja  
        _sQuery += "    AND (ZA7_CONT + ZA7_SEQ) <> "+ m->za7_cont + m->za7_seq 
        _sQuery += "    AND ZA7_VIGENT      = '1'"
        _aDados := U_Qry2Array (_sQuery)
        if _aDados[1,1] > 0
            u_help ("Já existe Contrato vigente para este cliente.")    
            _lRet = .F.    
        endif
    endif
return _lRet
