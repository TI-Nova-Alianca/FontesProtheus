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
    Local _nSeq     := 1
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
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZD0") + " ZD0 "
    _oSQL:_sQuery += "	WHERE ZD0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "	AND ZD0.ZD0_FILIAL   = '" + xFilial('ZD0') + "' "
    _oSQL:_sQuery += "	AND ZD0_DTAPGT BETWEEN '" + dtos(dDataIni) + "' AND '" + dtos(dDataFin) + "' "
    If !empty(mv_par03)
        _oSQL:_sQuery += "	AND ZD0_TID = '" + mv_par03 + "'"
    EndIf
    _oSQL:_sQuery += "	AND ZD0_STABAI = 'A' ""
    _oSQL:_sQuery += "	ORDER BY FILIAL, VALOR_PARCELA  DESC "
    _aZD0 := _oSQL:Qry2Array ()

    For _x:=1 to Len(_aZD0)
        // entrada de valores
        If alltrim(_aZD0[_x, 10]) == 'credit'
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
            _nTitNum  := _GeraNumeracao(_nSeq, _aZD0[_x,4], _aZD0[_x,5])
            _nSeq ++ 

            aAdd(_aAutoSE1, {"E1_FILIAL"   , _aZD0[_x,1]            , Nil})
            aAdd(_aAutoSE1, {"E1_PREFIXO"  , '10'                   , Nil})
            aAdd(_aAutoSE1, {"E1_NUM"      , _nTitNum               , Nil})            
            aAdd(_aAutoSE1, {"E1_PARCELA"  , _aZD0[_x,5]            , Nil})
            aAdd(_aAutoSE1, {"E1_TIPO"     , 'RA'                   , Nil})
            aAdd(_aAutoSE1, {"E1_NATUREZ"  , '110101'               , Nil})
            aAdd(_aAutoSE1, {"E1_CLIENTE"  , _aZD0[_x,11]           , Nil})
            aAdd(_aAutoSE1, {"E1_LOJA"     , _aZD0[_x,12]           , Nil})
            aAdd(_aAutoSE1, {"E1_EMISSAO"  , stod(_aZD0[_x,4])      , Nil})
            aAdd(_aAutoSE1, {"E1_VENCTO"   , stod(_aZD0[_x,4])      , Nil})
            aAdd(_aAutoSE1, {"E1_VENCREA"  , stod(_aZD0[_x,4])      , Nil})
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
                    //u_help("Gravado título "+ alltrim(_nTitNum) + " refetente a Id Transacao " +  _aZD0[_x,2])
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
                _oSQL:_sQuery += " AND E1_PREFIXO = '10'"
                _oSQL:_sQuery += " AND E1_TIPO    = 'RA'"
                _oSQL:_sQuery += " AND E1_CLIENTE = '" + _aZD0[_x,11] + "'"
                _oSQL:_sQuery += " AND E1_LOJA    = '01'"
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

        
        // estorno de valores
        else
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
                    //_oSQL:_sQuery += " AND ZD0_RID    = '" + _aZD0[_x,3]   + "'"
                    _oSQL:Log ()
                    _oSQL:Exec ()
                Endif
            Next            
        EndIf
    Next
    // chama relatorio de baixas
    U_ZD0RCMP(dDataIni, dDataFin)
Return
//
// -----------------------------------------------------------------------------------
// Gera numeração para titulos
Static Function _GeraNumeracao(_nSeq, _dtPgto, _sParcel)
    _sSeq := alltrim(str(_nSeq))

    _sAno := SubStr(_dtPgto, 3, 2)
    _sMes := SubStr(_dtPgto, 5, 2)
    _sDia := SubStr(_dtPgto, 7, 2)

    _sNumero := _sDia + _sMes + _sAno +_sSeq + _sParcel

Return _sNumero
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Id Transação ", "C", 15, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
