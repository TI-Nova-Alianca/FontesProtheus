// Programa...: FrtSelFr
// Autor......: Robert Koch
// Data.......: 06/05/2008
// Descricao..: Tela para usuario selecionar as notas de venda `as quais o conhecimento digitado se refere.
//              Inicialmente vai ser chamado pelo P.E. MA103But.
//
// Historico de alteracoes:
// 22/07/2008 - Robert - Ordena browse por numero de NF de venda.
// 29/07/2008 - Robert - Incluida visualizacao do numero do conhecimento nas telas (util
//                       na importacao de conhecimentos)
//                     - Se o prog. de import. de conhecimentos disponibilizar, jah traz a NF original selecionada.
// 19/08/2008 - Robert - Selecao de NFs de venda previstas e nao previstas passa a ser nesta mesma tela.
//                     - Deficicao do D1_CC trazida do MT100GRV para ca.
// 27/08/2008 - Robert - Criado tratamento para redespacho.
// 23/01/2009 - Robert - Quando nao for inclusao, consulta dados do SZH.
// 29/01/2009 - Robert - Criadas mais algumas validacoes de 'tudo ok'.
// 24/02/2010 - Robert - Quando NF tipo B ou D, passa a buscar nome do destinatario no SA2.
//                     - Marcando uma nota na parte de cima, digitando-a e deletando-a na parte de
//                       baixo, o sistema ignorava a nota. Agora nao deixa mais digitar.
//                     - Nao lista (por default) previsoes de fretes com mais de 2 meses de idade.
//                     - Criado tratamento para fretes sobre devolucoes de vendas (campo ZH_DEVVD)
// 20/03/2012 - Robert - Criado tratamento para o campo ZZ6_TPDES (posterior ZH_TPDESP).
//                     - Nao busca fretes previstos quando for conhecimento de paletizacao.
// 26/03/2012 - Robert - Nao exige mais CTR, basta que seja um item do VA_PRODCIF.
// 11/09/2012 - Robert - Corrigida leitura do aCols e N nas validacoes do browse de fretes nao previstos.
// 12/04/2013 - Leandro DWT - Preparacao para gravacao da tabela ZZN
// 11/09/2015 - Robert - Buscava nome do fornecedor incorretamente quando consultando conhecimento de frete.
// 18/03/2016 - Catia  - Alterada a forma de buscar as notas amarradas a fretes - busca tudo da SZH
// 16/06/2016 - Robert - Desabilitada a definicao do D1_CC. Passa a buscar padrao do cadastro do produto.
// 19/10/2016 - Catia  - tirado comentarios alguns bloco comentados
// 14/01/2020 - Andre  - Alterada query para mostrar dados especie CTE, CTR e tipo de produto iniciado com 'FR' 

#include "rwmake.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function FrtSelFr ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lPaletiz  := (alltrim (GDFieldGet ('D1_COD', 1)) == 'FR02')

	processa ({|| _AndaLogo (_lPaletiz)})

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return

