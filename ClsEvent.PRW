// Programa.: ClsEvent
// Autor....: Robert Koch
// Data.....: 10/07/2008
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Classe
// #Descricao         #Declaracao de classe para uso em outros programas.
// #PalavasChave      #classe #eventos
// #TabelasPrincipais #SZN 
// #Modulos           #todos

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
//                      - Criado parametro para nao enviar e-mail de notificacao de alteracao de cadastro 
//                        (util para execucao em batch)
// 20/08/2019 - Robert  - Melhorado metodo AltCadast() para gerar em formato parecido com XML.
// 22/06/2020 - Robert  - Eliminados alguns logs desnecessarios.
// 10/03/2021 - Robert  - Melhoria metodo Log().
//                      - Implementado metodo GravaNovo().
// 18/04/2021 - Robert  - Grava nome e metodo da classe no arquivo de log.
// 15/05/2021 - Claudia - Criada fun��o para typo de campo para tirar do loop, bug R27. GLPI: 8825
// 17/05/2021 - Robert  - Grava ::Texto e nao mais _sTextoZN no arquivo de log.
// 21/05/2021 - Robert  - Campo ZN_PILHA substituido pelo ZN_ORIGEM (GLPI 10072)
// 19/08/2021 - Robert  - Inicializador para ::Origem, pois quando pilha de chamadas, excedia tamanho do campo (GLPI 10578).
// 02/05/2022 - Robert  - Incluidas chamadas de U_PerfMon() para acompanhar tempo de gravacao.
// 20/07/2022 - Robert  - Criado tratamento para atributos ::DiasValid e ::ChaveNFe (GLPI 12336)
// 01/08/2022 - Robert  - Criado atributo ::MotProrTit
// 27/10/2022 - Robert  - Envia notificacao ao gravar codigo de evento desconhecido.
// 30/01/2023 - Robert  - Metodo GravaNovo passa a aceitar parametro de
//                        precisao para teste de jah existencia do evento.
//                      - Criado atributo Usuario.
// 22/02/2023 - Robert  - Criados atributos Safra e CargaSafra.
// 24/02/2023 - Robert  - Gera aviso quando receber chave antiga para evento de carga/safra.
// 28/04/2023 - Robert  - Erro na leitura do campo ZN_DIASVLD
// 30/08/2023 - Robert  - Nao envia mais e-mail de alter.cadastro para grupo 015 (auditoria) - GLPI 14099
// 20/10/2023 - Robert  - Criados atributos ::Avisar e ::AvisarZZU, com respectiva funcionalidade de envio de aviso (GLPI 14397)
// 06/06/2024 - Sandra  - Retirado grupo 011, n�o ser� mais utilizado. GLPI: 15557
//

#include "protheus.ch"

// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsEvent ()
return


// ------------------------------------------------------------------------------------
// Classe usada para armazenamento de dados de eventos do sistema (customizados).
CLASS ClsEvent

	// Declaracao das propriedades da Classe
	data Alias
	data Avisar     // Usuario(s) para gerar aviso
	data AvisarZZU  // Grupo(s) para gerar aviso
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
	data Origem
	data DiasValid
	data ChaveNFe
	data MotProrTit
	data Usuario
	data Safra
	data CargaSafra

	// Declara��o dos M�todos da Classe
	METHOD New ()
	METHOD AltCadast ()
	METHOD Exclui ()
	METHOD Grava ()
	METHOD GravaNovo ()
	METHOD LeParam ()
	METHOD Log ()
	METHOD SendMail ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New (_nRegSZN) Class ClsEvent
	::Filial     := xfilial ("SZN")
	::Alias      := ""
	::Avisar     := ""
	::AvisarZZU  := ""
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
	::Origem     := ''
	::DiasValid  := 0
	::ChaveNFe   := ''
	::MotProrTit := ''
	::Usuario    := cUserName
	::Safra      = ''
	::CargaSafra = ''

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
		::Origem     = SZN -> zn_origem
		::DiasValid  = SZN -> zn_diasvld
		::ChaveNFe   = SZN -> zn_chvnfe
		::MotProrTit = szn -> zn_MotPror
		::Usuario    = szn -> zn_usuario
		::Safra      = szn -> zn_safra
		::CargaSafra = szn -> zn_cargsaf
	endif
