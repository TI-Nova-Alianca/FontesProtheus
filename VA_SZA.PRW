// Programa...: VA_SZA
// Autor......: Robert Koch
// Data.......: 17/01/2009
// Descricao..: Tela de manutencao de listas de precos de uva para a safra.
//
// Historico de alteracoes:
// 27/03/2009 - Robert - Verifica se estah rodando em TOP ou nao.
// 05/11/2009 - Robert - Nao executa se nao estiver rodando em TOP.
// 16/07/2010 - Robert - Importa precos de uma tabela para outra.
// 06/01/2011 - Robert - Verifica existencia da tabela no SZ7 antes de excluir.
// 08/07/2017 - Robert - Implementada replicacao da tabela BASE<ano> para a tabela atual.
// 23/11/2018 - Robert - A partir de 2019 nao pretendo mais usar a tabela SZ7.
// 21/03/2020 - Robert - Nao verifica mais tabela SZ7 para nenhum caso.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function va_sza()
//	local _aCols    := {}
//	local _aOpcoes  := 0
	local _nOpcao   := 0
	local _sFilTop  := ''
	private aRotina := {}
	private _nModelTab := 0

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	_nModelTab = aviso ("Modelo de tabela", ;
		"As tabelas de precos de uva foram sendo aprimoradas ao longo do tempo e, por isso, nao ha compatibilidade entre todas.", ;
		{"Versao 1", "Versao 2", "Versao 3"}, 3, "Selecione modelo de tabela de precos")
	
	do case
	
	// Modelo SZA X SZ1
	case _nModelTab == 1
		aadd (aRotina, {"&Pesquisar"        , "AxPesqui",  0,1})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"&Incluir"          , "AxInclui",  0,3})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"&Alterar"          , "AxAltera",  0,4})
		aadd (aRotina, {"P&recos-atu.man"   , "U_VA_SZAP", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"P&recos-base"      , "U_VA_SZAP2", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"&Excluir"          , "U_VA_SZAE", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"&Copia para"       , "U_VA_SZAC", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"I&mporta de"       , "U_VA_SZAI", 0,4})
		private cString   := "SZA"
		private cCadastro := "Listas de precos safra"
		dbselectarea ("SZA")
		dbSetOrder (1)
		_sFilTop = "ZA_MODELO = '1'"
		mBrowse(,,,,"SZA",,,,,,,,,,,,,,_sFilTop)
	
	// Modelo usando somente ZX5 (tabelas 13 e 14)
	case _nModelTab == 2
		u_help ("ATENCAO: use este modelo apenas para safras ate 2023. A partir de 2024, use o modelo 3.")
/*
		_aOpcoes = {}
		aadd (_aOpcoes, {.F., "Grupos para tabela de preco", "ZX5_13"})
		aadd (_aOpcoes, {.F., "Grupos X variedades para tabela de preco", "ZX5_14"})
		_aCols = {}
		aadd (_aCols, {2, "Opcoes",  280,  ""})
		U_MBArray (@_aOpcoes, "Selecione cadastro", _aCols, 1, 700, 450, , ".T.")
		for _nOpcao = 1 to len (_aOpcoes)
			if _aOpcoes [_nOpcao, 1]
				if _aOpcoes [_nOpcao, 3] == "ZX5_13"
					U_ZX513 ()
				if _aOpcoes [_nOpcao, 3] == "ZX5_14"
					U_ZX513 ()
				else
					u_help ("Opcao sem tratamento: '" + _aOpcoes [_nOpcao, 3] + "'.")
				endif
			endif
		next
*/
		_nOpcao = aviso ("Selecione cadastro", ;
			"Seleciona qual cadastro deseja alterar: Precos dos grupos ou Variedades de cada grupo", ;
			{"Grupos", "Variedades"}, 3, "Selecione modelo")
		if _nOpcao == 1
			U_ZX5_13 ()
		elseif _nOpcao == 2
			U_ZX5_14 ()
		endif

	// Modelo usando SZA x ZX5
	case _nModelTab == 3
		aadd (aRotina, {"&Pesquisar"        , "AxPesqui",  0,1})
		aadd (aRotina, {"&Incluir"          , "AxInclui",  0,3})
		aadd (aRotina, {"&Alterar"          , "AxAltera",  0,4})
		aadd (aRotina, {"P&recos-atu.man"   , "U_VA_SZAP", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"P&recos-base"      , "U_VA_SZAP2", 0,4})
		aadd (aRotina, {"&Excluir"          , "U_VA_SZAE", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"&Copia para"       , "U_VA_SZAC", 0,4})
		// Formato de tabela em desuso. Precisaria dar manutencao nos programas ---> aadd (aRotina, {"I&mporta de"       , "U_VA_SZAI", 0,4})
