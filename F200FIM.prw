// Programa...: F200VAR
// Autor......: Cláudia Lionço
// Data.......: 03/2007
// Cliente....: Alianca
// Descricao..: P.E. Gravação de linha de lançamento
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Gravação de linha de lançamento
// #PalavasChave      #CNAB #final_CNAB 
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------------------

User Function F200FIM()
    If upper (GetEnvServer ()) $ "TESTE/TESTECLAUDIA" 
        u_ZB5TRANSF(cFilAnt)
    EndIf
Return
