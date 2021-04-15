//  Programa...: VA_COMEXE/VA_COMITNF 
//  Autor......: Cláudia Lionço
//  Data.......: 10/07/2020
//  Descricao..: Consulta de titulos principal para relatorio/email de comissões
//               Consulta de itens das notas principal para relatorio/email de comissões
//
// #TipoDePrograma    #consulta
// #PalavasChave      #comissoes #verbas #bonificação #comissões #representante #comissão
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 #SE5 #SA3
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 14/04/2021 - Cláudia - Melhoria na consulta com o plano de execução estimado (SQL)
//
// -------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_COMEXE(_dtaIni, _dtaFin, _sVend, _nLibPg)
	Local _oSQL  := ClsSQL ():New ()
	Local _sAliasQ  := ""

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	E3_VEND AS VENDEDOR"
	_oSQL:_sQuery += "    ,A3_NOME AS NOM_VEND"
	_oSQL:_sQuery += "    ,E3_PREFIXO AS PREFIXO"
	_oSQL:_sQuery += "    ,E3_NUM AS NUMERO"
	_oSQL:_sQuery += "    ,E3_PARCELA AS PARCELA"
	_oSQL:_sQuery += "    ,E3_CODCLI AS CODCLI"
	_oSQL:_sQuery += "    ,A1_NOME AS NOMECLIENTE"
	_oSQL:_sQuery += "    ,A1_NREDUZ AS NOMEREDUZIDO"
	_oSQL:_sQuery += "    ,F2_VALBRUT AS TOTAL_NF"
	_oSQL:_sQuery += "    ,F2_VALIPI AS IPI_NF"
	_oSQL:_sQuery += "    ,F2_ICMSRET AS ST_NF"
	_oSQL:_sQuery += "    ,(SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(D2_TOTAL), 2) AS VLR_COM"
	_oSQL:_sQuery += " 		FROM SD2010 AS SD2"
	_oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_oSQL:_sQuery += " 			ON (SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND SF4.F4_FILIAL ='" + xFilial('SF4') + "' "  
	_oSQL:_sQuery += " 			AND SF4.F4_CODIGO = SD2.D2_TES"
	_oSQL:_sQuery += " 			AND SF4.F4_MARGEM = '3')"
	_oSQL:_sQuery += " 		WHERE SD2.D2_FILIAL = SF2.F2_FILIAL"
	_oSQL:_sQuery += " 		AND SD2.D2_DOC = SF2.F2_DOC"
	_oSQL:_sQuery += " 		AND SD2.D2_SERIE = SF2.F2_SERIE"
	_oSQL:_sQuery += " 		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE"
	_oSQL:_sQuery += " 		AND SD2.D2_LOJA = SF2.F2_LOJA"
	_oSQL:_sQuery += " 		AND SD2.D2_EMISSAO = SF2.F2_EMISSAO"
	_oSQL:_sQuery += " 		GROUP BY SD2.D2_FILIAL"
	_oSQL:_sQuery += " 				,SD2.D2_DOC"
	_oSQL:_sQuery += " 				,SD2.D2_SERIE)"
	_oSQL:_sQuery += " 	AS BONIF_NF"
	_oSQL:_sQuery += "    ,F2_FRETE AS FRETE_NF"
	_oSQL:_sQuery += "    ,E1_BASCOM1 AS BASE_TIT"
	_oSQL:_sQuery += "    ,E1_VENCTO AS VENCIMENTO"
	_oSQL:_sQuery += "    ,E3_PEDIDO AS PEDIDO"
	_oSQL:_sQuery += "    ,E1_VALOR AS VALOR_TIT"
	_oSQL:_sQuery += "    ,ISNULL((SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(E5_VALOR), 2)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " AS SE5 "
	_oSQL:_sQuery += " 		WHERE E5_FILIAL = E3_FILIAL"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += " 		AND E5_RECPAG = 'R'"
	_oSQL:_sQuery += " 		AND E5_SITUACA != 'C'"
	_oSQL:_sQuery += " 		AND E5_NUMERO = E3_NUM"
	_oSQL:_sQuery += " 		AND (E5_TIPODOC = 'DC'"
	_oSQL:_sQuery += " 		OR (E5_TIPODOC = 'CP'"
	_oSQL:_sQuery += " 		AND E5_DOCUMEN NOT LIKE '% RA %'))"
	_oSQL:_sQuery += " 		AND E5_PREFIXO = E3_PREFIXO"
	_oSQL:_sQuery += " 		AND E5_PARCELA = E3_PARCELA"
	_oSQL:_sQuery += " 		AND E5_SEQ = E3_SEQ"
	_oSQL:_sQuery += " 		AND E5_DATA BETWEEN '"+ dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " 		GROUP BY E5_FILIAL"
	_oSQL:_sQuery += " 				,E5_RECPAG"
	_oSQL:_sQuery += " 				,E5_NUMERO"
	_oSQL:_sQuery += " 				,E5_PARCELA"
	_oSQL:_sQuery += " 				,E5_PREFIXO)"
	_oSQL:_sQuery += " 	 , 0) AS VLR_DESCONTO "
	_oSQL:_sQuery += "    ,ISNULL((SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(E5_VALOR), 2)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " AS SE5 "
	_oSQL:_sQuery += " 		WHERE E5_FILIAL = E3_FILIAL"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += " 		AND E5_RECPAG = 'R'"
	_oSQL:_sQuery += " 		AND E5_NUMERO = E3_NUM"
	_oSQL:_sQuery += " 		AND (E5_TIPODOC = 'VL'"
	_oSQL:_sQuery += " 		OR (E5_TIPODOC = 'CP'"
	_oSQL:_sQuery += " 		AND E5_DOCUMEN LIKE '% RA %'))"
	_oSQL:_sQuery += " 		AND E5_PREFIXO = E3_PREFIXO"
	_oSQL:_sQuery += " 		AND E5_PARCELA = E3_PARCELA"
	_oSQL:_sQuery += " 		AND E5_SEQ = E3_SEQ"
	_oSQL:_sQuery += " 		AND E5_DATA BETWEEN '"+ dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " 		GROUP BY E5_FILIAL"
	_oSQL:_sQuery += " 				,E5_RECPAG"
	_oSQL:_sQuery += " 				,E5_NUMERO"
	_oSQL:_sQuery += " 				,E5_PARCELA"
	_oSQL:_sQuery += " 				,E5_PREFIXO)"
	_oSQL:_sQuery += " 	  , 0) AS VLR_RECEBIDO"
	_oSQL:_sQuery += "    ,E3_BASE AS BASE_COMIS"
	_oSQL:_sQuery += "    ,E3_PORC AS PERCENTUAL"
	_oSQL:_sQuery += "    ,E3_COMIS AS VLR_COMIS"
	_oSQL:_sQuery += "    ,A3_INDENIZ AS INDENIZ"
	_oSQL:_sQuery += "    ,E3_LOJA AS LOJA"
	_oSQL:_sQuery += "    ,E1_BAIXA AS BAIXA"
	_oSQL:_sQuery += "    ,E1_SALDO AS SALDO"
	_oSQL:_sQuery += "    ,E3_EMISSAO AS DT_COMIS"
	_oSQL:_sQuery += "    ,ISNULL((SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(E5_VALOR), 2)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " AS SE5 "
	_oSQL:_sQuery += " 		WHERE E5_FILIAL = E3_FILIAL"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += " 		AND E5_RECPAG = 'R'"
	_oSQL:_sQuery += " 		AND E5_NUMERO = E3_NUM"
	_oSQL:_sQuery += " 		AND E5_TIPODOC = 'JR'"
	_oSQL:_sQuery += " 		AND E5_PREFIXO = E3_PREFIXO"
	_oSQL:_sQuery += " 		AND E5_PARCELA = E3_PARCELA"
	_oSQL:_sQuery += " 		AND E5_SEQ = E3_SEQ"
	_oSQL:_sQuery += " 		AND E5_DATA BETWEEN '"+ dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " 		GROUP BY E5_FILIAL"
	_oSQL:_sQuery += " 				,E5_RECPAG"
	_oSQL:_sQuery += " 				,E5_NUMERO"
	_oSQL:_sQuery += " 				,E5_PARCELA"
	_oSQL:_sQuery += " 				,E5_PREFIXO)"
	_oSQL:_sQuery += " 	, 0) AS VLR_JUROS"
	_oSQL:_sQuery += "    ,ISNULL((SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(E5_VALOR), 2)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " AS SE5 "
	_oSQL:_sQuery += " 		WHERE E5_FILIAL = E3_FILIAL"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += " 		AND E5_RECPAG = 'P'"
	_oSQL:_sQuery += " 		AND E5_NUMERO = E3_NUM"
	_oSQL:_sQuery += " 		AND E5_TIPODOC = 'ES'"
	_oSQL:_sQuery += " 		AND E5_MOTBX != 'CMP'"
	_oSQL:_sQuery += " 		AND E5_PREFIXO = E3_PREFIXO"
	_oSQL:_sQuery += " 		AND E5_PARCELA = E3_PARCELA"
	_oSQL:_sQuery += " 		AND E5_SEQ = E3_SEQ"
	_oSQL:_sQuery += " 		AND E5_DATA BETWEEN '"+ dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " 		GROUP BY E5_FILIAL"
	_oSQL:_sQuery += " 				,E5_RECPAG"
	_oSQL:_sQuery += " 				,E5_NUMERO"
	_oSQL:_sQuery += " 				,E5_PARCELA"
	_oSQL:_sQuery += " 				,E5_PREFIXO)"
	_oSQL:_sQuery += " 	 , 0) AS VLR_PG_ESTORNADO"
	_oSQL:_sQuery += "   ,ISNULL((SELECT"
	_oSQL:_sQuery += " 			ROUND(SUM(E5_VALOR), 2)"
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SE5") + " AS SE5 "
	_oSQL:_sQuery += " 		WHERE E5_FILIAL = E3_FILIAL"
	_oSQL:_sQuery += " 		AND D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += " 		AND E5_RECPAG = 'P'"
	_oSQL:_sQuery += " 		AND E5_NUMERO = E3_NUM"
	_oSQL:_sQuery += " 		AND E5_TIPODOC = 'ES'"
	_oSQL:_sQuery += " 		AND E5_MOTBX = 'CMP'"
	_oSQL:_sQuery += " 		AND E5_PREFIXO = E3_PREFIXO"
	_oSQL:_sQuery += " 		AND E5_PARCELA = E3_PARCELA"
	_oSQL:_sQuery += " 		AND E5_SEQ = E3_SEQ"
	_oSQL:_sQuery += " 		AND E5_DATA BETWEEN '"+ dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " 		GROUP BY E5_FILIAL"
	_oSQL:_sQuery += " 				,E5_RECPAG"
	_oSQL:_sQuery += " 				,E5_NUMERO"
	_oSQL:_sQuery += " 				,E5_PARCELA"
	_oSQL:_sQuery += " 				,E5_PREFIXO)"
	_oSQL:_sQuery += " 	  , 0) AS VLR_CP_ESTORNADO"
	_oSQL:_sQuery += "    ,SA2.A2_SIMPNAC AS SIMPLES"
	_oSQL:_sQuery += "    ,RTRIM(SA2.A2_BANCO) AS BANCO"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '001' THEN 'BANDO DO BRASIL'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '041' THEN 'BANRISUL'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '748' THEN 'SICRED'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '237' THEN 'BRADESCO'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '341' THEN 'ITAU'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '104' THEN 'CAIXA FEDERAL'"
	_oSQL:_sQuery += " 		WHEN RTRIM(SA2.A2_BANCO) = '746' THEN 'SICOOB'"
	_oSQL:_sQuery += " 		ELSE ''"
	_oSQL:_sQuery += " 	END AS NOMEBANCO"
	_oSQL:_sQuery += "    ,RTRIM(SA2.A2_AGENCIA) + '-' + RTRIM(SA2.A2_DVAGE) AS AGENCIA"
	_oSQL:_sQuery += "    ,RTRIM(SA2.A2_NUMCON) + '-' + RTRIM(SA2.A2_DVCTA) AS CONTA"
	_oSQL:_sQuery += "    ,SF2.F2_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,SE3.E3_TIPO AS E3_TIPO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE3") + " AS SE3 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
	_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND SA3.A3_FILIAL = '" + xFilial('SA3') + "' "  
	If mv_par09 = 1 // Não considera bloqueados
		_oSQL:_sQuery += " 			AND SA3.A3_MSBLQL != '1'"
		_oSQL:_sQuery += " 			AND SA3.A3_ATIVO != 'N'"
	EndIf
	_oSQL:_sQuery += " 			AND SA3.A3_COD = SE3.E3_VEND)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " AS SE1 "
	_oSQL:_sQuery += " 	ON (SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SE1.E1_FILIAL = SE3.E3_FILIAL"
	_oSQL:_sQuery += " 			AND SE1.E1_NUM = SE3.E3_NUM"
	_oSQL:_sQuery += " 			AND SE1.E1_PARCELA = SE3.E3_PARCELA"
	_oSQL:_sQuery += " 			AND SE1.E1_PREFIXO = SE3.E3_PREFIXO"
	_oSQL:_sQuery += " 			AND SE1.E1_TIPO = SE3.E3_TIPO"
	_oSQL:_sQuery += " 			AND SE1.E1_CLIENTE = SE3.E3_CODCLI)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_oSQL:_sQuery += " 	ON (SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND SF2.F2_FILIAL = SE3.E3_FILIAL"
	_oSQL:_sQuery += " 			AND SF2.F2_DOC = SE3.E3_NUM"
	_oSQL:_sQuery += " 			AND SF2.F2_SERIE = SE3.E3_PREFIXO"
	_oSQL:_sQuery += " 			AND SF2.F2_CLIENTE = SE3.E3_CODCLI"
	_oSQL:_sQuery += " 			AND SF2.F2_LOJA = SE3.E3_LOJA)"
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA2") + " AS SA2 "
	_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND A2_FILIAL = '" + xFilial('SA2') + "' "  
	_oSQL:_sQuery += " 			AND SA2.A2_COD = SA3.A3_FORNECE"
	_oSQL:_sQuery += " 			AND SA2.A2_LOJA = SA3.A3_LOJA)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND SA1.A1_FILIAL = '" + xFilial('SA1') + "' "  
	_oSQL:_sQuery += " 			AND SA1.A1_COD = SE3.E3_CODCLI"
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SE3.E3_LOJA)"
	_oSQL:_sQuery += " WHERE E3_FILIAL = '" + xFilial('SE3') + "' "  
	_oSQL:_sQuery += " AND E3_VEND = '" + _sVend + "'"
	_oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '" + dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " AND E3_BAIEMI = 'B'"
	_oSQL:_sQuery += " AND SE3.D_E_L_E_T_ = ''"
	If _nLibPg = 1  	// comissoes liberadas
		_oSQL:_sQuery += " AND E3_DATA = ''"
	Else 				// comissoes pagas
		_oSQL:_sQuery += " AND E3_DATA != ''"
	EndIf
	_oSQL:_sQuery += " ORDER BY E3_VEND, E3_NUM, E3_PARCELA"
	_oSQL:Log ()
	
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	

