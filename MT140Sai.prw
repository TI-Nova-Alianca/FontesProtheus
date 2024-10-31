// Programa...: MT140SAI
// Autor......: Robert Koch
// Data.......: 21/10/2015
// Descricao..: P.E. na saida da rotina de atualizacao da pre-nota de entrada.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. na saida da rotina de atualizacao da pre-nota de entrada.
// #PalavasChave      #ponto_de_entrada #pre_nota 
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 17/12/2018 - Andre   - Alterada Query para considerar fornecedor, loja, nota, serie 
//                        e não mais apenas a chave. Pois nem toda PRE NOTA tem chave. 
// 25/10/2024 - Claudia - Limpa a TES, pois o TOTVS Transmite obriga a inclusão de TES padrao. GLPI: 16297 
//
// ---------------------------------------------------------------------------------------------------------
user function MT140SAI()	
	if paramixb [1] == 5  // Exclusao
		_AtuZZX(paramixb [1])
	endif
	if paramixb [1] == 3  // Inclusão
		_TransmiteTES()
		//_TransProduto()
	endif
Return
//
// ---------------------------------------------------------------------------------------------------------
// Atualiza status na tabela ZZX.
static function _AtuZZX(_nOpc)
	local _oSQL := NIL
	
	if _nOpc == 5
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName("ZZX")
		_oSQL:_sQuery += " 		SET ZZX_STATUS = '3'"  // 1=NF gerada no SF1;2=Pre-NF gerada no SF1;3=NF excluida no SF1
		_oSQL:_sQuery += " WHERE ZZX_CLIFOR    = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += " 		AND ZZX_LOJA   = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery += " 		AND ZZX_DOC    = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery += " 		AND ZZX_SERIE  = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery += " 		AND D_E_L_E_T_ = '' "
		_oSQL:Exec ()
	endif 
return
//
// ---------------------------------------------------------------------------------------------------------
// Realiza tratamento de TES para CTes
static function _TransmiteTES()

	if alltrim(sf1 -> f1_origem) == 'COMXCOL' .and. alltrim(sf1 -> f1_especie) == 'CTE'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName("SD1")
		_oSQL:_sQuery += " 		SET D1_TES     = ''"  
		_oSQL:_sQuery += " WHERE D_E_L_E_T_    = '' " 
		_oSQL:_sQuery += " 		AND D1_DOC     = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery += " 		AND D1_SERIE   = '" + sf1 -> f1_serie   + "'"
		_oSQL:_sQuery += " 		AND D1_FORNECE = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += " 		AND D1_LOJA    = '" + sf1 -> f1_loja    + "'"	
		_oSQL:Exec ()
	endif
return
// //
// // ---------------------------------------------------------------------------------------------------------
// // Realiza tratamento de Produto para CTes
// static function _TransProduto()
// 	if alltrim(sf1 -> f1_origem) == 'COMXCOL' .and. alltrim(sf1 -> f1_especie) == 'CTE'
// 		_oSQL := ClsSQL():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " UPDATE " + RetSQLName("SD1")
// 		_oSQL:_sQuery += " 		SET D1_COD     = ''  , D1_DESCRI = '' "  
// 		_oSQL:_sQuery += " WHERE D_E_L_E_T_    = '' " 
// 		_oSQL:_sQuery += " 		AND D1_DOC     = '" + sf1 -> f1_doc     + "'"
// 		_oSQL:_sQuery += " 		AND D1_SERIE   = '" + sf1 -> f1_serie   + "'"
// 		_oSQL:_sQuery += " 		AND D1_FORNECE = '" + sf1 -> f1_fornece + "'"
// 		_oSQL:_sQuery += " 		AND D1_LOJA    = '" + sf1 -> f1_loja    + "'"	
// 		_oSQL:Exec ()
// 	endif
// return
