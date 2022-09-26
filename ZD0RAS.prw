// Programa...: ZD0RAS
// Autor......: Cláudia Lionço
// Data.......: 13/07/2022
// Descricao..: Gera títulos RA's dos recebíveis Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera títulos RA's dos recebíveis Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce #RA
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include "protheus.ch"
#include "tbiconn.ch"

User Function ZD0RAS(dDataIni, dDataFin)
    Private cPerg := "ZD0RAS"
	
    u_logIni()
    
    _ValidPerg()
    If Pergunte(cPerg,.T.)  
        dDataIni := mv_par01
        dDataFin := mv_par02

        MsAguarde({|| _GeraTitulos(dDataIni, dDataFin)}, "Aguarde...", "Gerando Títulos RA's...")
    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Gera titulos RA's para compensação
Static Function _GeraTitulos(dDataIni, dDataFin)
    Local _aZD0     := {}
    Local _aAutoSE1 := {}
    Local _x        := 0
    Local _y        := 0
    Local _i        := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "		ZD0_FILIAL AS FILIAL "          // 1
    _oSQL:_sQuery += "	   ,ZD0_TID AS ID_TRANSACAO "       // 2
    _oSQL:_sQuery += "	   ,ZD0_RID AS ID_RECEBIVEL "       // 3
    _oSQL:_sQuery += "	   ,ZD0_DTAPGT AS DATA_PGTO "       // 4
    _oSQL:_sQuery += "	   ,ZD0_PARCEL AS PARCELA "         // 5
    _oSQL:_sQuery += "	   ,ZD0_VLRPAR AS VALOR_PARCELA "   // 6
    _oSQL:_sQuery += "	   ,ZD0_TAXTOT AS TAXAS "           // 7
    _oSQL:_sQuery += "     ,ZD0_VLRLIQ AS VALOR_LIQ "       // 8
    _oSQL:_sQuery += "	   ,ZD0_PGTMET AS METODO_PGTO "     // 9
    _oSQL:_sQuery += "	   ,ZD0_PGTTIP AS TIPO "            // 10
    _oSQL:_sQuery += "	   ,ZD0_CLIENT AS CLIENTE "         // 11
    _oSQL:_sQuery += "	   ,ZD0_LOJA AS LOJA "              // 12
    _oSQL:_sQuery += "	   ,ZD0_STABAI AS STATUS "          // 13
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZD0") + " ZD0 "
    _oSQL:_sQuery += "	WHERE ZD0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "	AND ZD0.ZD0_FILIAL   = '" + xFilial('ZD0') + "' "
    _oSQL:_sQuery += "	AND ZD0_DTAPGT BETWEEN '" + dtos(dDataIni) + "' AND '" + dtos(dDataFin) + "' "
    _oSQL:_sQuery += "	AND ZD0_STABAI IN ('A','E')"
    _oSQL:_sQuery += "	ORDER BY FILIAL, VALOR_PARCELA  DESC "
    _aZD0 := _oSQL:Qry2Array ()

    For _x:=1 to Len(_aZD0)
        // entrada de valores
        If alltrim(_aZD0[_x, 10]) == 'credit' .and. _aZD0[_x, 13] == 'A'
            _aAutoSE1 := {}

            // Define banco
            If xFilial('ZD0') == '01'
                _sBanco     := '237'
                _sAgencia   := '03471'
                _sConta     := '0000470'
            else
                _sBanco     := '041'
                _sAgencia   := '0873'
                _sConta     := '0619710901'
            EndIf

            // Gera RA's com pgtos
            _sHist    := 'PAGAR.ME '+ _aZD0[_x,2] + '-' + _aZD0[_x,3]
            _nTitNum  := _BuscaNumeracao(_aZD0[_x,1])

            aAdd(_aAutoSE1, {"E1_FILIAL"   , _aZD0[_x,1]            , Nil})
            aAdd(_aAutoSE1, {"E1_PREFIXO"  , 'PGM'                  , Nil})
            aAdd(_aAutoSE1, {"E1_NUM"      , _nTitNum               , Nil})            
            aAdd(_aAutoSE1, {"E1_PARCELA"  , _aZD0[_x,5]            , Nil})
            aAdd(_aAutoSE1, {"E1_TIPO"     , 'RA'                   , Nil})
            aAdd(_aAutoSE1, {"E1_NATUREZ"  , '110101'               , Nil})
            aAdd(_aAutoSE1, {"E1_CLIENTE"  , _aZD0[_x,11]           , Nil})
            aAdd(_aAutoSE1, {"E1_LOJA"     , _aZD0[_x,12]           , Nil})
            aAdd(_aAutoSE1, {"E1_EMISSAO"  , dDataBase              , Nil}) // stod(_aZD0[_x,4])
            aAdd(_aAutoSE1, {"E1_VENCTO"   , dDataBase              , Nil})
            aAdd(_aAutoSE1, {"E1_VENCREA"  , dDataBase              , Nil})
            aAdd(_aAutoSE1, {"CBCOAUTO"    , _sBanco                , Nil})
            aAdd(_aAutoSE1, {"CAGEAUTO"    , _sAgencia              , Nil})
            aAdd(_aAutoSE1, {"CCTAAUTO"    , _sConta                , Nil}) 
            aAdd(_aAutoSE1, {"E1_VALOR"    , _aZD0[_x,8]            , Nil})
            aAdd(_aAutoSE1, {"E1_VLCRUZ"   , _aZD0[_x,8]            , Nil})
            aAdd(_aAutoSE1, {"E1_ORIGEM"   , 'PAGAR.ME'             , Nil})           
            aAdd(_aAutoSE1, {"E1_HIST"     , _sHist                 , Nil})
            aAdd(_aAutoSE1, {"E1_MOEDA"    , 1                      , Nil})

            Begin Transaction
                lMsErroAuto := .F.
                MSExecAuto({|x,y| FINA040(x,y)}, _aAutoSE1, 3)
                
                If lMsErroAuto
                    MostraErro()

                    _sErro   := ""
                    aLogAuto := GetAutoGRLog()

                    For _y := 1 To Len(aLogAuto)
                        _sErro += aLogAuto[_y] + CRLF
                    Next
                    
                    DisarmTransaction()
                    u_log2("Erro", _sErro)
                else
                    u_log2("Aviso", "Gravado título "+ alltrim(_nTitNum) + " refetente a Id Transacao " +  _aZD0[_x,2])
                EndIf
            End Transaction   

            // se gravou sem erros, grava os campos customizados
            If lMsErroAuto == .F.
                // grava id no titulo
                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " UPDATE " + RetSQLName ("SE1") + " SET E1_VAIDT = '"+ alltrim(_aZD0[_x,2]) +"'"
                _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
                _oSQL:_sQuery += " AND E1_FILIAL  = '" + _aZD0[_x,1]  + "'"
                _oSQL:_sQuery += " AND E1_NUM     = '" + _nTitNum     + "'"
                _oSQL:_sQuery += " AND E1_PARCELA = '" + _aZD0[_x,5]  + "'"
                _oSQL:_sQuery += " AND E1_PREFIXO = 'PGM' "
                _oSQL:_sQuery += " AND E1_TIPO    = 'RA' "
                _oSQL:_sQuery += " AND E1_CLIENTE = '" + _aZD0[_x,11] + "'"
                _oSQL:_sQuery += " AND E1_LOJA    = '01' "
                _oSQL:Log ()
                _oSQL:Exec ()

                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " UPDATE " + RetSQLName ("ZD0") + " SET ZD0_STABAI = 'R' "
                _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
                _oSQL:_sQuery += " AND ZD0_FILIAL = '" + _aZD0[_x,1]   + "'"
                _oSQL:_sQuery += " AND ZD0_TID    = '" + _aZD0[_x,2]   + "'"
                _oSQL:_sQuery += " AND ZD0_RID    = '" + _aZD0[_x,3]   + "'"
                _oSQL:Log ()
                _oSQL:Exec ()
            EndIf         
        
        else // estorno de valores
            // Busca RA para estorno, caso não tenha sido baixado
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += "     E1_FILIAL "
            _oSQL:_sQuery += "    ,E1_PREFIXO "
            _oSQL:_sQuery += "    ,E1_NUM "
            _oSQL:_sQuery += "    ,E1_PARCELA "
            _oSQL:_sQuery += "    ,E1_TIPO "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
            _oSQL:_sQuery += " WHERE E1_FILIAL = '" + _aZD0[_x,1] + "' "
            _oSQL:_sQuery += " AND E1_VAIDT    = '" + _aZD0[_x,2] + "' "
            _oSQL:_sQuery += " AND E1_TIPO     = 'RA' "
            _oSQL:_sQuery += " AND E1_PREFIXO  = 'PGM' "
            _oSQL:_sQuery += " AND E1_SALDO    = E1_VALOR "
            _oSQL:Log ()
            _aRA := _oSQL:Qry2Array ()

            For _i:=1 to Len(_aRA)
                DbSelectArea("SE1")
                SE1 -> (DBSetorder(1))
                If DbSeek(xFilial("SE1") + _aRA[_i, 2] + _aRA[_i, 3] + _aRA[_i, 4] + _aRA[_i, 5])
                    RecLock("SE1",.F.)
                    DbDelete()
                    MsUnLock()

                    _oSQL:= ClsSQL ():New ()
                    _oSQL:_sQuery := ""
                    _oSQL:_sQuery += " UPDATE " + RetSQLName ("ZD0") + " SET ZD0_STABAI = 'E' "
                    _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
                    _oSQL:_sQuery += " AND ZD0_FILIAL = '" + _aZD0[_x,1]   + "'"
                    _oSQL:_sQuery += " AND ZD0_TID    = '" + _aZD0[_x,2]   + "'"
                    _oSQL:Log ()
                    _oSQL:Exec ()
                Endif
            Next   

            // Busca título para cancelamento, caso esteja baixado
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	   SE1.E1_FILIAL "
            _oSQL:_sQuery += "    ,SE1.E1_PREFIXO "
            _oSQL:_sQuery += "    ,SE1.E1_NUM "
            _oSQL:_sQuery += "    ,SE1.E1_PARCELA "
            _oSQL:_sQuery += "    ,SE1.E1_TIPO "
            _oSQL:_sQuery += "    ,SE1.E1_CLIENTE "
            _oSQL:_sQuery += "    ,SE1.E1_LOJA "
            _oSQL:_sQuery += "    ,SE1.E1_EMISSAO "
            _oSQL:_sQuery += "    ,SE1.E1_BAIXA "
            _oSQL:_sQuery += "    ,SE1.E1_VALOR "
            _oSQL:_sQuery += "    ,SE1.E1_PORTADO "
            _oSQL:_sQuery += "    ,SE1.E1_AGEDEP "
            _oSQL:_sQuery += "    ,SE1.E1_CONTA "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
            _oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND SE1.E1_FILIAL    = '" + _aZD0[_x,1]   + "'"
            _oSQL:_sQuery += " AND SE1.E1_VAIDT     = '" + _aZD0[_x,2]   + "'"
            _oSQL:_sQuery += " AND SE1.E1_PARCELA   = '" + _aZD0[_x,5]   + "'"
            _oSQL:_sQuery += " AND SE1.E1_TIPO     <> 'RA' "
            _oSQL:_sQuery += " AND SE1.E1_BAIXA    <> '' "
            _aSE1 := _oSQL:Qry2Array ()

            // Se tem baixas na parcela, estorna
            If len(_aSE1) > 0
                lMsErroAuto := .F.
                _aAutoSE1   := {}

                aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aSE1[1,1]    , Nil})
                aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aSE1[1,2]    , Nil})
                aAdd(_aAutoSE1, {"E1_NUM"     	, _aSE1[1,3]	, Nil})
                aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aSE1[1,4]    , Nil})
                aAdd(_aAutoSE1, {"E1_TIPO" 	    , _aSE1[1,5]    , Nil})
                aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aSE1[1,6] 	, Nil})
                aAdd(_aAutoSE1, {"E1_LOJA"    	, _aSE1[1,7]	, Nil})
                aAdd(_aAutoSE1, {"E1_EMISSAO"   , _aSE1[1,8] 	, Nil})
                aAdd(_aAutoSE1, {"AUTDTBAIXA"   , _aSE1[1,9]    , Nil})
                aAdd(_aAutoSE1, {"AUTDTCREDITO" , _aSE1[1,9]    , Nil})
                aAdd(_aAutoSE1, {"AUTAGENCIA"  	, _aSE1[1,12]   , Nil})
                aAdd(_aAutoSE1, {"AUTCONTA"  	, _aSE1[1,13]   , Nil})
                aAdd(_aAutoSE1, {"AUTDESCONT"	, 0         	, Nil})
                aAdd(_aAutoSE1, {"AUTMULTA"  	, 0         	, Nil})
                aAdd(_aAutoSE1, {"AUTJUROS"  	, 0         	, Nil})
                aAdd(_aAutoSE1, {"AUTVALREC"  	, _aSE1[1,10] 	, Nil})
                _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

                cPerg = 'FIN070'
                _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
                U_GravaSX1 (cPerg, "01", 2)    // testar mostrando o lcto contabil depois pode passar para nao
                U_GravaSX1 (cPerg, "04", 2)    // esse movimento tem que contabilizar
                U_GravaSXK (cPerg, "01", "2", 'G' )
                U_GravaSXK (cPerg, "04", "2", 'G' )

				MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,5,.F.,5) // rotina automática para cancelamento de títulos

                If lMsErroAuto
                    u_log(memoread (NomeAutoLog ()))
                    MostraErro()
                Endif
                
                U_GravaSXK (cPerg, "01", "2", 'D' )
                U_GravaSXK (cPerg, "04", "2", 'D' )

                U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
            EndIf
         
        EndIf
    Next
    // chama relatorio de baixas
    U_ZD0RCMP(dDataIni, dDataFin)