Return Self


// --------------------------------------------------------------------------
// Gravacao de eventos
METHOD Grava () Class ClsEvent
	local _aArea    := U_ML_SRArea ()
	local _sTextoZN := ""
	local _oAviso   := Nil

	// Se tem quebras de linha no texto, gravo soh a primeira linha no SZN e deixo o restante para o campo memo.
	if chr (13) $ ::Texto
		_sTextoZN = left (::Texto, at (chr (13), ::Texto) - 1)
	else
		_sTextoZN = ::Texto
	endif

	if Empty(::Chave)
		::Chave = ::CodAlias
	EndIf

	u_log2 ('debug', '[' + GetClassName (::Self) + '.' + procname () + ']Gravando evento ' + dtoc (::DtEvento) + ' ' + ::HrEvento + ' ' + ::Texto)
	
	reclock ("SZN", .T.)
	SZN -> zn_filial  = ::Filial
	SZN -> zn_data    = ::DtEvento
	SZN -> zn_hora    = ::HrEvento
	SZN -> zn_usuario = ::Usuario
	SZN -> zn_estacao = getcomputername ()
	SZN -> zn_nfS     = ::NFSaida
	SZN -> zn_serieS  = ::SerieSaid
	SZN -> zn_nfE     = ::NFEntrada
	SZN -> zn_serieE  = ::SerieEntr
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
	szn -> zn_origem  = iif (empty (::Origem), _Origem (), ::Origem)
	szn -> zn_diasvld = ::DiasValid
	szn -> zn_chvnfe  = ::ChaveNFe
	szn -> zn_MotPror = ::MotProrTit
	szn -> zn_safra   = ::Safra
	szn -> zn_cargsaf = ::CargaSafra
	msunlock ("SZN")

	// Envia aviso em caso de codigo de evento nao cadastrado.
	if ! U_ExistZX5 ('54', ::CodEven, .f.)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'A'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = "Gravado evento com codigo inexistente (" + ::CodEven + ") na tabela 54 do ZX5"
		_oAviso:Texto      = _oAviso:Titulo
		_oAviso:InfoSessao = .T.
		_oAviso:Grava ()
	endif

	// Criei os atributos tarde demais, e tem muita coisa gravando pelo metodo antigo
	if ::Alias == 'SZE' .and. (empty (::Safra) .or. empty (::CargaSafra))
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'A'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = "Gravado evento de carga safra sem usar atributos novos."
		_oAviso:Texto      = _oAviso:Titulo + ' Texto do evento: ' + _sTextoZN
		_oAviso:InfoSessao = .T.
		_oAviso:Grava ()
	endif

	// Envia evento por e-mail, se for o caso.
	::Self:SendMail ()

	// Envia aviso, se solicitado pela rotina chamadora.
	if ! empty (::Avisar) .or. ! empty (::AvisarZZU)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'A'
		if ! empty (::Avisar)
			_oAviso:DestinAvis = alltrim (::Avisar)
		endif
		if ! empty (::AvisarZZU)
			_oAviso:DestinZZU = aclone (::AvisarZZU)
		endif
		_oAviso:Titulo     = 'Evento Protheus ' + _sTextoZN
		_oAviso:Texto      = _sTextoZN
		_oAviso:Grava ()
	endif

	U_ML_SRArea (_aArea)
return .t.


// --------------------------------------------------------------------------
// Gravacao de eventos somente quando ainda nao existirem (evitar duplicidade)
METHOD GravaNovo (_sPrecisao) Class ClsEvent
	local _oSQL := ClsSQL ():New ()

	// Nao quero considerar o metodo atual como parte da origem do evento
	::Origem = iif (empty (::Origem), strtran (_Origem (), procname (), ''), ::Origem)
