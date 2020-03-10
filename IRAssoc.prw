// Programa:   IRAssoc
// Autor:      Robert Koch
// Data:       27/02/2012
// Descricao:  Impressao de dados para declaracao de IR de associados
// 
// Historico de alteracoes:
// 15/08/2012 - Robert - Passa a agrupar todos os codigos/lojas usando o codigo e loja base do associado.
//                     - Passa a buscar historico de safra usando codigo e loja base do associado.
//                     - Passa a buscar capital social usando codigo e loja base do associado.
//                     - Passa a buscar CPF, RG, etc. usando codigo e loja base do associado.
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
// 01/04/2016 - Robert - Desabilitado metodo HistSafr da classe ClsAssoc. Passa a ler direto na query principal.
// 11/04/2017 - Robert - Passa a ler historico do plano de saudo direto do SZI e nao mais do metodo ExtratoCC().
// 30/05/2017 - Robert - Criado movimento 29 (Unimed Jacinto), que precisa mesmo tratamento do 01 (plano saude).
// 17/04/2019 - Robert - Tratamento para buscar somente as parcelas de pagto.safra com vcto.no ano base (GLPI 5727).
//

#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function IRAssoc (_lAutomat)
	local _aRet     := {}
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)  // Uso sem interface com o usuario.

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	// Variaveis obrigatorias dos programas de relatorio
	Titulo   := "Relatorio para fins de IR"
	cDesc1   := Titulo
	cDesc2   := ""
	cDesc3   := ""
	cString  := "SA2"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	nLastKey := 0
	cPerg    := "IRASSOC"
	nomeprog := "IRASSOC"
	wnrel    := "IRASSOC"
	tamanho  := "P"
	limite   := 80
	nTipo    := 18
	m_pag    := 1
	li       := 80
	cCabec1  := ""
 	cCabec2  := ""
	aOrd     := {}
	
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
//		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F., aOrd)
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString, ;  // Alias
		wnrel, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg, ;  // Parametros
		@titulo, ;  // Titulo do relatorio
		cDesc1, ;  // Descricao 1
		cDesc2, ;  // Descricao 2
		cDesc3, ;  // Descricao 3
		.F., ;  // .T. = usa dicionario
		aOrd, ;  // Array de ordenacoes para o usuario selecionar
		.T., ;  // .T. = comprimido
		tamanho, ;  // P/M/G
		NIL, ;  // Nao pude descobrir para que serve.
		.F., ;  // .T. = usa filtro
		NIL, ;  // lCrystal
		NIL, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T., ;  // .T. = NAO mostra interface para usuario
		.T., ;  // lServer
		NIL)    // cPortToPrint
	endif
	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	processa ({|| _Imprime ()})
	MS_FLUSH ()
	DbCommitAll ()

	// Se era execucao via rotina automatica, converte o relatorio para TXT.
	if _lAuto
		_sErroConv = U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
		if ! empty (_sErroConv)
			u_help (_sErroConv)
		endif
	else
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
return _aRet



