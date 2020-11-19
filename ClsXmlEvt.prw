// Programa:  ClsXmlEvt
// Autor:     Robert Koch
// Data:      15/09/2015
// Descricao: Declaracao de classe de representacao de eventos de uma unica nota fiscal eletronica.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 15/10/2015 - Robert - Criado tratamento para evento de cancelamento de CTe.
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsXmlEvt ()
return



// ==========================================================================
CLASS ClsXmlEvt

	// Declaracao das propriedades da Classe
	data Ambiente
	data XMLEvento
	data XMLRetorno
	data Chave
	data Doc
	data Serie
	data CNPJEmiten
	data NomeEmiten
	data CNPJDestin
	data NomeDestin
	data TipoDoc
	data Erros
	data Layout
	data TipoEvento
	data SeqEvt
	data JustEvt
	data Avisos
	data CliFor
	data Loja
	data NomeCliFor
	data DtEmissao
	data RetSEFAZ
	data Protocolo

	// Declaracao dos Metodos da classe
	METHOD New () Constructor
	METHOD LeXML ()
ENDCLASS



// --------------------------------------------------------------------------
// Construtor.
METHOD New (_sLayout) Class ClsXmlEvt

	// Inicializa atributos
	::Ambiente   = ''
	::XMLEvento  = NIL
	::XMLRetorno = NIL
	::Chave      = ''
	::Doc        = ""
	::Serie      = ""
	::CNPJEmiten = ''
	::NomeEmiten = ''
	::CNPJDestin = ''
	::NomeDestin = ''
	::TipoDoc    = ''
	::Erros      = {}
	::Layout     = _sLayout
	::TipoEvento = ""
	::SeqEvt     = ""
	::JustEvt    = ""
	::Avisos     = {}
	::CliFor     = ''
	::Loja       = ''
	::NomeCliFor = ''
	::DtEmissao  = ctod ('')
	::RetSEFAZ   = ''
	::Protocolo  = ''
Return ::self



// --------------------------------------------------------------------------
// Leitura do 'XML interno' de um evento.
METHOD LeXML (_oObjPai) Class ClsXmlEvt
	//local _nDet     := 0
	//local _nTamDoc  := TamSX3 ('ZZX_DOC')[1]
	//local _aAreaSM0 := {}

	u_logIni (GetClassName (::Self) + '.' + procname ())

	// Leitura de dados da secao 'evento'.
	if len (::Erros) == 0
		if ::Layout == "procEventoNFe"
			::Chave      = ::XMLEvento:_ChNfe:TEXT
		elseif ::Layout == "procEventoCTe"
			::Chave      = ::XMLEvento:_chCTe:TEXT
		endif
		::Serie      = ""
		::CNPJEmiten = ::XMLEvento:_CNPJ:TEXT
		::NomeEmiten = ""
		if empty (::Chave)
			aadd (::Erros, "Layout '" + ::Layout + "' desconhecido na identificacao da chave durante a leitura do 'XML interno' na classe " + GetClassName (::Self))
		endif
	endif

	// Leitura de dados da secao 'Retorno do evento'.
	if len (::Erros) == 0
		::Ambiente   = ::XMLRetorno:_tpAmb:TEXT
		::RetSEFAZ   = ::XMLRetorno:_cStat:TEXT
		if XmlChildEx (::XMLRetorno, "_CNPJDEST") != NIL
			::CNPJDestin = ::XMLRetorno:_CNPJDest:TEXT
		endif
		::Protocolo  = ::XMLRetorno:_nProt:TEXT
	endif

	if len (::Erros) == 0
		::TipoEvento   = ::XMLEvento:_TpEvento:TEXT
		::SeqEvt  = ::XMLEvento:_nSeqEvento:TEXT
		::DtEmissao  = stod (strtran (::XMLEvento:_dhEvento:TEXT, '-', ''))
		if ::TipoEvento == "110110"  // Carta de correcao
			::JustEvt = ::XMLEvento:_DetEvento:_xCorrecao:TEXT
		elseif ::TipoEvento == "110111"  // Cancelamento
			if valtype (XmlChildEx (::XMLEvento:_detEvento, '_EVCANCCTE')) == "O"
				if valtype (XmlChildEx (::XMLEvento:_detEvento:_evCancCTe, '_XJUST')) == "O"
					::JustEvt = ::XMLEvento:_detEvento:_evCancCTe:_xJust:TEXT
				endif
			else
				::JustEvt = ::XMLEvento:_DetEvento:_xJust:TEXT
			endif
		endif
		if ::Layout == "procEventoNFe"
			::Serie      = substr(::XMLEvento:_ChNfe:TEXT,25,1)
			::Doc        = substr(::XMLEvento:_ChNfe:TEXT,26,9)
		elseif ::Layout == "procEventoCTe"
			::Serie      = substr(::XMLEvento:_ChCte:TEXT,25,1)
			::Doc        = substr(::XMLEvento:_ChCte:TEXT,26,9)
		endif
		if ::TipoEvento == "110110"
			::TipoDoc  := "CCe"
		elseif ::TipoEvento == "110111"
			::TipoDoc  := "Canc"
		else
			aadd (::Erros, "Tipo de evento '" + ::TipoEvento + "' desconhecido.")
		endif
	endif


	// Habilitar as linhas abaixo para verificar os atributos da classe:
	//u_log ('Objeto ' + GetClassName (::Self) + ':')
	//u_log (ClassDataArr (::self))

	u_logFim (GetClassName (::Self) + '.' + procname ())
return (len (::Erros) == 0)
