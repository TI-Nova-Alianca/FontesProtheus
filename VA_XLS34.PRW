// Programa...: VA_XLS34
// Autor......: Robert Koch
// Data.......: 10/01/2018
// Descricao..: Exporta planilha com sequencia de recebimento de uvas na safra.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Exporta_planilha
// #Descricao         #Exporta planilha com sequencia de recebimento de uvas na safra.
// #PalavasChave      #safra #sequenciamento #dercarga #descarregamento
// #TabelasPrincipais #SD1 #SZE
// #Modulos           #COOP #PCP

// Historico de alteracoes:
// 23/02/2018 - Robert - Passa a usar a view VA_VNOTAS_SAFRA
//                     - Criado parametro de safra
//                     - Busca maior item da carga, para casos de mesmo produto (talhoes diferentes).
// 28/03/2022 - Robert - Nao considerava contranotas de producao propria.
// 10/02/2023 - Robert - Leitura campo ZZA_TQPULM
// 06/02/2024 - Sandra - Incluso campos cor e tipo - GLPI 14764.
//

// --------------------------------------------------------------------------
User Function VA_XLS34 (_lAutomat)
	Local cCadastro := "Exporta planilha com sequencia de recebimento de uvas na safra."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS34"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
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
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Monta lista dos tanques.
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT convert (varchar (20), CASE"
	_oSQL:_sQuery +=        " WHEN CARGAS.ZZA_INIST3 IS NULL OR"
	_oSQL:_sQuery +=           " CARGAS.ZZA_INIST3 = '' THEN CASE"
	_oSQL:_sQuery +=              " WHEN CARGAS.ZZA_INIST2 IS NULL OR"
	_oSQL:_sQuery +=                 " CARGAS.ZZA_INIST2 = '' THEN CASE"
	_oSQL:_sQuery +=                    " WHEN CARGAS.ZZA_INIST1 IS NULL OR"
	_oSQL:_sQuery +=                       " CARGAS.ZZA_INIST1 = '' THEN CASE"
	_oSQL:_sQuery +=                          " WHEN CARGAS.ZE_DATA + CARGAS.ZE_HORSAID IS NULL THEN CAST(V.DATA + ' ' + SF1.F1_VAHRINC AS DATETIME)"
	_oSQL:_sQuery +=                          " ELSE CAST(CARGAS.ZE_DATA + ' ' + CARGAS.ZE_HORSAID AS DATETIME)"
	_oSQL:_sQuery +=                       " END"
	_oSQL:_sQuery +=                    " ELSE CARGAS.ZZA_INIST1 END"
	_oSQL:_sQuery +=              " ELSE CARGAS.ZZA_INIST2 END"
	_oSQL:_sQuery +=        " ELSE CARGAS.ZZA_INIST3 END, 120) AS HORA_RECEB,"
	_oSQL:_sQuery +=        " V.FILIAL,"
	_oSQL:_sQuery +=        " V.PRODUTO,"
	_oSQL:_sQuery +=        " rtrim (V.DESCRICAO) AS DESCRICAO,"
	_oSQL:_sQuery +=        " SD1.D1_LOCAL AS ALMOX,"
	_oSQL:_sQuery +=        " '''' + SD1.D1_LOTECTL AS LOTE,"
	_oSQL:_sQuery +=        " V.PESO_LIQ AS QUANT,"
	_oSQL:_sQuery +=        " SD1.D1_UM AS UN_MED,"
	_oSQL:_sQuery +=        " CARGAS.ZE_CARGA AS CARGA,"
//	_oSQL:_sQuery +=        " CASE WHEN CARGAS.ZZA_LINHA IS NULL OR CARGAS.ZZA_LINHA = ' ' THEN CARGAS.ZE_LOCDESC"
//	_oSQL:_sQuery +=           " ELSE CARGAS.ZZA_LINHA"  // O campo ZZA_LINHA eh gravado pelo softwsre da Mazeli, entao entendo-o como 'tombador efetivo'.
//	_oSQL:_sQuery +=        " END AS TOMBADOR,"
	_oSQL:_sQuery +=        " CASE WHEN CARGAS.ZZA_TQPULM != 0 AND CARGAS.ZZA_TQPULM != CARGAS.ZZA_LINHA"
	_oSQL:_sQuery +=           " THEN CARGAS.ZZA_TQPULM"
	_oSQL:_sQuery +=           " ELSE CASE WHEN CARGAS.ZZA_LINHA IS NULL OR CARGAS.ZZA_LINHA = ' '"
	_oSQL:_sQuery +=                   " THEN CARGAS.ZE_LOCDESC"
	_oSQL:_sQuery +=                   " ELSE CARGAS.ZZA_LINHA"  // O campo ZZA_LINHA eh gravado pelo software da Mazeli, entao entendo-o como 'tombador efetivo'.
	_oSQL:_sQuery +=           " END"
	_oSQL:_sQuery +=        " END AS TANQUE_PULMAO,"
	_oSQL:_sQuery +=        " V.DOC AS NF"
	_oSQL:_sQuery +=        ",CASE WHEN CARGAS.ZZA_TQPULM != 0 AND CARGAS.ZZA_TQPULM != CARGAS.ZZA_LINHA"
	_oSQL:_sQuery +=        " THEN 'Desviado do tombador ' + CARGAS.ZZA_LINHA"
	_oSQL:_sQuery +=        " ELSE '' END AS DESVIO"
	_oSQL:_sQuery += "                      ,CASE                               		  "
    _oSQL:_sQuery += "                         		WHEN  V.COR ='T' THEN  'TINTO'        "
    _oSQL:_sQuery += "                          	WHEN  V.COR ='B' THEN  'BRANCO'    	  "
    _oSQL:_sQuery += "                           	WHEN  V.COR ='R' THEN  'ROSE'         "
    _oSQL:_sQuery += "                      END AS COR                 	              	  "
	
	_oSQL:_sQuery += "                      ,CASE                               						 "
    _oSQL:_sQuery += "                         		WHEN  V.TIPO_ORGANICO = 'C' THEN  'CONVENCIONAL'     "
    _oSQL:_sQuery += "                          	WHEN  V.TIPO_ORGANICO = 'O' THEN 'ORGANICA'          "
    _oSQL:_sQuery += "                           	WHEN  V.TIPO_ORGANICO = 'E' THEN 'EM_CONVERSAO'      "
    _oSQL:_sQuery += "                          	WHEN  V.TIPO_ORGANICO = 'B' THEN 'BORDADURA'         "
	_oSQL:_sQuery += "                      END AS TIPO  											     "
	
	

	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SF1") + " SF1, "
	_oSQL:_sQuery +=             RetSQLName ("SD1") + " SD1, "
	_oSQL:_sQuery +=           " VA_VNOTAS_SAFRA V"
	
	// Monta tabela de cargas agrupando por produto por que existem casos de cargas com mais de uma ocorrencia
	// do mesmo produto, originado de diferentes talhoes (IDSZ9) e que, na pratica, descarregam de uma soh vez,
	// ficando o grau gravado em apenas um dos itens do SZF.
	_oSQL:_sQuery +=  " LEFT JOIN (SELECT SZE.ZE_FILIAL, SZE.ZE_SAFRA, SZE.ZE_CARGA, SZE.ZE_NFGER, SZE.ZE_SERIE, SZF.ZF_PRODUTO, SZF.ZF_GRAU"
	_oSQL:_sQuery +=                    " ,SZE.ZE_DATA, SZE.ZE_HORSAID, SZE.ZE_LOCDESC "
	_oSQL:_sQuery +=                    " ,MAX (ZZA.ZZA_INIST1) AS ZZA_INIST1"
	_oSQL:_sQuery +=                    " ,MAX (ZZA.ZZA_INIST2) AS ZZA_INIST2"
	_oSQL:_sQuery +=                    " ,MAX (ZZA.ZZA_INIST3) AS ZZA_INIST3"
	_oSQL:_sQuery +=                    " ,MAX (ZZA.ZZA_LINHA)  AS ZZA_LINHA"
	_oSQL:_sQuery +=                    " ,MAX (ZZA.ZZA_TQPULM) AS ZZA_TQPULM"
	_oSQL:_sQuery +=               " FROM " + RetSQLName ("SZE") + " SZE, "
	_oSQL:_sQuery +=                          RetSQLName ("SZF") + " SZF "
	_oSQL:_sQuery +=                        " LEFT JOIN " + RetSQLName ("ZZA") + " ZZA "
	_oSQL:_sQuery +=                           " ON (ZZA.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=                           " AND ZZA.ZZA_FILIAL = SZF.ZF_FILIAL "
	_oSQL:_sQuery +=                           " AND ZZA.ZZA_SAFRA = SZF.ZF_SAFRA "
	_oSQL:_sQuery +=                           " AND ZZA.ZZA_CARGA = SZF.ZF_CARGA "
	_oSQL:_sQuery +=                           " AND ZZA.ZZA_PRODUT = SZF.ZF_ITEM) "
	_oSQL:_sQuery +=               " WHERE SZE.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=                 " AND SZF.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=                 " AND SZF.ZF_FILIAL = SZE.ZE_FILIAL "
	_oSQL:_sQuery +=                 " AND SZF.ZF_SAFRA = SZE.ZE_SAFRA "
	_oSQL:_sQuery +=                 " AND SZF.ZF_CARGA = SZE.ZE_CARGA
	_oSQL:_sQuery +=               " GROUP BY SZE.ZE_FILIAL, SZE.ZE_SAFRA, SZE.ZE_CARGA, SZE.ZE_NFGER, SZE.ZE_SERIE, SZF.ZF_PRODUTO, SZF.ZF_GRAU,"
	_oSQL:_sQuery +=                        " SZE.ZE_DATA, SZE.ZE_HORSAID, SZE.ZE_LOCDESC"
	_oSQL:_sQuery +=            " ) AS CARGAS "
	_oSQL:_sQuery +=          " ON (CARGAS.ZE_FILIAL  = V.FILIAL"
	_oSQL:_sQuery +=          " AND CARGAS.ZE_SAFRA   = V.SAFRA"
	_oSQL:_sQuery +=          " AND CARGAS.ZE_NFGER   = V.DOC"
	_oSQL:_sQuery +=          " AND CARGAS.ZE_SERIE   = V.SERIE "
	_oSQL:_sQuery +=          " AND CARGAS.ZF_PRODUTO = V.PRODUTO"
	_oSQL:_sQuery +=          " AND CARGAS.ZF_GRAU    = V.GRAU)"
	_oSQL:_sQuery +=  " WHERE SF1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=    " AND SF1.F1_FILIAL  = SD1.D1_FILIAL "
	_oSQL:_sQuery +=    " AND SF1.F1_DOC     = SD1.D1_DOC "
	_oSQL:_sQuery +=    " AND SF1.F1_SERIE   = SD1.D1_SERIE "
	_oSQL:_sQuery +=    " AND SF1.F1_FORNECE = SD1.D1_FORNECE "
	_oSQL:_sQuery +=    " AND SF1.F1_LOJA    = SD1.D1_LOJA "
	_oSQL:_sQuery +=    " AND SD1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=    " AND SD1.D1_ITEM    = V.ITEM_NOTA"
	_oSQL:_sQuery +=    " AND SD1.D1_DOC     = V.DOC"
	_oSQL:_sQuery +=    " AND SD1.D1_SERIE   = V.SERIE "
	_oSQL:_sQuery +=    " AND SD1.D1_FORNECE = V.ASSOCIADO"
	_oSQL:_sQuery +=    " AND SD1.D1_LOJA    = V.LOJA_ASSOC"
	_oSQL:_sQuery +=    " AND SD1.D1_FILIAL  = V.FILIAL"
	_oSQL:_sQuery +=    " AND V.SAFRA        = '" + mv_par01 + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL       BETWEEN '" + mv_par02 + "' AND '" + mv_par03 + "'"
	_oSQL:_sQuery +=    " AND V.DATA         between '" + dtos (mv_par04) + "' AND '" + dtos (mv_par05) + "'"
//	_oSQL:_sQuery +=    " AND V.TIPO_NF      in ('E', 'C')"
	_oSQL:_sQuery +=    " AND V.TIPO_NF      in ('E', 'C', 'P')"
	if mv_par06 == 1  // Lotes com saldo
		_oSQL:_sQuery +=  " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                " FROM " + RetSQLName ("SB8") + " SB8 "
		_oSQL:_sQuery +=               " WHERE SB8.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=                 " AND SB8.B8_FILIAL = SD1.D1_FILIAL"
		_oSQL:_sQuery +=                 " AND SB8.B8_PRODUTO = SD1.D1_COD"
		_oSQL:_sQuery +=                 " AND SB8.B8_LOTECTL = SD1.D1_LOTECTL"
		_oSQL:_sQuery +=                 " AND SB8.B8_SALDO > 0)"
	endif
	_oSQL:Log ()
	_oSQL:ArqDestXLS = 'VA_XLS34'
	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes            Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C",  4, 0,  "",   "   ", {}, ""})
	aadd (_aRegsPerg, {02, "Filial inicial                ", "C",  2, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {03, "Filial final                  ", "C",  2, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {04, "Data (NF) inicial             ", "D",  8, 0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {05, "Data (NF) final               ", "D",  8, 0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {06, "Saldo dos lotes               ", "N",  1, 0,  "",   "",    {'Apenas com saldo', 'Todos'}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
