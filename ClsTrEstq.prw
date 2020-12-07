// Programa:  ClsTrEstq
// Autor:     Robert Koch
// Data:      29/07/2018
// Descricao: Declaracao de classe de representacao de solicitacoes de transferencia de estoque.
//            Criada com base no programa VAFPCP01 de Daniel Scheeren (Proccdata)
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 08/04/2019 - Catia   - include TbiConn.ch 
// 12/04/2019 - Robert  - Deixa variavel _lClsTrEst declarada para posterior uso em pontos de entrada.
// 25/09/2019 - Robert  - Quando o produto tiver controle via FullWMS, libera somente para usuarios do grupo 029.
//                      - Criado atributo LibNaIncl.
// 26/09/2019 - Cl·udia - IncluÌda validaÁ„o de lote mÌnimo.
// 27/11/2020 - Robert  - Quando existir etiqueta relacionada, tenta inutiliza-la automaticamente.
//                      - Transf. envolvendo o AX01 (FullWMS) liberadas, momentaneamente, para aceitar liberacao manual (sem ser o Full).
// 04/12/2020 - RObert  - Criado tratamento para produto destino diferente do produto origem.
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsTrEstq ()
return


// ==========================================================================
CLASS ClsTrEstq

	// Declaracao das propriedades da Classe
	data Filial    // Filial onde foi incluido o registro (campo ZAG_FILIAL)
	data FilOrig   // Filial origem.
	data FilDest   // Filial destino.
	data Docto     // Numero docto na tabela ZAG.
	data DtEmis    // Data emissao (inclusao) do ZAG. Nao obrigatoriamente a mesma da geracao do movto.
	data RegZAG    // Numero registro (RECNO) no ZAG.
	data OP        // Numero da OP, quando a solic. for gerada por OP.
	data Motivo    // Descricao do motivo da transferencia. 
	data ProdOrig  // Codigo do produto origem a transferir.
	data ProdDest  // Codigo do produto destino (inicilmente a ideia eh sempre transferir para o msmo produto)
	data AlmOrig   // Almox (local) origem
	data AlmDest   // Almox (local) destino
	data ContrLoc  // Indica se o produto controla lote (campo B1_LOCALIZ)
	data ContrLote // Indica se o produto controla lote (campo B1_RASTRO)
	data EndOrig   // Endereco origem (quando produto tiver controle de localizacao)
	data EndDest   // Endereco destino  (quando produto tiver controle de localizacao)
	data Etiqueta  // Numero da etiqueta (tabela ZA1), quando existir
	data Executado // Indica se jah foi executado (se gerou alguma movimentacao) S=Executado;E=Erro na execucao;X=Estornado
	data FWProdOrig // Indica se o produto origem eh controlado pelo FullWMS
	data FWProdDest // Indica se o produto destino eh controlado pelo FullWMS
//	data IdSC5     // Id (numero pedido) gerado na tabela SC5 (quando transf. entre filiais) 
//	data IdSD3     // Id (D3_NUMSEQ) gerado na tabela SD3 (quando transf. interna)
	data ImprEtq   // ID da immpressora (caso seja necessario gerar e imprimir etiqueta) 
	data LibNaIncl // Indica se, no momento da inclusao do registro no ZAG, jah deve tentar fazer as liberacoes.
	data LoteOrig  // Lote origem (quando produto tiver controle de lote)
	data LoteDest  // Lote destino (quando produto tiver controle de lote)
	data QtdSolic  // Quantidade solicitada (inicial a ser transferida) 
//	data QtdReceb  // Quantidade recebida (confirmacao de recebimento)
	data UltMsg    // Ultima mensagem gerada.
	data UsrIncl   // Usuario que fez a inclusao do registro
	data UsrAutOri // Usuario que autorizou pelo almox origem
	data UsrAutDst // Usuario que autorizou pelo almox destino
	data UsrAutPCP // Usuario que autorizou pelo PCP
	data UsrAutQld // Usuario que autorizou pela qualidade

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD AlmUsaFull ()
	METHOD AtuZAG ()
	METHOD Estorna ()
	METHOD Exclui ()
	METHOD Executa ()
	METHOD Inclui ()
	METHOD GeraEtiq ()
	METHOD GeraSD3 ()
	METHOD Grava ()
	METHOD Libera ()
ENDCLASS


