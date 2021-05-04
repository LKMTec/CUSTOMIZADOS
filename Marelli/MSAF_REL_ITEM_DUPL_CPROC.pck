create or replace package MSAF_REL_ITEM_DUPL_CPROC is

  -- Autor   : Fabio Freitas
  -- Created : 17/08/2010
  -- Purpose : Relatório de Conferência de itens duplicados e fora da sequencia
  -- Parametros : Empresa, Estabelecimento, Data Inicio, Data Fim e tipo de crítca do relatório

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;

  function executar (pcd_empr      varchar2,
                     pcd_estab     varchar2,
                     pdt_inicio    date,
                     pdt_final     date,
                     p_tipo        varchar2,
                     pgera         varchar2,
                     pproc         varchar2) return integer;

 PROCEDURE Cabecalho (pcempresa            varchar2,
                      pcestab              varchar2,
                      pperiodo_ini         DATE,
                      pperiodo_fim         DATE,
                      pcpf_cgc             VARCHAR2,
                      prazao               varchar2,
                      vtipo                varchar2
                      );

end MSAF_REL_ITEM_DUPL_CPROC;
/
create or replace package body MSAF_REL_ITEM_DUPL_CPROC is

  mcod_estab   estabelecimento.cod_estab%TYPE;
  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;

  -- 001
  -- Fabio Freitas
  -- 07/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Duplicidade de Ativos

  -- 002
  -- Fabio Freitas
  -- 11/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Nota Fiscal sem Número da Chave Eletrônica

  -- 003
  -- Fabio Freitas
  -- 11/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Nota Fiscal com Número da Chave Eletrônica menor que 44 posições

  -- 004
  -- Fabio Freitas
  -- 12/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Comparação entre Unidade Padrão do cadastro de produtos com o movimento de inventário

  -- 005
  -- Fabio Freitas
  -- 12/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Comparação entre Unidade de Medida do cadastro de produtos com o movimento de inventário

  -- 006
  -- Fabio Freitas
  -- 12/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Classificação do Item em branco no cadastro de produto

  -- 007
  -- Fabio Freitas
  -- 13/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Grupo de Contagem do Inventário que necessita do CODIGO DE PESSOA FISICA / JURIDICA

  -- 008
  -- Fabio Freitas
  -- 13/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Relatório de críticas de NBM/NCM inconsistentes nas tabelas X52, x10, x08 e X2013

  -- 009
  -- Fabio Freitas
  -- 18/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Relatório de Ativos Imobilizados com valor zero

  -- 010
  -- Fabio Freitas
  -- 18/04/2011
  -- Inclusão de relatórios para o SPED FISCAL
  -- Relatório de Ativos Imobilizados não processados - Tabela Customizada Carga SAFX82

  -- 011
  -- Fabio Freitas
  -- 17/05/2011
  -- Inclusão de arquivo para o SPED FISCAL
  -- Geração de arquivos a partir da tabela customizada do MasterSAF com os layouts da SAFX13 e SAFX82

  -- 012
  -- Fabio Freitas
  -- 10/01/2012
  -- Modificação select documentos duplicados, eliminado do filtro a opção de verificação do movto_e_s
  -- Chamado: 103224

  -- 013
  -- Fabio Freitas
  -- 20/04/2012
  -- Inclusão de informações no Relatório de Ativos não processados - Tabela Customizada Carga SAFX82
  -- Chamado: 101275

  -- 014
  -- Fabio Freitas
  -- 08/06/2012
  -- Chamado 108272
  -- Inclusao de Campo RELATORIO DE ATIVOS NÃO PROCESSADOS-TABELA CUSTOMIZADA CARGA SAFX82

  -- 014
  -- Fabio Freitas
  -- 08/06/2012
  -- Chamado 108272
  -- Inclusao de Campo RELATORIO DE ATIVOS NÃO PROCESSADOS-TABELA CUSTOMIZADA CARGA SAFX82
  -- Campo NBM

  -- 015
  -- Fabio Freitas
  -- 04/10/2012
  -- Chamado 112545
  -- Inclusao de Relatório de demonstração de campos vazios que impedem a validação do SPED
  -- COD_CCUS   Centro de custo
  -- COD_NAT_CC Natureza do bem
  -- FUNC       Funcao do bem
  -- IDENT_MERC Tipo de Bem
  -- NIVEL      Nível da conta  vazio
  -- COD_CTA    Código da conta vazio no bem (Conta A do Bem)  
  
  --016
  --Paulo Ribeiro
  --Chamado 176226
  --Inclusão de Relatorio de Inconsistencia Modelo Docto x Chave NFE

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

    LIB_PROC.add_param(pstr, 'Empresa', 'Varchar2',
                             'Combobox', 'S', NULL, NULL,
                             'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where cod_empresa = '''||mcod_empresa||''' order by 1' );

   LIB_PROC.add_param(pstr, 'Estabelecimento'  , 'Varchar2', 'Combobox' , 'S', 'TODOS', NULL,
                            'select ''TODOS'',''Todos os Estabelecimentos'' from dual union '||
                            'Select distinct cod_estab, cod_estab||'' - ''||razao_social '||
                            'from estabelecimento where cod_empresa = :1 order by 1' );

    LIB_PROC.add_param(pstr,
                       'Data Inicio ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');

    LIB_PROC.add_param(pstr,
                       'Data Final ',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'dd/mm/yyyy');

    LIB_PROC.add_param(pstr,
                       'Tipo de Relatório ',
                       'Varchar2',
                       'Listbox', 'S', NULL, NULL,
                       '1=Relatório de Itens com problema de sequência-NF,' ||
                       '2=Relatório de Itens em duplicidade-NF,'||
                       '3=Relatório de Documentos sem Itens-NF,'||
                       '4=Relatório de Documentos Duplicados-NF,'||
                       '5=Relatório de Ativos Duplicados,'||
                       '6=Relatório de NFE Sem Chave Eletrônica,'||
                       '7=Relatório de Inconsistencia Modelo Docto x Chave NFE,'||
                       '8=Relatório de Comparação Und Padrão Produto X Inventário,'||
                       '9=Relatório de Comparação Und de Medida Produto X Inventário,'||
                       '10=Relatório de Classificação do Item em Branco,'||
                       '11=Relatório de Grupo de Contagem sem Código Pessoa Fis - Jur,'||
                       '12=Relatório de Inconsistências de NBM - NCM,'||
                       '13=Relatório de Ativo Imobilizado com valor zero,'||
                       '14=Relatório de Ativos não processados - Tabela Customizada Carga SAFX82,'||
                       '15=Arquivo: Pendencia Layout SAFX13 - Ativo Imobilizado,'||
-- 015
                       '16=Arquivo: Pendencia Layout SAFX82 - Ativo Imobilizado,'||
                       '17=Arquivo: Crítica CIAP-X13 Conta Contab-CCusto-Nivel-Funcao-Natureza,'||
                       '18=Relatorio de Validacao Fretes - UF Orig x Destino');
--                       '16=Arquivo: Pendencia Layout SAFX82 - Ativo Imobilizado');
-- 015

  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Utilizar o parâmetro abaixo somente quando a opção selecionada for o Relatório de Inconsistências de NBM - NCM'  , 'varchar2'  , 'text'  , 'N', null   , null) ;
    -- 008
     LIB_PROC.add_param(pstr,
                        'Tabela de Origem: ',
                        'Varchar2',
                        'RadioButton',
                        'N',
                        Null,
                        Null,
                        '1=ITENS DE MERCADORIA - X08,'||
                        '2=INVENTARIO - X52,'||
                        '3=MOVIMENTO DE ESTOQUE = X10,'||
                        '4=CADASTRO DE PRODUTO = X2013');
    -- 008

  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Utilizar o parâmetro abaixo somente quando a opção selecionada for o Relatório de Ativos não processados - Tabela Customizada '  , 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Carga SAFX82'  , 'varchar2'  , 'text'  , 'N', null   , null) ;
    -- 010
     LIB_PROC.add_param(pstr,
                        'Parâmetro de Processo: ',
                        'Varchar2',
                        'RadioButton',
                        'N',
                        Null,
                        Null,
                        '1=TODOS OS PERIODOS,'||
                        '2=FILTRAR PELA DATA PARAMETRIZADA');
    -- 010


  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Obs.: Antes da execução, verifique se o Data Mart está equalizado. Equalização para Notas Fiscais !'  , 'varchar2'  , 'text'  , 'N', null   , null) ;

-- 015
  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'Para o arquivo Crítica CIAP-X13, a data de seleção dos dados é a VALIDADE DO BEM'  , 'varchar2'  , 'text'  , 'N', null   , null) ;
-- 015

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório de inconsistências para APURAÇÃO DO SPED FISCAL';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório de inconsistências para APURAÇÃO DO SPED FISCAL';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Processos Customizados';
  END;

  FUNCTION Executar (pcd_empr      varchar2,
                     pcd_estab     varchar2,
                     pdt_inicio    date,
                     pdt_final     date,
                     p_tipo        varchar2,
                     pgera         varchar2,
                     pproc         varchar2) RETURN INTEGER IS

     -- Itens fora de sequência
     CURSOR cur_1 IS
          select cod_empresa,
                 cod_estab,
                 data_fiscal,
                 movto_e_s,
                 norm_dev,
                 ident_docto,
                 ident_fis_jur,
                 num_docfis,
                 serie_docfis,
                 sub_serie_docfis,
                 count(*)       contador
          from   dwt_itens_merc
          where  cod_empresa = pcd_empr
          and    cod_estab   = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
          and    data_fiscal between pdt_inicio and pdt_final
          group by
                cod_empresa,
                cod_estab,
                data_fiscal,
                movto_e_s,
                norm_dev,
                ident_docto,
                ident_fis_jur,
                num_docfis,
                serie_docfis,
                sub_serie_docfis
          having count(*) > 1
          order by data_fiscal, num_docfis;

     -- Itens duplicados
     CURSOR cur_2 IS
          select distinct
                 cod_empresa,
                 cod_estab,
                 data_fiscal,
                 movto_e_s,
                 norm_dev,
                 ident_docto,
                 ident_fis_jur,
                 num_docfis,
                 serie_docfis,
                 sub_serie_docfis,
                 num_item,
                 count(*)
          from   dwt_itens_merc
          where  cod_empresa = pcd_empr
          and    cod_estab   = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
          and    data_fiscal between pdt_inicio and pdt_final
          group by
                 cod_empresa,
                 cod_estab,
                 data_fiscal,
                 movto_e_s,
                 norm_dev,
                 ident_docto,
                 ident_fis_jur,
                 num_docfis,
                 serie_docfis,
                 sub_serie_docfis,
                 num_item
          having count(*) > 1
          order by data_fiscal, num_docfis;

     -- Codigo de Produto e Descricao
     CURSOR cur_3 (ccod_empresa      dwt_itens_merc.cod_empresa%type,
                   ccod_estab        dwt_itens_merc.cod_estab%type,
                   cdata_fiscal      dwt_itens_merc.data_fiscal%type,
                   cmovto_e_s        dwt_itens_merc.movto_e_s%type,
                   cnorm_dev         dwt_itens_merc.norm_dev%type,
                   cident_docto      dwt_itens_merc.ident_docto%type,
                   cident_fis_jur    dwt_itens_merc.ident_fis_jur%type,
                   cnum_docfis       dwt_itens_merc.num_docfis%type,
                   cserie_docfis     dwt_itens_merc.serie_docfis%type,
                   csub_serie_docfis dwt_itens_merc.sub_serie_docfis%type,
                   cnum_item         dwt_itens_merc.num_item%type
                   ) IS
         select a.cod_produto,
                a.descricao
         from   x2013_produto     a,
                dwt_itens_merc    b
         where  a.ident_produto     = b.ident_produto
         and    cod_empresa         = ccod_empresa
         and    cod_estab           = ccod_estab
         and    data_fiscal         = cdata_fiscal
         and    movto_e_s           = cmovto_e_s
         and    norm_dev            = cnorm_dev
         and    ident_docto         = cident_docto
         and    ident_fis_jur       = cident_fis_jur
         and    num_docfis          = cnum_docfis
         and    serie_docfis        = cserie_docfis
         and    sub_serie_docfis    = csub_serie_docfis
         and    num_item            = cnum_item
         order by data_fiscal, num_docfis;

     -- NF sem Item - Classificação 1
     CURSOR cur_4 IS
        select distinct
               cod_empresa,
               cod_estab,
               data_fiscal,
               movto_e_s,
               norm_dev,
               ident_docto,
               ident_fis_jur,
               num_docfis,
               serie_docfis,
               sub_serie_docfis,
               b.cod_modelo
        from   dwt_docto_fiscal     a,
               x2024_modelo_docto   b
        where  not exists (select 1
                           from   x08_itens_merc b
                           where  b.cod_empresa          = a.cod_empresa
                           and    b.cod_estab            = a.cod_estab
                           and    b.data_fiscal          = a.data_fiscal
                           and    b.movto_e_s            = a.movto_e_s
                           and    b.norm_dev             = a.norm_dev
                           and    b.ident_docto          = a.ident_docto
                           and    b.ident_fis_jur        = a.ident_fis_jur
                           and    b.num_docfis           = a.num_docfis
                           and    b.serie_docfis         = a.serie_docfis
                           and    b.sub_serie_docfis     = a.sub_serie_docfis)
        and    a.ident_modelo    = b.ident_modelo
        and    cod_class_doc_fis = '1'
        and    a.situacao        <> 'S'
        and    a.cod_empresa      = pcd_empr
        and    a.cod_estab        = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
        and    a.data_fiscal      between pdt_inicio and pdt_final
        order by data_fiscal, num_docfis;

     -- NF sem Item - Classificação 3
     CURSOR cur_5 IS
        select distinct
               cod_empresa,
               cod_estab,
               data_fiscal,
               movto_e_s,
               norm_dev,
               ident_docto,
               ident_fis_jur,
               num_docfis,
               serie_docfis,
               sub_serie_docfis,
               b.cod_modelo
        from   dwt_docto_fiscal     a,
               x2024_modelo_docto   b
        where  not exists (select 1
                           from   x08_itens_merc b
                           where  b.cod_empresa          = a.cod_empresa
                           and    b.cod_estab            = a.cod_estab
                           and    b.data_fiscal          = a.data_fiscal
                           and    b.movto_e_s            = a.movto_e_s
                           and    b.norm_dev             = a.norm_dev
                           and    b.ident_docto          = a.ident_docto
                           and    b.ident_fis_jur        = a.ident_fis_jur
                           and    b.num_docfis           = a.num_docfis
                           and    b.serie_docfis         = a.serie_docfis
                           and    b.sub_serie_docfis     = a.sub_serie_docfis)
        and not exists    (select 1
                           from   x09_itens_serv c
                           where  c.cod_empresa          = a.cod_empresa
                           and    c.cod_estab            = a.cod_estab
                           and    c.data_fiscal          = a.data_fiscal
                           and    c.movto_e_s            = a.movto_e_s
                           and    c.norm_dev             = a.norm_dev
                           and    c.ident_docto          = a.ident_docto
                           and    c.ident_fis_jur        = a.ident_fis_jur
                           and    c.num_docfis           = a.num_docfis
                           and    c.serie_docfis         = a.serie_docfis
                           and    c.sub_serie_docfis     = a.sub_serie_docfis)
        and    cod_class_doc_fis = '3'
        and    a.ident_modelo    = b.ident_modelo
        and    a.situacao        <> 'S'
        and    a.cod_empresa      = pcd_empr
        and    a.cod_estab        = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
        and    a.data_fiscal      between pdt_inicio and pdt_final
        order by data_fiscal, num_docfis;

     -- NF duplicada
     CURSOR cur_6 IS
        select  dwt_docto_fiscal.cod_empresa,
                dwt_docto_fiscal.cod_estab,
-- 012
--                dwt_docto_fiscal.movto_e_s,
-- 012
                dwt_docto_fiscal.norm_dev,
                dwt_docto_fiscal.num_docfis,
                dwt_docto_fiscal.serie_docfis,
                dwt_docto_fiscal.sub_serie_docfis,
                x04_pessoa_fis_jur.grupo_fis_jur,
                x04_pessoa_fis_jur.cod_fis_jur,
                x2005_tipo_docto.grupo_docto,
                count(*)
        from    dwt_docto_fiscal,
                x04_pessoa_fis_jur,
                x2005_tipo_docto
        where   x04_pessoa_fis_jur.ident_fis_jur = dwt_docto_fiscal.ident_fis_jur
        and     x2005_tipo_docto.ident_docto     = dwt_docto_fiscal.ident_docto
        and     dwt_docto_fiscal.cod_empresa     =  pcd_empr
        and     dwt_docto_fiscal.cod_estab       =  decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
        and     dwt_docto_fiscal.data_fiscal     >= pdt_inicio
        and     dwt_docto_fiscal.data_fiscal     <= pdt_final
        and     dwt_docto_fiscal.movto_e_s       in ('1','2','3','4','5','9')
        and     dwt_docto_fiscal.situacao        not in (' ', 'S')
        group by dwt_docto_fiscal.cod_empresa,
                dwt_docto_fiscal.cod_estab,
-- 012
--                dwt_docto_fiscal.movto_e_s,
-- 012
                dwt_docto_fiscal.norm_dev,
                dwt_docto_fiscal.num_docfis,
                dwt_docto_fiscal.serie_docfis,
                dwt_docto_fiscal.sub_serie_docfis,
                x04_pessoa_fis_jur.grupo_fis_jur,
                x04_pessoa_fis_jur.cod_fis_jur,
                x2005_tipo_docto.grupo_docto
        having count(1) > 1
        order by /*data_fiscal, */num_docfis;

     -- 001
     -- Ativos Duplicados
     CURSOR cur_7 IS
        select distinct
               a.cod_empresa,
               a.cod_estab,
               a.cod_bem,
               a.cod_inc,
               a.tipo_mov,
               b.descr_tipo_mov,
               count(*)
        from   apt_aquisicao a,
               apt_tipo_mov  b,
               apt_aquisicao c
        where  a.tipo_mov     = b.tipo_mov
        and    a.cod_empresa  = c.cod_empresa
        and    a.cod_estab    = c.cod_estab
        and    a.cod_bem      = c.cod_bem
        and    a.cod_inc      = c.cod_inc
        and    a.dat_oper     > add_months(pdt_final, -49)
        and    a.st_ativo     = 'A'
        and    c.st_ativo     = 'A'
        and    to_char(to_date(a.dat_oper, 'dd/mm/rrrr'), 'mm/rrrr') <> to_char(to_date(c.dat_oper, 'dd/mm/rrrr'), 'mm/rrrr')
        and    a.cod_empresa  = pcd_empr
        and    a.cod_estab    = decode(pcd_estab, 'TODOS', a.cod_estab, pcd_estab)
        group by
               a.cod_empresa,
               a.cod_estab,
               a.cod_bem,
               a.cod_inc,
               a.tipo_mov,
               b.descr_tipo_mov
        having count(*) > 1
        order by 1,2;

     -- numero do CIAP para ativos duplicados
     CURSOR cur_8 (pcod_empresa varchar2,
                   pcod_estab   varchar2,
                   pcob_bem     varchar2,
                   pcod_inc     varchar2,
                   ptipo_mov    varchar2) IS
        select num_ciap,
               dat_oper
        from   apt_aquisicao
        where  cod_empresa = pcod_empresa
        and    cod_estab   = decode(pcod_estab, 'TODOS', cod_estab, pcod_estab)
        and    cod_bem     = pcob_bem
        and    cod_inc     = pcod_inc
        and    tipo_mov    = ptipo_mov
        and    st_ativo    = 'A';
     -- 001

     -- 002
     -- Select Chave NFE Nula
     CURSOR cur_9 IS
     select b.cod_empresa,
            b.cod_estab,
            b.data_fiscal,
            b.movto_e_s,
            b.norm_dev,
            b.ident_docto,
            a.cod_docto,
            b.ident_fis_jur,
            d.ind_fis_jur,
            d.cod_fis_jur,
            b.num_docfis,
            b.serie_docfis,
            b.sub_serie_docfis,
            c.cod_modelo,
            c.descricao
     from   dwt_docto_fiscal      b,
            x2024_modelo_docto    c,
            x04_pessoa_fis_jur    d,
            x2005_tipo_docto      a

     where  b.num_autentic_nfe      is null
     and    b.ident_modelo          = c.ident_modelo
     and    b.ident_fis_jur         = d.ident_fis_jur
     and    b.ident_docto           = a.ident_docto
     and    c.cod_modelo            = '55'
     and    b.cod_empresa           = pcd_empr
     and    b.cod_estab             = decode(pcd_estab, 'TODOS', b.cod_estab, pcd_estab)
     and    b.data_fiscal           between pdt_inicio and pdt_final
     order by data_fiscal, num_docfis;
     -- 002

     -- 003
     -- Select Inconsistencia Modelo Docto x Chave NFE
     CURSOR cur_10 IS
     select b.cod_empresa,
            b.cod_estab,
            b.data_fiscal,
            b.movto_e_s,
            b.norm_dev,
            b.ident_docto,
            a.cod_docto,
            b.ident_fis_jur,
            d.ind_fis_jur,
            d.cod_fis_jur,
            b.num_docfis,
            b.serie_docfis,
            b.sub_serie_docfis,
            c.cod_modelo,
            c.descricao
     from   dwt_docto_fiscal      b,
            x2024_modelo_docto    c,
            x04_pessoa_fis_jur    d,
            x2005_tipo_docto      a

     where  b.num_autentic_nfe is not null
     and    b.cod_class_doc_fis <> '2'
     and    b.ident_modelo             = c.ident_modelo
     and    b.ident_fis_jur            = d.ident_fis_jur
     and    b.ident_docto              = a.ident_docto
     and    c.cod_modelo               not in ('55','57','58','59','67')
     and    b.cod_empresa              = pcd_empr
     and    b.cod_estab                = decode(pcd_estab, 'TODOS', b.cod_estab, pcd_estab)
     and    b.data_fiscal              between pdt_inicio and pdt_final
     order by data_fiscal, num_docfis;
     -- 003

     -- 004
     -- Select UND_PADRAO DO PRODUTO DIFERENTE DO INVENTARIO
     CURSOR cur_11 IS
     select x2017_p.cod_und_padrao             und_padrao_cad_prod,
            x2017_p.descricao                  descr_und_padrao_cad_prod,
            x2017_i.cod_und_padrao             und_padrao_invent,
            x2017_i.descricao                  descr_und_padrao_invent,
            x2013.cod_produto,
            x2013.ind_produto,
            x2013.descricao,
            x52.*
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2017_und_padrao   x2017_p,
            x2017_und_padrao   x2017_i
     where  x52.cod_Empresa        = pcd_empr
     and    x52.cod_Estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.ident_produto      = x2013.ident_produto
     and    x2013.ident_und_padrao = x2017_p.ident_und_padrao
     and    x52.ident_und_padrao   = x2017_i.ident_und_padrao
     and    x2017_p.cod_und_padrao <> x2017_i.cod_und_padrao
     and    data_inventario        = pdt_final;
     -- 004

     -- 005
     -- Select UND_MEDIDA DO PRODUTO DIFERENTE DO INVENTARIO
     CURSOR cur_12 IS
     select x2007_p.cod_medida             und_medida_cad_prod,
            x2007_p.descricao              descr_und_medida_cad_prod,
            x2007_i.cod_medida             und_medida_invent,
            x2007_i.descricao              descr_und_medida_invent,
            x2013.cod_produto,
            x2013.ind_produto,
            x2013.descricao,
            x52.*
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2007_medida       x2007_p,
            x2007_medida       x2007_i
     where  x52.cod_Empresa        = pcd_empr
     and    x52.cod_Estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.ident_produto      = x2013.ident_produto
     and    x2013.ident_medida     = x2007_p.ident_medida
     and    x52.ident_medida       = x2007_i.ident_medida
     and    x2007_p.cod_medida     <> x2007_i.cod_medida
     and    data_inventario        = pdt_final;
     -- 005

     -- 006
     -- Select para preechimento do campo Classificação do Item do Produto
     CURSOR cur_13 IS
     select x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario data_fiscal,
            'X52_INVENTARIO'    tabela,
            x2013.*
     from   x52_invent_produto       x52,
            x2013_produto            x2013
     where  x52.ident_produto   = x2013.ident_produto
     and    x52.cod_empresa     = pcd_empr
     and    x52.cod_estab       = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario = pdt_final
     and    x2013.clas_item     is null
     union all
     select x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'X08_ITENS_MERC'    tabela,
            x2013.*
     from   x2013_produto       x2013,
            dwt_itens_merc      x08
     where  x2013.ident_produto = x08.ident_produto
     and    x08.cod_empresa     = pcd_empr
     and    x08.cod_estab       = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal     between pdt_inicio and pdt_final
     and    x2013.clas_item     is null;
     -- 006

     -- 007
     -- Grupo de Contagem que necessita de Codigo de pessoa Fisica / Juridica
     CURSOR cur_14 IS
     select distinct
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario,
            x52.grupo_contagem,
            decode(x52.grupo_contagem, '1', 'Estoque Próprio, em Poder do Estabelecimento',
                                       '2', 'Estoque Próprio, em Poder de Terceiros',
                                       '3', 'Estoque de Terceiros, em Poder do Estabelecimento',
                                       '4', 'Estoque de Terceiros em poder de Terceiros',
                                       '5', 'Estoque em Depósito Fechado', null) grupo_contagem_dsc,
            x2013.ind_produto,
            x2013.cod_produto
     from   x52_invent_produto   x52,
            x2013_produto        x2013
     where  x52.ident_fis_jur   = x2013.ident_produto
     and    x52.ident_fis_jur   is null
     and    x52.grupo_contagem  in ('2', '3', '4', '5')
     and    x52.cod_empresa     = pcd_empr
     and    x52.cod_estab       = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario = pdt_final;
     -- 007

     -- 008
     CURSOR cur_15 IS
     -- Inventário com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            'INVENTARIO'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'   critica,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x52.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final
     union all
     -- Inventário com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            'INVENTARIO'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'   critica,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x52.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final
     union all
     -- Inventário com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            'INVENTARIO'                     tabela,
            'NBM/NCM NAO INFORMADA'          critica,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x52.ident_nbm          = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final;


     CURSOR cur_16 IS
     -- Docto Fiscal com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'          critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x08.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final
     union all
     -- Docto Fiscal com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'          critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x08.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final
     union all
     -- Docto Fiscal com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'                     tabela,
            'NBM/NCM NAO INFORMADA'                 critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x08.ident_nbm          = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final;

     CURSOR cur_17 IS
     -- Estoque com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'      critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x10.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final
     union all
     -- Estoque com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'      critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x10.ident_nbm          = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final
     union all
     -- Estoque com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM NAO INFORMADA'             critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x10.ident_nbm          = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final;

     CURSOR cur_18 IS
     -- Cadastro de Produto (Inventário) com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario              data_fiscal,
            'INVENTARIO'                     tabela,
            'NBM/NCM NAO INFORMADA'          critica
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final
     union all
     -- Cadastro de Produto (Inventário) com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario              data_fiscal,
            'INVENTARIO'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'   critica
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final
     union all
     -- Cadastro de Produto (Inventário) com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x52.cod_empresa,
            x52.cod_estab,
            x52.data_inventario              data_fiscal,
            'INVENTARIO'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'   critica
     from   x52_invent_produto x52,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x52.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x52.cod_empresa        = pcd_empr
     and    x52.cod_estab          = decode(pcd_estab, 'TODOS', x52.cod_estab, pcd_estab)
     and    x52.data_inventario    = pdt_final
     union all
     -- Cadastro de Produto (Docto Fiscal) com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'          critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final
     union all
     -- Cadastro de Produto (Docto Fiscal) com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'          critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final
     union all
     -- Cadastro de Produto (Docto Fiscal) com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x08.cod_empresa,
            x08.cod_estab,
            x08.data_fiscal,
            'ITEM DOCTO FISCAL'              tabela,
            'NBM/NCM NAO INFORMADA'          critica
     from   dwt_itens_merc     x08,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x08.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x08.cod_empresa        = pcd_empr
     and    x08.cod_estab          = decode(pcd_estab, 'TODOS', x08.cod_estab, pcd_estab)
     and    x08.data_fiscal        between pdt_inicio and pdt_final
     union all
     -- Cadastro de Produto (Estoque) com código de NBM/NCM menor que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto                      data_fiscal,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM MENOR QUE 8 POSICOES'      critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  < 8
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final
     union all
     -- Cadastro de Produto (Estoque) com código de NBM/NCM maior que 8 posições
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto                      data_fiscal,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM MAIOR QUE 8 POSICOES'      critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm
     and    length(x2043.cod_nbm)  > 8
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final
     union all
     -- Cadastro de Produto (Estoque) com código de NBM/NCM não informada
     select x2043.cod_nbm,
            x2013.ind_produto,
            x2013.cod_produto,
            x2013.descricao,
            x10.cod_empresa,
            x10.cod_estab,
            x10.data_movto                      data_fiscal,
            'MOVTO ESTOQUE'                     tabela,
            'NBM/NCM NAO INFORMADA'             critica
     from   x10_estoque        x10,
            x2013_produto      x2013,
            x2043_cod_nbm      x2043
     where  x10.ident_produto      = x2013.ident_produto
     and    x2013.ident_nbm        = x2043.ident_nbm(+)
     and    length(x2043.cod_nbm)  is null
     and    x10.cod_empresa        = pcd_empr
     and    x10.cod_estab          = decode(pcd_estab, 'TODOS', x10.cod_estab, pcd_estab)
     and    x10.data_movto         between pdt_inicio and pdt_final;
     -- 008

     -- 009
     CURSOR cur_19 IS
     -- Ativo Imobilizado com valor zerado
     select a.*, b.descr_tipo_mov
     from   apt_aquisicao a,
            apt_tipo_mov  b
     where  cod_empresa        = pcd_empr
     and    cod_estab          = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
     and    dat_oper           between pdt_inicio and pdt_final
     and    a.tipo_mov         = b.tipo_mov
     and    vlr_cred_icms      = '0'
     and    vlr_cred_dif_aliq  = '0'
     and    vlr_icms_frete     = '0'
     and    vlr_difal_frete    = '0'
     and    vlr_icms_frete_cv  = '0'
     and    vlr_difal_frete_cv = '0'
     and    vlr_icmss          = '0';
     -- 009

     -- 010
     -- Dados do CIAP Legado com data
     CURSOR cur_20 IS
     select a.cod_empresa,
            a.cod_estab,
            a.dat_fiscal,
            a.movto_e_s,
            a.norm_dev,
            a.cod_docto,
            a.num_docfis,
            a.serie_docfis,
            a.ind_fis_jur,
            a.cod_fis_jur,
            a.cod_cfo,
            a.cod_natureza_op,
            a.num_controle_docto,
            a.cod_modelo,
            a.num_item,
            a.ind_produto,
            a.cod_produto,
            a.data_processo,
            a.tipo_mov,
            b.descr_tipo_mov,
-- 013
            a.vlr_cred_icms,
            a.cod_custo,
            a.dat_emissao
-- 013
-- 014
            ,a.discri_item
            ,a.ident_docto
            ,a.ident_fis_jur
            ,a.rowid
-- 014
     from   msaf_ciap_legado_x08 a,
            apt_tipo_mov         b
     where  a.tipo_mov   = b.tipo_mov
     and    a.cod_empresa  = pcd_empr
     and    a.cod_estab    = decode(pcd_estab, 'TODOS', a.cod_estab, pcd_estab)
     and    a.flag_process = 'N';

     -- Dados do CIAP Legado sem data
     CURSOR cur_21 IS
     select a.cod_empresa,
            a.cod_estab,
            a.dat_fiscal,
            a.movto_e_s,
            a.norm_dev,
            a.cod_docto,
            a.num_docfis,
            a.serie_docfis,
            a.ind_fis_jur,
            a.cod_fis_jur,
            a.cod_cfo,
            a.cod_natureza_op,
            a.num_controle_docto,
            a.cod_modelo,
            a.num_item,
            a.ind_produto,
            a.cod_produto,
            a.data_processo,
            a.tipo_mov,
            b.descr_tipo_mov,
-- 013
            a.vlr_cred_icms,
            a.cod_custo,
            a.dat_emissao
-- 013
-- 014
            ,a.discri_item
            ,a.ident_docto
            ,a.ident_fis_jur
            ,a.rowid
-- 014
     from   msaf_ciap_legado_x08 a,
            apt_tipo_mov         b
     where  a.tipo_mov   = b.tipo_mov
     and    a.cod_empresa  = pcd_empr
     and    a.cod_estab    = decode(pcd_estab, 'TODOS', a.cod_estab, pcd_estab)
     and    a.flag_process = 'N'
     and    a.dat_fiscal   between pdt_inicio and pdt_final;
     -- 010

     -- 011
     CURSOR cur_22 IS
     select cod_empresa cod_empresa,
            cod_estab cod_estab,
            'x' cod_bem,
            'x' cod_inc,
            'x' valid_bem,
            decode(compl_descr_bem, null, 'x', compl_descr_bem) descricao,
            'x' cod_conta_cm,
            'x' data_aquis,
            'x' vlr_aquis,
            '@' cod_almox,
            '@' cod_conta_depr,
            decode(cod_custo, null,'x', cod_custo) cod_custo,
            '@' cod_despesa,
            decode(cod_docto, null, 'x', cod_docto) codt_docto,
            'x' ident_sit_bem,
            'x' cod_bem_orig,
            'x' cod_inc_orig,
            '@' data_baixa,
            '@' data_ini_cm,
            'x' data_ini_depr,
            num_docfis num_docfis,
            serie_docfis serie_docfis,
            sub_serie_docfis sub_serie_docfis,
            '@' serie_bem,
            '@' arquivamento,
            'x' taxa_depr,
            '@' cod_indice,
            '@' vlr_em_indice,
            '1' ind_nat_bem,
            'x' vlr_aquis_real,
            '0' vlr_depr_acum,
            '0' vlr_depr_lanc,
            '@' ind_gera_p7,
            'x' tipo_bem,
            'x' vida_util,
            '@' ind_bem_ori_ativo,
            'x' dsc_funcao,
            to_char(to_date(dat_fiscal, 'dd/mm/rrrr'),'rrrrmmdd') dat_fiscal,
            ind_fis_jur ind_fis_jur,
            cod_fis_jur cod_fis_jur,
            num_item num_item
     from   msaf_ciap_legado_x08
     where  cod_empresa    = pcd_empr
     and    cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
     and    flag_process   = 'N'
     and    dat_fiscal     between pdt_inicio and pdt_final
     and    data_proc_ciap is null;

     CURSOR cur_23 IS
     -- LAYOUT SAFX82 (PENDENCIAS)
     select *
     from   msaf_ciap_legado_x08
     where  cod_empresa    = pcd_empr
     and    cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
     and    dat_fiscal     between pdt_inicio and pdt_final
     and    data_proc_ciap is null;
     -- 011

-- 015
     CURSOR cur_24 IS
      select *
      from   (
      select 'NATUREZA_BEM' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_custo    = c.ident_custo(+)
      and    a.ident_conta_cm = b.ident_conta(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    a.ind_nat_bem    is null
      union all
      select 'TIPO_BEM' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_custo    = c.ident_custo(+)
      and    a.ident_conta_cm = b.ident_conta(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    a.tipo_bem       is null
      union all
      select 'FUNCAO_BEM' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_custo    = c.ident_custo(+)
      and    a.ident_conta_cm = b.ident_conta(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    a.dsc_funcao     is null
      union all
      select 'CONTA_CONTABIL' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_custo    = c.ident_custo(+)
      and    a.ident_conta_cm = b.ident_conta(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    a.ident_conta_cm is null
      union all
      select 'CENTRO_CUSTO' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_custo    = c.ident_custo(+)
      and    a.ident_conta_cm = b.ident_conta(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    a.ident_custo    is null
      union all
      select 'NIVEL_CONTA' CRITICA_ERRO,
             a.cod_empresa,
             a.cod_estab,
             a.cod_bem,
             a.cod_inc,
             a.valid_bem,
             a.descricao,
             a.cod_bem_orig,
             a.cod_inc_orig,
             a.valid_bem_orig,
             a.dat_fiscal,
             a.num_docfis,
             a.serie_docfis,
             a.num_item,
             a.ind_nat_bem,
             a.tipo_bem,
             a.dsc_funcao,
             b.cod_conta,
             c.cod_custo,
             b.nivel
      from   x13_bem_ativo      a,
             x2002_plano_contas b,
             x2003_centro_custo c
      where  a.ident_conta_cm = b.ident_conta
      and    a.ident_custo    = c.ident_custo(+)
      and    a.cod_empresa    = pcd_empr
      and    a.cod_estab      = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
      and    b.nivel          is null) z
      where  z.valid_bem      between pdt_inicio and pdt_final;
      
      CURSOR cur_25 IS      
              select x.cod_empresa
              ,x.cod_estab
              ,t.cod_fis_jur
              ,t.razao_social
              ,t.cpf_cgc
              ,x.data_fiscal
              ,x.data_emissao
              ,x.num_docfis
              ,x.serie_docfis
              ,x.vlr_tot_nota
              ,x.num_autentic_nfe
              

        from x07_docto_fiscal x
            ,x04_pessoa_fis_jur t
            ,x2024_modelo_docto y
            
        where x.ident_fis_jur = t.ident_fis_jur
        and   x.ident_modelo = y.ident_modelo
        and   x.cod_empresa = pcd_empr
        and   x.cod_estab = decode(pcd_estab, 'TODOS', cod_estab, pcd_estab)
        and   x.data_fiscal between pdt_inicio and pdt_final
        and   x.movto_e_s <> '9'
        and   y.cod_modelo in ('57','67')
        and   (x.ident_uf_destino is null or 
        x.ident_uf_orig_dest is null or 
        x.cod_municipio_dest is null or 
        x.cod_municipio_orig is null)
        and   x.situacao <> 'S';
      
-- 015

    /* Variáveis de Trabalho */
    mproc_id          INTEGER;
    mLinha            VARCHAR2(4000);
    v_linha           number(5) := 0;
    v_empresa         varchar2(3);
    v_estab           varchar2(6);
    v_cgc             varchar2(20);
    v_razao           varchar2(150);
    wloop             number      := 0;
    v_cab             number      := 0;
    v_num_item        number      := 0;
     -- 011
     vTab             varchar2(1):= chr(9);
     v_reg            varchar2(4000);
     v_reg_c          varchar2(4000);
     -- 011
     -- 014
     v_vlr_base_icms_1           dwt_itens_merc.vlr_base_icms_1%type;
     v_aliq_tributo_icms         dwt_itens_merc.aliq_tributo_icms%type;
     v_vlr_tributo_ipi           dwt_itens_merc.vlr_tributo_ipi%type;
     v_aliq_tributo_ipi          dwt_itens_merc.aliq_tributo_ipi%type;
     v_vlr_base_pis              dwt_itens_merc.vlr_base_pis%type;
     v_vlr_pis                   dwt_itens_merc.vlr_pis%type;
     v_vlr_aliq_pis              dwt_itens_merc.vlr_aliq_pis%type;
     v_vlr_base_cofins           dwt_itens_merc.vlr_base_cofins%type;
     v_vlr_cofins                dwt_itens_merc.vlr_cofins%type;
     v_vlr_aliq_cofins           dwt_itens_merc.vlr_aliq_cofins%type;
     v_descricao_compl           dwt_itens_merc.descricao_compl%type;
     -- 014
     -- 015
     v_cod_nbm                   x2043_cod_nbm.cod_nbm%type;
     -- 015

  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_REL_ITEM_DUPL_CPROC', 48, 150);

    if p_tipo not in ('14','15','16','17','18')  then
      LIB_PROC.add_tipo(mproc_id, 1, 'RELATORIO_INCONSIST_ITENS', 1);
    else
      LIB_PROC.add_tipo(mproc_id, 2, 'ARQUIVO_INCONSIST_ITENS', 2);
    end if;

    BEGIN

     -- Carrega variaveis de dados do estabelecimento para o cabecalho do relatorio
     begin
      select estab.cod_empresa,
             estab.cod_estab,
             estab.cgc,
             estab.razao_social
      into   v_empresa,
             v_estab,
             v_cgc,
             v_razao
      from   estabelecimento   estab
      where  estab.cod_empresa   = pcd_empr
      and    estab.cod_estab     = decode(pcd_estab, 'TODOS', estab.cod_estab, pcd_estab);
     exception when others then
      v_empresa := pcd_empr;
      v_estab   := 'TODOS';
     end;

if p_tipo = '1' then

      FOR mreg IN cur_1 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

      begin
           select max(num_item)
           into   v_num_item
           from   x08_itens_merc
           where  cod_empresa         = mreg.cod_empresa
           and    cod_estab           = mreg.cod_estab
           and    data_fiscal         = mreg.data_fiscal
           and    movto_e_s           = mreg.movto_e_s
           and    norm_dev            = mreg.norm_dev
           and    ident_docto         = mreg.ident_docto
           and    ident_fis_jur       = mreg.ident_fis_jur
           and    num_docfis          = mreg.num_docfis
           and    serie_docfis        = mreg.serie_docfis
           and    sub_serie_docfis    = mreg.sub_serie_docfis;
     exception when others then
         lib_proc.add_log('Maior numero do item não encontrato'||mreg.num_docfis||'. ', 1);
     end;

     if mreg.contador <> v_num_item then

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

     end if;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

elsif p_tipo = '2' then

      FOR mreg IN cur_2 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          for mreg1 in cur_3 (mreg.cod_empresa,
                              mreg.cod_estab,
                              mreg.data_fiscal,
                              mreg.movto_e_s,
                              mreg.norm_dev,
                              mreg.ident_docto,
                              mreg.ident_fis_jur,
                              mreg.num_docfis,
                              mreg.serie_docfis,
                              mreg.sub_serie_docfis,
                              mreg.num_item) loop

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.num_item, 71);
          mLinha := LIB_STR.w(mLinha, '|', 75);
          mLinha := LIB_STR.w(mLinha, mreg1.cod_produto||' - '||mreg1.descricao, 76);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP; -- cur2
      END LOOP; -- cur3

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

elsif p_tipo = '3' then

      FOR mreg IN cur_4 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_modelo, 71);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, 'MERCADORIA - CLASS 1', 81);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP; -- cur4

      FOR mreg IN cur_5 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_modelo, 71);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, 'MERCADORIA - CLASS 1', 81);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP; -- cur5

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

elsif p_tipo = '4' then

      FOR mreg IN cur_6 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, ' ', 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
-- 012
--          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '', 26);
-- 012
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_fis_jur, 71);
          mLinha := LIB_STR.w(mLinha, '|', 90);
          mLinha := LIB_STR.w(mLinha, mreg.grupo_fis_jur, 91);
          mLinha := LIB_STR.w(mLinha, '|', 110);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 001
elsif p_tipo = '5' then

      FOR mreg IN cur_7 LOOP

        FOR mreg1 in cur_8 (pcd_empr, pcd_estab, mreg.cod_bem, mreg.cod_inc, mreg.tipo_mov) LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 4);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
          mLinha := LIB_STR.w(mLinha, '|', 12);
          mLinha := LIB_STR.w(mLinha, mreg.cod_bem, 13);
          mLinha := LIB_STR.w(mLinha, '|', 43);
          mLinha := LIB_STR.w(mLinha, mreg.cod_inc, 44);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.tipo_mov, 51);
          mLinha := LIB_STR.w(mLinha, '|', 54);
          mLinha := LIB_STR.w(mLinha, mreg.descr_tipo_mov, 55);
          mLinha := LIB_STR.w(mLinha, '|', 75);
          mLinha := LIB_STR.w(mLinha, mreg1.num_ciap, 76);
          mLinha := LIB_STR.w(mLinha, '|', 88);
          mLinha := LIB_STR.w(mLinha, to_char(mreg1.dat_oper, 'dd/mm/rrrr'), 89);
          mLinha := LIB_STR.w(mLinha, '|', 99);
         if to_char(to_date(mreg1.dat_oper, 'dd/mm/rrrr'), 'mm/rrrr') <>
            to_char(to_date(pdt_final, 'dd/mm/rrrr'), 'mm/rrrr') then
          mLinha := LIB_STR.w(mLinha, 'Ativo fora do período de apuração. Não alterar. ', 100);
         else
          mLinha := LIB_STR.w(mLinha, 'Ativo permanente duplicado. Efetuar manutenção. ', 100);
         end if;
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP; -- cur8
      END LOOP; -- cur7

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 001
-- 002
elsif p_tipo = '6' then

      FOR mreg IN cur_9 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_fis_jur, 71);
          mLinha := LIB_STR.w(mLinha, '|', 90);
          mLinha := LIB_STR.w(mLinha, mreg.descricao, 91);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 002
-- 003
elsif p_tipo = '7' then

      FOR mreg IN cur_10 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 32);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 51);
          mLinha := LIB_STR.w(mLinha, '|', 60);
          mLinha := LIB_STR.w(mLinha, mreg.sub_serie_docfis, 61);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_fis_jur, 71);
          mLinha := LIB_STR.w(mLinha, '|', 90);
          mLinha := LIB_STR.w(mLinha, mreg.descricao, 91);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 003
-- 004
elsif p_tipo = '8' then

      FOR mreg IN cur_11 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_inventario, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.und_padrao_cad_prod , 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.descr_und_padrao_cad_prod, 32);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.und_padrao_invent, 51);
          mLinha := LIB_STR.w(mLinha, '|', 55);
          mLinha := LIB_STR.w(mLinha, mreg.descr_und_padrao_invent, 56);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 81);
          mLinha := LIB_STR.w(mLinha, '|', 84);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 85);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.descricao, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 004
-- 005
elsif p_tipo = '9' then

      FOR mreg IN cur_12 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_inventario, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.und_medida_cad_prod, 26);
          mLinha := LIB_STR.w(mLinha, '|', 31);
          mLinha := LIB_STR.w(mLinha, mreg.descr_und_medida_cad_prod, 32);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.und_medida_invent, 51);
          mLinha := LIB_STR.w(mLinha, '|', 55);
          mLinha := LIB_STR.w(mLinha, mreg.descr_und_medida_invent, 56);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 81);
          mLinha := LIB_STR.w(mLinha, '|', 84);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 85);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.descricao, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 005
-- 006
elsif p_tipo = '10' then

      FOR mreg IN cur_13 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.descricao, 71);
          mLinha := LIB_STR.w(mLinha, '|', 120);
          mLinha := LIB_STR.w(mLinha, mreg.tabela, 121);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 006
-- 007
elsif p_tipo = '11' then

      FOR mreg IN cur_14 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_inventario, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.grupo_contagem||' - '||mreg.grupo_contagem_dsc, 71);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 007
-- 008
elsif p_tipo = '12' then

   if pgera = '1' then

      FOR mreg IN cur_15 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_inventario, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_nbm, 71);
          mLinha := LIB_STR.w(mLinha, '|', 81);
          mLinha := LIB_STR.w(mLinha, mreg.tabela, 82);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.critica, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

   elsif pgera = '2' then

      FOR mreg IN cur_16 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_nbm, 71);
          mLinha := LIB_STR.w(mLinha, '|', 81);
          mLinha := LIB_STR.w(mLinha, mreg.tabela, 82);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.critica, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

   elsif pgera = '3' then

      FOR mreg IN cur_17 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_movto, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_nbm, 71);
          mLinha := LIB_STR.w(mLinha, '|', 81);
          mLinha := LIB_STR.w(mLinha, mreg.tabela, 82);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.critica, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

   elsif pgera = '4' then

      FOR mreg IN cur_18 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 8);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 9);
          mLinha := LIB_STR.w(mLinha, '|', 14);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_fiscal, 'dd/mm/rrrr'), 15);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto, 26);
          mLinha := LIB_STR.w(mLinha, '|', 34);
          mLinha := LIB_STR.w(mLinha, mreg.cod_produto, 35);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_nbm, 71);
          mLinha := LIB_STR.w(mLinha, '|', 81);
          mLinha := LIB_STR.w(mLinha, mreg.tabela, 82);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.critica, 101);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);

   end if;
-- 009
elsif p_tipo = '13' then

      FOR mreg IN cur_19 LOOP

          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 4);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
          mLinha := LIB_STR.w(mLinha, '|', 12);
          mLinha := LIB_STR.w(mLinha, mreg.cod_bem, 13);
          mLinha := LIB_STR.w(mLinha, '|', 43);
          mLinha := LIB_STR.w(mLinha, mreg.cod_inc, 44);
          mLinha := LIB_STR.w(mLinha, '|', 50);
          mLinha := LIB_STR.w(mLinha, mreg.tipo_mov, 51);
          mLinha := LIB_STR.w(mLinha, '|', 54);
          mLinha := LIB_STR.w(mLinha, mreg.descr_tipo_mov, 55);
          mLinha := LIB_STR.w(mLinha, '|', 75);
          mLinha := LIB_STR.w(mLinha, mreg.num_ciap, 76);
          mLinha := LIB_STR.w(mLinha, '|', 88);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.dat_oper, 'dd/mm/rrrr'), 89);
          mLinha := LIB_STR.w(mLinha, '|', 99);
          mLinha := LIB_STR.w(mLinha, 'Ativo permanente com valor zerado. Favor verificar', 100);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 1);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 1);
-- 009
-- 010
elsif p_tipo = '14' then

   if pproc = '1' then
-- 013
         v_reg_c := 'COD_EMPRESA'            ||vTab||
                    'COD_ESTAB'              ||vTab||
                    'DATA_FISCAL'            ||vTab||
                    'DATA_EMISSAO'           ||vTab||
                    'MOVTO_E_S'              ||vTab||
                    'NORM_DEV'               ||vTab||
                    'COD_DOCTO'              ||vTab||
                    'NUM_DOCFIS'             ||vTab||
                    'SERIE_DOCFIS'           ||vTab||
                    'COD_CUSTO'              ||vTab||
                    'IND/COD_FIS_JUR'        ||vTab||
                    'CFOP/NATUREZA'          ||vTab||
                    'IND/COD_PRODUTO'        ||vTab||
                    'NUM_ITEM'               ||vTab||
                    'TIPO_MOV'               ||vTab||
                    'DESCR TIPO MOVTO'       ||vTab||
                    'DATA_PROCESSO'          ||vTab||
                    'VLR_CRED_ICMS'          ||vTab||
-- 014
                    'V_VLR_BASE_ICMS_1'      ||vTab||
                    'V_ALIQ_TRIBUTO_ICMS'    ||vTab||
                    'V_VLR_TRIBUTO_IPI'      ||vTab||
                    'V_ALIQ_TRIBUTO_IPI'     ||vTab||
                    'V_VLR_BASE_PIS'         ||vTab||
                    'V_VLR_PIS'              ||vTab||
                    'V_VLR_ALIQ_PIS'         ||vTab||
                    'V_VLR_BASE_COFINS'      ||vTab||
                    'V_VLR_COFINS'           ||vTab||
                    'V_VLR_ALIQ_COFINS'      ||vTab||
                    'V_DESCRICAO_COMPL'      ||vTab||
-- 014
-- 015
                    'COD_NBM';
-- 015

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);
-- 013

      FOR mreg IN cur_20 LOOP

-- 013
/*
          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 4);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
          mLinha := LIB_STR.w(mLinha, '|', 10);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.dat_fiscal, 'dd/mm/rrrr'), 11);
          mLinha := LIB_STR.w(mLinha, '|', 21);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 22);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 26);
          mLinha := LIB_STR.w(mLinha, '|', 29);
          mLinha := LIB_STR.w(mLinha, mreg.cod_docto, 30);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 49);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 50);
          mLinha := LIB_STR.w(mLinha, '|', 53);
          mLinha := LIB_STR.w(mLinha, mreg.ind_fis_jur||'/'||mreg.cod_fis_jur, 54);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_cfo||'/'||mreg.cod_natureza_op, 71);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto||'/'||mreg.cod_produto, 81);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.num_item, 101);
          mLinha := LIB_STR.w(mLinha, '|', 105);
          mLinha := LIB_STR.w(mLinha, mreg.tipo_mov, 106);
          mLinha := LIB_STR.w(mLinha, '|', 109);
          mLinha := LIB_STR.w(mLinha, mreg.descr_tipo_mov, 110);
          mLinha := LIB_STR.w(mLinha, '|', 130);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_processo, 'dd/mm/rrrr hh24:mi:ss'), 131);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;
*/
-- 013
-- 014
begin
        select  x08.vlr_base_icms_1,
                x08.aliq_tributo_icms,
                x08.vlr_tributo_ipi,
                x08.aliq_tributo_ipi,
                x08.vlr_base_pis,
                x08.vlr_pis,
                x08.vlr_aliq_pis,
                x08.vlr_base_cofins,
                x08.vlr_cofins,
                x08.vlr_aliq_cofins,
                x08.descricao_compl,
                x2043.cod_nbm
        into    v_vlr_base_icms_1,
                v_aliq_tributo_icms,
                v_vlr_tributo_ipi,
                v_aliq_tributo_ipi,
                v_vlr_base_pis,
                v_vlr_pis,
                v_vlr_aliq_pis,
                v_vlr_base_cofins,
                v_vlr_cofins,
                v_vlr_aliq_cofins,
                v_descricao_compl,
                v_cod_nbm
        from    dwt_itens_merc x08,
                x2043_cod_nbm  x2043
        where   x08.ident_nbm        = x2043.ident_nbm(+)
        and     x08.cod_empresa      = mreg.cod_empresa
        and     x08.cod_estab        = mreg.cod_estab
        and     x08.num_docfis       = mreg.num_docfis
        and     x08.serie_docfis     = mreg.serie_docfis
        and     x08.data_fiscal      = mreg.dat_fiscal
        and     x08.movto_e_s        = mreg.movto_e_s
        and     x08.norm_dev         = mreg.norm_dev
        and     x08.num_item         = mreg.num_item
        and     x08.ident_docto      = mreg.ident_docto
        and     x08.ident_fis_jur    = mreg.ident_fis_jur
        and     x08.discri_item      = mreg.discri_item;
exception when others then
   lib_proc.add_log('Item não localizado '||mreg.rowid, 1);
end;
-- 014

         v_reg   := mreg.cod_empresa                                            ||vTab||
                    mreg.cod_estab                                              ||vTab||
                    to_char(mreg.dat_fiscal, 'dd/mm/rrrr')                      ||vTab||
                    to_char(mreg.dat_emissao, 'dd/mm/rrrr')                     ||vTab||
                    mreg.movto_e_s                                              ||vTab||
                    mreg.norm_dev                                               ||vTab||
                    mreg.cod_docto                                              ||vTab||
                    mreg.num_docfis                                             ||vTab||
                    mreg.serie_docfis                                           ||vTab||
                    mreg.cod_custo                                              ||vTab||
                    mreg.ind_fis_jur||'/'||mreg.cod_fis_jur                     ||vTab||
                    mreg.cod_cfo||'/'||mreg.cod_natureza_op                     ||vTab||
                    mreg.ind_produto||'/'||mreg.cod_produto                     ||vTab||
                    mreg.num_item                                               ||vTab||
                    mreg.tipo_mov                                               ||vTab||
                    mreg.descr_tipo_mov                                         ||vTab||
                    to_char(mreg.data_processo, 'dd/mm/rrrr hh24:mi:ss')        ||vTab||
                    mreg.vlr_cred_icms                                          ||vTab||
-- 014
                    v_vlr_base_icms_1                                           ||vTab||
                    v_aliq_tributo_icms                                         ||vTab||
                    v_vlr_tributo_ipi                                           ||vTab||
                    v_aliq_tributo_ipi                                          ||vTab||
                    v_vlr_base_pis                                              ||vTab||
                    v_vlr_pis                                                   ||vTab||
                    v_vlr_aliq_pis                                              ||vTab||
                    v_vlr_base_cofins                                           ||vTab||
                    v_vlr_cofins                                                ||vTab||
                    v_vlr_aliq_cofins                                           ||vTab||
                    v_descricao_compl                                           ||vTab||
-- 014
-- 015
                    v_cod_nbm;
-- 015

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 2);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;

   elsif pproc = '2' then

-- 013
         v_reg_c := 'COD_EMPRESA'            ||vTab||
                    'COD_ESTAB'              ||vTab||
                    'DATA_FISCAL'            ||vTab||
                    'DATA_EMISSAO'           ||vTab||
                    'MOVTO_E_S'              ||vTab||
                    'NORM_DEV'               ||vTab||
                    'COD_DOCTO'              ||vTab||
                    'NUM_DOCFIS'             ||vTab||
                    'SERIE_DOCFIS'           ||vTab||
                    'COD_CUSTO'              ||vTab||
                    'IND/COD_FIS_JUR'        ||vTab||
                    'CFOP/NATUREZA'          ||vTab||
                    'IND/COD_PRODUTO'        ||vTab||
                    'NUM_ITEM'               ||vTab||
                    'TIPO_MOV'               ||vTab||
                    'DESCR TIPO MOVTO'       ||vTab||
                    'DATA_PROCESSO'          ||vTab||
                    'VLR_CRED_ICMS'          ||vTab||
-- 014
                    'V_VLR_BASE_ICMS_1'      ||vTab||
                    'V_ALIQ_TRIBUTO_ICMS'    ||vTab||
                    'V_VLR_TRIBUTO_IPI'      ||vTab||
                    'V_ALIQ_TRIBUTO_IPI'     ||vTab||
                    'V_VLR_BASE_PIS'         ||vTab||
                    'V_VLR_PIS'              ||vTab||
                    'V_VLR_ALIQ_PIS'         ||vTab||
                    'V_VLR_BASE_COFINS'      ||vTab||
                    'V_VLR_COFINS'           ||vTab||
                    'V_VLR_ALIQ_COFINS'      ||vTab||
                    'V_DESCRICAO_COMPL'      ||vTab||
-- 014
-- 015
                    'COD_NBM';
-- 015

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);
-- 013

      FOR mreg IN cur_21 LOOP
/*
          if  v_cab = 0 then
           Cabecalho(v_empresa,
                     v_estab,
                     pdt_inicio,
                     pdt_final,
                     v_cgc,
                     v_razao,
                     p_tipo
                     );

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

              v_cab := 1;

          end if;

            if wloop > 37 then
            lib_proc.new_page();

               Cabecalho(v_empresa,
                         v_estab,
                         pdt_inicio,
                         pdt_final,
                         v_cgc,
                         v_razao,
                         p_tipo
                         );

            wloop := 10;

              mLinha := LIB_STR.w('', ' ', 1);
              LIB_PROC.add(mLinha, null, null, 1);

            end if;

          mLinha := LIB_STR.w('', ' ', 1);
          mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
          mLinha := LIB_STR.w(mLinha, '|', 4);
          mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
          mLinha := LIB_STR.w(mLinha, '|', 10);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.dat_fiscal, 'dd/mm/rrrr'), 11);
          mLinha := LIB_STR.w(mLinha, '|', 21);
          mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 22);
          mLinha := LIB_STR.w(mLinha, '|', 25);
          mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 26);
          mLinha := LIB_STR.w(mLinha, '|', 29);
          mLinha := LIB_STR.w(mLinha, mreg.cod_docto, 30);
          mLinha := LIB_STR.w(mLinha, '|', 36);
          mLinha := LIB_STR.w(mLinha, mreg.num_docfis, 37);
          mLinha := LIB_STR.w(mLinha, '|', 49);
          mLinha := LIB_STR.w(mLinha, mreg.serie_docfis, 50);
          mLinha := LIB_STR.w(mLinha, '|', 53);
          mLinha := LIB_STR.w(mLinha, mreg.ind_fis_jur||'/'||mreg.cod_fis_jur, 54);
          mLinha := LIB_STR.w(mLinha, '|', 70);
          mLinha := LIB_STR.w(mLinha, mreg.cod_cfo||'/'||mreg.cod_natureza_op, 71);
          mLinha := LIB_STR.w(mLinha, '|', 80);
          mLinha := LIB_STR.w(mLinha, mreg.ind_produto||'/'||mreg.cod_produto, 81);
          mLinha := LIB_STR.w(mLinha, '|', 100);
          mLinha := LIB_STR.w(mLinha, mreg.num_item, 101);
          mLinha := LIB_STR.w(mLinha, '|', 105);
          mLinha := LIB_STR.w(mLinha, mreg.tipo_mov, 106);
          mLinha := LIB_STR.w(mLinha, '|', 109);
          mLinha := LIB_STR.w(mLinha, mreg.descr_tipo_mov, 110);
          mLinha := LIB_STR.w(mLinha, '|', 130);
          mLinha := LIB_STR.w(mLinha, to_char(mreg.data_processo, 'dd/mm/rrrr hh24:mi:ss'), 131);
          mLinha := LIB_STR.w(mLinha, '|', 150);

          LIB_PROC.add(mLinha, null, null, 1);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;
*/

-- 013
-- 014
begin
        select  x08.vlr_base_icms_1,
                x08.aliq_tributo_icms,
                x08.vlr_tributo_ipi,
                x08.aliq_tributo_ipi,
                x08.vlr_base_pis,
                x08.vlr_pis,
                x08.vlr_aliq_pis,
                x08.vlr_base_cofins,
                x08.vlr_cofins,
                x08.vlr_aliq_cofins,
                x08.descricao_compl,
                x2043.cod_nbm
        into    v_vlr_base_icms_1,
                v_aliq_tributo_icms,
                v_vlr_tributo_ipi,
                v_aliq_tributo_ipi,
                v_vlr_base_pis,
                v_vlr_pis,
                v_vlr_aliq_pis,
                v_vlr_base_cofins,
                v_vlr_cofins,
                v_vlr_aliq_cofins,
                v_descricao_compl,
                v_cod_nbm
        from    dwt_itens_merc x08,
                x2043_cod_nbm  x2043
        where   x08.ident_nbm        = x2043.ident_nbm(+)
        and     x08.cod_empresa      = mreg.cod_empresa
        and     x08.cod_estab        = mreg.cod_estab
        and     x08.num_docfis       = mreg.num_docfis
        and     x08.serie_docfis     = mreg.serie_docfis
        and     x08.data_fiscal      = mreg.dat_fiscal
        and     x08.movto_e_s        = mreg.movto_e_s
        and     x08.norm_dev         = mreg.norm_dev
        and     x08.num_item         = mreg.num_item
        and     x08.ident_docto      = mreg.ident_docto
        and     x08.ident_fis_jur    = mreg.ident_fis_jur
        and     x08.discri_item      = mreg.discri_item;
exception when others then
   lib_proc.add_log('Item não localizado '||mreg.rowid, 1);
end;
-- 014
         v_reg   := mreg.cod_empresa                                            ||vTab||
                    mreg.cod_estab                                              ||vTab||
                    to_char(mreg.dat_fiscal, 'dd/mm/rrrr')                      ||vTab||
                    to_char(mreg.dat_emissao, 'dd/mm/rrrr')                     ||vTab||
                    mreg.movto_e_s                                              ||vTab||
                    mreg.norm_dev                                               ||vTab||
                    mreg.cod_docto                                              ||vTab||
                    mreg.num_docfis                                             ||vTab||
                    mreg.serie_docfis                                           ||vTab||
                    mreg.cod_custo                                              ||vTab||
                    mreg.ind_fis_jur||'/'||mreg.cod_fis_jur                     ||vTab||
                    mreg.cod_cfo||'/'||mreg.cod_natureza_op                     ||vTab||
                    mreg.ind_produto||'/'||mreg.cod_produto                     ||vTab||
                    mreg.num_item                                               ||vTab||
                    mreg.tipo_mov                                               ||vTab||
                    mreg.descr_tipo_mov                                         ||vTab||
                    to_char(mreg.data_processo, 'dd/mm/rrrr hh24:mi:ss')        ||vTab||
                    mreg.vlr_cred_icms                                          ||vTab||
-- 014
                    v_vlr_base_icms_1                                           ||vTab||
                    v_aliq_tributo_icms                                         ||vTab||
                    v_vlr_tributo_ipi                                           ||vTab||
                    v_aliq_tributo_ipi                                          ||vTab||
                    v_vlr_base_pis                                              ||vTab||
                    v_vlr_pis                                                   ||vTab||
                    v_vlr_aliq_pis                                              ||vTab||
                    v_vlr_base_cofins                                           ||vTab||
                    v_vlr_cofins                                                ||vTab||
                    v_vlr_aliq_cofins                                           ||vTab||
                    v_descricao_compl                                           ||vTab||
-- 014
-- 015
                    v_cod_nbm;
-- 015
          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 2);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;

   end if;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);
-- 010
-- 011
elsif p_tipo = '15' then

         v_reg_c := 'COD_EMPRESA'            ||vTab||
                    'COD_ESTAB'              ||vTab||
                    'COD_BEM'                ||vTab||
                    'COD_INC'                ||vTab||
                    'VALID_BEM'              ||vTab||
                    'DESCRICAO'              ||vTab||
                    'COD_CONTA_CM'           ||vTab||
                    'DATA_AQUIS'             ||vTab||
                    'VLR_AQUIS'              ||vTab||
                    'COD_ALMOX'              ||vTab||
                    'COD_CONTA_DEPR'         ||vTab||
                    'COD_CUSTO'              ||vTab||
                    'COD_DESPESA'            ||vTab||
                    'CODT_DOCTO'             ||vTab||
                    'IDENT_SIT_BEM'          ||vTab||
                    'COD_BEM_ORIG'           ||vTab||
                    'COD_INC_ORIG'           ||vTab||
                    'DATA_BAIXA'             ||vTab||
                    'DATA_INI_CM'            ||vTab||
                    'DATA_INI_DEPR'          ||vTab||
                    'NUM_DOCFIS'             ||vTab||
                    'SERIE_DOCFIS'           ||vTab||
                    'SUB_SERIE_DOCFIS'       ||vTab||
                    'SERIE_BEM'              ||vTab||
                    'ARQUIVAMENTO'           ||vTab||
                    'TAXA_DEPR'              ||vTab||
                    'COD_INDICE'             ||vTab||
                    'VLR_EM_INDICE'          ||vTab||
                    'IND_NAT_BEM'            ||vTab||
                    'VLR_AQUIS_REAL'         ||vTab||
                    'VLR_DEPR_ACUM'          ||vTab||
                    'VLR_DEPR_LANC'          ||vTab||
                    'IND_GERA_P7'            ||vTab||
                    'TIPO_BEM'               ||vTab||
                    'VIDA_UTIL'              ||vTab||
                    'IND_BEM_ORI_ATIVO'      ||vTab||
                    'DSC_FUNCAO'             ||vTab||
                    'DAT_FISCAL'             ||vTab||
                    'IND_FIS_JUR'            ||vTab||
                    'COD_FIS_JUR'            ||vTab||
                    'NUM_ITEM';

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN cur_22 LOOP

          v_reg := mreg.cod_empresa                             ||vtab||
                   mreg.cod_estab                               ||vtab||
                   mreg.cod_bem                                 ||vtab||
                   mreg.cod_inc                                 ||vtab||
                   mreg.valid_bem                               ||vtab||
                   mreg.descricao                               ||vtab||
                   mreg.cod_conta_cm                            ||vtab||
                   mreg.data_aquis                              ||vtab||
                   mreg.vlr_aquis                               ||vtab||
                   mreg.cod_almox                               ||vtab||
                   mreg.cod_conta_depr                          ||vtab||
                   mreg.cod_custo                               ||vtab||
                   mreg.cod_despesa                             ||vtab||
                   mreg.codt_docto                              ||vtab||
                   mreg.ident_sit_bem                           ||vtab||
                   mreg.cod_bem_orig                            ||vtab||
                   mreg.cod_inc_orig                            ||vtab||
                   mreg.data_baixa                              ||vtab||
                   mreg.data_ini_cm                             ||vtab||
                   mreg.data_ini_depr                           ||vtab||
                   mreg.num_docfis                              ||vtab||
                   mreg.serie_docfis                            ||vtab||
                   mreg.sub_serie_docfis                        ||vtab||
                   mreg.serie_bem                               ||vtab||
                   mreg.arquivamento                            ||vtab||
                   mreg.taxa_depr                               ||vtab||
                   mreg.cod_indice                              ||vtab||
                   mreg.vlr_em_indice                           ||vtab||
                   mreg.ind_nat_bem                             ||vtab||
                   mreg.vlr_aquis_real                          ||vtab||
                   mreg.vlr_depr_acum                           ||vtab||
                   mreg.vlr_depr_lanc                           ||vtab||
                   mreg.ind_gera_p7                             ||vtab||
                   mreg.tipo_bem                                ||vtab||
                   mreg.vida_util                               ||vtab||
                   mreg.ind_bem_ori_ativo                       ||vtab||
                   mreg.dsc_funcao                              ||vtab||
                   mreg.dat_fiscal                              ||vtab||
                   mreg.ind_fis_jur                             ||vtab||
                   mreg.cod_fis_jur                             ||vtab||
                   mreg.num_item;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 2);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);

elsif p_tipo = '16' then

         v_reg_c := 'COD_EMPRESA'            ||vTab||
                    'COD_ESTAB'              ||vTab||
                    'ANO_REGISTRO'           ||vTab||
                    'NUM_DOCFIS'             ||vTab||
                    'SERIE_DOCFIS'           ||vTab||
                    'SUB_SERIE_DOCFIS'       ||vTab||
                    'DAT_FISCAL'             ||vTab||
                    'IND_FIS_JUR'            ||vTab||
                    'COD_FIS_JUR'            ||vTab||
                    'COD_CFO'                ||vTab||
                    'COD_NATUREZA_OP'        ||vTab||
                    'COMPL_DESCR_BEM'        ||vTab||
                    'VLR_CRED_ICMS'          ||vTab||
                    'COD_CUSTO'              ||vTab||
                    'QUANTIDADE'             ||vTab||
                    'NUM_CONTROLE_DOCTO'     ||vTab||
                    'VLR_CRED_DIF_ALIQ'      ||vTab||
                    'MOVTO_E_S'              ||vTab||
                    'NORM_DEV'               ||vTab||
                    'COD_DOCTO'              ||vTab||
                    'NUM_DOCFIS_REF'         ||vTab||
                    'SERIE_DOCFIS_REF'       ||vTab||
                    'S_SER_DOCFIS_REF'       ||vTab||
                    'VLR_ICMS_FRETE'         ||vTab||
                    'VLR_DIFAL_FRETE'        ||vTab||
                    'DAT_EMISSAO'            ||vTab||
                    'COD_MODELO'             ||vTab||
                    'NUM_CHAVE_NFE'          ||vTab||
                    'NUM_ITEM'               ||vTab||
                    'IND_PRODUTO'            ||vTab||
                    'COD_PRODUTO'            ||vTab||
                    'VLR_ICMSS'              ||vTab||
                    'IDENT_DOCTO'            ||vTab||
                    'IDENT_FIS_JUR'          ||vTab||
                    'DISCRI_ITEM'            ||vTab||
                    'FLAG_PROCESS'           ||vTab||
                    'VLR_UNIT'               ||vTab||
                    'DATA_PROCESSO'          ||vTab||
                    'DATA_PROC_CIAP'         ||vTab||
                    'TIPO_MOV'               ;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN cur_23 LOOP

          v_reg := mreg.cod_empresa                             ||vtab||
                   mreg.cod_estab                               ||vtab||
                   mreg.ano_registro                            ||vtab||
                   mreg.num_docfis                              ||vtab||
                   mreg.serie_docfis                            ||vtab||
                   mreg.sub_serie_docfis                        ||vtab||
                   mreg.dat_fiscal                              ||vtab||
                   mreg.ind_fis_jur                             ||vtab||
                   mreg.cod_fis_jur                             ||vtab||
                   mreg.cod_cfo                                 ||vtab||
                   mreg.cod_natureza_op                         ||vtab||
                   mreg.compl_descr_bem                         ||vtab||
                   mreg.vlr_cred_icms                           ||vtab||
                   mreg.cod_custo                               ||vtab||
                   mreg.quantidade                              ||vtab||
                   mreg.num_controle_docto                      ||vtab||
                   mreg.vlr_cred_dif_aliq                       ||vtab||
                   mreg.movto_e_s                               ||vtab||
                   mreg.norm_dev                                ||vtab||
                   mreg.cod_docto                               ||vtab||
                   mreg.num_docfis_ref                          ||vtab||
                   mreg.serie_docfis_ref                        ||vtab||
                   mreg.s_ser_docfis_ref                        ||vtab||
                   mreg.vlr_icms_frete                          ||vtab||
                   mreg.vlr_difal_frete                         ||vtab||
                   mreg.dat_emissao                             ||vtab||
                   mreg.cod_modelo                              ||vtab||
                   mreg.num_chave_nfe                           ||vtab||
                   mreg.num_item                                ||vtab||
                   mreg.ind_produto                             ||vtab||
                   mreg.cod_produto                             ||vtab||
                   mreg.vlr_icmss                               ||vtab||
                   mreg.ident_docto                             ||vtab||
                   mreg.ident_fis_jur                           ||vtab||
                   mreg.discri_item                             ||vtab||
                   mreg.flag_process                            ||vtab||
                   mreg.vlr_unit                                ||vtab||
                   mreg.data_processo                           ||vtab||
                   mreg.data_proc_ciap                          ||vtab||
                   mreg.tipo_mov;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 1);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);

-- 011
-- 015
elsif trim(p_tipo) = '17' then

         v_reg_c := 'COD_EMPRESA'             ||vTab||
                    'COD_ESTAB'               ||vTab||
                    'COD_BEM'                 ||vTab||
                    'COD_INC'                 ||vTab||
                    'VALID_BEM'               ||vTab||
                    'DESCRICAO'               ||vTab||
                    'COD_BEM_ORIG'            ||vTab||
                    'COD_INC_ORIG'            ||vTab||
                    'VALID_BEM_ORIG'          ||vTab||
                    'DAT_FISCAL'              ||vTab||
                    'NUM_DOCFIS'              ||vTab||
                    'SERIE_DOCFIS'            ||vTab||
                    'NUM_ITEM'                ||vTab||
                    'IND_NAT_BEM'             ||vTab||
                    'TIPO_BEM'                ||vTab||
                    'DSC_FUNCAO'              ||vTab||
                    'COD_CONTA'               ||vTab||
                    'COD_CUSTO'               ||vTab||
                    'NIVEL'                   ||vTab||
                    'CRITICA_ERRO';

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN cur_24 LOOP

          v_reg := mreg.cod_empresa                            ||vtab||
                   mreg.cod_estab                              ||vtab||
                   mreg.cod_bem                                ||vtab||
                   mreg.cod_inc                                ||vtab||
                   mreg.valid_bem                              ||vtab||
                   mreg.descricao                              ||vtab||
                   mreg.cod_bem_orig                           ||vtab||
                   mreg.cod_inc_orig                           ||vtab||
                   mreg.valid_bem_orig                         ||vtab||
                   mreg.dat_fiscal                             ||vtab||
                   mreg.num_docfis                             ||vtab||
                   mreg.serie_docfis                           ||vtab||
                   mreg.num_item                               ||vtab||
                   mreg.ind_nat_bem                            ||vtab||
                   mreg.tipo_bem                               ||vtab||
                   mreg.dsc_funcao                             ||vtab||
                   mreg.cod_conta                              ||vtab||
                   mreg.cod_custo                              ||vtab||
                   mreg.nivel                                  ||vtab||
                   mreg.critica_erro;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 2);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);
-- 015

elsif p_tipo = '18' then

         v_reg_c := 'COD_EMPRESA'            ||vTab||
                    'COD_ESTAB'              ||vTab||
                    'COD_FIS_JUR'            ||vTab||
                    'RAZAO_SOCIAL'           ||vTab||
                    'CPF_CGC'                ||vTab||
                    'DATA_FISCAL'            ||vTab||
                    'DATA_EMISSAO'           ||vTab||
                    'NUM_DOCFIS'             ||vTab||
                    'SERIE_DOCFIS'           ||vTab||
                    'VLR_TOT_NOTA'           ||vTab||
                    'CHAVE ELETRONICA';
-- 015

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 1);

          LIB_PROC.add(mLinha, null, null, 2);
          
          
      FOR mreg IN cur_25 LOOP

          v_reg := mreg.cod_empresa   ||vtab||
                   mreg.cod_estab     ||vtab||
                   mreg.cod_fis_jur   ||vtab||
                   mreg.razao_social  ||vtab||
                   mreg.cpf_cgc       ||vtab||
                   mreg.data_fiscal   ||vtab||
                   mreg.data_emissao  ||vtab||
                   mreg.num_docfis    ||vtab||
                   mreg.serie_docfis  ||vtab||
                   mreg.vlr_tot_nota  ||vtab||
                   mreg.num_autentic_nfe;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 1);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;
         wloop   := wloop + 1;

          v_reg := null;

      END LOOP;


end if;

    END;

    if v_linha = 0 then
     lib_proc.add_log('Não há registros para processar de acordo com os critérios selecionados. ', 1);
     lib_proc.add_log(p_tipo, 1);
    else
     lib_proc.add_log('Geração do relatório concluída! Foram gravados '||v_linha||' registros ', 1);
    end if;

     LIB_PROC.CLOSE();

    RETURN mproc_id;
  END;

  PROCEDURE Cabecalho (pcempresa            varchar2,
                       pcestab              varchar2,
                       pperiodo_ini             DATE,
                       pperiodo_fim             DATE,
                       pcpf_cgc             VARCHAR2,
                       prazao               varchar2,
                       vtipo                varchar2
                       ) IS

     m_Linha  VARCHAR2(150);

     BEGIN

           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'Empr: '||pcempresa||'- Estab: '||pcestab||': '||prazao, 150);
           lib_proc.add(m_Linha, null, null, 1);

           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'CNPJ: '||substr(pcpf_cgc, 1, 2)||'.'||substr(pcpf_cgc, 3, 3)||'.'||substr(pcpf_cgc, 6, 3)||'/'||substr(pcpf_cgc, 9, 4)||'-'||substr(pcpf_cgc, 13, 2), 150);
           lib_proc.add(m_Linha, null, null, 1);

           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'PERIODO DE '||to_date(pperiodo_ini, 'dd/mm/rrrr')||' A '||to_date(pperiodo_fim, 'dd/mm/rrrr'), 150);
           lib_proc.add(m_Linha, null, null, 1);

           m_Linha := null;
           m_Linha := LIB_STR.w(m_Linha, rpad('-', '150', '-'), 1);
           lib_proc.add(m_Linha, null, null, 1);

          if vtipo = '1' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE ITENS COM PROBLEMA DE SEQUENCIA', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '2' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE NÚMERO DO ITEM EM DUPLICIDADE', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '3' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE NOTAS FISCAIS SEM ITEM', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '4' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE NOTAS FISCAIS DUPLICADAS', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '5' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE ATIVOS DUPLICADOS', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '6' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE NOTAS FISCAIS ELETRÔNICAS SEM CHAVE', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '7' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE INCONSISTENCIA MODELO DOCTO X CHAVE NFE', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '8' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO COMPARATIVO DE UNIDADE PADRÃO DO CADASTRO DE ITEM X MOVIMENTO DE INVENTÁRIO', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '9' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO COMPARATIVO DE UNIDADE DE MEDIDA DO CADASTRO DE ITEM X MOVIMENTO DE INVENTÁRIO', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '10' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE CLASSIFICAÇÃO DE ITEM EM BRANCO NO CADASTRO DE PRODUTOS - BASE: NFs E INVENTÁRIO', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '11' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO GRUPO DE CONTAGEM DO INVENTARIO QUE NECESSITA DO CODIGO DE PESSOA FIS / JUR', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '12' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO GRUPO DE INCONSISTENCIAS DE NBM/NCM', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '13' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE ATIVO IMOBILIZADO COM VALOR ZERO', 150);
           lib_proc.add(m_Linha, null, null, 1);
          elsif vtipo = '14' then
           m_Linha := null;
           m_Linha := LIB_STR.wcenter(m_Linha, 'RELATÓRIO DE ATIVO IMOBILIZADO NÃO CARREGADO - TABELA PROCESSO CUSTOMIZADO SAFX82', 150);
           lib_proc.add(m_Linha, null, null, 1);
          end if;

           m_Linha := null;
           m_Linha := LIB_STR.w(m_Linha, rpad('-', '150', '-'), 1);
           lib_proc.add(m_Linha, null, null, 1);
        -- 001
        if vtipo in ('5', '13') then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 4);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 5);
          m_Linha := LIB_STR.w(m_Linha, '|', 12);
          m_Linha := LIB_STR.w(m_Linha, 'COD BEM', 13);
          m_Linha := LIB_STR.w(m_Linha, '|', 43);
          m_Linha := LIB_STR.w(m_Linha, 'INC', 44);
          m_Linha := LIB_STR.w(m_Linha, '|', 50);
          m_Linha := LIB_STR.w(m_Linha, 'MOV', 51);
          m_Linha := LIB_STR.w(m_Linha, '|', 54);
          m_Linha := LIB_STR.w(m_Linha, 'DESCR MOVTO', 55);
          m_Linha := LIB_STR.w(m_Linha, '|', 75);
          m_Linha := LIB_STR.w(m_Linha, 'NUM CIAP', 76);
          m_Linha := LIB_STR.w(m_Linha, '|', 88);
          m_Linha := LIB_STR.w(m_Linha, 'DAT APUR', 89);
          m_Linha := LIB_STR.w(m_Linha, '|', 99);
          m_Linha := LIB_STR.w(m_Linha, 'MENSAGEM', 100);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 001
        elsif vtipo = '8' then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA INV', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'UND PD', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 31);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO UND CAD PRODUTO', 32);
          m_Linha := LIB_STR.w(m_Linha, '|', 50);
          m_Linha := LIB_STR.w(m_Linha, 'UND IN', 51);
          m_Linha := LIB_STR.w(m_Linha, '|', 55);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO UND INVENTARIO', 56);
          m_Linha := LIB_STR.w(m_Linha, '|', 80);
          m_Linha := LIB_STR.w(m_Linha, 'IND', 81);
          m_Linha := LIB_STR.w(m_Linha, '|', 84);
          m_Linha := LIB_STR.w(m_Linha, 'COD PROD', 85);
          m_Linha := LIB_STR.w(m_Linha, '|', 100);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO PRODUTO', 101);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 005
        elsif vtipo = '9' then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA INV', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'MED PD', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 31);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO MEDIDA CAD PRODUTO', 32);
          m_Linha := LIB_STR.w(m_Linha, '|', 50);
          m_Linha := LIB_STR.w(m_Linha, 'MED IN', 51);
          m_Linha := LIB_STR.w(m_Linha, '|', 55);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO MEDIDA INVENTARIO', 56);
          m_Linha := LIB_STR.w(m_Linha, '|', 80);
          m_Linha := LIB_STR.w(m_Linha, 'IND', 81);
          m_Linha := LIB_STR.w(m_Linha, '|', 84);
          m_Linha := LIB_STR.w(m_Linha, 'COD PROD', 85);
          m_Linha := LIB_STR.w(m_Linha, '|', 100);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO PRODUTO', 101);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 005
        -- 006
        elsif vtipo = '10' then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'IND PROD', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 34);
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO DE PRODUTO', 35);
          m_Linha := LIB_STR.w(m_Linha, '|', 70);
          m_Linha := LIB_STR.w(m_Linha, 'DESCRICAO PRODUTO', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 120);
          m_Linha := LIB_STR.w(m_Linha, 'TABELA DE ORIGEM', 121);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 006
        -- 007
        elsif vtipo = '11' then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'IND PROD', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 34);
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO DE PRODUTO', 35);
          m_Linha := LIB_STR.w(m_Linha, '|', 70);
          m_Linha := LIB_STR.w(m_Linha, 'GRUPO DE CONTAGEM', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 007
        -- 008
        elsif vtipo = '12' then
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'IND PROD', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 34);
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO DE PRODUTO', 35);
          m_Linha := LIB_STR.w(m_Linha, '|', 70);
          m_Linha := LIB_STR.w(m_Linha, 'NBM', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 81);
          m_Linha := LIB_STR.w(m_Linha, 'NOME DA TABELA', 82);
          m_Linha := LIB_STR.w(m_Linha, '|', 100);
          m_Linha := LIB_STR.w(m_Linha, 'CRITICA', 101);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        -- 008
        -- 010
        elsif vtipo = '14' then
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMP', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 4);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 5);
          m_Linha := LIB_STR.w(m_Linha, '|', 10);
          m_Linha := LIB_STR.w(m_Linha, 'DATA', 11);
          m_Linha := LIB_STR.w(m_Linha, '|', 21);
          m_Linha := LIB_STR.w(m_Linha, 'E/S', 22);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'N/D', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 29);
          m_Linha := LIB_STR.w(m_Linha, 'DOCTO', 30);
          m_Linha := LIB_STR.w(m_Linha, '|', 36);
          m_Linha := LIB_STR.w(m_Linha, 'NUM DOCFIS', 37);
          m_Linha := LIB_STR.w(m_Linha, '|', 49);
          m_Linha := LIB_STR.w(m_Linha, 'SER', 50);
          m_Linha := LIB_STR.w(m_Linha, '|', 53);
          m_Linha := LIB_STR.w(m_Linha, 'IND/COD FIS/JUR', 54);
          m_Linha := LIB_STR.w(m_Linha, '|', 70);
          m_Linha := LIB_STR.w(m_Linha, 'CFOP/NAT.', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 80);
          m_Linha := LIB_STR.w(m_Linha, 'IND/COD PRODUTO', 81);
          m_Linha := LIB_STR.w(m_Linha, '|', 100);
          m_Linha := LIB_STR.w(m_Linha, 'ITEM', 101);
          m_Linha := LIB_STR.w(m_Linha, '|', 105);
          m_Linha := LIB_STR.w(m_Linha, 'MOV', 106);
          m_Linha := LIB_STR.w(m_Linha, '|', 109);
          m_Linha := LIB_STR.w(m_Linha, 'DSC TIPO MOV', 110);
          m_Linha := LIB_STR.w(m_Linha, '|', 130);
          m_Linha := LIB_STR.w(m_Linha, 'DT PROCESSO', 131);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        else
          m_Linha := null;
          m_Linha := LIB_STR.w(m_Linha, 'EMPRESA', 1);
          m_Linha := LIB_STR.w(m_Linha, '|', 8);
          m_Linha := LIB_STR.w(m_Linha, 'ESTAB', 9);
          m_Linha := LIB_STR.w(m_Linha, '|', 14);
          m_Linha := LIB_STR.w(m_Linha, 'DATA', 15);
          m_Linha := LIB_STR.w(m_Linha, '|', 25);
          m_Linha := LIB_STR.w(m_Linha, 'MOVTO', 26);
          m_Linha := LIB_STR.w(m_Linha, '|', 31);
          m_Linha := LIB_STR.w(m_Linha, 'N/D', 32);
          m_Linha := LIB_STR.w(m_Linha, '|', 36);
          m_Linha := LIB_STR.w(m_Linha, 'NOTA FISCAL', 37);
          m_Linha := LIB_STR.w(m_Linha, '|', 50);
          m_Linha := LIB_STR.w(m_Linha, 'SERIE', 51);
          m_Linha := LIB_STR.w(m_Linha, '|', 60);
          m_Linha := LIB_STR.w(m_Linha, 'SUB SERIE', 61);
          m_Linha := LIB_STR.w(m_Linha, '|', 70);
        if  vtipo = '2' then
          m_Linha := LIB_STR.w(m_Linha, 'ITEM', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 75);
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO PRODUTO / DESCRICAO', 76);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        elsif vtipo = '3' then
          m_Linha := LIB_STR.w(m_Linha, 'MODELO/NF', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 80);
          m_Linha := LIB_STR.w(m_Linha, 'CLASSIFICAÇÃO DO DOCUMENTO', 81);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        elsif vtipo = '4' then
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO PESSOA F/J', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 90);
          m_Linha := LIB_STR.w(m_Linha, 'GRUPO PESSOA F/J', 91);
          m_Linha := LIB_STR.w(m_Linha, '|', 110);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        elsif vtipo = '6' then
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO PESSOA F/J', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 90);
          m_Linha := LIB_STR.w(m_Linha, 'MODELO DOCTO', 91);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        elsif vtipo = '7' then
          m_Linha := LIB_STR.w(m_Linha, 'CODIGO PESSOA F/J', 71);
          m_Linha := LIB_STR.w(m_Linha, '|', 90);
          m_Linha := LIB_STR.w(m_Linha, 'MODELO DOCTO', 91);
          m_Linha := LIB_STR.w(m_Linha, '|', 150);
        end if;
        end if;

           lib_proc.add(m_Linha, null, null, 1);

           m_Linha := null;
           m_Linha := LIB_STR.w(m_Linha, rpad('-', '150', '-'), 1);
           lib_proc.add(m_Linha, null, null, 1);

  END cabecalho;

END MSAF_REL_ITEM_DUPL_CPROC;
/
