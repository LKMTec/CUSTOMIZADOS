CREATE OR REPLACE PACKAGE GSR_ARQREL_PIS_COFINS_CPROC IS

  -- autor   : Everton Zamarioli
  -- created : 23/03/2011
  -- purpose : PIS/COFINS

  /* VARIÁVEIS DE CONTROLE DE CABEÇALHO DE RELATÓRIO */
    FUNCTION Parametros RETURN VARCHAR2;
    FUNCTION Nome RETURN VARCHAR2;
    FUNCTION Tipo RETURN VARCHAR2;
    FUNCTION Versao RETURN VARCHAR2;
    FUNCTION Descricao RETURN VARCHAR2;
    FUNCTION Modulo RETURN VARCHAR2;
    FUNCTION Classificacao RETURN VARCHAR2;

    FUNCTION Executar(pd_data_ini      date
                    , pd_data_fim      date
                    , pind_geracao     char
                    , pind_consol      char
                    , pind_ivecore     char
                    , pind_sapiens     char
                    , pind_powersap    char
                    , pind_mainframe   char
                    , pind_outros      char
                    , pcod_estab       LIB_PROC.varTab
                  ) RETURN INTEGER;


    PROCEDURE teste_rel ;



END GSR_ARQREL_PIS_COFINS_CPROC;
/
CREATE OR REPLACE PACKAGE BODY GSR_ARQREL_PIS_COFINS_CPROC IS

  mcod_empresa empresa.cod_empresa%TYPE;
  musuario     usuario_estab.cod_usuario%TYPE;
    vs_linha                   varchar2(4000);
    vs_tab                     char(1) := chr(9);

-- 001
-- Fabio Freitas
-- 21/01/2014
-- Ajuste Campo DAT LANCTO PIS COFINS X09

    vs_ind_ivecore     char := 'N';
    vs_ind_sapiens     char := 'N';
    vs_ind_powersap    char := 'N';
    vs_ind_mainframe   char := 'N';
    vs_ind_outros      char := 'N';
    vn_qtd_reg         number := 0;
    vn_qtd_reg_serv    number := 0;
    vn_qtd_reg_consol  number := 0;

  procedure gera_merc_ivecore (vs_cod_estab  varchar2
                             , vd_data_ini   date
                             , vd_data_fim   date)is



   cursor c_dados_merc (c_cod_estab  varchar2

                 , c_data_ini   date
                 , c_data_fim   date) is

      select 'ITEM'                   tipo_reg
           , x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x08.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x08.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item Incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x08.num_docfis           NUMERO_NF
           , x08.serie_docfis         SERIE_NF
           , x08.num_item             NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , x2013.ind_produto        IND_PRODUTO -- NOVA INCLUSÃO
           , x2013.cod_produto        CODIGO_PRODUTO
           , x2013.descricao          DESCRICAO
           , x2013.CLAS_ITEM          CLAS_ITEM -- Item Incluído 08/08/2016
           , nvl(x2043.cod_nbm,' ')   CODIGO_NBM
           , x08.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x08.vlr_contab_item      VALOR_CONTABIL
           , x08.aliq_tributo_icms    ALIQ_ICMS
           , x08.vlr_base_icms_1      BASE_ICMS_1
           , x08.vlr_base_icms_2      BASE_ICMS_2
           , x08.vlr_base_icms_3      BASE_ICMS_3
           , x08.vlr_base_icms_4      BASE_ICMS_4
           , x08.vlr_tributo_icms     VALOR_ICMS
           , x08.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x08.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , x08.VLR_FCP_UF_DEST      VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_DEST     VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_ORIG     VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , x08.Vlr_Icmss_Ndestac    VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , x08.Vlr_Icmss_n_Escrit   VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x08.aliq_tributo_ipi     ALIQ_IPI
           , x08.vlr_base_ipi_1       BASE_IPI_1
           , x08.vlr_base_ipi_2       BASE_IPI_2
           , x08.vlr_base_ipi_3       BASE_IPI_3
           , x08.vlr_base_ipi_4       BASE_IPI_4
           , x08.vlr_tributo_ipi      VALOR_IPI
           , x08.cod_situacao_pis     COD_SIT_PIS
           , x08.vlr_aliq_pis         ALIQ_PIS
           , x08.vlr_base_pis         BASE_PIS
           , x08.vlr_pis              VLR_PIS
           , x08.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_cofins  COD_SIT_COFINS
           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , x08.vlr_base_cofins      BASE_COFINS
           , x08.vlr_cofins           VALOR_COFINS
           , x08.vlr_frete            VLR_FRETE --NOVA INCLUSÃO 24-08--
           , x08.vlr_seguro           VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , x08.vlr_outras           VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , x08.ind_natureza_frete   NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , x08.CHASSI               CHASSI   -- Item Incluido 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , x08.base_icms_origdest   BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x08.vlr_icms_origdest    VLR_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , x2003.cod_custo          CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x08.vlr_tributo_icmss
           , x08.aliq_tributo_icmss
           , x08.vlr_base_icmss
           , x08.cod_trib_ipi
           , x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , x2017.cod_und_padrao     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , x2007.cod_medida         COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , x08.quantidade           QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , x08.VLR_ITEM
           , x08.VLR_UNIT             VLR_UNIT -- Item Incluido 08/08/2016
           , x08.COD_SITUACAO_PIS_ST
           , x08.VLR_BASE_PIS_ST
           , x08.VLR_ALIQ_PIS_ST
           , x08.VLR_PIS_ST
           , x08.COD_SITUACAO_COFINS_ST
           , x08.VLR_BASE_COFINS_ST
           , x08.VLR_ALIQ_COFINS_ST
           , x08.VLR_COFINS_ST
           , x08.DAT_LANC_PIS_COFINS
           , x08.USUARIO             USUARIO --  Item Incluido 08/08/2016
           , X08.DAT_OPERACAO        DAT_OPERACAO -- Item Incluido 08/08/2016
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x2017_und_padrao     x2017
          , x2007_medida         x2007
          , x04_pessoa_fis_jur   x04_2

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
      and x08.ident_docto          = x2005.ident_docto
      and x08.ident_und_padrao     = x2017.ident_und_padrao
      and x08.ident_medida         = x2007.ident_medida
      and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)


union all
        select  'CAPA'                  tipo_reg
           , x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x07.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x07.num_docfis           NUMERO_NF
           , x07.serie_docfis         SERIE_NF
           , 0                        NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , null                     IND_PRODUTO -- NOVA INCLUSÃO
           , null                     CODIGO_PRODUTO
           , null                     DESCRICAO
           , null                     CLAS_ITEM -- Item Incluído 08/08/2016
           , null                     CODIGO_NBM
           , x07.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x07.vlr_tot_nota         VALOR_CONTABIL
           , x07.aliq_tributo_icms    ALIQ_ICMS
           , x07.vlr_base_icms_1      BASE_ICMS_1
           , x07.vlr_base_icms_2      BASE_ICMS_2
           , x07.vlr_base_icms_3      BASE_ICMS_3
           , x07.vlr_base_icms_4      BASE_ICMS_4
           , x07.vlr_tributo_icms     VALOR_ICMS
           , x07.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x07.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , 0                        VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , null                     VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , null                     VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x07.aliq_tributo_ipi     ALIQ_IPI
           , x07.vlr_base_ipi_1       BASE_IPI_1
           , x07.vlr_base_ipi_2       BASE_IPI_2
           , x07.vlr_base_ipi_3       BASE_IPI_3
           , x07.vlr_base_ipi_4       BASE_IPI_4
           , x07.vlr_tributo_ipi      VALOR_IPI
           , x07.cod_sit_pis          COD_SIT_PIS
           , x07.vlr_aliq_pis         ALIQ_PIS
           , x07.vlr_base_pis         BASE_PIS
           , x07.vlr_pis              VLR_PIS
           , x07.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_cofins       COD_SIT_COFINS
           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , x07.vlr_base_cofins      BASE_COFINS
           , x07.vlr_cofins           VALOR_COFINS
           , null                     VLR_FRETE --NOVA INCLUSÃO 24-08--
           , null                     VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , null                     VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , null                     NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , null                     CHASSI -- Item Incluído 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , null                     BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , null                     VLR_ICMS_ORIGDEST  --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , null                     CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x07.vlr_tributo_icmss
           , x07.aliq_tributo_icmss
           , x07.vlr_base_icmss
           , null --x07.cod_trib_ipi
           , null --x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , null                     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , null                     COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , null                     QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , 0
           , 0                        VLR_UNIT -- Item Incluído 08/08/2016
           , null
           , 0
           , 0
           , 0
           , null
           , 0
           , 0
           , 0
           , null
           , x07.USUARIO              USUARIO -- Item Incluído 08/08/2016
           , x07.DAT_OPERACAO         DAT_OPERACAO -- Item Incluído 08/08/2016
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x04_pessoa_fis_jur x04_2

    where x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a  (+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b  (+)
  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.NUM_SELO_CONT_ICMS   = 'CORE'
      and x04.ident_estado         = munic.ident_estado
      and x04.cod_municipio        = munic.cod_municipio(+)
      and est.ident_estado         = x04.ident_estado
      and x07.ident_docto          = x2005.ident_docto
      --and null --x07.ident
     -- and null --x08.ident_medida
     and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)

