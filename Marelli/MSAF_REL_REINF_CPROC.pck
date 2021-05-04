create or replace package MSAF_REL_REINF_CPROC is

  -- Autor   : Paulo Ribeiro
  -- Created : 02/10/2018
  -- Purpose : Relatório de Conferência Sped Reinf - INSS
  -- Parametros : Empresa, Data Inicio, Data Fim

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */

  function parametros return varchar2;
  function nome return varchar2;
  function tipo return varchar2;
  function versao return varchar2;
  function descricao return varchar2;
  function modulo return varchar2;
  function classificacao return varchar2;

  function executar (pcd_empr      varchar2,
                     pdt_inicio    date,
                     pdt_final     date) return integer;

end MSAF_REL_REINF_CPROC;
/
create or replace package body MSAF_REL_REINF_CPROC is

  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;


  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);

  BEGIN
    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('USUARIO');

    LIB_PROC.add_param(pstr, 'Empresa', 'Varchar2',
                             'Combobox', 'S', NULL, NULL,
                             'SELECT e.cod_empresa,e.cod_empresa  || '' - '' || e.razao_social FROM empresa e where cod_empresa = '''||mcod_empresa||''' order by 1' );

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
                         
  LIB_PROC.add_param(pstr, ' ', 'varchar2'  , 'text'  , 'N', null   , null) ;
  lib_proc.add_param(pstr, 'ATENÇÃO: Antes da Geração dos Eventos Equalizar o Data Mart', 'varchar2'  , 'text'  , 'N', null   , null) ;
    
    RETURN pstr;
  END;

FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Sped Reinf - INSS';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'V1R1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatório de Validacao Sped Reinf - Inss';
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
                     pdt_inicio    date,
                     pdt_final     date) RETURN INTEGER IS

    /* Variáveis de Trabalho */
    mproc_id         INTEGER;
    mLinha           VARCHAR2(4000);
    v_linha          number(5)  := 0;
    vTab             varchar2(1):= chr(9);
    v_reg            varchar2(7000);
    v_reg_c          varchar2(7000);

CURSOR ict_1 is
-- RELACIONA E CALCULA SAFX07 E SAFX09
SELECT a.emp_x07     empresa,
       a.estab_x07   estabelecimento,
       a.movt_x07    ent_saida,
       a.cod_x07     cnpj_prestador,
       (case when length(a.cod_x07) = '11' then 'PF'else 'PJ' end) tp_prestador,
       a.name_x07    razao_social,
       a.comp_x07    competencia,
       a.lancto_x07  data_reg,
       a.nf_x07      nota_fiscal,
       a.base_x07    base_inss_capa,
       a.aliq_x07    aliq_inss_capa,
       a.inss_x07    vlr_inss_capa,      
       b.base_x09    base_inss_item,
       b.aliq_x09    aliq_inss_item,
       b.inss_x09    vlr_inss_item,
       (a.base_x07-b.base_x09) dif_base,
       (a.inss_x07-b.inss_x09) dif_inss,
       'nf_servicos'           tp_lancto    


 from (select   x07.cod_empresa                      emp_x07, 
                x07.cod_estab                        estab_x07,
                x07.data_emissao                     comp_x07,
                x07.data_fiscal                      lancto_x07,
                x04.cpf_cgc                          cod_x07,
                x04.razao_social                     name_x07,
                decode(x07.movto_e_s, '9', 'SAIDA','ENTRADA') movt_x07,
                x07.num_docfis                       nf_x07,                 
                x07.vlr_base_inss                    base_x07,
                x07.vlr_aliq_inss                    aliq_x07, 
                x07.vlr_inss_retido                  inss_x07 -- somatória de imposto de inss
    
    from x07_docto_fiscal X07, 
         x04_pessoa_fis_jur x04
    where 1=1
      AND SITUACAO = 'N' -- considera apenas notas não canceladas
      and vlr_base_inss > 0 -- com valor de base de inss maior que 0
      and x04.ident_fis_jur = x07.ident_fis_jur -- Utilizo a X04 para apresentar apenas pessoa juridica no calculo de valores
      and data_fiscal  between pdt_inicio and pdt_final -- Período a ser analisado
      and x07.cod_class_doc_fis <> '1'
      and x07.cod_empresa = pcd_empr) a,    
     (select   x09.cod_empresa      emp_x09, 
                  x09.cod_estab        estab_x09,
                  x04.cpf_cgc          cod_x09,
                  x04.razao_social     name_x09,
                  x09.num_docfis       nf_x09, 
              sum(x09.vlr_base_inss)   base_x09,  -- somatória de base de inss
                  x09.vlr_aliq_inss    aliq_x09,
              sum(x09.vlr_inss_retido) inss_x09 -- somatória de imposto de inss
   
  from x09_itens_serv x09, 
       x07_docto_fiscal x07, 
       x04_pessoa_fis_jur x04, 
       x2018_servicos x2018
    where 1=1
      and x09.data_fiscal  between pdt_inicio and pdt_final -- Período a ser analisado
      and x07.cod_empresa = pcd_empr
      and x07.cod_empresa = x09.cod_empresa -- Relaciono X07 com X09
      and x07.cod_estab = x09.cod_estab
      and x07.data_fiscal = x09.data_fiscal
      and x07.movto_e_s = x09.movto_e_s
      and x07.norm_dev = x09.norm_dev
      and x07.num_docfis = x09.num_docfis
      and x07.serie_docfis = x09.serie_docfis
      and x07.ident_fis_jur = x09.ident_fis_jur
      and x09.ident_servico = x2018.ident_servico
      and x07.situacao = 'N' -- considera apenas notas não canceladas
      and x09.vlr_base_inss > 0 -- com valor de base de inss maior que 0
      and x04.ident_fis_jur = x09.ident_fis_jur -- Utilizo a X04 para apresentar apenas pessoa juridica no calculo de valores
    group by x09.cod_empresa, 
             x09.cod_estab, 
             x04.cpf_cgc, 
             x04.razao_social, 
             x09.vlr_aliq_inss, 
             x09.num_docfis) b

where a.emp_x07 = b.emp_x09 (+)
and   a.estab_x07 = b.estab_x09 (+) 
and   a.cod_x07 = b.cod_x09 (+)
and   a.aliq_x07 = b.aliq_x09 (+)
and   a.nf_x07 = b.nf_x09 (+)

UNION ALL

-- RELACIONA E CALCULA SAFX07 E SAFX08
SELECT a.emp_x07       empresa,
       a.estab_x07     estabelecimento,
       a.movt_x07      ent_saida,
       a.cod_x07       cnpj_prestador,
       (case when length(a.cod_x07) = '11' 
             then 'PF'else 'PJ' end) tp_prestador,
       a.name_x07      razao_social,
       a.comp_x07      competencia,
       a.lancto_x07    data_reg,
       a.nf_x07        nota_fiscal,
       a.base_x07      base_inss_capa,
       a.aliq_x07      aliq_inss_capa,
       a.inss_x07      vlr_inss_capa,      
       b.base_x08      base_inss_item,
       b.aliq_x08      aliq_inss_item,
       b.inss_x08      vlr_inss_item,
       (a.base_x07-b.base_x08) dif_base,
       (a.inss_x07-b.inss_x08) dif_inss,
       'nf_mercadoria'         tp_lancto

 from (select   x07.cod_empresa        emp_x07, 
                x07.cod_estab          estab_x07,
                x07.data_emissao       comp_x07,
                x07.data_fiscal        lancto_x07,
                decode(x07.movto_e_s, '9', 'SAIDA','ENTRADA') movt_x07,
                x04.cpf_cgc            cod_x07,
                x04.razao_social       name_x07,
                x07.num_docfis         nf_x07,                 
                x07.vlr_base_inss      base_x07,
                x07.vlr_aliq_inss      aliq_x07, 
                x07.vlr_inss_retido    inss_x07 -- somatória de imposto de inss
    
    from x07_docto_fiscal X07, 
         x04_pessoa_fis_jur x04
    where 1=1
      AND SITUACAO = 'N' -- considera apenas notas não canceladas
      and vlr_base_inss > 0 -- com valor de base de inss maior que 0
      and x04.ident_fis_jur = x07.ident_fis_jur -- Utilizo a X04 para apresentar apenas pessoa juridica no calculo de valores
      and data_fiscal  between pdt_inicio and pdt_final -- Período a ser analisado
      and x07.cod_class_doc_fis = '1'
      and x07.cod_empresa = pcd_empr) a,
 (select   x08.cod_empresa      emp_x08, 
                  x08.cod_estab        estab_x08,
                  x04.cpf_cgc          cod_x08,
                  x04.razao_social     name_x08,
                  x08.num_docfis       nf_x08, 
              sum(x08.vlr_base_inss)   base_x08,  -- somatória de base de inss
                  x08.vlr_aliq_inss    aliq_x08,
              sum(x08.vlr_inss_retido) inss_x08 -- somatória de imposto de inss
   
  from x08_itens_merc x08, 
       x07_docto_fiscal x07, 
       x04_pessoa_fis_jur x04, 
       x2013_produto x2013
    where 1=1
      and x08.data_fiscal  between pdt_inicio and pdt_final -- Período a ser analisado
      and x08.cod_empresa = pcd_empr
      and x07.ident_fis_jur = x04.ident_fis_jur
      and x08.ident_fis_jur = x04.ident_fis_jur
      and x07.cod_empresa = x08.cod_empresa -- Relaciono X07 com X09
      and x07.cod_estab = x08.cod_estab
      and x07.data_fiscal = x08.data_fiscal
      and x07.movto_e_s = x08.movto_e_s
      and x07.norm_dev = x08.norm_dev
      and x07.num_docfis = x08.num_docfis
      and x07.serie_docfis = x08.serie_docfis
      and x07.ident_fis_jur = x08.ident_fis_jur
      and x08.ident_produto = x2013.ident_produto
      and x07.situacao = 'N' -- considera apenas notas não canceladas
      and x07.vlr_base_inss > 0 -- com valor de base de inss maior que 0      
    group by x08.cod_empresa, 
             x08.cod_estab, 
             x04.cpf_cgc, 
             x04.razao_social, 
             x08.num_docfis, 
             x08.vlr_aliq_inss) b

where a.emp_x07 = b.emp_x08 (+)
and   a.estab_x07 = b.estab_x08 (+) 
and   a.cod_x07 = b.cod_x08 (+)
and   a.aliq_x07 = b.aliq_x08 (+)
and   a.nf_x07 = b.nf_x08 (+)

order by 1,2;


BEGIN
    -- Cria Processo
    mproc_id := LIB_PROC.new('MSAF_REL_REINF_CPROC', 48, 150);
    LIB_PROC.add_tipo(mproc_id, 2, 'ARQUIVO_REINF_EVENT', 2);

    BEGIN

         v_reg_c :=     'EMPRESA'           ||vTab||
                        'ESTABELECIMENTO'   ||vTab||
      'ENT_SAIDA'         ||vTab||
			'CNPJ_PRESTADOR'    ||vTab||
			'TP_PRESTADOR'      ||vTab||
			'RAZAO_SOCIAL'      ||vTab||
			'COMPETENCIA'       ||vTab||
      'DATA_LANCTO'       ||vTab||
			'NOTA_FISCAL'       ||vTab||
			'BASE_INSS_CAPA'    ||vTab||
			'ALIQ_INSS_CAPA'    ||vTab||
			'VLR_INSS_CAPA'     ||vTab||
			'BASE_INSS_ITEM'    ||vTab||
			'ALIQ_INSS_ITEM'    ||vTab||
			'VLR_INSS_ITEM'     ||vTab||
			'DIF_BASE'          ||vTab||
			'DIF_INSS'          ||vTab||
			'TP_LANCTO';

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg_c, 2);

          LIB_PROC.add(mLinha, null, null, 2);

      FOR mreg IN ict_1 LOOP

          v_reg :=  mreg.empresa           ||vTab||
                    mreg.estabelecimento   ||vTab||
                    mreg.ent_saida         ||vTab||
                    mreg.cnpj_prestador    ||vTab||
                    mreg.tp_prestador      ||vTab||
                    mreg.razao_social      ||vTab||
                    mreg.competencia       ||vTab||
                    mreg.data_reg          ||vTab||
                    mreg.nota_fiscal       ||vTab||
                    trim(translate(to_char(mreg.base_inss_capa, '999999999999d00'), '.', ','))    ||vTab||
                    trim(translate(to_char(mreg.aliq_inss_capa, '999d0000'), '.', ','))           ||vTab||
                    trim(translate(to_char(mreg.vlr_inss_capa, '999999999999d00'), '.', ','))     ||vTab||
                    trim(translate(to_char(mreg.base_inss_item, '999999999999d00'), '.', ','))    ||vTab||
                    trim(translate(to_char(mreg.aliq_inss_item, '999d0000'), '.', ','))           ||vTab||
                    trim(translate(to_char(mreg.vlr_inss_item, '999999999999d00'), '.', ','))     ||vTab||
                    trim(translate(to_char(mreg.dif_base, '999999999999d00'), '.', ','))          ||vTab||
                    trim(translate(to_char(mreg.dif_inss, '999999999999d00'), '.', ','))          ||vTab||
                    mreg.tp_lancto;

          mLinha := null;
          mLinha := LIB_STR.w(mLinha, v_reg, 1);

          LIB_PROC.add(mLinha, null, null, 2);

         v_linha := v_linha + 1;

          v_reg := null;

      END LOOP;

          mLinha := null;
          LIB_PROC.add(mLinha, null, null, 2);

          mLinha := null;
          mLinha := LIB_STR.wcenter(mLinha, 'Foram Processadas '||v_linha||' linhas.', 150);
          LIB_PROC.add(mLinha, null, null, 2);
          

    END;

    if v_linha = 0 then
     lib_proc.add_log('Não há registros para processar de acordo com os critérios selecionados. ', 1);
    else
     lib_proc.add_log('Geração do relatório concluída! Foram gravados '||v_linha||' registros ', 1);
    end if;

     LIB_PROC.CLOSE();

    RETURN mproc_id;
  END;

END MSAF_REL_REINF_CPROC;
/
