// Programa.: BatVerFin
// Autor....: Cláudia Lionço
// Data.....: 15/09/2021
// Descricao: Batch de verificacoes gerais do financeiro
//            Criado para ser executado via batch.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Batch de verificacoes gerais do financeiro
// #PalavasChave      #verificacoes #validacoes #avisos #financeiro
// #TabelasPrincipais 
// #Modulos           #FIN

// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------------------------
User Function BatVerFin ()
    local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

    u_log2 ('info', 'Iniciando execucao das verificacoes financeiro')

    // Verifica se existe movimentos(baixas) de titulos usando verbas, sem a verba estar baixada. GLPI: 10973
    _VerifVerba()

	u_log2 ('info', 'Finalizando execucao das verificacoes finnceiro')
    U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return
//
// ----------------------------------------------------------------------------------------------------
// Verificação de verba utilizada
Static Function  _VerifVerba()
    Local _oSQL  := NIL
    Local _aCols := {}

    // cabeçalho
    aadd (_aCols, {'Filial'     ,    'left' ,  ''})
    aadd (_aCols, {'Título'     ,    'left' ,  ''})
    aadd (_aCols, {'Prefixo'    ,    'left' ,  ''})
    aadd (_aCols, {'Parcela'    ,    'left' ,  ''})
    aadd (_aCols, {'Verba'      ,    'left' ,  ''})
    aadd (_aCols, {'Histórico'  ,    'left' ,  ''})
    aadd (_aCols, {'Valor'      ,    'right' ,  ''})

    // conteúdo
    _oSQL := ClsSQL():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		E5_FILIAL AS FILIAL "
    _oSQL:_sQuery += " 	   ,E5_NUMERO AS TITULO "
    _oSQL:_sQuery += " 	   ,E5_PREFIXO AS PREFIXO "
    _oSQL:_sQuery += " 	   ,E5_PARCELA AS PARCELA "
    _oSQL:_sQuery += " 	   ,REPLICATE('0', 6 - LEN(SUBSTRING(E5_HISTOR, 9, 6))) + RTRIM(SUBSTRING(E5_HISTOR, 9, 6)) AS VERBA "
    _oSQL:_sQuery += " 	   ,E5_HISTOR AS HISTORICO "
    _oSQL:_sQuery += " 	   ,E5_VLDESCO AS VALOR "
    _oSQL:_sQuery += " 	   ,E5_DATA AS DT "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE5") + " AS SE5 "
    _oSQL:_sQuery += " 	WHERE SE5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND E5_HISTOR LIKE '%DESC VB%') "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   FILIAL "
    _oSQL:_sQuery += "    ,TITULO "
    _oSQL:_sQuery += "    ,PREFIXO "
    _oSQL:_sQuery += "    ,PARCELA "
    _oSQL:_sQuery += "    ,VERBA "
    _oSQL:_sQuery += "    ,HISTORICO "
    _oSQL:_sQuery += "    ,VALOR "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZA5") + " AS ZA5 "
    _oSQL:_sQuery += " 	ON (ZA5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND ZA5.ZA5_NUM = VERBA "
    _oSQL:_sQuery += " 			AND ZA5.ZA5_DOC = TITULO "
    _oSQL:_sQuery += " 			AND ZA5.ZA5_PARC = PARCELA) "
    _oSQL:_sQuery += " WHERE DT = '" + dtos (date()) + "'"
    _oSQL:_sQuery += " AND ZA5_NUM IS NULL "

    u_log (_oSQL:_sQuery)
    If len (_oSQL:Qry2Array (.T., .F.)) > 0

        _sMsg = _oSQL:Qry2HTM ("Data: " + dtoc(date()), _aCols, "", .F.)
        u_log (_sMsg)

        //U_SendMail ('compras@novaalianca.coop.br', "Itens recebidos no dia anterior", _sMsg, {})
        U_ZZUNU ({'122'}, "Verif. Financeiro - Baixas de titulos sem a baixa da verba", _sMsg, .F., cEmpAnt, cFilAnt, "") 
    EndIf
Return
