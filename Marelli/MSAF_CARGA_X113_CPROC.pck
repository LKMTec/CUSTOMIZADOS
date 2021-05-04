create or replace package MSAF_CARGA_X113_CPROC is

  -- Autor   : Fabio Freitas
  -- Created : 04/07/2012
  -- Purpose : Geração da Interface da X112 e X113 para atendimento ao SPED FISCAL REGISTRO C197
  -- Parametros : Empresa, Estabelecimento, Período, Tipo de geração

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
                     pperiodo      date,
                     ptipo         varchar2) return integer;

end MSAF_CARGA_X113_CPROC;
/
create or replace package body MSAF_CARGA_X113_CPROC is

  mcod_estab   estabelecimento.cod_estab%TYPE;
  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;

  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_estab   := NVL(LIB_PARAMETROS.RECUPERAR('ESTABELECIMENTO'), '');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

    LIB_PROC.add_param(pstr, 'Empresa', 'Varchar2',
                             'Combobox', 'S', NULL, NULL,
                             'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where cod_empresa = '''||mcod_empresa||''' order by 1' );

    LIB_PROC.add_param(pstr, 'Estabelecimento', 'Varchar2',
                             'Combobox', 'S',NULL, NULL,
                             'Select distinct cod_estab, cod_estab||'' - ''||razao_social '||
                             'from estabelecimento where cod_empresa = :1 and ident_estado = 61 order by 1' );

    LIB_PROC.add_param(pstr,
                       'Mês/Ano Competencia',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       'MM/YYYY');

    LIB_PROC.add_param(pstr,
                       'Tipo de Geração',
                       'Varchar2',
                       'Listbox',
                       'S',
                       NULL,
                       NULL,
                       '1=Processo de Carga,' ||
                       '2=Relatório de Movimento,' ||
                       '3=Relatório Dif Aliq sem item');

    RETURN pstr;
  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Carga de dados X112 e X113';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Carga';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Carga de Dados X112 e X113 para SPED FISCAL - REGISTRO C197';
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
                     pperiodo      date,
                     ptipo         varchar2) RETURN INTEGER IS

     -- Cursor X112
     CURSOR cur_1 IS
        select *
        from   (
        select distinct
               itens.cod_empresa                              ,  -- 01
               itens.cod_estab                                ,  -- 02
               itens.data_fiscal                              ,  -- 03
               itens.movto_e_s                                ,  -- 04
               itens.norm_dev                                 ,  -- 05
               itens.ident_docto                              ,  -- 06
               itens.ident_fis_jur                            ,  -- 07
               itens.num_docfis                               ,  -- 08
               itens.serie_docfis                             ,  -- 09
               itens.sub_serie_docfis                         ,  -- 10
               '1150'                    cod_observacao       ,  -- 11  -- Fixo cod_observacao     = 00006S
               'L'                       ind_icompl_lancto    ,  -- 12  -- Fixo ind_icompl_lancto  = L
               null                      dsc_complementar     ,  -- 13
               null                      num_processo         ,  -- 14
               null                      ind_gravacao         ,  -- 15
               null                      vinculacao              -- 16
        from   x08_base_merc             base   ,
               x08_trib_merc             trib   ,
               x08_itens_merc            itens  ,
               estabelecimento           estab
        where  itens.vlr_outros1         > '0'
        and    trib.cod_tributo          = 'ICMS'
        and    base.cod_tributo          = 'ICMS'
        and    base.cod_empresa          = trib.cod_empresa
        and    base.cod_estab            = trib.cod_estab
        and    base.data_fiscal          = trib.data_fiscal
        and    base.movto_e_s            = trib.movto_e_s
        and    base.norm_dev             = trib.norm_dev
        and    base.ident_docto          = trib.ident_docto
        and    base.ident_fis_jur        = trib.ident_fis_jur
        and    base.num_docfis           = trib.num_docfis
        and    base.serie_docfis         = trib.serie_docfis
        and    base.sub_serie_docfis     = trib.sub_serie_docfis
        and    base.discri_item          = trib.discri_item
        and    itens.cod_empresa         = trib.cod_empresa
        and    itens.cod_estab           = trib.cod_estab
        and    itens.data_fiscal         = trib.data_fiscal
        and    itens.movto_e_s           = trib.movto_e_s
        and    itens.norm_dev            = trib.norm_dev
        and    itens.ident_docto         = trib.ident_docto
        and    itens.ident_fis_jur       = trib.ident_fis_jur
        and    itens.num_docfis          = trib.num_docfis
        and    itens.serie_docfis        = trib.serie_docfis
        and    itens.sub_serie_docfis    = trib.sub_serie_docfis
        and    itens.discri_item         = trib.discri_item
        and    itens.cod_estab           = estab.cod_estab
        and    base.cod_empresa          = estab.cod_empresa
        and    base.cod_estab            = estab.cod_estab
        and    trib.cod_empresa          = estab.cod_empresa
        and    trib.cod_estab            = estab.cod_estab
        and    itens.cod_empresa         = pcd_empr
        and    itens.cod_estab           = pcd_estab
        and    to_char(to_date(itens.data_fiscal, 'dd/mm/rrrr'), 'mm/rrrr') = to_char(to_date(pperiodo, 'dd/mm/rrrr'), 'mm/rrrr')) a
        where  not exists                      (select 1
                                                from   x112_obs_docfis   x112
                                                where  x112.cod_empresa       = a.cod_empresa
                                                and    x112.cod_estab         = a.cod_estab
                                                and    x112.data_fiscal       = a.data_fiscal
                                                and    x112.movto_e_s         = a.movto_e_s
                                                and    x112.norm_dev          = a.norm_dev
                                                and    x112.ident_docto       = a.ident_docto
                                                and    x112.ident_fis_jur     = a.ident_fis_jur
                                                and    x112.num_docfis        = a.num_docfis
                                                and    x112.serie_docfis      = a.serie_docfis
                                                and    x112.sub_serie_docfis  = a.sub_serie_docfis
                                                and    x112.ident_observacao  = a.cod_observacao
                                                and    x112.ind_icompl_lancto = a.ind_icompl_lancto);

     -- Cursor X113
      Cursor cur_2 is
        select *
        from   (
        select distinct
               itens.cod_empresa                                   ,  -- 01
               itens.cod_estab                                     ,  -- 02
               itens.data_fiscal                                   ,  -- 03
               itens.movto_e_s                                     ,  -- 04
               itens.norm_dev                                      ,  -- 05
               itens.ident_docto                                   ,  -- 06
               itens.ident_fis_jur                                 ,  -- 07
               itens.num_docfis                                    ,  -- 08
               itens.serie_docfis                                  ,  -- 09
               itens.sub_serie_docfis                              ,  -- 10
               '1150'                           cod_observacao     ,  -- 11  -- Fixo cod_observacao     = 00006S
               'L'                              ind_icompl_lancto  ,  -- 12  -- Fixo ind_icompl_lancto  = L
               case
                 when cfop.cod_cfo = '2352' then 'MG70000001'
                 when cfop.cod_cfo = '2353' then 'MG70000001'
                 when cfop.cod_cfo = '2407' then 'MG70000001'
                 when cfop.cod_cfo = '2556' then 'MG70000001'
                 when cfop.cod_cfo = '2910' then 'MG70000001'
                 when cfop.cod_cfo = '2911' then 'MG70000001'
                 when cfop.cod_cfo = '2932' then 'MG70000001'
                 when cfop.cod_cfo = '2949' then 'MG70000001'
                 when cfop.cod_cfo = '1406' then 'MG70000001'
                 when cfop.cod_cfo = '1551' then 'MG70000001'
                 when cfop.cod_cfo = '2406' then 'MG70000001'
                 when cfop.cod_cfo = '2551' then 'MG70000001'
                 

               end                           cod_ajuste_sped       ,  -- 13
               itens.discri_item                                   ,  -- 14
               itens.num_item                                      ,  -- 15
               null                          dsc_comp_ajuste       ,  -- 16
               null                          vlr_base_icms         ,  -- 17
               null                          aliquota_icms         ,  -- 18
               itens.vlr_outros1             vlr_icms              ,  -- 19
               null                          vlr_outros            ,  -- 20
               null                          num_processo          ,  -- 21
               null                          ind_gravacao             -- 22
        from   x08_base_merc             base   ,
               x08_trib_merc             trib   ,
               x08_itens_merc            itens  ,
               estabelecimento           estab  ,
               x2012_cod_fiscal          cfop
        where  itens.vlr_outros1        >  '0'
        and   estab.ident_estado        =  '61'   --> SOMENTE PARA ESTABELECIMENTOS DE MINAS GERAIS
        and   trib.cod_tributo          =  'ICMS'
        and   base.cod_tributo          =  'ICMS'
        and   base.cod_empresa          =  trib.cod_empresa
        and   base.cod_estab            =  trib.cod_estab
        and   base.data_fiscal          =  trib.data_fiscal
        and   base.movto_e_s            =  trib.movto_e_s
        and   base.norm_dev             =  trib.norm_dev
        and   base.ident_docto          =  trib.ident_docto
        and   base.ident_fis_jur        =  trib.ident_fis_jur
        and   base.num_docfis           =  trib.num_docfis
        and   base.serie_docfis         =  trib.serie_docfis
        and   base.sub_serie_docfis     =  trib.sub_serie_docfis
        and   base.discri_item          =  trib.discri_item
        and   itens.cod_empresa         =  trib.cod_empresa
        and   itens.cod_estab           =  trib.cod_estab
        and   itens.data_fiscal         =  trib.data_fiscal
        and   itens.movto_e_s           =  trib.movto_e_s
        and   itens.norm_dev            =  trib.norm_dev
        and   itens.ident_docto         =  trib.ident_docto
        and   itens.ident_fis_jur       =  trib.ident_fis_jur
        and   itens.num_docfis          =  trib.num_docfis
        and   itens.serie_docfis        =  trib.serie_docfis
        and   itens.sub_serie_docfis    =  trib.sub_serie_docfis
        and   itens.discri_item         =  trib.discri_item
        and   itens.cod_empresa         =  estab.cod_empresa
        and   itens.cod_estab           =  estab.cod_estab
        and   base.cod_empresa          =  estab.cod_empresa
        and   base.cod_estab            =  estab.cod_estab
        and   trib.cod_empresa          =  estab.cod_empresa
        and   trib.cod_estab            =  estab.cod_estab
        and   itens.ident_cfo           =  cfop.ident_cfo
        and   cfop.cod_cfo              in ('2352', '2353', '2407', '2556', '2910', '2911', '2932', '2949', '1406', '1551', '2406', '2551')
        and   itens.cod_empresa         = pcd_empr
        and   itens.cod_estab           = pcd_estab
        and   to_char(to_date(itens.data_fiscal, 'dd/mm/rrrr'), 'mm/rrrr') = to_char(to_date(pperiodo, 'dd/mm/rrrr'), 'mm/rrrr')) a
        where not exists                ( select 1
                                          from   x113_ajuste_apur x113
                                          where  x113.cod_empresa      = a.cod_empresa
                                          and    x113.cod_estab        = a.cod_estab
                                          and    x113.data_fiscal      = a.data_fiscal
                                          and    x113.movto_e_s        = a.movto_e_s
                                          and    x113.norm_dev         = a.norm_dev
                                          and    x113.ident_docto      = a.ident_docto
                                          and    x113.ident_fis_jur    = a.ident_fis_jur
                                          and    x113.num_docfis       = a.num_docfis
                                          and    x113.serie_docfis     = a.serie_docfis
                                          and    x113.sub_serie_docfis = a.sub_serie_docfis
                                          and    x113.discri_item      = a.discri_item
                                          and    x113.num_item         = a.num_item
                                          and    x113.ident_observacao = a.cod_observacao
                                          and    x113.ind_icompl_lancto= a.ind_icompl_lancto
                                          and    x113.cod_ajuste_sped  = a.cod_ajuste_sped);
     -- Relatório Cursor X113
      Cursor cur_3 is
  select distinct
               x113.cod_empresa,
               x113.cod_estab,
               x113.data_fiscal,
               x113.movto_e_s,
               x113.norm_dev,
               x2005.cod_docto,
               x04.ind_fis_jur,
               x04.cod_fis_jur,
               x2013.ind_produto ||'-'|| x2013.cod_produto as produto, -- Incluido por F2S em 24/07/2012, por solicitação do usuário
               x113.num_docfis,
               x113.serie_docfis,
               x113.sub_serie_docfis,
               x113.num_item,
               x2012.cod_cfo,
               x2006.cod_natureza_op,
               x2009.cod_observacao,
               x113.cod_ajuste_sped,
               x113.vlr_icms
        from   x113_ajuste_apur     x113,
               x2005_tipo_docto     x2005,
               x04_pessoa_fis_jur   x04,
               x2009_observacao     x2009,
               x2012_cod_fiscal     x2012,
               x2006_natureza_op    x2006,
               x08_itens_merc       x08,
               x2013_produto        x2013
        where  x113.ident_docto      = x2005.ident_docto
        and    x113.ident_fis_jur    = x04.ident_fis_jur
        and    x113.ident_observacao = x2009.ident_observacao
        and    x113.cod_empresa      = x08.cod_empresa
        and    x113.cod_estab        = x08.cod_estab
        and    x113.data_fiscal      = x08.data_fiscal
        and    x113.movto_e_s        = x08.movto_e_s
        and    x113.norm_dev         = x08.norm_dev
        and    x113.ident_docto      = x08.ident_docto
        and    x113.ident_fis_jur    = x08.ident_fis_jur
        and    x113.num_docfis       = x08.num_docfis
        and    x113.serie_docfis     = x08.serie_docfis
        and    x113.sub_serie_docfis = x08.sub_serie_docfis
        and    x113.num_item         = x08.num_item
        and    x113.discri_item      = x08.discri_item
        and    x08.ident_produto     = x2013.ident_produto
        and    x08.ident_cfo         = x2012.ident_cfo
        and    x08.ident_natureza_op = x2006.ident_natureza_op
        and    x113.cod_empresa      = pcd_empr
        and    x113.cod_estab        = pcd_estab
        and    to_char(to_date(x113.data_fiscal, 'dd/mm/rrrr'), 'mm/rrrr') = to_char(to_date(pperiodo, 'dd/mm/rrrr'), 'mm/rrrr');

     -- Relatório Critica - Dif Aliq Sem Item
      Cursor cur_4 is
        select distinct
               itens.cod_empresa                                   ,
               itens.cod_estab                                     ,
               itens.data_fiscal                                   ,
               itens.movto_e_s                                     ,
               itens.norm_dev                                      ,
               itens.ident_docto                                   ,
               docto.cod_docto                                     ,
               itens.ident_fis_jur                                 ,
               fornec.ind_fis_jur                                  ,
               fornec.cod_fis_jur                                  ,
               itens.num_docfis                                    ,
               itens.serie_docfis                                  ,
               itens.sub_serie_docfis                              ,
               cfop.cod_cfo                                        ,
               natur.cod_natureza_op                               ,
               itens.vlr_outros1         vlr_icms
        from   x07_base_docfis           base   ,
               x07_trib_docfis           trib   ,
               x07_docto_fiscal          itens  ,
               estabelecimento           estab  ,
               x2012_cod_fiscal          cfop   ,
               x2005_tipo_docto          docto  ,
               x04_pessoa_fis_jur        fornec,
               x2006_natureza_op         natur
        where  itens.vlr_outros1        >  '0'
        and   estab.ident_estado        =  '61'   --> SOMENTE PARA ESTABELECIMENTOS DE MINAS GERAIS
        and   trib.cod_tributo          =  'ICMS'
        and   base.cod_tributo          =  'ICMS'
        and   base.cod_empresa          =  trib.cod_empresa
        and   base.cod_estab            =  trib.cod_estab
        and   base.data_fiscal          =  trib.data_fiscal
        and   base.movto_e_s            =  trib.movto_e_s
        and   base.norm_dev             =  trib.norm_dev
        and   base.ident_docto          =  trib.ident_docto
        and   base.ident_fis_jur        =  trib.ident_fis_jur
        and   base.num_docfis           =  trib.num_docfis
        and   base.serie_docfis         =  trib.serie_docfis
        and   base.sub_serie_docfis     =  trib.sub_serie_docfis
        and   base.cod_tributo          =  trib.cod_tributo
        and   itens.cod_empresa         =  trib.cod_empresa
        and   itens.cod_estab           =  trib.cod_estab
        and   itens.data_fiscal         =  trib.data_fiscal
        and   itens.movto_e_s           =  trib.movto_e_s
        and   itens.norm_dev            =  trib.norm_dev
        and   itens.ident_docto         =  trib.ident_docto
        and   itens.ident_fis_jur       =  trib.ident_fis_jur
        and   itens.num_docfis          =  trib.num_docfis
        and   itens.serie_docfis        =  trib.serie_docfis
        and   itens.sub_serie_docfis    =  trib.sub_serie_docfis
        and   itens.cod_empresa         =  estab.cod_empresa
        and   itens.cod_estab           =  estab.cod_estab
        and   base.cod_empresa          =  estab.cod_empresa
        and   base.cod_estab            =  estab.cod_estab
        and   trib.cod_empresa          =  estab.cod_empresa
        and   trib.cod_estab            =  estab.cod_estab
        and   itens.ident_cfo           =  cfop.ident_cfo
        and   itens.ident_docto         =  docto.ident_docto
        and   itens.ident_natureza_op   =  natur.ident_natureza_op(+)
        and   itens.ident_fis_jur       =  fornec.ident_fis_jur
        and   cfop.cod_cfo              in ('2352', '2353', '2407', '2556', '2910', '2911', '2932', '2949', '1406', '1551', '2406', '2551')
        and   itens.cod_empresa         = pcd_empr
        and   itens.cod_estab           = pcd_estab
        and   to_char(to_date(itens.data_fiscal, 'dd/mm/rrrr'), 'mm/rrrr') = to_char(to_date(pperiodo, 'dd/mm/rrrr'), 'mm/rrrr')
        and    not exists               (select 1
                                         from   x08_itens_merc x08
                                         where  x08.cod_empresa          =  itens.cod_empresa
                                         and    x08.cod_estab            =  itens.cod_estab
                                         and    x08.data_fiscal          =  itens.data_fiscal
                                         and    x08.movto_e_s            =  itens.movto_e_s
                                         and    x08.norm_dev             =  itens.norm_dev
                                         and    x08.ident_docto          =  itens.ident_docto
                                         and    x08.ident_fis_jur        =  itens.ident_fis_jur
                                         and    x08.num_docfis           =  itens.num_docfis
                                         and    x08.serie_docfis         =  itens.serie_docfis
                                         and    x08.sub_serie_docfis     =  itens.sub_serie_docfis);

    /* Variáveis de Trabalho */
    mLinha            varchar2(400);
    mproc_id          INTEGER;
    v_linha           number(5) := 0;
    v_per_encerrado_f char(1);
    v_grupo_fiscal    char(1);
    v_data_fech       prt_fecha_grp.dt_fechamento%type;
    v_total_icms      x113_ajuste_apur.vlr_icms%type := 0;

  BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_CARGA_X113_CPROC', 48, 150);

    BEGIN

if ptipo = '1' then

     begin
          select a.cod_grupo,
                 a.dt_fechamento
          into   v_grupo_fiscal,
                 v_data_fech
          from   prt_fecha_grp a,
                 brt_grupo     b
          where  a.cod_grupo     = b.cod_grupo
          and    a.cod_empresa   = pcd_empr
          and    a.cod_estab     = pcd_estab
          and    a.cod_grupo     = '3'
          and    to_char(to_date(a.dt_fechamento, 'dd/mm/rrrr'), 'mm/rrrr') >= to_char(to_date(last_day(pperiodo), 'dd/mm/rrrr'), 'mm/rrrr');
     exception when others then
       v_per_encerrado_f := 'N';
       lib_proc.add_log('Período Fiscal '||pperiodo||' aberto para a empresa '||pcd_empr||' Estab: '||pcd_estab, 1);
       lib_proc.add_log('A carga não pode ser gerada com o período fiscal aberto.', 1);
     end;

    if v_grupo_fiscal = '3' then
       v_per_encerrado_f := 'S';
    end if;

  if to_char(last_day(pperiodo), 'dd/mm/rrrr') <> to_char(v_data_fech, 'dd/mm/rrrr') then

     lib_proc.add_log('Período fiscal está encerrado, não pode ser gerado o relatório de movimento. ', 1);

     LIB_PROC.CLOSE();

    RETURN mproc_id;

  end if;

  if to_char(last_day(pperiodo), 'dd/mm/rrrr') = to_char(v_data_fech, 'dd/mm/rrrr') then

   if v_per_encerrado_f = 'S' then

   FOR mreg IN cur_1 LOOP

   begin
      insert into x112_obs_docfis (cod_empresa       , -- 01
                                   cod_estab         , -- 02
                                   data_fiscal       , -- 03
                                   movto_e_s         , -- 04
                                   norm_dev          , -- 05
                                   ident_docto       , -- 06
                                   ident_fis_jur     , -- 07
                                   num_docfis        , -- 08
                                   serie_docfis      , -- 09
                                   sub_serie_docfis  , -- 10
                                   ident_observacao  , -- 11
                                   ind_icompl_lancto , -- 12
                                   dsc_complementar  , -- 13
                                   num_processo      , -- 14
                                   ind_gravacao      , -- 15
                                   vinculacao        ) -- 16
                            values(mreg.cod_empresa        ,  -- 01
                                   mreg.cod_estab          ,  -- 02
                                   mreg.data_fiscal        ,  -- 03
                                   mreg.movto_e_s          ,  -- 04
                                   mreg.norm_dev           ,  -- 05
                                   mreg.ident_docto        ,  -- 06
                                   mreg.ident_fis_jur      ,  -- 07
                                   mreg.num_docfis         ,  -- 08
                                   mreg.serie_docfis       ,  -- 09
                                   mreg.sub_serie_docfis   ,  -- 10
                                   mreg.cod_observacao     ,  -- 11
                                   mreg.ind_icompl_lancto  ,  -- 12
                                   mreg.dsc_complementar   ,  -- 13
                                   mreg.num_processo       ,  -- 14
                                   mreg.ind_gravacao       ,  -- 15
                                   mreg.vinculacao);          -- 16
   exception when others then
    lib_proc.add_log('X112-Registro não inserido Emp: '||mreg.cod_empresa||' Estab: '||mreg.cod_estab||
                     ' Nota: '||mreg.num_docfis||' Ser: '||mreg.serie_docfis||' Dt: '||mreg.data_fiscal||
                     ' - '||sqlerrm, 1);
   end;

         v_linha := v_linha + 1;

   end loop;

  FOR mreg IN cur_2 LOOP
   begin
      insert into x113_ajuste_apur (cod_empresa             , -- 01
                                    cod_estab               , -- 02
                                    data_fiscal             , -- 03
                                    movto_e_s               , -- 04
                                    norm_dev                , -- 05
                                    ident_docto             , -- 06
                                    ident_fis_jur           , -- 07
                                    num_docfis              , -- 08
                                    serie_docfis            , -- 09
                                    sub_serie_docfis        , -- 11
                                    ident_observacao        , -- 12
                                    ind_icompl_lancto       , -- 13
                                    cod_ajuste_sped         , -- 14
                                    discri_item             , -- 15
                                    num_item                , -- 16
                                    dsc_comp_ajuste         , -- 17
                                    vlr_base_icms           , -- 18
                                    aliquota_icms           , -- 19
                                    vlr_icms                , -- 20
                                    vlr_outros              , -- 21
                                    num_processo            , -- 22
                                    ind_gravacao)             -- 23
                             values(mreg.cod_empresa        , -- 01
                                    mreg.cod_estab               , -- 02
                                    mreg.data_fiscal             , -- 03
                                    mreg.movto_e_s               , -- 04
                                    mreg.norm_dev                , -- 05
                                    mreg.ident_docto             , -- 06
                                    mreg.ident_fis_jur           , -- 07
                                    mreg.num_docfis              , -- 08
                                    mreg.serie_docfis            , -- 09
                                    mreg.sub_serie_docfis        , -- 11
                                    mreg.cod_observacao          , -- 12
                                    mreg.ind_icompl_lancto       , -- 13
                                    mreg.cod_ajuste_sped         , -- 14
                                    mreg.discri_item             , -- 15
                                    mreg.num_item                , -- 16
                                    mreg.dsc_comp_ajuste         , -- 17
                                    mreg.vlr_base_icms           , -- 18
                                    mreg.aliquota_icms           , -- 19
                                    mreg.vlr_icms                , -- 20
                                    mreg.vlr_outros              , -- 21
                                    mreg.num_processo            , -- 22
                                    mreg.ind_gravacao);            -- 23
   exception when others then
    lib_proc.add_log('X113-Registro não inserido Emp: '||mreg.cod_empresa||' Estab: '||mreg.cod_estab||
                     ' Nota: '||mreg.num_docfis||' Ser: '||mreg.serie_docfis||' Dt: '||mreg.data_fiscal||
                     ' - '||sqlerrm, 1);
   end;

         v_linha := v_linha + 1;

   end loop;
   end if;
   end if;


elsif ptipo = '2' then

    LIB_PROC.add_tipo(mproc_id, 1, 'Relatório de Críticas', 1);

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, lpad('=', 150, '='), 1);
        LIB_PROC.add(mLinha, null, null, 1);

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, 'EMP', 1);
        mLinha := LIB_STR.w(mLinha, '|', 4);
        mLinha := LIB_STR.w(mLinha, 'ESTAB', 5);
        mLinha := LIB_STR.w(mLinha, '|', 11);
        mLinha := LIB_STR.w(mLinha, 'DATA', 12);
        mLinha := LIB_STR.w(mLinha, '|', 22);
        mLinha := LIB_STR.w(mLinha, 'MOVTO', 23);
        mLinha := LIB_STR.w(mLinha, '|', 29);
        mLinha := LIB_STR.w(mLinha, 'NORM_DEV', 30);
        mLinha := LIB_STR.w(mLinha, '|', 38);
        mLinha := LIB_STR.w(mLinha, 'DOCTO', 39);
        mLinha := LIB_STR.w(mLinha, '|', 44);
        mLinha := LIB_STR.w(mLinha, 'FORNECEDOR', 45);
        mLinha := LIB_STR.w(mLinha, '|', 59);
        mLinha := LIB_STR.w(mLinha, 'NF/SER/SUB', 60);
        mLinha := LIB_STR.w(mLinha, '|', 78);
        mLinha := LIB_STR.w(mLinha, 'ITEM', 79);
        mLinha := LIB_STR.w(mLinha, '|', 83);
        mLinha := LIB_STR.w(mLinha, 'CFOP/NAT', 84);
        mLinha := LIB_STR.w(mLinha, '|', 93);
        mLinha := LIB_STR.w(mLinha, 'COD_OBS', 94);
        mLinha := LIB_STR.w(mLinha, '|', 100);
        mLinha := LIB_STR.w(mLinha, 'COD_AJUSTE_SPED', 101);
        mLinha := LIB_STR.w(mLinha, '|', 112);
        mLinha := LIB_STR.w(mLinha, 'VLR ICMS', 113);
        mLinha := LIB_STR.w(mLinha, '|', 130);
        mLinha := LIB_STR.w(mLinha, 'PRODUTO', 131); -- INCLUSAO DO IND PRODUTO + COD_PRODUTO em 24/07/2012
        mLinha := LIB_STR.w(mLinha, '|', 150);
        
        

        LIB_PROC.add(mLinha, null, null, 1);

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, lpad('=', 150, '='), 1);
        LIB_PROC.add(mLinha, null, null, 1);

     for mreg in CUR_3 LOOP

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
        mLinha := LIB_STR.w(mLinha, '|', 4);
        mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
        mLinha := LIB_STR.w(mLinha, '|', 11);
        mLinha := LIB_STR.w(mLinha, mreg.data_fiscal, 12);
        mLinha := LIB_STR.w(mLinha, '|', 22);
        mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 23);
        mLinha := LIB_STR.w(mLinha, '|', 29);
        mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 30);
        mLinha := LIB_STR.w(mLinha, '|', 38);
        mLinha := LIB_STR.w(mLinha, mreg.cod_docto, 39);
        mLinha := LIB_STR.w(mLinha, '|', 44);
        mLinha := LIB_STR.w(mLinha, mreg.ind_fis_jur||'-'||mreg.cod_fis_jur, 45);
        mLinha := LIB_STR.w(mLinha, '|', 59);
        mLinha := LIB_STR.w(mLinha, mreg.num_docfis||'-'||mreg.serie_docfis||'-'||mreg.sub_serie_docfis, 60);
        mLinha := LIB_STR.w(mLinha, '|', 78);
        mLinha := LIB_STR.w(mLinha, mreg.num_item, 79);
        mLinha := LIB_STR.w(mLinha, '|', 83);
        mLinha := LIB_STR.w(mLinha, mreg.cod_cfo||'-'||mreg.cod_natureza_op, 84);
        mLinha := LIB_STR.w(mLinha, '|', 93);
        mLinha := LIB_STR.w(mLinha, mreg.cod_observacao, 94);
        mLinha := LIB_STR.w(mLinha, '|', 100);
        mLinha := LIB_STR.w(mLinha, mreg.cod_ajuste_sped, 101);
        mLinha := LIB_STR.w(mLinha, '|', 112);
        mLinha := LIB_STR.w(mLinha, replace(to_char(mreg.vlr_icms, '999999990.00'), '.', ','), 113);
        mLinha := LIB_STR.w(mLinha, '|', 130);
        mLinha := LIB_STR.w(mLinha, mreg.produto, 131); -- INCLUSAO DO IND_PRODUTO + PRODUTO em 24/07/2012
        mLinha := LIB_STR.w(mLinha, '|', 150);
 

        v_total_icms := mreg.vlr_icms + v_total_icms;

        v_linha := v_linha + 1;

        LIB_PROC.add(mLinha, null, null, 1);
     end loop;

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, 'TOTAL: ', 1);
        mLinha := LIB_STR.w(mLinha, replace(replace(replace(to_char(v_total_icms, '999,999,990.00'), '.', '*'), ',', '.'), '*', ','), 113);

        LIB_PROC.add(mLinha, null, null, 1);

elsif ptipo = '3' then

    LIB_PROC.add_tipo(mproc_id, 1, 'Relatório de Críticas', 1);

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, lpad('=', 150, '='), 1);
        LIB_PROC.add(mLinha, null, null, 1);

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, 'EMP', 1);
        mLinha := LIB_STR.w(mLinha, '|', 4);
        mLinha := LIB_STR.w(mLinha, 'ESTAB', 5);
        mLinha := LIB_STR.w(mLinha, '|', 11);
        mLinha := LIB_STR.w(mLinha, 'DATA', 12);
        mLinha := LIB_STR.w(mLinha, '|', 22);
        mLinha := LIB_STR.w(mLinha, 'MOVTO', 23);
        mLinha := LIB_STR.w(mLinha, '|', 29);
        mLinha := LIB_STR.w(mLinha, 'NORM_DEV', 30);
        mLinha := LIB_STR.w(mLinha, '|', 38);
        mLinha := LIB_STR.w(mLinha, 'DOCTO', 39);
        mLinha := LIB_STR.w(mLinha, '|', 44);
        mLinha := LIB_STR.w(mLinha, 'FORNECEDOR', 45);
        mLinha := LIB_STR.w(mLinha, '|', 59);
        mLinha := LIB_STR.w(mLinha, 'NF/SER/SUB', 60);
        mLinha := LIB_STR.w(mLinha, '|', 78);
        mLinha := LIB_STR.w(mLinha, 'CFOP/NAT', 79);
        mLinha := LIB_STR.w(mLinha, '|', 93);
        mLinha := LIB_STR.w(mLinha, 'VLR ICMS', 94);
        mLinha := LIB_STR.w(mLinha, '|', 130);

        LIB_PROC.add(mLinha, null, null, 1);

        mLinha := LIB_STR.w('', ' ', 1);
        mLinha := LIB_STR.w(mLinha, lpad('=', 150, '='), 1);
        LIB_PROC.add(mLinha, null, null, 1);

     for mreg in CUR_4 LOOP

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, mreg.cod_empresa, 1);
        mLinha := LIB_STR.w(mLinha, '|', 4);
        mLinha := LIB_STR.w(mLinha, mreg.cod_estab, 5);
        mLinha := LIB_STR.w(mLinha, '|', 11);
        mLinha := LIB_STR.w(mLinha, mreg.data_fiscal, 12);
        mLinha := LIB_STR.w(mLinha, '|', 22);
        mLinha := LIB_STR.w(mLinha, mreg.movto_e_s, 23);
        mLinha := LIB_STR.w(mLinha, '|', 29);
        mLinha := LIB_STR.w(mLinha, mreg.norm_dev, 30);
        mLinha := LIB_STR.w(mLinha, '|', 38);
        mLinha := LIB_STR.w(mLinha, mreg.cod_docto, 39);
        mLinha := LIB_STR.w(mLinha, '|', 44);
        mLinha := LIB_STR.w(mLinha, mreg.ind_fis_jur||'-'||mreg.cod_fis_jur, 45);
        mLinha := LIB_STR.w(mLinha, '|', 59);
        mLinha := LIB_STR.w(mLinha, mreg.num_docfis||'-'||mreg.serie_docfis||'-'||mreg.sub_serie_docfis, 60);
        mLinha := LIB_STR.w(mLinha, '|', 78);
        mLinha := LIB_STR.w(mLinha, mreg.cod_cfo||'-'||mreg.cod_natureza_op, 79);
        mLinha := LIB_STR.w(mLinha, '|', 93);
        mLinha := LIB_STR.w(mLinha, replace(to_char(mreg.vlr_icms, '999999990.00'), '.', ','), 94);
        mLinha := LIB_STR.w(mLinha, '|', 130);

        v_total_icms := mreg.vlr_icms + v_total_icms;

        v_linha := v_linha + 1;

        LIB_PROC.add(mLinha, null, null, 1);
     end loop;

        mLinha := null;
        mLinha := LIB_STR.w(mLinha, 'TOTAL: ', 1);
        mLinha := LIB_STR.w(mLinha, replace(replace(replace(to_char(v_total_icms, '999,999,990.00'), '.', '*'), ',', '.'), '*', ','), 113);

        LIB_PROC.add(mLinha, null, null, 1);

end if;

    END;

  if ptipo = '1' then
      if v_linha = 0 then
       lib_proc.add_log('Não há registros para processar de acordo com os critérios selecionados. ', 1);
      else
       lib_proc.add_log('Gravacao do arquivo concluída! Foram gravados '||v_linha||' registros ', 1);
      end if;
  elsif ptipo = '2' then
      if v_linha = 0 then
       lib_proc.add_log('Não há rgistros para o período selecionado.', 1);
      else
       lib_proc.add_log('Relatório gerado! Foram processados '||v_linha||' registros ', 1);
      end if;
  end if;

     LIB_PROC.CLOSE();

    RETURN mproc_id;
  END;

END MSAF_CARGA_X113_CPROC;
/
