// Programa.: VA_LPR
// Autor....: Robert Koch
// Data.....: 07/03/2008
// Descricao: Geracao de listas de precos de venda.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Geracao de listas de precos de venda.
// #PalavasChave      #lista_de_preco 
// #TabelasPrincipais #DA0 #DA1
// #Modulos           #FAT
//
// Historico de alteracoes:
// 02/04/2008 - Robert  - Criados parametros de vendedor de...ate.
//                      - Soh imprime listas ativas.
// 07/04/2008 - Robert  - Cria variavel private para filtro por vendedor.
// 15/04/2008 - Robert  - Valida amarracao vendedor X tabela no SZY.
// 16/04/2008 - Robert  - Imprime campo memo de instrucoes
// 20/06/2008 - Robert  - Alterado titulo da coluna de preco.
// 24/07/2008 - Robert  - Criada opcao de listar o campo B1_IPINOVO.
// 12/09/2008 - Robert  - Diminuida altura da pagina
// 01/04/2009 - Robert  - Criado parametro de selecao de cod.barras / valor unitario na ultima coluna.
// 22/04/2010 - Robert  - Campo B1_IPINOVO excluido da base de dados.
// 08/03/2012 - Robert  - Tratamento para impressao do campo DA1_VAST.
// 10/01/2013 - Elaine  - Passa a tratar consulta padrao das listas de preços pelo F3_DA0
// 04/06/2013 - Robert  - Se usuario for representante, obriga a parametrizar para seu codigo de representante.
// 30/01/2015 - Catia   - Incluida a coluna de UF
// 02/02/2015 - Catia   - Incluido intervalo de CLIENTE/LOJA
// 03/02/2015 - Catia   - Alterado o F3 da consulta da lista de preços
// 28/09/2015 - Robert  - Nao somava a ST na coluna "valor final unidade"
// 02/12/2015 - Robert  - Tratamento para IPI por aliquota e por valor absoluto.
// 13/07/2016 - Robert  - Desabilitada impressao do final de vigencia, lista de vendedores e de clientes.
// 05/09/2016 - Robert  - Tabela 81 trocada pela tabela 38 do ZX5.
// 11/04/2019 - Robert  - Tabela 98 trocada pela tabela 50 do ZX5.
// 29/07/2019 - Andre   - Campo B1_VAEANUN substituido pelo campo B5_2CODBAR.
// 26/10/2021 - Claudia - Inclusao das tags de pesquisa.
//
// --------------------------------------------------------------------------
user function VA_LPR ()

	// Cria variavel private com o codigo do vendedor, para os casos em que esta
	// rotina for acessada por um representante e que esse representante deva
	// visualizar apenas os seus registros.
	// Sugestao de filtro para F3 --> iif(type("_sCodRep")=="C", da0->da0_vend==_sCodRep, .T.)
	private _sCodRep := NIL
	_xUsuario := upper(alltrim(cUserName))
	_xMat_usu := ALLTRIM(__CUSERID)
	dbselectarea ("SA3")
	DbGoTop()
	Do WHile !eof()
		If ALLTRIM(A3_CODUSR) == ALLTRIM(UPPER(_xMat_usu))
			_sCodRep := A3_COD
			EXIT
		ENDIF
		DbSkip()
	EndDo
	
	cPerg    := "VA_LPR"
	_ValidPerg ()

	// Caso seja um representante, grava seu codigo nos parametros.
	if !empty(_sCodRep)
		U_GravaSX1 (cPerg, '03', _sCodRep) 
		U_GravaSX1 (cPerg, '04', _sCodRep)
	endif

	if pergunte (cPerg, .T.)
		// Caso seja um representante, inibe parametrizacao para outros codigos de representantes.
		if !empty(_sCodRep)
			mv_par03 = _sCodRep
			mv_par04 = _sCodRep
		endif
		processa ({|| _AndaLogo ()})
	endif