// --------------------------------------------------------------------------
// Construtor.
METHOD New (_nRecno) Class ClsTrEstq
	local _nRegZAG  := 0
	::Filial    = ''
	::FilOrig   = ''
	::FilDest   = ''
	::Docto     = ''
	::DtEmis    = ''
	::RegZAG    = 0
	::OP        = ''
	::Motivo    = ''
	::ProdOrig  = ''
	::ProdDest  = ''
	::AlmOrig   = ''
	::AlmDest   = ''
	::EndOrig   = ''
	::EndDest   = ''
	::Etiqueta  = ''
	::Executado = ''
	::FWProdOrig = .F.
	::FWProdDest = .F.
	::ImprEtq   = ''
	::LibNaIncl = .T.
	::LoteOrig  = ''
	::LoteDest  = ''
	::QtdSolic  = 0
	::UltMsg    = ''
	::UsrIncl   = ''
	::UsrAutOri = ''
	::UsrAutDst = ''
	::UsrAutPCP = ''
	::UsrAutQld = ''

	// Se receber numero de registro do ZAG, alimenta atributos da classe com seus dados.
	if valtype (_nRecno) == "N"
		_nRegZAG = zag -> (recno ())
		zag -> (dbgoto (_nRecno))
		::Filial    = zag -> zag_filial
		::FilOrig   = zag -> zag_FilOri
		::FilDest   = zag -> zag_FilDst
		::RegZAG    = zag -> (recno ())
		::Docto     = zag -> zag_doc
		::DtEmis    = zag -> zag_emis
		::UsrIncl   = zag -> zag_usrinc
		::OP        = zag -> zag_op
		::Motivo    = zag -> zag_Motivo
		::ProdOrig  = zag -> zag_PrdOri
		::ProdDest  = zag -> zag_PrdDst
		::AlmOrig   = zag -> zag_AlmOri
		::AlmDest   = zag -> zag_AlmDst
		::EndOrig   = zag -> zag_EndOri
		::EndDest   = zag -> zag_EndDst
		::FWProdOrig = (fBuscaCpo ("SB1", 1, xfilial ("SB1") + ::ProdOrig, 'B1_VAFULLW') == 'S')
		::FWProdDest = (fBuscaCpo ("SB1", 1, xfilial ("SB1") + ::ProdDest, 'B1_VAFULLW') == 'S')
		::Executado = zag -> zag_exec
		::LoteOrig  = zag -> zag_LotOri
		::LoteDest  = zag -> zag_LotDst
		::QtdSolic  = zag -> zag_QtdSol
		::UsrAutOri = zag -> zag_UAutO
		::UsrAutDst = zag -> zag_UAutD
		::UsrAutPCP = zag -> zag_UAutP
		::UsrAutQld = zag -> zag_UAutQ
		zag -> (dbgoto (_nRegZAG))
	endif
Return ::self



// --------------------------------------------------------------------------
// Verifica se o almoxarifado eh controlado via FullWMS.
METHOD AlmUsaFull (_sAlm) Class ClsTrEstq
return (_sAlm $ '01/')



// --------------------------------------------------------------------------
// Atualiza (no arquivo) determinado atributo.
METHOD AtuZAG (_sCampo, _xValor) Class ClsTrEstq
	local _lRet := .F.
	local _aAreaAnt  := U_ML_SRArea ()

	u_log2 ('info', 'Atualizando campo ' + _sCampo + ' com ' + cvaltochar (_xValor))
	if ::RegZAG > 0
		zag -> (dbgoto (::RegZAG))
		reclock ("ZAG", .F.)
		zag -> &(_sCampo) = _xValor
		msunlock ()
		_lRet = .T.
	else
		::UltMsg += "Registro ainda nao gravado na tabela ZAG. Atualizacao do campo '" + _sCampo + "' nao pode ser feita na funcao " + procname ()
		_lRet = .F.
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet



// --------------------------------------------------------------------------
// Estorna movimento (transf. foi excluida pela tela padrao, preciso mudar o status.
METHOD Estorna () Class ClsTrEstq
	::Executado = 'X'
	::AtuZAG ("zag_exec", ::Executado)
return



// --------------------------------------------------------------------------
// Exclui movimento.
METHOD Exclui () Class ClsTrEstq
	local _lContinua := .T.
	local _oSQL      := NIL
	local _sEtiq     := ''

	u_logIni (GetClassName (::Self) + '.' + procname ())
	::UltMsg = ""

	if _lContinua .and. ::Executado == 'S'
		::UltMsg += "Este lancamento ja gerou movimentacao. Estorne, antes, o movimento gerado."
		_lContinua = .F.
	endif
	if _lContinua
		zag -> (dbgoto (::RegZAG))
		if zag -> (recno ()) != ::RegZAG
			::UltMsg += "Nao foi possivel localizar o registro correspondente no arquivo ZAG. Exclusao nao sera' efetuada."
			_lContinua = .F.
		endif                   
	endif
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT TOP 1 ZA1_CODIGO"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZA1")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZA1_FILIAL  = '" + xfilial ("ZA1") + "'"
		_oSQL:_sQuery += " AND ZA1_IDZAG   = '" + ::Docto + "'"
		_oSQL:_sQuery += " AND ZA1_APONT  != 'I'"
		_sEtiq = _oSQL:RetQry (1, .F.)
		if ! empty (_sEtiq)
			// Tenta inutilizar a etiqueta
			if ! U_EtqPllIn (_sEtiq, .F.)
				::UltMsg += "Existe a etiqueta " + _sEtiq + " gerada para esta solicitacao. Inutilize, antes, a etiqueta."
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		reclock ("ZAG", .F.)
		zag -> (dbdelete ())
		msunlock ()
		::UltMsg += "Documento " + ::Docto + " excluido."
	endif

	if ! _lContinua
		u_help (::UltMsg)
	endif

	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Executa a movimentacao necessaria para a transferencia.