// --------------------------------------------------------------------------
static function _AndaLogo (_lPaletiz)
	local _lContinua  := .T.
	local _sQuery     := ""
	local _nFrete     := 0
	local _bBotaoOK   := {|| NIL}
	local _bBotaoCan  := {|| NIL}
	local _aBotAdic   := {}
	local _aSize      := {}  // Para posicionamento de objetos em tela
	local _oDlg       := NIL
	local _aSZH       := {} 
	//local _aSF8		  := {}
	local _aCols      := {}
	local _nTotFret   := 0
	local _sProdCIF   := alltrim (GetMv('VA_PRODCIF'))
	local _n		  := 1
	private _oBmpOK   := LoadBitmap( GetResources(), "LBOK" )
	private _oBmpNo   := LoadBitmap( GetResources(), "LBNO" )
	private _oLbx     := NIL
	private _aFretes  := {}
	private _lPressOK := .F.
	private _oGetD    := NIL
	private aGets     := {}
	private aTela     := {}
	private aRotina   := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	                      {"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido pela MSGetDados!!!

	// Guarda o total do frete para posterior verificacao.
	_nTotFret = GDFieldGet ("D1_TOTAL")

	// Cria variavel publica para que fique disponivel a outros pontos de entrada
	public _oClsFrtFr := ClsFrtFr():New ()
	
	// Se nao for inclusao, visualiza os dados do SZH e cai fora da rotina.
	
	if ! inclui
	
		_sQuery := ""
		_sQuery += " SELECT DISTINCT SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SZH.ZH_DATA"
		_sQuery += "      , CASE WHEN SZH.ZH_TPFRE = 'E' AND SZH.ZH_TPNFENT = 'N' THEN 'Entrada'"
		_sQuery += "             WHEN SZH.ZH_TPFRE = 'E' AND SZH.ZH_TPNFENT = 'D' THEN 'Devoluções'"
		_sQuery += " 			 WHEN SZH.ZH_TPFRE = 'E' AND SZH.ZH_TPNFENT = 'B' THEN 'Entrada-Outros'"
		_sQuery += "             WHEN SZH.ZH_TPFRE = 'S' THEN 'Saidas' ELSE '' END AS TIPO"
		_sQuery += "      , SZH.ZH_NFENTR, SZH.ZH_SRNFENT"
		_sQuery += "      , CASE WHEN SZH.ZH_TPFRE = 'E' THEN SZH.ZH_CLIFOR" 
	    _sQuery += "       	     WHEN SZH.ZH_TPFRE = 'S' THEN SF2.F2_CLIENTE ELSE '' END AS CLIFOR"
     	_sQuery += "      , CASE WHEN SZH.ZH_TPFRE = 'E' THEN SZH.ZH_LOJA"
	    _sQuery += "     	     WHEN SZH.ZH_TPFRE = 'S' THEN SF2.F2_LOJA ELSE '' END AS LOJA"
     	_sQuery += "	  , CASE WHEN SZH.ZH_TPFRE = 'E' AND SZH.ZH_TPNFENT  = 'N' THEN SA2.A2_NOME"
	    _sQuery += "    		 WHEN SZH.ZH_TPFRE = 'E' AND SZH.ZH_TPNFENT != 'N' THEN SA1.A1_NOME"
	    _sQuery += "    		 WHEN SZH.ZH_TPFRE = 'S' AND SF2.F2_TIPO  = 'N' THEN SA1S.A1_NOME"
		_sQuery += "			 WHEN SZH.ZH_TPFRE = 'S' AND SF2.F2_TIPO != 'N' THEN SA2S.A2_NOME  ELSE '' END AS RAZAO_SOCIAL"
		_sQuery += "      , SZH.ZH_NFFRETE, SZH.ZH_SERFRET"
		_sQuery += "   FROM " + RetSQLName ("SZH") + " SZH"
		_sQuery += "   		LEFT JOIN SA1010 AS SA1"
		_sQuery += "   			ON (SA1.D_E_L_E_T_  = ''"
		_sQuery += "   				AND SA1.A1_COD  = SZH.ZH_CLIFOR"
		_sQuery += "   				AND SA1.A1_LOJA = SZH.ZH_LOJA)"
		_sQuery += "   		LEFT JOIN SA2010 AS SA2"
		_sQuery += "   			ON (SA2.D_E_L_E_T_  = ''"
		_sQuery += "   				AND SA2.A2_COD  = SZH.ZH_CLIFOR"
		_sQuery += "   				AND SA2.A2_LOJA = SZH.ZH_LOJA)"
		_sQuery += " 		LEFT JOIN SF2010 AS SF2"
		_sQuery += " 			ON (SF2.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SF2.F2_FILIAL = SZH.ZH_FILIAL"
		_sQuery += " 				AND SF2.F2_DOC    = SZH.ZH_NFSAIDA"
		_sQuery += " 				AND SF2.F2_SERIE  = SZH.ZH_SERNFS)"
		_sQuery += " 		LEFT JOIN SA1010 AS SA1S"
		_sQuery += " 			ON (SA1S.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA1S.A1_COD  = SF2.F2_CLIENTE"
		_sQuery += " 				AND SA1S.A1_LOJA = SF2.F2_LOJA)"
		_sQuery += " 		LEFT JOIN SA2010 AS SA2S"
		_sQuery += " 			ON (SA2S.D_E_L_E_T_  = ''"
		_sQuery += " 				AND SA2S.A2_COD  = SF2.F2_CLIENTE"
		_sQuery += " 				AND SA2S.A2_LOJA = SF2.F2_LOJA)"
		_sQuery += "  WHERE SZH.D_E_L_E_T_ = ''"
		_sQuery += "    AND SZH.ZH_FILIAL  = '" + xfilial ("SZH") + "'"
		if alltrim(sf1 -> f1_especie) == 'CTE' .or. alltrim(sf1 -> f1_especie) == 'CTR' .or. left(GDFIELDGET("D1_COD",1),2) == 'FR' 
			_sQuery += "    and SZH.ZH_NFFRETE = '" + sf1 -> f1_doc     + "'"
			_sQuery += "    and SZH.ZH_SERFRET = '" + sf1 -> f1_serie   + "'"
			_sQuery += "    and SZH.ZH_FORNECE = '" + sf1 -> f1_fornece + "'"
			_sQuery += "    and SZH.ZH_LOJA    = '" + sf1 -> f1_loja    + "'"
		else
			_sQuery += "    and SZH.ZH_NFENTR  = '" + sf1 -> f1_doc     + "'"
			_sQuery += "    and SZH.ZH_SRNFENT = '" + sf1 -> f1_serie   + "'"
			_sQuery += "    and SZH.ZH_CLIFOR  = '" + sf1 -> f1_fornece + "'"
			_sQuery += "    and SZH.ZH_LJCLIFO = '" + sf1 -> f1_loja    + "'"
		endif
					
		_aSZH = aclone (U_Qry2Array (_sQuery))
		
			_aCols = {}
			aadd (_aCols, { 1, "NF saida"          , 50, "@!"})
			aadd (_aCols, { 2, "Serie"             , 30, "@!"})
			aadd (_aCols, { 3, "Data"              , 50, "@!"})
			aadd (_aCols, { 4, "Frete Sobre"       , 60, "@!"})
			aadd (_aCols, { 5, "NF entrada"        , 60, "@!"})
			aadd (_aCols, { 6, "Serie"             , 30, "@!"})
			aadd (_aCols, { 7, "Cliente/Fornecedor", 60, "@!"})
			aadd (_aCols, { 8, "Loja"              , 20, "@!"})
			aadd (_aCols, { 9, "Razao Social"      ,100, "@!"})
			aadd (_aCols, {10, "Conhecimento"      , 60, "@!"})
			aadd (_aCols, {11, "Serie"             , 30, "@!"})
			
			if alltrim(sf1 -> f1_especie) == 'CTE' .or. alltrim(sf1 -> f1_especie) == 'CTR'
				U_F3Array (_aSZH, "Conhecimento X Notas", _aCols, NIL, NIL, "Notas amarradas a este conhecimento de frete", "", .T.)
			else
				U_F3Array (_aSZH, "Notas x Conhecimentos", _aCols, NIL, NIL, "Conhecimentos amarradas a este nota", "", .T.)
			endif				
		_lContinua = .F.
	endif
	
	if _lContinua
		if ! alltrim (GDFieldGet ("D1_COD", 1)) $ _sProdCIF  // Item especifico para frete sobre vendas.
			u_help ("Funcionalidade disponivel apenas para notas envolvendo frete sobre vendas (contendo produto (s)" + _sProdCIF + ").")
			_lContinua = .F.
		endif
	endif
	
	// Monta lista com os fretes previstos para esta transportadora
	if _lContinua
		_oClsFrtFr:_sFornece  = ca100for
		_oClsFrtFr:_sLoja     = cLoja

		_LePrev (.F., _lPaletiz)
		if len (_aFretes) == 0
			_LePrev (.T., _lPaletiz)
		endif

		// Prepara aHeader e aCols para montar uma GetDados onde o usuario vai poder digitar
		// as notas nao previstas (reentregas ou redespachos, por exemplo)
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_06DOC", "ZZZ_06SERI", "ZZZ_06CLI", "ZZZ_06LOJA", "ZZZ_06NOME", "ZZZ_06TPSE"}, .T.))
		aCols = {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))

		// Monta tela para interface com o usuario.
		_aSize := MsAdvSize()
		define msdialog _oDlg title "Amarracao fretes x NF de venda" from 0, 0 to _aSize [6], _aSize [5] of oMainWnd pixel

			@ 15, 10 say "Conhecimento de frete numero " + cNFiscal

			// Monta um markbrowse para o usuario selecionar a nota original.
			if len (_aFretes) == 0
				@ 50, 10 say "Nao ha fretes previstos para este fornecedor."
			else
				@ 25, 10 say "Fretes previstos para este fornecedor:"
				@ 20, 150 button "Buscar todas as previsoes" action _LePrev (.T., _lPaletiz)
				_oLbx := TWBrowse ():New (40, ;  // Linha
				10, ;  // Coluna
				_oDlg:nClientWidth / 2 - 20, ;   // Largura
				_oDlg:nClientHeight / 4, ;  // Altura
				NIL, ;                     // Campos
				{"OK", "NF orig", "Serie", "Cliente", "Loja", "Nome", "Vl.Peso", "Vl.Pedagio", "Vl.Ad Valorem", "Vl.Paletizacao", "Vl.CAT", "Vl.Despacho", "Vl.Gris", "Tipo NF"}, ;
				{20,   35,        20,      35,        20,     60,     45,        45,           45,              45,               45,       45,            45,        20}, ;
				_oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,)             // Etc. Veja pasta IXBPAD
				_oLbx:SetArray (_aFretes)
				_oLbx:bLine := {|| _aFretes [_oLbx:nAt]}
				_oLbx:bLDblClick := {|| _aFretes [_oLbx:nAt, 1] := iif (_aFretes [_oLbx:nAt, 1] == _oBmpOk, _oBmpNo, _oBmpOk), _oLbx:Refresh()}
				@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 90 bmpbutton type 1 action (_lBotaoOK  := .T., _oDlg:End ())
				@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 40 bmpbutton type 2 action (_oDlg:End ())
			endif

			// Monta uma getdados para o usuario informar notas nao previstas / reentregas, etc.
			@ _oDlg:nClientHeight / 4 + 50, 10 say "Notas nao previstas / reentregas e outros."
			_oGetD := MsNewGetDados ():New (_oDlg:nClientHeight / 4 + 60, ;                    // Limite superior
	                                10, ;                     // Limite esquerdo
	                                _oDlg:nClientHeight / 2 - 20, ;                     // Limite inferior
	                                _oDlg:nClientWidth / 2 - 10, ;                     // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
                                    GD_INSERT + GD_UPDATE + GD_DELETE, ;  // [ nStyle ]
                                    "U_FrtSelF1 ()", ;  // [ uLinhaOk ]
                                    "AllwaysTrue ()", ;  //[ uTudoOk ]
                                    NIL, ; //[cIniCpos]
                                    NIL,; //[ aAlter ]
                                    NIL,; // [ nFreeze ]
                                    NIL,; // [ nMax ]
                                    NIL,; // [ cFieldOk ]
                                    NIL,; // [ uSuperDel ]
                                    NIL,; // [ uDelOk ]
                                    _oDlg, ; // [ oWnd ]
                                    aHeader, ;
                                    aCols)

		// Define botoes para a barra de ferramentas
		_bBotaoOK  = {|| iif (U_FrtSelF1 () .and. U_FrtSelF2 (_oBmpOk, _nTotFret), (_lPressOK := .T., _oDlg:End ()), NIL)}
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}
		activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic))

		if _lPressOK  // Usuario confirmou a tela.
			// Guarda os 'recnos' do ZZ1 para os fretes selecionados.
			for _nFrete = 1 to len (_aFretes)
				if _aFretes [_nFrete, 1] == _oBmpOk
					aadd (_oClsFrtFr:_aRegsZZ1, _aFretes [_nFrete, 14])
				endif
			next

			// Guarda as notas nao previstas, reentregas, etc.
			aCols := aclone (_oGetD:acols)
			for _n = 1 to len (aCols)
				N := _n
				if ! GDDeleted () .and. ! empty (GDFieldGet ("ZZZ_06DOC"))
					aadd (_oClsFrtFr:_aNaoPrev, array (3))
					_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevDoc]         = GDFieldGet ("ZZZ_06DOC")
					_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevSerie]       = GDFieldGet ("ZZZ_06SERI")
					_oClsFrtFr:_aNaoPrev [len (_oClsFrtFr:_aNaoPrev), .FrtNaoPrevTipoServico] = GDFieldGet ("ZZZ_06TPSE")
				endif
			next

			// Busca CC pelas notas de saida. Como posso ter mais de uma nota, por
			// enquanto vou pegar da primeira (como jah era antes) e depois tratarei isso.
			_svend = ""
			if len (_oClsFrtFr:_aRegsZZ1) > 0
				zz1 -> (dbgoto (_oClsFrtFr:_aRegsZZ1 [1]))
				_sVend = fbuscacpo ("SF2", 1, xfilial ("SF2") + zz1 -> zz1_docs + zz1 -> zz1_series, 'F2_VEND1')
			elseif len (_oClsFrtFr:_aNaoPrev) > 0
				_sVend = fbuscacpo ("SF2", 1, xfilial ("SF2") + _oClsFrtFr:_aNaoPrev [1, 1] + _oClsFrtFr:_aNaoPrev [1, 2], 'F2_VEND1')
			end
		else
			_oClsFrtFr := NIL
		endif
	endif

