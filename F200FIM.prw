// Programa...: F200VAR
// Autor......: Cl�udia Lion�o
// Data.......: 03/2007
// Cliente....: Alianca
// Descricao..: P.E. Grava��o de linha de lan�amento
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Grava��o de linha de lan�amento
// #PalavasChave      #CNAB #final_CNAB 
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------------------

User Function F200FIM()
    If cFilAnt $ GetMv("VA_FILTNSF")
        u_ZB5TRANSF(cFilAnt)
    EndIf
Return
