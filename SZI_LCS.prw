// Programa:   SZI_LCS
// Autor:      Robert Koch
// Data:       12/09/2012
// Descricao:  Relatorio de lancamentos com saldo na conta corrente de associados.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Relatorio de lancamentos na conta corrente de associados com saldo em aberto na data informada.
// #PalavasChave      #conta_corrente_associados #lancamentos_com_saldo
// #TabelasPrincipais #SZI #SE2
// #Modulos           #COOP

// Historico de alteracoes:
// 08/10/2012 - Robert - Incluido parametro de forma de pagamento.
//                     - Incluido parametro de listar debitos / creditos / ambos.
// 15/10/2012 - Robert - Passa a listar (-) quando valores a debito.
// 18/10/2012 - Robert - Ordenacao por nome do associado.
//                     - Possibilidade de geracao de recibos no final.
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 25/04/2016 - Robert - Criada opcao de filtragem por parcela.
// 16/08/2016 - Robert - Ordenacao por TM dava erro no ORDER BY da query.
// 04/09/2017 - Robert - Filtro por nucleo nao funcionava quando deixado em branco.
//                     - Soh compoe o saldo quando data != date ()
// 19/11/2018 - Robert - Filtro de nucleo passa a validar objeto da classe ClsAssoc e nao mais campo A2_VANUCL
// 23/11/2020 - Robert - Criada opcao de listar com saldo/sem saldo/todos
//                     - Inserida coluna com o valor original.
//                     - Nao chama mais impressao de recibos (em desuso, pois agora deposita-se em conta).
// 05/05/2021 - Robert - Renomeado campo R_E_C_N_O_ para RegSZI na query por exigencia da classe FWTemporaryTable implementada na ClsAssoc (GLPI 9973).
//

// --------------------------------------------------------------------------
user function SZI_LCS (_lAutomat, _nOrdem)
	private _lAuto     := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
//	private _aRecibos  := {}

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Saldos lctos conta corrente associados"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SZI"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "SZI_LCS"
	nomeprog := "SZI_LCS"
	wnrel    := "SZI_LCS"
	tamanho  := "G"
	limite   := 132
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {"Por codigo associado + filial", "Por tipo de movimento + filial", "Por nome associado + filial"}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
//		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString, ;  // Alias
		wnrel, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg, ;  // Parametros
		@titulo, ;  // Titulo do relatorio
		cDesc1, ;  // Descricao 1
		cDesc2, ;  // Descricao 2
		cDesc3, ;  // Descricao 3
		.F., ;  // .T. = usa dicionario
		aOrd, ;  // Array de ordenacoes para o usuario selecionar
		.T., ;  // .T. = comprimido
		tamanho, ;  // P/M/G
		NIL, ;  // Nao pude descobrir para que serve.
		.F., ;  // .T. = usa filtro
		NIL, ;  // lCrystal
		NIL, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T., ;  // .T. = NAO mostra interface para usuario
		.T., ;  // lServer
		NIL)    // cPortToPrint
		aReturn [8] = _nOrdem
	endif
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	
	processa ({|| _Imprime ()})
	MS_FLUSH ()
	DbCommitAll ()

	// Se era execucao via rotina automatica, converte o relatorio para TXT.
	if _lAuto
		_sErroConv = U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
		if ! empty (_sErroConv)
			u_help (cvaltochar (_sErroConv),, .t.)
		endif
	else
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif

//	// Utiliza a rotina de impressao de recibos genericos.
//	if mv_par16 == 1
//		if len (_aRecibos) == 0
//			u_help ("Nao ha recibos gerados.")
//		else
//			_aRecibos = asort (_aRecibos,,, {|_x, _y| _x [4] < _y [4]})
//			_oAUtil := ClsAUtil():New (_aRecibos)
//			u_help ("A seguir serao gerados os recibos, totalizando valor de " + cvaltochar (_oAUtil:TotCol (2)))
//			U_VA_RCB (_aRecibos)
//		endif
//	endif
return