return

// --------------------------------------------------------------------------
// Leitura dos fretes previstos para a transportadora atual.
static Function _LePrev (_lTodos, _lPaletiz)
	local _sQuery := ""
	//local _aRet   := {}
	local _nFrete := 0

	// Para paletizacoes nao traz fretes previstos. Isso apenas para evitar que o conhecimento de
	// paletizacao chegue antes do conhecimento de frete e seja lancado como frete por engano do usuario...
	if ! _lPaletiz
		_sQuery := ""
		_sQuery += " Select '' as OK, ZZ1_DOCS, ZZ1_SERIES, F2_CLIENTE, F2_LOJA, A1_NOME, ZZ1_PESO, ZZ1_PEDAG, ZZ1_ADVALO, ZZ1_PALET, ZZ1_CAT, ZZ1_DESPAC, ZZ1_GRIS, ZZ1.R_E_C_N_O_, F2_TIPO"
		_sQuery += "   From " + RetSQLName ("ZZ1") + " as ZZ1, "
		_sQuery +=              RetSQLName ("SF2") + " as SF2 "
		_sQuery +=   " Left Join " + RetSQLName ("SA1") + " SA1 "
		_sQuery +=         " on (SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sQuery +=         " And SA1.D_E_L_E_T_ = ''"
		_sQuery +=         " And SA1.A1_COD     = SF2.F2_CLIENTE"
		_sQuery +=         " And SA1.A1_LOJA    = SF2.F2_LOJA)"
		_sQuery += "  Where ZZ1.D_E_L_E_T_ = ''"
		_sQuery += "    And SF2.D_E_L_E_T_ = ''"
		_sQuery += "    And ZZ1.ZZ1_FILIAL = '" + xfilial ("ZZ1") + "'"
		_sQuery += "    And SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sQuery += "    And ZZ1.ZZ1_FORNEC = '" + CA100FOR + "'"
		_sQuery += "    And ZZ1.ZZ1_LOJAFO = '" + CLOJA + "'"
		_sQuery += "    And ZZ1.ZZ1_DOCE   = ''"
		_sQuery += "    And ZZ1.ZZ1_SERIEE = ''"
		_sQuery += "    And SF2.F2_DOC     = ZZ1.ZZ1_DOCS"
		if ! _lTodos
			_sQuery += " And SF2.F2_EMISSAO >= '" + dtos (dDataBase - 60) + "'"
		endif
		_sQuery += "    And SF2.F2_SERIE   = ZZ1.ZZ1_SERIES"
		_sQuery += "    And not exists ("
		_sQuery +=        " select * from " + RetSQLName ("SZH") + " SZH "
		_sQuery +=        "  where SZH.D_E_L_E_T_ = ''"
		_sQuery +=        "    and SZH.ZH_FILIAL  = '" + xfilial ("SZH")   + "'"
		_sQuery +=        "    and SZH.ZH_NFSAIDA = ZZ1.ZZ1_DOCS"
		_sQuery +=        "    and SZH.ZH_SERNFS  = ZZ1.ZZ1_SERIES)"
		_sQuery += "  Order by ZZ1_DOCS"
		_aFretes := aclone (U_Qry2Array (_sQuery))
		
		// Passa todas as linhas da array preenchendo a primeira coluna com .F. para poder ser usada no MBArray.
		for _nFrete = 1 to len (_aFretes)
			_aFretes [_nFrete, 1] = _oBmpNo
	
			// Se for nota que utiliza fornecedor, busca o nome do mesmo.
			if _aFretes [_nFrete, 15] $ "BD"
				_aFretes [_nFrete, 6] = fBuscaCpo ("SA2", 1, xfilial ("SA2") + _aFretes [_nFrete, 4] + _aFretes [_nFrete, 5], "A2_NOME")
			endif
	
			// Se esta rotina estiver sendo chamada a partir da importacao de conhecimentos
			// de frete e a rotina de importacao tiver especificado o numero da NF original,
			// jah posso deixar essa nota marcada.
			// Acho que usarei isto na importacao de XML de CT-e.
			//if funname () == "IMPCONH" .and. type ("_xNFCFORI") == "C" .and. _aFretes [_nFrete, 2] $ _xNFCFORI
			//	_aFretes [_nFrete, 1] = _oBmpOk
			//endif
		next
	endif

	// Atualiza o browse em tela.
	if _lTodos .and. valtype (_oLbx) == "O"
		_oLbx:SetArray (_aFretes)
		_oLbx:bLine := {|| _aFretes [_oLbx:nAt]}
		_oLbx:bLDblClick := {|| _aFretes [_oLbx:nAt, 1] := iif (_aFretes [_oLbx:nAt, 1] == _oBmpOk, _oBmpNo, _oBmpOk), _oLbx:Refresh()}
	endif
