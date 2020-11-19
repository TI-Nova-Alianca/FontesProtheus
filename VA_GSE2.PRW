// Programa:  VA_GSE2
// Autor:     Catia Cardoso
// Data:      01/02/2018
// Descricao: Gera titulos no financeiro a partir de um excel 
//
// Historico de alteracoes:
//
// 06/09/2018 - Catia  - Criada a opcao de importar cedulas/km
// 10/12/2018 - Catia  - alterada conta para contabilizacao de delegados
// 10/06/2019 - Catia  - validação do CPF e do valor
// 03/10/2019 - Robert - Passa a receber parametros via SX1
//                     - Validacoes adicionais dos dados antes de gerar os titulos.
//

//#include "totvs.ch"
//#include "protheus.ch"
//#INCLUDE "rwmake.ch"
//#INCLUDE "topconn.ch"
//#INCLUDE "tbiconn.ch"

// --------------------------------------------------------------------------
User Function VA_GSE2(_lAutomat)
	Local cCadastro := "Importacao de planilha para contas a pagar"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VA_GSE2"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa ({|lEnd| _Gera()})
	else
		AADD(aSays,"Este programa tem como objetivo importar uma planilha")
		AADD(aSays,"com dados para geracao de titulos a pagar.")
		AADD(aSays,"")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return

//Static Function close()
//Return


//Static Function diretorio()
	//_caminho := cGetFile('*.*','Arquivos (Todos)',1,,.T.,GETF_LOCALHARD + GETF_NETWORKDRIVE)
//Return

