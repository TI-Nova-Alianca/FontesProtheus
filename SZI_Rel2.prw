// Programa:   SZI_Rel2                                                                    
// Autor:      Elaine Ballico - DWT
// Data:       15/05/2013
// Descricao:  Relatorio conta corrente associados buscando informacoes da tabela de saldos.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Impressao de relatorio extrato de conta corrente de associados modelo II
// #PalavasChave      #extrato #conta_corrente #associado #modelo #novo
// #TabelasPrincipais #SZI #SA2 #SE2 #SE5 #FK7 #FKA #FK2 #ZZM #ZX5
// #Modulos           #COOP

// Historico de alteracoes:
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 01/05/2019 - Robert - Passa a buscar dados na classe ClsExtrCC.
// 03/05/2019 - Robert - Nao mostrava totais gerais.
// 24/09/2019 - Robert - ClsExtrCC passa a ter novo atributo :FormaResult.
// 28/03/2022 - Robert - Eliminada funcionalidade de conversao para TXT (em alguns casos 'perdia' o relatorio).
// 04/08/2023 - Robert - Nao imprime mais o nucleo (tornou-se um metodo da classe e eu nao to a fim de alterar aqui)
// 14/05/2024 - Robert - Em caso de listar capital, verifica se os associados tem mais de um codigo/loja e mostra aviso em tela.
//

#Include "va_inclu.prw"

// --------------------------------------------------------------------------
user function SZI_Rel2 (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := " Conta corrente associados - mod. II "
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SZI"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "SZI_REL2"
	nomeprog := "SZI_Rel2"
	wnrel    := "SZI_Rel2"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {"Por codigo associado",  "Por nome associado"}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
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
		aReturn [8] = 1
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
	if !_lAuto
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
return

// --------------------------------------------------------------------------
static function _Imprime ()
	local _oSQL      := NIL
	local _aAssoc    := {}
	local _nAssoc    := 0
	local _nExtr     := 0
	local _sLinImp   := ""
	local _sHist     := ''
	local _aHist     := {}
	local _nHist     := 0
	local _nTamHist  := 99
	local _lContinua := .T.
	local _aSubTot   := {}
	local _aTotGer   := {}
	local _aDescriTM := {}
	local _nDescriTM := 0
	local _sDescriTM := ""
	local _oAssoc    := NIL
	local _aMaisDe1  := {}
	local _nMaisDe1  := 0
	local _aColsF3   := {}
	private _nMaxLin := 68
	li = _nMaxLin + 1

	u_logSX1 (cPerg)

	// Nao aceita filtro por que precisaria inserir na query.
	If _lContinua .and. !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.",, .t.)
		_lContinua = .F.
	EndIf	

	// Define titulo e cabecalhos
	cCabec1 = "Filial         Data         Prf/titulo-parc   Tipo de movimento             Historico                                                                                                   Debito        Credito          Saldo"

	procregua (10)
	incproc ("Lendo dados...")

	// Monta array com a lista dos associados a listar.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT ZI_ASSOC, ZI_LOJASSO, SA2.A2_NOME "
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
		_oSQL:_sQuery +=             RETSQLNAME ("SA2") + " SA2 "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
//		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC  + SZI.ZI_LOJASSO  BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC   BETWEEN '" + mv_par01 + "' AND '" + mv_par03 + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO BETWEEN '" + mv_par02 + "' AND '" + mv_par04 + "'"
		_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=   " AND SA2.A2_COD      = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=   " ORDER BY " + {"ZI_ASSOC, ZI_LOJASSO", "ZI_NOMASSO"} [aReturn [8]]
		_aAssoc := aclone (_oSQL:Qry2Array ())
		if len (_aAssoc) == 0
			u_help ("Nao foi encontrado nenhum associado no intervalo solicitado.")
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. mv_par07 == 2  // Listar movimentos 'de capital'
		incproc ("Verificando associados...")
		_aMaisDe1 = {}
		for _nAssoc = 1 to len (_aAssoc)
			_oAssoc := ClsAssoc ():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2], .T.)
			if ! empty (_oAssoc:Codigo)  // Se conseguiu instanciar o associado
				if len (_oAssoc:aCodigos) > 1
					for _nMaisDe1 = 1 to len (_oAssoc:aCodigos)

						// Se esta loja nao estiver na lista
						if ascan (_aAssoc, {|_aVal| _aVal [1] == _oAssoc:aCodigos [_nMaisDe1] .and. _aVal [2] == _oAssoc:aLojas [_nMaisDe1]}) == 0
							aadd (_aMaisDe1, {_oAssoc:aCodigos [_nMaisDe1], _oAssoc:aLojas [_nMaisDe1], _oAssoc:Nome})
						endif
					next
				endif
			endif
		next
		if len (_aMaisDe1) > 0
			_aColsF3 = {}
			aadd (_aColsF3, {1, 'Codigo', 60, ''})
			aadd (_aColsF3, {2, 'Loja',   30, ''})
			aadd (_aColsF3, {3, 'Nome',  180, ''})
			U_F3Array (_aMaisDe1, "Associados com mais de um codigo/loja.", _aColsF3, NIL, NIL, "Foram encontrados associados com mais de um codigo/loja.", "Lembre-se de gerar este relatorio para todos os codigos/lojas, a fim de obter o valor correto de capital.")
		endif
	endif

	// Monta array com a lista dos tipos de movimento e suas descricoes.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ZX5_10COD, ZX5_10DESC"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("ZX5")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZX5_FILIAL  = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_TABELA  = '10'"
		_aDescriTM := aclone (_oSQL:Qry2Array ())
