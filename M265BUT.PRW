// Programa:   M265BUT
// Autor:      Robert Koch
// Data:       27/11/2020
// Descricao:  P.E. para inclusao de botoes na tela de enderecar produtos
//             Criado inicialmente para chamar tela de consulta de enderecos anteriores (GLPI 8887)
 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada para incluir botoes na tela de enderecamento de produtos.
// #PalavasChave      #incluir_botoes
// #TabelasPrincipais #SDA #SDB
// #Modulos           #EST

// Historico de alteracoes:
// 

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function M265BUT ()
	local _aRet := {}
	aadd (_aRet, {"Outros end.docto.", {|| U_ConsSDB (m->da_doc, m->da_serie)} , "Outros end.docto." , "Outros end.docto." })
return _aRet



// --------------------------------------------------------------------------
user function ConsSDB (_sDoc, _sSerie)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DB_PRODUTO AS PRODUTO, B1_DESC AS DESCRICAO, DB_LOTECTL AS LOTE, DB_ESTORNO AS ESTORNADO"
	_oSQL:_sQuery +=      ", DB_LOCALIZ AS ENDERECO, DB_QUANT AS QUANTIDADE, dbo.VA_DTOC(DB_DATA) AS DATA"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SDB") + " SDB, "
	_oSQL:_sQuery +=            RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE SDB.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SDB.DB_FILIAL  = '" + xfilial ("SDB") + "'"
	_oSQL:_sQuery +=   " AND SDB.DB_DOC     = '" + _sDoc + "'"
	_oSQL:_sQuery +=   " AND SDB.DB_SERIE   = '" + _sSerie + "'"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     = SDB.DB_PRODUTO"
	_oSQL:_sQuery += " ORDER BY DB_PRODUTO, DB_DATA"
//	_oSQL:Log ()
	_oSQL:F3Array ("Outros enderecamentos deste documento")
return
