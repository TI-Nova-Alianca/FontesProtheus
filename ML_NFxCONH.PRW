//  Programa...: ML_NFxCONH
//  Autor......: Catia Cardoso
//  Data.......: 14/01/2015
//  Descricao..: Consulta Notas X Conhecimentos de Fretes 
// 
//  Historico de alterações
//  24/01/2015 - Catia - erro de divisao por zero - não dava erro na tela, mas a consulta aparecia pela metade
//  30/06/2015 - Catia - estava buscando o peso errado
//  09/07/2015 - Catia - conferido e validado os valores e pesos
//  19/11/2015 - Catia - revalidado relatorio de fretes - jeferson/rodrigo
//  03/10/2016 - Catia - desconsiderar as notas em que o transportador é o REMETENTE - codigo 704
//  05/02/2018 - Catia - tratamento do tipo de despesa de frete 5=transferencia
//  04/05/2018 - Catia - refeito o programa para melhorar a performance e para tratar as entradas
//  16/05/2018 - Catia - identificar as notas de transferencia e notas de importacao / exportacao
//  05/07/2018 - Catia - parametro de estado nao estava fazendo corretamente quando deixava em branco o estado
//
// ----------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_NFXCONH (_lAuto)

	cPerg   := "ML_NFXCONH"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		u_help ("Data inicial maior que a data final.",, .t.)
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.)
    
		_sQuery := " "
		_sQuery += " WITH C AS ("
		if mv_par15 == 1 .or. mv_par15 == 3 
	    	_sQuery += "  	SELECT 'SAI' AS TIPO"
			_sQuery += " 	 	,SZH.ZH_NFSAIDA AS NOTA"
			_sQuery += "		,SZH.ZH_SERNFS AS SERIE"
			_sQuery += "		,SF2.F2_TIPO AS TIPO_NF"
			_sQuery += "		,dbo.VA_DTOC(SD2.D2_EMISSAO) AS DATA"
			_sQuery += "		,SD2.D2_CLIENTE AS COD_CLIFOR"
			_sQuery += "		,SD2.D2_LOJA AS LJ_CLIFOR"
			_sQuery += "		,SZH.ZH_NFFRETE AS NRO_CONH"
			_sQuery += "		,SZH.ZH_SERFRET AS SER_CONH"
			_sQuery += "		,dbo.VA_DTOC(SF1.F1_DTDIGIT) AS DIG_CONH"
			_sQuery += "		,SZH.ZH_FORNECE AS FORN_CONH"
			_sQuery += "		,SZH.ZH_LOJA AS LOJA_CONH"
			_sQuery += "		,SF1.F1_VAFLAG AS VAFLAG"
			_sQuery += "		,SF1.F1_VAUSER AS INCLUIDO"
			_sQuery += "		,SF2.F2_PBRUTO AS PESO_BRUTO"
			_sQuery += "		,SUM(SZH.ZH_RATEIO) AS VLR_FRETE"
			_sQuery += "		,SUM(SD2.D2_TOTAL) + SUM(SD2.D2_VALIPI) + SUM(SD2.D2_ICMSRET) AS VLR_BRUT"
			_sQuery += "		,CASE"
			_sQuery += "		 WHEN SF2.F2_PBRUTO > 0 THEN ROUND(SUM(SZH.ZH_RATEIO) / SF2.F2_PBRUTO, 2)"
			_sQuery += "		 ELSE 0"
			_sQuery += "		 END AS FRETE_KG"
			_sQuery += "		,SZH.ZH_TPDESP AS TP_DESP"
			_sQuery += "		,SF2.F2_EST AS ESTADO"
			_sQuery += "	 FROM SZH010 AS SZH"
			_sQuery += "		INNER JOIN SD2010 AS SD2"
			_sQuery += "			ON (SD2.D_E_L_E_T_ = ''"
			_sQuery += "				AND SD2.D2_FILIAL  = SZH.ZH_FILIAL"
			_sQuery += "				AND SD2.D2_DOC     = SZH.ZH_NFSAIDA"
			_sQuery += "				AND SD2.D2_SERIE   = SZH.ZH_SERNFS"
			_sQuery += "				AND SD2.D2_ITEM    = SZH.ZH_ITNFS)"
			_sQuery += "		INNER JOIN SF2010 AS SF2"
			_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
			_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
			_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
			_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
			_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
			_sQuery += "				AND SF2.F2_CLIENTE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
			_sQuery += "				AND SF2.F2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			if mv_par11 <> 'ZZ' .and. mv_par11 <> '  '
  				_sQuery += " 			AND SF2.F2_EST     = '" + mv_par11 + "'"
  			endif 
  			_sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
			_sQuery += "		INNER JOIN SF4010 AS SF4"
			_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
			_sQuery += "				AND SF4.F4_CODIGO = SD2.D2_TES"
			_sQuery += "				AND SF4.F4_MARGEM IN ('1', '3'))"
			_sQuery += "		LEFT JOIN SF1010 AS SF1"
			_sQuery += "			ON (SF1.D_E_L_E_T_ = ''"
			_sQuery += "				AND SF1.F1_FILIAL  = SZH.ZH_FILIAL"
			_sQuery += "				AND SF1.F1_DOC     = SZH.ZH_NFFRETE"
			_sQuery += "				AND SF1.F1_SERIE   = SZH.ZH_SERFRET"
			_sQuery += "				AND SF1.F1_FORNECE = SZH.ZH_FORNECE)"
			_sQuery += "	WHERE SZH.D_E_L_E_T_ = ''"
			_sQuery += "	  AND SZH.ZH_FILIAL = '01'"
			_sQuery += "	  AND SZH.ZH_TPFRE = 'S'"
			_sQuery += "	  AND SZH.ZH_DATA    >= '" + dtos (mv_par01) + "'"
			_sQuery += "	  AND SZH.ZH_NFSAIDA BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'" 
			_sQuery += "	  AND SZH.ZH_NFFRETE BETWEEN '" + mv_par12 + "' AND '" + mv_par13 + "'"
			_sQuery += "	GROUP BY SZH.ZH_NFSAIDA"
			_sQuery += "			,SZH.ZH_SERNFS"
			_sQuery += "			,SF2.F2_TIPO"
			_sQuery += "			,SD2.D2_EMISSAO"
			_sQuery += "			,SD2.D2_CLIENTE"
			_sQuery += "			,SD2.D2_LOJA"
			_sQuery += "			,SF2.F2_PBRUTO"
			_sQuery += "			,SZH.ZH_NFFRETE"
			_sQuery += "			,SZH.ZH_SERFRET"
			_sQuery += "			,SZH.ZH_TPDESP"
			_sQuery += "			,SF1.F1_DTDIGIT"
			_sQuery += "			,SZH.ZH_FORNECE"
			_sQuery += "			,SZH.ZH_LOJA"
			_sQuery += "			,SF1.F1_VAFLAG"
			_sQuery += "			,SF1.F1_VAUSER"
			_sQuery += "			,SF2.F2_EST"
		endif
		if mv_par15 == 3			
			_sQuery += " UNION ALL"
		endif			
		if mv_par15 == 2 .or. mv_par15 == 3
			_sQuery += " SELECT 'ENT' AS TIPO"
			_sQuery += "		,SZH.ZH_NFENTR   AS NOTA"
			_sQuery += "		,SZH.ZH_SRNFENT AS SERIE"
			_sQuery += "		,SF1N.F1_TIPO   AS TIPO_NF"
			_sQuery += "		,dbo.VA_DTOC(SD1.D1_DTDIGIT) AS DATA"
			_sQuery += "		,SZH.ZH_CLIFOR  AS COD_CLIFOR"
			_sQuery += "		,SZH.ZH_LJCLIFO AS LJ_CLIFOR"
			_sQuery += "		,SZH.ZH_NFFRETE AS NRO_CONH"
			_sQuery += "		,SZH.ZH_SERFRET AS SER_CONH"
			_sQuery += "		,dbo.VA_DTOC(SF1C.F1_DTDIGIT) AS DIG_CONH"
			_sQuery += "		,SZH.ZH_FORNECE AS FORN_CONH"
			_sQuery += "		,SZH.ZH_LOJA    AS LOJA_CONH"
			_sQuery += "		,SF1C.F1_VAFLAG AS VAFLAG"
			_sQuery += "		,SF1C.F1_VAUSER AS INCLUIDO"
			_sQuery += "		,SF1N.F1_PBRUTO AS PESO_BRUTO"
			_sQuery += "		,SUM(SZH.ZH_RATEIO) AS VLR_FRETE"
			_sQuery += "		,SUM(SD1.D1_TOTAL) + SUM(SD1.D1_VALIPI) + SUM(SD1.D1_ICMSRET) AS VLR_BRUT"
			_sQuery += "		,CASE"
			_sQuery += "		 WHEN SF1N.F1_PBRUTO > 0 THEN ROUND(SUM(SZH.ZH_RATEIO) / SF1N.F1_PBRUTO, 2)"
			_sQuery += "		 ELSE 0"
			_sQuery += "		 END AS FRETE_KG"
			_sQuery += "		,SZH.ZH_TPDESP AS TP_DESP"
			_sQuery += "		,SF1N.F1_EST AS ESTADO"
			_sQuery += " 	 FROM SZH010 AS SZH"
			_sQuery += "		INNER JOIN SD1010 AS SD1"
			_sQuery += "			ON (SD1.D_E_L_E_T_ = ''"
			_sQuery += "				AND SD1.D1_FILIAL  = SZH.ZH_FILIAL"
			_sQuery += "				AND SD1.D1_DOC     = SZH.ZH_NFENTR"
			_sQuery += "				AND SD1.D1_FORNECE = SZH.ZH_CLIFOR"
			_sQuery += "				AND SD1.D1_SERIE   = SZH.ZH_SRNFENT"
			_sQuery += "				AND SD1.D1_ITEM    = '00' + SZH.ZH_ITNFE)"
			_sQuery += "		INNER JOIN SF1010 AS SF1N"
			_sQuery += "			ON (SF1N.D_E_L_E_T_ = ''"
			_sQuery += "				AND SF1N.F1_FILIAL  = SD1.D1_FILIAL"
			_sQuery += "				AND SF1N.F1_DOC     = SD1.D1_DOC"
			_sQuery += "				AND SF1N.F1_SERIE   = SD1.D1_SERIE"
			_sQuery += "				AND SF1N.F1_FORNECE = SD1.D1_FORNECE"
			if mv_par11 <> 'ZZ' .and. mv_par11 <> '  '
  				_sQuery += " 			AND SF1N.F1_EST     = '" + mv_par11 + "'"
  			endif 
  			_sQuery += "				AND SF1N.F1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sQuery += "				AND SF1N.F1_FORNECE BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
  			_sQuery += "				AND SF1N.F1_DTDIGIT = SD1.D1_DTDIGIT)"
			_sQuery += "		LEFT JOIN SF1010 AS SF1C"
			_sQuery += "			ON (SF1C.D_E_L_E_T_ = ''"
			_sQuery += "				AND SF1C.F1_FILIAL  = SZH.ZH_FILIAL"
			_sQuery += "				AND SF1C.F1_DOC     = SZH.ZH_NFFRETE"
			_sQuery += "				AND SF1C.F1_SERIE   = SZH.ZH_SERFRET"
			_sQuery += "				AND SF1C.F1_FORNECE = SZH.ZH_FORNECE)"
			_sQuery += "	WHERE SZH.D_E_L_E_T_ = ''"
	  		_sQuery += "	  AND SZH.ZH_FILIAL  = '01'"
	  		_sQuery += "	  AND SZH.ZH_TPFRE   = 'E'"
	  		_sQuery += "	  AND SZH.ZH_CLIFOR  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	  		_sQuery += "	  AND SZH.ZH_NFENTR  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	  		_sQuery += "	  AND SZH.ZH_NFFRETE BETWEEN '" + mv_par12 + "' AND '" + mv_par13 + "'"
	  		_sQuery += "	  AND SZH.ZH_DATA    >= '" + dtos (mv_par01) + "'"
	 		_sQuery += "	GROUP BY	SZH.ZH_NFENTR"
			_sQuery += "		,SZH.ZH_SRNFENT"
			_sQuery += "		,SF1N.F1_TIPO"
			_sQuery += "		,SD1.D1_DTDIGIT"
			_sQuery += "		,SZH.ZH_CLIFOR"
			_sQuery += "		,SZH.ZH_LJCLIFO"
			_sQuery += "		,SF1N.F1_PBRUTO"
			_sQuery += "		,SZH.ZH_NFFRETE"
			_sQuery += "		,SZH.ZH_SERFRET"
			_sQuery += "		,SZH.ZH_TPDESP"
			_sQuery += "		,SF1C.F1_DTDIGIT"
			_sQuery += "		,SZH.ZH_FORNECE"
			_sQuery += "		,SZH.ZH_LOJA"
			_sQuery += "		,SF1C.F1_VAFLAG"
			_sQuery += "		,SF1C.F1_VAUSER"
			_sQuery += "		,SF1N.F1_EST"
		endif			
		_sQuery += ")"
		_sQuery += " SELECT C.TIPO, C.NOTA, C.SERIE"
		_sQuery += "      , CASE C.TIPO"
		_sQuery += " 	    WHEN 'ENT' THEN CASE"
		_sQuery += " 	    		WHEN C.TIPO_NF = 'N' AND C.ESTADO = 'EX' THEN 'I'"
		_sQuery += " 	    		WHEN C.TIPO_NF = 'N' AND SUBSTRING(SA2.A2_CGC,1,8) = '88612486' THEN 'T'"
		_sQuery += " 	    		ELSE C.TIPO_NF END"
		_sQuery += " 	    	WHEN 'SAI' THEN CASE"
		_sQuery += " 	    		WHEN C.TIPO_NF = 'N' AND C.ESTADO = 'EX' THEN 'E'"
		_sQuery += " 	    		WHEN C.TIPO_NF = 'N' AND SUBSTRING(SA1.A1_CGC,1,8) = '88612486' THEN 'T'"
		_sQuery += " 	    		ELSE C.TIPO_NF END"
		_sQuery += " 	    	END AS TIPO_NF"
		_sQuery += "      , C.DATA, C.COD_CLIFOR, C.LJ_CLIFOR"
     	_sQuery += "	  , CASE C.TIPO" 
    	_sQuery += " 		WHEN 'ENT' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA2.A2_NOME ELSE SA1.A1_NOME END"
		_sQuery += " 		WHEN 'SAI' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA1.A1_NOME ELSE SA2.A2_NOME END"
       	_sQuery += "		END AS NOME"
	  	_sQuery += "	  , CASE C.TIPO" 
		_sQuery += " 		WHEN 'ENT' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA2.A2_MUN ELSE SA1.A1_MUN END"
		_sQuery += " 		WHEN 'SAI' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA1.A1_MUN ELSE SA2.A2_MUN END"
		_sQuery += "		END AS CIDADE"
	 	_sQuery += "	  , CASE C.TIPO"
		_sQuery += "		WHEN 'ENT' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA2.A2_EST ELSE SA1.A1_EST END"
		_sQuery += "		WHEN 'SAI' THEN CASE WHEN C.TIPO_NF = 'N' THEN SA1.A1_EST ELSE SA2.A2_EST END"
		_sQuery += "		END AS ESTADO"
     	_sQuery += "	  , C.NRO_CONH, C.SER_CONH, C.DIG_CONH"
	 	_sQuery += "	  , C.FORN_CONH, C.LOJA_CONH"
	 	_sQuery += "	  , SA2F.A2_NOME AS NOME_FORN, SA2F.A2_EST AS UF_FORN"
	 	_sQuery += "	  , ISNULL(CASE C.VAFLAG"
		_sQuery += "		WHEN 'S' THEN 'EDI'"
		_sQuery += "		WHEN 'X' THEN 'XML'"
	    _sQuery += "		END, 'DIG') AS IMPORTADO"
	 	_sQuery += "	  , C.INCLUIDO"
	 	_sQuery += "	  , CASE"
		_sQuery += "		WHEN C.TP_DESP = '1' THEN 'ENTREGA'"
		_sQuery += "		WHEN C.TP_DESP = '2' THEN 'REENTREGA'"
		_sQuery += "		WHEN C.TP_DESP = '3' THEN 'REDESPACHO'"
		_sQuery += "		WHEN C.TP_DESP = '4' THEN 'PALETIZACAO'"
		_sQuery += "		WHEN C.TP_DESP = '5' THEN 'TRANSFERENCIA'"
	  	_sQuery += "		END AS TP_DESP"
	 	_sQuery += "	  , C.PESO_BRUTO"
	 	_sQuery += "	  , C.VLR_FRETE, C.VLR_BRUT, C.FRETE_KG"
	 	_sQuery += "	  , ROUND((C.VLR_FRETE / C.VLR_BRUT) *100,2)
  		_sQuery += "   FROM C"
  		_sQuery += "	 LEFT JOIN SA1010 AS SA1"
		_sQuery += "		ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += "			AND SA1.A1_COD  = C.COD_CLIFOR"
		_sQuery += "			AND SA1.A1_LOJA = C.LJ_CLIFOR)"
		_sQuery += "	LEFT JOIN SA2010 AS SA2"
		_sQuery += "		ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += "			AND SA2.A2_COD  = C.COD_CLIFOR"
		_sQuery += "			AND SA2.A2_LOJA = C.LJ_CLIFOR)"
		_sQuery += "	INNER JOIN SA2010 AS SA2F"
		_sQuery += "		ON (SA2F.D_E_L_E_T_  = ''"
		_sQuery += "			AND SA2F.A2_COD  = C.FORN_CONH"
		_sQuery += "			AND SA2F.A2_LOJA = C.LOJA_CONH)"
		
		do case
			case mv_par14 = 1  // ordena por data
				_sQuery += "	ORDER BY C.DATA, C.TIPO, C.NOTA"
			case mv_par14 = 2  // ordena por documento
				_sQuery += "	ORDER BY C.DATA, C.TIPO, C.NOTA"
   			case mv_par14 = 3  // ordena por cliente/fornecedor
   				_sQuery += "	ORDER BY C.COD_CLIFOR, C.LJ_CLIFOR, C.DATA, C.TIPO, C.NOTA"
   			case mv_par14 = 4  // ordena por cliente/fornecedor
				_sQuery += "	ORDER BY ESTADO, CIDADE, C.DATA, C.TIPO, C.NOTA"
		endcase				
   		
   		u_log2 ('debug', _sQuery)
   		
		_aDados := U_Qry2Array(_sQuery)
    	if len(_aDados) > 0 
			if _lAuto
				U_AColsXLS (_aDados)
			else
				_aCols = {}
				aadd (_aCols, {01, "Tipo"  	   	   	   	   ,  20,  "@!"})
				aadd (_aCols, {02, "Num.Nota"       	   ,  30,  "@!"})
				aadd (_aCols, {03, "Serie"          	   ,  10,  "@!"})
				aadd (_aCols, {04, "Tipo NF" 	     	   ,  20,  "@!"})
				aadd (_aCols, {05, "Data"             	   ,  30,  "@D"})
				aadd (_aCols, {06, "Cli/Forn"        	   ,  30,  "@!"})
				aadd (_aCols, {07, "Loja"           	   ,  10,  "@!"})
				aadd (_aCols, {08, "Razão Social"   	   , 100,  "@!"})
				aadd (_aCols, {09, "Cidade"         	   ,  50,  "@!"})
				aadd (_aCols, {10, "UF"             	   ,  10,  "@!"})
				aadd (_aCols, {11, "CONH"       	  	   ,  30,  "@!"})
				aadd (_aCols, {12, "Serie"          	   ,  10,  "@!"})
				aadd (_aCols, {13, "Dt.Dig.CONH"      	   ,  30,  "@D"})
				aadd (_aCols, {14, "Fornecedor"            ,  30,  "@!"})
				aadd (_aCols, {15, "Loja"                  ,  10,  "@!"})
				aadd (_aCols, {16, "Razão Social"          , 100,  "@!"})
				aadd (_aCols, {17, "UF"             	   ,  10,  "@!"})
				aadd (_aCols, {18, "CONH"                  ,  20,  "@!"})
				aadd (_aCols, {19, "Usuario Inclusão CONH" ,  70,  "@!"})
				aadd (_aCols, {20, "Tipo Despesa"          ,  50,  "@!"})
				if  u_zzuvl ('032', __cUserId, .F.)
					aadd (_aCols, {21, "Peso Nota"    	, 50,  "@E 9,999,999.99"})
					aadd (_aCols, {22, "Valor Frete"    , 50,  "@E 999,999.99"})
					aadd (_aCols, {23, "Valor Nota"    	, 50,  "@E 9,999,999.99"})
					aadd (_aCols, {24, "Frete_KG"       , 35,  "@E 999.99"})
					aadd (_aCols, {25, "Frete_%"        , 35,  "@E 999.99"})
				endif
				U_F3Array (_aDados, "Consulta Notas X Conhecimentos", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 40 , "", "", .T., 'C' )
			endif
		else
			u_help ("Não foram encontrados dados para consulta")
		endif    		
	endif
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Emissao/Recebimento ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data Emissao/Recebimento ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Cliente de               ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {04, "Cliente ate              ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {05, "Doc de Saida             ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {06, "Doc de Saida             ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {07, "Fornecedor de            ?", "C", 6, 0,  "",   "SA2", {},  ""})
	aadd (_aRegsPerg, {08, "Fornecedor até           ?", "C", 6, 0,  "",   "SA2", {},  ""})
	aadd (_aRegsPerg, {09, "Doc de Entrada           ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {10, "Doc de Entrada           ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {11, "UF                       ?", "C", 2, 0,  "",   "12 ", {},  ""})
	aadd (_aRegsPerg, {12, "Conhecimento de          ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {13, "Conhecimento ate         ?", "C", 9, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {14, "Ordenar por              ?", "N", 1, 0,  "",   "   ", {"Data","Documento","Cli/Forn","UF"},   ""})
	aadd (_aRegsPerg, {15, "Listar                   ?", "N", 1, 0,  "",   "   ", {"Saidas","Entradas","Ambos"},          ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
