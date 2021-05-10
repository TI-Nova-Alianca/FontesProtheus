// Programa...: VA_XLS49
// Autor......: Robert Koch
// Data.......: 06/01/2020
// Descricao..: Consulta faixas de classificacao de uvas latadas para safra.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta faixas de classificacao de uvas latadas para safra.
// #PalavasChave      #uvas #safra #faixas_de_grau #classificacao
// #TabelasPrincipais #ZX5
// #Modulos           #coop

// Historico de alteracoes:
// 10/05/2021 - Robert - Melhorados titulos das colunas
//                     - Acrescentadas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
User Function VA_XLS49 ()
	local _sSafra := space (4)

	do while .T.
		_sSafra = U_Get ('Consulta faixas classif. uvas latadas p/safra (vazio=cancelar):', 'C', 4, '', '', U_IniSafra (date ()), .F., '.t.')
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
	_oSQL:_sQuery += " 
	_oSQL:_sQuery += " SELECT ZX5_52.ZX5_52GRUP + '-' + ZX5_52.ZX5_52DESC AS GRUPO,"
	_oSQL:_sQuery +=        " ZX5_52.ZX5_52GIA AS GR_MIN_A, ZX5_52.ZX5_52GIB AS GR_MIN_B, ZX5_52.ZX5_52GIC AS GR_MIN_C,"
	_oSQL:_sQuery +=        " STRING_AGG (RTRIM (SB1.B1_DESC), ', ') AS VARIEDADES"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZX5") + " ZX5_52, "
	_oSQL:_sQuery +=            RetSQLName ("ZX5") + " ZX5_53, "
	_oSQL:_sQuery +=            RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE ZX5_52.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZX5_52.ZX5_FILIAL = '" + xFilial ("ZX5") + "'"
	_oSQL:_sQuery += " AND ZX5_52.ZX5_TABELA = '52'"
	_oSQL:_sQuery += " AND ZX5_52.ZX5_52SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery += " AND ZX5_53.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZX5_53.ZX5_FILIAL = '" + xFilial ("ZX5") + "'"
	_oSQL:_sQuery += " AND ZX5_53.ZX5_TABELA = '53'"
	_oSQL:_sQuery += " AND ZX5_53.ZX5_53SAFR = ZX5_52.ZX5_52SAFR"
	_oSQL:_sQuery += " AND ZX5_53.ZX5_53GRUP = ZX5_52.ZX5_52GRUP"
	_oSQL:_sQuery += " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SB1.B1_FILIAL = '" + xFilial ("SB1") + "'"
	_oSQL:_sQuery += " AND SB1.B1_COD = ZX5_53.ZX5_53PROD"
	_oSQL:_sQuery += " GROUP BY ZX5_52.ZX5_52GRUP, ZX5_52.ZX5_52DESC, ZX5_52.ZX5_52GIA, ZX5_52.ZX5_52GIB, ZX5_52.ZX5_52GIC"
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))

	// Verifica se tem alguma variedade fora das faixas.
	_oSQL:_sQuery := "" 
	_oSQL:_sQuery += " SELECT STRING_AGG (RTRIM (B1_COD) + ' - ' + RTRIM (B1_DESC), ';')"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' AND B1_FILIAL = '" + xfilial ("SB1") + "' AND B1_GRUPO = '0400'"
	_oSQL:_sQuery += " AND B1_COD NOT IN ('9930','2684','9869')"  // Uva moida (transf.entre filiais), uvas de terceiros
	_oSQL:_sQuery += " AND B1_MSBLQL != '1'"
	_oSQL:_sQuery += " AND NOT EXISTS (SELECT * "
	_oSQL:_sQuery +=                   " FROM " + RetSQLName ("ZX5") + " ZX5_53 "
	_oSQL:_sQuery +=                  " WHERE ZX5_53.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND ZX5_53.ZX5_FILIAL = '" + xFilial ("ZX5") + "'"
	_oSQL:_sQuery +=                    " AND ZX5_53.ZX5_TABELA = '53'"
	_oSQL:_sQuery +=                    " AND ZX5_53.ZX5_53SAFR = '" + _sSafra + "'"
	_oSQL:_sQuery +=                    " AND ZX5_53.ZX5_53PROD = SB1.B1_COD)"
	_oSQL:Log ()
	_sFora = _oSQL:RetQry ()
	if ! empty (_sFora)
		u_help ("ATENCAO: Foram encontradas variedades que nao constam na tabela de faixas: " + left (_sFora, 200))
	endif
return
