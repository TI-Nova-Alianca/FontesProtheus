// Programa...: VA_MAPA
// Autor......: Claudia Lionço
// Data.......: 11/01/2023
// Descricao..: Exporta planilha para sistema MAPA
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planilha para sistema MAPA
// #PalavasChave      #MAPA
// #TabelasPrincipais #SB1 #SB9
// #Modulos 		  #COOP
//
// Historico de alteracoes:
// 15/01/2024 - Claudia - Incluida nova coluna de comercialização. GLPI: 14729
// 22/01/2024 - Claudia - Incluida nova coluna com pais de exportação. GLPI: 14776
//
// -----------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_MAPA()
	Local cCadastro := "Exporta planilha para sistema MAPA"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "VA_MAPA"
	_ValidPerg()
	Pergunte(cPerg,.F.)

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

return
//
// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
//
// --------------------------------------------------------------------------
// Gera arquivo
Static Function _Gera()
	local _oSQL   := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

    _dIniAnoAtual := STOD(mv_par01 + '0101')
    _dFinAnoAtual := STOD(mv_par01 + '1231')
    _dIniAnoAnt   := YearSub(_dIniAnoAtual, 1)
    _dFinAnoAnt   := YearSub(_dFinAnoAtual, 1)

    // Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   B1_COD AS PRODUTO "
    _oSQL:_sQuery += "    ,B1_UM AS UNIDADE "
    _oSQL:_sQuery += "    ,B1_LITROS AS CONVERSOR_LITROS "
    _oSQL:_sQuery += "    ,SB1.B1_VARMAAL AS COD_MAPA "
    _oSQL:_sQuery += "    ,ZX5_CAT.ZX5_39DESC AS CATEGORIA "
    _oSQL:_sQuery += "    ,B1_DESC AS DENOMINAÇÃO "
    _oSQL:_sQuery += "    ,B1_TIPO AS TIPO "
    _oSQL:_sQuery += "    ,ZX5_MAR.ZX5_40DESC AS MARCA "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			SUM(B9_QINI) "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SB9") + " SB9 "
    _oSQL:_sQuery += " 		WHERE SB9.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND B9_COD = B1_COD "
    _oSQL:_sQuery += " 		AND B9_DATA = '" + dtos(_dFinAnoAnt) +"') "
    _oSQL:_sQuery += " 	* B1_LITROS "
    _oSQL:_sQuery += " 	AS QTD_EST_ENVASE_ANO_ANT_LITROS "
    _oSQL:_sQuery += "    ,SUM(LITROS) AS QTD_PRODUZIDA_ANO_LITROS "
    _oSQL:_sQuery += "    ,SUM(LITROS) AS QTD_ENVASE_CONSUMIDOR_FINAL_ANO_LITROS "
    _oSQL:_sQuery += "    ,(SELECT "
    _oSQL:_sQuery += " 			SUM(B9_QINI) "
    _oSQL:_sQuery += " 		FROM " + RetSQLName ("SB9") + " SB9 "
    _oSQL:_sQuery += " 		WHERE SB9.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND B9_COD = B1_COD "
    _oSQL:_sQuery += " 		AND B9_DATA = '" + dtos(_dFinAnoAtual) +"') "
    _oSQL:_sQuery += " 	* B1_LITROS AS QTD_ESTOQUE_ANO_ENVASE_LITROS "
    _oSQL:_sQuery += "     ,(SELECT "
    _oSQL:_sQuery += " 			SUM(CASE "
    _oSQL:_sQuery += " 				WHEN F4_MARGEM = '1' THEN QTLITROS "
    _oSQL:_sQuery += " 				WHEN F4_MARGEM = '2' THEN QTLITROS * -1 "
    _oSQL:_sQuery += " 				WHEN F4_MARGEM = '3' THEN 0 " // bonificações
    _oSQL:_sQuery += " 				WHEN F4_MARGEM = '9' THEN 0 " // esse outros sao NF's para outros fins (material para cozinha, por ex)
    _oSQL:_sQuery += " 			END) "
    _oSQL:_sQuery += " 		FROM.BI_ALIANCA.dbo.VA_FATDADOS "
    _oSQL:_sQuery += " 		WHERE EMISSAO BETWEEN '"+ dtos(_dIniAnoAtual) +"' AND '"+ dtos(_dFinAnoAtual) +"' "
    _oSQL:_sQuery += " 		AND PRODUTO = B1_COD) AS QTD_COMERCIALIZADA_ANO "
    _oSQL:_sQuery += "     ,(SELECT
    _oSQL:_sQuery += " 			    YA_DESCR
    _oSQL:_sQuery += " 		    FROM SD2010 SD2
    _oSQL:_sQuery += " 		    INNER JOIN SA1010 SA1
    _oSQL:_sQuery += " 			    ON SA1.D_E_L_E_T_ = ''
    _oSQL:_sQuery += " 			    AND A1_COD = SD2.D2_CLIENTE
    _oSQL:_sQuery += " 			    AND SA1.A1_LOJA = SD2.D2_LOJA
    _oSQL:_sQuery += " 			    AND A1_EST = 'EX'
    _oSQL:_sQuery += " 		    INNER JOIN SYA010 SYA
    _oSQL:_sQuery += " 			    ON SYA.D_E_L_E_T_ = ''
    _oSQL:_sQuery += " 			    AND YA_CODGI = A1_PAIS
    _oSQL:_sQuery += " 		    WHERE SD2.D_E_L_E_T_ = ''
    _oSQL:_sQuery += " 		    AND D2_COD = B1_COD
    _oSQL:_sQuery += " 		    AND SD2.D2_EMISSAO BETWEEN '"+ dtos(_dIniAnoAtual) +"' AND '"+ dtos(_dFinAnoAtual) +"' "
    _oSQL:_sQuery += " 		    GROUP BY A1_PAIS
    _oSQL:_sQuery += " 				    ,YA_DESCR
    _oSQL:_sQuery += " 				    ,SD2.D2_COD
    _oSQL:_sQuery += " 				    ,SD2.D2_DESC) AS PAIS_EXPORTACAO
    _oSQL:_sQuery += " FROM " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB5") + " SB5 "
    _oSQL:_sQuery += " 	ON SB5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SB5.B5_COD = SB1.B1_COD "
    _oSQL:_sQuery += " 		AND SB5.B5_VASISDE <> 'S' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5_CAT "  
    _oSQL:_sQuery += " 	ON B1_CODLIN = ZX5_CAT.ZX5_39COD "
    _oSQL:_sQuery += " 		AND ZX5_CAT.ZX5_TABELA = '39' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5_MAR "   
    _oSQL:_sQuery += " 	ON B1_VAMARCM = ZX5_MAR.ZX5_40COD "
    _oSQL:_sQuery += " 		AND ZX5_MAR.ZX5_TABELA = '40' "
    _oSQL:_sQuery += " LEFT JOIN VA_VDADOS_OP QPRO "
    _oSQL:_sQuery += " 	ON FILIAL = '01' "
    _oSQL:_sQuery += " 		AND SUBSTRING(OP, 7, 2) != 'OS' "
    _oSQL:_sQuery += " 		AND TIPO_MOVTO = 'P' "
    _oSQL:_sQuery += " 		AND DATA BETWEEN '"+ dtos(_dIniAnoAtual) +"' AND '"+ dtos(_dFinAnoAtual) +"' "
    _oSQL:_sQuery += " 		AND PROD_FINAL = B1_COD "
    _oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND B1_TIPO = 'PA' "
    _oSQL:_sQuery += " AND SUBSTRING(B1_DESC, 1, 1) <> 'Z' "
    _oSQL:_sQuery += " GROUP BY B1_COD "
    _oSQL:_sQuery += " 		,B1_UM "
    _oSQL:_sQuery += " 		,B1_LITROS "
    _oSQL:_sQuery += " 		,SB1.B1_VARMAAL "
    _oSQL:_sQuery += " 		,ZX5_CAT.ZX5_39DESC "
    _oSQL:_sQuery += " 		,B1_DESC "
    _oSQL:_sQuery += " 		,B1_TIPO "
    _oSQL:_sQuery += " 		,ZX5_MAR.ZX5_40DESC "
    _oSQL:_sQuery += " ORDER BY B1_COD "

	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	//            Ordem    Descri            tipo tam dec valid    F3    opcoes (combo)                                 help
	aadd (_aRegsPerg, {01, "Ano referência ", "C", 4,  0,  "",   "   ", {},                   	""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
