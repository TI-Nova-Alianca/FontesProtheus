// Programa:  ClsNFSe
// Autor:     Robert Koch
// Data:      09/07/2014
// Descricao: Declaracao de classe de representacao de uma unica nota fiscal eletronica.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 02/02/2015 - Robert - Passa a aceitar CPF no emitente.
// 16/06/2015 - Robert - Melhorias tratamento layouts de notas de servicos.
// 21/09/2015 - Robert - Classe renomeada de ClsXmlNF para ClsNFSe por que foram criadas classes especificas para eventos, CTe, etc. 

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsNFSe ()
return



// ==========================================================================
CLASS ClsNFSe

	// Declaracao das propriedades da Classe
	data Ambiente
	data Avisos
	data CNPJDestin
	data CNPJEmiten
	data Chave
	data CliFor
	data Doc
	data DtEmissao
	data Erros
	data ItCFOP
	data Loja
	data NomeCliFor
	data NomeDestin
	data NomeEmiten
	data Serie
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
METHOD New (_sLayout) Class ClsNFSe

	// Inicializa atributos
	::Ambiente   = ''
	::XML        = NIL
	::Chave      = ''
	::Doc        = ""
	::Serie      = ""
	::CNPJEmiten = ''
	::NomeEmiten = ''
	::CNPJDestin = ''
	::NomeDestin = ''
	::TipoDoc    = ''
	::TipoNF     = ''
	::Erros      = {}
	::XMLLayout  = iif (_sLayout == NIL, '', _sLayout)
	::Avisos     = {}
	::CliFor     = ''
	::Loja       = ''
	::NomeCliFor = ''
	::DtEmissao  = ctod ('')
	::ItCFOP     = {}
Return ::self



// --------------------------------------------------------------------------
// Leitura do 'XML interno' de um arquivo recebido de fornecedor.
METHOD LeXML (_oObjPai) Class ClsNFSe
	local _nDet     := 0
	local _nTamDoc  := TamSX3 ('ZZX_DOC')[1]
	//local _aAreaSM0 := {}
//	local _nErro    := 0
//	local _nAviso   := 0

	u_logIni (GetClassName (::Self) + '.' + procname ())

	// NF de servico nao tem chave (que eu saiba). Como nao conheco um padrao definido, vou criando um nome para cada novo layout que recebo.
	if len (::Erros) == 0
		if ::XMLLayout != 'NFS-e' .and. ::XMLLayout != 'ConsultaNFS-e' .and. ::XMLLayout != 'GovDigital' .and. ::XMLLayout != 'ConsNFSeRps'
			aadd (::Erros, "Layout '" + ::XMLLayout + "' desconhecido na classe " + GetClassName (::Self))
		endif
	endif

	if len (::Erros) == 0
		::Chave      = 'Nao se aplica'

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		do case
		case ::XMLLayout $ "NFS-e"
			::Doc        = padl (alltrim (::XML:_nota:_enfs_notafisc:_ennf_idnumero:TEXT), _nTamDoc, '0')
			::CNPJEmiten = ::XML:_nota:_enfs_prestado:_espr_cpf_cnpj:TEXT
			::NomeEmiten = ::XML:_nota:_enfs_prestado:_espr_razasoci:TEXT
			::CNPJDestin = ::XML:_nota:_enfs__tomador:_esto_cpf_cnpj:TEXT
			::NomeDestin = ::XML:_nota:_enfs__tomador:_esto_razasoci:TEXT
			::DtEmissao  = stod (strtran (left (::XML:_nota:_enfs_notafisc:_ennf_dataemis:TEXT, 10), '-', ''))

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case ::XMLLayout $ "ConsultaNFS-e"
			if XmlChildEx (::XML:_ConsultarNfseResposta:_ListaNfse, "_COMPLNFSE") != NIL
				::Doc        = padl (alltrim (::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_Numero:TEXT), _nTamDoc, '0')
				::DtEmissao  = stod (strtran (left (::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_DataEmissao:TEXT, 10), '-', ''))
				::CNPJEmiten = ::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_PrestadorServico:_IdentificacaoPrestador:_Cnpj:TEXT
				::NomeEmiten = ::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_PrestadorServico:_RazaoSocial:TEXT
				::CNPJDestin = ::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_TomadorServico:_IdentificacaoTomador:_CpfCnpj:_Cnpj:TEXT
				::NomeDestin = ::XML:_ConsultarNfseResposta:_ListaNfse:_ComplNfse:_Nfse:_InfNfse:_TomadorServico:_RazaoSocial:TEXT
			elseif XmlChildEx (::XML:_ConsultarNfseResposta:_ListaNfse, "_COMPNFSE") != NIL
				::Doc        = padl (alltrim (::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_Numero:TEXT), _nTamDoc, '0')
				::DtEmissao  = stod (strtran (left (::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DataEmissao:TEXT, 10), '-', ''))
				::CNPJEmiten = ::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_PrestadorServico:_IdentificacaoPrestador:_Cnpj:TEXT
				::NomeEmiten = ::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_PrestadorServico:_RazaoSocial:TEXT
				::CNPJDestin = ::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_TomadorServico:_IdentificacaoTomador:_CpfCnpj:_Cnpj:TEXT
				::NomeDestin = ::XML:_ConsultarNfseResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_TomadorServico:_RazaoSocial:TEXT
			endif

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case ::XMLLayout $ "GovDigital"
			::Doc        = padl (alltrim (::XML:_GovDigital:_emissao:_nf_e:_numero:TEXT), _nTamDoc, '0')  // Tag "nf-e" eh alterada para "nf_e" pelo parser.
			::CNPJEmiten = ::XML:_GovDigital:_emissao:_nf_e:_prestador:_documento:TEXT
			::NomeEmiten = ::XML:_GovDigital:_emissao:_nf_e:_prestador:_nome:TEXT
			::CNPJDestin = ::XML:_GovDigital:_emissao:_nf_e:_tomador:_documento:TEXT
			::NomeDestin = ::XML:_GovDigital:_emissao:_nf_e:_tomador:_nome:TEXT
			::DtEmissao  = stod (strtran (left (::XML:_GovDigital:_emissao:_nf_e:_prestacao:TEXT, 10), '-', ''))  // Acho que nao estah correto, mas nao encontrei outra tag melhor.

		// Esta secao fiz com base num XML que recebi, mas acho que para cada prefeitura vai ser diferente.
		case ::XMLLayout $ "ConsNFSeRps"
			::Doc        = padl (alltrim (::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_Numero:TEXT), _nTamDoc, '0')
			::CNPJEmiten = ::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DeclaracaoPrestacaoServico:_InfDeclaracaoPrestacaoServico:_Prestador:_CpfCnpj:_Cnpj:TEXT
			::NomeEmiten = ::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DeclaracaoPrestacaoServico:_InfDeclaracaoPrestacaoServico:_Prestador:_RazaoSocial:TEXT
			::CNPJDestin = ::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DeclaracaoPrestacaoServico:_InfDeclaracaoPrestacaoServico:_Tomador:_IdentificacaoTomador:_CpfCnpj:_Cnpj:TEXT
			::NomeDestin = ::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DeclaracaoPrestacaoServico:_InfDeclaracaoPrestacaoServico:_Tomador:_RazaoSocial:TEXT
			::DtEmissao  = stod (strtran (left (::XML:_ConsultarNfseRpsResposta:_ListaNfse:_CompNfse:_Nfse:_InfNfse:_DataEmissao:TEXT, 10), '-', ''))

		otherwise
			aadd (::Erros, "Layout '" + ::XMLLayout + "' desconhecido na identificacao de CNPJ durante a leitura do 'XML interno' na classe " + GetClassName (::Self))
		endcase
	endif

	// Tive casos de receber o CNPJ sem os zeros a esquerda.
	if ! empty (::CNPJEmiten)
		while len (::CNPJEmiten) < 14
			u_log ('Acrescentando zero a esquerda no CNPJ do emitente')
			::CNPJEmiten = '0' + ::CNPJEmiten
		enddo
	endif

