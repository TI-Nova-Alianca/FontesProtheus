// Programa:  VA_CSoc
// Autor:     Robert Koch
// Data:      15/06/2016
// Descricao: Relatorio de capital social.
//
// Historico de alteracoes:
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
User Function VA_CSoc ()
	Local _oRep      := NIL
	private cPerg    := "VA_CSOC"
	private _sArqLog := U_NomeLog ()

	if ! U_ZZUVL ('059', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

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

	_oRep := TReport():New(cPerg, 'Capital social em ' + dtoc (mv_par01),cPerg,{|_oRep| PrintReport(_oRep)}, 'Capital social em ' + dtoc (mv_par01))
	_oRep:SetPortrait ()
	_oRep:SetTotalInLine (.F.)
	_oRep:nfontbody := 8

	_oSec1 := TRSection():New (_oRep, "Geral", {"Geral"}, , .F., .T.)
	TRCell():New(_oSec1, "CODIGO",   "", "Codigo",     '',                   6,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "LOJA",     "", "Loja",       '',                   2,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "ENTRADA",  "", "Dt.entrada", "@E D",              10,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "SAIDA",    "", "Dt.saida",   "@E D",              10,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "CPF",      "", "CPF/CNPJ",   '',                  18,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "NOME",     "", "Nome",       "",                  40,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "PARTICIP", "", "% particip", "@E 999.9999",        8,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)
	TRCell():New(_oSec1, "CAPITAL",  "", "Capital",    "@E 999,999,999.99", 14,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)

	_oSec2 := TRSection():New (_oRep, "Geral", {"Geral"}, , .F., .T.)
	TRCell():New(_oSec2, "GERAL", "", "Total capital", '@E 999,999,999,999.99', 14,/*lPixel*/,{|| }, "RIGHT",,,,,,,,.T.)

// como fazer um total geral? ainda nao descobri...
//	// Totalizacao na secao principal
//	oBreak := TRBreak():New(_oSec1,_oSec1:Cell("GERAL"),"")
//	_oTrf := TRFunction():New(_oSec1:Cell("CAPITAL"),,"SUM"	,oBreak,"Total geral", "@E 9,999,999,999.99",NIL, .T., .T.)
//	_oTrf:SetEndSection (.F.)  // Nao totaliza na quebra de secao.
Return _oRep



// -------------------------------------------------------------------------
Static Function PrintReport(_oRep)
	local _oSec1    := _oRep:Section(1)
	local _oSec2    := _oRep:Section(2)
	local _oFont10  := TFont():New("Arial",,11,,.f.,,,,,.f.)
	local _sAliasQ  := ""
	local _nSldCap  := 0
	local _nTotCap  := 0
	local _aAssoc   := {}
	local _nAssoc   := 0
	local _oAssoc   := NIL
	local _dDataRef := mv_par01

	_oSec1:Init()

	// Gera dados para tabela CGM (socios da empresa para SPED) com base nos dados de associados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT A2_VACBASE, A2_VALBASE, A2_TIPO" //, ISNULL(dbo.VA_FORMATA_CGC(A2_CGC), '') AS CPF, rtrim (A2_NOME)"
	_oSQL:_sQuery += " FROM SA2010 SA2"
	_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SA2.A2_FILIAL = '  '"
	_oSQL:_sQuery += " AND SA2.A2_COD = SA2.A2_VACBASE"  // PEGA APENAS O CODIGO E LOJA BASE PARA NAO REPETIR O MESMO ASSOCIADO.
	_oSQL:_sQuery += " AND SA2.A2_LOJA = SA2.A2_VALBASE"
	
	//_oSQL:_sQuery += " AND SA2.A2_COD <= '000161'"  // TESTES
	
	_oSQL:_sQuery += " AND EXISTS (SELECT *"
	_oSQL:_sQuery += " FROM SZI010 SZI"
	_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SZI.ZI_ASSOC = SA2.A2_COD"
	_oSQL:_sQuery += " AND SZI.ZI_LOJASSO = SA2.A2_LOJA"
	_oSQL:_sQuery += " AND SZI.ZI_DATA <= '" + dtos (_dDataRef) + "')"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	_nTotCap = 0
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())

		_oRep:IncMeter ()
		If _oRep:Cancel()
			u_help ("Operacao cancelada pelo usuario.")
			Exit
		End

		_oAssoc := ClsAssoc ():New ((_sAliasQ) -> a2_vacbase, (_sAliasQ) -> a2_valbase)
		_nSldCap = _oAssoc:SldQuotCap (_dDataRef) [.QtCapSaldoNaData]
		if mv_par02 == 3 .or. (mv_par02 == 1 .and. _nSldCap != 0) .or. (mv_par02 == 2 .and. _nSldCap == 0)
			aadd (_aAssoc, {_oAssoc:CodBase, ;
			                _oAssoc:LojaBase, ;
			                _oAssoc:Nome, ;
			                transform (_oAssoc:CPF, iif ((_sAliasQ) -> a2_tipo == 'J', "@R 99.999.999/9999-99", "@R 999.999.999-99")), ;
			                _oAssoc:DtEntrada (_dDataRef), ;
			                _oAssoc:DtSaida (_dDataRef), ;
			                _nSldCap, ;
			                0})
			_nTotCap += _nSldCap
		endif
		(_sALiasQ) -> (dbskip ())
 	enddo

	// Calcula percentual de participacao de cada associado.
	for _nAssoc = 1 to len (_aAssoc)
		_aAssoc [_nAssoc, 8] = _aAssoc [_nAssoc, 7] * 100 / _nTotCap
	next
	
	// Ordena por ranking de percentual de participacao
	asort (_aAssoc,,, {|_x, _y| _x [8] > _y [8]})
	u_log (_aAssoc)
	
	// Impressao
	for _nAssoc = 1 to len (_aAssoc)
		_oSec1:Cell("CODIGO"):SetBlock   ({|| _aAssoc [_nAssoc, 1]})
		_oSec1:Cell("LOJA"):SetBlock     ({|| _aAssoc [_nAssoc, 2]})
		_oSec1:Cell("NOME"):SetBlock     ({|| _aAssoc [_nAssoc, 3]})
		_oSec1:Cell("CPF"):SetBlock      ({|| _aAssoc [_nAssoc, 4]})
		_oSec1:Cell("ENTRADA"):SetBlock  ({|| _aAssoc [_nAssoc, 5]})
		_oSec1:Cell("SAIDA"):SetBlock    ({|| _aAssoc [_nAssoc, 6]})
		_oSec1:Cell("CAPITAL"):SetBlock  ({|| _aAssoc [_nAssoc, 7]})
		_oSec1:Cell("PARTICIP"):SetBlock ({|| _aAssoc [_nAssoc, 8]})
		_oSec1:PrintLine ()
	next
	u_log (_aAssoc)
	_oSec1:Finish ()

	_oSec2:Init()
	_oSec2:Cell("GERAL"):SetBlock ({|| _nTotCap})
	_oSec2:PrintLine ()
	_oSec2:Finish ()
Return



// -------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                   Help
	aadd (_aRegsPerg, {01, "Posicao na data de...         ", "D",  8, 0,  "",   "   ", {},                                      ""})
	aadd (_aRegsPerg, {02, "Quais associados?             ", "N",  1, 0,  "",   "   ", {'Com capital', 'Sem capital', 'Todos'}, ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
