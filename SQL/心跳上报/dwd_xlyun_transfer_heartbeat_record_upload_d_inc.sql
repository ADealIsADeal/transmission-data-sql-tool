insert overwrite table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc
select
    peer_id
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
    , app_start_time
    , duration
    , upload_bytes
    , dcache_task_upload_bytes
    , dcache_file_upload_bytes
    , vod_task_upload_bytes
    , vod_file_upload_bytes
    , other_task_upload_bytes
    , other_file_upload_bytes
    , upload_to
    , now() as etl_time
    , upload_duration
    , nat_type
    , extdata
    , cast(extdata["SameLANUploadBytes"] as bigint) as phub_same_lan_bytes
    , initial_cfg_strategy_name
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
        , app_start_time
        , duration
        , upload_bytes
        , dcache_task_upload_bytes
        , dcache_file_upload_bytes
        , vod_task_upload_bytes
        , vod_file_upload_bytes
        , other_task_upload_bytes
        , other_file_upload_bytes
        , upload_to
        , upload_duration
        , ds
        , nat_type
        , extdata
        , initial_cfg_strategy_name
        , row_number() over(partition by peer_id, app_start_time, record_seq order by server_time desc) as rn
    from
        dw_xlyun.ods_xlyun_transfer_heartbeat_record_upload_log_d_inc
    where
        ds = '${date}'
        and coalesce(upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(dcache_task_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(dcache_file_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(vod_task_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(vod_file_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(other_task_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
        and coalesce(other_file_upload_bytes, 0) <= 10995116277760 --过滤异常值，单个上报小于10T
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

-- create table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc (
--       peer_id                         string comment '节点id'
--     , record_seq                    string comment '任务维度的序号，任务开始为0，每上报一次累加1'
--     , event_name                    string comment '事件名'
--     , event_time                    string comment '生成当前上报记录时的本地时间戳，UTC时间；存在大量历史日期，优先使用server_time'
--     , server_time                   string comment '上报的时间戳，如：2026-04-22 18:01:26'
--     , user_id                       string comment '用户id'
--     , distinct_id                   string comment '访客 ID'
--     , ip                            string comment '设备的 IP 地址'
--     , city_name                     string comment '城市'
--     , province_name                 string comment '省份'
--     , country_name                  string comment '国家'
--     , carrier_name                  string comment '运营商'
--     , service_id                    string comment '客户端id，用于区分产品名称'
--     , service_version               string comment '客户端版本'
--     , product_id                    string comment '传输库id'
--     , product_version               string comment '传输库版本'
--     , stat_status                   string comment '上报状态；0：任务开始；1：心跳；2：任务结束'
--     , network_type                  string comment '网络类型；1：未知；2: WiFi；3：移动'
--     , vip_type                      string comment '会员类型，1:普通会员；3：白金会员；5：超级会员；unknown：非会员'
--     , app_start_time                string comment '任务开始时间，UTC时间，ms'
--     , duration                      bigint comment '周期时长'
--     , upload_bytes                  bigint comment '周期内上传的总字节数，单位byte'
--     , dcache_task_upload_bytes      bigint comment' 周期内从dcache上传的字节数（正在下载，顺便上传），单位byte'
--     , dcache_file_upload_bytes      bigint comment' 周期内从dcache上传的字节数（纯上传），单位byte'
--     , vod_task_upload_bytes         bigint comment' 周期内从点播上传的字节数（正在下载，顺便上传），单位byte'
--     , vod_file_upload_bytes         bigint comment' 周期内从点播文件上传的字节数（纯上传），单位byte'
--     , other_task_upload_bytes       bigint comment' 周期内从其他文件（bt/p2sp下载/取回等）上传的字节数（正在下载，顺便上传），单位byte'
--     , other_file_upload_bytes       bigint comment' 周期内从其他文件（bt/p2sp下载/取回等）上传的字节数（纯上传），单位byte'
--     , upload_to                     string comment '上传到哪里'
--     , etl_time                      string comment '跑数时间'
-- ) COMMENT 'DWD-迅雷云传输库-心跳上报-上行'
-- PARTITIONED BY (
--     ds string COMMENT '日期分区'
--     , platform string comment '端分区,取值：android、ios、pc'
--     , service_name string comment '产品名称。如：pc：迅雷-win；pc_player：PC迅雷网盘播放器；'
-- )
-- stored as parquet;


--20260528 新增
-- alter table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc add columns (
--     upload_duration bigint comment '周期内实际上传时长,单位：s'
-- );


-- alter table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc add columns(
--     nat_type                string comment 'NAT类型'
--     , extdata   map<string,string> comment '扩展字段，包含完整json字段'
--     , phub_same_lan_bytes bigint comment '内网流量，单位：字节'
-- );


--20260720新增上报
-- alter table dw_xlyun.dwd_xlyun_transfer_heartbeat_record_upload_d_inc add columns(
--     initial_cfg_strategy_name   string comment '下载库启动时获取到的配置文件策略名称；数据起始日期：20260720'
-- )