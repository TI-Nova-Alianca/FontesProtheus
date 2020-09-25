// Programa...: VA_XLS38
// Autor......: Robert Koch
// Data.......: 19/11/2018
// Descricao..: Exportacao para planilha de um kardex resumido por CR (cod.Sisdeclara)
//
// Historico de alteracoes:
// 27/09/2019 - Robert - Passa a usar uma funcao do SQL.
//

// --------------------------------------------------------------------------
User Function VA_XLS38 (_lAutomat)
	Local cCadastro := "Exportacao de planilha de movimentos com resumo por codigo Sisdeclara"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS38"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao de movimentos de estoque, com codigo de Sisdeclara,")
		AADD(aSays,"para planilha eletronica.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet


	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _sAliasQ   := NIL
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

	_oSQL := ClsSQL():New ()
/*
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH KARDEX AS"
	_oSQL:_sQuery += "(SELECT SB2.B2_FILIAL AS FILIAL, SB2.B2_COD AS PRODUTO, B1_DESC AS DESCRICAO, SB2.B2_LOCAL AS ALMOX, K.MOVIMENTO + ' ' + K.NOME AS MOVTO, K.OP, K.QT_ENTRADA * SB1.B1_LITROS AS LITROS_ENTRADA, K.QT_SAIDA * SB1.B1_LITROS AS LITROS_SAIDA"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=              RetSQLName ("SB2") + " SB2 "
	_oSQL:_sQuery +=            " cross apply (SELECT *"
	_oSQL:_sQuery +=                           " FROM dbo.VA_FKARDEX (B2_FILIAL, B2_COD, B2_LOCAL, '" + dtos (mv_par01) + "', '" + dtos (mv_par02) + "')"
	_oSQL:_sQuery +=                          " WHERE LINHA > 1"
	_oSQL:_sQuery +=                            " AND (QT_ENTRADA != 0 OR QT_SAIDA != 0)"
	_oSQL:_sQuery +=                        " )AS K"
	_oSQL:_sQuery +=  " WHERE SB2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB2.B2_FILIAL = '" + xfilial ("SB2") + "'"
	_oSQL:_sQuery +=    " AND B2_COD IN (SELECT B5_COD "
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SB5") + " SB5 "
	_oSQL:_sQuery +=                    " WHERE SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                      " AND SB5.B5_FILIAL = '" + xfilial ("SB5") + "'"
	_oSQL:_sQuery +=                      " AND SB5.B5_VACSD" + cFilAnt + " = '" + mv_par03 + "')"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD = SB2.B2_COD"
	_oSQL:_sQuery +=  ")"
	_oSQL:_sQuery +=  " SELECT FILIAL, PRODUTO, DESCRICAO, MOVTO, OP, SUM (LITROS_ENTRADA) AS LITROS_ENTRADA, SUM (LITROS_SAIDA) AS LITROS_SAIDA, ISNULL (SC2.C2_PRODUTO, '') AS PRODUTO_RELACIONADO, ISNULL (SB5.B5_VACSD" + cFilAnt + ", '') AS CR_RELACIONADO"
	_oSQL:_sQuery +=  " FROM KARDEX"
	_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SC2") + " SC2 "
	_oSQL:_sQuery +=            " LEFT JOIN " + RetSQLName ("SB5") + " SB5 "
	_oSQL:_sQuery +=              " ON (SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=              " AND SB5.B5_FILIAL = '" + xfilial ("SB5") + "'"
	_oSQL:_sQuery +=              " AND SB5.B5_COD = SC2.C2_PRODUTO)"
	_oSQL:_sQuery +=         " ON (SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=         " AND SC2.C2_FILIAL = KARDEX.FILIAL"
	_oSQL:_sQuery +=         " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = KARDEX.OP)"
	_oSQL:_sQuery +=  " GROUP BY FILIAL, PRODUTO, DESCRICAO, MOVTO, OP, SC2.C2_PRODUTO, SB5.B5_VACSD" + cFilAnt
*/
	_oSQL:_sQuery := "SELECT * FROM dbo.VA_FKARDEX_SISDEVIN ('" + cFilAnt + "', '" + mv_par03 + "', '" + dtos (mv_par01) + "', '" + dtos (mv_par02) + "')
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SB2")
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                          Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "      ", {},                             ""})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "      ", {},                             ""})
	aadd (_aRegsPerg, {03, "Codigo CR (Sisdeclara)        ", "C", 15, 0,  "",   "SB5   ", {},                             ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