return
//
// --------------------------------------------------------------------------
// Geracao do arquivo de trabalho p/ impressao
static function _AndaLogo ()
	local _aCampos   := {}  // Para os arquivos de trabalho
	local _aArqTrb   := {}  // Para os arquivos de trabalho
	local _oImpGr    := NIL
	local _oPrn      := NIL
	local _lVendOK   := .T.
	local _sAvisos   := ""
	local _sInstr    := ""
	local _aInstr    := {}
	local _nInstr    := 0

	// Teste para geracao de PDF. Nao vingou por que as coordenadas sao um pouco diferentes -->	_oPrn := FWMSPrinter():New("VA_LPR", 2)

	// Objetos para impressao
	_oPrn:=TAVPrinter():New("VA_LPR")
	_oPrn:Setup()           // Tela para usuario selecionar a impressora
	_oPrn:SetPortrait()     // ou SetLanscape()

	_oImpGr := ClsImpGr():New (_oPrn, "A4R")

	// Objetos para tamanho e tipo das fontes
	_oCour18N := TFont():New("Courier New",,18,,.T.,,,,,.F.)
	_oCour16N := TFont():New("Courier New",,16,,.T.,,,,,.F.)
	_oCour12N := TFont():New("Courier New",,12,,.T.,,,,,.F.)
	_oCour10N := TFont():New("Courier New",,10,,.T.,,,,,.F.)
	_oCour8N  := TFont():New("Courier New",,8 ,,.T.,,,,,.F.)

	// Gera arquivo de trabalho para posterior ordenacao na impressao.
	_aCampos = {}
	aadd (_aCampos, {"DA0_CODTAB", "C", tamsx3 ("DA0_CODTAB")[1], 0})
	aadd (_aCampos, {"DA0_DESCRI", "C", 50, 0})
	aadd (_aCampos, {"DA0_DATDE",  "D", 8, 0})
	aadd (_aCampos, {"DA0_DATATE", "D", 8, 0})
	aadd (_aCampos, {"DA0_DESC",   "N", tamsx3 ("DA0_DESC")[1], 2})
	aadd (_aCampos, {"DA0_VACMEM", "C", tamsx3 ("DA0_VACMEM")[1], 0})
	aadd (_aCampos, {"DA1_CODPRO", "C", tamsx3 ("DA1_CODPRO")[1], 0})
	aadd (_aCampos, {"B1_DESC",    "C", 60, 0})
	aadd (_aCampos, {"Grupo1",     "C", 1, 0})
	aadd (_aCampos, {"Grupo2",     "C", 1, 0})
	aadd (_aCampos, {"NomeGrupo1", "C", 40, 0})
	aadd (_aCampos, {"NomeGrupo2", "C", 40, 0})
	aadd (_aCampos, {"IPI",        "N", 8, 2})
	aadd (_aCampos, {"ValST",      "N", 18, 2})
	aadd (_aCampos, {"EAN",        "C", 13, 0})
	aadd (_aCampos, {"B1_GRPEMB",  "C", 16, 0})
	aadd (_aCampos, {"DA1_PRCVEN", "N", tamsx3 ("DA1_PRCVEN")[1], 2})
	aadd (_aCampos, {"QtdEmb",     "N", 10, 0})
	aadd (_aCampos, {"Estado",     "C", 2, 0})
	U_ArqTrb ("Cria", "_trb", _aCampos, {"da0_codtab + Grupo1 + Grupo2 + b1_grpemb + da1_codpro"}, @_aArqTrb)

	// Gera dados no arquivo de trabalho.
	sx5 -> (dbsetorder (1))
	sa3 -> (dbsetorder (1))
	sb1 -> (dbsetorder (1))
	da1 -> (dbsetorder (1))  // DA1_FILIAL+DA1_CODTAB+DA1_CODPRO+DA1_INDLOT+DA1_ITEM
	da0 -> (dbsetorder (1))  // DA0_FILIAL+DA0_CODTAB
	da0 -> (dbseek (xfilial ("DA0") + mv_par01, .T.))

	do while ! da0 -> (eof ()) .and. da0 -> da0_filial == xfilial ("DA0") .and. da0 -> da0_codtab <= mv_par02
		if (da0 -> da0_ativo != "1" .and. mv_par07 = 1) .or. (da0 -> da0_ativo != "2" .and. mv_par07 = 2)
			da0 -> (dbskip ())
			loop
		endif

		// Verifica amarracao com vendedores
		_lVendOK = .F.
		szy -> (dbsetorder (2))  // ZY_FILIAL+ZY_FILTAB+ZY_CODTAB+ZY_VEND
		if szy -> (dbseek (xfilial ("SZY") + da0 -> da0_filial + da0 -> da0_codtab, .T.))
			do while ! szy -> (eof ()) .and. szy -> zy_filial == xfilial ("SZY") .and. szy -> zy_filtab == da0 -> da0_filial .and. szy -> zy_codtab == da0 -> da0_codtab
				if szy -> zy_vend >= mv_par03 .and. szy -> zy_vend <= mv_par04
					_lVendOK = .T.
					exit
				endif
				szy -> (dbskip ())
			enddo
		
		// Tabela nao tem amarracao com nenhum vendedor: vai listar somente se o
		// vendedor 'branco' estiver dentro dos parametros (Ex.: usuario pediu de branco a zzzzzz)
		else
			if empty (mv_par03)
				_lVendOK = .T.
			endif
		endif

		if ! _lVendOK
			da0 -> (dbskip ())
			loop
		endif

		da1 -> (dbseek (xfilial ("DA1") + da0 -> da0_codtab, .T.))
		do while ! da1 -> (eof ()) .and. da1 -> da1_filial == xfilial ("DA1") .and. da1 -> da1_codtab == da0 -> da0_codtab

			if da1 -> da1_estado < mv_par08 .or. da1 -> da1_estado > mv_par09
				da1 -> (dbskip ())
				loop
			endif
			
			if da1 -> da1_client < mv_par10 .or. da1 -> da1_client > mv_par11
				da1 -> (dbskip ())
				loop
			endif
			
			if da1 -> da1_loja < mv_par12 .or. da1 -> da1_loja > mv_par13
				da1 -> (dbskip ())
				loop
			endif

			if sb1 -> (dbseek (xfilial ("SB1") + da1 -> da1_codpro, .F.))
				if empty (sb1 -> b1_vaGrLp) .or. empty (U_RetZX5("38", sb1 -> b1_vaGrLp, "ZX5_38G1"))
					_sAvisos += "Produto '" + alltrim (da1 -> da1_codpro) + "' tem campo '" + alltrim (RetTitle ("B1_VAGRLP")) + "' vazio ou invalido e vai ser impresso fora de ordem." + chr (13) + chr (10)
				else
					reclock ("_trb", .T.)
					_trb -> da0_codtab = da0 -> da0_codtab
					_trb -> da0_descri = da0 -> da0_descri
					_trb -> da0_datde  = da0 -> da0_datde
					_trb -> da0_datate = da0 -> da0_datate
					_trb -> da0_desc   = da0 -> da0_desc
					_trb -> da0_vaCMem = da0 -> da0_vaCMem
					_trb -> da1_codpro = da1 -> da1_codpro
					_trb -> da1_prcven = da1 -> da1_prcven
					_trb -> b1_desc    = sb1 -> b1_desc
					_trb -> Grupo1     = substr (sb1 -> b1_vaGrLp, 1, 1)
					_trb -> Grupo2     = substr (sb1 -> b1_vaGrLp, 2, 1)
					_trb -> NomeGrupo1 = U_RetZX5("38", sb1 -> b1_vaGrLp, "ZX5_38G1")  // sx5 -> x5_descri
					_trb -> NomeGrupo2 = U_RetZX5("38", sb1 -> b1_vaGrLp, "ZX5_38G2")  // sx5 -> x5_descSpa
					_trb -> ipi        = iif (sb1 -> b1_vlr_ipi > 0, sb1 -> b1_vlr_ipi, da1 -> da1_prcven * sb1 -> b1_ipi / 100)
					_trb -> ValST      = da1 -> da1_vast
					_trb -> ean        = POSICIONE("SB5",1,XFILIAL("SB5")+SB1->B1_COD,"B5_2CODBAR")
					_trb -> b1_grpemb  = U_RetZX5 ("50", sb1 -> b1_grpemb, "ZX5_50DESC")
					_trb -> QtdEmb     = sb1 -> b1_QtdEmb
					_trb -> Estado     = da1 -> da1_estado
					msunlock ()
				endif
			endif
			da1 -> (dbskip ())
		enddo
		da0 -> (dbskip ())
	enddo

	if ! empty (_sAvisos)
		U_ShowMemo (_sAvisos, "AVISOS")
	endif

	// Define variaveis para controle de quebras
	_sQuebra1  = "da0_codtab"
	_sNomeQbr1 = "da0_descri"
	_sQuebra2  = "Grupo1"
	_sNomeQbr2 = "NomeGrupo1"
	_sQuebra3  = "Grupo2"
	_sNomeQbr3 = "NomeGrupo2"

	// Impressao do arquivo de trabalho.
	_trb -> (dbgotop ())
	do while ! _trb -> (eof ())

		// Reinicia contagem de paginas e gera cabecalho automaticamente.
		_oImpGr:Cabec (.T., 0, .T.)

		// Controla quebra 1
		_xQuebra1 = _trb -> &(_sQuebra1)
		_sLinhaImp = padc (alltrim (left ("Tabela de precos " + _xQuebra1 + " - " + alltrim (_trb -> &(_sNomeQbr1)), 65)), 65, " ")
		_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq, _sLinhaImp, _oCour16N, 100)
		_oImpGr:IncLinha (2)

		_sLinhaImp := "Inicio da vigencia: " + dtoc (_trb -> da0_DatDe)
		_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 1200, _sLinhaImp, _oCour10N, 100)
		_oImpGr:IncLinha ()

		// Busca campo memo do DA0
		_sInstr = MSMM (_trb -> da0_vacmem,,,,3)

		do while ! _trb -> (eof ()) .and. _trb -> &(_sQuebra1) == _xQuebra1
			_oImpGr:Cabec (.F., 200)

			// Linha antes de cada marca de produtos
			_oPrn:Line(_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 50, _oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nLargPag - 100)
			_oImpGr:IncLinha ()

			// Controla quebra 2
			_xQuebra2 = _trb -> &(_sQuebra2)
			_sLinhaImp = alltrim (_trb -> &(_sNomeQbr2))
			_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 50, _sLinhaImp, _oCour18N, 100)
			_oImpGr:IncLinha (2)

			do while ! _trb -> (eof ()) .and. _trb -> &(_sQuebra1) == _xQuebra1 .and. _trb -> &(_sQuebra2) == _xQuebra2
				_oImpGr:Cabec (.F., 150)

				// Controla quebra 3
				_xQuebra3 = _trb -> &(_sQuebra3)
				_sLinhaImp = alltrim (_trb -> &(_sNomeQbr3))
				_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 100, _sLinhaImp, _oCour12N, 100)
				_oImpGr:IncLinha ()
				if mv_par06 == 1
					if mv_par05 == 1
						_sLinhaImp = "Codigo Descricao                                      Embalagem             Preco     IPI        ST  UF  EAN13-unid"
					else
						_sLinhaImp = "Codigo Descricao                                      Embalagem             Preco     IPI            UF  EAN13-unid"
					endif
				else
					if mv_par05 == 1
						_sLinhaImp = "Codigo Descricao                                      Embalagem             Preco     IPI       ST   UF  Vl.final unidade"
					else
						_sLinhaImp = "Codigo Descricao                                      Embalagem             Preco     IPI            UF  Vl.final unidade"
					endif
				endif
				_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 100, _sLinhaImp, _oCour8N, 100)
				_oImpGr:IncLinha ()
				_sLinhaImp = "------ ---------------------------------------------- ----------------  ---------  ------    ------  --  ----------------"
				_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 100, _sLinhaImp, _oCour8N, 100)
				_oImpGr:IncLinha ()
				do while ! _trb -> (eof ()) .and. _trb -> &(_sQuebra1) == _xQuebra1 .and. _trb -> &(_sQuebra2) == _xQuebra2 .and. _trb -> &(_sQuebra3) == _xQuebra3
					_oImpGr:Cabec (.F., 0)
					_sLinhaImp := left (_trb -> da1_codpro, 6) + " "
					_sLinhaImp += LEFT(_trb -> b1_desc,45) + "  "
					_sLinhaImp += _trb -> b1_grpemb + " "
					_sLinhaImp += transform (_trb -> da1_prcven, "@E 999,999.99") + " "
					_sLinhaImp += transform (_trb -> ipi, "@E 9999.99") + "   "
					if mv_par05 == 1
						_sLinhaImp += transform (_trb -> ValST, "@E 9999.99") + "  "
					else
						_sLinhaImp += space (11)
					endif
					_sLinhaImp += _trb -> estado + "  "
					if mv_par06 == 1
						_sLinhaImp += _trb -> ean
					else
						_sLinhaImp += transform ((_trb -> da1_prcven + _trb -> ipi + _trb -> ValST) / _trb -> qtdemb, "@E 999,999.99")
					endif
					_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq + 100, _sLinhaImp, _oCour8N, 100)
					_oImpGr:IncLinha ()
					_trb -> (dbskip ())
				enddo
				_oImpGr:IncLinha ()
			enddo
			_oImpGr:IncLinha ()
		enddo

 		// Lista campo memo do DA0 no final da tabela.
 		if ! empty (_sInstr)
	 		_sLinhaImp = "Instrucoes:"
			_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq, _sLinhaImp, _oCour12N, 100)
	 		_oImpGr:IncLinha ()
 			_aInstr = U_QuebraTXT (alltrim (_sInstr), 105)
	 		for _nInstr = 1 to len (_aInstr)
				_oImpGr:Cabec (.F., 0)
		 		_sLinhaImp = _aInstr [_nInstr]
				_oPrn:Say (_oImpGr:_nMargsup + _oImpGr:_nLinAtual, _oImpGr:_nMargEsq, _sLinhaImp, _oCour10N, 100)
		 		_oImpGr:IncLinha ()
		 	next
		endif
	enddo
	
	U_ArqTrb ("FechaTodos",,,, @_aArqTrb)
	
	_oPrn:Preview()       // Visualiza antes de imprimir
	_oPrn:End()