// --------------------------------------------------------------------------
static function _Imprime ()
	local _nMaxLin   := 60
	local _oSQL      := NIL
	local _aAssoc    := {}
	local _nAssoc    := 0
	local _aExtrat   := {}
	local _nExtrat   := 0
	local _nTotDesp  := 0
	local _nTotSafra := 0
	local _oCtaCOrr  := NIL //ClsCtaCorr():New ()
	local _nVlrSaude := 0
	local _nRendProd := 0
	local _sAliasQ   := ''
	local _sCodLoja  := ''
	local _nCodLoja	 := 0

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	

	li = _nMaxLin + 1
	procregua (3)

	// Para que seja considerado associado, deve ter pelo menos algum movimento no SZI, em qualquer filial.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT A2_COD, A2_LOJA "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_CGC BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COD     = SA2.A2_VACBASE"  // Busca sempre os dados do codigo/loja base do associado.
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = SA2.A2_VALBASE"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT * "
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                 " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                   " AND SZI.ZI_LOJASSO = SA2.A2_LOJA)"
//	_oSQL:_sQuery +=  " GROUP BY A2_COD, A2_LOJA"
	_oSQL:_sQuery +=  " ORDER BY A2_COD, A2_LOJA"
	//_oSQL:Log ()
	_aAssoc = aclone (_oSQL:Qry2Array())

	procregua (len (_aAssoc))

	sa2 -> (dbsetorder (1))
	for _nAssoc = 1 to len (_aAssoc)
		incproc ()
		sa2 -> (dbseek (xfilial ("SA2") + _aAssoc [_nAssoc, 1] + _aAssoc [_nAssoc, 2], .F.))
		_oAssoc := ClsAssoc():New (sa2 -> a2_cod, sa2 -> a2_loja)
		if valtype (_oAssoc) != "O"
			sa2 -> (dbskip ())
			loop
		endif
		incproc (sa2 -> a2_nome)
		
		// Quebra pagina por associado.
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)

		// Lista dados cadastrais
		@ li, 0 psay 'Codigo/loja.....: ' + _oAssoc:CodBase + '/' + _oAssoc:LojaBase + ' - ' + _oAssoc:Nome
		li ++
		@ li, 0 psay 'Data nascimento.: ' + dtoc (sa2 -> a2_vaDtNas) + '      Data falecimento...: ' + dtoc (sa2 -> a2_vaDtFal)
		li ++
		@ li, 0 psay 'Data filiacao...: ' + dtoc (_oAssoc:DtEntrada (dDataBase)) + '      Data desligamento..: ' + dtoc (_oAssoc:DtSaida (dDataBase))
		li ++
		@ li, 0 psay 'Documentos......: CPF..............: ' + transform (_oAssoc:CPF, "@R 999.999.999-99")
		li ++
		@ li, 0 psay '                  RG...............: ' + _oAssoc:RG
		li ++
		@ li, 0 psay '                  Inscr.estadual...: ' + _Array2TXT (_oAssoc:aInscrEst, ',')
		li ++
		@ li, 0 psay 'Endereco........: ' + U_TamFixo (alltrim (sa2 -> a2_end) + ' - bairro ' + alltrim (sa2 -> a2_bairro), 62)
		li ++
		@ li, 0 psay '                  ' + U_TamFixo (alltrim (sa2 -> a2_mun) + ' - ' + sa2 -> a2_est + '   CEP: ' + transform (sa2 -> a2_cep, "@R 99.999-999"), 62)
		li ++
		@ li, 0 psay 'Contato.........: ' + alltrim (sa2 -> a2_tel) + ' / ' + alltrim (sa2 -> a2_vaCelul)
		li ++
		@ li, 0 psay __PrtThinLine ()
		li += 2

		// Busca despesas com plano de saude.
		_nTotDesp = 0

		// Busca movimentos de plano de saude
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ZI_DATA, ZI_HISTOR, ZI_VALOR, R_E_C_N_O_ "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC   = '" + _oAssoc:Codigo + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO = '" + _oAssoc:Loja + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM      IN ('01', '29')"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA    BETWEEN '" + mv_par03 + '0101' + "' AND '" + mv_par03 + '1231' + "'"
		_oSQL:_sQuery += " ORDER BY ZI_DATA"
		//_oSQL:Log ()
		_aExtrat := aclone (_oSQL:Qry2Array (.F., .F.))
		
		for _nExtrat = 1 to len (_aExtrat)
			_oCtaCorr = ClsCtaCorr():New (_aExtrat [_nExtrat, 4])
			_nVlrSaude = _aExtrat [_nExtrat, 3] - _oCtaCorr:SaldoEm (stod (mv_par03 + '1231'))
			if _nVlrSaude > 0  
				if li > _nMaxLin - 2
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif

				@ li, 0  psay stod (_aExtrat [_nExtrat, 1])
				@ li, 12 psay U_TamFixo (_aExtrat [_nExtrat, 2], 57)
				@ li, 70 psay transform (_nVlrSaude, "@E 999,999.99")
				li ++
				_nTotDesp += _nVlrSaude //_aExtrat [_nExtrat, 3]
			endif
		next
		if _nTotDesp != 0
			@ li, 70 psay '----------'
			li ++
		endif
		@ li, 25 psay 'TOTAL DE DESPESAS MEDICAS EM ' + MV_PAR03 + ': ' + transform (_nTotDesp, "@E 999,999,999.99")
		li += 2
		@ li, 0 psay __PrtThinLine ()
		li += 2
		@ li, 25 psay 'SALDO QUOTA CAPITAL EM 31/12/' + mv_par03 + ': ' + transform (_oAssoc:SldQuotCap (stod (mv_par03 + '1231')) [.QtCapSaldoNaData], "@E 999,999,999.99")
		li += 2
		@ li, 0 psay __PrtThinLine ()
		li += 2

		// A partir de 2018 o parcelamento foi em 11 vezes, fazendo com que a ultima parcela seja paga no ano seguinte.
		// Para fins de IR devo listar o valor efetivamente pago e nao os direitos gerados pela nota de compra.
		_nRendProd = 0
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		if mv_par03 < '2018'
			_oSQL:_sQuery += " SELECT SUM (V.VALOR_TOTAL) "
			_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
			_oSQL:_sQuery +=  " WHERE V.SAFRA         = '" + MV_PAR03 + "'"
			_oSQL:_sQuery +=    " AND V.CODBASEASSOC  = '" + _oAssoc:CodBase + "'"
			_oSQL:_sQuery +=    " AND V.LOJABASEASSOC = '" + _oAssoc:LojaBase + "'"
			_oSQL:_sQuery +=    " AND V.TIPO_NF IN ('C', 'V')"
			_nRendProd = _oSQL:RetQry (1, .F.)
		else

			// Monta lista de codigos e lojas do associado (pode ter mais de uma loja) para uso na query, pois preciso
			// listar neste relatorio o total de rendimentos dele, em qualquer das suas lojas.
			//u_log ('aCodigos:', _oAssoc:aCodigos)
			if len (_oAssoc:aCodigos) > 0
				_sCodLoja = ''
				for _nCodLoja = 1 to len (_oAssoc:aCodigos)
					_sCodLoja += _oAssoc:aCodigos [_nCodLoja] + _oAssoc:aLojas [_nCodLoja] + iif (_nCodLoja < len (_oAssoc:aCodigos), '/', '')
				next
			else
				_sCodLoja = _oAssoc:Codigo + _oAssoc:Loja
			endif
			//u_log (_sCodLoja)

			_oSQL:_sQuery += " SELECT E2_FILIAL, E2_NUM, E2_PARCELA, E2_EMISSAO, E2_VENCREA, E2_VALOR "
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "

