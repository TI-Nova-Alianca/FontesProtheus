* Programa..: ML_SZ1.PRX
* Autor.....: Jeferson
* Data......: 8:45am Dez 23,1998
* Nota......: Lista de Precos p/ Safra da Uva
//
// Historico de alteracoes:
// 16/06/2008 - Robert - Alterado para modelo2.
// 17/01/2009 - Robert - Passa a ser chamado pelo VA_SZA pois existirao varias tabelas
//                       para cada safra, vinculadas ao SZA. Alterados indices do SZ1.
// 01/07/2010 - Robert - Criada opcao de copiar precos de uma variedade para outras.
// 13/07/2010 - Robert - Criada opcao de gerar precos a partir do preco do grau base.
// 28/07/2010 - Robert - Possibilita importar precos de um produto para outro.
// 07/01/2011 - Robert - Criado tratamento para cadastramento de tabela MOC.
// 25/07/2011 - Robert - Permite gerar precos dos demais graus com variacao fixa.
//                     - Verifica lacuna na sequencia de graus.
//                     - Permite aplicar % ao copiar precos para outros produtos.
// 02/03/2012 - Robert - Permite aplicar % aos valores, quando copiados de outra variedade.
// 20/12/2017 - Robert - Copiava indevidamente precos para produtos validando apenas parte do codigo.
// 23/03/2018 - Robert - Tratamento para tabela DESC (uvas desclassificadas na serra).
// 04/12/2018 - Robert - Permite informar decimais para arredondamento ao copiar preco de outro produto.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function Ml_sz1 ()
	private aRotina    := {}  // Opcoes do menu
	private cCadastro  := "Precos para safra da uva"
	
	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	aAdd(aRotina, {"Pesquisar",  "AxPesqui" , 0, 1})
	aAdd(aRotina, {"Visualizar", "U_ML_SZ1A", 0, 2})
	aAdd(aRotina, {"Incluir"  ,  "U_ML_SZ1A", 0, 3})
	aAdd(aRotina, {"Alterar"  ,  "U_ML_SZ1A", 0, 4})
	aAdd(aRotina, {"Copiar"   ,  "U_ML_SZ1C", 0, 4})
	aAdd(aRotina, {"Excluir"  ,  "U_ML_SZ1E", 0, 5})
	
	dbSelectArea ("SZ1")
	dbSetOrder (1)
	mBrowse(0, 0, 100, 100, "SZ1",,,,, 2)
return



