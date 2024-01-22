// Programa:   SZI_ICP
// Autor:      Robert Koch
// Data:       10/09/2012
// Descricao:  Gera integralizacao de capital social sobre a producao na conta corrente associados.
//
// Historico de alteracoes:
// 25/10/2013 - Robert  - Implementada geracao com base nas notas de compra de safra.
// 13/11/2013 - Robert  - Possibilidade de gerar dados ou apenas simulacao.
// 18/06/2015 - Robert  - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 21/03/2016 - Robert  - Valida se o usuario pertence ao grupo 059.
// 13/07/2017 - Robert  - Nao faz mais leitura de pre-notas nem de previsao de pagamento de safra.
// 10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Parametro em Loop 
//
// --------------------------------------------------------------------------
User Function SZI_ICP (_lAutom)
	
	cPerg    := "SZI_ICP"
	_ValidPerg ()
	pergunte (cPerg, .F.)
	
	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	if _lAutom == NIL .or. _lAutom == .F.
		if pergunte (cPerg, .T.)
			processa ({|| _Gera ()})
		endif
	else
		processa ({|| _Gera ()})
	endif
Return
//
// --------------------------------------------------------------------------
static function _Gera ()
	local _oSQL      := NIL
//	local _aRetClas  := {}
//	local _aPrev     := {}
//	local _aAvisos   := {}
	local _oCBase    := NIL
	local _aCBase    := {}
	local _nCBase    := 0
