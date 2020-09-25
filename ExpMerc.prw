// Programa:  ExpMerc
// Autor:     André Alves
// Data:      03/09/2018
// Descricao: Reenvia Notas para Mercanet
//
// Historico de alteracoes:
//
// 03/09/2018 - André - Criado para reenviar notas para Mercanet.
// 02/12/2019 - Robert - Declaradas variaveis locais para for...next - tratamento para mensagem [For variable is not Local]
// --------------------------------------------------------------------------

User Function ExpMerc ()
	Private cPerg   := "ExpMerc"
	private _nTipoPlan   := 0
	private _sTipoPlan := ''

	if U_msgnoyes ("reexporta dados especificos para Mercanet")

	//	_ValidPerg()
	//	do while pergunte (cPerg, .T.)
			_VaiMerc ()
	//	enddo
		

	//	cPerg = "EXP1"
	//	_ValidPerg ()
	//	cPerg = "EXP2"
	//	_ValidPerg ()

		// Consulta em loop para facilitar a troca de parametros.
	//	do while .T.
	//		_nTipoPlan = aviso ("Selecione o que exportar", ;
	//						   {"Notas", "Produtos", "Cancelar"}, ;
	//						   3,)
							
	//		if _nTipoPlan == 1
	//			_sTipoPlan = 'N'
	//			cPerg = "EXP1"
	//		elseif _nTipoPlan == 2
	//			_sTipoPlan = 'P'
	//			cPerg = "EXP2"
	//		else
	//			exit
	//		endif
				
	//		if Pergunte (cPerg, .T.)
	//			_VaiMerc ()
	//			loop
	//		else
	//			exit
	//		endif
	//	enddo
	endif
return

//Reenvia notas de entrada para Mercanet
Static Function _VaiMerc ()
	local _nLinha := 0
/*	set deleted off
	if _sTipoPlan = 'N'
		if mv_par01 == 1
			dbselectarea ("SF2")
			set filter to &("f2_filial='" + cFilAnt + "'.and.f2_doc='" + mv_par02 + "'.and.f2_serie='" + mv_par03 + "'")
			sf2 -> (dbgotop ())
			U_AtuMerc ("SF2", sf2 -> (recno ()))
		endif

		if mv_par01 == 2
			dbselectarea ("SF1")
			set filter to &("f1_filial='" + cFilAnt + "'.and.f1_doc='" + mv_par04 + "'.and.f1_serie='" + mv_par05 + "'.and.f1_fornece='" + mv_par08 + "'.and.f1_loja='" + mv_par09 + "'")
			sf1 -> (dbgotop ())
			U_AtuMerc ("SF1", sf1 -> (recno ()))
		endif
		
		if mv_par01 == 3
			dbselectarea ("SF1")
			set filter to &("f1_filial='" + cFilAnt + "'.and.f1_serie='" + mv_par05 + "'.and.f1_emissao>='" + mv_par06 + "'.and.f1_emissao<='" + mv_par07 + "'.and.f1_fornece='" + mv_par08 + "'.and.f1_loja='" + mv_par09 + "'")
			sf1 -> (dbgotop ())
			U_AtuMerc ("SF1", sf1 -> (recno ()))
		endif

	set deleted on
	 else */
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
	   	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SB1")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND B1_FILIAL = '" + xfilial ("SB1") + "'"  // Deixar esta opcao para poder ler os campos memo.
		_oSQL:_sQuery += " AND B1_TIPO = 'PA'"
	    _oSQL:_sQuery += " AND B1_COD IN ('0345', '0215')"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		For _nLinha := 1 To Len(_aDados)
			sb1 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SB1", sb1 -> (recno ()))
		next 
		
/*		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
	   	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SF4")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND F4_FILIAL = '" + xfilial ("SF4") + "'"  // Deixar esta opcao para poder ler os campos memo.
	//	_oSQL:_sQuery += " AND B1_TIPO = 'PA'"
	//  _oSQL:_sQuery += " AND B1_COD IN ('0345', '0215')"
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array ())
		For _nLinha := 1 To Len(_aDados)
			sf4 -> (dbgoto (_aDados [_nLinha, 1]))
			U_AtuMerc ("SF4", sf4 -> (recno ()))
		next */ 
	
		
	//endif
	

return

/*Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
//	if cPerg == 'EXP1'
	//                     PERGUNT                           TIPO TAM                   DEC VALID F3       Opcoes          Help
	aadd (_aRegsPerg, {01, "Tipo de Nota			      ", "C", 12,                   0,  "",   "     ", {'NF SAÍDA', 'NF DEVOLUCAO', 'DEVOLUCAO POR DATA'}, ""})
	aadd (_aRegsPerg, {02, "NF saida                      ", "C", 9,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {03, "Serie NF Saida                ", "C", 3,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {04, "NF devolucao                  ", "C", 9,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {05, "Serie NF Devolucao            ", "C", 3,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {06, "Data de       			      ", "D", 8,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {07, "Data até            		  ", "D", 8,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {08, "Fornecedor NF Devolucao       ", "C", 6,                    0,  "",   "     ", {},             ""})
	aadd (_aRegsPerg, {09, "Loja NF Devolucao             ", "C", 2,                    0,  "",   "     ", {},             ""})
	
//	elseif cPerg == 'EXP2'
	//                     PERGUNT                           TIPO TAM                   DEC VALID F3       Opcoes          Help
//	aadd (_aRegsPerg, {01, "Exportar Produtos ?		      ", "C",  3,                   0,  "",   "     ", {'SIM', 'NAO'}, ""})
	
//	endif
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
	
return*/