METHOD Executa (_lMensagem) Class ClsTrEstq
	local _lContinua := .T.
	local _sMsgInt   := ''

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua .and. ::RegZAG == 0
		_sMsgInt += "Transferencia ainda nao gravada na tabela ZZG"
		_lContinua = .F.
	endif
	if _lContinua .and. ::Executado == 'S'
		_sMsgInt += "Lancamento ja executado."
		_lContinua = .F.
	endif
	if _lContinua .and. ::Executado == 'X'
		_sMsgInt += "Lancamento ja estornado."
		_lContinua = .F.
	endif
	if _lContinua .and. ::FilOrig != cFilAnt
		_sMsgInt += "Esta transferencia deve ser originada na filial '" + ::FilOrig + "'."
		_lContinua = .F.
	endif
	if _lContinua .and. empty (::UsrAutOri)
		_sMsgInt += "Falta liberacao do responsavel pelo almox origem"
		_lContinua = .F.
	endif
	if _lContinua .and. empty (::UsrAutDst)
		_sMsgInt += "Falta liberacao do responsavel pelo almox destino"
		_lContinua = .F.
	endif
	if _lContinua .and. empty (::UsrAutPCP)
		_sMsgInt += "Falta liberacao do responsavel pelo PCP"
		_lContinua = .F.
	endif
	if _lContinua .and. empty (::UsrAutQld)
		_sMsgInt += "Falta liberacao do responsavel pela qualidade"
		_lContinua = .F.
	endif

	if ! _lContinua
		u_log2 ('info', 'Ainda nao estah em condicoes de executar - msg.interna: ' + _sMsgInt)
	endif

	// Concatena a mensagen interna somente se a rotina chamadora quiser ve-la.
	if _lMensagem
		::UltMsg += _sMsgInt
	endif
	if _lContinua .and. ::FilDest == ::FilOrig
		_lContinua = ::GeraSD3 ()
	endif
	if _lContinua .and. ::FilDest != ::FilOrig
		_lContinua = ::GeraSC5 ()
	endif

	if ! _lContinua .and. ! empty (::UltMsg)
		u_help (::UltMsg)
	endif

//	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua



