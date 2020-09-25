//  Programa  : NGTWFPro
//  Autor     : Andre Alves
//  Data      : 06/01/2020
//  Descricao : PE para Customizacao do layout de workflows
// 
//  Historico de alteracoes:
//  
//  ---------------------------------------------------------------------------------------------------------------------

#Include 'PROTHEUS.CH'
 
User Function NGTWFPro()
 
    Local oProcess := ParamIXB[1]
    Local cOrigin  := ParamIXB[2]
    Local nIndex   := 0
 
    Do case
    
    case cOrigin == 'MNTW040'
 
        aAdd( oProcess:oHTML:ValByName( 'head1.strBEMPAR' ), 'Parado'        )
        aAdd( oProcess:oHTML:ValByName( 'col1.strBEMPAR'  ), TQB->TQB_PARADA )
        /*
        dbSelectArea( 'ST9' )
        dbSetOrder( 1 )
        dbSeek( xFilial( 'ST9' ) + TQB->TQB_CODBEM )
 
        aAdd( oProcess:oHTML:ValByName( 'head2.strCcusto' ), 'Centro de Custos'   )
        aAdd( oProcess:oHTML:ValByName( 'head2.strCtrab'  ), 'Centro de Trabalho' )
 
        aAdd( oProcess:oHTML:ValByName( 'col2.strCcusto' ), ST9->T9_CCUSTO  )
        aAdd( oProcess:oHTML:ValByName( 'col2.strCtrab'  ), ST9->T9_CENTRAB )
        */
 
      // Inclusão de S.S.
    Case cOrigin == 'MNTW025'
 
   		aAdd( oProcess:oHTML:ValByName( 'head.strBEMPAR' ), 'Parado'        )
   		aAdd( oProcess:oHTML:ValByName( 'cols.strBEMPAR'  ), TQB->TQB_PARADA )
    
    EndCase
 
Return oProcess