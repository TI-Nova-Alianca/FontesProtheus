//  Programa...: VA_CLIPER
//  Autor......: Cláudia Lionço
//  Data.......: 25/06/2021
//  Descricao..: Consulta de títulos vencidos - Consulta 
//
// #TipoDePrograma    #Consulta
// #Descricao         #Relatório de títulos vencidos 
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//

User Function VA_CLIPER()
    Local _sTipo    := ""
    Local _aTitulos := {}
    Local _aDados   := {}
    Private cPerg   := "VA_CLIPER"

    
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
    _sTipo := RetornaTipo()
    _aDados:= _BuscaDadosSQL(_sTipo,'1', _aDados ) // Dados
    _aDados:= _BuscaDadosSQL(_sTipo,'2', _aDados ) // Totais

    If Len(_aDados) > 0
        AADD(_aTitulos, "FILIAL")
        AADD(_aTitulos, "TITULO")
        AADD(_aTitulos, "CLIENTE")
        AADD(_aTitulos, "NOME")
        AADD(_aTitulos, "EMISSÃO")
        AADD(_aTitulos, "VENCIMENTO REAL")
        AADD(_aTitulos, "ULTIMA BAIXA")
        AADD(_aTitulos, "VALOR ORIGINAL")
        AADD(_aTitulos, "VALOR VENCIDO")
        //
        u_showarray(_aDados, "Consulta de títulos em Atraso por Período", _aTitulos)
    Else
        u_help('Sem dados no período para serem mostrados!')
    EndIf
			
