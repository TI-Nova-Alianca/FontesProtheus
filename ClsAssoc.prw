// Programa:  ClsAssoc
// Autor:     Robert Koch
// Data:      01/07/2011
// Descricao: Declaracao de classe de representacao de associados da cooperativa.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 05/12/2011 - Robert - Implementados tratamentos para safra.
// 20/01/2012 - Robert - Ajustes metodo SldQuotCap.
// 08/02/2012 - Robert - Implementados metodos TrbPAss e UltSafra.
// 09/02/2012 - Robert - Criadas colunas de resgates e integralizacoes 'na data' no retorno do metodo SldQuotCap.
// 10/02/2012 - Robert - Nao considerava movtos. 17 e 18 no metodo SldQuotCap.
// 21/02/2012 - Robert - Metodo Patriarca renomeado para Patriarcas e passa a retornar array com tantos patriarcas quantos encontrar.
// 27/02/2012 - Robert - Criado metodo ExtratoCC.
// 14/05/2012 - Robert - Criados metodos IdadeEm e TmpAssoc.
// 13/08/2012 - Robert - Passa a considerar codigo e loja base (cfe. parametro) para leitura de historico de safras.
// 15/08/2012 - Robert - Metodos New, ExtratoCC, SldQuotCap passam a considerar codigo e loja base.
// 18/09/2012 - Robert - Metodo ExtratoCC nao busca mais dados de compensacoes para o historico (ver obs. no local).
// 24/10/2012 - Robert - Passa a considerar o movimento 20 como integralizacao de cota capital.
// 12/11/2012 - Robert - Atributos de banco/agencia/conta passam a ser buscados via metodo DadosBanc.
// 10/12/2012 - Robert - Metodo CadVitic passa a usar a view VA_ASSOC_CAD_VITIC.
// 21/03/2013 - Robert - Inclui Metodo SaldoEm e AtuSaldo
// 04/04/2013 - Elaine - Inclui Metodo MontaSld
// 11/09/2014 - Robert - Arrays de dados usadas quando o associado tem mais de um codigo nao estavam sendo preenchidas corretamente.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 06/07/2015 - Robert - Metodo :DifDatas() da classe ClsDUtil foi substituido pelo :DifMeses().
// 12/11/2015 - Robert - Criado atributo :Nucleo.
// 17/11/2015 - Robert - Associados da SA passam a gerar correcao na filial 01.
// 08/01/2016 - Robert - Desabilitada leitura de previsao de pagamentos futuros de safra na calculo de correcao monetaria.
// 19/05/2016 - Robert - Criado atributo Subnucleo.
// 15/06/2016 - Robert - Metodo SldQuotCap mostrava dDataBase em vez de _dDataRef na mensagem final.
// 16/12/2016 - Robert - Criado metodo UltSafra.
// 12/01/2017 - Robert - Criado tratamento para TM=27 (baixas cap. social por inatividade)
// 18/01/2017 - Robert - Incluida coluna 'conferido' na array de cadastros viticolas.
// 30/03/2017 - Robert - Correcao passa a ser calculada somente ma natriz.
// 13/07/2017 - Robert - Metodo PrevPgSafr desabilitado por nao ter mais uso.
// 17/07/2017 - Robert - Criado metodo LctComSald().
// 01/09/2017 - Robert - Criados diversos novos atributos (dados cadastrais, DAP, etc.)
// 02/10/2017 - Robert - Tag .QtCapResgatesEmAbertoNaData eliminada. Criada tag .QtCapTotalResgatesEmAberto com o total independente de data.
// 09/10/2017 - Robert - Nao lia tipo de movimento 27 na composicao da cota capital.
// 24/11/2017 - Robert - Melhoria mensagens e retorno metodo CalcCM.
// 06/12/2017 - Robert - Criados metodos CodSU5 e GeraSU5.
// 17/01/2018 - Robert - Criado metodo GrpFam.
// 18/02/2018 - Robert - Metodo ExtratoCC: trazia deb/cred invertido quando TM=15 e transf.saldo para outra filial
// 19/04/2018 - Robert - Metodo ExtratoCC: alterado vinculo SE5 com SZI para consistir o campo E5_VACHVEX inteiro.
// 19/11/2018 - Robert - Passa a buscar nucleo e subnucleo do cadastro de grupos familiares.
// 10/01/2019 - Robert - Novas colunas cadastro viticola.
// 01/02/2019 - Robert - Tag .QtCapResgatesEmAbertoNaData volta a existir, para diferenciar da tag .QtCapTotalResgatesEmAberto
// 06/03/2019 - Robert - Removidos metodos CodSU5, GeraSU5, Condominio, DadosBanc, Patriarcas por nao terem mais uso.
// 13/03/2019 - Robert - Removido metodo HistSafr por nao ter mais uso.
// 05/05/2019 - Robert - Removidas linhas comentariadas metodo CalcCM.
// 09/05/2019 - Robert - Versao inicial do metodo FechSafr.
// 14/05/2019 - Robert - Consulta de consulta de capital social passa a retornar, tambem, uma string pre-formatada para XML.
// 15/05/2019 - Robert - Consulta de cota capital passa a ter a tag 'QtCapIntegralizacaoSobrasEnquantoExSocio' (GLPI 5873).
// 18/06/2019 - Robert - Metodo FechSafr passa a retornar faturas, regras de pagamento, valor unitario efetivo e lctos CC.
// 21/10/2019 - Robert - Consulta de capital social passa a retornar situacao e (opcionalmente) ano da ultima safra.
// 20/01/2020 - Robert - Metodo GrpFam() habilitado novamente pois tinha uma consulta usando-o.
// 09/04/2020 - Robert - Inserida tag <filial> da nota na consulta de fechamento de safra.
//                     - Comentariadas variaveis declaradas e nao usadas.
//

#include "protheus.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsAssoc ()
return


// ==========================================================================
CLASS ClsAssoc

	// Declaracao das propriedades da Classe
	data Bloqueado   // [.T. / .F.] Registro bloqueado para uso (A2_MSBLQL)
	data CEP
	data CPF         // CPF do associado
	data CPFConju    // CPF do conjuge
	data Celular
	data CodAvisad   // A2_VACAVIS - Codigo do associado avisador (aquele que eh responsavel por avisar/chamar este associado)
	data CodBase
	data Codigo
	data aCodigos    // Array com todos os codigos (A2_COD). Util quando o associado tiver mais de um codigo/loja. 
	data aInscrEst   // Array com todas as inscr.est. (A2_INSCR). Util quando o associado tiver mais de um codigo/loja.
	data aLojas      // Array com todas as lojas (A2_LOJA). Util quando o associado tiver mais de um codigo/loja.
	data CoopOrigem
	data DAPAptidao  // A2_VAAPDAP - Apto a fazer DAP [S=Sim;N=Nao] - para cobrar do associado que providencie a DAP. 
	data DAPBenef    // A2_VAQBDAP - Qual eh o beneficiario [1=Primeiro;2=Segundo;3=Terceiro]
	data DAPEmissao  // A2_VAEMDAP - Data de emissao
	data DAPEnquadr  // A2_VAENDAP - Enquadramento
	data DAPMotivo   // A2_VAMNDAP - Motivo de nao ter DAP
	data DAPNumero   // A2_VANRDAP - Numero da DAP
	data DAPValidad  // A2_VAVLDAP - Data de validade
	data DAPnoMDA    // A2_VASTDAP - Status junto ao Minist.Agricult [C=No MDA com DAP;S=No MDA sem DAP;D=Desconsiderar]
	data DtFalecim
	data DtNascim
	data EMail
	data Endereco
	data GrpFam      // Codigo do grupo familiar
	data InscrEst    // Inscricao estadual.
	data LojAvisad   // A2_VALAVIS - Loja do associado avisador (aquele que eh responsavel por avisar/chamar este associado)
	data Loja
	data LojaBase
	data MotInativ   // Motivo de ser considerado inativo
	data Municipio
	data Nome
	data NomeConju   // Nome do conjuge
	data Nucleo
	data Posse       // Posse da terra: AR=Arrendatario;CO=Comodatario;OU=Outra;PA=Parceiro;PO=Posseiro;PR=Proprietario;PP=Propriet. Parceiro;PE=Propriet. Arrendatario 
	data RG
	data FUNCAO
	data Subnucleo
	data Telefone
	data UF
	data UltMsg     // Ultima(s) mensagem(s) do objeto, geralmente mensagens de erro.

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD AgeBanc ()
	METHOD Ativo ()  // Verifica se o associado encontra-se ativo (com direito a voto, etc) na data de referencia.
	METHOD AtuSaldo ()
	METHOD CadVitic ()
	METHOD CalcCM ()
	METHOD DtEntrada ()
	METHOD DtSaida ()
	METHOD EhSocio ()
	METHOD ExtratoCC ()
	METHOD ExtratoCC2 ()
	METHOD FechSafra ()
	METHOD GrpFam ()
	METHOD IdadeEm ()
	METHOD LctComSald ()
	METHOD SaldoEm ()
	METHOD SldQuotCap ()
	METHOD TmpAssoc ()
	METHOD UltSafra ()
ENDCLASS


// --------------------------------------------------------------------------
// Construtor da classe.
METHOD New (_sCodigo, _sLoja, _lSemTela) Class ClsAssoc
	local _aAreaAnt  := {}
	local _oRet      := NIL
	local _lContinua := .T.
	local _oSQL      := NIL
	local _aCodigos  := {}
	local _nCodigo   := 0

	::UltMsg    = ""
	::MotInativ = ""

	if _sCodigo == NIL .or. _sLoja == NIL
		_oRet = Self
	else
		_aAreaAnt := sa2 -> (getarea ())
		sa2 -> (dbsetorder (1))
		if _lContinua .and. ! sa2 -> (dbseek (xfilial ("SA2") + _sCodigo + _sLoja, .F.))
			if type ('_sErros') == 'C'
				_sErros += "Impossivel instanciar classe ClsAssoc. Codigo/loja '" + _sCodigo + "/" + _sLoja + "' nao cadastrado como fornecedor."
			endif
			u_log ("Impossivel instanciar classe ClsAssoc. Codigo/loja '" + _sCodigo + "/" + _sLoja + "' nao cadastrado como fornecedor.",, .t.)
			_lContinua = .F.
		endif
		if _lContinua .and. (empty (sa2 -> a2_vacbase) .or. empty (sa2 -> a2_valbase))
			//::UltMsg += "Associado '" + _sCodigo + '/' + _sLoja + "' sem codigo/loja base no cadastro."
			u_log ("Associado '" + _sCodigo + '/' + _sLoja + "' sem codigo/loja base no cadastro.")
			_lContinua = .F.
		endif
		if _lContinua

			// Alguns dados devem ser buscados no proprio registro do SA2, independente de codigo/loja base.
			::Codigo     := sa2 -> a2_cod
			::Loja       := sa2 -> a2_loja
			::CodBase    := sa2 -> a2_vacbase
			::LojaBase   := sa2 -> a2_valbase
			::Endereco   := sa2 -> a2_end
			::Municipio  := sa2 -> a2_mun
			::UF         := sa2 -> a2_est
			::CEP        := sa2 -> a2_cep
			::InscrEst   := sa2 -> a2_inscr
			::Posse      := sa2 -> a2_vaPosse

			// Se o codigo/loja base for de outro registro do SA2, busca dados do registro base.
			if sa2 -> a2_cod != sa2 -> a2_vacbase .or. sa2 -> a2_loja != sa2 -> a2_valbase
				if ! sa2 -> (dbseek (xfilial ("SA2") + ::CodBase + ::LojaBase, .F.))
					::UltMsg += "Impossivel instanciar classe ClsAssoc. Codigo/loja base '" + ::CodBase + '/' + ::LojaBase + "' nao cadastrado como fornecedor."
					u_help (::UltMsg,, .t.)
					_lContinua = .F.
				endif
			endif
				
			// Estes dados serao buscados do codigo/loja base, se for o caso.
			if _lContinua
				::Nome       := sa2 -> a2_nome
				::DtNascim   := sa2 -> a2_vaDtNas
				::DtFalecim  := sa2 -> a2_vaDtFal
				::CoopOrigem := sa2 -> a2_vaCOrig
				::Bloqueado  := (sa2 -> a2_msblql == '1')
				::CPF        := sa2 -> a2_cgc
				::RG         := sa2 -> a2_vaRG
				::FUNCAO	 := alltrim (X3Combo ("A2_VAFUNC", sa2 -> a2_vafunc))
				::Telefone   := sa2 -> a2_tel
				::Celular    := sa2 -> a2_vacelul
				::EMail      := sa2 -> a2_email
				::NomeConju  := sa2 -> a2_vaconju
				::CPFConju   := sa2 -> a2_vacpfco
				::DAPAptidao := sa2 -> A2_VAAPDAP 
				::DAPNumero  := sa2 -> A2_VANRDAP
				::DAPMotivo  := sa2 -> A2_VAMNDAP
				::DAPnoMDA   := sa2 -> A2_VASTDAP
				::DAPEnquadr := sa2 -> A2_VAENDAP
				::DAPEmissao := sa2 -> A2_VAEMDAP
				::DAPValidad := sa2 -> A2_VAVLDAP
				::DAPBenef   := sa2 -> A2_VAQBDAP
			endif

			// Alguns dados sao buscados do grupo familiar
			if _lContinua
				::GrpFam     := ''
				::Nucleo     := ''
				::Subnucleo  := ''
				::CodAvisad  := ''
				::LojAvisad  := ''
				zak -> (dbsetorder (2))  // ZAK_FILIAL, ZAK_ASSOC, ZAK_LOJA, ZAK_IDZAN
				if zak -> (dbseek (xfilial ("ZAK") + ::Codigo + ::Loja, .F.))
					::GrpFam := zak -> zak_IdZAN
					zan -> (dbsetorder (1))  // ZAN_FILIAL+ZAN_COD
					if zan -> (dbseek (xfilial ("ZAN") + ::GrpFam, .F.))
						::Nucleo     := zan -> zan_nucleo
						::Subnucleo  := zan -> zan_subnuc
						::CodAvisad  := zan -> zan_avisad
						::LojAvisad  := zan -> zan_ljavis
					else
						u_log ('Associado', ::Codigo, '/', ::Loja, 'vinculado ao grupo familiar', ::GrpFam, 'mas nao encontrei esse grupo')
					endif
				else
					::GrpFam = ''
					u_log ('Associado', ::Codigo, '/', ::Loja, 'nao vinculado a nenhum grupo familiar')
					if type ("_sErros") == 'C'
						_sErros += 'Associado ' + ::Codigo + '/' + ::Loja + 'nao vinculado a nenhum grupo familiar'
					endif
				endif
			endif

			// Dados que podem ter mais de uma ocorrencia, quando o associado tiver mais de uma loja, sao armazenados em arrays.
			if _lContinua
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT A2_COD, A2_LOJA, A2_INSCR"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2")
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND A2_FILIAL  = '" + xfilial ("SA2") + "'"
				_oSQL:_sQuery +=   " AND A2_VACBASE = '" + ::CodBase  + "'"
				_oSQL:_sQuery +=   " AND A2_VALBASE = '" + ::LojaBase + "'"
				_oSQL:_sQuery += " ORDER BY A2_COD, A2_LOJA"
				_aCodigos = aclone (_oSQL:Qry2Array (.F., .F.))
				::aCodigos  = {}
				::aLojas    = {}
				::aInscrEst = {}
				for _nCodigo = 1 to len (_aCodigos)
					aadd (::aCodigos,  _aCodigos [_nCodigo, 1])
					aadd (::aLojas,    _aCodigos [_nCodigo, 2])
					aadd (::aInscrEst, _aCodigos [_nCodigo, 3])
				next
			endif
		endif
		sa2 -> (restarea (_aAreaAnt))
		if _lContinua
			_oRet = Self
		else
			_oRet = NIL
		endif
	endif
