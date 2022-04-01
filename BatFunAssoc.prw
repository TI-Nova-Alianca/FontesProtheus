// Programa...: BatFunAssoc
// Autor......: Cláudia Lionço
// Data.......: 11/11/2021
// Descricao..: Bat para troca de status associado/nao associado, conforme situação.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Bat para troca de status associado/nao associado, conforme situação.
// #PalavasChave      #venda_associados #cliente_associados
// #TabelasPrincipais #AI0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatFunAssoc()
    Local _aCliente   := {}
    Local _x          := 0
    Local _i          := 0
    Local _sSocio     := 'N'
    Local _dUltDiaMes := lastday (Date())

    u_logIni ()
	u_log ("Iniciando em", date (), time ())

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 		  A1_CGC "
    _oSQL:_sQuery += " 		 ,A1_COD "
    _oSQL:_sQuery += " 		 ,A1_LOJA "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SA1")
    _oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND A1_MSBLQL = '2' "
    //u_log(_oSQL:_sQuery)
    _aCliente := aclone (_oSQL:Qry2Array ())

    For _x:=1 to Len(_aCliente)
        _sCliente := _aCliente[_x,2] 
        _sLojCli  := _aCliente[_x,3]

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	    A2_COD "
        _oSQL:_sQuery += "     ,A2_LOJA "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SA2")
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND A2_MSBLQL = '2' "
        _oSQL:_sQuery += " AND A2_CGC = '"+ _aCliente[_x,1] +"' "
        _aFornece := aclone (_oSQL:Qry2Array ())
    
        For _i:=1 to Len(_aFornece)
            _sFornece := _aFornece[_i, 1]
            _sLoja    := _aFornece[_i, 2]
            
            // Instancia classe para verificacao dos dados do associado.
            _oAssoc := ClsAssoc():New (_sFornece,_sLoja)
            If _oAssoc:EhSocio(_dUltDiaMes)
                If _oAssoc:Ativo(_dUltDiaMes)
                    _sSocio := 'A'
                Else
                    _sSocio := 'I'
                Endif
            Else
                _sSocio := 'N'
            Endif

            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT"
            _oSQL:_sQuery += " 		AI0_ASSOCI"
            _oSQL:_sQuery += " FROM " + RetSQLName ("AI0")
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
            _oSQL:_sQuery += " AND AI0_CODCLI = '" + _sCliente + "'"
            _oSQL:_sQuery += " AND AI0_LOJA   = '" + _sLojCli  + "'"
            _aAI0 := aclone (_oSQL:Qry2Array ())

            dbSelectArea("AI0")
            dbSetOrder(1) // filial + cliente + loja
            dbGoTop()

            If Len(_aAI0) > 0
                _sAssoc := _aAI0[1,1]
                If dbSeek(xFilial("AI0") + _sCliente + _sLoja )  .and. alltrim(_sAssoc) <> alltrim(_sSocio)
                    Reclock("AI0",.F.)
                        AI0->AI0_ASSOCI := _sSocio 
                    AI0->(MsUnlock())

                    u_log ("ALTERACAO - Cliente " + _sCliente +"/"+ _sLoja + " é sócio!")

                    _oEvento := ClsEvent():New ()
                    _oEvento:Alias   = 'AI0'
                    _oEvento:Texto   = "Alteracao no campo <AI0_ASSOCI> de " + _sAssoc + " para " + _sSocio
                    _oEvento:CodEven = "AI0001"
                    _oEvento:Cliente = _sCliente
                    _oEvento:LojaCli = _sLoja
                    _oEvento:Grava()
                EndIf
            Else
                Reclock("AI0",.T.)
                    AI0->AI0_CODCLI := _sCliente
                    AI0->AI0_LOJA   := _sLoja
                    AI0->AI0_CLIFUN := _sSocio
                AI0->(MsUnlock())

                u_log ("INCLUSAO - Cliente " + _sCliente +"/"+ _sLoja + " é sócio!")

                _oEvento := ClsEvent():New ()
                _oEvento:Alias   = 'AI0'
                _oEvento:Texto   = "Inclusão no campo <AI0_ASSOCI>:" + _sSocio
                _oEvento:CodEven = "AI0001"
                _oEvento:Cliente = _sCliente
                _oEvento:LojaCli = _sLoja
                _oEvento:Grava()
            EndIf
        Next
    Next
   
    u_logFim ()
Return .T.