// --------------------------------------------------------------------------
static function _Imprime ()
//	local _sQuery    := ""
	local _sArqTrb   := ""
	local _sQuebra   := ""
	local _xQuebra   := ""
	local _sNomeQbr  := ""
//	local _aObs      := {}
//	local _nObs      := 0
	local _sHist     := ""
	local _aHist     := {}
	local _nHist     := 0
	local _nTamHist  := 75 //45
	local _nTotGerV   := 0
	local _nTotGerS   := 0
	local _nSubTotV   := 0
	local _nSubTotS   := 0
//	local _aRecibo   := {}
	local _sNomAsso  := ""
	local _oAssoc    := NIL
	private _nMaxLin := 66
	li = _nMaxLin + 1

	procregua (3)

	// if mv_par16 == 1 .and. ! (aReturn [8] == 1 .or. aReturn [8] == 3)  // Por associado (nome ou codigo, tanto faz) + filial
	// 	u_help ("Geracao de recibos so' deve ser usada quando o relatorio for ordenado por associado.",, .t.)
	// 	return
	// endif

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.",, .t.)
		return
	EndIf	

	// Define titulo e cabecalhos
	titulo += " - posicao em " + dtoc (mv_par07)
	do case
	case aReturn [8] == 1 .or. aReturn [8] == 2 .or. aReturn [8] == 3
		cCabec1 = "Filial         Data        Titulo           Associado                          Historico                                                                      Valor orig.               Saldo"
	otherwise
		u_help ('Ordenacao sem tratamento na geracao de cabecalhos.',, .t.)
	endcase

	procregua (10)
	incproc ("Lendo dados...")


	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	
	// Busca conta corrente
	_oSQL:_sQuery += "SELECT SZI.R_E_C_N_O_ AS REGSZI,"
	_oSQL:_sQuery +=       " ZI_FILIAL, M0_FILIAL,"
	_oSQL:_sQuery +=       " ZI_TM, ZI_ASSOC, ZI_LOJASSO, ZI_HISTOR, ZI_DATA, ZI_SERIE, ZI_DOC, ZI_CODMEMO, ZI_PARCELA,"
	_oSQL:_sQuery +=       " A2_NOME, ZX5_10DESC, ZX5_10DC,"
	_oSQL:_sQuery +=       " ZI_SALDO AS SALDO,"
	_oSQL:_sQuery +=       " ZI_VALOR AS VALOR"
	_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
	_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5, "
	_oSQL:_sQuery +=             RETSQLNAME ("SA2") + " SA2, "
	_oSQL:_sQuery +=         "VA_SM0 SM0 "
	_oSQL:_sQuery += " WHERE SA2.A2_COD      = SZI.ZI_ASSOC"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = SZI.ZI_LOJASSO"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
	_oSQL:_sQuery +=   " AND SM0.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SM0.M0_CODIGO   = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=   " AND SM0.M0_CODFIL   = SZI.ZI_FILIAL"
	_oSQL:_sQuery +=   " AND ZX5.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = SZI.ZI_TM"
	if mv_par12 == 1
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10DC = 'D'"
	elseif mv_par12 == 2
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10DC = 'C'"
	endif
	_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC  + SZI.ZI_LOJASSO  BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_TM       NOT IN " + FormatIn (alltrim (mv_par13), '/')
	_oSQL:_sQuery +=   " AND SZI.ZI_DATA     <= '" + dtos (mv_par07) + "'"
	if ! empty (mv_par11)
		_oSQL:_sQuery += " AND SZI.ZI_FORMPAG  = '" + mv_par11 + "'"
	endif
	if ! empty (mv_par08)
		_oSQL:_sQuery +=     " AND SA2.A2_VACORIG IN " + FormatIn (alltrim (mv_par08), '/')
	endif
	if ! empty (mv_par14)
		_oSQL:_sQuery += " AND SZI.ZI_PARCELA IN " + FormatIn (alltrim (mv_par14), '/')
	endif
	do case
	case aReturn [8] == 1 .or. aReturn [8] == 3
		// Ordenacao por varios campos por que, do contrario, a cada vez o relatorio traz uma nova ordenacao e fica dificil fazer comparativos...
		_oSQL:_sQuery += " ORDER BY " + iif (aReturn [8] == 3, "ZI_NOMASSO,", "") + "ZI_ASSOC, ZI_LOJASSO, ZI_DATA, ZI_TM, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
	case aReturn [8] == 2
		_oSQL:_sQuery += " ORDER BY ZI_TM, ZI_ASSOC, ZI_LOJASSO, ZI_DATA, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
	otherwise
		u_help ('Ordenacao sem tratamento na query.',, .t.)
	endcase
	//_oSQL:Log ()

	_sArqTrb = _oSQL:Copy2Trb ()


	// Filtra nucleos.
	if ! empty (mv_par20)
		procregua ((_sArqTrb) -> (reccount ()))
		(_sArqTrb) -> (dbgotop ())
		do while ! (_sArqTrb) -> (eof ())
			incproc ('Filtrando nucleos')
			_oAssoc := ClsAssoc ():New ((_sArqTrb) -> zi_assoc, (_sArqTrb) -> zi_lojasso, .T.)
			if ! _oAssoc:Nucleo $ mv_par20
				//u_log ('Assoc', (_sArqTrb) -> zi_assoc + "/" + (_sArqTrb) -> zi_lojasso, 'pertence ao nucleo', _oAssoc:Nucleo)
				reclock ((_sArqTrb), .F.)
				(_sArqTrb) -> (dbdelete ())
				msunlock ()
			endif
			(_sArqTrb) -> (dbskip ())
		enddo
	endif


	// Verifica o saldo dos lancamentos e monta arquivo apenas com os que interessam.
	procregua ((_sArqTrb) -> (reccount ()))
	(_sArqTrb) -> (dbgotop ())
	do while ! (_sArqTrb) -> (eof ())
		incproc ('Verificando saldos')

		// Se for data diferente da atual, calcula o saldo.
		if mv_par07 != date ()
			// _oCtaCorr := ClsCtaCorr():New ((_sArqTrb) -> R_E_C_N_O_)
			_oCtaCorr := ClsCtaCorr():New ((_sArqTrb) -> RegSZI)
			_nSaldo = _oCtaCorr:SaldoEm (mv_par07)
		else
			_nSaldo = (_sArqTrb) -> saldo
		endif

