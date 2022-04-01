// Programa...: BatLojCGC
// Autor......: Cláudia Lionço
// Data.......: 16/02/2022
// Descricao..: Bat para gravação de CPF de clientes em cupons do PDV.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Bat para gravação de CPF de clientes em cupons do PDV.
// #PalavasChave      #PDV #clientes #grava_CGC
// #TabelasPrincipais #SL1 #SA1
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "protheus.ch"
#Include "totvs.ch"

User Function BatLojCGC()
    Local _oSQL := ClsSQL ():New ()
    Local _x    := 0
    Local _aCli := {}

    _dDtaIni  := FirstDate(Date())
    _dDtaFin  := LastDate (Date())

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   L1_FILIAL "
    _oSQL:_sQuery += "    ,L1_NUM "
    _oSQL:_sQuery += "    ,L1_CLIENTE "
    _oSQL:_sQuery += "    ,L1_EMISSAO "
    _oSQL:_sQuery += "    ,SA1.A1_CGC "
    _oSQL:_sQuery += "    ,SA1.A1_NOME "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SL1") + " SL1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD = SL1.L1_CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = SL1.L1_LOJA "
    _oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SL1.L1_EMISSAO BETWEEN '" + dtos(_dDtaIni) + "' AND '" + dtos(_dDtaFin) + "'"
    _oSQL:_sQuery += " AND SL1.L1_CLIENTE <> '000000' "
    _oSQL:_sQuery += " AND (SL1.L1_VACGC = '' "
    _oSQL:_sQuery += " OR SL1.L1_CGCCLI = '') "
    u_log(_oSQL:_sQuery)
    _aCli := aclone (_oSQL:Qry2Array ())

    For _x:=1 to Len(_aCli)
        dbSelectArea("SL1")
        dbSetOrder(1) // L1_FILIAL+L1_NUM
        dbGoTop()
        			
        If dbSeek(_aCli[_x, 1] + _aCli[_x, 2])
            Reclock("SL1",.F.)
                SL1->L1_VACGC  := _aCli[_x, 5]
                SL1->L1_CGCCLI := _aCli[_x, 5]
            SL1->(MsUnlock())
            u_log("Ajustado cupom:" + _aCli[_x, 2] +" Cliente:" + _aCli[_x, 3] +"-"+ alltrim(_aCli[_x, 6]) + "CGC:" + _aCli[_x, 5])
            
            _oEvento := ClsEvent():New ()
            _oEvento:Alias   = 'SL1'
            _oEvento:Texto   = "Alt.Cupom:"+_aCli[_x, 2] + " CGC:" + _aCli[_x, 5]
            _oEvento:CodEven = "AI0002"
            _oEvento:Cliente = _aCli[_x, 3]
            _oEvento:LojaCli = '01'
            _oEvento:Grava()
        EndIf
    Next
Return .T.
