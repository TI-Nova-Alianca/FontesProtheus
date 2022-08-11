// Programa.: ClsCtaRap
// Autor....: Claudia Lionço
// Data.....: 19/05/2022
// Descricao: Declaracao de classe de representacao de movimentos da conta corrente de rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Classe
// #Descricao         #Representa atributos e metodos da conta corrente de rapel
// #PalavasChave      #conta_corrente_rapel
// #TabelasPrincipais #ZC0
// #Modulos           #FAT #CTB 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"
#include "VA_Inclu.prw"

// ------------------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsCtaRap()
return

// ------------------------------------------------------------------------------------
CLASS ClsCtaRap

	// Declaracao das propriedades da Classe
	data Filial
	data Rede
	data LojaRed
	data Cliente
	data LojaCli
	data TM
	data Data
	data Hora
	data Usuario
	data Histor
	data SeqZC0
	data Documento
	data Serie
	data Parcela
	data Produto
	data Status
	data Rapel
	data Saldo
	data Origem
	data NFEmissao
	data RegZC0
	data UltMsg

	// Declaracao dos Metodos da classe
	METHOD New()
    METHOD GeraAtrib()
	METHOD Grava()
	METHOD GeraSeq()
	METHOD RetCodRede()
	METHOD RetNomeRede()
	METHOD TipoRapel()
	METHOD AtuSaldo()
	METHOD RetSaldo()
	METHOD RetDebCre()
	METHOD FecharPeriodo()
	METHOD AbrirPeriodo()
	METHOD Exclui()
	METHOD EhNegativo()
	//METHOD VerifUser()
ENDCLASS
//
// --------------------------------------------------------------------------
// Construtor
METHOD New(_nRecno) Class ClsCtaRap
	local _nRegZC0  := 0

	// Se receber numero de registro do ZC0, alimenta atributos da classe com seus dados.
	if valtype (_nRecno) == "N"
		_nRegZC0 = zc0 -> (recno ())
		zc0 -> (dbgoto (_nRecno))
		::GeraAtrib ("ZC0")
		zc0 -> (dbgoto (_nRegZC0))
	else
		::GeraAtrib ("")
	endif
	
Return ::self
//
// --------------------------------------------------------------------------
// Alimenta os atributos da classe
METHOD GeraAtrib(_sOrigem) Class ClsCtaRap
	local _aAreaAnt  := U_ML_SRArea()

	// Defaults
	::Filial  	:= xfilial ("ZC0")
	::Rede    	:= ''		
	::LojaRed 	:= ''	
	::Cliente	:= ''	
	::LojaCli	:= ''	
	::TM      	:= ''	
	::Data    	:= ctod ('')
	::Hora    	:= ''
	::Usuario 	:= cUserName
	::Histor  	:= ''
	::SeqZC0  	:= ''
	::Documento := ''
	::Serie 	:= ''
	::Parcela	:= ''
	::Produto   := ''
	::Status    := ''
	::Rapel		:= 0
	::Saldo		:= 0
	::Origem	:= ''
	::NFEmissao := ctod ('')

	if _sOrigem == 'M'  // Variaveis M->
		::Filial  	:= xfilial ("ZC0")
		::Rede    	:= m->zc0_codred 		
		::LojaRed 	:= m->zc0_lojred	
		::Cliente	:= m->zc0_codcli 	
		::LojaCli	:= m->zc0_lojcli 	
		::TM      	:= m->zc0_tm 	
		::Data    	:= m->zc0_data 
		::Hora    	:= m->zc0_hora 
		::Usuario 	:= m->zc0_user 
		::Histor  	:= m->zc0_histor 
		::SeqZC0  	:= m->zc0_seq 
		::Documento := m->zc0_doc 
		::Serie 	:= m->zc0_serie 
		::Parcela	:= m->zc0_parcel 
		::Produto   := m->zc0_prod
		::Status    := m->zc0_status
		::Rapel		:= m->zc0_rapel 
		::Saldo		:= m->zc0_saldo 
		::Origem	:= m->zc0_origem 
		::NFEmissao := m->zc0_nfemis
	elseif _sOrigem == "ZC0"
	    ::Filial  	:= xfilial ("ZC0")
		::Rede    	:= zc0->zc0_codred 		
		::LojaRed 	:= zc0->zc0_lojred	
		::Cliente	:= zc0->zc0_codcli 	
		::LojaCli	:= zc0->zc0_lojcli 	
		::TM      	:= zc0->zc0_tm 	
		::Data    	:= zc0->zc0_data 
		::Hora    	:= zc0->zc0_hora 
		::Usuario 	:= zc0->zc0_user 
		::Histor  	:= zc0->zc0_histor 
		::SeqZC0  	:= zc0->zc0_seq 
		::Documento := zc0->zc0_doc 
		::Serie 	:= zc0->zc0_serie 
		::Parcela	:= zc0->zc0_parcel 
		::Produto   := zc0->zc0_prod
		::Status    := zc0->zc0_status
		::Rapel		:= zc0->zc0_rapel 
		::Saldo		:= zc0->zc0_saldo 
		::Origem	:= zc0->zc0_origem 
		::NFEmissao := zc0->zc0_nfemis
		::RegZC0    := zc0 -> (recno())
	endif

	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Grava novo registro
