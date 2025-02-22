// Programa...: BatZA4
// Autor......: Cl�udia Lion�o
// Data.......: 12/02/2024
// Descricao..: Importa verbas Mercanet -> Protheus
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Importa verbas Mercanet -> Protheus
// #PalavasChave      #batchs #verbas #mercanet 
// #TabelasPrincipais #
// #Modulos   		  #FAT
//
// Historico de alteracoes:
// 21/02/2024 - Claudia - Retirada as valida��es da importa��o.
// 18/09/2024 - Claudia - Incluida a grava��o do c�digo matriz. GLPI: 15953
// 03/02/2025 - Claudia - Alterado campo de banco. GLPI: 16791
// 20/02/2025 - Claudia - Devido a inclusao da nova etapa, incluido 
//                        ATI.ATIVIDADE = 6 na consulta. GLPI: 16924
//
// -------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatZA4()
    local _aAreaAnt  := U_ML_SRArea ()
    local _x   := 1
    _sLinkSrv = U_LkServer ('MERCANET')

    _oSQL := ClsSQL():New ()

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   PRC.CODIGO AS ZA4_NUMMER "
    _oSQL:_sQuery += "    ,RIGHT(REPLICATE('0', 6) + CONVERT(VARCHAR, PRC.CLIENTE), 6) AS ZA4_CLI "
    _oSQL:_sQuery += "    ,'01' AS ZA4_LOJA "
    _oSQL:_sQuery += "    ,RIGHT(REPLICATE('0', 3) + CONVERT(VARCHAR, ITE.OPD_CODIGO), 3) AS ZA4_COD "
    _oSQL:_sQuery += "    ,PRC.VALOR AS ZA4_VLR "
    _oSQL:_sQuery += "    ,PRC.DATA AS ZA4_DGER "
    _oSQL:_sQuery += "    ,'2' AS ZA4_SGER "
    _oSQL:_sQuery += "    ,'admnistrador' AS ZA4_UGER "
    _oSQL:_sQuery += "    ,ITE1.OPD_CODIGO AS ZA4_TLIB "
    _oSQL:_sQuery += "    ,PRC.DATA_1 AS ZA4_VENCTO "
    _oSQL:_sQuery += "    ,ZA3.ZA3_CTB AS ZA3_CTB "
    _oSQL:_sQuery += "    ,'BANCO:' + TRIM(STR(BANCO.OPD_CODIGO)) + ' AGENCIA:' + TRIM(PRC.AGENCIA) + ' CONTA:' + TRIM(PRC.CONTA) AS ZA4_DADDEP "
    _oSQL:_sQuery += "    ,PRC.DOCUMENTO AS ZA4_DOC "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR(2000), PRC.DESCRICAO )AS ZA4_HG_OBS "
    _oSQL:_sQuery += "    ,DB_TBREP_CODORIG AS ZA4_VEND "
    _oSQL:_sQuery += "    ,PRC.SITUACAO AS ETAPA "
    _oSQL:_sQuery += "    ,ZA3_IND AS ZA3_IND "
    _oSQL:_sQuery += "    ,CONVERT(VARCHAR(2000), PRC.PRODUTOS_VERBAS ) AS ZA4_OBSPRO "
    _oSQL:_sQuery += "    ,PRC.BANCO_AGENCIA_CONTA AS ZA4_DADDEP2 "
    _oSQL:_sQuery += " FROM "+ _sLinkSrv +".DB_OC_PRINCIPAL PRC "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE "
    _oSQL:_sQuery += " 	ON ITE.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE.SEQUENCIA = VERBA_TIPO "
    _oSQL:_sQuery += " 		AND ITE.OPD_PERGUNTA = 105 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS ITE1 "
    _oSQL:_sQuery += " 	ON ITE1.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND ITE1.SEQUENCIA = PRC.LIBERACAO_TIPO "
    _oSQL:_sQuery += " 		AND ITE1.OPD_PERGUNTA = 106 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ATIVIDADES ATI "
    _oSQL:_sQuery += " 	ON ATI.CODIGO_OC = PRC.CODIGO "
    _oSQL:_sQuery += " 	AND ATI.ATIVIDADE = 6 "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_CLIENTE CLI "
    _oSQL:_sQuery += " 	ON CLI.DB_CLI_CODIGO = PRC.CLIENTE "
    _oSQL:_sQuery += " LEFT JOIN "+ _sLinkSrv +".DB_OC_ITENS BANCO "
    _oSQL:_sQuery += " 	ON BANCO.CODIGO_OC = 37400002 "
    _oSQL:_sQuery += " 		AND BANCO.OPD_PERGUNTA = 103 "
    _oSQL:_sQuery += " 		AND BANCO.SEQUENCIA = PRC.BANCO "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZA3") + " ZA3 "
    _oSQL:_sQuery += " 	ON ZA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND ZA3.ZA3_COD = RIGHT(REPLICATE('0', 3) + CONVERT(VARCHAR, ITE.OPD_CODIGO), 3) "
    _oSQL:_sQuery += " INNER JOIN "+ _sLinkSrv +".DB_TB_REPRES "
    _oSQL:_sQuery += " 	ON DB_TBREP_CODIGO = PRC.REPRESENTANTE "
    _oSQL:_sQuery += " WHERE PRC.TIPO = 1 "
    _oSQL:_sQuery += " AND NOT EXISTS (SELECT "
    _oSQL:_sQuery += " 		1 "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZA4") + " ZA4 "
    _oSQL:_sQuery += " WHERE ZA4.D_E_L_E_T_='' "
	_oSQL:_sQuery += " AND ZA4.ZA4_NUMMER = PRC.CODIGO) "
    _oSQL:_sQuery += " AND PRC.DATA >= '2024-03-14' " // data que entrar em vigor
    _oSQL:_sQuery += " AND PRC.SITUACAO = 'Aprovada' "
    u_log(_oSQL:_sQuery)
    _aVerbas := aclone(_oSQL:Qry2Array())

    For _x := 1 to Len(_aVerbas)
        _sNumMerc := alltrim(str(_aVerbas[_x, 1]))
        _sZA4Num := GetSXENum("ZA4","ZA4_NUM")

        _oSQL := ClsSQL():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT count(*) FROM ZA4010 WHERE D_E_L_E_T_='' AND ZA4_NUM='" + _sZA4Num + "'"
        _aOK := aclone(_oSQL:Qry2Array(.f.,.f.))

        _oCtaRapel := ClsCtaRap():New ()
		_sRede := _oCtaRapel:RetCodRede(_aVerbas[_x, 2], _aVerbas[_x, 3])

        _sBanco := ''
        if !empty(_aVerbas[_x,12])
            _sBanco := _aVerbas[_x,12]
        else
            _sBanco := _aVerbas[_x,19]
        endif

        if len(_aOK) > 0
            RecLock ("ZA4",.T.)
                ZA4 -> ZA4_NUM      := _sZA4Num       
                ZA4 -> ZA4_CLI      := _sRede		
                ZA4 -> ZA4_LOJA     := _aVerbas[_x, 3]		
                ZA4 -> ZA4_COD	    := _aVerbas[_x, 4]	
                ZA4 -> ZA4_VLR	    := _aVerbas[_x, 5]	
                ZA4 -> ZA4_DGER     := date()   
                ZA4 -> ZA4_SGER     := _aVerbas[_x, 7]   
                ZA4 -> ZA4_UGER     := _aVerbas[_x, 8]   
                ZA4 -> ZA4_TLIB	    := alltrim(str(_aVerbas[_x, 9]))	
                ZA4 -> ZA4_VENCTO   := _aVerbas[_x,10]	
                ZA4 -> ZA4_CTB      := _aVerbas[_x,11]	
                ZA4 -> ZA4_DADDEP   := _sBanco          //_aVerbas[_x,12]
                ZA4 -> ZA4_DOC      := _aVerbas[_x,13]
                ZA4 -> ZA4_HG_OBS	:= _aVerbas[_x,14]
                ZA4 -> ZA4_VEND		:= alltrim(str(_aVerbas[_x,15])) 
                ZA4 -> ZA4_SUTL     := '0'
                ZA4 -> ZA4_NUMMER   := _aVerbas[_x, 1]
                ZA4 -> ZA4_OBSPRO   := alltrim(_aVerbas[_x,18])
                ZA4 -> ZA4_STATUS   := 'I'    
            MsUnLock()
            
            _oSQL := ClsSQL():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT * FROM ZA4010 WHERE ZA4_NUM='" + _sZA4Num + "'"
            _aOK := aclone(_oSQL:Qry2Array())

            if len(_aOK) <= 0
                _oEvento := ClsEvent():New ()
                _oEvento:Alias     = "ZA4"
                _oEvento:Texto     = "Verba n�o gerada. Cod.Merc.:"+_sNumMerc
                _oEvento:CodEven   = "ZA4001"
                _oEvento:Produto   = _sNumMerc
                _oEvento:Grava()    

                _oAviso := ClsAviso():new ()
                _oAviso:Tipo       = 'E'  // I=Info;A=Aviso;E=Erro
                _oAviso:Titulo     = "Verba inclu�da Mercanet x Protheus"
                _oAviso:Texto      = "Verba " + _sZA4Num + " n�o inclu�da!"
                _oAviso:DestinZZU  = {'160'}  // grupo
                _oAviso:Origem     = procname()
                _oAviso:Formato    = 'H'  // [T]exto ou [H]tml
                _oAviso:Grava ()
            else
            
                // REALIZAR RATEIO QUANDO TIPO "RATEIO"
                _sTipo := Posicione("ZA3",1, xFilial("ZA3") + _aVerbas[_x, 4], "ZA3_TIPO") // ZA3_FILIAL+ZA3_COD        

                if _sTipo == 'R'   
                    _GrvRateio(_sZA4Num, _aVerbas[_x, 2],_aVerbas[_x, 3])
                endif         

                _oAviso := ClsAviso():new ()
                _oAviso:Tipo       = 'I'  // I=Info;A=Aviso;E=Erro
                _oAviso:Titulo     = "Verba inclu�da Mercanet x Protheus"
                _oAviso:Texto      = "Verba "+ _sZA4Num + " inclu�da com sucesso!"
                _oAviso:DestinZZU  = {'160'}  // grupo
                _oAviso:Origem     = procname()
                _oAviso:Formato    = 'H'  // [T]exto ou [H]tml
                _oAviso:Grava ()
                                                                                                                      
            endif
        else
            _oEvento := ClsEvent():New ()
            _oEvento:Alias     = "ZA4"
            _oEvento:Texto     = "Verba n�o gerada devido a numera��o. Cod.Protheus:"+ _sZA4Num +" Cod.Merc.:"+_sNumMerc
            _oEvento:CodEven   = "ZA4001"
            _oEvento:Produto   = _sNumMerc
            _oEvento:Grava()
        endif
        do while __lSX8
            ConfirmSX8 ()
        enddo
    Next 
    U_ML_SRArea (_aAreaAnt)
