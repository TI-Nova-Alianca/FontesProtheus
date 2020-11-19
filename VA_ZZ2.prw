// Programa...: VA_ZZ2
// Autor......: Robert Koch
// Data.......: 21/01/2010
// Descricao..: Tela de manutencao de dados para calculo de ST.
//
// Historico de alteracoes:
// 30/12/2010 - Robert - Implementado cadastro via modelo2.
// 15/07/2014 - Robert - Valida usuario pelo grupo 020 (tabela ZZU)
// 28/10/2014 - Robert - Passa a gravar evento padrao de alteracao de cadastros.
// 11/11/2014 - Robert - Passa a usar rotina de semaforo para ter acesso exclusivo a alteracao.
//                     - Passa a validar itens no 'Tudo OK' para permitir montar duas configuracoes
//                       de mesma UF com mesmo periodo, mas com produtos diferenciados.
//

// --------------------------------------------------------------------------
User Function VA_ZZ2 ()
	local   _aCores   := U_VA_ZZ2LG (.T.)
	private _sArqLog  := U_NomeLog ()
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Parametros para calculo de Substituicao Tributaria de ICMS"
	U_LogId ()
	
	aAdd (aRotina, {"Pesquisar",  "AxPesqui" , 0, 1})
	aAdd (aRotina, {"Visualizar", "U_VA_ZZ2A", 0, 2})
	aAdd (aRotina, {"Incluir"  ,  "U_VA_ZZ2A", 0, 3})
	aAdd (aRotina, {"Alterar"  ,  "U_VA_ZZ2A", 0, 4})
	aAdd (aRotina, {"Excluir"  ,  "U_VA_ZZ2E", 0, 5})
	aadd (aRotina, {"&Legenda" ,  "U_VA_ZZ2LG (.F.)", 0,5})
	
	dbSelectArea ("ZZ2")
	dbSetOrder (1)
	mBrowse(0, 0, 100, 100, "ZZ2",,,,, 2, _aCores)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function VA_ZZ2LG (_lRetCores)
   local _aCores := {}
   aadd (_aCores, {"zz2_ativo != 'S'", 'BR_VERMELHO'})
   aadd (_aCores, {"zz2_ativo == 'S'", 'BR_VERDE'})

   if ! _lRetCores
      BrwLegenda (cCadastro, "Legenda", {{"BR_VERDE",    "Ativo"}, ;
                                         {"BR_VERMELHO", "Inativo"}})
   else
      return _aCores
   endif
return