Return _oRet



// --------------------------------------------------------------------------
// Verifica se o associado encontra-se ativo na data de referencia.
METHOD Ativo (_dDataRef) Class ClsAssoc
	local _lRet   := .T.
	local _oSQL   := NIL
	local _dBaixa := ctod ('')

	_dDataRef = iif (_dDataRef == NIL, date (), _dDataRef)

	if _lRet .and. ! ::EhSocio (_dDataRef)
		//u_log ('desligado')
		_lRet = .F.
		::MotInativ = 'Desligado'
	endif
	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX (ZI_DATA)"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ = '' "
		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + ::Codigo + "' "
		_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + ::Loja + "' "
		_oSQL:_sQuery +=    " AND SZI.ZI_TM      = '27'"
		_oSQL:_sQuery +=    " AND SZI.ZI_DATA   <= '" + dtos (_dDataRef) + "'"
		//_oSQL:Log ()
		_dBaixa := _oSQL:RetQry ()
		//u_log (_dBaixa)
		if ! empty (_dBaixa)
			_lRet = .F.
			::MotInativ = 'Cotas baixadas por inatividade em ' + dtoc (stod (_dBaixa))
		endif
	endif

return _lRet



// --------------------------------------------------------------------------
// Atualiza saldos do associado no ZZM, a partir da data informada.
METHOD AtuSaldo (_dDataRec) Class ClsAssoc
	local _aAreaAnt  := U_ML_SRArea ()
//	local _sQuery    := ""
	local _oSQL      := NIL
	local _lContinua := .T.
	local _dPrimSZI  := ctod ('')
//	local _dIniZZM   := ctod ('')
//	local _dBaseZZM  := ctod ('')
	local _nAnoIni   := 0
	local _nAnoFim   := 0
	local _nAno      := 0
//	local _sWhereSZI := ""
	local _dDataZZM  := ctod ('')
	local _lTemZZM   := .F.
	local _aSaldoZZM := {}

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua
		_lContinua = (::Codigo != NIL .and. ::Loja != NIL)
	endif

	// Busca menor e maior datas de movimentacao do SZI. Deverao existir registros no ZZM para todos os periodos relacionados.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MIN (ZI_DATA)" //, MAX (ZI_DATA) "
		_oSQL:_sQuery += "   FROM " + RetSQLName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.ZI_ASSOC   = '" + ::Codigo + "' "
		_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + ::Loja + "' "
		_oSQL:_sQuery +=    " AND SZI.D_E_L_E_T_ = '' "
     	_dPrimSZI = stod (_oSQL:RetQry ())
		if empty (_dPrimSZI)
			u_log ('Sem datas no SZI. Abortando processo.')
			_lContinua = .F.
		endif
	endif

	// Define os periodos que deverao estar presentes no ZZM.
	if _lContinua
		// Sempre inicia com a ultima data do periodo anterior.
		_nAnoIni = year (_dPrimSZI) - 1
		_nAnoFim = year (date ()) - 1  // Limita pela data atual, para evitar que sejam considerados titulos futuros de resgate de quota social, por exemplo.
		zzm -> (dbsetorder (1))  // ZZM_FILIAL+ZZM_ASSOC+ZZM_LOJA+ZZM_DATA
		for _nAno = _nAnoIni to _nAnoFim
			_dDataZZM = stod (strzero (_nAno, 4) + '1231')
			_lTemZZM = zzm -> (dbseek (xfilial ("ZZM") + ::Codigo + ::Loja + dtos (_dDataZZM), .F.))
			
			// Se existe o ZZM deste periodo e foi o mesmo eh menor que a data para a qual foi solicitado recalculo, deixa-o em paz.
			if _lTemZZM .and. zzm -> zzm_data < _dDataRec
				//u_log ('Existe ZZM com data', zzm -> zzm_data, ' e esta eh menor que a data para recalculo (', _dDataRec, '). Por isso, deixo-o em paz.')
				loop
			endif
			
			// Se chegou aqui, eh por que o ZZM nao existe (precisa criar) ou por que existe e precisa ser recalculado.
			if _lTemZZM
				// Remove o registro do ZZM para que o metodo SaldoEm nao possa utiliza-lo e seja obrigado a recalcular o saldo.
				// u_log ('Removendo o registro de', zzm -> zzm_data, 'do ZZM para que o metodo SaldoEm nao possa utiliza-lo e seja obrigado a recalcular o saldo.')
				reclock ("ZZM", .F.)
				zzm -> (dbdelete ())
				msunlock ()
			endif
			_aSaldoZZM = aclone (::SaldoEm (_dDataZZM))
			reclock ("ZZM", .T.)
			ZZM -> ZZM_FILIAL  = xfilial ("ZZM")
			ZZM -> ZZM_ASSOC   = ::Codigo
			ZZM -> ZZM_LOJA    = ::Loja
			ZZM -> ZZM_DATA    = _dDataZZM
			
			// Capital nao social
			if _aSaldoZZM [.SaldoAssocCapNaoSocialDebito] > _aSaldoZZM [.SaldoAssocCapNaoSocialCredito]
				ZZM -> ZZM_CNSocD = _aSaldoZZM [.SaldoAssocCapNaoSocialDebito] - _aSaldoZZM [.SaldoAssocCapNaoSocialCredito]
			else
				ZZM -> ZZM_CNSocC = _aSaldoZZM [.SaldoAssocCapNaoSocialCredito] - _aSaldoZZM [.SaldoAssocCapNaoSocialDebito]
			endif
			
			// Capital social
			if _aSaldoZZM [.SaldoAssocCapSocialDebito] > _aSaldoZZM [.SaldoAssocCapSocialCredito]
				ZZM -> ZZM_CSocD = _aSaldoZZM [.SaldoAssocCapSocialDebito] - _aSaldoZZM [.SaldoAssocCapSocialCredito]
			else
				ZZM -> ZZM_CSocC = _aSaldoZZM [.SaldoAssocCapSocialCredito] - _aSaldoZZM [.SaldoAssocCapSocialDebito]
			endif

			msunlock ()
		next
	endif

	U_ML_SRArea (_aAreaAnt)
//	u_logFim (GetClassName (::Self) + '.' + procname ())
Return 



// --------------------------------------------------------------------------
// Busca os dados de cadastros viticolas ligados ao associado.
//METHOD CadVitic (_sSafra) Class ClsAssoc
METHOD CadVitic () Class ClsAssoc
	local _oSQL    := NIL
	local _aRetQry := {}
	local _aRet    := {}
	local _nLinha  := 0
//	u_logIni ()
//			u_log (::Codigo)
//			u_log (::Loja)

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT CAD_VITIC, GRPFAM, DESCR_GRPFAM, PRODUTO, DESCRICAO, TIPO_ORGANICO, RECADAST_VITIC, FINA_COMUM, DESCR_MUN, AMOSTRA, RECEB_FISICO_VITIC, SIST_CONDUCAO"
	_oSQL:_sQuery +=  " FROM VA_VASSOC_CAD_VITIC2 V"
	_oSQL:_sQuery += " WHERE V.ASSOCIADO  = '" + ::Codigo + "'"
	_oSQL:_sQuery +=   " AND V.LOJA_ASSOC = '" + ::Loja   + "'"
	_oSQL:_sQuery += " ORDER BY CAD_VITIC, GRPFAM, PRODUTO"
//	u_log (_oSQL:_squery)

	// Poderia simplesmente pegar o retorno da query, mas usando os includes facilito
	// futuras pesquisas em fontes para saber onde estes dados sao usados.
	_aRetQry = _oSQL:Qry2Array ()
	aRet = {}
	for _nLinha = 1 to len (_aRetQry)
		aadd (_aRet, array (.CadVitQtColunas))
		_aRet [_nLinha, .CadVitCodigo]      = _aRetQry [_nLinha, 1]
		_aRet [_nLinha, .CadVitCodGrpFam]   = _aRetQry [_nLinha, 2]
		_aRet [_nLinha, .CadVitNomeGrpFam]  = _aRetQry [_nLinha, 3]
		_aRet [_nLinha, .CadVitProduto]     = _aRetQry [_nLinha, 4]
		_aRet [_nLinha, .CadVitDescPro]     = _aRetQry [_nLinha, 5]
		_aRet [_nLinha, .CadVitOrganico]    = _aRetQry [_nLinha, 6]
		_aRet [_nLinha, .CadVitSafrVit]     = _aRetQry [_nLinha, 7]
		_aRet [_nLinha, .CadVitVarUva]      = _aRetQry [_nLinha, 8]
		_aRet [_nLinha, .CadVitDescMun]     = _aRetQry [_nLinha, 9]
		_aRet [_nLinha, .CadVitAmostra]     = _aRetQry [_nLinha, 10]
		_aRet [_nLinha, .CadVitRecebFisico] = stod (_aRetQry [_nLinha, 11])
		_aRet [_nLinha, .CadVitSistCond]    = _aRetQry [_nLinha, 12]
	next
//	U_LOG (_ArET)
//	u_logFim ()
return _aRet



// --------------------------------------------------------------------------
// Calcula correcao monetaria.
METHOD CalcCM (_sMesRef, _nTaxaVl1, _nTaxaVl2, _nLimVl1, _lGerarD, _lGerarC) Class ClsAssoc
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _nSldAssoc := 0
	local _dDtLimite := lastday (stod (substr (_sMesRef, 3, 4) + substr (_sMesRef, 1, 2) + '01'))
	local _oCtaCorr  := ClsCtaCorr():New ()
	local _sTMCorrC  := _oCtaCorr:TMCorrMonC
	local _sTMCorrD  := _oCtaCorr:TMCorrMonD
//	local _aFiliais  := {}
	local _nFilial   := 0
	local _aSldFil   := {}
	local _nPrevSafr := 0
//	local _sFilCalc  := ''
	local _nBaseCorr := 0
	local _nLimMin   := 500  // Limite minimo para gerar correcao. Definido em reuniao de diretoria em 17/05/2013.
	local _nFaixa    := 0
	local _nTaxa     := 0
	local _nCorrec   := 0
	local _sSerie    := ""
	local _aRegNF    := {}
	local _nRegNF    := 0
	local _nCodigo   := 0
	local _sInCodLoj := ""
	local _nAdtSafra := 0
	local _nSldNFSaf := 0
	local _oAssoc2   := NIL
	local _sTipoCorr := ""
	local _lRet      := .T.

	u_logIni (GetClassName (::Self) + '.' + procname ())

//if ! _sMesRef == '112017' // queremos pagar ainda dentro deste mes. remover esta linha depois...

	if _lContinua
		if substr (_sMesRef, 3, 4) + substr (_sMesRef, 1, 2) >= left (dtos (date ()), 6)
			::UltMsg += "O mes ainda nao acabou! Apenas Nostradamus tem permissao para calcular datas futuras. Se voce tiver a senha dele, sem problema..."
			_lRet = .F.
			_lContinua = .F.
		endif
	endif

