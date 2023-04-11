// Programa...: BatReserva
// Autor......: Cláudia Lionço
// Data.......: 27/03/2023
// Descricao..: Batch de manunteção de reservas Protheus de endereços/lotes/reservas Fullsoft
// Link.......: https://tdn.totvs.com/display/public/PROT/A430Reserv
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Batch de manunteção de reservas Protheus de endereços/lotes/reservas Fullsoft
// #PalavasChave      #batch #reservas #rastro #lote #rastreabilidade #fullsoft
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

User Function BatReserva()
    Local _sLinkSrv  := ""

    If "TESTE" $ upper(GetEnvServer())
        _sLinkSrv  := "LKSRV_FULLWMS_LOGISTICATESTE"
    else
        _sLinkSrv  := "LKSRV_FULLWMS_LOGISTICA"
    EndIf

    //_IncEndereco(_sLinkSrv)
    //_ExcEndereco(_sLinkSrv)
    //_BloqLotes(_sLinkSrv)
    //_LibLotes(_sLinkSrv)
    //_IncReserva(_sLinkSrv)
    _ExcReserva(_sLinkSrv)

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
//
// --------------------------------------------------------------------------
// Realiza bloqueio de lotes
Static Function _BloqLotes(_sLinkSrv)
    local _oSQL      := NIL
    Local _aDados    := {}
    Local _x         := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT MAX(DD_DOC) FROM " + RetSQLName ("SDD") 
    _oSQL:_sQuery += " WHERE DD_FILIAL = '" + xFilial("SDD") + "'"
    _oSQL:_sQuery += " AND DD_DOC LIKE 'F%' "
    _aNumero := aclone (_oSQL:Qry2Array (.F., .F.))

    If Len(_aNumero) > 0
        For _x:=1 to Len(_aNumero)
            _nNumero := val(SubStr(_aNumero[_x, 1],2,8))
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
    _oSQL:_sQuery += " 	FROM OPENQUERY(LKSRV_FULLWMS_LOGISTICATESTE, 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_LOTE LIKE ''B%''') "
    _oSQL:_sQuery += " 		) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += "    ,LOTE "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR(8), VALIDADE, 112) AS VALIDADE "
    _oSQL:_sQuery += "    ,POSICAO "
    _oSQL:_sQuery += "    ,QTD "
    _oSQL:_sQuery += "    ,B8_SALDO "
    _oSQL:_sQuery += " FROM FULLW "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SB8") 
    _oSQL:_sQuery += " 	ON SB8010.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND B8_LOCAL     = '01' "
    _oSQL:_sQuery += " 		AND B8_PRODUTO   = ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += " 		AND B8_LOTECTL   = LOTE "
    _oSQL:_sQuery += " 		AND B8_DTVALID   = VALIDADE "
    _oSQL:_sQuery += " ORDER BY ITEM_COD_ITEM_LOG, LOTE, POSICAO "
    u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        _sProd := _aDados[_x, 1]

        If _aDados[_x, 6] >= _aDados[_x, 5]

            _sNumero := 'F' + PADL(alltrim(str(_nNumero)), 8, '0')      
            _BloqueiaLote(_aDados, _x, _sNumero)
            _nNumero +=1
        else
            If _aDados[_x, 6] > 0
                _sMsg := "Lote sem quantidade para bloqueio! Produto " + _sProd + " Lote " + _aDados[_x, 2]
                u_log(_sMsg)

                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'SDD'
                _oEvento:Texto     = _sMsg
                _oEvento:CodEven   = "SDD001"
                _oEvento:Produto   = _sProd
                _oEvento:Grava()
            else
                 _sMsg := "Não encontrado lote no Protheus! Produto " + _sProd + " Lote " + _aDados[_x, 2]
                u_log(_sMsg)

                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'SDD'
                _oEvento:Texto     = _sMsg
                _oEvento:CodEven   = "SDD001"
                _oEvento:Produto   = _sProd
                _oEvento:Grava()
            EndIf
        EndIf
    Next
Return
//
// --------------------------------------------------------------------------
// Realiza bloqueio de lote
Static Function _BloqueiaLote(_aDados, _x, _sNumero)
    Local aVetor := {}  
    Local _sProd := PADR(alltrim(_aDados[_x, 1]),15,' ')       
    
    lMsErroAuto  := .F.          
    _sLote :=  PADR(alltrim(_aDados[_x, 2]),10,' ')

	aVetor :=  {{"DD_DOC"		, _sNumero              ,NIL},;
			    {"DD_PRODUTO" 	, _sProd                ,NIL},;
			    {"DD_LOCAL" 	,"01"			        ,NIL},;    
			    {"DD_LOTECTL"	,_sLote		            ,NIL},;    
			    {"DD_QUANT"		,_aDados[_x, 5]	        ,NIL},;
                {"DD_VAFRUA"	,alltrim(_aDados[_x, 4]),NIL},;
			    {"DD_MOTIVO"	,"ND"			        ,NIL}}                                               	
			
	MSExecAuto({|x, y| mata275(x, y)},aVetor, 3)       
			
    If lMsErroAuto    
        Mostraerro()
        _sMsg := "Problemas ao bloquear lote! Nº " + _sNumero + " Produto " + _sProd + " Lote " + _aDados[_x, 2]
        u_log(_sMsg)

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SDD'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SDD001"
        _oEvento:Produto   = _sProd
        _oEvento:Grava()
    else    
        _sMsg := "Lote Bloqueado! Nº " + _sNumero + " Produto " + _sProd + " Lote " + _aDados[_x, 2]
        u_log(_sMsg)

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SDD'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SDD001"
        _oEvento:Produto   = _sProd
        _oEvento:Grava()
    Endif
