// Programa...: ZC0
// Autor......: Cláudia Lionço
// Data.......: 20/05/2022
// Descricao..: Conta corrente Rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Conta corrente Rapel
// #PalavasChave      #rapel #conta_corrente 
// #TabelasPrincipais #ZC0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZC0()
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Conta corrente rapel"

    AADD(aRotina, {"&Visualizar"    , "AxVisual"      , 0, 1})
    AADD(aRotina, {"&Legenda"       , "U_ZC0LGD (.F.)", 0 ,5})

    AADD(_aCores,{ "ZC0_TM == '01'" , 'BR_AMARELO'   }) // Inclusão de saldo manual
    AADD(_aCores,{ "ZC0_TM == '02'" , 'BR_VERDE'     }) // Crédito
    AADD(_aCores,{ "ZC0_TM == '03'" , 'BR_VERMELHO'  }) // Débito

    dbSelectArea ("ZC0")
    dbSetOrder (1)
    mBrowse(,,,,"ZC0",,,,,,_aCores,,,,,,,,)

Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZC0LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
    aadd (aCores, {"ZC0->ZC0_TM == '01'" , 'BR_AMARELO' , 'Inclusão de saldo manual'	})
    aadd (aCores, {"ZC0->ZC0_TM == '02'" , 'BR_VERDE'   , 'Crédito'	})
    aadd (aCores, {"ZC0->ZC0_TM == '03'" , 'BR_VERMELHO', 'Débito'	})

	if ! _lRetCores
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 2], aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", aCores2)
	else
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 1], aCores [_i, 2]})
		next
		return aCores
	endif
return
// //
// // --------------------------------------------------------------------------
// // Grava registro no ZC0
// User Function ZC0GRV(_aZC0)
//     Local _x := 0

//     For _x:=1 to Len(_aZC0)
//         RecLock("ZC0", .T.)
//             ZC0 -> ZC0_FILIAL := _aZC0[_x, 1]  		// Filial
//             ZC0 -> ZC0_CODRED := _aZC0[_x, 2]  		// Cód.Rede/Base
//             ZC0 -> ZC0_LOJRED := _aZC0[_x, 3]  	    // Loja Rede/Base
//             ZC0 -> ZC0_CLIENT := _aZC0[_x, 4]  		// Cód.Cliente
//             ZC0 -> ZC0_LOJA   := _aZC0[_x, 5]   	// Loja cliente
//             ZC0 -> ZC0_DATA   := STOD(_aZC0[_x, 6]) // Data
//             ZC0 -> ZC0_TM     := _aZC0[_x, 7]  		// Tipo de Movimento
//             ZC0 -> ZC0_DESCTM := _aZC0[_x, 8]  		// Descrição movimento
//             ZC0 -> ZC0_DOC    := _aZC0[_x, 9]  		// Documento/NF 
//             ZC0 -> ZC0_SERIE  := _aZC0[_x,10]   	// Serie do documento
//             ZC0 -> ZC0_PARCEL := _aZC0[_x,11]       // Parcela   
//             ZC0 -> ZC0_VALOR  := _aZC0[_x,12]       // Valor
//             ZC0 -> ZC0_USER   := _aZC0[_x,13]  	    // Usuario
//             ZC0 -> ZC0_SEQ    := _aZC0[_x,14]       // Sequencia de movimento
//             ZC0 -> ZC0_STATUS := _aZC0[_x,15]       // Status F - registros fechados A - registros abertos
//         MsUnlock()
//     Next
// Return
// //
// // --------------------------------------------------------------------------
// // Retorna sequencia
// User Function ZC0SEQ(_sFilial, _sCliente, _sLoja, _sDoc, _sSerie, _sParcela)
//     Local _x    := 0
//     Local _nRet := 0

//     _oSQL := ClsSQL ():New ()
//     _oSQL:_sQuery := " SELECT TOP 1 "
//     _oSQL:_sQuery += " 	    ZC0_SEQ "
//     _oSQL:_sQuery += " FROM ZC0010 "
//     _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
//     _oSQL:_sQuery += " AND ZC0_FILIAL   = '" + _sFilial  + "' "
//     _oSQL:_sQuery += " AND ZC0_CLIENT   = '" + _sCliente + "' "
//     _oSQL:_sQuery += " AND ZC0_LOJA     = '" + _sLoja    + "' "
//     _oSQL:_sQuery += " AND ZC0_DOC      = '" + _sDoc     + "' "
//     _oSQL:_sQuery += " AND ZC0_SERIE    = '" + _sSerie   + "' "
//     _oSQL:_sQuery += " AND ZC0_PARCEL   = '" + _sParcela + "' "
//     _oSQL:_sQuery += " ORDER BY ZC0_SEQ DESC " 
//     _aDados := aclone(_oSQL:Qry2Array ())

//     If Len(_aDados) > 0
//         For _x:=1 to Len(_aDados)
//             _nRet += _aDados[_x,1] + 1
//         Next
//     else
//         _nRet := 1
//     EndIf
// Return _nRet


