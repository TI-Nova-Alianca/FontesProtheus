// Programa.:  BatMerc
// Autor....:  Robert Koch
// Data.....:  11/11/2016
// Descricao:  Verifica necessidade de integracoes com Mercanet.
//             Criado para ser executado via batch.
// 
//  #TipoDePrograma    #Batch
//  #Descricao         #Verifica necessidade de integracoes com Mercanet.
//  #PalavasChave      #Mercanet #integracao 
//  #TabelasPrincipais #ZA1 
//  #Modulos 		   #FAT 
//
// Historico de alteracoes:
// 01/03/2017 - Robert  - Chamada da funcao ConfirmSXC8() apos o MATA410 para tentar eliminar perda se 
//                        sequencia de numero de pedidos.
// 03/05/2017 - Robert  - Obriga banco CX1 quando cond.pag.097 (a vista).
// 26/06/2017 - Robert  - Busca campos Canal, Segmento, Opt.simples nacional nas tabelas do Mercanet, pois nao vem no ZA1010.
// 17/07/2017 - Robert  - Envia e-mail notificando erro na importacao de clientes.
// 28/07/2017 - Robert  - Busca e-mail direto das tabelas do Mercanet por que vem cortado na tabela ZA1010.
//                      - Tratamento para converter 'optante simples nacional' de 0 (Mercanet) para 2 (Protheus).
// 05/10/2017 - Robert  - Gravacao do campo C6_NUMPCOM.
// 19/02/2018 - Robert  - Campo A1_VABARAP passa a ser obrigatorio no SA1.
// 20/02/2018 - Robert  - Verifica se o CNPJ ja encontra-se cadastrado como cliente e grava codigo na tabela de retorno.
// 31/07/2018 - Robert  - Grava msg de erro no batch em caso de erro na execucao de algum SQL.
// 01/08/2018 - Robert  - Consiste CNPJ do cliente (raros casos de codigo sem zeros a esquerda no Protheus).
// 27/08/2018 - Robert  - Tratamento campo A1_FORMA.
// 17/10/2018 - Robert  - Criado tratamento para cliente '10013 ' (sem zero a esquerda).
// 30/10/2018 - Robert  - Criado tratamento para cliente '4954  ' (sem zero a esquerda).
// 23/01/2019 - Andre   - Criada novas regras para preenchimeno de novos campos obrigatorios no Protheus (A1_IENCONT, A1_CONTRIB).
// 30/04/2019 - Andre   - Incluido campos de integração da referencias bancarias/comerciais dos cliente vindas do Mercanet.
// 02/08/2019 - Robert  - Liberada importação de clientes pessoa fisica - GLPI 5846.
// 23/08/2019 - Andre   - Alterada rotina automatica para cadastro de CLIENTES.
// 10/10/2019 - Andre   - Caso cliente seja bloqueado, muda status do cliente para poder incluir pedido. 
//						  Depois de incluido, volta o status original do cliente.
// 14/11/2019 - Andre   - Adicionada validação para campo A1_VAFILAT.
// 05/12/2019 - Robert  - Ajustes para importar pedidos na filial 16
// 19/02/2020 - Andre   - Adicionada mesma regra para integração de pedidos com frete FOB. Leva em branco para Protheus.
// 06/05/2020 - Robert  - Desabilitada declaracao nome arquivo de log (aceita o que vier da rotina principal).
//                      - Numero do pedido do mercanet (zc5_pedmer) estava desposicionado nas mensagens de aviso.
// 08/05/2020 - Robert  - Melhoradas msg de erro
//                      - Campo ZC5_ERRO aumentado de 250 para 1000 caracteres.
// 11/05/2020 - Robert  - Importacao de pedidos passada para programa proprio (BatMercP.prw).
// 17/06/2021 - Claudia - Incluido os atributos de dados financeiros. GLPI: 9633
//
// ------------------------------------------------------------------------------------------------------------------------
user function BatMerc (_sQueFazer)
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _sLinkSrv := ""

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
//
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
		_oBatch:Mensagens += "Bloqueio de semaforo."
	else

		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ID, TIPO, RECNO, CHAVE1, CHAVE2, CHAVE3, CHAVE4, CHAVE5"
		_oSQL:_sQuery +=  " FROM VA_INTEGR_MERCANET"
		_oSQL:_sQuery += " ORDER BY ID"
		_aDados := _oSQL:Qry2Array (.F., .F.)
	
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
			
			if _oSQL:Exec ()
	
				// Elimina o registro da tabela de pendencias.
				_oSQL:_sQuery := "DELETE VA_INTEGR_MERCANET"
				_oSQL:_sQuery += " WHERE ID = " + cvaltochar (_aDados [_nDado, 1])
				
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
return
//
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
	private _sErroAuto := ""  // Deixar private para ser vista por rotinas automaticas, etc.
	
	oModel := FWLoadModel("MATA030")
	oModel:SetOperation(3)
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
				
				_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aRetQry)
					_sCanal   = _aRetQry [1, 1]
					_sSAtiv   = _aRetQry [1, 2]
					_sSimpNac = iif (_aRetQry [1, 3] == '1', '1', '2')
					_sEMail   = _aRetQry [1, 4]  // Vem cortado na tabela ZA1010
				endif
			endif

			// busca dados financeiros
			if _lContinua
				_sRet208 := ""
				_sRet209 := ""
				_sRet210 := ""
				_sRet212 := ""
				_sRet213 := ""
				_sRet214 := ""
				_sRet215 := ""

				// Contato financeiro 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 208 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet208 := _aAtrRet[1,1]
				endif

				// Telefone Financeiro 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 209 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet209 := _aAtrRet[1,1]
				endif

				// E-mail para cobrança 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 210 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet210 := _aAtrRet[1,1]
				endif

				// Banco 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 212 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet212 := _aAtrRet[1,1]
				endif

				// Agência 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 213 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet213 := _aAtrRet[1,1]
				endif

				// Conta corrente 
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 214 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet214 := _aAtrRet[1,1]
				endif

				// CNPJ favorecido
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := " SELECT "
				_oSQL:_sQuery += " 		db_clia_valor "
				_oSQL:_sQuery += " FROM " + _sLinkSrv + ".DB_CLIENTE_ATRIB "
				_oSQL:_sQuery += " WHERE db_clia_atrib = 215 "
				_oSQL:_sQuery += " AND db_clia_codigo = '" + (_sAliasQ) -> ZA1_CGC + "'"
				_aAtrRet := aclone (_oSQL:Qry2Array (.F., .F.))
				if len (_aAtrRet)
					_sRet215 := _aAtrRet[1,1]
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
				// dados financeiros
				oSA1Mod:SetValue("A1_CONTAT3"	, alltrim(_sRet208))  
				oSA1Mod:SetValue("A1_TELCOB"	, alltrim(_sRet209))  	
				oSA1Mod:SetValue("A1_VAEMLF"	, alltrim(_sRet210))  		
				oSA1Mod:SetValue("A1_VABCOF"	, alltrim(_sRet212))  	
				oSA1Mod:SetValue("A1_VAAGFIN"	, alltrim(_sRet213))  	
				oSA1Mod:SetValue("A1_VACTAFN"	, alltrim(_sRet214))  	
				oSA1Mod:SetValue("A1_VACGCFI"	, alltrim(_sRet215)) 

				U_LOG (_aAutoSA1)
								
				lMsErroAuto := .F.  // necessario a criacao
				_sErroAuto  := ""   // Erros e mensagens customizadas serao gravados aqui
					
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
				    //Se não deu certo, altera a variável para false
				    Else
				    	_sStatMerc = 'ERR'
				        lDeuCerto := .F.
				    EndIf			      
				//Se não conseguir validar as informações, altera a variável para false
				Else
				    lDeuCerto := .F.
				EndIf
			  
				//Se não deu certo a inclusão, mostra a mensagem de erro
				If ! lDeuCerto
				    //Busca o Erro do Modelo de Dados
				    aErro := oModel:GetErrorMessage()
				    
				    //Monta o Texto que será mostrado na tela				    
				    _sMsgErro += ("Id do formulário de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
				    _sMsgErro += ("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
				    _sMsgErro += ("Id do formulário de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
				    _sMsgErro += ("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
				    _sMsgErro += ("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
				    _sMsgErro += ("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
				    _sMsgErro += ("Mensagem da solução: "        + ' [' + AllToChar(aErro[07]) + ']')
				    _sMsgErro += ("Valor atribuído: "            + ' [' + AllToChar(aErro[08]) + ']')
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
					
					//Mercanet não tem esse campo, forçado a passar zero, depois limpa para preenchimento adequado.
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
			_oSQL:_sQuery +=   " SET ZA1_STATUS = '" + _sStatMerc + "',"
			_oSQL:_sQuery +=       " ZA1_DTFIM  = '" + dtos (date ()) + "',"
			_oSQL:_sQuery +=       " ZA1_HRFIM  = '" + time () + "',"
			_oSQL:_sQuery +=       " ZA1_ERRO   = '" + alltrim (_sMsgErro) + "'"
			
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
//
// --------------------------------------------------------------------------
// Retira caracteres especiais
static function _NoAcento (_sTexto)
return strtran (U_NoAcento (_sTexto), '&', 'e')