// --------------------------------------------------------------------------
// Tela de manutencao
user function ML_SZ1a ()
	private _sProduto  := ""  // Deixar private para ser visto em gatilhos e validacoes.
	private _sNomePrd  := space (50)
	private _sProdOri  := space (15)  // Deixar private para ser visto em gatilhos e validacoes.
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}
	
	nOpc := 2
	if inclui .or. altera
		nOpc = 4
	endif
	
	if inclui
		_sProduto  = CriaVar ("Z1_CODPRD")
	else
		_sProduto = sz1 -> z1_codprd
	endif
	_sNomePrd  = CriaVar ("Z1_DESCPRD")

	// Gera aHeader e aCols.
	aHeader := U_GeraHead ("SZ1")
	if ! inclui
		aCols := U_GeraCols ("SZ1", ;  // Alias
		1, ;  // Indice
		xfilial ("SZ1") + sza -> za_cod + sz1 -> z1_codprd, ;  // Seek inicial
		'xfilial ("SZ1") + sz1 -> z1_tabela + sz1 -> z1_codprd == "' + xfilial ("SZ1") + sza -> za_cod + sz1 -> z1_codprd + '"', ;  // While
		aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
		.F.)  // Executa ou nao os gatilhos.
	else
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif
	
	// Variaveis do cabecalho da tela:
	aC:={}
	aadd (aC, {"sza -> za_cod",  {15, 5},   "Tabela",              "@!",                          "", "", .F.})
	aadd (aC, {"sza -> za_desc", {15, 160}, "Descricao",           "@!",                          "", "", .F.})
	if left (sza -> za_cod, 3) == "MOC"
		aadd (aC, {"_sProduto",      {30, 5},   "Grupo tab.MOC",   "@!",                          "vazio () .or. U_ML_SZ1VP ()", "SX5_Z6", inclui})
	elseif left (sza -> za_cod, 4) == "BASE"
		aadd (aC, {"_sProduto",      {30, 5},   "Subgrp.planilha", "@!",                          "vazio () .or. U_ML_SZ1VP ()", "ZX513A", inclui})
	elseif left (sza -> za_cod, 4) == "DESC"
		aadd (aC, {"_sProduto",      {30, 5},   "Subgrp.planilha", "@!",                          "vazio () .or. U_ML_SZ1VP ()", "",       inclui})
	else
		aadd (aC, {"_sProduto",      {30, 5},   "Produto",         "@!",                          "vazio () .or. U_ML_SZ1VP ()", "SB1UVA", inclui})
	endif
	aadd (aC, {"_sNomePrd",      {30, 160}, "Nome",                "@!",                          "", "", .F.})
	aadd (aC, {"_sProdOri",      {45, 5},   "Copiar do produto",   "@!",                          "vazio () .or. U_ML_SZ1VC ()", "SB1UVA", inclui .or. altera})
	
	aR := {}
	_aJanela := {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}  // Janela (dialog) do modelo2
	aCGD := {80,20,_aJanela[3] - 85, _aJanela[4] - 25}//118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		aC, ;  // Cabecalho
		aR, ;  // Rodape
		aCGD, ;  // Coordenadas da getdados
		nOpc, ;  // nOPC
		'U_ML_SZ1LK ()', ;  // Linha OK
		'U_ML_SZ1TK ()', ;  // Tudo OK
		, ;  // Gets editaveis
		, ;  // bloco codigo para tecla F4
		, ;  // Campos inicializados
		9999, ;  // Numero maximo de linhas
		_aJanela, ;  // Coordenadas da janela
		.T.)  // Linhas podem ser deletadas.
		
		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"Z1_FILIAL", xfilial ("SZ1")})
		aadd (_aCposFora, {"Z1_TABELA", sza -> za_cod})
		aadd (_aCposFora, {"Z1_CODPRD", _sProduto})
		
		// Grava dados do aCols.
		SZ1 -> (dbsetorder (1))  // SZ1_FILIAL + z1_tabela + z1_codprd + SZ1_ORIGEM + SZ1_DESTIN
		for N = 1 to len (aCols)
			
			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if SZ1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto + GDFieldGet ("Z1_GRAU"), .F.))
				
				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted ()
					reclock ("SZ1", .F.)
					SZ1 -> (dbdelete ())
					msunlock ("SZ1")
				else  // Alteracao
					reclock ("SZ1", .F.)
					U_GrvACols ("SZ1", N, _aCposFora)
					msunlock ("SZ1")
				endif
				
			else  // A linha ainda nao existe no arquivo
				if GDDeleted ()
					loop
				else
					reclock ("SZ1", .T.)
					U_GrvACols ("SZ1", N, _aCposFora)
					msunlock ("SZ1")
				endif
			endif
		next
		
	endif
return



// --------------------------------------------------------------------------
// Exclusao total.
user function ML_SZ1E ()
	local _aArea    := getarea ()
	local _sProduto := sz1 -> z1_codprd
	local _sQuery   := ""
	
	if msgyesno ("Confirma a exclusao de todos os valores para o produto " + sz1 -> z1_codprd + "?")
		sz1 -> (dbsetorder (1))
		sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto, .T.))
		do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == sza -> za_cod .and. sz1 -> z1_codprd == _sProduto
			reclock ("SZ1", .F.)
			sz1 -> (dbdelete ())
			msunlock ()
			sz1 -> (dbskip ())
		enddo
		msginfo ("Dados excluidos.")
	endif
return



