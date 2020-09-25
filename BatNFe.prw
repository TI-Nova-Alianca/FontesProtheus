// Programa:   BatNFe
// Autor:      Robert Koch
// Data:       12/03/2010
// Descricao:  Verifica inconsistencias nas NFe.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 28/10/2010 - Robert - Melhorada mensagem (incluida empresa/filial).
// 21/12/2010 - Robert - Busca codigo da entidade direto da tabela SPED001.
// 26/02/2013 - Elaine - Incluida rotina para avisar existencia de pre-notas (D1_TES = '')
// 28/04/2015 - Robert - Passa a verificar NF-e nao autorizadas em todas as filiais.
//                     - Passa a usar o metodo ConsAutFP da classe ClsNFe.
// 28/09/2015 - Robert - Passa a buscar status da SEFAZ direto das tabelas do SPED e nao mais da classe ClsNFe.
// 04/10/2017 - Robert - Retorna mensagem para o batch com numero de avisos enviados.
// 17/11/2017 - Robert - Verificacao de pre-notas a classificar migrada para classe ClsVerif.
//

// --------------------------------------------------------------------------
user function BatNFe ()
	local _sTitulo   := ""
	local _sMsg      := ""
	local _oSQL      := NIL
	local _sQuery    := ""
	local _sOcorr    := ""
	local _oNFe      := NIL
	local _aAutori   := {}
	local _nQtAvisos := 0
	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()                                            


	// Monta clausula WHERE a ser usada em mais de um local, para geracao de uma lista das chaves
	// de NF-e e sua ultima ocorrencia protocolada junto a SEFAZ.
	_sOcorr := ""
	_sOcorr +=        " OCORRENCIAS.CSTAT_SEFR, OCORRENCIAS.XMOT_SEFR"
	_sOcorr += " FROM " + RetSQLName ("SF2") + " SF2 "
	_sOcorr +=     " LEFT JOIN (SELECT NFE_CHV, CSTAT_SEFR,	RTRIM(XMOT_SEFR) AS XMOT_SEFR"
	_sOcorr +=                  " FROM SPED054 S"
	_sOcorr +=                 " WHERE S.R_E_C_N_O_ = (SELECT TOP 1 R_E_C_N_O_"
	_sOcorr +=                                         " FROM SPED054 ULTIMA"
	_sOcorr +=                                        " WHERE ULTIMA.NFE_PROT != ''"
	_sOcorr +=                                          " AND ULTIMA.NFE_CHV = S.NFE_CHV"
	_sOcorr +=                                        " ORDER BY DTREC_SEFR DESC, HRREC_SEFR DESC)"
	_sOcorr +=                " ) AS OCORRENCIAS"

	// Verifica NF-e's de saida nao autorizadas pela SEFAZ.
	_sMsg = ""
	_sQuery := ""
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " WITH C AS ("
	_oSQL:_sQuery += " SELECT F2_FILIAL AS FILIAL, F2_DOC AS DOC, F2_SERIE AS SERIE, F2_CHVNFE AS CHAVE, "
	_oSQL:_sQuery +=        " OCORRENCIAS.CSTAT_SEFR, OCORRENCIAS.XMOT_SEFR"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2 "
	_oSQL:_sQuery +=     " LEFT JOIN (SELECT NFE_CHV, CSTAT_SEFR,	RTRIM(XMOT_SEFR) AS XMOT_SEFR"
	_oSQL:_sQuery +=                  " FROM SPED054 S"
	_oSQL:_sQuery +=                 " WHERE S.R_E_C_N_O_ = (SELECT TOP 1 R_E_C_N_O_"
	_oSQL:_sQuery +=                                         " FROM SPED054 ULTIMA"
	_oSQL:_sQuery +=                                        " WHERE ULTIMA.NFE_PROT != ''"
	_oSQL:_sQuery +=                                          " AND ULTIMA.NFE_CHV = S.NFE_CHV"
	_oSQL:_sQuery +=                                        " ORDER BY DTREC_SEFR DESC, HRREC_SEFR DESC)"
	_oSQL:_sQuery +=                " ) AS OCORRENCIAS"
	_oSQL:_sQuery +=               " ON OCORRENCIAS.NFE_CHV = SF2.F2_CHVNFE"
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND F2_EMISSAO BETWEEN '" + dtos (dDataBase - 10) + "' AND '" + dtos (dDataBase - 1) + "'"  // Ultimos dias
	_oSQL:_sQuery +=   " AND F2_ESPECIE = 'SPED'"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery +=  " WHERE CSTAT_SEFR != '100'"
	_oSQL:_sQuery +=  " ORDER BY FILIAL, DOC""
	u_log (_oSQL:_squery)
	if len (_oSQL:Qry2Array (.F., .T.)) > 1
		_sTitulo = 'Notas de saida com problema na SEFAZ"
		_sMsg = _oSQL:Qry2HTM (_sTitulo, NIL, "", .F., .T.)
		u_log (_sMsg)
		_nQtAvisos += U_ZZUNU ({'019'}, _sTitulo, _sMsg, .F., cEmpAnt, cFilAnt)
	endif

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " WITH C AS ("
	_oSQL:_sQuery += " SELECT F1_FILIAL AS FILIAL, F1_DOC AS DOC, F1_SERIE AS SERIE, F1_CHVNFE AS CHAVE,"
	_oSQL:_sQuery +=        " OCORRENCIAS.CSTAT_SEFR, OCORRENCIAS.XMOT_SEFR"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF1") + " SF1 "
	_oSQL:_sQuery +=     " LEFT JOIN (SELECT NFE_CHV, CSTAT_SEFR,	RTRIM(XMOT_SEFR) AS XMOT_SEFR"
	_oSQL:_sQuery +=                  " FROM SPED054 S"
	_oSQL:_sQuery +=                 " WHERE S.R_E_C_N_O_ = (SELECT TOP 1 R_E_C_N_O_"
	_oSQL:_sQuery +=                                         " FROM SPED054 ULTIMA"
	_oSQL:_sQuery +=                                        " WHERE ULTIMA.NFE_PROT != ''"
	_oSQL:_sQuery +=                                          " AND ULTIMA.NFE_CHV = S.NFE_CHV"
	_oSQL:_sQuery +=                                        " ORDER BY DTREC_SEFR DESC, HRREC_SEFR DESC)"
	_oSQL:_sQuery +=                " ) AS OCORRENCIAS"
	_oSQL:_sQuery +=               " ON OCORRENCIAS.NFE_CHV = SF1.F1_CHVNFE"
	_oSQL:_sQuery += " WHERE SF1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND F1_EMISSAO BETWEEN '" + dtos (dDataBase - 10) + "' AND '" + dtos (dDataBase - 1) + "'"  // Ultimos dias
	_oSQL:_sQuery +=   " AND F1_ESPECIE = 'SPED'"
	_oSQL:_sQuery +=   " AND F1_FORMUL  = 'S'"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery +=  " WHERE CSTAT_SEFR != '100'"
	_oSQL:_sQuery +=  " ORDER BY FILIAL, DOC""
	u_log (_oSQL:_squery)
	if len (_oSQL:Qry2Array (.F., .T.)) > 1
		_sTitulo = 'Notas de saida com problema na SEFAZ"
		_sMsg = _oSQL:Qry2HTM (_sTitulo, NIL, "", .F., .T.)
		u_log (_sMsg)
		_nQtAvisos += U_ZZUNU ({'019'}, _sTitulo, _sMsg, .F., cEmpAnt, cFilAnt)
	endif

