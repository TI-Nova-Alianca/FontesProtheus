// Programa...: _Mata460
// Autor......: Robert Koch
// Data.......: 25/02/2008
// Descricao..: Para ser chamado no menu em lugar do MATA460A.
//              Criado inicialmente para controle de semaforo e verificacoes iniciais.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Mascaramento da tela de faturamento de pedidos.
// #PalavasChave      #faturamento #MATA460 #preparacao_documento_saida #logistica #expedicao
// #TabelasPrincipais #SF2 #SC6 #SC9
// #Modulos           #FAT
//
// Historico de alteracoes:
// 01/12/2010 - Robert  - Libera semaforo logo apos a geracao das notas.
// 09/12/2010 - Robert  - Incluida coluna no browse com o total de volumes do pedido.
// 21/12/2010 - Robert  - Botao 'Revalidar pedidos' desabilitado, pois liberava todos os pedidos.
//                      - Leitura de pendencias passa a ser feita dentro de uma chamada MsgRun.
// 17/01/2011 - Robert  - Ao faltar estoque de um item, considerava faltantes todos os demais.
// 24/02/2011 - Robert  - Passa a ordenar os pedidos pelo campo C5_vaPrior, permitindo priorizar os pedidos.
// 31/03/2011 - Robert  - Verifica geracao de NF com mais de 30 dias retroativos.
// 16/12/2011 - Robert  - Funcao U_VerEstq passa a receber parametro de endereco de estoque.
// 16/03/2012 - Robert  - Passa a verificar o campo C5_VABLOQ.
// 01/11/2012 - Robert  - Ajustes para numeracao de notas com 9 posicoes.
// 10/07/2013 - Leandro - Alteração para que a filial de depósito não seja fixo '04', pegando da tebala ZS da SX5
// 19/09/2013 - Robert  - Passa a avisar quando pedido sem transportadora.
// 02/10/2013 - Robert  - Passa a bloquear pedidos sem transportadora.
//                      - Passa a mostrar o nome da transportadora.
// 05/11/2013 - Robert  - Passa a bloquear faturamento via deposito se houver transf.pendente parea almox. de retorno.
// 06/12/2013 - Robert  - Incluida verificacao tipo 21 para deposito fechado.
// 29/03/2014 - Robert  - Incluidas verificacoes para faturamento filial 01 via filial 13.
// 04/04/2014 - Robert  - Ajusta parametros do MATA460 quando o M460FIL nao estiver compilado.
// 23/07/2014 - Robert  - Monitor do SPED substituido por rotina customizada.
// 07/10/2014 - Robert  - Volta a verificar duplicidade de registros no SC9 (estava permitindo mais de um lote).
// 12/02/2015 - Robert  - Metodo ConsChv() trocado por ConsAutori() na consulta de autorizacao do SPED.
// 02/04/2015 - Catia   - Metodo ConsAutori() quando nao existia a nota estava retornar .F. alerado para ""
// 30/04/2015 - Robert  - Funcao _SPED passada para U_SpedAut ()
// 27/08/2015 - Robert  - Verificacoes adicionais - parecia prosseguir mesmo com erro na filtragem de pedidos.
// 09/03/2017 - Robert  - Passa a controlar semaforo concorrente com o U__MTA460B().
// 28/04/2017 - Robert  - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 11/07/2017 - Robert  - Removidos tratamentos para deposito fechado (filial 04) pois ha tempos foi fechada.
// 13/09/2017 - Robert  - Removidos mais tratamentos para deposito fechado.
//                      - Criada opcao de verificar apenas pedidos com carga/sem carga/todos.  
// 24/09/2018 - Catia   - Alterado para que permita faturar sem transportadora confome campo C5_TPFRETE - Adequação NFe 4.0
// 22/08/2019 - Robert  - Chama envio de XML mesmo em ambiente de teste (jah tem verificacao no U_SPEDAut)
// 25/02/2020 - Robert  - Passa a trabalhar com a array _aNComSono para saber quais as notas geradas. Antes apenas usava apenas uma
//                        faixa de numeracao, com a possibilidade de ter notas inutilizadas ou de entrada (formulário próprio) no meio.
// 31/07/2020 - Robert  - Melhorados avisos e logs.
//                      - Inseridas tags para catalogacao de fontes
// 12/02/2021 - Cláudia - Validação de cliente bloqueado. GLPI: 7982
//
// -------------------------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"  // Deixar este include para aparecerem os botoes da tela de acompanhamento do SPED

#XTranslate .PedOk             => 1
#XTranslate .PedFilialEmbarque => 2
#XTranslate .PedPedido         => 3
#XTranslate .PedCliente        => 4
#XTranslate .PedNomeCli        => 5
#XTranslate .PedErros          => 6
#XTranslate .PedAviso          => 7
#XTranslate .PedUsuario        => 8
#XTranslate .PedVolumes        => 9
#XTranslate .PedPrioridade     => 10
#XTranslate .PedTransp         => 11