//	U_Log2 ('debug', '[' + GetClassName (::Self) + '.' + procname () + ']Fiquei com origem = ' + ::Origem)

	// A chamada pode especificar a precisao de tempo para que um exento seja
	// considerado 'novo':
	// DHMS - Nao deve existir evento com mesmos dados no ultimo segundo.
	// DHM  - Nao deve existir evento com mesmos dados no ultimo minuto.
	// DH   - Nao deve existir evento com mesmos dados na ultima hora.
	// D    - Nao deve existir evento com mesmos dados nas ultimas 24 horas.
	_sPrecisao = iif (_sPrecisao == NIL, 'DHMS', _sPrecisao)
	if !_sPrecisao $ 'DHMS/DHM/DH/D'
		U_Log2 ('erro', '[' + GetClassName (::Self) + '.' + procname () + "]Precisao invalida '" + _sPrecisao + "' recebida! Origem = " + ::Origem)
		_sPrecisao = 'DHMS'
	endif

	// Vou testar apenas os campos que considero mais importantes.
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "select case WHEN exists (SELECT * "
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZN") + " SZN "
	_oSQL:_sQuery += " WHERE SZN.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SZN.ZN_FILIAL  = '" + ::Filial + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_CODEVEN = '" + ::CodEven + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_NFS     = '" + ::NFSaida + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_SERIES  = '" + ::SerieSaid + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_NFE     = '" + ::NFEntrada + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_SERIEE  = '" + ::SerieEntr + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_PRODUTO = '" + ::Produto + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_PEDVEND = '" + ::PedVenda + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_CLIENTE = '" + ::Cliente + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_LOJACLI = '" + ::LojaCli + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_FORNECE = '" + ::Fornece + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_LOJAFOR = '" + ::LojaFor + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_ALIAS   = '" + ::Alias + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_COD     = '" + ::CodAlias + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_CHAVE   = '" + ::Chave + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_PARCTIT = '" + ::ParcTit + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_OP      = '" + ::OP + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_ETIQ    = '" + ::Etiqueta + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_TRANSP  = '" + ::Transp + "'"
	_oSQL:_sQuery +=   " AND SZN.ZN_CHVNFE  = '" + ::ChaveNFe + "'"
//	_oSQL:_sQuery +=   " AND SZN.ZN_REDESP  = '" + ::TranspReds + "'"
//	_oSQL:_sQuery +=   " AND SZN.ZN_CODPROC = '" + ::CodProceda + "'"
//	_oSQL:_sQuery +=   " AND SZN.ZN_ORIGEM  = '" + ::Origem + "'"
//	_oSQL:_sQuery +=   " AND SZN.ZN_DIASVLD = " + cvaltochar (::DiasValid)
//	_oSQL:_sQuery +=   " AND SZN.ZN_MOTPROR = '" + ::MotProrTit + "'"

	if _sPrecisao == 'DHMS'  // Consistir tudo. Nem farei calculo algum.
		_oSQL:_sQuery += " AND SZN.ZN_DATA = '" + dtos (::DtEvento) + "'"
		_oSQL:_sQuery += " AND SZN.ZN_HORA = '" + ::HrEvento + "'"
	else
		
		// Fiz o teste em segundos, caso encontre uma data muito antiga,
		// ocorre erro de overflow na quantidade de segundos.
		// Uma vez que nao pretendo testar precisao maior que 1 dia, creio
		// que validar os ultimos 2 dias estaria mais que suficiente.
		_oSQL:_sQuery += " AND SZN.ZN_DATA >= '" + dtos (::DtEvento - 2) + "'"

		_oSQL:_sQuery += " AND DATEDIFF (second,"
		_oSQL:_sQuery += " CAST (SZN.ZN_DATA + ' ' + SZN.ZN_HORA as datetime),"
		_oSQL:_sQuery += " CAST ('" + dtos (::DtEvento) + " " + ::HrEvento + "' as datetime)"
		_oSQL:_sQuery += ") < "
		do case
		case _sPrecisao == 'DHM'
			_oSQL:_sQuery += "60"
		case _sPrecisao == 'DH'
			_oSQL:_sQuery += "3600"  // 60*60
		case _sPrecisao == 'D'
			_oSQL:_sQuery += "86400"  // 60*60*24
		endcase
	endif
	_oSQL:_sQuery += ") then 1 else 0 end"
