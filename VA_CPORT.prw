// Programa.:  VA_CPORT
// Autor....:  Leandro - DWT
// Data.....:  11/09/2013
// Descricao:  Controle de portaria, para emitir tickets na entrada e saida de cargas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Rotina de controle de portaria
// #PalavasChave      #controle_de_portaria #pesagem #veiculos #motoristas
// #TabelasPrincipais #ZZT
// #Modulos           #COOP
//
// Historico de alteracoes:
// 28/04/2014 - Marcelo DWT - Grava codigo do ticket na carga selecionada pelo usuario
// 30/04/2014 - Robert  - Gravacao de eventos e conf.embarque migrado para dentro de controle de transacao.
// 19/05/2014 - Marcelo DWT - Exclui o vinculo do ticket com a carga quando o ticket e excluido.
// 18/11/2015 - Robert  - Melhorias e validacoes diversas para entradas para coleta.
//                      - Vincula a carga do OMS na saida e nao mais na entrada.
// 18/01/2016 - Robert  - Melhoria ticket safra - nao conformidades
// 17/02/2016 - Robert  - Removida impressao de 2 cabecalhos no ticket de safra, pois nao era usado.
// 10/05/2016 - Catia   - teste conforme motivo, 3=entrega obriga documento e fornecedor  5= outros obriga obs 
// 19/07/2016 - Robert  - Nova rotina de leitura de peso (U_LeBalan2) adequada para Protheus 12.
// 24/07/2017 - Robert  - Ignora verificacao de CNPJ x chave NF-e para series 
//                        "890#891#892#893#894#895#896#897#898#899"
// 12/01/2018 - Robert  - Avaliacoes passam a ser feitas pelo NaWeb.
//                      - Passa a verificar na view VA_VAGENDA_SAFRA se precisa coletar amostra da uva.
// 18/01/2019 - Robert  - Tickets de safra passam a buscar dados no VA_RUSTK.prw
// 25/01/2018 - Robert  - Abertura de ticket safra (1a.pesagem) chama VA_RUSLI() para validar 
//                        se tudo Ok com inspecoes.
// 06/03/2019 - Robert  - Ajustes cod.barras ticket - novo firmware impressora 
//                      - royalties para Fabiano Fernandes
//                      - Migrada impressao ticket para U_ImpZZT ()
//                      - Eliminados parametros desnecessarios.
// 30/08/2019 - Claudia - Alterado campo peso bruto para b1_pesbru.
// 20/12/2019 - Claudia - Incluida na menu a rotina ZZX 
// 01/02/2020 - Robert  - Removido controle de transacao na inclusao por que impedia atualizacao 
//                        externa (NaWeb).
// 03/02/2020 - Robert  - Funcao de leitura de peso passada de U_LeBalan2 para U_LeBalan3 (via SQL).
// 21/02/2020 - Robert  - Alteracoes na tabela ZZA passam a ser feitas em rotina externa (U_AtuZZA).
// 07/08/2020 - Robert  - Incluidas tags para catalogacao de fontes
//                      - Melhorados logs e mensagens de erro; ajuste paravras acentuadas e 
//                         caracteres com erro de conversao para UTF8
//                      - Liberado uso em todas as filiais (antes era restito para a matriz)
// 03/02/2021 - Robert  - Chamada do fechamento de safra apos fechar entrada de portaria (GLPI 9319)
// 08/02/2021 - Robert  - Nao alimentava as variaveis _zx509fina e _zx509orga na chamada da tela de 
//                        fechamento de safra (GLPI 9319)
// 25/01/2022 - Claudia - Incluida rotina para exportar dados em planilha. GLPI: 10771.
// 11/03/2022 - Robert  - Novos parametros funcao U_VA_RusLI() - GLPI 11745.
// 14/06/2022 - sandra  - Incluso campo ZZT_OBS - GLPI 12209.
// 28/10/2022 - Robert  - Removidos alguns parametros em desuso (da rotina de recebimento safra).
// 12/01/2023 - Robert  - Instancia object ClsCarSaf antes de chamar tela de fechamento de safra.
// 25/01/2023 - Robert  - Passa a usar classe ClsCarSaf para atualizar tabela ZZA.
// 24/01/2024 - Robert  - Criada opcao de exportar historico de pesos lidos da balanca.
// 10/02/2024 - Robert  - Varieval _lLeBrix desabilitada (assume default .T.)
// 12/04/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// ----------------------------------------------------------------------------------------------------------------
#Include "PROTHEUS.CH"

#XTranslate .CargasOK         => 1
#XTranslate .CargasCodigo     => 2
#XTranslate .CargasTransp     => 3
#XTranslate .CargasNomeTransp => 4
#XTranslate .CargasPeso       => 5
#XTranslate .CargasDescri     => 6
#XTranslate .CargasOrigem     => 7
#XTranslate .CargasEmissao    => 8
#XTranslate .CargasUsuario    => 9
#XTranslate .CargasQtColunas  => 9

User Function VA_CPORT ()
	local _aCores       := U_ZZTLG (.T.)
	local _nPCham       := 0
	Private aRotina     := {}
	Private _aCargas    := {}
	Private cCadastro   := "Controle de Entradas e Saídas da Portaria"
	Private cDelFunc    := ".T."
	Private cString     := "ZZT"
	Private cExprFilTop := ""
	private _aRotAdic   := {}
	private _aRusInsp   := {}  // Deixar private para ser vista e alimentada por outras rotinas.

	// Verifica se estah sendo feita chamada resursiva (Na tela de safra tem atalho para esta e vice-versa)
	// Devido as diversas chamadas de menus, etc. feitas pelo Protheus, se esta tela jah estiver na pilha, vai ser em um numero bem alto
	_nPCham = 8
	do while procname (_nPCham) != ""
		if procname () $ procname (_nPCham)
			u_help ("Esta tela ja encontra-se aberta. Verifique se foi chamada de dentro da tela de recebimento de safra (ou vice-versa).",, .t.)
			return
		endif
		_nPCham++
	enddo

	// Submenu de rotinas adicionais
	aadd (_aRotAdic, {"Pedidos de venda"       , "U__MATA410 ()" 	, 0, 4})
	aadd (_aRotAdic, {"SPED NFe"               , "SPEDNFE ()"	  	, 0, 4})
	aadd (_aRotAdic, {"Guias transito"         , "U_VA_SZQ ()"   	, 0, 4})
	aadd (_aRotAdic, {"Cons.genericas"         , "EDAPP ()"	  	, 0, 4})
	aadd (_aRotAdic, {"Cons.NF saida"          , "MATC090 ()"		, 0, 4})
	aadd (_aRotAdic, {"Pre-nota"               , "MATA140 ()"		, 0, 4})
	aadd (_aRotAdic, {"Cargas OMS"             , "U_ZT_COMS()"		, 0, 1})
	aadd (_aRotAdic, {"Receb.uva safra"        , "U_VA_RUS()"		, 0, 4})
	aadd (_aRotAdic, {"Exporta dados portaria" , "U_VA_ZZTCON()"	, 0, 4})
	aadd (_aRotAdic, {"Historico pesos balanca", "U_VA_ZZTHP ()"	, 0, 4})
	_aRotAdic = asort (_aRotAdic,,, {|_x, _y| _x [1] < _y [1]})

	aRotina = {}
	aadd (aRotina, {"Pesquisar"		, "AxPesqui"					,0,1})
	aadd (aRotina, {"Visualizar"	, "AxVisual"					,0,2})
	aadd (aRotina, {"Ticket"		, "U_ZT_Tick()"					,0,3})
	aadd (aRotina, {"Alterar"		, "U_ZT_Tick('6')"				,0,4})
	aadd (aRotina, {"Excluir"		, "U_DelZZT()"					,0,5})
	aadd (aRotina, {"Impressao"		, "U_ImpZZT(ZZT->ZZT_COD,'', 1)",0,1})
	aadd (aRotina, {"Lib.peso saida", "U_ZT_LPS ()"					,0,1})
	aadd (aRotina, {"Manut.XML's"	, "U_ZZX ()"					,0,4})
	aadd (aRotina, {"Legenda"		, "U_ZZTLG (.F.)"				,0,5})
	aadd (aRotina, {"Outros"		, _aRotAdic						,0,4})

	dbSelectArea("ZZT")
	dbSetOrder(1)

	mBrowse(,,,,"ZZT",,,,,,_aCores ,,,,,,,,cExprFilTop)
