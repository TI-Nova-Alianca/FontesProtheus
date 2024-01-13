// Programa...: BatZBE
// Autor......: Robert Koch
// Data.......: 10/11/2022
// Descricao..: Limpeza/manut.diaria tabela ZBE-painel importador XML da TRS (GLPI 12622)
//              Programa criado para ser executado em batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Limpeza / manutencao diaria tabela ZBE (painel importador XML da TRS)
// #PalavasChave      #pack #limpeza #importador_XML #importador_TRS
// #TabelasPrincipais #ZBE
// #Modulos           #COM #EST

// Historico de alteracoes:
// 05/04/2023 - Robert - Grava evento referenciando a chave da nota.
//                     - Limpeza e envio de mensagem passa a ser dentro de controle de transacao.
// 11/01/2024 - Robert - Desabilitado envio de avisos de acompanhamento.
//

// ----------------------------------------------------------------
user function BatZBE ()
	local _oSQL      := NIL
	local _lContinua := .T.
	local _aRegZBE   := {}
	local _nRegZBE   := 0
	local _oAviso    := NIL
	local _oChvElim  := ClsAUtil():New()
	local _aColsMsg  := {}
	local _oEvento   := NIL

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT top 100 R_E_C_N_O_"  // Nao muitas para nao gerar msg de aviso muito grande
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZBE") + " ZBE"
		_oSQL:_sQuery += " WHERE ZBE.D_E_L_E_T_  = ''"
		// quero TODAS as filiais. _oSQL:_sQuery +=   " AND ZBE.ZBE_FILIAL  = '" + xfilial ("ZBE") + "'"
		_oSQL:_sQuery +=   " AND ZBE.ZBE_STATUS != '999'"  // NAO GEROU NOTA NEM PRE-NOTA
		_oSQL:_sQuery +=   " AND EXISTS (SELECT *"  // NOTA JAH FOI GERADA/DIGITADA POR OUTRA ROTINA
		_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SF1")
		_oSQL:_sQuery +=                " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                  " AND F1_CHVNFE  = ZBE_CHVNFE)"
		_oSQL:Log ('[' + procname () + ']')
		_aRegZBE = aclone (_oSQL:Qry2Array (.f., .f.))
		
		begin transaction
		for _nRegZBE = 1 to len (_aRegZBE)
			zbe -> (dbgoto (_aRegZBE [_nRegZBE, 1]))
			U_Log2 ('info', '[' + procname () + ']Eliminando chave ' + zbe -> zbe_chvnfe + ' por que jah foi gerada no SF1 por outra rotina.')
			aadd (_oChvElim:_aArray, {zbe -> zbe_filial, zbe -> zbe_chvnfe, alltrim (zbe -> zbe_file)})
			reclock ("ZBE", .F.)
			zbe -> (dbdelete ())
			msunlock ()

			_oEvento := ClsEvent():new ()
			_oEvento:CodEven    = 'ZBE002'
			_oEvento:Texto      = 'Eliminando chave da tabela ZBE por que jah foi gerada no SF1 por outra rotina.'
			_oEvento:Recno      = ZBE -> (recno ())
			_oEvento:Alias      = 'ZBE'
			_oEvento:ChaveNFe   = zbe -> zbe_chvnfe
			_oEvento:Grava ()
		next

		// Prepara mensagem bonitinha (HTML) de notificacao aos usuarios.
		if len (_oChvElim:_aArray) > 0
			_aColsMsg = {}
			aadd (_aColsMsg, {'Filial',     'left',  ''})
			aadd (_aColsMsg, {'Chave',      'left',  ''})
			aadd (_aColsMsg, {'Arquivo',    'left',  ''})
			_sMsgHTM = _oChvElim:ConvHTM ('Chaves eliminadas do painel XML pois foram digitadas por outra rotina', ;
										_aColsMsg, ;
										'', ;
										.F., ;
										NIL)

			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'I'
			_oAviso:DestinZZU  = {'019'}  // 019 = Notifica setor fiscal
			_oAviso:Titulo     = 'Limpeza painel XML (' + cvaltochar (len (_oChvElim:_aArray)) + ') registros.'
			_oAviso:Texto      = _sMsgHTM
			_oAviso:Formato    = 'H'
			_oAviso:Origem     = procname ()
			_oAviso:Grava ()

	//		// copia para testes
	//		_oAviso:DestinAvis = 'robert.koch'
	//		_oAviso:Grava ()
		endif

		_oBatch:Mensagens += 'Eliminados ' + cvaltochar (len (_aRegZBE)) + ' registros desnecessarios da tabela ZBE'
		end transaction
	endif

	if _lContinua
		_oBatch:Mensagens += procname () + " ok. "
	endif
return
