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
// 04/08/2022 - Robert - Ajuste log, que mostrava nome de outra rotina.
// 28/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
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

//    u_logIni ()
//	u_log ("Iniciando BatPessoas em", date (), time ())
	U_Log2 ('info', '[' + procname () + ']')

    // Executados
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DATA "
    _oSQL:_sQuery += "    ,HORA "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE DATA = '" + dtos(date()) + "' "
    _oSQL:_sQuery += " AND CODEVENTO in ('BAT001') "
    _oSQL:_sQuery += " ORDER BY DATA, HORA "
    u_log(_oSQL:_sQuery)
//    _aDados := aclone (_oSQL:Qry2Array ()) 
    _aDados := aclone (_oSQL:Qry2Array (.f., .f.)) 

    For _x:=1 to Len(_aDados)
        _sMsg1 += "<br>EXEC "+ dtoc(stod(_aDados[_x, 1])) + " " + _aDados[_x,2] + "</br>"+ _aDados[_x,3]  + chr (13) + chr (10) 
    Next

    // Erros
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DATA "
    _oSQL:_sQuery += "    ,HORA "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE DATA = '" + dtos(date()) + "' "
    _oSQL:_sQuery += " AND CODEVENTO in ('BAT002') "
    _oSQL:_sQuery += " ORDER BY DATA, HORA "
//    _aDados := aclone (_oSQL:Qry2Array ()) 
    _aDados := aclone (_oSQL:Qry2Array (.f., .f.)) 

    For _x:=1 to Len(_aDados)
        _sMsg1 += "<br>ERRO " + dtoc(stod(_aDados[_x, 1])) + " " + _aDados[_x,2] + "</br>"+ _aDados[_x,3]  + chr (13) + chr (10) 
    Next

    // Mensagem para e-mail
    _sMsg := "DATA DE VERIFICAÇÃO:" + dtoc(date()) + chr (13) + chr (10) 
    _sMsg += "<br></br>"
    _sMsg += _sMsg1 + chr (13) + chr (10) 

    _oBatch:Mensagens += _sMsg

    U_ZZUNU ({'135'}, "Verificações Batchs", _sMsg, .F., cEmpAnt, cFilAnt, "")
    u_log("Enviado e-mail para grupo 135")

Return
