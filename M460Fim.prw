// Programa.: M460Fim
// Autor....: Robert Koch
// Data.....: 21/12/2012
// Descricao: P.E. apos a gravacao da NF de saida e fora da transacao.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos a gravacao da NF de saida e fora da transacao
// #PalavasChave      #gravacao_NF #NF_de_saida 
// #TabelasPrincipais #SF2 #SC5 
// #Modulos           #todos
//
// Historico de alteracoes:
// 29/04/2014 - Robert  - Chama o reprocessamento de livro fiscal por causa da ST.
// 14/04/2015 - Catia   - erro ao executar reprocessamento fiscal
// 09/06/2015 - Catia   - rotinas de baixa de saldos de verbas
// 09/06/2015 - Catia   - rotina de verificação de dispensers
// 10/06/2015 - Catia   - acertada a gravação do ZA5 nao estava gravando o usuario e a data da 
//                       utilizacao da verba
// 11/06/2015 - Catia   - alterada rotina de geracao de email referente aos dispensers
// 15/06/2015 - Catia   - alterado status de utilizacao - testando pelo saldo da verba
// 12/09/2015 - Robert  - Removidos trechos (jah desabilitados) de tratamento de ST, pois agora 
//                        estamos calculando pelo padrao.
// 16/09/2015 - Robert  - Desabilitado reprocessamento automatico.
// 23/09/2015 - Robert  - Habilitado novamente o reprocessamento automatico (fora desabilitado dia 16, 
//                        mas nao foi compilado naquela ocasiao).
// 07/11/2015 - Catia   - Ajustes da rotina de geracao de emails de referente aos dispenser
// 29/12/2015 - Robert  - Baca para gravar a transportadora na nota, ateh que a versao padrao seja corrigida.
// 11/01/2015 - Catia   - na rotina de dispenser, alterada a Query pois nao estava mandando o email.
// 14/06/2016 - Robert  - Desabilitada chamada do reprocessamento de NF.
// 07/12/2016 - Robert  - Chama exportacao de dados para Mercanet.
// 11/07/2017 - Robert  - Removida funcao _RodaBatch() - tratamentos para deposito fechado 
//                        (filial 04) por ha tempos foi fechada.
// 18/11/2019 - Robert  - Desabilitado tratamento verbas via bonificacao. Nao usamos mais. GLPI 7001
// 24/02/2020 - Robert  - Alimenta lista de notas geradas, para posterior envio para a SEFAZ.
// 17/05/2021 - Claudia - Gravação da data prevista. GLPI: 9885
// 14/07/2021 - Claudia - Incluida a gravação produto x fornecedor de transferencias 
//                        entre filiais. GLPI: 10213
// 20/10/2021 - Robert  - Passa a gravar a serie na array _aNComSono (GLPI 11112).
// 02/12/2021 - Claudia - Incluida rotina para gravação do Rapel que será liberada por 
//                        parametro VA_RAPEL quando processo concluido. GLPI: 8916
// 23/05/2022 - Claudia - Ajuste da rotina de gravação de rapel. GLPI: 8916
// 11/07/2022 - Claudia - Incluida gravação de nota e serie na amarração produto x fornecedor de transferencias 
// 22/08/2022 - Claudia - Incluida validação para nao gravar registro no conta rapel 
//                        se não houver valor. GLPI: 8916
// 07/10/2022 - Claudia - Atualização de rapel apenas para serie 10. GLPI: 8916
// 28/10/2022 - Robert  - Cod. evento trocado de SA5010 para SA5001 ao gravar amarracao produto x fornecedor.
// 23/11/2022 - Claudia - Incluido evento ao gravar amarracao produto x fornecedor. GLPI: 12821
// 09/02/2023 - Claudia - Incluido log de gravação rapel.
// 26/04/2023 - Claudia - Ajustado a gravação de log de erro rapel. GLPI: 13741
// 11/07/2023 - Claudia - Incluida a gravação do produto fornecedor com dados do produto protheus. GLPI: 13859
// 25/07/2023 - Claudia - Integração de notas fiscais Protheus com CRM Simples. GLPI: 13963
//
// --------------------------------------------------------------------------------------------------------------
user function M460Fim ()
	local _aAreaAnt := U_ML_SRArea ()

	// Parece que estah chegando aqui sem nenhum alias().
	dbselectarea ("SF2")

	// Baca para gravar a transportadora na nota, pois na atualizacao fiscal para 01/01/2016
	// comecou a deixar o F2_TRANSP em branco quando fatura por carga.
	if empty (sf2 -> f2_transp)
		RecLock("SF2",.F.)
		sf2 -> f2_transp = sc5 -> c5_transp
		MsUnlock()	
	endif

	// Busca data de entrega para salvar na nota
	_dDtPrevista := _BuscaEntrega(sf2->f2_filial, sc5->c5_num, sf2->f2_cliente, sf2->f2_loja, sc5-> c5_vaest, sf2-> f2_emissao)
	if ! empty(_dDtPrevista)
		RecLock("SF2",.F.)
		sf2 -> f2_vadpent = _dDtPrevista
		MsUnlock()	
	endif

	_VerDispenser()
	
	// Integracao com Mercanet
	_VerMerc()

	// Alimenta lista de notas geradas, para posterior envio para a SEFAZ.
	// A variavel jah deve estar previamente declarada.
	if type ("_aNComSono") == "A"
	//	aadd (_aNComSono, {sf2 -> f2_doc, .F.})
		aadd (_aNComSono, {sf2 -> f2_doc, .F., sf2 -> f2_serie})
	endif

	// grava produto x fornecedor para transferencias
	u_log2 ('info', 'Produto X fornecedor - transferencia entre filial')
	_ProdXForneceFil(sf2->f2_filial, sf2->f2_doc, sf2->f2_serie, sf2->f2_cliente, sf2->f2_loja)

	// Grava rapel
	If GetMV('VA_RAPEL')
		_AtuZC0()
	EndIf

	_GravaCRM()

	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Dispenser
