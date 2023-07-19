// Programa...: VA_XLS51
// Autor......: Cláudia Lionço
// Data.......: 24/08/2020
// Descricao..: Exporta planiha com rateios CC auxiliares para produtivos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planiha com rateios CC auxiliares para produtivos
// #PalavasChave      #rateios #rateios_CC 
// #TabelasPrincipais #CT2 #CTT 
// #Modulos 		  #CTB 
//
// Historico de alteracoes:
// 
// --------------------------------------------------------------------------
User Function VA_XLS51()
	Private cPerg   := "VAXLS51"
	
	_ValidPerg()

	If Pergunte (cPerg, .T.)
		If !empty(mv_par01) .and. !empty(mv_par02)
			Processa( { |lEnd| _Gera() } )
		Else
			u_help("Deve-se preencher os parametros de ano inicial e final!")
		EndIf
	Endif

Return
//	
// --------------------------------------------------------------------------
// Geração da planilha
Static Function _Gera()
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	
	//ENCONTRA LOTES DE LCTOS CONTENDO RATEIOS								
	_oSQL:_sQuery := " WITH LOTES"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		CT2_FILIAL"
	_oSQL:_sQuery += " 	   ,CT2_DATA"
	_oSQL:_sQuery += " 	   ,CT2.CT2_CCC"
	_oSQL:_sQuery += " 	   ,CT2_CCD AS CC_DESTINO"
	_oSQL:_sQuery += " 	   ,CT2_VALOR"
	_oSQL:_sQuery += " 	   ,CT2_LOTE"
	_oSQL:_sQuery += " 	   ,CT2_SBLOTE"
	_oSQL:_sQuery += " 	   ,CT2_DOC"
	_oSQL:_sQuery += " 	   ,CT2_LINHA"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("CT2") + " CT2 "
	_oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND CT2_DATA <= '20190831'" 		 // ULTIMO MES EM QUE USAMOS RATEIO ONLINE, NAO ADIANTA BUSCAR PERIODO POSTERIOR.							
	_oSQL:_sQuery += " 	AND ((CT2_CREDIT = ''"
	_oSQL:_sQuery += " 	AND CT2_DEBITO LIKE '701011001%')"
	_oSQL:_sQuery += " 	OR (CT2_DEBITO = ''"
	_oSQL:_sQuery += " 	AND CT2_CREDIT LIKE '701011001%'))"  // RATEIO ONLINE SEMPRE TEM UMA PERNA DO LCTO VAZIA					
	_oSQL:_sQuery += " 	AND CT2_ROTINA = 'CTBA102'"
	_oSQL:_sQuery += " 	AND CT2.CT2_LOTE != '008840'"  		 // CONTABILIZACAO GERADA PELO CUSTO MEDIO							
	//VOU DESCONSIDERAR ESTES LOTES POR QUE PARECEM AJUSTES (TEM ORIGENS E DESTINOS ESTRANHOS E NAO FECHA NENHUMA SOMA DE ORIGENS PARA CHEGAR A UM DESTINO)							
	_oSQL:_sQuery += " 	AND NOT (CT2_FILIAL = '01'"
	_oSQL:_sQuery += " 	AND CT2_DATA = '20181231'"
	_oSQL:_sQuery += " 	AND CT2_LOTE = '000001'"
	_oSQL:_sQuery += " 	AND CT2_SBLOTE = '001'"
	_oSQL:_sQuery += " 	AND CT2_DOC = '000114')"
	_oSQL:_sQuery += " 	AND NOT (CT2_FILIAL = '01'"
	_oSQL:_sQuery += " 	AND CT2_DATA = '20180831'"
	_oSQL:_sQuery += " 	AND CT2_LOTE = '000001'"
	_oSQL:_sQuery += " 	AND CT2_SBLOTE = '001'"
	_oSQL:_sQuery += " 	AND CT2_DOC = '000071')"
	_oSQL:_sQuery += " 	AND NOT (CT2_FILIAL = '01'"
	_oSQL:_sQuery += " 	AND CT2_DATA = '20170630'"
	_oSQL:_sQuery += " 	AND CT2_LOTE = '000001'"
	_oSQL:_sQuery += " 	AND CT2_SBLOTE = '001'"
	_oSQL:_sQuery += " 	AND CT2_DOC = '000075')),"
	_oSQL:_sQuery += " RATEIO_ONLINE"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		'ONLINE' AS TIPO_RATEIO"
	_oSQL:_sQuery += " 	   ,CT2_FILIAL"
	_oSQL:_sQuery += " 	   ,CT2_DATA"
	_oSQL:_sQuery += " 	   ,(SELECT TOP 1"
	_oSQL:_sQuery += " 				CT2_CCC"
	_oSQL:_sQuery += " 			FROM LOTES L2"
	_oSQL:_sQuery += " 			WHERE L2.CT2_FILIAL = LOTES.CT2_FILIAL"
	_oSQL:_sQuery += " 			AND L2.CT2_DATA = LOTES.CT2_DATA"
	_oSQL:_sQuery += " 			AND L2.CT2_LOTE = LOTES.CT2_LOTE"
	_oSQL:_sQuery += " 			AND L2.CT2_SBLOTE = LOTES.CT2_SBLOTE"
	_oSQL:_sQuery += " 			AND L2.CT2_DOC = LOTES.CT2_DOC"
	_oSQL:_sQuery += " 			AND L2.CT2_LINHA < LOTES.CT2_LINHA"
	_oSQL:_sQuery += " 			AND CT2_CCC != ''"
	_oSQL:_sQuery += " 			ORDER BY L2.CT2_LINHA DESC)"
	_oSQL:_sQuery += " 		AS CC_ORIGEM"
	_oSQL:_sQuery += " 	   ,CC_DESTINO"
	_oSQL:_sQuery += " 	   ,CT2_VALOR"
	_oSQL:_sQuery += " 	   ,CT2_LOTE"
	_oSQL:_sQuery += " 	   ,CT2_SBLOTE"
	_oSQL:_sQuery += " 	   ,CT2_DOC"
	_oSQL:_sQuery += " 	   ,CT2_LINHA"
	_oSQL:_sQuery += " 	FROM LOTES"
	_oSQL:_sQuery += " 	WHERE CT2_CCC = ''"  // REMOVE A LINHA DE LCTO A CREDITO, POIS SERVIU APENAS PARA A SUBSTRING QUE BUSCA O 'CC_ORIGEM'								
	_oSQL:_sQuery += " ),"
	_oSQL:_sQuery += " RATEIO_OFFLINE"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		'OFFLINE' AS TIPO_RATEIO"
	_oSQL:_sQuery += " 	   ,CT2_FILIAL"
	_oSQL:_sQuery += " 	   ,CT2_DATA"
	_oSQL:_sQuery += " 	   ,CT2_CCC AS CC_ORIGEM"
	_oSQL:_sQuery += " 	   ,CT2_CCD AS CC_DESTINO"
	_oSQL:_sQuery += " 	   ,CT2_VALOR"
	_oSQL:_sQuery += " 	   ,CT2_LOTE"
	_oSQL:_sQuery += " 	   ,CT2_SBLOTE"
	_oSQL:_sQuery += " 	   ,CT2_DOC"
	_oSQL:_sQuery += " 	   ,CT2_LINHA"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("CT2") 
	_oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND CT2_DATA >= '20190930' " 	//PRIMEIRO MES EM QUE USAMOS RATEIO OFFLINE								
	_oSQL:_sQuery += " 	AND CT2_DEBITO LIKE '701011001%'"
	_oSQL:_sQuery += " 	AND CT2_CREDIT LIKE '701011001%'"
	_oSQL:_sQuery += " 	AND CT2_ROTINA = 'CTBA280'),"
	_oSQL:_sQuery += " VA_VRATEIOS_CC_AUX"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		TIPO_RATEIO"
	_oSQL:_sQuery += " 	   ,CT2_FILIAL AS FILIAL"
	_oSQL:_sQuery += " 	   ,SUBSTRING(CT2_DATA, 1, 4) AS ANO"
	_oSQL:_sQuery += " 	   ,SUBSTRING(CT2_DATA, 5, 2) AS MES"
	_oSQL:_sQuery += " 	   ,CC_ORIGEM"
	_oSQL:_sQuery += " 	   ,CTT_O.CTT_DESC01 AS DESC_CC_ORIG"
	_oSQL:_sQuery += " 	   ,CC_DESTINO"
	_oSQL:_sQuery += " 	   ,CTT_D.CTT_DESC01 AS DESC_CC_DEST"
	_oSQL:_sQuery += " 	   ,CT2_VALOR AS VALOR"
	_oSQL:_sQuery += " 	   ,CT2_LOTE"
	_oSQL:_sQuery += " 	   ,CT2_SBLOTE"
	_oSQL:_sQuery += " 	   ,CT2_DOC"
	_oSQL:_sQuery += " 	   ,CT2_LINHA"
	_oSQL:_sQuery += " 	FROM (SELECT"
	_oSQL:_sQuery += " 			*"
	_oSQL:_sQuery += " 		FROM RATEIO_ONLINE UNION ALL SELECT"
	_oSQL:_sQuery += " 			*"
	_oSQL:_sQuery += " 		FROM RATEIO_OFFLINE) AS C"
	_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("CTT") + " CTT_O "   
	_oSQL:_sQuery += " 		ON (CTT_O.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND CTT_O.CTT_FILIAL = '  '"
	_oSQL:_sQuery += " 		AND CTT_O.CTT_CUSTO = CC_ORIGEM)"
	_oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("CTT") + " CTT_D "
	_oSQL:_sQuery += " 		ON (CTT_D.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND CTT_D.CTT_FILIAL = '  '"
	_oSQL:_sQuery += " 		AND CTT_D.CTT_CUSTO = CC_DESTINO))"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	*"
	_oSQL:_sQuery += " FROM VA_VRATEIOS_CC_AUX"
	_oSQL:_sQuery += " WHERE ANO BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"	
	_oSQL:Log ()
	_oSQL:Qry2XLS (.F., .F., .T.)	

Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT        TIPO TAM DEC VALID F3     Opcoes          	    Help
	aadd (_aRegsPerg, {01, "Ano Inicial ", "C", 4,  0,  "",   "   ", {},                   	""})
	aadd (_aRegsPerg, {02, "Ano Final   ", "C", 4,  0,  "",   "   ", {},                   	""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return

