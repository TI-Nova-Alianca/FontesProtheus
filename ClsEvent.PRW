// Programa:  ClsEvent
// Autor:     Robert Koch
// Data:      10/07/2008
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 07/08/2008 - Robert  - Criado metodo de gravacao dos eventos.
// 03/03/2010 - Robert  - Criada possibilidade de enviar o texto do evento por e-mail.
// 28/04/2010 - Robert  - Melhorada mensagem do e-mail.
// 19/11/2010 - Robert  - Criado metodo AltCadast.
//                      - Criado metodo SendMail (pode enviar mail do evento mesmo sem grava-lo).
//                      - Criado campo ZN_Alias.
// 28/11/2010 - Robert  - Tratamento para os campos ZN_COD e ZN_RECNO.
// 02/12/2010 - Robert  - Criado metodo 'Log'.
// 14/02/2011 - Robert  - Criado campo ZN_PrefTit.
// 24/02/2011 - Robert  - Campo ZN_PrefTit mudado para ZN_ParcTit.
// 03/09/2013 - Robert  - Melhorias no metodo AltCadast para envio de e-mail.
// 29/10/2013 - Robert  - Criado atributo MailToZZU e tratamento para o mesmo.
// 15/01/2014 - Leandro - Tratamentos para historico de NF.
// 29/04/2014 - Robert  - Criado atributo ::filial (pode gerar evento em outra filial).
// 28/10/2014 - Robert  - Criado tratamento para dados adicionais no metodo :AltCatast.
// 07/07/2015 - Robert  - Grava campos chave (produto, cliente, fornecedor, etc.) no metodo AltCadast().
// 10/07/2015 - Robert  - Removido metodo Log() por nao ter utilizacao.
//                      - Atributo MailToZZU mudado de caracter para array.
// 17/10/2015 - Robert  - Metodo Log() reincluido e melhorado.
// 28/06/2016 - Robert  - Envia copia do e-mail para katia.nunes quando alias = SF4.
// 23/11/2016 - Robert  - Criado metodo LeParam().
// 27/06/2017 - Robert  - Criado metodo Exclui().
// 17/08/2018 - Robert  - Criado atributo :Etiqueta
// 13/11/2018 - Robert  - Envia e-mail para custos (grupo 069) ao alterar produto.
// 24/06/2019 - Robert  - Desabilitado atributo 'AvisaTI' por nao ser usado.
//                      - Grava texto do evento em campo memo real (ZN_TXT)
// 08/07/2019 - Robert  - Desabilitada gravacao campo memo via SYP pois foi migrado para campo ZN_TXT (memo rel).
// 26/07/2019 - Robert  - Melhorado teste de qual campo foi alterado (antes desconsiderava espacos vazios no final)
//                      - Quando alias = SB1, verifica tambem alteracoes em campos do SB5.
//                      - Criado parametro para nao enviar e-mail de notificacao de alteracao de cadastro (util para execucao em batch)
// 20/08/2019 - Robert  - Melhorado metodo AltCadast() para gerar em formato parecido com XML.
// 22/06/2020 - Robert  - Eliminados alguns logs desnecessarios.
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsEvent ()
return