Return _sAliasQ
// ---------------------------------------------------------------------------------------------------------------
// Consulta de itens das notas principal para relatorio/email de comissões
//
User Function VA_COMITNF(_sFilial, _sNota, _sSerie, _nBaseComis, _nVlrComis, _nBaseNota)
	Local _oSQL    := ClsSQL ():New ()
	Local _aItens  := {}
	Local i        := 0

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SD2.D2_COD, SB1.B1_DESC, SD2.D2_COMIS1, SD2.D2_TOTAL"
	_oSQL:_sQuery += " FROM SD2010 AS SD2"
	_oSQL:_sQuery += " 	  INNER JOIN SB1010 AS SB1"
	_oSQL:_sQuery += " 		 ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			 AND SB1.B1_COD = SD2.D2_COD)"
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SD2.D2_FILIAL  = '" + _sFilial + "'"
	_oSQL:_sQuery += " AND SD2.D2_DOC     = '" + _sNota   + "'"  
	_oSQL:_sQuery += " AND SD2.D2_SERIE   = '" + _sSerie  + "'"
	_oSQL:_sQuery += " ORDER BY SD2.D2_COD "
	_aDados := aclone (_oSQL:Qry2Array ())
	
	If len (_aDados) > 0
		_nBaseArred := _nBaseComis
		_nVlrArred  := _nVlrComis
		
		For i=1 to len(_aDados)
			_sCodPro  := _aDados[i,1]
			_sDescPro := _aDados[i,2]
			_nPerComI := _aDados[i,3]
			_nVlrItem := _aDados[i,4]
	
			_nLibItem   :=  ROUND(_nVlrItem * _nBaseComis / _nBaseNota,2) // ajusta diferença centavos no ultimo item - BASE COMISSAO LIBERADA
			_nBaseArred := _nBaseArred - _nLibItem
			If i = len(_aDados).and. _nBaseArred <> _nLibItem
				_nLibItem := _nLibItem + _nBaseArred
			EndIf
			
			_nComItem  := ROUND(_nLibItem * _nPerComI /100,2) // ajusta diferença centavos no ultimo item - VALOR COMISSAO
			_nVlrArred := _nVlrArred - _nComItem 
			If i = len(_aDados) .and. _nVlrArred <> _nComItem 
				_nComItem := _nComItem + _nVlrArred 	
			EndIf
			
			// Cria array de itens para impressão
			AADD(_aItens, { _sCodPro	,;
							_sDescPro 	,;
							_nVlrItem	,;
							_nLibItem	,;
							_nPerComI	,;
							_nComItem	})

		Next
	EndIf					
Return _aItens
