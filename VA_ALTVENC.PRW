// Programa:  VA_ALTVENC
// Autor:     Catia Cardoso
// Data:      16/10/2018
// Descricao: Altera data de vencimento de titulos no financeiro 
//            num primeiro momento - especifico para natureza 120206 - fretes - titulos de conhecimentos
//
// Historico de alteracoes:
// 
// 19/06/2019 - Catia - Parametro para poder selecionar a natureza mas so entre a 120206 e 120201
// 16/12/2019 - Claudia - Deviao a erro na R23, ajustado o if na data verificando se a mesma não está vazia
// --------------------------------------------------------------------------
User Function VA_ALTVENC ()
	Local _nTit	:= 0
	Private cPerg    := "VA_ALTVENC"
	
	_ValidPerg()
    if Pergunte(cPerg,.T.)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SE2.R_E_C_N_O_, SE2.E2_VENCTO, SE2.E2_EMISSAO, SE2.E2_FORNECE, SE2.E2_NATUREZ
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " AS SE2"
		_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '01'"
		_oSQL:_sQuery +=    " AND SE2.E2_SALDO > 0 "
		_oSQL:_sQuery +=    " AND SE2.E2_FORNECE BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_oSQL:_sQuery +=    " AND SE2.E2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
		if mv_par07 = 1
			_oSQL:_sQuery +=    " AND SE2.E2_NATUREZ = '120206'"
		else
			_oSQL:_sQuery +=    " AND SE2.E2_NATUREZ = '120201'"  /// PEGAR SO OS FRETES DA SAFRA - PAGOS PAR ASSOCIADOS
			_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO = 'FRS'"
		endif
		_oSQL:_sQuery +=    " AND SE2.E2_VENCTO  BETWEEN '" + dtos (mv_par05) + "' AND '" + dtos (mv_par06) + "'"
		_oSQL:Log ()
		_aTit := _oSQL:Qry2Array ()
		if len (_aTit) == 0
			u_help ("Nao foram encontrados titulos dentro dos parametros informados.")
		else
			_nAlter := 0
			for _nTit = 1 to len (_aTit)				
				if !empty(_aTit [_nTit, 2]) 
				//if _aTit [_nTit, 2]
					se2 -> (dbgoto (_aTit [_nTit, 1]))
					_oEvento := ClsEvent():new ()
					_oEvento:CodEven   = "SE2001"
					_oEvento:Texto     = "Parc.'" + se2 -> e2_parcela + "' vcto.alterado de " + dtoc (se2 -> e2_vencrea) + " para " + dtoc (mv_par08)
					_oEvento:NFEntrada = se2 -> e2_num
					_oEvento:SerieEntr = se2 -> e2_prefixo
					_oEvento:Fornece   = se2 -> e2_fornece
					_oEvento:LojaFor   = se2 -> e2_loja
					_oEvento:Grava ()
		
					reclock ("SE2", .F.)
						se2 -> e2_vencto  = mv_par08
						se2 -> e2_vencrea = DataValida (mv_par08)
					msunlock ()
					_nAlter ++
				endif
			next
		endif
	endif	
	u_help ("Processo concluido. " + cvaltochar (_nAlter) + " titulos alterados.")
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	aadd (_aRegsPerg, {01, "Fornecedor inicial    ", "C", 6,  0,  "",   "SA2", {},  "Codigo fornecedor inicial para filtragem de registros"})
	aadd (_aRegsPerg, {02, "Fornecedor final      ", "C", 6,  0,  "",   "SA2", {},  "Codigo fornecedor final para filtragem de registros"})
	aadd (_aRegsPerg, {03, "Emissao inicial       ", "D", 8,  0,  "",   ""	 , {},  "Data vencto inicial para filtragem de registros"})
	aadd (_aRegsPerg, {04, "Emissao final         ", "D", 8,  0,  "",   ""   , {},  "Data vencto final para filtragem de registros"})
	aadd (_aRegsPerg, {05, "Vencto inicial        ", "D", 8,  0,  "",   ""	 , {},  "Data vencto inicial para filtragem de registros"})
	aadd (_aRegsPerg, {06, "Vencto final          ", "D", 8,  0,  "",   ""   , {},  "Data vencto final para filtragem de registros"})
	aadd (_aRegsPerg, {07, "Natureza Financeira   ", "N", 1,  0,  "",   "   ", { "120206","120201"},""})
    aadd (_aRegsPerg, {08, "NOVA DATA VENCIMENTO  ", "D", 8,  0,  "",   ""   , {},  "Nova data de vencto"})
	U_ValPerg (cPerg, _aRegsPerg)
return