Return
//
// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZZTLG (_lRetCores)
	local _i       := 0
	local _aCores  := {}
	local _aCores2 := {}

	aadd (_aCores, {"zzt->zzt_blqpes$'NL '.and.!empty(zzt->zzt_dtent).and.!empty(zzt->zzt_dtsai)", 'BR_VERMELHO', 'Finalizado'})
	aadd (_aCores, {"zzt->zzt_blqpes$'NL '.and. empty(zzt->zzt_dtent) .or. empty(zzt->zzt_dtsai)", 'BR_VERDE',    'Pendente'})
	aadd (_aCores, {"zzt->zzt_blqpes=='B'",                                                        'BR_PRETO',    'Bloqueio diferenca peso'})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
//
// --------------------------------------------------------------------------
// Libera saida com diferenca de peso.
user function ZT_LPS ()
	if U_ZZUVL ('054', __cUserId, .T.)//, cEmpAnt, cFilAnt)
		reclock ("ZZT", .F.)
		zzt -> zzt_blqpes = 'L'
		zzt -> zzt_usrldp = cUserName
		msunlock ()
	endif
return
//
// --------------------------------------------------------------------------
// Lista cargas do OMS relacionadas a este ticket
User Function ZT_COMS ()
	local _oSQL := NIL

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT 'Carga logistica' AS ORIGEM, DAK_COD AS CARGA,"
	_oSQL:_sQuery +=        " 0 AS PESO,"  // Ainda nao temos o peso correto no DAK
	_oSQL:_sQuery +=        " dbo.VA_DTOC (DAK_DATA) AS DATA,"
	_oSQL:_sQuery +=        " SA4.A4_NOME AS TRANSP "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("DAK") + " DAK, "
	_oSQL:_sQuery +=              RetSQLName ("SA4") + " SA4 "
	_oSQL:_sQuery +=  " WHERE DAK.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND DAK.DAK_VATKP  = '" + zzt -> zzt_cod + "'"
	_oSQL:_sQuery +=    " AND SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA4.A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_COD     = DAK.DAK_VATRAN"
	_oSQL:_sQuery +=  " UNION ALL"
	_oSQL:_sQuery += " SELECT 'Ordem embarque' AS ORIGEM, ZO_NUMERO AS CARGA, "
	_oSQL:_sQuery +=        " 0 AS PESO,"
	_oSQL:_sQuery +=        " dbo.VA_DTOC (ZO_EMISSAO) AS DATA, "
	_oSQL:_sQuery +=        " SA4.A4_NOME AS TRANSP "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZO") + " SZO, "
	_oSQL:_sQuery +=              RetSQLName ("SA4") + " SA4 "
	_oSQL:_sQuery +=  " WHERE SZO.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SZO.ZO_VATKP   = '" + zzt -> zzt_cod + "'"
	_oSQL:_sQuery +=    " AND SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SZO.ZO_FILIAL  = '" + xfilial ("SZO") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_COD     = SZO.ZO_TRANSP"
	//_oSQL:Log ()
	_oSQL:F3Array ("Cargas OMS relacionadas a este ticket")
