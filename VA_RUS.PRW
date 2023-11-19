// Programa...: VA_RUS
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Descricao..: Tela de recebimento de uva durante a safra (uso na balanca).
//
// Historico de alteracoes:
// 01/02/2010 - Robert - Nao busca mais os associados inativos ou bloqueados.
// 16/04/2010 - Robert - Criado tratamento para associados do Condominio.
// 20/04/2010 - Robert - Verifica existencia de cargas antigas sem contranota.
// 06/01/2011 - Robert - Ajustes para safra 2011
// 04/01/2016 - Robert - Criado atalho para visualizacao da contranota.
// 19/01/2016 - Robert - Ajustes visualizacao fila descarga.
// 05/01/2017 - Robert - Ajustes para safra 2017.
// 16/02/2017 - Robert - Incluida filial 07 para receber uva propria.
// 04/01/2017 - Robert - Criado botao '1a.pesagem' separado de 'incluir'.
// 16/01/2018 - Robert - Criado botao para reenviar a carga para leitura de grau.
// 26/04/2018 - Robert - Criado botao para rastrear a carga no estoque.
//    02/2019 - Robert - Melhorias gerais para safra 2019
// 05/02/2019 - Robert - Ajustes para receber uva de associados da Coop.Garibaldi.
// 13/12/2019 - Robert - Adequacoes iniciais para safra 2020 (porta impressora ticket).
// 03/01/2020 - Robert - Criada opcao de (re)transmitir o XML da contranota para a SEFAZ.
// 20/01/2020 - Robert - Novos parametros chamada geracao ticket safra.
// 01/12/2020 - Robert - Passa a buscar dados de cadastro viticola na view GX0001_AGENDA_SAFRA e nao mais na VA_VASSOC_CAD_VITIC2
// 02/02/2021 - Robert - Criado botao para chamar o VA_RusEn (GLPI 8779).
// 03/02/2021 - Robert - Novos parametros funcao U_VA_Rus2().
// 16/02/2021 - Robert - Implementada simulacao de geracao de contranota (GLPI 9420)
// 23/02/2021 - Robert - Criada chamada para exportar planilha de medicoes de grau (GLPI 9454).
// 13/03/2022 - Robert - Melhorados logs, criados botoes para consulta de eventos e simulacao de leitura de inspecoes.
// 26/05/2022 - Robert - Novos parametros na chamada da funcao U_RastLt().
// 28/10/2022 - Robert - Removidos alguns parametros em desuso.
// 07/12/2022 - Robert - Removidos mais alguns parametros em desuso.
// 08/02/2023 - Robert - Criada opcao de segregar carga.
// 22/02/2023 - Robert - Chamada simulacao frete nao tinha objeto ClsCarSaf() instanciado.
//                     - Novo parametros chamada U_VA_SZNC()
// 18/11/2023 - Robert - Versao inicial do metodo ClsCarSaf:PodeGravar().
//

// --------------------------------------------------------------------------
User Function va_rus ()
	local _nCoop       := 0
	local _sCoop       := ""
	local _aCores      := U_VA_RUSLG (.T.)
	local _aMenuOut    := {}
	local _aMenuNFe    := {}
	local _lContinua   := .T.
	local _nPCham      := 0
	private _ZFEMBALAG := ""  // Deixar private para ser vista por outras rotinas.
	private _sBalanca  := ""  // Deixar private para ser vista por outras rotinas.
	private _lLeitBar  := ""  // Deixar private para ser vista por outras rotinas.
	private _lBalEletr := ""  // Deixar private para ser vista por outras rotinas.
	private _sPortaBal := ""  // Deixar private para ser vista por outras rotinas.
	private _sModelBal := ""  // Deixar private para ser vista por outras rotinas.
	private _nMultBal  := ""  // Deixar private para ser vista por outras rotinas.
	private _nPesoEmb  := ""  // Deixar private para ser vista por outras rotinas.