/*
		reclock ((_sArqTrb), .F.)
		if _nSaldo == 0
			(_sArqTrb) -> (dbdelete ())
		else
			(_sArqTrb) -> saldo = _nSaldo
		endif
		msunlock ()
*/
		reclock ((_sArqTrb), .F.)
		(_sArqTrb) -> saldo = _nSaldo

		if mv_par15 == 1 .and. _nSaldo == 0
			(_sArqTrb) -> (dbdelete ())
		endif
		if mv_par15 == 2 .and. _nSaldo != 0
			(_sArqTrb) -> (dbdelete ())
		endif

		msunlock ()

		(_sArqTrb) -> (dbskip ())
	enddo

	_nTotGerV = 0
	_nTotGerS = 0
	(_sArqTrb) -> (dbgotop ())
	do while ! (_sArqTrb) -> (eof ())
		incproc ('Imprimindo')

		if li > _nMaxLin - 6
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		
		// Define criterio de quebra conforme ordenacao selecionada pelo usuario e imprime cabecalho da quebra.
		do case
		case aReturn [8] == 1 .or. aReturn [8] == 3  // Por associado (nome ou codigo, tanto faz) + filial
			_sQuebra  = "ZI_ASSOC + '/' + ZI_LOJASSO"
			_xQuebra = (_sArqTrb) -> &(_sQuebra)
			_sNomeQbr = (_sArqTrb) -> a2_nome
			_sNomAsso = (_sArqTrb) -> a2_nome
			@ li, 0 psay "Associado: " + _xQuebra + ' - ' + _sNomeQbr
			li += 2
		case aReturn [8] == 2  // Por tipo de movimento + filial
			_sQuebra = "ZI_TM"
			_xQuebra = (_sArqTrb) -> &(_sQuebra)
			_sNomeQbr = (_sArqTrb) -> zx5_10desc
			@ li, 0 psay "Tipo de movimento: " + _xQuebra + ' - ' + _sNomeQbr
			li += 2
		otherwise
			u_help ('Ordenacao sem tratamento na definicao de quebras.',, .t.)
		endcase
	
		// Controla quebra
		_nSubTotV = 0
		_nSubTotS = 0
		do while ! (_sArqTrb) -> (eof ()) .and. (_sArqTrb) -> &(_sQuebra) == _xQuebra
			incproc ()

			_sHist = alltrim ((_sArqTrb) -> zi_histor)

			// Quebra o historico em quantas linhas forem necessarias (pelo menos uma).
			_aHist = U_QuebraTXT (_sHist, _nTamHist)
			if len (_aHist) == 0
				aadd (_aHist, "")
			endif

			// Monta linha para impressao
			_sLinImp = ""
			_sLinImp += U_TamFixo ((_sArqTrb) -> m0_filial, 13) + "  "
			_sLinImp += U_TamFixo (dtoc ((_sArqTrb) -> zi_data), 10) + "  "
			_sLinImp += (_sArqTrb) -> zi_serie + '/' + (_sArqTrb) -> zi_doc + '-' + (_sArqTrb) -> zi_parcela + '  '
			do case
			case aReturn [8] == 1 .or. aReturn [8] == 3  // Por associado
				_sLinImp += U_TamFixo ((_sArqTrb) -> zi_tm + "-" + (_sArqTrb) -> zx5_10desc, 33) + "  "
			case aReturn [8] == 2  // Por tipo de movimento
				_sLinImp += U_TamFixo ((_sArqTrb) -> zi_assoc + "/" + (_sArqTrb) -> zi_lojasso + " " + (_sArqTrb) -> a2_nome, 32) + "   "
			otherwise
				u_help ('Ordenacao sem tratamento na impressao.',, .t.)
			endcase
			
			// Primeira linha do historico
			_sLinImp += U_TamFixo (_aHist [1], _nTamHist) + " "
			
			_sLinImp += transform ((_sArqTrb) -> valor, "@E 999,999,999.99")
			_sLinImp += iif ((_sArqTrb) -> ZX5_10DC == 'D', '(-)', '   ') + '   '
			_sLinImp += transform ((_sArqTrb) -> saldo, "@E 999,999,999.99")
			_sLinImp += iif ((_sArqTrb) -> ZX5_10DC == 'D', '(-)', '   ')

			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay _sLinImp
			li ++
			_nSubTotV += (_sArqTrb) -> valor * iif ((_sArqTrb) -> ZX5_10DC == 'D', -1, 1)
			_nSubTotS += (_sArqTrb) -> saldo * iif ((_sArqTrb) -> ZX5_10DC == 'D', -1, 1)
			_nTotGerV += (_sArqTrb) -> valor * iif ((_sArqTrb) -> ZX5_10DC == 'D', -1, 1)
			_nTotGerS += (_sArqTrb) -> saldo * iif ((_sArqTrb) -> ZX5_10DC == 'D', -1, 1)

			// Imprime as linhas restantes do historico.
			for _nHist = 2 to len (_aHist)
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 69 psay _aHist [_nHist]
				li ++
			next

			(_sArqTrb) -> (dbskip ())
		enddo
		@ li, 155 psay '--------------      --------------'
		li ++
		_sLinImp := 'Subtotais: '
		_sLinImp += transform (_nSubTotV, "@E 999,999,999.99") + iif (_nSubTotV < 0, '(-)', '   ') + '   '
		_sLinImp += transform (_nSubTotS, "@E 999,999,999.99") + iif (_nSubTotS < 0, '(-)', '   ')
		@ li, 144 psay _sLinImp
		li ++

		if li > _nMaxLin - 3
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay __PrtThinLine ()
		li += 1

		// // Prepara dados para posterior geracao de recibos.
		// if mv_par16 == 1
		// 	_aRecibo = {}
		// 	aadd (_aRecibo, sm0 -> m0_nomecom)
		// 	aadd (_aRecibo, _nSubTotS)
		// 	aadd (_aRecibo, mv_par17)
		// 	aadd (_aRecibo, _sNomAsso)
		// 	aadd (_aRecibo, '')
		// 	aadd (_aRecibo, mv_par18)
		// 	aadd (_aRecibo, mv_par19)
		// 	aadd (_aRecibo, 1)
		// 	aadd (_aRecibo, 1)
		// 	aadd (_aRecibos, aclone (_aRecibo))
		// endif
		
		if aReturn [8] == 3
			li = _nMaxLin + 1
		endif

	enddo
	(_sArqTrb) -> (dbclosearea ())
	@ li, 155 psay '--------------      --------------'
	li ++
