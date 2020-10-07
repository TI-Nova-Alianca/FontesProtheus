// Programa:   BatVDAP
// Autor:      Robert Koch
// Data:       29/11/2011
// Cliente:    Nova Alianca
// Descricao:  Envia e-mail de aviso quando houver DAP's de associados expirando.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 06/08/2012 - Robert - Verifica CPF dos associados para evitar repeticao quando associado tiver mais de um codigo/loja.
// 05/03/2013 - Elaine - Inclui filtro de cliente/loja base para garantir que o associado que vier no select seja o correto
//

// --------------------------------------------------------------------------
user function BatVDAP ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg      := ""
	local _sQuery    := ""
	local _aRetQry   := {}
	local _nDias     := 90
	local _sDestin   := ""
	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

	_sQuery := " SELECT A2_VACORIG,"
	_sQuery +=        " A2_COD,"
	_sQuery +=        " A2_LOJA,"
	_sQuery +=        " A2_NOME,"
	_sQuery +=        " dbo.VA_FORMATA_CGC (A2_CGC),"
	_sQuery +=        " A2_VANRDAP,"
	_sQuery +=        " SUBSTRING (A2_VAVLDAP, 7, 2) + '/' + SUBSTRING (A2_VAVLDAP, 5, 2) + '/' + SUBSTRING (A2_VAVLDAP, 1, 4)"
	_sQuery += " FROM " + RetSQLName ("SA2") + " SA2 "
	_sQuery += " WHERE SA2.D_E_L_E_T_  = ''"
	_sQuery +=   " AND SA2.A2_VAVLDAP != ''"
	_sQuery +=   " AND SA2.A2_VASTDAP NOT IN ('I', 'E')"
	_sQuery +=   " AND SA2.A2_VAVLDAP <= '" + dtos (DATE () + _nDias) + "'"                                                                                                                       
	_sQuery +=   " AND SA2.A2_COD = SA2.A2_VACBASE "
	_sQuery +=   " AND SA2.A2_LOJA = SA2.A2_VALBASE " 

	// Se aparece com outro codigo/loja (pessoal com mais de 1 inscr. est.), nao me interessa.
	_sQuery +=   " AND NOT EXISTS (SELECT * "
	_sQuery +=                     " FROM " + RetSQLName ("SA2") + " SA2_OUTRA "
	_sQuery +=                    " WHERE SA2_OUTRA.D_E_L_E_T_ = ''"
	_sQuery +=                      " AND SA2_OUTRA.A2_CGC     = SA2.A2_CGC"
	_sQuery +=                      " AND SA2_OUTRA.A2_VACBASE + SA2_OUTRA.A2_VALBASE < SA2.A2_VACBASE + SA2.A2_VALBASE)"
	_sQuery +=   " ORDER BY SA2.A2_VAVLDAP, SA2.A2_COD"
	u_log (_squery)
	_aRetQry = U_Qry2Array (_sQuery)

	if len (_aRetQry) > 0

		// Monta mensagem em HTML para enviar no e-mail.
		_sMsg := ""

		// Cria objeto array com os dados de cada array e usa metodo de geracao de HTML com esses dados.
		_aCols = {}
		aadd (_aCols, {"Coop.orig",  "left",  "@!"})
		aadd (_aCols, {"Assoc.",     "left",  "@!"})
		aadd (_aCols, {"Loja",       "left",  "@!"})
		aadd (_aCols, {"Nome",       "left",  "@!"})
		aadd (_aCols, {"CPF",        "left",  "@!"})
		aadd (_aCols, {"Numero DAP", "left",  "@!"})
		aadd (_aCols, {"Validade",   "left",  "@!"})
		_oAUtil := ClsAUtil():New (_aRetQry)
		_sMsg += _oAUtil:ConvHTM ('DAPs perdendo a validade nos proximos ' + cvaltochar (_nDias) + ' dias', _aCols, 'width="85%" border="1" cellspacing="0" cellpadding="3" align="center"', .F.)

		u_log (_smsg)
		_sDestin := "rubiane.busetti@novaalianca.coop.br"
		U_SendMail (_sDestin, "DAPs perdendo a validade", _sMsg, {})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