//	private _lImpTick  := ""  // Deixar private para ser vista por outras rotinas.
//	private _sPortTick := ""  // Deixar private para ser vista por outras rotinas.
	private _lLeBrix   := .F. // Deixar private para ser vista por outras rotinas.
	private _nQViasTk1 := 0   // Deixar private para ser vista por outras rotinas.
	private _nQViasTk2 := 0   // Deixar private para ser vista por outras rotinas.
	//private _lTickPeso := .F. // Deixar private para ser vista por outras rotinas.
	private _xSAFRAJ   := U_IniSafra ()  // Retorna o Ano da Safra (ML_SZ9.PRW)
	private aRotina    := {}
	private cPerg      := 'VA_RUS'
	private _zx509fina := ""  // Deixar private para ser vista por outras rotinas.
	private _zx509orga := ""  // Deixar private para ser vista por outras rotinas.
	private _lIntPort  := ""  // Deixar private para ser vista por outras rotinas.

	// Verifica se estah sendo feita chamada resursiva (Na tela de portaria tem atalho para esta e vice-versa)
	// Devido as diversas chamadas de menus, etc. feitas pelo Protheus, se esta tela jah estiver na pilha, vai ser em um numero bem alto
	_nPCham = 8
	do while procname (_nPCham) != ""
		if procname () $ procname (_nPCham)
			u_help ("Esta tela ja encontra-se aberta. Verifique se foi chamada de dentro da tela de recebimento de safra (ou vice-versa).")
			return
		endif
		_nPCham++
	enddo

	// Deixa uma carga instanciada, mesmo que vazia, pois algumas funcoes
	// (como a validacao de parametros por exemplo) jah vao tentar ler o objeto.
	private _oCarSaf := ClsCarSaf ():New ()

	// Cria parametros e obriga usuario a responde-los na entrada da rotina.
	_ValidPerg ()
	_lContinua = U_VA_RUSLP (.T.)

//	if _lContinua .and. empty (U_RetZX5 ("09", _xSafraJ + _sBalanca, 'ZX5_09LOCA'))
//		u_help ("Relacao balanca X safra nao cadastrada. Verifique tabela 09 do ZX5.")
//		_lContinua = .F.
//	endif
//	if _lContinua
//		_zx509fina = U_RetZX5 ("09", _xSafraJ + _sBalanca, 'ZX5_09FINA')
//		_zx509orga = U_RetZX5 ("09", _xSafraJ + _sBalanca, 'ZX5_09ORGA')
		_zx509fina = _oCarSaf:RecebeVini
		_zx509orga = _oCarSaf:RecebeOrg
