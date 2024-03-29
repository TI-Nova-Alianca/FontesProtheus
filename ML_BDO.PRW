// Programa...: ML_BDO
// Autor......: Leandro DWT
// Data.......: 05/2000
// Descricao..: ExecBlock p/ Historico lcto padrao - 562
//   
// #TipoDePrograma    #processo
// #Descricao         #ExecBlock p/ Historico lcto padrao - 562
// #PalavasChave      #LPAD #lancamento_padrao
// #TabelasPrincipais #SE5 
// #Modulos 		  #CTB         
//
// Historico de alteracoes:
// 15/07/2009 - Robert  - Passam a ser contemplados mais historicos
// 15/03/2023 - Sandra  - Incluso op��o 23 "TIT ENVIADO A CARTORIO" - GLPI 13311
// 15/03/2023 - Claudia - Incluido tags de pesquisa de programa.
//
// ----------------------------------------------------------------------------------
#include "rwmake.ch"

User Function Ml_bdo()
     SetPrvt("_CHISTORICO,")
     Do Case
     Case SubStr(SE5->E5_HISTOR,1,11) == "CONFIRMACAO"                        .Or. ;
          SubStr(SE5->E5_HISTOR,1,18) == "ENTRADA CONFIRMADA"                 .Or. ;
          SubStr(SE5->E5_HISTOR,1,09) == "PROTESTAR"                          .or. ;
          SubStr(SE5->E5_HISTOR,1,23) == "TIT ENVIADO A CARTORIO"             .or. ;
          SubStr(SE5->E5_HISTOR,1,15) == "BAIXA DE TITULO"                    .or. ;
          SubStr(SE5->E5_HISTOR,1,16) == "BAIXA SOLICITADA"                   .or. ;
          SubStr(SE5->E5_HISTOR,1,20) == "ABATIMENTO CONCEDIDO"               .or. ;
          SubStr(SE5->E5_HISTOR,1,21) == "ALTERACAO DE VENCIMEN"              .or. ;
          SubStr(SE5->E5_HISTOR,1,06) == "TARIFA"                             .or. ;
          SubStr(SE5->E5_HISTOR,1,21) == "BAIXA CONFORME INSTRU"              .or. ;
          SubStr(SE5->E5_HISTOR,1,21) == "VENCIMENTO PRORROGADO"
          _cHistorico := "DESP COBRANCA CFE BORDERO "+TRIM(SA6->A6_NREDUZ)
     OtherWise
          _cHistorico := SE5->E5_HISTOR
     EndCase

Return(_cHistorico)
