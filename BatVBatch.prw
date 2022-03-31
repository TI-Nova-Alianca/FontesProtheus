// Programa...: BatVBatch
// Autor......: Cláudia Lionço
// Data.......: 31/03/2022
// Descricao..: Envia e-mail de logs de batchs gravados nos eventos do sistema (VA_VEVENTOS)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Envia e-mail de logs de batchs gravados nos eventos do sistema (VA_VEVENTOS)
// #PalavasChave      #batchs #verificações #erros 
// #TabelasPrincipais #
// #Modulos   		  #TODOS
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatVBatch()
    Local _aDados := {}
    Local _x      := 0
    Local _sMsg   := ""
    Local _sMsg1  := ""

    // Executados
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DATA "
    _oSQL:_sQuery += "    ,HORA "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE DATA = '" + dtos(date()-1) + "' "
    _oSQL:_sQuery += " AND CODEVENTO in ('BAT001') "
    _aDados := aclone (_oSQL:Qry2Array ()) 

    For _x:=1 to Len(_aDados)
        _sMsg1 += "EXEC "+ _aDados[_x, 1] + " " + _aDados[_x,2] + " "+ _aDados[_x,3]  + chr (13) + chr (10) 
    Next

    // Erros
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DATA "
    _oSQL:_sQuery += "    ,HORA "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE DATA = '" + dtos(date()-1) + "' "
    _oSQL:_sQuery += " AND CODEVENTO in ('BAT002') "
    _aDados := aclone (_oSQL:Qry2Array ()) 

    For _x:=1 to Len(_aDados)
        _sMsg1 += " ERRO " + _aDados[_x, 1] + " " + _aDados[_x,2] + " "+ _aDados[_x,3]  + chr (13) + chr (10) 
    Next

    If Len(_aDados) > 0
        // Mensagem para e-mail
        _sMsg := "Batchs. Data de verificação:" + dtoc(date()-1) + chr (13) + chr (10) 
        _sMsg += " " + chr (13) + chr (10) 
        _sMsg += _sMsg1 + chr (13) + chr (10) 

        _oBatch:Mensagens += _sMsg

        If type ("oMainWnd") == "O"  
            u_help (_sMsg)
        Else
            U_ZZUNU ({'135'}, "Verificações Batchs " + cFilAnt, _sMsg)
        EndIf
    EndIf
Return