//		u_log ('Tipos de mov:', _aDescriTM)
	endif

	_aTotGer = {0, 0, 0}
	procregua (len (_aAssoc))
	for _nAssoc = 1 to len (_aAssoc)
		incproc ()

		// Se nao conseguir instanciar o associado, nem adianta continuar.
		_oAssoc := ClsAssoc ():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2], .T.)
		if valtype (_oAssoc) != "O"
			loop
		endif

		_aSubTot = {0, 0, 0}
		// Gera extrato do associado
		_oExtr := ClsExtrCC ():New ()
		_oExtr:Cod_assoc = _aAssoc [_nAssoc, 1]
		_oExtr:Loja_assoc = _aAssoc [_nAssoc, 2]
		_oExtr:DataIni = mv_par05
		_oExtr:DataFim = mv_par06
		_oExtr:TMIni = ''
		_oExtr:TMFim = 'zz'
		_oExtr:LerObs = (mv_par08 == 1)
		_oExtr:LerComp3os = .t.
		_oExtr:TipoExtrato = iif (mv_par07 == 1, 'N', 'C')
		_oExtr:FormaResult = 'A'  // Quero o resultado em formato de array.
		_oExtr:Gera ()
//		u_log (_oExtr:Resultado)

		// Uma nova pagina para cada associado.
		if len (_oExtr:Resultado) > 0
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			@ li, 0 psay "Associado: " + _aAssoc [_nAssoc, 1] + "/" + _aAssoc [_nAssoc, 2] + ' - ' + _aAssoc [_nAssoc, 3] // + '    Nucleo: ' + _oAssoc:Nucleo
			li ++
		endif

		// Imprime possiveis mensagens de erro.
		if ! empty (_oExtr:UltMsg)
			@ li, 0 psay _oExtr:UltMsg
			li += 2
		endif

		// Varre a array do extrato e imprime seus dados.
		for _nExtr = 1 to len (_oExtr:Resultado)

			// Observacoes, se tiver, sao concatenadas com o historico.
			_sHist = alltrim (_oExtr:Resultado [_nExtr, .ExtrCCHist])
			if mv_par08 == 1 .and. ! empty (_oExtr:Resultado [_nExtr, .ExtrCCObs])
				_sHist += chr (13) + chr (10) + "Obs.:" + _oExtr:Resultado [_nExtr, .ExtrCCObs]
			endif

			// Quebra o historico em quantas linhas forem necessarias (pelo menos uma).
			_aHist = U_QuebraTXT (_sHist, _nTamHist)
			if len (_aHist) == 0
				aadd (_aHist, "")
			endif

			// Descricao do tipo de movimento
			_nDescriTM = ascan (_aDescriTM, {|_aVal| _aVal [1] == _oExtr:Resultado [_nExtr, .ExtrCCTM]})
			if _nDescriTM > 0
				_sDescriTM = _aDescriTM [_nDescriTM, 2]
			else
				_sDescriTM = ''
			endif

			// Monta linha para impressao
			if _nExtr == 1  // A primeira linha contem apenas o saldo anterior para inicio do relatorio.
				_sLinImp = ""
				_sLinImp += space (191) + "SALDO ANTERIOR:"
				_sLinImp += transform (_oExtr:Resultado [_nExtr, .ExtrCCSaldo], "@E 999,999,999.99")
			else 
				_sLinImp = ""
				_sLinImp += U_TamFixo (_oExtr:Resultado [_nExtr, .ExtrCCDescFil], 13) + "  "
				_sLinImp += U_TamFixo (dtoc (_oExtr:Resultado [_nExtr, .ExtrCCData]), 10) + "   "
				_sLinImp += U_TamFixo (_oExtr:Resultado [_nExtr, .ExtrCCPrefixo] + "/" + _oExtr:Resultado [_nExtr, .ExtrCCTitulo] + "-" + _oExtr:Resultado [_nExtr, .ExtrCCParcela], 15, ' ') + '   '
				_sLinImp += U_TamFixo (_oExtr:Resultado [_nExtr, .ExtrCCTM] + "-" + _sDescriTM, 28) + "  "
				_sLinImp += U_TamFixo (_aHist [1], _nTamHist) + " "  // Primeira linha do historico
				_sLinImp += transform (_oExtr:Resultado [_nExtr, .ExtrCCValorDebito], "@EZ 999,999,999.99") + ' '
				_sLinImp += transform (_oExtr:Resultado [_nExtr, .ExtrCCValorCredito], "@EZ 999,999,999.99") + ' '
				_sLinImp += transform (_oExtr:Resultado [_nExtr, .ExtrCCSaldo], "@E 999,999,999.99")
			endif

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay _sLinImp
			li ++

			// Imprime as linhas restantes do historico.
			for _nHist = 2 to len (_aHist)
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 76 psay _aHist [_nHist]
				li ++
			next

			// Acumula subtotais e totais.
			_aSubTot [1] += _oExtr:Resultado [_nExtr, .ExtrCCValorDebito]
			_aSubTot [2] += _oExtr:Resultado [_nExtr, .ExtrCCValorCredito]
			_aSubTot [3] := _oExtr:Resultado [_nExtr, .ExtrCCSaldo]  // Sempre o saldo final deste associado
			_aTotGer [1] += _oExtr:Resultado [_nExtr, .ExtrCCValorDebito]
			_aTotGer [2] += _oExtr:Resultado [_nExtr, .ExtrCCValorCredito]

			// Se for a primeira linha, significa que eh o saldo inicial. Vou deixar uma linha em branco.
			if _nExtr == 1
				li ++
			endif
		next

		// Acumula o saldo de todos os associados.
		_aTotGer [3] += _aSubTot [3]
		
		if li > _nMaxLin - 3
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		@ li, 0 psay space (176) + "--------------  -------------  -------------"
		li ++
		_sLinImp := space (119) + "Totais "
		_sLinImp += U_TamFixo (_oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + _oAssoc:Nome, 50, ' ')
		_sLinImp += transform (_aSubTot [1], "@E 999,999,999.99") + " " + transform (_aSubTot [2], "@E 999,999,999.99") + " " + transform (_aSubTot [3], "@E 999,999,999.99")
		@ li, 0 psay _sLinImp
		li += 2
		@ li, 0 psay __PrtThinLine ()
		li += 2
	next

	if li > _nMaxLin - 3
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	_sLinImp := space (160) + "TOTAIS GERAIS   "
	_sLinImp += transform (_aTotGer [1], "@E 999,999,999.99") + " " + transform (_aTotGer [2], "@E 999,999,999.99") + " " + transform (_aTotGer [3], "@E 999,999,999.99")
	@ li, 0 psay _sLinImp
	li += 2
	@ li, 0 psay __PrtThinLine ()
	li += 2

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
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {02, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {03, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})
	aadd (_aRegsPerg, {04, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {05, "Data digitacao inicial        ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {06, "Data digitacao final          ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {07, "Tipo de conta corrente        ", "N", 1,  0,  "",   "      ", {"Normal", "Capital social"},        ""})
	aadd (_aRegsPerg, {08, "Listar observacoes            ", "N", 1,  0,  "",   "      ", {"Sim", "Nao"},                      ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
