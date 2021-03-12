// Programa...: BatTransf
// Autor......: Cláudia Lionço
// Data.......: 25/02/2021
// Descricao..: Bat da Transferencia bancária automatica
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Bat da Transferencia bancária automatica
// #PalavasChave      #transfrencia_automatica #transferencia_bancaria 
// #TabelasPrincipais #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatTransf(_sFilBat, _sFilReg)
	cPerg   := "ZB5TRANSF"

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   ZB5.ZB5_FILIAL"
    _oSQL:_sQuery += "    ,SUM(ZB5.ZB5_VLRREC)"
    _oSQL:_sQuery += "    ,SUM(ZB5.ZB5_VLRDES)"
    _oSQL:_sQuery += "    ,ZB4.ZB4_BANCO"
    _oSQL:_sQuery += "    ,ZB4.ZB4_AGEN"
    _oSQL:_sQuery += "    ,ZB4.ZB4_CONTA"
    _oSQL:_sQuery += "    ,ZB4.ZB4_TBANCO"
    _oSQL:_sQuery += "    ,ZB4.ZB4_TAGEN"
    _oSQL:_sQuery += "    ,ZB4.ZB4_TCONTA"
    _oSQL:_sQuery += "    ,ZB4.ZB4_NATUR"
    _oSQL:_sQuery += "    ,ZB4.ZB4_TPMOV"
    _oSQL:_sQuery += "    ,ZB4.ZB4_HIST"
    _oSQL:_sQuery += "    ,ZB4.ZB4_BENEF"
    _oSQL:_sQuery += "    ,ZB4.ZB4_MBANCO"
    _oSQL:_sQuery += "    ,ZB4.ZB4_MAGEN"
    _oSQL:_sQuery += "    ,ZB4.ZB4_MCONTA"
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZB5") + " ZB5 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZB4") + " ZB4 "
    _oSQL:_sQuery += " 	ON ZB4.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_FILIAL = ZB5.ZB5_FILIAL"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_BANCO = ZB5.ZB5_BANCO"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_AGEN = ZB5.ZB5_AGEN"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_CONTA = ZB5.ZB5_CONTA"
    _oSQL:_sQuery += " WHERE ZB5.D_E_L_E_T_ = ''"
    If _sFilBat <> '01'
        _oSQL:_sQuery += " AND ZB5.ZB5_STATUS = 'A'"
        _oSQL:_sQuery += " AND ZB5.ZB5_FILIAL = '" + _sFilBat + "'"
    Else
        _oSQL:_sQuery += " AND ZB5.ZB5_STATUS = 'P'"
        _oSQL:_sQuery += " AND ZB5.ZB5_FILIAL = '" + _sFilReg + "'"
    EndIf
    _oSQL:_sQuery += " AND ZB5_DTAPRO = '"+ DTOS(date())+"'"
    _oSQL:_sQuery += " GROUP BY ZB5.ZB5_FILIAL"
    _oSQL:_sQuery += " 		,ZB4.ZB4_BANCO"
    _oSQL:_sQuery += " 		,ZB4.ZB4_AGEN"
    _oSQL:_sQuery += " 		,ZB4.ZB4_CONTA"
    _oSQL:_sQuery += " 		,ZB4.ZB4_TBANCO"
    _oSQL:_sQuery += " 		,ZB4.ZB4_TAGEN"
    _oSQL:_sQuery += " 		,ZB4.ZB4_TCONTA"
    _oSQL:_sQuery += " 		,ZB4.ZB4_NATUR"
    _oSQL:_sQuery += " 		,ZB4.ZB4_TPMOV"
    _oSQL:_sQuery += " 		,ZB4.ZB4_HIST"
    _oSQL:_sQuery += " 		,ZB4.ZB4_BENEF"
    _oSQL:_sQuery += "      ,ZB4.ZB4_MBANCO"
    _oSQL:_sQuery += "      ,ZB4.ZB4_MAGEN"
    _oSQL:_sQuery += "      ,ZB4.ZB4_MCONTA"
    _aZB5 := aclone (_oSQL:Qry2Array ()) 

    If Len(_aZB5) > 0
        If _sFilBat <> '01' 
            _FilialToCT(_sFilBat,_sFilReg,_aZB5) // Transf. FIlial -> conta transitória
        Else
            _CTtoMatriz(_sFilBat,_sFilReg,_aZB5) // Conta transitória -> Matriz
        EndIf
    Else
        _oEvento := ClsEvent():New ()
        _oEvento:Alias    = 'ZB5'
        _oEvento:Texto    = " SEM DADOS PARA TRANSFERENCIA" + chr (13) + chr (10) + ;
                            " CHAVE:" + _sFilBat 
        _oEvento:CodEven  = "ZB5001"
        _oEvento:Grava()            
    EndIf
