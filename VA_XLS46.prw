// Programa...: VA_XLS46
// Autor......: Robert Koch
// Data.......: 16/10/2019
// Descricao..: Exporta planiha com movimentos de industrializao (compra de itens tipo BN)
//
// Historico de alteracoes:
// 

// --------------------------------------------------------------------------
User Function VA_XLS46 (_lAuto)
	Local cCadastro := "Notas de industrializacao"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	Private cPerg   := "VAXLS46"
	_ValidPerg()
	Pergunte (cPerg, .F.)
	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera ()})
	else
		if Pergunte (cPerg, .T.)
			Processa( { |lEnd| _Gera() } )
		endif
	endif
return


	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT D1_FILIAL AS FILIAL, D1_FORNECE AS FORNEC, D1_LOJA AS LOJA, A2_NOME AS NOME_FORNEC, D1_COD AS PRODUTO,"
	_oSQL:_sQuery +=       " D1_DESCRI AS DESCRICAO, SD1.D1_QUANT AS QUANT, SD1.D1_UM AS UN_MED, SD1.D1_TOTAL AS VALOR,"
	_oSQL:_sQuery +=       " SD1.D1_DOC AS NF, dbo.VA_DTOC(SD1.D1_DTDIGIT) as DT_DIGITO, SD1.D1_OP AS OP,"
	_oSQL:_sQuery +=       " SC2.C2_PRODUTO AS PRODUTO_FINAL_DA_OP, SB1_OP.B1_DESC AS DESCR_PRODUTO_OP"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1 "
	_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SC2") + " SC2 "
	_oSQL:_sQuery +=            " JOIN " + RetSQLName ("SB1") + " SB1_OP "
	_oSQL:_sQuery +=                 " ON (SB1_OP.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                 " AND SB1_OP.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=                 " AND SB1_OP.B1_COD = SC2.C2_PRODUTO)"
	_oSQL:_sQuery +=           " ON (SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SC2.C2_FILIAL = SD1.D1_FILIAL"
	_oSQL:_sQuery +=           " AND SC2.C2_NUM + SC2.C2_ITEM + SC2.C2_SEQUEN + SC2.C2_ITEMGRD = D1_OP)"
	_oSQL:_sQuery +=       ", " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=       ", " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=  " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " AND SD1.D1_TP      = 'BN'"
	_oSQL:_sQuery +=    " AND SD1.D1_TIPO    = 'N'"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = D1_COD"
	_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COD     = D1_FORNECE"
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = D1_LOJA"
	_oSQL:_sQuery +=  " ORDER BY D1_DTDIGIT, D1_FORNECE, D1_DOC"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .T.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Data inicial digit.NF  ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Data final digit.NF    ", "D", 8,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {03, "Filial inicial         ", "C", 2,  0,  "",   "   ", {}, 					""})
	aadd (_aRegsPerg, {04, "Filial final           ", "C", 2,  0,  "",   "   ", {}, 					""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return

