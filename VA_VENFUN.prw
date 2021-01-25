// Programa..: VA_VENFUN
// Autor.....: Cláudia Lionço
// Data......: 25/01/2021
// Descricao.: Programa para executar o BatVenVer (verificações de vendas para funcionarios)
//             Todos os dias 25, independente do dia da semana
//
// #TipoDePrograma    #Processo
// #Descricao         #Programa para executar o BatVenVerno dia 25 do mes
// #PalavasChave      #venda_funcionario #venda #RH #compras_funcionarios
// #TabelasPrincipais #SL1 #SL4 #ZAD
// #Modulos 		  #LOJ #RH
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function VA_VENFUN()
    Local _nData := Day(Date())

    If _nData == 25
        U_BatVenFun()
    EndIf
Return
