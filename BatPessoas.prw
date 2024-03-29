// Programa...: BatPessoas
// Autor......: Cl�udia Lion�o
// Data.......: 31/03/2022
// Descricao..: Batch que executa batchs diversos e realiza altera��es/valida��es
//              em clientes/fornecedores/associados/funcionarios
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Batch que executa batchs diversos e realiza altera��es/valida��es em clientes/fornecedores/associados/funcionarios
// #PalavasChave      #associados #clientes #fornecedores #funcionarios
// #TabelasPrincipais #
// #Modulos   		  # 
//
// Historico de alteracoes:
// 04/08/2022 - Robert - Passa a gravar eventos com data de validade (expiracao).
// 04/03/2024 - Robert - Incluidas chamadas da funcao U_PerfMon() para acompanhar demora na execucao (GLPI 15031)
//

// --------------------------------------------------------------------------
//#Include "Protheus.ch"
//#include 'parmtype.ch'
//#Include "totvs.ch"

User Function BatPessoas()
	Local _lRet  := .F.
	Local _sMsg  := ""

	U_Log2 ('info', 'Iniciando ' + procname ())

	// Grava Funcionarios e Associados como Clientes
	u_perfmon ('I', 'U_BatFunAtlz')
	_lRet := U_BatFunAtlz()
	If _lRet
		_sMsg := "BatFunAtlz executado com sucesso!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	else
		_sMsg := "ERRO: BatFunAtlz n�o executado!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT002")
	EndIf
	u_perfmon ('L', 'U_BatFunAtlz')
	
	// Bat para troca de status associado/nao associado, conforme situa��o
	u_perfmon ('I', 'U_BatFunAssoc')
	_lRet := U_BatFunAssoc() 
	If _lRet
		_sMsg := "BatFunAssoc executado com sucesso!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	else
		_sMsg := "ERRO: BatFunAssoc n�o executado!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT002")
	EndIf
	u_perfmon ('L', 'U_BatFunAssoc')

	// Bat para troca de status funcion�rio/nao func. conforme situa��o
	u_perfmon ('I', 'U_BatFunCli')
	_lRet := U_BatFunCli() 
	If _lRet
		_sMsg := "BatFunCli executado com sucesso!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	else
		_sMsg := "ERRO: BatFunCli n�o executado!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT002")
	EndIf
	u_perfmon ('L', 'U_BatFunCli')

	// Bat para regra de tributa��o de associados
	u_perfmon ('I', 'U_BatTrbAss')
	_lRet := U_BatTrbAss() 
	If _lRet
		_sMsg := "BatTrbAss executado com sucesso!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	else
		_sMsg := "ERRO: BatTrbAss n�o executado!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT002")
	EndIf
	u_perfmon ('L', 'U_BatTrbAss')

	// Verifica��es de vendas para funcion�rios enviados para RH
	u_perfmon ('I', 'U_BatVenFun')
	_lExecuta := .F.
	_nDiaSem  := DOW(DATE()) // Retorna o n�mero (entre 0 e 7) do dia da semana. Sendo, Domingo=1 e S�bado=7
	_nData    := Day(Date())
	_nUltDt   := Day(LastDate(Date()))

	If _nDiaSem == 2 // Se � segunda - envia e-mail
		_lExecuta := .T.
	EndIf

	If _nData == _nUltDt // Se� ultimo dia do m�s
		_lExecuta := .T.
	EndIf

	If _lExecuta 
		_lRet := U_BatVenFun()
	If _lRet
		_sMsg := "BatVenFun executado com sucesso!"
			u_log(_sMsg)
			_GravaLog(_sMsg, "BAT001")
		else
			_sMsg := "ERRO: BatVenFun n�o executado!"
			u_log(_sMsg)
			_GravaLog(_sMsg, "BAT002")
		EndIf
	else
		_sMsg := "N�o � dia de executar o batch BatVenFun !"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	EndIf
	u_perfmon ('L', 'U_BatVenFun')
	
	// Bat para grava��o de CPF de clientes em cupons do PDV
	u_perfmon ('I', 'U_BatLojCGC')
	_lRet := U_BatLojCGC() 
	If _lRet
		_sMsg := "BatLojCGC executado com sucesso!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT001")
	else
		_sMsg := "ERRO: BatLojCGC n�o executado!"
		u_log(_sMsg)
		_GravaLog(_sMsg, "BAT002")
	EndIf
	u_perfmon ('L', 'U_BatLojCGC')
	
	U_Log2 ('info', 'Finalizando ' + procname ())
Return
//
// --------------------------------------------------------------------------
// Grava Log
Static Function _GravaLog(_sMsg, _sEvento)
	_oEvento := ClsEvent():New ()
	_oEvento:Alias     = 'BAT'
	_oEvento:Texto     = _sMsg
	_oEvento:CodEven   = _sEvento
	_oEvento:DiasValid = 30
	_oEvento:Grava()
Return
