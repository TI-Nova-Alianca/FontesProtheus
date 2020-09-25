//  Programa...: Relat�rio SIGAMNT
//  Autor......: Andre Alves
//  Data.......: 09/08/2018
//  Descricao..: Relat�rio de Impress�o Gr�fica para O.S
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

oPrint:Say(li,140 ,"|___________________PREENCHIMENTO MANUTENTOR (OBRIGAT�RIO)_____________________|",oFonTMN)
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
oPrint:Say(li,140 ,"| C�DIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| C�DIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| C�DIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| C�DIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
li += 100
oPrint:Say(li,140 ,"| C�DIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
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
oPrint:Say(li,140 ,"| OCORR�NCIA |_______________________________________________________________________________________|",oFonTPN)
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
oPrint:Say(li,140 ,"| SOLU��O    |_______________________________________________________________________________________|",oFonTPN)
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

oPrint:Say(li,140 ,"|                     NECESS�RIO CIP?  SIM (    ) N�O (    )                   |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|                NECESS�RIO ESTERILIZACAO?  SIM (    ) N�O (    )              |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|           DISPOSITIVOS DE SEGURAN�A ATUANDO ?  SIM (    ) N�O (    )         |",oFonTMN)
li += 100
oPrint:Say(li,140 ,"|____________________________CONSIDERA��ES FINAIS______________________________|",oFonTMN)
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