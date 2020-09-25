// Programa...: LJDEPSE1
// Autor......: Cláudia Lionço
// Data.......: 08/09/2020
// Descricao..: Ponto de Entrada acionado na finalização do Venda Assistida, 
//              após a gravação do título a receber na tabela SE1, 
//              possibilitando que sejam realizadas gravações complementares no titulo inserido.
//              O registro inserido fica posicionado para uso no Ponto de Entrada.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada após a gravação do título a receber (SE1), acionado na Finalização da Venda Assistida.
// #PalavasChave      #cielo #NSU #codigo_de_autorizacao #cartoes 
// #TabelasPrincipais #SE1 
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function LJDEPSE1()
    // //Local aParcelas := PARAMIXB[1]
    // Local _codNSU   := "        "
    // Local _codAut   := "      " 
    // Local aButtons  := {}
    // Local oGet1
    // Local oGet2
    // Local oSay1
    // Local oSay2
    // Local oSay3
    // Local oSay4
    // Local oSay5
    // Local oSay6
    // Local oSay7
    // Local oSay8
    // Local oSay9
    // Local oSay10
    // Local oSay11
    // Local oSay12
    // Local oSay13
    // Local oSay14
    // Local oSay15
    // Static oDlg

    // //Regra Customizada - Grava NSU e codiso de autorização nos titulos                  
    // If (alltrim(se1->e1_tipo) == 'CC' .or. alltrim(se1->e1_tipo) == 'CD')

    //     // Busca valor total
    //     _oSQL:= ClsSQL ():New ()
    //     _oSQL:_sQuery := ""
    //     _oSQL:_sQuery += " SELECT "
    //     _oSQL:_sQuery += "    L1_VLRTOT "
    //     _oSQL:_sQuery += " FROM " + RetSQLName ("SL1") 
    //     _oSQL:_sQuery += " WHERE L1_FILIAL = '" + se1 -> e1_filial   + "'"
    //     _oSQL:_sQuery += " AND L1_DOC    = '" + se1 -> e1_num      + "'"
    //     _oSQL:_sQuery += " AND L1_SERIE  = '" + se1 -> e1_prefixo  + "'"
    //     _oSQL:Log ()
    //     _aToTal := aclone (_oSQL:Qry2Array ())

    //     If Len(_aToTal) > 0
    //         _vlrTotal := _aToTal[1,1]
    //     Else
    //         _vlrTotal := 0
    //     EndIf

    //     // Busca NSU e Cod.Autorixação da primeira parcela, para deixar pronto em tela
    //     _oSQL:= ClsSQL ():New ()
    //     _oSQL:_sQuery := ""
    //     _oSQL:_sQuery += " SELECT  E1_NSUTEF, E1_CARTAUT " 
    //     _oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
    //     _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
    //     _oSQL:_sQuery += " AND E1_FILIAL    = '" + se1 -> e1_filial   + "'"
    //     _oSQL:_sQuery += " AND E1_NUM       = '" + se1 -> e1_num      + "'"
    //     _oSQL:_sQuery += " AND E1_PREFIXO   = '" + se1 -> e1_prefixo  + "'"
    //     _oSQL:_sQuery += " AND E1_PARCELA   = 'A'"
    //     _oSQL:_sQuery += " AND E1_CLIENTE   = '" + se1 -> e1_cliente  + "'"
    //     _oSQL:_sQuery += " AND E1_LOJA      = '" + se1 -> e1_loja     + "'"
    //     _oSQL:Log ()
    //     _aDados := aclone (_oSQL:Qry2Array ())

    //     If Len(_aDados) > 0
    //         _codNSU   := Substr(_aDados[1,1],1,8)
    //         _codAUT   := _aDados[1,2]
    //     EndIf

    //     _prefixo  := SE1->E1_PREFIXO
    //     _titulo   := SE1->E1_NUM
    //     _parcela  := SE1->E1_PARCELA
    //     _cartTipo := SE1->E1_TIPO
    //     _cartDesc := SE1->E1_NOMCLI
    //     _vlrParc  := SE1->E1_VALOR
            
    //     // Tela de gravação NSU e Cod.Autorização
    //     DEFINE MSDIALOG oDlg TITLE "Dados do cartão" FROM 000, 000  TO 270, 450 COLORS 0, 16777215 PIXEL

    //     @ 045, 080 SAY oSay2 PROMPT "Prefixo:" SIZE 020, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 060, 010 SAY oSay3 PROMPT "Cartão" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 045, 010 SAY oSay4 PROMPT "Título:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 045, 032 SAY oSay5 PROMPT _titulo SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 045, 100 SAY oSay6 PROMPT _prefixo SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 060, 035 SAY oSay7 PROMPT _cartTipo SIZE 020, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 096, 009 SAY oSay8 PROMPT "NSU" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 096, 102 SAY oSay9 PROMPT "Código Autorização" SIZE 051, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 096, 037 MSGET oGet1 VAR _codNSU SIZE 050, 010 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 096, 157 MSGET oGet2 VAR _codAUT SIZE 050, 010 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 060, 055 SAY oSay1 PROMPT _cartDesc SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 075, 010 SAY oSay10 PROMPT "Valor Parcela:" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 075, 045 SAY oSay11 PROMPT _vlrParc SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 075, 107 SAY oSay12 PROMPT "Valor Total:" SIZE 030, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 075, 137 SAY oSay13 PROMPT _vlrTotal SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 045, 130 SAY oSay14 PROMPT "Parcela:" SIZE 022, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     @ 045, 152 SAY oSay15 PROMPT _parcela SIZE 015, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //     ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg, {||_GravaDados(oDlg, _codNSU, _codAUT),{||oDlg:End()}}, {|| oDlg:End ()},,aButtons))
    // EndIf
