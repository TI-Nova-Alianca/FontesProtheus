//  Programa...: VA_ZAT
//  Autor......: Catia Cardoso
//  Data.......: 16/05/2016
//  Descricao..: Controle de Industrializações
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function VA_ZAT()

	local   _aCores   := U_LEG_CORES(.T.)
	private cCadastro := "Controle Industrializações"
	private aRotina   := {}
	private _aDados   := {}
	
    u_logId ()
    
    msgalert("Rotina ainda nao liberada.")
    return
	
	// Menu principal
	aadd (aRotina, {"&Inclui"                 , "U_ZAT_I()"   , 0,3})
	aadd (aRotina, {"&Visualizar"             , "AxVisual"    , 0,3})
	aadd (aRotina, {"&Componentes Fornecidos" , "U_ZAT_COMP()", 0,3})
	aadd (aRotina, {"&Altera"                 , "U_ZAT_A()"   , 0,3})
	aadd (aRotina, {"&Exclui"                 , "U_ZAT_E()"   , 0,3})
	
	aadd (aRotina, {"&Gera Ordem Compra"      , "U_ZAT_GOC()" , 0,3})
	aadd (aRotina, {"&Gera Pedido de Venda"   , "U_ZAT_GPV()" , 0,3})
	aadd (aRotina, {"&Gera Ordem de Produção" , "U_ZAT_GOP()" , 0,3})
	
	aadd (aRotina, {"&Consulta Notas Entrada" , "U_ZAT_CNE()" , 0,3})
    aadd (aRotina, {"&Consulta Notas Saidas"  , "U_ZAT_CNS()" , 0,3})
	aadd (aRotina, {"&Consulta OP's"          , "U_ZAT_OPS()" , 0,3})
	
	aadd (aRotina, {"&Extrato Operação"       , "U_ZAT_EXT()" , 0,3})
	aadd (aRotina, {"&Consulta Saldos"        , "U_ZAT_SLD()" , 0,3})
	
	aadd (aRotina, {"&Legenda"                , "U_LEG_CORES(.F.)", 0 ,3})
    
	dbselectarea ("ZAT")
    dbSetOrder (1)
    mBrowse(,,,,"ZAT",,,,,2, _aCores)
    
return

// -------------------------------------------------------------------------
// Inclusao
User Function ZAT_I ()
	private altera   := .F.
    private inclui   := .T.
    private aGets    := {}
    private aTela    := {}

    RegToMemory ("ZAT", inclui, inclui)
	axinclui ("ZAT", zat -> (recno ()), 3, NIL, NIL, NIL, NIL)
	
	if !EMPTY(ZAT-> ZAT_PROD)
		_AbreEstrutura('1')
	endif
return

// ---------
// Alteracao
// ---------
User Function ZAT_A()

	private altera   := .T.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
    u_logIni ()
    RegToMemory ("ZAT", inclui, .T.)
    
    if val(zat -> zat_nfes) > 0
       u_help ("Operação já esta vinculada a notas de entrada. Não permitida a alteração.")
       return      
    endif
    	
	if val(zat -> zat_nfs) > 0
       u_help ("Operação já esta vinculada a notas de saida. Não permitida a alteração.")
       return      
    endif
    
    if val(zat -> zat_ops) > 0
       u_help ("Operação já esta vinculada a ordens de produção. Não permitida a alteração.")
       return      
    endif
	
	// Apos a alteracao do registro, faz os tratamentos necessarios.
    axaltera ("ZAT", zat -> (recno ()), 4, NIL, NIL, NIL, NIL, NIL)
    
    if M->ZAT_PROD != ZAT -> ZAT_PROD
    	// se a criatura alterou o produto, limpa a tabela de componentes
    	_sSQL := ""
    	_sSQL += "  UPDATE ZAP010"
    	_sSQL += "     SET D_E_L_E_T_ = '*'"
 		_sSQL += "   WHERE D_E_L_E_T_ = ''"
   		_sSQL += "     AND ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   		_sSQL += "     AND ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    	
    	if TCSQLExec (_sSQL) < 0
    		U_help ("Erro não conseguiu excluir componentes enviados pelo cliente")
			return
       endif	
    endif
    
    if !EMPTY(ZAT -> ZAT_PROD)
		_AbreEstrutura('2')
	endif
    
return

