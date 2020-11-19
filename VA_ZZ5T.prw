// Programa...: VA_ZZ5T
// Autor......: Robert Koch
// Data.......: 19/02/2009
// Descricao..: Geracao de movimentos de transferencia de produtos da expedicao para a loja.
//              A transferencia consiste em desmontar a caixa e dar entrada das garrafas.
//
// Historico de alteracoes:
// 21/09/2012 - Elaine - Alteracao para tratar tamanho do campo da nota fiscal de 6 para 9 posicoes
// 26/11/2014 - Robert - Cria produto no SB2 caso ainda nao exista.
// 08/04/2019 - Catia  - include TbiConn.ch 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "rwmake.ch"

User Function VA_ZZ5T ()
	if ! empty (zz5 -> zz5_dtaten)
		msgalert ("Solicitacao ja' atendida.")
	else
		if ! cEmpAnt + cFilAnt $ '0113/0110'
			if ! msgnoyes ("Rotina desenvolvida para atender as filiais com loja (10 e 13). Confirma assim mesmo?")
				return
			endif
		endif
		if ! softlock ("ZZ5")
			msgalert ("Registro em uso por outra estacao.")
		else
			_AndaLogo ()
		endif
		dbselectarea ("ZZ5")
		msunlock ()
	endif
return



// Tela de conferencias
// --------------------------------------------------------------------------
Static Function _AndaLogo ()
	local _lContinua := .T.
	local _bBotaoOK  := {|| NIL}
	local _bBotaoCan := {|| NIL}
	local _aBotAdic  := {}
	local _sUMLoja   := ""
	local _sUMPai    := ""
	private _sLocPai := ""
	private _nQtPai  := 0
	private _nQtloja := 0
	private _nQtdEmb := 0
	private _nSaldoPai := 0
	private _sRespons  := __cUserID
	private _sNomeResp := cUserName

	// Verifica disponibilidade de estoque do produto a ser desmontado.
	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + zz5 -> zz5_codpai, .F.))
			msgalert ("Produto pai nao cadastrado")
			_lContinua = .F.
		else
			_nQtdEmb = sb1 -> b1_qtdemb
			_sLocPai = sb1 -> b1_locpad
			sb2 -> (dbsetorder (1))  // B2_FILIAL+B2_COD+B2_LOCAL
			if ! sb2 -> (dbseek (xfilial ("SB2") + zz5 -> zz5_codpai + _sLocPai, .F.))
				msgalert ("Produto pai sem saldo em estoque")
				_lContinua = .F.
			else
				_nSaldoPai = sb2 -> b2_qatu - sb2 -> b2_qemp - sb2 -> b2_reserva
			endif
		endif
	endif


	// Tela para definir a quantidade efetiva a ser transferida
	if _lContinua
	
		// Calcula a quantidade minima do pai para atender `a quantidade solicitada pela
		// loja e, depois, calcula a quantidade obtida na loja.
		_nQtPai = int (zz5 -> zz5_qtloja / _nQtdEmb)
		if zz5 -> zz5_qtloja % _nQtdEmb > 0
			_nQtPai ++
		endif
		//_nQtPai = min (_nSaldoPai, _nQtPai)
		_nQtLoja = _nQtPai * _nQtdEmb
		_sUMLoja = fBuscaCpo ("SB1", 1, xfilial ("SB1") + zz5 -> zz5_codloj, "B1_UM")
		_sUMPai  = fBuscaCpo ("SB1", 1, xfilial ("SB1") + zz5 -> zz5_codpai, "B1_UM")
		
		define MSDialog _oDlg from 0, 0 to 300, 600 of oMainWnd pixel title "Quantidades a transferir"

			@ 30, 10  say "Transferir de:"
			@ 30, 90  get (zz5 -> zz5_codpai + " - " + fBuscaCpo ("SB1", 1, xfilial ("SB1") + zz5 -> zz5_codpai, "B1_DESC")) when .F. size 180, 11
			@ 45, 10  say "Transferir para:"
			@ 45, 90  get (zz5 -> zz5_codloj + " - " + fBuscaCpo ("SB1", 1, xfilial ("SB1") + zz5 -> zz5_codloj, "B1_DESC")) when .F. size 180, 11
			@ 60, 10  say "Quantidade solicitada loja:"
			@ 60, 90  get zz5 -> zz5_qtloja picture "@E 9999" when .F.
			@ 60, 115 say _sUMLoja
			@ 75, 10  say "Quantidade minima do pai:"
			@ 75, 90  get round (zz5 -> zz5_qtloja / _nQtdEmb, 0) picture "@E 9999" when .F.
			@ 75, 115 say _sUMPai
			@ 90, 10  say "Saldo disponivel do pai:"
			@ 90, 90  get _nSaldoPai picture "@E 9999" when .F.
			@ 90, 115 say _sUMPai

			@ 75, 150  say "Quantidade a desmontar:"
			@ 75, 220  get _nQtPai picture "@E 9999" valid _ValQt ()
			@ 75, 245  say _sUMPai
			@ 90, 150  say "Quantidade obtida na loja:"
			@ 90, 220  get _nQtLoja picture "@E 9999" object _oGetLoja
			@ 90, 245 say _sUMLoja

			@ 105, 10 say "Responsavel:"
			@ 105, 90 get _sRespons valid _ValResp ()
			@ 105, 150 get _sNomeResp size 100, 11 when .F. object _oGetResp

			// Define botoes para a barra de ferramentas
			_bBotaoOK  = {|| processa ({||_Transf ()}), _oDlg:End ()}
			_bBotaoCan = {|| _oDlg:End ()}
			_aBotAdic  = {}

		activate dialog _oDlg centered on init EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic)
	endif

