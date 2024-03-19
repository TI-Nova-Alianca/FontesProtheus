// Programa.:  BMRP
// Autor....:  Robert Koch
// Data.....:  21/10/2015
// Descricao:  Bancada MRP (tela auxiliar para programacao de producao).
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processamento #consulta
// #Descricao         #Bancada MRP (tela auxiliar para programacao de producao)
// #PalavasChave      #programacao_de_producao #producao #PCP 
// #TabelasPrincipais #SB1 #SD3 #SB2
// #Modulos 		  #EST #PCP #OMS 
//
// Historico de alteracoes:
// 10/11/2015 - Robert  - Criada tela de simulacao de OP
// 18/11/2015 - Robert  - Na simulacao de OP busca estoque disponivel no local padrao do produto, mas busca empenhos em qualquer local.
// 08/12/2015 - Robert  - Aumentada area do grafico em tela
//                      - Separados parametros de PA x materiais.
// 21/06/2016 - Robert  - Reposicionamento de tela para Protheus 12.
//                      - Incluidas colunas de cor/linha de envase do produto (quando acabados), saldo de/em terceiros.
//                      - Simulador de OP abre a estrutura nivel a nivel.
// 16/08/2016 - Robert  - Filtro de tipo 'MP' trocado por grupo '0400' na simulacao de componentes de OP para ocultar uvas e mostrar outras MP.
//                      - Incluidas colunas de qt por embalagem, litros por embalagem, marca comercial, comum/vinifera, media saidas geral.
//                      - Criada opcao de informar lista de produtos ou produto de...ate
//                      - Coluna de empenhos em PV passa a ser lida direto do SC6.
// 24/02/2017 - Robert  - Tabela de marcas comerciais migrada do SX5 (tab.Z7) para ZX5 (tab.40).
// 14/09/2017 - Robert  - Considerava apenas C6_BLQ = 'R'
// 16/01/2019 - Robert  - Separadas colunas de SC1 e SC7 na simulacao de OP.
// 01/04/2019 - Robert  - Migrada tabela 88 do SX5 para 38 do ZX5 (linhas comerciais).
// 10/04/2019 - Robert  - Migrada tabela 98 do SX5 para 50 do ZX5.
// 20/05/2019 - Catia   - erro X5_TABELA = 39
// 22/05/2019 - Robert  - Erro ao buscar estoque na simulacao de OP quando nao existia SB2 para o componente (GLPI 5955)
// 04/07/2019 - Catia   - tirado o tratamento do campo B1 _ SITUACA
// 08/04/2020 - Claudia - Ajustada a pesquisa de simulação de OP, confome GLPI: 7599
// 22/04/2020 - Claudia - Acrescentado quantidades em almoxarifados na simulação de OP. GLPI: 7837
// 23/04/2020 - Claudia - Incluida a busca de cada estrutura na Simulação OP. GLPI: 7841
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 17/08/2020 - Robert  - Comentariadas declaracoes de variaveis nao usadas, desabilitada geracao de logs.
// 09/04/2021 - Robert  - Inseridos logs para analise de performance (GLPI 9797)
//                      - Incluido teste do B1_FILIAL no na query _sExistsB1 - reduziu de 627 para 33 segundos (GLPI 9797)
// 20/06/2022 - Claudia - Incluida importação .csv na simulação. GLPI: 12219
// 12/08/2022 - Claudia - Incluida opção de revisão ativa. GLPI:12466
// 01/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#include "protheus.ch"

user function BMRP ()
	local _nTipoPlan   := 0
	private _sTipoPlan := ''
	private cPerg      := ""

	cPerg = "BMRP1"
	_ValidPerg ()
	
	cPerg = "BMRP2"
	_ValidPerg ()
	
	cPerg = "BMRP3"
	_ValidPerg ()
	
	_nTipoPlan = aviso ("Bancada MRP - Selecione o tipo de analise", ;
						"Selecione o tipo de produto a ser analisado", ;
						{"Acabados", "Materiais", "Simulação","Cancelar"}, ;
						3, ;
						"Tipo de analise")
	if _nTipoPlan == 1
		_sTipoPlan = 'A'
		cPerg = "BMRP1"
	elseif _nTipoPlan == 2
		_sTipoPlan = 'M'
		cPerg = "BMRP2"
	elseif _nTipoPlan == 3
		_sTipoPlan = 'S'
		cPerg = "BMRP3"		
	endif
	
	if _sTipoPlan == 'S'	
		if Pergunte (cPerg, .T.)
			processa ({|| _TelaSimulacao ()})
		endif
	
	else
		if Pergunte (cPerg, .T.)
			processa ({|| _Tela ()})
		endif
	endif
return
//
// --------------------------------------------------------------------------
static function _Tela ()
	local _lContinua   := .T.
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _aSize       := {}  // Para posicionamento de objetos em tela
	local _oDlg        := NIL
	local _aHead1      := {}
	local _aCols1      := {}
	local _aArqTrb     := {}
	private _oGetD1    := NIL  // Deixar private para ser vista em outras rotinas.
	private _oTxtBrw1  := NIL
	private _oTxtBrw2  := NIL
	private _oTxtBrw3  := NIL
	private _oTxtBrw4  := NIL
	private _oTxtBrw5  := NIL
	private _oTxtBrw6  := NIL
	private aGets      := {}
	private aTela      := {}
	private aRotina    := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido pela MSGetDados!!!
	private aHeader    := {}
	private aCols      := {}
	private N          := 0
	private _aPeriodos := {}  // Periodos para analises de produto na getdados
	private _aSazo     := {}  // Periodos para analises de sazonalidades
	private _sPathGraf := ""
	private _sArqGraf  := ""
	private _lPrimVez  := .T.
	private _lGrafico  := iif (_sTipoPlan == 'A', (mv_par06 == 1), (mv_par05 == 1))  //(mv_par05 == 1)

	u_logsx1 (cPerg)

	if _lContinua
		_lContinua = _LeDados (@_aArqTrb)
	endif

	_aHead1 := aclone (aHeader)
	_aCols1 := aclone (aCols)

	// Define tamanho da tela
	if _lContinua
		_aSize := MsAdvSize()

		define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Bancada MRP"

		// P12: linha inicial pelo menos 25 ou 30
		_oGetD1 := MsNewGetDados ():New (iif ('TOTVS 2011' $ cVersao, 1, 31), ; //55, ;     // Limite superior
	                                5, ;                             						// Limite esquerdo 
	                                iif (_lGrafico, _oDlg:nClientHeight / 4 - 20, _oDlg:nClientHeight / 2 - iif ('TOTVS 2011' $ cVersao, 30, 1)), ;  // Limite inferior
	                                _oDlg:nClientWidth / 2 - 10, ;                          // Limite direito
                                    2, ;                                                    // [ nStyle ]
                                    "AllwaysTrue ()", ;              						// [ uLinhaOk ]
                                    "AllwaysTrue ()", ;              						// [ uTudoOk ]
                                    NIL, ; 													// [cIniCpos]
                                    NIL,; 													// [ aAlter ]
                                    NIL,; 													// [ nFreeze ]
                                    NIL,; 													// [ nMax ]
                                    NIL,; 													// [ cFieldOk ]
                                    NIL,;				 									// [ uSuperDel ]
                                    NIL,; 													// [ uDelOk ]
                                    _oDlg,; 												// [ oWnd ]
                                    _aHead1,; 												// [ ParHeader ]
                                    _aCols1) 												// [ aParCols ]
		
		_oGetD1:oBrowse:bLDblClick := {|| _DblClick ()}
		_oGetD1:oBrowse:bRClicked := {|_o, _x, _y| _RClick (_o, _x, _y)} 

		if _lGrafico
			// Chama atualizacao da tela a cada troca de linha no browse.
			_oGetD1:oBrowse:bChange := {|| _AtuTela (_oGetD1:nAt)}

			// Janela para grafico.
			_oGraf := TIBrowser():New (_oDlg:nClientHeight / 4 - 15, ;  // Limite superior
			                           							  5, ;  // Limite esquerdo
			                           _oDlg:nClientWidth /  2 - 15, ;  // Largura
			                           _oDlg:nClientHeight / 4 - 30, ;  // Altura
			                           							 "", ;  // Pagina inicial
			                           							 _oDlg) // Dialogo onde serah criado.
		endif

		// Define botoes para a barra de ferramentas
		_bBotaoOK  = {|| _oDlg:End ()}
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}

		aadd (_aBotAdic, {"", {|| aHeader := aclone (_oGetD1:aHeader), aCols := aclone (_oGetD1:aCols), U_aColsXLS ()}, "Exp.planilha"})
		activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), _AtuTela (_oGetD1:nAt))
	endif

	U_ArqTrb ('FechaTodos',,,, @_aArqTrb)
return
// --------------------------------------------------------------------------
// Atualiza tela ao mudar linha do browse.
static function _AtuTela (_nLinha)
	local _sXML     := ""
	local _nSaidas  := 0
	local _sProduto := ""
	local _sLinProd := ""
	local _nAno     := 0
	local _nMes     := 0
	local _sAno     := ""

	if _lGrafico

		aCols = aclone (_oGetD1:aCols)
		N = _oGetD1:nAt
		_sProduto = GDFieldGet ("PRODUTO")
		if _sTipoPlan == 'A'
			_sLinProd = GDFieldGet ("LINHAPROD")
		else
			_sLinProd = ''
		endif

		// Monta arquivo HTML para mostrar os graficos.
		if _lPrimVez
			_sArqGraf  = "U_BMRP_" + cvaltochar (ThreadId ())
			_sLargGraf = cvaltochar (_oGraf:nClientWidth - 50)
			_sAltGraf  = cvaltochar (_oGraf:nClientHeight - 60) //50)
			_sHTM := ''
			_sHTM += '<html xmlns="http://www.w3.org/1999/xhtml">'
			_sHTM += '<head>'
			_sHTM += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />'
			_sHTM += '<title>Grafico comparativo</title>'
			_sHTM += '<script language="JavaScript" src="FusionCharts.js"></script>'
			_sHTM += '</head>'
			_sHTM += '<body>'
			_sHTM += '<table width="98%" border="1" cellspacing="0" cellpadding="3" align="center">'
			_sHTM +=   '<tr>'
			_sHTM +=     '<td valign="top" class="text" align="center"> <div id="graf1" align="center"> </div>'
			_sHTM +=       '<script type="text/javascript">'
			_sHTM +=         'var chart = new FusionCharts("FCF_MSLine.swf",'  // Modelo de grafico
			_sHTM +=                                      '"ChartId",'  // Identificacao do grafico
			_sHTM +=                                      '"' + _sLargGraf + '",'  // Largura
			_sHTM +=                                      '"' + _sAltGraf + '");'  // Altura
			_sHTM +=         'chart.setDataURL("' + _sArqGraf + '.xml");'
			_sHTM +=         'chart.render("graf1");'
			_sHTM +=       '</script>'
			_sHTM +=     '</td>'
			_sHTM +=   '</tr>'
			_sHTM += '</table>'
			_sHTM += '</body>'
			_sHTM += '</html>'
			_sPathGraf = U_GeraGraf (_sArqGraf, _sHTM, "")
			_lPrimVez = .F.
		endif

		// Cria arquivo XML para geracao do grafico.
		_sXML := ""
		_sXML += "<graph animation='0' "  // 0=Sem animacao; 1=com animacao (fica meio lento ao mudar de linha)
		_sXML += "caption='Sazonalidade das saidas' subcaption='' "
		_sXML += "hovercapbg='FFECAA' hovercapborder='F47E00' formatNumberScale='0' decimalPrecision='0' showvalues='0' "
		_sXML += "numdivlines='3' numVdivlines='0' "
		_sXML += "yaxisname='' xaxisname='' "  // Nome das linhas e das colunas, respectivamente.
		_sXML += "decimalSeparator=',' thousandSeparator='.' "  // Formata separador de milhar e decimais.
		_sXML += "numberSuffix=' " + GDFieldGet ("UNMEDIDA") + "'"
		_sXML += "showShadow='0'"
		_sXML += "canvasBorderColor='CED7EF'"
		_sXML += "rotateNames='0'>"
		
		// Categorias (eixo X): periodos
		_sXML += "<categories >" 
		for _nMes = 1 to 12
			_sXML += "<category name='" + {'JAN','FEV','MAR','ABR','MAI','JUN','JUL','AGO','SET','OUT','NOV','DEZ'} [_nMes] + "' />" 
		next
		_sXML += "</categories >" 
		
		// Datasets (conjuntos de dados do eixo Y) para os valores do produto.
		_sAno = strzero (year (date ()) - 1, 4)
		_sXML += "<dataset seriesName='Produto " + alltrim (_sProduto) + " (" + strzero (year (date ()) - 1, 4) + ")'"
		_sXML += " color='FFDAB0' anchorBorderColor='FFDAB0' anchorBgColor='FFDAB0'>"
		for _nMes = 1 to 12
			_nSaidas = 0
			_sai -> (dbseek (cFilAnt + _sProduto + _sAno + strzero (_nMes, 2), .T.))
			do while ! _sai -> (eof ()) .and. _sai -> filial == cFilAnt .and. _sai -> produto == _sProduto .and. _sai -> ano == _sAno .and. _sai -> mes == substr (_aSazo [1, _nMes], 5, 2) 
				_nSaidas += _sai -> quant
				_sai -> (dbskip ())
			enddo
			_sXML += "<set value='" + cvaltochar (_nSaidas) + "' />"
		next
		_sXML += "</dataset>" 

		_sXML += "<dataset seriesName='Prod." + alltrim (_sProduto) + " (" + strzero (year (date ()), 4) + ")'"
		_sXML += " color='FF0000' anchorBorderColor='FF0000' anchorBgColor='FF0000'>" 
		_sAno = strzero (year (date ()), 4)
		for _nMes = 1 to 12
			_nSaidas = 0
			_sai -> (dbseek (cFilAnt + _sProduto + _sAno + strzero (_nMes, 2), .T.))
			do while ! _sai -> (eof ()) .and. _sai -> filial == cFilAnt .and. _sai -> produto == _sProduto .and. _sai -> ano == _sAno .and. _sai -> mes == substr (_aSazo [1, _nMes], 5, 2) 
				_nSaidas += _sai -> quant
				_sai -> (dbskip ())
			enddo
			_sXML += "<set value='" + cvaltochar (_nSaidas) + "' />"
		next
		_sXML += "</dataset>"

		// Datasets (conjuntos de dados) para os valores da linha de produtos.
		if ! empty (_sLinProd)
			for _nAno = 1 to len (_aSazo)
				_sXML += "<dataset seriesName='" + alltrim (_sLinProd) + " (" + left (_aSazo [_nAno, 1], 4) + ")'"
				if _nAno = 1
					_sXML += " color='CED7EA' anchorBorderColor='CED7EA' anchorBgColor='CED7EA'>"
				elseif _nAno = 2
					_sXML += " color='0080FF' anchorBorderColor='0080FF' anchorBgColor='0080FF'>"
				elseif _nAno = 3
					_sXML += " color='000000' anchorBorderColor='000000' anchorBgColor='000000'>"
				endif
				for _nMes = 1 to len (_aSazo [_nAno])
					_nSaidas = 0
					_saiLin -> (dbseek (cFilAnt + _sLinProd + _aSazo [_nAno, _nMes], .T.))
					do while ! _saiLin -> (eof ()) .and. _saiLin -> filial == cFilAnt .and. _saiLin -> Linha == _sLinProd .and. _saiLin -> ano == left (_aSazo [_nAno, _nMes], 4) .and. _saiLin -> mes == substr (_aSazo [_nAno, _nMes], 5, 2) 
						_nSaidas += _saiLin -> quant
						_saiLin -> (dbskip ())
					enddo
					_sXML += "<set value='" + cvaltochar (_nSaidas) + "' />" 
				next
				_sXML += "</dataset>"
			next
		endif
		
		_sXML += "</graph>" 
		_nHdl = fcreate (_sPathGraf + _sArqGraf + ".xml", 0)
		fwrite (_nHdl, _sXML)
		fclose (_nHdl)

		_oGraf:Navigate (_sPathGraf + _sArqGraf + ".htm")
	endif
