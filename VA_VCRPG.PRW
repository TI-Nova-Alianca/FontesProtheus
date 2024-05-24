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
//  Historico de alterações
//
// ---------------------------------------------------------------------------
#include "rwmake.ch"

User function VA_VCRPG()
	Local _x := 0
	Private cPerg := "VA_VCRPG"

	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	/*
		Vencidos até 30 dias
		Vencidos de 31 a 60 dias
		Vencidos de 61 a 90 dias
		Vencidos de 91 a 180 dias
		Vencidos de 181 a 365 dias
		Vencidos a mais de 365 dias
		A vencer até 365 dias
		A vencer a mais de 365 dias
	*/

	_dDtRef := mv_par01 				// data referencia

	_d365DDA := DaySum(mv_par01, 365) 	// 365 a vencer
	_d30DDV  := DaySub(mv_par01,  30) 	// 30  vencidos
	_d60DDV  := DaySub(mv_par01,  60) 	// 60  vencidos
	_d90DDV  := DaySub(mv_par01,  90) 	// 90  vencidos
	_d180DDV := DaySub(mv_par01, 180) 	// 180 vencidos
	_d365DDV := DaySub(mv_par01, 365) 	// 365 vencidos

	// Gera linha para Tipo
	_aLinha := U_SeparaCpo(mv_par03, ',')
	_sTipo  := ""
	For _x := 1 to Len(_aLinha)
		_sTipo += "'" + _aLinha[_x, 1] + "'"
		If _x <> Len(_aLinha)
			_sTipo += ","
		EndIf
	Next

	// Gera linha para natureza
	_aLinha    := U_SeparaCpo(mv_par04, ',')
	_sNatureza := ""
	For _x := 1 to Len(_aLinha)
		_sNatureza += "'" + _aLinha[_x, 1] + "'"
		If _x <> Len(_aLinha)
			_sNatureza += ","
		EndIf
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
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d30DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _dDtRef +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d30DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _dDtRef +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ _dDtRef +"' "
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
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d60DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d30DDV +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d60DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d30DDV +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ _dDtRef +"' "
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
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d180DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d60DDV  +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d180DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d60DDV  +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ _dDtRef  +"' "
	_aVenc90 := aclone(_oSQL:Qry2Array(.f., .f.))

	// Vencidos de 181 a 365 dias
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d365DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d180DDV  +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA >  '"+ _d365DDV +"' " 
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d180DDV +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ _dDtRef  +"' "
	_aVenc180 := aclone(_oSQL:Qry2Array(.f., .f.))

	// Vencidos a mais de 365 dias
	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d365DDV  +"' "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND SE1.E1_VENCREA <= '"+ _d365DDV +"' "
	_oSQL:_sQuery += " AND SE1.E1_BAIXA   >  '"+ _dDtRef  +"' "
	_aVenc365 := aclone(_oSQL:Qry2Array(.f., .f.))

	// A vencer até 365 dias
	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := " SELECT "
	_oSQL:_sQuery += " 	   E1_VENCREA "
	_oSQL:_sQuery += "    ,E1_FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM "
	_oSQL:_sQuery += "    ,E1_PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA "
	_oSQL:_sQuery += "    ,E1_CLIENTE "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND E1_VENCREA BETWEEN '"+ _dDtRef +"' AND '"+ _d365DDA +"'"
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
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,E1_LOJA "
	_oSQL:_sQuery += "    ,E1_VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO "
	_oSQL:_sQuery += "    ,E1_BAIXA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SE1.E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SE1.E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
	if !empty(_sTipo)
		_oSQL:_sQuery += " AND E1_TIPO NOT IN ("+ _sTipo +") " // ('NCC', 'RA') "
	endif
	if !empty(_sNatureza)
		_oSQL:_sQuery += " AND E1_NATUREZ IN ('"+ _sNatureza +"') "
	endif
	_oSQL:_sQuery += " AND E1_SALDO > 0 "
	_oSQL:_sQuery += " AND E1_VENCREA > '"+ _d365DDA +"'"
	_aVencerMais365 := aclone(_oSQL:Qry2Array(.f., .f.))


	
Return
//
// --------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Filial de       	", "C", 	2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Filial até   		", "C", 	2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Sem os tipo         ", "C",    20, 0,  "",  "   ", {},              							"Separar por virgulas"})
    aadd (_aRegsPerg, {04, "Sem as naturezas    ", "C",    20, 0,  "",  "   ", {},              							"Separar por virgulas"})
     U_ValPerg (cPerg, _aRegsPerg)
Return
