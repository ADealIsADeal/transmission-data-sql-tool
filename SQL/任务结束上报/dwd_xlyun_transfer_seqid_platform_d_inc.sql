------------------------------------------------------------
--  FILE:    dwd_xlyun_transfer_seqid_platform_d_inc.sql
--  DESC:    传输库宽表 DWD（日增量；读去重表 join hfk 后字段加工写入）
--  CHANGE:  20260701 不做 action_type 过滤；点播归类 play；DWD 保持天粒度；分片去重
--           20260703 去重逻辑独立落表；本脚本读去重表关联 hfk 后再做字段加工
--  PARAM:   ds='${date}'
--  UPSTREAM: dwd_xlyun_transfer_seqid_platform_dedup_d_inc
--  DEP:     去重表脚本需先执行完成
------------------------------------------------------------

with joined as (
    select
        d.peer_id
        , d.user_id
        , d.guid
        , d.parent_id
        , d.seqid
        , d.event_id
        , d.server_info
        , d.cmdid
        , d.appid
        , d.service_version
        , d.product_version
        , d.service_name
        , d.extdata_head
        , d.process_id
        , d.ip
        , d.attribute1
        , d.attribute2
        , d.cost1
        , d.cost2
        , d.cost3
        , d.cost4
        , d.final_result
        , d.event_status
        , d.mode
        , d.file_name
        , d.file_suffix
        , d.file_size
        , d.extdata
        , d.cdn_res_count
        , d.dcdn_hub_res_num
        , d.high_res_count
        , d.error_code
        , d.task_type
        , d.hub_gcid
        , d.real_gcid
        , d.download_time
        , d.recv_bytes
        , d.vip_type
        , d.anti_server
        , d.task_origin
        , d.ref_url
        , d.file_url
        , xl_urldecode(xl_urldecode(d.file_url)) as url
        , d.global_speed
        , d.download_strategy
        , d.token
        , d.error_bytes
        , d.index_extra_data
        , d.ts
        , d.jiasu_vip_speed
        , d.jiasu_super_speed
        , d.jiasu_smooth
        , d.jiasu_zero_speed
        , d.jiasu_group
        , d.all_bytes
        , d.origin_bytes
        , d.server_bytes
        , d.phub_bytes
        , d.phub_peer
        , d.tracker_bytes
        , d.tracker_peer
        , d.dcdn_bytes
        , d.dcdn_peer
        , d.pcdn_bytes
        , d.pcdn_peer
        , d.bonus_bytes
        , d.bonus_peer
        , d.phub_cdn_bytes
        , d.phub_dcdn_bytes
        , d.xphub_bytes
        , d.super_pcdn_bytes
        , d.super_pcdn_peer
        , d.phub_res_peer
        , d.phub_insert_peer
        , d.running_task_count_avg
        , d.running_user_task_count_avg
        , d.global_all_bytes
        , d.global_p2p_bytes
        , d.global_p2s_bytes
        , d.global_bonus_bytes
        , d.global_dcdn_bytes
        , d.global_origin_bytes
        , d.etag
        , d.query_all_hub_count
        , d.query_all_hub_result
        , d.global_speed_target_1
        , d.global_speed_target_64
        , d.first_insert_pcdn_peer_time
        , d.alloc_data_buffer_fail_count
        , d.global_speed_max_in_window
        , d.ending_span_time
        , d.is_netdisk_fetch_task
        , d.first_video_mode
        , d.player_mode
        , d.platform
        , d.action_type
        , if(hfk.hubgcid is not null, 1, 0) as is_hfk
    from
        dw_xlyun.dwd_xlyun_transfer_seqid_platform_dedup_d_inc as d
    left join (
        select
            hubgcid
        from
            dw_xlyun.dim_xlyun_transfer_gcid_forbidden_hfk_d_inc
        where
            ds = '${date}'
            and coalesce(hubgcid, '') <> ''
        group by
            hubgcid
    ) as hfk
    on
        d.hub_gcid = hfk.hubgcid
        and coalesce(d.hub_gcid, '') <> ''
    where
        d.ds = '${date}'
)

