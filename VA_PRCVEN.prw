#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

// Atualização: 
// 28/03/2014 - Função para retorno do preço de tabela máximo - DA1
// 02/02/2015 - novas regras por canal
// 02/02/2015 - tirado o campo canal da chave 9 da DA1
// 28/01/2017 - Catia  - Composicao do preço de venda conforme percentuais do cliente - igual ao Mercanet
// 10/07/2017 - Robert - Desabilitada mensagem "valor utilizado da lista de precos por canal".
 
User Function VA_PRCVEN(cliente,loja,produto,canal,estado,par)
local prcvenda:=0
LOCAL tabela:=''

DbSelectArea("DA1")
DbSetOrder(7)
DbSeek(xFilial()+'998'+cliente+loja+produto)
// Se está na tabela produtoXcliente usa preço de lá
If Found()
	if par==1 .OR. par==2
		prcvenda	:=DA1->DA1_PRCVEN
	elseif par==3 .AND.GDFIELDGET("C6_VAPRCVE")==0
		prcvenda	:=DA1->DA1_PRCVEN
	elseif par==3 .AND.GDFIELDGET("C6_VAPRCVE")<>0
		prcvenda:=GDFIELDGET("C6_VAPRCVE")
	endif
	
	//seta a ultima nota e seu valor nos itens de tabela 998
	GDFieldPut("C6_DOC",DA1->DA1_DOC)
	GDFieldPut("C6_SDOC",DA1->DA1_SERIE)
	GDFieldPut("C6_EMISS",DA1->DA1_EMISS)
	GDFieldPut("C6_VLRNF",DA1->DA1_VALNF)

Else
	// regra de CANAL x UF
	_wcentro_oeste := 'DF/MT/MS/GO/ES'
	_wnorte_ne     := 'AC/AP/AM/PA/RO/RR/TO/AL/BA/CE/MA/PB/PE/PI/RN/SE'
	_woutros       := 'RS/SP/MG/RJ'
	_wscpr		   := 'SC/PR'
	
	if canal=='01'
		if estado $ _wcentro_oeste
			tabela:='720'
		elseif estado $ _wnorte_ne
			tabela:='721'
		elseif estado $ _woutros
			tabela:='722'
		elseif estado $_wscpr
			tabela:='723'
		endif
	 
	elseif canal=='02' .or. canal=='03' .or. canal=='04'
		if estado $ _wcentro_oeste
			tabela:='724'
		elseif estado $ _wnorte_ne
			tabela:='725'
		elseif estado $ _woutros
			tabela:='726'
		elseif estado $_wscpr
			tabela:='727'
		endif
	
	elseif canal=='06'
		if estado $ _wcentro_oeste
			tabela:='736'
		elseif estado $ _wnorte_ne
			tabela:='740'
		elseif estado $ _woutros
			tabela:='738'
		elseif estado $_wscpr
			tabela:='739'
		endif
			
	endif
	
	DbSelectArea("DA1")
	DbSetOrder(9)
	//DbSeek(xFilial("DA1")+tabela+canal+estado+produto) //DA1_FILIAL+DA1_CODTAB+DA1_CANAL+DA1_ESTADO+DA1_CODPRO                                                                                                           
	DbSeek(xFilial("DA1")+tabela+ '  '+ estado+produto) //DA1_FILIAL+DA1_CODTAB+DA1_CANAL+DA1_ESTADO+DA1_CODPRO
	
	//seta em branco a ultima nota
	GDFieldPut("C6_DOC",'')
	GDFieldPut("C6_SDOC",'')
	GDFieldPut("C6_VLRNF",0)
	
	If Found()
		if par==1
			if IsInCallStack ("U_EDIM1")
				u_help ("Preco unitario = 1 centavo, apenas para nao bloquear a importacao do pedido")
				prcvenda = 0.01
			else
				if tabela = '990'
					//u_help ("Preço de Venda composto, conforme parametros do cliente.")
					prcvenda:= U_CompPrc (cliente, produto, par)
				else						
					//u_help ("Valor utilizado da Lista de Preços por Canal.")
					prcvenda:= DA1->DA1_PRCVEN
				endif						
			endif
		Elseif par==2
			if tabela = '990'
				prcvenda:= U_CompPrc (cliente, produto, par)
			else						
				prcvenda:= DA1->DA1_PRCVEN
			endif				
		ELSEIF par==3  .AND. GDFIELDGET("C6_VAPRCVE")==0
			if tabela = '990'
				prcvenda:= U_CompPrc (cliente, produto, par)				
			else
				prcvenda:= DA1->DA1_PRCVEN
			endif				
		elseif par==3 .AND.GDFIELDGET("C6_VAPRCVE")<>0
			prcvenda:=GDFIELDGET("C6_VAPRCVE")
		endif
	Endif
Endif

Return prcvenda
