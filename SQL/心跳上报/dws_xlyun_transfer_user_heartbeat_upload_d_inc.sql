insert overwrite table dw_xlyun.dws_xlyun_transfer_user_heartbeat_upload_d_inc
select
    peer_id
    , max(server_time) as server_time
    , user_id
    , service_id
    , service_version
    , product_id
    , product_version
    , stat_status
    , network_type
    , vip_type
    , min(app_start_time) as app_start_time
    , service_name
    , city_name
    , province_name
    , country_name
    , carrier_name
    , '20' as level_1_traffic_category
    , 'pub' as level_2_traffic_category
    , flow_type as level_3_traffic_category
    , server_time_5min
    , sum(flow_value) as upload_bytes_current
    , sum(duration) as duration_current
    , now() as etl_time
    , initial_cfg_strategy_name
    , '${date}' as ds
    , platform
from (
    select
        peer_id
        , server_time
        , user_id
        , distinct_id
        , service_id
        , service_version
        , product_id
        , product_version
        , stat_status
        , network_type
        , vip_type
        , app_start_time
        , service_name
        , city_name
        , if(country_name = '中国' or country_name = '共享地址', province_name, '国外') as province_name
        , country_name
        , if( carrier_name in ('电信', '移动', '联通'), carrier_name, '其他') as carrier_name
        , flow_type
        , flow_value
        , duration
        , platform
        , initial_cfg_strategy_name
        , from_unixtime(floor(unix_timestamp(server_time)/300)*300, 'yyyy-MM-dd HH:mm') as server_time_5min
    from
        dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc
    UNPIVOT (
        flow_value
        FOR flow_type IN (
            dcache_task_upload_bytes    as dcache_task,
            dcache_file_upload_bytes    as dcache_file,
            vod_task_upload_bytes       as vod_task,
            vod_file_upload_bytes       as vod_file,
            other_task_upload_bytes     as other_task,
            other_file_upload_bytes     as other_file
        )
    )
    where
        ds = '${date}'
        and flow_value IS NOT NULL AND flow_value > 0 --过滤流量为0或空的数据
) as t
group by
    peer_id
    , user_id
    , service_id
    , service_version
    , product_id
    , product_version
    , stat_status
    , network_type
    , vip_type
    , service_name
    , city_name
    , province_name
    , country_name
    , carrier_name
    , flow_type
    , server_time_5min
    , platform
    , initial_cfg_strategy_name
;

-- create table dw_xlyun.dws_xlyun_transfer_user_heartbeat_upload_d_inc (
--       peer_id                        string comment '节点id'
--     , server_time                    string comment '上报的时间戳，如：2026-04-22 18:01:26'
--     , user_id                        string comment '用户id'
--     , service_id                     string comment '客户端id，用于区分产品名称'
--     , service_version                string comment '客户端版本'
--     , product_id                     string comment '传输库id'
--     , product_version                string comment '传输库版本'
--     , stat_status                    string comment '上报状态'
--     , network_type                   string comment '网络类型'
--     , vip_type                       string comment '会员类型，'
--     , app_start_time                 string comment '任务开始时间，UTC时间，ms'
--     , service_name                   string comment '产品名称。如：pc：迅雷-win；pc_player：PC迅雷网盘播放器；'
--     , city_name                      string comment '城市'
--     , province_name                  string comment '省份；中国/共享地址取原省份，否则为国外'
--     , country_name                   string comment '国家'
--     , carrier_name                   string comment '运营商'
--     , level_1_traffic_category       string comment '一级流量分类, 10：付费，20：免费'
--     , level_2_traffic_category       string comment '二级流量分类'
--     , level_3_traffic_category       string comment '三级流量分类'
--     , server_time_5min               string comment 'server_time，根据5分钟划分区间'
--     , upload_bytes_current           bigint comment '流量'
--     , duration_current               bigint comment '周期'
--     , etl_time                       string comment '跑数时间'
-- ) COMMENT 'DWS-传输库-上行用户主题聚合'
-- PARTITIONED BY (
--     `ds` string COMMENT '日期分区'
--     , platform string comment '端分区'
-- )
-- stored as parquet;


--20260720新增上报
-- alter table dw_xlyun.dws_xlyun_transfer_user_heartbeat_upload_d_inc add columns(
--     initial_cfg_strategy_name   string comment '下载库启动时获取到的配置文件策略名称；数据起始日期：20260720'
-- )

