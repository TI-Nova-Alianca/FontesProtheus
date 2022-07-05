//  Programa...: ZDOCONS
//  Autor......: Claudia Lionço
//  Data.......: 05/07/2022
//  Descricao..: Consulta Pagar.me x pedido x nota x titulos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Consulta Pagar.me x pedido x nota x titulos
// #PalavasChave      #e-commerce #pagar.me 
// #TabelasPrincipais #SC5 #SE1 #SF2
// #Modulos           #FAT
//
//  Historico de alterações
//
// ----------------------------------------------------------------------------------------------------------------
#include "protheus.ch"

User function ZD0CONS()

	cPerg   := "ZDOCONS"
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.)
		_oSQL := ClsSQL():New ()  
		_oSQL:_sQuery := "" 		
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	   SC5.C5_VAIDT AS ID_PAGARME "
		_oSQL:_sQuery += "    ,SC5.C5_FILIAL AS FILIAL "
		_oSQL:_sQuery += "    ,SC5.C5_NUM AS PEDIDO "
		_oSQL:_sQuery += "    ,SC5.C5_NOTA AS NOTA "
		_oSQL:_sQuery += "    ,SC5.C5_SERIE AS SERIE "
		_oSQL:_sQuery += "    ,SE1.E1_PARCELA AS PARCELA "
		_oSQL:_sQuery += "    ,SE1.E1_VALOR AS VALOR "
		_oSQL:_sQuery += "    ,SC5.C5_EMISSAO AS EMISSAO_PEDIDO "
		_oSQL:_sQuery += "    ,SF2.F2_EMISSAO AS EMISSAO_NOTA "
		_oSQL:_sQuery += "    ,SE1.E1_VENCTO AS VENCIMENTO "
		_oSQL:_sQuery += "    ,CASE "
		_oSQL:_sQuery += " 			WHEN SE1.E1_SALDO = 0 THEN 'BAIXADO' "
		_oSQL:_sQuery += " 			ELSE 'ABERTO' "
		_oSQL:_sQuery += " 		END SITUACAO "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SC5") + " SC5 "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " 		ON SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SF2.F2_FILIAL  = SC5.C5_FILIAL " 
		_oSQL:_sQuery += " 			AND SF2.F2_DOC     = SC5.C5_NOTA "
		_oSQL:_sQuery += " 			AND SF2.F2_SERIE   = SC5.C5_SERIE "
		_oSQL:_sQuery += " 			AND SF2.F2_CLIENTE = SC5.C5_CLIENTE "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SE1") + " SE1 "
		_oSQL:_sQuery += " 		ON SE1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SE1.E1_FILIAL  = SF2.F2_FILIAL "
		_oSQL:_sQuery += " 			AND SE1.E1_NUM     = SF2.F2_DOC "
		_oSQL:_sQuery += " 			AND SE1.E1_SERIE   = SF2.F2_SERIE "
		_oSQL:_sQuery += " 			AND SE1.E1_CLIENTE = SF2.F2_CLIENTE "
		_oSQL:_sQuery += " 			AND SE1.E1_LOJA    = SF2.F2_LOJA
		_oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND SC5.C5_VAIDT <> '' "
		_oSQL:_sQuery += " AND SC5.C5_VAIDT = '" + alltrim(str(mv_par01))+"' "
		_aDados := _oSQL:Qry2Array ()

    	if len(_aDados) > 0 

			_aCols = {}
			aadd (_aCols, {01, "ID Transação Pagar.me" ,  30,  "@E 999999999999"})
			aadd (_aCols, {02, "Filial"       	   	   ,  10,  "@!"})
			aadd (_aCols, {03, "Pedido"          	   ,  15,  "@!"})
			aadd (_aCols, {04, "Nota" 	     	   	   ,  20,  "@!"})
			aadd (_aCols, {05, "Série"             	   ,  10,  "@!"})
			aadd (_aCols, {06, "Parcela"        	   ,  10,  "@!"})
			aadd (_aCols, {07, "Valor"           	   ,  30,  "@E 999,999,999.99"})
			aadd (_aCols, {08, "Dt.Emissão Pedido"     ,  20,  "@D"})
			aadd (_aCols, {09, "Dt.Emissão Nota"       ,  20,  "@D"})
			aadd (_aCols, {10, "Vencimento Parcela"    ,  20,  "@D"})
			aadd (_aCols, {11, "Situação"       	   ,  30,  "@!"})

			U_F3Array (_aDados, "Consulta Pagar.me ", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 40 , "", "", .T., 'C' )
		else
			u_help ("Não foram encontrados dados para consulta")
		endif    		
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "ID trans.Pagar.me",               "N", 12, 0,  "",   "   ", {},                       "Id da transação"})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