//			_oSQL:_sQuery +=   " FROM (SELECT DISTINCT FILIAL, DOC, SERIE, ASSOCIADO, LOJA_ASSOC"  // Usa distinct por que pode ter mais de 1 variedade na mesma nota.
//			_oSQL:_sQuery +=           " FROM VA_VNOTAS_SAFRA V "
//			_oSQL:_sQuery +=          " WHERE V.SAFRA         between '" + Tira1 (MV_PAR03) + "' AND '" + mv_par03 + "'" // Para pegar possiveis parcelas do ano anterior que foram pagas esta ano.
//			_oSQL:_sQuery +=            " AND V.CODBASEASSOC  = '" + _oAssoc:CodBase + "'"
//			_oSQL:_sQuery +=            " AND V.LOJABASEASSOC = '" + _oAssoc:LojaBase + "'"
//			_oSQL:_sQuery +=            " AND V.TIPO_NF IN ('C', 'V')) AS V,"
//			_oSQL:_sQuery +=          RetSQLName ("SE2") + " SE2 "

			_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '01'"  // Pagamento de safra sempre fica concentrado na matriz.
			_oSQL:_sQuery +=    " AND SE2.E2_TIPO    = 'FAT'"  // Pagamentos ficam aglutinados em faturas
			_oSQL:_sQuery +=    " AND SE2.E2_FATURA  = 'NOTFAT'"  // Evita que seja lida alguma 'fatura que virou fatura'
			_oSQL:_sQuery +=    " AND SE2.E2_VENCREA between '" + mv_par03 + "0101' AND '" + mv_par03 + "1231'"
			_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
			_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
			_oSQL:_sQuery +=                 " WHERE ZI_FILIAL  = SE2.E2_FILIAL""
			_oSQL:_sQuery +=                   " AND ZI_ASSOC   = SE2.E2_FORNECE"
			_oSQL:_sQuery +=                   " AND ZI_LOJASSO = SE2.E2_LOJA"
			_oSQL:_sQuery +=                   " AND ZI_DOC     = SE2.E2_NUM"
			_oSQL:_sQuery +=                   " AND ZI_SERIE   = SE2.E2_PREFIXO"
			_oSQL:_sQuery +=                   " AND ZI_PARCELA = SE2.E2_PARCELA"
			_oSQL:_sQuery +=                   " AND ZI_DATA    between '" + Tira1 (mv_par03) + "0101' AND '" + mv_par03 + "1231'" // Para pegar possiveis parcelas do ano anterior que foram pagas este ano.
			_oSQL:_sQuery +=                   " AND ZI_TM      = '13')"
			_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + E2_LOJA IN " + FormatIn (_sCodLoja, '/')
			//_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb (.T.)
			(_sAliasQ) -> (dbgotop ())
			if mv_par05 == 1  // Detalhar rendimentos de producao
				@ li, 16 psay 'Filial   Titulo       Emissao     Vencto             Valor'
				li ++
			endif
			do while ! (_sAliasQ) -> (eof ())
				if mv_par05 == 1  // Detalhar rendimentos de producao
					if li > _nMaxLin - 1
						cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
					endif
					@ li, 16 psay (_sAliasQ) -> e2_filial + '       ' + (_sAliasQ) -> e2_num + '-' + (_sAliasQ) -> e2_parcela + '  ' + dtoc ((_sAliasQ) -> e2_emissao) + '  ' + dtoc ((_sAliasQ) -> e2_vencrea) + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99")
					li ++
				endif
				_nRendProd += (_sAliasQ) -> e2_valor
				(_sAliasQ) -> (dbskip ())
			enddo
		endif

		if mv_par03 == '2019'
			u_help ('Para este ano verificar se deve somar aos rendimentos de producao o adto.de distribuicao de sobras gerado em 28/02/2019')
			_nRendProd = 0
		endif

		@ li, 12 psay 'TOTAL RENDIMENTOS PRODUCAO RECEBIDOS EM ' + mv_par03 + ':   ' + transform (_nRendProd, "@E 999,999,999.99")
		li += 2
	next

	// Imprime parametros usados na geracao do relatorio
	li ++
	if li > _nMaxLin - 5
		cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
	endif
	U_ImpParam (_nMaxLin)
return



// --------------------------------------------------------------------------
// Formata para impressao.
static function _Array2TXT (_aArray, _sSeparad)
	local _sRet := ""
	local _i    := 0
	for _i = 1 to len (_aArray)
		_sRet += alltrim (_aArray [_i]) + iif (_i < len (_aArray), _sSeparad, '')
	next
return _sRet



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
static function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes Help
	aadd (_aRegsPerg, {01, "CPF inicial                   ", "C", 14, 0,  "",   "SA2_CP", {},   ""})
	aadd (_aRegsPerg, {02, "CPF final                     ", "C", 14, 0,  "",   "SA2_CP", {},   ""})
	aadd (_aRegsPerg, {03, "Ano base                      ", "C", 4,  0,  "",   "      ", {},   ""})
	aadd (_aRegsPerg, {04, "Movtos.pl.saude(separ.por /)  ", "C", 60, 0,  "",   "      ", {},   ""})
	aadd (_aRegsPerg, {05, "Detalhar rendim.producao?     ", "N", 1,  0,  "",   "      ", {'Sim', 'Nao'},   ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