order by CODIGO_EMPRESA
        , ESTABELECIMENTO
        , data_fiscal
        , NUMERO_NF
        , SERIE_NF
        , NUMERO_ITEM;


  begin

      if vn_qtd_reg = 0 then
       -- insere cabecalho das colunas
        vs_linha :=  'TIPO_REG'
                  ||vs_tab||'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'DATA_FISCAL'
                  ||vs_tab||'DATA_EMISSAO'
                  ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                  ||vs_tab||'ENTRADA_SAIDA'
                  ||vs_tab||'MOVTO_E_S' -- Item Incluído 08/08/2016
                  ||vs_tab||'COD_DOCTO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'MODELO_NF'
                  ||vs_tab||'NUMERO_NF'
                  ||vs_tab||'SERIE_NF'
                  ||vs_tab||'NUMERO_ITEM'
                  ||vs_tab||'SITUACAO'
                  ||vs_tab||'NUM_DOCFIS_REF' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_PRODUTO' -- NOVA INCLUSÃO
                  ||vs_tab||'CODIGO_PRODUTO'
                  ||vs_tab||'DESCRICAO'
                  ||vs_tab||'CLASSIFICACAO ITEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'CODIGO_NBM'
                  ||vs_tab||'IND_FIS_JUR' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'CODIGO_FIS_JUR'
                  ||vs_tab||'RAZAO_SOCIAL'
                  ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                  ||vs_tab||'CGC'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'COD_NATUREZA_OP' -- NOVA INCLUSÃO
                  ||vs_tab||'DESCRICAO_NATUREZA_OP' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VALOR_CONTABIL'
                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  ||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'VALOR_FCP_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_ORIGEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
                  ||vs_tab||'VLR_ICMSS_NDESTAC' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_ICMSS_N_ESCRIT' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  ||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  ||vs_tab||'VLR_FRETE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_SEGURO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_OUTRAS' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
                  ||vs_tab||'NATUREZA_FRETE'
                  ||vs_tab||'IND_FATURA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_TP_FRETE'
                  ||vs_tab||'NUM_CONTROLE_DOCTO'
                  ||vs_tab||'CHASSI' -- Item Incluído 08/08/2016
                  ||vs_tab||'TIPO_COMPRA_VENDA' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'COD_FISJUR_LEASING' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'RAZAO_LEASING' --NOVA INCLUSÃO 28-03-17--
                  ||vs_tab||'BASE_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'VLR_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'CONTA_CONTABIL'
                  ||vs_tab||'CENTRO_CUSTO'
                  ||vs_tab||'SISTEMA'
                  ||vs_tab||'VLR_COMISSAO'
                  ||vs_tab||'UF'
                  ||vs_tab||'COD_MUNICIPIO'
                  ||vs_tab||'MUNICIPIO'
                  ||vs_tab||'COD_UND_PADRAO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'COD_MEDIDA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'QUANTIDADE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NORM_DEV' -- item incluído 22/08/2016
                  ||vs_tab||'VALOR_UNITARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VLR_ITEM'
                  ||vs_tab||'COD_SITUACAO_PIS_ST'
                  ||vs_tab||'VLR_BASE_PIS_ST'
                  ||vs_tab||'VLR_ALIQ_PIS_ST'
                  ||vs_tab||'VLR_PIS_ST'
                  ||vs_tab||'COD_SITUACAO_COFINS_ST'
                  ||vs_tab||'VLR_BASE_COFINS_ST'
                  ||vs_tab||'VLR_ALIQ_COFINS_ST'
                  ||vs_tab||'VLR_COFINS_ST'
                  ||vs_tab||'DAT_LANC_PIS_COFINS'
                  ||vs_tab||'USUARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'DATA_OPERACAO' -- Item Incluído 08/08/2016
                  ;

                  lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end if;

            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               vs_linha :=  mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MOVTO_E_S -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.COD_DOCTO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.NUM_DOCFIS_REF -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_PRODUTO -- NOVA INCLUSÃO
                         ||vs_tab||mreg.CODIGO_PRODUTO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.CLAS_ITEM -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.CODIGO_NBM
                         ||vs_tab||mreg.IND_FIS_JUR -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.COD_NATUREZA_OP -- NOVA INCLUSÃO
                         ||vs_tab||mreg.DESCRICAO_NATUREZA_OP -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_situacao_a||mreg.cod_situacao_b
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FCP_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_ORIG),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_N_ESCRIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IPI),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_trib_ipi
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FRETE),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_SEGURO),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTRAS),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
                         ||vs_tab||mreg.NATUREZA_FRETE
                         ||vs_tab||mreg.IND_FATURA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_TP_FRETE
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.CHASSI -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.tipo_compra_venda --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.cod_fisjur_leasing --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.razao_lsg --NOVA INCLUSÃO 28-03-17--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.base_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||mreg.cod_conta
                         ||vs_tab||mreg.centro_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.vlr_comissao
                         ||vs_tab||mreg.cod_estado
                         ||vs_tab||mreg.cod_municipio
                         ||vs_tab||mreg.descr_mun
                         ||vs_tab||mreg.COD_UND_PADRAO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.COD_MEDIDA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.QUANTIDADE -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NORM_DEV -- Item incluído 22/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_UNIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ITEM),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_PIS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_PIS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_COFINS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_COFINS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.DAT_LANC_PIS_COFINS
                         ||vs_tab||mreg.USUARIO -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.DAT_OPERACAO -- Item Incluído 08/08/2016
                         ;
                         lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg + 1;

          end loop;



  end gera_merc_ivecore;

  procedure gera_merc_sapiens (vs_cod_estab  varchar2
                             , vd_data_ini   date
                             , vd_data_fim   date)is



   cursor c_dados_merc (c_cod_estab  varchar2
                 , c_data_ini   date
                 , c_data_fim   date) is
       select 'ITEM'                  tipo_reg
           , x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x08.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x08.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item Incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x08.num_docfis           NUMERO_NF
           , x08.serie_docfis         SERIE_NF
           , x08.num_item             NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , x2013.ind_produto        IND_PRODUTO -- NOVA INCLUSÃO
           , x2013.cod_produto        CODIGO_PRODUTO
           , x2013.descricao          DESCRICAO
           , x2013.CLAS_ITEM          CLAS_ITEM -- Item Incluído 08/08/2016
           , nvl(x2043.cod_nbm,' ')   CODIGO_NBM
           , x08.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x08.vlr_contab_item      VALOR_CONTABIL
           , x08.aliq_tributo_icms    ALIQ_ICMS
           , x08.vlr_base_icms_1      BASE_ICMS_1
           , x08.vlr_base_icms_2      BASE_ICMS_2
           , x08.vlr_base_icms_3      BASE_ICMS_3
           , x08.vlr_base_icms_4      BASE_ICMS_4
           , x08.vlr_tributo_icms     VALOR_ICMS
           , x08.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x08.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , x08.VLR_FCP_UF_DEST      VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_DEST     VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_ORIG     VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , x08.Vlr_Icmss_Ndestac    VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , x08.Vlr_Icmss_n_Escrit   VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x08.aliq_tributo_ipi     ALIQ_IPI
           , x08.vlr_base_ipi_1       BASE_IPI_1
           , x08.vlr_base_ipi_2       BASE_IPI_2
           , x08.vlr_base_ipi_3       BASE_IPI_3
           , x08.vlr_base_ipi_4       BASE_IPI_4
           , x08.vlr_tributo_ipi      VALOR_IPI
           , x08.cod_situacao_pis     COD_SIT_PIS
           , x08.vlr_aliq_pis         ALIQ_PIS
           , x08.vlr_base_pis         BASE_PIS
           , x08.vlr_pis              VLR_PIS
           , x08.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_cofins  COD_SIT_COFINS
           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , x08.vlr_base_cofins      BASE_COFINS
           , x08.vlr_cofins           VALOR_COFINS
           , x08.vlr_frete            VLR_FRETE --NOVA INCLUSÃO 24-08--
           , x08.vlr_seguro           VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , x08.vlr_outras           VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , x08.ind_natureza_frete   NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , x08.CHASSI               CHASSI   -- Item Incluido 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , x08.base_icms_origdest   BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x08.vlr_icms_origdest    VLR_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , x2003.cod_custo          CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x08.vlr_tributo_icmss
           , x08.aliq_tributo_icmss
           , x08.vlr_base_icmss
           , x08.cod_trib_ipi
           , x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , x2017.cod_und_padrao     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , x2007.cod_medida         COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , x08.quantidade           QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , x08.VLR_ITEM
           , x08.VLR_UNIT             VLR_UNIT -- Item Incluido 08/08/2016
           , x08.COD_SITUACAO_PIS_ST
           , x08.VLR_BASE_PIS_ST
           , x08.VLR_ALIQ_PIS_ST
           , x08.VLR_PIS_ST
           , x08.COD_SITUACAO_COFINS_ST
           , x08.VLR_BASE_COFINS_ST
           , x08.VLR_ALIQ_COFINS_ST
           , x08.VLR_COFINS_ST
           , x08.DAT_LANC_PIS_COFINS
           , x08.USUARIO             USUARIO --  Item Incluido 08/08/2016
           , X08.DAT_OPERACAO        DAT_OPERACAO -- Item Incluido 08/08/2016
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x2017_und_padrao     x2017
          , x2007_medida         x2007
          , x04_pessoa_fis_jur   x04_2

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
      and x08.ident_docto          = x2005.ident_docto
      and x08.ident_und_padrao     = x2017.ident_und_padrao
      and x08.ident_medida         = x2007.ident_medida
      and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)


union all
        select  'CAPA'                  tipo_reg
           , x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x07.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x07.num_docfis           NUMERO_NF
           , x07.serie_docfis         SERIE_NF
           , 0                        NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , null                     IND_PRODUTO -- NOVA INCLUSÃO
           , null                     CODIGO_PRODUTO
           , null                     DESCRICAO
           , null                     CLAS_ITEM -- Item Incluído 08/08/2016
           , null                     CODIGO_NBM
           , x07.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x07.vlr_tot_nota         VALOR_CONTABIL
           , x07.aliq_tributo_icms    ALIQ_ICMS
           , x07.vlr_base_icms_1      BASE_ICMS_1
           , x07.vlr_base_icms_2      BASE_ICMS_2
           , x07.vlr_base_icms_3      BASE_ICMS_3
           , x07.vlr_base_icms_4      BASE_ICMS_4
           , x07.vlr_tributo_icms     VALOR_ICMS
           , x07.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x07.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , 0                        VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , null                     VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , null                     VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x07.aliq_tributo_ipi     ALIQ_IPI
           , x07.vlr_base_ipi_1       BASE_IPI_1
           , x07.vlr_base_ipi_2       BASE_IPI_2
           , x07.vlr_base_ipi_3       BASE_IPI_3
           , x07.vlr_base_ipi_4       BASE_IPI_4
           , x07.vlr_tributo_ipi      VALOR_IPI
           , x07.cod_sit_pis          COD_SIT_PIS
           , x07.vlr_aliq_pis         ALIQ_PIS
           , x07.vlr_base_pis         BASE_PIS
           , x07.vlr_pis              VLR_PIS
           , x07.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_cofins       COD_SIT_COFINS
           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , x07.vlr_base_cofins      BASE_COFINS
           , x07.vlr_cofins           VALOR_COFINS
           , null                     VLR_FRETE --NOVA INCLUSÃO 24-08--
           , null                     VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , null                     VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , null                     NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , null                     CHASSI -- Item Incluído 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , null                     BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , null                     VLR_ICMS_ORIGDEST  --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , null                     CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x07.vlr_tributo_icmss
           , x07.aliq_tributo_icmss
           , x07.vlr_base_icmss
           , null --x07.cod_trib_ipi
           , null --x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , null                     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , null                     COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , null                     QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , 0
           , 0                        VLR_UNIT -- Item Incluído 08/08/2016
           , null
           , 0
           , 0
           , 0
           , null
           , 0
           , 0
           , 0
           , null
           , x07.USUARIO              USUARIO -- Item Incluído 08/08/2016
           , x07.DAT_OPERACAO         DAT_OPERACAO -- Item Incluído 08/08/2016
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x04_pessoa_fis_jur x04_2

    where x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a  (+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b  (+)
  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.NUM_SELO_CONT_ICMS   = 'CORE'
      and x04.ident_estado         = munic.ident_estado
      and x04.cod_municipio        = munic.cod_municipio(+)
      and est.ident_estado         = x04.ident_estado
      and x07.ident_docto          = x2005.ident_docto
      --and null --x07.ident
     -- and null --x08.ident_medida
     and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)