//	local _aAssoc    := {}
	local _nAssoc    := 0
	local _nTotCBase := 0
	local _sTMIntegP := '20'
	local _oCtaCorr  := NIL
	local _nVlInteg  := 0
	local _nPerInteg := 5  // Cfe. estatuto, sempre 5% da producao.
	local _sMemCalc  := ""
	local _aSimul    := {}

	u_logsx1 (cPerg)

	// Busca codigo base de todos os associados 'candidatos a integralizar'.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SA2.A2_VACBASE, SA2.A2_VALBASE,"
	_oSQL:_sQuery +=       " (SELECT COUNT (*)"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("SZI") + " SZI, "
	_oSQL:_sQuery +=                     RetSQLName ("SA2") + " SA2_2 "
	_oSQL:_sQuery +=         " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SZI.ZI_TM      = '" + _sTMIntegP + "'"
	_oSQL:_sQuery +=           " AND SA2_2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SA2_2.A2_COD     = SZI.ZI_ASSOC"  // Pode ter integralizado com codigo diferente do codigo base.
	_oSQL:_sQuery +=           " AND SA2_2.A2_LOJA    = SZI.ZI_LOJASSO"
	_oSQL:_sQuery +=           " AND SA2_2.A2_VACBASE = SA2.A2_VACBASE"
	_oSQL:_sQuery +=           " AND SA2_2.A2_VALBASE = SA2.A2_VALBASE) AS FEITAS"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_VACBASE + SA2.A2_VALBASE BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
	
	// Para ser associado, deve ter movimento na tabela SZI.
	_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
	_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                  " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                  " AND SZI.ZI_LOJASSO = SA2.A2_LOJA)"
	
	// Associado que recebeu transferencia de saldo de cota capital nao
	// precisa integralizar, pois, pelo estatuto, somente podem ser
	// transferidas cotas quando ja totalmente integralizadas.
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                    " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                      " AND SZI.ZI_ASSOC   = SA2.A2_COD"
	_oSQL:_sQuery +=                      " AND SZI.ZI_TM      = '18'"
	_oSQL:_sQuery +=                      " AND SZI.ZI_LOJASSO = SA2.A2_LOJA)"

	// Apenas para quem se associou a partir desta data. Para os antigos vamos assumir
	// que foi integralizado, uma vez que nao havia nenhum controle formal.
	_oSQL:_sQuery +=   " AND dbo.VA_ASSOC_DT_ENTRADA (SA2.A2_VACBASE, SA2.A2_VALBASE, " + dtos (dDataBase) + ") >= '20111101'"
	
	// Este associado integralizou tudo numa parcela somente, em 28/05/2015
	_oSQL:_sQuery +=   " AND SA2.A2_VACBASE != '004994'"

	_oSQL:_sQuery += " ORDER BY SA2.A2_VACBASE, SA2.A2_VALBASE"
	_oSQL:Log ()
	_aCBase := aclone (_oSQL:Qry2Array (.F., .F.))

	procregua (len (_aCBase))
	
	_mvsimb1 := GetMv("MV_SIMB1")
	
	for _nCBase = 1 to len (_aCBase)
		incproc ()
		u_log2 ('info', 'Cod. base associado: ' + _aCBase [_nCBase, 1] + '/' + _aCBase [_nCBase, 2])

		// A integralizacao deve ser feita sempre em 3 parcelas. Se o associado desejar fazer toda
		// a integralizacao em uma unica safra (15%), ainda assim deverao ser gerados 3 lancamentos,
		// pois eh a forma que tenho para saber se estah completo.
		if _aCBase [_nCBase, 3] >= 3
			u_log2 ('info', 'Codigo base jah fez ' + cvaltochar (_aCBase [_nCBase, 3]) + ' integralizacoes')
			loop
		endif

		// Instancia o codigo base para buscar os demais codigos que podem estar abaixo dele.
		_oCBase := ClsAssoc():New (_aCBase [_nCBase, 1], _aCBase [_nCBase, 2])
		_nTotCBase = 0

		// Busca notas de compra de safra.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SUM (VALOR_TOTAL)"
		_oSQL:_sQuery +=  " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery += " WHERE SAFRA = '" + mv_par05 + "'"
		_oSQL:_sQuery +=   " AND TIPO_NF IN ('C', 'V')"
		_oSQL:_sQuery +=   " AND CODBASEASSOC  = '" + _aCBase [_nCBase, 1] + "'"
		_oSQL:_sQuery +=   " AND LOJABASEASSOC = '" + _aCBase [_nCBase, 2] + "'"
		_oSQL:Log ()
		_nTotCBase = _oSQL:RetQry (1, .f.)
	
		// Calcula valor a integralizar e gera lancamento na conta corrente.
		_nVlInteg = round (_nTotCBase * _nPerInteg / 100, 2)
		u_log2 ('info', 'Total safra do cod/loja base ' + _aCBase [_nCBase, 1] + '/' + _aCBase [_nCBase, 2] + ':' + cvaltochar (_nTotCBase) + ' --> Valor a integralizar:' + cvaltochar (_nVlInteg))
		if _nVlInteg > 0

			// Prepara texto com memoria de calculo para gravar nas observacoes do lancamento.
			_sMemCalc := "Vl.ref.integralizacao de capital de " + cvaltochar (_nPerInteg) + "% "
			_sMemCalc += "sobre o valor de compra (" + _mvsimb1 + " " + alltrim (transform (_nTotCBase, "@E 999,999,999,999.99")) + ") "
			_sMemCalc += "da safra " + mv_par05 + " "
			//_sMemCalc += "calculado com base nas " + iif (mv_par06 == 1, "pre-", "") + "notas de compra "
			_sMemCalc += "calculado com base nas notas de compra "
			if len (_oCBase:aCodigos) == 1
				_sMemCalc += "do associado."
			else
				u_log2 ('info', 'mais de 1 codigo')
				_sMemCalc += "dos seguintes codigos/lojas de associados, que encontram-se abaixo deste codigo/loja base:"
				for _nAssoc = 1 to len (_oCBase:aCodigos)
					_sMemCalc += _oCBase:aCodigos [_nAssoc] + '/' + _oCBase:aLojas [_nAssoc] + iif (_nAssoc < len (_oCBase:aCodigos), ', ', '')
				next
			endif
			u_log2 ('info', _sMemCalc)

			zx5 -> (dbsetorder (2))  // ZX5_FILIAL+ZX5_TABELA+ZX5_10COD
			if ! zx5 -> (dbseek (xfilial ("ZX5") + "10" + _sTMIntegP, .F.))
				u_help ("Tipo de movimento '" + _sTMIntegP + "' nao cadastrado na tabela de movimentos de conta corrente.",, .T.)
				exit
			else
				_oCtaCorr := ClsCtaCorr():New ()
				_oCtaCorr:Assoc    = _oCBase:Codigo
				_oCtaCorr:Loja     = _oCBase:Loja
				_oCtaCorr:TM       = _sTMIntegP
				_oCtaCorr:DtMovto  = dDataBase
				_oCtaCorr:Valor    = _nVlInteg
				_oCtaCorr:SaldoAtu = _nVlInteg
				_oCtaCorr:Usuario  = cUserName
				_oCtaCorr:Histor   = 'INTEGRALIZACAO ' + cvaltochar (_nPerInteg) + '% PRODUCAO SAFRA ' + mv_par05
				_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
				_oCtaCorr:Doc      = strzero(day(_oCtaCorr:DtMovto),2)+strzero(month(_oCtaCorr:DtMovto),2)+substr (strzero(year(_oCtaCorr:DtMovto),4), 3)
				_oCtaCorr:Serie    = zx5 -> zx5_10Pref
				_oCtaCorr:Obs      = _sMemCalc
				
				if _oCtaCorr:PodeIncl ()
					if mv_par06 == 1  // Gerar dados
						if ! _oCtaCorr:Grava (.F., .F.)
							U_help ("Erro na atualizacao da conta corrente para o associado '" + _oCBase:Codigo + '/' + _oCBase:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .T.)
						endif
					else  // Apenas simulacao
						aadd (_aSimul, {'Cod.base ' + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja, ;
										fbuscacpo ("SA2", 1, xfilial ("SA2") + _oCtaCorr:Assoc + _oCtaCorr:Loja, "A2_NOME"), ;
										_oCtaCorr:Valor, ;
										_sMemCalc})
					endif
				else
					U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + _oCBase:Codigo + '/' + _oCBase:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .T.)
				endif
			endif
		endif
	next
	
	if len (_aSimul) > 0
		u_log2 ('info', 'Resultado da simulacao')
		u_log2 ('info', _aSimul)
		u_showarray (_aSimul)
	endif
Return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                             Help
	aadd (_aRegsPerg, {01, "Cod. base associado inicial   ", "C", 6,  0,  "",   "SA2_AS", {},                                ""})
	aadd (_aRegsPerg, {02, "Loja base associado inicial   ", "C", 2,  0,  "",   "      ", {},                                ""})
	aadd (_aRegsPerg, {03, "Cod. base associado final     ", "C", 6,  0,  "",   "SA2_AS", {},                                ""})
	aadd (_aRegsPerg, {04, "Loja base associado final     ", "C", 2,  0,  "",   "      ", {},                                ""})
	aadd (_aRegsPerg, {05, "Safra                         ", "C", 4,  0,  "",   "      ", {},                                ""})
	aadd (_aRegsPerg, {06, "Simular ou gerar dados reais  ", "N", 1,  0,  "",   "      ", {"Gerar dados", "Simular"},        ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
