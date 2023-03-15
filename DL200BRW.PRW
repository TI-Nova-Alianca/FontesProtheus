// Programa...: DL200BRW
// Autor......: Cláudia Lionço
// Data.......: 27/01/2021
// Descricao..: Manipulação das Colunas do Browse de Pedidos da Montagem de Carga
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Manipulação das Colunas do Browse de Pedidos da Montagem de Carga
// #PalavasChave      #montagem_de_carga #pedidos 
// #TabelasPrincipais #SC5
// #Modulos   		  #OMS 
//
// Historico de alteracoes:
// 27/01/2021 - Claudia - Retirado os campos pois estavam repetidos no Browse
// 15/03/2023 - Claudia - Alterada ordenção das colunas do pedido. GLPI: 13286/13313
//
// ---------------------------------------------------------------------------------------

#include "totvs.ch"
#include "protheus.ch"

User Function DL200BRW()
    Local aRet := PARAMIXB

    aRet :={}

    AADD(aRet, {"PED_MARCA"	, NIL, " "					," "})
    AADD(aRet, {"PED_PEDIDO", NIL, "Pedido"					})
    AADD(aRet, {"PED_CODCLI", NIL, "Cliente"				})
    AADD(aRet, {"PED_LOJA"	, NIL, "Loja"					})
    AADD(aRet, {"PED_NOME"	, NIL, "Nome"					})
    AADD(aRet, {"PED_TPFRE" , NIL, "CIF/FOB"				})
    AADD(aRet, {"PED_PESO"	, NIL, "Peso"  ,"99999999.999"	})
    AADD(aRet, {"PED_EST"	, NIL, "Estado"					})
    AADD(aRet, {"PED_MUN"	, NIL, "Municipio"				})
    AADD(aRet, {"PED_VALOR"	, NIL, "Valor" ,"99999999.99" 	})
    AADD(aRet, {"PED_VOLUM"	, NIL, "Volume","99999999.999"	})
    AADD(aRet, {"PED_CEP"	, NIL, "CEP"					})
    AADD(aRet, {"PED_BAIRRO", NIL, "Bairro"					})
    AADD(aRet, {"PED_ENDCLI", NIL, "Endereco"				}) 
    AADD(aRet, {"PED_ROTA"	, NIL, "Rota"					})
    AADD(aRet, {"PED_SEQROT", NIL, "Entrega"				})
    AADD(aRet, {"PED_ITEM"	, NIL, "Item"					})
    AADD(aRet, {"PED_SEQLIB", NIL, "Seq. Liberacao"			})
    AADD(aRet, {"PED_CARGA"	, NIL, "Carga"					})
    AADD(aRet, {"PED_QTDLIB", NIL, "Quantidade"				})
    AADD(aRet, {"PED_REDESP", NIL, "Redespachante"			})
    AADD(aRet, {"PED_REDNOM", NIL, "Nome Redespachante"		})

Return aRet