order by CODIGO_EMPRESA
        , ESTABELECIMENTO
        , data_fiscal
        , NUMERO_NF
        , SERIE_NF
        , NUMERO_ITEM;


  begin

     if vn_qtd_reg = 0 then

       -- insere cabecalho das colunas
        vs_linha := 'TIPO_REG'
                  ||vs_tab||'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'DATA_FISCAL'
                  ||vs_tab||'DATA_EMISSAO'
                  ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                  ||vs_tab||'ENTRADA_SAIDA'
                  ||vs_tab||'MOVTO_E_S' -- Item Incluído 08/08/2016
                  ||vs_tab||'COD_DOCTO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'MODELO_NF'
                  ||vs_tab||'NUMERO_NF'
                  ||vs_tab||'SERIE_NF'
                  ||vs_tab||'NUMERO_ITEM'
                  ||vs_tab||'SITUACAO'
                  ||vs_tab||'NUM_DOCFIS_REF' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_PRODUTO' -- NOVA INCLUSÃO
                  ||vs_tab||'CODIGO_PRODUTO'
                  ||vs_tab||'DESCRICAO'
                  ||vs_tab||'CLASSIFICACAO ITEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'CODIGO_NBM'
                  ||vs_tab||'IND_FIS_JUR' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'CODIGO_FIS_JUR'
                  ||vs_tab||'RAZAO_SOCIAL'
                  ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                  ||vs_tab||'CGC'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'COD_NATUREZA_OP' -- NOVA INCLUSÃO
                  ||vs_tab||'DESCRICAO_NATUREZA_OP' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VALOR_CONTABIL'
                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  ||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'VALOR_FCP_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_ORIGEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
                  ||vs_tab||'VLR_ICMSS_NDESTAC' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_ICMSS_N_ESCRIT' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  ||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  ||vs_tab||'VLR_FRETE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_SEGURO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_OUTRAS' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
                  ||vs_tab||'NATUREZA_FRETE'
                  ||vs_tab||'IND_FATURA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_TP_FRETE'
                  ||vs_tab||'NUM_CONTROLE_DOCTO'
                  ||vs_tab||'CHASSI' -- Item Incluído 08/08/2016
                  ||vs_tab||'TIPO_COMPRA_VENDA' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'COD_FISJUR_LEASING' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'RAZAO_LEASING' --NOVA INCLUSÃO 28-03-17--
                  ||vs_tab||'BASE_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'VLR_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'CONTA_CONTABIL'
                  ||vs_tab||'CENTRO_CUSTO'
                  ||vs_tab||'SISTEMA'
                  ||vs_tab||'VLR_COMISSAO'
                  ||vs_tab||'UF'
                  ||vs_tab||'COD_MUNICIPIO'
                  ||vs_tab||'MUNICIPIO'
                  ||vs_tab||'COD_UND_PADRAO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'COD_MEDIDA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'QUANTIDADE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NORM_DEV' -- Item Incluido 22/08/2016
                  ||vs_tab||'VALOR_UNITARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VLR_ITEM'
                  ||vs_tab||'COD_SITUACAO_PIS_ST'
                  ||vs_tab||'VLR_BASE_PIS_ST'
                  ||vs_tab||'VLR_ALIQ_PIS_ST'
                  ||vs_tab||'VLR_PIS_ST'
                  ||vs_tab||'COD_SITUACAO_COFINS_ST'
                  ||vs_tab||'VLR_BASE_COFINS_ST'
                  ||vs_tab||'VLR_ALIQ_COFINS_ST'
                  ||vs_tab||'VLR_COFINS_ST'
                  ||vs_tab||'DAT_LANC_PIS_COFINS'
                  ||vs_tab||'USUARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'DATA_OPERACAO' -- Item Incluído 08/08/2016
                  ;

                  lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end if;

            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               vs_linha := mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO -- Item Excluído 08/08/2016
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MOVTO_E_S -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.COD_DOCTO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.NUM_DOCFIS_REF -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_PRODUTO -- NOVA INCLUSÃO
                         ||vs_tab||mreg.CODIGO_PRODUTO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.CLAS_ITEM -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.CODIGO_NBM
                         ||vs_tab||mreg.IND_FIS_JUR -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.COD_NATUREZA_OP -- NOVA INCLUSÃO
                         ||vs_tab||mreg.DESCRICAO_NATUREZA_OP -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_situacao_a||mreg.cod_situacao_b
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FCP_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_ORIG),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_N_ESCRIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IPI),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_trib_ipi
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FRETE),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_SEGURO),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTRAS),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
                         ||vs_tab||mreg.NATUREZA_FRETE
                         ||vs_tab||mreg.IND_FATURA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_TP_FRETE
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.CHASSI -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.tipo_compra_venda --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.cod_fisjur_leasing --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.razao_lsg --NOVA INCLUSÃO 28-03-17--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.base_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||mreg.cod_conta
                         ||vs_tab||mreg.centro_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.vlr_comissao
                         ||vs_tab||mreg.cod_estado
                         ||vs_tab||mreg.cod_municipio
                         ||vs_tab||mreg.descr_mun
                         ||vs_tab||mreg.COD_UND_PADRAO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.COD_MEDIDA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.QUANTIDADE -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NORM_DEV -- Item incluído 22/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_UNIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ITEM),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_PIS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_PIS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_COFINS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_COFINS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.DAT_LANC_PIS_COFINS
                         ||vs_tab||mreg.USUARIO -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.DAT_OPERACAO -- Item Incluído 08/08/2016
                         ;
                         lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end loop;



  end gera_merc_sapiens;

  procedure gera_merc_powersap (vs_cod_estab  varchar2
                              , vd_data_ini   date
                              , vd_data_fim   date)is



   cursor c_dados_merc (c_cod_estab  varchar2
                 , c_data_ini   date
                 , c_data_fim   date) is
      select 'ITEM'             tipo_reg
           , x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x08.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x08.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item Incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x08.num_docfis           NUMERO_NF
           , x08.serie_docfis         SERIE_NF
           , x08.num_item             NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , x2013.ind_produto        IND_PRODUTO -- NOVA INCLUSÃO
           , x2013.cod_produto        CODIGO_PRODUTO
           , x2013.descricao          DESCRICAO
           , x2013.CLAS_ITEM          CLAS_ITEM -- Item Incluído 08/08/2016
           , nvl(x2043.cod_nbm,' ')   CODIGO_NBM
           , x08.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x08.vlr_contab_item      VALOR_CONTABIL
           , x08.aliq_tributo_icms    ALIQ_ICMS
           , x08.vlr_base_icms_1      BASE_ICMS_1
           , x08.vlr_base_icms_2      BASE_ICMS_2
           , x08.vlr_base_icms_3      BASE_ICMS_3
           , x08.vlr_base_icms_4      BASE_ICMS_4
           , x08.vlr_tributo_icms     VALOR_ICMS
           , x08.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x08.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , x08.VLR_FCP_UF_DEST      VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_DEST     VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_ORIG     VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , x08.Vlr_Icmss_Ndestac    VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , x08.Vlr_Icmss_n_Escrit   VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x08.aliq_tributo_ipi     ALIQ_IPI
           , x08.vlr_base_ipi_1       BASE_IPI_1
           , x08.vlr_base_ipi_2       BASE_IPI_2
           , x08.vlr_base_ipi_3       BASE_IPI_3
           , x08.vlr_base_ipi_4       BASE_IPI_4
           , x08.vlr_tributo_ipi      VALOR_IPI
           , x08.cod_situacao_pis     COD_SIT_PIS
           , x08.vlr_aliq_pis         ALIQ_PIS
           , x08.vlr_base_pis         BASE_PIS
           , x08.vlr_pis              VLR_PIS
           , x08.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_cofins  COD_SIT_COFINS
           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , x08.vlr_base_cofins      BASE_COFINS
           , x08.vlr_cofins           VALOR_COFINS
           , x08.vlr_frete            VLR_FRETE --NOVA INCLUSÃO 24-08--
           , x08.vlr_seguro           VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , x08.vlr_outras           VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , x08.ind_natureza_frete   NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , x08.CHASSI               CHASSI   -- Item Incluido 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , x08.base_icms_origdest   BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x08.vlr_icms_origdest    VLR_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , x2003.cod_custo          CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x08.vlr_tributo_icmss
           , x08.aliq_tributo_icmss
           , x08.vlr_base_icmss
           , x08.cod_trib_ipi
           , x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , x2017.cod_und_padrao     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , x2007.cod_medida         COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , x08.quantidade           QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , x08.VLR_ITEM
           , x08.VLR_UNIT             VLR_UNIT -- Item Incluido 08/08/2016
           , x08.COD_SITUACAO_PIS_ST
           , x08.VLR_BASE_PIS_ST
           , x08.VLR_ALIQ_PIS_ST
           , x08.VLR_PIS_ST
           , x08.COD_SITUACAO_COFINS_ST
           , x08.VLR_BASE_COFINS_ST
           , x08.VLR_ALIQ_COFINS_ST
           , x08.VLR_COFINS_ST
           , x08.DAT_LANC_PIS_COFINS
           , x08.USUARIO             USUARIO --  Item Incluido 08/08/2016
           , X08.DAT_OPERACAO        DAT_OPERACAO -- Item Incluido 08/08/2016
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x2017_und_padrao     x2017
          , x2007_medida         x2007
          , x04_pessoa_fis_jur   x04_2

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
      and x08.ident_docto          = x2005.ident_docto
      and x08.ident_und_padrao     = x2017.ident_und_padrao
      and x08.ident_medida         = x2007.ident_medida
      and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)


union all
        select 'CAPA'                  tipo_reg
           , x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x07.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x07.num_docfis           NUMERO_NF
           , x07.serie_docfis         SERIE_NF
           , 0                        NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , null                     IND_PRODUTO -- NOVA INCLUSÃO
           , null                     CODIGO_PRODUTO
           , null                     DESCRICAO
           , null                     CLAS_ITEM -- Item Incluído 08/08/2016
           , null                     CODIGO_NBM
           , x07.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x07.vlr_tot_nota         VALOR_CONTABIL
           , x07.aliq_tributo_icms    ALIQ_ICMS
           , x07.vlr_base_icms_1      BASE_ICMS_1
           , x07.vlr_base_icms_2      BASE_ICMS_2
           , x07.vlr_base_icms_3      BASE_ICMS_3
           , x07.vlr_base_icms_4      BASE_ICMS_4
           , x07.vlr_tributo_icms     VALOR_ICMS
           , x07.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x07.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , 0                        VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , null                     VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , null                     VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x07.aliq_tributo_ipi     ALIQ_IPI
           , x07.vlr_base_ipi_1       BASE_IPI_1
           , x07.vlr_base_ipi_2       BASE_IPI_2
           , x07.vlr_base_ipi_3       BASE_IPI_3
           , x07.vlr_base_ipi_4       BASE_IPI_4
           , x07.vlr_tributo_ipi      VALOR_IPI
           , x07.cod_sit_pis          COD_SIT_PIS
           , x07.vlr_aliq_pis         ALIQ_PIS
           , x07.vlr_base_pis         BASE_PIS
           , x07.vlr_pis              VLR_PIS
           , x07.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_cofins       COD_SIT_COFINS
           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , x07.vlr_base_cofins      BASE_COFINS
           , x07.vlr_cofins           VALOR_COFINS
           , null                     VLR_FRETE --NOVA INCLUSÃO 24-08--
           , null                     VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , null                     VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , null                     NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , null                     CHASSI -- Item Incluído 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , null                     BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , null                     VLR_ICMS_ORIGDEST  --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , null                     CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x07.vlr_tributo_icmss
           , x07.aliq_tributo_icmss
           , x07.vlr_base_icmss
           , null --x07.cod_trib_ipi
           , null --x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , null                     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , null                     COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , null                     QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , 0
           , 0                        VLR_UNIT -- Item Incluído 08/08/2016
           , null
           , 0
           , 0
           , 0
           , null
           , 0
           , 0
           , 0
           , null
           , x07.USUARIO              USUARIO -- Item Incluído 08/08/2016
           , x07.DAT_OPERACAO         DAT_OPERACAO -- Item Incluído 08/08/2016
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x04_pessoa_fis_jur x04_2

    where x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a  (+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b  (+)
  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.NUM_SELO_CONT_ICMS   = 'CORE'
      and x04.ident_estado         = munic.ident_estado
      and x04.cod_municipio        = munic.cod_municipio(+)
      and est.ident_estado         = x04.ident_estado
      and x07.ident_docto          = x2005.ident_docto
      --and null --x07.ident
     -- and null --x08.ident_medida
     and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)

