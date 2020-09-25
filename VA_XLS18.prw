// Programa...: VA_XLS18
// Autor......: Robert Koch
// Data.......: 25/05/2012
// Descricao..: Exportacao notas de entrada X arquivos XML para planilha.
//
// Historico de alteracoes:
// 12/02/2013 - Elaine - Ajuste no SQL quando selecionado XML sem NF conforme chamado ocomon 456
// 14/02/2013 - Elaine - Inclusão e tratamento de filtros conforme chamado ocomon 455
// 24/09/2013 - Robert - Fica apenas a opcao de XML sem nota e nota sem XML
//                     - Verifica se existe cancelamento de algum XML
//                     - Pode retornar dados para rotina chamadora, caso necessario.
// 15/08/2014 - Robert - Criados parametros de data de digitacao de... ate.
// 05/09/2014 - Catia  - Criados parametros de fornecedor de... ate.
// 05/09/2014 - Robert - Desconsidera chaves vazias na leitura do ZZX.
// 12/09/2014 - Catia  - Criados parametros SPED/CTE/Ambos - p/poder separar as notas dos ctes            
// 15/10/2015 - Robert - Desconsidera campo ZZX_STATUS
//

// --------------------------------------------------------------------------
User Function VA_XLS18 (_sDestino, _nBase)
	Local cCadastro := "Exportacao notas de entrada X arquivos XML para planilha"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	local _xRet     := NIL
	Private cPerg   := "VAXLS18"
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	if _sDestino != NIL
		mv_par01 = _nBase
		_xRet = _Gera (_sDestino)
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays,"exportacao notas de entrada X arquivos XML para planilha")
		AADD(aSays,"para planilha eletronica.")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return _xRet



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet

	
	
