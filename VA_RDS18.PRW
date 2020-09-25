// Programa:  VA_RDS18
// Autor:     Robert Koch
// Data:      07/01/2019
// Descricao: Relatorio com base nas pre-notas de safra, para conferencias.
//
// Historico de alteracoes:
// 26/02/2019 - Robert - Busca sempre a parcela H do ZZ9
//                     - Impede a impressao quando safra diferente (precisaria criar tratamento)
// 18/03/2019 - Robert - Criados parametros de filtragem e ordenacao por nucleo.
//

// --------------------------------------------------------------------------
User Function VA_RDS18 ()
	Local cCadastro := "Retatorio distribuicao sobras 2018"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	
	// Variaveis obrigatorias dos programas de relatorio
	Private cDesc1   := "Relatorio distribuicao de sobras 2018"
	Private cDesc2   := ""
	Private cDesc3   := ""
	Private cString  := "SZI"
	Private aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	Private nLastKey := 0
	Private Titulo   := cDesc1
	Private cPerg    := "VA_RDS18"
	Private nomeprog := "VA_RDS18"
	Private wnrel    := "VA_RDS18"
	Private tamanho  := "G"
	Private limite   := 220
	Private nTipo    := 15
	Private m_pag    := 1
	Private li       := 80
	Private cCabec1  := "GRP FIL  NF.ORIG    VARIEDADE                                 GRAU    PESO_LIQ    UNIT.ORIG      SOBRA   UNIT.FINAL        TOTAL SOBRA  OBSERVACOES"
	Private cCabec2  := ""
	Private aOrd     := {}

	if ! U_ZZUVL ('051', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	
	processa ({|| _Gera ()})
	MS_FLUSH ()
	DbCommitAll ()

	If aReturn [5] == 1
		ourspool(wnrel)
	Endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL     := NIL
	local _sAliasQ  := ""
	local _sFornece := ''
	local _sLoja    := ''
	local _nTotForn := 0
	local _nTotGer  := 0
	local _sLinImp  := ""
	private _nMaxLin := 68
	li = _nMaxLin + 1

	procregua (3)
	incproc ("Lendo dados...")
		
	// Busca dados
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT ISNULL ((SELECT TOP 1 ZAN_NUCLEO"  // Usei TOP 1 por que o associado pode estar ligado a mais de um grupo familiar
    _oSQL:_sQuery +=                   " FROM " + RETSQLNAME ("ZAN") + " ZAN, "
    _oSQL:_sQuery +=                              RETSQLNAME ("ZAK") + " ZAK "
	_oSQL:_sQuery +=                  " WHERE ZAN.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                    " AND ZAN.ZAN_FILIAL = '" + xfilial ("ZAN")  + "'"
	_oSQL:_sQuery +=                    " AND ZAK.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                    " and ZAK.ZAK_FILIAL = '" + xfilial ("ZAK")  + "'"
	_oSQL:_sQuery +=                    " and ZAK.ZAK_ASSOC  = ZZ9.ZZ9_FORNEC"
	_oSQL:_sQuery +=                    " and ZAK.ZAK_LOJA   = ZZ9.ZZ9_LOJA"
	_oSQL:_sQuery +=                    " and ZAK.ZAK_IDZAN  = ZAN.ZAN_COD"
	_oSQL:_sQuery +=                 "), '') AS NUCLEO,"
	_oSQL:_sQuery +=         " V.FILIAL, V.ASSOCIADO, V.LOJA_ASSOC, SA2.A2_NOME AS NOME, V.DOC, V.PRODUTO, V.DESCRICAO, V.GRAU, V.PESO_LIQ,"
	_oSQL:_sQuery +=         " V.VUNIT_EFETIVO,"
	_oSQL:_sQuery +=         " (ZZ9.ZZ9_VUNIT + (V.VALOR_COMPRA + V.VALOR_COMPLEMENTO)) / V.PESO_LIQ AS UNIT_SIMULADO,"
	_oSQL:_sQuery +=         " ZZ9.ZZ9_VUNIT AS TOTAL_SIMULADO,"
	_oSQL:_sQuery +=         " ZZ9.ZZ9_OBS as OBS, ZZ9_PARCEL AS PARCELA"
	_oSQL:_sQuery +=  " from " + RETSQLNAME ("SA2") + " SA2, "
	_oSQL:_sQuery +=             " VA_VPRECO_EFETIVO_SAFRA V, "
	_oSQL:_sQuery +=             RETSQLNAME ("ZZ9") + " ZZ9 "
	_oSQL:_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_FILIAL between '" + mv_par08 + "' and '" + mv_par09 + "'"
	_oSQL:_sQuery +=   " and SA2.A2_FILIAL  = '" + xfilial ("SA2")  + "'"
	_oSQL:_sQuery +=   " and SA2.A2_COD     = ZZ9.ZZ9_FORNEC"
	_oSQL:_sQuery +=   " and SA2.A2_LOJA    = ZZ9.ZZ9_LOJA"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_FORNEC + ZZ9.ZZ9_LOJA between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	if mv_par05 == '2018'
		_oSQL:_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '" + mv_par05 + "'"
	else
		// Foi uma parcela (H) gerada para situacao atipica em 2018. Para outros anos certamente teremos diferencas.
		_oSQL:_sQuery +=   " and ZZ9.ZZ9_SAFRA  = 'XXXX'"
		u_help ("Sem tratamento para esta safra")
	endif
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_PRODUT between '" + mv_par06 + "' and '" + mv_par07 + "'"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_PARCEL = 'H'"
	_oSQL:_sQuery +=   " AND V.FILIAL = ZZ9.ZZ9_FILIAL AND V.SAFRA = ZZ9.ZZ9_SAFRA AND V.ASSOCIADO = ZZ9.ZZ9_FORNEC AND V.LOJA_ASSOC = ZZ9.ZZ9_LOJA" 
	_oSQL:_sQuery +=   " AND V.DOC = ZZ9.ZZ9_NFORI AND V.SERIE = ZZ9.ZZ9_SERIOR AND V.ITEM_NOTA = ZZ9.ZZ9_ITEMOR"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery +=  " WHERE NUCLEO BETWEEN '" + mv_par10 + "' and '" + mv_par11 + "'"
	_oSQL:_sQuery +=  " ORDER BY NUCLEO, NOME, ASSOCIADO, LOJA_ASSOC, PARCELA, FILIAL, DESCRICAO"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		// Controla quebra por fornecedor
		_sNome    = (_sAliasQ) -> nome
		_sFornece = (_sAliasQ) -> associado
		_sLoja    = (_sAliasQ) -> loja_assoc
		_nTotForn = 0

		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		_sLinImp = ""
//		_sLinImp += (_sAliasQ) -> associado + '/' + (_sAliasQ) -> loja_assoc + ' - ' + U_TamFixo ((_sAliasQ) -> nome, 40) + '  '
		_sLinImp += (_sAliasQ) -> associado + '/' + (_sAliasQ) -> loja_assoc + ' - ' + alltrim ((_sAliasQ) -> nome) + '  (nucleo ' + (_sAliasQ) -> nucleo + ')'
		@ li, 0 psay _sLinImp
		li += 2

		do while ! (_sAliasQ) -> (eof ()) ;
			.and. (_sAliasQ) -> nome == _sNome ;
			.and. (_sAliasQ) -> associado == _sFornece ;
			.and. (_sAliasQ) -> loja_assoc == _sLoja
			incproc ()

			// Monta linha para impressao
			_sLinImp = ""
			_sLinImp += ' ' + (_sAliasQ) -> parcela + "  "
			_sLinImp += (_sAliasQ) -> filial + "   "
			_sLinImp += (_sAliasQ) -> doc + '  '
			_sLinImp += U_TamFixo (alltrim ((_sAliasQ) -> produto) + ' - ' + (_sAliasQ) -> descricao, 40) + '  '
			_sLinImp += (_sAliasQ) -> grau + ' '
			_sLinImp += transform ((_sAliasQ) -> peso_liq, "@E 999,999,999") + '  '
			_sLinImp += transform ((_sAliasQ) -> vunit_efetivo, "@E 99,999.9999") + ' '
			_sLinImp += transform ((_sAliasQ) -> unit_simulado - (_sAliasQ) -> vunit_efetivo, "@E 9,999.9999") + '  '
			_sLinImp += transform ((_sAliasQ) -> unit_simulado, "@E 99,999.9999") + '  '
			_sLinImp += transform ((_sAliasQ) -> total_simulado, "@E 99,999,999,999.99") + '  '
			_sLinImp += (_sAliasQ) -> obs

			if li > _nMaxLin
				cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
			endif
			@ li, 0 psay _sLinImp
			li ++
			
			_nTotForn += (_sAliasQ) -> total_simulado
			_nTotGer  += (_sAliasQ) -> total_simulado

			(_sAliasQ) -> (dbskip ())
		enddo
		_sLinImp = "                                                                                                                   -------------------"
		@ li, 0 psay _sLinImp
		li ++
		_sLinImp = "                                                                                                  Total associado:      "
		_sLinImp += transform (_nTotForn, "@E 999,999,999.99") + '  '
		@ li, 0 psay _sLinImp
		li ++
	enddo
	(_sAliasQ) -> (dbclosearea ())
    dbselectarea ("ZZ9")

	cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	_sLinImp = "                                                                                                                   ==================="
	@ li, 0 psay _sLinImp
	li ++
	_sLinImp = "                                                                                                      Total geral:      "
	_sLinImp += transform (_nTotGer, "@E 999,999,999.99") + '  '
	@ li, 0 psay _sLinImp
	li ++
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                               Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",   "SA2", {},                         "Codigo do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",   "   ", {},                         "Loja do produtor (fornecedor) inicial"})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",   "SA2", {},                         "Codigo do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",   "   ", {},                         "Loja do produtor (fornecedor) final"})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,  0,  "",   "   ", {},                         "Safra (ano) a ser processada"})
	aadd (_aRegsPerg, {06, "Variedade (produto) inicial   ", "C", 15, 0,  "",   "SB1", {},                         ""})
	aadd (_aRegsPerg, {07, "Variedade (produto) final     ", "C", 15, 0,  "",   "SB1", {},                         ""})
	aadd (_aRegsPerg, {08, "Filial inicial                ", "C", 2,  0,  "",   "SM0", {},                         ""})
	aadd (_aRegsPerg, {09, "Filial final                  ", "C", 2,  0,  "",   "SM0", {},                         ""})
	aadd (_aRegsPerg, {10, "Nucleo inicial (SV/SG/FC...)  ", "C", 2,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {11, "Nucleo final (SV/SG/FC...)    ", "C", 2,  0,  "",   "   ", {},                         ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
