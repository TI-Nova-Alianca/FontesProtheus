// Programa...: M440SC9I
// Autor......: Jeferson Rech
// Data.......: 10/2005
// Descricao..: Atualiza Arquivo de Pedidos Liberados (SC9)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Atualiza Arquivo de Pedidos Liberados (SC9)
// #PalavasChave      #ponto_de_entrada #pedidos_liberados
// #TabelasPrincipais #SC6 #SC9 #SC5
// #Modulos           #FAT #EST
//
// Historico de alteracoes:
// 17/09/2009 - Robert - Gravacao de evento para posterior consulta.
// 02/01/2012 - Robert - Funcao _NCLIFOR passada de 'user' para 'static'.
// 30/08/2019 - Robert - Melhorada gravacao de log de evento (passa a gravar apenas um por pedido).
// 30/03/2020 - Robert - Comentariadas linhas de gravacao de logs.
// 17/02/2021 - Claudia - Incluida as tags de pesquisas
//
// ------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function M440SC9I()
	local _aAreaAnt := U_ML_SRArea ()
	dbSelectArea("SA1")
	dbSetOrder(1)
	MsSeek(xFilial("SA1")+SC6->C6_CLI+SC6->C6_LOJA)
	
	IF GETMV("ML_BLQBON") == "S"
		If SF4->F4_TOCON == "04"
			SC9->C9_BLCRED  := "01"
		Endif
		
		If SC9->(FieldPos("C9_VABONIF")) > 0    // Teste para nao dar erro demais empresas
			SC9->C9_VABONIF := IIf(SF4->F4_TOCON == "04","S","N")
		Endif
	ENDIF
	IF CEMPANT== "01" .AND. CFILANT == "01"
		// Se NAO for Bonificacao e Nem o Produto Generico
		If SF4->F4_MARGEM <> "3" .And. Alltrim(SC9->C9_PRODUTO) <> "9999"
			If !EMPTY(SC6->C6_BLQCRED)
				If SC9->(FieldPos("C9_BLVEND")) > 0    // Teste para nao dar erro demais empresas
					SC9->C9_BLVEND  := IIf(!EMPTY(SC6->C6_BLQCRED),"S","N")
					SC9->C9_BLCRED  := "01"
				Endif
			Endif
		Endif
	ENDIF
	
	SC9->C9_NREDUZ  := _NCLIFOR(SC5->C5_TIPO,2,SC5->C5_CLIENTE,SC5->C5_LOJACLI)[2]

	// Grava evento
	_GrvEvento ()

	U_ML_SRArea (_aAreaAnt)
Return(.T.)
//
// --------------------------------------------------------------------------
// Funcao que Retorna o Nome / N. Fantasia do Cliente                      
// 1 Parametro := N/B/C/D/etc                                              
// 2 Parametro := 1 Entradas / 2 - Saidas                                  
// 3 Parametro := Cod. do Cliente / Fornecedor                             
// 4 Parametro := Loja. do Cliente / Fornecedor                            
//
static Function _NCLIFOR(_xTIPO,nTipoMov,_xCOD,_xLOJA)
	Local _aArea    := GetArea()
	Local _aAreaSA1 := SA1->(GetArea())
	Local _aAreaSA2 := SA2->(GetArea())
	Local _aRetx    := Array(2)
	
	_aRetx[1] := ""
	_aRetx[2] := ""
	
	If nTipoMov>2
		MsgInfo("Tipo de Movimento Invalido: "+Str(nTipoMov),"Atencao!!! - U__NCLIFOR")
		RestArea(_aArea)
		Return(_aRetx)
	Endif
	
	If nTipoMov==1
		Iif(_xTIPO$"DB",DbSelectArea("SA1"),DbSelectArea("SA2"))
	Else
		Iif(_xTIPO$"DB",DbSelectArea("SA2"),DbSelectArea("SA1"))
	Endif
	DbSetOrder(1)
	DbSeek(xFilial()+_xCOD+_xLOJA)
	If !Found()
		MsgInfo("Nao Localizado codigo: "+_xCOD+_xLOJA,"Atencao!!! - U__NCLIFOR")
		RestArea(_aArea)
		Return(_aRetx)
	Endif
	If nTipoMov==1
		_xNOMEX        := If( _xTIPO$"DB",SA1->A1_NOME   ,SA2->A2_NOME  )
		//	_xNREDUZX      := If( _xTIPO$"DB",SA1->A1_NREDUZ ,SA2->A2_NREDUZ) //ADELAR 100807 A PEDIDO DA JUCANIA
		_xNREDUZX      := If( _xTIPO$"DB",SA1->A1_NOME ,SA2->A2_NOME)
		
	Else
		_xNOMEX        := If( _xTIPO$"DB",SA2->A2_NOME   ,SA1->A1_NOME  )
		//	_xNREDUZX      := If( _xTIPO$"DB",SA2->A2_NREDUZ ,SA1->A1_NREDUZ)  //ADELAR 100807 A PEDIDO DA JUCANIA
		_xNREDUZX      := If( _xTIPO$"DB",SA2->A2_NOME ,SA1->A1_NOME)
		
	Endif
	
	_aRetx[1] := _xNOMEX
	_aRetx[2] := _xNREDUZX
	
	// Retorno do Array                                                        
	// [1] := Nome do Cliente / Fornecedor                                     
	// [2] := Nome Fantasia do Cliente / Fornecedor      

	RestArea(_aAreaSA2)
	RestArea(_aAreaSA1)
	RestArea(_aArea)
Return(_aRetx)
//
// --------------------------------------------------------------------------
// Grava evento
static function _GrvEvento ()
	local _oEvento := NIL
	local _oSQL    := NIL

	// Grava evento somente no primeiro item do pedido.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT MIN (C6_ITEM)"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC6")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=  " AND C6_FILIAL    = '" + sc9 -> c9_filial + "'"
	_oSQL:_sQuery +=  " AND C6_NUM       = '" + sc9 -> c9_pedido + "'"
	_oSQL:Log ()
	//u_log ('comparando >>' + sc9 -> c9_item + '<< com >>' + _oSQL:RetQry (1, .F.) + '<<')
	if alltrim (sc9 -> c9_item) == alltrim (_oSQL:RetQry (1, .F.))
		//u_log ('posicionando SC5')
		sc5 -> (dbsetorder (1))  // C5_FILIAL+C5_NUM
		if ! sc5 -> (dbseek (xfilial ("SC5") + sc9 -> c9_pedido, .F.))
			//u_log ('Nao achei SC5')
			U_AvisaTI ("Nao encontrei SC5 na rotina de gravacao de evento de liberacao do pedido")
		else
			//u_log ('gerando evento')
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SC9001"
			_oEvento:Texto    := "Liber.coml.pedido. Informacoes principais:" + chr (10) + chr (13)
			_oEvento:Texto    +=  "Banco=" + sc5 -> c5_banco + chr (10) + chr (13)
			_oEvento:Texto    +=  "Cond.pag=" + sc5 -> c5_condpag + chr (10) + chr (13)
			_oEvento:Texto    +=  "Vl.tot=" + cvaltochar (sc5 -> c5_vaVlFat) + chr (10) + chr (13)
			_oEvento:Cliente   = sc9 -> c9_cliente
			_oEvento:LojaCli   = sc9 -> c9_loja
			_oEvento:PedVenda  = sc9 -> c9_pedido
			_oEvento:Grava ()
		endif
	endif
return
