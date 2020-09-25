#include 'protheus.ch'
#include 'parmtype.ch'

user function VAGEST01()
	/*
	+----------------------------------------------------------------------------------------------------------------------+
	| Programa     : VAGEST01
	| Autor        : Marcio Heleno - Procdata
	| Descricao    : Rateio de % na desmontagem de produtos. Chamado via gatilho do D3_COD.                                                                                                      |
	| Data Criacao : 04/10/2016                                                                                            |
	| Data Alt.    | Descricao                                                                                             |
	| 11/06/2015   | Ajuste para custo nao ficar zerado, se nao e encontrado o mesmo em um armazem e procurado nos outros. |
	+----------------------------------------------------------------------------------------------------------------------+ 
	*/
	Local aAreaSB1
	Local aAreaSD3
	Local nPosProd 
	Local nPosRat 
	Local cLocal 
	Local _i	:= 0
	Local nx	:= 0
	//ConOut(Funname())
	
	If Funname() == 'MATA242' // somente na tela do desmonte
		aAreaSD3 := SD3->(GetArea())
		aAreaSB1 := SB1->(GetArea())
		nPosProd := Ascan(aHeader,{|x| AllTrim(x[2])=="D3_COD"})
		nPosRat  := Ascan(aHeader,{|x| AllTrim(x[2])=="D3_RATEIO"})
		nPosQua  := Ascan(aHeader,{|x| AllTrim(x[2])=="D3_QUANT"})
		cLocal   := M->CLOCORIG 
		_ret:= aCols[n][nPosProd]
		
		//busca o total de custo dos produtos informado
		nTotal := 0
		For nx := 1 to Len(aCols)
		  	nCusto := 0
		  	If( ! (aCols[nx][len(aHeader)+1]) )
				DBSelectArea("SB1")
				DbSetOrder(1)
				DbSeek(xFilial("SB1")+aCols[nx][nPosProd]) 
				
				cQuery := " SELECT B2_LOCAL FROM SB2010 B2 "
				cQuery += " WHERE B2.D_E_L_E_T_ = '' "
				cQuery += " AND B2_COD = '" +ALLTRIM(SB1->B1_COD) + "'"
				cQuery += " ORDER BY B2_LOCAL  "
			 	_loc = U_Qry2Array(cQuery)
			 	FOR _i :=1 to len(_loc)  
			 	    if nCusto == 0
			 	    	nCusto := FBuscaCpo("SB2",1,xFilial("SB2")+SB1->B1_COD+_loc[_i,1], "B2_CM1") * aCols[nx][nPosQua]    
				 	endif       
			 	next
				nTotal += nCusto
			EndIf
		Next
		
		//movo loop para ajusta os Rateios
		For nx := 1 to Len(aCols)
			If( ! (aCols[nx][len(aHeader)+1]) )
				DbSelectArea("SB1")
				DbSeek(xFilial("SB1")+aCols[nx][nPosProd])        
				nCusto := 0  
				cQuery := " SELECT B2_LOCAL FROM SB2010 B2 "
				cQuery += " WHERE B2.D_E_L_E_T_ = '' "
				cQuery += " AND B2_COD = '" +ALLTRIM(SB1->B1_COD) + "'"
				cQuery += " ORDER BY B2_LOCAL  "
			 	_loc = U_Qry2Array(cQuery)
			 	FOR _i :=1 to len(_loc)  
			 	    if nCusto == 0
			 	    	nCusto := FBuscaCpo("SB2",1,xFilial("SB2")+SB1->B1_COD+_loc[_i,1], "B2_CM1") * aCols[nx][nPosQua]    
			 	    endif       
			 	next
				
				If nCusto > 0
					aCols[nx][nPosRat] :=  Round((nCusto/nTotal)*100,2)
					If nx == n
						M->D3_RATEIO:=aCols[nx][nPosRat]
					Endif
				ENdif
			EndIf
		Next
		
		RestArea(aAreaSB1)
		RestArea(aAreaSD3)
	Endif
Return ( M->D3_COD )