//	_oSQL:Log ('[' + GetClassName (::Self) + '.' + procname () + ']')

	if _oSQL:RetQry (1, .f.) == 0
		::Grava ()
	else
		U_Log2 ('aviso', '[' + GetClassName (::Self) + '.' + procname () + ']Evento nao vai ser gravado, pois jah existe registro com essa informacao no SZN, considerando uma precisao de ' + _sPrecisao)
	endif
return


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
		otherwise
			::Texto += " (" + alltrim (fBuscaCpo ("SX2", 1, _sAlias, "X2_NOME")) +")" + chr (13) + chr (10)
	endcase

	// Monta uma linha para cada campo alterado.
	for _nCampo = 1 to (_sAlias) -> (fcount ())
		_sCampo = (_sAlias) -> (fieldname (_nCampo))
		_sType := BuscaTipo(_sCampo)

		if alltrim(_sType) != "U"
			_sContAtu = alltrim (cvaltochar (&("M->" + _sCampo)))
			_sContAnt = alltrim (cvaltochar ((_sAlias) -> &_sCampo))

			if _sContAtu != _sContAnt
				_sMsgLog += '<cpo>' + alltrim (_sCampo) + '</cpo>' + chr (13) + chr (10)  
				_sMsgLog += '<de>' + _sContAnt + '</de>' + chr (13) + chr (10)
				_sMsgLog += '<para>' + _sContAtu + '</para>' + chr (13) + chr (10)
			endif
		endif
	next

	// Se for alteracao de produtos, verifica tambem o SB5. Provavelmente no futuro precise verificar tambem outras tabelas que vao aparecer na mesma tela.
	if _sAlias == 'SB1'
		for _nCampo = 1 to sb5 -> (fcount ())
			_sCampo = sb5 -> (fieldname (_nCampo))
			_sType := BuscaTipo(_sCampo)

			if alltrim(_sType) != "U"
				_sContAtu = alltrim (cvaltochar (&("M->" + _sCampo)))
				_sContAnt = alltrim (cvaltochar (sb5 -> &_sCampo))

				if _sContAtu != _sContAnt
					_sMsgLog += '<cpo>' + alltrim (_sCampo) + '</cpo>' + chr (13) + chr (10)  
					_sMsgLog += '<de>' + _sContAnt + '</de>' + chr (13) + chr (10)
					_sMsgLog += '<para>' + _sContAtu + '</para>' + chr (13) + chr (10)
				endif
			endif
		next
	endif

	if ! empty (_sMsgLog) .or. ! empty (_sDadAdic)
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
				// Liane disse (via Teams em 30/08/2023) que nao precisa mais  ---> aadd (::MailToZZU, '015')  // Controladoria
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

		//if ::Alias $ "SA1"
			//if _lNotif
				//aadd (::MailToZZU, '011')  // Supervisao comercial
			//endif
		//endif

		::Self:Grava ()
	endif

	U_ML_SRArea (_aAreaAnt)

return


