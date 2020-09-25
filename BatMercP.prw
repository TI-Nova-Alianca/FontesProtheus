// Programa...: BatMercP
// Autor......: Robert Koch
// Data.......: 11/11/2016
// Descricao..: Importa pedidos de venda do sistema Mercanet.
//              Criado para ser executado via batch.
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Importa pedidos de venda do sistema Mercanet.
// #PalavasChave      #mercanet #pedidos_de_venda #importacao
// #TabelasPrincipais #SC5 #SC6 #ZC5
// #Modulos           #FAT
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
// 23/01/2019 - Andre  - Criada novas regras para preenchimeno de novos campos obrigatorios no Protheus 
//						 (A1_IENCONT, A1_CONTRIB).
// 30/04/2019 - Andre  - Incluido campos de integração da referencias bancarias/comerciais dos cliente vindas do Mercanet.
// 02/08/2019 - Robert - Liberada importação de clientes pessoa fisica - GLPI 5846.
// 23/08/2019 - Andre  - Alterada rotina automatica para cadastro de CLIENTES.
// 10/10/2019 - Andre  - Caso cliente seja bloqueado, muda status do cliente para poder incluir pedido. 
//						 Depois de incluido, volta o status original do cliente.
// 14/11/2019 - Andre  - Adicionada validação para campo A1_VAFILAT.
// 05/12/2019 - Robert - Ajustes para importar pedidos na filial 16
// 19/02/2020 - Andre  - Adicionada mesma regra para integração de pedidos com frete FOB. Leva em branco para Protheus.
// 06/05/2020 - Robert - Desabilitada declaracao nome arquivo de log (aceita o que vier da rotina principal).
//                     - Numero do pedido do mercanet (zc5_pedmer) estava desposicionado nas mensagens de aviso.
// 08/05/2020 - Robert - Melhoradas msg de erro
//                     - Campo ZC5_ERRO aumentado de 250 para 1000 caracteres.
// 14/05/2020 - Robert - Desmembrado do BatMerc (tinha varias funcionalidades no mesmo programa e ficava confuso).
// 22/06/2020 - Robert - Funcao U_LkSrvMer() renomeada para U_LsServer().
//
// -----------------------------------------------------------------------------------------------------------------
user function BatMercP ()
	local _lContinua := .T.
	local _nLock     := 0

	u_log2 ('info', 'Iniciando execucao')

	// Deixa retorno pronto para chamada em batch.
	_oBatch:Retorno = 'S'

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	if _lContinua
		_nLock := U_Semaforo (procname () + '_EmpFil_' + cEmpAnt + cFilAnt)
		if _nLock == 0
			_lContinua = .F.
			_oBatch:Mensagens += "Bloqueio de semaforo."
		endif
	endif
		
	if _lContinua
		_LePed ()
	endif

	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

	u_log2 ('info', 'Mensagens do objeto batch: ' + _oBatch:Mensagens)
	u_log2 ('info', 'Processo finalizado')
