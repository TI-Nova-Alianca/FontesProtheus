#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TOPCONN.CH"
#Include "TbiConn.ch"


// Este programa vai incluir automaticamente, os registros de endereçamento para os produtos que
// forem rastro e localiz como controla.
// 20131211 - m|          // 

User Function MA_GLOTDI()

cPerg    := 'MA_GLOTDI'
_ValidPerg()
If Pergunte(cPerg)
	RptStatus({|| _Imprimir ()})
Endif

Return

//------------------------------------------------------------

Static Function _Imprimir (_lAuto)
aCabDA := {}
aItemDB:= {}
aItem := {}
dDatMov		:= dDataBase
_xgravouSD5:= .F.	         
_X_PAR01 := MV_PAR01
_X_PAR02 := MV_PAR02
_X_PAR03 := MV_PAR03
_X_PAR04 := MV_PAR04
_X_PAR05 := MV_PAR05
_X_PAR06 := MV_PAR06
_X_PAR07 := MV_PAR07
_X_PAR08 := MV_PAR08
//_X_PAR09 := MV_PAR09
Dbselectarea('SB1')
DbSetOrder(1)
DbSeek(xFilial('SB1')+ _X_PAR01)
if found()
	
	While !eof() .and.  (alltrim(SB1->B1_COD) >= alltrim(_X_PAR01))  .AND. (alltrim(SB1->B1_COD) <= alltrim(_X_PAR02))
		if (alltrim(SB1->B1_TIPO) >= alltrim(_X_PAR03))  .AND. (alltrim(SB1->B1_TIPO) <= alltrim(_X_PAR04))
			if(alltrim(SB1->B1_GRUPO) >= alltrim(_X_PAR05)) .AND. (alltrim(SB1->B1_GRUPO) <= alltrim(_X_PAR06)) .and. alltrim(SB1->B1_RASTRO) == 'L' .and. alltrim(SB1->B1_LOCALIZ) == 'S'
				aItem := {}
				_cProd := SB1->B1_COD
				
				//Valida os campos rastro e localiz no cadastro de produto.
				/*
				If (SB1->B1_RASTRO <> 'L') .or. (SB1->B1_LOCALIZ <> 'S')
					//	DbSelectArea('SB1')
					//	DbSkip()
					RecLock('SB1',.f.)
					SB1->B1_RASTRO  :='L'
					SB1->B1_LOCALIZ := 'S'
					MsUnLock()
					
					//	MSGALERt('O produto esta com o campo rastro <> L ou o campo Localiz <> S')
					
					//	Loop
				Endif
				*/
				
				//Verifica se já existe o produto e o local na tabela saldos por lote.
				
				Dbselectarea('SB8')
				DbSetOrder(1)//B8_FILIAL+B8_PRODUTO+B8_LOCAL+DTOS(B8_DTVALID)+B8_LOTECTL+B8_NUMLOTE
				DbSeek(xFilial('SB8') + _cProd + _X_PAR08 )
				If !Found()
					//			dDatMov		:= dDataBase
					//Busca a quantidade nos saldos fisicos
					Dbselectarea('SB2')
					DbSetOrder(1)//B2_FILIAL+B2_COD+B2_LOCAL
					DbSeek(xFilial('SB2') + _cProd + _X_PAR08 )
					If found()              
						if SB2->B2_QATU > 0 
							_nQuant := SB2->B2_QATU - SB2->B2_RESERVA
							aadd(aItem,{"D5_LOTEFOR",'',})
							aadd(aItem,{"D5_PRODUTO",_cProd,})
							aadd(aItem,{"D5_LOCAL",_X_PAR08,})
							aadd(aItem,{"D5_DOC",'',})
							aadd(aItem,{"D5_SERIE",'',})
							aadd(aItem,{"D5_DATA",dDatMov,})
							aadd(aItem,{"D5_QUANT",_nQuant ,})
							aadd(aItem,{"D5_LOTECTL",_X_PAR07,})
							aadd(aItem,{"D5_DTVALID",dDatMov,})
							
							//inclusao automatica com a rotina execauto
							lMsHelpAuto := .F.  // se .t. direciona as mensagens de help
							lMsErroAuto := .F.  // necessario a criacao
							BEGIN TRANSACTION
							MSExecAuto({|x,y| mata390(x,y)},aItem,3)
							END TRANSACTION
							
							If lMsErroAuto
								if !_lAuto
									Mostraerro()
							  //	else      
						//		   _xgravouSD5:= .T.	
								endif
							endif
						else
					//		msgalert('Aquantidade deste produto esta Zerada. Produto: ' + _cprod )
						endif
					else
					//	msgalert('O produto com este Local Não existe na tabela SB2(saldos por Almoxarifado. Produto: ' + _cprod )
					endif
				else
			//		msgalert('O produto com este armazem já existe na tabela SB8 (Saldos por Lote. Produto: ' + _cprod)
				endif
				//-------------------------- 
				
				/*
				if !empty(_X_PAR09)// .AND. _xgravouSD5
				   _xgravouSD5:= .F.	
					
					dbSelectArea("SD5")
					dbSetOrder(2)//D5_FILIAL+D5_PRODUTO+D5_LOCAL+D5_LOTECTL+D5_NUMLOTE+D5_NUMSEQ
					if DbSeek(xFilial('SD5') + _cProd + _X_PAR08 + _X_PAR07)
						
						
						dbSelectArea("SDA")
						dbSetOrder(1)//DA_FILIAL+DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA
						DbSeek(xFilial('SDA') + SD5->D5_PRODUTO + SD5->D5_LOCAL + SD5->D5_NUMSEQ  )
						
					  If SDA->DA_SALDO > 0
						aCAB  :={{"DA_PRODUTO"    , _cProd    , nil},;
						{"DA_LOCAL"   , SDA->DA_LOCAL    , nil} ,;
						{"DA_NUMSEQ"  , SDA->DA_NUMSEQ   , nil} ,;
						{"DA_DOC"     , SDA->DA_DOC      , nil} ,;
						{"DA_SERIE"   , SDA->DA_SERIE    , nil} }
						
						
						aITENS:={{{"DB_ITEM"  , "001"    , nil},;
						{"DB_LOCALIZ" , _X_PAR09         , nil},;
						{"DB_QUANT"   , SDA->DA_QTDORI   , nil},;
						{"DB_NUMSEQ"  , SDA->DA_NUMSEQ   , nil},; 
						{"DB_LOCALIZ"  , SDA->DA_NUMSEQ   , nil},; 						
						{"DB_DATA"    , dDATABASE        , nil}}}
						
						lMsErroAuto := .F.
						MSExecAuto({|x,y,z| mata265(x,y,z)},aCab,aItens,3) //Distribui
						
						
						If lMsErroAuto
							if !_lAuto
								Mostraerro()
							endif
						endif
					  ENDIF	
					endif
				endif
                */
			Endif
		Endif
		//-----------------
		Dbselectarea('SB1')
		DbSkip()

	Enddo