insert overwrite table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc
select /*+ MAPJOIN(dim_pub1, dim_pub2) */
    joined.peer_id
    , joined.user_id
    , joined.guid
    , joined.parent_id
    , joined.seqid
    , joined.event_id
    , cast(joined.server_info as string) as server_info
    , joined.cmdid
    , joined.appid
    , joined.service_version
    , joined.product_version
    , joined.service_name
    , joined.extdata_head
    , joined.process_id
    , joined.ip
    , joined.attribute1
    , joined.attribute2
    , joined.cost1
    , joined.cost2
    , joined.cost3
    , joined.cost4
    , coalesce(joined.final_result, 'N/A') as final_result
    , joined.event_status
    , case
        when joined.mode = '0' then 'new'
        when joined.mode = '1' then 'continue'
        when joined.mode is null then 'N/A'
        else joined.mode
    end as mode
    , joined.file_name
    , joined.file_suffix
    , coalesce(dim_pub1.dim_value, 'N/A') as file_type_code
    , coalesce(dim_pub1.dim_value_desc, 'N/A') as file_type_name
    , joined.file_size
    , joined.extdata
    , joined.cdn_res_count
    , joined.dcdn_hub_res_num
    , joined.high_res_count
    , joined.error_code
    , coalesce(dim_pub2.dim_key, 'N/A') as fail_reason_code
    , coalesce(dim_pub2.dim_value, 'N/A') as fail_reason_name
    , joined.task_type
    , if(length(joined.hub_gcid) = 40, joined.hub_gcid, 'N/A') as hub_gcid
    , if(length(joined.real_gcid) = 40, joined.real_gcid, 'N/A') as real_gcid
    , joined.download_time
    , joined.recv_bytes
    , joined.vip_type
    , '' as is_vip
    , joined.anti_server
    , joined.is_hfk
    , joined.task_origin
    , '' as prov_id
    , '' as city_id
    , '' as sp_id
    , joined.ref_url
    , if(length(parse_url(joined.ref_url, 'HOST')) >= 1, parse_url(joined.ref_url, 'HOST'), 'unknown') as source_host
    , joined.url
    , cast(joined.global_speed as bigint) as global_speed
    , joined.download_strategy
    , joined.token
    , cast(joined.error_bytes as bigint) as error_bytes
    , joined.index_extra_data
    , joined.ts
    , joined.jiasu_vip_speed
    , joined.jiasu_super_speed
    , joined.jiasu_smooth
    , joined.jiasu_zero_speed
    , joined.jiasu_group
    , joined.all_bytes
    , joined.origin_bytes
    , joined.server_bytes
    , joined.phub_bytes
    , joined.phub_peer
    , joined.tracker_bytes
    , joined.tracker_peer
    , joined.dcdn_bytes
    , joined.dcdn_peer
    , joined.pcdn_bytes
    , joined.pcdn_peer
    , joined.bonus_bytes
    , joined.bonus_peer
    , joined.phub_cdn_bytes
    , joined.phub_dcdn_bytes
    , joined.xphub_bytes
    , joined.super_pcdn_bytes
    , joined.super_pcdn_peer
    , joined.phub_res_peer
    , joined.phub_insert_peer
    , joined.running_task_count_avg
    , joined.running_user_task_count_avg
    , joined.global_all_bytes
    , joined.global_p2p_bytes
    , joined.global_p2s_bytes
    , joined.global_bonus_bytes
    , joined.global_dcdn_bytes
    , joined.global_origin_bytes
    , joined.etag
    , joined.query_all_hub_count
    , nvl(joined.query_all_hub_result, 'N/A') as query_all_hub_result
    , coalesce(joined.global_speed_target_64, joined.global_speed_target_1, 0) as global_speed_target
    , joined.first_insert_pcdn_peer_time
    , joined.alloc_data_buffer_fail_count
    , joined.global_speed_max_in_window
    , joined.ending_span_time
    , joined.is_netdisk_fetch_task
    , joined.first_video_mode
    , joined.player_mode
    , split(ip_parser(joined.ip), ',')[0] as country_name
    , split(ip_parser(joined.ip), ',')[1] as prov_name
    , split(ip_parser(joined.ip), ',')[2] as city_name
    , split(ip_parser(joined.ip), ',')[3] as carrier_name
    , if(joined.platform = 'pc', joined.extdata['NetWorkType'], joined.extdata['NetworkType']) as network_type
    , case
        when joined.action_type = 'withdraw' then 0
        when joined.action_type = 'download'
            and (
                joined.url like '%sandai%'
                or joined.url like '%backstage-file-ssl.a.88cdn.com/pc/upgrade/%'
                or joined.url like '%static-xl9-ssl.xunlei.com%'
                or joined.url like '%xlgameupdate%'
                or joined.url like '%admin.xl9.xunlei.com%'
                or joined.url like '%static-pc.xunlei.com%'
                or joined.url like '%xunleisetup%'
                or joined.url like '%xunlei.com%'
                )
        then 1
        else 0
        end as flag_system
    , case
        when joined.task_type in ('1', '14', '4635') then 'p2sp'
        when joined.task_type in ('4636') then 'bt_main'
        when joined.task_type in ('3', '4637') then 'bt'
        when joined.task_type in ('4', '4638') then 'emule'
        when joined.task_type in ('4639') then 'magnet'
        when joined.task_type in ('12', '16') then 'hls'
        else 'other'
    end as task_type_name
     , case
            when joined.vip_type in ('2', 'normal') then '1'
            when joined.vip_type in ('3', 'platinum') then '3'
            when joined.vip_type in ('super', '5') then '5'
            else '0'
        end as vip_type_name
    , '${date}' as ds
    , joined.platform
    , joined.action_type