order by CODIGO_EMPRESA
        , ESTABELECIMENTO
        , data_fiscal
        , NUMERO_NF
        , SERIE_NF
        , NUMERO_ITEM;


  begin

     if vn_qtd_reg = 0 then

       -- insere cabecalho das colunas
        vs_linha := 'TIPO_REG'
                  ||vs_tab||'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'DATA_FISCAL'
                  ||vs_tab||'DATA_EMISSAO'
                  ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                  ||vs_tab||'ENTRADA_SAIDA'
                  ||vs_tab||'MOVTO_E_S' -- Item Incluído 08/08/2016
                  ||vs_tab||'COD_DOCTO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'MODELO_NF'
                  ||vs_tab||'NUMERO_NF'
                  ||vs_tab||'SERIE_NF'
                  ||vs_tab||'NUMERO_ITEM'
                  ||vs_tab||'SITUACAO'
                  ||vs_tab||'NUM_DOCFIS_REF' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_PRODUTO' -- NOVA INCLUSÃO
                  ||vs_tab||'CODIGO_PRODUTO'
                  ||vs_tab||'DESCRICAO'
                  ||vs_tab||'CLASSIFICACAO ITEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'CODIGO_NBM'
                  ||vs_tab||'IND_FIS_JUR' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'CODIGO_FIS_JUR'
                  ||vs_tab||'RAZAO_SOCIAL'
                  ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                  ||vs_tab||'CGC'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'COD_NATUREZA_OP' -- NOVA INCLUSÃO
                  ||vs_tab||'DESCRICAO_NATUREZA_OP' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VALOR_CONTABIL'
                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  ||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'VALOR_FCP_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_ORIGEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
                  ||vs_tab||'VLR_ICMSS_NDESTAC' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_ICMSS_N_ESCRIT' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  ||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  ||vs_tab||'VLR_FRETE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_SEGURO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_OUTRAS' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
                  ||vs_tab||'NATUREZA_FRETE'
                  ||vs_tab||'IND_FATURA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_TP_FRETE'
                  ||vs_tab||'NUM_CONTROLE_DOCTO'
                  ||vs_tab||'CHASSI' -- Item Incluído 08/08/2016
                  ||vs_tab||'TIPO_COMPRA_VENDA' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'COD_FISJUR_LEASING' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'RAZAO_LEASING' --NOVA INCLUSÃO 28-03-17--
                  ||vs_tab||'BASE_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'VLR_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'CONTA_CONTABIL'
                  ||vs_tab||'CENTRO_CUSTO'
                  ||vs_tab||'SISTEMA'
                  ||vs_tab||'VLR_COMISSAO'
                  ||vs_tab||'UF'
                  ||vs_tab||'COD_MUNICIPIO'
                  ||vs_tab||'MUNICIPIO'
                  ||vs_tab||'COD_UND_PADRAO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'COD_MEDIDA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'QUANTIDADE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NORM_DEV' -- Item incluido 22/08/2016
                  ||vs_tab||'VALOR_UNITARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VLR_ITEM'
                  ||vs_tab||'COD_SITUACAO_PIS_ST'
                  ||vs_tab||'VLR_BASE_PIS_ST'
                  ||vs_tab||'VLR_ALIQ_PIS_ST'
                  ||vs_tab||'VLR_PIS_ST'
                  ||vs_tab||'COD_SITUACAO_COFINS_ST'
                  ||vs_tab||'VLR_BASE_COFINS_ST'
                  ||vs_tab||'VLR_ALIQ_COFINS_ST'
                  ||vs_tab||'VLR_COFINS_ST'
                  ||vs_tab||'DAT_LANC_PIS_COFINS'
                  ||vs_tab||'USUARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'DATA_OPERACAO' -- Item Incluído 08/08/2016
                  ;

                  lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end if;

            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

                vs_linha := mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MOVTO_E_S -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.COD_DOCTO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.NUM_DOCFIS_REF -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_PRODUTO -- NOVA INCLUSÃO
                         ||vs_tab||mreg.CODIGO_PRODUTO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.CLAS_ITEM -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.CODIGO_NBM
                         ||vs_tab||mreg.IND_FIS_JUR -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.COD_NATUREZA_OP -- NOVA INCLUSÃO
                         ||vs_tab||mreg.DESCRICAO_NATUREZA_OP -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_situacao_a||mreg.cod_situacao_b
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FCP_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_ORIG),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_N_ESCRIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IPI),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_trib_ipi
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FRETE),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_SEGURO),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTRAS),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
                         ||vs_tab||mreg.NATUREZA_FRETE
                         ||vs_tab||mreg.IND_FATURA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_TP_FRETE
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.CHASSI -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.tipo_compra_venda --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.cod_fisjur_leasing --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.razao_lsg --NOVA INCLUSÃO 28-03-17--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.base_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||mreg.cod_conta
                         ||vs_tab||mreg.centro_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.vlr_comissao
                         ||vs_tab||mreg.cod_estado
                         ||vs_tab||mreg.cod_municipio
                         ||vs_tab||mreg.descr_mun
                         ||vs_tab||mreg.COD_UND_PADRAO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.COD_MEDIDA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.QUANTIDADE -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NORM_DEV -- Item incluido 22/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_UNIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ITEM),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_PIS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_PIS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_COFINS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_COFINS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.DAT_LANC_PIS_COFINS
                         ||vs_tab||mreg.USUARIO -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.DAT_OPERACAO -- Item Incluído 08/08/2016
                         ;
                         lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end loop;



  end gera_merc_powersap;

  procedure gera_merc_mainframe (vs_cod_estab  varchar2
                               , vd_data_ini   date
                               , vd_data_fim   date)is



   cursor c_dados_merc (c_cod_estab  varchar2
                 , c_data_ini   date
                 , c_data_fim   date) is
       select 'ITEM'            tipo_reg
           , x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x08.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x08.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item Incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x08.num_docfis           NUMERO_NF
           , x08.serie_docfis         SERIE_NF
           , x08.num_item             NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , x2013.ind_produto        IND_PRODUTO -- NOVA INCLUSÃO
           , x2013.cod_produto        CODIGO_PRODUTO
           , x2013.descricao          DESCRICAO
           , x2013.CLAS_ITEM          CLAS_ITEM -- Item Incluído 08/08/2016
           , nvl(x2043.cod_nbm,' ')   CODIGO_NBM
           , x08.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x08.vlr_contab_item      VALOR_CONTABIL
           , x08.aliq_tributo_icms    ALIQ_ICMS
           , x08.vlr_base_icms_1      BASE_ICMS_1
           , x08.vlr_base_icms_2      BASE_ICMS_2
           , x08.vlr_base_icms_3      BASE_ICMS_3
           , x08.vlr_base_icms_4      BASE_ICMS_4
           , x08.vlr_tributo_icms     VALOR_ICMS
           , x08.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x08.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , x08.VLR_FCP_UF_DEST      VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_DEST     VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_ORIG     VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , x08.Vlr_Icmss_Ndestac    VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , x08.Vlr_Icmss_n_Escrit   VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x08.aliq_tributo_ipi     ALIQ_IPI
           , x08.vlr_base_ipi_1       BASE_IPI_1
           , x08.vlr_base_ipi_2       BASE_IPI_2
           , x08.vlr_base_ipi_3       BASE_IPI_3
           , x08.vlr_base_ipi_4       BASE_IPI_4
           , x08.vlr_tributo_ipi      VALOR_IPI
           , x08.cod_situacao_pis     COD_SIT_PIS
           , x08.vlr_aliq_pis         ALIQ_PIS
           , x08.vlr_base_pis         BASE_PIS
           , x08.vlr_pis              VLR_PIS
           , x08.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_cofins  COD_SIT_COFINS
           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , x08.vlr_base_cofins      BASE_COFINS
           , x08.vlr_cofins           VALOR_COFINS
           , x08.vlr_frete            VLR_FRETE --NOVA INCLUSÃO 24-08--
           , x08.vlr_seguro           VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , x08.vlr_outras           VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , x08.ind_natureza_frete   NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , x08.CHASSI               CHASSI   -- Item Incluido 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , x08.base_icms_origdest   BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x08.vlr_icms_origdest    VLR_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , x2003.cod_custo          CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x08.vlr_tributo_icmss
           , x08.aliq_tributo_icmss
           , x08.vlr_base_icmss
           , x08.cod_trib_ipi
           , x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , x2017.cod_und_padrao     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , x2007.cod_medida         COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , x08.quantidade           QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , x08.VLR_ITEM
           , x08.VLR_UNIT             VLR_UNIT -- Item Incluido 08/08/2016
           , x08.COD_SITUACAO_PIS_ST
           , x08.VLR_BASE_PIS_ST
           , x08.VLR_ALIQ_PIS_ST
           , x08.VLR_PIS_ST
           , x08.COD_SITUACAO_COFINS_ST
           , x08.VLR_BASE_COFINS_ST
           , x08.VLR_ALIQ_COFINS_ST
           , x08.VLR_COFINS_ST
           , x08.DAT_LANC_PIS_COFINS
           , x08.USUARIO             USUARIO --  Item Incluido 08/08/2016
           , X08.DAT_OPERACAO        DAT_OPERACAO -- Item Incluido 08/08/2016
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x2017_und_padrao     x2017
          , x2007_medida         x2007
          , x04_pessoa_fis_jur   x04_2

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
      and x08.ident_docto          = x2005.ident_docto
      and x08.ident_und_padrao     = x2017.ident_und_padrao
      and x08.ident_medida         = x2007.ident_medida
      and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)


union all
        select 'CAPA'                  tipo_reg
           , x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x07.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x07.num_docfis           NUMERO_NF
           , x07.serie_docfis         SERIE_NF
           , 0                        NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , null                     IND_PRODUTO -- NOVA INCLUSÃO
           , null                     CODIGO_PRODUTO
           , null                     DESCRICAO
           , null                     CLAS_ITEM -- Item Incluído 08/08/2016
           , null                     CODIGO_NBM
           , x07.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x07.vlr_tot_nota         VALOR_CONTABIL
           , x07.aliq_tributo_icms    ALIQ_ICMS
           , x07.vlr_base_icms_1      BASE_ICMS_1
           , x07.vlr_base_icms_2      BASE_ICMS_2
           , x07.vlr_base_icms_3      BASE_ICMS_3
           , x07.vlr_base_icms_4      BASE_ICMS_4
           , x07.vlr_tributo_icms     VALOR_ICMS
           , x07.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x07.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , 0                        VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , null                     VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , null                     VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x07.aliq_tributo_ipi     ALIQ_IPI
           , x07.vlr_base_ipi_1       BASE_IPI_1
           , x07.vlr_base_ipi_2       BASE_IPI_2
           , x07.vlr_base_ipi_3       BASE_IPI_3
           , x07.vlr_base_ipi_4       BASE_IPI_4
           , x07.vlr_tributo_ipi      VALOR_IPI
           , x07.cod_sit_pis          COD_SIT_PIS
           , x07.vlr_aliq_pis         ALIQ_PIS
           , x07.vlr_base_pis         BASE_PIS
           , x07.vlr_pis              VLR_PIS
           , x07.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_cofins       COD_SIT_COFINS
           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , x07.vlr_base_cofins      BASE_COFINS
           , x07.vlr_cofins           VALOR_COFINS
           , null                     VLR_FRETE --NOVA INCLUSÃO 24-08--
           , null                     VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , null                     VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , null                     NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , null                     CHASSI -- Item Incluído 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , null                     BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , null                     VLR_ICMS_ORIGDEST  --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , null                     CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x07.vlr_tributo_icmss
           , x07.aliq_tributo_icmss
           , x07.vlr_base_icmss
           , null --x07.cod_trib_ipi
           , null --x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , null                     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , null                     COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , null                     QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , 0
           , 0                        VLR_UNIT -- Item Incluído 08/08/2016
           , null
           , 0
           , 0
           , 0
           , null
           , 0
           , 0
           , 0
           , null
           , x07.USUARIO              USUARIO -- Item Incluído 08/08/2016
           , x07.DAT_OPERACAO         DAT_OPERACAO -- Item Incluído 08/08/2016
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x04_pessoa_fis_jur x04_2

    where x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a  (+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b  (+)
  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.NUM_SELO_CONT_ICMS   = 'CORE'
      and x04.ident_estado         = munic.ident_estado
      and x04.cod_municipio        = munic.cod_municipio(+)
      and est.ident_estado         = x04.ident_estado
      and x07.ident_docto          = x2005.ident_docto
      --and null --x07.ident
      --and null --x08.ident_medida
     and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)

order by CODIGO_EMPRESA
        , ESTABELECIMENTO
        , data_fiscal
        , NUMERO_NF
        , SERIE_NF
        , NUMERO_ITEM;


  begin

     if vn_qtd_reg = 0 then

       -- insere cabecalho das colunas
        vs_linha := 'TIPO_REG'
                  ||vs_tab||'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'DATA_FISCAL'
                  ||vs_tab||'DATA_EMISSAO'
                  ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                  ||vs_tab||'ENTRADA_SAIDA'
                  ||vs_tab||'MOVTO_E_S' -- Item Incluído 08/08/2016
                  ||vs_tab||'COD_DOCTO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'MODELO_NF'
                  ||vs_tab||'NUMERO_NF'
                  ||vs_tab||'SERIE_NF'
                  ||vs_tab||'NUMERO_ITEM'
                  ||vs_tab||'SITUACAO'
                  ||vs_tab||'NUM_DOCFIS_REF' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_PRODUTO' -- NOVA INCLUSÃO
                  ||vs_tab||'CODIGO_PRODUTO'
                  ||vs_tab||'DESCRICAO'
                  ||vs_tab||'CLASSIFICACAO ITEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'CODIGO_NBM'
                  ||vs_tab||'IND_FIS_JUR' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'CODIGO_FIS_JUR'
                  ||vs_tab||'RAZAO_SOCIAL'
                  ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                  ||vs_tab||'CGC'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'COD_NATUREZA_OP' -- NOVA INCLUSÃO
                  ||vs_tab||'DESCRICAO_NATUREZA_OP' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VALOR_CONTABIL'
                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  ||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'VALOR_FCP_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_ORIGEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
                  ||vs_tab||'VLR_ICMSS_NDESTAC' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_ICMSS_N_ESCRIT' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  ||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  ||vs_tab||'VLR_FRETE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_SEGURO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_OUTRAS' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
                  ||vs_tab||'NATUREZA_FRETE'
                  ||vs_tab||'IND_FATURA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_TP_FRETE'
                  ||vs_tab||'NUM_CONTROLE_DOCTO'
                  ||vs_tab||'CHASSI' -- Item Incluído 08/08/2016
                  ||vs_tab||'TIPO_COMPRA_VENDA' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'COD_FISJUR_LEASING' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'RAZAO_LEASING' --NOVA INCLUSÃO 28-03-17--
                  ||vs_tab||'BASE_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'VLR_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'CONTA_CONTABIL'
                  ||vs_tab||'CENTRO_CUSTO'
                  ||vs_tab||'SISTEMA'
                  ||vs_tab||'VLR_COMISSAO'
                  ||vs_tab||'UF'
                  ||vs_tab||'COD_MUNICIPIO'
                  ||vs_tab||'MUNICIPIO'
                  ||vs_tab||'COD_UND_PADRAO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'COD_MEDIDA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'QUANTIDADE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NORM_DEV' -- Item incluído 22/08/2016
                  ||vs_tab||'VALOR_UNITARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VLR_ITEM'
                  ||vs_tab||'COD_SITUACAO_PIS_ST'
                  ||vs_tab||'VLR_BASE_PIS_ST'
                  ||vs_tab||'VLR_ALIQ_PIS_ST'
                  ||vs_tab||'VLR_PIS_ST'
                  ||vs_tab||'COD_SITUACAO_COFINS_ST'
                  ||vs_tab||'VLR_BASE_COFINS_ST'
                  ||vs_tab||'VLR_ALIQ_COFINS_ST'
                  ||vs_tab||'VLR_COFINS_ST'
                  ||vs_tab||'DAT_LANC_PIS_COFINS'
                  ||vs_tab||'USUARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'DATA_OPERACAO' -- Item Incluído 08/08/2016
                  ;


                  lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end if;
            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               vs_linha :=  mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MOVTO_E_S -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.COD_DOCTO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.NUM_DOCFIS_REF -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_PRODUTO -- NOVA INCLUSÃO
                         ||vs_tab||mreg.CODIGO_PRODUTO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.CLAS_ITEM -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.CODIGO_NBM
                         ||vs_tab||mreg.IND_FIS_JUR -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.COD_NATUREZA_OP -- NOVA INCLUSÃO
                         ||vs_tab||mreg.DESCRICAO_NATUREZA_OP -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_situacao_a||mreg.cod_situacao_b
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FCP_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_ORIG),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_N_ESCRIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IPI),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_trib_ipi
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FRETE),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_SEGURO),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTRAS),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
                         ||vs_tab||mreg.NATUREZA_FRETE
                         ||vs_tab||mreg.IND_FATURA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_TP_FRETE
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.CHASSI -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.tipo_compra_venda --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.cod_fisjur_leasing --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.razao_lsg --NOVA INCLUSÃO 28-03-17--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.base_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||mreg.cod_conta
                         ||vs_tab||mreg.centro_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.vlr_comissao
                         ||vs_tab||mreg.cod_estado
                         ||vs_tab||mreg.cod_municipio
                         ||vs_tab||mreg.descr_mun
                         ||vs_tab||mreg.COD_UND_PADRAO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.COD_MEDIDA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.QUANTIDADE -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NORM_DEV -- Item incluído 22/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_UNIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ITEM),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_PIS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_PIS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_COFINS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_COFINS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.DAT_LANC_PIS_COFINS
                         ||vs_tab||mreg.USUARIO -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.DAT_OPERACAO -- Item Incluído 08/08/2016
                         ;
                         lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end loop;



  end gera_merc_mainframe;