/*
	// Verifica se existem pre-notas fiscais de entrada sem classificacao (campo D1_TES nao preenchido)
	_sMsg = ""
	_sQuery := ""	
	_sQuery += " SELECT D1_DOC AS DOC, D1_SERIE SER,  D1_FILIAL AS FILIAL, D1_FORNECE AS FORN, D1_LOJA, D1_EMISSAO EMISS "
	_sQuery += " FROM " + RetSQLName ("SD1") + " SD1  "
	_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += " AND D1_TES = '' "
	_sQuery += " GROUP BY D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO "
	_sQuery += " ORDER BY D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO "
	u_log (_squery)
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), "_prenf",.F.,.F.)
	do while ! _prenf -> (eof ())
		_sMsg += "NF " + _prenf -> doc + " - " + _prenf -> ser + "   Filial: " + _prenf -> filial + "   Fornec: " + _prenf -> forn + "   Dt Emissao: " + DToC(SToD(_prenf -> emiss))    + chr (13) + chr (10)
		_prenf -> (dbskip ())
	enddo
*/

	if ! empty (_sMsg)
		u_log (_sMsg)
		_nQtAvisos += U_ZZUNU ({'019'}, "Pre-notas entrada a classificar", _sMsg)
	endif

	_oBatch:Mensagens = cvaltochar (_nQtAvisos) + " avisos enviados"
	u_logFim ()
	_sArqLog = _sArqLog2
return