// ==========================================================================
// Classe usada para armazenamento de dados de eventos do sistema (customizados).
CLASS ClsEvent

	// Declaracao das propriedades da Classe
	data Alias
	data Filial
	data Texto
	data NFSaida
	data SerieSaid
	data NFEntrada
	data SerieEntr
	data Produto
	data CodEven
	data PedVenda
	data Cliente
	data LojaCli
	data Fornece
	data LojaFor
	data MailTo
	data MailToZZU
	data Recno
	data RecnoSZN
	data CodAlias
	data ParcTit
	data Hist
	data Status
	data Sub
	data Prazo
	data Flag
	data OP
	data Chave
	data Etiqueta
	data CodProceda
	data Transp
	data TranspReds
	data DtEvento
	data HrEvento
	data Ambiente

	// Declara��o dos M�todos da Classe
	METHOD New ()
	METHOD AltCadast ()
	METHOD Exclui ()
	METHOD Grava ()
	METHOD LeParam ()
	METHOD Log ()
	METHOD SendMail ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New (_nRegSZN) Class ClsEvent
	::Filial     := xfilial ("SZN")
	::Alias      := ""
	::Texto      := ""
	::NFSaida    := ""
	::SerieSaid  := ""
	::NFEntrada  := ""
	::SerieEntr  := ""
	::Produto    := ""
	::CodEven    := ""
	::PedVenda   := ""
	::Cliente    := ""
	::LojaCli    := ""
	::Fornece    := ""
	::LojaFor    := ""
	::MailTo     := ""
	::MailToZZU  := {}
	::Recno      := 0
	::CodAlias   := ""
	::ParcTit    := ""
	::Hist		 := ""
	::Status	 := ""
	::Sub		 := ""
	::Prazo		 := 0
	::Flag		 := .T.
	::OP         := ''
	::Chave      := ''
	::Etiqueta   := ''
	::CodProceda := ''
	::Transp     := ''
	::TranspReds := ''
	::DtEvento   := DATE()
	::HrEvento   := TIME()
	::Ambiente   := GetEnvServer ()
	if _nRegSZN != NIL
		szn -> (dbgoto (_nRegSZN))
		::Filial     = SZN -> zn_filial
		::NFSaida    = SZN -> zn_nfS 
		::SerieSaid  = SZN -> zn_serieS 
		::NFEntrada  = SZN -> zn_nfE 
		::SerieEntr  = SZN -> zn_serieE 
		::Texto      = SZN -> zn_texto 
		::Produto    = SZN -> zn_produto 
		::CodEven    = SZN -> zn_CodEven 
		::PedVenda   = SZN -> zn_PedVend 
		::Cliente    = SZN -> zn_Cliente 
		::LojaCli    = SZN -> zn_LojaCli 
		::Fornece    = SZN -> zn_Fornece 
		::LojaFor    = SZN -> zn_LojaFor 
		::Alias      = SZN -> zn_Alias 
		::Recno      = SZN -> zn_Recno 
		::RecnoSZN   = SZN -> (recno ()) 
		::CodAlias   = SZN -> zn_Cod 
		::ParcTit    = SZN -> zn_ParcTit 
		::Hist       = SZN -> zn_histnf 
		::Status     = SZN -> zn_status 
		::Sub        = SZN -> zn_substs 
		::Prazo      = SZN -> zn_prazo  
		::Flag       = SZN -> zn_flag 
		::OP         = SZN -> zn_op 
		::Chave      = SZN -> zn_chave
		::Etiqueta   = SZN -> zn_etiq
		::CodProceda = SZN -> zn_codproc
		::Transp     = SZN -> zn_transp
		::TranspReds = SZN -> zn_redesp
		::DtEvento   = SZN -> zn_data
		::HrEvento   = SZN -> zn_hora
		::Ambiente   = SZN -> zn_ambient
	endif
Return Self