-- todos os sistemas
  procedure gera_merc (vs_cod_estab  varchar2
                     , vd_data_ini   date
                     , vd_data_fim   date)is



   cursor c_dados_merc (c_cod_estab  varchar2
                 , c_data_ini   date
                 , c_data_fim   date) is
       select 'ITEM'                  tipo_reg
           , x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x08.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x08.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item Incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x08.num_docfis           NUMERO_NF
           , x08.serie_docfis         SERIE_NF
           , x08.num_item             NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , x2013.ind_produto        IND_PRODUTO -- NOVA INCLUSÃO
           , x2013.cod_produto        CODIGO_PRODUTO
           , x2013.descricao          DESCRICAO
           , x2013.CLAS_ITEM          CLAS_ITEM -- Item Incluído 08/08/2016
           , nvl(x2043.cod_nbm,' ')   CODIGO_NBM
           , x08.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x08.vlr_contab_item      VALOR_CONTABIL
           , x08.aliq_tributo_icms    ALIQ_ICMS
           , x08.vlr_base_icms_1      BASE_ICMS_1
           , x08.vlr_base_icms_2      BASE_ICMS_2
           , x08.vlr_base_icms_3      BASE_ICMS_3
           , x08.vlr_base_icms_4      BASE_ICMS_4
           , x08.vlr_tributo_icms     VALOR_ICMS
           , x08.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x08.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , x08.VLR_FCP_UF_DEST      VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_DEST     VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , x08.VLR_ICMS_UF_ORIG     VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , x08.Vlr_Icmss_Ndestac    VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , x08.Vlr_Icmss_n_Escrit   VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x08.aliq_tributo_ipi     ALIQ_IPI
           , x08.vlr_base_ipi_1       BASE_IPI_1
           , x08.vlr_base_ipi_2       BASE_IPI_2
           , x08.vlr_base_ipi_3       BASE_IPI_3
           , x08.vlr_base_ipi_4       BASE_IPI_4
           , x08.vlr_tributo_ipi      VALOR_IPI
           , x08.cod_situacao_pis     COD_SIT_PIS
           , x08.vlr_aliq_pis         ALIQ_PIS
           , x08.vlr_base_pis         BASE_PIS
           , x08.vlr_pis              VLR_PIS
           , x08.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_cofins  COD_SIT_COFINS
           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , x08.vlr_base_cofins      BASE_COFINS
           , x08.vlr_cofins           VALOR_COFINS
           , x08.vlr_frete            VLR_FRETE --NOVA INCLUSÃO 24-08--
           , x08.vlr_seguro           VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , x08.vlr_outras           VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , x08.ind_natureza_frete   NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , x08.CHASSI               CHASSI   -- Item Incluido 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , x08.base_icms_origdest   BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x08.vlr_icms_origdest    VLR_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , x2003.cod_custo          CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x08.vlr_tributo_icmss
           , x08.aliq_tributo_icmss
           , x08.vlr_base_icmss
           , x08.cod_trib_ipi
           , x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , x2017.cod_und_padrao     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , x2007.cod_medida         COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , x08.quantidade           QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , x08.VLR_ITEM
           , x08.VLR_UNIT             VLR_UNIT -- Item Incluido 08/08/2016
           , x08.COD_SITUACAO_PIS_ST
           , x08.VLR_BASE_PIS_ST
           , x08.VLR_ALIQ_PIS_ST
           , x08.VLR_PIS_ST
           , x08.COD_SITUACAO_COFINS_ST
           , x08.VLR_BASE_COFINS_ST
           , x08.VLR_ALIQ_COFINS_ST
           , x08.VLR_COFINS_ST
           , x08.DAT_LANC_PIS_COFINS
           , x08.USUARIO             USUARIO --  Item Incluido 08/08/2016
           , X08.DAT_OPERACAO        DAT_OPERACAO -- Item Incluido 08/08/2016
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x2017_und_padrao     x2017
          , x2007_medida         x2007
          , x04_pessoa_fis_jur   x04_2

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
      and x08.ident_docto          = x2005.ident_docto
      and x08.ident_und_padrao     = x2017.ident_und_padrao
      and x08.ident_medida         = x2007.ident_medida
      and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)