Return
//
// -------------------------------------------------------------------------------------------
// Gera financeiro
Static Function _GeraFina(_aVerbas, _x, _sZA4Num)
    local _lRetFin := .T.
    
    _sCliente := _aVerbas[_x, 2]
    _sLoja    := _aVerbas[_x, 3]
    _nValor   := _aVerbas[_x, 5]
    _sTLib    := alltrim(str(_aVerbas[_x, 9]))
    _sDtVcto  := _aVerbas[_x,10]
    _sNumMerc := alltrim(str(_aVerbas[_x, 1]))

    U_GravaSX1 ('FIN040', "01", 1) // for�a parametro de contabiliza��o on-line como SIM
    _aAutoSE1 := {}
    
    aAdd(_aAutoSE1, {"E1_FILIAL"    , xfilial("SE1")    , Nil})
    aAdd(_aAutoSE1, {"E1_PREFIXO"   , "CV "             , Nil})
    aAdd(_aAutoSE1, {"E1_NUM"       , _sZA4Num          , Nil})
    aAdd(_aAutoSE1, {"E1_PARCELA"   , '1'               , Nil})
    aAdd(_aAutoSE1, {"E1_CLIENTE"   , _sCliente         , Nil})
    aAdd(_aAutoSE1, {"E1_LOJA"      , _sLoja            , Nil})
    AAdd(_aAutoSE1, {"E1_TIPO"      , 'NCC'             , Nil})
    AAdd(_aAutoSE1, {"E1_NATUREZ"   , 'VERBAS'          , Nil})
    AAdd(_aAutoSE1, {"E1_EMISSAO"   , DATE()            , Nil})
    AAdd(_aAutoSE1, {"E1_VENCTO"    , _sDtVcto          , Nil})
    AAdd(_aAutoSE1, {"E1_VALOR"     , _nValor           , Nil})
    AAdd(_aAutoSE1, {"E1_ORIGEM"    , 'VERBAS'          , Nil})
    AAdd(_aAutoSE1, {"E1_HIST"      , IIF(_sTLib=='3','BOLETO','DEPOSITO'), Nil}) 
    
    // Inclui titulo a receber via rotina automatica.
    lMsHelpAuto := .T.  // se .T. direciona as mensagens de help
    lMsErroAuto := .F.  // necessario a criacao
    
    DbSelectArea("SE1")
    dbsetorder (1)
    MsExecAuto({|x,y|FINA040(x,y)},_aAutoSE1,3)

    If lMsErroAuto
        if empty (NomeAutoLog ())
            _sErro = "Nao foi possivel ler o arquivo de log de erros."
        else
            _sErro = memoread (NomeAutoLog ())
        endif
        _sMsg    := alltrim(_sErro) + ". Cod.Merc.:"+ _sNumMerc
        _lRetFin := .F.
    endif

