// Programa:   BatMerc
// Autor:      Robert Koch
// Data:       11/11/2016
// Descricao:  Verifica necessidade de integracoes com Mercanet.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 01/03/2017 - Robert - Chamada da funcao ConfirmSXC8() apos o MATA410 para tentar eliminar perda se sequencia de numero de pedidos.
// 03/05/2017 - Robert - Obriga banco CX1 quando cond.pag.097 (a vista).
// 26/06/2017 - Robert - Busca campos Canal, Segmento, Opt.simples nacional nas tabelas do Mercanet, pois nao vem no ZA1010.
// 17/07/2017 - Robert - Envia e-mail notificando erro na importacao de clientes.
// 28/07/2017 - Robert - Busca e-mail direto das tabelas do Mercanet por que vem cortado na tabela ZA1010.
//                     - Tratamento para converter 'optante simples nacional' de 0 (Mercanet) para 2 (Protheus).
// 05/10/2017 - Robert - Gravacao do campo C6_NUMPCOM.
// 19/02/2018 - Robert - Campo A1_VABARAP passa a ser obrigatorio no SA1.
// 20/02/2018 - Robert - Verifica se o CNPJ ja encontra-se cadastrado como cliente e grava codigo na tabela de retorno.
// 31/07/2018 - Robert - Grava msg de erro no batch em caso de erro na execucao de algum SQL.
// 01/08/2018 - Robert - Consiste CNPJ do cliente (raros casos de codigo sem zeros a esquerda no Protheus).
// 27/08/2018 - Robert - Tratamento campo A1_FORMA.
// 17/10/2018 - Robert - Criado tratamento para cliente '10013 ' (sem zero a esquerda).
// 30/10/2018 - Robert - Criado tratamento para cliente '4954  ' (sem zero a esquerda).
// 23/01/2019 - Andre  - Criada novas regras para preenchimeno de novos campos obrigatorios no Protheus (A1_IENCONT, A1_CONTRIB).
// 30/04/2019 - Andre  - Incluido campos de integra��o da referencias bancarias/comerciais dos cliente vindas do Mercanet.
// 02/08/2019 - Robert - Liberada importa��o de clientes pessoa fisica - GLPI 5846.
// 23/08/2019 - Andre  - Alterada rotina automatica para cadastro de CLIENTES.
// 10/10/2019 - Andre  - Caso cliente seja bloqueado, muda status do cliente para poder incluir pedido. 
//						 Depois de incluido, volta o status original do cliente.
// 14/11/2019 - Andre  - Adicionada valida��o para campo A1_VAFILAT.
// 05/12/2019 - Robert - Ajustes para importar pedidos na filial 16
// 19/02/2020 - Andre  - Adicionada mesma regra para integra��o de pedidos com frete FOB. Leva em branco para Protheus.
// 06/05/2020 - Robert - Desabilitada declaracao nome arquivo de log (aceita o que vier da rotina principal).
//                     - Numero do pedido do mercanet (zc5_pedmer) estava desposicionado nas mensagens de aviso.
// 08/05/2020 - Robert - Melhoradas msg de erro
//                     - Campo ZC5_ERRO aumentado de 250 para 1000 caracteres.
// 11/05/2020 - Robert - Importacao de pedidos passada para programa proprio (BatMercP.prw).
//

// --------------------------------------------------------------------------
user function BatMerc (_sQueFazer)
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _sLinkSrv := ""
//	_sArqLog := procname () + "_" + _sQueFazer + "_" + dtos (date ()) + ".log"
//	_sArqLog := procname () + "_" + _sQueFazer + "_F" + cFilAnt + '_' + dtos (date ()) + ".log"
	u_logDH ()
	u_logIni ()

	_oBatch:Retorno = 'S'

	// Define se deve apontar para o banco de producao ou de homologacao.
	if "TESTE" $ upper (GetEnvServer())
		_sLinkSrv = "LKSRV_MERCANETHML.MercanetHML.dbo"
	else
		_sLinkSrv = "LKSRV_MERCANETPRD.MercanetPRD.dbo"
	endif

	_sQueFazer = iif (_sQueFazer == NIL, '', _sQueFazer)
	do case
	case _sQueFazer == 'E'  // Enviar dados
		_Envia (_sLinkSrv)
	case _sQueFazer == 'P'  // Ler pedidos de venda
		//_LePed (_sLinkSrv)
		u_help ("Para importar pedidos use o agendamento do programa U_BatMercP()")
	case _sQueFazer == 'C'  // Ler novos clientes
		_LeCli (_sLinkSrv)
	otherwise
		U_Help ("Sem tratamento para opcao '" + _sQueFazer + "'")
		_oBatch:Retorno = 'N'
	endcase
	
	u_log ('Mensagens do batch:', _oBatch:Mensagens)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.