//	endif

	// Cria algumas variaveis private para agilizar o uso, jah que eh uma tela que vai
	// ficar em uso durante toda a safra.
	// Sao montadas arrays com as cooperativas (selecao inicial) e com os associados
	// de cada cooperativa, conforme cadastrados na tabela SZD.
	if _lContinua

		// A partir de 2018 estamos usando o conceito de grupos familiares, nao tem mais
		// o condominio, e nao temos previsao de receber de associados de outras cooperativas.
		private _aCoop    := {}
		aadd (_aCoop, {"Alianca", "000021", "01", "Alianca"})  // Codigo e loja no SA2 (embora o tratamento para a Alianca seja diferente)

		// Busca outras cooperativas habilitadas
		sa2 -> (dbsetorder (1))
		szd -> (dbsetorder (1))  // ZD_FILIAL+ZD_SAFRA+ZD_COOP+ZD_LJCOOP+ZD_FORNECE+ZD_LOJAFOR
		szd -> (dbseek (xfilial ("SZD") + _xSAFRAJ, .T.))
		do while ! szd -> (eof ()) .and. szd -> zd_filial == xfilial ("SZD") .and. szd -> zd_safra == _xSAFRAJ
			_sCoop = SZD->ZD_coop+SZD->ZD_ljcoop

			// Insere cooperativa na lista de cooperativas e cria array para guardar seus associados.
			if ascan (_aCoop, {|_aVal| _aVal [2] == szd -> zd_coop .and. _aVal [3] == szd -> zd_ljcoop}) == 0
				aadd (_aCoop, {fBuscaCpo ("SA2", 1, XFILIAL ("SA2")+_sCoop,"A2_NOME"), szd -> zd_coop, szd -> zd_ljcoop,  fBuscaCpo ("SA2", 1, XFILIAL ("SA2")+SZD->ZD_coop+SZD->ZD_ljcoop, "A2_NREDUZ")})

				// Cria uma array com nome igual ao codigo da cooperativa para guardar os seus associados.
				private &("_a" + _sCoop) := {}  // Condominio
			endif

			// Acrescenta associado da outra cooperativa na array dela.
			if ! sa2 -> (dbseek (XFILIAL ("SA2")+SZD->ZD_fornece+SZD->ZD_lojafor, .F.))
				u_help ('Associado ' + SZD->ZD_fornece+SZD->ZD_lojafor + ' ligado `a coop. ' + _sCoop + ' nao encontrado no cadastro de fornecedores.')
			else
				aadd (&("_a" + _sCoop), {sa2 -> a2_nome, sa2 -> a2_cgc, sa2 -> a2_mun, sa2 -> a2_end, sa2 -> a2_cod, sa2 -> a2_loja, ''})
			endif
			szd -> (dbskip ())
		enddo
		
		// Cria uma array para os associados da Alianca.
		private _a00002101 := {}  // Alianca
		//private _a00136901 := {}  // Condominio
		sa2 -> (dbsetorder (1))

		processa ({|| _LeAssoc (), 'Lendo associados'})
		
		if len (_a00002101) == 0
			u_help ("Nao encontrei associados habilitados a entregar uvas")
		endif
	
		// Ordena a lista de cooperativas por nome
		_aCoop = asort (_aCoop,,, {|_x, _y| _x [1] < _y [1]})
	
		// Ordena as listas de associados por nome
		for _nCoop = 1 to len (_aCoop)
			_sCoop = _aCoop [_nCoop, 2] + _aCoop [_nCoop, 3]
			&("_a" + _sCoop) = asort (&("_a" + _sCoop),,, {|_x, _y| _x [1] < _y [1]})
		next
	endif

	// Monta menu para a rotina.
	if _lContinua

		// Submenu para contranota.
		_aMenuNFe = {}
		aadd (_aMenuNFe, {"Gera contra&nota"   ,  "U_VA_RUSOO ('GerarContranota')", 0,4})
		aadd (_aMenuNFe, {"Im&prime DANFe"     ,  "U_VA_RUSOO ('ImprimeDanfe')", 0,4})
		aadd (_aMenuNFe, {"Monitor Faixa"      ,  "U_VA_RUSOO ('MonitorNFe_1')",0,2})
		aadd (_aMenuNFe, {"Monitor Tempo"      ,  "U_VA_RUSOO ('MonitorNFe_2')",0,2})
		aadd (_aMenuNFe, {"Transmite contanota",  "U_VA_RUSOO ('TransmiteContranota')",0,2})
		aadd (_aMenuNFe, {"Visualiza contanota",  "U_VA_RUSVC ()",0,2})
		aadd (_aMenuNFe, {"Devolucao carga    ",  "U_VA_RUSDC ()",0,2})
		aadd (_aMenuNFe, {"Simular contranota" ,  "U_VA_RUSOO ('SimularContranota')", 0,4})

		// Submenu para Outros.
		_aMenuOut = {}
		aadd (_aMenuOut, {"&Parametros",                     "U_VA_RUSLP (.T.)", 0,4})
		aadd (_aMenuOut, {"&Ticket 1a.pesag",                "U_VA_RUSOO ('Tk1Pes')",0,4})
		aadd (_aMenuOut, {"&Ticket 2a.pesag",                "U_VA_RUSOO ('Tk2Pes')",0,4})
		aadd (_aMenuOut, {"&Impr.Recibo",                    "U_VA_RUSR ()", 0,4})
		aadd (_aMenuOut, {"&Cons.Aglutinacoes",              "U_VA_RUSCA (1, .F.)",0,4})
		aadd (_aMenuOut, {"&Reenviar p/grau",                "U_VA_RUSOO ('ReenviarParaGrau')",0,4})
		aadd (_aMenuOut, {"&Rastrear estoque",               "U_VA_RUSRC ()", 0,4})
		aadd (_aMenuOut, {"&NF remessa coop",                "U_VA_RUSNR ('A')", 0,4})
		aadd (_aMenuOut, {"Controle Portaria",               "U_VA_CPORT ()", 0,4})
		aadd (_aMenuOut, {"Exportar medicoes do grau",       "U_VA_XLS54 (sze -> ze_filial, sze -> ze_safra, sze -> ze_carga)", 0,4})
		aadd (_aMenuOut, {"Enderecar uva no estoque",        "U_VA_RusOO ('EnderecarEstoque')", 0,4})
		aadd (_aMenuOut, {"Estornar enderecamento uva",      "U_VA_RusOO ('EstornarEnderecamento')", 0,4})
		aadd (_aMenuOut, {"Registrar evento/comentario",     "U_VA_RusOO ('EventoManual')", 0,4})