//	// Especifico para notas de retorno do deposito - Coop. Nova Alianca.
//	if len (::Erros) == 0 .and. sm0 -> m0_cgc == '88612486000160' .and. ::CNPJEmiten $ '88612486000402/88612486001484/88612486001565'
		//u_log ('Retorno de deposito Alianca')
//		::TipoNF = "B"
//	else
		// Verifica tipo de documento atraves dos CFOP's da nota.
		::TipoNF = "N"  // A maioria eh normal.
		if ::TipoDoc == "NF"
			for _nDet = 1 to len (::ItCFOP)

				// Verifica se trata-se de CFOP de devolucao de clientes
				if substr (::ItCFOP [_nDet], 2, 3) $ "201/202/210/410/411/412/413/503/553/555/556/603/660/661/909/913/918/919"
					::TipoNF = "D"
					exit
				elseif substr (::ItCFOP [_nDet], 2, 3) $ "901/915"
					::TipoNF = "B"
					exit
				elseif substr (::ItCFOP [_nDet], 2, 3) $ "208/209/662/664/665/902/903/906/907/916/921/925"
					::TipoNF = "N"
					exit
				endif
			next
		endif
//	endif

	// Verifica cadastro do fornecedor ou cliente, conforme o caso.
	if len (::Erros) == 0
		if ::TipoNF == "N"
			sa2 -> (dbsetorder (3))  // A2_FILIAL+A2_CGC
			if ! sa2 -> (dbseek (xfilial ("SA2") + ::CNPJEmiten, .F.))
				aadd (::Avisos, "Fornecedor com CNPJ '" + ::CNPJEmiten + "' nao encontrado no cadastro.")
			else
				::CliFor     = sa2 -> a2_cod
				::Loja       = sa2 -> a2_loja
				::NomeCliFor = sa2 -> a2_nome
			endif
		else
			sa1 -> (dbsetorder (3))  // A1_FILIAL+A1_CGC
			if ! sa1 -> (dbseek (xfilial ("SA1") + ::CNPJEmiten, .F.))
				aadd (::Avisos, "Cliente com CNPJ '" + ::CNPJEmiten + "' nao encontrado no cadastro.")
			else
				::CliFor     = sa1 -> a1_cod
				::Loja       = sa1 -> a1_loja
				::NomeCliFor = sa1 -> a1_nome
			endif
		endif
	endif

	// Habilitar as linhas abaixo para verificar os atributos da classe:
	//u_log ('Objeto ' + GetClassName (::Self) + ':')
	//u_log (ClassDataArr (::self))

	u_logFim (GetClassName (::Self) + '.' + procname ())
return (len (::Erros) == 0)