// --------------------------------------------------------------------------
Static Function _Gera (_sDestino)
	local _xRet := NIL
	local _oSQL := NIL
	private N   := 0

	_oSQL := ClsSQL():New ()

	// Usa as NF de entrada (tabela SF1) como base de pesquisa.
	if mv_par01 == 1
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH C AS ("
		_oSQL:_sQuery += "SELECT F1_FILIAL AS FILIAL,"
		_oSQL:_sQuery +=       " F1_EMISSAO AS EMISSAO,"
       _oSQL:_sQuery +=       " F1_DTDIGIT AS DIGITACAO,"
		_oSQL:_sQuery +=       " F1_DOC AS DOC,"
		_oSQL:_sQuery +=       " F1_SERIE AS SERIE,"
		_oSQL:_sQuery +=       " F1_TIPO AS TIPO_NF,"
		_oSQL:_sQuery +=       " F1_ESPECIE AS ESPECIE,"
		_oSQL:_sQuery +=       " F1_FORNECE AS FORN_CLIENTE,"
		_oSQL:_sQuery +=       " F1_LOJA AS LOJA,"
		_oSQL:_sQuery +=       " CASE"
		_oSQL:_sQuery +=            " WHEN F1_TIPO IN ('D', 'B') THEN SA1.A1_NOME"
		_oSQL:_sQuery +=            " ELSE SA2.A2_NOME"
		_oSQL:_sQuery +=       " END AS NOME,"
		//_oSQL:_sQuery +=       " ' '+SF1.F1_CHVNFE AS CHAVE,"  // Exporta com espaco no inicio para o BrOffice nao converter para notacao cientifica.
		_oSQL:_sQuery +=       " ' *' + SF1.F1_CHVNFE + ' *' AS CHAVE,"  // Exporta com espaco no inicio para o BrOffice nao converter para notacao cientifica.
		_oSQL:_sQuery +=       " (SELECT COUNT (*)"
		_oSQL:_sQuery +=          " FROM " + RetSQLName ("ZZX") + " ZZX "
		_oSQL:_sQuery +=         " WHERE ZZX.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=           " AND ZZX.ZZX_CHAVE != ''"
		_oSQL:_sQuery +=           " AND ZZX.ZZX_FILIAL = SF1.F1_FILIAL"  // Chave deve estar na filial correta.
		_oSQL:_sQuery +=           " AND ZZX.ZZX_CHAVE  = SF1.F1_CHVNFE) AS CHV_IMPORT,"
		_oSQL:_sQuery +=       " (SELECT COUNT (*)"
		_oSQL:_sQuery +=          " FROM " + RetSQLName ("ZZX") + " ZZX "
		_oSQL:_sQuery +=         " WHERE ZZX.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=           " AND ZZX.ZZX_FILIAL = SF1.F1_FILIAL"  // Chave deve estar na filial correta.
		_oSQL:_sQuery +=           " AND ZZX.ZZX_CHAVE != ''"
		_oSQL:_sQuery +=           " AND ZZX.ZZX_RETSEF = '100'"  // Uso autorizado
		_oSQL:_sQuery +=           " AND ZZX.ZZX_CHAVE  = SF1.F1_CHVNFE) AS EMIS_AUT,"
		_oSQL:_sQuery +=        " ((SELECT COUNT (*)"  // Cancelamento versao inicial (antes de ser por evento)
		_oSQL:_sQuery +=           " FROM " + RetSQLName ("ZZX") + " ZZX_CANC "
		_oSQL:_sQuery +=          " WHERE ZZX_CANC.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_CHAVE != ''"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_CHAVE  = SF1.F1_CHVNFE"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_LAYOUT = 'cancNFe'"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_RETSEF = '101')"  // Cancelamento autorizado
		_oSQL:_sQuery +=        " + "
		_oSQL:_sQuery +=        " (SELECT COUNT (*)"  // Cancelamento por evento
		_oSQL:_sQuery +=           " FROM " + RetSQLName ("ZZX") + " ZZX_CANC "
		_oSQL:_sQuery +=          " WHERE ZZX_CANC.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_CHAVE != ''"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_CHAVE  = SF1.F1_CHVNFE"
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_TPEVEN      = '110111'"  // Evento de cancelamento
		_oSQL:_sQuery +=            " AND ZZX_CANC.ZZX_RETSEF = '101')) AS CANC_AUT"  // Cancelamento autorizado
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SF1") + " SF1 "
		_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=         " ON (SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=         " AND SA2.A2_COD     = SF1.F1_FORNECE"
		_oSQL:_sQuery +=         " AND SA2.A2_LOJA    = SF1.F1_LOJA)"
		_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=         " ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=         " AND SA1.A1_COD     = SF1.F1_FORNECE"
		_oSQL:_sQuery +=         " AND SA1.A1_LOJA    = SF1.F1_LOJA)"
		_oSQL:_sQuery +=  " WHERE SF1.D_E_L_E_T_ = ''
		_oSQL:_sQuery +=    " AND F1_DTDIGIT BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
		_oSQL:_sQuery +=    " AND F1_FORNECE BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
		if mv_par06=3
		  _oSQL:_sQuery +=    " AND F1_ESPECIE IN ('SPED', 'CTE')"
		else
		  if mv_par06=1
		      _oSQL:_sQuery +=    " AND F1_ESPECIE IN ('SPED')"
		  else
		      _oSQL:_sQuery +=    " AND F1_ESPECIE IN ('CTE')"
		  endif  
		endif  
		_oSQL:_sQuery +=    " AND F1_FORMUL != 'S'"
		_oSQL:_sQuery +=  " ) " 
		_oSQL:_sQuery +=  " SELECT CASE WHEN CANC_AUT > 0 THEN 'CANCELAMENTO AUTORIZADO'"
		_oSQL:_sQuery +=         " ELSE CASE WHEN CHV_IMPORT = 0 THEN 'XML NAO ENCONTRADO'"
		_oSQL:_sQuery +=              " ELSE CASE WHEN EMIS_AUT = 0 THEN 'EMISSAO NAO AUTORIZADA'"
		_oSQL:_sQuery +=                   " ELSE ''"
		_oSQL:_sQuery +=                   " END"
		_oSQL:_sQuery +=              " END"
		_oSQL:_sQuery +=         " END AS PROBLEMA,"
		_oSQL:_sQuery +=         " C.FILIAL, C.EMISSAO, C.DIGITACAO, C.DOC, C.SERIE, C.FORN_CLIENTE, C.LOJA, C.NOME, C.CHAVE"
		_oSQL:_sQuery +=    " FROM C"
		_oSQL:_sQuery +=  " WHERE EMIS_AUT = 0 OR CANC_AUT > 0"
		_oSQL:_sQuery +=  " ORDER BY C.FILIAL, C.EMISSAO, C.FORN_CLIENTE, C.DOC"

	
	// Usa os arquivos XML (tabela ZZX) como base de pesquisa.
	else

		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT 'XML SEM NF DE ENTRADA' AS PROBLEMA,"
		_oSQL:_sQuery +=       " ZZX_FILIAL AS FILIAL,"
		_oSQL:_sQuery +=       " ZZX_DTIMP AS IMPORTACAO,"
		_oSQL:_sQuery +=       " ZZX_DOC AS DOC,"
		_oSQL:_sQuery +=       " ZZX_SERIE AS SERIE,"
		_oSQL:_sQuery +=       " ZZX_CLIFOR AS CLI_FORN,"
		_oSQL:_sQuery +=       " ZZX_LOJA AS LOJA,"
		_oSQL:_sQuery +=       " ISNULL (CASE"
		_oSQL:_sQuery +=            " WHEN ZZX_TIPONF IN ('D', 'B') THEN SA1.A1_NOME"
		_oSQL:_sQuery +=            " ELSE SA2.A2_NOME"
		_oSQL:_sQuery +=       " END, '') AS NOME,"
		_oSQL:_sQuery +=       " ' ' + ZZX_CHAVE AS CHAVE"  // Exporta com espaco no inicio para o BrOffice nao converter para notacao cientifica.
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZX") + " ZZX "
		_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=         " ON (SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=         " AND SA2.A2_COD     = ZZX.ZZX_CLIFOR"
		_oSQL:_sQuery +=         " AND SA2.A2_LOJA    = ZZX.ZZX_LOJA)"
		_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=         " ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=         " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=         " AND SA1.A1_COD     = ZZX.ZZX_CLIFOR"
		_oSQL:_sQuery +=         " AND SA1.A1_LOJA    = ZZX.ZZX_LOJA)"
		_oSQL:_sQuery +=  " WHERE ZZX.D_E_L_E_T_ = ''
