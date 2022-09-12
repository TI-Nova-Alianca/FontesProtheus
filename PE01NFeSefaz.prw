// Programa:   PE01NfeSefaz
// Autor:      Robert Koch
// Data:       07/01/2016
// Descricao:  P.E. no final da montagem do XML de NF-e.
//             Permite alguns tratamentos no XML gerado.
// 
// Historico de alteracoes:
// 01/08/2016 - Robert - Protheus 12 chegava a este P.E. sem 'alias' definido.
// 14/08/2017 - Robert - Monta estrutura de tags para leitura de redespachos (integracao com software da E-Sales) e retorna na msg. do contribuinte.
// 06/08/2018 - Catia  - mensagens do AMPARA e de IPI DEVOLUCAO nao estava saindo - o ponto de entrada estava substituindo as mensagens e nao mantia as geradas pelo sistema padrao
// 20/09/2018 - André  - Removido informação duplicada nas mensagens da nota.
// 13/11/2018 - Catia  - Tratamento do aObsCont - Tag <obsCont xCampo=" "> e <xTexto> 
// 30/10/2019 - Robert - Tratamento para concatenar msg proveniente do NFESEFAZ.PRW em vez de apenas sobrepor.
// 16/01/2020 - Robert - Desabilitadas gravacoes de logs.
// 01/09/2022 - Robert - Melhorias ClsAviso.
//

// ------------------------------------------------------------------------------------------
user function PE01NfeSefaz ()
	local _aAreaAnt := U_ML_SRArea ()
	Local aProd     := PARAMIXB[1]
	Local cMensCli  := PARAMIXB[2]
	Local cMensFis  := PARAMIXB[3]
	Local aDest     := PARAMIXB[4] 
	Local aNota     := PARAMIXB[5]
	Local aInfoItem := PARAMIXB[6]
	Local aDupl     := PARAMIXB[7]
	Local aTransp   := PARAMIXB[8]
	Local aEntrega  := PARAMIXB[9]
	Local aRetirada := PARAMIXB[10]
	Local aVeiculo  := PARAMIXB[11]
	Local aReboque  := PARAMIXB[12]
	Local aNfVincRur:= PARAMIXB[13]
	Local aEspVol   := PARAMIXB[14]
	Local aNfVinc   := PARAMIXB[15]
	Local AdetPag   := PARAMIXB[16]
	Local aObsCont  := PARAMIXB[17]
	Local aRetorno  := {}

//	u_logIni ()
//	U_LOG ('_sNFEntSai:', _sNFEntSai)
	
	// Altera o conteudo das variaveis de observacoes, dados adicionais, dados pata E-Sales, etc.
	cMensCli = _MsgCtr (cMensCli)
	cMensFis = _MsgFis (cMensFis)
	aObsCont = _MsgObs (aObsCont)
	
	//O retorno deve ser exatamente nesta ordem e passando o conteúdo completo dos arrays
	//pois no rdmake nfesefaz é atribuido o retorno completo para as respectivas variáveis
	aadd(aRetorno,aProd) 
	aadd(aRetorno,cMensCli)
	aadd(aRetorno,cMensFis)
	aadd(aRetorno,aDest)
	aadd(aRetorno,aNota)
	aadd(aRetorno,aInfoItem)
	aadd(aRetorno,aDupl)
	aadd(aRetorno,aTransp)
	aadd(aRetorno,aEntrega)
	aadd(aRetorno,aRetirada)
	aadd(aRetorno,aVeiculo)
	aadd(aRetorno,aReboque)
	aadd(aRetorno,aNfVincRur)
	aadd(aRetorno,aEspVol)
	aadd(aRetorno,aNfVinc)
	aadd(aRetorno,AdetPag)
    aadd(aRetorno,aObsCont)

	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
RETURN aRetorno

// --------------------------------------------------------------------------
// Monta dados adicionais de interesse do contribuinte
static function _MsgCtr (cMensCli)
	local _sRet  := cMensCli
//	u_logIni ()
	if _sNFEntSai == '1'  // Saida
		dbselectarea ("SF2")
	//	_sRet = MSMM (sf2->f2_vacmemc,,,,3)
//		U_LOG ('msmm:', MSMM (sf2->f2_vacmemc,,,,3))
		if ! empty (sf2->f2_vacmemC)
			_sRet = _Concat (_sRet, MSMM (sf2->f2_vacmemC,,,,3))
		endif
		
	else
		dbselectarea ("SF1")
//		_sRet = MSMM (sf1->f1_vacmemc,,,,3)
		if ! empty (sf1->f1_vacmemC)
			_sRet = _Concat (_sRet, MSMM (sf1->f1_vacmemC,,,,3))
		endif

		// NF de importacao
		if _ntotPIS > 0 .OR. _ntotCOF > 0
			if _ntotPIS > 0
				_sRet += _sRet + ' ' +  "; PIS: " + mv_simb1 + alltrim (Transform(_ntotPIS,"@R 999.999.99"))  //alltrim(Str(_ntotPIS))
			endif
			if _ntotCOF > 0
				_sRet += _sRet + ' ' +  "; COFINS: " + mv_simb1  + alltrim (Transform(_ntotCOF,"@R 999.999.99"))  //Alltrim(Str(_ntotCOF))
			endif
			if _nCMoedImp > 0
//				_sRet += _sRet + ' ' + "; Cotacao " + _sDMoedImp + ": " + mv_simb1 + alltrim (Transform (_nCMoedImp,"@E 999,999.9999"))
				_sRet += _sRet + ' ' + "; Cotacao: " + mv_simb1 + alltrim (Transform (_nCMoedImp,"@E 999,999.9999"))
			endif
			if SF1->F1_II > 0
				_sRet += _sRet + ' ' + "; Imposto importacao: " + mv_simb1 + alltrim (Transform (SF1->F1_II,"@E 999,999,999.99"))
			endif
		endif
	endif