return

// --------------------------------------------------------------------------
// Valida 'linha OK' da GetDados.
User Function FrtSelF1 ()
	local _lRet := .T.
	local _oSQL := NIL
	local _n    := N

	aHeader := _oGetD:aHeader
	aCols := _oGetD:acols
	N := _oGetD:nAt

	if _lRet .and. ascan (_aFretes, {|_aVal| _aVal [2] == GDFieldGet ("ZZZ_06DOC") .and. _aVal [3] == GDFieldGet ("ZZZ_06SERI")}) > 0
		u_help ("Nota fiscal consta no browse acima. Nao pode ser redigitada aqui, nem mesmo com a linha deletada.")
		_lRet = .F.
	endif
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZZ_06DOC"))
		_lRet = GDCheckKey ({"ZZZ_06DOC", "ZZZ_06SERIE", "ZZZ_06TPSE"}, 4)
	endif
	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZZ_06DOC"))
		sf2 -> (dbsetorder (1))
		if ! sf2 -> (dbseek (xfilial ("SF2") + GDFieldGet ("ZZZ_06DOC") + GDFieldGet ("ZZZ_06SERI"), .F.))
			u_help ("Nota fiscal '" + GDFieldGet ("ZZZ_06DOC") + "' nao encontrada.")
			_lRet = .F.
		else
			if sf2 -> f2_emissao < dDataBase - 60
				_lRet = msgnoyes ("Nota fiscal '" + GDFieldGet ("ZZZ_06DOC") + "' foi emitida em " + dtoc (sf2 -> f2_emissao) + ". O conhecimento de frete encontra-se muito atrasado. Confirma essa nota?","Confirmar")
			endif
		endif
	endif

	if _lRet .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZZZ_06DOC"))
		if empty (GDFieldGet ("ZZZ_06TPSE"))
			u_help ("Se informar o campo " + alltrim (RetTitle ("ZZZ_06DOC")) + ", informe tambem o campo " + alltrim (RetTitle ("ZZZ_06TPSE")) + ".")
			_lRet = .F.
		endif
		if _lRet .and. GDFieldGet ("ZZZ_06TPSE") == "1"  // Entrega normal
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select ZH_NFFRETE from " + RetSQLName ("SZH") + " SZH "
			_oSQL:_sQuery +=  " where SZH.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " and SZH.ZH_FILIAL  = '" + xfilial ("SZH")   + "'"
			_oSQL:_sQuery +=    " and SZH.ZH_NFSAIDA = '" + GDFieldGet ("ZZZ_06DOC") + "'"
			_oSQL:_sQuery +=    " and SZH.ZH_SERNFS  = '" + GDFieldGet ("ZZZ_06SERI") + "'"
			_oSQL:_sQuery +=    " and SZH.ZH_TPDESP  = '1'"
			if ! empty (_oSQL:RetQry ())
				u_help ("A nota fiscal de venda '" + GDFieldGet ("ZZZ_06DOC") + "' ja tem entrega amarrada a ela pelo conhecimento de frete '" + _oSQL:_xRetQry + "'. Informe outra NF de venda ou altere o campo " + alltrim (RetTitle ("ZZZ_06TPSE")) + ".")
				_lRet = .F.
			endif
		endif
	endif

	N := _n
