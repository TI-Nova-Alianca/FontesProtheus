// Programa:  VA_VEF
// Autor:     Robert Koch
// Data:      19/06/2023
// Descricao: Relatorio saldos de venda para entrega futura (GLPI 13746)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Relatorio saldos de venda para entrega futura
// #PalavasChave      #faturamento #venda_para_entrega_futura
// #TabelasPrincipais #ADA #ADB #SC6 #SD2
// #Modulos           #FAT

// Historico de alteracoes:
//

#include "rptdef.ch"  // Para ter a definicao da variavel IMP_PDF

// --------------------------------------------------------------------------
User Function VA_VEF (_lAuto)
	Local _oRep      := NIL
	private cPerg    := "VA_VEF"

	_ValidPerg ()
	Pergunte (cPerg, .F.)
	_oRep := ReportDef()
	u_logsx1 (cPerg)

	if _lAuto != NIL .and. _lAuto
		_oRep:setFile ('VA_VEF')
		_oRep:nDevice := IMP_PDF
		_oRep:nRemoteType := NO_REMOTE
		_oRep:PrintDialog()
	else
		If TRepInUse()
			_oRep:PrintDialog()
		else
			u_help ("Relatorio disponivel apenas na opcao 'personalizavel'.",, .t.)
		endif
	endif
Return



// -------------------------------------------------------------------------
Static Function ReportDef ()
	local _oRep    := NIL
	local _oSec1   := NIL
	local _sTitulo := ''

	_sTitulo := 'Contratos'
	if mv_par02 == 1
		_sTitulo += ' (em aberto)'
	elseif mv_par02 == 2
		_sTitulo += ' (encerrados)'
	endif
	_sTitulo += ' venda entrega futura'
	_sTitulo += ' - posicao de ' + dtoc (mv_par01)

	_oRep := TReport():New(cPerg, _sTitulo, cPerg,{|_oRep| PrintReport(_oRep)}, _sTitulo)
	_oRep:SetLandscape ()
	_oRep:SetTotalInLine (.F.)

	_oSec1 := TRSection():New (_oRep, "Geral", {"Geral"}, , .F., .T.)
	TRCell():New(_oSec1, "FILIAL",    "", "Filial",      '',                     3,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "CONTRATO",  "", "Contrato",    '',                     9,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "PRODUTO",   "", "Produto",     '',                    45,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "CLIENTE",   "", "Cliente",     '',                    45,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "TIPO_NF",   "", "Tp.NF",       '',                     8,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "NF",        "", "NF",          '',                    10,/*lPixel*/,{|| }, "LEFT",,"CENTER",,,,,, .T.)
	TRCell():New(_oSec1, "EMISSAO",   "", "Emissao",     '',                    10,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "QUANT",     "", "Quant",       '@E 999,999,999.9999', 16,/*lPixel*/,{|| }, "RIGHT",,"RIGHT",,,,,, .T.)
	TRCell():New(_oSec1, "UM",        "", "UM",          '',                     2,/*lPixel*/,{|| }, "LEFT",,,,,,,, .T.)
	TRCell():New(_oSec1, "VALOR_NF",  "", "Valor NF",    '@E 999,999,999.99',   14,/*lPixel*/,{|| }, "RIGHT",,"RIGHT",,,,,, .T.)
	TRCell():New(_oSec1, "CUSMED",    "", "Saldo custo", '@E 999,999,999.99',   14,/*lPixel*/,{|| }, "RIGHT",,"RIGHT",,,,,, .T.)

	_oBrkCtr := TRBreak():New(_oRep,{|| _oSec1:Cell('FILIAL'):uPrint + _oSec1:Cell('CONTRATO'):uPrint},'Saldos contrato',.F.)
	TRFunction():New(_oSec1:Cell('QUANT')   ,, 'SUM',_oBrkCtr ,,,,.F.,.F.,.F., _oSec1)
	TRFunction():New(_oSec1:Cell('VALOR_NF'),, 'SUM',_oBrkCtr ,,,,.F.,.F.,.F., _oSec1)