// --------
// Exclusão
// --------
User Function ZAT_E()
    private altera   := .F.
    private inclui   := .F.
    private aGets    := {}
    private aTela    := {}
    
    RegToMemory ("ZAT", inclui, .T.)
    
    // so é permitido exclusao se ainda não ouve nenhuma movimentação
    
    if val(zat -> zat_nfes) > 0
       u_help ("Operação já esta vinculada a notas de entrada. Não eh permitida a exclusão.")
       return      
    endif
    	
	if val(zat -> zat_nfs) > 0
       u_help ("Operação já esta vinculada a notas de saida. Não eh permitida a exclusão.")
       return      
    endif
    
    if val(zat -> zat_ops) > 0
       u_help ("Operação já esta vinculada a ordens de produção. Não eh permitida a exclusão.")
       return      
    endif
	
	AxDeleta ("ZAT", zat -> (recno ()), 5)
	
	// delete tabela de componentes
	_sSQL := ""
    _sSQL += " SELECT ZAP.ZAP_ITEM, ZAP.ZAP_DESCR"
  	_sSQL += "   FROM ZAP010 AS ZAP"
 	_sSQL += "  WHERE ZAP.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAP.ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAP.ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0
    	_sSQL := ""
    	_sSQL += "  UPDATE ZAP010"
    	_sSQL += "     SET D_E_L_E_T_ = '*'"
 		_sSQL += "   WHERE D_E_L_E_T_ = ''"
   		_sSQL += "     AND ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   		_sSQL += "     AND ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    	
    	if TCSQLExec (_sSQL) < 0
    		U_help ("Erro não conseguiu excluir componentes enviados pelo cliente")
			return
       endif  
    endif
	
return

// ------------------------------------------------------------------------------------
Static Function _AbreEstrutura(_wopcao)
 	local i	:= 0
 	
    _sSQL := ""
    _sSQL += " SELECT '' AS MARCA" 
    _sSQL += "      , SG1.G1_COMP"
    _sSQL += "      , SB1.B1_DESC"
	_sSQL += "      , SB1.B1_TIPO"
	_sSQL += "      , SB1.B1_UM"
	_sSQL += "   FROM SG1010 AS SG1"
	_sSQL += "   	INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = SG1.G1_COMP"
	_sSQL += " 				AND SB1.B1_TIPO != 'BN'"
	_sSQL += " 				AND SB1.B1_TIPO != 'MO')"
 	_sSQL += "  WHERE SG1.D_E_L_E_T_ = ''"
   	_sSQL += "    AND SG1.G1_COD = '" + ZAT->ZAT_PROD + "'"
   	_sSQL += "    AND G1_INI <= '" + dtos (date ()) + "'"
   	_sSQL += "    AND G1_FIM >= '" + dtos (date ()) + "'"
    
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0 
	    _aColsMB = {}
		
		aadd (_aColsMB, {2,  "Componente" ,  50,  "@!"})
	    aadd (_aColsMB, {3,  "Descricao"  , 200,  "@!"})
	    aadd (_aColsMB, {4,  "Tipo"       ,  30,  "@!"})
	    aadd (_aColsMB, {5,  "UM"         ,  30,  "@!"})
	    
	    for i=1 to len(_aDados)
	    	// verifica se o item ja esta marcado
	    	DbSelectArea("ZAP")
	        DbSetOrder(2)
        	if DbSeek(xFilial("ZAT") + ZAT -> ZAT_NUMERO + _aDados[i,2] ,.F.)
        		_aDados[i,1] = .T.
			else
				_aDados[i,1] = .F.			        		
	    	endif
	    next
		
		U_MBArray (@_aDados,"Marque os componentes que serão FORNECIDOS PELO CLIENTE", _aColsMB, 1,  oMainWnd:nClientWidth - 50 ,550, ".T.")
		
		if _wopcao = '2'
			_sSQL := ""
    		_sSQL += "  UPDATE ZAP010"
    		_sSQL += "     SET D_E_L_E_T_ = '*'"
 			_sSQL += "   WHERE D_E_L_E_T_ = ''"
   			_sSQL += "     AND ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   			_sSQL += "     AND ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    	
    		if TCSQLExec (_sSQL) < 0
    			U_help ("Erro não conseguiu excluir componentes enviados pelo cliente")
				return
       		endif
		endif
		
		for i=1 to len(_aDados)
			// se o componente esta marcado grava na ZAP
			if _aDados[i,1] = .T.
				reclock("ZAP", .T.)
	        		ZAP -> ZAP_FILIAL = xFilial('ZAT')
	        		ZAP -> ZAP_CLIENT = ZAT -> ZAT_CLIENT 
	        		ZAP -> ZAP_NUMERO = ZAT -> ZAT_NUMERO
					ZAP -> ZAP_ITEM   = _aDados[i,2] 
					ZAP -> ZAP_DESCR  = _aDados[i,3]
        		MsUnLock()
			endif
		next
    endif
