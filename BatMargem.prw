// Programa...: BatMargem
// Autor......: claudia Lion�o
// Data.......: 11/11/2021
// Descricao..: Bat criada para gerar tabela VA_RENTABILIDADE para consulta no Mercanet.
//
// Tipos de margem 
// 1=COMP/VEND;
// 2=Devolucao;
// 3=Bonificacao;
// 4=Comodato;
// 5=Ret.comodato;
// 6=Frete;
// 7=Servicos;
// 8=Uso e Consumo;
// 9=Outros   
//
// Historico de alteracoes:
// 09/05/2022 - Claudia - Ajustado para n�o dropar mais a tabela. GLPI: 11967
// 10/05/2022 - Claudia - Alterado campo de peso bruto para B1_PESBRU. GLPI: 11822
// 19/06/2022 - Robert  - Criados campos NF_LITROS e NF_QTCAIXAS (GLPI 12223)
// 20/07/2022 - Claudia - Ajustado o numero de dias de execu��o.
// 07/02/2023 - Claudia - Alterada a regra do ICMSRET. GLPI: 13155
//
// -----------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function BatMargem(_nTipo)
    local _oSQL   := NIL
	local _sSQL   := ""
	Private cPerg := "BatRentab"
	
	If _nTipo != 1
		u_help("Atualiza tabela VA_RENTABILIDADE")
		If ! u_zzuvl ('097', __cUserId, .T.)
			u_help ("Usu�rio sem permiss�o para usar estar rotina")
			Return
		Endif

		// Somente uma estacao por vez, pois a rotina eh pesada e certos usuarios derrubam o client na estacao e mandam rodar novamente...
		_nLock := U_Semaforo (procname ())
		If _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			Return
		Endif
	EndIf
	
	If _nTipo == 1
		_QtdDias := 90
		_dDtIni  := DTOS(DaySub( Date() , _QtdDias))
		_dDtFin  := DTOS( Date() )
	Else
		_ValidPerg()
		If Pergunte(cPerg,.T.)
			_dDtIni := DTOS(mv_par01)
			_dDtFin := DTOS(mv_par02)
		Else
			Return
		EndIf
	EndIf
	
	
	u_logIni ()
	_sErroAuto := ''  // Para a funcao u_help gravar mensagens
	
	_sSQL := " DELETE FROM BI_ALIANCA.dbo.VA_RENTABILIDADE" 
	_sSQL += " WHERE EMISSAO BETWEEN '"+ _dDtIni +"' AND '"+ _dDtFin +"'"
	u_log (_sSQL)

    If TCSQLExec (_sSQL) < 0
		if type ('_oBatch') == 'O'
			_oBatch:Mensagens += 'Erro ao limpar tabela VA_RENTABILIDADE'
			_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
		else
			u_help ('Erro ao limpar tabela VA_RENTABILIDADE',, .t.)
		endif
	Else
        _oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " 		INSERT INTO BI_ALIANCA.dbo.VA_RENTABILIDADE "
        _oSQL:_sQuery += " (TIPO,FILIAL,CLIENTE,LOJA,C_BASE,L_BASE,NOTA,SERIE,EMISSAO,ESTADO,VENDEDOR,LINHA,PRODUTO "
		_oSQL:_sQuery += " ,CUSTO_PREV,CUSTO_REAL,NF_QUANT,NF_VLRUNIT,NF_VLRPROD,NF_VALIPI,NF_ICMSRET,NF_VLR_BRT "
		_oSQL:_sQuery += " ,NF_ICMS,NF_COFINS,NF_PIS,VLR_COMIS_PREV,VLR_COMIS_REAL,TOTPROD_NF,FRETE_PREVISTO "
		_oSQL:_sQuery += " ,FRETE_REALIZADO,RAPEL_PREVISTO,RAPEL_REALIZADO,SUPER,VERBAS_UTIL,VERBAS_LIB,CODMUN,PROMOTOR "
		_oSQL:_sQuery += " ,NF_LITROS, NF_QTCAIXAS) "
		_oSQL:_sQuery += " (SELECT "
		_oSQL:_sQuery += " 	SF4.F4_MARGEM AS TIPO "
		_oSQL:_sQuery += "    ,SD2.D2_FILIAL AS FILIAL "
		_oSQL:_sQuery += "    ,SD2.D2_CLIENTE AS CLIENTE "
		_oSQL:_sQuery += "    ,SD2.D2_LOJA AS LOJA "
		_oSQL:_sQuery += "    ,SA1.A1_VACBASE AS C_BASE "
		_oSQL:_sQuery += "    ,SA1.A1_VALBASE AS L_BASE "
		_oSQL:_sQuery += "    ,SD2.D2_DOC AS NOTA "
		_oSQL:_sQuery += "    ,SD2.D2_SERIE AS SERIE "
		_oSQL:_sQuery += "    ,SD2.D2_EMISSAO AS EMISSAO "
		_oSQL:_sQuery += "    ,SD2.D2_EST AS ESTADO "
		_oSQL:_sQuery += "    ,SF2.F2_VEND1 AS VENDEDOR "
		_oSQL:_sQuery += "    ,SB1.B1_CODLIN AS LINHA "
		_oSQL:_sQuery += "    ,SD2.D2_COD AS PRODUTO "
		_oSQL:_sQuery += "    ,SUM(ROUND(D2_VACUSTD * SD2.D2_QUANT, 2)) AS CUSTO_PREV  " // PREVISTO
		_oSQL:_sQuery += "    ,SUM(ROUND(D2_CUSTO1, 2)) AS CUSTO_REAL				   " // REALIZADO
		_oSQL:_sQuery += "    ,SUM(SD2.D2_QUANT) AS NF_QUANT "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_PRUNIT) AS NF_VLRUNIT "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_PRCVEN * D2_QUANT) AS NF_VLRPROD "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_VALIPI) AS NF_VALIPI "
		//_oSQL:_sQuery += "    ,SUM(SD2.D2_ICMSRET) AS NF_ICMSRET "
 		_oSQL:_sQuery += "    ,CASE "
		_oSQL:_sQuery += "    		WHEN SF4.F4_CREDST = '4' THEN 0 "
		_oSQL:_sQuery += "    		ELSE SUM(SD2.D2_ICMSRET) "
		_oSQL:_sQuery += "     END AS NF_ICMSRET "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_VALBRUT) AS NF_VLR_BRT "
		_oSQL:_sQuery += "    ,CASE SF4.F4_MARGEM WHEN '1' THEN SUM(SD2.D2_VALICM) END AS NF_ICMS "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_VALIMP5) AS NF_COFINS "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_VALIMP6) AS NF_PIS "
		_oSQL:_sQuery += "    ,SUM(SD2.D2_TOTAL*SD2.D2_COMIS1/100) AS VLR_COMIS_PREV "
		_oSQL:_sQuery += "    ,ISNULL(((SELECT "
		_oSQL:_sQuery += " 			SUM(SE3.E3_COMIS) "
		_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE3") + " SE3 " 
		_oSQL:_sQuery += " 		WHERE SE3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SE3.E3_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 		AND SE3.E3_NUM = SD2.D2_DOC "
		_oSQL:_sQuery += " 		AND SE3.E3_EMISSAO >= SD2.D2_EMISSAO "
		_oSQL:_sQuery += " 		AND SE3.E3_CODCLI = SD2.D2_CLIENTE) "
		_oSQL:_sQuery += " 	* SD2.D2_TOTAL / SF2.F2_VALMERC), '0') AS VLR_COMIS_REAL "
		_oSQL:_sQuery += "    ,SF2.F2_VALMERC AS TOTPROD_NF "
		_oSQL:_sQuery += "    ,ISNULL(CASE SF2.F2_PBRUTO "
		_oSQL:_sQuery += " 		WHEN 0 THEN 0 "
		_oSQL:_sQuery += " 		ELSE ROUND(SC5.C5_MVFRE * (SB1.B1_PESBRU * SD2.D2_QUANT) / SF2.F2_PBRUTO, 2) "		
		_oSQL:_sQuery += " 		END, 0) AS FRETE_PREVISTO "
		_oSQL:_sQuery += "    ,ISNULL((SELECT "
		_oSQL:_sQuery += " 			SUM(SZH.ZH_RATEIO) "
		_oSQL:_sQuery += " 		FROM " + RetSQLName ("SZH") + " SZH "
		_oSQL:_sQuery += " 		WHERE SZH.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SZH.ZH_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 		AND SZH.ZH_TPFRE = 'S' "
		_oSQL:_sQuery += " 		AND SZH.ZH_NFSAIDA = SD2.D2_DOC "
		_oSQL:_sQuery += " 		AND SZH.ZH_SERNFS = SD2.D2_SERIE "
		_oSQL:_sQuery += " 		AND SZH.ZH_ITNFS = SD2.D2_ITEM) "
		_oSQL:_sQuery += " 	, '0') AS FRETE_REALIZADO "
		_oSQL:_sQuery += " 	,SUM(ROUND(SD2.D2_VRAPEL,2))  AS RAPEL_PREVISTO "
		_oSQL:_sQuery += "    ,ISNULL(((SELECT "
		_oSQL:_sQuery += " 			SUM(SE5.E5_VARAPEL) "
		_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " SE5 "
		_oSQL:_sQuery += " 		WHERE SE5.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SE5.E5_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 		AND SE5.E5_NUMERO = SD2.D2_DOC "
		_oSQL:_sQuery += " 		AND SE5.E5_DATA >= SD2.D2_EMISSAO "
		_oSQL:_sQuery += " 		AND SE5.E5_RECPAG = 'R' "
		_oSQL:_sQuery += " 		AND SE5.E5_CLIENTE = SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 		AND SE5.E5_LOJA = SD2.D2_LOJA "
		_oSQL:_sQuery += " 		AND SE5.E5_TIPODOC = 'DC' "
		_oSQL:_sQuery += " 		AND SE5.E5_SITUACA = '' "
		_oSQL:_sQuery += " 		AND SE5.E5_VARAPEL > 0) "
		_oSQL:_sQuery += " 	* SD2.D2_TOTAL / SF2.F2_VALMERC), '') AS RAPEL_REALIZADO "
		_oSQL:_sQuery += "    ,SA3.A3_VAGEREN AS SUPER "
		_oSQL:_sQuery += "    ,0 AS VERBAS_UTIL "
		_oSQL:_sQuery += "    ,0 AS VERBAS_LIB "
		_oSQL:_sQuery += "    ,SA1.A1_COD_MUN AS CODMUN "
		_oSQL:_sQuery += "    ,SA1.A1_VAPROMO AS PROMOTOR"
		_oSQL:_sQuery += "    ,SUM (CASE WHEN SD2.D2_TP IN ('PA', 'PI', 'VD') THEN SD2.D2_QUANT * SB1.B1_LITROS ELSE 0 END) AS NF_LITROS"
		_oSQL:_sQuery += "    ,dbo.VA_FQtCx (SD2.D2_COD, SUM (SD2.D2_QUANT)) AS NF_QTCAIXAS"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SF2.F2_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 			AND SF2.F2_DOC = SD2.D2_DOC "
		_oSQL:_sQuery += " 			AND SF2.F2_SERIE = SD2.D2_SERIE "
		_oSQL:_sQuery += " 			AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 			AND SF2.F2_LOJA = SD2.D2_LOJA "
		_oSQL:_sQuery += " 			AND SF2.F2_EMISSAO = SD2.D2_EMISSAO) "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 	AND SA1.A1_COD = SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 	AND SA1.A1_LOJA = SD2.D2_LOJA) "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " SA3 "
		_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SA3.A3_COD = SF2.F2_VEND1) "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery += " 	ON (SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SF4.F4_MARGEM IN ('1') "
		_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD2.D2_TES) "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SB1.B1_COD = SD2.D2_COD) "
		_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SC5") + " SC5 "
		_oSQL:_sQuery += " 	ON (SC5.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SC5.C5_NUM = SD2.D2_PEDIDO "
		_oSQL:_sQuery += " 			AND SC5.C5_FILIAL = SD2.D2_FILIAL) "
		_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND SD2.D2_EMISSAO BETWEEN '" + _dDtIni + "' AND '" + _dDtFin + "'"
		_oSQL:_sQuery += " GROUP BY SF4.F4_MARGEM "
		_oSQL:_sQuery += " 		,SD2.D2_FILIAL "
		_oSQL:_sQuery += " 		,SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 		,SA1.A1_VACBASE "
		_oSQL:_sQuery += " 		,SA1.A1_VALBASE "
		_oSQL:_sQuery += " 		,SD2.D2_DOC "
		_oSQL:_sQuery += " 		,SD2.D2_SERIE "
		_oSQL:_sQuery += " 		,SD2.D2_EMISSAO "
		_oSQL:_sQuery += " 		,SD2.D2_TOTAL "
		_oSQL:_sQuery += " 		,SF2.F2_VALMERC "
		_oSQL:_sQuery += " 		,SD2.D2_LOJA "
		_oSQL:_sQuery += " 		,SD2.D2_EST "
		_oSQL:_sQuery += " 		,SF2.F2_VEND1 "
		_oSQL:_sQuery += " 		,SD2.D2_ITEM "
		_oSQL:_sQuery += " 		,SA3.A3_VAGEREN "
		_oSQL:_sQuery += " 		,SB1.B1_CODLIN "
		_oSQL:_sQuery += " 		,SD2.D2_COD "
		_oSQL:_sQuery += " 		,SF2.F2_PBRUTO "
		_oSQL:_sQuery += " 		,SC5.C5_MVFRE "
		_oSQL:_sQuery += " 		,SB1.B1_PESBRU "
		_oSQL:_sQuery += " 		,SD2.D2_QUANT "
		_oSQL:_sQuery += " 		,SF2.F2_PBRUTO "
		_oSQL:_sQuery += "      ,SA1.A1_COD_MUN "
		_oSQL:_sQuery += "      ,SA1.A1_VAPROMO "
		_oSQL:_sQuery += "      ,SD2.D2_TP "
		_oSQL:_sQuery += " UNION ALL SELECT "
		_oSQL:_sQuery += " 		SF4.F4_MARGEM AS TIPO "
		_oSQL:_sQuery += " 	   ,SD1.D1_FILIAL AS FILIAL "
		_oSQL:_sQuery += " 	   ,SD1.D1_FORNECE AS CLIENTE "
		_oSQL:_sQuery += " 	   ,SD1.D1_LOJA AS LOJA "
		_oSQL:_sQuery += " 	   ,SA1.A1_VACBASE AS C_BASE "
		_oSQL:_sQuery += " 	   ,SA1.A1_VALBASE AS L_BASE "
		_oSQL:_sQuery += " 	   ,SD1.D1_DOC AS NOTA "
		_oSQL:_sQuery += " 	   ,SD1.D1_SERIE AS SERIE "
		_oSQL:_sQuery += " 	   ,SD1.D1_DTDIGIT AS DIGITACAO "
		_oSQL:_sQuery += " 	   ,SF1.F1_EST AS ESTADO "
		_oSQL:_sQuery += " 	   ,SE1.E1_VEND1 AS VENDEDOR "
		_oSQL:_sQuery += " 	   ,SB1.B1_CODLIN AS LINHA "
		_oSQL:_sQuery += " 	   ,SD1.D1_COD AS PRODUTO "
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(ROUND(SD2.D2_VACUSTD * SD1.D1_QUANT, 2)) * -1, 0) AS CUSTO_PREV " //PREVISTO
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(ROUND(SD1.D1_CUSTO, 2)) * -1, 0) AS CUSTO_REAL  " 				 //REALIZADO
		_oSQL:_sQuery += " 	   ,SUM(SD1.D1_QUANT) * -1 AS NF_QUANT "
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(SD1.D1_VUNIT) * -1, 0) AS NF_VLRUNIT "
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(SD1.D1_VUNIT * D1_QUANT) * -1, 0) AS NF_VLRPROD "
		_oSQL:_sQuery += " 	   ,SUM(SD1.D1_VALIPI) * -1 AS NF_VALIPI "
		//_oSQL:_sQuery += " 	   ,SUM(SD1.D1_ICMSRET) * -1 AS NF_ICMSRET "
		_oSQL:_sQuery += "    ,CASE "
		_oSQL:_sQuery += "    		WHEN SF4.F4_CREDST = '4' THEN 0 "
		_oSQL:_sQuery += "    		ELSE SUM(SD1.D1_ICMSRET) * -1 "
		_oSQL:_sQuery += "      END AS NF_ICMSRET "
		_oSQL:_sQuery += " 	   ,SUM(SD1.D1_TOTAL + SD1.D1_VALIPI + SD1.D1_ICMSRET) * -1 AS NF_VLR_BRT "
		_oSQL:_sQuery += " 	   ,CASE SF4.F4_MARGEM WHEN '2' THEN SUM(SD1.D1_VALICM) * -1 END AS NF_ICMS "
		_oSQL:_sQuery += " 	   ,SUM(SD1.D1_VALIMP5) * -1 AS NF_COFINS "
		_oSQL:_sQuery += " 	   ,SUM(SD1.D1_VALIMP6) * -1 AS NF_PIS "
		_oSQL:_sQuery += " 	   ,SUM((SD2.D2_TOTAL*SD2.D2_COMIS1/100)*SD1.D1_QUANT/SD2.D2_QUANT)*-1 AS VLR_COMIS_PREV "
		_oSQL:_sQuery += " 	   ,0 AS VLR_COMIS_REAL "
		_oSQL:_sQuery += " 	   ,SD1.D1_TOTAL * -1 AS TOTPROD_NF "
		_oSQL:_sQuery += " 	   ,0 AS FRETE_PREVISTO "
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(SZH.ZH_RATEIO), 0) AS FRETE_REALIZADO "
		_oSQL:_sQuery += " 	   ,ISNULL(SUM(SD2.D2_VRAPEL*SD1.D1_QUANT/SD2.D2_QUANT)*-1, 0) AS RAPEL_PREVISTO "
		_oSQL:_sQuery += " 	   ,0 AS RAPEL_REALIZADO "
		_oSQL:_sQuery += " 	   ,SA3.A3_VAGEREN AS SUPER "
		_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTIL "
		_oSQL:_sQuery += "     ,0 AS VERBAS_LIB "
		_oSQL:_sQuery += "     ,SA1.A1_COD_MUN AS CODMUN "
		_oSQL:_sQuery += "     ,SA1.A1_VAPROMO AS PROMOTOR"
		_oSQL:_sQuery += "     ,SUM (CASE WHEN SD1.D1_TP IN ('PA', 'PI', 'VD') THEN SD1.D1_QUANT * SB1.B1_LITROS ELSE 0 END) AS NF_LITROS"
		_oSQL:_sQuery += "     ,dbo.VA_FQtCx (SD1.D1_COD, SUM (SD1.D1_QUANT)) AS NF_QTCAIXAS"
		_oSQL:_sQuery += " 	FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SF1") + " SF1 "
		_oSQL:_sQuery += " 		ON (SF1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SF1.F1_FILIAL = SD1.D1_FILIAL "
		_oSQL:_sQuery += " 		AND SF1.F1_DOC = SD1.D1_DOC "
		_oSQL:_sQuery += " 		AND SF1.F1_SERIE = SD1.D1_SERIE "
		_oSQL:_sQuery += " 		AND SF1.F1_FORNECE = SD1.D1_FORNECE "
		_oSQL:_sQuery += " 		AND SF1.F1_LOJA = SD1.D1_LOJA "
		_oSQL:_sQuery += " 		AND SF1.F1_EMISSAO = SD1.D1_EMISSAO) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery += " 		ON (SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SF4.F4_CODIGO = SD1.D1_TES "
		_oSQL:_sQuery += " 		AND SF4.F4_MARGEM = '2') "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SB1.B1_COD = SD1.D1_COD) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " 		ON (SF2.F2_DOC = SD1.D1_NFORI "
		_oSQL:_sQuery += " 		AND SF2.F2_SERIE = SD1.D1_SERIORI "
		_oSQL:_sQuery += " 		AND SF2.D_E_L_E_T_ <> '*' "
		_oSQL:_sQuery += " 		AND SF2.F2_FILIAL = SD1.D1_FILIAL) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " 		ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA1.A1_COD = SD1.D1_FORNECE "
		_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SD1.D1_LOJA) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery += " 		ON (SD2.D2_DOC = SD1.D1_NFORI "
		_oSQL:_sQuery += " 		AND SD2.D2_SERIE = SD1.D1_SERIORI "
		_oSQL:_sQuery += " 		AND SD2.D2_ITEM = SD1.D1_ITEMORI "
		_oSQL:_sQuery += " 		AND SD2.D_E_L_E_T_ <> '*' "
		_oSQL:_sQuery += " 		AND SD2.D2_FILIAL = SD1.D1_FILIAL) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SE1") + " SE1 "
		_oSQL:_sQuery += " 		ON (SE1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SE1.E1_FILIAL = SD1.D1_FILIAL "
		_oSQL:_sQuery += " 		AND SE1.E1_NUM = SD1.D1_DOC "
		_oSQL:_sQuery += " 		AND SE1.E1_PREFIXO = SD1.D1_SERIE "
		_oSQL:_sQuery += " 		AND SE1.E1_CLIENTE = SD1.D1_FORNECE "
		_oSQL:_sQuery += " 		AND SE1.E1_LOJA = SD1.D1_LOJA) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA3") + " SA3 "
		_oSQL:_sQuery += " 		ON (SA3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA3.A3_COD = SE1.E1_VEND1) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SZH") + " SZH "
		_oSQL:_sQuery += " 		ON (SZH.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SZH.ZH_FILIAL = SD1.D1_FILIAL "
		_oSQL:_sQuery += " 		AND SZH.ZH_TPFRE = 'E' "
		_oSQL:_sQuery += " 		AND SZH.ZH_NFENTR = SD1.D1_DOC "
		_oSQL:_sQuery += " 		AND SZH.ZH_SRNFENT = SD1.D1_SERIE "
		_oSQL:_sQuery += " 		AND SZH.ZH_FORNECE = SD1.D1_FORNECE "
		_oSQL:_sQuery += " 		AND SZH.ZH_LOJA = SD1.D1_LOJA "
		_oSQL:_sQuery += " 		AND SZH.ZH_ITNFE = SUBSTRING(SD1.D1_ITEM, 3, 2)) "
		_oSQL:_sQuery += " 	WHERE SD1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "  AND SD1.D1_EMISSAO BETWEEN '" + _dDtIni + "' AND '" + _dDtFin + "'"
		_oSQL:_sQuery += " 	GROUP BY SF4.F4_MARGEM  "
		_oSQL:_sQuery += " 			,SD1.D1_FILIAL "
		_oSQL:_sQuery += " 			,SD1.D1_FORNECE "
		_oSQL:_sQuery += " 			,SA1.A1_VACBASE "
		_oSQL:_sQuery += " 			,SA1.A1_VALBASE "
		_oSQL:_sQuery += " 			,SD1.D1_COD "
		_oSQL:_sQuery += " 			,SD1.D1_SERIE "
		_oSQL:_sQuery += " 			,SD1.D1_DTDIGIT "
		_oSQL:_sQuery += " 			,SD1.D1_LOJA "
		_oSQL:_sQuery += " 			,SF1.F1_EST "
		_oSQL:_sQuery += " 			,SA3.A3_VAGEREN "
		_oSQL:_sQuery += " 			,SE1.E1_VEND1 "
		_oSQL:_sQuery += " 			,SB1.B1_CODLIN "
		_oSQL:_sQuery += " 			,SD1.D1_COD "
		_oSQL:_sQuery += " 			,SD1.D1_TOTAL "
		_oSQL:_sQuery += " 			,SD1.D1_DOC "
		_oSQL:_sQuery += " 			,SD1.D1_FORNECE "
		_oSQL:_sQuery += " 			,SD1.D1_LOJA "
		_oSQL:_sQuery += "          ,SA1.A1_COD_MUN "
		_oSQL:_sQuery += "          ,SA1.A1_VAPROMO "
		_oSQL:_sQuery += "          ,SD1.D1_TP "
		_oSQL:_sQuery += " 	UNION ALL SELECT "
		_oSQL:_sQuery += " 		SF4.F4_MARGEM AS TIPO "
		_oSQL:_sQuery += " 	   ,SD2.D2_FILIAL AS FILIAL "
		_oSQL:_sQuery += " 	   ,SD2.D2_CLIENTE AS CLIENTE "
		_oSQL:_sQuery += " 	   ,SD2.D2_LOJA AS LOJA "
		_oSQL:_sQuery += " 	   ,SA1.A1_VACBASE AS C_BASE "
		_oSQL:_sQuery += " 	   ,SA1.A1_VALBASE AS L_BASE "
		_oSQL:_sQuery += " 	   ,SD2.D2_DOC AS NOTA "
		_oSQL:_sQuery += " 	   ,SD2.D2_SERIE AS SERIE "
		_oSQL:_sQuery += " 	   ,SD2.D2_EMISSAO AS DIGITACAO "
		_oSQL:_sQuery += " 	   ,SD2.D2_EST AS ESTADO "
		_oSQL:_sQuery += " 	   ,SF2.F2_VEND1 AS VENDEDOR "
		_oSQL:_sQuery += " 	   ,SB1.B1_CODLIN AS LINHA "
		_oSQL:_sQuery += " 	   ,SD2.D2_COD AS PRODUTO "
		_oSQL:_sQuery += " 	   ,SUM(ROUND(D2_VACUSTD*SD2.D2_QUANT,2)) AS CUSTO_PREV "
		_oSQL:_sQuery += " 	   ,SUM(ROUND(D2_CUSTO1, 2))AS CUSTO_REAL "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_QUANT) AS NF_QUANT "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_PRUNIT) AS NF_VLRUNIT "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_PRCVEN * D2_QUANT) AS NF_VLRPROD "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_VALIPI) AS NF_VALIPI "
		//_oSQL:_sQuery += " 	   ,SUM(SD2.D2_ICMSRET) AS NF_ICMSRET "
		_oSQL:_sQuery += "     ,CASE "
		_oSQL:_sQuery += "    		WHEN SF4.F4_CREDST = '4' THEN 0 "
		_oSQL:_sQuery += "    		ELSE SUM(SD2.D2_ICMSRET) "
		_oSQL:_sQuery += "      END AS NF_ICMSRET "		
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_VALBRUT) AS NF_VLR_BRT "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_VALICM) AS NF_ICMS "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_VALIMP5) AS NF_COFINS "
		_oSQL:_sQuery += " 	   ,SUM(SD2.D2_VALIMP6) AS NF_PIS "
		_oSQL:_sQuery += " 	   ,0 AS VLR_COMIS_PREV "
		_oSQL:_sQuery += " 	   ,0 AS VLR_COMIS_REAL "
		_oSQL:_sQuery += " 	   ,SF2.F2_VALMERC AS TOTPROD_NF "
		_oSQL:_sQuery += " 	   ,ISNULL(CASE SF2.F2_PBRUTO "
		_oSQL:_sQuery += " 			WHEN 0 THEN 0 "
		_oSQL:_sQuery += " 			ELSE ROUND(SC5.C5_MVFRE * (SB1.B1_PESBRU * SD2.D2_QUANT) / SF2.F2_PBRUTO, 2) "
		_oSQL:_sQuery += " 			END, 0) AS FRETE_PREVISTO "
		_oSQL:_sQuery += " 	   ,(SELECT "
		_oSQL:_sQuery += " 				SUM(SZH.ZH_RATEIO) "
		_oSQL:_sQuery += " 			FROM " + RetSQLName ("SZH") + " SZH "
		_oSQL:_sQuery += " 			WHERE SZH.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 			AND SZH.ZH_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 			AND SZH.ZH_TPFRE = 'S' "
		_oSQL:_sQuery += " 			AND SZH.ZH_NFSAIDA = SD2.D2_DOC "
		_oSQL:_sQuery += " 			AND SZH.ZH_SERNFS = SD2.D2_SERIE "
		_oSQL:_sQuery += " 			AND SZH.ZH_ITNFS = SD2.D2_ITEM) "
		_oSQL:_sQuery += " 		AS FRETE_REALIZADO "
		_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREVISTO "
		_oSQL:_sQuery += " 	   ,0 AS RAPEL_REALIZADO "
		_oSQL:_sQuery += " 	   ,SA3.A3_VAGEREN AS SUPER "
		_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTIL "
		_oSQL:_sQuery += "     ,0 AS VERBAS_LIB "
		_oSQL:_sQuery += "     ,SA1.A1_COD_MUN AS CODMUN "
		_oSQL:_sQuery += "     ,SA1.A1_VAPROMO AS PROMOTOR"
		_oSQL:_sQuery += "     ,SUM (CASE WHEN SD2.D2_TP IN ('PA', 'PI', 'VD') THEN SD2.D2_QUANT * SB1.B1_LITROS ELSE 0 END) AS NF_LITROS"
		_oSQL:_sQuery += "     ,dbo.VA_FQtCx (SD2.D2_COD, SUM (SD2.D2_QUANT)) AS NF_QTCAIXAS"
		_oSQL:_sQuery += " 	FROM " + RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " 		ON (SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SF2.F2_FILIAL = SD2.D2_FILIAL "
		_oSQL:_sQuery += " 		AND SF2.F2_DOC = SD2.D2_DOC "
		_oSQL:_sQuery += " 		AND SF2.F2_SERIE = SD2.D2_SERIE "
		_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 		AND SF2.F2_LOJA = SD2.D2_LOJA "
		_oSQL:_sQuery += " 		AND SF2.F2_EMISSAO = SD2.D2_EMISSAO) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " 		ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA1.A1_COD = SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SD2.D2_LOJA) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA3") + " SA3 "
		_oSQL:_sQuery += " 		ON (SA3.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA3.A3_COD = SF2.F2_VEND1) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery += " 		ON (SF4.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SF4.F4_MARGEM IN ('3') "
		_oSQL:_sQuery += " 		AND SF4.F4_CODIGO = SD2.D2_TES) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SB1.B1_COD = SD2.D2_COD) "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SC5") + " SC5 "
		_oSQL:_sQuery += " 		ON (SC5.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SC5.C5_NUM = SD2.D2_PEDIDO "
		_oSQL:_sQuery += " 		AND SC5.C5_FILIAL = SD2.D2_FILIAL) "
		_oSQL:_sQuery += " 	WHERE SD2.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "  AND SD2.D2_EMISSAO BETWEEN '" + _dDtIni + "' AND '" + _dDtFin + "'"
		_oSQL:_sQuery += " 	GROUP BY SF4.F4_MARGEM "
		_oSQL:_sQuery += " 			,SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 			,SD2.D2_LOJA "
		_oSQL:_sQuery += " 			,SA1.A1_VACBASE "
		_oSQL:_sQuery += " 			,SA1.A1_VALBASE "
		_oSQL:_sQuery += " 			,SD2.D2_DOC "
		_oSQL:_sQuery += " 			,SD2.D2_SERIE "
		_oSQL:_sQuery += " 			,SD2.D2_DTDIGIT "
		_oSQL:_sQuery += " 			,SD2.D2_EST "
		_oSQL:_sQuery += " 			,SA3.A3_VAGEREN "
		_oSQL:_sQuery += " 			,SF2.F2_VEND1 "
		_oSQL:_sQuery += " 			,SB1.B1_CODLIN "
		_oSQL:_sQuery += " 			,SD2.D2_COD "
		_oSQL:_sQuery += " 			,SF2.F2_VALMERC "
		_oSQL:_sQuery += " 			,SD2.D2_FILIAL "
		_oSQL:_sQuery += " 			,SD2.D2_DOC "
		_oSQL:_sQuery += " 			,SD2.D2_EMISSAO "
		_oSQL:_sQuery += " 			,SD2.D2_TOTAL "
		_oSQL:_sQuery += " 			,SD2.D2_SERIE "
		_oSQL:_sQuery += " 			,SD2.D2_ITEM "
		_oSQL:_sQuery += " 			,SD2.D2_CLIENTE "
		_oSQL:_sQuery += " 			,SD2.D2_LOJA "
		_oSQL:_sQuery += " 			,SF2.F2_PBRUTO "
		_oSQL:_sQuery += " 			,SC5.C5_MVFRE "
		_oSQL:_sQuery += " 			,SB1.B1_PESBRU "
		_oSQL:_sQuery += " 			,SD2.D2_QUANT "
		_oSQL:_sQuery += "          ,SA1.A1_COD_MUN "
		_oSQL:_sQuery += "          ,SA1.A1_VAPROMO "
		_oSQL:_sQuery += "          ,SD2.D2_TP "
		_oSQL:_sQuery += " UNION ALL SELECT "
		_oSQL:_sQuery += " 		'6' AS TIPO "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_FILIAL AS FILIAL "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_CLI AS CLIENTE "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_LOJA AS LOJA "
		_oSQL:_sQuery += " 	   ,SA1.A1_VACBASE AS C_BASE "
		_oSQL:_sQuery += " 	   ,SA1.A1_VALBASE AS L_BASE "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_DOC AS NOTA "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_SERIE AS SERIE "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_DTA AS EMISSAO "
		_oSQL:_sQuery += " 	   ,SA1.A1_EST AS ESTADO "
		_oSQL:_sQuery += " 	   ,ZA5.ZA5_VENVER AS VENDEDOR "
		_oSQL:_sQuery += " 	   ,'' AS LINHA "
		_oSQL:_sQuery += " 	   ,'VERBA' AS PRODUTO "
		_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV "
		_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL "
		_oSQL:_sQuery += " 	   ,0 AS NF_QUANT "
		_oSQL:_sQuery += " 	   ,0 AS NF_VLRUNIT "
		_oSQL:_sQuery += " 	   ,0 AS NF_VLRPROD "
		_oSQL:_sQuery += " 	   ,0 AS NF_VALIPI "
		_oSQL:_sQuery += " 	   ,0 AS NF_ICMSRET "
		_oSQL:_sQuery += " 	   ,0 AS NF_VLR_BRT "
		_oSQL:_sQuery += " 	   ,0 AS NF_ICMS "
		_oSQL:_sQuery += " 	   ,0 AS NF_COFINS "
		_oSQL:_sQuery += " 	   ,0 AS NF_PIS "
		_oSQL:_sQuery += " 	   ,0 AS VLR_COMIS_PREV "
		_oSQL:_sQuery += " 	   ,0 AS VLR_COMIS_REAL "
		_oSQL:_sQuery += " 	   ,0 AS TOTPROD_NF "
		_oSQL:_sQuery += " 	   ,0 AS FRETE_PREVISTO "
		_oSQL:_sQuery += " 	   ,0 AS FRETE_REALIZADO "
		_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREVISTO "
		_oSQL:_sQuery += " 	   ,0 AS RAPEL_REALIZADO "
		_oSQL:_sQuery += " 	   ,SA3T.A3_VAGEREN AS SUPER"
		_oSQL:_sQuery += " 	   ,SUM(ZA5.ZA5_VLR) AS VERBAS_UTIL "
		_oSQL:_sQuery += "     ,0 AS VERBAS_LIB "
		_oSQL:_sQuery += "     ,SA1.A1_COD_MUN AS CODMUN "
		_oSQL:_sQuery += "     ,SA1.A1_VAPROMO AS PROMOTOR"
		_oSQL:_sQuery += "     ,0 AS NF_LITROS"
		_oSQL:_sQuery += "     ,0 AS NF_QTCAIXAS"
		_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZA5") + " ZA5 "
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " 		ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA1.A1_COD = ZA5.ZA5_CLI "
		_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZA5.ZA5_LOJA) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SF2") + " SF2 "
		_oSQL:_sQuery += " 		ON (SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SF2.F2_DOC = ZA5.ZA5_DOC "
		_oSQL:_sQuery += " 		AND SF2.F2_SERIE = '10' "
		_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = ZA5.ZA5_CLI "
		_oSQL:_sQuery += " 		AND SF2.F2_LOJA = ZA5.ZA5_LOJA) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SE1") + " SE1 "
		_oSQL:_sQuery += " 		ON (SE1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SE1.E1_NUM = ZA5.ZA5_DOC "
		_oSQL:_sQuery += " 		AND SE1.E1_CLIENTE = ZA5.ZA5_CLI "
		_oSQL:_sQuery += " 		AND SE1.E1_PARCELA = ZA5.ZA5_PARC "
		_oSQL:_sQuery += " 		AND SE1.E1_LOJA = ZA5.ZA5_LOJA) "
		_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SA3") + " SA3T "
		_oSQL:_sQuery += " 		ON (SA3T.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND SA3T.A3_COD = ZA5.ZA5_VENVER) "
		_oSQL:_sQuery += " 	WHERE ZA5.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "  AND ZA5.ZA5_DTA BETWEEN '" + _dDtIni + "' AND '" + _dDtFin + "'"
		_oSQL:_sQuery += " 	AND ZA5.ZA5_TLIB NOT IN ('1', '9') "
		_oSQL:_sQuery += " 	GROUP BY ZA5.ZA5_CLI "
		_oSQL:_sQuery += " 			,ZA5.ZA5_FILIAL "
		_oSQL:_sQuery += " 			,ZA5.ZA5_DOC "
		_oSQL:_sQuery += " 			,SA1.A1_VACBASE "
		_oSQL:_sQuery += " 			,SA1.A1_VALBASE "
		_oSQL:_sQuery += " 			,ZA5.ZA5_SERIE "
		_oSQL:_sQuery += " 			,ZA5.ZA5_DTA "
		_oSQL:_sQuery += " 			,ZA5.ZA5_LOJA "
		_oSQL:_sQuery += " 			,SA1.A1_EST "
		_oSQL:_sQuery += " 			,SA3T.A3_VAGEREN "
		_oSQL:_sQuery += " 			,SE1.E1_VEND1 "
		_oSQL:_sQuery += " 			,SA1.A1_VEND "
		_oSQL:_sQuery += " 			,ZA5.ZA5_VENVER "
		_oSQL:_sQuery += "          ,SA1.A1_COD_MUN "
		_oSQL:_sQuery += "          ,SA1.A1_VAPROMO "
		_oSQL:_sQuery += " UNION ALL SELECT "
		_oSQL:_sQuery += " 	  'A' AS TIPO "
		_oSQL:_sQuery += "    ,ZA4.ZA4_FILIAL AS FILIAL"
		_oSQL:_sQuery += "    ,ZA4.ZA4_CLI AS CLIENTE"
		_oSQL:_sQuery += "    ,ZA4.ZA4_LOJA AS LOJA"
		_oSQL:_sQuery += "    ,SA1.A1_VACBASE AS C_BASE"
		_oSQL:_sQuery += "    ,SA1.A1_VALBASE AS L_BASE"
		_oSQL:_sQuery += "    ,'' AS NOTA"
		_oSQL:_sQuery += "    ,'' AS SERIE"
		_oSQL:_sQuery += "    ,ZA4.ZA4_DLIB AS EMISSAO"
		_oSQL:_sQuery += "    ,SA1.A1_EST AS ESTADO"
		_oSQL:_sQuery += "    ,ZA4_VEND AS VENDEDOR"
		_oSQL:_sQuery += "    ,'' AS LINHA"
		_oSQL:_sQuery += "    ,'VERBA_LIB' AS PRODUTO"
		_oSQL:_sQuery += "    ,0 AS CUSTO_PREV"
		_oSQL:_sQuery += "    ,0 AS CUSTO_REAL"
		_oSQL:_sQuery += "    ,0 AS NF_QUANT"
		_oSQL:_sQuery += "    ,0 AS NF_VLRUNIT"
		_oSQL:_sQuery += "    ,0 AS NF_VLRPROD"
		_oSQL:_sQuery += "    ,0 AS NF_VALIPI"
		_oSQL:_sQuery += "    ,0 AS NF_ICMSRET"
		_oSQL:_sQuery += "    ,0 AS NF_VLR_BRT"
		_oSQL:_sQuery += "    ,0 AS NF_ICMS"
		_oSQL:_sQuery += "    ,0 AS NF_COFINS"
		_oSQL:_sQuery += "    ,0 AS NF_PIS"
		_oSQL:_sQuery += "    ,0 AS VLR_COMIS_PREV"
		_oSQL:_sQuery += "    ,0 AS VLR_COMIS_REAL"
		_oSQL:_sQuery += "    ,0 AS TOTPROD_NF"
		_oSQL:_sQuery += "    ,0 AS FRETE_PREVISTO"
		_oSQL:_sQuery += "    ,0 AS FRETE_REALIZADO"
		_oSQL:_sQuery += "    ,0 AS RAPEL_PREVISTO"
		_oSQL:_sQuery += "    ,0 AS RAPEL_REALIZADO"
		_oSQL:_sQuery += "    ,SA3.A3_VAGEREN AS SUPER"
		_oSQL:_sQuery += "    ,0 AS VERBAS_UTIL"
		_oSQL:_sQuery += "    ,SUM(ZA4.ZA4_VLR) AS VERBAS_LIB"
		_oSQL:_sQuery += "    ,SA1.A1_COD_MUN AS CODMUN "
		_oSQL:_sQuery += "    ,SA1.A1_VAPROMO AS PROMOTOR"
		_oSQL:_sQuery += "    ,0 AS NF_LITROS"
		_oSQL:_sQuery += "    ,0 AS NF_QTCAIXAS"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZA4") + " ZA4 "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 " 
		_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 			AND SA1.A1_COD = ZA4.ZA4_CLI"
		_oSQL:_sQuery += " 			AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " SA3 " 
		_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 			AND SA3.A3_COD = SA1.A1_VEND)"
		_oSQL:_sQuery += " WHERE ZA4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZA4.ZA4_TLIB != '1'"
        _oSQL:_sQuery += " AND ZA4.ZA4_DGER BETWEEN '" + _dDtIni + "' AND '" + _dDtFin + "'"
		_oSQL:_sQuery += " GROUP BY ZA4.ZA4_FILIAL"
		_oSQL:_sQuery += " 		,ZA4.ZA4_CLI"
		_oSQL:_sQuery += " 		,ZA4.ZA4_LOJA"
		_oSQL:_sQuery += " 		,ZA4.ZA4_DLIB"
		_oSQL:_sQuery += " 		,SA1.A1_VACBASE"
		_oSQL:_sQuery += " 		,SA1.A1_VALBASE"
		_oSQL:_sQuery += " 		,SA1.A1_EST"
		_oSQL:_sQuery += " 		,SA1.A1_VEND"
		_oSQL:_sQuery += " 		,SA3.A3_VAGEREN"
		_oSQL:_sQuery += "      ,ZA4_VEND"
		_oSQL:_sQuery += "      ,SA1.A1_COD_MUN "
		_oSQL:_sQuery += "      ,SA1.A1_VAPROMO "
		_oSQL:_sQuery += "       )"
		_oSQL:Log()

		nHandle := FCreate("c:\temp\log.txt")
		FWrite(nHandle,_oSQL:_sQuery)
		FClose(nHandle)

        _oSQL:Exec ()
    EndIf

    If _nTipo != 1
		u_help("Processo finalizado com sucesso")
	EndIf
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT         TIPO TAM DEC VALID F3     Opcoes             Help
	aadd (_aRegsPerg, {01, "Data inicial ", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final   ", "D", 08, 0,  "",   "   ", {},                ""})

	 U_ValPerg (cPerg, _aRegsPerg)
Return
