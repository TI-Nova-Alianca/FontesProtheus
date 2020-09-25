// Programa...: ML_Comp2
// Autor......: Robert Koch
// Data.......: 19/02/2004
// Cliente....: Generico
// Descricao..: Funcao recursiva para ler a estrutura do produto (SG1).

// Historico de alteracoes:
// 06/04/2004 - Robert  - Nao considerada a quantidade base da estrutura
// 27/05/2005 - Robert  - Na considerava o percentual de perda
//                      - Inclusao de nivel e caminho, melhorias gerais.
// 16/06/2005 - Robert  - Incluida possibilidade de verificar estoque.
// 16/05/2006 - Robert  - Incluida possibilidade de verificar operacoes de cada subconjunto.
// 24/05/2006 - Robert  - Criada possibilidade de incluir o item pai no cabecalho da lista.
// 15/08/2006 - Robert  - Ajuste no calculo do tempo padrao da operacao (estava multiplicando pelo setup!!!)
// 03/10/2007 - Robert  - Novo parametro para selecionar leitura ou nao das operacoes (SG2).
// 27/08/2018 - Robert  - Nova coluna com revisao atual da estrutura.
// 08/04/2020 - Claudia - Incluido o filtro por revisão da estrutura, confome GLPI: 7599
// 06/05/2020 - Cláudia - Incluida a validação se _sFilSG1   == "" receber .T., 
//                        para a utilização da rotina na validação de desmontagem
// 02/06/2020 - Cláudia - Na chamada recursiva do componente, adicionada a revisão atual do proprio componente
//
// -----------------------------------------------------------------------------------------------------
#include "rwmake.ch"