// --------------------------------------------------------------------------
// Envia dados para o Mercanet
static function _Envia (_sLinkSrv)
	local _oSQL     := NIL
	local _aDados   := {}
	local _nDado    := 0
	local _nLock    := 0
	local _nRegEnv  := 0

	u_logIni ()

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	_nLock := U_Semaforo (procname (1) + procname ())
	if _nLock == 0
		//u_log ("Bloqueio de semaforo.")
		_oBatch:Mensagens += "Bloqueio de semaforo."
	else

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ID, TIPO, RECNO, CHAVE1, CHAVE2, CHAVE3, CHAVE4, CHAVE5"
		_oSQL:_sQuery +=  " FROM VA_INTEGR_MERCANET"
		_oSQL:_sQuery += " ORDER BY ID"
		//_oSQL:Log ()
		_aDados := _oSQL:Qry2Array (.F., .F.)
		//u_log (_aDados)
	
		for _nDado = 1 to len (_aDados)
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "INSERT INTO " + _sLinkSrv + ".DB_INTERFACE_PROTHEUS (TIPO, R_E_C_N_O_, DATA_GRAVACAO, [STATUS], AUX_0, AUX_1, AUX_3, AUX_4, AUX_5)"
			_oSQL:_sQuery += " values (" + cvaltochar (_aDados [_nDado, 2]) + ","
			_oSQL:_sQuery +=               cvaltochar (_aDados [_nDado, 3]) + ","
			_oSQL:_sQuery +=               "getdate(),"
			_oSQL:_sQuery +=               "'INS',"
			_oSQL:_sQuery +=               "'" + _aDados [_nDado, 4] + "',"
			_oSQL:_sQuery +=               "'" + _aDados [_nDado, 5] + "',"
			_oSQL:_sQuery +=               "'" + _aDados [_nDado, 6] + "',"
			_oSQL:_sQuery +=               "'" + _aDados [_nDado, 7] + "',"
			_oSQL:_sQuery +=               "'" + _aDados [_nDado, 8] + "')"
			//_oSQL:Log ()
			if _oSQL:Exec ()
	
				// Elimina o registro da tabela de pendencias.
				_oSQL:_sQuery := "DELETE VA_INTEGR_MERCANET"
				_oSQL:_sQuery += " WHERE ID = " + cvaltochar (_aDados [_nDado, 1])
				//_oSQL:Log ()
				if ! _oSQL:Exec ()
					_oBatch:Mensagens += "Erro execucao SQL:" + _oSQL:_sQuery
					_oBatch:Retorno = 'N'
				endif
				_nRegEnv ++
			else
				_oBatch:Mensagens += "Erro execucao SQL:" + _oSQL:_sQuery
				_oBatch:Retorno = 'N'
			endif
		next
		_oBatch:Mensagens += cvaltochar (_nRegEnv) + " registros enviados"
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	//u_logFim ()
return


