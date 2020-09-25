// Programa...: F340DTFIN
// Autor......: Catia Cardoso	
// Data.......: 12/02/2018
// Descricao..: Valida data de pagamento
//
// Historico de alteracoes:
// 12/02/2018 - Catia - Implementado este ponto de entrada para que passe a validar o parametro MV_DATAFIN
//					  - nas compensaçoes CP - duvidas verificar link abaixo  
//                    - http://13.68.112.198/display/public/mp/F340DTFIN+-+Valida+data+de+pagamento+--+11755   
//                    - alterado tambem o parametro MV_BXDTFIN 
// --------------------------------------------------------------------------

#include "RWMAKE.CH"
#include "PROTHEUS.CH"
USER FUNCTION F340DTFIN
Return .T.