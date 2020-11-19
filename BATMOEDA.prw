// Programa:   ATUMOEDAS
// Autor:      Andre Alves
// Data:       26/10/2018
// Descricao:  Atualização automática das moedas (Dolar e EURO).
//
#include "TOTVS.CH"

User Function BATMOEDA() 

//Local cArq, cTexto, nLinhas, j
Local cArq, j
Local m      		:= 0
Local aDados  		:= {}
Local cLocalFile 	:= ""
Local cURL1 		:= ""
Local cUserPwd 		:= ""
Local aInfo 		:= {}
local _sArqLog2 	:= iif (type ("_sArqLog") == "C", _sArqLog, "")
Local nPass			:= 0

_sArqLog := U_NomeLog (.t., .f.)
u_logId ()
u_logIni ()
u_logDH ()

nRet := 0
For nPass := 0 to 0 step -1 
// Refaz dos ultimos 7 dias para o caso de algum dia a conexao ter falhado 
      
   dDataRef := dDataBase - nPass
   cLinha := ""
    If Dow(dDataRef) == 1    // Se for domingo 
          cArq := DTOS(dDataRef - 2)+".csv"
     ElseIf Dow(dDataBase) == 7            // Se for sábado 
          cArq := DTOS(dDataRef - 1)+".csv"
     Else                                   // Se for dia normal 
          cArq := DTOS(dDataRef)+".csv"
     EndIf 
         
     cLocalFile := "c:\temp\"+cArq
     u_log ('Arquivo para download:', cLocalFile)
     //msgalert("Fazendo download do arquivo " + cLocalFile)
     cURL1 := "https://www4.bcb.gov.br/download/fechamento/"+cArq   
     nRet = WDClient("GET", cLocalFile, cURL1, "", cUserPwd, @aInfo)
     u_log ('retorno do wdclient:', nRet)
     sleep (5000)
     if ! file (cLocalFile)
     	u_log ('nao gerou arquivo')
     else
	     FT_FUSE(cLocalFile)
	     u_log ('abri arquivo')
	     FT_FGOTOP()
	     u_log ('vou ler arquivo')
	     While !FT_FEOF()
	     	cLinha := FT_FREADLN()
	     	u_log ('linha lida:', cLinha)
	     	AADD(aDados,Separa(cLinha,";",.T.))
	     	FT_FSKIP()
	     EndDo
	     u_log ('terminei de ler arq')
	     u_log (aDados)   
	
	     if Len (aDados) > 0
	     For j := 1 to len (aDados)
	      		u_log ('processando linha', j)
		          cData :=  aDados[j,1]
		          cCompra := aDados[j,5]
		          if aDados[j,2] == "220" // Dolar Americano
		               DbSelectArea("SM2") 
		               DbSetOrder(1) 
		               dData := CTOD(cData)-1
		               For m := 1 To 1 // Se 1 to 15 projeta para 15 dias 
		               dData++
		               If DbSeek(DTOS(dData)) 
		                   Reclock("SM2",.F.)
		               Else 
		                   Reclock("SM2",.T.) 
		                   Replace M2_DATA With dData
		               EndIf
		              	   Replace M2_MOEDA2 With Val (strtran (cCompra, ',', '.'))
		                   Replace M2_INFORM With "S" 
		                   MsUnlock("SM2") 
		               Next
		               u_log ('gravei moeda 220') 
		          EndIf 
		          if aDados[j,2] =="978" // EURO
		               DbSelectArea("SM2") 
		               DbSetOrder(1) 
		               dData := CTOD(cData)-1 
		               For m := 1 To 1 // Se 1 to 15 projeta para 15 dias
		               dData++ 
		               If DbSeek(DTOS(dData)) 
		                  Reclock("SM2",.F.) 
		               Else 
		                  Reclock("SM2",.T.) 
		                  Replace M2_DATA   With dData 
		               EndIf
		                  Replace M2_MOEDA3 With Val (strtran (cCompra, ',', '.')) 
		                  Replace M2_INFORM With "S" 
		                  MsUnlock("SM2") 
		               Next 
		               u_log ('gravei moeda 978') 
		          EndIf
		      Next
		endif
	Endif
Next    
    
//if nRet == 0
//   u_help("Download bem sucedido, verifique nos arquivos locais")
//else
//   u_help("Erro " + AllTrim(Str(nRet)) + " no download")
//endif    
u_logFim ()
_sArqLog = _sArqLog2
Return .T.
