// Programa: MT110CPO
// Autor:    Andre Alves
// Data:     05/07/2019
// Funcao:   No inicio da rotina A110Aprov antes da execução da dialog de aprovação da SC,
//			 utilizado para manipular o Array com os campos da tabela SC1, indicado para
//			 adicionar mais campos para a apresentação.
//
// Historico de alteracoes:
//
// 07/01/2009 - Robert - Solicitacoes jah encaminhadas devem ter valor informado.
//
// ----------------------------------------------------------------------------------------------------------------------------------------------------
User Function MT110CPO()

Local aNewCpos :=  PARAMIXB[1]  //Array contendo os campos da tabela SC1 (Default)

aAdd (aNewCpos,{'C1_CONTA'})  //-- Adiciona os campos do usuario

Return (aNewCpos) 
