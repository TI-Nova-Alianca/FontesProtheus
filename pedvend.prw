// Programa...: pedvend
// Autor......: --------
// Data.......: 17/06/2011
// Descricao..: Faz a chamada do programa pedcong e o programa envped, um imprime o pedido e o programa envped,
//			  imprime o pedido e o outro envia por e-mail.  
//
// Historico de alteracoes:
// 18/07/2019 - Andre  - Incluido query para que envio seja apenas para pedido liberados.
// 30/08/2019 - Andre  - Removido query para pedidos liberados.
//
//---------------------------------------------------------------------------------

User Function pedvend()
	private caminho := '' 

	U_ML_PCPR()//chama programa de impressão grafica (gera PDF) 
	U_ENVPED(caminho)//chama o programa para enviar por e-mail
Return 