Static Function _VerDispenser()
	local _oSQL := NIL

	_aCols = {}
	aadd (_aCols, {'Documento'         ,    'left'  ,  ''})
	aadd (_aCols, {'Serie'             ,    'left'  ,  ''})
	aadd (_aCols, {'Dt.Emissao'        ,    'left'  ,  ''})
	aadd (_aCols, {'Cliente/Fornecedor',    'left'  ,  ''})
	aadd (_aCols, {'Produto'           ,    'left'  ,  ''})
	aadd (_aCols, {'Descricao'         ,    'left'  ,  ''})
	aadd (_aCols, {'Quantidade'        ,    'right' ,  '@E 999.99'})
	   
	// Avisa comercial - chegada de dispensers
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SD2.D2_DOC, SD2.D2_SERIE"
	_oSQL:_sQuery += "      , dbo.VA_DTOC(SD2.D2_EMISSAO)"
    _oSQL:_sQuery += "      , CASE SD2.D2_TIPO WHEN 'N' THEN SA1.A1_NOME ELSE SA2.A2_NOME END AS CLI_FOR"
	_oSQL:_sQuery += "      , SD2.D2_COD, SB1.B1_DESC, SD2.D2_QUANT"
	_oSQL:_sQuery += "   FROM " + RetSQLName ("SD2") + " SD2"
    _oSQL:_sQuery += " 		INNER JOIN SB1010 AS SB1"
	_oSQL:_sQuery += " 			ON (SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 				AND SB1.B1_COD    = SD2.D2_COD"
	_oSQL:_sQuery += " 				AND SB1.B1_CODLIN = '90')"
	_oSQL:_sQuery += "		LEFT JOIN SA2010 AS SA2"
	_oSQL:_sQuery += "			ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "				AND SA2.A2_COD  = SD2.D2_CLIENTE"
	_oSQL:_sQuery += "				AND SA2.A2_LOJA = SD2.D2_LOJA)"
	_oSQL:_sQuery += "		LEFT JOIN SA1010 AS SA1"
	_oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_oSQL:_sQuery += "				AND SA1.A1_LOJA = SD2.D2_LOJA)"
    _oSQL:_sQuery += "  WHERE SD2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += "    AND SD2.D2_FILIAL   = '" + xfilial ("SD2")   + "'"
	_oSQL:_sQuery += "    AND SD2.D2_DOC      = '" + sf2 -> f2_doc     + "'"
	_oSQL:_sQuery += "    AND SD2.D2_SERIE    = '" + sf2 -> f2_serie   + "'"
	
	if len (_oSQL:Qry2Array (.T., .F.)) > 0	
		_sMsg = _oSQL:Qry2HTM ("DISPENSERS MOVIMENTADOS - Saida: " + dtoc(sf2 -> f2_emissao), _aCols, "", .F.)
		U_ZZUNU ({'044'}, "DISPENSERS MOVIMENTADOS - Saida: " + dtoc(sf2 -> f2_emissao), _sMsg, .F. ) // Responsavel pelos dispenser
	endif
