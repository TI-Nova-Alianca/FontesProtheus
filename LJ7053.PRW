// Programa...: LJ7053
// Autor......: Catia Cardoso
// Data.......: 13/06/2017
// Descricao..: Ponto de Entrada no Venda Assistida - Cria mais opcoes no menu
//              Usado inicialmente para criar botao de alteracao de condicao de pagamento.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de Entrada no Venda Assistida - Criando mais opcoes
// #PalavasChave      #barra_de_funcoes
// #TabelasPrincipais #SL1 
// #Modulos   		  #LOJA 

// Historico de alteracoes:
// 27/03/2018 - Catia   - Permitir alteracao todas as condicoe de pagamento para 997 ele so permitia a 07
// 19/02/2021 - Claudia - Incluidas tags de pesquisa
// 05/04/2021 - Robert  - Grava evento para posterior rastreamento (GLPI 9573)
//

// ---------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function LJ7053()
	Local aArrayaRotinas	:= { {"Alt.Condição"  , "U_VA_LJCOND()", 0, 1, ,.F.} }
return	aArrayaRotinas


// ---------------------------------------------------------------------------------------------------------
// Solicita nova condicao de pagamento
User function VA_LJCOND()
	local _lRet    := .T.
	local _oEvento := NIL

	if _lRet
		_sDtvenda = SL1 -> L1_EMISSAO
		_sOldCond = SL1 -> L1_CONDPG	
		
		if _sDtvenda < (date() -10) // permite alterar cupons emitidos ate 2 dias antes
			u_help("Data da Venda não permite mais a alteração da condição de pagamento.")
			return
		endif
		
		_sNewCond = U_Get ("Condição Pagamento", "C", 3, "@!", "SE4", _sOldCond, .F., '.T.')

		if ! empty (_sNewCond)
			reclock ("SL1", .F.)
			SL1 -> L1_CONDPG = _sNewCond
			msunlock ()

			// Grava evento para posterior rastreamento
			_oEvento := ClsEvent ():New ()
			_oEvento:Alias = 'SL1'
			_oEvento:Texto = 'Alterada cond.pagto.de ' + _sOldCond + ' para ' + _sNewCond + ' apos emissao do cupom'
			_oEvento:NFSaida = sl1 -> l1_doc
			_oEvento:SerieSaid = sl1 -> l1_serie
			_oEvento:CodEven   = 'SL1002'
			_oEvento:Cliente   = sl1 -> l1_cliente
			_oEvento:LojaCli   = sl1 -> l1_loja
			_oEvento:Grava ()
		endif
	endif
return
