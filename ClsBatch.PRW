// Programa:  ClsBatch
// Autor:     Robert Koch
// Data:      26/02/2009
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Classe
// #Descricao         #Representacao de uma tarefa para execucao agendada (batch), com atributos e metodos pertinentes.
// #PalavasChave      #batch #job #tarefa
// #TabelasPrincipais #ZZ6
// #Modulos           #

// Historico de alteracoes:
// 11/05/2009 - Robert - Implementacao do codigo de batch '03'.
// 23/07/2009 - Robert - Campos novos na tabela ZZ6.
// 10/02/2010 - Robert - Compatibilizacao com ambiente DBF.
// 20/10/2010 - Robert - Passa a usar a funcao GetSXeNum para gerar o campo ZZ6_SEQ.
// 24/10/2010 - Robert - Implementacao do metodo Executa, atraves de chamada RPC.
// 18/11/2010 - Robert - Metodo 'Executa' nao roda se constar 'TESTE' no ambiente.
// 01/11/2010 - Robert - Criados campos DataBase, AnoMes e Modulo no ZZ6.
// 24/01/2011 - Robert - Inexistencia da variavel '_sArqLog' nao prevista no metodo 'Executa'.
// 24/08/2014 - Robert - Inicializa empresa e filial de destino com empresa e filial correntes.
// 15/04/2015 - Robert - Passa a receber recno. do ZZ6 no construtor da classe e inicializar objeto, quando for o caso.
// 11/05/2015 - Robert - Criados atributos HrIni, HrFim, Period, DiaSem, ACada, ACadaU.
// 14/05/2015 - Robert - Criado atributo TmpLim
//                     - Rotina de copia nao levava o tempo limite do batch de origem.
// 11/07/2017 - Robert - Separados metodos ExecRmt e Executa.
// 17/05/2019 - Robert - Desabilitado metodo ExecRmt.
//                     - Criado atributo AmbTeste
// 30/05/2019 - Robert - Nao inicializava corretamente o atributo AmbTeste.
// 07/06/2019 - Robert - Criado atributo ArqLog.
// 04/11/2019 - Robert - Criado atributo Ativo.
// 01/09/2020 - Robert - Inseridas tags para catalogo de fontes
//                     - Revisao logs, remocao chamadas funcao de geracao de mensagens na console.
// 29/03/2021 - Robert - Tratamento para campo ZZ6_JSON (GLPI 9592).
// 06/03/2023 - Robert - Criado atributo Prioridade (antes gravava sempre 5)
// 13/03/2023 - Robert - Conversao parametro ::Prioridade para caracter.
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsBatch ()
return


// ==========================================================================
// Classe usada para criar, gravar e executar processos em batch ou agendados.
CLASS ClsBatch

	// Declaracao das propriedades da Classe
	data ACada
	data ACadaU
	data AguardaWF
	data AnoMes
	data Ativo
	data CodPro
	data Comando
	data DataBase
	data DtIni
	data DiaSem
	data Dados
	data EmpDes
	data FilDes
	data HrIni
	data HrFim
	data JSON
	data Modulo
	data TmpRetent
	data MaxTent
	data Period
	data Retorno
	data Seq
	data Mensagens
	data TempoLim
	data AmbTeste
	data ArqLog
	data Prioridade

	// Declaração dos Métodos da Classe
	METHOD New ()
	METHOD Grava ()
	METHOD ExecRmt ()
	METHOD Executa ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New (_nRegZZ6) Class ClsBatch
	local _aAreaZZ6 := 0

	::Seq        := ""
	::CodPro     := ""
	::Dados      := ""
	::EmpDes     := cEmpAnt  //""
	::FilDes     := cFilAnt  //""
	::JSON       := ""
	::Comando    := ""
	::DataBase   := ctod ('')
	::AnoMes     := ""
	::Modulo     := 0
	::TmpRetent  := 0
	::MaxTent    := 0
	::AguardaWF  := ''
	::Retorno    := ''  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
	::Mensagens  := ''
	::HrIni      := time ()
	::HrFim      := '24:00'
	::DtIni      := date ()
	::DiaSem     := '1234567'
	::Period     := 'U'
	::ACada      := 0
	::ACadaU     := ''
	::TempoLim   := 0
	::AmbTeste   := 'N'  // Habilitado a executar em ambiente de testes [S/N]
	::ArqLog     := ''
	::Ativo      := 'S'  // Ativo por default
	::Prioridade := 5  // Prioridade: 0=mais prioritaroi;9=menos prioritario. Default = prioridade media
	
	// Se recebeu o numero do registro no ZZ6, preenche o objeto com dados do arquivo.
	if valtype (_nRegZZ6) == 'N'
		_aAreaZZ6 := zz6 -> (getarea ())
		zz6 -> (dbgoto (_nRegZZ6))
		::Seq        := zz6 -> zz6_seq
		::CodPro     := zz6 -> zz6_codpro
		::Dados      := zz6 -> zz6_dados
		::EmpDes     := zz6 -> zz6_empdes
		::FilDes     := zz6 -> zz6_fildes
		::JSON       := zz6 -> zz6_json
		::Comando    := alltrim (zz6 -> zz6_cmd)
		::DataBase   := zz6 -> zz6_dtbase
		::AnoMes     := zz6 -> zz6_anomes
		::Modulo     := zz6 -> zz6_modulo
		::TmpRetent  := zz6 -> zz6_minret
		::MaxTent    := zz6 -> zz6_maxten
		::AguardaWF  := zz6 -> zz6_agwf
		::DtIni      := zz6 -> zz6_DtIni
		::HrIni      := zz6 -> zz6_HrIni
		::HrFim      := zz6 -> zz6_HrFim
		::Period     := zz6 -> zz6_Period
		::DiaSem     := zz6 -> zz6_DiaSem
		::ACada      := zz6 -> zz6_ACada
		::ACadaU     := zz6 -> zz6_ACadaU
		::TempoLim   := zz6 -> zz6_TmpLim
		::AmbTeste   := zz6 -> zz6_AmbTst
		::ArqLog     := zz6 -> zz6_ArqLog
		::Ativo      := zz6 -> zz6_Ativo
		::Prioridade := zz6 -> zz6_Prior
		zz6 -> (restarea (_aAreaZZ6))
	endif