// --------------------------------------------------------------------------
Static Function _Gera () //(_caminho)
	Local _aDados    := {}
	local _aDados2   := {}
	local _sTipoDesp := ''
	local _sTipoTit  := ''
	local _sPrefixo  := ''
	local _oSQL      := NIL
	local _sNatur    := ''
	local _sCCD      := ''
	local _sHist     := ''
	local _sContaD   := ''
	local _nQtGera   := 0
	local _nVlGera   := 0
	//local i			 := 0
	local _i	     := 0

	Private lMsErroAuto := .F. // Determina se houve alguma inconsistencia na execucao da rotina 

	If !File(mv_par01)
		u_help ("O arquivo '" + mv_par01 + "' não foi encontrado. Atualização não realizada!")
		Return
	EndIf

	FT_FUSE(mv_par01)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()
		cLinha := FT_FREADLN()
		AADD(_aDados,Separa(cLinha,";",.T.))
		FT_FSKIP()
	EndDo   

	// Prepara nova array com todos os dados necessarios. Se algo faltar, aborta toda a operacao.
	u_log (_aDados)
	_aDados2 := {}
	For _i := 1 To Len(_aDados)
		_wnome   = _aDados[ _i, 1] 
		_wcpf    = alltrim (_aDados[ _i, 2])
		_sTipoDesp = upper (alltrim (_aDados[ _i, 4]))
		
		// Alguns tipos de despesa vem com descricao 'delegado' / 'delegada' ou 'confis' / 'consad' por exemplo...
		if 'DELEGAD' $ _sTipoDesp .or. 'AVISADOR' $ _sTipoDesp
			_sTipoDesp = 'DELEGADO'
		elseif _sTipoDesp $ 'CONFIS/CONSAD'
			_sTipoDesp = 'CONSELHO'
		endif

		_wvalor  = val (strtran(strtran (_aDados[_i,5], '"', ''),",","."))
		if _wvalor = 0
			u_help ("Valor zerado atribuido ao registros. Impotação cancelada, verifique CPF: " + _wcpf)
			return
		endif
		if len(_wcpf) <> 11
			u_help ("CPF invalido, verifique digitos a esquerda. Impotação cancelada, verifique CPF: " + _wcpf)
			return
		endif
		sa2 -> (dbsetorder (3))
		if ! sa2 -> (dbseek (xfilial ("SA2") + _wcpf, .F.))
			u_help ("Associado não cadastrado, verifique CPF: " + _wcpf)
			u_help ("CPF desconsiderado " + _wcpf)
			return
		endif
		if sa2 -> a2_msblql == '1' .or. sa2 -> a2_ativo != 'S'
			u_help ("Fornecedor '" + sa2 -> a2_cod + "' bloqueado ou inativo.")
			return
		endif

		if _sTipoDesp == 'UNIMED'
			_sTipoTit = 'NDF'
			_sPrefixo = 'UNI'
			_sNatur   = '120201'
			_sHist    = 'UNIMED ASSOCIADOS'
			_sContaD  = ''
			_sCCD     = ''
		elseif _sTipoDesp == 'DELEGADO'
			_sTipoTit = 'DP'
			_sPrefixo = 'DEL'
			_sNatur   = '120206'
			_sHist    = 'DESP.VIAGEM DELEGADOS-KM'
			_sContaD  = '403010201050'
			_sCCD     = '013002'
		elseif _sTipoDesp == 'CONSELHO'
			_sTipoTit = 'DP'
			_sPrefixo = 'CED'
			_sNatur   = '120506'
			_sHist    = 'CEDULAS PRESENCA/KM'
			_sContaD  = '403010201050'
			_sCCD     = '013002'
		elseif _sTipoDesp == 'ALELO'
			_sTipoTit = 'DP'
			_sPrefixo = 'ALE'
			_sNatur   = '120206'
			_sHist    = 'ALELO DEV SALDO CARTAO'
			_sContaD  = ''
			_sCCD     = ''
		else
			u_help ("Tipo de despesa '" + _sTipoDesp + "' sem tratamento")
			return
		endif

		aadd (_aDados2, {sa2 -> a2_cod, sa2 -> a2_loja, _sTipoDesp, _sTipoTit, _sPrefixo, _wvalor, _sNatur, _sHist, _sContaD, _sCCD, mv_par02})
	next
	
	U_GravaSX1 ( "FIN050", "01", 1 )  // para nao mostrar os lançamentos contabeis
	U_GravaSX1 ( "FIN050", "04", 2 )  // para fazer a contabilizacao on-line

	// Se chegou ateh aqui, deve ter todos os dados necessarios.
	_oSQL := ClsSQL ():New ()
	u_log (_aDados2)
	For _i := 1 To Len (_aDados2)
		
		// Busca o primeiro numero livre para este fornecedor.
		_oSQL:_sQuery := "SELECT ISNULL ((SELECT MAX (E2_NUM)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_oSQL:_sQuery +=   " AND E2_FORNECE = '" + _aDados2 [_i, 1] + "'"
		_oSQL:_sQuery +=   " AND E2_LOJA    = '" + _aDados2 [_i, 2] + "'"
		_oSQL:_sQuery +=   " AND E2_PREFIXO = '" + _aDados2 [_i, 5] + "'"
		_oSQL:_sQuery +=   " ), '000000000')"
		_oSQL:Log ()
		_wnumero = soma1 (_oSQL:RetQry ())

		// Gera titulo no contas a pagar.
		_aAutoSE2 := {}
		aadd (_aAutoSE2, {"E2_EMISSAO", dDataBase						, Nil})
		aadd (_aAutoSE2, {"E2_NUM"    , _wnumero 						, Nil})
		aadd (_aAutoSE2, {"E2_FORNECE", _aDados2 [_i, 1]				, Nil})
		aadd (_aAutoSE2, {"E2_LOJA"   , _aDados2 [_i, 2]				, Nil})
		aadd (_aAutoSE2, {"E2_TIPO",    _aDados2 [_i, 4]				, Nil})
		aadd (_aAutoSE2, {"E2_PREFIXO", _aDados2 [_i, 5]				, Nil})
		aadd (_aAutoSE2, {"E2_VALOR"  , _aDados2 [_i, 6]				, Nil})
		aadd (_aAutoSE2, {"E2_NATUREZ", _aDados2 [_i, 7]				, Nil})
		aadd (_aAutoSE2, {"E2_HIST"   , _aDados2 [_i, 8]				, Nil})
		aadd (_aAutoSE2, {"E2_CONTAD" , _aDados2 [_i, 9]				, Nil})
		aadd (_aAutoSE2, {"E2_CCD"    , _aDados2 [_i, 10]				, Nil})
		aadd (_aAutoSE2, {"E2_VENCTO" , _aDados2 [_i, 11]				, Nil})
		aadd (_aAutoSE2, {"E2_VACHVEX", 'VA_GSE2'						, Nil})
		_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
		u_log (_aAutoSE2)
		lMsErroAuto	:= .f.
		lMsHelpAuto	:= .f.
		_sErroAuto  := ""
		dbselectarea ("SE2")
		dbsetorder (1)
		MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
		if lMsErroAuto
			u_help ("Erro na rotina quer gera SE2 a partir de excel:" + U_LeErro (memoread (NomeAutoLog ())) + _sErroAuto)
			_lContinua = .F.
			MostraErro()
		else
			u_log ('titulo gerado')
			_nQtGera ++
			_nVlGera += se2 -> e2_valor
		endif
	next
	u_help ('Processo finalizado. ' + cvaltochar (_nQtGera) + ' titulos gerados, totalizando valor de ' + cvaltochar (_nVlGera))
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                                Help
	aadd (_aRegsPerg, {01, "Arquivo CSV a importar        ", "C", 60, 0,  "",   "DIR   ", {},                                   ""})
	aadd (_aRegsPerg, {02, "Data vencto. a gerar          ", "D", 8,  0,  "",   "      ", {},                                   ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
