// Programa...: FrtESal
// Autor......: Robert Koch
// Data.......: 15/10/2017
// Descricao..: Cota frete via webservice da E-Sales.
//              Criado com base no FrtSelPV.prw
//              Royalties para Fabio e Daniel (Procdata) pela leitura do WS.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela auxiliar (browse) para selecao de transportadora na montagem de cargas do modulo OMS
// #PalavasChave      #selecao_transportadora #cotacao_frete #montagem_de_carga
// #TabelasPrincipais #DAK #DAI
// #Modulos           #OMS
//
// Historico de alteracoes:
// 14/11/2017 - Robert  - Nao mostra a tela de selecao de transportadora se o entregou.com tiver retornado vazio.
// 06/06/2018 - Robert  - Verificacao de pedidos com frete FOB desabilitada (quem deve validar isso eh o P.E. OM200ok)
// 10/08/2020 - Robert  - Desabilitadas partes relacionadas a pedido de venda (esta funcao nao eh mais chamada desse local) - GLPI 8180
//                      - Inseridas tags para catalogacao de fontes.
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// -------------------------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "colors.ch"
#include "VA_Inclu.prw"

user function FrtESal (_sOrigCot, _sCargaOMS, _lComTela)
	local _aAreaAnt    := U_ML_SRArea ()
	local _aAmbAnt     := U_SalvaAmb ()
	local _lContinua   := .T.
	local _bAcao       := NIL
	local _oCour20     := TFont():New("Courier New",,20,,.T.,,,,,.F.)
	local _sMVEstICM   := ""
	local _nAliqICM    := 0
	local _aCandidat   := {}
	local _oSQL        := NIL
	local _aPed        := {}
	local _nPed        := 0
	local _nLin        := 0
	local _nCol        := 0
	local _nVlCota     := 0
	local _nCandidat   := 0
	local _nRetESal	   := 0
	private _sTransSel := ""  // Transportadora selecionada. Deixar private para ser vista por todas as rotinas.
	private _sTransNeg := space (6)  // Transportadora negociada. Deixar private para ser vista por todas as rotinas.
	private _sNomeTra  := ""
	private _nNegociad := 0
	private _sTransRed := space (6)
	private _sNomTrRed := ""
	private _aRetESal  := {}
	private _sOrigem   := _sOrigCot
	private _sCarga    := _sCargaOMS

	// Se estas variaveis nao existirem, tenho que cria-las.
	if type ("aHeader") != "A"
		private aHeader   := {}
	endif
	if type ("aCols") != "A"
		private aCols     := {}
	endif
	if type ("N") != "N"
		private N         := 1
	endif
	if type ("aRotina") != "A"
		private aRotina   := {}  // Variavel exigida pela GetDados.
	endif
	aRotina = {}
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 1})
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 2})
    
	u_logIni ()

	_lComTela := iif (_lComTela == NIL, .T., _lComTela)

	procregua (10)

	// Procura transportadoras habilitadas.
	if _lContinua
		incproc ('Verificando transportadoras habilitadas')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select distinct A4_CGC"
		_oSQL:_sQuery += "   from " + RetSQLName ("SA4") + " SA4  "
		_oSQL:_sQuery += "  where SA4.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery += "    and A4_FILIAL      =  '" + xfilial ("SA4") + "'"
		_oSQL:_sQuery += "    and A4_CGC         != ''"
		_oSQL:_sQuery += "    and A4_VADISPV     != 'N'"
		//_oSQL:Log ()
		_aCandidat := aclone (_oSQL:Qry2Array (.F., .F.))

		// Transforma em vetor simples.
		for _nCandidat = 1 to len (_aCandidat)
			_aCandidat [_nCandidat] = _aCandidat [_nCandidat, 1]
		next
		//u_log ('candidatas:', _aCandidat)
		if len (_aCandidat) == 0
			u_help ("Nenhuma transportadora habilitada para cotacao. Verifique se o campo '" + alltrim (RetTitle ("A4_VADISPV")) + "' encontra-se informado no cadastro das transportadoras.")
			_lContinua = .F.
		endif
		if len (_aCandidat) > 350
			u_help ('Numero excessivo de transportadoras configuradas para consulta. Verifique real necessidade de cotar frete com ' + cvaltochar (len (_aCandidat)) + ' transportadoras.')
			_lContinua = .F.
		endif
	endif

	// Busca dados dos pedidos a cotar.
	if _lContinua
		incproc ('Verificando pesos e valores do(s) pedido(s)')
			// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		if _sOrigem == 'C'  // Carga do OMS
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT C5_NUM, C5_CLIENTE, C5_LOJACLI, C5_PBRUTO, C5_VOLUME1, C5_VAEST, 0 AS ALIQICM,"
			_oSQL:_sQuery +=        " C5_VAVLFAT, A1_CGC, A1_CEP, A1_NOME, C5_VAOBSLG"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("DAI") + " DAI, "
			_oSQL:_sQuery +=              RetSQLName ("SC5") + " SC5, "
			_oSQL:_sQuery +=              RetSQLName ("SA1") + " SA1 "
			_oSQL:_sQuery +=  " WHERE DAI.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND DAI.DAI_FILIAL      =  '" + xfilial ("DAI") + "'"
			_oSQL:_sQuery +=    " AND DAI.DAI_COD     = '" + dak -> dak_cod + "'"
			_oSQL:_sQuery +=    " AND SC5.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND SC5.C5_FILIAL   = '" + xfilial ("SC5") + "'"
			_oSQL:_sQuery +=    " AND SC5.C5_NUM      = DAI.DAI_PEDIDO"
			_oSQL:_sQuery +=    " AND SC5.C5_TIPO     = 'N'"
			_oSQL:_sQuery +=    " AND SC5.C5_TPFRETE  = 'C'"
			_oSQL:_sQuery +=    " AND SA1.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=    " AND SA1.A1_FILIAL   = '" + xfilial ("SA1") + "'"
			_oSQL:_sQuery +=    " AND SA1.A1_COD      = SC5.C5_CLIENTE"
			_oSQL:_sQuery +=    " AND SA1.A1_LOJA     = SC5.C5_LOJACLI"
			_oSQL:_sQuery +=  " ORDER BY C5_CLIENTE, DAI_PEDIDO"
			_oSQL:Log ()
			_aPed := aclone (_oSQL:Qry2Array (.F., .F.))
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			if !empty (m->c5_cliente) .and. ! empty (m->c5_lojaent) .and. ! empty (m->c5_pbruto) .and. ! empty (m->c5_volume1)  // Usuario pode ainda estar preenchendo o pedido.
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				sa1 -> (dbsetorder (1))
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				if ! sa1 -> (dbseek (xfilial ("SA1") + m->c5_cliente + m->c5_lojaent, .F.))
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->					u_help ("Cliente nao encontrado.")
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->					aadd (_aPed, {m->c5_num, m->c5_cliente, m->c5_lojacli, m->c5_pbruto, m->c5_volume1, m->c5_vaest, 0, m->c5_vaVlFat, sa1 -> a1_cgc, sa1 -> a1_cep, sa1 -> a1_nome, m->C5_VAOBSLG})
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->				endif
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			endif
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		endif
	endif

	if _lContinua .and. len (_aPed) == 0
		u_help ("Nenhum pedido em condicoes de cotar frete no 'entregou'. Verifique se faltam dados no pedido (valor/peso/volumes/etc.), se o pedido eh do tipo normal e tem frete CIF.")
		_lContinua = .F.
	endif

	// Busca aliquota de ICMS das UF destino e calcula valor do pedido.
	if _lContinua
		_sMVEstIcm := alltrim (GetMv ("MV_ESTICM"))
		_sMVEstado := GetMv ("MV_ESTADO")
		_nMVIcmPad := GetMv ("MV_ICMPAD")
		
		for _nPed = 1 to len (_aPed)
			_sEstDest = _aPed [_nPed, 6]
	
			// Busca a aliquota de ICMS conforme estado do cliente
			if _sEstDest != _sMVEstado //GetMv ("MV_ESTADO")
				_nPos = at (_sEstDest, _sMVEstIcm)
				if _nPos == 0
					u_help ("Programa " + procname () + "Estado '" + _sEstDest + "' nao consta no parametro MV_ESTICM. Verifique!")
					_lContinua = .F.
				else
					_nPos += 2
					_sAliq = ""
					do while _nPos <= len (_sMVEstIcm) .and. ! IsAlpha (substr (_sMVEstIcm, _nPos, 1))
						_sAliq += substr (_sMVEstIcm, _nPos, 1)
						_nPos ++
					enddo
					_nAliqICM = val (_sAliq)
				endif
			else
				_nAliqICM = _nMVIcmPad // getmv ("MV_ICMPAD")
			endif
			_aPed [_nPed, 7] = _nAliqICM
		next
	endif

	if _lContinua
		
		// Inicializa aHeader com os campos fixos do inicio da linha. Posteriormente, para cada transportadora
		// que retorne uma cotacao, sera criado novo campo no aHeader e nova coluna no aCols.
		aHeader = {}
		//               Titulo    Campo      Masc                 Tam Dec ?   Usado, Tipo Arq Contexto
		aadd (aHeader, {"Pedido",  "PEDIDO",  "",                  6,  0,  "", "",    "C", "", "V"})
		aadd (aHeader, {"Cliente", "CLIENTE", "",                  6,  0,  "", "",    "C", "", "V"})
		aadd (aHeader, {"Loja",    "LOJA",    "",                  2,  0,  "", "",    "C", "", "V"})
		aadd (aHeader, {"Nome",    "NOMECLI", "",                  30, 0,  "", "",    "C", "", "V"})
		aadd (aHeader, {"Peso Kg", "PESO",    "@E 999,999.99", 9,  2,  "", "",    "N", "", "V"})
		aadd (aHeader, {"Vlr.fat", "VLRFAT",  "@E 999,999,999.99", 12, 2,  "", "",    "N", "", "V"})
		aadd (aHeader, {"UF",      "ESTADO",  "",                  2,  0,  "", "",    "C", "", "V"})
		aadd (aHeader, {"CEP",     "CEPCLI",  "",                  8,  0,  "", "",    "C", "", "V"})

		aCols := {}
		u_log ('pedidos:', _aPed)
		for _nPed = 1 to len (_aPed)
			u_logIni ('Cotando frete para o pedido ' + _aPed [_nPed, 1])
			
			processa ({||_aRetESal := aclone (U_VACGFRET (_aPed [_nPed, 9]	, ;  // CNPJ destino
			                                              _aPed [_nPed, 10]	, ;  // CEP destino
			                                              date ()			, ;  // Data entrega
			                                              _aPed [_nPed, 5]	, ;  // Qt volumes
			                                              'C'				, ;  // Tipo de frete
			                                              _aPed [_nPed, 8]	, ;  // Valor NF
			                                              _aPed [_nPed, 4]	, ;  // Peso Kg
			                                              1					, ;  // Cubagem. A principio valor fixo, pois o campo eh obrigatorio
			                                              _aPed [_nPed, 7]	, ;  // Aliquota ICMS
			                                              _aCandidat 		  ;  // Array de transportadoras para cotacao
			                                              					))}, "Cotando frete pedido " + _aPed [_nPed, 1] + " (" + cvaltochar (_nPed) + " de " + cvaltochar (len (_aPed)) + ")")
			// u_log ('retorno da e-sales:', _aRetESal)

			// Passa dados para a array que vai acumular as cotacoes de todos os pedidos.
			// O retorno do webservice eh uma array com uma linha para cada transportadora. Vou
			// transformar isso em uma linha da array _aPed.
			if len (_aRetESal) > 0
				aadd (aCols, aclone (U_LinVazia (aHeader)))
				GDFieldPut ("PEDIDO",  _aPed [_nPed, 1],  len (aCols))
				GDFieldPut ("CLIENTE", _aPed [_nPed, 2],  len (aCols))
				GDFieldPut ("LOJA",    _aPed [_nPed, 3],  len (aCols))
				GDFieldPut ("NOMECLI", _aPed [_nPed, 11], len (aCols))
				GDFieldPut ("ESTADO",  _aPed [_nPed, 6],  len (aCols))
				GDFieldPut ("CEPCLI",  _aPed [_nPed, 10], len (aCols))
				GDFieldPut ("PESO",    _aPed [_nPed, 4],  len (aCols))
				GDFieldPut ("VLRFAT",  _aPed [_nPed, 8],  len (aCols))
				for _nRetESal = 1 to len (_aRetESal)
					
					// Pode haver retorno de filiais da transportadora que nem temos no cadastro
					if _aRetESal [_nRetESal, .ESalesRetVlrFrete] > 0 .and. ! empty (_aRetESal [_nRetESal, .ESalesRetCodTransp])
	
						// Cria no aHeader, se necessario, coluna referente a esta transportadora
						if GDFieldPos ('TR_' + _aRetESal [_nRetESal, .ESalesRetCodTransp]) == 0
							aadd (aHeader, {left (alltrim (_aRetESal [_nRetESal, .ESalesRetCodTransp]) + '-' + alltrim (_aRetESal [_nRetESal, .ESalesRetNome]), 20), ;  // Titulo
							                'TR_' + _aRetESal [_nRetESal, .ESalesRetCodTransp], ;  // Nome campo
							                "@E 999,999.99", 9,  2,  "", "",    "N", "", "V"})  // Masc Tam Dec ? Usado, Tipo Arq Contexto
	
							// Cria coluna no aCols e grava zero em todas as linhas (pode ja haver outros pedidos que esta transportadora nao atendia).
							for _nLin = 1 to len (aCols)
								aadd (aCols [_nLin], .F.)
								aCols [_nLin, GDFieldPos ('TR_' + _aRetESal [_nRetESal, .ESalesRetCodTransp])] = 0
							next
						endif
						
						// Grava cotacao desta transportadora para o pedido atual
						aCols [len (aCols), GDFieldPos ('TR_' + _aRetESal [_nRetESal, .ESalesRetCodTransp])] = _aRetESal [_nRetESal, .ESalesRetVlrFrete]
					endif
				next
			else
				_lContinua = .F.
				exit
			endif

			u_logFim ('Cotando frete para o pedido ' + _aPed [_nPed, 1])
		next

		// Inclui ultima coluna com observacao da logistica. Nao inclui com as demais
		// para nao ocupar muito espaco no inicio do browse e para que a ultima coluna
		// de cotacao (quando houver poucas) nao fique esquecida a direita da tela.
		//               Titulo          Campo      Masc             Tam  Dec ?   Usado, Tipo Arq Contexto
		if _lContinua
			aadd (aHeader, {"Obs.logistica", "OBSLOG",  "",              150, 0,  "", "",    "C", "", "V"})
			for _nLin = 1 to len (aCols)
				aadd (aCols [_nLin], .F.)
			next
			for _nPed = 1 to len (_aPed)
				aCols [_nPed, GDFieldPos ("OBSLOG")] = alltrim (_aPed [_nPed, 12])
			next
		endif
	endif

	if _lContinua
		if _lComTela
			N = 1
			_bAcao = {|| _Seleciona ()}
	
			define MSDialog _oDlg from 0, 0 to 400, oMainWnd:nClientWidth - 20 of oMainWnd pixel title "Transportadoras disponiveis"
	
			// Textos variaveis
			//                     Linha                           Coluna                  bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                     altura
			_oTxt1 := tSay ():New (10,                             15,                     NIL, _oDlg, NIL, _oCour20, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,      15)
			_oTxt2 := tSay ():New (25,                             15,                     NIL, _oDlg, NIL, _oCour20, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth,      15)
			_oTxt3 := tSay ():New (50,                             50,                     NIL, _oDlg, NIL, _oCour20, NIL, NIL, NIL, .T.,  CLR_RED,  NIL,    _oDlg:nClientWidth,      15)
	
			if len (aCols) > 0
				_oTxt1:SetText ("Pedido(s) X Transportadoras disponiveis")
	
				_oGetD := MSGETDADOS ():New (40, ;   // Limite superior
				15, ;                                // Limite esquerdo
				_oDlg:nClientHeight / 2 - 55, ;      // Limite inferior
				_oDlg:nClientWidth / 2 - 35, ;       // Limite direito
				2, ;                                 // opcao do mbrowse, caso tivesse
				"allwaystrue ()", ;                  // Linha ok
				"allwaystrue ()", ;                  // Tudo ok
				, ;                                  // Campos com incremento automatico
				.F., ;                               // Permite deletar linhas
				, ;                                  // Vetor de campos que podem ser alterados
				, ;                                  // Reservado
				.F., ;                               // Se .T., a primeira coluna nunca pode ficar vazia
				len (aCols), ;                       // Maximo de linhas permitido
				"allwaystrue ()", ;                  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
				"AllwaysTrue ()", ;                  // Funcao executada quando pressionadas as teclas <Ctrl>+<Delete>.
				, ;                                  // Reservado
				"allwaystrue ()", ;                  // Funcao executada para validar a exclusao ou reinclusao de uma linha do aCols.
				_oDlg)                               // Objeto no qual a MsGetDados serah criada.
				_oGetD:oBrowse:bLDblClick := _bAcao
			else
				_oTxt3:SetText ("Nenhuma cotacao recebida.")
			endif
	
			@ _oDlg:nClientHeight / 2 - 50, 15  say "Transport.(negociado)"
			@ _oDlg:nClientHeight / 2 - 35, 15  say "Valor negociado"
			@ _oDlg:nClientHeight / 2 - 50, 80  get _sTransNeg size 50,  11 F3 "SA4" valid _ValTrNeg ()
			@ _oDlg:nClientHeight / 2 - 50, 140 get _sNomeTra  size 130, 11 when .F.
			@ _oDlg:nClientHeight / 2 - 50, 290 say "Transport. redespacho"
			@ _oDlg:nClientHeight / 2 - 50, 360 get _sTransRed size 50,  11 F3 "SA4" valid _ValTrRed ()
			@ _oDlg:nClientHeight / 2 - 50, 415 get _sNomTrRed size 130, 11 when .F.
			@ _oDlg:nClientHeight / 2 - 35, 100 get _nNegociad size 50,  11 picture "@E 999,999,999.99" valid _ValNeg ()
			@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 100 bmpbutton type 1 action (iif (_TudoOK(), (_Grava (), _oDlg:End ()), NIL))
			@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 45  bmpbutton type 2 action _oDlg:End ()
			activate dialog _oDlg centered valid _TudoOK ()
		else

			// Apenas retornar o percentual do menor frete.
			_nVlCota = 999999
			for _nLin = 1 to len (aCols)
				for _nCol = 1 to len (aHeader)
					if left (aHeader [_nCol, 2], 3) == 'TR_'
						if aCols [_nLin, _nCol] > 0
							u_log ('Validando cotacao de', aCols [_nLin, _nCol])
							_nVlCota = min (_nVlCota, aCols [_nLin, _nCol])
						endif
					endif
				next
			next
			u_log ('valor cotado:', _nVlCota)
			if _nVlCota == 999999
				u_log ('Nao consegui cotacao de frete valida para este pedido.')
				m->c5_mvfre = 0
			else
				m->c5_mvfre = _nVlCota
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Verifica 'tudo ok'.
static function _TudoOK ()
	local _lRet      := .T.
	
	if _lRet .and. empty (_sTransSel) .and. empty (_sTransNeg)
		u_help ("Selecione uma transportadora entre as disponiveis ou informe negociacao.")
		_lRet = .F.
	endif
	if _lRet .and. ! empty (_sTransNeg)
		if _nNegociad == 0
			u_help ("Frete negociado: valor nao pode ficar zerado.")
			_lRet = .F.
		endif
	endif
	if _lRet .and. _sTransRed == _sTransSel
		u_help ("Transportadora redespacho nao pode ser igual `a transportadora selecionada para o frete.")
		_lRet = .F.
	endif

// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	if _lRet .and. _sOrigem == 'P'
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		GetDRefresh ()  // Atualiza tela do pedido.
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		Sysrefresh ()
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	endif
return _lRet
//
// --------------------------------------------------------------------------
// Obtem o codigo da transportadora selecinada.
static function _Seleciona ()
	u_logIni ()
	// A selecao da transportadora eh feita pela coluna do aCols.
	if aHeader [_oGetD:oBrowse:nColPos, 2] != 'TR_'
		u_help ("Opcao invalida. Selecione uma coluna contendo uma transportadora cotada ou informe frete negociado.")
		_sTransSel = ''
	else
		_sTransSel = substr (aHeader [_oGetD:oBrowse:nColPos, 2], 4)
		_oTxt2:SetText ("Transportadora selecionada: " + alltrim (_sTransSel) + " - " + alltrim (fBuscaCpo ("SA4", 1, xfilial ("SA4") + _sTransSel, "A4_NOME")) + ' (' + alltrim (fBuscaCpo ("SA4", 1, xfilial ("SA4") + _sTransSel, "A4_NREDUZ")) + ')')
	endif
	u_log ('_sTransSel:', _sTransSel)
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Grava dados.
static function _Grava ()
	local _n := 1
	u_logIni ()

	// Altera as transportadoras nos pedidos da carga
	incproc ('Gravando dados')
	// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	if _sOrigem == 'C'  // Carga do OMS
	u_log ('origem: carga')
	u_log (len (aCols))
	sc5 -> (dbsetorder (1))
	for _n = 1 to len (aCols)
		N := _n
		u_log ('N=',N, GDFieldGet ("PEDIDO"), '_sTransSel:', _sTransSel, '_sTransNeg:', _sTransNeg)
		U_LOG ('>>' + xfilial ("SC5") + GDFieldGet ("PEDIDO") + '<<')
		if sc5 -> (dbseek (xfilial ("SC5") + GDFieldGet ("PEDIDO"), .F.))
			u_log ('gravando pedido', sc5 -> c5_num, 'vlr.frete:', GDFieldGet ("TR_" + _sTransSel), 'vlr.negociado:', _nNegociad)
			reclock ("SC5", .F.)
			if ! empty (_sTransSel)
				sc5 -> C5_TRANSP = _sTransSel
				sc5 -> C5_MVFRE  = GDFieldGet ("TR_" + _sTransSel)
			else
				sc5 -> C5_TRANSP = _sTransNeg
				sc5 -> C5_MVFRE  = _nNegociad
			endif
			sc5 -> C5_redesp = _sTransRed
			msunlock ()
		endif
	next

	// grava código da transportadora no DAK
	u_log ('gravando transp. na carga', dak -> dak_cod)
	reclock("DAK",.F.)
	if ! empty (_sTransSel)
		Replace DAK->DAK_VATRAN With _sTransSel
	else
		Replace DAK->DAK_VATRAN With _sTransNeg
	endif
	Replace DAK->DAK_VATRRE With _sTransRed
	msunlock()

// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		// O pedido assume a transportadora selecionada / informada.
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		if ! empty (_sTransSel)
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->c5_transp = _sTransSel
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->c5_mvfre  = GDFieldGet ("TR_" + _sTransSel)
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		else
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->C5_TRANSP = _sTransNeg
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->			m->C5_MVFRE  = _nNegociad
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		endif
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->		m->c5_redesp = _sTransRed
// Nao usa mais esta rotina a partir da tela de pedidos de venda -->	endif
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Valida transportadora negociada.
static function _ValTrNeg ()
	local _lRet := .T.
	if ! empty (_sTransNeg)
		if _sTransRed == _sTransNeg
			u_help ("Transportadora redespacho e negociada nao podem ser iguais.")
			_lRet = .F.
		else 
			sa4 -> (dbsetorder (1))
			if ! sa4 -> (dbseek (xfilial ("SA4") + _sTransNeg, .F.))
				u_help ("Transportadora nao cadastrada.")
				_lRet = .F.
			else
				_sNomeTra = sa4 -> a4_nome
			endif
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Valida transportadora redespacho.
static function _ValTrRed ()
	local _lRet := .T.
	if ! empty (_sTransRed)
		if _sTransRed == _sTransNeg
			u_help ("Transportadora redespacho e negociada nao podem ser iguais.")
			_lRet = .F.
		else 
			sa4 -> (dbsetorder (1))
			if ! sa4 -> (dbseek (xfilial ("SA4") + _sTransRed, .F.))
				u_help ("Transportadora nao cadastrada.")
				_lRet = .F.
			else
				_sNomTrRed = sa4 -> a4_nome
			endif
		endif
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Valida valor negociado.
static function _ValNeg ()
	local _lRet := .T.
	if _nNegociad != 0 .and. empty (_sTransNeg)
		u_help ("Informe antes a transportadora.")
		_lRet = .F.
	endif
return _lRet
