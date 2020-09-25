* Programa..: ML_PEMB.PRX
* Autor.....: Leandro
* Data......: 18:00 Pm Ago 08,1999
* Nota......: Relatorio Posicao de Embarque

// Historico de alteracoes:
// 16/12/2009 - Robert - Nao usava a serie da nota na leitura do SD2 e pegava notas antigas junto.
//                     - Perguntas ajustadas para versao 10.
// 27/09/2010 - Robert - Criada opcao de retornar dados para outro programa.
// 06/11/2012 - Robert - Ajustes para novo tamanho do numero de nota fiscal.
// 19/12/2012 - Elaine - Ajustes pois mudou o indice do dbsetorder da tabela SF2, agora está sendo
//                       tratado pelo nickname - devido ao problema que nao estava aparecendo informacoes na listagem
// 04/06/2013 - Robert - Se usuario for representante, obriga a parametrizar para seu codigo de representante.
// 31/03/2016 - Robert - Migrado para TReport
//                     - Removida opcao de 'analitico'
//                     - Criadas colunas de valor mercadoria / devolucao / bonificacao para ficar igual ao 'Analise de saidas'
// 04/08/2016 - Robert - Nao gravava o parametro 04.
//

// --------------------------------------------------------------------------
User Function ML_pemb (_lRetDados)
	private cPerg   :="ML_PEM"
	private _sArqLog := iif (type ('_sArqLog') == 'C', _sArqLog, U_NomeLog ())

	u_logId ()
	_ValidPerg ()
	pergunte (cPerg, .F.)

	// Este relatorio gera dados para envio diario para representantes.
	_lRetDados := iif (_lRetDados == NIL, .F., _lRetDados)
	if _lRetDados
		return _LeDados ()
	else
		If TRepInUse()
			if Pergunte (cPerg, .T.)
				_oRep := ReportDef()
				_oRep:PrintDialog()
			endif
		else
			u_help ("Relatorio disponivel apenas na opcao 'personalizavel'.")
		EndIf
	endif
Return



