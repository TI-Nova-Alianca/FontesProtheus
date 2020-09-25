// Programa:  ClsFrtFr
// Autor:     Robert Koch
// Data:      09/05/2008
// Cliente:   Alianca
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 12/04/2013 - Leandro - Preparacao para gravacao da tabela ZZN
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsFrtFr ()
return


// ==========================================================================
// Classe usada para armazenamento de dados de fretes durante o pedido de venda.
CLASS ClsFrtFr

	// Declaracao das propriedades da Classe
	data _sFornece
	data _sLoja
	data _aNaoPrev
	data _aRegsZZ1
	data _bValor

	// Declaração dos Métodos da Classe
	METHOD New ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New () Class ClsFrtFr
	::_sFornece := ""
	::_sLoja    := ""
	::_aNaoPrev := {}
	::_aRegsZZ1 := {}
	::_bValor   := .F.
Return Self
