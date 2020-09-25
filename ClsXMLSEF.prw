// Programa:  ClsXMLSEF
// Autor:     Robert Koch
// Data:      30/08/2012
// Descricao: Declaracao de classe de representacao de XML da SEFAZ (NF-e, CT-e, CC-e, etc.), para utilidades diversas.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 24/08/2013 - Robert - Passa a receber parametro opcional de empresa e filial no metodo ConsChv.
// 04/07/2014 - Robert - Passa a validar insc. estadual junto com CNPJ para buscar entidade no SPED001.
// 23/07/2014 - Robert - Criado metodo Chave050.
// 12/02/2015 - Robert - criado metodo ConsAutori, buscando da tabela SPED050, pois o metodo ConsChv parou
//                       de funcionar apos a atualizacao do TSS 2.27 para 2.42
// 02/04/2015 - Catia  - Metodo ConsAutori() quando nao existia a nota estava retornar .F. alerado para ""
// 24/04/2015 - Robert - Criado metodo ConsAtuFP ().
// 16/06/2015 - Robert - Melhorias tratamento layouts de notas de servicos, melhoria testes layout procNFe.
// 03/07/2015 - Robert - Criado atributo ::Ambiente.
// 21/09/2015 - Robert - Classe renomeada de ClsNFe para ClsXMLSEF por que passa a contemplar mais que apenas a NF-e.
// 15/10/2015 - Robert - Criado tratamento para evento de cancelamento de CTe.
// 08/12/2015 - Catia  - tratamento na importacao de um XML referente a CTE onde não somos tomador do frete.
// 10/12/2015 - Catia  - alteracao no email enviado sobre nao ser o tomador e gravar campo memo para desconsiderar da pendencia de XML a baixar  
// 05/01/2016 - Robert - Executa a funcao VerSF1 somente quando existir o objeto _oCTe
// 28/07/2016 - Robert - Possibilidade de tag RetEvento separada da InfEvento.
// 28/11/2016 - Robert - XML do CTe passou a vir com tag <procCTe> em vez de <cteProc>
// 07/11/2018 - Catia  - Alterado a leitura da versao dos XML layout <procNFe> que estava pegando a versao errada nas nossas notas de transferencia
 
#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsXMLSEF ()
return


// ==========================================================================
CLASS ClsXMLSEF

	// Declaracao das propriedades da Classe
	data Chave
	data CNPJDestin
	data CNPJEmiten
	data CTe
	data XMLLayout
	data XMLVersao
	data NFSe
	data NFe
	data EventoNFe
	data Erros
	data Avisos
	data Ambiente
	data FilDest
	data OrigArq

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD LeXML ()
	METHOD VerFilDst ()
ENDCLASS



// --------------------------------------------------------------------------
// Construtor.
METHOD New () Class ClsXMLSEF
	::Chave      = ""
	::CNPJDestin = ""
	::CTe        = NIL
	::XMLLayout  = ""
	::XMLVersao  = ""
	::NFe        = NIL
	::EventoNFe  = NIL
	::Erros      = {}
	::Avisos     = {}
	::Ambiente   = ""
		
Return ::self



// --------------------------------------------------------------------------
// Extrai os dados principais do XML.
METHOD LeXML (_sXMLOri) Class ClsXMLSEF
	local _sUTF8     := ""
	local _sError    := ''
	local _sWarning  := ''
	local _oEvento   := NIL
//	local _oRetEvt   := NIL
	local _nErro     := 0
	local _nAviso    := 0
	local _oNFe      := NIL
	local _oNFSe     := NIL
	local _oCTe      := NIL
	private _oXML := NIL  // Tenho certeza de que eu usava 'local', mas nao funciona mais...