// --------------------------------------------------------------------------
// Tela de manutencao
user function VA_ZZ2a ()
	local _nLock       := 0
	local _aBotAdic    := {}

	// Campos do cabecalho. Deixar private para serem vistos em gatilhos e validacoes.
  	private _ZZ2Cod    := ""
  	private _ZZ2Ativo  := ""
	private _ZZ2Descri := space (50)
	private _ZZ2Fili   := ""
	private _ZZ2DtIni  := ctod ('')
	private _ZZ2DtFim  := ctod ('')
	private _ZZ2UF     := ""
	private _ZZ2Recol  := ""
	private _ZZ2MsgNF  := ""
	private _ZZ2Inscr  := ""

	// Variaveis de manipulacao e controle de dados, tela, etc.
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private aGets      := {}
	private aTela      := {}
	private _aCabec	   := {}	
	private _aItens    := {}

	private _nRegZZ2     := zz2 -> (recno ())  // Deixar private para ser vista em outras rotinas.
	
	nOpc := 2

	// Valida usuario.
	if inclui .or. altera
		if ! U_ZZUVL ('020')
			return
		endif
		nOpc = 4
	endif
	
	// Controle de semaforo.
	_nLock := U_Semaforo (procname ())
	if _nLock == 0
		return
	endif

	if inclui
		_ZZ2Cod    = CriaVar ("ZZ2_COD")
		_ZZ2Ativo  = CriaVar ("ZZ2_ATIVO")
		_ZZ2Descri = CriaVar ("ZZ2_DESCRI")
		_ZZ2Fili   = CriaVar ("ZZ2_FILI")
		_ZZ2DtIni  = CriaVar ("ZZ2_DTINI")
		_ZZ2DtFim  = CriaVar ("ZZ2_DTFIM")
		_ZZ2UF     = CriaVar ("ZZ2_UF")
		_ZZ2Recol  = CriaVar ("ZZ2_RECOL")
		_ZZ2MsgNF  = CriaVar ("ZZ2_MSGNF")
		_ZZ2Inscr  = CriaVar ("ZZ2_INSCR")
	else
		_ZZ2Cod    = zz2 -> zz2_cod
		_ZZ2Ativo  = zz2 -> zz2_ativo
		_ZZ2Descri = zz2 -> zz2_DESCRI
		_ZZ2Fili   = zz2 -> zz2_FILI
		_ZZ2DtIni  = zz2 -> zz2_DTINI
		_ZZ2DtFim  = zz2 -> zz2_DTFIM
		_ZZ2UF     = zz2 -> zz2_UF
		_ZZ2Recol  = zz2 -> zz2_recol
		_ZZ2MsgNF  = zz2 -> zz2_MSGNF
		_ZZ2Inscr  = zz2 -> zz2_INSCR
	endif
	
	// Gera aHeader e aCols.
	aHeader := U_GeraHead ("ZZ2", .F., {"ZZ2_COD", "ZZ2_ATIVO", "ZZ2_DESCRI", "ZZ2_FILI", "ZZ2_DTINI", "ZZ2_DTFIM", "ZZ2_UF", "ZZ2_RECOL", "ZZ2_MSGNF", "ZZ2_INSCR"})
	if ! inclui
		CursorWait ()
		aCols := U_GeraCols ("ZZ2", ;  // Alias
		                     2, ;  // Indice: ZZ2_FILIAL+ZZ2_COD+ZZ2_TPPROD+ZZ2_GRUPO
		                     xfilial ("ZZ2") + zz2 -> zz2_cod, ;  // Seek inicial
		                     'xfilial ("ZZ2") + zz2 -> zz2_cod == "' + xfilial ("ZZ2") + zz2 -> zz2_cod + '"', ;  // While
		                     aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
		                     .F.)  // Executa ou nao os gatilhos.
	CursorArrow ()
	else
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif
	
	// Cria botao adicional para a Modelo2
	//aadd (_aBotAdic, {"WEB", {|| U_VA_ZZ2I ()},"Importa"})
	
	// Variaveis do cabecalho da tela:
	aC:={}
	aadd (aC, {"_ZZ2Cod",    {15, 5},   "Codigo",                             "@!", "vazio () .or. U_VA_VCpo ()", "", inclui})
	aadd (aC, {"_ZZ2Ativo",  {15, 60},  "Ativo [S/N]",                        "@!", "", "",    .T.})
	aadd (aC, {"_ZZ2Descri", {15, 110}, "Descricao",                          "@!", "", "",    .T.})
	aadd (aC, {"_ZZ2DtIni",  {30, 5},   "Valido de",                          "@D", "", "",    .T.})
	aadd (aC, {"_ZZ2DtFim",  {30, 80},  "ate",                                "@D", "", "",    .T.})
	aadd (aC, {"_ZZ2Fili",   {30, 140}, "Filiais onde se aplica",             "@!", "vazio () .or. U_VA_VCpo ()", "SM0", .T.})
	aadd (aC, {"_ZZ2UF",     {45, 5},   "UF",                                 "@!", "", "12",  .T.})
	aadd (aC, {"_ZZ2Recol",  {45, 60},  "Recolhimento [Emissao/Nao recolhe]", "@!", "vazio () .or. pertence('EN')", "",  .T.})
	aadd (aC, {"_ZZ2Inscr",  {45, 205}, "Inscr.est.na UF",                    "@!", "", "",    .T.})
	aadd (aC, {"_ZZ2MsgNF",  {60, 5},   "Mensagem para NF",                   "@!", "", "",    .T.})
	
	//copia o acols e os campos do cabeçalho para comparar depois
	aadd (_aCabec, _ZZ2Cod )
	aadd (_aCabec, _ZZ2Ativo)
	aadd (_aCabec, _ZZ2Descri)
	aadd (_aCabec, _ZZ2DtIni)
	aadd (_aCabec, _ZZ2DtFim)
	aadd (_aCabec, _ZZ2Fili)
	aadd (_aCabec, _ZZ2UF)
	aadd (_aCabec, _ZZ2Recol)
	aadd (_aCabec, _ZZ2Inscr)
	aadd (_aCabec, _ZZ2MsgNF)
	
	aadd (_aItens, aclone (aCols))
	
	aR := {}
	_aJanela := {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}  // Janela (dialog) do modelo2
	aCGD := {115,30,118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		        aC, ;  // Cabecalho
		        aR, ;  // Rodape
		        aCGD, ;  // Coordenadas da getdados
		        nOpc, ;  // nOPC
		        'U_VA_ZZ2LK ()', ;  // Linha OK
		        "U_VA_ZZ2TK ()", ;  // Tudo OK
		        , ;  // Gets editaveis
		        , ;  // bloco codigo para tecla F4
		        , ;  // Campos inicializados
		        9999, ;  // Numero maximo de linhas
		        _aJanela, ;  // Coordenadas da janela
		        .T., ;  // Linhas podem ser deletadas.
		        .F., ;  // .T. = Janela deve ser maximizada
		        _aBotAdic)  // Botoes adicionais.
		
		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZZ2_FILIAL", xfilial ("ZZ2")})
		aadd (_aCposFora, {"ZZ2_COD",    _ZZ2Cod})
		aadd (_aCposFora, {"ZZ2_ATIVO",  _ZZ2Ativo})
		aadd (_aCposFora, {"ZZ2_DESCRI", _ZZ2Descri})
		aadd (_aCposFora, {"ZZ2_FILI",   _ZZ2Fili})
		aadd (_aCposFora, {"ZZ2_DTINI",  _ZZ2DtIni})
		aadd (_aCposFora, {"ZZ2_DTFIM",  _ZZ2DtFim})
		aadd (_aCposFora, {"ZZ2_UF",     _ZZ2UF})
		aadd (_aCposFora, {"ZZ2_RECOL",  _ZZ2Recol})
		aadd (_aCposFora, {"ZZ2_MSGNF",  _ZZ2MsgNF})
		aadd (_aCposFora, {"ZZ2_INSCR",  _ZZ2Inscr})
		
		// Grava dados do aCols.
		ZZ2 -> (dbsetorder (2))  // ZZ2_FILIAL+ZZ2_COD+ZZ2_TPPROD+ZZ2_GRUPO+ZZ2_SIMPLE
		for N = 1 to len (aCols)
			
			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if ZZ2 -> (dbseek (xfilial ("ZZ2") + _ZZ2Cod + GDFieldGet ("ZZ2_TPPROD") + GDFieldGet ("ZZ2_GRUPO") + GDFieldGet ("ZZ2_SIMPLE"), .F.))
				
				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted ()
					reclock ("ZZ2", .F.)
					ZZ2 -> (dbdelete ())
					msunlock ("ZZ2")
				else  // Alteracao
					reclock ("ZZ2", .F.)
					U_GrvACols ("ZZ2", N, _aCposFora)
					msunlock ("ZZ2")
				endif
				
			else  // A linha ainda nao existe no arquivo
				if GDDeleted ()
					loop
				else
					reclock ("ZZ2", .T.)
					U_GrvACols ("ZZ2", N, _aCposFora)
					msunlock ("ZZ2")
				endif
			endif
		next
	endif

	// Libera semaforo
	U_Semaforo (_nLock)
