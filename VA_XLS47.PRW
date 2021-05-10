// Programa...: VA_XLS47
// Autor......: Robert Koch
// Data.......: 04/01/2020
// Descricao..: Consulta faixas de classificacao de uvas em espaldeira para safra.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta faixas de classificacao de uvas em espaldeira para safra.
// #PalavasChave      #uvas #safra #faixas_de_grau #classificacao
// #TabelasPrincipais #ZX5
// #Modulos           #coop

// Historico de alteracoes:
// 10/05/2021 - Robert - Melhorados titulos das colunas
//                     - Acrescentadas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
User Function VA_XLS47 ()
	local _sSafra := space (4)

	do while .T.
		_sSafra = U_Get ('Consulta faixas classif. uvas espaldeira p/safra (vazio=cancelar):', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
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
	_oSQL:_sQuery += "WITH FAIXAS AS"
	_oSQL:_sQuery += "("
	_oSQL:_sQuery += "       SELECT ROW_NUMBER () OVER (ORDER BY ZX5_17GIPR DESC, ZX5_17GIAA DESC, ZX5_17GIA DESC, ZX5_17GIB DESC, ZX5_17GIC DESC, ZX5_17GID DESC) AS FAIXA,"
	_oSQL:_sQuery += "	          ZX5_17.ZX5_17GIPR, ZX5_17GID, ZX5_17GIC, ZX5_17GIB, ZX5_17GIA, ZX5_17GIAA"
	_oSQL:_sQuery += "         FROM " + RetSQLName ("ZX5") + " ZX5_17"
	_oSQL:_sQuery += "        WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "          AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery += "          AND ZX5_TABELA = '17'"
	_oSQL:_sQuery += "          AND ZX5_17SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery += "        GROUP BY ZX5_17GIPR, ZX5_17GID, ZX5_17GIC, ZX5_17GIB, ZX5_17GIA, ZX5_17GIAA"
	_oSQL:_sQuery += "),"

	// BUSCA OS PRODUTOS (VARIEDADES)"
	_oSQL:_sQuery += "PRODUTOS AS ("
	_oSQL:_sQuery += "       SELECT F.FAIXA, PRODUTOS.ZX5_17PROD, SB1.B1_COD, rtrim(SB5.B5_CEME) + ' ' AS DESCRI_PROD"
	_oSQL:_sQuery += "			, F.ZX5_17GIPR, F.ZX5_17GIAA, F.ZX5_17GIA, F.ZX5_17GIB, F.ZX5_17GIC, F.ZX5_17GID"
	_oSQL:_sQuery += "        FROM " + RetSQLName ("ZX5") + " PRODUTOS, " + RetSQLName ("SB1") + " SB1, " + RetSQLName ("SB5") + " SB5, FAIXAS F"
	_oSQL:_sQuery += "        WHERE  PRODUTOS.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "            AND PRODUTOS.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery += "            AND PRODUTOS.ZX5_TABELA = '17'"
	_oSQL:_sQuery += "            AND PRODUTOS.ZX5_17SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery += "			AND PRODUTOS.ZX5_17GID  = F.ZX5_17GID"
	_oSQL:_sQuery += "			AND PRODUTOS.ZX5_17GIC  = F.ZX5_17GIC""
	_oSQL:_sQuery += "			AND PRODUTOS.ZX5_17GIB  = F.ZX5_17GIB"
	_oSQL:_sQuery += "			AND PRODUTOS.ZX5_17GIA  = F.ZX5_17GIA"
	_oSQL:_sQuery += "			AND PRODUTOS.ZX5_17GIAA = F.ZX5_17GIAA"
	_oSQL:_sQuery += "			AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "            AND SB1.B1_FILIAL = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery += "            AND SB1.B1_COD = PRODUTOS.ZX5_17PROD"
	_oSQL:_sQuery += "            AND SB5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "            AND SB5.B5_FILIAL = SB1.B1_FILIAL"
	_oSQL:_sQuery += "            AND SB5.B5_COD = SB1.B1_COD"
	_oSQL:_sQuery += "    ),"

	// CONCATENA AS DESCRICOES DOS PRODUTOS"
	_oSQL:_sQuery += "CONCATENADOS AS ("
	_oSQL:_sQuery += " SELECT FAIXA, ZX5_17GIPR AS GR_MIN_PR, ZX5_17GIAA AS GR_MIN_AA, ZX5_17GIA AS GR_MIN_A, ZX5_17GIB AS GR_MIN_B, ZX5_17GIC AS GR_MIN_C, ZX5_17GID AS GR_MIN_D, "
	_oSQL:_sQuery +=        " STRING_AGG (P1.DESCRI_PROD, ',') AS VARIEDADES"
 	_oSQL:_sQuery += " FROM   PRODUTOS AS P1"
	_oSQL:_sQuery += " GROUP BY FAIXA, ZX5_17GIPR, ZX5_17GIAA, ZX5_17GIA, ZX5_17GIB, ZX5_17GIC, ZX5_17GID"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT * FROM CONCATENADOS"
	_oSQL:_sQuery += " ORDER BY FAIXA"
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))

	// Verifica se tem alguma variedade fora das faixas.
	_oSQL:_sQuery := "" 
	_oSQL:_sQuery += " SELECT STRING_AGG (RTRIM (B1_COD) + ' - ' + RTRIM (B1_DESC), ';')"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '" + xfilial ("SB1") + "' AND B1_GRUPO = '0400' AND B1_VARUVA = 'F' AND B1_VAFCUVA = 'F'"
	_oSQL:_sQuery += " AND B1_COD NOT IN ('9930','2684','9869')"  // Uva moida (transf.entre filiais), uvas de terceiros
	_oSQL:_sQuery += " AND B1_MSBLQL != '1'"
	_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM " + RetSQLName ("ZX5") + " ZX5"
	_oSQL:_sQuery +=                  " WHERE ZX5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND ZX5.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_oSQL:_sQuery +=                    " AND ZX5.ZX5_TABELA = '17'"
	_oSQL:_sQuery +=                    " AND ZX5.ZX5_17SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery +=                    " AND ZX5.ZX5_17PROD = B1_COD)"
	_sFora = _oSQL:RetQry ()
	if ! empty (_sFora)
		u_help ("ATENCAO: Foram encontradas variedades que nao constam na tabela de faixas: " + left (_sFora, 200))
	endif
return