// --------------------------------------------------------------------------
// Gravacao de eventos
METHOD Grava () Class ClsEvent
	local _aArea    := U_ML_SRArea ()
	local _sTextoZN := ""
	local _sMemo    := ""

	//u_logIni (GetClassName (::Self) + '.' + procname ())

	// Se tem quebras de linha no texto ou se o texto eh grande demais, gera memo.
	if chr (13) $ ::Texto .or. len (alltrim (::Texto)) > tamsx3 ("ZN_TEXTO")[1]
		_sMemo = ::Texto
	endif
	
	// Se tem quebras de linha no texto, gravo soh a primeira linha no SZN e deixo o restante para o campo memo.
	if chr (13) $ ::Texto
		_sTextoZN = left (::Texto, at (chr (13), ::Texto) - 1)
	else
		_sTextoZN = ::Texto
	endif

	if Empty(::Chave)
		::Chave = ::CodAlias
	EndIf	
	
	u_log2 ('info', 'Gravando evento: ' + _sTextoZN)
	
	reclock ("SZN", .T.)
	SZN -> zn_filial  = ::Filial
	SZN -> zn_data    = ::DtEvento
	SZN -> zn_hora    = ::HrEvento
	SZN -> zn_usuario = cUserName
	SZN -> zn_estacao = getcomputername ()
	SZN -> zn_nfS     = ::NFSaida
	SZN -> zn_serieS  = ::SerieSaid
	SZN -> zn_nfE     = ::NFEntrada
	SZN -> zn_serieE  = ::SerieEntr
	SZN -> zn_pilha   = _PCham ()
	SZN -> zn_texto   = _sTextoZN
	SZN -> zn_produto = ::Produto
	SZN -> zn_CodEven = ::CodEven
	SZN -> zn_PedVend = ::PedVenda
	SZN -> zn_Cliente = ::Cliente
	SZN -> zn_LojaCli = ::LojaCli
	SZN -> zn_Fornece = ::Fornece
	SZN -> zn_LojaFor = ::LojaFor
	SZN -> zn_Alias   = ::Alias
	SZN -> zn_Recno   = ::Recno
	SZN -> zn_Cod     = ::CodAlias
	SZN -> zn_ParcTit = ::ParcTit
	SZN -> zn_histnf  = ::Hist
	SZN -> zn_status  = ::Status
	SZN -> zn_substs  = ::Sub
	SZN -> zn_prazo	  = ::Prazo
	SZN -> zn_flag    = ::Flag
	SZN -> zn_op      = ::OP
	SZN -> zn_chave   = ::Chave
	SZN -> zn_etiq    = ::Etiqueta
	SZN -> zn_codproc = ::CodProceda
	SZN -> zn_transp  = ::Transp
	SZN -> zn_redesp  = ::TranspReds
	szn -> zn_txt     = ::Texto
	szn -> zn_ambient = ::Ambiente
	msunlock ("SZN")

	// Envia evento por e-mail, se for o caso.
	::Self:SendMail ()

	U_ML_SRArea (_aArea)
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return .t.



// --------------------------------------------------------------------------
// Verifica alteracao de cadastros e grava evento quando for o caso.
// Deve ser disparado ANTES da alteracao, pois compara as variaveis M-> com os campos da tabela.
METHOD AltCadast (_sAlias, _sCodAlias, _nRecno, _sDadAdic, _lNotif) Class ClsEvent
	local _sMsgLog  := ""
	local _nCampo   := 0
	local _sCampo   := ""
	local _sContAnt := ''
	local _sContAtu := ''
	local _aAreaAnt := U_ML_SRArea ()

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	_sDadAdic := iif (_sDadAdic == NIL, '', _sDadAdic)
	_lNotif   := iif (_lNotif == NIL, .T., _lNotif)
	::Texto = "Alteracao manual arq." + _sAlias
	(_sAlias) -> (dbgoto (_nRecno))
	do case
		case _sAlias == 'CT5'
			::Texto += " Lcto padrao " + ct5 -> ct5_lanpad + ct5 -> ct5_sequen + chr (13) + chr (10)
		case _sAlias == 'SA1'
			::Cliente = sa1 -> a1_cod
			::LojaCli = sa1 -> a1_loja
			::Texto += " Cliente " + sa1 -> a1_cod + '/' + sa1 -> a1_Loja + "-" + alltrim (sa1 -> a1_nome) + chr (13) + chr (10)
		case _sAlias == 'SA2'
			::Fornece = sa2 -> a2_cod
			::LojaFor = sa2 -> a2_loja
			::Texto += " Fornecedor " + sa2 -> a2_cod + '/' + sa2 -> a2_Loja + "-" + alltrim (sa2 -> a2_nome) + chr (13) + chr (10)
		case _sAlias == 'SA3'
			::Texto += " Representante " + sa3 -> a3_cod + "-" + alltrim (sa3 -> a3_nome) + chr (13) + chr (10)
		case _sAlias == 'SB1'
			::Produto = sb1 -> b1_cod
			::Texto += " Produto " + alltrim (sb1 -> b1_cod) + "-" + alltrim (sb1 -> b1_desc) + chr (13) + chr (10)
		case _sAlias == 'SF4'
			::Texto += " TES " + sf4 -> f4_codigo + '-' + alltrim (sf4 -> f4_texto) + chr (13) + chr (10)
