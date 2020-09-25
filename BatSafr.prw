// Programa:   BatSafr
// Autor:      Robert Koch
// Data:       28/12/2011
// Descricao:  Envia e-mail com inconsistencias encontradas durante a safra.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 06/03/2012 - Robert - Nao considerava cargas aglutinadas.
// 13/03/2012 - Robert - Criada verificacao de cadastros viticolas nao renovados.
// 06/02/2013 - Robert - Separados os tipos de verificacao via parametro na chamada da funcao.
//                     - Passa a validar a safra atual pela data doo sistema.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 18/01/2016 - Robert - Desconsidera fornecedor 003114 no teste de cargas (transferencias da linha Jacinto para matriz)
// 25/01/2016 - Robert - Envia avisos para o grupo 045.
// 16/01/2019 - Robert - Incluido grupo 047 no aviso de cargas sem contranota.
//

// --------------------------------------------------------------------------
user function BatSafr (_sQueFazer)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _aCols     := {}
	local _aSemNota  := {}
	local _sDestin   := ""
	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _oSQL      := NIL

	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()
	u_log ("Iniciando as", time ())

	// Procura cargas sem contranota.
	if _sQueFazer == '1'
		_aSemNota = {}
		dbselectarea ("SZE")
		set filter to &('ZE_FILIAL=="' + xFilial("SZE") + '".And.ze_safra=="'+cvaltochar (year (date ()))+'".and.ze_coop$"000021".and.empty(ze_nfger).and.dtos(ze_data)<"' + dtos (ddatabase) + '".and.ze_aglutin!="O".and.ze_assoc!="003114"')
		dbgotop ()
		do while ! eof ()
			aadd (_aSemNota, {"Filial/carga '" + sze -> ze_filial + '/' + sze -> ze_carga + "' de " + dtoc (sze -> ze_data) + " sem contranota!", sze -> ze_nomasso})
			dbskip ()
		enddo
		set filter to
	
		if len (_aSemNota) > 0
			_aCols = {}
			aadd (_aCols, {"Mensagem",        "left",  "@!"})
			aadd (_aCols, {"Associado",       "left",  "@!"})
			_oAUtil := ClsAUtil():New (_aSemNota)
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			U_ZZUNU ({'045', '047'}, "Inconsistencias cargas safra", _sMsg)
		endif
	endif

	// Verifica contranotas com cadastro viticola desatualizado
	if _sQueFazer == '2'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT 'Filial:' + FILIAL + ' Assoc:' + ASSOCIADO + '-' + RTRIM (NOME_ASSOC) + ' Cad.vit:' + CAD_VITIC"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE SAFRA   = '" + cvaltochar (year (date ())) + "'"
		_oSQL:_sQuery +=    " AND TIPO_NF = 'E'"
		_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SZ2") + " SZ2 "
		_oSQL:_sQuery +=                     " WHERE SZ2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_FILIAL  = '" + xfilial ("SZ2") + "'"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_CADVITI = V.CAD_VITIC"
		_oSQL:_sQuery +=                       " AND SZ2.Z2_SAFRVIT = V.SAFRA)"
		u_log (_oSQL:_sQuery)
		_aCols = {}
		aadd (_aCols, {"Mensagem",        "left",  "@!"})
		_oAUtil := ClsAUtil():New (_oSQL:Qry2Array ())
		if len (_oAUtil:_aArray) > 0
			_sMsg := "Contranotas com cadastro viticola inconsistente ou nao renovado:"
			_sMsg += "<BR>"
			_sMsg += _oAUtil:ConvHTM ("", _aCols, 'width="80%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)
			u_log (_smsg)
			U_ZZUNU ({'045'}, "Inconsistencias cadastro viticola", _sMsg)
		endif
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