//		aadd (_aMenuOut, {"Consultar eventos",               "U_VA_SZNC  ('CARGASAFRA', sze -> ze_safra + sze -> ze_carga)", 0,4})
		aadd (_aMenuOut, {"Consultar eventos",               "U_VA_SZNC  ('CARGASAFRA', sze -> ze_safra, sze -> ze_carga)", 0,4})
		aadd (_aMenuOut, {"Consultar cargas compartilhadas", "U_VA_RusOO ('ConsultarCompartilhamento')", 0,4})
		aadd (_aMenuOut, {"Simular frete",                   "U_VA_RusOO ('SimularFrete')", 0,4})
		if upper (alltrim (cUserName)) $ 'ROBERT.KOCH/DAIANA.RIBAS'
			aadd (_aMenuOut, {"Simular leitura inspecoes",      "U_VA_RusLI (iif (sze -> ze_status == '1', 1, 2), .t.)", 0,4})
			aadd (_aMenuOut, {"Eliminar carga definitivamente", "U_VA_RusED (sze -> ze_safra, sze -> ze_carga)", 0,4})
			aadd (_aMenuOut, {"Segregar carga",                 "U_VA_RusOO ('SegregarCarga')", 0,4})
		endif
		if upper (alltrim (cUserName)) == 'ROBERT.KOCH'
			aadd (_aMenuOut, {"Recuperar carga cancelada (ainda nao pronto!)", "U_VA_RusOO ('RecuperarCargaCancelada')", 0,4})
		endif

		// Menu principal
		aadd (aRotina, {"&Pesquisar"        , "AxPesqui",           0,1})
		aadd (aRotina, {"&Visualizar"       , "U_VA_RUS2 (2, .F.)", 0,2})
		aadd (aRotina, {"Incluir"           , "U_VA_RUS1",          0,3})
		aadd (aRotina, {"&1a pesagem"       , "U_VA_RUS1P ()",      0,4})
		aadd (aRotina, {"&2a pesagem"       , "U_VA_RUS2 (4, .F.)", 0,4})
		aadd (aRotina, {"&Contranota"       , _aMenuNFe,            0,4})
		aadd (aRotina, {"&Outros"           , _aMenuOut,            0,4})
		aadd (aRotina, {"&Cancelar/Excluir" , "U_VA_RUS2 (5, .F.)", 0,5})
		aadd (aRotina, {"&Legenda"          , "U_VA_RUSLG(.F.)",    0,5})
		private cString   := "SZE"
		private cCadastro := "Recebimento de uva safra"
		dbselectarea (cString)
		dbSetOrder (1)
		
		DbSelectArea(cString)
		mBrowse(,,,,cString,,,,,2, _aCores)
		DbSelectArea(cString)
		DbSetOrder (1)
	endif
return



