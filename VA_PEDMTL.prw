// Programa.: VA_PEDMTL
// Autor....: Cláudia Lionço
// Data.....: 21/12/2023
// Descricao: Tela de formação da margem de contribuicao no pedido de venda.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #tela
// #Descricao         #Tela de formação da margem de contribuicao no pedido de venda.
// #PalavasChave      #margem #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_PEDMTL(_sFilial, _sPedido, _sCliente, _sLoja)
	local _oDlg         := NIL
	local _oCour24      := TFont():New("Courier New",,24,,.T.,,,,,.F.)
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private _aHeader    := {}
	private _aCols      := {}

	aHeader   := aclone(U_GeraHead ("ZZZ", .T., {}, {"ZZZ_15PROD","ZZZ_15DESC","ZZZ_15QTD","ZZZ_15PRC","ZZZ_15VVEN","ZZZ_15VCUS","ZZZ_15PCUS","ZZZ_15VCOM","ZZZ_15PCOM","ZZZ_15VICM","ZZZ_15PICM","ZZZ_15VPC","ZZZ_15PPC","ZZZ_15VRAP","ZZZ_15PRAP","ZZZ_15VFRE","ZZZ_15PFRE","ZZZ_15VFIN","ZZZ_15PFIN","ZZZ_15VMAR","ZZZ_15PMAR"}, .T.))
    _aSize     := MsAdvSize()	
    	// Define tamanho da tela.
    _aHead1 := aclone(aHeader)
	_aCols1 := _MontaColunas(_sFilial, _sCliente,_sLoja,_sPedido)

	define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Produtos"

    //                        Linha                         Coluna                      bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                          altura
    _oTxtBrw1 := tSay ():New (15,                           7,                          NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth / 2 - 90,  25)
    _oGetD1 := MsNewGetDados ():New (   40, ;                				// Limite superior
		                                5, ;                     			// Limite esquerdo
		                                _oDlg:nClientHeight / 2 - 28, ;     // Limite inferior
		                                _oDlg:nClientWidth / 2 - 10, ;      // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
		                                , ; 						// [ nStyle ]
		                                	, ;  							// Linha OK
		                                "AllwaysTrue ()", ;  				// [ uTudoOk ]
		                                NIL, ; 								// [cIniCpos]
		                                NIL,; 								// [ aAlter ]
		                                NIL,; 								// [ nFreeze ]
		                                99,; 								// [ nMax ]
		                                NIL,; 								// [ cFieldOk ]
		                                NIL,;					 			// [ uSuperDel ]
		                                NIL,; 								// [ uDelOk ]
		                                _oDlg,; 							// [ oWnd ]
		                                _aHead1,; 							// [ ParHeader ]
		                                _aCols1) 							// [ aParCols ]
    
     // Define botoes para a barra de ferramentas
    
    //_bBotaoOK  = {|| processa ({||_GeraSimul ()}), _oDlg:End ()}
    _bBotaoOK  = {|| _oDlg:End ()}
	_bBotaoCan = {|| _oDlg:End ()}
    
    activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")

Return

