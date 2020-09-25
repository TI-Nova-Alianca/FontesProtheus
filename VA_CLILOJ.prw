//  Programa...: VA_CLILOJ
//  Autor......: Cláudia Lionço
//  Data.......: 29/06/2020
//  Descricao..: Compras de clientes das lojas
//  GLPI.......: 8121
// 
//  Historico de alterações
//
// ----------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_CLILOJ()
	MsgRun("Aguarde o processamento...", "Compras de clientes das lojas com mais de 31 dias", {|| _ExecQuery()}) 
Return
// ----------------------------------------------------------------------------------
// Consulta 
Static Function _ExecQuery()
	Local _oSQL := NIL
	
	_sDtAtual := DTOS( Date() )
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT"
	_oSQL:_sQuery += " 		L1_VEND AS VENDEDOR"
	_oSQL:_sQuery += "     ,SA3.A3_NOME AS NOME_VENDEDOR "
	_oSQL:_sQuery += " 	   ,L1_CLIENTE AS CLIENTE"
	_oSQL:_sQuery += " 	   ,L1_LOJA AS LOJA"
	_oSQL:_sQuery += " 	   ,A1_NOME AS NOME"
	_oSQL:_sQuery += " 	   ,SA1.A1_TEL AS TELEFONE"
	_oSQL:_sQuery += " 	   ,SA1.A1_EMAIL AS EMAIL"
	_oSQL:_sQuery += " 	   ,MAX(L1_EMISSAO) AS ULTIMA_COMPRA"
	_oSQL:_sQuery += " 	   ,DATEDIFF(DAY, MAX(L1_EMISSAO), '" + _sDtAtual + "') AS DIAS_SEM_COMPRAR"
	_oSQL:_sQuery += " 	FROM  " + RetSqlName("SL1") + " SL1 "
	_oSQL:_sQuery += " 	INNER JOIN " + RetSqlName("SA1") + " SA1 "
	_oSQL:_sQuery += " 		ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SA1.A1_COD = SL1.L1_CLIENTE"
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = SL1.L1_LOJA"
	_oSQL:_sQuery += " 		AND SA1.A1_MSBLQL = 2)"
	_oSQL:_sQuery += " 		INNER JOIN " + RetSqlName("SA3") + " SA3 "
	_oSQL:_sQuery += " 			ON (SA3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA3.A3_COD= SL1.L1_VEND)"
	_oSQL:_sQuery += " 	WHERE SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SL1.L1_VEND IN ('060', '135', '186', '240')"
	_oSQL:_sQuery += " 	GROUP BY L1_VEND"
	_oSQL:_sQuery += " 			,L1_CLIENTE"
	_oSQL:_sQuery += " 			,L1_LOJA"
	_oSQL:_sQuery += " 			,A1_NOME"
	_oSQL:_sQuery += " 			,SA1.A1_TEL"
	_oSQL:_sQuery += " 			,SA1.A1_EMAIL"
	_oSQL:_sQuery += "          ,SA3.A3_NOME)"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	*"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " WHERE DIAS_SEM_COMPRAR > 31"
	_oSQL:_sQuery += " ORDER BY VENDEDOR, DIAS_SEM_COMPRAR, CLIENTE, LOJA"
	_oSQL:Log ()
	_oSQL:F3Array ('Compras de clientes das lojas com mais de 31 dias')

Return