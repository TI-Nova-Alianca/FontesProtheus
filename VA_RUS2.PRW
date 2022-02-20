// Programa...: VA_RUS2
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Descricao..: Tela 2a pesagem recebimento de uva durante a safra (uso na balanca).
//
// Historico de alteracoes:
// 17/04/2010 - Robert - Criada possibilidade de copiar itens de outra carga (util para condominio).
// 06/01/2011 - Robert - Ajustes para safra 2011
// 16/02/2011 - Robert - Possibilidade de diferentes multiplos de peso cfe. local de entrega.
// 28/12/2011 - Robert - Melhorias gerais para safra 2012.
// 02/02/2012 - Robert - Liberada funcionalidade de aglutinacao de cargas.
// 20/01/2013 - Robert - Ajustes para safra 2013.
// 31/01/2013 - Robert - Alimenta ZF_PRM02 e ZF_PRM99 apos leitura do grau do refratometro.
// 31/01/2013 - Elaine - Trata entrega de caderno de campo para safra 2013
// 07/02/2013 - Robert - Nao lia cadastro viticola de Livramento na segunda pesagem.
// 27/02/2013 - Robert - Varifica se o associado tem data de falecimento.
// 11/01/2015 - Robert - Melhoradas validacoes para safra 2015.
// 04/02/2015 - Robert - Busca a data da carga na tela de selecao para aglutinacao.
// 25/01/2016 - Robert - Atualiza campo de coleta de amostra.
// 05/01/2017 - Robert - Ajustes para safra 2017.
// 18/01/2017 - Robert - Verifica campo ZZC_OK.
// 08/01/2017 - Robert - Ajustes para passar sem peso (1a. pesagem em separado)
//                     - Aglutinacao de cargas passa a validar codigo de propriedade e talhao.
// 09/01/2018 - Robert - Exclusao de cargas passa a ser tratada como 'cancelamento', apenas mudando o status da carga.
// 12/01/2018 - Robert - Passa a verificar na view VA_VAGENDA_SAFRA se precisa coletar amostra da uva.
// 16/01/2018 - Robert - Deixa de exigir peso estimado. Com a agenda de safra, jah tem-se a estimativa de peso.
// 19/01/2018 - Robert - Ajustes aglutinacao Livramento.
// 23/02/2018 - Robert - Passa a gravar o talhao na descricao do ZZA e nao mais a qt. de embalagens.
//    02/2019 - Robert - Melhorias gerais para safra 2019
// 05/02/2019 - Robert - Ajustes para receber uva de associados da Coop.Garibaldi.
// 01/03/2019 - Robert - Campo ZF_PRREAL nao pode ser igual ao ZF_PRODUTO
//                     - Ajustada validacao de mistura de variedades detectada nos tombadores.
// 13/12/2019 - Robert - Adequacoes iniciais para safra 2020 (inclusao de cargas via web service).
// 20/01/2020 - Robert - Novos parametros chamada geracao ticket safra.
// 01/12/2020 - Robert - Passa a buscar dados de cadastro viticola na view GX0001_AGENDA_SAFRA e nao mais na VA_VASSOC_CAD_VITIC2
// 05/02/2021 - Robert - Funcao de aglutinacao de cargas, removida ha uns 2 anos, foi reativada (GLPI 9336)
// 16/02/2022 - Robert - Tratamentos para cancelamento de cargas chamado via web service (GLPI 11634)
// 20/02/2022 - Robert - Variavel _sErros (publica do web service) renomeada para _sErroWS
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
User Function va_rus2 (_nOpc, _lFechPort)
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _oDlg        := NIL
	local _lContinua   := .T.
	local _oSQL        := NIL
	local _nLock       := 0
	local _nVitNC      := 0
	local _nLinha      := 0
	private _aRusInsp  := {}  // Deixar private para ser vista e alimentada por outras rotinas.
	private aHeader    := {}
	private aCols      := {}
	private N          := 1
	private agets      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private aTela      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private _oGetD     := NIL // Deixar private para poder executar refresh na abertura da tela.
	private _oEnch1    := NIL // Deixar private para poder executar refresh na abertura da tela.
	private inclui     := (_nOpc == 3)
	private altera     := (_nOpc == 4)
	private _lDlgOK    := .F.  // Para retorno da tela modelo3.
	private _ZFQTEMBAL := iif (_ZFEMBALAG == 'GRANEL', 1, 0)   // Deixar private para ser vista por outras rotinas.
	private _aCadVitic := {}  // Deixar private para ser vista por outras rotinas.
	private _aAglut    := {}  // Deixar private para ser vista por outras rotinas.
	private cArqMnu    := FWGetMnuFile()  //'COOPERATIVA.XNU'

	u_Log2 ('info', 'Iniciando ' + procname () + ' Carga: ' + sze -> ze_carga + '   inclui: ' + cvaltochar (inclui) + '   altera: ' + cvaltochar (altera) + '   _nOpc: ' + cvaltochar (_nOpc))

	if _lContinua .and. _nOpc >= 4 .and. sze -> ze_status == "N"
		u_help ("Nota fiscal (" + sze -> ze_nfger + ") ja gerada para esta carga. Alteracao / exclusao nao permitidas. Exclua, antes, a nota fiscal.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua .and. _nOpc != 2  .and. _nOpc != 3 .and. sze -> ze_status == "C"
		u_help ("Nenhuma manutencao pode ser feita nesta carga, pois encontra-se cancelada.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua .and. sze -> ze_status == "D" .and. _nOpc != 2
		u_help ("Carga redirecionada para outra filial.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua .and. _nOpc >= 4 .and. sze -> ze_status == "R"
		_lContinua = u_msgnoyes ("Recibo ja impresso para esta carga. Deseja continuar mesmo assim?")
	endif
	if _lContinua .and. altera .and. sze -> ze_aglutin $ "D/O"
		_lContinua = u_msgnoyes ("Cargas aglutinadas / aglutinadoras nao passam pela segunda pesagem.",, .t.)
	endif
	if _lContinua .and. _nOpc == 5 .and. sze -> ze_aglutin == "D"
		_lContinua = u_msgnoyes ("Esta carga foi gerada aglutinando outras. As cargas aglutinadas voltarao a ficar em aberto. Confirma?")
	endif
	if _lContinua .and. _nOpc == 5 .and. sze -> ze_aglutin == "O"
		u_help ("Esta carga foi aglutinada com outras e somente pode ser excluida/cancelada depois da carga aglutinadora. Consulte aglutinacoes para mais detalhes.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua .and. _nOpc == 4 .and. sze -> ze_local != _sBalanca
		u_help ("Carga gerada na balanca '" + sze -> ze_local + "'. Deve ser finalizada na mesma balanca.",, .t.)
		_lContinua = .F.
	endif
	if _lContinua .and. _nOpc == 4 .and. sze -> ze_pesobru == 0
		u_help ("Esta carga ainda nao contem o peso bruto. Execute a primeira pesagem.",, .t.)
		_lContinua = .F.
	endif

	// Nao permite duas sessoes alterando a mesma carga.
	if _lContinua .and. altera
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt + sze -> ze_safra + sze -> ze_carga, .T.)
		if _nLock == 0
			u_log ("Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif
	if _lContinua .and. _nOpc == 4 .and. _lLeBrix
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZA") + " ZZA "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND ZZA_FILIAL  = '" + xfilial ("ZZA") + "'"
		_oSQL:_sQuery +=   " AND ZZA_SAFRA   = '" + sze -> ze_safra + "'"
		_oSQL:_sQuery +=   " AND ZZA_CARGA   = '" + sze -> ze_carga + "'"
		_oSQL:_sQuery +=   " AND ZZA_STATUS != '3'"
		if _oSQL:RetQry () > 0
			_lContinua = U_msgnoyes ("Algum(s) item(s) desta carga ainda nao tem brix informado pelo leitor. Deseja continuar mesmo assim?")
		endif
		if _lContinua
			szf -> (dbsetorder (1))  // filial + safra + carga + item
			szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
			do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
				if val (szf -> zf_grau) == 0  // Para nao sobrepor se o usuario jah digitou algo manualmente
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery += "SELECT ZZA_GRAU"
					_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZA") + " ZZA "
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=   " AND ZZA_FILIAL = '" + xfilial ("ZZA") + "'"
					_oSQL:_sQuery +=   " AND ZZA_SAFRA  = '" + sze -> ze_safra + "'"
					_oSQL:_sQuery +=   " AND ZZA_CARGA  = '" + sze -> ze_carga + "'"
					_oSQL:_sQuery +=   " AND ZZA_PRODUT = '" + szf -> zf_item  + "'"
					_oSQL:_sQuery +=   " AND ZZA_STATUS = '3'"

					// Alimenta o campo de grau, formatando-o conforme parametrizacao padrao (pretendemos usar decimais no futuro).
					reclock ("SZF", .F.)
					szf -> zf_grau = _FmtGrau (_oSQL:RetQry ())
					msunlock ()
					U_LOG2 ('info', 'Gravei grau com ' + szf -> zf_grau)
				endif
				szf -> (dbskip ())
			enddo
		endif
	endif

	// Ao entrar na segunda pesagem, busca dados de inspecao no NaWeb
	if _lContinua .and. _nOpc == 4
		_lContinua = U_VA_RusLI (2)
	endif

	if _lContinua
		
		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("SZE", inclui, inclui)
		
		// Monta aHeader e eCols para a getdados.
		aHeader := aclone (U_GeraHead ("SZF", .F., {}, {}, .F.))
		if ! inclui
			aCols := aclone (U_GeraCols ("SZF", ;  // Alias
			                     1, ;  // Indice: filial + safra + carga + item
			                     xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, ;  // Seek inicial
			                     'xfilial ("SZF") + szf -> zf_safra + szf -> zf_carga == "' + xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga + '"', ;  // While
			                     aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
			                     .F.))  // Executa ou nao os gatilhos.

			// Preenche conteudo dos campos virtuais
			for _nLinha = 1 to len (aCols)
				GDFieldPut ("ZF_DESCRI",  fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO", _nLinha), "B1_DESC"), _nLinha)
				GDFieldPut ("ZF_DESCREA", fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRREAL", _nLinha),  "B1_DESC"), _nLinha)
			next
		else
			aCols := {}
			aadd (aCols, aclone (U_LinVazia (aHeader)))
	   endif
	endif

	// Instancia associado, quando possivel.
	if _lContinua .and. sze -> ze_coop $ '00136901/00002101'
		if inclui
			_oAssoc := ClsAssoc():New (m->ze_assoc, m->ze_lojasso, .F.)
		else
			_oAssoc := ClsAssoc():New (sze -> ze_assoc, sze -> ze_lojasso, .F.)
		endif
		if valtype (_oAssoc) != "O"
			u_help ("Nao consta como associado nem como ex-associado.",, .t.)
			_lContinua = .F.
		endif
	endif

	if type ('_oAssoc') == "O" .and. ! empty (_oAssoc:DtFalecim) .and. _nOpc != 5
		u_help ("Associado consta como falecido em " + dtoc (_oAssoc:DtFalecim),, .t.)
		_lContinua = .F.
	endif

	// Monta tabela com relacao de cadastros viticolas X produtos ligados ao associado.
	if _nOpc != 5
		if _lContinua
			if m->ze_coop $ '00136901/00002101'
				_aCadVitic := aclone (_oAssoc:CadVitic ())
				if len (_aCadVitic) == 0
//					if type ('_sErros') == 'C' ; _sErros += 'Nao ha nenhuma variedade de uva ligada ao associado ' ; endif
					u_help ("Nao ha nenhuma variedade de uva ligada ao associado '" + _oAssoc:Codigo + "/" + _oAssoc:Loja + "'." + chr (13) + chr (10) + ;
					        "Verifique:" + chr (13) + chr (10) + ;
					        "- Amarracao do associado/loja com grupos familiares" + chr (13) + chr (10) + ;
					        "- Cadastros viticolas" + chr (13) + chr (10) + ;
					        "- Propriedades rurais (equivale a cadastros viticolas) do grupo familiar" + chr (13) + chr (10) + ;
					        "- Amarracao de variedades de uvas com cadastros viticolas",, .t.)
					_lContinua = .F.
				endif
			
			// Para nao associados, nao tenho como buscar na classe ClsAssoc, entao gero uma array equivalente.
			else
				_aCadVitic = aclone (U_VA_RusCV (m->ze_assoc, m->ze_lojasso))
			endif
		endif
		if _lContinua
			_nVitNC = ascan (_aCadVitic, {|_aVal| empty (_aVal [.CadVitRecebFisico])})
			if _nVitNC > 0
				u_help ("O cadastro viticola '" + _aCadVitic [_nVitNC, .CadVitCodigo] + "' (grupo familiar " + alltrim (_aCadVitic [_nVitNC, .CadVitNomeGrpFam]) + ") consta como nao recebido fisicamente. Solicite ao associado que traga uma copia do mesmo.")
			endif
		endif
	endif
	
	if _lContinua

		// Posso estar fazendo uma exclusao/cancelamento de carga chamada a partir do web service, entao nao posso abrir tela.
		if _nOpc == 5 .and. IsInCallStack ("_CanCarSaf")
			U_Log2 ('debug', '[' + procname () + ']Cancelando carga a partir do WS')
			_lDlgOK := .T.  // Simula 'botao OK'
		else
			// Monta tela para o usuario fazer as manutencoes
			N = 1
			define msDialog _oDlg from 0,0 to oMainWnd:nClientHeight - 50 , oMainWnd:nClientwidth - 4 of oMainWnd pixel title cCadastro
			
			// Enchoice para visualizacao do arquivo.
			_oEnch1 := MsMGet():New("SZE", ;  // Alias
			1, ;      // nReg
			_nOpc, ;  // Opcao do aRotina
			NIL, ;
			NIL, ;
			NIL, ;
			NIL, ;    // Array com nomes de campos a exibir (pra mim nao funcionou)
			{30, 2, _oDlg:nClientHeight / 3.5 - 5, _oDlg:nClientWidth / 2 - 10}, ;  // Posicionamento na tela  //{15, 2, _oDlg:nClientHeight / 3.5 - 5, _oDlg:nClientWidth / 2 - 10}, ;  // Posicionamento na tela
			NIL, ;    // Array com nomes de campos editaveis (pra mim trancou todos)
			NIL, ;    // 3
			NIL, ;
			NIL, ;
			NIL, ;    // "A415VldTOk"
			_oDlg, ;  // Dialogo onde vai ser criada
			NIL, ;    // logico
			NIL, ;    // lMemory
			.F., ;    // .T. = todos os campos em uma unica coluna
			NIL, ;    // "aSvATela"
			.T., ;
			NIL)      // lProperty
			
			// Itens
			_oGetD := MSGetDados ():New (_oDlg:nClientHeight / 3.5 + 15, ;       // Limite superior
										2, ;                                 // Limite esquerdo
										_oDlg:nClientHeight / 2 - 45, ;      // Limite inferior
										_oDlg:nClientWidth / 2 - 10, ;       // Limite direito
										_nOpc, ;                             // opcao do mbrowse (aRotina)
										"U_VA_RUS2L ()", ;                   // Linha ok
										"allwaystrue ()", ;                  // Tudo ok
										, ;                                  // Campos com incremento automatico
										inclui .or. altera, ;                // Permite deletar linhas
										, ;                                  // Vetor de campos que podem ser alterados
										, ;                                  // Reservado
										.F., ;                               // Se .T., a primeira coluna nunca pode ficar vazia
										999, ;                               // Maximo de linhas permitido
										"allwaystrue ()", ;                  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
										"allwaystrue ()", ;                  // Executada ao teclar CTRL + DEL
										, ;                                  // Reservado
										"allwaystrue ()", ;                  // Executada para validar delecao de uma linha
										_oDlg)                               // Objeto onde serah criada
			
			// Define botoes da barra de ferramentas.
			_bBotaoOK  = {|| iif (U_VA_RUS2T (_nOpc), (_lDlgOK := .T., _oDlg:End ()), NIL)}
			_bBotaoCan = {|| _oDlg:End ()}
			_aBotAdic  = {}
			if ! inclui
				aadd (_aBotAdic, {"S4WB005N", {|| _CopyCarga ()}, "Copiar"})
				if _lIntPort
					aadd (_aBotAdic, {"S4WB005N", {|| _LePortar ()}, "Portaria"})
				endif
			endif
			if inclui
				aadd (_aBotAdic, {"S4WB005N", {|| U_VA_RusAG ()}, "Aglutinar"})
			endif
			if (inclui .or. altera) .and. _lBalEletr
				SetKey(VK_F8, {|| _LePeso ()})
				aadd (_aBotAdic, {"BALANCA", {|| _LePeso ()}, "[F8] Peso"})
			endif
			if _lFechPort
				activate dialog _oDlg on init (EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic), _LePortar (), _oEnch1:Refresh (), _oGetD:Refresh ())
			else
				activate dialog _oDlg on init EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic)
			endif
		endif
	endif

	// Tratamento caso o usuario tenha confirmado a tela modelo3.
	if _lContinua .and. _lDlgOK
		U_VA_RUS2G (_nOpc, _nLock)
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	set key 119 to
return



// --------------------------------------------------------------------------
// Importa pesos da rotina de portaria.
static function _LePortar ()
	u_Log2 ('info', 'Iniciando ' + procname ())
	zzt -> (dbsetorder (2))  // ZZT_FILIAL+ZZT_SAFRA+ZZT_CARGA
	if ! zzt -> (dbseek (xfilial ("ZZT") + m->ze_safra + m->ze_carga, .F.))
		u_help ("Nao encontrei nenhum ticket de portaria referente a esta carga.")
	else
		if zzt -> zzt_pessai <= 0
			u_help ("Peso de saida invalido no ticket de portaria '" + zzt -> zzt_cod + "'. Verifique se a saida desse ticket ja foi realizada.")
		else
			m->ze_pesotar = zzt -> zzt_pessai

			// Chama primeira pesagem de safra para atualizacoes adicionais
			U_Log2 ('debug', 'Chamando VA_Rus1P de dentro do ' + procname ())
			U_VA_RUS1P (.T.)

			// Distribui peso entre as caixas dos itens. Existe chamada semelhante nos gatilhos dos campos de peso.
			U_VA_RUS2D ()
		endif
	endif
return



// --------------------------------------------------------------------------
// Recebe o grau como numerico e retorna formatado em caracter.
static function _FmtGrau (_nGrau)
	local _nInt  := 0
	local _nDec  := 0
	local _sInt  := ""
	local _sDec  := ""
	local _sGrau := ""
	local _aFmtGrau    := {2, 1}  // Formatacao para grau: {qt.digitos inteiros, qt.decimais}
	
	_nGrau = round (_nGrau, _aFmtGrau [2])  // Arredonda decimais
	_nInt = int (_nGrau)
	_sInt = strzero (_nInt, _aFmtGrau [1])
	if _aFmtGrau [2] > 0
		_nDec = (_nGrau - _nInt) * 10 * _aFmtGrau [2]
		_sDec = strzero (_nDec, _aFmtGrau [2])
	else
		_sDec = '0'
	endif
	_sGrau = _sInt + '.' + _sDec
return _sGrau



// --------------------------------------------------------------------------
// Le peso da balanca eletronica.
static function _LePeso ()
	private _nPLidoBal := 0

	if _lBalEletr
		MsgRun ("Aguarde, lendo dados da balanca", "Leitura balanca", {|| _nPLidoBal := U_LeBalan (_sPortaBal, _sModelBal)})
	
		// Faz arredondamento cfe. parametrizacao do usuario.
		_nPLidoBal = round (_nPLidoBal / _nMultBal, 0)
		_nPLidoBal *= _nMultBal
	
		if _lImpTick .and. _lTickPeso
			U_VA_RUSTk (3, _sPortTick, 1, {}, 'Bematech', .t.)
		endif

		if inclui  // Primeira pesagem: leitura do peso bruto
			m->ze_pesoBru = _nPLidoBal
			m->ze_PBruBal = m->ze_pesoBru  // Guarda um backup do peso fornecido pela balanca.
		elseif altera
			m->ze_pesoTar = _nPLidoBal
			m->ze_PTarBal = m->ze_pesoTar  // Guarda um backup do peso fornecido pela balanca.
		endif
		
		// Distribui peso entre as caixas dos itens. Existe chamada semenhante nos gatilhos dos campos de peso.
		U_VA_RUS2D ()
	else
		u_help ("Estacao sem comunicacao com balanca. Verifique seus parametros.",, .t.)
	endif
return



// --------------------------------------------------------------------------
// Copia os produtos de outra carga.
static function _CopyCarga ()
	local _nLinha    := 0
	local _aAreaAnt  := U_ML_SRArea ()
	local _sCargaOri := space (tamsx3 ("ZE_CARGA")[1])

	_sCargaOri = U_Get ("Informe carga original para copiar os produtos", "C", len (_sCargaOri), "", "", _sCargaOri, .F., ".T.")
	if empty (_sCargaOri)
		u_help ("Copia cancelada.")
	else
		szf -> (dbsetorder (1))
		if ! szf -> (dbseek (xfilial ("SZF") + m->ze_safra + _sCargaOri, .T.))
			u_help ("Carga nao encontrada ou sem segunda pesagem.")
		else
			aCols := aclone (U_GeraCols ("SZF", ;  // Alias
			                             1, ;  // Indice: filial + safra + carga + item
			                             xfilial ("SZF") + m->ze_safra + _sCargaOri, ;  // Seek inicial
			                             'xfilial ("SZF") + szf -> zf_safra + szf -> zf_carga == "' + xfilial ("SZF") + sze -> ze_safra + _sCargaOri + '"', ;  // While
			                             aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
			                             .F.))  // Executa ou nao os gatilhos.
	
			// Preenche conteudo dos campos virtuais
			for _nLinha = 1 to len (aCols)
				GDFieldPut ("ZF_DESCRI",  fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO", _nLinha), "B1_DESC"), _nLinha)
				GDFieldPut ("ZF_DESCREA", fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRREAL", _nLinha),  "B1_DESC"), _nLinha)
			next
	
			if len (aCols) == 0
				aCols := {}
				aadd (aCols, aclone (U_LinVazia (aHeader)))
			endif
	
			// Atualiza tela do usuario
			N = 1
			_oGetD:oBrowse:Refresh ()
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
// Distribui os pesos entre os diversos itens conforme a quantidade das embalagens
// Cuidado ao alterar, pois esta funcao tambem eh chamada por gatilhos.
user function VA_RUS2D ()
	local _xRet      := &(ReadVar ())  // Retorna sempre o proprio campo lido.
	local _nLinha    := 0
	local _oAUtil    := NIL
	
	if altera  // Soh distribui pesos na segunda pesagem.
		_oAUtil    := ClsAUtil():New (aCols)

		// Calcula o peso de cada linha por regra de 3, mantendo os valores sempre em
		// multiplos, conforme o menor peso acusado pela balanca.
		_oAUtil := ClsAUtil():New (aCols)
		_oAUtil:Dist3 (GDFieldPos ("ZF_QTEMBAL"), GDFieldPos ("ZF_PESO"), (m->ze_pesobru - m->ze_pesotar) / _nMultBal, 0)
		aCols := aclone (_oAUtil:_aArray)
		for _nLinha = 1 to len (aCols)
			GDFieldPut ("ZF_PESO", GDFieldGet ("ZF_PESO", _nLinha) * _nMultBal, _nLinha)
		next
	
		// Atualiza tela do usuario
		_oGetD:oBrowse:Refresh ()
	endif

return _xRet
