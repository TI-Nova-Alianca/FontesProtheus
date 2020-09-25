//  Programa...: FA430FIG
//  Autor......: Catia Cardoso
//  Data.......: 14/09/2015
//  Descricao..: Este Ponto de Entrada permite modificar o CNPJ obtido da leitura do arquivo de retorno DDA, de modo que a tabela SA2 seja posicionada por meio do CNPJ modificado neste Ponto de Entrada

User Function FA430FIG() 
	aDados := PARAMIXB
	//Alert('CGC: ' + aDados[1] + ' Fornecedor: ' + aDados[2] + ' Prefixo: '+aDados[3] + ' Título: '+aDados[4] +' Parcela: '+aDados[5]) 
Return aDados[1]