Return
//
// --------------------------------------------------------------------------
// Integracao com Mercanet
static function _VerMerc ()
	local _oSQL := NIL
	local _aPed := {}
	local _nPed := 0
	local _aTit := {}
	local _nTit := 0

	// Nao envia a nota agora por que ainda nao tem a chave gravada.  --> U_AtuMerc ('SF2', sf2 -> (recno ()))
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT D2_PEDIDO"
	_oSQL:_sQuery += "   FROM " + RetSQLName ("SD2") + " SD2"
    _oSQL:_sQuery += "  WHERE SD2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += "    AND SD2.D2_FILIAL   = '" + xfilial ("SD2")   + "'"
	_oSQL:_sQuery += "    AND SD2.D2_DOC      = '" + sf2 -> f2_doc     + "'"
	_oSQL:_sQuery += "    AND SD2.D2_SERIE    = '" + sf2 -> f2_serie   + "'"
	_aPed := aclone (_oSQL:Qry2Array (.F., .F.))

	sc5 -> (dbsetorder (1))  // C5_FILIAL+C5_NUM
	for _nPed = 1 to len (_aPed)
		if sc5 -> (dbseek (xfilial ("SC5") + _aPed [_nPed, 1], .F.))
			U_AtuMerc ('SC5', sc5 -> (recno ()))
		endif
	next

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT R_E_C_N_O_"
	_oSQL:_sQuery += "   from " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += "  where D_E_L_E_T_ != '*'"
	_oSQL:_sQuery += "    and E1_FILIAL  =  '" + xfilial ("SE1")   + "'"
	_oSQL:_sQuery += "    and E1_NUM     =  '" + sf2 -> f2_doc     + "'"
	_oSQL:_sQuery += "    and E1_PREFIXO =  '" + sf2 -> f2_serie   + "'"
	_oSQL:_sQuery += "    and E1_CLIENTE =  '" + sf2 -> f2_cliente + "'"
	_oSQL:_sQuery += "    and E1_LOJA    =  '" + sf2 -> f2_loja    + "'"
	_aTit := aclone (_oSQL:Qry2Array (.F., .F.))
	for _nTit = 1 to len (_aTit)
		U_AtuMerc ('SE1', _aTit [_nTit, 1])
	next
return
//
// --------------------------------------------------------------------------
// Busca a data de entrega
Static Function _BuscaEntrega(_sFilial, _sNumero, _sCliente, _sLoja, _sEst, _dtEmissao)
	local _sCEP  := ""
	local _aGUL  := {}
	local _aGU9  := {}
	local _x     := 0
	local _nDias := 0

	_sCEP := Posicione("SA1",1, xFilial("SA1") + _sCliente, "A1_CEP")

	// Busca quantidade de dias para somar na data de entrega
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		GUL_VADPEN "
	_oSQL:_sQuery += " FROM " + RetSQLName ("GUL") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND GUL_FILIAL   = '" + _sFilial + "' "
	_oSQL:_sQuery += " AND '" + _sCEP + "' BETWEEN GUL_CEPINI AND GUL_CEPFIM "
	_aGUL := aclone (_oSQL:Qry2Array ())

	// Se existir na tabela GUL -> 1º opção
	If len(_aGUL) > 0
		For _x := 1 to Len(_aGUL)
			_nDias := _aGUL[_x, 1]
		Next

		If _nDias == 0
			// Se não existir na GUL, busca da GU9 -> 2º opção
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		GU9_VADPEN  "
			_oSQL:_sQuery += " FROM " + RetSQLName ("GU9") 
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " AND GU9_FILIAL   = '" + _sFilial + "'"
			_oSQL:_sQuery += " AND GU9_CDUF     = '" + _sEst    + "'"
			_oSQL:_sQuery += " AND GU9_SIT      = '1'"
			_aGU9 := aclone (_oSQL:Qry2Array ())

			For _x:=1 to Len(_aGU9)
				_nDias := _aGU9[_x, 1]
			Next
		EndIf
	EndIf

	_dDtPrevista := DaySum(_dtEmissao,_nDias)

