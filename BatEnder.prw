// Programa...: BatReserva
// Autor......: Cláudia Lionço
// Data.......: 27/03/2023
// Descricao..: Batch de manunteção de endereços Protheus X Fullsoft
// Link.......: https://tdn.totvs.com/display/public/PROT/A430Reserv
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Batch de manunteção de endereços Protheus X Fullsoft
// #PalavasChave      #batch #endereco #rastro #rastreabilidade #fullsoft
// #TabelasPrincipais #V_ALIANCA_ESTOQUES
// #Modulos           #EST
//
// Historico de alteracoes:
//
//
// -------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'

User Function BatEnder()
    Local _sLinkSrv  := ""

    u_logIni()
    _sLinkSrv = U_LkServer('FULLWMS_AX01')

    u_log("LKServer:"+_sLinkSrv)

    u_log("Endereço")
    // Endereço
    _IncEndereco(_sLinkSrv)
    _ExcEndereco(_sLinkSrv)

    u_logFim()
Return
//
// --------------------------------------------------------------------------
// Inclui a reserva de endereço
Static Function _IncEndereco(_sLinkSrv)
    local _oSQL      := NIL
    Local _aDados    := {}
    Local _x         := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT MAX(C0_NUM) FROM " + RetSQLName ("SC0") 
    _oSQL:_sQuery += " WHERE C0_FILIAL = '" + xFilial("SC0") + "'"
    _oSQL:_sQuery += " AND C0_NUM LIKE 'E%' "
    _aNumero := aclone (_oSQL:Qry2Array (.F., .F.))

    If Len(_aNumero) > 0
        For _x:=1 to Len(_aNumero)
            _nNumero := val(SubStr(_aNumero[_x, 1],2,5))
            _nNumero += 1
        Next
    else
        _nNumero := 1
    EndIf

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " WITH FULLW "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		* "
    _oSQL:_sQuery += " 	FROM OPENQUERY("+ _sLinkSrv +", 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_RUA LIKE ''9%''')"
    _oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SC0") 
	_oSQL:_sQuery += " 	ON D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND ITEM_COD_ITEM_LOG = C0_PRODUTO"
	_oSQL:_sQuery += " 		AND LOTE              = C0_LOTECTL"
	_oSQL:_sQuery += " 		AND POSICAO           = C0_VAPOSI"
	_oSQL:_sQuery += " 		AND C0_LOCAL          = '01'"
    _oSQL:_sQuery += " 	) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += "    ,LOTE "
    _oSQL:_sQuery += "    ,POSICAO "
    _oSQL:_sQuery += "    ,QTD "
    _oSQL:_sQuery += "    ,C0_VATIPO "
    _oSQL:_sQuery += "    ,NUM_RESERVA "
    _oSQL:_sQuery += " FROM FULLW "
    _oSQL:_sQuery += " WHERE C0_VATIPO IS NULL "
    //_oSQL:_sQuery += " AND POSICAO LIKE 'H%' "
    _oSQL:_sQuery += " ORDER BY ITEM_COD_ITEM_LOG, LOTE, POSICAO "
    u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        
        _sNumero := 'E' + PADL(alltrim(str(_nNumero)), 5, '0')
        lReservOk := _IncluiReserva(_aDados, _x, _sNumero, 'E')

        If lReservOk
            _nNumero += 1
        EndIf
    Next