return     

// visualiza componentes fornecidos pelo cliente
user Function ZAT_COMP()
    
    _sSQL := ""
    _sSQL += " SELECT ZAP.ZAP_ITEM, ZAP.ZAP_DESCR"
    _sSQL += "      , SB1.B1_TIPO, SB1.B1_UM"
  	_sSQL += "   FROM ZAP010 AS ZAP"
	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = ZAP.ZAP_ITEM)"
 	_sSQL += "  WHERE ZAP.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAP.ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAP.ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0 
    	_aCols = {}
    	
    	aadd (_aCols, {1,  "Componente" ,  50,  "@!"})
	    aadd (_aCols, {2,  "Descricao"  , 200,  "@!"})
	    aadd (_aCols, {3,  "Tipo"       ,  30,  "@!"})
	    aadd (_aCols, {4,  "UM"         ,  30,  "@!"})
	    
	    U_F3Array (_aDados, "Componentes Fornecidos pelo Cliente", _aCols, oMainWnd:nClientWidth - 750, oMainWnd:nClientHeight -450 , "", "", .F., 'C' )
	else
		msgalert("Não há componentes fornecidos para esta operação.")	    
    endif
return     

// --------------------
// Gera Ordem de Compra
// --------------------
User Function ZAT_GOC()
	local i	:= 0
	
	_sSQL := ""
    _sSQL += " SELECT ZAP.ZAP_ITEM, ZAP.ZAP_DESCR"
    _sSQL += "      , SB1.B1_TIPO, SB1.B1_UM"
  	_sSQL += "   FROM ZAP010 AS ZAP"
	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = ZAP.ZAP_ITEM)"
 	_sSQL += "  WHERE ZAP.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAP.ZAP_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAP.ZAP_CLIENT = '" + ZAT->ZAT_CLIENT + "'"
    
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0
    	for i=1 to len(_aDados)
    		_wprod = _aDados[i,1]

			_aAutoSC7 = {}
			aadd (_aAutoSC7, {"C7_TIPO"   , '1'            , NIL})
			aadd (_aAutoSC7, {"C7_ITEM"   , '01'           , NIL})
			aadd (_aAutoSC7, {"C7_PRODUTO", _wprod         , NIL})
			aadd (_aAutoSC7, {"C7_QUANT"  , ZAT->ZAT_QUANT , NIL})
			aadd (_aAutoSC7, {"C7_PRECO"  , .1             , NIL})
			aadd (_aAutoSC7, {"C7_TOTAL"  , _wquant        , NIL})
		
			if len (_aAutoSC7) > 0
				lMsHelpAuto := .F. 
				lMsErroAuto := .F. 
				SC5 -> (dbsetorder (1))
				DbSelectArea("SC5")
				MATA410(_aAutoSC5,_aAutoSc6,3)
				If lMsErroAuto
					if ! empty (NomeAutoLog ())
						_sMsg = memoread (NomeAutoLog ())
						u_help (_sMsg)
						msgalert("Erro - LINHA 1")
					else
						u_help ("Nao foi possivel ler o log de erros.")
						msgalert("Erro - LINHA 2")
					endif
				else
					msgalert("gerou o pedido")
					u_log ('pedido gerado:', SC5 -> C5_NUM)
				endif
			endif			
		next			
	endif	
	
return

