// Programa...: CompPrc
// Autor......: Catia Cardoso
// Data.......: 28/01/2017
// Descricao..: Comp�e o pre�o de venda conforme percentuais e margens da tabela de custo 990 - igual ao Mercanet
//              Essa rotina � chamada das rotinas VA_ATUVEN e VA_PRVEN para buscar os pre�os de tabela, valor unitario e pre�o digitado 
//				por gatilhos no campo C6_QTDVEN e pela rotina ??????????
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
user function CompPrc (_sCliente, _sProduto, _sQualPrc)
	local _nRet      := 0
	// _sQaulPRC = 1 = C6_PRCVEN  	= Valor Unitario
	//             2 = C6_PRUNIT	= Pr Tabela
	//  		   3 = C6_VAPRCVE   = Pr Digitado
	
	// Busca custo e percentuais do cliente / produto
	_sQuery := ""
	_sQuery += " SELECT COMPOSICAO"		//	 1
	_sQuery += " 	  , PR_PRATICADO"	//	 2
	_sQuery += "   FROM MER_PERCOMP"		
	_sQuery += "  WHERE CODCLI = '" + _sCliente + "'" 
   	_sQuery += "    AND CODPRO = '" + _sProduto + "'"
   	_aPerComp := U_Qry2Array(_sQuery)
			
	if len(_aPerComp) > 0
		// Compoe preco de venda
		u_help ("Rotina de composi��o de Pre�o de Venda.")
		_wprcomposicao = _aPerComp[ 1, 1] 
		_wprpraticado  = _aPerComp[ 1, 2]
		// na teoria seria sempre o pre�o de composicao
		_nRet = _wprcomposicao
		// Valor Unitario ou Pr Digitado - Verifica Pre�o Praticado 
		if _sQualPrc != 2 
			if _wprpraticado > 0 .and. _wprpraticado <> _wprcomposicao  
	 			_nRet = _wprpraticado
	 			u_help ("Retorna Pre�o Praticado.")
			else
				_nRet = _wprcomposicao								
				u_help ("Retorna Pre�o Composto.")
			endif				
		endif									 	  		
	endif	
	 
return _nRet