Return
//
// --------------------------------------------------------------------------
// Inclui a reserva
Static Function _IncluiReserva(_aDados, _x, _sNumero, _sTipo)
    Local aOperacao := {}
    Local lReservOk := .T.
    Local cNumero   := _sNumero                             // C0_NUM
    Local cProduto  := PADR(alltrim(_aDados[_x,1]),15,' ')  // C0_PRODUTO
    Local cLocal    := '01'                                 // C0_LOCAL
    Local nQuant    := _aDados[_x,4]                        // C0_QUANT
    Local aLote     := {"",_aDados[_x,2],"",""}             // [1] -> [Numero do Lote] [2] -> [Lote de Controle] [3] -> [Localizacao] [4] -> [Numero de Serie]
    Local nOpc      := 1                                    // 1 - Inclui, 2 - Altera, 3 - Exclui
   
    Private aHeader := {}
    Private aCols   := {}

    //MONTAGEM DO HEADER E ACOLS PARA CAMPOS CUSTOMIZADOS OU PADRAO
    DbSelectArea("SC0")
    If !empty(_aDados[_x,3]) 
        aadd(aHeader,{  GetSx3Cache("C0_VAPOSI", 'X3_TITULO'    ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_CAMPO'     ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_PICTURE'   ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_TAMANHO'   ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_DECIMAL'   ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_VALID'     ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_USADO'     ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_TIPO'      ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_F3'        ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_CONTEXT'   ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_CBOX'      ),;
                        GetSx3Cache("C0_VAPOSI", 'X3_RELACAO'   ) })
        aadd(aCols, alltrim(_aDados[_x,3]))
    Endif
    If !empty(_aDados[_x,6]) 
        aadd(aHeader,{  GetSx3Cache("C0_VANRES", 'X3_TITULO'    ),;
                        GetSx3Cache("C0_VANRES", 'X3_CAMPO'     ),;
                        GetSx3Cache("C0_VANRES", 'X3_PICTURE'   ),;
                        GetSx3Cache("C0_VANRES", 'X3_TAMANHO'   ),;
                        GetSx3Cache("C0_VANRES", 'X3_DECIMAL'   ),;
                        GetSx3Cache("C0_VANRES", 'X3_VALID'     ),;
                        GetSx3Cache("C0_VANRES", 'X3_USADO'     ),;
                        GetSx3Cache("C0_VANRES", 'X3_TIPO'      ),;
                        GetSx3Cache("C0_VANRES", 'X3_F3'        ),;
                        GetSx3Cache("C0_VANRES", 'X3_CONTEXT'   ),;
                        GetSx3Cache("C0_VANRES", 'X3_CBOX'      ),;
                        GetSx3Cache("C0_VANRES", 'X3_RELACAO'   ) })
        aadd(aCols, alltrim(_aDados[_x,6]))
    Endif
    aadd(aHeader,{  GetSx3Cache("C0_VATIPO", 'X3_TITULO'    ),;
                    GetSx3Cache("C0_VATIPO", 'X3_CAMPO'     ),;
                    GetSx3Cache("C0_VATIPO", 'X3_PICTURE'   ),;
                    GetSx3Cache("C0_VATIPO", 'X3_TAMANHO'   ),;
                    GetSx3Cache("C0_VATIPO", 'X3_DECIMAL'   ),;
                    GetSx3Cache("C0_VATIPO", 'X3_VALID'     ),;
                    GetSx3Cache("C0_VATIPO", 'X3_USADO'     ),;
                    GetSx3Cache("C0_VATIPO", 'X3_TIPO'      ),;
                    GetSx3Cache("C0_VATIPO", 'X3_F3'        ),;
                    GetSx3Cache("C0_VATIPO", 'X3_CONTEXT'   ),;
                    GetSx3Cache("C0_VATIPO", 'X3_CBOX'      ),;
                    GetSx3Cache("C0_VATIPO", 'X3_RELACAO'   ) })
    aadd(aCols, _sTipo)     
    aOperacao := {  nOpc            ,; //[1] -> [Operacao : 1 Inclui,2 Altera,3 Exclui]
                    "VD"            ,; //[2] -> [Tipo da Reserva]
                    ""              ,; //[3] -> [Documento que originou a Reserva]
                    ""              ,; //[4] -> [Solicitante]
                    xFilial("SC0")   } //[5] -> [Filial da Reserva]

    lReservOk := a430Reserv(aOperacao,cNumero,cProduto,cLocal,nQuant,aLote,aHeader,aCols)

    If lReservOk
        _sMsg := "Reserva "+ cNumero +" cadastrada com Sucesso! Prod. " + cProduto + " Posição " + _aDados[_x,3] + " Reserva " + _aDados[_x,6]
        u_log(_sMsg)
        lReservOk := .T.

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SC0'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SC0001"
        _oEvento:Produto   = cProduto
        _oEvento:Grava()

    Else
        _sMsg := "Problemas ao cadastrar reserva " + cNumero + " Prod. " + cProduto + " Posição " + _aDados[_x,3] + " Reserva " + _aDados[_x,6]
        u_log(_sMsg)
        lReservOk := .F.

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SC0'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SC0001"
        _oEvento:Produto   = cProduto
        _oEvento:Grava()
    EndIf
