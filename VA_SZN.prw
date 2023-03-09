// Programa...: VA_SZN
// Autor......: Robert Koch
// Data.......: 19/06/2008
// Descricao..: Gravacao de log de eventos (customizados) do sistema

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Tela de gravacao / consulta de logs customizados do Protheus.
// #PalavasChave      #auxiliar #logs_eventos #dedo-duro
// #TabelasPrincipais #SZN
// #Modulos           #

// Historico de alteracoes:
// 10/07/2008 - Robert - Gravacao de pedido de venda, cliente e fornecedor.
//                     - Passa a receber um objeto com os dados do evento.
// 02/08/2008 - Robert - Permite inclusao manual de eventos.
// 01/09/2008 - Robert - Criada visualizacao de eventos de pedidos de venda.
// 05/09/2008 - Robert - Criada visualizacao de eventos de NF de entrada e saida.
//                     - Tela de visualizacao de enventos passa a ter texto na parte inferior.
// 15/09/2008 - Robert - Criado tratamento para campo memo na inclusao manual e na exclusao.
// 20/01/2009 - Robert - Compatibilizacao com DBF.
// 05/05/2010 - Robert - Incluidas, na consulta de NF de saida, mensagens da ordem de embarque e data real de entrega.
// 13/10/2011 - Robert - Passa a usar a funcao VA_ZZ4L para leitura do ZZ4.
// 03/08/2014 - Robert - Melhoria funcao VA_SZNI para atender chamadas externas.
// 17/10/2015 - Robert - Criado tratamento para consulta de eventos de OP.
// 22/05/2019 - Robert - Reativada opcao de exclusao, somente para usuario administrador/robert
// 11/08/2019 - Robert - Removido tratamento para campo memo (migrado de SYP para formato real).
// 19/11/2019 - Robert - Implementada leitura de eventos de cadastros viticolas.
// 20/04/2021 - Robert - Campo F2_DtEntr (padrao, mas atualmente vazio) substitui o campo customizado F2_vaDtEntr (GLPI 9884).
//                     - Incluidas tags para catalogo de fontes.
// 11/03/2022 - Robert - Consulta de logs de 'CARGASAFRA' passa a validar novos campos ZN_SAFRA e ZN_CARGSAF.
// 09/03/2023 - Robert - Criada opcao de consulta por ChaveNFe
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Consulta de eventos a partir do menu.
user function VA_SZNM ()
	Private aRotina   := aclone (_MenuDef ())
	private cCadastro := "Eventos"
	Private cDelFunc := "alltrim(upper(cUserName))$'ADMINISTRADOR'"
	Private cString  := "SZN"
	dbSelectArea("SZN")
	dbSetOrder(1)
	mBrowse( 6,1,22,75,cString)
return



// --------------------------------------------------------------------------
// Monta menu de rotinas em funcao separada, pois existem casos de chamadas
// externas para a inclusao de eventos, e o menu deve ser refeito.
static function _MenuDef ()
	local _aRotina := {}
	aadd (_aRotina, {"Pesquisar",  "AxPesqui",    0, 1})
	aadd (_aRotina, {"Visualizar", "AxVisual",    0, 2})
	aadd (_aRotina, {"Incluir",    "U_VA_SZNI ()",0, 3})
	if alltrim(upper(cUserName))$'ADMINISTRADOR/ROBERT.KOCH'
		aadd (_aRotina, {"Excluir",    "U_VA_SZNE ()",0, 5})
	endif
return _aRotina



// --------------------------------------------------------------------------
// Exclusao manual de eventos.
user function VA_SZNE ()
	local _oEvento := NIL

	if U_MsgNoYes ("Confirma exclusao deste evento?")
		_oEvento := ClsEvent ():New (szn -> (recno ()))
		_oEvento:Exclui ()
	endif
return



// --------------------------------------------------------------------------
// Inclusao manual de eventos. Pode receber array de campos jah preenchidos.
user function VA_SZNI (_aCpos)
//	local _nCampo    := 0
//	local _aCpoUsad  := {}
	local _aRotina   := iif (type ("aRotina") == "A", aclone (aRotina), {})
	private _aCampos := iif (valtype (_aCpos) == "A", aclone (_aCpos), {})

	// Refaz menu para uso nesta rotina.
	aRotina = aclone (_MenuDef ())

//	// Se recebeu array de campos, mostra apenas esses.
//	if valtype (_aCpos) == "A"
//		for _nCampo = 1 to len (_aCampos)
//			aadd (_aCpoUsad, _aCampos [_nCampo, 1])
//		next
//	else
//		_aCpoUsad = niL
//	endif

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	RegToMemory ("SZN", .t., .t.)

	if axinclui ("SZN", ;  // Tabela
	             szn -> (recno ()), ;  // Recno
	             3, ;  // Opcao do menu
	             NIL, ;  // Array de campos a serem tratados
	             "U_VA_SZNIL()", ;  // Funcao a ser executada ANTES de entrar na enchoice
	             NIL, ;  // Campos que devem ser aceitos
	             "allwaystrue()", ;  // Tudo OK
	             NIL, ;
	             NIL, ;
	             {}) == 1  // Botoes adicionais
	endif

	aRotina := aclone (_aRotina)
