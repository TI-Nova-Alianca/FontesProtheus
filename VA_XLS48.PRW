// Programa...: VA_XLS48
// Autor......: Robert Koch
// Data.......: 04/01/2020
// Descricao..: Consulta faixas de aceitacao de uvas para espumante para safra.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS48 ()
	local _sSafra := space (4)

	do while .T.
		_sSafra = U_Get ('Consulta faixas aceitacao uvas para espumante p/safra (vazio=cancelar):', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
		if _sSafra != NIL .and. ! empty (_sSafra)
			Processa( { |lEnd| _Gera (_sSafra) } )
		else
			exit
		endif
	enddo
return



// --------------------------------------------------------------------------
Static Function _Gera (_sSafra)
	local _oSQL := NIL

	procregua (10)
	incproc ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""

	// MONTA CTE PARA AGRUPAR AS FAIXAS DE GRAU
	_oSQL:_sQuery += " WITH FAIXAS AS"
	_oSQL:_sQuery += " (SELECT ROW_NUMBER() OVER (ORDER BY ZX5_17GIES DESC, ZX5_17GIES DESC) AS FAIXA, ZX5_17GIES, ZX5_17GFES"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZX5") + " ZX5_17"
	_oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery += " 	AND ZX5_TABELA = '17'"
	_oSQL:_sQuery += " 	AND ZX5_17SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery += " 	AND (ZX5_17GIES != '' OR ZX5_17GFES != '')"
	_oSQL:_sQuery += " 	GROUP BY ZX5_17GIES, ZX5_17GFES),"
	_oSQL:_sQuery += " PRODUTOS AS"
	_oSQL:_sQuery += " (SELECT F.FAIXA, PRODUTOS.ZX5_17PROD, SB1.B1_COD, RTRIM(SB5.B5_CEME) + ' ' AS DESCRI_PROD, F.ZX5_17GIES, F.ZX5_17GFES"
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("ZX5") + " PRODUTOS"
	_oSQL:_sQuery += " 		," + RetSQLName ("SB1") + " SB1"
	_oSQL:_sQuery += " 		," + RetSQLName ("SB5") + " SB5"
	_oSQL:_sQuery += " 		,FAIXAS F"
	_oSQL:_sQuery += " 	WHERE PRODUTOS.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND PRODUTOS.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery += " 	AND PRODUTOS.ZX5_TABELA = '17'"
	_oSQL:_sQuery += " 	AND PRODUTOS.ZX5_17SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery += " 	AND PRODUTOS.ZX5_17GIES = F.ZX5_17GIES"
	_oSQL:_sQuery += " 	AND PRODUTOS.ZX5_17GFES = F.ZX5_17GFES"
	_oSQL:_sQuery += " 	AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += " 	AND SB1.B1_COD = PRODUTOS.ZX5_17PROD"
	_oSQL:_sQuery += " 	AND SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SB5.B5_FILIAL = SB1.B1_FILIAL"
	_oSQL:_sQuery += " 	AND SB5.B5_COD = SB1.B1_COD),"
	_oSQL:_sQuery += " CONCATENADOS AS"
	_oSQL:_sQuery += " (SELECT FAIXA, ZX5_17GIES AS GRAU_INICIAL, ZX5_17GFES AS GRAU_FINAL, STRING_AGG(P1.DESCRI_PROD, ',') AS VARIEDADES"
	_oSQL:_sQuery += " 	FROM PRODUTOS AS P1"
	_oSQL:_sQuery += " 	GROUP BY FAIXA, ZX5_17GIES, ZX5_17GFES)"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery += " FROM CONCATENADOS"
	_oSQL:_sQuery += " ORDER BY FAIXA"
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))
return
