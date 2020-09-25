// Programa:   BatMail
// Autor:      Robert Koch
// Data:       02/10/2014
// Descricao:  Tenta enviar e-mails pendentes no workflow. Este batch foi criado por
//             que limitamos o numero de mensagens que podem ser enviadas por espaco
//             de tempo no servidor de e-mail, para evitar spam. Assim, quando o sistema
//             gera muitos e-mails de uma soh vez, os primeiros sao enviados e os demais
//             acabam ficando esquecidos na fila, pois o sistema nao tenta reenviar sozinho.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function BatMail ()
	StartJob( "WFLauncher", GetEnvServer(), .f., { "WFSndMsgAll", { cEmpAnt, cFilAnt } } )
Return .T.
