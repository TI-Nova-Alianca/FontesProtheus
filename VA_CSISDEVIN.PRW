//  Programa...: VA_CSISDEVIN
//  Autor......: Catia Cardoso
//  Data.......: 12/02/2019
//  Descricao..: Consulta Notas - SISDEVIN 
// 
//  Historico de alterações
//  04/03/2019  - Alteracao para que possa consulta a notas de entrada ou de saida atraves dessa tela
//  04/03/2019  - Alterado o parametro das OPS p/Lista OPs SIM OU NAO - antes listava sempre e ficava muito lento
//  04/03/2019  - Alterado para considerar so a filial atual do menu - pq senao ficava muito demorado
//  04/03/2019  - incluida a coluna de litragem
//  04/03/2019  - incluida a coluna de data de inclusao da nota
//  29/06/2020  - Cláudia - Incluida mensagem de processamento do relatorio
// -----------------------------------------------------------------------------------------

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_CSISDEVIN()

	cPerg   := "VA_CSISDEVIN"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	if Pergunte(cPerg,.T.) 
		MsgRun("Aguarde o processamento...", "Consulta Notas por cliente/fornecedor - SISDEVIN", {|| _ExecQuery()}) 	
	endif
return
// --------------------------------------------------------------------------
// Executa consulta principal
static function _ExecQuery()
	local _sQuery := ""
    
	_sQuery += "WITH C AS ("
	_sQuery += "	SELECT SD2.D2_FILIAL AS FILIAL"
	_sQuery += "		, 'SAIDA' AS OPERACAO"
	_sQuery += "	    , SD2.D2_TIPO   AS TP_NOTA"
	_sQuery += "		, SD2.D2_DOC    AS NOTA"
	_sQuery += "		, SD2.D2_SERIE  AS SERIE"
	_sQuery += "		, dbo.VA_DTOC(SD2.D2_EMISSAO) AS DATA"
	_sQuery += "	    , dbo.VA_DTOC(SD2.D2_EMISSAO) AS DT_INC"
	_sQuery += "		, SD2.D2_CLIENTE AS COD_CLIFOR"
	_sQuery += "		, IIF(SD2.D2_TIPO = 'N', SA1.A1_NOME, SA2.A2_NOME) AS NOME"
	_sQuery += "		, SD2.D2_COD    AS PRODUTO"
	_sQuery += "		, SB1.B1_DESC   AS DESCRICAO"
	_sQuery += "		, SB1.B1_TIPO   AS TIPO_PROD"
	_sQuery += "		, SD2.D2_GRUPO  AS GRUPO"
	_sQuery += "		, SB5.B5_VASISDE AS SISDEVIN"
	_sQuery += "		, CASE  WHEN SD2.D2_FILIAL = '01' THEN SB5.B5_VACSD01"
    _sQuery += "    			WHEN SD2.D2_FILIAL = '03' THEN SB5.B5_VACSD03"
    _sQuery += "    			WHEN SD2.D2_FILIAL = '07' THEN SB5.B5_VACSD07"
    _sQuery += "    			WHEN SD2.D2_FILIAL = '08' THEN SB5.B5_VACSD08"
	_sQuery += "				WHEN SD2.D2_FILIAL = '09' THEN SB5.B5_VACSD09"
    _sQuery += "    			WHEN SD2.D2_FILIAL = '10' THEN SB5.B5_VACSD10"
	_sQuery += "    			WHEN SD2.D2_FILIAL = '12' THEN SB5.B5_VACSD12"
	_sQuery += "				WHEN SD2.D2_FILIAL = '13' THEN SB5.B5_VACSD13"
    _sQuery += "		  ELSE 'SEM CODIGO CR' END AS CODIGO_CR"
    _sQuery += "		, SD2.D2_QUANT  AS QUANT"
    _sQuery += "		, ROUND(SD2.D2_QUANT * B1_LITROS,2) AS LITRAGEM"
    _sQuery += "		, SD2.D2_TES    AS TES"
    _sQuery += "		, SF4.F4_TEXTO  AS TIPO_OPERACAO"
    _sQuery += "		, SF4.F4_VASISDE  AS SIS_GRANEL"
    _sQuery += "		, SX5Z8.X5_DESCRI AS GRAVEL_DESCR"
    _sQuery += "		, SF4.F4_VASISEN  AS SIS_ENVASE"
    _sQuery += "		, SX5ZE.X5_DESCRI AS ENVASE_DESCR"
    _sQuery += "		, SD2.D2_NFORI   AS NF_ORIG"
    _sQuery += "		, SD2.D2_SERIORI AS SERIE_ORIG"
    _sQuery += "		, ''      AS OP"
    _sQuery += "	 FROM SD2010 AS SD2"
	_sQuery += "		INNER JOIN SB1010 AS SB1"
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SB1.B1_COD = SD2.D2_COD)"
	_sQuery += "		INNER JOIN SB5010 AS SB5"
	_sQuery += "			ON (SB5.D_E_L_E_T_ = ''"
	_sQuery += "				AND SB5.B5_COD = SD2.D2_COD)"
	_sQuery += "		INNER JOIN SF4010 AS SF4"
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO = SD2.D2_TES)"
	_sQuery += "		LEFT JOIN SX5010 AS SX5ZE"
	_sQuery += "			ON (SX5ZE.D_E_L_E_T_    = ''"
	_sQuery += "	    		AND SX5ZE.X5_TABELA = 'ZE'"
	_sQuery += "				AND SX5ZE.X5_CHAVE  =  SF4.F4_VASISEN)"
	_sQuery += "		LEFT JOIN SX5010 AS SX5Z8"
	_sQuery += "			ON (SX5Z8.D_E_L_E_T_    = ''"
	_sQuery += "	    		AND SX5Z8.X5_TABELA = 'Z8'" 
	_sQuery += "				AND SX5Z8.X5_CHAVE  =  SF4.F4_VASISDE)" 
	_sQuery += "		LEFT JOIN SA1010 AS SA1"
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD = SD2.D2_CLIENTE"
	_sQuery += "				AND SA1.A1_LOJA   = SD2.D2_LOJA)"
	_sQuery += "		LEFT JOIN SA2010 AS SA2"
	_sQuery += "			ON (SA2.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA2.A2_COD = SD2.D2_CLIENTE"
	_sQuery += "				AND SA2.A2_LOJA   = SD2.D2_LOJA)"					
	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"
	_sQuery += "	AND SD2.D2_FILIAL  = '" + xFilial("SD2") + "'"
	_sQuery += "	AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "	AND SD2.D2_CLIENTE BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	_sQuery += "    AND SD2.D2_COD BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
	_sQuery += " UNION ALL"
	_sQuery += " SELECT SD1.D1_FILIAL AS FILIAL"
	_sQuery += "	  , 'ENTRADA    ' AS OPERACAO"
	_sQuery += "	  , SD1.D1_TIPO   AS TP_NOTA"
	_sQuery += "	  , SD1.D1_DOC    AS NOTA"
	_sQuery += "	  , SD1.D1_SERIE  AS SERIE"
	_sQuery += "	  , dbo.VA_DTOC(SD1.D1_DTDIGIT) AS DATA"
	_sQuery += "	  , (SELECT dbo.VA_DTOC(SF1.F1_VADTINC)"
	_sQuery += "		   FROM SF1010 AS SF1
	_sQuery += "          WHERE SF1.F1_FILIAL  = SD1.D1_FILIAL
	_sQuery += "            AND SF1.D_E_L_E_T_ = ''"
	_sQuery += "            AND SF1.F1_DOC     = SD1.D1_DOC
	_sQuery += "            AND SF1.F1_SERIE   = SD1.D1_SERIE
	_sQuery += "            AND SF1.F1_FORNECE = SD1.D1_FORNECE
	_sQuery += "            AND SF1.F1_LOJA    = SD1.D1_LOJA) AS DT_INC"
	_sQuery += "      , SD1.D1_FORNECE AS COD_CLIFOR"
	_sQuery += "      , IIF(SD1.D1_TIPO = 'N', SA2.A2_NOME, SA1.A1_NOME) AS NOME"
	_sQuery += "	  , SD1.D1_COD     AS PRODUTO"
	_sQuery += "	  , SB1.B1_DESC    AS DESCRICAO"
	_sQuery += "	  , SB1.B1_TIPO    AS TIPO_PROD"
	_sQuery += "	  , SD1.D1_GRUPO   AS GRUPO"
	_sQuery += "	  , SB5.B5_VASISDE AS SISDEVIN"
	_sQuery += "	  , CASE WHEN SD1.D1_FILIAL = '01' THEN SB5.B5_VACSD01"
    _sQuery += "    		 WHEN SD1.D1_FILIAL = '03' THEN SB5.B5_VACSD03"
    _sQuery += "   			 WHEN SD1.D1_FILIAL = '07' THEN SB5.B5_VACSD07"
    _sQuery += "    		 WHEN SD1.D1_FILIAL = '08' THEN SB5.B5_VACSD08"
	_sQuery += "			 WHEN SD1.D1_FILIAL = '09' THEN SB5.B5_VACSD09"
    _sQuery += "    		 WHEN SD1.D1_FILIAL = '10' THEN SB5.B5_VACSD10"
	_sQuery += "       		 WHEN SD1.D1_FILIAL = '12' THEN SB5.B5_VACSD12"
	_sQuery += "			 WHEN SD1.D1_FILIAL = '13' THEN SB5.B5_VACSD13"
    _sQuery += "		ELSE 'SEM CODIGO CR' END AS CODIGO_CR"
    _sQuery += "	 , SD1.D1_QUANT    AS QUANT"
    _sQuery += "	 , ROUND(SD1.D1_QUANT * B1_LITROS,2) AS LITRAGEM"
    _sQuery += "	 , SD1.D1_TES      AS TES"
    _sQuery += "	 , SF4.F4_TEXTO    AS TIPO_OPERACAO"
    _sQuery += "	 , SF4.F4_VASISDE  AS SIS_GRANEL"
    _sQuery += "	 , SX5Z8.X5_DESCRI AS GRANEL_DESCR"
    _sQuery += "	 , SF4.F4_VASISEN  AS SIS_ENVASE"
    _sQuery += "	 , SX5ZE.X5_DESCRI AS ENVASE_DESCR"
    _sQuery += "	 , SD1.D1_NFORI    AS NF_ORIG"
    _sQuery += "	 , SD1.D1_SERIORI  AS SERIE_ORIG"
    _sQuery += "	 , SD1.D1_OP       AS OP"
    _sQuery += "  FROM SD1010 AS SD1"
	_sQuery += "	INNER JOIN SB1010 AS SB1"
	_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "			AND SB1.B1_COD = SD1.D1_COD)"
	_sQuery += "	INNER JOIN SB5010 AS SB5"
	_sQuery += "		ON (SB5.D_E_L_E_T_ = ''"
	_sQuery += "			AND SB5.B5_COD = SD1.D1_COD)"
	_sQuery += "	LEFT JOIN SF4010 AS SF4"
	_sQuery += "		ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "			AND SF4.F4_CODIGO = SD1.D1_TES)"
	_sQuery += "	LEFT JOIN SX5010 AS SX5ZE"
	_sQuery += "		ON (SX5ZE.D_E_L_E_T_    = ''"
	_sQuery += "	    	AND SX5ZE.X5_TABELA = 'ZE'" 
	_sQuery += "		AND SX5ZE.X5_CHAVE  =  SF4.F4_VASISEN)"
	_sQuery += "	LEFT JOIN SX5010 AS SX5Z8"
	_sQuery += "		ON (SX5Z8.D_E_L_E_T_    = ''"
	_sQuery += "	    	AND SX5Z8.X5_TABELA = 'Z8'" 
	_sQuery += "			AND SX5Z8.X5_CHAVE  =  SF4.F4_VASISDE)"
	_sQuery += "	LEFT JOIN SA1010 AS SA1"
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "			AND SA1.A1_COD = SD1.D1_FORNECE"
	_sQuery += "			AND SA1.A1_LOJA   = SD1.D1_LOJA)"
	_sQuery += "	LEFT JOIN SA2010 AS SA2"
	_sQuery += "		ON (SA2.D_E_L_E_T_ = ''"
	_sQuery += "			AND SA2.A2_COD = SD1.D1_FORNECE"
	_sQuery += "			AND SA2.A2_LOJA   = SD1.D1_LOJA)" 
	_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += "	AND SD1.D1_FILIAL  = '" + xFilial("SD1") + "'"
	_sQuery += "    AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD1.D1_FORNECE BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	_sQuery += "    AND SD1.D1_COD BETWEEN '" + mv_par05 + "' and '" + mv_par06 + "'"
	if mv_par08 = 2
		_sQuery += "    UNION ALL"
		_sQuery += "    SELECT SD3.D3_FILIAL AS FILIAL"
		_sQuery += "    	 , 'PRODUCAO'    AS OPERACAO"
		_sQuery += "    	 , '' AS TP_NOTA"
		_sQuery += "    	 , '' AS NOTA"
		_sQuery += "    	 , '' AS SERIE"
		_sQuery += "    	 , dbo.VA_DTOC(SD3.D3_EMISSAO) AS DATA"
		_sQuery += "    	 , dbo.VA_DTOC(SD3.D3_EMISSAO) AS DT_INC"
		_sQuery += "    	 , '' AS COD_CLI"
		_sQuery += "    	 , '' AS NOME"
		_sQuery += "    	 , SD3.D3_COD   AS PRODUTO"
		_sQuery += "    	 , SB1.B1_DESC  AS DESCRICAO"
		_sQuery += "    	 , SD3.D3_TIPO  AS TIPO_PROD"
		_sQuery += "    	 , SD3.D3_GRUPO AS GRUPO"
		_sQuery += "    	 , SB5.B5_VASISDE AS SISDEVIN"
		_sQuery += "    	 , CASE"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '01' THEN SB5.B5_VACSD01"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '03' THEN SB5.B5_VACSD03"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '07' THEN SB5.B5_VACSD07"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '08' THEN SB5.B5_VACSD08"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '09' THEN SB5.B5_VACSD09"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '10' THEN SB5.B5_VACSD10"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '12' THEN SB5.B5_VACSD12"
		_sQuery += "    		WHEN SD3.D3_FILIAL = '13' THEN SB5.B5_VACSD13"
		_sQuery += "    	 ELSE 'SEM CODIGO CR'"
		_sQuery += "    	 END AS CODIGO_CR"
		_sQuery += "    	, SD3.D3_QUANT AS QUANT"
		_sQuery += "	    , ROUND(SD3.D3_QUANT * B1_LITROS,2) AS LITRAGEM"
		_sQuery += "    	, '' AS TES"
		_sQuery += "    	, 'PRODUCAO ESTABELECIMENTO' AS TIPO_OPERACAO"
		_sQuery += "    	, '' AS SIS_GRANEL"
		_sQuery += "    	, '' AS GRANEL_DESCR"
		_sQuery += "    	, '' AS SIS_ENVASE"
		_sQuery += "    	, '' AS ENVASE_DESCR"
		_sQuery += "    	, '' AS NF_ORIG"
		_sQuery += "    	, '' AS SERIE_ORIG"
		_sQuery += "    	, SD3.D3_OP AS OP"
		_sQuery += "    FROM SD3010 AS SD3"
		_sQuery += "    	LEFT JOIN SB5010 AS SB5"
		_sQuery += "    		ON (SB5.D_E_L_E_T_ = ''"
		_sQuery += "    			AND SB5.B5_COD    = SD3.D3_COD)"
		_sQuery += "    	INNER JOIN SB1010 AS SB1"
		_sQuery += "    		ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "    			AND SB1.B1_COD = SD3.D3_COD)"
		_sQuery += "   WHERE SD3.D3_CF   LIKE 'PR%'"
		_sQuery += "	 AND SD3.D3_FILIAL  = '" + xFilial("SD3") + "'"
		_sQuery += "     AND SD3.D3_TIPO    = 'PA'"
		_sQuery += "     AND SD3.D3_EMISSAO  BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "     AND SD3.D_E_L_E_T_ = ''"
	endif	
	_sQuery += "    )"
	_sQuery += " SELECT *"
	_sQuery += " FROM C"
	IF mv_par07 == 2
		_sQuery += " WHERE C.SISDEVIN = 'S'"
	ENDIF
	_sQuery += " ORDER BY C.FILIAL, C.DATA, C.NOTA, C.SERIE"
	
	_aDados := U_Qry2Array(_sQuery)
	if len(_aDados) > 0 
		
		do while .t.
    		_aCols = {}
    		
    		aadd (_aCols, { 1, "Filial"         	,  30,  "@!"})
    		aadd (_aCols, { 2, "Operação"       	,  30,  "@!"})
    		aadd (_aCols, { 3, "Tp Nota"       	    ,  30,  "@!"})
    		aadd (_aCols, { 4, "Num.Nota"       	,  30,  "@!"})
	    	aadd (_aCols, { 5, "Serie"         	    ,  10,  "@!"})
	    	aadd (_aCols, { 6, "Data Mov."          ,  30,  "@D"})
	    	aadd (_aCols, { 7, "Data Inclusao"      ,  30,  "@D"})
	    	aadd (_aCols, { 8, "Cliente/Fornecedor" ,  30,  "@!"})
	    	aadd (_aCols, { 9, "Razão Social"   	, 150,  "@!"})
	    	aadd (_aCols, {10, "Produto"            ,  30,  "@!"})
	    	aadd (_aCols, {11, "Descricao"          , 140,  "@!"})
	    	aadd (_aCols, {12, "Tp.Produto"         ,  30,  "@!"})
	    	aadd (_aCols, {13, "Grupo"              ,  30,  "@!"})
	    	aadd (_aCols, {14, "SISDEVIN"           ,  30,  "@!"})
	    	aadd (_aCols, {15, "Codigo CR"          ,  40,  "@!"})
			aadd (_aCols, {16, "Quant NF"           ,  50,  "@E 9,999,999.9999"})
			aadd (_aCols, {17, "Litragem"           ,  50,  "@E 9,999,999.9999"})
			aadd (_aCols, {18, "TES"           	    ,  30,  "@!"})
			aadd (_aCols, {19, "Descricao TES" 	    ,  30,  "@!"})
	        aadd (_aCols, {20, "SIS-Granel"         ,  30,  "@!"})
	        aadd (_aCols, {21, "Descricao"          ,  30,  "@!"})
	    	aadd (_aCols, {22, "SIS-Envasado"       ,  30,  "@!"})
	    	aadd (_aCols, {23, "Descricao"          ,  30,  "@!"})
	    	aadd (_aCols, {24, "NF Origem"          ,  30,  "@!"})
	    	aadd (_aCols, {25, "Serie Origem"       ,  30,  "@!"})
	    	aadd (_aCols, {26, "OP Associada a NF"  ,  30,  "@!"})
	    	
	    	_wlinha = U_F3Array (_aDados, "Consulta Notas por cliente/fornecedor - SISDEVIN", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
				
	    	if _wlinha > 0
    			_ConsNotas( _aDados[_wlinha,2], _aDados[_wlinha,4], _aDados[_wlinha,5], _aDados[_wlinha,8] )
 	    	else
 	    		exit
 	    	endif	
	    enddo	
	else
		u_help("Não foram encontrados dados para consulta")
	endif    		
return
// --------------------------------------------------------------------------
// Consulta detalhes da movimentacao.
static function _ConsNotas (_wtpNF, _wDoc, _wSerie, _wClifor)
	// Variaveis para a rotina de visualizacao da nota.
	Private aRotina    := {{ , , 0 , 2 }}
	Private l103Auto   := .F.
	Private aAutoCab   := {}
	Private aAutoItens := {}

	do case
	   case _wTPNF = 'SAIDA'
			sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			if sf2 -> (dbseek (xfilial ("SF2") + _wDoc + _wSerie + _wClifor + '01', .F.))
				Mc090Visual ("SF2", recno (), 1)
			else
				u_help ("NF '" + _wDoc + "' nao encontrada.")
			endif
		case  _wTPNF = 'ENTRADA'
			sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
			if sf1 -> (dbseek (xfilial ("SF1") + _wDoc + _wSerie + _wClifor + '01', .F.))
				A103NFiscal ('SF1', recno (), 1)
			else
				u_help ("NF '" + _wDoc + "' nao encontrada.")
			endif
	endcase
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Emissao de            ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Emissao até           ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Cliente/Fornecedor    ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {04, "Cliente/Forneceodr    ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {05, "Produto de            ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {06, "Produto até           ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {07, "Apenas itens SISDEVIN ?", "N", 1, 0,  "",   "   ", {"Nao", "Sim"}, ""})
	aadd (_aRegsPerg, {08, "Lista OP's            ?", "N", 1, 0,  "",   "   ", {"Nao", "Sim"}, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
