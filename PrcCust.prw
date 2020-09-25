// Programa...: PrcCust
// Autor......: Robert Koch
// Data.......: 21/07/2013
// Descricao..: Busca ultimo custo do SB9, para casos onde deve "sair a preco de custo".
//
// Historico de alteracoes:
// 20/08/2014 - Robert - Passa a receber parametro indicando se busca do SB2 ou SB9.
//                     - Passa a considerar o parametro MV_CUSFIL.
// 04/05/2015 - Robert - Passa a arredondar o resultado fonal cfe. decimais do DANFe.
// 02/03/2016 - Robert - Removida geracao de logs pois estava lento.
// 01/06/2016 - Robert - Leitura sempre do SB2
//                     - Valida variacao do SB2 para os ultimos SB9
// 10/06/2016 - Robert - Se tiver erro no recalculo, ou SB2 zerado, busca no SB9 e avisa setor de custos.
// 25/08/2016 - Robert - Valor de retorno arredondado de 4 para 2 decimais (ainda temos muitos casos de diferenca no fechamento do SB6 quando ha varios retornos parciais).
// 05/06/2017 - Robert - Passa a buscar sempre do SB2, independente da ultima execucao do recalculo do medio.
// 16/10/2018 - Robert - Passa a busca do B2_VACUSTR (criado especificamente para isso) e nao mais do SUM(B2_VFIM1)/SUM(B2_QFIM).
//

// --------------------------------------------------------------------------
user function PrcCust (_sProduto, _sLocal)
	local _aAreaAnt  := U_ML_SRArea ()
	local _nRet      := 0
	local _oSQL      := NIL
//	local _sCusFil   := GetMv ("MV_CUSFIL")

/* vERSAO ATEH 16/10/2018
	// Busca custo medio previsto para fechamento (cfe. ultimo recalculo do custo medio).
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM (B2_VFIM1) / SUM (B2_QFIM)"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB2") + " SB2 " 
	_oSQL:_sQuery +=  " WHERE SB2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB2.B2_COD     = '" + _sProduto + "'"
	_oSQL:_sQuery +=    " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
	_oSQL:_sQuery +=    " AND SB2.B2_LOCAL   = '" + _sLocal + "'"
	_oSQL:_sQuery += " AND B2_QFIM > 0"
	_oSQL:_sQuery += " AND B2_VFIM1 > 0"
	_nRet = _oSQL:RetQry (1, .f.)

	// Arredonda o valor para a mesma quantidade de decimais a ser impressa no DANFe, pois o
	// terceiro vai fazer a devolucao baseando-se no que estah escrito no DANFe, e os valores
	// internos do sistema guardam mais decimais, gerando diferencas no fechamento do poder
	// de terceiros quando for incluida a nota de retorno.
	_nRet = round (_nRet, 2)  //7)  //4)
*/

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT B2_VACUSTR"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB2") + " SB2 " 
	_oSQL:_sQuery +=  " WHERE SB2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB2.B2_COD     = '" + _sProduto + "'"
	_oSQL:_sQuery +=    " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
	_oSQL:_sQuery +=    " AND SB2.B2_LOCAL   = '" + _sLocal + "'"
	_nRet = _oSQL:RetQry (1, .f.)
	_nRet = round (_nRet, 2)

	U_ML_SRArea (_aAreaAnt)
return _nRet
