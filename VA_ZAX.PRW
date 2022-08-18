// Programa...: VA_ZAX
// Autor......: Catia Cardoso
// Data.......: 31/10/2016
// Descricao..: Rapel - Cliente X Linha Formação Preço X Item
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cadastro
// #Descricao         #Rapel - Cliente X Linha Formação Preço X Item
// #PalavasChave      #rapel
// #TabelasPrincipais #ZAX
// #Modulos           #FAT
//
// Historico de alteracoes:
// 26/06/2017 - Catia   - Criada rotina 076 para validar a permissao de quem altera a rotina
// 27/06/2017 - Catia   - Erro do indice unico resolvido
// 04/11/2019 - Andre   - Adicionado dedo duro para inclusão, alteração e exclusão.
// 26/02/2021 - Sandra  - Valida se Cliente tem Rapel - GLPI 8551. 
// 17/08/2022 - Claudia - Ajuste de logs de eventos. GLPI: 12484
//
// ----------------------------------------------------------------------------------------------------
User Function VA_ZAX()

	if ! u_zzuvl ('076', __cUserId, .T.)
		return
	endif
	
	AxCadastro("ZAX","Rapel Cliente x Linha Formação Preço/Item","U_ZAXDEL()","U_ZAXVAL()")
Return
//
// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function ZAXDEL()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento := NIL
	
	if _lRet
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("ZAX", ZAX->ZAX_CLIENT + ZAX->ZAX_LOJA + ZAX->ZAX_LINHA, zax -> (recno ()),'Excluindo registro.')
		_oEvento:Cliente   = ZAX->ZAX_CLIENT
		_oEvento:LojaCli   = ZAX->ZAX_LOJA 
		_oEvento:CodEven   = "ZAX001"
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
//
// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function ZAXVAL()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _oEvento := NIL

	// Vailida se Cliente tem Rapel
    if _lRet
		if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->ZAX_CLIENT + m->ZAX_LOJA, "A1_VABARAP") = "0"
			u_help ("Não tem Rapel no Cadastro de Cliente!")
			_lRet = .F.
		endif
	endif
	
	// verifica cliente bloqueado
	if _lRet
		if fBuscaCpo ("SA1", 1, xfilial ("SA1") + m->ZAX_CLIENT + m->ZAX_LOJA, "A1_MSBLQL") != "2"
			u_help ("Cliente Bloqueado")
			_lRet = .F.
		endif
	endif
	
	// testa duplicidade
	if _lRet .and. inclui
		ZAX -> (dbsetorder (3))
		if ZAX -> (dbseek (xfilial ("ZAX") + m->ZAX_CLIENT + m->ZAX_LOJA + m->ZAX_LINHA + m->ZAX_ITEM, .F.))
			u_help ("Ja' existe registro de rapel para este cliente/linha e/ou item. Verifique! ")
			_lRet = .F.
		endif
	endif

	// Grava dedo duro
	if _lRet .and. altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("ZAX", m->ZAX_CLIENT + m->ZAX_LOJA + m->ZAX_LINHA, zax -> (recno ()))
		_oEvento:Cliente   = m->ZAX_CLIENT
		_oEvento:LojaCli   = m->ZAX_LOJA 
		_oEvento:CodEven   = "ZAX001"
	endif
	
	if _lRet .and. inclui
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("ZAX", m->ZAX_CLIENT + m->ZAX_LOJA + m->ZAX_LINHA, zax -> (recno ()))
		_oEvento:Cliente   = m->ZAX_CLIENT
		_oEvento:LojaCli   = m->ZAX_LOJA 
		_oEvento:CodEven   = "ZAX001"
	endif
	
	U_ML_SRArea (_aAreaAnt)
return _lRet

