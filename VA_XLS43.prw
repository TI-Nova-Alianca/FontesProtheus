// Programa...: VA_XLS43
// Autor......: Andre Alves
// Data.......: 20/05/2019
// Cliente....: Nova Alianca
// Descricao..: Exportar notas de devolução (quantidades) para planilha
//
// Historico de alteracoes:
// 
//
// 
//

// --------------------------------------------------------------------------
User Function VA_XLS43 (_lAutomat)
	Local cCadastro := "Exportar notas de devolução (quantidades) para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS43"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"Exportar notas de devolução (quantidades) para planilha")
		AADD(aSays,"")
		
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
	local _lContinua   := .T.
	local _sQuery      := ""
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SD1.D1_COD AS PRODUTO, SD1.D1_DESCRI AS DESCRICAO, SD1.D1_QUANT AS QUANTIDADE,"
	_oSQL:_sQuery += "SD1.D1_UM AS UNI_MEDIDA,"
	_oSQL:_sQuery += "SUBSTRING(SD1.D1_DTDIGIT,7,2) + '/' + SUBSTRING (SD1.D1_DTDIGIT,5,2) + '/' + SUBSTRING (SD1.D1_DTDIGIT,1,4) AS DIGITACAO,"
	_oSQL:_sQuery += "SD1.D1_DOC AS NOTA_FISCAL,"
    _oSQL:_sQuery += "SD1.D1_SERIE AS SERIE, SD1.D1_FORNECE AS CLIENTE, SA1.A1_NOME AS NOME_CLIENTE, SD1.D1_NFORI AS NOTA_ORIGEM"
    _oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1") + " SD1 "
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery +=       " ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SA1.A1_FILIAL = ''"
	_oSQL:_sQuery +=       " AND SA1.A1_COD = SD1.D1_FORNECE)"
	_oSQL:_sQuery +=     " INNER JOIN " + RetSQLName ("SF4") + " SF4 "
	_oSQL:_sQuery +=       " ON (SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=       " AND SF4.F4_CODIGO = SD1.D1_TES"
	_oSQL:_sQuery +=       " AND SF4.F4_ESTOQUE = 'S')"
	_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SD1.D1_FILIAL = '" + xfilial ("SD1") + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_TIPO = 'D'"
	_oSQL:_sQuery +=   " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_LOCAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND SD1.D1_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery += " ORDER BY SD1.D1_COD"
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Periodo de                    ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Periodo ate                   ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Almox de 					  ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Almox ate					  ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Produto inicial               ", "C", 4,  0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {06, "Produto final                 ", "C", 4,  0,  "",   "SB1", {},    ""})
	
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