return
//
// --------------------------------------------------------------------------
// Função para deletar registro
User Function DelZZT()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _oCarSaf   := NIL

	// Valida carga de safra.
	if ! empty(ZZT->ZZT_CARGA)
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		if sze -> (dbseek (xfilial ("SZE") + zzt -> zzt_safra + zzt -> zzt_carga, .F.))
			if ! empty (sze -> ze_nfger)
				u_help ("Este ticket refere-se `a carga '" + zzt -> zzt_carga + "' da safra '" + zzt -> zzt_safra + "'. Essa carga gerou a contranota '" + sze -> ze_nfger + "'. Para excluir o ticket cancele, antes, a contranota da carga.",, .t.)
				_lContinua = .F.
			endif

			if _lContinua
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery += "SELECT COUNT (*)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZA") + " ZZA "
				_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
				_oSQL:_sQuery +=   " AND ZZA_FILIAL  = '" + xfilial ("ZZA") + "'"
				_oSQL:_sQuery +=   " AND ZZA_SAFRA   = '" + zzt -> zzt_safra + "'"
				_oSQL:_sQuery +=   " AND ZZA_CARGA   = '" + zzt -> zzt_carga + "'"
				_oSQL:_sQuery +=   " AND ZZA_STATUS NOT IN ('0', '1')"
				if _oSQL:RetQry () > 0
					u_help ("A carga de safra amarrada a este ticket ja' esta' sendo (ou ja' foi) usada pelo programa de medicao de grau. Exclusao nao permitida.",, .t.)
					_lContinua = .F.
				endif
			endif
		endif
	endif

	// Valida cargas.
	dak -> (dbsetorder (5))  // DAK_FILIAL+DAK_VATKP
	if dak -> (dbseek (xfilial ("DAK") + zzt -> zzt_cod, .F.))
		u_help ("Ticket vinculado `a carga '" + dak -> dak_cod + "' do setor de logistica. Exclusao nao permitida.",, .t.)
		_lContinua = .F.
	endif
	szo -> (dbsetorder (2))  // ZO_FILIAL+ZO_VATKP
	if szo -> (dbseek (xfilial ("SZO") + zzt -> zzt_cod, .F.))
		u_help ("Ticket vinculado `a ordem de embarque (tabela SZO) numero '" + szo -> zo_numero + "'. Exclusao nao permitida.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		begin transaction
			if AxDeleta ("ZZT", zzt -> (recno ()), 5) == 2

				// Atualiza carga safra.
				if zzt -> zzt_entsai == 'E' .and. zzt -> zzt_pesent > 0 .and. ! empty (zzt -> zzt_safra) .and. ! empty (zzt -> zzt_carga)
					sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
					if sze -> (dbseek (xfilial ("SZE") + zzt -> zzt_safra + zzt -> zzt_carga, .F.))
						reclock ("SZE", .F.)
						sze -> ze_pesobru = 0
						msunlock ()
				
						// Atualiza tabela de comunicacao com leitor de grau.
						_oCarSaf := ClsCarSaf ():New (sze -> (recno ()))
						_oCarSaf:AtuZZA (.F.)
					endif
				endif
			endif
		end transaction
	endif
Return
//
// --------------------------------------------------------------------------
// Função para manutenção dos tickets (entrada ou saida)
User Function ZT_Tick(_sOpcao)
	local _lContinua := .T.
	local _ticket := space(tamsx3 ("ZZT_COD") [1])
	local _aBotAdic := {}
	local oDlg
	local oButton1
	local oGet1
	local oSay1
	local _aOpcoes := {}
	local _aCols   := {}
	private _sOperPort  := ''  // Deixar private para ser vista por inicializadores de campos, getilhos, etc.

	//	set key 119 to U_PesaZZT()  // tecla F8
	SetKey(VK_F8, {|| U_PesaZZT()})
	aadd(_aBotAdic,{"BALANCA",{|| U_PesaZZT()},"Pesagem"})

	_aCargas = {}

	if _sOpcao == NIL
		_aCols = {}
		aadd (_aCols, {1, 'Operacao', 100, ''})
		_aOpcoes = {}
		aadd (_aOpcoes, {"1 - Nova entrada"		})
		aadd (_aOpcoes, {"2 - Nova saida"		})
		aadd (_aOpcoes, {"3 - Fechar entrada"	})
		aadd (_aOpcoes, {"4 - Fechar saida"		})
		aadd (_aOpcoes, {"5 - Cancelar"			})

		_sOperPort = alltrim (str(U_F3Array(_aOpcoes	, ;  // Opcoes
								  "Controle de portaria", ;  // Titulo
												 _aCols	, ;  // Colunas a mostrar
													500	, ;  // Largura
													300 , ;  // Altura
					   'Selecione a operacao a realizar', ;  // Texto acima
		                                              '', ;  // Texto abaixo
		                                             .F., ;  // Mostra botao 'exportar para planilha'
		                                              '')))  // Tipo de pesquisa
	else
		_sOperPort = _sOpcao
	endif
	
	if _lContinua .and. _sOperPort $ '34'
		DEFINE MSDIALOG oDlg TITLE "Numero do Ticket !" FROM 000, 000  TO 150, 350 COLORS 0, 16777215 PIXEL
		@ 007, 012 SAY oSay1 PROMPT "Digite o numero do ticket" SIZE 154, 010 OF oDlg COLORS 0, 16777215 PIXEL
		if _sOperPort == '3'
			@ 049, 018 MSGET oGet1 VAR _ticket SIZE 055, 010 OF oDlg COLORS 0, 16777215 F3 "ZZT_3" PIXEL
		elseif _sOperPort == '4'
			@ 049, 018 MSGET oGet1 VAR _ticket SIZE 055, 010 OF oDlg COLORS 0, 16777215 F3 "ZZT_4" PIXEL
		endif
		@ 046, 106 BUTTON oButton1 PROMPT "Confirma" SIZE 038, 015 OF oDlg ACTION oDlg:End () PIXEL
		ACTIVATE MSDIALOG oDlg
		if _lContinua
			zzt -> (dbsetorder(1))
			if ! zzt -> (dbseek(xFilial("ZZT") + _ticket, .F.))
				u_help ("Ticket nao localizado",, .t.)
				_lContinua = .F.
			endif
		endif
		if _lContinua .and. ! empty (zzt -> zzt_dtent) .and. ! empty (zzt -> zzt_dtsai)
			u_help ("Ticket ja finalizado.",, .t.)
			_lContinua = .F.
		endif
		if _lContinua .and. zzt -> zzt_entsai == 'E' .and. _sOperPort != '3'
			u_help ("Ticket informado eh de entrada. Soh pode ser finalizado com a opcao 3",, .t.)
			_lContinua = .F.
		endif
		if _lContinua .and. zzt -> zzt_entsai == 'S' .and. _sOperPort != '4'
			u_help ("Ticket informado eh de saida. Soh pode ser finalizado com a opcao 4",, .t.)
			_lContinua = .F.
		endif
	
		if _lContinua
			if zzt -> zzt_motivo == '2'
				aadd(_aBotAdic,{"CARGAS",{|| _SelCarg ()},"Sel.cargas logist"})
			endif
			if AxAltera ("ZZT", ZZT -> (Recno ()), 4, NIL, NIL, NIL, NIL, "U_ZZT_TOk ()", NIL, "U_ZZT_AA ()", _aBotAdic) == 1
				if _sOperPort == '3'
					_AtuCargas (_aCargas)

					// Se estiver fechando uma entrada de recebimento de safra, abre a tela de segunda pesagem de uva para finalizar o recebimento.
					if ! empty (zzt -> zzt_safra) .and. ! empty (zzt -> zzt_carga)
						_SegPesSZE ()
					endif

				elseif _sOperPort == '4'
//					U_ZT_Impri(ZZT->ZZT_COD, mv_par07)
				endif
			endif
		endif
	endif
	if _lContinua .and. _sOperPort $ '12'
		// nao permite atualizar o naweb dentro de uma transacao (va_rus1p)		begin transaction
			if AxInclui ("ZZT", ZZT -> (recno ()), 3, NIL, NIL, NIL, "U_ZZT_TOk ()",,,_aBotAdic) == 1

				// Atualiza carga safra.
				if zzt -> zzt_entsai == 'E' .and. zzt -> zzt_pesent > 0 .and. ! empty (zzt -> zzt_safra) .and. ! empty (zzt -> zzt_carga)
					sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
					if sze -> (dbseek (xfilial ("SZE") + zzt -> zzt_safra + zzt -> zzt_carga, .F.))
						if sze -> ze_pesobru == 0
							reclock ("SZE", .F.)
							sze -> ze_pesobru = zzt -> zzt_pesent
							msunlock ()

							// Chama primeira pesagem de safra para atualizacoes adicionais
							U_Log2 ('debug', 'Chamando VA_Rus1P de dentro do ' + procname ())
							U_VA_RUS1P (.T.)
						else
							u_help ("Carga safra jah tem peso bruto cadastrado. O mesmo nao serah atualizado.",, .t.)
						endif
					endif
				endif
			else
				_lContinua = .F.
			endif
		// nao permite atualizar o naweb dentro de uma transacao (va_rus1p)		end transaction
	
		// Impressao de ticket
		if _lContinua
			if _sOperPort == '1'
				U_ImpZZT(ZZT->ZZT_COD, '', 1)
			elseif _sOperPort == '2'
//				U_ZT_Impri(ZZT->ZZT_COD, mv_par05)
			endif
		endif
	endif

	if _lContinua .and. _sOperPort == '6'
		if AxAltera ("ZZT", ZZT -> (Recno ()), 4, NIL, NIL, NIL, NIL, "U_ZZT_TOk ()", NIL, "U_ZZT_AA ()", _aBotAdic) == 1
			//u_log ('confirmou axaltera')
		endif
	endif

	set key 119 to
Return
//
// --------------------------------------------------------------------------
// Chama tela de segunda pesagem de safra para fechamento da carga.
static function _SegPesSZE ()
	local _aAmbPort  := {}
	local _aAreaPort := {}

	sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
	if sze -> (dbseek (xfilial ("SZE") + zzt -> zzt_safra + zzt -> zzt_carga, .F.))
	//	if U_MsgYesNo ("Deseja abrir a tela de safra para finalizar o recebimento da carga " + zzt -> zzt_carga + " ?")
			U_Log2 ('info', '[' + procname () + '] Vou chamar a tela de segunda pesagem de safra para encerrar a carga.')
			_aAreaPort := U_ML_SRArea ()
			_aAmbPort  := U_SalvaAmb ()

			// Deixa uma carga instanciada, mesmo que vazia, pois algumas funcoes
			// (como a validacao de parametros por exemplo) jah vao tentar ler o objeto.
			private _oCarSaf := ClsCarSaf ():New (sze -> (recno ()))

			// Variaveis que os programas de safra esperam encontrar.
			private _ZFEMBALAG := ""  // Deixar private para ser vista por outras rotinas.
			private _sBalanca  := iif (cFilAnt == '01', 'LB', iif (cFilAnt == '07', 'JC', iif (cFilAnt == '09', 'SP', '')))
			private _lLeitBar  := ""  // Deixar private para ser vista por outras rotinas.
			private _lBalEletr := ""  // Deixar private para ser vista por outras rotinas.
			private _sPortaBal := ""  // Deixar private para ser vista por outras rotinas.
			private _sModelBal := ""  // Deixar private para ser vista por outras rotinas.
			private _nMultBal  := ""  // Deixar private para ser vista por outras rotinas.
			private _nPesoEmb  := ""  // Deixar private para ser vista por outras rotinas.
		//	private _lLeBrix   := .F. // Deixar private para ser vista por outras rotinas.
			private _nQViasTk1 := 0   // Deixar private para ser vista por outras rotinas.
			private _nQViasTk2 := 0   // Deixar private para ser vista por outras rotinas.
			private _xSAFRAJ   := U_IniSafra ()  // Retorna o Ano da Safra (ML_SZ9.PRW)
			private aRotina    := {}
			private cPerg      := 'VA_RUS'
			private _zx509fina := _oCarSaf:RecebeVini
			private _zx509orga := _oCarSaf:RecebeOrg
			private _lIntPort  := ""  // Deixar private para ser vista por outras rotinas.

			aadd (aRotina, {"&Pesquisar"        , "AxPesqui"			, 0,1})
			aadd (aRotina, {"&Visualizar"       , "U_VA_RUS2 (2, .F.)"	, 0,2})
			aadd (aRotina, {"Incluir"           , "U_VA_RUS1"			, 0,3})
			aadd (aRotina, {"&1a pesagem"       , "U_VA_RUS1P ()"		, 0,4})
			aadd (aRotina, {"&2a pesagem"       , "U_VA_RUS2 (4, .F.)"	, 0,4})

			U_VA_RUSLP (.F.)  // Releitura de parametros do programa de safra
			U_VA_Rus2 (4, .T.)  // Segunda pesagem: opcao4=alteracao; .t.=a partir do fechamento de uma entrada no contr.portaria
			U_SalvaAmb (_aAmbPort)
			U_ML_SRArea (_aAreaPort)

			U_Log2 ('info', '[' + procname () + '] Retornou da tela de segunda pesagem de safra.')
	//	endif
	else
		U_Log2 ('erro', '[' + procname () + ']Nao encontrei SZE!')
	endif
return
//
// --------------------------------------------------------------------------
// Atualiza numero do ticket nas cargas.
static function _AtuCargas (_aCargas)
	local _nCarga := 0

	dak -> (dbsetorder (1))  //DAK_FILIAL+DAK_COD+DAK_SEQCAR
	szo -> (dbsetorder (1))
	for _nCarga = 1 to len (_aCargas)
		if _aCargas [_nCarga, .CargasOK]
			if _aCargas [_nCarga, .CargasOrigem] == 'DAK'
				if ! dak -> (dbseek (xfilial ("DAK") + _aCargas [_nCarga, .CargasCodigo], .F.))
					u_help ("Carga '" + _aCargas [_nCarga, .CargasCodigo] + "' nao encontrada na tabela DAK para atualizacao.",, .t.)
				else
					RecLock("DAK",.F.)
					DAK->DAK_VATKP := zzt->ZZT_COD
					MsUnlock("DAK")
				endif
			endif
			if _aCargas [_nCarga, .CargasOrigem] == 'SZO'
				if ! szo -> (dbseek (xfilial ("SZO") + _aCargas [_nCarga, .CargasCodigo], .F.))
					u_help ("Carga '" + _aCargas [_nCarga, .CargasCodigo] + "' nao encontrada na tabela SZO para atualizacao.",, .t.)
				else
					reclock ("SZO", .F.)
					szo -> zo_vatkp = zzt -> zzt_cod
					msunlock ()
				endif
			endif
		endif
	next
return
//
// --------------------------------------------------------------------------
// Valida inclusao e alteracao.
User Function ZZT_TOk ()
	local _lRet    := .T.
	local _sJahTem := ""

	if _lRet .and. m->zzt_motivo == '2'  // coleta
		if _sOperPort == '1' .and. empty (m->zzt_pesent)
			u_help ("Para coletas informe o peso de entrada.",, .t.)
			_lRet = .F.
		endif
		if _sOperPort == '3' .and. empty (m->zzt_pessai)
			u_help ("Para coletas informe o peso de saida.",, .t.)
			_lRet = .F.
		endif
		if _sOperPort == '3' .and. m->zzt_pesent >= m->zzt_pessai
			u_help ("Para coletas o peso de saida nao pode ser menor que o peso de entrada.",, .t.)
			_lRet = .F.
		endif
		if _sOperPort == '3'
			if m->zzt_blqpes == 'S'
				_lRet = u_msgnoyes ("Ticket vai ficar bloqueado por diferenca de peso. Confirma?", .F.)
			endif
		endif
	endif
	if _lRet .and. m->zzt_motivo == '4' // safra
		if empty (m->zzt_safra) .or. empty (m->zzt_carga)
			u_help ("Para entregas de safra informe safra e carga.",, .t.)
			_lRet = .F.
		endif
		if _sOperPort == '1'  // Entrada (1a. pesagem)
			if empty (m->zzt_pesent)
				u_help ("Para entregas de safra informe o peso de entrada.",, .t.)
				_lRet = .F.
			else
				sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
				if ! sze -> (dbseek (xfilial ("SZE") + m->zzt_safra + m->zzt_carga, .F.))
					u_help ("Carga de safra '" + m->zzt_carga + "' nao localizada.",, .t.)
					_lRet = .F.
				else
					// Leitura das inspecoes.
					_lRet = U_VA_RusLI (1, .f.)
				endif
			endif
		endif
		if _sOperPort == '3' .and. empty (m->zzt_pessai)
			u_help ("Para entregas de safra informe o peso de saida.",, .t.)
			_lRet = .F.
		endif
		if _sOperPort == '3' .and. m->zzt_pesent <= m->zzt_pessai
			u_help ("Para entregas de safra o peso de entrada nao pode ser menor que o peso de saida.",, .t.)
			_lRet = .F.
		endif
	endif
	if _lRet .and. m->zzt_motivo != '4' // testa para safra
		if !empty (m->zzt_safra) .or. !empty (m->zzt_carga)
			u_help ("Safra e carga so podem ser informadas quando motivo = 'Safra'.",, .t.)
			_lRet = .F.
		endif
	endif
	if _lRet .and. _sOperport $ '14' .and. (empty (m->zzt_dtent) .or. empty (m->zzt_hrent))
		u_help ("Informe data e hora de entrada.",, .t.)
		_lRet = .F.
	endif
	if _lRet .and. _sOperport $ '23' .and. (empty (m->zzt_dtsai) .or. empty (m->zzt_hrsai))
		u_help ("Informe data e hora de saida.",, .t.)
		_lRet = .F.
	endif
	if _lRet .and. ! empty (m->zzt_safra) .and. ! empty (m->zzt_carga)
		_sJahTem = fBuscaCpo ("ZZT", 2, xfilial ("ZZT") + m->zzt_safra + m->zzt_carga, "ZZT_COD")
		if ! empty (_sJahTem) .and. _sJahTem != m->zzt_cod
			u_help ("Ja existe o ticket '" + _sJahTem + "' para esta carga de safra.",, .t.)
			_lRet = .F.
		endif
	endif
	if _lRet .and. m->zzt_motivo = '3' // entrega
		if empty (m->zzt_forn)
			u_help ("Obrigatorio informar fornecedor, para motivo de Entrega.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->zzt_forn)
			u_help ("Obrigatorio informar o fornecedor, para motivo de Entrega.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->zzt_lojf)
			u_help ("Obrigatorio informar loja do fornecedor, para motivo de Entrega.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->zzt_nf)
			u_help ("Obrigatorio informar a nota fiscal do fornecedor, para motivo de Entrega.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. len(ALLTRIM(m->zzt_nf)) != 9
			u_help ("Obrigatorio informar o nro da nota fiscal com 9 digitos",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. !empty(m->zzt_chvnfe)

			//verifica se o fornecedor ta correto conforme a chave
			// so testa a inconsistencia de CNPJ se nao for a excecao das notas avulsas
			if ! substr (m->zzt_chvnfe, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
				// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
				//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
				//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
				//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
				//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
				_wcgc  = substr(m->zzt_chvnfe, 7, 14)
				_wforn = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcgc , "A2_COD")
				if _wforn != m->zzt_forn    
					u_help ("Fornecedor da chave nfe nao confere com o fornecedor digitado",, .t.)
					_lRet = .F.
				endif
			endif

			// verifica o nro do documento
			if _lRet .and. substr(m->zzt_chvnfe, 26, 9) !=  m->zzt_nf
				u_help ("Nro da nota fiscal da chave nfe nao confere com o documento digitado",, .t.)
				_lRet = .F.			      
			endif
		endif
	endif
	
	if _lRet .and. !empty(m->zzt_chv2)
		if ! substr (m->zzt_chv2, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv2, 7, 14)
			_wforn = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcgc , "A2_COD")
			if _wforn != m->zzt_forn    
				u_help ("Fornecedor da chave nfe nao confere com o fornecedor digitado",, .t.)
				_lRet = .F.
			endif
		endif
	endif
	if _lRet .and. !empty(m->zzt_chv3)
		if ! substr (m->zzt_chv3, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv3, 7, 14)
			_wforn = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcgc , "A2_COD")
			if _wforn != m->zzt_forn    
				u_help ("Fornecedor da chave nfe nao confere com o fornecedor digitado",, .t.)
				_lRet = .F.
			endif
		endif
	endif				
    if _lRet .and. !empty(m->zzt_chv4)
		if ! substr (m->zzt_chv4, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv4, 7, 14)
			_wforn = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcgc , "A2_COD")
			if _wforn != m->zzt_forn    
				u_help ("Fornecedor da chave nfe nao confere com o fornecedor digitado",, .t.)
				_lRet = .F.
			endif
		endif
	endif	
	if _lRet .and. !empty(m->zzt_chv5)
		if ! substr (m->zzt_chv5, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv5, 7, 14)
			_wforn = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcgc , "A2_COD")
			if _wforn != m->zzt_forn    
				u_help ("Fornecedor da chave nfe nao confere com o fornecedor digitado",, .t.)
				_lRet = .F.
			endif
		endif
	endif	
	
	
	if _lRet .and. m->zzt_motivo = '5' // outros
		if empty(m->zzt_obs)
			u_help ("Para motivo OUTROS, Obrigatorio informar observacao no controle de portaria",, .t.)
			_lRet = .F.
		endif					
	endif
	if _lRet .and. m->zzt_motivo = '6' // recebe devoluï¿½ï¿½o
		if empty (m->zzt_chvnfe)
			u_help ("Para motivo RECEB. DEVOLUCOES, Obrigatorio informar ao menos uma chave de Nota Fiscal.",, .t.)
			_lRet = .F.
		endif
		if _lRet .and. !empty(m->zzt_chv2)
			if ! substr (m->zzt_chv2, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv2, 7, 14)
			_wcli = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
				if _wcli != m->zzt_client    
					u_help ("Cliente da chave nfe nao confere com o cliente digitado",, .t.)
					_lRet = .F.
				endif
			endif
		endif			
		if _lRet .and. !empty(m->zzt_chv3)
			if ! substr (m->zzt_chv3, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv3, 7, 14)
			_wcli = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
				if _wcli != m->zzt_client    
					u_help ("Cliente da chave nfe nao confere com o cliente digitado",, .t.)
					_lRet = .F.
				endif
			endif
		endif	
		if _lRet .and. !empty(m->zzt_chv4)
			if ! substr (m->zzt_chv4, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv4, 7, 14)
			_wcli = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
				if _wcli != m->zzt_client    
					u_help ("Cliente da chave nfe nao confere com o cliente digitado",, .t.)
					_lRet = .F.
				endif
			endif
		endif	
		if _lRet .and. !empty(m->zzt_chv5)
			if ! substr (m->zzt_chv5, 23, 3) $ "890#891#892#893#894#895#896#897#898#899"
			// Exceï¿½ï¿½o 7: Escrituraï¿½ï¿½o de documentos emitidos por terceiros: os casos de escrituraï¿½ï¿½o de documentos fiscais 
			//            emitidos por terceiros, inclusive NF-e, como por ex. o consï¿½rcio constituï¿½do nos termos do 
			//            disposto nos Art. 278 e 279 da Lei nï¿½ 6.404, de 15 de dezembro de 1976, e das NF-e ï¿½avulsasï¿½ 
			//            emitidas pelas UF (sï¿½ries 890 a 899) devem ser informados como emissï¿½o de terceiros, com o 
			//            cï¿½digo de situaï¿½ï¿½o do documento igual a ï¿½08 - Documento Fiscal emitido com base em Regime Especial ou Norma Especï¿½ficaï¿½.  
			_wcgc  = substr(m->zzt_chv5, 7, 14)
			_wcli = fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
				if _wcli != m->zzt_client    
					u_help ("Cliente da chave nfe nao confere com o cliente digitado",, .t.)
					_lRet = .F.
				endif
			endif
		endif	
		
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Funcao chamada antes da alteracao.
User Function ZZT_AA ()
	if _sOperPort == '3'
		m->zzt_dtsai  = date ()
		m->zzt_hrsai  = time ()
		m->zzt_usrfec = cUserName
	endif
	if _sOperPort == '2'
		m->zzt_dtent = date ()
		m->zzt_hrent = time ()
	endif
	if _sOperPort == '4'
		m->zzt_dtent  = date ()
		m->zzt_hrent  = time ()
		m->zzt_usrfec = cUserName
	endif
return
//
// --------------------------------------------------------------------------
// Cria tela de selecao de cargas (da logistica) que podem ser vinculadas ao ticket da portaria.
static function _SelCarg ()
	local _oSQL    := NIL
	local _aCols   := {}
	local _nCarga  := 0
	local _sCargas := ""
	local _aRetQry := {}

	// Busca cargas do OMS e ordens de embarque junto, pois pode haver casos de embarcar pedidos
	// separados pela logistica (cargas do modulo OMS) e separados manualmente (ordem embarque tabela SZO).
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH CTE AS ("
	_oSQL:_sQuery += " SELECT DAK_COD, DAK_VATRAN, A4_NOME, DAK_PESO, dbo.VA_DTOC (DAK_DATA) AS EMISSAO, DAK_VAUSER, 'Carga logistica' AS DESCRI, 'DAK' AS ORIGEM "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("DAK") + " DAK, "
	_oSQL:_sQuery +=              RetSQLName ("SA4") + " SA4 "
	_oSQL:_sQuery +=  " WHERE DAK.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND DAK.DAK_VATKP  = ''"
	if ! empty (m->zzt_transp)
		_oSQL:_sQuery += " AND DAK.DAK_VATRAN = '" + m->zzt_transp + "'"
	endif
	_oSQL:_sQuery +=    " AND SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND DAK_FILIAL  = '" + xfilial ("DAK") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_COD     = DAK.DAK_VATRAN"
	_oSQL:_sQuery +=  " UNION ALL"
	_oSQL:_sQuery += " SELECT ZO_NUMERO, ZO_TRANSP, A4_NOME, 0 AS PESO, dbo.VA_DTOC (ZO_EMISSAO) AS EMISSAO, ZO_USUARIO, 'Ordem embarque' AS DESCRI, 'SZO' AS ORIGEM "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZO") + " SZO, "
	_oSQL:_sQuery +=              RetSQLName ("SA4") + " SA4 "
	_oSQL:_sQuery +=  " WHERE SZO.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SZO.ZO_VATKP   = ''"
	if ! empty (m->zzt_transp)
		_oSQL:_sQuery += " AND SZO.ZO_TRANSP = '" + m->zzt_transp + "'"
	endif
	_oSQL:_sQuery +=    " AND SA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SZO.ZO_FILIAL  = '" + xfilial ("SZO") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_oSQL:_sQuery +=    " AND SA4.A4_COD     = SZO.ZO_TRANSP"
	_oSQL:_sQuery += ") SELECT * FROM CTE"
	_oSQL:_sQuery +=  " ORDER BY DAK_COD"
	//_oSQL:Log ()

	// Cria array para selecao do usuario
	_aRetQry := aclone (_oSQL:Qry2Array (.F., .F.))
	_aCargas = {}
	For _nCarga := 1 To Len (_aRetQry)
		aadd (_aCargas, array (.CargasQtColunas))
		_aCargas [len (_aCargas), .CargasOK]         = .F.
		_aCargas [len (_aCargas), .CargasCodigo]     = _aRetQry [_nCarga, 1]
		_aCargas [len (_aCargas), .CargasTransp]     = _aRetQry [_nCarga, 2]
		_aCargas [len (_aCargas), .CargasNomeTransp] = _aRetQry [_nCarga, 3]
		_aCargas [len (_aCargas), .CargasPeso]       = _aRetQry [_nCarga, 4]
		_aCargas [len (_aCargas), .CargasEmissao]    = _aRetQry [_nCarga, 5]
		_aCargas [len (_aCargas), .CargasUsuario]    = _aRetQry [_nCarga, 6]
		_aCargas [len (_aCargas), .CargasDescri]     = _aRetQry [_nCarga, 7]
		_aCargas [len (_aCargas), .CargasOrigem]     = _aRetQry [_nCarga, 8]
	next
	_aCols := {}
	aadd (_aCols, {.CargasCodigo,     'Cod_carga',    40, ''})
	aadd (_aCols, {.CargasTransp,     'Transp',       60, ''})
	aadd (_aCols, {.CargasNomeTransp, 'Nome transp', 100, ''})
	aadd (_aCols, {.CargasEmissao,    'Emissao',      40, ''})
	aadd (_aCols, {.CargasPeso,       'Peso',         40, '@E 999,999,999.99'})
	aadd (_aCols, {.CargasUsuario,    'Usuario',      50, ''})
	aadd (_aCols, {.CargasDescri,     'Descricao',    60, ''})
	U_MbArray (@_aCargas, "Selecione a(s) carga(s) embarcada(s)", _aCols, 1)

	// Busca o peso das notas das cargas selecionadas.
	m->zzt_pesonf = 0
	//
	// Busca pelo DAK
	_sCargas = ""
	for _nCarga = 1 to len (_aCargas)
		if _aCargas [_nCarga, .CargasOK] .and. _aCargas [_nCarga, .CargasOrigem] == 'DAK'
			_sCargas += iif (empty (_sCargas), '', ',') + "'" + _aCargas [_nCarga, .CargasCodigo] + "'"
		endif
	next
	if ! empty (_sCargas)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := " SELECT SUM (SB1.B1_PESBRU * SC9.C9_QTDLIB) AS PESO"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC9") + " SC9, "
		_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery +=  " WHERE SC9.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB1.B1_COD     = SC9.C9_PRODUTO "
		_oSQL:_sQuery +=    " AND SC9.C9_FILIAL  = '" + xfilial ("SC9") + "'"
		_oSQL:_sQuery +=    " AND SC9.C9_CARGA IN (" + _sCargas + ")"
		//_oSQL:Log ()
		m->zzt_pesonf += _oSQL:RetQry (1, .f.)
	endif
	//
	// Busca pelo SZO
	_sCargas = ""
	for _nCarga = 1 to len (_aCargas)
		if _aCargas [_nCarga, .CargasOK] .and. _aCargas [_nCarga, .CargasOrigem] == 'SZO'
			_sCargas += iif (empty (_sCargas), '', ',') + "'" + _aCargas [_nCarga, .CargasCodigo] + "'"
		endif
	next
	if ! empty (_sCargas)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := " SELECT SUM (SB1.B1_PESBRU * SD2.D2_QUANT) AS PESO"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") + " SD2, "
		_oSQL:_sQuery +=              RetSQLName ("SF2") + " SF2, "
		_oSQL:_sQuery +=              RetSQLName ("SZO") + " SZO, "
		_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery +=  " WHERE SD2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
		_oSQL:_sQuery +=    " AND SD2.D2_DOC     = SF2.F2_DOC"
		_oSQL:_sQuery +=    " AND SD2.D2_SERIE   = SF2.F2_SERIE"
		_oSQL:_sQuery +=    " AND SF2.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SF2.F2_FILIAL  = SZO.ZO_FILIAL"
		_oSQL:_sQuery +=    " AND SF2.F2_ORDEMB  = SZO.ZO_NUMERO"
		_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=    " AND SB1.B1_COD     = SD2.D2_COD"
		_oSQL:_sQuery +=    " AND SZO.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SZO.ZO_FILIAL  = '" + xfilial ("SZO") + "'"
		_oSQL:_sQuery +=    " AND SZO.ZO_NUMERO IN (" + _sCargas + ")"
		//_oSQL:Log ()
		m->zzt_pesonf += _oSQL:RetQry (1, .f.)
	endif
	RunTrigger (1, nil, nil,, "ZZT_PESONF")  // Executa gatilhos do campo.

	m->zzt_usrfec = cUserName
return
//
// --------------------------------------------------------------------------
// Funcao para coletar informacao de peso da balanca e jogar nos campos de peso entrada ou peso saida
User function PesaZZT()
	private _nPLidoBal := 0

	processa ({|| _nPLidoBal := U_LeBalan3 ()})

	if _sOperPort $ '14'
		M->ZZT_PESENT := _nPLidoBal
		RunTrigger (1, nil, nil,, "ZZT_PESENT")  // Executa gatilhos do campo.
	elseif _sOperPort $ '23'
		M->ZZT_PESSAI :=  _nPLidoBal
		RunTrigger (1, nil, nil,, "ZZT_PESSAI")  // Executa gatilhos do campo.
	endif
return
//
// --------------------------------------------------------------------------
// Consulta de dados controle de portaria
User Function VA_ZZTCON()
    Local _aCols  := {}
    Local _aDados := {} 

    cPerg   := "VA_ZZTCON"
	_ValidPerg (cPerg)
	
    If Pergunte(cPerg,.T.)
        _oSQL:= ClsSQL():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "      ZZT_FILIAL"
        _oSQL:_sQuery += " 	   ,CASE "
        _oSQL:_sQuery += " 		    WHEN ZZT_ENTSAI = 'E' THEN 'ENTRADA' "
        _oSQL:_sQuery += " 		    ELSE 'SAIDA' "
        _oSQL:_sQuery += " 	   END TIPO "
        _oSQL:_sQuery += "    ,CASE "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '1' THEN 'VISITA' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '2' THEN 'COLETA' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '3' THEN 'ENTREGA' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '4' THEN 'SAFRA' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '5' THEN 'OUTROS' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '6' THEN 'RECEB.DEVOLUCOES' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '7' THEN 'AGUA' "
        _oSQL:_sQuery += " 		WHEN ZZT_MOTIVO = '8' THEN 'TRANSFERENCIA' "
        _oSQL:_sQuery += " 	   END MOTIVO "
        _oSQL:_sQuery += "    ,ZZT_DTENT "
        _oSQL:_sQuery += "    ,ZZT_HRENT "
        _oSQL:_sQuery += "    ,ZZT_DTSAI "
        _oSQL:_sQuery += "    ,ZZT_HRSAI "
        _oSQL:_sQuery += "    ,ZZT_PESENT "
        _oSQL:_sQuery += "    ,ZZT_PESSAI "
        _oSQL:_sQuery += "    ,ZZT_PESLIQ "
        _oSQL:_sQuery += "    ,ZZT_QPCISP "
        _oSQL:_sQuery += "    ,ZZT_QTPBR "
        _oSQL:_sQuery += "    ,ZZT_QCHTEX "
        _oSQL:_sQuery += "    ,ZZT_PESPAL "
        _oSQL:_sQuery += "    ,ZZT_PESONF "
        _oSQL:_sQuery += "    ,ZZT_DIFPES "
        _oSQL:_sQuery += "    ,ZZT_CARGA "
        _oSQL:_sQuery += "    ,ZZT_PLACA "
        _oSQL:_sQuery += "    ,ZZT_PCARRO "
        _oSQL:_sQuery += "    ,ZZT_TRANSP "
        _oSQL:_sQuery += "    ,ZZT_MOTOR "
        _oSQL:_sQuery += "    ,ZZT_NOME "
        _oSQL:_sQuery += "    ,ZZT_CHVNFE "
        _oSQL:_sQuery += "    ,ZZT_NF "
        _oSQL:_sQuery += "    ,ZZT_FORN "
        _oSQL:_sQuery += "    ,ZZT_LOJF "
        _oSQL:_sQuery += "    ,ZZT_CLIENT "
        _oSQL:_sQuery += "    ,ZZT_LOJAC "
		_oSQL:_sQuery += "    ,ZZT_OBS "
        _oSQL:_sQuery += " FROM ZZT010 "
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND ZZT_COD BETWEEN   '" + mv_par01 + "' AND '"+ mv_par02 + "'"
		if !empty(mv_par03)
        	_oSQL:_sQuery += " AND ZZT_DTENT BETWEEN '" + dtos(mv_par03) + "' AND '"+ dtos(mv_par04) + "'"
		endif
		if !empty(mv_par05)
        	_oSQL:_sQuery += " AND ZZT_DTSAI BETWEEN '" + dtos(mv_par05) + "' AND '"+ dtos(mv_par06) + "'"
		endif
		If !empty(mv_par07)
        	_oSQL:_sQuery += " AND ZZT_PLACA       = '" + mv_par07       + "'"
		EndIf
        If mv_par08 == 2 // com diferença
            _oSQL:_sQuery += " AND ZZT_DIFPES  < 0 " 
        else
            if mv_par08 == 3 // sem diferença
                _oSQL:_sQuery += " AND ZZT_DIFPES  > 0 " 
            endif
        endif
        u_log (_oSQL:_squery)
        _aDados := aclone (_oSQL:Qry2Array (.t., .f.))

        aadd (_aCols, {01, "Filial"  	   	    ,  10,  "@!"})
        aadd (_aCols, {02, "Tipo"       	    ,  15,  "@!"})
        aadd (_aCols, {03, "Motivo"             ,  20,  "@!"})
        aadd (_aCols, {04, "Dt.Entrada" 	    ,  10,  "@D"})
        aadd (_aCols, {05, "Hr.Entrada"         ,  10,  "@!"})
        aadd (_aCols, {06, "Dt.Saida"           ,  10,  "@D"})
        aadd (_aCols, {07, "Hr.Saida"           ,  10,  "@!"})
        aadd (_aCols, {08, "Peso Entrada"       ,  15,  "@E 9,999,999.99"})
        aadd (_aCols, {09, "Peso Saida"         ,  15,  "@E 9,999,999.99"})
        aadd (_aCols, {10, "Peso Liquido"       ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {11, "Qt.pallets Cisper"  ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {12, "Qt pallets PBR"     ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {13, "Qt.chapatex"        ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {14, "Peso pallets"       ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {15, "Peso NF saida"      ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {16, "Diferenca peso"     ,  20,  "@E 9,999,999.99"})
        aadd (_aCols, {17, "Carga Safra"       	,  20,  "@!"})
        aadd (_aCols, {18, "Placa veiculo"      ,  20,  "@!"})
        aadd (_aCols, {19, "Placa carroceria"   ,  20,  "@!"})
        aadd (_aCols, {20, "Transportadora"     ,  20,  "@!"})
        aadd (_aCols, {21, "Cod.Motorista"      ,  20,  "@!"})
        aadd (_aCols, {22, "Nome Motorista"     ,  40,  "@!"})
        aadd (_aCols, {23, "Chave NF "      	,  50,  "@!"})
        aadd (_aCols, {24, "Nota Fiscal"       	,  20,  "@!"})
        aadd (_aCols, {25, "Fornecedor"       	,  20,  "@!"})
        aadd (_aCols, {26, "Loja"       	    ,  10,  "@!"})
        aadd (_aCols, {27, "Cliente"       	    ,  20,  "@!"})
        aadd (_aCols, {28, "Loja"       	    ,  10,  "@!"})
		aadd (_aCols, {29, "OBS "       	    ,  20,  "@!"})
        
        U_F3Array (_aDados, "Controle de portaria", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 40 , "", "", .T., 'C' )
    else
        u_help("Não foram encontrados dados para consulta")
    EndIf 
Return

// --------------------------------------------------------------------------
// Consulta simples do historico de pesos lidos na balanca.
user function VA_ZZTHP ()
	local _sTabPeso  := ''
	local _oSQL      := NIL
	local _aAmbAnt   := U_SalvaAmb ()
	local _sPattern  := ''
	local _lContinua := .T.

	if _lContinua
		if cFilAnt == '01'
			_sTabPeso = 'VA_PESOS_BALANCA_MATRIZ'
		elseif cFilAnt == '07'
			_sTabPeso = 'VA_PESOS_BALANCA_F07'
		else
			u_help ("Sem tratamento para a empresa / filial atual.",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_ValidPerg ("VA_ZZTHP")
		if ! pergunte ("VA_ZZTHP")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Cria objeto da classe 'expressao regular' para validar formato dos horarios.
		_oRegex := tlpp.regex.Regex():new ('')
		_oRegex:setCaseSensitive (.F.)

		// Monta pattern (padrao) de pesquisa usando a sintaxe das expressoes regulares.
		_sPattern := '([01][0-9]|2[0-3])'  // Horas: de (00 a 19) ou (20 a 23)
		_sPattern += ':'                   // : separando horas e minutos
		_sPattern += '[0-5][0-9]'          // Minutos: de 00 a 59
		_sPattern += ':'                   // : separando minutos e segundos
		_sPattern += '[0-5][0-9]'          // Segundos: de 00 a 59

		_oRegex:SetPattern (_sPattern)

		if ! _oRegex:PartialMatch (mv_par02)
			u_help ("Hora inicial '" + mv_par02 + "' invalida. Formato deve ser HH:MM:SS.",, .t.)
			_lContinua = .F.
		endif
		if ! _oRegex:PartialMatch (mv_par04)
			u_help ("Hora final '" + mv_par04 + "' invalida. Formato deve ser HH:MM:SS.",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery += "SELECT FORMAT (DATAHORA, 'dd/MM/yyyy HH:mm:ss') AS DATA_HORA, PESO AS PESO_KG"
		_oSQL:_sQuery +=  " FROM " + _sTabPeso
		_oSQL:_sQuery += " WHERE DATAHORA >= '" + dtos (mv_par01) + ' ' + mv_par02 + "'"
		_oSQL:_sQuery +=   " AND DATAHORA <= '" + dtos (mv_par03) + ' ' + mv_par04 + "'"
		_oSQL:_sQuery += " ORDER BY DATAHORA"
		_oSQL:Log ('[' + procname () + ']')
		u_showarray (_oSQL:Qry2Array (.f., .f.))
	endif

	U_SalvaAmb (_aAmbAnt)
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg (_sPerg)
    local _aRegsPerg := {}

	if _sPerg == "VA_ZZTCON"
		//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
		aadd (_aRegsPerg, {01, "Ticket de       ", "C", 9, 0,  "",   "ZZT", {},  ""})
		aadd (_aRegsPerg, {02, "Ticket até      ", "C", 9, 0,  "",   "ZZT", {},  ""})
		aadd (_aRegsPerg, {03, "Dt.entrada de   ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {04, "Dt.entrada até  ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {05, "Dt.saída de     ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {06, "Dt.saída até    ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {07, "Placa           ", "C", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {08, "Peso            ", "N", 1, 0,  "",     " ", {"Ambos", "Com difer.", "Sem difer."},,  ""})
	elseif _sPerg == "VA_ZZTHP"
		//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
		aadd (_aRegsPerg, {01, "Dada inicial                  ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {02, "Hora inicial(formato HH:MM:SS)", "C", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {03, "Dada final                    ", "D", 8, 0,  "",     " ", {},  ""})
		aadd (_aRegsPerg, {04, "Hora final(formato HH:MM:SS)  ", "C", 8, 0,  "",     " ", {},  ""})
	endif
	U_ValPerg (_sPerg, _aRegsPerg)
Return
