// Programa...: EnvEtFul
// Autor......: Robert Koch
// Data.......: 19/07/2018
// Descricao..: Envia etiqueta para ser recebida pelo FullWMS.
//              Gerado Com base no SD3250I.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Envia etiquetas de pallets para o FullWMS, gravando-as na tabela tb_wms_etiquetas
// #PalavasChave      #etiqueta #FullWMS
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

// Historico de alteracoes (do SD3250I, mantido para ter historico do calculo de data de validade dos lotes)
// 01/08/2017 - Robert - Passa a gravar a tabela tb_wms_etiquetas (era feito logo apos a impressao das etiquetas).
// 18/08/2017 - Robert - Valid.produto na gravacao de etiquetas para FullWMS (tb_wms_etiquetas) - GLPI 2981
//                          - Quando OP de reprocesso assume dt valid do lote original (C2_VADVORI), cfe informada pelo usuario.
//                          - Quando OP normal, calculava dt.valid.=ZA1_DATA+B1_PRVALID. Alterado para C2_DATPRI+B1_PRVALID para manter consistencia com a impressao da OP.
// 25/08/2017 - Robert - Passa a gravar a data de validade como C2_DATPRF+B1_PRVALID nas etiquetas.
//
// Historico de alteracoes (deste programa)
// 04/09/2018 - Robert - Implementada exportacao de etiq. de NF
//                     - Reestruturacao exportacao de etiq. de OP
//                     - Grava campo tb_wms_etiquetas.status=N
// 24/10/2018 - Robert - Separado tratamento por origem (OP / NF / tabela ZAG)
// 25/09/2019 - Robert - Nao considerava ZAG_ALMORI na busca do lote no SB8.
// 20/08/2020 - Robert - Envia para o Full somente se o item existir na view v_wms_item.
//                     - Inseridas tags para catalogar fontes.
// 10/11/2020 - Robert - Valida dados logisticos no Full (qt.pallet e regiao de armazenagem) antes de enviar a etiqueta (GLPI 8790)
// 24/01/2022 - Robert - Vamos usar etiquetas no AX02, mesmo sem integracao com FullWMS (GLPI 11515).
// 11/02/2022 - Robert - Desabilitado envio para Full quando etiq. de NF de entrada (nunca chegamos a usar).
// 31/03/2022 - Robert - Passa a usar a classe ClsEtiq() - GLPI 11825
// 15/06/2022 - Robert - Removidas linhas comentariadas.
//

// ------------------------------------------------------------------------------------
User Function EnvEtFul (_sEtiq, _lMsg)
	Local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := NIL
	_oEtiq := ClsEtiq ():New (_sEtiq)
	_oEtiq:EnviaFull (_lMsg)
	U_ML_SRArea (_aAreaAnt)
Return
