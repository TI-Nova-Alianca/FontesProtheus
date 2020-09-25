// Programa:  ClsCTe
// Autor:     Robert Koch
// Data:      21/09/2015
// Descricao: Declaracao de classe de representacao de um conhecimento de transporte eletronico (CT-e).
//            Criado com base na classe ClsNFe, que comportava tanto NF-e como CT-e.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 16/11/2015 - Robert - Aumentados tratamentos para a tag TOMA03.
// 15/07/2016 - Robert - Criadas tags de valor de ICMS e valor total.
// 07/03/2017 - Catia  - Leitura da TAG valor total = ::vTPrest
// 17/07/2017 - Robert - Passa a contemplar também a tag TOMA3 e não apenas TOMA03.
// 25/07/2017 - Robert - Tag <rec> pode vir tambem como <receb>.
// 01/09/2017 - Catia  - Leitura da TAG (TOMA4) que nao existia - prioriza a TOMA3, se nao existir busca a TOMA4
// 21/03/2018 - Catia  - alterada leitura da TAG que le as notas referenciadas nos CTE's
// 06/08/2018 - Catia  - dava erro quando tomador=1 e devia buscar os dados do expedido
// 22/10/2018 - Catia  - alterado para que monte certo o campo TIPONF dos CTE's - verificando as notas referenciadas
// 22/03/2019 - Catia  - tinha ficado um show array aberto

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsCTe ()
return

// ==========================================================================
CLASS ClsCTe

	// Declaracao das propriedades da Classe
	data Ambiente
	data Avisos
	data CNPJDestin
	data CNPJEmiten
	data Chave
	data CliFor
	data Doc
	data DtEmissao
	data vTPrest
	data chaveRel
//	data chave
	data Erros
	data ItCFOP
	data ItVlICM
	data ItVlTot
	data Loja
	data NomeCliFor
	data NomeDestin
	data NomeEmiten
	data Serie
	data StatusZZX
	data TipoDoc
	data TipoNF
	data XML
	data XMLLayout

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD LeXML ()
ENDCLASS

// --------------------------------------------------------------------------
// Construtor.
METHOD New (_sLayout) Class ClsCTe

	// Inicializa atributos
	::Ambiente   = ''
	::XML        = NIL
	::Chave      = ''
	::Doc        = ""
	::Serie      = ""
	::CNPJEmiten = ''
	::NomeEmiten = ''
	::CNPJDestin = ''  //_sCNPJDst
	::NomeDestin = ''
	::TipoDoc    = ''
	::TipoNF     = ''
	::Erros      = {}
	::StatusZZX  = ''
	::XMLLayout  = iif (_sLayout == NIL, '', _sLayout)
	::Avisos     = {}
	::CliFor     = ''
	::Loja       = ''
	::NomeCliFor = ''
	::DtEmissao  = ctod ('')
	::ItCFOP     = {}
	::ItVlICM    = {}
	::ItVlTot    = {}
	::ChaveRel   = {}
Return ::self

