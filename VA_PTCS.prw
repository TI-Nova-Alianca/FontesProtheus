// Programa:   VA_PTCS
// Autor:      Robert Koch
// Data:       27/03/2019
// Descricao:  Relatorio auxiliar para preenchimento de taloes de produtor ref. contranotas de compra de safra.
//             Criado com base em consulta equivalente que existis no 'consultas web'
//
// Historico de alteracoes:
// 26/04/2019 - Robert - Criada opcao de exportar para planilha.
// 25/06/2020 - Robert - Removida validacao que permitia somente grupo 059 do ZZU.
//

// --------------------------------------------------------------------------
user function VA_PTCS ()

	// Verifica se o usuario tem acesso.
//	if ! U_ZZUVL ('059')
//		return
//	endif

	// Variaveis obrigatorias dos programas de relatorio
	cDesc1   := "Relatorio auxiliar para preenchimento dos taloes"
	cDesc2   := "de produtor ref. contranotas de compra ou de"
	cDesc3   := "complemento de valor de safra."
	cString  := "SA2"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	Titulo   := cDesc1
	cPerg    := "VA_PTCS"
	nomeprog := "VA_PTCS"
	wnrel    := "VA_PTCS"
	tamanho  := "G"
	limite   := 220
	nTipo    := 15
	m_pag    := 1
	li       := 80
	cCabec1  := ""
	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	processa ({|| _Imprime ()})
	if mv_par10 == 1
		MS_FLUSH ()
		DbCommitAll ()
		If aReturn [5] == 1
			ourspool(wnrel)
		endif
	endif
return



