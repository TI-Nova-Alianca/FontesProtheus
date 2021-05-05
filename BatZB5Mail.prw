// Programa...: BatZB5Mail
// Autor......: Cláudia Lionço
// Data.......: 13/03/2021
// Descricao..: Bat para envio de email de erros da Transf. bancária automatica
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Bat para envio de email de erros da Transf. bancária automatica
// #PalavasChave      #transfrencia_automatica #transferencia_bancaria 
// #TabelasPrincipais #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 29/03/2021 - Cláudia - Incluido logs de execução
// 05/05/2021 - Claudia - Incluida msg de resumo de lançamentos no mes. GLPI: 9983
//
// ----------------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatZB5Mail()
    Local _aFilial  := {}
    Local _aCT201   := {}
    Local _aCT2Fil  := {}
    Local _aRetorno := {}
    Local _nTotMat  := 0
    Local _nTotFil  := 0
    Local _x        := 0
    Local _i        := 0

    u_logIni ()
	u_log ("Iniciando em", date (), time ())

    // _nDiaSemana := Dow(date())

    // If _nDiaSemana == 2
    //     _dDate := DaySub(date(), 3)
    // Else
    //     _dDate := DaySub(date(), 1)
    // EndIf

    _dDate := DaySub(date(), 1)
    
    // Busca filiais
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	   M0_CODFIL"
    _oSQL:_sQuery += "    ,M0_FILIAL"
    _oSQL:_sQuery += " FROM VA_SM0"
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND M0_CODIGO = '01'"
    _oSQL:_sQuery += " AND M0_CODFIL <> '01'"
    _aFilial := aclone (_oSQL:Qry2Array ()) 

    For _x:=1 to Len(_aFilial)
        _n01Vlr  := 0
        _nXXVlr  := 0

        // Busca registro da matriz
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT"
        _oSQL:_sQuery += " 	     CT2_FILIAL"
        _oSQL:_sQuery += "      ,CT2_HIST"
        _oSQL:_sQuery += "      ,SUM(CT2_VALOR) / 2"
        _oSQL:_sQuery += " FROM " + RetSQLName ("CT2") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
        _oSQL:_sQuery += " AND CT2_FILIAL = '01'"
        _oSQL:_sQuery += " AND CT2_DATA = '" + DTOS(_dDate) + "'"
        _oSQL:_sQuery += " AND CT2_HIST LIKE 'TRANSF ENTRE CONTAS FL " + _aFilial[_x,1] + "'"
        _oSQL:_sQuery += " GROUP BY CT2_FILIAL, CT2_HIST"
        u_log (_oSQL:_sQuery)
        _aCT201 := aclone (_oSQL:Qry2Array ()) 

        // Busca registro da filial
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT"
        _oSQL:_sQuery += " 	     CT2_FILIAL"
        _oSQL:_sQuery += "      ,CT2_HIST"
        _oSQL:_sQuery += "      ,SUM(CT2_VALOR) / 2"
        _oSQL:_sQuery += " FROM " + RetSQLName ("CT2") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
        _oSQL:_sQuery += " AND CT2_FILIAL = '" + _aFilial[_x,1] +"'"
        _oSQL:_sQuery += " AND CT2_DATA = '" + DTOS(_dDate) + "'"
        _oSQL:_sQuery += " AND CT2_HIST LIKE 'TRANSF ENTRE CONTAS FL " + _aFilial[_x,1] + "'"
        _oSQL:_sQuery += " GROUP BY CT2_FILIAL, CT2_HIST"
        u_log (_oSQL:_sQuery)
        _aCT2Fil := aclone (_oSQL:Qry2Array ()) 

        If Len(_aCT201) > 0
            _n01Vlr  := _aCT201[1,3]
        EndIf

        If Len(_aCT2Fil) > 0
            _nXXVlr  := _aCT2Fil[1,3]
        EndIf

        _nTot    := _n01Vlr + _nXXVlr // se totalizador zerado, não foi realizada nenhuma transferencia
        _nTotMat += _n01Vlr
        _nTotFil += _nXXVlr

        If _n01Vlr == _nXXVlr .and. (_nTot > 0)
            aadd(_aRetorno, { 'TRANSFERÊNCIA REALIZADA COM SUCESSO' ,; // status
                               _aFilial[_x,1] +"-"+ _aFilial[_x,2]  ,; // filial
                               _n01Vlr                              ,; // vlr matriz
                               _nXXVlr                              ,; // vlr filial
                               ''                                   ,;
                               ''                                   })
        Else
            If (_nTot > 0)
                aadd(_aRetorno, { 'ERRO NA TRANSFERÊNCIA'            ,; // status
                                _aFilial[_x,1] +"-"+ _aFilial[_x,2]  ,; // filial
                                _n01Vlr                              ,; // vlr matriz
                                _nXXVlr                              ,; // vlr filial
                                    ''                               ,;
                                    ''                                })                                

            EndIf
        EndIf

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT"
        _oSQL:_sQuery += " 	   CT2_HIST"
        _oSQL:_sQuery += "    ,CT2_FILIAL"
        _oSQL:_sQuery += "    ,CT2_DEBITO"
        _oSQL:_sQuery += "    ,CT2_CREDIT"
        _oSQL:_sQuery += "    ,CT2_VALOR"
        _oSQL:_sQuery += " FROM " + RetSQLName ("CT2") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND CT2_DATA = '" + DTOS(_dDate) + "'"
        _oSQL:_sQuery += " AND CT2_HIST LIKE 'TRANSF ENTRE CONTAS FL " + _aFilial[_x,1] + "'"
        u_log (_oSQL:_sQuery)
        // _oSQL:_sQuery += " ORDER BY CT2_HIST, CT2_FILIAL"
        _aRetErro := aclone (_oSQL:Qry2Array ())

        For _i := 1 to Len(_aRetErro) 
            aadd(_aRetorno, {   _aRetErro[_i, 1] ,; // historico
                                _aRetErro[_i, 2] ,; // filial
                                _aRetErro[_i, 5] ,; // valor
                                0                ,;
                                _aRetErro[_i, 3] ,; // conta debito
                                _aRetErro[_i, 4] }) // conta credito
                                
        Next
    Next

    If Len(_aRetorno) > 0 // tem sempre o cabeçalho

        aadd(_aRetorno, {   'TOTAL'     ,; 
                            ' '         ,; 
                            _nTotMat    ,;
                            _nTotFil    ,;
                            ' '         ,; 
                            ' '         })

        _sMsg := '<H1 align="center"></H1>'
       // _sMsg += '<H2 align="center">TRANSFERENCIA DE VALORES ENTRE FILIAIS</H1>' + chr (13) + chr (10)
		_sMsg += '<H3 align="center">DATA DE PROCESSAMENTO ' + dtoc (date ()) + ' DATA DE ENTRADA CTB ' + dtoc (_dDate) +'</H2>' + chr (13) + chr (10)

        For _x:=1 to Len(_aRetorno)
            _aCols = {}
            aadd(_aCols, {'STATUS/HISTÓRICO'    , "left"    ,  "@!"})
            aadd(_aCols, {'FILIAL'              , "left"    ,  "@!"})
            aadd(_aCols, {'VALOR MATRIZ'        , "right"   ,  "@E 999,999,999.99"})
            aadd(_aCols, {'VALOR FILIAL'        , "right"   ,  "@E 999,999,999.99"})
            aadd(_aCols, {'CONTA DEB.'          , "left"    ,  "@!"})
            aadd(_aCols, {'CONTA CRED.'         , "left"    ,  "@!"})
        Next
                            
        _oAUtil := ClsAUtil():New (_aRetorno)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .T.)
        _sDestin := 'claudia.lionco@novaalianca.coop.br;charlene.baldez@novaalianca.coop.br'
        //_sDestin := 'claudia.lionco@novaalianca.coop.br'

		U_SendMail (_sDestin, "Transferencias de valores entre filiais", _sMsg, {})
    EndIf

    // --------------------------------------------------------------------------------------------------------------------------------------
    // 

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT DISTINCT"
    _oSQL:_sQuery += " 	   CT2_HIST"
    _oSQL:_sQuery += "    ,CT2_FILIAL"
    _oSQL:_sQuery += "    ,CT2_DATA"
    _oSQL:_sQuery += "    ,CT2_VALOR"
    _oSQL:_sQuery += " FROM " + RetSQLName ("CT2") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    _oSQL:_sQuery += " AND CT2_DATA BETWEEN '" + DTOS(FirstDate(date ())) + "' AND '" + dtos(date()) + "'"
    _oSQL:_sQuery += " AND CT2_HIST LIKE 'TRANSF ENTRE CONTAS FL%'"
    _oSQL:_sQuery += " ORDER BY CT2_DATA DESC, CT2_VALOR, CT2_FILIAL"
    u_log (_oSQL:_sQuery)
    _aResumo := aclone (_oSQL:Qry2Array ())

    If Len(_aResumo) > 0 // tem sempre o cabeçalho
        _sMsg := '<H1 align="center"></H1>'
		_sMsg += '<H3 align="center">LANÇAMENTOS DE ' +  DTOC(FirstDate(date ()))+ ' ATE ' + dtoc(date())+'</H2>' + chr (13) + chr (10)

        _aCols = {}
        aadd(_aCols, {'HISTÓRICO'   , "left"    ,  "@!"})
        aadd(_aCols, {'FILIAL'      , "left"    ,  "@!"})
        aadd(_aCols, {'DATA'        , "right"   ,  "@!"})
        aadd(_aCols, {'VALOR'       , "right"   ,  "@E 999,999,999.99"})
                            
        _oAUtil := ClsAUtil():New (_aResumo)
		_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
        _sDestin := 'claudia.lionco@novaalianca.coop.br;charlene.baldez@novaalianca.coop.br'
        //_sDestin := 'claudia.lionco@novaalianca.coop.br'

		U_SendMail (_sDestin, "Transf.de valores entre filiais MENSAL", _sMsg, {})
    EndIf
    u_logFim ()
Return