// -----------------------------------------------------------------------------------------------------
// Parametros:
// 1 - cod. produto cuja estrutura deve ser lida
// 2 - Quantidade do produto, Se nao informada, assume 1
// 3 - Expressao para filtro do SG1. Assumir que SB1 e SG1 estarao posicionados no COMPONENTE.
// 4 - Data para teste de validade dos componentes. Se nao informado, assume a data base do sistema.
// 5 - Indica se deve considerar estoque atual como disponivel.
// 6 - Indica se deve considerar estoque em poder de terceiros como disponivel.
// 7 - Indica se deve considerar saldo empenhado.
// 8 - Indica se deve considerar saldo em pedidos.
// 9 - Indica se deve ler dias de producao / compra (campo B1_LE).
// 10 - Se informado, indica qual roteiro de operacoes deve ser lido, para cada subconjunto.
// 11 - Indica se deve ser considerado setup no tempo da operacao.
// 12 - Expressao para filtro do SG2. Assumir que o SG2 estarah posicionados na operacao.
// 13 - Indica se deve incluir o pai no inicio da lista de componentes.
// 14 - Indica se deve ler operacoes (SG2).
// 15 - Revisão da estrutura selecionada pelo usuário
// 16 - Lista com a estrutura. Nao informar, pois eh de uso interno da funcao para chamada recursiva.
//
// Retorno: array com a estrutura nivel a nivel, sendo que cada linha tem os seguintes dados:
// 1 - Nivel
// 2 - Codigo do componente
// 3 - Quantidade do componente neste nivel
// 4 - Quantidade acumulada do componente (depende da quantidade do pai, do campo G1_FIVAR e do estoque.)
// 5 - Saldo em estoque
// 6 - Saldo em poder de terceiros
// 7 - Caminho de itens percorridos para chegar ateh o componente atual (codigos concatenados em uma string)
// 8 - Numero de dias de producao, acumulado pela estrutura.
// 8 - Saldo empenhado
// 9 - Saldo em pedidos
// 10 - Array com as operacoes
//
// -------------------------------------------------------------------------------------------------------------
User Function ML_Comp2 (_sItem, _nQtid, _sFilSG1, _dDtValid, _lSaldoAtu, _lSaldoTer, _lSaldoEmp, _lSaldoPre, _lDias, _sRoteiro, _lSetup, _sFilSG2, _lInclPai, _lLerSG2, _sRevisao, _aLista)
   local _nRegSG1   := 0  // Por que a chamada recursiva desposiciona o SG1
   local _nNivel    := 0
   local _sCaminho  := ""
   local _nQtBase   := 1
   local _nQtFilho  := 0
   local _nQtAcum   := 0
   local _nDiasPai  := 0
   local _nDias     := 0
   local _aRot      := {}
   local _nLotePad  := 0
   local _nTempo    := 0
   local _nSaldoAtu := 0
   local _nSaldoTer := 0
   local _nSaldoEmp := 0
   local _nSaldoPre := 0
   local _sRevAtu   := ""

   // Busca dados na lista jah existente, se houver, Senao, pega defaults.
   _nNivel    := iif (_aLista    == NIL, 1,         _aLista [len (_aLista), 1] + 1)
   _sCaminho  := iif (_aLista    == NIL, _sItem,    _aLista [len (_aLista), 7] + "," + _sItem)
   _nDiasPai  := iif (_aLista    == NIL, 0,         _aLista [len (_aLista), 8])
   _aLista    := iif (_aLista    == NIL, {},        _aLista)  // Se for a primeira chamada da funcao, crio a array onde vou guardar os valores.
   _dDtValid  := iif (_dDtValid  == NIL, dDataBase, _dDtValid)
   _sFilSG1   := iif (_sFilSG1   == NIL, ".T.",     _sFilSG1)
   _lSaldoAtu := iif (_lSaldoAtu == NIL, .F.,       _lSaldoAtu)
   _lSaldoTer := iif (_lSaldoTer == NIL, .F.,       _lSaldoTer)
   _lSaldoEmp := iif (_lSaldoEmp == NIL, .F.,       _lSaldoEmp)
   _lSaldoPre := iif (_lSaldoPre == NIL, .F.,       _lSaldoPre)
   _lDias     := iif (_lDias     == NIL, .F.,       _lDias)
   _sRoteiro  := iif (_sRoteiro  == NIL, "",        _sRoteiro)
   _lSetup    := iif (_lSetup    == NIL, .F.,       _lSetup)
   _lInclPai  := iif (_lInclPai  == NIL, .F.,       _lInclPai)
   _lLerSG2   := iif (_lLerSG2   == NIL, .F.,       _lLerSG2)

   // Busca a quantidade base na estrutura para proporcionalizar para os filhos
   sb1 -> (dbsetorder (1))
   _nQtBase = 1
   if sb1 -> (dbseek (xfilial ("SB1") + _sItem, .T.)) .and. sb1 -> b1_qb != 0
      _nQtBase = sb1 -> b1_qb
      _sRevAtu = _sRevisao//sb1 -> b1_revatu
      if _aLista == NIL
         _nDiasPai = _CalcDias ()
      endif
   endif

   // Se o pai deve ser incluido na lista, preciso pegar seus dados.
   if _lInclPai

      // Le roteiro de operacoes do pai
      _aRot := iif (_lLerSG2, _LeRoteiro (_sItem, _sRoteiro, _sFilSG2, _lSetup, _nQtid), {})

      // Le saldos do pai
      if _lSaldoAtu .or. _lSaldoTer .or. _lSaldoEmp .or. _lSaldoPre
         _LeSaldos (_sItem, @_nSaldoAtu, @_nSaldoTer, @_nSaldoEmp, @_nSaldoPre)
      endif

      // Inclui item pai na lista
      aadd (_aLista, {0, ;              // Nivel do componente na estrutura.
                      _sItem, ;         // Componente (filho)
                      _nQtid, ;         // Quantidade do componente neste nivel da estrutura
                      _nQtid, ;         // Quantidade acumulada do componente (depende da quantidade do pai)
                      _nSaldoAtu, ;     // Saldo atual (caso tenha sido considerado)
                      _nSaldoTer, ;     // Saldo poder 3os. (caso tenha sido considerado)
                      "", ;             // Caminho de itens percorridos para chegar ao atual, em formato string.
                      0, ;              // Dias acumulados para a producao deste item.
                      _nSaldoEmp, ;     // Saldo empenhos (caso tenha sido considerado)
                      _nSaldoPre, ;     // Saldo previsto PC/SC (caso tenha sido considerado)
                      aclone (_aRot), ; // Array com o roteiro de operacoes deste filho
                      _sRevisao})      	// Revisao atual da estrutura
                      //_sRevAtu})        // Revisao atual da estrutura
   endif

   // Acrescenta os filhos encontrados, mas antes verifica a estrutura de cada um.
   // Se nao tem mais filhos, retorna a lista como estah.
   sg1 -> (dbsetorder (1))  // g1_filial+g1_cod+g1_comp+g1_trt
   sg1 -> (dbseek (xfilial ("SG1") + _sItem, .T.))
   do while ! sg1 -> (eof ()) .and. sg1 -> g1_filial == xfilial ("SG1") .and. sg1 -> g1_cod    == _sItem
   		if sg1 -> g1_ini <= _dDtValid .and. sg1 -> g1_fim >= _dDtValid
	      	If sg1 -> g1_revini <= _sRevisao .and. sg1 -> g1_revfim >= _sRevisao  
	         
	         // Posiciona SB1 no componente para validar filtro.
	         if sb1 -> (dbseek (xfilial ("SB1") + sg1 -> g1_comp, .F.)) .and. &(_sFilSG1)
	
	            _sRevAtu = sb1 -> b1_revatu
	
	            // Busca saldos do componente.
	            if _lSaldoAtu .or. _lSaldoTer .or. _lSaldoEmp .or. _lSaldoPre
	               _LeSaldos (sg1 -> g1_comp, @_nSaldoAtu, @_nSaldoTer, @_nSaldoEmp, @_nSaldoPre, _lSaldoAtu, _lSaldoTer, _lSaldoEmp, _lSaldoPre)
	            endif
	
	            // Quantidade a usar do filho conforme quantidade base da estrutura
	            _nQtFilho = sg1 -> g1_quant / _nQtBase
	         
	            // Soma percentual de perdas
	            _nQtFilho += _nQtFilho * (sg1 -> g1_perda / 100)
	         
	            // Quantidade acumulada conforma quantidade do pai
	            _nQtAcum = _nQtFilho * iif (sg1 -> g1_fixvar == "V", _nQtid, 1)
	         
	            // Desconta saldos em estoque, terceiros, etc.
	            _nQtAcum -= min (_nQtAcum, (_nSaldoAtu + _nSaldoTer - _nSaldoEmp + _nSaldoPre))
	
	            // Calcula dias necessarios para entrega, acumulados com os dias do pai.
	            if _lDias
	               _nDias = _nDiasPai + _CalcDias ()
	            endif
	
	            // Le roteiro de operacoes do componente
	            _aRot := iif (_lLerSG2, _LeRoteiro (sg1 -> g1_comp, _sRoteiro, _sFilSG2, _lSetup, _nQtAcum), {})
	
	            // Adiciona o filho `a lista.
	            aadd (_aLista, {_nNivel, ;         // Nivel do componente na estrutura.
	                            sg1 -> g1_comp, ;  // Componente (filho)
	                            _nQtFilho, ;       // Quantidade do componente neste nivel da estrutura
	                            _nQtAcum, ;        // Quantidade acumulada do componente (depende da quantidade do pai)
	                            _nSaldoAtu, ;      // Saldo atual (caso tenha sido considerado)
	                            _nSaldoTer, ;      // Saldo poder 3os. (caso tenha sido considerado)
	                            _sCaminho, ;       // Caminho de itens percorridos para chegar ao atual, em formato string.
	                            _nDias, ;          // Dias acumulados para a producao deste item.
	                            _nSaldoEmp, ;      // Saldo empenhos (caso tenha sido considerado)
	                            _nSaldoPre, ;      // Saldo previsto PC/SC (caso tenha sido considerado)
	                            aclone (_aRot), ;  // Array com o roteiro de operacoes deste filho
	                            _sRevAtu})         // Revisao atual da estrutura
	
	            // Se ainda tem quantidade acumulada, verifica recursivamente a estrutura do componente.
	            if _nQtAcum != 0
	               _nRegSG1 = sg1 -> (recno ())       // Preciso guardar, pois a chamada recursiva desposiciona
	               //_aLista := U_ML_Comp2 (sg1 -> g1_comp, _nQtAcum, _sFilSG1, _dDtValid, _lSaldoAtu, _lSaldoTer, _lSaldoEmp, _lSaldoPre, _lDias, _sRoteiro, _lSetup, _sFilSG2, .F., _lLerSG2, _sRevisao, _aLista)  // Chamada recursiva para ler a estrutura do componente atual
	               _aLista := U_ML_Comp2 (sg1 -> g1_comp, _nQtAcum, _sFilSG1, _dDtValid, _lSaldoAtu, _lSaldoTer, _lSaldoEmp, _lSaldoPre, _lDias, _sRoteiro, _lSetup, _sFilSG2, .F., _lLerSG2, _sRevAtu, _aLista)  // Chamada recursiva para ler a estrutura do componente atual
	               sg1 -> (dbgoto (_nRegSG1))
	            endif
	         endif
	      endif
      endif
      sg1 -> (dbskip ())
   enddo
