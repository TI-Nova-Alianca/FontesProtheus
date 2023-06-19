// Programa:  VA_GNF3
// Autor:     Robert Koch
// Data:      21/08/2009
// Descricao: Gera registros tipo 'complemento de preco' no arquivo ZZ9 (previa das notas de compra de uva da safra)
//
// Historico de alteracoes:
// 26/10/2012 - Robert - Ajustes para safra 2012.
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
//                     - Ajustes para 2015.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 22/04/2017 - Robert - Tratamento para 2017
// 10/07/2017 - Robert - Novo complemento geral 2017
// 23/06/2020 - Robert - Implementacoes para safra 2020
// 06/07/2020 - Robert - Criados parametros de variedades a considerar e a desconsiderar.
// 22/04/2021 - Robert - Criado tratamento para safra 2020 (GLPI 9891).
//    05/2023 - Robert - Tratamentos para complemento 2023 (maio) - GLPI 13532.
// 16/06/2023 - Robert - Gravacao campo zz9_TpForn - GLPI 13699
//

// --------------------------------------------------------------------------
User Function VA_GNF3 (_lAuto)
	Local cCadastro := "Geracao NF de complemento de preco de compra de uva"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "VAGNF3"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	nOpca = 0
	if _lAuto != NIL .and. _lAuto
		nOpca = 1
	else
		AADD(aSays,"  Este programa tem como objetivo gerar complementos no arquivo de  ")
		AADD(aSays,"  previsao de notas de compra de uva, para posterior conferencia.   ")
		AADD(aSays,"  Recomenda-se executar este processo depois da geracao das notas de compra")
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
	endif
	If nOpca == 1
		u_logSX1 (cPerg)
		if mv_par05 <= '2011'
			Processa( { |lEnd| _Gera ()})
		elseif mv_par05 == '2012'
			Processa( { |lEnd| _Gera2012 ()})
		elseif mv_par05 == '2013'
			Processa( { |lEnd| _Gera2013 ()})
		elseif mv_par05 == '2014'
			Processa( { |lEnd| _Gera ()})
		elseif mv_par05 == '2015'
			if .f.
				Processa( { |lEnd| _Gera2015 ()})
			endif
			Processa( { |lEnd| _Gera2015A ()})
		elseif mv_par05 == '2016'
			Processa( { |lEnd| _Gera2016 ()})
		elseif mv_par05 == '2017'
			if .f.
				Processa( { |lEnd| _Gera2017 ()})
			endif
			Processa( { |lEnd| _Gera2017B ()})
		elseif mv_par05 == '2018'
			Processa( { |lEnd| _Gera2018 ()})
		elseif mv_par05 == '2020'
			Processa( { |lEnd| _Gera2020 ()})
		elseif mv_par05 == '2021'
			Processa( { |lEnd| _Gera2021 ()})
		elseif mv_par05 == '2023'
			Processa( { |lEnd| _Gera2023 ()})
		else
			u_help ('Sem tratamento para esta safra')
		endif
	Endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _lRet     := .T.
	_lRet = U_msgyesno ("ATENCAO: Este processo deve ser gerado somente uma vez. A cada vez que for executado, novas pre-notas de complemento serao geradas, independente de ja' terem sido geradas anteriormente. Continuar?")
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
	local _nPreco    := 0
	local _nNova	 := 0

	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (2)) // ZZ9_FILIAL+ZZ9_DCO
	zz9 -> (dbseek (xfilial ("ZZ9"), .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9")
//		u_log ('Verificando pre-nf', zz9 -> zz9_Pre_NF)
		incproc ()
		if zz9 -> zz9_safra != mv_par05 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10
			zz9 -> (dbskip ())
			loop
		endif

		// Busca o preco de compra para esta uva e verifica se foi usado preco menor.
		_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe)[2]
		u_log ('Preco atual:', _npreco, 'preco pago:', zz9 -> zz9_vunit)
		if _nPreco > zz9->zz9_vunit
			aadd (_aNovas, {zz9 -> zz9_fornec, ;
			                zz9 -> zz9_loja, ;
			                zz9 -> zz9_Produt, ;
			                zz9 -> zz9_Grau, ;
			                zz9 -> zz9_Classe, ;
			                (zz9->zz9_quant*_nPreco) - (zz9->zz9_quant*zz9->zz9_vunit), ;
			                zz9 -> zz9_Pre_NF, ;
			                zz9 -> zz9_nfentr, ;
			                zz9 -> zz9_dco})
			u_log ("dco:",TRAnsform (zz9->zz9_vunit, "@E 999.9999"), "compra:",TRAnsform (_nPreco, "@E 999.9999"), "qt:",trans(zz9->zz9_quant, "@E 99999"), zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe)
		endif

		zz9 -> (dbskip ())
	enddo

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		_sPreNF = _IncPreNF (_sPreNF)
		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = xfilial ("ZZ9")
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = _aNovas [_nNova, 1]
		zz9 -> zz9_loja   = _aNovas [_nNova, 2]
		zz9 -> zz9_produt = _aNovas [_nNova, 3]
		zz9 -> zz9_grau   = _aNovas [_nNova, 4]
		zz9 -> zz9_classe = _aNovas [_nNova, 5]
		zz9 -> zz9_vunit  = _aNovas [_nNova, 6]
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_nfentr = _aNovas [_nNova, 8]
		zz9 -> zz9_dco    = _aNovas [_nNova, 9]
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_tiponf = "C"
		zz9 -> zz9_preori = _aNovas [_nNova, 7]
		msunlock ()
	next

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Gera as notas com 'vazios' entre elas para poder inserir alguma pre-nf manualmente depois, se precisar.
Static Function _IncPreNF (_sPreNF)
return soma1 (soma1 (_sPreNF))  // Deixo uma em branco para caso de 'vai saber...'



// --------------------------------------------------------------------------
Static Function _Gera2012 ()
//	local _lContinua := .T.
//	local _sQuery    := ""
//	local _aNovas    := {}
	local _nPreco    := 0

	// Gera complemento de preco para uvas finas que deveriam ter desconsiderado classificacao.
	if ! cFilAnt $ '01/07/09/10/11/12'
		u_help ("Filial errada")
		return
	endif
	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (1)) // ZZ9_FILIAL+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_PRODUT+ZZ9_GRAU+ZZ9_CLASSE
	zz9 -> (dbseek (xfilial ("ZZ9") + mv_par05, .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9") .and. zz9 -> zz9_safra == mv_par05
		incproc ()
		if zz9 -> zz9_safra != mv_par05 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10
			zz9 -> (dbskip ())
			loop
		endif
		if empty (zz9 -> zz9_parcel) .or. zz9 -> zz9_parcel == mv_par06 .or. empty (zz9 -> zz9_classe) .or. alltrim (zz9 -> zz9_classe) $ "AA/A/B"
			zz9 -> (dbskip ())
			loop
		endif
		if fbuscacpo ("SB1", 1, xfilial ("SB1") + zz9 -> zz9_produt, "B1_VARUVA") != "F"
			zz9 -> (dbskip ())
			loop
		endif
		_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, 'B ')[2]
		if zz9 -> zz9_vunit >= _nPreco
			zz9 -> (dbskip ())
			loop
		endif
		u_log ('Preco atual:', _npreco, 'preco pago:', zz9 -> zz9_vunit)
		_Clona ((zz9->zz9_quant*_nPreco) - (zz9->zz9_quant*zz9->zz9_vunit))
		zz9 -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
Static Function _Gera2013 ()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
	local _nPreco    := 0
	local _nNova	 := 0

	_sQuery := " SELECT ASSOCIADO AS ASSOC, LOJA_ASSOC AS LOJA, PRODUTO, GRAU, CLAS_FINAL AS CLASSE, PESO_LIQ AS QUANT, VALOR_TOTAL AS VTOT "
	_sQuery += " FROM VA_VNOTAS_SAFRA V"
	_sQuery += " WHERE V.SAFRA = '2013' AND V.FILIAL = '07' AND V.CLAS_FINAL = 'DS' AND V.TIPO_NF = 'C' AND V.PRODUTO IN ('9908','9910','9911','9912','9916','9917','9969')"
	_sQuery += " AND FILIAL = '" + xfilial ("ZZ9") + "'"
	_sQuery += " ORDER BY V.PRODUTO, GRAU, V.NOME_ASSOC"
	u_log (_sQuery)
	_aNovas := aclone (U_Qry2Array (_sQuery))

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	u_log (_sQuery)
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		do case
		case alltrim (_aNovas [_nNova, 3]) == '9908' .and. _aNovas [_nNova, 4] == '13' ; _nPreco = .5
		case alltrim (_aNovas [_nNova, 3]) == '9908' .and. _aNovas [_nNova, 4] == '14' ; _nPreco = .55
		case alltrim (_aNovas [_nNova, 3]) == '9910' .and. _aNovas [_nNova, 4] == '14' ; _nPreco = .38
		case alltrim (_aNovas [_nNova, 3]) == '9911' .and. _aNovas [_nNova, 4] == '09' ; _nPreco = .35
		case alltrim (_aNovas [_nNova, 3]) == '9911' .and. _aNovas [_nNova, 4] == '10' ; _nPreco = .4
		case alltrim (_aNovas [_nNova, 3]) == '9911' .and. _aNovas [_nNova, 4] == '11' ; _nPreco = .46
		case alltrim (_aNovas [_nNova, 3]) == '9912' .and. _aNovas [_nNova, 4] == '10' ; _nPreco = .42
		case alltrim (_aNovas [_nNova, 3]) == '9912' .and. _aNovas [_nNova, 4] == '11' ; _nPreco = .46
		case alltrim (_aNovas [_nNova, 3]) == '9912' .and. _aNovas [_nNova, 4] == '12' ; _nPreco = .5
		case alltrim (_aNovas [_nNova, 3]) == '9912' .and. _aNovas [_nNova, 4] == '13' ; _nPreco = .55
		case alltrim (_aNovas [_nNova, 3]) == '9911' .and. _aNovas [_nNova, 4] == '13' ; _nPreco = .5
		case alltrim (_aNovas [_nNova, 3]) == '9916' .and. _aNovas [_nNova, 4] == '13' ; _nPreco = .5
		case alltrim (_aNovas [_nNova, 3]) == '9917' .and. _aNovas [_nNova, 4] == '14' ; _nPreco = .55
		case alltrim (_aNovas [_nNova, 3]) == '9969' .and. _aNovas [_nNova, 4] == '13' ; _nPreco = .42
		otherwise
			_nPreco = 0
		endcase 
		_sPreNF = _IncPreNF (_sPreNF)
		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = xfilial ("ZZ9")
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = _aNovas [_nNova, 1]
		zz9 -> zz9_loja   = _aNovas [_nNova, 2]
		zz9 -> zz9_produt = _aNovas [_nNova, 3]
		zz9 -> zz9_grau   = _aNovas [_nNova, 4]
		zz9 -> zz9_classe = _aNovas [_nNova, 5]
		zz9 -> zz9_vunit  = (_nPreco * _aNovas [_nNova, 6]) - _aNovas [_nNova, 7]
		zz9 -> zz9_tiponf = "C"
		msunlock ()
	next
return



// --------------------------------------------------------------------------
Static Function _Gera2015 ()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
	local _nPreco    := 0
	local _nNova	 := 0

	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (2)) // ZZ9_FILIAL+ZZ9_DCO
	zz9 -> (dbseek (xfilial ("ZZ9"), .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9")
		incproc ()
		if zz9 -> zz9_safra != mv_par05 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10 ;
			.or. ! zz9 -> zz9_parcel $ '1/2'  // 1 e 2: gerada nota compra; 3:gerada para comparar com 1 e 2 e achar diferencas lista preco; 4:gerado para nf compl.preco cfe diferente entre 1/2 e 3; 5:recompra do que foi devolvido com base na parcela 3
			zz9 -> (dbskip ())
			loop
		endif

		// Apenas meia duzia de casos especificos. Ver query "Diferenca preco lista safra 2015.sql" nos doc. de informatica.
		u_log ('>'+zz9 -> zz9_fornec + zz9 -> zz9_loja+'<', '>',alltrim (zz9 -> zz9_produt)+ '<', '>' + zz9 -> zz9_grau + '<', '>' + zz9 -> zz9_nfcomp + '<')
		_nPreco = 0
		do case
		case zz9 -> zz9_filial == '01' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00282501' .and. alltrim (zz9 -> zz9_produt) == '9911A' .and. zz9 -> zz9_grau == '18.0' .and. zz9 -> zz9_nfcomp == '000091733'
			_nPreco = 1.0868
		case zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00308301' .and. alltrim (zz9 -> zz9_produt) == '9913'  .and. zz9 -> zz9_grau == '16.0' .and. zz9 -> zz9_nfcomp == '000013469'
			_nPreco = 0.9923
		case zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00435401' .and. alltrim (zz9 -> zz9_produt) == '9912'  .and. zz9 -> zz9_grau == '16.0' .and. zz9 -> zz9_nfcomp == '000013700'
			_nPreco = 0.9923
		case zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00267101' .and. alltrim (zz9 -> zz9_produt) == '9912'  .and. zz9 -> zz9_grau == '16.0' .and. zz9 -> zz9_nfcomp == '000013522'
			_nPreco = 0.9923
		case zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00238601' .and. alltrim (zz9 -> zz9_produt) == '9912'  .and. zz9 -> zz9_grau == '16.0' .and. zz9 -> zz9_nfcomp == '000013586'
			_nPreco = 0.9923
		case zz9 -> zz9_filial == '07' .and. zz9 -> zz9_fornec + zz9 -> zz9_loja == '00123203' .and. alltrim (zz9 -> zz9_produt) == '9944'  .and. zz9 -> zz9_grau == '17.0' .and. zz9 -> zz9_nfcomp == '000013423'
			_nPreco = 1.616
		endcase

		// Verifica se foi usado preco menor.
		u_log ('Preco atual:', _npreco, 'preco pago:', zz9 -> zz9_vunit)
		if _nPreco > zz9->zz9_vunit
			aadd (_aNovas, {zz9 -> zz9_fornec, ;
			                zz9 -> zz9_loja, ;
			                zz9 -> zz9_Produt, ;
			                zz9 -> zz9_Grau, ;
			                zz9 -> zz9_Classe, ;
			                (zz9->zz9_quant*_nPreco) - (zz9->zz9_quant*zz9->zz9_vunit), ;
			                zz9 -> zz9_Pre_NF, ;
			                zz9 -> zz9_nfentr, ;
			                zz9 -> zz9_dco, ;
			                zz9 -> zz9_clabd})
			u_log ("dco:",TRAnsform (zz9->zz9_vunit, "@E 999.9999"), "compra:",TRAnsform (_nPreco, "@E 999.9999"), "qt:",trans(zz9->zz9_quant, "@E 99999"), zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe)
		endif

		zz9 -> (dbskip ())
	enddo

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		_sPreNF = _IncPreNF (_sPreNF)
		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = xfilial ("ZZ9")
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = _aNovas [_nNova, 1]
		zz9 -> zz9_loja   = _aNovas [_nNova, 2]
		zz9 -> zz9_produt = _aNovas [_nNova, 3]
		zz9 -> zz9_grau   = _aNovas [_nNova, 4]
		zz9 -> zz9_classe = _aNovas [_nNova, 5]
		zz9 -> zz9_vunit  = round (_aNovas [_nNova, 6], 2)
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_nfentr = _aNovas [_nNova, 8]
		zz9 -> zz9_dco    = _aNovas [_nNova, 9]
		zz9 -> zz9_clabd  = _aNovas [_nNova, 10]
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_tiponf = "C"
		zz9 -> zz9_preori = _aNovas [_nNova, 7]
		zz9 -> zz9_obs    = 'Erro vlr.lista orig.'
		msunlock ()
	next

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
Static Function _Gera2015A ()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
	local _nPreco    := 0
	local _nNova	 := 0
	
	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (2)) // ZZ9_FILIAL+ZZ9_DCO
	zz9 -> (dbseek (xfilial ("ZZ9"), .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9")
		incproc ()
		if zz9 -> zz9_safra != mv_par05 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10 ;
			.or. ! zz9 -> zz9_parcel $ '1/2'  // 1 e 2: gerada nota compra; 3:gerada para comparar com 1 e 2 e achar diferencas lista preco; 4:gerado para nf compl.preco cfe diferente entre 1/2 e 3; 5:recompra do que foi devolvido com base na parcela 3
			zz9 -> (dbskip ())
			loop
		endif

		u_log ('>'+zz9 -> zz9_fornec + zz9 -> zz9_loja+'<', '>',alltrim (zz9 -> zz9_produt)+ '<', '>' + zz9 -> zz9_grau + '<', '>' + zz9 -> zz9_nfcomp + '<')
		_nPreco = U_PrecoUva (zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe, zz9 -> zz9_clabd)[2]

		// Verifica se foi usado preco menor.
		u_log ('Preco atual:', _npreco, 'preco pago:', zz9 -> zz9_vunit)
		if _nPreco > zz9->zz9_vunit
			aadd (_aNovas, {zz9 -> zz9_fornec, ;
			                zz9 -> zz9_loja, ;
			                zz9 -> zz9_Produt, ;
			                zz9 -> zz9_Grau, ;
			                zz9 -> zz9_Classe, ;
			                (zz9->zz9_quant*_nPreco) - (zz9->zz9_quant*zz9->zz9_vunit), ;
			                zz9 -> zz9_Pre_NF, ;
			                zz9 -> zz9_nfentr, ;
			                zz9 -> zz9_dco, ;
			                zz9 -> zz9_clabd})
			u_log ("dco:",TRAnsform (zz9->zz9_vunit, "@E 999.9999"), "compra:",TRAnsform (_nPreco, "@E 999.9999"), "qt:",trans(zz9->zz9_quant, "@E 99999"), zz9 -> zz9_fornec, zz9 -> zz9_loja, zz9 -> zz9_Produt, zz9 -> zz9_Grau, zz9 -> zz9_Safra, zz9 -> zz9_Classe)
		endif

		zz9 -> (dbskip ())
	enddo

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		_sPreNF = _IncPreNF (_sPreNF)
		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = xfilial ("ZZ9")
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = _aNovas [_nNova, 1]
		zz9 -> zz9_loja   = _aNovas [_nNova, 2]
		zz9 -> zz9_produt = _aNovas [_nNova, 3]
		zz9 -> zz9_grau   = _aNovas [_nNova, 4]
		zz9 -> zz9_classe = _aNovas [_nNova, 5]
		zz9 -> zz9_vunit  = round (_aNovas [_nNova, 6], 2)
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_nfentr = _aNovas [_nNova, 8]
		zz9 -> zz9_dco    = _aNovas [_nNova, 9]
		zz9 -> zz9_clabd  = _aNovas [_nNova, 10]
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_tiponf = "C"
		zz9 -> zz9_preori = _aNovas [_nNova, 7]
		zz9 -> zz9_obs    = 'Erro vlr.lista orig.'
		msunlock ()
	next

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Algumas entradas de uvas viniferas em Livramento ficaram com classificacao
// abaixo por que foi usada tabela de faixas de grau errada.
Static Function _Gera2016 ()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
//	local _nPreco    := 0
	local _nNova	 := 0

	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (1)) // ZZ9_FILIAL+ZZ9_SAFRA+ZZ9_PARCEL+ZZ9_FORNEC+ZZ9_LOJA+ZZ9_PRODUT+ZZ9_GRAU+ZZ9_CLASSE
	zz9 -> (dbseek (xfilial ("ZZ9") + mv_par05, .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9") .and. zz9 -> zz9_safra == mv_par05
		incproc ()
		if zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10
			zz9 -> (dbskip ())
			loop
		endif
		aadd (_aNovas, {zz9 -> zz9_fornec, ;
		                zz9 -> zz9_loja, ;
		                zz9 -> zz9_Produt, ;
		                zz9 -> zz9_Grau, ;
		                zz9 -> zz9_Classe, ;
		                mv_par11, ;
		                zz9 -> zz9_Pre_NF, ;
		                zz9 -> zz9_nfentr, ;
		                zz9 -> zz9_dco, ;
		                zz9 -> zz9_clabd})
		exit  // Tendo uma ocorrencia eh suficiente.
		zz9 -> (dbskip ())
	enddo

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		_sPreNF = _IncPreNF (_sPreNF)
		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = xfilial ("ZZ9")
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = _aNovas [_nNova, 1]
		zz9 -> zz9_loja   = _aNovas [_nNova, 2]
		zz9 -> zz9_produt = _aNovas [_nNova, 3]
		zz9 -> zz9_grau   = _aNovas [_nNova, 4]
		zz9 -> zz9_classe = _aNovas [_nNova, 5]
		zz9 -> zz9_vunit  = round (_aNovas [_nNova, 6], 2)
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_nfentr = _aNovas [_nNova, 8]
		zz9 -> zz9_dco    = _aNovas [_nNova, 9]
		zz9 -> zz9_clabd  = _aNovas [_nNova, 10]
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_tiponf = "C"
		zz9 -> zz9_preori = _aNovas [_nNova, 7]
		zz9 -> zz9_obs    = 'Ajuste classif.viniferas'
		msunlock ()
	next
	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Notas de compra foram geradas mais cedo a preco de tabela MOC da CONAB para uso em comprovacoes de preco para emprestimos bancarios.
Static Function _Gera2017 ()
//	local _lContinua := .T.
	local _sQuery    := ""
	local _aNovas    := {}
//	local _nPreco    := 0
	local _nNova	 := 0

	procregua (zz9 -> (reccount ()))
	zz9 -> (dbsetorder (2)) // ZZ9_FILIAL+ZZ9_DCO
	zz9 -> (dbseek (xfilial ("ZZ9"), .T.))
	do while ! zz9 -> (eof ()) .and. zz9 -> zz9_filial == xfilial ("ZZ9")
		incproc ()
		if zz9 -> zz9_safra != mv_par05 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja < mv_par01 + mv_par02 ;
			.or. zz9 -> zz9_fornec + zz9 -> zz9_loja > mv_par03 + mv_par04 ;
			.or. zz9 -> zz9_dco < mv_par07 ;
			.or. zz9 -> zz9_dco > mv_par08 ;
			.or. zz9 -> zz9_produt < mv_par09 ;
			.or. zz9 -> zz9_produt > mv_par10 ;
			.or. zz9 -> zz9_parcel != 'C'  // Parcela criada no ZZ9 apenas para diferenciar as notas que precisam complemento.
			zz9 -> (dbskip ())
			loop
		endif
		aadd (_aNovas, {zz9 -> zz9_fornec, ;
		                zz9 -> zz9_loja, ;
		                zz9 -> zz9_Produt, ;
		                zz9 -> zz9_Grau, ;
		                zz9 -> zz9_Classe, ;
		                (zz9->ZZ9_QUANT * zz9->ZZ9_VUNIT) - (zz9->ZZ9_QUANT * zz9->ZZ9_VUNOLD), ;
		                zz9 -> zz9_Pre_NF, ;
		                zz9 -> zz9_nfentr, ;
		                zz9 -> zz9_dco, ;
		                zz9 -> zz9_clabd})
		zz9 -> (dbskip ())
	enddo

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)

	for _nNova = 1 to len (_aNovas)
		if round (_aNovas [_nNova, 6], 2) > 0  // Tive casos de nossa tabela ficar abaixo da MOC.
			_sPreNF = _IncPreNF (_sPreNF)
			reclock ("ZZ9", .T.)
			zz9 -> zz9_filial = xfilial ("ZZ9")
			zz9 -> zz9_safra  = mv_par05
			zz9 -> zz9_parcel = mv_par06
			zz9 -> zz9_fornec = _aNovas [_nNova, 1]
			zz9 -> zz9_loja   = _aNovas [_nNova, 2]
			zz9 -> zz9_produt = _aNovas [_nNova, 3]
			zz9 -> zz9_grau   = _aNovas [_nNova, 4]
			zz9 -> zz9_classe = _aNovas [_nNova, 5]
			zz9 -> zz9_vunit  = round (_aNovas [_nNova, 6], 2)
			zz9 -> zz9_pre_nf = _sPreNF
			zz9 -> zz9_nfentr = _aNovas [_nNova, 8]
			zz9 -> zz9_dco    = _aNovas [_nNova, 9]
			zz9 -> zz9_clabd  = _aNovas [_nNova, 10]
			zz9 -> zz9_quant  = 0
			zz9 -> zz9_tiponf = "C"
			zz9 -> zz9_preori = _aNovas [_nNova, 7]
			zz9 -> zz9_obs    = 'Vlr.MOC abaixo nossa tabela'
			msunlock ()
		endif
	next

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Complemento geral de valores 2017.
Static Function _Gera2017B ()
//	local _lContinua := .T.
//	local _aNovas    := {}
	local _nPreco    := 0
	local _oSQL      := NIL
	local _sAliasQ   := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT P.*,"

	// A leitura do sistema de conducao nao foi feita em julho/2017. Deixo o trecho de query aqui para que nao caia no esquecimento nas proximas vezes.
	_oSQL:_sQuery +=       " (SELECT TOP 1 SIST_CONDUCAO"
	_oSQL:_sQuery +=          " FROM VA_VASSOC_CAD_VITIC C"
	_oSQL:_sQuery +=         " WHERE C.SAFRA      = P.SAFRA"
	_oSQL:_sQuery +=           " AND C.ASSOCIADO  = P.ASSOCIADO"
	_oSQL:_sQuery +=           " AND C.LOJA_ASSOC = P.LOJA_ASSOC"
	_oSQL:_sQuery +=           " AND C.PRODUTO    = P.PRODUTO) AS CONDUCAO"

	_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA P"
	_oSQL:_sQuery += " WHERE P.SAFRA  = '2017'"
	_oSQL:_sQuery +=   " AND P.FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery += " ORDER BY P.FILIAL, P.PRODUTO, P.GRAU"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> filial == cFilAnt
		incproc ()
		_nPreco = U_PrecoUva ((_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, (_sAliasQ) -> produto, (_sAliasQ) -> grau, (_sAliasQ) -> safra, (_sAliasQ) -> clas_final, '', 'C', (_sAliasQ) -> filial)
		if _nPreco == 0
			u_log ('Sem preco definido')
		elseif _nPreco > (_sAliasQ) -> VUnit_efetivo

			// Gera proxima pre-nf livre
			_sQuery := " select max (ZZ9_PRE_NF)"
			_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
			_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
			_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
			_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
			_sPreNF = _IncPreNF (U_RetSQL (_sQuery))

			reclock ("ZZ9", .T.)
			zz9 -> zz9_filial = xfilial ("ZZ9")
			zz9 -> zz9_safra  = mv_par05
			zz9 -> zz9_parcel = mv_par06
			zz9 -> zz9_pre_nf = _sPreNF
			zz9 -> zz9_fornec = (_sAliasQ) -> associado
			zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
			zz9 -> zz9_produt = (_sAliasQ) -> produto
			zz9 -> zz9_grau   = (_sAliasQ) -> grau
			zz9 -> zz9_classe = (_sAliasQ) -> clas_final
			zz9 -> zz9_vunit  = round (((_sAliasQ) -> peso_liq * _nPreco) - ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo), 2)
			zz9 -> zz9_nfori  = (_sAliasQ) -> doc
			zz9 -> zz9_serior = (_sAliasQ) -> serie
			zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
			zz9 -> zz9_quant  = 0
			zz9 -> zz9_tiponf = "C"
			
			// O campo zz9_conduc nao foi gravado em julho/2017. Deixo-o aqui para que nao caia no esquecimento nas proximas vezes.
			zz9 -> zz9_conduc = (_sAliasQ) -> conducao
			msunlock ()
		endif

		(_sAliasQ) -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
// Simulacao complemento comuns 2018, provavelmente vai cair como distribuicao de sobras.
Static Function _Gera2018 ()  // faz para TODAS AS FILIAIS
//	local _lContinua := .T.
//	local _aNovas    := {}
	local _nPreco    := 0
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nVCompl   := 0
	local _lDesclas  := .F.

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT P.*, ISNULL (Z1_PRCCOM, 0) AS Z1_PRCCOM, ISNULL (N.GRUPO_PAGTO, '') AS GRUPO, B1_VARUVA, B1_VAFCUVA, B1_VACOR, "

	// A leitura do sistema de conducao nao interessa nas comuns, mas deixo o trecho de query aqui para que nao caia no esquecimento nas proximas vezes.
	_oSQL:_sQuery +=       " (SELECT TOP 1 SIST_CONDUCAO"
	_oSQL:_sQuery +=          " FROM VA_VASSOC_CAD_VITIC C"
	_oSQL:_sQuery +=         " WHERE C.SAFRA      = P.SAFRA"
	_oSQL:_sQuery +=           " AND C.ASSOCIADO  = P.ASSOCIADO"
	_oSQL:_sQuery +=           " AND C.LOJA_ASSOC = P.LOJA_ASSOC"
	_oSQL:_sQuery +=           " AND C.PRODUTO    = P.PRODUTO) AS CONDUCAO"

	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1, "
	_oSQL:_sQuery +=  " VA_VPRECO_EFETIVO_SAFRA P"
	_oSQL:_sQuery +=       " LEFT JOIN " + RetSQLName ("SZ1") + " SZ1 "
	_oSQL:_sQuery +=            " ON (SZ1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SZ1.Z1_TABELA  = '2018S1'"  // Tabela de simulacao dez/2018 
	_oSQL:_sQuery +=           " AND SZ1.Z1_CODPRD  = (CASE WHEN P.FILIAL = '01' AND P.ASSOCIADO = '002215' AND P.DOC = '000013441' THEN '9923           ' ELSE"  // variedade errada
	_oSQL:_sQuery +=                                " CASE WHEN P.FILIAL = '01' AND P.ASSOCIADO = '002948' AND P.DOC = '000013747' THEN '9923           ' ELSE"  // variedade errada
	_oSQL:_sQuery +=                                " P.PRODUTO END END)"
	_oSQL:_sQuery +=           " AND SZ1.Z1_GRAU    = P.GRAU)"
	_oSQL:_sQuery +=       " LEFT JOIN VA_VNOTAS_SAFRA N "
	_oSQL:_sQuery +=            " ON (N.SAFRA     = P.SAFRA"
	_oSQL:_sQuery +=           " AND N.FILIAL     = P.FILIAL" 
	_oSQL:_sQuery +=           " AND N.ASSOCIADO  = P.ASSOCIADO"
	_oSQL:_sQuery +=           " AND N.LOJA_ASSOC = P.LOJA_ASSOC"
	_oSQL:_sQuery +=           " AND N.DOC        = P.DOC"
	_oSQL:_sQuery +=           " AND N.SERIE      = P.SERIE"
	_oSQL:_sQuery +=           " AND N.ITEM_NOTA  = P.ITEM_NOTA)"
	_oSQL:_sQuery += " WHERE P.SAFRA  = '" + mv_par05 + "'"
	_oSQL:_sQuery +=   " AND P.ASSOCIADO + P.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND P.PRODUTO BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_oSQL:_sQuery +=   " AND P.PRODUTO = SB1.B1_COD"
	if ! empty (mv_par12)
		_oSQL:_sQuery +=    " AND P.PRODUTO IN " + FormatIn (alltrim (mv_par12), "/")
	endif
	if ! empty (mv_par13)
		_oSQL:_sQuery +=    " AND P.PRODUTO NOT IN " + FormatIn (alltrim (mv_par13), "/")
	endif
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND (SB1.B1_VARUVA = 'C' OR (SB1.B1_VARUVA = 'F' AND SB1.B1_VAFCUVA = 'F' AND P.FILIAL != '03'))"
	_oSQL:_sQuery +=   " AND P.FILIAL != '03'"
	_oSQL:_sQuery +=   " AND P.PRODUTO != '9976'"  // Violeta fica de fora


//	_oSQL:_sQuery +=   " AND SB1.B1_VARUVA = 'F'"


	_oSQL:_sQuery += " ORDER BY P.FILIAL, P.PRODUTO, P.GRAU"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	do while ! (_sAliasQ) -> (eof ())// .and. (_sAliasQ) -> filial == cFilAnt
		incproc ()
		//_nPreco = U_PrecoUva ((_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, (_sAliasQ) -> produto, (_sAliasQ) -> grau, (_sAliasQ) -> safra, (_sAliasQ) -> clas_final, '', 'C', (_sAliasQ) -> filial)
		_nPreco = (_sAliasQ) -> z1_prccom
		
		// Viniferas desclassificadas
		_lDesclas = .F.
		if (_sAliasQ) -> b1_varuva == 'F' .and. (_sAliasQ) -> b1_vafcuva == 'F'
			u_log ('vinifera:', (_sAliasQ) -> produto, (_sAliasQ) -> descricao, 'grau', (_sAliasQ) -> grau, (_sAliasQ) -> clas_ABD, 'pago:', (_sAliasQ) -> VUnit_efetivo)
			if (_sAliasQ) -> clas_abd == 'D'
				u_log ('desclassificada')
				_lDesclas = .T.
			endif
			if (_sAliasQ) -> b1_vacor $ 'B/R' .and. (_sAliasQ) -> grau < '11.0'
				u_log ('branca abaixo grau')
				_lDesclas = .T.
			endif
			if (_sAliasQ) -> b1_vacor == 'T'
				if alltrim ((_sAliasQ) -> produto) == '9969' // alicante somente abaixo de 11
					if (_sAliasQ) -> grau < '11.0'
						u_log ('alicante abaixo grau')
						_lDesclas = .T.
					elseif (_sAliasQ) -> grau == '12.0' .and. (_sAliasQ) -> clas_ABD == "A"
						_nPreco = 1.2623
					elseif (_sAliasQ) -> grau == '13.0' .and. (_sAliasQ) -> clas_ABD == "A"
						_nPreco = 1.4108
					endif
				else
					if (_sAliasQ) -> grau < '14.0'
						u_log ('tinta abaixo grau')
						_lDesclas = .T.
					endif
				endif
			endif
			if _lDesclas
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT Z1_PRCCOM"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZ1") + " SZ1 "
				_oSQL:_sQuery += " WHERE SZ1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SZ1.Z1_TABELA  = '2018S1'"  // Tabela de simulacao dez/2018 
				_oSQL:_sQuery +=   " AND SZ1.Z1_CODPRD  = '" + iif ((_sAliasQ) -> b1_vacor == 'T', '9901           ', '9904           ') + "'"
				_oSQL:_sQuery +=   " AND SZ1.Z1_GRAU    = '" + (_sAliasQ) -> grau + "'"
				_oSQL:Log ()
				_nPreco = _oSQL:RetQry ()
				u_log (_nPreco)
			endif
		endif
		
		if _nPreco == 0
			if (_sAliasQ) -> b1_varuva == 'F' .and. (_sAliasQ) -> b1_vafcuva == 'F' .and. _lDesclas
				u_log ('Sem preco definido para ', (_sAliasQ) -> produto, (_sAliasQ) -> descricao, 'grau', (_sAliasQ) -> grau, (_sAliasQ) -> clas_ABD)
			endif
		else
			_nVCompl = round (((_sAliasQ) -> peso_liq * _nPreco) - ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo), 2)
			if _lDesClas
				u_log ('compl=', _nVCompl, (_sAliasQ) -> produto, (_sAliasQ) -> descricao, 'grau', (_sAliasQ) -> grau, (_sAliasQ) -> clas_ABD)
			endif
			if _nVCompl > 0

				// Gera proxima pre-nf livre
				_sQuery := " select max (ZZ9_PRE_NF)"
				_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
				_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
				_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
				_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
				_sPreNF = _IncPreNF (U_RetSQL (_sQuery))
	
				reclock ("ZZ9", .T.)
				zz9 -> zz9_filial = (_sAliasQ) -> FILIAL
				zz9 -> zz9_safra  = mv_par05
				zz9 -> zz9_parcel = mv_par06
				zz9 -> zz9_pre_nf = _sPreNF
				zz9 -> zz9_fornec = (_sAliasQ) -> associado
				zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
				zz9 -> zz9_produt = (_sAliasQ) -> produto
				zz9 -> zz9_grau   = (_sAliasQ) -> grau
				zz9 -> zz9_classe = (_sAliasQ) -> clas_final
				zz9 -> zz9_vunit  = _nVCompl
				zz9 -> zz9_vunOld = (_sAliasQ) -> VUnit_efetivo
				zz9 -> zz9_nfori  = (_sAliasQ) -> doc
				zz9 -> zz9_serior = (_sAliasQ) -> serie
				zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
				zz9 -> zz9_quant  = 0
				zz9 -> zz9_tiponf = "C"
				zz9 -> zz9_conduc = (_sAliasQ) -> conducao
				zz9 -> zz9_obs    = "COMPL DEZ/2018"
				zz9 -> zz9_grupo  = (_sAliasQ) -> grupo
				msunlock ()
			else
				u_log ('Complemento negativo produto ', (_sAliasQ) -> produto, (_sAliasQ) -> descricao, 'grau', (_sAliasQ) -> grau)
			endif
		endif

		(_sAliasQ) -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
Static Function _Gera2020 ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nVCompl   := 0
	local _sClasFina := ''
	local _aRetPrc   := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT *"
	_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA P"
	_oSQL:_sQuery += " WHERE P.SAFRA  = '" + mv_par05 + "'"
	_oSQL:_sQuery +=   " AND P.ASSOCIADO + P.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND P.PRODUTO BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if ! empty (mv_par12)
		_oSQL:_sQuery +=    " AND P.PRODUTO IN " + FormatIn (alltrim (mv_par12), "/")
	endif
	if ! empty (mv_par13)
		_oSQL:_sQuery +=    " AND P.PRODUTO NOT IN " + FormatIn (alltrim (mv_par13), "/")
	endif
	_oSQL:_sQuery += " ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, PRODUTO, GRAU, CLAS_FINAL, CLAS_ABD"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	do while ! (_sAliasQ) -> (eof ())
		incproc ()
		
		// Fizemos apenas uma compra das notas 'limpas' (preco cheio) em maio.
		// Se for para complamentar mais alguma, criar tratamento para casos de mistura, etc.
		if ! alltrim ((_sAliasQ) -> produto) $ '9925/9822/9936/9811/9812'
			u_help ("Sem previsao de complemento pra esta variedade nesta safra",, .t.)
			(_sAliasQ) -> (dbskip ())
		endif

		// Assume a classificacao da uva vinifera conforme o sistema de conducao.
		if (_sAliasQ) -> sist_conducao == 'L'
			_sClasFina = (_sAliasQ) -> clas_abd
		elseif (_sAliasQ) -> sist_conducao == 'E'
			_sClasFina = (_sAliasQ) -> clas_final
		else
			u_help ("Sistema de conducao '" + (_sAliasQ) -> sist_conducao + "' sem tratamento (NF compra " + (_sAliasQ) -> doc + ")",, .t.)
		endif
		u_log2 ('info', 'NF orig: ' + (_sAliasQ) -> doc + ' Produto ' + alltrim ((_sAliasQ) -> produto) + '-' + alltrim ((_sAliasQ) -> descricao) + ' gr.' + (_sAliasQ) -> grau + ' ' + _sClasFina)

		_aRetPrc = aclone (U_PrcUva20 ((_sAliasQ) -> filial, (_sAliasQ) -> produto, val ((_sAliasQ) -> grau), _sClasFina, (_sAliasQ) -> sist_conducao, .F.))

		// A funcao retorna diferentes valores, mas aqui quero apenas o valor de compra e as observacoes.
		_aRetPrc = {_aRetPrc[2], _aRetPrc [3]}
	//	u_log2 ('info', 'Preco unit gerado           : ' + cvaltochar (_aRetPrc [1]) + '  ' + _aRetPrc [2])
	//	u_log2 ('info', 'Preco total gerado          : ' + cvaltochar ((_sAliasQ) -> peso_liq * _aRetPrc [1]))
	//	u_log2 ('info', 'Preco efetivo ateh o momento: ' + cvaltochar ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo))
		_nVCompl = ((_sAliasQ) -> peso_liq * _aRetPrc [1]) - ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo)
	//	u_log2 ('info', 'Valor total complemento     : ' + cvaltochar (_nVCompl))
		if _nVCompl > 10  // Estabeleci, por minha conta, um valor minimo. Robert, 23/06/20

			// Gera proxima pre-nf livre
			_sQuery := " select max (ZZ9_PRE_NF)"
			_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
			_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
			_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
			_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
			_sPreNF = _IncPreNF (U_RetSQL (_sQuery))

			reclock ("ZZ9", .T.)
			zz9 -> zz9_filial = (_sAliasQ) -> FILIAL
			zz9 -> zz9_safra  = mv_par05
			zz9 -> zz9_grupo  = (_sAliasQ) -> grupo_PAGTO
			zz9 -> zz9_parcel = mv_par06
			zz9 -> zz9_fornec = (_sAliasQ) -> associado
			zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
			zz9 -> zz9_pre_nf = _sPreNF
			zz9 -> zz9_tiponf = "C"
			zz9 -> zz9_produt = (_sAliasQ) -> produto
			zz9 -> zz9_grau   = (_sAliasQ) -> grau
			zz9 -> zz9_classe = (_sAliasQ) -> clas_final
			zz9 -> zz9_clabd  = (_sAliasQ) -> clas_abd
			zz9 -> zz9_conduc = (_sAliasQ) -> sist_conducao
			zz9 -> zz9_vunOld = (_sAliasQ) -> VUnit_efetivo
			zz9 -> zz9_quant  = 0
			zz9 -> zz9_vunit  = _nVCompl
			zz9 -> zz9_obs    = _aRetPrc [2]
			zz9 -> zz9_nfori  = (_sAliasQ) -> doc
			zz9 -> zz9_serior = (_sAliasQ) -> serie
			zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu1 = (_sAliasQ) -> ?
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu2 = (_sAliasQ) -> ?
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu3 = (_sAliasQ) -> ?
			zz9 -> zz9_msgNF  = 'COMPL PRECO'
			zz9 -> zz9_TES    = '107'
			msunlock ()

		else
			u_log2 ('info', 'Complemento negativo!')
		endif

		(_sAliasQ) -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return



