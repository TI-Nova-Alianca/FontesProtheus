// Programa:  VA_COP
// Autor:     Robert Koch
// Data:      28/02/2019
// Descricao: Relatorio de consumos em OP.
//            Criado inicialmente para ajudar a evidenciar sulfitacoes no processo do asseptico. 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de consumos em OP.  Criado inicialmente para ajudar a evidenciar sulfitacoes no processo do asseptico.
// #PalavasChave      #consumo #OP
// #TabelasPrincipais #VA_VDADOS_OP #SB1 #SBM 
// #Modulos 		  #PCP 
//
// Historico de alteracoes:
// 15/09/2020 - Cláudia - Incluido novos campos e alterada o retorno da query para array. GLPI: 8484
//
// --------------------------------------------------------------------------------------------------
User Function VA_COP ()
	Local _oRep      := NIL
	private cPerg    := "VA_COP"
	private _sArqLog := U_NomeLog ()

	If TRepInUse()
		_ValidPerg ()
		Pergunte (cPerg, .F.)
		if Pergunte (cPerg, .T.)
			_oRep := ReportDef()
			_oRep:PrintDialog()
		endif
	else
		u_help ("Relatorio disponivel apenas na opcao 'personalizavel'.")
	EndIf
Return
// -------------------------------------------------------------------------
// Declaração dos campos
Static Function ReportDef ()
	Local _oRep   := NIL
	Local _oSec1  := NIL

	_oRep := TReport():New(cPerg, 'Consumos de itens em OP entre ' + dtoc (mv_par01) + ' e ' + dtoc (mv_par02),cPerg,{|_oRep| PrintReport(_oRep)}, 'Consumos de itens em OP')
	_oRep:SetLandscape ()
	_oRep:SetTotalInLine (.F.)
	_oRep:nfontbody := 8

	_oSec1 := TRSection():New (_oRep, "Geral", {"Geral"}, , .F., .T.)
	TRCell():New(_oSec1, "FILIAL",      "", "Fil",              '',                   2,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "EMISSAO",     "", "Emissao",          "",                  12,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	if mv_par14 == 2
		TRCell():New(_oSec1, "OP",          "", "O.P.",             '',                  14,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	endif
	TRCell():New(_oSec1, "CODIGO",      "", "Componente",       "",                  15,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "DESCRICAO",   "", "Descricao",        "",                  40,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "TIPO", 		"", "Tipo"	, 			"",                   6,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "QUANT",       "", "Quantidade",       "@E 999,999,999.99", 15,/*lPixel*/,{|| }, "RIGHT",,,,,,,, .T.)
	TRCell():New(_oSec1, "UM",          "", "UM",               "",                   2,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	if mv_par14 == 2
		TRCell():New(_oSec1, "ALMOX",       "", "ALM",              "",                   2,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	endif
	TRCell():New(_oSec1, "CUSTO",       "", "Valor",            "@E 999,999,999.99", 16,/*lPixel*/,{|| }, "RIGHT",,,,,,,, .T.)
	TRCell():New(_oSec1, "PROD_FINAL",  "", "Produto da OP",    "",                  15,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "DESCR_FINAL", "", "Descr.prod.final", "",                  35,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "GRUPO", 		"", "Grupo", 			"",                  10,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "DESCR_GRUPO", "", "Descr.grupo", 		"",                  30,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	
	_oSec2 := TRSection():New (_oRep, "Totais por UM consumida", {"TotUM"}, , .F., .T.)
	TRCell():New(_oSec2, "UM",         "", "Unid.medida",     '',                       2,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "QTCONSUMO",  "", "Qt.consumida",    '@E 999,999,999,999.99', 20,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec2, "VLCONSUMO",  "", "Vl.consumido",    '@E 999,999,999,999.99', 20,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)
Return _oRep
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport (_oRep)
	local _oSec1     := _oRep:Section(1)
	local _oSec2     := _oRep:Section(2)
	local _lContinua := .T.
	local _aFiliais  := {}
	local _sAliasQ   := ""
	local _nFilial   := 0
	local _sFiliais  := ''
	local _aTotUM    := {}
	local _nTotUM    := 0
	local _nTGQt     := 0
	local _nTGVl     := 0

	_oSec1:Init()

	// Define filiais a serem lidas.
	if _lContinua
		if mv_par03 == 1  // Apenas filial atual
			_sFiliais = cFilAnt
		else
			_aFiliais = U_LeSM0 ('6', cEmpAnt, '', '')
			u_log (_aFiliais)
			if len (_aFiliais) == 0
				_lContinua = .F.
			else
				_sFiliais = ''
				for _nFilial = 1 to len (_aFiliais)
					_sFiliais += alltrim (_aFiliais [_nFilial, 3]) + iif (_nFilial < len (_aFiliais), '/', '')
				next
			endif
		endif
	endif

	// Gera dados para tabela CGM (socios da empresa para SPED) com base nos dados de associados.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " WITH C AS ("
		_oSQL:_sQuery += " SELECT " 
		_oSQL:_sQuery += " 		FILIAL" 			
		_oSQL:_sQuery += " 	   ,DATA"				
		_oSQL:_sQuery += " 	   ,OP"					
		_oSQL:_sQuery += " 	   ,TIPO_MOVTO"			
		_oSQL:_sQuery += " 	   ,CODIGO"				
		_oSQL:_sQuery += " 	   ,DESCRICAO"			
		_oSQL:_sQuery += " 	   ,QUANT_REAL"			
		_oSQL:_sQuery += " 	   ,CUSTO"				
		_oSQL:_sQuery += " 	   ,UN_MEDIDA"			
		_oSQL:_sQuery += " 	   ,LOCAL AS ALMOX"			
		_oSQL:_sQuery += " 	   ,PROD_FINAL"			
		_oSQL:_sQuery += " 	   ,DESC_PROD_FINAL"	
		_oSQL:_sQuery += " 	   ,SB1CONS.B1_TIPO AS TIPO"	
		_oSQL:_sQuery += " 	   ,SB1PROD.B1_GRUPO AS GRUPO"	
		_oSQL:_sQuery += " 	   ,SBM.BM_DESC AS DESC_GRUPO" 		
		_oSQL:_sQuery += " FROM VA_VDADOS_OP"
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1CONS "
		_oSQL:_sQuery += " 		ON (SB1CONS.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 		AND SB1CONS.B1_COD = CODIGO)"
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1PROD " 
		_oSQL:_sQuery += " 		ON (SB1PROD.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 		AND SB1PROD.B1_COD = PROD_FINAL)"
		_oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SBM") + " SBM "  
		_oSQL:_sQuery += " 		ON (SBM.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 		AND SBM.BM_GRUPO = SB1PROD.B1_GRUPO)"
		_oSQL:_sQuery += "  WHERE FILIAL IN " + FormatIn (_sFiliais, '/')
		_oSQL:_sQuery += " 		AND DATA   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_oSQL:_sQuery += " 		AND CODIGO BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
		if ! empty (mv_par06)
			_oSQL:_sQuery += " 	AND CODIGO IN " + FormatIn (mv_par06, '/')
		endif
		_oSQL:_sQuery +=   " 	AND GRUPO BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
		_oSQL:_sQuery +=   " 	AND OP    BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		_oSQL:_sQuery +=   " 	AND PROD_FINAL BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
		if ! empty (mv_par13)
			_oSQL:_sQuery += " 	AND PROD_FINAL IN " + FormatIn (mv_par13, '/')
		endif
		_oSQL:_sQuery +=   " 	AND TIPO_MOVTO != 'P'"   // QUERO APENAS OS CONSUMOS E DEVOLUCOES
		
		// Demonstrativo usado em processo do asseptico em 02/2019 precisa ignorar OPs que foram feitas apenas para transferencias entre codigos.
		_oSQL:_sQuery +=   "	AND NOT (FILIAL = '01' AND OP = '08641301001')"  // de 2445 para 2203
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '05872501001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '05934301001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '05936801001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '06186601001')"  // de 2203 para
		_oSQL:_sQuery +=   "	AND NOT (FILIAL = '01' AND OP = '06186701001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '06277901001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '06317401001')"  // de 2203 para
		_oSQL:_sQuery +=   " 	AND NOT (FILIAL = '01' AND OP = '06065101001')"  // de 2203 para

		_oSQL:_sQuery += ")"
		if mv_par14 == 1
			_oSQL:_sQuery += " SELECT FILIAL, SUBSTRING (DATA, 5, 2) + '/' + SUBSTRING (DATA, 1, 4) as DATA, TIPO_MOVTO, CODIGO, DESCRICAO, TIPO, UN_MEDIDA, PROD_FINAL, DESC_PROD_FINAL, "
			_oSQL:_sQuery += " GRUPO ,DESC_GRUPO, SUM (QUANT_REAL) AS QUANT_REAL, SUM (CUSTO) AS CUSTO"
			_oSQL:_sQuery += " 		FROM C"
			_oSQL:_sQuery += " GROUP BY FILIAL, SUBSTRING (DATA, 5, 2) + '/' + SUBSTRING (DATA, 1, 4), TIPO_MOVTO, CODIGO, DESCRICAO, TIPO, UN_MEDIDA, PROD_FINAL, DESC_PROD_FINAL, GRUPO ,DESC_GRUPO "
			_oSQL:_sQuery += " ORDER BY SUBSTRING (DATA, 5, 2) + '/' + SUBSTRING (DATA, 1, 4), FILIAL, TIPO_MOVTO"
		else
			_oSQL:_sQuery += " SELECT * "
			_oSQL:_sQuery += " 		FROM C"
			_oSQL:_sQuery += " ORDER BY DATA, FILIAL, TIPO_MOVTO"
		endif
		_oSQL:Log ()
		_sAliasQ := _oSQL:Qry2Trb ()
		procregua ((_sAliasQ) -> (reccount ()))
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
	
			_oRep:IncMeter ()
			If _oRep:Cancel()
				u_help ("Operacao cancelada pelo usuario.")
				Exit
			End

			// Impressao
			_oSec1:Cell("FILIAL"):SetBlock      ({|| (_sAliasQ) -> filial})
			if mv_par14 == 2
				_oSec1:Cell("EMISSAO"):SetBlock     ({|| stod ((_sAliasQ) -> data)})
				_oSec1:Cell("OP"):SetBlock          ({|| (_sAliasQ) -> op})
				_oSec1:Cell("ALMOX"):SetBlock       ({|| (_sAliasQ) -> almox})
			else
				_oSec1:Cell("EMISSAO"):SetBlock     ({|| (_sAliasQ) -> data})
			endif
			_oSec1:Cell("CODIGO"):SetBlock      ({|| (_sAliasQ) -> codigo})
			_oSec1:Cell("DESCRICAO"):SetBlock   ({|| (_sAliasQ) -> descricao})
			_oSec1:Cell("TIPO"):SetBlock   		({|| (_sAliasQ) -> tipo})
			_oSec1:Cell("QUANT"):SetBlock       ({|| (_sAliasQ) -> quant_real * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)})  // Eventuais devolucoes aparecem negativas
			_oSec1:Cell("UM"):SetBlock          ({|| (_sAliasQ) -> un_medida})
			_oSec1:Cell("CUSTO"):SetBlock       ({|| (_sAliasQ) -> custo * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)})  // Eventuais devolucoes aparecem negativas
			_oSec1:Cell("PROD_FINAL"):SetBlock  ({|| (_sAliasQ) -> prod_final})
			_oSec1:Cell("DESCR_FINAL"):SetBlock ({|| (_sAliasQ) -> desc_prod_final})
			_oSec1:Cell("GRUPO"):SetBlock  		({|| (_sAliasQ) -> grupo})
			_oSec1:Cell("DESCR_GRUPO"):SetBlock ({|| (_sAliasQ) -> desc_grupo})
			_oSec1:PrintLine ()


//			NAO VAI DAR CERTO. TERIA QUE SER POR UM ORIGEM + PRODUTO DESTINO
//			// Acumula na array de totais por produto final
//			_nTotDest = ascan (_aTotDest, {| _aVal| _aVal [1] == (_sAliasQ) -> desc_prod_final})
//			if _nTotDest == 0
//				aadd (_aTotDest, {(_sAliasQ) -> desc_prod_final, 0, 0})
//				_nTotDest = len (_aTotDest)
//			endif
//			_aTotDest [_nTotDest, 2] += (_sAliasQ) -> quant_real * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)
//			_aTotDest [_nTotDest, 3] += (_sAliasQ) -> custo * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)


			// Acumula na array de totais por unidade de medida
			_nTotUM = ascan (_aTotUM, {| _aVal| _aVal [1] == (_sAliasQ) -> un_medida})
			if _nTotUM == 0
				aadd (_aTotUM, {(_sAliasQ) -> un_medida, 0, 0})
				_nTotUM = len (_aTotUM)
			endif
			_aTotUM [_nTotUM, 2] += (_sAliasQ) -> quant_real * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)
			_aTotUM [_nTotUM, 3] += (_sAliasQ) -> custo * iif ((_sAliasQ) -> TIPO_MOVTO == 'D', -1, 1)

			(_sAliasQ) -> (dbskip ())
	 	enddo
		_oSec1:Finish ()


		// Impressao de totais gerais por produto destino
//		asort (_aTotDest,,, {|_x, _y| _x [1] < _y [1]})
//		_oSec2:Init()
//		for _nTotDest = 1 to len (_aTotDest)
//			_oSec2:Cell("UM"):SetBlock ({|| _aTotDest [_nTotDest, 1]})
//			_oSec2:Cell("QTCONSUMO"):SetBlock ({|| _aTotDest [_nTotDest, 2]})
//			_oSec2:Cell("VLCONSUMO"):SetBlock ({|| _aTotDest [_nTotDest, 3]})
//			_oSec2:PrintLine ()
//		next
//		_oSec2:Finish ()


		// Impressao de totais gerais por unidade de medida
		asort (_aTotUM,,, {|_x, _y| _x [1] < _y [1]})
		_nTGQt = 0
		_nTGVl = 0
		_oSec2:Init()
		for _nTotUM = 1 to len (_aTotUM)
			_oSec2:Cell("UM"):SetBlock ({|| _aTotUM [_nTotUM, 1]})
			_oSec2:Cell("QTCONSUMO"):SetBlock ({|| _aTotUM [_nTotUM, 2]})
			_oSec2:Cell("VLCONSUMO"):SetBlock ({|| _aTotUM [_nTotUM, 3]})
			_oSec2:PrintLine ()
			_nTGQt += _aTotUM [_nTotUM, 2]
			_nTGVl += _aTotUM [_nTotUM, 3]
		next
		_oSec2:Cell("UM"):SetBlock ({|| 'Tot.geral'})
		_oSec2:Cell("QTCONSUMO"):SetBlock ({|| _nTGQt})
		_oSec2:Cell("VLCONSUMO"):SetBlock ({|| _nTGVl})
		_oSec2:PrintLine ()
		_oSec2:Finish ()
	endif
Return
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Data de                       ", "D",  8, 0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {02, "Data ate                      ", "D",  8, 0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {03, "Filiais                       ", "N",  1, 0,  "",   "   ", {"Atual", "Selecionar"},   ""})
	aadd (_aRegsPerg, {04, "Produto (consumido) de        ", "C", 15, 0,  "",   "SB1", {},                        ""})
	aadd (_aRegsPerg, {05, "Produto (consumido) ate       ", "C", 15, 0,  "",   "SB1", {},                        ""})
	aadd (_aRegsPerg, {06, "Prd(consum)especif(sep.barras)", "C", 60, 0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {07, "Grupo prod.(consumido) de     ", "C",  4, 0,  "",   "SBM", {},                        ""})
	aadd (_aRegsPerg, {08, "Grupo prod.(consumido) ate    ", "C",  4, 0,  "",   "SBM", {},                        ""})
	aadd (_aRegsPerg, {09, "Ordem producao de             ", "C", 14, 0,  "",   "SC2", {},                        ""})
	aadd (_aRegsPerg, {10, "Ordem producao ate            ", "C", 14, 0,  "",   "SC2", {},                        ""})
	aadd (_aRegsPerg, {11, "Produto final da OP de        ", "C", 15, 0,  "",   "SB1", {},                        ""})
	aadd (_aRegsPerg, {12, "Produto final da OP ate       ", "C", 15, 0,  "",   "SB1", {},                        ""})
	aadd (_aRegsPerg, {13, "Prd(final)especif(sep.barras) ", "C", 60, 0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {14, "Resumido/detalhado            ", "N",  1, 0,  "",   "   ", {"Resumido", "Detalhado"}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