Return
//
// --------------------------------------------------------------------------
// Realiza as tranferencias Filial -> conta transitoria
Static Function _FilialToCT(_sFilBat,_sFilReg,_aZB5)
    Local _x        := 0
    Local _aFINA100 := {}
    Local _sNumDoc  := _sFilReg + Substr(DTOS(date()),7,2) + Substr(DTOS(date()),5,2) + Substr(DTOS(date()),3,2) //+ TIME()   

    For _x := 1 to Len(_aZB5)
        _nVlrRec    := _aZB5[_x, 2] 
        _nVlrDes    := _aZB5[_x, 3]
        _sTp        := alltrim(_aZB5[_x,11])
        _sFilial    := alltrim(_aZB5[_x, 1])
        lMsErroAuto := .F.
        lCont       := .T.

        If _nVlrRec > 0
            // LANÇAMENTO DE PGTO DE TÍTULOS - VLR RECEBIDO
            _aFINA100   := {{"CBCOORIG"   , _aZB5[_x, 4]    ,Nil},;
                            {"CAGENORIG"  , _aZB5[_x, 5]    ,Nil},;
                            {"CCTAORIG"   , _aZB5[_x, 6]    ,Nil},;
                            {"CNATURORI"  , _aZB5[_x,10]    ,Nil},;
                            {"CBCODEST"   , _aZB5[_x, 7]    ,Nil},;
                            {"CAGENDEST"  , _aZB5[_x, 8]    ,Nil},;
                            {"CCTADEST"   , _aZB5[_x, 9]    ,Nil},;
                            {"CNATURDES"  , _aZB5[_x,10]    ,Nil},;
                            {"CTIPOTRAN"  , _sTp            ,Nil},;
                            {"CDOCTRAN"   , _sNumDoc        ,Nil},;
                            {"NVALORTRAN" , _nVlrRec        ,Nil},;
                            {"CHIST100"   , _aZB5[_x,12]    ,Nil},;
                            {"CBENEF100"  , _aZB5[_x,13]    ,Nil} }

            U_GravaSXK (cPerg, "01", "2", 'G' )
            U_GravaSXK (cPerg, "04", "2", 'G' )

            MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aFINA100,7)

            If lMsErroAuto
                //MostraErro()
                lCont := .F.
                
                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " ERRO -TRANSF.VLR.RECEBIDO:" + str(_aZB5[_x, 2]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x, 4] +"-"+ _aZB5[_x, 5] +"-"+ _aZB5[_x, 6] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc + chr (13) + chr (10) + ;
                                    " ERRO LOG:"  + memoread (NomeAutoLog ())
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()

            Else
                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " TRANSF.VLR.RECEBIDO:" + str(_aZB5[_x, 2]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x, 4] +"-"+ _aZB5[_x, 5] +"-"+ _aZB5[_x, 6] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc 
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()
            EndIf    

            U_GravaSXK (cPerg, "01", "2", 'D' )
            U_GravaSXK (cPerg, "04", "2", 'D' )
        EndIf

        If lCont .and. _nVlrDes > 0
            // LANÇAMENTO DE DESPESAS DE REGISTRO - VLR DESP.COBRANÇA
            _aFINA100   := {{"CBCOORIG"   , _aZB5[_x, 7]    ,Nil},;
                            {"CAGENORIG"  , _aZB5[_x, 8]    ,Nil},;
                            {"CCTAORIG"   , _aZB5[_x, 9]    ,Nil},;
                            {"CNATURORI"  , _aZB5[_x,10]    ,Nil},;
                            {"CBCODEST"   , _aZB5[_x, 4]    ,Nil},;
                            {"CAGENDEST"  , _aZB5[_x, 5]    ,Nil},;
                            {"CCTADEST"   , _aZB5[_x, 6]    ,Nil},;
                            {"CNATURDES"  , _aZB5[_x,10]    ,Nil},;
                            {"CTIPOTRAN"  , _sTp            ,Nil},;
                            {"CDOCTRAN"   , _sNumDoc        ,Nil},;
                            {"NVALORTRAN" , _aZB5[_x, 3]    ,Nil},;
                            {"CHIST100"   , _aZB5[_x,12]    ,Nil},;
                            {"CBENEF100"  , _aZB5[_x,13]    ,Nil} }

            U_GravaSXK (cPerg, "01", "2", 'G' )
            U_GravaSXK (cPerg, "04", "2", 'G' )

            MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aFINA100,7)

            If lMsErroAuto
                //MostraErro()
                lCont := .F.

                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " ERRO - DESPESAS DE REGISTRO:" + str(_aZB5[_x, 3]) + chr (13) + chr (10) + ;
                                     " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,7] +"-"+ _aZB5[_x,8] +"-"+ _aZB5[_x,9] + chr (13) + chr (10) + ;
                                     " DOCUMENTO:" + _sNumDoc + chr (13) + chr (10) + ;
                                     " ERRO LOG:"  + memoread (NomeAutoLog ())
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()
            Else
                _oEvento := ClsEvent():New ()
                _oEvento:Alias    = 'ZB5'
                _oEvento:Texto    = " TRANSF.DESPESAS DE REGISTRO:" + str(_aZB5[_x, 3]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,7] +"-"+ _aZB5[_x,8] +"-"+ _aZB5[_x,9] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc 
                _oEvento:CodEven  = "ZB5001"
                _oEvento:Grava()
            EndIf 
            U_GravaSXK (cPerg, "01", "2", 'D' )
            U_GravaSXK (cPerg, "04", "2", 'D' )     
        EndIf

        If lCont .and. (_nVlrDes > 0 .or. _nVlrRec > 0) // grava status nos registros
            _GravaStatus('A','P', _sFilBat, _sFilial,_sFilReg)
            // cria o bacht da matriz
                _oBatch := ClsBatch():new ()
                _oBatch:Dados    = 'Transf.vlr. CT para 01 - Referente:'+_sFilBat
                _oBatch:EmpDes   = cEmpAnt
                _oBatch:FilDes   = '01'
                _oBatch:DataBase = dDataBase
                _oBatch:Modulo   = 6 
                _oBatch:Comando  = "U_BatTransf('01','" + _sFilBat + "')"
                _oBatch:Grava ()

                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = "CRIOU BATCH C.T-> MATRIZ:" + cEmpAnt +'-01-' + dtos(dDataBase) +'-'+ "U_BatTransf('01','" + _sFilBat + "')"
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()

        EndIf
    Next