/* Migrado para o programa U_BatMercP.prw
// --------------------------------------------------------------------------
// Leitura de pedidos do Mercanet
static function _LePed (_sLinkSrv)
	local _oSQL      := NIL
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _aLinhaSC6 := {}
	local _nBakSX1   := 0
	local _aAmbAnt   := {}
	local _sFila     := ""
	local _sPedMer   := ""
	local _oEvento   := NIL
	local _sAliasQ   := ""
	local _sMsgErro  := ""
	local _sStatMerc := ""
	local _nLock     := 0
	local _lContinua := .T.
	local _i         := 0
	local _aPedGer   := {}
	local _nPedGer   := 0
	local _sCliente  := ""
	local _sLojaCli  := ""
	local _sCNPJ     := ""
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	u_logIni ()

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname (1) + procname ())
		if _nLock == 0
			//u_log ("Bloqueio de semaforo.")
			_lContinua = .F.
			_oBatch:Mensagens += "Bloqueio de semaforo."
		endif
	endif
		
	if _lContinua
		 
		// Cria arquivo de trabalho com os pedidos a importar.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT * FROM " + _sLinkSrv + ".ZC5010, "
		_oSQL:_sQuery +=                    _sLinkSrv + ".ZC6010 "
		_oSQL:_sQuery += " WHERE ZC6_PEDMER  = ZC5_PEDMER"
		_oSQL:_sQuery += " AND ZC5_FILIAL  = 1"
		_oSQL:_sQuery += " AND ZC5_STATUS    = 'INS'"
		_oSQL:_sQuery += " AND ZC5_DTINI     = ''"
		_oSQL:_sQuery += " AND ZC5_HRINI     = ''"
		_oSQL:_sQuery += " ORDER BY ZC5_FILA, ZC5_PEDMER, ZC6_ITPMER"
		_oSQL:Log ()
		_sAliasQ := _oSQL:Qry2Trb ()

		if (_sAliasQ) -> (eof ())
			_oBatch:Mensagens = "Nenhum pedido a importar"
		endif

		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			_sFila = (_sAliasQ) -> zc5_fila
			_sPedMer = (_sAliasQ) -> zc5_pedmer

			// Avisa o Mercanet que estah iniciando o processamento deste pedido.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZC5010 "
			_oSQL:_sQuery +=   " SET ZC5_DTINI  = '" + dtos (date ()) + "',"
			_oSQL:_sQuery +=       " ZC5_HRINI  = '" + time () + "'"
			_oSQL:_sQuery += " WHERE ZC5_FILA   = '" + _sFila + "'"
			_oSQL:_sQuery +=   " AND ZC5_PEDMER = '" + _sPedMer + "'"
			_oSQL:_sQuery +=   " AND ZC5_FILIAL = 1"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				_oBatch:Mensagens += "Erro execucao SQL:" + _oSQL:_sQuery
				_oBatch:Retorno = 'N'
				_lContinua = .F.
			endif
			
			_sErroAuto = ""   // Erros e mensagens customizadas serao gravados aqui
			_sMsgErro  = ""
			_sStatMerc = ''

			// Verificacoes basicas...
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + (_sAliasQ) -> zc5_vend1, .F.))
				_sMsgErro += "Representante '" + (_sAliasQ) -> zc5_vend1 + "' nao cadastrado."
			endif
//			da0 -> (dbsetorder (1))  // DA0_FILIAL+DA0_CODTAB
//			if ! da0 -> (dbseek (xfilial ("DA0") + (_sAliasQ) -> zc5_tabela, .F.))
//				_sMsgErro += "Tabela de precos '" + (_sAliasQ) -> zc5_tabela + "' nao cadastrada."
//			else
//				if da0 -> da0_datde > dDataBase .or. da0 -> da0_datate < dDataBase .or. da0 -> da0_ativo != '1'
//					_sMsgErro += "Tabela de precos '" + (_sAliasQ) -> zc5_tabela + "' inativa ou fora de vigencia."
//				endif
//			endif
			se4 -> (dbsetorder (1))
			if ! se4 -> (dbseek (xfilial ("SE4") + (_sAliasQ) -> zc5_condpa, .F.))
				_sMsgErro += "Condicao de pagamento '" + (_sAliasQ) -> zc5_condpa + "' nao cadastrada."
			endif
			if U_TemNick ("SC5", "C5_VAPDMER")
				sc5 -> (dbOrderNickName ("C5_VAPDMER"))
				if sc5 -> (dbseek (xfilial ("SC5") + (_sAliasQ) -> zc5_pedmer, .T.))
					_sMsgErro += "Pedido mercanet '" + alltrim ((_sAliasQ) -> zc5_pedmer) + "' ja importado (numero Protheus: '" + sc5 -> c5_num + "')."
				endif
			else
				_sMsgErro += "Falta indice com nickname '" + C5_VAPDMER + "'."
			endif
			
			
			// Existem infelizes casos onde o cliente estah sem os zeros no inicio (Ex.: cliente '4986  ')
			// Por isso, busca tambem pelo CNPJ.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DB_CLI_CGCMF"
			_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".DB_CLIENTE, " + _sLinkSrv + ".DB_PEDIDO"
			_oSQL:_sQuery +=  " WHERE DB_CLI_CODIGO = DB_PED_CLIENTE"
			_oSQL:_sQuery +=    " AND DB_PED_NRO = " + substr ((_sAliasQ) -> zc5_pedmer, 1, 4) + substr ((_sAliasQ) -> zc5_pedmer, 6, 4)
			_oSQL:Log ()
			_sCNPJ = _oSQL:RetQry ()
			u_log ('CNPJ:', _sCNPJ)
			sa1 -> (dbsetorder (1))
			if sa1 -> (dbseek (xfilial ("SA1") + (_sAliasQ) -> zc5_client + (_sAliasQ) -> zc5_lojacl, .F.)) .and. alltrim (sa1 -> a1_cgc) != alltrim (_sCNPJ)
				// Como sao casos de aberracoes, alienigenas, gremlins, etc... prefiro tratar caso a caso quando ocorrerem.
				do case
				case (_sAliasQ) -> zc5_client == '004986' .and. (_sAliasQ) -> zc5_lojacl == '01'
					_sCliente = '4986  '
					_sLojaCli = '01'
				case (_sAliasQ) -> zc5_client == '010013' .and. (_sAliasQ) -> zc5_lojacl == '01'
					_sCliente = '10013 '
					_sLojaCli = '01'
				case (_sAliasQ) -> zc5_client == '004954' .and. (_sAliasQ) -> zc5_lojacl == '01'
					_sCliente = '4954  '
					_sLojaCli = '01'
				case (_sAliasQ) -> zc5_client == '010006' .and. (_sAliasQ) -> zc5_lojacl == '01'
					_sCliente = '10006 '
					_sLojaCli = '01'
				otherwise
					_sMsgErro += "Cliente '" + (_sAliasQ) -> zc5_client + '/' + (_sAliasQ) -> zc5_lojacl + "' informado no pedido tem CNPJ '" + _sCNPJ + "' no Mercanet e '" + sa1 -> a1_cgc + "' no Protheus. Verifique viabilidade/necessidade de criar tratamento no programa " + procname ()
				endcase
			else
				_sCliente = (_sAliasQ) -> zc5_client
				_sLojaCli = (_sAliasQ) -> zc5_lojacl
			endif
			
			//Valida��o para filiais
			if sa1 -> a1_vafilat != cFilAnt
				u_help ("Cliente " + sa1 -> a1_cod + " configurado (campo '" + alltrim (rettitle ("A1_VAFILAT")) + ") para ser atendido pela filial " + sa1 -> a1_vafilat + ". Pedido '" + alltrim ((_sAliasQ) -> zc5_pedmer) + "' n�o ser� processado.")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZC5010 "
				_oSQL:_sQuery +=   " SET ZC5_DTINI  = '',"
				_oSQL:_sQuery +=       " ZC5_HRINI  = '',"
//				_oSQL:_sQuery +=       " ZC5_ERRO   = 'Filiais n�o s�o iguais.'"
				_oSQL:_sQuery +=       " ZC5_ERRO   = 'Cliente '" + sa1 -> a1_cod + "' configurado (campo '" + alltrim (rettitle ("A1_VAFILAT")) + "') para ser atendido pela filial '" + sa1 -> a1_vafilat + "'. Pedido nao vai ser processado nesta filial.'"
				_oSQL:_sQuery += " WHERE ZC5_FILA   = '" + _sFila + "'"
				_oSQL:_sQuery +=   " AND ZC5_PEDMER = '" + _sPedMer + "'"
				_oSQL:_sQuery +=   " AND ZC5_FILIAL = 1"
				_oSQL:Log ()
				if ! _oSQL:Exec ()
					_oBatch:Mensagens += "Erro execucao SQL:" + _oSQL:_sQuery
					_oBatch:Retorno = 'N'
					_lContinua = .F.
				endif
				do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zc5_fila == _sFila .and. (_sAliasQ) -> zc5_pedmer == _sPedMer
					(_sAliasQ) -> (dbskip())
				enddo
				loop

			endif
			
			//// Por enquanto o Mercanet considera apenas tabelas da matriz.
			//if cFilAnt == '01'
				da0 -> (dbsetorder (1))  // DA0_FILIAL+DA0_CODTAB
				if ! da0 -> (dbseek (xfilial ("DA0") + (_sAliasQ) -> zc5_tabela, .F.))
					_sMsgErro += "Tabela de precos '" + (_sAliasQ) -> zc5_tabela + "' nao cadastrada."
				else
					if da0 -> da0_datde > dDataBase .or. da0 -> da0_datate < dDataBase .or. da0 -> da0_ativo != '1'
						_sMsgErro += "Tabela de precos '" + (_sAliasQ) -> zc5_tabela + "' inativa ou fora de vigencia."
					endif
				endif
			//endif

			_sDesbloq = ''
			if ! sa1 -> (dbseek (xfilial ("SA1") + _sCliente + _sLojaCli, .F.))
				_sMsgErro ("Cliente'" + _sCliente + '/' + _sLojaCli + "' n�o localizado.")
			else
				if sa1 -> a1_msblql = '1'
					reclock ("SA1", .F.)
					sa1 -> a1_msblql = '2'
					MSUNLOCK ()
					_sDesbloq = '1'
				endif
			endif

			// Monta array de cabecalho para geracao do pedido.
			_aAutoSC5 = {}
			if empty (_sMsgErro)
				aadd (_aAutoSC5, {"C5_VAPDMER", (_sAliasQ) -> zc5_pedmer, NIL})
				aadd (_aAutoSC5, {"C5_EMISSAO", stod ((_sAliasQ) -> zc5_emissa), NIL})
//				aadd (_aAutoSC5, {"C5_CLIENTE", (_sAliasQ) -> zc5_client, NIL})
//				aadd (_aAutoSC5, {"C5_LOJACLI", (_sAliasQ) -> zc5_lojacl, NIL})
				aadd (_aAutoSC5, {"C5_CLIENTE", _sCliente, NIL})
				aadd (_aAutoSC5, {"C5_LOJACLI", _sLojaCli, NIL})
				aadd (_aAutoSC5, {"C5_TPFRETE", (_sAliasQ) -> zc5_tpfret, NIL})
				aadd (_aAutoSC5, {"C5_CONDPAG", (_sAliasQ) -> zc5_condpa, NIL})
				if se4 -> e4_tipo == '9'  // dias fixos
					aadd (_aAutoSC5, {"C5_PARC1", 100, NIL})
					aadd (_aAutoSC5, {"C5_DATA1", DataValida (date () + 30), NIL})
				endif
				aadd (_aAutoSC5, {"C5_TABELA",  (_sAliasQ) -> zc5_tabela, NIL})
				aadd (_aAutoSC5, {"C5_VEND1",   (_sAliasQ) -> zc5_vend1, NIL})
				aadd (_aAutoSC5, {"C5_TIPO",    "N", NIL})
				aadd (_aAutoSC5, {"C5_VAUSER",  sa3 -> a3_nome, NIL})
				aadd (_aAutoSC5, {"C5_MENNOTA", alltrim (left ((_sAliasQ) -> zc5_mennot, tamsx3 ("C5_MENNOTA")[1])), NIL})
				if ! empty ((_sAliasQ) -> zc5_pedcli)
					aadd (_aAutoSC5, {"C5_PEDCLI",  alltrim ((_sAliasQ) -> zc5_pedcli), NIL})
				endif
//				aadd (_aAutoSC5, {"C5_OBS",     alltrim ((_sAliasQ) -> zc5_obs), NIL})
				aadd (_aAutoSC5, {"C5_OBS",     U_NoAcento (alltrim ((_sAliasQ) -> zc5_obs)), NIL})
				aadd (_aAutoSC5, {"C5_VAOBSLG", alltrim (left ((_sAliasQ) -> zc5_vaobslg, tamsx3 ("C5_VAOBSLG")[1])), NIL})
				
				// Para condicao a vista queremos sempre banco CX1.
				if (_sAliasQ) -> zc5_condpa == '097'
					aadd (_aAutoSC5, {"C5_BANCO", 'CX1' , NIL})
				else
					if ! empty ((_sAliasQ) -> zc5_banco)
						aadd (_aAutoSC5, {"C5_BANCO",   (_sAliasQ) -> zc5_banco, NIL})
					endif
				endif
				if (_sAliasQ) -> zc5_tpfret == 'C'
					aadd (_aAutoSC5, {"C5_TRANSP",  '', NIL})
				else
					aadd (_aAutoSC5, {"C5_TRANSP",  '', NIL})
					//aadd (_aAutoSC5, {"C5_TRANSP",  (_sAliasQ) -> zc5_transp, NIL})
				endif

//				if (_sAliasQ) -> zc5_tpfret == 'F' .and. ! empty ((_sAliasQ) -> zc5_transp) .and. val ((_sAliasQ) -> zc5_transp) > 0
//					aadd (_aAutoSC5, {"C5_TRANSP",  (_sAliasQ) -> zc5_transp, NIL})
//				else
//					aadd (_aAutoSC5, {"C5_TRANSP",  '', NIL})
//				endif

		
				// Ordena campos cfe. dicionario de dados.
				_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
				u_log (_aAutoSC5)
			endif

			_aAutoSC6 = {}
			do while _lContinua .and. ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zc5_fila == _sFila .and. (_sAliasQ) -> zc5_pedmer == _sPedMer
				u_log (' no item', _sMsgErro)
				if empty (_sMsgErro)
					_aLinhaSC6 = {}
					aadd (_aLinhaSC6, {"C6_ITEM",    strzero (len (_aAutoSC6) + 1, tamsx3 ("C6_ITEM")[1]), NIL})
					aadd (_aLinhaSC6, {"C6_VAITPME", (_sAliasQ) -> zc6_itpmer, NIL})
					aadd (_aLinhaSC6, {"C6_ENTREG",  stod ((_sAliasQ) -> zc6_entreg), NIL})
					aadd (_aLinhaSC6, {"C6_PRODUTO", (_sAliasQ) -> zc6_produt, NIL})
					aadd (_aLinhaSC6, {"C6_QTDVEN",  (_sAliasQ) -> zc6_qtdven, NIL})
					aadd (_aLinhaSC6, {"C6_TES",     (_sAliasQ) -> zc6_tes, NIL})
					aadd (_aLinhaSC6, {"C6_PRCVEN",  (_sAliasQ) -> zc6_vlr_liq, NIL})
					if ! empty ((_sAliasQ) -> zc5_pedcli)
						aadd (_aLinhaSC6, {"C6_NUMPCOM", alltrim ((_sAliasQ) -> zc5_pedcli), NIL})
						aadd (_aLinhaSC6, {"C6_ITEMPC", strzero (len (_aAutoSC6) + 1, tamsx3 ("C6_ITEMPC")[1]), NIL})
					endif
					if ! empty ((_sAliasQ) -> zc6_bonific)
						aadd (_aLinhaSC6, {"C6_BONIFIC", (_sAliasQ) -> zc6_bonific, NIL})
					endif
					aadd (_aLinhaSC6, {"C6_COMIS1",  (_sAliasQ) -> zc6_comis1, NIL})
					
					u_log ('zc5_pedcli:', (_sAliasQ) -> zc5_pedcli)
					u_log (_aLinhaSC6)
					
					// Ordena campos cfe. dicionario de dados
					_aLinhaSC6 = aclone (U_OrdAuto (_aLinhaSC6))
					aadd (_aAutoSC6, aclone (_aLinhaSC6))
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
	
			if len (_aAutoSC6) == 0
				_sMsgErro += "Nenhum item a ser gravado neste pedido."
				u_log (_sMsgErro)
			endif
			
			if empty (_sMsgErro)
			
				if len (_aAutoSC5) == 0 .or. len (_aAutoSC6) == 0
					_sMsgErro = "Nao encontrei cebecalho / itens para este pedido"
					_sStatMerc = 'ERR'
				else
		
					// Grava arrays e parametros no arquivo de log. Desabilitar quando entrar em producao.
					//u_log ("Dados para geracao do pedido:", _aAutoSC5)
					//for _i = 1 to len (_aAutoSC6)
						//u_log (_aAutoSC6 [_i])
					//next
					u_log ("Chamando MATA410")
					U_GravaSX1 ("MTA410", "01", 2)  // Sugere quantidade liberada no pedido = Nao
			
					lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
					lMsErroAuto := .F.  // necessario a criacao
					_sErroAuto  := ""   // Erros e mensagens customizadas serao gravados aqui
					sc5 -> (dbsetorder (1))
					DbSelectArea ("SC5")
					MATA410 (_aAutoSC5, _aAutoSc6,3)

					// Confirma sequenciais, se houver.
					do while __lSX8
						ConfirmSX8 ()
					enddo

					If lMsErroAuto
						_sMsgErro += iif (! empty (_sErroAuto), _sErroAuto + "; ", "")
						if ! empty (NomeAutoLog ())
							_sMsgErro += U_LeErro (memoread (NomeAutoLog ()))
						else
							_sMsgErro += "Impossivel ler arquivo de log de erros."
						endif
						u_log (_sMsgErro)
					else
						u_log ("Pedido gerado:", alltrim (_sPedMer) + '->' + sc5 -> c5_num)
						aadd (_aPedGer, alltrim (_sPedMer) + '->' + sc5 -> c5_num)
						
						// Grava evento no Protheus
						_oEvento = ClsEvent():New ()
					//	_oEvento:Texto    = "Ped. importado do Mercanet - ped.orig.: " + (_sAliasQ) -> zc5_pedmer
						_oEvento:Texto    = "Ped. importado do Mercanet - ped.orig.: " + _sPedMer
						_oEvento:CodEven  = "SC5006"
						_oEvento:PedVenda = sc5 -> c5_num
						_oEvento:Cliente  = sc5 -> c5_cliente
						_oEvento:LojaCli  = sc5 -> c5_lojacli
						_oEvento:Grava ()

						if se4 -> e4_tipo == '9'  // dias fixos
							U_ZZUNU ({"079"}, "Importado pedido com cond.pag.data fixa", "Pedido '" + sc5 -> c5_num + "' importado do Mercanet usando condicao de pagamento com data fixa. REVISE AS DATAS!", .F.)
						endif
					endif
				endif
			endif

			// Atualiza tabela de integracao no Mercanet.
			_sMsgErro = strtran (_sMsgErro, chr (13) + chr (10), ';')
			_sMsgErro = strtran (_sMsgErro, '"', '#')
			_sMsgErro = strtran (_sMsgErro, "'", '"')
			_sMsgErro = U_NoAcento (_sMsgErro)
			_sMsgErro = left (_sMsgErro, 1000)  // Tamanho do campo no database (se deixar maior ele nao grava)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZC5010 "
			_oSQL:_sQuery +=   " SET ZC5_STATUS = '" + iif (empty (_sMsgErro), "PRO", "ERR") + "',"
			_oSQL:_sQuery +=       " ZC5_DTFIM  = '" + dtos (date ()) + "',"
			_oSQL:_sQuery +=       " ZC5_HRFIM  = '" + time () + "',"
			_oSQL:_sQuery +=       " ZC5_ERRO   = '" + alltrim (_sMsgErro) + "'"
			if empty (_sMsgErro)
				_oSQL:_sQuery +=   ", ZC5_NUM  = '" + sc5 -> c5_num + "'"
			endif
			_oSQL:_sQuery += " WHERE ZC5_FILA   = '" + _sFila + "'"
			_oSQL:_sQuery +=   " AND ZC5_PEDMER = '" + _sPedMer + "'"
			_oSQL:_sQuery +=   " AND ZC5_FILIAL = 1"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				_oBatch:Mensagens += "Erro execucao SQL:" + _oSQL:_sQuery
				_oBatch:Retorno = 'N'
				_lContinua = .F.
			endif
			
			// Avisa setor comercial.
			if !empty (_sMsgErro)
				u_log (_sMsgErro)
				_oBatch:Mensagens += _sMsgErro
				U_ZZUNU ({'079'}, "Erro importacao pedido Mercanet " + _sPedMer, _sMsgErro)
			endif
			// voltar status do cliente do pedido
			if _sDesbloq = '1'
				reclock ("SA1", .F.)
				sa1 -> a1_msblql = '1'
				MSUNLOCK ()
				_sDesbloq = ''
			endif
	
		enddo
	endif

	//_oBatch:Mensagens = cvaltochar (len (_aPedGer)) + " pedido(s) gerado(s)"
	if len (_aPedGer) > 0
		_oBatch:Mensagens += "Ped.gerados:"
		for _nPedGer = 1 to len (_aPedGer)
			_oBatch:Mensagens += _aPedGer [_nPedGer] + iif (_nPedGer < len (_aPedGer), ';', '')
		next
	else
		_oBatch:Mensagens += "Nenhum pedido gerado"
	endif

	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_logFim ()
return
*/