//		case _sAlias == 'SRV'
//			::Texto += " Verba folha " + srv -> rv_cod + '-' + alltrim (srv -> rv_desc) 
//		case _sAlias == 'ZAX'
//			::Texto += " Cliente " + alltrim (zax -> zax_client) + chr (13) + chr (10)
		otherwise
			::Texto += " (" + alltrim (fBuscaCpo ("SX2", 1, _sAlias, "X2_NOME")) +")" + chr (13) + chr (10)
	endcase
//	::Texto += chr (13) + chr (10) + _sMsgLog


	// Monta uma linha para cada campo alterado.
	for _nCampo = 1 to (_sAlias) -> (fcount ())
		_sCampo = (_sAlias) -> (fieldname (_nCampo))
		if type ("M->" + _sCampo) != "U"
			_sContAtu = alltrim (cvaltochar (&("M->" + _sCampo)))
			_sContAnt = alltrim (cvaltochar ((_sAlias) -> &_sCampo))
			//u_log ('verificando ', "M->" + _sCampo, 'que contem:', _sContAtu, 'contra o anterior, que contem', _sContAnt)
			//if alltrim (cvaltochar (&("M->" + _sCampo))) != alltrim (cvaltochar ((_sAlias) -> &_sCampo))
			if _sContAtu != _sContAnt
				//_sMsgLog += alltrim (_sCampo) + " (" + alltrim (RetTitle (upper (_sCampo))) + "): alterado de '" + alltrim (cValToChar ((_sAlias) -> &_sCampo)) + "' para '" + alltrim (cValToChar (&("M->" + _sCampo))) + "'" + chr (13) + chr (10)
				_sMsgLog += '<cpo>' + alltrim (_sCampo) + '</cpo>' + chr (13) + chr (10)  //<titulo>' + alltrim (RetTitle (upper (_sCampo))) + '</titulo>' + chr (13) + chr (10)
				_sMsgLog += '<de>' + _sContAnt + '</de>' + chr (13) + chr (10)
				_sMsgLog += '<para>' + _sContAtu + '</para>' + chr (13) + chr (10)
			endif
		endif
	next
	//u_log ('_sMsgLog apos ler campos do ALIAS:', _sMsgLog)

	// Se for alteracao de produtos, verifica tambem o SB5. Provavelmente no futuro precise verificar tambem outras tabelas que vao aparecer na mesma tela.
	if _sAlias == 'SB1'
		for _nCampo = 1 to sb5 -> (fcount ())
			_sCampo = sb5 -> (fieldname (_nCampo))
			if type ("M->" + _sCampo) != "U"
				_sContAtu = alltrim (cvaltochar (&("M->" + _sCampo)))
				_sContAnt = alltrim (cvaltochar (sb5 -> &_sCampo))
				//u_log ('verificando ', "M->" + _sCampo, 'que contem:', _sContAtu, 'contra o anterior, que contem', _sContAnt)
//				if alltrim (cvaltochar (&("M->" + _sCampo))) != alltrim (cvaltochar (sb5 -> &_sCampo))
				if _sContAtu != _sContAnt
//					_sMsgLog += alltrim (_sCampo) + " (" + alltrim (RetTitle (upper (_sCampo))) + "): alterado de '" + alltrim (cValToChar (sb5 -> &_sCampo)) + "' para '" + alltrim (cValToChar (&("M->" + _sCampo))) + "'" + chr (13) + chr (10)
					_sMsgLog += '<cpo>' + alltrim (_sCampo) + '</cpo>' + chr (13) + chr (10)  //<titulo>' + alltrim (RetTitle (upper (_sCampo))) + '</titulo>' + chr (13) + chr (10)
					_sMsgLog += '<de>' + _sContAnt + '</de>' + chr (13) + chr (10)
					_sMsgLog += '<para>' + _sContAtu + '</para>' + chr (13) + chr (10)
				endif
			endif
		next
	endif
	//u_log ('_sMsgLog apos ler campos do SB5:', _sMsgLog)

	if ! empty (_sMsgLog) .or. ! empty (_sDadAdic)
		//u_log ('_sMsgLog: ' , _sMsgLog)
		::Alias     = _sAlias
		::CodEven   = "ALT001"
		::Texto    += _sMsgLog
		
		if ! empty (_sDadAdic)
			::Texto += chr (13) + chr (10) + _sDadAdic
		endif

		::CodAlias  = _sCodAlias
		::Recno     = _nRecno

		// Alguns cadastros sao monitorados.
		if ::Alias $ "SB1/SA1/SA2/SF4/SA3/ZZ2/CT5"
			if _lNotif
				aadd (::MailToZZU, '015')  // Controladoria
			endif
			if ::Alias == 'SF4'
				if _lNotif
					::MailTo = 'katia.nunes@novaalianca.coop.br'  // Responsavel pelo fiscal.
				endif
			endif
		endif
		if ::Alias $ "SB1"
			if _lNotif
				aadd (::MailToZZU, '069')  // Custos
			endif
		endif

		if ::Alias $ "SA1"
			if _lNotif
				aadd (::MailToZZU, '011')  // Supervisao comercial
			endif
		endif
		::Self:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)
