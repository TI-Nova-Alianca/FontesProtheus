// Programa:   VA_SZFR
// Autor:      Robert Koch
// Data:       28/01/2010
// Descricao:  Relatorio recebimentos de uva safra.
//
// Historico de alteracoes:
// 15/02/2010 - Robert - Melhoradas quebras de pagina.
// 30/03/2010 - Robert - Lista total por grau no final do relatorio.
// 07/01/2011 - Robert - Ajuste tamanho parametro local de entrega.
// 04/03/2011 - Robert - Nao amarrava campo ZE_SAFRA com ZF_SAFRA.
// 22/03/2011 - Robert - Incluidos parametros de produto de...ate.
// 05/04/2011 - Robert - Incluidos parametros de coop.origem de...ate.
// 02/05/2011 - Robert - Incluidos parametros de filial de...ate.
// 09/02/2012 - Robert - Considerava em duplicidade as cargas aglutinadas.
// 13/12/2012 - Elaine - Ajuste para mostrar separadamente cargas/produtos de filiais diferentes
// 10/03/2016 - Robert - Reduzidos parametros da SetPrint quando usada interface com usuario.
// 31/03/2017 - Robert - Tratamento para validar cargas devolvidas.
// 15/03/2018 - Robert - Tratamento para desconsiderar cargas direcionadas para outra filial ou canceladas.
// 28/03/2022 - Robert - Eliminada funcionalidade de conversao para TXT (em alguns casos 'perdia' o relatorio).
//