return



// --------------------------------------------------------------------------
// Exclusao total.
user function VA_ZZ2E ()
	//local _aArea := getarea ()
	local _ZZ2Cod := zz2 -> zz2_cod
	
	if ! U_ZZUVL ('020')
		return
	endif

	if msgyesno ("Confirma a exclusao de todos os relacionamentos para o codigo " + zz2 -> zz2_cod + "?","Excluir")
		zz2 -> (dbsetorder (2))  // ZZ2_FILIAL+ZZ2_COD+ZZ2_TPPROD+ZZ2_GRUPO
		zz2 -> (dbseek (xfilial ("ZZ2") + _ZZ2Cod, .T.))
		do while ! zz2 -> (eof ()) .and. zz2 -> zz2_filial == xfilial ("ZZ2") .and. zz2 -> zz2_cod == _ZZ2Cod
			reclock ("ZZ2", .F.)
			zz2 -> (dbdelete ())
			msunlock ()
			zz2 -> (dbskip ())
		enddo
		u_help ("Dados excluidos.")
	endif
return



// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function VA_ZZ2LK ()
	local _lRet    := .T.
	//local _nLinha  := 0
	
	// Verifica campos obrigatorios
	if _lRet .and. ! GDDeleted ()
		_lRet = MaCheckCols (aHeader, aCols, N, {})
	endif
	
	// Verifica campos exclusivos
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZ2_TPPROD")) .and. ! empty (GDFieldGet ("ZZ2_GRUPO"))
		u_help ("Os campos '" + alltrim (RetTitle ("ZZ2_TPPROD")) + "' e '" + alltrim (RetTitle ("ZZ2_GRUPO")) + "' nao devem ser informados juntos.")
		_lRet = .F.
	endif
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("ZZ2_TPPROD")) .and. empty (GDFieldGet ("ZZ2_GRUPO"))
		u_help ("Campo '" + alltrim (RetTitle ("ZZ2_TPPROD")) + "' ou '" + alltrim (RetTitle ("ZZ2_GRUPO")) + "' deve ser informado.")
		_lRet = .F.
	endif

	// Verifica linhas duplicadas
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZ2_TPPROD"))
		_lRet = GDCheckKey ({"ZZ2_TPPROD", "ZZ2_SIMPLE"}, 4)
	endif
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZ2_GRUPO"))
		_lRet = GDCheckKey ({"ZZ2_GRUPO", "ZZ2_SIMPLE"}, 4)
	endif