// --------------------------------------------------------------------------
// Copia precos para outro(s) produto(s).
user function ML_SZ1C ()
	local _aArea     := getarea ()
	local _sProduto  := sz1 -> z1_codprd
	local _aTpPrc   := {}
	local _aColsMB   := {}
	local _aVaried   := {}
	local _nVaried   := 0
	local _sVaried   := ""
	local _aPrcOri   := {}
	local _nPrcOri   := 0
	local _lContinua := .T.
	local _nPercent  := 0
	local _sGrupo    := ''

	if aviso ('Copiar para', 'Deseja visualizar apenas variedades semelhantes ou todas as possibilidades?', {'Semelhantes', 'Todas'}, 3, 'Variedades destino') == 1
		sb1 -> (dbsetorder (1))
		if sb1 -> (dbseek (xfilial ("SZ1") + _sProduto, .F.))
			_sGrupo = sb1 -> b1_varuva + sb1 -> b1_vafcuva
		endif
	endif
	//u_log ('grupo:', _sGrupo)

	// Browse para o usuario selecionar as variedades.
	CursorWait ()
	_aVaried = {}
	sb1 -> (dbsetorder (1))
	sz1 -> (dbsetorder (1))  // Z1_FILIAL+Z1_TABELA+Z1_CODPRD+Z1_GRAU
	sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod, .T.))
	do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == sza -> za_cod
		if sz1 -> z1_codprd != _sProduto .and. ascan (_aVaried, {|_aVal| _aVal [2] == sz1 -> z1_codprd}) == 0
			if ! empty (_sGrupo)
				if ! sb1 -> (dbseek (xfilial ("SZ1") + sz1 -> z1_codprd, .F.)) .or. sb1 -> b1_varuva + sb1 -> b1_vafcuva != _sGrupo
					//u_log ('ignorando ', sz1 -> z1_codprd)
					sz1 -> (dbskip ())
					loop
				endif
			endif
			aadd (_aVaried, {.F., sz1 -> z1_codprd, fBuscaCpo ("SB1", 1, xfilial ("SB1") + sz1 -> z1_codprd, "B1_DESC")})
		endif
		sz1 -> (dbskip ())
	enddo
	_aVaried = asort (_aVaried,,, {|_x, _y| _x [3] < _y [3]})
	CursorArrow ()
	_aColsMB = {}
	aadd (_aColsMB, {2, "Variedade", 50,  "@!"})
	aadd (_aColsMB, {3, "Descricao", 200, "@!"})
	U_MBArray (@_aVaried, "Selecione as variedades DESTINOS", _aColsMB, 1, 600, 550, ".T.")
	_lContinua = .F.
	for _nVaried = 1 to len (_aVaried)
		if _aVaried [_nVaried, 1]
			//_sVaried += alltrim (_aVaried [_nVaried, 2]) + "/"
			_sVaried += _aVaried [_nVaried, 2] + "/"
			_lContinua = .T.
		endif
	next

	// Browse para usuario selecionar quais precos serao copiados.
	if _lContinua
		aadd (_aTpPrc, {.F., RetTitle ("Z1_PRCREC")})
		aadd (_aTpPrc, {.F., RetTitle ("Z1_PRCCOM")})
		aadd (_aTpPrc, {.F., RetTitle ("Z1_PRCDCO")})
		_aColsMB = {}
		aadd (_aColsMB, {2, "Tipo preco", 50, ""})
		U_MbArray (@_aTpPrc, "Selecione quais precos devem ser copiados", _aColsMB, 1, 500, 300, ".t.")
		if !_aTpPrc [1, 1] .and. !_aTpPrc [2, 1] .and. !_aTpPrc [3, 1]
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_nPercent = U_Get ("Deseja aplicar % aos valores copiados?", "N", 8, "999.9999", "", 0, .F., ".T.")
		if valtype (_nPercent) == "U" // .or. _nPercent <= 0
			_nPercent = 0
		endif

		CursorWait ()
		
		// Monta array com os precos da variedade atual (origem)
		_aPrcOri = {}
		sz1 -> (dbsetorder (1))  // Z1_FILIAL+Z1_TABELA+Z1_CODPRD+Z1_GRAU
		sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProduto, .T.))
		do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == sza -> za_cod .and. sz1 -> z1_codprd == _sProduto
			aadd (_aPrcOri, {sz1 -> z1_grau, sz1 -> z1_prcrec, sz1 -> z1_prccom, sz1 -> z1_prcdco})
			sz1 -> (dbskip ())
		enddo

		// Atualiza precos nas variedades destino.
		//u_log ('_aVaried:', _aVaried)
		sz1 -> (dbsetorder (1))  // Z1_FILIAL+Z1_TABELA+Z1_CODPRD+Z1_GRAU
		sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod, .T.))
		do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == sza -> za_cod