// nao rolou por que pega o primeiro registro da proxima quebra --->	TRFunction():New(_oSec1:Cell('CUSMED')  ,, 'ONPRINT',_oBrkCtr ,,,,.F.,.F.,.F., _oSec1)


	_oBrkFil := TRBreak():New(_oRep,{|| _oSec1:Cell('FILIAL'):uPrint},'Saldos filial',.F.)
	TRFunction():New(_oSec1:Cell('VALOR_NF'),, 'SUM',_oBrkFil ,,,,.F.,.F.,.F., _oSec1)
// nao rolou por que pega o primeiro registro da proxima quebra --->	TRFunction():New(_oSec1:Cell('CUSMED')  ,, 'ONPRINT',_oBrkFil ,,,,.F.,.F.,.F., _oSec1)

	U_Log2 ('debug', '[' + procname () + ']finalizando')
Return _oRep



// -------------------------------------------------------------------------
Static Function PrintReport(_oRep)
	local _oSec1     := _oRep:Section(1)
	local _lContinua := .T.
	local _nRegAtu   := 0
	local _nUltLin   := 0
	local _nSaldoFim := 0

	_oSec1:Init()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT V.ROW_NUMBER"
	_oSQL:_sQuery +=      ", MAX (ROW_NUMBER) OVER (PARTITION BY FILIAL + CONTRATO + ITEM_CONTR) AS ULT_LIN"
	_oSQL:_sQuery +=      ", V.FILIAL, V.CONTRATO + '/' + V.ITEM_CONTR AS CONTRATO, V.CLIENTE, V.LOJA"
	_oSQL:_sQuery +=      ", CASE V.TIPO_MOVTO WHEN 'F' THEN 'Faturam' WHEN 'R' THEN 'Remessa' ELSE '' END AS TIPO_MOVTO"
	_oSQL:_sQuery +=      ", V.NF, V.EMISSAO_NF, V.QUANT_NF, V.SALDO_QT, V.VALOR_NF"
	_oSQL:_sQuery +=      ", V.PRODUTO, SB1.B1_UM, SB1.B1_DESC, SA1.A1_NOME"