return



// --------------------------------------------------------------------------
// Recalcula quantidade obtida na loja.
Static Function _ValQt ()
	local _lRet := .T.
	if _nQtPai > _nSaldoPai
		msgalert ("Quantidade nao pode exceder o saldo disponivel.")
		_lRet = .F.
	endif
	if _lRet
		_nQtLoja = _nQtPai * _nQtdEmb
		_oGetLoja:Refresh ()
	endif
return _lRet



// --------------------------------------------------------------------------
Static Function _ValResp ()
	if ! usrexist (_sRespons)
		msgalert ("Usuario nao cadastrado.")
	else
		_sNomeResp = UsrRetName (_sRespons)
		_oGetResp:Refresh ()
	endif
return .t.



// Processo de transferencia
// --------------------------------------------------------------------------
static function _Transf ()
	//local _sQuery    := ""
	local _sDocto    := ""
	local _aAutoCab  := {}
	local _aAutoIte  := {}
	//local _aLinha    := {}
	local _sFilSD3   := ""
	local _sLocal    := '10'

	procregua (5)

	// Gera numero de documento. Como a numeracao era mantida manualmente pelos usuarios
	// (sempre iniciando pela letra A), existem lacunas a serem preenchidas.
	incproc ("Gerando documento")
	sd3 -> (dbsetorder (2))  // D3_FILIAL+D3_DOC+D3_COD
    // 20120921 - Elaine Alteracao NF Alianca
	_sDocto = "A00000000"
	_sFilSD3 = xfilial ("SD3")
	do while sd3 -> (dbseek (_sFilSD3 + _sDocto, .F.))
		_sDocto = soma1 (_sDocto)
        // 20120921 - Elaine Alteracao NF Alianca
		if _sDocto >= "ZZZZZZZZZ"
			msgalert ("Numeracao de documentos esgotada. Solicite manutencao do programa.")
			return
		endif
	enddo
	sd3 -> (dbsetorder (1))
	
	// Cria produto no almox. da loja, caso nao exista
	sb2->(dbsetorder(1))
	if ! sb2 -> (dbseek (xfilial ("SB2") + zz5 -> zz5_codloja + _sLocal))
		CriaSB2 (zz5 -> zz5_codloja, _sLocal)
	endif

	// Monta campos do cabecalho
	_aAutoCab := {}
	aadd (_aAutoCab, {"cProduto",   zz5 -> zz5_codpai, nil})
	aadd (_aAutoCab, {"cLocOrig",   _sLocPai,          nil})
	aadd (_aAutoCab, {"nQtdOrig",   _nQtPai,           nil})
	aadd (_aAutoCab, {"cDocumento", _sDocto,           nil})

	// Monta campos do item
	_aAutoIte := {}
	_aItem = {}
	aadd (_aItem, {"D3_COD",    zz5 -> zz5_codloja, NIL})
	aadd (_aItem, {"D3_LOCAL",  _sLocal,               NIL})
	aadd (_aItem, {"D3_QUANT",  _nQtLoja,           NIL})
	aadd (_aItem, {"D3_RATEIO", 100,                NIL})
	aadd (_aAutoIte, aclone (_aItem))

	lMSErroAuto = .F.
	dbselectarea ("SD3")
	MSExecAuto({|v,x,y,z| Mata242(v,x,y,z)},_aAutoCab,_aAutoIte,3,.T.)
	If lMsErroAuto
		mostraerro()
	else

		// Atualiza solicitacao como 'atendida'.
		reclock ("ZZ5", .F.)
		zz5 -> zz5_dtaten = ddatabase
		zz5 -> zz5_qtreal = _nQtLoja
		zz5 -> zz5_doctr  = _sDocto
		zz5 -> zz5_respon = _sRespons
		msunlock ()

		msginfo ("Transferencia realizada com sucesso. Documento gerado: " + _sDocto)
	endif
return
