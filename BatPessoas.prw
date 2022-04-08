// Programa...: BatPessoas
// Autor......: Cláudia Lionço
// Data.......: 31/03/2022
// Descricao..: Batch que executa batchs diversos e realiza alterações/validações
//              em clientes/fornecedores/associados/funcionarios
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Batch que executa batchs diversos e realiza alterações/validações em clientes/fornecedores/associados/funcionarios
// #PalavasChave      #associados #clientes #fornecedores #funcionarios
// #TabelasPrincipais #
// #Modulos   		  # 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function BatPessoas()
    Local _lRet  := .F.
    Local _sMsg  := ""

    u_logIni()
	u_log("Iniciando BatPessoas em", date (), time ())

    // Grava Funcionarios e Associados como Clientes
    _lRet := U_BatFunAtlz()  
    If _lRet
        _sMsg := "BatFunAtlz executado com sucesso!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    else
        _sMsg := "ERRO: BatFunAtlz não executado!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT002")
    EndIf
    
    // Bat para troca de status associado/nao associado, conforme situação
    _lRet := U_BatFunAssoc() 
    If _lRet
        _sMsg := "BatFunAssoc executado com sucesso!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    else
        _sMsg := "ERRO: BatFunAssoc não executado!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT002")
    EndIf

    // Bat para troca de status funcionário/nao func. conforme situação
    _lRet := U_BatFunCli() 
    If _lRet
        _sMsg := "BatFunCli executado com sucesso!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    else
        _sMsg := "ERRO: BatFunCli não executado!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT002")
    EndIf

    // Bat para regra de tributação de associados
    _lRet := U_BatTrbAss() 
    If _lRet
        _sMsg := "BatTrbAss executado com sucesso!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    else
        _sMsg := "ERRO: BatTrbAss não executado!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT002")
    EndIf

    // Verificações de vendas para funcionários enviados para RH  
    _lExecuta := .F.
    _nDiaSem  := DOW(DATE()) // Retorna o número (entre 0 e 7) do dia da semana. Sendo, Domingo=1 e Sábado=7
    _nData    := Day(Date())
    _nUltDt   := Day(LastDate(Date()))

    If _nDiaSem == 2 // Se é segunda - envia e-mail
        _lExecuta := .T.
    EndIf

    If _nData == _nUltDt // Seé ultimo dia do mês
        _lExecuta := .T.
    EndIf

    If _lExecuta 
        _lRet := U_BatVenFun()   
       If _lRet
        _sMsg := "BatVenFun executado com sucesso!"
            u_log(_sMsg)
            _GravaLog(_sMsg, "BAT001")    
        else
            _sMsg := "ERRO: BatVenFun não executado!"
            u_log(_sMsg)
            _GravaLog(_sMsg, "BAT002")
        EndIf
    else
        _sMsg := "Não é dia de executar o batch BatVenFun !"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    EndIf
    
    // Bat para gravação de CPF de clientes em cupons do PDV
    _lRet := U_BatLojCGC() 
    If _lRet
        _sMsg := "BatLojCGC executado com sucesso!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT001")    
    else
        _sMsg := "ERRO: BatLojCGC não executado!"
        u_log(_sMsg)
        _GravaLog(_sMsg, "BAT002")
    EndIf
    
    u_logFim()
Return
//
// --------------------------------------------------------------------------
// Grava Log
Static Function _GravaLog(_sMsg, _sEvento)

    _oEvento := ClsEvent():New ()
    _oEvento:Alias   = 'BAT'
    _oEvento:Texto   = _sMsg
    _oEvento:CodEven = _sEvento
    _oEvento:Grava()

Return