// -----------------------
// Gera Ordem Pedido Venda
// -----------------------
User Function ZAT_GPV()

	msgalert("Cliente")
	msgalert(ZAT-> ZAT_CLIENT)
		
	// busca dados do cliente para gerar o pedido
	_wtransp  = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_TRANSP")
	_wtpfrete = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_TPFRET")
	_wtabela  = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_TABELA")
	_wcond    = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_COND")
	_wbanco   = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_BCO1")
	_wvend    = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_VEND")
	_wtipocli = fBuscaCpo ('SA1', 1, xfilial('SA1') + ZAT-> ZAT_CLIENT + '01', "A1_TIPO")
	
	// Prepara campos do cabecalho do pedido
	_aAutoSC5 = {}
	aadd (_aAutoSC5, {"C5_CLIENTE", ZAT-> ZAT_CLIENT , NIL})
	aadd (_aAutoSC5, {"C5_LOJACLI", '01'             , NIL})
	aadd (_aAutoSC5, {"C5_TIPOCLI", _wtipocli        , NIL})
	aadd (_aAutoSC5, {"C5_TRANSP" , _wtransp         , NIL})
	aadd (_aAutoSC5, {"C5_TPFRETE", _wtpfrete        , NIL})
	aadd (_aAutoSC5, {"C5_TABELA" , _wtabela         , NIL})
	aadd (_aAutoSC5, {"C5_CONDPAG", _wcond           , NIL})
	aadd (_aAutoSC5, {"C5_TIPO"   , 'N'              , NIL})
	aadd (_aAutoSC5, {"C5_VAUSER" , cUserName        , NIL})
	aadd (_aAutoSC5, {"C5_BANCO"  , _wbanco          , NIL})
	aadd (_aAutoSC5, {"C5_VEND1"  , _wvend           , NIL})
	aadd (_aAutoSC5, {"C5_TPCARGA", '2'              , NIL})
	
	_aAutoSC6 = {}
	aadd (_aAutoSC6, {"C6_FILIAL" , '01'           , NIL})
	aadd (_aAutoSC6, {"C6_ITEM"   , '01'           , NIL})
	aadd (_aAutoSC6, {"C6_PRODUTO", ZAT->ZAT_PROD  , NIL})
	aadd (_aAutoSC6, {"C6_TES"    , ZAT->ZAT_TIND  , NIL})
	aadd (_aAutoSC6, {"C6_QTDVEN" , ZAT->ZAT_QUANT , NIL})
	aadd (_aAutoSC6, {"C6_ENTREG" , ZAT->ZAT_FIM   , NIL})
	aadd (_aAutoSC6, {"C6_PRCVEN" , ZAT->ZAT_PRECO , NIL})
	
	if len (_aAutoSC6) > 0
		lMsHelpAuto := .F. 
		lMsErroAuto := .F. 
		SC5 -> (dbsetorder (1))
		DbSelectArea("SC5")
		MATA410(_aAutoSC5,_aAutoSc6,3)
		If lMsErroAuto
			if ! empty (NomeAutoLog ())
				_sMsg = memoread (NomeAutoLog ())
				u_help (_sMsg)
				msgalert("Erro - LINHA 1")
			else
				u_help ("Nao foi possivel ler o log de erros.")
				msgalert("Erro - LINHA 2")
			endif
		else
			msgalert("gerou o pedido")
			u_log ('pedido gerado:', SC5 -> C5_NUM)
		endif
	endif
return

// --------------------
// Gera Ordem de Compra
// --------------------
User Function ZAT_GOP()
return

// -------------------------
// Consulta notas de entrada
// -------------------------
User Function ZAT_CNE()

	_sSQL := ""
    _sSQL += " SELECT ZAQ.ZAQ_DATA, ZAQ.ZAQ_ITEM"
    _sSQL += "      , SB1.B1_DESC, SB1.B1_TIPO, SB1.B1_UM"
    _sSQL += "      , ZAQ.ZAQ_QUANT, ZAQ.ZAQ_NFE, ZAQ.ZAQ_SERNFE"
  	_sSQL += "   FROM ZAQ010 AS ZAQ"
  	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = ZAQ.ZAQ_ITEM)"
 	_sSQL += "  WHERE ZAQ.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAQ.ZAQ_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAQ.ZAQ_TIPO   = 'NFE'"
	_sSQL += " ORDER BY ZAQ.ZAQ_DATA"
     
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0 
    	_aCols = {}
    	
    	aadd (_aCols, {1,  "Data"       ,  50,  "@D"})
	    aadd (_aCols, {2,  "Item"       ,  50,  "@!"})
	    aadd (_aCols, {3,  "Descrição"  , 150,  "@!"})
	    aadd (_aCols, {4,  "Tipo"       ,  30,  "@!"})
	    aadd (_aCols, {5,  "UM"         ,  30,  "@!"})
	    aadd (_aCols, {6,  "Quantidade" ,  70,  "@E 999,999.99"})
	    aadd (_aCols, {7,  "Documento"  ,  40,  "@!"})
	    aadd (_aCols, {8,  "Série"      ,  10,  "@!"})
	    
	    U_F3Array (_aDados, "Notas de Entrada referentes a esta operação", _aCols, oMainWnd:nClientWidth - 450, oMainWnd:nClientHeight -450 , "", "", .F., 'C' )
	else
		msgalert("Não há notas de entrada referentes a esta operação.")	    
    endif