//endif

	if _lContinua
		if ::Codigo + ::Loja != ::CodBase + ::LojaBase
			::UltMsg += "Correcao deve ser calculada apenas para o codigo/loja base do associado (no caso, '" + ::CodBase + '/' + ::LojaBase + "')."
			_lRet = .F.
			_lContinua = .F.
		else
			// Monta string com codigo + loja de todos os codigos/lojas do associado, formatada para uso em clausulas IN do SQL.
		 	for _nCodigo = 1 to len (::aCodigos)
				_sInCodLoj += ::aCodigos [_nCodigo] + ::aLojas [_nCodigo] + iif (_nCodigo < len (::aCodigos), '/', '')
			next
		endif
	endif

	// A correcao eh sempre gerada na matriz a partir de 30/03/2017.
	if _lContinua .and. cEmpAnt + cFilAnt != '0101'
		::UltMsg += "A correcao deve ser gerada na matriz."
		_lRet = .F.
		_lContinua = .F.
	endif

//if ! _sMesRef == '112017' // queremos pagar ainda dentro deste mes. remover esta linha depois...
	// Nao permite mais de uma geracao no mesmo mes.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL  = '" + xfilial ("SZI") + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM      IN " + FormatIn (_sTMCorrC + "/" + _sTMCorrD, '/')
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO in " + FormatIn (_sInCodLoj, '/')
		_oSQL:_sQuery +=   " AND SZI.ZI_MESREF  = '" + _sMesRef + "'"
		if _lGerarD
			_oSQL:_sQuery += " AND SZI.ZI_TM = '" + _sTMCorrD + "'"
		endif
		if _lGerarC
			_oSQL:_sQuery += " AND SZI.ZI_TM = '" + _sTMCorrC + "'"
		endif
		//u_log (_oSQL:_sQuery)
		if _oSQL:RetQry () > 0
			::UltMsg += "Ja' existe correcao monetaria calculada para o mes de referencia " + _sMesRef + " para algum dos codigos/lojas (" + _sInCodLoj + ") deste associado."
			_lRet = .F.
			_lContinua = .F.
		endif
	endif
//endif

	// Busca os saldos de conta corrente de todas as lojas do associado.
	if _lContinua
		_nSldAssoc = 0
		for _nFilial = 1 to len (::aCodigos)

			// Se nao for o cod/loja atuais (assoc. tem mais de uma loja), instancia novo associado para buscar seu saldo.
			if ::aCodigos [_nFilial] != ::Codigo .or. ::aLojas [_nFilial] != ::Loja
				_oAssoc2 := ClsAssoc ():New (::aCodigos [_nFilial], ::aLojas [_nFilial])
			else
				_oAssoc2 = ::Self
			endif
			_aSldFil = aclone (_oAssoc2:SaldoEm (_dDtLimite))
			_nSldAssoc += _aSldFil [.SaldoAssocCapNaoSocialDebito] - _aSldFil [.SaldoAssocCapNaoSocialCredito]
			u_log ('Saldo devedor cta corrente para assoc/loja ', _oAssoc2:Codigo + '/' + _oAssoc2:Loja, ':', _aSldFil [.SaldoAssocCapNaoSocialDebito] - _aSldFil [.SaldoAssocCapNaoSocialCredito])
		next
	endif

	// Verifica saldos das notas de compra de safra deste ano.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO in " + FormatIn (_sInCodLoj, '/')
		_oSQL:_sQuery +=    " AND SZI.ZI_TM = '13'"
		_oSQL:_sQuery +=    " AND SZI.ZI_DATA >= '" + substr (_sMesRef, 3, 4) + "0101'"
		//u_log (_oSQL:_sQuery)
		_aRegNF = aclone (_oSQL:Qry2Array ())
		for _nRegNF = 1 to len (_aRegNF)
	  		_oCtaCorr := ClsCtaCorr():New (_aRegNF [_nRegNF, 1])
	  		_nSldNFSaf += _oCtaCorr:SaldoEm (_dDtLimite)
		next
	endif

	// Calcula base para correcao.
	if _lContinua
		_nAdtSafra = _nPrevSafr - _nSldNFSafr
		//u_log ('Saldo CC a debito deste associado (todas as lojas em todas as filiais)...:', _nSldAssoc)
		//u_log ('Previsao de pagamentos de safra posteriores a ' + dtoc (_dDtLimite) + ' ................:', _nPrevSafr)
		//u_log ('Saldos das notas de compra de safra na data de ' + dtoc (_dDtLimite) + ' ...............:', _nSldNFSafr)
		//u_log ('Adiantamentos de pagamentos das notas de compra de safra.................:', _nAdtSafra)
		_nBaseCorr = _nSldAssoc
		
		// Se estamos em epoca de pagamento (tem parcelas de safra previstas)...
		if _nPrevSafr > 0
			_nBaseCorr = _nPrevSafr + _nSldAssoc
		endif
		u_log ('Base (a debito) para calculo da correcao.................................: ', _nBaseCorr)
		
		if _lContinua .and. abs (_nBaseCorr) < _nLimMin
			::UltMsg += "Base abaixo do limite minimo (" + cvaltochar (_nLimMin) + ")"
			_lContinua = .F.
		endif
	endif

	if _lContinua

		// Determina em qual faixa o saldo deve ser considerado, taxa a utilizar e calcula valor da correcao.
		_nFaixa = iif (abs (_nBaseCorr) > _nLimVl1, 2, 1)
		_nTaxa  = iif (_nFaixa == 1, _nTaxaVl1, _nTaxaVl2)
		_nCorrec = abs (round (_nBaseCorr * _nTaxa / 100, 2))
		_sTipoCorr = iif (_nBaseCorr > 0, 'D', 'C')
		u_log ('Valor de correcao calculado..............................................:', _nCorrec, '(' + _sTipoCorr + ')')

		if _nCorrec == 0 .or. (_sTipoCorr == 'D' .and. ! _lGerarD) .or. (_sTipoCorr == 'C' .and. ! _lGerarC)
			::UltMsg += 'Valor zerado ou tipo (D/C) nao solicitado.'
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Monta texto para memoria de calculo.
		_sMemCalc := "Corr.mon.calculada em " + dtoc (date ()) + " " + time () + " com taxa de " + alltrim (transform (_nTaxa, "@E 999,999.99")) + "% sobre " + GetMv ("MV_SIMB1") + " " + alltrim (transform (abs (_nBaseCorr), "@E 999,999,999.99")) + chr (13) + chr (10)
		_sMemCalc += "Dados considerados para calculo:" + chr (13) + chr (10)
		_sMemCalc += "Saldo conta corrente em " + dtoc (_dDtLimite) + "..: " + GetMv ("MV_SIMB1") + " " + transform (abs (_nSldAssoc), "@E 999,999,999.99") + iif (_nSldAssoc < 0, ' (C)', ' (D)') + chr (13) + chr (10)
		_sMemCalc += "Parcelas previstas (futuras) safra..: " + GetMv ("MV_SIMB1") + " " + transform (_nPrevSafr, "@E 999,999,999.99") + chr (13) + chr (10)
		_sMemCalc += "Adiantamentos parcelas futuras safra: " + GetMv ("MV_SIMB1") + " " + transform (abs (_nAdtSafra), "@E 999,999,999.99")
		u_log ('Memoria de calculo:' + chr (13) + chr (10) + _sMemCalc)
		
		// Gera lancamento da correcao monetaria a debito ou a credito, conforme o valor, na conta corrente.
		if _sTipoCorr == 'C'
			_sSerie = fBuscaCpo ("ZX5", 2, xfilial ("ZX5") + '10' + '14', "ZX5_10PREF")
		else
			_sSerie = fBuscaCpo ("ZX5", 2, xfilial ("ZX5") + '10' + '15', "ZX5_10PREF")
		endif
		_oCtaCorr = ClsCtaCorr():New ()
		_oCtaCorr:Assoc   = ::Codigo
		_oCtaCorr:Loja    = ::Loja
		_oCtaCorr:TM      = iif (_sTipoCorr == 'C', _sTMCorrC, _sTMCorrD)
		_oCtaCorr:DtMovto = lastday (stod (substr (_sMesRef, 3, 4) + substr (_sMesRef, 1, 2) + '01')) + 1
		_oCtaCorr:Valor   = _nCorrec
		_oCtaCorr:Histor  = "CORR.MON.REF.SLD " + alltrim (transform (abs (_nBaseCorr), "@E 999,999,999.99")) + ' (' + _sTipoCorr + ')' + " de " + alltrim (::Nome)
		_oCtaCorr:MesRef  = _sMesRef
		_oCtaCorr:Doc     = strtran (dtoc (_oCtaCorr:DtMovto), '/', '')
		_oCtaCorr:Serie   = _sSerie
		_oCtaCorr:Obs     = _sMemCalc
		_oCtaCorr:Origem  = procname ()
		//u_logobj (_oCtaCorr)
		if ! _oCtaCorr:Grava ()
			::UltMsg += "Erro na gravacao do registro de correcao monetaria."
			_lRet = .F.
			_lContinua = .F.
		else
			::UltMsg += "Reg.gravado no SZI com seq." + _oCtaCorr:SeqSZI
		endif
	endif

	u_logFim (GetClassName (::Self) + '.' + procname ())
	U_ML_SRArea (_aAreaAnt)
return _lRet



// --------------------------------------------------------------------------
// Busca os grupos familiares aos quais o associado encontra-se ligado.
METHOD GrpFam () Class ClsAssoc
	local _oSQL    := NIL
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ZAN_COD, ZAN_DESCRI, "
	_oSQL:_sQuery +=         _oSQL:CaseX3CBox ("ZAK_TIPORE")
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAN") + " ZAN, "
	_oSQL:_sQuery +=             RetSQLName ("ZAK") + " ZAK "
	_oSQL:_sQuery += " WHERE ZAN.D_E_L_E_T_ = ''
	_oSQL:_sQuery +=   " AND ZAN_FILIAL = '" + xfilial ("ZAN") + "'"
	_oSQL:_sQuery +=   " AND ZAK_FILIAL = '" + xfilial ("ZAK") + "'"
	_oSQL:_sQuery +=   " AND ZAK_IDZAN  = ZAN.ZAN_COD"
	_oSQL:_sQuery +=   " AND ZAK_ASSOC  = '" + ::Codigo + "'"
	_oSQL:_sQuery +=   " AND ZAK_LOJA   = '" + ::Loja   + "'"
	_oSQL:_sQuery += " ORDER BY ZAN_COD"
	_oSQL:Log ()
return aclone (_oSQL:Qry2Array ())



// --------------------------------------------------------------------------
// Busca data de entrada no quadro de socios.
METHOD DtEntrada (_dDataRef) Class ClsAssoc
	local _sQuery  := ""
	local _sRetQry := ""
	local _dRet    := ctod ("")

	// O associado pode ter saido e entrado novamente no quadro de socios, entao
	// este metodo permite especificar uma data de referencia, sendo que deverah
	// existir entrada no quadro de socios anterior a esta data de referencia.
	// Se nao especificado, assume a data base.
	if valtype (_dDataRef) != "D" .or. empty (_dDataRef)
		_dDataRef = dDataBase
	endif
	
	// Varre todas as filiais.
	if ::Codigo != NIL .and. ::Loja != NIL
		_sQuery := ""
		_sQuery += "SELECT MAX (ZI_DATA)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_ASSOC   = '" + ::Codigo + "'"
		_sQuery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
		_sQuery +=   " AND ZI_DATA   <= '" + dtos (_dDataRef) + "'"
		_sQuery +=   " AND ZI_TM      = '08'"
		_sQuery +=   " AND NOT EXISTS (SELECT *"  // Se existir desligamento posterior, invalida a entrada.
		_sQuery +=                     " FROM " + RetSQLName ("SZI") + " AS DESASSOC"
		_sQuery +=                    " WHERE DESASSOC.D_E_L_E_T_ = ''"
		_sQuery +=                      " AND DESASSOC.ZI_ASSOC   = SZI.ZI_ASSOC"
		_sQuery +=                      " AND DESASSOC.ZI_LOJASSO = SZI.ZI_LOJASSO"
		_sQuery +=                      " AND DESASSOC.ZI_DATA   >= SZI.ZI_DATA"
		_sQuery +=                      " AND DESASSOC.ZI_DATA   <  '" + dtos (_dDataRef) + "'"
		_sQuery +=                      " AND DESASSOC.ZI_TM      = '09')"
	//	u_log (_squery)
		_sRetQry = U_RetSQL (_sQuery)
		if ! empty (_sRetQry)
			_dRet = stod (_sRetQry)
		endif
	endif
return _dRet



