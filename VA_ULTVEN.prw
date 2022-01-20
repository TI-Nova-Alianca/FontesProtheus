// Programa...: VA_ULTVEN
// Autor......: Claudia Lionço
// Data.......: 12/01/2022
// Descricao..: Busca ultima venda do pedido de venda selecionado
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Busca ultima venda do pedido de venda selecionado
// #PalavasChave      #pedido_de_venda #ultima_venda 
// #TabelasPrincipais #SC5 #SC6
// #Modulos   		  #FAT
//
// Historico de alteracoes:
// 20/01/2022 - Claudia - Incluida a data de emissão da nota e retirada a dt.emissao 
//                        do pedido. GLPI:11499
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function VA_ULTVEN(_sFilial, _sPedido, _sCliente, _sLoja)
    Local _aCols  := {}
    Local _aItens := {}
    Local _aDados := {} 
    Local _aProd  := {}
    Local _x      := 0
    Local _i      := 0

    _oSQL   := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	    SC6.C6_PRODUTO " "
    _oSQL:_sQuery += " FROM SC5010 SC5
    _oSQL:_sQuery += " INNER JOIN SC6010 SC6 "
    _oSQL:_sQuery += " 	ON SC6.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SC6.C6_FILIAL = SC5.C5_FILIAL "
    _oSQL:_sQuery += " 		AND SC6.C6_NUM = SC5.C5_NUM "
    _oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SC5.C5_FILIAL  = '"+ _sFilial +"'"
    _oSQL:_sQuery += " AND SC5.C5_NUM     = '"+ _sPedido +"'"
    _oSQL:_sQuery += " AND SC5.C5_CLIENTE = '"+ _sCliente+"'"
    _oSQL:_sQuery += " AND SC5.C5_LOJACLI = '"+ _sLoja   +"'"

    u_log (_oSQL:_squery)
    _aItens := aclone (_oSQL:Qry2Array ())

    For _x:=1 to Len(_aItens)

        _oSQL:= ClsSQL():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT TOP 1"
        _oSQL:_sQuery += " 	   SC5.C5_FILIAL AS FILIAL"
        _oSQL:_sQuery += "    ,SC5.C5_NUM AS NUMERO"
        _oSQL:_sQuery += "    ,SC5.C5_CLIENTE AS CLIENTE"
        _oSQL:_sQuery += "    ,SC5.C5_LOJACLI AS LOJA_CLIENTE"
        _oSQL:_sQuery += "    ,SA1.A1_NOME AS NOME"
        _oSQL:_sQuery += "    ,SC6.C6_PRODUTO AS PRODUTO "
        _oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO "
        _oSQL:_sQuery += "    ,SC6.C6_NOTA AS NOTA "
        _oSQL:_sQuery += "    ,SC6.C6_SERIE AS SERIE "
        _oSQL:_sQuery += "    ,SF2.F2_EMISSAO AS EMISSAO "
        _oSQL:_sQuery += "    ,SC6.C6_QTDVEN AS QTD_VENDIDA "
        _oSQL:_sQuery += "    ,SC6.C6_PRCVEN AS PRECO_VENDA "
        _oSQL:_sQuery += "    ,SC6.C6_PRUNIT AS PRECO_UNITARIO "
        _oSQL:_sQuery += "    ,SC6.C6_VALOR AS VALOR "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SC5") + " SC5 "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC6") + " SC6 "
        _oSQL:_sQuery += " 	ON SC6.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SC6.C6_FILIAL  = SC5.C5_FILIAL "
        _oSQL:_sQuery += " 		AND SC6.C6_NUM     = SC5.C5_NUM "
        _oSQL:_sQuery += "      AND SC6.C6_PRODUTO = '" + _aItens[_x, 1] + "' "
        _oSQL:_sQuery += "      AND SC6.C6_NOTA <> '' "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
        _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SA1.A1_COD  = SC5.C5_CLIENTE "
        _oSQL:_sQuery += " 		AND SA1.A1_LOJA = SC5.C5_LOJACLI "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SB1.B1_COD  = SC6.C6_PRODUTO "
        _oSQL:_sQuery += "     INNER JOIN " + RetSQLName ("SF2") + " SF2 "
        _oSQL:_sQuery += " 	ON SF2.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SF2.F2_FILIAL = SC6.C6_FILIAL "
        _oSQL:_sQuery += " 		AND SF2.F2_DOC    = SC6.C6_NOTA "
        _oSQL:_sQuery += " 		AND SF2.F2_SERIE  = SC6.C6_SERIE "
        _oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND C5_FILIAL  = '" + _sFilial  + "' "
        _oSQL:_sQuery += " AND C5_NUM    <> '" + _sPedido  + "' "
        _oSQL:_sQuery += " AND C5_CLIENTE = '" + _sCliente + "' "
        _oSQL:_sQuery += " AND C5_LOJACLI = '" + _sLoja    + "' "
        _oSQL:_sQuery += " ORDER BY SC5.R_E_C_N_O_ DESC "
        u_log (_oSQL:_squery)
        _aProd := aclone (_oSQL:Qry2Array ())

        For _i:=1 to Len(_aProd)
            aadd(_aDados,{  _aProd[_i, 1]       ,; 
                            _aProd[_i, 2]       ,;
                            _aProd[_i, 3]       ,;
                            _aProd[_i, 4]       ,;
                            _aProd[_i, 5]       ,;
                            _aProd[_i, 6]       ,;
                            _aProd[_i, 7]       ,;
                            _aProd[_i, 8]       ,;
                            _aProd[_i, 9]       ,;
                            stod(_aProd[_i,10]) ,;
                            _aProd[_i,11]       ,;
                            _aProd[_i,12]       ,;
                            _aProd[_i,13]       ,;
                            _aProd[_i,14]       })
        Next
    Next
            
    aadd (_aCols, {01, "FIlial"  	   	,  10,  "@!"})
    aadd (_aCols, {02, "Pedido"       	,  20,  "@!"})
    aadd (_aCols, {03, "Cliente"        ,  10,  "@!"})
    aadd (_aCols, {04, "Loja" 	     	,  10,  "@!"})
    aadd (_aCols, {05, "Nome"           ,  40,  "@D"})
    aadd (_aCols, {06, "Produto"        ,  30,  "@!"})
    aadd (_aCols, {07, "Descrição"      ,  40,  "@!"})
    aadd (_aCols, {08, "Nota"          	,  20,  "@!"})
    aadd (_aCols, {09, "Serie"          ,  20,  "@!"})
    aadd (_aCols, {10, "Emissao NF "    ,  20,  "@!"})
    aadd (_aCols, {11, "Qnt.Vendida"   	,  30,  "@E 9,999,999.99"})
    aadd (_aCols, {12, "Preço de Venda" ,  30,  "@E 9,999,999.99"})
    aadd (_aCols, {13, "Preço Unitario" ,  30,  "@E 9,999,999.99"})
    aadd (_aCols, {14, "Valor"       	,  30,  "@E 9,999,999.99"})
    
    U_F3Array (_aDados, "Consulta última venda", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 40 , "", "", .T., 'C' )

Return