return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Tudo OK'
user function VA_ZZ2TK ()
	local _lRet     := .T.
	local _aCampos  := {'_ZZ2Cod','_ZZ2Ativo','_ZZ2Fili','_ZZ2DtIni','_ZZ2DtFim','_ZZ2UF','_ZZ2Recol'}
	local _sQuery   := ""
	local _aFiliais := U_SeparaCpo (_ZZ2Fili, "/")
	local _aCabDif  := {}
	local _aItDif   := {}
	local _msg      := ''
	local _oEvento  := NIL
	local _n        := N
	local _nCampo   := 0
	local _nFilial  := 0
	local _x        := 0
	local i         := 0
	local _y        := 0

	_lRet = Obrigatorio (aGets, aTela)

	if _lRet
		for _nCampo = 1 to len (_aCampos)
			if empty (&(_aCampos [_nCampo]))
				u_help ("Campo '" + substr (_aCampos [_nCampo], 5) + "' deve ser informado.")
				_lRet = .F.
				exit
			endif
		next
	endif

	if _lRet
		if _ZZ2DtIni > _ZZ2DtFim
			_lRet = .F.
			u_help ("Data de termino menor que data de inicio.")
		endif
	endif

	// Verifica sobreposicao de parametros.
	if _lRet
		_sQuery := ""
		_sQuery += "SELECT DISTINCT ZZ2_COD AS CODIGO, ZZ2_DESCRI AS DESCRICAO, ZZ2_UF AS UF, ZZ2_DTINI AS DATA_INICIO, ZZ2_DTFIM AS DATA_FIM"
		_sQuery +=  " FROM " + RetSQLName ("ZZ2") + " ZZ2"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZZ2_FILIAL = '" + xfilial ("ZZ2") + "'"
		_sQuery +=   " AND ZZ2_COD   != '" + _ZZ2Cod + "'"
		_sQuery +=   " AND ZZ2_ATIVO  = 'S'"
		_sQuery +=   " AND ZZ2.ZZ2_UF = '" + _ZZ2UF + "'"

		// Nao pode sobrepor os itens (tipos/grupos de produtos)
		for N = 1 to len (aCols)
			if ! GDDeleted ()
				_sQuery += " AND ZZ2_TPPROD = '" + GDFieldGet ("ZZ2_TPPROD") + "'"
				_sQuery += " AND ZZ2_GRUPO  = '" + GDFieldGet ("ZZ2_GRUPO")  + "'"
				_sQuery += " AND ZZ2_SIMPLE IN ('T', '" + GDFieldGet ("ZZ2_SIMPLE") + "')"
			endif
		next

		// Nao pode sobrepor nenhuma data
		_sQuery += " AND ((ZZ2.ZZ2_DTINI <= '" + dtos (_ZZ2DtIni) + "' AND ZZ2.ZZ2_DTFIM >= '" + dtos (_ZZ2DtIni) + "')"
		_sQuery += "  OR  (ZZ2.ZZ2_DTINI >= '" + dtos (_ZZ2DtIni) + "' AND ZZ2.ZZ2_DTFIM <= '" + dtos (_ZZ2DtFim) + "')"
		_sQuery += "  OR  (ZZ2.ZZ2_DTINI <= '" + dtos (_ZZ2DtFim) + "' AND ZZ2.ZZ2_DTFIM >= '" + dtos (_ZZ2DtFim) + "')"
		_sQuery += "  OR  (ZZ2.ZZ2_DTINI <= '" + dtos (_ZZ2DtIni) + "' AND ZZ2.ZZ2_DTFIM >= '" + dtos (_ZZ2DtFim) + "'))"

		// Testa com todas as filiais
		_sQuery += "   and ("
		for _nFilial = 1 to len (_aFiliais)
			_sQuery += " ZZ2.ZZ2_FILI LIKE '%" + _aFiliais [_nFilial] + "%'"
			if _nFilial < len (_aFiliais)
				_sQuery += " OR "
			endif
		next
		_sQuery += ")"
		u_log (_sQuery)

		_aRetQry = U_Qry2Array (_sQuery, .F., .T.)
		if len (_aRetQry) > 1  // Desconsiderar a linha com os cabecalhos de colunas
			_lRet = .F.
			u_help ("A configuracao informada se sobrepoe a outra(s) ja existente(s). Verifique UF, filiais e data de inicio/termino. Na tela seguinte serao mostradas as configuracoes em conflito.")
			u_F3Array (_aRetQry)
		endif
    endif
         
    // Verifica se alguma coisa foi alterada e monta mensagem para e-mail.
    if _lRet .and. altera
    	if _aCabec[1] <> _ZZ2Cod
			aadd(_aCabDif,"Campo 'Código' era '" + alltrim(_aCabec[1]) + "' e foi alterado para '" + alltrim(_ZZ2Cod)+ "' ") 
		endif
		if _aCabec[2] <> _ZZ2Ativo
			aadd(_aCabDif,"Campo 'Ativo[S/N]' era '" + alltrim(_aCabec[2]) + "' e foi alterado para '" + alltrim(_ZZ2Ativo)+ "' ")  
		endif	
		if _aCabec[3] <> _ZZ2Descri                                         
			aadd(_aCabDif,"Campo 'Descricao' era '" + alltrim(_aCabec[3]) + "' e foi alterado para '" + alltrim(_ZZ2Descri)+ "' ") 
		endif	
		if _aCabec[4] <> _ZZ2DtIni
			aadd(_aCabDif,"Campo 'Valido de' era '" + alltrim(_aCabec[4]) + "' e foi alterado para '" + alltrim(_ZZ2DtIni)+ "' ")  
		endif	
		if _aCabec[5] <> _ZZ2DtFim                                          
			aadd(_aCabDif,"Campo 'Valido ate' era '" + alltrim(_aCabec[5]) + "' e foi alterado para '" + alltrim(_ZZ2DtFim)+ "' ") 
		endif	
		if _aCabec[6] <> _ZZ2Fili                                           
			aadd(_aCabDif,"Campo 'Filiais onde se aplica' era '" + alltrim(_aCabec[6]) + "' e foi alterado para '" + alltrim(_ZZ2Fili)+ "' ") 
		endif	
		if _aCabec[7] <> _ZZ2UF                                             
			aadd(_aCabDif,"Campo 'UF' era '" + alltrim(_aCabec[7]) + "' e foi alterado para '" + alltrim(_ZZ2UF)+ "' ") 
		endif	
		if _aCabec[8] <> _ZZ2Recol                                          
			aadd(_aCabDif,"Campo 'Recolhimento' era '" + alltrim(_aCabec[8]) + "' e foi alterado para '" + alltrim(_ZZ2Recol)+ "' ") 
		endif	
		if _aCabec[9] <> _ZZ2Inscr                                          
			aadd(_aCabDif,"Campo 'Insc.Est.na UF' era '" + alltrim(_aCabec[9]) + "' e foi alterado para '" + alltrim(_ZZ2Inscr)+ "' ")  
		endif	
		if _aCabec[10] <> _ZZ2MsgNF                                         
			aadd(_aCabDif,"Campo 'Mensagem para NF' era '" + alltrim(_aCabec[10]) + "' e foi alterado para '" + alltrim(_ZZ2MsgNF)+ "' ")  
		endif	
		
		for _x = 1 to len(acols)
			if _x <= len (_aItens)
				for _y = 1 to len(acols[1])
					if acols[_x][_y] <> _aItens[1][_x][_y]
						aadd(_aItDif,"Campo '" + aheader[_y][1] + "' do item '" + cvaltochar(_x) + "' era '" + iif(valtype(_aItens[1][_x][_y]) == "N",cvaltochar(_aItens[1][_x][_y]),_aItens[1][_x][_y]) + "' e foi alterado para '" + iif(valtype(acols[_x][_y]) == "N",cvaltochar(acols[_x][_y]), acols[_x][_y]) + "' ")
					endif
				next _y
			endif
		next _x
		
		if len(_aCabDif) > 0
			_msg += "Campos do cabeçalho que foram alterados: " + chr(13) + chr(10)
			for i = 1 to len(_aCabDif)
				_msg += alltrim(_aCabDif[i]) + chr(13) + chr(10)
			next i
			_msg += chr(13) + chr(10)
		endif
		
		if len(_aItDif) > 0 
			_msg += "Campos dos itens que foram alterados: " + chr(13) + chr(10)
			for i = 1 to len(_aItDif)
				_msg += alltrim(_aItDif[i]) + chr(13) + chr(10)
			next i
		endif
		
		// Grava evento para posterior consulta.
		if !empty(_msg)
			//u_help (_msg)
			_oEvento := ClsEvent():new ()
			processa ({||_oEvento:AltCadast ("ZZ2", _ZZ2Cod, _nRegZZ2, _msg)})
		endif 
		
    endif

    N := _n
return _lRet
