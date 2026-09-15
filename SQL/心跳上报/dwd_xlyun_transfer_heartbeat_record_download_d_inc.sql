insert overwrite table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_download_d_inc
select
    peer_id
    , task_id
    , sub_task_id
    , traceid
    , record_seq
    , event_name
    , event_time
    , server_time
    , user_id
    , distinct_id
    , ip
    , split(ip_parser(ip),',')[2] as city_name
    , split(ip_parser(ip),',')[1] as province_name
    , split(ip_parser(ip),',')[0] as country_name
    , split(ip_parser(ip),',')[3] as carrier_name
    , service_id
    , service_version
    , product_id
    , product_version
    , stat_status
    , coalesce(network_type, 'unknown') as network_type
    , case
        when vip_type = 'normal' or vip_type = '2' then '1'
        when vip_type = 'platinum' or vip_type = '3' then '3'
        when vip_type = 'super' or vip_type = '5' then '5'
        else 'unknown' end as vip_type
    , task_start_time
    , duration
    , coalesce(os_version, 'unknown')    as os_version
    , coalesce(task_type, 'unknown')     as task_type
    , coalesce(task_purpose, 'unknown')  as task_purpose
    , coalesce(has_play, 'unknown')      as has_play
    , hub_gcid
    , phub_bytes
    , pcdn_peer_bytes
    , dcdn_download_bytes
    , server_bytes
    , origin_bytes3d
    , origin_bytes_xl
    , resource_bytes
    , recv_bytes
    , all_task_recv_bytes
    , now() as etl_time
    , nat_type
    , extdata
    , cast(extdata["PhubSameLanBytes"] as bigint) as phub_same_lan_bytes
    , initial_cfg_strategy_name
    , task_cfg_strategy_name
    , '${date}' as ds
    , case
        when product_id = '33' then 'pc'
        when product_id = '18' then 'android'
        when product_id = '19' then 'ios'
        else product_id end as platform
    , case
        when service_id = 'pc.XMP_P' then 'pc_xmp'
        when service_id = 'pc.thunderX' then 'pc'
        when service_id = 'pc.NetDisk_N' then 'pc_player'
        when service_id = '6015' then 'mac'
        when service_id = '6100' then 'harmony'
        when service_id = '6009' then 'android'
        when service_id = '6050' then 'ios'
        when service_id = '6092' then 'browser_android'
        when service_id = '6097' then 'browser_ios'
        when service_id = '6066' then 'nas'
        else service_id end as service_name
