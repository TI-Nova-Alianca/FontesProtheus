// Programa...: MS520Vld
// Autor......: Robert Koch
// Data.......: 13/07/2011
// Cliente....: Nova Alianca
// Descricao..: Ponto de entrada para validar a exclusao de notas fiscais de saida.
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para validar a exclusao de notas fiscais de saida.
// #PalavasChave      #ponto_de_entrada #exclusao_de_nota #nota_de_saida #validacao_nota
// #TabelasPrincipais #SD2 #SF2
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 02/08/2013 - Robert  - Quando transf.p/ outra filial, exige exclusao da entrada antes.
// 21/08/2013 - Leandro - Inclusão de função para não permitir excluir a nota caso a 
//						  guia de livre trânsito não tenha sido excluída
// 21/08/2019 - Robert  - Nao verifica mais deposito fechado (nao utilizamos mais ha anos).
// 06/11/2020 - Cláudia - Permitir excluir notas de trasnf. emitidas pelo ativo. GLPI: ID 8753 
// 06/11/2020 - Cláudia - Não permitir excluir NF's de cartões quando possuirem títulos baixados. 
//						  GLPI: 8749
// 01/11/2022 - Claudia - Incluido o tipo PX para validação de exclusão de títulos. GLPI: 12713
//
// ---------------------------------------------------------------------------------------------
User Function MS520Vld () 
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	
	u_logIni ()

	if _lRet
		_lRet = _VerGuia ()
	endif
	
	if _lRet
		_lRet = _VerTrFil ()  // Verificar se precisa tratar de forma diferente quando transf.originada na tela ATFA060
	endif

	if _lRet
		_lRet := _VerNFCartao() // Verificar se a nota é tipo CC/CD
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _lRet
//
// --------------------------------------------------------------------------
// Verifica entrada desta nota noutra filial (quando transferencia).
static function _VerTrFil () 
	local _sQuery   := ""
	local _sQuery1  := ""
	local _sRetQry  := ""
	local _lPed     := .F.
	local _lRet     := .T.
	Local _aPed     := {}

	_sQuery := ""
	_sQuery += " SELECT TOP 1 FILDEST"
	_sQuery +=   " FROM VA_VTRANSF_ENTRE_FILIAIS V"
	_sQuery +=  " WHERE V.D2_FILIAL = '" + sf2 -> f2_filial + "'"
	_sQuery +=    " AND V.D2_DOC    = '" + sf2 -> f2_doc    + "'"
	_sQuery +=    " AND V.D2_SERIE  = '" + sf2 -> f2_serie  + "'"
	_sQuery +=    " AND V.D1_DOC    IS NOT NULL"
	_sRetQry = U_RetSQL (_sQuery)

	if ! empty (_sRetQry)

		// Verifica se nota foi gerada sem pedido -> no ativo
		_sQuery1 := ""
		_sQuery1 += " SELECT DISTINCT D2_PEDIDO FROM SD2010"
		_sQuery1 += " WHERE D2_FILIAL = '" + sf2 -> f2_filial + "'"
		_sQuery1 += " AND D2_DOC    = '" + sf2 -> f2_doc    + "'"
		_sQuery1 += " AND D2_SERIE  = '" + sf2 -> f2_serie  + "'"
		_aPed := U_Qry2Array(_sQuery1)

		If Len(_aPed) > 0
			If empty(_aPed[1,1]) .or. alltrim(_aPed[1,1]) == ''
				_lPed := .T.
			EndIf
		EndIf

		If _lPed == .T. // se o pedido for vazio é transferencia pelo ativo e permite excluir
			_lRet = .T.
		Else
			u_help ("A NF '" + sf2 -> f2_doc + "' é uma nota de transferencia para a filial '" + _sRetQry + "'. Sua exclusao somente será permitida apos a exclusao da nota / pre-nota de entrada correspondente na filial '" + _sRetQry + "'.")
			_lRet = .F.
		EndIf
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verifica guia de transito
static function _VerGuia () 
	local _sQuery   := ""
	local _sRetQry  := ""
	local _lRet     := .T.

	_sQuery := ""
	_sQuery += " SELECT TOP 1 ZQ_NUMERO "
	_sQuery += " FROM SZQ010 SZQ "
	_sQuery += " WHERE SZQ.D_E_L_E_T_ = ''"
	_sQuery += " AND SZQ.ZQ_FILIAL 	= '" + sf2 -> f2_filial + "'"
	_sQuery += " AND SZQ.ZQ_NF01    = '" + sf2 -> f2_doc    + "'"
	_sQuery += " AND SZQ.ZQ_SERIE01 = '" + sf2 -> f2_serie  + "'"
	
	_sRetQry = U_RetSQL (_sQuery)
	if ! empty (_sRetQry)
		u_help ("A nota fiscal '" + sf2 -> f2_doc + "' possui a guia de livre transito" + chr(13) + chr(10) + "numero '" + _sRetQry + "'. Favor excluir a guia antes de excluir a nota.")
		_lRet = .F.
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Verificar se a NF é do tipo CC/CD para validações de exclusão de títulos
Static Function _VerNFCartao() 
	local _aDados 	:= {}
	local _lRet 	:= .T.
	local _oSQL 	:= ClsSQL ():New ()

	_oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		  E1_TIPO "
	_oSQL:_sQuery += " 		, E1_ADM "
	_oSQL:_sQuery += " 		, E1_BAIXA "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
	_oSQL:_sQuery += " WHERE E1_FILIAL = '" + sf2 -> f2_filial + "'"
	_oSQL:_sQuery += " AND E1_NUM      = '" + sf2 -> f2_doc    + "'"
	_oSQL:_sQuery += " AND E1_PREFIXO  = '" + sf2 -> f2_serie  + "'"
	_oSQL:_sQuery += " AND E1_TIPO IN('CC','CD','PX') "
    _oSQL:_sQuery += " AND E1_ADM   <> '' "
	_oSQL:_sQuery += " AND E1_BAIXA <> '' "
	_aDados := aclone (_oSQL:Qry2Array ())

	If len(_aDados) > 0 // existe titulos de NF cartões baixados
		_lRet := .F.
		u_help ("A nota fiscal '" + sf2 -> f2_doc + "' possui títulos com baixas no sistema." + chr(13) + chr(10) + "Favor excluir as baixas antes de excluir a nota.")
	EndIf 

Return _lRet
/*
// --------------------------------------------------------------------------
// Verifica existencia de NF de retorno simbolico de deposito.
static function _VerRetDep () 
	local _sQuery   := ""
	local _sRetQry  := ""
	local _lRet     := .T.

	_sQuery := ""
	_sQuery += "SELECT F2_DOC"
	_sQuery +=  " FROM " + RETSQLNAME ("SF2") + " SF2 "
	_sQuery += " WHERE SF2.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SF2.F2_FILIAL  != '" + xfilial ("SF2") + "'"  // O retorno vem de outra filial.
	_sQuery +=   " AND SF2.F2_VANFFD   = '" + sf2 -> f2_doc   + "'"
	_sRetQry = U_RetSQL (_sQuery)
	if ! empty (_sRetQry)
		u_help ("A NF '" + sf2 -> f2_doc + "' e' uma nota de venda via deposito. Existe uma NF de retorno simbolico ('" + _sRetQry + "') referente a esta venda, o que impede sua exclusao.")
		_lRet = .F.
	endif
return _lRet
*/