Return
// //
// // --------------------------------------------------------------------------
// // Grava NSU e codigo de autorização na primeira parcela
// Static Function _GravaDados(oDlg, sNSU, sAUT, lParc)

//     If (alltrim(se1->e1_parcela) == '' .or. alltrim(se1->e1_parcela) == 'A') // grava em todas o NSU e Cod Aut da primeira parcela
//         _oSQL:= ClsSQL ():New ()
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " UPDATE " + RetSQLName ("SE1")
//         _oSQL:_sQuery += " SET E1_NSUTEF = '"+ sNSU +"'
//         _oSQL:_sQuery += "   ,E1_CARTAUT = '"+ sAUT +"'
//         _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//         _oSQL:_sQuery += " AND E1_FILIAL    = '" + se1 -> e1_filial   + "'"
//         _oSQL:_sQuery += " AND E1_NUM       = '" + se1 -> e1_num      + "'"
//         _oSQL:_sQuery += " AND E1_PREFIXO   = '" + se1 -> e1_prefixo  + "'"
//         _oSQL:_sQuery += " AND E1_CLIENTE   = '" + se1 -> e1_cliente  + "'"
//         _oSQL:_sQuery += " AND E1_LOJA      = '" + se1 -> e1_loja     + "'"
//         _oSQL:Log ()
//         _oSQL:Exec ()
//     Else                                        // Grava individualmente as proximas parcelas
//         _oSQL:= ClsSQL ():New ()
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " UPDATE " + RetSQLName ("SE1")
//         _oSQL:_sQuery += " SET E1_NSUTEF = '"+ sNSU +"'
//         _oSQL:_sQuery += "    ,E1_CARTAUT = '"+ sAUT +"'
//         _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//         _oSQL:_sQuery += " AND E1_FILIAL    = '" + se1 -> e1_filial   + "'"
//         _oSQL:_sQuery += " AND E1_NUM       = '" + se1 -> e1_num      + "'"
//         _oSQL:_sQuery += " AND E1_PREFIXO   = '" + se1 -> e1_prefixo  + "'"
//         _oSQL:_sQuery += " AND E1_PARCELA   = '" + se1 -> e1_parcela  + "'"
//         _oSQL:_sQuery += " AND E1_CLIENTE   = '" + se1 -> e1_cliente  + "'"
//         _oSQL:_sQuery += " AND E1_LOJA      = '" + se1 -> e1_loja     + "'"
//         _oSQL:Log ()
//         _oSQL:Exec ()
//     EndIf

//     oDlg:End()

// Return
