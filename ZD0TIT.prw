//  Programa...: ZDOTIT
//  Autor......: Claudia Lionço
//  Data.......: 18/07/2023
//  Descricao..: Consulta títulos pagar.me
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

User function ZD0TIT(_sFilial, _sTrans, _sParcela)

	cPerg   := "ZD0TIT"

		_oSQL := ClsSQL():New ()  
		_oSQL:_sQuery := "" 		
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   E1_FILIAL "
        _oSQL:_sQuery += "    ,E1_PREFIXO "
        _oSQL:_sQuery += "    ,E1_NUM "
        _oSQL:_sQuery += "    ,E1_PARCELA "
        _oSQL:_sQuery += "    ,E1_CLIENTE "
        _oSQL:_sQuery += "    ,E1_LOJA "
        _oSQL:_sQuery += "    ,E1_NOMCLI "
        _oSQL:_sQuery += "    ,E1_TIPO "
        _oSQL:_sQuery += "    ,E1_EMISSAO "
        _oSQL:_sQuery += "    ,E1_VENCTO "
        _oSQL:_sQuery += "    ,E1_VALOR "
        _oSQL:_sQuery += "    ,E1_SALDO "
        _oSQL:_sQuery += "    ,E1_BAIXA "
        _oSQL:_sQuery += "    ,E1_VAIDT "
        _oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND E1_FILIAL    = '"+ _sFilial  +"' "
        _oSQL:_sQuery += " AND E1_VAIDT     = '"+ _sTrans   +"' "
        _oSQL:_sQuery += " AND E1_PARCELA   = '"+ _sParcela +"' "

		_aDados := _oSQL:Qry2Array ()

    	if len(_aDados) > 0 

			_aCols = {}
			aadd (_aCols, {01, "Filial"      ,  10,  "@!"})
            aadd (_aCols, {02, "Prefixo"     ,  10,  "@!"})
			aadd (_aCols, {03, "Número"      ,  10,  "@!"})
            aadd (_aCols, {04, "Parcela"     ,  10,  "@!"})
            aadd (_aCols, {05, "Cliente"     ,  10,  "@!"})
            aadd (_aCols, {06, "Loja"        ,   5,  "@!"})
            aadd (_aCols, {07, "Nome"        ,  40,  "@!"})
            aadd (_aCols, {08, "Tipo"        ,   5,  "@!"})
            aadd (_aCols, {09, "Dt.Emissão"  ,  20,  "@D"})
            aadd (_aCols, {10, "Dt.Vencto"   ,  20,  "@D"})
            aadd (_aCols, {11, "Valor"       ,  30,  "@E 999,999,999.99"})
            aadd (_aCols, {12, "Saldo"       ,  30,  "@E 999,999,999.99"})
            aadd (_aCols, {13, "Dt.Baixa"    ,  20,  "@D"})
            aadd (_aCols, {14, "Id.Transação",  30,  "@D"})

			U_F3Array (_aDados, "Títulos ", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 40 , "", "", .T., 'C' )
		else
			u_help ("Não foram encontrados dados para consulta")
		endif    		
return