user function _Mata460 ()
	local _sParam     := "VA_USRENF"
	local _sUserLib   := alltrim (upper (GetMV (_sParam, .F., "")))
	local _sMsg       := ""
	local _aLiber     := {.F.,,}
	local _lContinua  := .T.
	local _nLock      := 0
	local _sNFIni     := ""
	local _sNFFim     := ""
	local _sSerie     := "10 "
	local _oSQL       := NIL
	local _sPerg      := "MT461A"
	local _aBkpSX1    := {}
	local _nNComSono  := 0
	private _aNComSono := {}  // Deixar como private para ser vista por outros P.E. (lista de notas a ser transmitida para a SEFAZ)

	u_log2 ('info', 'Iniciando processamento')

	// Verifica geracao de nota com data muito antiga.
	if _lContinua .and. (dDataBase + 59) < date ()
		_sMsg = "Cfe.layout XML da SEFAZ, o prazo maximo eh 60 dias retroativos p/ emissao de NF normais."
		if alltrim (upper (cUserName)) $ _sUserLib
			_lContinua =  U_msgnoyes (_sMsg + " Continua assim mesmo?")
		else
			_aLiber := U_ML_Senha ("Autorizacao exigida", _sMsg + " Liberacao conforme parametro '" + _sParam + "'", _sUserLib, .F.)
			_lContinua = _aLiber [1]
		endif
	endif

	// Controle de semaforo.
	if _lContinua
		_nLock := U_Semaforo ('faturamento' + cEmpAnt + xfilial ("SC9"))
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.",, .t.)
			_lContinua = .F.
			
			// Para os tristes e vergonhosos casos de travamento de servico...
			if alltrim (upper (cUserName)) == "ROBERT.KOCH" .and. u_msgnoyes ("Devo ignorar o semaforo?")
				_lContinua = .T.
			endif
		endif
	endif

	if _lContinua
		if _Filtra ()
			
			// Armazena primeiro pedido selecionado nos parametros do MATA460
			// para faturar apenas esse pedido e evitar que sejam faturados pedidos a mais
			// quando preciso descompilar esses pontos de entrada (ocorre erro em
			// casos aleatorios).
			if ! ExistBlock ("M460FIL") .or. ! ExistBlock ("M460QRY")
				u_log2 ('aviso', "Pontos de entrada de filtragem M460FIL e M460QRY nao estao compilados. Vou filtrar por numero de pedido.")
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT MIN (C9_PEDIDO)"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC9") + " SC9 "
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery +=    " AND C9_NFISCAL = ''"
				_oSQL:_sQuery +=    " AND C9_VABLOQ  = 'N'"
				_oSQL:Log ()
				_aBkpSX1 = U_SalvaSX1 (_sPerg)  // Salva parametros da rotina.
				U_GravaSX1 (_sPerg, "05", _oSQL:RetQry ())
				U_GravaSX1 (_sPerg, "06", _oSQL:RetQry ())
			endif
			
			// Tela padrao de preparacao de doctos.
			u_log2 ('info', 'Chamando MATA460A')

			MATA460A ()
			u_log2 ('info', 'Retornou do MATA460A')

			// Restaura parametros da rotina, caso os tenha alterado.
			if len (_aBkpSX1) > 0
				U_SalvaSX1 (_sPerg, _aBkpSX1)
			endif

			/*
			// Guarda numero da ultima NF gerada, para posterior envio das NF-e para o SPED.
			_sQuery := ""
			_sQuery += " SELECT MAX (F2_DOC)"
			_sQuery +=   " FROM " + RETSQLName ("SF2") + " SF2 "
			_sQuery +=  " WHERE F2_FILIAL   = '" + xFilial ("SF2") + "'"
			_sQuery +=    " AND D_E_L_E_T_  = ' '"
			_sQuery +=    " AND F2_SERIE    = '" + _sSerie + "'"
			_sQuery +=    " AND F2_EMISSAO  = '" + dtos (dDataBase) + "'"
			_sNFFim = U_RetSQL (_sQuery)
			*/

			// Libera semaforo
			U_Semaforo (_nLock)

			// Se foram geradas notas, chama rotina de transmissao para o SEFAZ.
			u_log2 ('info', 'notas geradas:')
			u_log2 ('info', _aNComSono)
			if len (_aNComSono) > 0 .and. U_MsgYesNo ("Voce gerou " + cvaltochar (len (_aNComSono)) + ' notas. Deseja transmiti-las para a SEFAZ agora?')

				// Antes de enviar uma faixa para a SEFAZ, verifica se teve lacuna na numeracao.
				// Reordena para ter certeza
				_aNComSono = asort (_aNComSono,,, {|_x, _y| _x [1] < _y [1]})

				// Varre a lista de notas e marca a posicao 2 com .T. naquelas cuja proxima nota nao for sequencia.
				for _nNComSono = 1 to len (_aNComSono)
					if _nNComSono < len (_aNComSono)
						if val (_aNComSono [_nNComSono + 1, 1]) > val (_aNComSono [_nNComSono, 1]) + 1
							_aNComSono [_nNComSono, 2] = .t.
						endif
					endif
				next

				// Chama telas de transmissao e de impressao de boletos a cada quebra de sequencia.
				if ascan (_aNComSono, {|_aVal| _aVal [2] == .T.}) > 0
					u_help ("Foram geradas notas com quebra de sequencia. Por esse motivo, vai ser feita mais de uma transmissao para a SEFAZ.")
				endif
				_nNComSono = 1
				do while .t.  //_nNComSono <= len (_aNComSono)
					_sNFIni = _aNComSono [_nNComSono, 1]
					_sNFFim = _aNComSono [_nNComSono, 1]
					do while .t. //_nNComSono <= len (_aNComSono)
						_sNFFim = _aNComSono [_nNComSono, 1]
						if _aNComSono [_nNComSono, 2] == .T.  // A proxima nota vai ter lacuna na numeracao.
							U_SPEDAut ('S', _sSerie, _sNFIni, _sNFFim)
							U_BolAuto (_sSerie, _sNFIni, _sNFFim)
							_sNFIni = _aNComSono [_nNComSono + 1, 1]
						endif
						_nNComSono ++
						if _nNComSono > len (_aNComSono)
							exit
						endif
					enddo
					if _nNComSono > len (_aNComSono)
						exit
					endif
				enddo
				U_SPEDAut ('S', _sSerie, _sNFIni, _sNFFim)
				U_BolAuto (_sSerie, _sNFIni, _sNFFim)
			endif
		endif
	endif
	u_log2 ('info', 'Finalizando execucao')