Return _lRetFin
//
// -------------------------------------------------------------------------------------------
// Grava rateio
Static Function _GrvRateio(_sZA4Num, _sCliente, _sLoja)
    Local _aProd := {}
    Local _x     := 0

    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT DISTINCT "
    _oSQL:_sQuery += " 	    D2_COD "
    _oSQL:_sQuery += " FROM SD2010 "
    _oSQL:_sQuery += " WHERE D2_FILIAL = '"+ xFilial("SD1") +"' "
    _oSQL:_sQuery += " AND D2_CLIENTE  = '"+ _sCliente +"' "
    _oSQL:_sQuery += " AND D2_LOJA     = '"+ _sLoja    +"' "
    _oSQL:_sQuery += " AND D2_EMISSAO BETWEEN '" + dtos(YearSub(date(), 1)) + "' AND '"+ dtos(date()) + "' "
    _aProd := aclone(_oSQL:Qry2Array())

    _nQtd := Len(_aProd)

    If _nQtd > 0
        _nPerc := round(100/_nQtd,2)

        For _x := 1 to Len(_aProd)
             RecLock ("ZC2",.T.)
                ZC2 -> ZC2_FILIAL   := '  '       
                ZC2 -> ZC2_VERBA    := _sZA4Num	
                ZC2 -> ZC2_CLIENT   := _sCliente	
                ZC2 -> ZC2_LOJA	    := _sLoja	
                ZC2 -> ZC2_PROD	    := _aProd[_x, 1]	
                ZC2 -> ZC2_PERC     := _nPerc  
                ZC2 -> ZC2_TIPO     := 'R'    
            MsUnLock()
        Next
    EndIf
Return
