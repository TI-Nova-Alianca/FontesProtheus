// Programa...: VA_XLS65
// Autor......: Sandra Sugari / Robert Koch
// Data.......: 29/01/2024
// Descricao..: Lote FULL x Notas Protheus.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Exporta_planilha
// #Descricao         #Lote FULL x Notas Protheus.
// #PalavasChave      #Lote #sNotas #de carga #descarregamento
// #TabelasPrincipais #tb_wms_lotes #separacoes #F2 #A1 #D2
// #Modulos           #FAT 

// Historico de alteracoes:
// 

// --------------------------------------------------------------------------
User Function VA_XLS65 (_lAutomat)
	Local cCadastro := "Lote FULL x Notas Protheus."
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS65"
	_ValidPerg()
	Pergunte(cPerg,.F.)

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
return



// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet



// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	// Monta lista dos tanques.
	incproc ("Buscando dados")
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""

/*	
// COM LOTE CONSIGO LOCALIZAR DENTRO DA FULL O NUMERO DA CARGA
_oSQL:_sQuery +=  " with separacoes as ( "
_oSQL:_sQuery +=  " SELECT SUBSTRING(documento_id,6,6) as carga, cod_item, SUM (qtde) as quant "
_oSQL:_sQuery +=  " FROM tb_wms_lotes "
_oSQL:_sQuery +=  " WHERE lote = '" + mv_par01 +"' "
_oSQL:_sQuery +=  " group by SUBSTRING(documento_id,6,6), cod_item) "

 
// DENTRO DO PROTHEUS SF2 COM AS CARGAS CONSIGO LOCALIZAR AS NOTAS OU PODERIA USAR OS PEDIDOS CONFORME TABELA DAI
_oSQL:_sQuery +=  " SELECT F2_FILIAL AS FILIAL, F2_CARGA as CARGA_OMS, F2_DOC AS NOTA, F2_SERIE AS SERIE_NOTA, A1_NOME AS CLIENTE, F2_LOJA, F2_EMISSAO "
_oSQL:_sQuery +=  " ,D2_COD, D2_QUANT AS QT_TOTAL_NF "
_oSQL:_sQuery +=  " ,S.quant AS QT_SEPARADA_DESTE_LOTE "
_oSQL:_sQuery +=  " FROM "   + RetSQLName ("SF2") + " SF2, "
_oSQL:_sQuery +=    		   RetSQLName ("SD2") + " SD2, " 
_oSQL:_sQuery +=    		   RetSQLName ("SA1") + " SA1, " 
_oSQL:_sQuery += " separacoes S "
_oSQL:_sQuery +=  " WHERE F2_CLIENTE = A1_COD "
_oSQL:_sQuery +=  " AND F2_LOJA = A1_LOJA "
_oSQL:_sQuery +=  " AND F2_FILIAL = '" + xfilial ("SF2") + "' "
_oSQL:_sQuery +=  " AND SF2.D_E_L_E_T_ = '' "
_oSQL:_sQuery +=  " AND SA1.D_E_L_E_T_ = '' "
_oSQL:_sQuery +=  " AND SD2.D_E_L_E_T_ = '' "
_oSQL:_sQuery +=  " AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_oSQL:_sQuery +=  " AND SD2.D2_DOC = SF2.F2_DOC "
_oSQL:_sQuery +=  " AND SD2.D2_SERIE = SF2.F2_SERIE "
_oSQL:_sQuery +=  " AND SF2.F2_CARGA = S.carga "
_oSQL:_sQuery +=  " AND SD2.D2_COD = S.cod_item "
_oSQL:_sQuery +=  " AND SF2.F2_CARGA != '' "  //PARA NAO LER OUTRAS SEPARACOES FEITAS PELO FULL
	*/

_oSQL:_sQuery += "WITH separacoes AS ("
_oSQL:_sQuery += "    SELECT SUBSTRING(documento_id, 6, 6) AS carga, cod_item, SUM(qtde) AS quant "
_oSQL:_sQuery += "    FROM tb_wms_lotes "
_oSQL:_sQuery += "    WHERE lote = '" + mv_par01 + "' "
_oSQL:_sQuery += "    GROUP BY SUBSTRING(documento_id, 6, 6), cod_item) "

_oSQL:_sQuery += "SELECT SF2.F2_FILIAL AS FILIAL, SF2.F2_CARGA AS CARGA_OMS, SF2.F2_DOC AS NOTA, SF2.F2_SERIE AS SERIE_NOTA, SA1.A1_NOME AS CLIENTE, SF2.F2_LOJA, SF2.F2_EMISSAO "
_oSQL:_sQuery += "    ,SD2.D2_COD, SD2.D2_QUANT AS QT_TOTAL_NF "
_oSQL:_sQuery += "    ,S.quant AS QT_SEPARADA_DESTE_LOTE "
_oSQL:_sQuery += "FROM " + RetSQLName("SF2") + " SF2 "
_oSQL:_sQuery += "    INNER JOIN " + RetSQLName("SD2") + " SD2 ON SD2.D2_FILIAL = SF2.F2_FILIAL AND SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE "
_oSQL:_sQuery += "    INNER JOIN " + RetSQLName("SA1") + " SA1 ON SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA "
_oSQL:_sQuery += "    LEFT JOIN separacoes S ON SF2.F2_CARGA = S.carga AND SD2.D2_COD = S.cod_item "
_oSQL:_sQuery += "WHERE SF2.F2_CLIENTE = A1_COD "
_oSQL:_sQuery += "    AND SF2.F2_LOJA = A1_LOJA "
_oSQL:_sQuery += "    AND SF2.F2_FILIAL = '" + xfilial("SF2") + "' "
_oSQL:_sQuery += "    AND SF2.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "    AND SA1.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "    AND SD2.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "    AND SF2.F2_CARGA != '' "





	_oSQL:Log ()
	_oSQL:ArqDestXLS = 'VA_XLS65'
	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Lote             ", "C", 10, 0,  "",   "   ", {}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
