// Programa...: VA_RUSC
// Autor......: Robert Koch
// Data.......: 19/03/2010
// Descricao..: Tela de informacao da classificacao das uvas finas recebidas durante a safra.
//
// Historico de alteracoes:
// 26/01/2016 - Robert - Rotina restrita ao grupo 056 do ZZU.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function va_rusC ()
	private aRotina    := {}
	private cString    := "SZE"
	private cCadastro  := "Classificacao de uva recebida na safra"
	
	private _ZFEMBALAG := ""  // Deixar private para ser vista por outras rotinas.
	private _sBalanca  := ""  // Deixar private para ser vista por outras rotinas.
	private _lLeitBar  := ""  // Deixar private para ser vista por outras rotinas.
	private _lBalEletr := ""  // Deixar private para ser vista por outras rotinas.
	private _sPortaBal := ""  // Deixar private para ser vista por outras rotinas.
	private _sModelBal := ""  // Deixar private para ser vista por outras rotinas.
	private _nMultBal  := ""  // Deixar private para ser vista por outras rotinas.
	private _nPesoEmb  := ""  // Deixar private para ser vista por outras rotinas.
	private _lImpTick  := ""  // Deixar private para ser vista por outras rotinas.
	private _sPortTick := ""  // Deixar private para ser vista por outras rotinas.
	private _lLeBrix   := .F. // Deixar private para ser vista por outras rotinas.
	private _nQViasTk1 := 0   // Deixar private para ser vista por outras rotinas.
	private _nQViasTk2 := 0   // Deixar private para ser vista por outras rotinas.
	private _lTickPeso := .F. // Deixar private para ser vista por outras rotinas.

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('056', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	aadd (aRotina, {"&Pesquisar"        , "AxPesqui",       0,1})
	aadd (aRotina, {"&Visualizar"       , "U_VA_RUS2 (2)",  0,2})
	aadd (aRotina, {"Alterar"           , "U_VA_RUSC2 (4)", 0,4})
 	aadd (aRotina, {"Legenda"           , "Allwaystrue",    0,4})  // Pelo menos 4 posicoes para atender as manhas da GetDados...
	
	DbSelectArea(cString)
	mBrowse(,,,,cString,,,,,2)
return



// --------------------------------------------------------------------------
// Atualiza os campos de classificacao da uva.
user function VA_RUSC2 (_nOpc)
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _oDlg        := NIL
	local _lContinua   := .T.
	local _n           := 0
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private agets      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private aTela      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private _oGetD     := NIL
	private inclui     := (_nOpc == 3)
	private altera     := (_nOpc == 4)
	private _lDlgOK    := .F.  // Para retorno da tela modelo3.

	if _lContinua
		
		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("SZE", inclui, inclui)
		
		// Monta aHeader e aCols para a getdados.
		aHeader := aclone (U_GeraHead ("SZF", .F., {}, {}, .F.))
		if ! inclui
			aCols := aclone (U_GeraCols ("SZF", ;  // Alias
			                     1, ;  // Indice: filial + safra + carga + item
			                     xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, ;  // Seek inicial
			                     'xfilial ("SZF") + szf -> zf_safra + szf -> zf_carga == "' + xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga + '"', ;  // While
			                     aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
			                     .F.))  // Executa ou nao os gatilhos.

			// Preenche conteudo dos campos virtuais
			for _n = 1 to len (aCols)
				N = _n
				GDFieldPut ("ZF_DESCRI", fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_DESC"))
			next
		else
			aCols := {}
			aadd (aCols, aclone (U_LinVazia (aHeader)))
	   endif
	endif
	
	if _lContinua
		
		// Monta tela para o usuario fazer as manutencoes
		N = 1
		define msDialog _oDlg from 0,0 to oMainWnd:nClientHeight - 50 , oMainWnd:nClientwidth - 4 of oMainWnd pixel title cCadastro
		
		// Enchoice para visualizacao do arquivo.
		_oEnch1 := MsMGet():New("SZE", ;  // Alias
		1, ;      // nReg
		2, ;  // Opcao do aRotina
		NIL, ;
		NIL, ;
		NIL, ;
		NIL, ;    // Array com nomes de campos a exibir (pra mim nao funcionou)
		{15, 2, _oDlg:nClientHeight / 5 - 5, _oDlg:nClientWidth / 2 - 10}, ;  // Posicionamento na tela
		NIL, ;    // Array com nomes de campos editaveis (pra mim trancou todos)
		NIL, ;    // 3
		NIL, ;
		NIL, ;
		NIL, ;    // "A415VldTOk"
		_oDlg, ;  // Dialogo onde vai ser criada
		NIL, ;    // logico
		NIL, ;    // lMemory
		.F., ;    // .T. = todos os campos em uma unica coluna
		NIL, ;    // "aSvATela"
		.T., ;
		NIL)      // lProperty
		
		_oGetD := MSGetDados ():New (_oDlg:nClientHeight / 5 + 5, ;       // Limite superior
		                             2, ;                                 // Limite esquerdo
		                             _oDlg:nClientHeight / 2 - 45, ;      // Limite inferior
		                             _oDlg:nClientWidth / 2 - 10, ;       // Limite direito
		                             _nOpc, ;                             // opcao do mbrowse (aRotina)
		                             "U_VA_RUSCL ()", ;                   // Linha ok
		                             "allwaystrue ()", ;                  // Tudo ok
		                             , ;                                  // Campos com incremento automatico
		                             .F., ;                               // Permite deletar linhas
		                             , ;                                  // Vetor de campos que podem ser alterados
		                             , ;                                  // Reservado
		                             .F., ;                               // Se .T., a primeira coluna nunca pode ficar vazia
		                             len (aCols), ;                       // Maximo de linhas permitido
		                             "allwaystrue ()", ;                  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
		                             "allwaystrue ()", ;                  // Executada ao teclar CTRL + DEL
		                             , ;                                  // Reservado
		                             "allwaystrue ()", ;                  // Executada para validar delecao de uma linha
		                             _oDlg)                               // Objeto onde serah criada
		
		_bBotaoOK  = {|| iif (U_VA_RUSCT (), (_lDlgOK := .T., _oDlg:End ()), NIL)}
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}
		activate dialog _oDlg on init EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic)
	endif

	// Tratamento caso o usuario tenha confirmado a tela modelo3.
	if _lContinua .and. _lDlgOK
		_Grava (_nOpc)
	endif
