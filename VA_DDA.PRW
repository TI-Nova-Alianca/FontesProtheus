// Programa...: VA_DDA
// Autor......: Catia Cardoso
// Data.......: 29/09/2015
// Descricao..: Tela de conciliação DDA - deleta registros vencidos
//
// Historico de alteracoes:
// 10/06/2016 - Catia - verificacoes de fornecedores que tem filial de cobraça OWNES, KLABIN, CELULOSE IRANI, STV
// 16/06/2016 - Catia - incluido tratamento do fornecedor EXPRESSO RINCAO
//
#include "rwmake.ch"

User Function VA_DDA ()
	local i := 0
	
	// delete registros "vencidos" nda FIG - para que nao apareça sujeira - vencidos não tem função
	_sSQL := ""
    _sSQL += " UPDATE " + RetSQLName ("FIG")
    _sSQL += "    SET D_E_L_E_T_='*'"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_VENCTO < '" + dtos (date ()) + "'"
   	
	if TCSQLExec (_sSQL) < 0
		msgalert ("Nao foi possivel excluir registros vencidos no DDA. Erro no UPDATE.")
	endif
	// TRATAMENTO ESPECIFICO PARA OWENS 
	// altera os registros DDA da OWENS que vem no outro CNPJ por conta da filial de cobrança
	// e altera os nros de docuemtnos da OWENS tirando os 2 ultimos digitos que identificam a parcela
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '08910541000169'"
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '001906'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da OWENS. Erro no UPDATE.")
			endif
		next
	endif
	// TRATAMENTO ESPECIFICO PARA KLABIN	 
	// altera os registros DDA da KLABIN que vem no outro CNPJ por conta da filial de cobrança
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '89637490000145'"
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '000900'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da KLABIN. Erro no UPDATE.")
			endif
		next
	endif
	// TRATAMENTO ESPECIFICO PARA SAINT GOBAIN	 
	// altera os registros DDA da KLABIN que vem no outro CNPJ por conta da filial de cobrança
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '60853942000144'"
   	
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '000851'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da SAINT GOBAIN. Erro no UPDATE.")
			endif
		next
	endif
	// TRATAMENTO ESPECIFICO PARA CELULOSE IRANI	 
	// altera os registros DDA da CELULOSE IRANI que vem no outro CNPJ por conta da filial de cobrança
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '92791243000103'"
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '003994'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da IRANI. Erro no UPDATE.")
			endif
		next
	endif
	// TRATAMENTO ESPECIFICO PARA EXPRESSO RINCAO	 
	// altera os registros DDA da EXPRESSO RINCAO que vem no outro CNPJ por conta da filial de cobrança
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '59160614000698'"
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '001010'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da RINCAO. Erro no UPDATE.")
			endif
		next
	endif
	// TRATAMENTO ESPECIFICO PARA STV	 
	// altera os registros DDA da STV que vem no outro CNPJ por conta da filial de cobrança
	_sSQL := ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM FIG010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CNPJ = '88191069000190'"
   	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wfornece = '003917'
			_wloja    = '01'
			_wcgc     = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_CGC")
			_wnome    = fBuscaCpo ('SA2', 1, xfilial('SA2') + _wfornece + _wloja, "A2_NREDUZ")
			_wrecno   = str(_aDados[i,1],6)
			_sSQL := ""
    		_sSQL += " UPDATE " + RetSQLName ("FIG")
    		_sSQL += "    SET FIG_FORNEC = '" + _wfornece + "'"
	        _sSQL += "      , FIG_LOJA   = '" + _wloja + "'"
	        _sSQL += "      , FIG_CNPJ   = '" + _wcgc + "'"
	        _sSQL += "      , FIG_NOMFOR = '" + _wnome + "'"
 			_sSQL += "  WHERE D_E_L_E_T_ = ''"
 			_sSQL += "    AND FIG_FILIAL = '01'"  // só tem esse caso na MATRIZ
   			_sSQL += "    AND FIG_CONCIL = '2'"
 			_sSQL += "    AND R_E_C_N_O_ = " + _wrecno
 	
 			if TCSQLExec (_sSQL) < 0	
				msgalert ("Nao foi possivel atualizar registros DDA da STV. Erro no UPDATE.")
			endif
		next
	endif
	// chama o programa normal de conciliação
	dbselectarea ("FIG")
	FINA260 ()
	
return