METHOD Grava(_lZC0Grav) Class ClsCtaRap
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()

	_lZC0Grav  := iif (_lZC0Grav  == NIL, .F., _lZC0Grav)  // Indica registro ja gravado na tabela
	
	if _lContinua
		if ! _lZC0Grav
			reclock("ZC0", .T.)
				zc0->zc0_filial := xfilial ("ZC0")
				zc0->zc0_codred := ::Rede 		
				zc0->zc0_lojred := ::LojaRed
				zc0->zc0_codcli := ::Cliente	
				zc0->zc0_lojcli := ::LojaCli	
				zc0->zc0_tm 	:= ::TM 
				zc0->zc0_data 	:= ::Data
				zc0->zc0_hora 	:= ::Hora 
				zc0->zc0_user 	:= cUserName
				zc0->zc0_histor := ::Histor 
				zc0->zc0_doc 	:= ::Documento
				zc0->zc0_serie 	:= ::Serie 
				zc0->zc0_parcel := ::Parcela
				zc0->zc0_prod   := ::Produto
				zc0->zc0_status := 'A'
				zc0->zc0_rapel 	:= ::Rapel
				zc0->zc0_saldo 	:= ::Saldo	
				zc0->zc0_origem := ::Origem
				zc0->zc0_nfemis := ::NFEmissao
			msunlock()
			
			_lZC0Grav = .T.
			::RegZC0 = zc0 -> (recno())
		endif

		// Gera sequencial para este novo registro.
		::GeraSeq()
		CursorArrow ()
	endif

	// Atualiza saldo 
	if _lContinua
		::AtuSaldo()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua
//
// --------------------------------------------------------------------------
// Gera sequencial para o registro atual
METHOD GeraSeq() Class ClsCtaRap
	local _nLock     := 0
	local _sQuery    := ""
	local _sSeqZC0   := ""
	local _lRet      := .F.
	local _nTentativ := 0

	if ! empty (zc0 -> zc0_seq)
		::UltMsg += "Chamada indevida do metodo " + procname () + ": registro do ZC0 ja tinha a sequencia '" + sz0 -> zc0_seq + "'. Solicite manutencao do programa."
		u_help (::UltMsg,, .t.)
	else
		do while _nTentativ <= 10
			_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("ZC0") + zc0 -> zc0_codred + zc0 -> zc0_lojred, .F.)
	
			// Se nao foi possivel bloquear o semaforo, deleta o registro do ZC0, cancelando sua inclusao.
			if _nLock == 0 
				reclock ("ZC0", .F.)
				ZC0 -> (dbdelete ())
				msunlock ()
			else
				_sQuery := ""
				_sQuery += " SELECT MAX (ZC0_SEQ)"
				_sQuery += " FROM " + RetSQLName ("ZC0")
				_sQuery += " WHERE ZC0_CODRED = '" + ZC0 -> zc0_codred   + "'"
				_sQUery += " AND ZC0_LOJRED = '" + ZC0 -> zc0_lojred + "'"
				_sSeqZC0:= U_RetSQL (_sQuery)
				if empty (_sSeqZC0)
					_sSeqZC0 = '000000'
				endif
				_sSeqZC0 = soma1(_sSeqZC0)
	
				// Grava a sequencia no ZC0 e libera o semaforo.
				reclock ("ZC0", .F.)
					zc0 -> zc0_seq := _sSeqZC0
				msunlock ()
				::SeqZC0 = zc0 -> zc0_seq
				U_Semaforo (_nLock)
				
				_lRet = .T.
				exit
			endif
		enddo
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Busca a rede do cliente
METHOD RetCodRede(_sCliente, _sLoja) Class ClsCtaRap
	_sRede := Posicione("SA1",1, xFilial("SA1") + _sCliente + _sLoja, "A1_VACBASE")
