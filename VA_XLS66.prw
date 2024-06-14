// Programa...: VA_XLS66
// Autor......: Cláudia Lionço
// Data.......: 14/05/2024
// Descricao..: Relatório de destino das uvas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de destino das uvas
// #PalavrasChaves    #custos #uva #op
// #TabelasPrincipais #VA_VDADOS_OP #VA_VOPS_DE_VINIFICACAO #SD3 #SB1
// #Modulos           #EST 
//
// Historico de alteracoes:
// 
// --------------------------------------------------------------------------
User Function VA_XLS66(_lAutomat)
	Local cCadastro := "Relatório de destino das uvas"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VA_XLS66"
	_ValidPerg()
	If Pergunte(cPerg,.T.)

        if _lAuto != NIL .and. _lAuto
            Processa( { |lEnd| _Gera() } )
        else
            AADD(aSays,cCadastro)
            AADD(aSays,"")
            AADD(aSays,"")
            AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
            AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
            AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
            FormBatch( cCadastro, aSays, aButtons )
            If nOpca == 1
                Processa( { |lEnd| _Gera() } )
            Endif
        endif
    EndIf
return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Execução da consulta
Static Function _Gera()
	local _oSQL  := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	_oSQL := ClsSQL():New()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   V.FILIAL "
    _oSQL:_sQuery += "    ,PROD_FINAL "
    _oSQL:_sQuery += "    ,V.DESC_PROD_FINAL "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			SUM(D3_QUANT) "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SD3") + " SD3 "
    _oSQL:_sQuery += " 		WHERE SD3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SD3.D3_CF LIKE 'PR%' "
    _oSQL:_sQuery += " 		AND SD3.D3_EMISSAO LIKE '"+ mv_par01 +"%' "
    _oSQL:_sQuery += " 		AND SD3.D3_COD = V.PROD_FINAL "
    _oSQL:_sQuery += " 		AND SD3.D3_ESTORNO = '' "
    _oSQL:_sQuery += " 		AND EXISTS (SELECT "
    _oSQL:_sQuery += " 				* "
    _oSQL:_sQuery += " 			FROM VA_VOPS_DE_VINIFICACAO OPV "
    _oSQL:_sQuery += " 			WHERE OPV.FILIAL = SD3.D3_FILIAL "
    _oSQL:_sQuery += " 			AND OPV.OP = SD3.D3_OP)) "
    _oSQL:_sQuery += " 	AS QT_PRODUZIDA "
    _oSQL:_sQuery += "    ,V.CODIGO "
    _oSQL:_sQuery += "    ,V.DESCRICAO "
    _oSQL:_sQuery += "    ,SUM(QUANT_REAL) QT_REQUIS "
    _oSQL:_sQuery += "    ,SUM(CUSTO) CUSTO_MEDIO "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			B1_CUSTD "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 		WHERE SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SB1.B1_FILIAL = '  ' "
    _oSQL:_sQuery += " 		AND SB1.B1_COD = V.CODIGO) "
    _oSQL:_sQuery += " 	AS CUSTO_REPOS_UNIT "
    _oSQL:_sQuery += " FROM VA_VDADOS_OP V "
    _oSQL:_sQuery += " INNER JOIN VA_VOPS_DE_VINIFICACAO OPV "
    _oSQL:_sQuery += " 	ON OPV.FILIAL IN ('01', '03', '07') "
    _oSQL:_sQuery += " 		AND OPV.PRIMEIRO_MOVTO LIKE '"+ mv_par01 +"%' "
    _oSQL:_sQuery += " 		AND OPV.FILIAL = V.FILIAL "
    _oSQL:_sQuery += " 		AND OPV.OP = V.OP "
    _oSQL:_sQuery += " WHERE V.GRUPO = '0400'  " // somente uvas
    _oSQL:_sQuery += " AND V.TIPO_MOVTO = 'C' "
    _oSQL:_sQuery += " GROUP BY V.FILIAL "
    _oSQL:_sQuery += " 		,PROD_FINAL "
    _oSQL:_sQuery += " 		,V.DESC_PROD_FINAL "
    _oSQL:_sQuery += " 		,CODIGO "
    _oSQL:_sQuery += " 		,V.DESCRICAO "
    _oSQL:_sQuery += " ORDER BY V.FILIAL "
    _oSQL:_sQuery += " 		, PROD_FINAL "
    _oSQL:_sQuery += " 		, V.DESC_PROD_FINAL "
    _oSQL:_sQuery += " 		, CODIGO "
    _oSQL:_sQuery += " 		, V.DESCRICAO " 
    _oSQL:Log()
    _oSQL:ArqDestXLS = 'VA_XLS66'
    _oSQL:Qry2XLS (.F., .F., .F.)

return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Ano Ref.      ", "C", 4, 0,  "",   "   ", {}, ""})
	U_ValPerg(cPerg, _aRegsPerg, {}, _aDefaults)
Return