union all
        select  'CAPA'                  tipo_reg
           , x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x07.data_fiscal          DATA_FISCAL
           , x07.data_emissao         DATA_EMISSAO
           , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
           , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
           , x07.MOVTO_E_S            MOVTO_E_S -- Item incluído 08/08/2016
           , x2005.cod_docto          COD_DOCTO --NOVA INCLUSÃO 24-08--
           , x2024.cod_modelo         MODELO_NF
           , x07.num_docfis           NUMERO_NF
           , x07.serie_docfis         SERIE_NF
           , 0                        NUMERO_ITEM
           , decode(x07.situacao,'S','CANCELADA','N','NORMAL') SITUACAO
           , x07.num_docfis_ref       NUM_DOCFIS_REF      --NOVA INCLUSÃO 24-08--
           , null                     IND_PRODUTO -- NOVA INCLUSÃO
           , null                     CODIGO_PRODUTO
           , null                     DESCRICAO
           , null                     CLAS_ITEM -- Item Incluído 08/08/2016
           , null                     CODIGO_NBM
           , x07.ident_fis_jur        IND_FIS_JUR      --NOVA INCLUSÃO 24-08--
           , x04.cod_fis_jur          CODIGO_FIS_JUR
           , x04.razao_social         RAZAO_SOCIAL
           , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
           , x04.cpf_cgc              CGC
           , x2012.cod_cfo            CFOP
           , x2006.cod_natureza_op    COD_NATUREZA_OP -- NOVA INCLUSÃO
           , x2006.descricao          DESCRICAO_NATUREZA_OP       --NOVA INCLUSÃO 24-08--
           , x07.vlr_tot_nota         VALOR_CONTABIL
           , x07.aliq_tributo_icms    ALIQ_ICMS
           , x07.vlr_base_icms_1      BASE_ICMS_1
           , x07.vlr_base_icms_2      BASE_ICMS_2
           , x07.vlr_base_icms_3      BASE_ICMS_3
           , x07.vlr_base_icms_4      BASE_ICMS_4
           , x07.vlr_tributo_icms     VALOR_ICMS
           , x07.vlr_icms_ndestac     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           , x07.vlr_outros1          VLR_OUTROS1 -- NOVA INCLUSÃO
           , 0                        VLR_FCP_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_DEST -- Item Incluído 08/08/2016
           , 0                        VLR_ICMS_UF_ORIG -- Item Incluído 08/08/2016
           , null                     VLR_ICMSS_NDESTAC --NOVA INCLUSÃO 24-08--
           , null                     VLR_ICMSS_N_ESCRIT --NOVA INCLUSÃO 24-08--
           , x07.aliq_tributo_ipi     ALIQ_IPI
           , x07.vlr_base_ipi_1       BASE_IPI_1
           , x07.vlr_base_ipi_2       BASE_IPI_2
           , x07.vlr_base_ipi_3       BASE_IPI_3
           , x07.vlr_base_ipi_4       BASE_IPI_4
           , x07.vlr_tributo_ipi      VALOR_IPI
           , x07.cod_sit_pis          COD_SIT_PIS
           , x07.vlr_aliq_pis         ALIQ_PIS
           , x07.vlr_base_pis         BASE_PIS
           , x07.vlr_pis              VLR_PIS
           , x07.vlr_ipi_ndestac      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_cofins       COD_SIT_COFINS
           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , x07.vlr_base_cofins      BASE_COFINS
           , x07.vlr_cofins           VALOR_COFINS
           , null                     VLR_FRETE --NOVA INCLUSÃO 24-08--
           , null                     VLR_SEGURO --NOVA INCLUSÃO 24-08--
           , null                     VLR_OUTRAS --NOVA INCLUSÃO 24-08--
           , x07.num_autentic_nfe     NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , null                     NATUREZA_FRETE
           , x07.ind_fatura           IND_FATURA --NOVA INCLUSÃO 24-08--
           , x07.num_controle_docto   NUM_CONTROLE_DOCTO
           , null                     CHASSI -- Item Incluído 08/08/2016
           , x07.ind_compra_venda     TIPO_COMPRA_VENDA --NOVA INCLUSÃO 25-11--
           , x04_2.cpf_cgc            COD_FISJUR_LEASING --NOVA INCLUSÃO 25-11--
           , x04_2.razao_social       razao_lsg --NOVA INCLUSÃO 28-03-17--
           , null                     BASE_ICMS_ORIGDEST --NOVA INCLUSÃO 28-11--
           , null                     VLR_ICMS_ORIGDEST  --NOVA INCLUSÃO 28-11--
           , x2002.cod_conta          cod_conta
           , null                     CENTRO_CUSTO
           , x07.NUM_SELO_CONT_ICMS
           , y2025.cod_situacao_a
           , y2026.cod_situacao_b
           , x07.vlr_tributo_icmss
           , x07.aliq_tributo_icmss
           , x07.vlr_base_icmss
           , null --x07.cod_trib_ipi
           , null --x08.vlr_comissao
           , munic.cod_municipio
           , munic.descricao descr_mun
           , null                     COD_UND_PADRAO       --NOVA INCLUSÃO 24-08--
           , null                     COD_MEDIDA           --NOVA INCLUSÃO 24-08--
           , null                     QUANTIDADE           --NOVA INCLUSÃO 24-08--
           , x07.NORM_DEV             NORM_DEV -- Item incluído 22/08/2016
           , est.cod_estado
           , decode(x07.ind_tp_frete,'1','1 - CIF','2','2 - FOB','0', '0 - Outros', '') ind_tp_frete
           , 0
           , 0                        VLR_UNIT -- Item Incluído 08/08/2016
           , null
           , 0
           , 0
           , 0
           , null
           , 0
           , 0
           , 0
           , null
           , x07.USUARIO              USUARIO -- Item Incluído 08/08/2016
           , x07.DAT_OPERACAO         DAT_OPERACAO -- Item Incluído 08/08/2016
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , x2005_tipo_docto     x2005
          , municipio            munic
          , estado               est
          , x04_pessoa_fis_jur x04_2

    where x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a  (+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b  (+)
  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.NUM_SELO_CONT_ICMS   = 'S747MOTORES'
      and x04.ident_estado         = munic.ident_estado
      and x04.cod_municipio        = munic.cod_municipio(+)
      and est.ident_estado         = x04.ident_estado
      and x07.ident_docto          = x2005.ident_docto
      --and null --x07.ident
     -- and null --x08.ident_medida
     and x07.ident_fisjur_lsg     = x04_2.ident_fis_jur(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)

order by CODIGO_EMPRESA
        , ESTABELECIMENTO
        , data_fiscal
        , NUMERO_NF
        , SERIE_NF
        , NUMERO_ITEM;


  begin

     if vn_qtd_reg = 0 then

       -- insere cabecalho das colunas
       vs_linha :=   'TIPO_REG'
                  ||vs_tab||'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'DATA_FISCAL'
                  ||vs_tab||'DATA_EMISSAO'
                  ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                  ||vs_tab||'ENTRADA_SAIDA'
                  ||vs_tab||'MOVTO_E_S' -- Item Incluído 08/08/2016
                  ||vs_tab||'COD_DOCTO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'MODELO_NF'
                  ||vs_tab||'NUMERO_NF'
                  ||vs_tab||'SERIE_NF'
                  ||vs_tab||'NUMERO_ITEM'
                  ||vs_tab||'SITUACAO'
                  ||vs_tab||'NUM_DOCFIS_REF' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_PRODUTO' -- NOVA INCLUSÃO
                  ||vs_tab||'CODIGO_PRODUTO'
                  ||vs_tab||'DESCRICAO'
                  ||vs_tab||'CLASSIFICACAO ITEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'CODIGO_NBM'
                  ||vs_tab||'IND_FIS_JUR' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'CODIGO_FIS_JUR'
                  ||vs_tab||'RAZAO_SOCIAL'
                  ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                  ||vs_tab||'CGC'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'COD_NATUREZA_OP' -- NOVA INCLUSÃO
                  ||vs_tab||'DESCRICAO_NATUREZA_OP' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VALOR_CONTABIL'
                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  ||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'VALOR_FCP_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_DESTINO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VALOR_ICMS_UF_ORIGEM' -- Item Incluído 08/08/2016
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
                  ||vs_tab||'VLR_ICMSS_NDESTAC' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_ICMSS_N_ESCRIT' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  ||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  ||vs_tab||'VLR_FRETE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_SEGURO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'VLR_OUTRAS' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
                  ||vs_tab||'NATUREZA_FRETE'
                  ||vs_tab||'IND_FATURA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'IND_TP_FRETE'
                  ||vs_tab||'NUM_CONTROLE_DOCTO'
                  ||vs_tab||'CHASSI' -- Item Incluído 08/08/2016
                  ||vs_tab||'TIPO_COMPRA_VENDA' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'COD_FISJUR_LEASING' --NOVA INCLUSÃO 25-11--
                  ||vs_tab||'RAZAO_LEASING' --NOVA INCLUSÃO 28-03-17--
                  ||vs_tab||'BASE_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'VLR_ICMS_ORIGDEST' --NOVA INCLUSÃO 28-11--
                  ||vs_tab||'CONTA_CONTABIL'
                  ||vs_tab||'CENTRO_CUSTO'
                  ||vs_tab||'SISTEMA'
                  ||vs_tab||'VLR_COMISSAO'
                  ||vs_tab||'UF'
                  ||vs_tab||'COD_MUNICIPIO'
                  ||vs_tab||'MUNICIPIO'
                  ||vs_tab||'COD_UND_PADRAO' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'COD_MEDIDA' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'QUANTIDADE' -- NOVA INCLUSÃO 24-08 --
                  ||vs_tab||'NOR_DEV' -- Item incluído 22/08/2016
                  ||vs_tab||'VALOR_UNITARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'VLR_ITEM'
                  ||vs_tab||'COD_SITUACAO_PIS_ST'
                  ||vs_tab||'VLR_BASE_PIS_ST'
                  ||vs_tab||'VLR_ALIQ_PIS_ST'
                  ||vs_tab||'VLR_PIS_ST'
                  ||vs_tab||'COD_SITUACAO_COFINS_ST'
                  ||vs_tab||'VLR_BASE_COFINS_ST'
                  ||vs_tab||'VLR_ALIQ_COFINS_ST'
                  ||vs_tab||'VLR_COFINS_ST'
                  ||vs_tab||'DAT_LANC_PIS_COFINS'
                  ||vs_tab||'USUARIO' -- Item Incluído 08/08/2016
                  ||vs_tab||'DATA_OPERACAO' -- Item Incluído 08/08/2016
                  ;


                  lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end if;

            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               vs_linha :=   mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MOVTO_E_S -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.COD_DOCTO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.NUM_DOCFIS_REF -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_PRODUTO -- NOVA INCLUSÃO
                         ||vs_tab||mreg.CODIGO_PRODUTO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.CLAS_ITEM -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.CODIGO_NBM
                         ||vs_tab||mreg.IND_FIS_JUR -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.COD_NATUREZA_OP -- NOVA INCLUSÃO
                         ||vs_tab||mreg.DESCRICAO_NATUREZA_OP -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_situacao_a||mreg.cod_situacao_b
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FCP_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_DEST),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_UF_ORIG),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMSS_N_ESCRIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IPI),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.cod_trib_ipi
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_FRETE),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_SEGURO),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTRAS),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
                         ||vs_tab||mreg.NATUREZA_FRETE
                         ||vs_tab||mreg.IND_FATURA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.IND_TP_FRETE
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.CHASSI -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.tipo_compra_venda --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.cod_fisjur_leasing --NOVA INCLUSÃO 25-11--
                         ||vs_tab||mreg.razao_lsg --NOVA INCLUSÃO 28-03-17--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.base_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_icms_origdest),'9,999,999,999.99'),'.',';'),',','.'),';',',')) --NOVA INCLUSÃO 28-11--
                         ||vs_tab||mreg.cod_conta
                         ||vs_tab||mreg.centro_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.vlr_comissao
                         ||vs_tab||mreg.cod_estado
                         ||vs_tab||mreg.cod_municipio
                         ||vs_tab||mreg.descr_mun
                         ||vs_tab||mreg.COD_UND_PADRAO -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.COD_MEDIDA -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.QUANTIDADE -- NOVA INCLUSÃO 24-08 --
                         ||vs_tab||mreg.NORM_DEV -- Item incluído 22/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_UNIT),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- Item Incluído 08/08/2016
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ITEM),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_PIS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_PIS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SITUACAO_COFINS_ST
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_BASE_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ALIQ_COFINS_ST),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_COFINS_ST),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.DAT_LANC_PIS_COFINS
                         ||vs_tab||mreg.USUARIO -- Item Incluído 08/08/2016
                         ||vs_tab||mreg.DAT_OPERACAO -- Item Incluído 08/08/2016
                         ;
                         lib_proc.add(vs_linha, null, null, 1);

            vn_qtd_reg := vn_qtd_reg +1;

            end loop;



  end gera_merc;


 procedure gera_serv (vs_cod_estab  varchar2
                     , vd_data_ini   date
                     , vd_data_fim   date) is

  vDatAIDF X106_MOVTO_AIDF.DAT_AIDF%TYPE;

  cursor dados_serv (c_cod_estab  varchar2
                   , c_data_ini   date
                   , c_data_fim   date) is

   select 'ITEMSERV'               tipo_reg
        , x09.cod_empresa          CODIGO_EMPRESA
        , x09.cod_estab            ESTABELECIMENTO
        , x09.data_fiscal          DATA_FISCAL
        , x07.data_emissao         DATA_EMISSAO
        , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
        , decode(x09.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
        , x2024.cod_modelo         MODELO_NF
        , x2005.cod_docto          TIPO_DOCUMENTO
        , x07.cod_class_doc_fis    CLASSIFICACAO
        , x2018.cod_servico        CODIGO_SERVICO
        , x2002.cod_conta          CODIGO_CONTA
        , x09.num_docfis           NUMERO_NF
        , x09.serie_docfis         SERIE_NF
        , x09.num_item             NUMERO_ITEM
        , decode(x07.situacao,'S','CANCELADA','NORMAL') SITUACAO
        , x04.cod_fis_jur          CODIGO_FIS_JUR
        , x04.razao_social         RAZAO_SOCIAL
        , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
        , x04.cpf_cgc              CGC
        , x09.vlr_tot              VALOR_TOTAL
        , x2012.cod_cfo            CFOP
        , x2006.cod_natureza_op    NAT_OPERACAO
        , x2006.descricao          DESCRICAO
        , x09.descricao_compl      DESCR_COMPL
        , x09.aliq_tributo_ir      ALIQ_IR
        , x09.vlr_tributo_ir       VALOR_IR
        , x09.aliq_tributo_iss     ALIQ_ISS
        , x09.vlr_tributo_iss      VLR_ISS
        , x09.vlr_iss_retido       ISS_RETIDO
        , x09.cod_situacao_pis     COD_SIT_PIS
        , x09.vlr_aliq_pis         ALIQ_PIS
        , x09.vlr_base_pis         BASE_PIS
        , x09.vlr_pis              VLR_PIS
        , x09.cod_situacao_cofins  COD_SIT_COFINS
        , x09.vlr_aliq_cofins      ALIQ_COFINS
        , x09.vlr_base_cofins      BASE_COFINS
        , x09.vlr_cofins           VALOR_COFINS
        , x07.num_controle_docto
        , x2003.cod_custo
        , x07.NUM_SELO_CONT_ICMS
        , x07.dat_valid_doc_aidf
        , x07.ident_docto
        , x07.ident_modelo
-- 001
        , x09.dat_lanc_pis_cofins
-- 001
     from dwt_docto_fiscal     x07
        , dwt_itens_serv       x09
        , x04_pessoa_fis_jur   x04
        , x2012_cod_fiscal     x2012
        , x2018_servicos       x2018
        , x2006_natureza_op    x2006
        , x2024_modelo_docto   x2024
        , x2005_tipo_docto     x2005
        , x2003_centro_custo   x2003
        , x2002_plano_contas   x2002
    where x09.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur       (+)
      and x09.ident_cfo            = x2012.ident_cfo         (+)
      and x09.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x09.ident_servico        = x2018.ident_servico     (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.ident_docto          = x2005.ident_docto
      and x09.ident_conta          = x2002.ident_conta       (+)
      and x09.ident_custo          = x2003.ident_custo       (+)
      and x09.cod_empresa          = mcod_empresa
      and x09.cod_estab            = c_cod_estab
      and x09.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_class_doc_fis  in ('2','3')
union all
   select 'CAPASERV'               tipo_reg
        , x07.cod_empresa          CODIGO_EMPRESA
        , x07.cod_estab            ESTABELECIMENTO
        , x07.data_fiscal          DATA_FISCAL
        , x07.data_emissao         DATA_EMISSAO
        , x07.data_saida_rec       DATA_SAIDA_RECEBIMENTO
        , decode(x07.movto_e_s,'9','SAIDA','ENTRADA') ENTRADA_SAIDA
        , x2024.cod_modelo         MODELO_NF
        , x2005.cod_docto          TIPO_DOCUMENTO
        , x07.cod_class_doc_fis    CLASSIFICACAO
        , null                     CODIGO_SERVICO
        , x2002.cod_conta          CODIGO_CONTA
        , x07.num_docfis           NUMERO_NF
        , x07.serie_docfis         SERIE_NF
        , 0                        NUMERO_ITEM
        , decode(x07.situacao,'S','CANCELADA','NORMAL') SITUACAO
        , x04.cod_fis_jur          CODIGO_FIS_JUR
        , x04.razao_social         RAZAO_SOCIAL
        , replace(x04.insc_estadual,' ','')        INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
        , x04.cpf_cgc              CGC
        , x07.vlr_tot_nota         VALOR_TOTAL
        , x2012.cod_cfo            CFOP
        , x2006.cod_natureza_op    NAT_OPERACAO
        , x2006.descricao          DESCRICAO
        , null --x07.descricao_compl      DESCR_COMPL
        , x07.aliq_tributo_ir      ALIQ_IR
        , x07.vlr_tributo_ir       VALOR_IR
        , x07.aliq_tributo_iss     ALIQ_ISS
        , x07.vlr_tributo_iss      VLR_ISS
        , x07.vlr_iss_retido       ISS_RETIDO
        , x07.cod_sit_pis          COD_SIT_PIS
        , x07.vlr_aliq_pis         ALIQ_PIS
        , x07.vlr_base_pis         BASE_PIS
        , x07.vlr_pis              VLR_PIS
        , x07.cod_sit_cofins       COD_SIT_COFINS
        , x07.vlr_aliq_cofins      ALIQ_COFINS
        , x07.vlr_base_cofins      BASE_COFINS
        , x07.vlr_cofins           VALOR_COFINS
        , x07.num_controle_docto
        , null                     cod_custo
        , x07.NUM_SELO_CONT_ICMS
        , x07.dat_valid_doc_aidf
        , x07.ident_docto
        , x07.ident_modelo
-- 001
        , x07.dat_lanc_pis_cofins
-- 001
     from dwt_docto_fiscal     x07
        , x04_pessoa_fis_jur   x04
        , x2012_cod_fiscal     x2012
   --     , x2018_servicos       x2018
        , x2006_natureza_op    x2006
        , x2024_modelo_docto   x2024
        , x2005_tipo_docto     x2005
        , x2002_plano_contas   x2002
    where x07.ident_fis_jur        = x04.ident_fis_jur       (+)
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      --and x07.ident_servico        = x2018.ident_servico     (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.ident_docto          = x2005.ident_docto
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.cod_empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_class_doc_fis  in ('2')
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)
order by CODIGO_EMPRESA,
         ESTABELECIMENTO,
         data_fiscal,
         NUMERO_NF,
         serie_nf,
         NUMERO_ITEM;


  begin


        vs_linha :=  'TIPO_REG'
                   ||vs_tab||'CODIGO_EMPRESA'
                   ||vs_tab||'ESTABELECIMENTO'
                   ||vs_tab||'DATA_FISCAL'
                   ||vs_tab||'DATA_EMISSAO'
                   ||vs_tab||'DATA_SAIDA_RECEBIMENTO'
                   ||vs_tab||'ENTRADA_SAIDA'
                   ||vs_tab||'MODELO_NF'
                   ||vs_tab||'TIPO_DOCUMENTO'
                   ||vs_tab||'CLASSIFICACAO'
                   ||vs_tab||'CODIGO_SERVICO'
                   ||vs_tab||'CODIGO_CONTA'
                   ||vs_tab||'NUMERO_NF'
                   ||vs_tab||'SERIE_NF'
                   ||vs_tab||'NUMERO_ITEM'
                   ||vs_tab||'SITUACAO'
                   ||vs_tab||'CODIGO_FIS_JUR'
                   ||vs_tab||'RAZAO_SOCIAL'
                   ||vs_tab||'INSCRICAO_ESTADUAL'  --NOVA INCLUSÃO 14-06-16--
                   ||vs_tab||'CGC'
                   ||vs_tab||'VALOR_TOTAL'
                   ||vs_tab||'CFOP'
                   ||vs_tab||'NAT_OPERACAO'
                   ||vs_tab||'DESCRICAO'
                   ||vs_tab||'DESCR_COMPL'
                   ||vs_tab||'ALIQ_IR'
                   ||vs_tab||'VALOR_IR'
                   ||vs_tab||'ALIQ_ISS'
                   ||vs_tab||'VLR_ISS'
                   ||vs_tab||'ISS_RETIDO'
                   ||vs_tab||'COD_SIT_PIS'
                   ||vs_tab||'ALIQ_PIS'
                   ||vs_tab||'BASE_PIS'
                   ||vs_tab||'VLR_PIS'
                   ||vs_tab||'COD_SIT_COFINS'
                   ||vs_tab||'ALIQ_COFINS'
                   ||vs_tab||'BASE_COFINS'
                   ||vs_tab||'VALOR_COFINS'
                   ||vs_tab||'NUM_CONTROLE_DOCTO'
                   ||vs_tab||'CENTRO_CUSTO'
                   ||vs_tab||'SISTEMA'
                   ||vs_tab||'DAT_VALID_DOC_AIDF'
                   ||vs_tab||'DAT_AIDF'
-- 001
                   ||vs_tab||'DAT_LANC_PIS_COFINS'
-- 001
                   ;
                   lib_proc.add(vs_linha, null, null, 2);




           for mreg in dados_serv (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               --busca data AIDF na x106
               Begin
                Select x106.DAT_AIDF
                  into vDatAIDF
                  from x106_movto_aidf x106
                 Where x106.cod_empresa = mcod_empresa
                   and x106.cod_estab = mreg.ESTABELECIMENTO
                   and x106.dat_movto = mreg.data_fiscal
                   and x106.ident_docto = mreg.ident_docto
                   and x106.ident_modelo = mreg.ident_modelo
                   and x106.num_docfis_ini >= mreg.numero_nf
                   and x106.num_docfis_fim <= mreg.numero_nf;
               Exception
                When Others Then
                   vDatAIDF := null;
               End;


               vs_linha := mreg.tipo_reg
                         ||vs_tab||mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.DATA_FISCAL
                         ||vs_tab||mreg.DATA_EMISSAO
                         ||vs_tab||mreg.DATA_SAIDA_RECEBIMENTO
                         ||vs_tab||mreg.ENTRADA_SAIDA
                         ||vs_tab||mreg.MODELO_NF
                         ||vs_tab||mreg.TIPO_DOCUMENTO
                         ||vs_tab||mreg.CLASSIFICACAO
                         ||vs_tab||mreg.CODIGO_SERVICO
                         ||vs_tab||mreg.CODIGO_CONTA
                         ||vs_tab||mreg.NUMERO_NF
                         ||vs_tab||mreg.SERIE_NF
                         ||vs_tab||mreg.NUMERO_ITEM
                         ||vs_tab||mreg.SITUACAO
                         ||vs_tab||mreg.CODIGO_FIS_JUR
                         ||vs_tab||mreg.RAZAO_SOCIAL
                         ||vs_tab||mreg.INSCRICAO_ESTADUAL  --NOVA INCLUSÃO 14-06-16--
                         ||vs_tab||mreg.CGC
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_TOTAL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||mreg.NAT_OPERACAO
                         ||vs_tab||mreg.DESCRICAO
                         ||vs_tab||mreg.DESCR_COMPL
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_IR),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IR),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ISS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ISS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ISS_RETIDO),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_PIS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.num_controle_docto
                         ||vs_tab||mreg.cod_custo
                         ||vs_tab||mreg.NUM_SELO_CONT_ICMS
                         ||vs_tab||mreg.dat_valid_doc_aidf
                         ||vs_tab||vDatAIDF