//	u_logFim (GetClassName (::Self) + '.' + procname ())
return



// --------------------------------------------------------------------------
// Exclusao do evento posicionado no SZN
METHOD Exclui () Class ClsEvent
	local _aArea    := U_ML_SRArea ()
//	local _sMemo    := ""

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	szn -> (dbgoto (::RecnoSZN))

	// Migrado para campo ZN_TXT (memo real). Robert, 07/07/2019
	//// Apaga memo relacionado.
	//if ! empty (szn -> zn_codmemo)
	//	msmm (szn -> zn_codmemo,,,, 2,,, "SZN", "ZN_CODMEMO")
	//endif
	
	reclock ("SZN", .F.)
	szn -> (dbdelete ())
	msunlock ()

	U_ML_SRArea (_aArea)
//	u_logFim (GetClassName (::Self) + '.' + procname ())
return



// --------------------------------------------------------------------------
// Faz a leitura das respostas de determinado grupo de perguntas e grava no evento.
METHOD LeParam (_sPerg) CLASS ClsEvent
	local _aPerg := {}
	local _nPerg := 0
	
	::Texto += "Grupo de parametros '" + _sPerg + "':" + chr (13) + chr (10)
	_aPerg = U_LePerg (__cUserID, _sPerg)
	for _nPerg = 1 to len (_aPerg)
		::Texto += _aPerg [_nPerg, 3] + ' ' + _aPerg [_nPerg, 4] + ' ' + cvaltochar (_aPerg [_nPerg, 5]) + chr (13) + chr (10)
	next
return



// --------------------------------------------------------------------------
// Grava dados do evento em arquivo de log
METHOD Log () Class ClsEvent
	U_Log ("----------------- EVENTO ----------------- [" + dtoc (date()) + ' ' + time() + ']')
	if !empty (::CodEven);                 U_Log ("Cod.evento.....:" + ::CodEven); endif
	if !empty (::Texto);                   U_Log ("Texto..........:" + ::Texto); endif
	if !empty (::OP);                      U_Log ("OP.............:" + ::OP); endif
	if !empty (::Produto);                 U_Log ("Produto........:" + ::Produto); endif
	if !empty (::PedVenda);                U_Log ("Pedido venda...:" + ::PedVenda); endif
	if !empty (::NFEntrada + ::SerieEntr); U_Log ("NF entr./serie.:" + ::NFEntrada + "/" + ::SerieEntr); endif
	if !empty (::NFSaida + ::SerieSaid);   U_Log ("NF saida/serie.:" + ::NFSaida + "/" + ::SerieSaid); endif
	if !empty (::ParcTit);                 U_Log ("Parcela titulo.:" + ::ParcTit); endif
	if !empty (::Cliente + ::LojaCli);     U_Log ("Cliente/loja...:" + ::Cliente + "/" + ::LojaCli); endif
	if !empty (::Fornece + ::LojaFor);     U_Log ("Fornecedor/loja:" + ::Fornece + "/" + ::LojaFor); endif
	if !empty (::Alias);                   U_Log ("Alias/recno....:" + ::Alias + "/" + cvaltochar (::Recno)); endif
	if !empty (::Recno);                   U_Log ("Recno..........:" + cvaltochar (::Recno)); endif
	if !empty (::CodAlias);                U_Log ("Codigo alias...:" + ::CodAlias); endif
	if !empty (::MailTo);                  U_Log ("MailTo.........:" + ::MailTo); endif
	if !empty (::MailToZZU);               U_Log ("MailToZZU......:" + ::MailToZZU); endif
	if !empty (::Hist);                    U_Log ("Historico......:" + ::Hist); endif
	if !empty (::Status);                  U_Log ("Status.........:" + ::Status); endif
	if !empty (::Sub);                     U_Log ("Substatus......:" + ::Sub); endif
	if !empty (::Prazo);                   U_Log ("Prazo..........:" + cvaltochar (::Prazo)); endif
	                                       U_Log ("Flag...........:" + cvaltochar (::Flag))
	U_Log ("-----------------------------------------------------------")
