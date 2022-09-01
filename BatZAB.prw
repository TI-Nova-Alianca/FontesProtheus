// Programa.:  BatZAB
// Autor....:  Robert Koch
// Data.....:  31/08/2022
// Descricao:  Verifica necessidade de enviar avisos represados para o NaWeb
//             Criado para ser executado via batch.
//
// #TipoDePrograma    #Batch
// #Descricao         #Verifica necessidade de enviar avisos para o NaWeb.
// #PalavasChave      #Avisos #integracao #NaWeb
// #TabelasPrincipais #ZAB
// #Modulos           #
//
// Historico de alteracoes:
//

// ------------------------------------------------------------------------------------------------------------------------
user function BatZAB ()
	local _oSQL    := NIL
	local _nLock   := 0
	local _aDados  := {}
	local _nDado   := 0
	local _nRegEnv := 0
	local _oAviso  := NIL

	_oBatch:Retorno = 'S'

	// Controla acesso via semaforo para evitar executar quando a execucao anterior ainda nao terminou.
	_nLock := U_Semaforo (procname (1) + procname ())
	if _nLock == 0
		_oBatch:Mensagens += "Bloqueio de semaforo."
	else

		// Avisos customizados ficam na tabela ZAB. Se possivel, jah faz o envio
		// para o NaWeb no mesmo momento, mas se der erro na integracao, este
		// batch tenta reeenviar depois.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT TOP 50 R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAB")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND ZAB_FILIAL  = '" + xfilial ("ZAB") + "'"
		_oSQL:_sQuery +=   " AND ZAB_ENVNAW != 'S'"
		_oSQL:_sQuery += " ORDER BY ZAB_DTEMIS, ZAB_HREMIS"
		_oSQL:Log ('[' + procname () + ']')
		_aDados := _oSQL:Qry2Array (.F., .F.)
		for _nDado = 1 to len (_aDados)
			U_Log2 ('debug', '[' + procname () + ']Vou instanciar recno ' + cvaltochar (_aDados [_nDado, 1]) + ' do ZAB')
			_oAviso := ClsAviso ():New (_aDados [_nDado, 1])
			/*
			if _oAviso:Tipo == 'E' .and. _oAviso:DiasDeVida == 0
				_oAviso:DiasDeVida = 90
			elseif _oAviso:Tipo == 'A' .and. _oAviso:DiasDeVida == 0
				_oAviso:DiasDeVida = 60
			elseif _oAviso:Tipo == 'I' .and. _oAviso:DiasDeVida == 0
				_oAviso:DiasDeVida = 30
			endif
			*/
			if ! _oAviso:EnviaNaWeb()
				exit  // durate testesn
			endif
		next
		_oBatch:Mensagens += cvaltochar (_nRegEnv) + " registros enviados"
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return