else
	msgalert('Produto não encontrado.')
endif

return()

//------------------------------------------------------------

Static Function _ValidPerg ()
local _aRegsPerg := {}

//                     PERGUNT                          TIPO TAM DEC VALID F3     Opcoes                        Help
aadd (_aRegsPerg, {01, "Produto de                   ?", "C", 30, 0,  "",   "SB1", {},                           ""})
aadd (_aRegsPerg, {02, "Produto ate                  ?", "C", 30, 0,  "",   "SB1", {},                           ""})
aadd (_aRegsPerg, {03, "Tipo de                   	 ?", "C", 02, 0,  "",   "02 ", {},                           ""})
aadd (_aRegsPerg, {04, "Tipo ate                     ?", "C", 02, 0,  "",   "02 ", {},                           ""})
aadd (_aRegsPerg, {05, "Grupo de                   	 ?", "C", 04, 0,  "",   "SBM", {},                           ""})
aadd (_aRegsPerg, {06, "Grupo ate                    ?", "C", 04, 0,  "",   "SBM", {},                           ""})
aadd (_aRegsPerg, {07, "Lote                         ?", "C", 10, 0,  "",   "   ", {},                           ""})
aadd (_aRegsPerg, {08, "Local                        ?", "C", 02, 0,  "",   "   ", {},                           ""})
//aadd (_aRegsPerg, {09, "Endereco                     ?", "C", 10, 0,  "",   "   ", {},                           ""})

U_ValPerg (cPerg, _aRegsPerg)
Return
