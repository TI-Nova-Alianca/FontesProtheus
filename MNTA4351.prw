// Programa:  MNTA4351
// Autor:     Robert Koch
// Data:      03/10/2022
// Descricao: Cria botao adicional na tela de retorno de OS mod.2
//            Criado por solicitacao via GLPI 12645.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Cria botao adicional na tela de retorno de OS mod.2
// #PalavasChave      #botao #botoes #retorno_OS_modelo_2 #retorno_modelo_2 #MNTA435
// #TabelasPrincipais #STJ
// #Modulos           #MNT

// --------------------------------------------------------------------------
user function MNTA4351 ()
	local _aBtn435 := {"PDCOMPRA", {||U_MNT453PC ()}, "oBtBCn", "Ped.compra", ""}
return _aBtn435
