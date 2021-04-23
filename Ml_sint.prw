// Programa...: ML_SINT
// Autor......: Robert Koch
// Data.......: 23/10/2002
// Descricao..: Leitura do arquivo exportado para o Sintegra e remocao de aspas e
//            	 apostrofes. Para isso, importa o arquivo para DBF e limpa linha por linha.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Leitura do arquivo exportado para o Sintegra e remocao de aspas e apostrofes.
// #PalavasChave      #Sintegra
// #TabelasPrincipais 
// #Modulos           
//
// Historico de alteracoes:
// 22/11/2002 - Robert Koch - Incluida verificacao do arquivo a procura de NF de
//                            importacao (reg. 54) onde ha particularidade de ICMS
//                            e passa a chamar o MATA940A internamente.
// 28/11/2002 - Robert Koch - Incluida verificacao de NF imobiliz. de saida tambem.
// 03/12/2002 - Robert Koch - Passa a limpar todas as series de NF ateh nov/2002
// 04/03/2020 - Claudia     - Ajuste de fonte conforme solicitação de versão 12.1.25
// 23/04/2021 - Claudia - Ajustes para versão R25.
//
// ------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function ML_SINT ()
   local _lErroSX1   := .F.
   private _sArq1    := space (70)

   // Executa o padrao e depois faz ajustes no arquivo gerado
   mata940a ()

   // Le o nome do arq. dos param. do MATA940A. Se nao conseguir, solicita ao usuario
   _lErroSX1 := .F.
   if ! sx1 -> (dbseek ("MTA94A" + "03", .F.))
      _lErroSX1 = .T.
   else
      _sArq1 = alltrim (sx1 -> x1_cnt01)
      if ! sx1 -> (dbseek ("MTA94A" + "04", .F.))
         _lErroSX1 = .T.
      else
         _sArq1 += ":\" + alltrim (sx1 -> x1_cnt01) + ".T01"
      endif
   endif

   if _lErroSX1
      @ 200, 001 TO 360, 330 DIALOG oDlgML_SINT TITLE "Nome arquivo"
      @ 015, 010 say "Confirme o nome do arquivo a ser gerado"
      @ 035, 010 say "Nome do arquivo:"
      @ 015, 070 Get _sArq1 Picture "@!" SIZE 95, 10 valid ! empty (_sArq1)
      @ 060, 095 BMPBUTTON TYPE 01 ACTION processa ({|| ML_SINT1 ()})
      ACTIVATE DIALOG oDlgML_SINT CENTERED
   else
      processa ({|| ML_SINT1 ()})
   endif
return
//
// --------------------------------------------------------------------------
Static Function ML_SINT1 ()
   local _aArqTrb    := {}

   _sArq1 = upper (alltrim (_sArq1))
   if ! file (_sArq1)
      msgbox ("Arquivo " + _sArq1 + " nao foi criado ou esta corrompido!")
      return
   endif

   // Cria arq. de trabalho para importacao 
   // incproc ("Processando...")
   // _ArqTrb ("cria", "_trb", {{"linha", "C", 126,  0}}, {})

   procregua (2)
   AADD(aCampos,{"linha", "C", 126,  0})
   U_ArqTrb ("Cria", "_trb", aCampos, {}, @_aArqTrb)

   dbselectarea ("_trb")
   append from (_sArq1) sdf

   // Faz uma copia e depois sobrescreve o arq. original
   copy file (_sArq1) to (strtran (_sArq1, ".T01", ".BAK"))
   _nHdl = fcreate (_sArq1, 0)
   procregua (_trb -> (lastrec ()))
   _trb -> (dbgotop ())
   
   do while ! _trb -> (eof ())
      _sLinha = _trb -> linha
      incproc ("Processando reg. " + left (_sLinha, 2))

      // Se houver mais caracteres a limpar, inserir em linha semelhante as abaixo
      _sLinha = strtran (_sLinha, "'", " ")
      _sLinha = strtran (_sLinha, '"', " ")

      // Limpa series das NF
      do case
         case left (_sLinha, 2) == "50"
            _sLinha = stuff (_sLinha, 43, 3, "   ")
         case left (_sLinha, 2) == "51"
            _sLinha = stuff (_sLinha, 41, 3, "   ")
         case left (_sLinha, 2) == "53"
            _sLinha = stuff (_sLinha, 43, 3, "   ")
         case left (_sLinha, 2) == "54"
            _sLinha = stuff (_sLinha, 19, 3, "   ")
         case left (_sLinha, 2) == "61"
            _sLinha = stuff (_sLinha, 41, 3, "   ")
         case left (_sLinha, 2) == "70"
            _sLinha = stuff (_sLinha, 43, 3, "   ")
         case left (_sLinha, 2) == "71"
            _sLinha = stuff (_sLinha, 43, 3, "   ")
      endcase

      fwrite (_nHdl, _sLinha + chr (13) + chr (10))
      _trb -> (dbskip ())
   enddo
   _ArqTrb ("deleta", "_trb")
   fclose (_nHdl)

   u_arqtrb ("FechaTodos",,,, @_aArqTrb)   
return
//
// --------------------------------------------------------------------------
// Cria ou deleta arquivo de trabalho e seus indices
Static Function _ArqTrb (_sOperacao, _sAlias, _aCampos, _aIndices)
   local  _sArqInd := ""
   local  _nIndice := 0
   static _sArqDBF := ""
   static _aArqInd := {}

   if upper (_sOperacao) == "CRIA"
      // _sArqDBF = criatrab (_aCampos, .T.)
      // _aArqInd = {}
      // dbusearea (.T.,, _sArqDBF, _sAlias, .F., .F.)
      U_ArqTrb ("Cria", _sAlias, _aCampos, {}, @_aArqTrb)

      for _nIndice = 1 to len (_aIndices)
         _sArqInd = criatrab ("", .F.)
         indregua (_sAlias, _sArqInd, _aIndices [_nIndice],,, "Indexando arquivo de trabalho")
         aadd (_aArqInd, _sArqInd)
      next
   endif

   if upper (_sOperacao) == "DELETA"
      (_sAlias) -> (dbclosearea ())
      ferase (_sArqDBF + ".dbf")
      for _nIndice = 1 to len (_aArqInd)
         ferase (_aArqInd [_nIndice] + OrdBagExt ())
      next
   endif
return