//	u_logIni (GetClassName (::Self) + '.' + procname ())
	
	// Verifica o Layout (tipo de documento XML) e gera array com as partes (subniveis)
	// do XML que interessam. Por exemplo, o layout 'NFe' eh semelhante ao subnivel 'NFe'
	// do layout 'nfeProc'.
	// Layout			Versão	Descrição
	// NFe				2.00	Leiaute da NF-e.
	// enviNFe			2.00	Mensagem de envio de lote de NF-e.
	// retEnviNFe		2.00	Mensagem de retorno do envio de lote de NF-e.
	// consReciNFe		2.00	Mensagem de consulta processamento do lote de NF-e transmitida.
	// retconsReciNFe	2.00	Mensagem de retorno da consulta de processamento do lote de NF-e.
	// procNFe			2.00	Leiaute de compartilhamento da NF-e.
	// cancNFe			2.00	Mensagem de solicitação de cancelamento da NF-e.
	// retCancNFe		2.00	Mensagem de retorno da solicitação de cancelamento da NF-e.
	// procCancNFe		2.00	Leiaute de compartilhamento de Pedido de cancelamento de NF-e
	// inutNFe			2.00	Mensagem de solicitação de inutilização de numeração de NF-e.
	// retInutNFe		2.00	Mensagem de retorno da solicitação de inutilização de numeração de NF-e.
	// procInutNFe		2.00	Leiaute de compartilhamento de pedido de inutilização de numeração de NF-e
	// consSitNFe		2.01	Mensagem de consulta da situação atual da NF-e.
	// retconsSitNFe	2.00	Mensagem de retorno da consulta da situação atual da NF-e.
	// consStatServ		2.00	Mensagem da consulta do status do serviço de autorização de NF-e.
	// retConsStatServ	2.00	Mensagem de retorno da consulta do status do serviço de autorização de NF-e.
	// consCad			2.00	Mensagem de consulta ao cadastro de contribuintes do ICMS.	
	// retConsCad		2.00	Mensagem de retorno da consulta ao cadastro de contribuintes do ICMS.

