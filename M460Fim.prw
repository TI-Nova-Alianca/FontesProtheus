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
//
// --------------------------------------------------------------------------------------------------
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
		aadd (_aNComSono, {sf2 -> f2_doc, .F.})
	endif

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
