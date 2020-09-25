// Programa:  MT410Cpy
// Autor:     Robert Koch
// Data:      16/10/2008
// Cliente:   Alianca
// Descricao: P.E. durante a copia de pedidos de venda.
//            Criado, inicialmente, para limpar campos que nao devem ser copiados.
//
// Historico de alteracoes:
// 09/03/2009 - Robert - Incluido campo C5_VAUSER.
// 14/05/2009 - Robert - Incluido campo C5_VADCO.
// 23/06/2009 - Robert - Incluido campo C5_PEDCLI.
// 22/05/2014 - Robert - Incluido campo C5_TPCARGA.
// 27/05/2014 - Robert - Incluido campo C5_VAPEMB.
//

// --------------------------------------------------------------------------
user function M461DINF ()
	
	if c5_data1 < DATE
	Alert (" Data fatura menor que a data base - M461DINF " )
	endif
return