Return
//
// -----------------------------------------------------------------------------------
// Busca numeração para titulos
Static Function _BuscaNumeracao(_sFilial)
    Local _x       := 0
    Local _sTabela := '01' 
    Local _sChave  := 'PGM'

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    X5_DESCRI "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SX5") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND X5_FILIAL    = '" + _sFilial + "' "
    _oSQL:_sQuery += " AND X5_TABELA    = '" + _sTabela + "' "
    _oSQL:_sQuery += " AND X5_CHAVE     = '" + _sChave  + "' "
    _aSX5 := _oSQL:Qry2Array ()

    For _x := 1 to Len(_aSX5)
        _nNumAtu  := val(_aSX5[_x,1])
        _nNumAtu  := _nNumAtu + 1
        _sNumNovo := PADL(alltrim(str(_nNumAtu)),9,'0')
    Next

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " UPDATE " + RetSQLName ("SX5") 
    _oSQL:_sQuery += " 	    SET X5_DESCRI='"+ _sNumNovo +"', X5_DESCSPA='"+ _sNumNovo +"', X5_DESCENG='"+ _sNumNovo +"'"
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND X5_FILIAL    = '" + _sFilial + "' "
    _oSQL:_sQuery += " AND X5_TABELA    = '" + _sTabela + "' "
    _oSQL:_sQuery += " AND X5_CHAVE     = '" + _sChave  + "' "
    _oSQL:Exec ()

Return _sNumNovo
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D",  8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
