#include 'protheus.ch'

#include 'parmtype.ch'


user function MAZVSTDF()


Local cEstado := Paramixb[1] // Estado de Destino

Local nIcmsSt := Paramixb[2] // Valor ICMS ST

Local nDifal  := Paramixb[3] // Valor de Difal

Local aItem   := Paramixb[4] // Quantidade de Itens

Local nX            := 0

Local nTotAnt := 0

      

dbSelectArea('SD2')

SD2->(dbSetOrder(3))


If cEstado == "CE"

       //Zera Valor de Difal

       If nDifal > 0 .And. nDifal < 1

             MafisAlt("NF_PPDIFAL",.F.)

             For nX := 1 to len(aItem)              

                    MafisAlt("IT_DIFAL",0,nX)

                    SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))

 nTotAnt := SD2->D2_TOTAL // Armazenar o valor de D2_TOTAL para que a funcao MaFisWrite nao sobreponha os valores gravados pelos tratamentos especificos da geracao de NF (MATA461)

                    MaFisWrite(2,"SD2",nX)

 SD2->D2_TOTAL := nTotAnt // Restaurando valor do campo p/ que nao haja divergencias quando o ponto de entrada for executado.

             Next

             MaFisWrite(2,"SF2")

       Endif

      

       If nIcmsSt > 0 .And. nIcmsSt < 1

             MafisAlt("NF_BASESOL",0)

             MaFisWrite(2,"SF2")

             For nX := 1 to len(aItem)

                    SD2->(MsSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA+(aItem[nX][16])+(aItem[nX][73])))

 nTotAnt := SD2->D2_TOTAL // Armazenar o valor de D2_TOTAL para que a funcao MaFisWrite nao sobreponha os valores gravados pelos tratamentos especificos da geracao de NF (MATA461)

                    MaFisWrite(2,"SD2",nX)

 SD2->D2_TOTAL := nTotAnt // Restaurando valor do campo p/ que nao haja divergencias quando o ponto de entrada for executado.

             Next

       Endif

Endif

      

Return