// --------------------------------------------------------------------------
// Leitura de novos clientes do Mercanet
static function _LeCli (_sLinkSrv)
	local _nLock     := 0
	local _lContinua := .T.
	local _aAutoSA1  := {}
	local _sAliasQ   := ""
	local _sMsgErro  := ""
	local _sMsgUsr   := ""
	local _sCanal    := ""
	local _sSAtiv    := ""
	local _sSimpNac  := ""
	local _sEMail    := ""
	LOCAL _sStatMerc := ""
	Local aAI0Auto   := ""
	private _sErroAuto := ""  // Deixar private para ser vista por rotinas automaticas, etc.
	//oModel:= MPFormModel():New("MATA030",/*Pre-Validacao*/, /*Pos-Validacao*/, /*Commit*/,/*Cancel*/)
	oModel := FWLoadModel("MATA030")
	oModel:SetOperation(3)
	//oModel:Activate()
	u_logIni ()

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname (1) + procname ())
		if _nLock == 0
			u_log ("Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif
	
	if _lContinua

		// Cria arquivo de trabalho com os pedidos a importar.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT * FROM " + _sLinkSrv + ".ZA1010 "
		_oSQL:_sQuery += " WHERE ZA1_STATUS  = 'INS'"
		_oSQL:_sQuery += " AND ZA1_DTINI     = ''"
		_oSQL:_sQuery += " AND ZA1_HRINI     = ''"
		_oSQL:_sQuery += " ORDER BY ZA1_FILA"
		_oSQL:Log ()
		_sAliasQ := _oSQL:Qry2Trb ()

		if (_sAliasQ) -> (eof ())
			_oBatch:Mensagens = "Nenhum cliente a importar"
		endif

		do while _lContinua .and. ! (_sAliasQ) -> (eof ())
			
			// Avisa o Mercanet que estah iniciando o processamento deste registro.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZA1010 "
			_oSQL:_sQuery +=   " SET ZA1_DTINI  = '" + dtos (date ()) + "',"
			_oSQL:_sQuery +=       " ZA1_HRINI  = '" + time () + "'"
			_oSQL:_sQuery += " WHERE R_E_C_N_O_ = " + cvaltochar ((_sAliasQ) -> R_E_C_N_O_)
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				_oBatch:Mensagens += 'Erro no SQL:' + _oSQL:_sQuery
				_oBatch:Retorno = 'N'
				_lContinua = .F.
				loop
			endif
			
			_sErroAuto = ""   // Erros e mensagens customizadas serao gravados aqui
			_sMsgErro  = ""
			_sStatMerc = ''

			// Verifica se o CNPJ ja eocontra-se cadastrado como cliente.
			if _lContinua
				sa1 -> (dbsetorder (3))  // A1_FILIAL+A1_CGC
				if sa1 -> (dbseek (xfilial ("SA1") + (_sAliasQ) -> ZA1_CGC, .F.))
					_sStatMerc = 'PRO'
					_sMsgErro = "CNPJ ja cadastrado com codigo " + sa1 -> a1_cod + "/" + sa1 -> a1_loja
					_lContinua = .F.
				endif
			endif

			if _lContinua
				sa3 -> (dbsetorder (1))
				if ! sa3 -> (dbseek (xfilial ("SA3") + substr ((_sAliasQ) -> ZA1_VEND, 4, 3), .F.))
					_sMsgErro += "Representante '" + substr ((_sAliasQ) -> ZA1_VEND, 4, 3) + "' nao cadastrado."
					_lContinua = .F.
				endif
//				if (_sAliasQ) -> ZA1_PESSOA != 'J' .or. len (alltrim ((_sAliasQ) -> ZA1_CGC)) < 14
//					_sMsgErro += "Aceitaremos somente CNPJ."
//					_lContinua = .F.
//				endif
			endif
			
			// Busca dados adicionais que nao constam na integracao.
			if _lContinua
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT ISNULL (CLI.DB_CLI_RAMATIV, '') AS CANAL,"
				_oSQL:_sQuery +=       " ISNULL (COMPL.DB_CLIC_RAMATIVII, '') AS SATIV,"
				_oSQL:_sQuery +=       " COMPL.DB_CLIC_OPTSIMPLES AS SIMPNAC,"
				_oSQL:_sQuery +=       " COMPL.DB_CLIC_EMAIL"
				_oSQL:_sQuery +=  " FROM " + _sLinkSrv + ".DB_CLIENTE CLI"
				_oSQL:_sQuery +=  " LEFT JOIN " + _sLinkSrv + ".DB_CLIENTE_COMPL COMPL"
				_oSQL:_sQuery +=       " ON (COMPL.DB_CLIC_COD = CLI.DB_CLI_CODIGO)"
				_oSQL:_sQuery += " WHERE DB_CLI_CGCMF = '" + (_sAliasQ) -> ZA1_CGC + "'"
				//_oSQL:Log ()
				_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aRetQry)
					_sCanal   = _aRetQry [1, 1]
					_sSAtiv   = _aRetQry [1, 2]
					_sSimpNac = iif (_aRetQry [1, 3] == '1', '1', '2')
					_sEMail   = _aRetQry [1, 4]  // Vem cortado na tabela ZA1010
				endif
			endif
	
			if _lContinua
				oModel:Activate()
				// Monta array de dados para inclusao do cadastro.
				oSA1Mod:= oModel:getModel("MATA030_SA1")
				oSA1Mod:SetValue("A1_NOME",		_NoAcento ((_sAliasQ) -> za1_nome))	
				oSA1Mod:SetValue("A1_PESSOA",	(_sAliasQ) -> ZA1_PESSOA)	
				oSA1Mod:SetValue("A1_TIPO",		'S')	
				oSA1Mod:SetValue("A1_NREDUZ",	_NoAcento ((_sAliasQ) -> ZA1_NREDUZ))	
				oSA1Mod:SetValue("A1_END",		_NoAcento ((_sAliasQ) -> ZA1_END))	
				oSA1Mod:SetValue("A1_EST",		(_sAliasQ) -> ZA1_EST)
				oSA1Mod:SetValue("A1_COD_MUN",	(_sAliasQ) -> ZA1_COD_MU)
				oSA1Mod:SetValue("A1_BAIRRO",	_NoAcento ((_sAliasQ) -> ZA1_BAIRRO))
				oSA1Mod:SetValue("A1_CEP",		(_sAliasQ) -> ZA1_CEP)	
				oSA1Mod:SetValue("A1_TEL",		strtran (strtran (strtran (alltrim ((_sAliasQ) -> ZA1_TEL), '-'), '.'), ' '))
				oSA1Mod:SetValue("A1_FAX",		(_sAliasQ) -> ZA1_FAX)
				oSA1Mod:SetValue("A1_CONTATO",	'')
				oSA1Mod:SetValue("A1_CGC",		(_sAliasQ) -> ZA1_CGC)
				oSA1Mod:SetValue("A1_INSCR",	(_sAliasQ) -> ZA1_INSCR)		
				oSA1Mod:SetValue("A1_VEND",		sa3 -> a3_cod)
				if empty ((_sAliasQ) -> ZA1_BCO1)
					oSA1Mod:SetValue("A1_BCO1",	'CX1')
					oSA1Mod:SetValue("A1_FORMA",'2')
				else
					oSA1Mod:SetValue("A1_BCO1",	(_sAliasQ) -> ZA1_BCO1)
					oSA1Mod:SetValue("A1_FORMA",'1')
				endif
				oSA1Mod:SetValue("A1_ULTVIS",	stod (substr ((_sAliasQ) -> ZA1_ULTVIS, 5, 4) + substr ((_sAliasQ) -> ZA1_ULTVIS, 3, 2) + substr ((_sAliasQ) -> ZA1_ULTVIS, 1, 2)))
				oSA1Mod:SetValue("A1_CXPOSTA",	(_sAliasQ) -> ZA1_CXPOST)
				if ! empty ((_sAliasQ) -> ZA1_ENDCOB)
					oSA1Mod:SetValue("A1_ENDCOB",	(_sAliasQ) -> ZA1_ENDCOB)
					oSA1Mod:SetValue("A1_BAIRROC",	_NoAcento ((_sAliasQ) -> ZA1_BAIRRC))
					oSA1Mod:SetValue("A1_CEPC",		(_sAliasQ) -> ZA1_CEPC)
					oSA1Mod:SetValue("A1_MUNC",		_NoAcento ((_sAliasQ) -> ZA1_MUNC))
					oSA1Mod:SetValue("A1_ESTC",		(_sAliasQ) -> ZA1_ESTC)
				endif
				oSA1Mod:SetValue("A1_EMAIL",	left(_sEMail,tamSX3('A1_EMAIL')[1]))
				oSA1Mod:SetValue("A1_VAMDANF",	left(_sEMail,tamSX3('A1_VAMDANF')[1]))		
				oSA1Mod:SetValue("A1_HPAGE",	(_sAliasQ) -> ZA1_HPAGE)		
				oSA1Mod:SetValue("A1_VAUSER",	left(_NoAcento (sa3 -> a3_nome),tamSX3('A1_VAUSER')[1]))
				oSA1Mod:SetValue("A1_VACANAL",	left(_sCanal,tamSX3('A1_VACANAL')[1]))
				oSA1Mod:SetValue("A1_SATIV1",	_sSativ)
				oSA1Mod:SetValue("A1_SIMPNAC",	_sSimpNac)
				oSA1Mod:SetValue("A1_VABARAP",	'0')
				oSA1Mod:SetValue("A1_VADTINC",	DATE())
				if (_sAliasQ) -> ZA1_INSCR != 'ISENTO' .or. !empty ((_sAliasQ) -> ZA1_INSCR)
					oSA1Mod:SetValue("A1_IENCONT",	'1')
					oSA1Mod:SetValue("A1_CONTRIB",	'1')
				else
					oSA1Mod:SetValue("A1_IENCONT",	'2')
					oSA1Mod:SetValue("A1_CONTRIB",	'2')
				endif
				oSA1Mod:SetValue("A1_CNAE",	'0000-0/00')
				U_LOG (_aAutoSA1)
								
				// Ordena campos cfe. dicionario de dados.
				//_aAutoSA1 = aclone (U_OrdAuto (_aAutoSA1))
				//u_log(_aAutoSA1)
				//lMsHelpAuto := .F.  // se .T. direciona as mensagens de help
				lMsErroAuto := .F.  // necessario a criacao
				_sErroAuto  := ""   // Erros e mensagens customizadas serao gravados aqui
				//sa1 -> (dbsetorder (1))
				//DbSelectArea ("SA1")
				//MATA030 (_aAutoSA1, 3)
					
				// Confirma sequenciais, se houver.
				do while __lSX8
					ConfirmSX8 ()
				enddo
				
				If oModel:VldData()
	      
				    //Tenta realizar o Commit
				    If oModel:CommitData()
				    	_sStatMerc = 'PRO'
				    	u_log('GRAVOU', SA1->A1_COD)
				        lDeuCerto := .T.
				          
				    //Se n�o deu certo, altera a vari�vel para false
				    Else
				    	_sStatMerc = 'ERR'
				        lDeuCerto := .F.
				    EndIf
			      
				//Se n�o conseguir validar as informa��es, altera a vari�vel para false
				Else
				    lDeuCerto := .F.
				EndIf
			  
				//Se n�o deu certo a inclus�o, mostra a mensagem de erro
				If ! lDeuCerto
				    //Busca o Erro do Modelo de Dados
				    aErro := oModel:GetErrorMessage()
				      
				    //Monta o Texto que ser� mostrado na tela
				    
				    _sMsgErro += ("Id do formul�rio de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
				    _sMsgErro += ("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
				    _sMsgErro += ("Id do formul�rio de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
				    _sMsgErro += ("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
				    _sMsgErro += ("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
				    _sMsgErro += ("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
				    _sMsgErro += ("Mensagem da solu��o: "        + ' [' + AllToChar(aErro[07]) + ']')
				    _sMsgErro += ("Valor atribu�do: "            + ' [' + AllToChar(aErro[08]) + ']')
				    _sMsgErro += ("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')
				    
				else
					// Grava evento no Protheus
					_oEvento = ClsEvent():New ()
					_oEvento:Texto     = "Cliente " + sa1 -> a1_cod + "/" + a1_loja + " (UF=" + sa1 -> a1_est + ") importado do sistema Mercanet" + chr (13) + chr (10) + _sMsgUsr
					_oEvento:CodEven   = "SA1003"
					_oEvento:Cliente   = sa1 -> a1_cod
					_oEvento:LojaCli   = sa1 -> a1_loja
					_oEvento:MailToZZU = {'079'}
					_oEvento:Grava ()
					
					//Mercanet n�o tem esse campo, for�ado a passar zero, depois limpa para preenchimento adequado.
					reclock ("SA1", .F.)
					SA1 -> A1_CNAE = ''
					MSUNLOCK ()
					_oBatch:Mensagens += sa1 -> a1_cod + "/" + sa1 -> a1_loja + ' '
				endif
			
		    //Desativa o modelo de dados
		    oModel:DeActivate()
			endif
				
			// Atualiza tabela de integracao no Mercanet.
			_sMsgErro = strtran (_sMsgErro, chr (13) + chr (10), ';')
			_sMsgErro = strtran (_sMsgErro, '"', '#')
			_sMsgErro = strtran (_sMsgErro, "'", '"')
			_sMsgErro = U_NoAcento (_sMsgErro)
			_sMsgErro = left (_sMsgErro, 250)  // Tamanho no database
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZA1010 "
			//_oSQL:_sQuery +=   " SET ZA1_STATUS = '" + iif (empty (_sMsgErro), "PRO", "ERR") + "',"
			_oSQL:_sQuery +=   " SET ZA1_STATUS = '" + _sStatMerc + "',"
			_oSQL:_sQuery +=       " ZA1_DTFIM  = '" + dtos (date ()) + "',"
			_oSQL:_sQuery +=       " ZA1_HRFIM  = '" + time () + "',"
			_oSQL:_sQuery +=       " ZA1_ERRO   = '" + alltrim (_sMsgErro) + "'"
			//if empty (_sMsgErro)
			if _sStatMerc == 'PRO'
				_oSQL:_sQuery +=   ", ZA1_COD   = '" + sa1 -> a1_cod + "'"
				_oSQL:_sQuery +=   ", ZA1_LOJA  = '" + sa1 -> a1_loja + "'"
			endif
			_oSQL:_sQuery += " WHERE R_E_C_N_O_ = " + cvaltochar ((_sAliasQ) -> R_E_C_N_O_)
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				_oBatch:Mensagens += 'Erro no SQL:' + _oSQL:_sQuery
				_oBatch:Retorno = 'N'
				_lContinua = .F.
				loop
			endif
			_sMsgErro = ''
			aErro = {}
			(_sAliasQ) -> (dbskip ())
			
		enddo
	endif
	_oBatch:Mensagens += _sMsgErro

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _NoAcento (_sTexto)
return strtran (U_NoAcento (_sTexto), '&', 'e')

// --------------------------------------------------------------------------
static function _AtuReferencia (_sTexto)


		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT * "
		_oSQL:_sQuery += " FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_CLIENTE_REFERENCIA "
		_oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
		_oSQL:_sQuery += "	 ON (SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "		AND SA1.A1_FILIAL = '' "
		_oSQL:_sQuery += "		AND SA1.A1_COD = REPLICATE('0', 6 - LEN(CLIENTE)) + RTRIM(CLIENTE)) "
		_oSQL:_sQuery += " WHERE NOT EXISTS (SELECT * "
		_oSQL:_sQuery += " 	FROM " + RetSQLName ("SAO") + " SAO "
		_oSQL:_sQuery += "	WHERE SAO.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += "  AND SAO.AO_FILIAL = '01' "
		_oSQL:_sQuery += "	AND SAO.AO_CLIENTE = SA1.A1_COD)"
		
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb ()
		u_logtrb (_sAliasQ, .T.)
		(_sAliasQ) -> (dbgotop ())
		_sItem1 == '01'
		_sItem2 == '01'
		_sItem3 == '01'
		do while ! (_sAliasQ) -> (eof ())
			reclock ("SAO", .T.)
			sao -> sao_filial  = xfilial ("SAO")
			sao -> sao_cliente = (_sAliasQ) -> CLIENTE
			sao -> sao_loja    = '01'
			if (_sAliasQ) -> TIPO = '01'
				sao -> sao_tipo   = '03'
				sao -> sao_item    = _sItem3
				_sItem3 = Soma1(_sItem3)
			else
				sao -> sao_tipo   = (_sAliasQ) -> TIPO
				sao -> sao_item    = _sItem2
				_sItem2 = Soma1(_sItem2)
			endif
			sao -> sao_nomins  = (_sAliasQ) -> REFERENCIA
//			sao -> sao_data    =  
//			sao -> sao_nomfun  = 
			sao -> sao_telefon = (_sAliasQ) -> TELEFONE
//			sao -> sao_contato = 
//			sao -> sao_desde   = 
//			sao -> sao_ultcom  = 
//			sao -> sao_maicom  =  
			sao -> sao_vlrmai  = (_sAliasQ) -> VOLUME_MES_COMPRAS
//			sao -> sao_pagpon  = 
//			sao -> sao_bcocar  = 
			sao -> sao_agencia = (_sAliasQ) -> AGENCIA
//			sao -> sao_limcre  = 
//			sao -> sao_movcc   = 
//			sao -> sao_outope  = 
//			sao -> sao_observ  = 
			sao -> sao_prfpag  = (_sAliasQ) -> PERFIL_PAGAMENTO 
			sao -> sao_credito = (_sAliasQ) -> CREDITO
			sao -> sao_impcli  = (_sAliasQ) -> IMPORTANCIA
			msunlock ()
			(_sAliasQ) -> (dbskip ())
			
		enddo
RETURN
		
		
		
		
		
		