-- 001
                         ||vs_tab||mreg.dat_lanc_pis_cofins
-- 001
                         ;
                         lib_proc.add(vs_linha, null, null, 2);


            vn_qtd_reg_serv := vn_qtd_reg_serv +1;

            vDatAIDF := null;


            end loop;



  end gera_serv;

  procedure gera_consolidado(vs_cod_estab  varchar2
                           , vd_data_ini   date
                           , vd_data_fim   date) is

   cursor c_dados_merc (c_cod_estab  varchar2
                 , c_data_ini   date
                 , c_data_fim   date) is
      select x08.cod_empresa          CODIGO_EMPRESA
           , x08.cod_estab            ESTABELECIMENTO
           , x2012.cod_cfo            CFOP
           , nvl(sum(x08.vlr_contab_item),0)      VALOR_CONTABIL
--           , x08.aliq_tributo_icms    ALIQ_ICMS
           , nvl(sum(x08.vlr_base_icms_1),0)      BASE_ICMS_1
           , nvl(sum(x08.vlr_base_icms_2),0)      BASE_ICMS_2
           , nvl(sum(x08.vlr_base_icms_3),0)      BASE_ICMS_3
           , nvl(sum(x08.vlr_base_icms_4),0)      BASE_ICMS_4
           , nvl(sum(x08.vlr_tributo_icms),0)     VALOR_ICMS
          -- , nvl(sum(x08.vlr_tributo_icms),0)     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
           --, nvl(sum(x08.vlr_tributo_icms),0)     VLR_OUTROS1 -- NOVA INCLUSÃO
           , nvl(sum(x08.vlr_base_ipi_1),0)       BASE_IPI_1
           , nvl(sum(x08.vlr_base_ipi_2),0)       BASE_IPI_2
           , nvl(sum(x08.vlr_base_ipi_3),0)       BASE_IPI_3
           , nvl(sum(x08.vlr_base_ipi_4 ),0)      BASE_IPI_4
           , nvl(sum(x08.vlr_tributo_ipi),0)      VALOR_IPI
        --   , nvl(sum(x08.vlr_ipi_ndestac),0)      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x08.cod_situacao_pis                 COD_SIT_PIS
--           , x08.vlr_aliq_pis         ALIQ_PIS
           , nvl(sum(x08.vlr_base_pis),0)         BASE_PIS
           , nvl(sum(x08.vlr_pis),0)              VLR_PIS
           , x08.cod_situacao_cofins              COD_SIT_COFINS
--           , x08.vlr_aliq_cofins      ALIQ_COFINS
           , nvl(sum(x08.vlr_base_cofins),0)      BASE_COFINS
           , nvl(sum(x08.vlr_cofins),0)           VALOR_COFINS
         --  , x07.num_autentic_nfe                 NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , nvl(sum(x08.vlr_tributo_icmss),0)    vlr_tributo_icmss
--           , x08.aliq_tributo_icmss
           , nvl(sum(x08.vlr_base_icmss),0)       vlr_base_icmss
--           , x08.cod_trib_ipi
--           , nvl(sum(x08.vlr_comissao),0)         vlr_comissao
       from dwt_docto_fiscal     x07
          , dwt_itens_merc       x08
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2013_produto        x2013
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2043_cod_nbm        x2043
          , x2003_centro_custo   x2003
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , municipio            munic
          , estado               est

    where x08.ident_docto_fiscal   = x07.ident_docto_fiscal
      and x07.ident_fis_jur        = x04.ident_fis_jur
      and x08.ident_cfo            = x2012.ident_cfo         (+)
      and x08.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x08.ident_produto        = x2013.ident_produto     (+)
      and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x08.ident_custo          = x2003.ident_custo       (+)
      and x08.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x08.data_fiscal          between c_data_ini and c_data_fim
      and x08.cod_Empresa          = mcod_empresa
      and x08.cod_estab            = c_cod_estab
      and x08.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x08.ident_situacao_b     = y2026.ident_situacao_b(+)
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)
group by x08.cod_empresa
           , x08.cod_estab
           , x2012.cod_cfo
           , x08.cod_situacao_pis
           , x08.cod_situacao_cofins

union all
       select  x07.cod_empresa          CODIGO_EMPRESA
           , x07.cod_estab            ESTABELECIMENTO
           , x2012.cod_cfo            CFOP
           , nvl(sum(x07.vlr_tot_nota),0)         VALOR_CONTABIL
--           , x07.aliq_tributo_icms    ALIQ_ICMS
           , nvl(sum(x07.vlr_base_icms_1),0)      BASE_ICMS_1
           , nvl(sum(x07.vlr_base_icms_2),0)      BASE_ICMS_2
           , nvl(sum(x07.vlr_base_icms_3),0)      BASE_ICMS_3
           , nvl(sum(x07.vlr_base_icms_4),0)      BASE_ICMS_4
           , nvl(sum(x07.vlr_tributo_icms),0)     VALOR_ICMS
      --    , nvl(sum(x07.vlr_tributo_icms),0)     VLR_ICMS_NDESTAC -- NOVA INCLUSÃO
       --    , nvl(sum(x07.vlr_tributo_icms),0)     VLR_OUTROS1 -- NOVA INCLUSÃO
--           , x07.aliq_tributo_ipi     ALIQ_IPI
           , nvl(sum(x07.vlr_base_ipi_1),0)       BASE_IPI_1
           , nvl(sum(x07.vlr_base_ipi_2),0)       BASE_IPI_2
           , nvl(sum(x07.vlr_base_ipi_3),0)       BASE_IPI_3
           , nvl(sum(x07.vlr_base_ipi_4),0)       BASE_IPI_4
           , nvl(sum(x07.vlr_tributo_ipi),0)      VALOR_IPI
     --      , nvl(sum(x07.vlr_ipi_ndestac),0)      VLR_IPI_NDESTAC -- NOVA INCLUSÃO
           , x07.cod_sit_pis          COD_SIT_PIS
--           , x07.vlr_aliq_pis         ALIQ_PIS
           , nvl(sum(x07.vlr_base_pis),0)         BASE_PIS
           , nvl(sum(x07.vlr_pis),0)              VLR_PIS
           , x07.cod_sit_cofins       COD_SIT_COFINS
--           , x07.vlr_aliq_cofins      ALIQ_COFINS
           , nvl(sum(x07.vlr_base_cofins),0)      BASE_COFINS
           , nvl(sum(x07.vlr_cofins),0)           VALOR_COFINS
     --      , x07.num_autentic_nfe                 NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
           , nvl(sum(x07.vlr_tributo_icmss),0)
--           , x07.aliq_tributo_icmss
           , nvl(sum(x07.vlr_base_icmss),0)
--           , 0 --x08.vlr_comissao
       from dwt_docto_fiscal     x07
          , x04_pessoa_fis_jur   x04
          , x2012_cod_fiscal     x2012
          , x2006_natureza_op    x2006
          , x2024_modelo_docto   x2024
          , x2002_plano_contas   x2002
          , y2025_sit_trb_uf_a   y2025
          , y2026_sit_trb_uf_b   y2026
          , municipio            munic
          , estado               est

    where  x07.ident_fis_jur        = x04.ident_fis_jur
      and x07.ident_cfo            = x2012.ident_cfo         (+)
      and x07.ident_natureza_op    = x2006.ident_natureza_op (+)
      and x07.ident_conta          = x2002.ident_conta       (+)
      and x07.ident_situacao_a     = y2025.ident_situacao_a(+)
      and x07.ident_situacao_b     = y2026.ident_situacao_b(+)

  --    and x08.ident_produto        = x2013.ident_produto     (+)
  --    and x08.ident_nbm            = x2043.ident_nbm         (+)
      and x07.ident_modelo         = x2024.ident_modelo
      and x07.cod_class_doc_fis in ('1','3')
      and x07.data_fiscal          between c_data_ini and c_data_fim
      and x07.cod_Empresa          = mcod_empresa
      and x07.cod_estab            = c_cod_estab
      and x04.ident_estado         = munic.ident_estado(+)
      and x04.cod_municipio        = munic.cod_municipio(+)
      and x04.ident_estado         = est.ident_estado(+)

      and not exists (select 1
                        from dwt_itens_merc x08
                       where x08.ident_docto_fiscal = x07.ident_docto_fiscal)
      and not exists (select 1
                        from dwt_itens_serv x09
                       where x09.ident_docto_fiscal = x07.ident_docto_fiscal)
   group by  x07.cod_empresa
           , x07.cod_estab
           , x2012.cod_cfo
           , x07.cod_sit_pis
           , x07.cod_sit_cofins;


  begin

     if vn_qtd_reg_consol = 0 then

       -- insere cabecalho das colunas
        vs_linha :=  'CODIGO_EMPRESA'
                  ||vs_tab||'ESTABELECIMENTO'
                  ||vs_tab||'CFOP'
                  ||vs_tab||'VALOR_CONTABIL'