// --------------------------------------------------------------------------
// Gera movimentacao interna de transferencia.
METHOD GeraSD3 () class ClsTrEstq
	local _lContinua := .T.
	local _sDoc      := ""
	local _aAuto261  := {}
	local _aItens    := {}
	local _sChaveEx  := 'ZAG' + ::Docto
	local _aRegsSD3  := {}

	u_log2 ('info', 'Iniciando ' + GetClassName (::Self) + '.' + procname ())

	// Se o produto ainda nao existe no almoxarifado destino, cria-o, para nao bloquear a transferencia de estoque.
	if _lContinua
		sb2 -> (dbsetorder (1))
		if ! sb2 -> (dbseek (xfilial ("SB2") + ::ProdDest + ::AlmDest))
			CriaSB2 (::ProdDest, ::AlmDest)
		endif
	endif

	if _lContinua
		
		// Variavel publica usada para retornad erros na funcao U_Help().
		if type ("_sErroAuto") != 'C'
			u_log ('Criando variavel _sErroAuto')
			private _sErroAuto := ""
		endif
	
		// Deixar private por que pode vir a ser testada nos pontos de entrada.
		private _lClsTrEst := .T.

		_sDoc := CriaVar ("D3_DOC")
		aadd(_aAuto261,{_sDoc,dDataBase})
		aadd(_aItens, ::ProdOrig)  // Produto origem
		aadd(_aItens,'')           //D3_DESCRI				Descri¡Ño do Produto Origem
		aadd(_aItens,'')           //D3_UM					Unidade de Medida Origem
		aadd(_aItens,::AlmOrig)    //Almox origem
		aadd(_aItens,::EndOrig)    //Endereco origem
		aadd(_aItens,::ProdDest)   //Codigo do produto destino
		aadd(_aItens,'')           //D3_DESCRI				Descri¡Ño do Produto de Destino
		aadd(_aItens,'')           //D3_UM					Unidade de Medida de Destino
		aadd(_aItens,::AlmDest)    //Almox destino
		aadd(_aItens,::EndDest)    //Endereco destino
		aadd(_aItens,"")           //D3_NUMSERI			Numero de Serie
		aadd(_aItens,::LoteOrig)   //Lote origem
		aadd(_aItens,"")           //D3_NUMLOTE			Numero do lote
		aadd(_aItens,ctod(""))     //D3_DTVALID			Validade Origem
		aadd(_aItens,0)            //D3_POTENCI			PotÕncia
		aadd(_aItens,::QtdSolic)   // Quantidade
		aadd(_aItens,0)            //D3_QTSEGUM			Segunda Quantidade
		aadd(_aItens,criavar("D3_ESTORNO"))  //D3_ESTORNO			Estorno
		aadd(_aItens,criavar("D3_NUMSEQ"))   //D3_NUMSEQ 			Numero de Sequencia
		aadd(_aItens,::LoteDest)             // Lote destino
		aadd(_aItens,ctod(""))               // D3_DTVALID			Validade de Destino
		aadd(_aItens,criavar("D3_ITEMGRD"))  // D3_ITEMGRD			Item Grade
		//aadd(_aItens,0)                      // Per.Imp. D3_PERIMP
		aadd(_aItens,'')                     // D3_OBSERVA
		aadd(_aItens,::Motivo)               // motivo
		aadd(_aItens,ctod (''))              // dt digit (vai ser gravado pelo SQL)
		aadd(_aItens,'')                     // hr digit (vai ser gravado pelo SQL)
		//aadd(_aItens,'')                     // laudo laboratorial (tabela ZAF)
		aadd(_aItens,::Etiqueta)             // D3_VAETIQ Etiqueta
		aadd(_aItens,_sChaveEx)        // Chave externa D3_VACHVEX
		//u_log (_aItens)
		aadd(_aAuto261, aclone (_aItens))

		lMsErroAuto := .F.
		MSExecAuto({|x,y| mata261(x,y)},_aAuto261,3) //INCLUSAO

		// Ja tive casos de nao gravar e tambem nao setar a variavel lMsErroAuto. Por isso vou conferir a gravacao.
		if ! lMsErroAuto
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := " SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=    " AND D3_VACHVEX = '" + _sChaveEx + "'"
			_aRegsSD3 := aclone (_oSQL:Qry2Array (.F., .F.))
			if len (_aRegsSD3) != 2
				::UltMsg += "Problemas na gravacao da transferencia. Nao encontrei os dois registros que deveriam ter sido gravados. Query para conferencia: " + _oSQL:_sQuery
				lMsErroAuto = .T.
			endif
		endif

		If lMsErroAuto
			if ! empty (_sErroAuto)
				::UltMsg += _sErroAuto
			endif
			if ! empty (NomeAutoLog ())
				::UltMsg += U_LeErro (memoread (NomeAutoLog ()))
			endif
			if empty (::UltMsg)
				::UltMsg += '[Sem descricao do erro]'
			endif
			::UltMsg = "Erro interno na rotina de transferencia: " + ::UltMsg
			::Executado = 'E'
			::AtuZAG ("zag_exec", ::Executado)
			_lContinua = .F.
		else
			::Executado = 'S'
			::AtuZAG ("zag_exec", ::Executado)
			::UltMsg += "Movto.gerado no Protheus com DOC=" + _sDoc
		endif
	endif

return _lContinua



// --------------------------------------------------------------------------
// Verifica necessidade e gera etiqueta para esta transferencia.
METHOD GeraEtiq (_lMsg) Class ClsTrEstq
	local _lContinua := .T.
	local _sEtiq     := ''
	local _sMsg      := ''

	u_logIni (GetClassName (::Self) + '.' + procname ())
	if empty (::RegZAG)
		_sMsg += "Registro ainda nao gravado na tabela ZAG. Etiqueta nao vai ser gerada."
		_lContinua = .F.
	endif
	if _lContinua .and. ! ::AlmUsaFull (::AlmDest)
		_sMsg += "Almoxarifado destino nao controlado pelo FullWMS. Etiqueta nao deve ser gerada."
		_lContinua = .F.
	endif
	if _lContinua .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + ::ProdDest, "B1_VAFULLW") != "S"
		_sMsg += "Produto destino '" + alltrim (::ProdDest) + "' nao controlado pelo FullWMS. Etiqueta nao pode ser gerada."
		_lContinua = .F.
	endif
	if _lContinua
		// Usa mesma rotina de etiquetas dos pallets de producao.
		_sEtiq = U_IncEtqPll (::ProdDest, '', ::QtdSolic, '', '', '', '', date (), '', ::Docto)
		if ! empty (_sEtiq)
			::UltMsg += 'Etiqueta gerada:' + _sEtiq + '.'
		
			// Se tem impressora informada, jah faz a impressao da etiqueta.
			if ! empty (::ImprEtq)
				U_ImpZA1 (_sEtiq, ::ImprEtq)
			endif
		endif
	endif
	if _lMsg .and. ! empty (_sMsg)
		u_help (_sMsg)
	endif
	u_logFim (GetClassName (::Self) + '.' + procname ())
