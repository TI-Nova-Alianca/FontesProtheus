// Programa:  VA_ETAF
// Autor:     Robert Koch
// Data:      27/07/2017
// Descricao: Exporta alguns dados para o modulo TAF para evitar digitacao.
//
// Historico de alteracoes:
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
User Function VA_ETAF (_lAuto)
	Local cCadastro   := "Arquivo p/ Declaracao Vinicola"
	Local aSays       := {}
	Local aButtons    := {}
	Local nOpca       := 0
	Local lPerg       := .F.
	private cPerg    := "VA_ETAF"

	_ValidPerg ()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	AADD (aSays, "Exporta alguns dados para o modulo TAF.")
	AADD (aSays, "O arquivo gerado deve ser importado na integracao TXT como se fosse originado")
	AADD (aSays, "por outro ERP nao-Totvs.")

	AADD (aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD (aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD (aButtons, { 2,.T.,{|| FechaBatch() }} )

	if _lAuto
		Processa( { |lEnd| _GeraTxt() } )
	else
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| _GeraTxt() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
static function _TudoOK ()
return .T.


// --------------------------------------------------------------------------
Static Function _GeraTxt()
	private _sErros    := ""
	private _sAvisos   := ""
	private _nHdl      := 0

	delete file (alltrim (mv_par01))
	_nHdl = fCreate (alltrim (mv_par01))
	If _nHdl==-1
		u_help("O arquivo de nome '" + alltrim (mv_par01) + "' nao pode ser criado! Verifique os parametros.")
		Return
	Endif

	ProcRegua(10)

	// Uma funcao para gerar cada tipo de registro.
	_T001 ()
	_T111 ()
	fClose(_nHdl)

	if ! empty (_sErros)
		delete file (alltrim (mv_par01))
		U_Help ("#################" + chr (13) + char (10) + ;
		        "ERROS ENCONTRADOS" + chr (13) + char (10) + ;
		        "#################" + chr (13) + char (10) + ;
		        "Foram encontrados erros que impedem a execucao do processo.", _sErros)
	else
		if ! empty (_sAvisos)
			u_help ("Arquivo '" + alltrim (mv_par01) + "' gerado, mas com os seguintes avisos:", _sAvisos)
		else
			u_help ("Arquivo '" + alltrim (mv_par01) + "' gerado com sucesso.")
		endif
	endif
return



// -------------------------------------------------------------------------
static function _T001 ()
	local _sLinha := ""
	_sLinha += "|T001|0101"
	_sLinha += "|alianca@novaalianca.coop.br"
	_sLinha += "||1|T"
	_sLinha += "|" + alltrim (sm0 -> m0_nomecom)
	_sLinha += "|||"
	fwrite (_nHdl, _sLinha + chr (13) + chr (10))
return



// -------------------------------------------------------------------------
static function _T111 ()
	local _sLinha   := ""
	local _sAliasQ  := ""
	local _nSldCap  := 0
	local _nTotCap  := 0
	local _aAssoc   := {}
	local _nAssoc   := 0
	local _oAssoc   := NIL
	local _dDataRef := mv_par02

	procregua (10)
	incproc ()

	// Gera dados para tabela CGM (socios da empresa para SPED) com base nos dados de associados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT A2_VACBASE, A2_VALBASE, A2_TIPO"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2"
	_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_COD     = SA2.A2_VACBASE"  // PEGA APENAS O CODIGO E LOJA BASE PARA NAO REPETIR O MESMO ASSOCIADO.
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = SA2.A2_VALBASE"
	
	// Testes:  	_oSQL:_sQuery += " AND SA2.A2_COD <= '000161'"
	
	_oSQL:_sQuery += " AND EXISTS (SELECT *"
	_oSQL:_sQuery +=               " FROM " + RetSQLName ("SZI") + " SZI"
	_oSQL:_sQuery +=               " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                 " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                 " AND SZI.ZI_LOJASSO = SA2.A2_LOJA"
	_oSQL:_sQuery +=                 " AND SZI.ZI_DATA   <= '" + dtos (_dDataRef) + "')"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	_nTotCap = 0
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		_oAssoc := ClsAssoc ():New ((_sAliasQ) -> a2_vacbase, (_sAliasQ) -> a2_valbase)
		incproc (_oAssoc:Nome)
		_nSldCap = _oAssoc:SldQuotCap (_dDataRef) [.QtCapSaldoNaData]
		if _nSldCap > 0
			aadd (_aAssoc, {_oAssoc:CodBase, ;
			                _oAssoc:LojaBase, ;
			                _oAssoc:Nome, ;
			                _oAssoc:CPF, ;  ////transform (_oAssoc:CPF, iif ((_sAliasQ) -> a2_tipo == 'J', "@R 99.999.999/9999-99", "@R 999.999.999-99")), ;
			                _oAssoc:DtEntrada (_dDataRef), ;
			                _oAssoc:DtSaida (_dDataRef), ;
			                _nSldCap, ;
			                0})
			_nTotCap += _nSldCap
		endif
		(_sAliasQ) -> (dbskip ())
 	enddo

	// Calcula percentual de participacao de cada associado.
	for _nAssoc = 1 to len (_aAssoc)
		_aAssoc [_nAssoc, 8] = round (_aAssoc [_nAssoc, 7] * 100 / _nTotCap, 2)
	next
	
	// Ordena por ranking de percentual de participacao
	asort (_aAssoc,,, {|_x, _y| _x [8] > _y [8]})
	
	// Exporta para TXT no layout do TAF.
	for _nAssoc = 1 to len (_aAssoc)
		_sLinha := "|T111"  // Tipo registro
		_sLinha += "|" + dtos (mv_par02)  // Periodo
		_sLinha += "|" + dtos (_aAssoc [_nAssoc, 5])  // Data associacao
		_sLinha += "|" + dtos (_aAssoc [_nAssoc, 6])  // Data desassociacao
		_sLinha += "|105"  // Codigo pais cfe tabela do SPED
		_sLinha += "|" + iif (len (alltrim (_aAssoc [_nAssoc, 4])) > 11, "2", "1")  // Qualificacao: 1=PF;2=PJ;3=Fundo de investimento
		_sLinha += "|" + _aAssoc [_nAssoc, 4]  // CPF ou CNPJ
		_sLinha += "|" + alltrim (_aAssoc [_nAssoc, 3])  // Nome
		_sLinha += "|" + iif (len (alltrim (_aAssoc [_nAssoc, 4])) > 11, "03", "01")  // Qualificacao
		_sLinha += "|" + cvaltochar (_aAssoc [_nAssoc, 8])  // Percentual sobre o total de capital
		_sLinha += "|" + cvaltochar (_aAssoc [_nAssoc, 8])  // Percentual sobre o total votante
		_sLinha += "|"  // CPF do representante legal
		_sLinha += "||"  // Qualificacao do representante legal
		fwrite (_nHdl, _sLinha + chr (13) + chr (10))
	next
Return



// -------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Arquivo destino               ", "C", 60, 0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Data ref.para quadro socios   ", "D",  8, 0,  "",   "   ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