Return Self


// --------------------------------------------------------------------------
// Serializacao e gravacao em arquivo
METHOD Grava () Class ClsBatch
	local _aAreaAnt  := U_ML_SRArea ()
	local _sSeq      := ""
	local _lContinua := .T.
	local _oJSBatch  := NIL
	local _sJSErro   := ''

	// Se recebi dados em formato JSON, vou valida-los antes de gravar.
	if _lContinua .and. ! empty (::JSON)
		::JSON = alltrim (::JSON)
		if len (::JSON) > TamSX3 ("ZZ6_JSON")[1]
			u_help ('Erro na validacao de dados JSON para agendamento de batch: o campo ZZ6_JSON nao comporta todo o JSON recebido: ' + ::JSON,, .t.)
			_lContinua = .F.
		endif
		if _lContinua
			_oJSBatch := JsonObject():new()
			_sJSErro := _oJSBatch:FromJson (::JSON)
			if ValType(_sJSErro) == "C"
				u_help ('Erro na validacao de dados JSON para agendamento de batch: ' + _sJSErro,, .t.)
				_lContinua = .F.
//			else
//				U_Log2 ('debug', 'Dados JSON para agendamento de batch:')
//				U_Log2 ('debug', _oJSBatch)
			endif
		endif
	endif

	if _lContinua
		::MaxTent = max (5, ::MaxTent) 
		_sSeq = GetSXeNum ("ZZ6", "ZZ6_SEQ")

		reclock ("ZZ6", .T.)
		zz6 -> zz6_filial  = xfilial ("ZZ6")
		zz6 -> zz6_seq     = _sSeq
		zz6 -> zz6_EmpInc  = cEmpAnt
		zz6 -> zz6_FilInc  = cFilAnt
		zz6 -> zz6_DtInc   = date ()
		zz6 -> zz6_HrInc   = time ()
		zz6 -> zz6_CodPro  = ::CodPro
		zz6 -> zz6_Dados   = ::Dados
		zz6 -> zz6_EmpDes  = ::EmpDes
		zz6 -> zz6_FilDes  = ::FilDes
		zz6 -> zz6_JSON    = ::JSON
		zz6 -> zz6_MaxTen  = ::MaxTent
		zz6 -> zz6_Ativo   = ::Ativo
		zz6 -> zz6_DtIni   = ::DtIni
		zz6 -> zz6_HrIni   = ::HrIni
		zz6 -> zz6_HrFim   = ::HrFim
		zz6 -> zz6_Period  = ::Period
		zz6 -> zz6_DiaSem  = ::DiaSem
		zz6 -> zz6_ACada   = ::ACada
		zz6 -> zz6_ACadaU  = ::ACadaU
		zz6 -> zz6_Cmd     = ::Comando
		zz6 -> zz6_DtBase  = ::DataBase
		zz6 -> zz6_AnoMes  = ::AnoMes
		zz6 -> zz6_Modulo  = ::Modulo
		zz6 -> zz6_Prior   = cvaltochar (::Prioridade)  // '5'
		zz6 -> zz6_minret  = ::TmpRetent
		zz6 -> zz6_agwf    = ::AguardaWF
		zz6 -> zz6_TmpLim  = ::TempoLim
		zz6 -> zz6_AmbTst  = ::AmbTeste
		zz6 -> zz6_ArqLog  = ::ArqLog
		msunlock ()
		
		do while __lSX8
			ConfirmSX8 ()
		enddo

		// Grava no objeto o numero sequencial gerado no arquivo (talvez seja necessario mais tarde).
		::Seq = zz6 -> zz6_seq
		
		u_log2 ('info', "Batch seq. " + _sSeq + " agendado em " + dtoc (date()) + " " + time())
	endif
	
	U_ML_SRArea (_aAreaAnt)
return _lContinua



// --------------------------------------------------------------------------
// Tenta executar o processo.
METHOD Executa (_sMsgLog) Class ClsBatch
	local _lContinua := .T.
//	local _nSegIni   := seconds ()

	//u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua .and. zz6 -> zz6_seq != ::Seq
		zz6 -> (dbsetorder (1))  // ZZ6_FILIAL+ZZ6_SEQ
		if ! zz6 -> (dbseek (xfilial ("ZZ6") + ::Seq, .F.))
			::Mensagens += "Processo '" + ::Seq + "' nao encontrado na tabela ZZ6"
			_lContinua = .F.
		endif
	endif

	if _lContinua
		processa ({|| U_VA_ZZ6Ex (_sMsgLog)})
 	endif

// 	if ! empty (::Mensagens)
 //		u_log2 ('info', ::Mensagens)
 //	endif

	//u_log ('Executou em', seconds () - _nSegIni, 'segundos')
	//u_logFim (GetClassName (::Self) + '.' + procname ())
return