Return
//
// --------------------------------------------------------------------------
// Realiza as tranferencias conta transitoria -> matriz
Static Function _CTtoMatriz(_sFilBat,_sFilReg,_aZB5)
    Local _x        := 0
    Local _aFINA100 := {}
    Local _sNumDoc  := _sFilReg + Substr(DTOS(date()),7,2) + Substr(DTOS(date()),5,2) + Substr(DTOS(date()),3,2) + 'A' //+ TIME()

    For _x := 1 to Len(_aZB5)
        _nVlrRec    := _aZB5[_x, 2] 
        _nVlrDes    := _aZB5[_x, 3]
        _sTp        := alltrim(_aZB5[_x,11])
        _sFilial    := alltrim(_aZB5[_x, 1])
        lMsErroAuto := .F.
        lCont       := .T.

        If _nVlrRec > 0
            // LANÇAMENTO DE PGTO DE TÍTULOS - VLR RECEBIDO
            _aFINA100   := {{"CBCOORIG"   , _aZB5[_x,14]    ,Nil},;
                            {"CAGENORIG"  , _aZB5[_x,15]    ,Nil},;
                            {"CCTAORIG"   , _aZB5[_x,16]    ,Nil},;
                            {"CNATURORI"  , _aZB5[_x,10]    ,Nil},;
                            {"CBCODEST"   , _aZB5[_x, 4]    ,Nil},;
                            {"CAGENDEST"  , _aZB5[_x, 5]    ,Nil},;
                            {"CCTADEST"   , _aZB5[_x, 6]    ,Nil},;
                            {"CNATURDES"  , _aZB5[_x,10]    ,Nil},;
                            {"CTIPOTRAN"  , _sTp            ,Nil},;
                            {"CDOCTRAN"   , _sNumDoc        ,Nil},;
                            {"NVALORTRAN" , _nVlrRec        ,Nil},;
                            {"CHIST100"   , _aZB5[_x,12]    ,Nil},;
                            {"CBENEF100"  , _aZB5[_x,13]    ,Nil} }

            U_GravaSXK (cPerg, "01", "1", 'G' )
            U_GravaSXK (cPerg, "04", "1", 'G' )

            MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aFINA100,7)

            If lMsErroAuto
                //MostraErro()
                lCont := .F.

                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " ERRO -TRANSF.VLR.RECEBIDO:" + str(_aZB5[_x, 2]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,14] +"-"+ _aZB5[_x,15] +"-"+ _aZB5[_x,16] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc + chr (13) + chr (10) + ;
                                    " ERRO LOG:"  + memoread (NomeAutoLog ())
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()
            Else
                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " TRANSF.VLR.RECEBIDO:" + str(_aZB5[_x, 2]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,14] +"-"+ _aZB5[_x,15] +"-"+ _aZB5[_x,16] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc 
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()
            EndIf  

            U_GravaSXK (cPerg, "01", "2", 'D' )
            U_GravaSXK (cPerg, "04", "2", 'D' )  
        EndIf

        If lCont .and. _nVlrDes > 0
            // LANÇAMENTO DE DESPESAS DE REGISTRO - VLR DESP.COBRANÇA
            _aFINA100   := {{"CBCOORIG"   , _aZB5[_x, 4]    ,Nil},;
                            {"CAGENORIG"  , _aZB5[_x, 5]    ,Nil},;
                            {"CCTAORIG"   , _aZB5[_x, 6]    ,Nil},;
                            {"CNATURORI"  , _aZB5[_x,10]    ,Nil},;
                            {"CBCODEST"   , _aZB5[_x,14]    ,Nil},;
                            {"CAGENDEST"  , _aZB5[_x,15]    ,Nil},;
                            {"CCTADEST"   , _aZB5[_x,16]    ,Nil},;
                            {"CNATURDES"  , _aZB5[_x,10]    ,Nil},;
                            {"CTIPOTRAN"  , _sTp            ,Nil},;
                            {"CDOCTRAN"   , _sNumDoc        ,Nil},;
                            {"NVALORTRAN" , _nVlrDes        ,Nil},;
                            {"CHIST100"   , _aZB5[_x,12]    ,Nil},;
                            {"CBENEF100"  , _aZB5[_x,13]    ,Nil} }

            U_GravaSXK (cPerg, "01", "1", 'G' )
            U_GravaSXK (cPerg, "04", "1", 'G' )

            MSExecAuto({|x,y,z| FinA100(x,y,z)},0,_aFINA100,7)

            If lMsErroAuto
                //MostraErro()
                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = 'ZB5'
                _oEvento:Texto     = " ERRO - DESPESAS DE REGISTRO:" + str(_aZB5[_x, 3]) + chr (13) + chr (10) + ;
                                     " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,4] +"-"+ _aZB5[_x,5] +"-"+ _aZB5[_x,6] + chr (13) + chr (10) + ;
                                     " DOCUMENTO:" + _sNumDoc + chr (13) + chr (10) + ;
                                     " ERRO LOG:"  + memoread (NomeAutoLog ())
                _oEvento:CodEven   = "ZB5001"
                _oEvento:Grava()
            Else
                _oEvento := ClsEvent():New ()
                _oEvento:Alias    = 'ZB5'
                _oEvento:Texto    = " TRANSF.DESPESAS DE REGISTRO:" + str(_aZB5[_x, 3]) + chr (13) + chr (10) + ;
                                    " CHAVE:"     + _sFilBat +"-"+ _aZB5[_x,4] +"-"+ _aZB5[_x,5] +"-"+ _aZB5[_x,6] + chr (13) + chr (10) + ;
                                    " DOCUMENTO:" + _sNumDoc 
                _oEvento:CodEven  = "ZB5001"
                _oEvento:Grava()
            EndIf     

            U_GravaSXK (cPerg, "01", "2", 'D' )
            U_GravaSXK (cPerg, "04", "2", 'D' )
        EndIf

        If lCont .and. (_nVlrDes > 0 .or. _nVlrRec > 0)// grava status nos registros
            _GravaStatus('P','F', _sFilBat, _sFilial,_sFilReg)
        EndIf
    Next
