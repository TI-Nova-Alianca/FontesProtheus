// Programa...: VA_XLS23
// Autor......: Elaine Ballico
// Data.......: 15/02/2013
// Descricao..: Exportacao de dados de preenchimento do Sisdeclara
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Exportacao de dados de preenchimento do Sisdeclara
// #PalavasChave      #sisdevin
// #TabelasPrincipais #SF1 #SF2 #SB1 #SF4
// #Modulos           
//
// Historico de alteracoes:
// 28/02/2013 - Elaine  - Alteracao para incluir o número da guia, código e descrição da operação no arquivo
// 08/04/2016 - Robert  - Programa desabilitado (ver adiante).
// 09/05/2016 - Robert  - Habilitado novamente (tratamento para novos campos no SB5).
// 03/06/2016 - Catia   - usar VA_VFAT ao inves do antigo exporta dados
// 07/06/2016 - Robert  - Campo PRODPAI em desuso. Passa a usar apenas o campo PRODUTO da view VA_VFAT.
// 23/12/2016 - Júlio   - Alterada a leitura da tabela SX5_88 para a tabela ZX5_39.  
// 06/05/2019 - Robert  - Ajustado campo X5_FILIAL para ZX5_FILIAL na tabela 50.
// 06/05/2019 - Sandra  - Ajustado campo X5_DESCRI para ZX5_DESCRI na tabela 50.
// 05/08/2019 - Andre   - Alterada tabela SZB para CC2.
// 07/11/2019 - Andre   - Removido CC2 da Query.
// 25/02/2020 - Claudia - Alterado o uso da view VA_VFAT para a tabela BI_ALIANCA.dbo.VA_FATDADOS
// 28/06/2023 - Claudia - Acrescentado novo campo de tipo de operação sisdevin F4_VASITO. GLPI: 13814
//
// ---------------------------------------------------------------------------------------------------------------
User Function VA_XLS23 (_lAutomat)
	Local cCadastro  := "Dados de Preenchimento do Sisdeclara"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg    := "VAXLS23"
	u_logId ()

	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo gerar uma")
		AADD(aSays," planilha excel com dados de Preenchimento do Sisdeclara.")
		
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
	local _sAliasQ   := ""
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.
	private N        := 0

	procregua (10)
	      
	// Busca lista de 'candidatos'.                           
	_oSQL := ClsSQL():New ()            
    _oSQL:_sQuery += " WITH C AS ( "
    _oSQL:_sQuery += "               SELECT V.DOC AS NF,   "
    _oSQL:_sQuery += "                      SUBSTRING(V.EMISSAO, 7, 2) + "  
    _oSQL:_sQuery += "                      '/'  +  SUBSTRING(V.EMISSAO, 5, 2) + '/' +" 
    _oSQL:_sQuery += "                      SUBSTRING(V.EMISSAO, 1, 4) AS EMISSAO, SERIE, "
    _oSQL:_sQuery += "                      RTRIM(ZX5_39.ZX5_39DESC) AS LINHA,  "
    _oSQL:_sQuery += "                      CASE SB1.B1_VACOR                  "
    _oSQL:_sQuery += "                           WHEN 'T' THEN 'TINTO'         "
    _oSQL:_sQuery += "                           WHEN 'B' THEN 'BRANCO'        "
    _oSQL:_sQuery += "                           WHEN 'R' THEN 'ROSE'          "
    _oSQL:_sQuery += "                           ELSE '?'                      "
    _oSQL:_sQuery += "                      END AS COR,                        "
    _oSQL:_sQuery += "                      RTRIM(ZX5_32.ZX5_32DESC) AS TIPO,   "
    _oSQL:_sQuery += "                      RTRIM(V.PRODUTO) AS CODIGO,        "
    _oSQL:_sQuery += "                      RTRIM(B1_DESC) AS DESCRICAO,       "
    _oSQL:_sQuery += "                      RTRIM(ZX5_50.ZX5_DESCRI) AS EMBALAGEM, "
    _oSQL:_sQuery += "                      V.QTLITROS AS LITRAGEM,            "
    _oSQL:_sQuery += "                      A1_EST AS ESTADO,                  "
    _oSQL:_sQuery += "                      F2_VAGUIA GUIA,                    "
    _oSQL:_sQuery += "                      CASE F4_VASITO                     "
    _oSQL:_sQuery += "                          WHEN ' ' THEN '99'             "
    _oSQL:_sQuery += "                          ELSE F4_VASITO                 "
    _oSQL:_sQuery += "                      END AS COD_OPERACAO,               "
    _oSQL:_sQuery += "                      CASE F4_VASITO                     "
    _oSQL:_sQuery += "                          WHEN ' ' THEN 'SEM DESCRICAO'  "
    _oSQL:_sQuery += "                          ELSE ZX557.ZX5_57DESC          "
    _oSQL:_sQuery += "                      END AS DESCR_OPER                  "
    _oSQL:_sQuery += "               FROM " +  RetSQLName ("SB5") + " SB5, "
    _oSQL:_sQuery += "                    " +  RetSQLName ("SB1") + " SB1 "

    _oSQL:_sQuery += "                      LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_39 "
    _oSQL:_sQuery += "                           ON  (                                         "
    _oSQL:_sQuery += "                                   ZX5_39.D_E_L_E_T_ = ''                "
    _oSQL:_sQuery += "                                   AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
    _oSQL:_sQuery += "                                   AND ZX5_39.ZX5_TABELA = '39'           "
    _oSQL:_sQuery += "                                   AND ZX5_39.ZX5_39COD = SB1.B1_CODLIN   "
    _oSQL:_sQuery += "                               )                                         "
    
    _oSQL:_sQuery += "                      LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_50 "
    _oSQL:_sQuery += "                           ON  (                                         "
    _oSQL:_sQuery += "                                   ZX5_50.D_E_L_E_T_ = ''                "
    _oSQL:_sQuery += "                                   AND ZX5_50.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
    _oSQL:_sQuery += "                                   AND ZX5_50.ZX5_TABELA = '50'           "
    _oSQL:_sQuery += "                                   AND ZX5_50.ZX5_50COD  = SB1.B1_GRPEMB   "
    _oSQL:_sQuery += "                               ),                                        "
    _oSQL:_sQuery +=                        RetSQLName ("SA1") + " SA1, "
    _oSQL:_sQuery +=                        RetSQLName ("SF2") + " SF2, "
    _oSQL:_sQuery +=                        RetSQLName ("SF4") + " SF4  "

    _oSQL:_sQuery += "                   LEFT JOIN " + RetSQLName("ZX5") + " ZX557      "
    _oSQL:_sQuery += "                          ON  (                                   "
    _oSQL:_sQuery += "                                ZX557.D_E_L_E_T_ = ''             "
    _oSQL:_sQuery += "                            AND ZX557.ZX5_FILIAL  = '" + xfilial ("ZX5") + "'"
    _oSQL:_sQuery += "                            AND ZX557.ZX5_TABELA = '57'            "
    _oSQL:_sQuery += "                            AND ZX557.ZX5_CHAVE = SF4.F4_VASITO    "
    _oSQL:_sQuery += "                                 ),                               "
    _oSQL:_sQuery +=                        RetSQLName ("ZX5") + " ZX5_32, "
    _oSQL:_sQuery += "                      BI_ALIANCA.dbo.VA_FATDADOS AS V "
    _oSQL:_sQuery += "                      LEFT JOIN " + RetSQLName ("SA3") + " SA3 "
    _oSQL:_sQuery += "                           ON  (                                       "
    _oSQL:_sQuery += "                                   SA3.D_E_L_E_T_ != '*'               "
    _oSQL:_sQuery += "                                   AND SA3.A3_FILIAL = '  '            "
    _oSQL:_sQuery += "                                   AND SA3.A3_COD = V.VEND1            "
    _oSQL:_sQuery += "                               )                                       "
    _oSQL:_sQuery += "                      LEFT JOIN " + RetSQLName ("SA4") + " SA4 "
    _oSQL:_sQuery += "                           ON  (                                       "
    _oSQL:_sQuery += "                                   SA4.D_E_L_E_T_ != '*'               "
    _oSQL:_sQuery += "                                   AND SA4.A4_FILIAL = '  '            "
    _oSQL:_sQuery += "                                   AND SA4.A4_COD = V.TRANSP           "
    _oSQL:_sQuery += "                               )                                       "
    _oSQL:_sQuery += "               WHERE  SB5.D_E_L_E_T_ != '*' "
    _oSQL:_sQuery += "                      AND SB5.B5_FILIAL = '  ' "
    _oSQL:_sQuery += "                      AND SB5.B5_COD = SB1.B1_COD "
    _oSQL:_sQuery += "                      AND SB1.D_E_L_E_T_ != '*'                            "
    _oSQL:_sQuery += "                      AND SB1.B1_FILIAL = '  '                         "
    _oSQL:_sQuery += "                      AND SB1.B1_COD = V.PRODUTO                       "
    _oSQL:_sQuery += "                      AND SA1.D_E_L_E_T_ != '*'                        "
    _oSQL:_sQuery += "                      AND SF4.F4_FILIAL = '" + xfilial ("SF4") + "'"
    _oSQL:_sQuery += "                      AND SF4.F4_CODIGO = V.TES                        "
    _oSQL:_sQuery += "                      AND SA1.A1_FILIAL = '  '                         "
    _oSQL:_sQuery += "                      AND SA1.A1_COD = V.CLIENTE                       "
    _oSQL:_sQuery += "                      AND SA1.A1_LOJA = V.LOJA                         "
    _oSQL:_sQuery += "                      AND SF2.F2_FILIAL = V.FILIAL                     "
    _oSQL:_sQuery += "                      AND SF2.F2_DOC = V.DOC                           "
    _oSQL:_sQuery += "                      AND SF2.F2_SERIE = V.SERIE                       "
    _oSQL:_sQuery += "                      AND V.ORIGEM = 'SD2'                             "
    _oSQL:_sQuery += "                      AND V.TIPONFSAID != 'B'                          "
    _oSQL:_sQuery += "                      AND V.TIPONFSAID != 'D'                          "
    _oSQL:_sQuery += "                      AND V.F4_MARGEM       IN ('1', '3')              "
    _oSQL:_sQuery += "                      AND V.EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _oSQL:_sQuery += "                      AND V.FILIAL = '" + xfilial ("SD2") + "'"
    _oSQL:_sQuery += "                      AND V.EMPRESA = '01'                            "
    _oSQL:_sQuery += "                      AND ZX5_32.D_E_L_E_T_ = ''                      "
    _oSQL:_sQuery += "                      AND ZX5_32.ZX5_FILIAL = '  '                     "
    _oSQL:_sQuery += "                      AND ZX5_32.ZX5_TABELA = '32'                     "
    _oSQL:_sQuery += "                      AND ZX5_32.ZX5_32COD  = SB5.B5_VACPSIS "
    _oSQL:_sQuery += "           )          "
    _oSQL:_sQuery += " SELECT EMISSAO,      "
    _oSQL:_sQuery += "        ESTADO,       "
    _oSQL:_sQuery += "        NF,           "
    _oSQL:_sQuery += "        SERIE,        "
    _oSQL:_sQuery += "        LINHA,        "
    _oSQL:_sQuery += "        COR,          "
    _oSQL:_sQuery += "        TIPO,         "
    _oSQL:_sQuery += "        EMBALAGEM,    "
    _oSQL:_sQuery += "        CODIGO,       "
    _oSQL:_sQuery += "        DESCRICAO,    "
    _oSQL:_sQuery += "        COD_OPERACAO, "
    _oSQL:_sQuery += "        DESCR_OPER,   "
    _oSQL:_sQuery += "        GUIA,         "
    _oSQL:_sQuery += "        SUM(LITRAGEM) AS LITROS   "
    _oSQL:_sQuery += " FROM   C             "
    _oSQL:_sQuery += " GROUP BY             "
    _oSQL:_sQuery += "        EMISSAO,      "
    _oSQL:_sQuery += "        ESTADO,       "
    _oSQL:_sQuery += "        NF,           "
    _oSQL:_sQuery += "        SERIE,        "
    _oSQL:_sQuery += "        LINHA,        "
    _oSQL:_sQuery += "        COR,          "
    _oSQL:_sQuery += "        TIPO,         "
    _oSQL:_sQuery += "        EMBALAGEM,    "
    _oSQL:_sQuery += "        CODIGO,       "
    _oSQL:_sQuery += "        DESCRICAO,    "
    _oSQL:_sQuery += "        COD_OPERACAO, "
    _oSQL:_sQuery += "        DESCR_OPER,   "
    _oSQL:_sQuery += "        GUIA          "
    _oSQL:_sQuery += " ORDER BY             "
    _oSQL:_sQuery += "        EMISSAO,      "
    _oSQL:_sQuery += "        ESTADO,       "
    _oSQL:_sQuery += "        NF,           "
    _oSQL:_sQuery += "        SERIE,        "
    _oSQL:_sQuery += "        LINHA,        "
    _oSQL:_sQuery += "        COR,          "
    _oSQL:_sQuery += "        TIPO,         "
    _oSQL:_sQuery += "        EMBALAGEM,    "
    _oSQL:_sQuery += "        CODIGO,       "
    _oSQL:_sQuery += "        DESCRICAO,    "
    _oSQL:_sQuery += "        COD_OPERACAO, "
    _oSQL:_sQuery += "        DESCR_OPER,   "
    _oSQL:_sQuery += "        GUIA          "

	u_log (_oSQL:_squery)
	_sAliasQ = _oSQL:Qry2Trb ()

	if ! (_sAliasQ) -> (eof ())
		incproc ("Gerando arquivo de exportacao")
    	processa ({ || U_Trb2XLS (_sAliasQ)})
		
	else
		u_help ("Nao ha dados gerados.")
	endif

return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()                                             
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID           F3   Opcoes          Help
	aadd (_aRegsPerg, {01, "Data incial                    ", "D", 8,  0,  ""           , "",  {}             , ""})
	aadd (_aRegsPerg, {02, "Data final                     ", "D", 8,  0,  ""           , "",  {}             , ""})


	U_ValPerg (cPerg, _aRegsPerg)
Return
