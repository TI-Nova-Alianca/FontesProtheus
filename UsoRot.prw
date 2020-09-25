// Programa: UsoRot
// Autor...: Robert Koch
// Data....: 24/05/2016
// Funcao..: Alimenta tabela de estatisticas de uso de rotinas.
//
// Historico de alteracoes:
// 23/06/2016 - Robert - Alterado para ser chamado via pontos de entrada genericos, com parametros de Inicio/Fim.
// 15/07/2016 - Robert - Nao usa mais o 'monitor' para setar o tempo de uso das threads abertas (suspeita de estar misturando as threads).
//                     - Melhorada filtragem para gravacao do nome da rotina e hora de saida (suspeita de estar misturando as threads).
//                     - Gera log diario.
// 04/07/2019 - Robert - Na atualizacao da hora de saida, filtra somente entradas das ultimas 24 horas (estava encontrando mesma thread em anos anteriores).
// 24/10/2019 - Robert - Valida uso da porta de conexao do servico das lojas por outros modulos.
// 10/02/2020 - Robert - Desabilitado indice ENTRADA_THREAD (nao ajudava no update)
//                     - Indice ENTRADA passa a ser criado como 'clustered' uma vez que este campo nao eh alterado no update da saida de tela.
// 16/03/2020 - Robert - Gravacao campos ESTACAO e IP.
// 15/06/2020 - Robert - Gravacao do __cUserID no campo USUARIO e criado campo NOME para o cUserName.
// 07/08/2020 - Robert - Ajuste teste porta SigaLoja.
//

// --------------------------------------------------------------------------
user function UsoRot (_sIniFim, _sRotina, _sOrigem)
	local _oSQL     := ClsSQL ():New ()
//	local _nMon     := 0
//	local _aThreads := {}
//	local _nThread  := 0

	// Criamos um servico em separado exclusivamente para as lojas usarem com os cupons, mas o pessoal comecou a
	// usar para tudo, entao estou tentando evitar pelo menos que usem outros modulos. Robert, 24/10/2019.
	if _sIniFim == 'I' .and. GetServerPort () == 1247  // Estou conectado no servico das lojas
		if upper (alltrim (procname (2))) != "U_SIGALOJ"
			
			// Finaliza a rotina.
			Final (procname () + ": Porta de conexao indevida.", "A porta de conexao que voce selecionou (" + cvaltochar (GetServerPort ()) + ") destina-se exclusivamente a operacao do modulo SigaLoja.")
		endif
	endif

	// Alguns tratamentos para o campo 'origem'.
	if empty (_sOrigem)
		_sOrigem = _Pcham ()
	endif
	_sOrigem = left (_sOrigem, 20) //200)
	_sOrigem = strtran (_sOrigem, "'", "")
	_sOrigem = strtran (_sOrigem, '"', '')
	_sOrigem = strtran (_sOrigem, ",", "")
	_sRotina = iif (_sRotina == NIL, '', _sRotina)

	if _sIniFim == 'I'
		// Cria tabela, caso nao exista.
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "IF OBJECT_ID('VA_USOROT', 'U') IS NULL"
		_oSQL:_sQuery += " BEGIN"
		_oSQL:_sQuery += " CREATE TABLE VA_USOROT("
		_oSQL:_sQuery += " SERVICO  INT          NOT NULL,"
		_oSQL:_sQuery += " THREAD   INT          NOT NULL,"
		_oSQL:_sQuery += " ENTRADA  datetime     NOT NULL,"
		_oSQL:_sQuery += " SAIDA    datetime,"
		_oSQL:_sQuery += " ROTINA   varchar(20),"
		_oSQL:_sQuery += " USUARIO  varchar(6)   NOT NULL,"
		_oSQL:_sQuery += " NOME     varchar(20)  NOT NULL,"
		_oSQL:_sQuery += " AMBIENTE varchar(15)  NOT NULL,"
		_oSQL:_sQuery += " ORIGEM   varchar(200) NOT NULL,"
		_oSQL:_sQuery += " FILIAL   varchar(2)   NOT NULL,"
		_oSQL:_sQuery += " ESTACAO  varchar(20),"
		_oSQL:_sQuery += " IP       varchar(15)"
		_oSQL:_sQuery += " );"
		
		// Cria o indice como 'clustered' para permitir que seja reorganizado pelo job de reorganizacao do SQL.
		_oSQL:_sQuery += " CREATE clustered INDEX ENTRADA ON VA_USOROT (ENTRADA);"
		_oSQL:_sQuery += " END"
		//_oSQL:Log ()
		_oSQL:Exec ()
	
		_oSQL:_sQuery := "INSERT INTO VA_USOROT (SERVICO, THREAD, ENTRADA, USUARIO, NOME, AMBIENTE, ORIGEM, ROTINA, FILIAL, ESTACAO, IP)"
		_oSQL:_sQuery += " VALUES ("
		_oSQL:_sQuery +=           cValToChar (GetServerPort ()) + ", "
		_oSQL:_sQuery +=           cValToChar (ThreadID ()) + ","