return



// --------------------------------------------------------------------------
// Verifica alteracao de cadastros e grava evento quando for o caso.
METHOD SendMail (_sDestin) Class ClsEvent
	local _sTxtMail := ""
	local _sTxtCabec := ""

//	u_logIni (GetClassName (::Self) + '.' + procname ())
	_sDestin := iif (_sDestin == NIL, ::MailTo, _sDestin)

	// Soh monta a mensagem se tiver destinatarios.
	if ! empty (_sDestin) .or. len (::MailToZZU) > 0

		// Se tem quebras de linha no texto, usa soh a primeira no cabec. do e-mail.
		if chr (13) $ ::Texto
			_sTxtCabec = left (::Texto, at (chr (13), ::Texto) - 1)
		else
			_sTxtCabec = ::Texto
		endif
	
		_sTxtMail := "Novo evento registrado no sistema de gestao:" + chr (13) + chr (10)
		_sTxtMail += "Descricao......: " + ::Texto + chr (13) + chr (10)
		_sTxtMail += "Tipo evento....: " + ::CodEven + " - " + Tabela ("79", ::CodEven) + chr (13) + chr (10)
		_sTxtMail += "Empresa/filial.: " + cEmpAnt + "/" + ::Filial + chr (13) + chr (10)
		if ! empty (::NFSaida)
			_sTxtMail += "NF saida.......: " + ::NFSaida + "/" + ::SerieSaid + chr (13) + chr (10)
		endif
		if ! empty (::NFEntrada)
			_sTxtMail += "NF entrada.....: " + ::NFEntrada + "/" + ::SerieEntr + chr (13) + chr (10)
		endif
		if ! empty (::Cliente)
			_sTxtMail += "Cliente........: " + ::Cliente + "/" + ::LojaCli + " - " + fBuscaCpo ("SA1", 1, xfilial ("SA1") + ::Cliente + ::LojaCli, "A1_NOME") + chr (13) + chr (10)
		endif
		if ! empty (::Fornece)
			_sTxtMail += "Fornecedor.....: " + ::Fornece + "/" + ::LojaFor + " - " + fBuscaCpo ("SA2", 1, xfilial ("SA2") + ::Fornece + ::LojaFor, "A2_NOME") + chr (13) + chr (10)
		endif
		if ! empty (::PedVenda)
			_sTxtMail += "Pedido de venda: " + ::PedVenda + chr (13) + chr (10)
		endif
		if ! empty (::Produto)
			_sTxtMail += "Produto........: " + ::Produto + chr (13) + chr (10)
		endif
		_sTxtMail += "Data/hora......: " + dtoc (date ()) + "  -  " + time () + chr (13) + chr (10)
		_sTxtMail += "Usuario/estacao: " + cUserName + " / " + getcomputername () + chr (13) + chr (10)
	endif

	if ! empty (_sDestin)
		U_SendMail (_sDestin, "Evento sist.: " + _sTxtCabec, _sTxtMail, {})
	endif
	if len (::MailToZZU) > 0
		U_ZZUNU (::MailToZZU, "Evento sist.: " + _sTxtCabec, _sTxtMail, .F., cEmpAnt, cFilAnt)
	endif

//	u_logFim (GetClassName (::Self) + '.' + procname ())
return



// --------------------------------------------------------------------------
// Faz exportacao da pilha de chamadas para uma string.
static function _PCham ()
	local _i      := 2
	local _sPilha := ""
	do while procname (_i) != ""
		_sPilha += procname (_i) + "=>"
		_i++
	enddo
return _sPilha