//	u_log ('XML original:', _sXMLOri)
	if empty (_sXMLOri)
		aadd (::Erros, "XML vazio")
	endif

	// Converte para conjunto de caracteres padrao (remove letras acentuadas, etc.).
	// Se retornar vazio, tenta manter o formato original.
	if len (::Erros) == 0
		_sUTF8 = EncodeUTF8 (_sXMLOri)
		if ! empty (_sUTF8)

			// Em alguns casos a conversao para UTF-8 aparecem caracteres especiais no inicio da string...
			if upper (substr (_sUTF8, 7, 1)) == '<'
				_sUTF8 = substring (_sUTF8, 7, len (_sUTF8))
			endif
			_sXMLOri = _sUTF8
		endif
	endif

	// Cria objeto XML para leitura dos dados.
	if len (::Erros) == 0
		_oXML := XmlParser(_sXMLOri, "_", @_sError, @_sWarning )
		If !Empty (_sError)
			aadd (::Erros, "CONTEUDO XML INVALIDO - Error: " + _sError)
		EndIf
		If !Empty (_sWarning)
			aadd (::Erros, "CONTEUDO XML INVALIDO - Warning: " + _sWarning)
		EndIf
	endif
	
	// Extrai dados principais do XML
	if len (::Erros) == 0
		do case
		case type ("_oXML:_nfeProc") == "O" // Layout de compartilhamento da NF-e.
			::XMLLayout = 'procNFe'
			::XMLVersao = _oXML:_nfeProc:_NFe:_infNfe:_versao:TEXT
			
			_oNFe  := ClsNFe ():New ()
			_oNFe:XMLLayout = ::XMLLayout
			_oNFe:XML       = _oXML:_nfeProc:_NFe:_infNfe
			
		case type ("_oXML:_NFe") == "O"  // Layout da NF-e.
			::XMLLayout = 'NFe'
			::XMLVersao = _oXML:_NFe:_infNfe:_versao:TEXT
			
			_oNFe  := ClsNFe ():New ()
			_oNFe:XMLLayout = ::XMLLayout
			_oNFe:XML       = _oXML:_NFe:_infNfe
			
		case type ("_oXML:_enviNFe") == "O"  // Mensagem de envio de lote de NF-e.
			::XMLLayout = 'enviNFe'
			::XMLVersao = _oXML:_enviNFe:_versao:TEXT

			// Este tipo de documento pode ter mais de uma nota, mas considerarei apenas a primeira.
			if valtype (_oXML:_enviNFe:_NFe) == "A"  // Mais de uma nota
				if type ("_oXML:_enviNFe:_NFe[1]:_ide") == "O"
					_oNFe  := ClsNFe ():New ()
					_oNFe:XMLLayout = ::XMLLayout
					_oNFe:XML       = _oXML:_enviNFe:_NFe[1]
				elseif type ("_oXML:_enviNFe:_NFe[1]:_infNFe") == "O"
					_oNFe  := ClsNFe ():New ()
					_oNFe:XMLLayout = ::XMLLayout
					_oNFe:XML       = _oXML:_enviNFe:_NFe[1]:_infNFe
				endif
			else
				if type ("_oXML:_enviNFe:_NFe:_ide") == "O"
					_oNFe  := ClsNFe ():New ()
					_oNFe:XMLLayout = ::XMLLayout
					_oNFe:XML       = _oXML:_enviNFe:_NFe
				elseif type ("_oXML:_enviNFe:_NFe:_infNFe") == "O"
					_oNFe  := ClsNFe ():New ()
					_oNFe:XMLLayout = ::XMLLayout
					_oNFe:XML       = _oXML:_enviNFe:_NFe:_infNFe
				endif
			endif
	
		case type ("_oXML:_cteProc") == "O" // Conhecimento de frete
			::XMLLayout = 'procCTe'
			::XMLVersao = _oXML:_cteProc:_versao:TEXT
			_oCTe      := ClsCTe ():New (::XMLLayout)
			_oCTe:XML   = _oXML:_cteProc:_CTe:_infCte
	
		case type ("_oXML:_procCTe") == "O" // Conhecimento de frete
			::XMLLayout = 'procCTe'
			::XMLVersao = _oXML:_procCTe:_versao:TEXT
			_oCTe      := ClsCTe ():New (::XMLLayout)
			_oCTe:XML   = _oXML:_procCTe:_CTe:_infCte

		case type ("_oXML:_CTe") == "O"  // Conhecimento de frete
			::XMLLayout = 'CTe'
			::XMLVersao = _oXML:_CTe:_infCte:_versao:TEXT
			_oCTe      := ClsCTe ():New (::XMLLayout)
			_oCTe:XML   = _oXML:_CTe:_infCte
	
		case type ("_oXML:_resultadoConsulta") == "O"
			aadd (::Erros, "CONTEUDO XML INVALIDO: NAO CONTEM DADOS NFE - SOMENTE CONSULTA")
	
		case type ("_oXML:_procCancNFe") == "O"
			::XMLLayout = "cancNFe"
			::XMLVersao = _oXML:_procCancNfe:_versao:TEXT


		// Verifica se eh um evento de CT-e
		case type ("_oXML:_procEventoCTe") == "O"
			::XMLLayout  = "procEventoCTe"
			::XMLVersao  = _oXML:_procEventoCTe:_versao:TEXT

			// Identifica evento e retorno (no caso de eventos, tem-se duas tags principais: Evento e retEvento).
			do case
			case type ("_oXML:_procEventoCTe:_eventoCTe:_InfEvento") == "O"
				_oEvento := ClsXmlEvt ():New (::XMLLayout)
				_oEvento:XMLEvento  = _oXML:_ProcEventoCte:_eventoCTe:_InfEvento
				_oEvento:XMLRetorno = _oXML:_ProcEventoCte:_retEventoCTe:_infEvento

			otherwise
				aadd (::Erros, "Layout de EVENTO desconhecido neste XML")
			endcase

		// Verifica se eh um evento de NF-e
		case type ("_oXML:_procEventoNFe") == "O"
			::XMLLayout  = "procEventoNFe"
			::XMLVersao  = _oXML:_procEventoNFe:_versao:TEXT

			// Identifica evento e retorno (no caso de eventos, tem-se duas tags principais: Evento e retEvento).
			do case
			case type ("_oXML:_procEventoNFe:_Evento:_InfEvento") == "O"
				_oEvento := ClsXmlEvt ():New (::XMLLayout)
				_oEvento:XMLEvento  = _oXML:_ProcEventoNfe:_Evento:_InfEvento
				_oEvento:XMLRetorno = _oXML:_ProcEventoNfe:_retEvento:_infEvento

			case type ("_oXML:_procEventoNFe:_Evento:_EnvEvento") == "O"
				_oEvento := ClsXmlEvt ():New (::XMLLayout)
				_oEvento:XMLEvento  = _oXML:_ProcEventoNfe:_Evento:_EnvEvento:_Evento:_InfEvento
				_oEvento:XMLRetorno = _oXML:_ProcEventoNfe:_retEvento:_retEnvEvento:_retEvento:_infEvento

			case type ("_oXML:_procEventoNFe:_EnvEvento") == "O"
				_oEvento := ClsXmlEvt ():New (::XMLLayout)
				_oEvento:XMLEvento  = _oXML:_ProcEventoNfe:_EnvEvento:_Evento:_InfEvento
				if type ("_oXML:_procEventoNFe:_RetEvento") == "O" .and. type ("_oXML:_ProcEventoNfe:_RetEvento:_InfEvento") == "O"
					_oEvento:XMLRetorno = _oXML:_ProcEventoNfe:_RetEvento:_InfEvento
				else
					_oEvento:XMLRetorno = _oXML:_ProcEventoNfe:_EnvEvento:_Evento:_InfEvento
				endif
			otherwise
				aadd (::Erros, "Layout de EVENTO desconhecido neste XML")
			endcase
			

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case type ("_oXML:_nota:_enfs_notafisc") == "O"
			::XMLLayout = 'NFS-e'
			_oNFSe := ClsNFSe ():New (::XMLLayout)
			_oNFSe:XML = _oXML

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case type ("_oXML:_ConsultarNfseResposta:_ListaNfse") == 'O'
			::XMLLayout = 'ConsultaNFS-e'
			_oNFSe := ClsNFSe ():New (::XMLLayout)
			_oNFSe:XML := _oXML

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case type ("_oXML:_GovDigital:_emissao:_nf_e:_prestacao") == 'O'  // Tag "nf-e" eh alterada para "nf_e" pelo parser.
			::XMLLayout = 'GovDigital'
			_oNFSe := ClsNFSe ():New (::XMLLayout)
			_oNFSe:XML = _oXML

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case type ("_oXML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse") == 'O'
			::XMLLayout = 'ConsNFSeRps'
			_oNFSe := ClsNFSe ():New (::XMLLayout)
			_oNFSe:XML = _oXML

		otherwise
			aadd (::Erros, "Layout de XML desconhecido na classe " + GetClassName (::Self))
			u_help ('Layout desconhecido:', _sXMLOri)
		endcase
	endif

	// Se chegou ateh aqui, extrai os dados do 'XML interno'.
	if len (::Erros) == 0
		do case
		case valtype (_oNFe) == 'O'  // Arquivo contem dados de nota fiscal.
			_oNFe:LeXML (::Self)
			::NFe = _oNFe  // O atributo local ::NFe recebe um ponteiro para o objeto 'nota interna'.
			for _nAviso = 1 to len (_oNFe:Avisos)
				aadd (::Avisos, _oNFe:Avisos [_nAviso])
			next
			for _nErro = 1 to len (_oNFe:Erros)
				aadd (::Erros, _oNFe:Erros [_nErro])
			next
			::Ambiente   = _oNFe:Ambiente
			::Chave      = _oNFe:Chave
			::CNPJDestin = _oNFe:CNPJDestin
			::CNPJEmiten = _oNFe:CNPJEmiten

		case valtype (_oCTe) == 'O'  // Arquivo contem dados conhecimento de transporte.
			_oCTe:LeXML (::Self)
			::CTe = _oCTe  // O atributo local ::CTe recebe um ponteiro para o objeto 'conhecimento de transporte'.
			for _nAviso = 1 to len (_oCTe:Avisos)
				aadd (::Avisos, _oCTe:Avisos [_nAviso])
			next
			for _nErro = 1 to len (_oCTe:Erros)
				aadd (::Erros, _oCTe:Erros [_nErro])
			next
			::Ambiente   = _oCTe:Ambiente
			::Chave      = _oCTe:Chave
			::CNPJDestin = _oCTe:CNPJDestin
			::CNPJEmiten = _oCTe:CNPJEmiten

		case valtype (_oNFSe) == 'O'  // Arquivo contem dados de nota fiscal.
			_oNFSe:LeXML (::Self)
			::NFSe = _oNFSe  // O atributo local ::NFSe recebe um ponteiro para o objeto 'nota de servico interna'.
			for _nAviso = 1 to len (_oNFSe:Avisos)
				aadd (::Avisos, _oNFSe:Avisos [_nAviso])
			next
			for _nErro = 1 to len (_oNFSe:Erros)
				aadd (::Erros, _oNFSe:Erros [_nErro])
			next
			::Ambiente   = _oNFSe:Ambiente
			::Chave      = _oNFSe:Chave
			::CNPJDestin = _oNFSe:CNPJDestin
			::CNPJEmiten = _oNFSe:CNPJEmiten

		case valtype (_oEvento) == 'O'  // Arquivo contem dados de evento de NFe / CTe.
			_oEvento:LeXML (::Self)
			::EventoNFe = _oEvento  // O atributo local ::EventoNFe recebe um ponteiro para o objeto evento.
			for _nAviso = 1 to len (_oEvento:Avisos)
				aadd (::Avisos, _oEvento:Avisos [_nAviso])
			next
			for _nErro = 1 to len (_oEvento:Erros)
				aadd (::Erros, _oEvento:Erros [_nErro])
			next
			::Ambiente   = _oEvento:Ambiente
			::Chave      = _oEvento:Chave
			::CNPJDestin = _oEvento:CNPJDestin
			::CNPJEmiten = _oEvento:CNPJEmiten