Return
//
// --------------------------------------------------------------------------
// Retorna os tipos não inclusos
Static Function _BuscaDadosSQL(_sTipo,_sTP, _aDados) 
    Local _aRet := {}

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	WITH C "
    _oSQL:_sQuery += "	AS "
    _oSQL:_sQuery += "	(SELECT "
    _oSQL:_sQuery += "	
    _oSQL:_sQuery += "			E1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "		   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO "
    _oSQL:_sQuery += "		   ,SE1.E1_CLIENTE + '/' + E1_LOJA AS CLIENTE "
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += "		   ,SE1.E1_VENCREA AS VENC_REAL "
    _oSQL:_sQuery += "		   ,SE1.E1_BAIXA AS DATA_ULT_BAIXA "
    _oSQL:_sQuery += "		   ,E1_VALOR AS VALOR_ORIGINAL "
    _oSQL:_sQuery += "		   ,SUM(E5_VALOR) AS TITULOS_VENC "
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += "		INNER JOIN " + RetSQLName ("SE5") + " AS SE5"
    _oSQL:_sQuery += "			ON SE5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SE5.E5_FILIAL = SE1.E1_FILIAL "
    _oSQL:_sQuery += "			AND SE5.E5_NUMERO = SE1.E1_NUM "
    _oSQL:_sQuery += "			AND SE5.E5_PREFIXO = SE1.E1_PREFIXO "
    _oSQL:_sQuery += "			AND SE5.E5_PARCELA = SE1.E1_PARCELA "
    _oSQL:_sQuery += "			AND SE5.E5_CLIFOR = SE1.E1_CLIENTE "
    _oSQL:_sQuery += "			AND SE5.E5_LOJA = SE1.E1_LOJA "
    _oSQL:_sQuery += "			AND E5_TIPODOC IN ('VL', 'CP', 'BA', 'DC') "
    _oSQL:_sQuery += "			AND E5_DATA >= '" + DTOS(mv_par07) + "' "
    _oSQL:_sQuery += "			AND E5_VALOR <> 0 "
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		GROUP BY E1_FILIAL "
    _oSQL:_sQuery += "				,SE1.E1_NUM "
    _oSQL:_sQuery += "				,SE1.E1_PREFIXO "
    _oSQL:_sQuery += "				,SE1.E1_PARCELA "
    _oSQL:_sQuery += "				,SE1.E1_CLIENTE "
    _oSQL:_sQuery += "				,E1_LOJA "
    _oSQL:_sQuery += "				,SE1.E1_EMISSAO "
    _oSQL:_sQuery += "				,SE1.E1_VENCREA "
    _oSQL:_sQuery += "				,SE1.E1_BAIXA "
    _oSQL:_sQuery += "				,E1_VALOR "
    _oSQL:_sQuery += "		UNION ALL "
    _oSQL:_sQuery += "		SELECT "
    _oSQL:_sQuery += "			E1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "		   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO "
    _oSQL:_sQuery += "		   ,SE1.E1_CLIENTE + '/' + E1_LOJA AS CLIENTE "
    _oSQL:_sQuery += "		   ,SE1.E1_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += "		   ,SE1.E1_VENCREA AS VENC_REAL "
    _oSQL:_sQuery += "		   ,SE1.E1_BAIXA AS DATA_ULT_BAIXA "
    _oSQL:_sQuery += "		   ,E1_VALOR AS VALOR_ORIGINAL "
    _oSQL:_sQuery += "		   ,SE1.E1_SALDO AS TITULOS_VENC "
    _oSQL:_sQuery += "		FROM " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += "		WHERE SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "		AND SE1.E1_FILIAL BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "		AND SE1.E1_TIPO NOT IN (" + alltrim(_sTipo) + ")"
    _oSQL:_sQuery += "		AND SE1.E1_EMISSAO BETWEEN '20030101' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND SE1.E1_VENCREA BETWEEN '" + DTOS(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "		AND E1_SALDO > 0) "
    If _sTP == '1'
        _oSQL:_sQuery += "	SELECT "
        _oSQL:_sQuery += "		FILIAL "
        _oSQL:_sQuery += "	   ,TITULO "
        _oSQL:_sQuery += "	   ,CLIENTE "
        _oSQL:_sQuery += "	   ,SA1.A1_NOME AS NOME "
        _oSQL:_sQuery += "	   ,EMISSAO "
        _oSQL:_sQuery += "	   ,VENC_REAL "
        _oSQL:_sQuery += "	   ,DATA_ULT_BAIXA "
        _oSQL:_sQuery += "	   ,VALOR_ORIGINAL "
        _oSQL:_sQuery += "	   ,TITULOS_VENC "
        _oSQL:_sQuery += "	FROM C "
        _oSQL:_sQuery += "	INNER JOIN SA1010 SA1 "
        _oSQL:_sQuery += "		ON SA1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "			AND SA1.A1_COD + '/' + SA1.A1_LOJA = CLIENTE "
        _aRet  := _oSQL:Qry2Array ()
        _aDados := AClone(_aRet)
    Else
        _oSQL:_sQuery += "	SELECT "
        _oSQL:_sQuery += "		'TOTAIS' "
        _oSQL:_sQuery += "	   ,'' "
        _oSQL:_sQuery += "	   ,'' "
        _oSQL:_sQuery += "	   ,'' "
        _oSQL:_sQuery += "	   ,'' "
        _oSQL:_sQuery += "	   ,'' "
        _oSQL:_sQuery += "	   ,'' " 
        _oSQL:_sQuery += "	   ,SUM(VALOR_ORIGINAL) "
        _oSQL:_sQuery += "	   ,SUM(TITULOS_VENC) "
        _oSQL:_sQuery += "	FROM C "
        _oSQL:_sQuery += "	INNER JOIN SA1010 SA1 "
        _oSQL:_sQuery += "		ON SA1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += "			AND SA1.A1_COD + '/' + SA1.A1_LOJA = CLIENTE "
        _aRet  := _oSQL:Qry2Array ()

        If Len(_aRet) > 0
        AADD(_aDados, { _aRet[1,1],;
                        _aRet[1,2],;
                        _aRet[1,3],;
                        _aRet[1,4],;
                        _aRet[1,5],;
                        _aRet[1,6],;
                        _aRet[1,7],;
                        _aRet[1,8],;
                        _aRet[1,9]})
        EndIf
    EndIf
Return _aDados
//
// --------------------------------------------------------------------------
// Retorna os tipos não inclusos
Static Function RetornaTipo()
    Local _sTipo   := ""
    Local _aTipos  := {}
    Local _aTipos2 := {}
    Local y        := 0

    _aTipos := STRTOKARR(mv_par05,",")

    For y:=1 to Len(_aTipos)
        _sTipo += "'" + alltrim(_aTipos[y]) + "'"
        If y < Len(_aTipos)
            _sTipo += ","
        EndIf
    Next

    _aTipos2 := STRTOKARR(mv_par06,",")

    For y:=1 to Len(_aTipos2)
        _sTipo += ",'" + alltrim(_aTipos2[y]) + "'"
    Next
Return _sTipo
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO  TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de        ", "C",  2, 0,  "",   "   ", {},              "Filial de"})
    aadd (_aRegsPerg, {02, "Filial ate       ", "C",  2, 0,  "",   "   ", {},              "Filial até"})
    aadd (_aRegsPerg, {03, "Dt.Venc.real de  ", "D",  8, 0,  "",   "   ", {},              "Data de vencimento de"})
    aadd (_aRegsPerg, {04, "Dt.Venc.real até ", "D",  8, 0,  "",   "   ", {},              "Data de vencimento até"})
    aadd (_aRegsPerg, {05, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},              "Incluir os tipos que não serão impressos, através de ;"})
    aadd (_aRegsPerg, {06, "Tipo não incluso ", "C", 20, 0,  "",   "   ", {},              "Incluir os tipos que não serão impressos, através de ;"})
    aadd (_aRegsPerg, {07, "Dt.Base p/ atraso", "D",  8, 0,  "",   "   ", {},              "Data base para atraso"})

    U_ValPerg (cPerg, _aRegsPerg)
Return