Return _sRede
//
// --------------------------------------------------------------------------
// Busca a nome da rede do cliente
METHOD RetNomeRede(_sCliente, _sLoja) Class ClsCtaRap
	_sRedeNome := Posicione("SA1",1, xFilial("SA1") + _sCliente + _sLoja, "A1_NOME")
Return _sRedeNome
//
// --------------------------------------------------------------------------
// Busca tipo da configuração do rapel
METHOD TipoRapel(_sRede, _sLoja) Class ClsCtaRap
	_sTpRapel := Posicione("SA1",1, xFilial("SA1") + _sRede + _sLoja, "A1_VABARAP")
Return _sTpRapel
//
// --------------------------------------------------------------------------
// Atualiza saldo da rede
METHOD AtuSaldo () Class ClsCtaRap
	local _lRet   := .T.
	local _x      := 0
	local _nSaldo := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	SUM(CASE "
	_oSQL:_sQuery += " 			WHEN ZX5_55DC = 'D' THEN ZC0_RAPEL * -1 "
	_oSQL:_sQuery += " 			ELSE ZC0_RAPEL "
	_oSQL:_sQuery += " 	    END) AS VLRRAPEL "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0_CODRED "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZC0_LOJRED "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5 "
	_oSQL:_sQuery += " 	ON ZX5.D_E_L_E_T_ = '' " 
	_oSQL:_sQuery += " 	    AND ZX5.ZX5_TABELA = '55' "
	_oSQL:_sQuery += " 		AND ZX5.ZX5_CHAVE = ZC0_TM "
	_oSQL:_sQuery += " WHERE ZC0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC0.ZC0_STATUS = 'A'"
	_oSQL:_sQuery += " AND ZC0.ZC0_CODRED = '" + ZC0 -> zc0_codred + "' " 
	_oSQL:_sQuery += " AND ZC0.ZC0_LOJRED = '" + ZC0 -> zc0_lojred + "' "
	_aSaldo := aclone (_oSQL:Qry2Array ())

	if Len(_aSaldo) > 0
		for _x := 1 to Len(_aSaldo)
			_nSaldo += _aSaldo[_x, 1]
		next
			
		// Grava o saldo no ZC0 
		reclock ("ZC0", .F.)
			zc0 -> zc0_saldo := _nSaldo
		msunlock ()
		::Saldo = zc0 -> zc0_saldo
	endif

return _lRet
//
// --------------------------------------------------------------------------
// Retorna saldo da rede
METHOD RetSaldo (_sRede, _sLojaRede) Class ClsCtaRap
	local _x      := 0
	local _nSaldo := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		ROUND(SUM(CASE "
	_oSQL:_sQuery += " 			WHEN ZX5_55DC = 'D' THEN ZC0_RAPEL * -1 "
	_oSQL:_sQuery += " 			ELSE ZC0_RAPEL "
	_oSQL:_sQuery += " 	    END),2) AS VLRRAPEL "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC0") + " ZC0 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD = ZC0_CODRED "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = ZC0_LOJRED "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("ZX5") + " ZX5 "
	_oSQL:_sQuery += " 	ON ZX5.D_E_L_E_T_ = '' " 
	_oSQL:_sQuery += " 	    AND ZX5.ZX5_TABELA = '55' "
	_oSQL:_sQuery += " 		AND ZX5.ZX5_CHAVE = ZC0_TM "
	_oSQL:_sQuery += " WHERE ZC0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC0.ZC0_STATUS = 'A'"
	_oSQL:_sQuery += " AND ZC0.ZC0_CODRED = '" + _sRede     + "' " 
	_oSQL:_sQuery += " AND ZC0.ZC0_LOJRED = '" + _sLojaRede + "' "
	_aSaldo := aclone (_oSQL:Qry2Array ())

	if Len(_aSaldo) > 0
		for _x := 1 to Len(_aSaldo)
			_nSaldo += _aSaldo[_x, 1]
		next
	endif
return _nSaldo
//
// --------------------------------------------------------------------------
// Retorna se movimento é debito ou credito
METHOD RetDebCre (_sTpMov) Class ClsCtaRap
	local _sDebCre := ''
	local _x       := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		ZX5_55DC "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZX5")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZX5_TABELA = '55' "
	_oSQL:_sQuery += " AND ZX5_CHAVE = '" + _sTpMov + "' "
	_aDebCre := aclone (_oSQL:Qry2Array ())

	if Len(_aDebCre) > 0
		for _x := 1 to Len(_aDebCre)
			_sDebCre := _aDebCre[_x, 1]
		next
	endif
	If empty(_sDebCre)
		u_help("Não encontrado tipo de movimento " + _sTpMov + " cadastrado.")
	EndIf
return _sDebCre
//
// --------------------------------------------------------------------------
// Realiza o fechamento de registros
METHOD FecharPeriodo (_dDtaIni, _sDataFin) Class ClsCtaRap
	local _lRet    := .T.
	local _x       := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT "
	_oSQL:_sQuery += " 		ZC0_CODRED "
	_oSQL:_sQuery += "     ,ZC0_LOJRED "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC0")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZC0_STATUS = 'A' "
	_oSQL:_sQuery += " AND ZC0_DATA BETWEEN '"+dtos(_dDtaIni)+"' AND '"+dtos(_sDataFin)+"' "
	_aPeriodo := aclone (_oSQL:Qry2Array ())

	if Len(_aPeriodo) > 0
		for _x := 1 to Len(_aPeriodo)
			// Busca saldo
			_oCtaRapel := ClsCtaRap():New ()
			_nSaldo    := _oCtaRapel:RetSaldo(_aPeriodo[_x,1], _aPeriodo[_x,2])

			_sData := dtos(date()) 
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE ZC0010 "
			_oSQL:_sQuery += " SET ZC0_STATUS = 'F', ZC0_DTAFIM = '" + _sData + "'"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
			_oSQL:_sQuery += " AND ZC0_STATUS = 'A' "
			_oSQL:_sQuery += " AND ZC0_CODRED = '"+ _aPeriodo[_x,1] +"' "
			_oSQL:_sQuery += " AND ZC0_LOJRED = '"+ _aPeriodo[_x,2] +"' "
			if _oSQL:Exec()

				// Cria registro de saldo			
				_oCtaRapel:Filial  	 = xfilial("ZC0")
				_oCtaRapel:Rede      = _aPeriodo[_x,1]	
				_oCtaRapel:LojaRed   = _aPeriodo[_x,2]
				_oCtaRapel:Cliente 	 = _aPeriodo[_x,1]	
				_oCtaRapel:LojaCli	 = _aPeriodo[_x,2]
				_oCtaRapel:TM      	 = '09' 	
				_oCtaRapel:Data    	 = date()
				_oCtaRapel:Hora    	 = time()
				_oCtaRapel:Usuario 	 = cusername 
				_oCtaRapel:Histor  	 = 'Geração de saldo por fechamento de registros' 
				_oCtaRapel:Documento = ''
				_oCtaRapel:Serie 	 = ''
				_oCtaRapel:Parcela	 = ''
				_oCtaRapel:Rapel	 = _nSaldo
				_oCtaRapel:Status	 = 'A' 
				_oCtaRapel:Origem	 = 'ZC0'

				if _oCtaRapel:Grava (.F.)
					_oEvento := ClsEvent():New ()
					_oEvento:Alias     = 'ZC0'
					_oEvento:Texto     = "Fechamento rapel rede "+ _aPeriodo[_x,1] + _aPeriodo[_x,2]
					_oEvento:CodEven   = 'ZC0001'
					_oEvento:Cliente   = _aPeriodo[_x,1]
					_oEvento:LojaCli   = _aPeriodo[_x,2]
					_oEvento:Grava()
				Else
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " UPDATE ZC0010 "
					_oSQL:_sQuery += " SET ZC0_STATUS = 'A', ZC0_DTAFIM = ''"
					_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
					_oSQL:_sQuery += " AND ZC0_STATUS = 'F' "
					_oSQL:_sQuery += " AND ZC0_DTAFIM = '"+ _sData          +"' "
					_oSQL:_sQuery += " AND ZC0_CODRED = '"+ _aPeriodo[_x,1] +"' "
					_oSQL:_sQuery += " AND ZC0_LOJRED = '"+ _aPeriodo[_x,2] +"' "
					_oSQL:Exec()
				endif
			endif		
		next
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Realiza a abertura do ultimo periodo fechado
METHOD AbrirPeriodo () Class ClsCtaRap
	local _lRet    := .T.
	local _x       := 0

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	MAX(ZC0_DTAFIM) "
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZC0")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_aPeriodo := aclone (_oSQL:Qry2Array ())

	if Len(_aPeriodo) > 0
		for _x := 1 to Len(_aPeriodo)
			_sData := _aPeriodo[_x, 1]

			// deleta registro de saldo gerado
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE ZC0010 "
			_oSQL:_sQuery += " 		SET D_E_L_E_T_ = '*'
			_oSQL:_sQuery += " WHERE ZC0_TM = '09' "
			_oSQL:_sQuery += " AND ZC0_DATA = '"+ _sData +"'"
			
			if _oSQL:Exec()
				// retorna status dos registros
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " UPDATE ZC0010 "
				_oSQL:_sQuery += " 		SET ZC0_STATUS = 'A', ZC0_DTAFIM = ''"
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND ZC0_STATUS = 'F' "
				_oSQL:_sQuery += " AND ZC0_DTAFIM = '"+ _sData +"' "
				_oSQL:Exec()

				_oEvento := ClsEvent():New ()
				_oEvento:Alias     = 'ZC0'
				_oEvento:Texto     = "Abertura rapel "+ _sData
				_oEvento:CodEven   = 'ZC0001'
				_oEvento:Grava()

				u_help("Período do dia " + dtoc(stod(_sData)) + " aberto com sucesso!")
			endif	
		next
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Exclui movimento.
METHOD Exclui(_nRecno, _sTM) Class ClsCtaRap
	local _lContinua := .T.
    local _sMsg      := ""

	if _lContinua
		ZC0 -> (dbgoto (_nRecno))
		if ZC0 -> (recno()) != _nRecno
			_sMsg := "Nao foi possivel localizar o registro correspondente no arquivo ZC0. Exclusao nao sera efetuada."
			u_help(_sMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if !(_sTM) $ '01/10'
			_sMsg := "Nao é possivel deletar registros não inseridos manualmente!"
			u_help(_sMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if ! ZC0 -> (deleted())
			reclock("ZC0", .F.)
				ZC0 -> (dbdelete())
			msunlock()
		endif
		_sMsg := "Registro deletado com sucesso!"
		u_help(_sMsg,, .t.)
	endif
return _lContinua
//
// --------------------------------------------------------------------------
// Verifica se o valor ficará negativo na conta
METHOD EhNegativo(_sRede, _sLojaRede, nVlr) Class ClsCtaRap
	local _lRet := .F.

	_oCtaRapel := ClsCtaRap():New ()
	_nSaldo    := _oCtaRapel:RetSaldo(_sRede, _sLojaRede)

	_nSaldoRest := _nSaldo - nVlr

	If _nSaldoRest < 0 .and. GetMV('VA_RAPNEG')
		u_help(" Com esse débito o saldo ficará negativo. Não será possível efetuar.")
		_lRet := .T.
	EndIf
return _lRet
//
// --------------------------------------------------------------------------
// Verifica se o usuario tem os devidos acessos.
// METHOD VerifUser (_sMsg) Class ClsCtaRap
// 	_lRet = U_ZZUVL ('051', __cUserID, .T., cEmpAnt, cFilAnt)
// 	if ! _lRet
// 		::UltMsg += _sMsg
// 		u_help (::UltMsg,, .t.)
// 	endif
// return _lRet