Return
//
// --------------------------------------------------------------------------
// Grava Status em registro ZB5 
Static Function _GravaStatus(_sStaAnt, _sStatus, _sFilBat, _sFilial,_sFilReg)
    Local _i:= 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   ZB5.ZB5_FILIAL"
    _oSQL:_sQuery += "    ,ZB5.ZB5_SERIE"
    _oSQL:_sQuery += "    ,ZB5.ZB5_NUM"
    _oSQL:_sQuery += "    ,ZB5.ZB5_PARC"
    _oSQL:_sQuery += "    ,ZB5.ZB5_CLI"
    _oSQL:_sQuery += "    ,ZB5.ZB5_LOJA"
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZB5") + " ZB5 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZB4") + " ZB4 "
    _oSQL:_sQuery += " 	ON ZB4.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_FILIAL = ZB5.ZB5_FILIAL"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_BANCO = ZB5.ZB5_BANCO"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_AGEN = ZB5.ZB5_AGEN"
    _oSQL:_sQuery += " 		AND ZB4.ZB4_CONTA = ZB5.ZB5_CONTA"
    _oSQL:_sQuery += " WHERE ZB5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND ZB5.ZB5_STATUS = '" + _sStaAnt + "'"
    If _sFilBat <> '01'
        _oSQL:_sQuery += " AND ZB5.ZB5_FILIAL = '" + _sFilBat + "'"
    Else
        _oSQL:_sQuery += " AND ZB5.ZB5_FILIAL = '" + _sFilReg + "'"
    EndIf
    _aZB5 := aclone (_oSQL:Qry2Array ()) 

    For _i := 1 to Len(_aZB5)
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " UPDATE ZB5010 "
        _oSQL:_sQuery += " SET ZB5_STATUS = '" + _sStatus + "'"
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''
        _oSQL:_sQuery += " AND ZB5_STATUS = '" + _sStaAnt + "'"
        _oSQL:_sQuery += " AND ZB5_FILIAL = '" + _aZB5[_i, 1] + "'"
        _oSQL:_sQuery += " AND ZB5_SERIE  = '" + _aZB5[_i, 2] + "'"
        _oSQL:_sQuery += " AND ZB5_NUM    = '" + _aZB5[_i, 3] + "'"
        _oSQL:_sQuery += " AND ZB5_PARC   = '" + _aZB5[_i, 4] + "'"
        _oSQL:_sQuery += " AND ZB5_CLI    = '" + _aZB5[_i, 5] + "'"
        _oSQL:_sQuery += " AND ZB5_LOJA   = '" + _aZB5[_i, 6] + "'"
        _oSQL:Exec ()

        _oEvento := ClsEvent():New ()
        _oEvento:Alias    = 'ZB5'
        _oEvento:Texto    = " GRAVADO STATUS DE " + _sStaAnt + " PARA " + _sStatus + chr (13) + chr (10) + ;
                            " CHAVE: " + _aZB5[_i,1] +"-"+ _aZB5[_i,2] +"-"+ _aZB5[_i,3] +"-"+ _aZB5[_i,4] +"-"+ _aZB5[_i,5] +"-"+ _aZB5[_i,6] 
        _oEvento:CodEven  = "ZB5001"
        _oEvento:Grava()
    Next
Return