return
//
// --------------------------------------------------------------------------
// Pergunte
static function _ValidPerg ()
	local _aRegsPerg  := {}
	local _aHelpPerg  := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                            Help
	aadd (_aRegsPerg, {01, "Lista de precos de            ", "C", 3,  0,  "",   "DA0", {},                              ""})
	aadd (_aRegsPerg, {02, "Lista de precos ate           ", "C", 3,  0,  "",   "DA0", {},                              ""})
	aadd (_aRegsPerg, {03, "Representante de              ", "C", 3,  0,  "",   "SA3",    {},                              "Filtra listas de preco vinculadas aos repersentantes informados aqui"})
	aadd (_aRegsPerg, {04, "Representante ate             ", "C", 3,  0,  "",   "SA3",    {},                              "Filtra listas de preco vinculadas aos repersentantes informados aqui"})
	aadd (_aRegsPerg, {05, "Imprime valor Subst.Trib.     ", "N", 1,  0,  "",   "   ",    {"Sim", "Nao"},                  ""})
	aadd (_aRegsPerg, {06, "Ultima coluna                 ", "N", 1,  0,  "",   "   ",    {"Cod.barras", "Vlr.unidade"},   "Indique se deseja listar, na ultima coluna, o codigo de barras do produto ou o valor final por unidade."})
	aadd (_aRegsPerg, {07, "Situacao tabelas              ", "N", 1,  0,  "",   "   ",    {"Ativas", "Inativas", "Ambas"}, ""})
	aadd (_aRegsPerg, {08, "UF de                         ", "C", 2,  0,  "",   "12 ",    {},                              ""})
	aadd (_aRegsPerg, {09, "UF ate                        ", "C", 2,  0,  "",   "12 ",    {},                              ""})
	aadd (_aRegsPerg, {10, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {11, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {12, "Loja de                       ", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {13, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	
	U_ValPerg (cPerg, _aRegsPerg, _aHelpPerg)
return
