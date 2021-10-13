// Programa...: VA_ZBCBI
// Autor......: Cláudia Lionço
// Data.......: 18/12/2019 
// Descricao..: Exporta dados de materiais para tabela BI - VA_MATERIAIS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Exporta dados de materiais para tabela BI - VA_MATERIAIS
// #PalavasChave      #materiais #planejamento_de_produção 
// #TabelasPrincipais #ZBC #VA_MATERIAIS
// #Modulos   		  #PCP 
//
// Historico de alteracoes:
// 11/10/2021 - Claudia - Criada rotina para geracao de dados de materiais. GLPI: 11035
//
// ------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_ZBCBI()
    Local cQuery    := ""	
	Local nAlx02 	:= 0
	Local nAlx07 	:= 0
	Local nAlx08 	:= 0
	Local nAlx90 	:= 0
	Local _lContinua:= .T.
    Local _lCont    := .F.
    Local _x        := 0
	Private sDesc
	Private sTipo
	Private cPerg   := "VA_ZBCBI"
	
	_ValidPerg()
    Pergunte(cPerg,.T.)  
	
    _oSQL := ClsSQL ():New ()
    _oSQL:_sQuery := " SELECT "
    _oSQL:_sQuery += " 	COUNT(*) "
    _oSQL:_sQuery += " 	FROM BI_ALIANCA.dbo.VA_MATERIAIS "
    _oSQL:_sQuery += " 	WHERE EVENTO = '" + mv_par03 + "'"
    _oSQL:_sQuery += " 	AND ANO      = '" + mv_par04 + "'"
    _aMat := aclone (_oSQL:Qry2Array ())

    For _x:= 1 to Len(_aMat)
        nQtdItens := _aMat[1,1]
    Next

    If nQtdItens > 0
        _lCont := U_MsgYesNo("Já existem registros do evento no ano informado. Deseja gerar novamente os dados?")

        if _lCont
            _oSQL := ClsSQL ():New ()
            _oSQL:_sQuery := " DELETE "
            _oSQL:_sQuery += " 	    FROM BI_ALIANCA.dbo.VA_MATERIAIS "
            _oSQL:_sQuery += " 	WHERE EVENTO = '" + mv_par03 + "'"
            _oSQL:_sQuery += " 	AND ANO      = '" + mv_par04 + "'"
            if ! _oSQL:Exec ()
                U_help("Erro ao deletar registros " + _oSQL:_sQuery)
                _lCont := .F.
            endif
        endif
    Else
        _lCont := .T.
    EndIf

    If _lCont 
        _aSC := {}
        _aPC := {}
        _aTC := {}
        If alltrim(mv_par05) == ''
            nPar05 := '0'
        Else
            nPar05 := mv_par05
        EndIf
        
        If alltrim(mv_par06) == 'Z' .or. alltrim(mv_par06) == 'z'
            nPar06 := '9'
        Else
            nPar06 := mv_par06
        EndIf

        nDifMes := DateDiffMonth(mv_par01 , mv_par02) 
        nQtdMes := nDifMes + 1
        dDt     := mv_par01
        
        If nQtdMes > 12
            u_help("A quantidade de meses para pesquisa não poderá ser mais que 12 meses. A quantidade por mês não será efetuada!")
            _lContinua := .F.
        EndIf

        If _lContinua == .T.
            cQuery := " WITH C AS ("
            cQuery += " SELECT"
            cQuery += " 	COMPONENTE"
            cQuery += "    ,MES01 = SUM(CASE WHEN MES = 1 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES02 = SUM(CASE WHEN MES = 2 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES03 = SUM(CASE WHEN MES = 3 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES04 = SUM(CASE WHEN MES = 4 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES05 = SUM(CASE WHEN MES = 5 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES06 = SUM(CASE WHEN MES = 6 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES07 = SUM(CASE WHEN MES = 7 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES08 = SUM(CASE WHEN MES = 8 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES09 = SUM(CASE WHEN MES = 9 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES10 = SUM(CASE WHEN MES = 10 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES11 = SUM(CASE WHEN MES = 11 THEN QNT_PROD ELSE 0 END)"
            cQuery += "    ,MES12 = SUM(CASE WHEN MES = 12 THEN QNT_PROD ELSE 0 END)"
            cQuery += " FROM dbo.VA_ZBCMAT('"+ DTOS(mv_par01) +"', '"+ DTOS(mv_par02) + "', '"+ mv_par03 +"', '"+ mv_par03 +"', '"+ mv_par04 +"', '"+mv_par04+"', '"+nPar05+"', '"+nPar06+"')"
            cQuery += " GROUP BY COMPONENTE"
            cQuery += " ) "
            cQuery += " SELECT "
            cQuery += " 	* "
            cQuery += " 	,SB1.B1_TIPO AS TIPOPROD "
            cQuery += "     ,SB1.B1_DESC AS DESCPROD "
            cQuery += " FROM C "
            cQuery += " INNER JOIN SB1010 SB1 "
            cQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
            cQuery += " 		AND SB1.B1_COD = COMPONENTE "
            cQuery += " 		AND B1_TIPO BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
            cQuery += " )"
            cQuery += " ORDER BY COMPONENTE"

            DbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
            TRA->(DbGotop())
        
            While TRA->(!Eof())
                If alltrim(TRA->TIPOPROD) == 'MO'
                    nAlx02 := 0
                    nAlx03 := 0
                    nAlx07 := 0
                    nAlx08 := 0
                    nAlx90 := 0
                    nSC    := 0
                    nPC    := 0
                    nTerc  := 0
                Else
                    nAlx02 := U_ZBCBSaldo(TRA -> COMPONENTE ,'02')
                    nAlx03 := U_ZBCBSaldo(TRA -> COMPONENTE ,'03')
                    nAlx07 := U_ZBCBSaldo(TRA -> COMPONENTE ,'07')
                    nAlx08 := U_ZBCBSaldo(TRA -> COMPONENTE ,'08')
                    nAlx90 := U_ZBCBSaldo(TRA -> COMPONENTE ,'90')
                    nSC    := U_ZBCBSC(TRA -> COMPONENTE)
                    nPC    := U_ZBCBPC(TRA -> COMPONENTE)
                    nTerc  := U_ZBCBTer(TRA -> COMPONENTE)
                EndIf

                _oSQL := ClsSQL ():New ()
                _oSQL:_sQuery := " INSERT INTO BI_ALIANCA.dbo.VA_MATERIAIS "
                _oSQL:_sQuery += "      (EVENTO,ANO,COMPONENTE,JANEIRO,FEVEREIRO,MARCO,ABRIL,MAIO,JUNHO"
                _oSQL:_sQuery += "      ,JULHO,AGOSTO,SETEMBRO,OUTUBRO,NOVEMBRO,DEZEMBRO,ALMOX02,ALMOX03,ALMOX07,ALMOX08,ALMOX90,SOLICIT_COMPRA,PEDIDO,TERCEIROS)"
                _oSQL:_sQuery += " VALUES "
                _oSQL:_sQuery += "	    ('" + mv_par03           + "'"
                _oSQL:_sQuery += "      ,'" + mv_par04           + "'"
                _oSQL:_sQuery += "      ,'" + TRA->COMPONENTE    + "'"
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES01,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES02,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES03,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES04,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES05,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES06,2)) 
                _oSQL:_sQuery += "	    ," + cvaltochar(round(TRA->MES07,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES08,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES09,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES10,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES11,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(TRA->MES12,2)) 
                _oSQL:_sQuery += "      ," + cvaltochar(round(nAlx02,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nAlx03,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nAlx07,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nAlx08,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nAlx90,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nSC,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nPC,2))
                _oSQL:_sQuery += "      ," + cvaltochar(round(nTerc,2)) 
                _oSQL:_sQuery += ") "
                
                nHandle := FCreate("c:\temp\log.txt")
                FWrite(nHandle,_oSQL:_sQuery)
                FClose(nHandle)

                if ! _oSQL:Exec ()
                    U_AvisaTI ("Erro ao criar registro " + _oSQL:_sQuery)
                    _lContinua = .F.
                endif

                DBSelectArea("TRA")
                dbskip()
            Enddo
            TRA->(DbCloseArea())	
            u_help("Processo de geração de dados finalizado!")	
        EndIf
    EndIf
Return
//
// ------------------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT           TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Data de      	", "D", 8, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {02, "Data até    	", "D", 8, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {03, "Evento          ", "C", 3, 0,    "",  "   ", {}                         				,""})
    aadd (_aRegsPerg, {04, "Ano             ", "C", 4, 0,    "",  "   ", {}                         				,""}) 
    aadd (_aRegsPerg, {05, "Nivel estr. de  ", "C", 1, 0,    "",  "   ", {}											,""})
    aadd (_aRegsPerg, {06, "Nivel estr. ate ", "C", 1, 0,    "",  "   ", {}											,""})
	aadd (_aRegsPerg, {07, "Tipo prod.de    ", "C", 2, 0,    "",  "02", {}                         					,""})
	aadd (_aRegsPerg, {08, "Tipo prod.ate   ", "C", 2, 0,    "",  "02", {}                         					,""})
    
	U_ValPerg (cPerg, _aRegsPerg)
Return
