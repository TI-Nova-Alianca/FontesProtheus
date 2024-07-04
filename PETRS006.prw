// Programa.:  PETRS006
// Autor....:  Robert Koch
// Data.....:  20/07/2022
// Descricao:  Ponto de entrada no importador de XML da Totvs RS.
//             Permite manipulacao dos dados de cabecalho e linha para execauto.
//             Criado inicialmente para gravacao de eventos e logs
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada no importador de XML da Totvs RS. Permite manipulacao dos dados de cabecalho e linha para execauto.
// #PalavasChave      #ponto_entrada #importador_XML
// #TabelasPrincipais #SD1 #SF1
// #Modulos           #COM #EST
//
// Historico de alteracoes:
// 28/11/2022 - Claudia - Acrescentada a gravação do campo F1_VAFLAG. GLPI: 12841
// 06/12/2022 - Robert  - Gravacao do campo D1_DESCRI
// 30/01/2023 - Robert  - Melhoria gravacao eventos.
// 08/03/2023 - Robert  - Melhorada extracao de campos e gravacao de evento.
//                      - Acrescentado D1_CONTA = B1_CONTA
// 21/03/2024 - Robert  - Iniciada leitura do arquivo XML (ainda sem gravar dados) - GLPI 
// 03/07/2024 - Claudia - Passando data e hora para o metodo GravaNovo. GLPI: 15671
// 04/07/2024 - Claudia - Retirada a gravação de evento. GLPI:15671
//
// ---------------------------------------------------------------------------------------------------------------------------------------

#Include "Protheus.ch"
#Include "RwMake.ch"

#XTranslate .HistStatus            => 1
#XTranslate .HistXMLOriginal       => 2
#XTranslate .HistObjetoXML         => 3
#XTranslate .HistUltItemProcessado => 4
#XTranslate .HistQtColunas         => 4

