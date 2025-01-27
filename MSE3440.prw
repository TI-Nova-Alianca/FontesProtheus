// Programa..: MSE3440
// Autor.....: Robert Koch
// Data......: 09/02/2011
// Descricao.: P.E. apos a gravacao do SE3 (reg.ainda bloqueado) no (re)calculo de comissoes.
// 
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos a gravacao do SE3 (reg.ainda bloqueado) no (re)calculo de comissoes.
// #PalavasChave      #comissões #comissoes #calculo #recalculo 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 07/11/2014 - Catia   - Recalcular comissoes e salvar no SE3 nos campos padrao
// 13/11/2014 - Catia   - Passado a gravar o campo desconto no SE3
// 03/12/2014 - Catia   - Refazer a base de comissao no E1 conforme calculado na nota
// 07/01/2015 - Catia   - Buscar os descontos e compensacoes totais do mes para o titulo 
//						  (deve ter apenas um registro por titulo)
// 21/01/2015 - Catia   - Ao rodas o recalculo retroativo, dava erro pq nao achava a nota no SF2, 
//						  incluido teste do retorno do array
// 27/01/2015 - Catia   - Passado a considerar o valor estornado nos titulos - casos dos cancelamentos de baixas
// 20/02/2015 - Catia   - alterado para que busque e considere as bonificacoes no calculo das comissoes.
// 04/03/2015 - Catia   - considerar no estorno apenas os estornos de baixas - desconsiderar os estornos de compensaçoes
// 11/03/2015 - Robert  - Testa se estah dentro da rotina de preparacao de nota fiscal.
// 17/05/2015 - Catia   - desconsiderar o frete tambem na base da comissao F2_FRETE
// 02/10/2015 - Catia   - Cancelamento de descontos e compensações - aparecia em duplicidade no relatorio
// 12/01/2016 - Catia   - tratamento para os RA (recebimento antecipado)
// 23/03/2018 - Catia   - percentual de comissao do vendedor 2 estava pegando errado - estava pegando igual ao 
//				          do primeiro vendedor
// 26/06/2018 - Catia   - posicionado o SE1 para que fique mais rapido o processamento - nos testes funcionou - 
//                        aguardar o ok da Andresa
// 10/08/2020 - Cláudia - Criado novo calculo de comissões com base em informações do Cesar, conforme GLI: 7899
// 05/04/2021 - Robert  - Incluidas chamadas da funcao PerfMon para monitoramento de tempos na emissao de cupom (GLPI 9573).
// 05/05/2021 - Cláudia - Adicionado valor de frete + seguro + despesas acessorias. GLPI: 9895
// 02/06/2021 - Claudia - Ajuste de descontos de ST e IPI. GLPI: 10051
// 22/07/2021 - Claudia - Incluida a divisão das parcelas para ST/IPI no "IPI distribuídos nas "N" parcelas".GLPI: 10539
// 05/09/2022 - Claudia - Incluso variaveis _VLRSEG, _VLFRETE, _vlrDesp - GLPI: 12563
// 16/02/2023 - Claudia - Descontado os juros da base liberada. GLPI: 13200
// 29/08/2023 - Claudia - Ajustes de devoluções/compensação. GLPI: 13795
// 31/08/2023 - Claudia - Ajustes em compensação de titulos RA. GLPI: 13536
//
// -----------------------------------------------------------------------------------------------------------------------------------
/*
#XTranslate .PercPercComis   => 1
#XTranslate .PercTotNFPerc   => 2
#XTranslate .PercTotNFGeral  => 3
#XTranslate .PercLiquido     => 4
#XTranslate .PercNovaBase    => 5
#XTranslate .PercNovoPerc    => 6
#XTranslate .PercNovaComis   => 7
#XTranslate .PercQtColunas   => 7
*/
// --------------------------------------------------------------------------
User Function MSE3440 ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nNovaBase := 0
	local _nNovaComi := 0
	local _lContinua := .T.
	local _x         := 0
	
	u_logIni ()
	u_log("gravando")
	
	// Se estiver sendo chamado a partir da rotina de preparacao de notas, nao executa.
	If _lContinua .and. (IsInCallStack ("MATA460A") .or. IsInCallStack ("MATA460B"))
		u_log ('Estou executando a partir da rotina de preparacao de notas. Abortando.')
		_lContinua = .F.
	Endif
	
	If _lContinua .and. IsInCallStack ("LOJA701")
		U_PerfMon ('I', 'MSE3440_em_LOJA701')  // Deixa variavel pronta para posterior medicao de tempos de execucao
	endif
	
	// Posiciona no contas a receber para buscar e atualizar dados.
	If _lContinua
		se1 -> (dbsetorder (1))
		u_log("1. " + se3 -> e3_num)
		If ! se1 -> (msSeek (xfilial ("SE1") + se3 -> e3_prefixo + se3 -> e3_num + se3 -> e3_parcela + se3 -> e3_tipo, .F.))
			u_help ('Titulo a receber nao encontrado: ' + xfilial ("SE1") + se3 -> e3_prefixo + se3 -> e3_num + se3 -> e3_parcela + se3 -> e3_tipo)
			_lContinua = .F.
		Endif
	Endif

	// busca dados do vendedor que esta lendo no SE3
	If _lContinua
		//u_log("2. " + se3 -> e3_num)
		//If se3->e3_num == '000242888'
		//	u_help("Nota")
		//EndIf
		_vend1     := se1 -> e1_vend1   
		_vend2     := se1 -> e1_vend2   
		_baseComis := se1 -> e1_bascom1 
		_valorTit  := se1 -> e1_valor
		_parcela   := se1 -> e1_parcela
			
		If se3 -> e3_vend == _vend1
			_npercSE3 := se1 -> e1_comis1 
		Elseif se3 -> e3_vend == _vend2
			_npercSE3 := se1 -> e1_comis2 
		Endif
		// monta data inicial e final para compor os valores de descontos, compensacoes e juros
		w_dtini    := substr (dtos (se3 -> e3_emissao),1,6) + '01'
		w_dtfim    := substr (dtos (se3 -> e3_emissao),1,6) + '31'
		//
		// **********************************************************************************************
		//Valor recebido
		_vlrRec := 0
		_sQuery := ""
		_sQuery += " SELECT 
		_sQuery += " 	ROUND(SUM(E5_VALOR), 2)"
		_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_sQuery += " AND E5_FILIAL  = '" + se3->e3_filial  + "'"
		_sQuery += " AND E5_NUMERO  = '" + se3->e3_num     + "'"
		_sQuery += " AND E5_PREFIXO = '" + se3->e3_prefixo + "'"
		_sQuery += " AND E5_PARCELA = '" + se3->e3_parcela + "'"
		_sQuery += " AND E5_CLIFOR 	= '" + se3->e3_codcli  + "'"
		_sQuery += " AND E5_LOJA   	= '" + se3->e3_loja    + "'"
		_sQuery += " AND E5_SEQ  	= '" + se3->e3_seq     + "'"
		_sQuery += " AND E5_RECPAG 	= 'R'"
		_sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '%RA%'))"
		_sQuery += " AND E5_DATA BETWEEN  '" + w_dtini + "' AND '" + w_dtfim + "'"
			
		_aVlrRec := U_Qry2Array(_sQuery)

		If Len(_aVlrRec) > 0
			_vlrRec := _aVlrRec[1,1]
		Else
			_vlrRec := 0
		EndIf
		// //
		// // **********************************************************************************************
		// // valor recebido no titulo
		// _vlrReceb := 0
		// _sQuery := ""
		// _sQuery += " SELECT 
		// _sQuery += " 	ROUND(SUM(E5_VALOR), 2)"
		// _sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		// _sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		// _sQuery += " AND E5_FILIAL  = '" + se1->e1_filial  +"'"
		// _sQuery += " AND E5_NUMERO  = '" + se1->e1_num     + "'"
		// _sQuery += " AND E5_PREFIXO = '" + se1->e1_prefixo + "'"
		// _sQuery += " AND E5_PARCELA = '" + se1->e1_parcela + "'"
		// _sQuery += " AND E5_CLIFOR 	= '" + se1->e1_cliente + "'"
		// _sQuery += " AND E5_LOJA   	= '" + se1->e1_loja    + "'"
		// _sQuery += " AND E5_RECPAG 	= 'R'"
		// _sQuery += " AND E5_SITUACA!= 'C'"
		// _sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
		// _sQuery += " AND E5_DATA BETWEEN '" + w_dtini + "' AND '" + w_dtfim + "'"
		// _aReceb := U_Qry2Array(_sQuery)

		// If Len(_aReceb)>0
		// 	_vlrReceb := _aReceb[1,1]
		// Else
		// 	_vlrReceb := 0
		// EndIf
		//
		// **********************************************************************************************
		//busca descontos do título
		_vlrDesc := 0
		_sQuery := ""
		_sQuery += " SELECT 
		_sQuery += " 	ROUND(SUM(E5_VALOR), 2)"
		_sQuery += " ,ROUND(SUM(E5_VARAPEL), 2)"
		_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_sQuery += " AND E5_FILIAL  = '" + se3->e3_filial  +"'"
		_sQuery += " AND E5_NUMERO  = '" + se3->e3_num     + "'"
		_sQuery += " AND E5_PREFIXO = '" + se3->e3_prefixo + "'"
		_sQuery += " AND E5_PARCELA = '" + se3->e3_parcela + "'"
		_sQuery += " AND E5_CLIFOR 	= '" + se3->e3_codcli  + "'"
		_sQuery += " AND E5_LOJA   	= '" + se3->e3_loja    + "'"
		_sQuery += " AND E5_SEQ  	= '" + se3->e3_seq     + "'"
		_sQuery += " AND E5_RECPAG 	= 'R'"
		_sQuery += " AND E5_SITUACA != 'C'"
		_sQuery += " AND (E5_TIPODOC = 'DC' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '%NCC%') AND (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '%RA%'))"
		//_sQuery += " AND (E5_TIPODOC = 'DC' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '% RA %') OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '%NCC%'))"
		_sQuery += " AND E5_DATA BETWEEN '" + w_dtini + "' AND '" + w_dtfim + "'"
		_aDesc := U_Qry2Array(_sQuery)
		
		If Len(_aDesc) > 0
			_vlrDesc := _aDesc[1,1]
		Else
			_vlrDesc := 0
		EndIf
		//
		// **********************************************************************************************
		// valor estornado no titulo
		_vlrEstorno := 0
		_sSQL := ""
		_sSQL += " SELECT ROUND(SUM(E5_VALOR),2)"
		_sSQL += "   FROM " + RetSQLName ("SE5") + " AS SE5 "
		_sSQL += " WHERE E5_FILIAL   = '" + xfilial ("SE5") + "'"
		_sSQL += " AND D_E_L_E_T_  = ''"
		_sSQL += " AND E5_RECPAG   = 'P'"
		_sSQL += " AND E5_NUMERO   = '" + se3 -> e3_num     + "'"
		_sSQL += " AND E5_PREFIXO  = '" + se3 -> e3_prefixo + "'"
		_sSQL += " AND E5_PARCELA  = '" + se3 -> e3_parcela + "'"
		_sSQL += " AND E5_TIPODOC  = 'ES'"
		_sSQL += " AND E5_MOTBX   != 'CMP'"
		_sSQL += " AND E5_DATA BETWEEN '"+ w_dtini + "' AND '" + w_dtfim + "'"
		_sSQL += " GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO "
		_aEstor := U_Qry2Array(_sSQL)
		
		If len(_aEstor) > 0
			_vlrEstorno := _aEstor[1,1]
		Else
			_vlrEstorno := 0
		Endif
		//
		// **********************************************************************************************
		// valor de juros no titulo
		_vlrJuros := 0
		_sSQL := ""
		_sSQL += " SELECT ROUND(SUM(E5_VALOR),2)"
		_sSQL += "   FROM " + RetSQLName ("SE5")
		_sSQL += " WHERE E5_FILIAL  = '" + xfilial ("SE5") + "'"
		_sSQL += " AND D_E_L_E_T_ = ''"
		_sSQL += " AND E5_NUMERO  = '" + se3 -> e3_num + "'"
		_sSQL += " AND E5_PARCELA = '" + se3 -> e3_parcela + "'"
		_sSQL += " AND E5_PREFIXO = '" + se3 -> e3_prefixo + "'"
		_sSQL += " AND E5_RECPAG  = 'R'"
		_sSQL += " AND E5_TIPODOC = 'JR'"
		_sSQL += " AND E5_SITUACA != 'C'"
		_sSQL += " AND E5_DATA BETWEEN '" + w_dtini + "' AND '" + w_dtfim + "'"
		_sSQL += " GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO"
		_aJuros := U_Qry2Array(_sSQL)
		
		If len(_aJuros) > 0
			_vlrJuros := _aJuros[1,1]
		Else
			_vlrJuros := 0
		Endif
		//
		// **********************************************************************************************
		// quantidade de parcelas do titulo
		_qtdParc := 1
		_sQuery := ""
		_sQuery += " SELECT COUNT (*) "
		_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
		_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
		_sQuery += " AND E1_FILIAL  = '" + se1->e1_filial  +"'"
		_sQuery += " AND E1_NUM     = '" + se1->e1_num     + "'"
		_sQuery += " AND E1_PREFIXO = '" + se1->e1_prefixo + "'"
		_sQuery += " AND E1_CLIENTE = '" + se1->e1_cliente + "'"
		_sQuery += " AND E1_LOJA   	= '" + se1->e1_loja    + "'"
		_aParc := U_Qry2Array(_sQuery)
		
		If Len(_aParc) > 0
			_qtdParc := _aParc[1,1]
		Else
			_qtdParc := 1
		EndIf
		//
		// **********************************************************************************************
		// condição de pagamento 
		_sQuery := ""
		_sQuery += " SELECT"
		_sQuery += " 	 SC5.C5_FILIAL"	//01
		_sQuery += "    ,SC5.C5_NUM"	//02
		_sQuery += "    ,SC5.C5_CLIENTE"//03
		_sQuery += "    ,SC5.C5_LOJACLI"//04
		_sQuery += "    ,SC5.C5_CONDPAG"//05
		_sQuery += "	,SC5.C5_PARC1"	//06
		_sQuery += "    ,SC5.C5_PARC2"	//07	
		_sQuery += "    ,SC5.C5_PARC3"	//08
		_sQuery += "    ,SC5.C5_PARC4"	//09
		_sQuery += "    ,SC5.C5_PARC5"	//10
		_sQuery += "    ,SC5.C5_PARC6"	//11
		_sQuery += "    ,SC5.C5_PARC7"	//12
		_sQuery += "    ,SC5.C5_PARC8"	//13
		_sQuery += "    ,SC5.C5_PARC9"	//14
		_sQuery += "    ,SC5.C5_PARCA"	//15
		_sQuery += "    ,SC5.C5_PARCB"	//16
		_sQuery += "    ,SC5.C5_PARCC"	//17
		_sQuery += " FROM " +  RetSQLName ("SC5") + " AS SC5" 
		_sQuery += " WHERE SC5.D_E_L_E_T_ = ''"
		_sQuery += " AND SC5.C5_FILIAL  = '" + se1->e1_filial  + "'"
		_sQuery += " AND SC5.C5_NOTA    = '" + se1->e1_num     + "'"
		_sQuery += " AND SC5.C5_SERIE   = '" + se1->e1_prefixo + "'"
		_sQuery += " AND SC5.C5_CLIENTE = '" + se1->e1_cliente + "'"
		_sQuery += " AND SC5.C5_LOJACLI = '" + se1->e1_loja    + "'"
		_aCondPgto := U_Qry2Array(_sQuery)

		If Len(_aCondPgto) > 0
			_sPedFil 	:= _aCondPgto[1,1]
			_sPedNum	:= _aCondPgto[1,2]
			_sPedCli	:= _aCondPgto[1,3]
			_sPedLoj	:= _aCondPgto[1,4]
			_sCondPgto  := _aCondPgto[1,5]
			_sParc1		:= _aCondPgto[1,6]
			_sParc2		:= _aCondPgto[1,7]
			_sParc3		:= _aCondPgto[1,8]
			_sParc4		:= _aCondPgto[1,9]
			_sParc5		:= _aCondPgto[1,10]
			_sParc6		:= _aCondPgto[1,11]
			_sParc7		:= _aCondPgto[1,12]
			_sParc8		:= _aCondPgto[1,13]
			_sParc9		:= _aCondPgto[1,14]
			_sParcA		:= _aCondPgto[1,15]
			_sParcB		:= _aCondPgto[1,16]
			_sParcC		:= _aCondPgto[1,17]
			//
			_sCondTipo := Posicione("SE4",1,'  ' + _sCondPgto,"E4_TIPO")
			_sCondIPI  := Posicione("SE4",1,'  ' + _sCondPgto,"E4_IPI") 
		Else	
			_sCondTipo  := '1'
			_sCondIPI   := 'N'
			_sParc1		:= 100
			_sParc2		:= 100
			_sParc3		:= 100
			_sParc4		:= 100
			_sParc5		:= 100
			_sParc6		:= 100
			_sParc7		:= 100
			_sParc8		:= 100
			_sParc9		:= 100
			_sParcA		:= 100
			_sParcB		:= 100
			_sParcC		:= 100
		EndIf
		//
		// **********************************************************************************************
		// busca dados da nota de IP e ST - e base de comissao prevista
		_vlrIpi 	:= 0
		_vlrST  	:= 0
		_vlrBC  	:= 0
		_vlFrete    := 0
		_Vlrseg     := 0
		_vlrDesp    := 0
		_vlrBasePrev:= _baseComis
		
		_sQuery := ""
		_sQuery += " SELECT F2_VALBRUT  AS TOTAL_NF"
		_sQuery += "      , F2_VALIPI   AS IPI_NF"
		_sQuery += "      , F2_ICMSRET  AS ST_NF"
		_sQuery += " 	  , (SELECT ROUND(SUM(D2_TOTAL),2)"
		_sQuery += "           FROM SD2010 AS SD2"
		_sQuery += "       			INNER JOIN SF4010 AS SF4"
		_sQuery += "						ON (SF4.D_E_L_E_T_ = ''"
		_sQuery += "							AND SF4.F4_CODIGO   = SD2.D2_TES"
		_sQuery += "							AND SF4.F4_MARGEM   = '3')"
		_sQuery += "   		  WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL"
		_sQuery += "     		AND SD2.D2_DOC     = SF2.F2_DOC"
		_sQuery += "     		AND SD2.D2_SERIE   = SF2.F2_SERIE"
		_sQuery += "     		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE"
		_sQuery += "     		AND SD2.D2_LOJA    = SF2.F2_LOJA"
		_sQuery += "     		AND SD2.D2_EMISSAO = SF2.F2_EMISSAO"
		_sQuery += "  		 GROUP BY SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE) AS VLR_BONIFIC"
		_sQuery += "      , F2_FRETE AS FRETE_NF"
		_sQuery += " 	  , (SELECT ROUND(SUM(D2_TOTAL),2)"
		_sQuery += "          FROM SD2010 AS SD2"
		_sQuery += "   		  WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL"
		_sQuery += "     		AND SD2.D2_DOC     = SF2.F2_DOC"
		_sQuery += "     		AND SD2.D2_SERIE   = SF2.F2_SERIE"
		_sQuery += "     		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE"
		_sQuery += "     		AND SD2.D2_LOJA    = SF2.F2_LOJA"
		_sQuery += "     		AND SD2.D2_EMISSAO = SF2.F2_EMISSAO) AS TOTBASCOM"
		_sQuery += "      , SF2.F2_SEGURO AS SEGURO"
		_sQuery += "      , SF2.F2_DESPESA AS DESPESA"
		_sQuery += "   FROM " +  RetSQLName ("SF2") + " AS SF2 "
		_sQuery += "  WHERE SF2.D_E_L_E_T_  = ''" 
		_sQuery += "    AND SF2.F2_FILIAL   =  '" + se3 -> e3_filial  + "'"
		_sQuery += "    AND SF2.F2_DOC      =  '" + se3 -> e3_num     + "'"
		_sQuery += "    AND SF2.F2_SERIE    =  '" + se3 -> e3_prefixo + "'"
		_sQuery += "    AND SF2.F2_CLIENTE  =  '" + se3 -> e3_codcli  + "'"
		_sQuery += "    AND SF2.F2_LOJA     =  '" + se3 -> e3_loja    + "'"

		_aNota := U_Qry2Array(_sQuery)
		
		If len(_aNota) > 0
			_brutoNota:= _aNota[1,1]
			_ipiNota  := _aNota[1,2]
			_stNota	  := _aNota[1,3]
			_vlBonif  := _aNota[1,4]
			_vlFrete  := _aNota[1,5]
			_vlrBC	  := _aNota[1,6]
			_vlrSeg	  := _aNota[1,7]
			_vlrDesp  := _aNota[1,8]

			If _sCondTipo == '9' // Escolhe o percentual de cada parcela
				Do Case 
					Case alltrim(_parcela) == '' 
						_vlrIpi := (_ipiNota * _sParc1) / 100
						_vlrST  := (_stNota  * _sParc1) / 100
					Case alltrim(_parcela) == 'A'
						_vlrIpi := (_ipiNota * _sParc1) / 100
						_vlrST  := (_stNota  * _sParc1) / 100 
					Case alltrim(_parcela) == 'B' 
						_vlrIpi := (_ipiNota * _sParc2) / 100
						_vlrST  := (_stNota  * _sParc2) / 100 
					Case alltrim(_parcela) == 'C' 
						_vlrIpi := (_ipiNota * _sParc3) / 100
						_vlrST  := (_stNota  * _sParc3) / 100 
					Case alltrim(_parcela) == 'D' 
						_vlrIpi := (_ipiNota * _sParc4) / 100
						_vlrST  := (_stNota  * _sParc4) / 100 
					Case alltrim(_parcela) == 'E' 
						_vlrIpi := (_ipiNota * _sParc5) / 100
						_vlrST  := (_stNota  * _sParc5) / 100 
					Case alltrim(_parcela) == 'F' 
						_vlrIpi := (_ipiNota * _sParc6) / 100
						_vlrST  := (_stNota  * _sParc6) / 100 
					Case alltrim(_parcela) == 'G' 
						_vlrIpi := (_ipiNota * _sParc7) / 100
						_vlrST  := (_stNota  * _sParc7) / 100 
					Case alltrim(_parcela) == 'H' 
						_vlrIpi := (_ipiNota * _sParc8) / 100
						_vlrST  := (_stNota  * _sParc8) / 100 
					Case alltrim(_parcela) == 'I' 
						_vlrIpi := (_ipiNota * _sParc9) / 100
						_vlrST  := (_stNota  * _sParc9) / 100 
					Case alltrim(_parcela) == 'J' 
						_vlrIpi := (_ipiNota * _sParcA) / 100
						_vlrST  := (_stNota  * _sParcA) / 100 
					Case alltrim(_parcela) == 'K'
						_vlrIpi := (_ipiNota * _sParcB) / 100
						_vlrST  := (_stNota  * _sParcB) / 100 
					Case alltrim(_parcela) == 'L'  
						_vlrIpi := (_ipiNota * _sParcC) / 100
						_vlrST  := (_stNota  * _sParcC) / 100 

				EndCase

			Else
				If _sCondIPI == 'N' // IPI distribuídos nas "N" parcelas
					If alltrim(se3->e3_parcela) == '' .or. alltrim(se3->e3_parcela) == 'A' // se for primeira parcela, verificar se tem mais baixas nele
						// verificar se existe mais que um registro de comissão. se sim, so retira IPI e ST da primeira.
						_nQtdCom := BuscaQtdComissao(se3->e3_filial, se3->e3_num, se3->e3_prefixo, se3->e3_parcela, se3->e3_codcli, se3->e3_loja)

						If _nQtdCom == 0 
							_vlrIpi := _ipiNota/_qtdParc
							_vlrST  := _stNota/_qtdParc
						Else
							_vlrIpi := 0
							_vlrST  := 0
						EndIf
					Else
						_vlrIpi := _ipiNota/_qtdParc
						_vlrST  := _stNota/_qtdParc
					EndIf

				Else 				// IPI cobrado na primeira parcela
					If alltrim(se3->e3_parcela) == '' .or. alltrim(se3->e3_parcela) == 'A' // se for a primeira parcela, desconta IPI e ST
						// verificar se existe mais que um registro de comissão. se sim, so retira IPI e ST da primeira.
						_nQtdCom := BuscaQtdComissao(se3->e3_filial, se3->e3_num, se3->e3_prefixo, se3->e3_parcela, se3->e3_codcli, se3->e3_loja)

						If _nQtdCom == 0
							_vlrIpi := _ipiNota
							_vlrST  := _stNota
						Else
							_vlrIpi := 0
							_vlrST  := 0
						EndIf
					Else
						_vlrIpi := 0
						_vlrST  := 0
					EndIf
				EndIf
			EndIf
			
			_vlrBasePrev := _vlrBC
		else
			_vlrIpi := 0
			_vlrST  := 0
			_ipiNota:= 0
			_stNota := 0
		endif
		//
		// **********************************************************************************************
		// verifica se o mesmo titulo possui dois pagamentos em meses diferentes
		_sQuery := ""
		_sQuery += " SELECT 
		_sQuery += " 	COUNT(*)"
		_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_sQuery += " AND E5_FILIAL  = '" + se1->e1_filial  +"'"
		_sQuery += " AND E5_NUMERO  = '" + se1->e1_num     + "'"
		_sQuery += " AND E5_PREFIXO = '" + se1->e1_prefixo + "'"
		_sQuery += " AND E5_PARCELA = '" + se1->e1_parcela + "'"
		_sQuery += " AND E5_CLIFOR 	= '" + se1->e1_cliente + "'"
		_sQuery += " AND E5_LOJA   	= '" + se1->e1_loja    + "'"
		_sQuery += " AND E5_RECPAG 	= 'R'"
		_sQuery += " AND E5_SITUACA!= 'C'"
		_sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
		_sQuery += " AND  E5_DATA < '" + w_dtini + "'"
		_aPgtos := U_Qry2Array(_sQuery)

		If Len(_aPgtos) > 0
			If _aPgtos[1,1] > 0 // se existir algum registro de movimento nos meses anteriores
				_vlrIpi := 0
				_vlrST  := 0
			EndIf
		EndIf
		//
		// **********************************************************************************************
		// Se for compensação, nao desconta IPI e ST
		_sQuery := ""
		_sQuery += " SELECT 
		_sQuery += " 	COUNT(*)"
		_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_sQuery += " AND E5_FILIAL  = '" + se1->e1_filial  +"'"
		_sQuery += " AND E5_NUMERO  = '" + se1->e1_num     + "'"
		_sQuery += " AND E5_PREFIXO = '" + se1->e1_prefixo + "'"
		_sQuery += " AND E5_PARCELA = '" + se1->e1_parcela + "'"
		_sQuery += " AND E5_CLIFOR 	= '" + se1->e1_cliente + "'"
		_sQuery += " AND E5_LOJA   	= '" + se1->e1_loja    + "'"
		_sQuery += " AND E5_RECPAG 	= 'R'"
		_sQuery += " AND E5_SITUACA!= 'C'"
		_sQuery += " AND E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '%NCC%'"
		_aNCC := U_Qry2Array(_sQuery)

		If Len(_aNCC) > 0
			_vlrIpi := 0
			_vlrST  := 0
		EndIf
		//
		// **********************************************************************************************
		// Se for compensação, RA usa base prevista
		_sQuery := ""
		_sQuery += " SELECT 
		_sQuery += " 	COUNT(*) , SUM(SE5.E5_VALOR)"
		_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_sQuery += " AND E5_FILIAL  = '" + se1->e1_filial  +"'"
		_sQuery += " AND E5_NUMERO  = '" + se1->e1_num     + "'"
		_sQuery += " AND E5_PREFIXO = '" + se1->e1_prefixo + "'"
		_sQuery += " AND E5_PARCELA = '" + se1->e1_parcela + "'"
		_sQuery += " AND E5_CLIFOR 	= '" + se1->e1_cliente + "'"
		_sQuery += " AND E5_LOJA   	= '" + se1->e1_loja    + "'"
		_sQuery += " AND E5_RECPAG 	= 'R'"
		_sQuery += " AND E5_SITUACA!= 'C'"
		_sQuery += " AND E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '%RA%'"
		_aRA := U_Qry2Array(_sQuery)

		For _x := 1 to Len(_aRA)
			If _aRA[_x,1] > 0
				_vlrRec := _aRA[_x,2]
			EndIf
		Next

		//
		// **********************************************************************************************
		// calculo da base de comissao liberada
		
		//_vlrComBaseLib := (_vlrRec - _vlrIpi - _vlrST)
		_vlrComBaseLib := (_vlrRec - _vlrIpi - _vlrST - _vlFrete - _vlrSeg - _vlrDesp -_vlrJuros)

		_vlrComis      := _vlrComBaseLib * _npercSE3
		
		_nNovaBase := ROUND(_vlrComBaseLib,2)
		_nNovaComi := ROUND(_vlrComis/100,2)		
			
		// atualiza base de comissao no titulo
		Reclock("SE1", .F.)
			SE1->E1_BASCOM1 := _vlrBasePrev  
		MsUnLock()

		// Grava valores calculados nos campos padrao do sistema
		se3 -> e3_base  := _nNovaBase
		se3 -> e3_comis := _nNovaComi
		se3 -> e3_porc  := _npercSE3
	EndIf

	If _lContinua .and. IsInCallStack ("LOJA701")
		U_PerfMon ('F', 'MSE3440_em_LOJA701')
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	
Return		
//
// ---------------------------------------------------------------------------------------
// Busca		
Static Function BuscaQtdComissao(_sFilial, _sNum, _sPrefixo, _sParcela, _sCliente, _sLoja)
	Local _nQtdCom := 0
	Local _aQtdCom := {}
	Local _x       := 0

	_sQuery := ""
	_sQuery += " SELECT
	_sQuery += " 	COUNT(E3_SEQ) AS QTD
	_sQuery += " FROM SE3010
	_sQuery += " WHERE D_E_L_E_T_ = ''"
	_sQuery += " AND E3_FILIAL  = '" + _sFilial  + "'"
	_sQuery += " AND E3_NUM     = '" + _sNum     + "'"
	_sQuery += " AND E3_SERIE   = '" + _sPrefixo + "'"
	_sQuery += " AND E3_PARCELA = '" + _sParcela + "'"
	_sQuery += " AND E3_CODCLI  = '" + _sCliente + "'"
	_sQuery += " AND E3_LOJA    = '" + _sLoja    + "'"
	_aQtdCom := U_Qry2Array(_sQuery)

	For _x:= 1 to Len(_aQtdCom)
		_nQtdCom := _aQtdCom[_x, 1]
	Next

Return _nQtdCom