Return _dDtPrevista
//
// --------------------------------------------------------------------------
// Verifica se é transferencia entre filiais e 
// busca Código de fornecedor, do emissor da NF de saida
Static Function _ProdXForneceFil(_sFilial, _sDoc, _sSerie, _sCliente, _sLoja)
	Local _sCGC := POSICIONE("SA1",1,XFILIAL("SA1") + _sCliente + _sLoja,"A1_CGC")  
	Local _x    := 0

	u_log2 ('info', 'CNPJ ' + _sCGC)
	If '88612486' $ _sCGC
		// Busca o codigo da filial de envio, para buscar codigo de fornecedor e gravar
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		M0_CGC "
		_oSQL:_sQuery += " FROM VA_SM0 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND M0_CODFIL    = '" + _sFilial + "'"
		_aCGCM0 := aclone (_oSQL:Qry2Array ())

		For _x:=1 to Len(_aCGCM0)
			_sCGCFornec := _aCGCM0[_x, 1]
		Next
		u_log2 ('info', 'CNPJ Fornecedor ' + _sCGCFornec)
		// Busca código de fornecedor do emissor da NF saida, para dar entrada no importador XML
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		A2_COD "
		_oSQL:_sQuery += "     ,A2_LOJA "
		_oSQL:_sQuery += "     ,A2_NOME "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SA2") 
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND A2_CGC = '" + _sCGCFornec + "' "
		_aCGCA2 := aclone (_oSQL:Qry2Array ())

		For _x:=1 to Len(_aCGCA2)
			_sCodForn := _aCGCA2[_x, 1]
			_sLojForn := _aCGCA2[_x, 2]
			_sNomForn := _aCGCA2[_x, 3]
		Next
		_GravaProdXFornc(_sFilial,_sDoc,_sSerie,_sCliente,_sLoja,_sCodForn,_sLojForn,_sNomForn)
	EndIf