return



// --------------------------------------------------------------------------
// Valida 'Linha OK'.
user function VA_RUSCL ()
	local _lRet    := .T.
	local _sVarUva := ""

	if _lRet .and. ! GDDeleted ()
		_sVarUva = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_VARUVA")
		if _sVarUva == "C"
			if ! empty (GDFieldGet ("ZF_PRM02")) .or.  ! empty (GDFieldGet ("ZF_PRM03")) .or.  ! empty (GDFieldGet ("ZF_PRM04")) .or.  ! empty (GDFieldGet ("ZF_PRM05")) .or.  ! empty (GDFieldGet ("ZF_PRM99"))
				u_help ("Classificacao da uva so deve ser informada para uvas finas",, .t.)
				_lRet = .F.
			endif
		else
			if empty (GDFieldGet ("ZF_PRM02")) .or.  empty (GDFieldGet ("ZF_PRM03")) .or.  empty (GDFieldGet ("ZF_PRM04")) .or.  empty (GDFieldGet ("ZF_PRM05")) .or.  empty (GDFieldGet ("ZF_PRM99"))
				//_lRet = MsgNoYes ("Classificacao incompleta. Confirma assim mesmo?")
				u_help ("Classificacao incompleta.",, .t.)
				_lRet = .f.
			endif
		endif
  	endif
	
return _lRet



// --------------------------------------------------------------------------
// Valida 'Linha OK'.
user function VA_RUSCT ()
	local _lRet    := .T.

	// Valida 'Linha OK' para a linha atual.
	if _lRet
		_lRet = U_VA_RUSCL ()
	endif
	
return _lRet



// --------------------------------------------------------------------------
// Gravacao dos registros.
Static Function _Grava (_nOpc)
	local _lContinua := .T.
	local _n		 := 0
	
	// Gravacao das linhas do aCols.
	sd1 -> (dbsetorder (1))  // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	SZF -> (dbsetorder (1))  // zf_FILIAL+zf_COD+zf_PRODUTO
	for _n = 1 to len (aCols)
		N := _n
			
		if szf -> (dbseek (xfilial ("SZF") + m->ze_safra + m->ze_carga + GDFieldGet ("ZF_ITEM") , .F.))

			// Grava somente campos de interesse da qualidade / agronomia.
			reclock ("SZF", .F.)
			SZF -> zf_prm02   = GDFieldGet ("ZF_PRM02")
			SZF -> zf_prm03   = GDFieldGet ("ZF_PRM03")
			SZF -> zf_prm04   = GDFieldGet ("ZF_PRM04")
			SZF -> zf_prm05   = GDFieldGet ("ZF_PRM05")
			SZF -> zf_prm99   = GDFieldGet ("ZF_PRM99")
			SZF -> zf_HrReceb = GDFieldGet ("ZF_HRRECEB")
			SZF -> zf_Insp1   = GDFieldGet ("ZF_INSP1")
			SZF -> zf_Insp2   = GDFieldGet ("ZF_INSP2")
			SZF -> zf_InspVi1 = GDFieldGet ("ZF_INSPVI1")
			SZF -> zf_InspVi2 = GDFieldGet ("ZF_INSPVI2")
			SZF -> zf_obs     = GDFieldGet ("ZF_OBS")
			msunlock ()

			// Tambem atualiza arquivo SD1, caso exista.
			if ! empty (sze -> ze_nfger)
				_sChaveSD1 = xfilial ("SD1") + sze -> ze_nfger + sze -> ze_serie + sze -> ze_assoc + sze -> ze_lojasso + GDFieldGet ("ZF_PRODUTO")
				sd1 -> (dbseek (_sChaveSD1, .T.))
				do while ! sd1 -> (eof ()) .and. sd1 -> d1_filial + sd1 -> d1_doc + sd1 -> d1_serie + sd1 -> d1_fornece + sd1 -> d1_loja + sd1 -> d1_cod == _sChaveSD1
					if sd1 -> d1_quant == GDFieldGet ("ZF_PESO") .and. sd1 -> d1_grau == GDFieldGet ("ZF_GRAU")

						// Grava somente campos de interesse da qualidade / agronomia.
						reclock ("SD1", .F.)
						sd1 -> d1_prm02 = GDFieldGet ("ZF_PRM02")
						sd1 -> d1_prm03 = GDFieldGet ("ZF_PRM03")
						sd1 -> d1_prm04 = GDFieldGet ("ZF_PRM04")
						sd1 -> d1_prm05 = GDFieldGet ("ZF_PRM05")
						sd1 -> d1_prm99 = GDFieldGet ("ZF_PRM99")
						msunlock ()
						exit
					endif
					sd1 -> (dbskip ())
				enddo
			endif
		else
			u_help ("Erro: Item nao foi mais encontrado nesta carga!")
			_lContinua = .F.
			exit
		endif
	next
Return
