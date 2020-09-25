// Programa...: VA_EXNFP
// Autor......: Andre Alves
// Data.......: 20/06/2018
// Descricao..: Gera Arquivo de Notas dos Associados para Metadados
//
// Historico de alteracoes:
// 02/04/2019 - Andre  - Somar total de notas com mais de 1 item.
// 10-06/2020 - Claudia - Ajustado conforme GLPI 8006

// --------------------------------------------------------------------------
User Function va_exnfp (_lAutomat)
	Local cCadastro   := "Exporta NF safra associados para Metadados"
	Local aSays       := {}
	Local aButtons    := {}
	Local nOpca       := 0
	Local lPerg       := .F.
	private _lAuto    := iif (_lAutomat == NIL, .F., _lAutomat)
	private _sGranel  := ""
	private _sSOper   := ""
	U_LogId ()

	Private cPerg   := "VA_EXNFP" //GRUPO DE PERGUNTAS EM NO SX1
	_ValidPerg () //CRIA O GRUPO DE PERGUNTAS NO SX1
	Pergunte (cPerg, .F.)

	AADD (aSays, "Este Programa Tem Como Objetivo exportar notas de safra para o Metadados")
	AADD (aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD (aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD (aButtons, { 2,.T.,{|| FechaBatch() }} )

	if _lAuto
		Processa( { |lEnd| _GeraTxt() } )
	else
		FormBatch( cCadastro, aSays, aButtons ) // Abre interface para usuário
		If nOpca == 1
			Processa( { |lEnd| _GeraTxt() } )
		Endif
	endif
return

Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return (_lRet)

Static Function _GeraTxt()
	local _oSQL    := nil
	local _sAliasQ := ''
	local _nhdl    := 0
	delete file (alltrim (MV_PAR03))
	_nHdl = fCreate (alltrim (MV_PAR03))
	If _nHdl==-1
		u_help("O arquivo de nome '" + alltrim (MV_PAR03) + "' nao pode ser criado! Verifique os parametros.")
		Return
	Endif

	U_LogSX1 (cPerg)

	u_logIni ()
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT DISTINCT '1' + '0001' + SUBSTRING (DATA,7,2) + '/' + SUBSTRING (DATA,5,2) + '/' + SUBSTRING (DATA,1,4) + "
//	_oSQL:_sQuery += "			REPLICATE('0', 10 - LEN(DOC)) + RTrim(DOC) + "
//  _oSQL:_sQuery += "          REPLICATE('0', 4 - LEN(SERIE)) + RTrim(SERIE) + '4' + "
//  _oSQL:_sQuery += "			REPLICATE('0', 11 - LEN(RTRIM(CAST(VALOR_TOTAL AS DECIMAL(11,2))))) + RTRIM(CAST(VALOR_TOTAL AS DECIMAL(11,2))) + '                              ' +"
//	_oSQL:_sQuery += "			REPLICATE('0', 4 - LEN (ISNULL(F.FORNECEDOR,'') COLLATE DATABASE_DEFAULT)) + RTRIM(ISNULL(F.FORNECEDOR,'') COLLATE DATABASE_DEFAULT) +  "
//	_oSQL:_sQuery += "			SUBSTRING (ISNULL (F.NOME,'') + REPLICATE(' ',40),1,40) + ISNULL (F.TIPOINSCRICAO,' ') + ISNULL (F.INSCRICAO,'                ') AS DADOS"
	_oSQL:_sQuery += " SELECT DISTINCT "
	_oSQL:_sQuery += " 		'1' + '0001' + SUBSTRING(DATA, 7, 2) + '/' + SUBSTRING(DATA, 5, 2) + '/' + SUBSTRING(DATA, 1, 4) + "
	_oSQL:_sQuery += " 		REPLICATE('0', 10 - LEN(DOC)) + RTRIM(DOC) + "
	_oSQL:_sQuery += " 		REPLICATE('0', 4 - LEN(SERIE)) + RTRIM(SERIE) + '4' + "
	_oSQL:_sQuery += " 		REPLICATE('0', 11 - LEN(REPLACE(RTRIM(CAST(VALOR_TOTAL AS DECIMAL(11, 2))),'.',''))) + "
	_oSQL:_sQuery += " 		REPLACE(RTRIM(CAST(VALOR_TOTAL AS DECIMAL(11, 2))),'.','') + "
	_oSQL:_sQuery += " 		'                      " + "00" + cFilant + "00" + cFilant + "' +"
	_oSQL:_sQuery += " 		REPLICATE('0', 4 - LEN(ISNULL(F.FORNECEDOR, '') COLLATE DATABASE_DEFAULT)) + "
	_oSQL:_sQuery += " 		RTRIM(ISNULL(F.FORNECEDOR, '') COLLATE DATABASE_DEFAULT) + SUBSTRING(ISNULL(F.NOME, '') + "
	_oSQL:_sQuery += " 		REPLICATE(' ', 40), 1, 40) + ISNULL(F.TIPOINSCRICAO, ' ') + ISNULL(F.INSCRICAO, '                ' ) + "
	_oSQL:_sQuery += " 		'                                                                                           ' + '11' AS DADOS "
	_oSQL:_sQuery += "			FROM (SELECT DATA, DOC, SERIE, SUM(VALOR_TOTAL) AS VALOR_TOTAL, ASSOCIADO, LOJA_ASSOC"
	_oSQL:_sQuery += "				  FROM VA_VNOTAS_SAFRA"
	_oSQL:_sQuery += "				  WHERE TIPO_NF IN ('V', 'C')"
	_oSQL:_sQuery += "				  AND DATA BETWEEN '" + DTOS (MV_PAR01) + "' AND '" + DTOS (MV_PAR02) + "'"
	_oSQL:_sQuery += "				  AND FILIAL = '" + cFilant + "'"
	_oSQL:_sQuery += "				  GROUP BY DATA, DOC, SERIE, ASSOCIADO, LOJA_ASSOC) V,"
	_oSQL:_sQuery +=	        RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery += "			LEFT JOIN LKSRV_SIRH.SIRH.dbo.VA_VFORNECEDORES F"
	_oSQL:_sQuery += "			ON (F.INSCRICAO  COLLATE DATABASE_DEFAULT = SA2.A2_CGC AND F.TIPOINSCRICAO = 3)"
	_oSQL:_sQuery += "			WHERE SA2.A2_FILIAL = '" + xFilial('SA2') + "'"
	_oSQL:_sQuery += "			AND SA2.A2_COD = V.ASSOCIADO"
	_oSQL:_sQuery += "          AND SA2.A2_TIPO = 'F'"
	_oSQL:_sQuery += "			AND SA2.A2_LOJA = V.LOJA_ASSOC"
	_oSQL:log()
	_sAliasQ := _oSql:qry2trb()
	DO WHILE ! (_sAliasQ) -> (eof())		
			fwrite (_nHdl, U_TamFixo ((_sAliasQ) -> DADOS, 220, " ") + chr (13) + chr (10))
			(_sAliasQ) -> (DBSKIP())
						
	enddo
	(_sAliasQ) -> (dbCloseArea())
	U_HELP ('Arquivo Gerado!')	
	u_logFim ()
Return

Static Function _ValidPerg ()
	local _aRegsPerg := {}

//                         PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Emissao NF de                 ", "D", 8,  0,  "",   "     ", {},    ""})
	aadd (_aRegsPerg, {02, "Emissao NF ate                ", "D", 8,  0,  "",   "     ", {},    ""})
	aadd (_aRegsPerg, {03, "Arquivo destino               ", "C", 60, 0,  "",   "     ", {},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