return



// --------------------------------------------------------------------------
// Grava novo registro.
METHOD Grava () Class ClsTrEstq
	local _lContinua := .T.
	local _lRet      := .F.

	u_logIni (GetClassName (::Self) + '.' + procname ())
	if ::RegZAG != 0
		::UltMsg += "Registro ja existe na tabela ZAG (recno " + cvaltochar (::RegZAG) + ") e nao vai ser regravado."
		_lContinua = .F.
	endif

	// Verifica campos obrigatorios, nao aceitos, tamanhos, tipos, etc.
	if _lContinua
		if empty (::FilOrig) ; ::UltMsg += "Filial de origem deve ser informada."          ; _lContinua = .F. ; endif
		if empty (::FilDest) ; ::UltMsg += "Filial destino deve ser informada."            ; _lContinua = .F. ; endif
		if empty (::AlmOrig) ; ::UltMsg += "Almoxarifado de origem deve ser informado."    ; _lContinua = .F. ; endif
		if empty (::AlmDest) ; ::UltMsg += "Almoxarifado destino deve ser informado."      ; _lContinua = .F. ; endif
		if empty (::DtEmis)  ; ::UltMsg += "Data de emissao deve ser informada."           ; _lContinua = .F. ; endif
		if empty (::UsrIncl) ; ::UltMsg += "Nome solicitante deve ser informado."          ; _lContinua = .F. ; endif
		if empty (::Motivo)  ; ::UltMsg += "Motivo da transferencia deve ser informado."   ; _lContinua = .F. ; endif
		if empty (::ProdOrig); ::UltMsg += "Produto deve ser informado."                   ; _lContinua = .F. ; endif
		if empty (::QtdSolic); ::UltMsg += "Quantidade solicitada deve ser informada."     ; _lContinua = .F. ; endif
		if ! empty (::Docto) ; ::UltMsg += "Documento NAO deve ser informado na inclusao."          ; _lContinua = .F. ; endif
		if ! empty (::RegZAG); ::UltMsg += "RECNO da tabela ZAG NAO deve ser informado na inclusao."; _lContinua = .F. ; endif
		if valtype (::QtdSolic) != 'N'
			::UltMsg += "Quantidade deve ser do tipo numerico."
			_lContinua = .F.
		else
			if ::QtdSolic <= 0
				::UltMsg += "Quantidade solicitada zerada ou negativa."
				_lContinua = .F.
			endif
		endif

		// Por enquanto, nao vou aceitar transferencia entre filiais. Robert, 11/04/2019
		if ::FilDest != ::FilOrig
			::UltMsg += "Transferencias entre filiais ainda nao sao permitidas nesta rotina."
			_lContinua = .F.
		endif

		// Verifica tamanhos de campos para evitar, por exemplo, uma chamada passando o produto com tamanho != 15
		// Usa tamanhos fixos (nao busca n SX3) por questao de performance, jah que sao campos chave e dificilmente mudarao de tamanho.  
		if _lContinua
			if len (::FilOrig)  !=  2; ::UltMsg += "Filial origem deve ter tamanho 2"    ; _lContinua = .F.; endif
			if len (::FilDest)  !=  2; ::UltMsg += "Filial destino deve ter tamanho 2"   ; _lContinua = .F.; endif
			if len (::ProdOrig) != 15; ::UltMsg += "Produto origem deve ter tamanho 15"  ; _lContinua = .F.; endif
			if len (::ProdDest) != 15; ::UltMsg += "Produto destino deve ter tamanho 15" ; _lContinua = .F.; endif
			if len (::AlmOrig)  !=  2; ::UltMsg += "Alm.origem deve ter tamanho 2"       ; _lContinua = .F.; endif
			if len (::AlmDest)  !=  2; ::UltMsg += "Alm.destino deve ter tamanho 2"      ; _lContinua = .F.; endif
			if ! empty (::EndOrig)  .and. len (::EndOrig)  != 15; ::UltMsg += "Endereco origem deve ter tamanho 15" ; _lContinua = .F.; endif
			if ! empty (::EndDest)  .and. len (::EndDest)  != 15; ::UltMsg += "Endereco destino deve ter tamanho 15"; _lContinua = .F.; endif
			if ! empty (::LoteOrig) .and. len (::LoteOrig) != 10; ::UltMsg += "Lote origem deve ter tamanho 10"     ; _lContinua = .F.; endif
			if ! empty (::loteDest) .and. len (::LoteDest) != 10; ::UltMsg += "Lote destino deve ter tamanho 10"    ; _lContinua = .F.; endif
		endif
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + ::ProdOrig, .F.))
			::UltMsg += "Produto '" + alltrim (::ProdOrig) + "' nao cadastrado."
			_lContinua = .F.
		else
			if sb1 -> b1_rastro == 'L' .and. empty (::LoteOrig) .and. ! ::AlmUsaFull (::AlmOrig)  // Alm 02 gera solicitacoes ao FullWMS
				::UltMsg += "Produto origem controla lotes. Lote de origem deve ser informado."
				_lContinua = .F.
			endif
			if sb1 -> b1_rastro == 'S'
				::UltMsg += "Produto origem controla sublote. Falta tratamento neste programa."
				_lContinua = .F.
			endif
			if sb1 -> b1_localiz == 'S' .and. empty (::EndOrig) .and. ! ::AlmUsaFull (::AlmOrig)  // Alm 02 gera solicitacoes ao FullWMS
				::UltMsg += "Produto origem controla localizacao. Endereco de origem deve ser informado."
				_lContinua = .F.
			endif
			if ! empty (::LoteOrig) .and. sb1 -> b1_rastro != 'L'
				::UltMsg += "Lote origem nao deve ser informado pois o produto '" + alltrim (::ProdOrig) + "' nao controla lote."
				_lContinua = .F.
			endif
			if ! empty (::EndOrig) .and. sb1 -> b1_localiz != 'S'
				::UltMsg += "Endereco origem nao deve ser informado pois o produto '" + alltrim (::ProdOrig) + "' nao controla localizacao."
				_lContinua = .F.
			endif
			::FWProdOrig = (sb1 -> b1_vaFullW == 'S')
			::FWProdDest = (sb1 -> b1_vaFullW == 'S')  // Como geralmente eh o mesmo item, jah deixo a variavel carregada.
		endif
		if ::ProdDest != ::ProdOrig
			if ! sb1 -> (dbseek (xfilial ("SB1") + ::ProdDest, .F.))
				::UltMsg += "Produto '" + alltrim (::ProdDest) + "' nao cadastrado."
				_lContinua = .F.
			else
				if sb1 -> b1_rastro == 'L' .and. empty (::LoteDest)
					::UltMsg += "Produto destino controla lotes. Lote destino deve ser informado."
					_lContinua = .F.
				endif
				if sb1 -> b1_rastro == 'S'
					::UltMsg += "Produto destino controla sublote. Falta tratamento neste programa."
					_lContinua = .F.
				endif
				if sb1 -> b1_localiz == 'S' .and. empty (::EndDest)
					::UltMsg += "Produto destino controla localizacao. Endereco destino deve ser informado."
					_lContinua = .F.
				endif
				if ! empty (::LoteDest) .and. sb1 -> b1_rastro != 'L'
					::UltMsg += "Lote destino nao deve ser informado pois o produto '" + alltrim (::ProdDest) + "' nao controla lote."
					_lContinua = .F.
				endif
				if ! empty (::EndDest) .and. sb1 -> b1_localiz != 'S'
					::UltMsg += "Endereco destino nao deve ser informado pois o produto '" + alltrim (::ProdDest) + "' nao controla localizacao."
					_lContinua = .F.
				endif
				::FWProdDest = (sb1 -> b1_vaFullW == 'S')
			endif
		endif
	endif

	if _lContinua .and. ! empty (::AlmOrig)
		nnr -> (dbsetorder (1))  // NNR_FILIAL+NNR_CODIGO
		if ! nnr -> (dbseek (xfilial ("NNR") + ::AlmOrig, .F.))  // Nao pesquisa pela filial origem por que o NNR eh compartilhado.
			::UltMsg += "Almoxarifado origem '" + ::AlmOrig + "' nao cadastrado."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::AlmDest)
		nnr -> (dbsetorder (1))
		if ! nnr -> (dbseek (xfilial ("NNR") + ::AlmDest, .F.))  // Nao pesquisa pela filial origem por que o NNR eh compartilhado.
			::UltMsg += "Almoxarifado destino '" + ::AlmDest + "' nao cadastrado."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::LoteOrig)
		sb8 -> (dbsetorder (5))  // B8_FILIAL+B8_PRODUTO+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
		if ! sb8 -> (dbseek (::FilOrig + ::ProdOrig + ::LoteOrig, .F.))
			::UltMsg += "Lote origem '" + ::LoteOrig + "' nao encontrado para o produto '" + ::ProdOrig + "' na filial '" + ::FilOrig + "'."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::LoteDest)
		sb8 -> (dbsetorder (5))  // B8_FILIAL+B8_PRODUTO+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
		if ! sb8 -> (dbseek (::FilDest + ::ProdDest + ::LoteDest, .F.))
			::UltMsg += "Lote destino '" + ::LoteDest + "' ja existe para o produto '" + ::ProdDest + "' na filial '" + ::FilDest + "'."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::EndOrig)
		sbe -> (dbsetorder (1))  // BE_FILIAL+BE_LOCAL+BE_LOCALIZ
		if ! sbe -> (dbseek (::FilOrig + ::AlmOrig + ::EndOrig, .F.))
			::UltMsg += "Endereco origem '" + ::EndOrig + "' nao encontrado no almoxarifado '" + ::AlmOrig + "' da filial '" + ::FilOrig + "'."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::EndDest)
		sbe -> (dbsetorder (1))  // BE_FILIAL+BE_LOCAL+BE_LOCALIZ
		if ! sbe -> (dbseek (::FilDest + ::AlmDest + ::EndDest, .F.))
			::UltMsg += "Endereco destino '" + ::EndDest + "' nao encontrado no almoxarifado '" + ::AlmDest + "' da filial '" + ::FilDest + "'."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ! empty (::OP)
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek (::FilOrig + ::OP, .F.))
			::UltMsg += "OP '" + ::OP + "' nao encontrada na filial '" + ::FilOrig + "'."
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. ::AlmUsaFull (::AlmOrig)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT MIN (A5_VAQSOLW)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA5") + " SA5 "
		_oSQL:_sQuery +=  " WHERE SA5.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=  " AND SA5.A5_FILIAL   = '" + xfilial ("SA5") + "'"
		_oSQL:_sQuery +=  " AND SA5.A5_PRODUTO  = '" + ::ProdOrig + "'"
		_oSQL:_sQuery +=  " AND SA5.A5_VAQSOLW != 0"
		_oSQL:Log ()
		_nTamLote = _oSQL:RetQry (1, .F.)
		//
		_nResto = ::QtdSolic % _nTamLote
		if _nResto != 0
			_lContinua = .F.
			::UltMsg += "Produto e almox. de origem operam com FullWMS, e o produto tem lote mÌnimo de "+ alltrim(str(_nTamLote)) + ". N„o ser· possÌvel gerar uma movimentaÁ„o."
		endif
	endif
	
	if _lContinua
		::Docto = GetSXENum ("ZAG", "ZAG_DOC")
		u_log ("Gravando ZAG_DOC:", ::Docto, ::ProdOrig, ::QtdSolic)
		reclock ("ZAG", .T.)
		zag -> zag_filial = xfilial ("ZAG")
		zag -> zag_FilOri = ::FilOrig
		zag -> zag_filDst = ::FilDest
		zag -> zag_doc    = ::Docto
		zag -> zag_emis   = ::DtEmis
		zag -> zag_usrinc = ::UsrIncl
		zag -> zag_op     = ::OP
		zag -> zag_Motivo = ::Motivo
		zag -> zag_PrdOri = ::ProdOrig
		zag -> zag_PrdDst = ::ProdDest
		zag -> zag_AlmOri = ::AlmOrig
		zag -> zag_AlmDst = ::AlmDest
		zag -> zag_EndOri = ::EndOrig
		zag -> zag_EndDst = ::EndDest
		zag -> zag_LotOri = ::LoteOrig
		zag -> zag_LotDst = ::LoteDest
		zag -> zag_QtdSol = ::QtdSolic