return _aLista
// --------------------------------------------------------------------------
// Le roteiro de operacoes do produto em questao
static function _LeRoteiro (_sProduto, _sRoteiro, _sFilSG2, _lSetup, _nQtAcum)
   local _aRot     := {}
   local _nTempo   := 0
   local _nLotePad := 0

   if ! empty (_sRoteiro)
               
      sg2 -> (dbsetorder (1))
      sg2 -> (dbseek (xfilial ("SG2") + _sProduto + _sRoteiro, .T.))
      do while !sg2 -> (eof ()) .and. sg2 -> g2_filial == xfilial ("SG2") .and. sg2 -> g2_produto == _sProduto .and. sg2 -> g2_codigo == _sRoteiro

         // Valida filtro.
         if &(_sFilSG2)

            // Calcula tempo padrao da operacao
            _nLotePad = iif (sg2 -> g2_lotepad == 0, 1, sg2 -> g2_lotepad)
            //_nTempo = (sg2 -> g2_tempad / _nLotePad) + iif (_lSetup, sg2 -> g2_setup, 0)
            _nTempo = (sg2 -> g2_tempad / _nLotePad)
            if sg2 -> g2_tpoper == "1" .or. empty (sg2 -> g2_tpoper)  // Default
               _nTempo *= _nQtAcum
            endif
            _nTempo += iif (_lSetup, sg2 -> g2_setup, 0)

            aadd (_aRot, {sg2 -> g2_operac, ;
                          fbuscacpo ("SH1", 1, xfilial ("SH1") + sg2 -> g2_recurso, "H1_CCUSTO"), ;
                          _nTempo})
         endif
         sg2 -> (dbskip ())
      enddo
   endif