//			u_log ('Objeto ' + GetClassName (::Self) + ':')
//			u_log (ClassDataArr (::self))

		otherwise
			aadd (::Erros, "Nao identifiquei nenhuma informacao util neste XML.")
		endcase
		
	endif

	// Verifica se o destinatario eh outra filial do sistema ou mesmo outra empresa.
	if len (::Erros) == 0
		::FilDest = ''
		if alltrim (::CNPJDestin) == alltrim (sm0 -> m0_cgc)
			::FilDest = cFilAnt
		else
			u_log ('Nao eh para o CNPJ atual do SM0')
			dbselectarea ("SM0")
			_aAreaSM0 = getarea ()
			sm0 -> (dbgotop ())
			do while ! sm0 -> (eof ())
				if alltrim (::CNPJDestin) == alltrim (sm0 -> m0_cgc)
					::FilDest = sm0 -> m0_codfil
					exit
				endif
				sm0 -> (dbskip ())
			enddo
			restarea (_aAreaSM0)
			if empty (::FilDest)
				//u_log (valtype (::CNPJDestin))
				//u_log (valtype (::CNPJEmiten))
				aadd (::Erros, "Arquivo XML destina-se ao CNPJ/CPF '" + ::CNPJDestin + "'. CNPJ emitente: '" + ::CNPJEmiten + "'")
				
				if valtype (_oCTe) == 'O'  // Arquivo contem dados conhecimento de transporte.
					_VerSF1(_oCTe:Chave)
				endif
			endif
		endif
	endif

	// Habilitar a linha abaixo para verificar os atributos da classe:
	//u_log ('Objeto ' + GetClassName (::Self) + ':')
	//u_log (ClassDataArr (::self))

	if len (::Avisos) > 0
		u_log ('Avisos:', ::Avisos)
	endif
	if len (::Erros) > 0
		u_log ('Erros:', ::Erros)
	endif
