//  Programa  : MNTNG
//  Autor     : Andre Alves
//  Data      : 18/06/2019
//  Descricao : PE para valida��es especificas do aplicativo MNT NG	
// 
//  Historico de alteracoes:
//  21/06/2019 - Andre  - Adicionado valida��o de datas retroativas.
//  07/04/2021 - Robert - Faltava declaracao variavel oParser (GLPI 9774)
//

//  ---------------------------------------------------------------------------------------------------------------------

#include "PROTHEUS.ch"
User Function MNTNG()
   
    Local cId := PARAMIXB[1] //Indica o momento da chamada do PE
    Local oWS := PARAMIXB[2] //Objeto com refer�ncia ao webservice
    //Local oParser, aArea, aAreaSTL
	local oParser := NIL
   // Local _xRet := NIL
      
    If cId == "CANCEL_VALID" //valida cancelamento da ordem
        If FWJsonDeserialize(oWS:GetContent(),@oParser) //Parse da string no formato Json
            If Empty( oParser:message )//verifica campo observa��o foi passado vazio
                Return "A observa��o do cancelamento � obrigat�ria."
            EndIf
        EndIf
      
    ElseIf cId == "FINISH_VALID_ORDER"
        If FWJsonDeserialize(oWS:GetContent(), @oParser)
            If Empty( oParser:observation ) //verifica campo observa��o foi passado vazio
                Return "Campo observa��o deve ser informado."
            EndIf
            if STOD(substr(oParser:startDate, 1, 8)) < date () -3 .and. STOD(substr(oParser:startDate, 1, 8)) > date () 
               	Return "Data inicial nao pode ser menor do que data de hoje."
            endif
            if STOD(substr(oParser:endDate, 1, 8)) < date () -3 .and. STOD(substr(oParser:endDate, 1, 8)) > date ()
            	Return "Data final nao pode ser menor do que data de hoje."
            endif
        EndIf
        
    ElseIf cId == "FILTER_PRODUCT" //adiciona filtro para busca de produtos
        Return  "AND B1_TIPO = 'MM'" 
    EndIf
  
Return
