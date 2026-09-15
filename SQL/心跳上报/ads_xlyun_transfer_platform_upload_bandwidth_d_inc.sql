insert overwrite table dw_xlyun.ads_xlyun_transfer_platform_upload_bandwidth_d_inc
select
    platform
    , service_name
    , service_version
    , product_version
    , carrier_name
    , province_name
    , vip_type
    , level_1_traffic_category
    , level_2_traffic_category
    , level_3_traffic_category
    , server_time_5min  as 5min_range
    , upload_bytes_current
    , duration_current
    , now() as etl_time
    , '${date}' as ds
from (
    select
          platform
        , case
            when service_name in ('pc.XMP_P', 'pc_xmp', 'pc.NetDisk_M', 'pc.netdisk_m') then 'XMP-win'
            when service_name in ('pc.thunderX', 'pc', 'pc.thunder9') then '迅雷-win'
            when service_name in ('pc.NetDisk_N', 'pc_player') then '迅雷-win'
            when service_name in ('6015', 'mac') then '迅雷-Mac'
            when service_name in ('6100', 'harmony') then '迅雷-鸿蒙'
            when service_name in ('6009', 'android') then '手雷-Android'
            when service_name in ('6050', 'ios') then '手雷-iOS'
            when service_name in ('6092', 'browser_android') then '浏览器-Android'
            when service_name in ('6097', 'browser_ios') then '浏览器-iOS'
            when service_name in ('6066', 'nas') then 'NAS'
            else '其他'
          end as service_name
        , service_version
        , product_version
        , carrier_name
        , province_name
        , vip_type
        , level_1_traffic_category
        , level_2_traffic_category
        , level_3_traffic_category
        , server_time_5min
        , sum(upload_bytes_current) as upload_bytes_current
        , sum(duration_current)     as duration_current
    from
        dw_xlyun.dws_xlyun_transfer_user_heartbeat_upload_d_inc
    where
        ds >= '${idd_edd_minus_dd1}' and ds <= '${date}'
        and substr(server_time_5min, 1, 10) = '${sdd}'
    group by
        platform
        , case
            when service_name in ('pc.XMP_P', 'pc_xmp', 'pc.NetDisk_M', 'pc.netdisk_m') then 'XMP-win'
            when service_name in ('pc.thunderX', 'pc', 'pc.thunder9') then '迅雷-win'
            when service_name in ('pc.NetDisk_N', 'pc_player') then '迅雷-win'
            when service_name in ('6015', 'mac') then '迅雷-Mac'
            when service_name in ('6100', 'harmony') then '迅雷-鸿蒙'
            when service_name in ('6009', 'android') then '手雷-Android'
            when service_name in ('6050', 'ios') then '手雷-iOS'
            when service_name in ('6092', 'browser_android') then '浏览器-Android'
            when service_name in ('6097', 'browser_ios') then '浏览器-iOS'
            when service_name in ('6066', 'nas') then 'NAS'
            else '其他'
          end
        , service_version
        , product_version
        , carrier_name
        , province_name
        , vip_type
        , level_1_traffic_category
        , level_2_traffic_category
        , level_3_traffic_category
        , server_time_5min
) as t
;


-- create table dw_xlyun.ads_xlyun_transfer_platform_upload_bandwidth_d_inc (
--     platform                       string comment '客户端平台'
--     , service_name                 string comment '业务分类（中文：XMP-win/迅雷-win/迅雷-Mac/迅雷-鸿蒙/手雷-Android/手雷-iOS/浏览器-Android/浏览器-iOS/NAS/其他）'
--     , service_version              string comment '客户端版本'
--     , product_version              string comment '传输库版本'
--     , carrier_name                 string comment '运营商'
--     , province_name                string comment '省份'
--     , vip_type                     string comment '会员类型，'
--     , level_1_traffic_category     string comment '一级流量分类'
--     , level_2_traffic_category     string comment '二级流量分类'
--     , level_3_traffic_category     string comment '三级流量分类'
--     , 5min_range                   string comment '5分钟划分区间'
--     , upload_bytes_current         bigint comment '上行流量'
--     , duration_current             bigint comment '周期'
--     , etl_time                     string comment '跑数时间'
-- ) COMMENT 'ADS-迅雷云传输库-p2p质量监控-上行带宽'
-- PARTITIONED BY (
--   `ds` string COMMENT '日期分区'
-- )
-- stored as parquet;