//	u_logFim ()
return _sRet


// --------------------------------------------------------------------------
// Monta dados adicionais de interesse do fisco
static function _MsgFis (cMensFis)
	local _sRet := cMensFis
//	u_logIni ()
	if _sNFEntSai == '1'  // Saida
		dbselectarea ("SF2")
//		_sRet = MSMM (sf2->f2_vacmemf,,,,3)
		if ! empty (sf2->f2_vacmemF)
			_sRet = _Concat (_sRet, MSMM (sf2->f2_vacmemF,,,,3))
		endif
	else
		dbselectarea ("SF1")
//		_sRet = MSMM (sf1->f1_vacmemf,,,,3)
		if ! empty (sf1->f1_vacmemF)
			_sRet = _Concat (_sRet, MSMM (sf1->f1_vacmemF,,,,3))
		endif
	endif
//	u_logFim ()
return _sRet

// --------------------------------------------------------------------------
// Monta dados para compor a tag <obsCont> (inicialmente para passar dados adiocionais para a E-Sales/entregou.com
static function _MsgObs (aObsCont)
	Local _sRet   := aObsCont
	local _oAviso := NIL
 	
 	if _sNFEntSai == '1'  // Saida
		if val(SF2->F2_REDESP) > 0
			sa4 -> (dbsetorder (1))
			if sa4 -> (msseek (xfilial('SA4') + SF2->F2_REDESP, .F.))
				// le os dados da transportadora de redespacho
/*
				_wnome := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_NOME")
				_wcnpj := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_CGC")
				_wend  := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_END")
				_wcep  := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_CEP")
				_wmuni := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_MUN")
				_west  := fBuscaCpo ('SA4', 1, xfilial('SA4') + SF2->F2_REDESP, "A4_EST")
				
				aAdd(_sRet,{ "nome_Cnpj"     ,; //xCampo
							_wnome + _wcnpj }) //xTexto
				aAdd(_sRet,{ "lgr_Cep"       ,; //xCampo
							_wend + _wcep   }) //xTexto
				aAdd(_sRet,{ "municipio_Uf"  ,; //xCampo
							_wmuni + _west  }) //xTexto
				aAdd(_sRet,{ "campos_Notfis" ,; //xCampo
							"Diversos 212NI"}) //xTexto	 -- #Nat.mercadoria:diversos # Tipo transp:1=carga fechada; 2 = carga fracionada # Meio transp: 1 = rodoviário; 2 = aéreo; 3 = marítimo; 4 = fluvial; 5 = ferroviário # Tipo carga: 1 = fria; 2 = seca; 3 = mista # Seguro já efetuado: s = sim; n = não # Ação docto: i = inclusão   e = exclusão/cancelamento      
*/
				aAdd(_sRet,{ "nome_Cnpj"     ,; //xCampo
							sa4 -> a4_nome + sa4 -> a4_cgc}) //xTexto
				aAdd(_sRet,{ "lgr_Cep"       ,; //xCampo
							sa4 -> a4_end + sa4 -> a4_cep   }) //xTexto
				aAdd(_sRet,{ "municipio_Uf"  ,; //xCampo
							sa4 -> a4_mun + sa4 -> a4_est  }) //xTexto
				aAdd(_sRet,{ "campos_Notfis" ,; //xCampo
							"Diversos 212NI"}) //xTexto	 -- #Nat.mercadoria:diversos # Tipo transp:1=carga fechada; 2 = carga fracionada # Meio transp: 1 = rodoviário; 2 = aéreo; 3 = marítimo; 4 = fluvial; 5 = ferroviário # Tipo carga: 1 = fria; 2 = seca; 3 = mista # Seguro já efetuado: s = sim; n = não # Ação docto: i = inclusão   e = exclusão/cancelamento      
			else
				_oAviso := ClsAviso ():New ()
				_oAviso:Tipo       = 'E'
				_oAviso:DestinAvis = 'grpTI'
				_oAviso:Texto      = "Transportadora '" + sf2 -> f2_redesp + "' nao localizada para gerar tag de redespacho'
				_oAviso:Origem     = procname (1)
				_oAviso:Grava ()
			endif
		endif
	endif
return _sRet



// --------------------------------------------------------------------------
static function _Concat (_sOrig, _sMemo)
	local _aMemo := {}
	local _nMemo := 0

//	u_log ('Msg original:', _sOrig)
//	u_log ('Conteudo lido do memo:', _sMemo)

	// Substitui quebras de linha por ';'
	_sMemo = strtran (_sMemo, chr (13) + chr (10), ';')
	
	// Transforma o conteudo do memo em array para tentar validar se jah constam na msg padrao.
	_aMemo := StrTokArr (cvaltochar (_sMemo), ';')
//	u_log (_aMemo)
	for _nMemo = 1 to len (_aMemo)
		//u_log ('Testando:', alltrim (_aMemo [_nMemo]))
		if ! alltrim (_aMemo [_nMemo]) $ _sOrig
		//	u_log ('Acrescentando: ', alltrim (_aMemo [_nMemo]))
			_sOrig += iif (empty (_sOrig), '', '; ') + alltrim (_aMemo [_nMemo])
		//else
		//	u_log ('Ja consta: ', alltrim (_aMemo [_nMemo]))
		endif
	next
//	u_log ('Retornando:', _sOrig)
return _sOrig