//	u_logFim (GetClassName (::Self) + '.' + procname ())
return (len (::Erros) == 0)


// --------------------------------------------------------------------------
// Verifica se ja existe o documento digitado no SF1  
static function _VerSF1(_wchave)

	// verifica se o DOC ja esta digitado
	_sSQL := ""
    _sSQL += " SELECT F1_FILIAL"
   	_sSQL += "      , SF1.F1_DOC"
   	_sSQL += "      , SA2.A2_NOME"
   	_sSQL += "      , SF1.F1_EMISSAO"
   	_sSQL += "      , SF1.F1_DTDIGIT"
   	_sSQL += "      , SF1.F1_VALBRUT"
   	_sSQL += "      , SF1.F1_CHVNFE"
   	_sSQL += "   FROM SF1010 AS SF1"
   	_sSQL += "   	INNER JOIN SA2010 AS SA2"
   	_sSQL += " 		  ON(SA2.D_E_L_E_T_ = ''"
   	_sSQL += " 		     AND SA2.A2_COD = SF1.F1_FORNECE)"
   	_sSQL += "  WHERE SF1.F1_CHVNFE = '" + alltrim(_wchave) + "'"
   	_sSQL += "    AND SF1.D_E_L_E_T_ = ''"
    
	aDados := U_Qry2Array(_sSQL)
	
	if len (aDados) > 0
		
		_aCols = {}
		aadd (_aCols, {'Filial'        ,    'left'  ,  ''})
		aadd (_aCols, {'CTe'           ,    'left'  ,  ''})
		aadd (_aCols, {'Fornecedor'    ,    'left'  ,  ''})
	   	aadd (_aCols, {'Dt.Emissao'    ,    'left'  ,  ''})
	   	aadd (_aCols, {'Dt.Digitação'  ,    'left'  ,  ''})
	   	aadd (_aCols, {'Valor'         ,    'right' ,  '@E 9,999,999.99'})
	   	aadd (_aCols, {'Chave CTe'     ,    'left'  ,  ''})
			    	   
	   	_oSQL := ClsSQL():New ()
	   	_oSQL:_sQuery := _sSQL  
	   	//u_log (_oSQL:_sQuery)
	   	if len (_oSQL:Qry2Array (.T., .F.)) > 0
    		_sMsg = _oSQL:Qry2HTM ("ERRO - CTe digitado no sistema porém, nao somos o tomador do frete.", _aCols, "", .F.)
    		
    		U_ZZUNU ({'036'}, "Verificar/Tratar: no FINANEIRO; Se ainda Pendente/BAIXAR documento por 'REVERSAO'", _sMsg, .F., cEmpAnt, cFilAnt, "") // setor financeiro
    		U_ZZUNU ({'019'}, "Verificar/Tratar: no FINANEIRO; Se ainda Pendente/BAIXAR documento por 'REVERSAO'", _sMsg, .F., cEmpAnt, cFilAnt, "") // setor fiscal
    		
    		_sSQL := ""
			_sSQL += " UPDATE SF1010"
			_sSQL += "    SET F1_MENNOTA = '858879'" // Memo que identifica que nao somos o tomador do frete - para desconsiderar nos XML's a baixar
			_sSQL += "  WHERE F1_CHVNFE  = '" + alltrim(_wchave) + "'"
			_sSQL += "    AND D_E_L_E_T_ = ''"
		
			if TCSQLExec (_sSQL) < 0
            	u_showmemo(_sSQL)
            	return
        	endif            
	    	
		endif
		            		
	endif				
return