// --------------------------------------------------------------------------
// Busca data de saida do quadro de socios.
METHOD DtSaida (_dDataRef) Class ClsAssoc
	local _sQuery  := ""
	local _sRetQry := ""
	local _dRet    := ctod ("")

	// O associado pode ter saido e entrado novamente no quadro de socios, entao
	// este metodo permite especificar uma data de referencia, sendo que deverah
	// existir saida no quadro de socios anterior a esta data de referencia.
	// Se nao especificado, assume a data base.
	if valtype (_dDataRef) != "D" .or. empty (_dDataRef)
		_dDataRef = dDataBase
	endif
	
	// Varre todas as filiais.
	_sQuery := ""
	_sQuery += "SELECT MAX (ZI_DATA)"
	_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
	_sQuery += " WHERE D_E_L_E_T_ = ''"
	_sQuery +=   " AND ZI_ASSOC   = '" + ::Codigo + "'"
	_sQuery +=   " AND ZI_LOJASSO = '" + ::Loja + "'"
	_sQuery +=   " AND ZI_DATA   <= '" + dtos (_dDataRef) + "'"
	_sQuery +=   " AND ZI_TM      = '09'"
	_sQuery +=   " AND NOT EXISTS (SELECT *"  // Se existir associacao posterior, invalida a saida.
	_sQuery +=                     " FROM " + RetSQLName ("SZI") + " AS REASSOC"
	_sQuery +=                    " WHERE REASSOC.D_E_L_E_T_ = ''"
	_sQuery +=                      " AND REASSOC.ZI_ASSOC   = SZI.ZI_ASSOC"
	_sQuery +=                      " AND REASSOC.ZI_LOJASSO = SZI.ZI_LOJASSO"
	_sQuery +=                      " AND REASSOC.ZI_DATA   >= SZI.ZI_DATA"
	_sQuery +=                      " AND REASSOC.ZI_DATA   <= '" + dtos (_dDataRef) + "'"
	_sQuery +=                      " AND REASSOC.ZI_TM      = '08')"
//	u_log (_squery)
	_sRetQry = U_RetSQL (_sQuery)
	if ! empty (_sRetQry)
		_dRet = stod (_sRetQry)
	endif
return _dRet



// --------------------------------------------------------------------------
// Verifica se o associado encontra-se no quadro social na data de referencia.
METHOD EhSocio (_dDataRef) Class ClsAssoc
	local _lRet    := .F.

	if ! empty (Self:DtEntrada (_dDataRef))
		_lRet = .T.
	endif
return _lRet



// --------------------------------------------------------------------------
// Gera array com dados para extrato da conta corrente do associado.
METHOD ExtratoCC (_sFilIni, _sFilFim, _dDataIni, _dDataFim, _sTMIni, _sTMFim, _lCodBase, _lSimples) Class ClsAssoc
	local _oSQL     := NIL
	local _sAliasQ  := ""
	local _aRet     := {}
	local _lInverte := .F.
	local _sDC      := ""
	local _nLinha   := 0
	local _aAreaAnt  := U_ML_SRArea ()

	// u_logIni (GetClassName (::Self) + '.' + procname ())

	if Self != NIL .and. ::Codigo != NIL .and. ::Loja != NIL
		//u_log ('Gerando extrato para:', _sFilIni, _sFilFim, _dDataIni, _dDataFim, _sTMIni, _sTMFim, _lCodBase, _lSimples)

		// Busca dados usando uma CTE para facilitar a uniao das consutas de diferentes tabelas.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH _CTE AS ("
		
		// Busca conta corrente
		_oSQL:_sQuery += "SELECT 'SZI' AS ORIGEM, ZI_FILIAL AS FILIAL, " + U_LeSM0 ('2', cEmpAnt, '', 'SZI', 'ZI_FILIAL', 'ZI_FILIAL') [2] + " AS DESCFIL, "
		_oSQL:_sQuery +=       " ZI_DATA AS DATA, ZI_TM AS TIPO_MOV, ZI_HISTOR AS HIST, ZI_ASSOC AS ASSOC, ZI_LOJASSO AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
		_oSQL:_sQuery +=       " ZI_VALOR AS VALOR, '' AS E5_RECPAG, ZI_DOC AS NUMERO, ZI_SERIE AS PREFIXO, '' AS DOCUMEN, '' AS E5_SEQ,"
		_oSQL:_sQuery +=       " '' AS E5_MOTBX, '' AS E5_PARCELA, '' AS E5_TIPODOC, '' AS E5_FORNADT, '' AS E5_LOJAADT, '' AS E5_ORIGEM"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + _sFilIni + "' AND '" + _sFilFim + "'"
		if _lCodBase
			_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
			_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SA2") + " SA2 "
			_oSQL:_sQuery +=                 " WHERE SA2.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=                   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_oSQL:_sQuery +=                   " AND SA2.A2_COD     = SZI.ZI_ASSOC"
			_oSQL:_sQuery +=                   " AND SA2.A2_LOJA    = SZI.ZI_LOJASSO"
			_oSQL:_sQuery +=                   " AND SA2.A2_VACBASE = '" + ::CodBase + "'"
			_oSQL:_sQuery +=                   " AND SA2.A2_VALBASE = '" + ::LojaBase + "'"
			_oSQL:_sQuery +=    " )"
		else
			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Codigo + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja + "'"
		endif
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + _sTMIni + "' AND '" + _sTMFim + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"  // Nao quero lcto que gerou movto bancario por que vai ser buscado posteriormente do SE5.
		_oSQL:_sQuery +=                     " FROM " + RETSQLNAME ("SE5") + " SE5 "
		_oSQL:_sQuery +=                    " WHERE SE5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                      " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"
		_oSQL:_sQuery +=                      " AND SE5.E5_TIPODOC  = 'PA'"  // Acho que VL tambem vai interessar posteriormente...
		_oSQL:_sQuery +=                      " AND SE5.E5_SITUACA != 'C'"
		_oSQL:_sQuery +=                      " AND SE5.E5_FILIAL   = SZI.ZI_FILIAL"
		_oSQL:_sQuery +=                      " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0)"

		// Busca movimento bancario ligado ao SZI.
		_oSQL:_sQuery += " UNION ALL "
		_oSQL:_sQuery += "SELECT 'SE5' AS ORIGEM, E5_FILIAL AS FILIAL, " + U_LeSM0 ('2', cEmpAnt, '', 'SE5', 'E5_FILIAL', 'E5_FILIAL') [2] + " AS DESCFIL, "
		_oSQL:_sQuery +=       " E5_DATA AS DATA, ZI_TM AS TIPO_MOV, E5_HISTOR AS HIST, E5_CLIFOR AS ASSOC, E5_LOJA AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
		_oSQL:_sQuery +=       " E5_VALOR AS VALOR, E5_RECPAG, E5_NUMERO AS NUMERO, E5_PREFIXO AS PREFIXO, E5_DOCUMEN AS DOCUMEN, E5_SEQ,"
		_oSQL:_sQuery +=       " E5_MOTBX, E5_PARCELA, E5_TIPODOC, E5_FORNADT, E5_LOJAADT, E5_ORIGEM"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5, "
		_oSQL:_sQuery +=             RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SE5.E5_FILIAL   BETWEEN '" + _sFilIni + "' AND '" + _sFilFim + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = SE5.E5_FILIAL"
		_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR   = '" + ::Codigo + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_LOJA     = '" + ::Loja + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"

// melhoria performance 19/04/2018 com uso de indice por e5_clifor
//		_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  LIKE 'SZI%'"  // Para ganho de performance: todo SE5 que me interessar aqui terah chave externa com o SZI.
//		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = SE5.E5_CLIFOR"
//		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = SE5.E5_LOJA"
//		_oSQL:_sQuery +=   " AND SZI.ZI_SEQ      = SUBSTRING (SE5.E5_VACHVEX, 12, 6)"

		_oSQL:_sQuery +=   " AND SE5.E5_VACHVEX  = 'SZI' + ZI_ASSOC + ZI_LOJASSO + ZI_SEQ"

		_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + _sTMIni + "' AND '" + _sTMFim + "'"
		_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
		_oSQL:_sQuery += " ) "
		_oSQL:_sQuery += "SELECT _CTE.*, A2_NOME AS NOME, ZX5_10DESC AS DESC_TM, ZX5_10DC AS DEB_CRED, ZX5.ZX5_10CAPI"
		_oSQL:_sQuery +=  " FROM _CTE,"
		_oSQL:_sQuery +=         RETSQLNAME ("ZX5") + " ZX5, "
		_oSQL:_sQuery +=         RETSQLNAME ("SA2") + " SA2 "
		_oSQL:_sQuery += " WHERE SA2.A2_COD      = _CTE.ASSOC"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = _CTE.LOJASSO"
		_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = _CTE.TIPO_MOV"

		// Ordenacao por varios campos por que, do contrario, a cada vez o relariorio traz uma nova ordenacao e fica dificil fazer comparativos...
		_oSQL:_sQuery += " ORDER BY DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, HIST, PREFIXO, NUMERO, E5_PARCELA"
		//u_log (_oSQL:_sQuery)
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		TCSetField (_sAliasQ, "DATA", "D")
		(_sAliasQ) -> (dbgotop ())                	
		do while ! (_sAliasQ) -> (eof ())
	
			// Gera nova linha para retorno.
			aadd (_aRet, array (.ExtratoCCQtColunas))
			_nLinha = len (_aRet)
			_aRet [_nLinha, .ExtratoCCFilial]    = (_sAliasQ) -> Filial
			_aRet [_nLinha, .ExtratoCCDescFil]   = (_sAliasQ) -> DescFil
			_aRet [_nLinha, .ExtratoCCData]      = (_sAliasQ) -> data
			_aRet [_nLinha, .ExtratoCCTM]        = (_sAliasQ) -> tipo_mov
			_aRet [_nLinha, .ExtratoCCDC]        = ''
			_aRet [_nLinha, .ExtratoCCValor]     = (_sAliasQ) -> valor
			_aRet [_nLinha, .ExtratoCCFornAdt]   = (_sAliasQ) -> e5_FornAdt
			_aRet [_nLinha, .ExtratoCCLojaAdt]   = (_sAliasQ) -> e5_LojaAdt
			_aRet [_nLinha, .ExtratoCCHist]      = ''
			_aRet [_nLinha, .ExtratoCCObs]       = ''
			_aRet [_nLinha, .ExtratoCCCapSocial] = (_sAliasQ) -> zx5_10capi
			_aRet [_nLinha, .ExtratoCCOrigem]    = (_sAliasQ) -> origem
	
			// Verifica se o movimento deve ser tratado como debito ou como credito.
			_sDC = (_sAliasQ) -> deb_cred
			if (_sAliasQ) -> origem == 'SE5'
				_lInverte = .F.
				if _sDC == "D" .and. (_sAliasQ) -> e5_recpag == "R"
					_lInverte = ! _lInverte
				elseif _sDC == "C" .and. (_sAliasQ) -> e5_recpag == "P"
					_lInverte = ! _lInverte
				endif
				if (_sAliasQ) -> e5_motbx == "CMP" .and. (_sAliasQ) -> e5_tipodoc != 'CP'
					_lInverte = ! _lInverte
				endif
				if (_sAliasQ) -> e5_motbx == "NOR" .and. (_sAliasQ) -> tipo_mov == '15' .and. (_sAliasQ) -> e5_origem = 'SZI_TSF' 
					u_log ('no quarto IF')
					_lInverte = ! _lInverte
				endif
	
				if _lInverte
					if _sDC == "D"
						_sDC = "C"
					elseif _sDC == "C"
						_sDC = "D"
					endif
				endif
			endif
			_aRet [_nLinha, .ExtratoCCDC] = _sDC
	
			// Formato simples destina-se apenas a buscar valores.
			if ! _lSimples
				_aRet [_nLinha, .ExtratoCCHist] = alltrim ((_sAliasQ) -> hist)
		
				// Quando for baixa por compensacao, monta historico um pouco mais elaborado.
				if (_sAliasQ) -> e5_motbx == "CMP" .and. ! empty ((_sAliasQ) -> documen)
					//_aRet [_nLinha, .ExtratoCCHist] = 'Compens.tit. ' + substr ((_sAliasQ) -> documen, 1, 3) + '/' + substr ((_sAliasQ) -> documen, 4, 6) + '-' + substr ((_sAliasQ) -> documen, 10, 1)
					_aRet [_nLinha, .ExtratoCCHist] = 'Compens.tit. ' + left ((_sAliasQ) -> documen, 13)
		
					// Se foi compensacao contra outro fornecedor, busca seus dados.
					if (_sAliasQ) -> assoc + (_sAliasQ) -> lojasso != (_sAliasQ) -> e5_fornadt + (_sAliasQ) -> e5_lojaadt
						_aRet [_nLinha, .ExtratoCCHist] += ' de ' + (_sAliasQ) -> e5_fornadt + '/' + (_sAliasQ) -> e5_lojaadt + ' (' + alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> e5_fornadt + (_sAliasQ) -> e5_lojaadt, "A2_NOME")) + ")"
					endif
					
				endif
		
				// Observacoes sao concatenadas com o historico.
				if ! empty ((_sAliasQ) -> codmemo)
					_aRet [_nLinha, .ExtratoCCObs] = alltrim (msmm ((_sAliasQ) -> codmemo,,,,3,,,'SZI'))
				endif
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	U_ML_SRArea (_aAreaAnt)
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet



/* Nunca foi finalizado. Robert, 08/05/2019
// --------------------------------------------------------------------------
// Gera array com dados para extrato da conta corrente do associado.
METHOD ExtratoCC2 (_sFilIni, _sFilFim, _dDataIni, _dDataFim, _sTMIni, _sTMFim, _lCodBase, _lSimples) Class ClsAssoc
	local _oSQL     := NIL
	local _sAliasQ  := ""
	local _aRet     := {}
	local _lInverte := .F.
	local _sDC      := ""
	local _nLinha   := 0
	local _sCodLoj  := ""
	local _nCodLoj  := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _nLojas   := 0

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if Self != NIL .and. ::Codigo != NIL .and. ::Loja != NIL
		// u_log ('Parametros:', _sFilIni, _sFilFim, _dDataIni, _dDataFim, _sTMIni, _sTMFim, _lCodBase, _lSimples)

		// Monta lista de codigos e lojas do associado
		_sCodLoj = "("
		if _lCodBase
			for _nLojas = 1 to len (::aCodigos)
				_sCodLoj += ::aCodigos [_nCodLoj] + ::aLojas [_nCodLoj] + iif (_nLojas < len (::aCodigos), ",", "")
			next
		else
			_sCodLoj += ::Codigo + ::Loja
		endif
		_sCodLoj += ")"
		u_log ('_sCodLoj = ', _sCodLoj)

		// Busca dados usando uma CTE para facilitar a uniao das consultas de diferentes tabelas.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH _FIN AS ("
		
		// Busca movimentos com correspondencia no financeiro.
		_oSQL:_sQuery += "SELECT 'SE5' AS ORIGEM, E5_FILIAL AS FILIAL, "
		_oSQL:_sQuery +=       " E5_DATA AS DATA, ZI_TM AS TIPO_MOV, E5_HISTOR AS HIST, E5_CLIFOR AS ASSOC, E5_LOJA AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
		_oSQL:_sQuery +=       " E5_VALOR AS VALOR, E5_RECPAG, E5_NUMERO AS NUMERO, E5_PREFIXO AS PREFIXO, E5_DOCUMEN AS DOCUMEN, E5_SEQ,"
		_oSQL:_sQuery +=       " E5_MOTBX, E5_PARCELA AS PARCELA, E5_TIPODOC, E5_FORNADT, E5_LOJAADT"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5, "
		_oSQL:_sQuery +=             RETSQLNAME ("SE2") + " SE2, "
		_oSQL:_sQuery +=             RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SE5.E5_FILIAL   BETWEEN '" + _sFilIni + "' AND '" + _sFilFim + "'"
		_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR   = SE2.E2_FORNECE"
		_oSQL:_sQuery +=   " AND SE5.E5_LOJA     = SE2.E2_LOJA"
		_oSQL:_sQuery +=   " AND SE5.E5_NUMERO   = SE2.E2_NUM"
		_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO  = SE2.E2_PREFIXO"
		_oSQL:_sQuery +=   " AND SE5.E5_PARCELA  = SE2.E2_PARCELA"
		_oSQL:_sQuery +=   " AND SE5.E5_TIPO    != ''"
		_oSQL:_sQuery +=   " AND SE5.E5_SITUACA != 'C'"
		_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
//		_oSQL:_sQuery +=   " AND SE5.E5_TIPODOC != 'PA'"  // Quando PA, quero suas baixas e nao a sua geracao.
		_oSQL:_sQuery +=   " AND SE5.E5_TIPODOC != 'JR'"
		_oSQL:_sQuery +=   " AND SE5.E5_DTDISPO  BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"

		_oSQL:_sQuery +=   " AND SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SE2.E2_FILIAL   = SE5.E5_FILIAL"
		_oSQL:_sQuery +=   " AND SE2.E2_FORNECE  = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=   " AND SE2.E2_LOJA     = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=   " AND SE2.E2_PREFIXO  = SZI.ZI_SERIE"
		_oSQL:_sQuery +=   " AND SE2.E2_NUM      = SZI.ZI_DOC"
		_oSQL:_sQuery +=   " AND SE2.E2_PARCELA  = SZI.ZI_PARCELA"

		_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = SE5.E5_FILIAL"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO IN " + _sCodLoj
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + _sTMIni + "' AND '" + _sTMFim + "'"

		_oSQL:_sQuery += " ), _SZI AS ( "

		// Busca registros da conta corrente que nao tem correspondencia no financeiro.
		_oSQL:_sQuery += "SELECT 'SZI' AS ORIGEM, ZI_FILIAL AS FILIAL, "
		_oSQL:_sQuery +=       " ZI_DATA AS DATA, ZI_TM AS TIPO_MOV, ZI_HISTOR AS HIST, ZI_ASSOC AS ASSOC, ZI_LOJASSO AS LOJASSO, ZI_CODMEMO AS CODMEMO,"
		_oSQL:_sQuery +=       " ZI_VALOR AS VALOR, '' AS E5_RECPAG, ZI_DOC AS NUMERO, ZI_SERIE AS PREFIXO, '' AS DOCUMEN, '' AS E5_SEQ,"
		_oSQL:_sQuery +=       " '' AS E5_MOTBX, ZI_PARCELA AS PARCELA, '' AS E5_TIPODOC, '' AS E5_FORNADT, '' AS E5_LOJAADT"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + _sFilIni + "' AND '" + _sFilFim + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO IN " + _sCodLoj
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + _sTMIni + "' AND '" + _sTMFim + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA     BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM _FIN"
		_oSQL:_sQuery +=                    " WHERE _FIN.FILIAL   = SZI.ZI_FILIAL"
		_oSQL:_sQuery +=                      " AND _FIN.ASSOC    = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                      " AND _FIN.LOJASSO  = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=                      " AND _FIN.PREFIXO  = SZI.ZI_SERIE"
		_oSQL:_sQuery +=                      " AND _FIN.NUMERO   = SZI.ZI_DOC"
		_oSQL:_sQuery +=                      " AND _FIN.PARCELA  = SZI.ZI_PARCELA)"
		_oSQL:_sQuery +=  "), _CTE AS ("
		_oSQL:_sQuery += " SELECT * FROM _FIN"
		_oSQL:_sQuery += " UNION ALL"
		_oSQL:_sQuery += " SELECT * FROM _SZI"
		_oSQL:_sQuery +=  ")"
		_oSQL:_sQuery += "SELECT _CTE.*, A2_NOME AS NOME, ZX5_10DESC AS DESC_TM, ZX5_10DC AS DEB_CRED, ZX5.ZX5_10CAPI, M0_FILIAL AS DESCFIL"
		_oSQL:_sQuery +=  " FROM _CTE,"
		_oSQL:_sQuery +=         RETSQLNAME ("ZX5") + " ZX5, "
		_oSQL:_sQuery +=         RETSQLNAME ("SA2") + " SA2, "
		_oSQL:_sQuery +=       " VA_SM0 AS SM0 "
		_oSQL:_sQuery += " WHERE SA2.A2_COD      = _CTE.ASSOC"
		_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = _CTE.LOJASSO"
		_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = _CTE.TIPO_MOV"
		_oSQL:_sQuery +=   " AND SM0.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SM0.M0_CODIGO   = '" + cEmpAnt + "'"
		_oSQL:_sQuery +=   " AND SM0.M0_CODFIL   = _CTE.FILIAL"
		// Ordenacao por varios campos por que, do contrario, a cada vez o relariorio traz uma nova ordenacao e fica dificil fazer comparativos...
		_oSQL:_sQuery += " ORDER BY DATA, TIPO_MOV, ORIGEM DESC, E5_SEQ, FILIAL, HIST, PREFIXO, NUMERO, PARCELA"
		u_log (_oSQL:_sQuery)
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		TCSetField (_sAliasQ, "DATA", "D")
		(_sAliasQ) -> (dbgotop ())                	
		do while ! (_sAliasQ) -> (eof ())
	
			// Gera nova linha para retorno.
			aadd (_aRet, array (.ExtratoCCQtColunas))
			_nLinha = len (_aRet)
			_aRet [_nLinha, .ExtratoCCFilial]    = (_sAliasQ) -> Filial
			_aRet [_nLinha, .ExtratoCCDescFil]   = (_sAliasQ) -> DescFil
			_aRet [_nLinha, .ExtratoCCData]      = (_sAliasQ) -> data
			_aRet [_nLinha, .ExtratoCCTM]        = (_sAliasQ) -> tipo_mov
			_aRet [_nLinha, .ExtratoCCDC]        = ''
			_aRet [_nLinha, .ExtratoCCValor]     = (_sAliasQ) -> valor
			_aRet [_nLinha, .ExtratoCCFornAdt]   = (_sAliasQ) -> e5_FornAdt
			_aRet [_nLinha, .ExtratoCCLojaAdt]   = (_sAliasQ) -> e5_LojaAdt
			_aRet [_nLinha, .ExtratoCCHist]      = ''
			_aRet [_nLinha, .ExtratoCCObs]       = ''
			_aRet [_nLinha, .ExtratoCCCapSocial] = (_sAliasQ) -> zx5_10capi
	
			// Verifica se o movimento deve ser tratado como debito ou como credito.
			_sDC = (_sAliasQ) -> deb_cred
			if (_sAliasQ) -> origem == 'SE5'
				_lInverte = .F.
				if _sDC == "D" .and. (_sAliasQ) -> e5_recpag == "R"
					_lInverte = ! _lInverte
				elseif _sDC == "C" .and. (_sAliasQ) -> e5_recpag == "P"
					_lInverte = ! _lInverte
				endif
				if (_sAliasQ) -> e5_motbx == "CMP" .and. (_sAliasQ) -> e5_tipodoc != 'CP'
					_lInverte = ! _lInverte
				endif
	
				if _lInverte
					if _sDC == "D"
						_sDC = "C"
					elseif _sDC == "C"
						_sDC = "D"
					endif
				endif
			endif
			_aRet [_nLinha, .ExtratoCCDC] = _sDC
	
			// Formato simples destina-se apenas a buscar valores.
			if ! _lSimples
				_aRet [_nLinha, .ExtratoCCHist] = alltrim ((_sAliasQ) -> hist)
		
				// Quando for baixa por compensacao, monta historico um pouco mais elaborado.
				if (_sAliasQ) -> e5_motbx == "CMP" .and. ! empty ((_sAliasQ) -> documen)
					//_aRet [_nLinha, .ExtratoCCHist] = 'Compens.tit. ' + substr ((_sAliasQ) -> documen, 1, 3) + '/' + substr ((_sAliasQ) -> documen, 4, 6) + '-' + substr ((_sAliasQ) -> documen, 10, 1)
					_aRet [_nLinha, .ExtratoCCHist] = 'Compens.tit. ' + left ((_sAliasQ) -> documen, 13)
		
					// Se foi compensacao contra outro fornecedor, busca seus dados.
					if (_sAliasQ) -> assoc + (_sAliasQ) -> lojasso != (_sAliasQ) -> e5_fornadt + (_sAliasQ) -> e5_lojaadt
						_aRet [_nLinha, .ExtratoCCHist] += ' de ' + (_sAliasQ) -> e5_fornadt + '/' + (_sAliasQ) -> e5_lojaadt + ' (' + alltrim (fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> e5_fornadt + (_sAliasQ) -> e5_lojaadt, "A2_NOME")) + ")"
					endif
					
				endif
		
				// Observacoes sao concatenadas com o historico.
				if ! empty ((_sAliasQ) -> codmemo)
					_aRet [_nLinha, .ExtratoCCObs] = alltrim (msmm ((_sAliasQ) -> codmemo,,,,3,,,'SZI'))
				endif
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	// u_log ('Retornando:', _aRet)
	U_ML_SRArea (_aAreaAnt)
	u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet
*/