//		zag -> zag_UAutP  = 'Auto'  // Liberacao automatica sempre
//		zag -> zag_UAutQ  = 'Auto'  // Liberacao automatica sempre
		msunlock ()
		do while __lSX8
			ConfirmSX8 ()
		enddo

		::RegZAG = zag -> (recno ())
		::UltMsg += "Solic.de transf.gerada: " + ::Docto + '.'
		_lRet = .T.
	endif

	// Verifica necessidade de gerar etiqueta
	if _lRet
		::GeraEtiq (.F.)
	endif

	// Faz as liberacoes que forem possiveis
	if _lRet
		if ::LibNaIncl
			::Libera (.F.)
		endif
	endif

	if ! _lContinua .and. ! empty (::UltMsg)
		u_help (::UltMsg)
	endif

	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lRet



// --------------------------------------------------------------------------
// Grava as liberacoes para as quais o usuario corrente tem permissao.
METHOD Libera (_lMsg, _sUserName) Class ClsTrEstq
	local _lNenhuma := .T.
	local _oSQL     := NIL
	local _aLib     := {}
//	local _sMsg     := ""

//	u_logIni (GetClassName (::Self) + '.' + procname ())

	_lMsg = iif (_lMsg == NIL, .T., _lMsg)
	_sUserName = iif (_sUserName == NIL, cUsername, _sUserName)

	// Se ainda tem alguma liberacao pendente...
	if empty (::UsrAutOri) .or. empty (::UsrAutDst) .or. empty (::UsrAutPCP) .or. empty (::UsrAutQld)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT rtrim (LIBERADORES_ALMORI)    AS ORI,"
		_oSQL:_sQuery +=       " rtrim (LIBERADORES_ALMDST)    AS DST"
		_oSQL:_sQuery +=  " FROM VA_VSOL_TRANSF_ESTOQUE"
		_oSQL:_sQuery += " WHERE ZAG_FILIAL = '" + xfilial ("ZAG") + "'"
		_oSQL:_sQuery +=   " AND ZAG_DOC    = '" + ::Docto + "'"
		_oSQL:Log ()
		_aLib := aclone (_oSQL:Qry2Array (.F., .F.))
		u_log2 ('debug', 'Liberadores alm ' + ::AlmOrig + '(origem) :' + alltrim (_aLib [1, 1]))
		u_log2 ('debug', 'Liberadores alm ' + ::AlmDest + '(destino):' + alltrim (_aLib [1, 2]))
		u_log2 ('debug', 'Testando com usuario ' + _sUserName)
		if empty (::UsrAutOri) .and. alltrim (upper (_sUserName)) $ _aLib [1, 1]
			u_log2 ('info', 'Usuario tem liberacao para o almox. origem')
			/* Permitido ateh que a gente implemente integracao com o endereco 'avarias' do Full (GLPI 8914)
			if ::FWProdOrig .and. ::AlmUsaFull (::AlmOrig) .and. _sUserName != 'FULLWMS'
				u_log2 ('info', '... mas o produto usa Full e o AX origem eh controlado pelo FullWMS')
				_sMsg = "Produto '" + alltrim (::ProdOrig) + "' tem controle via FullWMS no AX '" + ::AlmOrig + "' e nao deve ser movimentado manualmente."
				if U_ZZUVL ('029', __cUserId, .F.) .and. U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					if ::AtuZAG ("zag_UAutO", _sUserName)
						::UsrAutOri = _sUserName
						::UltMsg += iif (_lMsg, "AX orig.liberado. ", '')
						_lNenhuma = .F.
					endif
				else
					::UltMsg += _sMsg
				endif
			else
			*/
				if ::AtuZAG ("zag_UAutO", _sUserName)
					::UsrAutOri = _sUserName
					::UltMsg += iif (_lMsg, "AX orig.liberado. ", '')
					_lNenhuma = .F.
				endif