User Function PETRS006()
	//local _oEvento  := NIL
	Local _aTRS006  := PARAMIXB
	Local _aCabec   := _aTRS006[3]
	Local _aLinha   := _aTRS006[4]
	local _aRet     := {}
	local _aAreaAnt := U_ML_SRArea()
	local _aAmbAnt  := U_SalvaAmb()
	local _nPosProd := 0
	local _sProduto := ''
	local _sDoc     := ''
	local _sSerie   := ''
	local _sFornece := ''
	local _sLoja    := ''
	local _sChvNFe  := ''
	local _nPos     := 0
	static _aHistCham := {}

	U_Log2('debug', '[' + procname() + ']_aLinha na entrada:')
	U_Log2('debug', _aLinha)
	U_Log2('debug', '[' + procname() + ']_aHistCham na entrada:')
	U_Log2('debug', _aHistCham)
	//	u_showarray (_aTRS006)

	// Acrescenta campos especificos na array do cabecalho. Como este P.E. eh
	// chamado uma vez para cada item da nota, preciso evitar duplicidade
	if ascan(_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_VAFLAG'}) == 0
		AADD(_aCabec, {"F1_VAFLAG", 'P', Nil})  // P='nota importada pelo painel XML'
		U_Log2('debug', '[' + procname() + ']Estou na primeira chamada, pois o campo F1_VAFLAG ainda nao consta em _aCabec')

		// Sendo uma variavel STATIC, preciso inicializa-la na primeira chamada.
		U_Log2('debug', '[' + procname() + ']Inicializando historico')

		_aHistCham = array (.HistQtColunas)
		_aHistCham [.HistStatus]            = ''
		_aHistCham [.HistXMLOriginal]       = ''
		_aHistCham [.HistObjetoXML]         = NIL
		_aHistCham [.HistUltItemProcessado] = 0
	endif

	// Extrai alguns dados das arrays recebidas.
	_nPos = ascan(_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_CHVNFE'})
	if _nPos > 0
		_sChvNFe = _aCabec [_nPos, 2]
	else
		u_help("Nao encontrei o campo F1_CHVNFE na array de dados para geracao da nota. Impossivel buscar dados adicionais.",, .t.)
	endif
	_nPos = ascan(_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_FORNECE'})
	if _nPos > 0
		_sFornece = _aCabec [_nPos, 2]
	else
		u_help("Nao encontrei o campo F1_FORNECE na array de dados para geracao da nota. Impossivel buscar dados adicionais.",, .t.)
	endif
	_nPos = ascan(_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_LOJA'})
	if _nPos > 0
		_sLoja = _aCabec [_nPos, 2]
	else
		u_help ("Nao encontrei o campo F1_LOJA na array de dados para geracao da nota. Impossivel buscar dados adicionais.",, .t.)
	endif
	_nPos = ascan(_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_DOC'})
	if _nPos > 0
		_sDoc = _aCabec [_nPos, 2]
	else
		u_help("Nao encontrei o campo F1_DOC na array de dados para geracao da nota. Impossivel buscar dados adicionais.",, .t.)
	endif
	_nPos = ascan (_aCabec, {|_aVal| alltrim(upper(_aVal [1])) == 'F1_SERIE'})
	if _nPos > 0
		_sSerie = _aCabec [_nPos, 2]
	else
		u_help("Nao encontrei o campo F1_SERIE na array de dados para geracao da nota. Impossivel buscar dados adicionais.",, .t.)
	endif

	// Preenche dados adicionais do produto. Procurar manter consistencia com
	// gatilhos que seriam usados na digitacao manual das notas.
	_nPosProd = ascan(_aLinha, {|_aVal| alltrim(upper(_aVal [1])) == 'D1_COD'})
	if _nPosProd > 0
		_sProduto = PadR(_aLinha[_nPosProd, 2], TamSX3('B1_COD')[1])
		SB1->(dbSetOrder(1))
		If SB1->(MsSeek(xFilial('SB1') + _sProduto))
			AADD(_aLinha, {"D1_DESCRI", sb1 -> b1_desc,  Nil})
			AADD(_aLinha, {"D1_CONTA",  sb1 -> b1_conta, Nil})
		else
			U_help("Nao achei o produto '" + _sProduto + "' no cadastro. Impossivel buscar dados adicionais.",, .t.)
		endif
	else
		U_help("Nao encontrei o campo D1_COD na array de dados para geracao do item da nota. Impossivel buscar dados adicionais.",, .t.)
	EndIf

	// Quando o item nao controla rastro, o importador nao faz a leitura de
	// todos os respectivos campos do XML (pois nao pretente usar). Mas nos
	// queremos preencher sempre todos os campos no SD1.
	_LeRastro (@_aLinha, @_aHistCham)

	// // Grava evento temporario para rastreio de eventuais chaves perdidas
	// _oEvento := ClsEvent():new ()
	// if IsInCallStack("WFLAUNCHER")
	// 	_oEvento:Usuario = 'Schedule'  // Para facilitar a identificacao de importacao automatica (schedule)
	// 	_oEvento:Texto   = "Processando XML apos importacao automatica"
	// else
	// 	_oEvento:Texto   = "Reprocessando XML via painel"
	// endif
	// _oEvento:CodEven   = "ZBE001"
	// _oEvento:ChaveNFe  = _sChvNFe
	// _oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
	// _oEvento:NFEntrada = _sDoc
	// _oEvento:SerieEntr = _sSerie
	// _oEvento:Produto   = _sProduto
	// _oEvento:Fornece   = _sFornece
	// _oEvento:LojaFor   = _sLoja
	// _oEvento:DtEvento  = date()
	// _oEvento:HrEvento  = time()
	// _oEvento:GravaNovo('DHM')

	U_Log2('debug', '[' + procname () + ']_aLinha na saida:')
	U_Log2('debug', _aLinha)

	// Deve sempre retornar cabecalho e itens.
	_aRet := {_aCabec,_aLinha}

	U_ML_SRArea(_aAreaAnt)
	U_SalvaAmb(_aAmbAnt)
Return _aRet
//
// --------------------------------------------------------------------------
// Quando o item nao controla rastro, o importador nao faz a leitura de
// todos os respectivos campos do XML (pois nao pretente usar). Mas nos
// queremos preencher sempre todos os campos no SD1.
static function	_LeRastro(_aLinha, _aHistCham)
	local _sXMLOri   := ''
	local _oXMLSEF   := NIL
	local _nItXML    := 0
	local _lContinua := .T.
	local _aLotes    := {}
	local _nLote     := 0
	local _nPosLtFor := 0
	local _nPosDtFab := 0
	local _nPosDtVal := 0

	// Se jah tenho dados da execucao anterior, eh por que estou processando
	// o segundo/terceiro/... item do XML e nao preciso mair ler o XML do arquivo
	if empty(_aHistCham [.HistStatus])
		// U_LogTrb ('ZBE', .f.)
		_sXMLOri = ''
		if FT_FUSE(alltrim(zbe -> zbe_file)) < 0
			u_help("Nao foi possivel abrir o arquivo '" + alltrim(zbe -> zbe_file) + "' para extrair dados adicionais do XML.",, .t.)
			_lContinua = .F.
			_aHistCham [.HistStatus] = "Nao foi possivel encontrar/abrir o arquivo"
		else
			FT_FGOTOP()
			While !FT_FEOF()
				_sXMLOri += FT_FREADLN ()
				FT_FSKIP()
			EndDo
			FT_FUSE()  // Fecha o arquivo
			U_Log2('debug', '[' + procname() + ']_sXMLOri = ' + _sXMLOri)
			if empty(_sXMLOri)
				u_help ("Nao foi possivel ler o arquivo '" + alltrim(zbe -> zbe_file) + "' para extrair dados adicionais do XML.",, .t.)
				_lContinua = .F.
				_aHistCham [.HistStatus] = "Nao foi possivel ler o arquivo"
			else
				_aHistCham [.HistXMLOriginal] = _sXMLOri
				_oXMLSEF := ClsXMLSEF():New()
				_oXMLSEF:LeXML(_sXMLOri)

				if len(_oXMLSEF:Erros) > 0
					u_help("Nao foi possivel interpretar o XML do arquivo '" + alltrim(zbe -> zbe_file) + "' para extrair dados adicionais do XML.", _oXMLSEF:Erros [1], .t.)
					_lContinua = .F.
					_aHistCham [.HistStatus] = "Nao foi possivel interpretar o XML do arquivo"
				else
					if valtype(_oXMLSEF:NFe) != 'O'
						u_help("Objeto retornado a partir da leitura do XML do arquivo '" + alltrim(zbe -> zbe_file) + "' nao representa uma 'NFe'. Nao conseguirei extrair dados adicionais.",, .t.)
						_lContinua = .F.
						_aHistCham [.HistStatus] = "Interpretacao do XML nao retornou em formato de objeto"
					else
						_aHistCham [.HistStatus] = 'OK'
						_aHistCham [.HistObjetoXML] = _oXMLSEF:NFe
					endif
				endif
			endif
		endif
	else
		// Jah tenho prontos da execucao anterior.
		_sXMLOri := _aHistCham [.HistXMLOriginal]
		_oXMLSEF := ClsXMLSEF():New()
		_oXMLSEF:NFe := _aHistCham [.HistObjetoXML]
	endif

	if _aHistCham [1] == 'OK'

		// Nao sei qual dos itens estah sendo processado (o ponto de entrada
		// eh chamado uma vez para cada item do XML, mas nao recebo identificacao
		// nenhuma se trata-se do 1o, 2o, 3o,.... item). Por isso, vou incrementar
		// um contador a cada execucao.
		_nItXML = _aHistCham [.HistUltItemProcessado] + 1
		U_Log2('debug', '[' + procname () + ']Assumindo que estou processando o item ' + cvaltochar(_nItXML) + ' do XML')

		// Trabalho com array por que posso ter mais de um lote no mesmo item (produto) da nota
		_aLotes = _oXMLSEF:NFe:ItRastro [_nItXML]
		U_Log2('debug', '[' + procname() + ']Para este item, constam ' + cvaltochar(len(_aLotes)) + ' lotes no XML')
		U_Log2('debug', _aLotes)

		for _nLote = 1 to len (_aLotes)
			U_Log2('debug', '[' + procname() + '] _nLote ' + cvaltochar(_nLote) + ' Lote :' + cvaltochar(_aLotes [_nLote][1]))
			U_Log2('debug', '[' + procname() + '] _nLote ' + cvaltochar(_nLote) + ' Quant:' + cvaltochar(_aLotes [_nLote][2]))
			U_Log2('debug', '[' + procname() + '] _nLote ' + cvaltochar(_nLote) + ' DtFab:' + cvaltochar(_aLotes [_nLote][3]))
			U_Log2('debug', '[' + procname() + '] _nLote ' + cvaltochar(_nLote) + ' DtVal:' + cvaltochar(_aLotes [_nLote][4]))
		next

		// Se encontrei dados de rastreabilidade no XML, quero usar. Senao,
		// quero deixar os campos vazios.
		// Este trecho NAO TEM TRATAMENTO PARA XML COM MAIS DE UM LOTE DO
		// MESMO ITEM NO XML. ESTOU PEGANDO SEMPRE DO PRIMEIRO LOTE. Isso por
		// que o programa do importador jah teria que abrir mais linhas.
		_nPosLtFor = ascan(_aLinha, {|_aVal| alltrim(_aVal [1]) == 'D1_LOTEFOR'})
		if _nPosLtFor == 0
			AADD(_aLinha, {"D1_LOTEFOR", ctod(''), Nil})
			_nPosLtFor = len(_aLinha)
		endif
		if len(_aLotes) >= 1
			_aLinha [_nPosLtFor, 2] = _aLotes [1][1]
		else
			_aLinha [_nPosLtFor, 2] = ''
		endif

		_nPosDtFab = ascan(_aLinha, {|_aVal| alltrim(_aVal [1]) == 'D1_DFABRIC'})
		if _nPosDtFab == 0
			AADD(_aLinha, {"D1_DFABRIC", ctod(''), Nil})
			_nPosDtFab = len(_aLinha)
		endif
		if len (_aLotes) >= 1
			_aLinha [_nPosDtFab, 2] = stod(strtran(_aLotes [1][3], '-', ''))
		else
			_aLinha [_nPosDtFab, 2] = ctod('')
		endif

		_nPosDtVal = ascan(_aLinha, {|_aVal| alltrim(_aVal [1]) == 'D1_DTVALID'})
		if _nPosDtVal == 0
			U_Log2('debug', '[' + procname() + ']Ainda nao tem o campo D1_DTVALID na array')
			AADD(_aLinha, {"D1_DTVALID", ctod(''), Nil})
			_nPosDtVal = len(_aLinha)
		endif
		if len(_aLotes) >= 1
			_aLinha [_nPosDtVal, 2] = stod(strtran(_aLotes [1][4], '-', ''))
		else
			_aLinha [_nPosDtVal, 2] = ctod('')
		endif

	endif

	_aHistCham [.HistUltItemProcessado] ++
return
//
/*	Abaixo codigo que recebi como exemplo. Robert, 20/07/2022
User Function PETRS006()
	Local aRet	    := {}
	Local aArea		:= GetArea()
	Local _aTRS006	:= PARAMIXB
	Local _aCabec	:= _aTRS006[3]
	Local _aLinha	:= _aTRS006[4]
	Local lManut	:= _aTRS006[5]
	Local lEscrit	:= _aTRS006[6]
	Local nPosQtd	:= 0
	Local nPosQtSeg := 0
	Local _nPosProd 	:= 0
	// 	Local cLog 		:= ''
	Local nN 		:= 1
	// Local nPosForn	:= aScan(_aCabec,{|x| x[1] == "F1_FORNECE"})
	// Local nPosLoja	:= aScan(_aCabec,{|x| x[1] == "F1_LOJA"})

	ConOut('PETRS006')
	// Alimenta o Log
	// For nN := 1 To Len(_aCabec)
	// cLog += cValToChar(_aCabec[nN, 1]) +  ': ' + cValToChar(_aCabec[nN, 2]) + ' | '
	// Next

	If aScan(_aLinha,{|x| x[1] == "D1_QUANT"}) > 0 
		nPosQtd	:= aScan(_aLinha,{|x| x[1] == "D1_QUANT"})
	EndIf

	If aScan(_aLinha,{|x| x[1] == "D1_QTSEGUM"}) > 0 
		nPosQtSeg := aScan(_aLinha,{|x| x[1] == "D1_QTSEGUM"})
	EndIf

	If aScan(_aLinha,{|x| x[1] == "D1_COD"}) > 0 
		_nPosProd := aScan(_aLinha,{|x| x[1] == "D1_COD"})
	EndIf

	// Alert(xFilial('SB1') + PadR(_aLinha[_nPosProd, 2], TamSX3('B1_COD')[1]))
	SB1->(dbSetOrder(1))
	If SB1->(MsSeek(xFilial('SB1') + PadR(_aLinha[_nPosProd, 2], TamSX3('B1_COD')[1])))
		// cLog := ''
		// Alert('Found')
		If nPosQtSeg > 0
			If SB1->B1_TIPCONV == 'M'
				AADD(aLinha, {"D1_QUANT", _aLinha[nPosQtSeg, 2] / SB1->B1_CONV, Nil})
			Else
				AADD(aLinha, {"D1_QUANT", _aLinha[nPosQtSeg, 2] * SB1->B1_CONV, Nil})
			EndIf
		Else
			If SB1->B1_TIPCONV == 'M'
				AADD(aLinha, {"D1_QTSEGUM", _aLinha[nPosQtd, 2] * SB1->B1_CONV, Nil})
			Else
				AADD(aLinha, {"D1_QTSEGUM", _aLinha[nPosQtd, 2] / SB1->B1_CONV, Nil})
			EndIf
		EndIf

		AADD(_aLinha, {"D1_UM"		,SB1->B1_UM 	,Nil})
		If !Empty(AllTrim(SB1->B1_SEGUM))
			AADD(_aLinha, {"D1_SEGUM"	,SB1->B1_SEGUM 	,Nil})
		EndIf

		AADD(_aLinha, {"D1_TDESCPR"	,SB1->B1_DESC 	,Nil})
		If lEscrit
			AADD(_aLinha, {"D1_DESCRI"	,_aTRS006[1] 	,Nil}) // PRENTISS
		Else
			AADD(_aLinha, {"D1_DESCRI"	,SB1->B1_DESC 	,Nil}) // FARINA - PRENTISS
		EndIf
		AADD(_aLinha, {"D1_RDESCR "	,SB1->B1_DESC 	,Nil}) // RUGERI

		If lManut 
			AADD(_aLinha, {"D1_ZDESCRI"	,_aTRS006[1] 	,Nil}) // NUTRITEC	
		Else
			AADD(_aLinha, {"D1_ZDESCRI"	,SB1->B1_DESC 	,Nil}) // NUTRITEC	
		EndIf	
		AADD(_aLinha, {"D1_CONTA"	,SB1->B1_CONTA 	,Nil})
		AADD(_aLinha, {"D1_SNCM"	,SB1->B1_POSIPI	,Nil})
		AADD(_aLinha, {"D1_CC"		,SB1->B1_CC 	,Nil})
		AADD(_aLinha, {"D1_LOCAL"	,SB1->B1_LOCPAD ,Nil})
		AADD(_aLinha, {"D1_ITEMCTA"	,"" 			,Nil})

		// cLog += 'Encontrou SB1'
	Else
		// cLog += 'Não encontrou SB1'
	EndIf

//	SB6->(dbSetOrder(1))
//	If (SB6->(MsSeek(xFilial('SB6') + PadR(_aLinha[_nPosProd, 2], TamSX3('B1_COD')[1]) + PadR(_acabec[nPosForn, 2], TamSX3('B6_CLIFOR')[1]) + PadR(_acabec[nPosLoja, 2], TamSX3('B6_LOJA')[1]))))
//	SF4->(dbSetOrder(1))
//	If SF4->(MsSeek(xFilial('SF4') + SB6->B6_TES))
//	AADD(_aLinha, {"D1_TES", SF4->F4_TESDV, Nil})	 	
//	EndIf
//	EndIf

	aRet := {_aCabec,_aLinha}
Return aRet
*/
