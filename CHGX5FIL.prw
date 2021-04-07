// Programa...: CHGX5FIL
// Autor......: Robert Koch - TCX021
// Data.......: 19/10/2010

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada que retorna a filial a ser usada no SX5 para selecionar series de doc.fiscais.
// #PalavasChave      #serie_nf #serie_cupom
// #TabelasPrincipais #SX5
// #Modulos   		  #LOJA #FAT #COOP

// Descricao..: P.E. que retorna a filial a ser considerada para a tabela 01 do SX5
//              no momento de gerar notas fiscais. Foi criado por que a tabela 01
//              eh a unica tabela do SX5 com o campo X5_FILIAL preenchido, apesar
//              do arquivo ser compartilhado. Assim, eh possivel manter numeracao
//              separada para cada filial, utilizando a mesma serie.
//              Tambem foi implementado o programa SX5_01.PRW para fazer a edicao
//              de registros da tabela 01, pois pelo configurador a mesma aparece
//              vazia, uma vez que o configurador ignora este ponto de entrada.
//
// Historico de alteracoes:
// 05/04/2021 - Robert - Incluidas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
user function CHGX5FIL ()
return cFilAnt
