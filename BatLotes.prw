// Programa...: BatReserva
// Autor......: Cláudia Lionço
// Data.......: 27/03/2023
// Descricao..: Batch de manunteção de lotes Protheus X Fullsoft
// Link.......: https://tdn.totvs.com/display/public/PROT/A430Reserv
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Batch de manunteção de lotes Protheus X Fullsoft
// #PalavasChave      #batch #rastro #lote #rastreabilidade #fullsoft
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

User Function BatLotes()
    Local _sLinkSrv  := ""

    u_logIni()
    _sLinkSrv = U_LkServer('FULLWMS_AX01')

    u_log("LKServer:"+_sLinkSrv)

    u_log("Lotes")
    // Lotes
    _BloqLotes(_sLinkSrv)
    _LibLotes(_sLinkSrv)

    u_logFim()
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
    _oSQL:_sQuery += " AND DD_DOC LIKE 'L%' "
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
    _oSQL:_sQuery += " 	FROM OPENQUERY("+ _sLinkSrv +", 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_LOTE LIKE ''B%''') "
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
    //_oSQL:_sQuery += " WHERE ITEM_COD_ITEM_LOG='0150' ""
    _oSQL:_sQuery += " ORDER BY ITEM_COD_ITEM_LOG, LOTE, POSICAO "
    u_log(_oSQL:_sQuery)
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aDados)
        _sProd := _aDados[_x, 1]

        If _aDados[_x, 6] >= _aDados[_x, 5]

            _sNumero := 'L' + PADL(alltrim(str(_nNumero)), 8, '0')      
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
                _sMsg := "Não encontrado lote no Protheus! Verif. Lote e Data Validade. Produto " + _sProd + " Lote " + _aDados[_x, 2] + " Dt. Valid. " + _aDados[_x, 3]
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
			    {"DD_MOTIVO"	,"ND"			        ,NIL}}     

                                //{"DD_VAFRUA"	,alltrim(_aDados[_x, 4]),NIL},;                                          	
			
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
    _oSQL:_sQuery += " FROM OPENQUERY("+ _sLinkSrv +", 'SELECT * FROM V_ALIANCA_ESTOQUES WHERE SITUACAO_LOTE NOT LIKE ''B%''') "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SDD") + " SDD "
    _oSQL:_sQuery += " 	ON SDD.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SDD.DD_PRODUTO = ITEM_COD_ITEM_LOG "
    _oSQL:_sQuery += " 		AND SDD.DD_LOCAL = '01' "
    _oSQL:_sQuery += " 		AND SDD.DD_LOTECTL = LOTE "
    _oSQL:_sQuery += " 		AND TRIM(SDD.DD_VAFRUA) = TRIM(POSICAO) "
    _oSQL:_sQuery += " 		AND SDD.DD_DOC LIKE 'L%' "
    _oSQL:_sQuery += " 		AND SDD.DD_QUANT > 0 "
    _oSQL:_sQuery += " 		AND SDD.DD_SALDO > 0 "
    u_log(_oSQL:_sQuery)
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
