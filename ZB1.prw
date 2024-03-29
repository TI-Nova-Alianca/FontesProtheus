// Programa...: ZB1
// Autor......: Cl�udia Lion�o
// Data.......: 21/08/2020
// Descricao..: Tela de extrato de recebimento Cielo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de extrato de recebimento Cielo
// #PalavasChave      #extrato #cielo #recebimento #cartoes 
// #TabelasPrincipais #ZB1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 02/12/2020 - Claudia - Ajuste de devolu��es - GLPI: 8937
// 24/02/2021 - Claudia - Invertida a legenda 
// 29/03/2021 - Claudia - Incluida filial 13. GLPI: 9710
// 19/04/2021 - Claudia - Incluido relatorio de diferen�as de valores. GLPI: 9835
// 18/05/2021 - Claudia - Incluida chamada para concilia�ao de NF loja. GLPI: 10039
// 04/11/2021 - Claudia - Ajustado para importar somente venda de link cielo. GLPI 11145
//
// ----------------------------------------------------------------------------------
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "totvs.ch"

User Function ZB1()
	Local _sFiltrTop  := ""
	Local _lContinua  := .T.
	Private aRotina   := {}  
	Private _aCores   := {}
	Private cCadastro := "Extrato de recebimento Cielo"

	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("N�o foi poss�vel obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif

	If _lContinua
	/*
		Aadd(aRotina2, {"Funcao 11", "U_Funcao11", 0, 3 } )

		1. Nome a aparecer no cabecalho                            
		2. Nome da Rotina associada                                 
		3. Campo reservado                                   
		4. Tipo de Transacao a ser efetuada
			4.1 - Pesquisa e Posiciona em um Banco de Dados            
			4.2 - Simplesmente Mostra os Campos                        
			4.3 - Inclui registros no Bancos de Dados                  
			4.4 - Altera o registro corrente                           
			4.5 - Remove o registro corrente do Banco de Dados       
			4.6 - Altera determinados campos sem incluir novos Regs
	*/
		AADD(aRotina, {"&Visualizar" 	     , "AxVisual"      , 0, 1})
		AADD(aRotina, {"Importar"    	     , "U_ZB1_IMP()"   , 0, 4})
		//AADD(aRotina, {"Conciliar Cielo Loja", "U_ZB1_CON('1')", 0, 4})
		AADD(aRotina, {"Conciliar Cielo Link", "U_ZB1_CON('2')", 0, 4})
		//AADD(aRotina, {"Conciliar NF's Lojas", "U_ZB1_CON('3')", 0, 4})
		AADD(aRotina, {"&Legenda"        	 , "U_ZB1LGD (.F.)", 0 ,5})
		AADD(aRotina, {"Relatorio titulos"   , "U_ZB1RTIT()"   , 0, 6})
		AADD(aRotina, {"Relatorio importa��o", "U_ZB1REL()"    , 0, 6})
		AADD(aRotina, {"Relatorio diferen�as", "U_ZB1DIF()"    , 0, 6})
		AADD(aRotina, {"Fechar Registro"     , "U_ZB1_FEC()"   , 0, 6})

		AADD(_aCores,{ "ZB1_STAIMP == 'I'", 'BR_VERDE'    }) // importado
		AADD(_aCores,{ "ZB1_STAIMP == 'C'", 'BR_VERMELHO' }) // conciliado
		AADD(_aCores,{ "ZB1_STAIMP == 'F'", 'BR_PRETO'    }) // fechado
		AADD(_aCores,{ "ZB1_STAIMP == 'D'", 'BR_AZUL'     }) // debito
                      
		dbSelectArea ("ZB1")
		dbSetOrder (1)
		_sFiltrTop := "ZB1_FILIAL ='" + cFilAnt +"'"
		mBrowse(,,,,"ZB1",,,,,,_aCores,,,,,,,,_sFiltrTop)
	EndIf

Return
//
// --------------------------------------------------------------------------
// Retorna Legenda
User function ZB1LGD (_lRetCores)
	local aCores  := {}
	local aCores2 := {}
	local _i       := 0
	
	aadd (aCores, {"ZB1->ZB1_STAIMP=='I'", 'BR_VERMELHO', 'Reg.Importados'	})
	aadd (aCores, {"ZB1->ZB1_STAIMP=='C'", 'BR_VERDE'	 , 'Reg.Baixados'	})
	aadd (aCores, {"ZB1->ZB1_STAIMP=='F'", 'BR_PRETO'	 , 'Reg.Fechados'	})
	aadd (aCores, {"ZB1->ZB1_STAIMP=='D'", 'BR_AZUL'	 , 'Reg.Debitados'	})

	if ! _lRetCores
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 2], aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", aCores2)
	else
		for _i = 1 to len (aCores)
			aadd (aCores2, {aCores [_i, 1], aCores [_i, 2]})
		next
		return aCores
	endif
	
return