return
//
// --------------------------------------------------------------------------
// Funcao executada pelo duplo clique do mouse.
static function _DblClick ()
//	local _sCampo := aHeader [_oGetD1:oBrowse:nColPos, 2]
return
//
// --------------------------------------------------------------------------
// Funcao executada pelo clique do botao direito do mouse.
static function _RClick (_o, _x, _y)
	local _oMenu     := NIL
	Local _oMenuItem := {}
	local _sProduto  := GDFieldGet ("PRODUTO", _oGetD1:nAt, .f., _oGetD1:aHeader, _oGetD1:aCols)
	local _aSimula   := {}
 
	MENU _oMenu POPUP 
	aAdd( _oMenuItem, MenuAddItem ("Ordernar por esta coluna",,, .T.,,,, _oMenu, {|| (asort (_oGetD1:aCols,,, {|_x, _y| _x [_oGetD1:oBrowse:nColPos] < _y [_oGetD1:oBrowse:nColPos]}), _oGetD1:Refresh ()) },,,,,{|| .T.}) ) 
	aAdd( _oMenuItem, MenuAddItem ("Visualizar cadastro produto",,, .T.,,,, _oMenu, {|| _DetSB1 (_sProduto) },,,,,{|| .T.}) ) 
	aAdd( _oMenuItem, MenuAddItem ("Detalhar estoques",,, .T.,,,, _oMenu, {|| MaViewSB2 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar empenhos",,, .T.,,,, _oMenu, {|| _DetSD4 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar pedidos de venda",,, .T.,,,, _oMenu, {|| _DetSC5 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar previsoes de venda",,, .T.,,,, _oMenu, {|| _DetSC4 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar pedidos de compra",,, .T.,,,, _oMenu, {|| _DetSC7 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar solicitacoes de compra",,, .T.,,,, _oMenu, {|| _DetSC1 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar ordens de producao",,, .T.,,,, _oMenu, {|| _DetSC2 (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar movtos. de entrada",,, .T.,,,, _oMenu, {|| _DetEntr (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Detalhar movtos. de saida",,, .T.,,,, _oMenu, {|| _DetSaid (_sProduto) },,,,,{|| .T.}) )
	aAdd( _oMenuItem, MenuAddItem ("Simular OP",,, .T.,,,, _oMenu, {|| _SimulOP (_sProduto,1,_aSimula,.F.,"N") },,,,,{|| .T.}) )
	ENDMENU

	// Posiciona o menu conforme a interface em uso
	if oApp:lFlat
		_oMenu:Activate (_x + 15, _y + 125)
	else
		_oMenu:Activate (_x, _y)
	endif
return
// --------------------------------------------------------------------------
// Visualiza cadastro do produto.
static function _DetSB1 (_sProduto)
	sb1 -> (dbsetorder (1))
	if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
		A010Visul ("SB1", sb1 -> (recno ()), 2)
	endif
return
// --------------------------------------------------------------------------
// Detalha empenhos em OP
static function _DetSD4 (_sProduto)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (D4_DATA) AS DATA_EMPENHO, D4_QUANT AS QT_EMPENHO, D4_OP AS NUMERO_OP, C2_PRODUTO AS PRODUTO_FINAL, B1_DESC AS DESCRICAO_PRODUTO_FINAL, C2_QUANT AS QT_PRODUZIR, B1_UM AS UN_MEDIDA"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD4") + " SD4, "
	_oSQL:_sQuery +=             RetSQLName ("SC2") + " SC2, "
	_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE SD4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SD4.D4_FILIAL  = '" + xfilial ("SD4") + "'"
	_oSQL:_sQuery +=   " AND SD4.D4_COD     = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SD4.D4_QUANT   > 0"
	_oSQL:_sQuery +=   " AND SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = SD4.D4_FILIAL"
	_oSQL:_sQuery +=   " AND SC2.C2_NUM     = SUBSTRING (SD4.D4_OP, 1, 6)"
	_oSQL:_sQuery +=   " AND SC2.C2_ITEM    = SUBSTRING (SD4.D4_OP, 7, 2)"
	_oSQL:_sQuery +=   " AND SC2.C2_SEQUEN  = SUBSTRING (SD4.D4_OP, 9, 3)"
	_oSQL:_sQuery +=   " AND SC2.C2_ITEMGRD = SUBSTRING (SD4.D4_OP, 12, 2)"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     = SC2.C2_PRODUTO"
	_oSQL:_sQuery += " ORDER BY D4_DATA, D4_OP"

	_oSQL:F3Array ("Empenhos do produto '" + _sProduto + "' em ordens de producao")
return
//
// --------------------------------------------------------------------------
// Detalha OP
static function _DetSC2 (_sProduto)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (C2_DATPRF) AS DATA_PREVISTA, C2_QUANT - C2_QUJE AS QT_A_PRODUZIR, C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD AS NUMERO_OP,"
	_oSQL:_sQuery +=       " B1_UM AS UN_MEDIDA, C2_TPOP AS FIRME_PREV, C2_VALIBPR AS LIBERADA_PRODUCAO, "
	_oSQL:_sQuery +=         _oSQL:CaseX3CBox ("C2_VAOPESP") + " AS FINALIDADE, "
	_oSQL:_sQuery +=       " C2_OBS AS OBSERVACOES_DA_OP"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC2") + " SC2, "
	_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE SC2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC2.C2_FILIAL  = '" + xfilial ("SC2") + "'"
	_oSQL:_sQuery +=   " AND SC2.C2_PRODUTO = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SC2.C2_DATRF   = ''"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     = SC2.C2_PRODUTO"
	_oSQL:_sQuery += " ORDER BY C2_DATPRF, C2_NUM, C2_ITEM, C2_SEQUEN, C2_ITEMGRD"

	_oSQL:F3Array ("Ordens de producao do produto '" + _sProduto + "'")
return
//
// --------------------------------------------------------------------------
// Detalha pedidos de compra.
static function _DetSC7 (_sProduto)
	local _oSQL := ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (C7_DATPRF) AS DATA_PREVISTA, C7_QUANT - C7_QUJE AS QT_A_RECEBER, C7_UM AS UN_MEDIDA, C7_NUM AS PEDIDO, C7_ITEM AS ITEM_PEDIDO, C7_FORNECE AS FORNECEDOR, C7_LOJA AS LOJA, SA2.A2_NOME AS NOME_FORNECEDOR, C7_NUMSC AS SOLICITACAO, C7_ITEMSC AS ITEM_SOLICIT,"
	_oSQL:_sQuery +=       " ISNULL ((SELECT TOP 1 C1_SOLICIT
	_oSQL:_sQuery +=                  " FROM " + RetSqlName ("SC1") + " SC1"
	_oSQL:_sQuery +=                 " WHERE SC1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                   " AND SC1.C1_FILIAL   = SC7.C7_FILIAL"
	_oSQL:_sQuery +=                   " AND SC1.C1_NUM      = SC7.C7_NUMSC"
	_oSQL:_sQuery +=                   " AND SC1.C1_ITEM     = SC7.C7_ITEMSC"
	_oSQL:_sQuery +=                "), '') AS NOME_SOLICITANTE"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC7") + " SC7, "
	_oSQL:_sQuery +=             RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery += " WHERE SC7.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SC7.C7_FILIAL   = '" + xfilial ("SC7") + "'"
	_oSQL:_sQuery +=   " AND SC7.C7_PRODUTO  = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SC7.C7_QUANT   >  C7_QUJE"
	_oSQL:_sQuery +=   " AND SC7.C7_ENCER   != 'E'"
	_oSQL:_sQuery +=   " AND SC7.C7_RESIDUO != 'S'"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_COD      = SC7.C7_FORNECE"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = SC7.C7_LOJA"
	_oSQL:_sQuery += " ORDER BY C7_DATPRF, C7_NUM, C7_ITEM"
	
	_oSQL:F3Array ("Pedidos de compra do produto '" + _sProduto + "'")
return
//
// --------------------------------------------------------------------------
// Detalha solicitacoes de compra
static function _DetSC1 (_sProduto)
	local _oSQL := ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (C1_DATPRF) AS DATA_PREVISTA, C1_QUANT - C1_QUJE AS QT_SOLICITADA, C1_UM AS UN_MEDIDA, C1_NUM AS SOLICITACAO, C1_ITEM AS ITEM_SOLIC, C1_SOLICIT AS SOLICITANTE, C1_PEDIDO AS PED_COMPRA, C1_ITEMPED AS ITEM_PED"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC1") + " SC1 "
	_oSQL:_sQuery += " WHERE SC1.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND SC1.C1_FILIAL   = '" + xfilial ("SC1") + "'"
	_oSQL:_sQuery +=   " AND SC1.C1_PRODUTO  = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SC1.C1_QUANT   >  C1_QUJE"
	_oSQL:_sQuery +=   " AND SC1.C1_RESIDUO != 'S'"
	_oSQL:_sQuery += " ORDER BY C1_DATPRF, C1_NUM, C1_ITEM"
	//_oSQL:Log ()
	_oSQL:F3Array ("Solicitacoes de compra do produto '" + _sProduto + "'")
return
//
// --------------------------------------------------------------------------
// Detalha previsoes de venda.
static function _DetSC4 (_sProduto)
	local _oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (C4_DATA) AS DATA_PREVISAO, C4_QUANT AS QUANTIDADE, C4_DOC AS DOCUMENTO"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC4") + " SC4 "
	_oSQL:_sQuery += " WHERE SC4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC4.C4_FILIAL  = '" + xfilial ("SC4") + "'"
	_oSQL:_sQuery +=   " AND SC4.C4_PRODUTO = '" + _sProduto + "'"
	_oSQL:_sQuery += " ORDER BY C4_DATA"
	
	_oSQL:F3Array ("Previsoes de venda do produto '" + _sProduto + "'")
return
//
// --------------------------------------------------------------------------
// Detalha pedidos de venda.
static function _DetSC5 (_sProduto)
	local _oSQL := ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT dbo.VA_DTOC (C6_ENTREG) AS DATA_ENTREGA, C6_QTDVEN - C6_QTDENT AS QUANTIDADE, C6_NUM AS PEDIDO, C5_CLIENTE AS CLI_FORN, C5_LOJACLI AS LOJA, "
	_oSQL:_sQuery +=       " ISNULL (CASE WHEN C5_TIPO IN ('D', 'B') THEN SA2.A2_NOME ELSE SA1.A1_NOME END, '') AS NOME"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC6") + " SC6, "
	_oSQL:_sQuery +=             RetSQLName ("SC5") + " SC5 "
	_oSQL:_sQuery +=           " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery +=             " ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=             " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=             " AND SA1.A1_COD     = SC5.C5_CLIENTE"
	_oSQL:_sQuery +=             " AND SA1.A1_LOJA    = SC5.C5_LOJACLI)"
	_oSQL:_sQuery +=           " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=             " ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=             " AND SA2.A2_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=             " AND SA2.A2_COD     = SC5.C5_CLIENTE"
	_oSQL:_sQuery +=             " AND SA2.A2_LOJA    = SC5.C5_LOJACLI)"
	_oSQL:_sQuery += " WHERE SC6.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC6.C6_FILIAL  = '" + xfilial ("SC6") + "'"
	_oSQL:_sQuery +=   " AND SC6.C6_PRODUTO = '" + _sProduto + "'"
	_oSQL:_sQuery +=   " AND SC6.C6_QTDVEN  > SC6.C6_QTDENT"
	_oSQL:_sQuery +=   " AND SC6.C6_BLQ NOT IN ('R', 'S')"  // Eliminado residuo / bloqueio manual
	_oSQL:_sQuery +=   " AND SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC5.C5_FILIAL  = SC6.C6_FILIAL"
	_oSQL:_sQuery +=   " AND SC5.C5_NUM     = SC6.C6_NUM"
	_oSQL:_sQuery += " ORDER BY C6_ENTREG, C6_NUM"

	_oSQL:F3Array ("Pedidos de venda do produto '" + _sProduto + "'")
return
//
// --------------------------------------------------------------------------
// Detalha movimentos de entrada considerados na montagem da tela.
static function _DetEntr (_sProduto)
	private _sProd := _sProduto  // Para estar disponivel para a funcao ShowTrb.
	dbselectarea ("_ent")
	set filter to produto = _sProd
	u_showtrb ('_ent')
return
//
// --------------------------------------------------------------------------
// Detalha movimentos de saida considerados na montagem da tela.
static function _DetSaid (_sProduto)
	private _sProd := _sProduto  // Para estar disponivel para a funcao ShowTrb.
	dbselectarea ("_sai")
	set filter to produto = _sProd
	u_showtrb ('_sai')
return
// --------------------------------------------------------------------------
// Verifica disponibilidade de materiais
// Parametro _lSimula : Esse parametro é para diferenciar o processo de simulação de um item e de mais que um item;
// _lSimula == .F. -> Simulação de um registro
// _lSimula == .T. -> Simulação de mais de um registro pela quantidade
//
static function _SimulOP (_sProduto, _nQtd, _aSimula, _lSimula,_sRevis)
	local _nQtSimul  := 0
	local _oSQL      := NIL
	local _aCompon   := {}
	local _nCompon   := 0
	local _aDispComp := {}
	local _nDispComp := 0
	local _x		 := 0
	local _y		 := 0
	local _aRevisao  := {}

	If _lSimula == .T.
		_nQtSimul = _nQtd
	Else
		_nQtSimul = U_Get ("Quantidade a produzir", "N", 12, "@E 999,999,999.99", "", 0, .F., ".T.")
	EndIf
	
	If alltrim(_sRevis) == 'A' // tras apenas revisao atual
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT G5_PRODUTO, G5_OBS, G5_REVISAO, G5_DATAREV "
			_oSQL:_sQuery += " FROM SG5010"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_= ''"
			_oSQL:_sQuery += " AND G5_MSBLQL   = '2' ""
			_oSQL:_sQuery += " AND G5_PRODUTO  = '" + _sProduto + "'" 
			_aRevisao := _oSQL:Qry2Array (.t., .f.)
	Else
		If alltrim(_sRevis) == 'N'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT G5_PRODUTO, G5_OBS, G5_REVISAO, G5_DATAREV "
			_oSQL:_sQuery += " FROM SG5010"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
			_oSQL:_sQuery += " AND G5_PRODUTO = '" + _sProduto + "'" 
			_aRevisao := _oSQL:Qry2Array (.t., .f.)
		else
			If !empty(_sRevis) 
				aadd (_aRevisao, { _sProduto, "", _sRevis })
			EndIf
		endif
	EndIf
	
	_filtroSml = "!sb1->b1_tipo$'MO/'.and.!sb1->b1_grupo$'0400/'.and.sb1->b1_fantasm!='S'"
	
	If len(_aRevisao) >= 1
		
		For _x:=1 to Len(_aRevisao)
			_sRevisao := _aRevisao[_x,3]
			_aArray:= aclone (U_ML_Comp2 (_sProduto, _nQtSimul, _filtroSml, dDataBase, .F., .F., .F., .F., .T., '', .F., '.t.', .T., .F., _sRevisao))
				
			For _y:=1 to len(_aArray)
				aadd (_aCompon, { 	_aArray[_y, 1],;
									_aArray[_y, 2],;
									_aArray[_y, 3],;
									_aArray[_y, 4],;
									_aArray[_y, 5],;
									_aArray[_y, 6],;
									_aArray[_y, 7],;
									_aArray[_y, 8],;
									_aArray[_y, 9],;
									_aArray[_y,10],;
									_aArray[_y,11],;
									_sRevisao     })
			Next
		Next
	Else
		_sRevisao := "   "
		_aArray := aclone (U_ML_Comp2 (_sProduto, _nQtSimul, _filtroSml, dDataBase, .F., .F., .F., .F., .T., '', .F., '.t.', .T., .F., _sRevisao))
		For _y:=1 to len(_aArray)
				aadd (_aCompon, { 	_aArray[_y, 1],;
									_aArray[_y, 2],;
									_aArray[_y, 3],;
									_aArray[_y, 4],;
									_aArray[_y, 5],;
									_aArray[_y, 6],;
									_aArray[_y, 7],;
									_aArray[_y, 8],;
									_aArray[_y, 9],;
									_aArray[_y,10],;
									_aArray[_y,11],;
									_sRevisao     })
		Next
	EndIf
	
	for _nCompon = 1 to len (_aCompon)
		// Busca estoque disponivel no local padrao do produto, mas busca empenhos em qualquer local.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT SUM (CASE WHEN B2_LOCAL = B1_LOCPAD THEN B2_QATU - B2_RESERVA ELSE 0 END) PADRAO, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '01' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_01, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '02' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_02, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '03' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_03, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '07' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_07, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '08' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_08, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '30' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_30, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '31' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_31, "
		_oSQL:_sQuery += " 		 SUM (CASE WHEN B2_LOCAL = '90' THEN B2_QATU - B2_RESERVA ELSE 0 END) AS ALMOX_90, "
		_oSQL:_sQuery +=       " SUM (B2_QEMP) AS EMPENHO,"
		_oSQL:_sQuery +=       " ISNULL ((SELECT SUM (C1_QUANT - C1_QUJE)"
		_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC1") + " SC1 "
		_oSQL:_sQuery +=                 " WHERE SC1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                   " AND SC1.C1_FILIAL  = '" + xfilial ("SC1")        + "'"
		_oSQL:_sQuery +=                   " AND SC1.C1_PRODUTO = SB2.B2_COD"
		_oSQL:_sQuery +=                   " AND SC1.C1_RESIDUO != 'S'"
		_oSQL:_sQuery +=                   " AND SC1.C1_QUANT   > SC1.C1_QUJE), 0) AS SOLIC,"
		_oSQL:_sQuery +=       " ISNULL ((SELECT SUM (C7_QUANT - C7_QUJE)"
		_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC7") + " SC7 "
		_oSQL:_sQuery +=                 " WHERE SC7.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                   " AND SC7.C7_FILIAL  = '" + xfilial ("SC1")        + "'"
		_oSQL:_sQuery +=                   " AND SC7.C7_PRODUTO = SB2.B2_COD"
		_oSQL:_sQuery +=                   " AND SC7.C7_RESIDUO != 'S'"
		_oSQL:_sQuery +=                   " AND SC7.C7_QUANT   > SC7.C7_QUJE), 0) AS PEDCOM"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2, "
		_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB2.B2_FILIAL  = '" + xfilial ("SB2")        + "'"
		_oSQL:_sQuery +=   " AND SB2.B2_COD     = '" + _aCompon [_nCompon, 2] + "'"
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1")        + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD     = SB2.B2_COD"
		_oSQL:_sQuery += " GROUP BY SB2.B2_COD"
	
		_aSB2 = aclone (_oSQL:Qry2Array (.f., .f.))
		
		// Se nao existe registro de estoque deste componente, cria uma array zerada.
		if len (_aSB2) == 0
			_aSB2 = {{0,0,0,0,0,0,0,0,0,0,0,0}}
		endif
		
		aadd (_aDispComp, {_aCompon [_nCompon, 2]	, ;  // Codigo
		                   iif (_nCompon == 1, '', space (_aCompon [_nCompon, 1] * 5) + '+---') + fBuscaCpo ("SB1", 1, xfilial ("SB1") + _aCompon [_nCompon, 2], "B1_DESC"), ;
		                   _aCompon [_nCompon, 12]	, ;  // Revisao atual da estrutura
		                   _aSB2 [1, 1]				, ;  // Padrão
		                   _aSB2 [1, 2]				, ;  // Almox_01
		                   _aSB2 [1, 3]				, ;  // Almox_02
		                   _aSB2 [1, 4]				, ;  // Almox_03
		                   _aSB2 [1, 5]				, ;  // Almox_07		           
		                   _aSB2 [1, 6]				, ;  // Almox_08
		                   _aSB2 [1, 7]				, ;  // Almox_30
		                   _aSB2 [1, 8]				, ;  // Almox_31
		                   _aSB2 [1, 9]				, ;  // Almox_90		                   
		                   _aSB2 [1,10]				, ;  // Empenhos
		                   _aCompon [_nCompon, 4]	, ;  // Qt.acum.
		                   0						, ;  // Para posteriormente calcular o disponivel
		                   _aSB2 [1,11]				, ;  // Saldo em solicitacoes de compras
		                   _aSB2 [1,12]				, ;  // Saldo em pedidos de compras
		                   ''})

	next
	
	for _nDispComp = 1 to len (_aDispComp)
		_aDispComp [_nDispComp, 15] = _aDispComp [_nDispComp, 4] - _aDispComp [_nDispComp, 13] - _aDispComp [_nDispComp, 14]
	next
	
	If _lSimula == .T.
		_aSimula = _aDispComp
	Else
		// Monta colunas para mostrar na tela.
		_aCols = {}
		aadd (_aCols, { 1,  'Componente'			,45,  ''})
		aadd (_aCols, { 2,  'Descricao'				,170, ''})
		aadd (_aCols, { 3,  'Rev.estr'				,30,  ''})
		aadd (_aCols, { 4,  'Alx. padrão produto'	,45, '@E 999,999,999.99'})
		aadd (_aCols, { 5,  'Almox 01'				,45, '@E 999,999,999.99'})
		aadd (_aCols, { 6,  'Almox 02'				,45, '@E 999,999,999.99'})
		aadd (_aCols, { 7,  'Almox 03'				,45, '@E 999,999,999.99'})
		aadd (_aCols, { 8,  'Almox 07'				,45, '@E 999,999,999.99'})
		aadd (_aCols, { 9,  'Almox 08'				,45, '@E 999,999,999.99'})
		aadd (_aCols, {10,  'Almox 30'				,45, '@E 999,999,999.99'})
		aadd (_aCols, {11,  'Almox 31'				,45, '@E 999,999,999.99'})
		aadd (_aCols, {12,  'Almox 90'				,45, '@E 999,999,999.99'})
		aadd (_aCols, {13,  'Empenho(outras OP)'	,55, '@E 999,999,999.99'})
		aadd (_aCols, {14,  'Empenho(simulado)'		,55, '@E 999,999,999.99'})
		aadd (_aCols, {15,  'Disponivel'			,45, '@E 999,999,999.99'})
		aadd (_aCols, {16,  'Solic.compra'			,45, '@E 999,999,999.99'})
		aadd (_aCols, {17,  'Ped.compra'			,45, '@E 999,999,999.99'})
		aadd (_aCols, {18,  'Observacao'			,60, ''})
	
		_aSimula := {}
		u_F3Array (_aDispComp, "Disponibilidade de componentes", _aCols,,, "Disponibilidade dos empenhos", "", .T., 'C', TFont():New ("Courier New", 6, 14))
	EndIf
return _aSimula
//
// --------------------------------------------------------------------------
// Leitura dos dados para alimentar o aCols.
static function _LeDados (_aArqTrb)
	local _lContinua := .T.
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _dDataIni  := ctod ('')
	local _dDataFim  := ctod ('')
	local _sExistsB1 := ""
	local _sAlmoxNao := "66"  		// Almoxarifados a desconsiderar
	local _sAlmoxDuv := "90/91/92"  // Almoxarifados duvidosos
	local _sProdIni  := mv_par01
	local _sProdFim  := mv_par02
	local _sListProd := iif (_sTipoPlan == 'A', alltrim (mv_par03), '')
	local _lForaLinh := iif (_sTipoPlan == 'A', (mv_par04 == 1), (mv_par03 == 1))
	local _lForaMRP  := iif (_sTipoPlan == 'A', (mv_par05 == 1), (mv_par04 == 1))
	local _sEmbIni   := iif (_sTipoPlan == 'A', mv_par07, '')
	local _sEmbFim   := iif (_sTipoPlan == 'A', mv_par08, 'zz')
	local _sTipoIni  := iif (_sTipoPlan == 'M', mv_par06, '')
	local _sTipoFim  := iif (_sTipoPlan == 'M', mv_par07, 'zz')
	local _sLinhaIni := iif (_sTipoPlan == 'A', mv_par09, '')
	local _sLinhaFim := iif (_sTipoPlan == 'A', mv_par10, 'zz')
	local _sRecurIni := iif (_sTipoPlan == 'A', mv_par11, '')
	local _sRecurFim := iif (_sTipoPlan == 'A', mv_par12, 'zzzzzz')
	local _sPerIni   := ""
	local _sPerFim   := ""
	local _nPeriodo  := 0
	local _sPeriodo  := ""
	local _nVlTotEnt := 0
	local _nVlTotSai := 0
	local _aLinVazia := {}
	local _nAno      := 0
	local _nMes      := 0
	local _aAno      := {}

	procregua (10)

	// Valida parametros.
	if _lContinua
		if _sTipoPlan == 'A'
			if ! empty (_sListProd) .and. ! (empty (_sProdIni) .and. upper (left (_sProdFim, 1)) == 'Z')
				u_help ("Parametros conflitantes." + chr (10) + chr (13) + "Informe produto 'de branco a Z' ou lista de produtos, mas nao ambos.")
				_lContinua = .F. 
			endif
		endif
	endif

	// Monta lista de periodos (meses) para auxiliar na geracao de medias.
	if _lContinua
		_aPeriodos = {}
		_oDUtil := ClsDUtil():New ()
		_sPeriodo = _oDUtil:SubtrMes (left (dtos (date ()), 6), 1)  // Mes atual fica de fora para pegar 'mes cheio'
		aadd (_aPeriodos, _sPeriodo)
		for _nPeriodo = 1 to 11
			_sPeriodo = _oDUtil:SubtrMes (_sPeriodo, 1)
			aadd (_aPeriodos, {})
			ains (_aPeriodos, 1)
			_aPeriodos [1] = _sPeriodo
		next
		_dDataIni = stod (_aPeriodos [1] + '01')
		_dDataFim = lastday (stod (_aPeriodos [len (_aPeriodos)] + '01'))	
	
		// Monta array com periodos para analises de sazonalidade (anos completos independente da data atual)
		_aSazo = {}
		for _nAno = year (date ()) - 2 to year (date ())
			_aAno = {}
			for _nMes = 1 to 12
				aadd (_aAno, strzero (_nAno, 4) + strzero (_nMes, 2))
			next
			aadd (_aSazo, aclone (_aAno))
		next
	endif

	// Monta arquivos de trabalho para facilitar a preparacao dos dados.
	if _lContinua
		incproc ("Montando arquivos temporarios...")
		//
		_aCampos = {}
		aadd (_aCampos, {"Filial",     "C", 2,  0})
		aadd (_aCampos, {"Produto",    "C", 15, 0})
		aadd (_aCampos, {"Ano",        "C", 4,  0})
		aadd (_aCampos, {"Mes",        "C", 2,  0})
		aadd (_aCampos, {"Origem",     "C", 10, 0})
		aadd (_aCampos, {"Quant",      "N", 18, 2})
		aadd (_aCampos, {"Valor",      "N", 18, 2})
		U_ArqTrb ("Cria", "_ent", _aCampos, {"Filial + Produto + Ano + Mes + Origem"}, @_aArqTrb)
		U_ArqTrb ("Cria", "_sai", _aCampos, {"Filial + Produto + Ano + Mes + Origem"}, @_aArqTrb)
		_ent -> (dbsetorder (1))
		_sai -> (dbsetorder (1))
		
		_aCampos = {}
		aadd (_aCampos, {"Filial",     "C", 2,  0})
		aadd (_aCampos, {"Linha",      "C", 25, 0})
		aadd (_aCampos, {"Ano",        "C", 4,  0})
		aadd (_aCampos, {"Mes",        "C", 2,  0})
		aadd (_aCampos, {"Quant",      "N", 18, 2})
		U_ArqTrb ("Cria", "_saiLin", _aCampos, {"Filial + Linha + Ano + Mes"}, @_aArqTrb)
		_saiLin -> (dbsetorder (1))
		
		_aCampos = {}
		aadd (_aCampos, {"Embalagem",  "C", 25, 0})
		aadd (_aCampos, {"Linha",      "C", 25, 0})
		aadd (_aCampos, {"Qt_por_Emb", "N", 2,  0})
		aadd (_aCampos, {"Litragem",   "N", 6,  2})
		aadd (_aCampos, {"Tipo",       "C", 2,  0})
		aadd (_aCampos, {"Cor",        "C", 1,  0})
		aadd (_aCampos, {"VarUva",     "C", 5,  0})
		aadd (_aCampos, {"Marca",      "C", 10, 0})
		aadd (_aCampos, {"LinEnvase",  "C", 20, 0})
		aadd (_aCampos, {"Produto",    "C", 15, 0})
		aadd (_aCampos, {"Descricao",  "C", 60, 0})
		aadd (_aCampos, {"Un_Medida",  "C", 2,  0})
		aadd (_aCampos, {"Estoque",    "N", 18, 2})
		aadd (_aCampos, {"EstoqueDuv", "N", 18, 2})
		aadd (_aCampos, {"QNPT",       "N", 18, 2})
		aadd (_aCampos, {"QTNP",       "N", 18, 2})
		aadd (_aCampos, {"qt_entrou",  "N", 18, 2})
		aadd (_aCampos, {"qt_saiu",    "N", 18, 2})
		aadd (_aCampos, {"MEDSAI1A",   "N", 18, 2})
		aadd (_aCampos, {"MEDSAI6M",   "N", 18, 2})
		aadd (_aCampos, {"MEDSAI3M",   "N", 18, 2})
		aadd (_aCampos, {"MEDSAI1M",   "N", 18, 2})
		aadd (_aCampos, {"medsai1d",   "N", 18, 2})
		aadd (_aCampos, {"medsaiGer",  "N", 18, 2})
		aadd (_aCampos, {"Cobert_dia", "N", 18, 2})
		aadd (_aCampos, {"Cobert_sem", "N", 18, 2})
		aadd (_aCampos, {"Preco_unit", "N", 18, 2})
		aadd (_aCampos, {"CurEstat",   "C", 1,  0})
		aadd (_aCampos, {"valor_estq", "N", 18, 2})
		aadd (_aCampos, {"CurInvent",  "C", 1,  0})
		aadd (_aCampos, {"valor_es",   "N", 18, 2})
		aadd (_aCampos, {"CurEntSai",  "C", 1,  0})
		aadd (_aCampos, {"valor_entr", "N", 18, 2})
		aadd (_aCampos, {"CurEntr",    "C", 1,  0})
		aadd (_aCampos, {"valor_said", "N", 18, 2})
		aadd (_aCampos, {"CurSaid",    "C", 1,  0})
		aadd (_aCampos, {"Lote_Comp",  "N", 18, 2})
		aadd (_aCampos, {"Lote_Vend",  "N", 18, 2})
		aadd (_aCampos, {"estq_min",   "N", 18, 2})
		aadd (_aCampos, {"estq_max",   "N", 18, 2})
		aadd (_aCampos, {"Lead_Time",  "N", 6,  0})
		aadd (_aCampos, {"LtEconProd", "N", 18, 2})
		aadd (_aCampos, {"LtRealProd", "N", 18, 2})
		aadd (_aCampos, {"EmpenhoPV",  "N", 18, 2})
		aadd (_aCampos, {"EmpenhoOP",  "N", 18, 2})
		aadd (_aCampos, {"A_receber",  "N", 18, 2})
		aadd (_aCampos, {"estq_proj",  "N", 18, 2})
		aadd (_aCampos, {"observ",     "C", 80, 0})
		aadd (_aCampos, {"capproddia", "N", 18, 2})
		U_ArqTrb ("Cria", "_trb", _aCampos, {"Produto", 'preco_unit', 'valor_estq', 'valor_es', 'valor_entr', 'valor_said'}, @_aArqTrb)

		_trb -> (dbsetorder (1))

		// Monta clausula 'exists' para tabela SB1 a ser usada em todas as filtragens.
		_sExistsB1 := "SELECT B1_COD"
		_sExistsB1 +=  " FROM " + RetSQLName ("SB1") + " EXISTS_SB1 "
		_sExistsB1 += " WHERE EXISTS_SB1.D_E_L_E_T_ = ''"
		_sExistsB1 +=   " AND EXISTS_SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_sExistsB1 +=   " AND EXISTS_SB1.B1_TIPO    NOT IN ('AI', 'AN', 'BN', 'GF', 'GG', 'MC', 'MO', 'SL')"  // Tipos que nao interessam
		_sExistsB1 +=   " AND EXISTS_SB1.B1_GRUPO   != '0400'"  // Uvas
		_sExistsB1 +=   " AND EXISTS_SB1.B1_COD     BETWEEN '" + _sProdIni  + "' AND '" + _sProdFim  + "'"
		if ! empty (_sListProd)
			_sExistsB1 +=   " AND EXISTS_SB1.B1_COD IN " + FormatIn (_sListProd, '/')
		endif
		if ! _lForaMRP
			_sExistsB1 +=   " AND EXISTS_SB1.B1_MRP     != 'N'"
		endif
		if _sTipoPlan == 'M'
			_sExistsB1 +=   " AND EXISTS_SB1.B1_TIPO NOT IN ('PA', 'PI')"
			_sExistsB1 +=   " AND EXISTS_SB1.B1_TIPO BETWEEN '" + _sTipoIni + "' AND '" + _sTipoFim + "'"
		elseif _sTipoPlan == 'A'
			_sExistsB1 +=   " AND EXISTS_SB1.B1_CODLIN  BETWEEN '" + _sLinhaIni + "' AND '" + _sLinhaFim + "'"
			_sExistsB1 +=   " AND EXISTS_SB1.B1_GRPEMB  BETWEEN '" + _sEmbIni   + "' AND '" + _sEmbFim   + "'"
			_sExistsB1 +=   " AND EXISTS_SB1.B1_VALINEN BETWEEN '" + _sRecurIni + "' AND '" + _sRecurFim + "'"
			_sExistsB1 +=   " AND EXISTS_SB1.B1_TIPO    IN ('PA', 'PI')"
			if ! _lForaLinh
				_sExistsB1 +=   " AND EXISTS_SB1.B1_VAFORAL != 'S'"
			endif
		endif
	endif

	// Gera arquivos de trabalho para uso posterior.
	if _lContinua
		incproc ('Leitura de entradas via NF')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT 'NF' AS ORIGEM, D1_FILIAL AS FILIAL, D1_COD AS PRODUTO, SUBSTRING (SD1.D1_DTDIGIT, 1, 4) AS ANO, SUBSTRING (SD1.D1_DTDIGIT, 5, 2) AS MES, SUM (D1_QUANT) AS QUANT, SUM (D1_CUSTO) AS VALOR"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1") + " SD1, "
		_oSQL:_sQuery +=             RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DTDIGIT BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_TIPO    NOT IN ('B', 'D')"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE NOT IN (SELECT A2_COD"
		_oSQL:_sQuery +=                                " FROM " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=                               " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                                 " AND SA2.A2_CGC LIKE '" + left (sm0 -> m0_cgc, 8) + "%')"
		_oSQL:_sQuery +=   " AND SD1.D1_COD IN (" + _sExistsB1 + ")"
		_oSQL:_sQuery +=   " AND SF4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SF4.F4_CODIGO  = SD1.D1_TES"
		_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery +=   " AND SF4.F4_PODER3  NOT IN ('R', 'D')"
		_oSQL:_sQuery += " GROUP BY D1_FILIAL, D1_COD, SUBSTRING (SD1.D1_DTDIGIT, 1, 4), SUBSTRING (SD1.D1_DTDIGIT, 5, 2)"

		_sAliasQ = _oSQL:Qry2Trb (.f.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			reclock ("_ent", ! _ent -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> produto + (_sAliasQ) -> ano + (_sAliasQ) -> mes + (_sAliasQ) -> origem, .F.)))
			_ent -> filial  = (_sAliasQ) -> filial
			_ent -> produto = (_sAliasQ) -> produto
			_ent -> ano     = (_sAliasQ) -> ano
			_ent -> mes     = (_sAliasQ) -> mes
			_ent -> origem  = (_sAliasQ) -> origem
			_ent -> quant  += (_sAliasQ) -> quant
			_ent -> valor  += (_sAliasQ) -> valor
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	
		incproc ('Leitura de entradas via mov.internos')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT D3_CF AS ORIGEM, D3_FILIAL AS FILIAL, D3_COD AS PRODUTO, SUBSTRING (SD3.D3_EMISSAO, 1, 4) AS ANO, SUBSTRING (SD3.D3_EMISSAO, 5, 2) AS MES, SUM (D3_QUANT) AS QUANT, SUM (D3_CUSTO1) AS VALOR"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_CF      LIKE 'PR%'"
		_oSQL:_sQuery +=   " AND SD3.D3_COD IN (" + _sExistsB1 + ")"
		_oSQL:_sQuery += " GROUP BY D3_FILIAL, D3_COD, SUBSTRING (SD3.D3_EMISSAO, 1, 4), SUBSTRING (SD3.D3_EMISSAO, 5, 2), D3_CF"

		_sAliasQ = _oSQL:Qry2Trb (.f.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			reclock ("_ent", ! _ent -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> produto + (_sAliasQ) -> ano + (_sAliasQ) -> mes + (_sAliasQ) -> origem, .F.)))
			_ent -> filial  = (_sAliasQ) -> filial
			_ent -> produto = (_sAliasQ) -> produto
			_ent -> ano     = (_sAliasQ) -> ano
			_ent -> mes     = (_sAliasQ) -> mes
			_ent -> origem  = (_sAliasQ) -> origem
			_ent -> quant  += (_sAliasQ) -> quant
			_ent -> valor  += (_sAliasQ) -> valor
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())

		incproc ('Leitura de saidas via NF')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT 'NF' AS ORIGEM, D2_FILIAL AS FILIAL, D2_COD AS PRODUTO, "
		_oSQL:_sQuery +=       " SUBSTRING (SD2.D2_EMISSAO, 1, 4) AS ANO, SUBSTRING (SD2.D2_EMISSAO, 5, 2) AS MES,"
		_oSQL:_sQuery +=       " SUM (D2_QUANT) AS QUANT, SUM (D2_CUSTO1) AS VALOR"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD2") + " SD2, "
		_oSQL:_sQuery +=             RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
		_oSQL:_sQuery +=   " AND SD2.D2_EMISSAO BETWEEN '" + strzero (year (_dDataIni) - 1, 4) + "0101' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND SD2.D2_TIPO    NOT IN ('B', 'D')"
		_oSQL:_sQuery +=   " AND SD2.D2_COD IN (" + _sExistsB1 + ")"
		_oSQL:_sQuery +=   " AND SF4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SF4.F4_CODIGO  = SD2.D2_TES"
		_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery +=   " AND SF4.F4_PODER3  NOT IN ('R', 'D')"
		_oSQL:_sQuery += " GROUP BY D2_FILIAL, D2_COD, SUBSTRING (SD2.D2_EMISSAO, 1, 4), SUBSTRING (SD2.D2_EMISSAO, 5, 2)"

		_sAliasQ = _oSQL:Qry2Trb (.f.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			reclock ("_sai", ! _sai -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> produto + (_sAliasQ) -> ano + (_sAliasQ) -> mes + (_sAliasQ) -> origem, .F.)))
			_sai -> filial  = (_sAliasQ) -> filial
			_sai -> produto = (_sAliasQ) -> produto
			_sai -> ano     = (_sAliasQ) -> ano
			_sai -> mes     = (_sAliasQ) -> mes
			_sai -> origem  = (_sAliasQ) -> origem
			_sai -> quant  += (_sAliasQ) -> quant
			_sai -> valor  += (_sAliasQ) -> valor
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	
		incproc ('Leitura de saidas via mov.internos')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT D3_CF AS ORIGEM, D3_FILIAL AS FILIAL, D3_COD AS PRODUTO, SUBSTRING (SD3.D3_EMISSAO, 1, 4) AS ANO, SUBSTRING (SD3.D3_EMISSAO, 5, 2) AS MES, SUM (D3_QUANT) AS QUANT, SUM (D3_CUSTO1) AS VALOR"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND SD3.D3_CF      LIKE 'RE%'"
		_oSQL:_sQuery +=   " AND SD3.D3_CF      != 'RE4'"  // Transferencias
		_oSQL:_sQuery +=   " AND SD3.D3_COD IN (" + _sExistsB1 + ")"
		_oSQL:_sQuery += " GROUP BY D3_FILIAL, D3_COD, SUBSTRING (SD3.D3_EMISSAO, 1, 4), SUBSTRING (SD3.D3_EMISSAO, 5, 2), D3_CF"

		_sAliasQ = _oSQL:Qry2Trb (.f.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			reclock ("_sai", ! _sai -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> produto + (_sAliasQ) -> ano + (_sAliasQ) -> mes + (_sAliasQ) -> origem, .F.)))
			_sai -> filial  = (_sAliasQ) -> filial
			_sai -> produto = (_sAliasQ) -> produto
			_sai -> ano     = (_sAliasQ) -> ano
			_sai -> mes     = (_sAliasQ) -> mes
			_sai -> origem  = (_sAliasQ) -> origem
			_sai -> quant  += (_sAliasQ) -> quant
			_sai -> valor  += (_sAliasQ) -> valor
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())

		// Se vai ter grafico de sazonalidade, precisa gerar acumulados por linha de produto.
		if _lGrafico
			incproc ('Leitura de saidas via NF por linha de produto')
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT D2_FILIAL AS FILIAL, ZX5_39.ZX5_39DESC AS LINHA,"
			_oSQL:_sQuery +=       " SUBSTRING (SD2.D2_EMISSAO, 1, 4) AS ANO, SUBSTRING (SD2.D2_EMISSAO, 5, 2) AS MES,"
			_oSQL:_sQuery +=       " SUM (D2_QUANT) AS QUANT"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD2") + " SD2, "
			_oSQL:_sQuery +=             RetSQLName ("SF4") + " SF4, "
			_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1, "
			_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_39 "
			_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
			_oSQL:_sQuery +=   " AND SD2.D2_EMISSAO BETWEEN '" + _aSazo [1, 1] + "01' AND '" + _aSazo [len (_aSazo), 12] + "31'"
			_oSQL:_sQuery +=   " AND SD2.D2_TIPO    NOT IN ('B', 'D')"
			_oSQL:_sQuery +=   " AND SD2.D2_COD IN (" + _sExistsB1 + ")"
			_oSQL:_sQuery +=   " AND SF4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SF4.F4_CODIGO  = SD2.D2_TES"
			_oSQL:_sQuery +=   " AND SF4.F4_ESTOQUE = 'S'"
			_oSQL:_sQuery +=   " AND SF4.F4_PODER3  NOT IN ('R', 'D')"
			_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=   " AND SB1.B1_COD     = SD2.D2_COD"
			_oSQL:_sQuery +=   " AND ZX5_39.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_TABELA = '39'"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_39COD  = SB1.B1_CODLIN"
			_oSQL:_sQuery += " GROUP BY D2_FILIAL, ZX5_39.ZX5_39DESC, SUBSTRING (SD2.D2_EMISSAO, 1, 4), SUBSTRING (SD2.D2_EMISSAO, 5, 2)"

			_sAliasQ = _oSQL:Qry2Trb (.f.)
			(_sAliasQ) -> (dbgotop ())
			do while ! (_sAliasQ) -> (eof ())
				reclock ("_saiLin", ! _saiLin -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> linha + (_sAliasQ) -> ano + (_sAliasQ) -> mes, .F.)))
				_saiLin -> filial  = (_sAliasQ) -> filial
				_saiLin -> Linha   = (_sAliasQ) -> linha
				_saiLin -> ano     = (_sAliasQ) -> ano
				_saiLin -> mes     = (_sAliasQ) -> mes
				_saiLin -> quant  += (_sAliasQ) -> quant
				msunlock ()
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())

			incproc ('Leitura de saidas via NF por linha de produto')
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT D3_FILIAL AS FILIAL, ZX5_39.ZX5_39DESC AS LINHA,"
			_oSQL:_sQuery +=       " SUBSTRING (SD3.D3_EMISSAO, 1, 4) AS ANO, SUBSTRING (SD3.D3_EMISSAO, 5, 2) AS MES,"
			_oSQL:_sQuery +=       " SUM (D3_QUANT) AS QUANT"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3, "
			_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1, "
			_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_39 "
			_oSQL:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SD3.D3_FILIAL  = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=   " AND SD3.D3_EMISSAO BETWEEN '" + _aSazo [1, 1] + "01' AND '" + _aSazo [len (_aSazo), 12] + "31'"
			_oSQL:_sQuery +=   " AND SD3.D3_CF      LIKE 'RE%'"
			_oSQL:_sQuery +=   " AND SD3.D3_CF      != 'RE4'"  // Transferencias
			_oSQL:_sQuery +=   " AND SD3.D3_COD IN (" + _sExistsB1 + ")"
			_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=   " AND SB1.B1_COD     = SD3.D3_COD"
			_oSQL:_sQuery +=   " AND ZX5_39.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_TABELA = '39'"
			_oSQL:_sQuery +=   " AND ZX5_39.ZX5_39COD  = SB1.B1_CODLIN"
			_oSQL:_sQuery += " GROUP BY D3_FILIAL, ZX5_39.ZX5_39DESC, SUBSTRING (SD3.D3_EMISSAO, 1, 4), SUBSTRING (SD3.D3_EMISSAO, 5, 2)"

			_sAliasQ = _oSQL:Qry2Trb (.f.)
			(_sAliasQ) -> (dbgotop ())
			do while ! (_sAliasQ) -> (eof ())
				reclock ("_saiLin", ! _saiLin -> (dbseek ((_sAliasQ) -> filial + (_sAliasQ) -> linha + (_sAliasQ) -> ano + (_sAliasQ) -> mes, .F.)))
				_saiLin -> filial  = (_sAliasQ) -> filial
				_saiLin -> Linha   = (_sAliasQ) -> linha
				_saiLin -> ano     = (_sAliasQ) -> ano
				_saiLin -> mes     = (_sAliasQ) -> mes
				_saiLin -> quant  += (_sAliasQ) -> quant
				msunlock ()
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())

		endif

		// Leitura de produtos e demais dados que for possivel agrupar neste momento.
		incproc ('Leitura de estoque e parametros')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ISNULL (ZX5_50.ZX5_50DESC, '') AS EMBALAGEM, "
		_oSQL:_sQuery +=       " B1_QTDEMB, B1_LITROS,"
		_oSQL:_sQuery +=       " ISNULL (ZX5_40.ZX5_40DESC, '') AS MARCA,"
		_oSQL:_sQuery +=       " ISNULL (ZX5_39.ZX5_39DESC, '') AS LINHA,"
		_oSQL:_sQuery +=       " B1_TIPO, B1_COD, B1_DESC, B1_UM, B1_LM, B1_QE, B1_EMIN, B1_EMAX, B1_VACOR,"
		_oSQL:_sQuery +=       " CASE B1_VARUVA WHEN 'C' THEN 'COMUM' WHEN 'F' THEN 'VINIF' ELSE '' END AS VARUVA,"
		_oSQL:_sQuery +=       " B1_PE * CASE B1_TIPE WHEN 'H' THEN 0.0416"  // 1/24 horas
		_oSQL:_sQuery +=                            " WHEN 'D' THEN 1"
		_oSQL:_sQuery +=                            " WHEN 'S' THEN 7"
		_oSQL:_sQuery +=                            " WHEN 'M' THEN 30"
		_oSQL:_sQuery +=                            " WHEN 'A' THEN 365"
		_oSQL:_sQuery +=                            " ELSE 0 END AS LEAD_TIME,"
		_oSQL:_sQuery +=       " ISNULL (SUM (CASE WHEN SB2.B2_LOCAL NOT IN " + FormatIn (_sAlmoxDuv, '/') + " THEN SB2.B2_QATU ELSE 0 END), 0) AS ESTQ,"
		_oSQL:_sQuery +=       " ISNULL (SUM (CASE WHEN SB2.B2_LOCAL     IN " + FormatIn (_sAlmoxDuv, '/') + " THEN SB2.B2_QATU ELSE 0 END), 0) AS ESTQDUV,"
		_oSQL:_sQuery +=       " ISNULL (SUM (B2_QTNP), 0) AS QTNP,"
		_oSQL:_sQuery +=       " ISNULL (SUM (B2_QNPT), 0) AS QNPT,"
		_oSQL:_sQuery +=       " ISNULL ((SELECT SUM (C6_QTDVEN - C6_QTDENT)"
		_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SC6") + " SC6 "
		_oSQL:_sQuery +=                 " WHERE SC6.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                   " AND SC6.C6_FILIAL  = '" + xfilial ("SC6") + "'"
		_oSQL:_sQuery +=                   " AND SC6.C6_PRODUTO = SB1.B1_COD"
		_oSQL:_sQuery +=                   " AND SC6.C6_QTDVEN  > SC6.C6_QTDENT"
		_oSQL:_sQuery +=                   " AND SC6.C6_BLQ    != 'R'), 0) as EMPENHOPV,"  // Eliminado residuo
		_oSQL:_sQuery +=       " ISNULL (SUM (B2_QEMP), 0) AS EMPENHOOP,"
		_oSQL:_sQuery +=       " ISNULL (SUM (B2_SALPEDI), 0) AS A_RECEBER,"
		_oSQL:_sQuery +=       " SB1.B1_VAFORAL, SB1.B1_MRP, B1_VACAPDI, SH1.H1_DESCRI"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_39 "
		_oSQL:_sQuery +=        " ON (ZX5_39.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND ZX5_39.ZX5_FILIAL  = '" + xfilial ("SX5") + "'"
		_oSQL:_sQuery +=        " AND ZX5_39.ZX5_TABELA  = '39'"
		_oSQL:_sQuery +=        " AND ZX5_39.ZX5_39COD   = SB1.B1_CODLIN)"
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_50 "
		_oSQL:_sQuery +=        " ON (ZX5_50.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND ZX5_50.ZX5_FILIAL  = '" + xfilial ("SX5") + "'"
		_oSQL:_sQuery +=        " AND ZX5_50.ZX5_TABELA  = '50'"
		_oSQL:_sQuery +=        " AND ZX5_50.ZX5_50COD   = SB1.B1_GRPEMB)"
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("ZX5") + " ZX5_40 "
		_oSQL:_sQuery +=        " ON (ZX5_40.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND ZX5_40.ZX5_FILIAL  = '" + xfilial ("SX5") + "'"
		_oSQL:_sQuery +=        " AND ZX5_40.ZX5_TABELA  = '40'"
		_oSQL:_sQuery +=        " AND ZX5_40.ZX5_40COD   = SB1.B1_VAMARCM)"
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SB2") + " SB2 "
		_oSQL:_sQuery +=        " ON (SB2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SB2.B2_FILIAL  = '" + xfilial ("SB2") + "'"
		_oSQL:_sQuery +=        " AND SB2.B2_COD     = SB1.B1_COD"
		_oSQL:_sQuery +=        " AND SB2.B2_LOCAL   NOT IN " + FormatIn (_sAlmoxNao, '/') + ')'
		_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SH1") + " SH1 "
		_oSQL:_sQuery +=        " ON (SH1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=        " AND SH1.H1_FILIAL  = '" + xfilial ("SH1") + "'"
		_oSQL:_sQuery +=        " AND SH1.H1_CODIGO  = SB1.B1_VALINEN)"
		_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD     IN (" + _sExistsB1 + ")"
		_oSQL:_sQuery += " GROUP BY ZX5_50.ZX5_50DESC, ZX5_39.ZX5_39DESC, B1_TIPO, B1_COD, B1_DESC, B1_UM, B1_LM, B1_QE, B1_EMIN, B1_EMAX, B1_PE, B1_TIPE, B1_VAFORAL, B1_MRP, B1_VACAPDI, B1_VACOR, H1_DESCRI, B1_QTDEMB, B1_LITROS, ZX5_40.ZX5_40DESC, B1_VARUVA"

		_sAliasQ = _oSQL:Qry2Trb (.f.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			reclock ("_trb", .T.)
			_trb -> embalagem  = (_sAliasQ) -> embalagem
			_trb -> Qt_por_Emb = (_sAliasQ) -> b1_qtdemb
			_trb -> Litragem   = (_sAliasQ) -> b1_litros
			_trb -> linha      = (_sAliasQ) -> linha
			_trb -> marca      = (_sAliasQ) -> marca
			_trb -> linenvase  = (_sAliasQ) -> h1_descri
			_trb -> cor        = (_sAliasQ) -> b1_vacor
			_trb -> varuva     = (_sAliasQ) -> varuva
			_trb -> tipo       = (_sAliasQ) -> b1_tipo
			_trb -> produto    = (_sAliasQ) -> b1_cod
			_trb -> descricao  = (_sAliasQ) -> b1_desc
			_trb -> un_medida  = (_sAliasQ) -> b1_um
			_trb -> estoque    = (_sAliasQ) -> estq
			_trb -> estoqueDuv = (_sAliasQ) -> estqDuv
			_trb -> qtnp       = (_sAliasQ) -> qtnp
			_trb -> qnpt       = (_sAliasQ) -> qnpt
			_trb -> lote_comp  = (_sAliasQ) -> b1_qe
			_trb -> lote_vend  = (_sAliasQ) -> b1_lm
			_trb -> estq_min   = (_sAliasQ) -> b1_emin
			_trb -> estq_max   = (_sAliasQ) -> b1_emax
			_trb -> Lead_Time  = (_sAliasQ) -> lead_time
			_trb -> EmpenhoPV  = (_sAliasQ) -> EmpenhoPV
			_trb -> EmpenhoOP  = (_sAliasQ) -> EmpenhoOP
			_trb -> A_Receber  = (_sAliasQ) -> A_Receber
			_trb -> CapProdDia = (_sAliasQ) -> b1_vacapdi
			if (_sAliasQ) -> b1_vaforal == 'S'
				_trb -> observ = alltrim (_trb -> observ) + 'Fora de linha;'
			endif
			if (_sAliasQ) -> b1_mrp == 'N'
				_trb -> observ = alltrim (_trb -> observ) + 'Fora do MRP;'
			endif
			msunlock ()
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif
	
	// Repassa o arquivo de trabalho preenchendo os dados de quantidades.
	if _lContinua
		incproc ('Calculando valores')

		_sPerIni = _aPeriodos [1]
		_sPerFim = _aPeriodos [len (_aPeriodos)]	
		_trb -> (dbgotop ())
		do while ! _trb -> (eof ())
			_nVlTotEnt = 0
			_ent -> (dbseek (cFilAnt + _trb -> produto + _sPerIni, .T.))
			do while ! _ent -> (eof ()) .and. _ent -> filial == cFilAnt .and. _ent -> produto == _trb -> produto .and. _ent -> ano + _ent -> mes <= _sPerFim
				_trb -> qt_entrou += _ent -> quant
				_nVlTotEnt += _ent -> valor
				_ent -> (dbskip ())
			enddo

			_nVlTotSai = 0
			_sai -> (dbseek (cFilAnt + _trb -> produto + _sPerIni, .T.))
			do while ! _sai -> (eof ()) .and. _sai -> filial == cFilAnt .and. _sai -> produto == _trb -> produto .and. _sai -> ano + _sai -> mes <= _sPerFim
				_trb -> qt_saiu += _sai -> quant
				_nVlTotSai += _sai -> valor
				
				// Acumula quantidades de saidas para posterior calculo de medias por periodo.
				if _sai -> ano + _sai -> mes == _aPeriodos [len (_aPeriodos)]
					_trb -> medsai1M += _sai -> quant
				endif
				if _sai -> ano + _sai -> mes >= _aPeriodos [len (_aPeriodos) - 2]
					_trb -> medsai3M += _sai -> quant
				endif
				if _sai -> ano + _sai -> mes >= _aPeriodos [len (_aPeriodos) - 5]
					_trb -> medsai6M += _sai -> quant
				endif
				if _sai -> ano + _sai -> mes >= _aPeriodos [len (_aPeriodos) - 11]
					_trb -> medsai1A += _sai -> quant
				endif

				_sai -> (dbskip ())
			enddo

			// Medias de saidas nos ultimos 3, 6, 12, 1 mes e media diaria do ultimo mes.
			_trb -> medsai3M = _trb -> medsai3M / 3  
			_trb -> medsai6M = _trb -> medsai6M / 6
			_trb -> medsai1A = _trb -> medsai1A / 12
			_trb -> medsai1D = _trb -> medsai1M / 30

			_trb -> medsaiger = (_trb -> medsai3M + _trb -> medsai6M + _trb -> medsai1A + _trb -> medsai1M) / 4

			_trb -> cobert_dia = _trb -> estoque / _trb -> medsai1d
			_trb -> cobert_sem = round (_trb -> cobert_dia / 7, 0)

			if _trb -> tipo $ "PA/PI"
				_trb -> preco_unit = _nVlTotSai / _trb -> qt_saiu
			else
				_trb -> preco_unit = _nVlTotEnt / _trb -> qt_entrou
			endif

			_trb -> estq_proj = _trb -> estoque - _trb -> empenhoOP - _trb -> empenhoPV //+ _trb -> a_receber

			// Campos para geracao de curvas.
			_trb -> Valor_estq = _trb -> estoque * _trb -> preco_unit
			_trb -> Valor_es   = ((_trb -> qt_entrou * _trb -> preco_unit) + (_trb -> qt_saiu * _trb -> preco_unit)) / 2 
			_trb -> Valor_entr = _trb -> qt_entrou * _trb -> preco_unit 
			_trb -> Valor_said = _trb -> qt_saiu * _trb -> preco_unit 

			_trb -> (dbskip ())
		enddo
	endif

	// Classifica os itens como A/B/C
	if _lContinua
		_Curva ('preco_unit', 'CurEstat', 2)
		_Curva ('valor_estq', 'CurInvent', 3)
		_Curva ('valor_es',   'CurEntSai', 4)
		_Curva ('valor_entr', 'CurEntr', 5)
		_Curva ('valor_said', 'CurSaid', 6)
	endif

	if _lContinua
		_trb -> (dbsetorder (1))

		aHeader = {}
		aCols = {}
		if _sTipoPlan == "A"  // Produto acabado

			//              Titulo                 Campo         Masc                  Tam Dec Valid Usado Tipo F3     Context CBox Relacao Alteravel
			aadd (aHeader, {"Embalagem",           "EMBALAGEM",  "",                   25, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Qt por emb",          "QT_POR_EMB", "",                   3,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Litros emb",          "LITRAGEM",   "",                   6,  2,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Linha produto",       "LINHAPROD",  "",                   25, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Cor",                 "COR_PROD",   "",                   1,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Comum/vinif",         "VARUVA",     "",                   5,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Marca",               "MARCA",      "",                   10, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Linha envase",        "LINENVASE",  "",                   20, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Produto",             "PRODUTO",    "",                   15, 0,  "",   "",   "C", "SB1", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Descricao",           "DESCRICAO",  "",                   60, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Un.medida",           "UNMEDIDA",   "",                   2,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Saldo estoque",       "ESTQ",       "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Empenho PV",          "EMPENHOPV",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq duvidoso",       "ESTQDUV",    "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq.em 3os",         "QNPT",       "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq.de 3os",         "QTNP",       "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Qt.total saidas",     "QTSAIDA",    "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.mens.ult.ano",   "MEDSAI1A",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.mens.ult.sem",   "MEDSAI6M",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.mens.ult.trim",  "MEDSAI3M",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.mens.ult.mes",   "MEDSAI1M",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.diaria ult.mes", "MEDSAI1D",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Said.media geral",    "MEDSAIGER",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Cobertura dias",      "COBERTDIA",  "@E 99999",           5,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Cobertura semanas",   "COBERTSEM",  "@E 99999",           5,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Preco unit",          "PRECOUNIT",  "@E 999,999.9999",   12,  4,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Lote econ producao",  "LTECONPROD", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Lote real producao",  "LTECONPROD", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Capacid.diaria prod", "CAPPRODDIA", "@E 999,999",         6,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Entradas previstas",  "ENTRPREV",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq projetado",      "ESTQPROJET", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Observacoes",         "OBSERV",     "",                  80,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva estatica",      "CURESTAT",   "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.invent",    "CURINVENT",  "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.ent+sai",   "CURENTSAI",  "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.entrada",   "CURENTR",    "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.saida",     "CURSAID",    "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			_aLinVazia = aclone (U_LinVazia (aHeader))
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				aadd (aCols, aclone (_aLinVazia))
				N = len (aCols)
				GDFieldPut ("EMBALAGEM",  _trb -> embalagem)
				GDFieldPut ("QT_POR_EMB", _trb -> qt_por_emb)
				GDFieldPut ("LITRAGEM",   _trb -> litragem)
				GDFieldPut ("LINHAPROD",  _trb -> linha)
				GDFieldPut ("MARCA",      _trb -> marca)
				GDFieldPut ("VARUVA",     _trb -> varuva)
				GDFieldPut ("LINENVASE",  _trb -> linenvase)
				GDFieldPut ("COR_PROD",   _trb -> cor)
				GDFieldPut ("PRODUTO",    _trb -> produto)
				GDFieldPut ("DESCRICAO",  _trb -> descricao)
				GDFieldPut ("UNMEDIDA",   _trb -> un_medida)
				GDFieldPut ("ESTQ",       _trb -> estoque)
				GDFieldPut ("ESTQDUV",    _trb -> estoqueDuv)
				GDFieldPut ("QTNP",       _trb -> qtnp)
				GDFieldPut ("QNPT",       _trb -> qnpt)
				GDFieldPut ("QTSAIDA",    _trb -> qt_saiu)
				GDFieldPut ("MEDSAI1A",   _trb -> medsai1a)
				GDFieldPut ("MEDSAI6M",   _trb -> medsai6m)
				GDFieldPut ("MEDSAI3M",   _trb -> medsai3m)
				GDFieldPut ("MEDSAI1M",   _trb -> medsai1m)
				GDFieldPut ("MEDSAI1D",   _trb -> medsai1d)
				GDFieldPut ("MEDSAIGER",  _trb -> medsaiger)
				GDFieldPut ("COBERTDIA",  _trb -> cobert_dia)
				GDFieldPut ("COBERTSEM",  _trb -> cobert_sem)
				GDFieldPut ("PRECOUNIT",  _trb -> preco_unit)
				GDFieldPut ("CURESTAT",   _trb -> curestat)
				GDFieldPut ("CURINVENT",  _trb -> curinvent)
				GDFieldPut ("CURENTSAI",  _trb -> curentsai)
				GDFieldPut ("CURENTR",    _trb -> curentr)
				GDFieldPut ("CURSAID",    _trb -> cursaid)
				GDFieldPut ("LTECONPROD", _trb -> lteconprod)
				GDFieldPut ("LTREALPROD", _trb -> ltrealprod)
				GDFieldPut ("EMPENHOPV",  _trb -> empenhopv)
				GDFieldPut ("CAPPRODDIA", _trb -> capproddia)
				GDFieldPut ("ENTRPREV",   _trb -> a_receber)
				GDFieldPut ("ESTQPROJET", _trb -> estq_proj)
				GDFieldPut ("OBSERV",     _trb -> observ)
				_trb -> (dbskip ())
			enddo

		elseif _sTipoPlan == 'M'  // Materiais

			//              Titulo                Campo         Masc                  Tam Dec Valid Usado Tipo F3     Context CBox Relacao ".t."
			aadd (aHeader, {"Produto",            "PRODUTO",    "",                   15, 0,  "",   "",   "C", "SB1", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Descricao",          "DESCRICAO",  "",                   60, 0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Un.medida",          "UNMEDIDA",   "",                   2,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Saldo estoque",      "ESTQ",       "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq duvidoso",      "ESTQDUV",    "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Qt.total entradas",  "QTENTRADA",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Qt.total saidas",    "QTSAIDA",    "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Media saidas mes",   "MEDSAI1M",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Media saidas dia",   "MEDSAI1D",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Cobertura dias",     "COBERTDIA",  "@E 99999",           5,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Cobertura semanas",  "COBERTSEM",  "@E 99999",           5,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Preco unit",         "PRECOUNIT",  "@E 999,999.9999",   12,  4,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva estatica",     "CURESTAT",   "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.invent",   "CURINVENT",  "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.ent+sai",  "CURENTSAI",  "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.entrada",  "CURENTR",    "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Curva din.saida",    "CURSAID",    "",                   1,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq minimo",        "ESTQMINIMO", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq maximo",        "ESTQMAXIMO", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Lead time abast",    "LEADTIME",   "@E 999,999",         6,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Lote a comprar",     "LOTECOMPRA", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Empenho OP",         "EMPENHOOP",  "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Entradas previstas", "ENTRPREV",   "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Estq projetado",     "ESTQPROJET", "@E 999,999,999",     9,  0,  "",   "",   "N", "   ", "V",    "",  "",     '.F.'})
			aadd (aHeader, {"Observacoes",        "OBSERV",     "",                  80,  0,  "",   "",   "C", "   ", "V",    "",  "",     '.F.'})
			_aLinVazia = aclone (U_LinVazia (aHeader))
			_trb -> (dbgotop ())
			do while ! _trb -> (eof ())
				aadd (aCols, aclone (_aLinVazia))
				N = len (aCols)
				GDFieldPut ("PRODUTO",    _trb -> produto)
				GDFieldPut ("DESCRICAO",  _trb -> descricao)
				GDFieldPut ("UNMEDIDA",   _trb -> un_medida)
				GDFieldPut ("ESTQ",       _trb -> estoque)
				GDFieldPut ("ESTQDUV",    _trb -> estoqueDuv)
				GDFieldPut ("QTENTRADA",  _trb -> qt_entrou)
				GDFieldPut ("QTSAIDA",    _trb -> qt_saiu)
				GDFieldPut ("MEDSAI1M",   _trb -> medsai1m)
				GDFieldPut ("MEDSAI1D",   _trb -> medsai1d)
				GDFieldPut ("COBERTDIA",  _trb -> cobert_dia)
				GDFieldPut ("COBERTSEM",  _trb -> cobert_sem)
				GDFieldPut ("PRECOUNIT",  _trb -> preco_unit)
				GDFieldPut ("CURESTAT",   _trb -> curestat)
				GDFieldPut ("CURINVENT",  _trb -> curinvent)
				GDFieldPut ("CURENTSAI",  _trb -> curentsai)
				GDFieldPut ("CURENTR",    _trb -> curentr)
				GDFieldPut ("CURSAID",    _trb -> cursaid)
				GDFieldPut ("ESTQMINIMO", _trb -> estq_min)
				GDFieldPut ("ESTQMAXIMO", _trb -> estq_max)
				GDFieldPut ("LEADTIME",   _trb -> lead_time)
				GDFieldPut ("LOTECOMPRA", _trb -> lote_comp)
				GDFieldPut ("EMPENHOOP",  _trb -> empenhoop)
				GDFieldPut ("ENTRPREV",   _trb -> a_receber)
				GDFieldPut ("ESTQPROJET", _trb -> estq_proj)
				GDFieldPut ("OBSERV",     _trb -> observ)
				_trb -> (dbskip ())
			enddo
		endif
	endif
return _lContinua
//
// --------------------------------------------------------------------------
static function _Curva (_sCpoValor, _sCpoDest, _nIndice)
	local _nTotCurva := 0
	local _nPercA    := 80
	local _nPercB    := 15
	local _nAcumA    := 0
	local _nAcumB    := 0

	_trb -> (dbgotop ())
	do while ! _trb -> (eof ())
		_nTotCurva += _trb -> &(_sCpoValor)
		_trb -> (dbskip ())
	enddo
	_trb -> (dbsetorder (_nIndice))
	_trb -> (dbgobottom ())
	do while ! _trb -> (bof ()) .and. _nAcumA + _trb -> &(_sCpoValor) <= _nTotCurva * _nPercA / 100
		_trb -> &(_sCpoDest) = 'A'
		_nAcumA += _trb -> &(_sCpoValor)
		_trb -> (dbskip (-1))
	enddo
	do while ! _trb -> (bof ()) .and. _nAcumB + _trb -> &(_sCpoValor) <= _nTotCurva * _nPercB / 100
		_trb -> &(_sCpoDest)= 'B'
		_nAcumB += _trb -> &(_sCpoValor)
		_trb -> (dbskip (-1))
	enddo
	do while ! _trb -> (bof ())
		_trb -> &(_sCpoDest) = 'C'
		_trb -> (dbskip (-1))
	enddo
return
//
// --------------------------------------------------------------------------
// Simulação de OP de vários itens
static function _TelaSimulacao()
	local _x			:= 0
	local _oDlg         := NIL
	local _oCour24      := TFont():New("Courier New",,24,,.T.,,,,,.F.)
	private _oTxtBrw1   := NIL
	private _oGetD1     := NIL
	private aHeader     := {}
	private _aCols1     := {}

	_sCaminho := "C:\Temp\" + alltrim(mv_par02) + ".csv"

	If mv_par01 == 1
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_13PROD", "ZZZ_13QTD"}, .T.))
	else
		aHeader = aclone (U_GeraHead ("ZZZ", .T., {}, {"ZZZ_13PROD", "ZZZ_13QTD", "ZZZ_13REV"}, .T.))
	EndIf
	_aHead1    := aclone (aHeader)
	_aCols1    := {}
	_aLinVazia := aclone(U_LinVazia(aHeader))
	_aSize     := MsAdvSize()		// Define tamanho da tela.

	If !empty(_sCaminho)
		_aCols1 := _RetCSV(_sCaminho, ';', mv_par01)
	
		if Len(_aCols1) <= 0
			for _x:=1 to 99
				aadd (_aCols1, aclone (_aLinVazia))
			next
		endif
	else
		for _x:=1 to 99
			aadd (_aCols1, aclone (_aLinVazia))
		next
	EndIf

	define MSDialog _oDlg from _aSize [1], _aSize [1] to _aSize [6], _aSize [5] of oMainWnd pixel title "Produtos"
	
    //                        Linha                         Coluna                      bTxt oWnd   pict oFont     ?    ?    ?    pixel corTxt    corBack larg                          altura
    _oTxtBrw1 := tSay ():New (15,                           7,                          NIL, _oDlg, NIL, _oCour24, NIL, NIL, NIL, .T.,  CLR_BLUE, NIL,    _oDlg:nClientWidth / 2 - 90,  25)
    _oGetD1 := MsNewGetDados ():New (   40, ;                				// Limite superior
		                                5, ;                     			// Limite esquerdo
		                                _oDlg:nClientHeight / 2 - 28, ;     // Limite inferior
		                                _oDlg:nClientWidth / 2 - 10, ;      // Limite direito    // _oDlg:nClientWidth / 5 - 5, ;                     // Limite direito
		                                GD_UPDATE, ; 						// [ nStyle ]
		                                	, ;  							// Linha OK
		                                "AllwaysTrue ()", ;  				// [ uTudoOk ]
		                                NIL, ; 								// [cIniCpos]
		                                NIL,; 								// [ aAlter ]
		                                NIL,; 								// [ nFreeze ]
		                                99,; 								// [ nMax ]
		                                NIL,; 								// [ cFieldOk ]
		                                NIL,;					 			// [ uSuperDel ]
		                                NIL,; 								// [ uDelOk ]
		                                _oDlg,; 							// [ oWnd ]
		                                _aHead1,; 							// [ ParHeader ]
		                                _aCols1) 							// [ aParCols ]
    
     // Define botoes para a barra de ferramentas
    
    _bBotaoOK  = {|| processa ({||_GeraSimul ()}), _oDlg:End ()}
	_bBotaoCan = {|| _oDlg:End ()}
    
    activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, ), _oGetD1:oBrowse:SetFocus (), "")

return
//
// --------------------------------------------------------------------------
// Filtro da revisão    
User Function ZZZ13Rev()
	_sProd := GDFieldGet("ZZZ_13PROD")             
Return(_sProd)  
// 
// --------------------------------------------------------------------------
// Gera Simulação
static function _GeraSimul()
	local _x			:= 0
	local _y			:= 0
	local nAux      	:= 0
	local aProd 		:= {}
	local aProduto  	:= {}
	local aArray    	:= {}
	local aSimula   	:= {}
	local aColunas 		:= {}
	local lContinua 	:= .T.
	
	aProd   := aclone (_oGetD1:aCols)
	
	If len(aProd) > 0
		For _x:=1 to len(aProd) 
			If alltrim(aProd[_x, 1]) <> ''
				If mv_par03 == 1 // apenas revisao atual 
					aadd (aProduto,{ alltrim(aProd[_x,1]) , aProd[_x,2], "A"})
				else
					If mv_par01 == 1
						aadd (aProduto,{ alltrim(aProd[_x,1]) , aProd[_x,2], "N"})
					else
						aadd (aProduto,{ alltrim(aProd[_x,1]) , aProd[_x,2], aProd[_x,3]})
					EndIf
				EndIf
			EndIf
		Next
	Else
		lContinua := .F.
	EndIf
	
	If lContinua
		// Monta colunas para mostrar na tela.
		aadd (aColunas, { 1,  'Componente'				,45,  ''})
		aadd (aColunas, { 2,  'Descricao'				,170, ''})
		aadd (aColunas, { 3,  'Rev.estr'				,30,  ''})
		aadd (aColunas, { 4,  'Alx. padrão produto'	    ,45, '@E 999,999,999.99'})
		aadd (aColunas, { 5,  'Almox 01'				,45, '@E 999,999,999.99'})
		aadd (aColunas, { 6,  'Almox 02'				,45, '@E 999,999,999.99'})
		aadd (aColunas, { 7,  'Almox 03'				,45, '@E 999,999,999.99'})
		aadd (aColunas, { 8,  'Almox 07'				,45, '@E 999,999,999.99'})
		aadd (aColunas, { 9,  'Almox 08'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {10,  'Almox 30'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {11,  'Almox 31'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {12,  'Almox 90'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {13,  'Empenho(outras OP)'		,55, '@E 999,999,999.99'})
		aadd (aColunas, {14,  'Empenho(simulado)'		,55, '@E 999,999,999.99'})
		aadd (aColunas, {15,  'Disponivel'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {16,  'Solic.compra'			,45, '@E 999,999,999.99'})
		aadd (aColunas, {17,  'Ped.compra'				,45, '@E 999,999,999.99'})
		aadd (aColunas, {18,  'Saldo de Terc.'			,45, '@E 999,999,999.99'})
		aadd (aColunas, {19,  'Saldo em Terc.'			,45, '@E 999,999,999.99'})
		aadd (aColunas, {20,  'Observacao'				,60, ''})
	
		For _x:=1 to len(aProduto)
			sProduto := PADR(alltrim(aProduto[_x,1]),15,' ')
			nQtd     := aProduto[_x,2]
			_sRevis  := aProduto[_x,3]
			
			If nQtd <= 0
				nQtd = 1
			EndIf
			
			_SimulOP(sProduto, nQtd, aArray, .T. , _sRevis)
			
			For _y:=1 to len(aArray)
				nDeTerceiros := _SaldosDeTerceiros(aArray[_y, 1])
				nEmTerceiros := _SaldosEmTerceiros(aArray[_y, 1])
			
				aadd (aSimula,{aArray[_y, 1],; 
								aArray[_y, 2],;
								aArray[_y, 3],;
								aArray[_y, 4],;
								aArray[_y, 5],;
								aArray[_y, 6],;
								aArray[_y, 7],;
								aArray[_y, 8],;
								aArray[_y, 9],;
								aArray[_y,10],;
								aArray[_y,11],;
								aArray[_y,12],;
								aArray[_y,13],;
								aArray[_y,14],;
								aArray[_y,15],;
								aArray[_y,16],;
								aArray[_y,17],;
								nDeTerceiros ,;
								nEmTerceiros ,;
								aArray[_y,18]})
			Next
		Next
		If mv_par01 == 1 // não agrupa itens
			u_F3Array (aSimula, "Disponibilidade de componentes", aColunas,,, "Disponibilidade dos empenhos", "", .T., 'C', TFont():New ("Courier New", 6, 14))
		Else
			aTotais := {}
			for nAux := 1 to len(aSimula)
				if (nPos := ASCAN(aTotais, {|x| x[1] == aSimula[nAux][1]})) > 0
					aTotais[nPos][14] += aSimula[nAux][14]
				else
					AADD(aTotais, { aSimula[nAux][1],; 
									aSimula[nAux][2],;
									aSimula[nAux][3],;
									aSimula[nAux][4],;
									aSimula[nAux][5],;
									aSimula[nAux][6],;
									aSimula[nAux][7],;
									aSimula[nAux][8],;
									aSimula[nAux][9],;
									aSimula[nAux][10],;
									aSimula[nAux][11],;
									aSimula[nAux][12],;
									aSimula[nAux][13],;
									aSimula[nAux][14],;
									aSimula[nAux][15],;
									aSimula[nAux][16],;
									aSimula[nAux][17],;
									aSimula[nAux][18],;
									aSimula[nAux][19],;
									aSimula[nAux][20] }) 
				endif
			next nAux
			
			u_F3Array (aTotais, "Disponibilidade de componentes(agrupados)", aColunas,,, "Disponibilidade dos empenhos", "", .T., 'C', TFont():New ("Courier New", 6, 14))
		EndIf
	EndIf
return
//
// --------------------------------------------------------------------------
// Busca saldos de terceiros
Static Function _SaldosDeTerceiros(sProduto)
	local _aSaldo 	   := {}
	local nDeTerceiros := 0
	local _x           := 0
						
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT SUM(B6_SALDO) AS SALDO_DE_TERCEIROS "
	_oSQL:_sQuery += " FROM dbo.VA_VSALDOS_TERCEIROS V "
	_oSQL:_sQuery += " WHERE B6_PRODUTO = '" + sProduto + "'" 
	_oSQL:_sQuery += " AND  B6_TIPO = 'D' "
	_aSaldo := _oSQL:Qry2Array (.f., .f.)
			
	For _x:=1 to len(_aSaldo)
		nDeTerceiros += _aSaldo[_x,1]
	Next	
Return nDeTerceiros
//
// --------------------------------------------------------------------------
// Busca saldos de terceiros
Static Function _SaldosEmTerceiros(sProduto)
	local _aSaldo 	   := {}
	local nEmTerceiros := 0
	local _x           := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT SUM(B6_SALDO) AS SALDO_DE_TERCEIROS "
	_oSQL:_sQuery += " FROM dbo.VA_VSALDOS_TERCEIROS V "
	_oSQL:_sQuery += " WHERE B6_PRODUTO = '" + sProduto + "'" 
	_oSQL:_sQuery += " AND  B6_TIPO = 'E' "
	_aSaldo := _oSQL:Qry2Array (.f., .f.)
			
	For _x:=1 to len(_aSaldo)
		nEmTerceiros += _aSaldo[_x,1]
	Next
Return nEmTerceiros
//
// --------------------------------------------------------------------------
// Retorn CSV
Static Function _RetCSV(_sArq, _sSeparad, _stp)
	local _sLinha := ""
	local _aLinha := {}
	local _aRet   := {}

	if ! file (_sArq)
		u_help ("Arquivo nao encontrado: " + _sArq)
		Return _aRet
	endif
	
	FT_FUSE(_sArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()
		IncProc("Lendo arquivo " + _sArq)
		_sLinha := FT_FReadLN()
		_aLinha = U_SeparaCpo (_sLinha, iif (empty (_sSeparad), ';', _sSeparad))
		if len (_aLinha) > 0
			if _stp = 1
				aadd(_aRet, {_aLinha[1], val(_aLinha[2]), .F.})
			else
				aadd(_aRet, {_aLinha[1], val(_aLinha[2]),  _aLinha[3], .F.})
			endif
		endif
		FT_FSKIP()
	End
	FT_FUSE()
return _aRet
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	if cPerg == 'BMRP1'
		//                     PERGUNT                           TIPO TAM DEC VALID F3          Opcoes Help
		aadd (_aRegsPerg, {01, "Produto inicial               ", "C", 15, 0,  "",   "SB1  ", {},                              ""})
		aadd (_aRegsPerg, {02, "Produto final                 ", "C", 15, 0,  "",   "SB1  ", {},                              ""})
		aadd (_aRegsPerg, {03, "Somente os produtos (separ. /)", "C", 60, 0,  "",   "     ", {},                              ""})
		aadd (_aRegsPerg, {04, "Incluir produtos fora de linha", "N", 1,  0,  "",   "     ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {05, "Inclui prod.ignorados pelo MRP", "N", 1,  0,  "",   "     ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {06, "Grafico sazonalidade          ", "N", 1,  0,  "",   "     ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {07, "Grp.embalag.(quando PA)inicial", "C", 2,  0,  "",   "ZX550", {},                              ""})
		aadd (_aRegsPerg, {08, "Grp.embalag.(quando PA)final  ", "C", 2,  0,  "",   "ZX550", {},                              ""})
		aadd (_aRegsPerg, {09, "Linha prod.(quando PA) inicial", "C", 2,  0,  "",   "ZX539", {},                              ""})
		aadd (_aRegsPerg, {10, "Linha prod.(quando PA) final  ", "C", 2,  0,  "",   "ZX539", {},                              ""})
		aadd (_aRegsPerg, {11, "L.envase(recurso)(PA) inicial ", "C", 6,  0,  "",   "SH1  ", {},                              ""})
		aadd (_aRegsPerg, {12, "L.envase(recurso)(PA) final   ", "C", 6,  0,  "",   "SH1  ", {},                              ""})

	elseif cPerg == 'BMRP2'
		//                     PERGUNT                           TIPO TAM DEC VALID F3          Opcoes Help
		aadd (_aRegsPerg, {01, "Produto inicial               ", "C", 15, 0,  "",   "SB1 ", {},                              ""})
		aadd (_aRegsPerg, {02, "Produto final                 ", "C", 15, 0,  "",   "SB1 ", {},                              ""})
		aadd (_aRegsPerg, {03, "Incluir produtos fora de linha", "N", 1,  0,  "",   "    ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {04, "Inclui prod.ignorados pelo MRP", "N", 1,  0,  "",   "    ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {05, "Grafico sazonalidade          ", "N", 1,  0,  "",   "    ", {"Sim", "Nao"},                  ""})
		aadd (_aRegsPerg, {06, "Tipo produto inicial          ", "C", 2,  0,  "",   "02  ", {},                              ""})
		aadd (_aRegsPerg, {07, "Tipo produto final            ", "C", 2,  0,  "",   "02  ", {},                              ""})
		
	elseif cPerg == 'BMRP3'
		//                     PERGUNT         TIPO TAM DEC VALID F3          Opcoes Help
		aadd (_aRegsPerg, {01, "Agrupar itens?    ", "N",   1, 0,  "",  "    ", {"Nao", "Sim"},                  ""})
		aadd (_aRegsPerg, {02, "Arquivo no C:\temp", "C",  20, 0,  "",  "    ", {},                              ""})
		aadd (_aRegsPerg, {03, "Revisao           ", "N",   1, 0,  "",  "    ", {"Ativas", "Todas"},              ""})
	endif
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