// --------------------------------------------------------------------------
static function _Imprime ()
	local _oSQL := NIL
	local _sAliasQ := ''
	local _sCOrig := ''
	local _sNome := ''
	local _sLinImp := ''
	local _nTotPeso := 0
	local _nTotValor := 0
	private _nMaxLin := 68
	li = _nMaxLin + 1

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	// Define titulo e cabecalhos
	cCabec1 = "Associado                                              Filial           Contranotas                                                             Tipo uva       Peso Kg    Valor total"

	procregua (10)
	incproc ("Lendo dados...")

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += "              SELECT A2_VACORIG,"
	_oSQL:_sQuery += "                     V.NOME_ASSOC,"
	_oSQL:_sQuery += "                     V.ASSOCIADO,"
	_oSQL:_sQuery += "                     V.LOJA_ASSOC AS LOJA,"
	_oSQL:_sQuery += "                     SM0.M0_FILIAL AS FILIAL,"
	_oSQL:_sQuery += "                     SUBSTRING("  // GERA STRING COM A LISTA DAS CONTRANOTAS. USA SUBSTRING A PARTIR DA POSICAO 2 PARA REMOVER A VIRGULA INICIAL. USA A CLAUSULA FOR XML PARA CONCATENAR OS NUMEROS DAS NOTAS
	_oSQL:_sQuery += "                         ("
	_oSQL:_sQuery += "                             SELECT '/' + DOC AS [text()]"
	_oSQL:_sQuery += "                             FROM   ("
	_oSQL:_sQuery += "                                        SELECT DISTINCT DOC"
	_oSQL:_sQuery += "                                        FROM   VA_VNOTAS_SAFRA NOTAS"
	_oSQL:_sQuery += "                                        WHERE  NOTAS.ASSOCIADO = V.ASSOCIADO"
	_oSQL:_sQuery += "                                               AND NOTAS.LOJA_ASSOC = V.LOJA_ASSOC"
	_oSQL:_sQuery += "                                               AND NOTAS.SAFRA = V.SAFRA"
	_oSQL:_sQuery += "                                               AND NOTAS.FILIAL = V.FILIAL"
	_oSQL:_sQuery += "                                               AND NOTAS.TIPO_NF = V.TIPO_NF"
	_oSQL:_sQuery += "                                               AND NOTAS.DATA BETWEEN '" + dtos (mv_par06) + "' and '" + dtos (mv_par07) + "'"
	_oSQL:_sQuery += "                                    ) AS SUB1"
	_oSQL:_sQuery += "                                    FOR XML PATH('')"
	_oSQL:_sQuery += "                         ),"
	_oSQL:_sQuery += "                         2,"
	_oSQL:_sQuery += "                         100"
	_oSQL:_sQuery += "                     ) AS CONTRANOTAS,"
	_oSQL:_sQuery += "                     CASE V.FINA_COMUM"
	_oSQL:_sQuery += "                          WHEN 'F' THEN 'VINIFERA'"
	_oSQL:_sQuery += "                          WHEN 'C' THEN 'AMERICANA'"
	_oSQL:_sQuery += "                          ELSE ''"
	_oSQL:_sQuery += "                     END AS TIPO_UVA,"
	_oSQL:_sQuery += "                     SUM(V.PESO_LIQ) AS PESO_DA_NF,"
	_oSQL:_sQuery += "                     SUM(V.VALOR_TOTAL) AS VALOR_DA_NF"
	_oSQL:_sQuery += "              FROM   VA_VNOTAS_SAFRA V,"
	_oSQL:_sQuery +=                       RetSQLName ("SA2") + " SA2,"
	_oSQL:_sQuery += "                     VA_SM0 SM0"
	_oSQL:_sQuery += "              WHERE  V.SAFRA = '" + mv_par05 + "'"
	_oSQL:_sQuery += "                     AND V.TIPO_NF = '" + iif (mv_par08 == 1, 'C', 'V') + "'"
	_oSQL:_sQuery += "                     AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "                     AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery += "                     AND SA2.A2_COD = V.ASSOCIADO"
	_oSQL:_sQuery += "                     AND SA2.A2_LOJA = V.LOJA_ASSOC"
	if ! empty (mv_par09)
		_oSQL:_sQuery += "                     AND SA2.A2_VACORIG IN " + FormatIn (mv_par09, '/')
	endif
	_oSQL:_sQuery += "                     AND SM0.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "                     AND SM0.M0_CODIGO = '" + cEmpAnt + "'"
	_oSQL:_sQuery += "                     AND SM0.M0_CODFIL = V.FILIAL"
	_oSQL:_sQuery += "                     AND V.DATA BETWEEN '" + dtos (mv_par06) + "' and '" + dtos (mv_par07) + "'"
	_oSQL:_sQuery += "              GROUP BY V.SAFRA,A2_VACORIG,ASSOCIADO,V.LOJA_ASSOC,V.NOME_ASSOC,V.FILIAL,SM0.M0_FILIAL,DOC,V.FINA_COMUM,V.TIPO_NF
	_oSQL:_sQuery += "          )"
	_oSQL:_sQuery += " SELECT A2_VACORIG,"
	_oSQL:_sQuery += "       ASSOCIADO, LOJA, NOME_ASSOC,"
	_oSQL:_sQuery += "       FILIAL,"
	_oSQL:_sQuery += "       TIPO_UVA,"
	_oSQL:_sQuery += "       cast (CONTRANOTAS as varchar (80)) as CONTRANOTAS,"
	_oSQL:_sQuery += "       SUM(PESO_DA_NF) AS PESO,"
	_oSQL:_sQuery += "       SUM(VALOR_DA_NF) AS VALOR"
	_oSQL:_sQuery += " FROM   C"
	_oSQL:_sQuery += " GROUP BY A2_VACORIG,ASSOCIADO,LOJA,NOME_ASSOC,FILIAL,TIPO_UVA,CONTRANOTAS"
	_oSQL:_sQuery += " ORDER BY A2_VACORIG, NOME_ASSOC, FILIAL, TIPO_UVA"
	_oSQL:Log ()
	if mv_par10 == 1
		_sAliasQ = _oSQL:Qry2Trb ()
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			
			// Controla quebra por cooperativa de origem
			_sCOrig = (_sAliasQ) -> A2_VACORIG
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> A2_VACORIG == _sCOrig
				
				// Controla quebra por nome do associado
				_sNome = (_sAliasQ) -> nome_assoc
				if li > _nMaxLin
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 0 psay _sCOrig + '  ' + U_TamFixo ((_sAliasQ) -> associado + '/' + (_sAliasQ) -> loja + ' - ' + (_sAliasQ) -> nome_assoc, 50, ' ')
				do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> A2_VACORIG == _sCOrig .and. (_sAliasQ) -> nome_assoc == _sNome
					incproc ()
					if li > _nMaxLin
						cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
					endif
					_sLinImp := ''
					_sLinImp += U_TamFIxo ((_sAliasQ) -> filial, 15, '') + '  '
					_sLinImp += U_TamFixo ((_sAliasQ) -> contranotas, 70, ' ') + '  '
					_sLinImp += U_TamFixo ((_sAliasQ) -> tipo_uva, 9, ' ') + '  '
					_sLinImp += transform ((_sAliasQ) -> peso, "@E 999,999,999") + '  '
					_sLinImp += transform ((_sAliasQ) -> valor, "@E 99,999,999.99")
					@ li, 55 psay _sLinImp
					@ li ++

					_nTotPeso  += (_sAliasQ) -> peso
					_nTotValor += (_sAliasQ) -> valor
					(_sAliasQ) -> (dbskip ())
				enddo
				@ li, 0 psay __PrtThinLine ()
				li ++
			enddo
			
			// Quebra de pagina ao mudar a cooperativa de origem.
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		enddo
		(_sAliasQ) -> (dbclosearea ())

		// Imprime totais gerais
		if li > _nMaxLin
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		_sLinImp := ''
		_sLinImp += 'Totais:'
		_sLinImp += transform (_nTotPeso, "@E 999,999,999,999") + ' '
		_sLinImp += transform (_nTotValor, "@E 999,999,999.99")
		@ li, 144 psay _sLinImp
		@ li ++

		// Imprime parametros usados na geracao do relatorio
		if li > _nMaxLin - 2
			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
		endif
		U_ImpParam (_nMaxLin)
	else
		_oSQL:Qry2XLS (.F.)
	endif
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
	aadd (_aRegsPerg, {05, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {06, "Data contranota inicial       ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {07, "Data contranota final         ", "D", 8,  0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {08, "Tipo de contranota            ", "N", 1,  0,  "",   "      ", {"Compra", "Complemento"},           ""})
	aadd (_aRegsPerg, {09, "Coop.orig(AL/SV/...) bco=todas", "C", 18, 0,  "",   "      ", {},                                  ""})
	aadd (_aRegsPerg, {10, "Destino                       ", "N", 1,  0,  "",   "      ", {"Relatorio", "Planilha"},           ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
