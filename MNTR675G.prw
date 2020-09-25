//  Programa...: Relatório SIGAMNT
//  Autor......: Andre Alves
//  Data.......: 09/08/2018
//  Descricao..: Relatório de Impressão Gráfica para O.S
//
//  Historico de alteracoes:
//


User Function MNTR675G()

oFonTPN := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
oFonTMN := TFont():New("Courier New",13,13,,.T.,,,,.F.,.F.)

li += 100 //Incrementa linhas

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|___________________PREENCHIMENTO MANUTENTOR (OBRIGATÓRIO)_____________________|",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
li += 100


If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|_____________________________INSUMOS CONSUMIDOS_______________________________|",oFonTMN)
li += 100
oPrint:Say(li,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
li += 100

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|_____________PREENCHIMENTO MANUTENTOR (EM CASO DE O.S CORRETIVA)______________|",oFonTMN)
li += 100
oPrint:Say(li,140 ,"| OCORRÊNCIA |_______________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| CAUSA      |_______________________________________________________________________________________|",oFonTPN)
li += 100

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| SOLUÇÃO    |_______________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100


If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|                     NECESSÁRIO CIP?  SIM (    ) NÃO (    )                   |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|                NECESSÁRIO ESTERILIZACAO?  SIM (    ) NÃO (    )              |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|           DISPOSITIVOS DE SEGURANÇA ATUANDO ?  SIM (    ) NÃO (    )         |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|____________________________CONSIDERAÇÕES FINAIS______________________________|",oFonTMN)
li += 100

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
li += 100

If li > 2800
		li := 100
		nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
endif 

oPrint:Say(li,140 ,"| Assinatura Solicitante |_____________________________________________________|",oFonTMN)
li += 100
oPrint:Say(li,140 ,"| Assinatura Executor    |_____________________________________________________|",oFonTMN)
li += 100
oPrint:Say(li,140 ,"| Assinatura Supervisor  |_____________________________________________________|",oFonTMN)

Return .T.