//		_oSQL:_sQuery +=           " GETDATE (), "
		_oSQL:_sQuery +=           " CURRENT_TIMESTAMP, "
		_oSQL:_sQuery +=           "'" + __cUserId + "',"
		_oSQL:_sQuery +=           "'" + alltrim (LEFT (upper (cUserName), 20)) + "',"
		_oSQL:_sQuery +=           "'" + alltrim (LEFT (upper (GetEnvServer ()), 15)) + "',"
		_oSQL:_sQuery +=           "'" + _sOrigem + "',"
		_oSQL:_sQuery +=           "'" + _sRotina + "',"
		_oSQL:_sQuery +=           "'" + cFilAnt + "',"
		_oSQL:_sQuery +=           "'" + left (GetComputerName (), 20) + "',"
		_oSQL:_sQuery +=           "'" + GetClientIP () + "')"
//		_oSQL:Log ()
		_oSQL:Exec ()

	elseif _sIniFim == 'F'
//		_oSQL:_sQuery := "UPDATE VA_USOROT SET SAIDA = GETDATE(), ROTINA = '" + _sRotina + "'"
		_oSQL:_sQuery := "UPDATE VA_USOROT SET SAIDA = CURRENT_TIMESTAMP, ROTINA = '" + _sRotina + "'"
		_oSQL:_sQuery += " WHERE SERVICO  = " + cvaltochar (GetServerPort ())
		_oSQL:_sQuery +=   " AND THREAD   = " + cvaltochar (ThreadID ())
	//	_oSQL:_sQuery +=   " AND USUARIO  = '" + alltrim (LEFT (upper (cUserName), 20)) + "'"
		_oSQL:_sQuery +=   " AND USUARIO  = '" + __cUserId + "'"
		_oSQL:_sQuery +=   " AND AMBIENTE = '" + alltrim (LEFT (upper (GetEnvServer ()), 15)) + "'"
		_oSQL:_sQuery +=   " AND SAIDA IS NULL"
		_oSQL:_sQuery +=   " AND ENTRADA >= DATEADD (DAY, -1, GETDATE ())"
		//_oSQL:Log ()
		_oSQL:Exec ()

		_oSQL:_sQuery := "SELECT * FROM VA_USOROT WHERE SERVICO = " + cvaltochar (GetServerPort ()) + " AND THREAD  = " + cvaltochar (ThreadID ())
//		u_log (_oSQL:Qry2Array ())
	endif
//	u_logFim (_sIniFim)
	//_sArqLog = _sArqLog2
return



// --------------------------------------------------------------------------
static Function _PCham ()
	local _i      := 2
	local _sPilha := ""
	do while procname (_i) != ""
		_sPilha += alltrim (procname (_i)) + '==>'
		_i++
	enddo
return _sPilha