Return lReservOk
//
// --------------------------------------------------------------------------
// Exclui reservas
Static Function _ExcEndereco(_sLinkSrv)
    local _oSQL      := NIL
    Local _aDados    := {}
    Local _x         := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT "
    _oSQL:_sQuery += " 	   C0_NUM "
    _oSQL:_sQuery += "    ,C0_PRODUTO "
    _oSQL:_sQuery += "    ,C0_LOCAL "
    _oSQL:_sQuery += "    ,C0_QUANT "
    _oSQL:_sQuery += "    ,C0_LOTECTL "
    _oSQL:_sQuery += " FROM OPENQUERY("+ _sLinkSrv +", 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_RUA NOT LIKE ''9%''')"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC0") 
    _oSQL:_sQuery += "	 ON D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "		 AND ITEM_COD_ITEM_LOG = C0_PRODUTO "
    _oSQL:_sQuery += "		 AND LOTE              = C0_LOTECTL "
    _oSQL:_sQuery += "		 AND POSICAO           = C0_VAPOSI "
    _oSQL:_sQuery += "		 AND C0_LOCAL          = '01' "
    _oSQL:_sQuery += "		 AND C0_NUM LIKE 'E%' "
    u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        _ExcluiReserva(_aDados, _x)
    Next
Return
//
// --------------------------------------------------------------------------
// Exclui reservas
Static Function _ExcluiReserva(_aDados, _x)
    Local aOperacao := {}
    Local lReservOk := .T.
    Local cNumero   := _aDados[_x, 1]               // C0_NUM
    Local cProduto  := _aDados[_x, 2]               // C0_PRODUTO
    Local cLocal    := _aDados[_x, 3]               // C0_LOCAL
    Local aLote     := {"",_aDados[_x, 5],"",""}    // [1] -> [Numero do Lote] [2] -> [Lote de Controle] [3] -> [Localizacao] [4] -> [Numero de Serie]
    Local nOpc      := 3                            // Exclui

    Private aHeader := {}
    Private aCols   := {}

    //SELECIONAR ITEM PARA EXCLUIR
    DbSelectArea("SC0")
    SC0->(DbSetOrder(1))
    If !SC0->(DbSeek(xFilial("SC0")+cNumero+cProduto+cLocal))
        ConOut("Nao localizado o item para excluir")
        lReservOk:=.F.
    EndIf

    If lReservOk
        aOperacao:= {   nOpc            ,; //[1] -> [Operacao : 1 Inclui,2 Altera,3 Exclui]
                        SC0->C0_TIPO    ,; //[2] -> [Tipo da Reserva]
                        SC0->C0_DOCRES  ,; //[3] -> [Documento que originou a Reserva]
                        SC0->C0_SOLICIT ,; //[4] -> [Solicitante]
                        SC0->C0_FILIAL   } //[5] -> [Filial da Reserva]

        nQuant:= SC0->C0_QUANT

        lReservOk := a430Reserv(aOperacao,cNumero,cProduto,cLocal,nQuant,aLote,aHeader,aCols)

        If lReservOk
            _sMsg := "Reserva "+ cNumero +" excluída com Sucesso!"
            u_log(_sMsg)
            lReservOk := .T.

            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = 'SC0'
            _oEvento:Texto     = _sMsg
            _oEvento:CodEven   = "SC0001"
            _oEvento:Produto   = cProduto
            _oEvento:Grava()
            
        Else
            //MOSTRAERRO()
            _sMsg := "Problemas ao excluir reserva " + cNumero
            u_log(_sMsg)
            lReservOk := .F.

            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = 'SC0'
            _oEvento:Texto     = _sMsg
            _oEvento:CodEven   = "SC0001"
            _oEvento:Produto   = cProduto
            _oEvento:Grava()
        EndIf
    EndIf
Return
