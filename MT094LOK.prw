// Programa.: MT094LOK
// Autor....: Claudia Lionço
// Data.....: 21/02/2023
// Descricao: P.E. para validar a continuação da liberação de documentos
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para validar a continuação da liberação de documentos
// #PalavasChave      #pedido_de_compra #liberacao_de_pedido
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function MT094LOK()

    //_VerifLimite(SCR->CR_USER, SCR->CR_FILIAL, SCR->CR_NUM)

Return
//
// -----------------------------------------------------------------------------------------
// Verifica limite de pedido para gravação de mensagem no APP Meu Protheus
Static Function _VerifLimite(_sUser, _sFilial, _sNumero)
    Local _aLimite := {}
    Local _aTotal  := {}
    Local _aPed    := {}
    Local _aPedido := {}
    Local _x       := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    AK_LIMITE "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SAK") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND AK_USER = '"+ _sUser +"' "
    _aLimite := aclone(_oSQL:Qry2Array())

    If Len(_aLimite) > 0
        _nLimite := _aLimite[1,1]
    else
        _nLimite := 0
    EndIf

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    SUM(CR_VALLIB) "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SCR") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND CR_USER = '"+ _sUser +"' "
    _oSQL:_sQuery += " AND CR_DATALIB = '"+ dtos(dDataBase)+"' " 
    _aTotal := aclone(_oSQL:Qry2Array())

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	    SUM(CR_TOTAL)
    _oSQL:_sQuery += " FROM " + RetSQLName ("SCR") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''
    _oSQL:_sQuery += " AND CR_FILIAL = '"+ _sFilial +"' "
    _oSQL:_sQuery += " AND CR_NUM    = '"+ _sNumero +"' "
    _oSQL:_sQuery += " AND CR_USER   = '"+ _sUser   +"' "
    _aPed := aclone(_oSQL:Qry2Array())

    If Len(_aLimite) > 0
        _nTotal := _aTotal[1,1]
    else
        _nTotal := 0
    EndIf

    If Len(_aPed) > 0
        _nTotal += _aPed[1,1]
    EndIf

    If _nTotal > _nLimite

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   C7_FILIAL "
        _oSQL:_sQuery += "    ,C7_NUM "
        _oSQL:_sQuery += "    ,C7_ITEM "
        _oSQL:_sQuery += "    ,C7_SEQUEN "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SC7") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND C7_FILIAL    = '"+ _sFilial +"' "
        _oSQL:_sQuery += " AND C7_NUM       = '"+ _sNumero +"' "
        _aPedido := aclone(_oSQL:Qry2Array())

        For _x:=1 to Len(_aPedido)      
            dbSelectArea("SC7")
            dbSetOrder(1)           // c7_filial + c7_num + c7_item + c7_sequen  
            dbSeek(_aPedido[_x,1] + _aPedido[_x,2]  + _aPedido[_x,3] + _aPedido[_x,4] )

            If Found()              // Avalia o retorno da pesquisa realizada
                RecLock("SC7", .F.)
                    SC7->C7_VAMSG := " Pedido não liberado devido ao limite de crédito disponível!"
                MsUnlock()          // Destrava o registro
            EndIf	
        Next
    EndIf
Return
