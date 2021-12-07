//  Programa...: Relatório SIGAMNT
//  Autor......: Andre Alves
//  Data.......: 09/08/2018
//  Descricao..: Relatório de Impressão Gráfica para O.S
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Relatório de Impressão Gráfica para O.S
// #PalavasChave      #ponto_de_entrada #impressao_OS 
// #TabelasPrincipais 
// #Modulos           #MNT
//
//  Historico de alteracoes:
// 07/12/2021 - Claudia - Alterada a variavel de li para lin, pois nao estava mais sendo identificada. GLPI:11164
//
// -----------------------------------------------------------------------------------------------------------------
#include "totvs.ch"

User Function MNTR675G()

	oFonTPN := TFont():New("Courier New",10,10,,.T.,,,,.F.,.F.)
	oFonTMN := TFont():New("Courier New",13,13,,.T.,,,,.F.,.F.)

	lin += 100 //Incrementa linhas

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|___________________PREENCHIMENTO MANUTENTOR (OBRIGATÓRIO)_____________________|",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|DATA INICIAL|  /  /    |HORA INICIAL|   :           |DATA FINAL|  /  /    |HORA FINAL|   :          |",oFonTPN)
	lin += 100


	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|_____________________________INSUMOS CONSUMIDOS_______________________________|",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| CÓDIGO |_________| QTD |__________|________________________________________________________________|",oFonTPN)
	lin += 200

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|_____________PREENCHIMENTO MANUTENTOR (EM CASO DE O.S CORRETIVA)______________|",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"| OCORRÊNCIA |_______________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| CAUSA      |_______________________________________________________________________________________|",oFonTPN)
	lin += 100

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"| SOLUÇÃO    |_______________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100


	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|                     NECESSÁRIO CIP?  SIM (    ) NÃO (    )                   |",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"|                NECESSÁRIO ESTERILIZACAO?  SIM (    ) NÃO (    )              |",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"|           DISPOSITIVOS DE SEGURANÇA ATUANDO ?  SIM (    ) NÃO (    )         |",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________CONSIDERAÇÕES FINAIS______________________________|",oFonTMN)
	lin += 100

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100
	oPrint:Say(lin,140 ,"|____________________________________________________________________________________________________|",oFonTPN)
	lin += 100

	If lin > 2800
		lin := 100
		//nPaG ++
		oPrint:EndPage()
		oPrint:StartPage()
	endif 

	oPrint:Say(lin,140 ,"| Assinatura Solicitante |_____________________________________________________|",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"| Assinatura Executor    |_____________________________________________________|",oFonTMN)
	lin += 100
	oPrint:Say(lin,140 ,"| Assinatura Supervisor  |_____________________________________________________|",oFonTMN)

Return .T.