return _lRet

// --------------------------------------------------------------------------
// Valida 'tudo OK' da tela
User Function FrtSelF2 (_oBmpOk, _nTotFret)
	local _lRet     := .T.
	local _lTemPrev := .T.
	local _nLinha   := 0
	local _nTotSaid := 0
	local _n        := N

	aHeader := _oGetD:aHeader
	aCols := _oGetD:acols
	N := _oGetD:nAt

	// Se nao tem nenhuma nota prevista, quero pelo menos uma nao prevista.
	if _lRet
		_lTemPrev = .F.
		for _nLinha = 1 to len (_aFretes)
			if _aFretes [_nLinha, 1] == _oBmpOk
				_lTemPrev = .T.
				exit
			endif
		next
		if ! _lTemPrev
			if empty (GDFieldGet ("ZZZ_06DOC"))
				u_help ("Selecione pelo menos uma nota prevista ou informe uma nao prevista.")
				_lRet = .F.
			endif
		endif
	endif

	// Verifica se o frete fica muito divergente do valor da(s) nota(s) de saida.
	if _lRet
		_nTotSaid = 0
		sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL
		for _nLinha = 1 to len (_aFretes)
			if _aFretes [_nLinha, 1] == _oBmpOk
				if sf2 -> (dbseek (xfilial ("SF2") + _aFretes [_nLinha, 2] + _aFretes [_nLinha, 3], .F.))
					_nTotSaid += sf2 -> f2_valmerc
				endif
			endif
		next
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha) .and. ! empty (GDFieldGet ("ZZZ_06DOC"))
				if sf2 -> (dbseek (xfilial ("SF2") + GDFieldGet ("ZZZ_06DOC") + GDFieldGet ("ZZZ_06SERI"), .F.))
					_nTotSaid += sf2 -> f2_valmerc
				endif
			endif
		next
		if _nTotFret > (_nTotSaid * .2)  // A principio, o frete nao deve passar de 20% do faturamento
			_lRet = msgnoyes ("Valor do frete (" + cvaltochar (_nTotFret) + ") excessivamente alto para as notas de saida informadas (" + cvaltochar (_nTotSaid) + ") . Confirma assim mesmo?","Confirmar")
			_oClsFrtFr:_bValor  = .T. // se este objeto for igual a .T., significa que existe diferença entre valores
		endif
	endif

	N := _n
return _lRet                                                                                       
