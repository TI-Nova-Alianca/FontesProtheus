// Programa..: ML_LVDA.PRX
// Autor.....: Ricardo
// Data......: 9:39pm Abr 20,1999
// Nota......: ExecBlock Lancto Padrao Vendas
//
// Historico de alteracoes:
// 16/06/2008 - Robert - Passa a validar o parametro VA_SERIECF
// 29/07/2009 - Robert - Passa a somar d2_icmsret no valor retornado
// 18/03/2010 - Robert - TES 603 (venda sucata) retorna valor zerado.
//

#include "rwmake.ch"

User Function Ml_lvda()

SetPrvt("_WVAL,")

IF  SF4->F4_DUPLIC<>"S" .OR. SD2->D2_TIPO=="D" .OR. SD2->D2_TES$"518/510/603" .OR. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .OR.;
	SF4->F4_TOCON$('15/16')
    _wVAL:=0
ELSE
//   _wVAL:=SD2->D2_TOTAL+SD2->D2_VALIPI
   _wVAL:=SD2->D2_TOTAL+SD2->D2_VALIPI+sd2->d2_icmsret
ENDIF
Return(_wVAL)



// // Programa..: ML_LVDA.PRX
// // Autor.....: Ricardo
// // Data......: 20/04/1999 
// // Nota......: ExecBlock Lancto Padrao Vendas
// //
// // #TipoDePrograma    #processamento
// // #Descricao         #ExecBlock Lancto Padrao Vendas
// // #PalavasChave      #LPAD #lancamento_padrao 
// // #TabelasPrincipais #SD2 #SF4
// // #Modulos 		  #CTB 
// //
// // Parametros: _nEcomm
// // 1 - Retorna valor 0 para notas e-commerce
// // 2 - Retorna valor para notas e-commerce
// // 3 - Retorna conta contabil por bandeira
// // 4 - Retorna valor credito
// //
// // Historico de alteracoes:
// // 16/06/2008 - Robert  - Passa a validar o parametro VA_SERIECF
// // 29/07/2009 - Robert  - Passa a somar d2_icmsret no valor retornado
// // 18/03/2010 - Robert  - TES 603 (venda sucata) retorna valor zerado.
// // 05/11/2020 - Claudia - Incluida validações para notas do e-commerce 
// //
// // -------------------------------------------------------------------------------------
// #include "rwmake.ch"

// User Function ML_LVDA(_nEcomm)
//     Local _aDados := {}
//     Local _lEcomm := .F.
//     Local _sADM   := ""
//     Local _oSQL   := ClsSQL ():New ()

//     SetPrvt("_WVAL,")

//     // Verifica se é nota do ecommerce
//     If SD2->D2_FILIAL == '01' .or. SD2->D2_FILIAL == '16'
//         _oSQL:_sQuery := ""
//         _oSQL:_sQuery += " SELECT DISTINCT E1_ADM "
//         _oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
//         _oSQL:_sQuery += " WHERE E1_FILIAL = '" + SD2->D2_FILIAL + "'"
//         _oSQL:_sQuery += " AND E1_NUM      = '" + SD2->D2_DOC    + "'"
//         _oSQL:_sQuery += " AND E1_PREFIXO  = '"+ SD2->D2_SERIE   + "'"
//         _oSQL:_sQuery += " AND E1_TIPO IN('CC','CD') "
//         _oSQL:_sQuery += " AND E1_ADM <> ''"

//         _aDados := _oSQL:Qry2Array ()

//         If Len(_aDados) > 0
//             _lEcomm := .T.
//             _sADM   := _aDados[1,1]
//         EndIf
//     EndIf

//     If _lEcomm == .F. .and. (_nEcomm == '1' .or. _nEcomm == '4')// se nao for nota e-commerce
//         If  SF4->F4_DUPLIC<>"S" .or. SD2->D2_TIPO=="D" .or. SD2->D2_TES$"518/510/603" .or. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .or. SF4->F4_TOCON$('15/16')
//             _wVAL := 0
//         Else
//             _wVAL := SD2->D2_TOTAL+SD2->D2_VALIPI+sd2->d2_icmsret
//         EndIf
//     Else
//         If _nEcomm == '1' .and. _lEcomm == .T. // Nota ecommerce que retorna zero
//             _wVAL := 0
//         EndIf
//         If _nEcomm == '2' .and. _lEcomm == .T. // Nota ecommerce que retorna valor
//             _wVAL := SD2->D2_TOTAL+SD2->D2_VALIPI+sd2->d2_icmsret
//         EndIf
//         If _nEcomm == '3' .and. _lEcomm == .T. // Retorna conta contabil
//             Do Case
//                 Case _sADM == "100" .or. _sADM == "101"
//                     _wVAL:= "101021101002"
//                 Case _sADM == "200" .or. _sADM == "201"
//                     _wVAL:= "101021101001"
//                 Case _sADM == "300" .or. _sADM == "301"
//                     _wVAL:= "101021101003"
//                 Case _sADM == "400" .or. _sADM == "401"
//                     _wVAL:= "101021101004"
//                 otherwise
//                     _wVAL:= "101021101005"
//             EndCase  
//         EndIf
//     EndIf
  
// Return(_wVAL)