return .T.
//
// --------------------------------------------------------------------------
// Leitura de pedidos do Mercanet
static function _LePed ()
	local _oSQL      := NIL
	local _aAutoSC5  := {}
	local _aAutoSC6  := {}
	local _aLinhaSC6 := {}
	local _sFila     := ""
	local _sPedMer   := ""
	local _oEvento   := NIL
	local _sAliasQ   := ""
	local _sMsgErro  := ""
	local _sStatMerc := ""
	local _lContinua := .T.
	local _aPedGer   := {}
	local _nPedGer   := 0
	local _sCliente  := ""
	local _sLojaCli  := ""
	local _aCNPJ     := {}
	local _sLinkSrv  := ""
	private lMsHelpAuto := .F.
	private lMsErroAuto := .F.
	private _sErroAuto  := ""  // Deixar private para que a funcao U_Help possa gravar possiveis mensagens durante as rotinas automaticas.

	// Busca o caminho do banco de dados do Mercanet.
	_sLinkSrv = U_LkServer ('Mercanet')

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
			_oBatch:Mensagens = "Nenhum pedido a importar."
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
			_oSQL:_sQuery += " SELECT DISTINCT DB_PED_CLIENTE, ISNULL (DB_CLI_CGCMF, '')"
			_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".DB_PEDIDO "
			_oSQL:_sQuery +=   " LEFT JOIN " + _sLinkSrv + ".DB_CLIENTE ON (DB_CLI_CODIGO = DB_PED_CLIENTE)"
			_oSQL:_sQuery +=  " WHERE DB_PED_NRO = " + substr ((_sAliasQ) -> zc5_pedmer, 1, 4) + substr ((_sAliasQ) -> zc5_pedmer, 6, 4)
			_oSQL:Log ()
			_aCNPJ = _oSQL:Qry2Array (.F., .F.)
			
			u_log2 ('info', 'Resultado da busca do cliente por CNPJ:')
			u_log2 ('info', _aCNPJ)
			
			if len (_aCNPJ) == 0
				_sMsgErro += "O pedido Mercanet '" + substr ((_sAliasQ) -> zc5_pedmer, 1, 4) + substr ((_sAliasQ) -> zc5_pedmer, 6, 4) + "' consta na tabela de pedidos a importar, mas nao o encontrei na tabela de pedidos!"
				do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zc5_fila == _sFila .and. (_sAliasQ) -> zc5_pedmer == _sPedMer
					(_sAliasQ) -> (dbskip())
				enddo
			else
				sa1 -> (dbsetorder (1))
				if sa1 -> (dbseek (xfilial ("SA1") + (_sAliasQ) -> zc5_client + (_sAliasQ) -> zc5_lojacl, .F.)) .and. alltrim (sa1 -> a1_cgc) != alltrim (_aCNPJ [1, 2])
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
						_sMsgErro += "Cliente '" + (_sAliasQ) -> zc5_client + '/' + (_sAliasQ) -> zc5_lojacl + "' informado no pedido tem CNPJ '" + _aCNPJ [1, 2] + "' no Mercanet e '" + sa1 -> a1_cgc + "' no Protheus. Verifique viabilidade/necessidade de criar tratamento no programa " + procname ()
					endcase
				else
					_sCliente = (_sAliasQ) -> zc5_client
					_sLojaCli = (_sAliasQ) -> zc5_lojacl
				endif
			endif
			
			//Validação para filiais
			if sa1 -> a1_vafilat != cFilAnt
				u_help ("Cliente " + sa1 -> a1_cod + " configurado (campo '" + alltrim (rettitle ("A1_VAFILAT")) + ") para ser atendido pela filial " + sa1 -> a1_vafilat + ". Pedido '" + alltrim ((_sAliasQ) -> zc5_pedmer) + "' não será processado.")
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "UPDATE " + _sLinkSrv + ".ZC5010 "
				_oSQL:_sQuery +=   " SET ZC5_DTINI  = '',"
				_oSQL:_sQuery +=       " ZC5_HRINI  = '',"
//				_oSQL:_sQuery +=       " ZC5_ERRO   = 'Filiais não são iguais.'"
				_oSQL:_sQuery +=       " ZC5_ERRO   = 'Cliente configurado para ser atendido por outra filial. Pedido nao vai ser processado nesta filial.'"
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
				_sMsgErro ("Cliente'" + _sCliente + '/' + _sLojaCli + "' nao localizado.")
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
				endif

				// Ordena campos cfe. dicionario de dados.
				_aAutoSC5 = aclone (U_OrdAuto (_aAutoSC5))
				u_log ('debug', _aAutoSC5)
			endif

			_aAutoSC6 = {}
			do while _lContinua .and. ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zc5_fila == _sFila .and. (_sAliasQ) -> zc5_pedmer == _sPedMer
				//u_log (' no item', _sMsgErro)
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
					
					u_log2 ('debug', 'zc5_pedcli: '+ (_sAliasQ) -> zc5_pedcli)
					u_log2 ('debug', _aLinhaSC6)
					
					// Ordena campos cfe. dicionario de dados
					_aLinhaSC6 = aclone (U_OrdAuto (_aLinhaSC6))
					aadd (_aAutoSC6, aclone (_aLinhaSC6))
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
	
			if len (_aAutoSC6) == 0
				_sMsgErro += "Nenhum item a ser gravado neste pedido."
				u_log2 ('erro', _sMsgErro)
			endif
			
			if empty (_sMsgErro)
			
				if len (_aAutoSC5) == 0 .or. len (_aAutoSC6) == 0
					_sMsgErro = "Nao encontrei cebecalho / itens para este pedido"
					_sStatMerc = 'ERR'
				else
		
					u_log2 ('info', "Chamando MATA410")
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
						u_log2 ('erro', _sMsgErro)
					else
						u_help ("Pedido gerado: " + alltrim (_sPedMer) + '->' + sc5 -> c5_num)
						aadd (_aPedGer, alltrim (_sPedMer) + '->' + sc5 -> c5_num)
						
						// Grava evento no Protheus
						_oEvento = ClsEvent():New ()
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
				u_log2 ('erro', _sMsgErro)
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
		_oBatch:Mensagens += "Nenhum pedido gerado."
	endif
return