--                  ||vs_tab||'ALIQ_ICMS'
                  ||vs_tab||'BASE_ICMS_1'
                  ||vs_tab||'BASE_ICMS_2'
                  ||vs_tab||'BASE_ICMS_3'
                  ||vs_tab||'BASE_ICMS_4'
                  ||vs_tab||'VALOR_ICMS'
                  --||vs_tab||'VLR_ICMS_NDESTAC' -- NOVA INCLUSÃO
                 --||vs_tab||'VLR_OUTROS1' -- NOVA INCLUSÃO
--                  ||vs_tab||'CST_ICMS'
                  ||vs_tab||'BASE_ICMS-ST'
                  ||vs_tab||'VALOR_ICMS-ST'
--                  ||vs_tab||'ALIQ_IPI'
                  ||vs_tab||'BASE_IPI_1'
                  ||vs_tab||'BASE_IPI_2'
                  ||vs_tab||'BASE_IPI_3'
                  ||vs_tab||'BASE_IPI_4'
                  ||vs_tab||'VALOR_IPI'
                  --||vs_tab||'VLR_IPI_NDESTAC' -- NOVA INCLUSÃO
--                  ||vs_tab||'CST_IPI'
                  ||vs_tab||'COD_SIT_PIS'
--                  ||vs_tab||'ALIQ_PIS'
                  ||vs_tab||'BASE_PIS'
                  ||vs_tab||'VLR_PIS'
                  ||vs_tab||'COD_SIT_COFINS'
--                  ||vs_tab||'ALIQ_COFINS'
                  ||vs_tab||'BASE_COFINS'
                  ||vs_tab||'VALOR_COFINS'
                  --||vs_tab||'NUM_AUTENTIC_NFE' -- NOVA INCLUSÃO
--                  ||vs_tab||'VLR_COMISSAO'
                  ;

                  lib_proc.add(vs_linha, null, null, 2);

            vn_qtd_reg_consol := vn_qtd_reg_consol +1;

            end if;

            for mreg in c_dados_merc (vs_cod_estab
                                    , vd_data_ini
                                    , vd_data_fim) loop

               vs_linha := mreg.CODIGO_EMPRESA
                         ||vs_tab||mreg.ESTABELECIMENTO
                         ||vs_tab||mreg.CFOP
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_CONTABIL),'9,999,999,999.99'),'.',';'),',','.'),';',','))
--                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_ICMS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_ICMS_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_ICMS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         --||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_ICMS_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         --||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_OUTROS1),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_base_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.vlr_tributo_icmss),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_1),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_2),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_3),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_IPI_4),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_IPI),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         --||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_IPI_NDESTAC),'9,999,999,999.99'),'.',';'),',','.'),';',',')) -- NOVA INCLUSÃO
                         ||vs_tab||mreg.COD_SIT_PIS
--                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_PIS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VLR_PIS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||mreg.COD_SIT_COFINS
--                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.ALIQ_COFINS),'999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.BASE_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         ||vs_tab||trim(REPLACE(REPLACE(REPLACE(TO_CHAR(to_number(mreg.VALOR_COFINS),'9,999,999,999.99'),'.',';'),',','.'),';',','))
                         --||vs_tab||mreg.NUM_AUTENTIC_NFE -- NOVA INCLUSÃO
--                         ||vs_tab||mreg.vlr_comissao
;
                         lib_proc.add(vs_linha, null, null, 2);

            vn_qtd_reg_consol := vn_qtd_reg_consol +1;


            end loop;




  end;


  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN

    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('Usuario');

    LIB_PROC.add_param(pstr, 'Data Inicio', 'date', 'textbox', 'S', null, 'dd/mm/yyyy');
    LIB_PROC.add_param(pstr, 'Data Fim', 'date', 'textbox', 'S', null, 'dd/mm/yyyy');

    LIB_PROC.add_param(pstr,'Mercadoria/Servico','varchar2','listbox','S',1,null,'1=Mercadoria,2=Serviço,3=Todos');

    LIB_PROC.add_param(pstr,'Agrupado CST-CFOP','Varchar2','Listbox', 'S', 'N', null,'S=Sim,N=Não');

    lib_proc.add_param(pstr, '                            Sistemas Grupo Fiat:Notas Fiscais de Mercadorias'  , 'varchar2'  , 'text'  , 'N', null   , null) ;

    LIB_PROC.add_param(pstr,'Ivecore','varchar2','checkbox','N','N',null,null);
    LIB_PROC.add_param(pstr,'Sapiens','varchar2','checkbox','N','N',null,null);
    LIB_PROC.add_param(pstr,'PowerSAP','varchar2','checkbox','N','N',null,null);
    LIB_PROC.add_param(pstr,'Mainframe','varchar2','checkbox','N','N',null,null);
    LIB_PROC.add_param(pstr,'Outros Sistemas (Todas NF so pode ser utilizado sozinho)','varchar2','checkbox','N','N',null,null);



    LIB_PROC.add_param(pstr,'Estabelecimento','Varchar2','MultiSelect','S', NULL, NULL,
                      'select estab.cod_estab, estab.cod_estab || '' - '' || estab.razao_social '||
                      'from estabelecimento estab '||
                      'where estab.cod_empresa ='''||mcod_empresa||'''  '||
                      'order by 1 ',
                      'S');
                      
                      
   Lib_proc.add_param(pstr, ' '  , 'varchar2'  , 'text'  , 'N', null   , null) ;             
   Lib_proc.add_param(pstr, 'OBS.: É NECESSÁRIO A GERAÇÃO DO DATAMART ANTES DA EXECUÇÃO DO RELATÓRO.'  , 'varchar2'  , 'text'  , 'N', null   , null) ;
   Lib_proc.add_param(pstr, ' '  , 'varchar2'  , 'text'  , 'N', null   , null) ;

    RETURN pstr;

  END;

  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS - Relatórios Analíticos / Documentario Fiscal';
  END;

  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Geracao de relatorios analiticos de apoio ao PIS/COFINS';
  END;

  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PIS COFINS';
  END;

FUNCTION Executar(pd_data_ini      date
                , pd_data_fim      date
                , pind_geracao     char
                , pind_consol      char
                , pind_ivecore     char
                , pind_sapiens     char
                , pind_powersap    char
                , pind_mainframe   char
                , pind_outros      char
                , pcod_estab       LIB_PROC.varTab
                  ) RETURN INTEGER IS


    /* Variaveis de Trabalho */
    mproc_id                 integer;
    vs_cod_estab             varchar2(6);
    vd_data_limite           date;



  BEGIN



    mproc_id := LIB_PROC.new('GSR_ARQREL_PIS_COFINS_CPROC', 48, 150);

    mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    musuario     := LIB_PARAMETROS.Recuperar('Usuario');


    vs_ind_ivecore   := pind_ivecore;
    vs_ind_sapiens   := pind_sapiens;
    vs_ind_powersap  := pind_powersap;
    vs_ind_mainframe := pind_mainframe;
    vs_ind_outros    := pind_outros;

begin
select pd_data_ini + (INTERVAL '1' month )
into vd_data_limite
from dual;
exception when others then
vd_data_limite := pd_data_fim;
end;


if pd_data_fim > vd_data_limite then

   raise_application_error(-20000, 'Limite maximo de 1 mes para geracao');

end if;


--lib_proc.add_log(vs_ind_ivecore||vs_ind_sapiens||vs_ind_powersap||vs_ind_mainframe||vs_ind_outros,1);

    if pind_geracao = 1 then -- Mercadoria

          LIB_PROC.add_tipo(mproc_id, 1, 'PIS_COFINS_MERC', 2);

        if pind_consol = 'S' then
           LIB_PROC.add_tipo(mproc_id, 2, 'PIS_COFINS_MERC_CONSOL', 2);

        end if;

         if vs_ind_ivecore = 'N'
            and vs_ind_sapiens = 'N'
            and vs_ind_powersap = 'N'
            and vs_ind_mainframe = 'N'
            and vs_ind_outros = 'N' then

            raise_application_error(-20000, 'Favor selecionar pelo menos um sistema!!!');

          else

          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

              vs_cod_estab := pcod_estab(cont_estab);



              if vs_ind_outros = 'S' and (vs_ind_mainframe = 'S' or vs_ind_powersap = 'S' or vs_ind_sapiens = 'S' or vs_ind_ivecore = 'S') then

                     raise_application_error(-20000, 'Outros Sistemas, so pode ser utilizado sozinho, pois já esta contida todas as informacoes da base de NF!!!');


              else

                      if vs_ind_ivecore = 'S' then

                         gera_merc_ivecore(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_sapiens = 'S' then

                         gera_merc_sapiens(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_powersap = 'S' then

                         gera_merc_powersap(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_mainframe = 'S' then

                         gera_merc_mainframe(vs_cod_estab
                                           , pd_data_ini
                                           , pd_data_fim);
                      end if;

                      if vs_ind_outros = 'S' then

                         gera_merc(vs_cod_estab
                                 , pd_data_ini
                                 , pd_data_fim);
                      end if;

                      if pind_consol = 'S' then

                         gera_consolidado(vs_cod_estab
                                        , pd_data_ini
                                        , pd_data_fim);
                      end if;


              end if;


          end loop;
          end if;
    elsif pind_geracao = 2 then -- Servicos

          LIB_PROC.add_tipo(mproc_id, 2, 'PIS_COFINS_SERV', 2);


          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

             vs_cod_estab := pcod_estab(cont_estab);

             gera_serv(vs_cod_estab
                     , pd_data_ini
                     , pd_data_fim);

          end loop;


    else -- Todos

          LIB_PROC.add_tipo(mproc_id, 1, 'PIS_COFINS_MERC', 2);
          LIB_PROC.add_tipo(mproc_id, 2, 'PIS_COFINS_SERV', 2);

          FOR cont_estab IN 1 .. pcod_estab.COUNT LOOP

             vs_cod_estab := pcod_estab(cont_estab);



              if vs_ind_outros = 'S' and (vs_ind_mainframe = 'S' or vs_ind_powersap = 'S' or vs_ind_sapiens = 'S' or vs_ind_ivecore = 'S') then

                     raise_application_error(-20000, 'Outros Sistemas, so pode ser utilizado sozinho, pois já esta contida todas as informacoes da base de NF!!!');


              else

                      if vs_ind_ivecore = 'S' then

                         gera_merc_ivecore(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_sapiens = 'S' then

                         gera_merc_sapiens(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_powersap = 'S' then

                         gera_merc_powersap(vs_cod_estab
                                         , pd_data_ini
                                         , pd_data_fim);
                      end if;

                      if vs_ind_mainframe = 'S' then

                         gera_merc_mainframe(vs_cod_estab
                                           , pd_data_ini
                                           , pd_data_fim);
                      end if;

                      if vs_ind_outros = 'S' then

                         gera_merc(vs_cod_estab
                                 , pd_data_ini
                                 , pd_data_fim);
                      end if;



                      if pind_consol = 'S' then

                         gera_consolidado(vs_cod_estab
                                        , pd_data_ini
                                        , pd_data_fim);
                      end if;

              end if;

             gera_serv(vs_cod_estab
                     , pd_data_ini
                     , pd_data_fim);




          end loop;

    end if;


    vs_ind_sapiens     := 'N';
    vs_ind_powersap    := 'N';
    vs_ind_mainframe   := 'N';
    vs_ind_outros      := 'N';

    lib_proc.add_log('Quantidade de registros mercadorias gerados: '||vn_qtd_reg,1);
    lib_proc.add_log('Quantidade de registros servicos gerados: '||vn_qtd_reg_serv,1);
    lib_proc.add_log('Quantidade de registros consolidados gerados: '||vn_qtd_reg_consol,1);



    lib_proc.add_log('Processo Finalizado com sucesso',1);

    vn_qtd_reg := 0;
    vn_qtd_reg_serv := 0;
    vn_qtd_reg_consol := 0;

    LIB_PROC.CLOSE();
    RETURN mproc_id;

END;


  -------------------------------------------------------------------------
  -- Procedure para Teste
  -------------------------------------------------------------------------


    PROCEDURE teste_rel IS
    --mproc_id INTEGER;
    resultado integer := 0;
  BEGIN
    lib_parametros.salvar( 'EMPRESA', '001' );
    mcod_empresa := '001';
    --resultado := Executar( '05/01/2016','05/01/2016','114');

    dbms_output.put_line('');
    dbms_output.put_line('---Arquivo Magnetico----');
    dbms_output.put_line('');

    lib_proc.list_output(resultado, 1);
  END;

END GSR_ARQREL_PIS_COFINS_CPROC;
/
