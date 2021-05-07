//  Programa...: VA_TABIGPM
//  Autor......: Catia Cardoso
//  Data.......: 26/10/2016
//  Descricao..: Importa tabela de IGPM
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Importa tabela de IGPM
// #PalavasChave      #IGPM #tabela_IGPM
// #TabelasPrincipais #ZAI 
// #Modulos   		  #FAT
//
//  Historico de alteracoes:
//  07/05/2021 - Claudia - Incluido tags de customizações
//
// --------------------------------------------------------------------
#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_TABIGPM()
	AxCadastro("ZAI","Tabela IPGM",".T.","U_VALZAI()")
Return
//
// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function VALZAI()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	
	if substr( dtos(M->ZAI_DATA) ,7 ,2) != '01' 
		msgalert ("Deve ser usada a data do primeiro dia util do mês.")
		_lRet = .F.
	endif
		
	if _lRet
		ZAI -> (dbsetorder (1))
		if ZAI -> (dbseek (xfilial ("ZAI") + dtos(M->ZAI_DATA), .F.))
			msgalert ("Valor IGPM já cadastrado para esta data! ")
			_lRet = .F.
		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
return _lRet