//		_oSQL:_sQuery +=    " AND ZZX.ZZX_STATUS != '8'"  // Chave em duplicidade
		_oSQL:_sQuery +=    " AND ZZX.ZZX_RETSEF = '100'"  // Uso autorizado
		_oSQL:_sQuery +=    " AND ZZX.ZZX_DTIMP  BETWEEN '" + dtos (mv_par02) + "' AND '" + dtos (mv_par03) + "'"
       _oSQL:_sQuery +=    " AND ZZX.ZZX_CLIFOR BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
       _oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"  // Cancelamento versao inicial (antes de ser por evento)
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("ZZX") + " ZZX_CANC "
		_oSQL:_sQuery +=                     " WHERE ZZX_CANC.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_CHAVE  = ZZX.ZZX_CHAVE"
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_LAYOUT = 'cancNFe'"
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_RETSEF = '101')"  // Cancelamento autorizado
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"  // Cancelamento por evento
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("ZZX") + " ZZX_CANC "
		_oSQL:_sQuery +=                     " WHERE ZZX_CANC.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_CHAVE  = ZZX.ZZX_CHAVE"
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_TPEVEN      = '110111'"  // Evento de cancelamento
		_oSQL:_sQuery +=                       " AND ZZX_CANC.ZZX_RETSEF = '101')"  // Cancelamento autorizado
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SF1") + " SF1 "
		_oSQL:_sQuery +=                     " WHERE SF1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND SF1.F1_FILIAL  = ZZX.ZZX_FILIAL"
		_oSQL:_sQuery +=                       " AND SF1.F1_CHVNFE  = ZZX.ZZX_CHAVE)"
		_oSQL:_sQuery +=  " ORDER BY ZZX_FILIAL, ZZX_DTIMP, ZZX_CLIFOR, ZZX_DOC"
	endif

	u_log (_oSQL:_squery)
	do case
	case _sDestino == NIL
		processa ({ || _oSQL:Qry2XLS ()})
	case _sDestino == 'P'
		processa ({ || _oSQL:Qry2XLS ()})
	case _sDestino == "A"
		_xRet = aclone (_oSQL:Qry2Array (.t.,.t.))
	otherwise
		u_help ("Sem tratamento para destino = '" + cvaltochar (_sDestino) + "' na rotina " + ProcName () + "-->" + procname (1))
	endcase
return _xRet



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                                        Help
	aadd (_aRegsPerg, {01, "Base de pesquisa              ", "N", 1,  0,  "",   "   ", {'NF de entrada', 'XML importados'},             ""})
	aadd (_aRegsPerg, {02, "Digitacao da NF inicial       ", "D", 8,  0,  "",   "   ", {},                                              ""})
	aadd (_aRegsPerg, {03, "Digitacao da NF final         ", "D", 8,  0,  "",   "   ", {},                                              ""})
	aadd (_aRegsPerg, {04, "Fornecedor de                 ", "C", 6,  0,  "",   "SA2", {},                        "Fornecedor Inicial"})
    aadd (_aRegsPerg, {05, "Fornecedor ate                ", "C", 6,  0,  "",   "SA2", {},                        "Fornecedor Final"})
    aadd (_aRegsPerg, {06, "Opção Desejada                ", "N", 1,  0,  "",   "   ", {"NFE","CTE","Ambos"},   ""})
    
    
	U_ValPerg (cPerg, _aRegsPerg)
	
Return