// --------------------------------------------------------------------------
static function _Gera2021 ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nVCompl   := 0
	local _sClasFina := ''
	local _aRetPrc   := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT *"
	_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA P"
	_oSQL:_sQuery += " WHERE P.SAFRA  = '" + mv_par05 + "'"
	_oSQL:_sQuery +=   " AND P.ASSOCIADO + P.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND P.FILIAL  BETWEEN '" + mv_par14 + "' AND '" + mv_par15 + "'"
	_oSQL:_sQuery +=   " AND P.PRODUTO BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if ! empty (mv_par12)
		_oSQL:_sQuery +=    " AND P.PRODUTO IN " + FormatIn (alltrim (mv_par12), "/")
	endif
	if ! empty (mv_par13)
		_oSQL:_sQuery +=    " AND P.PRODUTO NOT IN " + FormatIn (alltrim (mv_par13), "/")
	endif
	_oSQL:_sQuery += " ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, PRODUTO, GRAU, CLAS_FINAL, CLAS_ABD"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	do while ! (_sAliasQ) -> (eof ())
		incproc ()
		
		// Assume a classificacao da uva vinifera conforme o sistema de conducao.
		// Para este ano vamos chumbar classificacao das latadas apenas pelo grau.
		_sClasFina = ''
		if (_sAliasQ) -> sist_conducao == 'L' .and. (_sAliasQ) -> filial == '07'
			if alltrim ((_sAliasQ) -> produto) $ '9845/9854/9911/9932/9920/9928/9912' // moscatos, riesling e procecco, trebiano
				if val ((_sAliasQ) -> grau) >= 12
					_sClasFina = 'A'
				elseif val ((_sAliasQ) -> grau) >= 9
					_sClasFina = 'B'
				else
					_sClasFina = 'D'
				endif
			endif
		elseif (_sAliasQ) -> sist_conducao == 'E'
			_sClasFina = (_sAliasQ) -> clas_final
		else
			u_help ("Sistema de conducao '" + (_sAliasQ) -> sist_conducao + "' sem tratamento (NF compra " + (_sAliasQ) -> doc + ")",, .t.)
		endif
		u_log2 ('info', 'NF orig: ' + (_sAliasQ) -> doc + ' Produto ' + alltrim ((_sAliasQ) -> produto) + '-' + alltrim ((_sAliasQ) -> descricao) + ' gr.' + (_sAliasQ) -> grau + ' ' + _sClasFina)

		_aRetPrc = aclone (U_PrcUva21 ((_sAliasQ) -> filial, (_sAliasQ) -> produto, val ((_sAliasQ) -> grau), _sClasFina, (_sAliasQ) -> sist_conducao, .F., .F.))

		// A funcao retorna diferentes valores, mas aqui quero apenas o valor de compra e as observacoes.
		_aRetPrc = {_aRetPrc[2], _aRetPrc [3]}
		u_log2 ('info', 'Preco unit gerado           : ' + cvaltochar (_aRetPrc [1]) + '  ' + _aRetPrc [2])
		u_log2 ('info', 'Preco total gerado          : ' + cvaltochar ((_sAliasQ) -> peso_liq * _aRetPrc [1]))
		u_log2 ('info', 'Preco total efetivo ateh o momento: ' + cvaltochar ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo))
		_nVCompl = ((_sAliasQ) -> peso_liq * _aRetPrc [1]) - ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo)
		u_log2 ('info', 'Valor total complemento     : ' + cvaltochar (_nVCompl))
		if _nVCompl > 0

			// Gera proxima pre-nf livre
			_sQuery := " select max (ZZ9_PRE_NF)"
			_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
			_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
			_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
			_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
			_sPreNF = _IncPreNF (U_RetSQL (_sQuery))

			reclock ("ZZ9", .T.)
			zz9 -> zz9_filial = (_sAliasQ) -> FILIAL
			zz9 -> zz9_safra  = mv_par05
			zz9 -> zz9_grupo  = (_sAliasQ) -> grupo_PAGTO
			zz9 -> zz9_parcel = mv_par06
			zz9 -> zz9_fornec = (_sAliasQ) -> associado
			zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
			zz9 -> zz9_pre_nf = _sPreNF
			zz9 -> zz9_tiponf = "C"
			zz9 -> zz9_produt = (_sAliasQ) -> produto
			zz9 -> zz9_grau   = (_sAliasQ) -> grau
			zz9 -> zz9_classe = (_sAliasQ) -> clas_final
			zz9 -> zz9_clabd  = (_sAliasQ) -> clas_abd
			zz9 -> zz9_conduc = (_sAliasQ) -> sist_conducao
			zz9 -> zz9_vunOld = (_sAliasQ) -> VUnit_efetivo
			zz9 -> zz9_quant  = 0
			zz9 -> zz9_qtOri  = (_sAliasQ) -> peso_liq  // Campo util para relatorios posteriores
			zz9 -> zz9_vunit  = _nVCompl
			zz9 -> zz9_vunit2 = _aRetPrc [1]
			zz9 -> zz9_obs    = _aRetPrc [2]
			zz9 -> zz9_nfori  = (_sAliasQ) -> doc
			zz9 -> zz9_serior = (_sAliasQ) -> serie
			zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu1 = (_sAliasQ) -> ?
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu2 = (_sAliasQ) -> ?
		// NAO CRIEI TRATAMENTO PARA ESTA SAFRA	zz9 -> zz9_mistu3 = (_sAliasQ) -> ?
			zz9 -> zz9_msgNF  = 'COMPL PRECO'
			zz9 -> zz9_TES    = U_TESSafra (mv_par05, (_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, 'V')
			zz9 -> zz9_dco    = 'GLPI9891'
			msunlock ()
		else
			u_log2 ('aviso', 'Complemento negativo ou zerado.')
		endif
		(_sAliasQ) -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return


// --------------------------------------------------------------------------
static function _Gera2023 ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _nVCompl   := 0
	local _sClasFina := ''
	local _aRetPrc   := 0
	local _sMsgNF    := ''
	local _nRecAtu   := 0
	local _nRecCount := 0
	local _lVerMist  := .F.
	local _aMenorVl  := {}
	local _nAux      := 0
	local _oCarSaf   := NIL
	local _nCpoZZ9   := 0
	local _sTpForn   := ''

	// Busca valores efetivos recebidos pelo produtor, para depois verificar
	// necessidade de complementar.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, ITEM_NOTA"
	_oSQL:_sQuery +=      ", PRODUTO, DESCRICAO, PESO_LIQ"
	_oSQL:_sQuery +=      ", rtrim (cast (ROUND (GRAU, 0) as varchar (4))) + '.0' AS GRAU"  // Simulando graus sem decimal
	_oSQL:_sQuery +=      ", SIST_CONDUCAO, CLAS_ABD, CLAS_FINAL, VUNIT_EFETIVO, GRUPO_PAGTO"
	_oSQL:_sQuery +=      ", COUNT (*) OVER (PARTITION BY FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE) AS QTITENS"
	_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA P"
	_oSQL:_sQuery += " WHERE P.SAFRA  = '" + mv_par05 + "'"
	_oSQL:_sQuery +=   " AND P.ASSOCIADO + P.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND P.FILIAL  BETWEEN '" + mv_par14 + "' AND '" + mv_par15 + "'"
	_oSQL:_sQuery +=   " AND P.PRODUTO BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	if ! empty (mv_par12)
		_oSQL:_sQuery +=    " AND P.PRODUTO IN " + FormatIn (alltrim (mv_par12), "/")
	endif
	if ! empty (mv_par13)
		_oSQL:_sQuery +=    " AND P.PRODUTO NOT IN " + FormatIn (alltrim (mv_par13), "/")
	endif
	_oSQL:_sQuery += " ORDER BY FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, PRODUTO, GRAU, CLAS_FINAL, CLAS_ABD"
	_oSQL:Log ('[' + procname () + ']')
	_sAliasQ = _oSQL:Qry2Trb ()
	dbselectarea (_sAliasQ)
	count to _nRecCount
	dbselectarea ("ZZ9")
	(_sAliasQ) -> (dbgotop ())
	procregua (_nRecCount)
	_nRecAtu = 0
	do while ! (_sAliasQ) -> (eof ())
		incproc ()
		u_log2 ('info', '[' + cvaltochar (++_nRecAtu) + ' de ' + cvaltochar (_nRecCount) + ']NF orig: ' + (_sAliasQ) -> doc + ' Produto ' + alltrim ((_sAliasQ) -> produto) + '-' + alltrim ((_sAliasQ) -> descricao) + ' gr.' + (_sAliasQ) -> grau + ' ' + _sClasFina)
		_sMsgNF = ''

		// Encontra a carga de origem, pois pode ter sido compartilhada com
		// outro produtor.
		sze -> (dbsetorder (3))  // ZE_FILIAL, ZE_NFGER, ZE_SERIE, R_E_C_N_O_, D_E_L_E_T_
		if ! sze -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> doc + (_sAliasQ) -> serie, .F.))
			u_help ("Nao encotrei nenhuma carga referenciando a contranota '" + (_sAliasQ) -> doc + "' da filial '" + (_sAliasQ) -> filial + "'",, .t.)
			exit
		endif

		// Se a contranota original tem mais de um item, eh suspeita de ter
		// mistura de variedades. Se a carga for compartilhada, eh mais suspeita ainda
		_aMenorVl = {}
		_lVerMist = .f.
		_oCarSaf  = NIL
		if (_sAliasQ) -> qtItens > 1
			U_Log2 ('info', '[' + procname () + ']Vou verificar mistura por que a contranota tem mais de um item')
			_lVerMist = .t.
		endif
		if ! empty (sze -> ze_ccompar)
			U_Log2 ('info', '[' + procname () + ']Vou verificar mistura por que a carga ' + sze -> ze_carga + ' foi compartilhada com a(s) carga(s) ' + sze -> ze_ccompar)
			_lVerMist = .t.
		endif
		if _lVerMist
			// Instancia a carga para poder verificar mais a fundo.
			_oCarSaf := ClsCarSaf ():New (sze -> (recno ())) //(_sAliasQ) -> filial + mv_par05 + _aMenorVl [_nAux, 3])
			if empty (_oCarSaf:Carga)
				u_help ("Impossivel instanciar carga (ou carga invalida).",, .t.)
				exit
			endif
			//U_Log2 ('debug', '[' + procname () + ']' + _oCarSaf:ConsCompar ())
			_aMenorVl = aclone (_oCarSaf:VarMenorVl (2))  // pos.2=preco de compra
		endif
		if len (_aMenorVl) > 3
			u_help ("Este programa nao tem tratamento para cargas com mistura de mais de 3 variedades. Faltariam campos na tabela ZZ9 !!!")
			exit
		else
			if len (_aMenorVl) > 1
				_sMsgNF += "Mistura:"
			endif
			for _nAux = 1 to len (_aMenorVl)
				if ! alltrim (_aMenorVl [_nAux, 1]) $ _sMsgNF
					_sMsgNF += alltrim (_aMenorVl [_nAux, 1]) + '-' + alltrim (fBuscaCpo ("SB5", 1, xfilial ("SB5") + _aMenorVl [_nAux, 1], "B5_CEME")) + ';'
				endif
			next
		endif

		// Se teve mistura, preciso assumir a variedade de menor valor.
		// Mas geralmente a 'variedade de menor valor' eh a propria variedade
		// da contranota original, entao nem preciso ficar gravando mensagem
		// sobre misturas.
		if len (_aMenorVl) >= 1 .and. _aMenorVl [1, 1] != (_sAliasQ) -> produto
			_sMsgNF += 'Usar preco de ' + alltrim (_aMenorVl [1, 1]) + ';'
			_aRetPrc = aclone (U_PrcUva23 ((_sAliasQ) -> filial, _aMenorVl [1, 1], val ((_sAliasQ) -> grau), _sClasFina, _aMenorVl [1, 3], .F., .F.))
		else
			// Assume a classificacao da uva vinifera conforme o sistema de conducao.
			_sClasFina = ''
			if (_sAliasQ) -> sist_conducao == 'L'
				_sClasFina = (_sAliasQ) -> clas_abd
			elseif (_sAliasQ) -> sist_conducao == 'E'
				_sClasFina = (_sAliasQ) -> clas_final
			else
				u_help ("Sistema de conducao '" + (_sAliasQ) -> sist_conducao + "' sem tratamento (NF compra " + (_sAliasQ) -> doc + ")",, .t.)
			endif
			_aRetPrc = aclone (U_PrcUva23 ((_sAliasQ) -> filial, (_sAliasQ) -> produto, val ((_sAliasQ) -> grau), _sClasFina, (_sAliasQ) -> sist_conducao, .F., .F.))
		endif

		// A funcao retorna diferentes valores, mas aqui quero apenas o valor de compra e as observacoes.
		_aRetPrc = {_aRetPrc[2], _aRetPrc [3], _aRetPrc [5]}
	//	u_log2 ('info', 'Preco unit gerado           : ' + cvaltochar (_aRetPrc [1]) + '  ' + _aRetPrc [2])
	//	u_log2 ('info', 'Preco total gerado          : ' + cvaltochar ((_sAliasQ) -> peso_liq * _aRetPrc [1]))
	//	u_log2 ('info', 'Preco total efetivo ateh o momento: ' + cvaltochar ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo))
		_nVCompl = ((_sAliasQ) -> peso_liq * _aRetPrc [1]) - ((_sAliasQ) -> peso_liq * (_sAliasQ) -> VUnit_efetivo)
	//	u_log2 ('info', 'Valor total complemento     : ' + cvaltochar (_nVCompl))

		// Implementei este paragrafo em 16/06/23, mas nao cheguei a testar
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery = "SELECT dbo.VA_FTIPO_FORNECEDOR_UVA ('" + (_sAliasQ) -> associado + "', '" + (_sAliasQ) -> loja_assoc + "', '" + mv_par05 + "0331')" // situacao ao final da safra	
		_sTpForn = alltrim (left (_oSQL:RetQry (1, .f.), 1))
		if empty (_sTpForn)
			u_help ("Tipo fornecedor de uva indefinido (forn/loja " + (_sAliasQ) -> associado + "/" + (_sAliasQ) -> loja_assoc,, .t.)
		endif

		// Gera proxima pre-nf livre
		_sQuery := " select max (ZZ9_PRE_NF)"
		_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
		_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
		_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + (_sAliasQ) -> FILIAL + "'"
		_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
		_sPreNF = _IncPreNF (U_RetSQL (_sQuery))

		reclock ("ZZ9", .T.)
		zz9 -> zz9_filial = (_sAliasQ) -> FILIAL
		zz9 -> zz9_safra  = mv_par05
		zz9 -> zz9_grupo  = (_sAliasQ) -> grupo_PAGTO
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_fornec = (_sAliasQ) -> associado
		zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_tiponf = "C"  // N=Normal;C=Complemento
		zz9 -> zz9_produt = (_sAliasQ) -> produto
		zz9 -> zz9_grau   = (_sAliasQ) -> grau
		zz9 -> zz9_classe = (_sAliasQ) -> clas_final
		zz9 -> zz9_clabd  = (_sAliasQ) -> clas_abd
		zz9 -> zz9_conduc = (_sAliasQ) -> sist_conducao
		zz9 -> zz9_vunOld = (_sAliasQ) -> VUnit_efetivo
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_qtOri  = (_sAliasQ) -> peso_liq  // Campo util para relatorios posteriores
		zz9 -> zz9_vunit  = _nVCompl   // Valor total a complementar
		zz9 -> zz9_nfcomp = iif (zz9 -> zz9_vunit <= 0, 'VLR_MENOR', '')  // Para evitar que posteriormente o programa VA_GNF2 tente gerar nota para este registro.
		zz9 -> zz9_vunit2 = _aRetPrc [1]  // Preco unitario que foi usado para calcular o complemento
		zz9 -> zz9_obs    = _aRetPrc [2]  // Observacoes geradas pelo prog. de calculo do preco
		zz9 -> zz9_vunit3 = _aRetPrc [3]  // Preco unitario da tabela CONAB
		zz9 -> zz9_nfori  = (_sAliasQ) -> doc
		zz9 -> zz9_serior = (_sAliasQ) -> serie
		zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
		zz9 -> zz9_msgNF  = 'COMPL PRECO;' + _sMsgNF
	//	zz9 -> zz9_TES    = iif (_nVCompl <= 0, '', U_TESSafra (mv_par05, (_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, 'V'))
		zz9 -> zz9_TES    = U_TESSafra (mv_par05, (_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, 'V')
		zz9 -> zz9_dco    = ''
		if valtype (_oCarSaf) == 'O' .and. len (_oCarSaf:CCompart) > 0
			zz9 -> zz9_ccomp  = _oCarSaf:TodasComp ()
		endif
		zz9 -> zz9_TpForn = _sTpForn

		// Grava as possibilidades de misturas de variedades.
		_nCpoZZ9 = 1
		for _nAux = 1 to len (_aMenorVl)
			// Geralmente a 'variedade de menor valor' eh a propria variedade
			// da contranota original, entao nem preciso gravar.
			if _aMenorVl [_nAux, 1] != (_sAliasQ) -> produto
				zz9 -> &('zz9_mistu' + cvaltochar (_nCpoZZ9)) = _aMenorVl [_nAux, 1]
				_nCpoZZ9 ++
			endif
		next
		
		msunlock ()
		(_sAliasQ) -> (dbskip ())
	enddo

	u_help ("Processo concluido.")
return


// --------------------------------------------------------------------------
static function _Clona (_nValor)
	local _nRegZZ9 := zz9 -> (recno ())
	local _nCampo  := 0
	local _aRegOri := {}
	local _sPreOri := zz9 -> zz9_pre_nf
	local _sPreNF  := ""

	// Gera proxima pre-nf livre
	_sQuery := " select max (ZZ9_PRE_NF)"
	_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9  "
	_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_sQuery +=   " and ZZ9.ZZ9_FILIAL = '" + xfilial ("ZZ9")  + "'"
	_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	_sPreNF = U_RetSQL (_sQuery)
	_sPreNF = soma1 (soma1 (soma1 (soma1 (soma1 (_sPreNF)))))

	for _nCampo = 1 to zz9 -> (fcount ())
		aadd (_aRegOri, zz9 -> (fieldget (_nCampo)))
	next
	reclock ("ZZ9", .t.)
	for _nCampo = 1 to zz9 -> (fcount ())
		zz9 -> (fieldput (_nCampo, _aRegOri [_nCampo]))
		zz9 -> zz9_pre_nf = _sPreNF
		zz9 -> zz9_parcel = mv_par06
		zz9 -> zz9_regori = _nRegZZ9
		zz9 -> zz9_QTUSAD = 0
		zz9 -> zz9_quant  = 0
		zz9 -> zz9_VUnit  = _nValor
		zz9 -> zz9_NFComp = ''
		zz9 -> zz9_SerCom = ''
		zz9 -> zz9_tiponf = "C"
		zz9 -> zz9_preori = _sPreOri
		zz9 -> zz9_obs    = 'COMPL.REF.CLASSIF.DESCONS.'
	next
	msunlock ()
	zz9 -> (dbgoto (_nRegZZ9))
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},             "Codigo do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "   ", {},             "Loja do produtor (fornecedor) inicial para geracao das notas."})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},             "Codigo do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "   ", {},             "Loja do produtor (fornecedor) final para geracao das notas."})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},             "Safra (ano) para a qual serao geradas as notas de compra."})
	aadd (_aRegsPerg, {06, "Gerar em qual parcela?        ", "C", 1,  0,  "",   "   ", {},             "Numero da parcela de pagto. onde os complementos serao gerados."})
	aadd (_aRegsPerg, {07, "DCO inicial                   ", "C", 13, 0,  "",   "ZZ8", {},             ""})
	aadd (_aRegsPerg, {08, "DCO final                     ", "C", 13, 0,  "",   "ZZ8", {},             ""})
	aadd (_aRegsPerg, {09, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {10, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},             ""})
	aadd (_aRegsPerg, {11, "Preco total (safra 2016)      ", "N", 10, 4,  "",   "",    {},             ""})
	aadd (_aRegsPerg, {12, "Apenas varied (separ.por /)   ", "C", 60, 0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {13, "Exceto varied (separ.por /)   ", "C", 60, 0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {14, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},             ""})
	aadd (_aRegsPerg, {15, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},             ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
