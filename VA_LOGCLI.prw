// Programa...: VA_LOGCLI
// Data.......: 13/11/2015
// Descricao..: Logistica - Observaçoes de Clientes
//
// Historico de alteracoes:
// 22/07/2020 - Robert  - Verificacao de acesso: passa a validar acesso 111 e nao mais 030.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Atualizacao de observacoes logisticas no cadastro de clientes.
// #PalavasChave      #observacoes #logisticas #clientes
// #TabelasPrincipais #SA1
// #Modulos           #FAT #OMS

#include 'totvs.ch'

User Function VA_LOGCLI()
	
//	local _aCores  := ""
//	Local cArqTRB  := ""
//	Local cInd1    := ""
//	Local nI       := 0
//	Local aStruct  := {}
	Local aHead := {}
	
//	if ! u_zzuvl ('030', __cUserId, .T.)
	if ! u_zzuvl ('111', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina.")
		return
	endif
	
	Private aRotina   := {}
	private cCadastro := "Observações de Clientes"
	private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
	
	aadd (aRotina, {"&Visualiza Cadastro"    ,"U_LOG_VISUAL"  , 0 ,1})	
	aadd (aRotina, {"&Separação"             ,"U_LOG_SEP"  , 0, 2})
	aadd (aRotina, {"&Entrega"               ,"U_LOG_ENT"  , 0, 2})
		
	Private cDelFunc := ".T."
		
	dbSelectArea("SA1")
	dbSetOrder(1)
		    
	mBrowse(,,,,"SA1",aHead,,,,,)
	SA1->(dbCloseArea())
		
Return

// observacoes de separacao
user function LOG_SEP()
	_sTexto = ''
	_sTextoOld = ''
	if ! empty (SA1->A1_LCODSEP)
		_sTextoOld = MSMM (SA1->A1_LCODSEP,,,,3)
		_sTexto = _sTextoOld
	endif
	_sTexto = U_ShowMemo (_sTexto, 'Observação Separação - Cliente: '+ SA1->A1_NOME )
	if empty (_sTexto) .and. ! empty (_sTextoOld)
		// Exclui.
		MSMM (SA1->A1_LCODSEP,,,, 2,,, "SA1", "A1_LCODSEP")
	else
		// Inclui / altera.
		MSMM (,,, _sTexto, 1,,, "SA1", "A1_LCODSEP")
	endif
	
return

// observacoes de entrega	
user function LOG_ENT()
	_sTexto = ''
	_sTextoOld = ''
	if ! empty (SA1->A1_LCODENT)
		_sTextoOld = MSMM (SA1->A1_LCODENT,,,,3)
		_sTexto = _sTextoOld
	endif
	_sTexto = U_ShowMemo (_sTexto, 'Observação Entrega - Cliente: '+ SA1->A1_NOME)
	
	if empty(_sTexto) .and. ! empty (_sTextoOld)
		// Exclui.
		MSMM (SA1->A1_LCODENT,,,, 2,,, "SA1", "A1_LCODENT")
	else
		// Inclui / altera.
		MSMM (,,, _sTexto, 1,,, "SA1", "A1_LCODENT")
	endif
return

// chama função visualizar
user function LOG_VISUAL()
	A030Visual('SA1',1,2)
return	
