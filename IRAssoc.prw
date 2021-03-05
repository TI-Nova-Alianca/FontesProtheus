// Programa:   IRAssoc
// Autor:      Robert Koch
// Data:       27/02/2012
// Descricao:  Impressao de dados para declaracao de IR de associados
// 
// Historico de alteracoes:
// 15/08/2012 - Robert  - Passa a agrupar todos os codigos/lojas usando o codigo e loja base do associado.
//                      - Passa a buscar historico de safra usando codigo e loja base do associado.
//                      - Passa a buscar capital social usando codigo e loja base do associado.
//                      - Passa a buscar CPF, RG, etc. usando codigo e loja base do associado.
// 21/03/2016 - Robert  - Valida se o usuario pertence ao grupo 059.
// 01/04/2016 - Robert  - Desabilitado metodo HistSafr da classe ClsAssoc. Passa a ler direto na query principal.
// 11/04/2017 - Robert  - Passa a ler historico do plano de saudo direto do SZI e nao mais do metodo ExtratoCC().
// 30/05/2017 - Robert  - Criado movimento 29 (Unimed Jacinto), que precisa mesmo tratamento do 01 (plano saude).
// 17/04/2019 - Robert  - Tratamento para buscar somente as parcelas de pagto.safra com vcto.no ano base (GLPI 5727).
// 10/03/2020 - Robert  - Linha inserida apenas para testar branches no Git
// 12/03/2020 - Robert  - Ajustes / alinhamentos layout de impressao.
//                      - Tratamento adto sobras pago em 2019 (GLPI 7614)
// 13/03/2020 - Claudia - Criado parametros de associado e nucleo. GLPI 7660
// 03/03/2021 - Robert  - Separados trechos de leitura de rendimentos de producao, por safra (GLPI 9535)
//

// -----------------------------------------------------------------------------------------------------------
#include "VA_Inclu.prw"

