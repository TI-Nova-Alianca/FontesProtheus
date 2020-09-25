// Programa.:  BatDocCanc
// Autor....:  Catia Cardoso       
// Data.....:  02/09/2015     
// Descricao:  Verifica documentos no SF1 com retorno de cancelamento da Sefaz 
//
// Historico de alteracoes:
//
// 29/10/2015 - Catia - Alterado para 45 dias a verificação
// 14/02/2018 - Catia - Voltada a verificacao para 30 dias
// 09/10/2018 - Catia - Verificação da tabela CLK - tabela IBPT - tributos aproximados cupom fiscal
// 22/02/2019 - Catia - Incluida a coluna de estado no email dos documentos sem retorno da sefaz

// ------------------------------------------------------------------------------------------------
user function BatDocCanc (_sQueFazer, _nQtDias)
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _sMsg      := ""
	local _aCols     := {}
	local _dDtImpIni := date()-_nQtDias

	if alltrim (upper (_sQueFazer)) == "OC"
		_aCols = {}
		aadd (_aCols, {'Filial'        ,    'left' ,  ''})
		aadd (_aCols, {'Dt.Digitação'  ,    'left' ,  ''})
		aadd (_aCols, {'Documento'     ,    'left' ,  ''})
		aadd (_aCols, {'Serie'         ,    'left' ,  ''})
		aadd (_aCols, {'Cli/Fornecedor',    'left' ,  ''})
		aadd (_aCols, {'Chave'         ,    'left' ,  ''})
		aadd (_aCols, {'Layout'        ,    'left' ,  ''})
		aadd (_aCols, {'Retorno'       ,    'left' ,  ''})
			
		// Busca Documentos de entrada com retorno de cancelamento na Sefaz
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZX_FILIAL"
		_oSQL:_sQuery += "      , dbo.VA_DTOC(F1_DTDIGIT)"
		_oSQL:_sQuery += "      , ZZX_DOC"
		_oSQL:_sQuery += "      , ZZX_SERIE"
		_oSQL:_sQuery += "      , ZZX_CLIFOR"
		_oSQL:_sQuery += "      , ZZX_CHAVE"
		_oSQL:_sQuery += "      , ZZX_LAYOUT"
		_oSQL:_sQuery += "      , ZZX_RETSEF"
		_oSQL:_sQuery += "   FROM ZZX010 AS ZZX"
		_oSQL:_sQuery += "		INNER JOIN SF1010 SF1"
		_oSQL:_sQuery += "			ON (SF1.D_E_L_E_T_ = ''" 
		_oSQL:_sQuery += "				AND SF1.F1_CHVNFE  = ZZX.ZZX_CHAVE )" 
		_oSQL:_sQuery += "  WHERE ZZX.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	 AND ZZX.ZZX_RETSEF = '101'"
		_oSQL:_sQuery += "    AND ZZX_CHAVE != ''"
		// _oSQL:_sQuery += "    AND ZZX_DTIMP >= '" + dtos (date()-30) + "'"
		_oSQL:_sQuery += "    AND ZZX_DTIMP >= '" + dtos (_dDtImpIni) + "'"
		_oSQL:_sQuery += "  ORDER BY SF1.F1_DTDIGIT"
		_oSQL:Log ()

		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMsg = _oSQL:Qry2HTM ("Documentos importados a partir de " + dtoc (_dDtImpIni) + " com retorno de cancelamento e que constam no sistema.", _aCols, "", .F.)
			u_log2 ('info', _sMsg)
			U_ZZUNU ({'019'}, "Documentos Cancelados", _sMsg, .F., cEmpAnt, cFilAnt, "") // Setor de Fiscal
		endif

		_aCols = {}
		aadd (_aCols, {'Filial'        ,    'left' ,  ''})
		aadd (_aCols, {'Dt.Importação' ,    'left' ,  ''})
		aadd (_aCols, {'Documento'     ,    'left' ,  ''})
		aadd (_aCols, {'Serie'         ,    'left' ,  ''})
		aadd (_aCols, {'Cli/Fornecedor',    'left' ,  ''})
		aadd (_aCols, {'Chave'         ,    'left' ,  ''})
		aadd (_aCols, {'Layout'        ,    'left' ,  ''})
		aadd (_aCols, {'Retorno'       ,    'left' ,  ''})
		aadd (_aCols, {'Estado'        ,    'left' ,  ''})
		
		// Verifica documentos sem RETORNO DA SEFAZ - e manda email p Catia avisando a TI
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZX_FILIAL"
		_oSQL:_sQuery += "      , dbo.VA_DTOC(ZZX_DTIMP)"
		_oSQL:_sQuery += "      , ZZX_DOC"
		_oSQL:_sQuery += "      , ZZX_SERIE"
		_oSQL:_sQuery += "      , ZZX_CLIFOR"
		_oSQL:_sQuery += "      , ZZX_CHAVE"
		_oSQL:_sQuery += "      , ZZX_LAYOUT"
		_oSQL:_sQuery += "      , ZZX_RETSEF"
		_oSQL:_sQuery += "      , CASE WHEN SUBSTRING(ZZX_CHAVE,1,2) = '11' THEN 'RO'"
		_oSQL:_sQuery += "             WHEN SUBSTRING(ZZX_CHAVE,1,2) = '12' THEN 'AC'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '13' THEN 'AM'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '14' THEN 'RR'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '16' THEN 'AP'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '17' THEN 'TO'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '21' THEN 'MA'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '22' THEN 'PI'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '23' THEN 'CE'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '24' THEN 'RN'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '25' THEN 'PB'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '26' THEN 'PE'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '28' THEN 'SE'"	
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '29' THEN 'BA'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '17' THEN 'AL'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '31' THEN 'MG'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '32' THEN 'ES'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '33' THEN 'RJ'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '35' THEN 'SP'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '41' THEN 'PR'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '42' THEN 'SC'"	
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '43' THEN 'RS'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '50' THEN 'MS'"	
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '51' THEN 'MT'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '52' THEN 'GO'"	
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '53' THEN 'DF'"
		_oSQL:_sQuery += "     		  WHEN SUBSTRING(ZZX_CHAVE,1,2) = '99' THEN 'EX'"	
		_oSQL:_sQuery += "     	  ELSE '' END AS UF"
		_oSQL:_sQuery += "   FROM ZZX010 AS ZZX"  
		_oSQL:_sQuery += "  WHERE ZZX.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "	 AND ZZX.ZZX_RETSEF = ''"
		_oSQL:_sQuery += "    AND ZZX_CHAVE != ''"
	//	_oSQL:_sQuery += "    AND ZZX_DTIMP >= '" + dtos (date()-30) + "'"
		_oSQL:_sQuery += "    AND ZZX_DTIMP >= '" + dtos (_dDtImpIni) + "'"
		_oSQL:_sQuery += "  ORDER BY ZZX_DTIMP"
		_oSQL:Log ()

		if len (_oSQL:Qry2Array (.T., .F.)) > 0
			_sMsg = _oSQL:Qry2HTM ("Documentos importados a partir de " + dtoc (_dDtImpIni) + " e SEM retorno da SEFAZ", _aCols, "", .F.)
			u_log2 ('info', _sMsg)
			U_ZZUNU ({'019'}, "Documentos sem retorno da SEFAZ", _sMsg, .F., cEmpAnt, cFilAnt, "") // Setor de Fiscal
		endif
	endif

	// verifica tabela CLK - se esta proximo o vencimento avisa o fiscal
	_sSQL := ""
	_sSQL += " SELECT MAX(CLK_DTFIMV)"
	_sSQL += "   FROM " + RetSQLName ("CLK")
	_sSQL += "  WHERE D_E_L_E_T_ = ''"
	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		_sMsg = ""
		if dtos(ddatabase + 15) > _aDados[1,1] 
			_sMsg = "A tabela de IBPT no sistema está para vencer providencie o dowload do arquivo CSV na receita e faça a atualização pelo modulo fiscal. Vencimento: " + _aDados[1,1]
		endif
		if dtos(ddatabase) > _aDados[1,1] 
			_sMsg = "A tabela de IBPT no sistema está para VENCIDA providencie o dowload do arquivo CSV na receita e faça a atualização pelo modulo fiscal. Vencimento: " + _aDados[1,1]
		endif
		if _sMsg != "" 	 
			// manda email pra equipe do fiscal avisando que tem que ser atualizada a tabela de IBPT
			U_ZZUNU ({'019'}, "Atualizar Tabela IBPT - Tributos Aproximados Cupom Fiscal", _sMsg, .F., cEmpAnt, cFilAnt, "") // Setor de Fiscal
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return .T.
