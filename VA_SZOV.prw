// Programa:  VA_SZOV
// Autor:     Robert Koch
// Data:      16/07/2008
// Cliente:   Alianca
// Descricao: Tela para visualizacao e exclusao de ordens de embarque.
//
// Historico de alteracoes:
// 23/04/2010 - Robert  - Criada rotina de confirmacao de embarque.
// 17/06/2010 - Robert  - Gera pendencias no AD5 apos confirmacao do embarque.
// 23/06/2010 - Robert  - Gravacao do campo AD5_VAPRAZ.
// 25/06/2010 - Robert  - Gravacao da NF e serie no arquivo AD5.
// 09/07/2010 - Robert  - Criado tratamento para campo A4_vaPosV.
// 04/08/2010 - Robert  - Adicionado Clovis como operador de empilhadeira.
// 15/04/2011 - Fabiano - Adicionado o Jeferson como operador e removido Clovis e Alexandre
// 14/09/2012 - Fabiano - Adicionado o "robson.rodrigues" como operador de empilhadeira
// 21/02/2013 - Elaine  - Passa a mostrar informações do fornecedor (município, estado, etc) quando nota for tipo B ou D (Beneficiamentou ou Devolucao)
// 26/02/2013 - Elaine  - Passa a tratar no parâmetro VA_USREMPI os usuários que sao operadores de empilhadeira
// 15/01/2014 - Leandro - grava evento para histórico de NF
// 21/07/2020 - Robert  - Desabilitada opcao 'confirmar embarque' pois nao eh mais usada.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Manutencao de ordens de embarque expedicao
// #PalavasChave      #ordens_embarque
// #TabelasPrincipais #ZZO
// #Modulos           #FAT
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function VA_SZOV (_lExclui, _lConfEmb)
	local _bBotaoOK    := {|| NIL}
	local _bBotaoCan   := {|| NIL}
	local _aBotAdic    := {}
	local _sQuery      := ""
	local _sAliasQ     := ""
	local _oDlg        := NIL
	local _aAreaAnt    := U_ML_SRArea ()
	local _aAmbAnt     := U_SalvaAmb ()
	//local _sSQL        := ""
	local _lContinua   := .T.
    local _sNome       := ""
    local _sMun        := ""
    local _sUF         := ""
	private aHeader    := {}
	private aCols      := {}
	private agets      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private aTela      := {}  // Alimentada pelas rotinas do sistema e necessaria para validacoes de campos obrigatorios.
	private _oGetD     := NIL
	private inclui     := .F.
	private altera     := .F.
	
/* Confirmacao de embarque desabilitada em 21/07/2020.
	// Verificacoes ref. confirmacao de embarques
	if _lContinua .and. _lConfEmb

	  	if _lContinua .and. ! upper (alltrim (cUserName)) $ GETMV("VA_USREMPI")
			msgalert ("Usuario nao e' operador de empilhadeira. Se for, ajuste o parametro VA_USREMPI.")
	 		_lContinua = .F.
	  	endif
	 	if _lContinua .and. ! empty (szo->ZO_RESPEMB)
	 		msgalert ("Carga ja embarcada por " + szo->ZO_RESPEMB)
	 		_lContinua = .F.
	 	endif
	endif
*/	
	if _lContinua
		
		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("SZO", inclui, inclui)