from
    joined
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'file_type'
) as dim_pub1
on
    dim_pub1.dim_key = joined.file_suffix
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'download_error_type'
) as dim_pub2
on
    dim_pub2.dim_key = joined.error_code
;

-- create table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc (
--     peer_id                          string comment '传输库id'
--     , user_id                        string comment '用户id'
--     , guid                          string comment '设备id'
--     , parent_id                      string comment '主任务id'
--     , seqid                         string comment '下载分片id'
--     , event_id                       string comment '事件id'
--     , server_info                    string comment 'server_info'
--     , cmdid                         bigint comment '命令id'
--     , appid                         string comment '产品id'
--     , service_version               string comment '客户端版本'
--     , product_version               string comment '下载库版本号'
--     , service_name                  string comment '产品id'
--     , extdata_head                  string comment ''
--     , process_id                     string comment '进程识别号'
--     , ip                            string comment '客户端ip'
--     , attribute1                    string comment ''
--     , attribute2                    string comment ''
--     , cost1                         bigint comment ''
--     , cost2                         bigint comment ''
--     , cost3                         bigint comment ''
--     , cost4                         bigint comment ''
--     , final_result                  string comment '下载结果'
--     , event_status                   string comment '任务状态'
--     , mode                          string comment '续传类型'
--     , file_name                     string comment '文件名'
--     , file_suffix                   string comment '文件后缀'
--     , file_type_code                string comment '文件类型'
--     , file_type_name                string comment '文件类型中文名'
--     , file_size                     bigint comment '文件大小'
--     , extdata                       map<string, string> comment '拓展字段'
--     , cdn_res_count                 bigint comment 'dcdn peer资源总数'
--     , dcdn_hub_res_num               bigint comment '离线资源总数'
--     , high_res_count                bigint comment '高速资源总数'
--     , error_code                    string comment '失败原因原始code'
--     , fail_reason_code              string comment '失败原因code'
--     , fail_reason_name              string comment '失败原因中文名'
--     , task_type                     string comment '任务类型'
--     , hub_gcid                      string comment 'hub gcid'
--     , real_gcid                     string comment 'real gcid'
--     , download_time                 bigint comment '分片下载时长'
--     , recv_bytes                    bigint comment '接收字节数'
--     , vip_type                      string comment '会员类型'
--     , is_vip                        string comment '会员类型'
--     , anti_server                   string comment '黄反标记'
--     , is_hfk                        string comment '关联黄反库'
--     , task_origin                   string comment '任务来源'
--     , prov_id                       string comment '省份'
--     , city_id                       string comment '城市'
--     , sp_id                         string comment '运营商'
--     , ref_url                       string comment '访问页url'
--     , source_host                   string comment '来源网站'
--     , url                           string comment '资源url'
--     , global_speed                  bigint comment '全局速度'
--     , download_strategy             bigint comment '下载策略'
--     , token                         string comment 'token'
--     , error_bytes                   bigint comment '错误字节数'
--     , index_extra_data              string comment '索引风控信息'
--     , ts                            string comment '上报时间'
--     , jiasu_vip_speed               bigint comment '会员加速'
--     , jiasu_super_speed             bigint comment '超级加速'
--     , jiasu_smooth                  bigint comment '顺畅模式加速'
--     , jiasu_zero_speed              bigint comment '0速度补速'
--     , jiasu_group                   bigint comment '抱团加速'
--     , all_bytes                     bigint comment '总字节数'
--     , origin_bytes                  bigint comment '原始资源字节数'
--     , server_bytes                  bigint comment '镜像资源字节数'
--     , phub_bytes                    bigint comment 'phub字节数'
--     , phub_peer                     bigint comment 'phub资源数'
--     , tracker_bytes                 bigint comment 'tracker字节数'
--     , tracker_peer                  bigint comment 'tracker资源数'
--     , dcdn_bytes                    bigint comment 'dcdn字节数'
--     , dcdn_peer                     bigint comment 'dcdn资源数'
--     , pcdn_bytes                    bigint comment 'pcdn字节数'
--     , pcdn_peer                     bigint comment 'pcdn资源数'
--     , bonus_bytes                   bigint comment 'bonus字节数'
--     , bonus_peer                    bigint comment 'bonus资源数'
--     , phub_cdn_bytes                bigint comment 'phub cdn字节数'
--     , phub_dcdn_bytes               bigint comment 'phub dcdn字节数'
--     , xphub_bytes                   bigint comment '缓存peer字节数'
--     , super_pcdn_bytes              bigint comment 'super pcdn字节数'
--     , super_pcdn_peer               bigint comment 'super pcdn资源数'
--     , phub_res_peer                 bigint comment 'phub资源peer数'
--     , phub_insert_peer              bigint comment '创建channel的phub数'
--     , running_task_count_avg        bigint comment '平均并发子任务数'
--     , running_user_task_count_avg   bigint comment '平均并发主任务数'
--     , global_all_bytes              bigint comment '全局接收字节数'
--     , global_p2p_bytes              bigint comment '全局phub字节数'
--     , global_p2s_bytes              bigint comment '全局p2s字节数'
--     , global_bonus_bytes            bigint comment '全局bonus字节数'
--     , global_dcdn_bytes             bigint comment '全局dcdn字节数'
--     , global_origin_bytes           bigint comment '全局原始url字节数'
--     , etag                          string comment 'etag'
--     , query_all_hub_count           string comment '查种次数'
--     , query_all_hub_result          string comment '查种结果'
--     , global_speed_target            bigint comment '目标配速'
--     , first_insert_pcdn_peer_time   bigint comment '查peer耗时'
--     , alloc_data_buffer_fail_count  bigint comment '磁盘慢限速次数'
--     , global_speed_max_in_window    bigint comment '边下边测最大测速'
--     , ending_span_time              bigint comment '写入磁盘耗时'
--     , is_netdisk_fetch_task            string comment '是否网盘取回任务，PC extdata[isnetdiskfetchtask]'
--     , first_video_mode                string comment '点播模式，PC extdata[firstvideomode]'
--     , player_mode                   string comment '播放模式，移动端 extdata[PlayerMode]'
-- )
-- comment 'dwd_迅雷云_传输库_任务退出上报_宽表'
-- partitioned by (
--     ds string comment '日期分区'
--     , platform string comment '端'
--     , action_type string comment '行为：download:下载，withdraw：取回，play：点播，other：其他'
-- )
-- stored as parquet;

-- alter table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc add columns(
--     country_name string comment '国家；客户端ip解析'
--     , prov_name                     string comment '省份'
--     , city_name                     string comment '城市'
--     , carrier_name                       string comment '运营商'
-- );

-- 添加日期：20260803
-- alter table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc add columns(
--     network_type string comment '网络类型'
--     , flag_system bigint comment '是否迅雷自有插件类任务，1：是，0：否'
--     , task_type_name string comment '任务类型，p2sp/bt_main/bt/emule/magnet/hls'
--     , vip_type_name string comment '会员类型，1：普通，3：白金，5：超会，0：非会员'
-- );