// --------------------------------------------------------------------------
// Leitura do 'XML interno' de um arquivo XML recebido de fornecedor.
METHOD LeXML (_oObjPai) Class ClsCTe
	local _nDet     := 0
	local _nTamDoc  := TamSX3 ('ZZX_DOC')[1]
	local _aAreaSM0 := {}
	local _sTomador := ""
	local i			:= 0

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if len (::Erros) == 0
		if ! ::XMLLayout $ 'procCTe/CTe'
			aadd (::Erros, "Layout '" + ::XMLLayout + "' desconhecido na classe " + GetClassName (::Self))
		endif
	endif

	if len (::Erros) == 0
		if substr (::XML:_Id:TEXT, 1, 3) == "CTe"
			::Chave  = substr (::XML:_Id:TEXT, 4)
		else
			::Chave  = ::XML:_Id:TEXT
		endif
		if empty (::Chave)
			aadd (::Erros, "Layout '" + ::XMLLayout + "' desconhecido na identificacao da chave durante a leitura do 'XML interno' na classe " + GetClassName (::Self))
		endif
	endif
	
	if len (::Erros) == 0
		::Serie      = ::XML:_ide:_serie:TEXT
		if valtype (XmlChildEx (::XML:_emit, '_CNPJ')) == "O"
			::CNPJEmiten = ::XML:_emit:_CNPJ:TEXT
		elseif valtype (XmlChildEx (::XML:_emit, '_CPF')) == "O"
			::CNPJEmiten = ::XML:_emit:_CPF:TEXT
		endif
		::NomeEmiten = ::XML:_emit:_xNome:TEXT
		::TipoDoc   = "CTE"
		::Doc       = padl (alltrim (::XML:_ide:_nCT:TEXT), _nTamDoc, '0')
		if valtype (XmlChildEx (::XML:_ide, '_DEMI')) == "O"
			::DtEmissao = stod (strtran (::XML:_ide:_dEmi:TEXT, '-', ''))
		elseif valtype (XmlChildEx (::XML:_ide, '_DHEMI')) == "O"
			::DtEmissao = stod (strtran (left (::XML:_ide:_dhEmi:TEXT, 10), '-', ''))
		endif

		// Verifica quem eh o tomador do servico.
		// Se tiver a tag <toma03> com o valor "0" considera o CNPJ do remetente <rem>
		// Se tiver a tag <toma03> com o valor "1" considera o CNPJ do expedidor <exped>
		// Se tiver a tag <toma03> com o valor "2" considera o CNPJ do recebedor <receb>
		// Se tiver a tag <toma03> com o valor "3" considera o CNPJ do destinatário <dest>
		// Se tiver a tag <toma4> considera o CNPJ da própria TAG
		_sTomador = ""
		if valtype (XmlChildEx (::XML:_ide, '_TOMA03')) == "O"
			_sTomador = ::XML:_ide:_toma03:_toma:TEXT
		elseif valtype (XmlChildEx (::XML:_ide, '_TOMA3')) == "O"  // Em 17/07/2017 recebi um arquivo assim, valido do SEFAZ, etc...
			_sTomador = ::XML:_ide:_toma3:_toma:TEXT
		endif
		if ! empty (_sTomador)
			do case
			case _sTomador == "0"  // Remetente
				::CNPJDestin = ::XML:_rem:_CNPJ:TEXT
				::NomeDestin = ::XML:_rem:_xNome:TEXT
			case _sTomador == "1"  // Expedidor
				::CNPJDestin = ::XML:_exped:_CNPJ:TEXT
				::NomeDestin = ::XML:_exped:_xNome:TEXT
			case _sTomador == "2"  // Recebedor
				if valtype (XmlChildEx (::XML, '_REC')) == "O"
					::CNPJDestin = ::XML:_rec:_CNPJ:TEXT
					::NomeDestin = ::XML:_rec:_xNome:TEXT
				elseif valtype (XmlChildEx (::XML, '_RECEB')) == "O"
					::CNPJDestin = ::XML:_receb:_CNPJ:TEXT
					::NomeDestin = ::XML:_receb:_xNome:TEXT
				endif
			case _sTomador == "3"  // Destinatario
				::CNPJDestin = iif (valtype (XmlChildEx (::XML:_dest, '_CNPJ')) == "O", ::XML:_dest:_CNPJ:TEXT, ::XML:_dest:_CPF:TEXT)
				::NomeDestin = ::XML:_dest:_xNome:TEXT
			otherwise
				aadd (::Erros, "Tag do TOMADOR tem conteudo sem tratamento na classe " + GetClassName (::Self))
			endcase
		else
			// tenta ler a tag toma4
			if valtype (XmlChildEx (::XML:_ide, '_TOMA4')) == "O"
				_sTomador = ::XML:_ide:_toma4:_toma:TEXT
			endif
			// se conseguir ler conteudo na tag TOMA4 assume o CNPJ informado nessa tag
			if ! empty (_sTomador)
				// se nao achar nada na TAG TOMA 4 assume que não tem tomador como ja fazia
				::CNPJDestin = ::XML:_ide:_toma4:_CNPJ:TEXT
				::NomeDestin = ::XML:_ide:_toma4:_xNome:TEXT
			else
				u_log ('nao tem TOMADOR')
				::CNPJDestin = ::XML:_rem:_CNPJ:TEXT
				::NomeDestin = ::XML:_rem:_xNome:TEXT
			endif				
		endif
		aadd (::ItCFOP,  ::XML:_ide:_CFOP:TEXT)
		aadd (::ItVlTot, val (::XML:_vPrest:_vTPrest:TEXT))
		if valtype (XmlChildEx (::XML:_vPrest, '_VPREST')) == "O"
			aadd (::vTPrest, val (::XML:_vPrest:_vTPrest:TEXT))
		endif
		
		//u_log ('_vPrest:', valtype (XmlChildEx (::XML, '_VPREST')))
		//u_log ('_vTPrest:', valtype (XmlChildEx (::XML:_vPrest, '_VTPREST')))
		//u_log ('_infCTeNorm:', valtype (XmlChildEx (::XML, '_INFCTENORM')))
		
		/*
		msgalert ('_infCTeNorm:', valtype (XmlChildEx (::XML, '_INFCTENORM')))
		msgalert ('_infCTeNorm:_infDoc:', valtype (XmlChildEx (::XML:_infCTeNorm, '_INFDOC')))
		msgalert ('_infCTeNorm:_infDoc:_infNfe:', valtype (XmlChildEx (::XML:_infCTeNorm:_infDoc, '_INFNFE')))
		msgalert ('_infCTeNorm:_infDoc:_infNfe:_chave', valtype (XmlChildEx (::XML:_infCTeNorm:_infDoc:_infNFe, '_CHAVE')))
		*/
		
		if valtype (XmlChildEx (::XML, '_INFCTENORM')) == "O"
			if valtype (XmlChildEx (::XML:_infCTeNorm, '_INFDOC')) == "O"
				if valtype (XmlChildEx (::XML:_infCTeNorm:_infDoc, '_INFNFE')) == "O"
					if valtype (XmlChildEx (::XML:_infCTeNorm:_infDoc:_infNFe, '_CHAVE')) == "O"
						aadd (::chaveRel, ::XML:_infCTeNorm:_infDoc:_infNFe:_chave:TEXT)
					endif
				elseif valtype (XmlChildEx (::XML:_infCTeNorm:_infDoc, '_INFNFE')) == "A"
					for i = 1 to len (::XML:_infCTeNorm:_infDoc:_infNFe)
						aadd (::chaveRel, ::XML:_infCTeNorm:_infDoc:_infNFe[i]:_chave:TEXT)
					next										
				endif
			endif
		endif
		
		if valtype (XmlChildEx (::XML:_imp, '_ICMS')) == "O" .and. valtype (XmlChildEx (::XML:_imp:_ICMS, '_ICMS00')) == "O"
			aadd (::ItVlICM, val (::XML:_imp:_ICMS:_ICMS00:_vICMS:TEXT))
		else
			aadd (::ItVlICM, 0)
		endif
	endif
	
	// Verifica cadastro do fornecedor (transportadora).
	if len (::Erros) == 0
		sa2 -> (dbsetorder (3))  // A2_FILIAL+A2_CGC
		if ! sa2 -> (dbseek (xfilial ("SA2") + ::CNPJEmiten, .F.))
			aadd (::Avisos, "Fornecedor com CNPJ '" + ::CNPJEmiten + "' nao encontrado no cadastro.")
		else
			::CliFor     = sa2 -> a2_cod
			::Loja       = sa2 -> a2_loja
			::NomeCliFor = sa2 -> a2_nome
		endif
		::TipoNF = 'N' // em teoria temos mais fretes sobre saidas
		// verifica notas referenciadas para verificar se eh um frete sobre compras
		//u_showarray(::ChaveRel)
		for i = 1 to len (::ChaveRel)
		_wchave  = ::ChaveRel [i]
			//u_help("Testa CGC base")
			if ! '88612846' $ _wchave
			 	u_help = 'Entrou no IF'
				::TipoNF = 'C'
				exit
			endif			
		next
						
	endif

	// Habilitar as linhas abaixo para verificar os atributos da classe:
	
	u_logFim (GetClassName (::Self) + '.' + procname ())
return (len (::Erros) == 0)