//			endif
		endif

		if empty (::UsrAutDst) .and. alltrim (upper (_sUserName)) $ _aLib [1, 2]
			u_log2 ('info', 'Usuario tem liberacao para o almox. destino')
			/* Permitido ateh que a gente implemente integracao com o endereco 'avarias' do Full (GLPI 8914)
			if ::FWProdDest .and. ::AlmUsaFull (::AlmDest) .and. _sUserName != 'FULLWMS'
				u_log ('info', '... mas o produto usa Full e o AX destino eh controlado pelo FullWMS')
				_sMsg = "Produto '" + alltrim (::ProdDest) + "' tem controle via FullWMS no AX '" + ::AlmDest + "' e nao deve ser movimentado manualmente."
				if U_ZZUVL ('029', __cUserId, .F.) .and. U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					if ::AtuZAG ("zag_UAutD", _sUserName)
						::UsrAutDst = _sUserName
						::UltMsg += iif (_lMsg, "AX dest.liberado. ", '')
						_lNenhuma = .F.
					endif
				else
					::UltMsg += _sMsg
				endif
			else
			*/
				if ::AtuZAG ("zag_UAutD", _sUserName)
					::UltMsg += iif (_lMsg, "AX dest.liberado. ", '')
					::UsrAutDst = _sUserName
					_lNenhuma = .F.
				endif
//			endif
		endif
		
		// Inicialmente a liberacao de PCP e qualidade vai ser automatica
		if empty (::UsrAutPCP) .and. ::AtuZAG ("zag_UAutP", 'Auto') // _sUserName)
			::UsrAutPCP = 'Auto' //_sUserName
			_lNenhuma = .F.
		endif
		if empty (::UsrAutQld) .and. ::AtuZAG ("zag_UAutQ", 'Auto') // _sUserName)
			::UsrAutQld = 'Auto' //_sUserName
			_lNenhuma = .F.
		endif

	endif

	if _lNenhuma
		u_log2 ('info', 'Nada a liberar')
		::UltMsg += iif (_lMsg, "Nenhuma liberacao pendente para este usuario.", '')
	endif

	// Tenta executar a transferencia
	::Executa (.F.)

//	u_logFim (GetClassName (::Self) + '.' + procname ())
return