Return
//
// --------------------------------------------------------------------------
// Realiza desbloqueio de lote
Static Function _LibLotes(_sLinkSrv)
    local _oSQL       := NIL
    Local _aDados     := {}
    Local _x          := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT "
    _oSQL:_sQuery += " 	    DD_DOC "
    _oSQL:_sQuery += "     ,DD_PRODUTO "
    _oSQL:_sQuery += "     ,DD_LOTECTL "
    _oSQL:_sQuery += " FROM OPENQUERY(LKSRV_FULLWMS_LOGISTICATESTE, 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_LOTE NOT LIKE ''B%''') "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SDD") + " SDD "
    _oSQL:_sQuery += " 	ON SDD.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SDD.DD_PRODUTO = ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += " 		AND SDD.DD_LOCAL = '01' "
    _oSQL:_sQuery += " 		AND SDD.DD_LOTECTL = LOTE "
    _oSQL:_sQuery += " 		AND TRIM(SDD.DD_VAFRUA) = TRIM(POSICAO) "
    _oSQL:_sQuery += " 		AND SDD.DD_DOC LIKE 'F%' "
    _oSQL:_sQuery += " 		AND SDD.DD_QUANT > 0 "
    _oSQL:_sQuery += " 		AND SDD.DD_SALDO > 0 "
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        _sNumero := _aDados[_x, 1]
        _sProd   := _aDados[_x, 2]
        _sLote   := _aDados[_x, 3]

        _LiberaLote(_sNumero, _sProd, _sLote)
    Next
Return
//
// --------------------------------------------------------------------------
// Realiza desbloqueio de lote
Static Function _LiberaLote(_sNumero, _sProd, _sLote)
    Local _aVetor     := {}
    Local lMsErroAuto := .F. 
  
    _aVetor  := {{"DD_DOC", _sNumero, NIL}}

    MSExecAuto({|x, y| mata275(x, y)},_aVetor, 4)  

    If lMsErroAuto    
        Mostraerro()
        _sMsg := "Problemas ao desbloquear lote! Nº " + _sNumero + " Produto " + _sProd + " Lote " + _sLote
        u_log(_sMsg)

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SDD'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SDD001"
        _oEvento:Produto   = _sProd
        _oEvento:Grava()
    else    
        _sMsg := "Lote desbloqueado! Nº " + _sNumero + " Produto " + _sProd + " Lote " + _sLote
        u_log(_sMsg)

        _oEvento := ClsEvent():New ()
        _oEvento:Alias     = 'SDD'
        _oEvento:Texto     = _sMsg
        _oEvento:CodEven   = "SDD001"
        _oEvento:Produto   = _sProd
        _oEvento:Grava()
    Endif
Return
//
// --------------------------------------------------------------------------
// Inclui a reserva da reserva full
Static Function _IncReserva(_sLinkSrv)
    local _oSQL      := NIL
    Local _aDados    := {}
    Local _x         := ""

    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT MAX(C0_NUM) FROM " + RetSQLName ("SC0") 
    _oSQL:_sQuery += " WHERE C0_FILIAL = '" + xFilial("SC0") + "'"
    _oSQL:_sQuery += " AND C0_NUM LIKE 'R%' "
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
    _oSQL:_sQuery := " SELECT "
    _oSQL:_sQuery += " 	   ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += "    ,LOTE "
    _oSQL:_sQuery += "    ,POSICAO "
    _oSQL:_sQuery += "    ,QTD "
    _oSQL:_sQuery += "    ,C0_VATIPO "
    _oSQL:_sQuery += "    ,NUM_RESERVA "
    _oSQL:_sQuery += " FROM OPENQUERY(LKSRV_FULLWMS_LOGISTICATESTE, 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE NUM_RESERVA IS NOT NULL') "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SC0") 
    _oSQL:_sQuery += " 	ON D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ITEM_COD_ITEM_LOG = C0_PRODUTO "
    _oSQL:_sQuery += " 		AND LOTE              = C0_LOTECTL "
    _oSQL:_sQuery += " 		AND POSICAO           = C0_VAPOSI "
    _oSQL:_sQuery += " 		AND C0_LOCAL          = '01' "
    _oSQL:_sQuery += " 		AND C0_VANRES IS NOT NULL "
    _oSQL:_sQuery += " ORDER BY ITEM_COD_ITEM_LOG, LOTE, POSICAO "
    u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        
        _sNumero := 'R' + PADL(alltrim(str(_nNumero)), 5, '0')
        lReservOk := _IncluiReserva(_aDados, _x, _sNumero, 'R')

        If lReservOk
            _nNumero += 1
        EndIf
    Next
Return
//
// --------------------------------------------------------------------------
// Exclui reservas
Static Function _ExcReserva(_sLinkSrv)
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
    _oSQL:_sQuery += " FROM OPENQUERY(LKSRV_FULLWMS_LOGISTICATESTE, 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE NUM_RESERVA IS NULL') "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC0") 
    _oSQL:_sQuery += " 	ON D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ITEM_COD_ITEM_LOG = C0_PRODUTO "
    _oSQL:_sQuery += " 		AND LOTE              = C0_LOTECTL "
    _oSQL:_sQuery += " 		AND POSICAO           = C0_VAPOSI "
    _oSQL:_sQuery += " 		AND C0_LOCAL          = '01' "
    _oSQL:_sQuery += " 		AND C0_VATIPO         = 'R' "
    _oSQL:_sQuery += " 		AND C0_VANRES         <> '' "
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        _ExcluiReserva(_aDados, _x)
    Next
Return
