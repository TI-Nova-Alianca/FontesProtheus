// Programa:  ClsFrtPV
// Autor:     Robert Koch
// Data:      21/05/2008
// Descricao: Declaracao de classe para representar cotacao de frete para pedido de venda / carga.
//
// Historico de alteracoes:
// 10/07/2008 - Robert - Criacao de novos atributos.
// 08/08/2008 - Robert - Criacao de novos atributos.
// 30/06/2017 - Robert - Criado atributo _TrRedesp.
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
//user function ClsFrtPV ()
//return


// --------------------------------------------------------------------------
// Classe usada para armazenamento de dados de fretes durante o pedido de venda.
CLASS ClsFrtPV

	// Declaracao das propriedades da Classe
	data _C5NUM
	data _C5CLIENTE
	data _C5LOJACLI
	data _C5CLIENT
	data _C5LOJAENT
	data _C5TRANSP
	data _ZZ1ORIGEM
	data _ZZ1DESTIN
	data _ZZ1PESO
	data _ZZ1UMPESO
	data _ZZ1FRTMIN
	data _ZZ1PESMIN
	data _ZZ1PEDAG
	data _ZZ1QTPEDG
	data _ZZ1ADVALO
	data _ZZ1PALET
	data _ZZ1CAT
	data _ZZ1DESPAC
	data _ZZ1GRIS
	data _ZZ1VLNEGO
	data _ZZ1VLCALC
	data _SemTransp
	data _ZZ1MINADV
	data _ZZ1PFixo1
	data _ZZ1PFixo2
	data _ZZ1PFixo3
	data _ZZ1PFixo4
	data _ZZ1PFixo5
	data _ZZ1PFixo6
	data _ZZ1PFixo7
	data _ZZ1PFixo8
	data _ZZ1PFixo9
	data _ZZ1PFixo10
	data _ZZ1VFixo1
	data _ZZ1VFixo2
	data _ZZ1VFixo3
	data _ZZ1VFixo4
	data _ZZ1VFixo5
	data _ZZ1VFixo6
	data _ZZ1VFixo7
	data _ZZ1VFixo8
	data _ZZ1VFixo9
	data _ZZ1VFixo10
	data _ZZ1PrcMin   // Preco minimo entre as transportadoras disponiveis.
	data _ZZ1TrPMin   // Transportadora que tinha o menor preco entre as disponiveis.
	data _ZZ1Justif   // Justificativa do usuario por nao selecionar a transportadora mais barata.
	data _ZZ1Usuari   // Usuario que fez a selecao do frete.
	data _TrRedesp    // Transportadora redespacho

	// Declaração dos Métodos da Classe
	METHOD New ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New () Class ClsFrtPV
	::_C5NUM      := ""
	::_C5CLIENTE  := ""
	::_C5LOJACLI  := ""
	::_C5CLIENT   := ""
	::_C5LOJAENT  := ""
	::_C5TRANSP   := ""
	::_ZZ1ORIGEM  := ""
	::_ZZ1DESTIN  := ""
	::_ZZ1PESO    := 0
	::_ZZ1UMPESO  := ""
	::_ZZ1FRTMIN  := 0
	::_ZZ1PESMIN  := 0
	::_ZZ1PEDAG   := 0
	::_ZZ1QTPEDG  := 0
	::_ZZ1ADVALO  := 0
	::_ZZ1PALET   := 0
	::_ZZ1CAT     := 0
	::_ZZ1DESPAC  := 0
	::_ZZ1GRIS    := 0
	::_ZZ1VLNEGO  := 0
	::_ZZ1VLCALC  := 0
	::_SemTransp  := .F.
	::_ZZ1MINADV  := 0
	::_ZZ1PFixo1  := 0
	::_ZZ1PFixo2  := 0
	::_ZZ1PFixo3  := 0
	::_ZZ1PFixo4  := 0
	::_ZZ1PFixo5  := 0
	::_ZZ1PFixo6  := 0
	::_ZZ1PFixo7  := 0
	::_ZZ1PFixo8  := 0
	::_ZZ1PFixo9  := 0
	::_ZZ1PFixo10 := 0
	::_ZZ1VFixo1  := 0
	::_ZZ1VFixo2  := 0
	::_ZZ1VFixo3  := 0
	::_ZZ1VFixo4  := 0
	::_ZZ1VFixo5  := 0
	::_ZZ1VFixo6  := 0
	::_ZZ1VFixo7  := 0
	::_ZZ1VFixo8  := 0
	::_ZZ1VFixo9  := 0
	::_ZZ1VFixo10 := 0
	::_ZZ1PrcMin  := 0
	::_ZZ1TrPMin  := ""
	::_ZZ1Justif  := ""
	::_ZZ1Usuari  := cUserName
	::_TrRedesp   := ""
Return Self
