// Programa..: BatUltVF
// Autor.....: Cláudia Lionço
// Data......: 25/01/2021
// Descricao.: Programa para executar o BatVenVer (verificações de vendas para funcionarios)
//             Ultimo dia do mês, independente do dia da semana
//
// #TipoDePrograma    #Processo
// #Descricao         #Programa para executar o BatVenVerno dia 25 do mes
// #PalavasChave      #venda_funcionario #venda #RH #compras_funcionarios
// #TabelasPrincipais #SL1 #SL4 #ZAD
// #Modulos 		  #LOJ #RH
//
// Historico de alteracoes:
// 15/02/2021 - Alterada datas para primeira e ultima do mes. GLPI: 9410
//
// --------------------------------------------------------------------------
User Function BatUltVF()
    Local _nData  := Day(Date())
    Local _nUltDt := Day(LastDate(Date()))

    //u_help(str(_nData) + " - "+ str(_nUltDt))
    If _nData == _nUltDt
        U_BatVenFun()
    EndIf
Return