// --------------------------------------------------------------------------
user function VA_SZFR (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	u_logId ()

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Cargas recebidas durante a safra"
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SZF"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "VASZFR"
	nomeprog := "VA_SZFR"
	wnrel    := "VA_SZFR"
	tamanho  := "M"
	limite   := 132
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
//		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
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

	if ! _lAuto
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
return



// --------------------------------------------------------------------------
static function _Imprime ()
	local _sQuery    := ""
	local _sAliasQ   := ""
	private _nMaxLin   := 77
	li = _nMaxLin + 1

	procregua (3)

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	procregua (10)
	incproc ("Lendo dados...")
                                                 

	_sQuery := ""
	_sQuery += "WITH CTE AS ("
	_sQuery += "SELECT SZF.*, B1_DESC,  ZE_FILIAL, ZE_COOP, ZE_LOJCOOP, SA2.A2_NOME, ZE_ASSOC, ZE_LOJASSO, ZE_NOMASSO, ZE_CARGA, ZE_DATA, ZE_HORA, "
	_sQuery +=       " ZE_NFPROD, ZE_PLACA, ZE_PESOBRU, ZE_PESOTAR, ZE_NFGER, ZE_LOCAL, A2_VACORIG, ZE_NFDEVOL"
	_sQuery +=  " FROM " + RETSQLNAME ("SZF") + " SZF, "
	_sQuery +=             RETSQLNAME ("SB1") + " SB1, "
	_sQuery +=             RETSQLNAME ("SZE") + " SZE "
	_sQuery +=  " LEFT JOIN " + RETSQLNAME ("SA2") + " SA2 "
	_sQuery +=         " ON (SA2.D_E_L_E_T_ != '*'"
	_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2")  + "'"
	_sQuery +=        " AND SA2.A2_COD     = SZE.ZE_ASSOC"
	_sQuery +=        " AND SA2.A2_LOJA    = SZE.ZE_LOJASSO)"
	_sQuery += " WHERE SB1.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SB1.B1_FILIAL   = '" + xfilial ("SB1")  + "'"
	_sQuery +=   " AND SB1.B1_COD      = SZF.ZF_PRODUTO"
	_sQuery +=   " AND SZF.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SZF.ZF_FILIAL   BETWEEN '" + mv_par19 + "' AND '" + mv_par20 + "'"
	_sQuery +=   " AND SZF.ZF_CARGA    = SZE.ZE_CARGA"
	_sQuery +=   " AND SZF.ZF_SAFRA    = SZE.ZE_SAFRA"
	_sQuery +=   " AND SZE.ZE_AGLUTIN != 'O'"  // Peso das cargas de origem seriam somados novamente na carga destino.
	_sQuery +=   " AND SZE.ZE_STATUS  != 'D'"  // Redirecionada
	_sQuery +=   " AND SZE.ZE_STATUS  != 'C'"  // Cancelada
	_sQuery +=   " AND SZE.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SZE.ZE_FILIAL   = ZF_FILIAL"
	_sQuery +=   " AND SZF.ZF_PRODUTO  BETWEEN '" + mv_par15 + "' AND '" + mv_par16 + "'"
	_sQuery +=   " AND SZE.ZE_LOCAL    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery +=   " AND SZE.ZE_COOP   + SZE.ZE_LOJCOOP  BETWEEN '" + mv_par05 + mv_par06 + "' AND '" + mv_par07 + mv_par08 + "'"
	_sQuery +=   " AND SZE.ZE_ASSOC  + SZE.ZE_LOJASSO  BETWEEN '" + mv_par09 + mv_par10 + "' AND '" + mv_par11 + mv_par12 + "'"
	_sQuery +=   " AND SZE.ZE_DATA     BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	if mv_par21 == 1
		_sQuery +=   " AND SZE.ZE_NFDEVOL = ''"
	else
		_sQuery +=   " AND SZE.ZE_NFDEVOL != ''"
	endif
	_sQuery += ") SELECT * FROM CTE"
	_sQuery += " WHERE A2_VACORIG BETWEEN '" + mv_par17 + "' AND '" + mv_par18 + "'"
	_sQuery += " ORDER BY ZF_SAFRA, ZE_FILIAL, ZE_COOP, ZE_LOJCOOP, ZE_ASSOC, ZE_LOJASSO, ZE_NOMASSO, ZE_CARGA, ZF_PRODUTO"
	u_log (_squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "ZE_DATA", "D")
	
	procregua ((_sAliasQ) -> (reccount ()))
	_aTotGeral = {}
	_aTotGrau  = {}
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		incproc ()

		// Nova pagina a cada safra
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				
		// Controla quebra por safra
		_sSafra = (_sAliasQ) -> zf_safra
		_aTotSafra = {}
		@ li, 0 psay padc ("-----------------", limite, " ")
		li ++
		@ li, 0 psay padc ("S A F R A :  " + _sSafra, limite, " ")
		li ++
		@ li, 0 psay padc ("-----------------", limite, " ")
		li += 2
		do while ! (_sAliasQ) -> (eof ()) ;
			.and. (_sAliasQ) -> zf_safra == _sSafra
		
			if li > _nMaxLin - 8
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
                                                                              

			// Controla quebra por filial
			_sFilial = (_sAliasQ) -> zf_filial                             
			_sNomFilial = fBuscaCpo ("SM0", 1, cEmpAnt + _sFilial,  "M0_FILIAL")
			_aTotFil = {}
			@ li, 0 psay "Filial: " + _sFilial + " - " + _sNomFilial
			li += 2
			do while ! (_sAliasQ) -> (eof ()) ;
				.and. (_sAliasQ) -> zf_safra   == _sSafra ;
				.and. (_sAliasQ) -> zf_filial  == _sFilial

				if li > _nMaxLin - 6
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif

				// Controla quebra por associado. O nome participa da chave por que eventuais associados
				// de outras cooperativas, ainda nao cadastrados aqui, entram com codigo generico.
				_sAssoc = (_sAliasQ) -> ze_assoc
				_sLojAssoc = (_sAliasQ) -> ze_lojasso
				_sNomAssoc = (_sAliasQ) -> ze_nomasso
				_aTotAssoc = {}
				if mv_par13 == 2  // Detalhado
					@ li, 0 psay "  Associado: " + _sAssoc + "/" + _sLojAssoc + " - " + _sNomAssoc
					li += 2
				endif
				do while ! (_sAliasQ) -> (eof ()) ;
					.and. (_sAliasQ) -> zf_safra   == _sSafra ;
					.and. (_sAliasQ) -> zf_filial  == _sFilial ;
					.and. (_sAliasQ) -> ze_assoc   == _sAssoc ;
					.and. (_sAliasQ) -> ze_lojasso == _sLojAssoc ;
					.and. (_sAliasQ) -> ze_nomasso == _sNomAssoc

					if li > _nMaxLin - 4
						cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
					endif

					// Controla quebra por carga
					_sCarga = (_sAliasQ) -> ze_carga
					if mv_par13 == 2  // Detalhado
						@ li, 0 psay "            Carga: " + _sCarga + "        Data...........: " + dtoc ((_sAliasQ) -> ze_data) + "            Peso bruto...: " + transform ((_sAliasQ) -> ze_pesobru, "@E 999,999,999") + " Kg        Contranota...: " + (_sAliasQ) -> ze_nfger
						li ++
						@ li, 0 psay "            " + iif (! empty ((_sAliasQ) -> ZE_NFDEVOL), "*** DEVOLVIDA ***", space (17)) + "  NF produtor....: " + (_sAliasQ) -> ze_nfprod + "             Peso tara....: " + transform ((_sAliasQ) -> ze_pesotar, "@E 999,999,999") + " Kg        Local entrega: " + (_sAliasQ) -> ze_local
						li ++
						@ li, 0 psay "            " + iif (! empty ((_sAliasQ) -> ZE_NFDEVOL), "NF Dev.:" + (_sAliasQ) -> ZE_NFDEVOL, space (17)) + "  Placa veiculo..: " + (_sAliasQ) -> ze_placa + "               Peso liquido.: " + transform ((_sAliasQ) -> ze_pesobru - (_sAliasQ) -> ze_pesotar, "@E 999,999,999") + " Kg"
						li += 2
						if li > _nMaxLin - 2
							cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
						endif
						@ li, 0 psay "                                         Produto                                                Embalagem       Peso Kg  Grau  Clas."
						li ++
						@ li, 0 psay "                                         -------------------------------------------------------------------------------------------"
						li ++
					endif
					do while ! (_sAliasQ) -> (eof ()) ;
						.and. (_sAliasQ) -> zf_safra   == _sSafra ;
						.and. (_sAliasQ) -> zf_filial  == _sFilial ;
						.and. (_sAliasQ) -> ze_assoc   == _sAssoc ;
						.and. (_sAliasQ) -> ze_lojasso == _sLojAssoc ;
						.and. (_sAliasQ) -> ze_nomasso == _sNomAssoc ;
						.and. (_sAliasQ) -> ze_carga   == _sCarga

						if mv_par13 == 2  // Detalhado
							if li > _nMaxLin
								cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
							endif
	
							_sLinImp := "                                         "
							_sLinImp += u_tamfixo (alltrim ((_sAliasQ) -> zf_produto) + " - " + (_sAliasQ) -> b1_desc, 50) + " "
							_sLinImp += transform ((_sAliasQ) -> zf_qtembal, "@E 99,999") + " "
							_sLinImp += u_tamfixo ((_sAliasQ) -> zf_embalag, 8) + " "
							_sLinImp += transform ((_sAliasQ) -> zf_peso, "@E 999,999,999") + "   "
							_sLinImp += (_sAliasQ) -> zf_grau + "    "
							_sLinImp += (_sAliasQ) -> zf_prm99
							@ li, 0 psay _sLinImp
							li ++
						endif
						
						// Acumula totais
						_Acumula (@_aTotAssoc, (_sAliasQ) -> zf_safra, (_sAliasQ) -> zf_filial, (_sAliasQ) -> ze_assoc, (_sAliasQ) -> ze_lojasso, (_sAliasQ) -> zf_produto, (_sAliasQ) -> b1_desc, (_sAliasQ) -> zf_peso, (_sAliasQ) -> zf_grau, (_sAliasQ) -> zf_prm99, "")
						_Acumula (@_aTotFil ,  (_sAliasQ) -> zf_safra, (_sAliasQ) -> zf_filial, "",                     "",                       (_sAliasQ) -> zf_produto, (_sAliasQ) -> b1_desc, (_sAliasQ) -> zf_peso, "",                    "",                     "")
						_Acumula (@_aTotGeral, ""                    ,  ""                  ,   "",                     "",                       (_sAliasQ) -> zf_produto, (_sAliasQ) -> b1_desc, (_sAliasQ) -> zf_peso, "",                    "",                     "")
						_Acumula (@_aTotGrau,  ""                    ,  ""                  ,   "",                     "",                       (_sAliasQ) -> zf_produto, (_sAliasQ) -> b1_desc, (_sAliasQ) -> zf_peso, (_sAliasQ) -> zf_grau, "",                     "")

						(_sAliasQ) -> (dbskip ())
					enddo
					if mv_par13 == 2
						li += 2
					endif
				enddo
				@ li, 2 psay replicate ("_", 130)
				li ++
				if li > _nMaxLin - 2
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 0 psay "  Totais " + U_TamFixo (_sAssoc + "-" + alltrim (_sNomAssoc), 30)
				_ImpTot (_aTotAssoc)
				li ++
				if mv_par13 == 2
					@ li, 0 psay __PrtThinLine ()
					li ++
				endif
			enddo
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay "Totais " + U_TamFixo (alltrim (_sNomFilial), 30)
			_ImpTot (_aTotFil)
			li ++
			@ li, 0 psay __PrtFatLine ()
			li ++
		enddo
		if li > _nMaxLin - 2
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
	enddo
	if li > _nMaxLin - 2
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	@ li, 0 psay "Totais gerais"
	_ImpTot (_aTotGeral)
	li ++
	@ li, 0 psay "Obs.: Este relatorio lista cargas recebidas na balanca e nao necessariamente reflete as contranotas emitidas, pois"
	li ++
	@ li, 0 psay "      podem existir cargas para as quais ainda nao foram emitidas as contranotas."
	li += 2

	if mv_par14 == 1
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		@ li, 0 psay "Totais gerais por variedade + grau       Produto                                                                Peso Kg  Grau"
		li ++
		@ li, 0 psay "                                         ------------------------------------------------------------------------------------"
		li ++
		_ImpTot (_aTotGrau)
		li ++
		@ li, 0 psay "Obs.: Este relatorio lista cargas recebidas na balanca e nao necessariamente reflete as contranotas emitidas, pois"
		li ++
		@ li, 0 psay "      podem existir cargas para as quais ainda nao foram emitidas as contranotas."
		li = _nMaxLin + 1
	endif

	// Imprime parametros usados na geracao do relatorio
	if li > _nMaxLin - 2
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	U_ImpParam (_nMaxLin)
return



// --------------------------------------------------------------------------
// Acumula totais em arrays para posterior impressao.
Static Function _Acumula (_aMat, _sSafra, _sFilial, _sAssoc, _sLojAssoc, _sProduto, _sDescri, _nPeso, _sGrau, _sPRM99, _sLocal)
	local _nLinha := 0
	_nLinha = ascan (_aMat, {|_aVal| _aVal [1] == _sSafra ;
	                           .and. _aVal [2] == _sFilial ;
	                           .and. _aVal [3] == "" ;
	                           .and. _aVal [4] == _sAssoc ;
	                           .and. _aVal [5] == _sLojAssoc ;
	                           .and. _aVal [6] == _sProduto ;
	                           .and. _aVal [7] == _sGrau ;
	                           .and. _aVal [8] == _sPRM99 ;
	                           .and. _aVal [11] == _sLocal})
	if _nLinha == 0
		aadd (_aMat, {_sSafra, _sFilial, "", _sAssoc, _sLojAssoc, _sProduto, _sGrau, _sPRM99, _sDescri, 0, _sLocal})
		_nLinha = len (_aMat)
	endif                                                            
//	u_log(_aMat)
//	u_log(_nLinha)
//	u_log(_nPeso)
	_aMat [_nLinha, 10] += _nPeso
return



// --------------------------------------------------------------------------
// Imprime totais
Static Function _ImpTot (_aMat, _sTipo)
	local _nMat    := 0
	local _sLinImp := 0
	local _nTotal  := 0

	// Ordena por produto + grau
	_aMat = asort (_aMat,,, {|_x, _y| _x[6] + _x[7] < _y [6] + _y[7]})
	
	for _nMat = 1 to len (_aMat)
		if li > _nMaxLin
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		_sLinImp := ""
		_sLinImp += u_TamFixo (alltrim (_aMat [_nMat, 6]) + " - " + _aMat [_nMat, 9], 61) + "  "
		_sLinImp += transform (_aMat [_nMat, 10], "@E 999,999,999,999") + "   "
		_sLinImp += _aMat [_nMat, 7] + "    "
		_sLinImp += _aMat [_nMat, 8]
		_nTotal += _aMat [_nMat, 10]
		@ li, 41 psay _sLinImp
		li ++
	next
	@ li, 107 psay "------------"
	li ++
	@ li, 104 psay transform (_nTotal, "@E 999,999,999,999")
	li ++
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                     Help
	aadd (_aRegsPerg, {01, "Data recebimento inicial      ", "D", 8,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {02, "Data recebimento final        ", "D", 8,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {03, "Local recebimento inicial     ", "C", 2,  0,  "",   "ZX509 ", {},                        ""})
	aadd (_aRegsPerg, {04, "Local recebimento final       ", "C", 2,  0,  "",   "ZX509 ", {},                        ""})
	aadd (_aRegsPerg, {05, "Cooperativa inicial           ", "C", 6,  0,  "",   "SA2   ", {},                        ""})
	aadd (_aRegsPerg, {06, "Loja cooperativa inicial      ", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {07, "Cooperativa final             ", "C", 6,  0,  "",   "SA2   ", {},                        ""})
	aadd (_aRegsPerg, {08, "Loja cooperativa final        ", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {09, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},                        ""})
	aadd (_aRegsPerg, {10, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {11, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},                        ""})
	aadd (_aRegsPerg, {12, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {13, "Resumido / detalhado          ", "N", 1,  0,  "",   "      ", {"Resumido", "Detalhado"}, ""})
	aadd (_aRegsPerg, {14, "Resumo variedade+grau no final", "N", 1,  0,  "",   "      ", {"Sim", "Nao"},            ""})
	aadd (_aRegsPerg, {15, "Produto (variedade) inicial   ", "C", 15, 0,  "",   "SB1   ", {},                        ""})
	aadd (_aRegsPerg, {16, "Produto (variedade) final     ", "C", 15, 0,  "",   "SB1   ", {},                        ""})
	aadd (_aRegsPerg, {17, "Coop.origem(associado) inicial", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {18, "Coop.origem(associado) final  ", "C", 2,  0,  "",   "      ", {},                        ""})
	aadd (_aRegsPerg, {19, "Filial inicial                ", "C", 2,  0,  "",   "SM0   ", {},                        ""})
	aadd (_aRegsPerg, {20, "Filial final                  ", "C", 2,  0,  "",   "SM0   ", {},                        ""})
	aadd (_aRegsPerg, {21, "Quanto a devolucao            ", "N", 1,  0,  "",   "      ", {"Normais", "Devolvidas"}, ""})

	aadd (_aDefaults, {"15", ""})
	aadd (_aDefaults, {"16", "zzzzzzzzzzzzzzzz"})
	aadd (_aDefaults, {"17", ""})
	aadd (_aDefaults, {"18", "zz"})
	aadd (_aDefaults, {"19", ""})
	aadd (_aDefaults, {"20", "zz"})
	aadd (_aDefaults, {"21", 1})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