from (
    select
        peer_id
        , app_seq_id as task_id
        , hash_info as sub_task_id
        , traceid
        , record_seq
        , event_name
        , event_time
        , from_unixtime(cast(server_time as bigint)/1000) as server_time
        , user_id
        , distinct_id
        , ip
        , service_id
        , service_version
        , product_id
        , product_version
        , stat_status
        , network_type
        , vip_type
        , task_start_time
        , duration
        , os_version
        , task_type
        , task_purpose
        , has_play
        , hub_gcid
        , phub_bytes
        , pcdn_peer_bytes
        , dcdn_download_bytes - pcdn_peer_bytes as dcdn_download_bytes --dcdn 包含 pcdn, 需剔除
        , server_bytes
        , origin_bytes3d
        , origin_bytes_xl
        , resource_bytes
        , recv_bytes
        , all_task_recv_bytes
        , ds
        , nat_type
        , extdata
        , initial_cfg_strategy_name
        , task_cfg_strategy_name
        , row_number() over(partition by peer_id, app_seq_id, hash_info, traceid, record_seq order by server_time desc) as rn
    from
        dw_xlyun.ods_xlyun_transfer_heartbeat_record_download_log_d_inc
    where
        ds = '${date}'
        and coalesce(phub_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(pcdn_peer_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(dcdn_download_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(server_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(origin_bytes3d, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(origin_bytes_xl, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(recv_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(all_task_recv_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and service_id in (
            'pc.thunderX'
            , 'pc.NetDisk_N'
            , 'pc.XMP_P'
            , 'pc.vip_thunder'
            , 'pc.thunder9'
            , 'pc.NetDisk_M'
            , 'XLSDKUPDATE'
            , 'pc.XLGameCenter'
            , 'pc.PikPak_K'
            , 'XMP'
            , 'OnlineInstall'
            , 'PCSDKDEMO'
            , '6015'
            , '6100'
            , '6009'
            , '6050'
            , '6092'
            , '6097'
            , '6066'
        )   --过滤异常service_id
) as t
where
    rn = 1
;

-- create table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_download_d_inc (
--       peer_id                 string comment '节点id'
--     , task_id                 string comment '客户端传下来的任务id，用于合并分片'
--     , sub_task_id	          string comment '区分不同BT子任务：infohash_fileindex；其他任务类型为空'
--     , traceid                 string comment '行为id'
--     , record_seq              string comment '任务维度的序号，任务开始为0，每上报一次累加1'
--     , event_name              string comment '事件名'
--     , event_time              string comment '生成当前上报记录时的本地时间戳，UTC时间；存在大量历史日期，优先使用server_time'
--     , server_time             string comment '上报的时间戳，如：2026-04-22 18:01:26'
--     , user_id                 string comment '用户id'
--     , distinct_id             string comment '访客 ID'
--     , ip                      string comment '设备的 IP 地址'
--     , city_name               string comment '城市'
--     , province_name           string comment '省份'
--     , country_name            string comment '国家'
--     , carrier_name            string comment '运营商'
--     , service_id              string comment '客户端id，用于区分产品名称'
--     , service_version         string comment '客户端版本'
--     , product_id              string comment '传输库id'
--     , product_version         string comment '传输库版本'
--     , stat_status             string comment '上报状态；0：任务开始；1：心跳；2：任务结束'
--     , network_type            string comment '网络类型；1：未知；2: WiFi；3：移动'
--     , vip_type                string comment '会员类型，1:普通会员；3：白金会员；5：超级会员；unknown：非会员'
--     , task_start_time         string comment '任务开始时间，UTC时间，ms'
--     , duration                bigint comment '周期时长'
--     , os_version              string comment '系统'
--     , task_type               string comment '任务类型(p2sp, emule, bt_main, bt_child, magnet，hls)'
--     , task_purpose            string comment '下载为主：下载/取回 （不管播多少都下完）   播放为主：播放（播多少下多少）'
--     , has_play                string comment '是否有实际播放请求'
--     , hub_gcid                string comment 'HUB gcid，查询服务端返回的gcid'
--     , phub_bytes              bigint comment '周期内从phub下载的字节数，单位byte'
--     , pcdn_peer_bytes         bigint comment '周期内从pcdn下载的字节数，单位byte'
--     , dcdn_download_bytes     bigint comment '周期内从dcdn下载的字节数，单位byte'
--     , server_bytes            bigint comment '周期内从server镜像下载的字节数，单位byte'
--     , origin_bytes3d          bigint comment '周期内从三方原始链接下载的字节数，单位byte'
--     , origin_bytes_xl         bigint comment '周期内从迅雷原始链接下载的字节数，例如云盘url，单位byte'
--     , resource_bytes          string comment '周期内从不同类型节点下载的字节数，单位byte'
--     , recv_bytes              bigint comment '周期内总的下载字节数，单位byte'
--     , all_task_recv_bytes     bigint comment '周期内全局所有任务总的下载字节数，单位byte'
--     , etl_time                string comment '跑数时间'
-- ) COMMENT 'DWD-迅雷云传输库-心跳上报-下行'
-- PARTITIONED BY (
--     ds string COMMENT '日期分区'
--     , platform string comment '端分区,取值：android、ios、pc'
--     , service_name string comment '产品名称。如：pc：迅雷-win；pc_player：PC迅雷网盘播放器；'
-- )
-- stored as parquet;
--
-- alter table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_download_d_inc add columns(
--     nat_type                string comment 'NAT类型'
--     , extdata   map<string,string> comment '扩展字段，包含完整json字段'
--     , phub_same_lan_bytes bigint comment '内网流量，单位：字节'
-- );

--20260720新增上报
-- alter table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_download_d_inc add columns(
--      initial_cfg_strategy_name string comment '下载库启动时获取到的配置文件策略名称；数据起始日期：20260720'
--      , task_cfg_strategy_name   string comment '任务开始下载时看到的配置文件策略名称；数据起始日期：20260720'
-- );