return
//
// --------------------------------------------------------------------------
// Grava campo customizado a ser usado posteriormente pelo P.E. M460Fil.
static function _Filtra ()
	local _sSQL      := ""
	local _aPed      := {}
	local _aPedAux   := {}
	local _nPed      := {}
	local _aSC5      := {}
	local _lContinua := .T.
	local _oDlgMbA   := NIL
	local _oBmpOK    := LoadBitmap( GetResources(), "LBOK" )
	local _oBmpNo    := LoadBitmap( GetResources(), "LBNO" )
	local _aAreaAnt  := U_ML_SRArea ()
	local _nQuaisPed := 0
	private _lBotaoOk := .F.

	procregua (10)
	incproc ("Verificando pedidos a faturar...")

	// Como tenho acesso exclusivo `a rotina (em cada filial), posso alterar todos os registros.
	if _lContinua
		_sSQL := " UPDATE " + RetSQLName ("SC9")
		_sSQL +=    " SET C9_VABLOQ  = 'S'"
		_sSQL +=  " WHERE D_E_L_E_T_ = ''"
		_sSQL +=    " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
		_sSQL +=    " AND C9_NFISCAL = ''"
		_sSQL +=    " AND C9_CARGA   = ''"
		// u_log (_sSQL)
		if TCSQLExec (_sSQL) < 0
			U_help ("Erro na atualizacao do bloqueio do SC9 - rotina " + procname () + " => " + procname (1) + " - comando: " + _sSQL,, .t.)
			U_AvisaTI ("Erro na atualizacao do bloqueio do SC9 - rotina " + procname () + " => " + procname (1) + " - comando: " + _sSQL)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_nQuaisPed = aviso ("Pedidos a verificar", "Selecione quais pedidos deseja verificar", {"Sem carga", "Utiliza carga", "Todos"}, 3)
	endif

	// Monta uma lista dos pedidos em aberto.
	if _lContinua
		_sQuery := ""
		_sQuery += " SELECT DISTINCT ' ', "
		_sQuery +=                  " C5_VAFEMB, "
		_sQuery +=                  " C9_PEDIDO, "
		_sQuery +=                  " C9_CLIENTE, "
		_sQuery +=                  " C9_NREDUZ, "
		_sQuery +=                  " 'Nao verificado', "
		_sQuery +=                  " 'Nao verificado', "
		_sQuery +=                  " C5_VAUSER, "
		_sQuery +=                  " C5_VOLUME1 + C5_VOLUME2, "
		_sQuery +=                  " C5_VAPRIOR, "
		_sQuery +=                  " RTRIM (A4_NOME) AS NOMETRAN "
		_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9, "
		_sQuery +=              RETSQLName ("SC5") + " SC5 "
		_sQuery +=  " LEFT JOIN " + RETSQLName ("SA4") + " SA4 "
		_sQuery +=         " ON (SA4.A4_FILIAL  = '" + xFilial ("SA4") + "'"
		_sQuery +=         " AND SA4.D_E_L_E_T_ = ' '"
		_sQuery +=         " AND SA4.A4_COD     = SC5.C5_TRANSP)"
		_sQuery +=  " WHERE SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
		_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
		_sQuery +=    " AND SC9.C9_NFISCAL = ''"
		_sQuery +=    " AND SC5.C5_FILIAL  = SC9.C9_FILIAL"
		_sQuery +=    " AND SC5.D_E_L_E_T_ = ' '"
		_sQuery +=    " AND SC5.C5_NUM     = SC9.C9_PEDIDO"
		if _nQuaisPed == 1
			_sQuery += " AND SC5.C5_TPCARGA = '2'"  // Nao utiliza
		elseif _nQuaisPed == 2
			_sQuery += " AND SC5.C5_TPCARGA = '1'"  // Utiliza
		endif
		_sQuery += " ORDER BY C5_VAFEMB, C5_VAPRIOR, C9_PEDIDO"
		//u_log (_sQuery)
		_aPedAux = aclone (U_Qry2Array (_sQuery))
		if len (_aPedAux) == 0
			u_help ("Nao foram encontrados pedidos em aberto.",, .t.)
			_lContinua = .F.
		endif
	endif

	// Faz uma verificacao inicial dos pedidos e filtra conforme selecao do usuario.
	if _lContinua

		// Marca pedidos para que sejam considerados na rotina de verificacao.
		for _nPed = 1 to len (_aPedAux)
			_aPedAux [_nPed, .PedOk] = .T.
		next

		processa ({|| _VerifPed (@_aPedAux)})

		// Desmarca os pedidos apos a verificacao.
		for _nPed = 1 to len (_aPedAux)
			_aPedAux [_nPed, .PedOk] = .F.
		next

		// Passa pedidos para a lista definitiva.
		_aPed = {}
		for _nPed = 1 to len (_aPedAux)
			aadd (_aPed, aclone (_aPedAux [_nPed]))
		next

		if len (_aPed) == 0
			u_help ("Nao foram encontrados pedidos em aberto que atendam o filtro informado.",, .t.)
			_lContinua = .F.
		endif
	endif

	// Abre tela para o usuario marcar quais pedidos deseja faturar.
	if _lContinua
		// u_log ("_aPed antes do mbrowse:", _aPed)
		define msdialog _oDlgMbA title "Selecione os pedidos para gerar nota" from 0, 0 to oMainWnd:nClientHeight - 150, oMainWnd:nClientWidth - 50 of oMainWnd pixel
			_oLbx := TWBrowse ():New (15, ;  // Linha
			10, ;  // Coluna
			_oDlgMbA:nClientWidth / 2 - 20, ;   // Largura
			_oDlgMbA:nClientHeight / 2 - 60, ;  // Altura
			NIL, ;                              // Campos
			{"Ok", "Fil.embarque", "Usuario", "Pedido", "Cliente", "Nome cliente", "Volumes", "Transportadora", "Avisos", "Erros", "Prioridade"}, ;  // Cabecalhos colunas
			{25,   35,             30,        30,       30,        100,            30,        50,               60,       500,       30}, ;          // Larguras colunas
			_oDlgMbA,,,,,,,,,,,,.F.,,.T.,,.F.,,,)             // Etc. Veja pasta IXBPAD
			_oLbx:SetArray (_aPed)
			_oLbx:bLine := {|| {iif (_aPed [_oLbx:nAt, .PedOk], _oBmpOk, _oBmpNo), ;
			                   _aPed [_oLbx:nAt, .PedFilialEmbarque], ;
			                   _aPed [_oLbx:nAt, .PedUsuario], ;
			                   _aPed [_oLbx:nAt, .PedPedido], ;
			                   _aPed [_oLbx:nAt, .PedCliente], ;
			                   _aPed [_oLbx:nAt, .PedNomeCli], ;
			                   _aPed [_oLbx:nAt, .PedVolumes], ;
			                   _aPed [_oLbx:nAt, .PedTransp], ;
			                   iif (empty (_aPed [_oLbx:nAt, .PedAviso]), "Ok", _aPed [_oLbx:nAt, .PedAviso]), ;
			                   iif (empty (_aPed [_oLbx:nAt, .PedErros]), "Ok", _aPed [_oLbx:nAt, .PedErros]), ;
			                   _aPed [_oLbx:nAt, .PedPrioridade]}}
			_oLbx:bLDblClick := {|| (_aPed [_oLbx:nAt, .PedOk] := ! _aPed [_oLbx:nAt, .PedOk], _oLbx:Refresh())}
			@ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 90 bmpbutton type 1 action (iif (_TudoOK (_aPed), (_lBotaoOK  := .T., _oDlgMbA:End ()), NIL))
			@ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 40 bmpbutton type 2 action (_lBotaoOK  := .F., _oDlgMbA:End ())
			@ _oDlgMbA:nClientHeight / 2 - 40, 10  button "Inverte selecao"   size 60, 14 action (_Inverte (@_aPed, _oBmpOk, _oBmpNo), _oLbx:Refresh())
			@ _oDlgMbA:nClientHeight / 2 - 40, 150 button "Visualizar pedido" size 60, 14 action (_VisualPed (_aPed [_oLbx:nAt, .PedPedido]))
		activate dialog _oDlgMbA centered

		// Se nao ha pedidos selecionados, simula botao de cancelamento.
		if ascan (_aPed, {|_aVal| _aVal [.PedOk]}) == 0
			_lBotaoOk = .F.
		endif

		_lContinua = _lBotaoOK
	endif

	// Grava campo usado para filtragem no M460Fil.
	if _lContinua
		for _nPed = 1 to len (_aPed)
			if _aPed [_nPed, .PedOk]  // Usuario selecionou este pedido para faturar
				_sSQL := " UPDATE " + RetSQLName ("SC9")
				_sSQL +=    " SET C9_VABLOQ  = 'N'"
				_sSQL +=  " WHERE D_E_L_E_T_ = ''"
				_sSQL +=    " AND C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_sSQL +=    " AND C9_NFISCAL = ''"
				_sSQL +=    " AND C9_PEDIDO  = '" + _aPed [_nPed, .PedPedido] + "'"
				// u_log (_sSQL)
				if TCSQLExec (_sSQL) < 0
					U_help ("Erro na atualizacao do bloqueio do SC9 - rotina " + procname () + " => " + procname (1) + " - comando: " + _sSQL,, .t.)
					U_AvisaTI ("Erro na atualizacao do bloqueio do SC9 - rotina " + procname () + " => " + procname (1) + " - comando: " + _sSQL)
					_lContinua = .F.
					exit
				endif
			endif
		next
	endif

	if _lContinua
		for _nPed = 1 to len (_aPed)
			if _aPed [_nPed, .PedOk]  // Usuario selecionou este pedido para faturar

				_sSQL := " SELECT"
				_sSQL += " 		 SC5.C5_NUM"
				_sSQL += " 		,SC5.C5_CLIENTE"
				_sSQL += " 		,SC5.C5_LOJACLI"
				_sSQL += " 		,SC5.C5_TIPO"
				_sSQL += " FROM " + RETSQLName ("SC5") + " SC5 "
				_sSQL += " WHERE SC5.D_E_L_E_T_ = ''"
				_sSQL += " AND SC5.C5_FILIAL = '" + xfilial ("SC5") + "'"
				_sSQL += " AND SC5.C5_NUM    = '" + _aPed [_nPed, .PedPedido] + "'"
				_aSC5 := U_Qry2Array(_sSQL)

				If Len(_aSC5) > 0
					_sPedido  := alltrim(_aSC5[1,1])
					_sCliente := alltrim(_aSC5[1,2])
					_sLoja    := alltrim(_aSC5[1,3])
					_sTipo    := alltrim(_aSC5[1,4])

					If _sTipo == 'D' .or. _sTipo == 'B' // é fornecedor
						_sQuery := " SELECT"
						_sQuery += "  	A2_MSBLQL "
						_sQuery += " FROM " + RETSQLName ("SA2")
						_sQuery += " WHERE D_E_L_E_T_ = '' "
						_sQuery += " AND A2_COD  = '" + _sCliente + "'"
						_sQuery += " AND A2_LOJA = '" + _sLoja    + "'"
						_aDados:= U_Qry2Array(_sQuery)	
					
					Else // é cliente

						_sQuery := " SELECT"
						_sQuery += "  	A1_MSBLQL "
						_sQuery += " FROM " + RETSQLName ("SA1")
						_sQuery += " WHERE D_E_L_E_T_ = '' "
						_sQuery += " AND A1_COD  = '" + _sCliente + "'"
						_sQuery += " AND A1_LOJA = '" + _sLoja    + "'"
						_aDados:= U_Qry2Array(_sQuery)	
					EndIf
	
					If Len(_aDados) > 0
						If alltrim(_aDados[1,1]) == '1'
							u_help(" O pedido " + alltrim(_sPedido) + " está com o cliente " + alltrim(_sCliente) + " bloqueado!")
							_lRet := .F.
						EndIf
					EndIf

				EndIf
			endif
		next
	endif
	U_ML_SRArea (_aAreaAnt)