return _aRot
// --------------------------------------------------------------------------
// Le saldos do produto em questao.
static function _LeSaldos (_sProduto, _nSaldoAtu, _nSaldoTer, _nSaldoEmp, _nSaldoPre, _lSaldoAtu, _lSaldoTer, _lSaldoEmp, _lSaldoPre)
   _nSaldoAtu = 0
   _nSaldoTer = 0
   _nSaldoEmp = 0
   _nSaldoPre = 0
   sb2 -> (dbseek (xfilial ("SB2") + sg1 -> g1_comp, .T.))
   do while !sb2 -> (eof ()) .and. sb2 -> b2_filial == xfilial ("SB2") .and. sb2 -> b2_cod == sg1 -> g1_comp
      _nSaldoAtu += iif (_lSaldoAtu, sb2 -> b2_qatu, 0)
      _nSaldoTer += iif (_lSaldoTer, sb2 -> b2_qnpt, 0)
      _nSaldoEmp += iif (_lSaldoEmp, sb2 -> b2_qemp, 0)
      _nSaldoPre += iif (_lSaldoPre, sb2 -> b2_salpedi, 0)
      sb2 -> (dbskip ())
   enddo
return
// --------------------------------------------------------------------------
// Calcula numero de dias para producao.
static function _CalcDias ()
   local _nDias := 0
   _nDias = sb1 -> b1_pe * iif (sb1 -> b1_tipe == "H", 1/24, ;
                              iif (sb1 -> b1_tipe == "D", 1, ;
                                 iif (sb1 -> b1_tipe == "S", 7,  ;
                                    iif (sb1 -> b1_tipe == "M", 30, ;
                                       iif (sb1 -> b1_tipe == "A", 365, 0)))))
return _nDias
