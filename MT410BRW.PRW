// Programa...: MT410Brw
// Autor......: Robert Koch
// Data.......: 30/08/2010
// Descricao..: P.E. antes de mostrar o MBrowse no programa de pedidos de venda
//              Criado inicialmente para adicionar item no menu.
//
// Historico de alteracoes:
// 27/09/2013 - Robert - Criado submenu de rotinas especificas.
// 23/10/2014 - Robert - Incluida chamada para rotina de aglutinacao de lotes do pedido.
// 04/05/2015 - Catia  - Incluida opcao de alterar o banco mesmo com o pedido em carga - só para o financeiro
// 13/04/2016 - Catia  - Alterar banco - passar parametro com o nro do pedido
// 08/03/2017 - Robert - Criado botao para (re)exportar registro para o mercanet.
// 22/06/2017 - Robert - Criado botao para alterar observacoes do pedido (GLPI 2729).
// 12/11/2019 - Robert - Removido botao de inclusao manual de eventos.
//

// --------------------------------------------------------------------------
user function MT410Brw ()
	local _aRotAdic := {}

	aadd (_aRotAdic, {"Imprimir",       "U__MATR730()", 0, 2})
	aadd (_aRotAdic, {"Alt.transp.",    "U_VA_ATPV()", 0, 2}) 
	aadd (_aRotAdic, {"Vis.Eventos",    "U_VA_SZNC ('PedVenda', sc5->c5_num)", 0, 2})
	aadd (_aRotAdic, {"Enviar p/ Mercanet", "U_AtuMerc ('SC5', sc5 -> (recno ()))", 0, 2})
	aadd (_aRotAdic, {"Alt.observ.",    "U_VA_ATOPV()", 0, 2}) 

	if u_zzuvl ('036', __cUserId, .F.)
		aadd (_aRotAdic, {"Altera Banco", "U_VA_ALTBCO(sc5->c5_num)", 0, 2})
	endif
	
	aadd (aRotina, {"Especificos", _aRotAdic, 0, 2})

return
