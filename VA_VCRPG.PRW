//  Programa...: VA_VCRPG
//  Autor......: Cláudia Lionço
//  Data.......: 24/05/2024
//  Descricao..: Posição de títulos Pagar/Receber
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatório
// #Descricao         #Posição de títulos Pagar/Receber
// #PalavasChave      #titulos #pagar_receber
// #TabelasPrincipais #SE1 #SE2 #SE5
// #Modulos           #FIN
//
// Vencidos até 30 dias
// Vencidos de 31 a 60 dias
// Vencidos de 61 a 90 dias
// Vencidos de 91 a 180 dias
// Vencidos de 181 a 365 dias
// Vencidos a mais de 365 dias
// A vencer até 365 dias
// A vencer a mais de 365 dias
//
//  Historico de alterações
//
// ---------------------------------------------------------------------------
#include "rwmake.ch"

User function VA_VCRPG()
	Local   _x 				:= 0
	Private cPerg 			:= "VA_VCRPG"
	Private _aVenc30  		:= {}
	Private _aVenc60		:= {}
	Private _aVenc90		:= {}
	Private _aVenc180		:= {}
	Private _aVenc365		:= {}
	Private _aVencMais365   := {}
	Private _aVencer365		:= {}
	Private _aVencerMais365 := {}

	_ValidPerg()
	Pergunte(cPerg,.T.)

	_dDtRef := mv_par05 				// data referencia

	_d365DDA := DaySum(mv_par05, 365) 	// 365 a vencer
	_d30DDV  := DaySub(mv_par05,  30) 	// 30  vencidos
	_d60DDV  := DaySub(mv_par05,  60) 	// 60  vencidos
	_d90DDV  := DaySub(mv_par05,  90) 	// 90  vencidos
	_d180DDV := DaySub(mv_par05, 180) 	// 180 vencidos
	_d365DDV := DaySub(mv_par05, 365) 	// 365 vencidos

	// Gera linha para Tipo
	_aLinha := U_SeparaCpo(mv_par03, ',')
	_sTipo  := ""
	For _x := 1 to Len(_aLinha)
		if !empty(_aLinha[_x])
			_sTipo += "'" + _aLinha[_x] + "'"
			if _x <> Len(_aLinha)
				_sTipo += ","
			endif
		endif
	Next

	// Gera linha para natureza
	_aLinha    := U_SeparaCpo(mv_par04, ',')
	_sNatureza := ""
	For _x := 1 to Len(_aLinha)
		if !empty(_aLinha[_x]) 
			_sNatureza += "'" + _aLinha[_x] + "'"
			if _x <> Len(_aLinha)
				_sNatureza += ","
			endif
		endif
	Next

	// Vencidos até 30 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "	
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ NOT IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d30DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_dDtRef) +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d30DDV)+"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_dDtRef) +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef) +"' "
	_aVenc30 := aclone(_oSQL:Qry2Array(.f., .f.))


	// Vencidos de 31 a 60 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d60DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d30DDV) +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d60DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d30DDV) +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef) +"' "
	_aVenc60 := aclone(_oSQL:Qry2Array(.f., .f.))

	// Vencidos de 91 a 180 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d90DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d60DDV) +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d90DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d60DDV) +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef) +"' "
	_aVenc90 := aclone(_oSQL:Qry2Array(.f., .f.))


	// Vencidos de 91 a 180 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d180DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d60DDV)  +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d180DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d60DDV)  +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef)  +"' "
	_aVenc180 := aclone(_oSQL:Qry2Array(.f., .f.))

	// Vencidos de 181 a 365 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza) 
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d365DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d180DDV) +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ dtos(_d365DDV) +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d180DDV) +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef)  +"' "
	_aVenc365 := aclone(_oSQL:Qry2Array(.f., .f.))

	// Vencidos a mais de 365 dias
	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d365DDV)  +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ dtos(_d365DDV) +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ dtos(_dDtRef)  +"' "
	_aVencMais365 := aclone(_oSQL:Qry2Array(.f., .f.))

	// A vencer até 365 dias
	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND E1_VENCREA BETWEEN '"+ dtos(_dDtRef) +"' AND '"+ dtos(_d365DDA) +"'"
	_aVencer365 := aclone(_oSQL:Qry2Array(.f., .f.))
	
	// A vencer até 365 dias
	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ("+ _sNatureza +") "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND E1_VENCREA > '"+ dtos(_d365DDA) +"'"
	_aVencerMais365 := aclone(_oSQL:Qry2Array(.f., .f.))

	if mv_par06 == 1
		_ImpSintetico()
	else
		_ImpAnalitico()
	endif