return



// --------------------------------------------------------------------------
// Funcao a ser executada ANTES de abrir a enchoice de inclusao, usada para
// inicializar os campos de memoria.
user function VA_SZNIL ()
	local _nCampo    := 0

	// Se recebeu array com dados, preenche os campos.
	for _nCampo = 1 to len (_aCampos)
		M->&(_aCampos [_nCampo, 1]) := _aCampos [_nCampo, 2]
	next

return .T.



// --------------------------------------------------------------------------
// Consulta de eventos a partir de outros programas.
user function VA_SZNC (_sOQue, _sChave1, _sChave2, _sChave3, _sChave4, _sChave5)
	processa ({|| _LeDados (_sOQue, _sChave1, _sChave2, _sChave3, _sChave4, _sChave5)})
return



// --------------------------------------------------------------------------
// Consulta de eventos a partir de outros programas.
static function _LeDados (_sOQue, _sChave1, _sChave2, _sChave3, _sChave4, _sChave5)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _oDlg      := NIL
	local _nCampo    := 0
	local _sQuery    := ""
	local _aLinVazia := {}
	local _lContinua := .T.
	local _sOrdEmb   := ""
	local _sMsgInf   := ""
	local _aSize     := {}  // Para posicionamento de objetos em tela
	local _aRecnos   := {}
	local _nRecno    := 0
	private aRotina  := {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
	{"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
	{"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
	{"BlaBlaBla", "allwaystrue ()", 0, 4}}  // aRotina eh exigido pela MSGetDados!!!

	// Monta query conforme parametros recebidos
	if _lContinua
		_sQuery := ""
		_sQuery += " select R_E_C_N_O_ "
		_sQuery += " from " + RetSQLName ("SZN")
		_sQuery += " where D_E_L_E_T_ !=      '*'"
		_sQuery += "   and ZN_FILIAL  =       '" + xfilial ("SZN")  + "'"
		do case
		case upper (_sOQue) == "PEDVENDA"
			_sQuery += "   and ZN_PEDVEND = '" + _sChave1 + "'"
		case upper (_sOQue) == "NFSAIDA"
			_sQuery += "   and ZN_NFS     = '" + _sChave1 + "'"
			_sQuery += "   and ZN_SERIES  = '" + _sChave2 + "'"
		case upper (_sOQue) == "NFENTRADA"
			_sQuery += "   and ZN_NFE     = '" + _sChave1 + "'"
			_sQuery += "   and ZN_SERIEE  = '" + _sChave2 + "'"
			_sQuery += "   and ZN_FORNECE = '" + _sChave3 + "'"
			_sQuery += "   and ZN_LOJAFOR = '" + _sChave4 + "'"
		case upper (_sOQue) == "OP"
			_sQuery += "   and ZN_OP      = '" + _sChave5 + "'"
		case upper (_sOQue) == "CADASTROVITICOLA"
			_sQuery += "   and ZN_ALIAS   = 'SZ2'"
			_sQuery += "   and ZN_COD     = '" + _sChave1 + "'"
		case upper (_sOQue) == "CARGASAFRA"
			_sQuery += "   and ZN_SAFRA   = '" + _sChave1 + "'"
			_sQuery += "   and ZN_CARGSAF = '" + _sChave2 + "'"
		case upper (_sOQue) == "ALIAS_CHAVE"
			_sQuery += "   and ZN_ALIAS   = '" + _sChave1 + "'"
			_sQuery += "   and ZN_CHAVE   = '" + _sChave2 + "'"
		case upper (_sOQue) == "EVENTO"
			_sQuery += "   and ZN_CODEVEN = '" + _sChave1 + "'"
		case upper (_sOQue) == "CHAVENFE"
			_sQuery += "   and ZN_CHVNFE = '" + _sChave1 + "'"
		otherwise
			u_help ("Consulta desconhecida no programa " + procname (),, .t.)
			_lContinua = .F.
		endcase
			U_Log2 ('debug', '[' + procname () + ']' +_sQuery)
			_aRecnos := aclone (U_Qry2Array (_sQuery))
	endif
	
	// Busca dados adicionais para a parte inferior da tela.
	if _lContinua
		do case
		case upper (_sOQue) == "NFSAIDA"

			// Busca embarque(s) da nota
			sf2 -> (dbsetorder (1))
			if sf2 -> (dbseek (xfilial ("SF2") + _sChave1 + _sChave2, .F.))
				_sOrdEmb = sf2 -> F2_ORDEMB
				if ! empty (_sOrdEmb)
					szo -> (dbsetorder (1))  // ZO_FILIAL+ZO_NUMERO
					if szo -> (dbseek (xfilial ("SZO") + _sOrdEmb, .F.))
						_sMsgInf += "Ordem de embarque '" + _sOrdEmb + "' emitida por " + alltrim (szo -> zo_usuario) + " em " + dtoc (szo -> zo_emissao) + " - transp. " + alltrim (szo -> zo_transp) + " (" + alltrim (fBuscaCpo ("SA4", 1, xfilial ("SF4") + szo -> zo_transp, "A4_NOME")) + ")" + chr (13) + chr (10)
						_sMsgInf += "Embarque feito por " + alltrim (szo -> zo_respemb) + " em " + dtoc (szo -> zo_dataemb) + " - Placa veiculo: " + alltrim (szo -> zo_placa) + " - Motorista: " + alltrim (szo -> zo_motoris) + chr (13) + chr (10)
					endif
				endif
			
				// Busca data real de entrega (informada pela transportadora)
				// if ! empty (sf2 -> f2_vaDtEnt)
				if ! empty (sf2 -> f2_DtEntr)
					// _sMsgInf += "Entrega ao cliente realizada em " + dtoc (sf2 -> f2_vaDtEnt) + chr (13) + chr (10)
					_sMsgInf += "Entrega ao cliente realizada em " + dtoc (sf2 -> f2_DtEntr) + chr (13) + chr (10)
				endif
			endif
		endcase
	endif

	if len (_aRecnos) == 0 .and. empty (_sMsgInf)
		u_help ("Nao ha' eventos ou dados adicionais a mostrar.")
		_lContinua = .F.
	endif
	
	if _lContinua
		aHeader := aclone (U_GeraHead ("SZN"))
		aCols := {}
		_aLinVazia := aclone (U_LinVazia (aHeader))
		for _nRecno = 1 to len (_aRecnos)
			AADD (aCols, aclone (_aLinVazia))
			N = len (aCols)
			szn -> (dbgoto (_aRecnos [_nRecno, 1]))
			for _nCampo = 1 to len (aHeader)
				if szn -> (FieldPos (aHeader [_nCampo, 2])) > 0  // Campo real. Nao testar pelo SX3 por que as vezes estah em branco!
					GDFieldPut (aHeader [_nCampo, 2], szn -> &(aHeader [_nCampo, 2]))
				else  // Campo virtual
					GDFieldPut (aHeader [_nCampo, 2], CriaVar (aHeader [_nCampo, 2]))
				endif
			Next
		next

		N := 1
		_aSize := MsAdvSize()
		define MSDialog _oDlg from 0,0 to _aSize [6], _aSize [5] of oMainWnd pixel title "Consulta de eventos / dados adicionais"
		
			// Botao OK para fechar o dialogo. Definido antes para que o 'foco' caia nele.
			@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 45  bmpbutton type 1 action _oDlg:End ()

			// Getdados para os eventos
			_oMulti := MSGETDADOS ():New (15, ;  // Limite superior
			15, ;                             // Limite esquerdo
			_oDlg:nClientHeight / 4 - 10, ;  // Limite inferior
			_oDlg:nClientWidth / 2 - 15, ;    // Limite direito
			4, ;                             // opcao do mbrowse, caso tivesse (alterar)
			"allwaystrue ()", ;              // Linha ok
			"allwaystrue ()", ;              // Tudo ok
			, ;                              // Campos com incremento automatico
			.F., ;                           // Permite deletar linhas
			, ;                              // Vetor de campos que podem ser alterados
			, ;                              // Reservado
			.F., ;                           // Se .T., a primeira coluna nunca pode ficar vazia
			len (aCols), ;                   // Maximo de linhas permitido
			"allwaystrue ()", ;              // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
			"AllwaysTrue ()", ;              // Funcao executada quando pressionadas as teclas <Ctrl>+<Delete>.
			, ;                              // Reservado
			"allwaystrue ()", ;              // Funcao executada para validar a exclusao ou reinclusao de uma linha do aCols.
			_oDlg)                           // Objeto no qual a MsGetDados serah criada.

			// Memo para informacoes em texto
			@ _oDlg:nClientHeight / 4, 15 get _sMsgInf MEMO size (_oDlg:nClientWidth / 2 - 30), (_oDlg:nClientHeight / 4 - 50) when .T. object _oGetMemo // Se colocar when .F., nao tem barra de rolagem
			_oGetMemo:oFont := TFont():New ("Courier New", 7, 16)
		activate msdialog _oDlg centered
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return
