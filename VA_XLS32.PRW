// Programa...: VA_XLS32
// Autor......: Robert Koch
// Data.......: 16/05/2017
// Descricao..: Exporta planilha com mapa de tanques (estoque / endereco / laudo)
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS32 (_lAutomat)
	Local cCadastro := "Exporta mapa de ocupacao dos tanques"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

	Private cPerg   := "VAXLS32"
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
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT BE_FILIAL AS FILIAL, BE_LOCAL AS ALMOX, BE_LOCALIZ AS TANQUE, BE_DESCRIC AS DESCRICAO,"
	_oSQL:_sQuery +=        " ISNULL ((SELECT TOP 1 RTRIM (BF_PRODUTO) + '-' + RTRIM (B1_DESC)"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SBF") + " SBF, "
	_oSQL:_sQuery +=                             RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=                 " WHERE SBF.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SBF.BF_FILIAL  = SBE.BE_FILIAL"
	_oSQL:_sQuery +=                   " AND SBF.BF_LOCAL   = SBE.BE_LOCAL"
	_oSQL:_sQuery +=                   " AND SBF.BF_LOCALIZ = SBE.BE_LOCALIZ"
	_oSQL:_sQuery +=                   " AND SBF.BF_QUANT   > 0"
	_oSQL:_sQuery +=                   " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=                   " AND SB1.B1_COD     = BF_PRODUTO"
	_oSQL:_sQuery +=                 " ORDER BY BF_QUANT DESC), '') AS OCUPADO_COM,"  // Ordena para pegar o produto de maior qtde, caso tenha mais de um
	_oSQL:_sQuery +=        " BE_CAPACID  AS CAPACIDADE, BE_ALTURLC AS ALTURA, BE_VADIAM AS DIAMETRO, BE_VABEM AS PATRIMONIO, BE_VAOBS AS OBSERVACAO,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_STATUS")  + " AS STATUS_TANQUE, "
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAMATL")  + " AS MATERIAL, "
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAREFRI") + " AS REFRIGERACAO, "
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAUSO")   + " AS FINALIDADE,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAVFINO") + " AS VINHO_FINO,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAVCOMU") + " AS VINHO_COMUM,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAGASEI") + " AS GASEIFICADO,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VAMOSTO") + " AS MOSTO,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VASUCOI") + " AS SUCO_INTEGRAL,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VASUCOA") + " AS SUCO_ASSEPTICO,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VANECTA") + " AS NECTAR,"
	_oSQL:_sQuery +=        _oSQL:CaseX3CBox ("BE_VASITUA") + " AS SITUACAO"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBE") + " SBE "
	_oSQL:_sQuery +=  " WHERE SBE.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SBE.BE_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=    " AND SUBSTRING (SBE.BE_LOCALIZ, 4, 4) BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND SBE.BE_VATANQ  = 'S'"
	_oSQL:_sQuery += " )"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=  " FROM C"
	if mv_par05 == 1
		_oSQL:_sQuery +=  " WHERE OCUPADO_COM = ''"
	elseif mv_par05 == 2
		_oSQL:_sQuery +=  " WHERE OCUPADO_COM != ''"
	endif
	_oSQL:_sQuery +=  " ORDER BY FILIAL, TANQUE"
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))
//	_oSQL:Qry2XLS (.F., .F., .F.)
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 02, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 02, 0,  "",   "SM0", {}, ""})
	aadd (_aRegsPerg, {03, "Numero tanque inicial         ", "C", 4,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {04, "Numero tanque final           ", "C", 4,  0,  "",   "",    {}, ""})
	aadd (_aRegsPerg, {05, "Situacao dos tanques          ", "N", 1,  0,  "",   "",    {"Livres", "Ocupados", "Todos"}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
