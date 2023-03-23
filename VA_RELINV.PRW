// Programa.: VA_RELINV
// Autor....: Cláudia Lionço
// Data.....: 21/01/2023
// Descricao: Relatório de inventário
// 
// Tags para automatizar catalogo de customizacoes:
// #Programa          #relatorio
// #Descricao		  #Relatório de inventário
// #PalavasChave      #inventario 
// #TabelasPrincipais #SB7 
// #Modulos 		  #CUS 
//
// Historico de alteracoes:
// 27/01/2023 - Claudia - Incluido parametro de ordenação
// 30/01/2023 - Claudia - Incluídos F3 nos parametros.
// 02/02/2023 - Claudia - Incluida ordenação por endereco. GLPI: 13136
// 03/02/2023 - Claudia - Incluida coluna de linha. GLPI: 13141
// 23/03/2023 - Claudia - Incluida coluna de unidade de medida. GLPI: 13334
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_RELINV()
	Local cCadastro := "Relatório de inventário"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	Private cPerg   := "VA_RELINV"
    
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

    // Busca dados
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    Do Case
		Case mv_par13 == 1
            _oSQL:_sQuery += " ROW_NUMBER() OVER(ORDER BY SB7.B7_FILIAL,SB7.B7_LOCAL,SB7.B7_COD) AS LINHA
		Case mv_par13 == 2
            _oSQL:_sQuery += " ROW_NUMBER() OVER(ORDER BY SB7.B7_FILIAL,SB7.B7_LOCAL,SB7.B7_TIPO,SB7.B7_LOCALIZ) AS LINHA
		Case mv_par13 == 3
            _oSQL:_sQuery += " ROW_NUMBER() OVER(ORDER BY SB7.B7_FILIAL,SB1.B1_DESC) AS LINHA
		Case mv_par13 == 4
            _oSQL:_sQuery += " ROW_NUMBER() OVER(ORDER BY SB7.B7_FILIAL,SB7.B7_LOCAL,SB7.B7_TIPO,SB1.B1_DESC) AS LINHA
        Case mv_par13 == 5
            _oSQL:_sQuery += " ROW_NUMBER() OVER(ORDER BY SB7.B7_FILIAL,SB7.B7_LOCALIZ,SB7.B7_TIPO) AS LINHA
	EndCase
    _oSQL:_sQuery += "    ,SB7.B7_DOC AS DOCUMENTO "
    _oSQL:_sQuery += "    ,SB7.B7_DATA AS DT_INVENTARIO"
    _oSQL:_sQuery += "    ,SB7.B7_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SB7.B7_LOCAL AS ALMOXARIFADO "
    _oSQL:_sQuery += "    ,SB7.B7_COD AS PRODUTO "
    _oSQL:_sQuery += "    ,SB1.B1_DESC AS DESCRICAO "
    _oSQL:_sQuery += "    ,SB7.B7_TIPO AS TP_MATERIAL"
    _oSQL:_sQuery += "    ,SB1.B1_UM AS UM "
    _oSQL:_sQuery += "    ,SB7.B7_LOCALIZ AS ENDERECO"
    _oSQL:_sQuery += "    ,SB7.B7_LOTECTL AS LOTE_CONTROL"
    _oSQL:_sQuery += "    ,SB7.B7_DTVALID AS DT_VALIDADE "
    _oSQL:_sQuery += "    ,SB7.B7_QUANT AS QUANTIDADE"
    _oSQL:_sQuery += "    ,SB7.B7_VAQTD AS QUANTIDADE_CONTADA"
    _oSQL:_sQuery += "    ,SB7.B7_VAOBS AS OBS "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SB7") + " SB7 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SB1.B1_COD = SB7.B7_COD "
    _oSQL:_sQuery += " WHERE SB7.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SB7.B7_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
    _oSQL:_sQuery += " AND SB7.B7_DOC    BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
    _oSQL:_sQuery += " AND SB7.B7_COD    BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
    _oSQL:_sQuery += " AND SB7.B7_LOCAL  BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"' "
    _oSQL:_sQuery += " AND SB7.B7_TIPO   BETWEEN '"+ mv_par09 +"' AND '"+ mv_par10 +"' "
    _oSQL:_sQuery += " AND SB7.B7_DATA   BETWEEN '"+ dtos(mv_par11) +"' AND '"+ dtos(mv_par12) +"' "
    If !empty(mv_par14)
		_oSQL:_sQuery += " AND SB7.B7_LOCALIZ BETWEEN '"+ mv_par14 +"' AND '"+ mv_par15 +"' ""
	EndIf
    Do Case
		Case mv_par13 == 1
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOXARIFADO, PRODUTO "
		Case mv_par13 == 2
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOXARIFADO, TP_MATERIAL, ENDERECO "
		Case mv_par13 == 3
			_oSQL:_sQuery += " ORDER BY FILIAL, DESCRICAO "
		Case mv_par13 == 4
			_oSQL:_sQuery += " ORDER BY FILIAL, ALMOXARIFADO, TP_MATERIAL, DESCRICAO "
        Case mv_par13 == 5
			_oSQL:_sQuery += " ORDER BY FILIAL, ENDERECO, TP_MATERIAL "
	EndCase

	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      						                        Help
    aadd (_aRegsPerg, {01, "Filial de       ", "C", 2, 0,  "",  "SM0", {},                         								                    ""})
    aadd (_aRegsPerg, {02, "Filial até      ", "C", 2, 0,  "",  "SM0", {},                         								                    ""})
    aadd (_aRegsPerg, {03, "Documento de    ", "C", 9, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {04, "Documento até   ", "C", 9, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {05, "Produto de      ", "C",15, 0,  "",  "SB1", {},                         								                    ""})
    aadd (_aRegsPerg, {06, "Produto até     ", "C",15, 0,  "",  "SB1", {},                         								                    ""})
    aadd (_aRegsPerg, {07, "Local de      	", "C", 2, 0,  "",  "NNR", {},                         								                    ""})
    aadd (_aRegsPerg, {08, "Local até       ", "C", 2, 0,  "",  "NNR", {},                         								                    ""})
    aadd (_aRegsPerg, {09, "Tipo de         ", "C", 2, 0,  "",  "02" , {},                         								                    ""})
    aadd (_aRegsPerg, {10, "Tipo até        ", "C", 2, 0,  "",  "02" , {},                         								                    ""})
    aadd (_aRegsPerg, {11, "Dt. geração de  ", "D", 8, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {12, "Dt. geração até ", "D", 8, 0,  "",  "   ", {},                         								                    ""})
    aadd (_aRegsPerg, {13, "Ordenação       ", "N", 1, 0,  "",  "   ", {"Almox+Item","Tipo+Endereço","Descrição","Tipo+Descrição","Endereço+Tipo"}, ""})
    aadd (_aRegsPerg, {14, "Endereço de     ", "C",15, 0,  "",  "SBE", {},                         								                    ""})
    aadd (_aRegsPerg, {15, "Endereço até    ", "C",15, 0,  "",  "SBE", {},                         								                    ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return

