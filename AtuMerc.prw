// Programa.: AtuMerc
// Autor....: Robert Koch
// Data.....: 08/11/2016
// Descricao: Cria agendamento de envio de atualizacoes para sistema Mercanet.
//            Nao grava diretamente na tabela de integracao do Mercanet por que essa
//            tabela encontra-se em outro database. Qualquer erro de comunicacao faria
//            o processo parar e derrubaria a sessao do usuario. Por isso gera uma tabela
//            de agendamentos e um processo posterior faz a gravacao no database da Mercanet.
//
// H/storico de alteracoes:
// 24/08/2017 - Robert  - Verifica se jah existe registro antes de inserir um igual.
// 06/06/2018 - Robert  - Envio da tabela 46 do ZX5.
// 19/06/2018 - Robert  - Envio da tabela 46 do ZX5 direcionada para codigo 8111 do Mercanet 
//                        (estava indo para 8101).
// 22/06/2020 - Robert  - Melhorada gravacao de logs.
// 01/03/2021 - Robert  - Envia SB1 somente se for B1_TIPO = 'PA' (GLPI 11687)
// 03/05/2022 - Claudia - Realiza envio de registro de cliente para mercanet 
//                        quando a1_savblq <> 'N'. GLPI: 11922
// 05/06/2022 - Robert  - Em vez de logar 'Enviando dados para Mercanet', passa a logar o SQL executado.
// 26/02/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------------------------
user function AtuMerc (_sAlias, _nRecno)
	local _aAreaAnt  := U_ML_SRArea ()
	local _nTipo     := 0
	local _oSQL      := NIL
	local _sChave1   := ""
	local _sChave2   := ""
	local _sChave3   := ""
	local _sChave4   := ""
	local _sChave5   := ""
	local _lContinua := .T.

	if _lContinua
		(_sAlias) -> (dbgoto (_nRecno))
		do case
			case _sAlias == 'SA1'
				if sa1->a1_savblq == 'N'
					_lContinua = .F.
				else
					_nTipo = 20
					_sChave1 = sa1 -> a1_cod
					_sChave2 = sa1 -> a1_loja
				endif
			case _sAlias == 'SA3'
				_nTipo = 8005
				_sChave1 = sa3 -> a3_cod
			case _sAlias == 'DA0'
				_nTipo = 41
				_sChave1 = da0 -> da0_codtab
			case _sAlias == 'SA4'
				_nTipo = 8020
				_sChave1 = sa4 -> a4_cod
			case _sAlias == 'SB1'
				if sb1 -> b1_tipo == 'PA'  // A principio nao temos intencao de vender outros tipos de itens.
					_nTipo = 40
					_sChave1 = sb1 -> b1_cod
				else
					_lContinua = .F.
				endif
			case _sAlias == 'SE4'
				_nTipo = 8012
				_sChave1 = se4 -> e4_codigo
			case _sAlias == 'SF4'
				_nTipo = 8007
				_sChave1 = sf4 -> f4_codigo
			case _sAlias == 'SC5'
				_nTipo = 30
				_sChave1 = sc5 -> c5_num
			case _sAlias == 'SF1'
				_nTipo = 35
				_sChave1 = sf1 -> f1_doc
				_sChave2 = sf1 -> f1_serie
				_sChave3 = sf1 -> f1_fornece
				_sChave4 = sf1 -> f1_loja
			case _sAlias == 'SF2'
				_nTipo = 37
				_sChave1 = sf2 -> f2_doc
				_sChave2 = sf2 -> f2_serie
			case _sAlias == 'SE1'
				_nTipo = 50
				_sChave1 = se1 -> e1_num
				_sChave2 = se1 -> e1_prefixo
				_sChave3 = se1 -> e1_parcela
			case _sAlias == 'SE5'
				_nTipo = 8108
				_sChave1 = se5 -> e5_numero
				_sChave2 = se5 -> e5_prefixo
				_sChave3 = se5 -> e5_parcela
			case _sAlias == 'ZX5' .and. zx5 -> zx5_tabela == '39'
				_nTipo = 8004
				_sChave1 = zx5 -> zx5_tabela
				_sChave2 = zx5 -> zx5_39cod
			case _sAlias == 'ZX5' .and. zx5 -> zx5_tabela == '40'
				_nTipo = 8101
				_sChave1 = zx5 -> zx5_tabela
				_sChave2 = zx5 -> zx5_40cod
			case _sAlias == 'ZX5' .and. zx5 -> zx5_tabela == '46'  // Promotores
				_nTipo = 8111
				_sChave1 = zx5 -> zx5_tabela
				_sChave2 = zx5 -> zx5_46cod
			otherwise
				U_AvisaTI ("Alias '" + _sAlias + "' (ou outra situacao) sem tratamento na interface com Mercanet.")
				_lContinua = .F.
		endcase
	endif

	// Cria tabela para integracao, caso nao exista.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery = "select count (*) from sysobjects where name = 'VA_INTEGR_MERCANET' and type = 'U'"
	//	if _oSQL:RetQry() == 0
		if _oSQL:RetQry (1, .f.) == 0
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "CREATE TABLE VA_INTEGR_MERCANET("
			_oSQL:_sQuery += " ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,"
			_oSQL:_sQuery += " TIPO int NOT NULL,"
			_oSQL:_sQuery += " RECNO int NOT NULL,"
			_oSQL:_sQuery += " DATA_GRAV datetime NOT NULL default getdate(),"
			_oSQL:_sQuery += " ALIAS varchar (3) NOT NULL DEFAULT '',"
			_oSQL:_sQuery += " CHAVE1 varchar(20) NOT NULL DEFAULT '',"
			_oSQL:_sQuery += " CHAVE2 varchar(20) NOT NULL DEFAULT '',"
			_oSQL:_sQuery += " CHAVE3 varchar(20) NOT NULL DEFAULT '',"
			_oSQL:_sQuery += " CHAVE4 varchar(20) NOT NULL DEFAULT '',"
			_oSQL:_sQuery += " CHAVE5 varchar(20) NOT NULL DEFAULT '')"
		//	_oSQL:Log ()
			if ! _oSQL:Exec ()
				U_AvisaTI ("Erro ao criar tabela para agendamento de exportacoes para Mercanet: " + _oSQL:_sQuery)
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
//		u_log2 ('info', 'Enviando dados para Mercanet. Alias: ' + _sAlias + ' Chave: ' + _sChave1 + _sChave2 + _sChave3 + _sChave4 + _sChave5)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " if not exists (SELECT * FROM VA_INTEGR_MERCANET WHERE ALIAS = '" + _sAlias + "' AND TIPO = " + cvaltochar (_nTipo) + " AND RECNO = " + cvaltochar (_nRecno) + ")" 
		_oSQL:_sQuery += " INSERT INTO VA_INTEGR_MERCANET"
		_oSQL:_sQuery += " (ALIAS, TIPO, RECNO, CHAVE1, CHAVE2, CHAVE3, CHAVE4, CHAVE5)"
		_oSQL:_sQuery += " values ('" + _sAlias + "',"
		_oSQL:_sQuery +=           cvaltochar (_nTipo) + ","
		_oSQL:_sQuery +=           cvaltochar (_nRecno) + ","
		_oSQL:_sQuery +=           "'" + _sChave1 + "',"
		_oSQL:_sQuery +=           "'" + _sChave2 + "',"
		_oSQL:_sQuery +=           "'" + _sChave3 + "',"
		_oSQL:_sQuery +=           "'" + _sChave4 + "',"
		_oSQL:_sQuery +=           "'" + _sChave5 + "')"
	//	_oSQL:Log ('[' + procname () + ']')
		if ! _oSQL:Exec ()
			U_AvisaTI ("Erro ao agendar exportacao para Mercanet: " + _oSQL:_sQuery)
			_lContinua = .F.
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return