// --------------------------------------------------------------------------
// Gera string para posteriormente montar demonstrativo de fechamento de safra em formato XML.
METHOD FechSafra (_sSafra) Class ClsAssoc
	local _sRet      := ''
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _aTipoNF   := {{'E', 'nfEntrada'}, {'C', 'nfCompra'}, {'V', 'nfComplemento'}}
	local _nTipoNF   := 0
	local _nTotPeso  := 0
	local _nTotValor := 0
	local _nTotSaldo := 0

	if empty (_sSafra)
		::UltMsg += "Safra nao informada"
	endif

	//u_logIni (GetClassName (::Self) + '.' + procname ())
	_sRet += '<assocFechSafra>'
	_sRet += '<associado>' + ::Codigo + '</associado>'
	_sRet += '<loja>' + ::Loja + '</loja>'
	_sRet += '<safra>' + _sSafra + '</safra>'

	// Busca notas do associado
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT TIPO_NF, FILIAL, DATA, DOC, SERIE, PRODUTO, DESCRICAO, GRAU, PESO_LIQ, VALOR_UNIT, VALOR_TOTAL, "
	_oSQL:_sQuery +=       " CASE WHEN SIST_CONDUCAO = 'E' THEN CLAS_FINAL ELSE CLAS_ABD END AS CLASSE,"
	_oSQL:_sQuery +=       " CASE WHEN TIPO_NF = 'E'"
	_oSQL:_sQuery +=            " THEN 'Nao serve como base para valor de compra'"
	_oSQL:_sQuery +=            " ELSE CASE WHEN TIPO_NF = 'C'"
	_oSQL:_sQuery +=                 " THEN ISNULL ((SELECT top 1 RTRIM (ZZ9_MSGNF) + CASE WHEN ZZ9_MSGNF = '' THEN '' ELSE ';' END + ZZ9_OBS"
	_oSQL:_sQuery +=                                 " FROM " + RetSQLName ("ZZ9") + " ZZ9 "
	_oSQL:_sQuery +=                                " WHERE ZZ9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                                  " AND ZZ9_FILIAL     = V.FILIAL"
	_oSQL:_sQuery +=                                  " AND ZZ9_SAFRA      = V.SAFRA"
	_oSQL:_sQuery +=                                  " AND ZZ9_FORNEC     = V.ASSOCIADO"
	_oSQL:_sQuery +=                                  " AND ZZ9_LOJA       = V.LOJA_ASSOC"
	_oSQL:_sQuery +=                                  " AND ZZ9_NFCOMP     = V.DOC"
	_oSQL:_sQuery +=                                  " AND ZZ9_SERCOM     = V.SERIE"
	_oSQL:_sQuery +=                                  " AND ZZ9_PRODUT     = V.PRODUTO"
	_oSQL:_sQuery +=                                  " AND ZZ9_GRAU       = V.GRAU"
	_oSQL:_sQuery +=                                  " AND ZZ9_CLASSE     = V.CLAS_FINAL"
	_oSQL:_sQuery +=                                  " AND ZZ9_CLABD      = V.CLAS_ABD"
	_oSQL:_sQuery +=                                  " AND ZZ9_VUNIT      = V.VALOR_UNIT)"
	_oSQL:_sQuery +=                        " , '')"
	_oSQL:_sQuery +=                 " ELSE ''"
	_oSQL:_sQuery +=                 " END"
	_oSQL:_sQuery +=            " END"
	_oSQL:_sQuery +=   	       " AS OBS"
	_oSQL:_sQuery +=  " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery += " WHERE SAFRA      = '" + _sSafra  + "'"
	_oSQL:_sQuery +=   " AND SAFRA     >= '2019'"  // Primeira safra em que este metodo foi implementado.
	_oSQL:_sQuery +=   " AND ASSOCIADO  = '" + ::Codigo + "'"
	_oSQL:_sQuery +=   " AND LOJA_ASSOC = '" + ::Loja   + "'"
	_oSQL:_sQuery += " ORDER BY CASE TIPO_NF WHEN 'E' THEN '1' WHEN 'C' THEN '2' WHEN 'V' THEN '3' END, DATA, DESCRICAO, GRAU"
	_sAliasQ := _oSQL:Qry2Trb (.F.)
		
	// Gera grupos de tags diferentes conforme o tipo de nota.
	for _nTipoNF = 1 to len (_aTipoNF)
		_nTotPeso = 0
		_nTotValor = 0
		_sRet += '<' + _aTipoNF [_nTipoNF, 2] + '>'
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			if (_sAliasQ) -> tipo_nf == _aTipoNF [_nTipoNF, 1]
				_sRet += '<' + _aTipoNF [_nTipoNF, 2] + 'Item>'
				_sRet += '<filial>'  + (_sAliasQ) -> filial + '</filial>'
				_sRet += '<doc>'     + (_sAliasQ) -> doc + '</doc>'
				_sRet += '<emissao>' + dtoc (stod ((_sAliasQ) -> data)) + '</emissao>'
				_sRet += '<varied>'  + alltrim ((_sAliasQ) -> produto) + '</varied>'
				_sRet += '<desc>'    + alltrim ((_sAliasQ) -> descricao) + '</desc>'
				_sRet += '<grau>'    + (_sAliasQ) -> grau + '</grau>'
				_sRet += '<clas>'    + alltrim ((_sAliasQ) -> classe) + '</clas>'
				_sRet += '<peso>'    + cvaltochar ((_sAliasQ) -> peso_liq) + '</peso>'
				_sRet += '<valunit>' + cvaltochar ((_sAliasQ) -> valor_unit) + '</valunit>'
				if _aTipoNF [_nTipoNF, 1] == 'V'  // Notas de complemento de valor nao tem quantidade.
					_sRet += '<valtot>'  + cvaltochar ((_sAliasQ) -> valor_unit) + '</valtot>'
				else
					_sRet += '<valtot>'  + cvaltochar ((_sAliasQ) -> peso_liq * (_sAliasQ) -> valor_unit) + '</valtot>'
				endif
				_sRet += '<obs>'     + alltrim ((_sAliasQ) -> obs) + '</obs>'
				_sRet += '</' + _aTipoNF [_nTipoNF, 2] + 'Item>'
				_nTotPeso += (_sAliasQ) -> peso_liq
				_nTotValor += (_sAliasQ) -> valor_unit * iif ((_sAliasQ) -> tipo_nf == 'V', 1, (_sAliasQ) -> peso_liq)
			endif
			(_sAliasQ) -> (dbskip ())
		//	u_log (_sRet)
		enddo

		// Exporta totais no final de cada tipo de nota.
		_sRet += '<' + _aTipoNF [_nTipoNF, 2] + 'Item>'
		_sRet += '<filial/>'
		_sRet += '<doc>TOTAIS</doc>'
		_sRet += '<emissao/>'
		_sRet += '<varied/>'
		_sRet += '<desc>TOTAIS NF ' + upper (_aTipoNF [_nTipoNF, 2]) + '</desc>'
		_sRet += '<grau/>'
		_sRet += '<clas/>'
		_sRet += '<peso>'    + cvaltochar (_nTotPeso) + '</peso>'
		_sRet += '<valunit/>'
		_sRet += '<valtot>'  + cvaltochar (round (_nTotValor, 2)) + '</valtot>'
		_sRet += '<obs/>'
		_sRet += '</' + _aTipoNF [_nTipoNF, 2] + 'Item>'

		// Fecha este tipo de nota
		_sRet += '</' + _aTipoNF [_nTipoNF, 2] + '>'
	next


	// Busca previsoes de pagamento (faturas e notas em aberto no contas a pagar).
	_sRet += '<faturaPagamento>'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT E2_NUM, E2_PREFIXO, E2_PARCELA, E2_VENCTO, E2_VALOR, E2_SALDO"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND E2_FILIAL  = '01'"  // Pagamentos sao feitos sempre pela matriz.
		_oSQL:_sQuery +=   " AND E2_FORNECE = '" + ::Codigo + "'"
		_oSQL:_sQuery +=   " AND E2_LOJA    = '" + ::Loja + "'"
		_oSQL:_sQuery +=   " AND E2_PREFIXO = '30'"  // Serie usada para notas e faturas de safra
		_oSQL:_sQuery +=   " AND ((E2_TIPO = 'FAT' AND E2_NUM like '" + _sSafra + "%') OR (E2_TIPO IN ('NF', 'DP') AND E2_FATURA = ''))"
		_oSQL:_sQuery +=   " AND E2_EMISSAO >= '" + _sSafra + "0101'"
		_oSQL:_sQuery +=   " AND E2_EMISSAO >= '20190101'"  // Primeira safra em que este metodo foi implementado. Para safras anteriores o tratamento era diferente.
		_oSQL:_sQuery +=   " ORDER BY E2_VENCTO, E2_NUM"
		_sAliasQ := _oSQL:Qry2Trb (.F.)
		_nTotValor = 0
		_nTotSaldo = 0
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			_sRet += '<faturaPagamentoItem>'
			_sRet += '<doc>'    + (_sAliasQ) -> e2_num + (_sAliasQ) -> e2_prefixo + (_sAliasQ) -> e2_parcela + '</doc>'
			_sRet += '<vencto>' + dtoc (stod ((_sAliasQ) -> e2_vencto)) + '</vencto>'
			_sRet += '<valor>'  + cvaltochar ((_sAliasQ) -> e2_valor) + '</valor>'
			_sRet += '<saldo>'  + cvaltochar ((_sAliasQ) -> e2_saldo) + '</saldo>'
			_nTotValor += (_sAliasQ) -> e2_valor
			_nTotSaldo += (_sAliasQ) -> e2_saldo
			_sRet += '</faturaPagamentoItem>'
			(_sAliasQ) -> (dbskip ())
		enddo

		// Ultima linha contem os totais
		_sRet += '<faturaPagamentoItem>'
		_sRet += '<doc>TOTAIS</doc>'
		_sRet += '<vencto/>'
		_sRet += '<valor>'  + cvaltochar (_nTotValor) + '</valor>'
		_sRet += '<saldo>'  + cvaltochar (_nTotSaldo) + '</saldo>'
		_sRet += '</faturaPagamentoItem>'
	_sRet += '</faturaPagamento>'


	// Regras de pagamento (informativo)
	_sRet += '<regraPagamento>'
		if _sSafra == '2019'
			_sRet += '<regraPagamentoItem>'
			_sRet += '<grupo>A</grupo>'
			_sRet += '<descricao>Bordo e organicas                - 5 vezes</descricao>'
			_sRet += '</regraPagamentoItem>'
			_sRet += '<regraPagamentoItem>'
			_sRet += '<grupo>B</grupo>'
			_sRet += '<descricao>Tintorias e viniferas espaldeira - 9 vezes</descricao>'
			_sRet += '</regraPagamentoItem>'
			_sRet += '<regraPagamentoItem>'
			_sRet += '<grupo>C</grupo>'
			_sRet += '<descricao>Demais variedades                - 11 vezes</descricao>'
			_sRet += '</regraPagamentoItem>'
		else
			_sRet += '<regraPagamentoItem>'
			_sRet += '<grupo>A</grupo>'
			_sRet += '<descricao>Sem definicao de regras de pagamento para esta safra</descricao>'
			_sRet += '</regraPagamentoItem>'
		endif
	_sRet += '</regraPagamento>'


	// Valores efetivos por variedade/grau
	_sRet += '<valoresEfetivos>'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT PRODUTO, DESCRICAO, GRAU, CLAS_ABD, CLAS_FINAL, PESO_LIQ, VUNIT_EFETIVO, VALOR_COMPRA + VALOR_COMPLEMENTO AS VALOR_TOTAL"
		_oSQL:_sQuery +=  " FROM VA_VPRECO_EFETIVO_SAFRA"
		_oSQL:_sQuery += " WHERE ASSOCIADO  = '" + ::Codigo + "'"
		_oSQL:_sQuery +=   " AND LOJA_ASSOC = '" + ::Loja + "'"
		_oSQL:_sQuery +=   " AND SAFRA      = '" + _sSafra + "'"
		_oSQL:_sQuery += " ORDER BY DESCRICAO, GRAU"
		_sAliasQ := _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			_sRet += '<valorEfetivoItem>'
			_sRet += '<varied>'         + alltrim ((_sAliasQ) -> produto) + '</varied>'
			_sRet += '<desc>'           + alltrim ((_sAliasQ) -> descricao) + '</desc>'
			_sRet += '<grau>'           + (_sAliasQ) -> grau + '</grau>'
			_sRet += '<clasLatada>'     + alltrim ((_sAliasQ) -> clas_abd) + '</clasLatada>'
			_sRet += '<clasEspaldeira>' + alltrim ((_sAliasQ) -> clas_final) + '</clasEspaldeira>'
			_sRet += '<peso>'           + cvaltochar ((_sAliasQ) -> peso_liq) + '</peso>'
			_sRet += '<valunit>'        + cvaltochar (round ((_sAliasQ) -> vunit_efetivo, 4)) + '</valunit>'
			_sRet += '<valtot>'         + cvaltochar (round ((_sAliasQ) -> valor_total, 2)) + '</valtot>'
			_sRet += '</valorEfetivoItem>'
			(_sAliasQ) -> (dbskip ())
		enddo
	_sRet += '</valoresEfetivos>'


	// Lancamentos com saldo na conta corrente
	_sRet += '<lctoCC>'
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SZI.ZI_DATA, ZI_TM, ZI_DOC, ZI_SERIE, ZI_PARCELA, ZI_HISTOR, ZX5_10DC, ZI_SALDO"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
		_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
		_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = SZI.ZI_TM"
		_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '  ' and 'zz'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Codigo + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       NOT IN ('10/17/18/19')"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA     like '" + _sSafra + "%'"
		_oSQL:_sQuery +=   " AND SZI.ZI_SALDO    > 0"
		_oSQL:_sQuery += " ORDER BY ZI_DATA, ZI_TM, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
		_sAliasQ := _oSQL:Qry2Trb (.F.)
		_nTotSaldo = 0
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			_sRet += '<lctoCCItem>'
			_sRet += '<dtMovto>' + dtoc (stod ((_sAliasQ) -> zi_data)) + '</dtMovto>'
			_sRet += '<doc>' + (_sAliasQ) -> zi_doc + '/' + (_sAliasQ) -> zi_serie + '-' + (_sAliasQ) -> zi_parcela + '</doc>'
			_sRet += '<hist>' + alltrim ((_sAliasQ) -> zi_histor) + '</hist>'
			_sRet += '<saldo>' + cvaltochar ((_sAliasQ) -> zi_saldo) + '</saldo>'
			_sRet += '<dc>' + (_sAliasQ) -> zx5_10dc + '</dc>'
			_sRet += '</lctoCCItem>'
			_nTotSaldo += (_sAliasQ) -> zi_saldo * iif ((_sAliasQ) -> zx5_10dc == 'D', -1, 1)
			(_sAliasQ) -> (dbskip ())
		enddo
		_sRet += '<lctoCCItem>'
		_sRet += '<dtMovto/>'
		_sRet += '<doc>TOTAIS</doc>'
		_sRet += '<hist>SALDO TOTAL</hist>'
		_sRet += '<saldo>' + cvaltochar (round (_nTotSaldo, 2)) + '</saldo>'
		_sRet += '<dc>' + iif (_nTotSaldo >= 0, 'C', 'D') + '</dc>'
		_sRet += '</lctoCCItem>'
	_sRet += '</lctoCC>'

	_sRet += '</assocFechSafra>'
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _sRet



// --------------------------------------------------------------------------
// Busca a idade (em anos) do associado em determinada data.
METHOD IdadeEm (_dDataRef) Class ClsAssoc
	local _nRet    := 0
	local _oDUtil  := ClsDUtil():New()
	if empty (::DtNascim)
		u_log ("Associado '" + ::Codigo + "/" + ::Loja + "' nao tem data de nascimento informada no cadastro.")
	else
		_nRet = int (_oDUtil:DifMeses (::DtNascim, _dDataRef) / 12)
	endif