Return
//
// --------------------------------------------------------------------------
// Grava Fornecedor X produto
Static Function _GravaProdXFornc(_sFilial,_sDoc,_sSerie,_sCliente,_sLoja,_sCodForn,_sLojForn,_sNomForn)
	Local _aProd := {}
	Local _x     := 0

	u_log2 ('info', 'Gravação Produto X Fornecedor ' + _sFilial+'-'+_sDoc+'-'+_sSerie+'-'+_sCliente+'-'+_sLoja+'-'+_sCodForn+'-'+_sLojForn+'-'+_sNomForn)
	// Busca produto para gravação
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		D2_COD "
	_oSQL:_sQuery += " FROM SD2010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND D2_FILIAL    = '" + _sFilial  + "' "
	_oSQL:_sQuery += " AND D2_DOC       = '" + _sDoc     + "' "
	_oSQL:_sQuery += " AND D2_SERIE     = '" + _sSerie   + "' "
	_oSQL:_sQuery += " AND D2_CLIENTE   = '" + _sCliente + "' "
	_oSQL:_sQuery += " AND D2_LOJA      = '" + _sLoja    + "' "
	_aProd := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aProd)
		_sProduto := _aProd[_x, 1]
		_sProdDesc := POSICIONE("SB1",1,XFILIAL("SB1") + _sProduto,"B1_DESC")  

		dbSelectArea("SA5")
		dbSetOrder(1) // A5_FILIAL+A5_FORNECE+A5_LOJA+A5_PRODUTO
		dbGoTop()

		If !dbSeek(xFilial("SA5") + _sCodForn + _sLojForn + _sProduto)  // registro novo
			Reclock("SA5",.T.)
				SA5->A5_FILIAL  := ''
				SA5->A5_FORNECE := _sCodForn
				SA5->A5_LOJA    := _sLojForn
				SA5->A5_NOMEFOR := _sNomForn
				SA5->A5_PRODUTO := _sProduto
				SA5->A5_NOMPROD := _sProdDesc
				SA5->A5_CODPRF  := _sProduto
			SA5->(MsUnlock())

			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'SA5'
			_oEvento:Texto     = " Inclusão de produto X fornecedor" + chr (13) + chr (10) + ;
								 " Produto: " + alltrim(_sProduto) + chr (13) + chr (10) + ;
								 " Fornecedor: "+ alltrim(_sCodForn) + "-" + alltrim(_sLojForn) + " "
			_oEvento:CodEven   = 'SA5002'  //"SA5010"
			_oEvento:Produto   = alltrim(_sProduto)
			_oEvento:NFSaida   = _sDoc
			_oEvento:SerieSaid = _sSerie
			_oEvento:Grava()

			u_log2 ('info', 'Gravação: Produto: ' + alltrim(_sProduto) + 'Fornecedor: '+ alltrim(_sCodForn) + "-" + alltrim(_sLojForn) )
		Else
			u_log2 ('info', 'NÃO gravou: Produto: ' + alltrim(_sProduto) + 'Fornecedor: '+ alltrim(_sCodForn) + "-" + alltrim(_sLojForn) )
			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'SA5'
			_oEvento:Texto     = " Produto já cadastrado em produto X fornecedor" + chr (13) + chr (10) + ;
								 " Produto: " + alltrim(_sProduto) + chr (13) + chr (10) + ;
								 " Fornecedor: "+ alltrim(_sCodForn) + "-" + alltrim(_sLojForn) + " "
			_oEvento:CodEven   = 'SA5003'  //"SA5010"
			_oEvento:Produto   = alltrim(_sProduto)
			_oEvento:NFSaida   = _sDoc
			_oEvento:SerieSaid = _sSerie
			_oEvento:Grava()	 
		EndIf
	Next
Return
//
// --------------------------------------------------------------------------
// Grava Rapel
Static Function _AtuZC0()
	Local _sTpRapel := ""
	Local _sRede    := ""
	
	_oCtaRapel := ClsCtaRap():New ()
	_sRede     := _oCtaRapel:RetCodRede(sf2->f2_cliente, sf2->f2_loja)
	_sTpRapel  := _oCtaRapel:TipoRapel(_sRede, sf2->f2_loja)
	
	If alltrim(_sTpRapel) <> '0' .and. sf2->f2_varapel > 0 .and. alltrim(sf2->f2_serie) == '10' // Se o cliente tem configuração de rapel
		_oCtaRapel:Filial  	 = sf2->f2_filial
		_oCtaRapel:Rede      = _sRede	
		_oCtaRapel:LojaRed   = sf2->f2_loja
		_oCtaRapel:Cliente 	 = sf2->f2_cliente
		_oCtaRapel:LojaCli	 = sf2->f2_loja
		_oCtaRapel:TM      	 = '02' 	
		_oCtaRapel:Data    	 = ddatabase//date()
		_oCtaRapel:Hora    	 = time()
		_oCtaRapel:Usuario 	 = cusername 
		_oCtaRapel:Histor  	 = 'Inclusão de rapel por emissão de NF' 
		_oCtaRapel:Documento = sf2->f2_doc
		_oCtaRapel:Serie 	 = sf2->f2_serie
		_oCtaRapel:Parcela	 = ''
		_oCtaRapel:Rapel	 = sf2->f2_varapel
		_oCtaRapel:Origem	 = 'M460FIM'
		_oCtaRapel:NfEmissao = sf2 -> f2_emissao

		If _oCtaRapel:Grava (.F.)
			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'ZC0'
			_oEvento:Texto     = "Inclusão de rapel por emissão de NF"
			_oEvento:CodEven   = 'ZC0001'
			_oEvento:Cliente   = sf2->f2_cliente
			_oEvento:LojaCli   = sf2->f2_loja
			_oEvento:NFSaida   = sf2->f2_doc
			_oEvento:SerieSaid = sf2->f2_serie
			_oEvento:Grava()
		else
			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'ZC0'
			_oEvento:Texto     = "ERRO na inclusão de rapel emissão NF"
			_oEvento:CodEven   = 'ZC0002'
			_oEvento:Cliente   = sf2->f2_cliente
			_oEvento:LojaCli   = sf2->f2_loja
			_oEvento:NFSaida   = sf2->f2_doc
			_oEvento:SerieSaid = sf2->f2_serie
			_oEvento:Grava()
		EndIf
	else
		If sf2->f2_varapel > 0
			_oEvento := ClsEvent():New ()
			_oEvento:Alias     = 'ZC0'
			_oEvento:Texto     = "ERRO inclusão rapel emissão NF. A1_VABARAP: " + _sTpRapel
			_oEvento:CodEven   = 'ZC0002'
			_oEvento:Cliente   = sf2->f2_cliente
			_oEvento:LojaCli   = sf2->f2_loja
			_oEvento:NFSaida   = sf2->f2_doc
			_oEvento:SerieSaid = sf2->f2_serie
			_oEvento:Grava()
		EndIf
	EndIf
