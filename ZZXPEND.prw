//  Programa...: ZZX_PEN
//  Autor......: Catia Cardoso
//  Data.......: 28/09/2015
//  Descricao..: Arquivos XML Emitidos contra a COOPEATIVA que ainda não foram dado entrada no sistema
//
//  Historico de alteracoes:
//  
//  22/10/2015 - Catia - Desconsiderar contra notas (por fornecedor)
//  22/10/2015 - Catia - Desconsiderar notas de transferencia de impostos - serie 20 - de uma filial pra outra
//  22/10/2015 - Catia - Usar o filtro a partir do campo STATUS no ZZX
//  ----------------------------------------------------------------------------------------------------------
user function ZZXPEND()
	local _aCores     := U_L_ZZXPEND (.T.)
	local _aIndBrw    := {}
	Private aRotina   := {}
	private cCadastro := "XML Emitidos e Pendentes de Recebimento"
	Private cString   := "ZZX"
	private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
	
	u_help("Programa foi substituído. Usar manutenção de XML de Entrada.")
	return
	
	cPerg   := "ZZXPEND"
	_ValidPerg()
    if Pergunte(cPerg,.T.) 
	
		aadd (aRotina, {"&Pesquisar"      , "AxPesqui"         , 0, 1})
		aadd (aRotina, {"&Visualizar"     , "AxVisual"         , 0, 2})
		aadd (aRotina, {"&Gera Pre-nota"  , "U_ZZXPRE_()"      , 0, 4})
		aadd (aRotina, {"&Identifica DOC" , "U_ZZXSF1()"       , 0, 4})
		aadd (aRotina, {"&Legenda"        , "U_L_ZZXPEND(.F.)" , 0 ,5})
		aadd (aRotina, {"Revalida XML"    , "U_ZZXR (.T.)"     , 0, 2})
		
	
    	dbSelectArea("ZZX")
    	DbSetOrder(5)
    
    	_cCondicao :=" ZZX_FILIAL = '" + xfilial("ZZX") + "'"
    	_cCondicao +=" .AND. ZZX_EMISSA     >= stod('20150901')"
    	_cCondicao +=" .AND. ZZX_STATUS     != '1'"
    	_cCondicao +=" .AND. (ZZX_RETSEF     = '100' .OR. ZZX_RETSEF     = '')"
    	_cCondicao +=" .AND. (ZZX_CHAVE != ''    .OR. (ZZX_CHAVE = 'Nao se aplica' .AND. ZZX_LAYOUT = 'NFS-e') )"
    	_cCondicao +=" .AND. ZZX_LAYOUT     != 'ConsNFSeRps'"  
    	_cCondicao +=" .AND. ZZX_LAYOUT     != 'procEventoNFe'"
    	// desconsidera contra notas SEMPRE
    	_cCondicao +=" .AND. ZZX_CONTRA     != 'S'"
    	_cCondicao +=" .AND. ZZX_CLIFOR     != '005121'
    	_cCondicao +=" .AND. ZZX_CLIFOR     != '004814'
    	// desconsidera notas de complemento de imposto 
    	_cCondicao +=" .AND. (ZZX_SERIE !='20' .AND. LEFT(ZZX_CNPJEM,8) != '88612486')
    	// add parametros no browse
		if mv_par01 == 2 // NF-e Devolução
			_cCondicao += " .AND. ZZX->ZZX_TIPONF != 'D'"
		endif
		if mv_par02 == 2 // NF-e Transferencias
			_cCondicao += " .AND. ZZX->ZZX_TRANSF != 'S'"
		endif
		if mv_par03 == 2 // CT-e
			_cCondicao += " .AND. ZZX->ZZX_LAYOUT != 'procCTe'" 
		endif
		if mv_par04 == 2 // NFS-e
			_cCondicao += " .AND. ZZX->ZZX_LAYOUT != 'NFS-e'"
		endif
		if mv_par05 == 2 // NF-e Normal
			_cCondicao += " .AND. ZZX->ZZX_TIPONF != 'N'"
		endif
		
		//_cCondicao +=" .AND. (ZZX->ZZX_LAYOUT = 'NFS-e' .AND. EMPTY(fBuscaCpo('SA3', 9, xfilial('SA3') + ZZX_CLIFOR, 'A3_COD')) )"
		
		_bFilBrw := {|| FilBrowse('ZZX',@_aIndBrw,@_cCondicao) }
		Eval(_bFilBrw)
		DbSelectArea('ZZX')
		mBrowse(,,,,'ZZX',,,,,2, _aCores)
		EndFilBrw('ZZX',_aIndBrw)
		DbSelectArea('ZZX')
		DbSetOrder(5) // ordenar por data de emissao
		Eval(_bFilBrw)
		DbClearFilter()
    	
    endif
return

// ------------------------------
// Geracao de Pre-Nota de entrada
// ------------------------------
user function ZZXPRE_()
	local _sXML     := ""
	local _oNFe     := NIL
	local _sErros   := ""
	local _nErro	:= 0
	local _nNota	:= 0
	local _aAmbAnt  := U_SalvaAmb ()  // As rotinas automaticas alteram o conteudo das variaveis mv_par.
	
	u_help("Função ainda não implementada.")
	return
	
	u_logIni ()

	_sXML = MSMM (zzx -> zzx_codmem,,,,3)
	u_log ("XML lido:", _sXml)

	// Neste ponto jah tenho o XML em formato string. Posso ler seus dados principais.
	_oNFe := ClsNFe ():New ()
	_oNFe:LeXML (_sXML)
	if len (_oNFe:XMLErros) > 0
		for _nErro = 1 to len (_oNFe:XMLErros)
			_sErros += _oNFe:XMLErros [_nErro] + chr (13) + chr (10)
		next
	else
		for _nNota = 1 to len (_oNFe:XMLNotas)
			_oXMLNota := ClsXmlNF ():New (_oNFe:XMLLayout, _oNFe:XMLTpEvt)
			_oXMLNota := _oNFe:XMLNotas [_nNota]
			if ! _oXMLNota:GeraNF (_lPreNF, _sCondPag)
				for _nErro = 1 to len (_oXMLNota:Erros)
					_sErros += _oXMLNota:Erros [_nErro] + chr (13) + chr (10)
				next
			endif
		next
	endif

	U_SalvaAmb (_aAmbAnt)
	u_logFim ()
return

// --------------------
// Identifica documento
// --------------------
user function ZZXSF1()
    u_help("Função ainda não implementada.")
return

// ------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function L_ZZXPEND (_lRetCores)
    local _aCores   := {}
	local _aCores2  := {}
	local _i		:= 0
	
	aadd (_aCores, {"ZZX->ZZX_TRANSF = 'S'"                              , 'BR_PRETO'   , 'NFe Transferencia'})
    aadd (_aCores, {"ZZX->ZZX_LAYOUT = 'procCTe'"                        , 'BR_LARANJA' , 'CTe'})
	aadd (_aCores, {"ZZX->ZZX_LAYOUT = 'NFS-e'"                          , 'BR_AZUL'    , 'NFe Serviço'})
	aadd (_aCores, {"ZZX->ZZX_TIPONF = 'D'"                              , 'BR_AMARELO' , 'NFe Devolução'})
    aadd (_aCores, {"ZZX->ZZX_TIPONF = 'N' .AND. ZZX->ZZX_TRANSF != 'S'" , 'BR_VERDE'   , 'NFe Normal'})
    
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Lista Devoluções           ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {02, "Lista Transferências       ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {03, "Lista CT-e                 ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {04, "Lista NFS-e                ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {05, "Lista NF-e Normal          ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