Return
//
// --------------------------------------------------------------------------
// Relatorio de registros importados ANALITICO
Static Function _ImpAnalitico()
	Private oReport

	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oBreak1

	oReport := TReport():New("VA_VCRPG","Posição de títulos Pagar/Receber Analitico",cPerg,{|oReport| PrintReport(oReport)},"Posição de títulos Pagar/Receber")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA01", 	"" ,"Dt.Venc.Real"	,	    				,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA02", 	"" ,"Filial"		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA03", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA04", 	"" ,"Prefixo"		,   					,10,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA05", 	"" ,"Parcela"		,    					,05,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA06", 	"" ,"Cliente"		,   					,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA07", 	"" ,"Loja"			,    					,05,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA08", 	"" ,"Nome"			,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA09", 	"" ,"Valor"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Saldo"			, "@E 999,999,999.99"	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Dt.Baixa"		,	    				,10,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  	:= oReport:Section(1)
	Local _x 			:= 0
	Local _nV30			:= 0
	Local _nV60			:= 0
	Local _nV90			:= 0
	Local _nV180		:= 0
	Local _nV365		:= 0
	Local _nVMais365	:= 0
	Local _nVencer365	:= 0
	Local _nVencerM365  := 0
	Local _nVS30		:= 0
	Local _nVS60		:= 0
	Local _nVS90		:= 0
	Local _nVS180		:= 0
	Local _nVS365		:= 0
	Local _nVMaisS365	:= 0
	Local _nVencerS365	:= 0
	Local _nVencerMS365 := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	oReport:PrintText("Vencidos até 30 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVenc30)

		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVenc30[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVenc30[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVenc30[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVenc30[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVenc30[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVenc30[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVenc30[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVenc30[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVenc30[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVenc30[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVenc30[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nV30  += _aVenc30[_x, 9]
		_nVS30 += _aVenc30[_x,10]
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("Vencidos de 31 a 60 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVenc60)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVenc60[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVenc60[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVenc60[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVenc60[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVenc60[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVenc60[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVenc60[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVenc60[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVenc60[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVenc60[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVenc60[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nV60  += _aVenc60[_x, 9]
		_nVS60 += _aVenc60[_x,10]
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("Vencidos de 61 a 90 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVenc90)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVenc90[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVenc90[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVenc90[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVenc90[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVenc90[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVenc90[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVenc90[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVenc90[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVenc90[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVenc90[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVenc90[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nV90  := _aVenc90[_x, 9]
		_nVS90 := _aVenc90[_x,10]
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("Vencidos de 91 a 180 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVenc180)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVenc180[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVenc180[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVenc180[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVenc180[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVenc180[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVenc180[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVenc180[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVenc180[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVenc180[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVenc180[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVenc180[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nV180  += _aVenc180[_x, 9]
		_nVS180 += _aVenc180[_x,10]
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("Vencidos de 181 a 365 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVenc365)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVenc365[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVenc365[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVenc365[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVenc365[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVenc365[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVenc365[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVenc365[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVenc365[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVenc365[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVenc365[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVenc365[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nV365  += _aVenc365[_x, 9]
		_nVS365 += _aVenc365[_x,10] 
	
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("Vencidos a mais de 365 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVencMais365)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVencMais365[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVencMais365[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVencMais365[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVencMais365[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVencMais365[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVencMais365[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVencMais365[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVencMais365[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVencMais365[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVencMais365[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVencMais365[_x,11]) }) 

			oSection1:PrintLine()
		endif

		_nVMais365  += _aVencMais365[_x, 9] 
		_nVMaisS365 += _aVencMais365[_x,10]		

	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("A vencer até 365 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVencer365)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVencer365[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVencer365[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVencer365[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVencer365[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVencer365[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVencer365[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVencer365[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVencer365[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVencer365[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVencer365[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVencer365[_x,11]) }) 

			oSection1:PrintLine()
		endif
		_nVencer365  += _aVencer365[_x, 9]
		_nVencerS365 += _aVencer365[_x,10]

	Next

	oReport:ThinLine()
	oReport:SkipLine(1)

	// --------------------------------------------------------------------------

	oReport:PrintText("A vencer a mais de 365 dias" ,, 100)
	oReport:ThinLine()
	oReport:SkipLine(1)

	For _x := 1 to Len(_aVencerMais365)
		if mv_par06 == 2
			oSection1:Cell("COLUNA01")	:SetBlock   ({|| stod(_aVencerMais365[_x, 1]) }) 
			oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aVencerMais365[_x, 2] })
			oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aVencerMais365[_x, 3] }) 
			oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aVencerMais365[_x, 4] }) 
			oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aVencerMais365[_x, 5] }) 
			oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aVencerMais365[_x, 6] }) 
			oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aVencerMais365[_x, 7] }) 
			oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVencerMais365[_x, 8] }) 
			oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVencerMais365[_x, 9] }) 
			oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVencerMais365[_x,10] })
			oSection1:Cell("COLUNA11")	:SetBlock   ({|| stod(_aVencerMais365[_x,11]) })

			oSection1:PrintLine() 
		endif

		_nVencerM365  += _aVencerMais365[_x, 9]
		_nVencerMS365 += _aVencerMais365[_x,10]

	Next

	_nTotVal := _nV30 + _nV60 + _nV90 + _nV180 + _nV365	+ _nVMais365 + _nVencer365 + _nVencerM365  
	_nTotSal := _nVS30 + _nVS60	+ _nVS90 + _nVS180 + _nVS365 + _nVMaisS365 + _nVencerS365 + _nVencerMS365 

	oReport:SkipLine(1)
	oReport:ThinLine()
	oReport:PrintText("Total Valor:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVal, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Total Saldo:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotSal, "@E 999,999,999.99"),20,' '),, 900)

	oReport:ThinLine()
	oReport:SkipLine(1)

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Relatorio de registros importados SINTETICO
Static Function _ImpSintetico()
	Private oReport

	oReport := ReportDef1()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef1()
	Local oReport  := Nil
	Local oSection1:= Nil

	oReport := TReport():New("VA_VCRPG","Posição de títulos Pagar/Receber Sintético",cPerg,{|oReport| PrintRep1(oReport)},"Posição de títulos Pagar/Receber")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA01", 	"" ,"Prazo"	,	    						,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA02", 	"" ,"Valor"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA03", 	"" ,"Saldo"			, "@E 999,999,999.99"	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintRep1(oReport)
	Local oSection1  	:= oReport:Section(1)
	Local _x 			:= 0
	Local _nV30			:= 0
	Local _nV60			:= 0
	Local _nV90			:= 0
	Local _nV180		:= 0
	Local _nV365		:= 0
	Local _nVMais365	:= 0
	Local _nVencer365	:= 0
	Local _nVencerM365  := 0
	Local _nVS30		:= 0
	Local _nVS60		:= 0
	Local _nVS90		:= 0
	Local _nVS180		:= 0
	Local _nVS365		:= 0
	Local _nVMaisS365	:= 0
	Local _nVencerS365	:= 0
	Local _nVencerMS365 := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	For _x := 1 to Len(_aVenc30)
		_nV30  += _aVenc30[_x, 9]
		_nVS30 += _aVenc30[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos até 30 dias" }) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nV30 					})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVS30 				}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVenc60)
		_nV60  += _aVenc60[_x, 9]
		_nVS60 += _aVenc60[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos de 31 a 60 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nV60 						})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVS60 					}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVenc90)
		_nV90  := _aVenc90[_x, 9]
		_nVS90 := _aVenc90[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos de 61 a 90 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nV90 						})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVS90 					}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVenc180)
		_nV180  += _aVenc180[_x, 9]
		_nVS180 += _aVenc180[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos de 91 a 180 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nV180 						})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVS180 						}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVenc365)
		_nV365  += _aVenc365[_x, 9]
		_nVS365 += _aVenc365[_x,10] 
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos de 181 a 365 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nV365 						})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVS365 						}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVencMais365)
		_nVMais365  += _aVencMais365[_x, 9] 
		_nVMaisS365 += _aVencMais365[_x,10]		
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "Vencidos a mais de 365 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nVMais365 					})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVMaisS365 					}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVencer365)
		_nVencer365  += _aVencer365[_x, 9]
		_nVencerS365 += _aVencer365[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "A vencer até 365 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nVencer365 				})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVencerS365 				}) 
	oSection1:PrintLine()

	// --------------------------------------------------------------------------
	For _x := 1 to Len(_aVencerMais365)
		_nVencerM365  += _aVencerMais365[_x, 9]
		_nVencerMS365 += _aVencerMais365[_x,10]
	Next

	oSection1:Cell("COLUNA01")	:SetBlock   ({|| "A vencer a mais de 365 dias"	}) 
	oSection1:Cell("COLUNA02")	:SetBlock   ({|| _nVencerM365 					})
	oSection1:Cell("COLUNA03")	:SetBlock   ({|| _nVencerMS365 					}) 
	oSection1:PrintLine()

	oReport:SkipLine(1)
	oReport:ThinLine()

	// --------------------------------------------------------------------------
	_nTotVal := _nV30 + _nV60 + _nV90 + _nV180 + _nV365	+ _nVMais365 + _nVencer365 + _nVencerM365  
	_nTotSal := _nVS30 + _nVS60	+ _nVS90 + _nVS180 + _nVS365 + _nVMaisS365 + _nVencerS365 + _nVencerMS365 

	oReport:SkipLine(1)
	oReport:ThinLine()
	oReport:PrintText("Total Valor:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVal, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Total Saldo:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotSal, "@E 999,999,999.99"),20,' '),, 900)

	oReport:ThinLine()
	oReport:SkipLine(1)

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de       	", "C", 	2, 0,  "",  "SM0", {}						,                     ""})
    aadd (_aRegsPerg, {02, "Filial até   		", "C", 	2, 0,  "",  "SM0", {}						,                     ""})
    aadd (_aRegsPerg, {03, "Tipo                ", "C",    20, 0,  "",  "   ", {}						, "Separar por virgulas"})
    aadd (_aRegsPerg, {04, "Sem as naturezas    ", "C",    20, 0,  "",  "   ", {}						, "Separar por virgulas"})
    aadd (_aRegsPerg, {05, "Data Referencia     ", "D",     8, 0,  "",  "   ", {}						,      				  ""})
	aadd (_aRegsPerg, {06, "Modelo              ", "N",     1, 0,  "",  "   ", {"Sintetico","Analitico"},                     ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
