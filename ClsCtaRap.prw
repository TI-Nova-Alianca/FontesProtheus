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
	data DebCred
	data SeqZC0
	data Documento
	data Serie
	data Parcela
	data Rapel
	data Saldo
	data Status
	data Origem
	data RegZC0
	data UltMsg

	// Declaracao dos Metodos da classe
	METHOD New()
    METHOD GeraAtrib()
	METHOD Grava()
	METHOD Exclui()
	METHOD GeraSeq()
	METHOD VerifUser()
	METHOD AtuSaldo()
	METHOD GravaEvento()
ENDCLASS

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
	::DebCred  	:= ''
	::SeqZC0  	:= ''
	::Documento := ''
	::Serie 	:= ''
	::Parcela	:= ''
	::Rapel		:= 0
	::Saldo		:= 0
	::Status	:= ''
	::Origem	:= ''

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
		::Rapel		:= m->zc0_rapel 
		::Saldo		:= m->zc0_saldo 
		::Status	:= m->zc0_status 
		::Origem	:= m->zc0_origem 
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
		::Rapel		:= zc0->zc0_rapel 
		::Saldo		:= zc0->zc0_saldo 
		::Status	:= zc0->zc0_status 
		::Origem	:= zc0->zc0_origem 
		::RegZC0    := zc0 -> (recno())
	endif

	// Define se o tipo de movimento eh considerado a debito ou a credito.
	//::DebCred = ""
	//if ! empty (::TM)
	//	::DebCred = fBuscaCpo ("ZX5", 2, xfilial ("ZX5") + '10' + ::TM, "ZX5_10DC")
	//endif
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
			//_cFilial := ZC0 -> zi_filial
			//_dDtAtu := ZC0 -> zi_data
			//u_log2 ('info', '[' + GetClassName (::Self) + '.' + procname () + '] Gravando ZI_DOC = ' + ::Doc + '/' + ::Serie + '-' + ::Parcela + ' $ ' + transform (::Valor, "@E 999,999,999.99"))
			
			reclock ("ZC0", .T.)
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
			//zc0->zc0_seq 	:= ::SeqZC0 
			zc0->zc0_doc 	:= ::Documento
			zc0->zc0_serie 	:= ::Serie 
			zc0->zc0_parcel := ::Parcela
			zc0->zc0_rapel 	:= ::Rapel
			zc0->zc0_saldo 	:= ::Saldo	
			zc0->zc0_status := ::Status
			zc0->zc0_origem := ::Origem

			msunlock ()
			
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
				_sQuery += " 	FROM " + RetSQLName ("ZC0")
				_sQuery += " WHERE ZC0_FILIAL  = '" + xfilial ("ZC0")   + "'"
				_sQuery += " 	AND ZC0_CODRED = '" + ZC0 -> zc0_codred   + "'"
				_sQUery += " 	AND ZC0_LOJRED = '" + ZC0 -> zc0_lojred + "'"
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
// Atualiza saldo do movimento
METHOD AtuSaldo () Class ClsCtaRap
	local _lContinua := .T.

return _lContinua
//
// --------------------------------------------------------------------------
// Exclui movimento.
METHOD Exclui() Class ClsCtaRap
	local _lContinua := .T.

	::UltMsg = ""
	
	if _lContinua
		ZC0 -> (dbgoto (::RegZC0))
		if ZC0 -> (recno ()) != ::RegZC0
			::UltMsg += "Nao foi possivel localizar o registro correspondente no arquivo ZC0. Exclusao nao sera' efetuada."
			u_help (::UltMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if ! ZC0 -> (deleted ())
			reclock ("ZC0", .F.)
				ZC0 -> (dbdelete ())
			msunlock ()
		endif
	endif
return _lContinua
//
// --------------------------------------------------------------------------
// Verifica se o usuario tem os devidos acessos.
METHOD VerifUser (_sMsg) Class ClsCtaRap
	_lRet = U_ZZUVL ('051', __cUserID, .T., cEmpAnt, cFilAnt)
	if ! _lRet
		::UltMsg += _sMsg
		u_help (::UltMsg,, .t.)
	endif
return _lRet

