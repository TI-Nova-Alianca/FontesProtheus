// Programa:  AtuZA4
// Autor:     Robert Koch
// Data:      08/10/2019
// Descricao: Atualiza tabela ZA4 (verbas comerciais)
//            Criado para ser chamado de diversos locais do sistema e concentrar
//            as regras em um unico local.
//
// Historico de alteracoes:
// 30/10/2019 - Robert - Passa a gravar avisos e erros usando a classe ClsAviso().
//

// --------------------------------------------------------------------------
user function AtuZA4 (_sVerba)
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _nUsado    := 0
	local _oAviso    := NIL
//	local _sMsg      := ''

	u_logIni ()
	
	za4 -> (dbsetorder (1))  // ZA4_FILIAL, ZA4_NUM, R_E_C_N_O_, D_E_L_E_T_
	if ! za4 -> (dbseek (xfilial ("ZA4") + _sVerba, .F.))
	//	U_GrvAviso ('E', 'grpTI', procname (), 0, "Verba '" + _sVerba + "' nao localizada na tabela ZA4. Atualizacao nao pode ser feita.")
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:Destinatar = 'grpTI'
		_oAviso:Texto      = "Verba '" + _sVerba + "' nao localizada na tabela ZA4. Atualizacao nao pode ser feita."
		_oAviso:Origem     = procname ()
		_oAviso:Grava ()
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SUM (ZA5_VLR)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA5") + " ZA5 "
		_oSQL:_sQuery +=  " WHERE ZA5.D_E_L_E_T_ = ''"
		// eu QUERO todas as filiais para compor o saldo da verba --> _oSQL:_sQuery +=    " AND ZA5.ZA5_FILIAL = '" + xfilial ("ZA5") + "'"
		_oSQL:_sQuery +=    " AND ZA5.ZA5_NUM    = '" + _sVerba + "'"
		_oSQL:Log ()
		_nUsado = _oSQL:RetQry (1, .F.)
		u_log ('Valor usado:', _nUsado)

		reclock ("ZA4", .F.)
		if _nUsado == 0
			za4 -> za4_sutl = '0'  // Pendente (ainda nao usado)
		elseif _nUsado < za4 -> za4_vlr
			za4 -> za4_sutl = '1'  // Parcial
		else
			za4 -> za4_sutl = '2'  // Usado total
			if _nUsado > za4 -> za4_vlr
//				U_GrvAviso ('E', 'grpTI', "Verba '" + _sVerba + "' valor usado maior que o valor da verba.", procname (), 0)
				_oAviso := ClsAviso ():New ()
				_oAviso:Tipo       = 'E'
				_oAviso:Destinatar = 'grpTI'
				_oAviso:Texto      = "Verba '" + _sVerba + "' valor usado maior que o valor da verba."
				_oAviso:Origem     = procname ()
				_oAviso:Grava ()
			endif
		endif
		msunlock ()
		u_log ('Atualizei ZA4_SUTL para:', za4 -> za4_sutl)
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