return _nRet



// --------------------------------------------------------------------------
// Retorna array contendo lancamentos da conta corrente (SZI) com saldo na data. Usado inicialmente para gerar relatorios.
METHOD LctComSald (_sFilIni, _sFilFim, _dDataRef, _sTMIni, _sTMFim, _sTMNao) Class ClsAssoc
	local _aRet     := {}
	local _oSQL     := NIL
	local _sArqTrb  := ""
	
	u_logIni (GetClassName (::Self) + '.' + procname ())

	// Busca conta corrente
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SZI.R_E_C_N_O_,"
	_oSQL:_sQuery +=       " ZI_FILIAL, M0_FILIAL,"
	_oSQL:_sQuery +=       " ZI_TM, ZI_ASSOC, ZI_LOJASSO, ZI_HISTOR, ZI_DATA, ZI_SERIE, ZI_DOC, ZI_CODMEMO, ZI_PARCELA,"
	_oSQL:_sQuery +=       " A2_NOME, ZX5_10DESC, ZX5_10DC,"
	_oSQL:_sQuery +=       " 0 AS SALDO"
	_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
	_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5, "
	_oSQL:_sQuery +=             RETSQLNAME ("SA2") + " SA2, "
	_oSQL:_sQuery +=         "VA_SM0 SM0 "
	_oSQL:_sQuery += " WHERE SA2.A2_COD      = SZI.ZI_ASSOC"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA     = SZI.ZI_LOJASSO"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL   = '" + xfilial ("SA2")  + "'"
	_oSQL:_sQuery +=   " AND SM0.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SM0.M0_CODIGO   = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=   " AND SM0.M0_CODFIL   = SZI.ZI_FILIAL"
	_oSQL:_sQuery +=   " AND ZX5.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
	_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = SZI.ZI_TM"
	_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '" + _sFilIni + "' AND '" + _sFilFim + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + ::Codigo + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + ::Loja + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_TM       BETWEEN '" + _sTMIni + "' AND '" + _sTMFim + "'"
	_oSQL:_sQuery +=   " AND SZI.ZI_TM       NOT IN " + FormatIn (_sTMNao, '/')
	_oSQL:_sQuery +=   " AND SZI.ZI_DATA     <= '" + dtos (_dDataRef) + "'"
	_oSQL:_sQuery += " ORDER BY ZI_DATA, ZI_TM, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
	u_log (_oSQL:_sQuery)
	_sArqTrb = _oSQL:Qry2Trb ()

	// Verifica o saldo dos lancamentos e monta retorno apenas com os que interessam.
	(_sArqTrb) -> (dbgotop ())
	do while ! (_sArqTrb) -> (eof ())
		_oCtaCorr := ClsCtaCorr():New ((_sArqTrb) -> R_E_C_N_O_)
		_nSaldo = _oCtaCorr:SaldoEm (_dDataRef)
		if _nSaldo > 0
			aadd (_aRet, {(_sArqTrb) -> zi_filial, ;
			              alltrim ((_sArqTrb) -> m0_filial), ;
			              stod ((_sArqTrb) -> zi_data), ;
			              (_sArqTrb) -> zi_serie, ;
			              (_sArqTrb) -> zi_doc, ;
			              (_sArqTrb) -> zi_parcela, ;
			              (_sArqTrb) -> zi_tm, ;
			              (_sArqTrb) -> zx5_10desc, ;
			              (_sArqTrb) -> zi_histor, ;
			              (_sArqTrb) -> ZX5_10DC, ;
			              _nSaldo})
		endif
		(_sArqTrb) -> (dbskip ())
	enddo
	u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet



// --------------------------------------------------------------------------
// Busca o saldo do associado (conta corrente) na data passada por parametro.
METHOD SaldoEm (_dDataSld) Class ClsAssoc
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _dUltZZM   := ctod ('')
	local _aRet      := {}
	local _aExtrato  := {}
	local _nExtrato  := 0
	local _aRetQry   := {}

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua
		_lContinua = (::Codigo != NIL .and. ::Loja != NIL)
		u_log ('[' + GetClassName (::Self) + '.' + procname () + '] Calculando saldo do associado ', ::Codigo + '/' + ::Loja, 'em ', _dDataSld)
	endif

	if _lContinua
		_aRet = afill (array (.SaldoAssocQtColunas), 0)

		// Busca o ultimo periodo fechado e calcula a partir dele. 
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT TOP 1 ZZM_CNSOCD, ZZM_CNSOCC, ZZM_CSOCD, ZZM_CSOCC, ZZM_DATA "
		_oSQL:_sQuery += "   FROM " + RetSQLName ("ZZM") + " ZZM "
		_oSQL:_sQuery +=  " WHERE ZZM.ZZM_FILIAL  = '" + xfilial ("ZZM") + "' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_ASSOC   = '" + ::Codigo + "' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_LOJA    = '" + ::Loja + "' "
		_oSQL:_sQuery +=    " AND ZZM.D_E_L_E_T_  = '' "
		_oSQL:_sQuery +=    " AND ZZM.ZZM_DATA   <= '" + dtos (_dDataSld) + "'"
		_oSQL:_sQuery +=  " ORDER BY ZZM_DATA DESC"
		_aRetQry = aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aRetQry) == 1
			//u_log ('Inicializando com valores do fechamento anterior:', _aRetQry)
			_aRet [.SaldoAssocCapNaoSocialDebito]  = _aRetQry [1, 1] 
			_aRet [.SaldoAssocCapNaoSocialCredito] = _aRetQry [1, 2] 
			_aRet [.SaldoAssocCapSocialDebito]     = _aRetQry [1, 3] 
			_aRet [.SaldoAssocCapSocialCredito]    = _aRetQry [1, 4]
			_dUltZZM = stod (_aRetQry [1, 5])
		else
			u_log ('Nao encontrei ZZM anterior. Inicializando os saldos com zero.')
			_dUltZZM = stod ('19000101')
		endif

		// Soh preciso gerar extrato se a data que encontrei no ZZM for menor que a solicitada.
		if _dUltZZM < _dDataSld
		
			// Os movimentos do periodo sao lidos diretamente do extrato do associado, para manter consistencia com outras rotinas.
			_aExtrato = aclone (::ExtratoCC ('', 'zz', _dUltZZM + 1, _dDataSld, '', 'zz', .F., .T.))
			//u_log ('Extrato:', _aExtrato)
			
			for _nExtrato = 1 to len (_aExtrato)
				if _aExtrato [_nExtrato, .ExtratoCCDC] $ 'DC'  // Alguns lancamentos nao movimentam valor.
					do case
					case _aExtrato [_nExtrato, .ExtratoCCDC] == 'D' .and. _aExtrato [_nExtrato, .ExtratoCCCapSocial] == 'N'
						_aRet [.SaldoAssocCapNaoSocialDebito] += _aExtrato [_nExtrato, .ExtratoCCValor]
					case _aExtrato [_nExtrato, .ExtratoCCDC] == 'C' .and. _aExtrato [_nExtrato, .ExtratoCCCapSocial] == 'N'
						_aRet [.SaldoAssocCapNaoSocialCredito] += _aExtrato [_nExtrato, .ExtratoCCValor]
					case _aExtrato [_nExtrato, .ExtratoCCDC] == 'D' .and. _aExtrato [_nExtrato, .ExtratoCCCapSocial] == 'S'
						_aRet [.SaldoAssocCapSocialDebito] += _aExtrato [_nExtrato, .ExtratoCCValor]
					case _aExtrato [_nExtrato, .ExtratoCCDC] == 'C' .and. _aExtrato [_nExtrato, .ExtratoCCCapSocial] == 'S'
						_aRet [.SaldoAssocCapSocialCredito] += _aExtrato [_nExtrato, .ExtratoCCValor]
					otherwise
						::UltMsg += "Retorno '" + _aExtrato [_nExtrato, .ExtratoCCCapSocial] + "' do metodo ExtratoCC desconhecido (nao indica se eh capital social ou nao). Saldo do associado vai ficar comprometido."
						u_help (::UltMsg)
					endcase
				endif
			next
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet



// --------------------------------------------------------------------------
// Busca o saldo da cota capital na data de referencia.
METHOD SldQuotCap (_dDataRef, _lUltSafra) Class ClsAssoc
	local _aAreaAnt  := U_ML_SRArea ()
	local _aRet      := {}
	local _aRetQry   := {}
	local _nRetQry   := 0
	local _oSQL      := NIL
	local _dLimInf   := ctod ('')
	local _dLimSup   := ctod ('')
	local _dReadmis  := ctod ('')
	local _oCtaCorr  := NIL
	local _sRetTxt   := ""
	local _sRetXML   := ""
	local _sCRLF     := chr (13) + chr (10)
	local _lContinua := .T.
	local _sUltSafra := ""
	local _lAtivo    := .T.

	//u_logIni (GetClassName (::Self) + '.' + procname ())
	
	if _lContinua .and. (valtype (_dDataRef) != "D" .or. empty (_dDataRef))
		::UltMsg += "Nao foi informada data de referencia para buscar saldo de cota capital."
		_lContinua = .F.
	endif

	// Busca ultima safra somente quando solicitado, pois eh uma leitura demorada.
	_lUltSafra = iif (_lUltSafra == NIL, .F., _lUltSafra)
	if _lContinua .and. _lUltSafra
		_sUltSafra = ::UltSafra (_dDataRef)
	endif

	if _lContinua
		_lAtivo = ::Ativo (_dDataRef)
	endif

	// Define intervalo de datas para calculo do saldo da quota capital: vai ser
	// o periodo em que ele foi (ou ainda eh) associado.
	if _lContinua
		_dLimInf = ::DtEntrada (_dDataRef)
		_dLimSup = ::DtSaida (_dDataRef)
		if ! empty (_dLimSup)
			// Se tem data de saida, verifica possibilidade de readmissao posterior.
			_dReadmis = ::DtEntrada (_dLimSup + 1)
		else
			_dLimSup = _dDataRef
		endif
	endif

	// Busca movimentos envolvendo capital social em qualquer filial e em qualquer codigo/loja do associado.
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=                " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                  " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=                  " AND SA2.A2_COD     = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                  " AND SA2.A2_LOJA    = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=                  " AND SA2.A2_VACBASE = '" + ::CodBase + "'"
		_oSQL:_sQuery +=                  " AND SA2.A2_VALBASE = '" + ::LojaBase + "'"
		_oSQL:_sQuery +=   " )"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM IN ('10','11','12','17','18','19','20','27')"
		_oSQL:_sQuery += " ORDER BY ZI_DATA"
		_oSQL:Log ()
		_aRetQry = _oSQL:Qry2Array ()
		_aRet = afill (array (.QtCapQtColunas), 0)
		for _nRetQry = 1 to len (_aRetQry)
			_oCtaCorr := ClsCtaCorr():New (_aRetQry [_nRetQry, 1])

			// Movimentos ocorridos dentro do periodo em que foi associado
			if _oCtaCorr:DtMovto >= _dLimInf .and. _oCtaCorr:DtMovto <= _dLimSup
				do case
				case _oCtaCorr:TM == '10'  // Implantacao saldo
					_aRet [.QtCapSaldoImplantadoEnquantoSocio] += _oCtaCorr:Valor
				case _oCtaCorr:TM == '11'  // Resgate
					_nSaldoMov = _oCtaCorr:SaldoEm (_dDataRef)
					_aRet [.QtCapSaldoResgatadoEnquantoSocio] += _oCtaCorr:Valor - _nSaldoMov
					_aRet [.QtCapResgatesEmAbertoEnquantoSocio] += _nSaldoMov
				case _oCtaCorr:TM $ '12/20'  // Integralizacao
					_nSaldoMov = _oCtaCorr:SaldoEm (_dDataRef)
					_aRet [.QtCapIntegralizadoEnquantoSocio] += _oCtaCorr:Valor - _nSaldoMov
					_aRet [.QtCapIntegralizEmAbertoEnquantoSocio] += _nSaldoMov
				case _oCtaCorr:TM == '17'
					_aRet [.QtCapSaidasTransfEnquantoSocio] += _oCtaCorr:Valor
				case _oCtaCorr:TM == '18'
					_aRet [.QtCapEntradasTransfEnquantoSocio] += _oCtaCorr:Valor
				case _oCtaCorr:TM == '19'
					_aRet [.QtCapIntegralizacaoSobrasEnquantoSocio] += _oCtaCorr:Valor
				case _oCtaCorr:TM == '27'
					_aRet [.QtCapBaixaPorInatividade] += _oCtaCorr:Valor
				endcase
			
			// Movimentos ocorridos apos desassociacao, mas limitados a uma possivel readmissao.
			elseif _oCtaCorr:DtMovto > _dLimSup .and. (empty (_dReadmis) .or. _oCtaCorr:DtMovto < _dReadmis)
				do case
				case _oCtaCorr:TM == '11'  // Resgate
					_nSaldoMov = _oCtaCorr:SaldoEm (stod ('20491231'))  // 
					_aRet [.QtCapSaldoResgatadoQuandoExSocio] += _oCtaCorr:Valor - _nSaldoMov
					_aRet [.QtCapResgatesEmAbertoQuandoExSocio] += _nSaldoMov
				case _oCtaCorr:TM == '19'
					_aRet [.QtCapIntegralizacaoSobrasEnquantoExSocio] += _oCtaCorr:Valor
				endcase
			endif

			// Resgates (restituicao) em aberto na data de referencia.
	//		if _oCtaCorr:TM == '11' .and. _oCtaCorr:DtMovto <= _dDataRef
			if _oCtaCorr:TM == '11' //.and. _oCtaCorr:DtMovto <= _dDataRef
				_nSaldoMov = _oCtaCorr:SaldoEm (_dDataRef)
				_aRet [.QtCapTotalResgatesEmAberto] += _nSaldoMov
				if _oCtaCorr:DtMovto <= _dDataRef  // AVALIAR SE REALMENTE Na data do dia ja se considera sem o saldo. Rubiane/Robert, 04/02/2019.
					_aRet [.QtCapResgatesEmAbertoNaData] += _nSaldoMov
				endif
			endif
		next

		// Calcula o saldo de capital social do associado na data de referencia.
		// Somente terah saldo se estiver ativo nesssa data.
	//	if _dDataRef >= _dLimInf .and. _dDataRef <= _dLimSup
		if _dDataRef >= _dLimInf .and. _dDataRef <= _dLimSup
			_aRet [.QtCapSaldoNaData] = 0
			_aRet [.QtCapSaldoNaData] += _aRet [.QtCapSaldoImplantadoEnquantoSocio]
			_aRet [.QtCapSaldoNaData] += _aRet [.QtCapIntegralizadoEnquantoSocio]
			_aRet [.QtCapSaldoNaData] -= _aRet [.QtCapSaldoResgatadoEnquantoSocio]
			_aRet [.QtCapSaldoNaData] += _aRet [.QtCapIntegralizacaoSobrasEnquantoSocio]
			_aRet [.QtCapSaldoNaData] += _aRet [.QtCapEntradasTransfEnquantoSocio]
			_aRet [.QtCapSaldoNaData] -= _aRet [.QtCapSaidasTransfEnquantoSocio]
			_aRet [.QtCapSaldoNaData] -= _aRet [.QtCapBaixaPorInatividade]
			//
			// Resgates solicitados, mesmo ainda nao pagos pela cooperativa, nao sao mais considerados como parte do capital social.
			_aRet [.QtCapSaldoNaData] -= _aRet [.QtCapResgatesEmAbertoEnquantoSocio]
			//
			// Integralizacoes, mesmo ainda nao pagas, sao consideradas como parte do capital social.
			_aRet [.QtCapSaldoNaData] += _aRet [.QtCapIntegralizEmAbertoEnquantoSocio]
		else
			//u_log ('nao era associado na data de referencia')
		endif

		// Habilitar este trecho para conferencias, quando necessario.
		if .f.
			u_log ('QtCapSaldoNaData........................:', _aRet [.QtCapSaldoNaData])
			u_log ('QtCapSaldoImplantadoEnquantoSocio.......:', _aRet [.QtCapSaldoImplantadoEnquantoSocio])
			u_log ('QtCapSaldoResgatadoEnquantoSocio........:', _aRet [.QtCapSaldoResgatadoEnquantoSocio])
			u_log ('QtCapIntegralizadoEnquantoSocio.........:', _aRet [.QtCapIntegralizadoEnquantoSocio])
			u_log ('QtCapResgatesEmAbertoEnquantoSocio......:', _aRet [.QtCapResgatesEmAbertoEnquantoSocio])
			u_log ('QtCapIntegralizEmAbertoEnquantoSocio....:', _aRet [.QtCapIntegralizEmAbertoEnquantoSocio])
			u_log ('QtCapResgatesEmAbertoQuandoExSocio......:', _aRet [.QtCapResgatesEmAbertoQuandoExSocio])
			u_log ('QtCapSaldoResgatadoQuandoExSocio........:', _aRet [.QtCapSaldoResgatadoQuandoExSocio])
			u_log ('QtCapSaidasTransfEnquantoSocio..........:', _aRet [.QtCapSaidasTransfEnquantoSocio])
			u_log ('QtCapEntradasTransfEnquantoSocio........:', _aRet [.QtCapEntradasTransfEnquantoSocio])
			u_log ('QtCapIntegralizacaoSobrasEnquantoSocio..:', _aRet [.QtCapIntegralizacaoSobrasEnquantoSocio])
			u_log ('QtCapIntegralizacaoSobrasEnquantoExSocio:', _aRet [.QtCapIntegralizacaoSobrasEnquantoExSocio])
			u_log ('QtCapResgatesEmAbertoNaData.............:', _aRet [.QtCapResgatesEmAbertoNaData])
			u_log ('QtCapTotalResgatesEmAberto..............:', _aRet [.QtCapTotalResgatesEmAberto])
			u_log ('QtCapBaixaPorInatividade................:', _aRet [.QtCapBaixaPorInatividade])
		endif

		// Monta mensagem para retorno em formato texto.
		_sRetTXT := ""
		_sRetTXT += "Associado " + ::Codigo + '/' + ::Loja + ' - ' + ::Nome + _sCRLF + _sCRLF
	//	_sRetTXT += "Associado " + ::Codigo + '/' + ::Loja + ' - ' + alltrim (::Nome) + '   Posicao em ' + dtoc (_dDataRef) + _sCRLF + _sCRLF
		_sRetTXT += "Data de nascimento..: " + dtoc (::DtNascim) + "     falecimento...: " + dtoc (::DtFalecim) + _sCRLF
		_sRetTXT += "Data de associacao..: " + dtoc (::DtEntrada (_dDataRef)) + "     desligamento..: " + dtoc (::DtSaida (_dDataRef)) + _sCRLF
//		_sRetTXT += "Coop. de origem.....: " + ::CoopOrigem + _sCRLF  + _sCRLF 
		_sRetTXT += "Coop. de origem.....: " + ::CoopOrigem + iif (_lUltSafra, "             ultima safra..: " + _sUltSafra, '') + _sCRLF
		_sRetTXT += "Ativo...............: " + iif (_lAtivo , 'sim', 'nao (' + alltrim (::MotInativ) + ")") + _sCRLF + _sCRLF
		_sRetTXT += "=====================================================================" + _sCRLF
		_sRetTXT += "                      DADOS DE CAPITAL SOCIAL" + _sCRLF + _sCRLF
		_sRetTXT += "Posicao de " + dtoc (_dDataRef) + ":" + _sCRLF
		_sRetTXT += "--------------------" + _sCRLF
		_sRetTXT += "Saldo capital social..............................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapSaldoNaData],                         "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Saldo implantado..................................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapSaldoImplantadoEnquantoSocio],        "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Valor integralizado...............................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapIntegralizadoEnquantoSocio],          "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Integralizacoes em aberto.........................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapIntegralizEmAbertoEnquantoSocio],     "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Valor resgatado...................................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapSaldoResgatadoEnquantoSocio],         "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Pedidos resgate em aberto.........................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapResgatesEmAbertoEnquantoSocio],       "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Transf.quota feitas para outros associados........: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapSaidasTransfEnquantoSocio],           "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Transf.quota recebidas de outros associados.......: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapEntradasTransfEnquantoSocio],         "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Integralizacoes de sobras.........................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapIntegralizacaoSobrasEnquantoSocio],   "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Baixas por inatividade............................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapBaixaPorInatividade],                 "@E 999,999,999.99") + _sCRLF + _sCRLF
		_sRetTXT += "Detalhes (enquanto ex-associado):" + _sCRLF
		_sRetTXT += "---------------------------------" + _sCRLF
		_sRetTXT += "Resgates efetuados................................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapSaldoResgatadoQuandoExSocio],         "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Pedidos resgate em aberto.........................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapResgatesEmAbertoQuandoExSocio],       "@E 999,999,999.99") + _sCRLF
		_sRetTXT += "Integralizacoes de sobras.........................: " + GetMV ("MV_SIMB1") + " " + transform (_aRet [.QtCapIntegralizacaoSobrasEnquantoExSocio], "@E 999,999,999.99") + _sCRLF
		_aRet [.QtCapRetTXT] = _sRetTXT


		// Monta mensagem para retorno em formato pronto para ser convertido em XML.
		_sRetXML := "<assocCapitalSocial>"
		_sRetXML += '<associado>'                    + ::Codigo                                                       + '</associado>'
		_sRetXML += '<loja>'                         + ::Loja                                                         + '</loja>'
		_sRetXML += '<nome>'                         + alltrim (::Nome)                                               + '</nome>'
		_sRetXML += '<dataNascimento>'               + dtoc (::DtNascim)                                              + '</dataNascimento>'
		_sRetXML += '<dataFalecimento>'              + dtoc (::DtFalecim)                                             + '</dataFalecimento>'
		_sRetXML += '<dataAssociacao>'               + dtoc (::DtEntrada (_dDataRef))                                 + '</dataAssociacao>'
		_sRetXML += '<dataDesligamento>'             + dtoc (::DtSaida (_dDataRef))                                   + '</dataDesligamento>'
		_sRetXML += '<dataReferencia>'               + dtoc (_dDataRef)                                               + '</dataReferencia>'
		_sRetXML += '<coopOrigem>'                   + ::CoopOrigem                                                   + '</coopOrigem>'
		if _lUltSafra
			_sRetXML += '<ultimaSafraEntregue>'          + _sUltSafra                                                     + '</ultimaSafraEntregue>'
		endif
		_sRetXML += '<ativo>'                        + iif (_lAtivo, 'S', 'N')                                        + '</ativo>'
		_sRetXML += '<motivoInatividade>'            + ::MotInativ                                                    + '</motivoInatividade>'
		_sRetXML += '<SaldoNaData>'                  + cValToChar (_aRet [.QtCapSaldoNaData])                         + '</SaldoNaData>'
		_sRetXML += '<SaldoImplantado>'              + cValToChar (_aRet [.QtCapSaldoImplantadoEnquantoSocio])        + '</SaldoImplantado>'
		_sRetXML += '<SaldoIntegralizado>'           + cValToChar (_aRet [.QtCapIntegralizadoEnquantoSocio])          + '</SaldoIntegralizado>'
		_sRetXML += '<IntegralizacoesEmAberto>'      + cValToChar (_aRet [.QtCapIntegralizEmAbertoEnquantoSocio])     + '</IntegralizacoesEmAberto>'
		_sRetXML += '<ValorResgatado>'               + cValToChar (_aRet [.QtCapSaldoResgatadoEnquantoSocio])         + '</ValorResgatado>'
		_sRetXML += '<ResgatesEmAberto>'             + cValToChar (_aRet [.QtCapResgatesEmAbertoEnquantoSocio])       + '</ResgatesEmAberto>'
		_sRetXML += '<TransfParaOutrosAssoc>'        + cValToChar (_aRet [.QtCapSaidasTransfEnquantoSocio])           + '</TransfParaOutrosAssoc>'
		_sRetXML += '<TransfDeOutrosAssoc>'          + cValToChar (_aRet [.QtCapEntradasTransfEnquantoSocio])         + '</TransfDeOutrosAssoc>'
		_sRetXML += '<IntegralizacoesSobras>'        + cValToChar (_aRet [.QtCapIntegralizacaoSobrasEnquantoSocio])   + '</IntegralizacoesSobras>'
		_sRetXML += '<IntegralizacoesSobrasExSocio>' + cValToChar (_aRet [.QtCapIntegralizacaoSobrasEnquantoExSocio]) + '</IntegralizacoesSobrasExSocio>'
		_sRetXML += '<BaixaPorInatividade>'          + cValToChar (_aRet [.QtCapBaixaPorInatividade])                 + '</BaixaPorInatividade>'
		_sRetXML += '<ExSocioResgatesEfetuados>'     + cValToChar (_aRet [.QtCapSaldoResgatadoQuandoExSocio])         + '</ExSocioResgatesEfetuados>'
		_sRetXML += '<ExSocioResgatesEmAberto>'      + cValToChar (_aRet [.QtCapResgatesEmAbertoQuandoExSocio])       + '</ExSocioResgatesEmAberto>'
		_sRetXML += "</assocCapitalSocial>"
		_aRet [.QtCapRetXML] = _sRetXML
	endif

	U_ML_SRArea (_aAreaAnt)
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _aRet



// --------------------------------------------------------------------------
// Retorna o tempo (em anos) de associacao em determinada data.
METHOD TmpAssoc (_dDataRef) Class ClsAssoc
	local _nRet    := 0
	local _oDUtil  := ClsDUtil():New()
	//u_logIni (GetClassName (::Self) + '.' + procname ())
	_nRet = int (_oDUtil:DifMeses (::DtEntrada (_dDataRef), _dDataRef) / 12)
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return _nRet



// --------------------------------------------------------------------------
// Retorna a ultima safra em que o associado entregou producao.
METHOD UltSafra (_dDataRef) Class ClsAssoc
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _sRet      := ""

	if Self != NIL .and. ::Codigo != NIL .and. ::Loja != NIL
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX (SAFRA)"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE CODBASEASSOC  = '" + ::CodBase + "'"
		_oSQL:_sQuery +=    " AND LOJABASEASSOC = '" + ::LojaBase + "'"
		//_oSQL:_sQuery +=    " AND TIPO_NF       = 'C'"
		if valtype (_dDataRef) == 'D'
			_oSQL:_sQuery +=    " AND DATA <= '" + dtos (_dDataRef) + "'"
		endif
		_sRet = _oSQL:RetQry ()
	endif
	U_ML_SRArea (_aAreaAnt)
return _sRet