return _lBotaoOK .and. _lContinua
//
// --------------------------------------------------------------------------
// Verifica se estah tudo OK com a marcacao do usuario.
static function _TudoOK (_aPed)
	local _lRet := .T.
	local _nPed := 0

	CursorWait ()
	if _lRet
		for _nPed = 1 to len (_aPed)
			if _aPed [_nPed, .PedOk] .and. ! empty (_aPed [_nPed, .PedAviso])
				_lRet = u_msgnoyes ("Foram selecionados pedidos com avisos ou nao verificados. Confirma assim mesmo?")
				exit
			endif
		next
	endif
	if _lRet
		for _nPed = 1 to len (_aPed)
			if _aPed [_nPed, .PedOk] .and. ! empty (_aPed [_nPed, .PedErros])
				u_help ("Foram selecionados pedidos com erros que impedem a geracao de notas. Revise marcacao. " + alltrim (_aPed [_nPed, .PedErros]),, .T.)
				_lRet = .F.
				exit
			endif
		next
	endif
	CursorArrow ()
return _lRet
//
// --------------------------------------------------------------------------
// Visualiza pedido.
static function _VisualPed (_sPedido)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	private aRotina    := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	                       {"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido para visualizar o pedido.
	CursorWait ()
	dbSelectArea("SC5")
	dbSetOrder(1)
	if dbseek (xfilial ("SC5") + _sPedido, .F.)
		A410Visual("SC5",sc5 -> (recno ()),2)
	endif
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	CursorArrow ()
return
//
// --------------------------------------------------------------------------
// Inverte a mancacao no browse.
static function _Inverte (_aOpcoes)
	local _nPed := 0
	CursorWait ()
	for _nPed = 1 to len (_aOpcoes)
		_aOpcoes [_nPed, .PedOk] = ! _aOpcoes [_nPed, .PedOk]
	next
	CursorArrow ()
return
//
// --------------------------------------------------------------------------
// Verifica situacao dos pedidos selecionados.
static function _VerifPed (_aPed)
	local _aUsados  := {}
	local _nUsado   := 0
	local _nPed     := 0
	local _sQuery   := ""
	local _sRetEstq := ""
	local _aSC9     := {}
	local _nSC9     := 0
	local _nQtSolic := 0
	local _aRetSQL  := {}
	local _oSQL     := NIL

	//u_logIni ()
	CursorWait ()
	procregua (len (_aPed))

	// Verifica estoque de pedido por pedido. A cada pedido com estoque suficiente,
	// acrescenta suas quantidades a uma array representando as quantidades acumuladas
	// consumidas pelos pedidos. Assim, se mais de um pedido usar o mesmo produto,
	// a validacao de estoque do segundo pedido jah vai considerar a baixa feita
	// pelo primeiro pedido.
	_aUsados = {}
	for _nPed = 1 to len (_aPed)
		_aPed [_nPed, .PedAviso] = ""
		_aPed [_nPed, .PedErros] = ""
		if _aPed [_nPed, .PedOk]
			// u_logIni (_aPed [_nPed, .PedPedido])
			incproc ("Verificando pedido " + _aPed [_nPed, .PedPedido])

			// Verifica SC9 e outras pendencias.
			_sQuery := ""
			_sQuery += " SELECT CASE WHEN SUM (CASE C5_VABLOQ  WHEN ''   THEN 0 ELSE 1 END) = 0 "
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'BLQ.GERENCIAL;'"
			_sQuery +=             " END + "
			_sQuery +=        " CASE WHEN SUM (CASE C9_BLEST   WHEN ''   THEN 0 ELSE 1 END) = 0 "
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'BLQ.ESTQ.;'"
			_sQuery +=             " END + "
			_sQuery +=        " CASE WHEN SUM (CASE C9_BLCRED  WHEN ''   THEN 0 ELSE 1 END) = 0 "
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'BLQ.CREDITO;'"
			_sQuery +=             " END + "
			_sQuery +=        " CASE WHEN SUM (CASE C9_BLVEND  WHEN ''   THEN 0 ELSE 1 END) = 0 "
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'BLQ.VENDAS;'"
			_sQuery +=             " END + "
			_sQuery +=        " CASE WHEN SUM (CASE C9_BLOQUEI WHEN ''   THEN 0 ELSE 1 END) = 0 ""
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'OUTROS BLOQ.;'"
			_sQuery +=             " END + "
			_sQuery +=        " CASE WHEN (SELECT COUNT (*)"
			_sQuery +=                     " FROM " + RetSQLName ("SC6") + " SC6_2"
			_sQuery +=                    " WHERE SC6_2.C6_FILIAL   = '" + xfilial ("SC6") + "'"
			_sQuery +=                      " AND SC6_2.C6_NUM      = '" + _aPed [_nPed, .PedPedido] + "'"
			_sQuery +=                      " AND SC6_2.D_E_L_E_T_  = ''"
			_sQuery +=                      " AND SC6_2.C6_BLQ NOT IN ('R', 'S')"  // Eliminado residuo / bloqueio manual
			_sQuery +=                      " AND SC6_2.C6_QTDVEN   > SC6_2.C6_QTDENT"
			_sQuery +=                      " AND NOT EXISTS (SELECT C9_FILIAL
			_sQuery +=                                        " FROM " + RetSQLName ("SC9") + " SC9_2"
			_sQuery +=                                       " WHERE SC9_2.C9_PEDIDO  = SC6_2.C6_NUM"
			_sQuery +=                                         " AND SC9_2.D_E_L_E_T_ = ''"
			_sQuery +=                                         " AND SC9_2.C9_FILIAL  = SC6_2.C6_FILIAL"
			_sQuery +=                                         " AND SC9_2.C9_ITEM    = SC6_2.C6_ITEM)) = 0"
			_sQuery +=             " THEN ''"
			_sQuery +=             " ELSE 'LIBER.PARCIAL; '"
			_sQuery +=             " END AS OBS, "

			_sQuery +=        " CASE WHEN SC5.C5_TRANSP = '' AND SC5.C5_TPFRETE IN ('C','F') ""
			_sQuery +=             " THEN 'FALTA TRANSP; '"
			_sQuery +=             " ELSE ''"
			_sQuery +=             " END + "

			_sQuery +=        " CASE WHEN SC5.C5_TPCARGA = '1' ""
			_sQuery +=             " THEN 'Utiliza carga; '"
			_sQuery +=             " ELSE ''"
			_sQuery +=             " END + "

			_sQuery +=        " CASE WHEN (SC5.C5_VAFEMB != SC5.C5_FILIAL OR SC5.C5_FILIAL IN ('04', '14'))"
			_sQuery +=              " AND (SELECT COUNT (*)"
			_sQuery +=                     " FROM " + RetSQLName ("ZZ6") + " ZZ6"
			_sQuery +=                    " WHERE ZZ6.ZZ6_FILIAL    = '" + xfilial ("ZZ6") + "'"
			_sQuery +=                      " AND ZZ6.ZZ6_CODPRO    = '04'"
			_sQuery +=                      " AND ZZ6.D_E_L_E_T_  = ''"
			_sQuery +=                      " AND ZZ6.ZZ6_EMPDES  = '01'"
			_sQuery +=                      " AND ((SC5.C5_VAFEMB != SC5.C5_FILIAL AND ZZ6.ZZ6_FILDES  = SC5.C5_VAFEMB)"
			_sQuery +=                       " OR  (SC5.C5_FILIAL IN ('04', '14') AND ZZ6.ZZ6_FILDES  = SC5.C5_FILIAL))"
			_sQuery +=                      " AND ZZ6.ZZ6_ATIVO   = 'S'"
			_sQuery +=                      " AND ZZ6.ZZ6_RODADO NOT IN ('S', 'C')) > 0"
			_sQuery +=             " THEN 'FALTA TR.ALM.RET;'"
			_sQuery +=             " ELSE ''"
			_sQuery +=             " END + "
			
			_sQuery +=        " CASE WHEN EXISTS (SELECT *"
			_sQuery +=                            " FROM " + RetSQLName ("DAI") + " DAI "
			_sQuery +=                           " WHERE DAI.D_E_L_E_T_ = ''"
			_sQuery +=                             " AND DAI.DAI_FILIAL = SC5.C5_FILIAL"
			_sQuery +=                             " AND DAI.DAI_PEDIDO = SC5.C5_NUM)"
			_sQuery +=             " THEN 'Faturar via OMS;'"
			_sQuery +=             " ELSE ''"
			_sQuery +=             " END "

			_sQuery +=             " AS ERROS"
			_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9, "
			_sQuery +=              RETSQLName ("SC5") + " SC5 "
			_sQuery +=  " WHERE SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
			_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC9.C9_PEDIDO  = '" + _aPed [_nPed, .PedPedido] + "'"
			_sQuery +=    " AND SC9.C9_NFISCAL = ''"
			_sQuery +=    " AND SC5.C5_FILIAL  = SC9.C9_FILIAL"
			_sQuery +=    " AND SC5.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC5.C5_NUM     = SC9.C9_PEDIDO"
			_sQuery +=  " GROUP BY SC5.C5_TRANSP, SC5.C5_FILIAL, SC5.C5_VAFEMB, SC5.C5_VAPEMB, SC5.C5_NUM, SC5.C5_TPCARGA, SC5.C5_TPFRETE"
			// u_log (_sQuery)
			//_aPed [_nPed, .PedAviso] = alltrim (U_RetSQL (_sQuery))
			_aRetSQL := aclone (U_Qry2Array (_sQuery, .F., .F.))
			_aPed [_nPed, .PedAviso] = alltrim (_aRetSQL [1, 1])
			_aPed [_nPed, .PedErros] = alltrim (_aRetSQL [1, 2])

			// Verifica se tem produtos armazenados pelo Fullsoft e se foi feita separacao.
			if cEmpAnt + cFilAnt == '0101'
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " WITH C AS ("
				_oSQL:_sQuery += " SELECT C9_PRODUTO, SUM (C9_QTDLIB) AS QT_CARGA,"
				_oSQL:_sQuery +=        " isnull("
				_oSQL:_sQuery +=               " (select qtde_exec"
				_oSQL:_sQuery +=                  " from tb_wms_pedidos"
				_oSQL:_sQuery +=                 " where nrodoc   = '10' + C9_FILIAL + C9_PEDIDO"
				_oSQL:_sQuery +=                   " and status   = '6'"
				_oSQL:_sQuery +=                   " and coditem  = RTRIM (SC9.C9_PRODUTO))"
				_oSQL:_sQuery +=        ", 0) AS QT_SEPARADA"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC9") + " SC9, "
				_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1 "
				_oSQL:_sQuery += " WHERE SC9.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
				_oSQL:_sQuery +=   " AND SC9.C9_PEDIDO  = '" + _aPed [_nPed, .PedPedido] + "'"
				_oSQL:_sQuery +=   " AND SC9.C9_CARGA  != ''"  // Somente pedidos com carga vao para Fullsoft.
				_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
				_oSQL:_sQuery +=   " AND SB1.B1_COD     = SC9.C9_PRODUTO"
				_oSQL:_sQuery +=   " AND B1_VAFULLW     = 'S'"
				_oSQL:_sQuery += " GROUP BY C9_FILIAL, C9_PEDIDO, C9_PRODUTO"
				_oSQL:_sQuery += " )"
				_oSQL:_sQuery += " SELECT COUNT (*)"
				_oSQL:_sQuery +=   " FROM C"
				_oSQL:_sQuery +=  " WHERE QT_CARGA != QT_SEPARADA"
				// u_log (_oSQL:_sQuery)
				if _oSQL:RetQry () > 0
					_aPed [_nPed, .PedErros] += "Falta separar Fullsoft; "
				endif
			endif

			// Ocorrem casos de 'quebra' do SC9 geralmente quando falta estoque de algum produto.
			_sQuery := ""
			_sQuery += " SELECT COUNT (*)"
			_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9 "
			_sQuery +=  " WHERE SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
			_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC9.C9_PEDIDO  = '" + _aPed [_nPed, .PedPedido] + "'"
			_sQuery +=    " AND SC9.C9_NFISCAL = ''"
			_sQuery +=  " GROUP BY C9_PEDIDO, C9_ITEM "
			//_sQuery +=  " GROUP BY C9_PEDIDO, C9_ITEM, C9_LOTECTL"
			_sQuery +=  " HAVING COUNT (*) > 1"
			//u_log (_sQuery)
			if U_RetSQL (_sQuery) > 1
				_aPed [_nPed, .PedAviso] += "DUPLICIDADE; "
			endif
			
			// Verifica estoques
			_sQuery := ""
			_sQuery += " SELECT C9_PRODUTO, C5_VAFEMB, C9_LOCAL, SUM (C9_QTDLIB), C6_TES, C6_LOCALIZ, C9_LOTECTL"
			_sQuery +=   " FROM " + RETSQLName ("SC9") + " SC9, "
			_sQuery +=              RETSQLName ("SC5") + " SC5, "
			_sQuery +=              RETSQLName ("SC6") + " SC6 "
			_sQuery +=  " WHERE SC9.C9_PEDIDO  = '" + _aPed [_nPed, .PedPedido] + "'"
			_sQuery +=    " AND SC9.C9_FILIAL  = '" + xFilial ("SC9") + "'"
			_sQuery +=    " AND SC9.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC5.C5_FILIAL  = SC9.C9_FILIAL"
			_sQuery +=    " AND SC5.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC5.C5_NUM     = SC9.C9_PEDIDO"
			_sQuery +=    " AND SC6.D_E_L_E_T_ = ' '"
			_sQuery +=    " AND SC6.C6_FILIAL  = SC5.C5_FILIAL"
			_sQuery +=    " AND SC6.C6_NUM     = SC9.C9_PEDIDO"
			_sQuery +=    " AND SC6.C6_ITEM    = SC9.C9_ITEM"
			_sQuery +=  " GROUP BY C9_PRODUTO, C5_VAFEMB, C9_LOCAL, C6_TES, C6_LOCALIZ, C9_LOTECTL"
			//u_log (_sQuery)
			_aSC9 := aclone (U_Qry2Array (_sQuery))
			// u_log ("Quantidades solicitadas pelo pedido "+ _aPed [_nPed, .PedPedido] + ":", _aSC9)
			_sRetEstq = ""
			for _nSC9 = 1 to len (_aSC9)

				_nQtSolic = _aSC9 [_nSC9, 4]
			
				// Verifica se este produto jah foi reservado por algum pedido anterior.
				_nUsado = ascan (_aUsados, {|_aVal| _aVal [1] == _aSC9 [_nSC9, 1] .and. _aVal [2] == _aSC9 [_nSC9, 2] .and. _aVal [3] == _aSC9 [_nSC9, 3] .and. _aVal [5] == _aSC9 [_nSC9, 6]})
				if _nUsado > 0
					_nQtSolic += _aUsados [_nUsado, 4]
				endif

				if ! (_aSC9 [_nSC9, 2] == '13' .and. _aSC9 [_nSC9, 3] == '13')
					_sRetEstq = U_VerEstq ("3", _aSC9 [_nSC9, 1], _aSC9 [_nSC9, 2], _aSC9 [_nSC9, 3], _nQtSolic, _aSC9 [_nSC9, 5], _aSC9 [_nSC9, 6], _aSC9 [_nSC9, 7], _aPed [_nPed, .PedPedido])
				endif

				if ! empty (_sRetEstq) .and. at (alltrim (_aSC9 [_nSC9, 1]), _aPed [_nPed, .PedErros]) == 0
					_aPed [_nPed, .PedErros] += alltrim (_aSC9 [_nSC9, 1]) + " insuficiente; "
				else
					// Acrescenta produto/filial de embarque/local `a lista de reservas.
					if _nUsado == 0
						aadd (_aUsados, {_aSC9 [_nSC9, 1], _aSC9 [_nSC9, 2], _aSC9 [_nSC9, 3], _nQtSolic, _aSC9 [_nSC9, 6]})
					else
						_aUsados [_nUsado, 4] = _nQtSolic
					endif
				endif
			next
		endif
	next
	CursorArrow ()
	//u_logFim ()
return