// --------------------------------------------------------------------------
// Tratamento para o que o usuario selecionou no menu de outras opcoes.
user function VA_RUSOO (_sQueFazer)
	local _sEvtManu := ''
	local _sMotSeg  := ''

	// Deixa atributos alimentados no objeto, por que a maioria das rotinas vai precisar.
	_oCarSaf:GeraAtrib ("SZE")

	do case
	case _sQueFazer == upper ('Tk1Pes')  // Sim, a chamada pelo menu parece passar tudo em maiusculas.
		_oCarSaf:ImprimeTk (1)

	case _sQueFazer == upper ('Tk2Pes')
		_oCarSaf:GeraAtrib ("SZE")  // Atualiza atributos com o que foi gravado nos arquivos.
		_oCarSaf:ImprimeTk (2)

	case _sQueFazer == upper ('GerarContranota')
		U_VA_RUSN (.F.)

	case _sQueFazer == upper ('EnderecarEstoque')
	//	_oCarSaf:EnderEstq ('I')
		MsgRun ("Aguarde, gerando enderecamento", "Enderecamento", {|| _oCarSaf:EnderEstq ('I')})

	case _sQueFazer == upper ('EstornarEnderecamento')
		//_oCarSaf:EnderEstq ('E')
		MsgRun ("Aguarde, estornando enderecamento", "Estorno enderecamento", {|| _oCarSaf:EnderEstq ('E')})

	case _sQueFazer == upper ('SimularContranota')
		U_VA_RUSN (.T.)

	case _sQueFazer == upper ('TransmiteContranota')
		U_VA_RUSTX ()

	case _sQueFazer == upper ('ImprimeDanfe')
		if empty (_oCarSaf:Contranota)
			u_help ("Nao ha nota fiscal gerada para esta carga.")
		else
			U_Log2 ('debug', '[' + procname () + ']Chamando IMPDANFE com: >>' + _oCarSaf:Contranota + '<< >>' + _oCarSaf:Contranota + '<< >>' + _oCarSaf:SerieCtrn + '<<')
			U_ImpDanfe ('E', _oCarSaf:Contranota, _oCarSaf:Contranota, _oCarSaf:SerieCtrn)
		endif

	case upper ('MonitorNFe') $ _sQueFazer
		// Variaveis usadas pelas rotinas da NFe
		private bFiltraBrw := {|| ".T."}
		private aFilBrw := {"SF2", ".T."}
		if upper (_sQueFazer) == upper ('MonitorNFe_1')
			SpedNFe1Mnt ()
		else
			SpedNFe2Mnt ()
		endif

	case _sQueFazer == upper ('ReenviarParaGrau')
		_oCarSaf:AtuZZA (.T.)

	case _sQueFazer == upper ('ConsultarCompartilhamento')
		U_ShowMemo (_oCarSaf:ConsCompar ())

	case _sQueFazer == upper ('EventoManual')
		_sEvtManu = U_ShowMemo (_sEvtManu, 'Descricao do evento ou comentario')
		if ! empty (_sEvtManu)
			_oCarSaf:GrvEvt ('SZE001', _sEvtManu)
		endif

	case _sQueFazer == upper ('SegregarCarga')
		if _oCarSaf:Segregada
			u_help ("Carga ja consta como segregada.")
		else
			if U_MsgNoYes ("Esta rotina permite alterar o status de uma carga para SEGREGADA. Deve ser usada com cautela, pois outros processos dependentes disso poderao ficar inconsistentes. Confirma assim mesmo?") 
				_sMotSeg = space (250)
				do while empty (_sMotSeg)
					_sMotSeg = U_Get ('Informe motivo de segregar carga sem ser pelo sistema de inspecoes', 'C', 250, '', '', _sMotSeg, .F., '.t.')
					if _sMotSeg == NIL  // Usuario cancelou com ESC
						u_help ("Carga nao vai ser segregada sem informar um motivo.",, .t.)
						exit
					endif
				enddo
				if _sMotSeg != NIL .and. ! empty (_sMotSeg)
					reclock ("SZE", .F.)
					sze -> ze_segreg = 'S'
					msunlock ()
					_oCarSaf:Segregada = .t.
					_oCarSaf:GrvEvt ("SZE009", "Segregando carga manualmente. Justificativa: " + _sMotSeg)
					if ! _oCarSaf:SegregarLt ()
						_oCarSaf:GrvEvt ("SZE009", "Nao foi possivel segregar o(s) lote(s) de estoque." + _oCarSaf:UltMsg)
						u_help ("Nao foi possivel segregar o(s) lote(s) de estoque. Notifique setor de producao! " + _oCarSaf:UltMsg,, .t.)
					endif
				endif
			endif
		endif

	case _sQueFazer == upper ('SimularFrete')
		U_VA_RusCF (.f.)

	otherwise
		u_help ("Acao desconhecida: " + cvaltochar (_sQueFazer),, .t.)
	endcase
return


