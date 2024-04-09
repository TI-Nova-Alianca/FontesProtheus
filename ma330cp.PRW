// Programa:  MA330CP
// Autor:     Claudio Gualdi - Totvs
// Data:      01/2020 (simulacoes iniciais)
// Descricao: P.E. que define o criterio de separacao das 'partes' para o custo em partes.
//
// Historico de alteracoes:
// 13/07/2020 - Robert - Definidas partes em reuniao de diretoria: MO+AP / GF / ME / MP / BN
//                     - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #PalavasChave      #custo_medio #custo_em_partes
// #TabelasPrincipais #SB1
// #Modulos           #EST

#include "rwmake.ch"
#include "topconn.ch"

// --------------------------------------------------------------------------
user function ma330cp()
	local _aRegraCP:={}

	// ATENCAO: Manter compaibilidade com a stored procedure MA330CP_01
	aAdd (_aRegraCP,"SB1->B1_TIPO $ 'MO/AP' ")
	aAdd (_aRegraCP,"SB1->B1_TIPO == 'GF'")
	aAdd (_aRegraCP,"SB1->B1_TIPO == 'ME'")
	aAdd (_aRegraCP,"SB1->B1_TIPO == 'MP'")
	aAdd (_aRegraCP,"SB1->B1_TIPO == 'BN'")
	
	// Apenas para mostrar as regras para o usuario.
//	_sMsg := 'Conferencia regras custo partes MA330CP' + chr (13) + chr (10) + chr (13) + chr (10)
//	aEval (_aRegraCP, {|_x| _sMsg += _x + chr (13) + chr (10)}) 
//	msgalert (_sMsg, 'Informacoes')

return _aRegraCP
