// Programa:  VA_Rcb
// Autor:     Robert Koch
// Data:      07/05/2009
// Descricao: Impressao de recibo generico.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio 
// #Descricao         #Impressao de recibo generico.
// #PalavasChave      #recibo_generico #recibo
// #Modulos           #todos 
//
// Historico de alteracoes:
// 10/05/2010 - Robert  - Recebe array com dados de programa externo.
// 04/04/2011 - Robert  - Possibilidade de imprimir recibo de pagaramento ou de recebimento.
//                      - Iniciado tratamento para mais de um layout de impressao.
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// --------------------------------------------------------------------------
User Function VA_RCB (_aDados)
	private cPerg    := "VA_RCB"
	
	_ValidPerg ()
	
	if valtype (_aDados) == "A"
		pergunte (cPerg, .F.)
		processa ({|| _AndaLogo (_aDados)})
	else
		if pergunte (cPerg, .T.)
			processa ({|| _AndaLogo ()})
		endif
	endif
	
Return
//
// --------------------------------------------------------------------------
// Geracao do arquivo de trabalho p/ impressao
static function _AndaLogo (_aDados)
	local _oPrn      := NIL
	local _oCour14N  := TFont():New("Courier New",,14,,.T.,,,,,.F.)
	local _oCour16   := TFont():New("Courier New",,16,,.F.,,,,,.F.)
	local _oCour16N  := TFont():New("Courier New",,16,,.T.,,,,,.F.)
	local _oCour20N  := TFont():New("Courier New",,20,,.T.,,,,,.F.)
	local _oArial10  := TFont():New("Arial",,10,,.F.,,,,,.F.)
	local _oArial16  := TFont():New("Arial",,16,,.F.,,,,,.F.)
	local _oArial32N := TFont():New("Arial",,32,,.T.,,,,,.F.)
	local _oArial48N := TFont():New("Arial",,48,,.T.,,,,,.F.)
	local _nPagAtual := 1
	local _nLinAtual := 0
	local _nMargSup  := 40
	local _nMargInf  := 50
	local _nMargEsq  := 40
	local _nAltPag   := 1400
	local _nLargPag  := 2350
	local _sExtenso  := ""
	local _nDado	 := 0
	// Se recebeu array com os dados de outro programa, utiliza-a. Senao, monta uma array com os parametros do usuario.
	if valtype (_aDados) != "A"
		_aDados = {{mv_par01, mv_par02, mv_par03, mv_par04, mv_par05, mv_par06, mv_par07, mv_par08, mv_par09}}
	endif

	// Objetos para impressao
	_oPrn:=TAVPrinter():New("VA_LPR")
	_oPrn:Setup()           // Tela para usuario selecionar a impressora
	_oPrn:SetPortrait()     // ou SetLanscape()

	_mvSimb1 := GetMv ("MV_SIMB1")
	for _nDado = 1 to len (_aDados)
		_oPrn:StartPage ()
	
		if _aDados [_nDado, 9] == 1  // Um por folha

			// Monta uma caixa em torno de todo o recibo.
			_oPrn:Box(_nMargSup + 20, _nMargEsq + 20, _nMargSup + _nAltPag, _nLargPag - _nMargEsq)
			
			_oPrn:Say (_nMargSup + 50,  _nMargEsq + 40, "R E C I B O", _oArial48N, 100)
			_oPrn:Say (_nMargSup + 100,  _nMargEsq + 1300, _mvSimb1 + " " + alltrim (transform (_aDados [_nDado, 2], "@E 999,999,999.99")) , _oArial32N, 100)
			
			_oPrn:Say (_nMargSup + 288,  _nMargEsq + 50, "Recebi(emos) de ", _oCour16, 100)
			_oPrn:Say (_nMargSup + 270,  _nMargEsq + 600, left (_aDados [_nDado, 1], 37), _oCour20N, 100)
			
			_sExtenso = Extenso (_aDados [_nDado, 2])
			_oPrn:Say (_nMargSup + 388,  _nMargEsq + 50, "A importancia de ", _oCour16, 100)
			_oPrn:Say (_nMargSup + 370,  _nMargEsq + 600, left (_sExtenso, 37), _oCour20N, 100)
			_oPrn:Say (_nMargSup + 470,  _nMargEsq + 50,  substr (_sExtenso, 38, 50), _oCour20N, 100)
			_oPrn:Say (_nMargSup + 570,  _nMargEsq + 50,  substr (_sExtenso, 88, 50), _oCour20N, 100)
			
			_oPrn:Say (_nMargSup + 688,  _nMargEsq + 50, "Correspondente a ", _oCour16, 100)
			_oPrn:Say (_nMargSup + 670,  _nMargEsq + 650, left (_aDados [_nDado, 3], 36), _oCour20N, 100)
			_oPrn:Say (_nMargSup + 770,  _nMargEsq + 50, left (_aDados [_nDado, 4], 50), _oCour20N, 100)
			
			// Adicionais (nome, etc)
			_oPrn:Say (_nMargSup + 938,  _nMargEsq + 50, left (_aDados [_nDado, 5], 50), _oCour16, 100)
			
			_oPrn:Say (_nMargSup + 1088,  _nMargEsq + 50, alltrim (left (_aDados [_nDado, 6], 25)) + ", " + dtoc (_aDados [_nDado, 7]), _oCour16, 100)
			
			_oPrn:Say (_nMargSup + 1200,  _nMargEsq + 1300, "_____________________", _oCour20N, 100)
			if _aDados [_ndado, 8] == 1  // Pagamento
				_oPrn:Say (_nMargSup + 1300,  _nMargEsq + 1670, "Assinatura", _oArial10, 100)
			else  // Recebimento
				_oPrn:Say (_nMargSup + 1300,  _nMargEsq + 1300, alltrim (sm0 -> m0_nomecom), _oArial10, 100)
			endif
		
		elseif _aDados [_nDado, 9] == 2  // 2 por folha
			u_help ("Layout ainda nao pronto.")
		endif

		_oPrn:EndPage()
	next
	_oPrn:Preview()  // Visualiza antes de imprimir
	_oPrn:End()

return
//
// --------------------------------------------------------------------------
// Perguntas
static function _ValidPerg ()
	local _aRegsPerg  := {}
	local _aHelpPerg  := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                          Help
	aadd (_aRegsPerg, {01, "Recebi(emos) de               ", "C", 37, 0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {02, "A importancia de              ", "N", 12, 2,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {03, "Correspondente a              ", "C", 36, 0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {04, "Correspondente a (continuacao)", "C", 50, 0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {05, "Adicionais (nome, etc.)       ", "C", 50, 0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {06, "Local                         ", "C", 25, 0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {07, "Data                          ", "D", 8,  0,  "",   "   ", {},                               ""})
	aadd (_aRegsPerg, {08, "Tipo de recibo                ", "N", 1,  0,  "",   "   ", {"Pagamento", "Recebimento"},     ""})
	aadd (_aRegsPerg, {09, "Layout                        ", "N", 1,  0,  "",   "   ", {"1 por pagina", "2 por pagina"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, _aHelpPerg)
return