Return 
//
// --------------------------------------------------------------------------
// Grava CRM
Static Function _GravaCRM()
	Local _aCrmNF := {}
	Local _x      := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		 ZCA_CODRES "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZCA")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZCA_CODREP   = '" + sf2->f2_vend1  + "' "
	_aResp := aclone (_oSQL:Qry2Array ())

	If Len(_aResp) > 0//  se existir responsavel, grava a NF no CRM
			_nResp      := _aResp[1,1]
			_sNF        := "NF " + sf2->f2_doc + " " + sf2->f2_serie
			_sDtEmissao := _DtToJson(sf2->f2_emissao)
			_sDtFat     := _DtToJson(date())

			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		 D2_COD "
			_oSQL:_sQuery += "    	,SB1.B1_DESC "
			_oSQL:_sQuery += "    	,SD2.D2_PRCVEN "
			_oSQL:_sQuery += "    	,SD2.D2_QUANT "
			_oSQL:_sQuery += "    	,D2_UM "
			_oSQL:_sQuery += "    	,D2_TOTAL "
			_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2 "
			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
			_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " 		AND SB1.B1_COD = SD2.D2_COD "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND D2_FILIAL    = '" + sf2->f2_filial  + "' "
			_oSQL:_sQuery += " AND D2_DOC       = '" + sf2->f2_doc     + "' "
			_oSQL:_sQuery += " AND D2_SERIE     = '" + sf2->f2_serie   + "' "
			_oSQL:_sQuery += " AND D2_CLIENTE   = '" + sf2->f2_cliente + "' "
			_oSQL:_sQuery += " AND D2_LOJA      = '" + sf2->f2_loja    + "' "
			_aProd := aclone (_oSQL:Qry2Array ())

			For _x := 1 to len(_aProd)
				aadd(_aCrmNF,{	sf2->f2_cliente 	,; // idExterno
								_sNF				,; // nome
								_sNF + " faturada"	,; // descricao
								_nResp 				,; // usuario
								_sDtFat				,; // concluidaEm
								sf2->f2_valmerc		,; // valor
								_sDtEmissao			,; // criadaEm
								_aProd[_x, 1]		,; // produto - idExterno
								_aProd[_x, 2]		,; // produto - descricao
								_aProd[_x, 3]		,; // produto - valorUnitario
								_aProd[_x, 4]		,; // produto - quantidade
								_aProd[_x, 5]		,; // produto - unidade
								_aProd[_x, 6]		,; // produto - valorTotal
													}) 
			Next

			U_VA_CRM(_aCrmNF, 'N')
	EndIf
Return
//
// --------------------------------------------------------------------------
// Transforma data no formato JSON
Static Function _DtToJson(_dDt)
	_sDt   := dtos(_dDt)
	_sAno  := substr(_sDt,1,4)
	_sMes  := substr(_sDt,5,2)
	_sDia  := substr(_sDt,7,2)
	_sHora := time()
	
	_jDt := _sAno + "-" + _sMes + "-" + _sDia + "T" + _sHora + ".000Z"
	
Return _jDt