//	_oSQL:_sQuery +=      ", CASE WHEN TIPO_MOVTO = 'F' THEN SALDO_CUSTO ELSE QUANT_NF * ULTIMO_CMED END AS CUSMED"
	_oSQL:_sQuery +=      ", SALDO_CUSTO as SALDO_CUST"
	_oSQL:_sQuery +=      ", ' ' AS SITUACAO"
	_oSQL:_sQuery +=  " FROM VA_VVENDA_ENT_FUTURA V"
	_oSQL:_sQuery +=      "," + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=      "," + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " WHERE V.FILIAL         BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=   " AND V.CLIENTE + LOJA BETWEEN '" + mv_par05 + mv_par06 + "' AND '" + mv_par07 + mv_par08 + "'"
	_oSQL:_sQuery +=   " AND V.PRODUTO        BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_oSQL:_sQuery +=   " AND V.EMISSAO_NF     <=      '" + dtos (mv_par01) + "'"
	_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_   = ''"
	_oSQL:_sQuery +=   " AND SB1.B1_FILIAL    = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=   " AND SB1.B1_COD       = V.PRODUTO"
	_oSQL:_sQuery +=   " AND SA1.D_E_L_E_T_   = ''"
	_oSQL:_sQuery +=   " AND SA1.A1_FILIAL    = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=   " AND SA1.A1_COD       = V.CLIENTE"
	_oSQL:_sQuery +=   " AND SA1.A1_LOJA      = V.LOJA"
	_oSQL:_sQuery += " ORDER BY ROW_NUMBER"
	_oSQL:Log ('[' + procname () + ']')
	_oSQL:Copy2Trb (.F., 4, '_trb', {'ROW_NUMBER'})
	procregua (_trb -> (reccount ()))
	
	// Varre o arquivo de trabalho marcando a situacao de cada contrato.
	// Nao tenho orgulho de dizer... mas nao consegui uma forma de fazer
	// isso pelo SQL sem que ficasse extremamente demorada!
	_trb -> (dbgotop ())
	do while _lContinua .and. ! _trb -> (eof ())
		_nRegAtu = _trb -> (recno ())
		_nUltLin = _trb -> Ult_Lin
		if ! _trb -> (dbseek (_nUltLin, .F.))
			u_help ("Impossivel encontrar a ultima linha do contrato para validar se tem saldo.",, .t.)
			_lContinua = .F.
		else
			_nSaldoFim = _trb -> saldo_qt
		endif
		_trb -> (dbgoto (_nRegAtu))

		if _nSaldoFim > 0
			_trb -> situacao = 'A'  // Aberto
		else
			_trb -> situacao = 'E'  // Encerrado
		endif
		_trb -> (dbskip ())
	enddo


	// Loop de impressao
	_trb -> (dbgotop ())
	do while _lContinua .and. ! _trb -> (eof ())

		_oRep:IncMeter ()
		If _oRep:Cancel()
			u_help ("Operacao cancelada pelo usuario.")
			Exit
		End

		if mv_par02 == 1 .and. _trb -> situacao != 'A'  // Aberto
			_trb -> (dbskip ())
			loop
		endif
		if mv_par02 == 2 .and. _trb -> situacao != 'E'  // Encerrado
			_trb -> (dbskip ())
			loop
		endif

		_oSec1:Cell("FILIAL"):SetBlock    ({|| _trb -> filial})
		_oSec1:Cell("CONTRATO"):SetBlock  ({|| _trb -> contrato})
		_oSec1:Cell("PRODUTO"):SetBlock   ({|| alltrim (_trb -> produto) + '-' + alltrim (_trb -> b1_desc)})
		_oSec1:Cell("CLIENTE"):SetBlock   ({|| _trb -> cliente + '/' + _trb -> loja + '-' + _trb -> a1_nome})
		_oSec1:Cell("TIPO_NF"):SetBlock   ({|| _trb -> tipo_movto})
		_oSec1:Cell("NF"):SetBlock        ({|| _trb -> nf})
		_oSec1:Cell("EMISSAO"):SetBlock   ({|| stod (_trb -> emissao_nf)})
		_oSec1:Cell("QUANT"):SetBlock     ({|| _trb -> quant_nf})
		_oSec1:Cell("UM"):SetBlock        ({|| _trb -> b1_um})
		_oSec1:Cell("VALOR_NF"):SetBlock  ({|| _trb -> valor_nf})
		_oSec1:Cell("CUSMED"):SetBlock    ({|| _trb -> saldo_cust})

		_oSec1:PrintLine ()
		
		_trb -> (dbskip ())
	enddo
	_trb -> (dbclosearea ())
	dbselectarea ("SB1")

	_oSec1:Finish ()
Return



// -------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Posicao na data de...         ", "D",  8, 0,  "",   "   ", {},                                   ""})
	aadd (_aRegsPerg, {02, "Situacao na data              ", "N",  1, 0,  "",   "   ", {"Com saldo", "Encerrados", "Todos"}, ""})
	aadd (_aRegsPerg, {03, "Filial inicial                ", "C",  2, 0,  "",   "SM0", {},                                   ""})
	aadd (_aRegsPerg, {04, "Filial final                  ", "C",  2, 0,  "",   "SM0", {},                                   ""})
	aadd (_aRegsPerg, {05, "Cliente inicial               ", "C",  6, 0,  "",   "SA1", {},                                   ""})
	aadd (_aRegsPerg, {06, "Loja cliente inicial          ", "C",  2, 0,  "",   "   ", {},                                   ""})
	aadd (_aRegsPerg, {07, "Cliente final                 ", "C",  6, 0,  "",   "SA1", {},                                   ""})
	aadd (_aRegsPerg, {08, "Loja cliente final            ", "C",  2, 0,  "",   "   ", {},                                   ""})
	aadd (_aRegsPerg, {09, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                                   ""})
	aadd (_aRegsPerg, {10, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},                                   ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
