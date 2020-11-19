// Programa:  VA_GiroE
// Autor:     Robert Koch
// Data:      02/03/2016
// Descricao: Relatorio de giro de estoques.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_GiroE ()
	Local _oRep
	private cPerg    := "VA_GIROE"
	private _sArqLog := U_NomeLog ()

	If TRepInUse()
		_ValidPerg ()
		if Pergunte (cPerg, .T.)
			_oRep := ReportDef()
			_oRep:PrintDialog()
		endif
	else
		u_help ("Relatorio disponivel apenas na opcao 'personalizavel'.")
	EndIf
Return



// -------------------------------------------------------------------------
Static Function ReportDef ()
	Local _oRep   := NIL
	Local _oSec1  := NIL
	Local cTitulo := "Giro de estoque entre " + dtoc (mv_par01) + ' e ' + dtoc (mv_par02) 

	_oRep := TReport():New(cPerg,cTitulo,cPerg,{|_oRep| PrintReport(_oRep)},cTitulo)
	_oRep:SetLandScape()
	_oRep:SetTotalInLine(.F.)
	_oRep:nfontbody := 8

	// secao 1 (quebra principal)
	_oSec1 := TRSection():New (_oRep, "Filial", {"SM0"}, , .F., .T.)
	_oSec1:SetPageBreak(.T.)  // Quebra pagina no final da secao.
	TRCell():New(_oSec1, "M0_CODFIL", "", "Filial",             "@!",              6,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "M0_FILIAL", "", "Nome",               "@!",             12,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "B1_TIPO",   "", "Tipo",	   	 		/*Picture*/    ,  02,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "B1_COD",    "", "Codigo",     		/*Picture*/    ,  15,/*lPixel*/,{|| },"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "B1_DESC",   "", "Descricao produto", 	/*Picture*/    ,  60,/*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "B1_UM",     "", "U.M.",				/*Picture*/    ,  2, /*lPixel*/,{||	},"LEFT",,,,,,,,.T.)
	TRCell():New(_oSec1, "SALDOINI",  "", "Saldo inicial",		"@E 9,999,999.99",12,/*lPixel*/,{|| },"RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec1, "SALDOFIM",  "", "Saldo final",		"@E 9,999,999.99",12,/*lPixel*/,{|| },"RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec1, "ESTQMEDIO", "", "Estq medio",			"@E 9,999,999.99",12,/*lPixel*/,{|| },"RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec1, "VENDA",     "", "Venda periodo",		"@E 9,999,999.99",12,/*lPixel*/,{|| },"RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec1, "GIRO",      "", "Giro",				"@E 999.99"      ,12,/*lPixel*/,{|| },"RIGHT",,,,,,,,.T.)
Return _oRep



// -------------------------------------------------------------------------
Static Function PrintReport(_oRep)
	local _oSec1    := _oRep:Section(1)
	local _oSQL     := NIL
	local _sAliasQ  := ""
	local _nEstqMed := 0
	local _nGiro    := 0
	//local _oFont10 := TFont():New("Arial",,11,,.f.,,,,,.f.)

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT B1_TIPO, B1_COD, B1_DESC, B1_UM"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xFilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_oSQL:_sQuery += " ORDER BY SB1.B1_COD"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	_oRep:SetMeter ((_sAliasQ) -> (reccount ()))
	_oSec1:Init()
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (EOF())
		_oRep:IncMeter()

		If _oRep:Cancel()
			u_help ("Operacao cancelada pelo usuario.")
			Exit
		End

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT dbo.VA_SALDOESTQ ('" + cFilAnt + "', '" + (_sAliasQ) -> b1_cod + "', '" + mv_par05 + "', '" + dtos (mv_par01) + "'), "
		_oSQL:_sQuery +=        " dbo.VA_SALDOESTQ ('" + cFilAnt + "', '" + (_sAliasQ) -> b1_cod + "', '" + mv_par05 + "', '" + dtos (mv_par02) + "'), "
		_oSQL:_sQuery +=        " (SELECT SUM (D2_QUANT)"
		_oSQL:_sQuery +=           " FROM " + RetSQLName ("SD2") + " SD2 "
		_oSQL:_sQuery +=             " INNER JOIN " + RetSQLName ("SF4") + " SF4 "
		_oSQL:_sQuery +=                 " ON (SF4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                 " AND SF4.F4_MARGEM  = '1'"
		_oSQL:_sQuery +=                 " AND SF4.F4_ESTOQUE = 'S'"
		_oSQL:_sQuery +=                 " AND SF4.F4_CODIGO  = SD2.D2_TES)"
		_oSQL:_sQuery +=          " WHERE SD2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=            " AND SD2.D2_FILIAL  = '" + xFilial ("SD2") + "'"
		_oSQL:_sQuery +=            " AND SD2.D2_COD     = '" + (_sAliasQ) -> b1_cod + "'"
		_oSQL:_sQuery +=            " AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
   		_oSQL:_sQuery +=        " )"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		//u_log (_aDados)

		if mv_par06 == 3 ;
			.or. ;
			(mv_par06 == 1 .and. (_aDados [1, 1] != 0 .or. _aDados [1, 3] != 0 .or. _aDados [1, 3] != 0)) ;
			.or. ;
			(mv_par06 == 2 .and. _aDados [1, 1] == 0 .and. _aDados [1, 3] == 0 .and. _aDados [1, 3] == 0)

			_nEstqMed = (_aDados [1, 1] + _aDados [1, 2]) / 2
			_nGiro = _aDados [1, 3] / _nEstqMed

			_oSec1:Cell("M0_CODFIL"):SetBlock ({|| cFilAnt})
			_oSec1:Cell("M0_FILIAL"):SetBlock ({|| sm0 -> m0_filial})
			_oSec1:Cell("B1_TIPO"):SetBlock   ({|| (_sAliasQ) -> b1_tipo})
			_oSec1:Cell("B1_COD"):SetBlock    ({|| (_sAliasQ) -> b1_cod})
			_oSec1:Cell("B1_DESC"):SetBlock   ({|| (_sAliasQ) -> b1_desc})
			_oSec1:Cell("B1_UM"):SetBlock     ({|| (_sAliasQ) -> b1_um})
			_oSec1:Cell("SALDOINI"):SetBlock  ({|| _aDados [1, 1]})
			_oSec1:Cell("SALDOFIM"):SetBlock  ({|| _aDados [1, 2]})
			_oSec1:Cell("ESTQMEDIO"):SetBlock ({|| _nEstqMed})
			_oSec1:Cell("VENDA"):SetBlock     ({|| _aDados [1, 3]})
//			_oSec1:Cell("GIRO"):SetBlock      ({|| _aDados [1, 1] / ((_aDados [1, 1] + _aDados [1, 2]) / 2)})
			_oSec1:Cell("GIRO"):SetBlock      ({|| _nGiro})
			_oSec1:PrintLine ()
		endif

		(_sAliasQ) -> (dbSkip())
	enddo
	(_sAliasQ) -> (DbcloseArea ())

	_oSec1:Finish()
	
Return



// -------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                           Help
	aadd (_aRegsPerg, {01, "Data inicial periodo          ", "D", 08, 0,  "",   "   ", {},                                              ""})
	aadd (_aRegsPerg, {02, "Data final periodo            ", "D", 08, 0,  "",   "   ", {},                                              ""})
	aadd (_aRegsPerg, {03, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                                              ""})
	aadd (_aRegsPerg, {04, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                                              ""})
	aadd (_aRegsPerg, {05, "Almoxarifado/local            ", "C", 2,  0,  "",   "NNR", {},                                              ""})
	aadd (_aRegsPerg, {06, "Quais itens                   ", "C", 2,  0,  "",   "   ", {'Com saldo/movto', 'Sem saldo/movto', 'Todos'}, ""})
	aadd (_aRegsPerg, {07, "Tipo produto inicial          ", "C",  2, 0,  "",   "02 ", {},                                              ""})
	aadd (_aRegsPerg, {08, "Tipo produto final            ", "C",  2, 0,  "",   "02 ", {},                                              ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
