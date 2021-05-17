// Programa:  MtColSE2
// Autor:     Robert Koch
// Data:      12/05/2021
// Descricao: P.E. para modificar os campos do aCols de duplicatas da nota de entrada
//            Usado inicialmente para declarar a variavel _aHeadSE2, que vai ser lida pelo MTColSE2.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada durante a gravacao da NF de entrada. Permite modificar os campos do aCols de duplicatas da nota de entrada. Usado inicialmente para declarar a variavel _aHeadSE2, que vai ser lida pelo MTColSE2.
// #PalavasChave      #ponto_de_entrada #NF_entrada #duplicatas #safra
// #TabelasPrincipais #SE2
// #Modulos           #COM #EST #COOP

// Historico de alteracoes
//

// --------------------------------------------------------------------------
user function MT103SE2 ()
	local _aRet := NIL  // Quero retorno invalido. Este P.E. serve apenas para declarar a variavel _aHeadSE2.

	// Esta variavel vai ser lida posteriormente pelo ponto de entrada MTColSE2.
	public _aHeadSE2 := aclone (paramixb [1])
return _aRet
