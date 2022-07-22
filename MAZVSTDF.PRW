
// Programa..: MAZVSTDF
// Autor.....: Claudia Lionço
// Data......: 08/11/2021
// Descricao.: Tratamento para notas com Difal ou ICMS ST para estado do Ceara
//
// Tags de localização
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Tratamento para notas com Difal ou ICMS ST para estado do Ceara
// #PalavasChave      #PE #NF #notadesaida #Difal_CE
// #TabelasPrincipais #SF2 #SD2 
// #Modulos           #faturamento #FAT
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
  
User Function MAZVSTDF()  
      Local cEstado   := Paramixb[1] // Estado de Destino
      Local nIcmsSt   := Paramixb[2] // Valor ICMS ST
      Local nDifal    := Paramixb[3] // Valor de Difal
      Local aItem     := Paramixb[4] // Quantidade de Itens
      Local nFecopDf  := Paramixb[5] // Valor Fecop Dif
      Local nFecopSt  := Paramixb[6] // Valor Fecop St
      Local nX        := 0
      //Local nTeste    := 0
 
      dbSelectArea('SD2')
      SD2->(dbSetOrder(3))
      
      If cEstado == "CE"
            //Zera Valor de Difal
            If nDifal > 0 .And. nDifal < 1
                  MafisAlt("NF_PPDIFAL",.F.)
                  For nX := 1 to len(aItem)         
                        MafisAlt("IT_DIFAL",0,nX)
                        SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))
                        MaFisWrite(2,"SD2",nX)
                  Next
                  MaFisWrite(2,"SF2")
            Endif
                  
            If nIcmsSt > 0 .And. nIcmsSt < 1
                  MafisAlt("NF_BASESOL",0)
                  MaFisWrite(2,"SF2")
                  For nX := 1 to len(aItem)
                        SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))
                        MaFisWrite(2,"SD2",nX)
                  Next
            Endif
            
            If nFecopDf > 0 .And. nFecopDf < 1
                  MaFisAlt("NF_VFCPDIF", 0)
                  MaFisWrite(2,"SF2")
                  For nX := 1 to len(aItem)
                        MafisAlt("IT_VFCPDIF", 0, nX)
                        SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))
                        MaFisWrite(2,"SD2",nX)         
                  Next
            Endif
            
            If nFecopSt > 0 .And. nFecopSt < 1
                  MaFisAlt("NF_VFECPST", 0)
                  MaFisWrite(2,"SF2")
                  For nX := 1 to len(aItem)
                        MafisAlt("IT_VFECPST", 0, nX)
                        SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))
                        MaFisWrite(2,"SD2",nX)           
                  Next
            Endif        
      Endif      
Return
