// Programa...: LJ7053
// Autor......: Catia Cardoso
// Data.......: 13/06/2017
// Descricao..: Ponto de Entrada no Venda Assistida - Criando mais opcoes
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de Entrada no Venda Assistida - Criando mais opcoes
// #PalavasChave      #barra_de_funcoes
// #TabelasPrincipais #SL1 
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
// 27/03/2018 - Catia   - Permitir alteracao todas as condicoe de pagamento para 997 ele so permitia a 07
// 19/02/2021 - Claudia - Incluidas tags de pesquisa
//
// ---------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function LJ7053()
	Local aArrayaRotinas	:= { {"Alt.Condição"  , "U_VA_LJCOND()", 0, 1, ,.F.} }
	
return	aArrayaRotinas
//
// ---------------------------------------------------------------------------------------------------------
// Solicita nova condicao de pagamento
User function VA_LJCOND()
	local _lRet := .T.

	if _lRet
		_sDtvenda = SL1 -> L1_EMISSAO
		_sOldCond = SL1 -> L1_CONDPG	
		
		if _sDtvenda < (date() -10) // permite alterar cupons emitidos ate 2 dias antes
			u_help("Data da Venda não permite mais a alteração da condição de pagamento.")
			return
		endif
		
		_sNewCond = U_Get ("Condição Pagamento", "C", 3, "@!", "SE4", _sOldCond, .F., '.T.')
		
		reclock ("SL1", .F.)
			SL1 -> L1_CONDPG = _sNewCond
		msunlock ()      
	endif
return