//	@ li, 140 psay 'Totais gerais: ' + iif (_nTotGerV < 0, '(-)', '   ') + transform (_nTotGerV, "@E 999,999,999.99") + '  ' + iif (_nTotGerS < 0, '(-)', '   ') + transform (_nTotGerS, "@E 999,999,999.99")
	_sLinImp := 'Totais gerais: '
	_sLinImp += transform (_nTotGerV, "@E 999,999,999.99") + iif (_nTotGerV < 0, '(-)', '   ') + '   '
	_sLinImp += transform (_nTotGerS, "@E 999,999,999.99") + iif (_nTotGerS < 0, '(-)', '   ')
	@ li, 140 psay _sLinImp
	li ++

	// Imprime parametros usados na geracao do relatorio
	if li > _nMaxLin - 2
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	U_ImpParam (_nMaxLin)

return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                              Help
	aadd (_aRegsPerg, {01, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},                                 ""})
	aadd (_aRegsPerg, {02, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {03, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},                                 ""})
	aadd (_aRegsPerg, {04, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {05, "Tipo de movimento inicial     ", "C", 2,  0,  "",   "ZX510 ", {},                                 ""})
	aadd (_aRegsPerg, {06, "Tipo de movimento final       ", "C", 2,  0,  "",   "ZX510 ", {},                                 ""})
	aadd (_aRegsPerg, {07, "Posicao em                    ", "D", 8,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {08, "Coop.orig(AL/SV/...) bco=todas", "C", 18, 0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {09, "Filial inicial                ", "C", 2,  0,  "",   "SM0   ", {},                                 ""})
	aadd (_aRegsPerg, {10, "Filial final                  ", "C", 2,  0,  "",   "SM0   ", {},                                 ""})
	aadd (_aRegsPerg, {11, "Forma pagamento (bco=todas)   ", "C", 1,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {12, "Movtos a debito ou a credido  ", "N", 1,  0,  "",   "      ", {"Debito", "Credito", "Todos"},     ""})
	aadd (_aRegsPerg, {13, "T.M. desconsiderar (separ. /) ", "C", 30, 0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {14, "Parcelas (separ. /) bco=todas ", "C", 60, 0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {15, "Quanto ao saldo               ", "N", 1,  0,  "",   "      ", {"Com saldo", "Sem saldo", "Todos"},""})
//	aadd (_aRegsPerg, {16, "Gerar recibos apos o relatorio", "N", 1,  0,  "",   "      ", {"Sim", "Nao"},                     ""})
//	aadd (_aRegsPerg, {17, "P/recibo: Correspondente a... ", "C", 50, 0,  "",   "      ", {},                                 ""})
//	aadd (_aRegsPerg, {18, "P/recibo: Local               ", "C", 25, 0,  "",   "      ", {},                                 ""})
//	aadd (_aRegsPerg, {19, "P/recibo: Data                ", "D", 8,  0,  "",   "      ", {},                                 ""})
//	aadd (_aRegsPerg, {20, "Nucleos(SG/FC/...) bco=todos  ", "C", 18, 0,  "",   "      ", {},                                 ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
