// Programa:   M265BUT
// Autor:      Robert Koch
// Data:       27/11/2020
// Descricao:  P.E. para inclusao de botoes na tela de enderecar produtos (DENTRO da tela. Precisa estar em visualizar/enderecar/...)
//             Criado inicialmente para chamar tela de consulta de enderecos anteriores (GLPI 8887)
 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada para incluir botoes na tela de enderecamento de produtos.
// #PalavasChave      #incluir_botoes
// #TabelasPrincipais #SDA #SDB
// #Modulos           #EST

// Historico de alteracoes:
// 01/02/2021 - Robert - Criado botão para chamar tela e destinação de lotes (GLPI 5563).
// 02/08/2022 - Robert - Adicionado DB_VAUSER na consulta de enderecamentos (GLPI 12421)
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Este P.E. eh chamado DENTRO da tela de manutencao. Nao no browse.
user function M265BUT ()
	local _aRet := {}
	aadd (_aRet, {"Outros end.docto.", {|| U_ConsSDB (m->da_doc, m->da_serie)} , "Outros end.docto." , "Outros end.docto." })
	aadd (_aRet, {"Destinacao lotes",  {|| U_AtuSB8 (m->da_produto, m->da_lotectl)} , "Destinacao lotes" , "Destinacao lotes" })
return _aRet



// --------------------------------------------------------------------------
user function ConsSDB (_sDoc, _sSerie)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DB_PRODUTO AS PRODUTO, B1_DESC AS DESCRICAO"
	_oSQL:_sQuery +=      ", DB_LOTECTL AS LOTE, DB_ESTORNO AS ESTORNADO"
	_oSQL:_sQuery +=      ", DB_LOCALIZ AS ENDERECO, DB_QUANT AS QUANTIDADE"
	_oSQL:_sQuery +=      ", dbo.VA_DTOC(DB_DATA) AS DATA, DB_VAUSER AS USUARIO"
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