//			if sz1 -> z1_codprd $ _sVaried
			if ascan (_aVaried, {|_aVal| _aVal [1] == .T. .and. _aVal [2] == sz1 -> z1_codprd}) > 0
				_nPrcOri = ascan (_aPrcOri, {|_aVal| _aVal [1] == sz1 -> z1_grau})
				if _nPrcOri == 0
					u_help ("Grau '" + sz1 -> z1_grau + "' nao existe na variedade origem. Atualizacao da variedade '" + alltrim (sz1 -> z1_codprd) + "' (" + alltrim (fBuscaCpo ("SB1", 1, xfilial ("SB1") + sz1 -> z1_codprd, "B1_DESC")) + ") vai ficar incompleta.")
					sz1 -> (dbskip ())
					loop
				endif
				//u_log ('Atualizando ', sz1 -> z1_codprd, sz1 -> z1_grau)
				reclock ("SZ1", .F.)
				if _aTpPrc [1, 1]
					sz1 -> z1_prcrec = iif (_nPrcOri == 0, 0, _aPrcOri [_nPrcOri, 2] + _aPrcOri [_nPrcOri, 2] * _nPercent / 100)
				endif
				if _aTpPrc [2, 1]
					sz1 -> z1_prcCom = iif (_nPrcOri == 0, 0, _aPrcOri [_nPrcOri, 3] + _aPrcOri [_nPrcOri, 3] * _nPercent / 100)
				endif
				if _aTpPrc [3, 1]
					sz1 -> z1_prcdco = iif (_nPrcOri == 0, 0, _aPrcOri [_nPrcOri, 4] + _aPrcOri [_nPrcOri, 4] * _nPercent / 100)
				endif
				msunlock ()
			endif
			sz1 -> (dbskip ())
		enddo
		CursorArrow ()
		U_Help ("Copia concluida.")
	endif
return



