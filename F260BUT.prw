// Programa...: F260BUT
// Autor......: Catia Cardoso	
// Data.......: 17/06/2016
// Descricao..: Cria botoes na tela do DDA
//
// Historico de alteracoes:

// --------------------------------------------------------------------------
user Function F260BUT (_wpar1, _wpar2, _wpar3, _wpar4)
	_aRet := aClone(paramixb)
	
	AAdd( _aRet , { "Verificar", "U_VA_CFOR()", 0, 1 } )
	
return _aRet

User function VA_CFOR()
	// se o registro ja foi conciliado não permite alterar para verificar
	
	// deixa o registro do DDA como a verificar
	_sSQL := ""
    _sSQL += " UPDATE " + RetSQLName ("FIG")
    _sSQL += "    SET FIG_FORNEC = ''"
	_sSQL += "      , FIG_LOJA   = ''"
	_sSQL += "      , FIG_NOMFOR = ''"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
 	_sSQL += "    AND FIG_FILIAL = '" + xfilial ("FIG")   + "'"
   	_sSQL += "    AND FIG_CONCIL = '2'"
   	_sSQL += "    AND FIG_CODBAR = '" + FIG -> FIG_CODBAR + "'"
   	_sSQL += "    AND FIG_CNPJ   = '" + FIG -> FIG_CNPJ + "'"
   	_sSQL += "    AND FIG_TITULO = '" + FIG -> FIG_TITULO + "'"
   	
 	if TCSQLExec (_sSQL) < 0	
		u_help ("Nao foi possivel atualizar registros DDA da OWENS. Erro no UPDATE.")
	endif
	 	
return