User function IRAssoc (_lAutomat)
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
//		_sErroConv = U_ML_R2T (__reldir + wnrel + ".##r", __reldir + wnrel + ".txt")
//		if ! empty (_sErroConv)
//			u_help (_sErroConv)
//		endif
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
//	local _nTotSafra := 0
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

	Titulo += " - ano base " + mv_par03
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
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO BETWEEN '" + mv_par04 + mv_par05 + "' AND '" + mv_par06 + mv_par07 + "'"
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                   " AND SZI.ZI_LOJASSO = SA2.A2_LOJA)"
	_oSQL:_sQuery +=  " ORDER BY A2_NOME, A2_COD, A2_LOJA"
	_oSQL:Log ()
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
		
		// se informou o Nucleo filtra por nucleo
		if mv_par08 != '  '
			_oAssoc := ClsAssoc ():New (sa2 -> a2_cod, sa2 -> a2_loja)
			if valtype (_oAssoc) != 'O' .or. _oAssoc:Nucleo != mv_par08
				sa2 -> (dbskip ())
				loop
			endif
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
				@ li, 12 psay U_TamFixo (_aExtrat [_nExtrat, 2], 51)
				@ li, 64 psay transform (_nVlrSaude, "@E 999,999.99")
				li ++
				_nTotDesp += _nVlrSaude //_aExtrat [_nExtrat, 3]
			endif
		next
		if _nTotDesp != 0
			@ li, 64 psay '----------'
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

		elseif mv_par03 $ '2018/2019'

			_oSQL:_sQuery += " SELECT E2_FILIAL, E2_NUM, E2_PARCELA, E2_EMISSAO, E2_VENCREA, E2_VALOR"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
			_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '01'"  // Pagamento de safra sempre fica concentrado na matriz.
			_oSQL:_sQuery +=    " AND SE2.E2_TIPO    = 'FAT'"  // Pagamentos ficam aglutinados em faturas
			_oSQL:_sQuery +=    " AND SE2.E2_FATURA  = 'NOTFAT'"  // Evita que seja lida alguma 'fatura que virou fatura'
			_oSQL:_sQuery +=    " AND SE2.E2_VENCREA between '" + mv_par03 + "0101' AND '" + mv_par03 + "1231'"
			_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + E2_LOJA IN " + FormatIn (_sCodLoja, '/')
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

			// Para este ano deve somar o adto.de distribuicao de sobras gerado em 28/02/2019
			if mv_par03 == '2019'
				_oSQL:_sQuery += " UNION ALL"
				_oSQL:_sQuery += " SELECT E2_FILIAL, E2_NUM, E2_PARCELA, E2_EMISSAO, E2_VENCREA, E2_VALOR"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
				_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '01'"  // Pagamento de safra sempre fica concentrado na matriz.
				_oSQL:_sQuery +=    " AND SE2.E2_TIPO    = 'DP'"  // Pagamentos ficam aglutinados em faturas
				_oSQL:_sQuery +=    " AND SE2.E2_VENCREA between '" + mv_par03 + "0101' AND '" + mv_par03 + "1231'"
				_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + E2_LOJA IN " + FormatIn (_sCodLoja, '/')
				_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
				_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
				_oSQL:_sQuery +=                 " WHERE ZI_FILIAL  = SE2.E2_FILIAL""
				_oSQL:_sQuery +=                   " AND ZI_ASSOC   = SE2.E2_FORNECE"
				_oSQL:_sQuery +=                   " AND ZI_LOJASSO = SE2.E2_LOJA"
				_oSQL:_sQuery +=                   " AND ZI_DOC     = SE2.E2_NUM"
				_oSQL:_sQuery +=                   " AND ZI_SERIE   = SE2.E2_PREFIXO"
				_oSQL:_sQuery +=                   " AND ZI_PARCELA = SE2.E2_PARCELA"
				_oSQL:_sQuery +=                   " AND ZI_DATA    between '" + Tira1 (mv_par03) + "0101' AND '" + mv_par03 + "1231'" // Para pegar possiveis parcelas do ano anterior que foram pagas este ano.
				_oSQL:_sQuery +=                   " AND ZI_TM      = '30')"
				_oSQL:_sQuery +=  " ORDER BY E2_VENCREA, E2_FILIAL, E2_NUM, E2_PARCELA"
			endif

		elseif mv_par03 $ '2020/2021'

			_oSQL:_sQuery += " WITH C AS ("
			_oSQL:_sQuery += " SELECT E2_FILIAL, E2_NUM, E2_PARCELA, E2_EMISSAO, E2_VENCREA, "

			// Existem casos em que nem todo o valor do titulo foi usado na geracao de uma fatura.
			// Por exemplo quando parte foi compensada e apenas o saldo restante virou fatura.
			// Ex.: título 000021485/30 -D do fornecedor 000643. Foi compensado R$ 3.066,09 e o saldo (R$ 1028,71) foi gerada a fatura 202000051.
			// Devo descontar do valor do titulo somente a parte que foi consumida na geracao da fatura.
			_oSQL:_sQuery += " E2_VALOR - ISNULL ((SELECT SUM (FK2_VALOR)"
			_oSQL:_sQuery +=                       " FROM " + RetSQLName ("FK7") + " FK7, "
			_oSQL:_sQuery +=                                  RetSQLName ("FK2") + " FK2 "
			_oSQL:_sQuery +=                            " WHERE FK7.D_E_L_E_T_ = '' AND FK7.FK7_FILIAL = SE2.E2_FILIAL AND FK7.FK7_ALIAS = 'SE2' AND FK7.FK7_CHAVE = SE2.E2_FILIAL + '|' + SE2.E2_PREFIXO + '|' + SE2.E2_NUM + '|' + SE2.E2_PARCELA + '|' + SE2.E2_TIPO + '|' + SE2.E2_FORNECE + '|' + SE2.E2_LOJA"
			_oSQL:_sQuery +=                              " AND FK2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                              " AND FK2.FK2_FILIAL = FK7.FK7_FILIAL"
			_oSQL:_sQuery +=                              " AND FK2.FK2_IDDOC  = FK7.FK7_IDDOC"
			_oSQL:_sQuery +=                              " AND FK2.FK2_MOTBX  = 'FAT'"
			_oSQL:_sQuery +=                              " AND FK2.FK2_TPDOC != 'ES'"  // ES=Movimento de estorno
			_oSQL:_sQuery +=                              " AND dbo.VA_FESTORNADO_FK2 (FK2.FK2_FILIAL, FK2.FK2_IDFK2) = 0"
			_oSQL:_sQuery +=                        "), 0) AS E2_VALOR "
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2 "
			_oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND E2_FILIAL  = '01'"  // Pagamentos sao feitos sempre pela matriz.
			_oSQL:_sQuery +=   " AND E2_PREFIXO in ('30 ', '31 ')"  // Serie usada para notas e faturas de safra
			_oSQL:_sQuery +=   " AND E2_TIPO IN ('NF', 'DP', 'FAT')"  // NF quando compra original da matriz; DP quando saldo transferido de outra filial; FAT quando agrupados em uma fatura.
			_oSQL:_sQuery +=   " AND E2_EMISSAO between '" + Tira1 (mv_par03) + "0101' AND '" + mv_par03 + "1231'" // Para pegar possiveis parcelas do ano anterior que foram pagas este ano.
			_oSQL:_sQuery +=   " AND SE2.E2_VENCREA between '" + mv_par03 + "0101' AND '" + mv_par03 + "1231'"
			_oSQL:_sQuery +=   " AND SE2.E2_FORNECE + E2_LOJA IN " + FormatIn (_sCodLoja, '/')
			_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
			_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SZI") + " SZI "
			_oSQL:_sQuery +=                " WHERE ZI_FILIAL  = SE2.E2_FILIAL""
			_oSQL:_sQuery +=                  " AND ZI_ASSOC   = SE2.E2_FORNECE"
			_oSQL:_sQuery +=                  " AND ZI_LOJASSO = SE2.E2_LOJA"
			_oSQL:_sQuery +=                  " AND ZI_DOC     = SE2.E2_NUM"
			_oSQL:_sQuery +=                  " AND ZI_SERIE   = SE2.E2_PREFIXO"
			_oSQL:_sQuery +=                  " AND ZI_PARCELA = SE2.E2_PARCELA"
			_oSQL:_sQuery +=                  " AND ZI_TM      = '13')"
			_oSQL:_sQuery +=   ")"
			_oSQL:_sQuery += " SELECT *"
			_oSQL:_sQuery +=   " FROM C"
			_oSQL:_sQuery +=  " WHERE E2_VALOR != 0"  // Os que estao zerados eh por que foram totalmente consumidos em uma fatura.

			// Somar o premio de qualidade referente a safra 2020, mas que foi pago em fev/2021.
			if mv_par03 == '2021'
				_oSQL:_sQuery += " UNION ALL"
				_oSQL:_sQuery += " SELECT E2_FILIAL, E2_NUM, E2_PARCELA, E2_EMISSAO, E2_VENCREA, E2_VALOR"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2 "
				_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '01'"
				_oSQL:_sQuery +=    " AND SE2.E2_TIPO    = 'DP'"
				_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO = 'OUT'"  // 
				_oSQL:_sQuery +=    " AND SE2.E2_VENCREA between '" + mv_par03 + "0101' AND '" + mv_par03 + "1231'"
				_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + E2_LOJA IN " + FormatIn (_sCodLoja, '/')
				_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
				_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
				_oSQL:_sQuery +=                 " WHERE ZI_FILIAL  = SE2.E2_FILIAL""
				_oSQL:_sQuery +=                   " AND ZI_ASSOC   = SE2.E2_FORNECE"
				_oSQL:_sQuery +=                   " AND ZI_LOJASSO = SE2.E2_LOJA"
				_oSQL:_sQuery +=                   " AND ZI_DOC     = SE2.E2_NUM"
				_oSQL:_sQuery +=                   " AND ZI_SERIE   = SE2.E2_PREFIXO"
				_oSQL:_sQuery +=                   " AND ZI_PARCELA = SE2.E2_PARCELA"
				_oSQL:_sQuery +=                   " AND ZI_DATA    = SE2.E2_EMISSAO"
				_oSQL:_sQuery +=                   " AND ZI_TM      = '16')"
			endif

			_oSQL:_sQuery +=  " ORDER BY E2_VENCREA, E2_FILIAL, E2_NUM, E2_PARCELA"

		else
			u_help ("Sem definicao de tratamento para leitura dos rendimentos de producao para a safra '" + mv_par03 + "'. Solicite manutencao do programa.",, .t.)
			_oSQL:_sQuery = " SELECT '' as E2_FILIAL, '' as E2_NUM, '' as E2_PARCELA, '' as E2_EMISSAO, '' as E2_VENCREA, 0 as E2_VALOR"
		endif
		_oSQL:Log ()

		// A partir de 2019 passou a listar os titulos do financeiro
		if mv_par03 >= '2018'
			_sAliasQ = _oSQL:Qry2Trb (.T.)
			(_sAliasQ) -> (dbgotop ())
			@ li, 16 psay 'Filial   Titulo       Emissao     Vencto             Valor'
			li ++
			do while ! (_sAliasQ) -> (eof ())
				if li > _nMaxLin - 1
					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
				endif
				@ li, 16 psay (_sAliasQ) -> e2_filial + '       ' + (_sAliasQ) -> e2_num + '-' + (_sAliasQ) -> e2_parcela + '  ' + dtoc ((_sAliasQ) -> e2_emissao) + '  ' + dtoc ((_sAliasQ) -> e2_vencrea) + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99")
				li ++
				_nRendProd += (_sAliasQ) -> e2_valor
				(_sAliasQ) -> (dbskip ())
			enddo
		endif

		if _nRendProd != 0
			@ li, 64 psay '----------'
			li ++
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
	aadd (_aRegsPerg, {04, "Associado inicial             ", "C", 6,  0,  "",   "SA2_AS", {},   ""})
	aadd (_aRegsPerg, {05, "Loja associado inicial        ", "C", 2,  0,  "",   "      ", {},   ""})
	aadd (_aRegsPerg, {06, "Associado final               ", "C", 6,  0,  "",   "SA2_AS", {},   ""})
	aadd (_aRegsPerg, {07, "Loja associado final          ", "C", 2,  0,  "",   "      ", {},   ""})
	aadd (_aRegsPerg, {08, "Nucleo                        ", "C", 2,  0,  "",   "   "   , {},   ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
