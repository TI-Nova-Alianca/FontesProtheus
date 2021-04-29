// Programa...: BatVerZB5
// Autor......: Cláudia Lionço
// Data.......: 29/04/2021
// Descricao..: Batch de verificação dos batchs da Transf. bancária automatica
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Batch de verificação dos batchs da Transf. bancária automatica
// #PalavasChave      #transferencia_automatica #transferencia_bancaria #batch_verificacao
// #TabelasPrincipais #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatVerZB5()
    Local _aZB5     := {}
    Local _aZZ6     := {}
    Local _x        := {}
    Local _aRetorno := {}

	u_logIni ()
	u_log ("Iniciando em", date (), time ())

    // ---------------------------- REGISTROS ABERTOS
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += "	  ZB5_FILIAL"
    _oSQL:_sQuery += "   ,ZB5_NUM"
    _oSQL:_sQuery += "   ,ZB5_SERIE"
    _oSQL:_sQuery += "   ,ZB5_PARC"
    _oSQL:_sQuery += "   ,ZB5_VLRREC"
    _oSQL:_sQuery += "   ,ZB5_VLRDES"
    _oSQL:_sQuery += "   ,ZB5_DTABAI"
    _oSQL:_sQuery += "   ,ZB5_DTAPRO"
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZB5")
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND ZB5_STATUS <> 'F'"
    _aZB5 := aclone (_oSQL:Qry2Array ()) 

    If Len(_aZB5) > 0
        For _x:=1 to Len(_aZB5)
            aadd(_aRetorno, {   _aZB5[_x, 1] ,; // FILIAL
                                _aZB5[_x, 2] ,; // NUMERO
                                _aZB5[_x, 3] ,; // SERIE
                                _aZB5[_x, 4] ,; // PARCELA
                                _aZB5[_x, 5] ,; // VLR. RECEBIDO
                                _aZB5[_x, 6] ,; // VLR. DESCONTO
                                _aZB5[_x, 7] ,; // DT. BAIXA
                                _aZB5[_x, 8] }) // DT. PROCESSAMENTO
        Next

        _aCols = {}
        aadd(_aCols, {'FILIAL'              , "left"    ,  "@!"})
        aadd(_aCols, {'NUMERO'              , "left"    ,  "@!"})
        aadd(_aCols, {'SERIE'               , "left"    ,  "@!"})
        aadd(_aCols, {'PARCELA'             , "left"    ,  "@!"})
        aadd(_aCols, {'VLR.RECEBIDO'        , "right"   ,  "@E 999,999,999.99"})
        aadd(_aCols, {'VLR.DESCONTO'        , "right"   ,  "@E 999,999,999.99"})
        aadd(_aCols, {'DT.BAIXA'            , "left"    ,  "@!"})
        aadd(_aCols, {'DT.PROCESSAMENTO'    , "left"    ,  "@!"})

        _sMsg := '<H1 align="center"></H1>'

        _oAUtil := ClsAUtil():New (_aRetorno)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="0" align="center"', .T.)
        _sDestin := 'claudia.lionco@novaalianca.coop.br;sandra.sugari@novaalianca.coop.br'

		U_SendMail (_sDestin, "VERIFICACOES:Reg. de transferencias não fechados ", _sMsg, {})
    EndIf


    // ---------------------------- BATCHS ABERTOS
    _aRetorno := {}

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   ZZ6_DADOS"
    _oSQL:_sQuery += "    ,ZZ6_CMD"
    _oSQL:_sQuery += "    ,ZZ6_DTINC"
    _oSQL:_sQuery += "    ,ZZ6_DTINI"
    _oSQL:_sQuery += "    ,ZZ6_DTBASE"
    _oSQL:_sQuery += "    ,ZZ6_DTUEXE"
    _oSQL:_sQuery += "    ,ZZ6_ARQLOG"
    _oSQL:_sQuery += " FROM ZZ6010"
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND ZZ6_CMD LIKE '%BatTransf%'"
    _oSQL:_sQuery += " AND ZZ6_ATIVO = 'S'"
    _oSQL:_sQuery += " AND ZZ6_RODADO <> 'S'"
    _aZZ6 := aclone (_oSQL:Qry2Array ()) 

    If Len(_aZZ6) > 0
        For _x:=1 to Len(_aZZ6)
            aadd(_aRetorno, {   _aZZ6[_x, 1] ,; // DADOS
                                _aZZ6[_x, 2] ,; // CMD
                                _aZZ6[_x, 3] ,; // DT INCLUSAO
                                _aZZ6[_x, 4] ,; // DT INICIAL
                                _aZZ6[_x, 5] ,; // DT BASE
                                _aZZ6[_x, 6] ,; // DT EXECUSAO
                                _aZZ6[_x, 7] }) // ARQUIVO LOG
        Next

        _aCols = {}
        aadd(_aCols, {'DADOS'       , "left"    ,  "@!"})
        aadd(_aCols, {'COMANDO'     , "left"    ,  "@!"})
        aadd(_aCols, {'DT.INCLUSAO' , "left"    ,  "@!"})
        aadd(_aCols, {'DT.INICIAL'  , "left"    ,  "@!"})
        aadd(_aCols, {'DT.BASE'     , "left"    ,  "@!"})
        aadd(_aCols, {'DT.EXECUSAO' , "left"    ,  "@!"})
        aadd(_aCols, {'ARQUIVO LOG' , "left"    ,  "@!"})

        _sMsg := '<H1 align="center"></H1>'
		_sMsg += '<H3 align="center">BATCHS DE TRANSFERENCIAS NAO EXECUTADOS</H2>' + chr (13) + chr (10)

        _oAUtil := ClsAUtil():New (_aRetorno)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="0" align="center"', .T.)
        _sDestin := 'claudia.lionco@novaalianca.coop.br;sandra.sugari@novaalianca.coop.br'

		U_SendMail (_sDestin, "VERIFICACOES:Batchs de transferencias não executados ", _sMsg, {})
    EndIf
Return
