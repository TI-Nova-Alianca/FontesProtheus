// Programa:  TesteVel
// Autor:     Robert Koch
// Data:      09/12/2019
// Descricao: Executa algumas operacoes para avaliar o tempo de execucao (espero gerar algumas estatisticas)

#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function TesteVel ()
//	local _oSQL      := NIL
	local _oAviso    := NIL
/*	local _nSegIni   := seconds ()
	local _aAutoSF1  := {}
	local _aAutoSD1  := {}
	local _aLinhas   := {}
	local _aRmtInfo  := {}
	local _sArqRet   := ''
	local _nHdl      := 0
	local _nTmpCopia := 0
	local _nTmpAviso := 0
	local _nLock     := 0
	private _sArqLog := procname () + '_' + computername () + '_' + dtos (date ()) + '.log'

	u_logDH ()
*/
	prepare environment empresa '01' filial '01' modulo '05'
	private cModulo   := 'FAT'
	private __cUserId := "000000"
	private cUserName := "Administrador"
	private __RelDir  := "c:\temp\spool_protheus\"
	set century on
	PtInternal (1, procname ())
/*
	U_UsoRot ('I', 'TESTEUPLOAD', ComputerName ())
	CpyT2S (AllTrim (GetTempPath ()) + '\TesteVel.txt', '\', .F. )
	U_UsoRot ('F', 'TESTEUPLOAD', ComputerName ())
	sleep (1000)  // Aguarda um tempo(em milissegundos) 

	U_UsoRot ('I', 'TESTEDOWNLOAD', ComputerName ())
	CpyS2T ('TesteVel.txt', AllTrim (GetTempPath ()), .F. )
	U_UsoRot ('F', 'TESTEDOWNLOAD', ComputerName ())
	sleep (1000)  // Aguarda um tempo(em milissegundos) 
*/
	U_UsoRot ('I', 'TESTEGRVAVISO', ComputerName ())

	// Gera um semaforo para dar algum processamento a mais
	_nLock = U_Semaforo (procname ())
	
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'A'
	_oAviso:Destinatar = 'grpTI'
	_oAviso:Texto      = 'Monitoramento disponibilidade servico porta ' + cValToChar (GetServerPort ())
	_oAviso:Origem     = procname ()
	_oAviso:DiasDeVida = 3
	_oAviso:CodAviso   = '009'
	_oAviso:Grava ()
	
	U_Semaforo (_nLock)

	U_UsoRot ('F', 'TESTEGRVAVISO', ComputerName ())

/*
	U_UsoRot ('I', procname (), ComputerName ())
	
	
	_nTmpCopia = seconds ()
	CpyS2T ('sigaadv.hls', AllTrim (GetTempPath ()), .F. )
	_nTmpCopia = seconds () - _nTmpCopia
	u_log ('copia server para remote:', _nTmpCopia)

//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := "SELECT COUNT (*) FROM SZ1010"
//	_nNada := _oSQL:RetQry ()
//	u_log (_oSQL:_sQuery + ':', seconds () - _nSegIni)

//	_aUsers := aclone (FwSfAllUsers ())
//	u_log ('Leitura usuarios:', seconds () - _nSegIni)

	_nTmpAviso = seconds ()
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'A'
	_oAviso:Destinatar = 'grpTI'
	_oAviso:Texto      = 'Monitoramento ' + ComputerName () + ': Tempo copia arq.p/remote: ' + cvaltochar (_nTmpCopia)
	_oAviso:Origem     = procname ()
	_oAviso:DiasDeVida = 1
	_oAviso:CodAviso   = '009'
	_oAviso:Grava ()
	_nTmpAviso = seconds () - _nTmpAviso
	u_log ('Gravacao aviso:', _nTmpAviso)

	_aRmtInfo := GetRmtInfo()
	u_log (_aRmtInfo)
	_sArqRet = procname () + '.txt' //criatrab (NIL, .F.) + '.txt'
	_nHdl = fcreate(_sArqRet, 0)
	fwrite (_nHdl, cvaltochar (_nTmpCopia) + '    Tempo para copiar arquivo para o remote' + chr (13) + chr (10))
	fwrite (_nHdl, cvaltochar (_nTmpAviso) + '    Tempo para gravar aviso' + chr (13) + chr (10))
	fwrite (_nHdl, 'Este arquivo serve apenas para retorno da funcao de verificacao de disponibilidade do protheus ' + procname ())
	fclose (_nHdl)
	u_log ('arq ret:', _sArqRet)
	CpyS2T (_sArqRet, _aRmtInfo [13], .F. )
	*/
//	U_UsoRot ('F', procname (), ComputerName ())
return