// --------------------------------------------------------------------------
// Validacao produto na inclusao.
user function ML_SZ1VP ()
	local _lRet    := .T.

	// Permite a inclusao de codigos especificos.
	if left (sza -> za_cod, 3) == "MOC"
		// O certo seria validar na tabela 14 do ZX5, por exemplo...
		//_lRet = existcpo ("SX5", "Z6" + _sProduto)
		//if _lRet
		//	_sNomePrd = Tabela ("Z6", _sProduto)
		//endif
	elseif left (sza -> za_cod, 4) == "BASE"  // Para tabela 'base'
		_lRet = U_existZX5 ("13", sza -> za_safra + _sProduto)
		if _lRet
			_sNomePrd = U_RetZX5 ("13", sza -> za_safra + _sProduto, 'ZX5_13DESC')
		endif
	elseif left (sza -> za_cod, 4) == "DESC"  // Para listinha das uvas desclassificadas na serra
		if _sProduto != '000'
			u_help ("Para lista de preco das uvas desclassificadas informe produto 000")
			_lRet = .F.
		endif
	else
		_lRet = existcpo ('SB1') .and. existchav ('SZ1', sza->za_cod+_sProduto)
		if _lRet
			_sNomePrd  = fbuscacpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_DESC")
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacao produto base para copia e geracao dos dados no aCols.
user function ML_SZ1VC ()
	local _lRet     := .T.
	local _nCampo   := 0
	local _oGetD    := NIL
	local _nQual    := 0
	local _aAreaAnt := {}
	local _nPercent := 0
	local _nDecim   := 0
	sz1 -> (dbsetorder (1))
	if ! sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProdOri, .F.))
		msgalert ("Produto '" + _sProdOri + "' nao encontrado nesta tabela de precos.")
		_lRet = .F.
	else
		if inclui
			_nPercent = U_Get ("Deseja aplicar % aos valores copiados?", "N", 8, "999.9999", "", 0, .F., ".T.")
			if valtype (_nPercent) == "U"
				_nPercent = 0
			endif
			_nDecim = U_Get ("Maximo de casas decimais", "N", 4, "9", "", 0, .F., ".T.")
			if valtype (_nDecim) == "U"
				_nDecim = 0
			endif
			aCols = {}
			do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == sza -> za_cod .and. sz1 -> z1_codprd == _sProdOri
				aadd (aCols, aclone (U_LinVazia (aHeader)))
				for _nCampo = 1 to len (aHeader)
					N = len (aCols)
	
					// Soh quero os campos reais.
					if SZ1 -> (fieldpos (aHeader [_nCampo, 2])) > 0
						if alltrim (upper (aHeader [_nCampo, 2])) $ 'Z1_PRCREC/Z1_PRCCOM/Z1_PRCDCO'
							GDFieldPut (aHeader [_nCampo, 2], round (sz1 -> &(aHeader [_nCampo, 2]) + sz1 -> &(aHeader [_nCampo, 2]) * _nPercent / 100, _nDecim))
						else
							GDFieldPut (aHeader [_nCampo, 2], sz1 -> &(aHeader [_nCampo, 2]))
						endif
					endif
				next
				sz1 -> (dbskip ())
			enddo
		else
			_nQual = aviso ("Selecione preco", ;
			                "Qual dos precos deseja importar do produto " + alltrim (_sProdOri) + "?", ;
			                {"1-Recebimento", "2-Compra", "3-Governo", "0-Cancelar"}, ;
			                3, ;
			                "Selecione preco")
			if _nQual == 0 .or. _nQual == 4
				return
			elseif _nQual == 1
				_sCampo = "Z1_PRCREC"
			elseif _nQual == 2
				_sCampo = "Z1_PRCCOM"
			elseif _nQual == 3
				_sCampo = "Z1_PRCDCO"
			endif

			_nPercent = U_Get ("Deseja aplicar % aos valores copiados?", "N", 8, "999.9999", "", 0, .F., ".T.")
			if valtype (_nPercent) == "U" // .or. _nPercent <= 0
				_nPercent = 0
			endif

			_aAreaAnt = U_ML_SRArea ()
			sz1 -> (dbsetorder (1))  // Z1_FILIAL+Z1_TABELA+Z1_CODPRD+Z1_GRAU
			for N = 1 to len (aCols)
				if sz1 -> (dbseek (xfilial ("SZ1") + sza -> za_cod + _sProdOri + GDFieldGet ("Z1_GRAU"), .F.))
//					GDFieldPut (_sCampo, sz1 -> &(_sCampo))
					GDFieldPut (_sCampo, sz1 -> &(_sCampo) + sz1 -> &(_sCampo) * _nPercent / 100)
				else
					GDFieldPut (_sCampo, 0)
				endif
			next
			U_ML_SRArea (_aAreaAnt)
		endif

		// Atualiza tela do usuario
		N = 1
		_oGetD := CallMod2Obj()
		_oGetD:oBrowse:Refresh ()
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function ML_SZ1LK ()
	local _lRet    := .T.
	local _nLinha  := 0
	
	// Verifica campos obrigatorios
	if _lRet .and. ! GDDeleted (N)
		_lRet = MaCheckCols (aHeader, aCols, N, {})
	endif
	
	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"Z1_GRAU"}, 4)
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Tudo OK'
user function ML_SZ1TK ()
	local _lRet      := .T.
	local _nLinha    := 0
	local _nMenor    := 99
	local _nMaior    := 0
	
	if _lRet
		_lRet = U_ML_SZ1LK ()
	endif
	if _lRet
		// Verifica maior e menor graus encontrados.
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha)
				_nMenor = min (_nMenor, val (GDFieldGet ("Z1_GRAU", _nLinha)))
				_nMaior = max (_nMaior, val (GDFieldGet ("Z1_GRAU", _nLinha)))
			endif
		next
		// Verifica se foi deixada lacuna nos graus.
		for _nGrau = _nMenor to _nMaior
			_nLinha = ascan (aCols, {|_aVal| val (_aVal [GDFieldPos ("Z1_GRAU")]) == _nGrau})
			if _nLinha == 0 .or. GDDeleted (_nLinha)
				u_help ("Sequencia de graus incompleta. Nao ha linha com o grau " + strzero (_nGrau, 2))
				_lRet = .F.
			endif
		next
	endif
return _lRet