//		if _lConfEmb
//			M->ZO_RESPEMB = cUserName
//			M->ZO_DATAEMB = date ()
//		endif
		
		// Monta aHeader e eCols para a getdados.
		aHeader := aclone (U_GeraHead ("", .F., {}, {"F2_TRANSP", "A4_NOME", "F2_DOC", "F2_SERIE", "F2_EMISSAO", "F2_CLIENTE", "F2_LOJA", "A1_NOME", "A1_EST", "A1_MUN"}, .T.))
		
		// Busca as notas que fazem parte deste embarque.
		CursorWait ()
		_sQuery := ""
		_sQuery += " Select F2_EMISSAO, F2_TRANSP, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_TIPO, A1_NOME, A4_NOME, A1_EST, A1_MUN"
		_sQuery += "   From " + RetSQLName ("SF2") + " SF2, "
		_sQuery +=              RetSQLName ("SA1") + " SA1, "
		_sQuery +=              RetSQLName ("SA4") + " SA4  "
		_sQuery += "  Where SF2.D_E_L_E_T_ = ''"
		_sQuery += "    And SA1.D_E_L_E_T_ = ''"
		_sQuery += "    And SA4.D_E_L_E_T_ = ''"
		_sQuery += "    And F2_FILIAL  = '" + xfilial ("SF2") + "'"
		_sQuery += "    And A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sQuery += "    And A4_FILIAL  = '" + xfilial ("SA4") + "'"
		_sQuery += "    And A4_COD     = F2_TRANSP"
		_sQuery += "    And A1_COD     = F2_CLIENTE"
		_sQuery += "    And A1_LOJA    = F2_LOJA"
		_sQuery += "    And F2_ORDEMB  = '" + szo -> zo_numero + "'"
		_sQuery += "  Order by F2_TRANSP, F2_EST, F2_CLIENTE, F2_DOC"
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		TCSetField (_sAliasQ, "F2_EMISSAO", "D")
		aCols = {}
		Do While ! (_sAliasQ) -> (Eof())
			aadd (aCols, aclone (U_LinVazia (aHeader)))
			N = len (aCols) 
            if (_sAliasQ) -> F2_TIPO $ "D/B"  // Caso for Devolucao ou Beneficiamento, busca informacoes do fornecedor, caso contrario, do cliente
               _sNome := fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA2->A2_NOME")
               _sMun  := fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA2->A2_MUN")
               _sUF   := fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA2->A2_EST")
            else
 	           _sNome := fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA1->A1_NOME")
 	           _sMun  := fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA1->A1_MUN")
 	           _sUF   := fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA1->A1_EST")
            endif
 			
			GDFieldPut ("F2_TRANSP",  (_sAliasQ) -> f2_transp)
			GDFieldPut ("A4_NOME",    (_sAliasQ) -> a4_nome)
			GDFieldPut ("F2_DOC",     (_sAliasQ) -> f2_doc)
			GDFieldPut ("F2_SERIE",   (_sAliasQ) -> f2_serie)
			GDFieldPut ("F2_EMISSAO", (_sAliasQ) -> f2_emissao)
			GDFieldPut ("F2_CLIENTE", (_sAliasQ) -> f2_cliente)
			GDFieldPut ("F2_LOJA",    (_sAliasQ) -> f2_loja)
			GDFieldPut ("A1_NOME",    _sNome)
			GDFieldPut ("A1_EST",     _sMun)
			GDFieldPut ("A1_MUN",     _sUF)
			(_sAliasQ) -> (dbskip())
		enddo
		(_sAliasQ) -> (dbclosearea ())
		CursorArrow ()
		dbselectarea ("SZO")
	endif
	
	if _lContinua
		
		// Monta tela para o usuario fazer as manutencoes
		N = 1
		define msDialog _oDlg from 0,0 to oMainWnd:nClientHeight - 50 , oMainWnd:nClientwidth - 4 of oMainWnd pixel title cCadastro
		
		// Enchoice para visualizacao do arquivo.
		_oEnch1 := MsMGet():New("SZO", ;  // Alias
		szo -> (recno ()), ;      // nReg
		iif (_lConfEmb, 3, 2), ;  // Opcao do aRotina
		NIL, ;
		NIL, ;
		NIL, ;
		NIL, ;    // Array com nomes de campos a exibir (pra mim nao funcionou)
		{15, 2, _oDlg:nClientHeight / 7 - 2, _oDlg:nClientWidth / 2 - 10}, ;  // Posicionamento na tela
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
		
		_oGetD := MSGetDados ():New (_oDlg:nClientHeight / 7 + 2, ;                               // Limite superior
		2, ;                                 // Limite esquerdo
		_oDlg:nClientHeight / 2 - 45, ;      // Limite inferior
		_oDlg:nClientWidth / 2 - 10, ;       // Limite direito
		2, ;                             // opcao do mbrowse (aRotina)
		"allwaystrue ()", ;                  // Linha ok
		"allwaystrue ()", ;                  // Tudo ok
		, ;                                  // Campos com incremento automatico
		.F., ;                               // Permite deletar linhas
		, ;                                  // Vetor de campos que podem ser alterados
		, ;                                  // Reservado
		.F., ;                               // Se .T., a primeira coluna nunca pode ficar vazia
		len (aCols), ;                       // Maximo de linhas permitido
		"allwaystrue ()", ;                  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
		"allwaystrue ()", ;                  // Executada ao teclar CTRL + DEL
		, ;                                  // Reservado
		"allwaystrue ()", ;                  // Executada para validar delecao de uma linha
		_oDlg)                               // Objeto onde serah criada
		
		if _lExclui
			_bBotaoOK  = {|| _Deleta (), _oDlg:End ()}
//		elseif _lConfEmb
//			_bBotaoOK  = {|| iif (_ConfEmb (), _oDlg:End (), NIL)}
		else
			_bBotaoOK  = {|| NIL}
		endif
		_bBotaoCan = {|| _oDlg:End ()}
		_aBotAdic  = {}
		activate dialog _oDlg on init EnchoiceBar (_oDlg, _bBotaoOK, _bBotaoCan,, _aBotAdic)
	endif
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return



// --------------------------------------------------------------------------
// Exclusao da ordem de embarque e de seu vinculo com as notas fiscais,
// liberando-as para uso em nova ordem.
static function _Deleta ()
	CursorWait ()
	
	// expedição/embarque deletado
	dbselectarea("SF2")
	dbsetorder(10)
	if dbseek(xFilial("SF2") + szo -> zo_numero)
		while !Eof() .and. SF2->F2_ORDEMB == szo -> zo_numero

			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SZN001"
			_oEvento:Texto	  = "Ordem de embarque numero " + alltrim(SF2->F2_ORDEMB) + " deletada."
			_oEvento:NFSaida	  = sf2 -> f2_doc
			_oEvento:SerieSaid = sf2 -> f2_serie
			_oEvento:PedVenda  = ""
			_oEvento:Cliente   = sf2 -> f2_cliente
			_oEvento:LojaCli   = sf2 -> f2_loja
			_oEvento:Hist	  = "1"
			_oEvento:Status	  = "10"
			_oEvento:Sub	  = ""
			_oEvento:Prazo	  = 0
			_oEvento:Flag	  = .T.
			_oEvento:Grava ()
			
			dbselectarea("SF2")
			dbskip()
		enddo
	endif
	
	_sSQL := ""
	_sSQL += " Update " + RetSQLName ("SF2")
	_sSQL += "    Set F2_ORDEMB  = '" + space (tamsx3 ("F2_ORDEMB")[1]) + "'"
	_sSQL += "  Where F2_ORDEMB  = '" + szo -> zo_numero     + "'"
	_sSQL += "    And F2_FILIAL  = '" + xfilial ("SF2")      + "'"
	_sSQL += "    And D_E_L_E_T_ = ''"
	if TCSQLExec (_sSQL) < 0
		u_help ("ERRO na limpeza das notas fiscais desta ordem de embarque.")
	endif
	
	reclock ("SZO", .F.)
	szo -> (dbdelete ())
	msunlock ()
	CursorArrow ()
return



/* Confirmacao de embarque desabilitada em 21/07/2020.
// --------------------------------------------------------------------------
// Confirmacao do carregamento da ordem de embarque e informacao de campos adicionais.
static function _ConfEmb ()
	local _lRet      := .F.
	local _sAliasQ   := ""
	local _lAlter    := .F.
	local _sMsgMail  := ""      	
	local _nCampo    := 0
	local _sCampo    := ""
	local _dPrevisao := ctod ("")
	local _sSeqAD5   := ""
	local _sCMun     := ""

	if Obrigatorio (aGets, aTela)
		CursorWait ()

		// Se jah havia data de embarque, gera evento e manda aviso aos interessados.
		if ! empty (szo -> zo_dataemb) .and. szo -> zo_dataemb != m->zo_dataemb
			_lAlter = .T.
			_sMsgMail := "Confirmacao do embarque '" + szo -> zo_numero + "' alterada por " + alltrim (cUserName) + ":" + chr (13) + chr (10)

			// Monta uma linha para cada campo alterado.
			for _nCampo = 1 to sb1 -> (fcount ())
				_sCampo = sb1 -> (fieldname (_nCampo))
				if type ("M->" + _sCampo) != "U"
					if &("M->" + _sCampo) != sb1 -> &_sCampo
						_sMsgMail += "Campo: " + alltrim (RetTitle (upper (_sCampo)))
						_sMsgMail += ": cont.anterior: " + cValToChar (sb1 -> &_sCampo)
						_sMsgMail += "  cont.novo: " + cValToChar (&("M->" + _sCampo)) + chr (13) + chr (10)
					endif
				endif
			next
			
//			U_SendMail ("limara.dutra@novaalianca.coop.br;ana.dalmagro@novaalianca.coop.br", "Embarque alterado", _sMsgMail)
			U_ZZUNU ({'003'}, "Embarque alterado", _sMsgMail)
		endif
		
		// expedição/embarque OK
		dbselectarea("SF2")
		dbsetorder(10)
		if dbseek(xFilial("SF2") + szo -> zo_numero)
			while !Eof() .and. SF2->F2_ORDEMB == szo -> zo_numero

				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "SZN001"
				_oEvento:Texto	  = "Ordem de embarque numero " + alltrim(SF2->F2_ORDEMB) + " confirmada."
				_oEvento:NFSaida	  = sf2 -> f2_doc
				_oEvento:SerieSaid = sf2 -> f2_serie
				_oEvento:PedVenda  = ""
				_oEvento:Cliente   = sf2 -> f2_cliente
				_oEvento:LojaCli   = sf2 -> f2_loja
				_oEvento:Hist	  = "1"
				_oEvento:Status	  = "2"
				_oEvento:Sub	  = ""
				_oEvento:Prazo	  = 0
				_oEvento:Flag	  = .T.
				_oEvento:Grava ()
				
				dbselectarea("SF2")
				dbskip()
			enddo
		endif

		// Grava data e responsavel pelo embarque
		reclock ("SZO", .F.)
		szo -> zo_respemb = m->zo_respemb
		szo -> zo_motoris = m->zo_motoris
		szo -> zo_placa   = m->zo_placa
		szo -> zo_dataemb = m->zo_dataemb
		msunlock ()
		
		// Gera pendencia de pos-vendas para entrar em contato com o cliente e confirmar recebimento das mercadorias.
		if ! _lAlter
			_sQuery := ""
			_sQuery += " Select distinct F2_TRANSP, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_VEND1, F2_TIPO, A1_CMUN"
			_sQuery += "   From " + RetSQLName ("SF2") + " SF2, "
			_sQuery +=              RetSQLName ("SA1") + " SA1, "
			_sQuery +=              RetSQLName ("SA4") + " SA4  "
			_sQuery += "  Where SF2.D_E_L_E_T_ = ''"
			_sQuery += "    And SA1.D_E_L_E_T_ = ''"
			_sQuery += "    And SA4.D_E_L_E_T_ = ''"
			_sQuery += "    And F2_FILIAL  = '" + xfilial ("SF2") + "'"
			_sQuery += "    And A1_FILIAL  = '" + xfilial ("SA1") + "'"
			_sQuery += "    And A4_FILIAL  = '" + xfilial ("SA4") + "'"
			_sQuery += "    And A1_COD     = F2_CLIENTE"
			_sQuery += "    And A1_LOJA    = F2_LOJA"
			_sQuery += "    And A4_COD     = F2_TRANSP"
			_sQuery += "    And F2_ORDEMB  = '" + szo -> zo_numero + "'"
			_sQuery += "    And A4_VAPOSV  = 'S'"
			_sAliasQ = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
			Do While ! (_sAliasQ) -> (Eof())
               if (_sAliasQ) -> F2_TIPO $ "D/B"  // Caso for Devolucao ou Beneficiamento, busca informacoes do fornecedor, caso contrario, do cliente
                  _sCMun  := fBuscaCpo ("SA2", 1, xfilial ("SA2") +  (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA2->A2_COD_MUN")
               else
   	              _sCMun  := fBuscaCpo ("SA1", 1, xfilial ("SA1") +  (_sAliasQ) -> f2_cliente + (_sAliasQ) -> f2_loja, "SA1->A1_CMUN")
               endif
 			
			                                                                
			
				// Busca o tempo necessario para a entrega nesse local.
				_sQuery := ""
				_sQuery += " Select ZZ0_DIAS"
				_sQuery += "   From " + RetSQLName ("ZZ0") + " ZZ0  "
				_sQuery += "  Where ZZ0.D_E_L_E_T_ = ''"
				_sQuery += "    And ZZ0.ZZ0_FILIAL = '" + xfilial ("ZZ0") + "'"
				_sQuery += "    And ZZ0.ZZ0_TRANSP = '" + (_sAliasQ) -> f2_transp + "'"
				_sQuery += "    And ZZ0.ZZ0_DESTIN = '" + _sCMun + "'"
				_nPrazo = U_RetSQL (_sQuery)
				_oDUtil := ClsDUtil():New ()
				_dPrevisao = _oDUtil:SomaDiaUt (m->zo_dataemb, _nPrazo)
				
				// Se o prazo estiver zerado (nao informado), manda e-mail de aviso
				if _nPrazo == 0
					_sMsgMail = "Dias para entrega nao informado p/ transportadora '" + (_sAliasQ) -> f2_transp + "' X municipio '" + _sCMun + "'. Previsao de entrega calculada para data igual `a do carregamento."
//					U_SendMail ("limara.dutra@novaalianca.coop.br;ana.dalmagro@novaalianca.coop.br", _sMsgMail, _sMsgMail)
					U_ZZUNU ({'003'}, _sMsgMail, _sMsgMail)
				endif

				// Busca proxima sequencia para esta data (chave unica do arquivo AD5)
				_sQuery := ""
				_sQuery += " Select MAX (AD5_SEQUEN)"
				_sQuery += "   From " + RetSQLName ("AD5") + " AD5  "
				_sQuery += "  Where AD5.D_E_L_E_T_ = ''"
				_sQuery += "    And AD5.AD5_FILIAL = '" + xfilial ("AD5") + "'"
				_sQuery += "    And AD5.AD5_VEND   = '" + (_sAliasQ) -> f2_vend1 + "'"
				_sQuery += "    And AD5.AD5_DATA   = '" + dtos (m->zo_dataemb) + "'"
				_sSeqAD5 = U_RetSQL (_sQuery)
				_sSeqAD5 = Soma1 (iif (empty (_sSeqAD5), "00", _sSeqAD5))

				// Gera pendencia no pos-venda.
				reclock ("AD5", .T.)
				ad5 -> ad5_filial = xfilial ("AD5")
				ad5 -> ad5_codcli = (_sAliasQ) -> f2_cliente
				ad5 -> ad5_loja   = (_sAliasQ) -> f2_loja
				ad5 -> ad5_vaNF   = (_sAliasQ) -> f2_doc
				ad5 -> ad5_vaSeri = (_sAliasQ) -> f2_serie
				ad5 -> ad5_evento = "000001"  // Embarque
				ad5 -> ad5_vend   = (_sAliasQ) -> f2_vend1
				ad5 -> ad5_data   = m->zo_dataemb
				ad5 -> ad5_sequen = _sSeqAD5
				ad5 -> ad5_vaOrEm = szo -> zo_numero
				ad5 -> ad5_vaStat = "C"  // Carregado
				ad5 -> ad5_vaPraz = _nPrazo
				ad5 -> ad5_vaPrEn = _dPrevisao
				ad5 -> ad5_vaAgLi = _dPrevisao + 1
				msunlock ()
				(_sAliasQ) -> (dbskip())
			enddo
			(_sAliasQ) -> (dbclosearea ())
			dbselectarea ("SZO")
		endif

		CursorArrow ()
		_lRet = .T.
	endif
return _lRet
*/
