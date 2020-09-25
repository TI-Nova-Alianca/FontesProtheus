// Programa...: LeBalan3
// Autor......: Robert Koch
// Data.......: 03/02/2020
// Descricao..: Simula leitura de peso de balanca na portaria da matriz
//              Digo 'simula' por que o peso jah encontra-se no banco de dados, previamente
//              gravado por uma rotina em PowerShell que fica ativa em uma das estacoes da balanca.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function LeBalan3 ()
	local _nRet      := 0
	local _oSQL   := NIL
	local _nTenta := 0

//	u_logIni ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "select top 1 PESO,"
	_oSQL:_sQuery +=       " rtrim (FORMAT(DATAHORA , 'dd/MM/yyyy HH:mm:ss')),"
	_oSQL:_sQuery +=       " DATEDIFF (SECOND, DATAHORA, CURRENT_TIMESTAMP)"
	_oSQL:_sQuery +=  " from VA_PESOS_BALANCA_MATRIZ"
	_oSQL:_sQuery += " order by DATAHORA desc"

	// Faz algumas tentativas para dar tempo da outra estacao gravar o peso.
	procregua (5)
	do while _nTenta++ <= 5
	//	u_log ('tentativa', _nTenta)
		incproc ("Leitura de peso - tentativa " + cValToChar (_nTenta))
		_aRetQry := aclone (_oSQL:Qry2Array (.f., .f.))
	//	u_log (_aRetQry)
		if len (_aRetQry) > 0
			if _aRetQry [1, 3] <= 10  // Idade maxima (em segundos) que vou aceitar como valida.
				if _aRetQry [1, 1] > 0
					_nRet = _aRetQry [1, 1]
					exit
				endif
			endif
		endif
		sleep (1000)
	enddo
	if _nRet == 0 
		u_help ("Verifique se o programa de leitura de peso encontra-se ativo na estacao da portaria, e se a balanca encontra-se estabilizada. Ultima leitura valida foi em " + alltrim (_aRetQry [1, 2]),, .T.)
	endif

//	u_logFim ()
return _nRet