// --------------------------------------------------------------------------
// Leitura da lista de associados habilitados
static function _LeAssoc ()
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _sCoop     := ""
	local _nPosCoop  := 0
	local _nPosAssoc := 0

	ProcRegua (10)
	incproc ("Buscando lista de associados...")
	
	sa2 -> (dbsetorder (1))
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery += "SELECT DISTINCT GX0001_GRUPO_CODIGO as grpfam"
	_oSQL:_sQuery +=      ", GX0001_ASSOCIADO_CODIGO as associado"
	_oSQL:_sQuery +=      ", GX0001_ASSOCIADO_LOJA as loja_assoc"
	_oSQL:_sQuery +=      ", GX0001_ASSOCIADO_NOME as nome_assoc"
	_oSQL:_sQuery +=      ", GX0001_ASSOCIADO_RESTRICAO as restricao"
	_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	do while ! (_sAliasQ) -> (eof ())
		incproc ()
		
		// Se for um grupo familiar que exista na lista de cooperativas, isso indica que li um associado de outra cooperativa.
		_nPosCoop = ascan (_aCoop, {|_aVal| _aVal [2] == (_sAliasQ) -> grpfam})
		if _nPosCoop > 0
			_sCoop = (_sAliasQ) -> grpfam + '01'
			
			// Varre lista de associados da cooperativa em questao ateh encontrar este associado.
			_nPosAssoc = ascan (&("_a" + _sCoop), {|_aVal| _aVal [5] == (_sAliasQ) -> associado .and. _aVal [6] == (_sAliasQ) -> loja_assoc})
			if _nPosAssoc > 0
				
				// Atualiza campo de restricoes.
				&("_a" + _sCoop) [_nPosAssoc, 7] = (_sAliasQ) -> restricao
			
			endif
		else
			if sa2 -> (dbseek (xfilial ("SA2") + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc, .F.))
				aadd (_a00002101, {(_sAliasQ) -> nome_assoc, sa2 -> a2_cgc, sa2 -> a2_mun, sa2 -> a2_end, sa2 -> a2_cod, sa2 -> a2_loja, (_sAliasQ) -> restricao})
			else
				u_log2 ('aviso', 'Nao encontrei SA2 com chave >>' + xfilial ("SA2") + (_sAliasQ) -> associado + (_sAliasQ) -> loja_assoc + '<<')
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function VA_RUSLG (_lRetCores)
	local _aTudo    := {}
	local _nTudo    := 0
	local _aCores   := {}
	local _aLegenda := {}
	
	// Monta array completa para depois gerar as demais.
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'N' .and. ze_status == '1'", 'BR_VERDE'   , 'Falta 2a. pesagem'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'N' .and. ze_status == '2'", 'BR_VERMELHO', 'Falta recibo ou NF'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'N' .and. ze_status == 'R'", 'BR_AZUL'    , 'Recibo impresso'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'N' .and. ze_status == 'N'", 'BR_BRANCO'  , 'Contranota gerada (normal)'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'N' .and. ze_status == 'D'", 'BR_MAGENTA' , 'Redirecionada para outra filial'})
	aadd (_aTudo, {" ze_status == 'C'"                                                 , 'BR_PRETO'   , 'Cancelada'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_status  == 'D'"                       , 'BR_MARRON'  , 'Redirecionada para outra filial'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'D' .and. ze_status == 'N'", 'BR_CINZA'   , 'Contranota gerada (aglutinadora)'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'D' .and. ze_status != 'N'", 'BR_LARANJA' , 'Aglutinadora'})
	aadd (_aTudo, {" empty (ze_nfdevol) .and. ze_aglutin == 'O'"                       , 'BR_AMARELO' , 'Aglutinada'})
	aadd (_aTudo, {"!empty (ze_nfdevol)"                                               , 'BR_CANCEL'  , 'Devolvida'})
	
	for _nTudo = 1 to len (_aTudo)
		aadd (_aCores,   {_aTudo [_nTudo, 1], _aTudo [_nTudo, 2]})
		aadd (_aLegenda, {_aTudo [_nTudo, 2], _aTudo [_nTudo, 3]})
	next
	
	if ! _lRetCores
		BrwLegenda (cCadastro, "Legenda", _aLegenda)
	else
		return _aCores
	endif
return


/* Em desuso. Robert, 06/01/2023
// --------------------------------------------------------------------------
// Redireciona a carga para outro local (filial).
user function VA_RUSRD ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	//local _sFilDest  := ''

	if _lContinua
		if sze -> ze_status $ '2/R/N/D/C'  // 1=Primeira pesagem OK;2=Segunda pesagem OK;R=Recibo impresso;N=NF gerada;D=Redirecionada;C=Cancelada
			u_help ("Status da carga nao permite mais ser redirecionada.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if U_MsgNoYes ("Confirma redirecionamento da carga para outra filial?")
			reclock ("SZE", .F.)
			sze -> ze_status = 'D'
			msunlock ()
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
*/


// --------------------------------------------------------------------------
// Rastreia lote no estoque.
user function VA_RUSRC ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _aLotes   := {}
	local _nLote    := 0
	local _sArq     := ""
	private _sRastUva := ""
	
	// Verifica o lote gerado pela nota de entrada.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT D1_COD, D1_DESCRI, D1_LOTECTL"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=   " AND D1_FILIAL   = '" + xfilial ("SD1")   + "'"
	_oSQL:_sQuery +=   " AND D1_DOC      = '" + sze -> ze_nfger   + "'"
	_oSQL:_sQuery +=   " AND D1_SERIE    = '" + sze -> ze_serie   + "'"
	_oSQL:_sQuery +=   " AND D1_FORNECE  = '" + sze -> ze_assoc   + "'"
	_oSQL:_sQuery +=   " AND D1_LOJA     = '" + sze -> ze_lojasso + "'"
	_oSQL:_sQuery +=   " AND D1_LOTECTL != ''"
	_oSQL:_sQuery += " ORDER BY D1_COD"
	_aLotes = aclone (_oSQL:Qry2Array ())
	if len (_aLotes) == 0
		u_help ("Nao ha lotes de estoque gerados por esta carga")
	else
		do while .t.
			_nLote = U_F3Array (_aLotes, 'Lotes gerados pela carga', NIL, NIL, NIL, 'Selecione o lote', '', .F., 'C')
			if _nLote == NIL .or. _nLote == 0
				exit
			endif
			processa ({|| _sRastUva = U_RastLT (sze -> ze_filial, _aLotes [_nLote, 1], _aLotes [_nLote, 3], 0, NIL, 1, 'A')})
			_sArq := 'c:\temp\rast_carga_' + _aLotes [_nLote, 3] + '.mm'
			delete file (_sArq)
			if file (_sArq)
				_nHdl = fopen(_sArq, 1)
			else
				_nHdl = fcreate(_sArq, 0)
			endif
			fwrite (_nHdl, _sRastUva)
			fclose (_nHdl)
			ShellExecute ("Open", _sArq, "", "", 1)
		enddo
	endif

	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Visualiza contranota.
user function VA_RUSVC ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt := U_SalvaAmb ()

	// Variaveis para a rotina de visualizacao da nota.
	Private aRotina    := {{ , , 0 , 2 }}
	Private l103Auto   := .F.
	Private aAutoCab   := {}
	Private aAutoItens := {}
	
	if empty (sze -> ze_nfger)
		u_help ("Contranota ainda nao gerada para esta carga.")
	else
		sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
		if ! sf1 -> (dbseek (xfilial ("SF1") + sze -> ze_nfger + sze -> ze_serie + sze -> ze_assoc + sze -> ze_lojasso, .F.))
			u_help ("Contranota nao encontrada!")
		else
			A103NFiscal("SF1",Recno(),1)
		endif
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                             Help
	aadd (_aRegsPerg, {01, "Balanca(AL/SP/NP/JC/QL...)    ", "C", 2,  0,  "",   "",      {},                                "Codigo da balanca onde voce esta trabalhando"})
	aadd (_aRegsPerg, {02, "Usa leitor de codigo de barras", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
	aadd (_aRegsPerg, {03, "Usa balanca eletronica        ", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
	aadd (_aRegsPerg, {04, "Porta comunicacao balanca     ", "C", 4,  0,  "",   "",      {},                                "COM1 / COM2 / ..."})
//	aadd (_aRegsPerg, {05, "Modelo balanca eletronica     ", "N", 1,  0,  "",   "",      {'Digitron', 'Toledo', 'Saturno'}, ""})
	aadd (_aRegsPerg, {05, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {06, "Multiplos Kg balanca          ", "N", 2,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {06, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {07, "Embalagem padrao              ", "N", 1,  0,  "",   "",      {'GRANEL', 'CAIXAS'},              ""})
	aadd (_aRegsPerg, {07, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {08, "Peso padrao embalagem (caixa) ", "N", 2,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {08, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {09, "Usa impressora de ticket      ", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
	aadd (_aRegsPerg, {09, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {10, "Impressora de ticket          ", "C", 2,  0,  "",   "ZX549", {},                                ""})
//	aadd (_aRegsPerg, {10, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {11, "Comunicacao c/ medidor de brix", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
//	aadd (_aRegsPerg, {12, "Qt. de vias ticket 1a.pesagem ", "N", 1,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {12, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {13, "Qt. de vias ticket 2a.pesagem ", "N", 1,  0,  "",   "",      {},                                ""})
	aadd (_aRegsPerg, {13, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {14, "Imprime ticket a cada pesagem ", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
	aadd (_aRegsPerg, {14, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})
//	aadd (_aRegsPerg, {15, "Integr. c/ controle portaria  ", "N", 1,  0,  "",   "",      {"Sim", "Nao"},                    ""})
	aadd (_aRegsPerg, {15, "PARAMETRO EM DESUSO           ", "N", 1,  0,  "",   "",      {},                                ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