Static Function _MontaColunas(_sFilial, _sCliente,_sLoja,_sPedido)
    Local _aDados := {}
    Local _x      := 0


    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     ZC1_PROD "
    _oSQL:_sQuery += "    ,B1_DESC "
    _oSQL:_sQuery += "    ,ZC1_QTD "
    _oSQL:_sQuery += "    ,ZC1_PRC "
    _oSQL:_sQuery += "    ,ZC1_VVEN "
    _oSQL:_sQuery += "    ,ZC1_VCUS "
    _oSQL:_sQuery += "    ,ZC1_PCUS "
    _oSQL:_sQuery += "    ,ZC1_VCOM "
    _oSQL:_sQuery += "    ,ZC1_PCOM "
    _oSQL:_sQuery += "    ,ZC1_VICMS "
    _oSQL:_sQuery += "    ,ZC1_PICMS "
    _oSQL:_sQuery += "    ,ZC1_VPC "
    _oSQL:_sQuery += "    ,ZC1_PPC "
    _oSQL:_sQuery += "    ,ZC1_VRAP "
    _oSQL:_sQuery += "    ,ZC1_PRAP "
    _oSQL:_sQuery += "    ,ZC1_VFRE "
    _oSQL:_sQuery += "    ,ZC1_PFRE "
    _oSQL:_sQuery += "    ,ZC1_VFIN "
    _oSQL:_sQuery += "    ,ZC1_PFIN "
    _oSQL:_sQuery += "    ,ZC1_VMAR "
    _oSQL:_sQuery += "    ,ZC1_PMAR "
    _oSQL:_sQuery += "    ,MAX(ZC1_SEQ) AS SEQ "
    _oSQL:_sQuery += " 	  ,ZC1_ITEM "
    _oSQL:_sQuery += " FROM ZC1010 ZC1 "
    _oSQL:_sQuery += " LEFT JOIN SB1010 SB1 "
    _oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND B1_COD = ZC1_PROD "
    _oSQL:_sQuery += " WHERE ZC1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZC1_FILIAL = '"+ _sFilial  +"' "
    _oSQL:_sQuery += " AND ZC1_CLI    = '"+ _sCliente +"' "
    _oSQL:_sQuery += " AND ZC1_LOJA   = '"+ _sLoja    +"' "
    _oSQL:_sQuery += " AND ZC1_PED    = '"+ _sPedido  +"' "
    _oSQL:_sQuery += " AND ZC1_SEQ = (SELECT
	_oSQL:_sQuery += " 				        MAX(ZC1_2.ZC1_SEQ)
	_oSQL:_sQuery += " 			        FROM ZC1010 ZC1_2
	_oSQL:_sQuery += " 			        WHERE ZC1_2.D_E_L_E_T_ = ''
	_oSQL:_sQuery += " 			        AND ZC1_2.ZC1_FILIAL   = '"+ _sFilial  +"' "
	_oSQL:_sQuery += " 			        AND ZC1_2.ZC1_PED      = '"+ _sPedido  +"' "
	_oSQL:_sQuery += " 			        AND ZC1_2.ZC1_CLI      = '"+ _sCliente +"' "
    _oSQL:_sQuery += "                  AND ZC1_2.ZC1_LOJA     = '"+ _sLoja    +"' "
    _oSQL:_sQuery += "                ) "
    _oSQL:_sQuery += " GROUP BY ZC1_ITEM "
    _oSQL:_sQuery += " 		,ZC1_PROD "
    _oSQL:_sQuery += " 		,B1_DESC "
    _oSQL:_sQuery += " 		,ZC1_QTD "
    _oSQL:_sQuery += " 		,ZC1_PRC "
    _oSQL:_sQuery += " 		,ZC1_VVEN "
    _oSQL:_sQuery += " 		,ZC1_VCUS "
    _oSQL:_sQuery += " 		,ZC1_PCUS "
    _oSQL:_sQuery += " 		,ZC1_VCOM "
    _oSQL:_sQuery += " 		,ZC1_PCOM "
    _oSQL:_sQuery += " 		,ZC1_VICMS "
    _oSQL:_sQuery += " 		,ZC1_PICMS "
    _oSQL:_sQuery += " 		,ZC1_VPC "
    _oSQL:_sQuery += " 		,ZC1_PPC "
    _oSQL:_sQuery += " 		,ZC1_VRAP "
    _oSQL:_sQuery += " 		,ZC1_PRAP "
    _oSQL:_sQuery += " 		,ZC1_VFRE "
    _oSQL:_sQuery += " 		,ZC1_PFRE "
    _oSQL:_sQuery += " 		,ZC1_VFIN "
    _oSQL:_sQuery += " 		,ZC1_PFIN "
    _oSQL:_sQuery += " 		,ZC1_VMAR "
    _oSQL:_sQuery += " 		,ZC1_PMAR "
    _aCols := aclone(_oSQL:Qry2Array())


    For _x :=1 to Len(_aCols)
        aAdd(_aDados,   {   _aCols[_x, 1] ,;
                            _aCols[_x, 2] ,;
                            _aCols[_x, 3] ,;
                            _aCols[_x, 4] ,;
                            _aCols[_x, 5] ,;
                            _aCols[_x, 6] ,;
                            _aCols[_x, 7] ,;
                            _aCols[_x, 8] ,;
                            _aCols[_x, 9] ,;
                            _aCols[_x,10] ,;
                            _aCols[_x,11] ,;
                            _aCols[_x,12] ,;
                            _aCols[_x,13] ,;
                            _aCols[_x,14] ,;
                            _aCols[_x,15] ,;
                            _aCols[_x,16] ,;
                            _aCols[_x,17] ,;
                            _aCols[_x,18] ,;
                            _aCols[_x,19] ,;
                            _aCols[_x,20] ,;
                            _aCols[_x,21] ,;
                                        .F.;
                        })
    Next

Return _aDados
