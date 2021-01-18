// Programa:   BatMail
// Autor:      Robert Koch
// Data:       02/10/2014
// Descricao:  Tenta enviar e-mails pendentes no workflow. Este batch foi criado por
//             que limitamos o numero de mensagens que podem ser enviadas por espaco
//             de tempo no servidor de e-mail, para evitar spam. Assim, quando o sistema
//             gera muitos e-mails de uma soh vez, os primeiros sao enviados e os demais
//             acabam ficando esquecidos na fila, pois o sistema nao tenta reenviar sozinho.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Executa 'job' de envio de todos os e-mails pendentes.
// #PalavasChave      #fila_de_e-mail #fila #email #e-mail
// #TabelasPrincipais 
// #Modulos           

// Historico de alteracoes:
// 17/01/2021 - Robert - Incluidos logs de inicio e fim de execucao (parece estar travando)
//                     - Inseridas tags para catalogo de programas.
//

// --------------------------------------------------------------------------
user function BatMail ()
	U_Log2 ('info', 'Iniciando ' + procname ())
	StartJob( "WFLauncher", GetEnvServer(), .f., { "WFSndMsgAll", { cEmpAnt, cFilAnt } } )
	U_Log2 ('info', 'Finalizando ' + procname ())
Return .T.