// --------------------------------------------------------------------------
// Exclusao do evento posicionado no SZN
METHOD Exclui () Class ClsEvent
	local _aArea    := U_ML_SRArea ()

	szn -> (dbgoto (::RecnoSZN))
	U_Log2 ('aviso', 'Deletando evento:')
	u_logtrb ('szn')

	reclock ("SZN", .F.)
	szn -> (dbdelete ())
	msunlock ()

	U_ML_SRArea (_aArea)
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
	local _sTxtlog := ''

	_sTxtLog := "----------------- EVENTO -----------------" + chr (13) + chr (10)
	                                       _sTxtLog += "Data/hora evt..: " + dtoc (::DtEvento) + ' ' + ::HrEvento + chr (13) + chr (10)
	if !empty (::CodEven);                 _sTxtLog += "Cod.evento.....: " + ::CodEven + chr (13) + chr (10); endif
	if !empty (::Texto);                   _sTxtLog += "Texto..........: " + ::Texto + chr (13) + chr (10); endif
	if !empty (::OP);                      _sTxtLog += "OP.............: " + ::OP + chr (13) + chr (10); endif
	if !empty (::Produto);                 _sTxtLog += "Produto........: " + ::Produto + chr (13) + chr (10); endif
	if !empty (::PedVenda);                _sTxtLog += "Pedido venda...: " + ::PedVenda + chr (13) + chr (10); endif
	if !empty (::NFEntrada + ::SerieEntr); _sTxtLog += "NF entr./serie.: " + ::NFEntrada + "/" + ::SerieEntr + chr (13) + chr (10); endif
	if !empty (::NFSaida + ::SerieSaid);   _sTxtLog += "NF saida/serie.: " + ::NFSaida + "/" + ::SerieSaid + chr (13) + chr (10); endif
	if !empty (::ParcTit);                 _sTxtLog += "Parcela titulo.: " + ::ParcTit + chr (13) + chr (10); endif
	if !empty (::Cliente + ::LojaCli);     _sTxtLog += "Cliente/loja...: " + ::Cliente + "/" + ::LojaCli + chr (13) + chr (10); endif
	if !empty (::Fornece + ::LojaFor);     _sTxtLog += "Fornecedor/loja: " + ::Fornece + "/" + ::LojaFor + chr (13) + chr (10); endif
	if !empty (::Alias);                   _sTxtLog += "Alias/recno....: " + ::Alias + "/" + cvaltochar (::Recno) + chr (13) + chr (10); endif
	if !empty (::Recno);                   _sTxtLog += "Recno..........: " + cvaltochar (::Recno) + chr (13) + chr (10); endif
	if !empty (::CodAlias);                _sTxtLog += "Codigo alias...: " + ::CodAlias + chr (13) + chr (10) ; endif
	if !empty (::MailTo);                  _sTxtLog += "MailTo.........: " + ::MailTo + chr (13) + chr (10); endif
	if !empty (::MailToZZU);               _sTxtLog += "MailToZZU......: " + ::MailToZZU + chr (13) + chr (10); endif
	if !empty (::Hist);                    _sTxtLog += "Historico......: " + ::Hist + chr (13) + chr (10); endif
	if !empty (::DiasValid);               _sTxtLog += "Dias vld.evento: " + cvaltochar (::DiasValid) + chr (13) + chr (10); endif
	if !empty (::ChaveNFe);                _sTxtLog += "Chave NFe......: " + ::ChaveNFe + chr (13) + chr (10); endif
	if !empty (::MotProrTit);              _sTxtLog += "Mot.prorrog.tit: " + ::MotProrTit + chr (13) + chr (10); endif

	_sTxtLog += "-----------------------------------------------------------" + chr (13) + chr (10)
	u_log2 ('info', _sTxtLog)
return


// --------------------------------------------------------------------------
// Envia copia do evento por e-mail, quando solicitado.
METHOD SendMail (_sDestin) Class ClsEvent
	local _sTxtMail := ""
	local _sTxtCabec := ""

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
		_sTxtMail += "Tipo evento....: " + ::CodEven + " - " + U_RetZX5 ('54', ::CodEven, 'ZX5_54DESC') + chr (13) + chr (10)
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
		if ! empty (::ChaveNFe)
			_sTxtMail += "Chave NFe......: " + ::ChaveNFe + chr (13) + chr (10)
		endif
		if ! empty (::MotProrTit)
			_sTxtMail += "Mot.prorrog.tit: " + ::MotProrTit + chr (13) + chr (10)
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

return


// --------------------------------------------------------------------------
// Faz exportacao da pilha de chamadas para uma string.
static function _PCham ()
	local _i      := 3  // Inicia em 3 por que nao quero pegar o nome da funcao interna GRAVA()
	local _sPilha := ""
	do while procname (_i) != ""
		_sPilha += procname (_i) + "=>"
		_i++
	enddo
return _sPilha


// --------------------------------------------------------------------------
// Busca o tipo do campo
static Function BuscaTipo(_sCampo)
	local _sRet := ""

	_sRet:= type("M->" + _sCampo) 

return _sRet


// --------------------------------------------------------------------------
// Tratamento para gerar o atributo Origem.
static function _Origem (_sOrigDef)
return left (iif (empty (_sOrigDef), _PCham (), _sOrigDef), TamSX3 ("ZN_ORIGEM") [1])
