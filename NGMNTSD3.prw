
// Programa: NGMNTSD3
// Autor...: Cláudia Lionço
// Data....: 07/02/2022
// Funcao..: Ponto de Entrada acionado após gravação de movimento interno referente a insumo de OS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         # PE acionado após gravação de movimento interno referente a insumo de OS
// #PalavasChave      #OS #movimento_interno #manutenção 
// #TabelasPrincipais #SD3
// #Modulos   		  #MNT 
//
// Historico de alteracoes:
//  
//--------------------------------------------------------------------------------------------------
#include 'protheus.ch'

User Function NGMNTSD3()
 
    RecLock( "SD3", .F. )
        sd3 -> d3_usuario := CUSERNAME
    MsUnLock()
 
Return