// -------------------------------------------------------------------------
Static Function ReportDef ()
	Local _oRep   := NIL
	Local _oSec1  := NIL
	Local _oSec2  := NIL
	Local cTitulo := "Relatorio de posicao de embarque" 
	local _sCodRep  := ''    

	// Se o usuario atual for um representante, busca seu codigo.
	sa3 -> (DbGoTop())
	   Do WHile ! sa3 -> (eof())
	      If ALLTRIM(sa3 -> A3_CODUSR) == ALLTRIM(UPPER(__cUserID))
		     _sCodRep := sa3 -> A3_COD
			 EXIT
		  ENDIF
		  sa3 -> (DbSkip ())
	   EndDo

    // Caso seja um representante, restringe os parametros apenas para seu codigo.
    if !empty(_sCodRep)
    	U_GravaSX1 (cPerg, '03', _sCodRep) 
    	U_GravaSX1 (cPerg, '04', _sCodRep)
    	mv_par03 = _sCodRep
    	mv_par04 = _sCodRep
    endif

	_oRep := TReport():New (cPerg, cTitulo, cPerg, {|_oRep| PrintReport (_oRep)}, cTitulo)
	_oRep:SetLandScape()
	_oRep:SetTotalInLine(.F.)
	_oRep:nfontbody := 8

	// secao 1 (quebra principal)
	_oSec1 := TRSection():New (_oRep, "Vendedor", {"Vendedor"}, , .F., .T.)
	TRCell():New(_oSec1, "Vendedor", "", "Vendedor",         "",                   6,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "NomeVend", "", "Nome vendedor",    "",                  50,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	_oSec1:SetPageBreak(.F.)  // Quebra pagina no final da secao.

	_oSec2 := TRSection():New (_oRep, "Geral", {"Geral"}, , .F., .F.)
//	_oSec2 := TRSection():New (_oRep, "Geral", {"Geral"})
	_oSec2:SetTotalInLine(.F.)
	TRCell():New(_oSec2, "Emissao",  "", "Emissao",          "@D",                10,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "NomeCli",  "", "Nome cliente",     "",                  45,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "Doc",      "", "NF",               "",                   9,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "Pedido",   "", "Pedido",           "",                   6,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "DescCond", "", "Cond.pagto",       "",                  15,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "NomeTra",  "", "Nome transp",      "",                  15,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "TpFrete",  "", "Tp.frt",           "",                   3,/*lPixel*/,{|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(_oSec2, "ValMerc",  "", "Valor mercadoria", "@E 999,999,999.99", 14,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec2, "ValDevol", "", "Valor devolucao",  "@E 999,999,999.99", 14,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec2, "ValBonif", "", "Valor bonific",    "@E 999,999,999.99", 14,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)

	// Totalizacao na secao principal
	oBreak := TRBreak():New(_oSec1, _oSec1:Cell("Vendedor"),"Totais vendedor")
	_oTrf := TRFunction():New(_oSec2:Cell("ValMerc")	,,"SUM"	,oBreak,"Totais vendedor",       "@E 9,999,999,999.99",NIL, .T., .T.)
	_oTrf := TRFunction():New(_oSec2:Cell("ValDevol")	,,"SUM"	,oBreak,"Totais vendedor",       "@E 9,999,999,999.99",NIL, .T., .T.)
	_oTrf := TRFunction():New(_oSec2:Cell("ValBonif")	,,"SUM"	,oBreak,"Totais vendedor",       "@E 9,999,999,999.99",NIL, .T., .T.)
	_oTrf:SetEndSection (.F.)  // Nao totaliza na quebra de secao.
Return _oRep



// ---------------------------------------------------------------------------
Static Function PrintReport (_lRetDados)
	local cArqTra := ""
	local _sVend  := ""
	local _oSec1 := _oRep:Section(1)
	local _oSec2 := _oRep:Section(2)

	cArqTra = _Ledados ()

	(cArqTra) -> (dbgotop ())
	do while ! (cArqTra) -> (eof ())

		//imprimo a primeira seção
		_oSec1:Init()
		_oSec1:Cell ("Vendedor"):SetValue ( (cArqTra) -> vend)
		_oSec1:Cell ("NomeVend"):SetValue ( (cArqTra) -> nomevend)
		_oSec1:Printline()
		_oRep:SkipLine()
		_oRep:ThinLine()

		// Controla quebra por vendedor
		_oSec2:Init()
		_sVend = (cArqTra) -> vend
		do while ! (cArqTra) -> (eof ()) .and. (cArqTra) -> vend == _sVend

			_oRep:IncMeter ()
			If _oRep:Cancel()
				u_help ("Operacao cancelada pelo usuario.")
				Exit
			End

			// Carrega dados para o objeto de impressao.
			_oSec2:Cell("Emissao"):SetBlock  ({|| stod ((cArqTra) -> emissao)})
			_oSec2:Cell("NomeCli"):SetBlock  ({|| (cArqTra) -> nomecli})
			_oSec2:Cell("Doc"):SetBlock      ({|| (cArqTra) -> doc})
			_oSec2:Cell("Pedido"):SetBlock   ({|| (cArqTra) -> pedido})
			_oSec2:Cell("DescCond"):SetBlock ({|| (cArqTra) -> Desccond})
			_oSec2:Cell("NomeTra"):SetBlock  ({|| (cArqTra) -> nometra})
			_oSec2:Cell("TpFrete"):SetBlock  ({|| (cArqTra) -> tpfrete})
			_oSec2:Cell("ValMerc"):SetBlock  ({|| (cArqTra) -> valmerc})
			_oSec2:Cell("ValDevol"):SetBlock ({|| (cArqTra) -> valdevol})
			_oSec2:Cell("ValBonif"):SetBlock ({|| (cArqTra) -> valbonif})
			_oSec2:PrintLine ()
	
			(cArqTra) -> (dbskip ())
		enddo
	enddo
	(cArqTra) -> (dbclosearea ())
	_oSec2:Finish()
	_oSec1:Finish()
return



// ---------------------------------------------------------------------------
// Gera arquivo de trabalho que serve tanto para impressao como para retorno de dados para outras funcoes.
static function _LeDados ()
	local _oSQL    := NIL
	local cArqTra  := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "WITH C AS ("
	_oSQL:_sQuery += " SELECT 'SD2' AS ORIGEM, F2_VEND1, F2_EMISSAO, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_COND, F2_TRANSP,"
	_oSQL:_sQuery +=        " F2_TPFRETE, F4_MARGEM, D2_PEDIDO, D2_TIPO, ROUND(SUM(D2_PRCVEN*D2_QUANT), 2) AS VALMERC"
  	_oSQL:_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_oSQL:_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
  	_oSQL:_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_oSQL:_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
  	_oSQL:_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE)"
	_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4"
	_oSQL:_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "              AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
  	_oSQL:_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)"
  	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "   AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
    _oSQL:_sQuery += "   AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery += "   AND SF2.F2_VEND1     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery += " GROUP BY F2_VEND1, F2_EMISSAO, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_COND, F2_TRANSP, F2_TPFRETE, F4_MARGEM, D2_PEDIDO, D2_TIPO"
    _oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT 'SD1' AS ORIGEM, A1_VEND, D1_DTDIGIT, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, '' AS F1_COND, '' AS F1_TRANSP,"
	_oSQL:_sQuery +=        " '' AS F2_TPFRETE, F4_MARGEM, '' AS D2_PEDIDO, D1_TIPO AS D2_TIPO, SUM (D1_TOTAL) AS VALMERC"
    _oSQL:_sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_oSQL:_sQuery += "	 INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_oSQL:_sQuery += "   	    ON (SF1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "		    AND SF1.F1_FILIAL  = SD1.D1_FILIAL"				
	_oSQL:_sQuery += "		    AND SF1.F1_DOC     = SD1.D1_DOC"				
	_oSQL:_sQuery += "		    AND SF1.F1_SERIE   = SD1.D1_SERIE"				
	_oSQL:_sQuery += "		    AND SF1.F1_FORNECE = SD1.D1_FORNECE"				
	_oSQL:_sQuery += "   		AND SF1.F1_LOJA    = SD1.D1_LOJA"	
	_oSQL:_sQuery += "          AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"	
	_oSQL:_sQuery += "     INNER JOIN " + RetSQLName ("SF4") + " AS SF4"			
	_oSQL:_sQuery += "		ON (SF4.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "          AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery += "			AND SF4.F4_CODIGO  = SD1.D1_TES"
	_oSQL:_sQuery += "			AND SF4.F4_MARGEM  = '2')"
	_oSQL:_sQuery += "     INNER JOIN " + RetSQLName ("SA1") + " AS SA1"			
	_oSQL:_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "          AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery += "			AND SA1.A1_COD  = SD1.D1_FORNECE"
	_oSQL:_sQuery += "          AND SA1.A1_VEND   BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _oSQL:_sQuery += "			AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "   AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
    _oSQL:_sQuery += "   AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery += "   AND SD1.D1_TIPO = 'D'"
	_oSQL:_sQuery += " GROUP BY A1_VEND, D1_DTDIGIT, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F4_MARGEM, D1_TIPO"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT C.F2_VEND1 AS VEND,"
	_oSQL:_sQuery +=        " ISNULL (SA3.A3_NOME, '') AS NOMEVEND,"
	_oSQL:_sQuery +=        " C.F2_EMISSAO AS EMISSAO,"
	_oSQL:_sQuery +=        " CASE WHEN ORIGEM = 'SD2' THEN "
	_oSQL:_sQuery +=             " CASE WHEN D2_TIPO IN ('B', 'D') THEN SA2.A2_NOME ELSE SA1.A1_NOME END"
	_oSQL:_sQuery +=        " ELSE"
	_oSQL:_sQuery +=             " CASE WHEN D2_TIPO IN ('B', 'D') THEN SA1.A1_NOME ELSE SA2.A2_NOME END"
	_oSQL:_sQuery +=        " END AS NOMECLI,"
	_oSQL:_sQuery +=        " C.F2_DOC AS DOC,"
	_oSQL:_sQuery +=        " C.D2_PEDIDO AS PEDIDO,"
	_oSQL:_sQuery +=        " ISNULL (SE4.E4_DESCRI, '') AS DESCCOND,"
	_oSQL:_sQuery +=        " CASE WHEN ORIGEM = 'SD2' THEN SA4.A4_NOME ELSE '' END AS NOMETRA,"
	_oSQL:_sQuery +=        " CASE C.F2_TPFRETE WHEN 'C' THEN 'CIF' WHEN 'F' THEN 'FOB' ELSE C.F2_TPFRETE END AS TPFRETE,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN C.F4_MARGEM = '1' THEN C.VALMERC ELSE 0 END) AS VALMERC,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN C.F4_MARGEM = '2' THEN C.VALMERC ELSE 0 END) AS VALDEVOL,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN C.F4_MARGEM = '3' THEN C.VALMERC ELSE 0 END) AS VALBONIF"
	_oSQL:_sQuery +=  " FROM C"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA1") + " AS SA1"			
	_oSQL:_sQuery +=        " ON (SA1.D_E_L_E_T_ = ''"				
    _oSQL:_sQuery +=        " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=        " AND SA1.A1_COD     = C.F2_CLIENTE"
	_oSQL:_sQuery +=        " AND SA1.A1_LOJA    = C.F2_LOJA)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA2") + " AS SA2"			
	_oSQL:_sQuery +=        " ON (SA2.D_E_L_E_T_ = ''"				
    _oSQL:_sQuery +=        " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=        " AND SA2.A2_COD     = C.F2_CLIENTE"
	_oSQL:_sQuery +=        " AND SA2.A2_LOJA    = C.F2_LOJA)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA3") + " AS SA3"			
	_oSQL:_sQuery +=        " ON (SA3.D_E_L_E_T_ = ''"				
    _oSQL:_sQuery +=        " AND SA3.A3_FILIAL  = '" + xfilial ("SA3") + "'"
	_oSQL:_sQuery +=        " AND SA3.A3_COD     = C.F2_VEND1)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SA4") + " AS SA4"			
	_oSQL:_sQuery +=        " ON (SA4.D_E_L_E_T_ = ''"				
    _oSQL:_sQuery +=        " AND SA4.A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery +=        " AND SA4.A4_COD     = C.F2_TRANSP)"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("SE4") + " AS SE4"			
	_oSQL:_sQuery +=        " ON (SE4.D_E_L_E_T_ = ''"				
    _oSQL:_sQuery +=        " AND SE4.E4_FILIAL  = '" + xfilial ("SE4") + "'"
	_oSQL:_sQuery +=        " AND SE4.E4_CODIGO  = C.F2_COND)"
	_oSQL:_sQuery += " GROUP BY C.F2_VEND1, C.F2_EMISSAO, C.ORIGEM, C.F2_DOC, C.D2_PEDIDO, C.F2_TPFRETE, A3_NOME, A4_NOME, D2_TIPO, A2_NOME, A1_NOME, E4_DESCRI"
	_oSQL:_sQuery += " ORDER BY C.F2_VEND1, C.F2_EMISSAO, C.F2_DOC"
    _oSQL:Log ()
    //_oSQL:SetField ('EMISSAO', 'D')
    cArqTra = _oSQL:Qry2Trb (.F.)
return cArqTra



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes          Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "   ", {},             "Data inicial NF"})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "   ", {},             "Data final NF"})
	aadd (_aRegsPerg, {03, "Vendedor inicial              ", "C", 6,  0,  "",   "SA3", {},             "Codigo vendedor inicial"})
	aadd (_aRegsPerg, {04, "Vendedor final                ", "C", 6,  0,  "",   "SA3", {},             "Codigo vendedor final"})
//	aadd (_aRegsPerg, {05, "Tipo                          ", "N", 1,  0,  "",   "   ", {"Analitico", "Sintetico"}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