//		private cString   := "SZA"
//		private cCadastro := "Listas de precos safra"
		dbselectarea ("SZA")
		dbSetOrder (1)
		_sFilTop = "ZA_MODELO = '3'"
		mBrowse(,,,,"SZA",,,,,,,,,,,,,,_sFilTop)

	otherwise
		u_help ("Modelo de tabela de preco de uva sem tratamento.",, .t.)
	endcase
return



// --------------------------------------------------------------------------
// Manutencao dos precos dos produtos.
User Function VA_SZAP ()

	// Os precos ficam na tabela SZ1. Para que nao aparecam todas as tabelas, filtra
	// o SZ1 e chama programa original de manutencao do SZ1.
	dbselectarea ("SZ1")
	set filter to &("Z1_TABELA == '" + sza -> za_cod + "'")
	U_ML_SZ1 ()
	dbselectarea ("SZ1")
	set filter to
return


/*
// --------------------------------------------------------------------------
// Atualiza tabela de precos pela lista de precos base da mesma safra.
User Function VA_SZAP2 ()
	local _lContinua := .T.
	local _sTabBase  := 'BASE' + right (sza -> za_safra, 2)

	if _lContinua
		_lContinua = U_MsgNoYes ("Esta rotina faz uma leitura da tabela de precos base (" + _sTabBase + ") e joga os precos para a tabela " + sza -> za_cod + "." + ;
		                         " Importante: a tabela base deve ja estar cadastrada, e seus itens devem representar grupos de variedades, previamente cadastrados na tabela 13 no ZX5." + ;
		                         " A relacao de quais variedades pertencem a cada grupo eh feita pela tabela 14 do ZX5. Deseja continuar?")
	endif
	if _lContinua
		// Zera os valores da nova tabela para evitar que fiquem valores antigos.
		_oSQL := CLSSQL ():New ()
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("SZ1") + " SET Z1_PRCREC = 0, Z1_PRCCOM = 0, Z1_PRCDCO = 0 WHERE Z1_FILIAL = '" + xfilial ("SZ1") + "' AND Z1_TABELA = '" + sza -> za_cod + "'"
		_oSQL:Exec ()

		_oSQL := CLSSQL ():New ()
		_oSQL:_sQuery := "UPDATE SZ1 SET Z1_PRCCOM = BASE.Z1_PRCCOM"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZ1") + " SZ1, "
		_oSQL:_sQuery +=             RetSQLName ("SZ1") + " BASE, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " GRUPOS, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " PRODUTOS "
		_oSQL:_sQuery += " WHERE SZ1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SZ1.Z1_FILIAL = '" + xfilial ("SZ1") + "'"
		_oSQL:_sQuery +=   " AND SZ1.Z1_TABELA = '" + sza -> za_cod + "'"
		_oSQL:_sQuery +=   " AND SZ1.Z1_CODPRD = PRODUTOS.ZX5_14PROD"
		_oSQL:_sQuery +=   " AND SZ1.Z1_GRAU   = BASE.Z1_GRAU"
		_oSQL:_sQuery +=   " AND GRUPOS.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND GRUPOS.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND GRUPOS.ZX5_TABELA = '13'"
		_oSQL:_sQuery +=   " AND GRUPOS.ZX5_13SAFR = '" + sza -> za_safra + "'"
		_oSQL:_sQuery +=   " AND PRODUTOS.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND PRODUTOS.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND PRODUTOS.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=   " AND PRODUTOS.ZX5_14GRUP = GRUPOS.ZX5_13GRUP"
		_oSQL:_sQuery +=   " AND PRODUTOS.ZX5_14SAFR = '" + sza -> za_safra + "'"
		_oSQL:_sQuery +=   " AND BASE.D_E_L_E_T_ = ''
		_oSQL:_sQuery +=   " AND BASE.Z1_FILIAL = '" + xfilial ("SZ1") + "'
		_oSQL:_sQuery +=   " AND BASE.Z1_TABELA = '" + _sTabBase + "'"
		_oSQL:_sQuery +=   " AND BASE.Z1_CODPRD = GRUPOS.ZX5_13GRUP"
		_oSQL:Log ()
		_oSQL:Exec ()
	endif
return



// --------------------------------------------------------------------------
// Exclusao total.
user function VA_SZAE ()
	local _sSQL   := ""
	//local _sQuery := ""
	//local _nUsado := 0

	if msgyesno ("Confirma a exclusao desta tabela e todos os precos relacionados a ela?","Excluir")
		CursorWait ()
		_sSQL := ""
		_sSQL += " Update " + RetSQLName ("SZ1")
		_sSQL +=    " set D_E_L_E_T_ = '*'" //, R_E_C_D_E_L_ = R_E_C_N_O_"
		_sSQL +=  " where D_E_L_E_T_ = ''"
		_sSQL +=    " and Z1_FILIAL  = '" + xfilial ("SZ1") + "'"
		_sSQL +=    " and Z1_TABELA  = '" + sza -> za_cod + "'"
		u_log (_ssql)
		if TCSQLExec (_sSQL) < 0
			u_help ("Erro na exclusao dos itens da tabela")
		else
			_sSQL := ""
			_sSQL += " Update " + RetSQLName ("SZA")
			_sSQL +=    " set D_E_L_E_T_ = '*'" //, R_E_C_D_E_L_ = R_E_C_N_O_"
			_sSQL +=  " where D_E_L_E_T_ = ''"
			_sSQL +=    " and ZA_FILIAL  = '" + xfilial ("SZA") + "'"
			_sSQL +=    " and ZA_COD     = '" + sza -> za_cod + "'"
			u_log (_ssql)
			if TCSQLExec (_sSQL) < 0
				u_help ("Erro na exclusao da tabela")
			endif
		endif
		CursorArrow ()
	endif
return



// --------------------------------------------------------------------------
// Copia uma tabela para outra, inclusive com seus precos.
User Function VA_SZAC ()
	local _sTabOrig := sza -> za_cod
	local _sQuery  := ""
	local _sAliasQ := ""
	//local _aAreaQ  := {}
	local _nCampo  := 0
	local _sCampo  := ""
	local _xDado   := NIL
	local _nFatorR := 1
	local _nFatorC := 1

	if ! msgyesno ("Esta rotina permite que uma nova tabela de precos seja criada com os precos da tabela '" + _sTabOrig + "'. Para isso, confirme o cadastro na tela seguinte e, depois, aguarde a copia dos valores.","Confirmar")
		return
	endif

	// Abre tela normal para inclusao. Se o usuario confirmar, prossegue o processamento.
	if axinclui ("SZA", sza -> (recno ()), 3, NIL, "allwaystrue ()") == 1

		_nFatorR = _Get ("Fator de multiplicacao p/preco entrada (1=permanece igual)", "N", 6, "@E 999.99", "", 1, .F., ".t.")
		_nFatorC = _Get ("Fator de multiplicacao p/preco compra (1=permanece igual)", "N", 6, "@E 999.99", "", 1, .F., ".t.")
		_nFatorR = iif (_nFatorR == NIL, 1, _nFatorR)
		_nFatorC = iif (_nFatorC == NIL, 1, _nFatorC)
	
		CursorWait ()
		_sQuery := ""
		_sQuery += " select *"
		_sQuery +=   " from " + RetSQLName ("SZ1")
		_sQuery +=  " where D_E_L_E_T_ = ''"
		_sQuery +=    " and Z1_FILIAL  = '" + xfilial ("SZ1") + "'"
		_sQuery +=    " and Z1_TABELA  = '" + _sTabOrig + "'"
		_sAliasQ = GetNextAlias ()
		u_log (_squery)
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		count to _nRecCount
		procregua (_nRecCount)
		incproc ("Copiando")
		(_sAliasQ) -> (DbGoTop())
		Do While !(_sAliasQ) -> (Eof())
			incproc ()
			reclock ("SZ1", .T.)
			for _nCampo = 1 to sz1 -> (fcount ())
				_sCampo = alltrim ((_sAliasQ) -> (fieldname (_nCampo)))
				
				// Soh quero os campos da query que existem no destino (R_E_C_N_O_ nao me interessa, por exemplo)
				if ("SZ1") -> (fieldpos (_sCampo)) > 0
					
					// Preciso tratar alguns campos e seus dados, por isso uso uma variavel para cada coisa.
					_xDado = (_sAliasQ) -> &(_sCampo)
					if _sCampo == "Z1_FILIAL"
						_xDado := xfilial ("SZ1")
					elseif _sCampo == "Z1_TABELA"
						_xDado := sza -> za_cod
					elseif _sCampo == "Z1_PRCREC"
						_xDado *= _nFatorR
					elseif _sCampo == "Z1_PRCCOM"
						_xDado *= _nFatorC
					endif
					("SZ1") -> &(_sCampo) = _xDado
				endif
			next
			sz1 -> z1_filial = xfilial ("SZ1")
			msunlock ()
	
			// Para o caso de haver pendencias do SX8
			do while __lSX8
				ConfirmSX8 ()
			enddo
			(_sAliasQ) -> (dbskip())
		enddo
		CursorArrow ()
		u_help ("Tabela copiada.")
	endif
return



// --------------------------------------------------------------------------
// Importa precos de outra tabela.
User Function VA_SZAI ()
	local _aTabelas := {}
	local _nTabOrig := 0
	local _sTabOrig := ""
	local _sTabDest := sza -> za_cod
	local _sQuery   := ""
	local _sCampo   := ""
	//local _aTabelas := {}
	local _nNovoPrc := 0
	local _nRegSZ1  := 0
	local _sProduto := ""
	local _sGrau    := ""
	local _aCols    := {}
	local _sVaried  := ""
	local _nVaried	:= 0
	private _aVaried  := {}

	if ! msgyesno ("Esta rotina permite que a tabela de precos '" + _sTabDest + "' seja atualizada buscando os precos correspondentes em outra tabela. Deseja continuar?","Continuar")
		return
	endif

	_sQuery := ""
	_sQuery += " select ZA_COD, ZA_DESC, ZA_SAFRA"
	_sQuery +=   " from " + RetSQLName ("SZA")
	_sQuery +=  " where D_E_L_E_T_ = ''"
	_sQuery +=    " and ZA_FILIAL  = '" + xfilial ("SZA") + "'"
	_sQuery +=    " and ZA_COD    != '" + _sTabDest + "'"
	_aTabelas = U_Qry2Array (_sQuery)
	_aCols = {}
	aadd (_aCols, {1, "Tabela",    50,  "@!"})
	aadd (_aCols, {2, "Descricao", 200, "@!"})
	aadd (_aCols, {3, "Safra",     50,  "@!"})
	_nTabOrig = U_F3Array (_aTabelas, "Selecione a tabela origem", _aCols, 600, 400, "Selecione a tabela a partir da qual os precos devem ser copiados.", "", .F.)
	if _nTabOrig == 0
		return
	endif
	_sTabOrig = _aTabelas [_nTabOrig, 1]

	// Seleciona qual o preco a ser importado e jah define uma variavel com o nome do campo.
	_nQualPrc = _SelTabPrc ("Qual preco deve ser importado?")
	do case
		case _nQualPrc == 1
			_sCampo = "Z1_PRCREC"
		case _nQualPrc == 2
			_sCampo = "Z1_PRCCOM"
		case _nQualPrc == 3
			_sCampo = "Z1_PRCDCO"
		otherwise
			return
	endcase

	// Monta tabela das variedades existentes nesta tabela de precos
	_sQuery := ""
	_sQuery += " select distinct case B1_VARUVA when 'C' then 'Comum' else case B1_VARUVA when 'F' then 'Fina' else '' end end,"
	_sQuery +=        " Z1_CODPRD, B1_DESC, ' ' as OK"
	_sQuery +=   " from " + RetSQLName ("SZ1") + " SZ1, "
	_sQuery +=              RetSQLName ("SB1") + " SB1 "
	_sQuery +=  " where SZ1.D_E_L_E_T_ = ''"
	_sQuery +=    " and SZ1.Z1_FILIAL  = '" + xfilial ("SZ1") + "'"
	_sQuery +=    " and SZ1.Z1_TABELA  = '" + _sTabOrig + "'"
	_sQuery +=    " and SB1.D_E_L_E_T_ = ''"
	_sQuery +=    " and SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery +=    " and SB1.B1_COD     = Z1_CODPRD"
	u_log (_sQuery)
	_aVaried = aclone (U_Qry2Array (_sQuery))
	for _nVaried = 1 to len (_aVaried)
		_aVaried [_nVaried, 4] = .F.
	next
	_aVaried = asort (_aVaried,,, {|_x, _y| _x[1] + _x [2] < _y [1] + _y [2]})

	// Browse para usuario selecionar as variedades
	_sVaried = _SelVaried ()
	if empty (_sVaried)
		return
	endif

	CursorWait ()
	sz1 -> (dbsetorder (1)) // Z1_FILIAL+Z1_TABELA+Z1_CODPRD+Z1_GRAU
	sz1 -> (dbseek (xfilial ("SZ1") + _sTabDest, .T.))
	do while ! sz1 -> (eof ()) .and. sz1 -> z1_filial == xfilial ("SZ1") .and. sz1 -> z1_tabela == _sTabDest

		if alltrim (sz1 -> z1_codprd) $ _sVaried

			// Busca o preco equivalente na tabela de origem
			_nNovoPrc = 0
			_sProduto = sz1 -> z1_codprd
			_sGrau    = sz1 -> z1_grau
			_nRegSZ1  = sz1 -> (recno ())
			if sz1 -> (dbseek (xfilial ("SZ1") + _sTabOrig + _sProduto + _sGrau, .F.))
				_nNovoPrc = sz1 -> &(_sCampo)
			endif
			sz1 -> (dbgoto (_nRegSZ1))
			reclock ("SZ1", .F.)
			sz1 -> &(_sCampo) = _nNovoPrc
			msunlock ()
		endif
		sz1 -> (dbskip ())
	enddo

	CursorArrow ()
	u_help ("Tabela copiada.")
return



// --------------------------------------------------------------------------
// Markbrowse para o usuario selecionar as variedades.
static function _SelVaried ()
	local _nVaried := 0
	//local _nLinha  := 0
	local _aCols   := {}
	local _sRet      := ""

	_aCols = {}
	aadd (_aCols, {1, "Tipo",      50,  "@!"})
	aadd (_aCols, {2, "Variedade", 50,  "@!"})
	aadd (_aCols, {3, "Descricao", 200, "@!"})
	u_log (_aVaried)
	U_MBArray (@_aVaried, "Selecione as variedades", _aCols, 4, 600, 550, ".T.")
	for _nVaried = 1 to len (_aVaried)
		if _aVaried [_nVaried, 4]
			_sRet += alltrim (_aVaried [_nVaried, 2]) + "/"
		endif
	next
return _sRet



// --------------------------------------------------------------------------
// Tela para o usuario selecionar um entre os possiveis precos de lista.
static function _SelTabPrc (_sPergunta)
	local _nRet := 0
	_nRet = aviso (_sPergunta, ;
	               "Preco de entrada: usado para as contranotas de recebimento durante a safra." + chr (13) + chr (10) + ;
	               "Preco de compra: usado para as notas de compra." + chr (13) + chr (10) + ;
	               "Preco do governo: preco da tabela MOC do governo.", ;
	               {"Entrada", "Compra", "Governo", "Cancelar"}, 3, _sPergunta)
return _nRet



// --------------------------------------------------------------------------
// Monta uma janela com texto e uma linha de get na tela. Usada para solicitar
// algum dado adicional ao usuario.
// Autor: Robert Koch - nov/2002
// Parametros: _sTexto   = texto a ser mostrado antes do get
//             _sTipo    = tipo de dado (C, D, N)
//             _nTamanho = tamanho da variavel a ser lida
//             _sMasc    = mascara (picture) a ser usada
//             _sF3      = para consulta padrao, se tiver. Senao, informar ""
//             _xIni     = inicializador para a variavel
//             _lPass    = se .T. faz leitura de senha (mostra asteriscos)
//             _sValid   = funcao para validacao
//
// Historico de alteracoes:
// 26/06/2003 - Robert - Implementada leitura de senha
// 19/01/2007 - Robert - Incluida opcao de informar funcao para validacao
//                     - Retorna NIL em caso de cancelamento
//
static function _Get (_sTexto, _sTipo, _nTamanho, _sMasc, _sF3, _xIni, _lPass, _sValid)
   local _xRet     := NIL
   local _oDlgGet  := NIL
   local _nLargura := min (max (300, max (len (_sTexto) * 5, _nTamanho * 10)), oMainWnd:nClientwidth / 2)
   private _xDado  // Deixar private para ser vista pela funcao de validacao

   _sF3    = iif (_sF3    == NIL, "",    _sF3)
   _sMasc  = iif (_sMasc  == NIL, "",    _sMasc)
   _lPass  = iif (_lPass  == NIL, .F.,   _lPass)
   _sValid = iif (_sValid == NIL, ".T.", _sValid)

   if _xIni != NIL .and. valtype (_xIni) != _sTipo
      msgbox ("Funcao _GET: inicializador incompativel com tipo de dado!")
      return NIL
   endif

   do case
      case _sTipo == "N"
         _xDado := iif (_xIni == NIL, 0, _xIni)
      case _sTipo == "D"
         _xDado := iif (_xIni == NIL, ctod (""), _xIni)
      case _sTipo == "C" .or. _sTipo == "M"
         _xDado := iif (_xIni == NIL, space (_nTamanho), _xIni)
   endcase

   define MSDialog _oDlgGet from 0, 0 to 120, _nLargura of oMainWnd pixel title "Entrada de dados"
      @ 10, 10 say _sTexto
      if _lPass
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3 PASSWORD
      else
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3
      endif
      @ 45, 10 bmpbutton type 1 action (iif (&(_sValid), (_xRet := _xDado, _oDlgGet:End ()), NIL))
   activate MSDialog _oDlgGet centered
return _xRet
*/