return
// -----------------------
// Consulta notas de saida
// -----------------------
User Function ZAT_CNS()
	
	_sSQL := ""
    _sSQL += " SELECT ZAQ.ZAQ_DATA, ZAQ.ZAQ_ITEM"
    _sSQL += "      , SB1.B1_DESC, SB1.B1_TIPO, SB1.B1_UM"
    _sSQL += "      , ZAQ.ZAQ_QUANT, ZAQ.ZAQ_NFS, ZAQ.ZAQ_SERNFS"
  	_sSQL += "   FROM ZAQ010 AS ZAQ"
  	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = ZAQ.ZAQ_ITEM)"
 	_sSQL += "  WHERE ZAQ.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAQ.ZAQ_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAQ.ZAQ_TIPO   = 'NFS'"
	_sSQL += " ORDER BY ZAQ.ZAQ_DATA"
     
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0 
    	_aCols = {}
    	
    	aadd (_aCols, {1,  "Data"       ,  50,  "@D"})
	    aadd (_aCols, {2,  "Item"       ,  50,  "@!"})
	    aadd (_aCols, {3,  "Descrição"  , 150,  "@!"})
	    aadd (_aCols, {4,  "Tipo"       ,  30,  "@!"})
	    aadd (_aCols, {5,  "UM"         ,  30,  "@!"})
	    aadd (_aCols, {6,  "Quantidade" ,  70,  "@E 999,999.99"})
	    aadd (_aCols, {7,  "Documento"  ,  40,  "@!"})
	    aadd (_aCols, {8,  "Série"      ,  10,  "@!"})
	    
	    U_F3Array (_aDados, "Notas de Saida referentes a esta operação", _aCols, oMainWnd:nClientWidth - 450, oMainWnd:nClientHeight -450 , "", "", .F., 'C' )
	else
		msgalert("Não há notas de Saida referentes a esta operação.")	    
    endif
	
return

// -----------------------
// Consulta notas de saida
// -----------------------
User Function ZAT_OPS()

	_sSQL := ""
    _sSQL += " SELECT ZAQ.ZAQ_DATA, ZAQ.ZAQ_ITEM"
    _sSQL += "      , SB1.B1_DESC, SB1.B1_TIPO, SB1.B1_UM"
    _sSQL += "      , ZAQ.ZAQ_QUANT, ZAQ.ZAQ_OPS"
  	_sSQL += "   FROM ZAQ010 AS ZAQ"
  	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = ZAQ.ZAQ_ITEM)"
 	_sSQL += "  WHERE ZAQ.D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZAQ.ZAQ_NUMERO = '" + ZAT->ZAT_NUMERO + "'"
   	_sSQL += "    AND ZAQ.ZAQ_TIPO   = 'OPS'"
	_sSQL += " ORDER BY ZAQ.ZAQ_DATA"
     
    _aDados := U_Qry2Array(_sSQL)
    if len(_aDados) > 0 
    	_aCols = {}
    	
    	aadd (_aCols, {1,  "Data"       ,  50,  "@D"})
	    aadd (_aCols, {2,  "Item"       ,  50,  "@!"})
	    aadd (_aCols, {3,  "Descrição"  , 150,  "@!"})
	    aadd (_aCols, {4,  "Tipo"       ,  30,  "@!"})
	    aadd (_aCols, {5,  "UM"         ,  30,  "@!"})
	    aadd (_aCols, {6,  "Quantidade" ,  70,  "@E 999,999.99"})
	    aadd (_aCols, {7,  "Documento"  ,  40,  "@!"})
	    
	    U_F3Array (_aDados, "Ordens de Produção referentes a esta operação", _aCols, oMainWnd:nClientWidth - 450, oMainWnd:nClientHeight -450 , "", "", .F., 'C' )
	else
		msgalert("Não há Ordens de Produção referentes a esta operação.")	    
    endif
	
return

// ------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function LEG_CORES (_lRetCores)
	local _aCores   := {}
	local _aCores2  := {}
	local _i		:= 0
	
    aadd (_aCores, {"EMPTY(ZAT->ZAT_NFES) .AND. EMPTY(ZAT->ZAT_NFS) .AND. EMPTY(ZAT->ZAT_OPS)" , 'BR_VERMELHO', 'Pendente'})
    aadd (_aCores, {"ZAT->ZAT_NFES != ''  .OR. ZAT->ZAT_NFS != ''  .OR. ZAT->ZAT_OPS != ''" , 'BR_AMARELO' , 'Em Andamento'})
    aadd (_aCores, {"ZAT->ZAT_NFES != '' .AND. ZAT->ZAT_NFS != '' .AND. ZAT->ZAT_OPS != ''" , 'BR_VERDE'   , 'Finalizada'})
    
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return